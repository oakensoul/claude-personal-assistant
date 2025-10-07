---
analyst: "Shell Systems & UX Designer"
perspective: "CLI/Shell UX, Command Discoverability, Installation Experience"
date: "2025-10-07"
issue: 39
---

# Shell Systems & UX Designer Analysis: Issue #39

## 1. Domain-Specific Concerns

### UX/Usability Concerns

#### Command Discoverability Gap

- Templates directory currently has 8 commands, but 4 critical workflow commands are missing
- Users examining templates/ won't see the full workflow command set
- No clear indicator that additional workflow commands exist elsewhere
- Creates confusion about what's available vs. what's installed

#### Installation Transparency

- Users can't preview workflow commands before installation
- No ability to understand what cleanup-main, implement, open-pr, start-work do without installing first
- Templates serve dual purpose: documentation and installation source
- Missing templates break this documentation-first principle

#### Customization Friction

- Current workflow commands in ~/.claude/commands/ were created manually or by another process (not during install.sh)
- Users wanting to customize these commands must edit live files, not templates
- No "template customization before install" workflow
- Breaks the expected pattern: review template → customize if needed → install

### CLI/Shell Constraints

#### Installation Consistency

- install.sh currently copies no command templates (verified by reading script)
- Script only creates directory structure and CLAUDE.md, doesn't populate commands
- Existing 8 template commands aren't being installed either
- Major gap in installation completeness

#### Version Control Impact

- Workflow commands in ~/.claude/commands/ aren't version controlled
- Users can't track changes or updates to workflow commands over time
- Template-based approach enables git-based workflow command evolution
- Missing opportunity for semantic versioning of commands

#### Dev Mode Implications

- --dev mode uses symlinks for live editing
- Should workflow commands be symlinked (live updates) or copied (user customization)?
- No clear policy on which files should be symlinked vs. copied
- Tension between "framework updates automatically" vs. "user customizations preserved"

## 2. Stakeholder Impact

### Who Is Affected

#### End Users (Primary)

- Can't preview workflow commands before installing
- Can't customize commands before first use
- Must manually edit live commands (higher risk of errors)
- Unclear which commands are "framework provided" vs. "user created"

#### AIDA Framework Contributors

- No standardized location for workflow command development
- Can't distribute command updates through template mechanism
- Difficult to maintain command documentation in sync with code

#### Documentation Writers

- templates/commands/README.md is incomplete (missing 4 commands)
- Can't reference full command set in one location
- Feature development workflow examples reference commands not in templates

### Value Provided

#### For Users

- Full visibility into all workflow commands before installation
- Ability to customize commands to match their workflow preferences
- Clear separation: templates (what AIDA provides) vs. ~/.claude/commands/ (what you're using)
- Git-trackable workflow command evolution

#### For Framework

- Single source of truth for all workflow commands
- Consistent installation experience
- Easier command updates and distribution
- Better alignment with existing template patterns

### Risks and Downsides

#### Migration Complexity

- Existing users already have workflow commands in ~/.claude/commands/
- Moving templates could cause confusion about which version is "correct"
- Need clear upgrade path: preserve customizations vs. adopt new templates

#### Customization vs. Updates Tension

- If users customize templates, how do they receive framework updates?
- Copy-based install means user edits override framework improvements
- Symlink-based install means user edits get overwritten on framework updates
- Need strategy for "merge user customizations with framework updates"

#### Installation Bloat

- Adding 4 more command templates increases installation footprint
- Each command is 7-46KB (cleanup-main: 11KB, implement: 46KB, open-pr: 26KB, start-work: 13KB)
- Total: ~96KB additional template data
- Minimal impact but worth noting for completeness

## 3. Questions & Clarifications

### Missing Information

#### Command Origin

- How did cleanup-main, implement, open-pr, start-work get into ~/.claude/commands/?
- Were they manually created during development?
- Created by a different installation process?
- Part of SlashCommand tool's embedded commands?

#### Template vs. Installed Command Policy

- Should templates be copied (allowing customization) or symlinked (receiving updates)?
- What's the policy for other template types (agents, knowledge)?
- Should workflow commands behave differently than non-workflow commands?

#### Existing User Migration

- What happens to users who already have these commands?
- Should install.sh detect existing commands and preserve them?
- Should there be an "update templates" command to refresh from framework?

### Decisions Needed

#### Installation Strategy

- Copy templates to ~/.claude/commands/ (current approach for other files)?
- Symlink templates to ~/.claude/commands/ (dev mode approach)?
- Hybrid: framework commands symlinked, custom commands copied?
- User choice during installation?

#### Update Mechanism

- How do users receive command updates after initial install?
- Re-run install.sh (destructive, loses customizations)?
- Separate "update commands" workflow?
- Git-based template pulling (advanced users)?

#### Template Organization

- Keep all commands in templates/commands/ (proposed)?
- Separate templates/commands/workflow/ for workflow-specific commands?
- Separate templates/commands/core/ vs. templates/commands/optional/?
- Tag commands in frontmatter: category: "workflow" vs. "utility"?

### Assumptions Needing Validation

#### Assumption: Commands are static after installation

- Need to validate: Do workflow commands change frequently?
- If yes: Symlink approach better for continuous updates
- If no: Copy approach better for user stability

#### Assumption: Users want to customize workflow commands

- Need to validate: How many users actually customize these?
- If few: Symlink approach acceptable (fewer customizations lost)
- If many: Copy approach critical (preserve user workflows)

#### Assumption: All 4 commands are equally important

- Need to validate: Which commands are most-used?
- start-work, open-pr likely high-usage (core workflow)
- cleanup-main, implement might be optional/advanced
- Could inform "core vs. optional" template organization

## 4. Recommendations

### Recommended Approach

#### Phase 1: Move Commands to Templates

- Move all 4 workflow commands to templates/commands/
- Maintain existing frontmatter structure (name, description, args)
- Add category field: `category: "workflow"` to differentiate from utility commands
- Update templates/commands/README.md with full command documentation

#### Phase 2: Update Installation Logic

- Modify install.sh to copy command templates during installation
- Add function: `install_command_templates()` after `create_directories()`
- Copy all .md files from templates/commands/ to ~/.claude/commands/
- Preserve existing commands if present (don't overwrite user customizations)

#### Phase 3: Handle Existing Users

- Add backup mechanism: if ~/.claude/commands/cleanup-main.md exists, create .backup before replacing
- Log which commands were backed up vs. newly installed
- Display summary: "Installed 8 commands, backed up 4 existing commands"
- Provide instructions for merging user customizations from backups

#### Phase 4: Documentation Updates

- Update templates/commands/README.md to document all 12 commands (8 existing + 4 workflow)
- Add migration guide for existing users
- Document template update workflow
- Add troubleshooting section for command conflicts

### What to Prioritize

#### Critical

- Move commands to templates/ (blocks user visibility and customization)
- Update install.sh to copy templates (blocks installation completeness)
- Backup existing commands (prevents user data loss)

#### Important

- Update README.md documentation (improves discoverability)
- Add category frontmatter field (enables future filtering/organization)
- Test both normal and --dev installation modes (ensures consistency)

#### Nice-to-Have

- Separate workflow vs. utility command organization (can be done later)
- Command update mechanism (future enhancement)
- User customization merging strategy (advanced feature)

### What to Avoid

#### Don't Overwrite User Customizations

- Never replace existing commands without backup
- Always preserve user modifications
- Provide clear path to review changes and merge

#### Don't Create Template-Installation Mismatch

- If templates exist, installation must use them
- Don't leave orphaned templates that aren't installed
- Ensure templates/commands/ and ~/.claude/commands/ stay in sync

#### Don't Make Dev Mode Inconsistent

- If other templates are symlinked in --dev mode, commands should be too
- If other templates are copied in --dev mode, commands should be too
- Maintain consistent behavior across all template types

#### Don't Ignore Existing SlashCommand Tool Integration

- Verify these commands aren't already provided by SlashCommand tool
- Check if moving to templates conflicts with tool-provided commands
- Ensure no duplicate command registration

### Implementation Notes

#### Install.sh Modification Pattern

```bash
install_command_templates() {
    print_message "info" "Installing command templates..."

    local template_dir="${AIDA_DIR}/templates/commands"
    local target_dir="${CLAUDE_DIR}/commands"

    mkdir -p "$target_dir"

    # Find all .md files in templates/commands/
    while IFS= read -r template_file; do
        local filename=$(basename "$template_file")
        local target_file="${target_dir}/${filename}"

        # Skip README.md
        if [[ "$filename" == "README.md" ]]; then
            continue
        fi

        # Backup existing file if present
        if [[ -f "$target_file" ]]; then
            local backup_file="${target_file}.backup.$(date +%Y%m%d_%H%M%S)"
            cp "$target_file" "$backup_file"
            print_message "warning" "Backed up existing command: $filename"
        fi

        # Copy template
        cp "$template_file" "$target_file"
        chmod 644 "$target_file"

    done < <(find "$template_dir" -maxdepth 1 -name "*.md" -type f)

    print_message "success" "Command templates installed"
}
```

#### Testing Checklist

- Normal install: Verify all 12 commands copied to ~/.claude/commands/
- Dev mode install: Verify symlink behavior for commands
- Existing commands: Verify backup creation and preservation
- README exclusion: Verify README.md not installed as command
- Permissions: Verify all installed commands are readable (644)

### Success Metrics

#### Immediate Success

- All 12 commands visible in templates/commands/
- install.sh successfully copies all command templates
- Existing user commands preserved with backups
- Documentation updated and accurate

#### Long-term Success

- Users report easier command discovery
- Users successfully customize workflow commands
- Framework command updates distribute smoothly
- No user data loss during installations/upgrades
