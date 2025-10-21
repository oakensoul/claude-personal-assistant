---
title: "Configuration Migration Guide: v1.0 → v2.0"
description: "Upgrading AIDA configuration to new schema with VCS provider abstraction"
category: "migration"
tags: ["migration", "configuration", "upgrade", "schema"]
last_updated: "2025-10-20"
status: "published"
audience: "users"
---

# Configuration Migration Guide

## Overview

AIDA v0.2.0 introduces a new configuration schema (v2.0) that replaces the GitHub-specific configuration with a flexible VCS provider abstraction system. This guide explains what changed, how to migrate your configuration, and how to roll back if needed.

### What Changed

**Schema Version**: v1.0 → v2.0

**Key Changes**:

1. **Namespace Reorganization**:
   - `github.*` → `vcs.github.*` (GitHub is now one of many VCS providers)
   - `workflow.pull_requests.reviewers` → `team.default_reviewers` (team-centric model)

2. **New Namespaces**:
   - `vcs.*` - Version control system configuration (GitHub, GitLab, Bitbucket)
   - `work_tracker.*` - Issue tracking system (GitHub Issues, Jira, Linear)
   - `team.*` - Team configuration (reviewers, members, timezone)

3. **Config File Location**:
   - Old: `~/.claude/aida-config.json`
   - New: `~/.claude/config.json`

4. **Security Improvements**:
   - User config now has 600 permissions (owner read/write only)
   - Config files added to .gitignore automatically

5. **VCS Auto-Detection**:
   - Automatically detects VCS provider from git remote URL
   - Populates configuration with detected values

### Why This Change

The old configuration was tightly coupled to GitHub. The new schema:

- **Supports multiple VCS providers**: GitHub, GitLab, Bitbucket, and more
- **Separates concerns**: VCS, work tracking, and team configuration
- **Enables auto-detection**: Zero-configuration setup for common scenarios
- **Improves security**: Proper file permissions and .gitignore integration
- **Future-proof**: Easy to add new providers without breaking changes

## Automatic Migration

### Via Installer

The installer automatically migrates your configuration when you upgrade:

```bash
# Run the installer
./install.sh

# The installer will:
# 1. Detect old config format
# 2. Create a backup (timestamped)
# 3. Transform to new schema
# 4. Validate the migration
# 5. Report any issues
```

**What Gets Migrated**:

- All existing configuration values
- Custom settings and overrides
- Multi-provider configurations

**What Gets Added**:

- `config_version: "2.0"` field
- New namespaces with defaults
- VCS auto-detected values

### Via Config Helper

You can also trigger migration manually:

```bash
# Check if migration needed
lib/aida-config-helper.sh --validate

# Migration happens automatically on next use
lib/aida-config-helper.sh | jq '.vcs'
```

The config helper checks for migration on every invocation and runs it automatically if needed.

### Via Migration Script

For manual control, use the migration script directly:

```bash
# Check config version
lib/installer-common/config-migration.sh detect-version ~/.claude/config.json

# Dry-run migration (see what would change)
lib/installer-common/config-migration.sh migrate ~/.claude/config.json --dry-run

# Run migration
lib/installer-common/config-migration.sh migrate ~/.claude/config.json
```

## Manual Migration

If you prefer to migrate manually or need to understand the transformation:

### Step 1: Backup Your Config

```bash
# Create manual backup
cp ~/.claude/config.json ~/.claude/config.json.backup.manual
```

### Step 2: Transform GitHub Namespace

**Before (v1.0)**:

```json
{
  "github": {
    "owner": "oakensoul",
    "repo": "claude-personal-assistant",
    "main_branch": "main",
    "enterprise_url": null
  }
}
```

**After (v2.0)**:

```json
{
  "config_version": "2.0",
  "vcs": {
    "provider": "github",
    "owner": "oakensoul",
    "repo": "claude-personal-assistant",
    "main_branch": "main",
    "auto_detect": true,
    "github": {
      "enterprise_url": null
    }
  }
}
```

### Step 3: Transform Reviewers

**Before (v1.0)**:

```json
{
  "workflow": {
    "pull_requests": {
      "reviewers": ["alice", "bob"]
    }
  }
}
```

**After (v2.0)**:

```json
{
  "team": {
    "default_reviewers": ["alice", "bob"],
    "review_strategy": "list",
    "members": [],
    "timezone": "UTC"
  }
}
```

### Step 4: Add New Namespaces

```json
{
  "work_tracker": {
    "provider": "github",
    "auto_detect": true
  }
}
```

### Step 5: Validate

```bash
# Validate the migrated config
lib/installer-common/config-validator.sh ~/.claude/config.json

# Should output: ✓ Configuration validation passed
```

## Complete Before/After Examples

### Example 1: Simple GitHub Configuration

**Before (v1.0)**:

```json
{
  "version": "0.1.6",
  "install_mode": "normal",
  "installed_at": "2025-09-15T10:30:00Z",
  "updated_at": "2025-10-20T15:45:00Z",
  "assistant_name": "jarvis",
  "personality": "jarvis",
  "github": {
    "owner": "oakensoul",
    "repo": "claude-personal-assistant",
    "main_branch": "main"
  },
  "workflow": {
    "pull_requests": {
      "reviewers": ["github-copilot[bot]"]
    }
  }
}
```

**After (v2.0)**:

```json
{
  "config_version": "2.0",
  "version": "0.2.0",
  "install_mode": "normal",
  "installed_at": "2025-09-15T10:30:00Z",
  "updated_at": "2025-10-20T15:45:00Z",
  "assistant_name": "jarvis",
  "personality": "jarvis",
  "vcs": {
    "provider": "github",
    "owner": "oakensoul",
    "repo": "claude-personal-assistant",
    "main_branch": "main",
    "auto_detect": true,
    "github": {
      "enterprise_url": null
    }
  },
  "work_tracker": {
    "provider": "github",
    "auto_detect": true
  },
  "team": {
    "default_reviewers": ["github-copilot[bot]"],
    "review_strategy": "list",
    "members": [],
    "timezone": "UTC"
  },
  "workflow": {
    "commit": {
      "auto_commit": true
    },
    "pr": {
      "auto_version_bump": true,
      "update_changelog": true
    }
  }
}
```

### Example 2: GitHub Enterprise

**Before (v1.0)**:

```json
{
  "github": {
    "owner": "company",
    "repo": "internal-project",
    "main_branch": "develop",
    "enterprise_url": "https://github.company.com"
  }
}
```

**After (v2.0)**:

```json
{
  "config_version": "2.0",
  "vcs": {
    "provider": "github",
    "owner": "company",
    "repo": "internal-project",
    "main_branch": "develop",
    "auto_detect": true,
    "github": {
      "enterprise_url": "https://github.company.com"
    }
  },
  "work_tracker": {
    "provider": "github",
    "auto_detect": true,
    "github": {
      "enterprise_url": "https://github.company.com"
    }
  }
}
```

## Rollback Procedure

If migration fails or you need to revert:

### Automatic Rollback

The migration script automatically creates backups and rolls back on validation failure. If you see an error during migration, your original config is preserved.

### Manual Rollback

1. **Find your backup**:

   ```bash
   ls -lt ~/.claude/*.backup.* | head -5
   ```

   Output:

   ```text
   -rw------- 1 user staff  1234 Oct 20 15:30 config.json.backup.20251020-153045
   ```

2. **Restore from backup**:

   ```bash
   # Replace current config with backup
   cp ~/.claude/config.json.backup.20251020-153045 ~/.claude/config.json
   ```

3. **Verify restoration**:

   ```bash
   # Check config version (should be 1.0 or missing)
   jq '.config_version // "1.0"' ~/.claude/config.json

   # Validate
   lib/aida-config-helper.sh --validate
   ```

### Using Migration Script

```bash
# Restore from specific backup
lib/installer-common/config-migration.sh restore \
  ~/.claude/config.json.backup.20251020-153045 \
  ~/.claude/config.json
```

## Troubleshooting

### Migration Fails with Validation Errors

**Problem**: Migration completes but validation fails

```text
✗ Configuration validation failed
✗ Missing required field: vcs.provider
```

**Solution**: Run migration again or manually add the missing fields:

```bash
# Re-run migration
lib/installer-common/config-migration.sh migrate ~/.claude/config.json

# Or manually fix (add config_version and vcs.provider)
jq '. + {config_version: "2.0", vcs: {provider: "github"}}' \
  ~/.claude/config.json > /tmp/fixed.json
mv /tmp/fixed.json ~/.claude/config.json
```

### Empty Provider After Migration

**Problem**: `vcs.provider` is empty string `""`

**Solution**: Run VCS auto-detection:

```bash
# Clear cache and regenerate config
lib/aida-config-helper.sh --clear-cache
lib/aida-config-helper.sh | jq '.vcs'

# Should now show detected values
```

### Backup Files Accumulate

**Problem**: Too many `.backup.*` files in `~/.claude/`

**Solution**: Clean up old backups (keeps most recent 5):

```bash
# Automatic cleanup
lib/installer-common/config-migration.sh cleanup ~/.claude/config.json

# Manual cleanup (remove all but 3 most recent)
ls -t ~/.claude/*.backup.* | tail -n +4 | xargs rm -f
```

### Config Not Auto-Detected

**Problem**: VCS provider not auto-detected despite being in git repo

**Solution**:

1. Check git remote:

   ```bash
   git remote get-url origin
   ```

2. Test VCS detector:

   ```bash
   lib/installer-common/vcs-detector.sh
   ```

3. Manually set provider:

   ```bash
   jq '.vcs.provider = "github"' ~/.claude/config.json > /tmp/config.json
   mv /tmp/config.json ~/.claude/config.json
   ```

### Permission Denied

**Problem**: Can't read/write config file

```text
Permission denied: ~/.claude/config.json
```

**Solution**: Fix permissions:

```bash
# Set correct permissions (600 = owner read/write only)
chmod 600 ~/.claude/config.json

# Verify
ls -la ~/.claude/config.json
# Should show: -rw------- (600)
```

## FAQ

### Q: Will my old config still work?

**A**: Yes! The old config format (v1.0) is supported until v0.4.0. Auto-migration runs automatically when you use AIDA commands, so there's no breaking change.

### Q: Can I use both old and new formats?

**A**: No. Once migrated to v2.0, you should use the new format. Mixing formats will cause validation errors.

### Q: What if I'm not using GitHub?

**A**: Perfect! The new schema supports GitLab, Bitbucket, and other VCS providers. See `docs/configuration/schema-reference.md` for details.

### Q: Do I need to migrate immediately?

**A**: No rush. Migration happens automatically on your next install/upgrade. However, new features (GitLab support, Jira integration) require the v2.0 schema.

### Q: Will this break my existing workflows?

**A**: No. Workflow commands (`/start-work`, `/open-pr`, etc.) work with both old and new config formats. They read from the correct namespace automatically.

### Q: What happens to my GitHub token?

**A**: GitHub tokens should NEVER be in config files (old or new). They belong in environment variables:

```bash
export GITHUB_TOKEN="ghp_..."
```

The migration script validates this and warns if it finds tokens in config.

### Q: Can I migrate multiple projects at once?

**A**: Each project has its own config (`.aida/config.json`). User config (`~/.claude/config.json`) is migrated once per system. Projects inherit from user config.

### Q: How do I migrate project-specific configs?

**A**: Run migration on each project config:

```bash
cd ~/project1
lib/installer-common/config-migration.sh migrate .aida/config.json

cd ~/project2
lib/installer-common/config-migration.sh migrate .aida/config.json
```

### Q: What if I have custom fields in my config?

**A**: Custom fields are preserved during migration. They're carried forward to the new config unchanged.

### Q: Can I customize the migration?

**A**: The migration is deterministic and safe. For custom transformations, copy your config, run migration, then manually adjust the result.

## Deprecation Timeline

| Version | Status | Notes |
|---------|--------|-------|
| v0.1.x | Old schema (v1.0) supported | No migration required |
| v0.2.0 | **Auto-migration introduced** | Runs automatically, backward compatible |
| v0.3.0 | Old schema deprecated | Warnings shown, migration recommended |
| v0.4.0 | Old schema removed | **Migration required** before upgrade |

**Recommendation**: Migrate now to avoid issues with future updates.

## Advanced Topics

### Multi-Provider Setup

You can configure multiple VCS and work tracker providers:

```json
{
  "vcs": {
    "provider": "github",
    "owner": "mycompany",
    "repo": "project"
  },
  "work_tracker": {
    "provider": "jira",
    "jira": {
      "domain": "mycompany.atlassian.net",
      "project_key": "PROJ"
    }
  }
}
```

### Provider-Specific Configuration

Each provider can have its own nested config:

```json
{
  "vcs": {
    "provider": "gitlab",
    "owner": "group/subgroup",
    "repo": "project",
    "gitlab": {
      "self_hosted_url": "https://gitlab.company.com",
      "api_version": "v4"
    }
  }
}
```

### Auto-Detection Opt-Out

Disable auto-detection if you prefer manual configuration:

```json
{
  "vcs": {
    "auto_detect": false,
    "provider": "github",
    "owner": "manual-config",
    "repo": "no-auto-detect"
  }
}
```

## Getting Help

If you encounter issues during migration:

1. **Check the logs**:

   ```bash
   tail -f ~/.claude/logs/install.log
   ```

2. **Run validation**:

   ```bash
   lib/installer-common/config-validator.sh ~/.claude/config.json --verbose
   ```

3. **Review migration report**:

   ```bash
   cat ~/.claude/config.json.migration-report.md
   ```

4. **Ask for help**:
   - GitHub Issues: <https://github.com/oakensoul/claude-personal-assistant/issues>
   - Tag: `migration`, `config-v2`

## See Also

- **Schema Reference**: `docs/configuration/schema-reference.md`
- **Security Model**: `docs/configuration/security-model.md`
- **VCS Providers Guide**: `docs/integration/vcs-providers.md`
- **Configuration Examples**: `templates/config/`

---

**Last Updated**: 2025-10-20

**Schema Version**: 2.0

**AIDA Version**: 0.2.0+
