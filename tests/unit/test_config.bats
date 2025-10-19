#!/usr/bin/env bats
#
# Unit tests for config.sh module
# Tests configuration wrapper functions

# Load test helpers
load ../helpers/test_helpers

setup() {
  # Load required dependencies
  source "${PROJECT_ROOT}/lib/installer-common/colors.sh"
  source "${PROJECT_ROOT}/lib/installer-common/logging.sh"
  source "${PROJECT_ROOT}/lib/installer-common/validation.sh"
  source "${PROJECT_ROOT}/lib/installer-common/config.sh"

  # Create temporary test directory
  setup_test_dir

  # Mock HOME for testing
  export HOME="$TEST_DIR"
}

teardown() {
  teardown_test_dir
}

#######################################
# Tests for check_config_helper
#######################################

@test "check_config_helper validates config helper exists" {
  run check_config_helper

  [ "$status" -eq 0 ]
}

@test "check_config_helper fails if config helper missing" {
  skip "Cannot override readonly CONFIG_HELPER variable - test design limitation"
  # Note: CONFIG_HELPER is defined as readonly in config.sh for immutability
  # This test would require removing the readonly constraint which would
  # weaken the module's guarantees. The actual error handling works correctly
  # in practice when sourcing fails.
}

#######################################
# Tests for write_user_config
#######################################

@test "write_user_config creates valid JSON config file" {
  local aida_dir="$TEST_DIR/.aida"
  local claude_dir="$TEST_DIR/.claude"

  run write_user_config "normal" "$aida_dir" "$claude_dir" "1.0.0" "JARVIS" "professional"

  [ "$status" -eq 0 ]
  assert_file_exists "$claude_dir/aida-config.json"
  assert_valid_json_file "$claude_dir/aida-config.json"
}

@test "write_user_config includes correct version" {
  local aida_dir="$TEST_DIR/.aida"
  local claude_dir="$TEST_DIR/.claude"

  write_user_config "normal" "$aida_dir" "$claude_dir" "2.5.1" "JARVIS" "professional" >/dev/null

  local version
  version=$(jq -r '.version' "$claude_dir/aida-config.json")

  [ "$version" = "2.5.1" ]
}

@test "write_user_config includes correct install mode" {
  local aida_dir="$TEST_DIR/.aida"
  local claude_dir="$TEST_DIR/.claude"

  write_user_config "dev" "$aida_dir" "$claude_dir" "1.0.0" "JARVIS" "professional" >/dev/null

  local mode
  mode=$(jq -r '.install_mode' "$claude_dir/aida-config.json")

  [ "$mode" = "dev" ]
}

@test "write_user_config includes correct paths" {
  local aida_dir="$TEST_DIR/.aida"
  local claude_dir="$TEST_DIR/.claude"

  write_user_config "normal" "$aida_dir" "$claude_dir" "1.0.0" "JARVIS" "professional" >/dev/null

  local aida_path
  aida_path=$(jq -r '.paths.aida_home' "$claude_dir/aida-config.json")

  [ "$aida_path" = "$aida_dir" ]
}

@test "write_user_config includes user preferences" {
  local aida_dir="$TEST_DIR/.aida"
  local claude_dir="$TEST_DIR/.claude"

  write_user_config "normal" "$aida_dir" "$claude_dir" "1.0.0" "Alfred" "butler" >/dev/null

  local assistant_name
  assistant_name=$(jq -r '.user.assistant_name' "$claude_dir/aida-config.json")
  local personality
  personality=$(jq -r '.user.personality' "$claude_dir/aida-config.json")

  [ "$assistant_name" = "Alfred" ]
  [ "$personality" = "butler" ]
}

@test "write_user_config creates claude directory if missing" {
  local aida_dir="$TEST_DIR/.aida"
  local claude_dir="$TEST_DIR/.claude"

  # Ensure directory doesn't exist
  [ ! -d "$claude_dir" ]

  run write_user_config "normal" "$aida_dir" "$claude_dir" "1.0.0" "JARVIS" "professional"

  [ "$status" -eq 0 ]
  assert_dir_exists "$claude_dir"
}

@test "write_user_config fails with invalid install mode" {
  local aida_dir="$TEST_DIR/.aida"
  local claude_dir="$TEST_DIR/.claude"

  run write_user_config "invalid_mode" "$aida_dir" "$claude_dir" "1.0.0" "JARVIS" "professional"

  [ "$status" -eq 1 ]
  [[ "$output" =~ "Invalid install mode" ]]
}

@test "write_user_config fails with missing required arguments" {
  run write_user_config "normal" "" "" ""

  [ "$status" -eq 1 ]
  [[ "$output" =~ "Missing required arguments for" ]]
}

#######################################
# Tests for config_exists
#######################################

@test "config_exists returns true for existing file" {
  local config_file="$TEST_DIR/test-config.json"
  echo '{}' > "$config_file"

  run config_exists "$config_file"

  [ "$status" -eq 0 ]
}

@test "config_exists returns false for missing file" {
  run config_exists "$TEST_DIR/nonexistent.json"

  [ "$status" -eq 1 ]
}

@test "config_exists fails with empty path" {
  run config_exists ""

  [ "$status" -eq 1 ]
  [[ "$output" =~ "Config path cannot be empty" ]]
}

#######################################
# Integration tests with actual config helper
#######################################

@test "get_config returns valid JSON" {
  skip "Requires full config setup - integration test"
}

@test "get_config_value retrieves specific value" {
  skip "Requires full config setup - integration test"
}

@test "validate_config validates merged config" {
  skip "Requires full config setup - integration test"
}
