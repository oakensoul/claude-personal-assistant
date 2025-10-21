# Test Fixtures for Configuration Validation

This directory contains JSON configuration fixtures used by the config-validator.sh unit tests.

## Directory Structure

```text
configs/
├── valid/                          # Valid configurations (7 files)
│   ├── github-simple.json          # Minimal GitHub config
│   ├── github-enterprise.json      # GitHub with enterprise URL
│   ├── gitlab-simple.json          # GitLab with numeric project_id
│   ├── gitlab-jira.json            # GitLab + Jira work tracker
│   ├── bitbucket-simple.json       # Bitbucket config
│   ├── linear-work-tracker.json    # Linear work tracker
│   └── complete.json               # Complete config with all options
│
├── invalid-structure/              # Schema/structure violations (4 files)
│   ├── missing-config-version.json # Missing required config_version
│   ├── invalid-json.json           # Invalid JSON syntax
│   ├── invalid-provider.json       # Invalid VCS provider enum
│   └── wrong-types.json            # Wrong data types
│
└── invalid-provider-rules/         # Provider rule violations (15 files)
    ├── github-missing-owner.json
    ├── github-missing-repo.json
    ├── github-http-enterprise.json
    ├── gitlab-missing-project-id.json
    ├── gitlab-invalid-project-id.json
    ├── gitlab-http-self-hosted.json
    ├── bitbucket-missing-workspace.json
    ├── bitbucket-invalid-repo-slug.json
    ├── jira-missing-base-url.json
    ├── jira-http-base-url.json
    ├── jira-invalid-project-key.json
    ├── jira-project-key-too-long.json
    ├── linear-missing-team-id.json
    ├── linear-invalid-uuid.json
    └── empty-config.json
```

## Usage

These fixtures are used by `tests/unit/test_config_validation.bats`:

```bash
# Run all validation tests
bats tests/unit/test_config_validation.bats

# Run specific tier tests
bats --filter "Tier 1" tests/unit/test_config_validation.bats
bats --filter "Tier 2" tests/unit/test_config_validation.bats
bats --filter "Tier 3" tests/unit/test_config_validation.bats
```

## Valid Fixtures

### GitHub Configs

**github-simple.json** - Minimal GitHub configuration:

```json
{
  "config_version": "1.0",
  "vcs": {
    "provider": "github",
    "owner": "oakensoul",
    "repo": "test-repo"
  }
}
```

**github-enterprise.json** - GitHub Enterprise configuration:

```json
{
  "config_version": "1.0",
  "vcs": {
    "provider": "github",
    "owner": "company",
    "repo": "enterprise-repo",
    "github": {
      "enterprise_url": "https://github.company.com"
    }
  }
}
```

### GitLab Configs

**gitlab-simple.json** - GitLab with numeric project_id:

```json
{
  "config_version": "1.0",
  "vcs": {
    "provider": "gitlab",
    "owner": "mygroup",
    "repo": "myproject",
    "gitlab": {
      "project_id": "12345"
    }
  }
}
```

**gitlab-jira.json** - GitLab + Jira work tracker:

```json
{
  "config_version": "1.0",
  "vcs": {
    "provider": "gitlab",
    "owner": "mygroup",
    "repo": "myproject",
    "gitlab": {
      "project_id": "my-group/my-project",
      "self_hosted_url": "https://gitlab.company.com"
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
```

### Bitbucket Configs

**bitbucket-simple.json** - Bitbucket configuration:

```json
{
  "config_version": "1.0",
  "vcs": {
    "provider": "bitbucket",
    "bitbucket": {
      "workspace": "my-workspace",
      "repo_slug": "my-project"
    }
  }
}
```

### Work Tracker Configs

**linear-work-tracker.json** - Linear work tracker:

```json
{
  "config_version": "1.0",
  "vcs": {
    "provider": "github",
    "owner": "oakensoul",
    "repo": "test-repo"
  },
  "work_tracker": {
    "provider": "linear",
    "linear": {
      "team_id": "123e4567-e89b-12d3-a456-426614174000",
      "board_id": "987fcdeb-51a2-43f1-9876-543210fedcba"
    }
  }
}
```

### Complete Config

**complete.json** - Full configuration with all options:

- VCS: GitHub with main_branch and auto_detect
- Work Tracker: GitHub Issues
- Team: Review strategy, default reviewers, members
- Workflow: Commit and PR automation settings

## Invalid Fixtures

### Structure Violations (Tier 1)

These fixtures fail JSON Schema validation:

- **missing-config-version.json** - Missing required `config_version` field
- **invalid-json.json** - Invalid JSON syntax (missing commas)
- **invalid-provider.json** - Invalid VCS provider enum value ("svn")
- **wrong-types.json** - Wrong data type (string instead of array)

### Provider Rule Violations (Tier 2)

These fixtures pass schema validation but fail provider-specific rules:

**GitHub**:

- **github-missing-owner.json** - Missing required `vcs.owner`
- **github-missing-repo.json** - Missing required `vcs.repo`
- **github-http-enterprise.json** - Enterprise URL uses HTTP not HTTPS

**GitLab**:

- **gitlab-missing-project-id.json** - Missing required `gitlab.project_id`
- **gitlab-invalid-project-id.json** - Invalid project_id format
- **gitlab-http-self-hosted.json** - Self-hosted URL uses HTTP not HTTPS

**Bitbucket**:

- **bitbucket-missing-workspace.json** - Missing required `workspace`
- **bitbucket-invalid-repo-slug.json** - Invalid repo_slug format (uppercase)

**Jira**:

- **jira-missing-base-url.json** - Missing required `base_url`
- **jira-http-base-url.json** - Base URL uses HTTP not HTTPS
- **jira-invalid-project-key.json** - Invalid project_key format (lowercase)
- **jira-project-key-too-long.json** - Project key exceeds 10 characters

**Linear**:

- **linear-missing-team-id.json** - Missing required `team_id`
- **linear-invalid-uuid.json** - Invalid UUID format for team_id

**Other**:

- **empty-config.json** - Empty JSON object

## Test Coverage

These fixtures provide comprehensive test coverage for:

- **26 Tier 1 tests** - Structure validation (schema, types, patterns)
- **30 Tier 2 tests** - Provider rules validation (all 5 providers)
- **7 Tier 3 tests** - Connectivity stub behavior
- **11 Error Message tests** - Error formatting and suggestions
- **10 Edge Case tests** - Cross-provider configs, null values, unicode
- **10 CLI tests** - Command-line interface and options

### Test Summary

Total: 94 test cases with 100% pass rate

## Maintenance

When adding new validation rules:

1. Add valid fixture to `valid/` directory
2. Add invalid fixture to appropriate subdirectory
3. Add corresponding test case to `test_config_validation.bats`
4. Update this README with fixture description

## Related Files

- Test suite: `tests/unit/test_config_validation.bats`
- Validator: `lib/installer-common/config-validator.sh`
- Schema: `lib/installer-common/config-schema.json`
- Documentation: `docs/configuration/schema-reference.md`
