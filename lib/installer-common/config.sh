#!/usr/bin/env bash
#
# config.sh - Config Wrapper Module
#
# Description:
#   Thin wrapper around aida-config-helper.sh for convenient use by install.sh.
#   Provides simple API for reading merged config, getting values, creating
#   user config, and validating configuration.
#
# Dependencies:
#   - ../aida-config-helper.sh (required)
#   - logging.sh (must be sourced first)
#   - validation.sh (must be sourced first)
#   - jq (required)
#
# Part of: AIDA installer-common library v1.0
# Usage:
#   source "${INSTALLER_COMMON}/colors.sh"
#   source "${INSTALLER_COMMON}/logging.sh"
#   source "${INSTALLER_COMMON}/validation.sh"
#   source "${INSTALLER_COMMON}/config.sh"
#
# Author: oakensoul
# License: AGPL-3.0
# Repository: https://github.com/oakensoul/claude-personal-assistant
#

set -euo pipefail

# Get script directory and locate config helper (if not already set)
if [[ -z "${SCRIPT_DIR:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
    readonly SCRIPT_DIR
fi
if [[ -z "${CONFIG_HELPER:-}" ]]; then
    readonly CONFIG_HELPER="${SCRIPT_DIR}/../aida-config-helper.sh"
fi

#######################################
# Validate config helper exists and is executable
# Globals:
#   CONFIG_HELPER
# Arguments:
#   None
# Returns:
#   0 if valid, 1 if not
#######################################
check_config_helper() {
    if [[ ! -f "$CONFIG_HELPER" ]]; then
        print_message "error" "Config helper not found: ${CONFIG_HELPER}"
        return 1
    fi

    if [[ ! -x "$CONFIG_HELPER" ]]; then
        print_message "error" "Config helper not executable: ${CONFIG_HELPER}"
        print_message "info" "Fix with: chmod +x ${CONFIG_HELPER}"
        return 1
    fi

    return 0
}

#######################################
# Create or update user config file
# Arguments:
#   $1 - Install mode ("normal" or "dev")
#   $2 - AIDA directory path
#   $3 - Claude config directory path
#   $4 - AIDA version
#   $5 - Assistant name
#   $6 - Personality
# Returns:
#   0 on success, 1 on error
#######################################
write_user_config() {
    local install_mode="${1:-}"
    local aida_dir="${2:-}"
    local claude_dir="${3:-}"
    local version="${4:-}"
    local assistant_name="${5:-}"
    local personality="${6:-}"

    # Validate required arguments
    if [[ -z "$install_mode" ]] || [[ -z "$aida_dir" ]] || [[ -z "$claude_dir" ]] || [[ -z "$version" ]]; then
        print_message "error" "Missing required arguments for write_user_config"
        print_message "info" "Usage: write_user_config <mode> <aida_dir> <claude_dir> <version> <name> <personality>"
        return 1
    fi

    # Validate install mode
    if [[ "$install_mode" != "normal" ]] && [[ "$install_mode" != "dev" ]]; then
        print_message "error" "Invalid install mode: ${install_mode}"
        print_message "info" "Valid modes: normal, dev"
        return 1
    fi

    # Create config directory if needed
    if [[ ! -d "$claude_dir" ]]; then
        mkdir -p "$claude_dir" || {
            print_message "error" "Failed to create config directory: ${claude_dir}"
            return 1
        }
    fi

    local config_file="${claude_dir}/aida-config.json"
    local timestamp
    timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)

    # For upgrades, preserve existing user customizations
    local final_name="$assistant_name"
    local final_personality="$personality"
    local final_installed_at="$timestamp"

    if [[ -f "$config_file" ]] && jq empty "$config_file" 2>/dev/null; then
        # Config exists and is valid JSON - this is an upgrade, preserve user settings
        # Prioritize top-level fields (what users manually edit) over nested fields
        local saved_name
        local saved_personality
        saved_name=$(jq -r '.assistant_name // .user.assistant_name // empty' "$config_file")
        saved_personality=$(jq -r '.personality // .user.personality // empty' "$config_file")

        # Only use saved values if they're non-empty and not null
        if [[ -n "$saved_name" ]] && [[ "$saved_name" != "null" ]]; then
            final_name="$saved_name"
        fi
        if [[ -n "$saved_personality" ]] && [[ "$saved_personality" != "null" ]]; then
            final_personality="$saved_personality"
        fi

        # Handle old config format (v0.1.x used install_date, v0.2.x uses installed_at)
        local old_installed_at
        old_installed_at=$(jq -r '.installed_at // .install_date // empty' "$config_file")
        if [[ -n "$old_installed_at" ]] && [[ "$old_installed_at" != "null" ]]; then
            final_installed_at="$old_installed_at"
        fi

        print_message "info" "Preserving existing configuration: ${final_name} (${final_personality})"
    fi

    # Create config JSON
    # Note: We write to both top-level AND nested fields for:
    # - Top-level: Easy for users to manually edit
    # - Nested: Backwards compatibility with older code
    cat > "$config_file" <<EOF
{
  "version": "${version}",
  "install_mode": "${install_mode}",
  "installed_at": "${final_installed_at}",
  "updated_at": "${timestamp}",
  "assistant_name": "${final_name}",
  "personality": "${final_personality}",
  "paths": {
    "aida_home": "${aida_dir}",
    "claude_config_dir": "${claude_dir}",
    "home": "${HOME}"
  },
  "user": {
    "assistant_name": "${final_name}",
    "personality": "${final_personality}"
  },
  "deprecation": {
    "include_deprecated": false
  }
}
EOF

    # Validate JSON was created successfully
    if [[ ! -f "$config_file" ]]; then
        print_message "error" "Config file was not created: ${config_file}"
        print_message "error" "This may indicate a filesystem or permissions issue"
        return 1
    fi

    # Validate JSON syntax
    if ! jq empty "$config_file" 2>/dev/null; then
        print_message "error" "Failed to create valid JSON config"
        print_message "error" "Config file location: ${config_file}"
        print_message "error" "File size: $(wc -c < "$config_file" 2>/dev/null || echo "unknown") bytes"
        print_message "error" ""
        print_message "error" "Config file contents:"
        cat "$config_file" >&2 || print_message "error" "(unable to read file)"
        print_message "error" ""
        print_message "error" "JQ validation output:"
        jq empty "$config_file" >&2 2>&1 || true
        print_message "error" ""
        print_message "error" "Variables used:"
        print_message "error" "  version=${version}"
        print_message "error" "  install_mode=${install_mode}"
        print_message "error" "  aida_dir=${aida_dir}"
        print_message "error" "  claude_dir=${claude_dir}"
        print_message "error" "  final_name=${final_name}"
        print_message "error" "  final_personality=${final_personality}"
        print_message "error" "  final_installed_at=${final_installed_at}"
        return 1
    fi

    print_message "success" "Created config: ${config_file}"
    return 0
}
