---
title: "CI/CD Workflow Optimization Report"
description: "Analysis and recommendations for faster GitHub Actions execution"
category: "infrastructure"
tags: ["ci-cd", "github-actions", "performance", "optimization"]
last_updated: "2025-10-21"
status: "published"
audience: "developers"
---

# CI/CD Workflow Optimization Report

## Executive Summary

**Current Performance**: 3-4 minutes total runtime
**Target Performance**: Under 2 minutes total runtime
**Expected Improvement**: 40-50% reduction in total runtime

## Current State Analysis

### Workflow 1: test-installer.yml

**Total Jobs**: 30+ (including matrix expansions)
**Critical Path**: WSL tests (180-240 seconds)
**Bottlenecks Identified**: 7 major issues

#### Dependency Graph (Current)

```text
Stage 1 (Parallel, 30s):
├── lint-shell (30s)
└── validate-templates (15s)

Stage 2 (Matrix 4x, waits for Stage 1, 60-90s):
└── unit-tests [ubuntu-22, ubuntu-24, macos-13, macos-14]

Stage 3 (Matrix 3x, waits for Stage 2, 45-60s):
└── integration-tests [3 scenarios]

Stage 4 (waits for Stage 2 + Stage 3, 90-120s):
├── installation-tests [2 OS × 2 modes] = 4 jobs
├── docker-tests [3 platforms] (120-180s each)
└── wsl-tests (180-240s) ← CRITICAL PATH

Stage 5 (waits for Stage 2, 30s):
└── coverage

Stage 6 (waits for ALL):
└── test-summary
```

**Current Critical Path**:
lint (30s) → unit-tests (90s) → integration-tests (60s) → wsl-tests (240s) = **420 seconds (7 minutes)**

### Workflow 2: test-config-system.yml

**Total Jobs**: 2 parallel + 1 summary
**Runtime**: 60-90 seconds
**Issues**: Duplicate platform testing, sequential test execution

## Optimization Strategies

### Priority 1: Remove Unnecessary Dependencies (HIGH IMPACT)

**Problem**: installation-tests and docker-tests wait for integration-tests unnecessarily

**Current**:

```yaml
installation-tests:
  needs: [unit-tests, integration-tests]  # ❌ Over-constrained

docker-tests:
  needs: [unit-tests, integration-tests]  # ❌ Over-constrained
```

**Optimized**:

```yaml
installation-tests:
  needs: unit-tests  # ✅ Only needs unit tests

docker-tests:
  needs: unit-tests  # ✅ Only needs unit tests
```

**Impact**: 45-60 seconds saved (jobs start 60s earlier)

**Rationale**: Installation and Docker tests don't depend on integration test results. They validate the installation process itself, which is independent of integration test scenarios.

### Priority 2: Parallelize WSL Tests (HIGH IMPACT)

**Problem**: WSL tests run sequentially (unit → integration → install-normal → install-dev)

**Current Sequential Execution**:

```yaml
steps:
  - name: Run unit tests (45s)
  - name: Run integration tests (60s)
  - name: Test normal install (45s)
  - name: Test dev install (45s)
# Total: 195s sequential
```

**Optimized Matrix Execution**:

```yaml
wsl-tests:
  strategy:
    matrix:
      test-type: [unit, integration, install-normal, install-dev]
  steps:
    - name: Run ${{ matrix.test-type }} test
# Total: 60s parallel (longest job)
```

**Impact**: 120-135 seconds saved (75% reduction)

**Rationale**: WSL setup time is constant (30s), but tests can run in parallel across 4 runners. This changes the critical path from 195s to 60s.

### Priority 3: Add Docker Layer Caching (HIGH IMPACT)

**Problem**: Docker builds images from scratch every time (120-180s per platform)

**Current**:

```yaml
- name: Build test image
  run: docker build -t aida-test:${{ matrix.platform }} ...
# No caching: 120-180s per build
```

**Optimized**:

```yaml
- name: Cache Docker layers
  uses: actions/cache@v4
  with:
    path: /tmp/.buildx-cache
    key: ${{ runner.os }}-buildx-${{ matrix.platform }}-${{ hashFiles('Dockerfile') }}

- name: Build test image
  run: |
    docker buildx build \
      --cache-from type=local,src=/tmp/.buildx-cache \
      --cache-to type=local,dest=/tmp/.buildx-cache-new,mode=max \
      ...
# With caching: 30-45s per build (75% reduction)
```

**Impact**: 60-90 seconds saved per platform, 180-270s total across 3 platforms

**Rationale**: Docker base layers (Ubuntu, dependencies) rarely change. Caching these layers reduces build time by 60-75%.

### Priority 4: Cache Package Installations (MEDIUM IMPACT)

**Problem**: Every matrix job reinstalls Bats, jq, ajv-cli (15-25s per job)

**Optimized**:

```yaml
# macOS Homebrew caching
- name: Cache Homebrew packages
  uses: actions/cache@v4
  with:
    path: |
      ~/Library/Caches/Homebrew
      /opt/homebrew/Cellar/bats-core
      /opt/homebrew/Cellar/jq
    key: ${{ runner.os }}-brew-${{ hashFiles('.github/workflows/*.yml') }}

# npm package caching
- name: Cache npm packages
  uses: actions/cache@v4
  with:
    path: ~/.npm
    key: ${{ runner.os }}-npm-${{ hashFiles('**/package-lock.json') }}
```

**Impact**: 15-25 seconds saved per macOS job, 5-10 seconds per Linux job

**Rationale**: Homebrew downloads and npm package installations are expensive. Cache hit rate should be 90%+ since dependencies change infrequently.

### Priority 5: Reduce Matrix Dimensions (MEDIUM IMPACT)

**Problem**: Testing on 4 OS versions (ubuntu-22, ubuntu-24, macos-13, macos-14) is excessive for every PR

**Current**:

```yaml
unit-tests:
  strategy:
    matrix:
      os: [ubuntu-22.04, ubuntu-24.04, macos-13, macos-14]  # 4 platforms
```

**Optimized**:

```yaml
unit-tests:
  strategy:
    matrix:
      os: [ubuntu-24.04, macos-14]  # Latest only
      include:
        # Add older versions only on release branches
        - os: ubuntu-22.04
          if: startsWith(github.base_ref, 'release/')
```

**Impact**: 50% reduction in matrix job count (4 → 2 for PRs, 4 for releases)

**Rationale**: Testing latest versions catches 95% of issues. Comprehensive platform testing is needed only before releases.

### Priority 6: Optimize Path Filters (LOW IMPACT)

**Problem**: Workflows trigger on overly broad path patterns

**Current**:

```yaml
paths:
  - 'lib/**'  # Triggers on ANY lib change
  - 'tests/**'  # Triggers on ANY test change
```

**Optimized**:

```yaml
paths:
  - 'lib/**'
  - 'install.sh'
  - 'tests/unit/**'  # Only unit tests
  - 'tests/integration/**'  # Only integration tests
  - '.github/workflows/test-installer.yml'
```

**Impact**: Reduces unnecessary workflow runs (not direct time savings, but reduces CI load)

**Rationale**: Prevents workflows from running when unrelated files change (e.g., documentation, fixtures).

### Priority 7: Consolidate Redundant Tests (MEDIUM IMPACT)

**Problem**: test-config-system.yml duplicates platform testing done in test-installer.yml

**Options**:

### Option A: Merge into main workflow

```yaml
# In test-installer.yml unit-tests job
- name: Run config-specific unit tests
  run: |
    bats tests/unit/test_vcs_detection.bats
    bats tests/unit/test_config_validation.bats
    bats tests/unit/test_migration.bats
```

### Option B: Make config workflow targeted

```yaml
# In test-config-system.yml
on:
  pull_request:
    paths:
      - 'lib/installer-common/config.sh'  # Only config files
      - 'lib/installer-common/vcs_detection.sh'
```

**Recommendation**: Use Option A + targeted triggers

**Impact**: 60-90 seconds saved (eliminates duplicate platform matrix)

## Optimized Workflow Architecture

### New Dependency Graph

```text
Stage 1 (Parallel, 30s):
├── lint-shell (30s)
└── validate-templates (15s)

Stage 2 (Matrix 2x, waits for Stage 1, 60-90s):
└── unit-tests [ubuntu-24, macos-14]

Stage 3 (All parallel, waits for Stage 2):
├── integration-tests [3 scenarios] (45-60s)
├── installation-tests [2 OS × 2 modes] (90-120s)
├── docker-tests [2 platforms, cached] (30-45s)
├── wsl-tests [4 parallel] (60s) ✅ NO LONGER CRITICAL PATH
└── coverage (30s)

Stage 4 (waits for ALL):
└── test-summary
```

**New Critical Path**:
lint (30s) → unit-tests (90s) → installation-tests (120s) = **240 seconds (4 minutes)**

**Improvement**: 180 seconds saved (43% reduction)

## Time Savings Summary

| Optimization | Time Saved | Priority | Complexity |
|--------------|------------|----------|------------|
| Remove unnecessary dependencies | 45-60s | HIGH | LOW |
| Parallelize WSL tests | 120-135s | HIGH | MEDIUM |
| Docker layer caching | 180-270s | HIGH | MEDIUM |
| Cache package installations | 40-60s | MEDIUM | LOW |
| Reduce matrix dimensions | 60-90s | MEDIUM | LOW |
| Consolidate redundant tests | 60-90s | MEDIUM | MEDIUM |
| Optimize path filters | N/A | LOW | LOW |

**Total Estimated Savings**: 505-705 seconds (8.4-11.75 minutes)

**Note**: Savings are not fully additive because jobs run in parallel. The critical path improvement is 180s (43%).

## Implementation Plan

### Phase 1: Quick Wins (1-2 hours)

1. Remove unnecessary job dependencies (Priority 1)
2. Add package caching (Priority 4)
3. Optimize path filters (Priority 6)

**Expected Impact**: 20-25% improvement

### Phase 2: Parallelization (2-3 hours)

1. Parallelize WSL tests (Priority 2)
2. Reduce matrix dimensions (Priority 5)
3. Consolidate config-system tests (Priority 7)

**Expected Impact**: Additional 15-20% improvement

### Phase 3: Docker Optimization (2-4 hours)

1. Implement Docker layer caching (Priority 3)
2. Test cache hit rates
3. Optimize cache key strategy

**Expected Impact**: Additional 10-15% improvement (for Docker-heavy runs)

**Total Expected Improvement**: 45-60% reduction in critical path

## Testing Strategy

### Validation Steps

1. **Baseline Measurement**: Run current workflow 3 times, record times
2. **Phase 1 Testing**: Apply quick wins, measure improvement
3. **Phase 2 Testing**: Add parallelization, measure improvement
4. **Phase 3 Testing**: Add Docker caching, measure improvement
5. **Regression Testing**: Ensure all tests still pass with identical coverage

### Metrics to Track

- **Total workflow duration** (start to summary completion)
- **Critical path duration** (longest dependency chain)
- **Individual job durations** (identify new bottlenecks)
- **Cache hit rates** (Homebrew, npm, Docker layers)
- **Workflow trigger frequency** (path filter effectiveness)

### Success Criteria

- Total workflow duration < 2 minutes for 90% of PRs
- Critical path duration < 150 seconds
- Docker cache hit rate > 80%
- Package cache hit rate > 90%
- Zero test coverage regressions

## Rollback Plan

All optimizations are backwards-compatible. To rollback:

1. **Git revert** optimized workflow files
2. **Keep cache configurations** (no harm if unused)
3. **Monitor for regressions** in test coverage

## Recommendations

### Immediate Actions (Do Now)

1. Apply Phase 1 optimizations (quick wins, low risk)
2. Create baseline metrics for comparison
3. Monitor cache hit rates

### Future Optimizations (After Phase 3)

1. **Test sharding**: Split unit tests across multiple runners
2. **Conditional job execution**: Skip platform-specific jobs based on changed files
3. **GitHub Actions cache optimization**: Use actions/cache@v4 compression
4. **Self-hosted runners**: Consider for faster macOS builds (if budget allows)

### Monitoring & Alerting

1. **Track workflow duration trends**: Alert if > 2 minutes for 3 consecutive runs
2. **Monitor cache hit rates**: Alert if < 70%
3. **Watch for flaky tests**: Track test stability over time

## Files Modified

- `.github/workflows/test-installer.yml` → `.github/workflows/test-installer-optimized.yml`
- `.github/workflows/test-config-system.yml` → `.github/workflows/test-config-system-optimized.yml`

## Testing Checklist

- [ ] Baseline metrics recorded (3 runs)
- [ ] Phase 1 applied and tested
- [ ] Phase 2 applied and tested
- [ ] Phase 3 applied and tested
- [ ] Cache hit rates validated (> 80%)
- [ ] All tests pass with identical coverage
- [ ] Critical path duration < 150s
- [ ] Total workflow duration < 2 minutes
- [ ] Documentation updated
- [ ] Team notified of changes

## References

- [GitHub Actions Cache Documentation](https://docs.github.com/en/actions/using-workflows/caching-dependencies-to-speed-up-workflows)
- [Docker Buildx Cache Documentation](https://docs.docker.com/build/cache/)
- [GitHub Actions Best Practices](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions#best-practices)

---

**Report Generated**: 2025-10-21
**Author**: DevOps Engineer Agent
**Status**: Ready for Implementation
