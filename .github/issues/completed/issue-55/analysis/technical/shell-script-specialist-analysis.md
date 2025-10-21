---
title: "Shell Script Specialist Analysis - Configuration System (#55)"
issue: 55
analyst: "shell-script-specialist"
created: "2025-10-20"
status: "draft"
category: "technical-analysis"
---

# Shell Script Specialist Analysis: Configuration System with VCS Abstraction

## Executive Summary

**Complexity**: **MEDIUM** (M)

**Confidence**: HIGH - Well-scoped utility development with clear integration points

**Key Insight**: This is primarily a refactoring and extension task that builds on existing, proven infrastructure (`aida-config-helper.sh`). The new utilities (`vcs-detector.sh`, `config-validator.sh`) follow established patterns with well-understood challenges (cross-platform compatibility, JSON manipulation with jq).

**Risk Level**: LOW - Contained scope, existing testing infrastructure, fallback strategies

## 1. Implementation Approach

### 1.1 Shell Script Architecture

**Modular Design Following Existing Patterns**:

```text
lib/
├── aida-config-helper.sh          # EXISTING - Extend with new namespaces
├── installer-common/
│   ├── vcs-detector.sh           # NEW - Git remote parsing and provider detection
│   ├── config-validator.sh       # NEW - JSON Schema validation and provider rules
│   ├── config-schema.json        # NEW - JSON Schema definition
│   └── config-migration.sh       # NEW - github.* → vcs.* migration
```

**Key Functions to Implement**:

```bash
# vcs-detector.sh
detect_vcs_provider()      # Parse git remote → {provider, owner, repo}
extract_github_info()      # GitHub-specific URL patterns
extract_gitlab_info()      # GitLab-specific URL patterns
extract_bitbucket_info()   # Bitbucket-specific URL patterns
detect_main_branch()       # git symbolic-ref → main/master
get_detection_confidence() # high/medium/low based on match quality

# config-validator.sh
validate_config_structure()   # JSON Schema validation (Tier 1)
validate_provider_rules()     # Provider-specific field validation (Tier 2)
validate_vcs_github()         # GitHub: owner+repo required
validate_vcs_gitlab()         # GitLab: project_id required
validate_work_tracker_jira()  # Jira: base_url+project_key format
validate_team_config()        # Team: review_strategy + members

# config-migration.sh
migrate_github_to_vcs()    # github.* → vcs.github.*
backup_config()            # Create timestamped backup
check_needs_migration()    # Detect old format
```

### 1.2 Git Remote Parsing Strategy

**URL Patterns to Support**:

```bash
# GitHub
git@github.com:owner/repo.git
https://github.com/owner/repo.git
https://github.com/owner/repo  # No .git suffix
git@github.enterprise.com:owner/repo.git  # Enterprise

# GitLab
git@gitlab.com:owner/repo.git
https://gitlab.com/owner/repo.git
https://gitlab.self-hosted.com/group/repo.git

# Bitbucket
git@bitbucket.org:workspace/repo.git
https://bitbucket.org/workspace/repo.git
```

**Implementation with Regex**:

```bash
detect_vcs_provider() {
  local remote_url
  remote_url=$(git remote get-url origin 2>/dev/null || echo "")

  if [[ -z "$remote_url" ]]; then
    echo "none"
    return 1
  fi

  # GitHub detection (supports enterprise)
  if [[ "$remote_url" =~ github\.com|ghe\. ]]; then
    extract_github_info "$remote_url"
    return 0
  fi

  # GitLab detection
  if [[ "$remote_url" =~ gitlab\. ]]; then
    extract_gitlab_info "$remote_url"
    return 0
  fi

  # Bitbucket detection
  if [[ "$remote_url" =~ bitbucket\. ]]; then
    extract_bitbucket_info "$remote_url"
    return 0
  fi

  # Unknown provider
  echo "unknown"
  return 1
}

extract_github_info() {
  local url="$1"
  local owner repo

  # SSH format: git@github.com:owner/repo.git
  if [[ "$url" =~ git@[^:]+:([^/]+)/([^/]+)(\.git)?$ ]]; then
    owner="${BASH_REMATCH[1]}"
    repo="${BASH_REMATCH[2]%.git}"  # Strip .git if present
  # HTTPS format: https://github.com/owner/repo.git
  elif [[ "$url" =~ https://[^/]+/([^/]+)/([^/]+)(\.git)?$ ]]; then
    owner="${BASH_REMATCH[1]}"
    repo="${BASH_REMATCH[2]%.git}"
  else
    return 1
  fi

  jq -n \
    --arg provider "github" \
    --arg owner "$owner" \
    --arg repo "$repo" \
    --arg confidence "high" \
    '{
      provider: $provider,
      owner: $owner,
      repo: $repo,
      confidence: $confidence
    }'
}
```

**Confidence Levels**:

- **HIGH**: Exact domain match (github.com → github)
- **MEDIUM**: Pattern match but ambiguous (custom domain → could be GitHub Enterprise or GitLab)
- **LOW**: Fallback guess based on URL structure

### 1.3 JSON Manipulation with jq

**Deep Merge Strategy** (already implemented in `aida-config-helper.sh`):

```bash
# Deep merge with jq's * operator (right-biased merge)
jq -n \
  --argjson sys "$system_defaults" \
  --argjson user "$user_config" \
  --argjson project "$project_config" \
  '$sys * $user * $project'
```

**Namespace Extraction**:

```bash
# Get vcs.* namespace
get_config_namespace "vcs" | jq '.'

# Get provider-specific config
get_config_namespace "vcs" | jq '.github'
```

**Array Merge for Reviewers** (NEW for team.default_reviewers):

```bash
# Union of arrays (remove duplicates)
jq -n \
  --argjson user '{"team":{"default_reviewers":["alice","bob"]}}' \
  --argjson project '{"team":{"default_reviewers":["bob","charlie"]}}' \
  '$user * $project | .team.default_reviewers |= unique'
```

### 1.4 Cross-Platform Compatibility

**Platform Detection Patterns** (already established in existing code):

```bash
# Detect OS (from aida-config-helper.sh get_file_checksum)
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS (BSD tools)
  stat -f "%m" "$file"
  md5 -q
else
  # Linux (GNU tools)
  stat -c "%Y" "$file"
  md5sum | cut -d' ' -f1
fi
```

**Git Command Compatibility**:

- `git remote get-url origin` - Works on Git 2.0+ (2014), universally supported
- `git symbolic-ref refs/remotes/origin/HEAD` - Reliable main branch detection
- `git config user.name` - Already used in existing code

**jq Dependency**: Already required by `aida-config-helper.sh`, no new dependency

**Bash Version Compatibility**: Bash 3.2+ required (already validated in `validation.sh` line 231)

## 2. Technical Concerns

### 2.1 Performance Considerations

**Detection Overhead**:

- **Git command latency**: 10-50ms per `git remote get-url` call
- **jq parsing**: 5-20ms for typical config files (< 5KB)
- **Total overhead**: 50-100ms per detection cycle

**Mitigation Strategy** (already implemented):

```bash
# Session-based caching from aida-config-helper.sh
readonly CACHE_FILE="/tmp/aida-config-cache-$$"  # PID-scoped
readonly CHECKSUM_FILE="/tmp/aida-config-checksum-$$"

# Checksum-based invalidation (lines 120-150)
get_config_checksum()  # Hash all config files + env vars
is_cache_valid()       # Check if cache matches current state
```

**Performance Profile**:

- First call: 100ms (detection + merge + cache)
- Subsequent calls: < 5ms (cache hit)
- Cache invalidation: Automatic when config files change

### 2.2 Error Handling Strategy

**Git Command Failures**:

```bash
# Safe git remote detection with fallback
detect_vcs_provider() {
  local remote_url

  # Handle missing git repo
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    print_message "warn" "Not in a git repository"
    echo '{"provider":"none","confidence":"high"}'
    return 0  # Not an error, just no VCS
  fi

  # Handle missing remote
  if ! remote_url=$(git remote get-url origin 2>/dev/null); then
    print_message "warn" "No git remote 'origin' found"
    echo '{"provider":"none","confidence":"high"}'
    return 0
  fi

  # Parse remote URL
  # ... detection logic ...
}
```

**jq Availability**:

```bash
# Already implemented in aida-config-helper.sh line 64-72
check_jq_dependency() {
  if ! command -v jq >/dev/null 2>&1; then
    print_message "error" "Required dependency 'jq' not found"
    print_message "info" "Install jq:"
    print_message "info" "  macOS: brew install jq"
    print_message "info" "  Linux: sudo apt-get install jq"
    exit 1
  fi
}
```

**Invalid JSON Config**:

```bash
# Already implemented in aida-config-helper.sh line 276-289
read_json_config() {
  local file="$1"

  if [[ ! -f "$file" ]]; then
    echo "{}"
    return 0
  fi

  # Try to parse JSON, return empty object on error
  if ! jq '.' "$file" 2>/dev/null; then
    log_to_file "WARNING" "Invalid JSON in config file: $file"
    echo "{}"  # Graceful degradation
  fi
}
```

**Validation Failures with Actionable Errors**:

```bash
validate_vcs_github() {
  local config="$1"
  local errors=0

  # Check required fields
  local owner repo
  owner=$(echo "$config" | jq -r '.vcs.github.owner // empty')
  repo=$(echo "$config" | jq -r '.vcs.github.repo // empty')

  if [[ -z "$owner" ]] || [[ -z "$repo" ]]; then
    print_message "error" "GitHub configuration incomplete"

    # Auto-detect and suggest fix
    local detected
    detected=$(detect_vcs_provider)
    local detected_owner detected_repo
    detected_owner=$(echo "$detected" | jq -r '.owner')
    detected_repo=$(echo "$detected" | jq -r '.repo')

    if [[ -n "$detected_owner" ]]; then
      print_message "info" "Auto-detected from git remote:"
      print_message "info" "  Owner: $detected_owner"
      print_message "info" "  Repo: $detected_repo"
      print_message "info" "Quick fix: aida-config-helper.sh --set vcs.github.owner $detected_owner"
    fi

    return 1
  fi

  return 0
}
```

### 2.3 Shell Portability

**Bash 3.2 Compatibility** (macOS default):

- **AVOID**: Associative arrays (`declare -A`) - Bash 4.0+ only
- **AVOID**: `readarray` / `mapfile` - Bash 4.0+ only
- **USE**: Regular arrays, `IFS` read, parameter expansion
- **USE**: POSIX regex with `[[ =~ ]]` (Bash 3.0+)

**Regex Compatibility**:

```bash
# GOOD - POSIX Extended Regex (Bash 3.0+)
if [[ "$url" =~ ^https://github\.com/([^/]+)/([^/]+) ]]; then
  owner="${BASH_REMATCH[1]}"
  repo="${BASH_REMATCH[2]}"
fi

# BAD - Named capture groups (not supported in Bash)
if [[ "$url" =~ (?P<owner>[^/]+)/(?P<repo>[^/]+) ]]; then
  # Won't work
fi
```

**String Manipulation**:

```bash
# GOOD - Parameter expansion (POSIX)
repo="${BASH_REMATCH[2]%.git}"  # Strip .git suffix

# GOOD - IFS for parsing
IFS='/' read -r owner repo <<< "$path"

# AVOID - sed/awk unless truly necessary (use parameter expansion)
```

### 2.4 Testing Strategy

**Unit Testing Approach**:

```bash
# Create test harness similar to existing validate-*.sh scripts
lib/installer-common/test-vcs-detector.sh
lib/installer-common/test-config-validator.sh

# Test cases
test_detect_github_ssh() {
  local url="git@github.com:oakensoul/claude-personal-assistant.git"
  local result
  result=$(extract_github_info "$url")

  assert_equals "github" "$(echo "$result" | jq -r '.provider')"
  assert_equals "oakensoul" "$(echo "$result" | jq -r '.owner')"
  assert_equals "claude-personal-assistant" "$(echo "$result" | jq -r '.repo')"
}

test_detect_gitlab_https() {
  # ...
}

test_invalid_url() {
  # Should return "unknown" provider, not crash
}
```

**Integration Testing**:

```bash
# Test against real git repos
test_real_repo_detection() {
  cd /path/to/test/repo
  local result
  result=$(detect_vcs_provider)

  # Verify detected provider matches actual remote
  assert_equals "github" "$(echo "$result" | jq -r '.provider')"
}
```

**Cross-Platform Testing** (Docker-based):

```bash
# Leverage existing .github/testing/test-install.sh infrastructure
.github/testing/test-install.sh --env ubuntu-22  # Linux
.github/testing/test-install.sh --env macos-13   # macOS

# Add config-specific tests
.github/testing/test-config-detection.sh
```

## 3. Dependencies & Integration

### 3.1 Required Dependencies

**No New External Dependencies**:

- `jq` - Already required by `aida-config-helper.sh`
- `git` - Assumed present (AIDA is git-based)
- `bash 3.2+` - Already validated by `validation.sh`
- `realpath` - Already required (from validation.sh line 118)

**Existing Utilities to Leverage**:

- `installer-common/logging.sh` - `print_message()`, `log_to_file()`
- `installer-common/validation.sh` - `validate_file_permissions()`, `validate_dependencies()`
- `installer-common/colors.sh` - Color constants for output

### 3.2 Integration with aida-config-helper.sh

**Extend Namespace Support**:

```bash
# CURRENT: get_system_defaults() - lines 191-265
# Add new namespaces to default structure

get_system_defaults() {
  # ... existing paths, user, git, github ...

  # NEW NAMESPACES
  jq -n \
    --arg aida_home "$aida_home" \
    # ... existing args ...
    '{
      # ... existing fields ...

      vcs: {
        provider: "",
        owner: "",
        repo: "",
        main_branch: "main",
        github: {
          enterprise_url: null
        },
        gitlab: {
          project_id: null,
          self_hosted_url: null,
          group: null
        },
        bitbucket: {
          workspace: null,
          repo_slug: null
        }
      },
      work_tracker: {
        provider: "github_issues",
        github_issues: {
          enabled: true
        },
        jira: {
          base_url: null,
          project_key: null
        },
        linear: {
          team_id: null,
          board_id: null
        }
      },
      team: {
        review_strategy: "list",
        default_reviewers: [],
        members: []
      }
    }'
}
```

**Add Validation Hooks**:

```bash
# Extend validate_config() - lines 556-589
validate_config() {
  local required_keys=(
    "paths.aida_home"
    "paths.claude_config_dir"
    "paths.home"
    # NEW: VCS validation
    "vcs.provider"
    "vcs.owner"
    "vcs.repo"
  )

  # ... existing validation logic ...

  # NEW: Provider-specific validation
  local provider
  provider=$(echo "$merged_config" | jq -r '.vcs.provider')

  case "$provider" in
    github)
      validate_vcs_github "$merged_config" || errors=$((errors + 1))
      ;;
    gitlab)
      validate_vcs_gitlab "$merged_config" || errors=$((errors + 1))
      ;;
    bitbucket)
      validate_vcs_bitbucket "$merged_config" || errors=$((errors + 1))
      ;;
    none)
      # Valid to have no VCS provider
      ;;
    *)
      print_message "error" "Unknown VCS provider: $provider"
      errors=$((errors + 1))
      ;;
  esac

  # ... existing error reporting ...
}
```

### 3.3 How Detection Utilities Are Called

**Call Flow**:

```text
User runs: aida command (e.g., /start-work)
    ↓
Command sources: lib/aida-config-helper.sh
    ↓
Config helper calls: get_merged_config()
    ↓
Merge configs calls: get_project_config()
    ↓
Project config includes: .aida/config.json (may have vcs.* section)
    ↓
If vcs.provider empty: Auto-detection runs
    ↓
Auto-detect calls: lib/installer-common/vcs-detector.sh detect_vcs_provider()
    ↓
Detection returns: {provider: "github", owner: "oakensoul", repo: "..."}
    ↓
Merge into config: vcs.* fields populated
    ↓
Validation runs: lib/installer-common/config-validator.sh validate_vcs_github()
    ↓
Result: Fully validated config returned to command
```

**Lazy Detection Pattern**:

```bash
# Only run detection if config is incomplete
get_vcs_config() {
  local config
  config=$(get_merged_config)

  local provider
  provider=$(echo "$config" | jq -r '.vcs.provider // empty')

  if [[ -z "$provider" ]] || [[ "$provider" == "null" ]]; then
    # Auto-detect
    local detected
    detected=$(detect_vcs_provider)

    # Merge detected values into config
    config=$(echo "$config" | jq \
      --argjson detected "$detected" \
      '.vcs = (.vcs * $detected)')
  fi

  echo "$config"
}
```

## 4. Effort & Complexity Estimation

### 4.1 Complexity Assessment: MEDIUM (M)

**Rationale**:

- **Extension, not rewrite**: Builds on existing `aida-config-helper.sh` infrastructure
- **Well-understood patterns**: Git parsing, JSON manipulation, cross-platform compatibility already solved in codebase
- **Clear scope**: 3 new utilities with defined responsibilities
- **Existing test infrastructure**: Docker-based cross-platform testing already in place
- **Proven dependencies**: jq + bash 3.2 compatibility already validated

### 4.2 Effort Drivers

**Development Effort** (Estimated: 8-12 hours):

1. **VCS Detector** (3-4 hours)
   - Git remote parsing with regex patterns (GitHub, GitLab, Bitbucket)
   - Confidence scoring logic
   - Main branch detection
   - Unit tests for URL patterns

2. **Config Validator** (3-4 hours)
   - JSON Schema validation (structure)
   - Provider-specific rules (GitHub, GitLab, Jira, Linear)
   - Error message templates with auto-detected values
   - Validation test suite

3. **Migration Script** (2-3 hours)
   - Backup logic
   - Namespace transformation (github.*→ vcs.github.*)
   - Migration detection (when to run)
   - Rollback strategy

4. **Integration** (1-2 hours)
   - Extend `aida-config-helper.sh` with new namespaces
   - Hook validation into existing flow
   - Update installer to run migration
   - End-to-end testing

**Testing Effort** (Estimated: 4-6 hours):

- Unit tests for each utility (2 hours)
- Cross-platform validation (macOS + Linux) (2 hours)
- Integration testing with real repos (1 hour)
- Edge case testing (missing remotes, invalid URLs, etc.) (1 hour)

**Documentation Effort** (Estimated: 2-3 hours):

- Update `lib/installer-common/README-config-aggregator.md`
- Create schema reference documentation
- Document provider patterns and detection logic
- Update CONTRIBUTING.md with validation guidelines

**Total Effort**: 14-21 hours (MEDIUM complexity)

### 4.3 Risky/Tricky Parts

**HIGH RISK**:

1. **Regex Pattern Matching**
   - **Risk**: Edge cases in URL formats (enterprise domains, custom ports, non-standard paths)
   - **Mitigation**: Comprehensive test suite with real-world examples, fallback to "unknown" provider

2. **Migration Breaking Changes**
   - **Risk**: Auto-migration corrupts existing configs, breaking workflows
   - **Mitigation**: Backup before migration, dry-run mode, 2-version deprecation period

**MEDIUM RISK**:

3. **Cross-Platform stat/md5 Commands**
   - **Risk**: Already solved in existing code (lines 83-107 of aida-config-helper.sh)
   - **Mitigation**: Reuse existing platform detection patterns

4. **JSON Schema Complexity**
   - **Risk**: Hand-written JSON Schema is error-prone
   - **Mitigation**: Use JSON Schema validators (e.g., `ajv-cli`), test with invalid configs

**LOW RISK**:

5. **Performance Overhead**
   - **Risk**: Detection adds latency to every command
   - **Mitigation**: Already solved with session-based caching

6. **jq Dependency**
   - **Risk**: jq not available on user's system
   - **Mitigation**: Already required and validated by existing code

## 5. Questions & Clarifications

### 5.1 Dependency Questions

**Q1: Should we vendor jq or require installation?**

**Recommendation**: **Require installation** (status quo)

**Rationale**:

- jq already required by `aida-config-helper.sh` (line 64)
- Existing dependency validation (validation.sh line 239)
- Installation instructions already documented
- Vendoring adds complexity (binary distribution, security updates)

**Alternative**: If vendoring desired, use GitHub releases:

```bash
# Download jq binary for platform
if ! command -v jq &>/dev/null; then
  print_message "info" "Downloading jq..."
  curl -L -o "${HOME}/.aida/bin/jq" "https://github.com/jqlang/jq/releases/download/jq-1.7/jq-${PLATFORM}"
  chmod +x "${HOME}/.aida/bin/jq"
  export PATH="${HOME}/.aida/bin:$PATH"
fi
```

**Decision**: Defer to tech-lead preference

### 5.2 Error Handling Questions

**Q2: How to handle git command timeout/failures?**

**Recommendation**: **Fail gracefully with fallback to manual config**

**Implementation**:

```bash
detect_vcs_provider() {
  # Timeout for git commands (5 seconds)
  local git_timeout=5

  # Use timeout command if available
  local timeout_cmd=""
  if command -v timeout &>/dev/null; then
    timeout_cmd="timeout ${git_timeout}"
  fi

  # Try to get remote URL with timeout
  local remote_url
  if ! remote_url=$($timeout_cmd git remote get-url origin 2>/dev/null); then
    print_message "warn" "Failed to detect VCS provider from git remote"
    print_message "info" "Please configure manually: aida-config-helper.sh --set vcs.provider github"
    echo '{"provider":"none","confidence":"low","error":"git_command_failed"}'
    return 0  # Not fatal, just no auto-detection
  fi

  # ... detection logic ...
}
```

**Fallback Behavior**:

- Auto-detection fails → provider = "none"
- Validation runs → detects required fields missing
- User sees actionable error: "Run `aida-config-helper.sh --set vcs.provider github`"

### 5.3 Testing Questions

**Q3: Unit testing strategy for shell scripts?**

**Recommendation**: **Follow existing pattern from validation module tests**

**Approach**:

```bash
# lib/installer-common/test-vcs-detector.sh
#!/usr/bin/env bash
set -euo pipefail

# Source the module under test
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/vcs-detector.sh"

# Simple assertion helpers
assert_equals() {
  local expected="$1"
  local actual="$2"
  local message="${3:-Assertion failed}"

  if [[ "$expected" != "$actual" ]]; then
    echo "FAIL: $message"
    echo "  Expected: $expected"
    echo "  Actual: $actual"
    return 1
  fi
  echo "PASS: $message"
}

# Test cases
test_github_ssh_detection() {
  local url="git@github.com:oakensoul/repo.git"
  local result
  result=$(extract_github_info "$url")

  assert_equals "github" "$(echo "$result" | jq -r '.provider')" "Provider"
  assert_equals "oakensoul" "$(echo "$result" | jq -r '.owner')" "Owner"
  assert_equals "repo" "$(echo "$result" | jq -r '.repo')" "Repo"
  assert_equals "high" "$(echo "$result" | jq -r '.confidence')" "Confidence"
}

test_github_https_detection() {
  # ...
}

test_invalid_url() {
  # ...
}

# Run all tests
main() {
  echo "Running VCS Detector Tests..."
  test_github_ssh_detection
  test_github_https_detection
  test_invalid_url
  echo "All tests passed!"
}

main "$@"
```

**Integration with Pre-Commit**:

```yaml
# .pre-commit-config.yaml
- repo: local
  hooks:
    - id: test-vcs-detector
      name: Test VCS Detector
      entry: lib/installer-common/test-vcs-detector.sh
      language: system
      pass_filenames: false
```

**Cross-Platform Testing** (Docker):

```bash
# Leverage existing .github/testing/test-install.sh
.github/testing/test-vcs-detector.sh
```

### 5.4 Design Questions

**Q4: Should auto-detection be opt-in or opt-out?**

**PRD Decision**: **Opt-out** (runs by default) - Already specified in PRD line 231

**Implementation**:

```bash
# In .aida/config.json
{
  "vcs": {
    "auto_detect": true  # Default: true
  }
}

# In detection logic
should_auto_detect() {
  local config
  config=$(get_merged_config)

  local auto_detect
  auto_detect=$(echo "$config" | jq -r '.vcs.auto_detect // true')

  [[ "$auto_detect" == "true" ]]
}
```

**Q5: How to handle multiple git remotes (origin vs upstream)?**

**PRD Decision**: Use primary remote (origin) - Already specified in PRD line 256

**Implementation**:

```bash
detect_vcs_provider() {
  # Try origin first (primary remote)
  local remote_url
  if remote_url=$(git remote get-url origin 2>/dev/null); then
    # Detect from origin
    extract_provider_info "$remote_url"
    return 0
  fi

  # Fallback: try upstream
  if remote_url=$(git remote get-url upstream 2>/dev/null); then
    print_message "warn" "No 'origin' remote found, using 'upstream' instead"
    extract_provider_info "$remote_url"
    return 0
  fi

  # No remotes found
  print_message "warn" "No git remotes found"
  echo '{"provider":"none","confidence":"high"}'
  return 0
}
```

### 5.5 Scope Questions

**Q6: Should we implement Tier 3 validation (API connectivity) in Issue #55?**

**PRD Guidance**: NO - Defer to later issues (line 316)

**Rationale**:

- Tier 1 (structure) + Tier 2 (provider rules) sufficient for Issue #55
- Tier 3 (connectivity) requires API credentials, increases complexity
- Can be added later as `--verify-connection` flag

**Recommendation**: Implement placeholder function, defer implementation:

```bash
# config-validator.sh
validate_api_connectivity() {
  local provider="$1"
  local config="$2"

  print_message "info" "API connectivity validation not yet implemented"
  print_message "info" "Use --verify-connection flag when available (future feature)"

  return 0  # Always succeed for now
}
```

## 6. Implementation Recommendations

### 6.1 Phased Development Approach

**Phase 1: Core Detection** (4-5 hours)

- Implement `vcs-detector.sh` with GitHub, GitLab, Bitbucket patterns
- Unit tests for URL parsing
- Cross-platform testing (macOS + Linux)

**Phase 2: Validation** (3-4 hours)

- Implement `config-validator.sh` with Tier 1 + Tier 2 validation
- Provider-specific validation functions
- Error message templates

**Phase 3: Migration** (2-3 hours)

- Implement `config-migration.sh`
- Backup and rollback logic
- Test with real configs

**Phase 4: Integration** (2-3 hours)

- Extend `aida-config-helper.sh` with new namespaces
- Hook validation into config loading
- Update installer

**Phase 5: Documentation & Testing** (3-4 hours)

- Documentation updates
- End-to-end integration tests
- Pre-commit hook integration

### 6.2 Testing Strategy

**Unit Testing**:

- Test each URL pattern (SSH, HTTPS, enterprise)
- Test invalid URLs (should return "unknown", not crash)
- Test missing git repo (should fail gracefully)
- Test validation rules (required fields, format validation)

**Integration Testing**:

- Test real git repos (GitHub, GitLab, Bitbucket)
- Test config merging with auto-detection
- Test migration from old to new format
- Test validation error messages

**Cross-Platform Testing**:

- macOS (BSD tools): stat, md5
- Linux (GNU tools): stat, md5sum
- Bash 3.2 (macOS default) vs Bash 5.0+ (Linux)

### 6.3 Code Quality Standards

**Follow Existing Patterns**:

- Source `installer-common/logging.sh` for `print_message()`
- Use `set -euo pipefail` for error handling
- Use `readonly` for constants
- Comprehensive comments (follow lib/*.sh style)

**ShellCheck Compliance**:

- Pass `shellcheck` with zero warnings
- Use `# shellcheck source=...` for sourced files
- Quote all variable expansions

**Pre-Commit Validation**:

- All scripts must pass existing pre-commit hooks
- Add new tests to pre-commit config

## 7. Success Criteria

**Issue #55 Complete When**:

1. VCS auto-detection works for GitHub, GitLab, Bitbucket (SSH + HTTPS)
2. Config validation enforces required fields per provider
3. Hierarchical loading merges user + project + detected config
4. Migration script converts `github.*` → `vcs.*` with backup
5. Pre-commit hook detects secrets in config files
6. Template config files created with examples
7. Unit tests pass on macOS + Linux
8. Integration tests validate full flow
9. Documentation updated (schema reference, provider patterns)

**User Validation**:

- Developer runs command in GitHub repo → VCS auto-detected
- Config validation fails → Error shows detected values + fix command
- Migration runs automatically → Old config backed up, new format works
- Pre-commit blocks commit with secrets → User sees actionable error

## 8. Risk Mitigation Summary

| Risk | Mitigation |
|------|------------|
| Regex pattern edge cases | Comprehensive test suite, fallback to "unknown" |
| Migration breaking configs | Backup before migration, dry-run mode, 2-version deprecation |
| Cross-platform compatibility | Reuse existing platform detection patterns |
| Git command failures | Timeout + graceful fallback to manual config |
| jq not available | Existing dependency validation, clear install instructions |
| Performance overhead | Session-based caching (already implemented) |

## 9. Next Steps

**Immediate Actions**:

1. Review this analysis with tech-lead for approval
2. Create feature branch: `feature/issue-55-config-system`
3. Implement Phase 1 (VCS detector) with tests
4. Iterate through Phases 2-5
5. Submit PR with comprehensive test coverage

**Coordination Required**:

- **Tech Lead**: Approve schema design and namespace structure
- **DevOps Engineer**: Review pre-commit hook integration
- **Security Engineer**: Review secret detection patterns
- **UX Designer**: Review error message templates

**Open Items**:

- Finalize jq vendoring decision (Q1)
- Confirm timeout strategy for git commands (Q2)
- Review test coverage requirements (Q3)

---

**Prepared by**: Shell Script Specialist Agent
**Reviewed by**: (Pending tech-lead approval)
**Status**: Draft - Ready for review
