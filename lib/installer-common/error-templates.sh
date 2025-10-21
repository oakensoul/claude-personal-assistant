#!/usr/bin/env bash
#
# error-templates.sh - Error Message Templates for Configuration Validation
#
# Description:
#   Provider-specific error message templates with auto-detection and fix suggestions.
#   Used by config-validator.sh to provide clear, actionable error messages.
#
# Features:
#   - Auto-detection using vcs-detector.sh
#   - Progressive disclosure (what, why, how)
#   - Provider-specific templates
#   - Color-coded for readability
#   - Copy-paste ready fixes
#
# Part of: AIDA installer-common library v1.0
# Usage:
#   source "${INSTALLER_COMMON}/error-templates.sh"
#
# Author: oakensoul
# License: AGPL-3.0
# Repository: https://github.com/oakensoul/claude-personal-assistant
#

set -euo pipefail

# This file is sourced by config-validator.sh which already sources colors.sh
# So we have access to color_* functions

#######################################
# Show GitHub configuration fix suggestions with auto-detection
# Arguments:
#   $1 - Missing fields (comma-separated: owner,repo,enterprise_url)
#   $2 - Config file path
#   $3 - Script directory (for vcs-detector.sh)
# Outputs:
#   Fix suggestions with auto-detected values
#######################################
show_github_fix_suggestion() {
    local missing_fields="$1"
    local config_file="$2"
    local script_dir="${3:-}"
    local detected_info=""

    # Try auto-detection from git remote
    if [[ -n "$script_dir" ]] && [[ -f "${script_dir}/vcs-detector.sh" ]]; then
        detected_info=$(bash "${script_dir}/vcs-detector.sh" 2>/dev/null || true)
    fi

    echo ""
    echo "$(color_blue '═══════════════════════════════════════')"
    echo "$(color_blue 'GitHub Configuration Fix Suggestions')"
    echo "$(color_blue '═══════════════════════════════════════')"
    echo ""

    # Show auto-detected values if available
    if [[ -n "$detected_info" ]]; then
        local detected_provider detected_owner detected_repo remote_url confidence
        detected_provider=$(echo "$detected_info" | jq -r '.provider // empty' 2>/dev/null || true)
        detected_owner=$(echo "$detected_info" | jq -r '.owner // empty' 2>/dev/null || true)
        detected_repo=$(echo "$detected_info" | jq -r '.repo // empty' 2>/dev/null || true)
        remote_url=$(echo "$detected_info" | jq -r '.remote_url // empty' 2>/dev/null || true)
        confidence=$(echo "$detected_info" | jq -r '.confidence // empty' 2>/dev/null || true)

        if [[ "$detected_provider" == "github" ]] && [[ -n "$detected_owner" ]] && [[ -n "$detected_repo" ]]; then
            echo "$(color_green '✓') Auto-detected from git remote:"
            echo "  Remote URL: ${remote_url}"
            echo "  Owner:      ${detected_owner}"
            echo "  Repo:       ${detected_repo}"
            echo "  Confidence: ${confidence}"
            echo ""
            echo "$(color_green 'Quick fix (copy and paste):')"
            echo "  Add to ${config_file}:"
            echo ""
            echo "  {"
            echo "    \"vcs\": {"
            echo "      \"provider\": \"github\","
            echo "      \"owner\": \"${detected_owner}\","
            echo "      \"repo\": \"${detected_repo}\""
            echo "    }"
            echo "  }"
            echo ""
        fi
    fi

    # Manual fix instructions
    echo "$(color_blue 'Manual configuration:')"
    echo "  1. Find your GitHub repository"
    echo "  2. Get the owner (username or organization)"
    echo "  3. Get the repository name"
    echo "  4. Add to your config file:"
    echo ""
    echo "  {"
    echo "    \"vcs\": {"
    echo "      \"provider\": \"github\","
    echo "      \"owner\": \"your-username\","
    echo "      \"repo\": \"your-repo-name\""
    echo "    }"
    echo "  }"
    echo ""

    # GitHub Enterprise instructions (if relevant)
    if [[ "$missing_fields" == *"enterprise_url"* ]]; then
        echo "$(color_yellow 'For GitHub Enterprise:')"
        echo "  {"
        echo "    \"vcs\": {"
        echo "      \"provider\": \"github\","
        echo "      \"owner\": \"your-username\","
        echo "      \"repo\": \"your-repo-name\","
        echo "      \"github\": {"
        echo "        \"enterprise_url\": \"https://github.company.com\""
        echo "      }"
        echo "    }"
        echo "  }"
        echo ""
    fi

    echo "$(color_blue 'ℹ') Documentation: docs/configuration/schema-reference.md#github"
    echo ""
}

#######################################
# Show GitLab configuration fix suggestions with auto-detection
# Arguments:
#   $1 - Missing fields (comma-separated)
#   $2 - Config file path
#   $3 - Script directory (for vcs-detector.sh)
# Outputs:
#   Fix suggestions with auto-detected values
#######################################
show_gitlab_fix_suggestion() {
    local missing_fields="$1"
    local config_file="$2"
    local script_dir="${3:-}"
    local detected_info=""

    # Try auto-detection from git remote
    if [[ -n "$script_dir" ]] && [[ -f "${script_dir}/vcs-detector.sh" ]]; then
        detected_info=$(bash "${script_dir}/vcs-detector.sh" 2>/dev/null || true)
    fi

    echo ""
    echo "$(color_blue '═══════════════════════════════════════')"
    echo "$(color_blue 'GitLab Configuration Fix Suggestions')"
    echo "$(color_blue '═══════════════════════════════════════')"
    echo ""

    # Show auto-detected values if available
    if [[ -n "$detected_info" ]]; then
        local detected_provider detected_owner detected_repo remote_url confidence
        detected_provider=$(echo "$detected_info" | jq -r '.provider // empty' 2>/dev/null || true)
        detected_owner=$(echo "$detected_info" | jq -r '.owner // empty' 2>/dev/null || true)
        detected_repo=$(echo "$detected_info" | jq -r '.repo // empty' 2>/dev/null || true)
        remote_url=$(echo "$detected_info" | jq -r '.remote_url // empty' 2>/dev/null || true)
        confidence=$(echo "$detected_info" | jq -r '.confidence // empty' 2>/dev/null || true)

        if [[ "$detected_provider" == "gitlab" ]] && [[ -n "$detected_owner" ]] && [[ -n "$detected_repo" ]]; then
            echo "$(color_green '✓') Auto-detected from git remote:"
            echo "  Remote URL: ${remote_url}"
            echo "  Owner:      ${detected_owner}"
            echo "  Repo:       ${detected_repo}"
            echo "  Confidence: ${confidence}"
            echo ""
            echo "$(color_green 'Quick fix (copy and paste):')"
            echo "  Add to ${config_file}:"
            echo ""
            echo "  {"
            echo "    \"vcs\": {"
            echo "      \"provider\": \"gitlab\","
            echo "      \"owner\": \"${detected_owner}\","
            echo "      \"repo\": \"${detected_repo}\","
            echo "      \"gitlab\": {"
            echo "        \"project_id\": \"${detected_owner}/${detected_repo}\""
            echo "      }"
            echo "    }"
            echo "  }"
            echo ""
            echo "$(color_yellow '⚠') Note: Update project_id with numeric ID if known"
            echo ""
        fi
    fi

    # Manual fix instructions
    echo "$(color_blue 'Manual configuration:')"
    echo "  1. Go to your GitLab project"
    echo "  2. Get the owner (username or group)"
    echo "  3. Get the repository name"
    echo "  4. Get the project ID (found in project settings or URL)"
    echo "  5. Add to your config file:"
    echo ""
    echo "  {"
    echo "    \"vcs\": {"
    echo "      \"provider\": \"gitlab\","
    echo "      \"owner\": \"your-username\","
    echo "      \"repo\": \"your-repo-name\","
    echo "      \"gitlab\": {"
    echo "        \"project_id\": \"12345\" or \"group/project\""
    echo "      }"
    echo "    }"
    echo "  }"
    echo ""

    # Self-hosted GitLab instructions (if relevant)
    if [[ "$missing_fields" == *"self_hosted_url"* ]]; then
        echo "$(color_yellow 'For self-hosted GitLab:')"
        echo "  {"
        echo "    \"vcs\": {"
        echo "      \"gitlab\": {"
        echo "        \"self_hosted_url\": \"https://gitlab.company.com\""
        echo "      }"
        echo "    }"
        echo "  }"
        echo ""
    fi

    echo "$(color_blue 'ℹ') Documentation: docs/configuration/schema-reference.md#gitlab"
    echo ""
}

#######################################
# Show Bitbucket configuration fix suggestions with auto-detection
# Arguments:
#   $1 - Missing fields (comma-separated)
#   $2 - Config file path
#   $3 - Script directory (for vcs-detector.sh)
# Outputs:
#   Fix suggestions with auto-detected values
#######################################
show_bitbucket_fix_suggestion() {
    local missing_fields="$1"
    local config_file="$2"
    local script_dir="${3:-}"
    local detected_info=""

    # Try auto-detection from git remote
    if [[ -n "$script_dir" ]] && [[ -f "${script_dir}/vcs-detector.sh" ]]; then
        detected_info=$(bash "${script_dir}/vcs-detector.sh" 2>/dev/null || true)
    fi

    echo ""
    echo "$(color_blue '═══════════════════════════════════════')"
    echo "$(color_blue 'Bitbucket Configuration Fix Suggestions')"
    echo "$(color_blue '═══════════════════════════════════════')"
    echo ""

    # Show auto-detected values if available
    if [[ -n "$detected_info" ]]; then
        local detected_provider workspace repo_slug remote_url confidence
        detected_provider=$(echo "$detected_info" | jq -r '.provider // empty' 2>/dev/null || true)
        workspace=$(echo "$detected_info" | jq -r '.workspace // empty' 2>/dev/null || true)
        repo_slug=$(echo "$detected_info" | jq -r '.repo_slug // empty' 2>/dev/null || true)
        remote_url=$(echo "$detected_info" | jq -r '.remote_url // empty' 2>/dev/null || true)
        confidence=$(echo "$detected_info" | jq -r '.confidence // empty' 2>/dev/null || true)

        if [[ "$detected_provider" == "bitbucket" ]] && [[ -n "$workspace" ]] && [[ -n "$repo_slug" ]]; then
            echo "$(color_green '✓') Auto-detected from git remote:"
            echo "  Remote URL:  ${remote_url}"
            echo "  Workspace:   ${workspace}"
            echo "  Repo slug:   ${repo_slug}"
            echo "  Confidence:  ${confidence}"
            echo ""
            echo "$(color_green 'Quick fix (copy and paste):')"
            echo "  Add to ${config_file}:"
            echo ""
            echo "  {"
            echo "    \"vcs\": {"
            echo "      \"provider\": \"bitbucket\","
            echo "      \"bitbucket\": {"
            echo "        \"workspace\": \"${workspace}\","
            echo "        \"repo_slug\": \"${repo_slug}\""
            echo "      }"
            echo "    }"
            echo "  }"
            echo ""
        fi
    fi

    # Manual fix instructions
    echo "$(color_blue 'Manual configuration:')"
    echo "  1. Go to your Bitbucket repository"
    echo "  2. Get the workspace name (from URL or settings)"
    echo "  3. Get the repository slug (lowercase repo name with hyphens)"
    echo "  4. Add to your config file:"
    echo ""
    echo "  {"
    echo "    \"vcs\": {"
    echo "      \"provider\": \"bitbucket\","
    echo "      \"bitbucket\": {"
    echo "        \"workspace\": \"my-workspace\","
    echo "        \"repo_slug\": \"my-repo-name\""
    echo "      }"
    echo "    }"
    echo "  }"
    echo ""

    echo "$(color_blue 'ℹ') Documentation: docs/configuration/schema-reference.md#bitbucket"
    echo ""
}

#######################################
# Show Jira configuration fix suggestions
# Arguments:
#   $1 - Missing fields (comma-separated)
#   $2 - Config file path
# Outputs:
#   Fix suggestions
#######################################
show_jira_fix_suggestion() {
    local missing_fields="$1"
    local config_file="$2"

    echo ""
    echo "$(color_blue '═══════════════════════════════════════')"
    echo "$(color_blue 'Jira Configuration Fix Suggestions')"
    echo "$(color_blue '═══════════════════════════════════════')"
    echo ""

    echo "$(color_blue 'Manual configuration:')"
    echo "  1. Go to your Jira instance"
    echo "  2. Get the base URL (e.g., https://company.atlassian.net)"
    echo "  3. Get your project key (uppercase, 1-10 characters)"
    echo "  4. Add to your config file:"
    echo ""
    echo "  {"
    echo "    \"work_tracker\": {"
    echo "      \"provider\": \"jira\","
    echo "      \"jira\": {"
    echo "        \"base_url\": \"https://company.atlassian.net\","
    echo "        \"project_key\": \"PROJ\""
    echo "      }"
    echo "    }"
    echo "  }"
    echo ""

    echo "$(color_yellow 'Finding your project key:')"
    echo "  - Go to your project in Jira"
    echo "  - Look at the issue prefix (e.g., PROJ-123 → project key is PROJ)"
    echo "  - Or check Project Settings → Details"
    echo ""

    echo "$(color_blue 'ℹ') Documentation: docs/configuration/schema-reference.md#jira"
    echo ""
}

#######################################
# Show Linear configuration fix suggestions
# Arguments:
#   $1 - Missing fields (comma-separated)
#   $2 - Config file path
# Outputs:
#   Fix suggestions
#######################################
show_linear_fix_suggestion() {
    local missing_fields="$1"
    local config_file="$2"

    echo ""
    echo "$(color_blue '═══════════════════════════════════════')"
    echo "$(color_blue 'Linear Configuration Fix Suggestions')"
    echo "$(color_blue '═══════════════════════════════════════')"
    echo ""

    echo "$(color_blue 'Manual configuration:')"
    echo "  1. Go to your Linear workspace"
    echo "  2. Get the team ID (UUID format)"
    echo "  3. Get the board ID (UUID format)"
    echo "  4. Add to your config file:"
    echo ""
    echo "  {"
    echo "    \"work_tracker\": {"
    echo "      \"provider\": \"linear\","
    echo "      \"linear\": {"
    echo "        \"team_id\": \"123e4567-e89b-12d3-a456-426614174000\","
    echo "        \"board_id\": \"987fcdeb-51a2-43f1-9876-543210fedcba\""
    echo "      }"
    echo "    }"
    echo "  }"
    echo ""

    echo "$(color_yellow 'Finding your team and board IDs:')"
    echo "  - Go to Linear Settings → API"
    echo "  - Or check the URL when viewing your team/board"
    echo "  - Team ID is in the workspace settings"
    echo "  - Board ID is in the project settings"
    echo ""

    echo "$(color_blue 'ℹ') Documentation: docs/configuration/schema-reference.md#linear"
    echo ""
}
