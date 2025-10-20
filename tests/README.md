---
title: "AIDA Test Suite"
description: "Overview of AIDA testing infrastructure and test organization"
category: "testing"
tags: ["bats", "testing", "unit-tests", "integration-tests"]
last_updated: "2025-10-18"
status: "published"
audience: "developers"
---

# AIDA Test Suite

Automated testing infrastructure for AIDA installer modules using Bats (Bash Automated Testing System).

## Quick Start

```bash
# Install Bats (see docs/testing/BATS_SETUP.md for details)
brew install bats-core  # macOS
sudo apt-get install bats  # Ubuntu/Debian

# Run all unit tests
make test-unit

# Run all integration tests
make test-integration

# Run all tests
make test-all

# Run specific test file
bats tests/unit/test_prompts.bats

# Watch for changes (requires entr)
make test-watch
```

## Test Organization

```text
tests/
├── unit/                      # Unit tests for individual modules
│   ├── test_prompts.bats      # User prompt functions
│   ├── test_config.bats       # Configuration wrapper functions
│   ├── test_directories.bats  # Directory/symlink operations
│   └── test_summary.bats      # Installation summary display
├── integration/               # Integration tests
│   └── test_upgrade_scenarios.bats  # Future: Upgrade scenarios
├── fixtures/                  # Test data and mock files
│   ├── configs/               # Sample configuration files
│   │   ├── sample-workflow-config.json
│   │   ├── sample-github-config.json
│   │   └── sample-aida-config.json
│   └── templates/             # Sample template files
│       └── sample-command.md
├── helpers/                   # Shared test utilities
│   └── test_helpers.bash      # Common test functions
└── README.md                  # This file
```

## Test Types

### Unit Tests (`tests/unit/`)

Test individual modules in isolation:

- **test_prompts.bats** - Tests `lib/installer-common/prompts.sh`
  - `prompt_yes_no()` - Yes/no prompts with defaults
  - `prompt_input()` - Text input with validation
  - `prompt_select()` - Selection from list
  - `prompt_multiselect()` - Multiple selections
  - `prompt_path()` - Path input with validation
  - `prompt_confirm()` - Confirmation prompts

- **test_config.bats** - Tests `lib/installer-common/config.sh`
  - `get_config()` - Load configuration files
  - `get_config_value()` - Extract values with jq
  - `write_user_config()` - Write JSON configurations
  - `validate_config()` - Configuration validation

- **test_directories.bats** - Tests `lib/installer-common/directories.sh`
  - `create_claude_dirs()` - Create directory structure
  - `create_symlink()` - Idempotent symlink creation
  - `backup_existing()` - Backup files/directories
  - `restore_backup()` - Restore from backup

- **test_summary.bats** - Tests `lib/installer-common/summary.sh`
  - `print_summary()` - Installation summary display
  - `print_success()` - Success messages
  - `print_error()` - Error messages
  - `print_warning()` - Warning messages

**Run unit tests:**

```bash
# All unit tests
make test-unit

# Specific module
bats tests/unit/test_prompts.bats

# With verbose output
bats --verbose tests/unit/test_prompts.bats
```

### Integration Tests (`tests/integration/`)

Test interactions between modules and full workflows:

- **test_upgrade_scenarios.bats** (future)
  - Fresh installation
  - Upgrade from previous version
  - Preserve user customizations
  - Handle configuration migrations

**Run integration tests:**

```bash
# All integration tests
make test-integration

# Specific test file
bats tests/integration/test_upgrade_scenarios.bats
```

## Test Fixtures

Test fixtures provide consistent test data:

### Configuration Fixtures (`tests/fixtures/configs/`)

Sample configuration files for testing config parsing:

- **sample-workflow-config.json** - Workflow automation config
- **sample-github-config.json** - GitHub integration config
- **sample-aida-config.json** - AIDA system configuration

**Usage in tests:**

```bash
@test "function processes valid config" {
  local config="${PROJECT_ROOT}/tests/fixtures/configs/sample-config.json"
  run process_config "$config"
  [ "$status" -eq 0 ]
}
```

### Template Fixtures (`tests/fixtures/templates/`)

Sample template files for testing template processing:

- **sample-command.md** - Example slash command template

**Usage in tests:**

```bash
@test "function processes template" {
  local template="${PROJECT_ROOT}/tests/fixtures/templates/sample-command.md"
  run process_template "$template"
  [ "$status" -eq 0 ]
}
```

## Test Helpers

Shared utilities in `tests/helpers/test_helpers.bash`:

### Environment Setup

- `PROJECT_ROOT` - Absolute path to project root
- `load_test_lib()` - Load specific installer module

### Directory Management

- `setup_test_dir()` - Create temporary test directory
- `teardown_test_dir()` - Remove temporary test directory

### Assertions

- `assert_file_exists()` - Check file exists
- `assert_dir_exists()` - Check directory exists
- `assert_file_contains()` - Check file contains text
- `assert_symlink_target()` - Verify symlink target

**Usage:**

```bash
load ../helpers/test_helpers

setup() {
  setup_test_dir
}

teardown() {
  teardown_test_dir
}

@test "example" {
  echo "test" > "$TEST_DIR/file.txt"
  assert_file_exists "$TEST_DIR/file.txt"
}
```

## Writing Tests

### Test Structure

```bash
#!/usr/bin/env bats

# Load helpers
load ../helpers/test_helpers

# Setup before each test
setup() {
  source "${PROJECT_ROOT}/lib/installer-common/module.sh"
  setup_test_dir
}

# Cleanup after each test
teardown() {
  teardown_test_dir
}

# Test case
@test "descriptive test name" {
  # Arrange
  local input="test value"

  # Act
  run my_function "$input"

  # Assert
  [ "$status" -eq 0 ]
  [[ "$output" =~ "expected" ]]
}
```

### Key Principles

1. **Test behavior, not implementation** - Focus on what functions do
2. **One assertion per test** - Keep tests focused
3. **Descriptive test names** - Should read like documentation
4. **Independent tests** - Each test stands alone
5. **Fast tests** - Unit tests should run in <1 second

See [docs/testing/UNIT_TESTING.md](../docs/testing/UNIT_TESTING.md) for comprehensive guide.

## Running Tests

### Make Targets

```bash
make test-unit         # Run all unit tests
make test-integration  # Run all integration tests
make test-all          # Run all tests
make test-watch        # Watch for changes and re-run
```

### Direct Bats Commands

```bash
# Single file
bats tests/unit/test_prompts.bats

# Multiple files
bats tests/unit/test_prompts.bats tests/unit/test_config.bats

# All files in directory
bats tests/unit/*.bats

# Verbose output
bats --verbose tests/unit/test_prompts.bats

# TAP output (for CI/CD)
bats --tap tests/unit/*.bats

# Filter tests (bats 1.5+)
bats --filter "prompt_yes_no" tests/unit/test_prompts.bats
```

## Debugging Tests

### 1. Verbose Output

```bash
bats --verbose tests/unit/test_prompts.bats
```

### 2. Add Debug Output

```bash
@test "debugging example" {
  run my_function "input"

  # Print to stderr (visible in verbose mode)
  echo "Status: $status" >&3
  echo "Output: $output" >&3

  [ "$status" -eq 0 ]
}
```

### 3. Skip Tests

```bash
@test "skip this test" {
  skip "Debugging other tests"
  # Test code...
}
```

### 4. Run Function Directly

```bash
@test "debugging example" {
  # Call directly instead of 'run' to see errors
  my_function "input"
}
```

## CI/CD Integration

Tests run automatically in GitHub Actions:

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install Bats
        run: sudo apt-get install -y bats
      - name: Run tests
        run: make test-all
```

## Test Coverage

Current test coverage:

| Module | Unit Tests | Coverage |
|--------|-----------|----------|
| prompts.sh | 8 tests | ✅ Complete |
| config.sh | 6 tests | ✅ Complete |
| directories.sh | 7 tests | ✅ Complete |
| summary.sh | 5 tests | ✅ Complete |

Total: 26 unit tests

## Contributing

When adding new modules:

1. **Create test file** in `tests/unit/test_<module>.bats`
2. **Write tests first** (TDD approach)
3. **Ensure all tests pass** before committing
4. **Update this README** with new test counts

When fixing bugs:

1. **Write failing test** that reproduces bug
2. **Fix the bug** in module
3. **Verify test passes**
4. **Commit both** test and fix

## Resources

- **Setup Guide**: [docs/testing/BATS_SETUP.md](../docs/testing/BATS_SETUP.md)
- **Testing Guide**: [docs/testing/UNIT_TESTING.md](../docs/testing/UNIT_TESTING.md)
- **Bats Documentation**: <https://bats-core.readthedocs.io/>
- **Bats GitHub**: <https://github.com/bats-core/bats-core>

## Future Enhancements

- [ ] Integration tests for upgrade scenarios
- [ ] Performance benchmarks for installer
- [ ] Cross-platform testing (macOS, Ubuntu, Debian)
- [ ] Coverage reporting with kcov
- [ ] Mutation testing for test quality
- [ ] Property-based testing for edge cases
