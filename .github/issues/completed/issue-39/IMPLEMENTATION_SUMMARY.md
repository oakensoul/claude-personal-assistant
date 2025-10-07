---
title: "Implementation Summary - Issue #39"
issue: 39
created: "2025-10-07"
status: "ready"
---

# Implementation Summary: Issue #39

## Overview

### What

Move 4 workflow commands (cleanup-main, implement, open-pr, start-work) from installed system to templates/ with variable substitution

### Why

Enable user customization, establish single source of truth, improve maintainability, support version control of commands

### Approach

Template-based distribution with hybrid variable substitution (install-time for static paths, runtime for dynamic paths)

## Key Decisions

### 1. Variable Substitution Strategy

#### Decision

Hybrid approach

- Install-time: `{{AIDA_HOME}}`, `{{CLAUDE_CONFIG_DIR}}`, `{{HOME}}` → sed substitution
- Runtime: `${PROJECT_ROOT}`, `${GIT_ROOT}` → bash variable resolution

#### Rationale

Static paths known at install, dynamic paths vary per-command execution

### 2. Template Syntax

#### Decision

`{{VARIABLE}}` for install-time, `${VARIABLE}` for runtime

#### Rationale

Clear distinction, prevents conflicts with bash variables

### 3. File Extensions

#### Decision

Keep `.md` extension (not `.template`)

#### Rationale

Templates are valid markdown, editor support, pre-commit validation

### 4. Substitution Tool

#### Decision

sed with portable syntax (BSD/GNU compatible)

#### Rationale

Zero dependencies, POSIX standard, already used in codebase

### 5. Backup Strategy

#### Decision

Timestamp backups to `~/.claude/commands/.backups/YYYYMMDD_HHMMSS/`

#### Rationale

Preserve user customizations, enable rollback, keep indefinitely

### 6. Dev Mode Behavior

#### Decision

Symlink templates (no substitution)

#### Rationale

Live editing for developers, consistent with other dev mode behavior

### 7. Permission Model

#### Decision

Templates 644, installed commands 600

#### Rationale

Templates are shareable, installed commands contain system paths

### 8. CI Template Validation

#### Decision

Create follow-up issue to fix (don't block this PR)

#### Rationale

CI debugging out of scope, address separately

## Implementation Scope

### In Scope

#### Phase 1 (This Issue)

- Extract 4 commands to `templates/commands/workflows/`
- Remove hardcoded paths, add template variables
- Update `install.sh` with `copy_command_templates()`
- Implement sed-based substitution
- Add backup logic with timestamps
- Set correct permissions (644 templates, 600 commands)
- Add pre-commit validation script
- Create documentation (README, architecture doc)
- Test on macOS and Linux

### Out of Scope (Deferred)

#### Phase 2

- Command schema validation
- Three-way merge for user customizations
- Advanced variable validation (dependency checks)
- Hot-reload in dev mode

#### Phase 3

- CLI validation tool (`aida validate-commands`)
- Command versioning system
- Automated migration for template updates
- Command marketplace/sharing

## Technical Approach

### Component Changes

#### New Components

- `templates/commands/workflows/` - Command templates with variables
- `scripts/validate-templates.sh` - Pre-commit validation
- `tests/test-command-templates.sh` - Test suite
- `docs/architecture/command-templates.md` - Documentation

#### Modified Components

- `install.sh` - Add `copy_command_templates()` function
- `.pre-commit-config.yaml` - Add template validation hook
- `.gitattributes` - Enforce LF line endings for templates

### Integration Points

#### install.sh Integration

```bash
copy_command_templates() {
    local template_dir="${SCRIPT_DIR}/templates/commands/workflows"
    local install_dir="${CLAUDE_DIR}/commands/workflows"
    local backup_dir="${CLAUDE_DIR}/commands/.backups/$(date +%Y%m%d_%H%M%S)"

    # Backup existing commands
    if [ -d "${install_dir}" ]; then
        mkdir -p "${backup_dir}"
        cp -r "${install_dir}"/* "${backup_dir}/"
    fi

    # Dev mode: symlink
    if [ "${DEV_MODE}" = true ]; then
        ln -sf "${template_dir}" "${install_dir}"
        return 0
    fi

    # Normal mode: copy with substitution
    for template in "${template_dir}"/*.md; do
        local cmd_name=$(basename "${template}")
        local target="${install_dir}/${cmd_name}"

        sed -e "s|{{AIDA_HOME}}|${AIDA_DIR}|g" \
            -e "s|{{CLAUDE_CONFIG_DIR}}|${CLAUDE_DIR}|g" \
            -e "s|{{HOME}}|${HOME}|g" \
            "${template}" > "${target}"

        chmod 600 "${target}"
    done
}
```

#### Command Execution

- Commands use `${PROJECT_ROOT}` which resolves at runtime
- State files: `${PROJECT_ROOT}/.claude/workflow-state.json`
- Agent invocations use substituted paths

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| sed BSD/GNU differences | High | Portable syntax, test on both platforms |
| Substitution failures | High | Validation, atomic operations, rollback |
| Hardcoded paths in templates | Medium | Pre-commit detection, automated scanning |
| User customization loss | Medium | Timestamped backups, documentation |
| Secret exposure | High | Pre-commit secret detection, validation |
| Dev mode symlink conflicts | Low | Documentation, test coverage |

## Success Criteria

- [ ] All 4 commands in `templates/commands/workflows/` with variables
- [ ] `install.sh` successfully substitutes variables
- [ ] Commands execute correctly with resolved paths
- [ ] Permissions enforced (644 templates, 600 installed)
- [ ] Pre-commit validation catches invalid templates
- [ ] Tests pass on macOS and Linux
- [ ] Documentation complete
- [ ] Zero hardcoded paths in templates
- [ ] Backups created before reinstall

## Effort Estimate

### Complexity

Medium (M)

### Total Hours

18-26 hours

### Breakdown

- Template creation and migration: 3-4 hours
- Install script modification: 4-6 hours
- Validation script: 2-3 hours
- Testing (unit + integration + platform): 6-8 hours
- Security review: 2-3 hours
- Documentation: 1-2 hours

## Next Steps

### Implementation Order

1. **Extract commands** (30 min)
   - Copy 4 commands from `~/.claude/commands/` to `templates/commands/workflows/`
   - Remove hardcoded absolute paths

2. **Add template variables** (1 hour)
   - Replace paths with `{{AIDA_HOME}}`, `{{CLAUDE_CONFIG_DIR}}`, etc.
   - Verify all hardcoded paths replaced

3. **Update install.sh** (4 hours)
   - Implement `copy_command_templates()` function
   - Add sed substitution logic
   - Implement backup strategy
   - Handle dev mode (symlinks)
   - Set permissions

4. **Create validation script** (2 hours)
   - Validate template syntax
   - Check for hardcoded paths
   - Verify variable completeness

5. **Add pre-commit hook** (1 hour)
   - Integrate validation script
   - Test hook on commit
   - Update documentation

6. **Write tests** (6 hours)
   - Unit tests for substitution
   - Integration tests for install flow
   - Platform tests (macOS + Linux)
   - Edge case coverage

7. **Documentation** (2 hours)
   - Architecture doc
   - Variable reference
   - Developer guide
   - User customization guide

8. **Security review** (2 hours)
   - Verify no secrets in templates
   - Test permission enforcement
   - Validate input sanitization

### Testing Checklist

#### Unit Tests

- [ ] Variable substitution (all variables)
- [ ] Permission enforcement (644/600)
- [ ] Backup creation
- [ ] Dev mode symlinks
- [ ] Normal mode copies

#### Integration Tests

- [ ] Fresh install (normal mode)
- [ ] Fresh install (dev mode)
- [ ] Reinstall with existing commands
- [ ] Command execution post-install
- [ ] State file management

#### Platform Tests

- [ ] macOS (BSD sed, bash 3.2)
- [ ] Linux (GNU sed, bash 5.x)

#### Edge Cases

- [ ] Spaces in PROJECT_ROOT
- [ ] Missing template variables
- [ ] Corrupt state files
- [ ] Permission denied scenarios

## Related Documentation

- PRD: `.github/issues/in-progress/issue-39/PRD.md`
- Technical Spec: `.github/issues/in-progress/issue-39/TECH_SPEC.md`
- Product Analyses: `.github/issues/in-progress/issue-39/analysis/product/`
- Technical Analyses: `.github/issues/in-progress/issue-39/analysis/technical/`

## Follow-Up Issues

### Follow-Up Issues to Create After This PR

1. **Fix CI template validation** (Q1 decision)
   - Debug validate-templates.sh in GitHub Actions
   - Re-enable pre-commit hook in CI

2. **Three-way merge for customizations**
   - Implement merge strategy for user-modified commands
   - Add diff tool for comparing template vs. customized

3. **Command versioning system**
   - Add version metadata to templates
   - Track installed versions
   - Automated migration on upgrade

4. **CLI validation tool**
   - `aida validate-commands` command
   - Check command syntax and dependencies
   - Verify variable resolution

## Key Insights

### Configuration Philosophy

Commands should be copied (not symlinked in normal mode) to allow user customization while maintaining framework template integrity. Dev mode symlinks for live editing.

### Variable Strategy

Hybrid substitution balances performance (install-time for static) with flexibility (runtime for dynamic). Clear syntax distinction prevents errors.

### Validation Approach

Multi-layer validation (pre-commit, install, runtime) provides defense in depth without blocking user experimentation.

### Backup Philosophy

Always backup, never overwrite without preservation. Disk space is cheap, user trust is expensive.
