#!/usr/bin/env bash
#
# deprecation.sh - Template Deprecation and Version Management
#
# Description:
#   Template deprecation detection, version comparison, and migration support for AIDA
#   installer-common library. Handles backward-compatible command renames by parsing
#   deprecation metadata from template frontmatter and making installation decisions
#   based on semantic versioning.
#
#   Key Features:
#   - Semantic version comparison (MAJOR.MINOR.PATCH)
#   - Frontmatter parsing for deprecation metadata
#   - Deprecation detection and validation
#   - Migration support (deprecated -> canonical)
#   - Conflict detection (user has both deprecated and canonical)
#   - Installation decision logic based on version and flags
#
# Dependencies:
#   - colors.sh (must be sourced first)
#   - logging.sh (must be sourced first)
#   - validation.sh (must be sourced first)
#
# Part of: AIDA installer-common library v1.0
# Usage:
#   source "${INSTALLER_COMMON}/colors.sh"
#   source "${INSTALLER_COMMON}/logging.sh"
#   source "${INSTALLER_COMMON}/validation.sh"
#   source "${INSTALLER_COMMON}/deprecation.sh"
#
# Author: oakensoul
# License: AGPL-3.0
# Repository: https://github.com/oakensoul/claude-personal-assistant
#

set -euo pipefail

# Prevent multiple sourcing
[[ -n "${_INSTALLER_DEPRECATION_SH_LOADED:-}" ]] && return 0
readonly _INSTALLER_DEPRECATION_SH_LOADED=1

#######################################
# Compare semantic versions
#
# Compares two semantic version strings (MAJOR.MINOR.PATCH) and returns a comparison result.
# Used for determining version relationships in deprecation logic.
#
# Arguments:
#   $1 - First version string (e.g., "0.2.0")
#   $2 - Second version string (e.g., "0.1.6")
#
# Returns:
#   0 if v1 == v2
#   1 if v1 > v2
#   2 if v1 < v2
#   3 if either version is invalid
#
# Outputs:
#   Error messages via logging if validation fails
#
# Example:
#   compare_versions "0.2.0" "0.1.6"  # Returns 1 (0.2.0 > 0.1.6)
#   echo $?  # 1
#
#   compare_versions "0.1.6" "0.2.0"  # Returns 2 (0.1.6 < 0.2.0)
#   echo $?  # 2
#
#   compare_versions "0.1.6" "0.1.6"  # Returns 0 (equal)
#   echo $?  # 0
#######################################
compare_versions() {
    local v1="$1"
    local v2="$2"

    # Validate inputs
    if [[ -z "$v1" ]] || [[ -z "$v2" ]]; then
        print_message "error" "compare_versions: Both version parameters required"
        return 3
    fi

    # Validate version format using validation.sh
    if ! validate_version "$v1"; then
        print_message "error" "compare_versions: Invalid version format: ${v1}"
        return 3
    fi

    if ! validate_version "$v2"; then
        print_message "error" "compare_versions: Invalid version format: ${v2}"
        return 3
    fi

    # Parse versions: MAJOR.MINOR.PATCH
    local v1_major v1_minor v1_patch
    IFS='.' read -r v1_major v1_minor v1_patch <<< "$v1"

    local v2_major v2_minor v2_patch
    IFS='.' read -r v2_major v2_minor v2_patch <<< "$v2"

    # Compare MAJOR
    if [[ "$v1_major" -gt "$v2_major" ]]; then
        return 1  # v1 > v2
    elif [[ "$v1_major" -lt "$v2_major" ]]; then
        return 2  # v1 < v2
    fi

    # Major versions equal, compare MINOR
    if [[ "$v1_minor" -gt "$v2_minor" ]]; then
        return 1  # v1 > v2
    elif [[ "$v1_minor" -lt "$v2_minor" ]]; then
        return 2  # v1 < v2
    fi

    # Minor versions equal, compare PATCH
    if [[ "$v1_patch" -gt "$v2_patch" ]]; then
        return 1  # v1 > v2
    elif [[ "$v1_patch" -lt "$v2_patch" ]]; then
        return 2  # v1 < v2
    fi

    # All components equal
    return 0
}

#######################################
# Extract value from YAML frontmatter
#
# Internal helper function to extract a specific field from YAML frontmatter.
# Handles simple key-value pairs (no nested structures).
#
# Arguments:
#   $1 - Frontmatter content (as string)
#   $2 - Key to extract (e.g., "deprecated", "canonical")
#
# Returns:
#   0 on success
#   1 if key not found
#
# Outputs:
#   Extracted value to stdout (trimmed of whitespace)
#
# Example:
#   frontmatter=$(extract_frontmatter "$template_file")
#   deprecated=$(extract_yaml_value "$frontmatter" "deprecated")
#######################################
extract_yaml_value() {
    local frontmatter="$1"
    local key="$2"

    # Extract value using grep and sed
    local value
    value=$(echo "$frontmatter" | grep "^${key}:" | sed "s/^${key}:[[:space:]]*//" | sed 's/[[:space:]]*$//')

    if [[ -z "$value" ]]; then
        return 1
    fi

    # Strip quotes if present (both single and double)
    value="${value#\"}"
    value="${value%\"}"
    value="${value#\'}"
    value="${value%\'}"

    echo "$value"
    return 0
}

#######################################
# Extract YAML frontmatter from template file
#
# Internal helper function to extract YAML frontmatter block from a template file.
# Frontmatter is expected to be between triple-dash markers at the start of the file.
#
# Arguments:
#   $1 - Template file path
#
# Returns:
#   0 on success
#   1 if no frontmatter found or file doesn't exist
#
# Outputs:
#   Frontmatter content to stdout (excluding --- markers)
#
# Example:
#   frontmatter=$(extract_frontmatter "/path/to/template.md")
#######################################
extract_frontmatter() {
    local template_file="$1"

    # Validate file exists
    if [[ ! -f "$template_file" ]]; then
        return 1
    fi

    # Extract frontmatter between first --- and second ---
    # Use sed to extract lines between first and second ---
    local frontmatter
    frontmatter=$(sed -n '/^---$/,/^---$/p' "$template_file" | sed '1d;$d')

    if [[ -z "$frontmatter" ]]; then
        return 1
    fi

    echo "$frontmatter"
    return 0
}

#######################################
# Parse deprecation metadata from template frontmatter
#
# Extracts deprecation information from a template file's YAML frontmatter.
# Returns all deprecation-related fields as a formatted string for easy parsing.
#
# Expected frontmatter format:
#   ---
#   deprecated: true
#   deprecated_in: "0.2.0"
#   remove_in: "0.4.0"
#   canonical: "issue-create"
#   reason: "Renamed to noun-verb convention"
#   ---
#
# Arguments:
#   $1 - Template file path (required)
#
# Returns:
#   0 on success (frontmatter found and parsed)
#   1 on failure (file doesn't exist, no frontmatter, or parsing error)
#
# Outputs:
#   Multi-line output with key=value pairs:
#     deprecated=true
#     deprecated_in=0.2.0
#     remove_in=0.4.0
#     canonical=issue-create
#     reason=Renamed to noun-verb convention
#
# Example:
#   metadata=$(parse_deprecation_metadata "/path/to/template.md")
#   if [[ $? -eq 0 ]]; then
#     deprecated=$(echo "$metadata" | grep "^deprecated=" | cut -d= -f2)
#     canonical=$(echo "$metadata" | grep "^canonical=" | cut -d= -f2)
#   fi
#######################################
parse_deprecation_metadata() {
    local template_file="$1"

    # Validate input
    if [[ -z "$template_file" ]]; then
        print_message "error" "parse_deprecation_metadata: template_file required"
        return 1
    fi

    # Check file exists
    if [[ ! -f "$template_file" ]]; then
        print_message "error" "Template file does not exist: ${template_file}"
        return 1
    fi

    # Extract frontmatter
    local frontmatter
    if ! frontmatter=$(extract_frontmatter "$template_file"); then
        # No frontmatter found - not necessarily an error (not all templates are deprecated)
        return 1
    fi

    # Extract deprecation fields (all optional)
    local deprecated deprecated_in remove_in canonical reason

    deprecated=$(extract_yaml_value "$frontmatter" "deprecated" || echo "")
    deprecated_in=$(extract_yaml_value "$frontmatter" "deprecated_in" || echo "")
    remove_in=$(extract_yaml_value "$frontmatter" "remove_in" || echo "")
    canonical=$(extract_yaml_value "$frontmatter" "canonical" || echo "")
    reason=$(extract_yaml_value "$frontmatter" "reason" || echo "")

    # Output key=value pairs (only non-empty values)
    [[ -n "$deprecated" ]] && echo "deprecated=${deprecated}"
    [[ -n "$deprecated_in" ]] && echo "deprecated_in=${deprecated_in}"
    [[ -n "$remove_in" ]] && echo "remove_in=${remove_in}"
    [[ -n "$canonical" ]] && echo "canonical=${canonical}"
    [[ -n "$reason" ]] && echo "reason=${reason}"

    return 0
}

#######################################
# Check if template is marked as deprecated
#
# Determines if a template file has deprecation metadata in its frontmatter.
# A template is considered deprecated if it has "deprecated: true" in frontmatter.
#
# Arguments:
#   $1 - Template file path (required)
#
# Returns:
#   0 if template is deprecated
#   1 if template is not deprecated or has no frontmatter
#
# Outputs:
#   None (silent check)
#
# Example:
#   if is_deprecated "/path/to/template.md"; then
#     echo "Template is deprecated"
#   fi
#######################################
is_deprecated() {
    local template_file="$1"

    # Validate input
    if [[ -z "$template_file" ]]; then
        return 1
    fi

    # Parse metadata
    local metadata
    if ! metadata=$(parse_deprecation_metadata "$template_file" 2>/dev/null); then
        return 1  # No metadata or error
    fi

    # Extract deprecated field
    local deprecated
    deprecated=$(echo "$metadata" | grep "^deprecated=" | cut -d= -f2)

    # Check if deprecated is true
    if [[ "$deprecated" == "true" ]]; then
        return 0
    else
        return 1
    fi
}

#######################################
# Determine if deprecated template should be removed
#
# Checks if the current version has reached or exceeded the removal version
# specified in template's deprecation metadata. Used to decide if a deprecated
# template should still be installed or completely removed.
#
# Arguments:
#   $1 - Current system version (e.g., "0.4.0")
#   $2 - Removal version from template metadata (e.g., "0.4.0")
#
# Returns:
#   0 if current_version >= remove_in (should remove)
#   1 if current_version < remove_in (keep for now)
#   2 if either version is invalid
#
# Outputs:
#   Error messages via logging if validation fails
#
# Example:
#   if should_remove_deprecated "0.4.0" "0.4.0"; then
#     echo "Time to remove this deprecated template"
#   fi
#######################################
should_remove_deprecated() {
    local current_version="$1"
    local remove_in="$2"

    # Validate inputs
    if [[ -z "$current_version" ]] || [[ -z "$remove_in" ]]; then
        print_message "error" "should_remove_deprecated: Both versions required"
        return 2
    fi

    # Compare versions
    compare_versions "$current_version" "$remove_in"
    local result=$?

    if [[ $result -eq 3 ]]; then
        # Invalid version format
        return 2
    elif [[ $result -eq 1 ]] || [[ $result -eq 0 ]]; then
        # current >= remove_in
        return 0
    else
        # current < remove_in
        return 1
    fi
}

#######################################
# Get canonical replacement name for deprecated template
#
# Extracts the canonical (new) template name from a deprecated template's frontmatter.
# The canonical field points to the new template that replaces the deprecated one.
#
# Arguments:
#   $1 - Deprecated template file path (required)
#
# Returns:
#   0 on success
#   1 if canonical field not found or parsing failed
#
# Outputs:
#   Canonical template name to stdout (without path or extension)
#
# Example:
#   canonical=$(get_canonical_name "/path/to/create-issue-draft.md")
#   echo "$canonical"  # "issue-create"
#######################################
get_canonical_name() {
    local template_file="$1"

    # Validate input
    if [[ -z "$template_file" ]]; then
        print_message "error" "get_canonical_name: template_file required"
        return 1
    fi

    # Parse metadata
    local metadata
    if ! metadata=$(parse_deprecation_metadata "$template_file" 2>/dev/null); then
        return 1
    fi

    # Extract canonical field (already quote-stripped by extract_yaml_value)
    local canonical
    canonical=$(echo "$metadata" | grep "^canonical=" | cut -d= -f2)

    if [[ -z "$canonical" ]]; then
        return 1
    fi

    echo "$canonical"
    return 0
}

#######################################
# Scan directory for deprecated templates
#
# Recursively searches a directory for all templates marked as deprecated.
# Returns a list of deprecated template paths.
#
# Arguments:
#   $1 - Directory to scan (required)
#
# Returns:
#   0 on success (even if no deprecated templates found)
#   1 on failure (directory doesn't exist or not readable)
#
# Outputs:
#   One template path per line to stdout (only deprecated templates)
#
# Example:
#   deprecated_list=$(scan_deprecated_templates "/path/to/templates")
#   while IFS= read -r template; do
#     echo "Deprecated: $template"
#   done <<< "$deprecated_list"
#######################################
scan_deprecated_templates() {
    local template_dir="$1"

    # Validate input
    if [[ -z "$template_dir" ]]; then
        print_message "error" "scan_deprecated_templates: template_dir required"
        return 1
    fi

    # Check directory exists
    if [[ ! -d "$template_dir" ]]; then
        print_message "error" "Directory does not exist: ${template_dir}"
        return 1
    fi

    # Find all .md files and check if deprecated
    local deprecated_count=0

    while IFS= read -r template_file; do
        if is_deprecated "$template_file"; then
            echo "$template_file"
            deprecated_count=$((deprecated_count + 1))
        fi
    done < <(find "$template_dir" -type f -name "*.md")

    # Return 0 even if no deprecated templates found (successful scan)
    return 0
}

#######################################
# Detect conflicts between deprecated and canonical templates
#
# Checks if a user has both deprecated and canonical versions of templates installed.
# This can cause confusion and should be flagged during installation/upgrade.
#
# Arguments:
#   $1 - User's Claude config directory (e.g., ~/.claude)
#
# Returns:
#   0 if conflicts found (warnings displayed)
#   1 if no conflicts found or directory doesn't exist
#
# Outputs:
#   Warning messages for each conflict found
#
# Example:
#   if handle_deprecation_conflicts ~/.claude; then
#     echo "Conflicts detected - review warnings above"
#   fi
#######################################
handle_deprecation_conflicts() {
    local claude_dir="$1"

    # Validate input
    if [[ -z "$claude_dir" ]]; then
        print_message "error" "handle_deprecation_conflicts: claude_dir required"
        return 1
    fi

    # Check directory exists
    if [[ ! -d "$claude_dir" ]]; then
        # Not an error - directory might not exist yet (fresh install)
        return 1
    fi

    local conflicts_found=0

    # Scan for deprecated templates in .aida-deprecated namespace
    local deprecated_dir="${claude_dir}/commands/.aida-deprecated"
    if [[ ! -d "$deprecated_dir" ]]; then
        return 1  # No deprecated namespace - no conflicts
    fi

    # Check each deprecated template
    while IFS= read -r deprecated_template; do
        if [[ ! -f "$deprecated_template/README.md" ]]; then
            continue
        fi

        # Get canonical name
        local canonical
        if canonical=$(get_canonical_name "$deprecated_template/README.md" 2>/dev/null); then
            # Check if canonical version exists in .aida namespace
            local deprecated_name
            deprecated_name=$(basename "$deprecated_template")
            local canonical_template="${claude_dir}/commands/.aida/${canonical}"

            if [[ -d "$canonical_template" ]]; then
                print_message "warning" "Conflict detected: Both deprecated and canonical versions exist"
                print_message "info" "  Deprecated: ${deprecated_name} (in .aida-deprecated/)"
                print_message "info" "  Canonical:  ${canonical} (in .aida/)"
                print_message "info" "  Recommendation: Remove deprecated version"
                conflicts_found=$((conflicts_found + 1))
            fi
        fi
    done < <(find "$deprecated_dir" -mindepth 1 -maxdepth 1 -type d)

    if [[ $conflicts_found -gt 0 ]]; then
        echo ""
        print_message "warning" "Found ${conflicts_found} deprecation conflict(s)"
        print_message "info" "Run with --cleanup-deprecated to remove old versions"
        return 0
    else
        return 1
    fi
}

#######################################
# Determine if deprecated template should be installed
#
# Main decision function that determines whether a deprecated template should be
# installed based on flags, current version, and deprecation metadata.
#
# Decision logic:
#   1. If --with-deprecated flag is true -> install
#   2. If current_version >= remove_in -> do NOT install (removed)
#   3. Otherwise -> install (still in deprecation grace period)
#
# Arguments:
#   $1 - with_deprecated flag (true/false)
#   $2 - Current system version (e.g., "0.3.0")
#   $3 - Template file path
#
# Returns:
#   0 if template should be installed
#   1 if template should NOT be installed
#   2 if error (invalid inputs)
#
# Outputs:
#   None (silent decision)
#
# Example:
#   if should_install_deprecated "false" "0.3.0" "/path/to/template.md"; then
#     echo "Install this deprecated template"
#   fi
#######################################
should_install_deprecated() {
    local with_deprecated_flag="$1"
    local current_version="$2"
    local template_file="$3"

    # Validate inputs
    if [[ -z "$with_deprecated_flag" ]] || [[ -z "$current_version" ]] || [[ -z "$template_file" ]]; then
        print_message "error" "should_install_deprecated: All parameters required"
        return 2
    fi

    # Validate flag is boolean
    if [[ "$with_deprecated_flag" != "true" && "$with_deprecated_flag" != "false" ]]; then
        print_message "error" "should_install_deprecated: with_deprecated_flag must be 'true' or 'false'"
        return 2
    fi

    # Rule 1: If --with-deprecated flag is true, always install
    if [[ "$with_deprecated_flag" == "true" ]]; then
        return 0
    fi

    # Parse deprecation metadata
    local metadata
    if ! metadata=$(parse_deprecation_metadata "$template_file" 2>/dev/null); then
        # No deprecation metadata - not deprecated, install normally
        return 0
    fi

    # Extract remove_in version (already quote-stripped by extract_yaml_value)
    local remove_in
    remove_in=$(echo "$metadata" | grep "^remove_in=" | cut -d= -f2)

    if [[ -z "$remove_in" ]]; then
        # No remove_in specified - install (perpetual deprecation)
        return 0
    fi

    # Rule 2: Check if current_version >= remove_in
    if should_remove_deprecated "$current_version" "$remove_in"; then
        # Time to remove - do NOT install
        return 1
    else
        # Still in grace period - install
        return 0
    fi
}

#######################################
# Get deprecation reason from template metadata
#
# Extracts the human-readable reason for deprecation from template frontmatter.
# Used for displaying helpful messages to users about why a template was deprecated.
#
# Arguments:
#   $1 - Template file path (required)
#
# Returns:
#   0 on success
#   1 if reason field not found or parsing failed
#
# Outputs:
#   Deprecation reason to stdout
#
# Example:
#   reason=$(get_deprecation_reason "/path/to/template.md")
#   echo "This template was deprecated because: $reason"
#######################################
get_deprecation_reason() {
    local template_file="$1"

    # Validate input
    if [[ -z "$template_file" ]]; then
        print_message "error" "get_deprecation_reason: template_file required"
        return 1
    fi

    # Parse metadata
    local metadata
    if ! metadata=$(parse_deprecation_metadata "$template_file" 2>/dev/null); then
        return 1
    fi

    # Extract reason field (already quote-stripped by extract_yaml_value)
    local reason
    reason=$(echo "$metadata" | grep "^reason=" | cut -d= -f2)

    if [[ -z "$reason" ]]; then
        return 1
    fi

    echo "$reason"
    return 0
}

#######################################
# Get deprecated_in version from template metadata
#
# Extracts the version when template was first deprecated from frontmatter.
# Used for informational purposes and migration planning.
#
# Arguments:
#   $1 - Template file path (required)
#
# Returns:
#   0 on success
#   1 if deprecated_in field not found or parsing failed
#
# Outputs:
#   Version string to stdout (e.g., "0.2.0")
#
# Example:
#   deprecated_in=$(get_deprecated_in_version "/path/to/template.md")
#   echo "Template deprecated since: v$deprecated_in"
#######################################
get_deprecated_in_version() {
    local template_file="$1"

    # Validate input
    if [[ -z "$template_file" ]]; then
        print_message "error" "get_deprecated_in_version: template_file required"
        return 1
    fi

    # Parse metadata
    local metadata
    if ! metadata=$(parse_deprecation_metadata "$template_file" 2>/dev/null); then
        return 1
    fi

    # Extract deprecated_in field (already quote-stripped by extract_yaml_value)
    local deprecated_in
    deprecated_in=$(echo "$metadata" | grep "^deprecated_in=" | cut -d= -f2)

    if [[ -z "$deprecated_in" ]]; then
        return 1
    fi

    echo "$deprecated_in"
    return 0
}

#######################################
# Get remove_in version from template metadata
#
# Extracts the version when template will be completely removed from frontmatter.
# Used to determine if template should still be installed or has reached end-of-life.
#
# Arguments:
#   $1 - Template file path (required)
#
# Returns:
#   0 on success
#   1 if remove_in field not found or parsing failed
#
# Outputs:
#   Version string to stdout (e.g., "0.4.0")
#
# Example:
#   remove_in=$(get_remove_in_version "/path/to/template.md")
#   echo "Template will be removed in: v$remove_in"
#######################################
get_remove_in_version() {
    local template_file="$1"

    # Validate input
    if [[ -z "$template_file" ]]; then
        print_message "error" "get_remove_in_version: template_file required"
        return 1
    fi

    # Parse metadata
    local metadata
    if ! metadata=$(parse_deprecation_metadata "$template_file" 2>/dev/null); then
        return 1
    fi

    # Extract remove_in field (already quote-stripped by extract_yaml_value)
    local remove_in
    remove_in=$(echo "$metadata" | grep "^remove_in=" | cut -d= -f2)

    if [[ -z "$remove_in" ]]; then
        return 1
    fi

    echo "$remove_in"
    return 0
}
