#!/usr/bin/env bash
#
# validate-directories-module.sh - Validation Tests for directories.sh Module
#
# Description:
#   Comprehensive validation tests for the directories.sh module.
#   Tests all functions for correctness, idempotency, cross-platform compatibility,
#   and edge case handling.
#
# Usage:
#   ./validate-directories-module.sh           # Run all tests
#   ./validate-directories-module.sh --verbose # Verbose output
#
# Author: oakensoul
# License: AGPL-3.0
# Repository: https://github.com/oakensoul/claude-personal-assistant
#

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# Verbose mode
VERBOSE=false
if [[ "${1:-}" == "--verbose" ]]; then
    VERBOSE=true
fi

# Test counters
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# Temporary directory for tests
TEST_DIR=""

# Color codes for output
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_RED='\033[0;31m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_NC='\033[0m' # No Color

#######################################
# Print test result
# Arguments:
#   $1 - Test name
#   $2 - Result (PASS or FAIL)
#   $3 - Message (optional)
#######################################
print_test_result() {
    local test_name="$1"
    local result="$2"
    local message="${3:-}"

    TESTS_TOTAL=$((TESTS_TOTAL + 1))

    if [[ "$result" == "PASS" ]]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo -e "${COLOR_GREEN}✓${COLOR_NC} ${test_name}"
        if [[ "$VERBOSE" == true && -n "$message" ]]; then
            echo "  ${message}"
        fi
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo -e "${COLOR_RED}✗${COLOR_NC} ${test_name}"
        if [[ -n "$message" ]]; then
            echo "  ${COLOR_RED}${message}${COLOR_NC}"
        fi
    fi
}

#######################################
# Setup test environment
#######################################
setup_test_env() {
    TEST_DIR=$(mktemp -d)
    if [[ "$VERBOSE" == true ]]; then
        echo -e "${COLOR_BLUE}Test directory: ${TEST_DIR}${COLOR_NC}"
    fi
}

#######################################
# Cleanup test environment
#######################################
cleanup_test_env() {
    if [[ -n "$TEST_DIR" && -d "$TEST_DIR" ]]; then
        rm -rf "$TEST_DIR"
    fi
}

#######################################
# Test: Module sources successfully
#######################################
test_module_sources() {
    local test_name="Module sources successfully"

    # Source dependencies first
    if source "${SCRIPT_DIR}/colors.sh" 2>/dev/null && \
       source "${SCRIPT_DIR}/logging.sh" 2>/dev/null && \
       source "${SCRIPT_DIR}/validation.sh" 2>/dev/null && \
       source "${SCRIPT_DIR}/directories.sh" 2>/dev/null; then
        print_test_result "$test_name" "PASS" "All dependencies loaded"
    else
        print_test_result "$test_name" "FAIL" "Failed to source module or dependencies"
        return 1
    fi
}

#######################################
# Test: All functions exported
#######################################
test_functions_exported() {
    local test_name="All functions exported"
    local required_functions=(
        "get_symlink_target"
        "validate_symlink"
        "create_symlink"
        "backup_existing"
        "create_claude_dirs"
        "create_namespace_dirs"
        "create_aida_dir"
    )

    local missing_functions=()
    for func in "${required_functions[@]}"; do
        if ! declare -f "$func" >/dev/null 2>&1; then
            missing_functions+=("$func")
        fi
    done

    if [[ ${#missing_functions[@]} -eq 0 ]]; then
        print_test_result "$test_name" "PASS" "All 7 functions available"
    else
        print_test_result "$test_name" "FAIL" "Missing functions: ${missing_functions[*]}"
        return 1
    fi
}

#######################################
# Test: create_aida_dir creates symlink correctly
#######################################
test_create_aida_dir() {
    local test_name="create_aida_dir creates symlink correctly"
    local repo_dir="${TEST_DIR}/repo"
    local aida_dir="${TEST_DIR}/.aida"

    # Create repo directory
    mkdir -p "$repo_dir"
    echo "test" > "$repo_dir/test.txt"

    # Create AIDA directory
    if create_aida_dir "$repo_dir" "$aida_dir" >/dev/null 2>&1; then
        # Verify symlink exists and points to correct target
        if [[ -L "$aida_dir" ]]; then
            local target
            target=$(get_symlink_target "$aida_dir" 2>/dev/null)
            if [[ "$target" == "$repo_dir" ]] || [[ "$(cd "$aida_dir" && pwd)" == "$repo_dir" ]]; then
                print_test_result "$test_name" "PASS" "Symlink created correctly"
            else
                print_test_result "$test_name" "FAIL" "Symlink points to wrong target: $target"
                return 1
            fi
        else
            print_test_result "$test_name" "FAIL" "Not a symlink"
            return 1
        fi
    else
        print_test_result "$test_name" "FAIL" "Function failed"
        return 1
    fi
}

#######################################
# Test: create_claude_dirs creates all directories
#######################################
test_create_claude_dirs() {
    local test_name="create_claude_dirs creates all directories"
    local claude_dir="${TEST_DIR}/.claude"

    # Create directories
    if create_claude_dirs "$claude_dir" >/dev/null 2>&1; then
        # Verify all expected directories exist
        local expected_dirs=(
            "$claude_dir"
            "$claude_dir/commands"
            "$claude_dir/agents"
            "$claude_dir/skills"
            "$claude_dir/config"
            "$claude_dir/knowledge"
            "$claude_dir/memory"
            "$claude_dir/memory/history"
        )

        local missing_dirs=()
        for dir in "${expected_dirs[@]}"; do
            if [[ ! -d "$dir" ]]; then
                missing_dirs+=("$dir")
            fi
        done

        if [[ ${#missing_dirs[@]} -eq 0 ]]; then
            print_test_result "$test_name" "PASS" "All 8 directories created"
        else
            print_test_result "$test_name" "FAIL" "Missing directories: ${#missing_dirs[@]}"
            return 1
        fi
    else
        print_test_result "$test_name" "FAIL" "Function failed"
        return 1
    fi
}

#######################################
# Test: create_namespace_dirs creates .aida subdirectories
#######################################
test_create_namespace_dirs() {
    local test_name="create_namespace_dirs creates .aida subdirectories"
    local claude_dir="${TEST_DIR}/.claude"

    # Create parent directories first
    create_claude_dirs "$claude_dir" >/dev/null 2>&1

    # Create namespace directories
    if create_namespace_dirs "$claude_dir" ".aida" >/dev/null 2>&1; then
        # Verify namespace directories exist
        local expected_dirs=(
            "$claude_dir/commands/.aida"
            "$claude_dir/agents/.aida"
            "$claude_dir/skills/.aida"
        )

        local missing_dirs=()
        for dir in "${expected_dirs[@]}"; do
            if [[ ! -d "$dir" ]]; then
                missing_dirs+=("$dir")
            fi
        done

        if [[ ${#missing_dirs[@]} -eq 0 ]]; then
            print_test_result "$test_name" "PASS" "All 3 namespace directories created"
        else
            print_test_result "$test_name" "FAIL" "Missing directories: ${#missing_dirs[@]}"
            return 1
        fi
    else
        print_test_result "$test_name" "FAIL" "Function failed"
        return 1
    fi
}

#######################################
# Test: backup_existing creates timestamped backup
#######################################
test_backup_existing() {
    local test_name="backup_existing creates timestamped backup"
    local test_file="${TEST_DIR}/test.txt"

    # Create test file
    echo "original content" > "$test_file"

    # Create backup
    if backup_existing "$test_file" >/dev/null 2>&1; then
        # Verify backup was created (check for .backup.* files)
        local backup_count
        backup_count=$(find "$TEST_DIR" -name "test.txt.backup.*" | wc -l)

        if [[ $backup_count -eq 1 ]]; then
            # Verify backup content
            local backup_file
            backup_file=$(find "$TEST_DIR" -name "test.txt.backup.*")
            if grep -q "original content" "$backup_file"; then
                print_test_result "$test_name" "PASS" "Backup created with correct content"
            else
                print_test_result "$test_name" "FAIL" "Backup content incorrect"
                return 1
            fi
        else
            print_test_result "$test_name" "FAIL" "Backup not created or multiple backups"
            return 1
        fi
    else
        print_test_result "$test_name" "FAIL" "Function failed"
        return 1
    fi
}

#######################################
# Test: create_symlink is idempotent
#######################################
test_create_symlink_idempotent() {
    local test_name="create_symlink is idempotent"
    local target="${TEST_DIR}/target"
    local link="${TEST_DIR}/link"

    # Create target
    mkdir -p "$target"
    echo "test" > "$target/file.txt"

    # Create symlink first time
    if ! create_symlink "$target" "$link" >/dev/null 2>&1; then
        print_test_result "$test_name" "FAIL" "First creation failed"
        return 1
    fi

    # Create symlink second time (should be idempotent)
    if create_symlink "$target" "$link" >/dev/null 2>&1; then
        # Verify symlink still points to correct target
        if validate_symlink "$link" "$target" 2>/dev/null; then
            print_test_result "$test_name" "PASS" "Second call succeeded (idempotent)"
        else
            print_test_result "$test_name" "FAIL" "Symlink validation failed after second call"
            return 1
        fi
    else
        print_test_result "$test_name" "FAIL" "Second creation failed"
        return 1
    fi
}

#######################################
# Test: create_symlink detects broken links
#######################################
test_create_symlink_broken() {
    local test_name="create_symlink detects broken links"
    local target="${TEST_DIR}/target"
    local link="${TEST_DIR}/link"

    # Create target and symlink
    mkdir -p "$target"
    ln -s "$target" "$link"

    # Remove target to break symlink
    rm -rf "$target"

    # Try to create symlink to new target
    local new_target="${TEST_DIR}/new_target"
    mkdir -p "$new_target"

    if create_symlink "$new_target" "$link" >/dev/null 2>&1; then
        # Verify symlink now points to new target
        if validate_symlink "$link" "$new_target" 2>/dev/null; then
            print_test_result "$test_name" "PASS" "Broken symlink detected and recreated"
        else
            print_test_result "$test_name" "FAIL" "Symlink validation failed"
            return 1
        fi
    else
        print_test_result "$test_name" "FAIL" "Failed to recreate broken symlink"
        return 1
    fi
}

#######################################
# Test: validate_symlink catches wrong targets
#######################################
test_validate_symlink_wrong_target() {
    local test_name="validate_symlink catches wrong targets"
    local target1="${TEST_DIR}/target1"
    local target2="${TEST_DIR}/target2"
    local link="${TEST_DIR}/link"

    # Create targets and symlink
    mkdir -p "$target1" "$target2"
    ln -s "$target1" "$link"

    # Validate symlink points to target1 (should pass)
    if ! validate_symlink "$link" "$target1" >/dev/null 2>&1; then
        print_test_result "$test_name" "FAIL" "Validation of correct target failed"
        return 1
    fi

    # Validate symlink points to target2 (should fail)
    if validate_symlink "$link" "$target2" >/dev/null 2>&1; then
        print_test_result "$test_name" "FAIL" "Validation of wrong target succeeded (should fail)"
        return 1
    else
        print_test_result "$test_name" "PASS" "Wrong target detected correctly"
    fi
}

#######################################
# Test: Cross-platform symlink reading
#######################################
test_cross_platform_symlink() {
    local test_name="Cross-platform symlink reading works"
    local target="${TEST_DIR}/target"
    local link="${TEST_DIR}/link"

    # Create target and symlink
    mkdir -p "$target"
    ln -s "$target" "$link"

    # Try to read symlink using get_symlink_target
    local read_target
    if read_target=$(get_symlink_target "$link" 2>/dev/null); then
        # Verify we got something back
        if [[ -n "$read_target" ]]; then
            print_test_result "$test_name" "PASS" "Symlink read successfully on $OSTYPE"
        else
            print_test_result "$test_name" "FAIL" "Empty target returned"
            return 1
        fi
    else
        print_test_result "$test_name" "FAIL" "Failed to read symlink"
        return 1
    fi
}

#######################################
# Main test runner
#######################################
main() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  directories.sh Module Validation Tests"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Setup test environment
    setup_test_env

    # Source dependencies (suppress output)
    source "${SCRIPT_DIR}/colors.sh" >/dev/null 2>&1 || {
        echo "Failed to source colors.sh"
        exit 1
    }
    source "${SCRIPT_DIR}/logging.sh" >/dev/null 2>&1 || {
        echo "Failed to source logging.sh"
        exit 1
    }
    source "${SCRIPT_DIR}/validation.sh" >/dev/null 2>&1 || {
        echo "Failed to source validation.sh"
        exit 1
    }

    # Run tests
    test_module_sources
    test_functions_exported
    test_create_aida_dir
    test_create_claude_dirs
    test_create_namespace_dirs
    test_backup_existing
    test_create_symlink_idempotent
    test_create_symlink_broken
    test_validate_symlink_wrong_target
    test_cross_platform_symlink

    # Cleanup
    cleanup_test_env

    # Print summary
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Test Summary"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Total Tests:  ${TESTS_TOTAL}"
    echo -e "Passed:       ${COLOR_GREEN}${TESTS_PASSED}${COLOR_NC}"
    echo -e "Failed:       ${COLOR_RED}${TESTS_FAILED}${COLOR_NC}"
    echo ""

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${COLOR_GREEN}✓ All tests passed!${COLOR_NC}"
        echo ""
        return 0
    else
        echo -e "${COLOR_RED}✗ Some tests failed${COLOR_NC}"
        echo ""
        return 1
    fi
}

# Trap for cleanup on exit
trap cleanup_test_env EXIT

# Run main
main "$@"
