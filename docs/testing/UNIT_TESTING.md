---
title: "Unit Testing with Bats"
description: "Guide to writing, running, and debugging unit tests for AIDA installer modules"
category: "testing"
tags: ["bats", "testing", "unit-tests", "best-practices"]
last_updated: "2025-10-18"
status: "published"
audience: "developers"
---

# Unit Testing with Bats

This guide covers writing, running, and debugging unit tests for AIDA installer modules using Bats.

## Quick Start

```bash
# Run all unit tests
make test-unit

# Run specific test file
bats tests/unit/test_prompts.bats

# Run with verbose output
bats --verbose tests/unit/test_prompts.bats

# Watch for changes and re-run tests (requires entr)
make test-watch
```

## Test Organization

### Directory Structure

```text
tests/
├── unit/                      # Unit tests (one file per module)
│   ├── test_prompts.bats
│   ├── test_config.bats
│   ├── test_directories.bats
│   └── test_summary.bats
├── integration/               # Integration tests
│   └── test_upgrade_scenarios.bats
├── fixtures/                  # Test data
│   ├── configs/
│   └── templates/
├── helpers/                   # Shared test utilities
│   └── test_helpers.bash
└── README.md
```

### Naming Conventions

- **Test files**: `test_<module_name>.bats`
- **Test names**: Descriptive phrases starting with function name
- **Helper files**: `<purpose>_helpers.bash`

**Examples:**

```bash
# Good test names
@test "prompt_yes_no accepts 'y' as yes"
@test "create_claude_dirs creates all required directories"
@test "get_config_value returns empty string for missing key"

# Bad test names
@test "test1"
@test "it works"
@test "prompt test"
```

## Writing Tests

### Basic Test Structure

```bash
#!/usr/bin/env bats

# Load test helpers
load ../helpers/test_helpers

# Optional: Run before each test
setup() {
  # Load module under test
  source "${PROJECT_ROOT}/lib/installer-common/prompts.sh"

  # Create temp directory
  TEST_DIR="$(mktemp -d)"
}

# Optional: Run after each test
teardown() {
  # Clean up temp directory
  [[ -n "${TEST_DIR:-}" ]] && rm -rf "$TEST_DIR"
}

# Individual test case
@test "function_name does expected thing" {
  # Arrange: Set up test conditions
  local input="test value"

  # Act: Run function
  run function_name "$input"

  # Assert: Check results
  [ "$status" -eq 0 ]
  [[ "$output" =~ "expected output" ]]
}
```

### Key Components

**`load`** - Load helper files or libraries:

```bash
load ../helpers/test_helpers
load ../helpers/assertion_helpers
```

**`setup()`** - Runs before each test:

```bash
setup() {
  source "${PROJECT_ROOT}/lib/installer-common/module.sh"
  TEST_DIR="$(mktemp -d)"
  export TEST_VAR="value"
}
```

**`teardown()`** - Runs after each test:

```bash
teardown() {
  rm -rf "$TEST_DIR"
  unset TEST_VAR
}
```

**`@test`** - Defines a test case:

```bash
@test "descriptive test name" {
  # Test code here
}
```

**`run`** - Executes command and captures output:

```bash
run my_function "arg1" "arg2"

# Captured variables:
# $status  - Exit code
# $output  - Combined stdout/stderr
# $lines   - Array of output lines
```

### Assertions

**Exit code assertions:**

```bash
[ "$status" -eq 0 ]     # Success
[ "$status" -eq 1 ]     # Failure
[ "$status" -ne 0 ]     # Any failure
```

**Output assertions:**

```bash
# Exact match
[ "$output" = "expected" ]

# Pattern match
[[ "$output" =~ "pattern" ]]

# Contains substring
[[ "$output" =~ "substring" ]]

# Empty output
[ -z "$output" ]

# Non-empty output
[ -n "$output" ]
```

**Line-specific assertions:**

```bash
# Check specific line
[ "${lines[0]}" = "first line" ]
[ "${lines[1]}" = "second line" ]

# Count lines
[ "${#lines[@]}" -eq 3 ]
```

**File/directory assertions:**

```bash
# File exists
[ -f "$TEST_DIR/file.txt" ]

# Directory exists
[ -d "$TEST_DIR/subdir" ]

# File is executable
[ -x "$TEST_DIR/script.sh" ]

# File is readable
[ -r "$TEST_DIR/file.txt" ]

# Symlink exists
[ -L "$TEST_DIR/link" ]
```

### Testing Interactive Functions

For functions that read user input, provide input via heredoc or pipe:

```bash
@test "prompt_yes_no accepts 'y' as yes" {
  # Use heredoc (<<<) to provide input
  run prompt_yes_no "Continue?" <<< "y"

  [ "$status" -eq 0 ]
}

@test "prompt_input handles multiple attempts" {
  # Provide multiple inputs (invalid then valid)
  run prompt_input "Number:" "" "^[0-9]+$" <<< $'abc\n42'

  [ "$status" -eq 0 ]
  [[ "$output" =~ "42" ]]
}
```

### Testing Error Conditions

```bash
@test "function fails with invalid input" {
  run my_function "invalid"

  # Should fail
  [ "$status" -ne 0 ]

  # Should have helpful error message
  [[ "$output" =~ "Error:" ]]
}

@test "function handles missing file gracefully" {
  run read_config "/nonexistent/file.json"

  [ "$status" -eq 1 ]
  [[ "$output" =~ "not found" ]]
}
```

### Testing with Mock Data

```bash
@test "function processes valid config" {
  # Use fixture file
  local config="${PROJECT_ROOT}/tests/fixtures/configs/sample-config.json"

  run process_config "$config"

  [ "$status" -eq 0 ]
}

@test "function creates expected file structure" {
  # Use temporary directory
  run create_structure "$TEST_DIR"

  [ "$status" -eq 0 ]
  [ -d "$TEST_DIR/subdir1" ]
  [ -d "$TEST_DIR/subdir2" ]
  [ -f "$TEST_DIR/file.txt" ]
}
```

## Testing Philosophy

### 1. Test Behavior, Not Implementation

#### Good: Tests what function does

```bash
@test "create_claude_dirs creates required directories" {
  run create_claude_dirs "$TEST_DIR"

  [ -d "$TEST_DIR/agents" ]
  [ -d "$TEST_DIR/knowledge" ]
  [ -d "$TEST_DIR/workflows" ]
}
```

#### Bad: Tests how it's implemented

```bash
@test "create_claude_dirs calls mkdir three times" {
  # Too tied to implementation details
  run create_claude_dirs "$TEST_DIR"
  [[ "$output" =~ "mkdir.*mkdir.*mkdir" ]]
}
```

### 2. One Assertion Per Test

#### Good: Focused test

```bash
@test "prompt_yes_no accepts 'y'" {
  run prompt_yes_no "Continue?" <<< "y"
  [ "$status" -eq 0 ]
}

@test "prompt_yes_no accepts 'n'" {
  run prompt_yes_no "Continue?" <<< "n"
  [ "$status" -eq 1 ]
}
```

#### Bad: Multiple assertions

```bash
@test "prompt_yes_no works" {
  run prompt_yes_no "Continue?" <<< "y"
  [ "$status" -eq 0 ]

  run prompt_yes_no "Continue?" <<< "n"
  [ "$status" -eq 1 ]

  run prompt_yes_no "Continue?" "y" <<< ""
  [ "$status" -eq 0 ]
}
```

### 3. Descriptive Test Names

Test names should read like documentation:

```bash
# Good: Clear what's being tested
@test "get_config_value returns empty string for missing key"
@test "create_symlink is idempotent"
@test "prompt_input validates regex pattern"

# Bad: Unclear what's tested
@test "test config"
@test "symlink works"
@test "validation"
```

### 4. Independent Tests

Each test should be self-contained:

```bash
# Good: Creates own test data
@test "function processes file" {
  local test_file="$TEST_DIR/test.txt"
  echo "data" > "$test_file"

  run process_file "$test_file"
  [ "$status" -eq 0 ]
}

# Bad: Depends on previous test
@test "function creates file" {
  run create_file "$TEST_DIR/test.txt"
  [ "$status" -eq 0 ]
}

@test "function processes file" {
  # Assumes previous test created file
  run process_file "$TEST_DIR/test.txt"
  [ "$status" -eq 0 ]
}
```

### 5. Fast Tests

Unit tests should be fast (<1 second each):

```bash
# Good: Fast test
@test "validates input format" {
  run validate_input "test@example.com"
  [ "$status" -eq 0 ]
}

# Bad: Slow test (use integration test instead)
@test "full installation works" {
  run ./install.sh --test-mode
  # Takes 30+ seconds...
}
```

## Test Helper Functions

Use helpers for common operations:

```bash
# Load helpers
load ../helpers/test_helpers

@test "example using helpers" {
  # Create temp directory
  setup_test_dir

  # Create test file
  echo "content" > "$TEST_DIR/file.txt"

  # Use assertion helper
  assert_file_exists "$TEST_DIR/file.txt"

  # Cleanup
  teardown_test_dir
}
```

See `tests/helpers/test_helpers.bash` for available helpers.

## Running Tests

### Run All Tests

```bash
# All unit tests
make test-unit

# All integration tests
make test-integration

# All tests
make test-all
```

### Run Specific Tests

```bash
# Single test file
bats tests/unit/test_prompts.bats

# Multiple files
bats tests/unit/test_prompts.bats tests/unit/test_config.bats

# All files in directory
bats tests/unit/*.bats
```

### Verbose Output

```bash
# Show all output (including passing tests)
bats --verbose tests/unit/test_prompts.bats

# Show test names as they run
bats --pretty tests/unit/test_prompts.bats
```

### TAP Output (for CI/CD)

```bash
# TAP format
bats --tap tests/unit/*.bats

# Save to file
bats --tap tests/unit/*.bats > results.tap
```

### Filter Tests

```bash
# Run tests matching pattern (requires bats 1.5+)
bats --filter "prompt_yes_no" tests/unit/test_prompts.bats
```

## Debugging Failing Tests

### 1. Run with Verbose Output

```bash
bats --verbose tests/unit/test_prompts.bats
```

### 2. Add Debug Output

```bash
@test "debugging example" {
  run my_function "input"

  # Print captured values
  echo "Status: $status" >&3
  echo "Output: $output" >&3
  echo "Lines: ${#lines[@]}" >&3

  [ "$status" -eq 0 ]
}
```

**Note**: Use `>&3` to print to stderr in bats (visible in verbose mode).

### 3. Run Function Directly

```bash
@test "debugging example" {
  # Instead of 'run', call directly to see errors
  my_function "input"
}
```

### 4. Inspect Test Environment

```bash
@test "debugging example" {
  echo "PWD: $PWD" >&3
  echo "PROJECT_ROOT: $PROJECT_ROOT" >&3
  echo "TEST_DIR: $TEST_DIR" >&3
  ls -la "$TEST_DIR" >&3
}
```

### 5. Skip Tests Temporarily

```bash
@test "skip this test" {
  skip "Debugging other tests first"

  # Test code...
}
```

## Common Patterns

### Testing File Creation

```bash
@test "function creates expected files" {
  run create_files "$TEST_DIR"

  [ "$status" -eq 0 ]
  [ -f "$TEST_DIR/file1.txt" ]
  [ -f "$TEST_DIR/file2.txt" ]
}
```

### Testing File Contents

```bash
@test "function writes correct content" {
  run write_config "$TEST_DIR/config.json"

  [ "$status" -eq 0 ]

  # Check file exists
  [ -f "$TEST_DIR/config.json" ]

  # Check content
  local content
  content=$(cat "$TEST_DIR/config.json")
  [[ "$content" =~ "expected_key" ]]
}
```

### Testing Idempotency

```bash
@test "function is idempotent" {
  # Run once
  run create_symlink "$TEST_DIR/link" "/target"
  [ "$status" -eq 0 ]

  # Run again - should succeed
  run create_symlink "$TEST_DIR/link" "/target"
  [ "$status" -eq 0 ]

  # Verify only one link
  [ -L "$TEST_DIR/link" ]
}
```

### Testing Error Messages

```bash
@test "function provides helpful error on failure" {
  run my_function "/invalid/path"

  [ "$status" -eq 1 ]
  [[ "$output" =~ "Error:" ]]
  [[ "$output" =~ "/invalid/path" ]]
}
```

## Best Practices

### DO

- **Write tests first** (TDD) when adding new features
- **Test edge cases** (empty input, special characters, etc.)
- **Use descriptive test names** that explain what's tested
- **Keep tests independent** - each test stands alone
- **Use setup/teardown** for common initialization
- **Clean up after tests** - remove temp files/directories
- **Test both success and failure** paths

### DON'T

- **Test implementation details** - focus on behavior
- **Share state between tests** - keep tests isolated
- **Make tests depend on execution order**
- **Skip cleanup** - always remove temp files
- **Test multiple things in one test**
- **Use hardcoded paths** - use TEST_DIR or fixtures
- **Leave debug output** - remove before committing

## Example Test File

Complete example of a well-structured test file:

```bash
#!/usr/bin/env bats

# Test: Prompts Module
# Tests all prompt functions for user input handling

# Load test helpers
load ../helpers/test_helpers

setup() {
  # Load module under test
  source "${PROJECT_ROOT}/lib/installer-common/prompts.sh"
}

# prompt_yes_no tests

@test "prompt_yes_no accepts 'y' as yes" {
  run prompt_yes_no "Continue?" <<< "y"
  [ "$status" -eq 0 ]
}

@test "prompt_yes_no accepts 'n' as no" {
  run prompt_yes_no "Continue?" <<< "n"
  [ "$status" -eq 1 ]
}

@test "prompt_yes_no uses default 'y' when empty" {
  run prompt_yes_no "Continue?" "y" <<< ""
  [ "$status" -eq 0 ]
}

@test "prompt_yes_no uses default 'n' when empty" {
  run prompt_yes_no "Continue?" "n" <<< ""
  [ "$status" -eq 1 ]
}

# prompt_input tests

@test "prompt_input returns user input" {
  run prompt_input "Name:" "" "" <<< "Alice"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Alice" ]]
}

@test "prompt_input validates regex pattern" {
  run prompt_input "Number:" "" "^[0-9]+$" <<< "42"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "42" ]]
}

@test "prompt_input rejects invalid input then accepts valid" {
  run prompt_input "Number:" "" "^[0-9]+$" <<< $'abc\n42'
  [ "$status" -eq 0 ]
  [[ "$output" =~ "42" ]]
}
```

## Next Steps

- Review existing tests in `tests/unit/` for examples
- Read [BATS_SETUP.md](./BATS_SETUP.md) for installation
- See [tests/README.md](../../tests/README.md) for test organization
- Check `tests/helpers/test_helpers.bash` for available helpers

## Resources

- **Bats Documentation**: <https://bats-core.readthedocs.io/>
- **Bats Tutorial**: <https://opensource.com/article/19/2/testing-bash-bats>
- **Testing Best Practices**: <https://github.com/bats-core/bats-core/wiki/Best-Practices>
