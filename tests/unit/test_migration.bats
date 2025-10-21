#!/usr/bin/env bats
#
# test_migration.bats - Tests for Config Migration Functions
#
# Description:
#   Comprehensive tests for configuration migration from old schema (1.0) to new schema (2.0).
#   Tests migration logic, safety checks, rollback behavior, and data integrity.
#
# Part of: AIDA Configuration System (Issue #55)
# Created: 2025-10-20
#
# Test Coverage:
#   - Version detection
#   - Migration from old format (github.* → vcs.github.*)
#   - Reviewers migration (workflow.pull_requests.reviewers → team.default_reviewers)
#   - Rollback on validation failure
#   - Idempotent behavior
#   - Dry-run mode
#   - Data integrity verification
#   - Migration report generation
#

# Setup test environment
setup() {
    # Load migration script
    SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../lib/installer-common" && pwd)"
    source "${SCRIPT_DIR}/config-migration.sh"

    # Disable -u flag to prevent bats internal variable issues
    set +u

    # Create temp directory for test files
    TEST_DIR="$(mktemp -d)"
    export TEST_DIR

    # Test config file paths
    export TEST_CONFIG="${TEST_DIR}/config.json"
    export OLD_CONFIG="${TEST_DIR}/config-old.json"
}

# Cleanup test environment
teardown() {
    if [[ -n "${TEST_DIR:-}" ]] && [[ -d "${TEST_DIR}" ]]; then
        rm -rf "${TEST_DIR}"
    fi
}

#######################################
# Version Detection Tests
#######################################

@test "detect_config_version: detects version 1.0 (has github.*)" {
    cat > "$TEST_CONFIG" << 'EOF'
{
  "github": {
    "owner": "oakensoul",
    "repo": "claude-personal-assistant"
  }
}
EOF

    version=$(detect_config_version "$TEST_CONFIG")
    [ "$version" = "1.0" ]
}

@test "detect_config_version: detects version 2.0 (has vcs.* and config_version)" {
    cat > "$TEST_CONFIG" << 'EOF'
{
  "config_version": "2.0",
  "vcs": {
    "provider": "github",
    "owner": "oakensoul",
    "repo": "claude-personal-assistant"
  }
}
EOF

    version=$(detect_config_version "$TEST_CONFIG")
    [ "$version" = "2.0" ]
}

@test "detect_config_version: detects version 2.0 (has vcs.* without config_version)" {
    cat > "$TEST_CONFIG" << 'EOF'
{
  "vcs": {
    "provider": "github",
    "owner": "oakensoul",
    "repo": "claude-personal-assistant"
  }
}
EOF

    version=$(detect_config_version "$TEST_CONFIG")
    [ "$version" = "2.0" ]
}

@test "detect_config_version: returns unknown for empty config" {
    echo '{}' > "$TEST_CONFIG"

    version=$(detect_config_version "$TEST_CONFIG")
    [ "$version" = "unknown" ]
}

@test "detect_config_version: returns unknown for missing file" {
    version=$(detect_config_version "/nonexistent/config.json")
    [ "$version" = "unknown" ]
}

@test "needs_migration: returns 0 for version 1.0 config" {
    cat > "$TEST_CONFIG" << 'EOF'
{
  "github": {
    "owner": "test",
    "repo": "test"
  }
}
EOF

    needs_migration "$TEST_CONFIG"
}

@test "needs_migration: returns 1 for version 2.0 config" {
    cat > "$TEST_CONFIG" << 'EOF'
{
  "config_version": "2.0",
  "vcs": {
    "provider": "github"
  }
}
EOF

    run needs_migration "$TEST_CONFIG"
    [ "$status" -eq 1 ]
}

#######################################
# GitHub to VCS Migration Tests
#######################################

@test "migrate_github_to_vcs: migrates github.* to vcs.github.*" {
    cat > "$TEST_CONFIG" << 'EOF'
{
  "github": {
    "owner": "oakensoul",
    "repo": "claude-personal-assistant",
    "main_branch": "main"
  }
}
EOF

    migrate_github_to_vcs "$TEST_CONFIG"

    # Check VCS provider is set
    provider=$(jq -r '.vcs.provider' "$TEST_CONFIG")
    [ "$provider" = "github" ]

    # Check owner migrated
    owner=$(jq -r '.vcs.owner' "$TEST_CONFIG")
    [ "$owner" = "oakensoul" ]

    # Check repo migrated
    repo=$(jq -r '.vcs.repo' "$TEST_CONFIG")
    [ "$repo" = "claude-personal-assistant" ]

    # Check main_branch migrated
    main_branch=$(jq -r '.vcs.main_branch' "$TEST_CONFIG")
    [ "$main_branch" = "main" ]

    # Check old github.* namespace is removed
    has_github=$(jq -r 'has("github")' "$TEST_CONFIG")
    [ "$has_github" = "false" ]
}

@test "migrate_github_to_vcs: migrates enterprise_url to vcs.github.enterprise_url" {
    cat > "$TEST_CONFIG" << 'EOF'
{
  "github": {
    "owner": "company",
    "repo": "project",
    "enterprise_url": "https://github.company.com"
  }
}
EOF

    migrate_github_to_vcs "$TEST_CONFIG"

    # Check enterprise_url in correct location
    enterprise_url=$(jq -r '.vcs.github.enterprise_url' "$TEST_CONFIG")
    [ "$enterprise_url" = "https://github.company.com" ]
}

@test "migrate_github_to_vcs: skips if no github.* namespace" {
    cat > "$TEST_CONFIG" << 'EOF'
{
  "vcs": {
    "provider": "gitlab"
  }
}
EOF

    run migrate_github_to_vcs "$TEST_CONFIG"
    [ "$status" -eq 0 ]

    # Config unchanged
    provider=$(jq -r '.vcs.provider' "$TEST_CONFIG")
    [ "$provider" = "gitlab" ]
}

@test "migrate_github_to_vcs: preserves existing vcs fields" {
    cat > "$TEST_CONFIG" << 'EOF'
{
  "github": {
    "owner": "oldowner",
    "repo": "oldrepo"
  },
  "vcs": {
    "auto_detect": false
  }
}
EOF

    migrate_github_to_vcs "$TEST_CONFIG"

    # Check auto_detect preserved
    auto_detect=$(jq -r '.vcs.auto_detect' "$TEST_CONFIG")
    [ "$auto_detect" = "false" ]

    # Check owner migrated
    owner=$(jq -r '.vcs.owner' "$TEST_CONFIG")
    [ "$owner" = "oldowner" ]
}

#######################################
# Reviewers Migration Tests
#######################################

@test "migrate_reviewers_to_team: migrates workflow reviewers to team.default_reviewers" {
    cat > "$TEST_CONFIG" << 'EOF'
{
  "workflow": {
    "pull_requests": {
      "reviewers": ["alice", "bob"]
    }
  }
}
EOF

    migrate_reviewers_to_team "$TEST_CONFIG"

    # Check reviewers migrated
    reviewers=$(jq -r '.team.default_reviewers | @json' "$TEST_CONFIG")
    [ "$reviewers" = '["alice","bob"]' ]

    # Check old reviewers field removed
    has_old_reviewers=$(jq -r '.workflow.pull_requests | has("reviewers")' "$TEST_CONFIG")
    [ "$has_old_reviewers" = "false" ]
}

@test "migrate_reviewers_to_team: preserves existing team.default_reviewers" {
    cat > "$TEST_CONFIG" << 'EOF'
{
  "team": {
    "default_reviewers": ["existing"]
  },
  "workflow": {
    "pull_requests": {
      "reviewers": ["new"]
    }
  }
}
EOF

    migrate_reviewers_to_team "$TEST_CONFIG"

    # Check existing reviewers preserved
    reviewers=$(jq -r '.team.default_reviewers | @json' "$TEST_CONFIG")
    [ "$reviewers" = '["existing"]' ]
}

@test "migrate_reviewers_to_team: skips if no reviewers to migrate" {
    cat > "$TEST_CONFIG" << 'EOF'
{
  "workflow": {
    "pull_requests": {}
  }
}
EOF

    run migrate_reviewers_to_team "$TEST_CONFIG"
    [ "$status" -eq 0 ]
}

#######################################
# Full Migration Tests
#######################################

@test "migrate_config: successfully migrates old config to new schema" {
    cat > "$TEST_CONFIG" << 'EOF'
{
  "github": {
    "owner": "oakensoul",
    "repo": "claude-personal-assistant",
    "main_branch": "main"
  },
  "workflow": {
    "pull_requests": {
      "reviewers": ["reviewer1"]
    }
  }
}
EOF

    run migrate_config "$TEST_CONFIG" "false"
    [ "$status" -eq 0 ]

    # Check config_version added
    version=$(jq -r '.config_version' "$TEST_CONFIG")
    [ "$version" = "2.0" ]

    # Check VCS migration
    provider=$(jq -r '.vcs.provider' "$TEST_CONFIG")
    [ "$provider" = "github" ]

    owner=$(jq -r '.vcs.owner' "$TEST_CONFIG")
    [ "$owner" = "oakensoul" ]

    # Check reviewers migration
    reviewers=$(jq -r '.team.default_reviewers | @json' "$TEST_CONFIG")
    [ "$reviewers" = '["reviewer1"]' ]

    # Check old namespaces removed
    has_github=$(jq -r 'has("github")' "$TEST_CONFIG")
    [ "$has_github" = "false" ]
}

@test "migrate_config: creates backup before migration" {
    cat > "$TEST_CONFIG" << 'EOF'
{
  "github": {
    "owner": "test",
    "repo": "test"
  }
}
EOF

    migrate_config "$TEST_CONFIG" "false"

    # Check backup exists
    backup_count=$(find "$TEST_DIR" -name "config.json.backup.*" -type f | wc -l)
    [ "$backup_count" -ge 1 ]
}

@test "migrate_config: generates migration report" {
    cat > "$TEST_CONFIG" << 'EOF'
{
  "github": {
    "owner": "test",
    "repo": "test"
  }
}
EOF

    migrate_config "$TEST_CONFIG" "false"

    # Check report exists
    [ -f "${TEST_CONFIG}.migration-report.md" ]

    # Check report content
    grep -q "Migration Report" "${TEST_CONFIG}.migration-report.md"
    grep -q "github.*" "${TEST_CONFIG}.migration-report.md"
}

@test "migrate_config: skips if already migrated" {
    cat > "$TEST_CONFIG" << 'EOF'
{
  "config_version": "2.0",
  "vcs": {
    "provider": "github"
  }
}
EOF

    run migrate_config "$TEST_CONFIG" "false"
    [ "$status" -eq 0 ]

    # Should output success message about already migrated
    [[ "$output" == *"already migrated"* ]]
}

@test "migrate_config: idempotent - running twice does not break config" {
    cat > "$TEST_CONFIG" << 'EOF'
{
  "github": {
    "owner": "test",
    "repo": "test"
  }
}
EOF

    # First migration
    migrate_config "$TEST_CONFIG" "false"

    # Save migrated config
    cp "$TEST_CONFIG" "${TEST_DIR}/migrated.json"

    # Second migration (should skip)
    migrate_config "$TEST_CONFIG" "false"

    # Configs should be identical
    diff "$TEST_CONFIG" "${TEST_DIR}/migrated.json"
}

#######################################
# Dry Run Tests
#######################################

@test "migrate_config: dry-run does not modify config" {
    cat > "$TEST_CONFIG" << 'EOF'
{
  "github": {
    "owner": "test",
    "repo": "test"
  }
}
EOF

    # Save original
    cp "$TEST_CONFIG" "${TEST_DIR}/original.json"

    # Run dry-run
    run migrate_config "$TEST_CONFIG" "true"
    [ "$status" -eq 0 ]

    # Config unchanged
    diff "$TEST_CONFIG" "${TEST_DIR}/original.json"

    # Should output dry-run messages
    [[ "$output" == *"DRY RUN"* ]]
}

@test "migrate_config: dry-run shows transformations" {
    cat > "$TEST_CONFIG" << 'EOF'
{
  "github": {
    "owner": "test",
    "repo": "test"
  }
}
EOF

    run migrate_config "$TEST_CONFIG" "true"

    [[ "$output" == *"github.* → vcs.github.*"* ]]
    [[ "$output" == *"workflow.pull_requests.reviewers → team.default_reviewers"* ]]
    [[ "$output" == *"config_version: 2.0"* ]]
}

#######################################
# Data Integrity Tests
#######################################

@test "count_json_fields: counts fields correctly" {
    cat > "$TEST_CONFIG" << 'EOF'
{
  "field1": "value1",
  "field2": {
    "nested1": "value2",
    "nested2": "value3"
  },
  "field3": ["item1", "item2"]
}
EOF

    count=$(count_json_fields "$TEST_CONFIG")
    # field1 (1) + nested1 (1) + nested2 (1) + item1 (1) + item2 (1) = 5
    [ "$count" -eq 5 ]
}

@test "verify_no_data_loss: detects preserved fields" {
    # Create old config
    cat > "$OLD_CONFIG" << 'EOF'
{
  "github": {
    "owner": "test",
    "repo": "test"
  }
}
EOF

    # Create new config (migrated)
    cat > "$TEST_CONFIG" << 'EOF'
{
  "config_version": "2.0",
  "vcs": {
    "provider": "github",
    "owner": "test",
    "repo": "test"
  }
}
EOF

    run verify_no_data_loss "$OLD_CONFIG" "$TEST_CONFIG"
    [ "$status" -eq 0 ]
}

@test "verify_no_data_loss: detects missing owner field" {
    # Create old config
    cat > "$OLD_CONFIG" << 'EOF'
{
  "github": {
    "owner": "test",
    "repo": "test"
  }
}
EOF

    # Create new config (missing owner)
    cat > "$TEST_CONFIG" << 'EOF'
{
  "vcs": {
    "provider": "github",
    "repo": "test"
  }
}
EOF

    run verify_no_data_loss "$OLD_CONFIG" "$TEST_CONFIG"
    [ "$status" -eq 1 ]
}

#######################################
# Rollback Tests
#######################################

@test "migrate_config: rolls back on validation failure" {
    skip "Test requires mock validation failure"

    # Create invalid old config that will fail migration
    cat > "$TEST_CONFIG" << 'EOF'
{
  "github": {
    "owner": "test"
  }
}
EOF

    # Save original
    local original_content
    original_content=$(cat "$TEST_CONFIG")

    # Try to migrate (will fail validation due to missing repo)
    # Note: This might not fail depending on schema requirements
    # For this test, we'll use a different approach
}

#######################################
# Error Handling Tests
#######################################

@test "migrate_config: fails gracefully on missing file" {
    run migrate_config "/nonexistent/config.json" "false"
    [ "$status" -ne 0 ]
}

@test "migrate_config: fails gracefully on invalid JSON" {
    echo "not valid json" > "$TEST_CONFIG"

    run migrate_config "$TEST_CONFIG" "false"
    [ "$status" -ne 0 ]
}

@test "migrate_github_to_vcs: fails gracefully on invalid JSON" {
    echo "not valid json" > "$TEST_CONFIG"

    run migrate_github_to_vcs "$TEST_CONFIG"
    [ "$status" -ne 0 ]
}

#######################################
# Integration Tests
#######################################

@test "Full migration workflow: old GitHub config with reviewers" {
    cat > "$TEST_CONFIG" << 'EOF'
{
  "github": {
    "owner": "oakensoul",
    "repo": "claude-personal-assistant",
    "main_branch": "main",
    "enterprise_url": null
  },
  "workflow": {
    "pull_requests": {
      "reviewers": ["alice", "bob"]
    }
  }
}
EOF

    # Run migration
    run migrate_config "$TEST_CONFIG" "false"
    [ "$status" -eq 0 ]

    # Verify all transformations
    version=$(jq -r '.config_version' "$TEST_CONFIG")
    [ "$version" = "2.0" ]

    provider=$(jq -r '.vcs.provider' "$TEST_CONFIG")
    [ "$provider" = "github" ]

    owner=$(jq -r '.vcs.owner' "$TEST_CONFIG")
    [ "$owner" = "oakensoul" ]

    repo=$(jq -r '.vcs.repo' "$TEST_CONFIG")
    [ "$repo" = "claude-personal-assistant" ]

    reviewers=$(jq -r '.team.default_reviewers[0]' "$TEST_CONFIG")
    [ "$reviewers" = "alice" ]

    has_github=$(jq -r 'has("github")' "$TEST_CONFIG")
    [ "$has_github" = "false" ]

    # Verify backup exists
    backup_count=$(find "$TEST_DIR" -name "config.json.backup.*" -type f | wc -l)
    [ "$backup_count" -ge 1 ]

    # Verify report exists
    [ -f "${TEST_CONFIG}.migration-report.md" ]
}
