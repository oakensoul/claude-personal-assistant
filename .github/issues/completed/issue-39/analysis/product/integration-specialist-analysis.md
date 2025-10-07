---
title: "Integration Specialist Analysis - Issue #39"
issue: 39
analyst: "integration-specialist"
created: "2025-10-07"
status: "completed"
---

# Integration Specialist Analysis: Workflow Commands Template Migration

## 1. Domain-Specific Concerns

### Integration Architecture Impact

#### Current state

Workflow commands exist in user's installed `~/.claude/commands/` directory but are missing from the repository's templates directory.

#### Migration concerns

- Commands are deeply integrated with external tools (git, GitHub CLI, devops-engineer agent)
- Commands reference runtime variables that must resolve correctly after templating
- Installation flow must copy templates to user directory while preserving functionality
- Dev mode requires special handling (symlinks vs copies)

### External Tool Dependencies

#### Commands integrate with

- **Git operations**: Branch management, commits, pushes, status checks
- **GitHub CLI (gh)**: Issue management, PR creation, project board updates
- **Agents**: devops-engineer for git operations, technical-writer for docs
- **Configuration files**: workflow-config.json, workflow-state.json, .implementation-state.json
- **File system**: .github/issues/ directories, .time-tracking/ directories

#### Risk

Template variables must not break integration paths after installation.

### Runtime Variable Resolution

#### Commands use these runtime variables

- `${PROJECT_ROOT}` - Current project directory
- `${CLAUDE_CONFIG_DIR}` - User's ~/.claude/ directory
- Absolute paths (e.g., `/Users/oakensoul/Developer/...`) must be templated

#### Concern

Install script must replace hardcoded paths with runtime variables.

### Command Interdependencies

#### Command workflow chain

```text
/start-work → /expert-analysis → /implement → /open-pr → /cleanup-main
```

#### Integration points

- start-work creates .github/issues/in-progress/ structure
- implement reads analysis documents from issue directory
- open-pr moves issue folder to completed/ and creates PR
- cleanup-main restores stashed changes and updates main

#### Risk

Template migration must preserve workflow state management.

## 2. Stakeholder Impact

### Users Affected

#### New users installing AIDA

- Benefit: Receive latest workflow commands automatically
- Risk: None (fresh install)

#### Existing users upgrading

- Benefit: Can update commands by re-running install script
- Risk: Existing customizations in ~/.claude/commands/ may be overwritten
- Mitigation needed: Backup existing commands before overwriting

#### Contributors developing AIDA

- Benefit: Commands now version-controlled and part of repository
- Risk: Dev mode must handle commands correctly (symlinks)

### Value Provided

#### Consistency

All users get same command templates during installation.

#### Maintainability

Commands are version-controlled and documented in repository.

#### Customizability

Users can modify templates in ~/.claude/commands/ without affecting framework.

#### Upgradability

Re-running install.sh updates commands from templates.

### Risks and Downsides

#### Overwriting customizations

- Users who customized commands will lose changes on reinstall
- Mitigation: Document backup strategy, consider merge strategy

#### Template variable errors

- Incorrect variable substitution breaks commands
- Mitigation: Thorough testing of install script variable replacement

#### Dev mode complexity

- Commands must work when symlinked from repository
- Absolute paths in commands won't resolve correctly
- Mitigation: Ensure all paths use runtime variables

## 3. Questions & Clarifications

### Missing Information

#### Q1: Do workflow commands currently exist in the repository?

A: No. The commands exist in user's installed system (`~/.claude/commands/`) but not in the repository's `templates/commands/` directory. They need to be copied from the installed system to the repository.

#### Q2: Are there hardcoded absolute paths in the commands?

A: Yes. Example from `/implement` command shows hardcoded path:

```bash
cat /Users/oakensoul/Developer/oakensoul/claude-personal-assistant/.claude/workflow-state.json
```

This must be templated to use `${PROJECT_ROOT}` variable.

#### Q3: How should install.sh handle variable substitution?

A: Needs decision. Options:

- Simple copy (no substitution) - commands must use relative paths
- Variable substitution during install - replace placeholders
- Runtime variable resolution - Claude resolves at command execution

#### Q4: What happens to existing user customizations during reinstall?

A: Not specified. Needs decision on backup/merge strategy.

### Decisions Needed

#### Decision 1: Variable substitution strategy

Options:

- **Option A**: Commands use relative paths and environment variables (simpler)
- **Option B**: Install script performs variable substitution (more complex)
- **Option C**: Claude Code resolves runtime variables at execution (current behavior)

Recommendation: Option A (relative paths) for simplicity.

#### Decision 2: Existing command handling during install

Options:

- **Option A**: Always overwrite (simple, loses customizations)
- **Option B**: Backup then overwrite (preserves history)
- **Option C**: Three-way merge (complex, preserves customizations)
- **Option D**: Skip if exists (preserves customizations, misses updates)

Recommendation: Option B (backup then overwrite) with clear documentation.

#### Decision 3: Dev mode command handling

Options:

- **Option A**: Symlink commands directory (live editing)
- **Option B**: Copy commands even in dev mode (safer)
- **Option C**: Detect dev mode in commands, adjust paths

Recommendation: Option A (symlink) for consistency with other dev mode behavior.

### Assumptions to Validate

#### Assumption 1: Commands can use relative paths instead of absolute paths

- Validation needed: Test commands with relative paths in different contexts
- Impact: May require changes to command content

#### Assumption 2: Variable substitution is NOT needed (Claude resolves at runtime)

- Validation needed: Verify Claude Code resolves ${PROJECT_ROOT} correctly
- Impact: Simplifies install script

#### Assumption 3: Users rarely customize workflow commands

- Validation needed: Survey existing users
- Impact: Affects decision on overwrite vs merge strategy

#### Assumption 4: Dev mode users want live editing of commands

- Validation needed: Confirm with project owner
- Impact: Affects symlink strategy

## 4. Recommendations

### Recommended Approach

#### Phase 1: Extract commands from installed system to repository

1. Copy workflow commands from `~/.claude/commands/` to `templates/commands/`:
   - cleanup-main.md
   - implement.md
   - open-pr.md
   - start-work.md

2. Remove hardcoded absolute paths, replace with relative paths or runtime variables.

3. Add frontmatter documentation to each command template.

#### Phase 2: Update install.sh to handle command templates

1. Add command template installation logic (similar to existing template copying).

2. Implement backup strategy: if `~/.claude/commands/{name}.md` exists, back up to `~/.claude/commands.backup.{timestamp}/{name}.md`.

3. Copy command templates from `templates/commands/` to `~/.claude/commands/`.

4. In dev mode: symlink commands directory for live editing.

#### Phase 3: Documentation and testing

1. Document command template system in templates/commands/README.md.

2. Update install.sh documentation with command handling details.

3. Test installation flow (normal and dev mode).

4. Test reinstallation with existing commands (verify backup works).

### What Should Be Prioritized

#### Priority 1 (Critical): Extract commands and remove hardcoded paths

- Blockers: Cannot proceed without source commands
- Impact: Commands won't work if paths are absolute

#### Priority 2 (High): Update install.sh with backup strategy

- Risk: Users lose customizations without backup
- Impact: User experience and trust

#### Priority 3 (Medium): Dev mode symlink handling

- Use case: Contributors developing AIDA
- Impact: Development workflow efficiency

#### Priority 4 (Low): Documentation updates

- Timing: After implementation verified working
- Impact: User understanding and adoption

### What Should Be Avoided

#### Avoid 1: Overwriting user customizations without backup

- Reason: Destroys user work, breaks trust
- Alternative: Always create timestamped backups

#### Avoid 2: Complex variable substitution in install script

- Reason: Increases complexity, introduces bugs
- Alternative: Use relative paths and runtime variables

#### Avoid 3: Breaking existing installed commands during migration

- Reason: Users expect continuity
- Alternative: Test migration path thoroughly

#### Avoid 4: Hardcoding paths in template commands

- Reason: Won't work in different environments
- Alternative: Use ${PROJECT_ROOT} and relative paths

### Integration Best Practices

#### Backup strategy

```bash
if [[ -d "${CLAUDE_DIR}/commands" ]]; then
  backup_dir="${CLAUDE_DIR}/commands.backup.$(date +%Y%m%d_%H%M%S)"
  mv "${CLAUDE_DIR}/commands" "${backup_dir}"
  echo "Backed up existing commands to: ${backup_dir}"
fi
```

#### Path templating pattern

```bash
# Bad (absolute path)
cat /Users/oakensoul/Developer/oakensoul/claude-personal-assistant/.claude/workflow-state.json

# Good (relative path with runtime variable)
cat "${PROJECT_ROOT}/.claude/workflow-state.json"
```

#### Dev mode handling

```bash
if [[ "$DEV_MODE" == true ]]; then
  # Symlink commands for live editing
  ln -s "${SCRIPT_DIR}/templates/commands" "${CLAUDE_DIR}/commands"
else
  # Copy commands for normal install
  cp -r "${SCRIPT_DIR}/templates/commands" "${CLAUDE_DIR}/commands"
fi
```

## Success Metrics

### Installation success

Commands installed correctly in both normal and dev mode.

### Functionality preservation

All workflow commands execute correctly after templating.

### Backup reliability

Existing commands backed up 100% before overwrite.

### Path portability

Commands work in any project directory without modification.

### Dev mode usability

Live editing works for contributors in dev mode.

## Next Steps

1. **Extract commands**: Copy workflow commands from installed system to repository.

2. **Audit paths**: Identify and replace all hardcoded absolute paths.

3. **Update install.sh**: Add command installation logic with backup.

4. **Test migration**: Verify normal install, dev mode, and reinstall scenarios.

5. **Update documentation**: Document command template system and migration notes.

---

**Analysis completed**: Integration concerns identified and recommendations provided for safe command template migration.
