---
title: "Test Results Directory"
description: "Runtime test results from Docker-based upgrade testing"
category: "testing"
tags: ["testing", "results", "artifacts"]
last_updated: "2024-10-18"
status: "published"
audience: "developers"
---

# Test Results Directory

This directory contains test outputs generated during Docker-based upgrade testing.

## Contents

Test results are created at runtime and may include:

### TAP Test Results

- `fresh-install-tests.tap` - Fresh installation test results
- `upgrade-tests.tap` - Upgrade scenario test results
- `migration-tests.tap` - Migration test results
- `dev-mode-tests.tap` - Dev mode test results

### Migration Artifacts

- `pre-migration-tree.txt` - Directory structure before migration
- `post-migration-tree.txt` - Directory structure after migration
- `pre-migration-checksums.txt` - File checksums before migration
- `post-migration-checksums.txt` - File checksums after migration

### Debug Outputs

- `*.log` - Test execution logs
- `*.debug` - Debug output files

## Usage

Results are automatically created when running Docker tests:

```bash
# Run tests (creates results automatically)
docker-compose --profile full run --rm test-all

# View results
cat results/fresh-install-tests.tap
cat results/upgrade-tests.tap
```

## Cleanup

Results are gitignored and can be safely deleted:

```bash
# Clean all results
rm -rf results/*

# Preserve gitignore and README
rm -rf results/*.tap results/*.txt results/*.log
```

## CI/CD

In CI/CD environments, these results are uploaded as artifacts:

```yaml
- name: Upload test results
  uses: actions/upload-artifact@v3
  with:
    name: test-results
    path: .github/testing/results/
```

## See Also

- [DOCKER_TESTING.md](../DOCKER_TESTING.md) - Docker testing guide
- [test_upgrade_scenarios.bats](../../tests/integration/test_upgrade_scenarios.bats) - Integration tests
