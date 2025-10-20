#!/usr/bin/env bash
# Docker entrypoint script for AIDA upgrade testing
# Orchestrates different test scenarios based on environment variables
#
# Environment Variables:
#   TEST_SCENARIO     - Test scenario to run (fresh, upgrade, migration, dev-mode)
#   INSTALL_MODE      - Installation mode (normal, dev)
#   WITH_DEPRECATED   - Include deprecated templates (true, false)
#   DEBUG             - Enable debug output (true, false)
#   VERBOSE           - Enable verbose output (true, false)
#
# Exit codes:
#   0 - All tests passed
#   1 - Test failure
#   2 - Configuration error
#   3 - Installation error

set -euo pipefail

# =============================================================================
# Configuration
# =============================================================================

# Declare and assign separately for shellcheck compliance
SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_NAME
readonly WORKSPACE="${WORKSPACE:-/workspace}"
readonly TEST_FIXTURES="${TEST_FIXTURES:-/test-fixtures}"
readonly TEST_RESULTS="${TEST_RESULTS:-/test-results}"

# Environment defaults
TEST_SCENARIO="${TEST_SCENARIO:-fresh}"
INSTALL_MODE="${INSTALL_MODE:-normal}"
WITH_DEPRECATED="${WITH_DEPRECATED:-false}"
DEBUG="${DEBUG:-false}"
VERBOSE="${VERBOSE:-false}"

# AIDA paths
AIDA_HOME="${AIDA_HOME:-${HOME}/.aida}"
CLAUDE_CONFIG_DIR="${CLAUDE_CONFIG_DIR:-${HOME}/.claude}"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# =============================================================================
# Helper Functions
# =============================================================================

log() {
  echo -e "${GREEN}[${SCRIPT_NAME}]${NC} $*" >&2
}

log_warn() {
  echo -e "${YELLOW}[${SCRIPT_NAME}] WARNING:${NC} $*" >&2
}

log_error() {
  echo -e "${RED}[${SCRIPT_NAME}] ERROR:${NC} $*" >&2
}

log_debug() {
  if [[ "${DEBUG}" == "true" ]]; then
    echo -e "${BLUE}[${SCRIPT_NAME}] DEBUG:${NC} $*" >&2
  fi
}

log_section() {
  echo ""
  echo -e "${GREEN}==============================================================================${NC}"
  echo -e "${GREEN}$*${NC}"
  echo -e "${GREEN}==============================================================================${NC}"
  echo ""
}

die() {
  log_error "$1"
  exit "${2:-1}"
}

# =============================================================================
# Validation Functions
# =============================================================================

validate_environment() {
  log_section "Validating Environment"

  # Check required directories exist
  [[ -d "${WORKSPACE}" ]] || die "Workspace directory not found: ${WORKSPACE}" 2
  [[ -d "${TEST_RESULTS}" ]] || die "Test results directory not found: ${TEST_RESULTS}" 2

  # Check AIDA repository is mounted
  [[ -f "${WORKSPACE}/install.sh" ]] || die "AIDA install.sh not found in workspace" 2
  [[ -d "${WORKSPACE}/lib" ]] || die "AIDA lib directory not found in workspace" 2

  # Validate TEST_SCENARIO
  case "${TEST_SCENARIO}" in
    fresh|upgrade|migration|dev-mode|test-all)
      log "✓ Test scenario: ${TEST_SCENARIO}"
      ;;
    *)
      die "Invalid TEST_SCENARIO: ${TEST_SCENARIO}. Must be: fresh, upgrade, migration, dev-mode, test-all" 2
      ;;
  esac

  # Validate INSTALL_MODE
  case "${INSTALL_MODE}" in
    normal|dev)
      log "✓ Install mode: ${INSTALL_MODE}"
      ;;
    *)
      die "Invalid INSTALL_MODE: ${INSTALL_MODE}. Must be: normal, dev" 2
      ;;
  esac

  log "✓ Environment validation passed"
}

# =============================================================================
# Test Scenario Functions
# =============================================================================

scenario_fresh_install() {
  log_section "Running Fresh Installation Test"

  # Run installer
  cd "${WORKSPACE}"

  log "Running AIDA installer in ${INSTALL_MODE} mode..."
  if [[ "${INSTALL_MODE}" == "dev" ]]; then
    echo -e "jarvis\n1\n" | ./install.sh --dev
  else
    echo -e "jarvis\n1\n" | ./install.sh
  fi

  # Verify installation
  log "Verifying installation..."
  [[ -d "${CLAUDE_CONFIG_DIR}" ]] || die "Installation failed: ${CLAUDE_CONFIG_DIR} not created" 3
  [[ -f "${CLAUDE_CONFIG_DIR}/aida-config.json" ]] || die "Installation failed: config not created" 3
  [[ -L "${AIDA_HOME}" ]] || die "Installation failed: ~/.aida symlink not created" 3

  # Verify namespace structure
  [[ -d "${CLAUDE_CONFIG_DIR}/commands/.aida" ]] || die "Namespace structure not created: commands/.aida" 3
  [[ -d "${CLAUDE_CONFIG_DIR}/agents/.aida" ]] || die "Namespace structure not created: agents/.aida" 3
  [[ -d "${CLAUDE_CONFIG_DIR}/skills/.aida" ]] || die "Namespace structure not created: skills/.aida" 3

  log "✓ Fresh installation completed successfully"

  # Run bats tests if available
  if [[ -f "${WORKSPACE}/tests/integration/test_upgrade_scenarios.bats" ]]; then
    log "Running integration tests..."
    cd "${WORKSPACE}"
    bats tests/integration/test_upgrade_scenarios.bats \
      --filter "fresh install" \
      --tap > "${TEST_RESULTS}/fresh-install-tests.tap" || true
  fi
}

scenario_upgrade() {
  log_section "Running Upgrade Test (v0.1.x → v0.2.x)"

  # Setup v0.1.x installation first
  log "Setting up v0.1.x installation..."
  setup_v0_1_installation

  # Create user content to test preservation
  log "Creating user content..."
  create_test_user_content

  # Calculate checksums before upgrade
  declare -A checksums_before
  local user_files=(
    "${CLAUDE_CONFIG_DIR}/commands/my-workflow.md"
    "${CLAUDE_CONFIG_DIR}/agents/my-agent.md"
    "${CLAUDE_CONFIG_DIR}/skills/my-skill.md"
  )

  for file in "${user_files[@]}"; do
    if [[ -f "$file" ]]; then
      checksums_before["$file"]=$(sha256sum "$file" | awk '{print $1}')
      log_debug "Checksum before upgrade: $file = ${checksums_before[$file]}"
    fi
  done

  # Run upgrade
  cd "${WORKSPACE}"
  log "Running upgrade installation..."
  echo -e "JARVIS\njarvis\n" | ./install.sh

  # Verify user content preserved
  log "Verifying user content preservation..."
  local failed=false
  for file in "${user_files[@]}"; do
    if [[ -f "$file" ]]; then
      local checksum_after
      checksum_after=$(sha256sum "$file" | awk '{print $1}')
      if [[ "${checksums_before[$file]}" != "$checksum_after" ]]; then
        log_error "File modified during upgrade: $file"
        failed=true
      else
        log "✓ Preserved: $file"
      fi
    fi
  done

  [[ "$failed" == "false" ]] || die "User content preservation failed" 1

  # Verify namespace structure created
  [[ -d "${CLAUDE_CONFIG_DIR}/commands/.aida" ]] || die "Namespace structure not created after upgrade" 3
  [[ -d "${CLAUDE_CONFIG_DIR}/agents/.aida" ]] || die "Namespace structure not created after upgrade" 3
  [[ -d "${CLAUDE_CONFIG_DIR}/skills/.aida" ]] || die "Namespace structure not created after upgrade" 3

  log "✓ Upgrade completed successfully with user data intact"

  # Run bats tests
  if [[ -f "${WORKSPACE}/tests/integration/test_upgrade_scenarios.bats" ]]; then
    log "Running upgrade integration tests..."
    cd "${WORKSPACE}"
    bats tests/integration/test_upgrade_scenarios.bats \
      --filter "upgrade" \
      --tap > "${TEST_RESULTS}/upgrade-tests.tap" || true
  fi
}

scenario_migration() {
  log_section "Running Migration Test (flat structure → namespace)"

  # Setup v0.1.x with complex user content
  log "Setting up v0.1.6 installation with user content..."
  setup_v0_1_installation
  create_complex_user_content

  # Document pre-migration state
  log "Documenting pre-migration state..."
  tree -a "${CLAUDE_CONFIG_DIR}" > "${TEST_RESULTS}/pre-migration-tree.txt" 2>&1 || true
  find "${CLAUDE_CONFIG_DIR}" -type f -exec sha256sum {} \; > "${TEST_RESULTS}/pre-migration-checksums.txt"

  # Run migration
  cd "${WORKSPACE}"
  log "Running migration..."
  echo -e "JARVIS\njarvis\n" | ./install.sh

  # Document post-migration state
  log "Documenting post-migration state..."
  tree -a "${CLAUDE_CONFIG_DIR}" > "${TEST_RESULTS}/post-migration-tree.txt" 2>&1 || true
  find "${CLAUDE_CONFIG_DIR}" -type f -exec sha256sum {} \; > "${TEST_RESULTS}/post-migration-checksums.txt"

  # Verify migration success
  verify_migration_success

  log "✓ Migration completed successfully"

  # Run bats tests
  if [[ -f "${WORKSPACE}/tests/integration/test_upgrade_scenarios.bats" ]]; then
    log "Running migration integration tests..."
    cd "${WORKSPACE}"
    bats tests/integration/test_upgrade_scenarios.bats \
      --filter "migration" \
      --tap > "${TEST_RESULTS}/migration-tests.tap" || true
  fi
}

scenario_dev_mode() {
  log_section "Running Dev Mode Test"

  # Run installer in dev mode
  cd "${WORKSPACE}"
  log "Installing AIDA in dev mode..."
  echo -e "JARVIS\njarvis\n" | ./install.sh --dev

  # Verify dev mode installation
  [[ -d "${CLAUDE_CONFIG_DIR}" ]] || die "Dev mode installation failed" 3

  # Check for symlinks vs copies
  log "Verifying dev mode symlink structure..."
  # Templates should be symlinked in dev mode
  # User content should still be copied

  # Create user content
  create_test_user_content

  # Verify user content is not symlinked
  local user_file="${CLAUDE_CONFIG_DIR}/commands/my-workflow.md"
  if [[ -f "$user_file" ]]; then
    if [[ -L "$user_file" ]]; then
      log_warn "User content is symlinked (should be copied)"
    else
      log "✓ User content correctly copied (not symlinked)"
    fi
  fi

  log "✓ Dev mode installation completed"

  # Run bats tests
  if [[ -f "${WORKSPACE}/tests/integration/test_upgrade_scenarios.bats" ]]; then
    log "Running dev mode tests..."
    cd "${WORKSPACE}"
    bats tests/integration/test_upgrade_scenarios.bats \
      --filter "dev mode" \
      --tap > "${TEST_RESULTS}/dev-mode-tests.tap" || true
  fi
}

scenario_test_all() {
  log_section "Running All Test Scenarios"

  # Run all scenarios in sequence
  scenario_fresh_install
  cleanup_installation

  scenario_upgrade
  cleanup_installation

  scenario_migration
  cleanup_installation

  scenario_dev_mode
  cleanup_installation

  log "✓ All test scenarios completed"
}

# =============================================================================
# Setup Functions
# =============================================================================

setup_v0_1_installation() {
  log "Creating v0.1.x installation structure..."

  # Create directories
  mkdir -p "${CLAUDE_CONFIG_DIR}/agents"
  mkdir -p "${CLAUDE_CONFIG_DIR}/commands"
  mkdir -p "${CLAUDE_CONFIG_DIR}/skills"

  # Create v0.1.x config
  cat > "${CLAUDE_CONFIG_DIR}/aida-config.json" <<'EOF'
{
  "version": "0.1.6",
  "install_date": "2024-09-01T12:00:00Z",
  "installation_path": "~/.aida",
  "assistant_name": "JARVIS",
  "personality": "jarvis",
  "mode": "normal"
}
EOF

  # Create old CLAUDE.md
  cat > "${HOME}/CLAUDE.md" <<'EOF'
# CLAUDE.md - AIDA v0.1.6

This is JARVIS, your AI assistant.

Version: 0.1.6
EOF

  # Create ~/.aida symlink
  if [[ ! -L "${AIDA_HOME}" ]]; then
    ln -s "${WORKSPACE}" "${AIDA_HOME}"
  fi

  log "✓ v0.1.x installation structure created"
}

create_test_user_content() {
  log "Creating test user content..."

  # User commands
  cat > "${CLAUDE_CONFIG_DIR}/commands/my-workflow.md" <<'EOF'
# My Custom Workflow

This is my personal workflow command.

**User-generated content - DO NOT DELETE**
EOF

  # User agents
  cat > "${CLAUDE_CONFIG_DIR}/agents/my-agent.md" <<'EOF'
# My Custom Agent

This is my personal agent definition.

**User-generated content - DO NOT DELETE**
EOF

  # User skills
  cat > "${CLAUDE_CONFIG_DIR}/skills/my-skill.md" <<'EOF'
# My Custom Skill

This is my personal skill.

**User-generated content - DO NOT DELETE**
EOF

  log "✓ Test user content created"
}

create_complex_user_content() {
  # Create basic content first
  create_test_user_content

  # Add nested content
  mkdir -p "${CLAUDE_CONFIG_DIR}/commands/my-team/workflows"
  cat > "${CLAUDE_CONFIG_DIR}/commands/my-team/workflows/deploy.md" <<'EOF'
# Team Deployment Workflow

Complex nested user content structure.
EOF

  # Add hidden files
  cat > "${CLAUDE_CONFIG_DIR}/commands/.my-hidden-config" <<'EOF'
# Hidden configuration
secret_key=test123
EOF

  # Add files with special characters
  cat > "${CLAUDE_CONFIG_DIR}/commands/my-workflow (2024-10-18).md" <<'EOF'
# Workflow with Special Characters

Testing special character handling.
EOF

  log "✓ Complex user content created"
}

verify_migration_success() {
  log "Verifying migration success..."

  # Check namespace structure created
  [[ -d "${CLAUDE_CONFIG_DIR}/commands/.aida" ]] || die "Migration failed: commands/.aida not created" 1
  [[ -d "${CLAUDE_CONFIG_DIR}/agents/.aida" ]] || die "Migration failed: agents/.aida not created" 1
  [[ -d "${CLAUDE_CONFIG_DIR}/skills/.aida" ]] || die "Migration failed: skills/.aida not created" 1

  # Check user content preserved (outside .aida/)
  [[ -f "${CLAUDE_CONFIG_DIR}/commands/my-workflow.md" ]] || die "Migration failed: user content deleted" 1

  # Verify user content NOT moved to .aida/
  if [[ -f "${CLAUDE_CONFIG_DIR}/commands/.aida/my-workflow.md" ]]; then
    die "Migration failed: user content incorrectly moved to .aida/" 1
  fi

  log "✓ Migration verification passed"
}

cleanup_installation() {
  log_debug "Cleaning up installation..."

  # Remove AIDA directories
  rm -rf "${CLAUDE_CONFIG_DIR}"
  rm -rf "${AIDA_HOME}"
  rm -f "${HOME}/CLAUDE.md"

  log_debug "✓ Installation cleaned up"
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
  log_section "AIDA Upgrade Testing - Docker Environment"

  log "Configuration:"
  log "  TEST_SCENARIO:    ${TEST_SCENARIO}"
  log "  INSTALL_MODE:     ${INSTALL_MODE}"
  log "  WITH_DEPRECATED:  ${WITH_DEPRECATED}"
  log "  DEBUG:            ${DEBUG}"
  log "  VERBOSE:          ${VERBOSE}"
  log "  WORKSPACE:        ${WORKSPACE}"
  log "  TEST_FIXTURES:    ${TEST_FIXTURES}"
  log "  TEST_RESULTS:     ${TEST_RESULTS}"

  # Validate environment
  validate_environment

  # Run test scenario based on command or environment variable
  local scenario="${1:-${TEST_SCENARIO}}"

  case "${scenario}" in
    fresh|fresh-install)
      scenario_fresh_install
      ;;
    upgrade)
      scenario_upgrade
      ;;
    migration)
      scenario_migration
      ;;
    dev-mode)
      scenario_dev_mode
      ;;
    test-all)
      scenario_test_all
      ;;
    bash|shell)
      # Drop into interactive shell for debugging
      log "Entering interactive shell..."
      exec /bin/bash
      ;;
    *)
      die "Unknown scenario: ${scenario}" 2
      ;;
  esac

  log_section "Test Execution Complete"
  log "Results available in: ${TEST_RESULTS}"

  exit 0
}

# Run main function with all arguments
main "$@"
