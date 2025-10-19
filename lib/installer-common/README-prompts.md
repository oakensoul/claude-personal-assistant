---
title: "prompts.sh Module Documentation"
description: "User interaction and prompt utilities for installer-common library"
category: "library"
tags: ["installer", "prompts", "user-input", "validation"]
last_updated: "2025-10-18"
status: "published"
audience: "developers"
---

# prompts.sh Module

User interaction and prompt utilities for the AIDA installer-common library.

## Overview

The `prompts.sh` module provides reusable, production-ready functions for user interaction including:

- Yes/No confirmation prompts
- Text input with validation (regex or custom functions)
- Selection from numbered lists
- Destructive action confirmations
- Informational messages with optional wait

## Design Principles

- **No global dependencies**: All functions accept parameters
- **Consistent API**: Predictable function signatures and return values
- **Comprehensive validation**: Input validation with helpful error messages
- **Retry limits**: Prevents infinite loops with max retry counts
- **Clear output**: Uses colors.sh and logging.sh for consistent messaging

## Dependencies

Required utilities (must be sourced before prompts.sh):

```bash
source "${INSTALLER_COMMON}/colors.sh"
source "${INSTALLER_COMMON}/logging.sh"
source "${INSTALLER_COMMON}/prompts.sh"
```

## Public API

### prompt_yes_no

Prompt for yes/no confirmation with default value support.

**Signature:**

```bash
prompt_yes_no <question> [default]
```

**Arguments:**

- `$1` - Question to ask (required)
- `$2` - Default answer: 'y' or 'n' (optional, default: 'n')

**Returns:**

- `0` - User answered yes (y/Y/yes/Yes)
- `1` - User answered no (n/N/no/No)
- `2` - Invalid default value provided

**Example:**

```bash
if prompt_yes_no "Continue with installation?" "y"; then
    echo "User confirmed"
else
    echo "User declined"
    exit 0
fi
```

### prompt_input

Prompt for text input with optional regex validation.

**Signature:**

```bash
prompt_input <question> [default] [validation_regex] [validation_error]
```

**Arguments:**

- `$1` - Question/prompt text (required)
- `$2` - Default value (optional, empty string if not provided)
- `$3` - Validation regex pattern (optional, no validation if not provided)
- `$4` - Validation error message (optional, generic message if not provided)

**Returns:**

- `0` - Valid input received (echoes input to stdout)
- `1` - Validation failed and max retries exceeded

**Example:**

```bash
# Simple input
name=$(prompt_input "Enter your name:" "DefaultUser")

# Input with regex validation
email=$(prompt_input "Enter email:" "" "^[^@]+@[^@]+\.[^@]+$" "Invalid email format")

# Input with validation and default
version=$(prompt_input "Enter version:" "1.0.0" "^[0-9]+\.[0-9]+\.[0-9]+$" "Version must be in format X.Y.Z")
```

### prompt_select

Prompt selection from numbered list of options.

**Signature:**

```bash
prompt_select <question> <option1> <option2> [option3...]
```

**Arguments:**

- `$1` - Question/prompt text (required)
- `$2+` - List of options (minimum 2 required)

**Returns:**

- `0` - Valid selection made (echoes selected option to stdout)
- `1` - Insufficient options provided
- `2` - Max retries exceeded

**Example:**

```bash
personalities=("jarvis" "alfred" "friday" "sage" "drill-sergeant")
choice=$(prompt_select "Select personality:" "${personalities[@]}")
echo "You selected: $choice"

# Direct array passing
options=("Development" "Staging" "Production")
env=$(prompt_select "Select environment:" "${options[@]}")
```

### confirm_action

Confirm potentially destructive action (requires typing 'yes').

**Signature:**

```bash
confirm_action <action_description> [warning_message]
```

**Arguments:**

- `$1` - Action description (required)
- `$2` - Warning message (optional)

**Returns:**

- `0` - User confirmed (typed 'yes' exactly)
- `1` - User declined (typed anything else)

**Example:**

```bash
if confirm_action "Delete all files in ~/.aida" "This action cannot be undone"; then
    rm -rf ~/.aida/*
    echo "Files deleted"
else
    echo "Operation cancelled"
    exit 0
fi
```

### prompt_input_validated

Advanced input prompt with custom validation function.

**Signature:**

```bash
prompt_input_validated <question> [default] [validation_func] [validation_error]
```

**Arguments:**

- `$1` - Question/prompt text (required)
- `$2` - Default value (optional, empty string if not provided)
- `$3` - Name of validation function (optional, no validation if not provided)
- `$4` - Validation error message (optional, generic message if not provided)

**Returns:**

- `0` - Valid input received (echoes input to stdout)
- `1` - Validation failed and max retries exceeded
- `2` - Validation function not defined

**Example:**

```bash
# Define custom validation function
validate_port() {
    local port="$1"
    [[ "$port" =~ ^[0-9]+$ ]] && [[ $port -ge 1024 && $port -le 65535 ]]
}

# Use custom validation
port=$(prompt_input_validated "Enter port number:" "8080" "validate_port" "Port must be 1024-65535")
echo "Using port: $port"
```

### prompt_info

Display informational message with optional wait for user acknowledgment.

**Signature:**

```bash
prompt_info <message> [wait_for_user]
```

**Arguments:**

- `$1` - Message to display (required)
- `$2` - Wait for user: 'true' or 'false' (optional, default: 'false')

**Returns:**

- `0` - Always

**Example:**

```bash
# Display info without waiting
prompt_info "Installation will begin..." "false"

# Display info and wait for Enter
prompt_info "Please review the configuration above" "true"
```

## Validation Best Practices

### Regex Validation

When using `prompt_input` with regex validation:

```bash
# Email validation
email=$(prompt_input "Email:" "" "^[^@]+@[^@]+\.[^@]+$" "Invalid email")

# Lowercase alphanumeric with hyphens
name=$(prompt_input "Name:" "" "^[a-z][a-z0-9-]*$" "Must be lowercase, start with letter")

# Version number (semver)
version=$(prompt_input "Version:" "" "^[0-9]+\.[0-9]+\.[0-9]+$" "Format: X.Y.Z")

# URL validation (basic)
url=$(prompt_input "URL:" "" "^https?://[^/]+.*$" "Must start with http:// or https://")
```

### Custom Validation Functions

For complex validation logic, use `prompt_input_validated`:

```bash
# Validate file exists
validate_file_exists() {
    local file="$1"
    [[ -f "$file" ]]
}

config_file=$(prompt_input_validated "Config file path:" "" "validate_file_exists" "File not found")

# Validate directory is writable
validate_writable_dir() {
    local dir="$1"
    [[ -d "$dir" ]] && [[ -w "$dir" ]]
}

install_dir=$(prompt_input_validated "Install directory:" "/opt/app" "validate_writable_dir" "Directory must exist and be writable")

# Validate against list of allowed values
validate_environment() {
    local env="$1"
    local allowed=("dev" "staging" "production")
    for allowed_env in "${allowed[@]}"; do
        if [[ "$env" == "$allowed_env" ]]; then
            return 0
        fi
    done
    return 1
}

environment=$(prompt_input_validated "Environment:" "dev" "validate_environment" "Must be: dev, staging, or production")
```

## Error Handling

All prompt functions implement:

- **Retry limits**: Max 5 retries before returning error
- **Clear error messages**: Uses logging.sh for consistent formatting
- **Graceful degradation**: Returns error codes, doesn't exit
- **Input validation**: Prevents empty input, validates ranges

**Example error handling:**

```bash
if ! name=$(prompt_input "Enter name:" "" "^[a-z]+$" "Lowercase letters only"); then
    print_message "error" "Failed to get valid name after maximum retries"
    exit 1
fi

if ! choice=$(prompt_select "Select option:" "${options[@]}"); then
    print_message "error" "Failed to get valid selection"
    exit 1
fi
```

## Testing

### Manual Testing

A manual test script is provided:

```bash
./lib/installer-common/test-prompts.sh
```

This script exercises all public functions with interactive prompts.

### Automated Testing (Future)

Unit tests will be added in `tests/unit/prompts.bats` when bats test framework is configured.

## Integration Examples

### From install.sh

Example of how prompts.sh can be used in install.sh:

```bash
# Source prompts module
source "${INSTALLER_COMMON}/prompts.sh"

# Prompt for assistant name with validation
prompt_assistant_name() {
    print_message "info" "Configure your assistant name"
    echo ""
    echo "Requirements: lowercase, no spaces, 3-20 characters"
    echo ""

    local name
    name=$(prompt_input "Enter assistant name" "" "^[a-z][a-z0-9-]{2,19}$" "Name must be 3-20 chars, lowercase, start with letter") || {
        print_message "error" "Failed to get valid assistant name"
        return 1
    }

    ASSISTANT_NAME="$name"
    print_message "success" "Assistant name set to: ${ASSISTANT_NAME}"
}

# Prompt for personality selection
prompt_personality() {
    local personalities=("jarvis" "alfred" "friday" "sage" "drill-sergeant")
    local choice

    choice=$(prompt_select "Select your assistant personality:" "${personalities[@]}") || {
        print_message "error" "Failed to select personality"
        return 1
    }

    PERSONALITY="$choice"
    print_message "success" "Personality set to: ${PERSONALITY}"
}

# Confirm before overwriting existing installation
if [[ -d "${AIDA_DIR}" ]]; then
    if ! confirm_action "Overwrite existing installation at ${AIDA_DIR}" "Backup will be created"; then
        print_message "info" "Installation cancelled"
        exit 0
    fi
fi
```

## Standards Compliance

- Bash 3.2+ compatible (macOS default)
- Passes shellcheck with zero warnings
- Uses `set -euo pipefail` for strict error handling
- Uses `readonly` for constants
- Comprehensive function documentation
- No hardcoded paths or global dependencies

## Version History

- **v1.0** (2025-10-18) - Initial implementation
  - Core prompt functions
  - Validation support (regex and custom functions)
  - Retry limits and error handling
  - Integration with colors.sh and logging.sh
