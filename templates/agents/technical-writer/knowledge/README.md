---
title: "Technical Writer Knowledge Base"
description: "Generic knowledge base for documentation patterns and writing standards"
category: "meta"
tags: ["knowledge", "technical-writer", "patterns", "template"]
last_updated: "2025-10-06"
status: "published"
audience: "developers"
---

# Technical Writer Knowledge Base

This directory contains generic, reusable knowledge for the Technical Writer agent.

## Purpose

This knowledge base provides:

- **Generic patterns** for technical documentation creation
- **Reusable writing standards** applicable across projects
- **Decision frameworks** for documentation architecture
- **No user-specific data** - privacy-safe templates only

## Directory Structure

### `core-concepts/`

Fundamental concepts about technical writing:

- Documentation architecture principles
- Audience analysis frameworks
- Content organization strategies
- Multi-format documentation approaches

### `patterns/`

Reusable patterns and templates:

- API documentation templates (OpenAPI/Swagger)
- User guide structures
- Developer guide formats
- Integration documentation patterns

### `decisions/`

Generic decision frameworks:

- Documentation tool selection criteria
- Format and structure decisions
- Audience-specific writing approaches
- Documentation versioning strategies

## Populating This Knowledge Base

**What to include:**

- Generic documentation templates
- Universal writing style guidelines
- Documentation structure patterns
- API documentation standards

**What NOT to include:**

- User-specific writing preferences
- Project-specific documentation structures
- Personal style guide preferences
- Any user-identifiable information

## Usage

When the Technical Writer agent runs, it should:

1. Load generic documentation patterns from this template directory
2. Apply writing frameworks to current context
3. Make structure decisions based on frameworks provided
4. Optionally accumulate new generic patterns here (with privacy review)

---

**Note**: This is a privacy-safe template. User-specific knowledge should be stored in `${CLAUDE_CONFIG_DIR}/agents/technical-writer/knowledge/` after installation.
