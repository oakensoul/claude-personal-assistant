---
title: "DevOps Engineer Analysis: Add Workflow Commands to Templates"
issue: "#39"
analyst: "devops-engineer"
created: "2025-10-07"
status: "draft"
---

# DevOps Engineer Analysis: Workflow Command Templates

## 1. Implementation Approach

### Recommended Strategy

#### Installation Automation

- Extend existing `install.sh` with `copy_command_templates()` function
- Use simple `sed` for variable substitution (zero dependencies, platform-agnostic)
- Implement atomic operations with temp files + mv for reliability
- Exit on first failure with clear error messages (`set -euo pipefail` already present)
- Log all operations for troubleshooting

#### Dev Mode vs Normal Mode

- Normal mode: Copy `.template` files to `~/.claude/commands/workflows/`, perform substitution, set 600 permissions
- Dev mode: Create directory-level symlink `~/.claude/commands/workflows/ -> ~/.aida/templates/commands/workflows/`
- Dev mode challenge: Cannot write substituted files to symlinked location (would modify templates)
- Recommendation: Dev mode should copy first install, then user manually edits templates directly

#### Backup Mechanism

- Check if `~/.claude/commands/workflows/*.sh` exists before copying
- Backup existing files to `*.bak.YYYYMMDD_HHMMSS` timestamp format
- Log backup location to stdout for user awareness
- Never overwrite `.bak` files (fail if backup destination exists)
- Preserve original file permissions during backup

### Technical Implementation Pattern

```bash
copy_command_templates() {
    local template_dir="${AIDA_DIR}/templates/commands/workflows"
    local install_dir="${CLAUDE_DIR}/commands/workflows"
    local backup_timestamp
    backup_timestamp=$(date +%Y%m%d_%H%M%S)

    # Ensure target directory exists
    mkdir -p "${install_dir}"

    # Process each template
    for template in "${template_dir}"/*.template; do
        [[ -e "${template}" ]] || continue  # Skip if no templates

        local cmd_name
        cmd_name=$(basename "${template}" .template)
        local target="${install_dir}/${cmd_name}"

        # Backup if exists
        if [[ -f "${target}" ]]; then
            local backup="${target}.bak.${backup_timestamp}"
            if [[ -f "${backup}" ]]; then
                print_message "error" "Backup already exists: ${backup}"
                return 1
            fi
            cp -p "${target}" "${backup}"
            print_message "warning" "Backed up: ${cmd_name} -> ${backup}"
        fi

        # Substitute variables atomically
        local temp_file="${target}.tmp.$$"
        sed -e "s|{{AIDA_HOME}}|${AIDA_DIR}|g" \
            -e "s|{{CLAUDE_DIR}}|${CLAUDE_DIR}|g" \
            -e "s|{{HOME}}|${HOME}|g" \
            "${template}" > "${temp_file}"

        # Validate output (basic check)
        if [[ ! -s "${temp_file}" ]]; then
            print_message "error" "Template substitution failed for ${cmd_name}"
            rm -f "${temp_file}"
            return 1
        fi

        # Atomic move
        mv "${temp_file}" "${target}"
        chmod 600 "${target}"
        print_message "success" "Installed: ${cmd_name}"
    done
}
```

## 2. Technical Concerns

### Installation Reliability

#### Atomicity

- Use temp files + `mv` for atomic writes (prevents partial writes on failure)
- Process templates sequentially (fail fast on first error)
- Validate template existence before processing (`[[ -e "${template}" ]]`)
- Check for write permissions before starting (`mkdir -p` will fail if no permissions)

#### Error Handling

- Return non-zero on any failure (already using `set -euo pipefail`)
- Provide actionable error messages with file paths
- Log all operations for post-mortem debugging
- Do not leave temporary files on failure (cleanup in trap handler)

### Idempotency Concerns

#### Multiple Runs

- First run: Install templates to `~/.claude/commands/workflows/`
- Subsequent runs: Backup existing, install new version
- Result: User gets latest templates, old version preserved
- Issue: Backup files accumulate (`.bak.TIMESTAMP` for each run)

#### Idempotency Strategy

- Check if installed file matches template (diff after substitution)
- Skip installation if identical (log "already up to date")
- Only backup if files differ
- Alternative: Always backup for safety, document cleanup procedure

### Rollback Strategies

#### Automatic Rollback

- Not recommended: Too complex, error-prone
- User can manually restore from `.bak` files
- Document rollback procedure in installation docs

#### Manual Rollback

```bash
# Restore from backup
cd ~/.claude/commands/workflows/
for backup in *.bak.20251007_*; do
    original="${backup%.bak.*}"
    mv "$backup" "$original"
done
```

#### Future Enhancement

- Track installed version in `~/.claude/config/installed-commands.json`
- Compare versions on upgrade, only backup if version changed
- Provide `aida rollback-commands` CLI tool

### CI/CD Implications

#### Pre-commit Hook Updates

- Add shellcheck validation for `templates/commands/**/*.template` files
- Validate template variable syntax (all `{{VAR}}` have substitution rule)
- Check for hardcoded paths (`/Users/`, `/home/`, absolute paths)
- Validate no secrets in templates (gitleaks already runs)

#### GitHub Actions Updates

- Update `test-installation.yml` to verify command installation
- Add test case: Check `~/.claude/commands/workflows/*.sh` files exist
- Validate variable substitution occurred (no `{{.*}}` in installed files)
- Test dev mode symlink creation
- Test backup mechanism on re-install

#### Workflow Additions

```yaml
- name: Verify command installation
  run: |
    # Check commands exist
    test -d ~/.claude/commands/workflows || (echo "Commands directory not created" && exit 1)

    # Check specific commands
    for cmd in cleanup-main.sh create-agent.sh create-command.sh create-issue.sh; do
      test -f ~/.claude/commands/workflows/$cmd || (echo "Missing: $cmd" && exit 1)
    done

    # Validate no template variables remain
    if grep -r '{{.*}}' ~/.claude/commands/workflows/; then
      echo "ERROR: Unsubstituted variables found"
      exit 1
    fi

- name: Test dev mode symlinks
  run: |
    rm -rf ~/.aida ~/.claude ~/CLAUDE.md
    ./install.sh --dev <<< "testassistant\n1\n"
    test -L ~/.aida || (echo "Dev mode: ~/.aida should be symlink" && exit 1)
```

#### Build Performance

- Template processing adds ~1-2 seconds to installation
- Minimal impact on CI/CD pipeline duration
- No external dependencies (sed is standard)

## 3. Dependencies & Integration

### Install Script Modifications

#### Required Changes

- Add `copy_command_templates()` function after `create_directories()`
- Call from `main()` after directory creation, before summary
- Add template directory validation (fail if missing)
- Update `DEV_MODE` handling (document symlink limitations)

#### Integration Points

- Uses existing `AIDA_DIR`, `CLAUDE_DIR` globals
- Uses existing `print_message()` logging function
- Requires `SCRIPT_DIR` to locate templates
- No new dependencies (sed, date, basename, dirname are standard)

### Testing Requirements

#### Unit Tests (Manual)

- Normal install: Verify commands copied and substituted
- Dev mode: Document expected behavior (copy on first install)
- Re-install: Verify backup created with timestamp
- Missing templates: Verify graceful failure with error message
- Permission denied: Verify clear error message

#### Integration Tests (CI)

- macOS: Verify installation on macOS runner
- Linux: Verify installation on Ubuntu 22.04, 20.04, Debian 12
- WSL: Verify installation on Windows WSL
- Dev mode: Verify symlink creation and command installation
- Upgrade simulation: Install, modify command, reinstall, verify backup

#### Pre-commit Validation

- Add hook to validate template syntax: `^templates/commands/.*\.template$`
- Run shellcheck on templates (ignore unset variables from substitution)
- Check for hardcoded paths using regex patterns
- Validate all variables have substitution rules in install.sh

### Platform Compatibility

#### macOS

- Bash 3.2 compatibility required (default macOS bash)
- GNU sed not required (use portable sed syntax)
- Test pattern: `sed -e 's|pattern|replacement|g'` (pipe delimiter, not slash)
- Path handling: Use `${HOME}` not `~` for portability

#### Linux

- Bash 4.x+ available on all modern distros
- GNU sed available by default
- File permissions work identically to macOS
- Tested on: Ubuntu 22.04, 20.04, Debian 12

#### WSL

- Same as Linux (Ubuntu-based WSL most common)
- Windows path translation handled by WSL
- Verify permissions work correctly (WSL mounts may have different defaults)

#### Compatibility Validation

```bash
# Portable sed syntax (works on macOS and Linux)
sed -e "s|{{VAR}}|${VALUE}|g"  # Pipe delimiter
sed -e 's/pattern/replacement/g'  # Slash delimiter (no paths)

# Avoid GNU-specific flags
sed -i.bak 's/old/new/g' file  # macOS requires extension with -i
sed -i'' 's/old/new/g' file     # Linux allows empty extension

# Solution: Use temp file + mv (portable)
sed 's/old/new/g' file > file.tmp && mv file.tmp file
```

## 4. Effort & Complexity

### Estimated Complexity: Medium (M)

#### Justification

- Installation automation is straightforward (extend existing script)
- Variable substitution is simple (sed one-liners)
- Backup logic is well-understood pattern
- Pre-commit validation requires custom hook script
- CI/CD updates require test case additions
- Documentation updates needed for users and contributors

### Key Effort Drivers

#### Primary Drivers (70% of effort)

- Pre-commit hook script for template validation (new script, testing required)
- CI/CD test case additions (verify installation, backup, variable substitution)
- Documentation updates (user customization guide, contributor guide, security guide)
- Testing across platforms (macOS, Linux, WSL, multiple distros)

#### Secondary Drivers (30% of effort)

- install.sh function implementation (straightforward, ~100 lines)
- Template creation (extract existing commands, add {{VAR}} markers)
- Backup mechanism testing (edge cases: permissions, existing backups)
- Dev mode behavior documentation (clarify symlink limitations)

### Risk Areas

#### High Risk

- Variable substitution errors causing broken commands (mitigated by CI tests)
- Backup failures leaving user with no working commands (mitigated by atomic operations)
- Platform-specific sed differences (mitigated by portable syntax, multi-platform tests)
- Pre-commit hook false positives blocking development (mitigated by thorough testing)

#### Medium Risk

- Dev mode confusion (users expect symlinks, get copies) - requires clear docs
- Backup file accumulation filling disk - document cleanup procedure
- Idempotency edge cases (multiple rapid reinstalls) - test thoroughly

#### Low Risk

- Performance impact on installation (1-2 seconds negligible)
- Security exposure from templates (gitleaks already scans, 644 permissions safe)

## 5. Questions & Clarifications

### Technical Questions

#### Variable Substitution Scope

- Q: What variables are required? `{{AIDA_HOME}}`, `{{CLAUDE_DIR}}`, `{{HOME}}`?
- A: VALIDATE - Review all 4 workflow commands to identify all hardcoded paths
- Action: Audit existing commands for paths to extract

#### Dev Mode Behavior

- Q: Should dev mode copy commands on install, or symlink and require manual template editing?
- A: DECISION NEEDED - Recommend copy on install, docs explain editing templates directly
- Alternative: Symlink workflows directory, document cannot customize without breaking templates

#### Idempotency Strategy

- Q: Skip installation if file unchanged, or always backup for safety?
- A: RECOMMEND - Always backup for safety, document cleanup procedure
- Alternative: Diff before install, skip if identical (more complex, fragile)

#### Shellcheck Configuration

- Q: How to handle template variables in shellcheck? Variables are unset until substitution.
- A: Options: (1) Disable SC2154 for templates, (2) Add dummy variable declarations, (3) Skip shellcheck on templates
- RECOMMEND - Disable SC2154 (unbound variable) for .template files only

### Decisions Needed

#### Template File Extension

- Q: Use `.template` suffix or `.sh.template` full extension?
- A: PRD recommends `.sh.template` for clarity (e.g., `cleanup-main.sh.template`)
- Decision: Approve PRD recommendation (better clarity, easier glob patterns)

#### Backup Retention Policy

- Q: Auto-delete old backups after N days, or leave for user to clean?
- A: RECOMMEND - Leave for user, document cleanup procedure
- Rationale: Safety first, disk space is cheap, user may need old versions

#### Pre-commit Hook Scope

- Q: Validate all templates or only workflow commands?
- A: RECOMMEND - Validate all templates (`templates/**/*.template`)
- Rationale: Establishes pattern for future template additions (agents, knowledge, etc.)

### Investigation Areas

#### Existing Command Inventory

- Action: List all files in `~/.claude/commands/workflows/` to confirm scope
- Expected: 4 commands per PRD, need to verify actual count
- If mismatch: Update PRD with correct inventory

#### Variable Audit

- Action: Search all workflow commands for hardcoded paths
- Pattern: `/Users/`, `/home/`, absolute paths starting with `/`
- Output: List of required template variables

#### Platform-Specific Sed Testing

- Action: Test sed substitution syntax on macOS (BSD sed) and Linux (GNU sed)
- Validate: Pipe delimiter works on both, temp file approach works
- Edge case: Special characters in paths (spaces, quotes, backslashes)

## DevOps Recommendations

### Priority Implementation Order

#### Phase 1: Core Automation (P0)

1. Implement `copy_command_templates()` in install.sh
2. Add backup mechanism with timestamp
3. Implement variable substitution (sed-based)
4. Set secure permissions (600 for commands)

#### Phase 2: Validation (P1)

1. Add pre-commit hook for template validation
2. Update CI/CD workflows with command verification tests
3. Test across all platforms (macOS, Linux, WSL)
4. Document rollback procedure

#### Phase 3: Polish (P2)

1. Add idempotency check (skip if unchanged)
2. Improve error messages with troubleshooting hints
3. Add `aida validate-commands` CLI tool (future)
4. Implement command version tracking (future)

### CI/CD Pipeline Enhancements

#### Required Updates

- `.github/workflows/test-installation.yml`: Add command verification steps
- `.pre-commit-config.yaml`: Add template validation hook
- `scripts/validate-templates.sh`: Extend for command template validation

#### New Test Cases

- Verify commands installed to correct location
- Verify no unsubstituted variables (`{{.*}}`)
- Verify file permissions (600 for commands)
- Verify backup creation on re-install
- Verify dev mode behavior (document expected vs actual)

### Security Considerations

#### File Permissions

- Templates: 644 (world-readable, templates are public)
- Installed commands: 600 (user-only, may contain runtime secrets in comments)
- Backup files: Inherit original permissions (600)

#### Secret Scanning

- Gitleaks already scans all files (including templates)
- Pre-commit hook should validate no hardcoded secrets
- Document: Commands should read secrets from environment or config files

#### Input Validation

- Template variables validated by pre-commit hook
- No user input in variable substitution (only system paths)
- Sed patterns are static (no injection risk)

### Monitoring & Observability

#### Installation Logging

- Log each command installed (name, source template, target path)
- Log backups created (filename, timestamp)
- Log variable substitution (before/after for debugging)
- Log failures with context (file, operation, error message)

#### Post-Install Verification

- Count installed commands, compare to expected
- Verify no template variables remain (`grep -r '{{.*}}'`)
- Check file permissions match expected (600)
- Report summary to user (X commands installed, Y backed up)

## Complexity Breakdown

| Area | Complexity | Effort | Risk |
|------|-----------|--------|------|
| install.sh function | Low | 2-3 hours | Low |
| Variable substitution | Low | 1 hour | Low |
| Backup mechanism | Low | 2 hours | Medium |
| Pre-commit hook | Medium | 4-6 hours | Medium |
| CI/CD updates | Medium | 4-6 hours | Low |
| Platform testing | Medium | 6-8 hours | High |
| Documentation | Medium | 4-6 hours | Low |
| **Total** | **Medium** | **23-32 hours** | **Medium** |

## Success Metrics

- 100% of workflow commands installed successfully on all platforms
- Zero unsubstituted variables in installed commands
- 100% backup success rate on re-install
- Zero permission-related failures
- All CI/CD tests passing on macOS, Linux, WSL
- Installation time increase < 5 seconds
- Zero security vulnerabilities (gitleaks, shellcheck clean)
