---
title: "VCS Provider Integration Guide"
description: "How to add support for new VCS providers to AIDA's configuration system"
category: "integration"
tags: ["vcs", "providers", "extensibility", "integration", "configuration"]
audience: "contributors"
last_updated: "2025-10-20"
status: "published"
---

# VCS Provider Integration Guide

## Overview

AIDA's configuration system is designed to support multiple VCS (Version Control System) providers through a provider abstraction pattern. This guide shows how to add support for new providers.

**Currently Supported Providers**:

- **GitHub** (github.com, GitHub Enterprise)
- **GitLab** (gitlab.com, self-hosted)
- **Bitbucket** (bitbucket.org, Bitbucket Server)

**Adding New Providers**: This guide demonstrates how to add **Gitea**, **Azure DevOps**, or any other VCS provider.

## Provider Abstraction Pattern

### Design Principles

AIDA's VCS provider system follows these core principles:

**1. Namespace Isolation**: Each provider has its own subsection in the config schema

- GitHub: `vcs.github.enterprise_url`
- GitLab: `vcs.gitlab.self_hosted_url`, `vcs.gitlab.project_id`
- Bitbucket: `vcs.bitbucket.workspace`, `vcs.bitbucket.repo_slug`
- Gitea (example): `vcs.gitea.base_url`

**2. Conditional Validation**: Requirements vary by provider

- All providers require `owner` and `repo` (or equivalent fields)
- GitLab requires `project_id` in addition
- Bitbucket uses `workspace` and `repo_slug` instead of `owner`/`repo`
- Requirements enforced via JSON Schema `allOf` conditions

**3. Auto-detection**: Infer provider from git remote URL

- Parse SSH and HTTPS URL formats
- Extract metadata (domain, owner, repo)
- Calculate confidence score (high/medium/low)

**4. Extensibility**: Adding providers doesn't break existing configs

- New providers are additive changes only
- Old configs continue to validate
- Provider-specific fields isolated in subsections

### Benefits

**No Breaking Changes**: New providers = additive changes only

- Existing configs remain valid
- No migration required for users
- Backward compatibility guaranteed

**Clear Boundaries**: Provider-specific fields isolated

- GitHub enterprise settings don't mix with GitLab self-hosted
- Easy to understand provider-specific requirements
- Clean separation of concerns

**Reusable Patterns**: Same structure for all providers

- Consistent detection function signatures
- Standardized JSON output format
- Common confidence scoring logic

**Easy Testing**: Each provider tested independently

- Unit tests per provider
- Mock URLs for testing
- Isolated test failures

## Provider Interface Specification

Every new provider must implement two core functions and produce standardized JSON output.

### Required Functions

**1. Detection Function**: `extract_<provider>_info()`

Parses provider-specific URLs and extracts metadata.

**Function Signature**:

```bash
extract_<provider>_info() {
  local url="$1"

  # Parse URL with provider-specific regex
  # Extract owner/repo (or workspace/project_id)
  # Return JSON with metadata
}
```

**Example** (GitHub):

```bash
extract_github_info() {
  local url="$1"
  local domain owner repo confidence detection_method

  url=$(normalize_url "$url")

  # SSH: git@github.com:owner/repo.git
  if [[ "$url" =~ ^git@([^:]+):([^/]+)/([^/]+)(\.git)?$ ]]; then
    domain="${BASH_REMATCH[1]}"
    owner="${BASH_REMATCH[2]}"
    repo="${BASH_REMATCH[3]}"
    detection_method="ssh_regex_match"

    if [[ "$domain" =~ ^github\.com$ ]]; then
      confidence="high"
    elif [[ "$domain" =~ github ]]; then
      confidence="medium"  # Enterprise
    else
      confidence="low"
    fi

  # HTTPS: https://github.com/owner/repo.git
  elif [[ "$url" =~ ^https://([^/]+)/([^/]+)/([^/]+)(\.git)?$ ]]; then
    domain="${BASH_REMATCH[1]}"
    owner="${BASH_REMATCH[2]}"
    repo="${BASH_REMATCH[3]}"
    detection_method="https_regex_match"

    if [[ "$domain" =~ ^github\.com$ ]]; then
      confidence="high"
    elif [[ "$domain" =~ github ]]; then
      confidence="medium"
    else
      confidence="low"
    fi
  else
    return 1
  fi

  # Return JSON
  cat <<EOF
{
  "provider": "github",
  "domain": "$domain",
  "owner": "$owner",
  "repo": "$repo",
  "confidence": "$confidence",
  "detection_method": "$detection_method"
}
EOF
  return 0
}
```

**2. Integration with Main Detector**: Update `detect_vcs_provider()`

Add your provider to the detection chain:

```bash
detect_vcs_provider() {
  local url="$1"

  # Try each provider in order (specific to general)
  extract_github_info "$url" && return 0
  extract_gitlab_info "$url" && return 0
  extract_bitbucket_info "$url" && return 0
  extract_gitea_info "$url" && return 0  # NEW PROVIDER

  # Unknown provider
  echo '{"provider": "unknown", ...}'
  return 1
}
```

### JSON Output Format

All providers must return JSON in this structure:

```json
{
  "provider": "gitea",
  "domain": "gitea.example.com",
  "owner": "username",
  "repo": "repository",
  "confidence": "high",
  "detection_method": "ssh_regex_match",
  "remote_url": "git@gitea.example.com:username/repository.git",
  "detected_at": "2025-10-20T21:00:00Z"
}
```

**Required Fields**:

- `provider` (string): Provider name (lowercase, no spaces)
- `domain` (string): Git server domain
- `owner` (string): Repository owner/organization/user
- `repo` (string): Repository name
- `confidence` (string): Detection confidence ("high", "medium", "low")
- `detection_method` (string): How URL was parsed

**Optional Fields**:

- `remote_url` (string): Original git remote URL
- `detected_at` (string): ISO 8601 timestamp
- Provider-specific fields (e.g., `workspace`, `project_id`)

**Provider-Specific Field Names**:

Some providers use different terminology:

- **Bitbucket**: `workspace` and `repo_slug` instead of `owner` and `repo`
- **GitLab**: May include `project_id` (numeric ID or full path)
- **Azure DevOps**: Might use `organization` and `project`

### Confidence Levels

Detection confidence scoring:

**High**: Exact domain match on known public instance

- Examples: `github.com`, `gitlab.com`, `bitbucket.org`
- Result: User can trust auto-detected values

**Medium**: Domain contains provider keyword but not exact match

- Examples: `github.company.com`, `gitlab.internal.net`
- Likely enterprise/self-hosted instance
- Result: Review recommended, likely correct

**Low**: Pattern matches but domain unknown

- URL structure matches but domain unrelated
- Could be false positive
- Result: Manual verification required

**Confidence Scoring Logic**:

```bash
if [[ "$domain" == "provider.com" ]]; then
  confidence="high"  # Known public instance
elif [[ "$domain" =~ provider ]]; then
  confidence="medium"  # Self-hosted, keyword match
else
  confidence="low"  # Unknown, pattern match only
fi
```

## Adding a New Provider: Step-by-Step

This section walks through adding **Gitea** support as a complete example.

### Step 1: Update JSON Schema

**File**: `lib/installer-common/config-schema.json`

**1a. Add provider to enum**:

```json
{
  "vcs": {
    "properties": {
      "provider": {
        "type": "string",
        "enum": ["github", "gitlab", "bitbucket", "gitea"],
        "description": "VCS provider type. Determines which provider-specific configuration is used."
      }
    }
  }
}
```

**1b. Add provider-specific subsection**:

```json
{
  "vcs": {
    "properties": {
      "gitea": {
        "type": "object",
        "description": "Gitea-specific configuration (only used when provider is 'gitea')",
        "additionalProperties": false,
        "properties": {
          "base_url": {
            "type": ["string", "null"],
            "pattern": "^https://[a-zA-Z0-9][a-zA-Z0-9.-]*[a-zA-Z0-9](:[0-9]+)?(/.*)?$",
            "default": null,
            "description": "Gitea instance URL (null for gitea.com). Must be HTTPS.",
            "examples": ["https://gitea.example.com", "https://gitea.io", null]
          }
        }
      }
    }
  }
}
```

**1c. Add conditional validation**:

```json
{
  "allOf": [
    {
      "if": {
        "properties": {
          "provider": {"const": "gitea"}
        }
      },
      "then": {
        "required": ["owner", "repo"],
        "properties": {
          "owner": {"type": "string"},
          "repo": {"type": "string"}
        }
      }
    }
  ]
}
```

### Step 2: Add Detection Function

**File**: `lib/installer-common/vcs-detector.sh`

**2a. Define URL patterns** (at top of file with other patterns):

```bash
# Gitea patterns (gitea.com and self-hosted)
readonly GITEA_SSH_PATTERN='^git@([^:]+):([^/]+)/([^/]+)(\.git)?$'
readonly GITEA_HTTPS_PATTERN='^https://([^/]+)/([^/]+)/([^/]+)(\.git)?$'

# Known Gitea domains for high-confidence detection
readonly GITEA_DOMAINS='^(gitea\.com|gitea\.io)$'
```

**2b. Implement detection function**:

```bash
# extract_gitea_info() - Extract owner and repo from Gitea URL
#
# Args:
#   $1 - Gitea remote URL (SSH or HTTPS)
#
# Returns:
#   JSON with owner, repo, domain, confidence
#
# Supported formats:
#   SSH: git@gitea.com:owner/repo.git
#   HTTPS: https://gitea.com/owner/repo.git
#   Self-hosted: git@gitea.example.com:owner/repo.git
extract_gitea_info() {
    local url="$1"
    local domain owner repo confidence detection_method

    url=$(normalize_url "$url")

    # Try SSH format: git@gitea.com:owner/repo
    if [[ "$url" =~ $GITEA_SSH_PATTERN ]]; then
        domain="${BASH_REMATCH[1]}"
        owner="${BASH_REMATCH[2]}"
        repo="${BASH_REMATCH[3]}"
        detection_method="ssh_regex_match"

        # Check if domain matches known Gitea domain
        if [[ "$domain" =~ $GITEA_DOMAINS ]]; then
            confidence="high"
        elif [[ "$domain" =~ gitea ]]; then
            confidence="medium"  # Self-hosted Gitea
        else
            confidence="low"
        fi

    # Try HTTPS format: https://gitea.com/owner/repo
    elif [[ "$url" =~ $GITEA_HTTPS_PATTERN ]]; then
        domain="${BASH_REMATCH[1]}"
        owner="${BASH_REMATCH[2]}"
        repo="${BASH_REMATCH[3]}"
        detection_method="https_regex_match"

        # Check if domain matches known Gitea domain
        if [[ "$domain" =~ $GITEA_DOMAINS ]]; then
            confidence="high"
        elif [[ "$domain" =~ gitea ]]; then
            confidence="medium"  # Self-hosted Gitea
        else
            confidence="low"
        fi
    else
        log_debug "URL does not match Gitea patterns: $url"
        return 1
    fi

    # Return JSON
    cat <<EOF
{
  "provider": "gitea",
  "domain": "$domain",
  "owner": "$owner",
  "repo": "$repo",
  "confidence": "$confidence",
  "detection_method": "$detection_method"
}
EOF
    return 0
}
```

**2c. Update main detection function**:

```bash
detect_vcs_provider() {
    local remote_name="${1:-origin}"
    local remote_url provider owner repo workspace repo_slug domain
    local main_branch branch_detected confidence detection_method
    local detected_at

    # Get remote URL
    if ! remote_url=$(get_git_remote_url "$remote_name"); then
        log_error "Failed to get git remote URL for '$remote_name'"
        cat <<EOF
{
  "provider": "unknown",
  "error": "not_a_git_repo_or_no_remote",
  "remote_name": "$remote_name",
  "confidence": "low"
}
EOF
        return 1
    fi

    log_debug "Detecting VCS provider for URL: $remote_url"

    # Try GitHub detection
    if github_info=$(extract_github_info "$remote_url" 2>/dev/null); then
        provider="github"
        domain=$(echo "$github_info" | grep -o '"domain": *"[^"]*"' | cut -d'"' -f4)
        owner=$(echo "$github_info" | grep -o '"owner": *"[^"]*"' | cut -d'"' -f4)
        repo=$(echo "$github_info" | grep -o '"repo": *"[^"]*"' | cut -d'"' -f4)
        confidence=$(echo "$github_info" | grep -o '"confidence": *"[^"]*"' | cut -d'"' -f4)
        detection_method=$(echo "$github_info" | grep -o '"detection_method": *"[^"]*"' | cut -d'"' -f4)

    # Try GitLab detection
    elif gitlab_info=$(extract_gitlab_info "$remote_url" 2>/dev/null); then
        provider="gitlab"
        domain=$(echo "$gitlab_info" | grep -o '"domain": *"[^"]*"' | cut -d'"' -f4)
        owner=$(echo "$gitlab_info" | grep -o '"owner": *"[^"]*"' | cut -d'"' -f4)
        repo=$(echo "$gitlab_info" | grep -o '"repo": *"[^"]*"' | cut -d'"' -f4)
        confidence=$(echo "$gitlab_info" | grep -o '"confidence": *"[^"]*"' | cut -d'"' -f4)
        detection_method=$(echo "$gitlab_info" | grep -o '"detection_method": *"[^"]*"' | cut -d'"' -f4)

    # Try Bitbucket detection
    elif bitbucket_info=$(extract_bitbucket_info "$remote_url" 2>/dev/null); then
        provider="bitbucket"
        domain=$(echo "$bitbucket_info" | grep -o '"domain": *"[^"]*"' | cut -d'"' -f4)
        workspace=$(echo "$bitbucket_info" | grep -o '"workspace": *"[^"]*"' | cut -d'"' -f4)
        repo_slug=$(echo "$bitbucket_info" | grep -o '"repo_slug": *"[^"]*"' | cut -d'"' -f4)
        confidence=$(echo "$bitbucket_info" | grep -o '"confidence": *"[^"]*"' | cut -d'"' -f4)
        detection_method=$(echo "$bitbucket_info" | grep -o '"detection_method": *"[^"]*"' | cut -d'"' -f4)

    # NEW: Try Gitea detection
    elif gitea_info=$(extract_gitea_info "$remote_url" 2>/dev/null); then
        provider="gitea"
        domain=$(echo "$gitea_info" | grep -o '"domain": *"[^"]*"' | cut -d'"' -f4)
        owner=$(echo "$gitea_info" | grep -o '"owner": *"[^"]*"' | cut -d'"' -f4)
        repo=$(echo "$gitea_info" | grep -o '"repo": *"[^"]*"' | cut -d'"' -f4)
        confidence=$(echo "$gitea_info" | grep -o '"confidence": *"[^"]*"' | cut -d'"' -f4)
        detection_method=$(echo "$gitea_info" | grep -o '"detection_method": *"[^"]*"' | cut -d'"' -f4)

    # Unknown provider
    else
        provider="unknown"
        confidence="low"
        detection_method="no_match"
        log_warn "Could not detect VCS provider for URL: $remote_url"
    fi

    # ... rest of function (branch detection, JSON output) ...
}
```

### Step 3: Add Validation Rules

**File**: `lib/installer-common/config-validator.sh` (Task 3.2 - will be created)

**3a. Implement provider-specific validation**:

```bash
# validate_gitea_config() - Validate Gitea-specific configuration
#
# Args:
#   $1 - Config JSON
#
# Returns:
#   0 - Valid
#   1 - Invalid (with error messages to stderr)
validate_gitea_config() {
    local config="$1"
    local errors=0

    # Check required fields
    local owner repo
    owner=$(echo "$config" | jq -r '.vcs.owner // empty')
    repo=$(echo "$config" | jq -r '.vcs.repo // empty')

    if [[ -z "$owner" ]]; then
        log_error "Gitea requires vcs.owner"
        errors=$((errors + 1))
    fi

    if [[ -z "$repo" ]]; then
        log_error "Gitea requires vcs.repo"
        errors=$((errors + 1))
    fi

    # Validate base_url format if provided
    local base_url
    base_url=$(echo "$config" | jq -r '.vcs.gitea.base_url // empty')
    if [[ -n "$base_url" ]]; then
        # Must be HTTPS
        if [[ ! "$base_url" =~ ^https:// ]]; then
            log_error "Gitea base_url must start with https://"
            errors=$((errors + 1))
        fi

        # Must be valid URL format
        if [[ ! "$base_url" =~ ^https://[a-zA-Z0-9][a-zA-Z0-9.-]*[a-zA-Z0-9](:[0-9]+)?(/.*)?$ ]]; then
            log_error "Gitea base_url is not a valid URL: $base_url"
            errors=$((errors + 1))
        fi
    fi

    return $errors
}
```

**3b. Add to main validation dispatcher**:

```bash
validate_vcs_config() {
    local config="$1"
    local provider

    provider=$(echo "$config" | jq -r '.vcs.provider')

    case "$provider" in
        github)
            validate_github_config "$config"
            ;;
        gitlab)
            validate_gitlab_config "$config"
            ;;
        bitbucket)
            validate_bitbucket_config "$config"
            ;;
        gitea)
            validate_gitea_config "$config"  # NEW
            ;;
        *)
            log_error "Unknown VCS provider: $provider"
            return 1
            ;;
    esac
}
```

### Step 4: Create Template Config

**File**: `templates/config/config-gitea.json`

**Purpose**: Provide example configuration for Gitea users

```json
{
  "config_version": "1.0",
  "vcs": {
    "provider": "gitea",
    "owner": "username",
    "repo": "repository",
    "main_branch": "main",
    "auto_detect": true,
    "gitea": {
      "base_url": "https://gitea.example.com"
    }
  },
  "work_tracker": {
    "provider": "github_issues",
    "auto_detect": true,
    "github_issues": {
      "enabled": true
    }
  },
  "team": {
    "review_strategy": "list",
    "default_reviewers": [],
    "members": []
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

**Note**: This template shows a mixed configuration (Gitea VCS + GitHub Issues work tracker), demonstrating that VCS and work tracker are independent.

### Step 5: Add Unit Tests

**File**: `tests/unit/test_vcs_detection.bats`

**5a. Basic URL detection tests**:

```bash
@test "Gitea: detects SSH URL from gitea.com" {
  source lib/installer-common/vcs-detector.sh

  result=$(extract_gitea_info "git@gitea.com:user/repo.git")

  [ "$(echo "$result" | jq -r '.provider')" = "gitea" ]
  [ "$(echo "$result" | jq -r '.owner')" = "user" ]
  [ "$(echo "$result" | jq -r '.repo')" = "repo" ]
  [ "$(echo "$result" | jq -r '.domain')" = "gitea.com" ]
  [ "$(echo "$result" | jq -r '.confidence')" = "high" ]
  [ "$(echo "$result" | jq -r '.detection_method')" = "ssh_regex_match" ]
}

@test "Gitea: detects SSH URL without .git suffix" {
  source lib/installer-common/vcs-detector.sh

  result=$(extract_gitea_info "git@gitea.com:user/repo")

  [ "$(echo "$result" | jq -r '.provider')" = "gitea" ]
  [ "$(echo "$result" | jq -r '.owner')" = "user" ]
  [ "$(echo "$result" | jq -r '.repo')" = "repo" ]
}

@test "Gitea: detects HTTPS URL from gitea.com" {
  source lib/installer-common/vcs-detector.sh

  result=$(extract_gitea_info "https://gitea.com/user/repo.git")

  [ "$(echo "$result" | jq -r '.provider')" = "gitea" ]
  [ "$(echo "$result" | jq -r '.owner')" = "user" ]
  [ "$(echo "$result" | jq -r '.repo')" = "repo" ]
  [ "$(echo "$result" | jq -r '.confidence')" = "high" ]
  [ "$(echo "$result" | jq -r '.detection_method')" = "https_regex_match" ]
}

@test "Gitea: detects HTTPS URL without .git suffix" {
  source lib/installer-common/vcs-detector.sh

  result=$(extract_gitea_info "https://gitea.com/user/repo")

  [ "$(echo "$result" | jq -r '.provider')" = "gitea" ]
  [ "$(echo "$result" | jq -r '.repo')" = "repo" ]
}
```

**5b. Self-hosted instance tests**:

```bash
@test "Gitea: detects self-hosted SSH URL with medium confidence" {
  source lib/installer-common/vcs-detector.sh

  result=$(extract_gitea_info "git@gitea.example.com:user/repo.git")

  [ "$(echo "$result" | jq -r '.provider')" = "gitea" ]
  [ "$(echo "$result" | jq -r '.domain')" = "gitea.example.com" ]
  [ "$(echo "$result" | jq -r '.confidence')" = "medium" ]
}

@test "Gitea: detects self-hosted HTTPS URL with medium confidence" {
  source lib/installer-common/vcs-detector.sh

  result=$(extract_gitea_info "https://gitea.internal.company.com/team/project.git")

  [ "$(echo "$result" | jq -r '.provider')" = "gitea" ]
  [ "$(echo "$result" | jq -r '.domain')" = "gitea.internal.company.com" ]
  [ "$(echo "$result" | jq -r '.owner')" = "team" ]
  [ "$(echo "$result" | jq -r '.repo')" = "project" ]
  [ "$(echo "$result" | jq -r '.confidence')" = "medium" ]
}
```

**5c. Negative tests**:

```bash
@test "Gitea: rejects invalid URL format" {
  source lib/installer-common/vcs-detector.sh

  run extract_gitea_info "not-a-url"
  [ "$status" -eq 1 ]
}

@test "Gitea: rejects GitHub URL" {
  source lib/installer-common/vcs-detector.sh

  run extract_gitea_info "git@github.com:user/repo.git"
  [ "$status" -eq 1 ]
}

@test "Gitea: rejects malformed SSH URL" {
  source lib/installer-common/vcs-detector.sh

  run extract_gitea_info "git@gitea.com/user/repo"
  [ "$status" -eq 1 ]
}
```

**5d. Edge case tests**:

```bash
@test "Gitea: handles repository names with dots" {
  source lib/installer-common/vcs-detector.sh

  result=$(extract_gitea_info "git@gitea.com:user/my.repo.name.git")

  [ "$(echo "$result" | jq -r '.repo')" = "my.repo.name" ]
}

@test "Gitea: handles repository names with dashes" {
  source lib/installer-common/vcs-detector.sh

  result=$(extract_gitea_info "git@gitea.com:user/my-repo-name.git")

  [ "$(echo "$result" | jq -r '.repo')" = "my-repo-name" ]
}

@test "Gitea: handles custom port in HTTPS URL" {
  source lib/installer-common/vcs-detector.sh

  result=$(extract_gitea_info "https://gitea.example.com:3000/user/repo.git")

  [ "$(echo "$result" | jq -r '.domain')" = "gitea.example.com:3000" ]
  [ "$(echo "$result" | jq -r '.owner')" = "user" ]
  [ "$(echo "$result" | jq -r '.repo')" = "repo" ]
}
```

### Step 6: Update Documentation

**6a. Schema Reference** (`docs/configuration/schema-reference.md`):

Add Gitea provider documentation:

```markdown
#### Gitea Provider

**Configuration**:

vcs:
  provider: "gitea"
  owner: "username"
  repo: "repository-name"
  gitea:
    base_url: "https://gitea.example.com"  # null for gitea.com

**Required Fields**:

- `owner` (string): Repository owner username
- `repo` (string): Repository name

**Optional Fields**:

- `gitea.base_url` (string, null): Gitea instance URL (null for gitea.com)
  - Must be HTTPS
  - Supports self-hosted instances

**Auto-Detection**:

Gitea URLs are detected from git remote:

- SSH: `git@gitea.com:owner/repo.git`
- HTTPS: `https://gitea.com/owner/repo.git`
- Self-hosted: `git@gitea.example.com:owner/repo.git`

**Validation Rules**:

- `owner` must be alphanumeric with hyphens
- `repo` must be alphanumeric with dots/dashes
- `base_url` must start with `https://` if provided
```

**6b. Update provider comparison table**:

```markdown
| Provider   | Owner Field | Repo Field   | Special Fields        |
|------------|-------------|--------------|----------------------|
| GitHub     | owner       | repo         | enterprise_url       |
| GitLab     | owner       | repo         | project_id, self_hosted_url, group |
| Bitbucket  | workspace   | repo_slug    | -                    |
| Gitea      | owner       | repo         | base_url             |
```

### Step 7: Testing Checklist

**Pre-Commit Testing**:

- [ ] All unit tests pass (`bats tests/unit/test_vcs_detection.bats`)
- [ ] Shellcheck passes on vcs-detector.sh
- [ ] JSON Schema validates with test config
- [ ] Markdownlint passes on documentation

**Manual Testing**:

- [ ] Create test Gitea repository
- [ ] Clone with SSH URL, run auto-detection
- [ ] Clone with HTTPS URL, run auto-detection
- [ ] Test self-hosted Gitea instance detection
- [ ] Verify config validation catches errors
- [ ] Test mixed configs (Gitea VCS + GitHub Issues)

**Integration Testing**:

- [ ] Run `/workflow-init` with Gitea repository
- [ ] Verify generated config includes Gitea fields
- [ ] Test workflow commands with Gitea config
- [ ] Cross-platform testing (macOS, Linux)

## URL Pattern Design Best Practices

### Supporting SSH and HTTPS

Most VCS providers support both SSH and HTTPS URL formats:

**SSH Format**:

```text
git@<domain>:<owner>/<repo>.git
```

**HTTPS Format**:

```text
https://<domain>/<owner>/<repo>.git
```

**Regex Patterns**:

```bash
# SSH pattern
readonly PROVIDER_SSH_PATTERN='^git@([^:]+):([^/]+)/([^/]+)(\.git)?$'

# HTTPS pattern
readonly PROVIDER_HTTPS_PATTERN='^https://([^/]+)/([^/]+)/([^/]+)(\.git)?$'
```

**Key regex components**:

- `([^:]+)` - Domain (everything up to colon)
- `([^/]+)` - Owner (everything up to first slash)
- `([^/]+)` - Repo (everything up to next slash or end)
- `(\.git)?` - Optional .git suffix

### Handling Edge Cases

**Optional .git suffix**:

Both `repo.git` and `repo` should work:

```bash
url="${url%.git}"  # Remove .git if present
```

**Custom ports**:

HTTPS URLs may include port numbers:

```text
https://gitea.example.com:3000/user/repo.git
```

Regex must accommodate:

```bash
readonly HTTPS_PATTERN='^https://([^/]+)/([^/]+)/([^/]+)(\.git)?$'
# Domain capture includes port: gitea.example.com:3000
```

**Repository names with special characters**:

Support dots, dashes, underscores:

```bash
# Valid repo names
my-repo
my_repo
my.repo.name
repo123
```

Pattern: `[a-zA-Z0-9][a-zA-Z0-9._-]*`

**URL normalization**:

Always normalize before parsing:

```bash
normalize_url() {
  local url="$1"
  url="${url%%/}"           # Remove trailing slash
  url="${url%.git}"         # Remove .git suffix
  url=$(echo "$url" | tr -d '[:space:]')  # Remove whitespace
  echo "$url"
}
```

### Domain Flexibility

Support both public and self-hosted instances:

**Known public domains** (high confidence):

```bash
readonly GITEA_DOMAINS='^(gitea\.com|gitea\.io)$'
```

**Self-hosted with keyword** (medium confidence):

```bash
elif [[ "$domain" =~ gitea ]]; then
  confidence="medium"
```

**Pattern match only** (low confidence):

```bash
else
  confidence="low"
fi
```

### Confidence Scoring Logic

**Three-tier confidence system**:

```bash
# High: Exact match on known domain
if [[ "$domain" =~ ^provider\.com$ ]]; then
  confidence="high"

# Medium: Domain contains provider keyword
elif [[ "$domain" =~ provider ]]; then
  confidence="medium"

# Low: Pattern matches but unknown domain
else
  confidence="low"
fi
```

**Use cases by confidence**:

- **High**: Auto-populate config, no user confirmation
- **Medium**: Auto-populate with warning, suggest review
- **Low**: Suggest values but require confirmation

### Regex Testing

**Test URL patterns thoroughly**:

```bash
# Public SSH
git@gitea.com:user/repo.git

# Public HTTPS
https://gitea.com/user/repo.git

# Self-hosted SSH
git@gitea.example.com:org/project.git

# Self-hosted HTTPS with port
https://gitea.internal.net:3000/team/app.git

# Without .git suffix
git@gitea.com:user/repo

# Repository with dots
git@gitea.com:user/my.repo.name.git

# Repository with dashes
git@gitea.com:user/my-repo-name.git
```

**Online regex testers**:

- [regex101.com](https://regex101.com) - Test patterns with sample URLs
- [regexr.com](https://regexr.com) - Interactive regex builder

## Validation Rule Addition

Validation rules ensure configuration correctness before use.

### Provider-Specific Validation

Each provider should validate its required fields and formats:

**Structure**:

```bash
validate_<provider>_config() {
  local config="$1"
  local errors=0

  # 1. Check required fields
  # 2. Validate field formats
  # 3. Check provider-specific constraints
  # 4. Return error count

  return $errors
}
```

### Required Field Validation

**Check for presence**:

```bash
local owner repo
owner=$(echo "$config" | jq -r '.vcs.owner // empty')
repo=$(echo "$config" | jq -r '.vcs.repo // empty')

if [[ -z "$owner" ]]; then
  log_error "Provider requires vcs.owner"
  errors=$((errors + 1))
fi

if [[ -z "$repo" ]]; then
  log_error "Provider requires vcs.repo"
  errors=$((errors + 1))
fi
```

### Format Validation

**URL validation**:

```bash
local base_url
base_url=$(echo "$config" | jq -r '.vcs.provider.base_url // empty')

if [[ -n "$base_url" ]]; then
  # Must be HTTPS
  if [[ ! "$base_url" =~ ^https:// ]]; then
    log_error "base_url must start with https://"
    errors=$((errors + 1))
  fi

  # Must match URL pattern
  if [[ ! "$base_url" =~ ^https://[a-zA-Z0-9][a-zA-Z0-9.-]*(:[0-9]+)?(/.*)?$ ]]; then
    log_error "base_url is not a valid URL: $base_url"
    errors=$((errors + 1))
  fi
fi
```

**Username/identifier validation**:

```bash
# Must be alphanumeric with hyphens, not starting/ending with hyphen
if [[ ! "$owner" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$|^[a-zA-Z0-9]$ ]]; then
  log_error "owner contains invalid characters: $owner"
  errors=$((errors + 1))
fi
```

### Provider-Specific Constraints

**GitLab example** (requires project_id):

```bash
validate_gitlab_config() {
  local config="$1"
  local errors=0

  # Standard fields
  local owner repo
  owner=$(echo "$config" | jq -r '.vcs.owner // empty')
  repo=$(echo "$config" | jq -r '.vcs.repo // empty')

  [[ -z "$owner" ]] && { log_error "GitLab requires owner"; errors=$((errors + 1)); }
  [[ -z "$repo" ]] && { log_error "GitLab requires repo"; errors=$((errors + 1)); }

  # GitLab-specific: project_id required
  local project_id
  project_id=$(echo "$config" | jq -r '.vcs.gitlab.project_id // empty')

  if [[ -z "$project_id" ]]; then
    log_error "GitLab requires vcs.gitlab.project_id"
    errors=$((errors + 1))
  else
    # project_id can be numeric ID or full path
    if [[ ! "$project_id" =~ ^[0-9]+$|^[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+$ ]]; then
      log_error "GitLab project_id must be numeric or full path: $project_id"
      errors=$((errors + 1))
    fi
  fi

  return $errors
}
```

### Error Message Templates

**Clear, actionable error messages**:

```bash
# Bad
log_error "Invalid config"

# Good
log_error "Gitea requires vcs.owner to be set"
log_error "base_url must start with https://, got: $base_url"
log_error "owner contains invalid characters (only alphanumeric and hyphens): $owner"
```

**Message guidelines**:

- State which field is invalid
- Explain what's expected
- Show the invalid value (if safe)
- Suggest correction if possible

## Testing New Providers

Comprehensive testing ensures reliability and prevents regressions.

### Unit Test Structure

**File**: `tests/unit/test_vcs_detection.bats`

**Test organization**:

```bash
# 1. Basic detection tests
@test "Provider: detects SSH URL" { ... }
@test "Provider: detects HTTPS URL" { ... }

# 2. URL normalization tests
@test "Provider: handles .git suffix" { ... }
@test "Provider: handles URLs without .git" { ... }

# 3. Self-hosted tests
@test "Provider: detects self-hosted SSH" { ... }
@test "Provider: detects self-hosted HTTPS" { ... }

# 4. Confidence scoring tests
@test "Provider: high confidence for known domain" { ... }
@test "Provider: medium confidence for keyword match" { ... }
@test "Provider: low confidence for unknown domain" { ... }

# 5. Negative tests
@test "Provider: rejects invalid URL" { ... }
@test "Provider: rejects other provider URLs" { ... }

# 6. Edge cases
@test "Provider: handles custom ports" { ... }
@test "Provider: handles special characters in repo name" { ... }
```

### Required Test Coverage

**Minimum tests per provider**:

- SSH URL detection (with .git)
- SSH URL detection (without .git)
- HTTPS URL detection (with .git)
- HTTPS URL detection (without .git)
- Self-hosted instance detection
- Confidence scoring (high/medium/low)
- Invalid URL rejection
- Edge cases (ports, special chars)

**Example test**:

```bash
@test "Gitea: detects SSH URL from gitea.com" {
  source lib/installer-common/vcs-detector.sh

  result=$(extract_gitea_info "git@gitea.com:user/repo.git")

  # Verify all expected fields
  [ "$(echo "$result" | jq -r '.provider')" = "gitea" ]
  [ "$(echo "$result" | jq -r '.owner')" = "user" ]
  [ "$(echo "$result" | jq -r '.repo')" = "repo" ]
  [ "$(echo "$result" | jq -r '.domain')" = "gitea.com" ]
  [ "$(echo "$result" | jq -r '.confidence')" = "high" ]
  [ "$(echo "$result" | jq -r '.detection_method')" = "ssh_regex_match" ]
}
```

### Integration Test Scenarios

**Full workflow testing**:

1. **Auto-detection workflow**:

   ```bash
   # Clone repo with provider URL
   git clone git@gitea.com:user/repo.git test-repo
   cd test-repo

   # Run VCS detection
   detection=$(./lib/installer-common/vcs-detector.sh)

   # Verify provider detected
   provider=$(echo "$detection" | jq -r '.provider')
   [ "$provider" = "gitea" ]
   ```

2. **Config generation workflow**:

   ```bash
   # Initialize workflow config
   ./lib/installer-common/workflow-init.sh

   # Verify config includes provider fields
   [ -f .claude/config.yml ]
   grep -q "provider: gitea" .claude/config.yml
   ```

3. **Mixed provider config**:

   ```bash
   # Gitea VCS + GitHub Issues
   # Verify both providers configured correctly
   ```

### URL Pattern Test Cases

**Test matrix**:

| URL Type | Format | .git Suffix | Port | Expected Result |
|----------|--------|-------------|------|----------------|
| SSH | Public | Yes | N/A | High confidence |
| SSH | Public | No | N/A | High confidence |
| SSH | Self-hosted | Yes | N/A | Medium confidence |
| SSH | Self-hosted | No | N/A | Medium confidence |
| HTTPS | Public | Yes | Default | High confidence |
| HTTPS | Public | No | Default | High confidence |
| HTTPS | Self-hosted | Yes | Custom | Medium confidence |
| HTTPS | Self-hosted | No | Custom | Medium confidence |

**Example URLs for each case**:

```bash
# SSH Public with .git
git@gitea.com:user/repo.git

# SSH Public without .git
git@gitea.com:user/repo

# SSH Self-hosted with .git
git@gitea.example.com:team/project.git

# HTTPS Public default port
https://gitea.com/user/repo.git

# HTTPS Self-hosted custom port
https://gitea.internal.net:3000/org/app.git
```

### Cross-Platform Testing

**macOS vs Linux differences**:

- `date` command format differences
- Regex engine variations (bash versions)
- jq availability

**Docker-based testing**:

```bash
# Test on Ubuntu 22.04
docker run --rm -v $(pwd):/workspace ubuntu:22.04 bash -c "
  apt-get update && apt-get install -y bats jq git
  cd /workspace
  bats tests/unit/test_vcs_detection.bats
"

# Test on Alpine (lightweight)
docker run --rm -v $(pwd):/workspace alpine:latest sh -c "
  apk add bash bats jq git
  cd /workspace
  bats tests/unit/test_vcs_detection.bats
"
```

## Maintenance Checklist

When adding a new VCS provider, complete these tasks:

### Code Changes

- [ ] **Schema**: Add provider to enum in `config-schema.json`
- [ ] **Schema**: Add provider-specific subsection with properties
- [ ] **Schema**: Add conditional validation rules (`allOf`)
- [ ] **Detection**: Add URL patterns to `vcs-detector.sh`
- [ ] **Detection**: Implement `extract_<provider>_info()` function
- [ ] **Detection**: Update `detect_vcs_provider()` to call new function
- [ ] **Validation**: Implement `validate_<provider>_config()` function
- [ ] **Validation**: Add provider case to validation dispatcher
- [ ] **Template**: Create `templates/config/config-<provider>.json`

### Testing

- [ ] **Unit Tests**: Add SSH URL tests (with/without .git)
- [ ] **Unit Tests**: Add HTTPS URL tests (with/without .git)
- [ ] **Unit Tests**: Add self-hosted instance tests
- [ ] **Unit Tests**: Add confidence scoring tests
- [ ] **Unit Tests**: Add negative tests (invalid URLs)
- [ ] **Unit Tests**: Add edge case tests (ports, special chars)
- [ ] **Integration**: Test auto-detection with real repository
- [ ] **Integration**: Test config generation with `/workflow-init`
- [ ] **Integration**: Test validation catches configuration errors
- [ ] **Cross-Platform**: Test on macOS
- [ ] **Cross-Platform**: Test on Linux (Ubuntu, Alpine)

### Documentation

- [ ] **Schema Docs**: Add provider section to `schema-reference.md`
- [ ] **Schema Docs**: Document required/optional fields
- [ ] **Schema Docs**: Add auto-detection examples
- [ ] **Schema Docs**: Update provider comparison table
- [ ] **Integration Guide**: Add provider to supported list (this doc)
- [ ] **Changelog**: Document new provider support
- [ ] **Migration**: Note any breaking changes (should be none)

### Quality Checks

- [ ] **Pre-commit**: All tests pass (`pre-commit run --all-files`)
- [ ] **Shellcheck**: No warnings in `vcs-detector.sh`
- [ ] **Shellcheck**: No warnings in validation functions
- [ ] **JSONSchema**: Validate example config against schema
- [ ] **Markdownlint**: Documentation passes linting
- [ ] **Manual**: Test with real repository clone
- [ ] **Manual**: Verify error messages are clear

## Common Pitfalls

### Domain Matching Too Broad

**Problem**: Regex matches unintended providers

```bash
# BAD: Matches "mygithub.com", "github-clone.org"
if [[ "$domain" =~ github ]]; then
  confidence="high"
fi
```

**Solution**: Use anchored patterns for known domains

```bash
# GOOD: Only matches exact domain
readonly GITHUB_DOMAINS='^github\.com$'
if [[ "$domain" =~ $GITHUB_DOMAINS ]]; then
  confidence="high"
elif [[ "$domain" =~ github ]]; then
  confidence="medium"  # Self-hosted with keyword
fi
```

### Missing .git Suffix Handling

**Problem**: URLs with/without `.git` parsed differently

```bash
# Fails for: git@gitea.com:user/repo (no .git)
if [[ "$url" =~ git@([^:]+):([^/]+)/([^/]+)\.git$ ]]; then
```

**Solution**: Make `.git` optional in regex

```bash
# Works for both: repo.git and repo
if [[ "$url" =~ git@([^:]+):([^/]+)/([^/]+)(\.git)?$ ]]; then
```

### Incorrect Field Extraction

**Problem**: Capturing wrong parts of URL

```bash
# WRONG: Captures port as part of owner
# URL: https://gitea.com:3000/user/repo
if [[ "$url" =~ https://([^/]+):([^/]+)/([^/]+) ]]; then
  domain="${BASH_REMATCH[1]}"  # gitea.com
  owner="${BASH_REMATCH[2]}"   # 3000 (WRONG!)
  repo="${BASH_REMATCH[3]}"    # user (WRONG!)
fi
```

**Solution**: Include port in domain capture

```bash
# CORRECT: Port is part of domain
if [[ "$url" =~ https://([^/]+)/([^/]+)/([^/]+) ]]; then
  domain="${BASH_REMATCH[1]}"  # gitea.com:3000
  owner="${BASH_REMATCH[2]}"   # user
  repo="${BASH_REMATCH[3]}"    # repo
fi
```

### Validation Too Strict

**Problem**: Rejecting valid configurations

```bash
# BAD: Rejects single-character usernames
if [[ ! "$owner" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]$ ]]; then
  log_error "Invalid owner"
fi
```

**Solution**: Handle edge cases explicitly

```bash
# GOOD: Allows single character
if [[ ! "$owner" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$|^[a-zA-Z0-9]$ ]]; then
  log_error "Invalid owner"
fi
```

### Missing Error Messages

**Problem**: User doesn't know what's wrong

```bash
# BAD: Generic error
if [[ -z "$owner" ]]; then
  log_error "Invalid configuration"
  errors=$((errors + 1))
fi
```

**Solution**: Specific, actionable messages

```bash
# GOOD: Clear guidance
if [[ -z "$owner" ]]; then
  log_error "Gitea requires vcs.owner to be set (repository owner username)"
  errors=$((errors + 1))
fi
```

## Related Documentation

- **Schema Reference**: `docs/configuration/schema-reference.md` - Complete schema documentation
- **VCS Detector Source**: `lib/installer-common/vcs-detector.sh` - Implementation reference
- **Config Schema**: `lib/installer-common/config-schema.json` - JSON Schema definition
- **Testing Guide**: `docs/testing/unit-tests.md` - Unit test best practices
- **Contributing**: `docs/CONTRIBUTING.md` - General contribution guidelines

## Future Enhancements

### Potential Providers to Add

**Source Code Hosting**:

- **Gitea** (demonstrated in this guide)
- **Gogs** (Gitea predecessor)
- **Sourcehut** (sr.ht)
- **Codeberg** (Gitea-based)
- **Azure DevOps** (Microsoft)
- **AWS CodeCommit** (Amazon)

**Self-Hosted Solutions**:

- **Gerrit** (Google-style code review)
- **Phabricator** (Facebook)
- **RhodeCode** (Enterprise)

### Provider Interface Improvements

**API Connectivity Validation**:

```bash
validate_api_connection() {
  local provider="$1"
  local base_url="$2"

  # Ping provider API
  # Verify credentials work
  # Check feature availability
}
```

**Feature Detection**:

```bash
detect_provider_features() {
  # Supports pull requests?
  # Supports draft PRs?
  # Supports labels?
  # Supports milestones?
  # API rate limits?
}
```

**Provider-Specific Operations Abstraction**:

```bash
# Unified interface across providers
create_pull_request() {
  local provider="$1"
  case "$provider" in
    github) github_create_pr "$@" ;;
    gitlab) gitlab_create_mr "$@" ;;
    gitea) gitea_create_pr "$@" ;;
  esac
}
```

### Auto-Configuration Enhancements

**Credential Management**:

- Detect existing credentials (gh, glab, git-credential)
- Validate API access before generating config
- Suggest credential setup if missing

**Smart Defaults**:

- Infer main branch from HEAD
- Detect default reviewers from CODEOWNERS
- Auto-populate team members from contributor list

**Migration Assistance**:

- Detect provider changes (GitHub → GitLab)
- Suggest config updates
- Validate cross-provider compatibility

---

**Last Updated**: 2025-10-20
**Version**: 1.0
**Maintained By**: AIDA Core Team
