#!/usr/bin/env bash
#
# migrations.sh - Data Migration Helpers
#
# Description:
#   Handles backward compatibility migrations for breaking changes.
#   Automatically migrates old directory structures to new patterns.
#
# Dependencies:
#   - colors.sh (must be sourced first)
#   - logging.sh (must be sourced first)
#
# Part of: AIDA installer-common library v1.0
# Usage:
#   source "${INSTALLER_COMMON}/colors.sh"
#   source "${INSTALLER_COMMON}/logging.sh"
#   source "${INSTALLER_COMMON}/migrations.sh"
#   run_migrations
#
# Author: oakensoul
# License: AGPL-3.0
# Repository: https://github.com/oakensoul/claude-personal-assistant
#

set -euo pipefail

#######################################
# Migrate .claude/agents-global/ to .claude/project/agents/
# Arguments:
#   $1 - Base directory (typically .claude)
# Returns:
#   0 on success, 1 on failure
# Outputs:
#   Migration status to stdout
#######################################
migrate_agents_global_to_project() {
    local base_dir="$1"
    local old_path="${base_dir}/agents-global"
    local new_path="${base_dir}/project/agents"

    # Check if old directory exists
    if [[ ! -d "$old_path" ]]; then
        return 0  # Nothing to migrate
    fi

    # Check if new directory already exists
    if [[ -d "$new_path" ]]; then
        print_message "warning" "Both ${old_path} and ${new_path} exist"
        print_message "info" "Skipping migration - manual intervention required"
        return 0
    fi

    print_message "info" "Migrating ${old_path} → ${new_path}"

    # Create parent directory
    mkdir -p "$(dirname "$new_path")" || {
        print_message "error" "Failed to create directory: $(dirname "$new_path")"
        return 1
    }

    # Move old directory to new location
    mv "$old_path" "$new_path" || {
        print_message "error" "Failed to move ${old_path} to ${new_path}"
        return 1
    }

    print_message "success" "Migration complete: agents-global → project/agents"
    return 0
}

#######################################
# Run all available migrations
# Arguments:
#   None (uses global CLAUDE_DIR if set)
# Returns:
#   0 on success
# Outputs:
#   Migration status to stdout
#######################################
run_migrations() {
    local claude_dir="${CLAUDE_DIR:-$HOME/.claude}"

    print_message "info" "Checking for required migrations..."

    # Run each migration
    local migrations_run=0

    # Migration 1: agents-global → project/agents (v0.2.0)
    if migrate_agents_global_to_project "$claude_dir"; then
        if [[ -d "${claude_dir}/project/agents" ]]; then
            ((migrations_run++))
        fi
    fi

    # Future migrations can be added here
    # Example:
    # if migrate_something_else "$claude_dir"; then
    #     ((migrations_run++))
    # fi

    if [[ $migrations_run -gt 0 ]]; then
        print_message "success" "Completed $migrations_run migration(s)"
    else
        print_message "info" "No migrations needed"
    fi

    return 0
}

#######################################
# Check if migrations are needed
# Arguments:
#   None (uses global CLAUDE_DIR if set)
# Returns:
#   0 if migrations needed, 1 if not
#######################################
check_migrations_needed() {
    local claude_dir="${CLAUDE_DIR:-$HOME/.claude}"

    # Check for agents-global
    if [[ -d "${claude_dir}/agents-global" ]] && [[ ! -d "${claude_dir}/project/agents" ]]; then
        return 0  # Migration needed
    fi

    # Add checks for future migrations here

    return 1  # No migrations needed
}

# Export functions for use in other scripts
export -f migrate_agents_global_to_project
export -f run_migrations
export -f check_migrations_needed
