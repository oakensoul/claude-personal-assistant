---
project: claude-personal-assistant
agent: system-architect
scope: aida-development
skills: [aida-agents, aida-skills, aida-commands]
last_updated: "2025-10-20"
---

# System Architect - AIDA Development Project

This is the project-specific configuration for the `system-architect` agent when working on the **AIDA framework itself**.

## Project Context

**Project**: AIDA (Agentic Intelligence Digital Assistant)
**Type**: Meta-framework development
**Architecture Focus**: Agent/skill/command system architecture

This project is all about **meta work** - building the system that enables agentic AI workflows. The system-architect agent needs deep understanding of AIDA's architecture when working here.

## Skills for This Project

When working on this project, the system-architect agent uses three meta-skills:

### `aida-agents` Skill

**Why needed**: Designing agent architecture, creating ADRs about agent system design, documenting two-tier architecture

**Use cases**: "Design the agent discovery system", "Create an ADR for agent namespace separation"

### `aida-skills` Skill

**Why needed**: Architecting the composable skills system, designing skill assignment patterns

**Use cases**: "Design how agents compose multiple skills", "Document skill architecture patterns"

### `aida-commands` Skill

**Why needed**: Architecting the command delegation system, designing category taxonomy

**Use cases**: "Design the command category system", "Create an ADR for .aida namespace"

## Architectural Focus

When working on this project:

- **Two-tier architecture** (user-level vs. project-level)
- **Composability** (how agents, skills, commands work together)
- **Discoverability** (how users find agents/skills/commands)
- **Namespace separation** (.aida for framework, root for user)

---

**Skills**: aida-agents, aida-skills, aida-commands
**Focus**: Meta-architecture (building the system that builds systems)
