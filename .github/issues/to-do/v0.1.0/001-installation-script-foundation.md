---
title: "Create foundational installation script"
labels:
  - "type: feature"
  - "priority: p0"
  - "effort: large"
  - "milestone: 0.1.0"
---

# Create foundational installation script

## Description

Create the core `install.sh` script that handles the basic AIDA framework installation. This is the foundation for all other features and must handle directory creation, template copying, variable substitution, and initial setup.

## Acceptance Criteria

- [ ] Script prompts user for assistant name with validation (no spaces, lowercase, 3-20 chars)
- [ ] Script prompts user to select from available personalities (jarvis, alfred, friday, sage, drill-sergeant)
- [ ] Script creates `~/.aida/` directory structure from repository
- [ ] Script creates `~/.claude/` directory structure:
  - `~/.claude/config/`
  - `~/.claude/knowledge/`
  - `~/.claude/memory/`
  - `~/.claude/memory/history/`
  - `~/.claude/agents/`
- [ ] Script sets proper permissions (755 for directories, 644 for files)
- [ ] Script provides clear status messages during installation
- [ ] Script handles errors gracefully with helpful messages
- [ ] Script supports `--dev` flag for development mode (symlinks instead of copies)
- [ ] Script is idempotent (can be run multiple times safely)
- [ ] Script creates backup of existing installation if found

## Implementation Notes

### Key Functions

```bash
prompt_assistant_name()    # Get and validate assistant name
prompt_personality()       # Interactive personality selection
validate_dependencies()    # Check for required tools (bash, git, etc.)
create_directories()       # Set up directory structure
check_existing_install()   # Detect and backup existing installation
```

### Error Handling

- Check if bash version >= 4.0
- Verify write permissions to home directory
- Detect if personality file exists
- Handle interrupted installations

### Development Mode

When `--dev` flag is used:

- Symlink `~/.aida/` to repository directory
- Copy (not symlink) `~/.claude/` to allow modifications
- Display dev mode warning

## Dependencies

None - this is the foundation

## Related Issues

- #002 (Template copying and variable substitution)
- #003 (CLI tool generation)
- #004 (PATH configuration)

## Definition of Done

- [ ] Script executes successfully on fresh macOS system
- [ ] Script executes successfully on fresh Ubuntu system
- [ ] Dev mode works and allows live editing
- [ ] Error messages are clear and actionable
- [ ] Script includes usage documentation (--help flag)
- [ ] Code is commented and maintainable
