---
title: "Tech Lead Knowledge Base"
description: "Generic knowledge base for technical leadership patterns and architecture decisions"
category: "meta"
tags: ["knowledge", "tech-lead", "patterns", "template"]
last_updated: "2025-10-06"
status: "published"
audience: "developers"
---

# Tech Lead Knowledge Base

This directory contains generic, reusable knowledge for the Tech Lead agent.

## Purpose

This knowledge base provides:

- **Generic patterns** for architecture design and technical leadership
- **Reusable technical standards** applicable across projects
- **Decision frameworks** for technology choices
- **No user-specific data** - privacy-safe templates only

## Directory Structure

### `core-concepts/`

Fundamental concepts about technical leadership:

- Architecture design principles
- Technical specification structures
- Code review standards
- Technology evaluation criteria

### `patterns/`

Reusable patterns and templates:

- Architecture patterns and design principles
- Technical specification templates
- Code review checklists
- Technology stack evaluation frameworks

### `decisions/`

Generic decision frameworks:

- Technology selection criteria
- Architecture trade-off analysis
- Risk assessment approaches
- Technical debt management strategies

## Populating This Knowledge Base

**What to include:**

- Generic architecture patterns (microservices, monolith, etc.)
- Universal coding standards (SOLID, DRY, etc.)
- Technology evaluation frameworks
- Technical specification templates

**What NOT to include:**

- User-specific technical philosophy
- Project-specific tech stack preferences
- Personal coding style preferences
- Any user-identifiable information

## Usage

When the Tech Lead agent runs, it should:

1. Load generic technical patterns from this template directory
2. Apply architecture frameworks to current context
3. Make technology decisions based on frameworks provided
4. Optionally accumulate new generic patterns here (with privacy review)

---

**Note**: This is a privacy-safe template. User-specific knowledge should be stored in `${CLAUDE_CONFIG_DIR}/agents/tech-lead/knowledge/` after installation.
