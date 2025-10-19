#!/usr/bin/env bats
#
# Unit tests for prompts.sh module
# Tests all user interaction and prompt functions

# Load test helpers
load ../helpers/test_helpers

setup() {
  # Load required dependencies
  source "${PROJECT_ROOT}/lib/installer-common/colors.sh"
  source "${PROJECT_ROOT}/lib/installer-common/logging.sh"
  source "${PROJECT_ROOT}/lib/installer-common/prompts.sh"
}

#######################################
# Tests for prompt_yes_no
#######################################

@test "prompt_yes_no accepts 'y' as yes" {
  run prompt_yes_no "Continue?" <<< "y"

  [ "$status" -eq 0 ]
}

@test "prompt_yes_no accepts 'Y' as yes" {
  run prompt_yes_no "Continue?" <<< "Y"

  [ "$status" -eq 0 ]
}

@test "prompt_yes_no accepts 'yes' as yes" {
  run prompt_yes_no "Continue?" <<< "yes"

  [ "$status" -eq 0 ]
}

@test "prompt_yes_no accepts 'n' as no" {
  run prompt_yes_no "Continue?" <<< "n"

  [ "$status" -eq 1 ]
}

@test "prompt_yes_no accepts 'N' as no" {
  run prompt_yes_no "Continue?" <<< "N"

  [ "$status" -eq 1 ]
}

@test "prompt_yes_no accepts 'no' as no" {
  run prompt_yes_no "Continue?" <<< "no"

  [ "$status" -eq 1 ]
}

@test "prompt_yes_no uses default 'y' when input is empty" {
  run prompt_yes_no "Continue?" "y" <<< ""

  [ "$status" -eq 0 ]
}

@test "prompt_yes_no uses default 'n' when input is empty" {
  run prompt_yes_no "Continue?" "n" <<< ""

  [ "$status" -eq 1 ]
}

@test "prompt_yes_no rejects invalid default value" {
  run prompt_yes_no "Continue?" "invalid"

  [ "$status" -eq 2 ]
  [[ "$output" =~ "Invalid default value" ]]
}

@test "prompt_yes_no retries on invalid input then accepts valid" {
  run prompt_yes_no "Continue?" <<< $'invalid\ny'

  [ "$status" -eq 0 ]
}

#######################################
# Tests for prompt_input
#######################################

@test "prompt_input returns user input" {
  run prompt_input "Enter name:" "" "" "" <<< "Alice"

  [ "$status" -eq 0 ]
  [[ "$output" =~ "Alice" ]]
}

@test "prompt_input uses default when input is empty" {
  run prompt_input "Enter name:" "Bob" "" "" <<< ""

  [ "$status" -eq 0 ]
  [[ "$output" =~ "Bob" ]]
}

@test "prompt_input validates regex pattern successfully" {
  run prompt_input "Enter number:" "" "^[0-9]+$" "" <<< "42"

  [ "$status" -eq 0 ]
  [[ "$output" =~ "42" ]]
}

@test "prompt_input rejects invalid regex then accepts valid" {
  run prompt_input "Enter number:" "" "^[0-9]+$" "Must be numeric" <<< $'abc\n42'

  [ "$status" -eq 0 ]
  [[ "$output" =~ "42" ]]
}

@test "prompt_input rejects empty input when no default" {
  # Provide empty input 6 times to exceed max retries
  run prompt_input "Enter name:" "" "" "" <<< $'\n\n\n\n\n\n'

  [ "$status" -eq 1 ]
  [[ "$output" =~ "Maximum retry attempts exceeded" ]]
}

@test "prompt_input shows custom validation error message" {
  run prompt_input "Enter email:" "" "^[^@]+@[^@]+$" "Invalid email" <<< $'notanemail\nuser@example.com'

  [ "$status" -eq 0 ]
  [[ "$output" =~ "Invalid email" ]]
  [[ "$output" =~ "user@example.com" ]]
}

#######################################
# Tests for prompt_select
#######################################

@test "prompt_select returns selected option" {
  local options=("Option 1" "Option 2" "Option 3")
  run prompt_select "Choose:" "${options[@]}" <<< "2"

  [ "$status" -eq 0 ]
  [[ "$output" =~ "Option 2" ]]
}

@test "prompt_select returns first option when selecting 1" {
  local options=("First" "Second" "Third")
  run prompt_select "Choose:" "${options[@]}" <<< "1"

  [ "$status" -eq 0 ]
  [[ "$output" =~ "First" ]]
}

@test "prompt_select returns last option when selecting max number" {
  local options=("First" "Second" "Third")
  run prompt_select "Choose:" "${options[@]}" <<< "3"

  [ "$status" -eq 0 ]
  [[ "$output" =~ "Third" ]]
}

@test "prompt_select rejects insufficient options" {
  run prompt_select "Choose:" "Only One Option"

  [ "$status" -eq 1 ]
  [[ "$output" =~ "requires at least 2 options" ]]
}

@test "prompt_select rejects out of range number then accepts valid" {
  local options=("First" "Second")
  run prompt_select "Choose:" "${options[@]}" <<< $'99\n1'

  [ "$status" -eq 0 ]
  [[ "$output" =~ "First" ]]
}

@test "prompt_select rejects non-numeric input then accepts valid" {
  local options=("First" "Second")
  run prompt_select "Choose:" "${options[@]}" <<< $'abc\n2'

  [ "$status" -eq 0 ]
  [[ "$output" =~ "Second" ]]
}

@test "prompt_select exceeds max retries with invalid input" {
  local options=("First" "Second")
  # Provide invalid input 6 times
  run prompt_select "Choose:" "${options[@]}" <<< $'abc\nabc\nabc\nabc\nabc\nabc'

  [ "$status" -eq 2 ]
  [[ "$output" =~ "Maximum retry attempts exceeded" ]]
}

#######################################
# Tests for confirm_action
#######################################

@test "confirm_action accepts 'yes' as confirmation" {
  run confirm_action "Delete files" <<< "yes"

  [ "$status" -eq 0 ]
}

@test "confirm_action rejects 'y' as confirmation" {
  run confirm_action "Delete files" <<< "y"

  [ "$status" -eq 1 ]
  [[ "$output" =~ "Action cancelled" ]]
}

@test "confirm_action rejects 'YES' as confirmation" {
  run confirm_action "Delete files" <<< "YES"

  [ "$status" -eq 1 ]
  [[ "$output" =~ "Action cancelled" ]]
}

@test "confirm_action rejects empty input" {
  run confirm_action "Delete files" <<< ""

  [ "$status" -eq 1 ]
  [[ "$output" =~ "Action cancelled" ]]
}

@test "confirm_action displays warning message when provided" {
  run confirm_action "Delete files" "This cannot be undone" <<< "yes"

  [ "$status" -eq 0 ]
  [[ "$output" =~ "This cannot be undone" ]]
}

#######################################
# Tests for prompt_input_validated
#######################################

@test "prompt_input_validated returns valid input with custom function" {
  # Define validation function
  validate_even() {
    local num="$1"
    [[ $((num % 2)) -eq 0 ]]
  }

  run prompt_input_validated "Enter even number:" "" "validate_even" "Must be even" <<< "42"

  [ "$status" -eq 0 ]
  [[ "$output" =~ "42" ]]
}

@test "prompt_input_validated rejects invalid then accepts valid with custom function" {
  # Define validation function
  validate_even() {
    local num="$1"
    [[ $((num % 2)) -eq 0 ]]
  }

  run prompt_input_validated "Enter even number:" "" "validate_even" "Must be even" <<< $'41\n42'

  [ "$status" -eq 0 ]
  [[ "$output" =~ "Must be even" ]]
  [[ "$output" =~ "42" ]]
}

@test "prompt_input_validated fails with undefined validation function" {
  run prompt_input_validated "Enter value:" "" "nonexistent_function" "" <<< "test"

  [ "$status" -eq 2 ]
  [[ "$output" =~ "not defined" ]]
}

@test "prompt_input_validated works without validation function" {
  run prompt_input_validated "Enter name:" "" "" "" <<< "Alice"

  [ "$status" -eq 0 ]
  [[ "$output" =~ "Alice" ]]
}

#######################################
# Tests for prompt_info
#######################################

@test "prompt_info displays message without waiting" {
  run prompt_info "Installation starting" "false"

  [ "$status" -eq 0 ]
  [[ "$output" =~ "Installation starting" ]]
}

# Note: prompt_info with wait_for_user=true uses interactive 'read -rp' which
# cannot be reliably tested in automated tests. Verified through manual testing.
