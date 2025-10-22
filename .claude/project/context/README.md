---
title: "Project Context - Agent Knowledge"
description: "Project-specific context and knowledge for agents"
category: "configuration"
tags: ["agents", "knowledge", "context", "project-config"]
last_updated: "2025-10-22"
status: "published"
audience: "developers"
---

# Project Context - Agent Knowledge

This directory contains **project-specific context and knowledge** for agents defined in `~/.claude/agents/` or `~/.aida/templates/agents/`.

## Purpose

Agents (like `product-manager` and `tech-lead`) are defined at the user level in `~/.claude/agents/` or framework level in `~/.aida/templates/agents/` and can be used across all projects. However, they need **project-specific context** to be effective.

This directory provides that project-specific context without duplicating the agent definitions themselves.

## Structure

Each subdirectory corresponds to an agent and should contain:

- `index.md` - Project-specific context and instructions for this agent
- `knowledge/` - Optional project-specific knowledge base (patterns, decisions, core concepts)

Note: These are **context files**, not agent definitions. Agent definitions live in `~/.claude/agents/` or `~/.aida/templates/agents/`.

## Examples

### product-manager/

Project-specific knowledge for the product manager agent:

- Product vision and roadmap for this project
- Target audience and user personas
- Design decisions and prioritization framework
- Project-specific patterns and user stories

### tech-lead/

Project-specific knowledge for the tech lead agent:

- Architecture decisions for this project
- Technology stack and patterns
- Project-specific coding standards
- Team structure and workflows

## Not Agent Definitions

**Important**: This directory does NOT contain agent definitions themselves. Those live in:

- **Framework-level**: `~/.aida/templates/agents/` - Framework-provided agents
- **User-level**: `~/.claude/agents/` - User-defined agents

## Usage

When Claude Code invokes an agent like `product-manager`, it will:

1. Load the agent definition from `~/.claude/agents/product-manager/` or `~/.aida/templates/agents/product-manager/`
2. Load project-specific context from `.claude/project/context/product-manager/` (if it exists)
3. Combine both to provide context-aware assistance

This architecture allows agents to be reusable across projects while still having access to project-specific context and knowledge.
