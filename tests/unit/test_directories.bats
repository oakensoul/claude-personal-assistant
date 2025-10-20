#!/usr/bin/env bats
#
# Unit tests for directories.sh module
# Tests directory creation, symlink management, and backup operations

# Load test helpers
load ../helpers/test_helpers

setup() {
  # Load required dependencies
  source "${PROJECT_ROOT}/lib/installer-common/colors.sh"
  source "${PROJECT_ROOT}/lib/installer-common/logging.sh"
  source "${PROJECT_ROOT}/lib/installer-common/validation.sh"
  source "${PROJECT_ROOT}/lib/installer-common/directories.sh"

  # Create temporary test directory
  setup_test_dir
}

teardown() {
  teardown_test_dir
}

#######################################
# Tests for create_symlink
#######################################

@test "create_symlink creates valid symlink" {
  local target="$TEST_DIR/target"
  local link="$TEST_DIR/link"

  mkdir -p "$target"

  run create_symlink "$target" "$link"

  [ "$status" -eq 0 ]
  [ -L "$link" ]
  assert_symlink_target "$link" "$target"
}

@test "create_symlink is idempotent" {
  local target="$TEST_DIR/target"
  local link="$TEST_DIR/link"

  mkdir -p "$target"

  # Create once
  create_symlink "$target" "$link" >/dev/null

  # Create again - should succeed
  run create_symlink "$target" "$link"

  [ "$status" -eq 0 ]
  [[ "$output" =~ "already correct" ]]
}

@test "create_symlink recreates incorrect symlink" {
  local target="$TEST_DIR/target"
  local wrong_target="$TEST_DIR/wrong"
  local link="$TEST_DIR/link"

  mkdir -p "$target" "$wrong_target"

  # Create symlink to wrong target
  ln -s "$wrong_target" "$link"

  # Recreate with correct target
  run create_symlink "$target" "$link"

  [ "$status" -eq 0 ]
  assert_symlink_target "$link" "$target"
}

@test "create_symlink fails if target does not exist" {
  local target="$TEST_DIR/nonexistent"
  local link="$TEST_DIR/link"

  run create_symlink "$target" "$link"

  [ "$status" -eq 1 ]
  [[ "$output" =~ "does not exist" ]]
}

@test "create_symlink fails if link path exists as regular file" {
  local target="$TEST_DIR/target"
  local link="$TEST_DIR/link"

  mkdir -p "$target"
  touch "$link"  # Regular file

  run create_symlink "$target" "$link"

  [ "$status" -eq 1 ]
  [[ "$output" =~ "not a symlink" ]]
}

@test "create_symlink creates parent directory if needed" {
  local target="$TEST_DIR/target"
  local link="$TEST_DIR/nested/deep/link"

  mkdir -p "$target"

  run create_symlink "$target" "$link"

  [ "$status" -eq 0 ]
  assert_dir_exists "$TEST_DIR/nested/deep"
  assert_symlink_target "$link" "$target"
}

@test "create_symlink fails with empty target" {
  run create_symlink "" "$TEST_DIR/link"

  [ "$status" -eq 1 ]
  [[ "$output" =~ "target path required" ]]
}

@test "create_symlink fails with empty link name" {
  run create_symlink "$TEST_DIR/target" ""

  [ "$status" -eq 1 ]
  [[ "$output" =~ "link_name required" ]]
}

#######################################
# Tests for backup_existing
#######################################

@test "backup_existing backs up directory" {
  local target="$TEST_DIR/mydir"

  mkdir -p "$target"
  echo "test" > "$target/file.txt"

  run backup_existing "$target"

  [ "$status" -eq 0 ]
  [[ "$output" =~ "Backed up directory" ]]

  # Check backup exists with timestamp format
  local backup
  backup=$(ls -d "${target}.backup."* 2>/dev/null | head -n1)
  [ -n "$backup" ]
  [ -d "$backup" ]
  [ -f "$backup/file.txt" ]
}

@test "backup_existing backs up file" {
  local target="$TEST_DIR/myfile.txt"

  echo "content" > "$target"

  run backup_existing "$target"

  [ "$status" -eq 0 ]
  [[ "$output" =~ "Backed up file" ]]

  # Check backup exists
  local backup
  backup=$(ls "${target}.backup."* 2>/dev/null | head -n1)
  [ -n "$backup" ]
  [ -f "$backup" ]
}

@test "backup_existing is idempotent when target does not exist" {
  local target="$TEST_DIR/nonexistent"

  run backup_existing "$target"

  [ "$status" -eq 0 ]
  [[ "$output" =~ "No backup needed" ]]
}

@test "backup_existing preserves file permissions" {
  local target="$TEST_DIR/executable.sh"

  echo "#!/bin/bash" > "$target"
  chmod 755 "$target"

  backup_existing "$target" >/dev/null

  # Check backup has same permissions
  local backup
  backup=$(ls "${target}.backup."* 2>/dev/null | head -n1)

  if [[ "$(uname)" == "Darwin" ]]; then
    # macOS (BSD stat)
    local orig_perms
    orig_perms=$(stat -f "%OLp" "$target")
    local backup_perms
    backup_perms=$(stat -f "%OLp" "$backup")
  else
    # Linux (GNU stat)
    local orig_perms
    orig_perms=$(stat -c "%a" "$target")
    local backup_perms
    backup_perms=$(stat -c "%a" "$backup")
  fi

  [ "$orig_perms" = "$backup_perms" ]
}

@test "backup_existing fails with empty target" {
  run backup_existing ""

  [ "$status" -eq 1 ]
  [[ "$output" =~ "target path required" ]]
}

#######################################
# Tests for create_claude_dirs
#######################################

@test "create_claude_dirs creates all required directories" {
  local claude_dir="$TEST_DIR/.claude"

  run create_claude_dirs "$claude_dir"

  [ "$status" -eq 0 ]
  assert_dir_exists "$claude_dir"
  assert_dir_exists "$claude_dir/commands"
  assert_dir_exists "$claude_dir/agents"
  assert_dir_exists "$claude_dir/skills"
  assert_dir_exists "$claude_dir/config"
  assert_dir_exists "$claude_dir/knowledge"
  assert_dir_exists "$claude_dir/memory"
  assert_dir_exists "$claude_dir/memory/history"
}

@test "create_claude_dirs is idempotent" {
  local claude_dir="$TEST_DIR/.claude"

  # Create once
  create_claude_dirs "$claude_dir" >/dev/null

  # Create again
  run create_claude_dirs "$claude_dir"

  [ "$status" -eq 0 ]
  [[ "$output" =~ "already exists" ]]
}

@test "create_claude_dirs sets correct permissions" {
  local claude_dir="$TEST_DIR/.claude"

  create_claude_dirs "$claude_dir" >/dev/null

  assert_file_permissions "$claude_dir" "755"
  assert_file_permissions "$claude_dir/commands" "755"
  assert_file_permissions "$claude_dir/agents" "755"
}

@test "create_claude_dirs fails with empty path" {
  run create_claude_dirs ""

  [ "$status" -eq 1 ]
  [[ "$output" =~ "claude_dir required" ]]
}

@test "create_claude_dirs fails if path is a file" {
  local file="$TEST_DIR/regular-file"
  touch "$file"

  run create_claude_dirs "$file"

  [ "$status" -eq 1 ]
  [[ "$output" =~ "is a file, not a directory" ]]
}

#######################################
# Tests for create_namespace_dirs
#######################################

@test "create_namespace_dirs creates .aida namespace directories" {
  local claude_dir="$TEST_DIR/.claude"

  # Create parent directories first
  create_claude_dirs "$claude_dir" >/dev/null

  run create_namespace_dirs "$claude_dir" ".aida"

  [ "$status" -eq 0 ]
  assert_dir_exists "$claude_dir/commands/.aida"
  assert_dir_exists "$claude_dir/agents/.aida"
  assert_dir_exists "$claude_dir/skills/.aida"
}

@test "create_namespace_dirs creates .aida-deprecated namespace directories" {
  local claude_dir="$TEST_DIR/.claude"

  # Create parent directories first
  create_claude_dirs "$claude_dir" >/dev/null

  run create_namespace_dirs "$claude_dir" ".aida-deprecated"

  [ "$status" -eq 0 ]
  assert_dir_exists "$claude_dir/commands/.aida-deprecated"
  assert_dir_exists "$claude_dir/agents/.aida-deprecated"
  assert_dir_exists "$claude_dir/skills/.aida-deprecated"
}

@test "create_namespace_dirs is idempotent" {
  local claude_dir="$TEST_DIR/.claude"

  create_claude_dirs "$claude_dir" >/dev/null

  # Create once
  create_namespace_dirs "$claude_dir" ".aida" >/dev/null

  # Create again
  run create_namespace_dirs "$claude_dir" ".aida"

  [ "$status" -eq 0 ]
  [[ "$output" =~ "already exists" ]]
}

@test "create_namespace_dirs warns about unusual namespace" {
  local claude_dir="$TEST_DIR/.claude"

  create_claude_dirs "$claude_dir" >/dev/null

  run create_namespace_dirs "$claude_dir" ".custom"

  [ "$status" -eq 0 ]
  [[ "$output" =~ "Unusual namespace" ]]
}

@test "create_namespace_dirs creates parent if missing" {
  local claude_dir="$TEST_DIR/.claude"

  # Don't create parent directories first

  run create_namespace_dirs "$claude_dir" ".aida"

  [ "$status" -eq 0 ]
  assert_dir_exists "$claude_dir/commands/.aida"
}

@test "create_namespace_dirs fails with empty claude_dir" {
  run create_namespace_dirs "" ".aida"

  [ "$status" -eq 1 ]
  [[ "$output" =~ "claude_dir required" ]]
}

@test "create_namespace_dirs fails with empty namespace" {
  run create_namespace_dirs "$TEST_DIR/.claude" ""

  [ "$status" -eq 1 ]
  [[ "$output" =~ "namespace required" ]]
}

#######################################
# Tests for create_aida_dir
#######################################

@test "create_aida_dir creates symlink to repository" {
  local repo_dir="$TEST_DIR/repo"
  local aida_dir="$TEST_DIR/.aida"

  mkdir -p "$repo_dir"

  run create_aida_dir "$repo_dir" "$aida_dir"

  [ "$status" -eq 0 ]
  [ -L "$aida_dir" ]
  assert_symlink_target "$aida_dir" "$repo_dir"
}

@test "create_aida_dir is idempotent" {
  local repo_dir="$TEST_DIR/repo"
  local aida_dir="$TEST_DIR/.aida"

  mkdir -p "$repo_dir"

  # Create once
  create_aida_dir "$repo_dir" "$aida_dir" >/dev/null

  # Create again
  run create_aida_dir "$repo_dir" "$aida_dir"

  [ "$status" -eq 0 ]
  [[ "$output" =~ "already symlinked correctly" ]]
}

@test "create_aida_dir backs up existing non-symlink directory" {
  local repo_dir="$TEST_DIR/repo"
  local aida_dir="$TEST_DIR/.aida"

  mkdir -p "$repo_dir"
  mkdir -p "$aida_dir"
  echo "user data" > "$aida_dir/file.txt"

  run create_aida_dir "$repo_dir" "$aida_dir"

  [ "$status" -eq 0 ]

  # Original should now be symlink
  [ -L "$aida_dir" ]

  # Backup should exist with user data
  local backup
  backup=$(ls -d "${aida_dir}.backup."* 2>/dev/null | head -n1)
  [ -n "$backup" ]
  [ -f "$backup/file.txt" ]
}

@test "create_aida_dir recreates incorrect symlink after backup" {
  local repo_dir="$TEST_DIR/repo"
  local wrong_dir="$TEST_DIR/wrong"
  local aida_dir="$TEST_DIR/.aida"

  mkdir -p "$repo_dir" "$wrong_dir"
  ln -s "$wrong_dir" "$aida_dir"

  run create_aida_dir "$repo_dir" "$aida_dir"

  [ "$status" -eq 0 ]
  assert_symlink_target "$aida_dir" "$repo_dir"

  # Note: backup_existing removes symlinks without creating backups
  # since they don't contain data, just metadata about the target
}

@test "create_aida_dir fails if repo does not exist" {
  local repo_dir="$TEST_DIR/nonexistent"
  local aida_dir="$TEST_DIR/.aida"

  run create_aida_dir "$repo_dir" "$aida_dir"

  [ "$status" -eq 1 ]
  [[ "$output" =~ "does not exist" ]]
}

@test "create_aida_dir fails with empty repo_dir" {
  run create_aida_dir "" "$TEST_DIR/.aida"

  [ "$status" -eq 1 ]
  [[ "$output" =~ "repo_dir required" ]]
}

@test "create_aida_dir fails with empty aida_dir" {
  run create_aida_dir "$TEST_DIR/repo" ""

  [ "$status" -eq 1 ]
  [[ "$output" =~ "aida_dir required" ]]
}

#######################################
# Tests for get_symlink_target
#######################################

@test "get_symlink_target returns target path" {
  local target="$TEST_DIR/target"
  local link="$TEST_DIR/link"

  mkdir -p "$target"
  ln -s "$target" "$link"

  run get_symlink_target "$link"

  [ "$status" -eq 0 ]
  [[ "$output" =~ "$target" ]]
}

@test "get_symlink_target fails if path is not a symlink" {
  local file="$TEST_DIR/regular-file"
  touch "$file"

  run get_symlink_target "$file"

  [ "$status" -eq 1 ]
  [[ "$output" =~ "not a symlink" ]]
}

@test "get_symlink_target fails with empty path" {
  run get_symlink_target ""

  [ "$status" -eq 1 ]
  [[ "$output" =~ "symlink path required" ]]
}

#######################################
# Tests for validate_symlink
#######################################

@test "validate_symlink succeeds for correct symlink" {
  local target="$TEST_DIR/target"
  local link="$TEST_DIR/link"

  mkdir -p "$target"
  ln -s "$target" "$link"

  run validate_symlink "$link" "$target"

  [ "$status" -eq 0 ]
}

@test "validate_symlink fails if symlink points to wrong target" {
  local target="$TEST_DIR/target"
  local wrong="$TEST_DIR/wrong"
  local link="$TEST_DIR/link"

  mkdir -p "$target" "$wrong"
  ln -s "$wrong" "$link"

  run validate_symlink "$link" "$target"

  [ "$status" -eq 1 ]
  [[ "$output" =~ "wrong target" ]]
}

@test "validate_symlink fails if path is not a symlink" {
  local target="$TEST_DIR/target"
  local file="$TEST_DIR/file"

  mkdir -p "$target"
  touch "$file"

  run validate_symlink "$file" "$target"

  [ "$status" -eq 1 ]
  [[ "$output" =~ "not a symlink" ]]
}

@test "validate_symlink fails with empty symlink path" {
  run validate_symlink "" "$TEST_DIR/target"

  [ "$status" -eq 1 ]
  [[ "$output" =~ "symlink path required" ]]
}

@test "validate_symlink fails with empty expected target" {
  run validate_symlink "$TEST_DIR/link" ""

  [ "$status" -eq 1 ]
  [[ "$output" =~ "expected_target required" ]]
}

#######################################
# Tests for upgrade path
#######################################

@test "create_claude_dirs converts old symlink structure to namespace isolation" {
  local claude_dir="$TEST_DIR/claude"
  local old_agents_target="$TEST_DIR/repo/agents"
  local old_commands_target="$TEST_DIR/repo/commands"

  # Create fake repo directories
  mkdir -p "$old_agents_target" "$old_commands_target"

  # Create old-style installation (entire directories are symlinks)
  mkdir -p "$claude_dir"
  ln -s "$old_agents_target" "$claude_dir/agents"
  ln -s "$old_commands_target" "$claude_dir/commands"

  # Verify old structure
  [ -L "$claude_dir/agents" ]
  [ -L "$claude_dir/commands" ]

  # Run create_claude_dirs to convert to new structure
  run create_claude_dirs "$claude_dir"

  [ "$status" -eq 0 ]
  [[ "$output" =~ "Converting old symlink structure" ]]

  # Verify new structure: directories are no longer symlinks
  [ -d "$claude_dir/agents" ]
  [ ! -L "$claude_dir/agents" ]
  [ -d "$claude_dir/commands" ]
  [ ! -L "$claude_dir/commands" ]

  # Verify backups were created
  local agents_backup_count
  agents_backup_count=$(find "$claude_dir" -maxdepth 1 -name "agents.backup.*" -type l | wc -l)
  [ "$agents_backup_count" -eq 1 ]

  local commands_backup_count
  commands_backup_count=$(find "$claude_dir" -maxdepth 1 -name "commands.backup.*" -type l | wc -l)
  [ "$commands_backup_count" -eq 1 ]
}
