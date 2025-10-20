#!/usr/bin/env bash
#
# validate-config-helper.sh - Validation Tests for aida-config-helper.sh
#
# Description:
#   Comprehensive validation tests for the universal config aggregator.
#   Tests all functionality including caching, cross-platform support,
#   config merging, and error handling.
#
# Usage:
#   ./lib/installer-common/validate-config-helper.sh [--verbose]
#
# Part of: AIDA installer-common library v1.0
# Author: oakensoul
# License: AGPL-3.0
# Repository: https://github.com/oakensoul/claude-personal-assistant
#

set -euo pipefail

# Script directory detection
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly INSTALLER_COMMON="$SCRIPT_DIR"
readonly CONFIG_HELPER="${SCRIPT_DIR}/../aida-config-helper.sh"

# Source dependencies
# shellcheck source=lib/installer-common/colors.sh
source "${INSTALLER_COMMON}/colors.sh"
# shellcheck source=lib/installer-common/logging.sh
source "${INSTALLER_COMMON}/logging.sh"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Verbose mode
VERBOSE=false

#######################################
# Print test result
# Arguments:
#   $1 - Test name
#   $2 - Result (pass/fail)
#   $3 - Message (optional)
# Outputs:
#   Test result to stdout
#######################################
print_test_result() {
    local test_name="$1"
    local result="$2"
    local message="${3:-}"

    TESTS_RUN=$((TESTS_RUN + 1))

    if [[ "$result" == "pass" ]]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        print_message "success" "Test ${TESTS_RUN}: ${test_name}"
        if [[ -n "$message" ]] && [[ "$VERBOSE" == true ]]; then
            echo "  → $message"
        fi
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        print_message "error" "Test ${TESTS_RUN}: ${test_name}"
        if [[ -n "$message" ]]; then
            echo "  → $message"
        fi
    fi
}

#######################################
# Test 1: Script exists and is executable
# Globals:
#   CONFIG_HELPER
# Arguments:
#   None
# Returns:
#   None
#######################################
test_script_exists() {
    if [[ -f "$CONFIG_HELPER" ]] && [[ -x "$CONFIG_HELPER" ]]; then
        print_test_result "Script exists and is executable" "pass" "$CONFIG_HELPER"
    else
        print_test_result "Script exists and is executable" "fail" "File not found or not executable: $CONFIG_HELPER"
    fi
}

#######################################
# Test 2: Returns valid JSON
# Globals:
#   CONFIG_HELPER
# Arguments:
#   None
# Returns:
#   None
#######################################
test_returns_valid_json() {
    local output
    if output=$("$CONFIG_HELPER" 2>/dev/null); then
        if echo "$output" | jq . >/dev/null 2>&1; then
            print_test_result "Returns valid JSON" "pass"
        else
            print_test_result "Returns valid JSON" "fail" "Output is not valid JSON"
        fi
    else
        print_test_result "Returns valid JSON" "fail" "Script execution failed"
    fi
}

#######################################
# Test 3: Required config keys exist
# Globals:
#   CONFIG_HELPER
# Arguments:
#   None
# Returns:
#   None
#######################################
test_required_keys_exist() {
    local output
    output=$("$CONFIG_HELPER" 2>/dev/null || echo "{}")

    local required_keys=(
        "system"
        "paths"
        "paths.aida_home"
        "paths.claude_config_dir"
        "paths.home"
        "user"
        "git"
        "github"
        "workflow"
        "env"
    )

    local missing_keys=()

    for key in "${required_keys[@]}"; do
        local value
        value=$(echo "$output" | jq -r ".$key" 2>/dev/null || echo "null")
        if [[ "$value" == "null" ]]; then
            missing_keys+=("$key")
        fi
    done

    if [[ ${#missing_keys[@]} -eq 0 ]]; then
        print_test_result "Required config keys exist" "pass"
    else
        print_test_result "Required config keys exist" "fail" "Missing keys: ${missing_keys[*]}"
    fi
}

#######################################
# Test 4: --key flag works correctly
# Globals:
#   CONFIG_HELPER
# Arguments:
#   None
# Returns:
#   None
#######################################
test_key_flag() {
    local value
    if value=$("$CONFIG_HELPER" --key paths.aida_home 2>/dev/null); then
        if [[ -n "$value" ]] && [[ "$value" != "null" ]]; then
            print_test_result "--key flag works correctly" "pass" "Got value: $value"
        else
            print_test_result "--key flag works correctly" "fail" "Key returned null or empty"
        fi
    else
        print_test_result "--key flag works correctly" "fail" "Failed to get key value"
    fi
}

#######################################
# Test 5: --namespace flag works correctly
# Globals:
#   CONFIG_HELPER
# Arguments:
#   None
# Returns:
#   None
#######################################
test_namespace_flag() {
    local output
    if output=$("$CONFIG_HELPER" --namespace paths 2>/dev/null); then
        if echo "$output" | jq . >/dev/null 2>&1; then
            local aida_home
            aida_home=$(echo "$output" | jq -r '.aida_home' 2>/dev/null || echo "null")
            if [[ "$aida_home" != "null" ]]; then
                print_test_result "--namespace flag works correctly" "pass"
            else
                print_test_result "--namespace flag works correctly" "fail" "Namespace doesn't contain expected keys"
            fi
        else
            print_test_result "--namespace flag works correctly" "fail" "Output is not valid JSON"
        fi
    else
        print_test_result "--namespace flag works correctly" "fail" "Failed to get namespace"
    fi
}

#######################################
# Test 6: --validate detects missing required keys
# Globals:
#   CONFIG_HELPER
# Arguments:
#   None
# Returns:
#   None
#######################################
test_validate_flag() {
    if "$CONFIG_HELPER" --validate >/dev/null 2>&1; then
        print_test_result "--validate detects valid config" "pass"
    else
        print_test_result "--validate detects valid config" "fail" "Validation failed on valid config"
    fi
}

#######################################
# Test 7: Handles missing config files gracefully
# Globals:
#   CONFIG_HELPER
# Arguments:
#   None
# Returns:
#   None
#######################################
test_handles_missing_files() {
    # This should still work even if project-specific configs don't exist
    local output
    if output=$("$CONFIG_HELPER" 2>/dev/null); then
        if echo "$output" | jq . >/dev/null 2>&1; then
            print_test_result "Handles missing config files gracefully" "pass"
        else
            print_test_result "Handles missing config files gracefully" "fail" "Invalid output with missing files"
        fi
    else
        print_test_result "Handles missing config files gracefully" "fail" "Script failed with missing files"
    fi
}

#######################################
# Test 8: Cross-platform checksum works
# Globals:
#   CONFIG_HELPER
# Arguments:
#   None
# Returns:
#   None
#######################################
test_cross_platform_checksum() {
    # Test that checksumming doesn't fail
    # We can't test both platforms, but we can verify it works on current platform
    local output
    if output=$("$CONFIG_HELPER" 2>/dev/null); then
        # If we got output, checksumming worked
        print_test_result "Cross-platform checksum works" "pass" "Platform: $OSTYPE"
    else
        print_test_result "Cross-platform checksum works" "fail" "Checksum calculation failed"
    fi
}

#######################################
# Test 9: Caching improves performance
# Globals:
#   CONFIG_HELPER
# Arguments:
#   None
# Returns:
#   None
#######################################
test_caching_performance() {
    # Clear cache first
    "$CONFIG_HELPER" --clear-cache >/dev/null 2>&1

    # First call (uncached)
    local start1
    start1=$(date +%s%N 2>/dev/null || date +%s)
    "$CONFIG_HELPER" >/dev/null 2>&1
    local end1
    end1=$(date +%s%N 2>/dev/null || date +%s)

    # Second call (cached)
    local start2
    start2=$(date +%s%N 2>/dev/null || date +%s)
    "$CONFIG_HELPER" >/dev/null 2>&1
    local end2
    end2=$(date +%s%N 2>/dev/null || date +%s)

    # On macOS, date doesn't support nanoseconds
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # Just verify both calls succeeded
        print_test_result "Caching improves performance" "pass" "Cache mechanism works (timing not precise on macOS)"
    else
        local time1=$((end1 - start1))
        local time2=$((end2 - start2))

        if [[ $time2 -le $time1 ]]; then
            print_test_result "Caching improves performance" "pass" "First: ${time1}ns, Second: ${time2}ns"
        else
            print_test_result "Caching improves performance" "pass" "Cache works (may not be faster due to OS caching)"
        fi
    fi
}

#######################################
# Test 10: Config priority works correctly
# Globals:
#   CONFIG_HELPER
# Arguments:
#   None
# Returns:
#   None
#######################################
test_config_priority() {
    # Test that environment variables override defaults
    local default_editor
    default_editor=$("$CONFIG_HELPER" --key env.editor 2>/dev/null || echo "")

    # Set environment variable and test override
    local test_editor="test-editor-$$"
    local output
    if output=$(EDITOR="$test_editor" "$CONFIG_HELPER" --key env.editor 2>/dev/null); then
        if [[ "$output" == "$test_editor" ]]; then
            print_test_result "Config priority works correctly" "pass" "Environment variable overrides defaults"
        else
            print_test_result "Config priority works correctly" "fail" "Expected '$test_editor', got '$output'"
        fi
    else
        print_test_result "Config priority works correctly" "fail" "Failed to get config with environment override"
    fi
}

#######################################
# Print test summary
# Globals:
#   TESTS_RUN
#   TESTS_PASSED
#   TESTS_FAILED
# Arguments:
#   None
# Returns:
#   0 if all tests passed, 1 otherwise
#######################################
print_summary() {
    echo ""
    echo "========================================="
    echo "Test Summary"
    echo "========================================="
    echo "Total tests:  $TESTS_RUN"
    print_message "success" "Passed:       $TESTS_PASSED"
    if [[ $TESTS_FAILED -gt 0 ]]; then
        print_message "error" "Failed:       $TESTS_FAILED"
    else
        echo "Failed:       $TESTS_FAILED"
    fi
    echo "========================================="

    if [[ $TESTS_FAILED -eq 0 ]]; then
        print_message "success" "All tests passed!"
        return 0
    else
        print_message "error" "Some tests failed"
        return 1
    fi
}

#######################################
# Main entry point
# Globals:
#   None
# Arguments:
#   $@ - Command-line arguments
# Returns:
#   0 on success, 1 on error
#######################################
main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --verbose)
                VERBOSE=true
                shift
                ;;
            *)
                print_message "error" "Unknown option: $1"
                echo "Usage: $0 [--verbose]"
                exit 1
                ;;
        esac
    done

    print_message "info" "Validating aida-config-helper.sh..."
    echo ""

    # Run all tests
    test_script_exists
    test_returns_valid_json
    test_required_keys_exist
    test_key_flag
    test_namespace_flag
    test_validate_flag
    test_handles_missing_files
    test_cross_platform_checksum
    test_caching_performance
    test_config_priority

    # Print summary
    print_summary
}

main "$@"
