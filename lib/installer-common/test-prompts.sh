#!/usr/bin/env bash
#
# test-prompts.sh - Manual Test Script for prompts.sh Module
#
# Description:
#   Simple manual test script to verify prompts.sh functionality.
#   This is for development/manual testing - not automated unit tests.
#
# Usage:
#   ./lib/installer-common/test-prompts.sh
#

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# Source required utilities
source "${SCRIPT_DIR}/colors.sh" || {
    echo "Error: Failed to source colors.sh"
    exit 1
}

source "${SCRIPT_DIR}/logging.sh" || {
    echo "Error: Failed to source logging.sh"
    exit 1
}

source "${SCRIPT_DIR}/prompts.sh" || {
    echo "Error: Failed to source prompts.sh"
    exit 1
}

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  prompts.sh Module - Manual Test Suite"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test 1: prompt_yes_no
echo "Test 1: prompt_yes_no"
echo "---------------------"
if prompt_yes_no "Do you want to continue with tests?" "y"; then
    print_message "success" "User confirmed"
else
    print_message "info" "User declined - exiting tests"
    exit 0
fi
echo ""

# Test 2: prompt_input (simple)
echo "Test 2: prompt_input (simple text)"
echo "----------------------------------"
name=$(prompt_input "Enter your name" "TestUser")
print_message "success" "Name captured: ${name}"
echo ""

# Test 3: prompt_input (with regex validation)
echo "Test 3: prompt_input (with regex validation)"
echo "--------------------------------------------"
email=$(prompt_input "Enter email address" "" "^[^@]+@[^@]+\.[^@]+$" "Invalid email format")
print_message "success" "Email captured: ${email}"
echo ""

# Test 4: prompt_select
echo "Test 4: prompt_select"
echo "---------------------"
options=("Option 1" "Option 2" "Option 3")
choice=$(prompt_select "Choose an option:" "${options[@]}")
print_message "success" "Selected: ${choice}"
echo ""

# Test 5: confirm_action
echo "Test 5: confirm_action"
echo "----------------------"
if confirm_action "Perform destructive operation" "This is a test warning message"; then
    print_message "success" "User confirmed destructive action"
else
    print_message "info" "User cancelled destructive action"
fi
echo ""

# Test 6: prompt_input_validated (with custom function)
echo "Test 6: prompt_input_validated (custom validation)"
echo "---------------------------------------------------"

# Define custom validation function
validate_number() {
    local input="$1"
    [[ "$input" =~ ^[0-9]+$ ]]
}

number=$(prompt_input_validated "Enter a number" "42" "validate_number" "Must be a positive integer")
print_message "success" "Number captured: ${number}"
echo ""

# Test 7: prompt_info
echo "Test 7: prompt_info"
echo "-------------------"
prompt_info "This is an informational message (no wait)" "false"
prompt_info "This is an informational message (with wait)" "true"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print_message "success" "All manual tests completed!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
