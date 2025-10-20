---
title: "System Architect Analysis - Issue #54 Discoverability Commands"
issue: 54
analyst: system-architect
created: 2025-10-20
status: completed
---

# System Architect Analysis: Discoverability Commands

**Issue**: #54 - Implement `/agent-list`, `/skill-list`, `/command-list`

**Architecture Focus**: Multi-layer discovery system, skills architecture definition, two-tier integration patterns

---

## 1. Implementation Approach

### Architecture Alignment

**FITS WELL** with existing AIDA patterns:

- **Two-tier discovery**: Mirrors ADR-002 (user-level + project-level)
- **Template-based generation**: Consistent with AIDA's configuration-over-code philosophy
- **Filesystem-driven**: No hardcoded registries, auto-discovery
- **Modular layering**: CLI → Skills → Commands → Agent orchestration

### Recommended Architectural Patterns

#### Pattern 1: Hierarchical Discovery System

```text

Layer 1: CLI Scripts (bash-based filesystem scanning)
  ├── scripts/list-agents.sh
  ├── scripts/list-commands.sh
  └── scripts/list-skills.sh

Layer 2: Slash Commands (user interface)
  ├── templates/commands/.aida/agent-list.md
  ├── templates/commands/.aida/command-list.md
  └── templates/commands/.aida/skill-list.md

Layer 3: Agent Coordination (optional enhancement)
  └── claude-agent-manager (orchestrates discovery agents)

```text

**Rationale**: Separation of concerns - scripts handle discovery logic, commands provide UX, agents add intelligence.

#### Pattern 2: Two-Tier Aggregation

```text

Discovery Flow:

1. Scan ~/.claude/{agents|commands|skills}/     (user-level)
2. Scan ./.claude/{agents|commands|skills}/     (project-level)
3. Aggregate + deduplicate (handle symlinks in dev mode)
4. Separate in output (Global vs Project sections)

```text

**Rationale**: Consistent with ADR-002, enables context-aware discovery.

#### Pattern 3: Progressive Disclosure for Skills

```text

/skill-list                    → Show 28 categories only
/skill-list <category>         → Show skills within category
/skill-list <category> <skill> → Show skill details (future)

```text

**Rationale**: Avoids overwhelming users with 177 skills, aligns with UX best practices.

### Skills System Architecture Proposal

**CRITICAL DECISION NEEDED**: Skills architecture is defined in ADR-009 but NOT implemented.

**Proposed Structure** (per ADR-009):

```text

User-Level (generic patterns):
~/.claude/skills/
  ├── compliance/
  │   ├── hipaa-compliance/
  │   └── gdpr-compliance/
  ├── testing/
  │   ├── pytest-patterns/
  │   └── playwright-automation/
  └── frameworks/
      ├── react-patterns/
      └── nextjs-setup/

Project-Level (project-specific):
{project}/.claude/skills/
  ├── acme-ui-library/
  └── warehouse-patterns/

```text

**Skill Metadata Format** (frontmatter):

```yaml

---
title: "Skill Name"
description: "Brief description"
category: "compliance|testing|frameworks|api|data-engineering|infrastructure"
used_by: ["agent-name", "agent-name"]
tags: ["tag1", "tag2"]
last_updated: "YYYY-MM-DD"
---

```text

**Integration with `/skill-list`**:

- Scan `~/.claude/skills/*/` directories
- Parse `README.md` frontmatter for category
- Group by category, show counts
- Filter by category when argument provided

### Component Interaction Design

**Interaction Pattern**:

```text

User types: /agent-list

Claude invokes: scripts/list-agents.sh

Script executes:

1. Scan ~/.claude/agents/ → parse frontmatter
2. Scan ./.claude/project/agents/ → parse frontmatter
3. Detect symlinks (realpath comparison)
4. Format output (Global section, Project section)
5. Return to Claude

Claude renders:

- Formatted table with agent names + descriptions
- Category grouping (if applicable)
- Usage hints at bottom

```text

**Why this pattern**:

- **Decoupled**: Scripts don't depend on Claude
- **Testable**: Can validate scripts independently
- **Reusable**: Same scripts could power future web UI
- **Fast**: Direct filesystem access, no agent overhead

---

## 2. Technical Concerns

### Architectural Consistency

**STRENGTHS**:

- ✅ Aligns with two-tier architecture (ADR-002)
- ✅ Filesystem-driven (no manual registries)
- ✅ Template-based (matches AIDA philosophy)
- ✅ Frontmatter metadata (consistent with existing patterns)

**RISKS**:

- ⚠️ Skills architecture undefined (ADR-009 exists but no implementation)
- ⚠️ Symlink handling in dev mode (could show duplicates)
- ⚠️ Performance with 177 skills (need efficient scanning)

### Coupling/Cohesion Considerations

**LOW COUPLING** (good):

- CLI scripts standalone (no Claude dependency)
- Slash commands invoke scripts (loose integration)
- Skills system separate from agents/commands

**HIGH COHESION** (good):

- All discovery commands follow same pattern
- Frontmatter parsing reusable across all three
- Output formatting consistent

**CONCERN**: Tight coupling between skills and agents

- Skills system (ADR-009) requires agents to "load" skills
- Discovery commands don't affect this, but implementation order matters
- **Recommendation**: Implement `/skill-list` AFTER skills infrastructure exists

### Extensibility for Future Enhancements

**EXCELLENT extensibility**:

- Add new metadata fields → just parse more frontmatter
- Add filtering → extend script arguments
- Add search → grep across frontmatter
- Add JSON output → change formatter only
- Add web UI → reuse same scripts

**Future-proofing**:

- Version field in frontmatter (future compatibility)
- Category taxonomy expandable (add new categories)
- Skills catalog external (could switch to API-based discovery)

### Architecture Decision Records Needed?

**RECOMMENDED ADRs**:

**ADR-014: Discoverability Command Architecture** (NEW)

- **Decision**: Multi-layer CLI → Commands → Scripts pattern
- **Rationale**: Separation of concerns, testability, reusability
- **Consequences**: Scripts must be executable standalone

**ADR-015: Skills System Implementation** (UPDATE ADR-009)

- **Decision**: When to implement skills infrastructure
- **Status**: ADR-009 defines architecture, need implementation ADR
- **Blocker**: `/skill-list` depends on this

**NOT NEEDED**:

- Category taxonomy (just document in templates/commands/README.md)
- Frontmatter schema (already established pattern)
- Output format (implementation detail, not architecture)

---

## 3. Dependencies & Integration

### Impact on Overall System Architecture

**POSITIVE IMPACTS**:

- Enables agent/skill/command discoverability (closes major UX gap)
- Validates two-tier architecture in practice
- Creates reusable frontmatter parsing pattern
- Demonstrates template-based code generation

**NEUTRAL IMPACTS**:

- Adds three new slash commands (minor addition)
- Adds CLI scripts (expected pattern)
- Requires frontmatter on all agents/commands (already recommended)

**NO BREAKING CHANGES**:

- Existing agents/commands continue working
- Adds metadata, doesn't change behavior
- Backward compatible (graceful degradation if frontmatter missing)

### Integration Patterns with Existing Components

#### Integration Point 1: Frontmatter Parsing

```bash

# Reusable pattern across all discovery scripts

parse_frontmatter() {
  local file="$1"
  # Extract YAML between --- markers
  # Return key-value pairs
}

```text

**Used by**: All three discovery scripts, could be library function

#### Integration Point 2: Two-Tier Scanning

```bash

# Standard pattern for user + project discovery

scan_user_level() {
  # Scan ~/.claude/{type}/
}

scan_project_level() {
  # Scan ./.claude/{type}/
}

```text

**Used by**: `/agent-list`, `/command-list`, `/skill-list`

#### Integration Point 3: Symlink Deduplication

```bash

# Handle dev mode symlinks

deduplicate_symlinks() {
  # Use realpath to detect duplicates
  # Prefer real file over symlink in output
}

```text

**Used by**: All discovery commands in dev mode

### Skills System Design Requirements

**ARCHITECTURE REQUIREMENTS** (from ADR-009):

1. **Two-tier structure**: `~/.claude/skills/` + `{project}/.claude/skills/`
2. **Category-based organization**: 28 categories defined in skills-catalog.md
3. **Frontmatter metadata**: category, used_by, tags, last_updated
4. **README per skill**: Overview, when to use, contents, examples

**IMPLEMENTATION REQUIREMENTS** (NEW):

1. **Skills directory creation**: `/workflow-init` should create `.claude/skills/`
2. **Skill templates**: Add to `templates/skills/` with examples
3. **Agent loading**: Agents must be able to "use" skills (needs specification)
4. **Discovery integration**: `/skill-list` scans skills directories

**BLOCKER**: Skills infrastructure doesn't exist yet

- ADR-009 defines architecture
- skills-catalog.md lists 177 planned skills
- **No implementation** (no `~/.claude/skills/` created by install.sh)
- **No skill loading** mechanism for agents

**RECOMMENDATION**: Phase 1 implement `/agent-list` + `/command-list`, Phase 2 implement skills + `/skill-list`

---

## 4. Effort & Complexity

### Estimated Complexity

#### Phase 1: Agents + Commands (MEDIUM)

- CLI scripts: 2-3 days (bash, frontmatter parsing, formatting)
- Slash commands: 1 day (simple wrappers)
- Testing: 1-2 days (validate two-tier, symlinks, edge cases)
- Documentation: 1 day (usage, examples)
- **Total**: 5-7 days

#### Phase 2: Skills (LARGE - depends on infrastructure)

- Skills infrastructure: 3-5 days (directory creation, templates, agent loading)
- Skills catalog population: 10-20 days (create 22 Phase 1 META skills from skills-catalog.md)
- `/skill-list` implementation: 2-3 days (similar to agent-list but with categories)
- **Total**: 15-28 days

**Overall Complexity**: MEDIUM to LARGE depending on scope

### Architectural Risk Areas

**HIGH RISK**:

- **Skills system undefined**: ADR-009 architecture exists, no implementation

  - **Mitigation**: Phase approach - defer `/skill-list` to Phase 2
  - **Validation**: Create ADR-015 for implementation plan

**MEDIUM RISK**:

- **Symlink handling**: Dev mode creates symlinks that could show as duplicates

  - **Mitigation**: Use `realpath` to detect and deduplicate
  - **Validation**: Test in dev mode extensively

- **Performance**: 177 skills could slow discovery

  - **Mitigation**: Progressive disclosure (show categories first)
  - **Validation**: Benchmark with full skills catalog

**LOW RISK**:

- **Frontmatter parsing**: Well-understood pattern
- **Two-tier scanning**: Proven in existing agents
- **Output formatting**: Straightforward bash

### Design Decisions Needed Upfront

**CRITICAL DECISIONS** (before implementation):

1. **Skills infrastructure timeline**

   - When to implement skills system?
   - Phase 1 (agents/commands only) vs full implementation?
   - **Recommendation**: Phase 1 MVP (agents/commands), Phase 2 (skills)

2. **Frontmatter schema validation**

   - Enforce required fields (title, description, category)?
   - Warn vs error on missing frontmatter?
   - **Recommendation**: Warn only, graceful degradation

3. **Category taxonomy**

   - Accept PRD's 8 categories for commands?
   - Use skills-catalog.md's 28 categories for skills?
   - **Recommendation**: Yes to both, document in READMEs

**IMPORTANT DECISIONS** (can decide during implementation):

1. **Output format**

   - Plain text vs markdown tables?
   - Color usage?
   - **Recommendation**: Plain text with color, defer markdown/JSON to Phase 2

2. **Symlink display**

   - Show "symlink → target" notation?
   - Hide symlinks entirely?
   - **Recommendation**: Show target, note if symlinked (transparency)

3. **Caching**

   - Cache discovery results?
   - How long to cache?
   - **Recommendation**: Defer to Phase 2 (optimize if slow)

---

## 5. Questions & Clarifications

### Skills System Architecture Definition

**QUESTION 1**: When should skills infrastructure be implemented?

**OPTIONS**:

- **A**: Before `/skill-list` (full system)
- **B**: Defer to Phase 2 (implement `/agent-list` + `/command-list` first)
- **C**: Minimal implementation (directory structure only, no loading mechanism)

**RECOMMENDATION**: Option B - Phase approach

**RATIONALE**:

- `/agent-list` and `/command-list` provide immediate value
- Skills infrastructure is large (15-28 days)
- PRD already recommends deferring `/skill-list`
- Less risk, faster delivery

**QUESTION 2**: How do agents "load" skills?

**CURRENT STATE**: Undefined in ADR-009

**OPTIONS**:

- **A**: Skills are markdown files, Claude reads them on-demand
- **B**: Skills are templates, agents copy into knowledge base
- **C**: Skills are references, agents include via frontmatter `uses: [skill1, skill2]`

**RECOMMENDATION**: Needs separate design discussion (out of scope for this issue)

**QUESTION 3**: Where do the 177 skills from skills-catalog.md come from?

**CLARIFICATION NEEDED**:

- Are these Claude Code built-in skills? (external)
- Are these AIDA-specific skills to be created? (internal)
- Do they already exist somewhere? (inventory)

**IMPACT**: Discovery mechanism differs based on answer

- **If external**: Scan Claude Code's skills catalog
- **If internal**: Create in `~/.claude/skills/` (28 categories, 177 skills)
- **If inventory**: Just list planned skills, mark as "not yet created"

### Should We Create ADRs?

#### ADR-014: Discoverability Command Architecture

**RECOMMENDATION**: YES

**RATIONALE**:

- Establishes multi-layer pattern (CLI → Commands → Scripts)
- Documents two-tier discovery pattern
- Justifies separation of concerns
- **Status**: Create before implementation

#### ADR-015: Skills System Implementation Plan

**RECOMMENDATION**: YES (UPDATE ADR-009)

**RATIONALE**:

- ADR-009 defines architecture, needs implementation plan
- Clarifies when skills infrastructure will be built
- Documents skills loading mechanism
- Blocks `/skill-list` implementation
- **Status**: Create when ready to implement skills

#### Category Taxonomy ADR?

**RECOMMENDATION**: NO

**RATIONALE**:

- Implementation detail, not architecture decision
- Document in templates/commands/README.md instead
- Easy to change (just metadata)

### Long-Term Architecture Vision for Discoverability

#### VISION 1: Self-Documenting System

```text

AIDA is fully self-documenting through filesystem discovery:

- /agent-list → shows all agents (user + project)
- /skill-list → shows all skills (177+ across 28 categories)
- /command-list → shows all commands (user + project + .aida namespace)
- /knowledge-list → shows knowledge base files (future)
- /memory-list → shows memory/context files (future)

```text

#### VISION 2: Intelligent Discovery Agent

```text

claude-agent-manager becomes discovery orchestrator:

- User: "What agents do I have?"
- Manager: Invokes /agent-list, analyzes output, suggests agents
- User: "Which skills help with HIPAA?"
- Manager: Searches skills, shows compliance/hipaa-compliance + usage

```text

#### VISION 3: Interactive Exploration

```text

Discovery commands become interactive:

- /agent-list → shows menu → select agent → shows details
- /skill-list <category> → shows skills → select skill → loads into agent
- /command-list --search <term> → fuzzy search → run command

```text

**RECOMMENDATION**: Start with Vision 1 (MVP), evolve toward Vision 2 (agent orchestration), consider Vision 3 (interactive mode in Phase 3).

---

## Architecture Recommendations

### Phase 1: MVP (Agents + Commands)

**IMPLEMENT**:

1. CLI scripts for agent + command discovery
2. Slash commands `/agent-list` + `/command-list`
3. Frontmatter parsing library function
4. Two-tier scanning pattern
5. Symlink deduplication
6. Category filtering for commands
7. Output formatting (plain text + color)

**DEFER**:

1. `/skill-list` (skills infrastructure not ready)
2. JSON output format (optimize later)
3. Caching (premature optimization)
4. Interactive mode (Phase 3)

### Phase 2: Skills Infrastructure + Discovery

**IMPLEMENT**:

1. Skills directory structure (`~/.claude/skills/`, `./.claude/skills/`)
2. Skill templates (28 categories from skills-catalog.md)
3. Skills loading mechanism for agents
4. `/skill-list` with category-first approach
5. Progressive disclosure (categories → skills → details)

**VALIDATE**:

1. ADR-015 created and approved
2. Skills loading pattern defined
3. Agent integration tested

### Phase 3: Enhancements

**CONSIDER**:

1. Search functionality (`/agent-list --search "data"`)
2. JSON output (`/command-list --format json`)
3. Interactive mode (select from menu)
4. Performance optimization (caching)
5. Web UI (reuse same scripts)

---

## Critical Path

**BLOCKERS**:

1. **Skills infrastructure** blocks `/skill-list`

   - Mitigation: Phase approach, implement agents/commands first

**DEPENDENCIES**:

1. Frontmatter added to all agents/commands

   - Status: Can implement alongside (non-breaking)

2. Category taxonomy defined

   - Status: PRD defines 8 categories (approved)

**NO BLOCKERS** for Phase 1 (agents + commands)

---

## Conclusion

**OVERALL ASSESSMENT**: MEDIUM complexity, HIGH value, EXCELLENT architecture alignment

**KEY STRENGTHS**:

- Aligns perfectly with AIDA's two-tier architecture
- Filesystem-driven (no manual registries)
- Reusable patterns across all three commands
- Extensible for future enhancements

**KEY RISKS**:

- Skills infrastructure undefined (defer to Phase 2)
- Symlink handling in dev mode (testable, mitigatable)

**RECOMMENDATION**:

- **Approve Phase 1**: Implement `/agent-list` + `/command-list` (5-7 days)
- **Defer Phase 2**: Implement skills infrastructure + `/skill-list` separately (15-28 days)
- **Create ADR-014**: Document discoverability architecture
- **Plan ADR-015**: Skills implementation plan (when ready)

**ARCHITECTURE CONFIDENCE**: HIGH (well-aligned with existing patterns, clear separation of concerns, proven two-tier approach)
