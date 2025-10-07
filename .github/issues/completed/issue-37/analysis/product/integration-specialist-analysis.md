---
title: "Integration Specialist Analysis - Issue #37"
issue: 37
agent: "integration-specialist"
created: "2025-10-06"
status: "draft"
---

# Integration Specialist Analysis: Archive Global Agents and Commands

## Executive Summary

Issue #37 impacts the entire three-repository ecosystem (AIDA framework, dotfiles, dotfiles-private) and the installation/integration flow. The archival creates the foundation for portable, reusable templates that can be:

- Installed via `install.sh` to `~/.claude/`
- Managed through dotfiles stow packages
- Overlayed with private configurations
- Distributed across development/production environments

**Critical Integration Concern**: Path variable substitution is ESSENTIAL for portability across the three-repo system.

## 1. Domain-Specific Concerns

### GNU Stow Integration Impact

**Current State**:

- AIDA installs to `~/.aida/` (framework)
- User config generated in `~/.claude/` (runtime)
- Dotfiles can optionally stow AIDA integration package

**Archival Impact**:

- Templates must support stow-based installation from dotfiles
- Commands with absolute paths will break when stowed
- Need `${PROJECT_ROOT}`, `${CLAUDE_CONFIG_DIR}`, `${AIDA_HOME}` substitution
- Dotfiles `aida/` stow package can reference archived templates

**Specific Concerns**:

- Commands reference absolute paths (e.g., `/start-work` uses `.github/issues/in-progress/issue-{id}/`)
- These paths assume `${PROJECT_ROOT}` context, not `~/.claude/` context
- Stow package in dotfiles needs to work with both installation methods
- Private dotfiles overlay may need to override specific commands/agents

### MCP Server Configuration

**Current State**:

- No MCP server configs archived yet
- Future: AIDA may expose MCP servers for external tool access

**Archival Implications**:

- If agents have MCP server dependencies, document in knowledge/
- Archive any existing MCP server configs from `~/.claude/`
- Path variables needed for MCP server installation locations
- Template structure should support future MCP integration

### Obsidian Integration

**Current State**:

- No Obsidian integration templates in `~/.claude/` yet
- Future: Daily notes, dashboard updates, knowledge sync

**Archival Implications**:

- Archive any existing Obsidian-related commands/agents
- Knowledge directories may contain Obsidian sync configs
- Template structure should support Obsidian vault paths
- Variable substitution for `${OBSIDIAN_VAULT_PATH}`

### Git Workflow Integration

**CRITICAL FINDING**: Commands heavily depend on git workflow

**Examples from archived commands**:

- `/start-work` - Creates `.github/issues/in-progress/issue-{id}/`
- `/cleanup-main` - Git branch management
- `/open-pr` - GitHub CLI integration
- `/publish-issue` - GitHub issue creation

**Path Substitution Requirements**:

```bash
# Current (absolute):
.github/issues/in-progress/issue-37/

# Template (variable):
${PROJECT_ROOT}/.github/issues/in-progress/issue-${ISSUE_ID}/

# Installed (~/.claude/):
~/.claude/commands/start-work.md (already processed)

# Stowed (dotfiles):
~/dotfiles/aida/.claude/commands/start-work.md.template
```

**Concern**: Commands assume project-level git context, not user-level config context.

## 2. Stakeholder Impact

### Affected Stakeholders

**AIDA Framework Users** (Direct Impact):

- Benefit: Access to battle-tested command/agent templates
- Benefit: Clear examples for creating custom commands/agents
- Risk: Breaking changes if paths not properly substituted

**Dotfiles Users** (Indirect Impact):

- Benefit: Can stow AIDA integration with pre-configured commands
- Benefit: Consistent tooling across machines via stow
- Risk: Confusion if templates require manual path configuration

**Dotfiles-Private Users** (Overlay Impact):

- Benefit: Can override specific commands with private versions
- Benefit: Layer private agents on top of public templates
- Risk: Breaking changes when public templates update

**AIDA Developers** (Development Impact):

- Benefit: Clear template structure for future development
- Benefit: Version control for command/agent evolution
- Risk: Must maintain backward compatibility

### Value Provided

**Documentation Value**:

- Living examples of command structure (frontmatter, args, instructions)
- Knowledge directory hierarchy for agent context
- Best practices embedded in working code

**Reusability Value**:

- Copy templates to create new commands/agents
- Customize existing templates for specific workflows
- Share commands across team/community

**Portability Value**:

- Install AIDA on new machine → get all commands
- Sync via dotfiles → consistent environment
- Overlay private configs → customize without forking

**Testing Value**:

- Archived commands provide test fixtures
- Validate install.sh template processing
- Ensure path substitution works correctly

### Risks & Downsides

**Path Substitution Errors**:

- If variables not substituted correctly, commands break
- Hard to debug when paths are wrong
- User experience degrades significantly

**Maintenance Burden**:

- Must update templates when command structure changes
- Breaking changes require migration guides
- Knowledge directories must stay in sync with agents

**Namespace Pollution**:

- 14 commands + N agents = lot of files
- Users may want subset, not all templates
- Need selective installation mechanism

**Documentation Debt**:

- READMEs must explain variable substitution
- Examples needed for customization
- Migration guides for version updates

## 3. Questions & Clarifications

### Critical Questions

**Variable Substitution Strategy**:

- Q: Which paths need substitution? All absolute paths?
- Q: What variables to support? `${PROJECT_ROOT}`, `${CLAUDE_CONFIG_DIR}`, `${AIDA_HOME}`, `${HOME}`?
- Q: How to handle paths in knowledge/ files? Do they also need variables?
- Q: What about paths in agent.md files that reference knowledge/?

**Stow Integration**:

- Q: Should dotfiles `aida/` package include copies of templates or symlinks?
- Q: How do users update templates from dotfiles if they customize?
- Q: Should stow package include all commands or selective subset?

**Installation Flow**:

- Q: Does install.sh process .template files during installation?
- Q: Can users selectively install commands/agents?
- Q: How do updates work? Re-run install.sh? Manual sync?

**Private Overlay**:

- Q: How do users override specific commands in dotfiles-private?
- Q: Conflict resolution when private overlays public?
- Q: Should private commands use .template or final files?

### Missing Information

**Current ~/.claude/ Inventory**:

- Need complete list of all files to archive (have partial)
- Need to identify which files have absolute paths
- Need to understand knowledge/ directory dependencies

**Path Analysis**:

- Which commands reference project-relative paths?
- Which commands reference home-relative paths?
- Which commands reference AIDA-relative paths?

**Usage Patterns**:

- Which commands are project-specific vs global?
- Should some commands NOT be archived (too personal)?
- Are there private commands that should stay out of repo?

### Assumptions Needing Validation

**Assumption 1**: All commands should use variable substitution

- Validation needed: Are some commands inherently non-portable?
- Example: Commands with hardcoded GitHub org/repo names

**Assumption 2**: Knowledge directories are self-contained

- Validation needed: Do knowledge/ files reference external paths?
- Example: Do agents reference files outside their knowledge/?

**Assumption 3**: Install.sh will process .template files

- Validation needed: Is template processing implemented?
- Current state: Not in v0.1.1 install.sh

**Assumption 4**: Dotfiles stow package will work seamlessly

- Validation needed: Test stow with template files
- Concern: .template extension may confuse stow

## 4. Recommendations

### Immediate Actions (Issue #37 Scope)

**1. Archive Everything (As Recommended)**:

```bash
templates/
├── commands/
│   ├── start-work.md.template
│   ├── cleanup-main.md.template
│   ├── open-pr.md.template
│   ├── create-issue.md.template
│   ├── publish-issue.md.template
│   ├── expert-analysis.md.template
│   ├── implement.md.template
│   ├── track-time.md.template
│   ├── create-agent.md.template
│   ├── create-command.md.template
│   ├── workflow-init.md.template
│   ├── generate-docs.md.template
│   └── README.md
└── agents/
    ├── tech-lead/
    │   ├── agent.md.template (if exists, else agent.md)
    │   └── knowledge/
    │       ├── README.md
    │       ├── patterns.md
    │       ├── standards.md
    │       └── tech-stack.md
    ├── product-manager/
    │   ├── agent.md.template
    │   └── knowledge/
    ├── devops-engineer/
    │   ├── agent.md.template
    │   └── knowledge/
    ├── code-reviewer/
    │   ├── agent.md.template
    │   └── knowledge/
    ├── technical-writer/
    │   ├── agent.md.template
    │   └── knowledge/
    ├── claude-agent-manager/
    │   ├── agent.md.template
    │   └── knowledge/
    └── README.md
```

**2. Variable Substitution Pattern**:

Use these variables consistently:

- `${PROJECT_ROOT}` - Project root (e.g., `~/Developer/oakensoul/claude-personal-assistant`)
- `${CLAUDE_CONFIG_DIR}` - User config dir (e.g., `~/.claude`)
- `${AIDA_HOME}` - Framework install dir (e.g., `~/.aida`)
- `${HOME}` - User home directory

Example substitution in `/start-work.md.template`:

```markdown
# Before:
.github/issues/in-progress/issue-{id}/

# After:
${PROJECT_ROOT}/.github/issues/in-progress/issue-{id}/
```

**3. Documentation Requirements**:

Create comprehensive READMEs:

- `templates/README.md` - Overview, installation, customization
- `templates/commands/README.md` - Command structure, variables, examples
- `templates/agents/README.md` - Agent structure, knowledge dirs, examples

**4. Preservation of Structure**:

- Keep knowledge/ directories intact with full hierarchy
- Use exact copies (not .template) for knowledge/ files (no variables needed)
- Only use .template for files with path substitution needs

### Prioritization

**P0 - Critical for Issue #37**:

1. Archive all 12 commands from `~/.claude/commands/`
2. Archive all 6 agents with knowledge directories
3. Implement path variable substitution in command templates
4. Create templates/commands/README.md with variable documentation
5. Create templates/agents/README.md with structure documentation

**P1 - Important for Integration**:

1. Test archived templates with install.sh
2. Document installation flow in templates/README.md
3. Validate path substitution patterns work
4. Test selective command installation

**P2 - Nice to Have**:

1. Create stow package in dotfiles repo
2. Test dotfiles-private overlay
3. Create migration guide for updates
4. Document customization workflows

### What to Avoid

**Don't**:

- Hard-code any absolute paths in templates (use variables)
- Assume all users want all commands (support selective install)
- Include sensitive/private data in archived templates
- Break existing `~/.claude/` installations during archival
- Create .template files without documentation of variables

**Don't Assume**:

- That all commands work globally (some are project-specific)
- That knowledge/ files never need path substitution (validate)
- That stow will handle .template files correctly (test first)
- That users understand variable substitution (document clearly)

### Integration Testing Plan

**Test Scenarios**:

1. **Fresh AIDA Install**: `./install.sh` → verify templates copied correctly
2. **Dotfiles Stow**: `stow aida` → verify stow package works
3. **Private Overlay**: Overlay private command → verify override works
4. **Path Substitution**: Install on different machines → verify paths work
5. **Selective Install**: Install subset of commands → verify no breakage

**Success Criteria**:

- All archived templates install without errors
- Path variables resolve correctly in all contexts
- Knowledge directories maintain proper structure
- READMEs provide clear customization guidance
- Stow integration works seamlessly (future)

## Integration-Specific Risks

### High Risk

**Path Substitution Failure**:

- Impact: Commands break on installation
- Mitigation: Comprehensive testing, clear variable docs
- Detection: Automated tests for path resolution

**Stow Package Conflicts**:

- Impact: Dotfiles stow fails with conflicts
- Mitigation: Test stow package separately
- Detection: Stow dry-run tests

### Medium Risk

**Knowledge Directory Size**:

- Impact: Templates repo becomes large
- Mitigation: Document knowledge/ as optional
- Detection: Monitor repo size

**Template Version Skew**:

- Impact: Dotfiles templates diverge from AIDA templates
- Mitigation: Version compatibility matrix
- Detection: Automated compatibility checks

### Low Risk

**Customization Confusion**:

- Impact: Users don't understand how to customize
- Mitigation: Comprehensive README examples
- Detection: User feedback

## Conclusion

Issue #37 is foundational for the three-repository integration strategy. The archival must:

1. **Support portability** via path variable substitution
2. **Enable stow integration** for dotfiles distribution
3. **Allow customization** via private overlays
4. **Provide documentation** for template usage

**Critical Success Factor**: Path variable substitution MUST work correctly, or the entire integration falls apart.

**Recommended Approach**: Archive everything with .template extension for files needing path substitution, preserve knowledge/ directories as-is, and create comprehensive READMEs documenting the variable substitution pattern.

---

**Next Steps**:

1. Validate complete inventory of files to archive
2. Identify all paths requiring variable substitution
3. Test template processing in install.sh
4. Create comprehensive documentation
