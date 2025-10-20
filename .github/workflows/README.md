---
title: "GitHub Actions Workflows"
description: "Automated CI/CD workflows for AIDA framework"
category: "ci-cd"
tags: ["github-actions", "ci", "cd", "automation"]
last_updated: "2025-10-18"
status: "published"
audience: "developers"
---

# GitHub Actions Workflows

Automated CI/CD workflows for the AIDA (Agentic Intelligence Digital Assistant) framework.

## Workflow Overview

| Workflow | Purpose | Triggers | Duration |
|----------|---------|----------|----------|
| **Lint** | Code quality checks | Push, PR | ~1 min |
| **Installer Tests** | Unit, integration, installation tests | Push, PR | ~8-10 min |
| **Installation Tests** | End-to-end installation validation | Push, PR | ~5-7 min |

## Available Workflows

### Lint (`lint.yml`)

**Purpose:** Runs pre-commit hooks for code quality validation.

**Triggers:**

- Push to `main` or `develop` branches
- Pull requests to `main` or `develop`

**Jobs:**

1. **`lint`** - Runs all pre-commit hooks
   - shellcheck for shell scripts
   - yamllint for YAML files
   - markdownlint for markdown files
   - gitleaks for secret scanning

**Fast feedback:** Completes in ~1 minute.

### Installer Tests (`test-installer.yml`)

**Purpose:** Comprehensive testing of modular installer across platforms and scenarios.

**Triggers:**

- Push to `main` or `milestone-*` branches
- Pull requests to `main` or `milestone-*`
- Manual dispatch (workflow_dispatch)
- Changes to:
  - `lib/**`
  - `install.sh`
  - `tests/**`
  - `Makefile`
  - `.github/workflows/test-installer.yml`

**Test Stages:**

#### Stage 1: Lint & Validation

- **lint-shell** - Shellcheck all scripts
- **validate-templates** - Verify template frontmatter

#### Stage 2: Unit Tests (Matrix)

**Platforms:** ubuntu-22.04, ubuntu-24.04, macos-13, macos-14

Tests all installer modules:

- `lib/installer-common/prompts.sh`
- `lib/installer-common/config.sh`
- `lib/installer-common/directories.sh`
- `lib/installer-common/summary.sh`
- `lib/installer-common/templates.sh`
- `lib/installer-common/deprecation.sh`

**Total:** 168+ unit tests per platform

#### Stage 3: Integration Tests (Matrix)

**Scenarios:**

- `fresh-install` - New installation
- `upgrade-v0.1` - Upgrade from v0.1.x
- `upgrade-with-content` - Preserve user content

Tests upgrade paths and content preservation.

#### Stage 4: Installation Tests (Matrix)

**Matrix:** `{ubuntu-22.04, macos-13} × {normal, dev}`

End-to-end installation testing:

- Normal mode (copied files)
- Dev mode (symlinked files)
- Upgrade scenarios
- Installation verification

#### Stage 5: Docker Tests (Matrix)

**Platforms:** ubuntu-22.04, ubuntu-24.04, debian-12

Containerized cross-platform testing:

- Unit tests in container
- Installation in container
- Platform compatibility

#### Stage 6: Coverage Analysis

- Test coverage report
- Module coverage statistics
- Coverage trends

#### Stage 7: Test Summary

- Aggregate all test results
- Generate summary report
- Fail if any stage fails

#### Stage 8: PR Comment

Posts test summary to PR with:

- Stage-by-stage results
- Overall pass/fail status
- Links to detailed logs

**Test Matrix:**

| Platform | Unit Tests | Integration | Installation | Docker |
|----------|-----------|-------------|--------------|--------|
| **ubuntu-22.04** | ✅ | ✅ | ✅ | ✅ |
| **ubuntu-24.04** | ✅ | - | - | ✅ |
| **macos-13** | ✅ | - | ✅ | - |
| **macos-14** | ✅ | - | - | - |
| **debian-12** | - | - | - | ✅ |

**Artifacts Generated:**

- `unit-test-results-{os}` - Unit test results per platform
- `integration-test-results-{scenario}` - Integration test results
- `integration-test-logs-{scenario}` - Detailed integration logs
- `installation-logs-{mode}-{os}` - Installation verification logs
- `docker-test-logs-{platform}` - Docker test logs
- `coverage-report` - Test coverage analysis (30 day retention)

**Execution Time:** ~8-10 minutes (parallel execution)

### Installation Tests (`test-installation.yml`)

**Triggers:**

- Push to `main` or `milestone-*` branches
- Pull requests to `main`
- Manual dispatch (workflow_dispatch)
- Changes to:
  - `install.sh`
  - `.github/testing/**`
  - `.github/workflows/test-installation.yml`

**Test Matrix:**

| Platform | Runner | Tests |
|----------|--------|-------|
| **macOS** | `macos-latest` | Help flag, dependencies, installation, verification |
| **Windows WSL** | `windows-latest` | WSL Ubuntu setup, installation, verification |
| **Linux (Docker)** | `ubuntu-latest` | Ubuntu 22.04, 20.04, Debian 12, Minimal |
| **Full Suite** | `ubuntu-latest` | All Docker environments |

**Jobs:**

1. **`lint`** - Validates installation script
   - Runs shellcheck
   - Checks bash syntax
   - Required for all other jobs

2. **`test-macos`** - macOS native testing
   - Checks bash version
   - Tests help flag
   - Verifies dependencies
   - Runs installation
   - Verifies file creation

3. **`test-windows-wsl`** - Windows WSL testing
   - Sets up WSL Ubuntu 22.04
   - Installs dependencies
   - Tests help flag
   - Runs installation
   - Verifies file creation

4. **`test-linux-docker`** - Linux Docker matrix
   - Tests 4 environments in parallel:
     - `ubuntu-22` - Ubuntu 22.04 LTS
     - `ubuntu-20` - Ubuntu 20.04 LTS
     - `debian-12` - Debian 12
     - `ubuntu-minimal` - Dependency validation
   - Uploads test logs as artifacts

5. **`test-full-suite`** - Complete test suite
   - Runs all Docker tests
   - Uploads comprehensive logs

6. **`test-summary`** - Results summary
   - Checks all job results
   - Reports overall pass/fail
   - Required status check

**Test Coverage:**

- ✅ Help flag display
- ✅ Dependency validation
- ✅ Normal installation
- ✅ Development mode installation
- ✅ File and directory creation
- ✅ Cross-platform compatibility

## Viewing Test Results

### In GitHub UI

1. Navigate to repository
2. Click "Actions" tab
3. Select workflow run
4. View job results and logs

### Test Artifacts

Failed tests upload logs as artifacts:

- `test-logs-{environment}` - Individual environment logs
- `test-logs-full-suite` - Complete suite logs
- Retained for 7 days

### Download Artifacts

```bash
# Using GitHub CLI
gh run download <run-id>

# Or from GitHub UI:
# Actions → Run → Artifacts section
```

## Local Testing

Run the same tests locally:

```bash
# Full test suite
./.github/testing/test-install.sh

# Specific environment
./.github/testing/test-install.sh --env ubuntu-22

# With verbose output
./.github/testing/test-install.sh --verbose
```

## Workflow Status Badges

Add to README.md:

```markdown
[![Installation Tests](https://github.com/oakensoul/claude-personal-assistant/workflows/Installation%20Tests/badge.svg)](https://github.com/oakensoul/claude-personal-assistant/actions/workflows/test-installation.yml)
```

## Manual Workflow Dispatch

Trigger workflow manually:

1. GitHub UI:
   - Actions → Installation Tests → Run workflow

2. GitHub CLI:

   ```bash
   gh workflow run test-installation.yml
   ```

3. With specific branch:

   ```bash
   gh workflow run test-installation.yml --ref feature-branch
   ```

## Protected Branches

Configure branch protection rules to require tests:

1. Settings → Branches → Add rule
2. Branch name pattern: `main`
3. Enable: "Require status checks to pass"
4. Select: `test-summary`
5. Save changes

This ensures all PRs pass tests before merging.

## Troubleshooting

### Tests Failing on PR but Passing Locally

1. Check environment differences:
   - Bash version
   - Tool versions (git, rsync)
   - Line endings (CRLF vs LF)

2. View detailed logs:
   - Download artifacts
   - Check specific failure point

3. Reproduce locally:

   ```bash
   # Use same Docker environment
   ./.github/testing/test-install.sh --env ubuntu-22
   ```

### Slow Test Runs

1. Docker layer caching:
   - GitHub Actions caches layers automatically
   - First run is slower (downloads base images)
   - Subsequent runs use cached layers

2. Parallel execution:
   - Matrix jobs run in parallel
   - Reduces total time

### WSL Test Failures

Common issues:

- WSL setup timeout
- Dependency installation failures
- Path issues

Fix:

- Check WSL setup step
- Verify sudo permissions
- Ensure correct shell context

### macOS Test Failures

Common issues:

- Bash version (macOS has old Bash 3.x by default)
- BSD vs GNU tools
- rsync differences

Fix:

- Install newer bash if needed
- Check tool versions
- Update script for BSD compatibility

## Adding New Tests

### Add New Unit Test

1. Create test file in `tests/unit/`:

   ```bash
   # tests/unit/test_new_module.bats
   #!/usr/bin/env bats

   load ../helpers/test_helpers

   setup() {
     source "${PROJECT_ROOT}/lib/installer-common/new_module.sh"
   }

   @test "new module test case" {
     run new_function "input"
     [ "$status" -eq 0 ]
   }
   ```

2. Test runs automatically in workflow (no changes needed)

### Add New Integration Test Scenario

1. Create fixture in `.github/testing/fixtures/`:

   ```bash
   .github/testing/fixtures/new-scenario/
   ├── .aida/
   └── .claude/
   ```

2. Update workflow matrix in `test-installer.yml`:

   ```yaml
   integration-tests:
     strategy:
       matrix:
         scenario:
           - fresh-install
           - upgrade-v0.1
           - upgrade-with-content
           - new-scenario  # Add here
   ```

### Add New Docker Platform

1. Create Dockerfile:

   ```bash
   # .github/testing/Dockerfile.new-platform
   FROM new-platform:latest
   RUN apt-get update && apt-get install -y bash git rsync jq bats
   ```

2. Update workflow matrix:

   ```yaml
   docker-tests:
     strategy:
       matrix:
         platform:
           - ubuntu-22.04
           - ubuntu-24.04
           - debian-12
           - new-platform  # Add here
   ```

## Local Testing

Run the same tests locally before pushing:

### Unit Tests

```bash
# All unit tests
make test-unit

# Specific test file
bats tests/unit/test_prompts.bats

# Verbose output
bats --verbose tests/unit/test_prompts.bats
```

### Integration Tests

```bash
# All integration tests
make test-integration

# Specific scenario
TEST_SCENARIO=upgrade-v0.1 bats tests/integration/test_upgrade_scenarios.bats
```

### Docker Tests

```bash
# Build test image
docker build -t aida-test:ubuntu-22.04 -f .github/testing/Dockerfile.ubuntu-22.04 .github/testing/

# Run tests in container
docker run --rm -v $(pwd):/workspace -w /workspace aida-test:ubuntu-22.04 make test-all
```

### Full CI Suite

```bash
# Run all checks (same as CI)
make ci

# Fast checks (skip integration)
make ci-fast
```

## Performance Optimization

### Cache Docker Layers

Already configured with `docker/setup-buildx-action@v3`:

- Automatic layer caching
- Shared between runs
- Reduces build time

### Parallel Execution

Matrix strategy runs jobs in parallel:

```yaml
strategy:
  fail-fast: false  # Continue even if one fails
  matrix:
    environment: [...]
```

### Conditional Execution

Only run on relevant changes:

```yaml
on:
  push:
    paths:
      - 'install.sh'
      - '.github/**'
```

## Security

### Secrets and Variables

No secrets currently required. If needed:

1. Add secret: Settings → Secrets → New secret

2. Reference in workflow:

   ```yaml
   env:
     MY_SECRET: ${{ secrets.MY_SECRET }}
   ```

### Permissions

Workflow uses minimal permissions:

```yaml
permissions:
  contents: read
```

## Viewing Test Results

### GitHub Actions UI

1. Navigate to repository
2. Click "Actions" tab
3. Select workflow run
4. View detailed logs for each job
5. Download artifacts for offline analysis

### PR Comments

For pull requests, `test-installer.yml` automatically posts a summary:

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

### Test Artifacts

Download artifacts from workflow run:

- **Unit test results** - Test output per platform
- **Integration test logs** - Detailed scenario logs
- **Installation logs** - Installation verification
- **Coverage report** - Module coverage statistics

```bash
# Using GitHub CLI
gh run download <run-id>

# Or from GitHub UI: Actions → Run → Artifacts section
```

## Monitoring

### Email Notifications

Configure in personal settings:

- Settings → Notifications
- Enable: "Actions"
- Choose: "Only notify on failure"

### Slack/Discord Integration

Use workflow notifications:

```yaml
- name: Notify on failure
  if: failure()
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

## Related Documentation

- [Unit Testing Guide](../../docs/testing/UNIT_TESTING.md)
- [Bats Setup Guide](../../docs/testing/BATS_SETUP.md)
- [Test Suite Overview](../../tests/README.md)
- [Test Scenarios](../testing/test-scenarios.md)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

## Workflow Status Badges

Add to README.md:

```markdown
[![Lint](https://github.com/oakensoul/claude-personal-assistant/workflows/Lint/badge.svg)](https://github.com/oakensoul/claude-personal-assistant/actions/workflows/lint.yml)
[![Installer Tests](https://github.com/oakensoul/claude-personal-assistant/workflows/Installer%20Tests/badge.svg)](https://github.com/oakensoul/claude-personal-assistant/actions/workflows/test-installer.yml)
[![Installation Tests](https://github.com/oakensoul/claude-personal-assistant/workflows/Installation%20Tests/badge.svg)](https://github.com/oakensoul/claude-personal-assistant/actions/workflows/test-installation.yml)
```

## Manual Workflow Dispatch

Trigger workflows manually:

### Using GitHub UI

1. Navigate to Actions tab
2. Select workflow (e.g., "Installer Tests")
3. Click "Run workflow"
4. Select branch
5. Click "Run workflow" button

### Using GitHub CLI

```bash
# Trigger installer tests
gh workflow run test-installer.yml

# Trigger on specific branch
gh workflow run test-installer.yml --ref feature-branch

# Trigger installation tests
gh workflow run test-installation.yml
```

## Support

For workflow issues:

1. Check workflow run logs in GitHub Actions UI
2. Download and review artifacts
3. Test locally with same environment
4. Reproduce in Docker container
5. File issue with:
   - Workflow run link
   - Platform/OS information
   - Error logs
   - Local test results

---

**Last Updated:** 2025-10-18
**Maintainer:** oakensoul
**Status:** Active
