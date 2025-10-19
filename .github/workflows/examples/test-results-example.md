---
title: "Test Results Example"
description: "Example output from test-installer.yml workflow"
category: "ci-cd"
tags: ["testing", "github-actions", "examples"]
last_updated: "2025-10-18"
status: "published"
audience: "developers"
---

# Test Results Example

This document shows example output from the `test-installer.yml` GitHub Actions workflow.

## GitHub Actions Summary

### Workflow Run Summary

```text
Installer Tests - All jobs completed
✅ 8 successful jobs
⏱️  Duration: 9m 23s
```

### Job Matrix

| Job | Platform/Scenario | Duration | Status |
|-----|------------------|----------|--------|
| lint-shell | ubuntu-latest | 45s | ✅ |
| validate-templates | ubuntu-latest | 32s | ✅ |
| unit-tests | ubuntu-22.04 | 1m 12s | ✅ |
| unit-tests | ubuntu-24.04 | 1m 18s | ✅ |
| unit-tests | macos-13 | 2m 34s | ✅ |
| unit-tests | macos-14 | 2m 28s | ✅ |
| integration-tests | fresh-install | 1m 45s | ✅ |
| integration-tests | upgrade-v0.1 | 1m 52s | ✅ |
| integration-tests | upgrade-with-content | 1m 48s | ✅ |
| installation-tests | ubuntu-22.04 normal | 1m 23s | ✅ |
| installation-tests | ubuntu-22.04 dev | 1m 19s | ✅ |
| installation-tests | macos-13 normal | 2m 45s | ✅ |
| installation-tests | macos-13 dev | 2m 41s | ✅ |
| docker-tests | ubuntu-22.04 | 2m 15s | ✅ |
| docker-tests | ubuntu-24.04 | 2m 18s | ✅ |
| docker-tests | debian-12 | 2m 12s | ✅ |
| coverage | ubuntu-latest | 1m 05s | ✅ |
| test-summary | ubuntu-latest | 15s | ✅ |

## Unit Test Output

### Example: test_prompts.bats (ubuntu-22.04)

```text
tests/unit/test_prompts.bats
 ✓ prompt_yes_no accepts 'y' as yes
 ✓ prompt_yes_no accepts 'Y' as yes
 ✓ prompt_yes_no accepts 'yes' as yes
 ✓ prompt_yes_no accepts 'n' as no
 ✓ prompt_yes_no accepts empty input with default
 ✓ prompt_input validates non-empty input
 ✓ prompt_input rejects empty input
 ✓ prompt_select validates selection in range
 ✓ prompt_select rejects out-of-range selection
 ✓ prompt_multiselect accepts multiple selections
 ✓ prompt_path validates existing paths
 ✓ prompt_path expands tilde paths
 ✓ prompt_confirm accepts confirmation

13 tests, 0 failures in 2.3s
```

### Example: test_config.bats (macos-13)

```text
tests/unit/test_config.bats
 ✓ get_config loads valid JSON
 ✓ get_config handles missing file
 ✓ get_config_value extracts nested values
 ✓ write_user_config creates valid JSON
 ✓ write_user_config preserves formatting
 ✓ validate_config passes valid config
 ✓ validate_config rejects invalid config

7 tests, 0 failures in 1.8s
```

## Integration Test Output

### Example: upgrade-v0.1 scenario

```text
tests/integration/test_upgrade_scenarios.bats
 ✓ upgrade from v0.1.5 preserves user content
 ✓ upgrade from v0.1.5 migrates deprecated templates
 ✓ upgrade from v0.1.5 updates config format
 ✓ upgrade from v0.1.5 maintains namespace isolation
 ✓ upgrade creates backup before migration
 ✓ upgrade handles missing optional directories

6 tests, 0 failures in 4.2s
```

## Installation Test Output

### Example: ubuntu-22.04 normal mode

```text
✓ ~/.aida exists
✓ ~/.claude exists
✓ CLAUDE.md exists
✓ Normal mode: lib is copied
✓ Upgrade preserved ~/.aida

Installation verified successfully!
```

### Example: macos-13 dev mode

```text
✓ ~/.aida exists
✓ ~/.claude exists
✓ CLAUDE.md exists
✓ Dev mode: lib is symlinked
  -> lib -> /Users/runner/work/claude-personal-assistant/lib
✓ Upgrade preserved ~/.aida

Installation verified successfully!
```

## Docker Test Output

### Example: ubuntu-22.04 container

```text
Building Docker image: aida-test:ubuntu-22.04
[+] Building 45.2s (8/8) FINISHED
 => [1/3] FROM ubuntu:22.04
 => [2/3] RUN apt-get update && apt-get install -y bash git rsync jq bats
 => [3/3] RUN useradd -m -s /bin/bash testuser
 => exporting to image

Running tests in container...
make test-all
  ✓ All unit tests passed (26 tests)
  ✓ All integration tests passed (6 tests)

Testing installation in container...
  ✓ Installation completed successfully
  ✓ All files created
  ✓ Configuration valid

Container tests completed successfully!
```

## Coverage Report

```text
Test Coverage Summary:

Unit Tests:
  prompts.sh:     13 tests  ✅ Complete
  config.sh:       7 tests  ✅ Complete
  directories.sh: 12 tests  ✅ Complete
  summary.sh:      8 tests  ✅ Complete
  templates.sh:   95 tests  ✅ Complete
  deprecation.sh: 33 tests  ✅ Complete

Total unit tests: 168

Integration Tests:
  Upgrade scenarios: 18 tests  ✅ Complete

Total integration tests: 18

Overall Coverage: 186 tests
Module Coverage: 100%
Platform Coverage: 6 platforms
```

## PR Comment

Automatically posted to pull requests:

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

[View detailed logs](https://github.com/oakensoul/claude-personal-assistant/pull/123/checks)
```

## Artifacts Generated

### File Structure

```text
artifacts/
├── unit-test-results-ubuntu-22.04/
│   └── test-results.tap
├── unit-test-results-ubuntu-24.04/
│   └── test-results.tap
├── unit-test-results-macos-13/
│   └── test-results.tap
├── unit-test-results-macos-14/
│   └── test-results.tap
├── integration-test-results-fresh-install/
│   └── test-results.tap
├── integration-test-results-upgrade-v0.1/
│   └── test-results.tap
├── integration-test-results-upgrade-with-content/
│   └── test-results.tap
├── integration-test-logs-upgrade-v0.1/
│   ├── migration.log
│   └── backup.log
├── installation-logs-normal-ubuntu-22.04/
│   ├── install.log
│   └── CLAUDE.md
├── installation-logs-dev-macos-13/
│   ├── install.log
│   └── CLAUDE.md
├── docker-test-logs-ubuntu-22.04/
│   └── test-results.tap
├── docker-test-logs-ubuntu-24.04/
│   └── test-results.tap
├── docker-test-logs-debian-12/
│   └── test-results.tap
└── coverage-report/
    └── coverage-report.txt
```

## Failed Test Example

If a test fails, the output shows clear diagnostics:

```text
tests/unit/test_config.bats
 ✓ get_config loads valid JSON
 ✓ get_config handles missing file
 ✗ get_config_value extracts nested values
   (in test file tests/unit/test_config.bats, line 42)
     `[ "$output" = "expected_value" ]' failed
   Expected: "expected_value"
   Actual:   "different_value"

   Stack trace:
     get_config_value() at lib/installer-common/config.sh:78
     test case at tests/unit/test_config.bats:42

3 tests, 1 failure
```

## Performance Metrics

### Execution Time by Stage

| Stage | Duration | Parallelization |
|-------|----------|-----------------|
| Lint & Validation | 45s | Sequential |
| Unit Tests | 2m 34s | 4 platforms parallel |
| Integration Tests | 1m 52s | 3 scenarios parallel |
| Installation Tests | 2m 45s | 4 configs parallel |
| Docker Tests | 2m 18s | 3 platforms parallel |
| Coverage | 1m 05s | Sequential |
| Summary | 15s | Sequential |

**Total Wall Time:** 9m 23s (with parallelization)

**Sequential Time:** ~27 minutes (if run sequentially)

**Speedup:** 2.9x with parallel matrix execution

---

**Generated:** 2025-10-18
**Workflow:** test-installer.yml v1.0
**Run ID:** 1234567890
