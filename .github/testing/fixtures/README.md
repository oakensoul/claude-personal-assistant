---
title: "Test Fixtures"
description: "Test data for validating AIDA installer behavior across various scenarios"
category: "testing"
tags: ["testing", "fixtures", "docker", "installation", "upgrade"]
last_updated: "2025-10-18"
status: "published"
audience: "developers"
---

# Test Fixtures

Test data for validating AIDA installer behavior across various scenarios including fresh installations, upgrades, and migrations.

## Structure

- `user-content/` - User-created templates (should be preserved)
- `v0.1-installation/` - Simulated v0.1.x installation
- `deprecated-templates/` - Templates with deprecation metadata
- `upgrade-scenarios/` - JSON configs describing test scenarios

## Usage

Fixtures are used by:

- Integration tests (`tests/integration/`)
- Docker test containers (`.github/testing/Dockerfile`)
- Manual upgrade testing
- CI/CD validation

## Scenarios Covered

### 1. Fresh Installation

Clean system with no existing AIDA installation.

**Preconditions:**

- No `~/.aida/` directory
- No `~/.claude/` directory
- No existing AIDA configuration

**Expected Outcome:**

- `.aida/` namespace created
- Templates installed to namespace directories
- User config directory structure created
- Entry point generated

### 2. Upgrade with User Content

Upgrade from v0.1.x to v0.2.0 while preserving custom user templates.

**Preconditions:**

- Existing v0.1.x installation
- User-created custom templates
- Flat directory structure

**Expected Outcome:**

- Namespace structure created
- AIDA templates moved to namespace
- User content preserved in place
- Old flat templates replaced

### 3. Flat to Namespace Migration

Migrate existing flat structure to namespace isolation.

**Preconditions:**

- v0.1.x installation with flat structure
- Mix of AIDA and user templates
- Deprecated command names

**Expected Outcome:**

- Namespace structure implemented
- AIDA templates isolated in `.aida/`
- User templates untouched
- Deprecated templates handled

## User Content Preservation

User content in fixtures represents the **critical test case** - these files must NEVER be touched by AIDA installer.

### Protected Patterns

User content that should be preserved:

- `~/.claude/commands/*.md` (NOT in `.aida/` subdirectory)
- `~/.claude/agents/*.md` (NOT in `.aida/` subdirectory)
- `~/.claude/skills/*.md` (NOT in `.aida/` subdirectory)
- Any custom directories created by users

### Framework Patterns

Framework content that can be replaced:

- `~/.claude/commands/.aida/*` (AIDA namespace)
- `~/.claude/agents/.aida/*` (AIDA namespace)
- `~/.claude/skills/.aida/*` (AIDA namespace)

### Detection Logic

Installer determines if a file is user content by:

1. **Location**: Files NOT in `.aida/` subdirectory are user content
2. **Metadata**: Files without AIDA framework metadata
3. **Timestamps**: Files modified after installation
4. **Authorship**: Files with `author: "user"` in frontmatter

## Fixture Details

### User Content Fixtures

**Purpose**: Realistic examples of user-created templates that must be preserved.

**Files:**

- `commands/my-workflow.md` - Personal workflow automation
- `commands/team-standup.md` - Team-specific command
- `agents/project-manager.md` - Custom project management agent
- `skills/python-expert.md` - Custom skill definition

**Validation**: Installer must preserve these files unchanged during upgrades.

### v0.1.x Installation Fixtures

**Purpose**: Simulate an existing v0.1.6 installation with flat structure.

**Files:**

- `.claude/aida-config.json` - Old configuration format
- `.claude/commands/start-work.md` - Framework command (flat structure)
- `.claude/commands/create-issue.md` - Deprecated command name
- `.claude/agents/secretary.md` - Framework agent (flat structure)
- `CLAUDE.md` - Old entry point

**Validation**: Installer must migrate framework content to namespace while preserving structure.

### Deprecated Template Fixtures

**Purpose**: Examples of deprecated templates with proper metadata.

**Files:**

- `create-issue/` - Renamed to `issue-create` (ADR-010)
- `publish-issue/` - Renamed to `issue-publish` (ADR-010)

**Validation**: Installer should handle deprecation gracefully.

### Upgrade Scenario Configs

**Purpose**: JSON configurations describing expected behavior for each scenario.

**Files:**

- `scenario-1-fresh.json` - Fresh installation expectations
- `scenario-2-upgrade.json` - Upgrade with user content expectations
- `scenario-3-migration.json` - Migration expectations

**Usage**: Test harness reads these configs to validate installer behavior.

## Adding New Fixtures

When adding new fixtures:

1. **Create realistic content**: Use actual examples from real-world usage
2. **Include frontmatter**: All markdown files need proper metadata
3. **Document in README**: Update this file with fixture details
4. **Reference in scenarios**: Add to appropriate scenario config
5. **Test preservation**: Verify user content is protected

## Testing with Fixtures

### Manual Testing

```bash
# Copy fixture to test location
cp -r .github/testing/fixtures/v0.1-installation/.claude ~/

# Run installer
./install.sh

# Verify user content preserved
diff ~/.claude/commands/my-workflow.md .github/testing/fixtures/user-content/commands/my-workflow.md
```

### Docker Testing

```bash
# Run Docker test with specific scenario
.github/testing/test-install.sh --scenario upgrade-with-user-content

# Run all scenarios
.github/testing/test-install.sh --all-scenarios
```

### Integration Testing

```bash
# Run integration tests with fixtures
pytest tests/integration/test_installer.py --fixtures=.github/testing/fixtures
```

## Maintenance

Fixtures should be updated when:

- AIDA version changes
- Template structure changes
- New deprecations introduced
- New user content patterns identified

Keep fixtures aligned with actual installation scenarios users will encounter.
