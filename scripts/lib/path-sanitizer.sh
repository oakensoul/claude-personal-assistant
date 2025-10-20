#!/usr/bin/env bash
# path-sanitizer.sh - Replace absolute paths with variables for privacy
#
# Usage:
#   source path-sanitizer.sh
#   sanitize_path <path>
#   sanitize_output <text>
#
# Description:
#   Replaces absolute paths with environment variables to protect user privacy
#   in command output and logs.

set -euo pipefail

# Sanitize a single path
# Args:
#   $1 - Path to sanitize
# Returns:
#   Sanitized path on stdout
sanitize_path() {
    local path="$1"

    # Get environment variables (with fallbacks)
    local home="${HOME:-}"
    local claude_config_dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
    local aida_home="${AIDA_HOME:-$HOME/.aida}"
    local project_root="${PROJECT_ROOT:-$(pwd)}"

    # Order matters: replace most specific paths first
    # This prevents partial replacements

    # Replace CLAUDE_CONFIG_DIR (most specific)
    if [[ -n "$claude_config_dir" ]] && [[ "$path" == "$claude_config_dir"* ]]; then
        echo "${path/$claude_config_dir/\${CLAUDE_CONFIG_DIR\}}"
        return 0
    fi

    # Replace AIDA_HOME
    if [[ -n "$aida_home" ]] && [[ "$path" == "$aida_home"* ]]; then
        echo "${path/$aida_home/\${AIDA_HOME\}}"
        return 0
    fi

    # Replace PROJECT_ROOT (only if not in home or system paths)
    if [[ -n "$project_root" ]] && [[ "$path" == "$project_root"* ]] && [[ "$path" != "$home"* ]]; then
        echo "${path/$project_root/\${PROJECT_ROOT\}}"
        return 0
    fi

    # Replace HOME directory
    if [[ -n "$home" ]] && [[ "$path" == "$home"* ]]; then
        echo "${path/$home/\${HOME\}}"
        return 0
    fi

    # No replacement needed
    echo "$path"
}

# Sanitize all paths in text output
# Args:
#   $1 - Text containing paths
# Returns:
#   Sanitized text on stdout
sanitize_output() {
    local text="$1"

    # Get environment variables
    local home="${HOME:-}"
    local claude_config_dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
    local aida_home="${AIDA_HOME:-$HOME/.aida}"
    local project_root="${PROJECT_ROOT:-$(pwd)}"

    # Replace in order (most specific first)
    # Use sed for multi-line text replacement

    # Replace CLAUDE_CONFIG_DIR
    if [[ -n "$claude_config_dir" ]]; then
        text=$(echo "$text" | sed "s|$claude_config_dir|\${CLAUDE_CONFIG_DIR}|g")
    fi

    # Replace AIDA_HOME
    if [[ -n "$aida_home" ]]; then
        text=$(echo "$text" | sed "s|$aida_home|\${AIDA_HOME}|g")
    fi

    # Replace PROJECT_ROOT (but not if it's in HOME)
    if [[ -n "$project_root" ]] && [[ "$project_root" != "$home"* ]]; then
        text=$(echo "$text" | sed "s|$project_root|\${PROJECT_ROOT}|g")
    fi

    # Replace HOME
    if [[ -n "$home" ]]; then
        text=$(echo "$text" | sed "s|$home|\${HOME}|g")
    fi

    echo "$text"
}

# Sanitize username from text
# Args:
#   $1 - Text potentially containing username
# Returns:
#   Sanitized text on stdout
sanitize_username() {
    local text="$1"
    local username="${USER:-$(whoami)}"

    if [[ -n "$username" ]]; then
        # Replace username with ${USER}
        echo "$text" | sed "s|$username|\${USER}|g"
    else
        echo "$text"
    fi
}

# Sanitize hostname from text
# Args:
#   $1 - Text potentially containing hostname
# Returns:
#   Sanitized text on stdout
sanitize_hostname() {
    local text="$1"
    local hostname="${HOSTNAME:-$(hostname)}"

    if [[ -n "$hostname" ]]; then
        # Replace hostname with ${HOSTNAME}
        echo "$text" | sed "s|$hostname|\${HOSTNAME}|g"
    else
        echo "$text"
    fi
}

# Full sanitization (all methods)
# Args:
#   $1 - Text to sanitize
# Returns:
#   Fully sanitized text on stdout
sanitize_all() {
    local text="$1"

    # Apply all sanitization methods in order
    text=$(sanitize_output "$text")
    text=$(sanitize_username "$text")
    text=$(sanitize_hostname "$text")

    echo "$text"
}

# Check if path contains sensitive information
# Args:
#   $1 - Path to check
# Returns:
#   0 if sensitive, 1 if safe
is_path_sensitive() {
    local path="$1"
    local home="${HOME:-}"
    local username="${USER:-$(whoami)}"

    # Check if path contains home directory
    if [[ -n "$home" ]] && [[ "$path" == "$home"* ]]; then
        return 0
    fi

    # Check if path contains username
    if [[ -n "$username" ]] && [[ "$path" == *"$username"* ]]; then
        return 0
    fi

    # Path appears safe
    return 1
}

# Get sanitized current working directory
# Returns:
#   Sanitized pwd on stdout
get_sanitized_pwd() {
    sanitize_path "$(pwd)"
}

# Export functions for use in other scripts
export -f sanitize_path
export -f sanitize_output
export -f sanitize_username
export -f sanitize_hostname
export -f sanitize_all
export -f is_path_sensitive
export -f get_sanitized_pwd
