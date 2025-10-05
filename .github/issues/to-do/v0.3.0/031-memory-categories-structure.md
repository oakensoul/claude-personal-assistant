---
title: "Implement memory categories and storage structure"
labels:
  - "type: feature"
  - "priority: p1"
  - "effort: medium"
  - "milestone: 0.3.0"
---

# Implement memory categories and storage structure

## Description

Create the enhanced memory storage structure with distinct categories (tasks, knowledge, decisions, preferences, context, history) and their specific storage mechanisms. This transforms memory from simple conversation logs into an organized knowledge system.

## Acceptance Criteria

- [ ] Memory directory structure created with all categories:
  - `~/.claude/memory/tasks/` (active, completed, archived)
  - `~/.claude/memory/knowledge/` (learnings, resources, patterns)
  - `~/.claude/memory/decisions/` (decisions.md, adr/)
  - `~/.claude/memory/preferences/` (preferences.md)
  - `~/.claude/memory/context/` (current.md, projects.md)
  - `~/.claude/memory/history/` (monthly archives)
- [ ] Each category has its own storage and retrieval mechanism
- [ ] Memory entry format is consistent across categories
- [ ] Memory entries include metadata (date, category, tags, project)
- [ ] Memory entries support markdown formatting
- [ ] Memory entries support cross-references and links
- [ ] Documentation explains memory structure and organization

## Implementation Notes

### Directory Structure

```
~/.claude/memory/
├── tasks/
│   ├── active.md
│   ├── completed.md
│   └── archived.md
├── knowledge/
│   ├── learnings.md
│   ├── resources.md
│   └── patterns.md
├── decisions/
│   ├── decisions.md
│   └── adr/
│       ├── 001-first-decision.md
│       └── 002-second-decision.md
├── preferences/
│   └── preferences.md
├── context/
│   ├── current.md
│   └── projects.md
└── history/
    ├── 2025-10.md
    └── 2025-11.md
```

### Memory Entry Format

```markdown
## [Title/Summary]

**Date**: 2025-10-04
**Category**: knowledge|task|decision|preference|context
**Tags**: #tag1 #tag2 #tag3
**Project**: [project-name] (optional)

[Content]

**Related**:
- Link to related memory
- Link to related project
```

### Category-Specific Formats

**Tasks**:
- Status: active/completed/archived
- Priority: p0/p1/p2/p3
- Due date (optional)
- Related project

**Knowledge**:
- Type: learning/pattern/technique/insight
- Source: where this came from
- Applied in: where it's been used

**Decisions**:
- Status: proposed/accepted/rejected/superseded
- Decision number (for ADRs)
- Alternatives considered

**Preferences**:
- Category: coding/workflow/communication/etc
- Applies to: global or project-specific

**Context**:
- Current state tracking
- Active projects
- Focus areas
- Blockers

## Dependencies

- #007 (Memory templates provide foundation)
- #002 (Template system for memory storage)

## Related Issues

- Part of #022 (Enhanced memory system epic)
- #032 (Memory search builds on this structure)
- #033 (Memory export uses this structure)

## Definition of Done

- [ ] All memory category directories created
- [ ] Each category has appropriate structure
- [ ] Memory entry format documented
- [ ] Example entries provided for each category
- [ ] Category-specific formats defined
- [ ] Documentation explains when to use each category
- [ ] Templates available for common entry types
