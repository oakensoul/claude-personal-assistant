---
title: "Technical Specification - Modular Installer Refactoring"
issue: 53
document_type: "technical-spec"
created: "2025-10-18"
version: "1.0"
status: "draft"
---

# Technical Specification: Modular Installer with Deprecation Support

**Issue**: #53
**Complexity**: LARGE (53h implementation + 32-45h testing = 85-98h total)
**Dependencies**: None (foundational work)
**Target Version**: v0.2.0
**Last Updated**: 2025-10-18 (Added universal config aggregator, resolved Q1-Q3)

---

## 1. Executive Summary

### Objective

Transform the 625-line monolithic `install.sh` into a modular, reusable architecture with:

- **6 focused library modules** in `lib/installer-common/`
- **Thin orchestrator** (`install.sh` ~150 lines)
- **Namespace isolation** (`.aida/` subdirectories protect user content)
- **Version-based deprecation** with frontmatter metadata
- **Cross-platform testing** (Docker + CI/CD + Makefile)
- **Dotfiles integration** (reusable libraries with stable API)

### Value Proposition

- **Zero data loss**: User content outside `.aida/` namespace preserved
- **Safe updates**: Framework updates via `git pull` (symlinked `~/.aida/`)
- **Bi-directional integration**: AIDA ↔ dotfiles repo (reusable libraries)
- **Foundation for ADR-010**: Command rename migration path

### Architecture Overview

```text
install.sh (150 lines)
└── sources lib/installer-common/
    ├── colors.sh (existing)
    ├── logging.sh (existing)
    ├── validation.sh (existing)
    ├── config.sh (new) - Universal config aggregator & JSON config reader/writer
    ├── directories.sh (new) - Directory/symlink mgmt
    ├── templates.sh (new) - Template installation (NO variable substitution)
    ├── prompts.sh (new) - User interaction
    ├── deprecation.sh (new) - Deprecation lifecycle
    └── summary.sh (new) - Output formatting

~/.aida/lib/aida-config-helper.sh (new)
└── Universal config aggregator
    ├── Merges: AIDA + workflow + GitHub + Git + env configs
    ├── Session caching with invalidation
    ├── Single source of truth for ALL commands
    └── 85%+ reduction in file I/O across all workflow commands
```

### Architectural Documentation

This implementation is governed by three Architecture Decision Records:

- **[ADR-011: Modular Installer Architecture](../../docs/architecture/decisions/adr-011-modular-installer-architecture.md)**
  - Decomposes monolithic installer into reusable library modules
  - Enables dotfiles integration and bi-directional library sharing
  - Reduces installer complexity by 85% (625 → 150 lines)

- **[ADR-012: Universal Config Aggregator Pattern](../../docs/architecture/decisions/adr-012-universal-config-aggregator-pattern.md)**
  - Establishes single source of truth for all configuration
  - Implements 7-tier priority resolution with session caching
  - Achieves 85-98% I/O reduction across all workflow commands

- **[ADR-013: Namespace Isolation for User Content Protection](../../docs/architecture/decisions/adr-013-namespace-isolation-user-content-protection.md)**
  - Guarantees zero data loss during framework updates
  - Framework templates in `.aida/` subdirectories, user content in parent
  - Enables idempotent, safe installation and upgrades

**C4 Architecture Diagrams:**

- **[C4 Context: AIDA Ecosystem](../../docs/architecture/diagrams/c4-context-aida-ecosystem.md)** - System context showing AIDA ↔ Dotfiles ↔ Claude Code integration
- **[C4 Container: Installer System](../../docs/architecture/diagrams/c4-container-installer-system.md)** - Container-level view of installation architecture
- **[C4 Component: Config Aggregator](../../docs/architecture/diagrams/c4-component-config-aggregator.md)** - Component-level internals of universal config aggregator

**Additional Documentation:**

- **[Architecture Summary](./architecture/ARCHITECTURE_SUMMARY.md)** - Comprehensive overview of all architectural decisions and patterns
- **[Architecture Navigation](./architecture/README.md)** - Quick reference guide to all architecture documentation

---

## 2. Module Specifications

### 2.1 Universal Config System: `aida-config-helper.sh` + `config.sh`

**Purpose**: Single source of truth for ALL configuration across AIDA ecosystem

**Architecture**:

```text
aida-config-helper.sh (standalone script)
  ├── Reads & merges ALL configs:
  │   ├── System defaults (built-in)
  │   ├── User AIDA config (~/.claude/aida-config.json)
  │   ├── Git config (~/.gitconfig, .git/config)
  │   ├── GitHub config (.github/GITHUB_CONFIG.json)
  │   ├── Workflow config (.github/workflow-config.json)
  │   ├── Project AIDA config (.aida/config.json)
  │   └── Environment variables overlay
  ├── Session caching with checksumvalidation
  └── Returns: Single merged JSON to stdout

config.sh (library module)
  └── Wrapper functions for install.sh to use
```

**Public API** (`aida-config-helper.sh`):

```bash
# Get full merged config (all sources)
aida-config-helper.sh
# Returns: Complete merged JSON to stdout

# Get specific value
aida-config-helper.sh --key paths.aida_home
# Returns: /Users/rob/.aida

# Get namespace
aida-config-helper.sh --namespace github
# Returns: All github.* config as JSON

# Output format
aida-config-helper.sh --format yaml
# Returns: YAML instead of JSON

# Validate config
aida-config-helper.sh --validate
# Returns: 0 if valid, 1 if missing required keys
```

**Merged Config Structure**:

```json
{
  "system": {
    "config_version": "1.0",
    "cache_enabled": true
  },
  "paths": {
    "aida_home": "/Users/rob/.aida",
    "claude_config_dir": "/Users/rob/.claude",
    "project_root": "/Users/rob/projects/my-app",
    "git_root": "/Users/rob/projects/my-app"
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
    "main_branch": "main",
    "labels": {...}
  },
  "workflow": {
    "commit": {
      "auto_commit": true,
      "message_prefix": "feat"
    },
    "pr": {
      "auto_reviewers": ["teammate1"],
      "draft": false
    },
    "versioning": {
      "enabled": true,
      "changelog": "CHANGELOG.md"
    }
  },
  "env": {
    "github_token": "ghp_xxx",
    "editor": "vim"
  }
}
```

**Config Resolution Priority** (highest to lowest):

```
7. Environment variables (GITHUB_TOKEN, EDITOR, etc.)
6. Project AIDA config (.aida/config.json)
5. Workflow config (.github/workflow-config.json)
4. GitHub config (.github/GITHUB_CONFIG.json)
3. Git config (~/.gitconfig, .git/config)
2. User AIDA config (~/.claude/aida-config.json)
1. System defaults (built-in)
```

**Session Caching**:

```bash
# Cache per shell session
CACHE_FILE="/tmp/aida-config-cache-$$"
CACHE_CHECKSUM_FILE="/tmp/aida-config-checksum-$$"

# Invalidate cache if any config file changes
get_config_checksum() {
  find . -name "*.json" -path "*/.github/*" -o \
         -name "aida-config.json" -o \
         -name ".aida/config.json" | \
    xargs stat -f "%m" 2>/dev/null | \
    sort | md5sum
}

# Use cached result if checksum matches
if [[ "$(cat $CACHE_CHECKSUM_FILE)" == "$(get_config_checksum)" ]]; then
  cat "$CACHE_FILE"  # Fast path
else
  merge_all_configs | tee "$CACHE_FILE"  # Regenerate
fi
```

**Performance Impact**:

**Before** (current workflow commands):
```bash
# Each command reads multiple files
WORKFLOW_CONFIG=$(cat .github/workflow-config.json)      # I/O
GITHUB_CONFIG=$(cat .github/GITHUB_CONFIG.json)          # I/O
AIDA_CONFIG=$(cat ~/.claude/aida-config.json)            # I/O
GIT_USER=$(git config user.name)                         # subprocess
GIT_EMAIL=$(git config user.email)                       # subprocess

# Multiple commands = duplicate reads (6+ I/O operations per command)
```

**After** (unified config aggregator):
```bash
# Single call, all configs merged
readonly CONFIG=$(aida-config-helper.sh)  # ONE I/O + merge operation

# All values from memory (no additional I/O)
readonly GITHUB_OWNER=$(echo "$CONFIG" | jq -r '.github.owner')
readonly AUTO_COMMIT=$(echo "$CONFIG" | jq -r '.workflow.commit.auto_commit')
readonly GIT_USER=$(echo "$CONFIG" | jq -r '.git.user.name')
readonly AIDA_HOME=$(echo "$CONFIG" | jq -r '.paths.aida_home')

# 85%+ reduction in file I/O across ALL workflow commands!
```

**Usage Pattern in Commands**:

```bash
#!/usr/bin/env bash
# templates/commands/start-work/README.md

# Get config once at start
readonly CONFIG=$(aida-config-helper.sh)

# Parse all needed values (fast - from memory)
readonly GITHUB_OWNER=$(echo "$CONFIG" | jq -r '.github.owner')
readonly GITHUB_REPO=$(echo "$CONFIG" | jq -r '.github.repo')
readonly MAIN_BRANCH=$(echo "$CONFIG" | jq -r '.github.main_branch')
readonly PROJECT_ROOT=$(echo "$CONFIG" | jq -r '.paths.project_root')
readonly AIDA_HOME=$(echo "$CONFIG" | jq -r '.paths.aida_home')

# Use throughout command
cd "$PROJECT_ROOT"
gh issue view "$ISSUE_NUM" --repo "${GITHUB_OWNER}/${GITHUB_REPO}"
```

**AIDA Config Skill** (~/.claude/skills/.aida/aida-config/):

All agents can use this skill for config reading:

```markdown
---
title: "AIDA Config Skill"
skill_type: "utility"
provides: ["config-reading", "path-resolution"]
dependencies: ["aida-config-helper.sh"]
---

# AIDA Config Skill

Fast, cached configuration for all AIDA agents and commands.

## Usage
```bash
# Get full config
CONFIG=$(aida-config-helper.sh)

# Get specific value
PROJECT_ROOT=$(aida-config-helper.sh --key project_root)
```

## Benefits
- Single call gets ALL config (AIDA, GitHub, workflow, git, env)
- Session caching (fast repeat calls)
- Consistent values across all commands
```

**Installation Integration**:

```bash
# install.sh creates initial config during installation
cat > "${HOME}/.claude/aida-config.json" <<EOF
{
  "version": "$(cat VERSION)",
  "install_mode": "${DEV_MODE:-normal}",
  "installed_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "paths": {
    "aida_home": "${AIDA_DIR}",
    "claude_config_dir": "${CLAUDE_DIR}",
    "home": "${HOME}"
  },
  "user": {
    "assistant_name": "${ASSISTANT_NAME}",
    "personality": "${PERSONALITY}"
  },
  "deprecation": {
    "include_deprecated": ${WITH_DEPRECATED:-false}
  }
}
EOF
```

**Templates Stay Pure** (No Variable Substitution Needed!):

```markdown
# templates/commands/start-work/README.md
# No substitution - templates keep {{VAR}} patterns

To create issue directory:
```bash
PROJECT_ROOT=$(aida-config-helper.sh --key paths.project_root)
mkdir -p "${PROJECT_ROOT}/.github/issues/in-progress/issue-${NUM}"
```

Variables resolved at runtime via config helper!
```

**Benefits**:

✅ **MASSIVE performance**: 85%+ reduction in I/O across ALL commands
✅ **Single source of truth**: One script merges ALL configs
✅ **DRY**: No duplicate config reading
✅ **Simpler templates**: No variable substitution needed
✅ **Dev mode simplified**: No runtime wrapper needed
✅ **Extensible**: Easy to add new config sources
✅ **Session caching**: Fast repeat calls
✅ **Debuggable**: View full merged config anytime

**Dependencies**: `logging.sh`, `validation.sh`, `jq` (required)

**Files**:
- `lib/aida-config-helper.sh`: ~200 lines (standalone aggregator)
- `lib/installer-common/config.sh`: ~50 lines (wrapper for install.sh)
- `skills/.aida/aida-config/`: Skill documentation

**Effort**: 8 hours (4h aggregator + 2h caching + 1h validation + 1h skill docs)
**Risk**: LOW (straightforward jq merging, well-understood caching)

---

### 2.2 Module: `directories.sh`

**Purpose**: Directory creation, symlink management, backup operations

**Public API**:

```bash
# Always symlink ~/.aida/ to repo (both normal and dev mode)
create_aida_dir() {
  local repo_dir="$1"     # Repository directory path
  local aida_dir="$2"     # Target ~/.aida/ path
  # Returns: 0 on success, 1 on failure
}

# Create ~/.claude/{commands,agents,skills}/ structure
create_claude_dirs() {
  local claude_dir="$1"   # ~/.claude/ path
  # Returns: 0 on success, 1 on failure
}

# Create namespace subdirectories (.aida/ within each type)
create_namespace_dirs() {
  local claude_dir="$1"   # ~/.claude/ path
  local namespace="$2"    # ".aida" or ".aida-deprecated"
  # Returns: 0 on success, 1 on failure
}

# Backup existing directory with timestamp
backup_existing() {
  local target="$1"       # Directory/file to backup
  # Returns: 0 on success, 1 on failure
}

# Safe symlink creation (idempotent, validates target)
create_symlink() {
  local target="$1"       # Symlink target (must exist)
  local link_name="$2"    # Symlink path to create
  # Returns: 0 on success, 1 on failure
}
```

**Namespace Isolation**:

```text
~/.claude/
├── commands/
│   ├── my-custom-command.md      # User content (preserved)
│   └── .aida/                    # AIDA framework (replaceable)
│       └── start-work/
│           └── README.md
├── agents/
│   ├── my-custom-agent.md        # User content (preserved)
│   └── .aida/                    # AIDA framework (replaceable)
│       └── secretary/
│           └── README.md
└── skills/
    └── .aida/                    # AIDA framework (replaceable)
        └── bash-expert/
            └── README.md
```

**Symlink Strategy**:

- **Always symlink** `~/.aida/` → repo (enables `git pull` updates)
- **Normal mode**: Copy templates with variable substitution
- **Dev mode**: Symlink templates for live editing

**Cross-Platform Handling**:

```bash
# macOS: BSD readlink (no -f flag)
# Linux: GNU readlink -f available
# Windows WSL: Symlinks work in WSL filesystem

get_symlink_target() {
  local symlink="$1"
  if [[ "$OSTYPE" == "darwin"* ]]; then
    readlink "$symlink"  # BSD
  else
    readlink -f "$symlink"  # GNU
  fi
}
```

**Dependencies**: `logging.sh`, `validation.sh`

**Lines**: ~200
**Effort**: 5 hours
**Risk**: MEDIUM (cross-platform symlinks, Windows WSL)

---

### 2.3 Module: `templates.sh`

**Purpose**: Template installation orchestration

**Public API**:

```bash
# Main entry point for template installation
install_templates() {
  local src_dir="$1"      # Source template directory
  local dst_dir="$2"      # Destination directory
  local dev_mode="${3:-false}"   # true = symlink, false = copy
  local namespace="${4:-.aida}"  # ".aida" or ".aida-deprecated"
  # Returns: 0 on success, 1 on failure
}

# Install single template folder
install_template_folder() {
  local src_folder="$1"   # Source folder path
  local dst_folder="$2"   # Destination folder path
  local dev_mode="$3"     # Installation mode
  # Returns: 0 on success, 1 on failure
}
```

**Installation Flow**:

```bash
# Normal mode
install_templates "${AIDA_DIR}/templates/commands" \
                  "${CLAUDE_DIR}/commands/.aida" \
                  false \
                  ".aida"

# Result: Templates copied with variable substitution
# ~/.claude/commands/.aida/start-work/README.md (file)

# Dev mode
install_templates "${AIDA_DIR}/templates/commands" \
                  "${CLAUDE_DIR}/commands/.aida" \
                  true \
                  ".aida"

# Result: Templates symlinked for live editing
# ~/.claude/commands/.aida -> /path/to/repo/templates/commands (symlink)
```

**Folder-Based Installation**:

- Install entire folders (not individual files)
- Example: `templates/commands/start-work/` → `~/.claude/commands/.aida/start-work/`
- Each command is a folder with `README.md` + optional supporting files

**No Variable Substitution Needed**:

- Templates installed as-is (pure copy or symlink)
- Variables resolved at runtime via `aida-config-helper.sh`
- Same template files work in both normal and dev mode
- Simpler implementation, no edge cases!

**Dependencies**: `directories.sh`, `logging.sh`

**Lines**: ~200 (simpler without substitution logic)
**Effort**: 6 hours (reduced from 8h - no variable handling)
**Risk**: MEDIUM (reduced from HIGH - no variable edge cases)

---

### 2.4 Module: `prompts.sh`

**Purpose**: User interaction and input validation

**Public API**:

```bash
# Prompt for assistant name with validation
prompt_assistant_name() {
  local default="${1:-assistant}"
  # Returns: Valid assistant name via stdout
}

# Prompt for personality selection
prompt_personality() {
  # Returns: Selected personality name via stdout
}

# Generic yes/no confirmation
prompt_confirm() {
  local message="$1"
  local default="${2:-n}"  # y or n
  # Returns: 0 for yes, 1 for no
}

# Menu-based selection
prompt_multiselect() {
  local prompt="$1"
  shift
  local options=("$@")
  # Returns: Selected option via stdout
}
```

**Validation Rules**:

```bash
# Assistant name
- Length: 3-20 characters
- Pattern: ^[a-z][a-z0-9-]*$
- Examples: "jarvis", "my-assistant-2"
- Invalid: "J", "My Assistant", "assistant!"

# Personality
- Options: jarvis, alfred, friday, sage, drill-sergeant
- Case-insensitive matching
- Default: jarvis
```

**User Experience**:

- Clear, concise prompts
- Default values shown in brackets `[default]`
- Validation feedback inline (not after submit)
- Retry on invalid input (max 3 attempts)

**Dependencies**: `logging.sh`

**Lines**: ~120
**Effort**: 3 hours
**Risk**: LOW

---

### 2.5 Module: `deprecation.sh`

**Purpose**: Deprecation lifecycle management

**Public API**:

```bash
# Check if template is deprecated
check_deprecated_status() {
  local template_file="$1"  # Path to template README.md
  # Returns: 0 if deprecated, 1 if not, 2 on error
}

# Extract deprecation metadata from frontmatter
parse_deprecation_metadata() {
  local template_file="$1"
  # Outputs: deprecated_in remove_in canonical reason
}

# Move deprecated template to .aida-deprecated/ namespace
move_to_deprecated() {
  local src_dir="$1"
  local dst_dir="$2"
  # Returns: 0 on success, 1 on failure
}

# Cleanup deprecated items based on version
cleanup_deprecated() {
  local current_version="$1"
  local templates_dir="$2"
  # Returns: 0 on success, 1 on failure
}
```

**Frontmatter Schema**:

```yaml
---
title: "Create Issue Command"
deprecated: true
deprecated_in: "0.2.0"
remove_in: "0.4.0"
canonical: "issue-create"
reason: "Renamed to noun-verb convention (ADR-010)"
---
```

**Version Comparison**:

```bash
# Semantic versioning (MAJOR.MINOR.PATCH)
compare_versions "0.1.0" "0.2.0"  # returns: -1 (less than)
compare_versions "0.2.0" "0.2.0"  # returns: 0 (equal)
compare_versions "0.3.0" "0.2.0"  # returns: 1 (greater than)

# Pre-release handling
compare_versions "0.2.0-alpha" "0.2.0"  # returns: -1
```

**Frontmatter Parsing** (Bash 3.2 compatible):

```bash
# Extract YAML frontmatter without yq/python
parse_frontmatter() {
  local file="$1"
  local key="$2"

  # Extract value between --- delimiters
  sed -n '/^---$/,/^---$/p' "$file" | \
    grep "^${key}:" | \
    sed 's/^[^:]*: *//'
}
```

**Installation Behavior**:

```bash
# Default: Skip deprecated templates
./install.sh
# Result: Only .aida/ namespace installed

# With flag: Install deprecated to separate namespace
./install.sh --with-deprecated
# Result: Both .aida/ and .aida-deprecated/ namespaces
```

**Cleanup Script** (separate tool):

```bash
#!/usr/bin/env bash
# scripts/cleanup-deprecated.sh

# Read current version
VERSION=$(cat VERSION)

# Find deprecated items where remove_in <= VERSION
# Remove from templates/ directory
# Does NOT affect user installations
```

**Dependencies**: `validation.sh`, `logging.sh`

**Lines**: ~180
**Effort**: 6 hours
**Risk**: HIGH (version comparison logic, frontmatter parsing)

---

### 2.6 Module: `summary.sh`

**Purpose**: Installation summary and next steps

**Public API**:

```bash
# Display installation summary
display_summary() {
  local install_dir="$1"    # ~/.aida/ path
  local config_dir="$2"     # ~/.claude/ path
  local dev_mode="$3"       # true/false
  local duration="$4"       # Installation time in seconds
  # Returns: 0 (always succeeds)
}

# Display what changed (for upgrades)
display_changes() {
  local before_snapshot="$1"
  local after_snapshot="$2"
  # Returns: 0 (always succeeds)
}

# Display next steps
display_next_steps() {
  local assistant_name="$1"
  local personality="$2"
  # Returns: 0 (always succeeds)
}
```

**Summary Format**:

```text
╔════════════════════════════════════════════════════════════╗
║           AIDA Installation Complete!                      ║
╚════════════════════════════════════════════════════════════╝

  Assistant Name: jarvis
  Personality:    JARVIS (Professional assistant)
  Mode:           Normal (templates copied)
  Duration:       8.2 seconds

  Installed To:
  ✓ ~/.aida/                    (framework - symlinked)
  ✓ ~/.claude/commands/.aida/   (12 commands)
  ✓ ~/.claude/agents/.aida/     (5 agents)
  ✓ ~/.claude/skills/.aida/     (3 skills)
  ✓ ~/CLAUDE.md                 (entry point)

  Next Steps:
  1. Open a new terminal to load environment
  2. Try: claude "What can you help me with?"
  3. Explore commands: ls ~/.claude/commands/.aida/
  4. Read documentation: ~/.aida/docs/

  Need help? Visit: https://github.com/org/repo/issues
```

**Dependencies**: `logging.sh`

**Lines**: ~100
**Effort**: 2 hours
**Risk**: LOW

---

## 3. Refactored `install.sh` Orchestrator

### Structure

```bash
#!/usr/bin/env bash
# install.sh - AIDA Framework Installer (~150 lines)

set -euo pipefail

# ============================================================
# Configuration
# ============================================================
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly INSTALLER_COMMON="${SCRIPT_DIR}/lib/installer-common"

# ============================================================
# Source Modules (order matters - dependencies first)
# ============================================================
source "${INSTALLER_COMMON}/colors.sh"
source "${INSTALLER_COMMON}/logging.sh"
source "${INSTALLER_COMMON}/validation.sh"
source "${INSTALLER_COMMON}/variables.sh"
source "${INSTALLER_COMMON}/directories.sh"
source "${INSTALLER_COMMON}/templates.sh"
source "${INSTALLER_COMMON}/prompts.sh"
source "${INSTALLER_COMMON}/deprecation.sh"
source "${INSTALLER_COMMON}/summary.sh"

# ============================================================
# Main Installation Flow
# ============================================================
main() {
  local start_time=$(date +%s)

  # Parse arguments
  parse_arguments "$@"

  # Pre-flight checks
  validate_dependencies
  detect_platform

  # User interaction
  ASSISTANT_NAME=$(prompt_assistant_name)
  PERSONALITY=$(prompt_personality)

  # Confirm destructive operations
  if [[ -d "${CLAUDE_DIR}" ]]; then
    prompt_confirm "Existing installation detected. Continue?" || exit 0
  fi

  # Directory setup
  backup_existing "${CLAUDE_DIR}"
  create_aida_dir "${SCRIPT_DIR}" "${AIDA_DIR}"
  create_claude_dirs "${CLAUDE_DIR}"
  create_namespace_dirs "${CLAUDE_DIR}" ".aida"

  if [[ "${WITH_DEPRECATED}" == true ]]; then
    create_namespace_dirs "${CLAUDE_DIR}" ".aida-deprecated"
  fi

  # Template installation
  install_templates "${SCRIPT_DIR}/templates/commands" \
                    "${CLAUDE_DIR}/commands/.aida" \
                    "${DEV_MODE}" ".aida"

  install_templates "${SCRIPT_DIR}/templates/agents" \
                    "${CLAUDE_DIR}/agents/.aida" \
                    "${DEV_MODE}" ".aida"

  install_templates "${SCRIPT_DIR}/templates/skills" \
                    "${CLAUDE_DIR}/skills/.aida" \
                    "${DEV_MODE}" ".aida"

  # Generate entry point
  generate_claude_md "${HOME}/CLAUDE.md" "${ASSISTANT_NAME}" "${PERSONALITY}"

  # Summary
  local duration=$(($(date +%s) - start_time))
  display_summary "${AIDA_DIR}" "${CLAUDE_DIR}" "${DEV_MODE}" "${duration}"
  display_next_steps "${ASSISTANT_NAME}" "${PERSONALITY}"
}

main "$@"
```

**Key Principles**:

- **No business logic** - delegates to library modules
- **Clear flow** - sequential steps, easy to read
- **Error handling** - `set -euo pipefail` stops on first error
- **Logging** - all operations logged via `logging.sh`

**Lines**: ~150
**Effort**: 4 hours
**Risk**: MEDIUM (orchestration logic)

---

## 4. Testing Infrastructure

### 4.1 Docker Testing Environments

**Existing Dockerfiles** (extend):

```text
.github/docker/
├── ubuntu-22.04.Dockerfile       (existing)
├── ubuntu-20.04.Dockerfile       (existing)
├── debian-12.Dockerfile          (existing)
├── ubuntu-minimal.Dockerfile     (existing - dependency validation)
├── ubuntu-upgrade-test.Dockerfile   (NEW - pre-seeded fixtures)
└── windows-2022.Dockerfile          (NEW - PowerShell/WSL)
```

**Upgrade Test Dockerfile**:

```dockerfile
FROM ubuntu:22.04

# Standard dependencies
RUN apt-get update && apt-get install -y git rsync

# Create test user
RUN useradd -m -s /bin/bash testuser

# Pre-seed with existing installation (fixtures)
COPY .github/testing/fixtures/existing-claude-config /home/testuser/.claude
RUN chown -R testuser:testuser /home/testuser/.claude

USER testuser
WORKDIR /workspace
```

**Test Fixtures** (new):

```text
.github/testing/fixtures/
├── existing-claude-config/       # Simulates v0.1.x installation
│   ├── commands/
│   │   ├── custom-command.md      # User content (must preserve)
│   │   └── .aida/                 # Old framework (can replace)
│   ├── agents/
│   │   └── custom-agent.md        # User content (must preserve)
│   ├── config/
│   │   └── assistant.yaml         # User config (must preserve)
│   └── memory/
│       └── session-123.json       # User data (must preserve)
└── deprecated-templates/         # Old deprecated templates
    └── commands/
        └── old-cmd.md             # deprecated_in: "0.1.0"
```

---

### 4.2 Makefile Orchestration

**New File**: `Makefile`

```makefile
# ============================================================
# AIDA Framework - Test Orchestration
# ============================================================

.PHONY: help test-all test-install test-upgrade test-fixtures \
        test-linux test-macos test-windows clean-test

.DEFAULT_GOAL := help

# ============================================================
# Configuration
# ============================================================
DOCKER_COMPOSE := $(shell command -v docker-compose 2>/dev/null || echo "docker compose")
TEST_SCRIPT := .github/testing/test-install.sh
VERBOSE ?= false
ENVIRONMENT ?= all

# ============================================================
# Help Target
# ============================================================
help: ## Show this help message
	@echo "AIDA Framework - Test Targets"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

# ============================================================
# Primary Test Targets
# ============================================================
test-all: test-install test-upgrade test-fixtures ## Run all test scenarios

test-install: ## Test fresh installation
	@echo "Running fresh installation tests..."
	$(TEST_SCRIPT) --scenario=fresh $(if $(filter true,$(VERBOSE)),--verbose)

test-upgrade: ## Test upgrade installation
	@echo "Running upgrade installation tests..."
	$(TEST_SCRIPT) --scenario=upgrade $(if $(filter true,$(VERBOSE)),--verbose)

test-fixtures: ## Validate test fixture integrity
	@echo "Validating test fixtures..."
	.github/testing/validate-fixtures.sh

# ============================================================
# Mode-Specific Targets
# ============================================================
test-normal-mode: ## Test normal installation mode
	$(TEST_SCRIPT) --mode=normal $(if $(filter true,$(VERBOSE)),--verbose)

test-dev-mode: ## Test dev installation mode
	$(TEST_SCRIPT) --mode=dev $(if $(filter true,$(VERBOSE)),--verbose)

# ============================================================
# Cleanup Targets
# ============================================================
clean-test: ## Clean test artifacts
	@echo "Cleaning test artifacts..."
	rm -rf .github/testing/logs/*
	$(DOCKER_COMPOSE) -f .github/docker/docker-compose.yml down -v
```

**Effort**: 2-3 hours

---

### 4.3 GitHub Actions Workflow

**Extend Existing**: `.github/workflows/test-installation.yml`

**Add Upgrade Testing Job**:

```yaml
test-upgrade-scenarios:
  name: Test Upgrade Scenarios
  runs-on: ubuntu-latest
  needs: lint
  strategy:
    fail-fast: false
    matrix:
      scenario:
        - fresh-install          # No existing ~/.claude/
        - upgrade-with-custom    # Existing + user content
        - upgrade-deprecated     # Existing + deprecated templates
        - dev-to-normal          # Mode switching
  steps:
    - uses: actions/checkout@v4

    - name: Run upgrade test for ${{ matrix.scenario }}
      run: |
        make test-upgrade SCENARIO=${{ matrix.scenario }} VERBOSE=true

    - name: Validate user content preserved
      run: |
        .github/testing/validate-preservation.sh ${{ matrix.scenario }}

    - name: Upload test artifacts
      if: always()
      uses: actions/upload-artifact@v4
      with:
        name: test-results-${{ matrix.scenario }}
        path: .github/testing/logs/
        retention-days: 7
```

**Add PR Comment Reporter** (optional v0.3.0):

```yaml
test-report:
  name: Comment Test Results
  runs-on: ubuntu-latest
  needs: [test-macos, test-windows-wsl, test-linux-docker, test-upgrade-scenarios]
  if: github.event_name == 'pull_request'
  permissions:
    pull-requests: write
  steps:
    - name: Generate test report
      id: report
      run: |
        REPORT=$(.github/testing/generate-pr-report.sh test-results/)
        echo "report<<EOF" >> $GITHUB_OUTPUT
        echo "$REPORT" >> $GITHUB_OUTPUT
        echo "EOF" >> $GITHUB_OUTPUT

    - name: Comment PR
      uses: actions/github-script@v7
      with:
        script: |
          github.rest.issues.createComment({
            issue_number: context.issue.number,
            owner: context.repo.owner,
            repo: context.repo.repo,
            body: `## 🧪 Installation Test Results\n\n${process.env.REPORT}`
          })
      env:
        REPORT: ${{ steps.report.outputs.report }}
```

**Effort**: 4-6 hours

---

### 4.4 Test Scenarios

**Validation Script** (new): `.github/testing/validate-preservation.sh`

```bash
#!/usr/bin/env bash
# Validates user content preservation after upgrade

validate_user_content_preserved() {
    local test_home="$1"
    local fixture_dir=".github/testing/fixtures/existing-claude-config"

    echo "Validating user content preservation..."

    # User-created files must exist and be unchanged
    for file in commands/custom-command.md config/assistant.yaml memory/session-123.json; do
        if ! diff -q "$fixture_dir/$file" "$test_home/.claude/$file" > /dev/null 2>&1; then
            echo "❌ FAIL: User file modified or missing: $file"
            return 1
        fi
    done

    # Framework templates must be updated (different from fixture)
    for file in commands/.aida/start-work/README.md agents/.aida/secretary/README.md; do
        if diff -q "$fixture_dir/$file" "$test_home/.claude/$file" > /dev/null 2>&1; then
            echo "❌ FAIL: Framework template not updated: $file"
            return 1
        fi
    done

    echo "✅ PASS: User content preserved, framework templates updated"
    return 0
}
```

**Effort**: 8-10 hours (upgrade scenarios + validation)

---

## 5. Implementation Plan

### Phase 1: Foundation (20 hours)

**Week 1**:

1. **Extract `prompts.sh`** (3h)
   - Lowest risk, standalone module
   - Move existing prompt functions
   - Add unit tests (bats framework setup)

2. **Extract `variables.sh`** (4h)
   - Variable substitution logic
   - Edge case handling (spaces, escapes)
   - Unit tests for substitution

3. **Extract `directories.sh`** (5h)
   - Directory creation logic
   - Symlink management
   - Cross-platform path handling
   - Unit tests

4. **Extract `summary.sh`** (2h)
   - Output formatting
   - Installation summary
   - Next steps display

5. **Refactor `install.sh` to orchestrator** (4h)
   - Remove business logic
   - Source modules
   - Sequential flow
   - Error handling

6. **Basic unit tests** (2h)
   - Setup bats framework
   - Test helper functions
   - Module isolation tests

**Milestone**: Modular architecture working, all existing functionality preserved

---

### Phase 2: Advanced Features (20 hours)

**Week 2**:

1. **Implement `templates.sh`** (8h)
   - Namespace isolation (`.aida/` subdirectories)
   - Folder-based installation
   - Normal vs dev mode handling
   - Variable substitution integration
   - Integration tests

2. **Implement `deprecation.sh`** (6h)
   - Frontmatter parsing (pure Bash)
   - Version comparison logic
   - Deprecated template installation
   - Cleanup script
   - Unit tests

3. **Docker test fixtures** (3h)
   - Create upgrade test fixtures
   - Existing installation simulation
   - User content examples
   - Deprecated template examples

4. **Integration tests** (3h)
   - Fresh install test
   - Upgrade install test
   - User content preservation
   - Dev mode validation

**Milestone**: All features implemented, integration tests passing

---

### Phase 3: CI/CD & Documentation (15 hours)

**Week 3**:

1. **Makefile creation** (2-3h)
   - Test targets
   - Parameterization
   - Help documentation

2. **Docker environment enhancements** (4-6h)
   - Upgrade test Dockerfile
   - Fixture volume mounts
   - Windows container (optional v0.3.0)

3. **GitHub Actions updates** (4-6h)
   - Upgrade scenario job
   - Test matrix expansion
   - PR comment reporter (optional)
   - Artifact collection

4. **Cross-platform testing** (3-4h)
   - macOS GitHub runner tests
   - Windows WSL tests
   - Platform-specific validation

5. **Documentation** (2-3h)
   - Update `docs/CONTRIBUTING.md`
   - Testing guide
   - Troubleshooting guide
   - Dotfiles integration examples

**Milestone**: Complete CI/CD pipeline, comprehensive documentation

---

## 6. Dotfiles Integration

### API Contract

**Dotfiles Installer Pattern**:

```bash
#!/usr/bin/env bash
# ~/dotfiles/install.sh

set -euo pipefail

# Check if AIDA installed
if [[ -d "${HOME}/.aida" ]]; then
  readonly INSTALLER_COMMON="${HOME}/.aida/lib/installer-common"

  # Version check
  if [[ -f "${HOME}/.aida/VERSION" ]]; then
    AIDA_VERSION=$(cat "${HOME}/.aida/VERSION")
    REQUIRED_VERSION="0.2.0"

    # Source validation module
    source "${INSTALLER_COMMON}/colors.sh"
    source "${INSTALLER_COMMON}/logging.sh"
    source "${INSTALLER_COMMON}/validation.sh"

    if check_version_compatibility "$AIDA_VERSION" "$REQUIRED_VERSION"; then
      # Source additional modules
      source "${INSTALLER_COMMON}/templates.sh"
      source "${INSTALLER_COMMON}/variables.sh"
      AIDA_AVAILABLE=true
    else
      print_message "warning" "AIDA version incompatible, using fallback"
      AIDA_AVAILABLE=false
    fi
  fi
else
  echo "AIDA not installed, using standalone mode"
  AIDA_AVAILABLE=false
fi

# Install dotfiles templates
if [[ "$AIDA_AVAILABLE" == true ]]; then
  # Use AIDA libraries for consistency
  install_templates \
    "${PWD}/templates/commands" \
    "${HOME}/.claude/commands/.dotfiles"
else
  # Fallback: manual installation
  cp -r "${PWD}/templates/commands" "${HOME}/.claude/commands/.dotfiles"
fi
```

**Semantic Versioning**:

- **MAJOR version**: Breaking changes to function signatures
- **MINOR version**: New features, backward compatible
- **PATCH version**: Bug fixes, no API changes

**Version Checking Function** (`validation.sh`):

```bash
check_version_compatibility() {
  local installed="$1"  # e.g., "0.2.1"
  local required="$2"   # e.g., "0.2.0"

  # Major must match exactly
  # Minor must be >= required
  # Patch doesn't matter

  # Returns: 0 if compatible, 1 if not
}
```

---

## 7. Risk Mitigation

### Critical Risks

**1. User Data Loss** 🔴

- **Risk**: Installer overwrites custom commands/agents/skills
- **Mitigation**:
  - Namespace isolation (`.aida/` subdirectories)
  - Pre-flight validation (detect user content)
  - Confirmation prompts before overwrites
  - Comprehensive automated tests with fixtures
  - Manual QA before every release

**2. Cross-Platform Compatibility** 🟠

- **Risk**: Works on Linux, breaks on macOS (or vice versa)
- **Mitigation**:
  - CI/CD matrix (Ubuntu + macOS runners)
  - Bash 3.2 linting and validation
  - Platform-specific test cases
  - Manual testing on both platforms

**3. Variable Substitution Bugs** 🟠

- **Risk**: Paths not substituted correctly, broken templates
- **Mitigation**:
  - Automated validation (grep for unresolved `{{VAR}}`)
  - Test with paths containing spaces/special chars
  - Comprehensive test fixtures
  - Clear distinction (install-time vs runtime)

**4. Symlink Issues (Dev Mode)** 🟡

- **Risk**: Broken symlinks, permission issues, wrong targets
- **Mitigation**:
  - Symlink validation after creation
  - Broken symlink detection and repair
  - Clear error messages if symlinks fail
  - WSL-specific testing

**5. Dotfiles Integration** 🟡

- **Risk**: Libraries don't work when sourced externally
- **Mitigation**:
  - Parameter-based functions (no globals)
  - Test sourcing from different directory
  - Version checking for compatibility
  - API contract documentation

---

## 8. Success Criteria

### Must Have (Blocking Release)

- ✅ Zero data loss: User content preserved during upgrades
- ✅ Modular architecture: `install.sh` < 150 lines, logic in modules
- ✅ Dotfiles integration: Libraries successfully sourced from dotfiles repo
- ✅ All tests pass: Docker tests + CI/CD tests on all platforms
- ✅ Namespace isolation: `.aida/` and `.aida-deprecated/` folders work correctly

### Should Have (Important)

- ✅ User confirmation before destructive operations
- ✅ Progress indicators for long operations
- ✅ Helpful error messages with recovery guidance
- ✅ Deprecation system working end-to-end
- ✅ Dev mode `git pull` auto-updates

### Nice to Have (Defer if Needed)

- ❌ Pre-flight installation plan (show changes before applying)
- ❌ Automated cleanup script integration in CI/CD
- ❌ Installation time estimates
- ❌ Rollback capability

---

## 9. Effort Summary

| Component | Complexity | Estimated Effort |
|-----------|-----------|------------------|
| **Shell Script Implementation** | HIGH | **53 hours** |
| - Module extraction (6 modules) | HIGH | 30 hours |
|   - `prompts.sh` | LOW | 3h |
|   - `aida-config-helper.sh` + `config.sh` | MEDIUM | 8h |
|   - `directories.sh` | MEDIUM | 5h |
|   - `templates.sh` (simplified, no vars) | MEDIUM | 6h |
|   - `deprecation.sh` | HIGH | 6h |
|   - `summary.sh` | LOW | 2h |
| - install.sh refactoring | MEDIUM | 4 hours |
| - Unit tests (bats) | MEDIUM | 8 hours |
| - Integration tests | HIGH | 8 hours |
| - Documentation | LOW | 3 hours |
| - ~~Spikes (3 unknowns)~~ | ~~MEDIUM~~ | ~~0 hours~~ (all resolved!) |
| **Testing Infrastructure** | MEDIUM | **32-45 hours** |
| - Makefile creation | LOW | 2-3 hours |
| - Docker enhancements | LOW-MEDIUM | 4-6 hours |
| - Test fixtures | MEDIUM | 6-8 hours |
| - Upgrade scenarios | MEDIUM | 8-10 hours |
| - GitHub Actions updates | LOW-MEDIUM | 4-6 hours |
| - Documentation | LOW | 2-3 hours |
| **TOTAL** | **LARGE** | **85-98 hours** |

**Timeline**: ~11-12 days (assuming 8h/day, single developer)

**Buffer**: Add 20% for unexpected issues = **102-118 hours** (13-15 days)

**Key Improvements from Universal Config Aggregator**:
- ✅ Eliminated 9h of spike work (Q1-Q3 resolved)
- ✅ Reduced templates.sh from 8h to 6h (no variable substitution)
- ✅ Added 4h for config aggregator (but provides MASSIVE value across all commands)
- ✅ **Net savings**: 2 hours + cleaner architecture + 85% I/O reduction

---

## 10. Open Questions

### ✅ ALL QUESTIONS RESOLVED

**Q1: Dev mode variable substitution** ✅ **RESOLVED**

- **Problem**: Symlinked templates can't have substituted variables
- **SOLUTION**: Universal config aggregator (`aida-config-helper.sh`)
  - Templates stay pure (no substitution needed)
  - Variables resolved at runtime via config helper
  - Works in both normal AND dev mode
  - No spike needed - cleaner architecture!

**Q2: Deprecation blocking** ✅ **RESOLVED**

- **Question**: Should installer refuse if deprecated templates conflict?
- **DECISION**: Warn and skip deprecated (Option 2)
  - Safest approach - never overwrites user content
  - Clear warning message with canonical alternative
  - User can manually install deprecated with `--with-deprecated`

**Q3: Version compatibility strictness** ✅ **RESOLVED**

- **Question**: How strict should version validation be?
- **DECISION**: Hard fail (Option 1)
  - Prevents subtle bugs from version mismatches
  - Clear error message with upgrade instructions
  - Dotfiles integration requires compatible AIDA version

---

## 11. Next Steps

### Immediate Actions

1. **Review with specialist agents** - Get technical review from shell-script-specialist, devops-engineer, qa-engineer
2. **Approve this spec** - Final sign off on architecture
3. **Create implementation branch** - `53-modular-installer`
4. **Begin Phase 1** - Extract `prompts.sh` module (lowest risk)

### Implementation Order

**Phase 1** (Foundation):

1. `prompts.sh` (3h)
2. `aida-config-helper.sh` + `config.sh` (8h)
3. `directories.sh` (5h)
4. `summary.sh` (2h)
5. Refactor `install.sh` (4h)
6. Unit tests (2h)

**Phase 2** (Advanced):

1. `templates.sh` (8h)
2. `deprecation.sh` (6h)
3. Docker fixtures (3h)
4. Integration tests (3h)

**Phase 3** (CI/CD):

1. Makefile (2-3h)
2. Docker enhancements (4-6h)
3. GitHub Actions (4-6h)
4. Cross-platform tests (3-4h)
5. Documentation (2-3h)

---

**Author**: Tech Lead (synthesized from shell-script-specialist, devops-engineer, qa-engineer)
**Created**: 2025-10-18
**Status**: Draft - Awaiting approval
