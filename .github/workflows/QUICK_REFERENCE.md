---
title: "GitHub Actions Quick Reference"
description: "Quick reference for AIDA CI/CD workflows"
category: "ci-cd"
tags: ["github-actions", "quick-reference", "cheat-sheet"]
last_updated: "2025-10-18"
status: "published"
audience: "developers"
---

# GitHub Actions Quick Reference

Quick reference guide for AIDA framework CI/CD workflows.

## Workflows at a Glance

```text
┌─────────────────┬──────────────────────┬──────────┐
│ Workflow        │ Purpose              │ Duration │
├─────────────────┼──────────────────────┼──────────┤
│ Lint            │ Code quality         │ ~1 min   │
│ Installer Tests │ Unit/Integration     │ ~9 min   │
│ Installation    │ End-to-end           │ ~6 min   │
└─────────────────┴──────────────────────┴──────────┘
```

## Common Commands

### Run Tests Locally

```bash
# Quick validation
make ci-fast                  # Lint + unit tests (~2 min)

# Full test suite
make ci                       # All checks (~5 min local)

# Specific tests
make test-unit               # Unit tests only
make test-integration        # Integration tests only
make lint                    # Linting only
make validate                # Template validation
```

### Manual Workflow Trigger

```bash
# Trigger specific workflow
gh workflow run test-installer.yml

# Trigger on branch
gh workflow run test-installer.yml --ref feature-branch

# View workflow runs
gh run list --workflow=test-installer.yml

# View run details
gh run view <run-id>

# Download artifacts
gh run download <run-id>
```

### Check Workflow Status

```bash
# List recent runs
gh run list

# Watch active run
gh run watch

# View logs
gh run view <run-id> --log

# Re-run failed jobs
gh run rerun <run-id> --failed
```

## Workflow Triggers

### Lint Workflow

**Triggers:**

- Push to `main` or `develop`
- PR to `main` or `develop`

**Skipped when:** Only documentation changes

### Installer Tests Workflow

**Triggers:**

- Push to `main` or `milestone-*`
- PR to `main` or `milestone-*`
- Changes to: `lib/**`, `install.sh`, `tests/**`, `Makefile`

**Skipped when:** Only documentation or template changes

### Installation Tests Workflow

**Triggers:**

- Push to `main` or `milestone-*`
- PR to `main`
- Changes to: `install.sh`, `.github/testing/**`

**Skipped when:** Only code changes without installer modification

## Test Matrix Coverage

```text
Platform Coverage
─────────────────
ubuntu-22.04  ████████████████ Unit, Integration, Install, Docker
ubuntu-24.04  ████████░░░░░░░░ Unit, Docker
macos-13      ████████████░░░░ Unit, Install
macos-14      ████░░░░░░░░░░░░ Unit only
debian-12     ████░░░░░░░░░░░░ Docker only
WSL (Win)     ████████████████ Unit, Integration, Install (Ubuntu 22.04 on Windows)
```

## Artifacts Reference

### Unit Test Results

```text
Location: unit-test-results-{platform}/
Retention: 7 days
Format: TAP (Test Anything Protocol)
Size: ~50 KB per platform
```

### Integration Test Results

```text
Location: integration-test-results-{scenario}/
Retention: 7 days
Format: TAP + logs
Size: ~100 KB per scenario
```

### Installation Logs

```text
Location: installation-logs-{mode}-{platform}/
Retention: 7 days
Format: Plain text logs + CLAUDE.md
Size: ~20 KB
```

### Coverage Report

```text
Location: coverage-report/
Retention: 30 days
Format: Plain text summary
Size: ~5 KB
```

## Debugging Failed Workflows

### Step 1: Identify Failure

```bash
# View recent failures
gh run list --workflow=test-installer.yml --status=failure

# View specific run
gh run view <run-id>
```

### Step 2: Download Artifacts

```bash
# Download all artifacts
gh run download <run-id>

# Download specific artifact
gh run download <run-id> -n unit-test-results-ubuntu-22.04
```

### Step 3: Reproduce Locally

```bash
# Run same test locally
make test-unit

# Run in Docker (same as CI)
docker build -t test -f .github/testing/Dockerfile.ubuntu-22.04 .github/testing/
docker run --rm -v $(pwd):/workspace -w /workspace test make test-unit
```

### Step 4: Check Logs

```bash
# View detailed logs
gh run view <run-id> --log

# View specific job
gh run view <run-id> --job=<job-id> --log
```

## Performance Optimization

### Workflow Duration

```text
Lint Workflow
─────────────
Sequential execution
1 job × 1 min = ~1 min total

Installer Tests Workflow
─────────────────────────
Parallel matrix execution
  Unit tests:        4 platforms × 2.5 min = ~2.5 min (parallel)
  Integration:       3 scenarios × 1.8 min = ~1.8 min (parallel)
  Installation:      4 configs × 2.5 min   = ~2.5 min (parallel)
  Docker:            3 platforms × 2.2 min = ~2.2 min (parallel)
  WSL:               1 platform × 3.5 min  = ~3.5 min (setup + tests)

Total: ~10 min (with parallelization)
      vs ~30 min (sequential)
Speedup: 3x

Installation Tests Workflow
────────────────────────────
Parallel matrix execution
3 platforms × 2 min = ~6 min total
```

### Cache Optimization

**Docker Layer Caching:**

- First build: ~2 min (download base images)
- Cached builds: ~30s (reuse layers)
- Cache hit rate: >90%

**Dependency Caching:**

- Bats installation: cached in base image
- No npm/pip dependencies: not applicable

## Status Badges

Add to your README.md:

```markdown
[![Lint](https://github.com/oakensoul/claude-personal-assistant/workflows/Lint/badge.svg)](https://github.com/oakensoul/claude-personal-assistant/actions/workflows/lint.yml)

[![Installer Tests](https://github.com/oakensoul/claude-personal-assistant/workflows/Installer%20Tests/badge.svg)](https://github.com/oakensoul/claude-personal-assistant/actions/workflows/test-installer.yml)

[![Installation Tests](https://github.com/oakensoul/claude-personal-assistant/workflows/Installation%20Tests/badge.svg)](https://github.com/oakensoul/claude-personal-assistant/actions/workflows/test-installation.yml)
```

## PR Integration

### Automatic Checks

When you open a PR:

1. ✅ Lint runs immediately
2. ✅ Installer tests run if lib/ or tests/ changed
3. ✅ Installation tests run if install.sh changed
4. 💬 Test summary posted as comment
5. 🔒 Merge blocked if tests fail

### PR Comment Format

```markdown
## 🧪 Installer Test Results

| Stage | Status |
|-------|--------|
| Shell Linting | ✅ |
| Template Validation | ✅ |
| Unit Tests | ✅ |
| Integration Tests | ✅ |
| Installation Tests | ✅ |
| Docker Tests | ✅ |

**Overall Status:** ✅ All tests passed!
```

## Troubleshooting

### Tests Pass Locally but Fail in CI

**Common causes:**

1. **Platform differences**
   - Local: macOS, CI: Ubuntu
   - Solution: Run in Docker locally

2. **Bash version differences**
   - Local: Bash 5.x, CI: Bash 4.x
   - Solution: Check bash compatibility

3. **Tool version differences**
   - Local: newer jq/bats, CI: older versions
   - Solution: Match CI versions locally

### Slow Test Runs

**Solutions:**

1. **Skip unnecessary platforms**
   - Remove matrix entries not needed
   - Example: Only test on ubuntu-22.04 for quick feedback

2. **Use fail-fast**
   - Stop on first failure
   - Add `fail-fast: true` to strategy

3. **Split into separate workflows**
   - Quick checks: lint + unit tests
   - Full suite: integration + installation

### Flaky Tests

**Identify:**

```bash
# Re-run workflow multiple times
for i in {1..5}; do
  gh workflow run test-installer.yml
done

# Check for inconsistent results
gh run list --workflow=test-installer.yml --limit=10
```

**Fix:**

1. Add retries to flaky operations
2. Increase timeouts
3. Improve test isolation

## Best Practices

### Before Committing

```bash
# Run fast checks
make ci-fast

# Run full suite
make ci

# Validate specific changes
make test-unit     # if lib/ changed
make test-integration  # if install.sh changed
make lint          # always
```

### Writing New Tests

1. **Test locally first**

   ```bash
   bats tests/unit/test_new_module.bats
   ```

2. **Verify in Docker**

   ```bash
   docker run --rm -v $(pwd):/workspace -w /workspace \
     aida-test:ubuntu-22.04 bats tests/unit/test_new_module.bats
   ```

3. **Check CI passes**
   - Push to branch
   - Verify workflow succeeds

### Updating Workflows

1. **Test workflow syntax**

   ```bash
   yamllint --strict .github/workflows/test-installer.yml
   ```

2. **Use workflow_dispatch for testing**
   - Trigger manually
   - Verify changes work
   - Merge to main

3. **Monitor first production run**
   - Watch logs carefully
   - Fix any issues immediately

## Quick Links

- [Full Workflow Documentation](README.md)
- [Test Suite Overview](../../tests/README.md)
- [Unit Testing Guide](../../docs/testing/UNIT_TESTING.md)
- [Bats Setup](../../docs/testing/BATS_SETUP.md)
- [GitHub Actions Docs](https://docs.github.com/en/actions)

---

**Last Updated:** 2025-10-18
**Version:** 1.0
