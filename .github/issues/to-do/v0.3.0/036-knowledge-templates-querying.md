---
title: "Implement knowledge templates and querying"
labels:
  - "type: feature"
  - "priority: p1"
  - "effort: small"
  - "milestone: 0.3.0"
---

# Implement knowledge templates and querying

## Description

Create templates for different knowledge types (pattern, technique, insight) and implement comprehensive knowledge querying and browsing capabilities with Obsidian integration support.

## Acceptance Criteria

- [ ] Pattern template created and functional
- [ ] Technique template created and functional
- [ ] Insight template created and functional
- [ ] Templates are accessible via CLI
- [ ] Knowledge querying supports natural language
- [ ] Knowledge querying supports CLI commands
- [ ] Knowledge browsing by category/tag/project works
- [ ] Recent knowledge listing works
- [ ] Obsidian export functionality works (if configured)
- [ ] Templates use consistent formatting

## Implementation Notes

### Knowledge Templates

**Pattern Template** (`~/.claude/templates/knowledge/pattern.md`):

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
```text

**Technique Template** (`~/.claude/templates/knowledge/technique.md`):

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
```

**Insight Template** (`~/.claude/templates/knowledge/insight.md`):

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
```text

### Knowledge Querying

**Natural Language**:

```

"What did I learn about React hooks?"
"Show me knowledge about memory management"
"Find patterns for API design"
"What techniques do I have for debugging?"
"Show me insights from October"

```text

**CLI Commands**:

```bash
# Search knowledge
aida knowledge search "React hooks"

# List by filters
aida knowledge list --category react --tag hooks
aida knowledge list --type pattern
aida knowledge list --project alpha

# Browse recent
aida knowledge recent --limit 10

# Show specific entry
aida knowledge show "React useEffect Cleanup"

# List by project
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

If Obsidian vault is configured, support export:

```bash
$ aida knowledge export --obsidian

Exporting knowledge to Obsidian vault...

Created notes:
  ~/Knowledge/Obsidian-Vault/Learnings/React-useEffect-Cleanup.md
  ~/Knowledge/Obsidian-Vault/Patterns/API-Rate-Limiting-Pattern.md
  ~/Knowledge/Obsidian-Vault/Techniques/PostgreSQL-Index-Strategy.md

✓ Exported 3 knowledge entries
✓ Created backlinks and tags
✓ Updated knowledge index
```javascript

**Obsidian Note Format**:

```markdown
---
tags: [react, useEffect, hooks, memory-management]
created: 2025-10-04
source: AIDA
category: React, Best Practices
---

# React useEffect Cleanup Functions

## Learning

React useEffect needs cleanup functions for subscriptions to prevent memory leaks.

## Details

When a useEffect subscribes to events, WebSocket connections, or intervals, it must return a cleanup function that unsubscribes/disconnects when the component unmounts or dependencies change.

## Example

\`\`\`typescript
useEffect(() => {
  const subscription = dataSource.subscribe(data => {
    setData(data);
  });

  // Cleanup function
  return () => {
    subscription.unsubscribe();
  };
}, [dataSource]);
\`\`\`

## Related

- [[React Hooks Best Practices]]
- [[Memory Management in React]]

## Projects

- [[Project Alpha]] - Chat feature
```

### Query Results Format

```text
Found 3 knowledge entries about "React hooks":

1. React useEffect Cleanup Functions [Learning]
   2025-10-04 | #react #useEffect #hooks
   "React useEffect needs cleanup functions for subscriptions..."

2. Custom React Hooks Pattern [Pattern]
   2025-10-03 | #react #hooks #patterns
   "Best practices for creating reusable custom hooks..."

3. React Hooks Optimization Technique [Technique]
   2025-10-02 | #react #hooks #performance
   "Use useMemo and useCallback to prevent unnecessary re-renders..."

[View entry? Enter number or 'q' to quit]
```

## Dependencies

- #031 (Memory categories structure)
- #035 (Knowledge capture mechanism)

## Related Issues

- Part of #023 (Knowledge capture system epic)
- #016 (Obsidian templates)
- #032 (Memory search)

## Definition of Done

- [ ] All three templates created
- [ ] Templates are well-structured and documented
- [ ] Knowledge querying works via natural language
- [ ] CLI commands functional
- [ ] Filtering by category/tag/project works
- [ ] Recent knowledge listing works
- [ ] Obsidian export functional (if configured)
- [ ] Query results are well-formatted
- [ ] Documentation explains templates
- [ ] Examples demonstrate usage
