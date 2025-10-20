#!/usr/bin/env bash
#
# logging.sh - Logging Utilities
#
# Description:
#   Logging and message output utilities for AIDA installer-common library.
#   Provides consistent messaging across AIDA and dotfiles installers.
#
# Dependencies:
#   - colors.sh (must be sourced first)
#
# Part of: AIDA installer-common library v1.0
# Usage:
#   source "${INSTALLER_COMMON}/colors.sh"
#   source "${INSTALLER_COMMON}/logging.sh"
#
# Author: oakensoul
# License: AGPL-3.0
# Repository: https://github.com/oakensoul/claude-personal-assistant
#

set -euo pipefail

# Log file location (created on first use)
# Logs go in ~/.claude/logs (always writable) not ~/.aida/logs (read-only in dev mode)
readonly AIDA_LOG_DIR="${HOME}/.claude/logs"
readonly AIDA_LOG_FILE="${AIDA_LOG_DIR}/install.log"

#######################################
# Initialize logging (create log directory)
# Globals:
#   AIDA_LOG_DIR
# Arguments:
#   None
# Returns:
#   0 on success
#######################################
init_logging() {
    if [[ ! -d "$AIDA_LOG_DIR" ]]; then
        mkdir -p "$AIDA_LOG_DIR"
        chmod 700 "$AIDA_LOG_DIR"
    fi
}

#######################################
# Write detailed message to log file
# Arguments:
#   $1 - Log level (INFO, SUCCESS, WARNING, ERROR)
#   $2 - Message text
# Outputs:
#   Writes to log file with timestamp
#######################################
log_to_file() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    init_logging

    # Path scrubbing: replace /Users/username/ with ~/
    local scrubbed_message
    scrubbed_message="${message//${HOME}/~}"

    echo "[${timestamp}] [${level}] ${scrubbed_message}" >> "$AIDA_LOG_FILE"
}

#######################################
# Print formatted message to stdout/stderr
# Arguments:
#   $1 - Message type (info, success, warning, error)
#   $2 - Message text
# Outputs:
#   Writes formatted message to stdout/stderr
#######################################
print_message() {
    local type="$1"
    local message="$2"

    case "$type" in
        info)
            echo -e "$(color_blue 'ℹ') ${message}"
            log_to_file "INFO" "$message"
            ;;
        success)
            echo -e "$(color_green '✓') ${message}"
            log_to_file "SUCCESS" "$message"
            ;;
        warning)
            echo -e "$(color_yellow '⚠') ${message}" >&2
            log_to_file "WARNING" "$message"
            ;;
        error)
            echo -e "$(color_red '✗') ${message}" >&2
            log_to_file "ERROR" "$message"
            ;;
        *)
            echo "${message}"
            log_to_file "INFO" "$message"
            ;;
    esac
}

#######################################
# Print generic error with detailed log
# Arguments:
#   $1 - Generic user-facing message
#   $2 - Detailed error message (logged only)
# Outputs:
#   Generic message to stderr, detailed to log
#######################################
print_error_with_detail() {
    local generic_message="$1"
    local detailed_message="$2"

    print_message "error" "$generic_message"
    log_to_file "ERROR_DETAIL" "$detailed_message"

    # Inform user about log location
    echo "$(color_blue 'ℹ') For details, see: ${AIDA_LOG_FILE}" >&2
}
