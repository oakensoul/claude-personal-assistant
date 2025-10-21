---
title: "Product Requirements Document - Configuration System (#55)"
issue: 55
status: "draft"
created: "2025-10-20"
category: "infrastructure"
---

# PRD: Configuration System with VCS Abstraction

## Executive Summary

**What**: A robust configuration system with `.claude/config.json` schema that supports VCS provider auto-detection (GitHub, GitLab, Bitbucket), hierarchical configuration (user + project), and work tracker integration.

**Why**: Current hardcoded GitHub-specific configuration blocks multi-provider teams and limits extensibility. This creates a foundation for Jira/GitLab integration while maintaining clean separation between infrastructure (Issue #55) and user-facing setup (Issue #56).

**Approach**: JSON-based configuration with auto-detection from git remotes, schema validation, hierarchical merging (user → project → environment), and provider-specific validation. Clean slate design (no backward compatibility with `github.*` namespace).

## Stakeholder Analysis

### Developers Using AIDA

**Key Concerns**:

- **Configuration complexity** - Don't want to manually configure every field
- **Discovery** - How to know what config options exist
- **Validation feedback** - Clear errors when config is wrong
- **Migration path** - Existing `github.*` configs need seamless upgrade

**Priorities**:

1. Auto-detection works for 95%+ of cases (silent success)
2. Error messages are actionable with fix suggestions
3. No manual JSON editing required for common tasks
4. Team config can be safely committed to git (no secrets)

**Recommendations**:

- Provide auto-detection with transparent feedback (verbose mode)
- Create interactive setup wizard (`/aida-init` in Issue #56)
- Auto-migration for existing configs with backup
- CLI-based config editing (`--set`, `--unset` flags)

### Future Contributors

**Key Concerns**:

- **Extensibility** - Can I add a custom VCS provider (Gitea, Codeberg)?
- **Maintainability** - How complex is adding new provider support?
- **Documentation** - Provider abstraction patterns clearly documented?

**Priorities**:

1. Provider plugin architecture documented
2. JSON Schema as single source of truth
3. Adding new provider takes < 2 hours
4. Provider-specific validation is isolated

**Recommendations**:

- Create provider interface specification (`lib/vcs-providers/base-provider.sh`)
- Document plugin system (`docs/integration/vcs-provider-plugins.md`)
- Provide custom provider template for extensions
- Namespace isolation prevents cross-provider contamination

### Multi-Provider Teams

**Key Concerns**:

- **Per-project providers** - GitHub for open source, GitLab for internal
- **Team defaults** - Share config patterns without secrets
- **Environment parity** - Dev/staging/prod with different providers

**Priorities**:

1. Project-level config overrides user defaults
2. Config hierarchy clearly documented
3. Team config safely committed (no secrets)
4. Provider switching is transparent

**Recommendations**:

- User config (`~/.claude/config.json`) - personal, 600 permissions, NOT committed
- Project config (`.aida/config.json`) - team, 644 permissions, committed to git
- Auto-detection confirms provider matches git remote
- Clear separation: config = metadata, env vars = secrets

## Requirements

### Functional Requirements

#### FR1: Configuration Schema

- JSON format (`.claude/config.json`, `.aida/config.json`)
- Namespaces: `vcs.*`, `work_tracker.*`, `team.*`, `workflow.*`
- Schema version field (`config_version: "1.0"`) for future migrations
- Provider-specific sections: `vcs.github.*`, `vcs.gitlab.*`, `vcs.bitbucket.*`

#### FR2: Auto-Detection

- Parse git remote URL to detect provider (github.com → github)
- Extract owner/repo from remote URL
- Detect main branch from git symbolic-ref
- Confidence levels: high (exact match), medium (pattern match), low (guess)
- Metadata tracking: detection method, timestamp, confidence

#### FR3: Hierarchical Configuration Loading

- Load order: system → user → project → environment
- Deep merge with namespace-aware strategy
- Project overrides user, environment overrides all
- Array merge: union for `team.default_reviewers`
- Object merge: deep merge for provider-specific config

#### FR4: Validation

- **Tier 1 (Structure)**: JSON Schema validation (types, required fields, enums)
- **Tier 2 (Provider Rules)**: Provider-specific field validation (GitHub: owner+repo, GitLab: project_id, Jira: project_key format)
- **Tier 3 (Runtime)**: OPTIONAL connectivity validation with `--verify-connection` flag
- Exit codes: 0=valid, 1=structure error, 2=provider rules error, 3=connectivity error

#### FR5: Security Requirements

- **NEVER store secrets in config files** - API keys/tokens in environment variables only
- Pre-commit hook scans for secret patterns (ghp_*, api_key=, token=)
- File permissions: user config 600, project config 644
- Config files reference env var names, not values
- `.gitignore` includes `~/.claude/config.json` (user config NOT committed)

#### FR6: Provider Abstraction (Design Only)

- Document provider interface contract (detect, get_issue, create_pr)
- Required vs optional operations (labels, drafts, projects)
- Feature detection pattern (`provider_supports_feature("labels")`)
- Graceful degradation for optional features
- **Note**: Actual provider implementations deferred to Issues #56-59

#### FR7: Team Configuration

- Namespace: `team.*`
- Review strategy: `round-robin`, `list`, `query`, `none`
- Default reviewers list with usernames (GitHub handles, not emails)
- Team members with roles (developer, tech-lead, reviewer) and availability

#### FR8: Work Tracker Integration (Config Only)

- Namespace: `work_tracker.*`
- Provider types: `github_issues`, `jira`, `linear`, `none`
- Provider-specific config sections
- **Note**: Actual Jira/Linear integration in future issues

### Non-Functional Requirements

#### NFR1: Security (Privacy-Security-Auditor)

- Secret detection blocks commits (pre-commit hook)
- File permissions enforced by installer
- Token validation checks format, not existence in config
- Audit trail logs credential usage (not values)
- GDPR compliance: use usernames (public), avoid emails in committed config

#### NFR2: Usability (Shell-Systems-UX-Designer)

- Auto-detection is opt-out (runs by default)
- Verbose mode shows what was detected (`--verbose`)
- Error messages use progressive disclosure (what → why → how to fix)
- Provider-specific error templates with auto-detected values
- Schema discovery command (`--schema vcs`)

#### NFR3: Extensibility (Integration-Specialist)

- Plugin architecture for custom providers
- Provider detection extensible (custom remote patterns)
- Namespace isolation prevents breaking changes
- JSON Schema supports versioning (`config_version`)
- Adding new provider doesn't require command changes

#### NFR4: Performance

- Validation completes in < 1 second for typical configs
- Auto-detection doesn't block on network calls
- Config loading cached per shell session
- Deep merge optimized with jq native operators

## Success Criteria

**Issue #55 Complete When**:

1. ✅ JSON Schema created (`lib/installer-common/config-schema.json`)
2. ✅ Auto-detection function extracts provider/owner/repo from git remote
3. ✅ Validation enforces required fields per provider
4. ✅ Hierarchical loading merges user + project config
5. ✅ `aida-config-helper.sh` supports new namespaces (vcs, work_tracker, team)
6. ✅ Pre-commit hook detects secrets in config files
7. ✅ Migration script converts `github.*` → `vcs.github.*`
8. ✅ Template config files created with examples
9. ✅ Documentation: schema reference, provider patterns, security model

**User Validation**:

- Developer runs `aida-config-helper.sh --detect-vcs` and sees correct provider
- Config validation fails with actionable error for missing fields
- Auto-migration preserves existing workflow-config.json values
- Pre-commit hook blocks commit when secrets detected in config

## Open Questions

**Q1: Should we support YAML in addition to JSON?**

**Decision**: NO - JSON only. Rationale: Simpler parsing with `jq`, no additional dependencies, existing `aida-config-helper.sh` infrastructure. Accepted trade-off: Less human-friendly (no comments), but better for programmatic access.

**Q2: What validation rules for each provider type?**

**Answer**:

- **GitHub**: `owner`, `repo` (required); `enterprise_url`, `main_branch` (optional)
- **GitLab**: `project_id`, `owner`, `repo` (required); `group`, `self_hosted_url` (optional)
- **Bitbucket**: `workspace`, `repo_slug` (required)
- **Jira**: `base_url` (HTTPS), `project_key` (uppercase alphanumeric, max 10 chars) (required)
- **Linear**: `team_id`, `board_id` (UUID format) (required)

**Q3: How to handle missing/invalid config gracefully?**

**Answer**: Three-tier fallback:

1. **Auto-detect**: Try to infer from git remote, environment
2. **Prompt**: If interactive mode, ask user
3. **Fail gracefully**: If non-interactive, provide clear error + fix instructions

**Q4: Should auto-detection be opt-in or opt-out?**

**Answer**: Opt-out (runs by default). Most users want auto-detection convenience. Power users can disable with `vcs.auto_detect: false` in config.

**Q5: How to validate Jira project_key format or Linear UUIDs?**

**Answer**: Format validation only (regex patterns), NOT existence validation (no API calls during validation). Runtime connectivity validation is OPTIONAL with `--verify-connection` flag.

**Q6: Should config files be in .gitignore by default?**

**Answer**: PARTIAL

- User config (`~/.claude/config.json`): YES - personal, NOT committed
- Project config (`.aida/config.json`): NO - shared, committed to git
- Installer creates `.gitignore` entries automatically

**Q7: How to communicate auto-detection results to users?**

**Answer**: Multi-level verbosity:

- Default: Quiet success (`✓ Configuration valid`), loud failure (detailed errors)
- Verbose: Show detected values (`--verbose`)
- Debug: Full merge details (`--debug`)

**Q8: Should we support multiple VCS providers in single project?**

**Answer**: NO - one VCS provider per project. Rationale: Simpler mental model, unambiguous auto-detection. Edge case: multiple remotes (origin + upstream) → use primary remote (origin).

## Recommendations

### Recommended Approach

#### Phase 1: Foundation (Issue #55 - THIS ISSUE)

1. JSON Schema design with provider-specific validation rules
2. VCS auto-detection from git remote (GitHub, GitLab, Bitbucket patterns)
3. Hierarchical config loading (user + project merge with jq)
4. Basic validation (structure + required fields)
5. Template config files with documented examples
6. Pre-commit hook for secret detection
7. Migration script for `github.*` → `vcs.*` namespace

#### Phase 2: User-Facing Setup (Issue #56)

1. `/aida-init` command with interactive wizard
2. Auto-detection with user confirmation
3. CLI config editing (`--set`, `--set`, `--unset`)
4. Schema discovery (`--schema <namespace>`)

#### Phase 3: Provider Implementations (Issues #57-59)

1. Jira work tracker integration
2. GitLab VCS provider
3. Linear work tracker integration
4. Bitbucket VCS provider

### Prioritize in Issue #55

**MUST HAVE (Blocking)**:

- JSON Schema with provider validation rules
- Auto-detection function (git remote → provider/owner/repo)
- Hierarchical config loading and merging
- Secret detection pre-commit hook
- Migration script for existing configs
- Template config files

**SHOULD HAVE (High Priority)**:

- Provider-specific validation with clear errors
- Backup config before migration
- File permission enforcement (installer sets 600/644)
- Documentation: schema reference, security model

**DEFER to Issue #56**:

- Interactive wizard (`/aida-init` command)
- CLI config editing (`--set`, `--unset`)
- Schema discovery (`--schema`)
- Verbose/debug output modes

**DEFER to Later Issues**:

- Runtime API validation (`--verify-connection`)
- Provider plugin system implementation
- Team review strategy logic (round-robin)
- Jira/Linear integration (config structure only in #55)

### Configuration Schema (Recommended)

```json
{
  "config_version": "1.0",
  "vcs": {
    "provider": "github|gitlab|bitbucket",
    "owner": "string",
    "repo": "string",
    "main_branch": "main|master",
    "github": {
      "enterprise_url": null
    },
    "gitlab": {
      "project_id": "string",
      "self_hosted_url": null,
      "group": null
    },
    "bitbucket": {
      "workspace": "string",
      "repo_slug": "string"
    }
  },
  "work_tracker": {
    "provider": "github_issues|jira|linear|none",
    "github_issues": {
      "enabled": true
    },
    "jira": {
      "base_url": null,
      "project_key": null
    },
    "linear": {
      "team_id": null,
      "board_id": null
    }
  },
  "team": {
    "review_strategy": "list|round-robin|query|none",
    "default_reviewers": ["username1"],
    "members": [
      {
        "username": "string",
        "role": "developer|tech-lead|reviewer",
        "availability": "available|limited|unavailable"
      }
    ]
  },
  "workflow": {
    "commit": {
      "auto_commit": true
    },
    "pr": {
      "auto_version_bump": true,
      "update_changelog": true,
      "draft_by_default": false
    }
  }
}
```

### Migration Strategy

**Auto-migration on first command execution**:

```bash
# Detect old config format
if [ -f ~/.claude/workflow-config.json ]; then
  if ! has_vcs_section; then
    # Backup old config
    cp ~/.claude/workflow-config.json ~/.claude/workflow-config.json.backup

    # Migrate: github.* → vcs.github.*
    migrate_config_to_vcs_schema

    log "✓ Config migrated from v1 to v2"
    log "  Backup: ~/.claude/workflow-config.json.backup"
  fi
fi
```

**Deprecation period**: Support both old and new formats for 2 minor versions (v0.2.x, v0.3.x). Remove old format in v0.4.0.

### Error Message Template (Example)

```text
Error: GitHub configuration incomplete

Required fields missing:
  ✗ github.owner
  ✗ github.repo

Auto-detected from git remote:
  Remote URL: git@github.com:oakensoul/claude-personal-assistant.git
  Owner: oakensoul
  Repo: claude-personal-assistant

Quick fix:
  aida-config-helper.sh --set github.owner oakensoul
  aida-config-helper.sh --set github.repo claude-personal-assistant

Or manually add to .aida/config.json:
  {
    "github": {
      "owner": "oakensoul",
      "repo": "claude-personal-assistant"
    }
  }

See: aida-config-helper.sh --help github
```

## Coordination Required

**With Tech Lead**:

- Approve schema design and namespace structure
- Review provider abstraction architecture
- Validate migration strategy for existing configs

**With DevOps Engineer**:

- CI/CD integration with new config validation
- Secret scanning in automated workflows
- Pre-commit hook integration

**With Security Engineer**:

- Review secret detection patterns
- Validate file permission enforcement
- Audit trail requirements for compliance

**With UX Designer** (Shell Systems):

- Review error message templates
- Validate auto-detection feedback patterns
- Approve validation verbosity levels

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Breaking changes for existing users | HIGH | MEDIUM | Auto-migration + 2-version deprecation |
| Secrets committed to git | HIGH | CRITICAL | Pre-commit hook + clear documentation |
| Auto-detection failures | MEDIUM | MEDIUM | Manual override + clear error messages |
| Provider validation complexity | MEDIUM | LOW | Provider-specific validation functions |
| Schema changes require migration | LOW | MEDIUM | Version field + migration script template |

**Overall Risk**: MEDIUM - Managed through auto-migration and deprecation period

## Next Steps

1. Create JSON Schema definition (`lib/installer-common/config-schema.json`)
2. Implement VCS auto-detection function
3. Update `aida-config-helper.sh` with hierarchical loading
4. Create provider-specific validation functions
5. Implement pre-commit hook for secret detection
6. Write migration script for `github.*` → `vcs.*`
7. Create template config files with examples
8. Document schema, security model, and provider patterns
9. Write integration tests for auto-detection and validation
10. Update installer to set file permissions and create .gitignore

---

**Related Issues**:

- #56 - `/aida-init` command (user-facing setup)
- #57-59 - Provider implementations (Jira, GitLab, Linear, Bitbucket)

**Dependencies**: None (clean slate approach)

**Blocks**: Issues #56-59 (require config infrastructure)
