---
title: "Dotfiles Integration Architecture"
description: "How AIDA framework integrates with dotfiles repositories"
category: "architecture"
tags: ["architecture", "dotfiles", "integration", "stow"]
last_updated: "2025-10-05"
status: "published"
audience: "developers"
---

# Dotfiles Integration Architecture

## Overview

The AIDA framework is designed to work with a three-repository ecosystem where dotfiles serve as the entry point and AIDA provides an optional intelligence layer.

## The Three-Repository System

### 1. claude-personal-assistant (this repo)

**Purpose**: Core AIDA framework - personalities, agents, templates

**Installation**: `~/.aida/`

**Standalone**: Yes - can be installed and used without dotfiles

**Provides**:

- Installation script (`install.sh`)
- Personality system (JARVIS, Alfred, FRIDAY, etc.)
- Agent templates (Secretary, File Manager, Dev Assistant)
- Core knowledge base templates
- User configuration generation (`~/.claude/`)

### 2. dotfiles (public)

**Purpose**: Base configuration templates for shell, git, vim, and AIDA integration

**Installation**: `~/dotfiles/` → stowed to `~/`

**Standalone**: Yes - works without AIDA for shell/git/vim configs

**Provides**:

- Shell configurations (`.zshrc`, `.bashrc`)
- Git configurations (`.gitconfig`, `.gitignore_global`)
- Vim/editor configurations
- Utility scripts (`~/bin/`)
- AIDA integration templates (optional stow package)

### 3. dotfiles-private

**Purpose**: Private configurations with secrets and personal customizations

**Installation**: `~/dotfiles-private/` → stowed to `~/` (overlays public)

**Standalone**: No - overlays dotfiles and/or AIDA

**Provides**:

- API keys, credentials, secrets
- Company-specific configurations
- Personal workflow customizations
- Private overrides of public templates

## Installation Flows

### Flow 1: Dotfiles-First (Recommended for Shell Users)

**Use case**: Users who want shell configurations and may add AIDA later

```bash
# Step 1: Clone dotfiles
git clone https://github.com/oakensoul/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Step 2: Run install script (prompts for AIDA)
./install.sh
# Prompts:
#   - Install shell configs? [Y/n] → yes
#   - Install git configs? [Y/n] → yes
#   - Install AIDA framework? [Y/n] → user choice
#     - If yes: clones claude-personal-assistant, runs install.sh
#     - If no: skips AIDA stow package

# Step 3: Customize
vim ~/.gitconfig  # Add your name/email
vim ~/.zshrc.local  # Add private configs

# Step 4 (optional): Add AIDA later
cd ~/.aida && ./install.sh
cd ~/dotfiles && stow aida
```

**Advantages**:

- Natural for shell users
- AIDA is optional enhancement
- Works without AIDA
- Can add AIDA anytime

**Disadvantages**:

- Two-step if adding AIDA later
- Must know to run `stow aida` after AIDA install

### Flow 2: AIDA-First (Current, for AI-First Users)

**Use case**: Users who want AIDA and may add dotfiles later

```bash
# Step 1: Install AIDA framework
git clone https://github.com/oakensoul/claude-personal-assistant.git ~/.aida
cd ~/.aida && ./install.sh
# Prompts for assistant name and personality

# Step 2 (optional): Add dotfiles
git clone https://github.com/oakensoul/dotfiles.git ~/dotfiles
cd ~/dotfiles && stow */

# Step 3: Customize
vim ~/CLAUDE.md  # Configure AIDA
vim ~/.claude/knowledge/  # Add knowledge base
```

**Advantages**:

- Direct path to AIDA features
- Clear what you're getting (AI assistant)
- AIDA works immediately

**Disadvantages**:

- Requires dotfiles knowledge for shell configs
- Two separate installs if wanting both

### Flow 3: Integrated Install (Future)

**Use case**: Users who want complete setup in one command

```bash
# Single command from dotfiles
cd ~/dotfiles && ./install.sh --with-aida

# Or from AIDA
cd ~/.aida && ./install.sh --with-dotfiles
```

**Status**: Planned for v0.3

## Stow Package Structure

### Dotfiles Repository Layout

```text
dotfiles/
├── shell/
│   └── .zshrc              # Standalone shell config
├── git/
│   └── .gitconfig          # Standalone git config
├── vim/
│   └── .vimrc              # Standalone vim config
├── aida/                   # Optional AIDA integration
│   ├── .claude/
│   │   ├── config/
│   │   └── knowledge/
│   └── CLAUDE.md.template
└── scripts/
    └── bin/
        └── aida-*          # AIDA utility scripts (if ~/.aida/ exists)
```

### Smart Stow Detection

The dotfiles install script checks for AIDA before stowing the `aida/` package:

```bash
# In dotfiles/install.sh
if [ -d ~/.aida ]; then
    echo "AIDA framework detected, installing integration..."
    stow aida
else
    echo "AIDA framework not found, skipping AIDA integration"
    echo "To add later: install AIDA, then run 'stow aida'"
fi
```

## Dependency Management

### AIDA Framework (claude-personal-assistant)

**Dependencies**: None

**Optional**: dotfiles for shell integration

**Provides to dotfiles**:

- `~/.aida/` - framework installation
- `~/.claude/` - user configuration

### Dotfiles (public)

**Required dependencies**: None (shell, git, vim work standalone)

**Optional dependencies**: AIDA framework for AI integration

**Checks for AIDA**:

```bash
# Only stow AIDA package if framework exists
[ -d ~/.aida ] && stow aida
```

### Dotfiles-Private

**Required dependencies**: Either dotfiles OR AIDA (or both)

**Overlays**: Both public dotfiles and AIDA configs

## Version Compatibility

### Semantic Versioning Strategy

**Major version compatibility**:

- `dotfiles 0.x.x` works with `AIDA 0.x.x`
- `dotfiles 1.x.x` works with `AIDA 1.x.x`
- Different major versions may have breaking changes

**Minor version flexibility**:

- `dotfiles 0.1.x` works with `AIDA 0.2.x` (forward compatible)
- New features may require matching minor versions
- Documented in changelogs

**Patch version independence**:

- `dotfiles 0.1.2` works with `AIDA 0.1.5` (fully compatible)
- Bug fixes don't affect compatibility

### Compatibility Matrix

| Dotfiles | AIDA | Status | Notes |
|----------|------|--------|-------|
| 0.1.x | 0.1.x | ✅ Tested | Initial release |
| 0.1.x | 0.2.x | ⚠️ Partial | May miss new features |
| 0.2.x | 0.1.x | ⚠️ Partial | May use unsupported features |
| 1.x.x | 0.x.x | ❌ Incompatible | Breaking changes |

## Development Coordination

### Development Order

#### 1. AIDA Framework (this repo)

- Develop core features standalone
- Test installation without dotfiles
- Ensure `~/.aida/` and `~/.claude/` work independently
- Document what dotfiles can integrate with

#### 2. Dotfiles (public)

- Develop shell/git/vim configs standalone
- Test without AIDA installed
- Add AIDA stow package as optional
- Test with AIDA installed

#### 3. Dotfiles-Private

- Develop personal overrides as needed
- Test overlay on top of public dotfiles
- Test overlay with AIDA integration

### Testing Requirements

**Per-repository testing**:

Each repository must test standalone functionality:

```bash
# AIDA framework
cd ~/.aida && ./install.sh
# Verify: ~/.aida/ created, ~/.claude/ configured, works without dotfiles

# Dotfiles (without AIDA)
cd ~/dotfiles && stow shell git vim
# Verify: shell/git/vim work, AIDA package skipped gracefully

# Dotfiles (with AIDA)
cd ~/.aida && ./install.sh
cd ~/dotfiles && stow */
# Verify: AIDA package stowed, integration works
```

**Integration testing**:

Test all installation flows:

1. AIDA only → works
2. Dotfiles only → works
3. AIDA first, then dotfiles → integration works
4. Dotfiles first (with AIDA), then private → layering works
5. Dotfiles first (without AIDA), add AIDA later, stow aida → works

### Breaking Changes

**When AIDA changes break dotfiles**:

1. Bump AIDA major version
2. Update dotfiles compatibility matrix
3. Create migration guide in AIDA repo
4. Update dotfiles to support both versions (if possible)
5. Announce in both repositories

**When dotfiles changes break AIDA integration**:

1. Bump dotfiles major version
2. Update compatibility matrix
3. Create migration guide in dotfiles repo
4. Test AIDA with both old and new dotfiles
5. Announce in both repositories

## Migration Paths

### From Standalone AIDA to Integrated Dotfiles

```bash
# Already have AIDA installed
cd ~/.aida  # verify exists

# Add dotfiles
git clone https://github.com/oakensoul/dotfiles.git ~/dotfiles
cd ~/dotfiles && stow */  # includes AIDA package

# Verify integration
cat ~/CLAUDE.md  # should reference dotfiles configs
```

### From Standalone Dotfiles to AIDA-Enhanced

```bash
# Already have dotfiles
cd ~/dotfiles  # verify exists

# Add AIDA
git clone https://github.com/oakensoul/claude-personal-assistant.git ~/.aida
cd ~/.aida && ./install.sh

# Integrate
cd ~/dotfiles && stow aida

# Verify
ls -la ~/.claude/  # should have AIDA configs
```

### From Separate to Integrated

```bash
# Have both but not integrated
[ -d ~/.aida ] && [ -d ~/dotfiles ]  # both exist

# Just stow the AIDA package
cd ~/dotfiles && stow aida

# Verify integration
echo $AIDA_HOME  # should be set by .zshrc if shell stowed
```

## Architecture Decisions

### Why Optional AIDA?

**Reasoning**:

1. Shell users don't need AI to configure git
2. AIDA is enhancement, not requirement
3. Dotfiles have broader appeal than AI assistants
4. Allows incremental adoption

### Why Three Repositories?

**Reasoning**:

1. **Separation of concerns**:
   - AIDA = AI framework (shareable)
   - dotfiles = configs (shareable)
   - dotfiles-private = secrets (not shareable)

2. **Reusability**:
   - AIDA can be used without dotfiles
   - Dotfiles can be used without AIDA
   - Mix and match as needed

3. **Privacy**:
   - Public templates separate from private data
   - Clear boundary for what's safe to share

### Why Dotfiles-First?

**Reasoning**:

1. **User expectations**: Most users start with dotfiles for shell setup
2. **Natural discovery**: "Oh, there's an AI assistant too? Cool!"
3. **Lower barrier**: Don't force AI on shell users
4. **Incremental value**: Add AIDA when ready

## Future Enhancements

### v0.2 - Smart Detection

- Dotfiles install script detects `~/.aida/`
- Automatic stow of AIDA package if present
- Clear messaging about what's installed

### v0.3 - Integrated Installer

- Single command installs both
- Options for customization during install
- One-command new machine setup

### v1.0 - Update Management

- `aida update` updates both framework and dotfiles
- Version compatibility checking
- Automatic migration for breaking changes

## Related Documentation

- [Installation Guide](../getting-started/installation.md)
- [Development Workflow](../development/workflow.md)
- [Testing Strategy](../testing/strategy.md)
- [Contributing Guidelines](../CONTRIBUTING.md)

---

**Remember**: Both AIDA and dotfiles should work standalone. Integration is a bonus, not a requirement.
