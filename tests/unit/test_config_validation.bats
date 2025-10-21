#!/usr/bin/env bats
# tests/unit/test_config_validation.bats
#
# Comprehensive unit tests for config-validator.sh
# Tests all three validation tiers with 90%+ code coverage
#
# Test Coverage:
#   - Tier 1: Structure Validation (25+ tests)
#   - Tier 2: Provider Rules (30+ tests)
#   - Tier 3: Connectivity Stub (5+ tests)
#   - Error Messages (10+ tests)
#   - Edge Cases (10+ tests)
#
# Total: 80+ test cases

# Setup and teardown
setup() {
  # Create temp directory for test configs
  TEST_DIR="$(mktemp -d)"
  export TEST_DIR
  export VALIDATOR="${BATS_TEST_DIRNAME}/../../lib/installer-common/config-validator.sh"
  export FIXTURES="${BATS_TEST_DIRNAME}/../fixtures/configs"

  # Ensure validator is executable (skip if already executable, e.g., in Docker volumes)
  if [[ ! -x "$VALIDATOR" ]]; then
    chmod +x "$VALIDATOR" 2>/dev/null || true
  fi
}

teardown() {
  # Cleanup temp directory
  if [[ -d "$TEST_DIR" ]]; then
    rm -rf "$TEST_DIR"
  fi
}

################################################################################
# TIER 1: STRUCTURE VALIDATION TESTS (25+ tests)
################################################################################

# Valid Configs - Should Pass Structure Validation

@test "Tier 1: Valid GitHub simple config passes" {
  run "$VALIDATOR" --tier structure "${FIXTURES}/valid/github-simple.json"
  [ "$status" -eq 0 ]
}

@test "Tier 1: Valid GitHub enterprise config passes" {
  run "$VALIDATOR" --tier structure "${FIXTURES}/valid/github-enterprise.json"
  [ "$status" -eq 0 ]
}

@test "Tier 1: Valid GitLab simple config passes" {
  run "$VALIDATOR" --tier structure "${FIXTURES}/valid/gitlab-simple.json"
  [ "$status" -eq 0 ]
}

@test "Tier 1: Valid GitLab with Jira config passes" {
  run "$VALIDATOR" --tier structure "${FIXTURES}/valid/gitlab-jira.json"
  [ "$status" -eq 0 ]
}

@test "Tier 1: Valid Bitbucket config passes" {
  run "$VALIDATOR" --tier structure "${FIXTURES}/valid/bitbucket-simple.json"
  [ "$status" -eq 0 ]
}

@test "Tier 1: Valid Linear work tracker config passes" {
  run "$VALIDATOR" --tier structure "${FIXTURES}/valid/linear-work-tracker.json"
  [ "$status" -eq 0 ]
}

@test "Tier 1: Valid complete config with all options passes" {
  run "$VALIDATOR" --tier structure "${FIXTURES}/valid/complete.json"
  [ "$status" -eq 0 ]
}

# Structure Errors - Missing Required Fields

@test "Tier 1: Missing config_version fails" {
  run "$VALIDATOR" --tier structure "${FIXTURES}/invalid-structure/missing-config-version.json"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "config_version" ]]
}

@test "Tier 1: Invalid JSON syntax fails" {
  run "$VALIDATOR" --tier structure "${FIXTURES}/invalid-structure/invalid-json.json"
  [ "$status" -eq 1 ]
}

@test "Tier 1: Invalid VCS provider enum fails" {
  run "$VALIDATOR" --tier structure "${FIXTURES}/invalid-structure/invalid-provider.json"
  [ "$status" -eq 1 ]
}

@test "Tier 1: Wrong type for default_reviewers fails" {
  run "$VALIDATOR" --tier structure "${FIXTURES}/invalid-structure/wrong-types.json"
  [ "$status" -eq 1 ]
}

@test "Tier 1: Missing vcs.provider fails" {
  cat > "${TEST_DIR}/config.json" <<'EOF'
{
  "config_version": "1.0",
  "vcs": {
    "owner": "test",
    "repo": "repo"
  }
}
EOF

  run "$VALIDATOR" --tier structure "${TEST_DIR}/config.json"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "provider" ]]
}

@test "Tier 1: Invalid config_version format fails" {
  cat > "${TEST_DIR}/config.json" <<'EOF'
{
  "config_version": "v1.0.0",
  "vcs": {
    "provider": "github",
    "owner": "test",
    "repo": "repo"
  }
}
EOF

  run "$VALIDATOR" --tier structure "${TEST_DIR}/config.json"
  [ "$status" -eq 1 ]
}

@test "Tier 1: Invalid work_tracker.provider enum fails" {
  cat > "${TEST_DIR}/config.json" <<'EOF'
{
  "config_version": "1.0",
  "vcs": {
    "provider": "github",
    "owner": "test",
    "repo": "repo"
  },
  "work_tracker": {
    "provider": "trello"
  }
}
EOF

  run "$VALIDATOR" --tier structure "${TEST_DIR}/config.json"
  [ "$status" -eq 1 ]
}

@test "Tier 1: Invalid review_strategy enum fails" {
  cat > "${TEST_DIR}/config.json" <<'EOF'
{
  "config_version": "1.0",
  "vcs": {
    "provider": "github",
    "owner": "test",
    "repo": "repo"
  },
  "team": {
    "review_strategy": "random"
  }
}
EOF

  run "$VALIDATOR" --tier structure "${TEST_DIR}/config.json"
  [ "$status" -eq 1 ]
}

@test "Tier 1: Invalid team member role enum fails" {
  cat > "${TEST_DIR}/config.json" <<'EOF'
{
  "config_version": "1.0",
  "vcs": {
    "provider": "github",
    "owner": "test",
    "repo": "repo"
  },
  "team": {
    "members": [
      {
        "username": "alice",
        "role": "manager"
      }
    ]
  }
}
EOF

  run "$VALIDATOR" --tier structure "${TEST_DIR}/config.json"
  [ "$status" -eq 1 ]
}

@test "Tier 1: Invalid availability enum fails" {
  cat > "${TEST_DIR}/config.json" <<'EOF'
{
  "config_version": "1.0",
  "vcs": {
    "provider": "github",
    "owner": "test",
    "repo": "repo"
  },
  "team": {
    "members": [
      {
        "username": "alice",
        "role": "developer",
        "availability": "sometimes"
      }
    ]
  }
}
EOF

  run "$VALIDATOR" --tier structure "${TEST_DIR}/config.json"
  [ "$status" -eq 1 ]
}

@test "Tier 1: Wrong type for auto_commit fails" {
  cat > "${TEST_DIR}/config.json" <<'EOF'
{
  "config_version": "1.0",
  "vcs": {
    "provider": "github",
    "owner": "test",
    "repo": "repo"
  },
  "workflow": {
    "commit": {
      "auto_commit": "yes"
    }
  }
}
EOF

  run "$VALIDATOR" --tier structure "${TEST_DIR}/config.json"
  [ "$status" -eq 1 ]
}

@test "Tier 1: Invalid owner pattern fails" {
  cat > "${TEST_DIR}/config.json" <<'EOF'
{
  "config_version": "1.0",
  "vcs": {
    "provider": "github",
    "owner": "-invalid-start",
    "repo": "repo"
  }
}
EOF

  run "$VALIDATOR" --tier structure "${TEST_DIR}/config.json"
  [ "$status" -eq 1 ]
}

@test "Tier 1: Invalid repo pattern fails" {
  cat > "${TEST_DIR}/config.json" <<'EOF'
{
  "config_version": "1.0",
  "vcs": {
    "provider": "github",
    "owner": "test",
    "repo": "-invalid"
  }
}
EOF

  run "$VALIDATOR" --tier structure "${TEST_DIR}/config.json"
  [ "$status" -eq 1 ]
}

@test "Tier 1: Invalid enterprise_url pattern (HTTP) fails" {
  cat > "${TEST_DIR}/config.json" <<'EOF'
{
  "config_version": "1.0",
  "vcs": {
    "provider": "github",
    "owner": "test",
    "repo": "repo",
    "github": {
      "enterprise_url": "http://github.company.com"
    }
  }
}
EOF

  run "$VALIDATOR" --tier structure "${TEST_DIR}/config.json"
  [ "$status" -eq 1 ]
}

@test "Tier 1: Invalid self_hosted_url pattern (HTTP) fails" {
  cat > "${TEST_DIR}/config.json" <<'EOF'
{
  "config_version": "1.0",
  "vcs": {
    "provider": "gitlab",
    "owner": "test",
    "repo": "repo",
    "gitlab": {
      "project_id": "12345",
      "self_hosted_url": "http://gitlab.company.com"
    }
  }
}
EOF

  run "$VALIDATOR" --tier structure "${TEST_DIR}/config.json"
  [ "$status" -eq 1 ]
}

@test "Tier 1: Invalid Jira base_url pattern (HTTP) fails" {
  cat > "${TEST_DIR}/config.json" <<'EOF'
{
  "config_version": "1.0",
  "vcs": {
    "provider": "github",
    "owner": "test",
    "repo": "repo"
  },
  "work_tracker": {
    "provider": "jira",
    "jira": {
      "base_url": "http://company.atlassian.net",
      "project_key": "PROJ"
    }
  }
}
EOF

  run "$VALIDATOR" --tier structure "${TEST_DIR}/config.json"
  [ "$status" -eq 1 ]
}

@test "Tier 1: Invalid project_key pattern (lowercase) fails" {
  cat > "${TEST_DIR}/config.json" <<'EOF'
{
  "config_version": "1.0",
  "vcs": {
    "provider": "github",
    "owner": "test",
    "repo": "repo"
  },
  "work_tracker": {
    "provider": "jira",
    "jira": {
      "base_url": "https://company.atlassian.net",
      "project_key": "lowercase"
    }
  }
}
EOF

  run "$VALIDATOR" --tier structure "${TEST_DIR}/config.json"
  [ "$status" -eq 1 ]
}

@test "Tier 1: Invalid Linear team_id pattern (not UUID) fails" {
  cat > "${TEST_DIR}/config.json" <<'EOF'
{
  "config_version": "1.0",
  "vcs": {
    "provider": "github",
    "owner": "test",
    "repo": "repo"
  },
  "work_tracker": {
    "provider": "linear",
    "linear": {
      "team_id": "not-a-uuid",
      "board_id": "987fcdeb-51a2-43f1-9876-543210fedcba"
    }
  }
}
EOF

  run "$VALIDATOR" --tier structure "${TEST_DIR}/config.json"
  [ "$status" -eq 1 ]
}

@test "Tier 1: Additional properties not allowed" {
  cat > "${TEST_DIR}/config.json" <<'EOF'
{
  "config_version": "1.0",
  "vcs": {
    "provider": "github",
    "owner": "test",
    "repo": "repo"
  },
  "unknown_field": "value"
}
EOF

  run "$VALIDATOR" --tier structure "${TEST_DIR}/config.json"
  [ "$status" -eq 1 ]
}

################################################################################
# TIER 2: PROVIDER RULES VALIDATION TESTS (30+ tests)
################################################################################

# GitHub Provider Tests (6 tests)

@test "Tier 2: GitHub with all fields passes" {
  run "$VALIDATOR" --tier provider "${FIXTURES}/valid/github-enterprise.json"
  [ "$status" -eq 0 ]
}

@test "Tier 2: GitHub missing owner fails" {
  run "$VALIDATOR" --tier provider "${FIXTURES}/invalid-provider-rules/github-missing-owner.json"
  [ "$status" -eq 2 ]
  [[ "$output" =~ "owner" ]]
}

@test "Tier 2: GitHub missing repo fails" {
  run "$VALIDATOR" --tier provider "${FIXTURES}/invalid-provider-rules/github-missing-repo.json"
  [ "$status" -eq 2 ]
  [[ "$output" =~ "repo" ]]
}

@test "Tier 2: GitHub enterprise_url HTTP not HTTPS fails" {
  run "$VALIDATOR" --tier provider "${FIXTURES}/invalid-provider-rules/github-http-enterprise.json"
  [ "$status" -eq 2 ]
  [[ "$output" =~ "HTTPS" ]]
}

@test "Tier 2: GitHub without enterprise_url passes" {
  run "$VALIDATOR" --tier provider "${FIXTURES}/valid/github-simple.json"
  [ "$status" -eq 0 ]
}

@test "Tier 2: GitHub with valid HTTPS enterprise_url passes" {
  run "$VALIDATOR" --tier provider "${FIXTURES}/valid/github-enterprise.json"
  [ "$status" -eq 0 ]
}

# GitLab Provider Tests (8 tests)

@test "Tier 2: GitLab with all fields passes" {
  run "$VALIDATOR" --tier provider "${FIXTURES}/valid/gitlab-jira.json"
  [ "$status" -eq 0 ]
}

@test "Tier 2: GitLab missing owner fails" {
  cat > "${TEST_DIR}/config.json" <<'EOF'
{
  "config_version": "1.0",
  "vcs": {
    "provider": "gitlab",
    "repo": "repo",
    "gitlab": {
      "project_id": "12345"
    }
  }
}
EOF

  run "$VALIDATOR" --tier provider "${TEST_DIR}/config.json"
  [ "$status" -eq 2 ]
  [[ "$output" =~ "owner" ]]
}

@test "Tier 2: GitLab missing repo fails" {
  cat > "${TEST_DIR}/config.json" <<'EOF'
{
  "config_version": "1.0",
  "vcs": {
    "provider": "gitlab",
    "owner": "test",
    "gitlab": {
      "project_id": "12345"
    }
  }
}
EOF

  run "$VALIDATOR" --tier provider "${TEST_DIR}/config.json"
  [ "$status" -eq 2 ]
  [[ "$output" =~ "repo" ]]
}

@test "Tier 2: GitLab missing project_id fails" {
  run "$VALIDATOR" --tier provider "${FIXTURES}/invalid-provider-rules/gitlab-missing-project-id.json"
  [ "$status" -eq 2 ]
  [[ "$output" =~ "project_id" ]]
}

@test "Tier 2: GitLab invalid project_id format fails" {
  run "$VALIDATOR" --tier provider "${FIXTURES}/invalid-provider-rules/gitlab-invalid-project-id.json"
  [ "$status" -eq 2 ]
  [[ "$output" =~ "invalid format" ]]
}

@test "Tier 2: GitLab self_hosted_url HTTP not HTTPS fails" {
  run "$VALIDATOR" --tier provider "${FIXTURES}/invalid-provider-rules/gitlab-http-self-hosted.json"
  [ "$status" -eq 2 ]
  [[ "$output" =~ "HTTPS" ]]
}

@test "Tier 2: GitLab with numeric project_id passes" {
  run "$VALIDATOR" --tier provider "${FIXTURES}/valid/gitlab-simple.json"
  [ "$status" -eq 0 ]
}

@test "Tier 2: GitLab with path format project_id passes" {
  run "$VALIDATOR" --tier provider "${FIXTURES}/valid/gitlab-jira.json"
  [ "$status" -eq 0 ]
}

# Bitbucket Provider Tests (4 tests)

@test "Tier 2: Bitbucket with workspace and repo_slug passes" {
  run "$VALIDATOR" --tier provider "${FIXTURES}/valid/bitbucket-simple.json"
  [ "$status" -eq 0 ]
}

@test "Tier 2: Bitbucket missing workspace fails" {
  run "$VALIDATOR" --tier provider "${FIXTURES}/invalid-provider-rules/bitbucket-missing-workspace.json"
  [ "$status" -eq 2 ]
  [[ "$output" =~ "workspace" ]]
}

@test "Tier 2: Bitbucket missing repo_slug fails" {
  cat > "${TEST_DIR}/config.json" <<'EOF'
{
  "config_version": "1.0",
  "vcs": {
    "provider": "bitbucket",
    "bitbucket": {
      "workspace": "my-workspace"
    }
  }
}
EOF

  run "$VALIDATOR" --tier provider "${TEST_DIR}/config.json"
  [ "$status" -eq 2 ]
  [[ "$output" =~ "repo_slug" ]]
}

@test "Tier 2: Bitbucket invalid repo_slug format (uppercase) fails" {
  run "$VALIDATOR" --tier provider "${FIXTURES}/invalid-provider-rules/bitbucket-invalid-repo-slug.json"
  [ "$status" -eq 2 ]
  [[ "$output" =~ "invalid format" ]]
}

# Jira Provider Tests (6 tests)

@test "Tier 2: Jira with base_url and project_key passes" {
  run "$VALIDATOR" --tier provider "${FIXTURES}/valid/gitlab-jira.json"
  [ "$status" -eq 0 ]
}

@test "Tier 2: Jira missing base_url fails" {
  run "$VALIDATOR" --tier provider "${FIXTURES}/invalid-provider-rules/jira-missing-base-url.json"
  [ "$status" -eq 2 ]
  [[ "$output" =~ "base_url" ]]
}

@test "Tier 2: Jira missing project_key fails" {
  cat > "${TEST_DIR}/config.json" <<'EOF'
{
  "config_version": "1.0",
  "vcs": {
    "provider": "github",
    "owner": "test",
    "repo": "repo"
  },
  "work_tracker": {
    "provider": "jira",
    "jira": {
      "base_url": "https://company.atlassian.net"
    }
  }
}
EOF

  run "$VALIDATOR" --tier provider "${TEST_DIR}/config.json"
  [ "$status" -eq 2 ]
  [[ "$output" =~ "project_key" ]]
}

@test "Tier 2: Jira base_url HTTP not HTTPS fails" {
  run "$VALIDATOR" --tier provider "${FIXTURES}/invalid-provider-rules/jira-http-base-url.json"
  [ "$status" -eq 2 ]
  [[ "$output" =~ "HTTPS" ]]
}

@test "Tier 2: Jira project_key lowercase fails" {
  run "$VALIDATOR" --tier provider "${FIXTURES}/invalid-provider-rules/jira-invalid-project-key.json"
  [ "$status" -eq 2 ]
  [[ "$output" =~ "invalid format" ]]
}

@test "Tier 2: Jira project_key too long (>10 chars) fails" {
  run "$VALIDATOR" --tier provider "${FIXTURES}/invalid-provider-rules/jira-project-key-too-long.json"
  [ "$status" -eq 2 ]
  [[ "$output" =~ "invalid format" ]]
}

# Linear Provider Tests (6 tests)

@test "Tier 2: Linear with team_id and board_id (UUIDs) passes" {
  run "$VALIDATOR" --tier provider "${FIXTURES}/valid/linear-work-tracker.json"
  [ "$status" -eq 0 ]
}

@test "Tier 2: Linear missing team_id fails" {
  run "$VALIDATOR" --tier provider "${FIXTURES}/invalid-provider-rules/linear-missing-team-id.json"
  [ "$status" -eq 2 ]
  [[ "$output" =~ "team_id" ]]
}

@test "Tier 2: Linear missing board_id fails" {
  cat > "${TEST_DIR}/config.json" <<'EOF'
{
  "config_version": "1.0",
  "vcs": {
    "provider": "github",
    "owner": "test",
    "repo": "repo"
  },
  "work_tracker": {
    "provider": "linear",
    "linear": {
      "team_id": "123e4567-e89b-12d3-a456-426614174000"
    }
  }
}
EOF

  run "$VALIDATOR" --tier provider "${TEST_DIR}/config.json"
  [ "$status" -eq 2 ]
  [[ "$output" =~ "board_id" ]]
}

@test "Tier 2: Linear invalid team_id (not UUID) fails" {
  run "$VALIDATOR" --tier provider "${FIXTURES}/invalid-provider-rules/linear-invalid-uuid.json"
  [ "$status" -eq 2 ]
  [[ "$output" =~ "invalid UUID format" ]]
}

@test "Tier 2: Linear invalid board_id (not UUID) fails" {
  cat > "${TEST_DIR}/config.json" <<'EOF'
{
  "config_version": "1.0",
  "vcs": {
    "provider": "github",
    "owner": "test",
    "repo": "repo"
  },
  "work_tracker": {
    "provider": "linear",
    "linear": {
      "team_id": "123e4567-e89b-12d3-a456-426614174000",
      "board_id": "not-a-uuid"
    }
  }
}
EOF

  run "$VALIDATOR" --tier provider "${TEST_DIR}/config.json"
  [ "$status" -eq 2 ]
  [[ "$output" =~ "invalid UUID format" ]]
}

@test "Tier 2: Linear malformed UUIDs fail" {
  cat > "${TEST_DIR}/config.json" <<'EOF'
{
  "config_version": "1.0",
  "vcs": {
    "provider": "github",
    "owner": "test",
    "repo": "repo"
  },
  "work_tracker": {
    "provider": "linear",
    "linear": {
      "team_id": "123e4567-e89b-12d3-a456",
      "board_id": "987fcdeb-51a2-43f1-9876-543210fedcba"
    }
  }
}
EOF

  run "$VALIDATOR" --tier provider "${TEST_DIR}/config.json"
  [ "$status" -eq 2 ]
}

################################################################################
# TIER 3: CONNECTIVITY STUB TESTS (5+ tests)
################################################################################

@test "Tier 3: Default behavior skips connectivity check" {
  run "$VALIDATOR" --verbose --tier connectivity "${FIXTURES}/valid/github-simple.json"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "skipped" ]]
}

@test "Tier 3: With --verify-connection flag shows stub" {
  run "$VALIDATOR" --tier connectivity --verify-connection "${FIXTURES}/valid/github-simple.json"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "NOT YET IMPLEMENTED" ]]
}

@test "Tier 3: Stub returns exit code 0 (doesn't fail)" {
  run "$VALIDATOR" --tier connectivity --verify-connection "${FIXTURES}/valid/github-simple.json"
  [ "$status" -eq 0 ]
}

@test "Tier 3: Stub output mentions provider" {
  run "$VALIDATOR" --tier connectivity --verify-connection "${FIXTURES}/valid/gitlab-simple.json"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "gitlab" ]]
}

@test "Tier 3: Verbose mode shows skip message" {
  run "$VALIDATOR" --verbose --tier connectivity "${FIXTURES}/valid/github-simple.json"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "skipped" ]]
}

@test "Tier 3: Stub shows planned tests for GitHub" {
  run "$VALIDATOR" --tier connectivity --verify-connection "${FIXTURES}/valid/github-simple.json"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Planned Tests" ]]
  [[ "$output" =~ "API Connection" ]]
}

@test "Tier 3: Stub shows planned tests for Jira" {
  run "$VALIDATOR" --tier connectivity --verify-connection "${FIXTURES}/valid/gitlab-jira.json"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Jira" ]]
  [[ "$output" =~ "Planned Tests" ]]
}

################################################################################
# ERROR MESSAGE TESTS (10+ tests)
################################################################################

@test "Error Messages: GitHub error shows fix suggestion" {
  run "$VALIDATOR" --tier provider "${FIXTURES}/invalid-provider-rules/github-missing-owner.json"
  [ "$status" -eq 2 ]
  [[ "$output" =~ "Quick fix" ]] || [[ "$output" =~ "Manual configuration" ]]
}

@test "Error Messages: GitLab error shows fix suggestion" {
  run "$VALIDATOR" --tier provider "${FIXTURES}/invalid-provider-rules/gitlab-missing-project-id.json"
  [ "$status" -eq 2 ]
  [[ "$output" =~ "Quick fix" ]] || [[ "$output" =~ "Manual configuration" ]]
}

@test "Error Messages: Bitbucket error shows fix suggestion" {
  run "$VALIDATOR" --tier provider "${FIXTURES}/invalid-provider-rules/bitbucket-missing-workspace.json"
  [ "$status" -eq 2 ]
  [[ "$output" =~ "Quick fix" ]] || [[ "$output" =~ "Manual configuration" ]]
}

@test "Error Messages: Jira error shows fix suggestion" {
  run "$VALIDATOR" --tier provider "${FIXTURES}/invalid-provider-rules/jira-missing-base-url.json"
  [ "$status" -eq 2 ]
  [[ "$output" =~ "Manual configuration" ]]
}

@test "Error Messages: Linear error shows fix suggestion" {
  run "$VALIDATOR" --tier provider "${FIXTURES}/invalid-provider-rules/linear-missing-team-id.json"
  [ "$status" -eq 2 ]
  [[ "$output" =~ "Manual configuration" ]]
}

@test "Error Messages: Error includes location ($.path)" {
  run "$VALIDATOR" --tier provider "${FIXTURES}/invalid-provider-rules/github-missing-owner.json"
  [ "$status" -eq 2 ]
  [[ "$output" =~ "Location:" ]]
}

@test "Error Messages: Error includes expected format" {
  run "$VALIDATOR" --tier provider "${FIXTURES}/invalid-provider-rules/gitlab-invalid-project-id.json"
  [ "$status" -eq 2 ]
  [[ "$output" =~ "Expected format:" ]]
}

@test "Error Messages: Multiple errors shown together" {
  cat > "${TEST_DIR}/config.json" <<'EOF'
{
  "config_version": "1.0",
  "vcs": {
    "provider": "github"
  }
}
EOF

  run "$VALIDATOR" --tier provider "${TEST_DIR}/config.json"
  [ "$status" -eq 2 ]
  [[ "$output" =~ "owner" ]]
  [[ "$output" =~ "repo" ]]
}

@test "Error Messages: Documentation link included" {
  run "$VALIDATOR" --tier structure "${FIXTURES}/invalid-structure/missing-config-version.json"
  [ "$status" -eq 1 ]
  [[ "$output" =~ docs/configuration/schema-reference.md ]]
}

@test "Error Messages: Exit code 1 for structure errors" {
  run "$VALIDATOR" --tier structure "${FIXTURES}/invalid-structure/missing-config-version.json"
  [ "$status" -eq 1 ]
}

@test "Error Messages: Exit code 2 for provider errors" {
  run "$VALIDATOR" --tier provider "${FIXTURES}/invalid-provider-rules/github-missing-owner.json"
  [ "$status" -eq 2 ]
}

################################################################################
# EDGE CASES TESTS (10+ tests)
################################################################################

@test "Edge Cases: Empty config file fails" {
  run "$VALIDATOR" --tier structure "${FIXTURES}/invalid-provider-rules/empty-config.json"
  [ "$status" -eq 1 ]
}

@test "Edge Cases: Config with only config_version passes structure" {
  cat > "${TEST_DIR}/config.json" <<'EOF'
{
  "config_version": "1.0"
}
EOF

  run "$VALIDATOR" --tier structure "${TEST_DIR}/config.json"
  [ "$status" -eq 0 ]
}

@test "Edge Cases: Null values in optional fields accepted" {
  cat > "${TEST_DIR}/config.json" <<'EOF'
{
  "config_version": "1.0",
  "vcs": {
    "provider": "github",
    "owner": "test",
    "repo": "repo",
    "github": {
      "enterprise_url": null
    }
  }
}
EOF

  run "$VALIDATOR" --tier structure "${TEST_DIR}/config.json"
  [ "$status" -eq 0 ]
}

@test "Edge Cases: Cross-provider GitLab VCS + GitHub Issues passes" {
  cat > "${TEST_DIR}/config.json" <<'EOF'
{
  "config_version": "1.0",
  "vcs": {
    "provider": "gitlab",
    "owner": "test",
    "repo": "repo",
    "gitlab": {
      "project_id": "12345"
    }
  },
  "work_tracker": {
    "provider": "github_issues"
  }
}
EOF

  run "$VALIDATOR" --tier all "${TEST_DIR}/config.json"
  [ "$status" -eq 0 ]
}

@test "Edge Cases: Cross-provider Bitbucket VCS + Jira passes" {
  cat > "${TEST_DIR}/config.json" <<'EOF'
{
  "config_version": "1.0",
  "vcs": {
    "provider": "bitbucket",
    "bitbucket": {
      "workspace": "my-workspace",
      "repo_slug": "my-project"
    }
  },
  "work_tracker": {
    "provider": "jira",
    "jira": {
      "base_url": "https://company.atlassian.net",
      "project_key": "PROJ"
    }
  }
}
EOF

  run "$VALIDATOR" --tier all "${TEST_DIR}/config.json"
  [ "$status" -eq 0 ]
}

@test "Edge Cases: Multiple validation errors at once" {
  cat > "${TEST_DIR}/config.json" <<'EOF'
{
  "config_version": "1.0",
  "vcs": {
    "provider": "github"
  },
  "work_tracker": {
    "provider": "jira",
    "jira": {}
  }
}
EOF

  run "$VALIDATOR" --tier provider "${TEST_DIR}/config.json"
  [ "$status" -eq 2 ]
  # Should have errors for: GitHub owner, repo, Jira base_url, project_key
  [[ "$output" =~ "owner" ]]
  [[ "$output" =~ "base_url" ]]
}

@test "Edge Cases: File not found returns exit code 3" {
  run "$VALIDATOR" --tier structure "/nonexistent/config.json"
  [ "$status" -eq 3 ]
  [[ "$output" =~ "File not found" ]]
}

@test "Edge Cases: Unicode values in strings rejected by pattern" {
  cat > "${TEST_DIR}/config.json" <<'EOF'
{
  "config_version": "1.0",
  "vcs": {
    "provider": "github",
    "owner": "test",
    "repo": "repo-with-émoji"
  }
}
EOF

  # Unicode characters in repo names don't match the pattern
  run "$VALIDATOR" --tier structure "${TEST_DIR}/config.json"
  [ "$status" -eq 1 ]
}

@test "Edge Cases: work_tracker.provider none passes" {
  cat > "${TEST_DIR}/config.json" <<'EOF'
{
  "config_version": "1.0",
  "vcs": {
    "provider": "github",
    "owner": "test",
    "repo": "repo"
  },
  "work_tracker": {
    "provider": "none"
  }
}
EOF

  run "$VALIDATOR" --tier all "${TEST_DIR}/config.json"
  [ "$status" -eq 0 ]
}

@test "Edge Cases: All tiers run sequentially with 'all' tier" {
  run "$VALIDATOR" --tier all "${FIXTURES}/valid/complete.json"
  [ "$status" -eq 0 ]
}

################################################################################
# COMMAND-LINE INTERFACE TESTS
################################################################################

@test "CLI: --help shows usage" {
  run "$VALIDATOR" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Usage:" ]]
}

@test "CLI: --verbose enables verbose output" {
  run "$VALIDATOR" --verbose --tier structure "${FIXTURES}/valid/github-simple.json"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Tier 1" ]]
}

@test "CLI: --tier structure validates only structure" {
  run "$VALIDATOR" --tier structure "${FIXTURES}/valid/github-simple.json"
  [ "$status" -eq 0 ]
}

@test "CLI: --tier provider validates only provider rules" {
  run "$VALIDATOR" --tier provider "${FIXTURES}/valid/github-simple.json"
  [ "$status" -eq 0 ]
}

@test "CLI: --tier connectivity validates only connectivity" {
  run "$VALIDATOR" --tier connectivity "${FIXTURES}/valid/github-simple.json"
  [ "$status" -eq 0 ]
}

@test "CLI: Invalid tier shows error" {
  run "$VALIDATOR" --tier invalid "${FIXTURES}/valid/github-simple.json"
  [ "$status" -eq 3 ]
  [[ "$output" =~ "Unknown tier" ]]
}

@test "CLI: Missing config file argument shows error" {
  run "$VALIDATOR" --tier structure
  [ "$status" -eq 2 ]
  [[ "$output" =~ "No config file specified" ]]
}

@test "CLI: Multiple config files shows error" {
  run "$VALIDATOR" "${FIXTURES}/valid/github-simple.json" "${FIXTURES}/valid/gitlab-simple.json"
  [ "$status" -eq 2 ]
  [[ "$output" =~ "Multiple config files" ]]
}

@test "CLI: Unknown option shows error" {
  run "$VALIDATOR" --unknown-option "${FIXTURES}/valid/github-simple.json"
  [ "$status" -eq 2 ]
  [[ "$output" =~ "Unknown option" ]]
}

@test "CLI: Success message shown for valid config" {
  run "$VALIDATOR" "${FIXTURES}/valid/github-simple.json"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "valid" ]]
}
