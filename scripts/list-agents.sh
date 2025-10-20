#!/usr/bin/env bash
# list-agents.sh - List all available AIDA agents
#
# Usage:
#   list-agents.sh [--format FORMAT]
#
# Options:
#   --format FORMAT   Output format: text (default) or json
#
# Description:
#   Scans user-level (~/.claude/agents/) directory for agent definitions
#   and displays them in a formatted list.

set -euo pipefail

# Script directory for sourcing libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"

# Source required libraries
# shellcheck source=lib/frontmatter-parser.sh
source "$LIB_DIR/frontmatter-parser.sh"
# shellcheck source=lib/path-sanitizer.sh
source "$LIB_DIR/path-sanitizer.sh"
# shellcheck source=lib/readlink-portable.sh
source "$LIB_DIR/readlink-portable.sh"
# shellcheck source=lib/json-formatter.sh
source "$LIB_DIR/json-formatter.sh"

# Default configuration
readonly CLAUDE_CONFIG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
readonly AIDA_HOME="${AIDA_HOME:-$HOME/.aida}"
readonly OUTPUT_FORMAT="${1:-text}"

# Parse command-line arguments
format="text"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --format)
            format="$2"
            shift 2
            ;;
        --help|-h)
            cat <<EOF
Usage: list-agents.sh [--format FORMAT]

List all available AIDA agents from user-level configuration.

Options:
  --format FORMAT   Output format: text (default) or json
  --help, -h        Show this help message

Examples:
  list-agents.sh                    # Plain text output
  list-agents.sh --format json      # JSON output
EOF
            exit 0
            ;;
        *)
            echo "ERROR: Unknown option: $1" >&2
            echo "Use --help for usage information" >&2
            exit 1
            ;;
    esac
done

# Validate format
if [[ "$format" != "text" ]] && [[ "$format" != "json" ]]; then
    echo "ERROR: Invalid format '$format'. Use 'text' or 'json'." >&2
    exit 1
fi

# Agent data structure (bash 3.2 compatible)
agents_seen_file=$(mktemp)
trap 'rm -f "$agents_seen_file"' EXIT
declare -a framework_agents
declare -a user_agents

# Discover agents in a directory
# Args:
#   $1 - Base directory to scan
#   $2 - File pattern (e.g., "*/agent-name.md" or "*/index.md")
#   $3 - Scope ("framework" or "user")
discover_agents() {
    local base_dir="$1"
    local file_pattern="$2"
    local scope="$3"

    # Check if directory exists
    if [[ ! -d "$base_dir" ]]; then
        return 0
    fi

    # Find agent files matching pattern
    while IFS= read -r -d '' agent_file; do
        # Skip knowledge base files (not agent definitions)
        if [[ "$agent_file" == */knowledge/* ]]; then
            continue
        fi

        # Skip README files (documentation, not agent definitions)
        if [[ "$(basename "$agent_file")" == "README.md" ]]; then
            continue
        fi

        # Get canonical path for deduplication
        local canonical_path
        canonical_path=$(realpath_portable "$agent_file" 2>/dev/null || echo "$agent_file")

        # Skip if already seen (deduplicate symlinks)
        if grep -Fxq "$canonical_path" "$agents_seen_file" 2>/dev/null; then
            continue
        fi

        # Validate frontmatter
        if ! validate_frontmatter "$agent_file" 2>/dev/null; then
            echo "WARNING: Skipping $agent_file (invalid frontmatter)" >&2
            continue
        fi

        # Extract frontmatter fields
        local name version category description short_description
        name=$(get_frontmatter_value "$agent_file" "name" 2>/dev/null || echo "")
        version=$(get_frontmatter_value "$agent_file" "version" 2>/dev/null || echo "")
        category=$(get_frontmatter_value "$agent_file" "category" 2>/dev/null || echo "")
        description=$(get_frontmatter_value "$agent_file" "description" 2>/dev/null || echo "")
        short_description=$(get_frontmatter_value "$agent_file" "short_description" 2>/dev/null || echo "")

        # Check if this is a project config file (has 'project' and 'agent' fields)
        # rather than an agent definition (has 'name' and 'description' fields)
        local project_field
        project_field=$(get_frontmatter_value "$agent_file" "project" 2>/dev/null || echo "")

        if [[ -n "$project_field" ]]; then
            # This is a project configuration file, not an agent definition - skip silently
            continue
        fi

        # Validate required fields for agent definitions
        if [[ -z "$name" ]] || [[ -z "$description" ]]; then
            echo "WARNING: Skipping $agent_file (missing required fields: name or description)" >&2
            continue
        fi

        # Use short_description for display, fallback to description
        local display_description="$short_description"
        if [[ -z "$display_description" ]]; then
            display_description="$description"
        fi

        # Check if agent has project context
        local has_context="No"
        if [[ -d ".claude/project/agents/$name" ]]; then
            has_context="Yes"
        fi

        # Sanitize path for privacy
        local sanitized_path
        sanitized_path=$(sanitize_path "$agent_file")

        # Mark as seen
        echo "$canonical_path" >> "$agents_seen_file"

        # Store agent data (with context flag)
        local agent_data="$name|$version|$category|$display_description|$has_context|$sanitized_path"

        if [[ "$scope" == "framework" ]]; then
            framework_agents+=("$agent_data")
        else
            user_agents+=("$agent_data")
        fi

    done < <(find "$base_dir" -type f \( -name "*.md" -o -name "index.md" \) -print0 2>/dev/null)
}

# Output agents in text format
output_text() {
    local total_count=$(( ${#framework_agents[@]:-0} + ${#user_agents[@]:-0} ))

    if [[ $total_count -eq 0 ]]; then
        echo "No agents found."
        echo ""
        echo "Framework agents: $AIDA_HOME/templates/agents/"
        echo "User agents: $CLAUDE_CONFIG_DIR/agents/"
        return 0
    fi

    # Display framework agents
    if [[ ${#framework_agents[@]:-0} -gt 0 ]]; then
        echo "Framework Agents"
        echo "──────────────────────────────────────────────────────────────────────────"
        echo ""
        printf "%-25s %-10s %-15s %-8s %s\n" "Name" "Version" "Category" "Context" "Description"
        printf "%-25s %-10s %-15s %-8s %s\n" "────" "───────" "────────" "───────" "───────────"

        for agent_data in "${framework_agents[@]}"; do
            IFS='|' read -r name version category description has_context path <<< "$agent_data"
            printf "%-25s %-10s %-15s %-8s %s\n" "$name" "$version" "$category" "$has_context" "$description"
        done
        echo ""
    fi

    # Display user agents
    if [[ ${#user_agents[@]:-0} -gt 0 ]]; then
        echo "User Agents"
        echo "──────────────────────────────────────────────────────────────────────────"
        echo ""
        printf "%-25s %-10s %-15s %-8s %s\n" "Name" "Version" "Category" "Context" "Description"
        printf "%-25s %-10s %-15s %-8s %s\n" "────" "───────" "────────" "───────" "───────────"

        for agent_data in "${user_agents[@]}"; do
            IFS='|' read -r name version category description has_context path <<< "$agent_data"
            printf "%-25s %-10s %-15s %-8s %s\n" "$name" "$version" "$category" "$has_context" "$description"
        done
        echo ""
    fi

    echo "Total: $total_count agent(s)"
}

# Output agents in JSON format
output_json() {
    local total_count=$(( ${#framework_agents[@]:-0} + ${#user_agents[@]:-0} ))

    # Build framework agents JSON array
    local framework_json="["
    local first=true
    for agent_data in ${framework_agents[@]+"${framework_agents[@]}"}; do
        IFS='|' read -r name version category description has_context path <<< "$agent_data"

        if [[ "$first" != "true" ]]; then
            framework_json+=","
        fi
        first=false

        # Add has_context to JSON
        framework_json+="{\"name\":$(json_string "$name"),\"version\":$(json_string "$version"),\"category\":$(json_string "$category"),\"description\":$(json_string "$description"),\"has_context\":$(json_string "$has_context"),\"path\":$(json_string "$path")}"
    done
    framework_json+="]"

    # Build user agents JSON array
    local user_json="["
    first=true
    for agent_data in ${user_agents[@]+"${user_agents[@]}"}; do
        IFS='|' read -r name version category description has_context path <<< "$agent_data"

        if [[ "$first" != "true" ]]; then
            user_json+=","
        fi
        first=false

        # Add has_context to JSON
        user_json+="{\"name\":$(json_string "$name"),\"version\":$(json_string "$version"),\"category\":$(json_string "$category"),\"description\":$(json_string "$description"),\"has_context\":$(json_string "$has_context"),\"path\":$(json_string "$path")}"
    done
    user_json+="]"

    # Output complete JSON response (rename from global/project to framework/user)
    cat <<EOF
{
  "type": "agents",
  "count": $total_count,
  "framework": $framework_json,
  "user": $user_json
}
EOF
}

# Main execution
main() {
    # Discover framework-provided agents
    if [[ -d "$AIDA_HOME/templates/agents" ]]; then
        discover_agents "$AIDA_HOME/templates/agents" "*/*.md" "framework"
    fi

    # Discover user-level agents
    # Pattern: ~/.claude/agents/{agent-name}/{agent-name}.md or {agent-name}/index.md
    # Note: ./.claude/project/agents/ contains project instructions, not agent definitions
    if [[ -d "$CLAUDE_CONFIG_DIR/agents" ]]; then
        discover_agents "$CLAUDE_CONFIG_DIR/agents" "*/*.md" "user"
    fi

    # Output results
    if [[ "$format" == "json" ]]; then
        output_json
    else
        output_text
    fi
}

# Run main function
main
