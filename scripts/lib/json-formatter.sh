#!/usr/bin/env bash
# json-formatter.sh - Format output as JSON
#
# Usage:
#   source json-formatter.sh
#   json_escape <string>
#   json_array <items...>
#   json_object <key1> <value1> <key2> <value2> ...
#
# Description:
#   Provides functions to format output as valid JSON without external dependencies.

set -euo pipefail

# Escape string for JSON
# Args:
#   $1 - String to escape
# Returns:
#   JSON-escaped string on stdout
json_escape() {
    local str="$1"

    # Escape special characters for JSON
    # Order matters: backslash first, then others
    str="${str//\\/\\\\}"  # \ -> \\
    str="${str//\"/\\\"}"  # " -> \"
    str="${str//$'\n'/\\n}"  # newline -> \n
    str="${str//$'\r'/\\r}"  # carriage return -> \r
    str="${str//$'\t'/\\t}"  # tab -> \t

    echo "$str"
}

# Create JSON string value
# Args:
#   $1 - String value
# Returns:
#   Quoted and escaped JSON string on stdout
json_string() {
    local str="$1"
    local escaped
    escaped=$(json_escape "$str")
    echo "\"$escaped\""
}

# Create JSON array from arguments
# Args:
#   $@ - Array items
# Returns:
#   JSON array on stdout
json_array() {
    local items=("$@")
    local output="["
    local first=true

    for item in "${items[@]}"; do
        if [[ "$first" == "true" ]]; then
            first=false
        else
            output+=","
        fi
        output+=$(json_string "$item")
    done

    output+="]"
    echo "$output"
}

# Create JSON object from key-value pairs
# Args:
#   $1, $2, ... - Alternating keys and values
# Returns:
#   JSON object on stdout
json_object() {
    local output="{"
    local first=true

    while [[ $# -gt 0 ]]; do
        local key="$1"
        local value="$2"
        shift 2

        if [[ "$first" == "true" ]]; then
            first=false
        else
            output+=","
        fi

        output+=$(json_string "$key")
        output+=":"
        output+=$(json_string "$value")
    done

    output+="}"
    echo "$output"
}

# Start JSON object output
# Returns:
#   Opening brace on stdout
json_start_object() {
    echo "{"
}

# End JSON object output
# Returns:
#   Closing brace on stdout
json_end_object() {
    echo "}"
}

# Start JSON array output
# Returns:
#   Opening bracket on stdout
json_start_array() {
    echo "["
}

# End JSON array output
# Returns:
#   Closing bracket on stdout
json_end_array() {
    echo "]"
}

# Format agent/skill/command as JSON object
# Args:
#   $1 - name
#   $2 - version
#   $3 - category
#   $4 - description
#   $5 - path
# Returns:
#   JSON object on stdout
json_item() {
    local name="$1"
    local version="$2"
    local category="$3"
    local description="$4"
    local path="$5"

    json_object \
        "name" "$name" \
        "version" "$version" \
        "category" "$category" \
        "description" "$description" \
        "path" "$path"
}

# Format list response as JSON
# Args:
#   $1 - type (agents, skills, or commands)
#   $2 - count
#   $3 - global_items (JSON array string)
#   $4 - project_items (JSON array string)
# Returns:
#   JSON response on stdout
json_list_response() {
    local type="$1"
    local count="$2"
    local global_items="$3"
    local project_items="$4"

    cat <<EOF
{
  "type": $(json_string "$type"),
  "count": $count,
  "global": $global_items,
  "project": $project_items
}
EOF
}

# Build JSON array from items (streaming)
# Usage:
#   {
#     echo '['
#     first=true
#     for item in items; do
#       if [[ "$first" != "true" ]]; then echo ','; fi
#       first=false
#       json_item "$name" "$version" "$category" "$description" "$path"
#     done
#     echo ']'
#   }
#
# This function helps manage the comma logic
# Returns:
#   Comma on stdout if not first item
json_item_separator() {
    local is_first="$1"

    if [[ "$is_first" != "true" ]]; then
        echo ","
    fi
}

# Pretty-print JSON (if jq available)
# Args:
#   $1 - JSON string
# Returns:
#   Pretty-printed JSON on stdout, or original if jq not available
json_pretty() {
    local json="$1"

    if command -v jq >/dev/null 2>&1; then
        echo "$json" | jq .
    else
        # Basic pretty-printing without jq
        echo "$json" | sed \
            -e 's/,/,\n/g' \
            -e 's/{/{\n/g' \
            -e 's/}/\n}/g' \
            -e 's/\[/\[\n/g' \
            -e 's/\]/\n\]/g'
    fi
}

# Validate JSON (if jq available)
# Args:
#   $1 - JSON string
# Returns:
#   0 if valid, 1 if invalid
json_validate() {
    local json="$1"

    if command -v jq >/dev/null 2>&1; then
        echo "$json" | jq empty 2>/dev/null
        return $?
    else
        # Basic validation: check balanced braces/brackets
        local open_braces
        local close_braces
        local open_brackets
        local close_brackets

        open_braces=$(echo "$json" | grep -o '{' | wc -l)
        close_braces=$(echo "$json" | grep -o '}' | wc -l)
        open_brackets=$(echo "$json" | grep -o '\[' | wc -l)
        close_brackets=$(echo "$json" | grep -o '\]' | wc -l)

        if [[ $open_braces -eq $close_braces ]] && [[ $open_brackets -eq $close_brackets ]]; then
            return 0
        else
            return 1
        fi
    fi
}

# Export functions for use in other scripts
export -f json_escape
export -f json_string
export -f json_array
export -f json_object
export -f json_start_object
export -f json_end_object
export -f json_start_array
export -f json_end_array
export -f json_item
export -f json_list_response
export -f json_item_separator
export -f json_pretty
export -f json_validate
