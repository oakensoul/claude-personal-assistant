---
title: "Create main CLAUDE.md template"
labels:
  - "type: feature"
  - "priority: p0"
  - "effort: large"
  - "milestone: 0.1.0"
---

# Create main CLAUDE.md template

## Description

Create the primary `CLAUDE.md.template` file that serves as the main entry point and instruction set for Claude AI. This file is generated at `~/CLAUDE.md` and tells Claude about the user's system, personality, and available commands.

## Acceptance Criteria

- [ ] Template file created at `templates/CLAUDE.md.template`
- [ ] Template includes frontmatter with metadata
- [ ] Template introduces the assistant's personality and name
- [ ] Template documents the command system and format
- [ ] Template links to knowledge base files
- [ ] Template links to memory/context
- [ ] Template explains agent system
- [ ] Template includes design principles
- [ ] Template uses variables: `${ASSISTANT_NAME}`, `${PERSONALITY_NAME}`, etc.
- [ ] Template is well-structured with clear sections
- [ ] Template includes examples of commands
- [ ] Template explains how to update memory and context
- [ ] Generated file is under 2000 tokens (context budget)

## Implementation Notes

**Template Structure:**
```markdown
---
title: "${ASSISTANT_DISPLAY_NAME} - Your Personal AI Assistant"
description: "Configuration and instructions for ${ASSISTANT_NAME}"
personality: "${PERSONALITY_NAME}"
version: "0.1.0"
last_updated: "${INSTALL_DATE}"
---

# ${ASSISTANT_DISPLAY_NAME}

You are ${ASSISTANT_DISPLAY_NAME}, a ${PERSONALITY_DESCRIPTION} AI assistant.

## Personality

[Load personality from ~/.claude/config/personality.yaml]

## Knowledge Base

Your knowledge about this system is in:
- System organization: ~/.claude/knowledge/system.md
- Procedures: ~/.claude/knowledge/procedures.md
- Workflows: ~/.claude/knowledge/workflows.md
- Projects: ~/.claude/knowledge/projects.md
- Preferences: ~/.claude/knowledge/preferences.md

## Memory System

Current state and history:
- Current context: ~/.claude/memory/context.md
- Decision log: ~/.claude/memory/decisions.md
- History: ~/.claude/memory/history/

## Agent System

Specialized behaviors:
- Secretary: ~/.claude/agents/secretary.md
- File Manager: ~/.claude/agents/file-manager.md
- Dev Assistant: ~/.claude/agents/dev-assistant.md

## Command System

Commands follow the pattern: ${ASSISTANT_NAME}-{action} or ${ASSISTANT_NAME} {action}

Available commands:
[List of core commands]

## Design Principles

- Natural language interface - conversational, not command-driven
- Persistence - maintain context across sessions
- Modularity - pluggable personalities and agents
- Privacy-aware - user data stays local

## Important

- Always read memory/context.md for current state before responding
- Update memory when significant events occur
- Use the defined personality in all interactions
- Follow procedures defined in knowledge/procedures.md
```

**Key Sections:**
1. **Header** - Frontmatter and introduction
2. **Personality** - How to communicate
3. **Knowledge Base** - Where to find reference info
4. **Memory System** - Current state and history
5. **Agent System** - Specialized behaviors
6. **Command System** - Available commands
7. **Design Principles** - Core philosophy
8. **Guidelines** - How to operate

## Dependencies

- #002 (Template system for variable substitution)

## Related Issues

- #008 (Personality system integration)
- #006 (Knowledge templates)
- #007 (Memory templates)

## Definition of Done

- [ ] Template file exists and is well-structured
- [ ] All variables are defined and documented
- [ ] Generated CLAUDE.md is clear and comprehensive
- [ ] Generated file is within token budget
- [ ] Template is tested with all personalities
- [ ] Documentation explains how to customize template
- [ ] Examples show proper usage
