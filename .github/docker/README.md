---
title: "Docker Testing Environment"
description: "Docker containers for testing AIDA framework installation"
category: "testing"
tags: ["docker", "testing", "ci", "qa"]
last_updated: "2025-10-05"
status: "published"
audience: "developers"
---

# Docker Testing Environment

This directory contains Docker configurations for testing the AIDA framework installation across different Linux distributions.

## Available Test Environments

| Environment | Dockerfile | Purpose |
|------------|------------|---------|
| Ubuntu 22.04 LTS | `ubuntu-22.04.Dockerfile` | Latest stable Ubuntu |
| Ubuntu 20.04 LTS | `ubuntu-20.04.Dockerfile` | Older stable Ubuntu |
| Debian 12 (Bookworm) | `debian-12.Dockerfile` | Latest Debian stable |
| Ubuntu Minimal | `ubuntu-minimal.Dockerfile` | Dependency validation testing |

## Quick Start

### Using Docker Compose (Recommended)

```bash
# Build all test environments
docker-compose -f .github/docker/docker-compose.yml build

# Run a specific test environment
docker-compose -f .github/docker/docker-compose.yml run ubuntu-22

# Inside the container, test installation:
./install.sh
```

### Using Docker Directly

```bash
# Build Ubuntu 22.04 test environment
docker build -f .github/docker/ubuntu-22.04.Dockerfile -t aida-test-ubuntu-22 .

# Run interactive test
docker run -it --rm -v $(pwd):/workspace:ro aida-test-ubuntu-22

# Inside container:
./install.sh
```

## Test Scenarios

### 1. Fresh Installation Test

Test a clean installation on a fresh system:

```bash
docker-compose run ubuntu-22

# Inside container:
./install.sh
# Follow prompts to complete installation
# Verify directories created: ~/.aida, ~/.claude, ~/CLAUDE.md
```

### 2. Development Mode Test

Test installation in development mode:

```bash
docker-compose run ubuntu-22

# Inside container:
./install.sh --dev
# Verify ~/.aida is a symlink to /workspace
```

### 3. Dependency Validation Test

Test dependency checking with minimal environment:

```bash
docker-compose run ubuntu-minimal

# Inside container:
./install.sh
# Should fail with clear error messages about missing git and rsync
```

### 4. Re-installation Test

Test backup functionality when re-running installation:

```bash
docker-compose run ubuntu-22

# Inside container:
# First installation
./install.sh
# (answer prompts)

# Second installation (should create backups)
./install.sh
# Verify backup directories created with timestamps
```

### 5. Help Flag Test

Test help documentation:

```bash
docker-compose run ubuntu-22

# Inside container:
./install.sh --help
# Verify help text displays correctly
```

## Automated Testing

Use the automated test script to run all test scenarios:

```bash
# Run from repository root
./.github/testing/test-install.sh
```

This will:

- Build all Docker images
- Run each test scenario
- Report success/failure for each environment
- Save test logs to `.github/testing/logs/`

### Understanding Test Results

**Expected output:**

```text
✓ Passed:  11
✗ Failed:  0
⚠ Skipped: 5

Why tests are skipped:
  • ubuntu-minimal: Skips install tests (tests dependency validation only)
  • Full environments: Skip dependency tests (all dependencies present)
  This is expected behavior - each environment tests different scenarios.
```

**This is correct!** Skipped tests are intentional:

- `ubuntu-minimal` tests dependency checking (skips install)
- Full environments test installation (skip dependency validation)

Use `--verbose` to see why each test is skipped:

```bash
./.github/testing/test-install.sh --verbose
```

## Manual Testing Checklist

When testing manually in a container:

- [ ] Run `./install.sh --help` - verify help displays
- [ ] Run `./install.sh` with valid inputs - verify success
- [ ] Check `~/.aida/` directory created with correct structure
- [ ] Check `~/.claude/` directory created with subdirectories
- [ ] Check `~/CLAUDE.md` generated with correct content
- [ ] Verify file permissions (755 for dirs, 644 for files)
- [ ] Run `./install.sh` again - verify backup created
- [ ] Run `./install.sh --dev` - verify symlink created
- [ ] Test with invalid inputs (name validation, personality selection)

## Environment Details

### Non-Root User Testing

All Docker environments run as `testuser` (non-root) to simulate real user installation:

- User: `testuser`
- Home: `/home/testuser`
- Shell: `/bin/bash`

### Installed Packages

**Full environments** (Ubuntu 22.04, 20.04, Debian 12):

- bash (>= 4.0)
- git
- rsync
- coreutils
- findutils

**Minimal environment** (Ubuntu Minimal):

- bash
- coreutils
- **Missing**: git, rsync (intentional for testing)

## Cleaning Up

Remove all test containers and images:

```bash
# Remove containers
docker-compose -f .github/docker/docker-compose.yml down

# Remove images
docker rmi aida-test-ubuntu-22 aida-test-ubuntu-20 aida-test-debian-12 aida-test-ubuntu-minimal

# Or remove all AIDA test images
docker images | grep aida-test | awk '{print $3}' | xargs docker rmi
```

## Troubleshooting

### Container Won't Start

```bash
# Check build logs
docker-compose -f .github/docker/docker-compose.yml build --no-cache ubuntu-22

# Check if ports are in use
docker ps -a
```

### Permission Issues

The workspace is mounted read-only (`:ro`) to prevent accidental modifications. This is intentional for testing. Installation will fail if trying to modify repository files directly.

### Bash Version Issues

```bash
# Check bash version in container
docker-compose run ubuntu-22 bash --version
```

## Next Steps

After Docker testing is successful:

1. Test on WSL (Windows Subsystem for Linux)
2. Test on Git Bash (Windows)
3. Set up CI/CD with GitHub Actions
4. Add automated regression testing

## Related Documentation

- [Test Scenarios](../testing/test-scenarios.md)
- [WSL Testing Guide](../testing/wsl-setup.md)
- [Git Bash Testing Guide](../testing/gitbash-setup.md)
