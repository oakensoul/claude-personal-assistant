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
# Get full merged configuration
# Globals:
#   CONFIG_HELPER
# Arguments:
#   None
# Returns:
#   0 on success, 1 on error
# Outputs:
#   Full merged JSON config to stdout
#######################################
get_config() {
    check_config_helper || return 1

    "$CONFIG_HELPER" || {
        print_message "error" "Failed to get merged config"
        return 1
    }
}

#######################################
# Get specific config value by key path
# Arguments:
#   $1 - Key path (e.g., "paths.aida_home")
# Returns:
#   0 on success, 1 on error
# Outputs:
#   Value to stdout
#######################################
get_config_value() {
    local key="$1"

    if [[ -z "$key" ]]; then
        print_message "error" "Config key cannot be empty"
        return 1
    fi

    check_config_helper || return 1

    "$CONFIG_HELPER" --key "$key" || {
        print_message "error" "Failed to get config value for key: $key"
        return 1
    }
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
    local install_mode="$1"
    local aida_dir="$2"
    local claude_dir="$3"
    local version="$4"
    local assistant_name="$5"
    local personality="$6"

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

    # Create config JSON
    cat > "$config_file" <<EOF
{
  "version": "${version}",
  "install_mode": "${install_mode}",
  "installed_at": "${timestamp}",
  "updated_at": "${timestamp}",
  "paths": {
    "aida_home": "${aida_dir}",
    "claude_config_dir": "${claude_dir}",
    "home": "${HOME}"
  },
  "user": {
    "assistant_name": "${assistant_name}",
    "personality": "${personality}"
  },
  "deprecation": {
    "include_deprecated": false
  }
}
EOF

    # Validate JSON
    if ! jq empty "$config_file" 2>/dev/null; then
        print_message "error" "Failed to create valid JSON config"
        return 1
    fi

    print_message "success" "Created config: ${config_file}"
    return 0
}

#######################################
# Validate configuration has required keys
# Globals:
#   CONFIG_HELPER
# Arguments:
#   None
# Returns:
#   0 if valid, 1 if validation fails
#######################################
validate_config() {
    check_config_helper || return 1

    "$CONFIG_HELPER" --validate || {
        print_message "error" "Configuration validation failed"
        return 1
    }
}

#######################################
# Check if config file exists
# Arguments:
#   $1 - Path to config file
# Returns:
#   0 if exists, 1 if not
#######################################
config_exists() {
    local config_path="$1"

    if [[ -z "$config_path" ]]; then
        print_message "error" "Config path cannot be empty"
        return 1
    fi

    if [[ -f "$config_path" ]]; then
        return 0
    else
        return 1
    fi
}
