#!/usr/bin/env bash
#
# validate-config-security.sh - Secret Detection Pre-commit Hook
#
# Description:
#   Scans configuration files for secrets (API keys, tokens, passwords) to prevent
#   them from being committed to git. Uses multi-tier pattern matching with context
#   awareness to minimize false positives while catching real secrets.
#
# Security Philosophy:
#   - NEVER store secrets in config files or git repositories
#   - API keys/tokens belong in environment variables or secrets managers
#   - Config files should reference env var names, not values
#   - False positives are acceptable; false negatives are NOT
#
# Detection Strategy:
#   - Tier 1: High confidence - Known token formats (ghp_, sk-ant-, lin_api_)
#   - Tier 2: Medium confidence - Context-aware (Jira tokens near "jira" keyword)
#   - Tier 3: Low confidence - Generic patterns (api_key, token fields)
#
# Usage:
#   ./scripts/validate-config-security.sh [OPTIONS] [FILES...]
#
# Options:
#   --verbose       Show detailed scanning information
#   --help          Show this help message
#   --test          Test mode (read from stdin)
#
# Exit Codes:
#   0 - No secrets detected (safe to commit)
#   1 - Secrets detected (block commit)
#   2 - Invalid usage or system error
#
# Part of: AIDA Configuration System (Issue #55)
# Author: oakensoul
# License: AGPL-3.0
# Repository: https://github.com/oakensoul/claude-personal-assistant
#

set -euo pipefail

#######################################
# Constants
#######################################
# shellcheck disable=SC2155
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC2155
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Exit codes
readonly EXIT_SUCCESS=0
readonly EXIT_SECRETS_FOUND=1
readonly EXIT_ERROR=2

# Color codes for output
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly BOLD='\033[1m'
readonly RESET='\033[0m'

#######################################
# Secret Patterns (Tier 1: High Confidence)
#######################################

# GitHub tokens (classic and fine-grained)
readonly GITHUB_CLASSIC_PATTERN='ghp_[A-Za-z0-9]{36}'
readonly GITHUB_PAT_PATTERN='github_pat_[A-Za-z0-9_]{82}'

# Linear API keys
readonly LINEAR_KEY_PATTERN='lin_api_[A-Za-z0-9]{40}'

# Anthropic API keys
readonly ANTHROPIC_KEY_PATTERN='sk-ant-[A-Za-z0-9_-]{95,}'

# AWS Access Keys
readonly AWS_ACCESS_KEY_PATTERN='AKIA[0-9A-Z]{16}'

# Generic high-confidence patterns (base64, long hex strings)
readonly BASE64_SECRET_PATTERN='"(api_key|token|secret)"\s*:\s*"[A-Za-z0-9+/]{40,}={0,2}"'
readonly HEX_SECRET_PATTERN='"(api_key|token|secret)"\s*:\s*"[a-fA-F0-9]{32,}"'

#######################################
# Jira Token Pattern (Tier 2: Context-Aware)
#######################################
# Jira tokens are 24-32 alphanumeric characters
# Only flag if near "jira" keyword to avoid false positives
readonly JIRA_TOKEN_LENGTH_MIN=24
readonly JIRA_TOKEN_LENGTH_MAX=32

#######################################
# Generic Patterns (Tier 3: Low Confidence)
#######################################
# JSON fields with literal values (check for placeholders)
readonly GENERIC_API_KEY_PATTERN='"api_key"\s*:\s*"([^"]+)"'
readonly GENERIC_TOKEN_PATTERN='"token"\s*:\s*"([^"]+)"'
readonly GENERIC_PASSWORD_PATTERN='"password"\s*:\s*"([^"]+)"'
readonly GENERIC_SECRET_PATTERN='"secret"\s*:\s*"([^"]+)"'

#######################################
# Placeholder Patterns (Safe Values)
#######################################
# These are NOT secrets - they're placeholders or examples
readonly PLACEHOLDER_PATTERNS=(
    'YOUR_.*_HERE'
    'EXAMPLE_.*'
    'TEST_.*'
    '\{\{.*\}\}'          # {{API_KEY}}
    '\$\{.*\}'            # ${API_KEY}
    '\$[A-Z_][A-Z0-9_]*'  # $API_KEY (fixed pattern)
    '^example-'
    '^test-'
    '^placeholder-'
    '^changeme'
    '^replace-'
    '^null$'
    '^""$'
)

#######################################
# Global state
#######################################
VERBOSE=false
TEST_MODE=false
SECRETS_FOUND=0
declare -a FINDINGS=()

#######################################
# Print colored message
# Arguments:
#   $1 - Color (RED, YELLOW, GREEN, BLUE)
#   $2 - Message
#######################################
print_color() {
    local color="$1"
    shift
    echo -e "${color}${*}${RESET}"
}

#######################################
# Print verbose message (only if --verbose)
# Arguments:
#   $* - Message
#######################################
print_verbose() {
    if [[ "$VERBOSE" == true ]]; then
        print_color "$BLUE" "  [SCAN] $*"
    fi
}

#######################################
# Check if value is a placeholder
# Arguments:
#   $1 - Value to check
# Returns:
#   0 if placeholder, 1 if not
#######################################
is_placeholder() {
    local value="$1"

    # Empty or null
    if [[ -z "$value" ]] || [[ "$value" == "null" ]]; then
        return 0
    fi

    # Check against placeholder patterns
    # Set LC_ALL=C to avoid locale issues with character ranges
    for pattern in "${PLACEHOLDER_PATTERNS[@]}"; do
        if LC_ALL=C echo "$value" | grep -qiE "$pattern"; then
            return 0
        fi
    done

    return 1
}

#######################################
# Record a secret finding
# Arguments:
#   $1 - File path
#   $2 - Line number
#   $3 - Matched text
#   $4 - Secret type
#   $5 - Confidence (high/medium/low)
#######################################
record_finding() {
    local file="$1"
    local line_num="$2"
    local matched_text="$3"
    local secret_type="$4"
    local confidence="$5"

    FINDINGS+=("$file|$line_num|$matched_text|$secret_type|$confidence")
    SECRETS_FOUND=$((SECRETS_FOUND + 1))
}

#######################################
# Detect GitHub tokens (Tier 1: High Confidence)
# Arguments:
#   $1 - File path
#   $2 - File content
#######################################
detect_github_tokens() {
    local file="$1"
    local content="$2"
    local line_num=0

    print_verbose "Checking for GitHub tokens..."

    while IFS= read -r line; do
        line_num=$((line_num + 1))

        # GitHub classic tokens (ghp_)
        if LC_ALL=C echo "$line" | grep -qE "$GITHUB_CLASSIC_PATTERN"; then
            local matched
            matched=$(LC_ALL=C echo "$line" | grep -oE "$GITHUB_CLASSIC_PATTERN" | head -1)
            record_finding "$file" "$line_num" "$matched" "GitHub Personal Access Token (classic)" "high"
        fi

        # GitHub fine-grained tokens (github_pat_)
        if LC_ALL=C echo "$line" | grep -qE "$GITHUB_PAT_PATTERN"; then
            local matched
            matched=$(LC_ALL=C echo "$line" | grep -oE "$GITHUB_PAT_PATTERN" | head -1)
            record_finding "$file" "$line_num" "$matched" "GitHub Personal Access Token (fine-grained)" "high"
        fi
    done <<< "$content"
}

#######################################
# Detect Linear API keys (Tier 1: High Confidence)
# Arguments:
#   $1 - File path
#   $2 - File content
#######################################
detect_linear_keys() {
    local file="$1"
    local content="$2"
    local line_num=0

    print_verbose "Checking for Linear API keys..."

    while IFS= read -r line; do
        line_num=$((line_num + 1))

        if LC_ALL=C echo "$line" | grep -qE "$LINEAR_KEY_PATTERN"; then
            local matched
            matched=$(LC_ALL=C echo "$line" | grep -oE "$LINEAR_KEY_PATTERN" | head -1)
            record_finding "$file" "$line_num" "$matched" "Linear API Key" "high"
        fi
    done <<< "$content"
}

#######################################
# Detect Anthropic API keys (Tier 1: High Confidence)
# Arguments:
#   $1 - File path
#   $2 - File content
#######################################
detect_anthropic_keys() {
    local file="$1"
    local content="$2"
    local line_num=0

    print_verbose "Checking for Anthropic API keys..."

    while IFS= read -r line; do
        line_num=$((line_num + 1))

        if LC_ALL=C echo "$line" | grep -qE "$ANTHROPIC_KEY_PATTERN"; then
            local matched
            matched=$(LC_ALL=C echo "$line" | grep -oE "$ANTHROPIC_KEY_PATTERN" | head -1)
            record_finding "$file" "$line_num" "$matched" "Anthropic API Key" "high"
        fi
    done <<< "$content"
}

#######################################
# Detect AWS access keys (Tier 1: High Confidence)
# Arguments:
#   $1 - File path
#   $2 - File content
#######################################
detect_aws_keys() {
    local file="$1"
    local content="$2"
    local line_num=0

    print_verbose "Checking for AWS access keys..."

    while IFS= read -r line; do
        line_num=$((line_num + 1))

        if LC_ALL=C echo "$line" | grep -qE "$AWS_ACCESS_KEY_PATTERN"; then
            local matched
            matched=$(LC_ALL=C echo "$line" | grep -oE "$AWS_ACCESS_KEY_PATTERN" | head -1)
            record_finding "$file" "$line_num" "$matched" "AWS Access Key" "high"
        fi
    done <<< "$content"
}

#######################################
# Detect Jira tokens (Tier 2: Context-Aware)
# Arguments:
#   $1 - File path
#   $2 - File content
#######################################
detect_jira_tokens() {
    local file="$1"
    local content="$2"
    local line_num=0

    print_verbose "Checking for Jira tokens (context-aware)..."

    # Read file with context window (3 lines before/after)
    local -a lines
    # Use compatible method for reading lines (works with bash 3.2+)
    while IFS= read -r line; do
        lines+=("$line")
    done <<< "$content"

    for ((i=0; i<${#lines[@]}; i++)); do
        local line="${lines[$i]}"
        line_num=$((i + 1))

        # Extract potential token values from JSON fields
        if LC_ALL=C echo "$line" | grep -qE '"(api_token|token|password)"\s*:\s*"[A-Za-z0-9]+"'; then
            local value
            value=$(echo "$line" | sed -E 's/.*"(api_token|token|password)"\s*:\s*"([^"]+)".*/\2/')

            # Check if it's a placeholder first
            if is_placeholder "$value"; then
                continue
            fi

            # Check token length
            local token_length=${#value}
            if [[ $token_length -ge $JIRA_TOKEN_LENGTH_MIN ]] && [[ $token_length -le $JIRA_TOKEN_LENGTH_MAX ]]; then
                # Check context: is "jira" mentioned nearby?
                local context_found=false
                local context_start=$((i - 3))
                local context_end=$((i + 3))
                [[ $context_start -lt 0 ]] && context_start=0
                [[ $context_end -ge ${#lines[@]} ]] && context_end=$((${#lines[@]} - 1))

                for ((j=context_start; j<=context_end; j++)); do
                    if LC_ALL=C echo "${lines[$j]}" | grep -qiE '(jira|atlassian)'; then
                        context_found=true
                        break
                    fi
                done

                if [[ "$context_found" == true ]]; then
                    record_finding "$file" "$line_num" "$value" "Jira API Token (context-detected)" "medium"
                fi
            fi
        fi
    done
}

#######################################
# Detect generic secrets (Tier 3: Low Confidence)
# Arguments:
#   $1 - File path
#   $2 - File content
#######################################
detect_generic_secrets() {
    local file="$1"
    local content="$2"
    local line_num=0

    print_verbose "Checking for generic secret patterns..."

    while IFS= read -r line; do
        line_num=$((line_num + 1))

        # Check each generic pattern
        for pattern in "$GENERIC_API_KEY_PATTERN" "$GENERIC_TOKEN_PATTERN" "$GENERIC_PASSWORD_PATTERN" "$GENERIC_SECRET_PATTERN"; do
            if LC_ALL=C echo "$line" | grep -qE "$pattern"; then
                # Extract the value
                local value
                value=$(echo "$line" | sed -E 's/.*"(api_key|token|password|secret)"\s*:\s*"([^"]+)".*/\2/')

                # Skip placeholders
                if is_placeholder "$value"; then
                    continue
                fi

                # Skip very short values (likely not real secrets)
                if [[ ${#value} -lt 8 ]]; then
                    continue
                fi

                # Extract field name
                local field_name
                field_name=$(echo "$line" | sed -E 's/.*"(api_key|token|password|secret)".*/\1/')

                record_finding "$file" "$line_num" "$value" "Generic ${field_name} value" "low"
            fi
        done

        # Check for base64-encoded secrets
        if LC_ALL=C echo "$line" | grep -qE "$BASE64_SECRET_PATTERN"; then
            local value
            value=$(echo "$line" | sed -E 's/.*"(api_key|token|secret)"\s*:\s*"([^"]+)".*/\2/')
            if ! is_placeholder "$value"; then
                record_finding "$file" "$line_num" "$value" "Base64-encoded secret" "medium"
            fi
        fi

        # Check for long hex strings (likely keys)
        if LC_ALL=C echo "$line" | grep -qE "$HEX_SECRET_PATTERN"; then
            local value
            value=$(echo "$line" | sed -E 's/.*"(api_key|token|secret)"\s*:\s*"([^"]+)".*/\2/')
            if ! is_placeholder "$value"; then
                record_finding "$file" "$line_num" "$value" "Hexadecimal secret" "medium"
            fi
        fi
    done <<< "$content"
}

#######################################
# Scan a single file for secrets
# Arguments:
#   $1 - File path
# Returns:
#   Number of secrets found
#######################################
scan_file() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        print_color "$YELLOW" "Warning: File not found: $file"
        return 0
    fi

    print_verbose "Scanning file: $file"

    # Read file content
    local content
    content=$(cat "$file")

    # Run all detection functions
    detect_github_tokens "$file" "$content"
    detect_linear_keys "$file" "$content"
    detect_anthropic_keys "$file" "$content"
    detect_aws_keys "$file" "$content"
    detect_jira_tokens "$file" "$content"
    detect_generic_secrets "$file" "$content"

    return 0
}

#######################################
# Get secret type display name and color
# Arguments:
#   $1 - Confidence level (high/medium/low)
# Outputs:
#   Color code
#######################################
get_confidence_color() {
    local confidence="$1"
    case "$confidence" in
        high)
            echo "$RED"
            ;;
        medium)
            echo "$YELLOW"
            ;;
        low)
            echo "$BLUE"
            ;;
        *)
            echo "$RESET"
            ;;
    esac
}

#######################################
# Show remediation help
#######################################
show_remediation_help() {
    echo ""
    print_color "$RED" "${BOLD}SECURITY RISK:${RESET}"
    echo "Committing secrets to git exposes them in version history and makes"
    echo "them accessible to anyone with repository access."
    echo ""
    print_color "$YELLOW" "${BOLD}HOW TO FIX:${RESET}"
    echo "1. Remove the secret from the config file"
    echo "2. Store the secret in an environment variable instead:"
    print_color "$GREEN" '   export GITHUB_TOKEN="ghp_1234567890abcdef1234567890abcdef123456"'
    echo ""
    echo "3. Reference the environment variable in your config:"
    # shellcheck disable=SC2016
    print_color "$GREEN" '   "api_key": "${GITHUB_TOKEN}"'
    echo ""
    echo "4. Add the secret to your shell profile (~/.bashrc, ~/.zshrc)"
    echo "   OR use a secrets manager (1Password, AWS Secrets Manager, etc.)"
    echo ""
    print_color "$YELLOW" "${BOLD}REMEDIATION (if already committed):${RESET}"
    echo "1. Revoke the exposed credentials immediately"
    echo "2. Generate new credentials"
    echo "3. Remove from git history: git filter-branch or BFG Repo-Cleaner"
    echo "4. Force push to rewrite history (coordinate with team)"
    echo ""
    print_color "$BLUE" "See: docs/configuration/security-model.md (when available)"
    echo ""
    print_color "$YELLOW" "To bypass this check (NOT recommended):"
    print_color "$YELLOW" "  git commit --no-verify"
    echo ""
}

#######################################
# Display findings report
#######################################
show_findings() {
    if [[ ${#FINDINGS[@]} -eq 0 ]]; then
        return
    fi

    echo ""
    print_color "$RED" "${BOLD}═══════════════════════════════════════════════════════════════${RESET}"
    print_color "$RED" "${BOLD}  SECRETS DETECTED - COMMIT BLOCKED${RESET}"
    print_color "$RED" "${BOLD}═══════════════════════════════════════════════════════════════${RESET}"
    echo ""

    # Group findings by file
    local current_file=""
    local finding_num=0

    for finding in "${FINDINGS[@]}"; do
        IFS='|' read -r file line_num matched_text secret_type confidence <<< "$finding"
        finding_num=$((finding_num + 1))

        # Print file header if new file
        if [[ "$file" != "$current_file" ]]; then
            current_file="$file"
            echo ""
            print_color "$BOLD" "Found in: $file"
            echo ""
        fi

        # Get color for confidence level
        local color
        color=$(get_confidence_color "$confidence")

        # Print finding
        print_color "$color" "  Line $line_num: $secret_type [$confidence confidence]"
        print_color "$YELLOW" "    Value: $matched_text"

        # Add specific remediation for known types
        case "$secret_type" in
            *"GitHub"*)
                echo "    Env var: export GITHUB_TOKEN=\"...\""
                echo "    Config:  \"api_key\": \"\${GITHUB_TOKEN}\""
                ;;
            *"Linear"*)
                echo "    Env var: export LINEAR_API_KEY=\"...\""
                echo "    Config:  \"api_key\": \"\${LINEAR_API_KEY}\""
                ;;
            *"Anthropic"*)
                echo "    Env var: export ANTHROPIC_API_KEY=\"...\""
                echo "    Config:  \"api_key\": \"\${ANTHROPIC_API_KEY}\""
                ;;
            *"Jira"*)
                echo "    Env var: export JIRA_API_TOKEN=\"...\""
                echo "    Config:  \"api_token\": \"\${JIRA_API_TOKEN}\""
                ;;
            *"AWS"*)
                echo "    Env var: export AWS_ACCESS_KEY_ID=\"...\""
                echo "    Config:  Use AWS credentials file or IAM roles"
                ;;
            *)
                # Generic fallback - no specific remediation
                ;;
        esac
        echo ""
    done

    print_color "$RED" "${BOLD}═══════════════════════════════════════════════════════════════${RESET}"
    print_color "$RED" "${BOLD}  Total: $SECRETS_FOUND secret(s) detected${RESET}"
    print_color "$RED" "${BOLD}═══════════════════════════════════════════════════════════════${RESET}"

    show_remediation_help
}

#######################################
# Show usage information
#######################################
show_usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] [FILES...]

Scans configuration files for secrets (API keys, tokens, passwords) to prevent
them from being committed to git.

OPTIONS:
  --verbose       Show detailed scanning information
  --help          Show this help message
  --test          Test mode (read from stdin)

ARGUMENTS:
  FILES           Specific files to scan (default: scan staged config files)

EXAMPLES:
  # Scan all staged config files (pre-commit mode)
  $(basename "$0")

  # Scan specific file
  $(basename "$0") ~/.claude/config.json

  # Scan with verbose output
  $(basename "$0") --verbose .aida/config.json

  # Test with sample content
  echo '{"api_key": "ghp_test123"}' | $(basename "$0") --test

EXIT CODES:
  0 - No secrets detected (safe to commit)
  1 - Secrets detected (block commit)
  2 - Invalid usage or system error

SECURITY:
  This script detects common secret patterns:
  - GitHub tokens (ghp_, github_pat_)
  - Linear API keys (lin_api_)
  - Anthropic API keys (sk-ant-)
  - AWS access keys (AKIA...)
  - Jira tokens (context-aware)
  - Generic api_key/token/password/secret fields

  Placeholders and environment variable references are ignored:
  - "{{API_KEY}}", "\${API_KEY}", "\$API_KEY"
  - "YOUR_KEY_HERE", "EXAMPLE_TOKEN", "test-key"

For more information, see:
  - docs/configuration/security-model.md (when available)
  - Issue #55: Configuration System

EOF
}

#######################################
# Main function
#######################################
main() {
    local files_to_scan=()

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --verbose)
                VERBOSE=true
                shift
                ;;
            --test)
                TEST_MODE=true
                shift
                ;;
            --help|-h)
                show_usage
                exit "$EXIT_SUCCESS"
                ;;
            -*)
                echo "Error: Unknown option: $1" >&2
                echo "Use --help for usage information" >&2
                exit "$EXIT_ERROR"
                ;;
            *)
                files_to_scan+=("$1")
                shift
                ;;
        esac
    done

    # Test mode: read from stdin
    if [[ "$TEST_MODE" == true ]]; then
        local test_content
        test_content=$(cat)
        local test_file="/dev/stdin"

        detect_github_tokens "$test_file" "$test_content"
        detect_linear_keys "$test_file" "$test_content"
        detect_anthropic_keys "$test_file" "$test_content"
        detect_aws_keys "$test_file" "$test_content"
        detect_jira_tokens "$test_file" "$test_content"
        detect_generic_secrets "$test_file" "$test_content"

        show_findings

        if [[ $SECRETS_FOUND -gt 0 ]]; then
            exit "$EXIT_SECRETS_FOUND"
        else
            print_color "$GREEN" "✓ No secrets detected"
            exit "$EXIT_SUCCESS"
        fi
    fi

    # If no files specified, scan staged config files
    if [[ ${#files_to_scan[@]} -eq 0 ]]; then
        # Check if we're in a git repository
        if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
            echo "Error: Not in a git repository and no files specified" >&2
            echo "Use --help for usage information" >&2
            exit "$EXIT_ERROR"
        fi

        # Get staged files matching config patterns
        while IFS= read -r file; do
            if [[ -n "$file" ]]; then
                files_to_scan+=("$file")
            fi
        done < <(git diff --cached --name-only --diff-filter=ACM | grep -E '(config\.(json|ya?ml)|\.claude/|\.aida/)' || true)

        if [[ ${#files_to_scan[@]} -eq 0 ]]; then
            print_verbose "No config files staged for commit"
            exit "$EXIT_SUCCESS"
        fi
    fi

    # Scan files
    print_verbose "Scanning ${#files_to_scan[@]} file(s) for secrets..."

    for file in "${files_to_scan[@]}"; do
        scan_file "$file"
    done

    # Show results
    if [[ $SECRETS_FOUND -gt 0 ]]; then
        show_findings
        exit "$EXIT_SECRETS_FOUND"
    else
        if [[ "$VERBOSE" == true ]]; then
            print_color "$GREEN" "✓ No secrets detected in ${#files_to_scan[@]} file(s)"
        fi
        exit "$EXIT_SUCCESS"
    fi
}

# Run main function
main "$@"
