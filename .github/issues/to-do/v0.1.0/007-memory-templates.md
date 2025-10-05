---
title: "Create memory system templates"
labels:
  - "type: feature"
  - "priority: p0"
  - "effort: medium"
  - "milestone: 0.1.0"
---

# Create memory system templates

## Description

Create the memory system templates that provide structure for tracking current state, decision history, and activity logs. The memory system is dynamic and updated frequently by Claude during interactions.

## Acceptance Criteria

- [ ] Template `templates/memory/context.md.template` created
- [ ] Template `templates/memory/decisions.md.template` created
- [ ] Template structure for `memory/history/YYYY-MM.md` defined
- [ ] Each template includes:
  - Frontmatter with metadata
  - Clear section structure
  - Instructions for Claude on when/how to update
  - Initial placeholder content
- [ ] Context template includes sections for:
  - Active work
  - Recent decisions
  - Pending items
  - System state
  - Last updated timestamp
- [ ] Decisions template includes format for logging decisions with rationale
- [ ] History template includes daily activity log format
- [ ] Templates are under 1500 tokens combined

## Implementation Notes

### context.md.template

Current state that Claude updates frequently:

```markdown
---
title: "Current Context"
description: "Current state and active work for ${ASSISTANT_NAME}"
category: "memory"
last_updated: "${INSTALL_DATE}"
---

# Current Context

> **Note**: This file is updated frequently by ${ASSISTANT_NAME} to track current state.
> Last updated: ${INSTALL_DATE}

## Active Work

**Current Focus**: [What you're working on right now]

### [Project Name]
- **Status**: In Progress
- **Progress**: 0%
- **Current Task**: [Specific task]
- **Blockers**: None

[Add more projects as work begins]

## Recent Decisions

[Last 3-5 significant decisions - full history in decisions.md]

## Pending Items

**High Priority**:
- [Urgent item]

**Medium Priority**:
- [Important item]

**Low Priority**:
- [Nice to have]

**Blocked**:
- [Item blocked on something]

## System State

**Last Cleanup**:
- Downloads: [Never/Date]
- Desktop: [Never/Date]
- Screenshots: [Never/Date]

**Disk Space**: [Unknown/Amount free]

**Last Backup**: [Never/Date]

## Notes

[Any temporary notes or reminders]

---

**Instructions for ${ASSISTANT_NAME}**:
- Update this file when significant events occur
- Keep "Active Work" current with project status
- Move completed items to history/YYYY-MM.md
- Update "Last updated" timestamp
- Keep this file concise (< 1500 tokens)
```

### decisions.md.template

Decision log with rationale:

```markdown
---
title: "Decision Log"
description: "Record of significant decisions made"
category: "memory"
last_updated: "${INSTALL_DATE}"
---

# Decision Log

> **Purpose**: Track important decisions with context and rationale.
> This helps maintain consistency and learn from past choices.

## Format

Each decision should include:
- **Date**: When the decision was made
- **Context**: What prompted the decision
- **Decision**: What was decided
- **Rationale**: Why this choice was made
- **Alternatives**: Other options considered
- **Outcome**: Results (added later)

---

## Example Decision

### 2025-10-04: Initialize AIDA Framework

**Context**: Need a better way to organize digital life and work with Claude AI.

**Decision**: Install AIDA framework with ${PERSONALITY_NAME} personality.

**Rationale**:
- AIDA provides structured knowledge and memory system
- ${PERSONALITY_NAME} personality matches preferred communication style
- Framework is modular and customizable

**Alternatives Considered**:
- Manual dotfiles and scripts (less structured)
- Other AI assistant frameworks (less focused on Claude)
- No system (too chaotic)

**Outcome**: [To be updated after using AIDA for a while]

---

[Future decisions will be appended below by ${ASSISTANT_NAME}]

---

**Instructions for ${ASSISTANT_NAME}**:
- Log significant decisions (technical choices, workflow changes, etc.)
- Include enough context to understand decision later
- Note alternatives to show decision was thoughtful
- Update outcomes when known
- Keep most recent decisions at top
```

### history/YYYY-MM.md format

Monthly activity log:

```markdown
---
title: "[Month] [Year] Activity Log"
description: "Daily activity log for [Month] [Year]"
category: "memory"
month: "[YYYY-MM]"
---

# [Month] [Year]

## Week 1

### [YYYY-MM-DD] [Day of Week]

**Accomplished**:
- [Major accomplishment]
- [Task completed]

**Progress**:
- [Project Name]: [Brief update]

**Decisions**:
- [Any decisions made - link to decisions.md]

**Notes**:
- [Any notable events or observations]

---

[New days are prepended to top by ${ASSISTANT_NAME}]

---

**Instructions for ${ASSISTANT_NAME}**:
- Add new day entries when ${ASSISTANT_NAME}-end-day is run
- Keep entries concise but informative
- Link to project notes in Obsidian when relevant
- Summarize completed tasks, don't list every small action
- Note patterns and insights
```

## Dependencies

- #002 (Template system)

## Related Issues

- #005 (CLAUDE.md references memory system)
- #006 (Knowledge templates)
- #011 (Procedures need to update memory)

## Definition of Done

- [ ] All memory templates are created
- [ ] Templates include clear instructions for Claude
- [ ] Templates use variable substitution correctly
- [ ] Templates are tested with installation script
- [ ] Generated files have proper structure and placeholders
- [ ] Documentation explains when Claude should update each file
- [ ] Templates are within token budget
