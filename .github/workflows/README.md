---
title: "GitHub Actions Workflows"
description: "Automated CI/CD workflows for AIDA framework"
category: "ci-cd"
tags: ["github-actions", "ci", "cd", "automation"]
last_updated: "2025-10-05"
status: "published"
audience: "developers"
---

# GitHub Actions Workflows

Automated CI/CD workflows for the AIDA (Agentic Intelligence Digital Assistant) framework.

## Available Workflows

### Installation Tests (`test-installation.yml`)

**Triggers:**

- Push to `main` or `milestone-*` branches
- Pull requests to `main`
- Manual dispatch (workflow_dispatch)
- Changes to:
  - `install.sh`
  - `.github/docker/**`
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

### Add New Test Job

1. Edit `test-installation.yml`

2. Add new job:

   ```yaml
   test-new-platform:
     name: Test on New Platform
     runs-on: platform-runner
     needs: lint
     steps:
       - uses: actions/checkout@v4
       # ... test steps ...
   ```

3. Update `test-summary` needs:

   ```yaml
   needs:
     - lint
     - test-macos
     - test-windows-wsl
     - test-linux-docker
     - test-full-suite
     - test-new-platform  # Add here
   ```

4. Update result check:

   ```yaml
   if [ "${{ needs.test-new-platform.result }}" != "success" ]; then
     echo "❌ New platform tests failed"
     exit 1
   fi
   ```

### Add New Docker Environment

1. Create Dockerfile in `.github/docker/`

2. Add to `docker-compose.yml`

3. Add to test matrix in workflow:

   ```yaml
   matrix:
     environment:
       - ubuntu-22
       - ubuntu-20
       - debian-12
       - ubuntu-minimal
       - new-environment  # Add here
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

- [Docker Testing Guide](../docker/README.md)
- [Testing Documentation](../testing/README.md)
- [Test Scenarios](../testing/test-scenarios.md)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

## Support

For workflow issues:

1. Check workflow run logs
2. Download and review artifacts
3. Test locally with same environment
4. File issue with workflow run link

---

**Last Updated:** 2025-10-05
**Maintainer:** oakensoul
**Status:** Active
