---
title: "Document core procedures in procedures.md template"
labels:
  - "type: feature"
  - "priority: p0"
  - "effort: medium"
  - "milestone: 0.1.0"
---

# Document core procedures in procedures.md template

## Description

Complete the `procedures.md.template` with detailed documentation for the core MVP procedures: start-day, end-day, status, and cleanup-downloads. These procedures tell Claude how to execute common commands.

## Acceptance Criteria

- [ ] Procedure `${ASSISTANT_NAME}-start-day` fully documented
- [ ] Procedure `${ASSISTANT_NAME}-end-day` fully documented
- [ ] Procedure `${ASSISTANT_NAME}-status` fully documented
- [ ] Procedure `${ASSISTANT_NAME}-cleanup-downloads` fully documented
- [ ] Each procedure includes:
  - Command trigger patterns
  - Command aliases
  - Purpose/description
  - Step-by-step procedure
  - Example output
  - Files to read/update
  - Personality integration notes
- [ ] Procedures integrate with agent system
- [ ] Procedures reference knowledge and memory files correctly
- [ ] Procedures are clear enough for Claude to execute independently

## Implementation Notes

Each procedure should follow this format:

```markdown
## Command: ${ASSISTANT_NAME}-start-day

**Aliases**: start-day, start, morning, begin day

**Trigger Patterns**:
- "${ASSISTANT_NAME}-start-day"
- "${ASSISTANT_NAME} start day"
- "${ASSISTANT_NAME} start"
- "start my day with ${ASSISTANT_NAME}"

**Purpose**: Morning routine - review yesterday's work, plan today's priorities, and set up the day for success.

**Agent**: Secretary (daily workflow management)

**Procedure**:

1. **Read Current State**
   - Read `~/.claude/memory/context.md` for current active work
   - Note any pending items or blockers

2. **Review Yesterday**
   - Check yesterday's daily note (if exists): `~/Knowledge/Obsidian-Vault/Daily/YYYY-MM-DD.md`
   - Identify carryover tasks

3. **Review Active Projects**
   - Read `~/.claude/knowledge/projects.md`
   - List active projects with current status
   - Identify any blockers or urgent items

4. **Generate Today's Plan**
   - Suggest 3-5 priority tasks based on:
     - Project progress and deadlines
     - Pending items from context
     - Carryover from yesterday
     - Known blockers
   - Prioritize high-impact work

5. **Create/Update Daily Note**
   - Create or update: `~/Knowledge/Obsidian-Vault/Daily/YYYY-MM-DD.md`
   - Include:
     - Date and day of week
     - Active projects
     - Today's priorities
     - Blockers or notes

6. **Update Memory**
   - Update `~/.claude/memory/context.md`:
     - Set today's priorities
     - Update project statuses if needed
     - Update "Last updated" timestamp

7. **Greet User**
   - Use personality-appropriate greeting
   - Present the plan
   - Ask if adjustments needed

**Files to Read**:
- `~/.claude/memory/context.md` (current state)
- `~/.claude/knowledge/projects.md` (active projects)
- `~/.claude/knowledge/workflows.md` (daily routine patterns)
- `~/Knowledge/Obsidian-Vault/Daily/[yesterday].md` (carryover)

**Files to Update**:
- `~/Knowledge/Obsidian-Vault/Daily/[today].md` (create/update)
- `~/.claude/memory/context.md` (update with today's plan)

**Example Output** (JARVIS personality):

```
Good morning, sir. Let's review your commitments for today.

**Active Projects**:
1. Project Alpha: API integration (80% complete)
   - Status: Ready for final testing
   - Blocker: None

2. Project Beta: Frontend refactor (35% complete)
   - Status: In progress - auth component
   - Blocker: Waiting on design mockups

**Carryover from Yesterday**:
- Complete Alpha integration testing
- Review teammate's PR #247

**Suggested Priorities for Today**:
1. ⚡ Finish Alpha integration testing (blocking deployment)
2. 🎨 Project Beta: Implement auth component (design available now)
3. 📝 Review teammate's PR #247 (low priority)

**Current Blockers**: None

**System Status**:
- Downloads: 34 files (last cleanup: 3 days ago)
- Disk space: 456GB free

I've created today's daily note and updated your context.

Shall we begin with the Alpha testing, or would you like to adjust priorities?
```

**Personality Integration**:
- Use personality's greeting templates
- Apply tone to task descriptions
- Use encouragement style from personality
- Address user according to preferences
```

**Key Points:**
- Procedures should be detailed enough for Claude to execute without ambiguity
- Include specific file paths
- Show example outputs for each personality type
- Reference agent system where appropriate
- Integrate with memory/knowledge system
- Provide clear success criteria

## Dependencies

- #006 (Knowledge templates must exist)
- #007 (Memory templates must exist)
- #009 (Agent templates for context)

## Related Issues

- #005 (CLAUDE.md template references procedures)
- #008 (JARVIS personality affects output)

## Definition of Done

- [ ] All four core procedures are fully documented
- [ ] Each procedure is detailed and unambiguous
- [ ] Example outputs are realistic and personality-appropriate
- [ ] File paths are correct and consistent
- [ ] Integration with agents is clear
- [ ] Procedures reference knowledge/memory correctly
- [ ] Documentation is tested with Claude execution
- [ ] Procedures template is under 3000 tokens
