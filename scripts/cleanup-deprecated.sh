#!/usr/bin/env bash
#
# cleanup-deprecated.sh - Remove Deprecated Templates Based on Version
#
# Description:
#   Automated cleanup script that removes deprecated templates when version thresholds
#   are exceeded. Uses lib/installer-common/deprecation.sh module for all deprecation
#   logic and version comparison.
#
#   Features:
#   - Scans templates/ directories for deprecated items
#   - Removes templates where current_version >= remove_in
#   - Dry-run mode to preview changes
#   - Backup creation before deletion
#   - Confirmation prompts for safety
#   - Detailed logging of all actions
#
# Usage:
#   ./scripts/cleanup-deprecated.sh [OPTIONS]
#
# Options:
#   --dry-run           Show what would be removed without removing (default mode)
#   --execute           Actually remove deprecated templates (requires confirmation)
#   --verbose           Show detailed version comparison logic
#   --force             Skip confirmation prompts (dangerous! use with caution)
#   --backup-dir DIR    Specify custom backup directory (default: .deprecated-backup/<timestamp>)
#   --no-backup         Don't create backups before deletion (very dangerous!)
#   --help              Show this help message
#
# Examples:
#   # Preview what would be removed (safe)
#   ./scripts/cleanup-deprecated.sh --dry-run
#
#   # Remove deprecated templates with confirmation
#   ./scripts/cleanup-deprecated.sh --execute
#
#   # Remove without confirmation (automation/CI)
#   ./scripts/cleanup-deprecated.sh --execute --force
#
#   # Verbose dry-run to see decision logic
#   ./scripts/cleanup-deprecated.sh --dry-run --verbose
#
# Exit Codes:
#   0 - Success (templates removed or dry-run completed)
#   1 - Error (invalid arguments, missing dependencies, cleanup failed)
#   2 - User cancelled operation
#
# Part of: AIDA installer-common library v1.0
# Author: oakensoul
# License: AGPL-3.0
# Repository: https://github.com/oakensoul/claude-personal-assistant
#

set -euo pipefail

#######################################
# Script Configuration
#######################################

# Determine script directory (absolute path)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# Determine project root (parent of scripts/)
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly PROJECT_ROOT

# Template directories to scan
readonly TEMPLATE_DIRS=(
  "templates/commands"
  "templates/agents"
  "templates/skills"
)

# Version file location
readonly VERSION_FILE="${PROJECT_ROOT}/VERSION"

# Default backup directory (timestamped)
DEFAULT_BACKUP_DIR="${PROJECT_ROOT}/.deprecated-backup/$(date +%Y-%m-%d-%H%M%S)"

#######################################
# Load Dependencies
#######################################

# Load installer-common library modules
readonly INSTALLER_COMMON="${PROJECT_ROOT}/lib/installer-common"

# Check if library exists
if [[ ! -d "$INSTALLER_COMMON" ]]; then
  echo "Error: installer-common library not found at: ${INSTALLER_COMMON}" >&2
  exit 1
fi

# Source required modules in dependency order
source "${INSTALLER_COMMON}/colors.sh"
source "${INSTALLER_COMMON}/logging.sh"
source "${INSTALLER_COMMON}/validation.sh"
source "${INSTALLER_COMMON}/deprecation.sh"
source "${INSTALLER_COMMON}/prompts.sh"

#######################################
# Global Variables
#######################################

# Command-line flags (defaults)
DRY_RUN=true           # Default to dry-run for safety
VERBOSE=false
FORCE=false
CREATE_BACKUP=true
BACKUP_DIR="${DEFAULT_BACKUP_DIR}"

# Counters for summary
TOTAL_SCANNED=0
TOTAL_DEPRECATED=0
TOTAL_REMOVED=0
TOTAL_KEPT=0
TOTAL_ERRORS=0

# Arrays to track results
REMOVED_TEMPLATES=()
KEPT_TEMPLATES=()
ERROR_TEMPLATES=()

#######################################
# Helper Functions
#######################################

#######################################
# Display usage information
#######################################
show_usage() {
  cat << 'EOF'
Usage: ./scripts/cleanup-deprecated.sh [OPTIONS]

Remove deprecated templates based on version thresholds.

OPTIONS:
  --dry-run           Show what would be removed without removing (default mode)
  --execute           Actually remove deprecated templates (requires confirmation)
  --verbose           Show detailed version comparison logic
  --force             Skip confirmation prompts (dangerous!)
  --backup-dir DIR    Specify custom backup directory
  --no-backup         Don't create backups (very dangerous!)
  --help              Show this help message

EXAMPLES:
  # Preview what would be removed (safe)
  ./scripts/cleanup-deprecated.sh --dry-run

  # Remove deprecated templates with confirmation
  ./scripts/cleanup-deprecated.sh --execute

  # Automated cleanup (CI/CD)
  ./scripts/cleanup-deprecated.sh --execute --force

  # Verbose dry-run
  ./scripts/cleanup-deprecated.sh --dry-run --verbose

EXIT CODES:
  0 - Success
  1 - Error (invalid arguments, cleanup failed)
  2 - User cancelled operation

For more information, see: docs/architecture/deprecation-system.md
EOF
}

#######################################
# Parse command-line arguments
#######################################
parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run)
        DRY_RUN=true
        shift
        ;;
      --execute)
        DRY_RUN=false
        shift
        ;;
      --verbose)
        VERBOSE=true
        shift
        ;;
      --force)
        FORCE=true
        shift
        ;;
      --no-backup)
        CREATE_BACKUP=false
        shift
        ;;
      --backup-dir)
        if [[ -z "${2:-}" ]]; then
          print_message "error" "--backup-dir requires a directory argument"
          exit 1
        fi
        BACKUP_DIR="$2"
        shift 2
        ;;
      --help|-h)
        show_usage
        exit 0
        ;;
      *)
        print_message "error" "Unknown option: $1"
        echo ""
        show_usage
        exit 1
        ;;
    esac
  done
}

#######################################
# Validate prerequisites
#######################################
validate_prerequisites() {
  local errors=0

  # Check VERSION file exists and is valid
  if [[ ! -f "$VERSION_FILE" ]]; then
    print_message "error" "VERSION file not found: ${VERSION_FILE}"
    errors=$((errors + 1))
  fi

  # Check template directories exist
  for template_dir in "${TEMPLATE_DIRS[@]}"; do
    local full_path="${PROJECT_ROOT}/${template_dir}"
    if [[ ! -d "$full_path" ]]; then
      print_message "warning" "Template directory not found: ${template_dir}"
    fi
  done

  # Check required commands
  local required_commands=("find" "rm" "mkdir" "cp")
  for cmd in "${required_commands[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      print_message "error" "Required command not found: ${cmd}"
      errors=$((errors + 1))
    fi
  done

  if [[ $errors -gt 0 ]]; then
    print_message "error" "Prerequisites validation failed (${errors} error(s))"
    return 1
  fi

  return 0
}

#######################################
# Get current version from VERSION file
#######################################
get_current_version() {
  local version

  if ! version=$(validate_version_file "$VERSION_FILE" 2>/dev/null); then
    print_message "error" "Failed to read version from VERSION file"
    return 1
  fi

  echo "$version"
  return 0
}

#######################################
# Create backup of template before removal
#
# Arguments:
#   $1 - Template directory path to backup
#
# Returns:
#   0 on success, 1 on failure
#######################################
backup_template() {
  local template_path="$1"
  local template_name
  template_name=$(basename "$template_path")

  # Determine relative path from PROJECT_ROOT
  local relative_path="${template_path#"${PROJECT_ROOT}"/}"

  # Create backup directory structure
  local backup_path="${BACKUP_DIR}/${relative_path}"
  local backup_parent
  backup_parent=$(dirname "$backup_path")

  if [[ "$VERBOSE" == "true" ]]; then
    print_message "info" "Creating backup: ${relative_path} -> ${backup_path}"
  fi

  # Create parent directory
  if ! mkdir -p "$backup_parent"; then
    print_message "error" "Failed to create backup directory: ${backup_parent}"
    return 1
  fi

  # Copy template to backup location
  if ! cp -a "$template_path" "$backup_path"; then
    print_message "error" "Failed to backup template: ${template_name}"
    return 1
  fi

  return 0
}

#######################################
# Remove deprecated template directory
#
# Arguments:
#   $1 - Template directory path to remove
#
# Returns:
#   0 on success, 1 on failure
#######################################
remove_template() {
  local template_path="$1"
  local template_name
  template_name=$(basename "$template_path")

  # Create backup if enabled
  if [[ "$CREATE_BACKUP" == "true" ]]; then
    if ! backup_template "$template_path"; then
      print_message "error" "Backup failed, skipping removal: ${template_name}"
      return 1
    fi
  fi

  # Remove template directory
  if [[ "$DRY_RUN" == "false" ]]; then
    if ! rm -rf "$template_path"; then
      print_message "error" "Failed to remove template: ${template_name}"
      return 1
    fi
  fi

  return 0
}

#######################################
# Process a single template for deprecation
#
# Arguments:
#   $1 - Template README.md file path
#   $2 - Current system version
#
# Returns:
#   0 on success (template processed)
#   1 on error (skip and continue)
#######################################
process_template() {
  local template_file="$1"
  local current_version="$2"
  local template_dir
  template_dir=$(dirname "$template_file")
  local template_name
  template_name=$(basename "$template_dir")

  # Increment scanned counter
  TOTAL_SCANNED=$((TOTAL_SCANNED + 1))

  # Check if template is deprecated
  if ! is_deprecated "$template_file" 2>/dev/null; then
    # Not deprecated - skip
    if [[ "$VERBOSE" == "true" ]]; then
      print_message "info" "  ${template_name}: Not deprecated, skipping"
    fi
    return 0
  fi

  # Increment deprecated counter
  TOTAL_DEPRECATED=$((TOTAL_DEPRECATED + 1))

  # Parse deprecation metadata
  local metadata
  if ! metadata=$(parse_deprecation_metadata "$template_file" 2>/dev/null); then
    print_message "warning" "Failed to parse deprecation metadata: ${template_name}"
    ERROR_TEMPLATES+=("${template_name}")
    TOTAL_ERRORS=$((TOTAL_ERRORS + 1))
    return 1
  fi

  # Extract deprecation fields
  local deprecated_in remove_in canonical reason
  deprecated_in=$(echo "$metadata" | grep "^deprecated_in=" | cut -d= -f2 || echo "")
  remove_in=$(echo "$metadata" | grep "^remove_in=" | cut -d= -f2 || echo "")
  canonical=$(echo "$metadata" | grep "^canonical=" | cut -d= -f2 || echo "")
  reason=$(echo "$metadata" | grep "^reason=" | cut -d= -f2 || echo "")

  # Check if remove_in is specified
  if [[ -z "$remove_in" ]]; then
    if [[ "$VERBOSE" == "true" ]]; then
      print_message "info" "  ${template_name}: No remove_in specified, keeping perpetually"
    fi
    KEPT_TEMPLATES+=("${template_name} (no removal version)")
    TOTAL_KEPT=$((TOTAL_KEPT + 1))
    return 0
  fi

  # Determine if should remove
  if should_remove_deprecated "$current_version" "$remove_in" 2>/dev/null; then
    # Should remove - version threshold exceeded
    if [[ "$DRY_RUN" == "true" ]]; then
      print_message "warning" "  ${template_name}: Would remove (deprecated: ${deprecated_in}, remove: ${remove_in})"
      if [[ -n "$canonical" ]]; then
        print_message "info" "    → Canonical replacement: ${canonical}"
      fi
      if [[ -n "$reason" ]]; then
        print_message "info" "    → Reason: ${reason}"
      fi
    else
      print_message "warning" "  ${template_name}: Removing (deprecated: ${deprecated_in}, remove: ${remove_in})"
      if remove_template "$template_dir"; then
        print_message "success" "    → Removed successfully"
        if [[ -n "$canonical" ]]; then
          print_message "info" "    → Canonical replacement: ${canonical}"
        fi
      else
        print_message "error" "    → Removal failed"
        ERROR_TEMPLATES+=("${template_name}")
        TOTAL_ERRORS=$((TOTAL_ERRORS + 1))
        return 1
      fi
    fi

    REMOVED_TEMPLATES+=("${template_name}")
    TOTAL_REMOVED=$((TOTAL_REMOVED + 1))
  else
    # Keep - still in grace period
    if [[ "$VERBOSE" == "true" ]]; then
      print_message "info" "  ${template_name}: Keep (deprecated: ${deprecated_in}, remove: ${remove_in})"
      print_message "info" "    → Grace period until v${remove_in}"
    fi
    KEPT_TEMPLATES+=("${template_name} (grace period until ${remove_in})")
    TOTAL_KEPT=$((TOTAL_KEPT + 1))
  fi

  return 0
}

#######################################
# Scan template directory for deprecated items
#
# Arguments:
#   $1 - Template directory to scan (relative to PROJECT_ROOT)
#   $2 - Current system version
#
# Returns:
#   0 on success (all templates processed)
#######################################
scan_template_directory() {
  local template_dir="$1"
  local current_version="$2"
  local full_path="${PROJECT_ROOT}/${template_dir}"

  # Check if directory exists
  if [[ ! -d "$full_path" ]]; then
    if [[ "$VERBOSE" == "true" ]]; then
      print_message "warning" "Skipping non-existent directory: ${template_dir}"
    fi
    return 0
  fi

  print_message "info" "Scanning: ${template_dir}/"

  # Find all README.md files in subdirectories (template definitions)
  local template_count=0
  while IFS= read -r readme_file; do
    process_template "$readme_file" "$current_version"
    template_count=$((template_count + 1))
  done < <(find "$full_path" -mindepth 2 -maxdepth 2 -name "README.md" -type f)

  if [[ $template_count -eq 0 ]]; then
    if [[ "$VERBOSE" == "true" ]]; then
      print_message "info" "  No templates found in ${template_dir}/"
    fi
  fi

  return 0
}

#######################################
# Display summary of cleanup operation
#######################################
display_summary() {
  echo ""
  echo "========================================"
  echo "Cleanup Summary"
  echo "========================================"
  echo ""

  print_message "info" "Templates scanned: ${TOTAL_SCANNED}"
  print_message "info" "Deprecated templates found: ${TOTAL_DEPRECATED}"

  echo ""

  if [[ "$DRY_RUN" == "true" ]]; then
    print_message "warning" "Would remove: ${TOTAL_REMOVED} template(s)"
  else
    if [[ $TOTAL_REMOVED -gt 0 ]]; then
      print_message "success" "Removed: ${TOTAL_REMOVED} template(s)"
    else
      print_message "info" "Removed: ${TOTAL_REMOVED} template(s)"
    fi
  fi

  print_message "info" "Kept: ${TOTAL_KEPT} template(s)"

  if [[ $TOTAL_ERRORS -gt 0 ]]; then
    print_message "error" "Errors: ${TOTAL_ERRORS} template(s)"
  fi

  # Show details if verbose or if there were removals
  if [[ "$VERBOSE" == "true" || ${TOTAL_REMOVED} -gt 0 ]]; then
    echo ""

    if [[ ${#REMOVED_TEMPLATES[@]} -gt 0 ]]; then
      if [[ "$DRY_RUN" == "true" ]]; then
        echo "Templates that would be removed:"
      else
        echo "Removed templates:"
      fi
      for template in "${REMOVED_TEMPLATES[@]}"; do
        echo "  - ${template}"
      done
      echo ""
    fi

    if [[ "$VERBOSE" == "true" && ${#KEPT_TEMPLATES[@]} -gt 0 ]]; then
      echo "Templates kept (grace period):"
      for template in "${KEPT_TEMPLATES[@]}"; do
        echo "  - ${template}"
      done
      echo ""
    fi

    if [[ ${#ERROR_TEMPLATES[@]} -gt 0 ]]; then
      echo "Templates with errors:"
      for template in "${ERROR_TEMPLATES[@]}"; do
        echo "  - ${template}"
      done
      echo ""
    fi
  fi

  # Show backup location if backups were created
  if [[ "$CREATE_BACKUP" == "true" && "$DRY_RUN" == "false" && ${TOTAL_REMOVED} -gt 0 ]]; then
    print_message "info" "Backups saved to: ${BACKUP_DIR}"
  fi

  echo ""
}

#######################################
# Main cleanup workflow
#######################################
cleanup_deprecated_templates() {
  # Get current version from VERSION file
  local current_version
  if ! current_version=$(get_current_version); then
    print_message "error" "Failed to get current version"
    return 1
  fi

  # Display operation mode
  echo ""
  echo "========================================"
  echo "Deprecated Template Cleanup"
  echo "========================================"
  echo ""
  print_message "info" "Current version: ${current_version}"
  print_message "info" "Mode: $(if [[ "$DRY_RUN" == "true" ]]; then echo "DRY-RUN (no changes)"; else echo "EXECUTE (will remove templates)"; fi)"

  if [[ "$CREATE_BACKUP" == "false" && "$DRY_RUN" == "false" ]]; then
    print_message "warning" "Backups disabled! Templates will be permanently deleted"
  fi

  echo ""

  # Scan all template directories
  for template_dir in "${TEMPLATE_DIRS[@]}"; do
    scan_template_directory "$template_dir" "$current_version"
  done

  # Display summary
  display_summary

  # Return status based on errors
  if [[ $TOTAL_ERRORS -gt 0 ]]; then
    return 1
  fi

  return 0
}

#######################################
# Main Script Entry Point
#######################################
main() {
  # Parse command-line arguments
  parse_arguments "$@"

  # Validate prerequisites
  if ! validate_prerequisites; then
    exit 1
  fi

  # Safety check: require confirmation for --execute mode
  if [[ "$DRY_RUN" == "false" && "$FORCE" == "false" ]]; then
    echo ""
    if ! confirm_action \
      "Remove deprecated templates (version threshold exceeded)" \
      "This will permanently delete template directories. Backups will be created unless --no-backup is used."; then
      print_message "info" "Operation cancelled by user"
      exit 2
    fi
    echo ""
  fi

  # Run cleanup
  if cleanup_deprecated_templates; then
    if [[ "$DRY_RUN" == "true" ]]; then
      print_message "success" "Dry-run completed successfully"
      echo ""
      print_message "info" "To actually remove templates, run with --execute"
    else
      print_message "success" "Cleanup completed successfully"
    fi
    exit 0
  else
    print_message "error" "Cleanup failed with errors"
    exit 1
  fi
}

# Run main function
main "$@"
