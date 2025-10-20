#!/usr/bin/env bats
#
# Unit tests for summary.sh module
# Tests installation summary display functions

# Load test helpers
load ../helpers/test_helpers

setup() {
  # Load required dependencies
  source "${PROJECT_ROOT}/lib/installer-common/colors.sh"
  source "${PROJECT_ROOT}/lib/installer-common/logging.sh"
  source "${PROJECT_ROOT}/lib/installer-common/summary.sh"

  # Create temporary test directory
  setup_test_dir

  # Mock HOME for testing
  export HOME="$TEST_DIR"
}

teardown() {
  teardown_test_dir
}

#######################################
# Tests for get_terminal_width
#######################################

@test "get_terminal_width returns numeric value" {
  run get_terminal_width

  [ "$status" -eq 0 ]
  [[ "$output" =~ ^[0-9]+$ ]]
}

@test "get_terminal_width returns at least 80 columns" {
  local width
  width=$(get_terminal_width)

  [ "$width" -ge 80 ] || [ "$width" -eq 80 ]
}

#######################################
# Tests for draw_horizontal_line
#######################################

@test "draw_horizontal_line draws line" {
  run draw_horizontal_line 40

  [ "$status" -eq 0 ]
  [ -n "$output" ]
}

@test "draw_horizontal_line respects width parameter" {
  local output
  output=$(draw_horizontal_line 20)

  local length=${#output}
  [ "$length" -eq 20 ] || [ "$length" -eq 21 ]  # Account for newline
}

#######################################
# Tests for count_templates
#######################################

@test "count_templates returns 0 for empty directory" {
  mkdir -p "$TEST_DIR/templates"

  run count_templates "$TEST_DIR/templates"

  [ "$status" -eq 0 ]
  [ "$output" = "0" ]
}

@test "count_templates counts .md files" {
  mkdir -p "$TEST_DIR/templates"
  touch "$TEST_DIR/templates/command1.md"
  touch "$TEST_DIR/templates/command2.md"
  touch "$TEST_DIR/templates/command3.md"

  run count_templates "$TEST_DIR/templates"

  [ "$status" -eq 0 ]
  [ "$output" = "3" ]
}

@test "count_templates ignores non-.md files" {
  mkdir -p "$TEST_DIR/templates"
  touch "$TEST_DIR/templates/command1.md"
  touch "$TEST_DIR/templates/readme.txt"
  touch "$TEST_DIR/templates/config.json"

  run count_templates "$TEST_DIR/templates"

  [ "$status" -eq 0 ]
  [ "$output" = "1" ]
}

@test "count_templates returns 0 for nonexistent directory" {
  run count_templates "$TEST_DIR/nonexistent"

  [ "$status" -eq 0 ]
  [ "$output" = "0" ]
}

@test "count_templates ignores subdirectories" {
  mkdir -p "$TEST_DIR/templates/subdir"
  touch "$TEST_DIR/templates/command1.md"
  touch "$TEST_DIR/templates/subdir/command2.md"

  run count_templates "$TEST_DIR/templates"

  [ "$status" -eq 0 ]
  [ "$output" = "1" ]
}

#######################################
# Tests for count_agents
#######################################

@test "count_agents returns 0 for empty directory" {
  mkdir -p "$TEST_DIR/agents"

  run count_agents "$TEST_DIR/agents"

  [ "$status" -eq 0 ]
  [ "$output" = "0" ]
}

@test "count_agents counts subdirectories" {
  mkdir -p "$TEST_DIR/agents/agent1"
  mkdir -p "$TEST_DIR/agents/agent2"
  mkdir -p "$TEST_DIR/agents/agent3"

  run count_agents "$TEST_DIR/agents"

  [ "$status" -eq 0 ]
  [ "$output" = "3" ]
}

@test "count_agents ignores files" {
  mkdir -p "$TEST_DIR/agents/agent1"
  touch "$TEST_DIR/agents/readme.md"
  touch "$TEST_DIR/agents/config.json"

  run count_agents "$TEST_DIR/agents"

  [ "$status" -eq 0 ]
  [ "$output" = "1" ]
}

@test "count_agents returns 0 for nonexistent directory" {
  run count_agents "$TEST_DIR/nonexistent"

  [ "$status" -eq 0 ]
  [ "$output" = "0" ]
}

#######################################
# Tests for display_summary
#######################################

@test "display_summary shows version" {
  local aida_dir="$TEST_DIR/.aida"
  local claude_dir="$TEST_DIR/.claude"

  mkdir -p "$aida_dir" "$claude_dir"

  run display_summary "normal" "$aida_dir" "$claude_dir" "1.2.3"

  [ "$status" -eq 0 ]
  [[ "$output" =~ 1.2.3 ]]
}

@test "display_summary shows normal mode" {
  local aida_dir="$TEST_DIR/.aida"
  local claude_dir="$TEST_DIR/.claude"

  mkdir -p "$aida_dir" "$claude_dir"

  run display_summary "normal" "$aida_dir" "$claude_dir" "1.0.0"

  [ "$status" -eq 0 ]
  [[ "$output" =~ "Normal installation" ]]
}

@test "display_summary shows dev mode" {
  local aida_dir="$TEST_DIR/.aida"
  local claude_dir="$TEST_DIR/.claude"

  mkdir -p "$aida_dir" "$claude_dir"

  run display_summary "dev" "$aida_dir" "$claude_dir" "1.0.0"

  [ "$status" -eq 0 ]
  [[ "$output" =~ "Development mode" ]]
}

@test "display_summary shows directory paths" {
  local aida_dir="$TEST_DIR/.aida"
  local claude_dir="$TEST_DIR/.claude"

  mkdir -p "$aida_dir" "$claude_dir"

  run display_summary "normal" "$aida_dir" "$claude_dir" "1.0.0"

  [ "$status" -eq 0 ]
  [[ "$output" =~ "Framework:" ]]
  [[ "$output" =~ "Configuration:" ]]
}

@test "display_summary shows template counts when present" {
  local aida_dir="$TEST_DIR/.aida"
  local claude_dir="$TEST_DIR/.claude"

  mkdir -p "$aida_dir" "$claude_dir/commands" "$claude_dir/agents/agent1"
  touch "$claude_dir/commands/cmd1.md"
  touch "$claude_dir/commands/cmd2.md"

  run display_summary "normal" "$aida_dir" "$claude_dir" "1.0.0"

  [ "$status" -eq 0 ]
  [[ "$output" =~ "Commands:" ]]
  [[ "$output" =~ "2 templates" ]]
}

#######################################
# Tests for display_next_steps
#######################################

@test "display_next_steps shows standard steps" {
  run display_next_steps "normal"

  [ "$status" -eq 0 ]
  [[ "$output" =~ "NEXT STEPS" ]]
  [[ "$output" =~ "Review configuration" ]]
}

@test "display_next_steps shows dev mode message in dev mode" {
  run display_next_steps "dev"

  [ "$status" -eq 0 ]
  [[ "$output" =~ "Development mode" ]]
}

@test "display_next_steps does not show dev message in normal mode" {
  run display_next_steps "normal"

  [ "$status" -eq 0 ]
  [[ ! "$output" =~ "Development mode" ]]
}

#######################################
# Tests for display_success
#######################################

@test "display_success shows success message" {
  run display_success "Installation complete"

  [ "$status" -eq 0 ]
  [[ "$output" =~ "Installation complete" ]]
}

@test "display_success shows optional details" {
  run display_success "Installation complete" "Details here"

  [ "$status" -eq 0 ]
  [[ "$output" =~ "Installation complete" ]]
  [[ "$output" =~ "Details here" ]]
}

#######################################
# Tests for display_error
#######################################

@test "display_error shows error message" {
  run display_error "Something failed" 2>&1

  [ "$status" -eq 0 ]
  [[ "$output" =~ "Something failed" ]]
}

@test "display_error shows recovery steps when provided" {
  local recovery="Step 1: Fix the issue
Step 2: Try again"

  run display_error "Something failed" "$recovery" 2>&1

  [ "$status" -eq 0 ]
  [[ "$output" =~ "Something failed" ]]
  [[ "$output" =~ "Recovery steps" ]]
  [[ "$output" =~ "Step 1" ]]
}

#######################################
# Tests for display_upgrade_summary
#######################################

@test "display_upgrade_summary shows version upgrade" {
  run display_upgrade_summary "1.0.0" "2.0.0" 5

  [ "$status" -eq 0 ]
  [[ "$output" =~ 1.0.0 ]]
  [[ "$output" =~ 2.0.0 ]]
  [[ "$output" =~ "UPGRADE COMPLETE" ]]
}

@test "display_upgrade_summary shows preserved files count" {
  run display_upgrade_summary "1.0.0" "2.0.0" 10

  [ "$status" -eq 0 ]
  [[ "$output" =~ "10 files preserved" ]]
}

@test "display_upgrade_summary shows zero preserved files" {
  run display_upgrade_summary "1.0.0" "2.0.0" 0

  [ "$status" -eq 0 ]
  # Should not show preserved files message when count is 0
  [[ ! "$output" =~ "files preserved" ]]
}

#######################################
# Tests for draw_box_header
#######################################

@test "draw_box_header draws header with title" {
  run draw_box_header "TEST TITLE"

  [ "$status" -eq 0 ]
  [[ "$output" =~ "TEST TITLE" ]]
}

#######################################
# Tests for draw_box
#######################################

@test "draw_box draws box with title and content" {
  run draw_box "Title" "Line 1" "Line 2"

  [ "$status" -eq 0 ]
  [[ "$output" =~ "Title" ]]
  [[ "$output" =~ "Line 1" ]]
  [[ "$output" =~ "Line 2" ]]
}
