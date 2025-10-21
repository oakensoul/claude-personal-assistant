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
        "${HOME}/.claude/config.json"
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
            config_version: "2.0",
            system: {
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
            vcs: {
                provider: "",
                owner: "",
                repo: "",
                main_branch: "main",
                auto_detect: true
            },
            work_tracker: {
                provider: "",
                auto_detect: true
            },
            team: {
                review_strategy: "list",
                default_reviewers: [],
                members: [],
                timezone: "UTC"
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
# Get user AIDA config (~/.claude/config.json or ~/.claude/aida-config.json)
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
    # Check new location first, fallback to old location
    local config_file="${HOME}/.claude/config.json"
    if [[ ! -f "$config_file" ]]; then
        config_file="${HOME}/.claude/aida-config.json"
    fi
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
# Check if user config needs migration and run if needed
# Globals:
#   HOME
#   INSTALLER_COMMON
# Arguments:
#   None
# Returns:
#   0 on success or no migration needed, 1 on migration failure
#######################################
check_and_migrate_config() {
    local user_config="${HOME}/.claude/config.json"

    # Check if old config exists (aida-config.json)
    if [[ ! -f "$user_config" ]] && [[ -f "${HOME}/.claude/aida-config.json" ]]; then
        user_config="${HOME}/.claude/aida-config.json"
    fi

    # Skip if no config file exists
    if [[ ! -f "$user_config" ]]; then
        return 0
    fi

    # Skip if migration script not available
    if [[ ! -f "${INSTALLER_COMMON}/config-migration.sh" ]]; then
        return 0
    fi

    # Check if migration needed
    # shellcheck source=lib/installer-common/config-migration.sh
    source "${INSTALLER_COMMON}/config-migration.sh"

    if needs_migration "$user_config" 2>/dev/null; then
        log_to_file "INFO" "Auto-migrating config: $user_config"

        # Run migration (suppress output to avoid polluting config output)
        if ! migrate_config "$user_config" "false" >/dev/null 2>&1; then
            log_to_file "ERROR" "Config migration failed: $user_config"
            return 1
        fi

        log_to_file "SUCCESS" "Config migration completed: $user_config"
    fi

    return 0
}

#######################################
# Apply VCS auto-detection if needed
# Arguments:
#   $1 - Merged config (JSON)
# Returns:
#   0 on success
# Outputs:
#   Updated config with VCS auto-detection results
#######################################
apply_vcs_autodetection() {
    local config="$1"

    # Check if auto-detection enabled and provider empty
    local auto_detect
    auto_detect=$(echo "$config" | jq -r '.vcs.auto_detect // true')

    local provider
    provider=$(echo "$config" | jq -r '.vcs.provider // ""')

    # Skip if auto-detection disabled or provider already set (non-empty)
    if [[ "$auto_detect" != "true" ]]; then
        echo "$config"
        return 0
    fi

    # Skip if provider is already set to a non-empty value
    if [[ -n "$provider" ]]; then
        echo "$config"
        return 0
    fi

    # Skip if VCS detector not available
    if [[ ! -f "${INSTALLER_COMMON}/vcs-detector.sh" ]]; then
        echo "$config"
        return 0
    fi

    # Run VCS detection
    local detected_info
    detected_info=$(bash "${INSTALLER_COMMON}/vcs-detector.sh" 2>/dev/null || echo "{}")

    # Check if detection succeeded
    local detected_provider
    detected_provider=$(echo "$detected_info" | jq -r '.provider // empty')

    if [[ -z "$detected_provider" ]] || [[ "$detected_provider" == "unknown" ]]; then
        # No detection results, return original config
        echo "$config"
        return 0
    fi

    # Merge detected values into config (only if not already set)
    # Use conditional checks because jq's // operator doesn't treat "" as null/false
    local updated_config
    updated_config=$(jq -n \
        --argjson base "$config" \
        --argjson detected "$detected_info" \
        '
        $base |
        .vcs.provider = (if ($base.vcs.provider == "" or $base.vcs.provider == null) then $detected.provider else $base.vcs.provider end) |
        .vcs.owner = (if ($base.vcs.owner == "" or $base.vcs.owner == null) then $detected.owner else $base.vcs.owner end) |
        .vcs.repo = (if ($base.vcs.repo == "" or $base.vcs.repo == null) then $detected.repo else $base.vcs.repo end) |
        if $detected.domain and $detected.provider then
            .vcs[$detected.provider] = (.vcs[$detected.provider] // {}) |
            .vcs[$detected.provider].enterprise_url = (
                if ($base.vcs[$detected.provider].enterprise_url == null or $base.vcs[$detected.provider].enterprise_url == "") then
                    if $detected.domain != ($detected.provider + ".com") then
                        "https://" + $detected.domain
                    else
                        null
                    end
                else
                    $base.vcs[$detected.provider].enterprise_url
                end
            )
        else . end
        ')

    echo "$updated_config"
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
    # Check for migration before caching
    check_and_migrate_config || {
        log_to_file "WARNING" "Config migration check failed, continuing with existing config"
    }

    if is_cache_valid; then
        # Fast path: return cached result
        cat "$CACHE_FILE"
    else
        # Slow path: merge configs and cache result
        local merged_config
        merged_config=$(merge_configs)

        # Apply VCS auto-detection if needed
        merged_config=$(apply_vcs_autodetection "$merged_config")

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
# Validate config using 3-tier validation framework
# Globals:
#   INSTALLER_COMMON
#   HOME
# Arguments:
#   $1 - Validation tier (optional: structure, provider, connectivity, all)
#        Defaults to "structure" for compatibility
# Returns:
#   0 if validation passes, 1 otherwise
# shellcheck disable=SC2120
#######################################
validate_config() {
    local tier="${1:-structure}"

    # Check if we have a user config file to validate
    local user_config="${HOME}/.claude/config.json"
    if [[ ! -f "$user_config" ]]; then
        user_config="${HOME}/.claude/aida-config.json"
    fi

    if [[ ! -f "$user_config" ]]; then
        # No user config exists - validate against minimal requirements
        print_message "info" "No user config found - validating system defaults..."

        local merged_config
        merged_config=$(get_merged_config)

        # Check minimal required paths exist
        local required_keys=(
            "paths.aida_home"
            "paths.claude_config_dir"
            "paths.home"
        )

        local errors=0

        for key in "${required_keys[@]}"; do
            local value
            value=$(echo "$merged_config" | jq -r ".$key" 2>/dev/null || echo "null")

            if [[ "$value" == "null" ]] || [[ -z "$value" ]]; then
                print_message "error" "Required config key missing or empty: $key"
                errors=$((errors + 1))
            fi
        done

        if [[ $errors -gt 0 ]]; then
            print_message "error" "Configuration validation failed ($errors errors)"
            return 1
        fi

        print_message "success" "Configuration validation passed (system defaults)"
        return 0
    fi

    # Use 3-tier validation framework if available
    if [[ -f "${INSTALLER_COMMON}/config-validator.sh" ]]; then
        print_message "info" "Running ${tier} validation on: $user_config"

        if bash "${INSTALLER_COMMON}/config-validator.sh" --tier "$tier" "$user_config"; then
            print_message "success" "Configuration validation passed (${tier})"
            return 0
        else
            print_message "error" "Configuration validation failed (${tier})"
            return 1
        fi
    else
        # Fallback to basic validation
        print_message "warning" "Validation framework not found, using basic validation"

        local merged_config
        merged_config=$(get_merged_config)

        local required_keys=(
            "paths.aida_home"
            "paths.claude_config_dir"
        )

        local errors=0

        for key in "${required_keys[@]}"; do
            local value
            value=$(echo "$merged_config" | jq -r ".$key" 2>/dev/null || echo "null")

            if [[ "$value" == "null" ]] || [[ -z "$value" ]]; then
                print_message "error" "Required config key missing or empty: $key"
                errors=$((errors + 1))
            fi
        done

        if [[ $errors -gt 0 ]]; then
            print_message "error" "Configuration validation failed ($errors errors)"
            return 1
        fi

        print_message "success" "Configuration validation passed (basic)"
        return 0
    fi
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
