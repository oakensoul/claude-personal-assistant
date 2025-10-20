---
title: "ADR-003: Rename agents-global to project/agents"
status: "Accepted"
date: "2025-10-20"
deciders: ["system-architect", "oakensoul"]
tags: ["architecture", "naming", "agents", "breaking-change"]
---

# ADR-003: Rename agents-global to project/agents

## Status

**Accepted** - Implemented in v0.2.0

## Context

The directory `.claude/agents-global/` was introduced to contain project-specific context for globally-defined agents. However, the name "agents-global" created significant confusion:

### Problems with "agents-global"

1. **Semantically incorrect**: "global" suggests universal/shared scope, but the content is project-specific
2. **Contradicts ADR-002 terminology**: ADR-002 defines user-level as "global" and project-level as "specific"
3. **Confuses tooling**: During implementation of `list-agents.sh`, the script initially attempted to discover agent definitions from this directory, requiring special filtering logic
4. **Counterintuitive**: New contributors consistently misunderstand the purpose (multiple instances documented)
5. **Requires constant explanation**: "agents-global is actually project-specific" became a common clarification

### Evidence

Issue discovered during Issue #54 (discoverability commands) implementation:

- `list-agents.sh` generated warnings for all files in `.claude/agents-global/`
- Script had to add special logic: "Skip if path contains project/agents"
- User question: "What's up with all the warnings?"
- System architect consultation confirmed architectural incorrectness

### The Relationship

**What the directory actually contains:**

- Project-specific instructions for globally-defined agents
- Context loaded when a global agent works on THIS project
- NOT agent definitions (those live in `~/.claude/agents/`)

**Example:**

- Global agent definition: `~/.claude/agents/system-architect/`
- Project context: `.claude/agents-global/system-architect/index.md` ❌ (old)
- Project context: `.claude/project/agents/system-architect/index.md` ✓ (new)

## Decision Drivers

- **Clarity**: Directory name should accurately reveal its purpose
- **Consistency**: Align with architectural terminology and ADR-002
- **Maintainability**: Eliminate counterintuitive naming requiring explanation
- **Tooling**: Enable discovery tools to work correctly without special cases
- **Future-proofing**: Establish scalable pattern for skills and commands
- **Self-documenting**: Follow principle of least surprise

## Considered Options

### Option 1: `.claude/project/agents/` ✓ CHOSEN

**Structure:**

```text
.claude/project/
├── agents/
│   └── system-architect/
├── commands/         (future)
└── skills/           (future)
```

**Pros:**

- Self-documenting: "project/agents" clearly signals "project context for agents"
- Clean namespace: Everything under `project/` is project-specific
- Scalable pattern: Extends naturally to `project/commands/`, `project/skills/`
- Mirrors structure: `~/.claude/agents/` → `.claude/project/agents/` (parallel)
- Shorter paths: Less typing, cleaner

**Cons:**

- Less explicit about "context" vs "definitions" (mitigated by namespace)

### Option 2: `.claude/agent-context/`

**Structure:**

```text
.claude/
├── agent-context/
│   └── system-architect/
├── command-context/
└── skill-context/
```

**Pros:**

- Very explicit: "agent-context" removes all ambiguity
- Clear it's context, not definitions

**Cons:**

- Doesn't indicate project-specific scope
- More verbose
- Doesn't establish clear namespace boundary

### Option 3: `.claude/project/agent-context/`

**Structure:**

```text
.claude/project/
├── agent-context/
│   └── system-architect/
├── command-context/
└── skill-context/
```

**Pros:**

- Most explicit option
- No ambiguity whatsoever

**Cons:**

- Redundant: "project/" already signals it's context
- Longer paths
- Extra nesting level

### Option 4: Keep as-is with documentation

**Pros:**

- No breaking changes
- No migration needed

**Cons:**

- Doesn't fix architectural incorrectness
- Confusion persists
- Tooling requires workarounds
- Technical debt accumulates

## Decision Outcome

**Chosen option:** `.claude/project/agents/` (Option 1)

### Rationale

1. **Semantic clarity**: "project/" establishes namespace; "agents/" specifies entity type
2. **Self-documenting**: Path reads as "project context for agents"
3. **Scalable**: Pattern extends naturally to other entity types
4. **Parallel structure**: Mirrors `~/.claude/agents/` with clear differentiation
5. **Simplicity**: Shortest path that achieves clarity goals
6. **Architectural correctness**: Aligns with ADR-002 terminology

### Path Comparison

| Entity | Global Definition | Project Context |
|--------|------------------|-----------------|
| Agents | `~/.claude/agents/system-architect/` | `.claude/project/agents/system-architect/` |
| Commands | `~/.claude/commands/.aida/start-work/` | `.claude/project/commands/start-work/` (future) |
| Skills | `~/.claude/skills/pdf/` | `.claude/project/skills/pdf/` (future) |

The pattern is consistent and self-explanatory.

## Consequences

### Positive

- **Self-documenting structure**: New contributors understand immediately
- **Tooling simplification**: No special cases needed for discovery
- **Architectural alignment**: Terminology matches ADR-002
- **Scalable pattern**: Established for commands/skills/agents
- **Reduced cognitive load**: No more explaining counterintuitive naming

### Negative

- **Breaking change**: Requires migration from v0.1.x
- **Migration impact**: ~181 references updated across 41 files
- **User migration**: Existing projects need to rename directory

### Neutral

- **One-time cost**: Refactoring effort
- **Documentation updates**: All docs reflect new structure
- **Version bump**: Breaking change requires v0.2.0

## Migration

### For Framework Development

1. ✓ Rename directory: `.claude/agents-global/` → `.claude/project/agents/`
2. ✓ Update all references (~181 occurrences, 41 files)
3. ✓ Create this ADR
4. ⏳ Update ADR-002 references
5. ⏳ Create migration script for users
6. ⏳ Update CHANGELOG with breaking change notice
7. ⏳ Version bump to 0.2.0

### For Users (Migration Script)

```bash
# Automatic migration in install.sh
if [ -d ".claude/agents-global" ] && [ ! -d ".claude/project/agents" ]; then
    echo "Migrating .claude/agents-global/ to .claude/project/agents/"
    mkdir -p .claude/project
    mv .claude/agents-global .claude/project/agents
    echo "✓ Migration complete"
fi
```

### Manual Migration

If needed, users can migrate manually:

```bash
cd /path/to/project
mkdir -p .claude/project
mv .claude/agents-global .claude/project/agents
```

## Validation

- [x] Aligns with ADR-002 two-tier architecture
- [x] Follows self-documenting naming principles
- [x] Consistent with domain language
- [x] Removes architectural contradictions
- [x] Reviewed by system-architect agent
- [x] Tested with discovery tools

## Implementation Notes

### Files Updated

- Scripts: `list-agents.sh` (comment updated)
- Documentation: ADR-002, README.md, CHANGELOG.md, architecture docs
- Templates: All agent templates (20+ files)
- Project configs: All `.claude/project/agents/*/index.md` files
- Issue tracking: Historical issues and analyses

### Testing Performed

- `list-agents.sh` - No warnings, correct discovery
- `list-commands.sh` - Still works correctly
- Directory structure - Clean, no orphaned files

## References

- [ADR-002: Two-Tier Agent Architecture](./adr-002-two-tier-agent-architecture.md)
- [Issue #54: Implement Discoverability Commands](../../../.github/issues/in-progress/issue-54/)
- System Architect analysis (2025-10-20)
- User feedback: "Is the name 'agents-global' too confusing?"

## Related Decisions

- ADR-002: Two-Tier Agent Architecture (updated to reflect new paths)
- Future: When implementing skill/command context, follow same pattern

---

**Decision**: Rename `.claude/agents-global/` to `.claude/project/agents/`
**Impact**: Breaking change, requires v0.2.0
**Status**: Implemented (2025-10-20)
