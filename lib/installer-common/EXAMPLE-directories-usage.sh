#!/usr/bin/env bash
#
# EXAMPLE-directories-usage.sh - Usage Examples for directories.sh Module
#
# Description:
#   Demonstrates common usage patterns for the directories.sh module.
#   Shows basic installation, upgrade flows, and namespace isolation.
#
# Usage:
#   This is a reference file - DO NOT RUN directly
#   Copy relevant sections to your installer script
#
# Author: oakensoul
# License: AGPL-3.0
# Repository: https://github.com/oakensoul/claude-personal-assistant
#

set -euo pipefail

# Script directory (repository root)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# Source shared utilities from installer-common library
readonly INSTALLER_COMMON="${SCRIPT_DIR}/lib/installer-common"

# Source dependencies
source "${INSTALLER_COMMON}/colors.sh"
source "${INSTALLER_COMMON}/logging.sh"
source "${INSTALLER_COMMON}/validation.sh"
source "${INSTALLER_COMMON}/directories.sh"

# Installation directories
readonly REPO_DIR="${SCRIPT_DIR}"
readonly AIDA_DIR="${HOME}/.aida"
readonly CLAUDE_DIR="${HOME}/.claude"

################################################################################
# EXAMPLE 1: Basic Fresh Installation
################################################################################
example_fresh_install() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  EXAMPLE 1: Fresh Installation"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    print_message "info" "Starting fresh AIDA installation..."
    echo ""

    # Step 1: Create AIDA directory (always symlink)
    print_message "info" "Step 1: Creating AIDA directory"
    create_aida_dir "$REPO_DIR" "$AIDA_DIR" || {
        print_message "error" "Failed to create AIDA directory"
        return 1
    }
    echo ""

    # Step 2: Create Claude configuration structure
    print_message "info" "Step 2: Creating Claude configuration directories"
    create_claude_dirs "$CLAUDE_DIR" || {
        print_message "error" "Failed to create Claude directories"
        return 1
    }
    echo ""

    # Step 3: Create framework namespace
    print_message "info" "Step 3: Creating framework namespace (.aida/)"
    create_namespace_dirs "$CLAUDE_DIR" ".aida" || {
        print_message "error" "Failed to create framework namespace"
        return 1
    }
    echo ""

    print_message "success" "Fresh installation complete!"
    echo ""
    echo "Directory structure created:"
    echo "  ~/.aida/              -> ${REPO_DIR}"
    echo "  ~/.claude/commands/   (ready for user content)"
    echo "  ~/.claude/commands/.aida/   (framework templates)"
    echo "  ~/.claude/agents/     (ready for user content)"
    echo "  ~/.claude/agents/.aida/     (framework agents)"
    echo "  ~/.claude/skills/     (ready for user content)"
    echo "  ~/.claude/skills/.aida/     (framework skills)"
    echo ""
}

################################################################################
# EXAMPLE 2: Installation with Deprecated Templates
################################################################################
example_install_with_deprecated() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  EXAMPLE 2: Installation with Deprecated Templates"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    print_message "info" "Installing AIDA with deprecated templates..."
    echo ""

    # Create main structure
    create_aida_dir "$REPO_DIR" "$AIDA_DIR"
    create_claude_dirs "$CLAUDE_DIR"

    # Create both framework and deprecated namespaces
    print_message "info" "Creating framework namespace"
    create_namespace_dirs "$CLAUDE_DIR" ".aida"
    echo ""

    print_message "info" "Creating deprecated namespace"
    create_namespace_dirs "$CLAUDE_DIR" ".aida-deprecated"
    echo ""

    print_message "success" "Installation complete with deprecated templates"
    echo ""
    echo "Users can now:"
    echo "  - Use current commands in .aida/"
    echo "  - Reference old commands in .aida-deprecated/"
    echo "  - Remove deprecated when ready: rm -rf ~/.claude/commands/.aida-deprecated/"
    echo ""
}

################################################################################
# EXAMPLE 3: Safe Upgrade (Preserving User Content)
################################################################################
example_safe_upgrade() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  EXAMPLE 3: Safe Upgrade (Preserving User Content)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    print_message "info" "Upgrading AIDA framework..."
    echo ""

    # Show existing user content
    print_message "info" "User content before upgrade:"
    if [[ -f "${CLAUDE_DIR}/commands/my-workflow.md" ]]; then
        echo "  ✓ ~/.claude/commands/my-workflow.md exists"
    fi
    echo ""

    # Update AIDA directory (idempotent - safe if already correct)
    print_message "info" "Updating AIDA directory symlink"
    create_aida_dir "$REPO_DIR" "$AIDA_DIR"
    echo ""

    # Recreate framework namespace (user content untouched!)
    print_message "info" "Recreating framework namespace"
    print_message "warning" "Removing old framework templates..."
    if [[ -d "${CLAUDE_DIR}/commands/.aida" ]]; then
        rm -rf "${CLAUDE_DIR}/commands/.aida"
    fi
    if [[ -d "${CLAUDE_DIR}/agents/.aida" ]]; then
        rm -rf "${CLAUDE_DIR}/agents/.aida"
    fi
    if [[ -d "${CLAUDE_DIR}/skills/.aida" ]]; then
        rm -rf "${CLAUDE_DIR}/skills/.aida"
    fi

    create_namespace_dirs "$CLAUDE_DIR" ".aida"
    echo ""

    # Verify user content preserved
    print_message "success" "Upgrade complete - verifying user content..."
    if [[ -f "${CLAUDE_DIR}/commands/my-workflow.md" ]]; then
        print_message "success" "User content preserved: my-workflow.md still exists"
    fi
    echo ""

    echo "Framework updated, user content safe!"
    echo ""
}

################################################################################
# EXAMPLE 4: Backup Before Destructive Operation
################################################################################
example_backup_before_destructive() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  EXAMPLE 4: Backup Before Destructive Operation"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    print_message "info" "Performing operation with backup safety..."
    echo ""

    local config_file="${CLAUDE_DIR}/config/assistant.yaml"

    # Check if file exists
    if [[ -f "$config_file" ]]; then
        # Backup before modifying
        print_message "info" "Creating backup before modification"
        backup_existing "$config_file"
        echo ""

        # Now safe to modify
        print_message "info" "Modifying configuration (backup created)"
        echo "# Modified" >> "$config_file"
        echo ""

        print_message "success" "Operation complete, backup available if needed"
    else
        print_message "info" "No existing config, creating new one"
    fi
    echo ""
}

################################################################################
# EXAMPLE 5: Idempotent Directory Creation
################################################################################
example_idempotent_creation() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  EXAMPLE 5: Idempotent Directory Creation"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    print_message "info" "Demonstrating idempotent operations..."
    echo ""

    # First call - creates directories
    print_message "info" "First call: Creating directories"
    create_claude_dirs "$CLAUDE_DIR"
    echo ""

    # Second call - does nothing (idempotent)
    print_message "info" "Second call: Safe to repeat"
    create_claude_dirs "$CLAUDE_DIR"
    echo ""

    # Third call - still safe
    print_message "info" "Third call: Still safe"
    create_claude_dirs "$CLAUDE_DIR"
    echo ""

    print_message "success" "All calls succeeded - idempotent behavior verified"
    echo ""
}

################################################################################
# EXAMPLE 6: Symlink Validation and Correction
################################################################################
example_symlink_validation() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  EXAMPLE 6: Symlink Validation and Correction"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    print_message "info" "Validating AIDA directory symlink..."
    echo ""

    # Check if symlink exists and is correct
    if [[ -L "$AIDA_DIR" ]]; then
        print_message "info" "AIDA directory is a symlink, validating target..."

        if validate_symlink "$AIDA_DIR" "$REPO_DIR"; then
            print_message "success" "Symlink is correct"
            local target
            target=$(get_symlink_target "$AIDA_DIR")
            echo "  Points to: $target"
        else
            print_message "warning" "Symlink points to wrong target"
            print_message "info" "Recreating symlink..."

            # Backup old symlink
            backup_existing "$AIDA_DIR"

            # Remove incorrect symlink
            rm "$AIDA_DIR"

            # Create correct symlink
            create_symlink "$REPO_DIR" "$AIDA_DIR"

            print_message "success" "Symlink corrected"
        fi
    else
        print_message "warning" "AIDA directory is not a symlink"
        print_message "info" "Creating symlink..."
        create_aida_dir "$REPO_DIR" "$AIDA_DIR"
    fi
    echo ""
}

################################################################################
# EXAMPLE 7: Migration from Flat to Namespace Structure
################################################################################
example_migrate_to_namespace() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  EXAMPLE 7: Migration from Flat to Namespace Structure"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    print_message "info" "Migrating from v0.1.x flat structure to v0.2.0 namespace isolation..."
    echo ""

    # Detect if migration needed
    local needs_migration=false
    local framework_commands=("start-work" "implement" "open-pr" "cleanup-main")

    for cmd in "${framework_commands[@]}"; do
        if [[ -d "${CLAUDE_DIR}/commands/${cmd}" ]] && [[ ! -d "${CLAUDE_DIR}/commands/.aida" ]]; then
            needs_migration=true
            break
        fi
    done

    if [[ "$needs_migration" == false ]]; then
        print_message "info" "No migration needed - already using namespace isolation"
        echo ""
        return 0
    fi

    print_message "warning" "Detected flat structure - migrating to namespace isolation"
    echo ""

    # Create namespace directory
    print_message "info" "Creating .aida namespace"
    create_namespace_dirs "$CLAUDE_DIR" ".aida"
    echo ""

    # Migrate framework templates
    print_message "info" "Migrating framework templates to .aida/"
    for cmd in "${framework_commands[@]}"; do
        local old_path="${CLAUDE_DIR}/commands/${cmd}"
        local new_path="${CLAUDE_DIR}/commands/.aida/${cmd}"

        if [[ -d "$old_path" ]]; then
            print_message "info" "  Moving ${cmd}/ to .aida/${cmd}/"
            mv "$old_path" "$new_path"
        fi
    done
    echo ""

    print_message "success" "Migration complete!"
    echo ""
    echo "Framework templates moved to .aida/"
    echo "User content preserved in parent directory"
    echo ""
}

################################################################################
# EXAMPLE 8: Complete Installation Flow with Error Handling
################################################################################
example_complete_install_with_errors() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  EXAMPLE 8: Complete Installation with Error Handling"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    print_message "info" "Starting complete installation with error handling..."
    echo ""

    # Step 1: Validate repository
    if [[ ! -d "$REPO_DIR" ]]; then
        print_message "error" "Repository directory does not exist: ${REPO_DIR}"
        return 1
    fi
    print_message "success" "Repository validated"
    echo ""

    # Step 2: Check for existing installation
    if [[ -e "$AIDA_DIR" ]] || [[ -e "$CLAUDE_DIR" ]]; then
        print_message "warning" "Existing installation detected"

        # Backup existing installation
        if [[ -e "$AIDA_DIR" ]]; then
            print_message "info" "Backing up existing AIDA directory"
            backup_existing "$AIDA_DIR" || {
                print_message "error" "Failed to backup AIDA directory"
                return 1
            }
            rm -rf "$AIDA_DIR"
        fi

        if [[ -e "$CLAUDE_DIR" ]]; then
            print_message "info" "Backing up existing Claude directory"
            backup_existing "$CLAUDE_DIR" || {
                print_message "error" "Failed to backup Claude directory"
                return 1
            }
            rm -rf "$CLAUDE_DIR"
        fi
        echo ""
    fi

    # Step 3: Create AIDA directory
    print_message "info" "Creating AIDA directory"
    create_aida_dir "$REPO_DIR" "$AIDA_DIR" || {
        print_message "error" "Failed to create AIDA directory"
        return 1
    }
    echo ""

    # Step 4: Create Claude structure
    print_message "info" "Creating Claude configuration structure"
    create_claude_dirs "$CLAUDE_DIR" || {
        print_message "error" "Failed to create Claude directories"
        return 1
    }
    echo ""

    # Step 5: Create framework namespace
    print_message "info" "Creating framework namespace"
    create_namespace_dirs "$CLAUDE_DIR" ".aida" || {
        print_message "error" "Failed to create framework namespace"
        return 1
    }
    echo ""

    # Step 6: Validate installation
    print_message "info" "Validating installation"

    local validation_errors=0

    # Validate AIDA symlink
    if ! validate_symlink "$AIDA_DIR" "$REPO_DIR" 2>/dev/null; then
        print_message "error" "AIDA directory validation failed"
        validation_errors=$((validation_errors + 1))
    fi

    # Validate Claude directories
    local required_dirs=(
        "$CLAUDE_DIR/commands"
        "$CLAUDE_DIR/agents"
        "$CLAUDE_DIR/skills"
        "$CLAUDE_DIR/commands/.aida"
        "$CLAUDE_DIR/agents/.aida"
        "$CLAUDE_DIR/skills/.aida"
    )

    for dir in "${required_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            print_message "error" "Missing directory: ${dir}"
            validation_errors=$((validation_errors + 1))
        fi
    done

    if [[ $validation_errors -eq 0 ]]; then
        print_message "success" "Installation validation passed"
        echo ""
        print_message "success" "AIDA installation complete!"
    else
        print_message "error" "Installation validation failed with ${validation_errors} errors"
        return 1
    fi
    echo ""
}

################################################################################
# Main Menu
################################################################################
main() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  directories.sh Module - Usage Examples"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Available examples:"
    echo ""
    echo "  1) Fresh installation"
    echo "  2) Installation with deprecated templates"
    echo "  3) Safe upgrade (preserving user content)"
    echo "  4) Backup before destructive operation"
    echo "  5) Idempotent directory creation"
    echo "  6) Symlink validation and correction"
    echo "  7) Migration from flat to namespace structure"
    echo "  8) Complete installation with error handling"
    echo "  9) Run all examples"
    echo "  0) Exit"
    echo ""

    read -rp "Select example [0-9]: " choice

    case "$choice" in
        1) example_fresh_install ;;
        2) example_install_with_deprecated ;;
        3) example_safe_upgrade ;;
        4) example_backup_before_destructive ;;
        5) example_idempotent_creation ;;
        6) example_symlink_validation ;;
        7) example_migrate_to_namespace ;;
        8) example_complete_install_with_errors ;;
        9)
            example_fresh_install
            example_install_with_deprecated
            example_safe_upgrade
            example_backup_before_destructive
            example_idempotent_creation
            example_symlink_validation
            example_migrate_to_namespace
            example_complete_install_with_errors
            ;;
        0)
            echo "Exiting..."
            exit 0
            ;;
        *)
            print_message "error" "Invalid choice: ${choice}"
            exit 1
            ;;
    esac
}

# Only run main if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
