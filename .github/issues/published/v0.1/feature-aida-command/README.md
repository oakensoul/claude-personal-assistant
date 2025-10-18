---
slug: aida-command
title: "Create /aida command - framework management"
type: feature
milestone: v0.1.0
labels: foundational, commands, framework
estimated_effort: 8
status: draft
created: 2025-10-10
depends_on: ["versioning-system"]
---

# Create /aida command - framework management

## Problem

Framework management commands are scattered:
- `create-agent`, `create-command` - individual commands
- No centralized way to manage AIDA itself
- No validation, migration, or health checking
- No backup/restore functionality

Need a unified `/aida` command for all framework management operations.

## Solution

Create `/aida` command with comprehensive subcommands for managing the AIDA framework.

### `/aida` Command Structure

**Agent Management:**
```bash
/aida agent create              # Create new agent
/aida agent update              # Update agents to latest standards
/aida agent list                # List all agents
/aida agent sync                # Sync agents between global/project
/aida agent validate            # Validate agent structure
```

**Command Management:**
```bash
/aida command create            # Create new command
/aida command update            # Update commands to latest standards
/aida command list              # List all commands
/aida command sync              # Sync commands
/aida command validate          # Validate command structure
```

**Framework Operations:**
```bash
/aida scan                      # Scan for outdated patterns
/aida validate                  # Validate all configurations
/aida migrate                   # Migrate to new structures
/aida backup                    # Backup AIDA configuration
/aida restore                   # Restore from backup
/aida version                   # Show version info
/aida report                    # Configuration health report
```

## Implementation Tasks

- [ ] **Design `/aida` command routing**
  - Subcommand structure
  - Category grouping (agent, command, framework)
  - Help text organization
  - Error handling

- [ ] **Implement `/aida agent create`**
  - Interactive prompts
  - Template selection
  - Knowledge base setup
  - Frontmatter generation
  - Replaces `create-agent`

- [ ] **Implement `/aida agent update`**
  - Detect outdated agents
  - Update frontmatter
  - Update model references
  - Preserve customizations

- [ ] **Implement `/aida agent list` and `/aida agent sync`**
  - List global agents
  - List project agents
  - Sync between locations
  - Handle conflicts

- [ ] **Implement `/aida command create`**
  - Interactive prompts
  - Template selection
  - Agent reference setup
  - Frontmatter generation
  - Replaces `create-command`

- [ ] **Implement `/aida command update`**
  - Detect outdated commands
  - Update frontmatter
  - Update agent references
  - Preserve customizations

- [ ] **Implement `/aida command list` and `/aida command sync`**
  - List all commands
  - Show command details
  - Sync between locations
  - Handle conflicts

- [ ] **Implement `/aida scan`**
  - Scan for deprecated patterns
  - Detect outdated versions
  - Find missing dependencies
  - Identify inconsistencies

- [ ] **Implement `/aida validate`**
  - Validate all commands
  - Validate all agents
  - Check version compatibility
  - Verify dependencies
  - Run linting checks
  - Generate health report

- [ ] **Implement `/aida migrate`**
  - Detect current version
  - Plan migration path
  - Backup before migration
  - Execute migration steps
  - Validate after migration
  - Generate migration report

- [ ] **Implement `/aida backup` and `/aida restore`**
  - Backup all AIDA configurations
  - Include versioning metadata
  - Compress backups
  - List available backups
  - Restore from backup
  - Validate restored configuration

- [ ] **Implement `/aida version`**
  - Show AIDA framework version
  - Show command structure version
  - Show agent structure version
  - List installed commands/agents
  - Check for updates

- [ ] **Implement `/aida report`**
  - Configuration health score
  - Compatibility status
  - Outdated components
  - Missing dependencies
  - Recommendations

- [ ] **Add comprehensive error handling**
  - Missing dependencies
  - Invalid configurations
  - Permission errors
  - Backup/restore failures

- [ ] **Documentation**
  - Usage examples for each subcommand
  - Agent/command creation guides
  - Migration procedures
  - Backup/restore best practices

## Success Criteria

- [ ] All agent operations work correctly
- [ ] All command operations work correctly
- [ ] Framework validation is comprehensive
- [ ] Migration system works smoothly
- [ ] Backup/restore preserves all data
- [ ] Tests pass on macOS and Linux
- [ ] Documentation is comprehensive

## Testing Scenarios

```bash
# Test agent management
/aida agent create "Test Agent"
/aida agent list
/aida agent validate

# Test command management
/aida command create "Test Command"
/aida command list
/aida command validate

# Test framework operations
/aida scan
/aida validate
/aida version
/aida report

# Test backup/restore
/aida backup
/aida restore backup-2025-10-10.tar.gz

# Test migration
/aida migrate --from=1.0 --to=2.0
```

## Dependencies

- Requires: versioning-system (#1)
- Blocks: None (can be developed in parallel with other commands)

## Replaces v1 Commands

- `create-agent` → `/aida agent create`
- `create-command` → `/aida command create`

## New Functionality

- Agent/command validation
- Migration system
- Backup/restore
- Health reporting
- Version management
- Sync operations

## Notes

- This command is critical for framework maintenance
- Validation must be thorough to catch issues early
- Migration system enables safe upgrades
- Backup/restore provides safety net
- Health reporting helps users maintain quality
- Should integrate with claude-agent-manager patterns
