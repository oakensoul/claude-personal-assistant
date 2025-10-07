---
title: "Code Reviewer Knowledge Base"
description: "Generic knowledge base for code review patterns and quality standards"
category: "meta"
tags: ["knowledge", "code-review", "patterns", "template"]
last_updated: "2025-10-06"
status: "published"
audience: "developers"
---

# Code Reviewer Knowledge Base

This directory contains generic, reusable knowledge for the Code Reviewer agent.

## Purpose

This knowledge base provides:

- **Generic patterns** for code review across technologies
- **Reusable quality standards** applicable to multiple projects
- **Decision frameworks** for code quality assessment
- **No user-specific data** - privacy-safe templates only

## Directory Structure

### `core-concepts/`

Fundamental concepts about code review:

- Code quality principles
- Security review frameworks
- Performance review patterns
- Testing strategy assessment

### `patterns/`

Reusable patterns and templates:

- Multi-language review patterns (PHP, JavaScript/TypeScript, etc.)
- Security vulnerability detection patterns
- Performance bottleneck identification
- Code maintainability assessment

### `decisions/`

Generic decision frameworks:

- When to escalate security issues
- Performance threshold determination
- Code complexity assessment criteria
- Test coverage requirements

## Populating This Knowledge Base

**What to include:**

- Generic code quality standards (PSR, ESLint configs, etc.)
- Language-agnostic review patterns
- Security review checklists (OWASP, etc.)
- Performance optimization patterns

**What NOT to include:**

- User-specific coding preferences
- Project-specific quality gates
- Personal style preferences
- Any user-identifiable information

## Usage

When the Code Reviewer agent runs, it should:

1. Load generic quality standards from this template directory
2. Apply review patterns to code under review
3. Make assessment decisions based on frameworks provided
4. Optionally accumulate new generic patterns here (with privacy review)

---

**Note**: This is a privacy-safe template. User-specific knowledge should be stored in `${CLAUDE_CONFIG_DIR}/agents/code-reviewer/knowledge/` after installation.
