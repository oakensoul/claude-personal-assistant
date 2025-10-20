#!/usr/bin/env bash
# list-commands.sh - List all available AIDA commands
#
# Usage:
#   list-commands.sh [--format FORMAT] [--category CATEGORY]
#
# Options:
#   --format FORMAT       Output format: text (default) or json
#   --category CATEGORY   Filter by category
#
# Description:
#   Scans user-level (~/.claude/commands/) and project-level (./.claude/commands/)
#   directories for command definitions and displays them in a formatted list.
#   Supports filtering by category and grouping output by category.

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

# Valid categories (from taxonomy)
readonly VALID_CATEGORIES=(
    "workflow"
    "git"
    "project"
    "analysis"
    "deployment"
    "testing"
    "documentation"
    "meta"
)

# Parse command-line arguments
format="text"
category_filter=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --format)
            format="$2"
            shift 2
            ;;
        --category)
            category_filter="$2"
            shift 2
            ;;
        --help|-h)
            cat <<EOF
Usage: list-commands.sh [--format FORMAT] [--category CATEGORY]

List all available AIDA commands from user and project levels.

Options:
  --format FORMAT       Output format: text (default) or json
  --category CATEGORY   Filter by category (workflow, git, project, analysis,
                        deployment, testing, documentation, meta)
  --help, -h            Show this help message

Examples:
  list-commands.sh                          # Plain text output, all categories
  list-commands.sh --category workflow      # Show only workflow commands
  list-commands.sh --format json            # JSON output
  list-commands.sh --category meta --format json
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

# Validate category filter (if provided)
if [[ -n "$category_filter" ]]; then
    valid=false
    for cat in "${VALID_CATEGORIES[@]}"; do
        if [[ "$cat" == "$category_filter" ]]; then
            valid=true
            break
        fi
    done

    if [[ "$valid" == "false" ]]; then
        echo "ERROR: Invalid category '$category_filter'." >&2
        echo "Valid categories: ${VALID_CATEGORIES[*]}" >&2
        exit 1
    fi
fi

# Command data structure (bash 3.2 compatible)
commands_seen_file=$(mktemp)
trap 'rm -f "$commands_seen_file"' EXIT
declare -a global_commands
declare -a project_commands

# Discover commands in a directory
# Args:
#   $1 - Base directory to scan
#   $2 - Scope ("global" or "project")
discover_commands() {
    local base_dir="$1"
    local scope="$2"

    # Check if directory exists
    if [[ ! -d "$base_dir" ]]; then
        return 0
    fi

    # Find all .md files (including in .aida subdirectory)
    while IFS= read -r -d '' command_file; do
        # Skip if not a markdown file
        if [[ ! "$command_file" =~ \.md$ ]]; then
            continue
        fi

        # Skip README files (documentation, not commands)
        if [[ "$(basename "$command_file")" == "README.md" ]]; then
            continue
        fi

        # Determine command name and namespace
        local command_name namespace=""
        if [[ "$command_file" == *"/.aida/"* ]]; then
            namespace=".aida/"
            command_name=$(basename "$command_file" .md)
        else
            command_name=$(basename "$command_file" .md)
        fi

        local full_name="${namespace}${command_name}"

        # Deduplication: project commands override user commands
        if [[ "$scope" == "project" ]]; then
            # Project command - always include (overrides user)
            echo "$full_name|project" >> "$commands_seen_file"
        else
            # User command - only include if not already seen from project
            if grep -q "^$full_name|" "$commands_seen_file" 2>/dev/null; then
                continue  # Skip, project version takes precedence
            fi
            echo "$full_name|global" >> "$commands_seen_file"
        fi

        # Validate frontmatter
        if ! validate_frontmatter "$command_file" 2>/dev/null; then
            echo "WARNING: Skipping $command_file (invalid frontmatter)" >&2
            continue
        fi

        # Extract frontmatter fields
        local name version category description
        name=$(get_frontmatter_value "$command_file" "name" 2>/dev/null || echo "")
        version=$(get_frontmatter_value "$command_file" "version" 2>/dev/null || echo "1.0.0")
        category=$(get_frontmatter_value "$command_file" "category" 2>/dev/null || echo "")
        description=$(get_frontmatter_value "$command_file" "description" 2>/dev/null || echo "")

        # Validate required fields
        if [[ -z "$name" ]] || [[ -z "$description" ]] || [[ -z "$category" ]]; then
            echo "WARNING: Skipping $command_file (missing required fields)" >&2
            continue
        fi

        # Apply category filter if specified
        if [[ -n "$category_filter" ]] && [[ "$category" != "$category_filter" ]]; then
            continue
        fi

        # Sanitize path for privacy
        local sanitized_path
        sanitized_path=$(sanitize_path "$command_file")

        # Store command data (with namespace prefix)
        local command_data="${full_name}|${version}|${category}|${description}|${sanitized_path}"

        if [[ "$scope" == "global" ]]; then
            global_commands+=("$command_data")
        else
            project_commands+=("$command_data")
        fi

    done < <(find "$base_dir" -type f -name "*.md" -print0 2>/dev/null)
}

# Sort and group commands by category (bash 3.2 compatible)
# Args:
#   $@ - Array of command data strings
# Returns:
#   Sorted commands on stdout
sort_by_category() {
    local commands=("$@")

    # Print all commands, prepending with category for sorting
    for command_data in "${commands[@]}"; do
        IFS='|' read -r name version category description path <<< "$command_data"
        echo "$category|$command_data"
    done | sort
}

# Output commands in text format
output_text() {
    local total_count=$(( ${#global_commands[@]:-0} + ${#project_commands[@]:-0} ))

    if [[ $total_count -eq 0 ]]; then
        if [[ -n "$category_filter" ]]; then
            echo "No commands found in category '$category_filter'."
        else
            echo "No commands found."
        fi
        echo ""
        echo "Commands should be located in:"
        echo "  - User-level: $CLAUDE_CONFIG_DIR/commands/"
        echo "  - Project-level: ./.claude/commands/"
        return 0
    fi

    # Display global commands
    if [[ ${#global_commands[@]:-0} -gt 0 ]]; then
        echo "Global Commands (User-Level)"
        echo "──────────────────────────────────────────────────"
        echo ""

        # Sort by category and display
        local prev_cat=""
        while IFS='|' read -r cat_sort name version category description path; do
            if [[ "$category" != "$prev_cat" ]]; then
                # Print category header (capitalize first letter, bash 3.2 compatible)
                local cat_display
                cat_display="$(echo "$category" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')"
                echo "$cat_display"
                prev_cat="$category"
            fi

            printf "  %-30s %-10s %s\n" "$name" "$version" "$description"
        done < <(sort_by_category "${global_commands[@]}")
        echo ""
    fi

    # Display project commands
    if [[ ${#project_commands[@]:-0} -gt 0 ]]; then
        echo "Project Commands"
        echo "──────────────────────────────────────────────────"
        echo ""

        # Sort by category and display
        local prev_cat=""
        while IFS='|' read -r cat_sort name version category description path; do
            if [[ "$category" != "$prev_cat" ]]; then
                # Print category header (capitalize first letter, bash 3.2 compatible)
                local cat_display
                cat_display="$(echo "$category" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')"
                echo "$cat_display"
                prev_cat="$category"
            fi

            printf "  %-30s %-10s %s\n" "$name" "$version" "$description"
        done < <(sort_by_category "${project_commands[@]}")
        echo ""
    fi

    echo "Total: $total_count command(s)"
}

# Output commands in JSON format
output_json() {
    local total_count=$(( ${#global_commands[@]:-0} + ${#project_commands[@]:-0} ))

    # Build global commands JSON array
    local global_json="["
    local first=true
    for command_data in ${global_commands[@]+"${global_commands[@]}"}; do
        IFS='|' read -r name version category description path <<< "$command_data"

        if [[ "$first" != "true" ]]; then
            global_json+=","
        fi
        first=false

        global_json+=$(json_item "$name" "$version" "$category" "$description" "$path")
    done
    global_json+="]"

    # Build project commands JSON array
    local project_json="["
    first=true
    for command_data in ${project_commands[@]+"${project_commands[@]}"}; do
        IFS='|' read -r name version category description path <<< "$command_data"

        if [[ "$first" != "true" ]]; then
            project_json+=","
        fi
        first=false

        project_json+=$(json_item "$name" "$version" "$category" "$description" "$path")
    done
    project_json+="]"

    # Output complete JSON response
    json_list_response "commands" "$total_count" "$global_json" "$project_json"
}

# Main execution
main() {
    # Discover framework-provided commands (lowest priority)
    if [[ -d "$AIDA_HOME/templates/commands" ]]; then
        discover_commands "$AIDA_HOME/templates/commands" "global"
    fi

    # Discover user-level commands (overrides framework, includes .aida namespace)
    discover_commands "$CLAUDE_CONFIG_DIR/commands" "global"

    # Discover project-level commands (highest priority, overrides both)
    if [[ -d "./.claude/commands" ]]; then
        discover_commands "./.claude/commands" "project"
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
