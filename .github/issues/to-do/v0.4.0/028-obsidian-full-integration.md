---
title: "Implement full Obsidian integration"
labels:
  - "type: feature"
  - "priority: p1"
  - "effort: large"
  - "milestone: 0.4.0"
  - "epic: needs-breakdown"
---

# Implement full Obsidian integration

> **⚠️ Epic Breakdown Required**: This is a Large effort issue that should be broken down into smaller, more atomic issues before milestone work begins. This breakdown should happen during sprint planning for v0.4.0.

## Description

Implement comprehensive Obsidian integration that goes beyond basic templates to include bidirectional sync, automatic note creation/updates, task synchronization, and knowledge management within Obsidian vault.

## Suggested Breakdown

When breaking down this epic, consider creating separate issues for:

1. **Bidirectional Task Sync** - Sync tasks between AIDA and Obsidian tasks plugin
2. **Automatic Daily Notes** - Create and update daily notes in Obsidian vault
3. **Knowledge Sync** - Export knowledge entries to Obsidian with backlinks
4. **Decision Records Sync** - Export ADRs/PDRs to Obsidian with proper formatting
5. **Project Notes Integration** - Create and maintain project notes in Obsidian
6. **Vault Configuration** - Configurable vault location, structure, and templates
7. **Conflict Resolution** - Handle concurrent edits and sync conflicts
8. **Obsidian CLI Commands** - Commands for manual sync and operations

Each sub-issue should be scoped to Small or Medium effort.

## Acceptance Criteria

- [ ] Bidirectional task sync between AIDA and Obsidian
- [ ] Automatic daily note creation and updates
- [ ] Knowledge entries sync to Obsidian vault
- [ ] Decision records (ADRs) sync to Obsidian
- [ ] Project notes creation and tracking in Obsidian
- [ ] Configurable vault location and structure
- [ ] Template customization support
- [ ] Dataview query compatibility
- [ ] Conflict resolution for concurrent edits
- [ ] CLI commands for Obsidian operations
- [ ] Real-time or scheduled sync modes

## Implementation Notes

### Obsidian Configuration

```yaml
# ~/.claude/config/obsidian.yaml
---
enabled: true
vault_path: "~/Knowledge/Obsidian-Vault"

sync:
  mode: "realtime"  # or "scheduled", "manual"
  interval: 300     # seconds (for scheduled mode)
  conflict_resolution: "prompt"  # or "aida-wins", "obsidian-wins", "merge"

structure:
  daily_notes: "Daily"
  projects: "Projects"
  learnings: "Learnings"
  decisions: "Decisions/ADR"
  templates: "Templates/AIDA"
  tasks: "Tasks"

templates:
  daily_note: "Templates/AIDA/Daily-Note.md"
  project: "Templates/AIDA/Project.md"
  learning: "Templates/AIDA/Learning.md"
  decision: "Templates/AIDA/ADR.md"

features:
  auto_create_daily_note: true
  sync_tasks: true
  sync_knowledge: true
  sync_decisions: true
  create_backlinks: true
  update_dataview_metadata: true
```text

### Bidirectional Task Sync

**AIDA → Obsidian**:

```markdown
# Daily Note (2025-10-04)

## Tasks

### High Priority
- [ ] Fix production payment bug #urgent #work ⏰2025-10-04 📌aida-001
- [ ] Review PR #123 #code-review #work ⏰2025-10-05 📌aida-002

### Medium Priority
- [ ] Update documentation #documentation ⏰2025-10-07 📌aida-003

### Completed
- [x] Implement authentication ✅2025-10-04 📌aida-004
```

**Obsidian → AIDA**:

- Parse Obsidian tasks from daily notes
- Extract priority from heading context
- Extract due dates from ⏰ notation
- Track task ID with 📌 notation
- Sync completion status

**Sync Logic**:

```python
def sync_tasks_bidirectional():
    # Get AIDA tasks
    aida_tasks = get_aida_tasks()

    # Get Obsidian tasks
    obsidian_tasks = parse_obsidian_tasks(vault_path)

    # Find changes
    for task_id in all_task_ids:
        aida_task = aida_tasks.get(task_id)
        obs_task = obsidian_tasks.get(task_id)

        if aida_task and not obs_task:
            # New in AIDA, add to Obsidian
            add_task_to_obsidian(aida_task)

        elif obs_task and not aida_task:
            # New in Obsidian, add to AIDA
            add_task_to_aida(obs_task)

        elif aida_task and obs_task:
            # Exists in both, check for changes
            if aida_task.updated > obs_task.updated:
                update_obsidian_task(aida_task)
            elif obs_task.updated > aida_task.updated:
                update_aida_task(obs_task)
            elif conflict_detected():
                resolve_conflict(aida_task, obs_task)
```text

### Automatic Daily Note Creation

**Morning Routine Integration**:

```bash
$ aida morning

Good morning! Let's plan your day.

Creating today's daily note...
✓ Created: ~/Knowledge/Obsidian-Vault/Daily/2025-10-04.md

Populating with:
  ✓ Active projects status
  ✓ High priority tasks
  ✓ Today's meetings
  ✓ Yesterday's accomplishments

Opening in Obsidian...
```

**Daily Note Structure**:

```markdown
---
date: 2025-10-04
day: Friday
week: 2025-W40
tags: [daily-note]
created_by: aida
---

# 2025-10-04 - Friday

## 🎯 Today's Priorities

1. Fix production payment bug (High)
2. Prepare presentation for stakeholder review (High)
3. Review PR #123 (Medium)

## 📊 Active Projects

<!-- Auto-populated by AIDA -->

- [[Project Alpha]] - 85% complete
  - Status: Final testing phase
  - Next: Deploy to staging
  - Blocker: None

- [[Project Beta]] - 40% complete
  - Status: Frontend development
  - Next: Implement authentication UI
  - Blocker: Waiting on design mockups

## ✅ Accomplished

- [x] Implemented user authentication
- [x] Wrote unit tests for API endpoints
- [x] Reviewed security scan results

## 📝 Notes & Observations

- Authentication implementation went smoothly
- Test coverage now at 87%

## 🚧 Blockers

- Project Beta blocked on design mockups (expected Monday)

## 💡 Ideas

- Consider moving to React Query for API state management
- Explore Playwright for E2E testing

## 📅 Meetings

- 10:00-11:00 - Team standup
- 14:00-15:00 - Stakeholder review (Project Alpha)

## 🔗 Links

- Previous: [[2025-10-03]]
- Next: [[2025-10-05]]
- Week: [[2025-W40]]

---

**Last updated by AIDA**: 2025-10-04 17:30
```text

### Knowledge Sync

**AIDA Learning → Obsidian Note**:

When user captures knowledge:

```
User: "Remember that React useEffect needs cleanup functions"
AIDA: ✓ Captured knowledge

      Syncing to Obsidian...
      ✓ Created: ~/Knowledge/Obsidian-Vault/Learnings/React-useEffect-Cleanup.md
```json

**Obsidian Note**:

```markdown
---
title: "React useEffect Cleanup Functions"
category: React, Best Practices
tags: [react, useEffect, memory-management, hooks]
source: Work on Project Alpha
date_learned: 2025-10-04
created_by: aida
---

# React useEffect Cleanup Functions

## Learning

React useEffect needs cleanup functions for subscriptions to prevent memory leaks.

## Detail

When a useEffect subscribes to events, WebSocket connections, or intervals, it must return a cleanup function that unsubscribes/disconnects when the component unmounts or dependencies change.

## Example

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

## When to Apply

- WebSocket connections
- Event listeners
- setInterval/setTimeout
- Third-party subscriptions

## Related

- [[React Hooks Best Practices]]
- [[Memory Management in React]]

## Used In

- [[Project Alpha]] (chat feature)

---

**Captured by AIDA**: 2025-10-04

```text

### Decision Records Sync

**ADR in Obsidian**:
```markdown
---
title: "Use PostgreSQL for Project Alpha Database"
adr_number: 3
status: Accepted
date: 2025-10-04
project: [[Project Alpha]]
tags: [adr, database, postgresql, architecture]
created_by: aida
---

# ADR-003: Use PostgreSQL for Project Alpha Database

## Context

[same content as before]

## Dataview Compatibility

```dataview
TABLE status, date, project
FROM #adr
WHERE status = "Accepted"
SORT date DESC
```

```text

### CLI Commands

```bash
# Obsidian configuration
aida obsidian setup              # Interactive setup
aida obsidian config             # Show current config
aida obsidian verify             # Verify vault structure

# Manual sync
aida obsidian sync               # Full sync
aida obsidian sync --tasks       # Sync tasks only
aida obsidian sync --knowledge   # Sync knowledge only
aida obsidian sync --decisions   # Sync decisions only

# Note operations
aida obsidian create daily-note  # Create today's note
aida obsidian create project "Project Gamma"
aida obsidian open daily-note    # Open in Obsidian app

# Status and health
aida obsidian status             # Sync status
aida obsidian conflicts          # Show conflicts
```

### Dataview Integration

**Dashboard Query**:

```markdown
# 📊 AIDA Dashboard

## Active Tasks

```dataview
TASK
FROM #daily-note OR "Tasks"
WHERE !completed
WHERE contains(text, "📌aida")
GROUP BY priority
```text

## Recent Learnings

```dataview
TABLE
  category as Category,
  tags as Tags,
  date_learned as "Learned"
FROM "Learnings"
WHERE created_by = "aida"
SORT date_learned DESC
LIMIT 10
```

## Project Progress

```dataview
TABLE
  progress as "Progress",
  status as "Status",
  WITHOUT ID
FROM "Projects"
WHERE contains(file.frontmatter.tags, "project")
SORT progress DESC
```text

## Architecture Decisions

```dataview
TABLE
  status as Status,
  project as Project,
  date as Date
FROM "Decisions/ADR"
WHERE created_by = "aida"
SORT adr_number DESC
```

```text

### Conflict Resolution

```bash
$ aida obsidian sync

Syncing with Obsidian vault...

⚠️  Conflict detected:

Task: "Fix production bug"
AIDA status: completed (2025-10-04 15:30)
Obsidian status: in-progress (2025-10-04 15:45)

Options:
  [A] Use AIDA version (mark completed)
  [O] Use Obsidian version (keep in-progress)
  [M] Merge (prompt for resolution)
  [S] Skip this conflict

Choice: A

✓ Updated Obsidian to match AIDA

Sync complete:
  • Tasks: 12 synced, 1 conflict resolved
  • Knowledge: 3 synced, 0 conflicts
  • Decisions: 1 synced, 0 conflicts
```

## Dependencies

- #016 (Obsidian templates provide foundation)
- #026 (Task management system)
- #023 (Knowledge capture system)
- #024 (Decision documentation system)

## Related Issues

- #027 (Workflow automation creates Obsidian notes)
- #025 (Agents update Obsidian content)

## Definition of Done

- [ ] Bidirectional task sync implemented and tested
- [ ] Automatic daily note creation works
- [ ] Knowledge sync to Obsidian functional
- [ ] Decision records sync to Obsidian
- [ ] Project notes sync properly
- [ ] Conflict resolution handles edge cases
- [ ] CLI commands work reliably
- [ ] Dataview queries are compatible
- [ ] Performance is acceptable (sync < 5 seconds)
- [ ] Documentation explains setup and usage
- [ ] Examples demonstrate common workflows
