---
title: "Implement extended command system"
labels:
  - "type: feature"
  - "priority: p2"
  - "effort: large"
  - "milestone: 0.2.0"
---

# Implement extended command system

## Description

Extend the command system beyond the MVP basics to include file management, project management, and memory commands. These commands provide more sophisticated interactions with the system.

## Acceptance Criteria

### File Management Commands

- [ ] `${ASSISTANT_NAME}-clear-desktop` documented in procedures.md
- [ ] `${ASSISTANT_NAME}-organize-screenshots` documented
- [ ] `${ASSISTANT_NAME}-file-this [path]` documented

### Project Management Commands

- [ ] `${ASSISTANT_NAME}-project-status [name]` documented
- [ ] `${ASSISTANT_NAME}-project-update [name]` documented
- [ ] `${ASSISTANT_NAME}-projects-list` documented
- [ ] `${ASSISTANT_NAME}-blockers` documented

### Memory Commands

- [ ] `${ASSISTANT_NAME}-remember [thing]` documented
- [ ] `${ASSISTANT_NAME}-recall [topic]` documented
- [ ] `${ASSISTANT_NAME}-context` documented

### System Commands

- [ ] `${ASSISTANT_NAME}-system-health` documented
- [ ] All commands integrate with appropriate agents
- [ ] All commands have example outputs
- [ ] All commands update memory/knowledge appropriately

## Implementation Notes

### File Management Commands

#### clear-desktop

```markdown
## Command: ${ASSISTANT_NAME}-clear-desktop

**Purpose**: Minimize Desktop folder to keep workspace clean

**Agent**: File Manager

**Procedure**:
1. List all items on Desktop
2. Categorize by type and age
3. For each item, suggest destination:
   - Screenshots → ~/Media/Screenshots/
   - Documents → ~/Documents/
   - Downloads → ~/Downloads/ (for later cleanup)
   - Temporary → ~/Temp/ or trash
   - Keep only: Active project shortcuts, essential apps
4. Move files with confirmation
5. Update memory/context.md with cleanup timestamp
6. Report clean desktop status

**Example Output** (JARVIS):
```text

Your Desktop has 23 items. Shocking levels of disorder, sir.

**Categorization**:

- 8 screenshots → ~/Media/Screenshots/
- 5 PDFs → ~/Documents/Personal/
- 3 project folders → Keep (active work)
- 4 random files → ~/Downloads/ for processing
- 3 old installers → Trash

Shall I proceed with this cleanup?

```
```bash

#### organize-screenshots

```markdown
## Command: ${ASSISTANT_NAME}-organize-screenshots

**Purpose**: Organize screenshots by date and optionally rename

**Agent**: File Manager

**Procedure**:
1. Scan ~/Desktop/ and ~/Downloads/ for screenshots
2. Group by date taken (from EXIF or filename)
3. Create dated folders: ~/Media/Screenshots/YYYY/MM/
4. Optionally rename with descriptive names (based on content)
5. Move files
6. Report summary

**Example Output**:
```

Found 47 screenshots across Desktop and Downloads.

**Organization Plan**:

- 12 screenshots from October 2025 → Media/Screenshots/2025/10/
- 35 screenshots from September 2025 → Media/Screenshots/2025/09/

**Optional Renaming**:

- Screenshot-2025-10-04-at-3.45.12-PM.png → error-message-postgresql.png
- [Similar for others]

Rename for clarity? (Y/n):

```text
```

#### file-this

```markdown
## Command: ${ASSISTANT_NAME}-file-this [path]

**Purpose**: Intelligently file a specific item

**Agent**: File Manager

**Procedure**:
1. Analyze file:
   - File type and extension
   - Filename for context clues
   - Contents (if text/code)
   - Metadata (date, EXIF, etc.)
2. Determine appropriate destination based on:
   - knowledge/system.md (directory structure)
   - knowledge/preferences.md (naming conventions)
   - File content and purpose
3. Suggest destination and optional rename
4. Move file with confirmation
5. If project-related, update projects.md

**Example**:
```bash

$ jarvis file-this ~/Downloads/api-documentation.pdf

**Analysis**:

- Type: PDF document
- Content: API documentation for Stripe payments
- Related to: Project Alpha (payment integration)

**Suggested Action**:

- Destination: ~/Development/personal/project-alpha/docs/
- Rename to: stripe-api-reference.pdf

Proceed? (Y/n):

```
```bash

### Project Management Commands

#### project-status

```markdown
## Command: ${ASSISTANT_NAME}-project-status [name]

**Purpose**: Get detailed status of a specific project

**Agent**: Dev Assistant + Secretary

**Procedure**:
1. Read project info from knowledge/projects.md
2. If git repository:
   - Check git status
   - Review recent commits
   - Check for uncommitted changes
3. Read project's daily notes (if Obsidian)
4. Identify blockers
5. Suggest next actions
6. Report comprehensive status

**Example Output**:
```

#### Project Alpha Status

**Overview**:

- Progress: 80% complete
- Status: 🟢 Active
- Last Update: 2 hours ago

**Git Status**:

- Branch: feature/payment-integration
- Uncommitted changes: 3 files
- Recent commits:
  - "Add Stripe payment processing" (2 hours ago)
  - "Update API client" (yesterday)

**Next Actions**:

1. Complete integration testing
2. Write unit tests for payment flow
3. Update documentation

**Blockers**: None

**Notes**:
Ready for final testing before merge to main.

Would you like to proceed with testing?

```text
```

#### projects-list

```markdown
## Command: ${ASSISTANT_NAME}-projects-list

**Purpose**: List all projects with status summary

**Agent**: Secretary

**Procedure**:
1. Read knowledge/projects.md
2. For each project:
   - Name and status
   - Progress percentage
   - Last update
   - Any blockers
3. Group by status (active, on-hold, completed)
4. Highlight urgent items
5. Suggest focus areas

**Example Output**:
```text

**Active Projects** (3):

1. 🟢 Project Alpha - API Integration
   Progress: 80% | Last update: 2 hours ago
   Next: Complete testing

2. 🟡 Project Beta - Frontend Refactor
   Progress: 35% | Last update: yesterday
   Blocked: Waiting on design mockups

3. 🟢 Project Gamma - Documentation
   Progress: 60% | Last update: 3 days ago
   Next: Write deployment guide

**On Hold** (1):

4. ⚪ Project Delta - Mobile App
   Progress: 15% | Paused 2 weeks ago
   Reason: Waiting for API completion

**Recently Completed** (1):

5. ✅ Project Epsilon - Database Migration
   Completed: 1 week ago

**Recommendations**:

- Focus: Project Alpha (nearly complete, high priority)
- Unblock: Project Beta (follow up on designs)
- Review: Project Gamma (stale, needs attention)

```
```bash

### Memory Commands

#### remember

```markdown
## Command: ${ASSISTANT_NAME}-remember [thing]

**Purpose**: Add important information to memory

**Agent**: Secretary

**Procedure**:
1. Parse the information
2. Determine category:
   - Decision (goes to decisions.md)
   - Context (goes to context.md)
   - Preference (goes to preferences.md)
3. Format appropriately
4. Append to relevant file
5. Confirm storage

**Example**:
```

$ jarvis remember "We decided to use PostgreSQL instead of MongoDB for Project Alpha because we need ACID compliance and complex relational queries"

**Categorized as**: Decision

**Logged to**: ~/.claude/memory/decisions.md

**Entry**:

### 2025-10-04: Database Choice for Project Alpha

**Decision**: Use PostgreSQL instead of MongoDB

**Rationale**:

- Need ACID compliance
- Complex relational queries required

**Project**: Project Alpha

✓ Remembered. I will reference this in future discussions about Project Alpha.

```text
```

#### recall

```markdown
## Command: ${ASSISTANT_NAME}-recall [topic]

**Purpose**: Search memory for information about a topic

**Agent**: Secretary

**Procedure**:
1. Search across memory files:
   - context.md
   - decisions.md
   - history/*.md
2. Search knowledge files:
   - preferences.md
   - projects.md
3. Return relevant information
4. Show sources

**Example**:
```bash

$ jarvis recall "database choice"

**Found in Memory**:

**Decision** (2025-10-04):
Database choice for Project Alpha: PostgreSQL

- Rationale: ACID compliance, relational queries
- Source: ~/.claude/memory/decisions.md

**History** (2025-10-03):
Researched database options (PostgreSQL vs MongoDB)

- Source: ~/.claude/memory/history/2025-10.md

**Related Projects**:

- Project Alpha uses PostgreSQL

Anything specific about database choices you'd like to know?

```
```text

## Dependencies

- #006 (Knowledge templates)
- #007 (Memory templates)
- #009 (Agent templates)
- #011 (Core procedures as foundation)

## Related Issues

- #016 (Obsidian templates for project notes)

## Definition of Done

- [ ] All commands documented in procedures.md
- [ ] Each command has clear procedure
- [ ] Example outputs for each command
- [ ] Integration with agents defined
- [ ] Memory/knowledge updates specified
- [ ] Commands tested with Claude
- [ ] Documentation updated
