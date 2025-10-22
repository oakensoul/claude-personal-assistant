---
title: "CI/CD Optimization Implementation Guide"
description: "Step-by-step guide to implement workflow optimizations"
category: "infrastructure"
tags: ["ci-cd", "github-actions", "implementation", "guide"]
last_updated: "2025-10-21"
status: "published"
audience: "developers"
---

# CI/CD Optimization Implementation Guide

## Quick Start

This guide provides step-by-step instructions to implement the CI/CD optimizations analyzed in [ci-cd-optimization-report.md](ci-cd-optimization-report.md).

## Prerequisites

- Access to GitHub repository settings
- Permissions to modify GitHub Actions workflows
- Baseline metrics from current workflow runs

## Implementation Phases

### Phase 1: Quick Wins (1-2 hours)

**Estimated Improvement**: 20-25%
**Risk Level**: LOW
**Rollback Ease**: HIGH

#### Step 1.1: Remove Unnecessary Dependencies (15 minutes)

**File**: `.github/workflows/test-installer.yml`

**Changes**:

```diff
  installation-tests:
    name: Installation Test (${{ matrix.mode }} mode, ${{ matrix.os }})
    runs-on: ${{ matrix.os }}
-   needs: [unit-tests, integration-tests]
+   needs: unit-tests
    strategy:

  docker-tests:
    name: Docker Tests (${{ matrix.platform }})
    runs-on: ubuntu-latest
-   needs: [unit-tests, integration-tests]
+   needs: unit-tests
    strategy:

  wsl-tests:
    name: WSL Tests (Ubuntu on Windows)
    runs-on: windows-latest
-   needs: [unit-tests, integration-tests]
+   needs: unit-tests
    steps:
```

**Expected Impact**: 45-60 seconds saved

**Validation**:

```bash
# After merging PR, check workflow graph
gh run view --web
# Verify installation-tests starts immediately after unit-tests
```

#### Step 1.2: Add Package Caching (30 minutes)

**File**: `.github/workflows/test-installer.yml`

**Add to ALL jobs that install dependencies**:

```yaml
# For macOS jobs
- name: Cache Homebrew packages
  if: runner.os == 'macOS'
  uses: actions/cache@v4
  with:
    path: |
      ~/Library/Caches/Homebrew
      /opt/homebrew/Cellar/bats-core
      /opt/homebrew/Cellar/jq
    key: ${{ runner.os }}-brew-${{ hashFiles('.github/workflows/*.yml') }}
    restore-keys: |
      ${{ runner.os }}-brew-

# For all jobs using npm
- name: Cache npm packages
  uses: actions/cache@v4
  with:
    path: ~/.npm
    key: ${{ runner.os }}-npm-${{ hashFiles('**/package-lock.json') }}
    restore-keys: |
      ${{ runner.os }}-npm-
```

**Jobs to update**:

- `unit-tests` (add before "Install Bats" step)
- `installation-tests` (add before "Install jq" step)
- test-config-system.yml: `test-macos` and `test-linux` (add before "Install dependencies")

**Expected Impact**: 15-25 seconds per macOS job, 5-10 seconds per Linux job

**Validation**:

```bash
# Check cache hit rates in workflow logs
gh run view <run-id> --log | grep "Cache restored"
# Should see "Cache restored from key: macos-brew-xxx" on subsequent runs
```

#### Step 1.3: Optimize Path Filters (15 minutes)

**File**: `.github/workflows/test-installer.yml`

```diff
  on:
    pull_request:
      branches:
        - main
        - 'milestone-*'
      paths:
        - 'lib/**'
        - 'install.sh'
-       - 'tests/**'
+       - 'tests/unit/**'
+       - 'tests/integration/**'
        - 'Makefile'
        - '.github/workflows/test-installer.yml'
```

**File**: `.github/workflows/test-config-system.yml`

```diff
  on:
    pull_request:
      branches:
        - main
        - 'milestone-v**'
      paths:
-       - 'lib/installer-common/**'
+       - 'lib/installer-common/config.sh'
+       - 'lib/installer-common/vcs_detection.sh'
        - 'lib/aida-config-helper.sh'
        - 'tests/unit/test_vcs_detection.bats'
        - 'tests/unit/test_config_validation.bats'
        - 'tests/unit/test_migration.bats'
        - 'tests/integration/test_config_workflow.sh'
        - '.github/workflows/test-config-system.yml'
```

**Expected Impact**: Fewer unnecessary workflow runs

**Validation**:

```bash
# Create test PR with only doc changes
echo "test" >> README.md
git add README.md && git commit -m "docs: update"
git push origin test-branch
# Verify workflows don't trigger
```

#### Step 1.4: Test Phase 1 Changes (15 minutes)

```bash
# Create feature branch
git checkout -b optimize/ci-phase1

# Apply changes
git add .github/workflows/

# Commit
git commit -m "ci: Phase 1 optimizations - caching and dependency cleanup"

# Push and create PR
git push origin optimize/ci-phase1
gh pr create --title "CI Phase 1: Quick Wins" --body "..."

# Measure baseline vs optimized
# Record workflow duration in PR description
```

**Success Criteria**:

- Workflow completes in < 6 minutes (down from 7-8 minutes)
- Cache hit rate > 70% on second run
- All tests pass with identical coverage

---

### Phase 2: Parallelization (2-3 hours)

**Estimated Improvement**: 15-20% (additional)
**Risk Level**: MEDIUM
**Rollback Ease**: MEDIUM

#### Step 2.1: Parallelize WSL Tests (60 minutes)

**File**: `.github/workflows/test-installer.yml`

**Replace entire `wsl-tests` job**:

```yaml
wsl-tests:
  name: WSL Tests (${{ matrix.test-type }})
  runs-on: windows-latest
  needs: unit-tests
  strategy:
    fail-fast: false
    matrix:
      test-type: [unit, integration, install-normal, install-dev]
  steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Setup WSL
      uses: Vampire/setup-wsl@v2
      with:
        distribution: Ubuntu-22.04

    - name: Install test dependencies in WSL
      shell: wsl-bash {0}
      run: |
        sudo apt-get update -qq
        sudo apt-get install -y bats shellcheck jq make

    - name: Run ${{ matrix.test-type }} test
      shell: wsl-bash {0}
      run: |
        case "${{ matrix.test-type }}" in
          unit)
            make test-unit
            ;;
          integration)
            make test-integration
            ;;
          install-normal)
            echo -e "testassistant\n1" | ./install.sh
            test -d ~/.aida && test -d ~/.claude && test -f ~/CLAUDE.md
            ;;
          install-dev)
            echo -e "testassistant\n1" | ./install.sh --dev
            test -L ~/.claude/agents/.aida
            test -L ~/.claude/commands/.aida
            readlink ~/.claude/agents/.aida | grep -q "templates/agents"
            ;;
        esac

    - name: Upload WSL test logs
      if: always()
      uses: actions/upload-artifact@v4
      with:
        name: wsl-test-logs-${{ matrix.test-type }}
        path: tests/results/
        retention-days: 7
        if-no-files-found: ignore
```

**Expected Impact**: 120-135 seconds saved (from 195s sequential to 60s parallel)

**Validation**:

```bash
# Check that all 4 WSL jobs run in parallel
gh run view --web
# Look for 4 WSL job boxes side-by-side in workflow graph
```

#### Step 2.2: Reduce Matrix Dimensions (30 minutes)

**File**: `.github/workflows/test-installer.yml`

```diff
  unit-tests:
    name: Unit Tests (${{ matrix.os }})
    runs-on: ${{ matrix.os }}
    needs: [lint-shell, validate-templates]
    strategy:
      fail-fast: false
      matrix:
-       os: [ubuntu-22.04, ubuntu-24.04, macos-13, macos-14]
+       os: [ubuntu-24.04, macos-14]

  installation-tests:
    name: Installation Test (${{ matrix.mode }} mode, ${{ matrix.os }})
    runs-on: ${{ matrix.os }}
    needs: unit-tests
    strategy:
      fail-fast: false
      matrix:
-       os: [ubuntu-22.04, macos-13]
+       os: [ubuntu-24.04, macos-14]
        mode: [normal, dev]
```

**Expected Impact**: 50% reduction in matrix jobs for PRs

**Note**: For release branches, you can add older versions back:

```yaml
matrix:
  os: [ubuntu-24.04, macos-14]
  include:
    - os: ubuntu-22.04
      if: startsWith(github.base_ref, 'release/')
    - os: macos-13
      if: startsWith(github.base_ref, 'release/')
```

**Validation**:

```bash
# Verify only 2 unit-test jobs run for feature PRs
gh pr view <pr-number> --web
# Check Actions tab - should see 2 unit-test jobs, not 4
```

#### Step 2.3: Consolidate Config-System Tests (45 minutes)

**Option A**: Merge into test-installer.yml

Add to `unit-tests` job:

```yaml
- name: Run config-specific unit tests
  run: |
    bats tests/unit/test_vcs_detection.bats
    bats tests/unit/test_config_validation.bats
    bats tests/unit/test_migration.bats
```

Update path filters in test-config-system.yml to only trigger on config file changes:

```yaml
paths:
  - 'lib/installer-common/config.sh'
  - 'lib/installer-common/vcs_detection.sh'
  - 'lib/aida-config-helper.sh'
```

**Option B**: Use optimized config-system workflow

```bash
# Copy optimized workflow
cp .github/workflows/test-config-system-optimized.yml \
   .github/workflows/test-config-system.yml
```

**Recommendation**: Use Option A for maximum efficiency

**Expected Impact**: 60-90 seconds saved (eliminates duplicate platform testing)

#### Step 2.4: Test Phase 2 Changes (30 minutes)

```bash
# Create feature branch
git checkout -b optimize/ci-phase2

# Apply changes
git add .github/workflows/

# Commit
git commit -m "ci: Phase 2 optimizations - parallelization and matrix reduction"

# Push and create PR
git push origin optimize/ci-phase2
gh pr create --title "CI Phase 2: Parallelization" --body "..."

# Measure improvement
# Record workflow duration in PR description
```

**Success Criteria**:

- Workflow completes in < 4.5 minutes
- WSL tests complete in parallel (< 90 seconds total)
- All tests pass with identical coverage

---

### Phase 3: Docker Optimization (2-4 hours)

**Estimated Improvement**: 10-15% (additional)
**Risk Level**: MEDIUM
**Rollback Ease**: MEDIUM

#### Step 3.1: Implement Docker Layer Caching (90 minutes)

**File**: `.github/workflows/test-installer.yml`

**Update `docker-tests` job**:

```diff
  docker-tests:
    name: Docker Tests (${{ matrix.platform }})
    runs-on: ubuntu-latest
    needs: unit-tests
    strategy:
      fail-fast: false
      matrix:
        platform:
-         - ubuntu-22.04
          - ubuntu-24.04
          - debian-12
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

+     - name: Cache Docker layers
+       uses: actions/cache@v4
+       with:
+         path: /tmp/.buildx-cache
+         key: ${{ runner.os }}-buildx-${{ matrix.platform }}-${{ hashFiles('.github/testing/Dockerfile.${{ matrix.platform }}') }}
+         restore-keys: |
+           ${{ runner.os }}-buildx-${{ matrix.platform }}-
+           ${{ runner.os }}-buildx-

      - name: Build test image
        run: |
-         docker build --no-cache -t aida-test:${{ matrix.platform }} \
+         docker buildx build \
+           --cache-from type=local,src=/tmp/.buildx-cache \
+           --cache-to type=local,dest=/tmp/.buildx-cache-new,mode=max \
+           --load \
+           -t aida-test:${{ matrix.platform }} \
            -f .github/testing/Dockerfile.${{ matrix.platform }} \
            .github/testing/

+     - name: Move cache
+       run: |
+         rm -rf /tmp/.buildx-cache
+         mv /tmp/.buildx-cache-new /tmp/.buildx-cache

      - name: Run tests in container
        # ... rest unchanged
```

**Expected Impact**: 60-90 seconds per platform (first run same, subsequent runs 70% faster)

**Validation**:

```bash
# First run: Should take 120-150s per platform (no cache)
# Second run: Should take 30-45s per platform (cache hit)

# Check cache logs
gh run view <run-id> --log | grep "buildx-cache"
# Should see "Cache restored successfully" on second run
```

#### Step 3.2: Optimize Docker Build Context (30 minutes)

Create `.dockerignore` in `.github/testing/`:

```text
# .github/testing/.dockerignore
**/.git
**/.github
**/node_modules
**/tests/tmp
**/coverage
**/*.log
```

**Expected Impact**: 5-10 seconds faster build (smaller context)

#### Step 3.3: Test Phase 3 Changes (45 minutes)

```bash
# Create feature branch
git checkout -b optimize/ci-phase3

# Apply changes
git add .github/workflows/ .github/testing/.dockerignore

# Commit
git commit -m "ci: Phase 3 optimizations - Docker layer caching"

# Push and create PR
git push origin optimize/ci-phase3
gh pr create --title "CI Phase 3: Docker Optimization" --body "..."

# Test multiple times to verify caching
# First run: baseline
# Second run: should be significantly faster

# Record improvements in PR description
```

**Success Criteria**:

- First run: Similar to current (120-150s per platform)
- Second run: < 45 seconds per platform
- Cache hit rate > 80%
- All tests pass with identical coverage

---

## Validation Checklist

After each phase:

- [ ] All tests pass with identical coverage
- [ ] No new flaky tests introduced
- [ ] Workflow duration improved as expected
- [ ] Cache hit rates meet targets (if applicable)
- [ ] No regressions in test coverage
- [ ] Documentation updated
- [ ] Team notified of changes

## Rollback Procedure

If issues arise:

```bash
# Revert workflow changes
git revert <commit-hash>
git push origin <branch>

# Or restore previous workflow
git checkout HEAD~1 .github/workflows/test-installer.yml
git commit -m "ci: rollback optimizations"
git push origin <branch>
```

**Note**: Cache configurations are safe to leave in place even if workflows are reverted.

## Measuring Success

### Baseline Metrics (Before)

```bash
# Record these metrics before starting
gh run list --workflow=test-installer.yml --limit 10 --json conclusion,createdAt,updatedAt,databaseId
```

Calculate average duration:

```bash
gh run list --workflow=test-installer.yml --limit 10 --json durationMs \
  | jq -r '.[] | .durationMs' \
  | awk '{sum+=$1; count++} END {print "Average: " sum/count/1000 " seconds"}'
```

### Target Metrics (After All Phases)

| Metric | Before | Target | Actual |
|--------|--------|--------|--------|
| Average duration | 420s | 240s | ___ |
| P95 duration | 480s | 300s | ___ |
| Compute minutes | 30.25 | 20.75 | ___ |
| Cache hit rate (Homebrew) | N/A | 85% | ___ |
| Cache hit rate (npm) | N/A | 90% | ___ |
| Cache hit rate (Docker) | N/A | 80% | ___ |

## Monitoring & Alerting

### Set Up Workflow Duration Alerts

Create `.github/workflows/monitor-ci-performance.yml`:

```yaml
name: CI Performance Monitor

on:
  workflow_run:
    workflows: ["Installer Tests"]
    types: [completed]

jobs:
  monitor:
    runs-on: ubuntu-latest
    steps:
      - name: Check duration
        run: |
          DURATION=${{ github.event.workflow_run.updated_at - github.event.workflow_run.created_at }}
          if [ $DURATION -gt 300 ]; then  # 5 minutes
            echo "::warning::Workflow took ${DURATION}s (target: < 240s)"
          fi
```

### Track Cache Performance

Add to workflow summary:

```yaml
- name: Report cache performance
  if: always()
  run: |
    echo "## Cache Performance" >> $GITHUB_STEP_SUMMARY
    echo "Homebrew: ${{ steps.cache-homebrew.outputs.cache-hit }}" >> $GITHUB_STEP_SUMMARY
    echo "npm: ${{ steps.cache-npm.outputs.cache-hit }}" >> $GITHUB_STEP_SUMMARY
    echo "Docker: ${{ steps.cache-docker.outputs.cache-hit }}" >> $GITHUB_STEP_SUMMARY
```

## Troubleshooting

### Issue: Cache not hitting

**Symptoms**: Workflow still slow, cache shows "Cache not found"

**Solutions**:

```bash
# Check cache key format
gh cache list --repo <owner>/<repo>

# Verify cache key matches
# key: ${{ runner.os }}-brew-${{ hashFiles('.github/workflows/*.yml') }}

# Clear old caches if needed
gh cache delete <cache-key>
```

### Issue: WSL tests failing intermittently

**Symptoms**: Random failures in WSL matrix jobs

**Solutions**:

```yaml
# Add retry logic
- uses: nick-invision/retry@v2
  with:
    timeout_minutes: 10
    max_attempts: 3
    command: make test-unit
```

### Issue: Docker builds failing with cache

**Symptoms**: "failed to solve with frontend dockerfile.v0"

**Solutions**:

```bash
# Clear buildx cache
docker buildx prune --all

# In workflow, add fallback
- name: Build without cache (fallback)
  if: failure()
  run: |
    docker build --no-cache -t aida-test:${{ matrix.platform }} ...
```

## Resources

- [GitHub Actions Cache Documentation](https://docs.github.com/en/actions/using-workflows/caching-dependencies-to-speed-up-workflows)
- [Docker Buildx Cache Backends](https://docs.docker.com/build/cache/backends/)
- [GitHub Actions Best Practices](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)

---

**Last Updated**: 2025-10-21
**Implementation Status**: Ready
**Next Review**: After Phase 3 completion
