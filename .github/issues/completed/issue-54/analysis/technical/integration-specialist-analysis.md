---
title: "Integration Specialist Technical Analysis - Discoverability Commands"
issue: 54
analyst: integration-specialist
created: 2025-10-20
status: draft
---

# Integration Specialist Analysis: Discoverability Commands

## Executive Summary

This feature requires a **multi-layer integration architecture** connecting CLI scripts → slash commands → agent orchestration. The integration pattern is clear and follows existing AIDA patterns, but the skills layer integration requires architectural clarification before implementation.

**Complexity**: **Medium (M)** for Phase 1 (agents/commands), **Large (L)** including skills system

**Key Risk**: Skills system architecture undefined - defer `/skill-list` to Phase 2

## 1. Implementation Approach

### Multi-Layer Integration Architecture

```text
Layer 1: CLI Scripts (Data Collection)
  ├── scripts/list-agents.sh
  ├── scripts/list-commands.sh
  └── scripts/list-skills.sh (Phase 2)
  │
  └─> Output: Formatted text with frontmatter data

Layer 2: Slash Commands (User Interface)
  ├── /agent-list
  ├── /command-list
  └── /skill-list (Phase 2)
  │
  └─> Invokes: Layer 1 scripts via bash execution

Layer 3: Agent Orchestration (Optional Enhancement)
  └── claude-agent-manager
      └─> Could format/enhance output if needed
```text

### Integration Pattern: Direct Script Invocation

**Recommended Approach**: Slash commands directly invoke CLI scripts

```markdown
# templates/commands/.aida/agent-list.md
---
name: agent-list
description: List all available agents with descriptions and usage patterns
---

# Agent List Command

## Instructions

1. Execute the agent listing script:
   ```bash
   ${AIDA_HOME}/scripts/list-agents.sh
```text

2. Display the output to the user

3. If script fails:
   - Display error: "Failed to list agents. Check that AIDA is properly installed."
   - Exit with error status

```text

#### Why Direct Invocation?

- **Simplicity**: No intermediate agent needed for data display
- **Performance**: Faster than agent delegation (<500ms target)
- **Loose Coupling**: Scripts are standalone, testable independently
- **Flexibility**: Can invoke scripts from commands, agents, or directly

#### When to Use Agent Orchestration?

Agent involvement (claude-agent-manager) only if:

- Output formatting requires AI decision-making
- Need to merge/transform data intelligently
- Interactive filtering beyond simple grep
- Phase 2+ features (search, recommendations)

### CLI Script Integration Requirements

**Filesystem Scanning Pattern**:

```bash
#!/usr/bin/env bash
# scripts/list-agents.sh

# Scan user-level agents
for agent_file in ~/.claude/agents/*/*.md; do
    # Parse frontmatter using grep/sed (not full file read)
    name=$(grep "^name:" "$agent_file" | sed 's/name: //')
    description=$(grep "^description:" "$agent_file" | sed 's/description: //')

    # Store for display
done

# Scan project-level agents (if in project)
if [ -d ".claude/agents" ]; then
    for agent_file in .claude/agents/*/*.md; do
        # Parse and deduplicate
    done
fi

# Format output
echo "=== User-Level Agents (${user_count}) ==="
# Display user agents
echo ""
echo "=== Project-Level Agents (${project_count}) ==="
# Display project agents
```text

**Key Integration Points**:

- **Path Resolution**: Use `${AIDA_HOME}`, `${CLAUDE_CONFIG_DIR}` variables
- **Error Handling**: Graceful failures, no path exposure
- **Output Format**: Consistent across all three commands
- **Deduplication**: Handle symlinks (dev mode)

### Skills System Integration (Phase 2)

**Critical Questions for Skills Architecture**:

1. **Storage Location**:
   - Are skills in `templates/skills/`?
   - External catalog URL?
   - Both (local + remote)?

2. **File Format**:
   - YAML files with frontmatter?
   - JSON catalog?
   - Markdown with metadata?

3. **Registration Mechanism**:
   - How do skills become "available"?
   - Dynamic discovery or static registry?

4. **Invocation Pattern**:
   - How does `claude-agent-manager` invoke skills?
   - Subprocess execution? Import? API call?

5. **Category System**:
   - Existing 28 categories confirmed?
   - Hierarchical or flat taxonomy?

**Recommended Skills Integration Pattern** (pending architecture):

```bash
# scripts/list-skills.sh (placeholder)

# Option A: Local Filesystem Scanning
find ~/.aida/skills/ -name "*.yaml" | parse_metadata

# Option B: Registry-Based
cat ~/.aida/skills-catalog.json | jq '.skills[] | {name, category, description}'

# Option C: Hybrid
# Scan local + fetch remote + merge
```text

## 2. Technical Concerns

### Integration Complexity

**Low Complexity** (Agents/Commands):

- Filesystem scanning is straightforward
- Frontmatter parsing with grep/sed
- Existing patterns in codebase (validate-templates.sh)
- No external dependencies

**Medium Complexity** (Skills):

- Architecture investigation required
- Unknown integration points
- Potential external catalog dependency
- Category taxonomy validation

### Loose Coupling Requirements

**Achieved Through**:

1. **CLI Scripts as Standalone Units**:
   - Executable without AIDA context
   - Testable independently
   - No bash/zsh-specific features
   - POSIX-compliant where possible

2. **Interface Contracts**:
   - Scripts accept standard arguments
   - Output to stdout (not direct file writes)
   - Exit codes indicate success/failure
   - Consistent output format

3. **Variable Expansion Strategy**:
   - Install-time: `${AIDA_HOME}` → `~/.aida`
   - Runtime: Scripts resolve paths dynamically
   - No hardcoded absolute paths

**Example Interface Contract**:

```bash
# scripts/list-commands.sh --category workflow
#
# Output Format:
# === User-Level Commands (workflow) ===
# /start-work - Begin work on GitHub issue
# /implement - Implement features with auto-commit
# ...
#
# Exit Codes:
# 0 - Success
# 1 - General error
# 2 - Invalid arguments
# 3 - Not found (no agents/commands/skills)
```text

### API/Interface Design

**Script Invocation Interface**:

```bash
# Agent listing
scripts/list-agents.sh [--format text|json]

# Command listing with category filter
scripts/list-commands.sh [--category <name>] [--format text|json]

# Skill listing (Phase 2)
scripts/list-skills.sh [<category>] [--format text|json]
```text

**Output Format Standards**:

```text
=== Section Header (count) ===

name - description
name - description

→ Usage: <usage hint>
```text

**JSON Output Format** (Phase 2):

```json
{
  "agents": {
    "user_level": [
      {"name": "code-reviewer", "description": "...", "model": "claude-sonnet-4.5"}
    ],
    "project_level": [...]
  }
}
```text

## 3. Dependencies & Integration

### System Components Affected

**Direct Dependencies**:

1. **Filesystem Structure**:
   - `~/.claude/agents/` - User agent definitions
   - `.claude/agents/` - Project agent definitions
   - `~/.claude/commands/` - User commands
   - `.claude/commands/` - Project commands
   - Skills location TBD

2. **Frontmatter Parsing**:
   - YAML frontmatter extraction
   - Validation of required fields
   - No full file content parsing (privacy)

3. **Installation System**:
   - Variable substitution (`${AIDA_HOME}`, etc.)
   - Script permissions (executable)
   - Dev mode symlink handling

**Indirect Dependencies**:

1. **Agent System**:
   - `claude-agent-manager` - Optional formatting enhancement
   - Agent frontmatter standards (name, description, model)

2. **Command System**:
   - Slash command invocation mechanism
   - Argument passing from commands to scripts

3. **Skills System** (Phase 2):
   - Skills catalog architecture (unknown)
   - Category taxonomy (28 categories)
   - Skill registration/discovery mechanism

### Integration with Existing Patterns

**Leverages Existing Code**:

```bash
# scripts/validate-templates.sh already does frontmatter parsing
extract_frontmatter_field() {
    # Reuse this pattern for list-agents.sh
}
```text

**Extends Existing Workflows**:

- `/create-agent` → adds agent that appears in `/agent-list`
- `/create-command` → adds command that appears in `/command-list`
- Agent creation validates against discovered conflicts

**Follows Established Patterns**:

- CLI scripts in `scripts/` directory
- Slash commands in `templates/commands/.aida/`
- Output to stdout, errors to stderr
- Exit codes indicate status

### Agent Discovery & Invocation

**Discovery Mechanism**:

```bash
# 1. Find all agent definition files
find ~/.claude/agents -name "*.md" -type f

# 2. Check if file has required frontmatter
grep -q "^name:" "$file" && grep -q "^description:" "$file"

# 3. Extract metadata
name=$(sed -n 's/^name: \(.*\)/\1/p' "$file")

# 4. Deduplicate (handle symlinks in dev mode)
realpath "$file" >> seen_files.txt

# 5. Categorize (user vs project)
if [[ "$file" =~ /.claude/agents/ ]]; then
    project_agents+=("$name")
else
    user_agents+=("$name")
fi
```text

**Invocation from Commands**:

```markdown
# In slash command file
1. Run bash script:
   ```bash
   ${AIDA_HOME}/scripts/list-agents.sh
```text

2. Capture output

3. Display to user

```text

## 4. Effort & Complexity

### Estimated Complexity: Medium (M) for Phase 1

**Breakdown**:

| Component | Complexity | Effort | Reason |
|-----------|-----------|--------|--------|
| `list-agents.sh` | Simple | 4h | Straightforward scanning, existing patterns |
| `list-commands.sh` | Simple | 4h | Similar to agents, add category filter |
| Slash commands | Trivial | 2h | Thin wrappers around scripts |
| Frontmatter parsing | Simple | 3h | Reuse validate-templates.sh patterns |
| Deduplication logic | Medium | 4h | Handle symlinks, realpath resolution |
| Output formatting | Simple | 3h | Consistent formatting, colors, usage hints |
| Testing | Medium | 6h | Test user/project separation, edge cases |
| Documentation | Simple | 2h | Usage docs, integration patterns |
| **Phase 1 Total** | **Medium** | **28h** | **~3.5 days** |

**Phase 2 (Skills System)**:

| Component | Complexity | Effort | Reason |
|-----------|-----------|--------|--------|
| Skills architecture investigation | Large | 8h | Unknown system, research required |
| `list-skills.sh` implementation | Medium-Large | 8-12h | Depends on architecture findings |
| Category filtering | Medium | 4h | 28 categories, taxonomy validation |
| Progressive disclosure | Simple | 3h | Category-first, then details |
| Integration testing | Medium | 6h | Validate across all three lists |
| **Phase 2 Total** | **Large** | **29-35h** | **~4-5 days** |

### Key Effort Drivers

**Phase 1**:

1. **Frontmatter Parsing Robustness**:
   - Handle malformed YAML gracefully
   - Missing required fields
   - Invalid frontmatter structure
   - Multi-line field values

2. **Deduplication Logic**:
   - Dev mode creates symlinks
   - Same agent appears twice (source + symlink)
   - Need realpath resolution
   - Track seen files

3. **Two-Tier Discovery**:
   - Scan both user and project levels
   - Separate in output
   - Handle missing directories
   - Permission errors

4. **Output Formatting**:
   - Consistent format across all three commands
   - Color-coded (counts, categories, hints)
   - Screen reader friendly
   - Works without color

**Phase 2**:

1. **Skills Architecture Investigation**:
   - Unknown storage format
   - Unknown discovery mechanism
   - Unknown category system
   - Unknown invocation pattern

2. **Category System**:
   - 28 categories to validate
   - Category filtering logic
   - Progressive disclosure (177 skills)
   - Category-first UI

3. **Integration Testing**:
   - Validate all three listing commands work together
   - Consistent behavior across agents/commands/skills
   - Test JSON output option

### Risk Areas

**High Risk**:

1. **Skills Architecture Unknown**:
   - Cannot implement `/skill-list` without architecture
   - May require significant rework
   - Could affect agents/commands integration
   - **Mitigation**: Defer to Phase 2, investigate first

2. **Frontmatter Parsing Edge Cases**:
   - Malformed YAML crashes script
   - Multi-line fields not handled
   - Comments in frontmatter
   - **Mitigation**: Robust parsing, validation, error handling

**Medium Risk**:

3. **Performance Target (<1s)**:
   - 177 skills + agents + commands could be slow
   - Filesystem scanning overhead
   - Frontmatter parsing for each file
   - **Mitigation**: Optimize with parallel processing, caching (Phase 2)

4. **Symlink Deduplication**:
   - Dev mode symlinks complicate discovery
   - Need realpath resolution
   - Cross-platform compatibility
   - **Mitigation**: Use `realpath` command, test on macOS/Linux

**Low Risk**:

5. **Output Format Consistency**:
   - Three commands need identical formatting
   - **Mitigation**: Shared formatting functions, style guide

6. **Path Sanitization**:
   - Replace absolute paths with variables
   - **Mitigation**: Simple sed/awk replacement

## 5. Questions & Clarifications

### Critical (Blocking `/skill-list`)

**Skills Catalog Architecture**:

1. Where are skills stored? (`templates/skills/`, external catalog, both?)
2. What file format? (YAML, JSON, Markdown?)
3. How do skills become available? (filesystem discovery, registry, API?)
4. How does `claude-agent-manager` invoke skills? (subprocess, import, MCP?)
5. What's the skill schema? (name, description, category, dependencies?)
6. Are AIDA skills separate from Claude Code built-in skills?

**Category System**:

7. Confirm 28 categories for skills (from Claude Code skills catalog?)
8. Should commands use same categories as skills? (or separate taxonomy?)
9. Is category hierarchical (parent/child) or flat?

**Integration Points**:

10. Does `claude-agent-manager` need to know about skills?
11. Do skills have frontmatter like agents/commands?
12. How to test skill invocation (integration tests)?

### Important (Design Decisions)

**Output Format**:

13. Start with plain text only? (defer JSON to Phase 2?)
14. Should output be paginated? (177 skills is long)
15. Color scheme: green=counts, blue=categories, yellow=hints? (accessibility OK?)

**Symlink Handling**:

16. Show "→ symlink to X" in output? (or hide symlink detail?)
17. Prefer symlink target or symlink location for display?

**Performance**:

18. Is <1s hard requirement or aspirational? (affects caching decision)
19. Should we cache results? (trade-off: freshness vs speed)
20. Parallel processing acceptable? (may break on some platforms)

### Nice to Have (Future Enhancements)

**Phase 2+ Features**:

21. Search within listings (`/agent-list --search "security"`)
22. Filter by model (`/agent-list --model sonnet`)
23. Interactive selection mode (pick from list)
24. Export to JSON for automation

**Validation**:

25. Should listings warn about missing frontmatter?
26. Validate category against taxonomy?
27. Check for naming conflicts?

## 6. Recommended Implementation Strategy

### Phase 1: MVP (Agents + Commands)

**Step 1**: Create CLI scripts (scripts/list-agents.sh, scripts/list-commands.sh)

- Filesystem scanning with two-tier discovery
- Frontmatter parsing (reuse validate-templates.sh patterns)
- Deduplication logic (symlink handling)
- Output formatting (consistent style)
- Error handling (graceful failures, no path exposure)

**Step 2**: Create slash commands (templates/commands/.aida/)

- `/agent-list` - Direct script invocation
- `/command-list` - Direct script invocation with optional `--category`
- Thin wrappers (no agent orchestration needed)

**Step 3**: Testing

- User vs project separation
- Symlink deduplication
- Category filtering
- Permission error handling
- Missing directory handling

**Step 4**: Documentation

- Usage examples in command files
- Integration patterns documented
- Troubleshooting guide

### Phase 2: Skills System (After Architecture Investigation)

**Step 1**: Skills architecture investigation

- Research skills catalog location/format
- Document integration patterns
- Define skill schema
- Test skill invocation manually

**Step 2**: Implement skills listing

- Create `scripts/list-skills.sh`
- Category-first approach (show categories, then drill down)
- Progressive disclosure (avoid dumping 177 skills)
- Integration with existing listing commands

**Step 3**: Enhanced features

- JSON output option (`--format json`)
- Search functionality (`--search <term>`)
- Performance optimization (caching)

## 7. Integration Patterns Reference

### Pattern: Direct Script Invocation (Recommended)

```markdown
# Slash command delegates to CLI script
1. Execute script: ${AIDA_HOME}/scripts/list-agents.sh
2. Display output to user
3. Handle errors gracefully
```text

**Pros**:

- Simple, fast, testable
- No agent overhead
- Loose coupling

**Cons**:

- No AI-enhanced formatting
- Static output format

**Use When**: Data display is straightforward (Phase 1)

### Pattern: Agent-Orchestrated Invocation (Optional)

```markdown
# Slash command delegates to agent
1. Invoke claude-agent-manager
2. Agent executes script
3. Agent enhances/formats output
4. Display to user
```text

**Pros**:

- AI-enhanced formatting
- Intelligent filtering
- Context-aware display

**Cons**:

- Slower (agent invocation overhead)
- More complex testing
- Tighter coupling

**Use When**: Output needs AI decision-making (Phase 2+ features)

### Pattern: Hybrid Approach (Future)

```markdown
# Slash command with optional agent enhancement
1. Execute script for raw data
2. If --enhance flag: Invoke agent to format
3. Otherwise: Display raw output
4. User chooses behavior
```text

**Best of Both**: Performance when needed, intelligence when wanted

## Conclusion

**Phase 1 (Agents/Commands)** is well-defined and ready to implement:

- **Complexity**: Medium (M)
- **Effort**: ~3.5 days
- **Integration Pattern**: Direct script invocation
- **Dependencies**: None (existing filesystem/frontmatter patterns)

**Phase 2 (Skills System)** requires architecture investigation:

- **Complexity**: Large (L)
- **Effort**: ~4-5 days (after investigation)
- **Integration Pattern**: TBD (depends on skills architecture)
- **Dependencies**: Skills catalog architecture definition

**Recommendation**: Proceed with Phase 1 immediately. Investigate skills architecture in parallel, implement Phase 2 once clarified.

---

**Next Steps**:

1. **shell-systems-ux-designer**: Implement CLI scripts with robust frontmatter parsing
2. **configuration-specialist**: Add `category` field to all command frontmatter
3. **integration-specialist** (this agent): Investigate skills catalog architecture
4. **claude-agent-manager**: Create slash command definitions
5. **privacy-security-auditor**: Review path sanitization and privacy controls
