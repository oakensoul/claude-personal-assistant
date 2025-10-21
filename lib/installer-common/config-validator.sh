#!/usr/bin/env bash
#
# config-validator.sh - Configuration Validator
#
# Description:
#   Three-tier configuration validation system for AIDA workflow configuration.
#   Validates configuration files against schema, provider-specific rules, and
#   connectivity requirements with clear, actionable error messages.
#
# Validation Tiers:
#   Tier 1: Structure (JSON Schema) - Validates structure, types, required fields
#   Tier 2: Provider Rules - Validates provider-specific constraints and logic
#   Tier 3: Connectivity - Validates API credentials and network access
#
# Dependencies:
#   - validate-schema.sh (JSON Schema validation)
#   - colors.sh (via validate-schema.sh)
#   - logging.sh (via validate-schema.sh)
#   - One of: ajv-cli, check-jsonschema, or jq
#
# Part of: AIDA installer-common library v1.0
# Usage:
#   ./config-validator.sh [options] <config-file>
#
# Author: oakensoul
# License: AGPL-3.0
# Repository: https://github.com/oakensoul/claude-personal-assistant
#

set -euo pipefail

# Script directory and paths
# Note: SCRIPT_DIR will be set by validate-schema.sh when sourced
# We need to set SCRIPT_DIR before sourcing to avoid conflicts
if [[ -z "${SCRIPT_DIR:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    readonly SCRIPT_DIR
fi
readonly SCHEMA_FILE="${SCRIPT_DIR}/config-schema.json"

# Source dependencies
# shellcheck source=lib/installer-common/validate-schema.sh
source "${SCRIPT_DIR}/validate-schema.sh"
# Note: validate-schema.sh sources colors.sh and logging.sh

# shellcheck source=lib/installer-common/error-templates.sh
source "${SCRIPT_DIR}/error-templates.sh"
# Note: error-templates.sh provides provider-specific fix suggestions

# Global variables
VERBOSE=0
TIER="all"
VERIFY_CONNECTION=0

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
Usage: $(basename "$0") [options] <config-file>

Three-tier configuration validation for AIDA workflow configuration.

OPTIONS:
    -h, --help              Show this help message
    -v, --verbose           Enable verbose output
    -t, --tier TIER         Validation tier to run (default: all)
                            Options: all, structure, provider, connectivity
    --verify-connection     Enable Tier 3 connectivity validation (optional)
                            Default: disabled (not yet implemented)

ARGUMENTS:
    config-file             JSON configuration file to validate

VALIDATION TIERS:
    Tier 1: Structure
        - JSON Schema validation
        - Required field checks
        - Type validation
        - Pattern validation

    Tier 2: Provider Rules
        - Provider-specific constraints
        - Required field validation per provider
        - Format validation (URLs, UUIDs, etc.)
        - Logical consistency checks

    Tier 3: Connectivity (optional, not yet implemented)
        - API credential validation
        - Network connectivity tests
        - Repository/project access checks
        - Permission verification

EXIT CODES:
    0   Configuration valid
    1   Validation failed (structure/schema violations)
    2   Validation failed (provider rule violations)
    3   Validation failed (connectivity issues) OR system error

EXAMPLES:
    # Validate all tiers (structure + provider rules)
    $(basename "$0") config.json

    # Validate structure only
    $(basename "$0") --tier structure config.json

    # Validate with verbose output
    $(basename "$0") --verbose config.json

    # Test connectivity validation (stub, shows what will be implemented)
    $(basename "$0") --verify-connection config.json

    # Validate specific tier with connection check
    $(basename "$0") --tier connectivity --verify-connection config.json

For schema documentation: docs/configuration/schema-reference.md
EOF
}

#######################################
# Parse and enhance validator error messages
# Globals:
#   None
# Arguments:
#   $1 - Validator name (ajv, check-jsonschema, jq)
#   $2 - Raw error output from validator
# Outputs:
#   Enhanced error messages to stdout
#######################################
enhance_error_messages() {
    local validator="$1"
    local raw_errors="$2"
    local error_count=0

    echo ""
    echo "Structure Errors (Tier 1):"

    case "$validator" in
        ajv)
            # Parse ajv error format
            # ajv outputs errors like: "data.vcs should have required property 'owner'"
            while IFS= read -r line; do
                if [[ "$line" =~ data\.([^ ]+)\ should\ have\ required\ property\ \'([^\']+)\' ]]; then
                    error_count=$((error_count + 1))
                    local location="${BASH_REMATCH[1]}"
                    local property="${BASH_REMATCH[2]}"

                    echo "  ${error_count}. Missing required property: ${location}.${property}"
                    echo "     Location: \$.${location}"
                    suggest_fix_for_missing "$location" "$property"

                elif [[ "$line" =~ data\.([^ ]+)\ should\ be\ equal\ to\ one\ of\ the\ allowed\ values ]]; then
                    error_count=$((error_count + 1))
                    local location="${BASH_REMATCH[1]}"

                    echo "  ${error_count}. Invalid value for: ${location}"
                    echo "     Location: \$.${location}"
                    suggest_fix_for_enum "$location"

                elif [[ "$line" =~ data\.([^ ]+)\ should\ be\ ([a-z]+) ]]; then
                    error_count=$((error_count + 1))
                    local location="${BASH_REMATCH[1]}"
                    local expected_type="${BASH_REMATCH[2]}"

                    echo "  ${error_count}. Invalid type for: ${location}"
                    echo "     Location: \$.${location}"
                    echo "     Expected type: ${expected_type}"
                    suggest_fix_for_type "$location" "$expected_type"

                elif [[ "$line" =~ data\.([^ ]+)\ should\ match\ pattern ]]; then
                    error_count=$((error_count + 1))
                    local location="${BASH_REMATCH[1]}"

                    echo "  ${error_count}. Invalid format for: ${location}"
                    echo "     Location: \$.${location}"
                    suggest_fix_for_pattern "$location"
                fi
            done <<< "$raw_errors"
            ;;

        check-jsonschema)
            # Parse check-jsonschema error format
            # check-jsonschema outputs errors like: "'owner' is a required property"
            while IFS= read -r line; do
                if [[ "$line" =~ \'([^\']+)\'\ is\ a\ required\ property ]]; then
                    error_count=$((error_count + 1))
                    local property="${BASH_REMATCH[1]}"

                    echo "  ${error_count}. Missing required property: ${property}"
                    echo "     Location: \$.${property}"
                    suggest_fix_for_missing "root" "$property"

                elif [[ "$line" =~ is\ not\ one\ of ]]; then
                    error_count=$((error_count + 1))

                    echo "  ${error_count}. Invalid enum value"
                    echo "     Check allowed values in schema"

                elif [[ "$line" =~ is\ not\ of\ type ]]; then
                    error_count=$((error_count + 1))

                    echo "  ${error_count}. Type mismatch"
                    echo "     Check expected type in schema"
                fi
            done <<< "$raw_errors"
            ;;

        jq)
            # jq only does syntax validation, not schema validation
            echo "  Note: jq fallback mode - only JSON syntax validated"
            echo "  For full schema validation, install ajv-cli or check-jsonschema"
            echo ""
            echo "  Syntax error:"
            # Indent each line with 4 spaces
            while IFS= read -r line; do
                echo "    $line"
            done <<< "$raw_errors"
            ;;
        *)
            # Unknown validator - show raw errors
            echo "  Unknown validator: ${validator}"
            while IFS= read -r line; do
                echo "    $line"
            done <<< "$raw_errors"
            ;;
    esac

    if [[ $error_count -eq 0 ]] && [[ "$validator" != "jq" ]]; then
        # No parsed errors, show raw output
        echo "  Raw validation errors:"
        while IFS= read -r line; do
            echo "    $line"
        done <<< "$raw_errors"
    fi

    echo ""
}

#######################################
# Suggest fix for missing required property
# Arguments:
#   $1 - Parent location (e.g., "vcs", "root")
#   $2 - Property name
# Outputs:
#   Suggestion to stdout
#######################################
suggest_fix_for_missing() {
    local location="$1"
    local property="$2"

    case "$location.$property" in
        vcs.owner|root.owner)
            echo "     Fix: Add \"owner\": \"your-github-username\" to vcs section"
            ;;
        vcs.repo|root.repo)
            echo "     Fix: Add \"repo\": \"repository-name\" to vcs section"
            ;;
        vcs.provider|root.provider)
            echo "     Fix: Add \"provider\": \"github\" to vcs section"
            ;;
        root.config_version)
            echo "     Fix: Add \"config_version\": \"1.0\" at top level"
            ;;
        gitlab.project_id)
            echo "     Fix: Add \"project_id\": \"12345\" or \"group/project\" to gitlab section"
            ;;
        jira.base_url)
            echo "     Fix: Add \"base_url\": \"https://company.atlassian.net\" to jira section"
            ;;
        jira.project_key)
            echo "     Fix: Add \"project_key\": \"PROJ\" to jira section"
            ;;
        linear.team_id)
            echo "     Fix: Add \"team_id\": \"uuid-here\" to linear section"
            ;;
        linear.board_id)
            echo "     Fix: Add \"board_id\": \"uuid-here\" to linear section"
            ;;
        bitbucket.workspace)
            echo "     Fix: Add \"workspace\": \"workspace-name\" to bitbucket section"
            ;;
        bitbucket.repo_slug)
            echo "     Fix: Add \"repo_slug\": \"repository-slug\" to bitbucket section"
            ;;
        *)
            echo "     Fix: Add required property \"${property}\" to ${location} section"
            ;;
    esac
}

#######################################
# Suggest fix for invalid enum value
# Arguments:
#   $1 - Property location
# Outputs:
#   Suggestion to stdout
#######################################
suggest_fix_for_enum() {
    local location="$1"

    case "$location" in
        *provider*)
            if [[ "$location" =~ vcs ]]; then
                echo "     Expected: One of [github, gitlab, bitbucket]"
            else
                echo "     Expected: One of [github_issues, jira, linear, none]"
            fi
            echo "     Fix: Check spelling and ensure value is lowercase"
            ;;
        *review_strategy*)
            echo "     Expected: One of [list, round-robin, query, none]"
            echo "     Fix: Check spelling and ensure value is lowercase"
            ;;
        *role*)
            echo "     Expected: One of [developer, tech-lead, reviewer]"
            echo "     Fix: Check spelling and ensure value is lowercase"
            ;;
        *availability*)
            echo "     Expected: One of [available, limited, unavailable]"
            echo "     Fix: Check spelling and ensure value is lowercase"
            ;;
        *)
            echo "     Fix: Check allowed values in schema documentation"
            ;;
    esac
}

#######################################
# Suggest fix for invalid type
# Arguments:
#   $1 - Property location
#   $2 - Expected type
# Outputs:
#   Suggestion to stdout
#######################################
suggest_fix_for_type() {
    local location="$1"
    local expected_type="$2"

    case "$expected_type" in
        array)
            echo "     Fix: Use array syntax [\"item1\", \"item2\"] instead of string"
            if [[ "$location" =~ reviewers ]]; then
                echo "     Example: \"default_reviewers\": [\"alice\", \"bob\"]"
            fi
            ;;
        object)
            echo "     Fix: Use object syntax {\"key\": \"value\"} instead of other type"
            ;;
        string)
            echo "     Fix: Use string value \"text\" instead of number or boolean"
            ;;
        boolean)
            echo "     Fix: Use boolean value true or false (without quotes)"
            ;;
        number)
            echo "     Fix: Use numeric value without quotes"
            ;;
        *)
            echo "     Fix: Use ${expected_type} type for this property"
            ;;
    esac
}

#######################################
# Suggest fix for invalid pattern
# Arguments:
#   $1 - Property location
# Outputs:
#   Suggestion to stdout
#######################################
suggest_fix_for_pattern() {
    local location="$1"

    case "$location" in
        *username*|*owner*)
            echo "     Fix: Use alphanumeric characters and hyphens only"
            echo "     Must start and end with alphanumeric character"
            ;;
        *project_key*)
            echo "     Fix: Use uppercase alphanumeric characters (max 10 characters)"
            ;;
        *repo*|*project*)
            echo "     Fix: Use alphanumeric characters, dots, underscores, and hyphens"
            echo "     Must start with alphanumeric character"
            ;;
        *url*)
            echo "     Fix: Use valid HTTPS URL (must start with https://)"
            ;;
        *_id)
            echo "     Fix: Use valid UUID format"
            ;;
        *config_version*)
            echo "     Fix: Use version format like \"1.0\" (major.minor)"
            ;;
        *)
            echo "     Fix: Check pattern requirements in schema documentation"
            ;;
    esac
}

#######################################
# Tier 1: Structure Validation
# Validates configuration against JSON Schema
# Globals:
#   SCHEMA_FILE
#   VERBOSE
# Arguments:
#   $1 - Config file path
# Returns:
#   0 if valid, 1 if validation failed
# Outputs:
#   Validation results and enhanced error messages
#######################################
validate_structure() {
    local config_file="$1"

    if [[ $VERBOSE -eq 1 ]]; then
        print_message "info" "Running Tier 1 validation: Structure"
    fi

    # Detect validator
    local validator
    validator=$(detect_validator) || true

    if [[ "$validator" == "none" ]]; then
        print_message "error" "No JSON validator available"
        print_message "info" "Install one of:"
        print_message "info" "  npm install -g ajv-cli (recommended)"
        print_message "info" "  pip install check-jsonschema"
        return 2
    fi

    # Run schema validation and capture output
    local validation_output
    local validation_result=0

    case "$validator" in
        ajv)
            validation_output=$(ajv validate -s "$SCHEMA_FILE" -d "$config_file" 2>&1) || validation_result=$?
            ;;
        check-jsonschema)
            validation_output=$(check-jsonschema --schemafile "$SCHEMA_FILE" "$config_file" 2>&1) || validation_result=$?
            ;;
        jq)
            validation_output=$(jq empty "$config_file" 2>&1) || validation_result=$?
            ;;
        *)
            print_message "error" "Unknown validator: ${validator}"
            return 2
            ;;
    esac

    # Check validation result
    if [[ $validation_result -eq 0 ]]; then
        if [[ $VERBOSE -eq 1 ]]; then
            print_message "success" "Tier 1 validation passed: Structure is valid"
        fi
        return 0
    else
        # Validation failed - show enhanced error messages
        print_message "error" "Configuration validation failed"
        echo ""
        echo "File: ${config_file}"

        # Enhance error messages based on validator
        enhance_error_messages "$validator" "$validation_output"

        echo "For schema documentation: docs/configuration/schema-reference.md"
        return 1
    fi
}

#######################################
# Validate GitHub provider configuration
# Arguments:
#   $1 - Config JSON string
#   $2 - Config file path (for fix suggestions)
# Returns:
#   0 if valid, number of errors otherwise
# Outputs:
#   Error messages to stdout
#######################################
validate_github_config() {
    local config="$1"
    local config_file="${2:-config.json}"
    local errors=0
    local missing_fields=""

    # Check required fields
    local owner repo
    owner=$(echo "$config" | jq -r '.vcs.owner // empty')
    repo=$(echo "$config" | jq -r '.vcs.repo // empty')

    if [[ -z "$owner" ]]; then
        errors=$((errors + 1))
        echo "  ${errors}. $(color_red '✗') GitHub requires vcs.owner"
        echo "     Location: \$.vcs.owner"
        missing_fields="owner"
    fi

    if [[ -z "$repo" ]]; then
        errors=$((errors + 1))
        echo "  ${errors}. $(color_red '✗') GitHub requires vcs.repo"
        echo "     Location: \$.vcs.repo"
        if [[ -n "$missing_fields" ]]; then
            missing_fields="${missing_fields},repo"
        else
            missing_fields="repo"
        fi
    fi

    # Validate optional enterprise_url
    local enterprise_url
    enterprise_url=$(echo "$config" | jq -r '.vcs.github.enterprise_url // empty')
    if [[ -n "$enterprise_url" ]] && [[ "$enterprise_url" != "null" ]]; then
        if [[ ! "$enterprise_url" =~ ^https:// ]]; then
            errors=$((errors + 1))
            echo "  ${errors}. $(color_red '✗') GitHub enterprise_url must use HTTPS"
            echo "     Location: \$.vcs.github.enterprise_url"
            echo "     Current value: \"${enterprise_url}\""
            echo "     Expected format: Must start with https://"
            echo "     Fix: Change to \"enterprise_url\": \"https://github.company.com\""
            echo ""
            if [[ -n "$missing_fields" ]]; then
                missing_fields="${missing_fields},enterprise_url"
            else
                missing_fields="enterprise_url"
            fi
        fi
    fi

    # Show fix suggestions if there were errors
    if [[ $errors -gt 0 ]] && [[ -n "$missing_fields" ]]; then
        show_github_fix_suggestion "$missing_fields" "$config_file" "$SCRIPT_DIR"
    fi

    return "$errors"
}

#######################################
# Validate GitLab provider configuration
# Arguments:
#   $1 - Config JSON string
#   $2 - Config file path (for fix suggestions)
# Returns:
#   0 if valid, number of errors otherwise
# Outputs:
#   Error messages to stdout
#######################################
validate_gitlab_config() {
    local config="$1"
    local config_file="${2:-config.json}"
    local errors=0
    local missing_fields=""

    # Check required fields
    local owner repo project_id
    owner=$(echo "$config" | jq -r '.vcs.owner // empty')
    repo=$(echo "$config" | jq -r '.vcs.repo // empty')
    project_id=$(echo "$config" | jq -r '.vcs.gitlab.project_id // empty')

    if [[ -z "$owner" ]]; then
        errors=$((errors + 1))
        echo "  ${errors}. $(color_red '✗') GitLab requires vcs.owner"
        echo "     Location: \$.vcs.owner"
        missing_fields="owner"
    fi

    if [[ -z "$repo" ]]; then
        errors=$((errors + 1))
        echo "  ${errors}. $(color_red '✗') GitLab requires vcs.repo"
        echo "     Location: \$.vcs.repo"
        if [[ -n "$missing_fields" ]]; then
            missing_fields="${missing_fields},repo"
        else
            missing_fields="repo"
        fi
    fi

    if [[ -z "$project_id" ]] || [[ "$project_id" == "null" ]]; then
        errors=$((errors + 1))
        echo "  ${errors}. $(color_red '✗') GitLab requires vcs.gitlab.project_id"
        echo "     Location: \$.vcs.gitlab.project_id"
        echo "     Expected format: Numeric ID (e.g., \"12345\") or path (e.g., \"group/project\")"
        if [[ -n "$missing_fields" ]]; then
            missing_fields="${missing_fields},project_id"
        else
            missing_fields="project_id"
        fi
    else
        # Validate project_id format (numeric or path)
        if [[ ! "$project_id" =~ ^[0-9]+$ ]] && [[ ! "$project_id" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*/[a-zA-Z0-9][a-zA-Z0-9._-]*$ ]]; then
            errors=$((errors + 1))
            echo "  ${errors}. $(color_red '✗') GitLab project_id has invalid format"
            echo "     Location: \$.vcs.gitlab.project_id"
            echo "     Current value: \"${project_id}\""
            echo "     Expected format: Numeric ID (e.g., \"12345\") or path (e.g., \"group/project\")"
            echo "     Fix: Use numeric ID or path format: \"12345\" or \"my-group/my-project\""
            echo ""
        fi
    fi

    # Validate optional self_hosted_url
    local self_hosted_url
    self_hosted_url=$(echo "$config" | jq -r '.vcs.gitlab.self_hosted_url // empty')
    if [[ -n "$self_hosted_url" ]] && [[ "$self_hosted_url" != "null" ]]; then
        if [[ ! "$self_hosted_url" =~ ^https:// ]]; then
            errors=$((errors + 1))
            echo "  ${errors}. $(color_red '✗') GitLab self_hosted_url must use HTTPS"
            echo "     Location: \$.vcs.gitlab.self_hosted_url"
            echo "     Current value: \"${self_hosted_url}\""
            echo "     Expected format: Must start with https://"
            echo "     Fix: Change to \"self_hosted_url\": \"https://gitlab.company.com\""
            echo ""
            if [[ -n "$missing_fields" ]]; then
                missing_fields="${missing_fields},self_hosted_url"
            else
                missing_fields="self_hosted_url"
            fi
        fi
    fi

    # Show fix suggestions if there were errors
    if [[ $errors -gt 0 ]] && [[ -n "$missing_fields" ]]; then
        show_gitlab_fix_suggestion "$missing_fields" "$config_file" "$SCRIPT_DIR"
    fi

    return "$errors"
}

#######################################
# Validate Bitbucket provider configuration
# Arguments:
#   $1 - Config JSON string
#   $2 - Config file path (for fix suggestions)
# Returns:
#   0 if valid, number of errors otherwise
# Outputs:
#   Error messages to stdout
#######################################
validate_bitbucket_config() {
    local config="$1"
    local config_file="${2:-config.json}"
    local errors=0
    local missing_fields=""

    # Check required fields
    local workspace repo_slug
    workspace=$(echo "$config" | jq -r '.vcs.bitbucket.workspace // empty')
    repo_slug=$(echo "$config" | jq -r '.vcs.bitbucket.repo_slug // empty')

    if [[ -z "$workspace" ]] || [[ "$workspace" == "null" ]]; then
        errors=$((errors + 1))
        echo "  ${errors}. $(color_red '✗') Bitbucket requires vcs.bitbucket.workspace"
        echo "     Location: $.vcs.bitbucket.workspace"
        missing_fields="workspace"
    fi

    if [[ -z "$repo_slug" ]] || [[ "$repo_slug" == "null" ]]; then
        errors=$((errors + 1))
        echo "  ${errors}. $(color_red '✗') Bitbucket requires vcs.bitbucket.repo_slug"
        echo "     Location: $.vcs.bitbucket.repo_slug"
        echo "     Expected format: Lowercase alphanumeric with hyphens (e.g., \"my-project\")"
        if [[ -n "$missing_fields" ]]; then
            missing_fields="${missing_fields},repo_slug"
        else
            missing_fields="repo_slug"
        fi
    else
        # Validate repo_slug format (lowercase alphanumeric with hyphens)
        if [[ ! "$repo_slug" =~ ^[a-z0-9][a-z0-9-]*[a-z0-9]$|^[a-z0-9]$ ]]; then
            errors=$((errors + 1))
            echo "  ${errors}. $(color_red '✗') Bitbucket repo_slug has invalid format"
            echo "     Location: $.vcs.bitbucket.repo_slug"
            echo "     Current value: \"${repo_slug}\""
            echo "     Expected format: Lowercase alphanumeric with hyphens (e.g., \"my-project\", \"web-app\")"
            echo "     Fix: Use lowercase alphanumeric characters and hyphens only"
            echo ""
        fi
    fi

    # Show fix suggestions if there were errors
    if [[ $errors -gt 0 ]] && [[ -n "$missing_fields" ]]; then
        show_bitbucket_fix_suggestion "$missing_fields" "$config_file" "$SCRIPT_DIR"
    fi

    return "$errors"
}

#######################################
# Validate Jira work tracker configuration
# Arguments:
#   $1 - Config JSON string
#   $2 - Config file path (for fix suggestions)
# Returns:
#   0 if valid, number of errors otherwise
# Outputs:
#   Error messages to stdout
#######################################
validate_jira_config() {
    local config="$1"
    local config_file="${2:-config.json}"
    local errors=0
    local missing_fields=""

    # Check required fields
    local base_url project_key
    base_url=$(echo "$config" | jq -r '.work_tracker.jira.base_url // empty')
    project_key=$(echo "$config" | jq -r '.work_tracker.jira.project_key // empty')

    if [[ -z "$base_url" ]] || [[ "$base_url" == "null" ]]; then
        errors=$((errors + 1))
        echo "  ${errors}. $(color_red '✗') Jira requires work_tracker.jira.base_url"
        echo "     Location: $.work_tracker.jira.base_url"
        echo "     Expected format: HTTPS URL (e.g., \"https://company.atlassian.net\")"
        missing_fields="base_url"
    else
        # Validate base_url is HTTPS
        if [[ ! "$base_url" =~ ^https:// ]]; then
            errors=$((errors + 1))
            echo "  ${errors}. $(color_red '✗') Jira base_url must use HTTPS"
            echo "     Location: $.work_tracker.jira.base_url"
            echo "     Current value: \"${base_url}\""
            echo "     Expected format: Must start with https://"
            echo "     Fix: Change to \"base_url\": \"https://company.atlassian.net\""
            echo ""
        fi
    fi

    if [[ -z "$project_key" ]] || [[ "$project_key" == "null" ]]; then
        errors=$((errors + 1))
        echo "  ${errors}. $(color_red '✗') Jira requires work_tracker.jira.project_key"
        echo "     Location: $.work_tracker.jira.project_key"
        echo "     Expected format: Uppercase alphanumeric, max 10 chars (e.g., \"PROJ\", \"DEV123\")"
        if [[ -n "$missing_fields" ]]; then
            missing_fields="${missing_fields},project_key"
        else
            missing_fields="project_key"
        fi
    else
        # Validate project_key format (uppercase alphanumeric, max 10 chars)
        if [[ ! "$project_key" =~ ^[A-Z0-9]{1,10}$ ]]; then
            errors=$((errors + 1))
            echo "  ${errors}. $(color_red '✗') Jira project_key has invalid format"
            echo "     Location: $.work_tracker.jira.project_key"
            echo "     Current value: \"${project_key}\""
            echo "     Expected format: Uppercase alphanumeric, max 10 chars (e.g., \"PROJ\", \"DEV123\")"
            echo "     Fix: Use uppercase alphanumeric characters only, maximum 10 characters"
            echo ""
        fi
    fi

    # Show fix suggestions if there were errors
    if [[ $errors -gt 0 ]] && [[ -n "$missing_fields" ]]; then
        show_jira_fix_suggestion "$missing_fields" "$config_file"
    fi

    return "$errors"
}

#######################################
# Validate Linear work tracker configuration
# Arguments:
#   $1 - Config JSON string
#   $2 - Config file path (for fix suggestions)
# Returns:
#   0 if valid, number of errors otherwise
# Outputs:
#   Error messages to stdout
#######################################
validate_linear_config() {
    local config="$1"
    local config_file="${2:-config.json}"
    local errors=0
    local missing_fields=""

    # UUID pattern for validation
    local uuid_pattern='^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'

    # Check required fields
    local team_id board_id
    team_id=$(echo "$config" | jq -r '.work_tracker.linear.team_id // empty')
    board_id=$(echo "$config" | jq -r '.work_tracker.linear.board_id // empty')

    if [[ -z "$team_id" ]] || [[ "$team_id" == "null" ]]; then
        errors=$((errors + 1))
        echo "  ${errors}. $(color_red '✗') Linear requires work_tracker.linear.team_id"
        echo "     Location: $.work_tracker.linear.team_id"
        echo "     Expected format: UUID (e.g., \"123e4567-e89b-12d3-a456-426614174000\")"
        missing_fields="team_id"
    else
        # Validate team_id UUID format
        if [[ ! "$team_id" =~ $uuid_pattern ]]; then
            errors=$((errors + 1))
            echo "  ${errors}. $(color_red '✗') Linear team_id has invalid UUID format"
            echo "     Location: $.work_tracker.linear.team_id"
            echo "     Current value: \"${team_id}\""
            echo "     Expected format: UUID (e.g., \"123e4567-e89b-12d3-a456-426614174000\")"
            echo "     Fix: Use valid UUID format with lowercase hexadecimal digits"
            echo ""
        fi
    fi

    if [[ -z "$board_id" ]] || [[ "$board_id" == "null" ]]; then
        errors=$((errors + 1))
        echo "  ${errors}. $(color_red '✗') Linear requires work_tracker.linear.board_id"
        echo "     Location: $.work_tracker.linear.board_id"
        echo "     Expected format: UUID (e.g., \"987fcdeb-51a2-43f1-9876-543210fedcba\")"
        if [[ -n "$missing_fields" ]]; then
            missing_fields="${missing_fields},board_id"
        else
            missing_fields="board_id"
        fi
    else
        # Validate board_id UUID format
        if [[ ! "$board_id" =~ $uuid_pattern ]]; then
            errors=$((errors + 1))
            echo "  ${errors}. $(color_red '✗') Linear board_id has invalid UUID format"
            echo "     Location: $.work_tracker.linear.board_id"
            echo "     Current value: \"${board_id}\""
            echo "     Expected format: UUID (e.g., \"987fcdeb-51a2-43f1-9876-543210fedcba\")"
            echo "     Fix: Use valid UUID format with lowercase hexadecimal digits"
            echo ""
        fi
    fi

    # Show fix suggestions if there were errors
    if [[ $errors -gt 0 ]] && [[ -n "$missing_fields" ]]; then
        show_linear_fix_suggestion "$missing_fields" "$config_file"
    fi

    return "$errors"
}

#######################################
# Tier 2: Provider Rules Validation
# Validates provider-specific constraints and logic
# Arguments:
#   $1 - Config file path
# Returns:
#   0 if valid, number of errors otherwise
# Outputs:
#   Validation results and error messages
#######################################
validate_provider_rules() {
    local config_file="$1"
    local errors=0
    local has_errors=0

    if [[ $VERBOSE -eq 1 ]]; then
        print_message "info" "Running Tier 2 validation: Provider Rules"
    fi

    # Read config
    local config
    config=$(cat "$config_file")

    # Get VCS provider
    local vcs_provider
    vcs_provider=$(echo "$config" | jq -r '.vcs.provider // empty')

    # Validate VCS provider
    if [[ -n "$vcs_provider" ]]; then
        case "$vcs_provider" in
            github)
                local github_errors=0
                if output=$(validate_github_config "$config" "$config_file"); then
                    github_errors=0
                else
                    github_errors=$?
                    has_errors=1
                    if [[ $errors -eq 0 ]]; then
                        echo ""
                        echo "Provider Rule Errors (Tier 2):"
                    fi
                    echo "$output"
                    errors=$((errors + github_errors))
                fi
                ;;
            gitlab)
                local gitlab_errors=0
                if output=$(validate_gitlab_config "$config" "$config_file"); then
                    gitlab_errors=0
                else
                    gitlab_errors=$?
                    has_errors=1
                    if [[ $errors -eq 0 ]]; then
                        echo ""
                        echo "Provider Rule Errors (Tier 2):"
                    fi
                    echo "$output"
                    errors=$((errors + gitlab_errors))
                fi
                ;;
            bitbucket)
                local bitbucket_errors=0
                if output=$(validate_bitbucket_config "$config" "$config_file"); then
                    bitbucket_errors=0
                else
                    bitbucket_errors=$?
                    has_errors=1
                    if [[ $errors -eq 0 ]]; then
                        echo ""
                        echo "Provider Rule Errors (Tier 2):"
                    fi
                    echo "$output"
                    errors=$((errors + bitbucket_errors))
                fi
                ;;
            *)
                # Unknown provider - should be caught by Tier 1 schema validation
                if [[ $VERBOSE -eq 1 ]]; then
                    print_message "info" "Skipping unknown VCS provider: ${vcs_provider}"
                fi
                ;;
        esac
    fi

    # Get work tracker provider
    local work_tracker_provider
    work_tracker_provider=$(echo "$config" | jq -r '.work_tracker.provider // empty')

    # Validate work tracker provider
    if [[ -n "$work_tracker_provider" ]]; then
        case "$work_tracker_provider" in
            jira)
                local jira_errors=0
                if output=$(validate_jira_config "$config" "$config_file"); then
                    jira_errors=0
                else
                    jira_errors=$?
                    has_errors=1
                    if [[ $errors -eq 0 ]]; then
                        echo ""
                        echo "Provider Rule Errors (Tier 2):"
                    fi
                    echo "$output"
                    errors=$((errors + jira_errors))
                fi
                ;;
            linear)
                local linear_errors=0
                if output=$(validate_linear_config "$config" "$config_file"); then
                    linear_errors=0
                else
                    linear_errors=$?
                    has_errors=1
                    if [[ $errors -eq 0 ]]; then
                        echo ""
                        echo "Provider Rule Errors (Tier 2):"
                    fi
                    echo "$output"
                    errors=$((errors + linear_errors))
                fi
                ;;
            github_issues|none)
                # No additional validation needed
                ;;
            *)
                # Unknown provider - should be caught by Tier 1 schema validation
                if [[ $VERBOSE -eq 1 ]]; then
                    print_message "info" "Skipping unknown work tracker provider: ${work_tracker_provider}"
                fi
                ;;
        esac
    fi

    if [[ $has_errors -eq 1 ]]; then
        echo "For schema documentation: docs/configuration/schema-reference.md"
        return 2
    fi

    if [[ $VERBOSE -eq 1 ]]; then
        print_message "success" "Tier 2 validation passed: Provider rules satisfied"
    fi

    return 0
}

#######################################
# Tier 3: Connectivity Validation
# Validates API credentials and network access
# Globals:
#   VERIFY_CONNECTION - Whether to run connectivity checks
# Arguments:
#   $1 - Config file path
# Returns:
#   0 if valid or skipped, 3 if connectivity validation fails (when implemented)
# Outputs:
#   Stub message showing what will be implemented
#######################################
validate_connectivity() {
    local config_file="$1"

    # Skip if connectivity verification not requested
    if [[ $VERIFY_CONNECTION -ne 1 ]]; then
        if [[ $VERBOSE -eq 1 ]]; then
            print_message "info" "Tier 3 validation: Connectivity (skipped, use --verify-connection to enable)"
        fi
        return 0
    fi

    # Read configuration
    local config
    config=$(cat "$config_file")

    # Get configured providers
    local vcs_provider
    vcs_provider=$(echo "$config" | jq -r '.vcs.provider // empty')

    local work_tracker_provider
    work_tracker_provider=$(echo "$config" | jq -r '.work_tracker.provider // empty')

    # Display stub implementation message
    echo ""
    echo "========================================================================"
    echo "Connectivity Validation (Tier 3): NOT YET IMPLEMENTED"
    echo "========================================================================"
    echo ""
    echo "This tier will test API connectivity to configured providers."
    echo ""
    echo "When implemented, this validation will:"
    echo "  - Test network connectivity to API endpoints"
    echo "  - Verify authentication with provided credentials"
    echo "  - Check repository/project access permissions"
    echo "  - Validate API token scopes and capabilities"
    echo "  - Return exit code 3 on connectivity failures"
    echo ""

    # Show what would be validated for VCS provider
    if [[ -n "$vcs_provider" ]]; then
        echo "VCS Provider: ${vcs_provider}"
        echo "------------------------------------------------------------------------"

        case "$vcs_provider" in
            github)
                local enterprise_url
                enterprise_url=$(echo "$config" | jq -r '.vcs.github.enterprise_url // empty')

                local api_url="https://api.github.com"
                if [[ -n "$enterprise_url" ]] && [[ "$enterprise_url" != "null" ]]; then
                    api_url="${enterprise_url}/api/v3"
                fi

                echo "  Planned Tests:"
                echo "    1. API Connection"
                echo "       - Endpoint: ${api_url}"
                echo "       - Test: GET ${api_url}/rate_limit"
                echo "       - Validates: Network connectivity to GitHub API"
                echo ""
                echo "    2. Authentication"
                echo "       - Environment: \$GITHUB_TOKEN"
                echo "       - Test: GET ${api_url}/user"
                echo "       - Validates: Token is valid and properly authenticated"
                echo ""
                echo "    3. Repository Access"
                local owner repo
                owner=$(echo "$config" | jq -r '.vcs.owner // empty')
                repo=$(echo "$config" | jq -r '.vcs.repo // empty')
                if [[ -n "$owner" ]] && [[ -n "$repo" ]]; then
                    echo "       - Test: GET ${api_url}/repos/${owner}/${repo}"
                    echo "       - Validates: Access to repository ${owner}/${repo}"
                    echo "       - Checks: Read/write permissions, admin access"
                fi
                echo ""
                # TODO (Issue #56): Implement GitHub API connectivity check
                #   - Test connection to github.com or enterprise_url
                #   - Verify authentication with $GITHUB_TOKEN
                #   - Check repository access (GET /repos/:owner/:repo)
                #   - Verify token scopes include: repo, workflow
                #   - Return exit code 3 on connectivity failure
                ;;
            gitlab)
                local self_hosted_url
                self_hosted_url=$(echo "$config" | jq -r '.vcs.gitlab.self_hosted_url // empty')

                local api_url="https://gitlab.com/api/v4"
                if [[ -n "$self_hosted_url" ]] && [[ "$self_hosted_url" != "null" ]]; then
                    api_url="${self_hosted_url}/api/v4"
                fi

                echo "  Planned Tests:"
                echo "    1. API Connection"
                echo "       - Endpoint: ${api_url}"
                echo "       - Test: GET ${api_url}/version"
                echo "       - Validates: Network connectivity to GitLab API"
                echo ""
                echo "    2. Authentication"
                echo "       - Environment: \$GITLAB_TOKEN"
                echo "       - Test: GET ${api_url}/user"
                echo "       - Validates: Token is valid and properly authenticated"
                echo ""
                echo "    3. Project Access"
                local project_id
                project_id=$(echo "$config" | jq -r '.vcs.gitlab.project_id // empty')
                if [[ -n "$project_id" ]] && [[ "$project_id" != "null" ]]; then
                    echo "       - Test: GET ${api_url}/projects/${project_id}"
                    echo "       - Validates: Access to project ${project_id}"
                    echo "       - Checks: Developer/maintainer permissions"
                fi
                echo ""
                # TODO (Issue #57): Implement GitLab API connectivity check
                #   - Test connection to gitlab.com or self_hosted_url
                #   - Verify authentication with $GITLAB_TOKEN
                #   - Check project access (GET /projects/:id)
                #   - Verify token scopes include: api, write_repository
                #   - Return exit code 3 on connectivity failure
                ;;
            bitbucket)
                local workspace repo_slug
                workspace=$(echo "$config" | jq -r '.vcs.bitbucket.workspace // empty')
                repo_slug=$(echo "$config" | jq -r '.vcs.bitbucket.repo_slug // empty')

                echo "  Planned Tests:"
                echo "    1. API Connection"
                echo "       - Endpoint: https://api.bitbucket.org/2.0"
                echo "       - Test: GET /2.0/user"
                echo "       - Validates: Network connectivity to Bitbucket API"
                echo ""
                echo "    2. Authentication"
                echo "       - Environment: \$BITBUCKET_TOKEN or \$BITBUCKET_USERNAME/\$BITBUCKET_APP_PASSWORD"
                echo "       - Test: GET /2.0/user"
                echo "       - Validates: Credentials are valid and properly authenticated"
                echo ""
                if [[ -n "$workspace" ]] && [[ "$repo_slug" ]]; then
                    echo "    3. Repository Access"
                    echo "       - Test: GET /2.0/repositories/${workspace}/${repo_slug}"
                    echo "       - Validates: Access to repository ${workspace}/${repo_slug}"
                    echo "       - Checks: Read/write permissions"
                fi
                echo ""
                # TODO (Issue #58): Implement Bitbucket API connectivity check
                #   - Test connection to bitbucket.org
                #   - Verify authentication with $BITBUCKET_TOKEN or username/password
                #   - Check repository access (GET /repositories/:workspace/:repo_slug)
                #   - Verify account permissions
                #   - Return exit code 3 on connectivity failure
                ;;
            *)
                # Unknown VCS provider - should be caught by Tier 1/2
                echo "  Unknown VCS provider: ${vcs_provider}"
                ;;
        esac
        echo ""
    fi

    # Show what would be validated for work tracker provider
    if [[ -n "$work_tracker_provider" ]] && [[ "$work_tracker_provider" != "none" ]]; then
        echo "Work Tracker: ${work_tracker_provider}"
        echo "------------------------------------------------------------------------"

        case "$work_tracker_provider" in
            github_issues)
                local owner repo
                owner=$(echo "$config" | jq -r '.vcs.owner // empty')
                repo=$(echo "$config" | jq -r '.vcs.repo // empty')

                echo "  Planned Tests:"
                echo "    1. GitHub Issues API Access"
                echo "       - Uses same authentication as VCS (GitHub)"
                if [[ -n "$owner" ]] && [[ -n "$repo" ]]; then
                    echo "       - Test: GET /repos/${owner}/${repo}/issues"
                    echo "       - Validates: Can list issues"
                    echo ""
                    echo "    2. Issue Creation Permission"
                    echo "       - Test: Verify repo permissions include issues"
                    echo "       - Validates: Can create and manage issues"
                fi
                echo ""
                # Note: GitHub Issues uses same token as GitHub VCS
                # Connectivity validation will be handled by GitHub VCS validation
                ;;
            jira)
                local base_url project_key
                base_url=$(echo "$config" | jq -r '.work_tracker.jira.base_url // empty')
                project_key=$(echo "$config" | jq -r '.work_tracker.jira.project_key // empty')

                echo "  Planned Tests:"
                echo "    1. API Connection"
                if [[ -n "$base_url" ]] && [[ "$base_url" != "null" ]]; then
                    echo "       - Endpoint: ${base_url}/rest/api/2"
                    echo "       - Test: GET ${base_url}/rest/api/2/serverInfo"
                fi
                echo "       - Validates: Network connectivity to Jira instance"
                echo ""
                echo "    2. Authentication"
                echo "       - Environment: \$JIRA_TOKEN or \$JIRA_EMAIL/\$JIRA_API_TOKEN"
                if [[ -n "$base_url" ]] && [[ "$base_url" != "null" ]]; then
                    echo "       - Test: GET ${base_url}/rest/api/2/myself"
                fi
                echo "       - Validates: Credentials are valid and properly authenticated"
                echo ""
                if [[ -n "$project_key" ]] && [[ "$project_key" != "null" ]]; then
                    echo "    3. Project Access"
                    echo "       - Test: GET /rest/api/2/project/${project_key}"
                    echo "       - Validates: Access to project ${project_key}"
                    echo "       - Checks: Create/edit issue permissions"
                fi
                echo ""
                # TODO (Issue #59): Implement Jira API connectivity check
                #   - Test connection to base_url
                #   - Verify authentication with $JIRA_TOKEN or $JIRA_EMAIL/$JIRA_API_TOKEN
                #   - Check project access (GET /rest/api/2/project/:key)
                #   - Verify permissions to create/edit issues
                #   - Return exit code 3 on connectivity failure
                ;;
            linear)
                local team_id board_id
                team_id=$(echo "$config" | jq -r '.work_tracker.linear.team_id // empty')
                board_id=$(echo "$config" | jq -r '.work_tracker.linear.board_id // empty')

                echo "  Planned Tests:"
                echo "    1. API Connection"
                echo "       - Endpoint: https://api.linear.app/graphql"
                echo "       - Test: GraphQL query { viewer { id name } }"
                echo "       - Validates: Network connectivity to Linear API"
                echo ""
                echo "    2. Authentication"
                echo "       - Environment: \$LINEAR_TOKEN"
                echo "       - Test: GraphQL query { viewer { id name email } }"
                echo "       - Validates: Token is valid and properly authenticated"
                echo ""
                if [[ -n "$team_id" ]] && [[ "$team_id" != "null" ]]; then
                    echo "    3. Team Access"
                    echo "       - Test: GraphQL query { team(id: \"${team_id}\") { id name } }"
                    echo "       - Validates: Access to team ${team_id}"
                fi
                if [[ -n "$board_id" ]] && [[ "$board_id" != "null" ]]; then
                    echo ""
                    echo "    4. Board Access"
                    echo "       - Test: GraphQL query { workflowState(id: \"${board_id}\") { id name } }"
                    echo "       - Validates: Access to board/workflow ${board_id}"
                fi
                echo ""
                # TODO (Issue #60): Implement Linear API connectivity check
                #   - Test connection to Linear GraphQL API
                #   - Verify authentication with $LINEAR_TOKEN
                #   - Check team access via GraphQL query
                #   - Check board/workflow access
                #   - Return exit code 3 on connectivity failure
                ;;
            *)
                # Unknown work tracker provider - should be caught by Tier 1/2
                echo "  Unknown work tracker provider: ${work_tracker_provider}"
                ;;
        esac
        echo ""
    fi

    # Implementation status
    echo "========================================================================"
    echo "Implementation Status:"
    echo "  Status: DEFERRED"
    echo "  Tracking Issues:"
    if [[ -n "$vcs_provider" ]]; then
        case "$vcs_provider" in
            github)   echo "    - Issue #56: GitHub API connectivity validation" ;;
            gitlab)   echo "    - Issue #57: GitLab API connectivity validation" ;;
            bitbucket) echo "    - Issue #58: Bitbucket API connectivity validation" ;;
            *) ;; # Unknown provider, no issue to reference
        esac
    fi
    if [[ -n "$work_tracker_provider" ]] && [[ "$work_tracker_provider" != "none" ]]; then
        case "$work_tracker_provider" in
            jira)   echo "    - Issue #59: Jira API connectivity validation" ;;
            linear) echo "    - Issue #60: Linear API connectivity validation" ;;
            github_issues) echo "    - (Covered by Issue #56: GitHub connectivity)" ;;
            *) ;; # Unknown provider, no issue to reference
        esac
    fi
    echo ""
    echo "To skip this message, omit the --verify-connection flag"
    echo "========================================================================"
    echo ""

    if [[ $VERBOSE -eq 1 ]]; then
        print_message "info" "Tier 3 validation: Connectivity (stub displayed)"
    fi

    # Return 0 for now (stub doesn't fail validation)
    # When implemented, this will return 3 on connectivity failures
    return 0
}

#######################################
# Main validation orchestrator
# Runs requested validation tiers and aggregates results
# Globals:
#   VERBOSE
# Arguments:
#   $1 - Config file path
#   $2 - Tier to run (all, structure, provider, connectivity)
# Returns:
#   0 if valid, 1 for structure errors, 2 for provider errors, 3 for system errors
# Outputs:
#   Validation results to stdout/stderr
#######################################
validate_config() {
    local config_file="$1"
    local tier="${2:-all}"
    local failed=0

    # Check file exists
    if [[ ! -f "$config_file" ]]; then
        print_message "error" "File not found: ${config_file}"
        return 3
    fi

    # Check file is readable
    if [[ ! -r "$config_file" ]]; then
        print_message "error" "File not readable: ${config_file}"
        return 3
    fi

    # Run requested validation tiers
    case "$tier" in
        all)
            validate_structure "$config_file" || failed=$?
            if [[ $failed -eq 0 ]]; then
                validate_provider_rules "$config_file" || failed=$?
            fi
            if [[ $failed -eq 0 ]]; then
                validate_connectivity "$config_file" || failed=$?
            fi
            ;;
        structure)
            validate_structure "$config_file" || failed=$?
            ;;
        provider)
            validate_provider_rules "$config_file" || failed=$?
            ;;
        connectivity)
            validate_connectivity "$config_file" || failed=$?
            ;;
        *)
            print_message "error" "Unknown tier: ${tier}"
            print_message "info" "Valid tiers: all, structure, provider, connectivity"
            return 3
            ;;
    esac

    return "$failed"
}

#######################################
# Main entry point
# Globals:
#   VERBOSE
#   TIER
# Arguments:
#   Command-line arguments
# Returns:
#   0 if valid, 1 if validation failed, 2 if error
#######################################
main() {
    local config_file=""

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
            -t|--tier)
                if [[ -z "${2:-}" ]]; then
                    print_message "error" "Option --tier requires an argument"
                    echo ""
                    show_help
                    exit 2
                fi
                TIER="$2"
                shift 2
                ;;
            --verify-connection)
                VERIFY_CONNECTION=1
                shift
                ;;
            -*)
                print_message "error" "Unknown option: $1"
                echo ""
                show_help
                exit 2
                ;;
            *)
                if [[ -n "$config_file" ]]; then
                    print_message "error" "Multiple config files specified"
                    print_message "info" "This validator processes one file at a time"
                    echo ""
                    show_help
                    exit 2
                fi
                config_file="$1"
                shift
                ;;
        esac
    done

    # Validate arguments
    if [[ -z "$config_file" ]]; then
        print_message "error" "No config file specified"
        echo ""
        show_help
        exit 2
    fi

    # Run validation
    local result=0
    validate_config "$config_file" "$TIER" || result=$?

    # Display final result
    if [[ $result -eq 0 ]]; then
        if [[ "$TIER" == "all" ]]; then
            print_message "success" "Configuration is valid (all tiers passed)"
        else
            print_message "success" "Configuration is valid (${TIER} tier passed)"
        fi
        exit 0
    elif [[ $result -eq 1 ]]; then
        print_message "error" "Validation failed (structure/schema violations)"
        echo ""
        print_message "info" "Fix validation errors and try again"
        exit 1
    elif [[ $result -eq 2 ]]; then
        print_message "error" "Validation failed (provider rule violations)"
        echo ""
        print_message "info" "Fix provider-specific errors and try again"
        exit 2
    else
        # result == 3 (system error already displayed)
        exit 3
    fi
}

# Only run main if executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
