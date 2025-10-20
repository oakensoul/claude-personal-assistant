---
title: "Global Agents - Project Extensions"
description: "Project-specific knowledge for global (user-level) agents"
category: "configuration"
tags: ["agents", "knowledge", "global", "project-config"]
last_updated: "2025-10-09"
status: "published"
audience: "developers"
---

# Global Agents - Project Extensions

This directory contains **project-specific knowledge** for global (user-level) agents that are defined in `~/.claude/agents/`.

## Purpose

Global agents (like `product-manager` and `tech-lead`) are defined at the user level in `~/.claude/agents/` and can be used across all projects. However, they need **project-specific context** to be effective.

This directory provides that project-specific knowledge without duplicating the agent definitions themselves.

## Structure

Each subdirectory corresponds to a global agent and should contain:

- `index.md` - Project-specific instructions and context for this agent
- `knowledge/` - Optional project-specific knowledge base (patterns, decisions, core concepts)

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

- **User-level**: `~/.claude/agents/` - Global agent definitions
- **Project-level**: `.claude/agents/` - Standalone project-specific agents

## Usage

When Claude Code invokes a global agent like `product-manager`, it will:

1. Load the agent definition from `~/.claude/agents/product-manager/`
2. Load project-specific context from `.claude/project/agents/product-manager/`
3. Combine both to provide context-aware assistance

This architecture allows global agents to be reusable across projects while still having access to project-specific knowledge.
