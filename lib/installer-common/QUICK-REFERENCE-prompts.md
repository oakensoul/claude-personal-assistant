---
title: "prompts.sh Quick Reference Card"
description: "Quick reference for prompts.sh module functions"
category: "reference"
tags: ["installer", "prompts", "quick-reference"]
last_updated: "2025-10-18"
status: "published"
audience: "developers"
---

# prompts.sh Quick Reference Card

One-page reference for the prompts.sh module functions.

## Setup

```bash
source "${INSTALLER_COMMON}/colors.sh"
source "${INSTALLER_COMMON}/logging.sh"
source "${INSTALLER_COMMON}/prompts.sh"
```

## Functions

### prompt_yes_no

Yes/No confirmation prompt.

```bash
# Signature
prompt_yes_no <question> [default_y_or_n]

# Returns: 0=yes, 1=no, 2=invalid_default

# Examples
if prompt_yes_no "Continue?" "y"; then
    echo "Continuing..."
fi

if ! prompt_yes_no "Install?" "n"; then
    exit 0
fi
```

### prompt_input

Text input with optional regex validation.

```bash
# Signature
prompt_input <question> [default] [regex] [error_msg]

# Returns: 0=valid, 1=max_retries_exceeded
# Output: Echoes validated input to stdout

# Examples
name=$(prompt_input "Enter name:" "user")
email=$(prompt_input "Email:" "" "^[^@]+@[^@]+\.[^@]+$" "Invalid email")
version=$(prompt_input "Version:" "1.0.0" "^[0-9]+\.[0-9]+\.[0-9]+$" "Format: X.Y.Z")
```

### prompt_select

Selection from numbered list.

```bash
# Signature
prompt_select <question> <option1> <option2> [option3...]

# Returns: 0=valid, 1=insufficient_options, 2=max_retries_exceeded
# Output: Echoes selected option to stdout

# Examples
options=("dev" "staging" "prod")
env=$(prompt_select "Select environment:" "${options[@]}")

personalities=("jarvis" "alfred" "friday")
choice=$(prompt_select "Choose personality:" "${personalities[@]}")
```

### confirm_action

Destructive action confirmation (requires typing 'yes').

```bash
# Signature
confirm_action <action_description> [warning_msg]

# Returns: 0=confirmed, 1=declined

# Examples
if confirm_action "Delete all files" "Cannot be undone"; then
    rm -rf ~/.aida/*
fi

if ! confirm_action "Reset database"; then
    exit 0
fi
```

### prompt_input_validated

Advanced input with custom validation function.

```bash
# Signature
prompt_input_validated <question> [default] [validation_func] [error_msg]

# Returns: 0=valid, 1=max_retries, 2=function_not_defined
# Output: Echoes validated input to stdout

# Examples
validate_port() {
    local port="$1"
    [[ "$port" =~ ^[0-9]+$ ]] && [[ $port -ge 1024 && $port -le 65535 ]]
}
port=$(prompt_input_validated "Port:" "8080" "validate_port" "Port must be 1024-65535")

validate_file() {
    [[ -f "$1" ]]
}
config=$(prompt_input_validated "Config file:" "" "validate_file" "File not found")
```

### prompt_info

Informational message with optional wait.

```bash
# Signature
prompt_info <message> [wait_true_or_false]

# Returns: 0 (always)

# Examples
prompt_info "Installation starting..." "false"
prompt_info "Please review the settings above" "true"
```

## Common Patterns

### Required Input

```bash
name=$(prompt_input "Enter name:" "" "^.+$" "Name required") || exit 1
```

### Optional Input with Default

```bash
port=$(prompt_input "Port:" "8080")
```

### Email Validation

```bash
email=$(prompt_input "Email:" "" "^[^@]+@[^@]+\.[^@]+$" "Invalid email")
```

### Number Validation

```bash
age=$(prompt_input "Age:" "" "^[0-9]+$" "Must be a number")
```

### Lowercase Alphanumeric

```bash
name=$(prompt_input "Name:" "" "^[a-z][a-z0-9-]*$" "Lowercase, start with letter")
```

### URL Validation

```bash
url=$(prompt_input "URL:" "" "^https?://.*$" "Must start with http:// or https://")
```

### File Exists

```bash
validate_exists() { [[ -f "$1" ]]; }
file=$(prompt_input_validated "File:" "" "validate_exists" "File not found")
```

### Directory is Writable

```bash
validate_writable() { [[ -d "$1" && -w "$1" ]]; }
dir=$(prompt_input_validated "Directory:" "" "validate_writable" "Not writable")
```

### Confirmation Before Destructive Action

```bash
if [[ -d "$INSTALL_DIR" ]]; then
    if ! confirm_action "Overwrite $INSTALL_DIR" "Backup will be created"; then
        exit 0
    fi
fi
```

## Error Handling

All functions return exit codes - check them:

```bash
# Stop on error
name=$(prompt_input "Name:" "") || {
    print_message "error" "Failed to get name"
    exit 1
}

# Continue on error
if ! result=$(prompt_input "Optional:" ""); then
    print_message "warning" "Using default"
    result="default"
fi

# With custom error handling
if ! choice=$(prompt_select "Choose:" "${opts[@]}"); then
    case $? in
        1) print_message "error" "Not enough options" ;;
        2) print_message "error" "Too many retries" ;;
    esac
    exit 1
fi
```

## Return Codes

| Function | 0 | 1 | 2 |
|----------|---|---|---|
| prompt_yes_no | Yes | No | Invalid default |
| prompt_input | Valid | Max retries | - |
| prompt_select | Valid | Insufficient options | Max retries |
| confirm_action | Confirmed | Declined | - |
| prompt_input_validated | Valid | Max retries | Func not defined |
| prompt_info | Always | - | - |

## Tips

- Always capture output: `result=$(prompt_input ...)`
- Check return codes: `... || exit 1`
- Use defaults for optional values
- Prefer regex for simple validation
- Use custom functions for complex validation
- Max retries is 5 attempts (hardcoded)

## Full Documentation

See `/Users/rob/Develop/oakensoul/claude-personal-assistant/lib/installer-common/README-prompts.md`
