---
title: "DevOps Engineer Analysis - Configuration System (#55)"
issue: 55
analyst: "devops-engineer"
analysis_date: "2025-10-20"
category: "technical"
status: "draft"
---

# DevOps Engineer Analysis: Configuration System with VCS Abstraction

## Executive Summary

Issue #55 introduces a foundational configuration system that will impact deployment pipelines, CI/CD workflows, containerized testing, and operational procedures. The migration from `github.*` to `vcs.*` namespace presents both technical challenges and opportunities for improving deployment automation.

**Key Concerns**:

- **Breaking changes** to existing installations require robust auto-migration
- **CI/CD integration** needs environment-aware configuration loading
- **Docker testing** infrastructure must validate migration paths
- **Pre-commit hooks** must prevent config secrets in VCS
- **Rollback strategy** critical for failed migrations

**Recommendation**: Implement phased rollout with auto-migration, extensive testing infrastructure, and clear rollback procedures.

## 1. Implementation Approach

### 1.1 Auto-Migration Strategy

**Current State**:

- Users have `~/.claude/workflow-config.json` (not tracked)
- Config uses `github.*` namespace
- No formal migration tooling exists

**Proposed Migration Flow**:

```bash
# Detection phase (run on ANY AIDA command execution)
if [[ -f ~/.claude/workflow-config.json ]]; then
  config_version=$(jq -r '.config_version // "0.0"' ~/.claude/workflow-config.json)

  if [[ "$config_version" == "0.0" ]]; then
    # Old format detected - needs migration
    log "⚠️  Detected v1.0 configuration format"
    log "🔄 Migrating to v2.0 format..."

    # Backup (CRITICAL)
    backup_config ~/.claude/workflow-config.json

    # Migrate namespace: github.* → vcs.github.*
    migrate_github_to_vcs

    # Add config_version field
    add_config_version "1.0"

    # Validate migrated config
    if validate_config_schema; then
      log "✅ Migration successful"
      log "📦 Backup saved to: ${BACKUP_PATH}"
    else
      log "❌ Migration validation failed"
      restore_config_from_backup
      exit 1
    fi
  fi
fi
```

**Migration Script** (`lib/installer-common/migrate-config.sh`):

```bash
#!/usr/bin/env bash
#
# migrate-config.sh - Auto-migration for config schema changes
#
# Migrates v1 (github.*) to v2 (vcs.github.*) format
#

migrate_github_to_vcs() {
  local config_file="$1"
  local backup_file="${config_file}.backup.$(date +%Y%m%d-%H%M%S)"

  # Backup FIRST (no exceptions)
  cp "$config_file" "$backup_file" || {
    echo "❌ Failed to create backup"
    return 1
  }

  # Transform: github.* → vcs.github.*
  jq '
    {
      "config_version": "1.0",
      "vcs": {
        "provider": "github",
        "owner": .github.owner,
        "repo": .github.repo,
        "main_branch": (.github.main_branch // "main"),
        "github": {
          "enterprise_url": (.github.enterprise_url // null)
        }
      },
      "work_tracker": {
        "provider": "github_issues",
        "github_issues": {
          "enabled": true
        }
      },
      "team": {
        "review_strategy": (.github.review_strategy // "list"),
        "default_reviewers": (.github.default_reviewers // [])
      },
      "workflow": {
        "commit": {
          "auto_commit": (.github.auto_commit // true)
        },
        "pr": {
          "auto_version_bump": (.github.auto_version_bump // true),
          "update_changelog": (.github.update_changelog // true),
          "draft_by_default": (.github.draft_by_default // false)
        }
      }
    }
  ' "$config_file" > "${config_file}.tmp"

  # Validate transformed JSON
  if jq empty "${config_file}.tmp" 2>/dev/null; then
    mv "${config_file}.tmp" "$config_file"
    echo "✅ Migration successful. Backup: $backup_file"
    return 0
  else
    echo "❌ Migration produced invalid JSON"
    rm -f "${config_file}.tmp"
    return 1
  fi
}
```

**Auto-Migration Trigger Points**:

1. **Installation** - `install.sh` runs migration check
2. **Command execution** - Every slash command checks config version
3. **Manual** - `aida-config-helper.sh --migrate` for user control

**Rollback Procedure**:

```bash
# If migration fails or causes issues
restore_config_from_backup() {
  local latest_backup
  latest_backup=$(ls -t ~/.claude/workflow-config.json.backup.* 2>/dev/null | head -1)

  if [[ -n "$latest_backup" ]]; then
    cp "$latest_backup" ~/.claude/workflow-config.json
    echo "✅ Restored config from: $latest_backup"
    return 0
  else
    echo "❌ No backup found"
    return 1
  fi
}
```

### 1.2 CI/CD Configuration Injection

**Problem**: CI/CD environments need config without user prompts or file state.

**Solution**: Environment variable override system

**Implementation**:

```bash
# aida-config-helper.sh additions

#######################################
# Load configuration with CI/CD environment awareness
# Order: Files → Environment Variables → Auto-detection
#######################################
load_config_with_env_overrides() {
  local config_json

  # 1. Load from files (hierarchical merge)
  config_json=$(load_hierarchical_config)

  # 2. Override with environment variables (CI/CD)
  if [[ -n "${AIDA_VCS_PROVIDER:-}" ]]; then
    config_json=$(echo "$config_json" | jq \
      --arg provider "$AIDA_VCS_PROVIDER" \
      '.vcs.provider = $provider')
  fi

  if [[ -n "${AIDA_VCS_OWNER:-}" ]]; then
    config_json=$(echo "$config_json" | jq \
      --arg owner "$AIDA_VCS_OWNER" \
      '.vcs.owner = $owner')
  fi

  if [[ -n "${AIDA_VCS_REPO:-}" ]]; then
    config_json=$(echo "$config_json" | jq \
      --arg repo "$AIDA_VCS_REPO" \
      '.vcs.repo = $repo')
  fi

  # 3. Auto-detect if still missing (local dev)
  if [[ "$(echo "$config_json" | jq -r '.vcs.provider // "null"')" == "null" ]]; then
    config_json=$(auto_detect_vcs "$config_json")
  fi

  echo "$config_json"
}
```

**GitHub Actions Integration**:

```yaml
# .github/workflows/test-installation.yml additions

env:
  # Config overrides for CI environment
  AIDA_VCS_PROVIDER: "github"
  AIDA_VCS_OWNER: "${{ github.repository_owner }}"
  AIDA_VCS_REPO: "${{ github.event.repository.name }}"
  AIDA_VCS_MAIN_BRANCH: "main"

  # Prevent interactive prompts
  CI: "true"
  AIDA_NON_INTERACTIVE: "true"

jobs:
  test-config-migration:
    name: Test Config Migration
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Create old-format config
        run: |
          mkdir -p ~/.claude
          cat > ~/.claude/workflow-config.json <<'EOF'
          {
            "github": {
              "owner": "test-owner",
              "repo": "test-repo",
              "main_branch": "main"
            }
          }
          EOF

      - name: Run migration
        run: |
          ./lib/installer-common/migrate-config.sh ~/.claude/workflow-config.json

      - name: Validate migrated config
        run: |
          # Check config_version field exists
          version=$(jq -r '.config_version' ~/.claude/workflow-config.json)
          [[ "$version" == "1.0" ]] || exit 1

          # Check namespace migration
          provider=$(jq -r '.vcs.provider' ~/.claude/workflow-config.json)
          [[ "$provider" == "github" ]] || exit 1

          # Check data preservation
          owner=$(jq -r '.vcs.owner' ~/.claude/workflow-config.json)
          [[ "$owner" == "test-owner" ]] || exit 1

          echo "✅ Migration validation passed"

      - name: Test rollback
        run: |
          # Simulate failed migration
          echo "invalid json" > ~/.claude/workflow-config.json

          # Restore from backup
          ./scripts/restore-config-backup.sh

          # Verify restoration
          jq empty ~/.claude/workflow-config.json || exit 1
```

### 1.3 Docker/Container Config Patterns

**Challenge**: Docker testing needs config isolation per environment.

**Solution**: Volume-mounted config fixtures with environment-specific overrides.

**Implementation**:

```dockerfile
# .github/testing/Dockerfile.ubuntu-22.04 additions

# Copy test fixtures into container
COPY .github/testing/fixtures/configs/v1-github-format.json /tmp/test-config-v1.json
COPY .github/testing/fixtures/configs/v2-vcs-format.json /tmp/test-config-v2.json

# Test migration in isolated environment
RUN mkdir -p /root/.claude && \
    cp /tmp/test-config-v1.json /root/.claude/workflow-config.json && \
    /root/.aida/lib/installer-common/migrate-config.sh /root/.claude/workflow-config.json && \
    /root/.aida/lib/aida-config-helper.sh --validate
```

**Docker Compose for Multi-Environment Testing**:

```yaml
# .github/testing/docker-compose.yml additions

services:
  test-migration-ubuntu-22:
    build:
      context: ../..
      dockerfile: .github/testing/Dockerfile.ubuntu-22.04
    environment:
      - AIDA_VCS_PROVIDER=github
      - AIDA_VCS_OWNER=oakensoul
      - AIDA_VCS_REPO=claude-personal-assistant
    volumes:
      - ./fixtures/configs:/tmp/test-configs:ro
    command: |
      bash -c "
        echo '📋 Testing v1 → v2 migration...'
        cp /tmp/test-configs/v1-github-format.json ~/.claude/workflow-config.json
        /root/.aida/lib/installer-common/migrate-config.sh ~/.claude/workflow-config.json
        /root/.aida/lib/aida-config-helper.sh --validate
      "

  test-env-overrides:
    build:
      context: ../..
      dockerfile: .github/testing/Dockerfile.ubuntu-22.04
    environment:
      - AIDA_VCS_PROVIDER=gitlab
      - AIDA_VCS_OWNER=test-group
      - AIDA_VCS_REPO=test-project
      - AIDA_VCS_GITLAB_PROJECT_ID=12345
    command: |
      bash -c "
        echo '📋 Testing environment variable overrides...'
        config=$(/root/.aida/lib/aida-config-helper.sh)
        provider=$(echo \$config | jq -r '.vcs.provider')
        [[ \$provider == 'gitlab' ]] || exit 1
        echo '✅ Environment overrides working'
      "
```

### 1.4 Config File Distribution (Templates in Installer)

**Template Config Files**:

```bash
# templates/config/workflow-config.template.json
{
  "config_version": "1.0",
  "vcs": {
    "provider": "{{VCS_PROVIDER}}",
    "owner": "{{VCS_OWNER}}",
    "repo": "{{VCS_REPO}}",
    "main_branch": "{{MAIN_BRANCH}}",
    "github": {
      "enterprise_url": null
    }
  },
  "work_tracker": {
    "provider": "github_issues"
  },
  "team": {
    "review_strategy": "list",
    "default_reviewers": []
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

**Installer Integration** (`install.sh` additions):

```bash
# In main() function, after create_directories()

# Generate initial config from template with auto-detection
print_message "info" "Generating configuration..."

# Auto-detect VCS from git remote if in repository
if git rev-parse --git-dir >/dev/null 2>&1; then
  VCS_INFO=$(detect_vcs_from_git_remote)
  VCS_PROVIDER=$(echo "$VCS_INFO" | jq -r '.provider')
  VCS_OWNER=$(echo "$VCS_INFO" | jq -r '.owner')
  VCS_REPO=$(echo "$VCS_INFO" | jq -r '.repo')
  MAIN_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")
else
  # Not in git repo - use placeholders
  VCS_PROVIDER="github"
  VCS_OWNER="your-username"
  VCS_REPO="your-repository"
  MAIN_BRANCH="main"
fi

# Substitute template variables
sed "s/{{VCS_PROVIDER}}/${VCS_PROVIDER}/g; \
     s/{{VCS_OWNER}}/${VCS_OWNER}/g; \
     s/{{VCS_REPO}}/${VCS_REPO}/g; \
     s/{{MAIN_BRANCH}}/${MAIN_BRANCH}/g" \
  "${SCRIPT_DIR}/templates/config/workflow-config.template.json" \
  > "${CLAUDE_DIR}/workflow-config.json"

print_message "success" "Configuration generated with auto-detected values"
```

## 2. Technical Concerns

### 2.1 Breaking Changes to Existing Setups

**Impact Analysis**:

| Component | Breaking Change | Mitigation |
|-----------|----------------|------------|
| Slash commands | Expect `vcs.*` namespace | Auto-migration on first run |
| `aida-config-helper.sh` | New namespace structure | Backward compat layer (2 versions) |
| User scripts | Hardcoded `github.*` refs | Deprecation warnings + docs |
| Documentation | All examples use old format | Update in same PR |

**Backward Compatibility Layer** (temporary, 2 minor versions):

```bash
# aida-config-helper.sh additions

get_config_value_with_fallback() {
  local key="$1"
  local config_json="$2"

  # Try new namespace first
  local value
  value=$(echo "$config_json" | jq -r ".$key // null")

  if [[ "$value" == "null" ]]; then
    # Fallback to old namespace (github.* → vcs.github.*)
    local old_key="${key#vcs.github.}"
    if [[ "$key" =~ ^vcs\.github\. ]]; then
      value=$(echo "$config_json" | jq -r ".github.$old_key // null")

      if [[ "$value" != "null" ]]; then
        # Found in old namespace - warn user
        print_message "warning" "Deprecated config key: github.$old_key"
        print_message "warning" "Please run: aida-config-helper.sh --migrate"
      fi
    fi
  fi

  echo "$value"
}
```

**Deprecation Timeline**:

- **v0.2.0** - Introduce `vcs.*`, auto-migrate, support both formats
- **v0.3.0** - Deprecation warnings for `github.*` usage
- **v0.4.0** - Remove `github.*` support entirely

### 2.2 CI/CD Environment Detection vs Local Dev

**Challenge**: Distinguish between CI environment (non-interactive) and local dev (interactive prompts OK).

**Detection Strategy**:

```bash
is_ci_environment() {
  # Check multiple CI indicators
  [[ -n "${CI:-}" ]] || \
  [[ -n "${GITHUB_ACTIONS:-}" ]] || \
  [[ -n "${GITLAB_CI:-}" ]] || \
  [[ -n "${JENKINS_HOME:-}" ]] || \
  [[ -n "${CIRCLECI:-}" ]] || \
  [[ "$AIDA_NON_INTERACTIVE" == "true" ]]
}

load_config_smart() {
  if is_ci_environment; then
    # CI: Fail fast if config invalid, no prompts
    config=$(load_config_with_env_overrides)
    validate_config "$config" || {
      echo "❌ Config validation failed in CI"
      echo "Set AIDA_VCS_* environment variables or commit valid config"
      exit 1
    }
  else
    # Local dev: Interactive fallback
    config=$(load_config_with_env_overrides)
    if ! validate_config "$config" 2>/dev/null; then
      echo "⚠️  Config incomplete or invalid"
      echo "Run '/aida-init' to configure interactively"
      exit 1
    fi
  fi

  echo "$config"
}
```

**GitHub Actions Best Practices**:

```yaml
# Recommended approach for AIDA workflows in CI

env:
  # Force non-interactive mode
  CI: "true"

  # Config overrides (prevents file dependency)
  AIDA_VCS_PROVIDER: "github"
  AIDA_VCS_OWNER: "${{ github.repository_owner }}"
  AIDA_VCS_REPO: "${{ github.event.repository.name }}"

  # Secrets via environment (NEVER in config files)
  GITHUB_TOKEN: "${{ secrets.GITHUB_TOKEN }}"

jobs:
  deploy:
    steps:
      - name: Validate AIDA config
        run: |
          # This should succeed using env vars only
          /root/.aida/lib/aida-config-helper.sh --validate
```

### 2.3 Config Validation in Pre-Commit Hooks

**Requirement**: Prevent secrets in config files before commit.

**Implementation** (`.pre-commit-config.yaml` additions):

```yaml
repos:
  # Existing gitleaks hook (general secret detection)
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.18.2
    hooks:
      - id: gitleaks
        name: Detect secrets and credentials

  # AIDA-specific config validation
  - repo: local
    hooks:
      - id: validate-aida-config
        name: Validate AIDA config files
        description: |
          Check config files for:
          - Secret patterns (tokens, API keys)
          - Valid JSON schema
          - Required fields per provider
        entry: scripts/validate-config-pre-commit.sh
        language: script
        files: '(workflow-config\.json|config\.json|\.aida/config\.json)$'
        pass_filenames: true
        verbose: true
```

**Validation Script** (`scripts/validate-config-pre-commit.sh`):

```bash
#!/usr/bin/env bash
#
# validate-config-pre-commit.sh - Pre-commit hook for config validation
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Source validation library
source "${REPO_ROOT}/lib/installer-common/logging.sh"

validate_config_file() {
  local file="$1"
  local errors=0

  echo "🔍 Validating: $file"

  # 1. JSON syntax
  if ! jq empty "$file" 2>/dev/null; then
    echo "❌ Invalid JSON syntax"
    errors=$((errors + 1))
  fi

  # 2. Secret patterns (CRITICAL - blocks commit)
  local secret_patterns=(
    'ghp_[a-zA-Z0-9]{36}'           # GitHub personal access token
    'ghs_[a-zA-Z0-9]{36}'           # GitHub server token
    '"token":\s*"[^"]+"'            # Generic token field with value
    '"api_key":\s*"[^"]+"'          # API key field with value
    '"password":\s*"[^"]+"'         # Password field with value
    '"secret":\s*"[^"]+"'           # Secret field with value
  )

  for pattern in "${secret_patterns[@]}"; do
    if grep -qE "$pattern" "$file"; then
      echo "❌ BLOCKED: Secret pattern detected: $pattern"
      echo "   Config files should reference env var NAMES, not VALUES"
      echo "   Example: \"token_var\": \"GITHUB_TOKEN\" (not the token itself)"
      errors=$((errors + 1))
    fi
  done

  # 3. Schema validation (structure + required fields)
  if jq empty "$file" 2>/dev/null; then
    # Check config_version field
    version=$(jq -r '.config_version // "missing"' "$file")
    if [[ "$version" == "missing" ]]; then
      echo "⚠️  Warning: Missing config_version field (auto-migration will add)"
    fi

    # Provider-specific validation
    provider=$(jq -r '.vcs.provider // "null"' "$file")
    if [[ "$provider" != "null" ]]; then
      case "$provider" in
        github)
          # Check required GitHub fields
          for field in owner repo; do
            value=$(jq -r ".vcs.$field // \"null\"" "$file")
            if [[ "$value" == "null" ]]; then
              echo "❌ Missing required field: vcs.$field (provider: github)"
              errors=$((errors + 1))
            fi
          done
          ;;
        gitlab)
          # Check required GitLab fields
          for field in project_id owner repo; do
            value=$(jq -r ".vcs.$field // \"null\"" "$file")
            if [[ "$value" == "null" ]]; then
              echo "❌ Missing required field: vcs.$field (provider: gitlab)"
              errors=$((errors + 1))
            fi
          done
          ;;
        bitbucket)
          # Check required Bitbucket fields
          for field in workspace repo_slug; do
            value=$(jq -r ".vcs.bitbucket.$field // \"null\"" "$file")
            if [[ "$value" == "null" ]]; then
              echo "❌ Missing required field: vcs.bitbucket.$field"
              errors=$((errors + 1))
            fi
          done
          ;;
      esac
    fi
  fi

  if [[ $errors -eq 0 ]]; then
    echo "✅ Config validation passed"
    return 0
  else
    echo "❌ Config validation failed: $errors error(s)"
    return 1
  fi
}

# Validate all config files passed by pre-commit
exit_code=0
for file in "$@"; do
  if [[ -f "$file" ]]; then
    if ! validate_config_file "$file"; then
      exit_code=1
    fi
  fi
done

exit $exit_code
```

**Testing Pre-Commit Hook**:

```bash
# Test locally
pre-commit run validate-aida-config --files ~/.claude/workflow-config.json

# Test in CI (GitHub Actions)
- name: Run pre-commit hooks
  run: |
    pip install pre-commit
    pre-commit run --all-files
```

### 2.4 Rollback if Migration Fails

**Failure Scenarios**:

1. **JSON transformation error** - `jq` produces invalid JSON
2. **Data loss** - Required fields missing after migration
3. **Validation failure** - Migrated config doesn't pass schema validation
4. **User error** - User manually edits during migration

**Rollback Strategy**:

```bash
# Full migration workflow with rollback safety

migrate_with_rollback() {
  local config_file="$1"
  local backup_file="${config_file}.backup.$(date +%Y%m%d-%H%M%S)"
  local temp_file="${config_file}.migrating"

  # Step 1: Backup (CRITICAL - never skip)
  echo "📦 Creating backup: $backup_file"
  cp "$config_file" "$backup_file" || {
    echo "❌ FATAL: Cannot create backup. Migration aborted."
    return 1
  }

  # Step 2: Migrate to temp file (preserve original)
  echo "🔄 Migrating configuration..."
  if ! migrate_github_to_vcs "$config_file" > "$temp_file"; then
    echo "❌ Migration transformation failed"
    rm -f "$temp_file"
    echo "✅ Original config preserved (no changes made)"
    return 1
  fi

  # Step 3: Validate migrated config
  echo "✅ Validating migrated configuration..."
  if ! validate_config_schema "$temp_file"; then
    echo "❌ Migrated config failed validation"
    echo "📋 Validation errors:"
    validate_config_schema "$temp_file" 2>&1 | sed 's/^/   /'
    rm -f "$temp_file"
    echo "✅ Original config preserved (no changes made)"
    return 1
  fi

  # Step 4: Verify data integrity (compare key fields)
  local old_owner new_owner
  old_owner=$(jq -r '.github.owner // "null"' "$config_file")
  new_owner=$(jq -r '.vcs.owner // "null"' "$temp_file")

  if [[ "$old_owner" != "$new_owner" ]]; then
    echo "❌ Data integrity check failed"
    echo "   Expected owner: $old_owner"
    echo "   Migrated owner: $new_owner"
    rm -f "$temp_file"
    echo "✅ Original config preserved (no changes made)"
    return 1
  fi

  # Step 5: Atomic replacement (all validations passed)
  echo "✅ All checks passed. Applying migration..."
  mv "$temp_file" "$config_file" || {
    echo "❌ Failed to replace config file"
    echo "🔧 Manual recovery required:"
    echo "   cp $backup_file $config_file"
    return 1
  }

  echo "✅ Migration completed successfully"
  echo "📦 Backup: $backup_file"
  echo "🔧 To rollback: cp $backup_file $config_file"
  return 0
}

# Automatic rollback on any error
migrate_with_auto_rollback() {
  local config_file="$1"

  if ! migrate_with_rollback "$config_file"; then
    echo ""
    echo "⚠️  Migration failed. No changes were made to your config."
    echo "📁 Original config: $config_file"
    echo "🆘 Need help? https://github.com/oakensoul/claude-personal-assistant/issues/55"
    return 1
  fi

  return 0
}
```

**User-Facing Rollback Command**:

```bash
# scripts/rollback-config.sh

#!/usr/bin/env bash
#
# rollback-config.sh - Restore config from most recent backup
#

set -euo pipefail

CONFIG_FILE="${HOME}/.claude/workflow-config.json"

# Find most recent backup
LATEST_BACKUP=$(ls -t "${CONFIG_FILE}.backup."* 2>/dev/null | head -1)

if [[ -z "$LATEST_BACKUP" ]]; then
  echo "❌ No backup found"
  echo "   Looked for: ${CONFIG_FILE}.backup.*"
  exit 1
fi

echo "📦 Found backup: $LATEST_BACKUP"
echo "📅 Created: $(stat -f '%Sm' "$LATEST_BACKUP" 2>/dev/null || stat -c '%y' "$LATEST_BACKUP")"
echo ""
read -p "Restore this backup? [y/N] " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
  cp "$LATEST_BACKUP" "$CONFIG_FILE"
  echo "✅ Config restored from backup"
  echo "📁 Current config: $CONFIG_FILE"
else
  echo "❌ Rollback cancelled"
  exit 1
fi
```

## 3. Dependencies & Integration

### 3.1 GitHub Actions Workflow Updates

**Required Changes**:

**File**: `.github/workflows/test-installation.yml`

```yaml
# Add config migration testing job

jobs:
  test-config-migration:
    name: Test Config Migration (v1 → v2)
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install dependencies
        run: sudo apt-get update && sudo apt-get install -y jq

      - name: Create v1 config fixture
        run: |
          mkdir -p ~/.claude
          cat > ~/.claude/workflow-config.json <<'EOF'
          {
            "github": {
              "owner": "oakensoul",
              "repo": "claude-personal-assistant",
              "main_branch": "main",
              "default_reviewers": ["reviewer1"],
              "auto_commit": true
            }
          }
          EOF

      - name: Run migration
        run: |
          bash lib/installer-common/migrate-config.sh ~/.claude/workflow-config.json

      - name: Validate migration
        run: |
          # Schema validation
          bash lib/aida-config-helper.sh --validate

          # Data integrity checks
          config=$(cat ~/.claude/workflow-config.json)

          # Check config_version added
          [[ $(echo "$config" | jq -r '.config_version') == "1.0" ]] || exit 1

          # Check namespace migration
          [[ $(echo "$config" | jq -r '.vcs.provider') == "github" ]] || exit 1
          [[ $(echo "$config" | jq -r '.vcs.owner') == "oakensoul" ]] || exit 1
          [[ $(echo "$config" | jq -r '.vcs.repo') == "claude-personal-assistant" ]] || exit 1

          # Check data preservation
          [[ $(echo "$config" | jq -r '.team.default_reviewers[0]') == "reviewer1" ]] || exit 1
          [[ $(echo "$config" | jq -r '.workflow.commit.auto_commit') == "true" ]] || exit 1

          echo "✅ Migration validation passed"

      - name: Verify backup created
        run: |
          ls -la ~/.claude/workflow-config.json.backup.* || {
            echo "❌ No backup file created"
            exit 1
          }
          echo "✅ Backup file exists"

  # Add to existing test-summary job dependencies
  test-summary:
    needs:
      - lint
      - test-macos
      - test-windows-wsl
      - test-linux-docker
      - test-full-suite
      - test-config-migration  # NEW
```

**File**: `.github/workflows/lint.yml`

```yaml
# Add config validation to lint workflow

jobs:
  lint-configs:
    name: Lint Config Files
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install jq
        run: sudo apt-get update && sudo apt-get install -y jq

      - name: Validate template configs
        run: |
          # Check all template config files
          find templates/config -name "*.json" -type f | while read -r config; do
            echo "Validating: $config"
            jq empty "$config" || exit 1
          done
          echo "✅ All template configs valid"

      - name: Check for secrets in configs
        run: |
          # Run secret detection on config files
          if grep -rE '(ghp_|ghs_)[a-zA-Z0-9]{36}' templates/config/; then
            echo "❌ GitHub token pattern found in config templates"
            exit 1
          fi
          echo "✅ No secrets detected in config templates"
```

### 3.2 Docker Testing Infrastructure Changes

**Required Docker Fixture Files**:

```bash
# Create test config fixtures
mkdir -p .github/testing/fixtures/configs

# v1 format (old)
cat > .github/testing/fixtures/configs/v1-github-format.json <<'EOF'
{
  "github": {
    "owner": "test-user",
    "repo": "test-repo",
    "main_branch": "main",
    "default_reviewers": ["reviewer1", "reviewer2"],
    "auto_commit": true,
    "auto_version_bump": true,
    "enterprise_url": null
  }
}
EOF

# v2 format (new)
cat > .github/testing/fixtures/configs/v2-vcs-format.json <<'EOF'
{
  "config_version": "1.0",
  "vcs": {
    "provider": "github",
    "owner": "test-user",
    "repo": "test-repo",
    "main_branch": "main",
    "github": {
      "enterprise_url": null
    }
  },
  "work_tracker": {
    "provider": "github_issues"
  },
  "team": {
    "review_strategy": "list",
    "default_reviewers": ["reviewer1", "reviewer2"]
  },
  "workflow": {
    "commit": {
      "auto_commit": true
    },
    "pr": {
      "auto_version_bump": true,
      "update_changelog": true
    }
  }
}
EOF
```

**Docker Test Script Updates** (`.github/testing/test-install.sh`):

```bash
# Add migration testing scenario

test_config_migration() {
  local env="$1"
  local dockerfile
  dockerfile=$(get_dockerfile "$env")

  echo "🧪 Testing config migration in $env..."

  docker run --rm \
    -v "${REPO_ROOT}/.github/testing/fixtures/configs:/tmp/test-configs:ro" \
    -e TEST_SCENARIO="migration" \
    "aida-test:${env}" \
    bash -c '
      # Setup v1 config
      mkdir -p ~/.claude
      cp /tmp/test-configs/v1-github-format.json ~/.claude/workflow-config.json

      # Run migration
      bash /root/.aida/lib/installer-common/migrate-config.sh ~/.claude/workflow-config.json

      # Validate result
      bash /root/.aida/lib/aida-config-helper.sh --validate || exit 1

      # Check backup exists
      ls ~/.claude/workflow-config.json.backup.* || exit 1

      echo "✅ Migration test passed"
    '

  if [[ $? -eq 0 ]]; then
    echo "✅ Migration test passed: $env"
    return 0
  else
    echo "❌ Migration test failed: $env"
    return 1
  fi
}

# Add to main test suite
main() {
  # ... existing tests ...

  # Add migration test
  for env in "${environments[@]}"; do
    test_config_migration "$env" || TESTS_FAILED=$((TESTS_FAILED + 1))
  done
}
```

### 3.3 Installation Script Modifications

**File**: `install.sh`

```bash
# Add after create_directories() call

# Auto-detect VCS and generate initial config
print_message "info" "Detecting VCS configuration..."

if [[ -d .git ]]; then
  # In git repository - auto-detect
  VCS_DETECTION=$("${SCRIPT_DIR}/lib/installer-common/detect-vcs.sh")

  print_message "success" "VCS auto-detected:"
  echo "  Provider: $(echo "$VCS_DETECTION" | jq -r '.provider')"
  echo "  Owner:    $(echo "$VCS_DETECTION" | jq -r '.owner')"
  echo "  Repo:     $(echo "$VCS_DETECTION" | jq -r '.repo')"
  echo ""

  # Generate config from template with detected values
  "${SCRIPT_DIR}/lib/installer-common/generate-config.sh" \
    --template "${SCRIPT_DIR}/templates/config/workflow-config.template.json" \
    --output "${CLAUDE_DIR}/workflow-config.json" \
    --from-json "$VCS_DETECTION"
else
  # Not in git repo - use placeholder template
  print_message "info" "Not in git repository - creating placeholder config"

  cp "${SCRIPT_DIR}/templates/config/workflow-config.template.json" \
     "${CLAUDE_DIR}/workflow-config.json"

  print_message "warning" "Run '/aida-init' to configure VCS settings"
fi

echo ""
```

**New Script**: `lib/installer-common/detect-vcs.sh`

```bash
#!/usr/bin/env bash
#
# detect-vcs.sh - Auto-detect VCS provider from git remote
#

set -euo pipefail

detect_vcs_from_git_remote() {
  local remote_url
  remote_url=$(git config --get remote.origin.url 2>/dev/null || echo "")

  if [[ -z "$remote_url" ]]; then
    echo '{"error": "No git remote found", "provider": null}'
    return 1
  fi

  local provider owner repo

  # GitHub patterns
  if [[ "$remote_url" =~ github\.com[:/]([^/]+)/([^/]+)(\.git)?$ ]]; then
    provider="github"
    owner="${BASH_REMATCH[1]}"
    repo="${BASH_REMATCH[2]%.git}"  # Remove .git suffix

  # GitLab patterns
  elif [[ "$remote_url" =~ gitlab\.com[:/]([^/]+)/([^/]+)(\.git)?$ ]]; then
    provider="gitlab"
    owner="${BASH_REMATCH[1]}"
    repo="${BASH_REMATCH[2]%.git}"

  # Bitbucket patterns
  elif [[ "$remote_url" =~ bitbucket\.org[:/]([^/]+)/([^/]+)(\.git)?$ ]]; then
    provider="bitbucket"
    owner="${BASH_REMATCH[1]}"
    repo="${BASH_REMATCH[2]%.git}"

  else
    # Unknown provider
    provider="unknown"
    owner=""
    repo=""
  fi

  # Get main branch
  local main_branch
  main_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")

  # Output JSON
  jq -n \
    --arg provider "$provider" \
    --arg owner "$owner" \
    --arg repo "$repo" \
    --arg main_branch "$main_branch" \
    --arg remote_url "$remote_url" \
    '{
      provider: $provider,
      owner: $owner,
      repo: $repo,
      main_branch: $main_branch,
      remote_url: $remote_url,
      detected_at: (now | strftime("%Y-%m-%dT%H:%M:%SZ")),
      confidence: (if $provider == "unknown" then "low" else "high" end)
    }'
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  detect_vcs_from_git_remote
fi
```

### 3.4 Config Template Generation in Installer

**New Script**: `lib/installer-common/generate-config.sh`

```bash
#!/usr/bin/env bash
#
# generate-config.sh - Generate config file from template with variable substitution
#

set -euo pipefail

usage() {
  cat <<EOF
Usage: generate-config.sh [OPTIONS]

Generate AIDA config file from template with variable substitution.

Options:
  --template FILE     Template config file (JSON with {{VARS}})
  --output FILE       Output config file path
  --from-json JSON    JSON object with substitution values
  --provider NAME     VCS provider (github, gitlab, bitbucket)
  --owner NAME        Repository owner/organization
  --repo NAME         Repository name
  --help              Show this help

Examples:
  # From JSON detection
  generate-config.sh --template template.json --output config.json \\
    --from-json '{"provider":"github","owner":"user","repo":"project"}'

  # From individual args
  generate-config.sh --template template.json --output config.json \\
    --provider github --owner oakensoul --repo claude-personal-assistant

EOF
}

# Parse arguments
TEMPLATE=""
OUTPUT=""
FROM_JSON=""
PROVIDER=""
OWNER=""
REPO=""
MAIN_BRANCH="main"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --template) TEMPLATE="$2"; shift 2 ;;
    --output) OUTPUT="$2"; shift 2 ;;
    --from-json) FROM_JSON="$2"; shift 2 ;;
    --provider) PROVIDER="$2"; shift 2 ;;
    --owner) OWNER="$2"; shift 2 ;;
    --repo) REPO="$2"; shift 2 ;;
    --main-branch) MAIN_BRANCH="$2"; shift 2 ;;
    --help) usage; exit 0 ;;
    *) echo "Unknown option: $1"; usage; exit 1 ;;
  esac
done

# Extract values from JSON if provided
if [[ -n "$FROM_JSON" ]]; then
  PROVIDER=$(echo "$FROM_JSON" | jq -r '.provider // "github"')
  OWNER=$(echo "$FROM_JSON" | jq -r '.owner // "your-username"')
  REPO=$(echo "$FROM_JSON" | jq -r '.repo // "your-repository"')
  MAIN_BRANCH=$(echo "$FROM_JSON" | jq -r '.main_branch // "main"')
fi

# Validate required arguments
[[ -z "$TEMPLATE" ]] && { echo "Error: --template required"; exit 1; }
[[ -z "$OUTPUT" ]] && { echo "Error: --output required"; exit 1; }
[[ ! -f "$TEMPLATE" ]] && { echo "Error: Template not found: $TEMPLATE"; exit 1; }

# Substitute variables in template
sed "s|{{VCS_PROVIDER}}|${PROVIDER}|g; \
     s|{{VCS_OWNER}}|${OWNER}|g; \
     s|{{VCS_REPO}}|${REPO}|g; \
     s|{{MAIN_BRANCH}}|${MAIN_BRANCH}|g" \
  "$TEMPLATE" > "$OUTPUT"

# Validate generated JSON
if ! jq empty "$OUTPUT" 2>/dev/null; then
  echo "Error: Generated invalid JSON"
  rm -f "$OUTPUT"
  exit 1
fi

echo "✅ Config generated: $OUTPUT"
```

## 4. Effort & Complexity

### 4.1 Migration Script Complexity

**Estimated Effort**: 3-5 days

| Task | Complexity | Time | Risk |
|------|-----------|------|------|
| Write migration function | Medium | 1 day | Low |
| Add validation checks | Medium | 1 day | Low |
| Implement rollback logic | High | 1 day | Medium |
| Test across fixtures | Medium | 1 day | Medium |
| Edge case handling | High | 1 day | High |

**Complexity Factors**:

- **Namespace mapping** - Straightforward with `jq`
- **Data integrity** - Need comprehensive validation
- **Backward compatibility** - Temporary fallback layer adds complexity
- **Error handling** - Critical path with many failure modes

**Risk Mitigation**:

- Start with comprehensive fixture library (10+ scenarios)
- Test migration idempotency (run twice, same result)
- Validate data integrity with checksums
- Extensive rollback testing

### 4.2 Testing Across Environments

**Estimated Effort**: 4-6 days

| Environment | Test Scenarios | Complexity | Time |
|-------------|---------------|-----------|------|
| macOS (native) | Fresh install, upgrade, migration | Medium | 1 day |
| Linux (Docker) | 4 distros × 3 scenarios | High | 2 days |
| Windows (WSL) | Fresh install, upgrade | Medium | 1 day |
| CI/CD (GitHub Actions) | All scenarios automated | High | 2 days |

**Test Matrix**:

```text
Scenarios:
1. Fresh install (no existing config)
2. Upgrade (v1 config exists)
3. Migration (v1 → v2 transform)
4. Rollback (failed migration recovery)
5. Env override (CI environment)

Environments:
- macOS 13+ (native bash 5.x)
- Ubuntu 22.04, 20.04 (Docker)
- Debian 12 (Docker)
- Ubuntu minimal (Docker)
- Windows 11 WSL (Ubuntu 22.04)
- GitHub Actions (ubuntu-latest)

Total: 6 environments × 5 scenarios = 30 test cases
```

**Automation Strategy**:

```bash
# .github/testing/test-config-scenarios.sh

run_all_config_tests() {
  local environments=("ubuntu-22" "ubuntu-20" "debian-12" "ubuntu-minimal")
  local scenarios=("fresh" "upgrade" "migration" "rollback" "env-override")

  for env in "${environments[@]}"; do
    for scenario in "${scenarios[@]}"; do
      echo "🧪 Testing: $env / $scenario"

      docker run --rm \
        -v "${FIXTURES_DIR}:/tmp/fixtures:ro" \
        -e TEST_SCENARIO="$scenario" \
        "aida-test:${env}" \
        "/tmp/fixtures/test-${scenario}.sh"

      if [[ $? -eq 0 ]]; then
        echo "✅ PASS: $env / $scenario"
      else
        echo "❌ FAIL: $env / $scenario"
        FAILURES=$((FAILURES + 1))
      fi
    done
  done

  echo ""
  echo "Test Results: $((6 * 5 - FAILURES)) / 30 passed"
}
```

### 4.3 Documentation for CI/CD Setup

**Estimated Effort**: 2 days

**Required Documentation**:

1. **Migration Guide** (`docs/migration/v1-to-v2-config.md`)
   - What changed (namespace restructure)
   - Automatic vs manual migration
   - Rollback procedure
   - Troubleshooting

2. **CI/CD Integration Guide** (`docs/integration/ci-cd-config.md`)
   - Environment variable overrides
   - GitHub Actions examples
   - GitLab CI examples
   - Jenkins examples
   - Non-interactive mode

3. **Config Schema Reference** (`docs/reference/config-schema.md`)
   - Full schema with examples
   - Provider-specific fields
   - Required vs optional
   - Validation rules

4. **Pre-Commit Hook Setup** (`docs/development/pre-commit-hooks.md`)
   - Installing hooks
   - Config validation rules
   - Secret detection patterns
   - Bypassing checks (emergency)

**Documentation Template**:

````markdown
---
title: "Migration Guide: v1 → v2 Config Format"
description: "Migrate from github.* to vcs.* namespace"
category: "migration"
version: "2.0"
audience: "users"
---

# Migration Guide: v1 → v2 Configuration

## What Changed

AIDA v2.0 introduces a new configuration schema with VCS provider abstraction:

| Old (v1) | New (v2) |
|----------|----------|
| `github.owner` | `vcs.owner` |
| `github.repo` | `vcs.repo` |
| `github.main_branch` | `vcs.main_branch` |
| `github.default_reviewers` | `team.default_reviewers` |
| `github.auto_commit` | `workflow.commit.auto_commit` |

## Automatic Migration

**Migration runs automatically** on first AIDA command after upgrade.

```bash
# Upgrade AIDA
cd ~/.aida
git pull origin main

# Run any AIDA command - migration auto-triggers
aida-config-helper.sh --validate

# Output:
# ⚠️  Detected v1 configuration format
# 🔄 Migrating to v2 format...
# ✅ Migration successful
# 📦 Backup saved to: ~/.claude/workflow-config.json.backup.20251020-143022
```

## Manual Migration

```bash
# Migrate specific config file
bash ~/.aida/lib/installer-common/migrate-config.sh ~/.claude/workflow-config.json

# Validate migration
bash ~/.aida/lib/aida-config-helper.sh --validate
```

## Rollback Procedure

If migration causes issues:

```bash
# Automatic rollback (uses most recent backup)
bash ~/.aida/scripts/rollback-config.sh

# Manual rollback
cp ~/.claude/workflow-config.json.backup.TIMESTAMP \
   ~/.claude/workflow-config.json
```

## CI/CD Environments

Use environment variables instead of config files:

```yaml
# .github/workflows/deploy.yml
env:
  AIDA_VCS_PROVIDER: "github"
  AIDA_VCS_OWNER: "${{ github.repository_owner }}"
  AIDA_VCS_REPO: "${{ github.event.repository.name }}"
```

## Troubleshooting

### Migration Validation Failed

**Symptom**: Migration completes but validation fails

**Solution**:
```bash
# Check what failed
aida-config-helper.sh --validate --verbose

# Common issue: Missing required fields
# Fix: Manually add missing fields to config
```

### Backup Not Created

**Symptom**: No `.backup.*` file after migration

**Solution**: Migration was aborted early (likely JSON syntax error in original config)

```bash
# Check original config
jq empty ~/.claude/workflow-config.json

# If invalid, manually fix JSON then re-run migration
```

## Getting Help

- GitHub Issue: [#55 - Config System](https://github.com/oakensoul/claude-personal-assistant/issues/55)
- Documentation: https://aide.dev/docs/config
- Discord: https://discord.gg/aide
````

## 5. Questions & Clarifications

### Q1: Should migration be automatic or manual?

**Recommendation**: **Automatic with opt-out**

**Rationale**:

- **UX**: Most users want seamless upgrades without manual steps
- **Safety**: Backup before migration prevents data loss
- **Transparency**: Log migration steps with verbose output
- **Control**: Provide `--skip-migration` flag for power users

**Implementation**:

```bash
# Every AIDA command checks config version
if needs_migration && [[ "${AIDA_SKIP_MIGRATION:-false}" != "true" ]]; then
  migrate_with_rollback
fi

# Opt-out with environment variable
export AIDA_SKIP_MIGRATION=true
```

**User Control**:

```bash
# Manual migration (user-triggered)
aida-config-helper.sh --migrate

# Skip auto-migration for this session
export AIDA_SKIP_MIGRATION=true
./my-command

# Disable auto-migration permanently (config setting)
jq '.migration.auto_migrate = false' ~/.claude/workflow-config.json
```

### Q2: How to handle CI/CD-specific config overrides?

**Recommendation**: **Environment variable priority system**

**Priority Order** (highest to lowest):

1. **Environment variables** (`AIDA_VCS_*`) - CI/CD overrides
2. **Project config** (`.aida/config.json`) - Team settings
3. **User config** (`~/.claude/workflow-config.json`) - Personal defaults
4. **Auto-detection** (git remote) - Smart defaults

**Implementation**:

```bash
# Config loading with priority cascade
load_config() {
  local config

  # Start with empty config
  config='{}'

  # Layer 1: User config (if exists)
  if [[ -f ~/.claude/workflow-config.json ]]; then
    config=$(jq -s '.[0] * .[1]' <(echo "$config") ~/.claude/workflow-config.json)
  fi

  # Layer 2: Project config (if exists)
  if [[ -f .aida/config.json ]]; then
    config=$(jq -s '.[0] * .[1]' <(echo "$config") .aida/config.json)
  fi

  # Layer 3: Environment overrides (CI/CD)
  if [[ -n "${AIDA_VCS_PROVIDER:-}" ]]; then
    config=$(echo "$config" | jq --arg p "$AIDA_VCS_PROVIDER" '.vcs.provider = $p')
  fi
  if [[ -n "${AIDA_VCS_OWNER:-}" ]]; then
    config=$(echo "$config" | jq --arg o "$AIDA_VCS_OWNER" '.vcs.owner = $o')
  fi
  if [[ -n "${AIDA_VCS_REPO:-}" ]]; then
    config=$(echo "$config" | jq --arg r "$AIDA_VCS_REPO" '.vcs.repo = $r')
  fi

  # Layer 4: Auto-detect (if still null)
  if [[ "$(echo "$config" | jq -r '.vcs.provider // "null"')" == "null" ]]; then
    local detected
    detected=$(detect_vcs_from_git_remote)
    config=$(jq -s '.[0] * .[1]' <(echo "$config") <(echo "$detected"))
  fi

  echo "$config"
}
```

**CI/CD Best Practice**:

```yaml
# GitHub Actions - Use env vars (no config file needed)
env:
  AIDA_VCS_PROVIDER: "github"
  AIDA_VCS_OWNER: "${{ github.repository_owner }}"
  AIDA_VCS_REPO: "${{ github.event.repository.name }}"
  AIDA_VCS_MAIN_BRANCH: "${{ github.event.repository.default_branch }}"
  CI: "true"  # Prevents interactive prompts

jobs:
  deploy:
    steps:
      - run: aida-config-helper.sh --validate  # Uses env vars
```

### Q3: What's rollback strategy if migration fails?

**Recommendation**: **Multi-layer safety net**

**Rollback Strategy**:

**Layer 1: Preventive** (stop failure before it happens)

```bash
# Never modify original until ALL validations pass
migrate_with_rollback() {
  # 1. Backup original (ALWAYS)
  # 2. Transform to TEMP file (preserve original)
  # 3. Validate temp file (schema + data integrity)
  # 4. ONLY if all pass: Replace original
}
```

**Layer 2: Automatic** (rollback on detected failure)

```bash
# Detect validation failure and auto-restore
if ! validate_config "$config_file"; then
  echo "❌ Config validation failed after migration"
  restore_from_backup
  exit 1
fi
```

**Layer 3: Manual** (user-triggered recovery)

```bash
# User notices issues after migration
aida-config-helper.sh --rollback

# Or script-based
bash ~/.aida/scripts/rollback-config.sh
```

**Layer 4: Emergency** (everything else failed)

```bash
# Manual file restoration
ls -lt ~/.claude/workflow-config.json.backup.* | head -1
cp ~/.claude/workflow-config.json.backup.20251020-143022 \
   ~/.claude/workflow-config.json
```

**Testing Rollback**:

```bash
# Test suite includes rollback scenarios
test_rollback_on_validation_failure() {
  # Create intentionally broken config
  echo '{"invalid": json}' > ~/.claude/workflow-config.json

  # Migration should detect and rollback
  migrate_with_rollback ~/.claude/workflow-config.json

  # Verify original preserved
  [[ -f ~/.claude/workflow-config.json.backup.* ]] || exit 1

  # Verify migration didn't apply
  grep -q "config_version" ~/.claude/workflow-config.json && exit 1

  echo "✅ Rollback test passed"
}
```

### Q4: Should pre-commit hooks block commits or warn?

**Recommendation**: **Block for secrets, warn for schema issues**

**Rationale**:

- **Secrets** = Security risk → **BLOCK** (no exceptions)
- **Schema issues** = UX/validation → **WARN** (allow with override)
- **Missing fields** = May be intentional → **WARN**

**Implementation**:

```bash
# Pre-commit hook severity levels
validate_config_pre_commit() {
  local file="$1"
  local exit_code=0

  # CRITICAL: Secrets detected (BLOCKS commit)
  if detect_secrets "$file"; then
    echo "❌ BLOCKED: Secrets detected in config"
    echo "   Config should reference env var NAMES, not values"
    exit 1  # Hard block
  fi

  # ERROR: Invalid JSON (BLOCKS commit)
  if ! jq empty "$file" 2>/dev/null; then
    echo "❌ BLOCKED: Invalid JSON syntax"
    exit 1  # Hard block
  fi

  # WARNING: Schema validation failed (WARNS, allows commit)
  if ! validate_schema "$file" 2>/dev/null; then
    echo "⚠️  WARNING: Config schema validation failed"
    echo "   Commit will proceed, but fix before running AIDA commands"
    # exit 0  # Allow commit with warning
  fi

  # INFO: Missing optional fields (silent or info)
  if [[ -z "$(jq -r '.workflow.pr.draft_by_default // ""' "$file")" ]]; then
    echo "ℹ️  Info: Optional field missing: workflow.pr.draft_by_default"
    # exit 0  # Allow
  fi

  return $exit_code
}

# Override for emergency commits
# git commit --no-verify -m "Emergency fix"
```

### Q5: How to validate config in environments without git?

**Recommendation**: **Standalone validation with environment awareness**

**Scenarios**:

1. **Docker containers** - No git, need validation
2. **CI/CD environments** - Git exists but different context
3. **Production servers** - AIDA installed, no git repo

**Solution**: Make validation git-independent

```bash
# aida-config-helper.sh --validate (works anywhere)

validate_config_standalone() {
  local config_file="${1:-$HOME/.claude/workflow-config.json}"

  # 1. File existence (always required)
  if [[ ! -f "$config_file" ]]; then
    echo "❌ Config file not found: $config_file"
    return 1
  fi

  # 2. JSON syntax (always required)
  if ! jq empty "$config_file" 2>/dev/null; then
    echo "❌ Invalid JSON syntax"
    return 1
  fi

  # 3. Schema validation (required fields)
  local config
  config=$(cat "$config_file")

  local provider
  provider=$(echo "$config" | jq -r '.vcs.provider // "null"')

  if [[ "$provider" == "null" ]]; then
    # No provider set - check if auto-detection possible
    if git rev-parse --git-dir >/dev/null 2>&1; then
      echo "ℹ️  No provider set, but auto-detection available"
      return 0  # Valid (will auto-detect)
    else
      echo "❌ No provider set and auto-detection unavailable (not in git repo)"
      return 1
    fi
  fi

  # 4. Provider-specific validation
  case "$provider" in
    github)
      validate_github_config "$config"
      ;;
    gitlab)
      validate_gitlab_config "$config"
      ;;
    bitbucket)
      validate_bitbucket_config "$config"
      ;;
    *)
      echo "❌ Unknown provider: $provider"
      return 1
      ;;
  esac
}

# Usage in environments without git
docker run --rm -v ~/.claude:/root/.claude aida \
  bash -c "aida-config-helper.sh --validate"
```

## 6. Deployment Checklist

### Pre-Release

- [ ] Migration script tested on 10+ config fixtures
- [ ] Rollback procedure validated in all scenarios
- [ ] CI/CD integration tested in GitHub Actions
- [ ] Docker testing updated with migration scenarios
- [ ] Pre-commit hooks tested (block secrets, warn schema)
- [ ] Documentation complete (migration guide, CI/CD setup, schema reference)
- [ ] Backward compatibility layer working (2 versions)
- [ ] Environment variable override system tested

### Release

- [ ] Tag release with semantic version (v0.2.0)
- [ ] Generate changelog from conventional commits
- [ ] Include migration guide in release notes
- [ ] Announce deprecation timeline for `github.*` namespace
- [ ] Update main README with config changes
- [ ] Create migration issue template for bug reports

### Post-Release

- [ ] Monitor GitHub issues for migration failures
- [ ] Collect metrics on auto-migration success rate
- [ ] Update troubleshooting docs based on user feedback
- [ ] Plan deprecation removal for v0.4.0

## 7. Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Auto-migration success rate** | > 95% | Track migration errors in logs |
| **Rollback invocations** | < 2% | Count rollback script executions |
| **CI/CD test pass rate** | 100% | GitHub Actions workflow status |
| **Config validation errors** | < 5% | Pre-commit hook blocks |
| **User-reported migration issues** | < 10 | GitHub issues tagged `migration` |
| **Documentation clarity** | > 4.5/5 | User feedback survey |

## 8. Risk Assessment

| Risk | Likelihood | Impact | Mitigation | Contingency |
|------|-----------|--------|------------|-------------|
| **Data loss during migration** | LOW | CRITICAL | Mandatory backup before migration | Rollback script + restore procedure |
| **Breaking existing workflows** | MEDIUM | HIGH | Auto-migration + 2-version compat | Deprecation warnings, docs |
| **CI/CD config injection failures** | MEDIUM | HIGH | Comprehensive env var testing | Fallback to file-based config |
| **Secret commits to VCS** | MEDIUM | CRITICAL | Pre-commit hook (gitleaks + custom) | Post-commit scanning, git history rewrite |
| **Docker testing gaps** | LOW | MEDIUM | 30-test matrix (6 envs × 5 scenarios) | Extended testing period before release |
| **Migration validation false positives** | MEDIUM | MEDIUM | Schema flexibility, clear error messages | Manual override flag |

**Overall Risk Level**: **MEDIUM** (well-mitigated with comprehensive safety nets)

## 9. Implementation Timeline

**Estimated Total**: 12-15 days

### Phase 1: Foundation (5 days)

- Migration script with rollback (2 days)
- Config template system (1 day)
- VCS auto-detection (1 day)
- Pre-commit hooks (1 day)

### Phase 2: Integration (4 days)

- GitHub Actions workflows (2 days)
- Docker testing updates (1 day)
- Installer modifications (1 day)

### Phase 3: Testing & Documentation (3 days)

- Comprehensive test suite (1.5 days)
- Documentation (1 day)
- Review and refinement (0.5 days)

### Phase 4: Release (1 day)

- Final testing
- Release preparation
- Deployment

---

**Prepared by**: DevOps Engineer Agent
**Date**: 2025-10-20
**Issue**: #55 - Configuration System with VCS Abstraction
**Status**: Ready for technical review

**Next Steps**:

1. Review with Tech Lead for architecture approval
2. Review with Security Engineer for secret detection patterns
3. Begin Phase 1 implementation after approval

**Related Analyses**:

- Configuration Specialist (product requirements)
- Privacy Security Auditor (secret management)
- Shell Systems UX Designer (error messaging)
- Integration Specialist (provider abstraction)
