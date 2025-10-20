#!/usr/bin/env bats
#
# Unit tests for templates.sh module
# Tests template installation, namespace isolation, and folder-based structure

# Load test helpers
load ../helpers/test_helpers

setup() {
  # Load required dependencies
  source "${PROJECT_ROOT}/lib/installer-common/colors.sh"
  source "${PROJECT_ROOT}/lib/installer-common/logging.sh"
  source "${PROJECT_ROOT}/lib/installer-common/validation.sh"
  source "${PROJECT_ROOT}/lib/installer-common/templates.sh"

  # Create temporary test directory
  setup_test_dir
}

teardown() {
  teardown_test_dir
}

#######################################
# Tests for validate_template_structure
#######################################

@test "validate_template_structure accepts valid template" {
  local template="$TEST_DIR/template"
  mkdir -p "$template"
  echo "# Template" > "$template/README.md"

  run validate_template_structure "$template"

  [ "$status" -eq 0 ]
}

@test "validate_template_structure rejects non-directory" {
  local template="$TEST_DIR/template.txt"
  touch "$template"

  run validate_template_structure "$template"

  [ "$status" -eq 1 ]
}

@test "validate_template_structure rejects missing README.md" {
  local template="$TEST_DIR/template"
  mkdir -p "$template"

  run validate_template_structure "$template"

  [ "$status" -eq 1 ]
}

@test "validate_template_structure requires template_dir parameter" {
  run validate_template_structure ""

  [ "$status" -eq 1 ]
}

#######################################
# Tests for install_template_folder (normal mode)
#######################################

@test "install_template_folder copies template in normal mode" {
  local src="$TEST_DIR/src/template"
  local dst="$TEST_DIR/dst/template"

  mkdir -p "$src"
  echo "# Template" > "$src/README.md"
  echo "content" > "$src/file.txt"

  run install_template_folder "$src" "$dst" false

  [ "$status" -eq 0 ]
  [ -d "$dst" ]
  [ ! -L "$dst" ]
  [ -f "$dst/README.md" ]
  [ -f "$dst/file.txt" ]
}

@test "install_template_folder creates parent directory if needed" {
  local src="$TEST_DIR/src/template"
  local dst="$TEST_DIR/dst/deep/nested/template"

  mkdir -p "$src"
  echo "# Template" > "$src/README.md"

  run install_template_folder "$src" "$dst" false

  [ "$status" -eq 0 ]
  [ -d "$dst" ]
}

@test "install_template_folder preserves file attributes" {
  local src="$TEST_DIR/src/template"
  local dst="$TEST_DIR/dst/template"

  mkdir -p "$src"
  echo "# Template" > "$src/README.md"
  echo "executable" > "$src/script.sh"
  chmod 755 "$src/script.sh"

  install_template_folder "$src" "$dst" false >/dev/null

  [ -f "$dst/script.sh" ]
  [ -x "$dst/script.sh" ]
}

@test "install_template_folder overwrites existing directory in normal mode" {
  local src="$TEST_DIR/src/template"
  local dst="$TEST_DIR/dst/template"

  mkdir -p "$src" "$dst"
  echo "# Template" > "$src/README.md"
  echo "new content" > "$src/file.txt"
  echo "old content" > "$dst/old-file.txt"

  run install_template_folder "$src" "$dst" false

  [ "$status" -eq 0 ]
  [ -f "$dst/README.md" ]
  [ -f "$dst/file.txt" ]
  grep -q "new content" "$dst/file.txt"
}

#######################################
# Tests for install_template_folder (dev mode)
#######################################

@test "install_template_folder creates symlink in dev mode" {
  local src="$TEST_DIR/src/template"
  local dst="$TEST_DIR/dst/template"

  mkdir -p "$src"
  echo "# Template" > "$src/README.md"

  run install_template_folder "$src" "$dst" true

  [ "$status" -eq 0 ]
  [ -L "$dst" ]
  assert_symlink_target "$dst" "$src"
}

@test "install_template_folder is idempotent in dev mode" {
  local src="$TEST_DIR/src/template"
  local dst="$TEST_DIR/dst/template"

  mkdir -p "$src"
  echo "# Template" > "$src/README.md"

  # Create symlink first time
  install_template_folder "$src" "$dst" true >/dev/null

  # Create symlink second time - should succeed
  run install_template_folder "$src" "$dst" true

  [ "$status" -eq 0 ]
  [ -L "$dst" ]
  assert_symlink_target "$dst" "$src"
}

@test "install_template_folder backs up directory before symlinking" {
  local src="$TEST_DIR/src/template"
  local dst="$TEST_DIR/dst/template"

  mkdir -p "$src" "$dst"
  echo "# Template" > "$src/README.md"
  echo "existing content" > "$dst/existing.txt"

  run install_template_folder "$src" "$dst" true

  [ "$status" -eq 0 ]
  [ -L "$dst" ]

  # Check backup exists
  local backup_count
  backup_count=$(find "$TEST_DIR/dst" -name "template.backup.*" | wc -l)
  [ "$backup_count" -eq 1 ]
}

@test "install_template_folder recreates wrong symlink in dev mode" {
  local src="$TEST_DIR/src/template"
  local wrong_target="$TEST_DIR/wrong/template"
  local dst="$TEST_DIR/dst/template"

  mkdir -p "$src" "$wrong_target"
  echo "# Template" > "$src/README.md"
  echo "# Wrong" > "$wrong_target/README.md"

  # Create symlink to wrong target
  mkdir -p "$(dirname "$dst")"
  ln -s "$wrong_target" "$dst"

  # Install should fix the symlink
  run install_template_folder "$src" "$dst" true

  [ "$status" -eq 0 ]
  [ -L "$dst" ]
  assert_symlink_target "$dst" "$src"
}

#######################################
# Tests for install_template_folder validation
#######################################

@test "install_template_folder rejects invalid template" {
  local src="$TEST_DIR/src/template"
  local dst="$TEST_DIR/dst/template"

  mkdir -p "$src"
  # No README.md - invalid template

  run install_template_folder "$src" "$dst" false

  [ "$status" -eq 1 ]
  [ ! -d "$dst" ]
}

@test "install_template_folder requires all parameters" {
  local src="$TEST_DIR/src/template"
  local dst="$TEST_DIR/dst/template"

  mkdir -p "$src"
  echo "# Template" > "$src/README.md"

  # Missing src_folder
  run install_template_folder "" "$dst" false
  [ "$status" -eq 1 ]

  # Missing dst_folder
  run install_template_folder "$src" "" false
  [ "$status" -eq 1 ]

  # Missing dev_mode
  run install_template_folder "$src" "$dst" ""
  [ "$status" -eq 1 ]
}

#######################################
# Tests for install_templates (normal mode)
#######################################

@test "install_templates creates namespace directory" {
  local src="$TEST_DIR/src"
  local dst="$TEST_DIR/dst"

  mkdir -p "$src/template1"
  echo "# Template 1" > "$src/template1/README.md"

  run install_templates "$src" "$dst" false ".aida"

  [ "$status" -eq 0 ]
  [ -d "$dst/.aida" ]
  [ -d "$dst/.aida/template1" ]
}

@test "install_templates installs multiple templates" {
  local src="$TEST_DIR/src"
  local dst="$TEST_DIR/dst"

  mkdir -p "$src/template1" "$src/template2" "$src/template3"
  echo "# Template 1" > "$src/template1/README.md"
  echo "# Template 2" > "$src/template2/README.md"
  echo "# Template 3" > "$src/template3/README.md"

  run install_templates "$src" "$dst" false ".aida"

  [ "$status" -eq 0 ]
  [ -d "$dst/.aida/template1" ]
  [ -d "$dst/.aida/template2" ]
  [ -d "$dst/.aida/template3" ]
}

@test "install_templates copies templates in normal mode" {
  local src="$TEST_DIR/src"
  local dst="$TEST_DIR/dst"

  mkdir -p "$src/template1"
  echo "# Template 1" > "$src/template1/README.md"
  echo "content" > "$src/template1/file.txt"

  run install_templates "$src" "$dst" false ".aida"

  [ "$status" -eq 0 ]
  [ -d "$dst/.aida/template1" ]
  [ ! -L "$dst/.aida/template1" ]
  [ -f "$dst/.aida/template1/README.md" ]
  [ -f "$dst/.aida/template1/file.txt" ]
}

@test "install_templates copies entire directory including files" {
  local src="$TEST_DIR/src"
  local dst="$TEST_DIR/dst"

  mkdir -p "$src/template1"
  echo "# Template 1" > "$src/template1/README.md"
  echo "not a template" > "$src/file.txt"

  run install_templates "$src" "$dst" false ".aida"

  [ "$status" -eq 0 ]
  [ -d "$dst/.aida/template1" ]
  # With cp -a, everything gets copied including files
  [ -f "$dst/.aida/file.txt" ]
}

#######################################
# Tests for install_templates (dev mode)
#######################################

@test "install_templates creates directory symlink in dev mode" {
  local src="$TEST_DIR/src"
  local dst="$TEST_DIR/dst"

  mkdir -p "$src/template1" "$src/template2"
  echo "# Template 1" > "$src/template1/README.md"
  echo "# Template 2" > "$src/template2/README.md"

  run install_templates "$src" "$dst" true ".aida"

  [ "$status" -eq 0 ]

  # .aida itself should be a symlink (not individual templates)
  [ -L "$dst/.aida" ]
  assert_symlink_target "$dst/.aida" "$src"

  # Templates should be accessible through the symlink
  [ -f "$dst/.aida/template1/README.md" ]
  [ -f "$dst/.aida/template2/README.md" ]
}

#######################################
# Tests for install_templates namespace isolation
#######################################

@test "install_templates uses .aida namespace by default" {
  local src="$TEST_DIR/src"
  local dst="$TEST_DIR/dst"

  mkdir -p "$src/template1"
  echo "# Template 1" > "$src/template1/README.md"

  run install_templates "$src" "$dst"

  [ "$status" -eq 0 ]
  [ -d "$dst/.aida" ]
  [ -d "$dst/.aida/template1" ]
}

@test "install_templates supports .aida-deprecated namespace" {
  local src="$TEST_DIR/src"
  local dst="$TEST_DIR/dst"

  mkdir -p "$src/template1"
  echo "# Template 1" > "$src/template1/README.md"

  run install_templates "$src" "$dst" false ".aida-deprecated"

  [ "$status" -eq 0 ]
  [ -d "$dst/.aida-deprecated" ]
  [ -d "$dst/.aida-deprecated/template1" ]
}

@test "install_templates warns about unusual namespace" {
  local src="$TEST_DIR/src"
  local dst="$TEST_DIR/dst"

  mkdir -p "$src/template1"
  echo "# Template 1" > "$src/template1/README.md"

  run install_templates "$src" "$dst" false ".custom"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Unusual namespace"* ]]
}

@test "install_templates preserves user content outside namespace" {
  local src="$TEST_DIR/src"
  local dst="$TEST_DIR/dst"

  # Create user content
  mkdir -p "$dst"
  echo "# User Template" > "$dst/user-template.md"
  mkdir -p "$dst/user-folder"
  echo "user content" > "$dst/user-folder/file.txt"

  # Install AIDA templates
  mkdir -p "$src/aida-template"
  echo "# AIDA Template" > "$src/aida-template/README.md"

  run install_templates "$src" "$dst" false ".aida"

  [ "$status" -eq 0 ]

  # User content preserved
  [ -f "$dst/user-template.md" ]
  [ -d "$dst/user-folder" ]
  [ -f "$dst/user-folder/file.txt" ]

  # AIDA content in namespace
  [ -d "$dst/.aida/aida-template" ]
}

#######################################
# Tests for install_templates validation
#######################################

@test "install_templates requires src_dir parameter" {
  run install_templates "" "$TEST_DIR/dst" false ".aida"

  [ "$status" -eq 1 ]
}

@test "install_templates requires dst_dir parameter" {
  run install_templates "$TEST_DIR/src" "" false ".aida"

  [ "$status" -eq 1 ]
}

@test "install_templates rejects non-existent source directory" {
  run install_templates "$TEST_DIR/nonexistent" "$TEST_DIR/dst" false ".aida"

  [ "$status" -eq 1 ]
}

@test "install_templates handles empty source directory" {
  local src="$TEST_DIR/src"
  local dst="$TEST_DIR/dst"

  mkdir -p "$src"

  run install_templates "$src" "$dst" false ".aida"

  [ "$status" -eq 0 ]
  [[ "$output" == *"No template directories found"* ]]
}

@test "install_templates reports installation statistics" {
  local src="$TEST_DIR/src"
  local dst="$TEST_DIR/dst"

  mkdir -p "$src/template1" "$src/template2"
  echo "# Template 1" > "$src/template1/README.md"
  echo "# Template 2" > "$src/template2/README.md"

  run install_templates "$src" "$dst" false ".aida"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Installed 2 template(s)"* ]]
}

@test "install_templates copies entire directory without per-template validation" {
  local src="$TEST_DIR/src"
  local dst="$TEST_DIR/dst"

  mkdir -p "$src/valid" "$src/invalid"
  echo "# Valid" > "$src/valid/README.md"
  # invalid has no README.md (but still gets copied)

  run install_templates "$src" "$dst" false ".aida"

  # Should succeed - copies entire directory without validation
  [ "$status" -eq 0 ]
  [[ "$output" == *"Installed 2 template(s)"* ]]

  # Both directories should be copied
  [ -d "$dst/.aida/valid" ]
  [ -d "$dst/.aida/invalid" ]

  # Note: Template validation should happen at a different layer
  # (e.g., during template creation or CI validation)
}

#######################################
# Tests for generate_claude_md
#######################################

@test "generate_claude_md creates CLAUDE.md file" {
  local output_file="$TEST_DIR/CLAUDE.md"

  run generate_claude_md "$output_file" "JARVIS" "professional" "0.1.6"

  [ "$status" -eq 0 ]
  [ -f "$output_file" ]
}

@test "generate_claude_md includes frontmatter" {
  local output="$TEST_DIR/CLAUDE.md"

  generate_claude_md "$output" "JARVIS" "professional" "0.1.6" >/dev/null

  grep -q "^---$" "$output"
  grep -q "assistant_name: \"JARVIS\"" "$output"
  grep -q "personality: \"professional\"" "$output"
}

@test "generate_claude_md includes configuration paths" {
  local output="$TEST_DIR/CLAUDE.md"

  generate_claude_md "$output" "JARVIS" "professional" "0.1.6" >/dev/null

  # shellcheck disable=SC2088  # We're searching for literal tilde strings, not paths
  grep -qF '~/.aida/' "$output"
  # shellcheck disable=SC2088
  grep -qF '~/.claude/' "$output"
}

@test "generate_claude_md includes version" {
  local output="$TEST_DIR/CLAUDE.md"

  generate_claude_md "$output" "JARVIS" "professional" "0.1.6" >/dev/null

  grep -q "v0.1.6" "$output"
}

@test "generate_claude_md sets correct permissions" {
  local output="$TEST_DIR/CLAUDE.md"

  generate_claude_md "$output" "JARVIS" "professional" "0.1.6" >/dev/null

  # Check file is readable by user
  [ -r "$output" ]

  # Check file is not world-writable (last digit not 2, 3, 6, or 7)
  local perms
  if [[ "$OSTYPE" == "darwin"* ]]; then
    perms=$(stat -f "%Lp" "$output")
  else
    perms=$(stat -c "%a" "$output")
  fi

  local last_digit="${perms: -1}"
  [[ ! "$last_digit" =~ [2367] ]]
}

@test "generate_claude_md requires all parameters" {
  local output="$TEST_DIR/CLAUDE.md"

  # Missing output_file
  run generate_claude_md "" "JARVIS" "professional" "0.1.6"
  [ "$status" -eq 1 ]

  # Missing assistant_name
  run generate_claude_md "$output" "" "professional" "0.1.6"
  [ "$status" -eq 1 ]

  # Missing personality
  run generate_claude_md "$output" "JARVIS" "" "0.1.6"
  [ "$status" -eq 1 ]

  # Missing version
  run generate_claude_md "$output" "JARVIS" "professional" ""
  [ "$status" -eq 1 ]
}

#######################################
# Integration tests
#######################################

@test "install_templates supports conversion between modes" {
  local src="$TEST_DIR/src"
  local dst="$TEST_DIR/dst"

  mkdir -p "$src/template1" "$src/template2"
  echo "# Template 1" > "$src/template1/README.md"
  echo "# Template 2" > "$src/template2/README.md"

  # Install in dev mode (directory-level symlink)
  install_templates "$src" "$dst" true ".aida" >/dev/null

  # Verify .aida itself is a symlink to src
  [ -L "$dst/.aida" ]
  [ "$(readlink "$dst/.aida")" = "$src" ]

  # Templates should be accessible through symlink
  [ -f "$dst/.aida/template1/README.md" ]
  [ -f "$dst/.aida/template2/README.md" ]

  # Convert to normal mode (copy entire directory)
  run install_templates "$src" "$dst" false ".aida"

  [ "$status" -eq 0 ]

  # .aida should now be a regular directory (not a symlink)
  [ -d "$dst/.aida" ]
  [ ! -L "$dst/.aida" ]

  # Templates should be copied as directories
  [ -d "$dst/.aida/template1" ]
  [ -d "$dst/.aida/template2" ]
  [ -f "$dst/.aida/template1/README.md" ]

  # Check backup of directory symlink was created
  local backup_count
  backup_count=$(find "$dst" -maxdepth 1 -name ".aida.backup.*" -type l | wc -l)
  [ "$backup_count" -eq 1 ]
}

@test "install_templates handles complex template structures" {
  local src="$TEST_DIR/src"
  local dst="$TEST_DIR/dst"

  mkdir -p "$src/template1/subdir/nested"
  echo "# Template 1" > "$src/template1/README.md"
  echo "content" > "$src/template1/file.txt"
  echo "nested content" > "$src/template1/subdir/nested/file.txt"

  run install_templates "$src" "$dst" false ".aida"

  [ "$status" -eq 0 ]
  [ -f "$dst/.aida/template1/README.md" ]
  [ -f "$dst/.aida/template1/file.txt" ]
  [ -f "$dst/.aida/template1/subdir/nested/file.txt" ]
}
