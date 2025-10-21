#!/usr/bin/env bash
# Test helper functions for upgrade scenario integration tests
# Provides utilities for testing installation, upgrades, and user content preservation

# Get fixtures directory
FIXTURES_DIR="${BATS_TEST_DIRNAME}/../fixtures"
readonly FIXTURES_DIR

# Get project root directory (via test_helpers.bash)
if [[ -z "${PROJECT_ROOT:-}" ]]; then
  PROJECT_ROOT="$(cd "$(dirname "${BATS_TEST_DIRNAME}")/.." && pwd)"
  export PROJECT_ROOT
fi

# Setup simulated v0.1.x installation
# Usage: setup_v0_1_installation "$TEST_DIR"
# Creates a v0.1.x-style flat structure installation
setup_v0_1_installation() {
  local test_dir="$1"

  if [[ -z "$test_dir" ]]; then
    echo "Error: setup_v0_1_installation requires test directory" >&2
    return 1
  fi

  # Create base directories with v0.1.x flat structure
  mkdir -p "${test_dir}/.claude/agents"
  mkdir -p "${test_dir}/.claude/commands"
  mkdir -p "${test_dir}/.claude/skills"

  # Copy v0.1.x fixtures if they exist
  if [[ -d "${FIXTURES_DIR}/v0.1-installation/.claude" ]]; then
    cp -R "${FIXTURES_DIR}/v0.1-installation/.claude/"* "${test_dir}/.claude/" 2>/dev/null || true
  fi

  # Create v0.1.x config file (old format with old filename)
  local config_file="${test_dir}/.claude/aida-config.json"
  cat > "$config_file" <<'EOF'
{
  "version": "0.1.6",
  "install_date": "2024-09-01T12:00:00Z",
  "installation_path": "~/.aida",
  "assistant_name": "JARVIS",
  "personality": "jarvis",
  "mode": "normal"
}
EOF

  # Create old CLAUDE.md at home
  cat > "${test_dir}/CLAUDE.md" <<'EOF'
# CLAUDE.md - AIDA v0.1.6

This is JARVIS, your AI assistant.

Version: 0.1.6
EOF

  # Create ~/.aida symlink to repo (simulating v0.1.x)
  ln -s "${PROJECT_ROOT}" "${test_dir}/.aida"

  return 0
}

# Create user content in test directory
# Usage: create_user_content "$TEST_DIR"
# Creates realistic user-generated content outside .aida/ namespace
create_user_content() {
  local test_dir="$1"

  if [[ -z "$test_dir" ]]; then
    echo "Error: create_user_content requires test directory" >&2
    return 1
  fi

  # User commands
  mkdir -p "${test_dir}/.claude/commands"
  cat > "${test_dir}/.claude/commands/my-workflow.md" <<'EOF'
# My Custom Workflow

This is my personal workflow command.

**User-generated content - DO NOT DELETE**
EOF

  cat > "${test_dir}/.claude/commands/team-deploy.md" <<'EOF'
# Team Deployment Workflow

Deployment workflow for my team.
EOF

  # User agents
  mkdir -p "${test_dir}/.claude/agents"
  cat > "${test_dir}/.claude/agents/my-agent.md" <<'EOF'
# My Custom Agent

This is my personal agent definition.

**User-generated content - DO NOT DELETE**
EOF

  # User skills
  mkdir -p "${test_dir}/.claude/skills"
  cat > "${test_dir}/.claude/skills/my-skill.md" <<'EOF'
# My Custom Skill

This is my personal skill.

**User-generated content - DO NOT DELETE**
EOF

  # Nested user content
  mkdir -p "${test_dir}/.claude/commands/my-team/workflows"
  cat > "${test_dir}/.claude/commands/my-team/workflows/deploy.md" <<'EOF'
# Nested Deploy Command

Complex nested user content structure.
EOF

  # User content with special characters
  cat > "${test_dir}/.claude/commands/my-workflow (2024-09-15).md" <<'EOF'
# Workflow with Special Characters

Testing special character handling.
EOF

  # Hidden user file
  cat > "${test_dir}/.claude/commands/.my-hidden-config" <<'EOF'
# Hidden configuration file
secret_value=abc123
EOF

  return 0
}

# Run installer in test environment
# Usage: run_installer "normal" "$TEST_DIR"
#        run_installer "dev" "$TEST_DIR"
run_installer() {
  local mode="${1:-normal}"
  local test_dir="$2"

  if [[ -z "$test_dir" ]]; then
    echo "Error: run_installer requires test directory" >&2
    return 1
  fi

  # Set HOME to test directory for installation
  local original_home="$HOME"
  export HOME="$test_dir"

  # Build installer command
  local installer_cmd="${PROJECT_ROOT}/install.sh"
  local installer_args=""

  if [[ "$mode" == "dev" ]]; then
    installer_args="--dev"
  fi

  # Run installer with automatic yes responses
  # Provide: assistant name (jarvis), personality choice (1)
  if [[ "$mode" == "dev" ]]; then
    # Dev mode needs user input
    echo -e "jarvis\n1\n" | "$installer_cmd" $installer_args 2>&1
  else
    # Normal mode with non-interactive flag (if supported)
    # For now, provide default answers
    echo -e "jarvis\n1\n" | "$installer_cmd" $installer_args 2>&1
  fi

  local exit_code=$?

  # Restore original HOME
  export HOME="$original_home"

  return $exit_code
}

# Verify file unchanged by comparing checksums
# Usage: assert_file_unchanged "/path/to/file" "expected_checksum"
assert_file_unchanged() {
  local file="$1"
  local expected_checksum="$2"

  if [[ -z "$file" ]] || [[ -z "$expected_checksum" ]]; then
    echo "Error: assert_file_unchanged requires file and checksum" >&2
    return 1
  fi

  if [[ ! -f "$file" ]]; then
    echo "Assertion failed: File not found: $file" >&2
    return 1
  fi

  # Calculate actual checksum (cross-platform)
  local actual_checksum
  if command -v sha256sum >/dev/null 2>&1; then
    # Linux
    actual_checksum=$(sha256sum "$file" | awk '{print $1}')
  elif command -v shasum >/dev/null 2>&1; then
    # macOS
    actual_checksum=$(shasum -a 256 "$file" | awk '{print $1}')
  else
    echo "Error: No checksum command available" >&2
    return 1
  fi

  if [[ "$actual_checksum" != "$expected_checksum" ]]; then
    echo "Assertion failed: File content changed" >&2
    echo "  File: $file" >&2
    echo "  Expected checksum: $expected_checksum" >&2
    echo "  Actual checksum: $actual_checksum" >&2
    return 1
  fi

  return 0
}

# Calculate file checksum
# Usage: checksum=$(calculate_checksum "/path/to/file")
calculate_checksum() {
  local file="$1"

  if [[ -z "$file" ]]; then
    echo "Error: calculate_checksum requires file path" >&2
    return 1
  fi

  if [[ ! -f "$file" ]]; then
    echo "Error: File not found: $file" >&2
    return 1
  fi

  # Calculate checksum (cross-platform)
  if command -v sha256sum >/dev/null 2>&1; then
    # Linux
    sha256sum "$file" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    # macOS
    shasum -a 256 "$file" | awk '{print $1}'
  else
    echo "Error: No checksum command available" >&2
    return 1
  fi
}

# Verify directory has namespace structure
# Usage: assert_namespace_structure "$TEST_DIR/.claude"
assert_namespace_structure() {
  local base_dir="$1"

  if [[ -z "$base_dir" ]]; then
    echo "Error: assert_namespace_structure requires base directory" >&2
    return 1
  fi

  # Check for .aida/ namespace directories
  local errors=0

  if [[ ! -d "${base_dir}/commands/.aida" ]]; then
    echo "Assertion failed: Missing ${base_dir}/commands/.aida/" >&2
    ((errors++))
  fi

  if [[ ! -d "${base_dir}/agents/.aida" ]]; then
    echo "Assertion failed: Missing ${base_dir}/agents/.aida/" >&2
    ((errors++))
  fi

  if [[ ! -d "${base_dir}/skills/.aida" ]]; then
    echo "Assertion failed: Missing ${base_dir}/skills/.aida/" >&2
    ((errors++))
  fi

  if [[ $errors -gt 0 ]]; then
    return 1
  fi

  return 0
}

# Verify AIDA templates are in .aida/ namespace
# Usage: assert_aida_templates_namespaced "$TEST_DIR/.claude"
assert_aida_templates_namespaced() {
  local base_dir="$1"

  if [[ -z "$base_dir" ]]; then
    echo "Error: assert_aida_templates_namespaced requires base directory" >&2
    return 1
  fi

  # All AIDA templates should be in .aida/ subdirectories
  # Look for common AIDA template names outside .aida/

  local found_outside_namespace=false

  # Check commands
  if [[ -f "${base_dir}/commands/start-work.md" ]] && [[ ! -L "${base_dir}/commands/start-work.md" ]]; then
    echo "Assertion failed: AIDA template outside namespace: commands/start-work.md" >&2
    found_outside_namespace=true
  fi

  if [[ -f "${base_dir}/commands/implement.md" ]] && [[ ! -L "${base_dir}/commands/implement.md" ]]; then
    echo "Assertion failed: AIDA template outside namespace: commands/implement.md" >&2
    found_outside_namespace=true
  fi

  # Check agents
  if [[ -f "${base_dir}/agents/secretary.md" ]] && [[ ! -L "${base_dir}/agents/secretary.md" ]]; then
    echo "Assertion failed: AIDA template outside namespace: agents/secretary.md" >&2
    found_outside_namespace=true
  fi

  if [[ "$found_outside_namespace" == "true" ]]; then
    return 1
  fi

  return 0
}

# Assert file has not changed (by content comparison)
# Usage: assert_file_content_unchanged "/path/to/file" "expected content"
assert_file_content_unchanged() {
  local file="$1"
  local expected_content="$2"

  if [[ -z "$file" ]] || [[ -z "$expected_content" ]]; then
    echo "Error: assert_file_content_unchanged requires file and content" >&2
    return 1
  fi

  if [[ ! -f "$file" ]]; then
    echo "Assertion failed: File not found: $file" >&2
    return 1
  fi

  local actual_content
  actual_content=$(cat "$file")

  if [[ "$actual_content" != "$expected_content" ]]; then
    echo "Assertion failed: File content changed" >&2
    echo "  File: $file" >&2
    echo "  Expected: $expected_content" >&2
    echo "  Actual: $actual_content" >&2
    return 1
  fi

  return 0
}

# Verify config file has required v0.2.0 fields
# Usage: assert_config_v0_2_format "$config_file"
assert_config_v0_2_format() {
  local config_file="$1"

  if [[ -z "$config_file" ]]; then
    echo "Error: assert_config_v0_2_format requires config file" >&2
    return 1
  fi

  if [[ ! -f "$config_file" ]]; then
    echo "Assertion failed: Config file not found: $config_file" >&2
    return 1
  fi

  # Check for v0.2.0 fields using jq
  local errors=0

  # Version should be >= 0.2.0
  local version
  version=$(jq -r '.version' "$config_file")
  if [[ ! "$version" =~ ^0\.2\. ]]; then
    echo "Assertion failed: Config version not 0.2.x: $version" >&2
    ((errors++))
  fi

  # Should have installation_mode field (new in v0.2.0)
  if ! jq -e '.installation_mode' "$config_file" >/dev/null 2>&1; then
    echo "Assertion failed: Config missing installation_mode field" >&2
    ((errors++))
  fi

  # Should have namespace_version field (new in v0.2.0)
  if ! jq -e '.namespace_version' "$config_file" >/dev/null 2>&1; then
    echo "Assertion failed: Config missing namespace_version field" >&2
    ((errors++))
  fi

  if [[ $errors -gt 0 ]]; then
    return 1
  fi

  return 0
}

# Assert file timestamp has not changed
# Usage: assert_file_timestamp_preserved "/path/to/file" "expected_timestamp"
assert_file_timestamp_preserved() {
  local file="$1"
  local expected_timestamp="$2"

  if [[ -z "$file" ]] || [[ -z "$expected_timestamp" ]]; then
    echo "Error: assert_file_timestamp_preserved requires file and timestamp" >&2
    return 1
  fi

  if [[ ! -f "$file" ]]; then
    echo "Assertion failed: File not found: $file" >&2
    return 1
  fi

  # Get file modification timestamp (cross-platform)
  local actual_timestamp
  if [[ "$(uname)" == "Darwin" ]]; then
    # macOS (BSD stat)
    actual_timestamp=$(stat -f "%m" "$file")
  else
    # Linux (GNU stat)
    actual_timestamp=$(stat -c "%Y" "$file")
  fi

  if [[ "$actual_timestamp" != "$expected_timestamp" ]]; then
    echo "Assertion failed: File timestamp changed" >&2
    echo "  File: $file" >&2
    echo "  Expected: $expected_timestamp" >&2
    echo "  Actual: $actual_timestamp" >&2
    return 1
  fi

  return 0
}

# Get file modification timestamp
# Usage: timestamp=$(get_file_timestamp "/path/to/file")
get_file_timestamp() {
  local file="$1"

  if [[ -z "$file" ]]; then
    echo "Error: get_file_timestamp requires file path" >&2
    return 1
  fi

  if [[ ! -f "$file" ]]; then
    echo "Error: File not found: $file" >&2
    return 1
  fi

  # Get file modification timestamp (cross-platform)
  if [[ "$(uname)" == "Darwin" ]]; then
    # macOS (BSD stat)
    stat -f "%m" "$file"
  else
    # Linux (GNU stat)
    stat -c "%Y" "$file"
  fi
}

# Assert user content exists outside .aida/ namespace
# Usage: assert_user_content_outside_namespace "$TEST_DIR/.claude"
assert_user_content_outside_namespace() {
  local base_dir="$1"

  if [[ -z "$base_dir" ]]; then
    echo "Error: assert_user_content_outside_namespace requires base directory" >&2
    return 1
  fi

  # Count files outside .aida/ namespace
  local user_file_count=0

  # Commands outside .aida/
  if [[ -d "${base_dir}/commands" ]]; then
    user_file_count=$(find "${base_dir}/commands" -type f ! -path "*/\.aida/*" | wc -l | tr -d ' ')
  fi

  if [[ $user_file_count -eq 0 ]]; then
    echo "Assertion failed: No user content found outside .aida/ namespace" >&2
    return 1
  fi

  return 0
}

# Assert deprecated templates in separate namespace
# Usage: assert_deprecated_templates_namespaced "$TEST_DIR/.claude"
assert_deprecated_templates_namespaced() {
  local base_dir="$1"

  if [[ -z "$base_dir" ]]; then
    echo "Error: assert_deprecated_templates_namespaced requires base directory" >&2
    return 1
  fi

  # Deprecated templates should be in .aida-deprecated/
  if [[ ! -d "${base_dir}/commands/.aida-deprecated" ]]; then
    echo "Assertion failed: Missing ${base_dir}/commands/.aida-deprecated/" >&2
    return 1
  fi

  return 0
}
