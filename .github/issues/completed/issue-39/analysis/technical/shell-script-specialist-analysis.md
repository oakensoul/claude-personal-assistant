---
title: "Shell Script Specialist Technical Analysis"
issue: "#39"
created: "2025-10-07"
agent: "shell-script-specialist"
status: "draft"
---

# Shell Script Specialist Technical Analysis: Issue #39

## 1. Implementation Approach

### Recommended Bash Implementation Strategy

- Use simple `sed`-based variable substitution (zero dependencies, POSIX-compliant)
- Leverage existing `install.sh` modular structure with dedicated function
- Template files use `.template` extension convention
- Variable syntax: `{{VARIABLE_NAME}}` (double braces for easy sed matching)
- Copy templates during installation, not symlink (maintains user customization)

### Key Technical Decisions

- **Templating**: Plain `sed` replacement over envsubst/mustache (no new dependencies)
- **File Structure**: `templates/commands/workflows/*.sh.template` → `~/.claude/commands/workflows/*.sh`
- **Backup Strategy**: Timestamp-based `.bak` files (non-destructive, preserves user changes)
- **Dev Mode**: Symlink entire `workflows/` directory, not individual files (simpler)
- **Validation**: shellcheck in pre-commit hooks for template files

### Tool Choices

- `sed`: Variable substitution (already validated as available)
- `rsync`: File copying with exclusions (already used in install.sh)
- `chmod`: Permission management (600 for installed commands, 644 for templates)
- `find`: Batch permission setting (already used)

## 2. Technical Concerns

### Performance Implications

- Minimal: 4 small shell scripts, sed processing <1ms per file
- Target <10s total installation time easily achievable
- No network I/O, all local file operations

### Security Considerations

- **Command Injection Risk**: sed pattern must use `|` delimiter, not `/` (handles paths with slashes)
- **Permission Control**: Templates 644 (read-only), installed commands 600 (user-only)
- **Path Validation**: Leverage existing `validate_path()` from `lib/installer-common/validation.sh`
- **Secrets**: Templates must contain NO hardcoded tokens/API keys (validate in pre-commit)
- **World-Writable Check**: Use existing `validate_file_permissions()` function

### Maintainability Issues

- **Single Source of Truth**: Templates directory is authoritative, eliminates drift
- **Variable Documentation**: Must document all template variables clearly
- **Testing**: Need shellcheck validation for both templates and generated commands
- **Upgrade Path**: Backup strategy handles existing user customizations

### Technical Risks

- **Variable Naming Conflicts**: If command uses `{{VAR}}` literally, sed will corrupt it
- **Dev Mode Complexity**: Symlinked workflows cannot be user-customized
- **Incomplete Substitution**: Missing variables silently create broken commands
- **Platform Differences**: Path handling between macOS/Linux (mitigated by existing patterns)

## 3. Dependencies & Integration

### Systems/Components Affected

- `install.sh`: Add `copy_command_templates()` function (lines ~350-400)
- `lib/installer-common/validation.sh`: Reuse path validation functions
- Pre-commit hooks: Add shellcheck validation for `templates/commands/workflows/*.template`
- `.gitignore`: Ensure `~/.claude/` excluded, templates/ included

### Required Dependencies

- `sed`: Already present (POSIX standard)
- `realpath`: Already validated in `validate_dependencies()`
- `rsync`: Already used in install.sh
- `shellcheck`: Already in pre-commit hooks

### Integration Points

- Install.sh integration: Call `copy_command_templates()` after `create_directories()`
- Validation integration: Call `validate_file_permissions()` on templates before copy
- Dev mode integration: Special handling in `create_directories()` for workflows symlink
- Logging integration: Use existing `print_message()` from `lib/installer-common/logging.sh`

### No New Dependencies Required

## 4. Effort & Complexity

### Estimated Complexity: MEDIUM (M)

### Effort Breakdown

- Template extraction (4 commands): 2-3 hours
  - Identify hardcoded paths in each command
  - Replace with template variables
  - Test templates parse correctly
- Install.sh function: 1-2 hours
  - Write `copy_command_templates()`
  - Implement backup logic
  - Add error handling
- Dev mode support: 1 hour
  - Symlink entire workflows directory
  - Document limitations
- Pre-commit validation: 1 hour
  - Add shellcheck for templates
  - Validate variable syntax
- Testing: 2-3 hours
  - Test normal install
  - Test dev mode install
  - Test upgrade scenario (existing commands)
  - Test on macOS and Linux
- Documentation: 1-2 hours
  - Document template variables
  - Document customization workflow
  - Update README

### Total Estimate: 8-12 hours

### Key Effort Drivers

- **Path Discovery**: Finding all hardcoded paths in 4 workflow commands
- **Testing Rigor**: Must test install, upgrade, dev mode, normal mode
- **Cross-Platform Testing**: Validate on both macOS and Linux
- **Edge Case Handling**: User customizations, partial installs, permission issues

### Risk Areas

- **Variable Completeness**: Missing a hardcoded path breaks command silently
- **Dev Mode Edge Cases**: User customizes command, then switches to dev mode
- **Backup Conflicts**: Multiple rapid installs create many .bak files
- **Template Syntax**: Using wrong delimiter in sed causes path corruption

## 5. Questions & Clarifications

### Technical Questions

- **Q1**: What variables are needed beyond `{{PROJECT_ROOT}}`, `{{AIDA_HOME}}`, `{{HOME}}`?
  - Action: Grep all 4 commands for paths, identify patterns
  - Recommendation: Start with these 3, add as needed
- **Q2**: Should templates validate that all variables were substituted?
  - Action: Add post-substitution check for remaining `{{*}}` patterns
  - Recommendation: Fail installation if variables remain unexpanded
- **Q3**: How to handle dev mode when user has customized commands?
  - Action: Detect conflict, prompt user: backup and use templates, or keep custom
  - Recommendation: Prevent dev mode if customizations detected

### Decisions Needed

- **D1**: Backup strategy for multiple reinstalls (accumulate .bak files vs single backup)?
  - Recommendation: Single `.bak` per file, overwrite on each install (simpler)
- **D2**: Should install.sh validate template variable syntax before substitution?
  - Recommendation: Yes, check all templates contain expected variables
- **D3**: Pre-commit hook scope: all templates or only workflows?
  - Recommendation: Validate all `templates/**/*.template` files (future-proof)

### Areas Needing Investigation

- **I1**: Current state of 4 workflow commands (do they exist, where, what paths?)
  - Action: Search `~/.claude/commands/workflows/` for existing implementations
  - Priority: HIGH - must understand current state before migration
- **I2**: Variable substitution edge cases (spaces, special chars in paths)
  - Action: Test sed pattern with problematic paths (`/path with spaces/`, `/path-with-$var/`)
  - Priority: MEDIUM - handle during implementation
- **I3**: Shellcheck compatibility with template files (does it parse `{{VAR}}`?)
  - Action: Run shellcheck on template with variables, check errors
  - Priority: MEDIUM - may need pre-processing or exclusion rules

## Implementation Pattern

### Template File Example

(`templates/commands/workflows/example.sh.template`):

```bash
#!/usr/bin/env bash
set -euo pipefail

# AIDA Framework - Example Workflow Command
readonly PROJECT_ROOT="{{PROJECT_ROOT}}"
readonly AIDA_HOME="{{AIDA_HOME}}"
readonly CLAUDE_DIR="${HOME}/.claude"

# Command logic using dynamic paths
workflow_state="${PROJECT_ROOT}/.claude/workflow-state.json"
```

### Install.sh Function

(add after line ~345):

```bash
#######################################
# Copy and configure command templates
# Globals:
#   SCRIPT_DIR, CLAUDE_DIR
# Arguments:
#   None
# Returns:
#   0 on success
#######################################
copy_command_templates() {
    print_message "info" "Installing workflow commands..."

    local template_dir="${SCRIPT_DIR}/templates/commands/workflows"
    local install_dir="${CLAUDE_DIR}/commands/workflows"

    # Create workflows directory
    mkdir -p "${install_dir}"
    chmod 755 "${install_dir}"

    # Process each template
    for template in "${template_dir}"/*.template; do
        [[ -f "$template" ]] || continue

        local cmd_name
        cmd_name=$(basename "${template}" .template)
        local target="${install_dir}/${cmd_name}"

        # Backup existing command
        if [[ -f "${target}" ]]; then
            cp "${target}" "${target}.bak"
            print_message "warning" "Backed up existing ${cmd_name} to ${cmd_name}.bak"
        fi

        # Substitute variables using | delimiter (handles paths with /)
        sed -e "s|{{PROJECT_ROOT}}|${SCRIPT_DIR}|g" \
            -e "s|{{AIDA_HOME}}|${AIDA_DIR}|g" \
            -e "s|{{HOME}}|${HOME}|g" \
            "${template}" > "${target}"

        # Validate substitution completed (no remaining {{*}})
        if grep -q '{{.*}}' "${target}"; then
            print_message "error" "Template substitution incomplete in ${cmd_name}"
            rm "${target}"
            return 1
        fi

        # Set secure permissions (user-only read/write)
        chmod 600 "${target}"
        print_message "success" "Installed ${cmd_name}"
    done

    print_message "success" "Workflow commands installed"
    echo ""
}
```

### Validation Hook

(`.pre-commit-config.yaml`):

```yaml
- repo: local
  hooks:
    - id: shellcheck-templates
      name: ShellCheck Command Templates
      entry: bash -c 'for f in "$@"; do shellcheck -x "$f" || exit 1; done' --
      language: system
      files: 'templates/commands/.*\.template$'
      types: [file]
```

## Security Checklist

- [ ] Templates contain no secrets (validated in pre-commit)
- [ ] Installed commands have 600 permissions (user-only)
- [ ] Template files have 644 permissions (read-only)
- [ ] sed uses `|` delimiter (prevents path injection)
- [ ] Validate all variables substituted (no remaining `{{*}}`)
- [ ] Backup preserves user customizations (non-destructive)
- [ ] Path validation uses existing `validate_path()` function
- [ ] No world-writable files created

## Conclusion

### Recommended Approach

Simple sed-based substitution integrated into existing install.sh modular structure. Leverages existing validation functions, follows established patterns, requires no new dependencies.

### Complexity

Medium - straightforward implementation but requires thorough testing across installation modes and platforms.

### Risk Mitigation

Use existing validation library, comprehensive testing, clear error messages, non-destructive backups.

### Next Steps

Investigate current state of 4 workflow commands (I1), identify all hardcoded paths, create templates, implement install function, validate across platforms.
