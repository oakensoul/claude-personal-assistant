---
title: "Create user-facing installation and usage documentation"
labels:
  - "type: documentation"
  - "priority: p0"
  - "effort: medium"
  - "milestone: 0.1.0"
---

# Create user-facing installation and usage documentation

## Description

Create comprehensive, user-friendly documentation that helps new users install AIDA, understand how it works, and start using it effectively. This includes installation guides, getting started guides, and basic usage examples.

## Acceptance Criteria

- [ ] File `docs/getting-started/installation.md` created or updated
- [ ] File `docs/getting-started/quick-start.md` created
- [ ] File `docs/getting-started/first-steps.md` created
- [ ] Main `README.md` updated with clear overview and installation
- [ ] Documentation includes:
  - Prerequisites and dependencies
  - Step-by-step installation instructions
  - Platform-specific notes (macOS, Linux, WSL)
  - Troubleshooting common issues
  - First-use walkthrough
  - Basic command examples
  - Screenshots or GIFs (optional but nice)
- [ ] Documentation is clear and accessible to non-technical users
- [ ] All links and references are correct
- [ ] Examples are tested and accurate

## Implementation Notes

### README.md Structure

Update main README with:

```markdown
# AIDA - Agentic Intelligence Digital Assistant

> A conversational, personality-driven AI assistant system powered by Claude AI

AIDA transforms Claude into your personal digital assistant with memory, personality, and specialized knowledge about your system and workflows.

## ✨ Features

- **Personality-Driven**: Choose from 5 personalities (JARVIS, Alfred, FRIDAY, Sage, Drill Sergeant)
- **Persistent Memory**: Context and history across conversations
- **Specialized Agents**: Secretary, File Manager, Dev Assistant
- **Knowledge Base**: Structured documentation of your system
- **Natural Language**: Conversational interface, not command-driven
- **Privacy-First**: All data stays on your machine

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/oakensoul/claude-personal-assistant.git
cd claude-personal-assistant

# Run installation
./install.sh

# Start using AIDA
jarvis status  # or whatever you named your assistant
```text

## 📋 Prerequisites

- macOS, Linux, or Windows WSL
- Bash 4.0 or later
- Git
- Claude AI access (Claude.ai, Claude Desktop, or Claude Code)

## 📖 Documentation

- [Installation Guide](docs/getting-started/installation.md)
- [Quick Start](docs/getting-started/quick-start.md)
- [Architecture](docs/architecture/ARCHITECTURE.md)
- [Roadmap](docs/development/ROADMAP.md)

## 🎭 Personalities

Choose your assistant's communication style:

- **JARVIS** - Snarky, witty, tough-love (like Tony Stark's AI)
- **Alfred** - Professional, dignified, butler-like
- **FRIDAY** - Enthusiastic, friendly, supportive
- **Sage** - Calm, mindful, zen-like
- **Drill Sergeant** - Direct, intense, no-nonsense

## 🤝 Contributing

See [ROADMAP.md](docs/development/ROADMAP.md) for development plans and contribution guidelines.

## 📄 License

MIT License - see [LICENSE](LICENSE)

```

### Installation Guide (`docs/getting-started/installation.md`)

```markdown
# Installation Guide

Complete installation instructions for AIDA framework.

## Prerequisites

### Required
- **Operating System**: macOS (Monterey+), Linux (Ubuntu 20.04+, Debian 11+), or Windows 10+ with WSL2
- **Shell**: Bash 4.0+ or Zsh 5.0+
- **Git**: 2.0+
- **Claude AI**: Access to Claude via chat, desktop app, or Claude Code

### Optional
- **Obsidian**: For daily notes and project tracking integration
- **GNU Stow**: For dotfiles management (Phase 2 feature)

### Verify Prerequisites

```bash
# Check bash version
bash --version  # Should be 4.0+

# Check git
git --version  # Should be 2.0+

# Check shell
echo $SHELL
```text

## Installation Steps

### 1. Clone Repository

```bash
cd ~
git clone https://github.com/oakensoul/claude-personal-assistant.git
cd claude-personal-assistant
```

### 2. Run Installation Script

```bash
./install.sh
```text

### 3. Follow Prompts

The installer will ask:

#### Assistant Name:

- Enter a name for your assistant (lowercase, no spaces)
- Examples: jarvis, alfred, friday
- This becomes your CLI command

#### Personality:

- Choose from 5 personalities:
  1. JARVIS (snarky, witty)
  2. Alfred (professional, dignified)
  3. FRIDAY (enthusiastic, friendly)
  4. Sage (calm, mindful)
  5. Drill Sergeant (direct, intense)

### 4. Verify Installation

```bash
# Check CLI is accessible
jarvis status  # Replace 'jarvis' with your assistant name

# Should show:
# - AIDA version
# - Installation path
# - Personality
# - Health check
```

### 5. Shell Restart (if needed)

If the CLI isn't found:

```bash
# Restart shell or source config
source ~/.bashrc  # For bash
source ~/.zshrc   # For zsh
```

## What Gets Installed

```text
~/.aida/              # Framework installation
~/CLAUDE.md           # Main entry point for Claude
~/.claude/            # Your personal configuration
  ├── config/         # Personality and settings
  ├── knowledge/      # System documentation
  ├── memory/         # Current context and history
  └── agents/         # Specialized agents
~/bin/jarvis          # CLI tool (or your chosen name)
```

## Development Mode

For contributors:

```bash
./install.sh --dev
```

This symlinks `~/.aida/` to the repository for live editing.

## Platform-Specific Notes

### macOS

- Default shell is zsh (macOS 10.15+)
- Uses `~/.zshrc` for configuration
- Homebrew optional but recommended

### Linux (Ubuntu/Debian)

- Default shell is bash
- Uses `~/.bashrc` for configuration
- May need to install git: `sudo apt install git`

### Windows (WSL)

- Install WSL2 first: <https://learn.microsoft.com/en-us/windows/wsl/install>
- Recommended: Ubuntu 22.04 from Microsoft Store
- Follow Linux instructions once in WSL

## Troubleshooting

### "Command not found: jarvis"

**Cause**: CLI not in PATH

**Solution**:

```bash
# Check if ~/bin exists
ls ~/bin/jarvis

# If it exists, add to PATH manually
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```text

### "Permission denied"

**Cause**: CLI not executable

**Solution**:

```bash
chmod +x ~/bin/jarvis
```

### "Template variables not replaced"

**Cause**: Installation issue

**Solution**:

```bash
# Re-run installation
./install.sh
```text

### "YAML parsing error"

**Cause**: Corrupted personality file

**Solution**:

```bash
# Re-install personality
cp ~/.aida/personalities/jarvis.yaml ~/.claude/config/personality.yaml
```

## Next Steps

See [Quick Start Guide](quick-start.md) for first steps after installation.

```text

### Quick Start Guide (`docs/getting-started/quick-start.md`)

```markdown
# Quick Start Guide

Get started with AIDA after installation.

## First Conversation

### With Claude Chat (claude.ai)

1. Start new conversation
2. Copy content of `~/CLAUDE.md`
3. Paste into Claude
4. Say: "jarvis start day" (use your assistant's name)

### With Claude Desktop

1. Install MCP servers (recommended):
   - Filesystem server
   - Git server
   - Memory server

2. Open Claude Desktop
3. Say: "Read ~/CLAUDE.md and introduce yourself"
4. Say: "jarvis start day"

### With Claude Code

1. Open VS Code
2. Install Claude Code extension
3. Open your project
4. Say: "jarvis start day"

## Basic Commands

### Morning Routine
```

jarvis start day

```text

Claude will:
- Review your active projects
- Check for pending items
- Suggest today's priorities
- Create daily note

### Check Status
```

jarvis status

```text

Shows quick system overview.

### End of Day
```

jarvis end day

```text

Claude will:
- Review accomplishments
- Update project statuses
- Log activity
- Wrap up

### Clean Downloads
```

jarvis cleanup downloads

```text

Claude will:
- Scan Downloads folder
- Categorize files
- Suggest destinations
- Organize with confirmation

## Customize Your Setup

### Edit Knowledge Base

Customize system documentation:

```bash
# How your system is organized
$EDITOR ~/.claude/knowledge/system.md

# Your workflows and routines
$EDITOR ~/.claude/knowledge/workflows.md

# Your preferences
$EDITOR ~/.claude/knowledge/preferences.md
```

### Customize Agents

Personalize agent behaviors:

```bash
# Secretary agent (daily workflow)
$EDITOR ~/.claude/agents/secretary.md

# File manager agent
$EDITOR ~/.claude/agents/file-manager.md

# Dev assistant agent
$EDITOR ~/.claude/agents/dev-assistant.md
```text

## Obsidian Integration (Optional)

### Setup

1. Create Obsidian vault at `~/Knowledge/Obsidian-Vault/`
2. Tell Claude the vault location
3. Run `jarvis start day` - daily note will be created

### Structure

```

~/Knowledge/Obsidian-Vault/
├── Daily/           # Daily notes (auto-created)
├── Projects/        # Project tracking
└── Index/           # Overview and dashboards

```text

## Tips

1. **Be conversational**: AIDA understands natural language
2. **Update memory**: Tell Claude about important decisions
3. **Use agents**: Mention tasks to invoke specialized agents
4. **Customize knowledge**: Make it yours - edit templates
5. **Check context**: Claude reads memory/context.md before responding

## Common Workflows

### Starting a New Project

```text
I'm starting a new project called "awesome-app".
It's a React web application for [purpose].
Can you help me track this?
```

### Daily Planning

```text
jarvis start day
[Review suggestions]
Actually, I need to prioritize the design work today.
Can you update my plan?
```

### Organizing Files

```text
My Downloads folder is a mess. Can you help organize it?
[Claude shows categorization]
Yes, proceed with those suggestions.
```

## Next Steps

- Read [Architecture](../architecture/ARCHITECTURE.md) to understand how AIDA works
- Explore [Roadmap](../development/ROADMAP.md) for upcoming features
- Join discussions for questions and feedback

```text

## Dependencies

- #001-#011 (Installation and templates must work)
- #012 (Testing validates documentation accuracy)

## Related Issues

None

## Definition of Done

- [ ] All documentation files created or updated
- [ ] README.md is clear and compelling
- [ ] Installation guide is comprehensive
- [ ] Quick start guide is easy to follow
- [ ] All examples are tested and accurate
- [ ] Troubleshooting covers common issues
- [ ] Links and references all work
- [ ] Documentation reviewed for clarity
- [ ] Suitable for MVP release
