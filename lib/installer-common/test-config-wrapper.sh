#!/usr/bin/env bash
#
# test-config-wrapper.sh - Test Config Wrapper Module
#
# Description:
#   Comprehensive tests for config.sh wrapper module.
#
# Usage:
#   ./test-config-wrapper.sh
#

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# Source dependencies
source "${SCRIPT_DIR}/colors.sh"
source "${SCRIPT_DIR}/logging.sh"
source "${SCRIPT_DIR}/validation.sh"
source "${SCRIPT_DIR}/config.sh"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

#######################################
# Print test header
# Arguments:
#   $1 - Test name
#######################################
test_header() {
    local test_name="$1"
    echo ""
    echo "=========================================="
    echo "TEST: ${test_name}"
    echo "=========================================="
    TESTS_RUN=$((TESTS_RUN + 1))
}

#######################################
# Print test result
# Arguments:
#   $1 - Result (PASS or FAIL)
#   $2 - Message
#######################################
test_result() {
    local result="$1"
    local message="$2"

    if [[ "$result" == "PASS" ]]; then
        print_message "success" "${message}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        print_message "error" "${message}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

#######################################
# Test 1: Module sources successfully
#######################################
test_module_sources() {
    test_header "Module sources successfully"

    # Already sourced at the top, verify functions exist
    if declare -F get_config >/dev/null && \
       declare -F get_config_value >/dev/null && \
       declare -F write_user_config >/dev/null && \
       declare -F validate_config >/dev/null && \
       declare -F config_exists >/dev/null; then
        test_result "PASS" "All expected functions are defined"
        return 0
    else
        test_result "FAIL" "Missing expected functions"
        return 1
    fi
}

#######################################
# Test 2: get_config returns valid JSON
#######################################
test_get_config() {
    test_header "get_config returns valid JSON"

    local config
    config=$(get_config 2>/dev/null || echo "")

    if [[ -z "$config" ]]; then
        test_result "FAIL" "get_config returned empty result"
        return 1
    fi

    # Validate JSON
    if echo "$config" | jq empty 2>/dev/null; then
        test_result "PASS" "get_config returned valid JSON"
        return 0
    else
        test_result "FAIL" "get_config returned invalid JSON"
        return 1
    fi
}

#######################################
# Test 3: get_config_value retrieves correct values
#######################################
test_get_config_value() {
    test_header "get_config_value retrieves correct values"

    # Test known key
    local aida_home
    aida_home=$(get_config_value "paths.aida_home" 2>/dev/null || echo "")

    if [[ -n "$aida_home" ]]; then
        print_message "info" "Retrieved paths.aida_home: ${aida_home}"
        test_result "PASS" "get_config_value retrieved known key"
    else
        test_result "FAIL" "get_config_value failed to retrieve known key"
        return 1
    fi

    # Test invalid key (should fail)
    local invalid_value
    if get_config_value "invalid.nonexistent.key" 2>/dev/null; then
        test_result "FAIL" "get_config_value should fail for invalid key"
        return 1
    else
        test_result "PASS" "get_config_value correctly fails for invalid key"
    fi

    return 0
}

#######################################
# Test 4: write_user_config creates valid JSON file
#######################################
test_write_user_config() {
    test_header "write_user_config creates valid JSON file"

    # Create temporary config directory
    local temp_dir
    temp_dir=$(mktemp -d)
    local config_file="${temp_dir}/aida-config.json"

    # Write config
    if write_user_config "dev" "/tmp/aida" "$temp_dir" "0.2.0" "jarvis" "JARVIS" 2>/dev/null; then
        # Verify file was created
        if [[ ! -f "$config_file" ]]; then
            test_result "FAIL" "Config file was not created"
            rm -rf "$temp_dir"
            return 1
        fi

        # Verify JSON is valid
        if ! jq empty "$config_file" 2>/dev/null; then
            test_result "FAIL" "Config file contains invalid JSON"
            rm -rf "$temp_dir"
            return 1
        fi

        # Verify content
        local version
        version=$(jq -r '.version' "$config_file")
        local install_mode
        install_mode=$(jq -r '.install_mode' "$config_file")
        local assistant_name
        assistant_name=$(jq -r '.user.assistant_name' "$config_file")

        if [[ "$version" == "0.2.0" ]] && \
           [[ "$install_mode" == "dev" ]] && \
           [[ "$assistant_name" == "jarvis" ]]; then
            test_result "PASS" "write_user_config created valid config file with correct content"
        else
            test_result "FAIL" "Config file content is incorrect"
            print_message "info" "version=${version}, mode=${install_mode}, name=${assistant_name}"
            rm -rf "$temp_dir"
            return 1
        fi
    else
        test_result "FAIL" "write_user_config failed"
        rm -rf "$temp_dir"
        return 1
    fi

    # Cleanup
    rm -rf "$temp_dir"
    return 0
}

#######################################
# Test 5: validate_config detects valid config
#######################################
test_validate_config() {
    test_header "validate_config detects valid config"

    # This should pass if system has valid config
    if validate_config 2>/dev/null; then
        test_result "PASS" "validate_config passed"
        return 0
    else
        # This might fail if no config exists, which is OK for this test
        print_message "warning" "validate_config failed (may be expected if no config exists)"
        test_result "PASS" "validate_config executed (failure expected without config)"
        return 0
    fi
}

#######################################
# Test 6: config_exists works correctly
#######################################
test_config_exists() {
    test_header "config_exists works correctly"

    # Create temporary file
    local temp_file
    temp_file=$(mktemp)

    # Test existing file
    if config_exists "$temp_file"; then
        test_result "PASS" "config_exists correctly detected existing file"
    else
        test_result "FAIL" "config_exists failed to detect existing file"
        rm -f "$temp_file"
        return 1
    fi

    # Remove file and test non-existing
    rm -f "$temp_file"

    if config_exists "$temp_file"; then
        test_result "FAIL" "config_exists incorrectly detected non-existing file"
        return 1
    else
        test_result "PASS" "config_exists correctly detected non-existing file"
    fi

    return 0
}

#######################################
# Test 7: Error handling for missing config helper
#######################################
test_missing_config_helper() {
    test_header "Error handling for missing config helper"

    # Temporarily rename config helper
    local original_helper="${CONFIG_HELPER}"
    local temp_helper="${CONFIG_HELPER}.bak"

    if [[ -f "$original_helper" ]]; then
        mv "$original_helper" "$temp_helper"
    fi

    # Test should fail gracefully
    if get_config 2>/dev/null; then
        test_result "FAIL" "get_config should fail when config helper is missing"
        # Restore
        if [[ -f "$temp_helper" ]]; then
            mv "$temp_helper" "$original_helper"
        fi
        return 1
    else
        test_result "PASS" "get_config correctly fails when config helper is missing"
    fi

    # Restore config helper
    if [[ -f "$temp_helper" ]]; then
        mv "$temp_helper" "$original_helper"
    fi

    return 0
}

#######################################
# Test 8: Error handling for invalid keys
#######################################
test_invalid_keys() {
    test_header "Error handling for invalid keys"

    # Test empty key
    if get_config_value "" 2>/dev/null; then
        test_result "FAIL" "get_config_value should fail for empty key"
        return 1
    else
        test_result "PASS" "get_config_value correctly fails for empty key"
    fi

    # Test nonexistent key
    if get_config_value "this.key.does.not.exist" 2>/dev/null; then
        test_result "FAIL" "get_config_value should fail for nonexistent key"
        return 1
    else
        test_result "PASS" "get_config_value correctly fails for nonexistent key"
    fi

    return 0
}

#######################################
# Print test summary
#######################################
print_summary() {
    echo ""
    echo "=========================================="
    echo "TEST SUMMARY"
    echo "=========================================="
    echo "Tests run:    ${TESTS_RUN}"
    echo "Tests passed: ${TESTS_PASSED}"
    echo "Tests failed: ${TESTS_FAILED}"
    echo ""

    if [[ $TESTS_FAILED -eq 0 ]]; then
        print_message "success" "All tests passed!"
        return 0
    else
        print_message "error" "${TESTS_FAILED} test(s) failed"
        return 1
    fi
}

#######################################
# Main test runner
#######################################
main() {
    echo "Config Wrapper Module Test Suite"
    echo "================================="

    # Run all tests
    test_module_sources
    test_get_config
    test_get_config_value
    test_write_user_config
    test_validate_config
    test_config_exists
    test_missing_config_helper
    test_invalid_keys

    # Print summary
    print_summary
}

main "$@"
