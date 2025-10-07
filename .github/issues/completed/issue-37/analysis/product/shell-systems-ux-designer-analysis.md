---
title: "Shell Systems & UX Analysis - Issue #37"
issue: "#37 - Archive global agents and commands to templates folder"
analyst: "Shell Systems & UX Designer"
date: "2025-10-06"
status: "draft"
---

# Shell Systems & UX Analysis - Issue #37

## 1. Domain-Specific Concerns

### Path Portability & Variable Substitution

**Critical UX Issue**: Commands contain hardcoded absolute paths that will break for other users

- **Pattern found**: `/Users/oakensoul/Developer/oakensoul/claude-personal-assistant/`
- **User impact**: Commands fail silently or with cryptic errors on other systems
- **Solution**: Requires systematic variable substitution with clear naming

**Variable Strategy**:

- `${PROJECT_ROOT}` - Active project directory (git root)
- `${CLAUDE_CONFIG_DIR}` - User's ~/.claude/ directory
- `${AIDA_HOME}` - AIDA installation (~/.aida/)
- **Critical**: Don't use `${HOME}` - too ambiguous in multi-user contexts

### Command Discovery & Documentation

**Current state**: 14 commands, no index or categorization

**UX Problems**:

- Users can't discover what commands exist without `ls ~/.claude/commands/`
- No usage examples or quick reference
- No categorization (git workflow vs documentation vs development)
- Command descriptions buried in frontmatter

**Recommendations**:

- Create `templates/commands/README.md` with categorized command list
- Include one-liner descriptions and common use cases
- Add "See Also" cross-references between related commands
- Consider command naming convention guide

### Agent Discoverability

**Current state**: 22 agents (6 with knowledge dirs, 16 standalone)

**UX Challenges**:

- Agent purpose not clear from filename alone
- No categorization (core workflow agents vs specialized tech agents)
- Knowledge directory structure inconsistent
- No indication which agents work together

**Structure Recommendations**:

```text
templates/agents/
├── README.md                    # Agent catalog with categories
├── core/                        # Workflow orchestration agents
│   ├── claude-agent-manager.md
│   ├── devops-engineer.md
│   └── product-manager.md
├── development/                 # Tech-specific agents
│   ├── php-engineer.md
│   ├── nextjs-engineer.md
│   └── web-frontend-engineer.md
├── quality/                     # QA and review agents
│   ├── code-reviewer.md
│   └── larp-qa-engineer.md
└── documentation/
    └── technical-writer.md
```

### Error Handling UX

**Template not found scenarios**:

- User installs AIDA but templates missing
- User tries to create agent/command but template source unavailable
- Partial installation (some templates copied, others missing)

**Requirements**:

- Clear error messages: "Template not found at ~/.aida/templates/agents/foo.md"
- Suggest resolution: "Run: aida repair" or "Reinstall AIDA framework"
- Graceful degradation: Core commands work even if specialized agents missing

### Installation Flow Ergonomics

**Critical UX Decision**: Template → User Config Flow

**Two approaches**:

1. **Copy on install** (current implied approach)
   - Pro: User gets working files immediately
   - Con: Updates don't propagate to existing installs
   - Con: Users modify copies, lose update path

2. **Reference with override** (recommended)
   - Templates stay in `~/.aida/templates/`
   - User config in `~/.claude/` overrides templates
   - Command resolution: `~/.claude/commands/foo.md` || `~/.aida/templates/commands/foo.md`
   - Pro: Users get updates automatically
   - Pro: Clear separation of framework vs customization
   - Con: Requires resolution logic in command loader

**Recommendation**: Start with copy-on-install (simpler), plan for reference model in v0.2

## 2. Stakeholder Impact

### Primary Users: AIDA Framework Installers

**Value Provided**:

- Access to 14 proven workflow commands
- 22 specialized agents for different tasks
- Knowledge bases for core agents (patterns, standards, stakeholders)
- Working examples for creating custom commands/agents

**Pain Points Addressed**:

- Don't have to create workflow commands from scratch
- Clear templates for customization
- Documented patterns reduce trial-and-error

**Risks**:

- Commands may reference project-specific tools/structure
- Knowledge bases may contain user-specific preferences
- Version drift between templates and user configs

### Secondary Users: AIDA Contributors/Maintainers

**Value Provided**:

- Committed record of current command/agent state
- Regression testing baseline
- Documentation of system capabilities
- Examples for new contributors

**Risks**:

- Maintenance burden - templates diverge from active development
- Unclear ownership - who updates templates vs user configs?
- Knowledge directory bloat - when to include vs exclude?

### Tertiary Users: Documentation Readers

**Value Provided**:

- Concrete examples of AIDA capabilities
- Template reference for documentation
- Understanding of agent specializations

## 3. Questions & Clarifications

### Missing Information

**Template Substitution Mechanism**:

- [ ] How are variables replaced during installation?
- [ ] Is there a template processor or manual sed/awk?
- [ ] What happens if variable undefined at install time?

**Knowledge Directory Filtering**:

- [ ] Should knowledge/ contain project-specific info or only patterns?
- [ ] How to identify what's generic vs user-specific?
- [ ] Example: `tech-lead/knowledge/tech-stack.md` - is this AIDA's stack or user's?

**Update Strategy**:

- [ ] When user customizes a command, how do they get updates?
- [ ] Should we track "last synced from template" metadata?
- [ ] Diff/merge workflow for template updates?

### Decisions Needed

**Agent Categorization**:

- [ ] Flat structure or hierarchical (core/development/quality)?
- [ ] Category naming convention?
- [ ] Migration path for existing ~/.claude/agents/?

**Variable Naming Convention**:

- [ ] `${PROJECT_ROOT}` vs `${PROJECT_DIR}` vs `${CWD}`?
- [ ] `${CLAUDE_CONFIG_DIR}` vs `${CLAUDE_HOME}` vs `${USER_CONFIG}`?
- [ ] Document authoritative list in templates/README.md?

**Template File Extensions**:

- [ ] Use `.md.template` only when substitution needed?
- [ ] Or always use `.template` for clarity (file is a template)?
- [ ] How to indicate "safe to use as-is" vs "requires customization"?

### Assumptions to Validate

**Assumption**: All 14 commands should be archived

- Some may be user-specific workflows
- Some may be experimental/deprecated
- Should we audit before archiving?

**Assumption**: Knowledge directories are portable

- May contain absolute paths or user-specific context
- Need to verify each knowledge/ directory
- May need sanitization before templating

**Assumption**: Commands work in project-independent contexts

- Many reference `.claude/workflow-config.json` in project root
- Implies commands expect to run in AIDA-managed project
- May need conditional logic: "if in project, use workflow-config, else skip"

## 4. Recommendations

### Approach: Phased Archival with Progressive Enhancement

#### Phase 1: Direct Archive (Minimal Viable)

1. Archive all commands as exact copies (`.md` not `.template`)
2. Archive all agents with knowledge directories
3. Create basic README files with file listings
4. Document that path substitution is manual during install

**Rationale**: Get committed record quickly, defer complex substitution

#### Phase 2: Path Substitution (Post-Archive)

1. Identify all absolute path patterns across commands
2. Create substitution map (hardcoded path → variable)
3. Convert affected files to `.template` extension
4. Add variable reference documentation

**Rationale**: Easier to diff and validate substitutions with committed baseline

#### Phase 3: Enhanced Discovery (Future)

1. Categorize agents into logical groups
2. Create rich README.md files with examples
3. Add cross-references and usage patterns
4. Implement template → user config resolution

### Prioritization

**Must Have (MVP)**:

- ✅ Archive all 14 commands verbatim
- ✅ Archive all 22 agents + knowledge dirs
- ✅ Basic README.md with file listing
- ✅ Document path variables in templates/README.md

**Should Have (Quality)**:

- ⚠️ Path substitution for `${PROJECT_ROOT}` in commands
- ⚠️ Agent categorization (at minimum: core vs specialized)
- ⚠️ Knowledge directory sanitization (remove user-specific paths)

**Nice to Have (Future)**:

- ⭕ Rich command catalog with examples
- ⭕ Agent relationship diagram
- ⭕ Template update workflow
- ⭕ Install-time variable resolution

### What to Avoid

**Anti-patterns**:

- ❌ **Over-templating**: Don't use `.template` for files that need no substitution
  - UX confusion: "Why is this a template if I use it as-is?"

- ❌ **Premature categorization**: Don't reorganize agent structure without user validation
  - Risk: Break existing workflows that reference agent paths

- ❌ **Aggressive sanitization**: Don't remove knowledge/ content without manual review
  - Risk: Lose valuable context and patterns

- ❌ **Generic variable names**: Avoid `${DIR}`, `${PATH}`, `${HOME}`
  - UX confusion: Which directory? Path to what?

**Scope creep to avoid**:

- Creating new commands/agents during archival
- Refactoring command internals "while we're at it"
- Building template installation framework (separate issue)
- Comprehensive agent documentation (separate issue)

### Implementation Checklist

**Pre-archive Audit**:

- [ ] Review each command for obvious user-specific content
- [ ] Check each knowledge/ directory for sensitive information
- [ ] Identify deprecated or experimental commands to exclude
- [ ] List all absolute path patterns for substitution mapping

**Archive Execution**:

- [ ] Copy commands: `cp -R ~/.claude/commands/* templates/commands/`
- [ ] Copy agents: `cp -R ~/.claude/agents/* templates/agents/`
- [ ] Create templates/README.md with variable definitions
- [ ] Create templates/commands/README.md with command listing
- [ ] Create templates/agents/README.md with agent listing

**Post-archive Validation**:

- [ ] Verify all expected files present
- [ ] Check knowledge/ directories copied correctly
- [ ] Lint all markdown files
- [ ] Test: Fresh install can use templates
- [ ] Document any known limitations or TODOs

## Summary

**Core UX Principle**: Templates should be "copy and customize" not "read and rewrite"

The archival should prioritize **completeness** (get everything committed) over **perfection** (ideally structured templates). Path substitution and enhanced documentation can iterate post-archive with the safety of version control.

**Key Success Metrics**:

1. New user can install AIDA and get working commands/agents
2. Paths don't break on different systems
3. User can discover what agents/commands exist
4. User knows which agents to use for which tasks
5. Template updates don't break user customizations

**Biggest Risk**: Path portability issues causing silent failures or cryptic errors for new users. Mitigate with clear variable documentation and installation validation.
