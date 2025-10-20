#!/usr/bin/env bash
#
# validate-prompts-module.sh - Validation Script for prompts.sh Module
#
# Description:
#   Automated validation script to verify prompts.sh module is ready for use.
#   Checks: sourcing, function exports, dependencies, documentation.
#
# Usage:
#   ./lib/installer-common/validate-prompts-module.sh
#

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# ANSI colors (simple, no dependency on colors.sh for validation)
readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0

#######################################
# Print test result
#######################################
print_result() {
    local status="$1"
    local message="$2"

    if [[ "$status" == "PASS" ]]; then
        echo -e "${GREEN}✓${NC} ${message}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    elif [[ "$status" == "FAIL" ]]; then
        echo -e "${RED}✗${NC} ${message}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    else
        echo -e "${YELLOW}⚠${NC} ${message}"
    fi
}

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  prompts.sh Module Validation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test 1: Check file exists
echo "Test 1: Module File Existence"
echo "------------------------------"
if [[ -f "${SCRIPT_DIR}/prompts.sh" ]]; then
    print_result "PASS" "prompts.sh exists"
else
    print_result "FAIL" "prompts.sh not found"
fi
echo ""

# Test 2: Check dependencies exist
echo "Test 2: Dependency Files"
echo "------------------------"
if [[ -f "${SCRIPT_DIR}/colors.sh" ]]; then
    print_result "PASS" "colors.sh exists"
else
    print_result "FAIL" "colors.sh not found"
fi

if [[ -f "${SCRIPT_DIR}/logging.sh" ]]; then
    print_result "PASS" "logging.sh exists"
else
    print_result "FAIL" "logging.sh not found"
fi
echo ""

# Test 3: Check module can be sourced
echo "Test 3: Module Sourcing"
echo "-----------------------"
if bash -c "source '${SCRIPT_DIR}/colors.sh' && source '${SCRIPT_DIR}/logging.sh' && source '${SCRIPT_DIR}/prompts.sh'" 2>/dev/null; then
    print_result "PASS" "Module sources successfully"
else
    print_result "FAIL" "Module failed to source"
fi
echo ""

# Test 4: Check required functions are exported
echo "Test 4: Function Exports"
echo "------------------------"
REQUIRED_FUNCTIONS=(
    "prompt_yes_no"
    "prompt_input"
    "prompt_select"
    "confirm_action"
    "prompt_input_validated"
    "prompt_info"
)

for func in "${REQUIRED_FUNCTIONS[@]}"; do
    if bash -c "source '${SCRIPT_DIR}/colors.sh' && source '${SCRIPT_DIR}/logging.sh' && source '${SCRIPT_DIR}/prompts.sh' && declare -F '$func'" >/dev/null 2>&1; then
        print_result "PASS" "Function exported: ${func}"
    else
        print_result "FAIL" "Function missing: ${func}"
    fi
done
echo ""

# Test 5: Check documentation exists
echo "Test 5: Documentation Files"
echo "----------------------------"
if [[ -f "${SCRIPT_DIR}/README-prompts.md" ]]; then
    print_result "PASS" "README-prompts.md exists"
else
    print_result "FAIL" "README-prompts.md not found"
fi

if [[ -f "${SCRIPT_DIR}/test-prompts.sh" ]]; then
    print_result "PASS" "test-prompts.sh exists"
else
    print_result "FAIL" "test-prompts.sh not found"
fi

if [[ -f "${SCRIPT_DIR}/EXAMPLE-install-prompts-usage.sh" ]]; then
    print_result "PASS" "EXAMPLE-install-prompts-usage.sh exists"
else
    print_result "FAIL" "EXAMPLE-install-prompts-usage.sh not found"
fi

if [[ -f "${SCRIPT_DIR}/TASK-001-SUMMARY.md" ]]; then
    print_result "PASS" "TASK-001-SUMMARY.md exists"
else
    print_result "FAIL" "TASK-001-SUMMARY.md not found"
fi
echo ""

# Test 6: Check file permissions
echo "Test 6: File Permissions"
echo "------------------------"
if [[ -r "${SCRIPT_DIR}/prompts.sh" ]]; then
    print_result "PASS" "prompts.sh is readable"
else
    print_result "FAIL" "prompts.sh is not readable"
fi

if [[ -x "${SCRIPT_DIR}/test-prompts.sh" ]]; then
    print_result "PASS" "test-prompts.sh is executable"
else
    print_result "FAIL" "test-prompts.sh is not executable"
fi

if [[ -x "${SCRIPT_DIR}/EXAMPLE-install-prompts-usage.sh" ]]; then
    print_result "PASS" "EXAMPLE-install-prompts-usage.sh is executable"
else
    print_result "FAIL" "EXAMPLE-install-prompts-usage.sh is not executable"
fi
echo ""

# Test 7: Check for basic shellcheck compliance markers
echo "Test 7: Code Quality Markers"
echo "-----------------------------"
if grep -q "set -euo pipefail" "${SCRIPT_DIR}/prompts.sh"; then
    print_result "PASS" "Uses 'set -euo pipefail'"
else
    print_result "FAIL" "Missing 'set -euo pipefail'"
fi

if grep -q "^#######################################" "${SCRIPT_DIR}/prompts.sh"; then
    print_result "PASS" "Uses Google Shell Style Guide comments"
else
    print_result "FAIL" "Missing proper function documentation"
fi
echo ""

# Test 8: Check module metadata
echo "Test 8: Module Metadata"
echo "-----------------------"
if grep -q "Part of: AIDA installer-common library" "${SCRIPT_DIR}/prompts.sh"; then
    print_result "PASS" "Contains library attribution"
else
    print_result "FAIL" "Missing library attribution"
fi

if grep -q "License: AGPL-3.0" "${SCRIPT_DIR}/prompts.sh"; then
    print_result "PASS" "Contains license information"
else
    print_result "FAIL" "Missing license information"
fi
echo ""

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Validation Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Tests Passed: ${TESTS_PASSED}"
echo "  Tests Failed: ${TESTS_FAILED}"
echo ""

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "${GREEN}✓ All validation tests passed!${NC}"
    echo ""
    echo "prompts.sh module is ready for use in Task 006 (install.sh refactoring)"
    echo ""
    exit 0
else
    echo -e "${RED}✗ Some validation tests failed${NC}"
    echo ""
    echo "Please review and fix the issues above before proceeding."
    echo ""
    exit 1
fi
