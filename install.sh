#!/usr/bin/env bash
#
# install.sh - AIDA Framework Installation Script
#
# Description:
#   Core installation script for the AIDA (Agentic Intelligence Digital Assistant) framework.
#   Handles directory creation, template copying, variable substitution, and initial setup.
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

# Script version
readonly VERSION="0.1.0"

# Installation directories
readonly AIDA_DIR="${HOME}/.aida"
readonly CLAUDE_DIR="${HOME}/.claude"
readonly CLAUDE_MD="${HOME}/CLAUDE.md"

# Script directory (repository root)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# Installation mode
DEV_MODE=false

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

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
# Print formatted message
# Arguments:
#   $1 - Message type (info, success, warning, error)
#   $2 - Message text
# Outputs:
#   Writes formatted message to stdout/stderr
#######################################
print_message() {
    local type="$1"
    local message="$2"

    case "$type" in
        info)
            echo -e "${BLUE}ℹ${NC} ${message}"
            ;;
        success)
            echo -e "${GREEN}✓${NC} ${message}"
            ;;
        warning)
            echo -e "${YELLOW}⚠${NC} ${message}"
            ;;
        error)
            echo -e "${RED}✗${NC} ${message}" >&2
            ;;
        *)
            echo "${message}"
            ;;
    esac
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

    # Check bash version (require >= 4.0)
    if [[ "${BASH_VERSINFO[0]}" -lt 4 ]]; then
        print_message "error" "Bash version 4.0 or higher is required (found ${BASH_VERSION})"
        errors=$((errors + 1))
    else
        print_message "success" "Bash version ${BASH_VERSION}"
    fi

    # Check for required commands
    local required_commands=("git" "mkdir" "chmod" "ln" "rsync" "date" "mv" "find")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            print_message "error" "Required command not found: $cmd"
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
# Prompt user for assistant name with validation
# Globals:
#   ASSISTANT_NAME
# Arguments:
#   None
# Returns:
#   0 on success
# Outputs:
#   Writes prompts to stdout, reads from stdin
#######################################
prompt_assistant_name() {
    print_message "info" "Configure your assistant name"
    echo ""
    echo "The assistant name will be used throughout the AIDA framework."
    echo "Requirements: lowercase, no spaces, 3-20 characters"
    echo ""

    while true; do
        read -rp "Enter assistant name (e.g., 'jarvis', 'alfred'): " name

        # Validate name
        if [[ -z "$name" ]]; then
            print_message "warning" "Assistant name cannot be empty"
            continue
        fi

        if [[ ${#name} -lt 3 || ${#name} -gt 20 ]]; then
            print_message "warning" "Name must be 3-20 characters (got ${#name})"
            continue
        fi

        if [[ "$name" =~ [[:space:]] ]]; then
            print_message "warning" "Name cannot contain spaces"
            continue
        fi

        if [[ "$name" != "${name,,}" ]]; then
            print_message "warning" "Name must be lowercase"
            continue
        fi

        if [[ ! "$name" =~ ^[a-z][a-z0-9-]*$ ]]; then
            print_message "warning" "Name must start with a letter and contain only lowercase letters, numbers, and hyphens"
            continue
        fi

        # Valid name
        ASSISTANT_NAME="$name"
        print_message "success" "Assistant name set to: ${ASSISTANT_NAME}"
        echo ""
        break
    done
}

#######################################
# Prompt user to select personality
# Globals:
#   PERSONALITY
# Arguments:
#   None
# Returns:
#   0 on success
# Outputs:
#   Writes prompts to stdout, reads from stdin
#######################################
prompt_personality() {
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

    while true; do
        read -rp "Select personality [1-5]: " choice

        if [[ ! "$choice" =~ ^[1-5]$ ]]; then
            print_message "warning" "Invalid choice. Please enter a number between 1 and 5"
            continue
        fi

        # Convert choice to array index (0-based)
        local index=$((choice - 1))
        PERSONALITY="${personalities[$index]}"

        print_message "success" "Personality set to: ${PERSONALITY}"
        echo ""
        break
    done
}

#######################################
# Check for existing installation and create backup
# Globals:
#   AIDA_DIR, CLAUDE_DIR, CLAUDE_MD, DEV_MODE
# Arguments:
#   None
# Returns:
#   0 on success
# Outputs:
#   Writes status messages to stdout
#######################################
check_existing_install() {
    local backup_needed=false
    local backup_timestamp
    backup_timestamp=$(date +%Y%m%d_%H%M%S)

    print_message "info" "Checking for existing installation..."

    # Check for existing AIDA directory
    if [[ -e "${AIDA_DIR}" ]]; then
        print_message "warning" "Existing AIDA installation found at ${AIDA_DIR}"

        # In dev mode, check if it's already a symlink to this directory
        if [[ "$DEV_MODE" == true ]] && [[ -L "${AIDA_DIR}" ]]; then
            local link_target
            link_target=$(readlink "${AIDA_DIR}")
            if [[ "$link_target" == "$SCRIPT_DIR" ]]; then
                print_message "info" "AIDA directory already symlinked to this repository"
                return 0
            fi
        fi

        backup_needed=true
        local backup_dir="${AIDA_DIR}.backup.${backup_timestamp}"
        print_message "info" "Creating backup: ${backup_dir}"
        mv "${AIDA_DIR}" "${backup_dir}"
        print_message "success" "Backup created"
    fi

    # Check for existing Claude directory
    if [[ -d "${CLAUDE_DIR}" ]]; then
        print_message "warning" "Existing Claude configuration found at ${CLAUDE_DIR}"
        backup_needed=true
        local backup_dir="${CLAUDE_DIR}.backup.${backup_timestamp}"
        print_message "info" "Creating backup: ${backup_dir}"
        mv "${CLAUDE_DIR}" "${backup_dir}"
        print_message "success" "Backup created"
    fi

    # Check for existing CLAUDE.md
    if [[ -f "${CLAUDE_MD}" ]]; then
        print_message "warning" "Existing CLAUDE.md found at ${CLAUDE_MD}"
        backup_needed=true
        local backup_file="${CLAUDE_MD}.backup.${backup_timestamp}"
        print_message "info" "Creating backup: ${backup_file}"
        mv "${CLAUDE_MD}" "${backup_file}"
        print_message "success" "Backup created"
    fi

    if [[ "$backup_needed" == false ]]; then
        print_message "success" "No existing installation found"
    fi

    echo ""
}

#######################################
# Create required directory structure
# Globals:
#   AIDA_DIR, CLAUDE_DIR, DEV_MODE, SCRIPT_DIR
# Arguments:
#   None
# Returns:
#   0 on success
# Outputs:
#   Writes status messages to stdout
#######################################
create_directories() {
    print_message "info" "Creating directory structure..."

    # Create AIDA directory (or symlink in dev mode)
    if [[ "$DEV_MODE" == true ]]; then
        print_message "info" "Creating symlink: ${AIDA_DIR} -> ${SCRIPT_DIR}"
        ln -s "${SCRIPT_DIR}" "${AIDA_DIR}"
        print_message "success" "AIDA directory symlinked (dev mode)"
    else
        print_message "info" "Creating directory: ${AIDA_DIR}"
        mkdir -p "${AIDA_DIR}"

        # Copy repository contents to AIDA directory
        print_message "info" "Copying framework files..."

        # Copy directories and files, excluding .git and other dev files
        rsync -av --exclude='.git' \
                  --exclude='.github' \
                  --exclude='.idea' \
                  --exclude='*.backup.*' \
                  "${SCRIPT_DIR}/" "${AIDA_DIR}/"

        print_message "success" "Framework files copied"
    fi

    # Create Claude configuration directories
    print_message "info" "Creating Claude configuration directories..."

    local claude_dirs=(
        "${CLAUDE_DIR}"
        "${CLAUDE_DIR}/config"
        "${CLAUDE_DIR}/knowledge"
        "${CLAUDE_DIR}/memory"
        "${CLAUDE_DIR}/memory/history"
        "${CLAUDE_DIR}/agents"
    )

    for dir in "${claude_dirs[@]}"; do
        mkdir -p "$dir"
        chmod 755 "$dir"
    done

    print_message "success" "Claude configuration directories created"

    # Set proper permissions
    print_message "info" "Setting permissions..."
    find "${CLAUDE_DIR}" -type f -exec chmod 644 {} \;
    find "${CLAUDE_DIR}" -type d -exec chmod 755 {} \;

    if [[ "$DEV_MODE" == false ]]; then
        find "${AIDA_DIR}" -type f -exec chmod 644 {} \;
        find "${AIDA_DIR}" -type d -exec chmod 755 {} \;
        chmod 755 "${AIDA_DIR}/install.sh"
    fi

    print_message "success" "Permissions set"
    echo ""
}

#######################################
# Generate main CLAUDE.md entry point
# Globals:
#   CLAUDE_MD, ASSISTANT_NAME, PERSONALITY
# Arguments:
#   None
# Returns:
#   0 on success
# Outputs:
#   Writes status messages to stdout
#######################################
generate_claude_md() {
    print_message "info" "Generating CLAUDE.md entry point..."

    cat > "${CLAUDE_MD}" << EOF
---
title: "CLAUDE.md - ${ASSISTANT_NAME} Configuration"
description: "Personal AIDA assistant configuration"
assistant_name: "${ASSISTANT_NAME}"
personality: "${PERSONALITY}"
last_updated: "$(date +%Y-%m-%d)"
---

# ${ASSISTANT_NAME^^} - Your AIDA Assistant

Welcome! I'm ${ASSISTANT_NAME}, your Agentic Intelligence Digital Assistant.

## Personality

Current personality: **${PERSONALITY}**

## Configuration

- Framework: \`~/.aida/\`
- Configuration: \`~/.claude/\`
- Knowledge base: \`~/.claude/knowledge/\`
- Memory: \`~/.claude/memory/\`
- Agents: \`~/.claude/agents/\`

## Quick Reference

### Managing Your Assistant

\`\`\`bash
aida status        # Check system status
aida personality   # Change personality
aida knowledge     # View knowledge base
aida memory        # View memory
aida help          # Show help
\`\`\`

### Natural Language Commands

Simply talk to me naturally:
- "What should I focus on today?"
- "Clean up my downloads folder"
- "End of day summary"
- "Help me with [task]"

## Getting Started

1. Review the knowledge base in \`~/.claude/knowledge/\`
2. Customize your preferences
3. Start a conversation!

---

Generated by AIDA Framework v${VERSION}
For more information: https://github.com/oakensoul/claude-personal-assistant
EOF

    chmod 644 "${CLAUDE_MD}"
    print_message "success" "CLAUDE.md generated at ${CLAUDE_MD}"
    echo ""
}

#######################################
# Display installation summary
# Globals:
#   AIDA_DIR, CLAUDE_DIR, CLAUDE_MD, ASSISTANT_NAME, PERSONALITY, DEV_MODE
# Arguments:
#   None
# Outputs:
#   Writes summary to stdout
#######################################
display_summary() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_message "success" "Installation complete!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Configuration Summary:"
    echo "  Assistant Name:  ${ASSISTANT_NAME}"
    echo "  Personality:     ${PERSONALITY}"
    if [[ "$DEV_MODE" == true ]]; then
        echo "  Mode:            Development (symlinked)"
    else
        echo "  Mode:            Normal"
    fi
    echo ""
    echo "Installation Locations:"
    echo "  Framework:       ${AIDA_DIR}"
    echo "  Configuration:   ${CLAUDE_DIR}"
    echo "  Entry Point:     ${CLAUDE_MD}"
    echo ""
    echo "Next Steps:"
    echo "  1. Review your configuration in ${CLAUDE_DIR}"
    echo "  2. Customize knowledge base and agents"
    echo "  3. Start using AIDA with Claude AI"
    echo ""
    if [[ "$DEV_MODE" == true ]]; then
        print_message "warning" "Development mode is active"
        echo "     Changes to ${SCRIPT_DIR} will be reflected in ${AIDA_DIR}"
        echo ""
    fi
    echo "For help and documentation:"
    echo "  https://github.com/oakensoul/claude-personal-assistant"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

#######################################
# Main installation function
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

    # Run installation steps
    validate_dependencies || {
        print_message "error" "Dependency validation failed"
        exit 1
    }
    echo ""

    prompt_assistant_name
    prompt_personality

    check_existing_install
    create_directories
    generate_claude_md

    display_summary

    print_message "success" "Installation completed successfully!"
    echo ""
}

# Run main function with all script arguments
main "$@"
