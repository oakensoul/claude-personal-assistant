---
title: "PRD: Add Workflow Commands to Templates Folder"
issue: "#39"
created: "2025-10-07"
status: "draft"
---

# Product Requirements Document: Workflow Command Templates

## Executive Summary

Move workflow commands from installed system (`~/.claude/commands/workflows/`) to public templates folder, enabling users to discover, customize, and version control workflow automation. Currently, 4 workflow commands exist only in installed systems with no template source, no installation process, and hardcoded absolute paths preventing portability. This change establishes commands as first-class framework components with proper installation, customization, and security controls.

## Stakeholder Analysis

### End Users (AIDA Installers)

- **Concerns**: Cannot customize workflow commands, no visibility into what commands are available, hardcoded paths break on their systems
- **Priorities**: Easy discovery, safe customization without breaking functionality, clear documentation
- **Recommendations**: Template-based installation with variable substitution, backup existing commands, installation transparency

### Framework Maintainers

- **Concerns**: No source of truth for commands, installation script incomplete, security risks from command injection and secret exposure
- **Priorities**: Maintainable command distribution, validation pipeline, secure defaults
- **Recommendations**: Commands in templates/ as authoritative source, validation in pre-commit hooks, secure file permissions (644 templates, 600 installed commands)

### Contributors

- **Concerns**: Unclear how to add new commands, no testing framework, complex dependencies between commands
- **Priorities**: Clear contribution path, validation tooling, dev mode support
- **Recommendations**: Template schema, validation CLI tool, symlinks in dev mode for live editing

## Requirements

### Functional Requirements

- Move 4 workflow commands from installed system to `templates/commands/workflows/` as authoritative source
- Update `install.sh` to copy command templates to `~/.claude/commands/workflows/` during installation
- Implement variable substitution to replace hardcoded paths with dynamic values (e.g., `{{PROJECT_ROOT}}`, `{{AIDA_HOME}}`)
- Preserve existing user commands during installation (backup to `.bak` if conflicts exist)
- Support dev mode with symlinks from `~/.aida/` to development directory for live command editing
- Create `.template` extension convention for template files (e.g., `workflow-init.sh.template`)
- Add command validation to pre-commit hooks (shellcheck, variable substitution validation)

### Non-Functional Requirements

#### Security

- Command templates must have 644 permissions (read-only)
- Installed commands must have 600 permissions (user-only read/write)
- No secrets in template files
- Input validation in all commands to prevent injection attacks
- Secure handling of GitHub tokens and API credentials

#### Usability

- Installation must show which commands are being installed
- Conflicts must prompt user for resolution (keep existing, use new, backup)
- Documentation must explain customization workflow
- Template variables must be clearly documented

#### Performance

- Installation must complete in under 10 seconds for command copying
- Variable substitution must not require external dependencies

#### Maintainability

- Single source of truth for command content (templates/)
- Validation prevents broken commands from being committed
- Clear separation between template (templates/) and instance (~/.claude/)

## Success Criteria

- All 4 workflow commands exist in `templates/commands/workflows/` with no hardcoded paths
- `install.sh` successfully copies and configures commands on fresh install
- `install.sh --dev` creates symlinks for live editing
- Pre-commit hooks catch invalid command templates before commit
- Documentation explains customization workflow with examples
- Zero security vulnerabilities in command templates (shellcheck clean, no secrets)
- User commands are preserved during reinstall/upgrade

## Open Questions

### Variable Substitution Strategy

- Q: Use simple string replacement or templating engine (envsubst, mustache)?
- A: DECISION NEEDED - Recommend simple `sed` replacement for zero dependencies
- Q: What variables are needed? (`{{PROJECT_ROOT}}`, `{{AIDA_HOME}}`, `{{USER}}`, `{{HOME}}`?)
- A: VALIDATE - Review all 4 commands to identify required variables

### Conflict Resolution

- Q: How to handle user-modified commands during upgrade?
- A: DECISION NEEDED - Options: (1) Always backup user version, (2) Prompt user, (3) Three-way merge
- Recommendation: Backup to `.bak` and install new version, log warning

### Template Validation

- Q: How comprehensive should validation be?
- A: VALIDATE - Start with shellcheck + variable syntax check, add schema in Phase 2
- Q: Should validation run on every commit or only on template changes?
- A: DECISION NEEDED - Recommend pre-commit hook on templates/* files only

### Dev Mode Behavior

- Q: Should dev mode symlink commands individually or entire workflows directory?
- A: DECISION NEEDED - Recommend directory-level symlink for simplicity
- Q: What happens if user has customized commands when entering dev mode?
- A: VALIDATE - Behavior needs to be clearly documented or prevented

## Recommendations

### Recommended Approach

#### Phase 1: Core Functionality (MVP for v0.2)

1. Extract 4 workflow commands from installed system to `templates/commands/workflows/`
2. Remove hardcoded paths, replace with template variables (`{{PROJECT_ROOT}}`, etc.)
3. Update `install.sh` to copy templates and perform variable substitution
4. Add basic validation (shellcheck, variable syntax check) to pre-commit hooks
5. Set correct file permissions (644 templates, 600 installed)
6. Document customization workflow

#### Phase 2: Enhanced Validation (Post-MVP)

- Command template schema (YAML describing expected structure)
- Dependency validation (detect command chain issues)
- Integration testing for command workflows

#### Phase 3: Advanced Features (Future)

- CLI validation tool (`aida validate-commands`)
- Hot-reload for command changes in dev mode
- Command versioning and migration system

### MVP Scope

#### Include in v0.2

- All 4 workflow commands as templates
- Basic variable substitution (PROJECT_ROOT, AIDA_HOME, HOME)
- install.sh command copying logic
- Backup strategy for existing commands
- Pre-commit shellcheck validation
- Basic customization documentation

#### Defer to Later

- Command schema and advanced validation
- Three-way merge for conflicts
- Hot-reload in dev mode
- CLI validation tool
- Command dependency graph

### Priority Recommendations

#### P0 (Must Have)

- Extract commands to templates/
- Remove hardcoded paths
- Update install.sh
- Set secure file permissions

#### P1 (Should Have)

- Backup existing commands
- Pre-commit validation
- Customization documentation

#### P2 (Nice to Have)

- Dev mode symlinks
- Advanced validation
- Command schema

## Technical Considerations

### File Structure

```text
templates/
├── commands/
│   └── workflows/
│       ├── cleanup-main.sh.template
│       ├── create-agent.sh.template
│       ├── create-command.sh.template
│       ├── create-issue.sh.template
│       ├── expert-analysis.sh.template
│       ├── generate-docs.sh.template
│       ├── implement.sh.template
│       ├── open-pr.sh.template
│       ├── publish-issue.sh.template
│       ├── start-work.sh.template
│       ├── track-time.sh.template
│       └── workflow-init.sh.template
```

### Variable Substitution Pattern

```bash
# In template
WORKFLOW_STATE="{{PROJECT_ROOT}}/.claude/workflow-state.json"

# After substitution
WORKFLOW_STATE="/Users/oakensoul/Developer/oakensoul/claude-personal-assistant/.claude/workflow-state.json"
```

### Installation Logic

```bash
# In install.sh
copy_command_templates() {
    local template_dir="${SCRIPT_DIR}/templates/commands/workflows"
    local install_dir="${CLAUDE_DIR}/commands/workflows"

    for template in "${template_dir}"/*.template; do
        local cmd_name=$(basename "${template}" .template)
        local target="${install_dir}/${cmd_name}"

        # Backup existing
        if [[ -f "${target}" ]]; then
            cp "${target}" "${target}.bak"
            echo "Backed up existing ${cmd_name} to ${cmd_name}.bak"
        fi

        # Substitute variables
        sed -e "s|{{PROJECT_ROOT}}|${PROJECT_ROOT}|g" \
            -e "s|{{AIDA_HOME}}|${AIDA_HOME}|g" \
            -e "s|{{HOME}}|${HOME}|g" \
            "${template}" > "${target}"

        chmod 600 "${target}"
    done
}
```

## Security Checklist

- [ ] No secrets in template files
- [ ] Input validation prevents command injection
- [ ] File permissions set correctly (644 templates, 600 commands)
- [ ] GitHub tokens handled securely
- [ ] Workflow state files not world-readable
- [ ] PII scrubbing in command output documentation
- [ ] Auto-commit feature documented with security warnings

## Documentation Requirements

### User Documentation

- How to customize workflow commands
- What template variables are available
- How to safely modify commands without breaking workflows
- What happens during upgrade/reinstall

### Contributor Documentation

- How to add new command templates
- Template variable conventions
- Validation requirements
- Testing workflow commands

### Security Documentation

- Secret management in commands
- Secure file permissions
- Input validation requirements
- PII handling guidelines
