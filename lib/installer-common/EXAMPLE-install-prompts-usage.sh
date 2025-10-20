#!/usr/bin/env bash
#
# EXAMPLE-install-prompts-usage.sh
#
# Description:
#   Example demonstrating how install.sh will use prompts.sh module in Task 006.
#   This shows the refactored versions of prompt_assistant_name() and prompt_personality()
#   using the new prompts.sh utilities.
#
# Note: This is an EXAMPLE file, not actual production code yet.
#       The actual refactoring will happen in Task 006.
#

set -euo pipefail

# Source required utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

source "${SCRIPT_DIR}/colors.sh"
source "${SCRIPT_DIR}/logging.sh"
source "${SCRIPT_DIR}/prompts.sh"

# User configuration globals (example)
ASSISTANT_NAME=""
PERSONALITY=""

#######################################
# BEFORE: Original implementation from install.sh (lines 122-167)
#######################################
prompt_assistant_name_original() {
    print_message "info" "Configure your assistant name"
    echo ""
    echo "The assistant name will be used throughout the AIDA framework."
    echo "Requirements: lowercase, no spaces, 3-20 characters"
    echo ""

    while true; do
        read -rp "Enter assistant name (e.g., 'jarvis', 'alfred'): " name

        # Validate name
        if [[ -z "$name" ]]; then
            print_message "warning" "Assistant name cannot be empty"
            continue
        fi

        if [[ ${#name} -lt 3 || ${#name} -gt 20 ]]; then
            print_message "warning" "Name must be 3-20 characters (got ${#name})"
            continue
        fi

        if [[ "$name" =~ [[:space:]] ]]; then
            print_message "warning" "Name cannot contain spaces"
            continue
        fi

        # Convert to lowercase for comparison (Bash 3.2 compatible)
        local name_lower
        name_lower=$(echo "$name" | tr '[:upper:]' '[:lower:]')
        if [[ "$name" != "$name_lower" ]]; then
            print_message "warning" "Name must be lowercase"
            continue
        fi

        if [[ ! "$name" =~ ^[a-z][a-z0-9-]*$ ]]; then
            print_message "warning" "Name must start with a letter and contain only lowercase letters, numbers, and hyphens"
            continue
        fi

        # Valid name
        ASSISTANT_NAME="$name"
        print_message "success" "Assistant name set to: ${ASSISTANT_NAME}"
        echo ""
        break
    done
}

#######################################
# AFTER: Refactored implementation using prompts.sh
#
# Benefits:
#   - 45 lines reduced to ~15 lines
#   - Validation logic moved to reusable prompt_input function
#   - Single regex pattern instead of multiple validation checks
#   - Automatic retry handling
#   - Consistent error messages
#######################################
prompt_assistant_name_refactored() {
    print_message "info" "Configure your assistant name"
    echo ""
    echo "The assistant name will be used throughout the AIDA framework."
    echo "Requirements: lowercase, no spaces, 3-20 characters"
    echo ""

    local name
    name=$(prompt_input \
        "Enter assistant name (e.g., 'jarvis', 'alfred')" \
        "" \
        "^[a-z][a-z0-9-]{2,19}$" \
        "Name must be 3-20 characters, lowercase, start with letter, and contain only letters, numbers, and hyphens"
    ) || {
        print_message "error" "Failed to get valid assistant name"
        return 1
    }

    ASSISTANT_NAME="$name"
    print_message "success" "Assistant name set to: ${ASSISTANT_NAME}"
    echo ""
}

#######################################
# BEFORE: Original implementation from install.sh (lines 180-209)
#######################################
prompt_personality_original() {
    print_message "info" "Select your assistant personality"
    echo ""
    echo "Available personalities:"
    echo "  1) jarvis         - Snarky British AI (helpful but judgmental)"
    echo "  2) alfred         - Dignified butler (professional, respectful)"
    echo "  3) friday         - Enthusiastic helper (upbeat, encouraging)"
    echo "  4) sage           - Zen guide (calm, mindful)"
    echo "  5) drill-sergeant - No-nonsense coach (intense, demanding)"
    echo ""

    local personalities=("jarvis" "alfred" "friday" "sage" "drill-sergeant")

    while true; do
        read -rp "Select personality [1-5]: " choice

        if [[ ! "$choice" =~ ^[1-5]$ ]]; then
            print_message "warning" "Invalid choice. Please enter a number between 1 and 5"
            continue
        fi

        # Convert choice to array index (0-based)
        local index=$((choice - 1))
        PERSONALITY="${personalities[$index]}"

        print_message "success" "Personality set to: ${PERSONALITY}"
        echo ""
        break
    done
}

#######################################
# AFTER: Refactored implementation using prompts.sh
#
# Benefits:
#   - 30 lines reduced to ~10 lines
#   - Array handling and validation moved to prompt_select
#   - Automatic bounds checking
#   - Automatic retry handling
#   - More flexible (can easily add/remove options)
#
# Note: We lose the custom descriptions, but could add them
#       as a separate prompt_info call before the selection.
#######################################
prompt_personality_refactored() {
    print_message "info" "Select your assistant personality"
    echo ""
    echo "  jarvis         - Snarky British AI (helpful but judgmental)"
    echo "  alfred         - Dignified butler (professional, respectful)"
    echo "  friday         - Enthusiastic helper (upbeat, encouraging)"
    echo "  sage           - Zen guide (calm, mindful)"
    echo "  drill-sergeant - No-nonsense coach (intense, demanding)"
    echo ""

    local personalities=("jarvis" "alfred" "friday" "sage" "drill-sergeant")

    local choice
    choice=$(prompt_select "Select personality:" "${personalities[@]}") || {
        print_message "error" "Failed to select personality"
        return 1
    }

    PERSONALITY="$choice"
    print_message "success" "Personality set to: ${PERSONALITY}"
    echo ""
}

#######################################
# Demo function to show both implementations
#######################################
demo_comparison() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Demonstration: Original vs Refactored Prompts"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    if prompt_yes_no "Test refactored implementations?" "y"; then
        # Test refactored assistant name
        echo ""
        echo "Testing: prompt_assistant_name_refactored()"
        echo "=============================================="
        prompt_assistant_name_refactored

        # Test refactored personality
        echo ""
        echo "Testing: prompt_personality_refactored()"
        echo "========================================"
        prompt_personality_refactored

        # Show results
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        print_message "success" "Configuration captured successfully!"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Results:"
        echo "  Assistant Name: ${ASSISTANT_NAME}"
        echo "  Personality:    ${PERSONALITY}"
        echo ""
    fi
}

# Run demo
demo_comparison
