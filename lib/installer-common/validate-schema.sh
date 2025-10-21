#!/usr/bin/env bash
#
# validate-schema.sh - JSON Schema Validator
#
# Description:
#   Validates JSON configuration files against JSON Schema using tiered validator
#   fallback for maximum compatibility across different environments.
#
# Validator Priority:
#   1. ajv-cli (best: full schema validation with detailed errors)
#   2. check-jsonschema (good: schema validation with clear errors)
#   3. jq (fallback: syntax validation only, warns about limited capability)
#
# Dependencies:
#   - colors.sh (must be sourced)
#   - logging.sh (must be sourced)
#   - One of: ajv-cli, check-jsonschema, or jq
#
# Part of: AIDA installer-common library v1.0
# Usage:
#   ./validate-schema.sh [options] <config-file> [config-file...]
#
# Author: oakensoul
# License: AGPL-3.0
# Repository: https://github.com/oakensoul/claude-personal-assistant
#

set -euo pipefail

# Script directory and paths
# Only set SCRIPT_DIR if not already set (for library sourcing compatibility)
if [[ -z "${SCRIPT_DIR:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    readonly SCRIPT_DIR
fi
readonly DEFAULT_SCHEMA="${SCRIPT_DIR}/config-schema.json"

# Source shared utilities
# shellcheck source=lib/installer-common/colors.sh
source "${SCRIPT_DIR}/colors.sh"
# shellcheck source=lib/installer-common/logging.sh
source "${SCRIPT_DIR}/logging.sh"

# Global variables
VERBOSE=0
SCHEMA_PATH="$DEFAULT_SCHEMA"
VALIDATOR=""

#######################################
# Show usage information
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Usage documentation to stdout
#######################################
show_help() {
    cat <<EOF
Usage: $(basename "$0") [options] <config-file> [config-file...]

Validate JSON configuration files against JSON Schema.

OPTIONS:
    -h, --help              Show this help message
    -v, --verbose           Enable verbose output
    -s, --schema PATH       Use custom schema file (default: config-schema.json)

ARGUMENTS:
    config-file             One or more JSON files to validate

EXIT CODES:
    0   All files valid
    1   Validation failed (schema violations)
    2   Error (missing file, invalid JSON syntax, etc.)

VALIDATORS:
    This script uses tiered validator fallback for compatibility:

    1. ajv-cli (preferred)
       - Full JSON Schema Draft-07 support
       - Detailed error messages with line numbers
       - Install: npm install -g ajv-cli

    2. check-jsonschema (good)
       - Good JSON Schema support
       - Clear, user-friendly error messages
       - Install: pip install check-jsonschema

    3. jq (fallback)
       - JSON syntax validation only
       - No schema validation capability
       - Warning displayed when used

EXAMPLES:
    # Validate single file
    $(basename "$0") config.json

    # Validate with custom schema
    $(basename "$0") --schema custom-schema.json config.json

    # Validate multiple files
    $(basename "$0") config1.json config2.json config3.json

    # Verbose mode
    $(basename "$0") --verbose config.json

For more information: docs/configuration/schema-reference.md
EOF
}

#######################################
# Detect available JSON validator
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   0 if validator found, 1 if only jq available
# Outputs:
#   Validator name to stdout (ajv, check-jsonschema, jq, or none)
#######################################
detect_validator() {
    # Check for ajv-cli (best validator)
    if command -v ajv &>/dev/null; then
        echo "ajv"
        return 0
    fi

    # Check for check-jsonschema (good validator)
    if command -v check-jsonschema &>/dev/null; then
        echo "check-jsonschema"
        return 0
    fi

    # Check for jq (fallback - syntax only)
    if command -v jq &>/dev/null; then
        echo "jq"
        return 1
    fi

    # No validator available
    echo "none"
    return 2
}

#######################################
# Validate using ajv-cli
# Globals:
#   SCHEMA_PATH
#   VERBOSE
# Arguments:
#   $1 - Config file path
# Returns:
#   0 if valid, 1 if invalid
# Outputs:
#   Validation errors to stderr
#######################################
validate_with_ajv() {
    local config_file="$1"

    if [[ $VERBOSE -eq 1 ]]; then
        print_message "info" "Validating with ajv-cli: ${config_file}"
    fi

    # Run ajv validation
    local output
    if output=$(ajv validate -s "$SCHEMA_PATH" -d "$config_file" 2>&1); then
        if [[ $VERBOSE -eq 1 ]]; then
            print_message "success" "Schema validation passed"
        fi
        return 0
    else
        # Parse ajv error output
        print_message "error" "Schema validation failed: ${config_file}"
        echo ""
        echo "Validation errors:"
        echo "$output" | grep -E "(data|schema)" || echo "$output"
        echo ""
        return 1
    fi
}

#######################################
# Validate using check-jsonschema
# Globals:
#   SCHEMA_PATH
#   VERBOSE
# Arguments:
#   $1 - Config file path
# Returns:
#   0 if valid, 1 if invalid
# Outputs:
#   Validation errors to stderr
#######################################
validate_with_check_jsonschema() {
    local config_file="$1"

    if [[ $VERBOSE -eq 1 ]]; then
        print_message "info" "Validating with check-jsonschema: ${config_file}"
    fi

    # Run check-jsonschema validation
    local output
    if output=$(check-jsonschema --schemafile "$SCHEMA_PATH" "$config_file" 2>&1); then
        if [[ $VERBOSE -eq 1 ]]; then
            print_message "success" "Schema validation passed"
        fi
        return 0
    else
        # Display check-jsonschema error output
        print_message "error" "Schema validation failed: ${config_file}"
        echo ""
        echo "$output"
        echo ""
        return 1
    fi
}

#######################################
# Validate using jq (syntax only)
# Globals:
#   VERBOSE
# Arguments:
#   $1 - Config file path
# Returns:
#   0 if valid JSON, 1 if invalid
# Outputs:
#   Validation errors to stderr
#######################################
validate_with_jq() {
    local config_file="$1"

    # Warn user about limited validation
    print_message "warning" "Using jq fallback - syntax validation only"
    print_message "info" "For full schema validation, install ajv-cli or check-jsonschema"
    print_message "info" "  npm install -g ajv-cli"
    print_message "info" "  pip install check-jsonschema"
    echo ""

    if [[ $VERBOSE -eq 1 ]]; then
        print_message "info" "Validating JSON syntax with jq: ${config_file}"
    fi

    # Run jq syntax validation
    local output
    if output=$(jq empty "$config_file" 2>&1); then
        if [[ $VERBOSE -eq 1 ]]; then
            print_message "success" "JSON syntax is valid"
        fi
        print_message "warning" "Schema validation skipped (jq fallback mode)"
        return 0
    else
        # Display jq error output
        print_message "error" "Invalid JSON syntax: ${config_file}"
        echo ""
        echo "$output"
        echo ""
        return 1
    fi
}

#######################################
# Validate a single config file
# Globals:
#   VALIDATOR
#   SCHEMA_PATH
#   VERBOSE
# Arguments:
#   $1 - Config file path
# Returns:
#   0 if valid, 1 if validation failed, 2 if error
# Outputs:
#   Validation results to stdout/stderr
#######################################
validate_config() {
    local config_file="$1"

    # Check file exists
    if [[ ! -f "$config_file" ]]; then
        print_message "error" "File not found: ${config_file}"
        return 2
    fi

    # Check file is readable
    if [[ ! -r "$config_file" ]]; then
        print_message "error" "File not readable: ${config_file}"
        return 2
    fi

    # Dispatch to appropriate validator
    case "$VALIDATOR" in
        ajv)
            validate_with_ajv "$config_file"
            return $?
            ;;
        check-jsonschema)
            validate_with_check_jsonschema "$config_file"
            return $?
            ;;
        jq)
            validate_with_jq "$config_file"
            return $?
            ;;
        none)
            print_message "error" "No JSON validator available"
            print_message "info" "Install one of:"
            print_message "info" "  npm install -g ajv-cli"
            print_message "info" "  pip install check-jsonschema"
            print_message "info" "  brew install jq (macOS) or apt-get install jq (Linux)"
            return 2
            ;;
        *)
            print_message "error" "Unknown validator: ${VALIDATOR}"
            return 2
            ;;
    esac
}

#######################################
# Main entry point
# Globals:
#   VERBOSE
#   SCHEMA_PATH
#   VALIDATOR
# Arguments:
#   Command-line arguments
# Returns:
#   0 if all files valid, 1 if any validation failed, 2 if error
#######################################
main() {
    local config_files=()

    # Parse command-line arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=1
                shift
                ;;
            -s|--schema)
                if [[ -z "${2:-}" ]]; then
                    print_message "error" "Option --schema requires an argument"
                    echo ""
                    show_help
                    exit 2
                fi
                SCHEMA_PATH="$2"
                shift 2
                ;;
            -*)
                print_message "error" "Unknown option: $1"
                echo ""
                show_help
                exit 2
                ;;
            *)
                config_files+=("$1")
                shift
                ;;
        esac
    done

    # Validate arguments
    if [[ ${#config_files[@]} -eq 0 ]]; then
        print_message "error" "No config files specified"
        echo ""
        show_help
        exit 2
    fi

    # Check schema file exists
    if [[ ! -f "$SCHEMA_PATH" ]]; then
        print_message "error" "Schema file not found: ${SCHEMA_PATH}"
        exit 2
    fi

    # Detect validator
    local validator_status
    VALIDATOR=$(detect_validator) || validator_status=$?
    # If detect_validator succeeded, set validator_status to 0
    validator_status=${validator_status:-0}

    if [[ $VERBOSE -eq 1 ]]; then
        print_message "info" "Detected validator: ${VALIDATOR}"
        print_message "info" "Schema: ${SCHEMA_PATH}"
        print_message "info" "Config files: ${#config_files[@]}"
    fi

    # Warn if no proper validator available
    if [[ $validator_status -eq 2 ]]; then
        print_message "error" "No JSON validator available"
        print_message "info" "Install one of:"
        print_message "info" "  npm install -g ajv-cli (recommended)"
        print_message "info" "  pip install check-jsonschema"
        print_message "info" "  brew install jq (macOS) or apt-get install jq (Linux)"
        exit 2
    fi

    # Validate each config file
    local validation_errors=0
    local system_errors=0

    for config_file in "${config_files[@]}"; do
        if [[ $VERBOSE -eq 1 ]] || [[ ${#config_files[@]} -gt 1 ]]; then
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            print_message "info" "Validating: ${config_file}"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        fi

        # Call validate_config and capture result (use || true to prevent set -e from exiting)
        local result=0
        validate_config "$config_file" || result=$?

        if [[ $result -eq 1 ]]; then
            validation_errors=$((validation_errors + 1))
        elif [[ $result -eq 2 ]]; then
            system_errors=$((system_errors + 1))
        else
            if [[ $VERBOSE -eq 1 ]] || [[ ${#config_files[@]} -gt 1 ]]; then
                print_message "success" "Valid: ${config_file}"
            fi
        fi
    done

    # Print summary for multiple files
    if [[ ${#config_files[@]} -gt 1 ]]; then
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        print_message "info" "Validation Summary"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Total files: ${#config_files[@]}"
        echo "Valid: $((${#config_files[@]} - validation_errors - system_errors))"
        echo "Schema violations: ${validation_errors}"
        echo "Errors: ${system_errors}"
        echo ""
    fi

    # Return appropriate exit code
    if [[ $system_errors -gt 0 ]]; then
        print_message "error" "Validation completed with errors"
        exit 2
    elif [[ $validation_errors -gt 0 ]]; then
        print_message "error" "Validation failed"
        echo ""
        print_message "info" "Fix validation errors and try again"
        print_message "info" "For schema documentation: docs/configuration/schema-reference.md"
        exit 1
    else
        if [[ ${#config_files[@]} -eq 1 ]] && [[ $VERBOSE -eq 0 ]]; then
            print_message "success" "Configuration is valid"
        else
            print_message "success" "All configurations are valid"
        fi
        exit 0
    fi
}

# Only run main if executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
