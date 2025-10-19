---
title: "Docker Testing Quick Start"
description: "Quick reference for running Docker-based upgrade tests"
category: "testing"
tags: ["docker", "testing", "quick-start"]
last_updated: "2024-10-18"
status: "published"
audience: "developers"
---

# Docker Testing Quick Start

Fast reference for running AIDA Docker tests.

## One-Line Commands

```bash
# Build image
make docker-build

# Run all tests
make docker-test-all

# Run specific scenario
make docker-test-fresh     # Fresh install
make docker-test-upgrade   # Upgrade test
make docker-test-migration # Migration test
make docker-test-dev       # Dev mode

# Debug
make docker-debug          # Interactive shell

# View results
make docker-results

# Clean up
make docker-clean
```

## Manual Docker Commands

```bash
# Build
cd .github/testing
docker build -t aida-test .

# Run scenarios
docker run --rm -v $(pwd)/../..:/workspace aida-test fresh
docker run --rm -v $(pwd)/../..:/workspace aida-test upgrade
docker run --rm -v $(pwd)/../..:/workspace aida-test migration
docker run --rm -v $(pwd)/../..:/workspace aida-test dev-mode
docker run --rm -v $(pwd)/../..:/workspace aida-test test-all

# Debug shell
docker run --rm -it -v $(pwd)/../..:/workspace aida-test bash
```

## Docker Compose

```bash
cd .github/testing

# Fresh install
docker-compose --profile fresh run --rm fresh-install

# Upgrade
docker-compose --profile upgrade run --rm upgrade

# Migration
docker-compose --profile migration run --rm migration

# Dev mode
docker-compose --profile dev run --rm dev-mode

# All tests
docker-compose --profile full run --rm test-all

# Debug
docker-compose --profile debug run --rm debug
```

## Test Results

```bash
# View results
ls -la .github/testing/results/

# TAP results
cat .github/testing/results/fresh-install-tests.tap
cat .github/testing/results/upgrade-tests.tap
cat .github/testing/results/migration-tests.tap

# Migration artifacts
cat .github/testing/results/pre-migration-tree.txt
cat .github/testing/results/post-migration-tree.txt
diff .github/testing/results/pre-migration-checksums.txt \
     .github/testing/results/post-migration-checksums.txt
```

## Common Tasks

### First Time Setup

```bash
# Build image
make docker-build

# Run all tests
make docker-test-all

# View results
make docker-results
```

### Quick Test During Development

```bash
# Fresh install (fast)
make docker-test-fresh

# Or upgrade only
make docker-test-upgrade
```

### Debug Failed Test

```bash
# Enter debug shell
make docker-debug

# Inside container:
cd /workspace
./install.sh --dev
tree -a ~/.claude
cat ~/.claude/aida-config.json
```

### CI/CD Testing

```bash
# Run all tests (CI mode)
make docker-test-all

# Upload results (in GitHub Actions)
# - name: Upload test results
#   uses: actions/upload-artifact@v3
#   with:
#     name: docker-test-results
#     path: .github/testing/results/
```

## Environment Variables

```bash
# Enable debug output
docker run --rm \
  -v $(pwd):/workspace \
  -e DEBUG=true \
  aida-test fresh

# Enable verbose output
docker run --rm \
  -v $(pwd):/workspace \
  -e VERBOSE=true \
  aida-test upgrade

# Custom scenario
docker run --rm \
  -v $(pwd):/workspace \
  -e TEST_SCENARIO=migration \
  -e INSTALL_MODE=dev \
  -e DEBUG=true \
  aida-test
```

## Troubleshooting

### Build fails

```bash
# Clear cache
docker builder prune -a

# Rebuild
make docker-build
```

### Tests fail

```bash
# Run with debug
docker run --rm \
  -v $(pwd):/workspace \
  -e DEBUG=true \
  aida-test upgrade

# Check results
cat .github/testing/results/upgrade-tests.tap
```

### Permission issues

```bash
# Check volume mounts
docker run --rm \
  -v $(pwd):/workspace \
  aida-test bash -c "ls -la /workspace"

# Run as current user
docker run --rm \
  -v $(pwd):/workspace \
  -u $(id -u):$(id -g) \
  aida-test fresh
```

## See Also

- [DOCKER_TESTING.md](DOCKER_TESTING.md) - Comprehensive guide
- [Dockerfile](Dockerfile) - Image definition
- [docker-compose.yml](docker-compose.yml) - Service definitions
- [docker-entrypoint.sh](docker-entrypoint.sh) - Entrypoint script
