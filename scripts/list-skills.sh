#!/usr/bin/env bash
# list-skills.sh - List all available AIDA skills
#
# Usage:
#   list-skills.sh [--format FORMAT]
#
# Options:
#   --format FORMAT   Output format: text (default) or json
#
# Description:
#   Scans framework (~/.aida/templates/skills/) and user-level (~/.claude/skills/)
#   directories for skill definitions and displays them.

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
Usage: list-skills.sh [--format FORMAT]

List all available AIDA skills from framework and user levels.

Options:
  --format FORMAT   Output format: text (default) or json
  --help, -h        Show this help message

Examples:
  list-skills.sh                    # Plain text output
  list-skills.sh --format json      # JSON output
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

# Skill data structure (bash 3.2 compatible)
skills_seen_file=$(mktemp)
trap 'rm -f "$skills_seen_file"' EXIT
declare -a framework_skills
declare -a user_skills

# Discover skills in a directory
# Args:
#   $1 - Base directory to scan
#   $2 - File pattern (e.g., "*/skill-name.md" or "*/index.md")
#   $3 - Scope ("framework" or "user")
discover_skills() {
    local base_dir="$1"
    local file_pattern="$2"
    local scope="$3"

    # Check if directory exists
    if [[ ! -d "$base_dir" ]]; then
        return 0
    fi

    # Find skill files matching pattern
    while IFS= read -r -d '' skill_file; do
        # Skip documentation files (not skill definitions)
        local basename_file
        basename_file="$(basename "$skill_file")"
        if [[ "$basename_file" =~ ^(README|EXAMPLES|QUICKREF|CHANGELOG|LICENSE|setup)\.md$ ]]; then
            continue
        fi

        # Get canonical path for deduplication
        local canonical_path
        canonical_path=$(realpath_portable "$skill_file" 2>/dev/null || echo "$skill_file")

        # Skip if already seen (deduplicate symlinks)
        if grep -Fxq "$canonical_path" "$skills_seen_file" 2>/dev/null; then
            continue
        fi

        # Validate frontmatter
        if ! validate_frontmatter "$skill_file" 2>/dev/null; then
            echo "WARNING: Skipping $skill_file (invalid frontmatter)" >&2
            continue
        fi

        # Extract frontmatter fields
        local name version category description short_description
        name=$(get_frontmatter_value "$skill_file" "name" 2>/dev/null || echo "")
        version=$(get_frontmatter_value "$skill_file" "version" 2>/dev/null || echo "")
        category=$(get_frontmatter_value "$skill_file" "category" 2>/dev/null || echo "")
        description=$(get_frontmatter_value "$skill_file" "description" 2>/dev/null || echo "")
        short_description=$(get_frontmatter_value "$skill_file" "short_description" 2>/dev/null || echo "")

        # Validate required fields
        if [[ -z "$name" ]] || [[ -z "$description" ]]; then
            echo "WARNING: Skipping $skill_file (missing required fields: name or description)" >&2
            continue
        fi

        # Use short_description for display, fallback to description
        local display_description="$short_description"
        if [[ -z "$display_description" ]]; then
            display_description="$description"
        fi

        # Sanitize path for privacy
        local sanitized_path
        sanitized_path=$(sanitize_path "$skill_file")

        # Mark as seen
        echo "$canonical_path" >> "$skills_seen_file"

        # Store skill data
        local skill_data="$name|$version|$category|$display_description|$sanitized_path"

        if [[ "$scope" == "framework" ]]; then
            framework_skills+=("$skill_data")
        else
            user_skills+=("$skill_data")
        fi

    done < <(find "$base_dir" -type f \( -name "*.md" -o -name "index.md" \) -print0 2>/dev/null)
}

# Output skills in text format
output_text() {
    local total_count=$(( ${#framework_skills[@]:-0} + ${#user_skills[@]:-0} ))

    if [[ $total_count -eq 0 ]]; then
        echo "No skills found."
        echo ""
        echo "Skills are not yet implemented in AIDA."
        echo "This command is a placeholder for future functionality."
        return 0
    fi

    # Display framework skills
    if [[ ${#framework_skills[@]:-0} -gt 0 ]]; then
        echo "Framework Skills"
        echo "──────────────────────────────────────────────────────────────────────────"
        echo ""
        printf "%-30s %-10s %-15s %s\n" "Name" "Version" "Category" "Description"
        printf "%-30s %-10s %-15s %s\n" "────" "───────" "────────" "───────────"

        for skill_data in "${framework_skills[@]}"; do
            IFS='|' read -r name version category description path <<< "$skill_data"
            printf "%-30s %-10s %-15s %s\n" "$name" "$version" "$category" "$description"
        done
        echo ""
    fi

    # Display user skills
    if [[ ${#user_skills[@]:-0} -gt 0 ]]; then
        echo "User Skills"
        echo "──────────────────────────────────────────────────────────────────────────"
        echo ""
        printf "%-30s %-10s %-15s %s\n" "Name" "Version" "Category" "Description"
        printf "%-30s %-10s %-15s %s\n" "────" "───────" "────────" "───────────"

        for skill_data in "${user_skills[@]}"; do
            IFS='|' read -r name version category description path <<< "$skill_data"
            printf "%-30s %-10s %-15s %s\n" "$name" "$version" "$category" "$description"
        done
        echo ""
    fi

    echo "Total: $total_count skill(s)"
}

# Output skills in JSON format
output_json() {
    local total_count=$(( ${#framework_skills[@]:-0} + ${#user_skills[@]:-0} ))

    # Build framework skills JSON array
    local framework_json="["
    local first=true
    for skill_data in ${framework_skills[@]+"${framework_skills[@]}"}; do
        IFS='|' read -r name version category description path <<< "$skill_data"

        if [[ "$first" != "true" ]]; then
            framework_json+=","
        fi
        first=false

        framework_json+=$(json_item "$name" "$version" "$category" "$description" "$path")
    done
    framework_json+="]"

    # Build user skills JSON array
    local user_json="["
    first=true
    for skill_data in ${user_skills[@]+"${user_skills[@]}"}; do
        IFS='|' read -r name version category description path <<< "$skill_data"

        if [[ "$first" != "true" ]]; then
            user_json+=","
        fi
        first=false

        user_json+=$(json_item "$name" "$version" "$category" "$description" "$path")
    done
    user_json+="]"

    # Output complete JSON response
    cat <<EOF
{
  "type": "skills",
  "count": $total_count,
  "framework": $framework_json,
  "user": $user_json
}
EOF
}

# Main execution
main() {
    # Discover framework-provided skills
    if [[ -d "$AIDA_HOME/templates/skills" ]]; then
        discover_skills "$AIDA_HOME/templates/skills" "*/*.md" "framework"
    fi

    # Discover user-level skills
    if [[ -d "$CLAUDE_CONFIG_DIR/skills" ]]; then
        discover_skills "$CLAUDE_CONFIG_DIR/skills" "*/*.md" "user"
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
