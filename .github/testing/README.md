---
title: "Testing Documentation"
description: "Comprehensive testing documentation for AIDA framework"
category: "testing"
tags: ["testing", "qa", "documentation"]
last_updated: "2025-10-05"
status: "published"
audience: "developers"
---

# AIDA Framework Testing

Comprehensive testing documentation for the AIDA (Agentic Intelligence Digital Assistant) framework installation script.

## Overview

This directory contains all testing resources, documentation, and automation scripts for validating the AIDA framework installation across multiple platforms and environments.

## Quick Start

### Run All Automated Tests (Docker)

```bash
# From repository root
./.github/testing/test-install.sh
```

### Run Specific Environment

```bash
# Test only Ubuntu 22.04
./.github/testing/test-install.sh --env ubuntu-22

# Verbose output
./.github/testing/test-install.sh --verbose
```

### Manual Testing

See platform-specific guides:

- [Docker Testing](../docker/README.md)
- [WSL Testing](wsl-setup.md)
- [Git Bash Testing](gitbash-setup.md)

## Documentation Structure

### Core Documentation

| Document | Description |
|----------|-------------|
| [README.md](README.md) | This file - testing overview |
| [test-scenarios.md](test-scenarios.md) | Comprehensive test scenarios and checklists |

### Platform Guides

| Platform | Document | Status |
|----------|----------|--------|
| Linux (Docker) | [../docker/README.md](../docker/README.md) | ✅ Complete |
| Windows (WSL) | [wsl-setup.md](wsl-setup.md) | ✅ Complete |
| Windows (Git Bash) | [gitbash-setup.md](gitbash-setup.md) | ✅ Complete |
| macOS | Manual testing | ✅ Supported |

### Test Scripts

| Script | Purpose |
|--------|---------|
| [test-install.sh](test-install.sh) | Automated Docker testing |

## Supported Platforms

### ✅ Fully Supported

- **Ubuntu 22.04 LTS** - Docker, WSL
- **Ubuntu 20.04 LTS** - Docker, WSL
- **Debian 12** - Docker, WSL
- **macOS 13+** - Native

### ⚠️ Limited Support

- **Git Bash (Windows)** - Requires rsync installation, limited symlink support

## Test Coverage

### Automated Tests

- ✅ Help flag display
- ✅ Dependency validation
- ✅ Normal installation
- ✅ Development mode installation
- ✅ Multi-platform compatibility

### Understanding Skipped Tests

When running tests, you'll see some tests marked as "Skipped". **This is expected behavior!**

Each test environment serves a different purpose:

**ubuntu-minimal:**

- ✅ Tests dependency validation (missing git, rsync)
- ⏭️ Skips installation tests (would fail without dependencies)

**Full environments (ubuntu-22, ubuntu-20, debian-12):**

- ✅ Test installation (normal and dev mode)
- ⏭️ Skip dependency validation (all dependencies present)

**Why this design?**

- Tests different failure scenarios
- Ensures error messages are helpful
- Validates the script works in varied environments
- Confirms dependency checking catches missing tools

**Expected results when running all tests:**

```text
✓ Passed:  11
✗ Failed:  0
⚠ Skipped: 5

Why tests are skipped:
  • ubuntu-minimal: Skips install tests (tests dependency validation only)
  • Full environments: Skip dependency tests (all dependencies present)
  This is expected behavior - each environment tests different scenarios.
```

Use `--verbose` flag to see detailed skip messages:

```bash
./.github/testing/test-install.sh --verbose
```

### Manual Test Scenarios

1. **Fresh Installation** - Clean install on new system
2. **Development Mode** - Symlink-based installation
3. **Re-installation** - Backup and restore testing
4. **Dependency Validation** - Missing dependency detection
5. **Input Validation** - Name and personality validation
6. **Help Documentation** - Help flag and error messages
7. **Idempotency** - Multiple runs without issues
8. **Permissions** - File and directory permissions
9. **Generated Content** - CLAUDE.md validation
10. **Platform-Specific** - macOS, WSL, Git Bash

## Testing Workflow

### For Contributors

1. **Make Changes** to `install.sh`

2. **Run Automated Tests**

   ```bash
   ./.github/testing/test-install.sh
   ```

3. **Test Manually** on your platform

   ```bash
   ./install.sh --help
   ./install.sh --dev
   ```

4. **Document Results** using test scenarios

5. **Submit PR** with test results

### For Reviewers

1. **Review changes** to installation script

2. **Verify tests pass** in CI (when configured)

3. **Run manual tests** on multiple platforms

4. **Check documentation** updates

## Test Environments

### Docker Environments

| Environment | Dockerfile | Purpose |
|-------------|------------|---------|
| Ubuntu 22.04 | `ubuntu-22.04.Dockerfile` | Latest stable Ubuntu |
| Ubuntu 20.04 | `ubuntu-20.04.Dockerfile` | Older stable Ubuntu |
| Debian 12 | `debian-12.Dockerfile` | Latest Debian |
| Ubuntu Minimal | `ubuntu-minimal.Dockerfile` | Dependency testing |

### Using Docker

```bash
# Use the automated test script (recommended)
./.github/testing/test-install.sh

# Or test specific environment
./.github/testing/test-install.sh --env ubuntu-22

# Verbose output
./.github/testing/test-install.sh --verbose
```

### WSL Testing

```bash
# Install WSL distribution
wsl --install -d Ubuntu-22.04

# Launch WSL
wsl

# Run tests
cd ~/claude-personal-assistant
./install.sh
```

See [WSL Testing Guide](wsl-setup.md) for details.

### Git Bash Testing

See [Git Bash Testing Guide](gitbash-setup.md) for details.

**Important:** Git Bash requires rsync installation and has symlink limitations.

## Known Issues

### Windows (Git Bash)

- **rsync not included** - Must be installed separately
- **Symlinks require admin** - Or Developer Mode enabled
- **Limited permissions** - NTFS vs Unix permissions

### WSL

- **Performance** - Windows filesystem (/mnt/c/) is slower
- **Line endings** - May need `core.autocrlf` configuration

### macOS

- **BSD vs GNU** - Some command differences (mostly handled)

## CI/CD Integration (Future)

### GitHub Actions

```yaml
# .github/workflows/test-install.yml
name: Installation Tests

on: [push, pull_request]

jobs:
  test-linux:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run tests
        run: ./.github/testing/test-install.sh

  test-macos:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run installation
        run: ./install.sh --help
```

## Contributing to Tests

### Adding New Test Scenarios

1. Document in [test-scenarios.md](test-scenarios.md)
2. Add to automated script if possible
3. Update this README

### Adding New Platforms

1. Create Dockerfile (for Docker environments)
2. Create platform guide (like wsl-setup.md)
3. Add to test matrix
4. Update documentation

### Reporting Issues

When reporting test failures:

1. **Environment details** (OS, version, etc.)
2. **Steps to reproduce**
3. **Expected vs actual results**
4. **Logs and screenshots**
5. **Suggested fix** (if known)

## Test Logs

Automated test logs are saved to:

```text
.github/testing/logs/
├── build-ubuntu-22.log
├── test-help-ubuntu-22.log
├── test-deps-ubuntu-minimal.log
├── test-install-ubuntu-22.log
└── test-dev-ubuntu-22.log
```

## Cleaning Up

### Remove Docker Images

```bash
# Remove test images
docker rmi aida-test-ubuntu-22 aida-test-ubuntu-20 \
           aida-test-debian-12 aida-test-ubuntu-minimal

# Or remove all AIDA test images
docker images | grep aida-test | awk '{print $3}' | xargs docker rmi
```

### Remove Test Installations

```bash
# Remove AIDA installation
rm -rf ~/.aida ~/.claude ~/CLAUDE.md

# Remove backups
rm -rf ~/.aida.backup.* ~/.claude.backup.* ~/CLAUDE.md.backup.*
```

### Clean Test Logs

```bash
# Remove all test logs
rm -rf .github/testing/logs/
```

## Resources

### External Documentation

- [Docker Documentation](https://docs.docker.com/)
- [WSL Documentation](https://docs.microsoft.com/en-us/windows/wsl/)
- [Git for Windows](https://git-scm.com/download/win)
- [Bash Reference Manual](https://www.gnu.org/software/bash/manual/)

### Project Documentation

- [Installation Script](../../install.sh)
- [Project README](../../README.md)
- [CLAUDE.md](../../CLAUDE.md)

## Getting Help

### Documentation

1. Read platform-specific guide
2. Check [test scenarios](test-scenarios.md)
3. Review known issues

### Support

- File an issue: [GitHub Issues](https://github.com/oakensoul/claude-personal-assistant/issues)
- Check existing issues for similar problems
- Provide full context when asking for help

## Next Steps

- [ ] Set up GitHub Actions CI
- [ ] Add integration tests
- [ ] Add performance benchmarks
- [ ] Create video tutorials
- [ ] Add automated screenshot testing

---

**Last Updated:** 2025-10-05
**Maintainer:** oakensoul
**Status:** Active
