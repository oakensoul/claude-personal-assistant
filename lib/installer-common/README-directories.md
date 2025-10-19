---
title: "directories.sh Module Documentation"
description: "Directory creation, symlink management, and backup operations for AIDA installer"
category: "installer-common"
tags: ["installer", "directories", "symlinks", "namespace-isolation"]
last_updated: "2025-10-18"
version: "1.0"
---

# directories.sh Module

Directory creation, symlink management, and backup operations for the AIDA installer-common library.

## Overview

The `directories.sh` module provides filesystem operations for AIDA installations with emphasis on:

- **Namespace isolation** - Protects user content from framework updates (ADR-013)
- **Idempotency** - Safe to call functions multiple times
- **Cross-platform compatibility** - Works on macOS (BSD) and Linux (GNU)
- **Data safety** - Automatic backups before destructive operations
- **Clear error messages** - Actionable guidance for recovery

## Dependencies

This module requires the following to be sourced first:

```bash
source "${INSTALLER_COMMON}/colors.sh"
source "${INSTALLER_COMMON}/logging.sh"
source "${INSTALLER_COMMON}/validation.sh"
source "${INSTALLER_COMMON}/directories.sh"
```

## Functions

### Core Directory Operations

#### create_aida_dir

Creates `~/.aida/` as a symlink to the repository directory.

**Signature:**

```bash
create_aida_dir <repo_dir> <aida_dir>
```

**Parameters:**

- `repo_dir` - Repository directory path (must exist)
- `aida_dir` - AIDA directory path (e.g., `~/.aida`)

**Returns:**

- `0` - Success (symlink created or already correct)
- `1` - Failure (repo doesn't exist, permissions issue, etc.)

**Behavior:**

- If `aida_dir` doesn't exist → creates symlink
- If `aida_dir` is symlink to correct target → does nothing (idempotent)
- If `aida_dir` is symlink to wrong target → backs up and recreates
- If `aida_dir` exists but isn't symlink → backs up and creates symlink

**Example:**

```bash
create_aida_dir /path/to/claude-personal-assistant ~/.aida
# Creates: ~/.aida -> /path/to/claude-personal-assistant
```

#### create_claude_dirs

Creates the `~/.claude/` directory structure with all required subdirectories.

**Signature:**

```bash
create_claude_dirs <claude_dir>
```

**Parameters:**

- `claude_dir` - Claude directory path (e.g., `~/.claude`)

**Returns:**

- `0` - Success (all directories created)
- `1` - Failure

**Creates:**

```text
~/.claude/
├── commands/
├── agents/
├── skills/
├── config/
├── knowledge/
├── memory/
└── memory/history/
```

**Example:**

```bash
create_claude_dirs ~/.claude
# Creates all 8 directories with permissions 755
```

#### create_namespace_dirs

Creates namespace subdirectories (`.aida/` or `.aida-deprecated/`) in commands, agents, and skills directories.

**Signature:**

```bash
create_namespace_dirs <claude_dir> <namespace>
```

**Parameters:**

- `claude_dir` - Claude directory path (e.g., `~/.claude`)
- `namespace` - Namespace name (`.aida` or `.aida-deprecated`)

**Returns:**

- `0` - Success (all namespace directories created)
- `1` - Failure

**Creates:**

```text
~/.claude/
├── commands/.aida/
├── agents/.aida/
└── skills/.aida/
```

**Example:**

```bash
# Create framework namespace
create_namespace_dirs ~/.claude .aida

# Create deprecated namespace
create_namespace_dirs ~/.claude .aida-deprecated
```

### Symlink Operations

#### create_symlink

Creates a symlink with idempotent behavior and automatic correction of broken links.

**Signature:**

```bash
create_symlink <target> <link_name>
```

**Parameters:**

- `target` - Target path (must exist)
- `link_name` - Symlink path to create

**Returns:**

- `0` - Success (symlink created or already correct)
- `1` - Failure (target doesn't exist, permissions issue, etc.)

**Behavior:**

- If symlink exists and correct → does nothing (idempotent)
- If symlink exists but wrong target → removes and recreates
- If path exists but not symlink → returns error
- If broken symlink → removes and recreates

**Example:**

```bash
create_symlink /path/to/target /path/to/link
# Creates: /path/to/link -> /path/to/target

# Calling again is safe (idempotent)
create_symlink /path/to/target /path/to/link
# Output: "Symlink already correct: /path/to/link -> /path/to/target"
```

#### validate_symlink

Validates that a symlink exists and points to the expected target.

**Signature:**

```bash
validate_symlink <symlink> <expected_target>
```

**Parameters:**

- `symlink` - Symlink path to validate
- `expected_target` - Expected target path

**Returns:**

- `0` - Valid (symlink exists and points to expected target)
- `1` - Invalid (broken, missing, or wrong target)

**Example:**

```bash
if validate_symlink ~/.aida /path/to/repo; then
    echo "Symlink is correct"
else
    echo "Symlink is broken or points to wrong target"
fi
```

#### get_symlink_target

Reads the target of a symlink using platform-specific commands.

**Signature:**

```bash
target=$(get_symlink_target <symlink>)
```

**Parameters:**

- `symlink` - Symlink path to read

**Returns:**

- `0` - Success (target path written to stdout)
- `1` - Failure (not a symlink, doesn't exist)

**Platform Compatibility:**

- **macOS (BSD)**: Uses `readlink` without `-f` flag
- **Linux (GNU)**: Uses `readlink -f` for canonical path
- **WSL**: Works in WSL filesystem

**Example:**

```bash
target=$(get_symlink_target ~/.aida)
echo "AIDA directory points to: $target"
```

### Backup Operations

#### backup_existing

Creates a timestamped backup of a directory or file.

**Signature:**

```bash
backup_existing <target>
```

**Parameters:**

- `target` - Path to backup (directory or file)

**Returns:**

- `0` - Success (backup created or target doesn't exist)
- `1` - Failure (backup failed)

**Backup Format:**

```text
Original: /path/to/file.txt
Backup:   /path/to/file.txt.backup.20251018-143022
```

**Behavior:**

- If target doesn't exist → does nothing (idempotent)
- If target is directory → uses `cp -a` (preserves permissions/timestamps)
- If target is file → uses `cp -p` (preserves permissions/timestamps)
- Timestamp format: `YYYYMMDD-HHMMSS`

**Example:**

```bash
# Backup before destructive operation
backup_existing ~/.claude/commands
# Creates: ~/.claude/commands.backup.20251018-143022

# Backup file
backup_existing ~/CLAUDE.md
# Creates: ~/CLAUDE.md.backup.20251018-143022
```

## Namespace Isolation Pattern

The module implements the namespace isolation pattern from ADR-013 to protect user content from framework updates.

### Architecture

```text
~/.claude/
├── commands/
│   ├── .aida/                    # Framework content (replaceable)
│   │   ├── start-work/
│   │   ├── implement/
│   │   └── open-pr/
│   ├── .aida-deprecated/         # Deprecated content (optional)
│   │   └── create-issue/
│   └── my-custom-workflow.md     # User content (protected)
│
├── agents/
│   ├── .aida/                    # Framework content (replaceable)
│   ├── .aida-deprecated/         # Deprecated content (optional)
│   └── my-custom-agent.md        # User content (protected)
│
└── skills/
    ├── .aida/                    # Framework content (replaceable)
    ├── .aida-deprecated/         # Deprecated content (optional)
    └── (no user skills yet)
```

### Safety Guarantees

**Framework updates can NEVER touch user content:**

```bash
# Safe operations (installer can do these)
rm -rf ~/.claude/commands/.aida/           # Nuke framework
rm -rf ~/.claude/commands/.aida-deprecated/ # Nuke deprecated

# User content untouched
ls ~/.claude/commands/my-workflow.md  # Still exists!
```

## Idempotency

All functions in this module are **idempotent** - safe to call multiple times:

```bash
# First call creates directories
create_claude_dirs ~/.claude
# Success: Created 8 directories

# Second call does nothing
create_claude_dirs ~/.claude
# Success: Directories already exist

# Third call still safe
create_claude_dirs ~/.claude
# Success: Directories already exist
```

## Cross-Platform Compatibility

### macOS vs Linux

The module handles platform differences transparently:

**Symlink Reading:**

```bash
# macOS (BSD)
readlink "$symlink"  # No -f flag

# Linux (GNU)
readlink -f "$symlink"  # Canonical path with -f
```

**File Permissions:**

```bash
# macOS (BSD stat)
stat -f "%Lp" "$file"

# Linux (GNU stat)
stat -c "%a" "$file"
```

**Testing:**

The module is tested on both macOS and Linux to ensure compatibility.

## Error Handling

All functions provide clear error messages with recovery guidance:

```bash
# Example: Target doesn't exist
create_symlink /nonexistent/path ~/.aida
# Error: Symlink target does not exist: /nonexistent/path

# Example: Wrong target
validate_symlink ~/.aida /wrong/path
# Error: Symlink points to wrong target
#   Expected: /wrong/path
#   Actual:   /correct/path

# Example: Not a symlink
create_symlink /target /existing/file
# Error: Path exists but is not a symlink: /existing/file
#   Cannot create symlink at existing non-symlink path
#   Remove or rename the existing path first
```

## Testing

Run the validation script to test all functions:

```bash
# Run all tests
./validate-directories-module.sh

# Verbose output
./validate-directories-module.sh --verbose
```

**Test Coverage:**

1. Module sources successfully
2. All functions exported
3. create_aida_dir creates symlink correctly
4. create_claude_dirs creates all directories
5. create_namespace_dirs creates .aida subdirectories
6. backup_existing creates timestamped backup
7. create_symlink is idempotent
8. create_symlink detects broken links
9. validate_symlink catches wrong targets
10. Cross-platform symlink reading works

## Examples

See `EXAMPLE-directories-usage.sh` for complete usage examples.

### Basic Installation Flow

```bash
#!/usr/bin/env bash
set -euo pipefail

# Source dependencies
INSTALLER_COMMON="${SCRIPT_DIR}/lib/installer-common"
source "${INSTALLER_COMMON}/colors.sh"
source "${INSTALLER_COMMON}/logging.sh"
source "${INSTALLER_COMMON}/validation.sh"
source "${INSTALLER_COMMON}/directories.sh"

# Configuration
REPO_DIR="/path/to/claude-personal-assistant"
AIDA_DIR="${HOME}/.aida"
CLAUDE_DIR="${HOME}/.claude"

# Create AIDA directory (always symlink)
create_aida_dir "$REPO_DIR" "$AIDA_DIR"

# Create Claude configuration structure
create_claude_dirs "$CLAUDE_DIR"

# Create framework namespace
create_namespace_dirs "$CLAUDE_DIR" ".aida"

# Optionally create deprecated namespace
create_namespace_dirs "$CLAUDE_DIR" ".aida-deprecated"
```

### Safe Upgrade Flow

```bash
#!/usr/bin/env bash
set -euo pipefail

# Backup user content before upgrade (optional but recommended)
backup_existing ~/.claude/commands/my-workflow.md

# Update AIDA directory (idempotent)
create_aida_dir /path/to/updated/repo ~/.aida

# Recreate framework namespace (safe - user content protected)
rm -rf ~/.claude/commands/.aida/
create_namespace_dirs ~/.claude .aida

# User content preserved
ls ~/.claude/commands/my-workflow.md  # Still there!
```

## Architecture References

- **ADR-013**: Namespace Isolation for User Content Protection
- **ADR-011**: Modular Installer Architecture
- **Issue #53**: Modular Installer Refactoring (Task 004)

## Version History

**v1.0** - 2025-10-18

- Initial implementation
- All 7 core functions
- Cross-platform compatibility (macOS/Linux)
- Full test coverage (10 tests)
- Namespace isolation support
- Idempotent operations
- Automatic backups

## License

AGPL-3.0 - See LICENSE file for details

## Author

oakensoul

## Repository

<https://github.com/oakensoul/claude-personal-assistant>
