---
title: "AIDA Config Skill"
description: "Fast, cached configuration access for all AIDA agents and commands"
category: "guide"
tags: ["skill", "configuration", "utility", "agent-tool"]
skill_type: "utility"
provides: ["config-reading", "path-resolution", "variable-resolution"]
dependencies: ["aida-config-helper.sh"]
version: "1.0"
last_updated: "2025-10-18"
status: "published"
audience: "developers"
---

# AIDA Config Skill

Fast, cached configuration access for all AIDA agents and commands.

## Overview

The AIDA Config skill provides unified access to configuration from 7 sources with automatic caching and priority resolution. Use this skill whenever you need configuration values for paths, credentials, workflow settings, or environment variables.

**Key Benefits**:

- **Single source of truth**: All configuration in one place
- **Smart caching**: First call ~500ms, subsequent calls ~50ms
- **Priority resolution**: Automatic merging from multiple sources
- **Type-safe access**: JSON output for reliable parsing
- **Environment aware**: Automatically detects project context

## Quick Start

### Get Full Configuration

```bash
CONFIG=$(aida-config-helper.sh)
echo "$CONFIG" | jq .
```

### Get Specific Value

```bash
AIDA_HOME=$(aida-config-helper.sh --key paths.aida_home)
echo "AIDA installed at: $AIDA_HOME"
```

### Get Namespace

Get all configuration under a specific namespace (e.g., all `github.*` config):

```bash
GITHUB_CONFIG=$(aida-config-helper.sh --namespace github)
OWNER=$(echo "$GITHUB_CONFIG" | jq -r '.owner')
REPO=$(echo "$GITHUB_CONFIG" | jq -r '.repo')
```

### Validate Configuration

```bash
aida-config-helper.sh --validate
# Exits 0 if valid, 1 if invalid
```

## What This Skill Provides

### Configuration Sources (Priority Order)

The helper merges configuration from 7 sources in priority order (highest first):

1. **Environment variables** (`ENV_VAR=value`) - Runtime overrides
2. **Project config** (`${PROJECT_ROOT}/.aida/config.json`) - Project-specific settings
3. **Workflow config** (`${PROJECT_ROOT}/.aida/workflow-config.json`) - Workflow automation
4. **GitHub config** (`${PROJECT_ROOT}/.aida/github-config.json`) - GitHub integration
5. **Git config** (`~/.gitconfig`) - Git user settings
6. **User config** (`~/.claude/config.json`) - User preferences
7. **System config** (`~/.aida/config.json`) - System defaults

### Capabilities

- **Path resolution**: All key paths (AIDA_HOME, PROJECT_ROOT, GIT_ROOT, CLAUDE_CONFIG_DIR)
- **User settings**: Personality, assistant name, preferences
- **Git identity**: User name and email from gitconfig
- **GitHub integration**: Owner, repo, main branch, credentials
- **Workflow automation**: Auto-commit, PR settings, branch patterns
- **Environment variables**: Tokens, API keys, editor, shell settings
- **Validation**: Check configuration validity
- **Caching**: Session-based performance optimization

## Usage Patterns

### Pattern 1: Get Paths for File Operations

```bash
# Get project paths
PROJECT_ROOT=$(aida-config-helper.sh --key paths.project_root)
GIT_ROOT=$(aida-config-helper.sh --key paths.git_root)

# Create issue directory
ISSUE_DIR="${PROJECT_ROOT}/.github/issues/in-progress/issue-${NUM}"
mkdir -p "$ISSUE_DIR"

# Read from knowledge base
KNOWLEDGE_DIR=$(aida-config-helper.sh --key paths.claude_config_dir)
cat "${KNOWLEDGE_DIR}/knowledge/workflows/start-work.md"
```

### Pattern 2: Get Workflow Configuration

```bash
# Check if auto-commit is enabled
AUTO_COMMIT=$(aida-config-helper.sh --key workflow.commit.auto_commit)
if [[ "$AUTO_COMMIT" == "true" ]]; then
  git add .
  git commit -m "feat: implement feature"
fi

# Get commit message prefix
PREFIX=$(aida-config-helper.sh --key workflow.commit.message_prefix)
git commit -m "${PREFIX}: add new feature"

# Check if PRs should be draft
DRAFT=$(aida-config-helper.sh --key workflow.pr.draft)
gh pr create ${DRAFT:+--draft} --title "..."
```

### Pattern 3: Get GitHub Credentials

```bash
# Authenticate with GitHub
GITHUB_TOKEN=$(aida-config-helper.sh --key env.github_token)
gh auth login --with-token <<< "$GITHUB_TOKEN"

# Get repository info
OWNER=$(aida-config-helper.sh --key github.owner)
REPO=$(aida-config-helper.sh --key github.repo)
MAIN_BRANCH=$(aida-config-helper.sh --key github.main_branch)

# Use in API calls
gh api "repos/${OWNER}/${REPO}/issues"
```

### Pattern 4: Cache Config at Command Start (RECOMMENDED)

```bash
#!/bin/bash
set -euo pipefail

# Cache once at command start
readonly CONFIG=$(aida-config-helper.sh)

# Extract multiple values (fast - from memory)
readonly OWNER=$(echo "$CONFIG" | jq -r '.github.owner')
readonly REPO=$(echo "$CONFIG" | jq -r '.github.repo')
readonly BRANCH=$(echo "$CONFIG" | jq -r '.github.main_branch')
readonly AUTO_COMMIT=$(echo "$CONFIG" | jq -r '.workflow.commit.auto_commit')
readonly PROJECT_ROOT=$(echo "$CONFIG" | jq -r '.paths.project_root')

# Use values throughout command
gh api "repos/${OWNER}/${REPO}/branches/${BRANCH}"
cd "$PROJECT_ROOT"
[[ "$AUTO_COMMIT" == "true" ]] && git commit -m "update"
```

### Pattern 5: Get User Preferences

```bash
# Get personality and assistant name
PERSONALITY=$(aida-config-helper.sh --key user.personality)
ASSISTANT_NAME=$(aida-config-helper.sh --key user.assistant_name)

echo "Hello, I'm ${ASSISTANT_NAME} (${PERSONALITY} personality)"

# Get editor preference
EDITOR=$(aida-config-helper.sh --key env.editor)
"$EDITOR" myfile.txt
```

### Pattern 6: Check Configuration Validity

```bash
# Validate before using
if aida-config-helper.sh --validate; then
  CONFIG=$(aida-config-helper.sh)
  # Proceed with valid config
else
  echo "ERROR: Invalid configuration" >&2
  exit 1
fi
```

### Pattern 7: Get Namespace for Related Settings

```bash
# Get all GitHub settings at once
GITHUB_CONFIG=$(aida-config-helper.sh --namespace github)

# Extract individual values
OWNER=$(echo "$GITHUB_CONFIG" | jq -r '.owner')
REPO=$(echo "$GITHUB_CONFIG" | jq -r '.repo')
MAIN_BRANCH=$(echo "$GITHUB_CONFIG" | jq -r '.main_branch')
DEFAULT_REVIEWERS=$(echo "$GITHUB_CONFIG" | jq -r '.default_reviewers[]?')

echo "Repository: ${OWNER}/${REPO}"
echo "Main branch: ${MAIN_BRANCH}"
echo "Default reviewers: ${DEFAULT_REVIEWERS}"
```

## Configuration Schema

### Complete Structure

```json
{
  "system": {
    "config_version": "1.0",
    "cache_enabled": true
  },
  "paths": {
    "aida_home": "/Users/rob/.aida",
    "claude_config_dir": "/Users/rob/.claude",
    "project_root": "/Users/rob/projects/myapp",
    "git_root": "/Users/rob/projects/myapp",
    "home": "/Users/rob"
  },
  "user": {
    "assistant_name": "jarvis",
    "personality": "JARVIS"
  },
  "git": {
    "user": {
      "name": "Rob Smith",
      "email": "rob@example.com"
    }
  },
  "github": {
    "owner": "oakensoul",
    "repo": "claude-personal-assistant",
    "main_branch": "main",
    "default_reviewers": ["teammate1", "teammate2"]
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
    "branch": {
      "prefix": "feature",
      "include_issue_number": true
    }
  },
  "env": {
    "github_token": "ghp_xxx",
    "editor": "vim",
    "shell": "/bin/bash",
    "pager": "less"
  }
}
```

### Key Namespaces

#### `system.*` - System Settings

- `config_version`: Configuration schema version
- `cache_enabled`: Whether caching is enabled

#### `paths.*` - File System Paths

- `aida_home`: AIDA installation directory (e.g., `~/.aida`)
- `claude_config_dir`: Claude configuration directory (e.g., `~/.claude`)
- `project_root`: Current project root directory
- `git_root`: Git repository root directory
- `home`: User's home directory

#### `user.*` - User Preferences

- `assistant_name`: Name of AI assistant (e.g., "jarvis")
- `personality`: Personality type (e.g., "JARVIS", "Alfred")

#### `git.user.*` - Git Identity

- `name`: Git user name
- `email`: Git user email

#### `github.*` - GitHub Integration

- `owner`: GitHub username or organization
- `repo`: Repository name
- `main_branch`: Main branch name (e.g., "main", "master")
- `default_reviewers`: Array of default PR reviewers

#### `workflow.commit.*` - Commit Settings

- `auto_commit`: Auto-commit after each task (true/false)
- `message_prefix`: Default commit message prefix (e.g., "feat", "fix")

#### `workflow.pr.*` - Pull Request Settings

- `auto_reviewers`: Array of automatic PR reviewers
- `draft`: Create PRs as draft by default (true/false)

#### `workflow.branch.*` - Branch Settings

- `prefix`: Default branch prefix (e.g., "feature", "bugfix")
- `include_issue_number`: Include issue number in branch name (true/false)

#### `env.*` - Environment Variables

- `github_token`: GitHub personal access token
- `editor`: Preferred text editor
- `shell`: User's shell
- `pager`: Preferred pager

## Performance

### Session Caching

Configuration is cached per shell session (PID-based):

- **First call**: ~500ms (reads and merges all 7 config files)
- **Subsequent calls**: ~50ms (reads from cache)
- **Cache invalidation**: Automatic when config files change (mtime-based)
- **Cache location**: `/tmp/aida-config-cache-$$` (automatic cleanup on exit)

### Best Practices

**✅ Good - Cache once at start**:

```bash
# Cache full config once
readonly CONFIG=$(aida-config-helper.sh)

# Extract multiple values (fast - from memory)
value1=$(echo "$CONFIG" | jq -r '.key1')
value2=$(echo "$CONFIG" | jq -r '.key2')
value3=$(echo "$CONFIG" | jq -r '.key3')
```

**❌ Bad - Multiple helper calls**:

```bash
# Calls helper 3 times (slower, unnecessary I/O)
value1=$(aida-config-helper.sh --key key1)
value2=$(aida-config-helper.sh --key key2)
value3=$(aida-config-helper.sh --key key3)
```

### Cache Behavior

```bash
# First call - builds cache (~500ms)
CONFIG=$(aida-config-helper.sh)

# Second call - reads cache (~50ms)
AIDA_HOME=$(aida-config-helper.sh --key paths.aida_home)

# Edit config file
echo '{"user": {"personality": "Alfred"}}' > ~/.claude/config.json

# Next call - detects change, rebuilds cache (~500ms)
CONFIG=$(aida-config-helper.sh)
```

## Troubleshooting

### Issue: "aida-config-helper.sh: command not found"

**Cause**: Helper script not in PATH or not executable

**Solutions**:

```bash
# Option 1: Use full path
CONFIG=$(~/.aida/lib/aida-config-helper.sh)

# Option 2: Add to PATH (in ~/.bashrc or ~/.zshrc)
export PATH="$HOME/.aida/lib:$PATH"

# Option 3: Check executable permissions
chmod +x ~/.aida/lib/aida-config-helper.sh
```

### Issue: Empty or Invalid JSON Returned

**Cause**: Config file has syntax errors

**Solutions**:

```bash
# Validate configuration
aida-config-helper.sh --validate

# Check individual config files
jq . ~/.aida/config.json
jq . ~/.claude/config.json
jq . ./.aida/config.json

# Look for common errors
# - Missing commas
# - Trailing commas
# - Unquoted keys
# - Invalid JSON types
```

### Issue: Wrong Value Returned

**Cause**: Config priority mismatch - a higher-priority source is overriding

**Priority order** (highest first):

1. Environment variables
2. Project config (`.aida/config.json`)
3. Workflow config (`.aida/workflow-config.json`)
4. GitHub config (`.aida/github-config.json`)
5. Git config (`~/.gitconfig`)
6. User config (`~/.claude/config.json`)
7. System config (`~/.aida/config.json`)

**Solutions**:

```bash
# Check all sources
echo "Project config:"
jq . ./.aida/config.json 2>/dev/null || echo "Not found"

echo "User config:"
jq . ~/.claude/config.json 2>/dev/null || echo "Not found"

echo "System config:"
jq . ~/.aida/config.json 2>/dev/null || echo "Not found"

# Check environment variables
env | grep -E '^(AIDA|GITHUB|WORKFLOW)_'

# Get merged result
aida-config-helper.sh | jq .
```

### Issue: Slow Performance

**Cause**: Cache not working or being invalidated frequently

**Solutions**:

```bash
# Check cache exists
ls -lh /tmp/aida-config-cache-$$

# Check cache permissions
test -r /tmp/aida-config-cache-$$ && echo "Readable" || echo "Not readable"

# Disable cache for debugging
rm /tmp/aida-config-cache-$$
CONFIG=$(aida-config-helper.sh)

# Check for frequent config changes
watch -n 1 'stat -f "%Sm" ~/.claude/config.json'
```

### Issue: "jq: command not found"

**Cause**: `jq` not installed (required dependency)

**Solutions**:

```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install jq

# RHEL/CentOS
sudo yum install jq
```

### Issue: Null or Missing Values

**Cause**: Key doesn't exist in any config source

**Solutions**:

```bash
# Check if key exists
VALUE=$(aida-config-helper.sh --key some.nested.key)
if [[ "$VALUE" == "null" ]] || [[ -z "$VALUE" ]]; then
  echo "Key not found, using default"
  VALUE="default-value"
fi

# Provide default in jq
VALUE=$(echo "$CONFIG" | jq -r '.some.nested.key // "default-value"')

# Add to appropriate config file
# System defaults: ~/.aida/config.json
# User overrides: ~/.claude/config.json
# Project-specific: ./.aida/config.json
```

## Integration with Agents

### When to Use This Skill

Use the AIDA Config skill when your agent needs to:

- **Read paths**: AIDA_HOME, PROJECT_ROOT, CLAUDE_CONFIG_DIR
- **Get user preferences**: Personality, assistant name
- **Access credentials**: GitHub tokens, API keys
- **Check workflow settings**: Auto-commit, PR defaults
- **Get Git identity**: User name, email
- **Resolve GitHub info**: Owner, repo, main branch

### Agent Usage Example

```markdown
# Agent: start-work

## Configuration Loading

```bash
# Cache config at command start
readonly CONFIG=$(aida-config-helper.sh)

# Extract required values
readonly PROJECT_ROOT=$(echo "$CONFIG" | jq -r '.paths.project_root')
readonly OWNER=$(echo "$CONFIG" | jq -r '.github.owner')
readonly REPO=$(echo "$CONFIG" | jq -r '.github.repo')
readonly MAIN_BRANCH=$(echo "$CONFIG" | jq -r '.github.main_branch')
readonly BRANCH_PREFIX=$(echo "$CONFIG" | jq -r '.workflow.branch.prefix // "feature"')
```

## Command Logic

```bash
# Use cached config values
ISSUE_NUM=$1
BRANCH_NAME="${BRANCH_PREFIX}/issue-${ISSUE_NUM}"

# Create branch
git checkout -b "$BRANCH_NAME" "origin/${MAIN_BRANCH}"

# Update issue
gh api "repos/${OWNER}/${REPO}/issues/${ISSUE_NUM}" \
  --method PATCH \
  --field state="in_progress"
```
```

## Examples

See [EXAMPLES.md](./EXAMPLES.md) for extended real-world usage examples.

## Quick Reference

See [QUICKREF.md](./QUICKREF.md) for a one-page reference guide.

## Related Documentation

- **Implementation**: `~/.aida/lib/aida-config-helper.sh` - Source code
- **Testing**: `~/.aida/test/test-config.sh` - Test suite
- **Config Files**:
  - System: `~/.aida/config.json`
  - User: `~/.claude/config.json`
  - Project: `./.aida/config.json`
  - Workflow: `./.aida/workflow-config.json`
  - GitHub: `./.aida/github-config.json`

## Version History

- **v1.0** (2025-10-18): Initial skill documentation
