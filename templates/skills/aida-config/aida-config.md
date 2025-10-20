---
name: aida-config
version: 1.0.0
category: meta
description: Fast, cached configuration access for all AIDA agents and commands with automatic priority resolution
short_description: Unified configuration access with caching and multi-source merging
tags: [configuration, utility, caching, multi-source, priority-resolution]
used_by: [all-agents, all-commands]
depends_on: [aida-config-helper.sh]
last_updated: "2025-10-20"
---

# AIDA Config Meta-Skill

This skill provides comprehensive knowledge about AIDA's configuration system, enabling intelligent configuration access, validation, and troubleshooting across all agents and commands.

## Purpose

This meta-skill enables the AIDA system to:

- **Access** configuration from 7 different sources with automatic priority resolution
- **Cache** configuration for optimal performance (~50ms for cached calls)
- **Validate** configuration syntax and required fields
- **Merge** configuration across system, user, project, and environment levels
- **Resolve** paths and variables dynamically
- **Debug** configuration issues with comprehensive tooling

## Configuration System Overview

### What is AIDA Configuration?

AIDA configuration provides a **unified, hierarchical system** for managing settings across multiple levels:

- System-level defaults (`~/.aida/config.json`)
- User preferences (`~/.claude/config.json`)
- Project-specific settings (`./.aida/config.json`)
- Workflow automation (`./.aida/workflow-config.json`)
- Environment variables (highest priority)

### Seven Configuration Sources (Priority Order)

**Highest → Lowest Priority**:

1. **Environment Variables** - Runtime overrides (`WORKFLOW_COMMIT_AUTO_COMMIT=false`)
2. **Project Config** - Project-specific settings (`./.aida/config.json`)
3. **Workflow Config** - Workflow automation (`./.aida/workflow-config.json`)
4. **GitHub Config** - Repository settings (`./.aida/github-config.json`)
5. **Git Config** - Git identity (`~/.gitconfig`)
6. **User Config** - User preferences (`~/.claude/config.json`)
7. **System Config** - Framework defaults (`~/.aida/config.json`)

## Configuration Helper

### Core Tool: `aida-config-helper.sh`

Central script that:

- Merges configuration from all sources
- Caches results for performance
- Provides simple query interface
- Validates configuration syntax

**Location**: `~/.aida/lib/aida-config-helper.sh`

### Basic Usage Patterns

**Get full merged configuration**:

```bash
CONFIG=$(aida-config-helper.sh)
echo "$CONFIG" | jq .
```

**Get specific key**:

```bash
AIDA_HOME=$(aida-config-helper.sh --key paths.aida_home)
```

**Get namespace**:

```bash
GITHUB_CONFIG=$(aida-config-helper.sh --namespace github)
OWNER=$(echo "$GITHUB_CONFIG" | jq -r '.owner')
```

**Validate configuration**:

```bash
aida-config-helper.sh --validate
```

## Configuration Schema

### Paths Namespace

Core system paths:

```json
{
  "paths": {
    "aida_home": "${HOME}/.aida",
    "claude_config_dir": "${HOME}/.claude",
    "project_root": "/path/to/project",
    "git_root": "/path/to/project",
    "home": "${HOME}"
  }
}
```

### User Namespace

User preferences:

```json
{
  "user": {
    "assistant_name": "jarvis",
    "personality": "JARVIS"
  }
}
```

### Git Namespace

Git identity:

```json
{
  "git": {
    "user": {
      "name": "Your Name",
      "email": "email@example.com"
    }
  }
}
```

### GitHub Namespace

Repository settings:

```json
{
  "github": {
    "owner": "username",
    "repo": "repository",
    "main_branch": "main",
    "default_reviewers": ["user1", "user2"]
  }
}
```

### Workflow Namespace

Workflow automation settings:

```json
{
  "workflow": {
    "commit": {
      "auto_commit": true,
      "message_prefix": "feat"
    },
    "pr": {
      "draft": false,
      "auto_reviewers": ["user1"]
    },
    "branch": {
      "prefix": "feature",
      "include_issue_number": true
    }
  }
}
```

### Environment Namespace

Environment variables:

```json
{
  "env": {
    "github_token": "ghp_xxx",
    "editor": "vim",
    "shell": "/bin/bash"
  }
}
```

## Performance and Caching

### Caching Strategy

- **Location**: `/tmp/aida-config-cache-$$` (PID-based)
- **Lifetime**: Shell session duration
- **Invalidation**: Automatic on config file modification
- **Performance**:

  - First call: ~500ms (merge + validation)
  - Cached calls: ~50ms (read from cache)

### Best Practices

**✅ Cache configuration at script start**:

```bash
#!/bin/bash
set -euo pipefail

# Cache once
readonly CONFIG=$(aida-config-helper.sh)

# Extract multiple values from cache
readonly OWNER=$(echo "$CONFIG" | jq -r '.github.owner')
readonly REPO=$(echo "$CONFIG" | jq -r '.github.repo')
readonly MAIN_BRANCH=$(echo "$CONFIG" | jq -r '.github.main_branch')
```

**❌ Don't call helper multiple times**:

```bash
# BAD - Multiple helper calls
OWNER=$(aida-config-helper.sh --key github.owner)
REPO=$(aida-config-helper.sh --key github.repo)
MAIN_BRANCH=$(aida-config-helper.sh --key github.main_branch)
```

## Agent Integration

### When Agents Should Use This Skill

- Loading configuration to understand context
- Getting paths to knowledge bases
- Determining project vs user context
- Accessing credentials and tokens
- Reading workflow preferences
- Adapting behavior based on settings

### Example: Agent Loading Configuration

```bash
# Agent initialization
CONFIG=$(aida-config-helper.sh)

# Determine context
PROJECT_ROOT=$(echo "$CONFIG" | jq -r '.paths.project_root')
if [[ "$PROJECT_ROOT" != "null" ]] && [[ -d "$PROJECT_ROOT" ]]; then
  CONTEXT="project"
  echo "Working in project: $PROJECT_ROOT"
else
  CONTEXT="user"
  echo "Working in user context"
fi

# Load appropriate knowledge base
CLAUDE_CONFIG=$(echo "$CONFIG" | jq -r '.paths.claude_config_dir')
if [[ "$CONTEXT" == "project" ]]; then
  KNOWLEDGE_BASE="$PROJECT_ROOT/.aida/agents/${AGENT_NAME}/knowledge"
else
  KNOWLEDGE_BASE="$CLAUDE_CONFIG/agents/${AGENT_NAME}/knowledge"
fi
```

## Command Integration

### When Commands Should Use This Skill

- Accessing GitHub repository info
- Getting workflow automation settings
- Determining branch naming conventions
- Loading git identity for commits
- Checking auto-commit preferences
- Reading PR configuration

### Example: Command Using Configuration

```bash
#!/bin/bash
set -euo pipefail

# Load configuration once
readonly CONFIG=$(aida-config-helper.sh)

# Extract workflow settings
readonly AUTO_COMMIT=$(echo "$CONFIG" | jq -r '.workflow.commit.auto_commit // true')
readonly COMMIT_PREFIX=$(echo "$CONFIG" | jq -r '.workflow.commit.message_prefix // "feat"')

# Use settings
if [[ "$AUTO_COMMIT" == "true" ]]; then
  git commit -m "${COMMIT_PREFIX}: ${TASK_DESCRIPTION}"
fi
```

## Validation and Debugging

### Configuration Validation

**Validate syntax**:

```bash
aida-config-helper.sh --validate
```

**Check specific files**:

```bash
jq . ~/.aida/config.json
jq . ~/.claude/config.json
jq . ./.aida/config.json
```

### Debugging Configuration Issues

**Common issues and solutions**:

1. **Empty or null values**
   - Check all configuration sources in priority order
   - Verify JSON syntax in config files
   - Check environment variables

2. **Wrong priority**
   - Remember: Environment > Project > Workflow > GitHub > Git > User > System
   - Use `aida-config-helper.sh` to see merged result

3. **Invalid JSON**
   - Validate each config file with `jq .`
   - Check for trailing commas, missing quotes

4. **Missing helper script**
   - Verify `~/.aida/lib/aida-config-helper.sh` exists
   - Check it's executable: `chmod +x ~/.aida/lib/aida-config-helper.sh`

## Supporting Documentation

This skill is supported by comprehensive documentation:

- **README.md** - Full skill documentation with detailed examples
- **QUICKREF.md** - One-page quick reference for common tasks
- **EXAMPLES.md** - Extended real-world usage examples

## Integration with AIDA Commands

### Commands That Use This Skill

All AIDA workflow commands use this skill:

- `/start-work` - Branch naming, issue tracking
- `/implement` - Auto-commit behavior
- `/open-pr` - PR configuration, reviewers
- `/cleanup-main` - Branch cleanup, stash management

### How Commands Use This Skill

1. **Command invoked** by user (e.g., `/start-work 123`)
2. **Command loads** configuration via this skill
3. **Command extracts** needed values (owner, repo, branch prefix, etc.)
4. **Command executes** using configuration-driven behavior

## Best Practices

### Configuration Organization

- **System config**: Framework defaults only
- **User config**: Personal preferences and identity
- **Project config**: Project-specific settings and overrides
- **Environment**: Temporary runtime overrides (CI, testing)

### Default Values

Always provide sensible defaults:

```bash
# Using jq default operator
AUTO_COMMIT=$(echo "$CONFIG" | jq -r '.workflow.commit.auto_commit // true')

# Using shell parameter expansion
AUTO_COMMIT=$(aida-config-helper.sh --key workflow.commit.auto_commit)
AUTO_COMMIT=${AUTO_COMMIT:-true}
```

### Configuration Security

- **Never commit secrets** to config files
- **Use environment variables** for sensitive data
- **Keep tokens in** `.env` files (git-ignored)
- **Use git config** for identity (already configured)

## Troubleshooting

### Configuration Not Found

**Symptoms**: `null` values or missing configuration

**Checks**:

1. Does config file exist?
2. Is JSON valid?
3. Are keys spelled correctly?
4. Is helper script accessible?

**Fix**: Create config file, validate JSON, fix key names

### Priority Not Working

**Symptoms**: Wrong value being used despite override

**Checks**:

1. Verify priority order
2. Check environment variables
3. Confirm config file locations
4. Test merged output

**Fix**: Adjust priority levels, move config to correct file

### Performance Issues

**Symptoms**: Slow configuration access

**Checks**:

1. Calling helper multiple times?
2. Cache invalidated repeatedly?
3. Large config files?

**Fix**: Cache config at script start, optimize config size

## Summary

The AIDA Config skill provides:

- **Unified access** to configuration from 7 sources
- **Automatic merging** with priority resolution
- **Performance caching** for fast repeated access
- **Simple interface** for agents and commands
- **Validation tools** for debugging
- **Comprehensive documentation** for all use cases

**Key Principle**: Load configuration once, cache it, extract multiple values from the cache.

---

**Version**: 1.0.0
**Last Updated**: 2025-10-20
**Maintained By**: AIDA Framework Team
