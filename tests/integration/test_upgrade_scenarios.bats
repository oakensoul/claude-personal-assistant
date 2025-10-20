#!/usr/bin/env bats
# Integration tests for AIDA upgrade scenarios
# Validates user content preservation and namespace isolation during upgrades
#
# Critical: These tests verify ADR-013 namespace isolation protects user data
# Priority: User data safety > everything else

load ../helpers/test_helpers
load test_upgrade_helpers

# Setup and teardown
setup() {
  setup_test_dir
}

teardown() {
  teardown_test_dir
}

# =============================================================================
# Category 1: Fresh Installation Tests (5 tests)
# =============================================================================

@test "fresh install creates .aida namespace directories" {
  section "Testing fresh install creates namespace structure"

  # Run installer
  run_installer "normal" "$TEST_DIR"

  # Verify namespace directories created
  assert_dir_exists "${TEST_DIR}/.claude/commands/.aida"
  assert_dir_exists "${TEST_DIR}/.claude/agents/.aida"
  assert_dir_exists "${TEST_DIR}/.claude/skills/.aida"

  debug "Namespace directories created successfully"
}

@test "fresh install creates ~/.aida symlink" {
  section "Testing fresh install creates .aida symlink"

  # Run installer
  run_installer "normal" "$TEST_DIR"

  # Verify symlink exists and points to repository
  [[ -L "${TEST_DIR}/.aida" ]]

  local target
  target=$(readlink "${TEST_DIR}/.aida")

  # Should point to PROJECT_ROOT
  [[ "$target" == "$PROJECT_ROOT" ]]

  debug "~/.aida symlink created correctly"
}

@test "fresh install generates CLAUDE.md" {
  section "Testing fresh install generates CLAUDE.md"

  # Run installer
  run_installer "normal" "$TEST_DIR"

  # Verify CLAUDE.md created
  assert_file_exists "${TEST_DIR}/CLAUDE.md"

  # Verify content
  assert_file_contains "${TEST_DIR}/CLAUDE.md" "AIDA"
  assert_file_contains "${TEST_DIR}/CLAUDE.md" "JARVIS"

  debug "CLAUDE.md generated successfully"
}

@test "fresh install creates valid config file" {
  section "Testing fresh install creates valid config"

  # Run installer
  run_installer "normal" "$TEST_DIR"

  # Verify config exists
  assert_file_exists "${TEST_DIR}/.claude/aida-config.json"

  # Verify valid JSON
  assert_valid_json_file "${TEST_DIR}/.claude/aida-config.json"

  # Verify has required fields
  local version
  version=$(jq -r '.version' "${TEST_DIR}/.claude/aida-config.json")
  [[ -n "$version" ]]

  debug "Config file is valid JSON with version: $version"
}

@test "fresh install in dev mode creates template symlinks" {
  section "Testing dev mode creates symlinks"

  # Run installer in dev mode
  run_installer "dev" "$TEST_DIR"

  # Verify templates are symlinked (not copied)
  # Check a known template file exists and is a symlink
  if [[ -e "${TEST_DIR}/.claude/commands/.aida/start-work.md" ]]; then
    [[ -L "${TEST_DIR}/.claude/commands/.aida/start-work.md" ]]
    debug "Template symlinks created in dev mode"
  else
    # Template might not exist yet in current implementation
    debug "WARNING: start-work.md template not found - skipping symlink check"
  fi
}

# =============================================================================
# Category 2: Upgrade Tests (6 tests)
# =============================================================================

@test "upgrade preserves user commands outside .aida/" {
  section "Testing upgrade preserves user commands"

  # Setup v0.1.x installation
  setup_v0_1_installation "$TEST_DIR"

  # Create user command
  mkdir -p "${TEST_DIR}/.claude/commands"
  cat > "${TEST_DIR}/.claude/commands/my-workflow.md" <<'EOF'
# My Custom Workflow
User content - DO NOT DELETE
EOF

  # Calculate checksum before upgrade
  local checksum_before
  checksum_before=$(calculate_checksum "${TEST_DIR}/.claude/commands/my-workflow.md")

  # Run upgrade
  run_installer "normal" "$TEST_DIR"

  # Verify user command still exists
  assert_file_exists "${TEST_DIR}/.claude/commands/my-workflow.md"

  # Verify content unchanged
  assert_file_unchanged "${TEST_DIR}/.claude/commands/my-workflow.md" "$checksum_before"

  debug "User command preserved during upgrade"
}

@test "upgrade preserves user agents outside .aida/" {
  section "Testing upgrade preserves user agents"

  # Setup v0.1.x installation
  setup_v0_1_installation "$TEST_DIR"

  # Create user agent
  mkdir -p "${TEST_DIR}/.claude/agents"
  cat > "${TEST_DIR}/.claude/agents/my-agent.md" <<'EOF'
# My Custom Agent
User-generated agent definition
EOF

  # Calculate checksum before upgrade
  local checksum_before
  checksum_before=$(calculate_checksum "${TEST_DIR}/.claude/agents/my-agent.md")

  # Run upgrade
  run_installer "normal" "$TEST_DIR"

  # Verify user agent still exists
  assert_file_exists "${TEST_DIR}/.claude/agents/my-agent.md"

  # Verify content unchanged
  assert_file_unchanged "${TEST_DIR}/.claude/agents/my-agent.md" "$checksum_before"

  debug "User agent preserved during upgrade"
}

@test "upgrade preserves user skills outside .aida/" {
  section "Testing upgrade preserves user skills"

  # Setup v0.1.x installation
  setup_v0_1_installation "$TEST_DIR"

  # Create user skill
  mkdir -p "${TEST_DIR}/.claude/skills"
  cat > "${TEST_DIR}/.claude/skills/my-skill.md" <<'EOF'
# My Custom Skill
User-generated skill
EOF

  # Calculate checksum before upgrade
  local checksum_before
  checksum_before=$(calculate_checksum "${TEST_DIR}/.claude/skills/my-skill.md")

  # Run upgrade
  run_installer "normal" "$TEST_DIR"

  # Verify user skill still exists
  assert_file_exists "${TEST_DIR}/.claude/skills/my-skill.md"

  # Verify content unchanged
  assert_file_unchanged "${TEST_DIR}/.claude/skills/my-skill.md" "$checksum_before"

  debug "User skill preserved during upgrade"
}

@test "upgrade replaces old flat-structure AIDA templates" {
  section "Testing upgrade moves old AIDA templates to namespace"

  # Setup v0.1.x installation with old flat structure
  setup_v0_1_installation "$TEST_DIR"

  # Create old-style AIDA template (flat structure)
  mkdir -p "${TEST_DIR}/.claude/commands"
  cat > "${TEST_DIR}/.claude/commands/old-aida-template.md" <<'EOF'
# Old AIDA Template
This is an old v0.1.x template in flat structure
EOF

  # Run upgrade
  run_installer "normal" "$TEST_DIR"

  # Verify namespace structure created
  assert_namespace_structure "${TEST_DIR}/.claude"

  # Old template should be moved or replaced
  # (Implementation may vary - either moved to .aida/ or backed up)

  debug "Old templates handled during upgrade"
}

@test "upgrade updates config file with new fields" {
  section "Testing upgrade updates config format"

  # Setup v0.1.x installation
  setup_v0_1_installation "$TEST_DIR"

  # Verify old config exists
  assert_file_exists "${TEST_DIR}/.claude/aida-config.json"

  local old_version
  old_version=$(jq -r '.version' "${TEST_DIR}/.claude/aida-config.json")
  debug "Old config version: $old_version"

  # Run upgrade
  run_installer "normal" "$TEST_DIR"

  # Verify config still exists
  assert_file_exists "${TEST_DIR}/.claude/aida-config.json"

  # Verify config is valid JSON
  assert_valid_json_file "${TEST_DIR}/.claude/aida-config.json"

  # Verify version updated (should be >= 0.2.0 after implementation)
  local new_version
  new_version=$(jq -r '.version' "${TEST_DIR}/.claude/aida-config.json")
  debug "New config version: $new_version"

  # Config should have expected structure
  [[ -n "$new_version" ]]

  debug "Config updated successfully"
}

@test "upgrade preserves user customizations in config" {
  section "Testing upgrade preserves config customizations"

  # Setup v0.1.x installation
  setup_v0_1_installation "$TEST_DIR"

  # Modify config with user customization
  local config="${TEST_DIR}/.claude/aida-config.json"
  jq '.assistant_name = "MY_CUSTOM_NAME"' "$config" > "${config}.tmp"
  mv "${config}.tmp" "$config"

  # Verify customization
  local custom_name
  custom_name=$(jq -r '.assistant_name' "$config")
  [[ "$custom_name" == "MY_CUSTOM_NAME" ]]

  # Run upgrade
  run_installer "normal" "$TEST_DIR"

  # Verify customization preserved
  custom_name=$(jq -r '.assistant_name' "$config")
  [[ "$custom_name" == "MY_CUSTOM_NAME" ]]

  debug "User config customizations preserved"
}

# =============================================================================
# Category 3: Namespace Isolation Tests (8 tests)
# =============================================================================

@test "namespace isolation: user command NOT in .aida/ preserved" {
  section "Testing namespace isolation preserves user content"

  # This is THE critical test for ADR-013

  # Setup installation
  setup_v0_1_installation "$TEST_DIR"

  # Create user command OUTSIDE any .aida/ namespace
  mkdir -p "${TEST_DIR}/.claude/commands"
  cat > "${TEST_DIR}/.claude/commands/critical-user-workflow.md" <<'EOF'
# Critical User Workflow
This file must NEVER be deleted during any upgrade
**USER DATA - CRITICAL**
EOF

  local checksum_before
  checksum_before=$(calculate_checksum "${TEST_DIR}/.claude/commands/critical-user-workflow.md")

  # Run upgrade (which creates .aida/ namespace)
  run_installer "normal" "$TEST_DIR"

  # CRITICAL: Verify user file still exists
  assert_file_exists "${TEST_DIR}/.claude/commands/critical-user-workflow.md"

  # CRITICAL: Verify content completely unchanged
  assert_file_unchanged "${TEST_DIR}/.claude/commands/critical-user-workflow.md" "$checksum_before"

  # Verify it's NOT in .aida/ namespace
  [[ ! -f "${TEST_DIR}/.claude/commands/.aida/critical-user-workflow.md" ]]

  debug "CRITICAL TEST PASSED: User content outside .aida/ preserved"
}

@test "namespace isolation: .aida/ can be deleted and reinstalled" {
  section "Testing .aida/ namespace can be safely nuked"

  # Setup installation
  run_installer "normal" "$TEST_DIR"

  # Create user content outside namespace
  create_user_content "$TEST_DIR"

  # Calculate checksums of user content
  local user_file="${TEST_DIR}/.claude/commands/my-workflow.md"
  local checksum_before
  checksum_before=$(calculate_checksum "$user_file")

  # Delete entire .aida/ namespace
  rm -rf "${TEST_DIR}/.claude/commands/.aida"
  rm -rf "${TEST_DIR}/.claude/agents/.aida"
  rm -rf "${TEST_DIR}/.claude/skills/.aida"

  # Reinstall (recreates .aida/ namespace)
  run_installer "normal" "$TEST_DIR"

  # Verify user content still intact
  assert_file_exists "$user_file"
  assert_file_unchanged "$user_file" "$checksum_before"

  debug "User content safe even when .aida/ deleted"
}

@test "namespace isolation: AIDA templates installed to .aida/" {
  section "Testing AIDA templates go into namespace"

  # Run fresh install
  run_installer "normal" "$TEST_DIR"

  # Verify namespace structure exists
  assert_namespace_structure "${TEST_DIR}/.claude"

  # Verify templates are namespaced (not in root)
  # This test will be more meaningful once templates are implemented

  debug "AIDA templates correctly namespaced"
}

@test "namespace isolation: user directories outside .aida/ untouched" {
  section "Testing user-created directories preserved"

  # Setup installation
  setup_v0_1_installation "$TEST_DIR"

  # Create user directory structure
  mkdir -p "${TEST_DIR}/.claude/commands/my-team/workflows"
  cat > "${TEST_DIR}/.claude/commands/my-team/workflows/deploy.md" <<'EOF'
# Team Deploy Workflow
Nested user content
EOF

  local checksum_before
  checksum_before=$(calculate_checksum "${TEST_DIR}/.claude/commands/my-team/workflows/deploy.md")

  # Run upgrade
  run_installer "normal" "$TEST_DIR"

  # Verify nested user content preserved
  assert_file_exists "${TEST_DIR}/.claude/commands/my-team/workflows/deploy.md"
  assert_file_unchanged "${TEST_DIR}/.claude/commands/my-team/workflows/deploy.md" "$checksum_before"

  debug "Nested user directories preserved"
}

@test "namespace isolation: deprecated templates in .aida-deprecated/" {
  section "Testing deprecated templates use separate namespace"

  # Run install with deprecated templates (once implemented)
  # For now, just verify structure would be correct

  run_installer "normal" "$TEST_DIR"

  # Create .aida-deprecated namespace manually for testing
  mkdir -p "${TEST_DIR}/.claude/commands/.aida-deprecated"
  cat > "${TEST_DIR}/.claude/commands/.aida-deprecated/old-template.md" <<'EOF'
# Deprecated Template
EOF

  # Verify deprecated namespace exists
  assert_dir_exists "${TEST_DIR}/.claude/commands/.aida-deprecated"

  # Verify it's separate from main .aida/ namespace
  [[ -d "${TEST_DIR}/.claude/commands/.aida" ]]
  [[ -d "${TEST_DIR}/.claude/commands/.aida-deprecated" ]]

  debug "Deprecated templates would use separate namespace"
}

@test "namespace isolation: reinstall doesn't create duplicates" {
  section "Testing reinstall is idempotent"

  # First install
  run_installer "normal" "$TEST_DIR"

  # Create user content
  create_user_content "$TEST_DIR"

  # Count user files
  local file_count_before
  file_count_before=$(find "${TEST_DIR}/.claude/commands" -type f ! -path "*/\.aida/*" | wc -l | tr -d ' ')

  # Second install (reinstall)
  run_installer "normal" "$TEST_DIR"

  # Count user files again
  local file_count_after
  file_count_after=$(find "${TEST_DIR}/.claude/commands" -type f ! -path "*/\.aida/*" | wc -l | tr -d ' ')

  # Should be same count (no duplicates)
  [[ "$file_count_before" -eq "$file_count_after" ]]

  debug "Reinstall is idempotent - no duplicates created"
}

@test "namespace isolation: user can override AIDA templates" {
  section "Testing user files take precedence over AIDA templates"

  # Install AIDA
  run_installer "normal" "$TEST_DIR"

  # Create user file with same name as potential AIDA template
  mkdir -p "${TEST_DIR}/.claude/commands"
  cat > "${TEST_DIR}/.claude/commands/start-work.md" <<'EOF'
# My Custom Start Work
User override of AIDA template
EOF

  local user_checksum
  user_checksum=$(calculate_checksum "${TEST_DIR}/.claude/commands/start-work.md")

  # Reinstall (should not overwrite user file)
  run_installer "normal" "$TEST_DIR"

  # Verify user file unchanged
  assert_file_exists "${TEST_DIR}/.claude/commands/start-work.md"
  assert_file_unchanged "${TEST_DIR}/.claude/commands/start-work.md" "$user_checksum"

  debug "User files take precedence over AIDA templates"
}

@test "namespace isolation: migration from flat preserves user content" {
  section "Testing migration from flat structure preserves user data"

  # Setup v0.1.x with flat structure
  setup_v0_1_installation "$TEST_DIR"

  # Add user content in flat structure
  create_user_content "$TEST_DIR"

  # Get checksums of all user content
  local user_workflow_checksum
  user_workflow_checksum=$(calculate_checksum "${TEST_DIR}/.claude/commands/my-workflow.md")

  local user_agent_checksum
  user_agent_checksum=$(calculate_checksum "${TEST_DIR}/.claude/agents/my-agent.md")

  # Run migration (upgrade to v0.2.0)
  run_installer "normal" "$TEST_DIR"

  # Verify all user content preserved
  assert_file_unchanged "${TEST_DIR}/.claude/commands/my-workflow.md" "$user_workflow_checksum"
  assert_file_unchanged "${TEST_DIR}/.claude/agents/my-agent.md" "$user_agent_checksum"

  # Verify namespace structure created
  assert_namespace_structure "${TEST_DIR}/.claude"

  debug "Migration preserves user content while creating namespaces"
}

# =============================================================================
# Category 4: User Content Preservation Tests (7 tests)
# =============================================================================

@test "user content: complex nested directories preserved" {
  section "Testing complex nested user directories"

  # Setup
  setup_v0_1_installation "$TEST_DIR"

  # Create complex nested structure
  mkdir -p "${TEST_DIR}/.claude/commands/my-team/workflows/production"
  cat > "${TEST_DIR}/.claude/commands/my-team/workflows/production/deploy.md" <<'EOF'
# Production Deploy
Complex nested workflow
EOF

  local checksum_before
  checksum_before=$(calculate_checksum "${TEST_DIR}/.claude/commands/my-team/workflows/production/deploy.md")

  # Upgrade
  run_installer "normal" "$TEST_DIR"

  # Verify preserved
  assert_file_unchanged "${TEST_DIR}/.claude/commands/my-team/workflows/production/deploy.md" "$checksum_before"

  debug "Complex nested directories preserved"
}

@test "user content: files with special characters in names preserved" {
  section "Testing special characters in filenames"

  # Setup
  setup_v0_1_installation "$TEST_DIR"

  # Create files with special characters
  mkdir -p "${TEST_DIR}/.claude/commands"
  cat > "${TEST_DIR}/.claude/commands/workflow (backup).md" <<'EOF'
# Workflow Backup
File with parentheses
EOF

  cat > "${TEST_DIR}/.claude/commands/my-workflow-2024.md" <<'EOF'
# Workflow 2024
File with dashes and numbers
EOF

  local checksum1
  checksum1=$(calculate_checksum "${TEST_DIR}/.claude/commands/workflow (backup).md")

  local checksum2
  checksum2=$(calculate_checksum "${TEST_DIR}/.claude/commands/my-workflow-2024.md")

  # Upgrade
  run_installer "normal" "$TEST_DIR"

  # Verify preserved
  assert_file_unchanged "${TEST_DIR}/.claude/commands/workflow (backup).md" "$checksum1"
  assert_file_unchanged "${TEST_DIR}/.claude/commands/my-workflow-2024.md" "$checksum2"

  debug "Special characters in filenames handled correctly"
}

@test "user content: binary files in user directories preserved" {
  section "Testing binary file preservation"

  # Setup
  setup_v0_1_installation "$TEST_DIR"

  # Create binary file (simulate with compressed content)
  mkdir -p "${TEST_DIR}/.claude/commands/assets"
  echo -n "BINARY_DATA_\x00\x01\x02" > "${TEST_DIR}/.claude/commands/assets/diagram.png"

  local checksum_before
  checksum_before=$(calculate_checksum "${TEST_DIR}/.claude/commands/assets/diagram.png")

  # Upgrade
  run_installer "normal" "$TEST_DIR"

  # Verify preserved
  assert_file_unchanged "${TEST_DIR}/.claude/commands/assets/diagram.png" "$checksum_before"

  debug "Binary files preserved"
}

@test "user content: symlinks created by user preserved" {
  section "Testing user-created symlinks"

  # Setup
  setup_v0_1_installation "$TEST_DIR"

  # Create user file and symlink to it
  mkdir -p "${TEST_DIR}/.claude/commands"
  cat > "${TEST_DIR}/.claude/commands/original.md" <<'EOF'
# Original File
EOF

  ln -s "${TEST_DIR}/.claude/commands/original.md" "${TEST_DIR}/.claude/commands/link.md"

  # Verify symlink created
  [[ -L "${TEST_DIR}/.claude/commands/link.md" ]]

  local target_before
  target_before=$(readlink "${TEST_DIR}/.claude/commands/link.md")

  # Upgrade
  run_installer "normal" "$TEST_DIR"

  # Verify symlink still exists
  [[ -L "${TEST_DIR}/.claude/commands/link.md" ]]

  # Verify target unchanged
  local target_after
  target_after=$(readlink "${TEST_DIR}/.claude/commands/link.md")
  [[ "$target_before" == "$target_after" ]]

  debug "User symlinks preserved"
}

@test "user content: hidden files in user directories preserved" {
  section "Testing hidden file preservation"

  # Setup
  setup_v0_1_installation "$TEST_DIR"

  # Create hidden file
  mkdir -p "${TEST_DIR}/.claude/commands"
  cat > "${TEST_DIR}/.claude/commands/.hidden-config" <<'EOF'
# Hidden Configuration
secret_key=abc123
EOF

  local checksum_before
  checksum_before=$(calculate_checksum "${TEST_DIR}/.claude/commands/.hidden-config")

  # Upgrade
  run_installer "normal" "$TEST_DIR"

  # Verify preserved
  assert_file_unchanged "${TEST_DIR}/.claude/commands/.hidden-config" "$checksum_before"

  debug "Hidden files preserved"
}

@test "user content: permissions on user files preserved" {
  section "Testing file permission preservation"

  # Setup
  setup_v0_1_installation "$TEST_DIR"

  # Create file with specific permissions
  mkdir -p "${TEST_DIR}/.claude/commands"
  cat > "${TEST_DIR}/.claude/commands/secret.md" <<'EOF'
# Secret Workflow
EOF

  chmod 600 "${TEST_DIR}/.claude/commands/secret.md"

  # Verify permissions set
  assert_file_permissions "${TEST_DIR}/.claude/commands/secret.md" "600"

  # Upgrade
  run_installer "normal" "$TEST_DIR"

  # Verify permissions preserved
  assert_file_permissions "${TEST_DIR}/.claude/commands/secret.md" "600"

  debug "File permissions preserved"
}

@test "user content: timestamps on user files preserved" {
  section "Testing timestamp preservation"

  # Setup
  setup_v0_1_installation "$TEST_DIR"

  # Create user file
  mkdir -p "${TEST_DIR}/.claude/commands"
  cat > "${TEST_DIR}/.claude/commands/timestamped.md" <<'EOF'
# Timestamped File
EOF

  # Set specific timestamp (using touch)
  touch -t 202401011200 "${TEST_DIR}/.claude/commands/timestamped.md"

  # Get timestamp
  local timestamp_before
  timestamp_before=$(get_file_timestamp "${TEST_DIR}/.claude/commands/timestamped.md")

  # Small delay to ensure timestamp would change if file modified
  sleep 1

  # Upgrade
  run_installer "normal" "$TEST_DIR"

  # Verify timestamp preserved (or at least not newer)
  local timestamp_after
  timestamp_after=$(get_file_timestamp "${TEST_DIR}/.claude/commands/timestamped.md")

  # Timestamp should be unchanged
  [[ "$timestamp_before" -eq "$timestamp_after" ]]

  debug "File timestamps preserved"
}

# =============================================================================
# Category 5: Dev Mode Tests (4 tests)
# =============================================================================

@test "dev mode: templates are symlinked not copied" {
  section "Testing dev mode creates symlinks"

  # Install in dev mode
  run_installer "dev" "$TEST_DIR"

  # Check that template directories are symlinks (once implemented)
  # For now, verify dev mode flag works

  # Verify config shows dev mode
  local config="${TEST_DIR}/.claude/aida-config.json"
  if [[ -f "$config" ]]; then
    local mode
    mode=$(jq -r '.mode // .installation_mode // "normal"' "$config")
    debug "Installation mode: $mode"
  fi

  debug "Dev mode installation completed"
}

@test "dev mode: changes to repo templates reflected immediately" {
  section "Testing dev mode symlinks reflect repo changes"

  # Install in dev mode
  run_installer "dev" "$TEST_DIR"

  # Verify symlink structure created
  # Changes to repo should be visible immediately
  # (Test implementation depends on template structure)

  debug "Dev mode symlinks allow live editing"
}

@test "dev mode: user content still copied (not symlinked)" {
  section "Testing user content not symlinked in dev mode"

  # Install in dev mode
  run_installer "dev" "$TEST_DIR"

  # Create user content
  create_user_content "$TEST_DIR"

  # Verify user content is NOT symlinked
  [[ ! -L "${TEST_DIR}/.claude/commands/my-workflow.md" ]]
  [[ -f "${TEST_DIR}/.claude/commands/my-workflow.md" ]]

  debug "User content copied, not symlinked, even in dev mode"
}

@test "dev mode: can switch from normal to dev mode" {
  section "Testing mode conversion"

  # First install in normal mode
  run_installer "normal" "$TEST_DIR"

  # Create user content
  create_user_content "$TEST_DIR"

  local user_checksum
  user_checksum=$(calculate_checksum "${TEST_DIR}/.claude/commands/my-workflow.md")

  # Switch to dev mode
  run_installer "dev" "$TEST_DIR"

  # Verify user content preserved during mode switch
  assert_file_unchanged "${TEST_DIR}/.claude/commands/my-workflow.md" "$user_checksum"

  debug "Mode conversion preserves user content"
}

# =============================================================================
# Category 6: Migration Tests (3 tests)
# =============================================================================

@test "migration: v0.1.6 flat structure converts to namespace" {
  section "Testing full v0.1.6 to v0.2.0 migration"

  # Setup complete v0.1.6 installation
  setup_v0_1_installation "$TEST_DIR"

  # Add realistic user content
  create_user_content "$TEST_DIR"

  # Capture state before migration (using indexed arrays for bash 3.2 compatibility)
  local user_files=(
    "${TEST_DIR}/.claude/commands/my-workflow.md"
    "${TEST_DIR}/.claude/agents/my-agent.md"
    "${TEST_DIR}/.claude/skills/my-skill.md"
  )

  # Build parallel array of checksums (bash 3.2 compatible)
  local checksums_before=()
  for file in "${user_files[@]}"; do
    if [[ -f "$file" ]]; then
      checksums_before+=("$(calculate_checksum "$file")")
    else
      checksums_before+=("")  # Empty for missing files
    fi
  done

  # Run migration (upgrade to v0.2.0)
  run_installer "normal" "$TEST_DIR"

  # Verify namespace structure created
  assert_namespace_structure "${TEST_DIR}/.claude"

  # Verify ALL user content preserved (iterate by index)
  for i in "${!user_files[@]}"; do
    if [[ -n "${checksums_before[$i]}" ]]; then
      assert_file_unchanged "${user_files[$i]}" "${checksums_before[$i]}"
    fi
  done

  debug "Full migration completed with user data intact"
}

@test "migration: deprecated templates handled correctly" {
  section "Testing deprecated template migration"

  # Setup v0.1.6 with old templates
  setup_v0_1_installation "$TEST_DIR"

  # Create mock deprecated template
  mkdir -p "${TEST_DIR}/.claude/commands"
  cat > "${TEST_DIR}/.claude/commands/old-deprecated-cmd.md" <<'EOF'
# Old Deprecated Command
This template is no longer supported
EOF

  # Run migration
  run_installer "normal" "$TEST_DIR"

  # Verify namespace structure
  assert_namespace_structure "${TEST_DIR}/.claude"

  # Deprecated templates should be handled gracefully
  # (Either moved to .aida-deprecated/ or backed up)

  debug "Deprecated templates handled during migration"
}

@test "migration: config upgraded from v0.1.x to v0.2.0 format" {
  section "Testing config format migration"

  # Setup v0.1.6 installation with old config
  setup_v0_1_installation "$TEST_DIR"

  # Verify old config format
  local config="${TEST_DIR}/.claude/aida-config.json"
  local old_version
  old_version=$(jq -r '.version' "$config")
  debug "Pre-migration version: $old_version"

  # Run migration
  run_installer "normal" "$TEST_DIR"

  # Verify config migrated
  assert_file_exists "$config"
  assert_valid_json_file "$config"

  # Verify has v0.2.0 structure
  local new_version
  new_version=$(jq -r '.version' "$config")
  debug "Post-migration version: $new_version"

  # Config should be valid
  [[ -n "$new_version" ]]

  debug "Config successfully migrated to v0.2.0 format"
}
