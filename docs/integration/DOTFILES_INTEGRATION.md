---
title: "Dotfiles Integration Guide"
description: "Comprehensive guide for integrating AIDA framework with dotfiles repositories"
category: "integration"
tags: ["integration", "dotfiles", "installation", "architecture"]
last_updated: "2025-10-18"
status: "published"
audience: "developers"
---

# Dotfiles Integration Guide

Complete guide for integrating the AIDA (Agentic Intelligence Digital Assistant) framework with dotfiles repositories, enabling bi-directional integration and shared installation libraries.

## Table of Contents

- [Executive Summary](#executive-summary)
- [Architecture Overview](#architecture-overview)
- [Installation Flows](#installation-flows)
- [Shared Library Integration](#shared-library-integration)
- [Namespace Isolation](#namespace-isolation)
- [Configuration Aggregator](#configuration-aggregator)
- [Development Workflow](#development-workflow)
- [Testing Integration](#testing-integration)
- [Troubleshooting](#troubleshooting)
- [Migration Guide](#migration-guide)

## Executive Summary

### What is Dotfiles Integration?

AIDA framework is designed to work seamlessly with dotfiles repositories through a modular architecture that enables:

- **Bi-directional integration**: Install in any order (AIDA-first or dotfiles-first)
- **Shared installation libraries**: Dotfiles reuse AIDA's installer-common libraries
- **Namespace isolation**: Framework and user content never conflict
- **Consistent user experience**: Same installation patterns across both repos

### Benefits of Integration

**For Users**:

- Single command setup for complete development environment
- Consistent shell/git configurations plus AI assistant
- Safe framework updates that preserve user customizations
- Seamless upgrade path between versions

**For Developers**:

- Reusable installation libraries (no code duplication)
- Consistent configuration management across repos
- Clear separation between framework and user content
- Testable, maintainable installer architecture

### Three-Repository Ecosystem

The AIDA ecosystem consists of three repositories working together:

```text
┌─────────────────────────────────────────────────────────┐
│  1. claude-personal-assistant (AIDA Framework)          │
│     Location: ~/.aida/                                  │
│     Standalone: Yes                                     │
│     Provides: AI assistant, personalities, agents       │
└─────────────────────────────────────────────────────────┘
                           │
                           │ (optional integration)
                           ▼
┌─────────────────────────────────────────────────────────┐
│  2. dotfiles (Public Shell/Git/Vim Configs)             │
│     Location: ~/dotfiles/ → stowed to ~/                │
│     Standalone: Yes                                     │
│     Provides: Shell configs + optional AIDA integration │
└─────────────────────────────────────────────────────────┘
                           │
                           │ (overlays both)
                           ▼
┌─────────────────────────────────────────────────────────┐
│  3. dotfiles-private (Secrets & Personal Overrides)     │
│     Location: ~/dotfiles-private/ → stowed to ~/        │
│     Standalone: No (requires dotfiles or AIDA)          │
│     Provides: API keys, secrets, customizations         │
└─────────────────────────────────────────────────────────┘
```

## Architecture Overview

### Three-Repository System

#### 1. claude-personal-assistant (this repo)

**Purpose**: Core AIDA framework - AI assistant with personalities and agents

**Installation**: `~/.aida/`

**Standalone**: ✅ Yes - works without dotfiles

**Provides**:

- Installation framework (`install.sh`)
- Shared installer libraries (`lib/installer-common/`)
- Configuration aggregator (`lib/aida-config-helper.sh`)
- Personality system (JARVIS, Alfred, FRIDAY, Sage, Drill Sergeant)
- Agent templates (Secretary, File Manager, Dev Assistant)
- Core knowledge base templates
- User configuration generation (`~/.claude/`)

**Dependencies**: None

#### 2. dotfiles (public)

**Purpose**: Base configuration templates for shell, git, vim, and AIDA integration

**Installation**: `~/dotfiles/` → stowed to `~/`

**Standalone**: ✅ Yes - works without AIDA for shell/git/vim configs

**Provides**:

- Shell configurations (`.zshrc`, `.bashrc`)
- Git configurations (`.gitconfig`, `.gitignore_global`)
- Vim/editor configurations
- Utility scripts (`~/bin/`)
- AIDA integration templates (optional stow package)

**Dependencies**: Optional AIDA for AI integration

#### 3. dotfiles-private

**Purpose**: Private configurations with secrets and personal customizations

**Installation**: `~/dotfiles-private/` → stowed to `~/` (overlays public)

**Standalone**: ❌ No - overlays dotfiles and/or AIDA

**Provides**:

- API keys, credentials, secrets
- Company-specific configurations
- Personal workflow customizations
- Private overrides of public templates

**Dependencies**: Either dotfiles OR AIDA (or both)

### Integration Model

The modular architecture enables AIDA and dotfiles to share installation code:

```text
~/.aida/                           # AIDA framework (this repo)
├── lib/
│   ├── installer-common/          # Shared library modules
│   │   ├── colors.sh             # Terminal colors
│   │   ├── logging.sh            # Structured logging
│   │   ├── validation.sh         # Dependency checks
│   │   ├── config.sh             # Config management
│   │   ├── directories.sh        # Directory/symlink management
│   │   ├── templates.sh          # Template installation
│   │   ├── prompts.sh            # User interaction
│   │   ├── deprecation.sh        # Version lifecycle
│   │   └── summary.sh            # Output formatting
│   └── aida-config-helper.sh     # Universal config aggregator
├── templates/                     # AIDA templates
└── install.sh                     # AIDA installer (uses libraries)

~/dotfiles/                        # Public dotfiles repo
├── shell/                         # Shell configurations
├── git/                           # Git configurations
├── .claude/                       # AIDA integration templates
│   ├── commands/                 # Additional workflow commands
│   ├── agents/                   # Project-specific agents
│   └── skills/                   # Enhanced skills
└── install.sh                     # Dotfiles installer
                                   # Sources ~/.aida/lib/installer-common/
```

### Key Architectural Decisions

**ADR-011**: Modular Installer Architecture

- Decomposed 625-line monolithic installer into focused modules
- Enables dotfiles to reuse AIDA installation logic
- 85% reduction in install.sh complexity

**ADR-012**: Universal Config Aggregator Pattern

- Single source of truth for configuration
- 7-tier priority resolution (env vars → project → workflow → git → user → defaults)
- 85%+ I/O reduction via session caching

**ADR-013**: Namespace Isolation for User Content Protection

- Framework content: `~/.claude/commands/.aida/` (replaceable)
- Dotfiles content: `~/.claude/commands/.dotfiles/` (replaceable)
- User content: `~/.claude/commands/` (preserved forever)
- Zero data loss during framework updates

## Installation Flows

### Flow 1: AIDA Standalone (AI-First Users)

**Use case**: Users who want AIDA and may add dotfiles later

```bash
# Step 1: Install AIDA framework
git clone https://github.com/oakensoul/claude-personal-assistant.git ~/.aida
cd ~/.aida
./install.sh
# Prompts:
#   - What would you like to call your AI assistant? [jarvis]
#   - Choose personality: JARVIS (default), Alfred, FRIDAY, Sage, Drill Sergeant

# Step 2 (optional): Add dotfiles later
git clone <dotfiles-repo> ~/dotfiles
cd ~/dotfiles
./install.sh  # Detects ~/.aida/, integrates automatically

# Result:
# - AIDA working immediately
# - Dotfiles integration seamless when added
```

**Advantages**:

- ✅ Direct path to AIDA features
- ✅ Clear what you're getting (AI assistant)
- ✅ AIDA works immediately without dependencies
- ✅ Can add dotfiles anytime

**Disadvantages**:

- ⚠️ Requires dotfiles knowledge for shell configs
- ⚠️ Two separate installs if wanting both

### Flow 2: Dotfiles-First (Recommended Entry Point)

**Use case**: Users who want shell configurations and may add AIDA later

```bash
# Step 1: Clone dotfiles
git clone <dotfiles-repo> ~/dotfiles
cd ~/dotfiles

# Step 2: Run install script (prompts for AIDA)
./install.sh
# Prompts:
#   - Install shell configs? [Y/n] → yes
#   - Install git configs? [Y/n] → yes
#   - Install AIDA framework? [Y/n] → user choice
#     - If yes: clones claude-personal-assistant, runs install.sh
#     - If no: skips AIDA integration, can add later

# Step 3: Customize
vim ~/.gitconfig.local  # Add your name/email
vim ~/.zshrc.local      # Add private configs

# Step 4 (optional): Add AIDA later if skipped
cd ~/.aida && ./install.sh
cd ~/dotfiles && stow aida
```

**Advantages**:

- ✅ Natural for shell users (most developers start here)
- ✅ AIDA is optional enhancement
- ✅ Works without AIDA (shell/git/vim standalone)
- ✅ Can add AIDA anytime
- ✅ Lower barrier to entry

**Disadvantages**:

- ⚠️ Two-step if adding AIDA later
- ⚠️ Must remember to run `stow aida` after AIDA install

### Flow 3: Both Installed, Any Order

**Use case**: Installing both, order doesn't matter

```bash
# Scenario A: AIDA first, then dotfiles
cd ~/.aida && ./install.sh
cd ~/dotfiles && ./install.sh  # Detects ~/.aida/, integrates

# Scenario B: Dotfiles first, then AIDA
cd ~/dotfiles && ./install.sh  # Skips AIDA
cd ~/.aida && ./install.sh
cd ~/dotfiles && stow aida     # Integrate after AIDA installed

# Both work perfectly - order independent!
```

**Advantages**:

- ✅ Flexible installation order
- ✅ Detection is automatic
- ✅ Integration works regardless of sequence

### Flow 4: Full Stack with Private Dotfiles

**Use case**: Complete setup with secrets and customizations

```bash
# Install base layers
cd ~/.aida && ./install.sh
cd ~/dotfiles && ./install.sh

# Overlay private customizations
git clone <dotfiles-private-repo> ~/dotfiles-private
cd ~/dotfiles-private
./install.sh  # Overlays both AIDA and dotfiles

# Result: Three-layer configuration
# 1. AIDA framework (system-level)
# 2. Public dotfiles (shareable configs)
# 3. Private dotfiles (secrets, personal overrides)
```

### Installation Flow Diagram

```text
┌────────────────────────────────────────────────────────────┐
│  User Entry Point                                          │
└────────────────────────────────────────────────────────────┘
                    │
        ┌───────────┴───────────┐
        │                       │
        ▼                       ▼
┌───────────────┐       ┌───────────────┐
│  AIDA First   │       │ Dotfiles First│
└───────────────┘       └───────────────┘
        │                       │
        │ Install AIDA          │ Install Dotfiles
        ▼                       ▼
┌───────────────┐       ┌───────────────┐
│ ~/.aida/      │       │ ~/dotfiles/   │
│ created       │       │ stowed        │
└───────────────┘       └───────────────┘
        │                       │
        │                       │ Prompts for AIDA?
        │                       ├─ Yes ─► Install AIDA
        │                       └─ No ──► Skip
        │                       │
        └───────────┬───────────┘
                    │
                    ▼
        ┌───────────────────────┐
        │  Both Installed       │
        │  Integration Active   │
        └───────────────────────┘
                    │
                    │ (Optional)
                    ▼
        ┌───────────────────────┐
        │  Add Private Dotfiles │
        │  Overlay Secrets      │
        └───────────────────────┘
```

## Shared Library Integration

### How Dotfiles Uses installer-common

Dotfiles repository reuses AIDA's installation libraries for consistent behavior:

```bash
#!/usr/bin/env bash
# ~/dotfiles/install.sh

set -euo pipefail

# Step 1: Check if AIDA installed
AIDA_DIR="${HOME}/.aida"
if [[ ! -d "$AIDA_DIR" ]]; then
    echo "Notice: AIDA framework not found at ${AIDA_DIR}"
    echo "Installing dotfiles without AIDA integration"
    echo "To add AIDA later: https://github.com/oakensoul/claude-personal-assistant"
    AIDA_AVAILABLE=false
else
    AIDA_AVAILABLE=true
fi

# Step 2: If AIDA available, validate version compatibility
if [[ "$AIDA_AVAILABLE" == true ]]; then
    AIDA_VERSION=$(cat "${AIDA_DIR}/VERSION" 2>/dev/null || echo "")
    MIN_AIDA_VERSION="0.2.0"

    # Simple version comparison (major.minor match)
    if [[ "$AIDA_VERSION" < "$MIN_AIDA_VERSION" ]]; then
        echo "Warning: AIDA version $AIDA_VERSION too old (requires >=${MIN_AIDA_VERSION})"
        echo "Upgrade AIDA: cd ~/.aida && git pull && ./install.sh"
        AIDA_AVAILABLE=false
    fi
fi

# Step 3: Source AIDA libraries if available
if [[ "$AIDA_AVAILABLE" == true ]]; then
    INSTALLER_COMMON="${AIDA_DIR}/lib/installer-common"

    # Source libraries in dependency order
    source "${INSTALLER_COMMON}/colors.sh" || exit 1
    source "${INSTALLER_COMMON}/logging.sh" || exit 1
    source "${INSTALLER_COMMON}/validation.sh" || exit 1
    source "${INSTALLER_COMMON}/config.sh" || exit 1
    source "${INSTALLER_COMMON}/directories.sh" || exit 1
    source "${INSTALLER_COMMON}/templates.sh" || exit 1
    source "${INSTALLER_COMMON}/prompts.sh" || exit 1

    print_message "success" "AIDA utilities loaded (v${AIDA_VERSION})"
else
    # Fallback: Basic functions if AIDA not available
    print_message() {
        local type="$1"
        local message="$2"
        echo "[$type] $message"
    }
fi

# Step 4: Install dotfiles using shared utilities
main() {
    if [[ "$AIDA_AVAILABLE" == true ]]; then
        # Use AIDA's template installer with namespace isolation
        install_templates \
            "${PWD}/.claude/commands" \
            "${HOME}/.claude/commands" \
            false \
            .dotfiles  # Namespace for dotfiles content

        print_message "success" "Dotfiles integrated with AIDA"
    else
        # Fallback: Manual installation
        mkdir -p "${HOME}/.claude/commands/.dotfiles"
        cp -r .claude/commands/* "${HOME}/.claude/commands/.dotfiles/"

        print_message "info" "Dotfiles installed (without AIDA integration)"
    fi
}

main "$@"
```

### Available Library Functions

**colors.sh** - Terminal colors and formatting:

```bash
supports_color()              # Check if terminal supports colors
color_red(text)               # Output text in red
color_green(text)             # Output text in green
color_yellow(text)            # Output text in yellow
color_blue(text)              # Output text in blue
```

**logging.sh** - Structured logging:

```bash
init_logging()                # Initialize logging (create log directory)
print_message(type, message)  # Print formatted message (info, success, warning, error)
log_to_file(level, message)   # Write to log file
print_error_with_detail(generic, detailed)  # User-facing + detailed logging
```

**validation.sh** - Dependency checks and security:

```bash
validate_dependencies()       # Check system dependencies
validate_version(version)     # Validate semantic version format
check_version_compatibility(installed, required)  # Semantic version check
validate_path(path, prefix)   # Canonicalize and validate path
validate_file_permissions(file)  # Reject world-writable files
validate_filename(filename)   # Validate filename characters
```

**config.sh** - Configuration management:

```bash
read_config(file)            # Read JSON config file
write_config(file, content)  # Write JSON config file
merge_configs(file1, file2)  # Merge two JSON configs
```

**directories.sh** - Directory and symlink management:

```bash
create_directory(path, mode)           # Create directory with permissions
create_symlink(target, link_name)      # Create symlink safely
remove_broken_symlinks(directory)      # Clean up broken links
backup_directory(source, backup_dir)   # Backup before changes
```

**templates.sh** - Template installation orchestration:

```bash
install_templates(source, dest, dev_mode, namespace)
# Args:
#   source: Template source directory
#   dest: Installation destination
#   dev_mode: true = symlink, false = copy
#   namespace: Subdirectory for namespace isolation (e.g., ".dotfiles")
```

**prompts.sh** - User interaction:

```bash
prompt_yes_no(question, default)        # Yes/no prompt
prompt_choice(question, options)        # Multiple choice
prompt_text(question, default)          # Text input
validate_input(input, pattern)          # Input validation
```

### Library Dependency Tree

```text
install.sh (orchestrator)
├── colors.sh (no dependencies)
├── logging.sh (depends: colors.sh)
├── validation.sh (depends: logging.sh)
├── config.sh (depends: logging.sh, validation.sh)
├── directories.sh (depends: logging.sh, validation.sh)
├── templates.sh (depends: logging.sh, directories.sh)
├── prompts.sh (depends: logging.sh)
├── deprecation.sh (depends: logging.sh, validation.sh)
└── summary.sh (depends: logging.sh)
```

**Source libraries in this order** to satisfy dependencies.

### API Stability Guarantees

**Semantic Versioning for Libraries**:

- **Major version** must match exactly: AIDA 0.x ↔ dotfiles requiring >=0.x
- **Minor version** forward compatible: AIDA 0.2.0 works with dotfiles requiring >=0.1.0
- **Patch version** independent: Any patch versions compatible

**Breaking Changes**:

- Only in major version bumps (0.x → 1.x)
- Migration guide provided
- Backward compatibility maintained within major versions

**Version Checking**:

```bash
# Dotfiles should check AIDA version before sourcing
if check_version_compatibility "$(cat ~/.aida/VERSION)" "0.2.0"; then
    source ~/.aida/lib/installer-common/templates.sh
else
    echo "AIDA version incompatible, using fallback"
fi
```

## Namespace Isolation

### Directory Structure

AIDA uses namespace isolation to prevent data loss during framework updates:

```text
~/.claude/
├── commands/
│   ├── .aida/                    # AIDA framework (replaceable)
│   │   ├── start-work/
│   │   ├── implement/
│   │   ├── open-pr/
│   │   └── cleanup-main/
│   ├── .dotfiles/                # Dotfiles repo (replaceable)
│   │   ├── backup/
│   │   ├── sync/
│   │   └── deploy/
│   ├── .aida-deprecated/         # Deprecated AIDA (optional)
│   │   └── create-issue/
│   └── my-custom-command.md      # User content (preserved)
│
├── agents/
│   ├── .aida/                    # AIDA agents
│   │   ├── secretary/
│   │   ├── file-manager/
│   │   └── dev-assistant/
│   ├── .dotfiles/                # Dotfiles agents
│   │   └── deployment-agent/
│   └── my-custom-agent.md        # User content (preserved)
│
├── skills/
│   ├── .aida/                    # AIDA skills
│   │   ├── bash-expert/
│   │   ├── git-workflow/
│   │   └── aida-config/
│   ├── .dotfiles/                # Dotfiles skills
│   │   └── docker-expert/
│   └── python-expert.md          # User content (preserved)
│
├── config/                       # User config (preserved)
├── memory/                       # User memory (preserved)
└── knowledge/                    # User knowledge (preserved)
```

### Namespace Benefits

**Clear Ownership**:

- `.aida/` = AIDA framework content (owned by AIDA)
- `.dotfiles/` = Dotfiles repo content (owned by dotfiles)
- Parent directory = User content (owned by user)

**Zero Data Loss**:

- Framework updates only touch `.aida/` directory
- Dotfiles updates only touch `.dotfiles/` directory
- User content never touched by installers
- Idempotent: Safe to re-run installers multiple times

**Visual Clarity**:

- Dotfile convention signals "system/framework"
- Easy to see what's replaceable vs preserved
- Clear separation in filesystem

### Installing with Namespace Isolation

**AIDA Installer**:

```bash
# AIDA installs to .aida/ namespace
install_templates \
    "${SCRIPT_DIR}/templates/commands" \
    "${HOME}/.claude/commands" \
    "${DEV_MODE}" \
    .aida  # Namespace subdirectory
```

**Dotfiles Installer**:

```bash
# Dotfiles installs to .dotfiles/ namespace
install_templates \
    "${PWD}/.claude/commands" \
    "${HOME}/.claude/commands" \
    false \
    .dotfiles  # Namespace subdirectory
```

**User Content**:

```bash
# User creates commands in parent directory (NOT in namespaced subdirs)
cat > ~/.claude/commands/my-workflow.md <<EOF
# My Custom Workflow
Custom command for my specific needs
EOF

# Now protected from all framework updates!
```

### Update Safety

**Framework Update** (AIDA or dotfiles):

```bash
# Safe: Nuke and recreate namespace
rm -rf ~/.claude/commands/.aida/        # Delete AIDA content
rm -rf ~/.claude/commands/.dotfiles/    # Delete dotfiles content

# Reinstall from latest
cp -r templates/commands/* ~/.claude/commands/.aida/

# User content untouched
ls ~/.claude/commands/my-workflow.md    # Still exists!
```

## Configuration Aggregator

### Universal Config Helper

The `aida-config-helper.sh` script provides a single source of truth for configuration across the entire AIDA ecosystem.

**Location**: `~/.aida/lib/aida-config-helper.sh`

**Purpose**: Aggregate configuration from 7 sources with clear priority resolution

### 7-Tier Priority Resolution

Configuration sources (highest to lowest priority):

```text
7. Environment variables (GITHUB_TOKEN, EDITOR, AIDA_*, CLAUDE_*)
6. Project AIDA config (.aida/config.json)
5. Workflow config (.github/workflow-config.json)
4. GitHub config (.github/GITHUB_CONFIG.json)
3. Git config (~/.gitconfig, .git/config)
2. User AIDA config (~/.claude/aida-config.json)
1. System defaults (built-in fallbacks)
```

**Example**:

If `GITHUB_TOKEN` is set as environment variable, it overrides all file-based configs.

### Public API

**Get full merged config**:

```bash
CONFIG=$(aida-config-helper.sh)
# Returns: Complete merged JSON to stdout
```

**Get specific value**:

```bash
PROJECT_ROOT=$(aida-config-helper.sh --key paths.project_root)
# Returns: /Users/rob/projects/my-app
```

**Get namespace**:

```bash
GITHUB_CONFIG=$(aida-config-helper.sh --namespace github)
# Returns: All github.* config as JSON
```

**Output format**:

```bash
# YAML instead of JSON
aida-config-helper.sh --format yaml
```

**Disable cache** (for debugging):

```bash
aida-config-helper.sh --no-cache
```

**Validate config**:

```bash
aida-config-helper.sh --validate
# Returns: 0 if valid, 1 if missing required keys
```

### Configuration Example

**Merged Configuration Output**:

```json
{
  "system": {
    "config_version": "1.0"
  },
  "paths": {
    "aida_home": "/Users/rob/.aida",
    "claude_config_dir": "/Users/rob/.claude",
    "project_root": "/Users/rob/projects/my-app"
  },
  "user": {
    "assistant_name": "jarvis",
    "personality": "JARVIS"
  },
  "git": {
    "user": {
      "name": "Rob",
      "email": "rob@example.com"
    }
  },
  "github": {
    "owner": "oakensoul",
    "repo": "claude-personal-assistant",
    "main_branch": "main"
  },
  "workflow": {
    "commit": {
      "auto_commit": true
    },
    "pr": {
      "auto_reviewers": ["teammate1"]
    }
  },
  "env": {
    "github_token": "ghp_xxx",
    "editor": "vim"
  }
}
```

### Session Caching

**Performance Optimization**:

- **First call** (cold cache): ~50-100ms (read + merge all configs)
- **Subsequent calls** (warm cache): ~1-2ms (read cache file)
- **85%+ I/O reduction** compared to reading files directly

**Cache Location**:

```bash
/tmp/aida-config-cache-$$        # Per-shell session
/tmp/aida-config-checksum-$$     # Validation checksum
```

**Cache Invalidation**:

- Automatic when config files modified
- Checksum-based (file modification times)
- Per-shell session (no conflicts)

### Usage in Dotfiles

**Example - Dotfiles Installer**:

```bash
#!/usr/bin/env bash
# ~/dotfiles/install.sh

# Get AIDA configuration
if [[ -x ~/.aida/lib/aida-config-helper.sh ]]; then
    CONFIG=$(~/.aida/lib/aida-config-helper.sh)

    # Extract values
    AIDA_HOME=$(echo "$CONFIG" | jq -r '.paths.aida_home')
    CLAUDE_DIR=$(echo "$CONFIG" | jq -r '.paths.claude_config_dir')
    GIT_USER=$(echo "$CONFIG" | jq -r '.git.user.name')

    echo "Installing dotfiles for user: $GIT_USER"
    echo "AIDA installed at: $AIDA_HOME"
    echo "Claude config at: $CLAUDE_DIR"
fi
```

### Benefits

**Performance**:

- 85%+ reduction in file I/O operations
- Session caching makes repeat calls ~50-98% faster
- Single call gets ALL configuration

**Consistency**:

- All commands see same config with same priority
- No duplicate config reading logic
- Single source of truth

**Debuggability**:

```bash
# View full merged config
aida-config-helper.sh | jq

# Check specific value
aida-config-helper.sh --key github.owner

# Validate configuration
aida-config-helper.sh --validate
```

## Development Workflow

### For AIDA Framework Developers

**Setup Development Environment**:

```bash
cd ~/
git clone https://github.com/oakensoul/claude-personal-assistant.git .aida
cd .aida

# Install in dev mode (creates symlinks for live editing)
./install.sh --dev

# Changes immediately available
```

**Making Changes**:

```bash
cd ~/.aida

# Edit template
vim templates/commands/start-work/README.md

# Changes immediately visible (symlinked in dev mode)
/start-work  # Uses latest version

# Commit when ready
git add templates/commands/start-work/
git commit -m "feat: improve start-work command"
git push
```

**Testing Changes**:

```bash
# Run pre-commit hooks
pre-commit run --all-files

# Validate templates
./scripts/validate-templates.sh --verbose

# Test installation flows
./.github/testing/test-install.sh
```

### For Dotfiles Developers

**Setup Dotfiles Development**:

```bash
cd ~/
git clone <dotfiles-repo> dotfiles
cd dotfiles

# Install in dev mode (symlinks for live editing)
./install.sh --dev
```

**Making Changes**:

```bash
cd ~/dotfiles

# Edit dotfiles template
vim .claude/commands/backup.md

# If AIDA installed, changes symlinked
/backup  # Uses latest version

# Commit when ready
git add .claude/commands/backup.md
git commit -m "feat: add backup command"
git push
```

**Testing Integration with AIDA**:

```bash
# Ensure AIDA installed
test -d ~/.aida && echo "AIDA available"

# Source AIDA libraries
source ~/.aida/lib/installer-common/validation.sh

# Test version compatibility
if check_version_compatibility "$(cat ~/.aida/VERSION)" "0.2.0"; then
    echo "Compatible!"
fi
```

### Dev Mode vs Normal Mode

**Dev Mode** (`--dev` flag):

- Creates symlinks to source templates
- Changes immediately visible
- Perfect for development
- Live editing workflow

```bash
./install.sh --dev

# Templates are symlinked
ls -la ~/.claude/commands/.aida/start-work
# lrwxr-xr-x ... start-work -> ~/.aida/templates/commands/start-work
```

**Normal Mode** (default):

- Copies templates to destination
- Stable deployment
- Templates frozen at install time
- Production use

```bash
./install.sh

# Templates are copied
ls -la ~/.claude/commands/.aida/start-work
# drwxr-xr-x ... start-work/
```

### Coordinating Changes Across Repos

**When AIDA changes affect dotfiles**:

1. Update AIDA repository first
2. Test AIDA changes standalone
3. Create AIDA PR and merge
4. Bump AIDA version
5. Update dotfiles to reference new AIDA version
6. Test dotfiles with new AIDA
7. Create dotfiles PR

**When dotfiles changes need AIDA updates**:

1. Identify AIDA dependency
2. Create AIDA issue/PR first
3. Wait for AIDA version bump
4. Update dotfiles to use new AIDA features
5. Document version requirement

## Testing Integration

### Test All Installation Flows

**Flow 1: AIDA Only (Standalone)**:

```bash
# Clean environment
rm -rf ~/.aida ~/.claude

# Install AIDA
cd ~/.aida && ./install.sh

# Verify
test -d ~/.aida && echo "✓ AIDA installed"
test -d ~/.claude && echo "✓ Config created"
test -d ~/.claude/commands/.aida && echo "✓ Commands installed"
```

**Flow 2: Dotfiles Only (Standalone)**:

```bash
# Clean environment
rm -rf ~/dotfiles ~/.zshrc ~/.gitconfig

# Install dotfiles without AIDA
cd ~/dotfiles && stow shell git vim

# Verify
test -f ~/.zshrc && echo "✓ Shell configured"
test -f ~/.gitconfig && echo "✓ Git configured"
test ! -d ~/.claude/commands/.dotfiles && echo "✓ AIDA integration skipped"
```

**Flow 3: AIDA First, Then Dotfiles**:

```bash
# Install AIDA
cd ~/.aida && ./install.sh

# Verify AIDA
test -d ~/.claude/commands/.aida && echo "✓ AIDA commands"

# Install dotfiles
cd ~/dotfiles && ./install.sh

# Verify integration
test -d ~/.claude/commands/.dotfiles && echo "✓ Dotfiles commands"
test -f ~/.zshrc && echo "✓ Shell configured"
```

**Flow 4: Dotfiles First, Add AIDA Later**:

```bash
# Install dotfiles without AIDA
cd ~/dotfiles && stow shell git vim

# Verify no AIDA integration
test ! -d ~/.claude && echo "✓ No AIDA integration"

# Install AIDA
cd ~/.aida && ./install.sh

# Integrate dotfiles with AIDA
cd ~/dotfiles && stow aida

# Verify full integration
test -d ~/.claude/commands/.aida && echo "✓ AIDA commands"
test -d ~/.claude/commands/.dotfiles && echo "✓ Dotfiles commands"
```

**Flow 5: Full Stack with Private**:

```bash
# Install base layers
cd ~/.aida && ./install.sh
cd ~/dotfiles && ./install.sh

# Overlay private
cd ~/dotfiles-private && ./install.sh

# Verify layers
test -d ~/.claude/commands/.aida && echo "✓ AIDA layer"
test -d ~/.claude/commands/.dotfiles && echo "✓ Dotfiles layer"
grep -q "private-secret" ~/.gitconfig && echo "✓ Private layer"
```

### Test Namespace Isolation

**Verify User Content Protected**:

```bash
# Create user content
echo "custom" > ~/.claude/commands/my-command.md

# Run AIDA installer (should preserve user content)
cd ~/.aida && ./install.sh

# Verify preservation
grep -q "custom" ~/.claude/commands/my-command.md && echo "✓ User content preserved"
```

**Verify Framework Updates Safe**:

```bash
# Modify AIDA template
echo "modified" >> ~/.claude/commands/.aida/start-work/README.md

# Re-run installer (should replace framework content)
cd ~/.aida && ./install.sh

# Verify replacement
! grep -q "modified" ~/.claude/commands/.aida/start-work/README.md && echo "✓ Framework updated"

# Verify user content still there
test -f ~/.claude/commands/my-command.md && echo "✓ User content safe"
```

### Test Library Integration

**Verify Dotfiles Can Use AIDA Libraries**:

```bash
# In dotfiles installer
if [[ -d ~/.aida/lib/installer-common ]]; then
    source ~/.aida/lib/installer-common/colors.sh
    source ~/.aida/lib/installer-common/logging.sh

    print_message "success" "Libraries loaded"
    echo "✓ Dotfiles using AIDA libraries"
fi
```

**Verify Version Compatibility Checking**:

```bash
# In dotfiles installer
source ~/.aida/lib/installer-common/validation.sh

AIDA_VERSION=$(cat ~/.aida/VERSION)
if check_version_compatibility "$AIDA_VERSION" "0.2.0"; then
    echo "✓ Version compatible"
else
    echo "✗ Version incompatible"
fi
```

### Docker-Based Integration Testing

AIDA provides Docker-based testing for cross-platform validation:

```bash
# Test AIDA installation
./.github/testing/test-install.sh

# Test specific environment
./.github/testing/test-install.sh --env ubuntu-22

# Verbose output
./.github/testing/test-install.sh --verbose

# Test all platforms
./.github/testing/test-install.sh --all
```

## Troubleshooting

### Common Issues

#### Issue: Dotfiles Install Can't Find AIDA Libraries

**Error**:

```text
Error: AIDA framework required but not found at /Users/rob/.aida
Install AIDA: https://github.com/oakensoul/claude-personal-assistant
```

**Solution**:

```bash
# Option 1: Install AIDA first
cd ~/
git clone https://github.com/oakensoul/claude-personal-assistant.git .aida
cd .aida
./install.sh

# Then retry dotfiles install
cd ~/dotfiles
./install.sh

# Option 2: Install dotfiles without AIDA integration
cd ~/dotfiles
stow shell git vim  # Skip AIDA package
```

#### Issue: Version Incompatibility

**Error**:

```text
Error: AIDA version 0.1.2 too old (requires >=0.2.0)
Upgrade AIDA: cd ~/.aida && git pull && ./install.sh
```

**Solution**:

```bash
# Upgrade AIDA to latest version
cd ~/.aida
git pull
./install.sh

# Retry dotfiles install
cd ~/dotfiles
./install.sh
```

#### Issue: Templates Overwritten During Update

**Error**: User creates `~/.claude/commands/my-command.md` and it disappears after running installer

**Cause**: User created command inside `.aida/` or `.dotfiles/` namespace

**Solution**:

```bash
# Create user content in parent directory (NOT in namespaced subdirs)
# Wrong:
~/.claude/commands/.aida/my-command.md        # Will be deleted on update

# Correct:
~/.claude/commands/my-command.md              # Safe, preserved forever
```

**Prevention**: Always create user content in parent directory.

#### Issue: Config Values Not Resolving

**Error**: Commands can't find config values, getting empty strings

**Debug**:

```bash
# Test config aggregator
~/.aida/lib/aida-config-helper.sh | jq

# Get specific value with verbose output
~/.aida/lib/aida-config-helper.sh --key paths.aida_home --verbose

# Validate configuration
~/.aida/lib/aida-config-helper.sh --validate

# Check config files exist
ls -la ~/.claude/aida-config.json
ls -la .github/workflow-config.json
ls -la .github/GITHUB_CONFIG.json
```

**Solution**:

- Ensure config files created (run installers)
- Check JSON syntax is valid
- Verify file permissions (should be readable)
- Try `--no-cache` flag to bypass caching

#### Issue: Namespace Directories Not Created

**Error**: Commands installed to wrong location, missing `.aida/` or `.dotfiles/` subdirectory

**Solution**:

```bash
# Manually create namespace directories
mkdir -p ~/.claude/commands/.aida
mkdir -p ~/.claude/commands/.dotfiles
mkdir -p ~/.claude/agents/.aida
mkdir -p ~/.claude/agents/.dotfiles
mkdir -p ~/.claude/skills/.aida
mkdir -p ~/.claude/skills/.dotfiles

# Re-run installer
cd ~/.aida && ./install.sh
```

#### Issue: Broken Symlinks in Dev Mode

**Error**: Commands not found or showing errors in dev mode

**Solution**:

```bash
# Check for broken symlinks
find ~/.claude -type l ! -exec test -e {} \; -print

# Remove broken symlinks
find ~/.claude -type l ! -exec test -e {} \; -delete

# Reinstall in dev mode
cd ~/.aida
./install.sh --dev
```

#### Issue: Libraries Not Sourcing

**Error**: `bash: source: file not found` when dotfiles tries to source AIDA libraries

**Debug**:

```bash
# Verify AIDA library exists
test -d ~/.aida/lib/installer-common && echo "✓ Libraries exist" || echo "✗ Not found"

# List library files
ls -la ~/.aida/lib/installer-common/

# Check permissions
stat ~/.aida/lib/installer-common/colors.sh
```

**Solution**:

```bash
# Ensure AIDA fully installed
cd ~/.aida
./install.sh

# Verify library files readable
chmod +r ~/.aida/lib/installer-common/*.sh
```

### Debug Mode

Enable detailed logging for troubleshooting:

```bash
# Set debug environment variable
export AIDA_DEBUG=1

# Run installer with verbose output
./install.sh --verbose

# Check log files
cat ~/.aida/logs/install.log
tail -n 100 ~/.aida/logs/install.log
```

### Getting Help

**Log File Location**:

```bash
~/.aida/logs/install.log
```

**Check Logs**:

```bash
# View full log
cat ~/.aida/logs/install.log

# Last 50 lines
tail -n 50 ~/.aida/logs/install.log

# Search for errors
grep -i error ~/.aida/logs/install.log
```

**GitHub Issues**:

- AIDA Issues: <https://github.com/oakensoul/claude-personal-assistant/issues>
- Dotfiles Issues: <your-dotfiles-repo>/issues

**Discussion Forums**:

- AIDA Discussions: <https://github.com/oakensoul/claude-personal-assistant/discussions>

## Migration Guide

### From v0.1.x to v0.2.x

The v0.2.0 release introduces namespace isolation and modular installer architecture. Migration is **automatic** but understanding the changes helps.

#### What Changed

**Directory Structure**:

```text
# Before (v0.1.x) - Flat structure
~/.claude/commands/
├── start-work/              # Framework
├── open-pr/                 # Framework
└── my-workflow.md           # User content (at risk!)

# After (v0.2.0) - Namespace isolation
~/.claude/commands/
├── .aida/
│   ├── start-work/          # Framework (replaceable)
│   └── open-pr/             # Framework (replaceable)
└── my-workflow.md           # User content (safe!)
```

**Benefits**:

- User content never overwritten during updates
- Clear separation between framework and user
- Safe, idempotent installer reruns

#### Automatic Migration

The installer automatically detects v0.1.x structure and migrates:

```bash
# Run installer (detects old structure)
cd ~/.aida
./install.sh

# Migration log:
# Migrating to namespace isolation (v0.2.0)...
#
# Framework templates moved to .aida/:
# ✓ commands/start-work → commands/.aida/start-work
# ✓ commands/open-pr → commands/.aida/open-pr
# ✓ agents/secretary → agents/.aida/secretary
#
# User content preserved:
# ✓ commands/my-workflow.md
# ✓ agents/my-agent.md
#
# Migration complete!
```

#### Manual Migration (if needed)

If automatic migration fails:

```bash
# Create namespace directories
mkdir -p ~/.claude/commands/.aida
mkdir -p ~/.claude/agents/.aida
mkdir -p ~/.claude/skills/.aida

# Known framework templates (v0.1.x)
FRAMEWORK_COMMANDS=(start-work implement open-pr cleanup-main)
FRAMEWORK_AGENTS=(secretary file-manager dev-assistant)
FRAMEWORK_SKILLS=(bash-expert git-workflow)

# Move framework commands
for cmd in "${FRAMEWORK_COMMANDS[@]}"; do
    if [[ -d ~/.claude/commands/$cmd ]]; then
        mv ~/.claude/commands/$cmd ~/.claude/commands/.aida/
    fi
done

# Move framework agents
for agent in "${FRAMEWORK_AGENTS[@]}"; do
    if [[ -d ~/.claude/agents/$agent ]]; then
        mv ~/.claude/agents/$agent ~/.claude/agents/.aida/
    fi
done

# Move framework skills
for skill in "${FRAMEWORK_SKILLS[@]}"; do
    if [[ -d ~/.claude/skills/$skill ]]; then
        mv ~/.claude/skills/$skill ~/.claude/skills/.aida/
    fi
done

# User content stays in parent directories (automatically safe)
```

#### Verification After Migration

```bash
# Verify framework templates in namespaces
test -d ~/.claude/commands/.aida/start-work && echo "✓ AIDA commands"
test -d ~/.claude/agents/.aida/secretary && echo "✓ AIDA agents"
test -d ~/.claude/skills/.aida/bash-expert && echo "✓ AIDA skills"

# Verify user content preserved
test -f ~/.claude/commands/my-workflow.md && echo "✓ User commands"
test -f ~/.claude/agents/my-agent.md && echo "✓ User agents"

# Test command discovery
/start-work --help  # Should still work
/my-workflow --help # Should still work
```

#### What to Do After Migration

**Review User Content**:

```bash
# List user content (anything NOT in .aida/ or .dotfiles/)
find ~/.claude/commands -maxdepth 1 -type f -o -type d ! -name ".*"
find ~/.claude/agents -maxdepth 1 -type f -o -type d ! -name ".*"
find ~/.claude/skills -maxdepth 1 -type f -o -type d ! -name ".*"
```

**Create New User Content in Correct Location**:

```bash
# Correct: Parent directory
cat > ~/.claude/commands/my-new-command.md <<EOF
# My New Command
Custom workflow
EOF

# Wrong: Inside namespace (will be deleted on update!)
# ~/.claude/commands/.aida/my-new-command.md  # DON'T DO THIS
```

**Update AIDA Safely**:

```bash
# Now safe to re-run installer anytime
cd ~/.aida
git pull
./install.sh  # User content preserved!
```

### From Standalone AIDA to Integrated Dotfiles

**Current State**: AIDA installed, no dotfiles

**Goal**: Add dotfiles integration

**Steps**:

```bash
# 1. Verify AIDA installed
test -d ~/.aida && echo "✓ AIDA installed"

# 2. Clone dotfiles
git clone <dotfiles-repo> ~/dotfiles
cd ~/dotfiles

# 3. Install dotfiles (will detect AIDA)
./install.sh
# Prompts may ask: "AIDA detected, integrate? [Y/n]"

# 4. Verify integration
test -d ~/.claude/commands/.aida && echo "✓ AIDA commands"
test -d ~/.claude/commands/.dotfiles && echo "✓ Dotfiles commands"
```

### From Standalone Dotfiles to AIDA-Enhanced

**Current State**: Dotfiles installed, no AIDA

**Goal**: Add AIDA integration

**Steps**:

```bash
# 1. Verify dotfiles installed
test -f ~/.zshrc && echo "✓ Dotfiles installed"

# 2. Install AIDA
git clone https://github.com/oakensoul/claude-personal-assistant.git ~/.aida
cd ~/.aida
./install.sh

# 3. Integrate dotfiles with AIDA
cd ~/dotfiles
stow aida  # Stow AIDA integration package

# 4. Verify integration
test -d ~/.claude && echo "✓ AIDA config created"
test -d ~/.claude/commands/.aida && echo "✓ AIDA commands"
test -d ~/.claude/commands/.dotfiles && echo "✓ Dotfiles commands"
```

## Related Documentation

- [Architecture: Dotfiles Integration](../architecture/dotfiles-integration.md) - High-level architecture
- [ADR-011: Modular Installer Architecture](../architecture/decisions/adr-011-modular-installer-architecture.md) - Design decisions
- [ADR-012: Universal Config Aggregator Pattern](../architecture/decisions/adr-012-universal-config-aggregator-pattern.md) - Configuration system
- [ADR-013: Namespace Isolation](../architecture/decisions/adr-013-namespace-isolation-user-content-protection.md) - Safety system
- [Installer-Common Library README](../../lib/installer-common/README.md) - Library API reference
- [Contributing Guidelines](../CONTRIBUTING.md) - Development standards

## Version History

- **v0.2.0** (2025-10-18): Initial dotfiles integration support
  - Modular installer architecture (ADR-011)
  - Universal config aggregator (ADR-012)
  - Namespace isolation (ADR-013)
  - Shared installer-common libraries

---

**Remember**: Both AIDA and dotfiles work standalone. Integration is optional, flexible, and designed for safety.
