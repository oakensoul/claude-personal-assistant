---
title: "DevOps Engineer Knowledge Base"
description: "Generic knowledge base for DevOps patterns and infrastructure management"
category: "meta"
tags: ["knowledge", "devops", "patterns", "template"]
last_updated: "2025-10-06"
status: "published"
audience: "developers"
---

# DevOps Engineer Knowledge Base

This directory contains generic, reusable knowledge for the DevOps Engineer agent.

## Purpose

This knowledge base provides:

- **Generic patterns** for CI/CD and infrastructure management
- **Reusable deployment strategies** applicable across projects
- **Decision frameworks** for DevOps architecture
- **No user-specific data** - privacy-safe templates only

## Directory Structure

### `core-concepts/`

Fundamental concepts about DevOps:

- CI/CD pipeline architecture
- Infrastructure as Code principles
- Deployment strategies
- Monitoring and observability patterns

### `patterns/`

Reusable patterns and templates:

- GitHub Actions workflow patterns
- Docker and containerization strategies
- Deployment automation patterns
- Infrastructure management approaches

### `decisions/`

Generic decision frameworks:

- When to use different deployment strategies
- Infrastructure scaling decisions
- Tool selection criteria
- Security vs. convenience trade-offs

## Populating This Knowledge Base

**What to include:**

- Generic CI/CD pipeline patterns
- Infrastructure as Code best practices
- Container orchestration strategies
- Deployment workflow templates

**What NOT to include:**

- User-specific deployment configurations
- Project-specific infrastructure details
- Personal tool preferences
- Any user-identifiable information

## Usage

When the DevOps Engineer agent runs, it should:

1. Load generic DevOps patterns from this template directory
2. Apply infrastructure patterns to current context
3. Make deployment decisions based on frameworks provided
4. Optionally accumulate new generic patterns here (with privacy review)

---

**Note**: This is a privacy-safe template. User-specific knowledge should be stored in `${CLAUDE_CONFIG_DIR}/agents/devops-engineer/knowledge/` after installation.
