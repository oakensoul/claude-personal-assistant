#!/usr/bin/env bash
# Test helper functions for Bats unit tests
# Provides common utilities for testing AIDA installer modules

# Get project root directory
PROJECT_ROOT="$(cd "$(dirname "${BATS_TEST_DIRNAME}")/.." && pwd)"
export PROJECT_ROOT

# Test directory for temporary files
export TEST_DIR=""

# Load a specific installer module
# Usage: load_test_lib "prompts"
load_test_lib() {
  local lib="$1"

  if [[ -z "$lib" ]]; then
    echo "Error: load_test_lib requires module name" >&2
    return 1
  fi

  local lib_path="${PROJECT_ROOT}/lib/installer-common/${lib}.sh"

  if [[ ! -f "$lib_path" ]]; then
    echo "Error: Module not found: $lib_path" >&2
    return 1
  fi

  # shellcheck source=/dev/null
  source "$lib_path"
}

# Create temporary test directory
# Usage: setup_test_dir
# Sets: TEST_DIR environment variable
setup_test_dir() {
  TEST_DIR="$(mktemp -d)"
  export TEST_DIR

  if [[ ! -d "$TEST_DIR" ]]; then
    echo "Error: Failed to create test directory" >&2
    return 1
  fi
}

# Clean up temporary test directory
# Usage: teardown_test_dir
teardown_test_dir() {
  if [[ -n "${TEST_DIR:-}" ]] && [[ -d "$TEST_DIR" ]]; then
    rm -rf "$TEST_DIR"
  fi
  unset TEST_DIR
}

# Assert file exists
# Usage: assert_file_exists "/path/to/file"
assert_file_exists() {
  local file="$1"

  if [[ -z "$file" ]]; then
    echo "Error: assert_file_exists requires file path" >&2
    return 1
  fi

  if [[ ! -f "$file" ]]; then
    echo "Assertion failed: File not found: $file" >&2
    return 1
  fi

  return 0
}

# Assert directory exists
# Usage: assert_dir_exists "/path/to/directory"
assert_dir_exists() {
  local dir="$1"

  if [[ -z "$dir" ]]; then
    echo "Error: assert_dir_exists requires directory path" >&2
    return 1
  fi

  if [[ ! -d "$dir" ]]; then
    echo "Assertion failed: Directory not found: $dir" >&2
    return 1
  fi

  return 0
}

# Assert file contains text
# Usage: assert_file_contains "/path/to/file" "search text"
assert_file_contains() {
  local file="$1"
  local text="$2"

  if [[ -z "$file" ]] || [[ -z "$text" ]]; then
    echo "Error: assert_file_contains requires file and text" >&2
    return 1
  fi

  if [[ ! -f "$file" ]]; then
    echo "Assertion failed: File not found: $file" >&2
    return 1
  fi

  if ! grep -q "$text" "$file"; then
    echo "Assertion failed: File does not contain '$text': $file" >&2
    return 1
  fi

  return 0
}

# Assert symlink exists and points to target
# Usage: assert_symlink_target "/path/to/link" "/expected/target"
assert_symlink_target() {
  local link="$1"
  local expected_target="$2"

  if [[ -z "$link" ]] || [[ -z "$expected_target" ]]; then
    echo "Error: assert_symlink_target requires link and target" >&2
    return 1
  fi

  if [[ ! -L "$link" ]]; then
    echo "Assertion failed: Symlink not found: $link" >&2
    return 1
  fi

  local actual_target
  actual_target=$(readlink "$link")

  if [[ "$actual_target" != "$expected_target" ]]; then
    echo "Assertion failed: Symlink target mismatch" >&2
    echo "  Link: $link" >&2
    echo "  Expected: $expected_target" >&2
    echo "  Actual: $actual_target" >&2
    return 1
  fi

  return 0
}

# Assert file has specific permissions
# Usage: assert_file_permissions "/path/to/file" "644"
assert_file_permissions() {
  local file="$1"
  local expected_perms="$2"

  if [[ -z "$file" ]] || [[ -z "$expected_perms" ]]; then
    echo "Error: assert_file_permissions requires file and permissions" >&2
    return 1
  fi

  if [[ ! -e "$file" ]]; then
    echo "Assertion failed: File/directory not found: $file" >&2
    return 1
  fi

  # Get permissions in octal format (cross-platform)
  local actual_perms
  if [[ "$(uname)" == "Darwin" ]]; then
    # macOS (BSD stat)
    actual_perms=$(stat -f "%OLp" "$file")
  else
    # Linux (GNU stat)
    actual_perms=$(stat -c "%a" "$file")
  fi

  if [[ "$actual_perms" != "$expected_perms" ]]; then
    echo "Assertion failed: Permission mismatch for $file" >&2
    echo "  Expected: $expected_perms" >&2
    echo "  Actual: $actual_perms" >&2
    return 1
  fi

  return 0
}

# Assert JSON is valid
# Usage: assert_valid_json '{"key": "value"}'
assert_valid_json() {
  local json="$1"

  if [[ -z "$json" ]]; then
    echo "Error: assert_valid_json requires JSON string" >&2
    return 1
  fi

  if ! echo "$json" | jq . >/dev/null 2>&1; then
    echo "Assertion failed: Invalid JSON" >&2
    echo "$json" >&2
    return 1
  fi

  return 0
}

# Assert JSON file is valid
# Usage: assert_valid_json_file "/path/to/file.json"
assert_valid_json_file() {
  local file="$1"

  if [[ -z "$file" ]]; then
    echo "Error: assert_valid_json_file requires file path" >&2
    return 1
  fi

  if [[ ! -f "$file" ]]; then
    echo "Assertion failed: File not found: $file" >&2
    return 1
  fi

  if ! jq . "$file" >/dev/null 2>&1; then
    echo "Assertion failed: Invalid JSON in file: $file" >&2
    return 1
  fi

  return 0
}

# Assert command succeeds
# Usage: assert_success command arg1 arg2
assert_success() {
  if ! "$@" >/dev/null 2>&1; then
    echo "Assertion failed: Command failed: $*" >&2
    return 1
  fi

  return 0
}

# Assert command fails
# Usage: assert_failure command arg1 arg2
assert_failure() {
  if "$@" >/dev/null 2>&1; then
    echo "Assertion failed: Command succeeded (expected failure): $*" >&2
    return 1
  fi

  return 0
}

# Create a mock file with content
# Usage: create_mock_file "/path/to/file" "content"
create_mock_file() {
  local file="$1"
  local content="$2"

  if [[ -z "$file" ]]; then
    echo "Error: create_mock_file requires file path" >&2
    return 1
  fi

  local dir
  dir=$(dirname "$file")

  if [[ ! -d "$dir" ]]; then
    mkdir -p "$dir" || {
      echo "Error: Failed to create directory: $dir" >&2
      return 1
    }
  fi

  echo "$content" > "$file" || {
    echo "Error: Failed to create file: $file" >&2
    return 1
  }

  return 0
}

# Create a mock JSON file
# Usage: create_mock_json_file "/path/to/file.json" '{"key": "value"}'
create_mock_json_file() {
  local file="$1"
  local json="$2"

  if [[ -z "$file" ]] || [[ -z "$json" ]]; then
    echo "Error: create_mock_json_file requires file and JSON" >&2
    return 1
  fi

  # Validate JSON first
  if ! echo "$json" | jq . >/dev/null 2>&1; then
    echo "Error: Invalid JSON" >&2
    return 1
  fi

  local dir
  dir=$(dirname "$file")

  if [[ ! -d "$dir" ]]; then
    mkdir -p "$dir" || {
      echo "Error: Failed to create directory: $dir" >&2
      return 1
    }
  fi

  echo "$json" | jq . > "$file" || {
    echo "Error: Failed to create JSON file: $file" >&2
    return 1
  }

  return 0
}

# Create a mock directory structure
# Usage: create_mock_dir_structure "$TEST_DIR" "dir1" "dir2/subdir"
create_mock_dir_structure() {
  local base_dir="$1"
  shift

  if [[ -z "$base_dir" ]]; then
    echo "Error: create_mock_dir_structure requires base directory" >&2
    return 1
  fi

  for dir in "$@"; do
    mkdir -p "${base_dir}/${dir}" || {
      echo "Error: Failed to create directory: ${base_dir}/${dir}" >&2
      return 1
    }
  done

  return 0
}

# Print debug information (visible with bats --verbose)
# Usage: debug "Variable value: $var"
debug() {
  echo "[DEBUG] $*" >&3
}

# Print test section header (visible with bats --verbose)
# Usage: section "Setup phase"
section() {
  echo "" >&3
  echo "=== $* ===" >&3
}
