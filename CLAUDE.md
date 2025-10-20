---
title: "CLAUDE.md - Project Instructions"
description: "Guidance for Claude Code when working with this repository"
category: "meta"
tags: ["claude", "instructions", "project-config", "development"]
last_updated: "2025-10-20"
status: "published"
audience: "developers"
---

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AIDA (Agentic Intelligence Digital Assistant) is a conversational, agentic operating system for managing digital life through Claude AI. This is the **public framework** repository that provides the core system anyone can use.

### Three-Repo Ecosystem

1. **`claude-personal-assistant`** (this repo) - Public framework with templates, personalities, and installation scripts
   - Installs to `~/.aida/`
   - **Standalone**: Works without dotfiles
   - Core AI functionality

2. **`dotfiles`** - Public configuration templates with generic shell configs and AIDA templates
   - Managed with GNU Stow
   - **Standalone**: Works without AIDA (shell/git/vim configs)
   - **Optional**: Can integrate with AIDA if `~/.aida/` exists
   - **Recommended entry point** for most users

3. **`dotfiles-private`** - Private configurations with secrets and API keys (not public)
   - Overlays dotfiles and/or AIDA
   - Not standalone

**Architecture**: See [docs/architecture/dotfiles-integration.md](docs/architecture/dotfiles-integration.md) for complete integration details.

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

### Installation and Testing

```bash
# Installation
./install.sh                    # Normal install (creates ~/.claude/)
./install.sh --dev              # Dev mode (symlinks for live editing)
./install.sh --help             # Show usage and options

# Setup development environment
pre-commit install              # Install pre-commit hooks

# Testing
pre-commit run --all-files      # Run all quality checks (shellcheck, yamllint, markdownlint)
./scripts/validate-templates.sh --verbose  # Validate template variables and privacy

# Testing installation across platforms (Docker-based)
./.github/testing/test-install.sh              # All platforms
./.github/testing/test-install.sh --env ubuntu-22  # Specific environment
./.github/testing/test-install.sh --verbose    # Detailed output
```

### CLI Commands (planned)

```bash
aida status          # System status
aida personality     # Manage personality
aida knowledge       # View knowledge base
aida memory          # View memory
aida help            # Show help
```

### Custom Slash Commands

This repository provides workflow commands (when installed).

#### Discovery Commands (Meta)

- `/agent-list` - List all available agents with versions and descriptions
- `/skill-list` - List all available skills grouped by category
- `/command-list` - List all available commands with optional category filtering

These commands delegate to the `claude-agent-manager` agent which uses meta-skills for comprehensive knowledge.

#### Workflow Commands

- `/start-work` - Begin work on a GitHub issue (creates branch, updates issue tracking)
- `/implement` - Implement planned features with auto-commit after each task
- `/open-pr` - Create pull request with version bumping and changelog updates
- `/cleanup-main` - Post-merge cleanup (update main, delete branch, restore stash)

See `templates/commands/` for all available workflow templates.

### AIDA Meta-Skills

This project includes three foundational meta-skills that provide comprehensive knowledge about AIDA's architecture:

#### `aida-agents` Skill

**Location**: `templates/skills/aida-agents/`

**Provides knowledge about**:

- Agent architecture (two-tier system, file structure, naming conventions)
- Frontmatter schema (required/optional fields, validation)
- Agent categories and design patterns
- Creating, updating, and validating agents
- Integration with `list-agents.sh` CLI script
- Best practices and troubleshooting

**Used by**: `claude-agent-manager` agent for all agent-related operations

#### `aida-skills` Skill

**Location**: `templates/skills/aida-skills/`

**Provides knowledge about**:

- Skill architecture (composable knowledge modules)
- Skills vs. Agents (key differences and relationships)
- Frontmatter schema and skill categories
- Creating, updating, and validating skills
- How agents use skills (assignment patterns, loading strategies)
- Integration with `list-skills.sh` CLI script
- Skill patterns (procedural, decision framework, pattern library, etc.)

**Used by**: `claude-agent-manager` agent for all skill-related operations

#### `aida-commands` Skill

**Location**: `templates/skills/aida-commands/`

**Provides knowledge about**:

- Command architecture (slash commands, namespaces, .aida framework commands)
- Category taxonomy (8 standard categories: workflow, git, project, analysis, deployment, testing, documentation, meta)
- Frontmatter schema and command structure
- Creating, updating, and validating commands
- Delegation patterns (how commands invoke agents)
- Integration with `list-commands.sh` CLI script
- Command patterns and best practices

**Used by**: `claude-agent-manager` agent for all command-related operations

#### Why Meta-Skills Matter

**Composable Knowledge**: Any agent can reference these skills to understand AIDA's architecture without duplicating documentation.

**Single Source of Truth**: When AIDA's schemas or patterns change, update the meta-skill once and all agents benefit.

**Reduced Context Size**: Agents reference skills instead of embedding large knowledge blocks, keeping agent files lean and focused on behavior.

**Example Architecture**:

```text
User invokes: /agent-list
    ↓
Command delegates to: claude-agent-manager
    ↓
Agent loads skill: aida-agents (comprehensive knowledge)
    ↓
Agent executes: list-agents.sh (CLI script)
    ↓
Agent presents: Results with context from skill knowledge
```

See `templates/agents/claude-agent-manager/` for how the meta-agent uses these skills.

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
- Source shared utilities from `lib/installer-common/` library

### YAML Guidelines

- Pass `yamllint --strict`
- Use 2-space indentation
- No document-start markers (`---`) in docker-compose.yml

### Template Variable Substitution

**Two types of variables for privacy and flexibility:**

**Install-time variables** (`{{VAR}}`) - Substituted during installation:

- `{{AIDA_HOME}}` - AIDA installation directory
- `{{CLAUDE_CONFIG_DIR}}` - Claude config directory
- `{{HOME}}` - User's home directory

**Runtime variables** (`${VAR}`) - Resolved when commands execute:

- `${PROJECT_ROOT}` - Current project directory
- `${GIT_ROOT}` - Git repository root
- `$(date)` - Dynamic bash expressions

**Example:**

```markdown
# Install-time for user paths
{{CLAUDE_CONFIG_DIR}}/knowledge/

# Runtime for project paths
${PROJECT_ROOT}/docs/
```

**Full standards**: See [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md)

## Multi-Repo Coordination

AIDA is part of a three-repository ecosystem. Understanding how they interact is critical for development.

### The Three Repositories

**1. claude-personal-assistant (this repo)** - Core AIDA framework

- **Location**: `~/.aida/`
- **Standalone**: Yes - works without dotfiles
- **Provides**: AI assistant, personalities, agents, templates

**2. dotfiles (public)** - Base shell/git/vim configurations

- **Location**: `~/dotfiles/` → stowed to `~/`
- **Standalone**: Yes - works without AIDA
- **Provides**: Shell configs, git configs, AIDA integration templates

**3. dotfiles-private** - Personal overrides with secrets

- **Location**: `~/dotfiles-private/` → stowed to `~/`
- **Standalone**: No - overlays dotfiles and/or AIDA
- **Provides**: API keys, secrets, personal customizations

### Installation Flows

**Test all flows when implementing features:**

- **AIDA standalone**: Install AIDA only (works without dotfiles)
- **Dotfiles-first** (recommended): Dotfiles optionally install AIDA
- **Either order works**: Install AIDA or dotfiles first, integrate later

### Repository Boundaries

When implementing features, maintain the separation between:

- **Public shareable framework** (this repo) - standalone AIDA
- **Public dotfiles** (shell/git/vim) - optional AIDA integration
- **User-generated configuration** (`~/.claude/`) - created by AIDA install
- **Private sensitive data** (dotfiles-private repo) - overlays both

See [docs/architecture/dotfiles-integration.md](docs/architecture/dotfiles-integration.md) for complete details.

## Current State

**Active development** - v0.1.6 released with modular installer and .aida namespace installation.

**In progress** - v0.1.7: Discoverability commands (Issue #54)

- ✅ AIDA meta-skills created (`aida-agents`, `aida-skills`, `aida-commands`)
- ✅ CLI infrastructure built (frontmatter parser, path sanitizer, JSON formatter)
- ✅ Discovery scripts created (`list-agents.sh`, `list-skills.sh`, `list-commands.sh`)
- ✅ Slash commands created (`/agent-list`, `/skill-list`, `/command-list`)
- ✅ `claude-agent-manager` agent updated with meta-skills
- 🚧 Configuration migration (add category/version to 32 commands)
- 🚧 Testing & validation
- 🚧 Installer integration
