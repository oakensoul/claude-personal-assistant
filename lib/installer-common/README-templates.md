---
title: "templates.sh Module Documentation"
description: "Template installation with namespace isolation for AIDA installer"
category: "installer-common"
tags: ["installer", "templates", "namespace-isolation", "dev-mode"]
last_updated: "2025-10-18"
version: "1.0"
---

# templates.sh Module

Template installation with namespace isolation for the AIDA installer-common library.

## Overview

The `templates.sh` module provides template installation operations for AIDA with emphasis on:

- **Namespace isolation** - Installs templates to `.aida/` subdirectories (ADR-013)
- **No variable substitution** - Templates stay pure, use `aida-config-helper.sh` at runtime
- **Folder-based templates** - Templates are directories with README.md, not individual files
- **Dual installation modes** - Normal mode (copy) and dev mode (symlink)
- **User content protection** - Framework templates isolated from user customizations

## Key Architecture Decisions

### ADR-013: Namespace Isolation

Templates install to `.aida/` subdirectories to protect user content:

```text
~/.claude/commands/
├── my-custom-command.md        # User content (preserved)
└── .aida/                      # AIDA framework (replaceable)
    ├── start-work/
    │   └── README.md
    └── open-pr/
        └── README.md
```

### No Variable Substitution

**Old approach (deprecated):**

```markdown
# Bad - variable substitution at install-time
To start work: cd {{PROJECT_ROOT}}
```

**New approach (config aggregator):**

```markdown
# Good - templates stay pure, call config helper at runtime
To start work:

` ``bash
PROJECT_ROOT=$(aida-config-helper.sh --key paths.project_root)
cd "$PROJECT_ROOT"
` ``
```

Templates NO LONGER use `{{VAR}}` patterns. Configuration is resolved at runtime via `aida-config-helper.sh`.

### Folder-Based Templates

Templates must be **folders** containing at minimum a `README.md` file:

```text
templates/commands/
├── start-work/
│   └── README.md           # Required
├── open-pr/
│   ├── README.md           # Required
│   └── pr-template.txt     # Optional additional files
└── cleanup-main/
    └── README.md           # Required
```

## Dependencies

This module requires the following to be sourced first:

```bash
source "${INSTALLER_COMMON}/colors.sh"
source "${INSTALLER_COMMON}/logging.sh"
source "${INSTALLER_COMMON}/validation.sh"
source "${INSTALLER_COMMON}/templates.sh"
```

## Functions

### Core Template Operations

#### install_templates

Main entry point for template installation. Installs templates from source directory to destination within a namespace subdirectory.

**Signature:**

```bash
install_templates <src_dir> <dst_dir> [dev_mode] [namespace]
```

**Parameters:**

- `src_dir` (required) - Source template directory (e.g., `~/.aida/templates/commands`)
- `dst_dir` (required) - Destination base directory (e.g., `~/.claude/commands`)
- `dev_mode` (optional, default: `false`) - Installation mode:
  - `false` - Normal mode: copy templates
  - `true` - Dev mode: symlink templates for live editing
- `namespace` (optional, default: `.aida`) - Namespace subdirectory:
  - `.aida` - Current framework templates
  - `.aida-deprecated` - Deprecated templates (for migration)

**Returns:**

- `0` - All templates installed successfully
- `1` - Installation failed (validation error or filesystem error)

**Example:**

```bash
# Normal mode: copy templates to ~/.claude/commands/.aida/
install_templates \
  ~/.aida/templates/commands \
  ~/.claude/commands \
  false \
  .aida

# Dev mode: symlink templates for live editing
install_templates \
  ~/.aida/templates/commands \
  ~/.claude/commands \
  true \
  .aida
```

**Behavior:**

1. Validates source directory exists
2. Creates namespace directory (e.g., `~/.claude/commands/.aida/`)
3. Iterates through each folder in source directory
4. Validates each template has required structure (README.md)
5. Installs each template based on mode (copy or symlink)
6. Reports installation statistics

**Installation Modes:**

**Normal Mode** (`dev_mode=false`):

- Copies template folders to namespace directory
- Overwrites existing templates with fresh copies
- Converts symlinks to directories (backs up symlink first)
- Safe for production installations

**Dev Mode** (`dev_mode=true`):

- Creates symlinks to template folders in repository
- Enables live editing (changes reflect immediately)
- Backs up existing directories before symlinking
- Intended for AIDA framework development

#### install_template_folder

Installs a single template folder to destination.

**Signature:**

```bash
install_template_folder <src_folder> <dst_folder> <dev_mode>
```

**Parameters:**

- `src_folder` (required) - Source template folder path
- `dst_folder` (required) - Destination folder path
- `dev_mode` (required) - Installation mode (`true` or `false`)

**Returns:**

- `0` - Template installed successfully
- `1` - Installation failed

**Example:**

```bash
install_template_folder \
  ~/.aida/templates/commands/start-work \
  ~/.claude/commands/.aida/start-work \
  false
```

**Behavior:**

1. Validates template structure (must be directory with README.md)
2. Creates parent directory if needed
3. Normal mode: copies folder recursively with `cp -a`
4. Dev mode: creates symlink with `ln -s`
5. Handles existing templates (backup, overwrite, or skip)

#### validate_template_structure

Validates that a template folder has the required structure.

**Signature:**

```bash
validate_template_structure <template_dir>
```

**Parameters:**

- `template_dir` (required) - Template directory path to validate

**Returns:**

- `0` - Valid template structure
- `1` - Invalid structure (not a directory or missing README.md)

**Example:**

```bash
if validate_template_structure ~/.aida/templates/commands/start-work; then
  echo "Valid template"
fi
```

**Validation Rules:**

- Must be a directory (not a file)
- Must contain `README.md` file at root level

### CLAUDE.md Generation

#### generate_claude_md

Generates the main CLAUDE.md entry point file at `~/CLAUDE.md`.

**Signature:**

```bash
generate_claude_md <output_file> <assistant_name> <personality> <version>
```

**Parameters:**

- `output_file` (required) - Output file path (e.g., `~/CLAUDE.md`)
- `assistant_name` (required) - Assistant name (e.g., `JARVIS`)
- `personality` (required) - Personality type (e.g., `professional`)
- `version` (required) - AIDA version (e.g., `0.1.6`)

**Returns:**

- `0` - CLAUDE.md generated successfully
- `1` - Generation failed

**Example:**

```bash
generate_claude_md ~/CLAUDE.md "JARVIS" "professional" "0.1.6"
```

**Generated Content:**

- Frontmatter with metadata (title, assistant_name, personality, date)
- Welcome message with assistant name
- Configuration paths (framework, config, knowledge, memory)
- Quick reference for AIDA commands
- Natural language command examples
- Getting started guide

**File Permissions:**

Sets file to `644` (owner read/write, group/others read-only).

## Template Structure Requirements

### Folder-Based Templates

All templates must be folders (not individual markdown files):

**Valid structure:**

```text
templates/commands/start-work/
├── README.md           # Required - main template content
└── helpers/            # Optional - additional files
    └── workflow.sh
```

**Invalid structure:**

```text
templates/commands/
└── start-work.md       # Invalid - must be folder
```

### Required Files

Each template folder must contain:

- `README.md` - Main template content (slash command definition, agent definition, etc.)

### Optional Files

Templates may contain additional files:

- Helper scripts
- Configuration templates
- Documentation
- Subdirectories with nested content

## Namespace Isolation Pattern

### Directory Structure

Templates install to `.aida/` subdirectories in:

- `~/.claude/commands/.aida/` - Slash command templates
- `~/.claude/agents/.aida/` - Agent definitions
- `~/.claude/skills/.aida/` - Skill definitions

### User Content Protection

User content at root level is preserved:

```text
~/.claude/commands/
├── my-custom-command.md        # User content - PRESERVED
├── team-workflow.md            # User content - PRESERVED
└── .aida/                      # AIDA framework - REPLACEABLE
    ├── start-work/             # Framework template
    ├── open-pr/                # Framework template
    └── cleanup-main/           # Framework template
```

### Upgrade Behavior

When AIDA framework updates:

1. Framework recreates `.aida/` namespace with new templates
2. User content at root level remains untouched
3. User customizations in `.aida/` are replaced (should customize at root)

### Deprecated Templates

During migration, deprecated templates move to `.aida-deprecated/`:

```text
~/.claude/commands/
├── .aida/              # Current templates
└── .aida-deprecated/   # Old templates (for migration reference)
```

## Usage Patterns

### Install Commands in Normal Mode

```bash
install_templates \
  ~/.aida/templates/commands \
  ~/.claude/commands \
  false \
  .aida
```

**Result:**

```text
~/.claude/commands/.aida/
├── start-work/
├── open-pr/
└── cleanup-main/
```

### Install Agents in Dev Mode

```bash
install_templates \
  ~/.aida/templates/agents \
  ~/.claude/agents \
  true \
  .aida
```

**Result:**

```text
~/.claude/agents/.aida/
├── secretary -> ~/.aida/templates/agents/secretary
├── dev-assistant -> ~/.aida/templates/agents/dev-assistant
└── file-manager -> ~/.aida/templates/agents/file-manager
```

### Convert from Dev Mode to Normal Mode

```bash
# Initially installed in dev mode (symlinks)
install_templates ~/.aida/templates/commands ~/.claude/commands true .aida

# Convert to normal mode (copies)
install_templates ~/.aida/templates/commands ~/.claude/commands false .aida
```

**Behavior:**

- Backs up symlinks with timestamp (e.g., `start-work.backup.20251018-143022`)
- Replaces symlinks with copied directories
- Preserves all template content

### Deprecate Old Templates

```bash
# Move old templates to deprecated namespace
install_templates \
  ~/.aida/templates/commands \
  ~/.claude/commands \
  false \
  .aida-deprecated
```

## Error Handling

### Validation Errors

**Missing README.md:**

```text
✗ Template missing README.md: /path/to/template
```

**Not a directory:**

```text
✗ Template is not a directory: /path/to/template.md
```

### Filesystem Errors

**Failed to create directory:**

```text
✗ Failed to create namespace directory: ~/.claude/commands/.aida
```

**Failed to copy template:**

```text
✗ Failed to copy template: start-work
```

**Failed to create symlink:**

```text
✗ Failed to create symlink for template: start-work
```

### Installation Summary

After installation, reports statistics:

**Success:**

```text
✓ Installed 15 template(s) to ~/.claude/commands/.aida
```

**Partial failure:**

```text
✗ Template installation completed with errors
ℹ   Installed: 14
ℹ   Failed:    1
```

## Cross-Platform Compatibility

### macOS Support

- Uses BSD `cp` for copying (`cp -a`)
- Uses BSD `ln` for symlinking (`ln -s`)
- Uses BSD `stat` for permissions (in `generate_claude_md`)

### Linux Support

- Uses GNU `cp` for copying (`cp -a`)
- Uses GNU `ln` for symlinking (`ln -s`)
- Uses GNU `stat` for permissions

### Symlink Handling

Uses platform-agnostic `readlink` (no `-f` flag for macOS compatibility).

## Testing

### Unit Tests

Located in `tests/unit/test_templates.bats`:

```bash
# Run all template tests
bats tests/unit/test_templates.bats

# Run specific test
bats tests/unit/test_templates.bats --filter "install_templates creates namespace"
```

### Test Coverage

Tests cover:

- Template structure validation
- Normal mode installation (copy)
- Dev mode installation (symlink)
- Namespace isolation
- Mode conversion (dev → normal)
- Error handling and validation
- User content preservation
- CLAUDE.md generation

### Manual Testing

```bash
# Test normal mode installation
./install.sh

# Verify namespace structure
ls -la ~/.claude/commands/.aida/
ls -la ~/.claude/agents/.aida/

# Test dev mode installation
./install.sh --dev

# Verify symlinks
ls -la ~/.claude/commands/.aida/
readlink ~/.claude/commands/.aida/start-work
```

## Migration Guide

### From Old Variable Substitution Approach

**Old code (deprecated):**

```bash
copy_command_templates "$template_dir" "$install_dir" "$aida_dir" "$claude_dir" "$home_dir" "$dev_mode"
```

**New code:**

```bash
install_templates "$template_dir" "$install_dir" "$dev_mode" ".aida"
```

**Key changes:**

- No more variable substitution parameters (AIDA_DIR, CLAUDE_DIR, HOME)
- Templates stay pure (no `{{VAR}}` replacement)
- Must specify namespace (`.aida`)
- Folder-based templates (not `.md` files)

### Converting Templates to Folders

**Before (file-based):**

```text
templates/commands/
└── start-work.md
```

**After (folder-based):**

```text
templates/commands/start-work/
└── README.md
```

**Migration steps:**

1. Create folder: `mkdir templates/commands/start-work`
2. Move file: `mv templates/commands/start-work.md templates/commands/start-work/README.md`
3. Update references to use folder path

### Removing Variable Substitution

**Before:**

```markdown
# Start Work

To start work on an issue, run:

` ``bash
cd {{PROJECT_ROOT}}
git checkout -b feature/{{ISSUE_NUMBER}}
` ``
```

**After:**

```markdown
# Start Work

To start work on an issue, run:

` ``bash
PROJECT_ROOT=$(aida-config-helper.sh --key paths.project_root)
ISSUE_NUMBER=$(aida-config-helper.sh --key issue.number)
cd "$PROJECT_ROOT"
git checkout -b "feature/${ISSUE_NUMBER}"
` ``
```

## Integration with install.sh

### Normal Installation

```bash
# In install.sh
install_templates "${REPO_DIR}/templates/commands" "${CLAUDE_DIR}/commands" false ".aida"
install_templates "${REPO_DIR}/templates/agents" "${CLAUDE_DIR}/agents" false ".aida"
install_templates "${REPO_DIR}/templates/skills" "${CLAUDE_DIR}/skills" false ".aida"
```

### Dev Mode Installation

```bash
# In install.sh --dev
install_templates "${REPO_DIR}/templates/commands" "${CLAUDE_DIR}/commands" true ".aida"
install_templates "${REPO_DIR}/templates/agents" "${CLAUDE_DIR}/agents" true ".aida"
install_templates "${REPO_DIR}/templates/skills" "${CLAUDE_DIR}/skills" true ".aida"
```

## Version History

### v1.0 (2025-10-18)

- Initial release with namespace isolation (ADR-013)
- Removed variable substitution (use config aggregator)
- Folder-based template structure
- Dual installation modes (normal/dev)
- User content protection via namespaces

## See Also

- [directories.sh](README-directories.md) - Directory creation and namespace management
- [config-aggregator.sh](README-config-aggregator.md) - Runtime configuration resolution
- [ADR-013: Namespace Isolation](../../docs/adr/ADR-013-namespace-isolation.md)
