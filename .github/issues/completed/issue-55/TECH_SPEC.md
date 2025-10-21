---
title: "Technical Specification - Configuration System (#55)"
issue: 55
status: "draft"
created: "2025-10-20"
category: "technical-specification"
---

# Technical Specification: Configuration System with VCS Abstraction

## Architecture Overview

**Approach**: Build JSON-based configuration infrastructure with VCS provider abstraction, leveraging existing `aida-config-helper.sh` (750 lines, proven caching architecture). This is **foundation work only** - no actual provider implementations in this issue.

**Key Components**:

1. **JSON Schema**: Validation and IDE autocomplete support
2. **VCS Detector**: Auto-detect provider from git remote (GitHub, GitLab, Bitbucket)
3. **Config Validator**: Three-tier validation (structure → provider rules → connectivity)
4. **Config Migrator**: Safe migration from `github.*` → `vcs.github.*` with rollback

**Architecture Diagram**:

```text
┌─────────────────────────────────────────────────────────────┐
│  User Interaction Layer                                     │
│  (Commands, Installer, /aida-init)                          │
└─────────────┬───────────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────────────────┐
│  Config Helper (aida-config-helper.sh)                      │
│  - Load hierarchical config (user → project → env)          │
│  - Merge with deep namespace-aware strategy                 │
│  - Cache with checksum-based invalidation                   │
└─────────────┬───────────────────────────────────────────────┘
              │
              ├─────► VCS Detector (vcs-detector.sh)
              │       - Parse git remote URL
              │       - Extract provider/owner/repo
              │       - Confidence scoring (high/medium/low)
              │
              ├─────► Config Validator (config-validator.sh)
              │       - Tier 1: JSON Schema (structure)
              │       - Tier 2: Provider rules (required fields)
              │       - Tier 3: Connectivity (OPTIONAL, --verify-connection)
              │
              └─────► Config Migrator (config-migration.sh)
                      - Backup original config (timestamped)
                      - Transform github.* → vcs.github.*
                      - Validate migrated config
                      - Rollback on failure
```

**Data Flow**:

```text
User runs command → Load config → Check version
    ↓
If version < 1.0: Auto-migrate (with backup)
    ↓
If vcs.provider empty: Auto-detect from git remote
    ↓
Validate config:
  - Tier 1: Structure (JSON Schema)
  - Tier 2: Provider rules (GitHub requires owner+repo)
  - Tier 3: Connectivity (OPTIONAL)
    ↓
Merge configs (user → project → env vars → detected)
    ↓
Cache merged config (checksum-based)
    ↓
Return to command
```

---

## Technical Decisions

### Decision 1: JSON Only (No YAML)

**Decision**: Use JSON exclusively for configuration files.

**Rationale**:

- Simpler parsing with `jq` (already required dependency)
- No additional dependencies (YAML would require `yq` or Python)
- Existing `aida-config-helper.sh` infrastructure is JSON-based (750 lines)
- JSON Schema ecosystem mature and well-supported

**Alternatives Considered**:

- **YAML**: More human-friendly (supports comments), but adds complexity
- **TOML**: Popular for config files, but lacks shell tooling

**Trade-offs**:

- ✅ Pro: Native `jq` support, simpler parsing, IDE autocomplete via JSON Schema
- ❌ Con: No comments (use field descriptions in schema instead)
- ❌ Con: Less human-friendly than YAML (mitigated by templates and IDE autocomplete)

**Accepted**: Trade human-friendliness for simplicity and existing infrastructure compatibility.

---

### Decision 2: Three-Tier Validation

**Decision**: Implement progressive validation with three tiers, each with distinct exit codes.

**Rationale**:

- **Tier 1 (Structure)**: Fast, catches syntax and type errors early
- **Tier 2 (Provider Rules)**: Context-aware validation (GitHub needs owner+repo, GitLab needs project_id)
- **Tier 3 (Connectivity)**: Optional, expensive API calls only when requested

**Alternatives Considered**:

- **Single-tier validation**: Simpler but less granular error reporting
- **Two-tier validation**: No connectivity check (defer to runtime failures)

**Trade-offs**:

- ✅ Pro: Progressive disclosure of errors, fast feedback loop, clear separation of concerns
- ❌ Con: More complex implementation, three separate validation paths
- ✅ Mitigation: Tier 3 is opt-in (default validation completes in <150ms)

**Exit Codes**:

- `0`: Validation passed
- `1`: Structure validation failed (invalid JSON, wrong types, missing required fields)
- `2`: Provider rules validation failed (GitHub missing owner/repo, GitLab missing project_id)
- `3`: Connectivity validation failed (API unreachable, authentication failed)

---

### Decision 3: Clean Slate (No Backward Compatibility with github.*)

**Decision**: Auto-migration required, no runtime support for old `github.*` namespace.

**Rationale**:

- Clean namespace design without legacy cruft
- Forces users to upgrade (prevents indefinite tech debt)
- Simpler codebase (no dual-path logic)
- Auto-migration makes transition seamless

**Alternatives Considered**:

- **Dual support**: Support both `github.*` and `vcs.github.*` for 2 versions
- **Manual migration only**: Require users to run migration script themselves

**Trade-offs**:

- ✅ Pro: Clean codebase, no legacy support burden
- ❌ Con: Breaking change for existing users
- ✅ Mitigation: Auto-migration with backup, clear documentation, 2-version deprecation warnings

**Migration Strategy**:

1. **v0.2.0**: Introduce `vcs.*`, auto-migrate on first command execution, create backup
2. **v0.2.x-v0.3.x**: Log deprecation warnings if old format detected
3. **v0.4.0**: Remove support for old format entirely

---

### Decision 4: Team Namespace at Top Level (Not in workflow.*)

**Decision**: Move `workflow.pull_requests.reviewers` → `team.default_reviewers` at config root.

**Rationale**:

- Team configuration is orthogonal to VCS provider (applies to GitHub, GitLab, Bitbucket)
- `team.*` namespace groups related fields (reviewers, members, review_strategy)
- Clearer separation of concerns (VCS config vs team config vs workflow preferences)

**Alternatives Considered**:

- Keep in `workflow.pull_requests.reviewers` (mixing workflow automation with team metadata)
- Create `reviewers.*` namespace (too narrow, doesn't accommodate team members, roles)

**Trade-offs**:

- ✅ Pro: Logical grouping, reusable across providers, extensible for future team fields
- ❌ Con: Breaking change from existing structure
- ✅ Mitigation: Auto-migration handles this transformation

**New Schema**:

```json
{
  "team": {
    "review_strategy": "list|round-robin|query|none",
    "default_reviewers": ["username1", "username2"],
    "members": [
      {
        "username": "alice",
        "role": "tech-lead",
        "availability": "available"
      }
    ]
  }
}
```

---

### Decision 5: Provider-Specific Subsections (Not Flat Namespace)

**Decision**: Use nested provider-specific config (`vcs.github.*`, `vcs.gitlab.*`, `work_tracker.jira.*`).

**Rationale**:

- **Namespace isolation**: Adding new provider doesn't conflict with existing providers
- **Clear validation**: Required fields scoped to active provider
- **Extensibility**: New provider = new subsection, no schema-wide changes
- **Self-documenting**: Structure clearly shows which fields apply to which provider

**Alternatives Considered**:

- **Flat namespace**: `vcs.project_id`, `vcs.workspace`, `vcs.enterprise_url` all at top level
- **Provider-prefixed fields**: `vcs.github_enterprise_url`, `vcs.gitlab_project_id`

**Trade-offs**:

- ✅ Pro: Isolation prevents field collision, clear provider boundaries, easy to add new providers
- ❌ Con: Deeper nesting (requires more `jq` path navigation)
- ✅ Accepted: Slight increase in path depth is worth namespace clarity

**Example**:

```json
{
  "vcs": {
    "provider": "github",
    "owner": "oakensoul",
    "repo": "repo",
    "github": {
      "enterprise_url": null
    },
    "gitlab": {
      "project_id": null,
      "self_hosted_url": null
    }
  }
}
```

---

## Implementation Plan

### Components to Build/Modify

#### 1. `lib/installer-common/config-schema.json` (NEW)

**Purpose**: JSON Schema Draft-07 definition for validation and IDE autocomplete.

**Key Features**:

- Conditional validation (`allOf` + `if/then`) for provider-specific requirements
- Pattern validation (URLs must be HTTPS, Jira project_key format, UUID format)
- Default values documented in schema
- `additionalProperties: false` to catch typos

**Complexity**: MEDIUM (4-6 hours)

---

#### 2. `lib/installer-common/vcs-detector.sh` (NEW)

**Purpose**: Auto-detect VCS provider from git remote URL.

**Functions**:

- `detect_vcs_provider()`: Parse git remote URL, return provider name
- `extract_github_info()`: Extract owner/repo from GitHub URL (SSH + HTTPS)
- `extract_gitlab_info()`: Extract owner/repo from GitLab URL
- `extract_bitbucket_info()`: Extract workspace/repo_slug from Bitbucket URL
- `detect_main_branch()`: Get main branch from git symbolic-ref
- `get_detection_confidence()`: Return high/medium/low confidence

**Regex Patterns**:

- GitHub SSH: `git@github\.com:([^/]+)/([^/]+)(\.git)?$`
- GitHub HTTPS: `https://github\.com/([^/]+)/([^/]+)(\.git)?$`
- GitLab SSH: `git@gitlab\.com:([^/]+)/([^/]+)(\.git)?$`
- GitLab HTTPS: `https://gitlab\.com/([^/]+)/([^/]+)(\.git)?$`
- Bitbucket: Similar patterns with `bitbucket\.org`

**Complexity**: MEDIUM (3-4 hours)

---

#### 3. `lib/installer-common/config-validator.sh` (NEW)

**Purpose**: Three-tier validation (structure → provider rules → connectivity).

**Functions**:

- `validate_structure()`: JSON Schema validation (Tier 1)
- `validate_provider_rules()`: Provider-specific validation (Tier 2)
- `validate_github_config()`: GitHub requires owner+repo
- `validate_gitlab_config()`: GitLab requires project_id, owner, repo
- `validate_bitbucket_config()`: Bitbucket requires workspace+repo_slug
- `validate_jira_config()`: Jira requires base_url+project_key with format validation
- `validate_connectivity()`: Optional API connectivity checks (Tier 3)
- `show_provider_fix_suggestion()`: Error messages with auto-detected values

**Validator Selection** (tiered fallback):

1. Try `ajv-cli` (Node.js, best error messages)
2. Try `check-jsonschema` (Python, good error messages)
3. Fallback to `jq empty` (basic syntax validation only)

**Complexity**: MEDIUM-HIGH (4-6 hours)

---

#### 4. `lib/installer-common/config-migration.sh` (NEW)

**Purpose**: Safe migration from `github.*` → `vcs.github.*` with rollback.

**Functions**:

- `migrate_config()`: Orchestrator with version detection
- `migrate_github_to_vcs()`: Transform old namespace to new
- `backup_config()`: Create timestamped backup with validation
- `restore_config_from_backup()`: Atomic restore on migration failure
- `cleanup_old_backups()`: Keep last N backups (default: 5)

**Safety Features**:

- **Atomic operations**: Write to temp file, validate, then atomic move
- **Backup first**: Never modify original until all validations pass
- **Auto-rollback**: Restore from backup if migration validation fails
- **Idempotent**: Running migration twice produces same result

**Complexity**: HIGH (6-8 hours)

---

#### 5. `lib/aida-config-helper.sh` (MODIFY)

**Purpose**: Extend existing config helper with new namespaces.

**Changes**:

- Add `vcs.*`, `work_tracker.*`, `team.*` to `get_system_defaults()`
- Extend `validate_config()` to use new `config-validator.sh`
- Add migration check in `get_merged_config()` (auto-migrate if version < 1.0)
- Integrate VCS auto-detection if `vcs.provider` empty and `vcs.auto_detect = true`
- Preserve existing caching infrastructure (checksum-based invalidation)

**Complexity**: MEDIUM (3-4 hours)

---

#### 6. `.pre-commit-config.yaml` + `scripts/validate-config-security.sh` (NEW)

**Purpose**: Pre-commit hook to detect secrets in config files.

**Secret Patterns**:

- GitHub tokens: `ghp_[A-Za-z0-9]{36}`, `github_pat_[A-Za-z0-9_]{82}`
- Jira tokens: `[A-Za-z0-9]{24,32}` (context-aware, must be near "jira" or "api_token")
- Linear keys: `lin_api_[A-Za-z0-9]{40}`
- Anthropic keys: `sk-ant-[A-Za-z0-9\-_]{95,}`
- Generic patterns: `"api_key"\s*:\s*"[^"]+"`, `"token"\s*:\s*"[^"]+"`

**Integration**:

```yaml
# .pre-commit-config.yaml
- repo: local
  hooks:
    - id: validate-config-security
      name: Validate config file security
      entry: scripts/validate-config-security.sh
      language: script
      files: 'config\.json$'
      pass_filenames: false
```

**Complexity**: LOW (2-3 hours)

---

#### 7. `templates/config/*.json` (NEW)

**Purpose**: Template config files for common scenarios.

**Templates to Create**:

- `config.json.template` - Generic template with placeholders
- `config-github-simple.json` - Minimal GitHub config
- `config-github-enterprise.json` - GitHub Enterprise example
- `config-gitlab-jira.json` - GitLab VCS + Jira work tracker
- `config-bitbucket.json` - Bitbucket example

**Complexity**: LOW (2-3 hours)

---

### Dependencies

**External Dependencies** (already in project):

- `jq` - JSON parsing and manipulation (required by existing code)
- `git` - Version control operations (assumed present)
- `bash 3.2+` - Shell environment (validated by existing code)
- `realpath` - Path resolution (already required)

**Optional Dependencies** (graceful degradation):

- `ajv-cli` or `check-jsonschema` - JSON Schema validation (fallback to `jq` if unavailable)
- `rsync` - Atomic file copy for backups (fallback to `cp` if unavailable)

**New Internal Dependencies**:

- `vcs-detector.sh` - Auto-detection logic
- `config-validator.sh` - Validation tiers
- `config-migration.sh` - Migration and rollback

---

### Integration Points

#### Integration 1: Installer (`install.sh`)

**Changes**:

1. Set file permissions after config creation:
   - User config: `chmod 600 ~/.claude/config.json`
   - Project config: `chmod 644 .aida/config.json`
2. Run migration check on first install (if old config exists)
3. Generate initial config from template with auto-detected values
4. Add `.gitignore` entries for user config and backups

**Code Changes**:

```bash
# In install.sh, after create_directories()
if [[ -f ~/.claude/workflow-config.json ]]; then
  migrate_config ~/.claude/workflow-config.json
fi

# Set permissions
chmod 600 ~/.claude/config.json
chmod 644 .aida/config.json

# Add to .gitignore
echo "~/.claude/config.json" >> ~/.gitignore
echo "*.backup.*" >> .aida/.gitignore
```

---

#### Integration 2: Commands (`/start-work`, `/open-pr`, etc.)

**No Changes in Issue #55** - Commands continue using `aida-config-helper.sh` interface.

**Future Integration** (Issue #56+):

- Commands will use new `vcs.*` namespace
- VCS-agnostic function calls: `vcs_get_issue()`, `vcs_create_pr()`
- Provider-specific logic moved to provider implementations

---

#### Integration 3: Pre-commit Hooks

**New Hook**: `validate-config-security.sh` (secret detection)

**Integration**:

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.18.2
    hooks:
      - id: gitleaks  # Existing pattern-based detection

  - repo: local
    hooks:
      - id: validate-config-security  # NEW: AIDA-specific validation
        name: Validate config file security
        entry: scripts/validate-config-security.sh
        language: script
        files: 'config\.json$'
```

---

## Technical Risks & Mitigations

### Risk 1: Migration Breaking Existing Workflows

**Impact**: HIGH - Users unable to run commands after upgrade

**Likelihood**: MEDIUM - Migration logic has edge cases (complex jq transformations)

**Mitigation**:

1. **Backup before migration**: Create timestamped backup, never overwrite without validation
2. **Validate migrated config**: Run full validation before replacing original
3. **Auto-rollback**: If validation fails, restore from backup automatically
4. **Comprehensive testing**: Test migration with 10+ real-world config fixtures
5. **Dry-run mode**: Allow users to preview migration without applying
6. **Two-version deprecation**: Support old format for v0.2.x and v0.3.x with warnings

**Contingency**: If migration fails in production, provide manual rollback instructions and script.

---

### Risk 2: Auto-Detection False Positives/Negatives

**Impact**: MEDIUM - Incorrect provider detection leads to validation errors

**Likelihood**: MEDIUM - Git remote URL patterns have edge cases (enterprise, custom domains)

**Mitigation**:

1. **Confidence scoring**: Track detection confidence (high/medium/low)
2. **Fallback to manual**: If confidence < high, prompt user to confirm
3. **Comprehensive regex testing**: Test against 20+ URL pattern variations
4. **User override**: Allow `vcs.auto_detect = false` to disable
5. **Clear error messages**: Show detected values, allow easy correction
6. **Logging**: Log detection metadata for troubleshooting

**Contingency**: If auto-detection fails, provide clear instructions to set values manually.

---

### Risk 3: Performance Degradation from Validation

**Impact**: MEDIUM - Slow validation disrupts workflow

**Likelihood**: LOW - JSON Schema validation is generally fast

**Mitigation**:

1. **Performance budget**: Tier 1+2 validation must complete in <150ms
2. **Caching**: Reuse existing checksum-based cache (config unchanged = skip validation)
3. **Lazy validation**: Only validate provider-specific sections that exist in config
4. **Opt-in Tier 3**: Connectivity validation only runs with `--verify-connection` flag
5. **Tiered validator**: Use fast `jq` fallback if ajv-cli unavailable

**Benchmark Target**:

- Cache hit: <10ms
- Full validation (no connectivity): <150ms
- With connectivity: <2000ms (acceptable, opt-in only)

---

### Risk 4: Secrets Committed to Git History

**Impact**: CRITICAL - Security breach, credential exposure

**Likelihood**: MEDIUM - Users may not understand secrets policy

**Mitigation**:

1. **Pre-commit hook**: Block commits with secret patterns (GitHub tokens, API keys)
2. **Documentation**: Clear security model documentation
3. **Error messages**: Explain why secrets don't belong in config, how to use env vars
4. **File permissions**: User config 600 (private), project config 644 (no secrets)
5. **Gitleaks integration**: Leverage existing gitleaks hook + custom AIDA patterns
6. **Detection guide**: Document how to detect and remove secrets from git history

**Contingency**: If secrets committed, provide clear remediation guide (revoke, rewrite history).

---

### Risk 5: JSON Schema Evolution Complexity

**Impact**: MEDIUM - Schema changes require migration, complex version management

**Likelihood**: MEDIUM - As new providers added, schema will evolve

**Mitigation**:

1. **Semantic versioning**: MAJOR.MINOR in `config_version` field
2. **Backward-compatible additions**: New optional fields = MINOR version bump (no migration)
3. **Breaking changes**: Remove/rename field = MAJOR version bump (migration required)
4. **Migration framework**: Reusable migration pattern for future schema changes
5. **Schema documentation**: Auto-generated docs from schema (always up-to-date)

**Contingency**: If schema change breaks configs, provide rollback to previous version.

---

## Testing Strategy

### Unit Testing

**Scope**: Individual functions in isolation

**Test Files**:

- `tests/unit/test-vcs-detection.sh` - VCS auto-detection with URL patterns
- `tests/unit/test-config-validation.sh` - Three-tier validation
- `tests/unit/test-config-merging.sh` - Hierarchical merge logic
- `tests/unit/test-secret-detection.sh` - Pre-commit hook patterns

**Key Test Cases**:

1. **VCS Detection**:
   - GitHub SSH/HTTPS (github.com, enterprise)
   - GitLab SSH/HTTPS (gitlab.com, self-hosted)
   - Bitbucket SSH/HTTPS
   - Invalid URLs (should gracefully fail)
   - Multiple remotes (use origin, warn about others)

2. **Validation**:
   - Valid configs (all providers)
   - Missing required fields (per provider)
   - Invalid field types (string vs number)
   - Unknown provider
   - Empty config (should use defaults)

3. **Merging**:
   - User config overrides system defaults
   - Project config overrides user config
   - Environment variables override all
   - Array merge (reviewers union)
   - Deep object merge (namespace-aware)

4. **Secret Detection**:
   - GitHub tokens (classic, fine-grained)
   - Jira tokens (context-aware)
   - Linear keys
   - Generic API keys
   - False positives (example values, placeholders)

---

### Integration Testing

**Scope**: End-to-end workflows with real config files

**Test Scenarios**:

1. **Fresh Install**: Generate config from template, validate, use in commands
2. **Migration**: Convert old config, validate migrated, verify data preservation
3. **Rollback**: Trigger migration failure, verify auto-rollback, check backup
4. **Multi-provider**: Test GitHub, GitLab, Bitbucket configs
5. **Pre-commit**: Stage config with secret, verify hook blocks commit

**Test Infrastructure**:

```bash
# tests/integration/test-config-workflow.sh

test_fresh_install() {
  # Setup: Clean environment
  rm -rf ~/.claude .aida

  # Run installer with auto-detection
  ./install.sh

  # Verify config created with detected values
  assert_file_exists .aida/config.json
  assert_equals "github" "$(jq -r '.vcs.provider' .aida/config.json)"

  # Validate config
  ./lib/installer-common/config-validator.sh .aida/config.json
  assert_exit_code 0
}
```

---

### Cross-Platform Testing

**Platforms**:

- macOS (BSD userland, stat -f)
- Linux (GNU userland, stat -c)
- Docker (Ubuntu 22, Ubuntu 20, Debian 12)

**Platform-Specific Test Cases**:

- `stat` command compatibility (macOS vs Linux)
- File permissions enforcement (600/644)
- `realpath` vs `readlink -f`
- Bash 3.2 compatibility (macOS default)

**CI/CD Integration**:

```yaml
# .github/workflows/test-config-system.yml
name: Config System Tests

on: [push, pull_request]

jobs:
  test-macos:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - run: tests/unit/test-vcs-detection.sh
      - run: tests/integration/test-config-workflow.sh

  test-linux:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        env: [ubuntu-22, ubuntu-20, debian-12]
    steps:
      - uses: actions/checkout@v4
      - run: .github/testing/test-install.sh --env ${{ matrix.env }}
```

---

### Edge Cases to Cover

**Critical Edge Cases**:

1. Empty config file → should use system defaults
2. Invalid JSON syntax → clear error with line number
3. Unknown provider → suggest valid providers
4. Missing git remote → gracefully fall back to manual config
5. Multiple remotes with different providers → use origin, warn
6. Config with extra fields (typos) → `additionalProperties: false` catches
7. Partial config (only vcs namespace) → merge with defaults
8. Circular references (future: config includes) → detect and error
9. Very large config file (>1MB) → performance test
10. Config with Unicode values → ensure proper encoding

---

## Open Technical Questions

### Q1: Should we vendor `jq` binary or require installation?

**Current**: Require installation (existing pattern in `validation.sh`)

**Recommendation**: **Keep requiring installation** (status quo)

**Rationale**:

- jq already required by existing code (aida-config-helper.sh uses it extensively)
- Cross-platform binary distribution complex (different architectures)
- Security risk (vendoring binaries requires signature verification)
- Installation simple on all platforms (brew, apt, yum all have jq)

**Alternative**: If vendoring desired, use GitHub releases with checksum verification.

---

### Q2: Should validation run on every command execution or only when config changes?

**Current**: Run on first command execution per shell session (cached)

**Recommendation**: **Cache validation results with checksum-based invalidation**

**Rationale**:

- Config changes infrequently (validation once per session is sufficient)
- Checksum detects config file changes (auto-invalidate cache)
- Performance budget: <10ms for cache hit, <150ms for cache miss
- Already implemented in existing aida-config-helper.sh

**Implementation**: Leverage existing `get_config_checksum()` infrastructure.

---

### Q3: How to handle schema evolution when adding new providers?

**Answer**: **Provider subsections are isolated, schema evolution is additive**

**Process**:

1. Add new enum value to `vcs.provider` (e.g., "gitea")
2. Add new subsection `vcs.gitea` with provider-specific fields
3. Add conditional validation (`if provider = gitea, then require gitea subsection`)
4. Increment MINOR version (backward-compatible addition)
5. Update auto-detection patterns in `vcs-detector.sh`

**No Breaking Changes** because:

- Existing provider configs unaffected
- `additionalProperties: false` only applies to top-level, not subsections
- New fields are optional (only required if provider selected)

---

### Q4: Should we support environment-specific configs (dev/staging/prod)?

**Current Scope**: Not in Issue #55 (defer to future)

**Recommendation**: **Defer to post-v1.0, but design namespace to support it**

**Future Design**:

```json
{
  "environments": {
    "dev": {
      "vcs": { "provider": "gitlab", "self_hosted_url": "https://gitlab.dev.internal" }
    },
    "staging": {
      "vcs": { "provider": "gitlab", "self_hosted_url": "https://gitlab.staging.internal" }
    },
    "prod": {
      "vcs": { "provider": "github", "owner": "prod-org", "repo": "prod-repo" }
    }
  }
}
```

**Usage**: `AIDA_ENV=staging aida command` → load `environments.staging.*` config

---

### Q5: Should auto-detection be opt-in or opt-out?

**PRD Decision**: **Opt-out** (auto-detection runs by default)

**Rationale**:

- Most users want convenience (auto-detect from git remote)
- Power users can disable with `vcs.auto_detect = false`
- Reduces manual configuration burden
- Detection metadata logged for troubleshooting

**Implementation**:

```json
{
  "vcs": {
    "auto_detect": true,  // Default: true
    "provider": "github"  // Overrides auto-detection if set
  }
}
```

**Behavior**:

- If `vcs.provider` empty AND `vcs.auto_detect = true`: Run auto-detection
- If `vcs.provider` set: Use explicit value, skip detection
- If `vcs.auto_detect = false`: Skip detection, require manual config

---

## Effort Estimate

### Overall Complexity: **MEDIUM-HIGH**

**Rationale**:

- Builds on existing infrastructure (aida-config-helper.sh proven)
- Well-scoped (foundation only, no provider implementations)
- Clear technical decisions (JSON Schema, three-tier validation)
- Established patterns (caching, validation, migration already exist in codebase)

**Risk Areas** (likely to exceed estimates):

- Migration script (complex jq transformations, edge cases)
- Integration testing (need comprehensive test coverage)
- Error message UX (iteration required for clarity)

---

### Component Breakdown with Hour Estimates

| Component | Complexity | Effort | Notes |
|-----------|-----------|--------|-------|
| **1. JSON Schema Design** | MEDIUM | 4-6h | Well-defined structure, conditional validation |
| **2. VCS Detector** | MEDIUM | 3-4h | Regex patterns, confidence scoring |
| **3. Config Validator (3 tiers)** | MEDIUM-HIGH | 6-8h | Tiered validation, error templates |
| **4. Config Migrator** | HIGH | 6-8h | Backup/rollback, jq transforms, edge cases |
| **5. aida-config-helper.sh Updates** | MEDIUM | 3-4h | Extend existing code with new namespaces |
| **6. Pre-commit Hook** | LOW | 2-3h | Secret pattern detection |
| **7. Template Configs** | LOW | 2-3h | Create 5 templates with examples |
| **8. Unit Tests** | MEDIUM | 6-8h | Detection, validation, merging, secrets |
| **9. Integration Tests** | HIGH | 8-10h | End-to-end workflows, cross-platform |
| **10. Documentation** | MEDIUM | 4-6h | Schema ref, security model, migration guide |
| **11. Installer Integration** | MEDIUM | 3-4h | Permissions, migration check, .gitignore |
| **TOTAL** | | **47-64h** | **~6-8 working days** |

---

### Critical Path

**Longest dependency chain** (cannot parallelize):

```text
1. JSON Schema Design (6h)
     ↓
2. VCS Detector (4h) ← Uses schema for validation
     ↓
3. Config Validator (8h) ← Uses detector for auto-detected values
     ↓
4. Config Migrator (8h) ← Uses validator for migrated config
     ↓
5. Integration Tests (10h) ← Tests all components together
     ↓
6. Documentation (6h) ← Documents finalized behavior

TOTAL CRITICAL PATH: ~42 hours (5-6 days)
```

**Parallelizable Work**:

- Pre-commit hook (independent)
- Template configs (independent)
- Unit tests (can start after each component completes)
- aida-config-helper.sh updates (can start after schema design)

---

### Phased Implementation

**Week 1: Core Infrastructure** (20-25 hours)

- JSON Schema design and validation (6h)
- VCS auto-detection function (4h)
- Config validator (Tier 1 + Tier 2) (8h)
- aida-config-helper.sh integration (4h)

**Week 2: Migration & Security** (20-25 hours)

- Config migration with rollback (8h)
- Pre-commit hook (secret detection) (3h)
- Template config files (3h)
- Unit tests (8h)

**Week 3: Testing & Documentation** (15-20 hours)

- Integration tests (10h)
- Cross-platform testing (Docker) (3h)
- Documentation (schema ref, security, migration) (6h)

**Week 4: Polish & Release** (5-10 hours)

- Installer integration (4h)
- Final testing and bug fixes (4h)
- Release preparation (2h)

#### Total: 60-80 hours (3-4 weeks)

---

## Success Criteria

**Issue #55 is COMPLETE when**:

1. ✅ **JSON Schema created** (`lib/installer-common/config-schema.json`)
   - Validation: All providers (GitHub, GitLab, Bitbucket, Jira, Linear)
   - IDE support: VS Code/IntelliJ autocomplete works
   - Documentation: Auto-generated schema reference exists

2. ✅ **VCS Auto-detection works** (`lib/installer-common/vcs-detector.sh`)
   - Detects: GitHub, GitLab, Bitbucket from git remote
   - Formats: SSH and HTTPS URLs supported
   - Confidence: Returns high/medium/low confidence score
   - Metadata: Logs detection method and timestamp

3. ✅ **Three-tier validation enforces rules** (`lib/installer-common/config-validator.sh`)
   - Tier 1: JSON Schema structure validation (exit code 1)
   - Tier 2: Provider-specific rules (exit code 2)
   - Tier 3: Connectivity checks (optional, exit code 3)
   - Error messages: Show auto-detected values, suggest fixes

4. ✅ **Hierarchical loading merges configs** (enhanced `aida-config-helper.sh`)
   - Load order: system → user → project → env vars → detected
   - Deep merge: Namespace-aware (vcs.*, work_tracker.*, team.*)
   - Array merge: Union for `team.default_reviewers`
   - Caching: Checksum-based invalidation (existing infrastructure)

5. ✅ **Migration script works** (`lib/installer-common/config-migration.sh`)
   - Transforms: `github.*` → `vcs.github.*`
   - Backup: Creates timestamped backup before migration
   - Validation: Validates migrated config before applying
   - Rollback: Auto-restores from backup on failure
   - Idempotent: Running twice produces same result

6. ✅ **Pre-commit hook detects secrets** (`.pre-commit-config.yaml` + `scripts/validate-config-security.sh`)
   - Patterns: GitHub, Jira, Linear, Anthropic tokens
   - Integration: Works with existing gitleaks hook
   - Errors: Clear explanation + remediation steps
   - Bypass: `git commit --no-verify` documented

7. ✅ **Template configs created** (`templates/config/*.json`)
   - Templates: GitHub simple, GitHub enterprise, GitLab+Jira, Bitbucket
   - Placeholders: Clear instructions for user-specific values
   - Examples: Real-world use cases covered

8. ✅ **Tests pass** (unit + integration + cross-platform)
   - Unit: 50+ test cases (detection, validation, merging, secrets)
   - Integration: End-to-end workflows (fresh install, migration, rollback)
   - Cross-platform: macOS + Linux (Ubuntu 22, Ubuntu 20, Debian 12)
   - CI/CD: GitHub Actions workflows passing

9. ✅ **Documentation complete**
   - Schema reference: Auto-generated from JSON Schema
   - Security model: Secret management, file permissions, audit trail
   - Provider patterns: Auto-detection, validation, extensibility
   - Migration guide: v0 → v1 with examples and troubleshooting

---

## Related Files

**New Files** (to be created):

- `/Users/rob/Develop/oakensoul/claude-personal-assistant/lib/installer-common/config-schema.json`
- `/Users/rob/Develop/oakensoul/claude-personal-assistant/lib/installer-common/vcs-detector.sh`
- `/Users/rob/Develop/oakensoul/claude-personal-assistant/lib/installer-common/config-validator.sh`
- `/Users/rob/Develop/oakensoul/claude-personal-assistant/lib/installer-common/config-migration.sh`
- `/Users/rob/Develop/oakensoul/claude-personal-assistant/scripts/validate-config-security.sh`
- `/Users/rob/Develop/oakensoul/claude-personal-assistant/templates/config/*.json`

**Modified Files**:

- `/Users/rob/Develop/oakensoul/claude-personal-assistant/lib/aida-config-helper.sh`
- `/Users/rob/Develop/oakensoul/claude-personal-assistant/.pre-commit-config.yaml`
- `/Users/rob/Develop/oakensoul/claude-personal-assistant/install.sh`

**Documentation**:

- `/Users/rob/Develop/oakensoul/claude-personal-assistant/docs/configuration/schema-reference.md`
- `/Users/rob/Develop/oakensoul/claude-personal-assistant/docs/configuration/security-model.md`
- `/Users/rob/Develop/oakensoul/claude-personal-assistant/docs/integration/vcs-providers.md`
- `/Users/rob/Develop/oakensoul/claude-personal-assistant/docs/migration/v0-to-v1-config.md`

---

## Coordination Required

**Before Implementation**:

- **Tech Lead**: Approve schema design, namespace structure, migration strategy
- **Security Engineer**: Review secret detection patterns, file permission strategy
- **UX Designer**: Review error message templates, validation feedback

**During Implementation**:

- **DevOps Engineer**: CI/CD integration for config validation in workflows
- **QA Engineer**: Test coverage strategy, cross-platform testing approach

**After Implementation**:

- **Integration Specialist**: Provider interface specification for Issues #56-59
- **Documentation Team**: Review schema docs and migration guide

---

## Next Steps

**Immediate Actions** (Before Implementation):

1. Create feature branch: `feature/issue-55-config-system`
2. Create directory structure: `lib/installer-common/`, `templates/config/`
3. Draft JSON Schema with basic structure (vcs.*, work_tracker.*, team.*)
4. Prototype VCS detector with GitHub URL patterns
5. Set up test infrastructure: `tests/unit/`, `tests/integration/`, `tests/fixtures/`

**Implementation Sequence**:

1. **Day 1-2**: JSON Schema design → VCS detector → Config validator (Tier 1+2)
2. **Day 3-4**: Config migrator → aida-config-helper.sh integration → Pre-commit hook
3. **Day 5-6**: Unit tests → Integration tests → Template configs
4. **Day 7-8**: Cross-platform testing → Documentation → Installer integration
5. **Day 9-10**: Final testing → Bug fixes → Release preparation

**Success Metrics**:

- All tests pass (unit, integration, cross-platform)
- Schema validates correctly (ajv-cli validation passes)
- Migration succeeds on 10+ real-world configs
- Pre-commit hook catches all secret patterns
- Documentation is clear and comprehensive

---

**Prepared by**: Tech Lead Agent (synthesized from 6 technical analyses)
**Reviewed by**: (Pending approval)
**Status**: Draft - Ready for implementation
