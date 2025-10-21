#!/usr/bin/env bash
# vcs-detector.sh - Version Control System detection library
#
# Detects VCS provider (GitHub, GitLab, Bitbucket) from git remote URLs
# and extracts repository metadata (owner, repo, main branch, etc.)
#
# Usage Examples:
#   # Detect VCS provider for current repository
#   source lib/installer-common/vcs-detector.sh
#   detection=$(detect_vcs_provider)
#   echo "$detection" | jq -r '.provider'  # → "github"
#   echo "$detection" | jq -r '.owner'     # → "oakensoul"
#
#   # Extract GitHub info from URL
#   github_info=$(extract_github_info "git@github.com:user/repo.git")
#   echo "$github_info" | jq -r '.owner'   # → "user"
#
#   # Get main branch name
#   branch=$(detect_main_branch)           # → "main"
#
#   # Run as standalone script
#   ./vcs-detector.sh | jq .
#
# Functions:
#   detect_vcs_provider()      - Main detection entry point
#   extract_github_info()      - Parse GitHub URLs (SSH/HTTPS, github.com/enterprise)
#   extract_gitlab_info()      - Parse GitLab URLs (SSH/HTTPS, gitlab.com/self-hosted)
#   extract_bitbucket_info()   - Parse Bitbucket URLs (SSH/HTTPS)
#   detect_main_branch()       - Get default branch name from git
#   get_detection_confidence() - Calculate confidence level (high/medium/low)
#
# Supported URL Formats:
#   GitHub:    git@github.com:owner/repo.git, https://github.com/owner/repo
#   GitLab:    git@gitlab.com:owner/repo.git, https://gitlab.com/owner/repo
#   Bitbucket: git@bitbucket.org:workspace/repo.git, https://bitbucket.org/workspace/repo
#   Enterprise: Works with self-hosted instances (confidence: medium)
#
# Returns: JSON output with detection metadata
#
# Exit codes:
#   0 - Success
#   1 - Error (no remote, invalid URL, etc.)
#
# Environment Variables:
#   VCS_DEBUG=1  - Enable debug logging to stderr

set -euo pipefail

# Source shared utilities if available
# Use BASH_SOURCE if available (bash), fallback to sourced file path (zsh)
if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
    # Fallback for zsh or direct execution
    # shellcheck disable=SC2296  # zsh-specific syntax
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
fi
readonly SCRIPT_DIR
# Simple logging functions (standalone - no external dependencies)
# These provide basic debug/info/warn/error output to stderr
log_debug() {
    if [[ "${VCS_DEBUG:-0}" == "1" ]]; then
        echo "[DEBUG] $*" >&2
    fi
}
log_info() { echo "[INFO] $*" >&2; }
log_warn() { echo "[WARN] $*" >&2; }
log_error() { echo "[ERROR] $*" >&2; }

# Regex patterns for VCS URL detection
# GitHub patterns (github.com and enterprise)
readonly GITHUB_SSH_PATTERN='^git@([^:]+):([^/]+)/([^/]+)(\.git)?$'
readonly GITHUB_HTTPS_PATTERN='^https://([^/]+)/([^/]+)/([^/]+)(\.git)?$'

# GitLab patterns (gitlab.com and self-hosted)
readonly GITLAB_SSH_PATTERN='^git@([^:]+):([^/]+)/([^/]+)(\.git)?$'
readonly GITLAB_HTTPS_PATTERN='^https://([^/]+)/([^/]+)/([^/]+)(\.git)?$'

# Bitbucket patterns
readonly BITBUCKET_SSH_PATTERN='^git@([^:]+):([^/]+)/([^/]+)(\.git)?$'
readonly BITBUCKET_HTTPS_PATTERN='^https://([^/]+)/([^/]+)/([^/]+)(\.git)?$'

# Known VCS provider domains for high-confidence detection
# Use anchored patterns to avoid matching enterprise subdomains
readonly GITHUB_DOMAINS='^github\.com$'
readonly GITLAB_DOMAINS='^gitlab\.com$'
readonly BITBUCKET_DOMAINS='^bitbucket\.org$'

# get_git_remote_url() - Get the git remote URL for the specified remote
#
# Args:
#   $1 - Remote name (default: "origin")
#
# Returns:
#   Remote URL on stdout, empty string if not found
#
# Exit codes:
#   0 - Success (remote found)
#   1 - Error (not a git repo or remote not found)
get_git_remote_url() {
    local remote_name="${1:-origin}"
    local remote_url

    # Check if we're in a git repository
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        log_debug "Not in a git repository"
        return 1
    fi

    # Get remote URL
    if ! remote_url=$(git remote get-url "$remote_name" 2>/dev/null); then
        log_debug "Remote '$remote_name' not found"
        return 1
    fi

    # Normalize URL (remove trailing slash, whitespace)
    remote_url=$(echo "$remote_url" | sed 's:/*$::' | tr -d '[:space:]')

    echo "$remote_url"
    return 0
}

# normalize_url() - Normalize git remote URL for consistent parsing
#
# Args:
#   $1 - Raw remote URL
#
# Returns:
#   Normalized URL on stdout
normalize_url() {
    local url="$1"

    # Remove trailing slashes
    url="${url%%/}"

    # Remove trailing .git if present
    url="${url%.git}"

    # Remove whitespace
    url=$(echo "$url" | tr -d '[:space:]')

    echo "$url"
}

# extract_github_info() - Extract owner and repo from GitHub URL
#
# Args:
#   $1 - GitHub remote URL (SSH or HTTPS)
#
# Returns:
#   JSON with owner, repo, domain, confidence
#
# Supported formats:
#   SSH: git@github.com:owner/repo.git
#   HTTPS: https://github.com/owner/repo.git
#   Enterprise: git@github.company.com:owner/repo.git
extract_github_info() {
    local url="$1"
    local domain owner repo confidence detection_method

    url=$(normalize_url "$url")

    # Try SSH format: git@github.com:owner/repo
    if [[ "$url" =~ $GITHUB_SSH_PATTERN ]]; then
        domain="${BASH_REMATCH[1]}"
        owner="${BASH_REMATCH[2]}"
        repo="${BASH_REMATCH[3]}"
        detection_method="ssh_regex_match"

        # Check if domain matches known GitHub domain
        if [[ "$domain" =~ $GITHUB_DOMAINS ]]; then
            confidence="high"
        elif [[ "$domain" =~ github ]]; then
            confidence="medium"  # Enterprise GitHub
        else
            # Domain doesn't match GitHub - reject
            log_debug "Domain '$domain' is not GitHub, rejecting"
            return 1
        fi

    # Try HTTPS format: https://github.com/owner/repo
    elif [[ "$url" =~ $GITHUB_HTTPS_PATTERN ]]; then
        domain="${BASH_REMATCH[1]}"
        owner="${BASH_REMATCH[2]}"
        repo="${BASH_REMATCH[3]}"
        detection_method="https_regex_match"

        # Check if domain matches known GitHub domain
        if [[ "$domain" =~ $GITHUB_DOMAINS ]]; then
            confidence="high"
        elif [[ "$domain" =~ github ]]; then
            confidence="medium"  # Enterprise GitHub
        else
            # Domain doesn't match GitHub - reject
            log_debug "Domain '$domain' is not GitHub, rejecting"
            return 1
        fi
    else
        log_debug "URL does not match GitHub patterns: $url"
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

# extract_gitlab_info() - Extract owner and repo from GitLab URL
#
# Args:
#   $1 - GitLab remote URL (SSH or HTTPS)
#
# Returns:
#   JSON with owner, repo, domain, confidence
#
# Supported formats:
#   SSH: git@gitlab.com:owner/repo.git
#   HTTPS: https://gitlab.com/owner/repo.git
#   Self-hosted: git@gitlab.company.com:owner/repo.git
extract_gitlab_info() {
    local url="$1"
    local domain owner repo confidence detection_method

    url=$(normalize_url "$url")

    # Try SSH format: git@gitlab.com:owner/repo
    if [[ "$url" =~ $GITLAB_SSH_PATTERN ]]; then
        domain="${BASH_REMATCH[1]}"
        owner="${BASH_REMATCH[2]}"
        repo="${BASH_REMATCH[3]}"
        detection_method="ssh_regex_match"

        # Check if domain matches known GitLab domain
        if [[ "$domain" =~ $GITLAB_DOMAINS ]]; then
            confidence="high"
        elif [[ "$domain" =~ gitlab ]]; then
            confidence="medium"  # Self-hosted GitLab
        else
            # Domain doesn't match GitLab - reject
            log_debug "Domain '$domain' is not GitLab, rejecting"
            return 1
        fi

    # Try HTTPS format: https://gitlab.com/owner/repo
    elif [[ "$url" =~ $GITLAB_HTTPS_PATTERN ]]; then
        domain="${BASH_REMATCH[1]}"
        owner="${BASH_REMATCH[2]}"
        repo="${BASH_REMATCH[3]}"
        detection_method="https_regex_match"

        # Check if domain matches known GitLab domain
        if [[ "$domain" =~ $GITLAB_DOMAINS ]]; then
            confidence="high"
        elif [[ "$domain" =~ gitlab ]]; then
            confidence="medium"  # Self-hosted GitLab
        else
            # Domain doesn't match GitLab - reject
            log_debug "Domain '$domain' is not GitLab, rejecting"
            return 1
        fi
    else
        log_debug "URL does not match GitLab patterns: $url"
        return 1
    fi

    # Return JSON
    cat <<EOF
{
  "provider": "gitlab",
  "domain": "$domain",
  "owner": "$owner",
  "repo": "$repo",
  "confidence": "$confidence",
  "detection_method": "$detection_method"
}
EOF
    return 0
}

# extract_bitbucket_info() - Extract workspace and repo_slug from Bitbucket URL
#
# Args:
#   $1 - Bitbucket remote URL (SSH or HTTPS)
#
# Returns:
#   JSON with workspace, repo_slug, domain, confidence
#
# Supported formats:
#   SSH: git@bitbucket.org:workspace/repo.git
#   HTTPS: https://bitbucket.org/workspace/repo.git
extract_bitbucket_info() {
    local url="$1"
    local domain workspace repo_slug confidence detection_method

    url=$(normalize_url "$url")

    # Try SSH format: git@bitbucket.org:workspace/repo
    if [[ "$url" =~ $BITBUCKET_SSH_PATTERN ]]; then
        domain="${BASH_REMATCH[1]}"
        workspace="${BASH_REMATCH[2]}"
        repo_slug="${BASH_REMATCH[3]}"
        detection_method="ssh_regex_match"

        # Check if domain matches known Bitbucket domain
        if [[ "$domain" =~ $BITBUCKET_DOMAINS ]]; then
            confidence="high"
        elif [[ "$domain" =~ bitbucket ]]; then
            confidence="medium"  # Self-hosted Bitbucket
        else
            # Domain doesn't match Bitbucket - reject
            log_debug "Domain '$domain' is not Bitbucket, rejecting"
            return 1
        fi

    # Try HTTPS format: https://bitbucket.org/workspace/repo
    elif [[ "$url" =~ $BITBUCKET_HTTPS_PATTERN ]]; then
        domain="${BASH_REMATCH[1]}"
        workspace="${BASH_REMATCH[2]}"
        repo_slug="${BASH_REMATCH[3]}"
        detection_method="https_regex_match"

        # Check if domain matches known Bitbucket domain
        if [[ "$domain" =~ $BITBUCKET_DOMAINS ]]; then
            confidence="high"
        elif [[ "$domain" =~ bitbucket ]]; then
            confidence="medium"  # Self-hosted Bitbucket
        else
            # Domain doesn't match Bitbucket - reject
            log_debug "Domain '$domain' is not Bitbucket, rejecting"
            return 1
        fi
    else
        log_debug "URL does not match Bitbucket patterns: $url"
        return 1
    fi

    # Return JSON (Bitbucket uses "workspace" instead of "owner")
    cat <<EOF
{
  "provider": "bitbucket",
  "domain": "$domain",
  "workspace": "$workspace",
  "repo_slug": "$repo_slug",
  "confidence": "$confidence",
  "detection_method": "$detection_method"
}
EOF
    return 0
}

# detect_main_branch() - Detect the default/main branch name
#
# Returns:
#   Branch name on stdout (e.g., "main", "master", "develop")
#   Falls back to "main" if detection fails
#
# Detection methods (in order):
#   1. git symbolic-ref refs/remotes/origin/HEAD
#   2. git remote show origin (slower, requires network)
#   3. Fallback to "main"
detect_main_branch() {
    local branch

    # Method 1: Check symbolic ref (fast, local)
    if branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null); then
        # Extract branch name from refs/remotes/origin/main
        branch="${branch#refs/remotes/origin/}"
        log_debug "Detected main branch via symbolic-ref: $branch"
        echo "$branch"
        return 0
    fi

    # Method 2: Query remote (slower, requires network)
    if branch=$(git remote show origin 2>/dev/null | grep 'HEAD branch' | cut -d' ' -f5); then
        if [[ -n "$branch" ]]; then
            log_debug "Detected main branch via remote show: $branch"
            echo "$branch"
            return 0
        fi
    fi

    # Fallback to "main"
    log_debug "Could not detect main branch, falling back to 'main'"
    echo "main"
    return 0
}

# get_detection_confidence() - Calculate overall detection confidence
#
# Args:
#   $1 - Provider detection confidence (high/medium/low)
#   $2 - Branch detection success (true/false)
#
# Returns:
#   Confidence level: "high", "medium", or "low"
#
# Confidence rules:
#   high   - Exact match on known domain AND branch detected
#   medium - Pattern match but unknown subdomain OR branch fallback
#   low    - Fallback/guess
get_detection_confidence() {
    local provider_confidence="${1:-low}"
    local branch_detected="${2:-false}"

    # High confidence requires both high provider confidence and branch detection
    if [[ "$provider_confidence" == "high" && "$branch_detected" == "true" ]]; then
        echo "high"
    elif [[ "$provider_confidence" == "high" || "$branch_detected" == "true" ]]; then
        echo "medium"
    else
        echo "low"
    fi
}

# detect_vcs_provider() - Main detection entry point
#
# Detects VCS provider from git remote URL and returns comprehensive metadata
#
# Args:
#   $1 - Optional: remote name (default: "origin")
#
# Returns:
#   JSON with complete detection results
#
# Exit codes:
#   0 - Success
#   1 - Error (not a git repo, no remote, etc.)
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

    # Unknown provider
    else
        provider="unknown"
        confidence="low"
        detection_method="no_match"
        log_warn "Could not detect VCS provider for URL: $remote_url"
    fi

    # Detect main branch
    if main_branch=$(detect_main_branch 2>/dev/null); then
        branch_detected="true"
    else
        main_branch="main"
        branch_detected="false"
    fi

    # Calculate overall confidence
    confidence=$(get_detection_confidence "$confidence" "$branch_detected")

    # Get current timestamp in ISO 8601 format
    detected_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Build JSON output (handle Bitbucket's different field names)
    if [[ "$provider" == "bitbucket" ]]; then
        cat <<EOF
{
  "provider": "$provider",
  "domain": "${domain:-unknown}",
  "workspace": "${workspace:-unknown}",
  "repo_slug": "${repo_slug:-unknown}",
  "main_branch": "$main_branch",
  "confidence": "$confidence",
  "detection_method": "$detection_method",
  "remote_url": "$remote_url",
  "remote_name": "$remote_name",
  "detected_at": "$detected_at"
}
EOF
    else
        cat <<EOF
{
  "provider": "$provider",
  "domain": "${domain:-unknown}",
  "owner": "${owner:-unknown}",
  "repo": "${repo:-unknown}",
  "main_branch": "$main_branch",
  "confidence": "$confidence",
  "detection_method": "$detection_method",
  "remote_url": "$remote_url",
  "remote_name": "$remote_name",
  "detected_at": "$detected_at"
}
EOF
    fi

    return 0
}

# If script is executed directly (not sourced), run detection
# Check if running as a script (bash or zsh)
if [[ -n "${BASH_SOURCE[0]:-}" && "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # bash
    detect_vcs_provider "$@"
elif [[ -n "${ZSH_EVAL_CONTEXT:-}" && "${ZSH_EVAL_CONTEXT}" == "toplevel" ]]; then
    # zsh
    detect_vcs_provider "$@"
fi
