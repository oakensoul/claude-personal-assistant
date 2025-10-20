#!/usr/bin/env bash
#
# test-install.sh - Automated AIDA Framework Installation Testing
#
# Description:
#   Runs automated tests of install.sh across multiple Docker environments
#
# Usage:
#   ./test-install.sh [OPTIONS]
#
# Options:
#   --verbose    Show detailed output
#   --env ENV    Test specific environment only
#   --help       Show this help
#
# Author: oakensoul
# License: AGPL-3.0

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
DOCKER_DIR="${SCRIPT_DIR}"
LOG_DIR="${SCRIPT_DIR}/logs"

# Map environment names to Dockerfiles
declare -A DOCKERFILE_MAP=(
    ["ubuntu-22"]="Dockerfile.ubuntu-22.04"
    ["ubuntu-20"]="Dockerfile.ubuntu-20.04"
    ["debian-12"]="Dockerfile.debian-12"
    ["ubuntu-minimal"]="Dockerfile.ubuntu-minimal"
)

# Test configuration
VERBOSE=false
SPECIFIC_ENV=""

# Color codes
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Test results
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

#######################################
# Print formatted message
#######################################
print_msg() {
    local type="$1"
    local message="$2"

    case "$type" in
        info)
            echo -e "${BLUE}ℹ${NC} ${message}"
            ;;
        success)
            echo -e "${GREEN}✓${NC} ${message}"
            ;;
        warning)
            echo -e "${YELLOW}⚠${NC} ${message}"
            ;;
        error)
            echo -e "${RED}✗${NC} ${message}" >&2
            ;;
        *)
            echo "${message}"
            ;;
    esac
}

#######################################
# Show usage
#######################################
usage() {
    cat << EOF
AIDA Framework Automated Testing

Usage: $(basename "$0") [OPTIONS]

Options:
    --verbose           Show detailed output
    --env ENV          Test specific environment (ubuntu-22, ubuntu-20, debian-12, ubuntu-minimal)
    --help             Display this help message

Environments:
    ubuntu-22          Ubuntu 22.04 LTS
    ubuntu-20          Ubuntu 20.04 LTS
    debian-12          Debian 12 (Bookworm)
    ubuntu-minimal     Ubuntu with missing dependencies

Examples:
    $(basename "$0")                    # Run all tests
    $(basename "$0") --verbose          # Run with detailed output
    $(basename "$0") --env ubuntu-22    # Test only Ubuntu 22.04

EOF
}

#######################################
# Setup test environment
#######################################
setup_test_env() {
    print_msg "info" "Setting up test environment..."

    # Create log directory
    mkdir -p "${LOG_DIR}"

    # Clean old logs
    rm -f "${LOG_DIR}"/*.log

    print_msg "success" "Test environment ready"
    echo ""
}

#######################################
# Build Docker images
#######################################
build_docker_images() {
    local env="$1"
    local dockerfile="${DOCKERFILE_MAP[$env]}"

    print_msg "info" "Building Docker image: ${env}..."

    local log_file="${LOG_DIR}/build-${env}.log"
    local image_name="aida-test-${env}"

    if docker build -t "${image_name}" \
        -f "${DOCKER_DIR}/${dockerfile}" \
        "${REPO_ROOT}" > "${log_file}" 2>&1; then
        print_msg "success" "Built ${env}"
        return 0
    else
        print_msg "error" "Failed to build ${env} (see ${log_file})"
        return 1
    fi
}

#######################################
# Test help flag
#######################################
test_help_flag() {
    local env="$1"
    local image_name="aida-test-${env}"
    local log_file="${LOG_DIR}/test-help-${env}.log"

    if [[ "$VERBOSE" == true ]]; then
        print_msg "info" "Testing --help flag in ${env}..."
    fi

    if docker run --rm \
        -v "${REPO_ROOT}:/workspace:ro" \
        -w /workspace \
        "${image_name}" \
        bash -c "./install.sh --help" > "${log_file}" 2>&1; then

        if grep -q "AIDA Framework Installation Script" "${log_file}"; then
            print_msg "success" "[${env}] Help flag test passed"
            TESTS_PASSED=$((TESTS_PASSED + 1))
            return 0
        fi
    fi

    print_msg "error" "[${env}] Help flag test failed"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
}

#######################################
# Test dependency validation (minimal env only)
#######################################
test_dependency_validation() {
    local env="$1"
    local image_name="aida-test-${env}"
    local log_file="${LOG_DIR}/test-deps-${env}.log"

    if [[ "$env" != "ubuntu-minimal" ]]; then
        if [[ "$VERBOSE" == true ]]; then
            print_msg "info" "[${env}] Skipping dependency validation test (only runs on ubuntu-minimal)"
        fi
        TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
        return 0
    fi

    if [[ "$VERBOSE" == true ]]; then
        print_msg "info" "Testing dependency validation in ${env}..."
    fi

    # Should fail because git and rsync are missing
    if docker run --rm \
        -v "${REPO_ROOT}:/workspace:ro" \
        -w /workspace \
        "${image_name}" \
        bash -c "./install.sh" < /dev/null > "${log_file}" 2>&1; then

        print_msg "error" "[${env}] Dependency validation should have failed but didn't"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    else
        # Check if error messages mention missing dependencies
        if grep -q "Required command not found" "${log_file}"; then
            print_msg "success" "[${env}] Dependency validation test passed"
            TESTS_PASSED=$((TESTS_PASSED + 1))
            return 0
        fi
    fi

    print_msg "error" "[${env}] Dependency validation test failed"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
}

#######################################
# Test normal installation
#######################################
test_normal_installation() {
    local env="$1"
    local image_name="aida-test-${env}"
    local log_file="${LOG_DIR}/test-install-${env}.log"

    # Skip minimal environment (it should fail dependency checks)
    if [[ "$env" == "ubuntu-minimal" ]]; then
        if [[ "$VERBOSE" == true ]]; then
            print_msg "info" "[${env}] Skipping normal installation test (missing dependencies by design)"
        fi
        TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
        return 0
    fi

    if [[ "$VERBOSE" == true ]]; then
        print_msg "info" "Testing normal installation in ${env}..."
    fi

    # Provide automated input: assistant name and personality choice
    if echo -e "testassistant\n1\n" | docker run --rm -i \
        -v "${REPO_ROOT}:/workspace:ro" \
        -w /workspace \
        "${image_name}" \
        bash -c "./install.sh" > "${log_file}" 2>&1; then

        # Verify success message
        if grep -q "Installation completed successfully" "${log_file}"; then
            print_msg "success" "[${env}] Normal installation test passed"
            TESTS_PASSED=$((TESTS_PASSED + 1))
            return 0
        fi
    fi

    print_msg "error" "[${env}] Normal installation test failed"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
}

#######################################
# Test dev mode installation
#######################################
test_dev_installation() {
    local env="$1"
    local image_name="aida-test-${env}"
    local log_file="${LOG_DIR}/test-dev-${env}.log"

    # Skip minimal environment
    if [[ "$env" == "ubuntu-minimal" ]]; then
        if [[ "$VERBOSE" == true ]]; then
            print_msg "info" "[${env}] Skipping dev mode installation test (missing dependencies by design)"
        fi
        TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
        return 0
    fi

    if [[ "$VERBOSE" == true ]]; then
        print_msg "info" "Testing dev mode installation in ${env}..."
    fi

    # Provide automated input
    if echo -e "devtest\n2\n" | docker run --rm -i \
        -v "${REPO_ROOT}:/workspace:ro" \
        -w /workspace \
        "${image_name}" \
        bash -c "./install.sh --dev" > "${log_file}" 2>&1; then

        # Verify dev mode messages
        if grep -q "Development mode is active" "${log_file}"; then
            print_msg "success" "[${env}] Dev mode installation test passed"
            TESTS_PASSED=$((TESTS_PASSED + 1))
            return 0
        fi
    fi

    print_msg "error" "[${env}] Dev mode installation test failed"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
}

#######################################
# Run all tests for an environment
#######################################
test_environment() {
    local env="$1"

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_msg "info" "Testing environment: ${env}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Build image first
    if ! build_docker_images "${env}"; then
        print_msg "error" "Skipping tests for ${env} due to build failure"
        TESTS_FAILED=$((TESTS_FAILED + 4))
        return 1
    fi

    # Run test suite
    test_help_flag "${env}"
    test_dependency_validation "${env}"
    test_normal_installation "${env}"
    test_dev_installation "${env}"

    echo ""
}

#######################################
# Display test summary
#######################################
display_summary() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Test Summary"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    print_msg "success" "Passed:  ${TESTS_PASSED}"
    print_msg "error"   "Failed:  ${TESTS_FAILED}"
    print_msg "warning" "Skipped: ${TESTS_SKIPPED}"
    echo ""

    if [[ ${TESTS_SKIPPED} -gt 0 ]]; then
        echo "Why tests are skipped:"
        echo "  • ubuntu-minimal: Skips install tests (tests dependency validation only)"
        echo "  • Full environments: Skip dependency tests (all dependencies present)"
        echo "  This is expected behavior - each environment tests different scenarios."
        echo ""
    fi

    echo "Logs saved to: ${LOG_DIR}"
    echo ""

    if [[ $TESTS_FAILED -eq 0 ]]; then
        print_msg "success" "All tests passed!"
        return 0
    else
        print_msg "error" "Some tests failed. Check logs for details."
        return 1
    fi
}

#######################################
# Main function
#######################################
main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --verbose)
                VERBOSE=true
                shift
                ;;
            --env)
                SPECIFIC_ENV="$2"
                shift 2
                ;;
            --help)
                usage
                exit 0
                ;;
            *)
                print_msg "error" "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done

    # Header
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  AIDA Framework Automated Testing"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    setup_test_env

    # Determine which environments to test
    local environments=()
    if [[ -n "$SPECIFIC_ENV" ]]; then
        environments=("$SPECIFIC_ENV")
    else
        environments=("ubuntu-22" "ubuntu-20" "debian-12" "ubuntu-minimal")
    fi

    # Run tests
    for env in "${environments[@]}"; do
        test_environment "$env"
    done

    # Show summary
    display_summary
}

main "$@"
