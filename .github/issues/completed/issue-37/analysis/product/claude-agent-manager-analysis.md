---
agent: claude-agent-manager
issue: 37
title: "Archive global agents and commands to templates folder"
analysis_date: "2025-10-06"
perspective: "Agent & Command Management"
---

# Claude Agent Manager Analysis: Issue #37

## Executive Summary

This archival task is critical for establishing a **committed reference baseline** of the agent ecosystem before further development. As the meta-agent responsible for agent/command lifecycle, I assess this as a **preservation and standardization effort** with implications for future agent development, installation workflows, and ecosystem consistency.

## 1. Domain-Specific Concerns

### Agent Structure Integrity

- **Frontmatter preservation**: All 22 agents have YAML frontmatter (name, description, model, color) that must be preserved exactly
- **Knowledge directory relationships**: 5 agents have knowledge/ subdirectories with hierarchical structure (core-concepts/, patterns/, decisions/)
- **Cross-references**: Agents may reference their knowledge bases using relative paths that break if structure changes
- **Index.md files**: Knowledge directories contain index.md catalogs that track knowledge_count and categories

### Command Structure & Metadata

- **Hardcoded paths**: Commands contain absolute paths (`/Users/oakensoul/Developer/oakensoul/claude-personal-assistant`) that limit portability
- **Frontmatter args**: Commands define argument schemas in frontmatter that control behavior
- **Workflow dependencies**: Commands like `/implement` and `/start-work` coordinate through shared state files (workflow-state.json)
- **Agent invocation patterns**: Commands invoke specific agents and expect them to be available

### Variable Substitution Requirements

- **PROJECT_ROOT scope**: Commands reference project-specific paths (.claude/workflow-state.json, .github/issues/)
- **Global config scope**: Some commands may reference ~/.claude/ which differs from project .claude/
- **Installation paths**: Future AIDA_HOME variable needed for ~/.aida/ references
- **Path consistency**: Substitution must not break bash command escaping or heredoc syntax

### Agent Discovery & Activation

- **Flat agent structure**: Claude Code discovers agents from ~/.claude/agents/ directory
- **Subdirectory handling**: Agents with knowledge/ create subdirectories - discovery mechanism unclear
- **Simple agents**: 17 agents have no knowledge/ - these are single .md files
- **Naming conventions**: Agent file must match agent name in frontmatter

## 2. Stakeholder Impact

### Who Is Affected

- **Future AIDA users**: Will receive these templates during installation
- **Development team**: Will use templates/ as reference for agent development
- **install.sh maintainer**: Must implement template installation logic
- **Agent developers**: Must understand template structure for creating new agents

### Value Provided

- **Committed baseline**: Preserves current agent ecosystem state in version control
- **Installation source**: Provides templates for fresh AIDA installations
- **Development reference**: Documents agent/command structure for future development
- **Portability**: Variable substitution enables multi-environment deployment
- **Consistency**: Establishes standard structure for all future agents/commands

### Risks & Downsides

- **Maintenance burden**: Templates diverge from ~/.claude/ unless kept in sync
- **Duplication concern**: Same content exists in two places (templates/ and ~/.claude/)
- **Variable substitution errors**: Incorrect path replacement could break commands
- **Knowledge directory size**: Archiving all knowledge/ adds ~50+ files to repo
- **Installation complexity**: install.sh must handle variable substitution correctly

## 3. Questions & Clarifications

### Missing Information

- **Template installation trigger**: When does install.sh copy from templates/? Only on first install or every time?
- **Update mechanism**: How do changes to ~/.claude/ agents propagate back to templates/?
- **Global vs project**: Some commands are project-specific (/implement, /start-work) - should these be in templates/commands/?
- **Knowledge directory discovery**: Does Claude Code auto-discover knowledge/ subdirectories?
- **Variable expansion timing**: When are ${PROJECT_ROOT} variables expanded - during install.sh or at runtime?

### Decisions Needed

- **Template vs working files**: Is templates/ the source of truth or is ~/.claude/?
- **.template extension**: Should commands be .md.template or .md with ${VARS} inside?
- **Documentation location**: Should agent usage docs go in templates/agents/README.md or stay in CLAUDE.md?
- **Selective archival**: Archive all 22 agents or only the "core" ones?
- **Git LFS consideration**: Knowledge directories may contain large files - need LFS?

### Assumptions to Validate

- **Assumption**: Variable substitution happens at install time, not runtime
- **Assumption**: Agents with knowledge/ should be in subdirectories, simple agents at root
- **Assumption**: All 14 commands are generic enough for template use (not user-specific)
- **Assumption**: Knowledge directory contents are static markdown, no generated files
- **Assumption**: install.sh will handle ${PROJECT_ROOT} expansion using `sed` or similar

## 4. Recommendations

### Recommended Approach

**Two-Phase Archival Strategy**:

**Phase 1: Archive Core Framework** (Priority: HIGH)

- Archive 6 core agents with knowledge/ (claude-agent-manager, code-reviewer, devops-engineer, product-manager, tech-lead, technical-writer)
- Archive 8 generic commands (create-agent, create-command, create-issue, publish-issue, expert-analysis, generate-docs, track-time, workflow-init)
- Skip user-specific commands (implement, open-pr, start-work, cleanup-main) - these are too project-specific

**Phase 2: Document Specialized Agents** (Priority: MEDIUM)

- Archive 16 specialized agents as reference (without installing by default)
- Create templates/agents/specialized/ subdirectory
- Document in templates/agents/README.md but don't auto-install

**Rationale**: Not all agents are universally applicable. LARP-specific and technology-specific agents should be optional.

### Prioritization

**Must Have**:

1. Archive 6 core agents with full knowledge/ hierarchies
2. Archive 8 generic commands with ${PROJECT_ROOT} substitution
3. Create templates/README.md, templates/agents/README.md, templates/commands/README.md
4. Validate frontmatter integrity for all archived agents

**Should Have**:

5. Archive 16 specialized agents to templates/agents/specialized/
6. Document variable substitution pattern in commands README
7. Create .github/workflows/validate-templates.yml for CI

**Could Have**:

8. Script to sync ~/.claude/ back to templates/
9. Template versioning strategy
10. Knowledge directory index validation

### What to Avoid

**Critical Mistakes to Prevent**:

- **Don't use .template extension** unless file has actual {{mustache}} or {{liquid}} templating - just use ${BASH_VARS}
- **Don't flatten knowledge/ hierarchy** - preserve exact directory structure (core-concepts/, patterns/, decisions/)
- **Don't substitute paths in agent .md files** - only commands need path substitution
- **Don't archive user-specific workflow state** - templates should be clean starting points
- **Don't break YAML frontmatter** - preserve exact formatting including quotes, dashes, indentation
- **Don't commit large binary files** - if knowledge/ contains images, consider .gitignore or LFS

**Structural Anti-Patterns**:

- Mixing simple and complex agents at same level (use subdirectories for agents with knowledge/)
- Inconsistent variable naming (stick to ${PROJECT_ROOT}, ${CLAUDE_CONFIG_DIR}, ${AIDA_HOME})
- Missing README files (every directory needs context)
- Incomplete archival (partial agent files without their knowledge/)

### Implementation Guidance

**Variable Substitution Pattern**:

```bash
# Commands should use these specific variables:
${PROJECT_ROOT}          # Project working directory
${CLAUDE_CONFIG_DIR}     # Usually ~/.claude
${AIDA_HOME}             # Usually ~/.aida

# Example in implement.md:
cat ${PROJECT_ROOT}/.claude/workflow-state.json
gh issue view ${active_issue.number} --repo ${GITHUB_REPO}
```

**Directory Structure**:

```text
templates/
├── README.md                                  # Templates overview
├── agents/
│   ├── README.md                              # Agent templates guide
│   ├── claude-agent-manager/                  # Core agents with knowledge
│   │   ├── claude-agent-manager.md
│   │   └── knowledge/
│   │       ├── index.md
│   │       ├── core-concepts/
│   │       ├── patterns/
│   │       └── decisions/
│   ├── [5 more core agents with knowledge/]
│   └── specialized/                           # Optional specialized agents
│       ├── README.md
│       ├── api-design-architect.md
│       ├── larp-product-manager.md
│       └── [14 more specialized agents]
├── commands/
│   ├── README.md                              # Command templates guide
│   ├── create-agent.md                        # Generic commands
│   ├── create-command.md
│   └── [6 more generic commands]
└── documents/                                 # Existing document templates
    ├── PRD.md.template
    └── TECH_SPEC.md.template
```

**Quality Checklist**:

- [ ] All agent frontmatter validated (name, description, model)
- [ ] Knowledge/ index.md files have accurate knowledge_count
- [ ] Commands use ${PROJECT_ROOT} not absolute paths
- [ ] Subdirectory structure matches ~/.claude/ layout
- [ ] README files explain structure and usage
- [ ] No user-specific content (API keys, personal paths)
- [ ] Git history shows which ~/.claude/ snapshot was archived
- [ ] Templates are installable via install.sh test run

### Future Considerations

**Template Maintenance Strategy**:

- Establish sync workflow: ~/.claude/ → templates/ when agents stabilize
- Version templates/ directory (v0.1.0-agents snapshot)
- Consider templates/ as "release artifacts" not working copies
- Document divergence policy (when is it OK for ~/.claude/ to differ?)

**Installation Integration**:

- install.sh should accept `--agents-only` or `--commands-only` flags
- Support selective agent installation (core vs specialized)
- Validate frontmatter during installation
- Detect conflicts with existing ~/.claude/agents/

**Agent Development Workflow**:

- New agents developed in ~/.claude/agents/
- When stable, archived to templates/agents/
- templates/ becomes the "published" agent catalog
- ~/.claude/ remains the development/testing environment

## Conclusion

This archival task is **foundation-critical** for the AIDA ecosystem. It establishes:

1. **Version-controlled agent baseline** for future reference
2. **Installation source** for fresh AIDA deployments
3. **Development template** for creating new agents
4. **Portability layer** through variable substitution

**Recommended path**: Two-phase archival (core first, specialized second) with clear documentation and validation. Prioritize integrity over completeness - better to archive 6 agents correctly than 22 agents incorrectly.

**Key success metric**: Can `install.sh` successfully install from templates/ to a fresh ~/.claude/ directory and have all agents/commands function correctly with substituted paths?
