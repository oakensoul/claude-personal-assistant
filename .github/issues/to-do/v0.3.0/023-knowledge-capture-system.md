---
title: "Implement knowledge capture system"
labels:
  - "type: epic"
  - "priority: p1"
  - "effort: medium"
  - "milestone: 0.3.0"
---

# Implement knowledge capture system

> **Epic**: This feature has been broken down into smaller, more focused issues. See the sub-issues below for implementation details.

## Description

Implement a system for capturing and organizing learnings, insights, and discoveries from daily work. This allows users to build a personal knowledge base of reusable patterns, techniques, and best practices.

## Sub-Issues

This epic is broken down into the following issues:

- #035 - Knowledge capture mechanism
- #036 - Knowledge templates and querying

## Acceptance Criteria

- [ ] Natural language knowledge capture: "Remember that [learning]"
- [ ] Knowledge categorization by topic, technology, and context
- [ ] Knowledge tagging for better organization
- [ ] Knowledge querying: "What did I learn about React?"
- [ ] Knowledge linking to projects and contexts
- [ ] Knowledge export to Obsidian (if configured)
- [ ] Knowledge templates for common types (pattern, technique, insight)
- [ ] Knowledge browsing and navigation
- [ ] Knowledge search with relevance ranking

## Implementation Notes

### Knowledge Capture Flow

**User**: "Remember that React useEffect needs cleanup functions for subscriptions to prevent memory leaks"

**AIDA**:

```text
✓ Captured knowledge about React useEffect cleanup

Category: React, Best Practices
Tags: #react #useEffect #memory-management #hooks

Saved to: ~/.claude/memory/knowledge/learnings.md

Would you like to:
  [E] Elaborate with example
  [L] Link to project
  [S] Share to Obsidian
  [D] Done
```javascript

### Knowledge Entry Format

```markdown
## React useEffect Cleanup Functions

**Date Learned**: 2025-10-04
**Category**: React, Best Practices
**Tags**: #react #useEffect #memory-management #hooks
**Source**: Work on Project Alpha

### Learning

React useEffect needs cleanup functions for subscriptions to prevent memory leaks.

### Detail

When a useEffect subscribes to events, WebSocket connections, or intervals, it must return a cleanup function that unsubscribes/disconnects when the component unmounts or dependencies change.

### Example

```typescript
useEffect(() => {
  const subscription = dataSource.subscribe(data => {
    setData(data);
  });

  // Cleanup function
  return () => {
    subscription.unsubscribe();
  };
}, [dataSource]);
```

### When to Apply

- WebSocket connections
- Event listeners
- setInterval/setTimeout
- Third-party subscriptions
- Any resource that needs cleanup

**Related Knowledge**:

- [[React Hooks Best Practices]]
- [[Memory Management in React]]

**Used In Projects**:

- Project Alpha (chat feature)

```text

### Knowledge Templates

**Pattern Template**:
```markdown
## [Pattern Name]

**Category**: [Category]
**Tags**: [Tags]
**Date**: [Date]

### Problem

[What problem does this pattern solve?]

### Solution

[How does the pattern solve it?]

### Example

[Code or concrete example]

### When to Use

- [Scenario 1]
- [Scenario 2]

### Trade-offs

**Pros**:
- [Advantage 1]

**Cons**:
- [Disadvantage 1]
```

**Technique Template**:

```markdown
## [Technique Name]

**Category**: [Category]
**Tags**: [Tags]
**Date**: [Date]

### What

[Brief description of technique]

### Why

[Why is this technique useful?]

### How

[Step-by-step or code example]

### Gotchas

- [Common mistake 1]
- [Common mistake 2]
```text

**Insight Template**:

```markdown
## [Insight Title]

**Category**: [Category]
**Tags**: [Tags]
**Date**: [Date]
**Context**: [What prompted this insight?]

### Insight

[The core realization or learning]

### Implications

[How does this change your understanding or approach?]

### Action Items

- [How to apply this insight]
```

### Knowledge Querying

```bash
# Natural language queries
"What did I learn about React hooks?"
"Show me knowledge about memory management"
"Find patterns for API design"

# CLI commands
aida knowledge search "React hooks"
aida knowledge list --category react --tag hooks
aida knowledge recent --limit 10
aida knowledge by-project alpha
```

### Knowledge Organization

```text
~/.claude/memory/knowledge/
├── learnings.md           # General learnings
├── patterns/              # Design and code patterns
│   ├── react.md
│   ├── api-design.md
│   └── architecture.md
├── techniques/            # Specific techniques
│   ├── debugging.md
│   ├── optimization.md
│   └── testing.md
├── insights/              # Higher-level insights
│   ├── productivity.md
│   └── decision-making.md
└── resources/             # Links and references
    └── resources.md
```

### Obsidian Integration

If user has Obsidian configured, knowledge can be exported:

```bash
$ aida knowledge export --obsidian

Exporting knowledge to Obsidian vault...

Created notes:
  ~/Knowledge/Obsidian-Vault/Learnings/React-useEffect-Cleanup.md
  ~/Knowledge/Obsidian-Vault/Learnings/API-Rate-Limiting-Pattern.md
  ~/Knowledge/Obsidian-Vault/Learnings/PostgreSQL-Index-Strategy.md

✓ Exported 3 knowledge entries
✓ Created backlinks and tags
✓ Updated knowledge index
```

## Dependencies

- #022 (Enhanced memory system provides storage)
- #007 (Memory templates provide foundation)

## Related Issues

- #024 (Decision documentation similar workflow)
- #016 (Obsidian templates for export)
- #009 (Secretary agent helps organize knowledge)

## Definition of Done

- [ ] Natural language knowledge capture works
- [ ] Knowledge is properly categorized and tagged
- [ ] Knowledge templates are available and useful
- [ ] Knowledge search returns relevant results
- [ ] Knowledge querying supports multiple methods
- [ ] Obsidian export works (if vault configured)
- [ ] Knowledge browsing is intuitive
- [ ] CLI commands are well-documented
- [ ] Examples demonstrate common use cases
