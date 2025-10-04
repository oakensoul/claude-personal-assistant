# Claude Personal Assistant (AIDE)

**Agentic Intelligence & Digital Environment**

A conversational, agentic operating system for managing digital life through Claude AI. Unlike traditional dotfiles (shell configurations), AIDE provides a natural language interface to manage projects, files, tasks, and daily workflows.

## Overview

**This is the PUBLIC FRAMEWORK** - the core AIDE system that anyone can use.

### The Three-Repo System

This project is part of a three-repository ecosystem:

1. **`claude-personal-assistant`** (this repo) - Public framework
    - Templates, personalities, installation scripts
    - The core AIDE system everyone can use
    - Installed to `~/.aide/`

2. **`dotfiles`** - Public configuration templates
    - Generic shell configs, git setup, AIDE templates
    - Serves as base layer for configurations
    - Managed with GNU Stow

3. **`dotfiles-private`** - Private personal configurations
    - Actual secrets, API keys, personal AIDE configs
    - Overrides public dotfiles
    - Not publicly accessible

## What is AIDE?

AIDE turns Claude into your personal assistant for:
- 📊 Project tracking and workflow management
- 🗂️ Intelligent file organization
- 📝 Daily note-taking and summaries
- 🧠 Persistent memory across conversations
- 🎭 Customizable personalities (JARVIS, Alfred, FRIDAY, etc.)
- 💬 Natural language interface

**Not "dotfiles" - this is a conversational layer on top of your digital life.**

## Quick Start

```bash
# Clone the framework
git clone https://github.com/yourusername/claude-personal-assistant.git ~/.aide
cd ~/.aide

# Install
./install.sh

# Choose your personality (JARVIS, Alfred, FRIDAY, etc.)
# Configure your preferences
# Done!
```

## Installation Options

### Normal Install (For Users)
```bash
./install.sh
```
Creates `~/.claude/` with your personal configuration.

### Dev Mode (For Contributors)
```bash
./install.sh --dev
```
Symlinks `~/.aide/` to your development directory for live editing.

## Directory Structure

```
~/.aide/                    # Framework (installed from this repo)
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

Switch anytime: `aide personality jarvis`

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

AIDE works through natural conversation with Claude:

```
You: "What should I focus on today?"
AIDE: "Good morning. Project Alpha is at 80%, 
       Project Beta needs attention..."

You: "Clean up my downloads"
AIDE: "Your Downloads folder has 47 files. 
       Analyzing... shall I organize them?"

You: "End of day summary"
AIDE: "You completed the API integration, fixed 2 bugs..."
```

## CLI Commands

```bash
aide status        # System status
aide personality   # Manage personality
aide knowledge     # View knowledge base
aide memory        # View memory
aide help          # Show help
```

## For Developers

### Contributing

1. Fork this repository
2. Create a feature branch
3. Make your changes
4. Test with `./install.sh --dev`
5. Submit a pull request

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

This framework is designed to work with dotfiles managed by GNU Stow:

```bash
# Install framework
git clone https://github.com/you/claude-personal-assistant.git ~/.aide
cd ~/.aide && ./install.sh

# Then stow your dotfiles (if you have them)
cd ~/dotfiles && stow aide
```

## Requirements

- macOS (Linux support coming)
- Git
- Claude AI access (via chat, API, or Claude Code)
- Optional: Obsidian for knowledge management

## Documentation

- [Requirements Document](docs/requirements.md)
- [Personality System](docs/personalities.md)
- [Agent System](docs/agents.md)
- [Integration Guide](docs/integration.md)

## License

MIT License - See LICENSE file

## Links

- Public dotfiles templates: [github.com/you/dotfiles](https://github.com/you/dotfiles)
- Documentation: [Link to docs]
- Issues: [GitHub Issues](https://github.com/you/claude-personal-assistant/issues)

---

**Created with the vision of making Claude a true personal assistant for digital life.**