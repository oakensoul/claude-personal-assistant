#!/usr/bin/env bash
#
# install.sh - AIDA Framework Installation Script (Orchestrator)
#
# Description:
#   Thin orchestration layer for AIDA framework installation.
#   Sources modular components from lib/installer-common/ and coordinates installation flow.
#   All business logic has been extracted to reusable modules.
#
# Usage:
#   ./install.sh           # Normal installation
#   ./install.sh --dev     # Development mode (uses symlinks)
#   ./install.sh --help    # Show help
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

# Core utilities (order matters - colors and logging first)
# shellcheck source=lib/installer-common/colors.sh
source "${INSTALLER_COMMON}/colors.sh" || {
    echo "Error: Failed to source colors.sh from ${INSTALLER_COMMON}"
    exit 1
}

# shellcheck source=lib/installer-common/logging.sh
source "${INSTALLER_COMMON}/logging.sh" || {
    echo "Error: Failed to source logging.sh from ${INSTALLER_COMMON}"
    exit 1
}

# shellcheck source=lib/installer-common/validation.sh
source "${INSTALLER_COMMON}/validation.sh" || {
    print_message "error" "Failed to source validation.sh from ${INSTALLER_COMMON}"
    exit 1
}

# Installer modules (extracted business logic)
# shellcheck source=lib/installer-common/prompts.sh
source "${INSTALLER_COMMON}/prompts.sh" || {
    print_message "error" "Failed to source prompts.sh from ${INSTALLER_COMMON}"
    exit 1
}

# shellcheck source=lib/installer-common/directories.sh
source "${INSTALLER_COMMON}/directories.sh" || {
    print_message "error" "Failed to source directories.sh from ${INSTALLER_COMMON}"
    exit 1
}

# shellcheck source=lib/installer-common/config.sh
source "${INSTALLER_COMMON}/config.sh" || {
    print_message "error" "Failed to source config.sh from ${INSTALLER_COMMON}"
    exit 1
}

# shellcheck source=lib/installer-common/summary.sh
source "${INSTALLER_COMMON}/summary.sh" || {
    print_message "error" "Failed to source summary.sh from ${INSTALLER_COMMON}"
    exit 1
}

# shellcheck source=lib/installer-common/templates.sh
source "${INSTALLER_COMMON}/templates.sh" || {
    print_message "error" "Failed to source templates.sh from ${INSTALLER_COMMON}"
    exit 1
}

# shellcheck source=lib/installer-common/migrations.sh
source "${INSTALLER_COMMON}/migrations.sh" || {
    print_message "error" "Failed to source migrations.sh from ${INSTALLER_COMMON}"
    exit 1
}

# Script version
VERSION_FILE="${SCRIPT_DIR}/VERSION"
if [[ -f "$VERSION_FILE" ]]; then
    VERSION="$(cat "$VERSION_FILE")"
    readonly VERSION
else
    print_message "error" "VERSION file not found at $VERSION_FILE"
    exit 1
fi

# Installation directories
readonly AIDA_DIR="${HOME}/.aida"
readonly CLAUDE_DIR="${HOME}/.claude"
readonly CLAUDE_MD="${HOME}/CLAUDE.md"

# Installation mode
DEV_MODE=false

# User configuration
ASSISTANT_NAME=""
PERSONALITY=""

#######################################
# Display usage information
# Globals:
#   VERSION
# Arguments:
#   None
# Outputs:
#   Writes usage information to stdout
#######################################
usage() {
    cat << EOF
AIDA Framework Installation Script v${VERSION}

Usage: $(basename "$0") [OPTIONS]

Options:
    --dev       Install in development mode (uses symlinks for live editing)
    --help      Display this help message and exit

Description:
    Installs the AIDA (Agentic Intelligence Digital Assistant) framework to your system.

    Normal installation creates:
        ~/.aida/        Framework files (copied from repository)
        ~/.claude/      User configuration directory
        ~/CLAUDE.md     Main entry point file

    Development mode creates:
        ~/.aida/        Symlink to repository (for live editing)
        ~/.claude/      User configuration directory (copied)
        ~/CLAUDE.md     Main entry point file

Examples:
    $(basename "$0")            # Normal installation
    $(basename "$0") --dev      # Development mode
    $(basename "$0") --help     # Show this help

For more information, visit:
    https://github.com/oakensoul/claude-personal-assistant

EOF
}


#######################################
# Check for existing installation and create backup
# Delegates to directories.sh module for actual implementation
# Globals:
#   AIDA_DIR, CLAUDE_DIR, CLAUDE_MD, DEV_MODE, SCRIPT_DIR
# Arguments:
#   None
# Returns:
#   0 on success
#######################################
check_existing_install() {
    print_message "info" "Checking for existing installation..."

    local backup_made=false

    # Check AIDA directory - use validate_symlink if in dev mode
    if [[ -e "${AIDA_DIR}" ]]; then
        if [[ "$DEV_MODE" == true ]] && [[ -L "${AIDA_DIR}" ]]; then
            if validate_symlink "${AIDA_DIR}" "${SCRIPT_DIR}"; then
                print_message "info" "AIDA directory already symlinked correctly"
                return 0
            fi
        fi

        backup_existing "${AIDA_DIR}" || return 1
        # backup_existing removes symlinks but not directories, so remove if it's a directory
        if [[ -d "${AIDA_DIR}" ]]; then
            rm -rf "${AIDA_DIR}" || {
                print_message "error" "Failed to remove existing AIDA directory after backup"
                return 1
            }
        fi
        backup_made=true
    fi

    # Check Claude directory
    # NOTE: We do NOT delete ~/.claude/ - it may contain user files!
    # The namespace design installs AIDA templates to ~/.claude/*/.aida/
    # User files remain at the top level: ~/.claude/commands/my-file.md
    # AIDA files go in subdirs: ~/.claude/commands/.aida/start-work.md
    if [[ -e "${CLAUDE_DIR}" ]]; then
        if [[ ! -d "${CLAUDE_DIR}" ]]; then
            print_message "error" "${CLAUDE_DIR} exists but is not a directory"
            return 1
        fi
        print_message "info" "Found existing ${CLAUDE_DIR} directory (user content will be preserved)"
        backup_made=true
    fi

    # Check CLAUDE.md
    if [[ -e "${CLAUDE_MD}" ]]; then
        backup_existing "${CLAUDE_MD}" || return 1
        # Remove the original file after backup
        if [[ -f "${CLAUDE_MD}" ]]; then
            rm -f "${CLAUDE_MD}" || {
                print_message "error" "Failed to remove existing CLAUDE.md after backup"
                return 1
            }
        fi
        backup_made=true
    fi

    if [[ "$backup_made" == false ]]; then
        print_message "success" "No existing installation found"
    fi

    echo ""
}

#######################################
# Create required directory structure
# Delegates to directories.sh module for actual implementation
# Globals:
#   AIDA_DIR, CLAUDE_DIR, DEV_MODE, SCRIPT_DIR
# Arguments:
#   None
# Returns:
#   0 on success
#######################################
create_directories() {
    print_message "info" "Creating directory structure..."

    # Create AIDA directory using module function
    create_aida_dir "$SCRIPT_DIR" "$AIDA_DIR" "$DEV_MODE" || {
        print_message "error" "Failed to create AIDA directory"
        return 1
    }

    # Create Claude configuration directories using module function
    create_claude_dirs "$CLAUDE_DIR" || {
        print_message "error" "Failed to create Claude directories"
        return 1
    }

    # Set proper permissions (only on AIDA-managed files, not user content)
    print_message "info" "Setting permissions on AIDA-managed files..."

    # Set permissions only on AIDA namespace directories (preserves user file permissions)
    for namespace_dir in "${CLAUDE_DIR}/commands/.aida" "${CLAUDE_DIR}/agents/.aida" \
                         "${CLAUDE_DIR}/skills/.aida" "${CLAUDE_DIR}/documents/.aida"; do
        if [[ -d "$namespace_dir" ]]; then
            find "$namespace_dir" -type f -exec chmod 644 {} \; 2>/dev/null || true
            find "$namespace_dir" -type d -exec chmod 755 {} \; 2>/dev/null || true
        fi
    done

    # Set permissions on config file and CLAUDE.md
    chmod 644 "${CLAUDE_DIR}/aida-config.json" 2>/dev/null || true
    chmod 644 "${HOME}/CLAUDE.md" 2>/dev/null || true

    if [[ "$DEV_MODE" == false ]]; then
        find "${AIDA_DIR}" -type f -exec chmod 644 {} \; 2>/dev/null || true
        find "${AIDA_DIR}" -type d -exec chmod 755 {} \; 2>/dev/null || true
        chmod 755 "${AIDA_DIR}/install.sh" 2>/dev/null || true
    fi

    print_message "success" "Permissions set"
    echo ""
}


#######################################
# Display installation summary wrapper
# Calls summary.sh module functions
# Globals:
#   VERSION, DEV_MODE, AIDA_DIR, CLAUDE_DIR
# Arguments:
#   None
#######################################
show_installation_summary() {
    # Convert DEV_MODE boolean to mode string
    local mode="normal"
    if [[ "$DEV_MODE" == true ]]; then
        mode="dev"
    fi

    # Use the display_summary function from summary.sh module
    display_summary "$mode" "$AIDA_DIR" "$CLAUDE_DIR" "$VERSION"

    # Display user configuration details
    echo ""
    echo "User Configuration:"
    echo "  Assistant Name:  ${ASSISTANT_NAME}"
    echo "  Personality:     ${PERSONALITY}"
    echo ""
}

#######################################
# Main installation function (orchestrator)
# Coordinates installation flow by calling modular functions
# Globals:
#   All script globals
# Arguments:
#   Command line arguments
# Returns:
#   0 on success, non-zero on failure
#######################################
main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dev)
                DEV_MODE=true
                shift
                ;;
            --help)
                usage
                exit 0
                ;;
            *)
                print_message "error" "Unknown option: $1"
                echo ""
                usage
                exit 1
                ;;
        esac
    done

    # Display header
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  AIDA Framework Installer v${VERSION}"
    echo "  Agentic Intelligence Digital Assistant"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    if [[ "$DEV_MODE" == true ]]; then
        print_message "warning" "Running in DEVELOPMENT MODE"
        echo ""
    fi

    # Run installation steps (orchestrated flow)
    validate_dependencies || {
        print_message "error" "Dependency validation failed"
        exit 1
    }
    echo ""

    # Prompt for assistant name
    print_message "info" "Configure your assistant name"
    echo ""
    echo "The assistant name will be used throughout the AIDA framework."
    echo "Requirements: lowercase, no spaces, 3-20 characters"
    echo ""

    ASSISTANT_NAME=$(prompt_input \
        "Enter assistant name (e.g., 'jarvis', 'alfred')" \
        "" \
        "^[a-z][a-z0-9-]*$" \
        "Name must start with a letter and contain only lowercase letters, numbers, and hyphens")

    while [[ ${#ASSISTANT_NAME} -lt 3 || ${#ASSISTANT_NAME} -gt 20 ]]; do
        print_message "warning" "Name must be 3-20 characters (got ${#ASSISTANT_NAME})"
        ASSISTANT_NAME=$(prompt_input \
            "Enter assistant name (e.g., 'jarvis', 'alfred')" \
            "" \
            "^[a-z][a-z0-9-]*$" \
            "Name must start with a letter and contain only lowercase letters, numbers, and hyphens")
    done

    print_message "success" "Assistant name set to: ${ASSISTANT_NAME}"
    echo ""

    # Prompt for personality selection
    print_message "info" "Select your assistant personality"
    echo ""
    echo "Available personalities:"
    echo "  1) jarvis         - Snarky British AI (helpful but judgmental)"
    echo "  2) alfred         - Dignified butler (professional, respectful)"
    echo "  3) friday         - Enthusiastic helper (upbeat, encouraging)"
    echo "  4) sage           - Zen guide (calm, mindful)"
    echo "  5) drill-sergeant - No-nonsense coach (intense, demanding)"
    echo ""

    local personalities=("jarvis" "alfred" "friday" "sage" "drill-sergeant")
    local choice

    while true; do
        choice=$(prompt_input "Select personality [1-5]" "")

        if [[ ! "$choice" =~ ^[1-5]$ ]]; then
            print_message "warning" "Invalid choice. Please enter a number between 1 and 5"
            continue
        fi

        local index=$((choice - 1))
        PERSONALITY="${personalities[$index]}"
        break
    done

    print_message "success" "Personality set to: ${PERSONALITY}"
    echo ""

    # Backup existing installation if found
    check_existing_install

    # Run migrations for backward compatibility
    run_migrations

    # Create directory structure
    create_directories

    # Install templates using namespace isolation (.aida/)

    # Commands
    install_templates \
        "${SCRIPT_DIR}/templates/commands" \
        "${CLAUDE_DIR}/commands" \
        "$DEV_MODE" \
        ".aida" || {
        print_message "error" "Failed to install command templates"
        exit 1
    }

    # Agents
    install_templates \
        "${SCRIPT_DIR}/templates/agents" \
        "${CLAUDE_DIR}/agents" \
        "$DEV_MODE" \
        ".aida" || {
        print_message "error" "Failed to install agent templates"
        exit 1
    }

    # Skills
    install_templates \
        "${SCRIPT_DIR}/templates/skills" \
        "${CLAUDE_DIR}/skills" \
        "$DEV_MODE" \
        ".aida" || {
        print_message "error" "Failed to install skill templates"
        exit 1
    }

    # Documents
    install_templates \
        "${SCRIPT_DIR}/templates/documents" \
        "${CLAUDE_DIR}/documents" \
        "$DEV_MODE" \
        ".aida" || {
        print_message "error" "Failed to install document templates"
        exit 1
    }

    # Scripts
    install_templates \
        "${SCRIPT_DIR}/scripts" \
        "${CLAUDE_DIR}/scripts" \
        "$DEV_MODE" \
        ".aida" || {
        print_message "error" "Failed to install CLI scripts"
        exit 1
    }

    # Write user configuration (convert boolean to string)
    local install_mode="normal"
    if [[ "$DEV_MODE" == "true" ]]; then
        install_mode="dev"
    fi

    write_user_config "$install_mode" "$AIDA_DIR" "$CLAUDE_DIR" "$VERSION" "$ASSISTANT_NAME" "$PERSONALITY" || {
        print_message "error" "Failed to write user configuration"
        exit 1
    }

    # Generate entry point (use module function with all required parameters)
    generate_claude_md "$CLAUDE_MD" "$ASSISTANT_NAME" "$PERSONALITY" "$VERSION" || {
        print_message "error" "Failed to generate CLAUDE.md"
        exit 1
    }

    # Display results
    show_installation_summary

    # Convert DEV_MODE to mode string for display_next_steps
    local mode="normal"
    if [[ "$DEV_MODE" == true ]]; then
        mode="dev"
    fi
    display_next_steps "$mode"

    echo ""
    display_success "Installation completed successfully!"
    echo ""
}

# Run main function with all script arguments
main "$@"
