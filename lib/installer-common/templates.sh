#!/usr/bin/env bash
#
# templates.sh - Template Processing and File Generation
#
# Description:
#   AIDA-specific template processing including command templates and CLAUDE.md generation.
#   Handles variable substitution and template deployment for both normal and dev modes.
#
# Dependencies:
#   - colors.sh (must be sourced first)
#   - logging.sh (must be sourced first)
#
# Part of: AIDA installer-common library v1.0
# Usage:
#   source "${INSTALLER_COMMON}/colors.sh"
#   source "${INSTALLER_COMMON}/logging.sh"
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
# Copy command templates with variable substitution
# Arguments:
#   $1 - Source template directory (required)
#   $2 - Destination directory (required)
#   $3 - AIDA_DIR path for substitution (required)
#   $4 - CLAUDE_DIR path for substitution (required)
#   $5 - HOME path for substitution (required)
#   $6 - DEV_MODE (true/false) (required)
# Returns:
#   0 on success, 1 on failure
# Outputs:
#   Writes status messages via logging
#######################################
copy_command_templates() {
    local template_dir="$1"
    local install_dir="$2"
    local aida_dir="$3"
    local claude_dir="$4"
    local home_dir="$5"
    local dev_mode="${6:-false}"
    local backup_timestamp
    backup_timestamp=$(date +%Y%m%d_%H%M%S)

    print_message "info" "Installing command templates..."

    # Ensure target directory exists
    mkdir -p "${install_dir}"

    # Dev mode: symlink templates directory
    if [[ "$dev_mode" == true ]]; then
        print_message "info" "Dev mode: symlinking commands for live editing..."
        if [[ -d "${install_dir}" ]] && [[ ! -L "${install_dir}" ]]; then
            # Backup existing directory before replacing with symlink
            local dev_backup="${install_dir}.backup.${backup_timestamp}"
            mv "${install_dir}" "${dev_backup}"
            print_message "warning" "Backed up existing commands to ${dev_backup}"
        fi
        # Remove existing symlink if present
        rm -rf "${install_dir}"
        # Create symlink to template directory
        ln -s "${template_dir}" "${install_dir}"
        print_message "success" "Commands symlinked (dev mode)"
        echo ""
        return 0
    fi

    # Normal mode: copy templates with variable substitution
    print_message "info" "Processing command templates with variable substitution..."

    # Process each template file
    for template in "${template_dir}"/*.md; do
        # Skip if no templates found
        [[ -e "${template}" ]] || continue

        local cmd_name
        cmd_name=$(basename "${template}")
        local target="${install_dir}/${cmd_name}"

        # Backup existing file if it exists
        if [[ -f "${target}" ]]; then
            local backup_dir="${claude_dir}/commands/.backups/${backup_timestamp}"
            mkdir -p "${backup_dir}"
            cp -p "${target}" "${backup_dir}/${cmd_name}"
            print_message "info" "Backed up: ${cmd_name}"
        fi

        # Substitute variables using sed
        # Note: {{VAR}} patterns are for install-time substitution
        # ${VAR} patterns in templates are preserved for runtime bash resolution
        sed -e "s|{{AIDA_HOME}}|${aida_dir}|g" \
            -e "s|{{CLAUDE_CONFIG_DIR}}|${claude_dir}|g" \
            -e "s|{{HOME}}|${home_dir}|g" \
            "${template}" > "${target}"

        # Validate output (check file was created and not empty)
        if [[ ! -s "${target}" ]]; then
            print_message "error" "Template substitution failed for ${cmd_name}"
            rm -f "${target}"
            return 1
        fi

        # Verify install-time template variables were substituted
        # Note: Runtime variables like {{PROJECT_ROOT}} and {{timestamp}} are intentionally preserved
        if grep -qE '\{\{(AIDA_HOME|CLAUDE_CONFIG_DIR|HOME)\}\}' "${target}"; then
            print_message "error" "Unresolved install-time template variables in ${cmd_name}"
            grep -E '\{\{(AIDA_HOME|CLAUDE_CONFIG_DIR|HOME)\}\}' "${target}"
            return 1
        fi

        # Set restrictive permissions (600) for installed commands
        chmod 600 "${target}"
    done

    print_message "success" "Command templates installed"
    echo ""
}

#######################################
# Generate main CLAUDE.md entry point
# Arguments:
#   $1 - Output file path (required)
#   $2 - Assistant name (required)
#   $3 - Personality (required)
#   $4 - Version (required)
# Returns:
#   0 on success, 1 on failure
# Outputs:
#   Writes status messages via logging
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
