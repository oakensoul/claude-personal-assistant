---
title: "Implement ADR system and templates"
labels:
  - "type: feature"
  - "priority: p2"
  - "effort: small"
  - "milestone: 0.3.0"
---

# Implement ADR system and templates

## Description

Create Architecture Decision Record (ADR) and Product Decision Record (PDR) templates following industry best practices. Implement the decision numbering system and status workflow.

## Acceptance Criteria

- [ ] ADR template created following Michael Nygard's format
- [ ] PDR template created for product decisions
- [ ] Decision numbering system implemented (automatic)
- [ ] Decision status workflow defined (proposed → accepted → superseded)
- [ ] Decision metadata structure defined
- [ ] Templates stored in appropriate location
- [ ] Templates include comprehensive sections
- [ ] Documentation explains when to use ADR vs PDR
- [ ] Example decisions provided

## Implementation Notes

### ADR Template

Location: `~/.claude/templates/decisions/adr-template.md`

```markdown
# ADR-XXX: [Decision Title]

**Date**: [Date]
**Status**: [Proposed|Accepted|Rejected|Superseded|Deprecated]
**Context**: [Project or System]
**Tags**: [Tags]

## Context

[What is the issue motivating this decision?]

## Decision

[What is the change being proposed or made?]

## Rationale

[Why this decision? Key factors and reasoning.]

## Alternatives Considered

### [Alternative 1]
- **Pros**: [Advantages]
- **Cons**: [Disadvantages]
- **Why Not**: [Reason for not choosing]

### [Alternative 2]
- **Pros**: [Advantages]
- **Cons**: [Disadvantages]
- **Why Not**: [Reason for not choosing]

## Consequences

**Positive**:
- [Good outcomes]

**Negative**:
- [Trade-offs and costs]

**Neutral**:
- [Neutral implications]

## Follow-up Actions

- [ ] [Action item 1]
- [ ] [Action item 2]

## Related Decisions

- [Link to related ADRs]

## Superseded By

- [Link if decision is superseded, otherwise "None (current decision)"]

---

**Decision Made By**: [Person/Team]
**Reviewed By**: [Reviewers]
```text

### PDR Template

Location: `~/.claude/templates/decisions/pdr-template.md`

```markdown
# PDR-XXX: [Product Decision Title]

**Date**: [Date]
**Status**: [Proposed|Accepted|Rejected|Superseded]
**Impact**: [Users|Business|Team]
**Tags**: [Tags]

## Problem

[What user or business problem are we addressing?]

## Decision

[What product decision are we making?]

## Rationale

[Why this decision? User research, data, strategic alignment.]

## Options Considered

### [Option 1]
- **User Value**: [How this helps users]
- **Business Value**: [How this helps business]
- **Effort**: [Implementation cost]
- **Why Not**: [Reason for not choosing]

### [Option 2]
- **User Value**: [How this helps users]
- **Business Value**: [How this helps business]
- **Effort**: [Implementation cost]
- **Why Not**: [Reason for not choosing]

## Success Criteria

[How will we measure if this decision was right?]

## Risks

[What could go wrong?]

## Timeline

[When will this be implemented/reviewed?]

## Related Decisions

- [Link to related product or technical decisions]

---

**Decision Made By**: [Person/Team]
**Stakeholders**: [Who was consulted]
```

### Decision Numbering System

**ADR Numbering**:

- Auto-increment from 001
- Check `~/.claude/memory/decisions/adr/` for highest number
- Format: `ADR-001`, `ADR-002`, etc.

**PDR Numbering**:

- Auto-increment from 001
- Check `~/.claude/memory/decisions/pdr/` for highest number
- Format: `PDR-001`, `PDR-002`, etc.

**Numbering Logic**:

```bash
# Find next ADR number
find ~/.claude/memory/decisions/adr/ -name "*.md" | \
  sed 's/.*adr-\([0-9]*\).*/\1/' | \
  sort -n | \
  tail -1 | \
  awk '{printf "%03d\n", $1+1}'
```text

### Decision Status Workflow

```

Proposed → Accepted → [Superseded|Deprecated]
         ↓
      Rejected

```text

**Status Definitions**:

- **Proposed**: Under consideration, seeking feedback
- **Accepted**: Active decision, being implemented
- **Rejected**: Decided against, with reasoning
- **Superseded**: Replaced by newer decision (must reference new ADR/PDR)
- **Deprecated**: No longer recommended but not formally replaced

**Status Transitions**:

- `Proposed → Accepted`: Decision approved
- `Proposed → Rejected`: Decision declined
- `Accepted → Superseded`: New decision replaces this
- `Accepted → Deprecated`: No longer current practice

### Decision Directory Structure

```

~/.claude/memory/decisions/
├── decisions.md           # Index of all decisions
├── adr/                   # Architecture Decision Records
│   ├── 001-database-choice.md
│   ├── 002-api-framework.md
│   └── 003-deployment-strategy.md
├── pdr/                   # Product Decision Records
│   ├── 001-personality-builder.md
│   └── 002-obsidian-integration.md
└── templates/
    ├── adr-template.md
    └── pdr-template.md

```text

### Decisions Index Format

`~/.claude/memory/decisions/decisions.md`:

```markdown
# Decision Index

## Architecture Decisions (ADR)

| Number | Title | Status | Date | Context |
|--------|-------|--------|------|---------|
| ADR-003 | Database Choice | Accepted | 2025-10-04 | Project Alpha |
| ADR-002 | API Framework | Accepted | 2025-10-01 | Core Platform |
| ADR-001 | Deployment Strategy | Superseded | 2025-09-28 | Infrastructure |

## Product Decisions (PDR)

| Number | Title | Status | Date | Impact |
|--------|-------|--------|------|--------|
| PDR-002 | Obsidian Integration | Accepted | 2025-10-03 | Users |
| PDR-001 | Personality Builder | Accepted | 2025-09-30 | Users |
```

## Dependencies

- #031 (Memory categories structure)
- #007 (Memory templates)

## Related Issues

- Part of #024 (Decision documentation epic)
- #038 (Decision capture uses these templates)

## Definition of Done

- [ ] ADR template created and documented
- [ ] PDR template created and documented
- [ ] Templates include all necessary sections
- [ ] Decision numbering system implemented
- [ ] Status workflow defined and documented
- [ ] Directory structure created
- [ ] Index file format defined
- [ ] Documentation explains ADR vs PDR usage
- [ ] Example decisions provided
- [ ] Templates accessible via CLI
