---
title: "Quick Reference - Config Aggregator"
description: "Quick reference for aida-config-helper.sh usage patterns"
category: "development"
tags: ["config", "quick-reference", "cheatsheet"]
last_updated: "2025-10-18"
status: "published"
audience: "developers"
---

# Quick Reference - Config Aggregator

## Command-Line Usage

```bash
# Get full config
aida-config-helper.sh

# Get specific value
aida-config-helper.sh --key paths.aida_home

# Get namespace
aida-config-helper.sh --namespace github

# Validate config
aida-config-helper.sh --validate

# Clear cache
aida-config-helper.sh --clear-cache

# Help
aida-config-helper.sh --help
```

## Common Patterns

### In Workflow Commands

```bash
#!/usr/bin/env bash
readonly CONFIG_HELPER="${AIDA_HOME}/lib/aida-config-helper.sh"

# Get config
GITHUB_CONFIG=$("$CONFIG_HELPER" --namespace github)
OWNER=$(echo "$GITHUB_CONFIG" | jq -r '.owner')
REPO=$(echo "$GITHUB_CONFIG" | jq -r '.repo')

# Validate first
"$CONFIG_HELPER" --validate || exit 1
```

### In Install Scripts

```bash
# Get paths
AIDA_HOME=$("$CONFIG_HELPER" --key paths.aida_home)
CLAUDE_CONFIG_DIR=$("$CONFIG_HELPER" --key paths.claude_config_dir)
```

## Key Paths

**Paths**:

- `paths.aida_home` - AIDA installation
- `paths.claude_config_dir` - User config
- `paths.project_root` - Current project
- `paths.git_root` - Git repository
- `paths.home` - User home

**GitHub**:

- `github.owner` - Repository owner
- `github.repo` - Repository name
- `github.main_branch` - Main branch

**Workflow**:

- `workflow.commit.auto_commit` - Auto-commit
- `workflow.pr.auto_version_bump` - Auto-version
- `workflow.versioning.enabled` - Versioning

**Environment**:

- `env.github_token` - GitHub token
- `env.editor` - Text editor

## Config Priority

1. Environment variables (highest)
2. Project AIDA config
3. Workflow config
4. GitHub config
5. Git config
6. User AIDA config
7. System defaults (lowest)

## Performance Tips

1. **Use namespace for related config** (1 call vs many)
2. **Cache is automatic** (90% faster on subsequent calls)
3. **Validate early** (fail fast on invalid config)
4. **Clear cache when testing** (ensure fresh config)

## Testing

```bash
# Run validation tests
./lib/installer-common/validate-config-helper.sh

# Run examples
./lib/installer-common/EXAMPLE-config-usage.sh
```

## Files

- **Module**: `lib/aida-config-helper.sh`
- **Validation**: `lib/installer-common/validate-config-helper.sh`
- **Documentation**: `lib/installer-common/README-config-aggregator.md`
- **Examples**: `lib/installer-common/EXAMPLE-config-usage.sh`
- **Quick Ref**: `lib/installer-common/QUICK-REFERENCE-config.md`

---

**For complete documentation**: See `README-config-aggregator.md`
