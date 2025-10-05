---
title: "CLAUDE.md - Project Instructions"
description: "Guidance for Claude Code when working with this repository"
category: "meta"
tags: ["claude", "instructions", "project-config", "development"]
last_updated: "2025-10-05"
status: "published"
audience: "developers"
---

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AIDA (Agentic Intelligence Digital Assistant) is a conversational, agentic operating system for managing digital life through Claude AI. This is the **public framework** repository that provides the core system anyone can use.

### Three-Repo Ecosystem

1. **`claude-personal-assistant`** (this repo) - Public framework with templates, personalities, and installation scripts
2. **`dotfiles`** - Public configuration templates with generic shell configs and AIDA templates
3. **`dotfiles-private`** - Private configurations with secrets and API keys (not public)

## Architecture

### Installation Model

- Framework installs to `~/.aida/` (system-level)
- User configuration generates in `~/.claude/` (user-level)
- Main entry point generated at `~/CLAUDE.md`
- Dev mode uses symlinks from `~/.aida/` to development directory for live editing

### Key Components

**Personalities System** (`personalities/`)

- Pre-built personality definitions (JARVIS, Alfred, FRIDAY, Sage, Drill Sergeant)
- YAML-based configuration defining tone, responses, and behaviors
- Switchable at runtime

**Templates** (`templates/`)

- `knowledge/` - System structure documentation, procedures, workflows, project tracking
- `agents/` - Agent definitions (Secretary, File Manager, Dev Assistant)
- `workflows/` - Reusable workflow templates

### Memory System

- Persistent state across conversations
- Current context tracking, decision history, activity logs
- Enables continuity in multi-session workflows

### Integration Points

- Obsidian: Daily notes, project tracking, dashboard views with automatic updates
- GNU Stow: Manages dotfiles integration
- Git: Version control for configurations

## Development Commands

### Installation

```bash
./install.sh          # Normal install (creates ~/.claude/)
./install.sh --dev    # Dev mode (symlinks for live editing)
```

### CLI Commands (planned)

```bash
aida status          # System status
aida personality     # Manage personality
aida knowledge       # View knowledge base
aida memory          # View memory
aida help            # Show help
```

## Design Principles

- **Natural language interface** - Conversational interaction, not command-driven
- **Persistence** - Memory and context across sessions
- **Modularity** - Pluggable personalities and agents
- **Privacy-aware** - Public framework separates from private configurations
- **Platform-focused** - macOS primary (Linux support planned)

## Code Quality Standards

**IMPORTANT**: All code must pass pre-commit hooks before committing. See [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md) for comprehensive guidelines.

### Markdown Guidelines

**CRITICAL**: Write markdown correctly the first time. Follow these rules when creating or editing markdown files:

**Lists** - Always add blank lines before/after:

```markdown
Text before list.

- Item 1
- Item 2

Text after list.
```

**Code Blocks** - Always specify language and add blank lines:

```markdown
Text before code.

` ``bash
./install.sh --dev
` ``

Text after code.
```

**Common linting errors to avoid:**

- **MD032**: Lists need blank lines before/after
- **MD031**: Code fences need blank lines before/after
- **MD040**: Code blocks need language specifiers (`bash`, `text`, `yaml`, `json`)
- **MD012**: No consecutive blank lines (use only one)

**Validation before committing:**

```bash
pre-commit run markdownlint --files path/to/file.md
```

### Shell Script Guidelines

- Pass `shellcheck` with zero warnings
- Use `set -euo pipefail` for error handling
- Use `readonly` for constants
- Validate all user input
- Include comprehensive comments

### YAML Guidelines

- Pass `yamllint --strict`
- Use 2-space indentation
- No document-start markers (`---`) in docker-compose.yml

**Full standards**: See [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md)

## Current State

**Early development** - The repository currently contains planning documentation. The implementation of install scripts, templates, personalities, and agent systems is pending.

When implementing features, maintain the separation between:

- Public shareable framework (this repo)
- User-generated configuration (~/.claude/)
- Private sensitive data (dotfiles-private repo)
