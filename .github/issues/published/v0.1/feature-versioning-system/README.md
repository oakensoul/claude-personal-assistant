---
slug: versioning-system
title: "Implement versioning system for commands and agents"
type: feature
milestone: v0.1.0
labels: foundational, commands, agents
estimated_effort: 6
status: draft
created: 2025-10-10
blocks: ["work-command", "workflow-commands", "operations-commands", "quality-commands", "aida-command"]
---

# Implement versioning system for commands and agents

## Problem

As AIDA evolves, we need a way to:
- Track command structure versions
- Ensure compatibility between AIDA versions
- Provide smooth migration paths
- Validate configurations

Without versioning, users won't know what version they're running or how to upgrade safely.

## Solution

Implement a comprehensive versioning system for all commands and agents.

### Versioning Schema

```yaml
---
name: work
version: "2.0.0"
aida:
  min_version: "0.1.0"        # Minimum AIDA framework version required
  structure: "consolidated"    # Command structure type
  schema: "2.0"               # Schema format version
replaces:
  - {name: "start-work", version: "1.0.0"}
  - {name: "implement", version: "1.0.0"}
---
```

### `/aida version` Command

Show complete version information:

```bash
$ /aida version

AIDA Framework: v0.1.0
Command Structure: v2.0 (consolidated)
Agent Structure: v2.0 (two-tier)

Installed Commands: 10
Installed Agents: 18

Updates available:
  None - you're up to date!
```

### `/aida validate` Command

Validate all configurations:

```bash
$ /aida validate

Validating AIDA configuration...
✓ All commands compatible with AIDA v0.1.0
✓ All agents valid structure (v2.0)
✓ No missing dependencies
✓ Markdown linting passed

Configuration health: 100%
```

## Implementation Tasks

- [ ] **Design version schema**
  - Define frontmatter structure
  - Document all version fields
  - Create schema validation

- [ ] **Add versioning to templates**
  - Add version to all command templates
  - Add version to all agent templates
  - Create migration tracking file

- [ ] **Implement `/aida version` command**
  - Show AIDA framework version
  - Show command/agent structure versions
  - Show installed counts
  - Check for updates

- [ ] **Implement `/aida validate` command**
  - Validate command versions
  - Validate agent versions
  - Check compatibility
  - Run linting checks
  - Generate health report

- [ ] **Create validation functions**
  - Version compatibility checker
  - Schema validator
  - Dependency resolver

- [ ] **Documentation**
  - Document versioning approach
  - Create upgrade guide
  - Add examples

## Success Criteria

- [ ] All templates have version metadata
- [ ] `/aida version` shows complete version info
- [ ] `/aida validate` catches incompatibilities
- [ ] Documentation is clear and comprehensive
- [ ] Tests pass on macOS and Linux

## Testing

```bash
# Test version command
/aida version

# Test validation
/aida validate

# Test with incompatible version
# (simulate by editing a command version)

# Test migration tracking
# (create a migration record)
```

## Dependencies

None - this is foundational work that other issues depend on.

## Notes

- This must be completed first - other issues depend on it
- Keep the versioning simple but extensible
- Focus on clarity over complexity
- Version format: semver (major.minor.patch)
