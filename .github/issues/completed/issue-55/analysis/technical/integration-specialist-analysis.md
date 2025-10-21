---
title: "Integration Specialist Technical Analysis - Issue #55"
issue: 55
analyst: "integration-specialist"
analysis_type: "technical"
created: "2025-10-20"
status: "draft"
---

# Integration Specialist Technical Analysis - Configuration System (#55)

## Executive Summary

**Context**: Project-level integration knowledge detected. Working with AIDA integration requirements for VCS providers, work trackers, and multi-provider abstraction.

**Notice**: User-level integration specialist knowledge not found. Analysis based on project context and generic integration best practices.

**Recommendation**: This issue should focus on **configuration infrastructure only**. Provider implementations (GitHub, GitLab, Jira) deferred to Issues #56-59.

## 1. Implementation Approach

### Provider Interface Specification

**What methods are required for VCS abstraction?**

Define minimal contract in `lib/vcs-providers/base-provider.sh`:

```bash
#!/bin/bash
# Base VCS Provider Interface Contract
# All provider implementations MUST implement these functions

# ============================================================================
# REQUIRED OPERATIONS (all providers must support)
# ============================================================================

# Provider Detection
# Returns provider name if remote URL matches this provider, empty otherwise
# Args: $1 = remote URL (e.g., "https://github.com/owner/repo.git")
# Returns: provider name or empty string
provider_detect() {
  local remote_url="$1"
  # Implementation required
}

# Issue Operations
# Get issue details in standardized JSON format
# Args: $1 = issue ID
# Returns: JSON with {number, title, body, labels[], state, assignees[], milestone}
provider_get_issue() {
  local issue_id="$1"
  # Implementation required
}

# Assign issue to user
# Args: $1 = issue ID, $2 = username
# Returns: 0 on success, non-zero on failure
provider_assign_issue() {
  local issue_id="$1"
  local assignee="$2"
  # Implementation required
}

# Pull/Merge Request Operations
# Create PR/MR with standardized arguments
# Args: $1 = title, $2 = body, $3 = labels (comma-separated)
# Returns: PR URL
provider_create_pr() {
  local title="$1"
  local body="$2"
  local labels="$3"
  # Implementation required
}

# Get PR/MR details
# Args: $1 = PR number
# Returns: JSON with {number, title, url, state}
provider_get_pr() {
  local pr_number="$1"
  # Implementation required
}

# ============================================================================
# OPTIONAL OPERATIONS (graceful degradation if not supported)
# ============================================================================

# Feature Detection
# Returns 0 if feature supported, 1 if not
# Args: $1 = feature name (labels, projects, drafts, auto_merge)
provider_supports_feature() {
  local feature="$1"
  case "$feature" in
    labels|projects|drafts|auto_merge)
      # Override in implementation
      return 1  # Default: not supported
      ;;
    *)
      return 1
      ;;
  esac
}

# Label Operations (optional)
provider_list_labels() {
  log_warning "Provider does not support labels"
  return 1
}

provider_apply_labels() {
  local pr_number="$1"
  local labels="$2"
  log_warning "Provider does not support labels"
  return 1
}

# Project/Board Operations (optional)
provider_update_project_status() {
  local issue_id="$1"
  local status="$2"
  log_warning "Provider does not support project tracking"
  return 1
}

# Draft PR Support (optional)
provider_create_draft_pr() {
  local title="$1"
  local body="$2"
  log_warning "Provider does not support draft PRs, creating regular PR"
  provider_create_pr "$title" "$body" ""
}

# ============================================================================
# VALIDATION
# ============================================================================

# Validate provider implements required interface
validate_provider_interface() {
  local provider="$1"
  local required_functions=(
    "detect"
    "get_issue"
    "assign_issue"
    "create_pr"
    "get_pr"
  )

  for func in "${required_functions[@]}"; do
    if ! declare -f "provider_${provider}_${func}" >/dev/null 2>&1; then
      log_error "Provider '$provider' missing required function: $func"
      return 1
    fi
  done

  log_debug "Provider '$provider' interface validated"
  return 0
}
```

**Key Design Decisions**:

- **Standardized JSON output**: All providers return same schema (field mapping in provider implementation)
- **Feature detection**: Optional features checked before use (`supports_feature("labels")`)
- **Graceful degradation**: Missing optional features logged but don't block workflow
- **Exit codes**: 0 = success, 1 = feature unsupported, 2+ = error conditions

### Config Schema Structure for Provider-Specific Fields

**Two-tier configuration system** (user + project):

```json
{
  "config_version": "1.0",
  "vcs": {
    "provider": "github",
    "auto_detect": true,
    "owner": "oakensoul",
    "repo": "claude-personal-assistant",
    "main_branch": "main",
    "github": {
      "enterprise_url": null,
      "project": {
        "enabled": true,
        "name": "AIDA Development",
        "status_field": "Status",
        "status_transitions": {
          "start_work": {
            "from": "Prioritized",
            "to": "In Progress"
          },
          "open_pr": {
            "from": "In Progress",
            "to": "In Review"
          }
        }
      }
    },
    "gitlab": {
      "self_hosted_url": null,
      "group": null,
      "project_id": null,
      "board": {
        "enabled": false,
        "board_id": null,
        "list_mapping": {
          "todo": "To Do",
          "in_progress": "In Progress",
          "in_review": "Review"
        }
      }
    },
    "bitbucket": {
      "workspace": null,
      "repo_slug": null
    }
  },
  "work_tracker": {
    "provider": "github_issues",
    "github_issues": {
      "enabled": true
    },
    "jira": {
      "base_url": null,
      "project_key": null,
      "status_transitions": {
        "start_work": "In Progress",
        "open_pr": "In Review"
      }
    },
    "linear": {
      "team_id": null,
      "board_id": null
    }
  },
  "team": {
    "review_strategy": "list",
    "default_reviewers": ["user1", "user2"],
    "members": [
      {
        "username": "user1",
        "role": "tech-lead",
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

**Key Features**:

- **Namespace isolation**: `vcs.*`, `work_tracker.*`, `team.*`, `workflow.*`
- **Provider-specific sections**: `vcs.github.*`, `vcs.gitlab.*` (only populate active provider)
- **Config version field**: Enables future migrations
- **Common fields at top level**: `owner`, `repo`, `main_branch` (provider-agnostic)
- **Feature flags**: `enabled` fields for optional integrations

**File Locations**:

```text
~/.claude/config.json          # User-level defaults (600 permissions, NOT committed)
${PROJECT}/.aida/config.json   # Project-level config (644 permissions, committed)
```

### How Commands Dispatch to Correct Provider

**Three-layer architecture**:

```text
┌─────────────────────────────────────────────┐
│  Layer 1: Commands                          │
│  (/start-work, /open-pr, /cleanup-main)     │
│                                             │
│  - Load config (detect provider)            │
│  - Call VCS interface functions             │
│  - Handle responses                         │
└───────────────────┬─────────────────────────┘
                    │
                    │ vcs_get_issue("42")
                    │ vcs_create_pr(...)
                    ▼
┌─────────────────────────────────────────────┐
│  Layer 2: VCS Interface                     │
│  (lib/vcs-interface.sh)                     │
│                                             │
│  - Load provider implementation             │
│  - Dispatch to provider functions           │
│  - Handle errors & feature detection        │
└───────────┬─────────────┬───────────────────┘
            │             │
            ▼             ▼
┌──────────────────┐  ┌──────────────────┐
│ Layer 3: GitHub  │  │ Layer 3: GitLab  │
│ Provider         │  │ Provider         │
│ (github.sh)      │  │ (gitlab.sh)      │
│                  │  │                  │
│ - gh CLI calls   │  │ - glab CLI calls │
│ - JSON mapping   │  │ - JSON mapping   │
└──────────────────┘  └──────────────────┘
```

**Implementation**: `lib/vcs-interface.sh`

```bash
#!/bin/bash
# VCS Provider Interface - Dispatcher

# Source all provider implementations
source_providers() {
  local provider_dir="${AIDA_LIB}/vcs-providers"

  for provider_file in "$provider_dir"/*.sh; do
    if [ -f "$provider_file" ] && [ "$(basename "$provider_file")" != "base-provider.sh" ]; then
      source "$provider_file"
      log_debug "Loaded VCS provider: $(basename "$provider_file" .sh)"
    fi
  done

  # Load custom providers if exist
  local custom_dir="${CLAUDE_CONFIG}/lib/vcs-providers/custom"
  if [ -d "$custom_dir" ]; then
    for custom_file in "$custom_dir"/*.sh; do
      [ -f "$custom_file" ] && source "$custom_file"
    done
  fi
}

# Initialize VCS interface
init_vcs_interface() {
  # Load configuration
  load_config

  # Get VCS provider from config or auto-detect
  VCS_PROVIDER="${CONFIG_vcs_provider:-}"

  if [ -z "$VCS_PROVIDER" ] || [ "$CONFIG_vcs_auto_detect" = "true" ]; then
    VCS_PROVIDER=$(auto_detect_vcs_provider)
    [ -z "$VCS_PROVIDER" ] && log_error "Could not detect VCS provider" && return 1
  fi

  # Validate provider interface
  validate_provider_interface "$VCS_PROVIDER" || return 1

  export VCS_PROVIDER
  log_debug "VCS provider initialized: $VCS_PROVIDER"
}

# Auto-detect VCS provider from git remote
auto_detect_vcs_provider() {
  local remote_url
  remote_url=$(git remote get-url origin 2>/dev/null) || {
    log_error "No git remote 'origin' found"
    return 1
  }

  # Try each provider's detect function
  for provider in github gitlab bitbucket; do
    if detect_result=$(provider_${provider}_detect "$remote_url"); then
      [ -n "$detect_result" ] && echo "$detect_result" && return 0
    fi
  done

  log_error "Could not detect VCS provider from remote: $remote_url"
  return 1
}

# Generic VCS operations (delegate to provider)
vcs_get_issue() {
  local issue_id="$1"
  provider_${VCS_PROVIDER}_get_issue "$issue_id"
}

vcs_assign_issue() {
  local issue_id="$1"
  local assignee="$2"
  provider_${VCS_PROVIDER}_assign_issue "$issue_id" "$assignee"
}

vcs_create_pr() {
  local title="$1"
  local body="$2"
  local labels="${3:-}"

  if vcs_supports_feature "labels" && [ -n "$labels" ]; then
    provider_${VCS_PROVIDER}_create_pr "$title" "$body" "$labels"
  else
    provider_${VCS_PROVIDER}_create_pr "$title" "$body" ""
  fi
}

vcs_supports_feature() {
  local feature="$1"
  provider_${VCS_PROVIDER}_supports_feature "$feature"
}

vcs_update_project_status() {
  local issue_id="$1"
  local status="$2"

  if vcs_supports_feature "projects"; then
    provider_${VCS_PROVIDER}_update_project_status "$issue_id" "$status"
  else
    log_debug "Project tracking not supported by $VCS_PROVIDER, skipping"
    return 0  # Non-blocking
  fi
}

# Initialize on source
source_providers
init_vcs_interface
```

**Command Integration**:

```bash
# In /start-work command
source "${AIDA_LIB}/vcs-interface.sh"

# Old (hardcoded GitHub):
# gh issue view "$issue_id" --json number,title,body

# New (provider-agnostic):
issue_json=$(vcs_get_issue "$issue_id") || {
  log_error "Failed to fetch issue #$issue_id"
  exit 1
}

# Parse JSON (same schema regardless of provider)
issue_title=$(echo "$issue_json" | jq -r '.title')
issue_state=$(echo "$issue_json" | jq -r '.state')
```

### Plugin/Extension Pattern for Custom Providers

**Custom provider registration**:

```json
{
  "vcs": {
    "custom_providers": {
      "company-gitlab": {
        "type": "gitlab",
        "remote_pattern": "gitlab\\.company\\.com",
        "api_url": "https://gitlab.company.com/api/v4",
        "cli_command": "glab"
      }
    }
  }
}
```

**Custom provider implementation**: `~/.claude/lib/vcs-providers/custom/company-gitlab.sh`

```bash
#!/bin/bash
# Custom GitLab Provider for company instance

PROVIDER_NAME="company-gitlab"

# Detection
provider_company_gitlab_detect() {
  local remote_url="$1"
  [[ "$remote_url" =~ gitlab\.company\.com ]] && echo "$PROVIDER_NAME"
}

# Inherit from base GitLab provider
provider_company_gitlab_get_issue() {
  # Override API URL from config
  GITLAB_API_URL="${CONFIG_vcs_custom_providers_company_gitlab_api_url}"
  provider_gitlab_get_issue "$@"
}

# ... other operations inherit from gitlab.sh or override as needed
```

**Discovery and loading**: Automatic via `source_providers()` in `vcs-interface.sh`

## 2. Technical Concerns

### Provider Feature Parity

**Feature Matrix**:

| Feature | GitHub | GitLab | Bitbucket | Abstraction Strategy |
|---------|--------|--------|-----------|---------------------|
| Issues | Projects V2 | Issues | Jira integration | **Required** - all must support |
| PRs/MRs | Pull Requests | Merge Requests | Pull Requests | **Required** - terminology abstraction |
| Labels | ✓ | ✓ | ✗ | **Optional** - feature flag |
| Drafts | ✓ | ✓ | ✗ | **Optional** - fallback to regular PR |
| Projects | Projects V2 (GraphQL) | Boards (REST) | ✗ | **Optional** - provider-specific config |
| Auto-merge | ✓ | ✓ | ✓ | **Optional** - feature detection |

**Handling GitHub Projects vs GitLab Boards**:

```json
{
  "vcs": {
    "github": {
      "project": {
        "enabled": true,
        "name": "AIDA Development",
        "status_field": "Status",
        "graphql_project_id": "PVT_kwDOABcDEFGH"
      }
    },
    "gitlab": {
      "board": {
        "enabled": true,
        "board_id": 12345,
        "list_mapping": {
          "Prioritized": "To Do",
          "In Progress": "Doing",
          "In Review": "Review"
        }
      }
    }
  }
}
```

**Implementation approach**:

- **Separate config sections**: `vcs.github.project` vs `vcs.gitlab.board`
- **Feature detection**: Commands check `supports_feature("projects")` before calling
- **Graceful degradation**: Log warning if unsupported, continue workflow

### Graceful Degradation When Feature Unsupported

**Pattern**: Check before use, log and continue

```bash
# In /open-pr command
if vcs_supports_feature "labels"; then
  vcs_apply_labels "$pr_number" "$labels"
else
  log_warning "VCS provider '$VCS_PROVIDER' does not support labels"
  log_warning "Skipping label application for PR #$pr_number"
  # Continue without labels - not a blocking error
fi

# In /start-work command
if vcs_supports_feature "projects"; then
  vcs_update_project_status "$issue_id" "In Progress" || {
    log_warning "Could not update project status (non-blocking)"
  }
else
  log_info "Project tracking not available for $VCS_PROVIDER"
fi
```

**Error levels**:

- **CRITICAL** (exit): Issue fetch failed, PR creation failed
- **WARNING** (continue): Labels not supported, project update failed
- **INFO** (continue): Feature not available for provider

### Provider Auto-Detection Reliability

**Detection algorithm**:

```bash
auto_detect_vcs_provider() {
  local remote_url
  remote_url=$(git remote get-url origin 2>/dev/null) || return 1

  # Pattern matching for common providers
  case "$remote_url" in
    *github.com*)
      echo "github"
      return 0
      ;;
    *gitlab.com*|*gitlab.*.com*)
      echo "gitlab"
      return 0
      ;;
    *bitbucket.org*)
      echo "bitbucket"
      return 0
      ;;
    *)
      # Try custom provider patterns from config
      local custom_providers
      custom_providers=$(jq -r '.vcs.custom_providers | keys[]' "$CONFIG_FILE" 2>/dev/null)

      for provider_name in $custom_providers; do
        local pattern
        pattern=$(jq -r ".vcs.custom_providers[\"$provider_name\"].remote_pattern" "$CONFIG_FILE")

        if [[ "$remote_url" =~ $pattern ]]; then
          echo "$provider_name"
          return 0
        fi
      done

      log_error "Could not detect VCS provider from remote: $remote_url"
      log_error "Supported: github.com, gitlab.com, bitbucket.org"
      log_error "For custom providers, add to config.json vcs.custom_providers"
      return 1
      ;;
  esac
}
```

**Reliability considerations**:

- **SSH vs HTTPS remotes**: Both patterns supported
  - SSH: `git@github.com:owner/repo.git`
  - HTTPS: `https://github.com/owner/repo.git`
- **Enterprise instances**: Regex patterns for self-hosted
- **Multiple remotes**: Use primary `origin` only
- **Confidence metadata**: Track detection method for troubleshooting

**Validation**:

```bash
validate_detected_provider() {
  local detected="$1"
  local configured="${CONFIG_vcs_provider:-}"

  if [ -n "$configured" ] && [ "$configured" != "$detected" ]; then
    log_warning "Detected provider ($detected) differs from config ($configured)"
    log_warning "Using configured provider: $configured"
    echo "$configured"
  else
    echo "$detected"
  fi
}
```

### Version Compatibility (GitHub API v3 vs v4)

**GitHub CLI abstraction** (hides API version complexity):

```bash
# GitHub provider uses 'gh' CLI which handles API versions
provider_github_get_issue() {
  local issue_id="$1"

  # gh CLI uses REST API v3 by default
  gh issue view "$issue_id" --json number,title,body,labels,state,assignees,milestone 2>/dev/null || {
    log_error "Failed to fetch GitHub issue #$issue_id"
    return 1
  }
}

provider_github_update_project_status() {
  local issue_id="$1"
  local status="$2"

  # GitHub Projects V2 requires GraphQL (API v4)
  # Use gh CLI which handles GraphQL queries
  local project_id="${CONFIG_vcs_github_project_graphql_project_id}"
  local status_field="${CONFIG_vcs_github_project_status_field}"

  gh project item-edit --project-id "$project_id" \
    --id "$issue_id" \
    --field-name "$status_field" \
    --field-value "$status" 2>/dev/null || {
    log_warning "Could not update GitHub Project status"
    return 1
  }
}
```

**Key strategy**: Use official CLIs (`gh`, `glab`) which handle API versioning internally. Avoid direct API calls.

**Fallback for API changes**:

```bash
# Version detection and fallback
github_api_version() {
  gh api /meta --jq '.installed_version' 2>/dev/null || echo "unknown"
}

# If future breaking changes occur
if [ "$(github_api_version)" = "unknown" ]; then
  log_warning "Could not detect GitHub API version"
  log_warning "Using default CLI behavior"
fi
```

## 3. Dependencies & Integration

### REST API Clients Needed

**Primary strategy**: Use official provider CLIs

| Provider | CLI Tool | Installation | Authentication |
|----------|----------|--------------|----------------|
| GitHub | `gh` | `brew install gh` / apt | `gh auth login` |
| GitLab | `glab` | `brew install glab` / apt | `glab auth login` |
| Bitbucket | `bb` (unofficial) or API | `pip install bitbucket-cli` | API token via env var |
| Jira | `jira` (go-jira) | `brew install go-jira` | API token via env var |
| Linear | `linear-cli` | `npm install -g @linear/cli` | API key via env var |

**Fallback strategy**: Direct API calls with `curl`

```bash
# If CLI not available, fallback to curl
provider_github_get_issue_api_fallback() {
  local issue_id="$1"
  local api_url="${GITHUB_API_URL:-https://api.github.com}"
  local token="${GITHUB_TOKEN:-}"

  curl -s -H "Authorization: token $token" \
    "$api_url/repos/${CONFIG_vcs_owner}/${CONFIG_vcs_repo}/issues/$issue_id" || {
    log_error "GitHub API call failed"
    return 1
  }
}
```

**Dependency validation**:

```bash
# On VCS interface init, check CLI availability
validate_vcs_dependencies() {
  local provider="$1"

  case "$provider" in
    github)
      if ! command -v gh >/dev/null 2>&1; then
        log_error "GitHub CLI (gh) not found"
        log_error "Install: brew install gh"
        log_error "Auth: gh auth login"
        return 1
      fi
      ;;
    gitlab)
      if ! command -v glab >/dev/null 2>&1; then
        log_error "GitLab CLI (glab) not found"
        log_error "Install: brew install glab"
        return 1
      fi
      ;;
  esac

  return 0
}
```

### Provider SDK Dependencies

**Minimal dependencies approach**:

- **Prefer CLIs over SDKs**: `gh`, `glab` are standalone binaries
- **JSON parsing**: Use `jq` (already required by AIDA)
- **No language-specific SDKs**: Avoid Python/Node.js dependencies for core functionality

**Optional SDK usage** (future enhancement):

```bash
# If Python SDK available, can use for complex operations
if command -v python3 >/dev/null && python3 -c "import github" 2>/dev/null; then
  USE_GITHUB_SDK=true
else
  USE_GITHUB_SDK=false
fi
```

### How Config Feeds into Provider Implementations

**Config loading pattern**:

```bash
# lib/config.sh (enhanced)
load_vcs_config() {
  local provider="${CONFIG_vcs_provider}"

  # Load common fields
  VCS_OWNER="${CONFIG_vcs_owner}"
  VCS_REPO="${CONFIG_vcs_repo}"
  VCS_MAIN_BRANCH="${CONFIG_vcs_main_branch:-main}"

  # Load provider-specific config
  case "$provider" in
    github)
      GITHUB_ENTERPRISE_URL="${CONFIG_vcs_github_enterprise_url:-https://api.github.com}"
      GITHUB_PROJECT_ENABLED="${CONFIG_vcs_github_project_enabled:-false}"
      GITHUB_PROJECT_NAME="${CONFIG_vcs_github_project_name:-}"
      ;;
    gitlab)
      GITLAB_API_URL="${CONFIG_vcs_gitlab_self_hosted_url:-https://gitlab.com}"
      GITLAB_GROUP="${CONFIG_vcs_gitlab_group:-}"
      GITLAB_PROJECT_ID="${CONFIG_vcs_gitlab_project_id:-}"
      ;;
  esac

  export VCS_OWNER VCS_REPO VCS_MAIN_BRANCH
}
```

**Provider access to config**:

```bash
# In github.sh provider
provider_github_create_pr() {
  local title="$1"
  local body="$2"
  local labels="$3"

  # Use config values
  local api_url="${GITHUB_ENTERPRISE_URL:-https://api.github.com}"

  gh pr create \
    --repo "${VCS_OWNER}/${VCS_REPO}" \
    --title "$title" \
    --body "$body" \
    --label "$labels" || return 1
}
```

### Command Refactoring Scope

**Commands requiring refactoring**:

| Command | Lines Using `gh` | Complexity | Estimated Effort |
|---------|------------------|------------|------------------|
| `/start-work` | ~15 locations | HIGH | 4 hours |
| `/open-pr` | ~20 locations | HIGH | 6 hours |
| `/cleanup-main` | ~8 locations | MEDIUM | 2 hours |
| `/github-init` | ~30 locations | HIGH | 4 hours |
| `/github-sync` | ~25 locations | HIGH | 4 hours |

**Total refactoring effort**: ~20 hours for GitHub abstraction

**Refactoring strategy**:

```bash
# OLD: Direct gh CLI usage in /start-work
gh issue view "$issue_id" --json number,title,body,labels,state,assignees,milestone
gh issue edit "$issue_id" --add-assignee @me

# NEW: VCS interface abstraction
source "${AIDA_LIB}/vcs-interface.sh"

issue_json=$(vcs_get_issue "$issue_id")
vcs_assign_issue "$issue_id" "@me"
```

**Migration phases**:

1. **Issue #55**: Create config schema and VCS interface (no command changes yet)
2. **Issue #56**: Implement GitHub provider (`lib/vcs-providers/github.sh`)
3. **Issue #57**: Refactor `/start-work` to use VCS interface
4. **Issue #58**: Refactor `/open-pr` and `/cleanup-main`
5. **Issue #59+**: Add GitLab, Jira, Linear providers

**Backward compatibility during migration**:

```bash
# In commands during transition period
if [ -f "${AIDA_LIB}/vcs-interface.sh" ]; then
  # New VCS abstraction available
  source "${AIDA_LIB}/vcs-interface.sh"
  issue_json=$(vcs_get_issue "$issue_id")
else
  # Fallback to old GitHub-specific code
  issue_json=$(gh issue view "$issue_id" --json number,title,body,labels,state,assignees,milestone)
fi
```

## 4. Effort & Complexity

### Interface Design Complexity

Complexity: HIGH

**Challenges**:

1. **Terminology mapping**: PR (GitHub/Bitbucket) vs MR (GitLab)
2. **Status transitions**: GitHub (project field update) vs GitLab (board list move) vs Jira (workflow transitions)
3. **Label systems**: GitHub/GitLab have labels, Bitbucket uses Jira labels
4. **Authentication**: Different token formats and scopes per provider
5. **JSON schema normalization**: Each provider returns different field structures

**Mitigation strategies**:

- **Start simple**: Define minimal interface (issue fetch, PR create)
- **Iterate**: Add optional features (labels, projects) incrementally
- **Provider-specific adapters**: Each provider handles its own JSON mapping
- **Extensive testing**: Unit tests for each provider implementation

**Estimated effort**: 16 hours

- Interface design: 4 hours
- Base provider template: 2 hours
- GitHub implementation: 4 hours
- GitLab implementation: 4 hours
- Documentation: 2 hours

### Per-Provider Implementation Effort

**GitHub Provider** (`lib/vcs-providers/github.sh`):

- **Effort**: 6 hours
- **Complexity**: MEDIUM (already using `gh` CLI, just need abstraction layer)
- **Scope**: Migrate existing `gh` calls into provider interface

**GitLab Provider** (`lib/vcs-providers/gitlab.sh`):

- **Effort**: 8 hours
- **Complexity**: HIGH (new integration, different API patterns)
- **Scope**: Implement from scratch using `glab` CLI

**Bitbucket Provider** (`lib/vcs-providers/bitbucket.sh`):

- **Effort**: 10 hours
- **Complexity**: HIGH (no official CLI, API-based, Jira integration)
- **Scope**: Implement using Bitbucket REST API + Jira for issue tracking

**Jira Work Tracker** (`lib/work-trackers/jira.sh`):

- **Effort**: 8 hours
- **Complexity**: HIGH (workflow transitions, custom fields, JQL queries)
- **Scope**: Issue operations separate from VCS provider

**Linear Work Tracker** (`lib/work-trackers/linear.sh`):

- **Effort**: 6 hours
- **Complexity**: MEDIUM (GraphQL API, good CLI available)
- **Scope**: Issue tracking independent of VCS

**Total per-provider effort**: ~38 hours

### Testing with Multiple Providers

**Testing strategy**:

1. **Unit tests**: Provider detection, JSON parsing, feature flags
2. **Integration tests**: Real API calls with test credentials
3. **Mock tests**: Simulated provider responses for fast feedback

**Test infrastructure**:

```bash
# tests/integration/vcs-providers/test-provider.sh

test_github_provider() {
  export VCS_PROVIDER="github"
  export CONFIG_vcs_owner="oakensoul"
  export CONFIG_vcs_repo="claude-personal-assistant"

  # Test detection
  assert_equals "github" "$(auto_detect_vcs_provider)"

  # Test issue fetch (requires GITHUB_TOKEN)
  if [ -n "$GITHUB_TOKEN" ]; then
    issue_json=$(vcs_get_issue "1")
    assert_contains "$issue_json" "\"number\": 1"
  else
    skip "GITHUB_TOKEN not set"
  fi
}

test_gitlab_provider() {
  export VCS_PROVIDER="gitlab"
  # Similar tests for GitLab
}

# Run tests for all providers
for provider in github gitlab bitbucket; do
  test_${provider}_provider || echo "FAILED: $provider"
done
```

**CI/CD integration**:

```yaml
# .github/workflows/test-vcs-providers.yml
name: Test VCS Providers

on: [push, pull_request]

jobs:
  test-github:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install gh CLI
        run: gh version
      - name: Run GitHub provider tests
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: ./tests/integration/vcs-providers/test-github.sh

  test-gitlab:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install glab CLI
        run: |
          brew install glab
      - name: Run GitLab provider tests
        env:
          GITLAB_TOKEN: ${{ secrets.GITLAB_TOKEN }}
        run: ./tests/integration/vcs-providers/test-gitlab.sh
```

**Estimated testing effort**: 12 hours

- Test infrastructure setup: 4 hours
- Per-provider test suites: 6 hours
- CI/CD integration: 2 hours

## 5. Questions & Clarifications

### Q1: Should Issue #55 define the provider interface?

**Answer**: YES

**Rationale**:

- Issue #55 creates **configuration infrastructure** and **interface specification**
- Actual provider implementations deferred to Issues #56-59
- Define `lib/vcs-providers/base-provider.sh` with interface contract
- Document required vs optional operations
- Create template for future implementations

**Deliverables for #55**:

- ✅ Config schema (`lib/installer-common/config-schema.json`)
- ✅ Provider interface spec (`lib/vcs-providers/base-provider.sh`)
- ✅ VCS interface dispatcher (`lib/vcs-interface.sh`)
- ✅ Auto-detection logic
- ✅ Config validation
- ✅ Documentation (`docs/integration/vcs-providers.md`)
- ❌ Provider implementations (deferred to #56-59)

### Q2: How much provider implementation happens in #55 vs #56-59?

**Recommended split**:

**Issue #55** (Configuration Foundation):

- Config schema design and validation
- Provider interface specification
- VCS interface dispatcher skeleton
- Auto-detection algorithm
- Documentation and examples
- Migration script for existing configs
- **NO actual provider implementations**

**Issue #56** (GitHub Provider + Command Refactoring):

- Implement `lib/vcs-providers/github.sh`
- Refactor `/start-work` to use VCS interface
- Refactor `/open-pr` to use VCS interface
- Refactor `/cleanup-main` to use VCS interface
- Integration tests for GitHub provider

**Issue #57** (GitLab Provider):

- Implement `lib/vcs-providers/gitlab.sh`
- Test all workflow commands with GitLab
- Document GitLab-specific configuration

**Issue #58** (Jira Work Tracker):

- Implement `lib/work-trackers/jira.sh`
- Add Jira authentication and config
- Test Jira + Bitbucket integration

**Issue #59** (Linear + Bitbucket):

- Implement `lib/vcs-providers/bitbucket.sh`
- Implement `lib/work-trackers/linear.sh`
- Complete multi-provider test coverage

**Why this split?**:

- Issue #55 stays **infrastructure-focused** (schema, interfaces, validation)
- Avoids scope creep and keeps issue manageable
- Enables parallel work on multiple providers after #55
- Clear success criteria per issue

### Q3: What's the minimal viable provider contract?

**Minimal contract** (required for all providers):

```bash
# Detection
provider_<name>_detect(remote_url) -> provider_name

# Issue operations
provider_<name>_get_issue(issue_id) -> JSON
provider_<name>_assign_issue(issue_id, username) -> exit_code

# PR operations
provider_<name>_create_pr(title, body, labels) -> pr_url
provider_<name>_get_pr(pr_number) -> JSON

# Feature detection
provider_<name>_supports_feature(feature_name) -> exit_code
```

**Optional but recommended**:

```bash
# Label operations
provider_<name>_list_labels() -> JSON_array
provider_<name>_apply_labels(pr_number, labels) -> exit_code

# Project/board operations
provider_<name>_update_project_status(issue_id, status) -> exit_code

# Draft PRs
provider_<name>_create_draft_pr(title, body) -> pr_url
```

**Standardized return formats**:

```json
{
  "issue": {
    "number": 42,
    "title": "Issue title",
    "body": "Issue description",
    "labels": ["bug", "priority:high"],
    "state": "open",
    "assignees": ["user1"],
    "milestone": "v1.0"
  },
  "pr": {
    "number": 123,
    "url": "https://provider.com/owner/repo/pull/123",
    "title": "PR title",
    "state": "open",
    "draft": false
  }
}
```

**Provider responsibilities**:

- Map provider-specific JSON to standardized schema
- Handle authentication (read from env vars)
- Return meaningful error codes (0 = success, 1+ = error)
- Log provider-specific errors for debugging

### Q4: Should we support custom/private VCS providers?

**Answer**: YES (via plugin system)

**Rationale**:

- Many teams use self-hosted GitLab, Bitbucket, or custom git platforms
- Plugin system enables extensibility without core code changes
- Documented interface allows community contributions

**Implementation**:

```text
~/.claude/lib/vcs-providers/custom/
├── company-gitlab.sh          # Custom GitLab instance
├── gitea.sh                   # Gitea self-hosted
└── codeberg.sh                # Codeberg provider
```

**Registration in config**:

```json
{
  "vcs": {
    "custom_providers": {
      "company-gitlab": {
        "type": "gitlab",
        "remote_pattern": "gitlab\\.company\\.com",
        "api_url": "https://gitlab.company.com/api/v4",
        "cli_command": "glab"
      },
      "gitea": {
        "type": "custom",
        "remote_pattern": "gitea\\.company\\.com",
        "api_url": "https://gitea.company.com/api/v1",
        "cli_command": "tea"
      }
    }
  }
}
```

**Plugin template**: Provide `lib/vcs-providers/custom/template.sh` with documented interface

**Documentation**: `docs/integration/custom-vcs-providers.md`

**Validation**: Custom providers MUST implement required interface (validated on load)

## 6. Implementation Recommendations

### Phase 1: Issue #55 - Foundation Only

**Scope**: Infrastructure, no provider implementations

**Deliverables**:

1. JSON config schema with provider namespaces
2. Provider interface specification (`base-provider.sh`)
3. VCS interface dispatcher (`vcs-interface.sh`)
4. Auto-detection algorithm (skeleton, no provider-specific logic yet)
5. Config validation (structure only, not provider-specific validation)
6. Migration script (convert `github.*` → `vcs.github.*`)
7. Template config files
8. Documentation (`docs/integration/vcs-providers.md`)

**NOT in scope for #55**:

- ❌ Provider implementations (GitHub, GitLab, etc.)
- ❌ Command refactoring (`/start-work`, `/open-pr`)
- ❌ Work tracker implementations (Jira, Linear)
- ❌ Runtime API validation

**Success criteria**:

- ✅ Config schema validates correctly
- ✅ Auto-detection returns provider name from git remote
- ✅ Interface specification documented and testable
- ✅ Migration script converts old configs without data loss
- ✅ Template configs created for all providers

### Phase 2: Issue #56 - GitHub Provider + Command Migration

**Scope**: Implement GitHub provider and migrate workflow commands

**Deliverables**:

1. `lib/vcs-providers/github.sh` (full implementation)
2. Refactor `/start-work` to use `vcs_get_issue()`, `vcs_assign_issue()`
3. Refactor `/open-pr` to use `vcs_create_pr()`
4. Refactor `/cleanup-main` to use VCS interface
5. Integration tests for GitHub provider
6. Update documentation with usage examples

**Success criteria**:

- ✅ All workflow commands work with VCS abstraction
- ✅ GitHub Projects integration preserved
- ✅ No regressions in existing functionality
- ✅ Tests pass for GitHub provider

### Phase 3: Issues #57-59 - Additional Providers

**GitLab** (#57):

- Implement `gitlab.sh` provider
- Test workflow commands with GitLab
- Document GitLab board integration

**Jira** (#58):

- Implement `jira.sh` work tracker
- Add Jira authentication
- Test Bitbucket + Jira combination

**Linear + Bitbucket** (#59):

- Implement `bitbucket.sh` provider
- Implement `linear.sh` work tracker
- Complete test coverage

### Migration Strategy

**Auto-migration on first use**:

```bash
# In aida-config-helper.sh
migrate_config_v1_to_v2() {
  local old_config="$HOME/.claude/workflow-config.json"
  local new_config="$HOME/.claude/config.json"

  if [ -f "$old_config" ] && ! [ -f "$new_config" ]; then
    log_info "Migrating config from v1 to v2..."

    # Backup
    cp "$old_config" "${old_config}.backup"

    # Convert github.* → vcs.github.*
    jq '{
      config_version: "1.0",
      vcs: {
        provider: "github",
        owner: .github.owner,
        repo: .github.repo,
        main_branch: .github.main_branch,
        github: .github
      },
      work_tracker: {
        provider: "github_issues",
        github_issues: { enabled: true }
      },
      team: .team,
      workflow: .workflow
    }' "$old_config" > "$new_config"

    log_info "✓ Config migrated to $new_config"
    log_info "  Backup: ${old_config}.backup"
  fi
}
```

**Deprecation warnings** (2-version cycle):

```bash
# In commands
if config_has_legacy_format; then
  log_warning "DEPRECATED: Old config format detected"
  log_warning "Support will be removed in v0.3.0"
  log_warning "Run '/workflow-init' to upgrade"
fi
```

## 7. Risk Mitigation

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Breaking changes for existing users | HIGH | HIGH | Auto-migration + 2-version deprecation |
| Provider API changes break abstraction | MEDIUM | MEDIUM | Use official CLIs (handle API versions internally) |
| Complex provider-specific features can't be abstracted | MEDIUM | HIGH | Provider-specific config sections + feature flags |
| Performance degradation from abstraction layer | LOW | LOW | Minimal overhead (just function dispatch) |
| Security: Secrets in config files | CRITICAL | MEDIUM | Pre-commit hook + validation + documentation |

## 8. Next Steps for Issue #55

**Immediate actions**:

1. Create `lib/installer-common/config-schema.json` with full JSON Schema definition
2. Create `lib/vcs-providers/base-provider.sh` with interface specification
3. Create `lib/vcs-interface.sh` with dispatcher skeleton
4. Implement auto-detection function (detect provider from git remote)
5. Add config validation to `aida-config-helper.sh`
6. Create migration script for `github.*` → `vcs.*` namespace
7. Create template configs for all providers
8. Write documentation: `docs/integration/vcs-providers.md`, `docs/integration/custom-vcs-providers.md`
9. Add pre-commit hook for secret detection in config files
10. Update installer to set file permissions (600 for user config, 644 for project config)

**Files to create**:

```text
lib/
├── installer-common/
│   └── config-schema.json           # JSON Schema for validation
├── vcs-providers/
│   ├── base-provider.sh             # Interface specification
│   └── custom/
│       └── template.sh              # Plugin template
└── vcs-interface.sh                 # Dispatcher

templates/
└── config/
    ├── config.json.template         # User config template
    └── project-config.json.template # Project config template

docs/
└── integration/
    ├── vcs-providers.md             # Provider abstraction guide
    ├── custom-vcs-providers.md      # Plugin development guide
    └── config-schema-reference.md   # Full schema documentation
```

**Testing**:

- Unit tests for config validation
- Unit tests for auto-detection
- Integration tests deferred to #56 (provider implementations)

---

## Summary

**Key Findings**:

1. **Provider abstraction is essential** - Don't just rename config keys, design proper abstraction layer
2. **Three-layer architecture** - Commands → VCS Interface → Provider Implementations
3. **Feature detection critical** - GitHub Projects ≠ GitLab Boards, graceful degradation needed
4. **Issue #55 scope: Foundation only** - Config schema, interface spec, validation (NO implementations)
5. **Provider implementations deferred** - Issues #56-59 handle GitHub, GitLab, Jira, Linear, Bitbucket
6. **Plugin system for extensibility** - Custom providers via documented interface
7. **Auto-migration required** - Existing users have `github.*` configs that need upgrading
8. **Use official CLIs** - `gh`, `glab` handle API versioning, avoid direct API calls

**Complexity Assessment**:

- **Configuration schema**: MEDIUM (well-defined structure)
- **Provider interface design**: HIGH (abstraction complexity, feature parity challenges)
- **Auto-detection**: MEDIUM (regex patterns, edge case handling)
- **Migration**: MEDIUM (automated but needs validation)
- **Overall**: HIGH complexity project, but manageable with phased approach

**Estimated Effort**:

- **Issue #55** (Foundation): 16 hours
- **Issue #56** (GitHub + Commands): 20 hours
- **Issue #57-59** (Additional providers): 38 hours
- **Total**: ~74 hours for complete multi-provider support

**Risk Level**: MEDIUM (mitigated through auto-migration and deprecation period)

**Recommendation**: Proceed with Issue #55 as infrastructure-only. Define solid foundation before implementing providers.

---

**Analysis complete**. Ready to proceed with implementation.
