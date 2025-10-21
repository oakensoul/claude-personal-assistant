#!/usr/bin/env bash
# detect-vcs.sh - VCS Provider Detection CLI Tool
#
# CLI tool for VCS provider detection and debugging
# Wrapper around vcs-detector.sh library
#
# Usage:
#   ./scripts/detect-vcs.sh                    # Detect current repository
#   ./scripts/detect-vcs.sh --json             # JSON output
#   ./scripts/detect-vcs.sh --verbose          # Show detection process
#   ./scripts/detect-vcs.sh --path /path/repo  # Detect specific repository
#   ./scripts/detect-vcs.sh --url "URL"        # Test URL parsing
#   ./scripts/detect-vcs.sh --help             # Show help
#
# Exit codes:
#   0 - Detection successful
#   1 - Detection failed (no git remote, invalid URL, etc.)
#   2 - Error (invalid arguments, missing dependencies, etc.)
#
# Author: oakensoul
# License: AGPL-3.0
# Repository: https://github.com/oakensoul/claude-personal-assistant

set -euo pipefail

# Get script and project directories
CLI_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CLI_SCRIPT_DIR
CLI_PROJECT_ROOT="$(cd "$CLI_SCRIPT_DIR/.." && pwd)"
readonly CLI_PROJECT_ROOT

# Source detection library and colors
# shellcheck source=../lib/installer-common/vcs-detector.sh
source "${CLI_PROJECT_ROOT}/lib/installer-common/vcs-detector.sh"
# shellcheck source=../lib/installer-common/colors.sh
source "${CLI_PROJECT_ROOT}/lib/installer-common/colors.sh"

# Global flags
OUTPUT_MODE="human"     # human, json, verbose
REPO_PATH=""            # Path to git repository
TEST_URL=""             # URL to test parsing
REMOTE_NAME="origin"    # Git remote name

#######################################
# Show usage information
# Outputs:
#   Help text to stdout
#######################################
show_help() {
    cat <<'EOF'
detect-vcs.sh - VCS Provider Detection CLI Tool

Detects VCS provider (GitHub, GitLab, Bitbucket) from git remote URLs
and extracts repository metadata.

USAGE:
    detect-vcs.sh [OPTIONS]

OPTIONS:
    --help              Show this help message
    --json              Output results as JSON
    --verbose           Show detailed detection process
    --path PATH         Path to git repository (default: current directory)
    --url URL           Test specific URL (no git repo required)
    --remote NAME       Git remote name (default: origin)

EXAMPLES:
    # Detect current repository
    detect-vcs.sh

    # JSON output for scripting
    detect-vcs.sh --json

    # Verbose mode for debugging
    detect-vcs.sh --verbose

    # Detect specific repository
    detect-vcs.sh --path /path/to/repo

    # Test URL parsing
    detect-vcs.sh --url "git@github.com:user/repo.git"

    # Use different remote
    detect-vcs.sh --remote upstream

OUTPUT FORMATS:
    Human-readable (default):
        Provider:     GitHub
        Domain:       github.com
        Owner:        oakensoul
        Repository:   claude-personal-assistant
        ...

    JSON (--json):
        {"provider": "github", "domain": "github.com", ...}

    Verbose (--verbose):
        Step-by-step detection process with pattern matching details

EXIT CODES:
    0 - Detection successful
    1 - Detection failed (no git remote, invalid URL, etc.)
    2 - Error (invalid arguments, missing dependencies, etc.)

SUPPORTED VCS PROVIDERS:
    - GitHub (github.com and enterprise)
    - GitLab (gitlab.com and self-hosted)
    - Bitbucket (bitbucket.org)

EOF
}

#######################################
# Format JSON output with pretty-printing
# Reads JSON from stdin
# Outputs:
#   Pretty-printed JSON to stdout
#######################################
format_json() {
    # Try jq for pretty printing, fall back to cat
    if command -v jq >/dev/null 2>&1; then
        jq .
    else
        cat
    fi
}

#######################################
# Format human-readable output
# Reads JSON from stdin
# Outputs:
#   Human-readable formatted text
#######################################
format_human_readable() {
    local json
    json=$(cat)

    # Extract values from JSON (using grep/cut for portability)
    local provider domain owner repo workspace repo_slug main_branch confidence
    local remote_url remote_name detection_method detected_at

    provider=$(echo "$json" | grep -o '"provider": *"[^"]*"' | cut -d'"' -f4)
    domain=$(echo "$json" | grep -o '"domain": *"[^"]*"' | cut -d'"' -f4)
    owner=$(echo "$json" | grep -o '"owner": *"[^"]*"' | cut -d'"' -f4 || echo "")
    repo=$(echo "$json" | grep -o '"repo": *"[^"]*"' | cut -d'"' -f4 || echo "")
    workspace=$(echo "$json" | grep -o '"workspace": *"[^"]*"' | cut -d'"' -f4 || echo "")
    repo_slug=$(echo "$json" | grep -o '"repo_slug": *"[^"]*"' | cut -d'"' -f4 || echo "")
    main_branch=$(echo "$json" | grep -o '"main_branch": *"[^"]*"' | cut -d'"' -f4 || echo "")
    confidence=$(echo "$json" | grep -o '"confidence": *"[^"]*"' | cut -d'"' -f4)
    remote_url=$(echo "$json" | grep -o '"remote_url": *"[^"]*"' | cut -d'"' -f4 || echo "")
    remote_name=$(echo "$json" | grep -o '"remote_name": *"[^"]*"' | cut -d'"' -f4 || echo "")
    detection_method=$(echo "$json" | grep -o '"detection_method": *"[^"]*"' | cut -d'"' -f4)
    detected_at=$(echo "$json" | grep -o '"detected_at": *"[^"]*"' | cut -d'"' -f4 || echo "")

    # Display header
    echo ""
    echo "VCS Detection Results"
    echo "═══════════════════════════════════════"
    echo ""

    # Color code based on provider
    local provider_display
    case "$provider" in
        github)
            provider_display=$(color_green "GitHub")
            ;;
        gitlab)
            provider_display=$(color_blue "GitLab")
            ;;
        bitbucket)
            provider_display=$(color_yellow "Bitbucket")
            ;;
        unknown)
            provider_display=$(color_red "Unknown")
            ;;
        *)
            provider_display="$provider"
            ;;
    esac

    # Display basic info
    printf "%-14s %s\n" "Provider:" "$provider_display"
    printf "%-14s %s\n" "Domain:" "$domain"

    # Bitbucket uses different field names
    if [[ "$provider" == "bitbucket" ]]; then
        printf "%-14s %s\n" "Workspace:" "$workspace"
        printf "%-14s %s\n" "Repository:" "$repo_slug"
    else
        printf "%-14s %s\n" "Owner:" "$owner"
        printf "%-14s %s\n" "Repository:" "$repo"
    fi

    if [[ -n "$main_branch" ]]; then
        printf "%-14s %s\n" "Main Branch:" "$main_branch"
    fi

    # Color code confidence
    local confidence_display
    case "$confidence" in
        high)
            confidence_display=$(color_green "high")
            ;;
        medium)
            confidence_display=$(color_yellow "medium")
            ;;
        low)
            confidence_display=$(color_red "low")
            ;;
        *)
            confidence_display="$confidence"
            ;;
    esac
    printf "%-14s %s\n" "Confidence:" "$confidence_display"

    # Display technical details
    echo ""
    if [[ -n "$remote_url" ]]; then
        printf "%-14s %s\n" "Remote URL:" "$remote_url"
    fi
    if [[ -n "$remote_name" ]]; then
        printf "%-14s %s\n" "Remote Name:" "$remote_name"
    fi
    printf "%-14s %s\n" "Detection:" "$detection_method"
    if [[ -n "$detected_at" ]]; then
        printf "%-14s %s\n" "Detected at:" "$detected_at"
    fi
    echo ""
}

#######################################
# Format verbose output with step-by-step details
# Reads JSON from stdin
# Arguments:
#   $1 - Remote URL being tested
# Outputs:
#   Detailed detection process
#######################################
format_verbose() {
    local test_url="${1:-}"
    local json
    json=$(cat)

    # Extract values
    local provider domain owner repo workspace repo_slug main_branch confidence
    local remote_url remote_name detection_method

    provider=$(echo "$json" | grep -o '"provider": *"[^"]*"' | cut -d'"' -f4)
    domain=$(echo "$json" | grep -o '"domain": *"[^"]*"' | cut -d'"' -f4)
    owner=$(echo "$json" | grep -o '"owner": *"[^"]*"' | cut -d'"' -f4 || echo "")
    repo=$(echo "$json" | grep -o '"repo": *"[^"]*"' | cut -d'"' -f4 || echo "")
    workspace=$(echo "$json" | grep -o '"workspace": *"[^"]*"' | cut -d'"' -f4 || echo "")
    repo_slug=$(echo "$json" | grep -o '"repo_slug": *"[^"]*"' | cut -d'"' -f4 || echo "")
    main_branch=$(echo "$json" | grep -o '"main_branch": *"[^"]*"' | cut -d'"' -f4 || echo "")
    confidence=$(echo "$json" | grep -o '"confidence": *"[^"]*"' | cut -d'"' -f4)
    remote_url=$(echo "$json" | grep -o '"remote_url": *"[^"]*"' | cut -d'"' -f4 || echo "$test_url")
    remote_name=$(echo "$json" | grep -o '"remote_name": *"[^"]*"' | cut -d'"' -f4 || echo "N/A")
    detection_method=$(echo "$json" | grep -o '"detection_method": *"[^"]*"' | cut -d'"' -f4)

    # Display verbose header
    echo ""
    echo "VCS Detection (Verbose Mode)"
    echo "═══════════════════════════════════════"
    echo ""

    # Step 1: Getting URL
    color_blue "Step 1: Getting git remote URL"
    if [[ -n "$test_url" ]]; then
        echo "  Mode: URL test (no git required)"
        echo "  URL: $remote_url"
    else
        echo "  Remote: $remote_name"
        echo "  URL: $remote_url"
    fi
    echo ""

    # Step 2: Detecting provider
    color_blue "Step 2: Detecting provider"
    echo "  Testing provider patterns..."

    # Show which patterns were tested based on detection method
    case "$detection_method" in
        ssh_regex_match)
            echo "    SSH pattern: $(color_green "MATCH ✓")"
            echo "    HTTPS pattern: skipped (SSH matched)"
            ;;
        https_regex_match)
            echo "    SSH pattern: no match"
            echo "    HTTPS pattern: $(color_green "MATCH ✓")"
            ;;
        no_match)
            echo "    SSH pattern: no match"
            echo "    HTTPS pattern: no match"
            echo "    $(color_red "No provider patterns matched")"
            ;;
        *)
            echo "    Method: $detection_method"
            ;;
    esac

    echo "  Provider: $provider"

    # Show confidence reasoning
    case "$confidence" in
        high)
            echo "  Confidence: $(color_green "high") (exact domain match)"
            ;;
        medium)
            echo "  Confidence: $(color_yellow "medium") (pattern match, enterprise/self-hosted)"
            ;;
        low)
            echo "  Confidence: $(color_red "low") (fallback/unknown)"
            ;;
        *)
            echo "  Confidence: $confidence"
            ;;
    esac
    echo ""

    # Step 3: Extracting metadata
    if [[ "$provider" != "unknown" ]]; then
        color_blue "Step 3: Extracting metadata"
        if [[ "$provider" == "bitbucket" ]]; then
            echo "  Workspace: $workspace"
            echo "  Repository: $repo_slug"
        else
            echo "  Owner: $owner"
            echo "  Repository: $repo"
        fi
        echo "  Domain: $domain"
        echo ""
    fi

    # Step 4: Detecting main branch (only if not URL test)
    if [[ -z "$test_url" && -n "$main_branch" ]]; then
        color_blue "Step 4: Detecting main branch"
        echo "  Method: git symbolic-ref / remote show"
        echo "  Branch: $main_branch"
        echo ""
    fi

    # Final result
    echo "═══════════════════════════════════════"
    if [[ "$provider" != "unknown" && "$confidence" != "low" ]]; then
        color_green "Final Result: Success ($confidence confidence)"
    elif [[ "$provider" != "unknown" ]]; then
        color_yellow "Final Result: Detected with low confidence"
    else
        color_red "Final Result: Detection failed"
    fi
    echo ""
}

#######################################
# Test URL parsing without git repository
# Arguments:
#   $1 - URL to test
# Outputs:
#   Detection results
# Returns:
#   0 on success, 1 on failure
#######################################
test_url() {
    local url="$1"
    local result

    # Try each provider's extraction function
    if result=$(extract_github_info "$url" 2>/dev/null); then
        # Add remote_url to result
        local provider domain owner repo confidence detection_method
        provider=$(echo "$result" | grep -o '"provider": *"[^"]*"' | cut -d'"' -f4)
        domain=$(echo "$result" | grep -o '"domain": *"[^"]*"' | cut -d'"' -f4)
        owner=$(echo "$result" | grep -o '"owner": *"[^"]*"' | cut -d'"' -f4)
        repo=$(echo "$result" | grep -o '"repo": *"[^"]*"' | cut -d'"' -f4)
        confidence=$(echo "$result" | grep -o '"confidence": *"[^"]*"' | cut -d'"' -f4)
        detection_method=$(echo "$result" | grep -o '"detection_method": *"[^"]*"' | cut -d'"' -f4)

        result=$(cat <<EOF
{
  "provider": "$provider",
  "domain": "$domain",
  "owner": "$owner",
  "repo": "$repo",
  "confidence": "$confidence",
  "detection_method": "$detection_method",
  "remote_url": "$url"
}
EOF
)
    elif result=$(extract_gitlab_info "$url" 2>/dev/null); then
        # Add remote_url to result
        local provider domain owner repo confidence detection_method
        provider=$(echo "$result" | grep -o '"provider": *"[^"]*"' | cut -d'"' -f4)
        domain=$(echo "$result" | grep -o '"domain": *"[^"]*"' | cut -d'"' -f4)
        owner=$(echo "$result" | grep -o '"owner": *"[^"]*"' | cut -d'"' -f4)
        repo=$(echo "$result" | grep -o '"repo": *"[^"]*"' | cut -d'"' -f4)
        confidence=$(echo "$result" | grep -o '"confidence": *"[^"]*"' | cut -d'"' -f4)
        detection_method=$(echo "$result" | grep -o '"detection_method": *"[^"]*"' | cut -d'"' -f4)

        result=$(cat <<EOF
{
  "provider": "$provider",
  "domain": "$domain",
  "owner": "$owner",
  "repo": "$repo",
  "confidence": "$confidence",
  "detection_method": "$detection_method",
  "remote_url": "$url"
}
EOF
)
    elif result=$(extract_bitbucket_info "$url" 2>/dev/null); then
        # Add remote_url to result
        local provider domain workspace repo_slug confidence detection_method
        provider=$(echo "$result" | grep -o '"provider": *"[^"]*"' | cut -d'"' -f4)
        domain=$(echo "$result" | grep -o '"domain": *"[^"]*"' | cut -d'"' -f4)
        workspace=$(echo "$result" | grep -o '"workspace": *"[^"]*"' | cut -d'"' -f4)
        repo_slug=$(echo "$result" | grep -o '"repo_slug": *"[^"]*"' | cut -d'"' -f4)
        confidence=$(echo "$result" | grep -o '"confidence": *"[^"]*"' | cut -d'"' -f4)
        detection_method=$(echo "$result" | grep -o '"detection_method": *"[^"]*"' | cut -d'"' -f4)

        result=$(cat <<EOF
{
  "provider": "$provider",
  "domain": "$domain",
  "workspace": "$workspace",
  "repo_slug": "$repo_slug",
  "confidence": "$confidence",
  "detection_method": "$detection_method",
  "remote_url": "$url"
}
EOF
)
    else
        # Unknown provider
        result=$(cat <<EOF
{
  "provider": "unknown",
  "error": "no_pattern_match",
  "confidence": "low",
  "detection_method": "no_match",
  "remote_url": "$url"
}
EOF
)
    fi

    echo "$result"

    # Return success if provider detected
    local provider
    provider=$(echo "$result" | grep -o '"provider": *"[^"]*"' | cut -d'"' -f4)
    if [[ "$provider" != "unknown" ]]; then
        return 0
    else
        return 1
    fi
}

#######################################
# Main entry point
# Arguments:
#   Command-line arguments
# Returns:
#   0 on success, 1 on detection failure, 2 on error
#######################################
main() {
    local exit_code=0

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)
                show_help
                return 0
                ;;
            --json)
                OUTPUT_MODE="json"
                shift
                ;;
            --verbose|-v)
                OUTPUT_MODE="verbose"
                shift
                ;;
            --path)
                if [[ -z "${2:-}" ]]; then
                    color_red "Error: --path requires an argument" >&2
                    echo "Try 'detect-vcs.sh --help' for more information." >&2
                    return 2
                fi
                REPO_PATH="$2"
                shift 2
                ;;
            --url)
                if [[ -z "${2:-}" ]]; then
                    color_red "Error: --url requires an argument" >&2
                    echo "Try 'detect-vcs.sh --help' for more information." >&2
                    return 2
                fi
                TEST_URL="$2"
                shift 2
                ;;
            --remote)
                if [[ -z "${2:-}" ]]; then
                    color_red "Error: --remote requires an argument" >&2
                    echo "Try 'detect-vcs.sh --help' for more information." >&2
                    return 2
                fi
                REMOTE_NAME="$2"
                shift 2
                ;;
            *)
                color_red "Error: Unknown option: $1" >&2
                echo "Try 'detect-vcs.sh --help' for more information." >&2
                return 2
                ;;
        esac
    done

    # Check for required commands
    if [[ -z "$TEST_URL" ]] && ! command -v git >/dev/null 2>&1; then
        color_red "Error: git is required but not installed" >&2
        echo "Install git or use --url to test URL parsing without git." >&2
        return 2
    fi

    # Change to repository path if specified
    if [[ -n "$REPO_PATH" ]]; then
        if [[ ! -d "$REPO_PATH" ]]; then
            color_red "Error: Directory does not exist: $REPO_PATH" >&2
            return 2
        fi
        cd "$REPO_PATH" || {
            color_red "Error: Cannot access directory: $REPO_PATH" >&2
            return 2
        }
    fi

    # Run detection
    local result
    if [[ -n "$TEST_URL" ]]; then
        # Test URL mode
        if result=$(test_url "$TEST_URL" 2>&1); then
            exit_code=0
        else
            exit_code=1
        fi
    else
        # Normal detection mode
        if result=$(detect_vcs_provider "$REMOTE_NAME" 2>&1); then
            exit_code=0
        else
            exit_code=1
        fi
    fi

    # Format and display output
    case "$OUTPUT_MODE" in
        json)
            echo "$result" | format_json
            ;;
        verbose)
            echo "$result" | format_verbose "$TEST_URL"
            ;;
        human|*)
            echo "$result" | format_human_readable
            ;;
    esac

    return "$exit_code"
}

# Run main function
main "$@"
