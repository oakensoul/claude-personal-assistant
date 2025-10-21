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

#######################################
# Tests for write_user_config
#######################################

@test "write_user_config creates valid JSON config file" {
  local aida_dir="$TEST_DIR/.aida"
  local claude_dir="$TEST_DIR/.claude"

  run write_user_config "normal" "$aida_dir" "$claude_dir" "1.0.0" "JARVIS" "professional"

  [ "$status" -eq 0 ]
  assert_file_exists "$claude_dir/config.json"
  assert_valid_json_file "$claude_dir/config.json"
}

@test "write_user_config includes correct version" {
  local aida_dir="$TEST_DIR/.aida"
  local claude_dir="$TEST_DIR/.claude"

  write_user_config "normal" "$aida_dir" "$claude_dir" "2.5.1" "JARVIS" "professional" >/dev/null

  local version
  version=$(jq -r '.version' "$claude_dir/config.json")

  [ "$version" = "2.5.1" ]
}

@test "write_user_config includes correct install mode" {
  local aida_dir="$TEST_DIR/.aida"
  local claude_dir="$TEST_DIR/.claude"

  write_user_config "dev" "$aida_dir" "$claude_dir" "1.0.0" "JARVIS" "professional" >/dev/null

  local mode
  mode=$(jq -r '.install_mode' "$claude_dir/config.json")

  [ "$mode" = "dev" ]
}

@test "write_user_config includes correct paths" {
  local aida_dir="$TEST_DIR/.aida"
  local claude_dir="$TEST_DIR/.claude"

  write_user_config "normal" "$aida_dir" "$claude_dir" "1.0.0" "JARVIS" "professional" >/dev/null

  local aida_path
  aida_path=$(jq -r '.paths.aida_home' "$claude_dir/config.json")

  [ "$aida_path" = "$aida_dir" ]
}

@test "write_user_config includes user preferences" {
  local aida_dir="$TEST_DIR/.aida"
  local claude_dir="$TEST_DIR/.claude"

  write_user_config "normal" "$aida_dir" "$claude_dir" "1.0.0" "Alfred" "butler" >/dev/null

  local assistant_name
  assistant_name=$(jq -r '.user.assistant_name' "$claude_dir/config.json")
  local personality
  personality=$(jq -r '.user.personality' "$claude_dir/config.json")

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
