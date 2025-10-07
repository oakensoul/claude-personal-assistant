---
title: "Technical Specification - Issue #39"
description: "Move workflow commands to templates with variable substitution"
issue: 39
created: "2025-10-07"
status: "draft"
complexity: "Medium"
effort: "18-26 hours"
---

# Technical Specification: Workflow Command Templates

## Architecture Overview

Template-based command distribution system where commands live in `templates/commands/` with placeholder variables ({{PROJECT_ROOT}}, {{AIDA_HOME}}, etc.). Install script copies templates to `~/.claude/commands/` and substitutes variables using sed. Commands execute with runtime variable resolution for project-specific paths.

**Key components**: Template storage (source), install script (copy+substitute), command execution (runtime resolution), validation system (pre-commit hooks).

## Technical Decisions

### Decision 1: Variable Substitution Strategy

#### Decision

Hybrid approach - install-time substitution for system paths ({{AIDA_HOME}}), runtime substitution for project paths (${PROJECT_ROOT})

#### Rationale

- System paths are static after installation (AIDA_HOME, CLAUDE_CONFIG_DIR)
- Project paths are dynamic per-command execution (PROJECT_ROOT, GIT_ROOT)
- Hybrid approach balances performance (no runtime overhead for static paths) with flexibility (project-agnostic commands)

#### Alternatives

- Pure install-time: Requires reinstall for any path change
- Pure runtime: Performance overhead for static path resolution

#### Trade-offs

- Pros: Best of both worlds, efficient, flexible
- Cons: More complex than single approach, requires clear documentation

### Decision 2: Template Syntax

#### Decision

Use {{VARIABLE}} for install-time substitution, ${VARIABLE} for runtime substitution

#### Rationale

- Clear visual distinction between substitution types
- {{}} invalid in bash, prevents accidental execution
- ${} is standard bash variable syntax
- sed pattern matching simple with {{}}

#### Alternatives

- @VARIABLE@ (autoconf style): Less familiar
- %VARIABLE% (Windows style): Platform confusion
- $VARIABLE: Conflicts with bash variables

#### Trade-offs

- Pros: Unambiguous, familiar to developers, prevents errors
- Cons: Two syntaxes to document and maintain

### Decision 3: File Extensions

#### Decision

Use `.md` extension for templates (not `.template` or `.md.template`)

#### Rationale

- Commands are markdown files with shell code blocks
- Templates are valid markdown before substitution
- Syntax highlighting works in editors
- Pre-commit hooks can validate markdown structure

#### Alternatives

- `.template`: Loses markdown syntax support
- `.md.template`: Redundant, breaks tool recognition

#### Trade-offs

- Pros: Full editor support, immediate validation
- Cons: Less obvious they're templates (addressed via directory structure)

### Decision 4: Substitution Tool

#### Decision

Use sed with portable syntax (BSD/GNU compatible)

#### Rationale

- Zero dependencies (sed is POSIX standard)
- Simple pattern replacement sufficient
- Portable across macOS (BSD) and Linux (GNU)
- Already used elsewhere in codebase

#### Alternatives

- envsubst: Not available on macOS by default
- awk: Overkill for simple substitution
- perl: Additional dependency

#### Trade-offs

- Pros: Universal availability, simple, proven
- Cons: Syntax differences between BSD/GNU require testing

### Decision 5: Backup Strategy

#### Decision

Timestamp-based backups before overwriting existing commands

#### Rationale

- Preserves user customizations during reinstall
- Allows rollback if substitution fails
- Timestamp ensures unique filenames
- Backup location in ~/.claude/commands/.backups/

#### Alternatives

- No backups: User data loss risk
- Numbered backups: Harder to identify by date
- Single backup: Loses history

#### Trade-offs

- Pros: Safe, traceable, reversible
- Cons: Disk space usage (mitigated by cleanup strategy)

### Decision 6: Permission Model

#### Decision

Templates 644, installed commands 600, validate at multiple stages

#### Rationale

- Templates are shareable (644), installed commands contain paths (600)
- Pre-commit enforces template permissions
- Install script enforces installed permissions
- Defense in depth

#### Alternatives

- All 644: Exposes system paths to other users
- All 600: Prevents sharing templates

#### Trade-offs

- Pros: Security + shareability, layered validation
- Cons: Permission errors if umask misconfigured

## Implementation Plan

### Components to Build/Modify

#### templates/commands/ (new directory)

- Create directory structure for command templates
- Move existing commands from `.claude/commands/` with variables substituted
- Add README explaining template system

#### install.sh (modify)

- Add `copy_command_templates()` function
- Implement sed-based variable substitution
- Add backup logic before overwriting
- Enforce 600 permissions on installed commands
- Validate substitution success

#### scripts/validate-templates.sh (new)

- Validate template syntax ({{VAR}} completeness)
- Check required variables present
- Verify markdown structure
- Detect hardcoded paths

#### .pre-commit-config.yaml (modify)

- Add template validation hook
- Check template permissions (644)
- Validate variable syntax

#### docs/architecture/command-templates.md (new)

- Document template system architecture
- Variable reference table
- Substitution process flow
- Developer guide for adding commands

#### tests/test-command-templates.sh (new)

- Test substitution logic (all variables)
- Test permission enforcement
- Test backup/restore
- Test error handling
- Platform-specific tests (macOS + Linux)

### Dependencies

#### External

- sed (POSIX standard, already required)
- bash 3.2+ (already required for macOS)
- git (already required)
- gh CLI (already required for workflow commands)

#### Internal

- install.sh sourcing mechanism
- pre-commit hook infrastructure
- Test framework structure

### Integration Points

#### Install Script Integration

- Called during normal install (`./install.sh`)
- Called during dev mode (`./install.sh --dev`)
- Hooks into existing installation flow after `~/.claude/` creation

#### Command Execution Integration

- Commands source runtime variables from state files
- PROJECT_ROOT resolved via git root detection
- AIDA_HOME read from environment or default
- Integration with `/workflow-init`, `/start-work`, `/create-issue`, etc.

#### Pre-commit Integration

- Validates templates before commit
- Runs on template file changes
- Blocks commits with invalid templates or permissions

#### Agent Integration

- Commands invoke agents via established mechanisms
- Agent paths use substituted variables
- State files use runtime-resolved paths

## Technical Risks & Mitigations

### Risk: sed syntax differences between BSD (macOS) and GNU (Linux)

- **Impact**: High (cross-platform breakage)
- **Mitigation**: Use portable sed syntax (avoid `-i` extension differences), test on both platforms, document sed version requirements

### Risk: Variable substitution failures leave broken commands

- **Impact**: High (unusable commands)
- **Mitigation**: Validate substitution success, atomic operations (write to temp, validate, move), rollback on failure

### Risk: Hardcoded paths slip into templates

- **Impact**: Medium (portability loss)
- **Mitigation**: Pre-commit validation script scans for common path patterns (`/Users/`, `/home/`, absolute paths), automated detection

### Risk: User customizations lost during reinstall

- **Impact**: Medium (user frustration)
- **Mitigation**: Backup before overwrite, clear documentation, restoration instructions, consider merge strategy for future

### Risk: Secret exposure in command templates

- **Impact**: High (security breach)
- **Mitigation**: Pre-commit secret detection, template review process, avoid commands that handle secrets, runtime secret management

### Risk: Dev mode symlink conflicts

- **Impact**: Low (dev workflow disruption)
- **Mitigation**: Dev mode skips substitution (symlinks remain to templates), document behavior, test dev mode specifically

### Risk: Permission drift (wrong permissions set)

- **Impact**: Medium (security or usability issues)
- **Mitigation**: Multiple validation layers (pre-commit, install script, runtime checks), automated enforcement

## Testing Strategy

### Unit Tests (scripts/test-command-templates.sh)

- Variable substitution accuracy (100% coverage required)
  - All variables substituted correctly
  - No leftover {{}} placeholders
  - Correct bash ${} syntax preserved
- Permission enforcement (100% coverage required)
  - Templates are 644
  - Installed commands are 600
  - Backups inherit correct permissions
- Backup/restore functionality
  - Backups created before overwrite
  - Restoration successful
  - Cleanup after successful install

### Integration Tests

- End-to-end install flow
  - Fresh install substitutes correctly
  - Reinstall preserves backups
  - Dev mode skips substitution
- Command execution with substituted variables
  - System paths resolve correctly
  - Project paths resolve at runtime
  - Agent invocations work
- Pre-commit hook validation
  - Blocks invalid templates
  - Blocks wrong permissions
  - Detects hardcoded paths

### Platform Tests (matrix: macOS + Linux)

- sed behavior consistency
- Permission model differences
- Path handling (macOS case-insensitive)
- Bash version compatibility (3.2+ for macOS)

### Edge Cases

- Empty template directory (90% coverage target)
- Missing variables in templates
- User-modified commands during reinstall
- Corrupt state files during command execution
- Network failures during agent/gh operations (command resilience)

### Security Tests

- Secret detection in templates
- Command injection attempts via variables
- Permission escalation attempts
- Symlink attacks during install

## Open Technical Questions

### Q1: Should template validation be re-enabled in CI, or is it intentionally disabled?

- **Investigation**: Review CI configuration and recent changes
- **Decision needed**: If disabled for issue #39 work, create follow-up task to re-enable

### Q2: What's the merge strategy for user-customized commands during reinstall?

- **Options**: Overwrite with backup, 3-way merge, skip if customized, prompt user
- **Recommendation**: Start with backup+overwrite, add merge in future iteration
- **Decision needed**: Document behavior in install.sh and user-facing docs

### Q3: Should dev mode symlink templates or copy+substitute?

- **Integration Specialist**: Symlink for live editing
- **Security Auditor**: Copy to enforce permissions
- **Recommendation**: Symlink templates (developer convenience), document security implications
- **Decision needed**: Confirm dev mode behavior and document

### Q4: How to detect user customizations vs. template-generated commands?

- **Options**: Metadata header, checksum comparison, modification timestamp
- **Recommendation**: Add `# Generated from template: <template-name>` header
- **Decision needed**: Implementation approach for future merge support

### Q5: Should backup cleanup be automatic or manual?

- **Options**: Auto-cleanup after N days, manual cleanup command, never cleanup
- **Recommendation**: Keep backups indefinitely (disk space negligible), add `aida cleanup` command in future
- **Decision needed**: Initial cleanup policy

### Q6: Cross-platform path separator handling (Windows future-proofing)?

- **Current**: Hardcoded `/` for POSIX
- **Recommendation**: Ignore Windows for v0.1, document POSIX-only
- **Decision needed**: Document platform limitations

## Effort Estimate

### Overall Complexity

Medium (M)

### Total Effort

18-26 hours

### Breakdown

- Template creation and migration: 3-4 hours
  - Move commands to templates/
  - Replace hardcoded paths with variables
  - Create template README
- Install script modification: 4-6 hours
  - Implement copy_command_templates()
  - Add sed substitution logic
  - Implement backup strategy
  - Permission enforcement
- Validation script: 2-3 hours
  - Template syntax validation
  - Hardcoded path detection
  - Pre-commit integration
- Testing: 6-8 hours
  - Unit test coverage (100% for critical paths)
  - Platform testing (macOS + Linux)
  - Integration testing
  - Edge case coverage
- Security review and hardening: 2-3 hours
  - Secret detection patterns
  - Permission enforcement validation
  - Command injection prevention
- Documentation: 1-2 hours
  - Architecture documentation
  - Variable reference
  - Developer guide

### Key Effort Drivers

- Cross-platform sed compatibility (macOS BSD vs. Linux GNU)
- Comprehensive test coverage (security-critical component)
- Backup/restore robustness (protecting user data)
- Multi-layer validation (pre-commit, install, runtime)

### Recommended Approach

- Start with single command template (POC)
- Validate substitution and permissions work cross-platform
- Expand to all commands
- Add comprehensive testing last

### Dependencies for Completion

- Resolve Q1 (CI template validation)
- Resolve Q3 (dev mode behavior)
- Access to Linux environment for testing

## Success Criteria

- All workflow commands moved to templates/ with variables
- Install script successfully substitutes all variables
- Commands execute correctly with resolved paths
- Permissions enforced (644 templates, 600 installed)
- Pre-commit validation prevents invalid templates
- Tests pass on macOS and Linux
- Documentation complete with variable reference
- Zero hardcoded paths in templates
- User backups created before reinstall
