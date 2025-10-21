#!/usr/bin/env bash
#
# config-migration.sh - Configuration Backup and Migration Utilities
#
# Description:
#   Configuration backup, restoration, and migration utilities for AIDA config system.
#   Provides safe backup/restore operations with atomic operations and validation.
#
# Part of: AIDA Configuration System (Issue #55)
# Created: 2025-10-20
#
# Usage:
#   # As library
#   source lib/installer-common/config-migration.sh
#   backup_config ~/.claude/config.json
#   restore_config_from_backup ~/.claude/config.json.backup.20251020-213045
#
#   # As CLI
#   ./config-migration.sh backup ~/.claude/config.json
#   ./config-migration.sh list ~/.claude/config.json
#   ./config-migration.sh restore backup-file.json [target-file]
#   ./config-migration.sh cleanup ~/.claude/config.json [max-backups]
#
# Author: oakensoul
# License: AGPL-3.0
# Repository: https://github.com/oakensoul/claude-personal-assistant
#

# Only apply strict mode when executed directly, not when sourced
# (sourcing with -u causes issues with bats internal variables)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    set -euo pipefail
fi

# Constants
# Declare and assign separately to avoid masking return values (SC2155)
# Allow SCRIPT_DIR to be inherited if already set (when sourced by other scripts)
if [[ -z "${SCRIPT_DIR:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    readonly SCRIPT_DIR
fi
readonly BACKUP_EXTENSION=".backup"
readonly MAX_BACKUPS=5

# Exit codes (integers don't need quoting but we follow style for consistency)
readonly EXIT_SUCCESS=0
readonly EXIT_VALIDATION_ERROR=1
readonly EXIT_IO_ERROR=2
readonly EXIT_OPERATION_ABORTED=3

# Source dependencies (allow failure for standalone usage)
# shellcheck source=lib/installer-common/colors.sh
if [[ -f "${SCRIPT_DIR}/colors.sh" ]]; then
    source "${SCRIPT_DIR}/colors.sh"
else
    # Fallback color functions if colors.sh not available
    color_red() { echo "$1"; }
    color_green() { echo "$1"; }
    color_yellow() { echo "$1"; }
    color_blue() { echo "$1"; }
fi

# shellcheck source=lib/installer-common/logging.sh
if [[ -f "${SCRIPT_DIR}/logging.sh" ]]; then
    source "${SCRIPT_DIR}/logging.sh"
else
    # Fallback logging functions if logging.sh not available
    print_message() {
        local type="$1"
        local message="$2"
        case "$type" in
            error) echo "ERROR: $message" >&2 ;;
            warning) echo "WARNING: $message" >&2 ;;
            success) echo "SUCCESS: $message" ;;
            *) echo "$message" ;;
        esac
    }
fi

#######################################
# Validate JSON file syntax
# Arguments:
#   $1 - Path to JSON file
# Returns:
#   0 if valid JSON, 1 otherwise
#######################################
validate_json_file() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        return 1
    fi

    if ! command -v jq &>/dev/null; then
        # If jq not available, do basic validation with python
        if command -v python3 &>/dev/null; then
            python3 -c "import json; json.load(open('$file'))" 2>/dev/null
            return $?
        fi
        # Can't validate without jq or python, assume valid
        return 0
    fi

    jq empty "$file" 2>/dev/null
}

#######################################
# Get file size in bytes (cross-platform)
# Arguments:
#   $1 - Path to file
# Outputs:
#   File size in bytes
# Returns:
#   0 on success, 1 on failure
#######################################
get_file_size() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        return 1
    fi

    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS (BSD stat)
        stat -f%z "$file"
    else
        # Linux (GNU stat)
        stat -c%s "$file"
    fi
}

#######################################
# Get file modification time (cross-platform)
# Arguments:
#   $1 - Path to file
# Outputs:
#   File modification time (epoch seconds)
# Returns:
#   0 on success, 1 on failure
#######################################
get_file_mtime() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        return 1
    fi

    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS (BSD stat)
        stat -f%m "$file"
    else
        # Linux (GNU stat)
        stat -c%Y "$file"
    fi
}

#######################################
# Format file size for human readability
# Arguments:
#   $1 - Size in bytes
# Outputs:
#   Human-readable size (e.g., "1.2K", "3.4M")
#######################################
format_size() {
    local size="$1"
    local unit="B"

    if (( size > 1024 )); then
        size=$((size / 1024))
        unit="K"
    fi

    if (( size > 1024 )); then
        size=$((size / 1024))
        unit="M"
    fi

    if (( size > 1024 )); then
        size=$((size / 1024))
        unit="G"
    fi

    echo "${size}${unit}"
}

#######################################
# Create timestamped backup of configuration file
# Arguments:
#   $1 - Path to configuration file
# Outputs:
#   Backup file path on success
# Returns:
#   0 on success
#   1 on validation error
#   2 on I/O error
#######################################
backup_config() {
    local config_file="$1"
    local timestamp
    timestamp=$(date +%Y%m%d-%H%M%S)
    local backup_file="${config_file}${BACKUP_EXTENSION}.${timestamp}"

    # Validate source file exists
    if [[ ! -f "$config_file" ]]; then
        print_message "error" "Configuration file does not exist: $config_file"
        return "$EXIT_VALIDATION_ERROR"
    fi

    # Validate source file is valid JSON
    if ! validate_json_file "$config_file"; then
        print_message "error" "Configuration file is not valid JSON: $config_file"
        return "$EXIT_VALIDATION_ERROR"
    fi

    # Create backup using atomic operation (temp file + move)
    local temp_backup="${backup_file}.tmp.$$"

    if ! cp -a "$config_file" "$temp_backup" 2>/dev/null; then
        print_message "error" "Failed to create backup (I/O error)"
        rm -f "$temp_backup" 2>/dev/null || true
        return "$EXIT_IO_ERROR"
    fi

    # Validate backup was created successfully
    if ! validate_json_file "$temp_backup"; then
        print_message "error" "Backup validation failed"
        rm -f "$temp_backup" 2>/dev/null || true
        return "$EXIT_VALIDATION_ERROR"
    fi

    # Atomic move (same filesystem)
    if ! mv "$temp_backup" "$backup_file" 2>/dev/null; then
        print_message "error" "Failed to finalize backup (I/O error)"
        rm -f "$temp_backup" 2>/dev/null || true
        return "$EXIT_IO_ERROR"
    fi

    print_message "success" "Created backup: $backup_file" >&2
    echo "$backup_file"
    return "$EXIT_SUCCESS"
}

#######################################
# Restore configuration from backup file
# Arguments:
#   $1 - Path to backup file
#   $2 - Target file path (optional, derived from backup if not provided)
# Outputs:
#   Success message on completion
# Returns:
#   0 on success
#   1 on validation error
#   2 on I/O error
#######################################
restore_config_from_backup() {
    local backup_file="$1"
    local target_file="${2:-}"

    # Validate backup file exists
    if [[ ! -f "$backup_file" ]]; then
        print_message "error" "Backup file does not exist: $backup_file"
        return "$EXIT_VALIDATION_ERROR"
    fi

    # Derive target file from backup name if not provided
    if [[ -z "$target_file" ]]; then
        # Remove .backup.TIMESTAMP suffix
        # Quote expansion separately for SC2295
        target_file="${backup_file%%"${BACKUP_EXTENSION}".*}"

        if [[ "$target_file" == "$backup_file" ]]; then
            print_message "error" "Could not derive target file from backup name: $backup_file"
            return "$EXIT_VALIDATION_ERROR"
        fi
    fi

    # Validate backup file is valid JSON
    if ! validate_json_file "$backup_file"; then
        print_message "error" "Backup file is not valid JSON: $backup_file"
        return "$EXIT_VALIDATION_ERROR"
    fi

    # Create backup of existing target if it exists
    if [[ -f "$target_file" ]]; then
        local pre_restore_backup
        pre_restore_backup="${target_file}${BACKUP_EXTENSION}.pre-restore.$(date +%Y%m%d-%H%M%S)"
        if ! cp -a "$target_file" "$pre_restore_backup" 2>/dev/null; then
            print_message "warning" "Could not backup existing file before restore"
        else
            print_message "info" "Backed up existing file: $pre_restore_backup"
        fi
    fi

    # Atomic restore (write to temp, validate, then move)
    local temp_restore="${target_file}.tmp.$$"

    if ! cp -a "$backup_file" "$temp_restore" 2>/dev/null; then
        print_message "error" "Failed to copy backup file (I/O error)"
        rm -f "$temp_restore" 2>/dev/null || true
        return "$EXIT_IO_ERROR"
    fi

    # Validate restored content
    if ! validate_json_file "$temp_restore"; then
        print_message "error" "Restored file validation failed"
        rm -f "$temp_restore" 2>/dev/null || true
        return "$EXIT_VALIDATION_ERROR"
    fi

    # Ensure target directory exists
    local target_dir
    target_dir=$(dirname "$target_file")
    if [[ ! -d "$target_dir" ]]; then
        if ! mkdir -p "$target_dir" 2>/dev/null; then
            print_message "error" "Failed to create target directory: $target_dir"
            rm -f "$temp_restore" 2>/dev/null || true
            return "$EXIT_IO_ERROR"
        fi
    fi

    # Atomic move
    if ! mv "$temp_restore" "$target_file" 2>/dev/null; then
        print_message "error" "Failed to finalize restore (I/O error)"
        rm -f "$temp_restore" 2>/dev/null || true
        return "$EXIT_IO_ERROR"
    fi

    print_message "success" "Restored configuration from: $backup_file"
    return "$EXIT_SUCCESS"
}

#######################################
# Cleanup old backups, keeping only the most recent N
# Arguments:
#   $1 - Path to configuration file
#   $2 - Maximum number of backups to keep (default: MAX_BACKUPS)
# Outputs:
#   Number of backups deleted
# Returns:
#   0 on success
#######################################
cleanup_old_backups() {
    local config_file="$1"
    local max_backups="${2:-$MAX_BACKUPS}"

    # Find all backups for this config file, sorted by modification time (newest first)
    local backup_pattern="${config_file}${BACKUP_EXTENSION}.*"
    local backups=()

    # Use process substitution to avoid subshell issues with array population
    while IFS= read -r -d '' backup; do
        backups+=("$backup")
    done < <(find "$(dirname "$config_file")" -maxdepth 1 -type f -name "$(basename "$backup_pattern")" -print0 2>/dev/null | sort -zr)

    local total_backups=${#backups[@]}

    if (( total_backups <= max_backups )); then
        print_message "info" "Found $total_backups backup(s), keeping all (max: $max_backups)"
        echo "0"
        return "$EXIT_SUCCESS"
    fi

    # Delete old backups (keep newest max_backups)
    local deleted_count=0
    local i=0

    for backup in "${backups[@]}"; do
        if (( i >= max_backups )); then
            if rm -f "$backup" 2>/dev/null; then
                ((deleted_count++))
                print_message "info" "Deleted old backup: $(basename "$backup")"
            else
                print_message "warning" "Failed to delete backup: $(basename "$backup")"
            fi
        fi
        ((i++))
    done

    print_message "success" "Cleaned up $deleted_count old backup(s), kept $max_backups most recent"
    echo "$deleted_count"
    return "$EXIT_SUCCESS"
}

#######################################
# List all backups for a configuration file
# Arguments:
#   $1 - Path to configuration file
# Outputs:
#   Formatted list of backups with timestamps and sizes
# Returns:
#   Number of backups found
#######################################
list_backups() {
    local config_file="$1"
    local backup_pattern="${config_file}${BACKUP_EXTENSION}.*"
    local backups=()

    # Find all backups, sorted by modification time (newest first)
    while IFS= read -r -d '' backup; do
        backups+=("$backup")
    done < <(find "$(dirname "$config_file")" -maxdepth 1 -type f -name "$(basename "$backup_pattern")" -print0 2>/dev/null | sort -zr)

    local total_backups=${#backups[@]}

    if (( total_backups == 0 )); then
        print_message "info" "No backups found for: $config_file"
        echo "0"
        return "$EXIT_SUCCESS"
    fi

    color_blue "Backups for: $config_file"
    echo ""

    local i=1
    for backup in "${backups[@]}"; do
        local basename
        basename=$(basename "$backup")

        local size
        size=$(get_file_size "$backup" 2>/dev/null || echo "0")
        local size_formatted
        size_formatted=$(format_size "$size")

        # Extract timestamp from filename
        # Quote expansion separately for SC2295
        local timestamp="${basename##*"${BACKUP_EXTENSION}".}"

        # Format timestamp for display (YYYY-MM-DD HH:MM:SS)
        local display_timestamp
        if [[ "$timestamp" =~ ^([0-9]{8})-([0-9]{6})$ ]]; then
            local date_part="${BASH_REMATCH[1]}"
            local time_part="${BASH_REMATCH[2]}"
            display_timestamp="${date_part:0:4}-${date_part:4:2}-${date_part:6:2} ${time_part:0:2}:${time_part:2:2}:${time_part:4:2}"
        else
            display_timestamp="$timestamp"
        fi

        printf "  %d. %s  [%s]  (%s)\n" "$i" "$display_timestamp" "$size_formatted" "$backup"
        ((i++))
    done

    echo ""
    print_message "success" "Found $total_backups backup(s)"
    echo "$total_backups"
    return "$EXIT_SUCCESS"
}

#######################################
# Get the most recent backup for a configuration file
# Arguments:
#   $1 - Path to configuration file
# Outputs:
#   Path to most recent backup
# Returns:
#   0 on success, 1 if no backups found
#######################################
get_latest_backup() {
    local config_file="$1"
    local backup_pattern="${config_file}${BACKUP_EXTENSION}.*"

    # Find most recent backup
    local latest_backup
    latest_backup=$(find "$(dirname "$config_file")" -maxdepth 1 -type f -name "$(basename "$backup_pattern")" 2>/dev/null | sort -r | head -n 1)

    if [[ -z "$latest_backup" ]]; then
        print_message "error" "No backups found for: $config_file"
        return "$EXIT_VALIDATION_ERROR"
    fi

    echo "$latest_backup"
    return "$EXIT_SUCCESS"
}

#######################################
# Migration Functions
#######################################

#######################################
# Detect configuration version
# Arguments:
#   $1 - Path to configuration file
# Outputs:
#   Version string (e.g., "1.0", "2.0", "unknown")
# Returns:
#   0 on success
#######################################
detect_config_version() {
    local config_file="$1"

    if [[ ! -f "$config_file" ]]; then
        echo "unknown"
        return "$EXIT_SUCCESS"
    fi

    # Try to read config_version field
    local version
    version=$(jq -r '.config_version // empty' "$config_file" 2>/dev/null)

    if [[ -n "$version" ]]; then
        echo "$version"
        return "$EXIT_SUCCESS"
    fi

    # Check for old-style config (has github.* namespace)
    local has_github
    has_github=$(jq -r 'has("github")' "$config_file" 2>/dev/null)

    if [[ "$has_github" == "true" ]]; then
        echo "1.0"
        return "$EXIT_SUCCESS"
    fi

    # Check for new-style config (has vcs.* namespace)
    local has_vcs
    has_vcs=$(jq -r 'has("vcs")' "$config_file" 2>/dev/null)

    if [[ "$has_vcs" == "true" ]]; then
        # Has vcs but no version, probably manual edit
        echo "2.0"
        return "$EXIT_SUCCESS"
    fi

    echo "unknown"
    return "$EXIT_SUCCESS"
}

#######################################
# Check if configuration needs migration
# Arguments:
#   $1 - Path to configuration file
# Returns:
#   0 if migration needed, 1 if already migrated
#######################################
needs_migration() {
    local config_file="$1"
    local version
    version=$(detect_config_version "$config_file")

    case "$version" in
        1.0|unknown)
            return "$EXIT_SUCCESS"
            ;;
        2.0)
            return "$EXIT_VALIDATION_ERROR"
            ;;
        *)
            # Unknown version, assume needs migration
            return "$EXIT_SUCCESS"
            ;;
    esac
}

#######################################
# Migrate GitHub-specific config to generic VCS config
# Arguments:
#   $1 - Path to configuration file
# Outputs:
#   Migration status messages
# Returns:
#   0 on success, 1 on error
#######################################
migrate_github_to_vcs() {
    local config_file="$1"

    if [[ ! -f "$config_file" ]]; then
        print_message "error" "Configuration file does not exist: $config_file"
        return "$EXIT_VALIDATION_ERROR"
    fi

    # Validate JSON before migration
    if ! validate_json_file "$config_file"; then
        print_message "error" "Configuration file is not valid JSON"
        return "$EXIT_VALIDATION_ERROR"
    fi

    print_message "info" "Migrating GitHub config to VCS namespace..."

    # Check if old github.* namespace exists
    local has_github
    has_github=$(jq -r 'has("github")' "$config_file" 2>/dev/null)

    if [[ "$has_github" != "true" ]]; then
        print_message "info" "No github.* namespace found, skipping GitHub migration"
        return "$EXIT_SUCCESS"
    fi

    # Transform github.* → vcs.github.*
    # Set provider to "github"
    # Move all github.* fields under vcs.github.*
    local temp_file="${config_file}.migrate.tmp.$$"

    if ! jq '
        # Extract github namespace
        .github as $github_config |

        # Remove old github namespace
        del(.github) |

        # Create new vcs namespace if it does not exist
        if has("vcs") | not then
            .vcs = {}
        else
            .
        end |

        # Set VCS provider
        .vcs.provider = "github" |

        # Copy github fields to vcs (preserve existing vcs fields if present)
        .vcs.owner = (if $github_config.owner then $github_config.owner elif .vcs.owner then .vcs.owner else null end) |
        .vcs.repo = (if $github_config.repo then $github_config.repo elif .vcs.repo then .vcs.repo else null end) |
        .vcs.main_branch = (if $github_config.main_branch then $github_config.main_branch elif .vcs.main_branch then .vcs.main_branch else "main" end) |
        .vcs.auto_detect = (if ($github_config | has("auto_detect")) then $github_config.auto_detect elif (.vcs | has("auto_detect")) then .vcs.auto_detect else true end) |

        # Move GitHub-specific fields to vcs.github namespace
        if has("vcs.github") | not then
            .vcs.github = {}
        else
            .
        end |
        .vcs.github.enterprise_url = (if $github_config.enterprise_url then $github_config.enterprise_url elif .vcs.github.enterprise_url then .vcs.github.enterprise_url else null end)
    ' "$config_file" > "$temp_file"; then
        print_message "error" "GitHub to VCS transformation failed"
        rm -f "$temp_file"
        return "$EXIT_VALIDATION_ERROR"
    fi

    # Validate transformed config
    if ! validate_json_file "$temp_file"; then
        print_message "error" "Transformed config is not valid JSON"
        rm -f "$temp_file"
        return "$EXIT_VALIDATION_ERROR"
    fi

    # Replace original with transformed config
    if ! mv "$temp_file" "$config_file"; then
        print_message "error" "Failed to write migrated config"
        rm -f "$temp_file"
        return "$EXIT_IO_ERROR"
    fi

    print_message "success" "Migrated github.* → vcs.github.*"
    return "$EXIT_SUCCESS"
}

#######################################
# Migrate workflow reviewers to team namespace
# Arguments:
#   $1 - Path to configuration file
# Outputs:
#   Migration status messages
# Returns:
#   0 on success, 1 on error
#######################################
migrate_reviewers_to_team() {
    local config_file="$1"

    if [[ ! -f "$config_file" ]]; then
        print_message "error" "Configuration file does not exist: $config_file"
        return "$EXIT_VALIDATION_ERROR"
    fi

    print_message "info" "Migrating workflow reviewers to team namespace..."

    # Check if workflow.pull_requests.reviewers exists
    local has_reviewers
    has_reviewers=$(jq -r '.workflow.pull_requests.reviewers != null' "$config_file" 2>/dev/null)

    if [[ "$has_reviewers" != "true" ]]; then
        print_message "info" "No workflow reviewers found, skipping"
        return "$EXIT_SUCCESS"
    fi

    local temp_file="${config_file}.migrate.tmp.$$"

    if ! jq '
        # Extract reviewers
        .workflow.pull_requests.reviewers as $reviewers |

        # Create team namespace if it does not exist
        if has("team") | not then
            .team = {}
        else
            .
        end |

        # Copy reviewers to team.default_reviewers (preserve existing if present)
        .team.default_reviewers = (.team.default_reviewers // $reviewers) |

        # Remove old workflow.pull_requests.reviewers
        del(.workflow.pull_requests.reviewers) |

        # Clean up empty pull_requests object
        if .workflow.pull_requests == {} then
            del(.workflow.pull_requests)
        else
            .
        end |

        # Clean up empty workflow object
        if .workflow == {} then
            del(.workflow)
        else
            .
        end
    ' "$config_file" > "$temp_file"; then
        print_message "error" "Reviewers migration failed"
        rm -f "$temp_file"
        return "$EXIT_VALIDATION_ERROR"
    fi

    # Validate transformed config
    if ! validate_json_file "$temp_file"; then
        print_message "error" "Transformed config is not valid JSON"
        rm -f "$temp_file"
        return "$EXIT_VALIDATION_ERROR"
    fi

    # Replace original with transformed config
    if ! mv "$temp_file" "$config_file"; then
        print_message "error" "Failed to write migrated config"
        rm -f "$temp_file"
        return "$EXIT_IO_ERROR"
    fi

    print_message "success" "Migrated workflow.pull_requests.reviewers → team.default_reviewers"
    return "$EXIT_SUCCESS"
}

#######################################
# Count fields in JSON object recursively
# Arguments:
#   $1 - JSON string or file path
# Outputs:
#   Number of fields
# Returns:
#   0 on success
#######################################
count_json_fields() {
    local input="$1"
    local json_content

    if [[ -f "$input" ]]; then
        json_content=$(cat "$input")
    else
        json_content="$input"
    fi

    # Count all leaf fields recursively
    echo "$json_content" | jq '
        # Recursive function to count all leaf nodes
        def count_leaves:
            if type == "object" then
                [.[] | count_leaves] | add // 0
            elif type == "array" then
                [.[] | count_leaves] | add // 0
            else
                1
            end;
        count_leaves
    '
}

#######################################
# Compare two configs and verify no data loss
# Arguments:
#   $1 - Old config file path
#   $2 - New config file path
# Outputs:
#   Comparison report
# Returns:
#   0 if no data loss detected, 1 otherwise
#######################################
verify_no_data_loss() {
    local old_config="$1"
    local new_config="$2"

    print_message "info" "Verifying data integrity..."

    # Count fields in both configs
    local old_count
    old_count=$(count_json_fields "$old_config")

    local new_count
    new_count=$(count_json_fields "$new_config")

    print_message "info" "Field count: $old_count (old) → $new_count (new)"

    # Allow new config to have MORE fields (config_version added)
    # But warn if significantly fewer fields
    if (( new_count < old_count - 1 )); then
        print_message "warning" "Data loss detected: new config has $((old_count - new_count)) fewer fields"
        return "$EXIT_VALIDATION_ERROR"
    fi

    # Verify all original non-github fields are preserved
    local preserved=true

    # Check for fields that should have been migrated
    local old_github_owner
    old_github_owner=$(jq -r '.github.owner // empty' "$old_config" 2>/dev/null)

    local new_vcs_owner
    new_vcs_owner=$(jq -r '.vcs.owner // empty' "$new_config" 2>/dev/null)

    if [[ -n "$old_github_owner" ]] && [[ -z "$new_vcs_owner" ]]; then
        print_message "error" "Data loss: github.owner not migrated to vcs.owner"
        preserved=false
    fi

    # Check workflow fields are preserved
    local old_reviewers
    old_reviewers=$(jq -r '.workflow.pull_requests.reviewers // empty' "$old_config" 2>/dev/null)

    local new_reviewers
    new_reviewers=$(jq -r '.team.default_reviewers // empty' "$new_config" 2>/dev/null)

    if [[ -n "$old_reviewers" ]] && [[ -z "$new_reviewers" ]]; then
        print_message "error" "Data loss: workflow reviewers not migrated to team.default_reviewers"
        preserved=false
    fi

    if [[ "$preserved" == "false" ]]; then
        return "$EXIT_VALIDATION_ERROR"
    fi

    print_message "success" "Data integrity verified: no data loss detected"
    return "$EXIT_SUCCESS"
}

#######################################
# Generate migration report
# Arguments:
#   $1 - Old config file path
#   $2 - New config file path
#   $3 - Output report file path
# Outputs:
#   Migration report written to file
# Returns:
#   0 on success
#######################################
generate_migration_report() {
    local old_config="$1"
    local new_config="$2"
    local report_file="$3"

    local timestamp
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    cat > "$report_file" << EOF
# AIDA Configuration Migration Report

**Generated**: $timestamp
**Source Version**: $(detect_config_version "$old_config")
**Target Version**: 2.0

## Summary

Configuration successfully migrated from old schema to new schema.

## Transformations Applied

### 1. GitHub Namespace Migration

- **Before**: \`github.*\`
- **After**: \`vcs.github.*\`
- **Status**: ✅ Complete

$(if jq -e '.github' "$old_config" >/dev/null 2>&1; then
    echo "#### Migrated Fields"
    echo ""
    echo '```json'
    jq '.github' "$old_config" 2>/dev/null || echo "{}"
    echo '```'
    echo ""
    echo "→"
    echo ""
    echo '```json'
    jq '.vcs' "$new_config" 2>/dev/null || echo "{}"
    echo '```'
else
    echo "_No GitHub config to migrate_"
fi)

### 2. Workflow Reviewers Migration

- **Before**: \`workflow.pull_requests.reviewers\`
- **After**: \`team.default_reviewers\`
- **Status**: ✅ Complete

$(if jq -e '.workflow.pull_requests.reviewers' "$old_config" >/dev/null 2>&1; then
    echo "#### Migrated Reviewers"
    echo ""
    echo '```json'
    jq '.workflow.pull_requests.reviewers' "$old_config" 2>/dev/null || echo "[]"
    echo '```'
    echo ""
    echo "→"
    echo ""
    echo '```json'
    jq '.team.default_reviewers' "$new_config" 2>/dev/null || echo "[]"
    echo '```'
else
    echo "_No reviewers to migrate_"
fi)

### 3. Version Field Added

- **Field**: \`config_version\`
- **Value**: \`2.0\`
- **Status**: ✅ Complete

## Data Integrity

- **Old config fields**: $(count_json_fields "$old_config")
- **New config fields**: $(count_json_fields "$new_config")
- **Data loss check**: ✅ Passed

## Validation

$(if [[ -f "${SCRIPT_DIR}/config-validator.sh" ]]; then
    if bash "${SCRIPT_DIR}/config-validator.sh" --tier structure "$new_config" >/dev/null 2>&1; then
        echo "- **Schema validation**: ✅ Passed"
    else
        echo "- **Schema validation**: ❌ Failed"
    fi
else
    echo "- **Schema validation**: ⚠️ Skipped (validator not available)"
fi)

## Backup

Original configuration backed up to:
\`$(find "$(dirname "$old_config")" -name "$(basename "$old_config").backup.*" -type f 2>/dev/null | sort -r | head -n1)\`

## Rollback Procedure

If you need to rollback this migration:

\`\`\`bash
# Restore from backup
./lib/installer-common/config-migration.sh restore \\
    "$old_config.backup.TIMESTAMP" \\
    "$old_config"
\`\`\`

---

**Migration completed successfully**
EOF

    print_message "success" "Migration report saved: $report_file"
    return "$EXIT_SUCCESS"
}

#######################################
# Migrate configuration from old schema to new schema
# Arguments:
#   $1 - Path to configuration file
#   $2 - Dry run flag (optional, "true" to simulate migration)
# Outputs:
#   Migration status messages
# Returns:
#   0 on success, 1 on validation error, 2 on I/O error, 3 if migration aborted
#######################################
migrate_config() {
    local config_file="$1"
    local dry_run="${2:-false}"

    if [[ ! -f "$config_file" ]]; then
        print_message "error" "Configuration file does not exist: $config_file"
        return "$EXIT_VALIDATION_ERROR"
    fi

    # Detect version
    local current_version
    current_version=$(detect_config_version "$config_file")

    print_message "info" "Detected config version: $current_version"

    # Check if migration needed
    if ! needs_migration "$config_file"; then
        print_message "success" "Configuration is already migrated (version 2.0)"
        return "$EXIT_SUCCESS"
    fi

    if [[ "$dry_run" == "true" ]]; then
        print_message "info" "[DRY RUN] Would migrate config from version $current_version to 2.0"
        print_message "info" "[DRY RUN] Transformations:"
        print_message "info" "[DRY RUN]   - github.* → vcs.github.*"
        print_message "info" "[DRY RUN]   - workflow.pull_requests.reviewers → team.default_reviewers"
        print_message "info" "[DRY RUN]   - Add config_version: 2.0"
        return "$EXIT_SUCCESS"
    fi

    # Create backup before migration
    print_message "info" "Creating backup before migration..."
    local backup_file
    if ! backup_file=$(backup_config "$config_file"); then
        print_message "error" "Failed to create backup, aborting migration"
        return "$EXIT_OPERATION_ABORTED"
    fi

    print_message "success" "Backup created: $backup_file"

    # Perform migrations
    local migration_failed=false

    # 1. Migrate github.* → vcs.github.*
    if ! migrate_github_to_vcs "$config_file"; then
        migration_failed=true
    fi

    # 2. Migrate workflow.pull_requests.reviewers → team.default_reviewers
    if [[ "$migration_failed" == "false" ]]; then
        if ! migrate_reviewers_to_team "$config_file"; then
            migration_failed=true
        fi
    fi

    # 3. Add config_version field
    if [[ "$migration_failed" == "false" ]]; then
        print_message "info" "Adding config_version field..."
        local temp_file="${config_file}.version.tmp.$$"

        if jq '. + {config_version: "2.0"}' "$config_file" > "$temp_file" && validate_json_file "$temp_file"; then
            mv "$temp_file" "$config_file"
            print_message "success" "Added config_version: 2.0"
        else
            print_message "error" "Failed to add config_version field"
            rm -f "$temp_file"
            migration_failed=true
        fi
    fi

    # Validate migrated config with validation framework
    if [[ "$migration_failed" == "false" ]]; then
        print_message "info" "Validating migrated configuration..."

        # Source validator if available
        if [[ -f "${SCRIPT_DIR}/config-validator.sh" ]]; then
            # Run validation (Tier 1: Structure only)
            if bash "${SCRIPT_DIR}/config-validator.sh" --tier structure "$config_file" >/dev/null 2>&1; then
                print_message "success" "Migrated config passed validation"
            else
                print_message "error" "Migrated config failed validation"
                migration_failed=true
            fi
        else
            print_message "warning" "Validator not available, skipping validation"
        fi
    fi

    # Verify no data loss
    if [[ "$migration_failed" == "false" ]]; then
        if ! verify_no_data_loss "$backup_file" "$config_file"; then
            print_message "error" "Data integrity check failed"
            migration_failed=true
        fi
    fi

    # Handle migration failure - rollback
    if [[ "$migration_failed" == "true" ]]; then
        print_message "error" "Migration failed, rolling back to backup..."

        if restore_config_from_backup "$backup_file" "$config_file"; then
            print_message "success" "Rollback successful"
            print_message "info" "Original config preserved at: $backup_file"
            return "$EXIT_VALIDATION_ERROR"
        else
            print_message "error" "Rollback failed! Original backup at: $backup_file"
            print_message "error" "Manual restore required: cp \"$backup_file\" \"$config_file\""
            return "$EXIT_IO_ERROR"
        fi
    fi

    # Migration successful - generate report
    print_message "success" "Configuration migrated successfully!"
    print_message "info" "Backup preserved at: $backup_file"

    # Generate migration report
    local report_file="${config_file}.migration-report.md"
    generate_migration_report "$backup_file" "$config_file" "$report_file"

    print_message "info" "Migration report: $report_file"

    return "$EXIT_SUCCESS"
}

#######################################
# CLI Usage Information
#######################################
show_usage() {
    cat << EOF
$(color_blue "Configuration Backup and Migration Utilities")

Usage: $(basename "$0") <command> [options]

Commands:
  backup <config-file>
      Create timestamped backup of configuration file

  restore <backup-file> [target-file]
      Restore configuration from backup
      If target-file not provided, derives from backup filename

  list <config-file>
      List all available backups for configuration file

  latest <config-file>
      Get path to most recent backup

  cleanup <config-file> [max-backups]
      Remove old backups, keeping only max-backups most recent
      Default: $MAX_BACKUPS

  migrate <config-file> [--dry-run]
      Migrate configuration from old schema (1.0) to new schema (2.0)
      Creates backup before migration, validates after, rolls back on failure

  detect-version <config-file>
      Detect configuration version (1.0, 2.0, or unknown)

  help
      Show this help message

Examples:
  # Create backup
  $(basename "$0") backup ~/.claude/config.json

  # List backups
  $(basename "$0") list ~/.claude/config.json

  # Restore from specific backup
  $(basename "$0") restore ~/.claude/config.json.backup.20251020-213045

  # Restore from latest backup
  latest=\$($(basename "$0") latest ~/.claude/config.json)
  $(basename "$0") restore "\$latest"

  # Cleanup old backups (keep 5)
  $(basename "$0") cleanup ~/.claude/config.json 5

  # Migrate configuration (dry run)
  $(basename "$0") migrate ~/.claude/config.json --dry-run

  # Migrate configuration (actual)
  $(basename "$0") migrate ~/.claude/config.json

  # Detect config version
  $(basename "$0") detect-version ~/.claude/config.json

Exit Codes:
  0 - Success
  1 - Validation error (invalid JSON, missing file)
  2 - I/O error (disk full, permissions)
  3 - Operation aborted (user cancelled, safety check)

Part of: AIDA Configuration System (Issue #55)
EOF
}

#######################################
# Main CLI Interface
#######################################
main() {
    if [[ $# -eq 0 ]]; then
        show_usage
        return "$EXIT_VALIDATION_ERROR"
    fi

    local command="$1"
    shift

    case "$command" in
        backup)
            if [[ $# -ne 1 ]]; then
                print_message "error" "Usage: backup <config-file>"
                return "$EXIT_VALIDATION_ERROR"
            fi
            backup_config "$1"
            ;;
        restore)
            if [[ $# -lt 1 ]] || [[ $# -gt 2 ]]; then
                print_message "error" "Usage: restore <backup-file> [target-file]"
                return "$EXIT_VALIDATION_ERROR"
            fi
            restore_config_from_backup "$@"
            ;;
        list)
            if [[ $# -ne 1 ]]; then
                print_message "error" "Usage: list <config-file>"
                return "$EXIT_VALIDATION_ERROR"
            fi
            list_backups "$1"
            ;;
        latest)
            if [[ $# -ne 1 ]]; then
                print_message "error" "Usage: latest <config-file>"
                return "$EXIT_VALIDATION_ERROR"
            fi
            get_latest_backup "$1"
            ;;
        cleanup)
            if [[ $# -lt 1 ]] || [[ $# -gt 2 ]]; then
                print_message "error" "Usage: cleanup <config-file> [max-backups]"
                return "$EXIT_VALIDATION_ERROR"
            fi
            cleanup_old_backups "$@"
            ;;
        help|--help|-h)
            show_usage
            return "$EXIT_SUCCESS"
            ;;
        migrate)
            if [[ $# -lt 1 ]] || [[ $# -gt 2 ]]; then
                print_message "error" "Usage: migrate <config-file> [--dry-run]"
                return "$EXIT_VALIDATION_ERROR"
            fi
            local config_file="$1"
            local dry_run="false"
            if [[ $# -eq 2 ]] && [[ "$2" == "--dry-run" ]]; then
                dry_run="true"
            fi
            migrate_config "$config_file" "$dry_run"
            ;;
        detect-version)
            if [[ $# -ne 1 ]]; then
                print_message "error" "Usage: detect-version <config-file>"
                return "$EXIT_VALIDATION_ERROR"
            fi
            detect_config_version "$1"
            ;;
        *)
            print_message "error" "Unknown command: $command"
            show_usage
            return "$EXIT_VALIDATION_ERROR"
            ;;
    esac
}

# Only run main if executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
