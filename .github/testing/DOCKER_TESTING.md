---
title: "Docker-Based Upgrade Testing"
description: "Comprehensive guide to Docker-based upgrade testing for AIDA framework"
category: "testing"
tags: ["docker", "testing", "upgrade", "ci-cd", "integration-tests"]
last_updated: "2024-10-18"
status: "published"
audience: "developers"
---

# Docker-Based Upgrade Testing

Comprehensive Docker infrastructure for testing AIDA installation, upgrade, and migration scenarios across multiple platforms.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Test Scenarios](#test-scenarios)
- [Docker Architecture](#docker-architecture)
- [Usage Examples](#usage-examples)
- [Troubleshooting](#troubleshooting)
- [CI/CD Integration](#cicd-integration)

## Overview

The Docker testing infrastructure provides:

- **Reproducible environments** - Ubuntu 22.04 LTS (primary), 24.04 LTS (future)
- **Isolated testing** - Clean environment for each test run
- **Multi-scenario support** - Fresh install, upgrade, migration, dev mode
- **Automated validation** - Runs bats integration tests
- **Fast iteration** - Efficient layer caching

### Key Features

1. **Multi-stage builds** - Optimized layer caching for fast rebuilds
2. **Non-root user** - Realistic testing as non-root user
3. **Volume mounts** - Workspace, fixtures, and results
4. **Environment configuration** - Flexible test scenarios via env vars
5. **Comprehensive logging** - Detailed output with debug mode

## Quick Start

### Prerequisites

- Docker (v20.10+)
- Docker Compose (v2.0+)
- Git

### Build Test Image

```bash
cd .github/testing
docker build -t aida-test .
```

### Run Tests

```bash
# Fresh installation test
docker run --rm -v $(pwd)/../..:/workspace aida-test fresh

# Upgrade test
docker run --rm -v $(pwd)/../..:/workspace aida-test upgrade

# All tests
docker-compose --profile full run --rm test-all
```

### Quick Test with docker-compose

```bash
# Fresh install
docker-compose --profile fresh run --rm fresh-install

# Upgrade scenario
docker-compose --profile upgrade run --rm upgrade

# Migration test
docker-compose --profile migration run --rm migration

# Dev mode test
docker-compose --profile dev run --rm dev-mode

# All scenarios
docker-compose --profile full run --rm test-all
```

## Test Scenarios

### 1. Fresh Installation (`fresh`)

Tests clean installation on fresh system.

**What it tests:**

- AIDA installation from scratch
- Namespace directory creation (`.aida/`)
- Config file generation
- CLAUDE.md creation
- Symlink setup

**Environment:**

```bash
TEST_SCENARIO=fresh
INSTALL_MODE=normal
```

**Expected results:**

- `~/.aida` symlink created
- `~/.claude/` directory structure created
- `~/.claude/commands/.aida/` namespace exists
- `~/.claude/agents/.aida/` namespace exists
- `~/.claude/skills/.aida/` namespace exists
- `~/CLAUDE.md` generated

### 2. Upgrade Test (`upgrade`)

Tests upgrade from v0.1.x to v0.2.x.

**What it tests:**

- User content preservation during upgrade
- Namespace migration (flat → `.aida/`)
- Config format migration
- AIDA template updates
- User file checksum validation

**Environment:**

```bash
TEST_SCENARIO=upgrade
INSTALL_MODE=normal
```

**Expected results:**

- All user content preserved (checksums match)
- New namespace structure created
- Old user files remain outside `.aida/`
- Config migrated to v0.2.x format

### 3. Migration Test (`migration`)

Tests complex migration scenarios with nested user content.

**What it tests:**

- Complex nested directory preservation
- Special characters in filenames
- Hidden files preservation
- Symlinks preservation
- File permissions preservation
- Timestamp preservation

**Environment:**

```bash
TEST_SCENARIO=migration
INSTALL_MODE=normal
WITH_DEPRECATED=true
```

**Expected results:**

- All user content preserved with original metadata
- Namespace structure created alongside user content
- Pre/post migration trees captured in results

### 4. Dev Mode Test (`dev-mode`)

Tests installation in development mode with symlinks.

**What it tests:**

- Dev mode symlink creation
- Template live-editing capability
- User content copied (not symlinked)
- Mode switching (normal → dev)

**Environment:**

```bash
TEST_SCENARIO=dev-mode
INSTALL_MODE=dev
```

**Expected results:**

- Templates symlinked from repository
- User content copied (not symlinked)
- Config indicates dev mode

### 5. All Tests (`test-all`)

Runs all scenarios in sequence.

**What it tests:**

- Complete test suite validation
- Scenario isolation verification
- Cleanup between scenarios

**Environment:**

```bash
TEST_SCENARIO=test-all
```

## Docker Architecture

### Multi-Stage Build

```dockerfile
Stage 1: Base environment (Ubuntu + system deps)
  ↓
Stage 2: Test environment (bats, shellcheck, jq)
  ↓
Stage 3: Upgrade testing (AIDA paths, entrypoint)
```

### Volume Mounts

| Mount Point | Purpose | Access |
|-------------|---------|--------|
| `/workspace` | AIDA repository | Read-only |
| `/test-fixtures` | Test fixtures | Read-only |
| `/test-results` | Test outputs | Read-write |

### Environment Variables

#### Test Configuration

| Variable | Default | Options | Description |
|----------|---------|---------|-------------|
| `TEST_SCENARIO` | `fresh` | `fresh`, `upgrade`, `migration`, `dev-mode`, `test-all` | Test scenario to run |
| `INSTALL_MODE` | `normal` | `normal`, `dev` | Installation mode |
| `WITH_DEPRECATED` | `false` | `true`, `false` | Include deprecated templates |
| `DEBUG` | `false` | `true`, `false` | Enable debug output |
| `VERBOSE` | `false` | `true`, `false` | Enable verbose output |

#### AIDA Paths

| Variable | Default | Description |
|----------|---------|-------------|
| `AIDA_HOME` | `/home/testuser/.aida` | AIDA installation directory |
| `CLAUDE_CONFIG_DIR` | `/home/testuser/.claude` | Claude config directory |
| `HOME` | `/home/testuser` | User home directory |

## Usage Examples

### Basic Usage

```bash
# Build image
docker build -t aida-test .github/testing/

# Run fresh install test
docker run --rm \
  -v $(pwd):/workspace \
  aida-test fresh

# Run with debug enabled
docker run --rm \
  -v $(pwd):/workspace \
  -e DEBUG=true \
  aida-test upgrade
```

### Using docker-compose

```bash
cd .github/testing

# Fresh installation
docker-compose --profile fresh run --rm fresh-install

# Upgrade test
docker-compose --profile upgrade run --rm upgrade

# Migration with deprecated templates
docker-compose --profile migration run --rm migration

# Dev mode
docker-compose --profile dev run --rm dev-mode

# All tests
docker-compose --profile full run --rm test-all

# Debug shell
docker-compose --profile debug run --rm debug
```

### Advanced Usage

#### Custom Test Scenario

```bash
docker run --rm \
  -v $(pwd):/workspace \
  -v $(pwd)/.github/testing/fixtures:/test-fixtures \
  -v $(pwd)/.github/testing/results:/test-results \
  -e TEST_SCENARIO=upgrade \
  -e INSTALL_MODE=dev \
  -e DEBUG=true \
  -e VERBOSE=true \
  aida-test
```

#### Interactive Debugging

```bash
# Enter container shell
docker run --rm -it \
  -v $(pwd):/workspace \
  aida-test bash

# Inside container:
$ cd /workspace
$ ./install.sh --dev
$ tree -a ~/.claude
$ cat ~/.claude/aida-config.json
```

#### Run Specific bats Tests

```bash
docker run --rm \
  -v $(pwd):/workspace \
  aida-test bash -c "cd /workspace && bats tests/integration/test_upgrade_scenarios.bats --filter 'upgrade preserves user'"
```

#### Ubuntu 24.04 Testing

```bash
# Build Ubuntu 24.04 variant
docker build \
  --build-arg UBUNTU_VERSION=24.04 \
  -t aida-test:ubuntu24 \
  .github/testing/

# Run tests
docker run --rm \
  -v $(pwd):/workspace \
  aida-test:ubuntu24 fresh

# Using docker-compose
docker-compose --profile ubuntu24 run --rm fresh-install-ubuntu24
```

### Results Collection

```bash
# Create results directory
mkdir -p .github/testing/results

# Run tests with results
docker-compose --profile full run --rm test-all

# View results
ls -la .github/testing/results/
cat .github/testing/results/fresh-install-tests.tap
cat .github/testing/results/upgrade-tests.tap
cat .github/testing/results/pre-migration-tree.txt
cat .github/testing/results/post-migration-tree.txt
```

## Troubleshooting

### Common Issues

#### 1. Volume Mount Errors

**Problem:** Permission denied when accessing `/workspace`

**Solution:**

```bash
# Ensure Docker has access to project directory
# On macOS: Docker Desktop → Settings → Resources → File Sharing

# Or use absolute paths
docker run --rm -v /absolute/path/to/repo:/workspace aida-test fresh
```

#### 2. Build Failures

**Problem:** Package installation fails

**Solution:**

```bash
# Clear Docker cache
docker builder prune -a

# Rebuild without cache
docker build --no-cache -t aida-test .github/testing/
```

#### 3. Test Failures

**Problem:** Tests fail unexpectedly

**Solution:**

```bash
# Run with debug enabled
docker run --rm \
  -v $(pwd):/workspace \
  -e DEBUG=true \
  -e VERBOSE=true \
  aida-test upgrade

# Check results
cat .github/testing/results/upgrade-tests.tap

# Enter debug shell
docker-compose --profile debug run --rm debug
```

#### 4. Stale Results

**Problem:** Old test results persist

**Solution:**

```bash
# Clean results directory
rm -rf .github/testing/results/*

# Rerun tests
docker-compose --profile full run --rm test-all
```

### Debugging Tips

#### Enable Debug Output

```bash
docker run --rm \
  -v $(pwd):/workspace \
  -e DEBUG=true \
  aida-test upgrade
```

#### Inspect Container

```bash
# Run and keep container
docker run --rm -it \
  -v $(pwd):/workspace \
  --entrypoint /bin/bash \
  aida-test

# Inside container
$ tree -a ~/.claude
$ cat ~/.claude/aida-config.json
$ find ~/.claude -type f -ls
```

#### Check Logs

```bash
# Run with verbose output
docker run --rm \
  -v $(pwd):/workspace \
  -e VERBOSE=true \
  aida-test migration 2>&1 | tee test-output.log
```

## CI/CD Integration

### GitHub Actions

```yaml
name: Docker Upgrade Tests

on:
  pull_request:
    branches: [main, develop]
  push:
    branches: [main]

jobs:
  upgrade-tests:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        scenario: [fresh, upgrade, migration, dev-mode]

    steps:
      - uses: actions/checkout@v4

      - name: Build test image
        run: |
          cd .github/testing
          docker build -t aida-test .

      - name: Run ${{ matrix.scenario }} tests
        run: |
          docker run --rm \
            -v ${{ github.workspace }}:/workspace \
            -v ${{ github.workspace }}/.github/testing/results:/test-results \
            -e TEST_SCENARIO=${{ matrix.scenario }} \
            aida-test

      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: test-results-${{ matrix.scenario }}
          path: .github/testing/results/
```

### Makefile Integration

Add to project `Makefile`:

```makefile
.PHONY: docker-test
docker-test: ## Run Docker-based upgrade tests
	cd .github/testing && docker-compose --profile full run --rm test-all

.PHONY: docker-test-fresh
docker-test-fresh: ## Run fresh install test
	cd .github/testing && docker-compose --profile fresh run --rm fresh-install

.PHONY: docker-test-upgrade
docker-test-upgrade: ## Run upgrade test
	cd .github/testing && docker-compose --profile upgrade run --rm upgrade

.PHONY: docker-test-debug
docker-test-debug: ## Enter debug shell
	cd .github/testing && docker-compose --profile debug run --rm debug

.PHONY: docker-build
docker-build: ## Build Docker test image
	cd .github/testing && docker build -t aida-test .

.PHONY: docker-clean
docker-clean: ## Clean Docker test artifacts
	docker rmi aida-test || true
	rm -rf .github/testing/results/*
```

### Pre-commit Hook

Add to `.pre-commit-config.yaml`:

```yaml
- repo: local
  hooks:
    - id: docker-upgrade-tests
      name: Docker Upgrade Tests
      entry: make docker-test-fresh
      language: system
      pass_filenames: false
      stages: [push]
```

## Performance Optimization

### Layer Caching

The Dockerfile is optimized for layer caching:

1. System packages (changes rarely)
2. bats installation (stable version)
3. Test environment setup (rarely changes)
4. Entrypoint script (changes occasionally)

### Fast Iteration

```bash
# Build once
docker build -t aida-test .github/testing/

# Run tests multiple times (uses cached layers)
docker run --rm -v $(pwd):/workspace aida-test fresh
docker run --rm -v $(pwd):/workspace aida-test upgrade
docker run --rm -v $(pwd):/workspace aida-test migration
```

### Parallel Testing

```bash
# Run multiple scenarios in parallel
docker-compose --profile fresh run --rm fresh-install &
docker-compose --profile upgrade run --rm upgrade &
docker-compose --profile migration run --rm migration &
wait
```

## Best Practices

### 1. Always Use Volume Mounts

```bash
# Good: Mount repository
docker run --rm -v $(pwd):/workspace aida-test fresh

# Bad: Copy repository into image
# (Makes image huge and slow)
```

### 2. Use Read-Only Mounts for Code

```bash
# Prevent accidental modifications
docker run --rm -v $(pwd):/workspace:ro aida-test fresh
```

### 3. Capture Test Results

```bash
# Always mount results directory
docker run --rm \
  -v $(pwd):/workspace \
  -v $(pwd)/.github/testing/results:/test-results \
  aida-test migration
```

### 4. Clean Between Runs

```bash
# Clean results before new run
rm -rf .github/testing/results/*
docker-compose --profile full run --rm test-all
```

### 5. Use Profiles with docker-compose

```bash
# Good: Use profiles
docker-compose --profile fresh run --rm fresh-install

# Bad: Run all services
# docker-compose up (starts everything)
```

## File Reference

| File | Purpose |
|------|---------|
| `Dockerfile` | Multi-stage Docker image definition |
| `docker-entrypoint.sh` | Test orchestration script |
| `docker-compose.yml` | Service definitions for all scenarios |
| `DOCKER_TESTING.md` | This documentation |
| `fixtures/` | Test fixtures and data |
| `results/` | Test output directory (created at runtime) |

## See Also

- [test_upgrade_scenarios.bats](../../tests/integration/test_upgrade_scenarios.bats) - Integration tests
- [test_upgrade_helpers.bash](../../tests/integration/test_upgrade_helpers.bash) - Test helper functions
- [fixtures/README.md](fixtures/README.md) - Test fixtures documentation
- [../workflows/upgrade-tests.yml](../.github/workflows/upgrade-tests.yml) - CI/CD workflow

## Version History

- **v0.2.0** (2024-10-18) - Initial Docker testing infrastructure
  - Multi-stage builds
  - Multiple test scenarios
  - docker-compose orchestration
  - Comprehensive documentation
