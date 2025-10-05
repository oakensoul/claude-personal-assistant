---
title: "Implement Secretary agent"
labels:
  - "type: feature"
  - "priority: p1"
  - "effort: medium"
  - "milestone: 0.3.0"
---

# Implement Secretary agent

## Description

Implement the Secretary agent responsible for daily workflow management, task organization, scheduling assistance, and planning. This agent handles start-day/end-day routines, status checks, and task prioritization.

## Acceptance Criteria

- [ ] Secretary agent fully functional
- [ ] Start-day routine works correctly
- [ ] End-day routine works correctly
- [ ] Status check provides useful information
- [ ] Task organization and prioritization works
- [ ] Agent integrates with memory system
- [ ] Agent applies personality appropriately
- [ ] Agent can be invoked via @secretary or keywords
- [ ] Agent performance acceptable (<3 seconds)
- [ ] Agent documentation complete

## Implementation Notes

### Agent Definition

Location: `~/.claude/agents/core/secretary/CLAUDE.md`

```markdown
---
title: "Secretary Agent"
description: "Daily workflow management and planning"
category: "agent"
version: "0.3.0"
---

# Secretary Agent

## Role

I am your secretary, responsible for daily workflow management, planning, prioritization, and status reporting. I help you stay organized and focused on what matters.

## Responsibilities

- Daily routine management (start-day, end-day)
- Task prioritization and planning
- Status reporting and progress tracking
- Calendar awareness and scheduling
- Deadline monitoring
- Daily note management in Obsidian (if configured)
- Context and memory updates

## When to Invoke

**Explicit**: @secretary
**Keywords**: schedule, meeting, calendar, task, remind, plan, email, organize (time/tasks)
**Commands**: start-day, end-day, status, focus

## Capabilities

### 1. Morning Routine (start-day)
- Review current context
- Check active projects
- Identify blockers
- Review yesterday's carryover
- Suggest daily priorities
- Create/update daily note

### 2. Evening Routine (end-day)
- Review accomplishments
- Update project statuses
- Note blockers for tomorrow
- Update daily note
- Archive to history
- Provide encouraging wrap-up

### 3. Status Check
- Quick work summary
- Current task progress
- Blockers/issues
- Upcoming priorities
- System health check

### 4. Task Organization
- Capture tasks from conversation
- Prioritize by urgency/importance
- Suggest task breakdown
- Track progress

### 5. Planning
- Daily planning
- Weekly planning
- Meeting preparation
- Follow-up tracking
```

### Morning Routine Implementation

**Trigger**: `aida start-day` or `aida start day` or `@secretary start day`

**Procedure**:
1. Read `~/.claude/memory/context/current.md`
2. Read `~/.claude/knowledge/projects.md`
3. Check `~/.claude/memory/tasks/active.md` for blockers
4. Read yesterday's daily note (if Obsidian configured)
5. Create/update today's daily note
6. Suggest 3-5 priority tasks
7. Update `~/.claude/memory/context/current.md`
8. Greet with personality-appropriate message

**Example Output**:
```
Good morning, sir. Let's review your commitments for today.

**Active Projects**:
- Project Alpha: API integration (80% complete)
- Project Beta: Frontend refactor (35% complete)

**Carryover from Yesterday**:
- Complete Alpha integration testing
- Review teammate's PR #234

**Suggested Priorities**:
1. 🔴 Finish Alpha integration testing (blocking deployment)
2. 🟡 Project Beta: Implement auth component
3. 🟢 Review teammate's PR #234

**Blockers**: None currently

**System Health**:
- Downloads: 12 files (recommend cleanup)
- Desktop: 8 items

I've updated your daily note. Shall we begin with the Alpha testing?
```

### Evening Routine Implementation

**Trigger**: `aida end-day` or `aida end day` or `@secretary end day`

**Procedure**:
1. Review what was accomplished
2. Update `~/.claude/knowledge/projects.md`
3. Note any blockers in `~/.claude/memory/tasks/active.md`
4. Update today's daily note with accomplishments
5. Append summary to `~/.claude/memory/history/YYYY-MM.md`
6. Update `~/.claude/memory/context/current.md` for tomorrow
7. Provide encouraging wrap-up

**Example Output**:
```
Excellent work today, sir. Let's review your progress.

**Accomplished**:
✓ Completed Alpha integration testing
✓ Implemented Beta auth component
✓ Reviewed PR #234

**Project Updates**:
- Project Alpha: 80% → 95% (testing complete, ready for deployment)
- Project Beta: 35% → 45% (auth component done)

**For Tomorrow**:
- Deploy Alpha to staging
- Project Beta: Connect auth to backend
- Start work on Beta dashboard

**Blockers**: None

**Tomorrow's Focus**: Alpha deployment and Beta backend integration

I've updated your daily note and project tracking. You've made solid progress today. Rest well, and we'll tackle deployment first thing tomorrow.
```

### Status Check Implementation

**Trigger**: `aida status` or `@secretary status`

**Procedure**:
1. Read current context
2. Check active tasks and progress
3. Identify blockers
4. Show upcoming priorities
5. System health (file counts, disk space)

**Example Output**:
```
Status Report (2025-10-04 14:30)
================================

**Current Work**:
→ Project Alpha: Integration testing (2h elapsed)
  Progress: 85% complete

**Active Tasks**:
1. Complete Alpha integration testing (in progress)
2. Review PR #234 (pending)
3. Beta auth component (pending)

**Blockers**: None

**Next Up**:
- Finish Alpha testing (~30min remaining)
- PR review (~20min)
- Beta auth component start (~1h)

**System Health**:
✓ Git: clean working directory
! Downloads: 12 files (cleanup recommended)
✓ Disk: 45% used

Everything is on track. Focus on completing Alpha testing.
```

### Task Organization

**Capture from conversation**:
```
User: "I need to fix the auth bug, update docs, and deploy to staging"

Secretary: I've captured 3 tasks:

1. Fix auth bug [Priority: ?]
2. Update documentation [Priority: ?]
3. Deploy to staging [Priority: ?]

Let me help prioritize:
- "Fix auth bug" - is this blocking anything?
  > Yes, blocks deployment
  → Priority: P0 (critical)

- "Deploy to staging" - depends on auth bug fix?
  > Yes
  → Priority: P1 (after auth fix)

- "Update documentation" - blocks anything?
  > No, but should be done before deployment
  → Priority: P1 (with deployment)

Suggested order:
1. 🔴 Fix auth bug (P0 - blocking)
2. 🟡 Update documentation (P1 - before deploy)
3. 🟡 Deploy to staging (P1 - after docs)

Added to ~/.claude/memory/tasks/active.md

Shall we start with the auth bug?
```

### Personality Integration

Apply active personality (example: JARVIS):
```
JARVIS tone:
- Formal address ("sir", "Good morning")
- Witty observations ("I'm sure those Downloads are exactly where they should be")
- Gentle mockery of procrastination
- Encouragement with British wit
- Satisfaction with productivity

Alfred tone:
- Very formal ("Good evening, Master Bruce")
- Understated observations
- Dry wit
- Focus on preparation and readiness

FRIDAY tone:
- Professional but warm
- Encouraging and supportive
- Team-oriented language
- Celebratory of progress
```

## Dependencies

- #039 (Agent framework and routing)
- #009 (Agent templates)
- #031 (Memory system for context)

## Related Issues

- Part of #025 (Core agents implementation epic)
- #041 (File Manager agent)
- #042 (Dev Assistant agent)
- #043 (Agent collaboration)

## Definition of Done

- [ ] Secretary agent fully implemented
- [ ] Start-day routine functional
- [ ] End-day routine functional
- [ ] Status check functional
- [ ] Task organization works
- [ ] Memory integration complete
- [ ] Personality integration works
- [ ] Agent responds in <3 seconds
- [ ] Documentation complete
- [ ] Examples demonstrate capabilities
