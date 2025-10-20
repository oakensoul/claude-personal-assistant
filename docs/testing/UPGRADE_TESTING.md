---
title: "AIDA Upgrade Testing Documentation"
description: "Comprehensive documentation for AIDA upgrade scenario testing and user content preservation validation"
category: "testing"
tags: ["testing", "upgrade", "integration", "user-data", "namespace-isolation"]
last_updated: "2025-10-18"
status: "published"
audience: "developers"
---

# AIDA Upgrade Testing Documentation

## Overview

This document describes the comprehensive integration testing suite for AIDA upgrade scenarios, focusing on the #1 stakeholder concern: **preventing user data loss**.

These tests validate that the namespace isolation architecture (ADR-013) successfully protects user content during upgrades, reinstallations, and migrations.

## Testing Philosophy

**Priority**: User data safety > everything else

Every test asks: **"Can a user lose data in this scenario?"**

If yes → we write a test to prevent it.

## Test Organization

Tests are organized in `/tests/integration/test_upgrade_scenarios.bats` with supporting helpers in `/tests/integration/test_upgrade_helpers.bash`.

### Test Categories

1. **Fresh Installation Tests** (5 tests) - Clean install scenarios
2. **Upgrade Tests** (6 tests) - v0.1.x → v0.2.0 with user content
3. **Namespace Isolation Tests** (8 tests) - Verify .aida/ separation
4. **User Content Preservation Tests** (7 tests) - Critical data safety tests
5. **Dev Mode Tests** (4 tests) - Symlink behavior
6. **Migration Tests** (3 tests) - Flat structure → namespace structure

**Total**: 33 comprehensive tests

## Test Infrastructure

### Helper Functions

#### Installation and Setup

**`setup_v0_1_installation(test_dir)`**

Simulates a v0.1.6 installation with flat structure:

- Creates `.claude/` directory structure
- Installs v0.1.6 config file
- Creates old-format `CLAUDE.md`
- Sets up `~/.aida` symlink

**`create_user_content(test_dir)`**

Creates realistic user-generated content:

- User commands, agents, skills
- Nested directory structures
- Files with special characters
- Hidden files
- Various content types

**`run_installer(mode, test_dir)`**

Executes the installer in a test environment:

- Supports "normal" and "dev" modes
- Redirects HOME to test directory
- Handles interactive prompts
- Returns installation status

#### Validation Functions

**`assert_file_unchanged(file, checksum)`**

Verifies file content hasn't changed:

- Compares SHA-256 checksums
- Cross-platform compatible
- Detailed error messages

**`assert_namespace_structure(base_dir)`**

Verifies namespace directories exist:

- Checks `.aida/` subdirectories
- Validates directory structure
- Ensures proper organization

**`assert_aida_templates_namespaced(base_dir)`**

Ensures AIDA templates are in `.aida/`:

- Checks for templates outside namespace
- Validates proper isolation
- Prevents namespace pollution

**`assert_config_v0_2_format(config_file)`**

Validates config file format:

- Checks for v0.2.0 fields
- Validates JSON structure
- Ensures migration completed

#### Utility Functions

**`calculate_checksum(file)`**

Cross-platform file checksumming:

- Uses `sha256sum` (Linux) or `shasum` (macOS)
- Returns SHA-256 hash
- Error handling for missing files

**`get_file_timestamp(file)`**

Cross-platform file modification time:

- Uses BSD `stat` (macOS) or GNU `stat` (Linux)
- Returns Unix timestamp
- Useful for timestamp preservation tests

## Test Coverage

### Category 1: Fresh Installation Tests

These tests validate that fresh installations create the correct structure.

#### Test: Fresh install creates .aida namespace directories

**Purpose**: Verify namespace structure is created on fresh install

**Validates**:

- `.claude/commands/.aida/` created
- `.claude/agents/.aida/` created
- `.claude/skills/.aida/` created

**Critical**: Foundation for namespace isolation

#### Test: Fresh install creates ~/.aida symlink

**Purpose**: Verify installation directory linkage

**Validates**:

- `~/.aida` symlink exists
- Points to repository location

**Critical**: Required for template access

#### Test: Fresh install generates CLAUDE.md

**Purpose**: Verify main configuration file created

**Validates**:

- `~/CLAUDE.md` exists
- Contains AIDA references
- Contains personality information

#### Test: Fresh install creates valid config file

**Purpose**: Verify configuration file structure

**Validates**:

- `~/.claude/aida-config.json` exists
- Valid JSON format
- Contains required fields

#### Test: Fresh install in dev mode creates template symlinks

**Purpose**: Verify dev mode creates symlinks instead of copies

**Validates**:

- Templates are symlinked (not copied)
- Development workflow supported

### Category 2: Upgrade Tests

These tests validate that upgrades from v0.1.x preserve user content.

#### Test: Upgrade preserves user commands outside .aida/

**Purpose**: Critical test for command preservation

**Scenario**:

- v0.1.x installation with user command
- Upgrade to v0.2.0
- Verify user command unchanged

**Validates**:

- File exists after upgrade
- Content identical (checksum match)
- Location unchanged

#### Test: Upgrade preserves user agents outside .aida/

**Purpose**: Validate agent preservation

**Scenario**:

- v0.1.x with user agent
- Upgrade to v0.2.0
- Verify preservation

#### Test: Upgrade preserves user skills outside .aida/

**Purpose**: Validate skill preservation

**Scenario**:

- v0.1.x with user skill
- Upgrade to v0.2.0
- Verify preservation

#### Test: Upgrade replaces old flat-structure AIDA templates

**Purpose**: Verify old templates migrated to namespace

**Scenario**:

- v0.1.x with flat structure templates
- Upgrade to v0.2.0
- Verify namespace structure created

**Validates**:

- Old templates moved/replaced
- Namespace structure created
- No duplicate content

#### Test: Upgrade updates config file with new fields

**Purpose**: Verify config migration

**Scenario**:

- v0.1.x config format
- Upgrade to v0.2.0
- Verify new fields added

**Validates**:

- Config still valid JSON
- New v0.2.0 fields present
- Version number updated

#### Test: Upgrade preserves user customizations in config

**Purpose**: Critical - ensure user config changes preserved

**Scenario**:

- User modifies config in v0.1.x
- Upgrade to v0.2.0
- Verify customizations intact

**Validates**:

- Custom values preserved
- No overwrite of user settings

### Category 3: Namespace Isolation Tests

**Most critical category** - validates ADR-013 namespace isolation.

#### Test: Namespace isolation: user command NOT in .aida/ preserved

##### THE critical test for ADR-013

**Purpose**: Prove namespace isolation works

**Scenario**:

- Create user content outside `.aida/`
- Run upgrade (creates `.aida/` namespace)
- Verify user content untouched

**Validates**:

- User file exists after upgrade
- Content completely unchanged
- File NOT moved to `.aida/`

**Why critical**: If this fails, users can lose data

#### Test: Namespace isolation: .aida/ can be deleted and reinstalled

**Purpose**: Validate clean uninstall/reinstall

**Scenario**:

- Installation with user content
- Delete entire `.aida/` namespace
- Reinstall
- Verify user content intact

**Validates**:

- User content safe from `.aida/` deletion
- Reinstall doesn't break user files

**Use case**: Allows users to "nuke and reinstall" AIDA without fear

#### Test: Namespace isolation: AIDA templates installed to .aida/

**Purpose**: Verify template namespacing

**Validates**:

- AIDA templates in `.aida/` subdirectories
- No templates in root directories
- Proper organization

#### Test: Namespace isolation: user directories outside .aida/ untouched

**Purpose**: Validate nested user content

**Scenario**:

- Complex nested user directory structure
- Upgrade to v0.2.0
- Verify structure preserved

#### Test: Namespace isolation: deprecated templates in .aida-deprecated/

**Purpose**: Verify deprecated template handling

**Validates**:

- Deprecated templates isolated
- Separate namespace from active templates
- No conflicts with user content

#### Test: Namespace isolation: reinstall doesn't create duplicates

**Purpose**: Validate idempotency

**Scenario**:

- Install AIDA
- Create user content
- Reinstall AIDA
- Verify no duplicate files created

**Validates**:

- Same file count before/after reinstall
- Reinstall is safe operation

#### Test: Namespace isolation: user can override AIDA templates

**Purpose**: Validate user override behavior

**Scenario**:

- User creates file with same name as AIDA template
- Reinstall AIDA
- Verify user file not overwritten

**Validates**:

- User files take precedence
- AIDA respects user overrides

#### Test: Namespace isolation: migration from flat preserves user content

**Purpose**: Comprehensive migration test

**Scenario**:

- v0.1.x flat structure with user content
- Full upgrade to v0.2.0 namespaces
- Verify all user content preserved

**Validates**:

- Multiple user files preserved
- Namespace structure created
- No data loss during migration

### Category 4: User Content Preservation Tests

These tests validate edge cases and special scenarios.

#### Test: Complex nested directories preserved

**Purpose**: Validate deep directory structures

**Scenario**: `.claude/commands/my-team/workflows/production/deploy.md`

**Validates**: Multi-level nesting preserved

#### Test: Files with special characters in names preserved

**Purpose**: Validate filename handling

**Scenarios**:

- Files with parentheses: `workflow (backup).md`
- Files with dashes: `my-workflow-2024.md`

**Validates**: Special character handling

#### Test: Binary files in user directories preserved

**Purpose**: Validate non-text file handling

**Scenarios**: Images, PDFs, compressed files

**Validates**: Binary content unchanged

#### Test: Symlinks created by user preserved

**Purpose**: Validate symlink handling

**Scenario**:

- User creates symlink between files
- Upgrade
- Verify symlink intact

**Validates**:

- Symlink exists
- Target unchanged

#### Test: Hidden files in user directories preserved

**Purpose**: Validate dotfile handling

**Scenarios**: `.my-config`, `.hidden-settings`

**Validates**: Hidden files preserved

#### Test: Permissions on user files preserved

**Purpose**: Validate permission preservation

**Scenario**:

- User sets `chmod 600` on sensitive file
- Upgrade
- Verify permissions unchanged

**Validates**: File modes preserved

#### Test: Timestamps on user files preserved

**Purpose**: Validate timestamp preservation

**Scenario**:

- User file with specific mtime
- Upgrade
- Verify timestamp unchanged

**Validates**: Modification times preserved

### Category 5: Dev Mode Tests

These tests validate development workflow.

#### Test: Templates are symlinked not copied

**Purpose**: Verify dev mode symlinks

**Validates**:

- Templates symlinked to repository
- Live editing supported

#### Test: Changes to repo templates reflected immediately

**Purpose**: Validate live editing workflow

**Validates**:

- Changes in repo visible in `~/.claude/`
- No restart required

#### Test: User content still copied (not symlinked)

**Purpose**: Verify user content handling in dev mode

**Validates**:

- User files copied (not symlinked)
- User content independent of repo

#### Test: Can switch from normal to dev mode

**Purpose**: Validate mode conversion

**Scenario**:

- Install in normal mode
- Switch to dev mode
- Verify user content preserved

**Validates**:

- Mode switch safe operation
- User data preserved during switch

### Category 6: Migration Tests

These tests validate full migration paths.

#### Test: v0.1.6 flat structure converts to namespace

**Purpose**: Comprehensive migration test

**Scenario**:

- Complete v0.1.6 installation
- Realistic user content
- Full upgrade to v0.2.0

**Validates**:

- Namespace structure created
- All user content preserved
- Config migrated

#### Test: Deprecated templates handled correctly

**Purpose**: Validate deprecated template migration

**Scenario**:

- v0.1.6 with old templates
- Upgrade to v0.2.0
- Verify deprecated templates handled

**Validates**:

- Deprecated templates isolated
- No conflicts with user content

#### Test: Config upgraded from v0.1.x to v0.2.0 format

**Purpose**: Validate config migration

**Scenario**:

- v0.1.x config format
- Upgrade to v0.2.0
- Verify config structure updated

**Validates**:

- Config migrated successfully
- Valid JSON maintained
- New fields present

## Running the Tests

### Run all upgrade scenario tests

```bash
bats tests/integration/test_upgrade_scenarios.bats
```

### Run with verbose output

```bash
bats --verbose tests/integration/test_upgrade_scenarios.bats
```

### Run specific test category

```bash
# Run only namespace isolation tests
bats tests/integration/test_upgrade_scenarios.bats --filter "namespace isolation"
```

### Run single test

```bash
bats tests/integration/test_upgrade_scenarios.bats --filter "user command NOT in .aida/ preserved"
```

### Run via Make

```bash
# Run all integration tests
make test-integration

# Run all tests (unit + integration)
make test
```

## Test Fixtures

Tests use fixtures from `.github/testing/fixtures/`:

### v0.1-installation/

Simulated v0.1.6 installation structure:

- `.claude/agents/` (flat structure)
- `.claude/commands/` (flat structure)
- `aida-config.json` (v0.1.6 format)

### user-content/

Realistic user-generated content:

- Custom commands
- Custom agents
- Custom skills
- Nested structures

### upgrade-scenarios/

Specific upgrade test scenarios (if needed)

## Success Criteria

All 33 tests must pass with:

- ✅ User content preservation validated
- ✅ Namespace isolation verified
- ✅ Dev mode behavior tested
- ✅ Migration paths tested
- ✅ Edge cases covered
- ✅ No user data loss scenarios

## Debugging Failed Tests

### Test fails with "File not found"

**Cause**: File expected but doesn't exist after operation

**Debug**:

```bash
# Run with verbose output
bats --verbose tests/integration/test_upgrade_scenarios.bats

# Check test directory
ls -laR "$TEST_DIR"
```

### Test fails with "checksum mismatch"

**Cause**: File content changed when it shouldn't have

**Debug**:

```bash
# Compare file content
diff expected_file actual_file

# Check for whitespace differences
diff -w expected_file actual_file
```

### Test fails with "Directory not found"

**Cause**: Expected directory structure not created

**Debug**:

```bash
# Check directory tree
find "$TEST_DIR" -type d

# Verify namespace structure
ls -la "$TEST_DIR/.claude/commands/"
```

## Continuous Integration

These tests run automatically on:

- Pull requests to `main`
- Commits to `main`
- Release branches

**CI Configuration**: `.github/workflows/ci.yml`

**Required**: All tests must pass before merge

## Test Maintenance

### Adding new upgrade scenarios

1. Create test fixture in `.github/testing/fixtures/`
2. Add test case to appropriate category
3. Add helper function if needed
4. Update this documentation

### Updating for new AIDA versions

1. Add new version fixtures
2. Create migration test (old → new)
3. Verify all existing tests still pass
4. Update version checks in tests

## Related Documentation

- [ADR-013: Namespace Isolation](../architecture/decisions/adr-013-namespace-isolation.md)
- [Testing Strategy](../testing/TESTING_STRATEGY.md)
- [Contributing Guide](../CONTRIBUTING.md)

## Version History

**v1.0** - 2025-10-18

- Initial comprehensive upgrade testing suite
- 33 tests across 6 categories
- User content preservation validation
- Namespace isolation verification
- Dev mode testing
- Migration path testing
