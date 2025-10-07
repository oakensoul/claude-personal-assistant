---
title: "Product Manager Knowledge Base"
description: "Generic knowledge base for product management patterns and requirements analysis"
category: "meta"
tags: ["knowledge", "product-manager", "patterns", "template"]
last_updated: "2025-10-06"
status: "published"
audience: "developers"
---

# Product Manager Knowledge Base

This directory contains generic, reusable knowledge for the Product Manager agent.

## Purpose

This knowledge base provides:

- **Generic patterns** for requirements analysis and PRD creation
- **Reusable prioritization frameworks** applicable across projects
- **Decision frameworks** for product management
- **No user-specific data** - privacy-safe templates only

## Directory Structure

### `core-concepts/`

Fundamental concepts about product management:

- Requirements gathering methodologies
- PRD structure and content principles
- Stakeholder communication strategies
- Product prioritization frameworks

### `patterns/`

Reusable patterns and templates:

- PRD templates and structures
- User story formats
- Acceptance criteria patterns
- Prioritization frameworks (RICE, MoSCoW, etc.)

### `decisions/`

Generic decision frameworks:

- Feature prioritization criteria
- Scope management strategies
- Trade-off analysis approaches
- Stakeholder alignment techniques

## Populating This Knowledge Base

**What to include:**

- Generic PRD templates
- Universal prioritization frameworks
- Requirements analysis methodologies
- Stakeholder communication patterns

**What NOT to include:**

- User-specific PM philosophy
- Project-specific requirements
- Personal prioritization preferences
- Any user-identifiable information

## Usage

When the Product Manager agent runs, it should:

1. Load generic PM patterns from this template directory
2. Apply requirements frameworks to current context
3. Make prioritization decisions based on frameworks provided
4. Optionally accumulate new generic patterns here (with privacy review)

---

**Note**: This is a privacy-safe template. User-specific knowledge should be stored in `${CLAUDE_CONFIG_DIR}/agents/product-manager/knowledge/` after installation.
