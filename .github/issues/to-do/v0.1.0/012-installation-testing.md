---
title: "Test installation on fresh systems"
labels:
  - "type: testing"
  - "priority: p0"
  - "effort: medium"
  - "milestone: 0.1.0"
---

# Test installation on fresh systems

## Description

Thoroughly test the installation script on fresh systems to ensure it works correctly across different platforms and configurations. This is critical for MVP release quality.

## Acceptance Criteria

- [ ] Installation tested on fresh macOS system (Monterey or later)
- [ ] Installation tested on fresh Ubuntu 22.04 system
- [ ] Installation tested on fresh Debian system
- [ ] Installation tested with bash shell
- [ ] Installation tested with zsh shell
- [ ] Installation tested in dev mode (`--dev` flag)
- [ ] All generated files are correct and complete
- [ ] CLI tool is accessible and functional
- [ ] Variable substitution works correctly
- [ ] No template remnants (${VAR}) remain
- [ ] Permissions are set correctly
- [ ] Error handling works for common failure scenarios
- [ ] Documentation for testing is created

## Implementation Notes

### Test Environments

**macOS Testing:**
- Fresh macOS user account or VM
- Test with default shell (zsh on modern macOS)
- Test with bash (if user changes shell)
- Verify Homebrew compatibility (if present)

**Linux Testing:**
- Ubuntu 22.04 LTS (most common)
- Debian 12 (stable)
- Test with bash (default on most Linux)
- Test with zsh (common alternative)

### Test Procedure

**1. Clean System Test:**
```bash
# Start with no ~/.claude/ or ~/.aida/
# No ~/CLAUDE.md
# No ~/bin/ directory

# Run installation
./install.sh

# Verify outputs
# - Prompt for assistant name works
# - Prompt for personality works
# - Directories created correctly
# - Templates copied and substituted
# - CLI tool generated and executable
# - PATH configured correctly
# - CLI is accessible
```

**2. Dev Mode Test:**
```bash
# Clean system
./install.sh --dev

# Verify
# - ~/.aida/ is symlink to repo
# - ~/.claude/ is regular directory
# - Changes in repo reflect immediately
# - Dev mode warning displayed
```

**3. Re-installation Test:**
```bash
# Install once
./install.sh

# Install again
./install.sh

# Verify
# - Backup created of existing install
# - No data loss
# - Clean re-installation
# - Idempotent behavior
```

**4. Error Scenario Testing:**
```bash
# Test with no write permissions
chmod 000 ~
./install.sh
# Should fail gracefully with clear message

# Test with invalid input
# - Assistant name with spaces
# - Assistant name too short
# - Non-existent personality
# Should reject and re-prompt

# Test with missing dependencies
# Should detect and report clearly
```

### Verification Checklist

For each test run, verify:

**Directory Structure:**
- [ ] `~/.aida/` exists and contains framework files
- [ ] `~/.claude/` exists with correct subdirectories
- [ ] `~/.claude/config/` contains personality.yaml
- [ ] `~/.claude/knowledge/` contains all templates
- [ ] `~/.claude/memory/` contains context.md
- [ ] `~/.claude/agents/` contains agent files
- [ ] `~/bin/` exists and contains CLI tool
- [ ] `~/CLAUDE.md` exists

**File Contents:**
- [ ] All `${ASSISTANT_NAME}` replaced with actual name
- [ ] All `${PERSONALITY_NAME}` replaced correctly
- [ ] All `${INSTALL_DATE}` has valid timestamp
- [ ] No template variables remain unreplaced
- [ ] YAML files are valid
- [ ] Markdown files are well-formed

**Permissions:**
- [ ] Directories are 755 (rwxr-xr-x)
- [ ] Regular files are 644 (rw-r--r--)
- [ ] CLI tool is 755 (rwxr-xr-x)

**Functionality:**
- [ ] CLI tool executes without errors
- [ ] `{name} status` works
- [ ] `{name} help` displays correctly
- [ ] `{name} version` shows correct info
- [ ] CLI is in PATH (accessible from anywhere)
- [ ] Shell restart not required (or clearly indicated)

**Error Handling:**
- [ ] Missing dependencies detected
- [ ] Invalid input rejected
- [ ] Permission issues reported clearly
- [ ] Interrupted install can recover
- [ ] Existing install backed up

### Test Documentation

Create `docs/development/testing.md`:
```markdown
# Testing Guide

## Prerequisites
- VirtualBox or similar for VM testing
- macOS and Linux VMs
- Clean user accounts

## Test Matrix

| Platform | Shell | Mode | Status |
|----------|-------|------|--------|
| macOS 13 | zsh   | normal | ✓     |
| macOS 13 | zsh   | dev    | ✓     |
| macOS 13 | bash  | normal | ✓     |
| Ubuntu 22| bash  | normal | ✓     |
| Ubuntu 22| zsh   | normal | ✓     |
| Debian 12| bash  | normal | ✓     |

## How to Test

[Detailed testing procedures]

## Common Issues

[Document known issues and workarounds]

## Reporting Issues

[How to report test failures]
```

## Dependencies

- #001 (Installation script)
- #002 (Template system)
- #003 (CLI tool generation)
- #004 (PATH configuration)
- #005-#011 (All templates must be ready)

## Related Issues

- #013 (Documentation needs test results)

## Definition of Done

- [ ] All test environments executed successfully
- [ ] Test documentation created
- [ ] Test matrix shows all passing
- [ ] Common issues documented with workarounds
- [ ] Edge cases tested and handled
- [ ] Performance is acceptable (< 30 seconds install)
- [ ] No errors or warnings in normal operation
- [ ] Ready for MVP release
