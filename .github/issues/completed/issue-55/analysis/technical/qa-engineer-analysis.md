---
title: "QA Engineer Analysis - Configuration System (#55)"
issue: 55
analyst: "qa-engineer"
created: "2025-10-20"
status: "complete"
category: "technical-analysis"
---

# QA Engineer Analysis: Configuration System with VCS Abstraction

## Executive Summary

**Testing Complexity**: MEDIUM-HIGH
**Critical Risk Areas**: Cross-platform compatibility, auto-detection accuracy, config merge logic
**Recommended Framework**: Custom bash test suite with Docker-based cross-platform testing
**Estimated Test Coverage**: 85%+ achievable with proposed approach

**Key Findings**:

- Existing test infrastructure (`lib/installer-common/test-*.sh`, `.github/testing/`) provides strong foundation
- Auto-detection logic is highest risk area (git remote parsing, platform-specific commands)
- Config merging requires exhaustive edge case testing (deep merge, namespace conflicts)
- Cross-platform testing MUST use real environments (Docker-based), not mocks
- Secret detection is security-critical and requires dedicated pre-commit hook testing

## 1. Implementation Approach

### Recommended Test Framework

**Primary Framework**: Custom bash test suite (consistent with existing `test-config-wrapper.sh` pattern)

**Rationale**:

- ✅ **Consistency**: Matches existing test infrastructure (`lib/installer-common/test-*.sh`)
- ✅ **No external dependencies**: Pure bash + `jq` (already required)
- ✅ **CI-friendly**: Integrates with existing Docker-based testing (`.github/testing/`)
- ✅ **Platform-native**: Tests shell scripts using shell (not abstracted through bats)
- ❌ **Trade-off**: More verbose than bats, requires custom test harness

**Alternative considered**: BATS (Bash Automated Testing System)

- Pros: Industry-standard, cleaner syntax, better reporting
- Cons: External dependency, additional installation complexity, not currently used in project

**Decision**: Use custom bash framework for consistency, consider BATS migration in future (Issue #XX)

### Test Suite Structure

```text
tests/
├── unit/
│   ├── test-vcs-detection.sh           # VCS auto-detection logic
│   ├── test-config-validation.sh       # Schema + provider validation
│   ├── test-config-merging.sh          # Hierarchical merge logic
│   ├── test-secret-detection.sh        # Pre-commit hook secrets
│   └── test-migration.sh               # github.* → vcs.* migration
├── integration/
│   ├── test-config-workflow.sh         # End-to-end config loading
│   ├── test-cross-platform.sh          # Platform-specific behavior
│   └── test-error-scenarios.sh         # Error messages and edge cases
└── fixtures/
    ├── git-remotes/                    # Sample git remote URLs
    ├── valid-configs/                  # Valid config examples
    ├── invalid-configs/                # Invalid configs (missing fields, etc.)
    └── edge-cases/                     # Special characters, corrupt JSON, etc.
```

### Unit Tests for Detection Logic

#### Priority: CRITICAL

```bash
# tests/unit/test-vcs-detection.sh

test_github_ssh_detection() {
    test_header "GitHub SSH remote detection"

    local remote="git@github.com:oakensoul/claude-personal-assistant.git"
    local result
    result=$(detect_vcs_from_remote "$remote")

    assert_equals "github" "$(echo "$result" | jq -r '.provider')"
    assert_equals "oakensoul" "$(echo "$result" | jq -r '.owner')"
    assert_equals "claude-personal-assistant" "$(echo "$result" | jq -r '.repo')"
    assert_equals "high" "$(echo "$result" | jq -r '.confidence')"
}

test_github_https_detection() {
    test_header "GitHub HTTPS remote detection"

    local remote="https://github.com/oakensoul/claude-personal-assistant.git"
    local result
    result=$(detect_vcs_from_remote "$remote")

    assert_equals "github" "$(echo "$result" | jq -r '.provider')"
    assert_equals "oakensoul" "$(echo "$result" | jq -r '.owner')"
    assert_equals "claude-personal-assistant" "$(echo "$result" | jq -r '.repo')"
}

test_gitlab_self_hosted_detection() {
    test_header "GitLab self-hosted detection"

    local remote="git@gitlab.company.com:team/project.git"
    local result
    result=$(detect_vcs_from_remote "$remote")

    assert_equals "gitlab" "$(echo "$result" | jq -r '.provider')"
    assert_equals "team" "$(echo "$result" | jq -r '.owner')"
    assert_equals "project" "$(echo "$result" | jq -r '.repo')"
    assert_equals "gitlab.company.com" "$(echo "$result" | jq -r '.self_hosted_url')"
}

test_bitbucket_detection() {
    test_header "Bitbucket workspace/slug detection"

    local remote="git@bitbucket.org:workspace/repo-slug.git"
    local result
    result=$(detect_vcs_from_remote "$remote")

    assert_equals "bitbucket" "$(echo "$result" | jq -r '.provider')"
    assert_equals "workspace" "$(echo "$result" | jq -r '.workspace')"
    assert_equals "repo-slug" "$(echo "$result" | jq -r '.repo_slug')"
}

test_invalid_remote_handling() {
    test_header "Invalid remote URL graceful failure"

    local remote="not-a-valid-remote-url"
    local result
    result=$(detect_vcs_from_remote "$remote" 2>&1)

    assert_contains "$result" "Unable to detect VCS provider"
    assert_exit_code 1
}

test_ambiguous_remote_detection() {
    test_header "Ambiguous remote (multiple providers match)"

    # Simulate git remote with both origin and upstream
    local result
    result=$(detect_vcs_with_multiple_remotes)

    # Should prefer 'origin' over 'upstream'
    assert_equals "origin" "$(echo "$result" | jq -r '.remote_name')"
}
```

### Integration Tests for Config Merging

#### Priority: HIGH

```bash
# tests/integration/test-config-merging.sh

test_user_project_merge() {
    test_header "User config overridden by project config"

    # Setup: Create user config with github.owner = "user1"
    create_test_config "$HOME/.claude/config.json" '{
        "vcs": {
            "provider": "github",
            "owner": "user1",
            "repo": "default-repo"
        }
    }'

    # Setup: Create project config with github.owner = "team"
    create_test_config "$PWD/.aida/config.json" '{
        "vcs": {
            "provider": "github",
            "owner": "team",
            "repo": "project-repo"
        }
    }'

    # Test: Merged config should use project values
    local merged
    merged=$(aida-config-helper.sh)

    assert_equals "team" "$(echo "$merged" | jq -r '.vcs.owner')"
    assert_equals "project-repo" "$(echo "$merged" | jq -r '.vcs.repo')"
}

test_deep_merge_namespaces() {
    test_header "Deep merge preserves non-conflicting keys"

    create_test_config "$HOME/.claude/config.json" '{
        "vcs": {
            "provider": "github",
            "owner": "user1"
        },
        "team": {
            "default_reviewers": ["alice"]
        }
    }'

    create_test_config "$PWD/.aida/config.json" '{
        "vcs": {
            "repo": "project-repo"
        },
        "team": {
            "default_reviewers": ["bob", "charlie"]
        }
    }'

    local merged
    merged=$(aida-config-helper.sh)

    # VCS namespace should deep merge
    assert_equals "user1" "$(echo "$merged" | jq -r '.vcs.owner')"
    assert_equals "project-repo" "$(echo "$merged" | jq -r '.vcs.repo')"

    # Team reviewers should be union (array merge)
    local reviewers
    reviewers=$(echo "$merged" | jq -r '.team.default_reviewers | @json')
    assert_contains "$reviewers" "alice"
    assert_contains "$reviewers" "bob"
    assert_contains "$reviewers" "charlie"
}

test_environment_variable_override() {
    test_header "Environment variables override all config"

    create_test_config "$HOME/.claude/config.json" '{
        "vcs": {"owner": "user1"}
    }'

    export AIDA_VCS_OWNER="env-override"

    local merged
    merged=$(aida-config-helper.sh)

    assert_equals "env-override" "$(echo "$merged" | jq -r '.vcs.owner')"

    unset AIDA_VCS_OWNER
}
```

### Cross-Platform Testing Strategy

#### Priority: CRITICAL

**Approach**: Docker-based multi-environment testing (existing infrastructure in `.github/testing/`)

**Test Environments**:

- **macOS-like** (BSD userland): Use existing macOS GitHub Actions runner
- **Ubuntu 22.04** (GNU userland): Primary Linux target (existing Dockerfile)
- **Ubuntu 20.04**: Legacy support (existing Dockerfile)
- **Debian 12**: Alternative Linux distro (existing Dockerfile)

**Platform-Specific Test Cases**:

```bash
# tests/integration/test-cross-platform.sh

test_stat_command_compatibility() {
    test_header "File modification time detection (cross-platform)"

    local test_file="/tmp/test-mtime"
    touch "$test_file"

    # Function should work on both BSD (macOS) and GNU (Linux)
    local mtime
    mtime=$(get_file_checksum "$test_file")

    assert_not_empty "$mtime"
    assert_is_number "$mtime"

    rm -f "$test_file"
}

test_readlink_compatibility() {
    test_header "Symlink resolution (cross-platform)"

    local link="/tmp/test-link"
    local target="/tmp/test-target"

    touch "$target"
    ln -s "$target" "$link"

    # Test cross-platform symlink resolution
    local resolved
    resolved=$(resolve_symlink "$link")

    assert_equals "$target" "$resolved"

    rm -f "$link" "$target"
}

test_jq_deep_merge_consistency() {
    test_header "jq merge behavior consistency across versions"

    local config1='{"a": {"b": 1}}'
    local config2='{"a": {"c": 2}}'

    local merged
    merged=$(echo "$config1 $config2" | jq -s '.[0] * .[1]')

    # Ensure deep merge works consistently
    assert_equals "1" "$(echo "$merged" | jq -r '.a.b')"
    assert_equals "2" "$(echo "$merged" | jq -r '.a.c')"
}
```

**CI/CD Integration**:

```yaml
# .github/workflows/test-config-system.yml

name: Config System Tests

on: [push, pull_request]

jobs:
  test-macos:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install dependencies
        run: brew install jq
      - name: Run unit tests
        run: tests/unit/test-vcs-detection.sh
      - name: Run integration tests
        run: tests/integration/test-config-merging.sh

  test-linux:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        env: [ubuntu-22, ubuntu-20, debian-12]
    steps:
      - uses: actions/checkout@v4
      - name: Test in Docker environment
        run: |
          .github/testing/test-install.sh --env ${{ matrix.env }}
          docker exec aida-${{ matrix.env }} bash -c "cd /workspace && tests/unit/test-vcs-detection.sh"
```

### Mocking Git Commands

**Approach**: Use git test fixtures + subprocess mocking for isolation

**Strategy 1: Git Fixtures (Recommended)**:

```bash
# tests/fixtures/git-remotes/setup-test-repo.sh

setup_github_repo() {
    local repo_dir="$1"
    mkdir -p "$repo_dir"
    cd "$repo_dir"

    git init
    git remote add origin git@github.com:oakensoul/test-repo.git
    git config --local user.name "Test User"
    git config --local user.email "test@example.com"
}

setup_gitlab_repo() {
    local repo_dir="$1"
    mkdir -p "$repo_dir"
    cd "$repo_dir"

    git init
    git remote add origin https://gitlab.com/team/project.git
}

setup_multiple_remotes() {
    local repo_dir="$1"
    mkdir -p "$repo_dir"
    cd "$repo_dir"

    git init
    git remote add origin git@github.com:oakensoul/test-repo.git
    git remote add upstream git@github.com:upstream/test-repo.git
}
```

**Strategy 2: Git Command Stubbing** (for tests without real repos):

```bash
# tests/lib/git-stubs.sh

stub_git_remote() {
    local remote_url="$1"

    # Create temporary git stub
    cat > /tmp/git-stub-$$ << EOF
#!/usr/bin/env bash
if [[ "\$1" == "remote" ]] && [[ "\$2" == "get-url" ]]; then
    echo "$remote_url"
    exit 0
fi
exec /usr/bin/git "\$@"
EOF

    chmod +x /tmp/git-stub-$$

    # Override git in PATH for this test
    export PATH="/tmp:$PATH"
    ln -sf /tmp/git-stub-$$ /tmp/git
}

unstub_git() {
    rm -f /tmp/git-stub-$$ /tmp/git
}
```

**Recommendation**: Use **git fixtures** for integration tests (more realistic), **stubs** for unit tests (faster, isolated).

## 2. Technical Concerns

### Test Coverage Requirements

**Minimum Acceptable Coverage**: 85%

**Coverage by Component**:

| Component | Target Coverage | Rationale |
|-----------|-----------------|-----------|
| VCS Auto-Detection | 95% | Critical path, highest risk |
| Config Validation | 90% | Security-critical (secrets) |
| Config Merging | 85% | Complex logic, many edge cases |
| Migration Script | 90% | One-time operation, must be perfect |
| Error Messaging | 70% | Nice-to-have, not critical |
| Pre-commit Hook | 100% | Security-critical |

**Coverage Measurement**:

```bash
# Use bashcov (if available) or manual tracking
bashcov --root lib/installer-common tests/unit/*.sh

# Manual coverage tracking
total_functions=25
tested_functions=21
coverage=$((tested_functions * 100 / total_functions))
echo "Coverage: ${coverage}%"
```

### Regression Testing Strategy

**Priority: HIGH** - Existing `aida-config-helper.sh` must continue to work

**Regression Test Suite**:

```bash
# tests/regression/test-existing-config-helper.sh

test_existing_get_config() {
    test_header "Existing get_config() still works"

    # Test against known good configuration
    local config
    config=$(get_config)

    assert_valid_json "$config"
    assert_has_key "$config" "paths.aida_home"
}

test_existing_get_config_value() {
    test_header "Existing get_config_value() still works"

    local aida_home
    aida_home=$(get_config_value "paths.aida_home")

    assert_not_empty "$aida_home"
    assert_directory_exists "$aida_home"
}

test_backward_compatibility_github_namespace() {
    test_header "Old github.* namespace still readable during migration"

    # Create old-format config
    create_test_config "$HOME/.claude/workflow-config.json" '{
        "github": {
            "owner": "oakensoul",
            "repo": "test-repo"
        }
    }'

    # Should still read old format during migration period
    local owner
    owner=$(aida-config-helper.sh --key github.owner)

    assert_equals "oakensoul" "$owner"
}
```

**Regression Test Execution**:

```bash
# Run before ANY changes to config system
pre-commit run --all-files
tests/regression/test-existing-config-helper.sh

# Run after implementation
tests/regression/test-existing-config-helper.sh
diff results/before.json results/after.json
```

### Edge Cases: Invalid URLs, Missing Git, Corrupt JSON

#### Priority: MEDIUM-HIGH

**Test Suite**:

```bash
# tests/integration/test-error-scenarios.sh

test_invalid_git_remote_url() {
    test_header "Invalid git remote URL"

    local result
    result=$(detect_vcs_from_remote "not-a-url" 2>&1)

    assert_contains "$result" "Unable to detect VCS provider"
    assert_contains "$result" "git remote get-url origin"
    assert_exit_code 1
}

test_missing_git_binary() {
    test_header "Git binary not found"

    # Temporarily hide git from PATH
    local original_path="$PATH"
    export PATH="/usr/bin:/bin"  # Exclude /usr/local/bin where git might be

    local result
    result=$(detect_vcs_from_remote "git@github.com:user/repo.git" 2>&1)

    export PATH="$original_path"

    assert_contains "$result" "git is required"
    assert_exit_code 1
}

test_corrupt_json_config() {
    test_header "Corrupt JSON config file"

    # Create invalid JSON
    echo '{"vcs": {invalid-json}' > /tmp/test-config.json

    local result
    result=$(aida-config-helper.sh --config /tmp/test-config.json 2>&1)

    assert_contains "$result" "Invalid JSON"
    assert_contains "$result" "/tmp/test-config.json"
    assert_exit_code 1

    rm -f /tmp/test-config.json
}

test_missing_required_fields() {
    test_header "Missing required fields in config"

    create_test_config "/tmp/test-config.json" '{
        "vcs": {
            "provider": "github"
        }
    }'

    local result
    result=$(aida-config-helper.sh --validate --config /tmp/test-config.json 2>&1)

    assert_contains "$result" "Required field missing: vcs.owner"
    assert_contains "$result" "Required field missing: vcs.repo"
    assert_exit_code 2  # Validation error exit code

    rm -f /tmp/test-config.json
}

test_special_characters_in_repo_name() {
    test_header "Special characters in repository name"

    local remote="git@github.com:user/repo-with-special_chars.git"
    local result
    result=$(detect_vcs_from_remote "$remote")

    assert_equals "repo-with-special_chars" "$(echo "$result" | jq -r '.repo')"
}

test_unicode_in_config_values() {
    test_header "Unicode characters in config values"

    create_test_config "/tmp/test-config.json" '{
        "team": {
            "members": [
                {"username": "用户", "role": "developer"}
            ]
        }
    }'

    local merged
    merged=$(aida-config-helper.sh --config /tmp/test-config.json)

    assert_equals "用户" "$(echo "$merged" | jq -r '.team.members[0].username')"

    rm -f /tmp/test-config.json
}

test_deeply_nested_json_merging() {
    test_header "Deeply nested JSON deep merge"

    create_test_config "/tmp/config1.json" '{
        "a": {"b": {"c": {"d": 1}}}
    }'

    create_test_config "/tmp/config2.json" '{
        "a": {"b": {"e": 2}}
    }'

    local merged
    merged=$(jq -s '.[0] * .[1]' /tmp/config1.json /tmp/config2.json)

    assert_equals "1" "$(echo "$merged" | jq -r '.a.b.c.d')"
    assert_equals "2" "$(echo "$merged" | jq -r '.a.b.e')"

    rm -f /tmp/config1.json /tmp/config2.json
}
```

### Performance Testing for Caching

#### Priority: MEDIUM

**Performance Requirements** (from PRD):

- Validation completes in < 1 second for typical configs
- Config loading cached per shell session
- Auto-detection doesn't block on network calls

**Test Suite**:

```bash
# tests/performance/test-config-performance.sh

test_cache_performance() {
    test_header "Config caching reduces subsequent loads"

    # First load (cold cache)
    local start_cold
    start_cold=$(date +%s%N)
    aida-config-helper.sh > /dev/null
    local end_cold
    end_cold=$(date +%s%N)
    local duration_cold=$(( (end_cold - start_cold) / 1000000 ))  # Convert to ms

    # Second load (warm cache)
    local start_warm
    start_warm=$(date +%s%N)
    aida-config-helper.sh > /dev/null
    local end_warm
    end_warm=$(date +%s%N)
    local duration_warm=$(( (end_warm - start_warm) / 1000000 ))

    print_message "info" "Cold load: ${duration_cold}ms, Warm load: ${duration_warm}ms"

    # Warm cache should be at least 2x faster
    assert_less_than "$duration_warm" "$((duration_cold / 2))"
}

test_validation_performance() {
    test_header "Validation completes in < 1 second"

    create_test_config "/tmp/test-config.json" '{
        "vcs": {
            "provider": "github",
            "owner": "test",
            "repo": "test-repo"
        }
    }'

    local start
    start=$(date +%s%N)
    aida-config-helper.sh --validate --config /tmp/test-config.json > /dev/null
    local end
    end=$(date +%s%N)
    local duration=$(( (end - start) / 1000000 ))

    print_message "info" "Validation duration: ${duration}ms"

    # Must complete in < 1000ms (per NFR4)
    assert_less_than "$duration" 1000

    rm -f /tmp/test-config.json
}

test_no_network_calls_in_auto_detection() {
    test_header "Auto-detection doesn't make network calls"

    # Monitor network activity during detection
    # This is a best-effort test, may require tcpdump/wireshark

    local result
    result=$(timeout 2 detect_vcs_from_remote "git@github.com:user/repo.git")

    # Should complete within 2 seconds without network
    assert_exit_code 0
}
```

## 3. Dependencies & Integration

### Test Framework Installation

**Required Dependencies**:

```bash
# Core requirements (already in project)
jq

# Optional (for enhanced testing)
shellcheck       # Pre-commit hook already uses
yamllint         # Pre-commit hook already uses
bashcov          # Code coverage (optional)
```

**Installation in CI/CD**:

```yaml
# .github/workflows/test-config-system.yml

- name: Install test dependencies
  run: |
    # macOS
    brew install jq shellcheck

    # Ubuntu (Docker)
    apt-get update && apt-get install -y jq
```

**No additional test framework needed** - Use existing custom bash test harness.

### Mock/Stub Utilities for Git, jq

**Git Mocking**:

```bash
# tests/lib/git-test-helpers.sh

create_test_git_repo() {
    local repo_dir="$1"
    local remote_url="$2"

    mkdir -p "$repo_dir"
    cd "$repo_dir"
    git init
    git remote add origin "$remote_url"
}

mock_git_remote_command() {
    local mock_url="$1"

    # Override git command for testing
    git() {
        if [[ "$1" == "remote" ]] && [[ "$2" == "get-url" ]]; then
            echo "$mock_url"
            return 0
        fi
        command git "$@"
    }
    export -f git
}
```

**jq Validation Helpers**:

```bash
# tests/lib/json-test-helpers.sh

assert_valid_json() {
    local json="$1"
    if ! echo "$json" | jq empty 2>/dev/null; then
        test_result "FAIL" "Invalid JSON: $json"
        return 1
    fi
}

assert_has_key() {
    local json="$1"
    local key="$2"

    if ! echo "$json" | jq -e ".${key}" >/dev/null 2>&1; then
        test_result "FAIL" "Missing key: $key"
        return 1
    fi
}

assert_json_equals() {
    local expected="$1"
    local actual="$2"

    if ! diff <(echo "$expected" | jq -S .) <(echo "$actual" | jq -S .); then
        test_result "FAIL" "JSON mismatch"
        return 1
    fi
}
```

### CI/CD Test Automation

**GitHub Actions Workflow**:

```yaml
# .github/workflows/config-system-tests.yml

name: Config System Tests

on:
  push:
    branches: [main, develop]
    paths:
      - 'lib/aida-config-helper.sh'
      - 'lib/installer-common/config.sh'
      - 'tests/**'
  pull_request:
    paths:
      - 'lib/aida-config-helper.sh'
      - 'lib/installer-common/config.sh'
      - 'tests/**'

jobs:
  unit-tests:
    name: Unit Tests
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest]
    steps:
      - uses: actions/checkout@v4

      - name: Install dependencies
        run: |
          if [[ "${{ matrix.os }}" == "macos-latest" ]]; then
            brew install jq
          else
            sudo apt-get update && sudo apt-get install -y jq
          fi

      - name: Run unit tests
        run: |
          tests/unit/test-vcs-detection.sh
          tests/unit/test-config-validation.sh
          tests/unit/test-config-merging.sh
          tests/unit/test-secret-detection.sh
          tests/unit/test-migration.sh

  integration-tests:
    name: Integration Tests (Docker)
    runs-on: ubuntu-latest
    strategy:
      matrix:
        env: [ubuntu-22, ubuntu-20, debian-12]
    steps:
      - uses: actions/checkout@v4

      - name: Build Docker test environment
        run: |
          docker build -f .github/testing/Dockerfile.${{ matrix.env }} \
            -t aida-test-${{ matrix.env }} .

      - name: Run integration tests
        run: |
          docker run --rm \
            -v ${{ github.workspace }}:/workspace \
            aida-test-${{ matrix.env }} \
            bash -c "cd /workspace && tests/integration/test-config-workflow.sh"

  regression-tests:
    name: Regression Tests
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install dependencies
        run: sudo apt-get update && sudo apt-get install -y jq

      - name: Run regression tests
        run: |
          tests/regression/test-existing-config-helper.sh

  secret-detection-tests:
    name: Secret Detection Tests
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install dependencies
        run: |
          sudo apt-get update && sudo apt-get install -y jq
          pip install pre-commit

      - name: Test pre-commit hook
        run: |
          tests/unit/test-secret-detection.sh

  performance-tests:
    name: Performance Tests
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install dependencies
        run: sudo apt-get update && sudo apt-get install -y jq

      - name: Run performance tests
        run: |
          tests/performance/test-config-performance.sh

  test-summary:
    name: Test Summary
    needs: [unit-tests, integration-tests, regression-tests, secret-detection-tests, performance-tests]
    runs-on: ubuntu-latest
    if: always()
    steps:
      - name: Report results
        run: |
          echo "## Test Results" >> $GITHUB_STEP_SUMMARY
          echo "✅ All test suites completed" >> $GITHUB_STEP_SUMMARY
```

### Test Fixtures and Sample Configs

**Directory Structure**:

```text
tests/fixtures/
├── git-remotes/
│   ├── github-ssh.txt              # git@github.com:user/repo.git
│   ├── github-https.txt            # https://github.com/user/repo.git
│   ├── gitlab-ssh.txt              # git@gitlab.com:group/project.git
│   ├── gitlab-self-hosted.txt      # git@gitlab.company.com:team/project.git
│   ├── bitbucket-ssh.txt           # git@bitbucket.org:workspace/slug.git
│   └── invalid-urls.txt            # Invalid remote URLs
├── valid-configs/
│   ├── github-minimal.json         # Minimal GitHub config
│   ├── github-full.json            # Full GitHub config with all fields
│   ├── gitlab-minimal.json         # Minimal GitLab config
│   ├── bitbucket-minimal.json      # Minimal Bitbucket config
│   ├── jira-work-tracker.json      # Config with Jira work tracker
│   ├── team-config.json            # Team config with reviewers
│   └── multi-provider.json         # Multiple providers configured
├── invalid-configs/
│   ├── missing-owner.json          # Missing required vcs.owner
│   ├── missing-repo.json           # Missing required vcs.repo
│   ├── invalid-provider.json       # Invalid vcs.provider value
│   ├── corrupt-json.json           # Malformed JSON
│   ├── wrong-types.json            # Fields with wrong types
│   └── secrets-in-config.json      # Config with secrets (for detection test)
├── edge-cases/
│   ├── special-chars-repo.json     # Repo name with special characters
│   ├── unicode-values.json         # Unicode in config values
│   ├── deeply-nested.json          # Deeply nested JSON structure
│   ├── empty-arrays.json           # Empty arrays in config
│   └── null-values.json            # Null values in optional fields
└── migration/
    ├── old-github-format.json      # Old github.* namespace
    ├── mixed-old-new.json          # Both old and new namespaces
    └── expected-migrated.json      # Expected result after migration
```

**Sample Fixture**:

```json
// tests/fixtures/valid-configs/github-full.json
{
  "config_version": "1.0",
  "vcs": {
    "provider": "github",
    "owner": "oakensoul",
    "repo": "claude-personal-assistant",
    "main_branch": "main",
    "github": {
      "enterprise_url": null
    }
  },
  "work_tracker": {
    "provider": "github_issues",
    "github_issues": {
      "enabled": true
    }
  },
  "team": {
    "review_strategy": "list",
    "default_reviewers": ["alice", "bob"],
    "members": [
      {
        "username": "alice",
        "role": "tech-lead",
        "availability": "available"
      },
      {
        "username": "bob",
        "role": "developer",
        "availability": "available"
      }
    ]
  },
  "workflow": {
    "commit": {
      "auto_commit": true
    },
    "pr": {
      "auto_version_bump": true,
      "update_changelog": true,
      "draft_by_default": false
    }
  }
}
```

## 4. Effort & Complexity

### Test Suite Size/Complexity

**Estimated Test Suite**:

| Test Category | Files | Test Cases | LOC | Complexity |
|---------------|-------|------------|-----|------------|
| Unit Tests | 5 | 50-60 | 1,200 | MEDIUM |
| Integration Tests | 3 | 30-40 | 800 | MEDIUM-HIGH |
| Regression Tests | 1 | 10-15 | 300 | LOW |
| Performance Tests | 1 | 5-10 | 200 | LOW |
| **Total** | **10** | **95-125** | **2,500** | **MEDIUM** |

**Complexity Drivers**:

- **VCS Auto-Detection**: Complex regex patterns, multiple providers (HIGH)
- **Config Merging**: Deep merge logic, namespace conflicts (HIGH)
- **Platform Compatibility**: BSD vs GNU commands (MEDIUM)
- **Secret Detection**: Regex patterns, false positives (MEDIUM)
- **Migration**: One-time logic, backward compatibility (MEDIUM)

**Comparison to Existing Tests**:

- `test-config-wrapper.sh`: 345 LOC, 8 test cases (reference baseline)
- **Issue #55 tests**: ~7x larger, ~15x more test cases (expected for foundational infrastructure)

### Cross-Platform Testing Burden

**Existing Infrastructure** (`.github/testing/`):

- ✅ Docker-based testing already implemented
- ✅ Multiple environments (Ubuntu 22/20, Debian 12, minimal)
- ✅ CI/CD integration exists
- ✅ Bash 3.2 compatibility already tested (macOS)

**Additional Burden for Issue #55**:

1. **New platform-specific tests**: ~200 LOC
2. **Docker test execution**: Already automated
3. **CI/CD workflow updates**: ~50 LOC YAML
4. **Maintenance**: LOW (infrastructure exists)

**Mitigation**: Leverage existing Docker infrastructure, minimal additional burden.

### Maintenance Overhead

**Ongoing Maintenance**:

| Component | Maintenance Frequency | Effort |
|-----------|----------------------|--------|
| Unit tests | Per provider added | 2-4 hours |
| Integration tests | Per major feature | 1-2 hours |
| Regression tests | Per breaking change | 1 hour |
| Fixtures | Per provider added | 30 min |
| CI/CD workflow | Per infrastructure change | 1 hour |

**Total Estimated Maintenance**: 4-8 hours per quarter

**Maintenance Triggers**:

- New VCS provider added (GitLab, Bitbucket implementations)
- Schema version changes (migrations)
- Platform updates (new Ubuntu LTS, macOS version)
- Security updates (new secret patterns)

**Mitigation Strategies**:

- **Fixture-driven tests**: Adding new provider = add fixtures, minimal code changes
- **Generic test patterns**: Reuse test logic across providers
- **CI/CD automation**: Catch regressions automatically
- **Documentation**: Maintain `tests/README.md` with testing guide

## 5. Questions & Clarifications

### Q1: What's minimum acceptable test coverage?

**Recommendation**: **85% overall, 95% for critical paths**

**Rationale**:

- **VCS auto-detection** (95%): Highest risk, most complex logic
- **Config validation** (90%): Security-critical (secret detection)
- **Config merging** (85%): Complex but lower risk
- **Error messaging** (70%): Nice-to-have, not critical

**Measurement**: Manual function coverage tracking (bashcov if available)

**Acceptance Criteria**:

- All critical paths tested (auto-detection, validation, merging)
- All error scenarios tested (invalid URLs, corrupt JSON, missing git)
- All platform-specific code tested (macOS + Linux)
- All migration paths tested (old → new format)

### Q2: Should we test with real git repos or mocks?

**Recommendation**: **Both, depending on test type**

**Strategy**:

- **Unit tests**: Use mocks/stubs (faster, isolated)
- **Integration tests**: Use real git repos (more realistic)
- **CI/CD tests**: Use Docker with real git (full end-to-end)

**Example**:

```bash
# Unit test: Mock git remote
mock_git_remote_command "git@github.com:user/repo.git"
test_github_detection

# Integration test: Real git repo
create_test_git_repo "/tmp/test-repo" "git@github.com:user/repo.git"
cd /tmp/test-repo
test_auto_detection_workflow
```

**Rationale**:

- Mocks: Faster, no network, isolated, good for edge cases
- Real repos: Catch real-world issues (git version differences, network timeouts)

### Q3: How to test auto-detection without network?

**Recommendation**: **Parse git remote URLs locally (no API calls)**

**Implementation**:

Auto-detection ONLY parses `git remote get-url origin` output (local command).
It does NOT make API calls to GitHub/GitLab/Bitbucket APIs.

**Test Approach**:

```bash
# No network required - just parse git remote URL
test_github_detection_no_network() {
    # Create local git repo with remote
    mkdir -p /tmp/test-repo
    cd /tmp/test-repo
    git init
    git remote add origin git@github.com:oakensoul/test-repo.git

    # Auto-detection works without network
    local result
    result=$(detect_vcs_from_remote "$(git remote get-url origin)")

    assert_equals "github" "$(echo "$result" | jq -r '.provider')"
}
```

**Runtime validation** (optional `--verify-connection` flag) DOES make API calls, but is DEFERRED to Issue #56.

### Q4: What's the regression test strategy?

**Recommendation**: **Three-tier regression testing**

**Tier 1: Functionality Regression** (Before ANY changes)

```bash
# Baseline: Capture current behavior
tests/regression/test-existing-config-helper.sh > results/baseline.txt

# After changes: Compare
tests/regression/test-existing-config-helper.sh > results/current.txt
diff results/baseline.txt results/current.txt
```

**Tier 2: Migration Regression** (During migration period)

```bash
# Test old format still works
test_old_github_namespace_readable() {
    create_old_config  # github.owner, github.repo
    local owner
    owner=$(aida-config-helper.sh --key github.owner)
    assert_equals "expected-owner" "$owner"
}
```

**Tier 3: API Regression** (Ensure commands still work)

```bash
# Test downstream commands that depend on config
test_start_work_command_still_works() {
    # /start-work depends on aida-config-helper.sh
    local result
    result=$(/start-work 123 2>&1)
    assert_not_contains "$result" "config error"
}
```

**Execution Frequency**:

- **Pre-commit**: Tier 1 (existing functionality)
- **Pre-PR**: Tier 1 + Tier 2 (migration compatibility)
- **Post-release**: Tier 3 (command integration)

### Q5: How to validate provider-specific rules without API calls?

**Recommendation**: **Format validation only (regex), NOT existence validation**

**Example**:

```bash
# GOOD: Format validation (no API call)
validate_github_config() {
    local owner="$1"
    local repo="$2"

    # Regex: alphanumeric, hyphens, underscores
    if ! [[ "$owner" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        error "Invalid GitHub owner format: $owner"
        return 1
    fi

    if ! [[ "$repo" =~ ^[a-zA-Z0-9._-]+$ ]]; then
        error "Invalid GitHub repo format: $repo"
        return 1
    fi
}

# BAD: Existence validation (requires API call - defer to --verify-connection)
validate_github_repo_exists() {
    curl -s https://api.github.com/repos/$owner/$repo  # NO - defer to Issue #56
}
```

**Test Approach**:

```bash
test_github_owner_format_validation() {
    # Valid formats
    assert_valid_github_owner "oakensoul"
    assert_valid_github_owner "oak-en_soul"

    # Invalid formats
    assert_invalid_github_owner "oak@ensoul"  # Special char
    assert_invalid_github_owner ""            # Empty
}

test_jira_project_key_format() {
    # Valid: uppercase alphanumeric, max 10 chars
    assert_valid_jira_key "AIDA"
    assert_valid_jira_key "PROJ123"

    # Invalid
    assert_invalid_jira_key "lowercase"       # Not uppercase
    assert_invalid_jira_key "TOOLONGKEY123"   # > 10 chars
}
```

**Runtime connectivity validation** (`--verify-connection` flag) is DEFERRED to Issue #56.

### Q6: Should we test all git remote URL formats?

**Recommendation**: **Yes - test comprehensive URL pattern matrix**

**Test Matrix**:

| Provider | SSH | HTTPS | Self-Hosted | Enterprise | Subgroups |
|----------|-----|-------|-------------|------------|-----------|
| GitHub | ✅ | ✅ | N/A | ✅ | N/A |
| GitLab | ✅ | ✅ | ✅ | N/A | ✅ |
| Bitbucket | ✅ | ✅ | ✅ | N/A | N/A |

**Example Test**:

```bash
test_github_enterprise_url() {
    local remote="git@github.company.com:team/repo.git"
    local result
    result=$(detect_vcs_from_remote "$remote")

    assert_equals "github" "$(echo "$result" | jq -r '.provider')"
    assert_equals "github.company.com" "$(echo "$result" | jq -r '.enterprise_url')"
}

test_gitlab_subgroup_detection() {
    local remote="git@gitlab.com:parent-group/subgroup/project.git"
    local result
    result=$(detect_vcs_from_remote "$remote")

    assert_equals "gitlab" "$(echo "$result" | jq -r '.provider')"
    assert_equals "parent-group/subgroup" "$(echo "$result" | jq -r '.group')"
}
```

**Rationale**: URL parsing is the foundation of auto-detection. Must be comprehensive and robust.

### Q7: How to test secret detection pre-commit hook?

**Recommendation**: **Dedicated test suite with known-bad configs**

**Test Approach**:

```bash
# tests/unit/test-secret-detection.sh

test_detect_github_token() {
    test_header "Detect GitHub personal access token"

    # Create config with secret
    cat > /tmp/bad-config.json << 'EOF'
{
    "github": {
        "token": "ghp_1234567890abcdefghijklmnopqrstuvwxyz"
    }
}
EOF

    # Pre-commit hook should catch it
    if pre-commit run --files /tmp/bad-config.json 2>&1 | grep -q "GitHub token detected"; then
        test_result "PASS" "Secret detection caught GitHub token"
    else
        test_result "FAIL" "Secret detection MISSED GitHub token"
    fi

    rm -f /tmp/bad-config.json
}

test_detect_api_key_pattern() {
    test_header "Detect generic API key pattern"

    cat > /tmp/bad-config.json << 'EOF'
{
    "jira": {
        "api_key": "abc123xyz789"
    }
}
EOF

    if pre-commit run --files /tmp/bad-config.json 2>&1 | grep -q "API key detected"; then
        test_result "PASS" "Secret detection caught API key"
    else
        test_result "FAIL" "Secret detection MISSED API key"
    fi

    rm -f /tmp/bad-config.json
}

test_allow_env_var_references() {
    test_header "Allow environment variable references"

    cat > /tmp/good-config.json << 'EOF'
{
    "github": {
        "token_env_var": "GITHUB_TOKEN"
    }
}
EOF

    # Should NOT trigger detection (referencing env var, not actual secret)
    if pre-commit run --files /tmp/good-config.json 2>&1 | grep -q "Secret detected"; then
        test_result "FAIL" "Secret detection false positive on env var reference"
    else
        test_result "PASS" "Secret detection correctly allowed env var reference"
    fi

    rm -f /tmp/good-config.json
}
```

**Secret Patterns to Test**:

```bash
# GitHub tokens
ghp_[a-zA-Z0-9]{36}
gho_[a-zA-Z0-9]{36}
ghr_[a-zA-Z0-9]{36}

# Generic API keys
api_key=["']?[a-zA-Z0-9]{20,}["']?
token=["']?[a-zA-Z0-9]{20,}["']?

# Jira API tokens
[a-zA-Z0-9]{24}  # (if in jira.api_token field)
```

### Q8: How to test config caching invalidation?

**Recommendation**: **Test checksum-based cache invalidation**

**Test Approach**:

```bash
# tests/performance/test-config-caching.sh

test_cache_invalidation_on_config_change() {
    test_header "Cache invalidates when config file changes"

    # Create initial config
    create_test_config "/tmp/test-config.json" '{"vcs": {"owner": "user1"}}'

    # Load config (caches it)
    local result1
    result1=$(aida-config-helper.sh --config /tmp/test-config.json)

    # Modify config
    sleep 1  # Ensure mtime changes
    create_test_config "/tmp/test-config.json" '{"vcs": {"owner": "user2"}}'

    # Load config again (should invalidate cache)
    local result2
    result2=$(aida-config-helper.sh --config /tmp/test-config.json)

    # Should reflect new value
    assert_equals "user2" "$(echo "$result2" | jq -r '.vcs.owner')"

    rm -f /tmp/test-config.json
}

test_cache_persists_across_calls() {
    test_header "Cache persists when config unchanged"

    create_test_config "/tmp/test-config.json" '{"vcs": {"owner": "user1"}}'

    # First call
    aida-config-helper.sh --config /tmp/test-config.json > /dev/null

    # Cache file should exist
    assert_file_exists "/tmp/aida-config-cache-$$"

    # Second call (same config)
    aida-config-helper.sh --config /tmp/test-config.json > /dev/null

    # Cache should still exist (not recreated)
    assert_file_exists "/tmp/aida-config-cache-$$"

    rm -f /tmp/test-config.json
}
```

## Risk Assessment & Mitigation

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| **Auto-detection failures** | MEDIUM | HIGH | Comprehensive URL pattern tests, fallback to manual config |
| **Platform-specific test failures** | MEDIUM | MEDIUM | Docker-based cross-platform testing, BSD/GNU compatibility layer |
| **Test suite maintenance burden** | LOW | MEDIUM | Fixture-driven tests, generic patterns, CI/CD automation |
| **Regression in existing config helper** | LOW | HIGH | Dedicated regression test suite, pre-commit hooks |
| **Secret detection false positives** | MEDIUM | LOW | Well-tuned regex patterns, whitelist for env var refs |
| **Performance degradation** | LOW | MEDIUM | Performance tests in CI/CD, caching optimization |

## Recommendations Summary

### MUST HAVE (Blocking for Issue #55)

1. ✅ **Unit tests for VCS auto-detection** (50+ test cases, all URL formats)
2. ✅ **Integration tests for config merging** (deep merge, namespace conflicts)
3. ✅ **Cross-platform tests** (macOS + Linux Docker environments)
4. ✅ **Regression tests** (existing `aida-config-helper.sh` still works)
5. ✅ **Secret detection tests** (pre-commit hook catches known patterns)
6. ✅ **Edge case tests** (invalid URLs, corrupt JSON, special characters)

### SHOULD HAVE (High Priority)

1. ✅ **Performance tests** (caching, validation < 1s)
2. ✅ **Migration tests** (old format → new format)
3. ✅ **Error message validation** (actionable, helpful)
4. ✅ **CI/CD integration** (automated testing on every PR)
5. ✅ **Test fixtures** (comprehensive sample configs)

### NICE TO HAVE (Defer if time-constrained)

1. ⏸ **Code coverage reporting** (bashcov integration)
2. ⏸ **Load testing** (1000+ config loads)
3. ⏸ **Fuzz testing** (random config generation)
4. ⏸ **Visual test reports** (HTML output)

## Next Steps (QA Implementation Roadmap)

### Phase 1: Test Infrastructure (Week 1)

1. Create test directory structure (`tests/unit/`, `tests/integration/`, `tests/fixtures/`)
2. Port existing `test-config-wrapper.sh` patterns to new test framework
3. Create test fixtures for all VCS providers
4. Set up CI/CD workflow (`.github/workflows/config-system-tests.yml`)

### Phase 2: Unit Tests (Week 1-2)

1. Implement VCS auto-detection tests (all URL patterns)
2. Implement config validation tests (schema + provider rules)
3. Implement config merging tests (deep merge, namespaces)
4. Implement secret detection tests (pre-commit hook)
5. Implement migration tests (old → new format)

### Phase 3: Integration Tests (Week 2)

1. Implement end-to-end config workflow tests
2. Implement cross-platform compatibility tests (Docker)
3. Implement error scenario tests (invalid URLs, corrupt JSON)
4. Implement performance tests (caching, validation timing)

### Phase 4: Regression & Validation (Week 3)

1. Run regression tests against existing `aida-config-helper.sh`
2. Validate test coverage (aim for 85%+)
3. Review and refine error messages based on test results
4. Document testing guide (`tests/README.md`)

### Phase 5: CI/CD Integration (Week 3)

1. Integrate tests into GitHub Actions
2. Configure test matrix (macOS, Ubuntu 22, Ubuntu 20, Debian 12)
3. Set up automated test reporting
4. Configure pre-commit hooks for secret detection

## Conclusion

**Testing Approach**: Comprehensive, multi-layered, platform-focused

**Key Success Factors**:

- Leverage existing test infrastructure (`.github/testing/`, custom bash framework)
- Exhaustive VCS auto-detection testing (highest risk area)
- Real cross-platform testing (Docker-based, not mocked)
- Strong regression testing (backward compatibility)
- Security-critical secret detection (pre-commit hooks)

**Effort Estimate**: 2-3 weeks for comprehensive test suite (95-125 test cases, 2,500 LOC)

**Confidence Level**: HIGH - Existing infrastructure + clear test requirements = manageable complexity

---

**Related Files**:

- PRD: `.github/issues/in-progress/issue-55/prd.md`
- Technical Spec: `.github/issues/in-progress/issue-55/technical-specification.md` (pending)
- Test Infrastructure: `.github/testing/`, `lib/installer-common/test-*.sh`

**Dependencies**: None (test infrastructure exists)

**Blocks**: Issue #56 implementation (requires validated config system)
