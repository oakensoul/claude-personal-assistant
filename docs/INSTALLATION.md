---
title: "AIDA Installation Guide"
description: "Comprehensive installation guide for AIDA framework v0.2.0 with modular architecture, namespace isolation, and upgrade paths"
category: "getting-started"
tags: ["installation", "setup", "configuration", "upgrade"]
last_updated: "2025-10-19"
status: "published"
audience: "users"
version: "0.2.0"
---

# AIDA Installation Guide

Comprehensive installation guide for AIDA (Agentic Intelligence Digital Assistant) framework v0.2.0.

## Table of Contents

- [Introduction](#introduction)
- [What is AIDA?](#what-is-aida)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Installation Modes](#installation-modes)
- [What Gets Installed](#what-gets-installed)
- [Namespace Isolation](#namespace-isolation)
- [Upgrading from v0.1.x](#upgrading-from-v01x)
- [Configuration](#configuration)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)
- [Uninstallation](#uninstallation)
- [Getting Help](#getting-help)
- [Next Steps](#next-steps)

## Introduction

This guide covers everything you need to install and configure AIDA framework v0.2.0. Whether you're a first-time user or upgrading from a previous version, this guide will walk you through the complete installation process.

### Version Information

- **Current Version**: v0.2.0
- **Release Date**: October 2025
- **Major Changes**:
  - Modular installer architecture with reusable components
  - Namespace isolation (`.aida/` subdirectories) prevents user data loss
  - Universal config aggregator for runtime configuration
  - Improved upgrade path from v0.1.x
  - Support for both normal and development modes

## What is AIDA?

AIDA (Agentic Intelligence Digital Assistant) is a conversational, agentic operating system for managing your digital life through Claude AI. It provides:

- **Intelligent Agents**: Pre-built specialized agents (AWS, DevOps, Security, etc.)
- **Workflow Automation**: Slash commands for common development workflows
- **Persistent Memory**: Context retention across conversation sessions
- **Personality System**: Switchable assistant personalities (JARVIS, Alfred, FRIDAY, etc.)
- **Project Integration**: Seamless integration with Git, GitHub, and project workflows

AIDA is designed to be your technical co-pilot, helping you navigate complex development tasks with natural language interaction.

## Prerequisites

Before installing AIDA, ensure your system meets these requirements:

### Operating Systems

- **macOS**: 13.0 (Ventura) or later
- **Linux**:
  - Ubuntu 22.04 LTS or later
  - Debian 12 (Bookworm) or later

### Required Software

- **Bash**: 3.2 or later (pre-installed on macOS/Linux)
- **Git**: 2.0 or later
- **jq**: JSON processor (required for config aggregation)

### Optional Software

- **Docker**: For running installation tests (development only)

### Disk Space

- **Minimum**: 50 MB for framework installation
- **Recommended**: 100 MB including user configuration and memory

### Installation Verification

Verify your system has the required software:

```bash
# Check Bash version
bash --version

# Check Git version
git --version

# Check jq installation
jq --version

# If jq is not installed:
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get update && sudo apt-get install jq
```

## Quick Start

The fastest way to get AIDA up and running:

```bash
# 1. Clone the repository to ~/.aida
git clone https://github.com/oakensoul/claude-personal-assistant ~/.aida

# 2. Navigate to the installation directory
cd ~/.aida

# 3. Run the installer
./install.sh

# 4. Follow the interactive prompts to configure your assistant

# 5. Verify installation
ls -la ~/.aida ~/.claude ~/CLAUDE.md
```

That's it! Your AIDA framework is now installed and ready to use.

## Installation Modes

AIDA supports two installation modes, each designed for different use cases.

### Normal Mode (Default)

**Best for**: Regular users who want a stable installation.

**What it does**:

- Copies framework files to `~/.aida/` (actually creates symlink to repo)
- Creates user configuration in `~/.claude/`
- Installs templates to `~/.claude/{commands,agents,skills}/.aida/`
- Generates main entry point at `~/CLAUDE.md`

**Installation**:

```bash
cd ~/.aida
./install.sh
```

**Characteristics**:

- Framework is symlinked to repository (not copied)
- `git pull` in `~/.aida/` updates framework instantly
- User customizations are isolated and protected
- Safe for production use

### Development Mode

**Best for**: Framework developers and contributors who need to modify core templates.

**What it does**:

- Creates symlink from `~/.aida/` to your repository location
- Enables live editing of framework templates
- Changes to repository immediately affect installation
- Perfect for developing new agents, commands, or skills

**Installation**:

```bash
# Clone to your preferred development location
git clone https://github.com/oakensoul/claude-personal-assistant ~/Development/aida

# Install in development mode
cd ~/Development/aida
./install.sh --dev
```

**Characteristics**:

- Framework directory is symlinked to your development repo
- Edit templates in place and test immediately
- All changes reflect instantly without reinstallation
- Requires keeping repository in permanent location

**Important**: Don't move the repository after installation in dev mode, as it will break the symlinks.

### Choosing the Right Mode

| Use Case | Recommended Mode |
|----------|------------------|
| Using AIDA for daily work | Normal |
| Contributing to AIDA framework | Development |
| Testing framework changes | Development |
| Production use | Normal |
| Learning AIDA internals | Development |

## What Gets Installed

Understanding the directory structure helps you customize and maintain your AIDA installation.

### Directory Structure After Installation

```text
~/.aida/                          # Framework (symlinked to repository)
├── lib/
│   ├── installer-common/         # Shared installer modules
│   │   ├── colors.sh
│   │   ├── config.sh
│   │   ├── directories.sh
│   │   ├── logging.sh
│   │   ├── prompts.sh
│   │   ├── summary.sh
│   │   ├── templates.sh
│   │   └── validation.sh
│   └── aida-config-helper.sh     # Universal config aggregator
├── templates/
│   ├── commands/                 # Workflow command templates
│   │   ├── start-work.md
│   │   ├── open-pr.md
│   │   ├── cleanup-main.md
│   │   └── ...
│   ├── agents/                   # Agent templates
│   │   ├── aws-cloud-engineer/
│   │   ├── datadog-observability-engineer/
│   │   ├── technical-writer/
│   │   └── ...
│   └── skills/                   # Skill templates (future)
├── personalities/                # Personality definitions
│   ├── jarvis.yaml
│   ├── alfred.yaml
│   ├── friday.yaml
│   └── ...
├── install.sh                    # Main installer script
└── VERSION                       # Version identifier

~/.claude/                        # User configuration directory
├── commands/
│   ├── .aida/                    # AIDA commands (framework-managed)
│   │   ├── start-work.md
│   │   ├── open-pr.md
│   │   └── ...
│   └── my-custom-command.md      # Your custom commands
├── agents/
│   ├── .aida/                    # AIDA agents (framework-managed)
│   │   ├── aws-cloud-engineer/
│   │   ├── technical-writer/
│   │   └── ...
│   └── my-custom-agent.md        # Your custom agents
├── skills/
│   ├── .aida/                    # AIDA skills (framework-managed)
│   └── my-skill.md               # Your custom skills
├── knowledge/                    # Knowledge base
│   ├── procedures/
│   ├── workflows/
│   └── reference/
├── memory/                       # Persistent memory
│   └── history/
├── config/                       # Configuration files
└── aida-config.json             # Main configuration file

~/CLAUDE.md                       # Main entry point (personalized)
```

### Framework Components (`~/.aida/`)

The framework directory contains:

- **Installer Library** (`lib/installer-common/`): Modular installation components
- **Config Aggregator** (`lib/aida-config-helper.sh`): Runtime configuration resolver
- **Templates**: Pre-built commands, agents, and skills
- **Personalities**: Assistant personality definitions

**Important**: In AIDA v0.2.0, `~/.aida/` is ALWAYS a symlink to the repository, even in "normal" mode. This allows easy framework updates via `git pull`.

### User Configuration (`~/.claude/`)

Your personal AIDA configuration includes:

- **Commands**: Workflow automation slash commands
- **Agents**: Specialized AI agents for different tasks
- **Skills**: Reusable skills and expertise definitions
- **Knowledge**: Your personal knowledge base
- **Memory**: Conversation history and context
- **Config**: Configuration files and settings

**Important**: Your custom content is NEVER overwritten by framework updates.

### Entry Point (`~/CLAUDE.md`)

The main entry point file that Claude reads when starting conversations. This file is personalized with:

- Your chosen assistant name
- Selected personality
- Version information
- Framework integration

## Namespace Isolation

**Critical Feature**: AIDA v0.2.0 introduces namespace isolation to protect your custom content.

### How Namespace Isolation Works

Framework-provided templates are installed to **`.aida/` subdirectories**:

```text
~/.claude/commands/
├── .aida/                   # Framework commands (managed by AIDA)
│   ├── start-work.md
│   ├── open-pr.md
│   └── cleanup-main.md
└── my-command.md            # Your custom command (NEVER touched)
```

### Protection Guarantees

1. **Framework updates ONLY affect `.aida/` directories**
2. **User content in parent directories is NEVER modified**
3. **Backups are automatic when upgrading**
4. **Clear separation between framework and custom content**

### Example Scenario

```bash
# You create a custom command
~/.claude/commands/my-workflow.md

# AIDA provides a command with same name
~/.claude/commands/.aida/my-workflow.md

# Result: Both coexist safely!
# - AIDA command: ~/.claude/commands/.aida/my-workflow.md
# - Your command: ~/.claude/commands/my-workflow.md
```

Claude will see both commands, and you can choose which one to use.

### Migration from v0.1.x

When upgrading from v0.1.x:

1. **Old templates** are moved to `.aida/` namespace
2. **Your customizations** remain in parent directories
3. **Automatic backup** created at `~/.claude/{type}/.backup.YYYYMMDD-HHMMSS/`
4. **No data loss** - everything is preserved

## Upgrading from v0.1.x

If you're upgrading from AIDA v0.1.x, the process is simple and safe.

### Upgrade Process

```bash
# 1. Navigate to your AIDA installation
cd ~/.aida

# 2. Pull latest changes
git pull

# 3. Run installer (it detects existing installation)
./install.sh

# 4. Follow prompts to migrate to v0.2.0 structure
```

### What Happens During Upgrade

The installer automatically:

1. **Detects existing v0.1.x installation**
2. **Creates backup** of existing configuration
3. **Migrates templates** to `.aida/` namespace
4. **Preserves user customizations** in parent directories
5. **Updates configuration** to v0.2.0 format
6. **Validates migration** was successful

### Backup Location

Automatic backups are created at:

```text
~/.claude/commands/.backup.YYYYMMDD-HHMMSS/
~/.claude/agents/.backup.YYYYMMDD-HHMMSS/
~/.claude/skills/.backup.YYYYMMDD-HHMMSS/
```

**Example**: `~/.claude/commands/.backup.20251019-143022/`

### Rollback

If you need to rollback to v0.1.x:

```bash
# 1. Navigate to AIDA directory
cd ~/.aida

# 2. Checkout previous version
git checkout v0.1.6

# 3. Restore from backup (if needed)
cp -r ~/.claude/commands/.backup.20251019-143022/* ~/.claude/commands/

# 4. Reinstall
./install.sh
```

### Upgrade Checklist

Before upgrading:

- [ ] Commit any local changes to custom commands/agents
- [ ] Note your current personality and assistant name
- [ ] Verify you have recent backups (installer creates them automatically)

After upgrading:

- [ ] Verify namespace directories exist (`.aida/`)
- [ ] Check your custom commands/agents are preserved
- [ ] Test config aggregator: `~/.aida/lib/aida-config-helper.sh --validate`
- [ ] Verify `~/CLAUDE.md` reflects your configuration

## Configuration

AIDA configuration is managed through multiple sources with a clear priority hierarchy.

### Interactive Configuration

During installation, you'll be prompted for:

#### Assistant Name

The name your assistant will use.

- **Requirements**: Lowercase, 3-20 characters, letters/numbers/hyphens only
- **Examples**: `jarvis`, `alfred`, `aida`, `my-assistant`
- **Default**: `jarvis`

```text
Enter assistant name (e.g., 'jarvis', 'alfred'): jarvis
```

#### Personality Selection

Choose your assistant's personality:

| Number | Personality | Description |
|--------|-------------|-------------|
| 1 | jarvis | Snarky British AI (helpful but judgmental) |
| 2 | alfred | Dignified butler (professional, respectful) |
| 3 | friday | Enthusiastic helper (upbeat, encouraging) |
| 4 | sage | Zen guide (calm, mindful) |
| 5 | drill-sergeant | No-nonsense coach (intense, demanding) |

```text
Select personality [1-5]: 1
```

### Configuration File

After installation, configuration is stored in `~/.claude/aida-config.json`:

```json
{
  "version": "0.2.0",
  "install_mode": "normal",
  "paths": {
    "aida_home": "/Users/username/.aida",
    "claude_config_dir": "/Users/username/.claude"
  },
  "user": {
    "assistant_name": "jarvis",
    "personality": "jarvis"
  },
  "system": {
    "installed_at": "2025-10-19T14:30:22Z"
  }
}
```

### Configuration Priority

AIDA uses a 7-tier configuration system (highest to lowest priority):

1. **Environment Variables** (`GITHUB_TOKEN`, `EDITOR`, etc.)
2. **Project AIDA Config** (`.aida/config.json` in current project)
3. **Workflow Config** (`.github/workflow-config.json`)
4. **GitHub Config** (`.github/GITHUB_CONFIG.json`)
5. **Git Config** (`~/.gitconfig`, `.git/config`)
6. **User AIDA Config** (`~/.claude/aida-config.json`)
7. **System Defaults** (built-in)

### Universal Config Aggregator

AIDA v0.2.0 includes a universal config aggregator that merges all configuration sources:

```bash
# Get full merged configuration
~/.aida/lib/aida-config-helper.sh

# Get specific value
~/.aida/lib/aida-config-helper.sh --key paths.aida_home

# Get all GitHub config
~/.aida/lib/aida-config-helper.sh --namespace github

# Validate configuration
~/.aida/lib/aida-config-helper.sh --validate
```

### Editing Configuration

To change your configuration after installation:

```bash
# Edit configuration file
$EDITOR ~/.claude/aida-config.json

# Change assistant name
jq '.user.assistant_name = "alfred"' ~/.claude/aida-config.json > tmp.$$ && mv tmp.$$ ~/.claude/aida-config.json

# Change personality
jq '.user.personality = "friday"' ~/.claude/aida-config.json > tmp.$$ && mv tmp.$$ ~/.claude/aida-config.json

# Validate changes
~/.aida/lib/aida-config-helper.sh --validate
```

## Verification

After installation, verify everything is working correctly.

### Step 1: Check Installation Structure

Verify the directory structure:

```bash
# Check framework directory (should be symlink)
ls -la ~/.aida

# Check user configuration directory
ls -la ~/.claude

# Check entry point file
ls -la ~/CLAUDE.md
```

Expected output:

```text
lrwxr-xr-x  1 user  staff  45 Oct 19 14:30 /Users/user/.aida -> /Users/user/.aida
drwxr-xr-x  8 user  staff  256 Oct 19 14:30 /Users/user/.claude
-rw-r--r--  1 user  staff  3245 Oct 19 14:30 /Users/user/CLAUDE.md
```

### Step 2: Verify Namespace Structure

Check that namespace isolation is working:

```bash
# Check commands namespace
ls -la ~/.claude/commands/.aida/

# Check agents namespace
ls -la ~/.claude/agents/.aida/

# Check skills namespace
ls -la ~/.claude/skills/.aida/
```

You should see framework templates inside `.aida/` directories.

### Step 3: Test Config Aggregator

Validate your configuration:

```bash
# Validate required configuration keys
~/.aida/lib/aida-config-helper.sh --validate
```

Expected output:

```text
Validating configuration...
  paths.aida_home: /Users/user/.aida
  paths.claude_config_dir: /Users/user/.claude
  paths.home: /Users/user
Configuration validation passed
```

### Step 4: Check Version

Verify installed version:

```bash
cat ~/.aida/VERSION
```

Expected output:

```text
0.2.0
```

### Step 5: Verify Entry Point

Check your personalized entry point:

```bash
head -20 ~/CLAUDE.md
```

You should see your assistant name and personality reflected in the file.

### Verification Checklist

- [ ] `~/.aida/` exists and is a symlink to repository
- [ ] `~/.claude/` directory structure created
- [ ] `~/.claude/{commands,agents,skills}/.aida/` namespace directories exist
- [ ] `~/CLAUDE.md` exists and contains your configuration
- [ ] Config aggregator validates successfully
- [ ] VERSION file shows `0.2.0`

## Troubleshooting

Common issues and their solutions.

### Permission Denied

**Problem**: `bash: ./install.sh: Permission denied`

**Solution**:

```bash
# Make installer executable
chmod +x ~/.aida/install.sh

# Run installer
./install.sh
```

### jq Not Found

**Problem**: `Required dependency 'jq' not found`

**Solution**:

```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get update
sudo apt-get install jq

# Verify installation
jq --version
```

### Symlink Issues (Dev Mode)

**Problem**: Symlinks broken after moving repository

**Solution**:

```bash
# Option 1: Reinstall from new location
cd /new/repo/location
./install.sh --dev

# Option 2: Recreate symlinks manually
rm ~/.aida
ln -s /new/repo/location ~/.aida
```

**Prevention**: Don't move repository after installing in dev mode.

### Config Validation Fails

**Problem**: `Configuration validation failed`

**Solution**:

```bash
# Check what's wrong
~/.aida/lib/aida-config-helper.sh --validate

# Verify required files exist
ls -la ~/.claude/aida-config.json

# Regenerate config by reinstalling
cd ~/.aida
./install.sh
```

### Templates Not Appearing

**Problem**: Commands/agents not visible in `~/.claude/`

**Solution**:

```bash
# Check namespace directories exist
ls -la ~/.claude/commands/.aida/
ls -la ~/.claude/agents/.aida/
ls -la ~/.claude/skills/.aida/

# If missing, reinstall
cd ~/.aida
./install.sh

# Verify permissions
chmod -R 755 ~/.claude/
```

### Installation Hangs During Prompts

**Problem**: Installer waits indefinitely for input

**Solution**:

```bash
# Press Ctrl+C to cancel

# Restart with verbose logging
bash -x ~/.aida/install.sh

# If issue persists, check terminal compatibility
echo $TERM
```

### Backup Restore

**Problem**: Need to restore from automatic backup

**Solution**:

```bash
# Find your backup (sorted by timestamp)
ls -lt ~/.claude/commands/.backup.*

# Restore specific backup
cp -r ~/.claude/commands/.backup.20251019-143022/* ~/.claude/commands/

# Verify restoration
ls -la ~/.claude/commands/
```

### Framework Not Updating

**Problem**: `git pull` doesn't update framework

**Solution**:

```bash
# Check if .aida is symlinked correctly
ls -la ~/.aida

# Navigate to actual repository
cd ~/.aida

# Verify git status
git status

# Pull updates
git pull

# If issues persist, check remote
git remote -v
```

### Common Error Messages

| Error | Meaning | Solution |
|-------|---------|----------|
| `PATH is not a symlink` | Path exists but isn't symlink | Backup and remove existing path |
| `Symlink target does not exist` | Broken symlink | Remove symlink and reinstall |
| `Config key not found` | Missing configuration | Regenerate config with `./install.sh` |
| `Invalid JSON in config file` | Corrupted config | Restore from backup or reinstall |
| `Failed to create directory` | Permission issue | Check directory permissions |

## Uninstallation

If you need to remove AIDA, follow these steps to ensure clean removal.

### Important: Backup First

**Before uninstalling**, backup your custom content:

```bash
# Backup your entire Claude configuration
cp -r ~/.claude ~/.claude-backup-$(date +%Y%m%d)

# Or backup just your custom content
mkdir -p ~/aida-backup
cp ~/.claude/commands/my-*.md ~/aida-backup/
cp ~/.claude/agents/my-*.md ~/aida-backup/
```

### Complete Uninstallation

Remove all AIDA components:

```bash
# 1. Remove framework (symlink)
rm ~/.aida

# 2. Remove framework templates (keeps your custom content)
rm -rf ~/.claude/commands/.aida
rm -rf ~/.claude/agents/.aida
rm -rf ~/.claude/skills/.aida

# 3. Optional: Remove all configuration (including your customizations)
rm -rf ~/.claude
rm ~/CLAUDE.md
```

### Partial Uninstallation

Keep your configuration but remove framework:

```bash
# Remove framework only
rm ~/.aida

# Remove framework templates only
rm -rf ~/.claude/commands/.aida
rm -rf ~/.claude/agents/.aida
rm -rf ~/.claude/skills/.aida

# Your custom commands/agents/config remain in ~/.claude/
```

### Uninstallation Checklist

- [ ] Backed up custom commands/agents/skills
- [ ] Backed up configuration (`~/.claude/aida-config.json`)
- [ ] Backed up knowledge base (`~/.claude/knowledge/`)
- [ ] Backed up memory (`~/.claude/memory/`)
- [ ] Removed framework symlink (`~/.aida`)
- [ ] Removed framework templates (`.aida/` directories)
- [ ] Optional: Removed user configuration (`~/.claude/`)
- [ ] Optional: Removed entry point (`~/CLAUDE.md`)

### Reinstallation

To reinstall after uninstallation:

```bash
# Clone fresh copy
git clone https://github.com/oakensoul/claude-personal-assistant ~/.aida

# Install
cd ~/.aida
./install.sh

# Restore your backups (if desired)
cp ~/aida-backup/* ~/.claude/commands/
```

## Getting Help

If you encounter issues or need assistance:

### Documentation

- **Installation Guide**: This document
- **Contributing Guide**: `docs/CONTRIBUTING.md`
- **Architecture Docs**: `docs/architecture/`
- **Integration Guide**: `docs/integration/DOTFILES_INTEGRATION.md`
- **Testing Guide**: `docs/testing/README.md`

### GitHub Repository

- **Issues**: [https://github.com/oakensoul/claude-personal-assistant/issues](https://github.com/oakensoul/claude-personal-assistant/issues)
- **Discussions**: [https://github.com/oakensoul/claude-personal-assistant/discussions](https://github.com/oakensoul/claude-personal-assistant/discussions)
- **Pull Requests**: [https://github.com/oakensoul/claude-personal-assistant/pulls](https://github.com/oakensoul/claude-personal-assistant/pulls)

### Reporting Issues

When reporting issues, include:

1. **System Information**:

   ```bash
   uname -a
   bash --version
   git --version
   jq --version
   ```

2. **Installation Mode**: Normal or dev mode

3. **AIDA Version**:

   ```bash
   cat ~/.aida/VERSION
   ```

4. **Error Messages**: Full error output

5. **Steps to Reproduce**: What you were doing when the error occurred

6. **Configuration** (sanitized):

   ```bash
   ~/.aida/lib/aida-config-helper.sh --validate
   ```

### Community

- **Discord**: (Coming soon)
- **Slack**: (Coming soon)

## Next Steps

Now that AIDA is installed, here's what to do next:

### 1. Review Main Entry Point

Read your personalized entry point:

```bash
cat ~/CLAUDE.md
```

This file is what Claude reads when starting conversations with you.

### 2. Explore Framework Templates

Browse available commands:

```bash
ls -la ~/.claude/commands/.aida/
```

Browse available agents:

```bash
ls -la ~/.claude/agents/.aida/
```

### 3. Customize Configuration

Edit your configuration to match your preferences:

```bash
$EDITOR ~/.claude/aida-config.json
```

### 4. Create Your First Custom Command

Create a simple custom command:

```bash
cat > ~/.claude/commands/hello.md << 'EOF'
---
title: "Hello Command"
description: "Simple test command"
category: "custom"
tags: ["test", "custom"]
last_updated: "2025-10-19"
status: "published"
audience: "users"
---

# Hello Command

This is a test command that demonstrates custom command creation.

When invoked with `/hello`, respond with a friendly greeting.
EOF
```

### 5. Read Contributing Guide

If you want to contribute to AIDA:

```bash
cat docs/CONTRIBUTING.md
```

### 6. Learn About Integration

Understand how AIDA integrates with dotfiles:

```bash
cat docs/integration/DOTFILES_INTEGRATION.md
```

### 7. Try Workflow Commands

Test a workflow command:

- `/start-work` - Begin work on a GitHub issue
- `/open-pr` - Create a pull request
- `/cleanup-main` - Clean up after PR merge

### 8. Explore Agents

Learn about available agents:

- AWS Cloud Engineer: `~/.claude/agents/.aida/aws-cloud-engineer/`
- DataDog Observability: `~/.claude/agents/.aida/datadog-observability-engineer/`
- Technical Writer: `~/.claude/agents/.aida/technical-writer/`

### 9. Build Your Knowledge Base

Start documenting your workflows:

```bash
mkdir -p ~/.claude/knowledge/procedures
mkdir -p ~/.claude/knowledge/reference
```

### 10. Join the Community

- Star the repository on GitHub
- Watch for updates and new features
- Share your experience and feedback
- Contribute back to the project

## Summary

You've successfully installed AIDA! Here's what you now have:

- ✅ **Framework installed** at `~/.aida/`
- ✅ **User configuration** at `~/.claude/`
- ✅ **Entry point** at `~/CLAUDE.md`
- ✅ **Namespace isolation** protecting your customizations
- ✅ **Config aggregator** for runtime configuration
- ✅ **Workflow commands** ready to use
- ✅ **Specialized agents** available
- ✅ **Upgrade path** from v0.1.x

Welcome to the AIDA ecosystem! Start exploring, customizing, and automating your development workflows with your new AI assistant.

For questions, issues, or contributions, visit the [GitHub repository](https://github.com/oakensoul/claude-personal-assistant).
