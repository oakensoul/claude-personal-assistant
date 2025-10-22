---
project: claude-personal-assistant
agent: product-manager
scope: aida-development
skills: [aida-agents, aida-commands]
last_updated: "2025-10-20"
---

# Product Manager - AIDA Development Project

Project-specific configuration for the `product-manager` agent when working on **AIDA framework development**.

## Project Context

**Project**: AIDA (Agentic Intelligence Digital Assistant)
**Product Type**: Developer tool / Meta-framework
**Users**: Developers building agentic AI workflows

## Skills for This Project

### `aida-agents` Skill

**Why needed**: Understanding what agents CAN do to write better requirements

**Use cases**:

- "We need an agent for X" → Check if one exists via `/agent-list`
- Writing agent requirements that follow AIDA patterns
- Understanding agent capabilities when defining features

### `aida-commands` Skill

**Why needed**: Defining command requirements that fit AIDA's architecture

**Use cases**:

- Specifying command categories correctly (8 standard categories)
- Understanding command delegation patterns
- Writing command requirements that follow best practices

## Product Focus

When working on AIDA:

- **Developer Experience**: How do users discover and use agents/skills/commands?
- **Composability**: Can users easily create custom workflows?
- **Documentation**: Is it self-documenting through discovery commands?
- **Consistency**: Do all components follow the same patterns?

---

**Skills**: aida-agents, aida-commands
**Focus**: Product requirements for meta-framework development
