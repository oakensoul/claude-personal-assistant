#!/usr/bin/env bash
#
# directories.sh - Directory Creation and Symlink Management
#
# Description:
#   Directory creation, symlink management, and backup operations for AIDA installer-common library.
#   Handles filesystem operations including the critical .aida namespace isolation that prevents
#   user data loss. All operations are idempotent and cross-platform compatible (macOS/Linux).
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
#   source "${INSTALLER_COMMON}/directories.sh"
#
# Author: oakensoul
# License: AGPL-3.0
# Repository: https://github.com/oakensoul/claude-personal-assistant
#

set -euo pipefail

#######################################
# Get symlink target path (cross-platform)
#
# Reads the target of a symlink using platform-specific commands.
# Handles differences between macOS (BSD) and Linux (GNU) readlink.
#
# Arguments:
#   $1 - Symlink path to read (required)
#
# Returns:
#   0 on success
#   1 if symlink does not exist or is not a symlink
#
# Outputs:
#   Writes symlink target path to stdout
#
# Example:
#   target=$(get_symlink_target ~/.aida)
#######################################
get_symlink_target() {
    local symlink="$1"

    # Validate input
    if [[ -z "$symlink" ]]; then
        print_message "error" "get_symlink_target: symlink path required"
        return 1
    fi

    # Check if path exists and is a symlink
    if [[ ! -L "$symlink" ]]; then
        print_message "error" "Path is not a symlink: ${symlink}"
        return 1
    fi

    # Platform-specific symlink reading
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS (BSD) - readlink without -f flag
        readlink "$symlink" || {
            print_message "error" "Failed to read symlink: ${symlink}"
            return 1
        }
    else
        # Linux (GNU) - readlink with -f for canonical path
        readlink -f "$symlink" || {
            print_message "error" "Failed to read symlink: ${symlink}"
            return 1
        }
    fi
}

#######################################
# Validate symlink points to expected target
#
# Checks if a symlink exists and points to the expected target path.
# Uses platform-specific symlink reading for compatibility.
#
# Arguments:
#   $1 - Symlink path to validate (required)
#   $2 - Expected target path (required)
#
# Returns:
#   0 if symlink is valid and points to expected target
#   1 if symlink is broken, missing, or points to wrong target
#
# Outputs:
#   Writes validation messages via logging
#
# Example:
#   if validate_symlink ~/.aida /path/to/repo; then
#       echo "Symlink is correct"
#   fi
#######################################
validate_symlink() {
    local symlink="$1"
    local expected_target="$2"

    # Validate inputs
    if [[ -z "$symlink" ]]; then
        print_message "error" "validate_symlink: symlink path required"
        return 1
    fi

    if [[ -z "$expected_target" ]]; then
        print_message "error" "validate_symlink: expected_target required"
        return 1
    fi

    # Check if symlink exists
    if [[ ! -L "$symlink" ]]; then
        if [[ -e "$symlink" ]]; then
            print_message "error" "Path exists but is not a symlink: ${symlink}"
        else
            print_message "error" "Symlink does not exist: ${symlink}"
        fi
        return 1
    fi

    # Get actual target
    local actual_target
    actual_target=$(get_symlink_target "$symlink") || return 1

    # Normalize both paths for comparison (resolve to absolute)
    local normalized_expected
    local normalized_actual

    # Normalize expected target (make absolute if needed)
    if [[ "$expected_target" == /* ]]; then
        normalized_expected="$expected_target"
    else
        normalized_expected="$(cd "$(dirname "$expected_target")" 2>/dev/null && pwd)/$(basename "$expected_target")" || {
            print_message "error" "Cannot normalize expected target: ${expected_target}"
            return 1
        }
    fi

    # Normalize actual target (make absolute if relative)
    if [[ "$actual_target" == /* ]]; then
        normalized_actual="$actual_target"
    else
        # Relative symlink - resolve from symlink's directory
        local symlink_dir
        symlink_dir="$(cd "$(dirname "$symlink")" && pwd)"
        normalized_actual="$(cd "${symlink_dir}" && cd "$actual_target" 2>/dev/null && pwd)" || {
            print_message "error" "Symlink target does not exist (broken link): ${actual_target}"
            return 1
        }
    fi

    # Compare normalized paths
    if [[ "$normalized_actual" == "$normalized_expected" ]]; then
        return 0
    else
        print_message "error" "Symlink points to wrong target"
        print_message "info" "  Expected: ${normalized_expected}"
        print_message "info" "  Actual:   ${normalized_actual}"
        return 1
    fi
}

#######################################
# Create symlink with idempotent behavior
#
# Creates a symlink from link_name to target with safe, idempotent behavior.
# If symlink exists and points to correct target, does nothing.
# If symlink exists but points to wrong target, recreates it.
# If path exists but is not a symlink, returns error.
#
# Arguments:
#   $1 - Target path (must exist, required)
#   $2 - Symlink path to create (required)
#
# Returns:
#   0 on success (symlink created or already correct)
#   1 on failure (target doesn't exist, permissions issue, etc.)
#
# Outputs:
#   Writes status messages via logging
#
# Example:
#   create_symlink /path/to/repo ~/.aida
#######################################
create_symlink() {
    local target="$1"
    local link_name="$2"

    # Validate inputs
    if [[ -z "$target" ]]; then
        print_message "error" "create_symlink: target path required"
        return 1
    fi

    if [[ -z "$link_name" ]]; then
        print_message "error" "create_symlink: link_name required"
        return 1
    fi

    # Validate target exists
    if [[ ! -e "$target" ]]; then
        print_message "error" "Symlink target does not exist: ${target}"
        return 1
    fi

    # If symlink already exists, check if it points to correct target
    if [[ -L "$link_name" ]]; then
        if validate_symlink "$link_name" "$target" 2>/dev/null; then
            print_message "info" "Symlink already correct: ${link_name} -> ${target}"
            return 0
        else
            print_message "warning" "Symlink points to wrong target, recreating"
            rm "$link_name" || {
                print_message "error" "Failed to remove incorrect symlink: ${link_name}"
                return 1
            }
        fi
    elif [[ -e "$link_name" ]]; then
        print_message "error" "Path exists but is not a symlink: ${link_name}"
        print_message "info" "  Cannot create symlink at existing non-symlink path"
        print_message "info" "  Remove or rename the existing path first"
        return 1
    fi

    # Create parent directory if needed
    local link_dir
    link_dir="$(dirname "$link_name")"
    if [[ ! -d "$link_dir" ]]; then
        mkdir -p "$link_dir" || {
            print_message "error" "Failed to create directory for symlink: ${link_dir}"
            return 1
        }
    fi

    # Create symlink
    ln -s "$target" "$link_name" || {
        print_message "error" "Failed to create symlink: ${link_name} -> ${target}"
        return 1
    }

    print_message "success" "Created symlink: ${link_name} -> ${target}"
    return 0
}

#######################################
# Backup existing directory or file with timestamp
#
# Creates a timestamped backup of a directory or file.
# Uses format: {original}.backup.YYYYMMDD-HHMMSS
# Idempotent: if target doesn't exist, returns success (nothing to backup).
#
# Arguments:
#   $1 - Path to backup (directory or file, required)
#
# Returns:
#   0 on success (backup created or target doesn't exist)
#   1 on failure (backup failed)
#
# Outputs:
#   Writes backup status via logging
#
# Example:
#   backup_existing ~/.claude/commands
#######################################
backup_existing() {
    local target="$1"

    # Validate input
    if [[ -z "$target" ]]; then
        print_message "error" "backup_existing: target path required"
        return 1
    fi

    # If target doesn't exist, nothing to backup (idempotent)
    if [[ ! -e "$target" ]]; then
        print_message "info" "No backup needed: ${target} does not exist"
        return 0
    fi

    # Generate backup path with timestamp
    local timestamp
    timestamp=$(date +%Y%m%d-%H%M%S)
    local backup_path="${target}.backup.${timestamp}"

    # Create backup
    if [[ -d "$target" ]]; then
        # Directory backup
        cp -a "$target" "$backup_path" || {
            print_message "error" "Failed to backup directory: ${target}"
            return 1
        }
        print_message "success" "Backed up directory: ${target} -> ${backup_path}"
    elif [[ -f "$target" ]]; then
        # File backup
        cp -p "$target" "$backup_path" || {
            print_message "error" "Failed to backup file: ${target}"
            return 1
        }
        print_message "success" "Backed up file: ${target} -> ${backup_path}"
    else
        print_message "warning" "Target is neither file nor directory: ${target}"
        return 1
    fi

    return 0
}

#######################################
# Create Claude configuration directory structure
#
# Creates the ~/.claude/ directory structure with proper permissions.
# Includes: commands, agents, skills, config, knowledge, memory subdirectories.
# Idempotent: safe to call multiple times.
#
# Arguments:
#   $1 - Claude directory path (e.g., ~/.claude, required)
#
# Returns:
#   0 on success (all directories created)
#   1 on failure
#
# Outputs:
#   Writes creation status via logging
#
# Example:
#   create_claude_dirs ~/.claude
#######################################
create_claude_dirs() {
    local claude_dir="$1"

    # Validate input
    if [[ -z "$claude_dir" ]]; then
        print_message "error" "create_claude_dirs: claude_dir required"
        return 1
    fi

    # Validate path is a directory path (not a file)
    if [[ -f "$claude_dir" ]]; then
        print_message "error" "Path is a file, not a directory: ${claude_dir}"
        return 1
    fi

    # Define directory structure
    local dirs=(
        "$claude_dir"
        "$claude_dir/commands"
        "$claude_dir/agents"
        "$claude_dir/skills"
        "$claude_dir/documents"
        "$claude_dir/config"
        "$claude_dir/knowledge"
        "$claude_dir/memory"
        "$claude_dir/memory/history"
    )

    # Create directories
    for dir in "${dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            print_message "info" "Directory already exists: ${dir}"
        else
            mkdir -p "$dir" || {
                print_message "error" "Failed to create directory: ${dir}"
                return 1
            }
            chmod 755 "$dir"
            print_message "success" "Created directory: ${dir}"
        fi
    done

    return 0
}

#######################################
# Create namespace subdirectories in Claude directories
#
# Creates .aida/ or .aida-deprecated/ subdirectories in commands, agents, skills.
# This implements the namespace isolation pattern from ADR-013.
# Idempotent: safe to call multiple times.
#
# Arguments:
#   $1 - Claude directory path (e.g., ~/.claude, required)
#   $2 - Namespace name (e.g., ".aida" or ".aida-deprecated", required)
#
# Returns:
#   0 on success (all namespace directories created)
#   1 on failure
#
# Outputs:
#   Writes creation status via logging
#
# Example:
#   create_namespace_dirs ~/.claude .aida
#   create_namespace_dirs ~/.claude .aida-deprecated
#######################################
create_namespace_dirs() {
    local claude_dir="$1"
    local namespace="$2"

    # Validate inputs
    if [[ -z "$claude_dir" ]]; then
        print_message "error" "create_namespace_dirs: claude_dir required"
        return 1
    fi

    if [[ -z "$namespace" ]]; then
        print_message "error" "create_namespace_dirs: namespace required"
        return 1
    fi

    # Validate namespace format (should be .aida or .aida-deprecated)
    if [[ "$namespace" != ".aida" && "$namespace" != ".aida-deprecated" ]]; then
        print_message "warning" "Unusual namespace: ${namespace} (expected .aida or .aida-deprecated)"
    fi

    # Define namespace subdirectories
    local namespace_dirs=(
        "$claude_dir/commands/$namespace"
        "$claude_dir/agents/$namespace"
        "$claude_dir/skills/$namespace"
    )

    # Create namespace directories
    for dir in "${namespace_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            print_message "info" "Namespace directory already exists: ${dir}"
        else
            # Create parent if needed (should already exist from create_claude_dirs)
            local parent_dir
            parent_dir="$(dirname "$dir")"
            if [[ ! -d "$parent_dir" ]]; then
                mkdir -p "$parent_dir" || {
                    print_message "error" "Failed to create parent directory: ${parent_dir}"
                    return 1
                }
            fi

            # Create namespace directory
            mkdir -p "$dir" || {
                print_message "error" "Failed to create namespace directory: ${dir}"
                return 1
            }
            chmod 755 "$dir"
            print_message "success" "Created namespace directory: ${dir}"
        fi
    done

    return 0
}

#######################################
# Create AIDA directory as symlink to repository
#
# Creates ~/.aida/ as a symlink to the repository directory.
# This is used for both normal and dev mode installations.
# In AIDA architecture, ~/.aida/ is ALWAYS a symlink to the repo.
# Idempotent: safe to call multiple times.
#
# Arguments:
#   $1 - Repository directory path (must exist, required)
#   $2 - AIDA directory path (e.g., ~/.aida, required)
#
# Returns:
#   0 on success (symlink created or already correct)
#   1 on failure
#
# Outputs:
#   Writes creation status via logging
#
# Example:
#   create_aida_dir /path/to/claude-personal-assistant ~/.aida
#######################################
create_aida_dir() {
    local repo_dir="$1"
    local aida_dir="$2"

    # Validate inputs
    if [[ -z "$repo_dir" ]]; then
        print_message "error" "create_aida_dir: repo_dir required"
        return 1
    fi

    if [[ -z "$aida_dir" ]]; then
        print_message "error" "create_aida_dir: aida_dir required"
        return 1
    fi

    # Validate repo_dir exists and is a directory
    if [[ ! -d "$repo_dir" ]]; then
        print_message "error" "Repository directory does not exist: ${repo_dir}"
        return 1
    fi

    # Check if aida_dir already exists
    if [[ -e "$aida_dir" ]]; then
        # If it's a symlink, validate it points to correct target
        if [[ -L "$aida_dir" ]]; then
            if validate_symlink "$aida_dir" "$repo_dir" 2>/dev/null; then
                print_message "info" "AIDA directory already symlinked correctly: ${aida_dir} -> ${repo_dir}"
                return 0
            else
                print_message "warning" "AIDA directory is symlink but points to wrong target"
                print_message "info" "Creating backup and recreating symlink..."
                backup_existing "$aida_dir" || return 1
                rm "$aida_dir" || {
                    print_message "error" "Failed to remove incorrect symlink: ${aida_dir}"
                    return 1
                }
            fi
        else
            # Not a symlink - backup before replacing
            print_message "warning" "AIDA directory exists but is not a symlink"
            print_message "info" "Creating backup before replacing with symlink..."
            backup_existing "$aida_dir" || return 1
            rm -rf "$aida_dir" || {
                print_message "error" "Failed to remove existing AIDA directory: ${aida_dir}"
                return 1
            }
        fi
    fi

    # Create symlink
    create_symlink "$repo_dir" "$aida_dir" || {
        print_message "error" "Failed to create AIDA directory symlink"
        return 1
    }

    print_message "success" "AIDA directory created: ${aida_dir} -> ${repo_dir}"
    return 0
}
