---
title: "Configuration Specialist Analysis - Issue #55"
issue: 55
agent: "configuration-specialist"
analysis_date: "2025-10-20"
status: "initial"
---

# Configuration Specialist Analysis: Issue #55

**Issue**: Create configuration system with `.claude/config.yml` schema

**Analyzed by**: configuration-specialist agent

**Date**: 2025-10-20

## 1. Domain-Specific Concerns

### Configuration Schema Design

#### Format Decision: JSON vs YAML

- **Decision made**: JSON only (no YAML)
- **Rationale**: Simpler parsing, existing `aida-config-helper.sh` uses `jq`, no YAML dependencies
- **Trade-offs accepted**:
  - Less human-friendly than YAML (no comments, stricter syntax)
  - Harder to hand-edit (quotes required, no trailing commas)
  - Better for programmatic access (jq ecosystem mature)

**Recommended Schema Structure**:

```json
{
  "config_version": "1.0",
  "vcs": {
    "provider": "github|gitlab|bitbucket",
    "owner": "string",
    "repo": "string",
    "remote_url": "string (auto-detected)",
    "main_branch": "main|master|develop",
    "github": {
      "api_base": "https://api.github.com (default)",
      "enterprise_url": null
    },
    "gitlab": {
      "api_base": "https://gitlab.com/api/v4 (default)",
      "self_hosted_url": null,
      "group": null
    },
    "bitbucket": {
      "api_base": "https://api.bitbucket.org/2.0 (default)",
      "workspace": null
    }
  },
  "work_tracker": {
    "provider": "github_issues|jira|linear|none",
    "github_issues": {
      "enabled": true,
      "labels_enabled": true
    },
    "jira": {
      "enabled": false,
      "base_url": null,
      "project_key": null,
      "issue_type": "Task"
    },
    "linear": {
      "enabled": false,
      "team_id": null,
      "board_id": null
    }
  },
  "team": {
    "review_strategy": "round-robin|list|query|none",
    "default_reviewers": ["username1", "username2"],
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
    },
    "versioning": {
      "enabled": true
    }
  }
}
```

### Validation Strategy

**Provider-Specific Validation Rules**:

**VCS Provider Validation**:

- `github`: Requires `owner`, `repo`, optional `github.enterprise_url`
- `gitlab`: Requires `owner`, `repo`, optional `group`, `self_hosted_url`
- `bitbucket`: Requires `workspace`, `repo`

**Work Tracker Validation**:

- `github_issues`: Auto-valid if VCS is GitHub
- `jira`: Requires `base_url`, `project_key`
- `linear`: Requires `team_id`, `board_id`

**Team Review Strategy Validation**:

- `round-robin`: Requires `team.default_reviewers` list with 1+ members
- `list`: Requires `team.default_reviewers` list
- `query`: No requirements (runtime query)
- `none`: No requirements

**Validation Implementation Approach**:

```bash
# Recommended: JSON Schema validation (draft-07)
# Create: lib/installer-common/config-schema.json
# Validate using: jq with --schema flag (if available) or ajv-cli

# Fallback: Shell-based validation in aida-config-helper.sh
validate_vcs_config() {
  local provider="$1"
  local config_json="$2"

  case "$provider" in
    github)
      jq -e '.vcs.owner and .vcs.repo' <<< "$config_json" >/dev/null
      ;;
    gitlab)
      jq -e '.vcs.owner and .vcs.repo' <<< "$config_json" >/dev/null
      ;;
    bitbucket)
      jq -e '.vcs.workspace and .vcs.repo' <<< "$config_json" >/dev/null
      ;;
  esac
}
```

### Default Value Strategy

**Layered Defaults Pattern** (already implemented in `aida-config-helper.sh`):

1. **System defaults** (built-in JSON) - Foundation layer
2. **User config** (`~/.claude/aida-config.json`) - User preferences
3. **Project config** (`.aida/config.json`) - Project overrides
4. **Environment variables** - Runtime overrides

**Auto-Detection Defaults**:

```json
{
  "vcs": {
    "provider": "${AUTO_DETECT_FROM_GIT_REMOTE}",
    "owner": "${PARSE_FROM_REMOTE_URL}",
    "repo": "${PARSE_FROM_REMOTE_URL}",
    "main_branch": "${GIT_SYMBOLIC_REF_DEFAULT}"
  },
  "work_tracker": {
    "provider": "${INFER_FROM_VCS_PROVIDER}",
    "github_issues": {
      "enabled": "${TRUE_IF_VCS_GITHUB}"
    }
  },
  "team": {
    "review_strategy": "list",
    "default_reviewers": []
  }
}
```

**Sensible Default Values**:

- `vcs.main_branch`: "main" (detect from `git symbolic-ref refs/remotes/origin/HEAD`)
- `work_tracker.provider`: "github_issues" if VCS is GitHub, else "none"
- `team.review_strategy`: "list" (simplest, no round-robin logic needed)
- `workflow.commit.auto_commit`: true (existing AIDA behavior)
- `workflow.pr.auto_version_bump`: true (existing AIDA behavior)

### Hierarchical Configuration Merging

**Current Implementation** (from `aida-config-helper.sh`):

- Uses `jq` deep merge with `*` operator
- Priority order correct: system → user → git → github → workflow → project → env
- **Gap**: No namespace-specific merging strategy

**Recommended Enhancement**:

```bash
# Current merge (simple deep merge)
'$sys * $user * $git * $github * $workflow * $project * $env'

# Enhanced merge (namespace-aware)
# - vcs.* namespace: project overrides all
# - work_tracker.* namespace: project overrides all
# - team.* namespace: merge arrays (union), objects (deep merge)
# - workflow.* namespace: project overrides all
```

**Array Merge Strategy**:

- `team.default_reviewers`: **union** (combine user + project reviewers)
- `team.members`: **union by username** (project members override user members)

**Object Merge Strategy**:

- `vcs.github.*`: **deep merge** (allows partial overrides)
- `work_tracker.jira.*`: **deep merge** (allows partial overrides)

## 2. Stakeholder Impact

### Developers

**Ease of Configuration**:

- **Positive**: Auto-detection eliminates most manual config
- **Negative**: JSON less friendly than YAML for hand-editing
- **Mitigation**: Provide `aida config init` command with interactive prompts

**Discovery**:

- **Need**: How do I know what config options exist?
- **Solution**: `aida config show --schema` to display JSON schema
- **Solution**: Template config file with comments (external `.md` docs)

**Validation Feedback**:

- **Need**: Clear error messages when config invalid
- **Solution**: Provider-specific validation with fix suggestions
- **Example**:

  ```text
  Configuration Error: vcs.provider = "github"

  Missing required fields for GitHub provider:
    - vcs.owner (e.g., "oakensoul")
    - vcs.repo (e.g., "claude-personal-assistant")

  Auto-detect these values? Run:
    aida config detect --vcs
  ```

### Users (Non-Developers)

**Understandability**:

- **Challenge**: JSON syntax strict (quotes, no trailing commas)
- **Mitigation**: Provide `aida config edit` that validates on save
- **Mitigation**: Provide `aida config set <key> <value>` for single-value updates

**Modification Confidence**:

- **Challenge**: Fear of breaking config with typos
- **Mitigation**: Backup config before edits (`~/.claude/aida-config.json.backup`)
- **Mitigation**: `aida config validate` command with detailed errors

### Future Maintainers

**Schema Extensibility**:

- **Positive**: JSON Schema supports versioning via `config_version`
- **Positive**: Provider-specific sections easily added (e.g., `vcs.gitea.*`)
- **Negative**: Migration logic needed when schema changes

**Backward Compatibility**:

- **Decision**: No backward compat with `github.*` namespace (clean slate)
- **Risk**: Users with existing `.github/GITHUB_CONFIG.json` need migration
- **Mitigation**: Provide `aida config migrate` command for v0.0.x → v0.1.0

**New Provider Addition**:

- **Process**:
  1. Add provider section to schema (e.g., `vcs.gitea`)
  2. Add detection logic to auto-detect function
  3. Add validation rules to validate function
  4. Add provider-specific config to defaults
- **Complexity**: Low (schema-driven design)

## 3. Questions & Clarifications

### Validation Rules

**Q1**: What validation rules for each provider type?

**A1**: See "Validation Strategy" section above. Key rules:

- **GitHub**: owner, repo (required); enterprise_url (optional)
- **GitLab**: owner, repo (required); group, self_hosted_url (optional)
- **Bitbucket**: workspace, repo (required)
- **Jira**: base_url, project_key (required); issue_type (optional)
- **Linear**: team_id, board_id (required)

**Q2**: Should validation be strict (fail on unknown fields) or lenient (ignore)?

**Recommendation**: **Strict mode by default**, with `--lenient` flag for testing

- Prevents typos (`vcs.owwner` instead of `vcs.owner`)
- Use `additionalProperties: false` in JSON Schema
- Allow lenient mode for future compatibility

### Missing/Invalid Config Handling

**Q3**: How to handle missing config gracefully?

**Recommendation**: **Three-tier fallback strategy**:

1. **Auto-detect**: Try to infer from git remote, environment
2. **Prompt**: If in interactive mode, ask user
3. **Fail gracefully**: If non-interactive, provide clear error + fix instructions

**Example**:

```bash
# Auto-detect attempt
if ! config_exists "vcs.provider"; then
  detect_vcs_provider_from_git_remote
fi

# Still missing? Prompt if interactive
if ! config_exists "vcs.provider" && is_interactive; then
  prompt_for_vcs_provider
fi

# Still missing? Fail with helpful message
if ! config_exists "vcs.provider"; then
  echo "ERROR: vcs.provider not configured and could not auto-detect"
  echo ""
  echo "Fix: Run one of:"
  echo "  1. aida config detect --vcs  (auto-detect from git remote)"
  echo "  2. aida config set vcs.provider github"
  echo "  3. Edit ~/.claude/aida-config.json manually"
  exit 1
fi
```

**Q4**: What to do with invalid config values?

**Recommendation**: **Fail fast with validation**, provide fix suggestions

```bash
# Example: Invalid VCS provider
if ! valid_vcs_provider "$provider"; then
  echo "ERROR: Invalid vcs.provider: $provider"
  echo ""
  echo "Valid providers: github, gitlab, bitbucket"
  echo ""
  echo "Did you mean one of these?"
  suggest_similar_value "$provider" "github gitlab bitbucket"
  exit 1
fi
```

### Auto-Detection Behavior

**Q5**: Should auto-detection be opt-in or opt-out?

**Recommendation**: **Opt-out (run by default)**

- Most users want auto-detection (convenience)
- Power users can disable with `vcs.auto_detect: false`
- First-time setup always runs auto-detection

**Q6**: What if auto-detection is wrong?

**Recommendation**: **Allow manual override**

- Auto-detected values saved to `.aida/config.json` (project-level)
- User can edit or run `aida config set vcs.provider gitlab`
- Manual values take precedence over auto-detected values

### Provider-Specific Field Validation

**Q7**: How to validate Jira `project_key` format (e.g., must be UPPERCASE)?

**Recommendation**: **Provider-specific validation functions**

```bash
validate_jira_config() {
  local config="$1"

  # Validate project_key format (uppercase, alphanumeric, max 10 chars)
  local project_key
  project_key=$(jq -r '.work_tracker.jira.project_key' <<< "$config")

  if [[ ! "$project_key" =~ ^[A-Z][A-Z0-9]{1,9}$ ]]; then
    echo "ERROR: Invalid Jira project_key: $project_key"
    echo "Format: 2-10 uppercase alphanumeric characters (e.g., AIDA, PROJ)"
    return 1
  fi

  # Validate base_url is HTTPS
  local base_url
  base_url=$(jq -r '.work_tracker.jira.base_url' <<< "$config")

  if [[ ! "$base_url" =~ ^https:// ]]; then
    echo "ERROR: Jira base_url must use HTTPS: $base_url"
    return 1
  fi
}
```

**Q8**: How to validate Linear `board_id` or `team_id` (UUIDs)?

**Recommendation**: **Format validation only** (not existence validation)

```bash
validate_linear_config() {
  local config="$1"

  # Validate team_id is UUID format
  local team_id
  team_id=$(jq -r '.work_tracker.linear.team_id' <<< "$config")

  if [[ ! "$team_id" =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$ ]]; then
    echo "ERROR: Invalid Linear team_id (must be UUID): $team_id"
    echo "Find your team ID: https://linear.app/[workspace]/settings/api"
    return 1
  fi
}
```

**Note**: Do NOT validate that IDs exist (no API calls during validation)

## 4. Recommendations

### Schema Design Patterns

#### 1. Use JSON Schema draft-07 for formal validation

Create `lib/installer-common/config-schema.json`:

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "AIDA Configuration",
  "type": "object",
  "required": ["config_version", "vcs", "work_tracker", "team"],
  "properties": {
    "config_version": {
      "type": "string",
      "pattern": "^\\d+\\.\\d+$",
      "description": "Configuration schema version (e.g., '1.0')"
    },
    "vcs": {
      "type": "object",
      "required": ["provider"],
      "properties": {
        "provider": {
          "type": "string",
          "enum": ["github", "gitlab", "bitbucket"],
          "description": "Version control system provider"
        },
        "owner": {"type": "string"},
        "repo": {"type": "string"},
        "main_branch": {
          "type": "string",
          "default": "main"
        }
      }
    }
  }
}
```

#### 2. Provide namespace isolation for provider-specific config

- Each provider gets own section: `vcs.github.*`, `vcs.gitlab.*`, `vcs.bitbucket.*`
- Only validate active provider's section (ignore others)
- Allows config to contain multiple provider configs (multi-project support)

#### 3. Include metadata for auto-detection tracking

```json
{
  "vcs": {
    "provider": "github",
    "_detected": {
      "method": "git_remote",
      "timestamp": "2025-10-20T12:34:56Z",
      "confidence": "high"
    }
  }
}
```

Benefits:

- Debug auto-detection issues
- Know when to re-run detection (stale data)
- Distinguish user-provided vs auto-detected values

### Validation Approach

**1. Three-tier validation strategy**:

**Tier 1: JSON Schema validation** (structure + types)

- Validates JSON structure against schema
- Checks required fields, types, enums
- Fast, comprehensive, standard

**Tier 2: Provider-specific validation** (business rules)

- Validates provider-specific field formats
- Checks inter-field dependencies
- Custom error messages with fix suggestions

**Tier 3: Runtime validation** (connectivity, permissions)

- OPTIONAL: Test API connectivity (with `--verify-connection` flag)
- OPTIONAL: Check API token permissions
- Slow, only run when explicitly requested

**2. Validation timing**:

- **On load**: Always validate structure (Tier 1)
- **On save**: Always validate structure + provider rules (Tier 1 + 2)
- **On demand**: User runs `aida config validate --verify-connection` (all tiers)

**3. Error message format**:

```text
Configuration Validation Error

File: ~/.claude/aida-config.json
Path: vcs.provider
Value: "githb" (typo)

Problem: Invalid VCS provider
Valid values: github, gitlab, bitbucket

Did you mean: github?

Fix:
  1. Edit ~/.claude/aida-config.json
  2. Change "vcs.provider" to "github"
  3. Run: aida config validate

Or run: aida config set vcs.provider github
```

### Error Handling Strategy

#### 1. Fail fast with helpful messages

- Don't continue with invalid config
- Provide clear error + actionable fix
- Suggest auto-detect/interactive mode when applicable

#### 2. Graceful degradation for optional features

- If `work_tracker.jira` config missing, disable Jira integration (don't fail)
- If `team.default_reviewers` empty, use alternative review strategy
- Log warnings for degraded functionality

#### 3. Backup config before destructive operations

```bash
# Before overwriting config
cp ~/.claude/aida-config.json ~/.claude/aida-config.json.backup.$(date +%s)

# Provide restore instructions on error
echo "Config backup saved: ~/.claude/aida-config.json.backup.1729425600"
echo "Restore with: mv ~/.claude/aida-config.json.backup.1729425600 ~/.claude/aida-config.json"
```

#### 4. Validation exit codes

- `0`: Valid config
- `1`: Invalid config (structure)
- `2`: Invalid config (provider rules)
- `3`: Invalid config (runtime connectivity)

Allows callers to distinguish error types:

```bash
if ! aida-config-helper.sh --validate; then
  case $? in
    1) echo "Fix JSON structure errors" ;;
    2) echo "Fix provider configuration" ;;
    3) echo "Check API connectivity" ;;
  esac
fi
```

### Configuration Documentation Approach

**1. Multi-format documentation**:

- **JSON Schema** (`lib/installer-common/config-schema.json`) - Machine-readable
- **Template config** (`templates/config/aida-config.template.json`) - Human-readable with comments (in adjacent `.md` file)
- **CLI help** (`aida config --help`) - Quick reference
- **Full docs** (`docs/configuration.md`) - Comprehensive guide

**2. Template config with external comments**:

Since JSON doesn't support comments, create:

- `templates/config/aida-config.template.json` - Clean JSON template
- `templates/config/aida-config-guide.md` - Field-by-field documentation

Users can reference guide while editing config.

**3. Interactive config builder**:

```bash
aida config init --interactive

# Prompts:
# 1. Detect VCS provider from git remote? [Y/n]
# 2. VCS Provider: github
# 3. Work tracker: (1) GitHub Issues (2) Jira (3) Linear (4) None
# 4. Team review strategy: (1) List (2) Round-robin (3) Query (4) None
# ... etc
```

**4. Configuration examples for common scenarios**:

```markdown
# docs/configuration.md

## Example Configurations

### GitHub with GitHub Issues
```json
{
  "vcs": {"provider": "github", "owner": "oakensoul", "repo": "aida"},
  "work_tracker": {"provider": "github_issues"}
}
```

### GitLab with Jira

```json
{
  "vcs": {"provider": "gitlab", "owner": "acme", "repo": "project"},
  "work_tracker": {
    "provider": "jira",
    "jira": {"base_url": "https://acme.atlassian.net", "project_key": "PROJ"}
  }
}
```

## Implementation Priority

**Phase 1: Foundation** (v0.1.0 - MVP)

1. JSON schema design (`lib/installer-common/config-schema.json`)
2. VCS auto-detection from git remote
3. Basic validation (structure + required fields)
4. Template config file with guide
5. Update `aida-config-helper.sh` to support new namespaces

**Phase 2: Validation** (v0.1.1)

1. Provider-specific validation functions
2. Helpful error messages with fix suggestions
3. `aida config validate` command
4. Backup/restore on config changes

**Phase 3: Interactive Setup** (v0.1.2)

1. `aida config init --interactive`
2. Auto-detection with user confirmation
3. Migration from old `github.*` namespace

**Phase 4: Advanced Features** (v0.2.0+)

1. Runtime validation (API connectivity testing)
2. Multi-project config support
3. Team review strategy implementation
4. Jira/Linear integration (deferred)

## Migration Path (v0.0.x → v0.1.0)

**Existing Config**: `.github/GITHUB_CONFIG.json` with `github.*` namespace

**New Config**: `~/.claude/aida-config.json` with `vcs.*`, `work_tracker.*` namespaces

**Migration Strategy**:

```bash
# aida config migrate
# 1. Detect old config files
# 2. Parse github.owner, github.repo
# 3. Create new config with vcs.provider=github
# 4. Copy workflow settings
# 5. Backup old config (don't delete)
# 6. Validate new config
```

**Example Migration**:

```json
// OLD: .github/GITHUB_CONFIG.json
{
  "github": {
    "owner": "oakensoul",
    "repo": "aida",
    "main_branch": "main"
  }
}

// NEW: ~/.claude/aida-config.json
{
  "config_version": "1.0",
  "vcs": {
    "provider": "github",
    "owner": "oakensoul",
    "repo": "aida",
    "main_branch": "main"
  },
  "work_tracker": {
    "provider": "github_issues",
    "github_issues": {"enabled": true}
  }
}
```

## Risk Assessment

**Low Risk**:

- JSON Schema design (standard, well-understood)
- VCS auto-detection (low complexity, git remote parsing)
- Basic validation (structure + types)

**Medium Risk**:

- Provider-specific validation (requires understanding each provider's rules)
- Migration from old config (need to handle edge cases)
- Error message quality (requires UX iteration)

**High Risk**:

- Runtime API validation (network calls, timeouts, rate limits)
- Multi-provider support (complexity grows with each provider)
- Backward compatibility (if we commit to it, hard to change)

**Mitigation**:

- Start with GitHub-only (defer GitLab/Bitbucket to v0.2+)
- Skip runtime validation in v0.1.0 (add in v0.2+)
- Clean slate approach (no backward compat) reduces risk

## Success Criteria

**Developer Experience**:

- [ ] `aida config init` creates valid config in < 30 seconds
- [ ] Auto-detection succeeds for 95%+ of GitHub repos
- [ ] Validation errors include fix suggestions
- [ ] Config changes don't require manual JSON editing

**Maintainability**:

- [ ] Adding new VCS provider takes < 2 hours
- [ ] JSON Schema serves as single source of truth
- [ ] Validation functions tested with 100% coverage
- [ ] Migration path documented and tested

**Future-Proofing**:

- [ ] Schema supports versioning (`config_version`)
- [ ] Provider-specific sections isolated (no cross-contamination)
- [ ] Extensible to Jira/Linear without breaking changes
- [ ] Team settings support future collaboration features

---

**Next Steps**:

1. Review this analysis with tech-lead
2. Finalize schema design (JSON Schema file)
3. Implement VCS auto-detection function
4. Create template config + guide
5. Update `aida-config-helper.sh` with new namespaces
6. Write validation tests

**Coordination Required**:

- **tech-lead**: Approve schema design, namespace structure
- **devops-engineer**: CI/CD integration with new config
- **product-manager**: Review UX of error messages, interactive setup
