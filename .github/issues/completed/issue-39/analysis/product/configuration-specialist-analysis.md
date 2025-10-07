---
title: "Configuration Specialist Analysis - Issue #39"
issue: 39
analyst: "configuration-specialist"
date: "2025-10-07"
focus: "template system, configuration management, installation integration"
---

# Configuration Specialist Analysis - Issue #39

**Issue**: Add workflow commands to templates folder for user customization

**Focus Areas**: Template system design, configuration validation, installation integration, user customization patterns

## 1. Domain-Specific Concerns

### Template System Integration

#### Current State

- Templates exist at `/templates/commands/` with 8 commands
- Commands use YAML frontmatter with `name`, `description`, `args` schema
- Runtime variables supported: `${CLAUDE_CONFIG_DIR}`, `${PROJECT_ROOT}`, `${AIDA_HOME}`
- Installation copies templates to `~/.claude/commands/` during setup
- README references 4 commands that don't exist as templates yet

#### Configuration Concerns

- **Template Validation**: No schema validation for command templates
- **Variable Substitution**: Missing commands may use undocumented variables
- **Installation Integration**: `install.sh` doesn't currently copy command templates
- **Dev Mode Behavior**: Unclear how command templates work in `--dev` mode (symlinks vs copies)
- **Template Consistency**: Missing commands may not follow established frontmatter schema

### Variable Substitution Requirements

#### Known Variables

- `${CLAUDE_CONFIG_DIR}` - User configuration directory (`~/.claude/`)
- `${PROJECT_ROOT}` - Current project root
- `${AIDA_HOME}` - AIDA installation directory (`~/.aida/`)

#### Potential Variables in Missing Commands

- Workflow commands likely reference `workflow-config.json` path
- May need `${WORKFLOW_CONFIG}` or similar
- Branch naming, git operations may need repository-specific variables
- Time tracking may need developer name, email variables

### Installation Flow Gaps

#### Current Installation (`install.sh` lines 300-330)

- Copies framework files to `~/.aida/` (or symlinks in dev mode)
- Creates `~/.claude/` directory structure
- Does NOT copy command templates from `/templates/commands/` to `~/.claude/commands/`
- Generates only `CLAUDE.md` entry point

#### Missing Steps

- Command template copying logic
- Variable substitution during installation
- Template validation pre-copy
- Dev mode handling for command templates

## 2. Stakeholder Impact

### Affected Stakeholders

#### Users (Primary)

- Need workflow commands available immediately post-install
- Expect commands to work in both normal and dev modes
- Want to customize commands for their workflow
- Require clear documentation of available commands

#### Developers (Secondary)

- Need consistent template structure for new commands
- Require schema validation for command frontmatter
- Must understand dev mode behavior for command editing
- Need clear separation between framework templates and user customizations

#### Framework Maintainers (Tertiary)

- Must maintain backward compatibility with existing workflows
- Need to version control command templates
- Require clear upgrade path for command template changes
- Must ensure installation reliability

### Value Provided

#### For Users

- **Immediate Availability**: Commands work out-of-the-box post-install
- **Customization**: Can modify commands in `~/.claude/commands/` without affecting framework
- **Discoverability**: Template location matches existing patterns (agents, knowledge)
- **Consistency**: All commands follow same structure and conventions

#### For Framework

- **Maintainability**: Commands version-controlled in templates
- **Testability**: Can validate command templates before installation
- **Documentation**: Templates serve as authoritative command reference
- **Extensibility**: Users can create new commands following template patterns

### Risks and Downsides

#### Installation Complexity

- Additional installation steps increase failure surface area
- Variable substitution adds processing overhead
- Dev mode behavior may confuse users (when to symlink vs copy?)
- Template validation errors may block installation

#### User Confusion

- Unclear when to edit framework templates vs user copies
- Dev mode: editing `~/.aida/templates/` affects all installations
- Normal mode: framework updates don't propagate to user copies
- Variable substitution may fail silently with invalid paths

#### Backward Compatibility

- Existing users may have custom commands in `~/.claude/commands/`
- Installation may overwrite user customizations
- Need migration strategy for existing installations
- Missing commands may break documented workflows

#### Security Concerns

- Variable substitution from user input could inject paths
- Command templates execute arbitrary bash commands
- Malicious templates could compromise system
- Need template validation and sandboxing

## 3. Questions & Clarifications

### Missing Information

#### Command Specifications

- What are the EXACT specifications for the 4 missing commands?
- What arguments do `cleanup-main`, `implement`, `open-pr`, `start-work` accept?
- What workflows do these commands orchestrate?
- Do they delegate to agents? Which ones?
- What runtime variables do they require?

#### Installation Behavior

- Should `install.sh` copy ALL command templates or only a subset?
- How should dev mode handle command templates? Symlink or copy?
- Should installation validate command templates before copying?
- What happens on re-install with existing user commands?

#### Template Validation

- Should command templates be validated against a schema?
- What validation should run at installation time vs runtime?
- How should invalid templates be handled (skip, warn, error)?
- Should there be a `aida validate` command for user testing?

### Design Decisions Needed

#### Dev Mode Strategy

- **Option A**: Symlink `~/.claude/commands/` → `~/.aida/templates/commands/` (live editing)
- **Option B**: Copy templates even in dev mode (safer, isolated)
- **Option C**: Symlink individual commands, allow user additions
- **Recommendation**: Option B - copy commands in all modes for isolation

#### Variable Substitution Timing

- **Option A**: Substitute at install time (bake values into files)
- **Option B**: Substitute at runtime (dynamic resolution)
- **Option C**: Hybrid (install-time for system vars, runtime for dynamic)
- **Recommendation**: Option C - system paths at install, dynamic at runtime

#### Upgrade Strategy

- **Option A**: Overwrite user commands on upgrade (destructive)
- **Option B**: Skip existing commands, require manual migration
- **Option C**: Create `.new` files for updated commands, prompt user
- **Recommendation**: Option C - preserve user customizations, offer updates

#### Template Schema

- Should there be a formal JSON Schema for command templates?
- Should validation be enforced or advisory?
- Should invalid templates block installation?
- **Recommendation**: JSON Schema with warnings, non-blocking

### Assumptions to Validate

#### Installation Assumptions

- Users run `./install.sh` from repository root
- `templates/commands/*.md` exists at install time
- Target `~/.claude/commands/` directory is writable
- User has not manually created conflicting command files

#### Runtime Assumptions

- Claude Code reads commands from `~/.claude/commands/` at runtime
- Commands can access git, gh CLI, project files
- Workflow config exists at `~/.claude/workflow-config.json`
- User is in a git repository when running workflow commands

#### Validation Assumptions

- Command frontmatter uses valid YAML syntax
- Required fields (`name`, `description`) are present
- Variable placeholders use `${VAR_NAME}` syntax
- Commands are idempotent and safe to re-run

## 4. Recommendations

### Immediate Actions (Critical Path)

#### 1. Create Missing Command Templates

- Draft `cleanup-main.md`, `implement.md`, `open-pr.md`, `start-work.md`
- Follow existing frontmatter schema
- Document arguments, workflows, prerequisites
- Include variable placeholders for dynamic content
- Validate against existing command patterns

#### 2. Implement Installation Logic

- Add command template copying to `install.sh` (after line 330)
- Copy `templates/commands/*.md` → `~/.claude/commands/`
- Preserve existing user commands (no overwrite)
- Log which commands were installed
- Handle both normal and dev modes consistently

#### 3. Add Template Validation

- Create `validate_command_template()` function in `lib/installer-common/validation.sh`
- Check required frontmatter fields (`name`, `description`, `args`)
- Validate YAML syntax
- Check for undefined variable placeholders
- Log validation warnings, don't block installation

### Short-Term Improvements (Phase 2)

#### 1. Variable Substitution Engine

- Create `lib/installer-common/template-processor.sh`
- Implement `process_template()` for variable substitution
- Substitute system variables at install time (`${AIDA_HOME}`, `${CLAUDE_CONFIG_DIR}`)
- Document available variables in template comments
- Add validation for unresolved variables

#### 2. Command Schema Definition

- Create `templates/commands/SCHEMA.json` (JSON Schema)
- Define required and optional frontmatter fields
- Specify argument structure (required, description)
- Document validation rules
- Provide schema validation tooling

#### 3. Upgrade Migration

- Detect existing commands on re-install
- Compare template versions (add `version` to frontmatter)
- Create `*.new` files for updated commands
- Prompt user to review changes
- Preserve user customizations

### Long-Term Enhancements (Phase 3)

#### 1. Command Validation CLI

```bash
aida validate commands          # Validate all user commands
aida validate commands --template  # Validate framework templates
aida commands list             # List installed commands
aida commands update           # Update commands from framework
```

#### 2. Template Hot-Reload

- Watch `~/.claude/commands/` for changes
- Validate commands on save
- Provide instant feedback on invalid templates
- Support iterative command development

#### 3. Command Versioning

- Add `version` field to command frontmatter
- Track installed command versions
- Detect framework updates
- Offer opt-in command upgrades

### What to Prioritize

#### Phase 1 (Issue #39 - This PR)

1. Create 4 missing command template files
2. Add command copying to `install.sh`
3. Add basic frontmatter validation
4. Update documentation with new commands
5. Test installation (normal and dev modes)

#### Phase 2 (Post-v0.1.0)

1. Implement variable substitution engine
2. Create command schema definition
3. Add upgrade migration logic
4. Enhance validation with helpful errors

#### Phase 3 (Future)

1. Command validation CLI
2. Template hot-reload
3. Command versioning system
4. Template marketplace (community commands)

### What to Avoid

#### Anti-Patterns

- **Don't** symlink commands in dev mode (breaks user isolation)
- **Don't** overwrite user commands without backup
- **Don't** bake all variables at install time (loses flexibility)
- **Don't** block installation on validation warnings
- **Don't** require schema validation for user-created commands

#### Security Risks

- **Don't** trust user input in variable substitution
- **Don't** execute commands during template validation
- **Don't** allow path traversal in variable values
- **Don't** run templates with elevated privileges

#### Complexity Traps

- **Don't** implement custom template language (use simple substitution)
- **Don't** add conditional logic to templates (keep declarative)
- **Don't** create template inheritance hierarchy (keep flat)
- **Don't** support dynamic template generation (security risk)

## Summary

### Critical Configuration Issues

1. **Installation Gap**: No command template copying logic in `install.sh`
2. **Missing Templates**: 4 workflow commands documented but not implemented
3. **No Validation**: Command templates not validated before installation
4. **Variable Substitution**: No engine for resolving template variables
5. **Dev Mode Ambiguity**: Unclear how command templates behave in dev mode

### Recommended Approach

#### For Issue #39 (Minimal Viable Solution)

1. Create 4 missing command template files with proper frontmatter
2. Add simple copy logic to `install.sh` after directory creation
3. Copy ALL `templates/commands/*.md` → `~/.claude/commands/`
4. Skip existing files (no overwrite)
5. Add basic YAML frontmatter validation (warn on errors)
6. Test normal and dev mode installations
7. Update README with complete command documentation

#### Post-v0.1.0 (Robust Solution)

1. Implement variable substitution engine
2. Create JSON Schema for command validation
3. Add upgrade migration with version comparison
4. Build `aida validate` CLI command
5. Enhance error messages with fix suggestions
6. Support command template hot-reload

### Success Criteria

#### Installation

- ✅ All command templates copied to `~/.claude/commands/`
- ✅ Existing user commands preserved
- ✅ Both normal and dev modes work correctly
- ✅ Installation completes without errors
- ✅ Commands available immediately post-install

#### Validation

- ✅ Command frontmatter validated (YAML syntax, required fields)
- ✅ Helpful error messages for validation failures
- ✅ Warnings don't block installation
- ✅ Users can validate custom commands

#### Documentation

- ✅ README accurately describes all available commands
- ✅ Command templates self-document with examples
- ✅ Installation flow documented with command handling
- ✅ Variable substitution documented for users

#### User Experience

- ✅ Commands work out-of-the-box (no additional configuration)
- ✅ Users can customize commands without breaking framework
- ✅ Clear separation between framework templates and user copies
- ✅ Upgrade path preserves user customizations

---

**Key Insight**: This issue is about establishing a robust template-to-configuration pipeline. The immediate goal is functionality (copy templates), but the long-term goal is maintainability (validation, versioning, migration). Solve for today's problem (missing commands) while designing for tomorrow's needs (template system evolution).
