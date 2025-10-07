---
title: "Claude Agent Manager Knowledge Base"
description: "Generic knowledge base for agent management and creation patterns"
category: "meta"
tags: ["knowledge", "agent-manager", "patterns", "template"]
last_updated: "2025-10-06"
status: "published"
audience: "developers"
---

# Claude Agent Manager Knowledge Base

This directory contains generic, reusable knowledge for the Claude Agent Manager agent.

## Purpose

This knowledge base provides:

- **Generic patterns** for agent creation and management
- **Reusable concepts** applicable across all projects
- **Decision frameworks** for agent architecture
- **No user-specific data** - privacy-safe templates only

## Directory Structure

### `core-concepts/`

Fundamental concepts about agent management:

- Agent architecture patterns
- Agent lifecycle management
- Agent coordination strategies
- MCP integration patterns

### `patterns/`

Reusable patterns and templates:

- Agent creation patterns
- Knowledge organization patterns
- Agent communication patterns
- Multi-agent coordination workflows

### `decisions/`

Generic decision frameworks:

- When to create new agents vs. extend existing
- Agent specialization vs. generalization trade-offs
- Knowledge sharing strategies
- Agent tool access patterns

## Populating This Knowledge Base

**What to include:**

- Generic agent management best practices
- Framework-level patterns applicable to any project
- Architectural patterns proven across multiple use cases
- Tool usage patterns and optimization strategies

**What NOT to include:**

- User-specific learned patterns
- Project-specific agent configurations
- Personal preferences or workflows
- Any user-identifiable information

## Usage

When the Claude Agent Manager agent runs, it should:

1. Load generic knowledge from this template directory
2. Apply patterns to current context
3. Make decisions based on frameworks provided
4. Optionally accumulate new generic patterns here (with privacy review)

---

**Note**: This is a privacy-safe template. User-specific knowledge should be stored in `${CLAUDE_CONFIG_DIR}/agents/claude-agent-manager/knowledge/` after installation.
