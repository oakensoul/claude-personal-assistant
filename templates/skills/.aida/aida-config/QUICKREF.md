---
title: "AIDA Config Skill - Quick Reference"
description: "One-page reference for AIDA Config skill usage"
category: "reference"
tags: ["skill", "configuration", "reference", "cheatsheet"]
last_updated: "2025-10-18"
status: "published"
audience: "developers"
---

# AIDA Config Skill - Quick Reference

One-page reference for fast lookups.

## Basic Usage

```bash
# Get full config
CONFIG=$(aida-config-helper.sh)

# Get specific key
VALUE=$(aida-config-helper.sh --key path.to.key)

# Get namespace
NAMESPACE=$(aida-config-helper.sh --namespace github)

# Validate config
aida-config-helper.sh --validate
```

## Common Keys

### Paths

```bash
AIDA_HOME=$(aida-config-helper.sh --key paths.aida_home)
CLAUDE_CONFIG=$(aida-config-helper.sh --key paths.claude_config_dir)
PROJECT_ROOT=$(aida-config-helper.sh --key paths.project_root)
GIT_ROOT=$(aida-config-helper.sh --key paths.git_root)
HOME=$(aida-config-helper.sh --key paths.home)
```

### GitHub

```bash
OWNER=$(aida-config-helper.sh --key github.owner)
REPO=$(aida-config-helper.sh --key github.repo)
MAIN_BRANCH=$(aida-config-helper.sh --key github.main_branch)
GITHUB_TOKEN=$(aida-config-helper.sh --key env.github_token)
```

### Git Identity

```bash
GIT_NAME=$(aida-config-helper.sh --key git.user.name)
GIT_EMAIL=$(aida-config-helper.sh --key git.user.email)
```

### Workflow

```bash
AUTO_COMMIT=$(aida-config-helper.sh --key workflow.commit.auto_commit)
COMMIT_PREFIX=$(aida-config-helper.sh --key workflow.commit.message_prefix)
DRAFT_PR=$(aida-config-helper.sh --key workflow.pr.draft)
AUTO_REVIEWERS=$(aida-config-helper.sh --key 'workflow.pr.auto_reviewers[]')
```

### User Preferences

```bash
PERSONALITY=$(aida-config-helper.sh --key user.personality)
ASSISTANT_NAME=$(aida-config-helper.sh --key user.assistant_name)
```

## Configuration Priority

**Highest → Lowest**:

1. Environment variables (`ENV_VAR=value`)
2. Project config (`.aida/config.json`)
3. Workflow config (`.aida/workflow-config.json`)
4. GitHub config (`.aida/github-config.json`)
5. Git config (`~/.gitconfig`)
6. User config (`~/.claude/config.json`)
7. System config (`~/.aida/config.json`)

## Performance Tips

```bash
# ✅ GOOD - Cache once, use multiple times
CONFIG=$(aida-config-helper.sh)
VAL1=$(echo "$CONFIG" | jq -r '.key1')
VAL2=$(echo "$CONFIG" | jq -r '.key2')

# ❌ BAD - Multiple helper calls
VAL1=$(aida-config-helper.sh --key key1)
VAL2=$(aida-config-helper.sh --key key2)
```

## Common Patterns

### Cache at Script Start

```bash
#!/bin/bash
set -euo pipefail

# Cache config once
readonly CONFIG=$(aida-config-helper.sh)

# Extract values
readonly OWNER=$(echo "$CONFIG" | jq -r '.github.owner')
readonly REPO=$(echo "$CONFIG" | jq -r '.github.repo')
```

### Provide Defaults

```bash
# Using jq default operator
VALUE=$(echo "$CONFIG" | jq -r '.some.key // "default-value"')

# Using shell parameter expansion
VALUE=$(aida-config-helper.sh --key some.key)
VALUE=${VALUE:-"default-value"}
```

### Conditional Behavior

```bash
AUTO_COMMIT=$(aida-config-helper.sh --key workflow.commit.auto_commit)
if [[ "$AUTO_COMMIT" == "true" ]]; then
  git commit -m "auto commit"
fi
```

### Get Array Values

```bash
# Get all array elements
REVIEWERS=$(echo "$CONFIG" | jq -r '.workflow.pr.auto_reviewers[]?')

# Iterate over array
echo "$CONFIG" | jq -r '.workflow.pr.auto_reviewers[]?' | while read -r reviewer; do
  echo "Reviewer: $reviewer"
done
```

## Namespace Shortcuts

```bash
# Get all GitHub config at once
GITHUB=$(aida-config-helper.sh --namespace github)
OWNER=$(echo "$GITHUB" | jq -r '.owner')
REPO=$(echo "$GITHUB" | jq -r '.repo')

# Get all workflow config
WORKFLOW=$(aida-config-helper.sh --namespace workflow)
AUTO_COMMIT=$(echo "$WORKFLOW" | jq -r '.commit.auto_commit')
```

## Validation

```bash
# Validate before use
if ! aida-config-helper.sh --validate; then
  echo "Invalid configuration" >&2
  exit 1
fi

# Validate specific file
jq . ~/.claude/config.json || echo "Invalid JSON"
```

## Troubleshooting

### Command Not Found

```bash
# Use full path
CONFIG=$(~/.aida/lib/aida-config-helper.sh)

# Or add to PATH
export PATH="$HOME/.aida/lib:$PATH"
```

### Empty/Null Values

```bash
# Check for null
VALUE=$(aida-config-helper.sh --key some.key)
if [[ "$VALUE" == "null" ]] || [[ -z "$VALUE" ]]; then
  echo "Key not found"
fi

# Provide default
VALUE=$(echo "$CONFIG" | jq -r '.some.key // "default"')
```

### Wrong Value

```bash
# Check all config sources
jq . ~/.aida/config.json      # System
jq . ~/.claude/config.json    # User
jq . ./.aida/config.json      # Project

# Check environment variables
env | grep -E '^(AIDA|GITHUB|WORKFLOW)_'
```

### Invalid JSON

```bash
# Validate each config file
for file in ~/.aida/config.json ~/.claude/config.json ./.aida/*.json; do
  if [[ -f "$file" ]]; then
    echo "Checking $file..."
    jq . "$file" || echo "INVALID: $file"
  fi
done
```

## Configuration Schema

```json
{
  "system": {"config_version": "1.0", "cache_enabled": true},
  "paths": {
    "aida_home": "/Users/user/.aida",
    "claude_config_dir": "/Users/user/.claude",
    "project_root": "/path/to/project",
    "git_root": "/path/to/project",
    "home": "/Users/user"
  },
  "user": {
    "assistant_name": "jarvis",
    "personality": "JARVIS"
  },
  "git": {
    "user": {"name": "Name", "email": "email@example.com"}
  },
  "github": {
    "owner": "username",
    "repo": "repository",
    "main_branch": "main",
    "default_reviewers": ["user1"]
  },
  "workflow": {
    "commit": {"auto_commit": true, "message_prefix": "feat"},
    "pr": {"auto_reviewers": ["user1"], "draft": false},
    "branch": {"prefix": "feature", "include_issue_number": true}
  },
  "env": {
    "github_token": "ghp_xxx",
    "editor": "vim",
    "shell": "/bin/bash"
  }
}
```

## Cache Details

- **Location**: `/tmp/aida-config-cache-$$`
- **Lifetime**: Shell session (PID-based)
- **Invalidation**: Automatic on config file changes
- **Performance**: First call ~500ms, cached ~50ms

## Related Files

- **Helper**: `~/.aida/lib/aida-config-helper.sh`
- **System**: `~/.aida/config.json`
- **User**: `~/.claude/config.json`
- **Project**: `./.aida/config.json`
- **Workflow**: `./.aida/workflow-config.json`
- **GitHub**: `./.aida/github-config.json`

## See Also

- [README.md](./README.md) - Complete documentation
- [EXAMPLES.md](./EXAMPLES.md) - Extended examples
