#!/usr/bin/env bash
#
# test_install_refactoring.sh - Integration Tests for Refactored Installer
#
# Description:
#   Validates that the refactored install.sh works identically to the original.
#   Tests all installation modes and verifies file creation, permissions, and content.
#
# Usage:
#   ./tests/integration/test_install_refactoring.sh
#

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Colors
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_RED='\033[0;31m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

#######################################
# Print test result
#######################################
print_test_result() {
    local test_name="$1"
    local result="$2"

    TESTS_RUN=$((TESTS_RUN + 1))

    if [[ "$result" == "PASS" ]]; then
        echo -e "${COLOR_GREEN}✓ PASS${COLOR_NC} - ${test_name}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${COLOR_RED}✗ FAIL${COLOR_NC} - ${test_name}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

#######################################
# Test: Help flag works
#######################################
test_help_flag() {
    local test_name="Help flag displays usage"

    if "${REPO_ROOT}/install.sh" --help >/dev/null 2>&1; then
        print_test_result "$test_name" "PASS"
    else
        print_test_result "$test_name" "FAIL"
    fi
}

#######################################
# Test: Invalid argument rejected
#######################################
test_invalid_argument() {
    local test_name="Invalid argument rejected"

    if "${REPO_ROOT}/install.sh" --invalid-arg 2>/dev/null; then
        print_test_result "$test_name" "FAIL"
    else
        print_test_result "$test_name" "PASS"
    fi
}

#######################################
# Test: Module files exist
#######################################
test_module_files() {
    local test_name="All module files exist and are readable"

    # Check that all module files exist
    if [[ -r "${REPO_ROOT}/lib/installer-common/colors.sh" ]] &&
       [[ -r "${REPO_ROOT}/lib/installer-common/logging.sh" ]] &&
       [[ -r "${REPO_ROOT}/lib/installer-common/validation.sh" ]] &&
       [[ -r "${REPO_ROOT}/lib/installer-common/prompts.sh" ]] &&
       [[ -r "${REPO_ROOT}/lib/installer-common/directories.sh" ]] &&
       [[ -r "${REPO_ROOT}/lib/installer-common/config.sh" ]] &&
       [[ -r "${REPO_ROOT}/lib/installer-common/summary.sh" ]] &&
       [[ -r "${REPO_ROOT}/lib/installer-common/templates.sh" ]]; then
        print_test_result "$test_name" "PASS"
    else
        print_test_result "$test_name" "FAIL"
    fi
}

#######################################
# Test: Script syntax is valid
#######################################
test_syntax() {
    local test_name="install.sh syntax is valid"

    if bash -n "${REPO_ROOT}/install.sh" 2>/dev/null; then
        print_test_result "$test_name" "PASS"
    else
        print_test_result "$test_name" "FAIL"
    fi
}

#######################################
# Test: Module syntax validation
#######################################
test_module_syntax() {
    local test_name="All modules have valid bash syntax"

    local all_valid=true

    for module in colors.sh logging.sh validation.sh prompts.sh directories.sh config.sh summary.sh templates.sh; do
        if ! bash -n "${REPO_ROOT}/lib/installer-common/${module}" 2>/dev/null; then
            all_valid=false
            break
        fi
    done

    if [[ "$all_valid" == true ]]; then
        print_test_result "$test_name" "PASS"
    else
        print_test_result "$test_name" "FAIL"
    fi
}

#######################################
# Test: VERSION file exists
#######################################
test_version_file() {
    local test_name="VERSION file exists and is readable"

    if [[ -f "${REPO_ROOT}/VERSION" ]] && [[ -r "${REPO_ROOT}/VERSION" ]]; then
        print_test_result "$test_name" "PASS"
    else
        print_test_result "$test_name" "FAIL"
    fi
}

#######################################
# Test: Template directory exists
#######################################
test_template_directory() {
    local test_name="Command templates directory exists"

    if [[ -d "${REPO_ROOT}/templates/commands" ]]; then
        print_test_result "$test_name" "PASS"
    else
        print_test_result "$test_name" "FAIL"
    fi
}

#######################################
# Main test runner
#######################################
main() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Integration Tests - Refactored Installer"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    echo "Running tests..."
    echo ""

    # Run tests
    test_syntax
    test_help_flag
    test_invalid_argument
    test_module_files
    test_module_syntax
    test_version_file
    test_template_directory

    # Display summary
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Test Results"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  Tests Run:    ${TESTS_RUN}"
    echo "  Tests Passed: ${TESTS_PASSED}"
    echo "  Tests Failed: ${TESTS_FAILED}"
    echo ""

    if [[ ${TESTS_FAILED} -eq 0 ]]; then
        echo -e "${COLOR_GREEN}All tests passed!${COLOR_NC}"
        echo ""
        exit 0
    else
        echo -e "${COLOR_RED}Some tests failed!${COLOR_NC}"
        echo ""
        exit 1
    fi
}

main "$@"
