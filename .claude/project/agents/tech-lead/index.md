---
project: claude-personal-assistant
agent: tech-lead
scope: aida-development
skills: [aida-agents, aida-skills, aida-commands]
last_updated: "2025-10-20"
---

# Tech Lead - AIDA Development Project

Project-specific configuration for the `tech-lead` agent when working on **AIDA framework development**.

## Project Context

**Project**: AIDA (Agentic Intelligence Digital Assistant)
**Tech Focus**: Shell scripting, frontmatter parsing, agent/skill/command system
**Languages**: Bash, Markdown, YAML

## Skills for This Project

### `aida-agents` Skill

**Why needed**: Implementing agents that follow AIDA standards

**Use cases**:

- Creating new agents with correct frontmatter
- Reviewing agent implementations for compliance
- Implementing agent discovery mechanisms
- Code review for agent-related changes

### `aida-skills` Skill

**Why needed**: Implementing skills and skill assignment

**Use cases**:

- Creating new skills with correct structure
- Implementing skill loading in agents
- Reviewing skill implementations
- Understanding composability patterns

### `aida-commands` Skill

**Why needed**: Implementing commands correctly

**Use cases**:

- Creating commands in correct categories
- Implementing command delegation
- Reviewing command implementations
- Ensuring .aida namespace usage

## Technical Standards for AIDA

When working on this project:

### Code Quality

- All bash scripts pass shellcheck
- All markdown passes markdownlint
- Frontmatter follows schemas from meta-skills

### Architecture Patterns

- Two-tier system (user vs. project)
- Composability (agents use skills)
- Discoverability (list-*.sh scripts)
- Privacy (path sanitization)

### Testing

- Pre-commit hooks validate all changes
- Cross-platform compatibility (macOS + Linux)
- Performance targets (<500ms for most operations)

---

**Skills**: aida-agents, aida-skills, aida-commands
**Focus**: Technical implementation of AIDA meta-framework
