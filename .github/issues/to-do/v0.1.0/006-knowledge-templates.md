---
title: "Create knowledge base templates"
labels:
  - "type: feature"
  - "priority: p0"
  - "effort: large"
  - "milestone: 0.1.0"
---

# Create knowledge base templates

## Description

Create the foundational knowledge base templates that provide structure for documenting the user's system, procedures, workflows, projects, and preferences. These templates help users organize information that Claude needs to assist effectively.

## Acceptance Criteria

- [ ] Template `templates/knowledge/system.md.template` created
- [ ] Template `templates/knowledge/procedures.md.template` created
- [ ] Template `templates/knowledge/workflows.md.template` created
- [ ] Template `templates/knowledge/projects.md.template` created
- [ ] Template `templates/knowledge/preferences.md.template` created
- [ ] Each template includes:
  - Frontmatter with metadata
  - Clear section structure
  - Examples and placeholders
  - Instructions for customization
  - Variable substitution (${ASSISTANT_NAME})
- [ ] Templates are user-friendly and easy to fill out
- [ ] Templates include helpful comments and tips
- [ ] Each template is under 1000 tokens

## Implementation Notes

### system.md.template

Documents how the user's computer is organized:

```markdown
---
title: "System Organization"
description: "How ${ASSISTANT_NAME} should understand this system"
category: "knowledge"
last_updated: "${INSTALL_DATE}"
---

# System Organization

## Directory Structure

### Development
- `~/Development/personal/` - Personal projects
- `~/Development/work/` - Work projects (if applicable)
- `~/Development/experiments/` - Learning and experiments
- `~/Development/forks/` - Forked repositories
- `~/Development/sandbox/` - Temporary test projects

### Knowledge Management
- `~/Knowledge/Obsidian-Vault/` - Obsidian vault
  - Daily notes, project notes, references

### File Naming Conventions
- Projects: lowercase-with-hyphens
- Documents: Title_Case_With_Underscores
- Scripts: lowercase_snake_case.sh

## System Preferences
- Operating System: [macOS/Linux/WSL]
- Shell: [bash/zsh/fish]
- Editor: [vim/nano/vscode/etc]
- Package Manager: [brew/apt/yum/etc]

## Ignore Patterns
Files and directories ${ASSISTANT_NAME} should ignore:
- node_modules/
- .git/
- *.pyc
- .DS_Store
- .env (but aware it exists for secrets)
```

### procedures.md.template

Defines how to perform tasks:

```markdown
---
title: "Procedures"
description: "Step-by-step procedures for common tasks"
category: "knowledge"
last_updated: "${INSTALL_DATE}"
---

# Procedures

## Daily Workflow

### Command: ${ASSISTANT_NAME}-start-day
**Aliases**: start-day, start, morning

**Purpose**: Morning routine - review yesterday, plan today

**Procedure**:
1. Read ~/.claude/memory/context.md for current state
2. Review active projects from projects.md
3. Check for blockers or urgent items
4. Suggest daily priorities
5. Create/update today's Obsidian daily note
6. Update memory/context.md with today's plan

**Example Output**:
[Provide example of what user sees]

### Command: ${ASSISTANT_NAME}-end-day
**Aliases**: end-day, end, eod

**Purpose**: End of day wrap-up

**Procedure**:
1. Review what was accomplished today
2. Update project statuses
3. Note any blockers for tomorrow
4. Update daily note with accomplishments
5. Append summary to memory/history/YYYY-MM.md
6. Update memory/context.md

## File Management

### Command: ${ASSISTANT_NAME}-cleanup-downloads
**Purpose**: Organize Downloads folder

**Procedure**:
1. Scan ~/Downloads/ for files
2. Categorize by type (documents, images, archives, etc.)
3. Suggest destinations based on content
4. Move files with confirmation
5. Report summary

[Add more procedures as they are implemented]
```

### workflows.md.template

Describes when to do things:

```markdown
---
title: "Workflows"
description: "When and why to perform tasks"
category: "knowledge"
last_updated: "${INSTALL_DATE}"
---

# Workflows

## Daily Routine

**Morning** (9:00 AM):
- Run ${ASSISTANT_NAME}-start-day
- Review calendar and commitments
- Prioritize tasks

**Midday** (12:00 PM):
- Quick status check
- Adjust priorities if needed

**Evening** (5:00 PM):
- Run ${ASSISTANT_NAME}-end-day
- Log accomplishments
- Plan for tomorrow

## Weekly Maintenance

**Monday Morning**:
- Review weekly goals
- Plan project milestones
- Check for system updates

**Friday Afternoon**:
- Weekly review
- Archive completed projects
- Backup important data

## Monthly Tasks

**First of Month**:
- Review previous month's history
- Set monthly goals
- Archive old downloads

[Customize with user's actual workflows]
```

### projects.md.template

Indexes active projects:

```markdown
---
title: "Active Projects"
description: "Current projects and their status"
category: "knowledge"
last_updated: "${INSTALL_DATE}"
---

# Active Projects

## In Progress

### [Project Name]
- **Status**: Active
- **Progress**: 45%
- **Next Action**: [Specific task]
- **Blockers**: [Any blockers]
- **Path**: ~/Development/personal/project-name/
- **Obsidian Note**: [[Projects/project-name]]

[Add more projects as they are created]

## On Hold

[Projects paused temporarily]

## Recently Completed

[Completed in last 30 days]

## Backlog

[Future projects to consider]
```

### preferences.md.template

Personal preferences and context:

```markdown
---
title: "Preferences"
description: "${ASSISTANT_NAME}'s understanding of user preferences"
category: "knowledge"
last_updated: "${INSTALL_DATE}"
---

# Preferences

## Communication Style
- Formality: [Casual/Professional/Balanced]
- Detail Level: [Concise/Detailed/Verbose]
- Emoji Usage: [None/Minimal/Frequent]
- Address me as: [Name/Sir/Boss/etc]

## Work Preferences
- Typical Work Hours: [e.g., 9am-5pm]
- Focus Time: [When not to interrupt]
- Break Preferences: [Pomodoro/Scheduled/Flexible]

## Tool Preferences
- IDE: [VSCode/Vim/etc]
- Terminal: [iTerm2/Terminal/etc]
- Browser: [Chrome/Firefox/Safari/etc]
- Note-taking: [Obsidian/Notion/etc]

## Project Preferences
- Commit Message Style: [Conventional/Descriptive/etc]
- Code Style: [Specific linting rules]
- Testing Approach: [TDD/Manual/Automated/etc]

## Personal Context
- Background: [Relevant experience/expertise]
- Learning Goals: [What you're trying to learn]
- Common Tasks: [Frequent activities]

[Customize with actual preferences]
```

## Dependencies

- #002 (Template system)

## Related Issues

- #005 (CLAUDE.md template references these)
- #007 (Memory templates)
- #011 (Core procedures implementation)

## Definition of Done

- [ ] All five templates are created and well-structured
- [ ] Templates include helpful examples and placeholders
- [ ] Templates use variable substitution correctly
- [ ] Each template is within token budget (< 1000 tokens)
- [ ] Templates are tested with installation script
- [ ] User can easily understand how to fill out each template
- [ ] Documentation explains purpose of each knowledge file
