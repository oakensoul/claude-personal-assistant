#!/usr/bin/env bash
#
# summary.sh - Installation Summary Display
#
# Description:
#   User-friendly installation summary display with visual formatting.
#   Provides clear feedback about installation results and next steps.
#
# Dependencies:
#   - colors.sh (must be sourced first)
#   - logging.sh (must be sourced first)
#
# Part of: AIDA installer-common library v1.0
# Usage:
#   source "${INSTALLER_COMMON}/colors.sh"
#   source "${INSTALLER_COMMON}/logging.sh"
#   source "${INSTALLER_COMMON}/summary.sh"
#
# Author: oakensoul
# License: AGPL-3.0
# Repository: https://github.com/oakensoul/claude-personal-assistant
#

set -euo pipefail

# Additional color codes for summary display
readonly COLOR_CYAN='\033[0;36m'
readonly COLOR_MAGENTA='\033[0;35m'
readonly COLOR_BOLD='\033[1m'
readonly COLOR_BOLD_BLUE='\033[1;34m'

# Box drawing characters (Unicode)
readonly BOX_TOP_LEFT="╔"
readonly BOX_TOP_RIGHT="╗"
readonly BOX_BOTTOM_LEFT="╚"
readonly BOX_BOTTOM_RIGHT="╝"
readonly BOX_HORIZONTAL="═"
readonly BOX_VERTICAL="║"
readonly BOX_DIVIDER_LEFT="╠"
readonly BOX_DIVIDER_RIGHT="╣"
readonly LINE_HORIZONTAL="─"

#######################################
# Get terminal width for responsive output
# Arguments:
#   None
# Returns:
#   Terminal width in columns (default: 80)
# Outputs:
#   Width to stdout
#######################################
get_terminal_width() {
    tput cols 2>/dev/null || echo "80"
}

#######################################
# Draw a horizontal line with box drawing characters
# Arguments:
#   $1 - Width (optional, defaults to terminal width)
#   $2 - Character to use (optional, defaults to LINE_HORIZONTAL)
# Outputs:
#   Horizontal line to stdout
#######################################
draw_horizontal_line() {
    local width="${1:-$(get_terminal_width)}"
    local char="${2:-$LINE_HORIZONTAL}"
    printf '%*s\n' "$width" '' | tr ' ' "$char"
}

#######################################
# Draw a box header
# Arguments:
#   $1 - Title text
# Outputs:
#   Formatted box header to stdout
#######################################
draw_box_header() {
    local title="$1"
    local width
    width=$(get_terminal_width)
    local inner_width=$((width - 2))
    local title_length=${#title}
    local padding=$(( (inner_width - title_length) / 2 ))
    local remaining=$((inner_width - title_length - padding))

    if supports_color; then
        echo -e "${COLOR_BOLD_BLUE}${BOX_TOP_LEFT}$(printf '%*s' "$inner_width" '' | tr ' ' "$BOX_HORIZONTAL")${BOX_TOP_RIGHT}${COLOR_NC}"
        echo -e "${COLOR_BOLD_BLUE}${BOX_VERTICAL}$(printf '%*s' "$padding" '')${COLOR_BOLD}${title}$(printf '%*s' "$remaining" '')${BOX_VERTICAL}${COLOR_NC}"
        echo -e "${COLOR_BOLD_BLUE}${BOX_BOTTOM_LEFT}$(printf '%*s' "$inner_width" '' | tr ' ' "$BOX_HORIZONTAL")${BOX_BOTTOM_RIGHT}${COLOR_NC}"
    else
        echo "${BOX_TOP_LEFT}$(printf '%*s' "$inner_width" '' | tr ' ' "$BOX_HORIZONTAL")${BOX_TOP_RIGHT}"
        echo "${BOX_VERTICAL}$(printf '%*s' "$padding" '')${title}$(printf '%*s' "$remaining" '')${BOX_VERTICAL}"
        echo "${BOX_BOTTOM_LEFT}$(printf '%*s' "$inner_width" '' | tr ' ' "$BOX_HORIZONTAL")${BOX_BOTTOM_RIGHT}"
    fi
}

#######################################
# Draw a box footer with content inside
# Arguments:
#   $1 - Title text
#   $@ - Content lines (passed via here-doc or additional args)
# Outputs:
#   Formatted box to stdout
#######################################
draw_box() {
    local title="$1"
    shift
    local width
    width=$(get_terminal_width)
    local inner_width=$((width - 2))

    # Draw top border
    if supports_color; then
        echo -e "${COLOR_BOLD_BLUE}${BOX_TOP_LEFT}$(printf '%*s' "$inner_width" '' | tr ' ' "$BOX_HORIZONTAL")${BOX_TOP_RIGHT}${COLOR_NC}"
        echo -e "${COLOR_BOLD_BLUE}${BOX_VERTICAL} ${COLOR_BOLD}${title}$(printf '%*s' $((inner_width - ${#title} - 1)) '')${BOX_VERTICAL}${COLOR_NC}"
        echo -e "${COLOR_BOLD_BLUE}${BOX_DIVIDER_LEFT}$(printf '%*s' "$inner_width" '' | tr ' ' "$BOX_HORIZONTAL")${BOX_DIVIDER_RIGHT}${COLOR_NC}"
    else
        echo "${BOX_TOP_LEFT}$(printf '%*s' "$inner_width" '' | tr ' ' "$BOX_HORIZONTAL")${BOX_TOP_RIGHT}"
        echo "${BOX_VERTICAL} ${title}$(printf '%*s' $((inner_width - ${#title} - 1)) '')${BOX_VERTICAL}"
        echo "${BOX_DIVIDER_LEFT}$(printf '%*s' "$inner_width" '' | tr ' ' "$BOX_HORIZONTAL")${BOX_DIVIDER_RIGHT}"
    fi

    # Draw content (read from stdin if no args)
    if [[ $# -eq 0 ]]; then
        while IFS= read -r line; do
            local padding=$((inner_width - ${#line} - 1))
            if supports_color; then
                echo -e "${COLOR_BOLD_BLUE}${BOX_VERTICAL}${COLOR_NC} ${line}$(printf '%*s' "$padding" '')${COLOR_BOLD_BLUE}${BOX_VERTICAL}${COLOR_NC}"
            else
                echo "${BOX_VERTICAL} ${line}$(printf '%*s' "$padding" '')${BOX_VERTICAL}"
            fi
        done
    else
        for line in "$@"; do
            local padding=$((inner_width - ${#line} - 1))
            if supports_color; then
                echo -e "${COLOR_BOLD_BLUE}${BOX_VERTICAL}${COLOR_NC} ${line}$(printf '%*s' "$padding" '')${COLOR_BOLD_BLUE}${BOX_VERTICAL}${COLOR_NC}"
            else
                echo "${BOX_VERTICAL} ${line}$(printf '%*s' "$padding" '')${BOX_VERTICAL}"
            fi
        done
    fi

    # Draw bottom border
    if supports_color; then
        echo -e "${COLOR_BOLD_BLUE}${BOX_BOTTOM_LEFT}$(printf '%*s' "$inner_width" '' | tr ' ' "$BOX_HORIZONTAL")${BOX_BOTTOM_RIGHT}${COLOR_NC}"
    else
        echo "${BOX_BOTTOM_LEFT}$(printf '%*s' "$inner_width" '' | tr ' ' "$BOX_HORIZONTAL")${BOX_BOTTOM_RIGHT}"
    fi
}

#######################################
# Count templates in a directory
# Arguments:
#   $1 - Template directory path
# Returns:
#   Number of templates (0 if directory doesn't exist)
# Outputs:
#   Count to stdout
#######################################
count_templates() {
    local template_dir="$1"

    if [[ -d "$template_dir" ]]; then
        find "$template_dir" -mindepth 1 -maxdepth 1 -type f -name "*.md" | wc -l | tr -d ' '
    else
        echo "0"
    fi
}

#######################################
# Count agents in a directory
# Arguments:
#   $1 - Agents directory path
# Returns:
#   Number of agents (0 if directory doesn't exist)
# Outputs:
#   Count to stdout
#######################################
count_agents() {
    local agents_dir="$1"

    if [[ -d "$agents_dir" ]]; then
        find "$agents_dir" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' '
    else
        echo "0"
    fi
}

#######################################
# Display installation summary
# Arguments:
#   $1 - Install mode ("normal" or "dev")
#   $2 - AIDA directory path
#   $3 - Claude config directory path
#   $4 - AIDA version
# Outputs:
#   Formatted summary to stdout
#######################################
display_summary() {
    local install_mode="$1"
    local aida_dir="$2"
    local claude_dir="$3"
    local version="$4"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo ""
    draw_box_header "AIDA FRAMEWORK INSTALLATION COMPLETE"
    echo ""

    echo "Installation Details:"
    draw_horizontal_line 65 "$LINE_HORIZONTAL"
    echo ""
    echo "  $(apply_color "$COLOR_CYAN" "Version:")        $version"
    if [[ "$install_mode" == "dev" ]]; then
        echo "  $(apply_color "$COLOR_CYAN" "Mode:")           Development mode (symlinked)"
    else
        echo "  $(apply_color "$COLOR_CYAN" "Mode:")           Normal installation"
    fi
    echo "  $(apply_color "$COLOR_CYAN" "Installed:")      $timestamp"
    echo ""
    echo "  $(apply_color "$COLOR_MAGENTA" "Framework:")      ${aida_dir/#$HOME/\~}"
    if [[ "$install_mode" == "dev" ]]; then
        echo "                    $(apply_color "$COLOR_YELLOW" "(symlinked to repository)")"
    fi
    echo "  $(apply_color "$COLOR_MAGENTA" "Configuration:")  ${claude_dir/#$HOME/\~}"
    echo "  $(apply_color "$COLOR_MAGENTA" "Entry Point:")    ~/CLAUDE.md"
    echo ""

    # Count installed templates
    local commands_count agents_count
    commands_count=$(count_templates "${claude_dir}/commands")
    agents_count=$(count_agents "${claude_dir}/agents")

    if [[ "$commands_count" -gt 0 ]] || [[ "$agents_count" -gt 0 ]]; then
        echo "Installed Templates:"
        draw_horizontal_line 65 "$LINE_HORIZONTAL"
        echo ""
        if [[ "$commands_count" -gt 0 ]]; then
            echo "  $(apply_color "$COLOR_GREEN" "Commands:")      ${commands_count} templates"
        fi
        if [[ "$agents_count" -gt 0 ]]; then
            echo "  $(apply_color "$COLOR_GREEN" "Agents:")        ${agents_count} agents"
        fi
        echo ""
    fi
}

#######################################
# Display next steps after installation
# Arguments:
#   $1 - Install mode ("normal" or "dev")
# Outputs:
#   Formatted next steps to stdout
#######################################
display_next_steps() {
    local install_mode="$1"

    draw_box "NEXT STEPS" <<EOF

  1. Review configuration: ~/.claude/aida-config.json
  2. Try a command: /start-work
  3. Read documentation: ~/.aida/README.md
$(if [[ "$install_mode" == "dev" ]]; then echo "
  Development mode: Changes to templates take effect
  immediately (no reinstall needed)"; fi)

EOF
    echo ""
}

#######################################
# Display success message with confirmation
# Arguments:
#   $1 - Success message
#   $2 - Optional details
# Outputs:
#   Formatted success message to stdout
#######################################
display_success() {
    local message="$1"
    local details="${2:-}"

    print_message "success" "$message"
    if [[ -n "$details" ]]; then
        echo ""
        echo "$details"
    fi
}

#######################################
# Display error message with recovery guidance
# Arguments:
#   $1 - Error message
#   $2 - Optional recovery steps (newline-separated)
# Outputs:
#   Formatted error message to stderr
#######################################
display_error() {
    local error_message="$1"
    local recovery_steps="${2:-}"

    echo "" >&2
    print_message "error" "$error_message"

    if [[ -n "$recovery_steps" ]]; then
        echo "" >&2
        apply_color "$COLOR_BOLD" "Recovery steps:" >&2
        echo "" >&2
        echo "$recovery_steps" | while IFS= read -r step; do
            if [[ -n "$step" ]]; then
                echo "  $step" >&2
            fi
        done
        echo "" >&2
    fi
}

#######################################
# Display upgrade installation summary
# Arguments:
#   $1 - Previous version
#   $2 - New version
#   $3 - Number of preserved files
# Outputs:
#   Formatted upgrade summary to stdout
#######################################
display_upgrade_summary() {
    local previous_version="$1"
    local new_version="$2"
    local preserved_files_count="$3"

    echo ""
    draw_box_header "AIDA FRAMEWORK UPGRADE COMPLETE"
    echo ""

    echo "Upgrade Details:"
    draw_horizontal_line 65 "$LINE_HORIZONTAL"
    echo ""
    echo "  $(apply_color "$COLOR_CYAN" "Previous Version:") $previous_version"
    echo "  $(apply_color "$COLOR_CYAN" "New Version:")      $new_version"
    echo ""
    if [[ "$preserved_files_count" -gt 0 ]]; then
        echo "  $(apply_color "$COLOR_GREEN" "User Files:")      ${preserved_files_count} files preserved"
        echo ""
    fi

    echo "What Changed:"
    draw_horizontal_line 65 "$LINE_HORIZONTAL"
    echo ""
    echo "  $(apply_color "$COLOR_GREEN" "✓") Framework files updated to v${new_version}"
    echo "  $(apply_color "$COLOR_GREEN" "✓") Your configuration and customizations preserved"
    if [[ "$preserved_files_count" -gt 0 ]]; then
        echo "  $(apply_color "$COLOR_GREEN" "✓") ${preserved_files_count} user files backed up and restored"
    fi
    echo ""
}
