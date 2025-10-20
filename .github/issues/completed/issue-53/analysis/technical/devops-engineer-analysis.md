---
title: "DevOps Engineer - CI/CD & Testing Infrastructure Analysis"
issue: 53
document_type: "technical-analysis"
created: "2025-10-18"
agent: "devops-engineer"
version: "1.0"
status: "draft"
---

# DevOps Engineer Analysis: CI/CD & Testing Infrastructure

## Executive Summary

**Current State**: Docker-based testing for Linux, native GitHub runners for macOS/Windows. No upgrade scenario testing or user content preservation validation.

**Gap**: Missing Makefile abstraction, test fixtures for upgrade scenarios, Windows Docker testing, PR comment reporting.

**Recommendation**: Extend existing Docker infrastructure with Makefile orchestration layer and fixture-based upgrade testing. **Complexity: M** (moderate).

---

## 1. Docker Testing Architecture

### Current Implementation

**Linux Environments** (`.github/docker/`):

- `ubuntu-22.04.Dockerfile` - Ubuntu 22.04 LTS (primary)
- `ubuntu-20.04.Dockerfile` - Ubuntu 20.04 LTS (compatibility)
- `debian-12.Dockerfile` - Debian 12 Bookworm
- `ubuntu-minimal.Dockerfile` - Dependency validation testing (intentionally missing git/rsync)

**Strengths**:

- ✅ Read-only volume mounts (`/workspace:ro`) prevent test contamination
- ✅ Non-root `testuser` for realistic permissions
- ✅ Docker Compose orchestration with named containers
- ✅ Separate environments for different test purposes

**Gaps for Modular Installer**:

- ❌ No Windows Docker image (only WSL via GitHub Actions)
- ❌ No test fixtures for upgrade scenarios (existing `~/.claude/` with user content)
- ❌ No writable volume for user content preservation testing
- ❌ Hard-coded workspace paths (not parameterized)

### Recommended Enhancements

**Add Windows Container Support**:

```yaml
# docker-compose.yml
windows-2022:
  image: mcr.microsoft.com/windows/servercore:ltsc2022
  volumes:
    - ../..:/workspace:ro
    - aida-test-windows:/home/testuser  # Writable for upgrade tests
  working_dir: /workspace
  container_name: aida-test-windows-2022
```

**Add Upgrade Test Fixtures**:

```dockerfile
# ubuntu-upgrade-test.Dockerfile
FROM ubuntu:22.04

# ... standard dependencies ...

# Pre-seed with existing installation + user content
COPY .github/testing/fixtures/existing-claude-config /home/testuser/.claude
COPY .github/testing/fixtures/deprecated-templates /home/testuser/.aida-deprecated

USER testuser
ENV HOME=/home/testuser
```

**Fixture Structure** (`.github/testing/fixtures/`):

```text
fixtures/
├── existing-claude-config/        # Simulates existing ~/.claude/
│   ├── commands/
│   │   ├── custom-command.md      # User-created (must preserve)
│   │   └── .aida/
│   │       └── old-template.md    # Framework template (can replace)
│   ├── config/
│   │   └── assistant.yaml         # User config (must preserve)
│   └── memory/
│       └── session-123.json       # User data (must preserve)
├── deprecated-templates/          # Simulates old framework templates
│   ├── commands/
│   │   └── old-cmd.md             # deprecated: "v0.2.0"
│   └── agents/
│       └── old-agent.md           # deprecated: "v0.1.0"
└── README.md                      # Fixture documentation
```

**Volume Mount Strategy**:

```yaml
# docker-compose.yml
services:
  ubuntu-upgrade-test:
    build:
      context: ../..
      dockerfile: .github/docker/ubuntu-upgrade-test.Dockerfile
    volumes:
      - ../..:/workspace:ro           # Framework code (read-only)
      - ./fixtures:/fixtures:ro       # Test fixtures (read-only)
      - aida-test-data:/home/testuser # User data (writable, ephemeral)
    environment:
      - TEST_SCENARIO=upgrade         # Trigger fixture setup
      - AIDA_VERSION=0.1.5           # Current version for testing
```

---

## 2. Makefile Design

### Current State

**No Makefile exists** - tests invoked directly via:

- `.github/testing/test-install.sh` (Docker orchestration)
- GitHub Actions calling test script

### Recommended Makefile Structure

**Target Organization** (`Makefile`):

```makefile
# ============================================================
# AIDA Framework - Test Orchestration
# ============================================================

.PHONY: help test-all test-install test-upgrade test-fixtures \
        test-linux test-macos test-windows clean-test

# Default target
.DEFAULT_GOAL := help

# ============================================================
# Configuration
# ============================================================
DOCKER_COMPOSE := $(shell command -v docker-compose 2>/dev/null || echo "docker compose")
TEST_SCRIPT := .github/testing/test-install.sh
VERBOSE ?= false
ENVIRONMENT ?= all

# ============================================================
# Help Target
# ============================================================
help: ## Show this help message
    @echo "AIDA Framework - Test Targets"
    @echo ""
    @grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
        awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

# ============================================================
# Primary Test Targets
# ============================================================
test-all: test-install test-upgrade test-fixtures ## Run all test scenarios

test-install: ## Test fresh installation (no existing ~/.claude/)
    @echo "Running fresh installation tests..."
    $(TEST_SCRIPT) --scenario=fresh $(if $(filter true,$(VERBOSE)),--verbose)

test-upgrade: ## Test upgrade installation (existing ~/.claude/)
    @echo "Running upgrade installation tests..."
    $(TEST_SCRIPT) --scenario=upgrade $(if $(filter true,$(VERBOSE)),--verbose)

test-fixtures: ## Validate test fixture integrity
    @echo "Validating test fixtures..."
    .github/testing/validate-fixtures.sh

# ============================================================
# Platform-Specific Targets
# ============================================================
test-linux: ## Test all Linux environments (Docker)
    @echo "Testing Linux environments..."
    $(TEST_SCRIPT) --platform=linux $(if $(filter true,$(VERBOSE)),--verbose)

test-macos: ## Test macOS (requires macOS host)
    @echo "Testing macOS..."
    $(TEST_SCRIPT) --platform=macos $(if $(filter true,$(VERBOSE)),--verbose)

test-windows: ## Test Windows via WSL/Docker
    @echo "Testing Windows..."
    $(TEST_SCRIPT) --platform=windows $(if $(filter true,$(VERBOSE)),--verbose)

# ============================================================
# Environment-Specific Targets
# ============================================================
test-ubuntu-22: ## Test Ubuntu 22.04 only
    $(TEST_SCRIPT) --env ubuntu-22 $(if $(filter true,$(VERBOSE)),--verbose)

test-ubuntu-20: ## Test Ubuntu 20.04 only
    $(TEST_SCRIPT) --env ubuntu-20 $(if $(filter true,$(VERBOSE)),--verbose)

test-debian-12: ## Test Debian 12 only
    $(TEST_SCRIPT) --env debian-12 $(if $(filter true,$(VERBOSE)),--verbose)

test-minimal: ## Test dependency validation (ubuntu-minimal)
    $(TEST_SCRIPT) --env ubuntu-minimal $(if $(filter true,$(VERBOSE)),--verbose)

# ============================================================
# Mode-Specific Targets
# ============================================================
test-normal-mode: ## Test normal installation mode
    $(TEST_SCRIPT) --mode=normal $(if $(filter true,$(VERBOSE)),--verbose)

test-dev-mode: ## Test dev installation mode (symlinks)
    $(TEST_SCRIPT) --mode=dev $(if $(filter true,$(VERBOSE)),--verbose)

# ============================================================
# CI/CD Integration
# ============================================================
ci-test: ## Run tests for CI/CD pipeline
    @echo "Running CI/CD test suite..."
    @$(MAKE) test-all VERBOSE=true

ci-report: ## Generate test report for CI/CD
    @echo "Generating test report..."
    .github/testing/generate-report.sh

# ============================================================
# Cleanup Targets
# ============================================================
clean-test: ## Clean test artifacts and Docker volumes
    @echo "Cleaning test artifacts..."
    rm -rf .github/testing/logs/*
    $(DOCKER_COMPOSE) -f .github/docker/docker-compose.yml down -v
    docker volume prune -f

clean-fixtures: ## Reset test fixtures to defaults
    @echo "Resetting test fixtures..."
    git checkout .github/testing/fixtures/

# ============================================================
# Development Targets
# ============================================================
docker-build: ## Rebuild all Docker images
    @echo "Building Docker images..."
    $(DOCKER_COMPOSE) -f .github/docker/docker-compose.yml build

docker-shell: ## Open shell in test container
    @echo "Opening shell in $(ENVIRONMENT) environment..."
    $(DOCKER_COMPOSE) -f .github/docker/docker-compose.yml run --rm $(ENVIRONMENT) /bin/bash
```

**Parameterization Strategy**:

- Environment variables for verbosity/environment selection
- Conditional verbose output (`$(if $(filter true,$(VERBOSE)),--verbose)`)
- Passthrough to test script for consistent behavior
- Self-documenting help target using inline `##` comments

**Usage Examples**:

```bash
# Run all tests
make test-all

# Verbose output
make test-all VERBOSE=true

# Specific environment
make test-ubuntu-22 VERBOSE=true

# Open shell for debugging
make docker-shell ENVIRONMENT=ubuntu-22

# Clean up
make clean-test
```

---

## 3. GitHub Actions Workflow

### Current Implementation

**Workflow**: `.github/workflows/test-installation.yml`

**Structure**:

```yaml
jobs:
  lint: shellcheck + bash syntax
  test-macos: Native macOS runner
  test-windows-wsl: WSL via Vampire/setup-wsl action
  test-linux-docker: Matrix of 4 Docker environments
  test-full-suite: All environments via test-install.sh
  test-summary: Aggregates results from all jobs
```

**Strengths**:

- ✅ Comprehensive platform coverage (Linux/macOS/Windows)
- ✅ Fail-fast disabled for matrix (all environments tested)
- ✅ Concurrency control prevents duplicate runs
- ✅ Artifact collection for debugging (test logs)
- ✅ Automated input handling (no manual prompts)

**Gaps**:

- ❌ No upgrade scenario testing (only fresh installs)
- ❌ No PR comment with test results
- ❌ No user content preservation validation
- ❌ No performance metrics (installation time)
- ❌ No test coverage reporting

### Recommended Enhancements

**Add Upgrade Testing Job**:

```yaml
test-upgrade-scenarios:
  name: Test Upgrade Scenarios
  runs-on: ubuntu-latest
  needs: lint
  strategy:
    fail-fast: false
    matrix:
      scenario:
        - fresh-install          # No existing ~/.claude/
        - upgrade-with-custom    # Existing + user customizations
        - upgrade-deprecated     # Existing + deprecated templates
        - dev-to-normal         # Switching modes
  steps:
    - uses: actions/checkout@v4
    - name: Run upgrade test for ${{ matrix.scenario }}
      run: |
        make test-upgrade SCENARIO=${{ matrix.scenario }} VERBOSE=true
    - name: Validate user content preserved
      run: |
        .github/testing/validate-preservation.sh ${{ matrix.scenario }}
```

**Add PR Comment Reporter**:

```yaml
test-report:
  name: Comment Test Results
  runs-on: ubuntu-latest
  needs: [test-macos, test-windows-wsl, test-linux-docker, test-upgrade-scenarios]
  if: github.event_name == 'pull_request'
  permissions:
    pull-requests: write
  steps:
    - uses: actions/checkout@v4

    - name: Download all test artifacts
      uses: actions/download-artifact@v4
      with:
        path: test-results/

    - name: Generate test report
      id: report
      run: |
        REPORT=$(.github/testing/generate-pr-report.sh test-results/)
        echo "report<<EOF" >> $GITHUB_OUTPUT
        echo "$REPORT" >> $GITHUB_OUTPUT
        echo "EOF" >> $GITHUB_OUTPUT

    - name: Comment PR
      uses: actions/github-script@v7
      with:
        script: |
          github.rest.issues.createComment({
            issue_number: context.issue.number,
            owner: context.repo.owner,
            repo: context.repo.repo,
            body: `## 🧪 Installation Test Results\n\n${process.env.REPORT}`
          })
      env:
        REPORT: ${{ steps.report.outputs.report }}
```

**PR Report Format** (`.github/testing/generate-pr-report.sh`):

```markdown
## 🧪 Installation Test Results

### Summary
- ✅ **15/16 tests passed** (93.8%)
- ❌ **1 test failed**
- ⏱️ Total runtime: 12m 34s

### Platform Results

#### 🐧 Linux (Docker)
| Environment | Fresh Install | Upgrade | Dev Mode | Preservation |
|-------------|--------------|---------|----------|--------------|
| Ubuntu 22.04 | ✅ 8.2s | ✅ 9.1s | ✅ 7.8s | ✅ Pass |
| Ubuntu 20.04 | ✅ 8.5s | ✅ 9.3s | ✅ 8.1s | ✅ Pass |
| Debian 12 | ✅ 8.9s | ✅ 9.5s | ✅ 8.4s | ✅ Pass |
| Minimal | ❌ Expected fail | N/A | N/A | N/A |

#### 🍎 macOS
| Test | Result | Time |
|------|--------|------|
| Fresh Install | ✅ Pass | 11.2s |
| Upgrade | ✅ Pass | 12.5s |
| Preservation | ✅ Pass | - |

#### 🪟 Windows (WSL)
| Test | Result | Time |
|------|--------|------|
| Fresh Install | ✅ Pass | 15.3s |
| Upgrade | ✅ Pass | 16.8s |
| Preservation | ✅ Pass | - |

### User Content Preservation Tests
- ✅ Custom commands preserved
- ✅ User config files intact
- ✅ Memory data preserved
- ✅ Deprecated templates removed
- ✅ Framework templates updated

### Detailed Logs
[View full test logs](https://github.com/org/repo/actions/runs/12345)
```

**Matrix Strategy**:

```yaml
strategy:
  fail-fast: false
  matrix:
    include:
      # Linux environments
      - os: ubuntu-latest
        platform: linux
        environment: ubuntu-22
        scenarios: [fresh, upgrade, dev]

      - os: ubuntu-latest
        platform: linux
        environment: ubuntu-20
        scenarios: [fresh, upgrade, dev]

      # macOS
      - os: macos-latest
        platform: macos
        environment: native
        scenarios: [fresh, upgrade, dev]

      # Windows WSL
      - os: windows-latest
        platform: windows
        environment: wsl-ubuntu-22
        scenarios: [fresh, upgrade, dev]
```

**Artifact Collection Strategy**:

```yaml
- name: Upload test artifacts
  if: always()
  uses: actions/upload-artifact@v4
  with:
    name: test-results-${{ matrix.platform }}-${{ matrix.environment }}
    path: |
      .github/testing/logs/
      .github/testing/reports/
      /tmp/aida-test-*.log
    retention-days: 7
```

---

## 4. Test Scenarios Implementation

### Current Coverage

**Implemented** (`.github/testing/test-install.sh`):

1. ✅ Help flag test
2. ✅ Dependency validation (minimal env)
3. ✅ Normal installation
4. ✅ Dev mode installation

**Missing**:

- ❌ Upgrade scenarios (existing `~/.claude/` with user content)
- ❌ User content preservation validation
- ❌ Deprecated template cleanup
- ❌ Mode switching (normal → dev, dev → normal)
- ❌ Partial installation recovery

### Recommended Test Scenarios

**Scenario: Upgrade with User Content**:

```bash
# .github/testing/scenarios/upgrade-with-custom.sh

test_upgrade_preserves_user_content() {
    local env="$1"
    local fixture_dir=".github/testing/fixtures/existing-claude-config"

    # Setup: Pre-seed with existing installation
    docker cp "$fixture_dir" "aida-test-${env}:/home/testuser/.claude"

    # Action: Run installation (upgrade)
    docker exec "aida-test-${env}" bash -c "echo -e 'upgraded\n1\n' | ./install.sh"

    # Validation: User content preserved
    assert_file_exists "/home/testuser/.claude/commands/custom-command.md"
    assert_file_unchanged "/home/testuser/.claude/config/assistant.yaml"
    assert_directory_exists "/home/testuser/.claude/memory"

    # Validation: Framework templates updated
    assert_file_updated "/home/testuser/.claude/commands/.aida/start-work.md"

    # Validation: Deprecated templates removed
    assert_file_not_exists "/home/testuser/.aida-deprecated/commands/old-cmd.md"
}
```

**Scenario: Deprecated Template Cleanup**:

```bash
# .github/testing/scenarios/deprecated-cleanup.sh

test_deprecated_template_cleanup() {
    local env="$1"

    # Setup: Pre-seed with deprecated templates
    docker cp ".github/testing/fixtures/deprecated-templates" \
        "aida-test-${env}:/home/testuser/.aida-deprecated"

    # Action: Run installation
    docker exec "aida-test-${env}" bash -c "echo -e 'test\n1\n' | ./install.sh"

    # Validation: Deprecated templates moved to archive
    assert_directory_exists "/home/testuser/.aida-deprecated.archive.$(date +%Y%m%d)"
    assert_file_not_exists "/home/testuser/.aida-deprecated/commands/old-cmd.md"

    # Validation: New templates installed
    assert_file_exists "/home/testuser/.claude/commands/.aida/start-work.md"
}
```

**Scenario: Mode Switching**:

```bash
# .github/testing/scenarios/mode-switch.sh

test_normal_to_dev_mode_switch() {
    local env="$1"

    # Setup: Normal mode installation
    docker exec "aida-test-${env}" bash -c "echo -e 'normal\n1\n' | ./install.sh"
    assert_directory_not_symlink "/home/testuser/.aida"

    # Action: Switch to dev mode
    docker exec "aida-test-${env}" bash -c "echo -e 'dev\n1\n' | ./install.sh --dev"

    # Validation: .aida is now symlink
    assert_directory_is_symlink "/home/testuser/.aida"
    assert_symlink_target "/home/testuser/.aida" "/workspace"

    # Validation: User content preserved
    assert_file_exists "/home/testuser/.claude/commands/custom-command.md"
}
```

**User Content Fixture Structure**:

```bash
# .github/testing/fixtures/existing-claude-config/

commands/
  custom-command.md              # User-created (MUST preserve)
  project-workflow.md            # User-created (MUST preserve)
  .aida/
    start-work.md                # v0.1.0 template (can update)
    implement.md                 # v0.1.0 template (can update)

config/
  assistant.yaml                 # User config (MUST preserve)
  personalities/
    custom-personality.yaml      # User-created (MUST preserve)

memory/
  session-123.json               # User data (MUST preserve)
  context.json                   # User data (MUST preserve)

agents/
  custom-agent.md                # User-created (MUST preserve)
  .aida/
    secretary.md                 # v0.1.0 template (can update)
```

**Validation Script** (`.github/testing/validate-preservation.sh`):

```bash
#!/usr/bin/env bash
# Validates user content preservation after installation

validate_user_content_preserved() {
    local test_home="$1"
    local fixture_dir=".github/testing/fixtures/existing-claude-config"

    echo "Validating user content preservation..."

    # User-created files must exist and be unchanged
    for file in commands/custom-command.md config/assistant.yaml memory/session-123.json; do
        if ! diff -q "$fixture_dir/$file" "$test_home/.claude/$file" > /dev/null 2>&1; then
            echo "❌ FAIL: User file modified or missing: $file"
            return 1
        fi
    done

    # Framework templates must be updated (different from fixture)
    for file in commands/.aida/start-work.md agents/.aida/secretary.md; do
        if diff -q "$fixture_dir/$file" "$test_home/.claude/$file" > /dev/null 2>&1; then
            echo "❌ FAIL: Framework template not updated: $file"
            return 1
        fi
    done

    echo "✅ PASS: User content preserved, framework templates updated"
    return 0
}
```

---

## 5. Integration with Existing Tests

### Current Test Script

**File**: `.github/testing/test-install.sh`

**Architecture**:

- Bash script with 400 lines
- Docker Compose orchestration
- 4 test functions per environment
- Log file collection
- Test result aggregation

**Strengths**:

- ✅ Well-structured with helper functions
- ✅ Color-coded output
- ✅ Detailed logging
- ✅ Environment-specific test skipping

### Integration Strategy

**Option A: Extend Existing Script** (Recommended)

**Pros**:

- Reuses existing Docker orchestration
- Maintains single entry point
- Minimal refactoring required

**Cons**:

- Script continues to grow (already 400 lines)
- Mixing orchestration with test logic

**Implementation**:

```bash
# .github/testing/test-install.sh

# Add new test functions
test_upgrade_installation() { ... }
test_user_content_preservation() { ... }
test_deprecated_cleanup() { ... }
test_mode_switching() { ... }

# Update test suite runner
test_environment() {
    local env="$1"
    local scenario="${TEST_SCENARIO:-fresh}"  # Default to fresh install

    case "$scenario" in
        fresh)
            test_help_flag "$env"
            test_dependency_validation "$env"
            test_normal_installation "$env"
            test_dev_installation "$env"
            ;;
        upgrade)
            setup_upgrade_fixtures "$env"
            test_upgrade_installation "$env"
            test_user_content_preservation "$env"
            test_deprecated_cleanup "$env"
            ;;
        mode-switch)
            test_normal_to_dev_switch "$env"
            test_dev_to_normal_switch "$env"
            ;;
        *)
            print_msg "error" "Unknown scenario: $scenario"
            return 1
            ;;
    esac
}
```

**Option B: Modular Test Suite** (Future-proof)

**Pros**:

- Separates orchestration from test logic
- Easier to maintain individual test scenarios
- Reusable test functions across scenarios

**Cons**:

- Requires refactoring existing script
- More complex file structure

**Structure**:

```text
.github/testing/
├── test-install.sh              # Main orchestrator (150 lines)
├── lib/
│   ├── docker-utils.sh          # Docker orchestration helpers
│   ├── test-utils.sh            # Test assertion helpers
│   └── fixture-utils.sh         # Fixture management
├── scenarios/
│   ├── fresh-install.sh         # Fresh installation tests
│   ├── upgrade.sh               # Upgrade scenario tests
│   ├── mode-switch.sh           # Mode switching tests
│   └── deprecation.sh           # Deprecation cleanup tests
└── fixtures/
    ├── existing-claude-config/
    └── deprecated-templates/
```

### Migration Path

**Phase 1**: Extend existing script with upgrade scenarios (Option A)

- Add upgrade test functions to `test-install.sh`
- Add fixture setup/teardown
- Update GitHub Actions to run both fresh and upgrade tests

**Phase 2**: Introduce Makefile for orchestration

- Create `Makefile` with test targets
- Update GitHub Actions to use `make` commands
- Maintain backward compatibility with direct script invocation

**Phase 3**: Refactor to modular structure (Option B)

- Extract scenario-specific tests to `scenarios/` directory
- Create shared library functions
- Simplify main orchestrator script

**Backward Compatibility**:

```bash
# .github/testing/test-install.sh

# Detect if called via Makefile or directly
if [[ -n "${MAKEFILE_INVOKED:-}" ]]; then
    # New modular behavior
    source .github/testing/lib/test-utils.sh
    run_scenario "${TEST_SCENARIO}"
else
    # Legacy behavior (backward compatible)
    main "$@"
fi
```

---

## 6. Technical Risks & Mitigations

### Risk 1: Cross-Platform Docker Compatibility

**Risk**: Windows Docker containers have different filesystem semantics (NTFS vs ext4, symlink support, line endings).

**Impact**: HIGH - Tests may pass on Linux but fail on Windows.

**Mitigation**:

- Use Windows Server Core containers (not nanoserver)
- Explicitly handle line endings in Dockerfiles:

  ```dockerfile
  # Windows Dockerfile
  RUN git config --global core.autocrlf false
  RUN git config --global core.eol lf
  ```

- Test symlink support early in test suite:

  ```bash
  # Test symlink support before running dev mode tests
  test_symlink_support() {
      ln -s /workspace /home/testuser/test-link || {
          print_msg "warning" "Symlinks not supported - skipping dev mode tests"
          return 0
      }
      rm /home/testuser/test-link
  }
  ```

### Risk 2: CI/CD Runtime Limits

**Risk**: GitHub Actions free tier has 6-hour job limit, 20 concurrent jobs. Large test matrix could exceed limits or cost money.

**Impact**: MEDIUM - Workflow may timeout or fail to run all tests.

**Mitigation**:

- Run only changed platform tests on PRs (detect via `paths` filter)
- Run full matrix only on `main` branch pushes
- Use workflow dispatch for manual full testing
- Optimize Docker layer caching to reduce build times:

  ```yaml
  - name: Set up Docker Buildx
    uses: docker/setup-buildx-action@v3
    with:
      buildkitd-flags: --debug

  - name: Cache Docker layers
    uses: actions/cache@v4
    with:
      path: /tmp/.buildx-cache
      key: ${{ runner.os }}-buildx-${{ github.sha }}
      restore-keys: |
        ${{ runner.os }}-buildx-
  ```

- Implement test result caching for unchanged code:

  ```yaml
  - name: Cache test results
    uses: actions/cache@v4
    with:
      path: .github/testing/logs/
      key: test-results-${{ hashFiles('install.sh', 'lib/**') }}
  ```

**Estimated Runtime**:

- Current: ~10 minutes (4 Docker envs + macOS + Windows)
- With upgrade scenarios: ~15-20 minutes (double the test scenarios)
- **Acceptable** for PR checks

### Risk 3: Test Maintenance Burden

**Risk**: Adding upgrade scenarios doubles the test surface area. Flaky tests or environment drift could increase maintenance.

**Impact**: MEDIUM - Developer time spent debugging test failures.

**Mitigation**:

- Pin Docker base image versions (not `ubuntu:latest`, use `ubuntu:22.04`)
- Version test fixtures alongside code:

  ```yaml
  # .github/testing/fixtures/README.md
  ## Fixture Versions
  - v0.1.0: Initial fixture set (fresh install only)
  - v0.2.0: Added upgrade fixtures with deprecated templates
  - v0.3.0: Added mode-switching fixtures
  ```

- Implement fixture validation script:

  ```bash
  # .github/testing/validate-fixtures.sh
  # Ensures fixtures have required structure and frontmatter
  ```

- Document test debugging workflow:

  ```bash
  # Run failing test locally
  make docker-shell ENVIRONMENT=ubuntu-22

  # Inside container, manually run installation
  ./install.sh

  # Inspect filesystem
  ls -la ~/.claude/
  ```

### Risk 4: Fixture Drift from Real User Content

**Risk**: Test fixtures don't reflect actual user customizations, leading to false confidence.

**Impact**: LOW - Tests pass but real users still experience data loss.

**Mitigation**:

- Base fixtures on real user examples (anonymized)
- Add "chaos monkey" tests with randomized user content:

  ```bash
  # Generate random user files
  for i in {1..10}; do
      echo "Custom content $i" > ~/.claude/commands/custom-$i.md
  done

  # Run installation
  ./install.sh

  # Verify all files preserved
  ```

- Document fixture creation guidelines:

  ```markdown
  ## Fixture Creation Guidelines
  1. Include files in all user-writable directories
  2. Use realistic frontmatter (not just test values)
  3. Include edge cases (empty files, large files, special characters)
  4. Version fixtures with framework releases
  ```

---

## 7. Effort Estimate

### Complexity: **M (Moderate)**

**Justification**:

- Extends existing Docker infrastructure (not greenfield)
- Makefile adds abstraction layer (low complexity)
- Upgrade scenarios are new but follow existing patterns
- PR comment integration is straightforward (GitHub Actions has good examples)

**Breakdown**:

| Component | Complexity | Estimated Time |
|-----------|-----------|----------------|
| **Makefile Creation** | Low | 2-3 hours |
| - Test target organization | Simple | 1 hour |
| - Parameterization & help | Simple | 1 hour |
| - CI integration targets | Simple | 1 hour |
| **Docker Enhancements** | Low-Medium | 4-6 hours |
| - Upgrade test Dockerfile | Medium | 2 hours |
| - Volume mount strategy | Simple | 1 hour |
| - Windows container setup | Medium | 2-3 hours |
| **Test Fixtures** | Medium | 6-8 hours |
| - Fixture structure design | Medium | 2 hours |
| - Create realistic fixtures | Medium | 3-4 hours |
| - Validation scripts | Simple | 2 hours |
| **Upgrade Test Scenarios** | Medium | 8-10 hours |
| - User content preservation | Medium | 3 hours |
| - Deprecated cleanup | Medium | 2 hours |
| - Mode switching | Medium | 2 hours |
| - Validation assertions | Simple | 2-3 hours |
| **GitHub Actions Updates** | Low-Medium | 4-6 hours |
| - Upgrade scenario job | Simple | 2 hours |
| - PR comment reporter | Medium | 2-3 hours |
| - Artifact collection | Simple | 1 hour |
| **Documentation** | Low | 2-3 hours |
| - Update testing README | Simple | 1 hour |
| - Fixture documentation | Simple | 1 hour |
| - Troubleshooting guide | Simple | 1 hour |

**Total Estimate**: **26-36 hours** (3-4.5 days for one developer)

**Key Effort Drivers**:

1. **Fixture Creation** - Realistic user content examples take time
2. **Cross-Platform Testing** - Windows Docker setup has platform quirks
3. **Validation Logic** - Ensuring user content preservation is complex

**Dependencies**:

- Requires modular installer implementation (Phase 1)
- Blocked by `lib/installer-common/` library creation
- Can proceed in parallel with deprecation system

**Risk Factors**:

- Windows Docker testing may reveal platform-specific issues (add 25% buffer)
- Fixture validation complexity may grow with edge cases (add 20% buffer)

**Revised Estimate with Buffer**: **32-45 hours** (4-5.5 days)

---

## Recommendations

### Immediate Actions (v0.2.0)

1. **Create Makefile** - Single entry point for all test scenarios
2. **Add Upgrade Fixtures** - Realistic user content examples
3. **Extend test-install.sh** - Add upgrade scenario tests
4. **Update GitHub Actions** - Run both fresh and upgrade tests

### Future Enhancements (v0.3.0+)

1. **Windows Docker Testing** - Full Windows container support
2. **PR Comment Reporter** - Inline test results in PRs
3. **Performance Metrics** - Track installation time regressions
4. **Modular Test Suite** - Refactor to `scenarios/` structure

### Success Criteria

- ✅ All test scenarios pass on Linux/macOS/Windows
- ✅ User content preservation validated in CI/CD
- ✅ Makefile provides intuitive test interface
- ✅ PR comments show test results automatically
- ✅ Test runtime < 20 minutes on GitHub Actions

---

## Related Files

- `.github/testing/test-install.sh` - Current test orchestrator
- `.github/workflows/test-installation.yml` - GitHub Actions workflow
- `.github/docker/docker-compose.yml` - Docker environment definitions
- `.github/testing/test-scenarios.md` - Test scenario documentation

## Coordinates With

- **tech-lead** - Overall testing strategy and CI/CD architecture
- **security-engineer** - Test fixture security (no secrets in fixtures)
- **product-manager** - Test coverage priorities
