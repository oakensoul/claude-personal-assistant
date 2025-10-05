---
title: "Implement decision capture and querying"
labels:
  - "type: feature"
  - "priority: p2"
  - "effort: medium"
  - "milestone: 0.3.0"
---

# Implement decision capture and querying

## Description

Implement natural language decision capture with guided ADR/PDR creation, decision querying, and decision history tracking with Obsidian integration support.

## Acceptance Criteria

- [ ] Natural language decision capture works
- [ ] Interactive guided ADR/PDR creation
- [ ] Decision type detection (technical vs product)
- [ ] Decision querying via natural language
- [ ] Decision querying via CLI commands
- [ ] Decision history and evolution tracking
- [ ] Decision reversal tracking (superseded decisions)
- [ ] Obsidian export functionality works (if configured)
- [ ] Decision index automatically updated
- [ ] Decision status updates supported

## Implementation Notes

### Decision Capture Flow

**User Input**:

```text
"Document decision: We chose PostgreSQL over MongoDB for Project Alpha because we need ACID compliance and complex relational queries"
```

**AIDA Response**:

```text
Creating Architecture Decision Record...

ADR-003: Use PostgreSQL for Project Alpha Database

I've captured the core decision. Let me help you complete the ADR.

**Context Questions**:
  1. What problem are you solving?
  2. What alternatives did you consider?
  3. What are the consequences (pros/cons)?

Shall I guide you through these, or would you prefer to write the full ADR yourself?

[G] Guided (I'll ask questions)
[M] Manual (I'll open the template for you)
[Q] Quick (save as-is for now, enhance later)
```

### Guided Creation

**Guided Flow for ADR**:

```text
Creating ADR-003: Database Choice for Project Alpha

1. What problem are you solving?
   > "Need database for user data, transactions, and analytics with ACID compliance"

2. What alternatives did you consider? (Enter each alternative, empty line when done)
   > "MongoDB - flexible schema, easier scaling"
   > "MySQL - simpler operations"
   > "DynamoDB - serverless scaling"
   >

3. For each alternative, why was it not chosen?

   MongoDB:
   > "Weaker consistency guarantees, ACID compliance critical for financial data"

   MySQL:
   > "Less sophisticated JSON support, weaker analytical capabilities"

   DynamoDB:
   > "Vendor lock-in, prefer open-source and portable solution"

4. What are the positive consequences?
   > "Strong data integrity, powerful analytics, well-understood operations"

5. What are the negative consequences?
   > "Horizontal scaling more complex, requires careful index management"

6. Any follow-up actions needed?
   > "Set up PostgreSQL instance"
   > "Design schema with indexing"
   > "Configure backups"
   >

✓ ADR-003 created successfully!
Saved to: ~/.claude/memory/decisions/adr/003-database-choice.md

[V] View  [E] Edit  [S] Share to Obsidian  [D] Done
```

### Decision Type Detection

Determine ADR vs PDR based on keywords:

**Technical/Architecture (ADR)**:

- Keywords: database, framework, architecture, deployment, infrastructure, technology
- Context: technical trade-offs, implementation details
- Focus: engineering decisions

**Product (PDR)**:

- Keywords: feature, user, customer, business, roadmap, pricing, UX
- Context: user value, business impact
- Focus: product direction

**Auto-suggestion**:

```text
Detected as: Architecture Decision (technical trade-offs mentioned)
Create as ADR? (Y/n)
```

### Decision Querying

**Natural Language**:

```text
"Why did we choose PostgreSQL?"
"Show me database decisions"
"What decisions have we made about Project Alpha?"
"List all accepted decisions"
"Show superseded decisions"
```

**CLI Commands**:

```bash
# List all decisions
aida decisions list

# Search decisions
aida decisions search "database"

# Show specific decision
aida decisions show 003
aida decisions show ADR-003

# Filter by status
aida decisions list --status accepted
aida decisions list --status superseded

# Filter by project
aida decisions by-project alpha

# Filter by type
aida decisions list --type adr
aida decisions list --type pdr

# Show recent
aida decisions recent --limit 5
```text

### Decision History and Evolution

Track when decisions change:

```bash
$ aida decisions history 003

ADR-003: Database Choice for Project Alpha
History:

2025-10-15: Status changed to Superseded
  - Superseded by: ADR-008 (Move to NewSQL)
  - Reason: Scaling requirements changed

2025-10-04: Status changed to Accepted
  - Decision approved by team
  - Implementation started

2025-10-03: Created as Proposed
  - Initial draft for team review
```

### Decision Reversal Tracking

When a decision is superseded:

```bash
$ aida decisions supersede 003

Superseding ADR-003: Database Choice

This will mark ADR-003 as Superseded.

What is the new decision replacing this?
  [N] Create new decision now
  [R] Reference existing decision (enter number)
  [L] Note reason without replacement

> N

Creating ADR-008 to replace ADR-003...

Title for new decision:
> "Migrate to NewSQL for improved scaling"

[... guided creation continues ...]

✓ ADR-003 marked as Superseded
✓ ADR-008 created
✓ Cross-references updated
```text

### Obsidian Integration

Export decisions to Obsidian vault:

```bash
$ aida decisions export --obsidian

Exporting decisions to Obsidian...

Created decision notes:
  ~/Knowledge/Obsidian-Vault/Decisions/ADR-003-Database-Choice.md
  ~/Knowledge/Obsidian-Vault/Decisions/ADR-002-API-Framework.md
  ~/Knowledge/Obsidian-Vault/Decisions/PDR-001-Personality-Builder.md

✓ Exported 3 decisions
✓ Created backlinks between related decisions
✓ Updated decision index
```

**Obsidian Format**:

```markdown
---
tags: [decision, adr, database, postgresql]
status: Superseded
date: 2025-10-04
context: Project Alpha
superseded-by: [[ADR-008-NewSQL-Migration]]
---

# ADR-003: Database Choice for Project Alpha

> **Status**: Superseded (replaced by [[ADR-008-NewSQL-Migration]])

## Context

[... full ADR content ...]

## Related Decisions

- [[ADR-008-NewSQL-Migration]] (supersedes this)
- [[PDR-001-Personality-Builder]] (uses this database)
```text

### Decision Index Auto-Update

When decisions are created/updated, automatically update index:

```markdown
# Decision Index

Last updated: 2025-10-04 15:30

## Architecture Decisions (ADR)

| Number | Title | Status | Date | Context |
|--------|-------|--------|------|---------|
| ADR-003 | Database Choice | Superseded | 2025-10-04 | Project Alpha |
| ADR-002 | API Framework | Accepted | 2025-10-01 | Core Platform |
| ADR-001 | Deployment Strategy | Accepted | 2025-09-28 | Infrastructure |

## Product Decisions (PDR)

| Number | Title | Status | Date | Impact |
|--------|-------|--------|------|--------|
| PDR-002 | Obsidian Integration | Accepted | 2025-10-03 | Users |
| PDR-001 | Personality Builder | Accepted | 2025-09-30 | Users |

---

## Statistics

- Total Decisions: 5
- Active (Accepted): 4
- Superseded: 1
- Rejected: 0

## Recent Activity

- 2025-10-04: ADR-003 created (Database Choice)
- 2025-10-03: PDR-002 created (Obsidian Integration)
- 2025-10-01: ADR-002 created (API Framework)
```

## Dependencies

- #037 (ADR templates and numbering system)
- #031 (Memory categories structure)

## Related Issues

- Part of #024 (Decision documentation epic)
- #023 (Knowledge capture similar workflow)
- #016 (Obsidian templates)

## Definition of Done

- [ ] Natural language decision capture works
- [ ] Guided ADR/PDR creation functional
- [ ] Decision type detection accurate
- [ ] All query methods work correctly
- [ ] Decision history tracking implemented
- [ ] Decision reversal/superseding works
- [ ] Obsidian export functional
- [ ] Decision index auto-updates
- [ ] Status updates supported
- [ ] Documentation complete
- [ ] Examples demonstrate workflows
