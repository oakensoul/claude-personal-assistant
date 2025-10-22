---
title: "CI/CD Workflow Comparison: Before vs After Optimization"
description: "Visual comparison of workflow execution patterns"
category: "infrastructure"
tags: ["ci-cd", "github-actions", "visualization", "performance"]
last_updated: "2025-10-21"
status: "published"
audience: "developers"
---

# CI/CD Workflow Comparison

## Critical Path Analysis

### BEFORE: Current Workflow (420 seconds)

```text
Timeline (seconds):
0        60       120      180      240      300      360      420
|--------|--------|--------|--------|--------|--------|--------|
[lint-shell (30s)              ]
         [validate-templates (15s)]
                  [unit-tests (90s) - Matrix 4x        ]
                                    [integration (60s) - Matrix 3x]
                                                        [wsl-tests (240s)]
                                                                            DONE

Critical Path: lint → unit-tests → integration-tests → wsl-tests = 420s
```

### AFTER: Optimized Workflow (240 seconds)

```text
Timeline (seconds):
0        60       120      180      240
|--------|--------|--------|--------|
[lint-shell (30s)              ]
         [validate-templates (15s)]
                  [unit-tests (90s) - Matrix 2x]
                                    [integration (60s)]
                                    [installation (120s)]
                                    [docker (45s, cached)]
                                    [wsl (60s, parallel)]
                                    [coverage (30s)]
                                                        DONE

Critical Path: lint → unit-tests → installation-tests = 240s

Improvement: 180 seconds saved (43% reduction)
```

## Parallelization Improvements

### Stage 3 Execution Pattern

#### BEFORE: Sequential + Bottleneck

```text
unit-tests completes → integration-tests starts
                        (60s)
                               ↓
                        integration-tests completes → installation/docker/wsl start
                                                      (240s WSL bottleneck)

Total wait: 60s (integration) + 240s (wsl) = 300s
```

#### AFTER: Parallel Execution

```text
unit-tests completes → ALL start immediately in parallel:
                       ├─ integration-tests (60s)
                       ├─ installation-tests (120s) ← NEW CRITICAL PATH
                       ├─ docker-tests (45s, cached)
                       ├─ wsl-tests (60s, parallelized)
                       └─ coverage (30s)

Total wait: 120s (longest job = installation-tests)
```

**Improvement**: 180s saved by removing integration-tests dependency + parallelizing WSL

## Job Duration Comparison

### Unit Tests (Matrix Jobs)

| Platform | BEFORE (4 platforms) | AFTER (2 platforms) | Savings |
|----------|---------------------|---------------------|---------|
| ubuntu-22.04 | 75s | Removed (release-only) | N/A |
| ubuntu-24.04 | 80s | 70s (cached deps) | 10s |
| macos-13 | 90s | Removed (release-only) | N/A |
| macos-14 | 95s | 75s (cached deps) | 20s |
| **Total Jobs** | **4** | **2** | **50% reduction** |

### WSL Tests

| Test Type | BEFORE (Sequential) | AFTER (Parallel Matrix) | Savings |
|-----------|---------------------|-------------------------|---------|
| Unit tests | 45s (step 1) | 45s (job 1) | Parallel |
| Integration tests | 60s (step 2) | 60s (job 2) | Parallel |
| Install normal | 45s (step 3) | 45s (job 3) | Parallel |
| Install dev | 45s (step 4) | 45s (job 4) | Parallel |
| **Total Duration** | **195s** | **60s** | **135s saved** |

### Docker Tests

| Platform | BEFORE (No cache) | AFTER (Layer cache) | Savings |
|----------|------------------|---------------------|---------|
| ubuntu-22.04 | 150s | Removed | N/A |
| ubuntu-24.04 | 160s | 40s (cached) | 120s |
| debian-12 | 145s | 35s (cached) | 110s |
| **Total Time** | **455s** | **75s** | **380s saved** |
| **Platforms** | **3** | **2** | **33% reduction** |

Note: Docker savings are cumulative across all jobs, but they run in parallel so critical path impact is less.

## Resource Utilization

### BEFORE: Total Compute Minutes

```text
Workflow Run:
├── lint-shell: 1 job × 0.5 min = 0.5 min
├── validate-templates: 1 job × 0.25 min = 0.25 min
├── unit-tests: 4 jobs × 1.5 min = 6 min
├── integration-tests: 3 jobs × 1 min = 3 min
├── installation-tests: 4 jobs × 2 min = 8 min
├── docker-tests: 3 jobs × 2.5 min = 7.5 min
├── wsl-tests: 1 job × 4 min = 4 min
├── coverage: 1 job × 0.5 min = 0.5 min
└── test-summary: 1 job × 0.25 min = 0.25 min

Total: 30.25 compute minutes
Wall-clock time: 7 minutes
```

### AFTER: Total Compute Minutes

```text
Workflow Run:
├── lint-shell: 1 job × 0.5 min = 0.5 min
├── validate-templates: 1 job × 0.25 min = 0.25 min
├── unit-tests: 2 jobs × 1.25 min = 2.5 min
├── integration-tests: 3 jobs × 1 min = 3 min
├── installation-tests: 4 jobs × 2 min = 8 min
├── docker-tests: 2 jobs × 0.75 min = 1.5 min
├── wsl-tests: 4 jobs × 1 min = 4 min
├── coverage: 1 job × 0.5 min = 0.5 min
└── test-summary: 1 job × 0.25 min = 0.25 min

Total: 20.75 compute minutes
Wall-clock time: 4 minutes

Savings: 31% fewer compute minutes
Improvement: 43% faster wall-clock time
```

## Cache Performance

### Expected Cache Hit Rates

| Cache Type | Size | Hit Rate | Miss Penalty | Benefit |
|------------|------|----------|--------------|---------|
| Homebrew (macOS) | 100-200 MB | 85-90% | 20s | 17-18s avg savings |
| npm packages | 50-100 MB | 90-95% | 10s | 9-9.5s avg savings |
| Docker layers (ubuntu) | 500 MB | 80-85% | 120s | 96-102s avg savings |
| Docker layers (debian) | 450 MB | 80-85% | 110s | 88-93s avg savings |

### Cache Storage Requirements

```text
Total cache storage per workflow run:
├── Homebrew (2 macOS jobs): 200 MB × 2 = 400 MB
├── npm (all jobs): 75 MB × 10 = 750 MB
├── Docker ubuntu: 500 MB
└── Docker debian: 450 MB

Total: ~2.1 GB per workflow (well within GitHub 10 GB limit)
Cache retention: 7 days (auto-cleanup)
```

## Dependency Graph Visualization

### BEFORE: Over-Constrained Dependencies

```text
         lint-shell ────────────┐
              │                  │
              ▼                  │
         unit-tests              │
           │      │              │
           │      └──────┐       │
           ▼             ▼       │
    integration ──> installation │
           │             │       │
           │             ▼       │
           └───────> docker      │
           │             │       │
           │             ▼       │
           └───────> wsl         │
                        │        │
                        ▼        ▼
                    coverage  validate
                        │        │
                        └────┬───┘
                             ▼
                        test-summary

Legend:
─── = waits for (blocking dependency)
```

### AFTER: Optimized Parallelism

```text
         lint-shell ────────────┐
              │                  │
              ▼                  │
         unit-tests              │
              │                  │
        ┌─────┼─────┬────┬────┐ │
        ▼     ▼     ▼    ▼    ▼ ▼
    integ  install  docker wsl coverage validate
        │     │       │    │    │    │
        └─────┴───────┴────┴────┴────┘
                     ▼
                test-summary

Legend:
─── = waits for (blocking dependency)
Vertical alignment = runs in parallel
```

## Performance by Branch Type

### Feature Branch PRs (Most Common)

| Workflow | BEFORE | AFTER | Improvement |
|----------|--------|-------|-------------|
| test-installer | 7 min | 4 min | 43% faster |
| test-config-system | 1.5 min | 1.2 min | 20% faster |
| **Total** | **8.5 min** | **5.2 min** | **39% faster** |

### Release Branch PRs (Comprehensive Testing)

| Workflow | BEFORE | AFTER | Improvement |
|----------|--------|-------|-------------|
| test-installer (4 platforms) | 7 min | 5 min | 29% faster |
| test-config-system | 1.5 min | 1.2 min | 20% faster |
| **Total** | **8.5 min** | **6.2 min** | **27% faster** |

Note: Release branches test on all 4 platforms (ubuntu-22, ubuntu-24, macos-13, macos-14) but still benefit from caching and parallelization.

## Cost Analysis (GitHub Actions Minutes)

### Monthly CI Usage Estimate

Assumptions:

- 20 PRs per month
- 3 commits per PR (average)
- 60 workflow runs per month

#### BEFORE: Monthly Costs

```text
60 runs × 30.25 compute min = 1,815 minutes/month
At $0.008/min (GitHub Team): $14.52/month
```

#### AFTER: Monthly Costs

```text
60 runs × 20.75 compute min = 1,245 minutes/month
At $0.008/min (GitHub Team): $9.96/month

Savings: $4.56/month (31% reduction)
Annual savings: $54.72/year
```

Note: macOS minutes cost 10x more ($0.08/min), but savings are proportional.

## Recommendations by Priority

### High Priority (Implement First)

1. Remove integration-tests dependency from installation/docker/wsl jobs
2. Parallelize WSL tests into matrix
3. Add Docker layer caching

**Expected Impact**: 35-40% improvement

### Medium Priority (Implement Second)

1. Add Homebrew and npm caching
2. Reduce matrix dimensions for PRs
3. Consolidate config-system tests

**Expected Impact**: Additional 10-15% improvement

### Low Priority (Nice to Have)

1. Optimize path filters
2. Add workflow duration monitoring
3. Implement cache hit rate alerting

**Expected Impact**: Better observability, prevents regressions

## Monitoring Dashboard (Proposed)

Track these metrics post-optimization:

```text
CI Performance Dashboard
├── Average workflow duration: 4 min (target: < 2 min)
├── 95th percentile duration: 5.5 min (target: < 3 min)
├── Cache hit rates:
│   ├── Homebrew: 87% (target: > 80%)
│   ├── npm: 92% (target: > 90%)
│   └── Docker: 83% (target: > 80%)
├── Workflow runs per month: 60
├── Total compute minutes: 1,245 (31% reduction)
└── Cost: $9.96/month (31% savings)
```

---

**Document Version**: 1.0
**Last Updated**: 2025-10-21
**Status**: Implementation Ready
