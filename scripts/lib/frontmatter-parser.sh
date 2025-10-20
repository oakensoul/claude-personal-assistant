#!/usr/bin/env bash
# frontmatter-parser.sh - Extract YAML frontmatter from markdown files
#
# Usage:
#   source frontmatter-parser.sh
#   parse_frontmatter <file> <key>
#   get_frontmatter_value <file> <key>
#   validate_frontmatter <file>
#
# Description:
#   Provides functions to extract and validate YAML frontmatter from markdown files.
#   Uses sed/awk for portability (no dependencies like yq).

set -euo pipefail

# Extract frontmatter section from markdown file
# Args:
#   $1 - File path
# Returns:
#   Frontmatter content (without --- markers) on stdout
extract_frontmatter() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        return 1
    fi

    # Extract content between first two '---' markers
    # This sed command:
    # 1. Looks for lines starting with '---'
    # 2. Prints everything between first and second occurrence
    # 3. Excludes the '---' markers themselves
    sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$file"
}

# Get value for a specific frontmatter key
# Args:
#   $1 - File path
#   $2 - Key name (e.g., "name", "version", "category")
# Returns:
#   Value on stdout, or empty string if not found
get_frontmatter_value() {
    local file="$1"
    local key="$2"

    if [[ ! -f "$file" ]]; then
        return 1
    fi

    # Extract frontmatter and parse specific key
    # This awk command:
    # 1. Looks for "key:" pattern
    # 2. Handles quoted and unquoted values
    # 3. Trims whitespace
    extract_frontmatter "$file" | awk -v key="$key" '
        $1 == key ":" {
            # Remove key and colon
            sub(/^[^:]+:[ \t]*/, "")

            # Remove quotes if present
            gsub(/^["'\'']|["'\'']$/, "")

            # Trim whitespace
            gsub(/^[ \t]+|[ \t]+$/, "")

            print
            exit
        }
    '
}

# Get array values for a frontmatter key
# Args:
#   $1 - File path
#   $2 - Key name (e.g., "tags", "skills")
# Returns:
#   Array values, one per line
get_frontmatter_array() {
    local file="$1"
    local key="$2"

    if [[ ! -f "$file" ]]; then
        return 1
    fi

    # Extract frontmatter and parse array
    # Handles both inline arrays [a, b, c] and multi-line arrays
    extract_frontmatter "$file" | awk -v key="$key" '
        BEGIN { in_array = 0 }

        # Inline array: tags: [tag1, tag2, tag3]
        $1 == key ":" && /\[.*\]/ {
            # Extract content between brackets
            match($0, /\[([^\]]*)\]/, arr)
            if (arr[1]) {
                # Split by comma and print each item
                n = split(arr[1], items, /,[ \t]*/)
                for (i = 1; i <= n; i++) {
                    # Remove quotes
                    gsub(/^["'\'']|["'\'']$/, "", items[i])
                    gsub(/^[ \t]+|[ \t]+$/, "", items[i])
                    if (items[i] != "") print items[i]
                }
            }
            exit
        }

        # Multi-line array start
        $1 == key ":" {
            in_array = 1
            next
        }

        # Array items (start with -)
        in_array && /^[ \t]*-/ {
            sub(/^[ \t]*-[ \t]*/, "")
            gsub(/^["'\'']|["'\'']$/, "")
            gsub(/^[ \t]+|[ \t]+$/, "")
            if ($0 != "") print
            next
        }

        # End of array (non-indented key or empty line)
        in_array && /^[a-zA-Z]/ {
            exit
        }
    '
}

# Validate that file has valid frontmatter
# Args:
#   $1 - File path
# Returns:
#   0 if valid, 1 if invalid
validate_frontmatter() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        return 1
    fi

    # Check that file starts with ---
    if ! head -n 1 "$file" | grep -q '^---$'; then
        return 1
    fi

    # Check that there's a closing ---
    if ! sed -n '2,/^---$/p' "$file" | tail -n 1 | grep -q '^---$'; then
        return 1
    fi

    return 0
}

# Validate required frontmatter fields
# Args:
#   $1 - File path
#   $2+ - Required field names
# Returns:
#   0 if all fields present, 1 if any missing
# Outputs:
#   Missing field names to stderr
validate_required_fields() {
    local file="$1"
    shift
    local required_fields=("$@")
    local missing_fields=()

    if ! validate_frontmatter "$file"; then
        echo "ERROR: Invalid or missing frontmatter in $file" >&2
        return 1
    fi

    for field in "${required_fields[@]}"; do
        local value
        value=$(get_frontmatter_value "$file" "$field")
        if [[ -z "$value" ]]; then
            missing_fields+=("$field")
        fi
    done

    if [[ ${#missing_fields[@]} -gt 0 ]]; then
        echo "ERROR: Missing required fields in $file: ${missing_fields[*]}" >&2
        return 1
    fi

    return 0
}

# Validate frontmatter field format
# Args:
#   $1 - File path
#   $2 - Field name
#   $3 - Regex pattern
# Returns:
#   0 if valid, 1 if invalid
validate_field_format() {
    local file="$1"
    local field="$2"
    local pattern="$3"

    local value
    value=$(get_frontmatter_value "$file" "$field")

    if [[ -z "$value" ]]; then
        echo "ERROR: Field '$field' not found in $file" >&2
        return 1
    fi

    if ! echo "$value" | grep -qE "$pattern"; then
        echo "ERROR: Field '$field' in $file has invalid format: '$value' (expected pattern: $pattern)" >&2
        return 1
    fi

    return 0
}

# Export functions for use in other scripts
export -f extract_frontmatter
export -f get_frontmatter_value
export -f get_frontmatter_array
export -f validate_frontmatter
export -f validate_required_fields
export -f validate_field_format
