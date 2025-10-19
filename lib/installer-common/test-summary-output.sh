#!/usr/bin/env bash
#
# test-summary-output.sh - Visual Tests for Summary Module
#
# Description:
#   Comprehensive visual testing for summary.sh module functions.
#   Tests all display functions with various scenarios.
#
# Usage:
#   ./test-summary-output.sh
#   ./test-summary-output.sh --no-color  # Test without colors
#
# Author: oakensoul
# License: AGPL-3.0
# Repository: https://github.com/oakensoul/claude-personal-assistant
#

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# Source dependencies
# shellcheck source=lib/installer-common/colors.sh
source "${SCRIPT_DIR}/colors.sh"
# shellcheck source=lib/installer-common/logging.sh
source "${SCRIPT_DIR}/logging.sh"
# shellcheck source=lib/installer-common/summary.sh
source "${SCRIPT_DIR}/summary.sh"

# Test counter
TEST_NUM=0

#######################################
# Print test header
# Arguments:
#   $1 - Test description
#######################################
test_header() {
    TEST_NUM=$((TEST_NUM + 1))
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "TEST $TEST_NUM: $1"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

#######################################
# Create test directory structure
#######################################
setup_test_dirs() {
    local test_root="${TMPDIR:-/tmp}/aida-summary-test-$$"
    mkdir -p "$test_root"
    mkdir -p "${test_root}/.aida"
    mkdir -p "${test_root}/.claude/commands"
    mkdir -p "${test_root}/.claude/agents/agent1"
    mkdir -p "${test_root}/.claude/agents/agent2"

    # Create some dummy template files
    touch "${test_root}/.claude/commands/start-work.md"
    touch "${test_root}/.claude/commands/implement.md"
    touch "${test_root}/.claude/commands/open-pr.md"

    echo "$test_root"
}

#######################################
# Clean up test directories
#######################################
cleanup_test_dirs() {
    local test_root="$1"
    if [[ -d "$test_root" ]]; then
        rm -rf "$test_root"
    fi
}

#######################################
# Main test suite
#######################################
main() {
    # Parse arguments
    if [[ "${1:-}" == "--no-color" ]]; then
        export NO_COLOR=1
        echo "Running tests without color support"
    fi

    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║         SUMMARY MODULE VISUAL TESTS                            ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""

    # Setup test environment
    local test_root
    test_root=$(setup_test_dirs)

    # Test 1: display_summary with normal mode
    test_header "display_summary - Normal Installation"
    display_summary "normal" \
        "${test_root}/.aida" \
        "${test_root}/.claude" \
        "v0.2.0"

    # Test 2: display_summary with dev mode
    test_header "display_summary - Development Mode"
    display_summary "dev" \
        "${test_root}/.aida" \
        "${test_root}/.claude" \
        "v0.2.0"

    # Test 3: display_next_steps - normal mode
    test_header "display_next_steps - Normal Mode"
    display_next_steps "normal"

    # Test 4: display_next_steps - dev mode
    test_header "display_next_steps - Development Mode"
    display_next_steps "dev"

    # Test 5: display_success - simple
    test_header "display_success - Simple Success"
    display_success "Installation completed successfully!"

    # Test 6: display_success - with details
    test_header "display_success - Success with Details"
    display_success "Configuration updated" \
        "Your assistant is now configured with the 'jarvis' personality.
All templates have been installed to ~/.claude/commands/"

    # Test 7: display_error - simple
    test_header "display_error - Simple Error"
    display_error "Failed to create directory"

    # Test 8: display_error - with recovery steps
    test_header "display_error - Error with Recovery Steps"
    display_error "Failed to create symlink" "1. Check ~/.aida doesn't already exist
2. Ensure you have write permissions to $HOME
3. Run: rm -rf ~/.aida and try again
4. If problem persists, check disk space"

    # Test 9: display_upgrade_summary
    test_header "display_upgrade_summary - Upgrade from v0.1.6 to v0.2.0"
    display_upgrade_summary "v0.1.6" "v0.2.0" "3"

    # Test 10: display_upgrade_summary - no preserved files
    test_header "display_upgrade_summary - Clean Upgrade (No Preserved Files)"
    display_upgrade_summary "v0.1.5" "v0.2.0" "0"

    # Test 11: Helper functions
    test_header "Helper Functions - get_terminal_width"
    local width
    width=$(get_terminal_width)
    echo "Terminal width: $width columns"

    # Test 12: Helper functions - count_templates
    test_header "Helper Functions - count_templates"
    local count
    count=$(count_templates "${test_root}/.claude/commands")
    echo "Templates found: $count"
    echo "Expected: 3"
    if [[ "$count" == "3" ]]; then
        print_message "success" "Template count correct"
    else
        print_message "error" "Template count incorrect (got $count, expected 3)"
    fi

    # Test 13: Helper functions - count_agents
    test_header "Helper Functions - count_agents"
    count=$(count_agents "${test_root}/.claude/agents")
    echo "Agents found: $count"
    echo "Expected: 2"
    if [[ "$count" == "2" ]]; then
        print_message "success" "Agent count correct"
    else
        print_message "error" "Agent count incorrect (got $count, expected 2)"
    fi

    # Test 14: Box drawing
    test_header "Box Drawing - draw_box_header"
    draw_box_header "TEST HEADER"

    # Test 15: Box drawing - draw_box
    test_header "Box Drawing - draw_box with content"
    draw_box "SAMPLE BOX" <<EOF
This is line 1 of content
This is line 2 of content
This is line 3 of content
EOF

    # Test 16: Horizontal lines
    test_header "Horizontal Lines"
    echo "Default line:"
    draw_horizontal_line
    echo ""
    echo "60-character line:"
    draw_horizontal_line 60
    echo ""
    echo "Line with equals signs:"
    draw_horizontal_line 60 "="

    # Test 17: Full installation flow simulation
    test_header "Full Installation Flow - Normal Mode"
    echo "Simulating complete installation output..."
    echo ""
    display_summary "normal" \
        "${test_root}/.aida" \
        "${test_root}/.claude" \
        "v0.2.0"
    display_next_steps "normal"
    display_success "Installation completed successfully!"

    # Test 18: Full installation flow simulation - dev mode
    test_header "Full Installation Flow - Development Mode"
    echo "Simulating complete dev installation output..."
    echo ""
    display_summary "dev" \
        "${test_root}/.aida" \
        "${test_root}/.claude" \
        "v0.2.0"
    display_next_steps "dev"
    display_success "Development installation completed!"

    # Cleanup
    cleanup_test_dirs "$test_root"

    # Summary
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║              VISUAL TESTS COMPLETED                            ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "All $TEST_NUM test scenarios displayed."
    echo ""
    echo "Review the output above to verify:"
    echo "  ✓ Box drawing renders correctly"
    echo "  ✓ Colors work (if terminal supports them)"
    echo "  ✓ Text alignment is proper"
    echo "  ✓ Information is clear and complete"
    echo "  ✓ Next steps are actionable"
    echo "  ✓ Error messages include recovery guidance"
    echo ""
    echo "To test without colors: $0 --no-color"
    echo ""
}

# Run tests
main "$@"
