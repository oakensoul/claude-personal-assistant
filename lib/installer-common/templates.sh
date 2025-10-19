#!/usr/bin/env bash
#
# templates.sh - Template Installation with Namespace Isolation
#
# Description:
#   Template installation for AIDA installer-common library implementing namespace
#   isolation (ADR-013). Installs templates to .aida/ subdirectories to protect user
#   content. Supports both normal mode (copy) and dev mode (symlink).
#
#   NO VARIABLE SUBSTITUTION: Templates stay pure and use aida-config-helper.sh at runtime.
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
#   source "${INSTALLER_COMMON}/templates.sh"
#
# Author: oakensoul
# License: AGPL-3.0
# Repository: https://github.com/oakensoul/claude-personal-assistant
#

set -euo pipefail

# Prevent multiple sourcing
[[ -n "${_INSTALLER_TEMPLATES_SH_LOADED:-}" ]] && return 0
readonly _INSTALLER_TEMPLATES_SH_LOADED=1

#######################################
# Validate template folder structure
#
# Validates that a template folder has the required structure:
# - Must be a directory
# - Must contain README.md file
#
# Arguments:
#   $1 - Template directory path (required)
#
# Returns:
#   0 if valid template structure
#   1 if invalid structure
#
# Outputs:
#   Error messages via logging if validation fails
#
# Example:
#   if validate_template_structure "$template_dir"; then
#     echo "Valid template"
#   fi
#######################################
validate_template_structure() {
    local template_dir="$1"

    # Validate input
    if [[ -z "$template_dir" ]]; then
        print_message "error" "validate_template_structure: template_dir required"
        return 1
    fi

    # Check if directory exists
    if [[ ! -d "$template_dir" ]]; then
        print_message "error" "Template is not a directory: ${template_dir}"
        return 1
    fi

    # Check for valid template file
    # Commands/Documents use README.md
    # Agents use {agent-name}.md
    local template_name
    template_name=$(basename "$template_dir")

    if [[ -f "${template_dir}/README.md" ]]; then
        # Standard template (commands, documents, skills)
        return 0
    elif [[ -f "${template_dir}/${template_name}.md" ]]; then
        # Agent template (agent-name/agent-name.md)
        return 0
    else
        print_message "error" "Template missing required file: ${template_dir}"
        print_message "info" "  Expected: README.md or ${template_name}.md"
        return 1
    fi

    return 0
}

#######################################
# Install single template folder
#
# Installs a single template folder to destination with either copy or symlink
# based on dev_mode setting. Validates template structure before installation.
#
# Arguments:
#   $1 - Source template folder path (required)
#   $2 - Destination folder path (required)
#   $3 - Dev mode (true = symlink, false = copy, required)
#
# Returns:
#   0 on success
#   1 on failure
#
# Outputs:
#   Installation status via logging
#
# Example:
#   install_template_folder "$src/start-work" "$dst/.aida/start-work" false
#######################################
install_template_folder() {
    local src_folder="$1"
    local dst_folder="$2"
    local dev_mode="$3"

    # Validate inputs
    if [[ -z "$src_folder" ]]; then
        print_message "error" "install_template_folder: src_folder required"
        return 1
    fi

    if [[ -z "$dst_folder" ]]; then
        print_message "error" "install_template_folder: dst_folder required"
        return 1
    fi

    if [[ -z "$dev_mode" ]]; then
        print_message "error" "install_template_folder: dev_mode required"
        return 1
    fi

    # Validate template structure
    if ! validate_template_structure "$src_folder"; then
        return 1
    fi

    local template_name
    template_name=$(basename "$src_folder")

    # Create parent directory if needed
    local parent_dir
    parent_dir=$(dirname "$dst_folder")
    if [[ ! -d "$parent_dir" ]]; then
        mkdir -p "$parent_dir" || {
            print_message "error" "Failed to create parent directory: ${parent_dir}"
            return 1
        }
    fi

    # Install based on mode
    if [[ "$dev_mode" == "true" ]]; then
        # Dev mode: create symlink
        if [[ -L "$dst_folder" ]]; then
            # Check if symlink already points to correct target
            local current_target
            if current_target=$(readlink "$dst_folder" 2>/dev/null); then
                if [[ "$current_target" == "$src_folder" ]]; then
                    print_message "info" "Template already symlinked correctly: ${template_name}"
                    return 0
                else
                    print_message "warning" "Template symlink points to wrong target, recreating: ${template_name}"
                    rm "$dst_folder"
                fi
            fi
        elif [[ -e "$dst_folder" ]]; then
            # Path exists but is not a symlink - backup and remove
            local timestamp
            timestamp=$(date +%Y%m%d-%H%M%S)
            local backup_path="${dst_folder}.backup.${timestamp}"
            print_message "warning" "Backing up existing template before symlinking: ${template_name}"
            mv "$dst_folder" "$backup_path" || {
                print_message "error" "Failed to backup existing template: ${template_name}"
                return 1
            }
            print_message "info" "Backup created: ${backup_path}"
        fi

        # Create symlink
        ln -s "$src_folder" "$dst_folder" || {
            print_message "error" "Failed to create symlink for template: ${template_name}"
            return 1
        }
        print_message "success" "Template symlinked (dev mode): ${template_name}"

    else
        # Normal mode: copy files
        if [[ -e "$dst_folder" ]]; then
            # Destination already exists - backup and remove
            local timestamp
            timestamp=$(date +%Y%m%d-%H%M%S)
            local backup_path="${dst_folder}.backup.${timestamp}"

            if [[ -L "$dst_folder" ]]; then
                print_message "warning" "Converting symlink to directory: ${template_name}"
            else
                print_message "info" "Updating existing template: ${template_name}"
            fi

            mv "$dst_folder" "$backup_path" || {
                print_message "error" "Failed to backup existing template: ${template_name}"
                return 1
            }
            print_message "info" "Backup created: ${backup_path}"
        fi

        # Copy template (recursive, preserve attributes)
        cp -a "$src_folder" "$dst_folder" || {
            print_message "error" "Failed to copy template: ${template_name}"
            return 1
        }
        print_message "success" "Template installed: ${template_name}"
    fi

    return 0
}

#######################################
# Install templates with namespace isolation
#
# Main entry point for template installation. Installs templates from source directory
# to destination directory within a namespace subdirectory (.aida or .aida-deprecated).
# This implements the namespace isolation pattern from ADR-013.
#
# Templates are installed as folders (not individual files) and NO variable substitution
# is performed. Templates should use aida-config-helper.sh at runtime for configuration.
#
# Arguments:
#   $1 - Source template directory (required)
#   $2 - Destination base directory (required)
#   $3 - Dev mode (true = symlink, false = copy, default: false)
#   $4 - Namespace (.aida or .aida-deprecated, default: .aida)
#
# Returns:
#   0 on success (all templates installed)
#   1 on failure
#
# Outputs:
#   Installation status via logging
#
# Example:
#   # Normal mode: copy templates to ~/.claude/commands/.aida/
#   install_templates "$repo/templates/commands" ~/.claude/commands false .aida
#
#   # Dev mode: symlink templates for live editing
#   install_templates "$repo/templates/commands" ~/.claude/commands true .aida
#######################################
install_templates() {
    local src_dir="$1"
    local dst_dir="$2"
    local dev_mode="${3:-false}"
    local namespace="${4:-.aida}"

    # Validate inputs
    if [[ -z "$src_dir" ]]; then
        print_message "error" "install_templates: src_dir required"
        return 1
    fi

    if [[ -z "$dst_dir" ]]; then
        print_message "error" "install_templates: dst_dir required"
        return 1
    fi

    # Validate source directory exists
    if [[ ! -d "$src_dir" ]]; then
        print_message "error" "Source template directory does not exist: ${src_dir}"
        return 1
    fi

    # Validate namespace format
    if [[ "$namespace" != ".aida" && "$namespace" != ".aida-deprecated" ]]; then
        print_message "warning" "Unusual namespace: ${namespace} (expected .aida or .aida-deprecated)"
    fi

    local namespace_dir="${dst_dir}/${namespace}"

    print_message "info" "Installing templates from ${src_dir}..."

    # Dev mode: symlink entire namespace directory to source
    if [[ "$dev_mode" == "true" ]]; then
        # Create parent directory if needed
        if [[ ! -d "$dst_dir" ]]; then
            mkdir -p "$dst_dir" || {
                print_message "error" "Failed to create directory: ${dst_dir}"
                return 1
            }
        fi

        # Check if namespace already exists
        if [[ -e "$namespace_dir" ]]; then
            if [[ -L "$namespace_dir" ]]; then
                # It's a symlink - check if it points to correct target
                local current_target
                if current_target=$(readlink "$namespace_dir" 2>/dev/null); then
                    if [[ "$current_target" == "$src_dir" ]]; then
                        # Count templates for reporting
                        local template_count=0
                        for template in "$src_dir"/*; do
                            [[ -d "$template" ]] || continue
                            template_count=$((template_count + 1))
                        done
                        print_message "info" "Namespace already symlinked correctly: ${namespace_dir}"
                        print_message "success" "Verified ${template_count} template(s) at ${namespace_dir}"
                        return 0
                    else
                        print_message "warning" "Namespace symlink points to wrong target, recreating"
                        rm "$namespace_dir" || {
                            print_message "error" "Failed to remove incorrect symlink"
                            return 1
                        }
                    fi
                fi
            else
                # It's a regular directory - backup and remove
                local timestamp
                timestamp=$(date +%Y%m%d-%H%M%S)
                local backup_path="${namespace_dir}.backup.${timestamp}"
                print_message "warning" "Backing up existing namespace directory before symlinking"
                mv "$namespace_dir" "$backup_path" || {
                    print_message "error" "Failed to backup namespace directory"
                    return 1
                }
                print_message "info" "Backup created: ${backup_path}"
            fi
        fi

        # Create symlink
        ln -s "$src_dir" "$namespace_dir" || {
            print_message "error" "Failed to create namespace symlink: ${namespace_dir} -> ${src_dir}"
            return 1
        }

        # Count templates for reporting
        local template_count=0
        for template in "$src_dir"/*; do
            [[ -d "$template" ]] || continue
            template_count=$((template_count + 1))
        done

        print_message "success" "Symlinked ${template_count} template(s): ${namespace_dir} -> ${src_dir}"
        return 0
    fi

    # Normal mode: copy entire templates directory to namespace
    # Create parent directory if needed
    if [[ ! -d "$dst_dir" ]]; then
        mkdir -p "$dst_dir" || {
            print_message "error" "Failed to create directory: ${dst_dir}"
            return 1
        }
    fi

    # Check if namespace directory already exists
    if [[ -e "$namespace_dir" ]]; then
        # Backup existing namespace directory
        local timestamp
        timestamp=$(date +%Y%m%d-%H%M%S)
        local backup_path="${namespace_dir}.backup.${timestamp}"
        print_message "warning" "Backing up existing namespace directory"
        mv "$namespace_dir" "$backup_path" || {
            print_message "error" "Failed to backup namespace directory"
            return 1
        }
        print_message "info" "Backup created: ${backup_path}"
    fi

    # Copy entire source directory to namespace (recursive, preserve attributes)
    cp -a "$src_dir" "$namespace_dir" || {
        print_message "error" "Failed to copy templates: ${src_dir} -> ${namespace_dir}"
        return 1
    }

    # Count templates for reporting
    local template_count=0
    for template in "$namespace_dir"/*; do
        [[ -d "$template" ]] || continue
        template_count=$((template_count + 1))
    done

    # Check if any templates were found
    if [[ $template_count -eq 0 ]]; then
        print_message "warning" "No template directories found in: ${src_dir}"
        return 0
    fi

    print_message "success" "Installed ${template_count} template(s) to ${namespace_dir}"
    return 0
}

#######################################
# Generate main CLAUDE.md entry point
#
# Generates the main CLAUDE.md file at ~/CLAUDE.md that serves as the entry point
# for the AIDA assistant. This file contains basic configuration and quick reference.
#
# Arguments:
#   $1 - Output file path (required)
#   $2 - Assistant name (required)
#   $3 - Personality (required)
#   $4 - Version (required)
#
# Returns:
#   0 on success
#   1 on failure
#
# Outputs:
#   Writes status messages via logging
#
# Example:
#   generate_claude_md ~/CLAUDE.md "JARVIS" "professional" "0.1.6"
#######################################
generate_claude_md() {
    local output_file="$1"
    local assistant_name="$2"
    local personality="$3"
    local version="$4"

    # Validate required parameters
    if [[ -z "$output_file" ]] || [[ -z "$assistant_name" ]] ||
       [[ -z "$personality" ]] || [[ -z "$version" ]]; then
        print_message "error" "generate_claude_md: Missing required parameters"
        return 1
    fi

    print_message "info" "Generating CLAUDE.md entry point..."

    cat > "${output_file}" << CLAUDEEOF
---
title: "CLAUDE.md - ${assistant_name} Configuration"
description: "Personal AIDA assistant configuration"
assistant_name: "${assistant_name}"
personality: "${personality}"
last_updated: "$(date +%Y-%m-%d)"
---

# $(echo "$assistant_name" | tr '[:lower:]' '[:upper:]') - Your AIDA Assistant

Welcome! I'm ${assistant_name}, your Agentic Intelligence Digital Assistant.

## Personality

Current personality: **${personality}**

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

Generated by AIDA Framework v${version}
For more information: https://github.com/oakensoul/claude-personal-assistant
CLAUDEEOF

    # Validate file was created
    if [[ ! -s "$output_file" ]]; then
        print_message "error" "Failed to generate CLAUDE.md"
        return 1
    fi

    chmod 644 "${output_file}"
    print_message "success" "CLAUDE.md generated at ${output_file}"
    echo ""

    return 0
}
