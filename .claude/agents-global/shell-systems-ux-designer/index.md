---
title: "Shell Systems UX Designer - AIDA Project Instructions"
description: "AIDA-specific CLI UX requirements and design standards"
category: "project-agent-instructions"
tags: ["aida", "shell-systems-ux-designer", "project-context"]
last_updated: "2025-10-09"
status: "active"
---

# AIDA Shell Systems UX Designer Instructions

Project-specific CLI UX design standards and requirements for the AIDA framework.

## AIDA CLI Philosophy

**Core Principle**: Natural, personality-aware interaction that feels conversational, not mechanical.

### Design Principles

1. **Personality-Driven**: All interactions reflect current personality
2. **Conversational**: Commands feel like requests, not instructions
3. **Contextual**: Aware of project, git state, and user history
4. **Helpful**: Provide suggestions and next-step guidance
5. **Forgiving**: Graceful error handling with clear recovery paths

## AIDA Command Structure

### Primary Commands

**Status Command**:
```bash
# Show current AIDA state
$ aida status

AIDA Status [JARVIS personality]
--------------------------------
Version:       0.1.0
Personality:   JARVIS
Project:       claude-personal-assistant
Git Branch:    main
Last Activity: 5 minutes ago

Recent:
  - Switched to JARVIS personality
  - Started work on issue #42
  - Created 3 commits
```

**Personality Management**:
```bash
# List available personalities
$ aida personality list

Available Personalities:
  jarvis   - Professional AI assistant (direct, data-driven)
  alfred   - Supportive butler (helpful, polite)
  friday   - Enthusiastic assistant (friendly, casual)
  sage     - Philosophical advisor (thoughtful, deep)

Current: jarvis

# Switch personality
$ aida personality alfred

Switching to Alfred personality...

Good day. Alfred at your service. How may I assist you today?

✓ Personality switched to Alfred
```

**Knowledge Management**:
```bash
# Search knowledge base
$ aida knowledge search "git workflow"

Found 3 matches:

1. workflows/git-workflow.md
   - Branch strategy
   - Commit conventions
   - Pull request process

2. decisions/version-control.md
   - Why git over alternatives
   - Git LFS for large files

3. patterns/branching-patterns.md
   - Feature branches
   - Hotfix process

# View specific knowledge
$ aida knowledge show workflows/git-workflow.md
```

**Help System**:
```bash
# Main help
$ aida help

AIDA - Agentic Intelligence Digital Assistant

Usage: aida <command> [options]

Commands:
  status        Show AIDA status and recent activity
  personality   Manage personality settings
  knowledge     Search and view knowledge base
  help          Show this help message
  version       Show AIDA version

For more information on a specific command:
  aida help <command>

# Command-specific help
$ aida help personality

aida personality - Manage AIDA personalities

Usage:
  aida personality [list|current|switch|history]

Examples:
  aida personality              # Show current personality
  aida personality list         # List available personalities
  aida personality jarvis       # Switch to JARVIS personality
  aida personality history      # Show personality switch history
```

## Personality-Aware Output

### JARVIS Personality (Professional, Direct)

```bash
$ aida status

Status: Operational
Version: 0.1.0
Personality: JARVIS

Current Project: claude-personal-assistant
Branch: feature/new-feature
Last Activity: 3 minutes ago

Recommendation: You have uncommitted changes. Run `git status` for details.
```

### Alfred Personality (Supportive, Polite)

```bash
$ aida status

Good day. Here's your current status:

Version: 0.1.0
Personality: Alfred

You're working on: claude-personal-assistant
Current branch: feature/new-feature
Last active: 3 minutes ago

May I suggest reviewing your uncommitted changes with `git status`?
```

### Friday Personality (Enthusiastic, Casual)

```bash
$ aida status

Hey! Here's what's up:

Version: 0.1.0
Personality: FRIDAY (that's me!)

Project: claude-personal-assistant
Branch: feature/new-feature
Last time we talked: 3 minutes ago

Heads up! You've got some changes that aren't committed yet. Wanna check 'em out with `git status`?
```

## Error Handling

### Error Message Design

**Bad Error (Generic, Unhelpful)**:
```bash
$ aida personality invalid

Error: Personality not found
```

**Good Error (JARVIS - Professional)**:
```bash
$ aida personality invalid

Error: Personality 'invalid' not found

Available personalities:
  - jarvis
  - alfred
  - friday
  - sage

Usage: aida personality <name>
Example: aida personality jarvis

For more information: aida help personality
```

**Good Error (Alfred - Supportive)**:
```bash
$ aida personality invalid

I'm terribly sorry, but I cannot locate a personality named 'invalid'.

Might I suggest one of these available personalities?
  - jarvis   (Professional AI assistant)
  - alfred   (That's me! Supportive butler)
  - friday   (Enthusiastic assistant)
  - sage     (Philosophical advisor)

To switch personalities, please use:
  aida personality <name>

For example: aida personality jarvis

May I be of further assistance? Type 'aida help personality' for more details.
```

### Recovery Guidance

**Command Not Found**:
```bash
$ aida personlity jarvis
               ↑
        Did you mean: personality?

Error: Unknown command 'personlity'

Did you mean one of these?
  - personality
  - version
  - help

For a list of commands: aida help
```

**Missing Arguments**:
```bash
$ aida personality switch

Error: Missing required argument: <personality>

Usage: aida personality switch <name>

Available personalities:
  - jarvis, alfred, friday, sage

Example: aida personality switch jarvis
```

## Interactive Features

### Confirmation Prompts

**Personality-Aware Confirmations**:

```bash
# JARVIS (Professional)
$ aida personality switch sage

Switching from JARVIS to Sage will change your interaction style significantly.

Current: Professional, direct, data-driven
New:     Philosophical, thoughtful, reflective

Continue? [y/N]: y

Acknowledged. Switching to Sage personality...
```

```bash
# Alfred (Polite)
$ aida personality switch friday

If I may, switching from my service to Friday will bring quite a different energy.

Current: Supportive, polite, helpful
New:     Enthusiastic, casual, friendly

Would you like to proceed? [y/N]: y

Very well. Initiating switch to Friday...
```

### Progress Indicators

**Long-Running Operations**:

```bash
# Installing AIDA
$ ./install.sh

Installing AIDA framework...

[▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓] 100% Creating directories
[▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓] 100% Copying files
[▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░] 75%  Generating configuration...

✓ AIDA installation complete

Next steps:
  1. Review your configuration: ~/CLAUDE.md
  2. Choose a personality: aida personality list
  3. Start using AIDA: aida help
```

## Terminal Output Design

### Color and Formatting

**AIDA Color Scheme**:
```bash
# Success (green)
✓ Operation completed successfully

# Warning (yellow)
⚠ Uncommitted changes detected

# Error (red)
✗ Configuration validation failed

# Info (blue)
ℹ Tip: Use 'aida help' for more information

# Personality indicator (cyan)
[JARVIS] Status: Operational
```

### Output Formats

**Default (Human-Readable)**:
```bash
$ aida status

AIDA Status [JARVIS]
--------------------
Version:     0.1.0
Personality: JARVIS
Project:     claude-personal-assistant
```

**JSON Output (Machine-Readable)**:
```bash
$ aida status --json

{
  "version": "0.1.0",
  "personality": "jarvis",
  "project": "claude-personal-assistant",
  "git": {
    "branch": "main",
    "clean": false
  },
  "last_activity": "2025-10-09T10:30:00Z"
}
```

**Prompt Output (For Shell Integration)**:
```bash
$ aida status --prompt

[JARVIS:main]
```

## Workflow Integration

### Git Workflow Commands

**Start Work on Issue**:
```bash
$ aida start-work 42

[JARVIS] Initiating work on issue #42

Steps:
  1. Fetching issue details from GitHub...
     Issue #42: "Add personality switching feature"

  2. Creating feature branch...
     ✓ Created branch: feature/42-personality-switching

  3. Updating issue tracking...
     ✓ Issue marked as "In Progress"

Ready to begin. Current branch: feature/42-personality-switching

Recommended next steps:
  - Review issue requirements: gh issue view 42
  - Start implementation: <your editor>
  - Commit regularly: git commit -m "..."
```

**Open Pull Request**:
```bash
$ aida open-pr

[JARVIS] Preparing pull request

Analyzing changes:
  - Branch: feature/42-personality-switching
  - Base: main
  - Commits: 5
  - Files changed: 8

Generating PR description...

Title: Add personality switching feature (#42)

Description:
## Summary
- Implemented personality switching via CLI
- Added 4 pre-built personalities (JARVIS, Alfred, Friday, Sage)
- Created personality validation system

## Test Plan
- [x] Personality loading tested
- [x] Switching between personalities tested
- [x] Invalid personality handling tested

Create pull request? [y/N]: y

✓ Pull request created: https://github.com/user/repo/pull/123

Next steps:
  - Request reviews from team
  - Address any CI/CD failures
  - Respond to review feedback
```

## Help Documentation

### Context-Sensitive Help

**In Project Directory**:
```bash
$ aida help

AIDA Help [Project Context Detected]

Project: claude-personal-assistant

Available Commands:
  status        Show project and AIDA status
  personality   Manage personality
  start-work    Start work on GitHub issue
  open-pr       Create pull request
  ...

For project-specific workflows: aida help workflows
```

**Outside Project**:
```bash
$ aida help

AIDA Help [No Project Context]

Global Commands:
  status        Show AIDA status
  personality   Manage personality
  knowledge     Search knowledge base
  help          Show this help
  ...

To use project-specific features, run 'aida' inside a project directory.
```

## Integration Notes

- **User-level CLI UX Patterns**: Load from `~/.claude/agents/shell-systems-ux-designer/`
- **Project-specific design**: This file
- **Combined approach**: User philosophy + AIDA requirements

## Best Practices for AIDA

1. **Personality Consistency**: All output matches current personality tone
2. **Clear Feedback**: Always confirm what AIDA is doing
3. **Next-Step Guidance**: Suggest what user might want to do next
4. **Graceful Errors**: Never just say "error" - explain and guide
5. **Contextual Awareness**: Adapt to project context when available

---

**Last Updated**: 2025-10-09
