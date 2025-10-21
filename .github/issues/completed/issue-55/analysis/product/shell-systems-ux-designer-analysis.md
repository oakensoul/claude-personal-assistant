---
issue: 55
title: "Shell Systems UX Designer Analysis - Configuration System"
analyst: shell-systems-ux-designer
date: 2025-10-20
status: complete
---

# Shell Systems UX Designer Analysis - Issue #55

## Executive Summary

The configuration system introduces **auto-detection and validation** capabilities that must "just work" for common cases while providing clear guidance when manual intervention is needed. The UX challenge is balancing automatic convenience with transparent control and actionable error messages.

---

## 1. Domain-Specific Concerns

### 1.1 Error Message Quality

#### Validation Failures - Current Gap

The existing `aida-config-helper.sh` provides basic validation but lacks **domain-specific guidance**:

```bash
# Current (too generic)
Error: Config key not found: vcs.provider

# Better (actionable)
Error: VCS provider not configured

Auto-detection failed. Could not determine VCS provider from git remote.

To fix this, add to ~/.claude/config.json:
  {
    "vcs": {
      "provider": "github",  // or "gitlab", "bitbucket"
      "url": "https://github.com"
    }
  }

Current git remote:
  origin  git@example.com:user/repo.git (fetch)

See: aida-config-helper.sh --help vcs
```

#### Missing Config - Contextual Guidance

When config files don't exist, errors should **guide users to the right action**:

```bash
# Current
Configuration file not found: ~/.claude/config.json

# Better (first-time user)
Welcome! AIDA configuration not found.

Let's set up your configuration:
  aida-init  # Interactive setup (coming soon)

Or manually create ~/.claude/config.json:
  cp ~/.aida/templates/config/aida-config.json ~/.claude/config.json
  $EDITOR ~/.claude/config.json

# Better (project context)
Project AIDA configuration not found: .aida/config.json

Working with project: oakensoul/claude-personal-assistant
Detected: GitHub repository

Initialize project configuration:
  aida-init --project  # Configure VCS, issue tracker, workflows

Or copy template:
  mkdir -p .aida
  cp ~/.aida/templates/config/project-config.json .aida/config.json
```

#### Provider-Specific Validation

Each VCS provider has **unique requirements** that should be validated:

```bash
# GitHub
Error: GitHub configuration incomplete

Required fields missing:
  ✗ github.owner
  ✗ github.repo

Auto-detected from git remote:
  owner: oakensoul
  repo: claude-personal-assistant

Add to .aida/config.json:
  {
    "github": {
      "owner": "oakensoul",
      "repo": "claude-personal-assistant",
      "main_branch": "main"
    }
  }

# GitLab
Error: GitLab configuration incomplete

Required fields:
  ✗ gitlab.project_id  (required for API access)
  ✗ gitlab.url         (defaults to gitlab.com)

Find your project ID:
  1. Visit: https://gitlab.com/user/repo/-/settings/general
  2. Copy "Project ID" from top of page

Add to .aida/config.json:
  {
    "gitlab": {
      "project_id": "12345678",
      "url": "https://gitlab.com"
    }
  }
```

### 1.2 Auto-Detection Feedback

#### Silent Success is Confusing

Users need to know **what was detected and why**:

```bash
# Bad (silent)
$ aida-config-helper.sh --validate
Configuration validation passed

# Good (transparent)
$ aida-config-helper.sh --validate
Validating configuration...

Auto-detected from git remote:
  ✓ VCS provider: GitHub
  ✓ Repository: oakensoul/claude-personal-assistant
  ✓ Issue tracker: GitHub Issues

Configuration sources:
  ✓ System defaults    ~/.aida/config.json
  ✓ User config        ~/.claude/config.json
  ✓ Project config     .aida/config.json (auto-detected)
  ✓ Git config         .git/config

All required fields present:
  ✓ vcs.provider: github
  ✓ vcs.owner: oakensoul
  ✓ vcs.repo: claude-personal-assistant
  ✓ paths.aida_home: /Users/rob/.aida

Configuration ready!
```

#### Detection Failures Need Context

When auto-detection fails, explain **why and how to fix**:

```bash
$ aida-config-helper.sh --detect-vcs
Auto-detecting VCS provider...

✗ Detection failed

Reason: Git remote URL format not recognized
  Current: https://custom-gitlab.company.com/team/project.git
  Expected: github.com, gitlab.com, or bitbucket.org

Manual configuration required:
  1. Identify your VCS provider
  2. Add to .aida/config.json:

     {
       "vcs": {
         "provider": "gitlab",
         "url": "https://custom-gitlab.company.com",
         "project_id": "12345"  # Required for GitLab
       }
     }

  3. Re-run: aida-config-helper.sh --validate
```

#### Override Mechanism Must Be Obvious

Users need to **easily override auto-detection**:

```bash
# Environment variable (temporary)
VCS_PROVIDER=gitlab aida-config-helper.sh --validate

# Project config (permanent)
echo '{"vcs": {"provider": "gitlab"}}' > .aida/config.json

# User config (all projects)
# Add to ~/.claude/config.json:
{
  "vcs": {
    "provider": "gitlab",  // Override auto-detection
    "url": "https://gitlab.company.com"
  }
}
```

### 1.3 Configuration Discoverability

**How do users know what's available?**

#### Missing: Schema Documentation

Users need to **discover available config keys**:

```bash
# Add to aida-config-helper.sh
$ aida-config-helper.sh --schema
AIDA Configuration Schema

Available namespaces:
  paths         System paths (aida_home, project_root, etc.)
  user          User preferences (assistant_name, personality)
  vcs           Version control (provider, owner, repo)
  git           Git identity (user.name, user.email)
  github        GitHub settings (owner, repo, main_branch)
  gitlab        GitLab settings (project_id, url)
  workflow      Workflow automation (commit, pr, branch)
  env           Environment variables (github_token, editor)

Show namespace details:
  aida-config-helper.sh --schema vcs
  aida-config-helper.sh --schema workflow
```

#### Missing: Examples for Each Provider

```bash
$ aida-config-helper.sh --schema vcs
VCS Configuration Schema

Provider-specific configurations:

GitHub:
  {
    "vcs": {
      "provider": "github",
      "url": "https://github.com"  // Optional, defaults to github.com
    },
    "github": {
      "owner": "username",          // Required
      "repo": "repository",         // Required
      "main_branch": "main",        // Optional, auto-detected
      "default_reviewers": ["user"] // Optional
    }
  }

GitLab:
  {
    "vcs": {
      "provider": "gitlab",
      "url": "https://gitlab.com"  // Optional, defaults to gitlab.com
    },
    "gitlab": {
      "project_id": "12345",       // Required for API access
      "group": "group-name",       // Optional
      "main_branch": "main"        // Optional, auto-detected
    }
  }

Bitbucket:
  {
    "vcs": {
      "provider": "bitbucket",
      "url": "https://bitbucket.org"
    },
    "bitbucket": {
      "workspace": "workspace",    // Required
      "repo_slug": "repository",   // Required
      "main_branch": "main"        // Optional
    }
  }
```

#### Missing: Interactive Configuration Wizard

```bash
$ aida-config-helper.sh --wizard
AIDA Configuration Wizard

Detected: Git repository
Remote URL: git@github.com:oakensoul/claude-personal-assistant.git

Auto-detected configuration:
  VCS Provider: GitHub
  Owner: oakensoul
  Repository: claude-personal-assistant
  Issue Tracker: GitHub Issues

Is this correct? [Y/n]: y

Where should this configuration be saved?
  1) Project only (.aida/config.json)
  2) User default (~/.claude/config.json)
  3) Both (project overrides user)

Select [1-3]: 1

Creating .aida/config.json...
✓ Configuration saved

Validate configuration:
  aida-config-helper.sh --validate
```

### 1.4 Help Text and Documentation Needs

#### Current Help is Good, But Missing VCS Context

Add VCS-specific help:

```bash
$ aida-config-helper.sh --help vcs
VCS Configuration Help

The VCS configuration determines how AIDA interacts with version control
and issue tracking systems.

Auto-Detection:
  AIDA automatically detects your VCS provider by parsing 'git remote -v'.

  Supported patterns:
    github.com      → GitHub
    gitlab.com      → GitLab
    bitbucket.org   → Bitbucket

  Custom instances:
    gitlab.company.com → GitLab (requires manual config)
    github.enterprise  → GitHub Enterprise (requires manual config)

Configuration Priority:
  1. Environment: VCS_PROVIDER=github
  2. Project:     .aida/config.json
  3. User:        ~/.claude/config.json
  4. Auto-detect: From git remote

Examples:
  # Auto-detect and validate
  aida-config-helper.sh --detect-vcs

  # Override auto-detection
  echo '{"vcs": {"provider": "gitlab"}}' > .aida/config.json

  # Check current VCS config
  aida-config-helper.sh --namespace vcs

See also:
  aida-config-helper.sh --schema vcs
  ~/.aida/docs/configuration/vcs-providers.md
```

---

## 2. Stakeholder Impact

### 2.1 First-Time Users

**Can they set up config without docs?**

**Current State: NO** - Too many manual steps, unclear what's required

#### Recommended Experience

```bash
# First command they run (any AIDA command)
$ aida status

Welcome to AIDA! 👋

Configuration setup required.

Run the setup wizard:
  aida-init

Or view configuration help:
  aida-config-helper.sh --help

# Interactive wizard guides them
$ aida-init

AIDA Setup Wizard

Step 1/4: Detect VCS Provider
  Analyzing git repository...
  ✓ Detected: GitHub (oakensoul/claude-personal-assistant)

Step 2/4: Issue Tracker
  Use GitHub Issues? [Y/n]: y
  ✓ Configured: GitHub Issues

Step 3/4: User Preferences
  Assistant name [aida]: jarvis
  Personality [default]: professional
  ✓ Configured

Step 4/4: Save Configuration
  Save to: ~/.claude/config.json
  ✓ Configuration saved

Setup complete! 🎉

Try these commands:
  aida status           # Check system status
  aida start-work 55    # Start working on issue #55
```

### 2.2 Power Users

**Can they override/customize easily?**

**Yes, with improvements**:

#### Environment Variable Overrides

```bash
# Quick override for single command
VCS_PROVIDER=gitlab aida-config-helper.sh --validate

# Session override
export VCS_PROVIDER=gitlab
export VCS_URL=https://gitlab.company.com

# Add to shell profile for permanent override
echo 'export VCS_PROVIDER=gitlab' >> ~/.zshrc
```

#### Direct JSON Editing

```bash
# Edit user config
$EDITOR ~/.claude/config.json

# Edit project config
$EDITOR .aida/config.json

# Validate after editing
aida-config-helper.sh --validate
```

#### CLI-Based Editing (recommended addition)

```bash
# Set config value
aida-config-helper.sh --set vcs.provider gitlab
aida-config-helper.sh --set vcs.url https://gitlab.company.com

# Unset config value (fall back to auto-detect)
aida-config-helper.sh --unset vcs.provider

# List current config
aida-config-helper.sh --namespace vcs
```

### 2.3 Teams

**Can they share config patterns?**

#### Recommended: Team Templates

```bash
# Project-level config (committed to VCS)
.aida/config.json  # Team defaults
.aida/config.json.example  # Template with comments

# Per-developer overrides (gitignored)
.aida/config.local.json  # Personal overrides

# Priority:
# 1. .aida/config.local.json (personal)
# 2. .aida/config.json (team)
# 3. ~/.claude/config.json (user)
```

**Example Team Config**:

```json
// .aida/config.json (committed)
{
  "vcs": {
    "provider": "github",
    "url": "https://github.com"
  },
  "github": {
    "owner": "oakensoul",
    "repo": "claude-personal-assistant",
    "main_branch": "main",
    "default_reviewers": ["tech-lead", "senior-dev"]
  },
  "workflow": {
    "commit": {
      "auto_commit": true,
      "message_prefix": "feat"
    },
    "pr": {
      "draft": false,
      "auto_reviewers": ["tech-lead"]
    }
  }
}

// .aida/config.local.json (gitignored)
{
  "workflow": {
    "commit": {
      "auto_commit": false  // Override: manual commits
    }
  }
}
```

---

## 3. Questions & Clarifications

### 3.1 Auto-Detection Communication

**Q: How to communicate auto-detection results to users?**

#### Recommendation: Multi-Level Verbosity

```bash
# Default (quiet success, loud failure)
$ aida-config-helper.sh --validate
✓ Configuration valid

# Verbose (show what was detected)
$ aida-config-helper.sh --validate --verbose
Auto-detection results:
  ✓ VCS provider: github (from git remote)
  ✓ Repository: oakensoul/claude-personal-assistant
  ✓ Main branch: main (from git config)
✓ Configuration valid

# Debug (full details)
$ aida-config-helper.sh --validate --debug
Config sources checked:
  1. Environment variables: 0 values
  2. Project config: .aida/config.json (found)
  3. User config: ~/.claude/config.json (found)
  4. Git config: .git/config (found)
  5. Auto-detection: git remote -v (success)

Merged config:
  {
    "vcs": {"provider": "github"},
    "github": {"owner": "oakensoul", "repo": "claude-personal-assistant"}
  }

Validation results:
  ✓ Required: vcs.provider = "github"
  ✓ Required: github.owner = "oakensoul"
  ✓ Required: github.repo = "claude-personal-assistant"

✓ Configuration valid
```

### 3.2 Provider-Specific Error Messages

**Q: What error messages for missing provider-specific fields?**

#### Recommendation: Progressive Disclosure

```bash
# Level 1: What's wrong
Error: GitHub configuration incomplete

# Level 2: What's missing
Required fields:
  ✗ github.owner
  ✗ github.repo

# Level 3: How to fix (auto-detected values)
Auto-detected from git remote:
  owner: oakensoul
  repo: claude-personal-assistant

# Level 4: Exact command to run
Add to .aida/config.json:
  echo '{"github": {"owner": "oakensoul", "repo": "claude-personal-assistant"}}' > .aida/config.json

# Level 5: Where to learn more
See: aida-config-helper.sh --help github
```

### 3.3 Validation Verbosity

**Q: Should validation be verbose or quiet by default?**

#### Recommendation: Context-Dependent

```bash
# Interactive context (verbose)
$ aida-init
  Auto-detecting VCS...
  ✓ Detected: GitHub

# Script context (quiet)
$ aida-config-helper.sh --validate && echo "OK"
OK

# Explicit verbose
$ aida-config-helper.sh --validate --verbose
  [detailed output]

# CI/CD (machine-readable)
$ aida-config-helper.sh --validate --format json
{"valid": true, "errors": [], "warnings": []}
```

**Exit codes for scripting**:

- `0` - Valid config
- `1` - Invalid config (missing required fields)
- `2` - Configuration file not found
- `3` - JSON parse error
- `4` - Auto-detection failed

### 3.4 Incomplete Configuration Guidance

**Q: How to guide users when config is incomplete?**

#### Recommendation: Contextual Next Steps

```bash
# Scenario 1: First-time user
Configuration incomplete: No VCS provider configured

This looks like your first time using AIDA.

Quick setup:
  aida-init  # Interactive wizard

Manual setup:
  cp ~/.aida/templates/config/aida-config.json ~/.claude/config.json
  $EDITOR ~/.claude/config.json

# Scenario 2: Project without config
Configuration incomplete: Project VCS not configured

Working in: oakensoul/claude-personal-assistant
Detected: GitHub repository

Quick setup:
  aida-init --project  # Configure this project

# Scenario 3: Missing specific field
Configuration incomplete: github.owner not set

Auto-detected from git remote:
  owner: oakensoul
  repo: claude-personal-assistant

Add to .aida/config.json:
  aida-config-helper.sh --set github.owner oakensoul
  aida-config-helper.sh --set github.repo claude-personal-assistant

Or manually edit:
  $EDITOR .aida/config.json
```

---

## 4. Recommendations

### 4.1 Error Message Templates

#### Template Structure

```text
[ERROR_LEVEL]: [WHAT_WENT_WRONG]

[WHY_IT_HAPPENED]

[AUTO_DETECTED_INFO]

[HOW_TO_FIX]:
  [RECOMMENDED_COMMAND]

[ALTERNATIVE]:
  [MANUAL_STEPS]

[SEE_ALSO]:
  [RELATED_HELP]
```

#### GitHub Provider Template

```bash
Error: GitHub configuration incomplete

Required for GitHub API access:
  ✗ github.owner
  ✗ github.repo

Auto-detected from git remote:
  Remote URL: git@github.com:oakensoul/claude-personal-assistant.git
  Owner: oakensoul
  Repo: claude-personal-assistant

Quick fix:
  aida-config-helper.sh --set github.owner oakensoul
  aida-config-helper.sh --set github.repo claude-personal-assistant

Or manually add to .aida/config.json:
  {
    "github": {
      "owner": "oakensoul",
      "repo": "claude-personal-assistant"
    }
  }

See: aida-config-helper.sh --help github
```

#### GitLab Provider Template

```bash
Error: GitLab configuration incomplete

Required for GitLab API access:
  ✗ gitlab.project_id (required)
  ✗ gitlab.url (optional, defaults to gitlab.com)

Auto-detected from git remote:
  Remote URL: git@gitlab.com:group/project.git
  URL: https://gitlab.com

Find your GitLab project ID:
  1. Visit: https://gitlab.com/group/project/-/settings/general
  2. Copy "Project ID" from General Settings
  3. Add to config:
     aida-config-helper.sh --set gitlab.project_id 12345678

Or manually add to .aida/config.json:
  {
    "gitlab": {
      "project_id": "12345678",
      "url": "https://gitlab.com"
    }
  }

See: aida-config-helper.sh --help gitlab
```

### 4.2 Auto-Detection Feedback Patterns

#### Pattern 1: Silent Success, Detailed Failures

```bash
# Success (quiet)
$ aida-config-helper.sh --validate
✓ Configuration valid

# Failure (detailed)
$ aida-config-helper.sh --validate
✗ Configuration invalid

Auto-detection attempted:
  Git remote: git@github.com:oakensoul/claude-personal-assistant.git
  ✓ Provider detected: github
  ✓ Owner detected: oakensoul
  ✓ Repo detected: claude-personal-assistant

Configuration check:
  ✗ github.owner not set (detected: oakensoul)
  ✗ github.repo not set (detected: claude-personal-assistant)

Apply auto-detected values:
  aida-config-helper.sh --apply-detection

Or manually configure:
  aida-init --project
```

#### Pattern 2: Progress Indicators for Long Operations

```bash
$ aida-config-helper.sh --detect-vcs
Detecting VCS provider...
  [1/4] Checking git remote... ✓
  [2/4] Parsing remote URL... ✓
  [3/4] Identifying provider... ✓
  [4/4] Validating detection... ✓

Detected: GitHub
  Owner: oakensoul
  Repo: claude-personal-assistant

Save to project config:
  aida-config-helper.sh --apply-detection
```

#### Pattern 3: Dry-Run Mode

```bash
$ aida-config-helper.sh --apply-detection --dry-run
DRY RUN: No changes will be made

Would add to .aida/config.json:
  {
    "vcs": {
      "provider": "github",
      "url": "https://github.com"
    },
    "github": {
      "owner": "oakensoul",
      "repo": "claude-personal-assistant",
      "main_branch": "main"
    }
  }

To apply these changes:
  aida-config-helper.sh --apply-detection
```

### 4.3 Configuration Documentation Structure

#### Recommended Documentation Hierarchy

```text
~/.aida/docs/configuration/
├── README.md                    # Overview and quick start
├── schema.md                    # Complete schema reference
├── auto-detection.md            # Auto-detection behavior
├── providers/
│   ├── github.md                # GitHub-specific config
│   ├── gitlab.md                # GitLab-specific config
│   └── bitbucket.md             # Bitbucket-specific config
├── examples/
│   ├── single-project.md        # Solo developer
│   ├── team-project.md          # Team configuration
│   └── multi-vcs.md             # Multiple VCS providers
└── troubleshooting.md           # Common issues
```

#### Quick Reference Card (add to --help)

```bash
$ aida-config-helper.sh --help

QUICK REFERENCE

Get config:
  aida-config-helper.sh                    # Full config
  aida-config-helper.sh --key vcs.provider # Specific value
  aida-config-helper.sh --namespace github # Namespace

Set config:
  aida-config-helper.sh --set KEY VALUE    # Set value
  aida-config-helper.sh --unset KEY        # Remove value

Validation:
  aida-config-helper.sh --validate         # Check config
  aida-config-helper.sh --detect-vcs       # Auto-detect VCS

Discovery:
  aida-config-helper.sh --schema           # List all namespaces
  aida-config-helper.sh --schema vcs       # Namespace details

Setup:
  aida-init                                # Interactive wizard
  aida-init --project                      # Project setup

CONFIGURATION PRIORITY (highest → lowest):
  1. Environment variables (VCS_PROVIDER=github)
  2. Project config (.aida/config.json)
  3. User config (~/.claude/config.json)
  4. Git config (.git/config)
  5. Auto-detection (git remote -v)
  6. System defaults (~/.aida/config.json)

See full help: aida-config-helper.sh --help [topic]
Topics: vcs, github, gitlab, bitbucket, workflow
```

### 4.4 User Guidance for Common Scenarios

#### Scenario 1: GitHub to GitLab Migration

```bash
$ aida-config-helper.sh --help migrate

MIGRATING VCS PROVIDERS

Scenario: Moving from GitHub to GitLab

Current state:
  VCS: GitHub
  Project: oakensoul/claude-personal-assistant

Target state:
  VCS: GitLab
  Project: company-group/claude-personal-assistant

Steps:
  1. Update git remote:
     git remote set-url origin git@gitlab.com:company-group/claude-personal-assistant.git

  2. Update VCS config:
     aida-config-helper.sh --set vcs.provider gitlab
     aida-config-helper.sh --set gitlab.project_id 12345678

  3. Validate:
     aida-config-helper.sh --validate

  4. Clear cache:
     aida-config-helper.sh --clear-cache

Note: Some commands may need updates for GitLab API differences.
See: ~/.aida/docs/configuration/providers/gitlab.md
```

#### Scenario 2: Team Onboarding

```bash
$ aida-config-helper.sh --help team

TEAM CONFIGURATION

Scenario: New team member setup

As a team member:
  1. Clone repository:
     git clone git@github.com:oakensoul/claude-personal-assistant.git

  2. Install AIDA:
     ./install.sh

  3. Initialize configuration:
     aida-init

     This will:
     ✓ Auto-detect VCS from git remote
     ✓ Load team defaults from .aida/config.json
     ✓ Create personal config at ~/.claude/config.json

  4. Override team defaults (optional):
     Edit: ~/.claude/config.json
     Or use: .aida/config.local.json (gitignored)

As a team lead:
  1. Create team template:
     cp .aida/config.json .aida/config.json.example
     Add comments explaining each field

  2. Document team conventions:
     Create: .aida/README.md
     Include: VCS provider, issue tracker, workflow preferences

  3. Commit team config:
     git add .aida/config.json .aida/README.md
     git commit -m "Add AIDA team configuration"
```

#### Scenario 3: Multi-Project Workflow

```bash
$ aida-config-helper.sh --help multi-project

MULTI-PROJECT CONFIGURATION

Scenario: Working across multiple projects with different VCS providers

Project A (GitHub):
  ~/work/project-a/.aida/config.json:
  {
    "vcs": {"provider": "github"},
    "github": {"owner": "company", "repo": "project-a"}
  }

Project B (GitLab):
  ~/work/project-b/.aida/config.json:
  {
    "vcs": {"provider": "gitlab"},
    "gitlab": {"project_id": "12345"}
  }

User defaults:
  ~/.claude/config.json:
  {
    "user": {"assistant_name": "jarvis"},
    "workflow": {"commit": {"auto_commit": true}}
  }

Behavior:
  - User config applies to ALL projects
  - Project config overrides for specific project
  - VCS provider auto-switches based on project

Validate current project:
  cd ~/work/project-a
  aida-config-helper.sh --validate  # Uses GitHub config

  cd ~/work/project-b
  aida-config-helper.sh --validate  # Uses GitLab config
```

---

## Summary of UX Improvements Needed

### Critical (Must Have)

1. **Auto-detection feedback** - Users must see what was detected
2. **Provider-specific validation** - Clear errors for missing GitHub/GitLab/Bitbucket fields
3. **Interactive wizard** - `aida-init` command for first-time setup
4. **Schema discovery** - `--schema` flag to show available config keys

### Important (Should Have)

5. **Contextual error messages** - Differentiate first-time vs. missing field vs. invalid value
6. **CLI config editing** - `--set` and `--unset` flags for easy config updates
7. **Dry-run mode** - `--dry-run` for auto-detection and config changes
8. **Team templates** - Documentation and examples for team configuration

### Nice to Have (Could Have)

9. **Migration guide** - Help for switching VCS providers
10. **Multi-project docs** - Guidance for working across projects
11. **Machine-readable output** - JSON format for CI/CD validation
12. **Progress indicators** - Feedback for long-running detection operations

---

## Files to Create/Update

### New Files

- `~/.aida/docs/configuration/schema.md` - Complete config schema
- `~/.aida/docs/configuration/auto-detection.md` - Auto-detection behavior
- `~/.aida/docs/configuration/providers/github.md` - GitHub config guide
- `~/.aida/docs/configuration/providers/gitlab.md` - GitLab config guide
- `~/.aida/templates/config/project-config.json` - Project config template

### Update Files

- `lib/aida-config-helper.sh` - Add `--schema`, `--set`, `--detect-vcs`, `--wizard`
- `lib/aida-config-helper.sh` - Improve error messages (use templates above)
- `lib/aida-config-helper.sh` - Add provider-specific validation
- `templates/commands/aida-init.md` - Create interactive setup wizard

---

## Exit Codes for Scripting

Recommend standardizing exit codes:

- `0` - Success (config valid)
- `1` - General error (invalid config)
- `2` - File not found (config file missing)
- `3` - Parse error (invalid JSON)
- `4` - Auto-detection failed
- `5` - Validation failed (missing required fields)
- `10` - User cancellation (wizard)

---

**Analysis Complete**: 2025-10-20

**Next Steps**:

1. Review with product manager for requirements alignment
2. Prioritize UX improvements (critical vs. nice-to-have)
3. Create technical specification for implementation
4. Design error message templates for each provider
5. Build interactive wizard mockup/prototype
