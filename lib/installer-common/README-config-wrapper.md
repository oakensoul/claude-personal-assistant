---
title: "Config Wrapper Module - README"
description: "Thin wrapper around aida-config-helper.sh for convenient use by install.sh"
category: "installer-library"
tags: ["config", "wrapper", "installer", "modular-refactoring"]
last_updated: "2025-10-18"
status: "published"
audience: "developers"
---

# Config Wrapper Module (config.sh)

## Overview

The config wrapper module provides a simple, focused API for `install.sh` to interact with the universal config aggregator (`aida-config-helper.sh`). It's a thin wrapper that handles common configuration tasks without duplicating the complex merging logic.

**Design Philosophy**: Keep it simple. The heavy lifting is done by `aida-config-helper.sh`. This module just makes it convenient to use from install scripts.

## Usage

### Basic Setup

```bash
#!/usr/bin/env bash
set -euo pipefail

# Source dependencies
INSTALLER_COMMON="${SCRIPT_DIR}/lib/installer-common"
source "${INSTALLER_COMMON}/colors.sh"
source "${INSTALLER_COMMON}/logging.sh"
source "${INSTALLER_COMMON}/validation.sh"
source "${INSTALLER_COMMON}/config.sh"

# Now use config functions
```

## API Reference

### get_config()

Get the full merged configuration as JSON.

**Returns**: Full merged JSON config to stdout

**Example**:

```bash
config=$(get_config)
echo "$config" | jq '.paths.aida_home'
```

### get_config_value(key)

Get a specific configuration value by key path.

**Arguments**:

- `$1` - Key path (e.g., "paths.aida_home")

**Returns**: Value to stdout

**Example**:

```bash
aida_home=$(get_config_value "paths.aida_home")
echo "AIDA home: ${aida_home}"
```

### write_user_config(mode, aida_dir, claude_dir, version, name, personality)

Create or update the user configuration file at `~/.claude/aida-config.json`.

**Arguments**:

1. `$1` - Install mode ("normal" or "dev")
2. `$2` - AIDA directory path (e.g., "/Users/rob/.aida")
3. `$3` - Claude config directory path (e.g., "/Users/rob/.claude")
4. `$4` - AIDA version (e.g., "0.2.0")
5. `$5` - Assistant name (e.g., "jarvis")
6. `$6` - Personality (e.g., "JARVIS")

**Returns**: 0 on success, 1 on error

**Example**:

```bash
write_user_config \
    "dev" \
    "/Users/rob/.aida" \
    "/Users/rob/.claude" \
    "0.2.0" \
    "jarvis" \
    "JARVIS"
```

**Generated Config Structure**:

```json
{
  "version": "0.2.0",
  "install_mode": "dev",
  "installed_at": "2025-10-18T20:00:00Z",
  "updated_at": "2025-10-18T20:00:00Z",
  "paths": {
    "aida_home": "/Users/rob/.aida",
    "claude_config_dir": "/Users/rob/.claude",
    "home": "/Users/rob"
  },
  "user": {
    "assistant_name": "jarvis",
    "personality": "JARVIS"
  },
  "deprecation": {
    "include_deprecated": false
  }
}
```

### validate_config()

Validate that the merged configuration has all required keys.

**Returns**: 0 if valid, 1 if validation fails

**Example**:

```bash
if validate_config; then
    echo "Configuration is valid"
else
    echo "Configuration validation failed"
    exit 1
fi
```

### config_exists(path)

Check if a configuration file exists.

**Arguments**:

- `$1` - Path to config file

**Returns**: 0 if exists, 1 if not

**Example**:

```bash
if config_exists "${HOME}/.claude/aida-config.json"; then
    echo "User config exists"
else
    echo "No user config found"
fi
```

## Integration with install.sh

Typical install.sh usage pattern:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Source installer-common modules
source "${INSTALLER_COMMON}/config.sh"

# Get version
VERSION=$(validate_version_file "VERSION") || exit 1

# Prompt for user preferences
ASSISTANT_NAME=$(prompt_for_assistant_name)
PERSONALITY=$(prompt_for_personality)

# Determine install mode
DEV_MODE=false
if [[ "${1:-}" == "--dev" ]]; then
    DEV_MODE=true
fi

# Set paths
AIDA_DIR="${HOME}/.aida"
CLAUDE_DIR="${HOME}/.claude"

# ... installation logic ...

# Write user configuration
INSTALL_MODE="normal"
[[ "$DEV_MODE" == true ]] && INSTALL_MODE="dev"

write_user_config \
    "$INSTALL_MODE" \
    "$AIDA_DIR" \
    "$CLAUDE_DIR" \
    "$VERSION" \
    "$ASSISTANT_NAME" \
    "$PERSONALITY"

# Validate configuration
validate_config || {
    print_message "error" "Configuration validation failed"
    exit 1
}

print_message "success" "Installation complete!"
```

## Error Handling

The module provides clear error messages for common failures:

### Missing Config Helper

```bash
get_config
# Output:
# ✗ Config helper not found: /path/to/aida-config-helper.sh
```

### Not Executable

```bash
get_config
# Output:
# ✗ Config helper not executable: /path/to/aida-config-helper.sh
# ℹ Fix with: chmod +x /path/to/aida-config-helper.sh
```

### Invalid Key

```bash
get_config_value "invalid.key"
# Output:
# ✗ Config key not found: invalid.key
# ✗ Failed to get config value for key: invalid.key
```

### Invalid Install Mode

```bash
write_user_config "invalid" ...
# Output:
# ✗ Invalid install mode: invalid
# ℹ Valid modes: normal, dev
```

## Testing

Run the comprehensive test suite:

```bash
./lib/installer-common/test-config-wrapper.sh
```

**Test Coverage**:

1. Module sources successfully
2. get_config returns valid JSON
3. get_config_value retrieves correct values
4. write_user_config creates valid JSON file
5. validate_config detects valid config
6. config_exists works correctly
7. Error handling for missing config helper
8. Error handling for invalid keys

All tests should pass with output like:

```text
TEST SUMMARY
==========================================
Tests run:    8
Tests passed: 11
Tests failed: 0

✓ All tests passed!
```

## Dependencies

- `../aida-config-helper.sh` - Universal config aggregator (required)
- `logging.sh` - Logging utilities (must be sourced first)
- `validation.sh` - Validation utilities (must be sourced first)
- `jq` - JSON processor (required, system dependency)

## Design Notes

### Why a Wrapper?

The universal config aggregator (`aida-config-helper.sh`) is powerful but complex. It handles:

- 7 configuration sources
- Deep merging with priority
- Session caching with checksums
- Platform-specific file operations

This wrapper provides:

- Simple function API instead of CLI flags
- Convenience functions for common tasks
- Integration with installer-common logging
- Error handling tailored for install.sh

### Single Responsibility

This module does **one thing**: make `aida-config-helper.sh` easy to use from install scripts.

It does **not**:

- Duplicate merging logic (uses config helper)
- Parse JSON manually (uses jq and config helper)
- Implement complex validation (delegates to config helper)

### Thin by Design

The entire module is ~220 lines including comments and error handling. It's intentionally minimal to avoid becoming a maintenance burden.

## File Structure

```text
lib/
├── aida-config-helper.sh       # Universal config aggregator
└── installer-common/
    ├── config.sh               # THIS MODULE - thin wrapper
    ├── test-config-wrapper.sh  # Comprehensive tests
    └── README-config-wrapper.md # This documentation
```

## Part of Modular Installer Refactoring

This module is **Task 003** of the modular installer refactoring (Issue #53):

- **Task 001**: Summary module (✓ completed)
- **Task 002**: Config aggregator (✓ completed)
- **Task 003**: Config wrapper (✓ completed)
- **Task 004**: Prompts refactoring (in progress)
- **Task 005**: Directories refactoring (planned)

See [lib/installer-common/README-config-aggregator.md](README-config-aggregator.md) for details on the underlying config aggregator.

## Version

Part of: AIDA installer-common library v1.0

## Author

oakensoul

## License

AGPL-3.0

## Repository

<https://github.com/oakensoul/claude-personal-assistant>
