#!/usr/bin/env bash
#
# aida-config-helper.sh - Universal Config Aggregator
#
# Description:
#   Standalone executable that merges 7 configuration sources with session
#   caching and checksum-based invalidation. Eliminates need for variable
#   substitution in templates by providing runtime configuration resolution.
#
# Usage:
#   aida-config-helper.sh                         # Full merged config (JSON)
#   aida-config-helper.sh --key paths.aida_home   # Specific value
#   aida-config-helper.sh --namespace github      # All github.* config
#   aida-config-helper.sh --format yaml           # YAML output (future)
#   aida-config-helper.sh --validate              # Validate required keys
#   aida-config-helper.sh --clear-cache           # Clear session cache
#
# Dependencies:
#   - jq (required)
#   - installer-common/logging.sh
#   - installer-common/validation.sh
#
# Architecture:
#   This is the keystone of the modular installer refactoring. It provides
#   single source of truth for all configuration across AIDA system.
#
# Part of: AIDA installer-common library v1.0
# Author: oakensoul
# License: AGPL-3.0
# Repository: https://github.com/oakensoul/claude-personal-assistant
#

set -euo pipefail

# Script directory detection
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly INSTALLER_COMMON="${SCRIPT_DIR}/installer-common"

# Source dependencies
# shellcheck source=lib/installer-common/colors.sh
source "${INSTALLER_COMMON}/colors.sh"
# shellcheck source=lib/installer-common/logging.sh
source "${INSTALLER_COMMON}/logging.sh"
# shellcheck source=lib/installer-common/validation.sh
source "${INSTALLER_COMMON}/validation.sh"

# Session-based cache files (PID-scoped)
readonly CACHE_FILE="/tmp/aida-config-cache-$$"
readonly CHECKSUM_FILE="/tmp/aida-config-checksum-$$"

# Cleanup on exit
trap 'rm -f "$CACHE_FILE" "$CHECKSUM_FILE"' EXIT INT TERM

#######################################
# Check if jq is available (required dependency)
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   0 if jq available, exits with error if not
#######################################
check_jq_dependency() {
    if ! command -v jq >/dev/null 2>&1; then
        print_message "error" "Required dependency 'jq' not found"
        print_message "info" "Install jq:"
        print_message "info" "  macOS: brew install jq"
        print_message "info" "  Linux: sudo apt-get install jq"
        exit 1
    fi
}

#######################################
# Get file modification time checksum (cross-platform)
# Arguments:
#   $1 - File path
# Returns:
#   0 on success, 1 on failure
# Outputs:
#   Checksum string to stdout
#######################################
get_file_checksum() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        echo "0"
        return 0
    fi

    # Platform-specific stat command
    local mtime
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS (BSD stat)
        mtime=$(stat -f "%m" "$file" 2>/dev/null || echo "0")
    else
        # Linux (GNU stat)
        mtime=$(stat -c "%Y" "$file" 2>/dev/null || echo "0")
    fi

    # Use md5 for checksum (cross-platform)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo -n "$mtime" | md5 -q 2>/dev/null || echo "0"
    else
        echo -n "$mtime" | md5sum 2>/dev/null | cut -d' ' -f1 || echo "0"
    fi
}

#######################################
# Calculate combined checksum of all config sources
# Globals:
#   HOME
# Arguments:
#   None
# Returns:
#   0 on success
# Outputs:
#   Combined checksum to stdout
#######################################
get_config_checksum() {
    local checksum=""

    # Config file locations (in priority order, lowest to highest)
    local config_files=(
        "${HOME}/.claude/aida-config.json"
        "${HOME}/.gitconfig"
        ".git/config"
        ".github/GITHUB_CONFIG.json"
        ".github/workflow-config.json"
        ".aida/config.json"
    )

    # Accumulate checksums
    for file in "${config_files[@]}"; do
        checksum+=$(get_file_checksum "$file")
    done

    # Environment variables that affect config
    checksum+="${GITHUB_TOKEN:-}"
    checksum+="${EDITOR:-}"
    checksum+="${AIDA_HOME:-}"
    checksum+="${CLAUDE_CONFIG_DIR:-}"

    # Hash the combined checksum
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo -n "$checksum" | md5 -q 2>/dev/null || echo "0"
    else
        echo -n "$checksum" | md5sum 2>/dev/null | cut -d' ' -f1 || echo "0"
    fi
}

#######################################
# Check if cache is valid
# Globals:
#   CACHE_FILE
#   CHECKSUM_FILE
# Arguments:
#   None
# Returns:
#   0 if cache valid, 1 if invalid or missing
#######################################
is_cache_valid() {
    if [[ ! -f "$CACHE_FILE" ]]; then
        return 1
    fi

    if [[ ! -f "$CHECKSUM_FILE" ]]; then
        return 1
    fi

    local cached_checksum
    cached_checksum=$(cat "$CHECKSUM_FILE" 2>/dev/null || echo "")

    local current_checksum
    current_checksum=$(get_config_checksum)

    [[ "$cached_checksum" == "$current_checksum" ]]
}

#######################################
# Get system defaults configuration
# Globals:
#   HOME
# Arguments:
#   None
# Returns:
#   0 on success
# Outputs:
#   JSON configuration to stdout
#######################################
get_system_defaults() {
    # Detect AIDA_HOME (try multiple locations)
    local aida_home="${AIDA_HOME:-}"
    if [[ -z "$aida_home" ]]; then
        if [[ -d "${HOME}/.aida" ]]; then
            aida_home="${HOME}/.aida"
        elif [[ -d "${HOME}/aida" ]]; then
            aida_home="${HOME}/aida"
        else
            aida_home="${HOME}/.aida"  # Default even if doesn't exist
        fi
    fi

    # Detect CLAUDE_CONFIG_DIR
    local claude_config_dir="${CLAUDE_CONFIG_DIR:-${HOME}/.claude}"

    # Detect project root (git root or current directory)
    local project_root
    project_root=$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")

    # Detect git root
    local git_root
    git_root=$(git rev-parse --show-toplevel 2>/dev/null || echo "")

    jq -n \
        --arg aida_home "$aida_home" \
        --arg claude_config_dir "$claude_config_dir" \
        --arg project_root "$project_root" \
        --arg git_root "$git_root" \
        --arg home "$HOME" \
        '{
            system: {
                config_version: "1.0",
                cache_enabled: true
            },
            paths: {
                aida_home: $aida_home,
                claude_config_dir: $claude_config_dir,
                project_root: $project_root,
                git_root: $git_root,
                home: $home
            },
            user: {
                assistant_name: "aida",
                personality: "default"
            },
            git: {
                user: {
                    name: "",
                    email: ""
                }
            },
            github: {
                owner: "",
                repo: "",
                main_branch: "main"
            },
            workflow: {
                commit: {
                    auto_commit: true
                },
                pr: {
                    auto_version_bump: true,
                    update_changelog: true
                },
                versioning: {
                    enabled: true
                }
            },
            env: {
                github_token: "",
                editor: ""
            }
        }'
}

#######################################
# Read and parse JSON config file
# Arguments:
#   $1 - File path
# Returns:
#   0 on success, 1 if file doesn't exist or invalid JSON
# Outputs:
#   JSON content to stdout, or empty object on error
#######################################
read_json_config() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        echo "{}"
        return 0
    fi

    # Try to parse JSON, return empty object on error
    if ! jq '.' "$file" 2>/dev/null; then
        log_to_file "WARNING" "Invalid JSON in config file: $file"
        echo "{}"
    fi
}

#######################################
# Get user AIDA config (~/.claude/aida-config.json)
# Globals:
#   HOME
# Arguments:
#   None
# Returns:
#   0 on success
# Outputs:
#   JSON configuration to stdout
#######################################
get_user_config() {
    local config_file="${HOME}/.claude/aida-config.json"
    read_json_config "$config_file"
}

#######################################
# Get git configuration
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   0 on success
# Outputs:
#   JSON configuration to stdout
#######################################
get_git_config() {
    local git_user_name
    git_user_name=$(git config user.name 2>/dev/null || echo "")

    local git_user_email
    git_user_email=$(git config user.email 2>/dev/null || echo "")

    jq -n \
        --arg name "$git_user_name" \
        --arg email "$git_user_email" \
        '{
            git: {
                user: {
                    name: $name,
                    email: $email
                }
            }
        }'
}

#######################################
# Get GitHub config (.github/GITHUB_CONFIG.json)
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   0 on success
# Outputs:
#   JSON configuration to stdout
#######################################
get_github_config() {
    local config_file=".github/GITHUB_CONFIG.json"
    read_json_config "$config_file"
}

#######################################
# Get workflow config (.github/workflow-config.json)
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   0 on success
# Outputs:
#   JSON configuration to stdout
#######################################
get_workflow_config() {
    local config_file=".github/workflow-config.json"
    read_json_config "$config_file"
}

#######################################
# Get project AIDA config (.aida/config.json)
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   0 on success
# Outputs:
#   JSON configuration to stdout
#######################################
get_project_config() {
    local config_file=".aida/config.json"
    read_json_config "$config_file"
}

#######################################
# Get environment variable config
# Globals:
#   GITHUB_TOKEN
#   EDITOR
# Arguments:
#   None
# Returns:
#   0 on success
# Outputs:
#   JSON configuration to stdout
#######################################
get_env_config() {
    local github_token="${GITHUB_TOKEN:-}"
    local editor="${EDITOR:-}"

    jq -n \
        --arg token "$github_token" \
        --arg editor "$editor" \
        '{
            env: {
                github_token: $token,
                editor: $editor
            }
        }'
}

#######################################
# Merge all configuration sources
# Priority order (highest to lowest):
#   1. Environment variables
#   2. Project AIDA config (.aida/config.json)
#   3. Workflow config (.github/workflow-config.json)
#   4. GitHub config (.github/GITHUB_CONFIG.json)
#   5. Git config (~/.gitconfig, .git/config)
#   6. User AIDA config (~/.claude/aida-config.json)
#   7. System defaults
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   0 on success
# Outputs:
#   Merged JSON configuration to stdout
#######################################
merge_configs() {
    local system_defaults
    system_defaults=$(get_system_defaults)

    local user_config
    user_config=$(get_user_config)

    local git_config
    git_config=$(get_git_config)

    local github_config
    github_config=$(get_github_config)

    local workflow_config
    workflow_config=$(get_workflow_config)

    local project_config
    project_config=$(get_project_config)

    local env_config
    env_config=$(get_env_config)

    # Deep merge with jq (later configs override earlier ones)
    jq -n \
        --argjson sys "$system_defaults" \
        --argjson user "$user_config" \
        --argjson git "$git_config" \
        --argjson github "$github_config" \
        --argjson workflow "$workflow_config" \
        --argjson project "$project_config" \
        --argjson env "$env_config" \
        '$sys * $user * $git * $github * $workflow * $project * $env'
}

#######################################
# Get merged config with caching
# Globals:
#   CACHE_FILE
#   CHECKSUM_FILE
# Arguments:
#   None
# Returns:
#   0 on success
# Outputs:
#   Merged JSON configuration to stdout
#######################################
get_merged_config() {
    if is_cache_valid; then
        # Fast path: return cached result
        cat "$CACHE_FILE"
    else
        # Slow path: merge configs and cache result
        local merged_config
        merged_config=$(merge_configs)

        # Cache the result
        echo "$merged_config" > "$CACHE_FILE"
        get_config_checksum > "$CHECKSUM_FILE"

        echo "$merged_config"
    fi
}

#######################################
# Get specific config value by key path
# Arguments:
#   $1 - Key path (e.g., "paths.aida_home")
# Returns:
#   0 on success, 1 if key not found
# Outputs:
#   Value to stdout
#######################################
get_config_value() {
    local key="$1"
    local merged_config
    merged_config=$(get_merged_config)

    # Use jq to extract value
    local value
    value=$(echo "$merged_config" | jq -r ".$key" 2>/dev/null || echo "null")

    if [[ "$value" == "null" ]]; then
        print_message "error" "Config key not found: $key"
        return 1
    fi

    echo "$value"
}

#######################################
# Get config namespace (e.g., all "github.*" config)
# Arguments:
#   $1 - Namespace (e.g., "github")
# Returns:
#   0 on success, 1 if namespace not found
# Outputs:
#   JSON object to stdout
#######################################
get_config_namespace() {
    local namespace="$1"
    local merged_config
    merged_config=$(get_merged_config)

    # Use jq to extract namespace
    local ns_config
    ns_config=$(echo "$merged_config" | jq ".$namespace" 2>/dev/null || echo "null")

    if [[ "$ns_config" == "null" ]]; then
        print_message "error" "Config namespace not found: $namespace"
        return 1
    fi

    echo "$ns_config"
}

#######################################
# Validate config has required keys
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   0 if all required keys exist, 1 otherwise
#######################################
validate_config() {
    local required_keys=(
        "paths.aida_home"
        "paths.claude_config_dir"
        "paths.home"
    )

    local merged_config
    merged_config=$(get_merged_config)

    local errors=0

    print_message "info" "Validating configuration..."

    for key in "${required_keys[@]}"; do
        local value
        value=$(echo "$merged_config" | jq -r ".$key" 2>/dev/null || echo "null")

        if [[ "$value" == "null" ]] || [[ -z "$value" ]]; then
            print_message "error" "Required config key missing or empty: $key"
            errors=$((errors + 1))
        else
            print_message "success" "  $key: $value"
        fi
    done

    if [[ $errors -gt 0 ]]; then
        print_message "error" "Configuration validation failed ($errors errors)"
        return 1
    fi

    print_message "success" "Configuration validation passed"
    return 0
}

#######################################
# Clear session cache
# Globals:
#   CACHE_FILE
#   CHECKSUM_FILE
# Arguments:
#   None
# Returns:
#   0 on success
#######################################
clear_cache() {
    rm -f "$CACHE_FILE" "$CHECKSUM_FILE"
    print_message "success" "Cache cleared"
}

#######################################
# Show usage information
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   0
#######################################
show_usage() {
    cat <<EOF
AIDA Config Helper - Universal Configuration Aggregator

Usage:
  aida-config-helper.sh [OPTIONS]

Options:
  (no args)                      Output full merged config as JSON
  --key <key-path>               Output specific config value
                                 Example: --key paths.aida_home
  --namespace <namespace>        Output all config in namespace
                                 Example: --namespace github
  --validate                     Validate required config keys exist
  --clear-cache                  Clear session cache
  --help                         Show this help message

Examples:
  # Get full config
  aida-config-helper.sh

  # Get specific value
  aida-config-helper.sh --key paths.aida_home

  # Get all GitHub config
  aida-config-helper.sh --namespace github

  # Validate config
  aida-config-helper.sh --validate

Configuration Priority (highest to lowest):
  1. Environment variables (GITHUB_TOKEN, EDITOR, etc.)
  2. Project AIDA config (.aida/config.json)
  3. Workflow config (.github/workflow-config.json)
  4. GitHub config (.github/GITHUB_CONFIG.json)
  5. Git config (~/.gitconfig, .git/config)
  6. User AIDA config (~/.claude/aida-config.json)
  7. System defaults (built-in)

Caching:
  - Session-based caching (PID-scoped)
  - Automatic invalidation when config files change
  - Clear manually with --clear-cache

For more information, see:
  lib/installer-common/README-config-aggregator.md
EOF
}

#######################################
# Main entry point
# Globals:
#   None
# Arguments:
#   $@ - Command-line arguments
# Returns:
#   0 on success, 1 on error
#######################################
main() {
    # Check jq dependency
    check_jq_dependency

    # Parse command-line arguments
    local action="full"
    local key=""
    local namespace=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --key)
                action="key"
                key="${2:-}"
                if [[ -z "$key" ]]; then
                    print_message "error" "--key requires an argument"
                    show_usage
                    exit 1
                fi
                shift 2
                ;;
            --namespace)
                action="namespace"
                namespace="${2:-}"
                if [[ -z "$namespace" ]]; then
                    print_message "error" "--namespace requires an argument"
                    show_usage
                    exit 1
                fi
                shift 2
                ;;
            --validate)
                action="validate"
                shift
                ;;
            --clear-cache)
                action="clear-cache"
                shift
                ;;
            --help)
                show_usage
                exit 0
                ;;
            *)
                print_message "error" "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done

    # Execute action
    case "$action" in
        full)
            get_merged_config
            ;;
        key)
            get_config_value "$key"
            ;;
        namespace)
            get_config_namespace "$namespace"
            ;;
        validate)
            validate_config
            ;;
        clear-cache)
            clear_cache
            ;;
        *)
            print_message "error" "Unknown action: $action"
            exit 1
            ;;
    esac
}

# Run main if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
