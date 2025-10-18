---
title: "Shell Script Specialist - AIDA Project Instructions"
description: "AIDA-specific shell scripting requirements and standards"
category: "project-agent-instructions"
tags: ["aida", "shell-script-specialist", "project-context"]
last_updated: "2025-10-09"
status: "active"
---

# AIDA Shell Script Specialist Instructions

Project-specific shell scripting standards and requirements for the AIDA framework.

## AIDA Shell Scripting Standards

### Critical Compatibility Requirements

**Bash 3.2 Compatibility (macOS Default)**:

```bash
# NEVER use Bash 4+ features
# ✗ NO: Associative arrays (Bash 4+)
declare -A config  # WILL FAIL ON macOS!

# ✓ YES: Use indexed arrays instead
config_keys=("name" "version")
config_values=("AIDA" "0.1.0")

# ✗ NO: Bash 4+ globstar
shopt -s globstar
for file in **/*.sh; do  # WILL FAIL ON macOS!

# ✓ YES: Use find instead
find . -name "*.sh" -type f | while IFS= read -r file; do
```

**Cross-Platform Commands**:

```bash
# readlink differs between macOS and Linux
# ✗ NO: readlink -f (Linux-specific)
realpath=$(readlink -f "$file")  # FAILS ON macOS

# ✓ YES: Portable alternative
realpath=$(cd "$(dirname "$file")" && pwd)/$(basename "$file")

# OR: Check for greadlink on macOS
if command -v greadlink >/dev/null 2>&1; then
    readlink="greadlink"
else
    readlink="readlink"
fi
```

## AIDA Installation Scripts

### install.sh Structure

**Main Installation Script**:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Constants
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly AIDA_HOME="${HOME}/.aida"
readonly CLAUDE_CONFIG="${HOME}/.claude"

# Functions
install_framework() {
    echo "Installing AIDA framework..."
    mkdir -p "$AIDA_HOME"
    cp -r personalities templates lib "$AIDA_HOME/"
}

install_dev_mode() {
    echo "Installing AIDA in dev mode..."
    ln -s "$SCRIPT_DIR" "$AIDA_HOME"
}

generate_user_config() {
    echo "Generating user configuration..."
    mkdir -p "$CLAUDE_CONFIG"/{agents,commands}

    # Process templates with variable substitution
    for template in templates/agents/*.md; do
        process_template "$template" "$CLAUDE_CONFIG/agents/"
    done
}

# Main execution
main() {
    if [[ "${1:-}" == "--dev" ]]; then
        install_dev_mode
    else
        install_framework
    fi

    generate_user_config
    echo "✓ AIDA installation complete"
}

main "$@"
```

### Template Processing

**Variable Substitution**:

```bash
# Process install-time variables ONLY
process_template() {
    local template="$1"
    local output_dir="$2"
    local filename="$(basename "$template")"
    local output_file="${output_dir}/${filename}"

    # Substitute install-time variables
    sed \
        -e "s|{{AIDA_HOME}}|${AIDA_HOME}|g" \
        -e "s|{{CLAUDE_CONFIG_DIR}}|${CLAUDE_CONFIG}|g" \
        -e "s|{{HOME}}|${HOME}|g" \
        "$template" > "$output_file"

    # Preserve runtime variables (${VAR}) - do NOT expand
    # They should remain as ${PROJECT_ROOT}, ${GIT_ROOT}, etc.
}
```

### Error Handling

**AIDA Error Standards**:

```bash
# Function for consistent error messages
error() {
    local message="$1"
    local code="${2:-1}"

    echo "ERROR: $message" >&2
    echo "" >&2
    echo "Installation failed. Please report this issue at:" >&2
    echo "https://github.com/oakensoul/claude-personal-assistant/issues" >&2
    exit "$code"
}

# Usage
test -d "$HOME" || error "Cannot determine HOME directory"
test -w "$HOME" || error "HOME directory is not writable"
```

## AIDA CLI Tool

### CLI Structure

**Main CLI Entry Point**:

```bash
#!/usr/bin/env bash
# ~/.aida/bin/aida

set -euo pipefail

readonly AIDA_VERSION="0.1.0"
readonly AIDA_HOME="${HOME}/.aida"

# Load library functions
source "${AIDA_HOME}/lib/common.sh"

# Subcommand dispatcher
main() {
    local command="${1:-help}"
    shift || true

    case "$command" in
        status)       cmd_status "$@" ;;
        personality)  cmd_personality "$@" ;;
        knowledge)    cmd_knowledge "$@" ;;
        help)         cmd_help ;;
        version)      echo "AIDA v${AIDA_VERSION}" ;;
        *)            error "Unknown command: $command" ;;
    esac
}

main "$@"
```

### Subcommand Implementation

**Personality Management**:

```bash
# ~/.aida/lib/personality.sh

cmd_personality() {
    local action="${1:-current}"

    case "$action" in
        list)
            list_personalities
            ;;
        current)
            get_current_personality
            ;;
        switch|set)
            local personality="$2"
            switch_personality "$personality"
            ;;
        history)
            show_personality_history
            ;;
        *)
            error "Unknown personality action: $action"
            ;;
    esac
}

switch_personality() {
    local personality="$1"
    local personality_file="${AIDA_HOME}/personalities/${personality}.yml"

    # Validate personality exists
    if [[ ! -f "$personality_file" ]]; then
        error "Personality not found: $personality"
    fi

    # Validate YAML
    yamllint "$personality_file" || error "Invalid personality YAML"

    # Switch personality
    echo "$personality" > "${CLAUDE_CONFIG}/current_personality"

    # Log to history
    log_personality_switch "$personality"

    echo "✓ Switched to personality: $personality"
}
```

**Status Display**:

```bash
# ~/.aida/lib/status.sh

cmd_status() {
    local format="${1:---full}"

    case "$format" in
        --full)
            show_full_status
            ;;
        --prompt)
            show_prompt_status
            ;;
        --json)
            show_json_status
            ;;
        *)
            error "Unknown status format: $format"
            ;;
    esac
}

show_full_status() {
    local personality=$(get_current_personality)
    local version="$AIDA_VERSION"

    cat <<EOF
AIDA Status
-----------
Version:      $version
Personality:  $personality
Config:       $CLAUDE_CONFIG
Framework:    $AIDA_HOME

Recent Activity:
$(tail -5 "${CLAUDE_CONFIG}/logs/activity.log" 2>/dev/null || echo "  No recent activity")
EOF
}
```

## AIDA Automation Scripts

### Validation Scripts

**Configuration Validation**:

```bash
#!/usr/bin/env bash
# ~/.aida/bin/validate-config

set -euo pipefail

validate_personalities() {
    local personalities_dir="${AIDA_HOME}/personalities"
    local errors=0

    for personality_file in "$personalities_dir"/*.yml; do
        echo "Validating $(basename "$personality_file")..."

        # YAML syntax
        yamllint --strict "$personality_file" || ((errors++))

        # Required fields
        grep -q "^name:" "$personality_file" || {
            echo "ERROR: Missing 'name' field"
            ((errors++))
        }
    done

    return $errors
}

validate_templates() {
    local templates_dir="${AIDA_HOME}/templates"
    local errors=0

    # Check for install-time variables properly formatted
    if grep -r "{{ [A-Z_]* }}" "$templates_dir" 2>/dev/null; then
        echo "ERROR: Found variables with spaces (use {{VAR}} not {{ VAR }})"
        ((errors++))
    fi

    # Check for accidental expansion
    if grep -r "/Users/" "$templates_dir" 2>/dev/null; then
        echo "ERROR: Found hardcoded paths (use {{HOME}})"
        ((errors++))
    fi

    return $errors
}

main() {
    echo "Validating AIDA configuration..."
    validate_personalities
    validate_templates
    echo "✓ Validation complete"
}

main "$@"
```

### Git Hooks

**Pre-commit Hook**:

```bash
#!/usr/bin/env bash
# .git/hooks/pre-commit

set -euo pipefail

# Run validation before commit
if [[ -x ~/.aida/bin/validate-config ]]; then
    ~/.aida/bin/validate-config || {
        echo "Configuration validation failed. Commit aborted."
        exit 1
    }
fi

# Check for PII in committed files
git diff --cached --name-only | while IFS= read -r file; do
    if git diff --cached "$file" | grep -i "api[_-]key.*sk-"; then
        echo "ERROR: API key detected in $file"
        exit 1
    fi
done

echo "✓ Pre-commit checks passed"
```

## Cross-Platform Compatibility

### Path Handling

**Portable Path Operations**:

```bash
# Handle spaces in paths
safe_path_op() {
    local source="$1"
    local dest="$2"

    # Always quote paths
    cp -r "$source" "$dest"

    # Use arrays for find results
    local files=()
    while IFS= read -r -d '' file; do
        files+=("$file")
    done < <(find "$source" -type f -print0)
}

# Expand tilde safely
expand_path() {
    local path="$1"

    # Expand ~ to $HOME
    path="${path/#\~/$HOME}"

    echo "$path"
}
```

### Platform Detection

**Detect macOS vs Linux**:

```bash
detect_platform() {
    case "$(uname -s)" in
        Darwin*)
            echo "macos"
            ;;
        Linux*)
            echo "linux"
            ;;
        *)
            error "Unsupported platform: $(uname -s)"
            ;;
    esac
}

# Platform-specific operations
if [[ "$(detect_platform)" == "macos" ]]; then
    # Use BSD commands
    READLINK="greadlink"
    STAT_FORMAT="-f %A"
else
    # Use GNU commands
    READLINK="readlink"
    STAT_FORMAT="-c %a"
fi
```

## Testing Requirements

### Script Testing

**Test Framework**:

```bash
# tests/test_install.sh

test_normal_install() {
    ./install.sh

    assert_dir_exists ~/.aida
    assert_dir_exists ~/.claude
    assert_file_exists ~/CLAUDE.md
}

test_dev_install() {
    ./install.sh --dev

    assert_symlink ~/.aida
    assert_symlink_points_to ~/.aida "$(pwd)"
}

# Helper functions
assert_dir_exists() {
    [[ -d "$1" ]] || fail "Directory does not exist: $1"
}

assert_file_exists() {
    [[ -f "$1" ]] || fail "File does not exist: $1"
}
```

## Integration Notes

- **User-level Shell Patterns**: Load from `~/.claude/agents/shell-script-specialist/`
- **Project-specific requirements**: This file
- **Combined approach**: User philosophy + AIDA requirements

## Best Practices for AIDA

1. **Bash 3.2 Compatible**: Always test on macOS default shell
2. **Cross-Platform**: Test on both macOS and Linux
3. **Error Handling**: Use `set -euo pipefail` and clear error messages
4. **Path Safety**: Always quote paths and handle spaces
5. **Shellcheck Clean**: Zero warnings required

---

**Last Updated**: 2025-10-09
