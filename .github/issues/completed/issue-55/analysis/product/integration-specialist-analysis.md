---
title: "Integration Specialist Analysis - Issue #55"
issue: 55
analyst: "integration-specialist"
created: "2025-10-20"
status: "draft"
---

# Integration Specialist Analysis - Configuration System with VCS Abstraction

## Executive Summary

**Context**: Project-level integration knowledge detected. Working with AIDA project integration requirements including Obsidian, GNU Stow, Git workflows, MCP servers, and shell integration.

**Notice**: No user-level integration specialist knowledge found. Providing analysis based on project context and generic best practices.

**Recommendation**: Create `~/.claude/agents/integration-specialist/knowledge/` for reusable integration patterns across all projects.

## 1. Domain-Specific Concerns

### Integration Points Analysis

**Existing Workflow Commands** (`/start-work`, `/open-pr`, `/cleanup-main`):

- **Current state**: Hardcoded GitHub CLI (`gh`) usage throughout
- **Impact area**: ~500+ lines across 3 commands with `gh issue`, `gh pr`, `gh api` calls
- **Migration path**: Abstract to VCS provider interface, not direct config changes
- **Breaking change risk**: HIGH if config structure changes, MEDIUM if provider interface introduced

**Provider Abstraction Pattern**:

```yaml
# BAD: Commands directly read config and call gh CLI
/open-pr reads config.github.* → calls gh pr create

# GOOD: Commands call VCS interface → interface reads config → calls provider CLI
/open-pr → VCS.create_pr() → GitHubProvider.create_pr() → gh pr create
                           → GitLabProvider.create_pr() → glab mr create
```

**Configuration Schema Integration**:

```yaml
# Hierarchical config loading pattern
vcs:
  provider: "github"  # Auto-detected from git remote
  github:
    api_url: "https://api.github.com"
    organization: "oakensoul"
    project:
      name: "AIDA Development"
      status_field: "Status"
  gitlab:  # Project may use GitLab for other repos
    api_url: "https://gitlab.com/api/v4"
    group: "oakensoul"

work_tracker:
  provider: "github-issues"  # Could be "jira", "linear", etc.
  github_issues:
    # Uses same config as vcs.github
  jira:  # Future: separate tracker
    url: "https://company.atlassian.net"
    project: "AIDA"
```

**Key Integration Concerns**:

- **VCS operations**: Issue viewing, PR creation, label management, branch operations
- **Work tracker operations**: Issue creation, status transitions, time tracking
- **Config validation**: Schema validation before commands run (fail fast)
- **Auto-detection logic**: Parse `git remote -v`, map to provider, populate defaults
- **Error handling**: Graceful degradation when provider API unavailable

### Provider Abstraction Patterns

**Interface Contract** (applies to all providers):

```python
# Pseudo-code for VCS provider interface
class VCSProvider:
    def detect_from_remote(remote_url: str) -> str:
        """github.com → github, gitlab.com → gitlab"""
        pass

    def get_issue(issue_id: str) -> Issue:
        """Fetch issue details (provider-agnostic)"""
        pass

    def create_pr(title: str, body: str, labels: list) -> PullRequest:
        """Create PR with consistent interface"""
        pass

    def update_issue_status(issue_id: str, status: str):
        """Update issue status (maps to provider-specific field)"""
        pass

    def assign_issue(issue_id: str, assignee: str):
        """Assign issue to user"""
        pass
```

**Provider Feature Matrix**:

| Feature | GitHub | GitLab | Bitbucket | Abstraction Strategy |
|---------|--------|--------|-----------|---------------------|
| Issues | ✓ | ✓ | ✓ (Jira) | Required - all providers |
| PRs/MRs | ✓ | ✓ | ✓ | Required - different terminology |
| Labels | ✓ | ✓ | ✗ | Optional - graceful skip |
| Projects | ✓ | ✓ Boards | ✗ | Optional - feature flag |
| Auto-assign | ✓ | ✓ | ✓ | Required - common pattern |
| Draft PRs | ✓ | ✓ | ✗ | Optional - fallback to regular PR |

**Recommendation**: **Required** vs **Optional** feature detection with graceful degradation:

```bash
# Feature detection pattern
if provider_supports_feature("labels"); then
  apply_labels "$pr_number" "$labels"
else
  log_warning "Provider does not support labels, skipping"
fi
```

### API Compatibility Across Providers

**GitHub vs GitLab vs Bitbucket Command Mapping**:

| Operation | GitHub (`gh`) | GitLab (`glab`) | Bitbucket (API) | Abstraction |
|-----------|--------------|----------------|-----------------|-------------|
| Create PR | `gh pr create --title X --body Y` | `glab mr create --title X --description Y` | `bb pr create` | `vcs_create_pr()` |
| View issue | `gh issue view 42 --json` | `glab issue view 42 --output-format json` | `bb issue get 42` | `vcs_get_issue()` |
| List labels | `gh label list --json` | `glab label list --output-format json` | N/A (use Jira) | `vcs_list_labels()` |
| Push branch | `git push -u origin X` | `git push -u origin X` | `git push -u origin X` | **No abstraction needed** |

**Key Differences**:

- **Terminology**: PR (GitHub/Bitbucket) vs MR (GitLab)
- **CLI flags**: `--body` (GitHub) vs `--description` (GitLab)
- **JSON output**: Different schemas require field mapping
- **Work trackers**: Bitbucket → Jira integration (separate API)

**Abstraction Strategy**:

```bash
# Wrapper functions in lib/vcs-provider.sh
vcs_create_pr() {
  local title="$1"
  local body="$2"
  local labels="$3"

  case "$VCS_PROVIDER" in
    github)
      gh pr create --title "$title" --body "$body" --label "$labels"
      ;;
    gitlab)
      glab mr create --title "$title" --description "$body" --label "$labels"
      ;;
    bitbucket)
      # Bitbucket CLI or API call
      bb pr create --title "$title" --description "$body"
      ;;
    *)
      echo "Error: Unsupported VCS provider: $VCS_PROVIDER"
      exit 1
      ;;
  esac
}
```

### Future Extensibility

**Plugin Architecture for Custom Providers**:

```yaml
# User can define custom provider in config
vcs:
  provider: "custom-gitlab-instance"
  custom_providers:
    custom-gitlab-instance:
      type: "gitlab"  # Inherits from GitLab provider
      api_url: "https://gitlab.company.com/api/v4"
      cli_command: "glab"
      remote_pattern: "gitlab.company.com"
```

**Extension Points**:

1. **Custom CLI detection**: Map remote URL to provider
2. **Custom API endpoints**: Override default API URLs
3. **Custom field mappings**: Map "Status" to provider-specific field names
4. **Custom authentication**: OAuth, PAT, SSH keys per provider

**Provider Plugin Structure**:

```text
lib/
├── vcs-providers/
│   ├── github.sh          # GitHub implementation
│   ├── gitlab.sh          # GitLab implementation
│   ├── bitbucket.sh       # Bitbucket implementation
│   ├── base-provider.sh   # Common interface contract
│   └── custom/            # User-defined providers
│       └── company-gitlab.sh
└── vcs-interface.sh       # Dispatcher (routes to provider)
```

**Recommendation**: Start with GitHub/GitLab/Bitbucket providers. Document plugin interface for future extension.

## 2. Stakeholder Impact

### Workflow Command Users

**Breaking Changes Risk**:

- **Config structure change**: `github.project` → `vcs.github.project`
- **Impact**: Existing `workflow-config.json` files become invalid
- **Users affected**: All users who ran `/workflow-init` (v0.1.6+)

**Migration Strategy**:

```bash
# Option 1: Auto-migration script (RECOMMENDED)
# Detect old config, migrate to new structure, preserve values
if config_has_old_structure; then
  migrate_config_v1_to_v2
  log "Config migrated from v1 (github.*) to v2 (vcs.*)"
fi

# Option 2: Deprecation period
# Support both old and new config for 2-3 versions
if config.github exists; then
  log_warning "Config format deprecated. Run /workflow-init to upgrade."
  use_legacy_config
else
  use_new_vcs_config
fi

# Option 3: Hard break (NOT RECOMMENDED - too early in project lifecycle)
# Require manual migration
```

**Recommendation**: **Auto-migration** with deprecation warnings. Support both formats for 2 minor versions.

**User Communication**:

```text
CHANGELOG v0.2.0:
- BREAKING: Configuration schema updated for VCS provider abstraction
- MIGRATION: Run `/workflow-init` to upgrade config automatically
- DEPRECATED: `github.*` config (still supported in v0.2.x, removed in v0.3.0)
- NEW: Multi-provider support (GitHub, GitLab, Bitbucket)
```

### Multi-Provider Teams

**Use Case**: Team uses GitHub for `claude-personal-assistant`, GitLab for internal tools

**Config Hierarchy**:

```yaml
# ~/.claude/config.yml (user-level defaults)
vcs:
  provider: "github"  # Default for most projects
  github:
    organization: "oakensoul"

# /path/to/internal-project/.claude/config.yml (project-level override)
vcs:
  provider: "gitlab"  # Override for this project
  gitlab:
    group: "company-internal"
    api_url: "https://gitlab.company.com/api/v4"
```

**Config Loading Logic**:

```bash
# 1. Load user-level config (~/.claude/config.yml)
# 2. Load project-level config (${PROJECT_ROOT}/.claude/config.yml)
# 3. Merge with project overriding user
# 4. Auto-detect provider from git remote (if not explicitly set)
# 5. Validate final merged config
```

**Recommendation**: **Full support** for per-project provider switching. User default + project override pattern.

### Plugin Developers

**Can They Add Custom Providers?**

**YES** - with documented plugin interface:

```bash
# lib/vcs-providers/custom-example.sh

# Required: Provider detection
provider_detect_custom_example() {
  local remote_url="$1"
  [[ "$remote_url" =~ custom-example\.com ]] && echo "custom-example"
}

# Required: Core operations
provider_custom_example_get_issue() {
  local issue_id="$1"
  # Call custom API or CLI
  custom-cli issue view "$issue_id" --json
}

provider_custom_example_create_pr() {
  local title="$1"
  local body="$2"
  # Call custom API or CLI
  custom-cli pr create --title "$title" --body "$body"
}

# Optional: Provider-specific features
provider_custom_example_supports_feature() {
  local feature="$1"
  case "$feature" in
    labels) return 0 ;;  # Supported
    drafts) return 1 ;;  # Not supported
    *) return 1 ;;
  esac
}
```

**Plugin Registration**:

```yaml
# ~/.claude/config.yml
vcs:
  custom_providers:
    - name: "custom-example"
      script: "~/.claude/lib/vcs-providers/custom-example.sh"
      cli_command: "custom-cli"
```

**Recommendation**: Document plugin interface in `docs/integration/vcs-provider-plugins.md`. Provide example plugin.

## 3. Questions & Clarifications

### Provider-Specific Features

**Question**: How to handle GitHub Projects vs GitLab Boards?

**Analysis**:

- GitHub: Projects V2 with GraphQL API, complex status field mapping
- GitLab: Issue Boards with simpler REST API
- Bitbucket: No native boards (uses Jira)

**Recommendation**:

```yaml
# Make project tracking OPTIONAL and provider-specific
vcs:
  github:
    project:
      enabled: true  # Feature flag
      name: "AIDA Development"
      status_field: "Status"
  gitlab:
    board:
      enabled: true
      board_id: 123
      list_mapping:
        todo: "Prioritized"
        in_progress: "In Progress"
```

**Implementation**:

```bash
# Commands check if project tracking is enabled
if config.vcs.${provider}.project.enabled; then
  update_project_status "$issue_id" "$new_status"
else
  log_debug "Project tracking disabled for $provider, skipping"
fi
```

**Answer**: Use **feature flags** with provider-specific config sections. Commands check capability before attempting operations.

### Multiple VCS Providers in Single Project

**Question**: Should we support GitHub + Bitbucket in one project?

**Analysis**:

- **Use case**: Rare - usually one primary VCS per repo
- **Complexity**: High - which provider for which operation?
- **Alternative**: Use project-level config to switch providers per repo

**Recommendation**: **NO** - one VCS provider per project. Use config hierarchy for multi-repo workflows.

**Rationale**:

- Simpler mental model: One `.git` remote = one VCS provider
- Auto-detection always unambiguous
- Users with complex needs can create custom provider plugins

**Edge case handling**:

```bash
# If multiple remotes detected (origin + upstream)
if multiple_vcs_providers_detected; then
  log_warning "Multiple VCS providers detected in remotes"
  log_warning "Using primary remote 'origin' for provider detection"
  # Use primary remote (origin) for provider
fi
```

### Work Tracker Abstraction

**Question**: How to abstract issue operations (create, transition status)?

**Design Pattern**:

```bash
# Work tracker interface (separate from VCS)
work_tracker_create_issue() {
  case "$WORK_TRACKER_PROVIDER" in
    github-issues)
      gh issue create --title "$title" --body "$body"
      ;;
    jira)
      jira_cli issue create -p "$project" -s "$title" -d "$body"
      ;;
    linear)
      linear issue create --title "$title" --description "$body"
      ;;
  esac
}

work_tracker_transition_status() {
  local issue_id="$1"
  local new_status="$2"

  case "$WORK_TRACKER_PROVIDER" in
    github-issues)
      # GitHub uses project boards for status
      gh issue edit "$issue_id" --add-project-field "Status=$new_status"
      ;;
    jira)
      # Jira uses transitions
      jira_cli issue transition "$issue_id" "$new_status"
      ;;
    linear)
      # Linear uses state IDs
      linear issue update "$issue_id" --state "$new_status"
      ;;
  esac
}
```

**Config Schema**:

```yaml
work_tracker:
  provider: "jira"  # Can differ from VCS provider!
  jira:
    url: "https://company.atlassian.net"
    project: "AIDA"
    status_transitions:
      start_work:
        from: "Backlog"
        to: "In Progress"
      open_pr:
        from: "In Progress"
        to: "In Review"
```

**Answer**: **Separate abstraction** for work tracker. VCS provider != work tracker provider (e.g., Bitbucket + Jira).

### Provider Interface Contract

**Question**: What's the minimum provider interface contract?

**Required Operations** (all providers MUST support):

```bash
# Detection
provider_detect()            # Detect from git remote URL

# Issue operations
provider_get_issue()         # Fetch issue details
provider_assign_issue()      # Assign issue to user

# PR/MR operations
provider_create_pr()         # Create pull/merge request
provider_get_pr()            # Fetch PR details

# Branch operations
provider_list_branches()     # List remote branches (git-based, may not need abstraction)
```

**Optional Operations** (providers MAY support):

```bash
# Label operations
provider_supports_labels()   # Feature detection
provider_list_labels()       # List available labels
provider_apply_labels()      # Apply labels to PR

# Project/board operations
provider_supports_projects() # Feature detection
provider_update_status()     # Update issue/PR status

# Draft PR support
provider_supports_drafts()   # Feature detection
provider_create_draft_pr()   # Create draft PR
```

**Interface Validation**:

```bash
# On provider load, validate interface
validate_provider_interface() {
  local provider="$1"

  # Check required functions exist
  for func in detect get_issue assign_issue create_pr; do
    if ! type "provider_${provider}_${func}" &>/dev/null; then
      log_error "Provider $provider missing required function: $func"
      exit 1
    fi
  done

  # Optional functions are fine if missing
  log_info "Provider $provider validated successfully"
}
```

**Answer**: **Required** (detect, issue ops, PR ops) + **Optional** (labels, projects, drafts). Validate on load.

## 4. Recommendations

### Provider Abstraction Strategy

**Three-Layer Architecture**:

```text
┌─────────────────────────────────────────────┐
│  Commands (/start-work, /open-pr, etc.)    │
│  - Call VCS interface (provider-agnostic)  │
└─────────────────┬───────────────────────────┘
                  │
┌─────────────────▼───────────────────────────┐
│  VCS Interface (lib/vcs-interface.sh)      │
│  - Auto-detect provider from git remote    │
│  - Load provider implementation            │
│  - Route to provider-specific functions    │
└─────────────────┬───────────────────────────┘
                  │
        ┌─────────┴──────────┬─────────────┐
        ▼                    ▼             ▼
┌───────────────┐  ┌────────────────┐  ┌──────────────┐
│ GitHub        │  │ GitLab         │  │ Bitbucket    │
│ Provider      │  │ Provider       │  │ Provider     │
│ (github.sh)   │  │ (gitlab.sh)    │  │(bitbucket.sh)│
└───────────────┘  └────────────────┘  └──────────────┘
```

**Implementation Phases**:

**Phase 1** (Issue #55 - Configuration Infrastructure):

- Create `.claude/config.yml` schema with `vcs.*` structure
- Implement VCS provider auto-detection from `git remote -v`
- Add config validation (schema enforcement)
- Document provider abstraction design (not implemented yet)

**Phase 2** (Issue #56-59 - Provider Implementations):

- Create `lib/vcs-interface.sh` (dispatcher)
- Implement `lib/vcs-providers/github.sh` (migrate existing `gh` calls)
- Implement `lib/vcs-providers/gitlab.sh` (`glab` CLI)
- Implement `lib/vcs-providers/bitbucket.sh` (Bitbucket API)

**Phase 3** (Future - Command Migration):

- Refactor `/start-work` to use VCS interface
- Refactor `/open-pr` to use VCS interface
- Refactor `/cleanup-main` to use VCS interface
- Add integration tests for each provider

**Recommendation**: **Start simple** (Issue #55 just creates config schema). **Defer complexity** (provider implementations in later issues).

### Integration Testing Approach

**Test Strategy** (per provider):

```bash
# tests/integration/vcs-providers/github-provider.test.sh

test_github_detect_from_remote() {
  local remote="https://github.com/oakensoul/claude-personal-assistant.git"
  local provider=$(vcs_detect_provider "$remote")
  assert_equals "github" "$provider"
}

test_github_get_issue() {
  # Mock gh CLI response
  mock_gh_issue_view() {
    cat <<EOF
{"number": 55, "title": "Test Issue", "state": "OPEN"}
EOF
  }

  local issue=$(vcs_get_issue "55")
  assert_contains "$issue" "Test Issue"
}

test_github_create_pr() {
  # Integration test (requires real GitHub auth)
  if [ -z "$GITHUB_TOKEN" ]; then
    skip "GITHUB_TOKEN not set"
  fi

  local pr_url=$(vcs_create_pr "Test PR" "Test body" "version:patch")
  assert_matches "$pr_url" "https://github.com/.*/pull/[0-9]+"
}
```

**Test Coverage**:

- **Unit tests**: Provider detection, config parsing, validation
- **Integration tests**: Real API calls (requires auth, runs in CI)
- **Mock tests**: Simulate provider responses (fast, no auth needed)

**CI/CD Integration**:

```yaml
# .github/workflows/test-vcs-providers.yml
name: Test VCS Providers

on: [push, pull_request]

jobs:
  test-providers:
    strategy:
      matrix:
        provider: [github, gitlab, bitbucket]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install provider CLI
        run: |
          case "${{ matrix.provider }}" in
            github) gh version ;;
            gitlab) glab version ;;
            bitbucket) pip install bitbucket-cli ;;
          esac
      - name: Run provider tests
        run: ./tests/integration/vcs-providers/${{ matrix.provider }}-provider.test.sh
        env:
          PROVIDER_TOKEN: ${{ secrets[format('{0}_TOKEN', matrix.provider)] }}
```

**Recommendation**: **Mock-first** testing for fast feedback. **Integration tests** in CI with real credentials.

### Graceful Degradation

**When Provider Unsupported**:

```bash
# In command execution
if ! provider_supports_feature "labels"; then
  log_warning "Provider does not support labels"
  log_warning "Skipping label application for PR #$pr_number"
  # Continue without labels
fi

# In config validation
validate_provider_support() {
  local provider="$1"

  case "$provider" in
    github|gitlab|bitbucket)
      return 0  # Supported
      ;;
    *)
      log_error "Unsupported VCS provider: $provider"
      log_error "Supported providers: github, gitlab, bitbucket"
      log_error ""
      log_error "To add custom provider, see docs/integration/vcs-provider-plugins.md"
      exit 1
      ;;
  esac
}
```

**Feature Detection Pattern**:

```bash
# Before using optional feature
if vcs_supports_feature "projects"; then
  vcs_update_project_status "$issue_id" "In Progress"
else
  log_info "Project tracking not available for $VCS_PROVIDER"
  # Command continues without project update
fi
```

**User Communication**:

```text
⚠ WARNING: GitLab provider detected
  Feature 'draft PRs' not supported by GitLab
  Creating regular MR instead

✓ Merge request created: https://gitlab.com/user/repo/-/merge_requests/42
```

**Recommendation**: **Fail gracefully** for optional features. **Fail fast** for required operations (issue creation, PR creation).

### Plugin/Extension Points

**Custom Provider Registration**:

```yaml
# ~/.claude/config.yml
vcs:
  custom_providers:
    company-gitlab:
      type: "gitlab"  # Inherits from gitlab provider
      remote_pattern: "gitlab.company.com"
      api_url: "https://gitlab.company.com/api/v4"
      cli_command: "glab"  # Or custom: /usr/local/bin/company-git-cli
```

**Plugin Discovery**:

```bash
# lib/vcs-interface.sh
load_custom_providers() {
  local provider_dir="${CLAUDE_CONFIG}/lib/vcs-providers/custom"

  if [ -d "$provider_dir" ]; then
    for provider_script in "$provider_dir"/*.sh; do
      if [ -f "$provider_script" ]; then
        source "$provider_script"
        log_debug "Loaded custom provider: $(basename "$provider_script" .sh)"
      fi
    done
  fi
}
```

**Plugin Template** (`~/.claude/lib/vcs-providers/custom/template.sh`):

```bash
#!/bin/bash
# Custom VCS Provider Template
# Copy this file to create your custom provider

# Provider name (must match config key)
PROVIDER_NAME="my-custom-provider"

# Required: Detect if remote URL matches this provider
provider_detect_my_custom_provider() {
  local remote_url="$1"
  [[ "$remote_url" =~ my-git-server\.com ]] && echo "$PROVIDER_NAME"
}

# Required: Get issue details
provider_my_custom_provider_get_issue() {
  local issue_id="$1"
  # Call your custom API or CLI
  my-git-cli issue view "$issue_id" --format json
}

# Required: Create pull request
provider_my_custom_provider_create_pr() {
  local title="$1"
  local body="$2"
  local labels="$3"
  # Call your custom API or CLI
  my-git-cli pr create --title "$title" --body "$body" --labels "$labels"
}

# Optional: Feature support
provider_my_custom_provider_supports_feature() {
  local feature="$1"
  case "$feature" in
    labels) return 0 ;;
    projects) return 1 ;;  # Not supported
    *) return 1 ;;
  esac
}
```

**Documentation**: Create `docs/integration/vcs-provider-plugins.md` with:

- Plugin interface specification
- Required vs optional functions
- Testing custom providers
- Example custom provider

**Recommendation**: **Provide template** and **clear documentation** for custom providers. Support in v0.2.0+.

## 5. Integration Architecture Diagram

```text
Configuration Hierarchy & Provider Abstraction
================================================

┌─────────────────────────────────────────────────────────┐
│  User-Level Config (~/.claude/config.yml)              │
│  ┌─────────────────────────────────────────────────┐   │
│  │ vcs:                                            │   │
│  │   provider: "github"  # Default for all repos  │   │
│  │   github:                                       │   │
│  │     organization: "oakensoul"                   │   │
│  └─────────────────────────────────────────────────┘   │
└───────────────────────┬─────────────────────────────────┘
                        │ (inherits + overrides)
┌───────────────────────▼─────────────────────────────────┐
│  Project-Level Config (${PROJECT}/.claude/config.yml)  │
│  ┌─────────────────────────────────────────────────┐   │
│  │ vcs:                                            │   │
│  │   provider: "gitlab"  # Override for this repo │   │
│  │   gitlab:                                       │   │
│  │     group: "company"                            │   │
│  │     api_url: "https://gitlab.company.com"       │   │
│  └─────────────────────────────────────────────────┘   │
└───────────────────────┬─────────────────────────────────┘
                        │ (load + validate)
┌───────────────────────▼─────────────────────────────────┐
│  Auto-Detection (git remote -v)                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │ https://gitlab.company.com/repo.git             │   │
│  │                          │                      │   │
│  │                          ▼                      │   │
│  │               Detected: "gitlab"                │   │
│  │                          │                      │   │
│  │            (confirms config provider)           │   │
│  └─────────────────────────────────────────────────┘   │
└───────────────────────┬─────────────────────────────────┘
                        │ (dispatch to provider)
┌───────────────────────▼─────────────────────────────────┐
│  VCS Interface (lib/vcs-interface.sh)                   │
│  ┌─────────────────────────────────────────────────┐   │
│  │ vcs_create_pr() {                               │   │
│  │   case "$VCS_PROVIDER" in                       │   │
│  │     github) provider_github_create_pr ;;        │   │
│  │     gitlab) provider_gitlab_create_pr ;;        │   │
│  │     *)      unsupported_provider_error ;;       │   │
│  │   esac                                          │   │
│  │ }                                               │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────┬───────────────┬───────────────────────────┘
              │               │
      ┌───────▼──────┐  ┌────▼──────────┐
      │ GitHub       │  │ GitLab        │
      │ Provider     │  │ Provider      │
      │ (github.sh)  │  │ (gitlab.sh)   │
      │              │  │               │
      │ gh pr create │  │ glab mr create│
      └──────────────┘  └───────────────┘
```

## 6. Migration Path for Existing Users

**Step 1**: Install v0.2.0 with new config schema

**Step 2**: Auto-migration script detects old config:

```bash
# On first command execution after upgrade
if [ -f ~/.claude/config/workflow-config.json ]; then
  if ! config_has_vcs_section; then
    log_info "Detecting legacy config format..."
    log_info "Migrating to new VCS provider schema..."

    # Backup old config
    cp ~/.claude/config/workflow-config.json ~/.claude/config/workflow-config.json.backup

    # Migrate: github.* → vcs.github.*
    migrate_config_to_vcs_schema

    log_info "✓ Config migrated successfully"
    log_info "  Backup saved: ~/.claude/config/workflow-config.json.backup"
    log_info "  New config: ~/.claude/config.yml"
  fi
fi
```

**Step 3**: Deprecation warnings for old config references:

```bash
# Commands check for old config usage
if config_using_github_direct; then
  log_warning "DEPRECATED: 'github.*' config will be removed in v0.3.0"
  log_warning "Run '/workflow-init' to upgrade to VCS provider config"
fi
```

**Step 4**: v0.3.0 removes old config support

**Recommendation**: **2-version deprecation cycle**. Auto-migrate on first use. Warn for 2 versions. Remove in v0.3.0.

## 7. Configuration Schema Validation

**Schema Definition** (`lib/config-schema.yml`):

```yaml
# JSON Schema for .claude/config.yml validation
$schema: "http://json-schema.org/draft-07/schema#"
type: "object"
required: ["vcs"]
properties:
  vcs:
    type: "object"
    required: ["provider"]
    properties:
      provider:
        type: "string"
        enum: ["github", "gitlab", "bitbucket"]
      github:
        type: "object"
        properties:
          organization:
            type: "string"
          project:
            type: "object"
            properties:
              enabled:
                type: "boolean"
              name:
                type: "string"
              status_field:
                type: "string"
      gitlab:
        type: "object"
        properties:
          group:
            type: "string"
          api_url:
            type: "string"
            format: "uri"
  work_tracker:
    type: "object"
    properties:
      provider:
        type: "string"
        enum: ["github-issues", "jira", "linear"]
```

**Validation Function**:

```bash
validate_config() {
  local config_file="$1"

  # Check file exists
  if [ ! -f "$config_file" ]; then
    log_error "Config file not found: $config_file"
    return 1
  fi

  # Validate YAML syntax
  if ! yq eval '.' "$config_file" >/dev/null 2>&1; then
    log_error "Invalid YAML syntax in $config_file"
    return 1
  fi

  # Validate required fields
  if ! yq eval '.vcs.provider' "$config_file" >/dev/null 2>&1; then
    log_error "Missing required field: vcs.provider"
    return 1
  fi

  # Validate provider value
  local provider=$(yq eval '.vcs.provider' "$config_file")
  case "$provider" in
    github|gitlab|bitbucket)
      log_debug "Valid provider: $provider"
      ;;
    *)
      log_error "Invalid provider: $provider"
      log_error "Supported: github, gitlab, bitbucket"
      return 1
      ;;
  esac

  return 0
}
```

**Recommendation**: Validate config on load. Fail fast with clear error messages.

## 8. Next Steps

**For Issue #55** (Configuration Infrastructure):

1. Create `.claude/config.yml` schema specification document
2. Implement config file generation in `/workflow-init`
3. Add VCS provider auto-detection from `git remote -v`
4. Add config validation function with schema enforcement
5. Document hierarchical config loading (user + project merge)
6. Add migration script for existing `workflow-config.json` files

**For Future Issues** (Provider Implementation):

- **Issue #56**: Jira work tracker integration
- **Issue #57**: GitLab VCS provider implementation
- **Issue #58**: Linear work tracker integration
- **Issue #59**: Bitbucket VCS provider implementation

**Documentation Needed**:

- `docs/configuration/config-schema.md` - Full schema reference
- `docs/integration/vcs-providers.md` - Provider abstraction design
- `docs/integration/vcs-provider-plugins.md` - Custom provider guide
- `docs/migration/v0.1-to-v0.2.md` - Migration guide for users

---

## Analysis Complete

**Key Takeaways**:

1. **Provider abstraction is critical** - Don't just rename config keys
2. **Three-layer architecture** - Commands → VCS Interface → Provider Implementations
3. **Graceful degradation** - Optional features should not block workflows
4. **Auto-migration** - Detect and upgrade old configs automatically
5. **Plugin system** - Allow custom providers via documented interface

**Risk Level**: MEDIUM - Breaking changes managed through auto-migration
**Complexity**: HIGH - Multi-provider abstraction requires careful design
**Value**: HIGH - Enables multi-VCS teams and extensibility
