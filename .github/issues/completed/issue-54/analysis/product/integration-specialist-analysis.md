---
title: "Integration Specialist Analysis - Issue #54"
issue: 54
agent: integration-specialist
created: "2025-10-20"
status: "draft"
---

# Integration Specialist Analysis: Discoverability Commands

Analysis of integration patterns and system integration concerns for implementing `/agent-list`, `/skill-list`, and `/command-list`.

## 1. Domain-Specific Concerns

### Integration Architecture

**Multi-Layer Discovery System**:

- **Layer 1**: CLI scripts (filesystem scanning, platform-agnostic)
- **Layer 2**: Skills (output formatting, Claude integration)
- **Layer 3**: Slash commands (user interface delegation)
- **Layer 4**: Agent orchestration (claude-agent-manager)

**Integration Patterns**:

- **Plugin Discovery Pattern**: Auto-discover agents/skills/commands from filesystem
- **Delegation Pattern**: Slash commands delegate to claude-agent-manager with skills
- **Template Pattern**: Consistent output formatting across all list commands
- **Two-Tier Integration**: Support both user-level (`~/.claude/`) and project-level (`./.claude/`) discovery

### Skills System Integration

**Current State**:

- Skills directory exists: `templates/skills/` with subdirectories (aida-config, hipaa-compliance, pytest-patterns)
- Skills are referenced in Claude Code's built-in skill system (177+ skills mentioned)
- No existing skill invocation pattern visible in AIDA codebase

**Integration Gaps**:

- **Skill Definition Format**: Unclear how skills are defined (YAML? Markdown? JSON?)
- **Skill Registration**: How does claude-agent-manager discover/register skills?
- **Skill Invocation**: How do slash commands invoke skills?
- **Skill Output Format**: What format do skills return (JSON? Text? Structured data?)

**Critical Questions**:

1. Are AIDA skills separate from Claude Code's 177+ built-in skills?
2. How do skills integrate with the agent system?
3. What's the skill definition schema?

### Filesystem Integration Patterns

**Discovery Pattern**:

```bash
# Two-tier discovery (user + project level)
~/.claude/agents/          # User-level agents (global)
./.claude/agents/          # Project-level agents (standalone)
~/.claude/project/context/   # User-level extensions (symlinks)
./.claude/project/context/   # Project-level extensions

# Commands
~/.claude/commands/        # User-level commands (via symlink to templates)
./.claude/commands/        # Project-level commands (if custom)

# Skills
templates/skills/          # Framework-level skills (installed to ~/.aida/)
```text

**Complexity**:

- Symlink resolution (user directories symlink to framework templates in dev mode)
- Deduplication (avoid showing same agent/command twice)
- Version tracking (installed vs available)

### API Design Considerations

**Output Format Options**:

1. **Plain Text**: Simple, human-readable, Claude-friendly
2. **Structured Markdown**: Tables, headings, formatted lists
3. **JSON**: Machine-parseable, enables future CLI/API integration
4. **Mixed**: Markdown for display, JSON metadata for processing

**Recommendation**: Structured Markdown with optional `--json` flag for future extensibility

**Category Filtering Pattern**:

```bash
/command-list                     # All commands
/command-list --category workflow # Filter by category
/command-list --category github   # Multiple categories possible
```text

**Category Detection Strategy**:

- Parse frontmatter for `category` field
- Infer from directory structure
- Use filename patterns (e.g., `github-*`)
- Default category: "uncategorized"

## 2. Stakeholder Impact

### Users Affected

**Primary**:

- **New AIDA users**: Need discoverability to understand available functionality
- **Existing users**: Reminder of available commands/agents they may have forgotten
- **Power users**: Quick reference without reading documentation

**Secondary**:

- **Agent developers**: Reference for existing agents when creating new ones
- **Command developers**: Avoid duplicate command names
- **Documentation maintainers**: Auto-generated reference material

### Value Provided

**Immediate**:

- **Reduced cognitive load**: Don't need to remember all commands/agents
- **Faster onboarding**: New users discover features organically
- **Better UX**: Self-documenting system

**Long-term**:

- **Extensibility foundation**: Skills system becomes more visible/usable
- **Integration readiness**: CLI/API foundation for future tooling
- **Documentation sync**: Auto-discovery reduces docs drift

### Risks & Downsides

**Technical Risks**:

- **Skills system undefined**: Building on unclear foundation (see Section 3)
- **Performance**: Filesystem scanning on every invocation (minor, but consider caching)
- **Symlink complexity**: Dev mode symlinks may cause duplicate listings
- **Category inconsistency**: No enforced category taxonomy

**UX Risks**:

- **Information overload**: 177+ skills in flat list is overwhelming
- **Outdated listings**: If agents/commands change, lists may be stale until rescan
- **Incomplete metadata**: Missing descriptions make listings less useful

**Mitigation**:

- Add `--short` flag for concise output
- Implement smart categorization for skills (group by domain)
- Cache filesystem scans (invalidate on directory modification)
- Enforce frontmatter validation via pre-commit hooks

## 3. Questions & Clarifications

### Critical (Blocking Implementation)

**Skills System Architecture**:

1. **Where are skills defined?** (templates/skills/ subdirectories or elsewhere?)
2. **What is a skill's file format?** (YAML metadata? Markdown? Python modules?)
3. **How does claude-agent-manager discover skills?** (scan filesystem? registry?)
4. **How do skills integrate with Claude Code's built-in skills?** (separate namespaces? conflicts?)
5. **What's the skill invocation protocol?** (function call? script execution? prompt template?)

**Skills vs Commands vs Agents**:

- **Skill**: Reusable capability invoked by agents (e.g., "scan filesystem", "parse frontmatter")
- **Command**: User-facing slash command delegating to agents (e.g., `/agent-list`)
- **Agent**: Intelligent orchestrator invoking skills (e.g., claude-agent-manager)
- **Clarify relationship**: Do skills exist independently or only via agent invocation?

**Output Destination**:

- Where do CLI scripts write output? (stdout, file, return value?)
- How do skills consume script output? (parse stdout? JSON response?)
- How do commands format skill output for Claude? (markdown? structured text?)

### Important (Design Decisions)

**Category Taxonomy**:

- Should categories be standardized (predefined list) or freeform (user-defined)?
- Where are categories defined? (frontmatter, directory structure, separate manifest?)
- How to handle multi-category assignments? (comma-separated, array, tags?)

**Symlink Handling**:

- Dev mode creates symlinks from `~/.claude/` → framework templates
- Should listings show "source" (framework templates) or "target" (user directories)?
- How to deduplicate entries when both exist?

**Version Display**:

- Should listings show agent/command versions?
- Where is version info stored? (frontmatter `version` field?)
- How to indicate "installed" vs "available" vs "outdated"?

### Nice to Have (Future Enhancements)

- Filter by model (`--model sonnet` shows only sonnet-based agents)
- Search within listings (`/agent-list --search "sql"`)
- Diff mode (`/agent-list --diff` shows changes since last check)
- Export mode (`/agent-list --json > agents.json`)

## 4. Recommendations

### Recommended Approach

#### Phase 1: Foundation (Minimum Viable)

1. **CLI Scripts First** (scripts/list-*.sh):
   - Implement filesystem scanning for agents/commands
   - Parse frontmatter (name, description, category, version)
   - Output structured markdown tables
   - Handle two-tier discovery (user + project levels)
   - Deduplicate symlinked entries

2. **Document Skills Architecture** (BEFORE implementing skill-related code):
   - **CRITICAL**: Define skill schema in templates/skills/README.md
   - Document skill lifecycle (discovery → registration → invocation)
   - Create example skill with full metadata
   - Update claude-agent-manager agent definition with skill patterns

3. **Defer Skills Integration** (Phase 2):
   - Skip skill listing until architecture is clarified
   - Focus on agents and commands (well-defined, proven patterns)
   - Skills can be added later without breaking changes

#### Phase 2: Skills Integration (After Architecture Defined)

4. **Skills Listing** (scripts/list-skills.sh):
   - Implement based on documented skill architecture
   - Categorize by domain (filesystem, git, analysis, etc.)
   - Show skill source (AIDA framework vs Claude Code built-in)

5. **Skills as Output Formatters** (optional):
   - Create skills that invoke CLI scripts and format output
   - claude-agent-manager invokes skills instead of scripts directly
   - Enables consistent formatting, error handling

### What to Prioritize

**High Priority (Do First)**:

1. Clarify skills architecture (documentation, not code)
2. Implement `/agent-list` and `/command-list` (proven patterns)
3. Create scripts/list-agents.sh and scripts/list-commands.sh
4. Add category filtering for commands
5. Test two-tier discovery (user + project levels)

**Medium Priority (After Phase 1)**:

6. Define skill schema and registration pattern
7. Implement `/skill-list` once architecture is clear
8. Add version tracking display
9. Implement output caching for performance

**Low Priority (Future)**:

10. JSON output format (`--json` flag)
11. Advanced filtering (`--model`, `--search`)
12. Interactive mode (numbered selection, multi-select)

### What to Avoid

**Don't**:

- **Don't build skills infrastructure without documentation**: Leads to technical debt
- **Don't assume skill = script**: May be more complex (plugin system, Claude integration)
- **Don't ignore symlinks**: Dev mode users will see duplicate listings
- **Don't hardcode categories**: Use frontmatter for extensibility
- **Don't implement all 3 commands identically**: agents/commands are similar, skills are different

**Do Instead**:

- **Document first, code second**: Write templates/skills/README.md explaining architecture
- **Examine existing skills**: Reverse-engineer from templates/skills/* subdirectories
- **Start simple**: Plain markdown output, add JSON later
- **Use metadata validation**: Pre-commit hooks enforce frontmatter completeness
- **Modular design**: Separate scanning logic, formatting logic, output logic

### Implementation Strategy

**Recommended Sequence**:

```bash
# 1. Create scripts (no skills dependency)
scripts/list-agents.sh      # Scan ~/.claude/agents/ and ./.claude/agents/
scripts/list-commands.sh    # Scan ~/.claude/commands/ and ./.claude/commands/

# 2. Create slash commands (direct script invocation)
templates/commands/.aida/agent-list.md    # Invoke script, format output
templates/commands/.aida/command-list.md  # Invoke script, format output

# 3. Document skills architecture
templates/skills/README.md                # Define schema, lifecycle, examples

# 4. (Later) Create skills infrastructure
templates/skills/*/                       # Skill definitions
scripts/list-skills.sh                    # Skills discovery

# 5. (Later) Add skill-based formatting
templates/skills/list-formatter/          # Format list output via skill
```text

**Why This Order**:

- Agents/commands have proven patterns (see /install-agent)
- Scripts provide immediate value without skills dependency
- Documenting skills architecture prevents rework
- Skills can enhance existing commands retroactively

### Integration Pattern Recommendation

**Use Delegation Pattern**:

```markdown
# templates/commands/.aida/agent-list.md
---
name: agent-list
description: List all available agents (global + project-level)
agent: claude-agent-manager
---

## Workflow

1. Invoke list-agents.sh script
2. Parse output (markdown table)
3. Display to user with helpful context
4. (Future) Format via skill for consistency
```text

**Benefits**:

- Simple, testable, scriptable
- Works without skills infrastructure
- Easy to enhance with skills later
- Consistent with existing command patterns

### Success Metrics

**Phase 1 Success**:

- `/agent-list` shows all user + project agents without duplicates
- `/command-list --category workflow` filters correctly
- Scripts are executable standalone (not Claude-dependent)
- Output is human-readable markdown tables

**Phase 2 Success** (after skills architecture defined):

- `/skill-list` shows categorized skills with descriptions
- Skills architecture is documented and proven
- claude-agent-manager can invoke skills consistently

## Related Integration Patterns

**Similar Patterns in AIDA**:

- **/install-agent**: Scans `~/.claude/agents/` for two-tier agents, handles symlinks
- **scripts/validate-templates.sh**: Filesystem scanning, frontmatter parsing
- **templates/agents/*/knowledge/index.md**: Metadata-driven documentation

**Learn From**:

- `/install-agent` two-tier detection logic
- validate-templates.sh frontmatter parsing
- Existing agent frontmatter schema (name, description, model, color)

**Diverge Where**:

- Skills need categorization (agents don't)
- Commands need arguments display (agents don't)
- Skills may need source tracking (AIDA vs Claude Code)

---

## Summary

**Integration Specialist Perspective**:

This feature implements a **plugin discovery pattern** across AIDA's multi-tier architecture. The primary integration challenge is the **undefined skills system architecture**. Recommend:

1. **Implement agents/commands first** (proven patterns)
2. **Document skills architecture** before implementation
3. **Use simple delegation pattern** (scripts → commands → agents)
4. **Add skills integration later** when architecture is clear

**Key Risk**: Building skills infrastructure on assumptions rather than documented architecture.

**Key Opportunity**: Establish pattern for auto-discovery that scales to future components (runbooks, workflows, personalities).
