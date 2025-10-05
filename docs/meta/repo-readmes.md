---
title: "Repository README Templates"
description: "Complete README templates for AIDA ecosystem repositories"
category: "meta"
tags: ["readme", "templates", "documentation", "repository"]
last_updated: "2025-10-04"
status: "published"
audience: "developers"
---

# Repository READMEs

---

## 1. README.md for `claude-personal-assistant` (Public Framework)

```markdown
# Claude Personal Assistant (AIDA)

**Agentic Intelligence Digital Assistant**

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

```bash
# Clone the framework
git clone https://github.com/yourusername/claude-personal-assistant.git ~/.aida
cd ~/.aida

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

Symlinks `~/.aida/` to your development directory for live editing.

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
git clone https://github.com/you/claude-personal-assistant.git ~/.aida
cd ~/.aida && ./install.sh

# Then stow your dotfiles (if you have them)
cd ~/dotfiles && stow aida
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

---

## 2. README.md for `dotfiles` (Public Templates)

```markdown
# My Dotfiles

Personal configuration files and templates for macOS, featuring AIDA integration (Claude personal assistant system).

## Overview

**This is my PUBLIC DOTFILES repository** - configuration templates and base setups that others can learn from and adapt.

### The Three-Repo System

This is part of my complete development environment:

1. **`claude-personal-assistant`** - Public AIDA framework
   - Core system that powers my AI assistant
   - [github.com/you/claude-personal-assistant](https://github.com/you/claude-personal-assistant)

2. **`dotfiles`** (this repo) - Public configuration templates
   - Base shell configs, git setup, AIDA templates
   - Generic scripts and workflows
   - Safe to share publicly

3. **`dotfiles-private`** - Private configurations
   - My actual secrets and personal configs
   - Overrides these templates
   - Not publicly accessible

## Philosophy

These dotfiles serve as a **base layer** that can be extended with private configurations. Public configs use templates and source private overrides when available.

Managed with **GNU Stow** for clean, organized, symlink-based installation.

## Structure

```text
dotfiles/
├── shell/
│   └── .zshrc              # Sources .zshrc.local for private configs
├── git/
│   └── .gitconfig          # Template with placeholders
├── aida/
│   ├── CLAUDE.md.template  # AIDA configuration template
│   └── .claude/
│       └── knowledge/
│           └── *.template  # Knowledge base templates
├── scripts/
│   └── bin/
│       └──*.sh           # Useful utility scripts
└── vim/
    └── .vimrc             # Vim configuration
```

## Quick Start

```bash
# Clone this repo
git clone https://github.com/you/dotfiles.git ~/dotfiles

# Install with Stow
cd ~/dotfiles
stow */

# Customize the templates
vim ~/.gitconfig  # Add your name/email
vim ~/CLAUDE.md   # Configure AIDA

# Create private overrides
echo "export API_KEY=secret" > ~/.zshrc.local
```

## Installation

### Prerequisites

```bash
# Install Stow
brew install stow

# Install AIDA framework
git clone https://github.com/you/claude-personal-assistant.git ~/.aida
cd ~/.aida && ./install.sh
```

### Install All Packages

```bash
cd ~/dotfiles
stow */
```

### Install Specific Packages

```bash
cd ~/dotfiles
stow shell    # Install shell configs
stow git      # Install git config
stow aida     # Install AIDA templates
stow scripts  # Install utility scripts
```

## Packages

### Shell

- `.zshrc` - Zsh configuration
- Sources `.zshrc.local` for private configurations
- Generic aliases and PATH setup

### Git

- `.gitconfig` - Git configuration template
- `.gitignore_global` - Global gitignore patterns
- Replace placeholders with your information

### AIDA

- `CLAUDE.md.template` - AIDA configuration template
- `.claude/` templates - Knowledge base structure
- Integrates with [claude-personal-assistant](https://github.com/you/claude-personal-assistant)

### Scripts

- `bin/` - Utility scripts
- Generic helpers and tools
- Nothing machine-specific

### Vim

- `.vimrc` - Vim configuration
- Basic setup, extend as needed

## Customization

### Private Overrides

Create a `~/.zshrc.local` file for private configurations:

```bash
# ~/.zshrc.local
export ANTHROPIC_API_KEY="your-key"
export WORK_EMAIL="you@company.com"

alias work='cd ~/Development/work'
```

This file is sourced by `.zshrc` but never committed.

### AIDA Setup

1. Install AIDA framework: `cd ~/.aida && ./install.sh`
2. Copy template: `cp ~/CLAUDE.md.template ~/CLAUDE.md`
3. Customize `~/CLAUDE.md` with your preferences
4. Populate `~/.claude/knowledge/` with your information

### Extending with Private Repo

Create a `dotfiles-private` repository that stows on top:

```bash
# Stow public first
cd ~/dotfiles && stow */

# Stow private second (overrides public)
cd ~/dotfiles-private && stow */
```

## Usage

### Update Configs

```bash
# Edit through symlinks
vim ~/.zshrc          # Edits ~/dotfiles/shell/.zshrc

# Commit changes
cd ~/dotfiles
git add shell/.zshrc
git commit -m "Updated shell config"
git push
```

### Add New Package

```bash
cd ~/dotfiles
mkdir newpackage
# Add files to newpackage/
stow newpackage
git add newpackage/
git commit -m "Added new package"
```

### Remove Package

```bash
cd ~/dotfiles
stow -D vim    # Remove symlinks
rm -rf vim/    # Remove package
```

## New Machine Setup

```bash
# 1. Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Install Stow
brew install stow git

# 3. Clone dotfiles
git clone https://github.com/you/dotfiles.git ~/dotfiles

# 4. Stow everything
cd ~/dotfiles && stow */

# 5. Install AIDA
git clone https://github.com/you/claude-personal-assistant.git ~/.aida
cd ~/.aida && ./install.sh

# 6. Customize
vim ~/.gitconfig  # Add your info
vim ~/CLAUDE.md   # Configure AIDA
```

## AIDA Integration

This dotfiles repo includes templates for AIDA (Claude personal assistant):

- `aida/CLAUDE.md.template` - Main configuration template
- `aida/.claude/` - Knowledge base structure
- Integrates with the [claude-personal-assistant](https://github.com/you/claude-personal-assistant) framework

After stowing, install AIDA and customize the templates.

## Requirements

- macOS (adaptable to Linux)
- GNU Stow
- Git
- Zsh (or adapt to Bash)

## License

MIT License - Feel free to use and adapt!

## Inspiration

- [mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles)
- [holman/dotfiles](https://github.com/holman/dotfiles)
- [paulirish/dotfiles](https://github.com/paulirish/dotfiles)

## Links

- AIDA Framework: [claude-personal-assistant](https://github.com/you/claude-personal-assistant)
- My Blog: [your-blog.com](https://your-blog.com)
- Twitter: [@yourusername](https://twitter.com/yourusername)

---

**These are templates - customize for your own use!**

---

## 3. README.md for `dotfiles-private` (Private Repo)

```markdown
# My Private Dotfiles

Private configurations, secrets, and personal overrides for my dotfiles setup.

## Overview

**This is my PRIVATE DOTFILES repository** - contains actual secrets, API keys, personal configurations, and real AIDA knowledge/memory.

### The Three-Repo System

This is my personal layer in a three-repository ecosystem:

1. **`claude-personal-assistant`** - Public AIDA framework
   - Core system (public)
   - Installed to `~/.aida/`

2. **`dotfiles`** - Public configuration templates
   - Base configs (public)
   - Templates others can use

3. **`dotfiles-private`** (this repo) - Private configurations
   - My actual secrets and configs
   - Overrides public templates
   - Real AIDA memory and knowledge

## ⚠️ Security Note

**This repo contains sensitive information:**
- API keys and tokens
- Personal AIDA configurations
- Work-related configs
- SSH configurations
- Real project information

**Never make this repository public!**

## Structure

```text
dotfiles-private/
├── shell/
│   └── .zshrc.local        # Private shell config (sourced by public .zshrc)
├── git/
│   └── .gitconfig          # Real name, email, signing keys
├── aida/
│   ├── CLAUDE.md           # My actual AIDA config
│   └── .claude/
│       ├── config/
│       │   └── personality.yaml  # My chosen personality (JARVIS)
│       ├── knowledge/
│       │   ├── system.md         # My actual system setup
│       │   ├── procedures.md     # My actual workflows
│       │   └── projects.md       # My real projects
│       ├── memory/
│       │   ├── context.md        # Current state
│       │   └── history/          # Activity logs
│       └── agents/
│           └── *.md              # My customized agents
├── ssh/
│   └── config              # SSH configurations
├── secrets/
│   └── .env                # API keys, tokens
└── work/
    └── company-configs/    # Work-specific stuff
```

## Installation

### Prerequisites

Must have public dotfiles installed first:

```bash
# 1. Install public dotfiles
cd ~/dotfiles && stow */

# 2. Install AIDA framework
cd ~/.aida && ./install.sh

# 3. THEN install private (overrides public)
cd ~/dotfiles-private && stow */
```

### Install All

```bash
cd ~/dotfiles-private
stow */
```

Private configs will override public templates where they conflict.

## What's in Here

### Shell (`.zshrc.local`)

- Environment variables with secrets
- Work-specific aliases
- Company SSH shortcuts
- Private functions

### Git (`.gitconfig`)

- Real name and email
- GPG signing key
- Work-specific configuration
- Private aliases

### AIDA Configuration

- **Personality**: JARVIS (snarky British AI)
- **Knowledge Base**: My actual system, projects, procedures
- **Memory**: Current project states, decisions, history
- **Agents**: Customized secretary, file manager, dev assistant

### Secrets

- Anthropic API key
- GitHub tokens
- AWS credentials
- Work API keys

### SSH

- Personal SSH config
- Jump hosts
- Key paths

## Usage

### Update Configs

```bash
# Edit through symlinks
vim ~/.zshrc.local
vim ~/CLAUDE.md
vim ~/.claude/knowledge/system.md

# Commit changes
cd ~/dotfiles-private
git add .
git commit -m "Updated configurations"
git push
```

### Update AIDA Knowledge

```bash
# Edit knowledge base
vim ~/.claude/knowledge/projects.md

# Commit
cd ~/dotfiles-private
git add aida/.claude/knowledge/
git commit -m "Updated project tracking"
git push
```

### Sync to Another Machine

```bash
# On new machine (after public dotfiles)
git clone git@github.com:you/dotfiles-private.git ~/dotfiles-private
cd ~/dotfiles-private
stow */
```

## AIDA Integration

This repo contains my actual AIDA configuration:

**Personality**: JARVIS (snarky British AI)

**Current Projects** (as of last update):

- [Your actual projects here]

**System**: macOS with custom folder structure

See `aida/.claude/` for complete AIDA knowledge and memory.

## Maintenance

### Before Committing

Always verify no accidental secrets:

```bash
cd ~/dotfiles-private
git status
git diff

# Check for accidentally added secrets
grep -r "sk-ant-" .
grep -r "password" .
```

### .gitignore

Even in private repo, some things shouldn't be tracked:

```gitignore
# Super sensitive
*.key
*.pem
.ssh/id_*
.aws/credentials

# Temporary
*.tmp
*.log
.DS_Store

# Generated
*.swp
*~
```

## Security

- Repository is **private** on GitHub
- Uses SSH key authentication
- Never shared publicly
- Regular security audits

## Backup

This repo is critical - ensure backups:

- GitHub private repo (primary)
- Local Time Machine
- Encrypted external drive (quarterly)

## New Machine Setup

```bash
# 1. Setup SSH keys first
ssh-keygen -t ed25519 -C "your_email@example.com"

# 2. Add key to GitHub
cat ~/.ssh/id_ed25519.pub  # Add to GitHub

# 3. Clone and install public dotfiles
git clone https://github.com/you/dotfiles.git ~/dotfiles
cd ~/dotfiles && stow */

# 4. Install AIDA framework
git clone https://github.com/you/claude-personal-assistant.git ~/.aida
cd ~/.aida && ./install.sh

# 5. Clone and install private dotfiles
git clone git@github.com:you/dotfiles-private.git ~/dotfiles-private
cd ~/dotfiles-private && stow */

# Done!
```

## Links

- Public dotfiles: [github.com/you/dotfiles](https://github.com/you/dotfiles)
- AIDA framework: [github.com/you/claude-personal-assistant](https://github.com/you/claude-personal-assistant)

---

### ⚠️ Keep this repository PRIVATE! ⚠️

---

## Quick Installation Instructions

Save each README to its respective repository:

```bash
# Save to claude-personal-assistant
cat > ~/Development/personal/claude-personal-assistant/README.md << 'EOF'
[paste first README]
EOF

# Save to dotfiles
cat > ~/Development/personal/dotfiles/README.md << 'EOF'
[paste second README]
EOF

# Save to dotfiles-private
cat > ~/Development/personal/dotfiles-private/README.md << 'EOF'
[paste third README]
EOF
```

Then commit each:

```bash
cd ~/Development/personal/claude-personal-assistant
git add README.md && git commit -m "Added comprehensive README"

cd ~/Development/personal/dotfiles
git add README.md && git commit -m "Added comprehensive README"

cd ~/Development/personal/dotfiles-private
git add README.md && git commit -m "Added comprehensive README"
```
