---
title: "Configuration Specialist Technical Analysis - Issue #39"
issue: "#39"
analyst: "configuration-specialist"
created: "2025-10-07"
status: "draft"
---

# Configuration Specialist Technical Analysis: Issue #39

## 1. Implementation Approach

### Configuration Architecture

#### Template Variable System

- Use simple `{{VARIABLE_NAME}}` syntax for template placeholders
- Shell script-based substitution (sed/awk) - zero dependencies
- No templating engine required (mustache/jinja unnecessary overhead)
- Support nested variables: `{{CLAUDE_CONFIG_DIR}}/commands/workflows/`

#### Variable Categories

- **System variables**: `HOME`, `USER`, `SHELL`, `OSTYPE`
- **AIDA variables**: `AIDA_HOME` (~/.aida), `PROJECT_ROOT` (repo location)
- **Claude variables**: `CLAUDE_CONFIG_DIR` (~/.claude)
- **Runtime variables**: Computed during installation (timestamp, version)

#### Validation Strategy

- Pre-commit hook validates template syntax before commit
- Installation validates all variables resolved before file write
- Schema validation for command metadata (YAML frontmatter)

### Variable Substitution Implementation

#### Processing Pipeline

```bash
# In install.sh
process_command_template() {
    local template="$1"
    local output="$2"

    # 1. Read template
    # 2. Substitute variables (sed)
    # 3. Validate no unresolved variables
    # 4. Write output with correct permissions

    sed -e "s|{{PROJECT_ROOT}}|${PROJECT_ROOT}|g" \
        -e "s|{{AIDA_HOME}}|${AIDA_HOME}|g" \
        -e "s|{{CLAUDE_CONFIG_DIR}}|${CLAUDE_DIR}|g" \
        -e "s|{{HOME}}|${HOME}|g" \
        -e "s|{{USER}}|${USER}|g" \
        "${template}" > "${output}"

    # Validate no unresolved variables remain
    if grep -qE '\{\{[A-Z_]+\}\}' "${output}"; then
        echo "ERROR: Unresolved variables in ${output}"
        return 1
    fi
}
```

#### Template Extension Convention

- Template files: `command-name.sh.template` or `command-name.md.template`
- Installed files: `command-name.sh` or `command-name.md`
- Clear distinction between source (template) and generated (instance)

### Template Processing Logic

#### Installation Flow

1. Detect installation mode (normal vs dev)
2. Dev mode: Create symlinks (no substitution needed)
3. Normal mode: Copy templates with variable substitution
4. Validate all variables resolved
5. Set permissions (644 templates, 600 installed commands)
6. Backup existing commands if present

#### Directory Structure

```text
templates/
├── commands/
│   ├── workflows/
│   │   ├── cleanup-main.sh.template
│   │   ├── create-agent.sh.template
│   │   ├── create-command.sh.template
│   │   ├── create-issue.sh.template
│   │   ├── expert-analysis.sh.template
│   │   ├── generate-docs.sh.template
│   │   ├── implement.sh.template
│   │   ├── open-pr.sh.template
│   │   ├── publish-issue.sh.template
│   │   ├── start-work.sh.template
│   │   ├── track-time.sh.template
│   │   └── workflow-init.sh.template
│   └── README.md
```

## 2. Technical Concerns

### Configuration Validation

#### Template Syntax Validation

- Variable naming convention: Uppercase with underscores only
- No spaces inside braces: `{{VAR}}` not `{{ VAR }}`
- All variables must be defined in approved list
- Detect typos: `{{AIDA_HONE}}` should be `{{AIDA_HOME}}`

#### Variable Resolution Errors

- Unresolved variables after substitution indicate missing definitions
- Partial matches may indicate escaping issues
- Empty variable values should fail validation (HOME=/Users/oakensoul not HOME=)

#### Error Detection Strategy

```bash
# Pre-commit validation
validate_template_variables() {
    local template="$1"

    # Extract all variables
    local vars=$(grep -oE '\{\{[A-Z_]+\}\}' "${template}" | sort -u)

    # Check against approved list
    local approved="PROJECT_ROOT|AIDA_HOME|CLAUDE_CONFIG_DIR|HOME|USER"

    for var in ${vars}; do
        if ! echo "${var}" | grep -qE "\{\{(${approved})\}\}"; then
            echo "ERROR: Unapproved variable ${var} in ${template}"
            return 1
        fi
    done
}
```

### Template Syntax Issues

#### Escaping Challenges

- Shell variables `${var}` vs template variables `{{VAR}}`
- Must escape shell variables in templates: `\${var}` or use different syntax
- Recommendation: Use `{{VAR}}` for template-time, `${var}` passes through to shell

#### Nested Substitution

- Path construction: `{{CLAUDE_CONFIG_DIR}}/commands/workflows/`
- Must handle directory separators correctly
- No double-slashes from concatenation

#### Line-ending Issues

- Templates must use LF (Unix) not CRLF (Windows)
- Git attributes should enforce LF for .template files
- Validation hook checks line endings

### Configuration Migration

#### Version Detection

- No existing commands to migrate (first implementation)
- Future: Detect template version in frontmatter
- Support backward compatibility for user-modified commands

#### Upgrade Strategy

- Backup existing commands before overwrite
- Timestamp backups: `command.sh.bak.20251007_143022`
- Never overwrite user modifications without backup
- Log all migration actions for debugging

#### Conflict Resolution

- If user modified command, prompt before overwrite
- Options: Keep existing, use new template, show diff
- Default: Backup existing and install new template
- Preserve user customizations in .bak file

## 3. Dependencies & Integration

### Configuration File Dependencies

#### Required Files

- `templates/commands/workflows/*.template` (12 command templates)
- `install.sh` (installation logic)
- `.pre-commit-config.yaml` (validation hooks)
- `scripts/validate-templates.sh` (existing privacy validator)

#### New Files Needed

- `scripts/validate-command-templates.sh` (variable validation)
- `templates/commands/README.md` (documentation)
- `.gitattributes` updates (enforce LF line endings)

#### Existing Integration Points

- `validate-templates.sh` already checks for hardcoded paths
- Extend to validate template variable syntax
- No conflicts with existing privacy validation

### Template Processing Tools

#### Native Shell Tools (Zero Dependencies)

- `sed`: Variable substitution (POSIX compliant)
- `grep`: Variable extraction and validation
- `find`: Template file discovery
- `chmod`: Permission setting

#### No External Dependencies

- No envsubst (not always available)
- No mustache/jinja/handlebars
- No Node.js/Python template engines
- Pure bash implementation for portability

#### Compatibility

- Bash 3.2+ (macOS default)
- POSIX sed (both BSD and GNU)
- Works on macOS and Linux

### Validation Frameworks

#### Pre-commit Integration

- Hook: `validate-command-templates` (new)
- Runs on: `templates/commands/**/*.template`
- Fast: Only scans changed template files
- Fails commit if validation errors found

#### Validation Checks

1. Variable syntax: `{{VARIABLE_NAME}}` format
2. Approved variables: Only allowed variable names
3. No unresolved variables: All variables have definitions
4. Line endings: LF only (no CRLF)
5. File permissions: Templates are 644
6. Shellcheck: Command scripts pass shellcheck

#### Existing Hooks (Extend, Don't Replace)

- `validate-templates.sh`: Privacy validation (hardcoded paths)
- `markdownlint`: Markdown command documentation
- `shellcheck`: Shell script command validation
- `yamllint`: YAML frontmatter validation

## 4. Effort & Complexity

### Estimated Complexity: M (Medium)

#### Justification

- Template creation: Straightforward (convert 12 existing commands)
- Variable substitution: Simple sed-based implementation
- Validation logic: Moderate complexity (pattern matching, error reporting)
- Testing: Need to test normal mode, dev mode, upgrades
- Documentation: User-facing docs, contributor guidelines

#### Not Simple (S) Because

- 12 command files to convert and test
- Installation logic changes in install.sh
- New validation script required
- Pre-commit hook integration
- User migration edge cases (backups, conflicts)

#### Not Large (L) Because

- No templating engine to integrate
- No schema system to design
- No configuration language to parse
- Existing validate-templates.sh provides pattern
- Simple sed-based substitution (well-understood)

### Configuration Implementation Effort

#### Phase 1: Core Implementation (4-6 hours)

- Create `.template` versions of 12 command files
- Replace hardcoded paths with `{{VARIABLES}}`
- Update install.sh with template processing
- Test installation in normal and dev modes

#### Phase 2: Validation (2-3 hours)

- Create `scripts/validate-command-templates.sh`
- Add pre-commit hook configuration
- Test validation with invalid templates
- Document validation rules

#### Phase 3: Documentation (2-3 hours)

- Update install.sh help text
- Create templates/commands/README.md
- Document customization workflow
- Add contributor guidelines for templates

#### Phase 4: Testing (2-3 hours)

- Test fresh installation
- Test upgrade with existing commands
- Test dev mode symlinks
- Test validation hook catches errors

#### Total Effort: 10-15 hours

### High-Risk Areas

#### Variable Escaping in Shell Scripts

- Risk: Shell variables `${var}` conflict with template syntax
- Mitigation: Use `{{VAR}}` for templates, `${var}` passes through
- Test: Verify nested variable expansion works correctly

#### Permission Issues

- Risk: Installed commands not executable or too permissive
- Mitigation: Explicit chmod in install.sh (600 for commands)
- Test: Verify permissions on installed commands

#### Backup Collision

- Risk: Multiple backups overwrite each other
- Mitigation: Timestamp backups (`.bak.20251007_143022`)
- Test: Run installation twice, verify both backups exist

#### Dev Mode Symlink Conflicts

- Risk: Symlinks point to wrong location or break on upgrade
- Mitigation: Detect existing symlinks, validate target
- Test: Switch between normal and dev mode

#### Variable Typos

- Risk: `{{AIDA_HONE}}` instead of `{{AIDA_HOME}}` silently fails
- Mitigation: Validation script checks approved variable list
- Test: Commit template with typo, verify hook catches it

## 5. Questions & Clarifications

### Configuration Questions

#### Q1: Variable Naming Convention

- Should we support `{{project.root}}` (dotted) or `{{PROJECT_ROOT}}` (underscored)?
- **Recommendation**: Uppercase with underscores (`{{PROJECT_ROOT}}`) for shell compatibility
- **Rationale**: Matches shell variable convention, easier to grep

#### Q2: Template Extension

- Should templates be `.sh.template` or `.template.sh`?
- **Recommendation**: `.sh.template` (extension describes generated file)
- **Rationale**: Clearer that base file is `.sh`, template modifier at end

#### Q3: Nested Variables

- Should we support `{{CLAUDE_CONFIG_DIR}}/commands` or `{{CLAUDE_COMMANDS_DIR}}`?
- **Recommendation**: Concatenation (`{{CLAUDE_CONFIG_DIR}}/commands`)
- **Rationale**: Fewer variables to maintain, more flexible

#### Q4: Variable Resolution Failure

- Should installation fail or warn if variable unresolved?
- **Recommendation**: Fail installation (exit 1)
- **Rationale**: Better to fail early than install broken commands

### Implementation Decisions

#### Q5: Backup Strategy

- Always backup, never backup, or prompt user?
- **Recommendation**: Always backup with timestamp
- **Rationale**: Non-destructive, allows recovery, no user interruption

#### Q6: Dev Mode Handling

- Symlink entire workflows/ directory or individual files?
- **Recommendation**: Symlink entire directory
- **Rationale**: Simpler, easier to maintain, fewer symlinks to track

#### Q7: Validation Hook Scope

- Validate all templates or only workflows/?
- **Recommendation**: All templates in templates/ directory
- **Rationale**: Ensures consistency, future-proof for other template types

#### Q8: Template Documentation

- Embed variable documentation in templates or separate README?
- **Recommendation**: Both (comments in template + README.md)
- **Rationale**: In-place reference + comprehensive guide

### Validation Strategy

#### Q9: Validation Timing

- Pre-commit only or also at runtime (installation)?
- **Recommendation**: Both
- **Rationale**: Pre-commit catches dev errors, runtime validates system state

#### Q10: Error Reporting

- Show all errors or fail-fast on first error?
- **Recommendation**: Show all errors (collect and report)
- **Rationale**: Faster to fix multiple issues at once

#### Q11: Variable Whitelist

- Hardcode approved variables or load from config file?
- **Recommendation**: Hardcode in validation script
- **Rationale**: Simpler, fewer files to maintain, clear contract

#### Q12: Line Ending Enforcement

- Validate line endings or let git attributes handle it?
- **Recommendation**: Both (git attributes + validation)
- **Rationale**: Defense in depth, catch issues early

## Recommendations Summary

### Critical Path

1. Define approved variable list (PROJECT_ROOT, AIDA_HOME, CLAUDE_CONFIG_DIR, HOME, USER)
2. Create template extension convention (.sh.template, .md.template)
3. Implement simple sed-based substitution in install.sh
4. Create validation script for pre-commit hook
5. Test installation flow (normal, dev, upgrade scenarios)

### Quick Wins

- Extend existing validate-templates.sh rather than new script
- Use existing shellcheck/markdownlint hooks for command validation
- Document variables in templates/commands/README.md
- Add .gitattributes for line ending enforcement

### Avoid Over-Engineering

- No templating engine needed (sed is sufficient)
- No schema validation system yet (defer to Phase 2)
- No configuration file for variables (hardcode in install.sh)
- No hot-reload in dev mode (defer to future enhancement)

### Success Criteria

- All 12 commands converted to templates with no hardcoded paths
- Installation succeeds on macOS and Linux
- Pre-commit hook catches invalid templates
- User commands preserved during upgrade (timestamped backups)
- Documentation clear for users and contributors
