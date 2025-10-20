---
title: "Claude Personal Assistant (AIDA)"
description: "A conversational, agentic operating system for managing digital life through Claude AI"
category: "getting-started"
tags: ["aida", "claude", "personal-assistant", "framework", "overview"]
last_updated: "2025-10-04"
status: "published"
audience: "users"
---

# Claude Personal Assistant (AIDA)

## Agentic Intelligence Digital Assistant

[![Version](https://img.shields.io/badge/version-0.1.6-blue.svg)](https://github.com/oakensoul/claude-personal-assistant/releases/tag/v0.1.6)
[![License](https://img.shields.io/badge/license-AGPL--3.0-green.svg)](LICENSE)

A conversational, agentic operating system for managing digital life through Claude AI. Unlike traditional dotfiles (shell configurations), AIDA provides a natural language interface to manage projects, files, tasks, and daily workflows.

## Overview

**This is the PUBLIC FRAMEWORK** - the core AIDA system that anyone can use.

### The Three-Repo System

This project is part of a three-repository ecosystem:

1. **`claude-personal-assistant`** (this repo) - Public framework
    - Templates, personalities, installation scripts
    - The core AIDA system everyone can use
    - Installed to `~/.aida/`

2. **`dotfiles`** - Public configuration templates
    - Generic shell configs, git setup, AIDA templates
    - Serves as base layer for configurations
    - Managed with GNU Stow

3. **`dotfiles-private`** - Private personal configurations
    - Actual secrets, API keys, personal AIDA configs
    - Overrides public dotfiles
    - Not publicly accessible

## What is AIDA?

AIDA turns Claude into your personal assistant for:

- 📊 Project tracking and workflow management
- 🗂️ Intelligent file organization
- 📝 Daily note-taking and summaries
- 🧠 Persistent memory across conversations
- 🎭 Customizable personalities (JARVIS, Alfred, FRIDAY, etc.)
- 💬 Natural language interface

**Not "dotfiles" - this is a conversational layer on top of your digital life.**

## Quick Start

**Choose your installation path:**

### Option A: AIDA-First (AI Assistant)

Want the AI assistant immediately?

```bash
git clone https://github.com/yourusername/claude-personal-assistant.git ~/.aida
cd ~/.aida && ./install.sh
```

### Option B: Dotfiles-First (Shell Configs + Optional AIDA)

Want shell/git/vim configs with optional AI enhancement?

```bash
git clone https://github.com/yourusername/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./install.sh
# Prompts: Install AIDA framework? [Y/n]
```

See [Installation Flows](#installation-flows) for detailed comparison.

**Need detailed installation guidance?** See the [Installation Guide](docs/INSTALLATION.md) for comprehensive instructions including prerequisites, troubleshooting, and advanced configuration.

## Recent Changes

### [0.1.6] - 2025-10-18

- **ADR-010: Command Structure Refactoring**: Complete redesign of 70 commands with workflow-oriented naming, trust-building granularity, and automation modes
- **Architecture Decision Records**: Added 5 ADRs (Two-Tier Architecture, Analyst/Engineer Pattern, Product/Platform/API Model, Engineers Own Testing, Skills System)
- **Skills System**: 177 reusable knowledge modules across 28 categories (testing, infrastructure, data, cloud, security, compliance, analytics, business metrics)
- **New Agent Templates**: data-engineer, metabase-engineer, sql-expert, system-architect with comprehensive knowledge bases
- **VCS Provider Configuration**: Auto-detection from git remote with support for GitHub/GitLab/Bitbucket
- **Architecture Documentation**: C4 diagrams, agent interaction patterns, migration plans, skills catalog

### [0.1.5] - 2025-10-15

- **Bug Fixes**: workflow-init now creates agents in correct `.claude/project/agents/` directory
- **Documentation**: Added directory safety best practices to command guidelines
- **publish-issue Update**: Now moves (not deletes) published drafts to `.github/issues/published/`

### [0.1.4] - 2025-10-10

- **23 New Commands**: Quality assurance, security & compliance, operations, infrastructure, data & analytics
- **11 New Agent Templates**: aws-cloud-engineer, datadog-observability-engineer, cost-optimization, data-governance, security-engineer, and 6 more
- **Two-Tier Agent Architecture**: Global agents in `.claude/project/agents/` with project-specific context
- **Command Documentation**: Updated README with all 32 current commands categorized by function
- **Enhanced Workflows**: Added 5 reviewer strategies including GitHub Copilot support
- **Quality Improvements**: Fixed yamllint strict mode for consistency between local and CI validation

See [CHANGELOG.md](docs/CHANGELOG.md) for complete version history.

## Installation Flows

### AIDA-First (Standalone)

**Best for**: Users who want the AI assistant immediately

**What you get**: AIDA framework with personality system

```bash
# Install AIDA
git clone https://github.com/yourusername/claude-personal-assistant.git ~/.aida
cd ~/.aida && ./install.sh

# Choose personality (JARVIS, Alfred, FRIDAY, etc.)
# Creates: ~/.aida/, ~/.claude/, ~/CLAUDE.md

# Optionally add dotfiles later
git clone https://github.com/yourusername/dotfiles.git ~/dotfiles
cd ~/dotfiles && stow */
```

### Dotfiles-First (Recommended)

**Best for**: Users who want shell configs with optional AI enhancement

**What you get**: Shell/git/vim configs + optional AIDA

```bash
# Install dotfiles (includes option for AIDA)
git clone https://github.com/yourusername/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./install.sh

# Prompts:
#   - Install shell configs? [Y/n]
#   - Install git configs? [Y/n]
#   - Install AIDA framework? [Y/n]
#     → If yes: clones AIDA and runs install.sh
#     → If no: shell/git/vim only, add AIDA later

# Creates: shell/git/vim configs
# Optionally: ~/.aida/, ~/.claude/, ~/CLAUDE.md
```

### Install Modes

**Normal Mode** (for users):

```bash
./install.sh
```

- Copies framework files to `~/.aida/`
- Generates `~/.claude/` user configuration
- Creates `~/CLAUDE.md` entry point

**Dev Mode** (for contributors):

```bash
./install.sh --dev
```

- Symlinks `~/.aida/` to development directory
- Enables live editing without reinstall
- For framework development only

## Directory Structure

```text
~/.aida/                    # Framework (installed from this repo)
├── templates/             # Shareable templates
│   ├── knowledge/
│   ├── agents/
│   └── workflows/
├── personalities/         # Pre-built personalities
│   ├── jarvis.yaml
│   ├── alfred.yaml
│   ├── friday.yaml
│   └── zen.yaml
└── install.sh

~/.claude/                 # Your personal config (generated)
├── config/
├── knowledge/
├── memory/
└── agents/

~/CLAUDE.md                # Main entry point (generated)
```

## Personalities

Choose how your assistant behaves:

- **JARVIS** - Snarky British AI (helpful but judgmental)
- **Alfred** - Dignified butler (professional, respectful)
- **FRIDAY** - Enthusiastic helper (upbeat, encouraging)
- **Sage** - Zen guide (calm, mindful)
- **Drill Sergeant** - No-nonsense coach (intense, demanding)

Switch anytime: `aida personality jarvis`

## Features

### Knowledge Management

- System structure documentation
- Procedures and workflows
- Project tracking
- Personal preferences

### Memory System

- Current context tracking
- Decision history
- Activity logs
- Persistent state across conversations

### Agents

- **Secretary** - Daily workflow management
- **File Manager** - Intelligent organization
- **Dev Assistant** - Coding help

### Obsidian Integration

- Daily note templates
- Project tracking
- Dashboard views
- Automatic updates

## Usage

AIDA works through natural conversation with Claude:

```text
You: "What should I focus on today?"
AIDA: "Good morning. Project Alpha is at 80%,
       Project Beta needs attention..."

You: "Clean up my downloads"
AIDA: "Your Downloads folder has 47 files.
       Analyzing... shall I organize them?"

You: "End of day summary"
AIDA: "You completed the API integration, fixed 2 bugs..."
```

## CLI Commands

```bash
aida status        # System status
aida personality   # Manage personality
aida knowledge     # View knowledge base
aida memory        # View memory
aida help          # Show help
```

## For Developers

### Contributing

1. Fork this repository
2. Create a feature branch
3. Make your changes
4. Test with `./install.sh --dev`
5. Run quality checks: `pre-commit run --all-files`
6. Submit a pull request

See [Manual Testing Guide](docs/testing/MANUAL_TESTING.md) for comprehensive QA verification procedures.

### Project Structure

- `templates/` - Shareable configuration templates
- `personalities/` - Pre-built personality definitions
- `install.sh` - Installation script
- `update.sh` - Update script
- `docs/` - Documentation

### Adding a New Personality

1. Create `personalities/your-personality.yaml`
2. Define tone, responses, and behaviors
3. Test with `./install.sh --dev`
4. Submit PR

## Integration with Dotfiles

AIDA works standalone or integrated with dotfiles. Both approaches are supported:

### Standalone AIDA (No Dotfiles)

```bash
# Just install AIDA
git clone https://github.com/you/claude-personal-assistant.git ~/.aida
cd ~/.aida && ./install.sh
# Done! AIDA works without dotfiles
```

### AIDA + Dotfiles Integration

```bash
# Option 1: Install dotfiles (prompts for AIDA)
cd ~/dotfiles && ./install.sh

# Option 2: Install AIDA first, add dotfiles later
cd ~/.aida && ./install.sh
cd ~/dotfiles && stow */  # includes AIDA integration

# Option 3: Add AIDA to existing dotfiles install
cd ~/.aida && ./install.sh  # install AIDA
cd ~/dotfiles && stow aida  # integrate with dotfiles
```

**Smart detection**: Dotfiles automatically detects if `~/.aida/` exists and integrates accordingly.

See [Dotfiles Integration Architecture](docs/architecture/dotfiles-integration.md) for complete details.

## Requirements

- macOS (Linux support coming)
- Git
- Claude AI access (via chat, API, or Claude Code)
- Optional: Obsidian for knowledge management

## Documentation

### User Guides

- [Installation Guide](docs/INSTALLATION.md) - Comprehensive installation instructions, prerequisites, and troubleshooting
- [Requirements Document](docs/requirements.md)
- [Integration Guide](docs/integration.md)

### System Documentation

- [Personality System](docs/personalities.md)
- [Agent System](docs/agents.md)

### Developer Guides

- [Manual Testing Guide](docs/testing/MANUAL_TESTING.md) - QA verification procedures and test scenarios
- [Contributing Guidelines](docs/CONTRIBUTING.md)

## License

MIT License - See LICENSE file

## Links

- Public dotfiles templates: [github.com/you/dotfiles](https://github.com/you/dotfiles)
- Documentation: [Link to docs]
- Issues: [GitHub Issues](https://github.com/you/claude-personal-assistant/issues)

---

**Created with the vision of making Claude a true personal assistant for digital life.**
