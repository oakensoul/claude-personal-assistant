#!/usr/bin/env bash
#
# prompts.sh - User Interaction and Prompt Utilities
#
# Description:
#   User interaction, prompting, and input validation utilities for AIDA installer-common library.
#   Provides reusable prompt functions for yes/no questions, text input, selections, and confirmations.
#   All functions are designed to be modular and accept parameters (no hardcoded globals).
#
# Dependencies:
#   - colors.sh (must be sourced first)
#   - logging.sh (must be sourced first)
#
# Part of: AIDA installer-common library v1.0
# Usage:
#   source "${INSTALLER_COMMON}/colors.sh"
#   source "${INSTALLER_COMMON}/logging.sh"
#   source "${INSTALLER_COMMON}/prompts.sh"
#
# Author: oakensoul
# License: AGPL-3.0
# Repository: https://github.com/oakensoul/claude-personal-assistant
#

set -euo pipefail

#######################################
# Prompt yes/no question with validation
#
# Presents a yes/no question to the user and returns 0 for yes, 1 for no.
# Validates input and supports default values.
#
# Arguments:
#   $1 - Question to ask (required)
#   $2 - Default answer: 'y' or 'n' (optional, default: 'n')
#
# Returns:
#   0 if user answered yes (y/Y)
#   1 if user answered no (n/N)
#
# Outputs:
#   Writes prompt to stdout, reads from stdin
#
# Example:
#   if prompt_yes_no "Continue with installation?" "y"; then
#       echo "User confirmed"
#   else
#       echo "User declined"
#   fi
#######################################
prompt_yes_no() {
    local question="$1"
    local default="${2:-n}"
    local answer=""

    # Validate default value
    if [[ "$default" != "y" && "$default" != "n" ]]; then
        print_message "error" "Invalid default value for prompt_yes_no: ${default} (must be 'y' or 'n')"
        return 2
    fi

    # Format prompt with default indicator
    local prompt_text
    if [[ "$default" == "y" ]]; then
        prompt_text="${question} [Y/n]: "
    else
        prompt_text="${question} [y/N]: "
    fi

    while true; do
        read -rp "$prompt_text" answer

        # Use default if no answer provided
        if [[ -z "$answer" ]]; then
            answer="$default"
        fi

        # Convert to lowercase for comparison (Bash 3.2 compatible)
        answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')

        case "$answer" in
            y|yes)
                return 0
                ;;
            n|no)
                return 1
                ;;
            *)
                print_message "warning" "Invalid input. Please enter 'y' or 'n'"
                ;;
        esac
    done
}

#######################################
# Prompt for text input with optional validation
#
# Prompts user for text input with optional regex validation and default value.
# Continues prompting until valid input is received or validation passes.
#
# Arguments:
#   $1 - Question/prompt text (required)
#   $2 - Default value (optional, empty string if not provided)
#   $3 - Validation regex pattern (optional, no validation if not provided)
#   $4 - Validation error message (optional, generic message if not provided)
#
# Returns:
#   0 on success
#   1 if validation fails and max retries exceeded
#
# Outputs:
#   Writes prompt to stdout, validated input to stdout via echo
#
# Example:
#   name=$(prompt_input "Enter your name:" "" "^[a-zA-Z ]+$" "Name must contain only letters and spaces")
#   email=$(prompt_input "Enter email:" "user@example.com" "^[^@]+@[^@]+\.[^@]+$" "Invalid email format")
#######################################
prompt_input() {
    local question="$1"
    local default="${2:-}"
    local validation_regex="${3:-}"
    local validation_error="${4:-Invalid input. Please try again}"
    local input=""
    local retry_count=0
    local max_retries=5

    while true; do
        # Format prompt with default if provided
        local prompt_text="$question"
        if [[ -n "$default" ]]; then
            prompt_text="${question} [${default}]: "
        else
            prompt_text="${question}: "
        fi

        read -rp "$prompt_text" input

        # Use default if no input provided
        if [[ -z "$input" && -n "$default" ]]; then
            input="$default"
        fi

        # Check for empty input when no default
        if [[ -z "$input" ]]; then
            print_message "warning" "Input cannot be empty"
            retry_count=$((retry_count + 1))
            if [[ $retry_count -ge $max_retries ]]; then
                print_message "error" "Maximum retry attempts exceeded"
                return 1
            fi
            continue
        fi

        # Validate input if regex provided
        if [[ -n "$validation_regex" ]]; then
            if [[ ! "$input" =~ $validation_regex ]]; then
                print_message "warning" "$validation_error"
                retry_count=$((retry_count + 1))
                if [[ $retry_count -ge $max_retries ]]; then
                    print_message "error" "Maximum retry attempts exceeded"
                    return 1
                fi
                continue
            fi
        fi

        # Valid input
        echo "$input"
        return 0
    done
}

#######################################
# Prompt selection from numbered list of options
#
# Presents a numbered list of options and prompts user to select one.
# Returns the selected option text (not the number).
#
# Arguments:
#   $1 - Question/prompt text (required)
#   $2+ - List of options (minimum 2 required)
#
# Returns:
#   0 on success
#   1 if insufficient options provided
#   2 if max retries exceeded
#
# Outputs:
#   Writes options and prompt to stdout, selected option to stdout via echo
#
# Example:
#   options=("Option 1" "Option 2" "Option 3")
#   choice=$(prompt_select "Choose an option:" "${options[@]}")
#   echo "You selected: $choice"
#######################################
prompt_select() {
    local question="$1"
    shift
    local options=("$@")
    local choice=""
    local retry_count=0
    local max_retries=5

    # Validate minimum number of options
    if [[ ${#options[@]} -lt 2 ]]; then
        print_message "error" "prompt_select requires at least 2 options"
        return 1
    fi

    # Display options
    echo ""
    echo "$question"
    echo ""
    for i in "${!options[@]}"; do
        local num=$((i + 1))
        echo "  ${num}) ${options[$i]}"
    done
    echo ""

    while true; do
        read -rp "Select option [1-${#options[@]}]: " choice

        # Validate choice is a number
        if [[ ! "$choice" =~ ^[0-9]+$ ]]; then
            print_message "warning" "Please enter a number"
            retry_count=$((retry_count + 1))
            if [[ $retry_count -ge $max_retries ]]; then
                print_message "error" "Maximum retry attempts exceeded"
                return 2
            fi
            continue
        fi

        # Validate choice is in range
        if [[ $choice -lt 1 || $choice -gt ${#options[@]} ]]; then
            print_message "warning" "Invalid choice. Please enter a number between 1 and ${#options[@]}"
            retry_count=$((retry_count + 1))
            if [[ $retry_count -ge $max_retries ]]; then
                print_message "error" "Maximum retry attempts exceeded"
                return 2
            fi
            continue
        fi

        # Valid choice - convert to array index (0-based)
        local index=$((choice - 1))
        echo "${options[$index]}"
        return 0
    done
}

#######################################
# Confirm potentially destructive action
#
# Presents a confirmation prompt for destructive actions with optional warning message.
# Requires explicit 'yes' (not just 'y') for confirmation to prevent accidental execution.
#
# Arguments:
#   $1 - Action description (required)
#   $2 - Warning message (optional)
#
# Returns:
#   0 if user confirmed (typed 'yes')
#   1 if user declined (typed anything else or just pressed enter)
#
# Outputs:
#   Writes warning and prompt to stdout, reads from stdin
#
# Example:
#   if confirm_action "Delete all files" "This action cannot be undone"; then
#       echo "User confirmed deletion"
#   else
#       echo "User cancelled"
#   fi
#######################################
confirm_action() {
    local action_description="$1"
    local warning_message="${2:-}"
    local confirmation=""

    echo ""
    print_message "warning" "CONFIRMATION REQUIRED"
    echo ""
    echo "Action: ${action_description}"
    if [[ -n "$warning_message" ]]; then
        echo ""
        print_message "warning" "$warning_message"
    fi
    echo ""
    read -rp "Type 'yes' to confirm (anything else to cancel): " confirmation

    # Require exact match of 'yes' (case-sensitive)
    if [[ "$confirmation" == "yes" ]]; then
        return 0
    else
        print_message "info" "Action cancelled"
        return 1
    fi
}

#######################################
# Prompt for text input with custom validation function
#
# Advanced input prompt that accepts a custom validation function for complex validation logic.
# The validation function should return 0 for valid input, non-zero for invalid input.
#
# Arguments:
#   $1 - Question/prompt text (required)
#   $2 - Default value (optional, empty string if not provided)
#   $3 - Name of validation function (optional, no validation if not provided)
#   $4 - Validation error message (optional, generic message if not provided)
#
# Returns:
#   0 on success
#   1 if validation fails and max retries exceeded
#   2 if validation function is not defined
#
# Outputs:
#   Writes prompt to stdout, validated input to stdout via echo
#
# Example:
#   validate_email() {
#       local email="$1"
#       [[ "$email" =~ ^[^@]+@[^@]+\.[^@]+$ ]]
#   }
#   email=$(prompt_input_validated "Enter email:" "" "validate_email" "Invalid email format")
#######################################
prompt_input_validated() {
    local question="$1"
    local default="${2:-}"
    local validation_func="${3:-}"
    local validation_error="${4:-Invalid input. Please try again}"
    local input=""
    local retry_count=0
    local max_retries=5

    # Check if validation function is defined
    if [[ -n "$validation_func" ]]; then
        if ! declare -f "$validation_func" >/dev/null 2>&1; then
            print_message "error" "Validation function '${validation_func}' is not defined"
            return 2
        fi
    fi

    while true; do
        # Format prompt with default if provided
        local prompt_text="$question"
        if [[ -n "$default" ]]; then
            prompt_text="${question} [${default}]: "
        else
            prompt_text="${question}: "
        fi

        read -rp "$prompt_text" input

        # Use default if no input provided
        if [[ -z "$input" && -n "$default" ]]; then
            input="$default"
        fi

        # Check for empty input when no default
        if [[ -z "$input" ]]; then
            print_message "warning" "Input cannot be empty"
            retry_count=$((retry_count + 1))
            if [[ $retry_count -ge $max_retries ]]; then
                print_message "error" "Maximum retry attempts exceeded"
                return 1
            fi
            continue
        fi

        # Validate input if function provided
        if [[ -n "$validation_func" ]]; then
            if ! "$validation_func" "$input"; then
                print_message "warning" "$validation_error"
                retry_count=$((retry_count + 1))
                if [[ $retry_count -ge $max_retries ]]; then
                    print_message "error" "Maximum retry attempts exceeded"
                    return 1
                fi
                continue
            fi
        fi

        # Valid input
        echo "$input"
        return 0
    done
}

#######################################
# Display informational message with optional continuation prompt
#
# Shows an informational message and optionally waits for user to press Enter to continue.
# Useful for displaying important information that user should acknowledge.
#
# Arguments:
#   $1 - Message to display (required)
#   $2 - Wait for user (optional, 'true' to wait, 'false' to continue, default: 'false')
#
# Returns:
#   0 always
#
# Outputs:
#   Writes message to stdout, optionally waits for Enter key
#
# Example:
#   prompt_info "Installation will begin..." "false"
#   prompt_info "Please review the configuration above" "true"
#######################################
prompt_info() {
    local message="$1"
    local wait_for_user="${2:-false}"

    echo ""
    print_message "info" "$message"
    echo ""

    if [[ "$wait_for_user" == "true" ]]; then
        read -rp "Press Enter to continue..."
        echo ""
    fi
}
