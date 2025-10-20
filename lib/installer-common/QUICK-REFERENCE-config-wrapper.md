---
title: "Config Wrapper - Quick Reference"
description: "Fast reference for config.sh wrapper module functions"
category: "quick-reference"
tags: ["config", "wrapper", "reference", "installer"]
last_updated: "2025-10-18"
status: "published"
audience: "developers"
---

# Config Wrapper Module - Quick Reference

## Setup

```bash
source "${INSTALLER_COMMON}/colors.sh"
source "${INSTALLER_COMMON}/logging.sh"
source "${INSTALLER_COMMON}/validation.sh"
source "${INSTALLER_COMMON}/config.sh"
```

## Functions

### get_config()

Get full merged configuration as JSON.

```bash
config=$(get_config)
echo "$config" | jq '.paths.aida_home'
```

### get_config_value(key)

Get specific config value.

```bash
aida_home=$(get_config_value "paths.aida_home")
claude_dir=$(get_config_value "paths.claude_config_dir")
assistant=$(get_config_value "user.assistant_name")
```

**Common Keys**:

- `paths.aida_home` - AIDA installation directory
- `paths.claude_config_dir` - Claude config directory
- `paths.home` - User home directory
- `user.assistant_name` - Assistant name
- `user.personality` - Selected personality

### write_user_config(mode, aida_dir, claude_dir, version, name, personality)

Create user configuration file.

```bash
write_user_config \
    "dev" \
    "/Users/rob/.aida" \
    "/Users/rob/.claude" \
    "0.2.0" \
    "jarvis" \
    "JARVIS"
```

**Creates**: `~/.claude/aida-config.json`

### validate_config()

Validate configuration has required keys.

```bash
if validate_config; then
    echo "Config is valid"
else
    echo "Config validation failed"
    exit 1
fi
```

### config_exists(path)

Check if config file exists.

```bash
if config_exists "${HOME}/.claude/aida-config.json"; then
    echo "User config exists"
fi
```

## Common Patterns

### Installation Script

```bash
# Get version
VERSION="0.2.0"

# Get user preferences
ASSISTANT_NAME="jarvis"
PERSONALITY="JARVIS"

# Set install mode
INSTALL_MODE="normal"
[[ "${1:-}" == "--dev" ]] && INSTALL_MODE="dev"

# Write config
write_user_config \
    "$INSTALL_MODE" \
    "${HOME}/.aida" \
    "${HOME}/.claude" \
    "$VERSION" \
    "$ASSISTANT_NAME" \
    "$PERSONALITY"

# Validate
validate_config || exit 1
```

### Read Config Values

```bash
# Get paths
AIDA_HOME=$(get_config_value "paths.aida_home")
CLAUDE_DIR=$(get_config_value "paths.claude_config_dir")

# Get user settings
ASSISTANT=$(get_config_value "user.assistant_name")
PERSONALITY=$(get_config_value "user.personality")

# Use in script
echo "AIDA home: ${AIDA_HOME}"
echo "Assistant: ${ASSISTANT} (${PERSONALITY})"
```

### Check for Existing Config

```bash
CONFIG_FILE="${HOME}/.claude/aida-config.json"

if config_exists "$CONFIG_FILE"; then
    # Read existing config
    ASSISTANT=$(get_config_value "user.assistant_name")
    echo "Found existing assistant: ${ASSISTANT}"
else
    # Create new config
    echo "No config found, creating new one..."
    write_user_config ...
fi
```

## Error Handling

All functions return:

- `0` on success
- `1` on error

Errors print via `print_message "error"`.

```bash
if ! get_config_value "paths.aida_home"; then
    echo "Failed to get config"
    exit 1
fi
```

## Testing

```bash
./lib/installer-common/test-config-wrapper.sh
```

## Full Documentation

See [README-config-wrapper.md](README-config-wrapper.md) for complete documentation.
