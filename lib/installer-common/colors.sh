#!/usr/bin/env bash
#
# colors.sh - Terminal Color Utilities
#
# Description:
#   Terminal color codes and formatting utilities for AIDA installer-common library.
#   Provides consistent color output across AIDA and dotfiles installers.
#
# Part of: AIDA installer-common library v1.0
# Usage:
#   source "${INSTALLER_COMMON}/colors.sh"
#
# Author: oakensoul
# License: AGPL-3.0
# Repository: https://github.com/oakensoul/claude-personal-assistant
#

set -euo pipefail

# Color codes for terminal output
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_NC='\033[0m' # No Color

#######################################
# Check if terminal supports colors
# Globals:
#   NO_COLOR (environment variable)
#   TERM (environment variable)
# Arguments:
#   None
# Returns:
#   0 if colors supported, 1 otherwise
#######################################
supports_color() {
    # Check NO_COLOR environment variable (standard)
    if [[ -n "${NO_COLOR:-}" ]]; then
        return 1
    fi

    # Check if stdout is a terminal
    if [[ ! -t 1 ]]; then
        return 1
    fi

    # Check TERM variable
    if [[ -z "${TERM:-}" ]] || [[ "${TERM}" == "dumb" ]]; then
        return 1
    fi

    return 0
}

#######################################
# Apply color to text if colors supported
# Arguments:
#   $1 - Color code (COLOR_RED, COLOR_GREEN, etc.)
#   $2 - Text to colorize
# Outputs:
#   Colored text if supported, plain text otherwise
#######################################
apply_color() {
    local color="$1"
    local text="$2"

    if supports_color; then
        echo -e "${color}${text}${COLOR_NC}"
    else
        echo "$text"
    fi
}

#######################################
# Output text in red (errors)
# Arguments:
#   $1 - Text to output
# Outputs:
#   Red-colored text
#######################################
color_red() {
    apply_color "$COLOR_RED" "$1"
}

#######################################
# Output text in green (success)
# Arguments:
#   $1 - Text to output
# Outputs:
#   Green-colored text
#######################################
color_green() {
    apply_color "$COLOR_GREEN" "$1"
}

#######################################
# Output text in yellow (warnings)
# Arguments:
#   $1 - Text to output
# Outputs:
#   Yellow-colored text
#######################################
color_yellow() {
    apply_color "$COLOR_YELLOW" "$1"
}

#######################################
# Output text in blue (info)
# Arguments:
#   $1 - Text to output
# Outputs:
#   Blue-colored text
#######################################
color_blue() {
    apply_color "$COLOR_BLUE" "$1"
}
