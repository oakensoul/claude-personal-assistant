#!/usr/bin/env bash
#
# validation.sh - Input Validation and Security Controls
#
# Description:
#   Input sanitization, path validation, permission checking, and version
#   compatibility utilities for AIDA installer-common library.
#
# Dependencies:
#   - logging.sh (must be sourced first)
#
# Part of: AIDA installer-common library v1.0
# Usage:
#   source "${INSTALLER_COMMON}/colors.sh"
#   source "${INSTALLER_COMMON}/logging.sh"
#   source "${INSTALLER_COMMON}/validation.sh"
#
# Author: oakensoul
# License: AGPL-3.0
# Repository: https://github.com/oakensoul/claude-personal-assistant
#

set -euo pipefail

#######################################
# Validate semantic version format
# Arguments:
#   $1 - Version string to validate
# Returns:
#   0 if valid, 1 if invalid
#######################################
validate_version() {
    local version="$1"

    # Regex: MAJOR.MINOR.PATCH (digits only)
    if [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        return 0
    else
        return 1
    fi
}

#######################################
# Check semantic version compatibility
# Arguments:
#   $1 - Installed version (e.g., 0.1.2)
#   $2 - Required version (e.g., 0.1.0)
# Returns:
#   0 if compatible, 1 if incompatible
# Outputs:
#   Error message if incompatible
#######################################
check_version_compatibility() {
    local installed_version="$1"
    local required_version="$2"

    # Validate both versions first
    if ! validate_version "$installed_version"; then
        print_message "error" "Invalid installed version format: ${installed_version}"
        return 1
    fi

    if ! validate_version "$required_version"; then
        print_message "error" "Invalid required version format: ${required_version}"
        return 1
    fi

    # Parse versions: MAJOR.MINOR.PATCH
    local inst_major inst_minor inst_patch
    IFS='.' read -r inst_major inst_minor inst_patch <<< "$installed_version"

    local req_major req_minor req_patch
    IFS='.' read -r req_major req_minor req_patch <<< "$required_version"

    # Major version must match exactly
    if [[ "$inst_major" != "$req_major" ]]; then
        print_message "error" "Version incompatible: major version mismatch"
        print_message "info" "  Installed: v${installed_version} (major ${inst_major})"
        print_message "info" "  Required:  v${required_version} (major ${req_major})"
        return 1
    fi

    # Minor version must be >= required (forward compatible)
    if [[ "$inst_minor" -lt "$req_minor" ]]; then
        print_message "error" "Version incompatible: installed version too old"
        print_message "info" "  Installed: v${installed_version}"
        print_message "info" "  Required:  v${required_version} or higher"
        print_message "info" "  Upgrade:   cd ~/.aida && git pull && ./install.sh"
        return 1
    fi

    # Patch version doesn't matter for compatibility (minor handles it)
    return 0
}

#######################################
# Validate and canonicalize path
# Arguments:
#   $1 - Path to validate
#   $2 - Expected prefix (e.g., $HOME)
# Returns:
#   0 if valid, 1 if invalid
# Outputs:
#   Canonical path to stdout if valid
#######################################
validate_path() {
    local path="$1"
    local expected_prefix="${2:-$HOME}"

    # Check for path traversal patterns
    if [[ "$path" == *".."* ]]; then
        print_message "error" "Invalid path: contains '..' (path traversal attempt)"
        log_to_file "SECURITY" "Path traversal attempt blocked: $path"
        return 1
    fi

    # Require realpath for canonicalization
    if ! command -v realpath >/dev/null 2>&1; then
        print_message "error" "Required command not found: realpath"
        print_message "info" "Install on macOS: brew install coreutils"
        print_message "info" "Install on Linux: sudo apt-get install coreutils"
        return 1
    fi

    # Canonicalize path
    local canonical_path
    if ! canonical_path=$(realpath -m "$path" 2>/dev/null); then
        print_message "error" "Failed to canonicalize path: ${path}"
        return 1
    fi

    # Validate path is within expected prefix
    if [[ "$canonical_path" != "$expected_prefix"* ]]; then
        print_message "error" "Invalid path: outside allowed directory"
        print_message "info" "  Path: ${canonical_path}"
        print_message "info" "  Allowed prefix: ${expected_prefix}"
        log_to_file "SECURITY" "Path outside allowed directory blocked: $canonical_path"
        return 1
    fi

    # Output canonical path
    echo "$canonical_path"
    return 0
}

#######################################
# Validate file permissions (reject world-writable)
# Arguments:
#   $1 - File path to check
# Returns:
#   0 if valid, 1 if invalid
#######################################
validate_file_permissions() {
    local file="$1"

    if [[ ! -e "$file" ]]; then
        print_message "error" "File does not exist: ${file}"
        return 1
    fi

    # Get file permissions (platform-specific stat)
    local perms
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS (BSD stat)
        perms=$(stat -f "%Lp" "$file" 2>/dev/null || echo "")
    else
        # Linux (GNU stat)
        perms=$(stat -c "%a" "$file" 2>/dev/null || echo "")
    fi

    if [[ -z "$perms" ]]; then
        print_message "error" "Failed to read file permissions: ${file}"
        return 1
    fi

    # Check if world-writable (last digit is 2, 3, 6, or 7)
    local last_digit="${perms: -1}"
    if [[ "$last_digit" =~ [2367] ]]; then
        print_message "error" "Security: file is world-writable: ${file}"
        print_message "info" "  Permissions: ${perms}"
        print_message "info" "  Fix with: chmod go-w ${file}"
        log_to_file "SECURITY" "World-writable file rejected: $file (perms: $perms)"
        return 1
    fi

    return 0
}

#######################################
# Validate filename (alphanumeric, underscore, hyphen, dot)
# Arguments:
#   $1 - Filename to validate
# Returns:
#   0 if valid, 1 if invalid
#######################################
validate_filename() {
    local filename="$1"

    # No leading dot
    if [[ "$filename" == .* ]]; then
        print_message "error" "Invalid filename: cannot start with dot"
        return 1
    fi

    # Allowlist: alphanumeric, underscore, hyphen, dot
    if [[ ! "$filename" =~ ^[a-zA-Z0-9._-]+$ ]]; then
        print_message "error" "Invalid filename: must contain only letters, numbers, dots, underscores, hyphens"
        return 1
    fi

    return 0
}

#######################################
# Validate system dependencies
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   0 on success, 1 on failure
# Outputs:
#   Writes validation status to stdout/stderr
#######################################
validate_dependencies() {
    print_message "info" "Validating system dependencies..."

    local errors=0

    # Check bash version (require >= 3.2 for macOS compatibility)
    if [[ "${BASH_VERSINFO[0]}" -lt 3 ]] || { [[ "${BASH_VERSINFO[0]}" -eq 3 ]] && [[ "${BASH_VERSINFO[1]}" -lt 2 ]]; }; then
        print_message "error" "Bash version 3.2 or higher is required (found ${BASH_VERSION})"
        errors=$((errors + 1))
    else
        print_message "success" "Bash version ${BASH_VERSION}"
    fi

    # Check for required commands
    local required_commands=("git" "mkdir" "chmod" "ln" "rsync" "date" "mv" "find" "realpath")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            print_message "error" "Required command not found: $cmd"
            if [[ "$cmd" == "realpath" ]]; then
                print_message "info" "Install realpath on macOS: brew install coreutils"
            fi
            errors=$((errors + 1))
        fi
    done

    if [[ $errors -eq 0 ]]; then
        print_message "success" "All dependencies validated"
    fi

    # Check write permissions to home directory
    if [[ ! -w "${HOME}" ]]; then
        print_message "error" "No write permission to home directory: ${HOME}"
        errors=$((errors + 1))
    fi

    return "$errors"
}

#######################################
# Validate VERSION file and return version
# Arguments:
#   $1 - Path to VERSION file
# Returns:
#   0 if valid, 1 if invalid
# Outputs:
#   Version string to stdout if valid
#######################################
validate_version_file() {
    local version_file="$1"

    # Check file exists
    if [[ ! -f "$version_file" ]]; then
        print_message "error" "VERSION file not found: ${version_file}"
        return 1
    fi

    # Check file permissions
    if ! validate_file_permissions "$version_file"; then
        return 1
    fi

    # Read version
    local version
    version=$(cat "$version_file" 2>/dev/null | head -1 | tr -d '[:space:]')

    if [[ -z "$version" ]]; then
        print_message "error" "VERSION file is empty: ${version_file}"
        return 1
    fi

    # Validate version format
    if ! validate_version "$version"; then
        print_message "error" "Invalid version format in VERSION file: ${version}"
        print_message "info" "  Expected format: MAJOR.MINOR.PATCH (e.g., 0.1.2)"
        return 1
    fi

    # Output version
    echo "$version"
    return 0
}
