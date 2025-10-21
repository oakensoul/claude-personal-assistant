---
title: "Privacy & Security Analysis - Configuration System (#55)"
agent: "privacy-security-auditor"
issue: 55
created: "2025-10-20"
status: "draft"
category: "technical-analysis"
focus: ["secret-detection", "file-permissions", "secure-migration", "environment-validation"]
---

# Technical Security Analysis: Configuration System

## Executive Summary

**Scope**: Security implementation for `.claude/config.json` schema with VCS abstraction, focusing on secret prevention, file permissions, secure migrations, and environment variable validation.

**Security Posture**: MEDIUM-HIGH risk due to credential handling requirements. Critical that secrets NEVER reach config files or git history.

**Key Concerns**:

1. **Secret Detection**: Pre-commit hooks must block all token patterns (GitHub, Jira, Linear, API keys)
2. **File Permissions**: User configs (600), project configs (644) must be enforced at creation and validated
3. **Secure Migration**: Backup existing configs atomically before transformation to prevent data loss
4. **Environment Validation**: Token format validation WITHOUT exposing values in logs/errors

**Recommendation**: Leverage existing gitleaks infrastructure + custom patterns for AIDA-specific validation.

---

## 1. Implementation Approach

### 1.1 Pre-Commit Hook Implementation

**Current Infrastructure**:

```yaml
# .pre-commit-config.yaml (existing)
- repo: https://github.com/gitleaks/gitleaks
  rev: v8.18.2
  hooks:
    - id: gitleaks
      name: Detect secrets and credentials
```

**Current Gitleaks Config** (`.gitleaks.toml`):

- ✅ Already configured with allowlist for documentation
- ✅ Handles example API keys (Metabase, Stripe test keys)
- ⚠️ **GAP**: No specific rules for config files or VCS provider tokens

#### Recommended Enhancement

**Add config-specific secret detection patterns**:

```toml
# .gitleaks.toml - Additional rules for Issue #55

[[rules]]
id = "github-token-in-config"
description = "GitHub token in JSON config file"
regex = '''["']gh[pousr]_[A-Za-z0-9_]{36,}["']'''
path = '''(\.claude/|\.aida/).*config\.json$'''

[[rules]]
id = "jira-token-in-config"
description = "Jira API token in config file"
regex = '''["'](api_token|jira_token)["']\s*:\s*["'][A-Za-z0-9]{24,}["']'''
path = '''(\.claude/|\.aida/).*config\.json$'''

[[rules]]
id = "linear-token-in-config"
description = "Linear API key in config file"
regex = '''["']lin_api_[A-Za-z0-9]{40,}["']'''
path = '''(\.claude/|\.aida/).*config\.json$'''

[[rules]]
id = "anthropic-key-in-config"
description = "Anthropic API key in config file"
regex = '''["']sk-ant-[A-Za-z0-9\-_]{95,}["']'''
path = '''(\.claude/|\.aida/).*config\.json$'''

# Allowlist for example config files
[allowlist]
paths = [
    '''tests/fixtures/configs/.*''',
    '''docs/examples/.*\.json$''',
]
```

**Token Detection Patterns by Provider**:

| Provider | Pattern | Example | Notes |
|----------|---------|---------|-------|
| GitHub PAT (classic) | `ghp_[A-Za-z0-9]{36}` | `ghp_1234567890abcdefghij1234567890abcd` | Classic tokens |
| GitHub PAT (fine-grained) | `github_pat_[A-Za-z0-9_]{82}` | `github_pat_11A...` | New format |
| GitHub OAuth | `gho_[A-Za-z0-9]{36}` | `gho_abc123...` | OAuth apps |
| GitHub User-to-server | `ghu_[A-Za-z0-9]{36}` | `ghu_xyz789...` | User access |
| Jira API token | `[A-Za-z0-9]{24}` | Generic, context needed | Check near `api_token` key |
| Linear API key | `lin_api_[A-Za-z0-9]{40}` | `lin_api_abc...` | Official format |
| Anthropic | `sk-ant-[A-Za-z0-9\-_]{95}` | From PRD examples | Official format |

**Custom Validation Hook** (complement gitleaks):

```bash
#!/usr/bin/env bash
# .git/hooks/pre-commit.d/validate-config-security.sh
# Custom config-specific validation (runs AFTER gitleaks)

set -euo pipefail

# Source validation library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/installer-common/validation.sh"

validate_config_files() {
    # Find all staged config.json files
    local staged_configs
    staged_configs=$(git diff --cached --name-only --diff-filter=ACM | grep -E 'config\.json$' || true)

    if [[ -z "$staged_configs" ]]; then
        return 0  # No config files staged
    fi

    local errors=0

    while IFS= read -r config_file; do
        # Skip if file doesn't exist (deletion)
        [[ ! -f "$config_file" ]] && continue

        # Validation 1: Valid JSON
        if ! jq empty "$config_file" 2>/dev/null; then
            echo "❌ Invalid JSON: $config_file"
            ((errors++))
            continue
        fi

        # Validation 2: No secret-like fields in config
        local secret_fields=("api_key" "api_secret" "token" "password" "secret")
        for field in "${secret_fields[@]}"; do
            if jq -e ".. | select(type == \"object\") | has(\"$field\")" "$config_file" >/dev/null 2>&1; then
                echo "❌ Config contains secret field '$field': $config_file"
                echo "   Secrets must be in environment variables, not config files"
                ((errors++))
            fi
        done

        # Validation 3: Environment variable references (should be key names, not values)
        # Check if config has *_TOKEN or *_KEY fields with actual values (not env var names)
        local token_value
        token_value=$(jq -r '.. | select(type == "string") | select(length > 32 and test("^[A-Za-z0-9_-]{32,}$"))' "$config_file" 2>/dev/null || true)
        if [[ -n "$token_value" ]]; then
            echo "❌ Suspicious token-like value in config: $config_file"
            echo "   Long alphanumeric strings should be environment variables"
            ((errors++))
        fi

    done <<< "$staged_configs"

    return "$errors"
}

# Run validation
if ! validate_config_files; then
    echo ""
    echo "🔒 Security: Config validation failed"
    echo ""
    echo "Fix by:"
    echo "  1. Remove secret fields from config.json"
    echo "  2. Store secrets in environment variables (e.g., GITHUB_TOKEN)"
    echo "  3. Reference env var NAME in config, not the value"
    echo ""
    echo "Example:"
    echo "  ❌ \"github\": { \"token\": \"ghp_abc123...\" }"
    echo "  ✅ Environment: export GITHUB_TOKEN=\"ghp_abc123...\""
    echo "  ✅ Config: \"github\": { \"owner\": \"oakensoul\", \"repo\": \"..\" }"
    echo ""
    exit 1
fi
```

**Integration with Pre-Commit Framework**:

```yaml
# .pre-commit-config.yaml (add to local hooks)
- repo: local
  hooks:
    - id: validate-config-security
      name: Validate config file security
      description: Check config files for embedded secrets
      entry: scripts/validate-config-security.sh
      language: script
      files: 'config\.json$'
      pass_filenames: false
```

**Effort**: 4-6 hours

- Write custom validation script: 2 hours
- Enhance gitleaks.toml patterns: 1 hour
- Test against real token patterns: 2 hours
- Documentation: 1 hour

---

### 1.2 File Permission Enforcement

**Strategy**: Enforce at creation (installer/helper) + validate at runtime (pre-commit/validator)

#### Permission Requirements

| File Type | Location | Permissions | Owner | Reason |
|-----------|----------|-------------|-------|--------|
| User config | `~/.claude/config.json` | 600 (rw-------) | $USER | Contains user preferences, NOT committed |
| Project config | `.aida/config.json` | 644 (rw-r--r--) | $USER | Shared team config, committed to git |
| Schema file | `lib/installer-common/config-schema.json` | 644 | $USER | Public reference |
| Backup configs | `~/.claude/config.json.backup.*` | 600 | $USER | Contains user data |

**Rationale**:

- **600 (User config)**: Prevents accidental exposure to other users on multi-user systems
- **644 (Project config)**: Allows team members to read, git to track, but only owner writes
- **World-writable NEVER allowed**: Security risk (existing validation already blocks this)

#### Implementation: Creation-Time Enforcement

**Location**: `lib/installer-common/config.sh` (enhance `write_user_config()`)

```bash
# lib/installer-common/config.sh - Enhanced permission enforcement

write_user_config() {
    local config_file="${claude_dir}/config.json"

    # ... (existing config creation logic) ...

    # SECURITY: Set restrictive permissions on user config
    chmod 600 "$config_file" || {
        print_message "error" "Failed to set permissions on ${config_file}"
        return 1
    }

    # Verify permissions were set correctly
    if ! validate_file_permissions "$config_file"; then
        print_message "error" "Config file has incorrect permissions after creation"
        return 1
    fi

    print_message "success" "Created config with secure permissions (600): ${config_file}"
    return 0
}

write_project_config() {
    local config_file=".aida/config.json"

    # ... (project config creation logic) ...

    # SECURITY: Set team-readable permissions on project config
    chmod 644 "$config_file" || {
        print_message "error" "Failed to set permissions on ${config_file}"
        return 1
    }

    # Verify permissions
    if ! validate_file_permissions "$config_file"; then
        print_message "error" "Project config has incorrect permissions"
        return 1
    fi

    print_message "success" "Created project config with team permissions (644): ${config_file}"
    return 0
}
```

**Existing Infrastructure** (already available in `validation.sh`):

```bash
# validation.sh:153-187 - Already implements permission validation
validate_file_permissions() {
    local file="$1"

    # Platform-specific stat (macOS vs Linux)
    # Checks for world-writable (last digit 2, 3, 6, 7)
    # ✅ Already production-ready
}
```

**Cross-Platform Considerations**:

| Platform | stat Command | Permission Format | Notes |
|----------|--------------|-------------------|-------|
| macOS | `stat -f "%Lp"` | Octal (644) | BSD stat |
| Linux | `stat -c "%a"` | Octal (644) | GNU stat |
| Windows (WSL) | `stat -c "%a"` | Octal | Git Bash uses Linux stat |
| Windows (native) | N/A | Use icacls | **Out of scope** (PRD: macOS/Linux only) |

**Permission Validation Pre-Commit Hook**:

```bash
#!/usr/bin/env bash
# Validate config file permissions before commit

validate_config_permissions() {
    local staged_configs
    staged_configs=$(git diff --cached --name-only --diff-filter=ACM | grep -E 'config\.json$' || true)

    [[ -z "$staged_configs" ]] && return 0

    local errors=0

    while IFS= read -r config_file; do
        [[ ! -f "$config_file" ]] && continue

        # Get file permissions
        local perms
        if [[ "$OSTYPE" == "darwin"* ]]; then
            perms=$(stat -f "%Lp" "$config_file" 2>/dev/null)
        else
            perms=$(stat -c "%a" "$config_file" 2>/dev/null)
        fi

        # User config: must be 600
        if [[ "$config_file" == *"/.claude/config.json" ]]; then
            if [[ "$perms" != "600" ]]; then
                echo "❌ Incorrect permissions on user config: $config_file"
                echo "   Expected: 600 (rw-------), Got: $perms"
                echo "   Fix: chmod 600 $config_file"
                ((errors++))
            fi
        fi

        # Project config: should be 644 (warn if not)
        if [[ "$config_file" == *"/.aida/config.json" ]]; then
            if [[ "$perms" != "644" ]]; then
                echo "⚠️  Non-standard permissions on project config: $config_file"
                echo "   Expected: 644 (rw-r--r--), Got: $perms"
                echo "   Recommended: chmod 644 $config_file"
                # Don't increment errors - this is a warning, not blocker
            fi
        fi

        # CRITICAL: Check for world-writable (security violation)
        local last_digit="${perms: -1}"
        if [[ "$last_digit" =~ [2367] ]]; then
            echo "🚨 SECURITY: World-writable config detected: $config_file"
            echo "   Permissions: $perms"
            echo "   Fix immediately: chmod go-w $config_file"
            ((errors++))
        fi

    done <<< "$staged_configs"

    return "$errors"
}

if ! validate_config_permissions; then
    exit 1
fi
```

**Effort**: 3-4 hours

- Enhance `write_user_config()`: 1 hour (already 80% done in validation.sh)
- Create `write_project_config()`: 1 hour
- Permission validation hook: 1.5 hours
- Cross-platform testing: 1 hour

---

### 1.3 Environment Variable Validation

**Requirement**: Validate token FORMAT without exposing values in logs/errors.

#### Validation Strategy

**Three-Tier Validation**:

1. **Tier 1: Existence** - Is env var set? (Don't log value)
2. **Tier 2: Format** - Does it match provider pattern? (Don't log value)
3. **Tier 3: Connectivity** (OPTIONAL, `--verify-connection` flag) - Can we auth with it?

#### Implementation: Format Validation

```bash
#!/usr/bin/env bash
# lib/installer-common/token-validator.sh

set -euo pipefail

#######################################
# Validate GitHub token format
# Arguments:
#   $1 - Environment variable name (not value)
# Returns:
#   0 if valid, 1 if invalid
# Outputs:
#   Error message WITHOUT token value
#######################################
validate_github_token() {
    local env_var_name="$1"

    # Check if environment variable is set
    if [[ -z "${!env_var_name:-}" ]]; then
        print_message "error" "Environment variable not set: ${env_var_name}"
        print_message "info" "Set with: export ${env_var_name}=your_token_here"
        return 1
    fi

    local token="${!env_var_name}"

    # Validate format (without logging token)
    # GitHub PAT classic: ghp_[A-Za-z0-9]{36}
    # GitHub PAT fine-grained: github_pat_[A-Za-z0-9_]{82}
    # GitHub OAuth: gho_[A-Za-z0-9]{36}

    if [[ "$token" =~ ^ghp_[A-Za-z0-9]{36}$ ]]; then
        print_message "success" "GitHub token format valid (classic PAT)"
        return 0
    elif [[ "$token" =~ ^github_pat_[A-Za-z0-9_]{82}$ ]]; then
        print_message "success" "GitHub token format valid (fine-grained PAT)"
        return 0
    elif [[ "$token" =~ ^gho_[A-Za-z0-9]{36}$ ]]; then
        print_message "success" "GitHub token format valid (OAuth)"
        return 0
    else
        print_message "error" "GitHub token format invalid"
        print_message "info" "Expected format:"
        print_message "info" "  - Classic PAT: ghp_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
        print_message "info" "  - Fine-grained: github_pat_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
        print_message "info" "  - OAuth: gho_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
        print_message "info" "Token prefix: ${token:0:4}... (length: ${#token})"
        return 1
    fi
}

#######################################
# Validate Jira token format
# Arguments:
#   $1 - Environment variable name
# Returns:
#   0 if valid, 1 if invalid
#######################################
validate_jira_token() {
    local env_var_name="$1"

    if [[ -z "${!env_var_name:-}" ]]; then
        print_message "error" "Environment variable not set: ${env_var_name}"
        return 1
    fi

    local token="${!env_var_name}"

    # Jira API tokens are base64-encoded, typically 24-32 characters
    # Format: alphanumeric (case-sensitive)
    if [[ "$token" =~ ^[A-Za-z0-9]{24,32}$ ]]; then
        print_message "success" "Jira token format valid (${#token} chars)"
        return 0
    else
        print_message "error" "Jira token format invalid"
        print_message "info" "Expected: 24-32 alphanumeric characters"
        print_message "info" "Token length: ${#token}"
        return 1
    fi
}

#######################################
# Validate Linear API key format
# Arguments:
#   $1 - Environment variable name
# Returns:
#   0 if valid, 1 if invalid
#######################################
validate_linear_token() {
    local env_var_name="$1"

    if [[ -z "${!env_var_name:-}" ]]; then
        print_message "error" "Environment variable not set: ${env_var_name}"
        return 1
    fi

    local token="${!env_var_name}"

    # Linear API keys: lin_api_[A-Za-z0-9]{40}
    if [[ "$token" =~ ^lin_api_[A-Za-z0-9]{40}$ ]]; then
        print_message "success" "Linear API key format valid"
        return 0
    else
        print_message "error" "Linear API key format invalid"
        print_message "info" "Expected format: lin_api_<40_character_token>"
        print_message "info" "Token prefix: ${token:0:8}... (length: ${#token})"
        return 1
    fi
}

#######################################
# Validate provider token (dispatcher)
# Arguments:
#   $1 - Provider name (github, jira, linear)
#   $2 - Environment variable name
# Returns:
#   0 if valid, 1 if invalid
#######################################
validate_provider_token() {
    local provider="$1"
    local env_var_name="$2"

    case "$provider" in
        github)
            validate_github_token "$env_var_name"
            ;;
        jira)
            validate_jira_token "$env_var_name"
            ;;
        linear)
            validate_linear_token "$env_var_name"
            ;;
        *)
            print_message "error" "Unknown provider: ${provider}"
            return 1
            ;;
    esac
}
```

**Logging Without Exposing Secrets**:

```bash
# ❌ BAD - Logs actual token
print_message "error" "Token invalid: ${GITHUB_TOKEN}"

# ✅ GOOD - Logs only metadata
print_message "error" "Token invalid"
print_message "info" "Token prefix: ${GITHUB_TOKEN:0:4}... (length: ${#GITHUB_TOKEN})"

# ✅ GOOD - No value in audit logs
log_to_file "SECURITY" "Token validation failed for env var: GITHUB_TOKEN (provider: github)"
```

**Audit Trail** (without exposing secrets):

```bash
# Log credential usage metadata (not values)
log_credential_usage() {
    local provider="$1"
    local operation="$2"
    local env_var_name="$3"

    local timestamp
    timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)

    # Log to audit file (NOT regular logs)
    local audit_log="${CLAUDE_DIR}/audit.log"
    echo "${timestamp} | ${operation} | ${provider} | env_var=${env_var_name}" >> "$audit_log"

    # Ensure audit log has restricted permissions
    chmod 600 "$audit_log"
}

# Usage
log_credential_usage "github" "token_validation" "GITHUB_TOKEN"
log_credential_usage "jira" "api_call" "JIRA_API_TOKEN"
```

**Effort**: 5-7 hours

- Token validation functions: 3 hours (all providers)
- Secure logging patterns: 2 hours
- Audit trail implementation: 1.5 hours
- Testing with real tokens: 1 hour

---

### 1.4 Secure Backup/Restore Mechanism

**Requirement**: Backup existing configs atomically before migration to prevent data loss.

**Existing Infrastructure** (from `migrations.sh`):

```bash
# migrations.sh:36-69 - Directory migration pattern
# ✅ Uses mkdir -p for safety
# ✅ Checks for conflicts before moving
# ⚠️ GAP: No backup before transformation
```

#### Atomic Backup Strategy

**Goals**:

1. **Atomic operations**: Backup succeeds completely or fails with no partial state
2. **Timestamped backups**: Allow rollback to specific versions
3. **Validation**: Verify backup is valid JSON before proceeding
4. **Cleanup**: Remove old backups after configurable retention period

**Implementation**:

```bash
#!/usr/bin/env bash
# lib/installer-common/config-migration.sh

set -euo pipefail

#######################################
# Create atomic backup of config file
# Arguments:
#   $1 - Config file path to backup
# Returns:
#   0 on success, 1 on failure
# Outputs:
#   Backup file path to stdout if successful
#######################################
create_config_backup() {
    local config_file="$1"

    # Validate input
    if [[ ! -f "$config_file" ]]; then
        print_message "error" "Config file not found: ${config_file}"
        return 1
    fi

    # Validate it's valid JSON before backing up
    if ! jq empty "$config_file" 2>/dev/null; then
        print_message "error" "Config file is not valid JSON, refusing to backup"
        print_message "info" "Fix JSON errors before migration"
        return 1
    fi

    # Create timestamped backup filename
    local timestamp
    timestamp=$(date -u +%Y%m%d-%H%M%S)
    local backup_file="${config_file}.backup.${timestamp}"

    # Use rsync for atomic copy (safer than cp)
    # --archive preserves permissions, timestamps
    # --quiet suppresses output
    if rsync -aq "$config_file" "$backup_file"; then
        # Set restrictive permissions on backup (same as original)
        chmod 600 "$backup_file"

        # Verify backup is valid JSON
        if ! jq empty "$backup_file" 2>/dev/null; then
            print_message "error" "Backup created but is invalid JSON (corruption during copy)"
            rm -f "$backup_file"
            return 1
        fi

        print_message "success" "Created backup: ${backup_file}"
        echo "$backup_file"  # Output backup path
        return 0
    else
        print_message "error" "Failed to create backup: ${backup_file}"
        return 1
    fi
}

#######################################
# Restore config from backup
# Arguments:
#   $1 - Backup file path
#   $2 - Target config file path
# Returns:
#   0 on success, 1 on failure
#######################################
restore_config_backup() {
    local backup_file="$1"
    local target_file="$2"

    if [[ ! -f "$backup_file" ]]; then
        print_message "error" "Backup file not found: ${backup_file}"
        return 1
    fi

    # Validate backup is valid JSON
    if ! jq empty "$backup_file" 2>/dev/null; then
        print_message "error" "Backup file is corrupted (invalid JSON)"
        return 1
    fi

    # Atomic restore with rsync
    if rsync -aq "$backup_file" "$target_file"; then
        print_message "success" "Restored config from: ${backup_file}"
        return 0
    else
        print_message "error" "Failed to restore config"
        return 1
    fi
}

#######################################
# Migrate config with automatic backup
# Arguments:
#   $1 - Config file path
#   $2 - Migration function name
# Returns:
#   0 on success, 1 on failure
#######################################
migrate_config_with_backup() {
    local config_file="$1"
    local migration_function="$2"

    print_message "info" "Starting migration: ${config_file}"

    # Step 1: Create backup
    local backup_file
    if ! backup_file=$(create_config_backup "$config_file"); then
        print_message "error" "Migration aborted: backup failed"
        return 1
    fi

    # Step 2: Run migration function
    print_message "info" "Running migration function: ${migration_function}"
    if $migration_function "$config_file"; then
        # Migration succeeded
        print_message "success" "Migration completed successfully"
        print_message "info" "Backup preserved at: ${backup_file}"
        return 0
    else
        # Migration failed - restore backup
        print_message "error" "Migration failed, restoring backup..."
        if restore_config_backup "$backup_file" "$config_file"; then
            print_message "success" "Successfully restored original config"
            print_message "info" "Config unchanged: ${config_file}"
        else
            print_message "error" "CRITICAL: Failed to restore backup"
            print_message "error" "Manual restore required from: ${backup_file}"
        fi
        return 1
    fi
}

#######################################
# Example migration: github.* → vcs.github.*
# Arguments:
#   $1 - Config file path (modified in place)
# Returns:
#   0 on success, 1 on failure
#######################################
migrate_github_to_vcs() {
    local config_file="$1"

    # Use jq to transform namespace (atomic write to temp file)
    local temp_file
    temp_file=$(mktemp)

    # Transform: github.* → vcs.github.*
    if jq '.vcs.github = .github | del(.github)' "$config_file" > "$temp_file"; then
        # Validate transformed config
        if ! jq empty "$temp_file" 2>/dev/null; then
            print_message "error" "Transformed config is invalid JSON"
            rm -f "$temp_file"
            return 1
        fi

        # Atomic move to replace original
        if mv "$temp_file" "$config_file"; then
            chmod 600 "$config_file"  # Restore permissions
            print_message "success" "Migrated github → vcs.github namespace"
            return 0
        else
            print_message "error" "Failed to write transformed config"
            rm -f "$temp_file"
            return 1
        fi
    else
        print_message "error" "jq transformation failed"
        rm -f "$temp_file"
        return 1
    fi
}

#######################################
# Clean up old backups (keep last N)
# Arguments:
#   $1 - Config file path (backups are ${config}.backup.*)
#   $2 - Number of backups to retain (default: 5)
# Returns:
#   0 on success
#######################################
cleanup_old_backups() {
    local config_file="$1"
    local keep_count="${2:-5}"

    # Find all backups for this config (sorted by timestamp in filename)
    local backups=()
    while IFS= read -r backup; do
        backups+=("$backup")
    done < <(find "$(dirname "$config_file")" -name "$(basename "$config_file").backup.*" | sort -r)

    # If more than keep_count, delete oldest
    if [[ ${#backups[@]} -gt $keep_count ]]; then
        local to_delete=$((${#backups[@]} - keep_count))
        print_message "info" "Cleaning up ${to_delete} old backup(s), keeping ${keep_count}"

        for ((i=keep_count; i<${#backups[@]}; i++)); do
            rm -f "${backups[$i]}"
            print_message "info" "Deleted old backup: ${backups[$i]}"
        done
    fi

    return 0
}
```

**Usage Example**:

```bash
# In installer or migration script
source lib/installer-common/config-migration.sh

# Migrate with automatic backup/restore
if migrate_config_with_backup ~/.claude/config.json migrate_github_to_vcs; then
    echo "Migration successful"
    # Cleanup old backups (keep last 5)
    cleanup_old_backups ~/.claude/config.json 5
else
    echo "Migration failed, original config preserved"
fi
```

**Security Considerations**:

| Risk | Mitigation |
|------|------------|
| Backup file exposure | Set 600 permissions immediately after creation |
| Partial backup (corruption) | Validate JSON before AND after backup |
| Failed restore | Keep backup file on disk, log path for manual recovery |
| Backup accumulation | Cleanup old backups (configurable retention) |
| Temp file exposure | Use `mktemp` (creates with 600 permissions) |
| Race conditions | Use `rsync` (atomic), `mv` (atomic on same filesystem) |

**Effort**: 6-8 hours

- Backup/restore functions: 3 hours
- Migration wrapper with rollback: 2 hours
- Cleanup logic: 1.5 hours
- Testing migration scenarios: 2 hours
- Error recovery testing: 1 hour

---

## 2. Technical Concerns

### 2.1 Regex Patterns for Token Detection

**Complexity**: MEDIUM-HIGH

**Challenge**: Balance precision (catch real secrets) with recall (avoid false positives).

#### Pattern Analysis by Provider

**GitHub Tokens** (HIGH confidence):

```regex
# Classic PAT (40 chars total: prefix 4 + hash 36)
ghp_[A-Za-z0-9]{36}

# Fine-grained PAT (86 chars total: prefix 11 + hash 75)
# Note: Actual format is github_pat_ + 82 chars
github_pat_[A-Za-z0-9_]{82}

# OAuth tokens
gho_[A-Za-z0-9]{36}

# User-to-server tokens
ghu_[A-Za-z0-9]{36}

# Refresh tokens
ghr_[A-Za-z0-9]{36}

# App tokens (old format)
ghs_[A-Za-z0-9]{36}
```

**Confidence**: 99% - GitHub has well-defined prefixes, very few false positives.

**Jira Tokens** (MEDIUM confidence):

```regex
# API tokens (base64-like, 24-32 chars)
[A-Za-z0-9]{24,32}

# Context-aware: must be near "jira", "api_token", or in jira.* namespace
```

**Confidence**: 70% - Generic alphanumeric, needs context checking.

**False Positive Risk**: HIGH if used alone. Must check surrounding JSON structure:

```bash
# Context-aware Jira detection
if jq -e '.jira.api_token' config.json >/dev/null; then
    # This field should NOT exist in committed config
    echo "ERROR: jira.api_token field found in config"
fi
```

**Linear Tokens** (HIGH confidence):

```regex
# Linear API keys (48 chars total: prefix 8 + hash 40)
lin_api_[A-Za-z0-9]{40}
```

**Confidence**: 95% - Well-defined prefix, low false positive rate.

**Anthropic Tokens** (HIGH confidence):

```regex
# Anthropic API keys (99+ chars: prefix sk-ant- + base62 hash)
sk-ant-[A-Za-z0-9\-_]{95,}
```

**Confidence**: 99% - Unique prefix, very long, minimal false positives.

#### False Positive Mitigation

##### Strategy 1: Allowlist Example Files

```toml
# .gitleaks.toml
[allowlist]
paths = [
    '''tests/fixtures/.*''',
    '''docs/examples/.*''',
    '''templates/.*\.example\.json$''',
]
```

##### Strategy 2: Context-Aware Detection

```bash
# Don't flag if token is in comment or documentation
if line contains "#" or "Example:" or "Format:"; then
    skip
fi

# Don't flag if token matches example pattern
if token matches "ghp_XXXX" or "your_token_here"; then
    skip
fi
```

##### Strategy 3: JSON Structure Validation

```bash
# Config should NOT have these fields
forbidden_fields=("api_key" "api_secret" "token" "password" "secret" "credential")

for field in "${forbidden_fields[@]}"; do
    if jq -e ".. | select(type == \"object\") | has(\"$field\")" config.json; then
        echo "ERROR: Config contains forbidden field: $field"
    fi
done
```

#### Testing Token Patterns

**Test Suite** (use fake tokens with correct format):

```bash
#!/usr/bin/env bash
# tests/security/test-token-detection.sh

test_github_classic_pat() {
    local fake_token="ghp_1234567890abcdefghijklmnopqrstuv12"
    assert_matches "$fake_token" '^ghp_[A-Za-z0-9]{36}$'
}

test_github_fine_grained_pat() {
    local fake_token="github_pat_$(head -c 82 /dev/urandom | base64 | tr -dc 'A-Za-z0-9_' | head -c 82)"
    assert_matches "$fake_token" '^github_pat_[A-Za-z0-9_]{82}$'
}

test_linear_token() {
    local fake_token="lin_api_$(head -c 40 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 40)"
    assert_matches "$fake_token" '^lin_api_[A-Za-z0-9]{40}$'
}

test_anthropic_token() {
    local fake_token="sk-ant-$(head -c 95 /dev/urandom | base64 | tr -dc 'A-Za-z0-9_-' | head -c 95)"
    assert_matches "$fake_token" '^sk-ant-[A-Za-z0-9\-_]{95,}$'
}

# Test gitleaks directly
test_gitleaks_detection() {
    # Create temp config with fake token
    local temp_config=$(mktemp)
    echo '{"github": {"token": "ghp_1234567890abcdefghijklmnopqrstuv12"}}' > "$temp_config"

    # Run gitleaks
    if gitleaks detect --source "$temp_config" --no-git; then
        echo "FAIL: gitleaks did not detect embedded token"
        return 1
    else
        echo "PASS: gitleaks detected embedded token"
        return 0
    fi
}
```

---

### 2.2 Race Conditions in File Permission Checks

**Risk**: TOCTOU (Time-of-check-time-of-use) vulnerabilities.

**Scenario**:

```bash
# Thread 1: Validation
if validate_file_permissions config.json; then  # ← Check (permissions OK)
    # ...
fi

# Thread 2: Attack (between check and use)
chmod 777 config.json  # ← Permissions changed!

# Thread 1: Usage
cat config.json  # ← Use (now world-readable!)
```

**Mitigation Strategies**:

#### Strategy 1: Check-and-Use Atomically

**Bad** (vulnerable):

```bash
# Check permissions
validate_file_permissions "$config_file"

# Later: use file (permissions may have changed)
config=$(cat "$config_file")
```

**Good** (atomic):

```bash
# Open file descriptor with validated permissions
exec 3< "$config_file"
if validate_file_permissions "$config_file"; then
    config=$(cat <&3)
    exec 3<&-  # Close FD
else
    exec 3<&-
    exit 1
fi
```

#### Strategy 2: Use O_NOFOLLOW and Validate Ownership

```bash
# Ensure file is not a symlink (prevents symlink attacks)
if [[ -L "$config_file" ]]; then
    echo "ERROR: Config is a symlink (security risk)"
    exit 1
fi

# Validate ownership matches current user
if [[ "$OSTYPE" == "darwin"* ]]; then
    owner=$(stat -f "%Su" "$config_file")
else
    owner=$(stat -c "%U" "$config_file")
fi

if [[ "$owner" != "$USER" ]]; then
    echo "ERROR: Config owned by $owner (expected: $USER)"
    exit 1
fi
```

#### Strategy 3: Set Permissions Immediately After Creation

**Current code** (already does this):

```bash
# lib/installer-common/config.sh:164-165
cat > "$config_file" <<EOF
{ ... }
EOF

# IMMEDIATELY set restrictive permissions
chmod 600 "$config_file"
```

**Why this works**: File created with default permissions (usually 644), then immediately restricted. Window for attack is microseconds.

**Additional Hardening**:

```bash
# Set umask before creating sensitive files
old_umask=$(umask)
umask 077  # Create files with 600 by default

cat > "$config_file" <<EOF
{ ... }
EOF

# Explicitly set permissions (belt and suspenders)
chmod 600 "$config_file"

# Restore original umask
umask "$old_umask"
```

#### Strategy 4: Use `mktemp` for Temporary Files

**Current code** (needs enhancement):

```bash
# migrations.sh - Uses mktemp correctly
local temp_file
temp_file=$(mktemp)  # Created with 600 permissions by default

# Write to temp file
jq '.transform' "$config_file" > "$temp_file"

# Atomic move
mv "$temp_file" "$config_file"
```

**mktemp guarantees**:

- File created with 600 permissions
- Unique filename (no collision attacks)
- Created in secure temp directory

**Platform Differences**:

| Platform | Default umask | mktemp Permissions | Temp Directory |
|----------|---------------|-------------------|----------------|
| macOS | 022 | 600 | `/var/folders/...` (user-specific) |
| Linux | 022 | 600 | `/tmp` (sticky bit set) |
| WSL | 022 | 600 | `/tmp` |

**Effort**: 2-3 hours (mostly testing edge cases)

---

### 2.3 Secure Temp File Handling During Migration

**Requirements**:

1. Temp files created with 600 permissions
2. Temp files cleaned up on error
3. No temp file path prediction (use `mktemp`)
4. Atomic operations (temp → final)

**Implementation** (already partially in migrations.sh):

```bash
#!/usr/bin/env bash
# Secure temp file handling pattern

secure_transform_config() {
    local config_file="$1"

    # Create secure temp file (600 permissions)
    local temp_file
    temp_file=$(mktemp "${config_file}.XXXXXX") || {
        print_message "error" "Failed to create temp file"
        return 1
    }

    # Ensure cleanup on exit (success or failure)
    trap 'rm -f "$temp_file"' EXIT ERR INT TERM

    # Transform config to temp file
    if jq '.transform' "$config_file" > "$temp_file"; then
        # Validate transformed config
        if ! jq empty "$temp_file" 2>/dev/null; then
            print_message "error" "Transformed config is invalid"
            return 1
        fi

        # Atomic move (same filesystem)
        if mv "$temp_file" "$config_file"; then
            # Explicitly set permissions (belt and suspenders)
            chmod 600 "$config_file"
            print_message "success" "Config transformed"
            return 0
        else
            print_message "error" "Failed to replace config"
            return 1
        fi
    else
        print_message "error" "Transformation failed"
        return 1
    fi

    # Note: trap ensures temp_file is cleaned up even if we return early
}
```

**Trap Guarantees**:

- `EXIT`: Cleanup when function returns normally
- `ERR`: Cleanup when command fails (with `set -e`)
- `INT`: Cleanup when user presses Ctrl+C
- `TERM`: Cleanup when process is killed

**Atomic Move Requirements**:

```bash
# Atomic move only works on same filesystem
# Check if temp and config are on same filesystem

src_fs=$(df "$temp_file" | tail -1 | awk '{print $1}')
dst_fs=$(df "$config_file" | tail -1 | awk '{print $1}')

if [[ "$src_fs" != "$dst_fs" ]]; then
    # Different filesystems - use rsync instead of mv
    rsync -aq "$temp_file" "$config_file"
    rm -f "$temp_file"
else
    # Same filesystem - atomic mv
    mv "$temp_file" "$config_file"
fi
```

**Effort**: 1-2 hours (enhance existing patterns)

---

### 2.4 Logging Without Exposing Secrets

**Requirement**: Debug info without leaking credentials.

#### Safe Logging Patterns

**BAD** (leaks secrets):

```bash
echo "Using token: $GITHUB_TOKEN"
log_to_file "DEBUG" "API call with token $GITHUB_TOKEN"
print_message "error" "Invalid token: $GITHUB_TOKEN"
```

**GOOD** (metadata only):

```bash
# Log token metadata, not value
echo "Using token from: GITHUB_TOKEN"
log_to_file "DEBUG" "API call with env var: GITHUB_TOKEN (provider: github)"
print_message "error" "Invalid token format (expected: ghp_*, got prefix: ${GITHUB_TOKEN:0:4}...)"

# Log length and format hints
local token_length="${#GITHUB_TOKEN}"
local token_prefix="${GITHUB_TOKEN:0:4}"
print_message "info" "Token prefix: ${token_prefix}..., length: ${token_length}"
```

**Redaction Function**:

```bash
#######################################
# Redact sensitive values from log output
# Arguments:
#   $1 - Text to redact
# Returns:
#   Redacted text to stdout
#######################################
redact_secrets() {
    local text="$1"

    # Redact GitHub tokens (leave prefix visible for debugging)
    text=$(echo "$text" | sed -E 's/(ghp_)[A-Za-z0-9]{32,}/\1**REDACTED**/g')
    text=$(echo "$text" | sed -E 's/(github_pat_)[A-Za-z0-9_]{78,}/\1**REDACTED**/g')

    # Redact Linear tokens
    text=$(echo "$text" | sed -E 's/(lin_api_)[A-Za-z0-9]{36,}/\1**REDACTED**/g')

    # Redact Anthropic tokens
    text=$(echo "$text" | sed -E 's/(sk-ant-)[A-Za-z0-9\-_]{91,}/\1**REDACTED**/g')

    # Redact Jira tokens (generic alphanumeric 24-32 chars near "token")
    text=$(echo "$text" | sed -E 's/(api_token["\s:=]+)[A-Za-z0-9]{24,32}/\1**REDACTED**/g')

    echo "$text"
}

# Usage
log_message() {
    local level="$1"
    local message="$2"

    # Redact before logging
    local safe_message
    safe_message=$(redact_secrets "$message")

    echo "[${level}] ${safe_message}" | tee -a "${LOG_FILE}"
}
```

**Testing Redaction**:

```bash
# Test redaction function
test_redaction() {
    local input="Token: ghp_1234567890abcdefghijklmnopqrstuv12 failed"
    local expected="Token: ghp_**REDACTED** failed"
    local actual
    actual=$(redact_secrets "$input")

    assert_equals "$expected" "$actual"
}
```

**Effort**: 2-3 hours (implement + test)

---

## 3. Dependencies & Integration

### 3.1 Pre-Commit Framework Integration

**Current State**:

```yaml
# .pre-commit-config.yaml - Already configured
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.18.2
    hooks:
      - id: gitleaks
```

**Required Additions**:

```yaml
# Add config-specific validation
- repo: local
  hooks:
    - id: validate-config-security
      name: Validate config file security
      entry: scripts/validate-config-security.sh
      language: script
      files: 'config\.json$'
      pass_filenames: false

    - id: validate-config-permissions
      name: Validate config file permissions
      entry: scripts/validate-config-permissions.sh
      language: script
      files: 'config\.json$'
      pass_filenames: false
```

**Installation**:

```bash
# Install pre-commit hooks (already documented in CLAUDE.md)
pre-commit install

# Run manually
pre-commit run --all-files

# Run only config validation
pre-commit run validate-config-security --all-files
```

**Dependencies**:

- Python 3.x (for pre-commit framework) ✅ Already required
- gitleaks ✅ Already in .pre-commit-config.yaml
- jq ✅ Already in validation.sh dependencies
- bash 3.2+ ✅ Already required

**No new dependencies** - all infrastructure exists.

**Effort**: 1 hour (add hooks to config, test)

---

### 3.2 Secret Scanning Tools

**Question from PRD**: Should we use existing secret scanners or build custom?

**Recommendation**: **Hybrid Approach**

#### Use Gitleaks (Existing)

**Pros**:

- ✅ Already integrated in pre-commit
- ✅ Industry-standard patterns (10,000+ stars on GitHub)
- ✅ Supports custom rules via `.gitleaks.toml`
- ✅ Fast (written in Go)
- ✅ CI/CD friendly

**Cons**:

- ❌ Generic patterns may not catch AIDA-specific issues
- ❌ No JSON structure validation (only regex-based)

**Use For**: Pattern-based token detection (GitHub, Linear, Anthropic, AWS keys)

#### Build Custom Validation (Complement Gitleaks)

**Pros**:

- ✅ JSON structure validation (detect `api_key` fields)
- ✅ AIDA-specific rules (config schema validation)
- ✅ Context-aware detection (Jira tokens only in `jira.*` namespace)
- ✅ No external dependencies (pure bash + jq)

**Cons**:

- ❌ Maintenance burden (must update as threats evolve)
- ❌ Potential for false negatives

**Use For**: Config-specific validation, JSON structure checks, AIDA schema enforcement

#### Recommended Architecture

```text
Pre-Commit Hook
├── Gitleaks (pattern-based secret detection)
│   ├── GitHub tokens (ghp_, github_pat_, etc.)
│   ├── Anthropic keys (sk-ant-*)
│   ├── Linear keys (lin_api_*)
│   ├── AWS keys (AKIA*)
│   └── Generic high-entropy strings
│
└── Custom Validation (AIDA-specific)
    ├── JSON structure (no api_key fields)
    ├── Config schema validation
    ├── File permissions (600/644)
    ├── Namespace validation (vcs.*, work_tracker.*)
    └── Environment variable references
```

**Why Hybrid**:

- **Defense in Depth**: Two layers catch more issues than one
- **Complementary**: Gitleaks = patterns, Custom = structure
- **Flexibility**: Can disable gitleaks in allowlisted dirs, custom validation always runs
- **Performance**: Both are fast (gitleaks is Go, custom is bash+jq)

**Other Tools Considered (NOT recommended)**:

| Tool | Reason Not Using |
|------|------------------|
| `detect-secrets` | Python dependency, slower than gitleaks, less maintained |
| `truffleHog` | Go binary, similar to gitleaks but less feature-rich |
| `git-secrets` | AWS-focused, limited pattern library |
| `tartufo` | Python, high false positive rate |

**Effort**: 0 hours (use existing gitleaks + custom validation already planned)

---

### 3.3 Permission Handling Cross-Platform

**Supported Platforms** (from PRD):

- macOS (primary)
- Linux (Ubuntu, Debian, Fedora, Arch)
- WSL2 (Windows Subsystem for Linux)

**Not Supported**: Native Windows (cmd.exe, PowerShell) - out of scope

#### Permission Enforcement by Platform

| Platform | stat Command | chmod Support | umask Support | Notes |
|----------|-------------|---------------|---------------|-------|
| macOS | `stat -f "%Lp"` | ✅ Full | ✅ Full | BSD stat, different flags |
| Linux | `stat -c "%a"` | ✅ Full | ✅ Full | GNU stat |
| WSL2 | `stat -c "%a"` | ✅ Full | ✅ Full | Linux kernel, GNU tools |

**Cross-Platform Abstraction** (already in validation.sh):

```bash
# validation.sh:162-169 - Platform detection
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS (BSD stat)
    perms=$(stat -f "%Lp" "$file" 2>/dev/null || echo "")
else
    # Linux (GNU stat)
    perms=$(stat -c "%a" "$file" 2>/dev/null || echo "")
fi
```

**Testing Matrix**:

| Platform | Test Environment | Validation |
|----------|-----------------|------------|
| macOS 14+ | Developer machine | Manual testing |
| Ubuntu 22.04 | Docker (`.github/testing/test-install.sh`) | Automated CI |
| Debian 12 | Docker | Automated CI |
| Fedora 39 | Docker | Automated CI |
| WSL2 (Ubuntu) | GitHub Actions (windows-latest) | Automated CI |

**No New Implementation Needed**: Existing `validation.sh` already handles cross-platform.

**Effort**: 0 hours (already implemented)

---

### 3.4 Audit Logging Requirements

**Requirement** (from PRD NFR1): Audit trail logs credential usage (not values).

#### Audit Log Design

**What to Log**:

- ✅ Credential validation attempts (success/failure)
- ✅ Provider used (github, jira, linear)
- ✅ Environment variable name (not value)
- ✅ Operation (token_validation, api_call, migration)
- ✅ Timestamp (UTC ISO 8601)
- ✅ User (for multi-user systems)
- ❌ **NEVER**: Actual token values

**Audit Log Format**:

```text
# ~/.claude/audit.log
2025-10-20T15:30:45Z | user:rob | token_validation | github | env_var:GITHUB_TOKEN | status:success
2025-10-20T15:31:12Z | user:rob | api_call | github | env_var:GITHUB_TOKEN | operation:list_issues | status:success
2025-10-20T15:35:00Z | user:rob | config_migration | N/A | operation:github_to_vcs | status:success | backup:config.json.backup.20251020-153500
2025-10-20T16:00:00Z | user:rob | token_validation | jira | env_var:JIRA_API_TOKEN | status:failure | reason:invalid_format
```

**Implementation**:

```bash
#!/usr/bin/env bash
# lib/installer-common/audit.sh

set -euo pipefail

# Audit log location
readonly AUDIT_LOG="${CLAUDE_DIR:-$HOME/.claude}/audit.log"

#######################################
# Log audit event
# Arguments:
#   $1 - Operation (token_validation, api_call, config_migration)
#   $2 - Provider (github, jira, linear, N/A)
#   $3 - Status (success, failure)
#   $4+ - Additional key=value pairs
# Returns:
#   0 always
#######################################
log_audit_event() {
    local operation="$1"
    local provider="$2"
    local status="$3"
    shift 3

    local timestamp
    timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)

    local user="${USER:-unknown}"

    # Build audit entry
    local entry="${timestamp} | user:${user} | ${operation} | ${provider} | status:${status}"

    # Add additional key=value pairs
    for arg in "$@"; do
        entry="${entry} | ${arg}"
    done

    # Create audit log if it doesn't exist
    if [[ ! -f "$AUDIT_LOG" ]]; then
        touch "$AUDIT_LOG"
        chmod 600 "$AUDIT_LOG"  # Restrictive permissions
    fi

    # Append to audit log
    echo "$entry" >> "$AUDIT_LOG"

    return 0
}

# Usage examples:
# log_audit_event "token_validation" "github" "success" "env_var:GITHUB_TOKEN"
# log_audit_event "api_call" "github" "success" "env_var:GITHUB_TOKEN" "operation:list_issues"
# log_audit_event "config_migration" "N/A" "success" "operation:github_to_vcs" "backup:config.json.backup.20251020-153500"
# log_audit_event "token_validation" "jira" "failure" "env_var:JIRA_API_TOKEN" "reason:invalid_format"
```

**Audit Log Rotation** (optional):

```bash
# Rotate audit logs monthly (keep last 12 months)
rotate_audit_log() {
    local audit_log="${CLAUDE_DIR}/audit.log"

    if [[ ! -f "$audit_log" ]]; then
        return 0
    fi

    # Check if log is > 1 MB or > 1 month old
    local log_size
    log_size=$(stat -f "%z" "$audit_log" 2>/dev/null || stat -c "%s" "$audit_log" 2>/dev/null)

    if [[ $log_size -gt 1048576 ]]; then  # > 1 MB
        local timestamp
        timestamp=$(date -u +%Y%m)

        # Archive current log
        cp "$audit_log" "${audit_log}.${timestamp}"
        chmod 600 "${audit_log}.${timestamp}"

        # Truncate current log
        echo "# Audit log rotated $(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$audit_log"
        chmod 600 "$audit_log"

        # Delete logs older than 12 months
        find "$(dirname "$audit_log")" -name "audit.log.*" -mtime +365 -delete
    fi
}
```

**Privacy Compliance**:

- ✅ **GDPR Article 30**: Records of processing activities
- ✅ **No PII**: Uses usernames (public identifiers), not emails
- ✅ **Retention**: 12 months (configurable)
- ✅ **Right to Access**: User can read their own audit log
- ✅ **Right to Erasure**: User can delete their own audit log

**Effort**: 3-4 hours

- Audit logging function: 1.5 hours
- Log rotation: 1 hour
- Integration with token validation: 1 hour
- Testing: 1 hour

---

## 4. Effort & Complexity

### 4.1 Secret Detection Pattern Complexity

**Complexity**: MEDIUM

**Breakdown**:

| Task | Complexity | Effort | Rationale |
|------|-----------|--------|-----------|
| GitHub token patterns | LOW | 1 hour | Well-defined formats, high confidence |
| Linear token patterns | LOW | 0.5 hours | Unique prefix, minimal false positives |
| Anthropic token patterns | LOW | 0.5 hours | Long, unique prefix |
| Jira token patterns | MEDIUM | 2 hours | Generic format, needs context checking |
| Gitleaks.toml enhancement | LOW | 1 hour | Add new rules to existing config |
| Custom JSON validation | MEDIUM | 2 hours | Structure checking, namespace validation |
| Testing & validation | MEDIUM | 2 hours | Test with fake tokens, verify no false positives |

**Total**: 9 hours

**Risk**: LOW - Patterns are well-documented by providers.

---

### 4.2 Cross-Platform Permission Handling

**Complexity**: LOW

**Breakdown**:

| Task | Complexity | Effort | Rationale |
|------|-----------|--------|-----------|
| macOS support | DONE | 0 hours | Already in validation.sh |
| Linux support | DONE | 0 hours | Already in validation.sh |
| WSL2 support | DONE | 0 hours | Uses Linux kernel/tools |
| Testing on all platforms | LOW | 2 hours | Run in Docker + GitHub Actions |

**Total**: 2 hours

**Risk**: VERY LOW - Existing code already cross-platform.

---

### 4.3 Testing Security Validations

**Complexity**: MEDIUM-HIGH (comprehensive testing required)

**Breakdown**:

| Test Suite | Complexity | Effort | Rationale |
|------------|-----------|--------|-----------|
| Token pattern detection | MEDIUM | 3 hours | Test all provider formats, edge cases |
| Pre-commit hook integration | LOW | 1 hour | Verify hooks trigger on config files |
| File permission enforcement | LOW | 2 hours | Test 600/644, cross-platform |
| Secure backup/restore | MEDIUM | 3 hours | Test atomic operations, rollback |
| Environment validation | MEDIUM | 2 hours | Test format validation, error messages |
| Audit logging | LOW | 1.5 hours | Test log format, rotation |
| End-to-end migration | HIGH | 4 hours | Test full migration with all security checks |

**Total**: 16.5 hours

**Risk**: MEDIUM - Security testing requires careful validation.

---

### 4.4 Total Effort Estimate

| Component | Hours |
|-----------|-------|
| **1. Implementation** | |
| Pre-commit hooks | 6 |
| File permissions | 4 |
| Environment validation | 7 |
| Secure backup/restore | 8 |
| **2. Integration** | |
| Pre-commit framework | 1 |
| Audit logging | 4 |
| **3. Testing** | |
| Security validations | 16.5 |
| **Total** | **46.5 hours** |

**Confidence**: MEDIUM-HIGH

**Assumptions**:

- Leverage existing infrastructure (gitleaks, validation.sh, migrations.sh)
- No new external dependencies
- Standard bash/jq tooling
- Cross-platform already handled

**Risk Contingency**: +20% (9 hours) for edge cases, documentation

**Total with Contingency**: **55.5 hours** (~7 working days)

---

## 5. Questions & Clarifications

### Q1: Should we use existing secret scanners or build custom?

**Answer**: **Hybrid Approach** (recommended above)

- ✅ Use gitleaks for pattern-based detection
- ✅ Build custom validation for AIDA-specific structure checks
- ✅ Both layers provide defense in depth

**Rationale**: Gitleaks is industry-standard and fast. Custom validation adds AIDA-specific intelligence (JSON structure, namespace validation, config schema).

---

### Q2: How to handle secrets accidentally committed historically?

**Scenario**: User already committed config with embedded token to git history.

**Strategy**: **Git History Rewriting** (DANGEROUS - user opt-in only)

#### Detection

```bash
# Scan git history for secrets
gitleaks detect --source=. --log-opts="--all"

# Find commits with secrets in config files
git log --all --oneline -- '*.config.json' | while read commit hash file; do
    if gitleaks detect --source=. --log-opts="${commit}"; then
        echo "Commit ${commit} contains secrets in ${file}"
    fi
done
```

#### Remediation Options

**Option 1: BFG Repo-Cleaner** (recommended for large repos)

```bash
# Install BFG
brew install bfg  # macOS
# or download from https://rtyley.github.io/bfg-repo-cleaner/

# Replace secrets with placeholder
bfg --replace-text secrets.txt  # secrets.txt contains patterns to replace

# Rewrite history
git reflog expire --expire=now --all
git gc --prune=now --aggressive
```

**Option 2: git-filter-repo** (more control)

```bash
# Install git-filter-repo
pip install git-filter-repo

# Remove secrets from history
git filter-repo --path config.json --invert-paths --force
```

**Option 3: Manual history rewrite** (for small repos)

```bash
# Interactive rebase to edit commits
git rebase -i --root

# Amend each commit to remove secrets
# WARNING: Changes commit SHAs, breaks shared history
```

**User Warning** (show before any history rewriting):

```text
⚠️  WARNING: Git History Rewriting Detected

Secrets found in git history. To remove them, we must rewrite git history.

CONSEQUENCES:
  - All commit SHAs will change
  - Anyone with cloned repo must re-clone
  - Open pull requests will break
  - CI/CD pipelines may fail until updated

ALTERNATIVE:
  - Revoke exposed secrets immediately (GitHub, Jira, Linear)
  - Generate new secrets
  - Leave old commits in history (secrets already compromised)

RECOMMENDATION:
  - If secrets are already public: REVOKE IMMEDIATELY
  - If repo is private: Consider history rewrite
  - If repo is shared: Coordinate with team before rewriting

Proceed with history rewrite? (yes/NO)
```

**Implementation**:

```bash
#!/usr/bin/env bash
# scripts/cleanup-git-secrets.sh

detect_secrets_in_history() {
    print_message "warning" "Scanning git history for secrets..."

    # Use gitleaks to scan all history
    if gitleaks detect --source=. --log-opts="--all" --report-path=secrets-report.json; then
        print_message "success" "No secrets found in git history"
        return 0
    else
        print_message "error" "Secrets detected in git history"

        # Parse gitleaks report
        local secret_count
        secret_count=$(jq length secrets-report.json)

        print_message "info" "Found ${secret_count} secret(s) in history"
        print_message "info" "Review report: secrets-report.json"

        # Show warning
        show_history_rewrite_warning

        return 1
    fi
}

cleanup_secrets_from_history() {
    # User must explicitly opt-in
    read -p "Proceed with history rewrite? (yes/NO) " -r
    if [[ ! $REPLY =~ ^yes$ ]]; then
        print_message "info" "History rewrite cancelled"
        print_message "info" "IMPORTANT: Revoke exposed secrets immediately"
        return 1
    fi

    # Recommend BFG or git-filter-repo (don't implement here)
    print_message "info" "Use BFG Repo-Cleaner or git-filter-repo to rewrite history"
    print_message "info" "See: docs/security/removing-secrets-from-history.md"
}
```

**Recommendation**: **Provide detection + documentation, NOT automated cleanup**

**Rationale**:

- History rewriting is dangerous (can break repos)
- User should understand consequences before running
- External tools (BFG, git-filter-repo) are better than DIY
- Provide clear documentation, don't automate

**Effort**: 4-6 hours (detection + documentation, no automated cleanup)

---

### Q3: What's the audit trail for config changes?

**Answer**: Two-level auditing

#### Level 1: Git History (Team-Visible)

```bash
# Track who changed config and when
git log --follow -- .aida/config.json

# See specific changes
git diff HEAD~1 HEAD -- .aida/config.json
```

**Provides**:

- ✅ Who changed config (git author)
- ✅ When it was changed (commit timestamp)
- ✅ What was changed (git diff)
- ✅ Why it was changed (commit message)

**Limitations**:

- ❌ User configs (`~/.claude/config.json`) NOT in git
- ❌ No record of failed validation attempts
- ❌ No record of environment variable usage

#### Level 2: Audit Log (User-Private)

```text
# ~/.claude/audit.log
2025-10-20T15:35:00Z | user:rob | config_migration | N/A | operation:github_to_vcs | status:success | backup:config.json.backup.20251020-153500
2025-10-20T15:40:00Z | user:rob | config_update | N/A | field:vcs.github.owner | old_value:REDACTED | new_value:REDACTED | status:success
```

**Provides**:

- ✅ User config changes (not in git)
- ✅ Migration operations
- ✅ Validation failures
- ✅ Environment variable usage metadata

**Limitations**:

- ❌ Only accessible to individual user (not team)
- ❌ Can be deleted by user (not tamper-proof)

#### Recommended Audit Scope

| Event | Git History | Audit Log | Notes |
|-------|------------|-----------|-------|
| Project config change | ✅ | ❌ | Git commit shows who/what/when/why |
| User config change | ❌ | ✅ | Not in git, logged locally |
| Config migration | ❌ | ✅ | User operation, not committed |
| Validation failure | ❌ | ✅ | Pre-commit hook blocks, but log records attempt |
| Token validation | ❌ | ✅ | Environment variable usage (metadata only) |
| API call | ❌ | ✅ | Record provider/operation/status |

**GDPR Compliance**:

- ✅ Right to Access: User can read `~/.claude/audit.log`
- ✅ Right to Erasure: User can delete audit log
- ✅ Data Minimization: Log only metadata, not values
- ✅ Storage Limitation: Rotate logs after 12 months

**Effort**: 4 hours (already estimated in audit logging section)

---

### Q4: Should we support encrypted config files (future)?

**Answer**: **Yes, but defer to future issue** (not in Issue #55 scope)

**Use Case**: User wants to commit config to git (even with secrets) by encrypting it.

**Approach** (future consideration):

```bash
# Encrypt config before commit
aida-config-helper.sh --encrypt ~/.claude/config.json

# Decrypts to temporary file, validates, re-encrypts
aida-config-helper.sh --edit ~/.claude/config.json

# Decrypt for use (in-memory only)
aida-config-helper.sh --decrypt ~/.claude/config.json
```

**Encryption Strategy**:

- **GPG**: Use user's existing GPG key
- **Age**: Modern alternative to GPG (simpler)
- **git-crypt**: Transparent encryption in git repos
- **SOPS**: Secret management (supports GPG, Age, KMS)

**Recommended**: **git-crypt** (for project configs) + **Age** (for user configs)

**Why git-crypt**:

- ✅ Transparent encryption (git diff works on decrypted content)
- ✅ Per-file encryption (.gitattributes defines which files)
- ✅ Team collaboration (multiple GPG keys)
- ✅ No plaintext in repo (only encrypted blobs)

**Why Age**:

- ✅ Simpler than GPG (no key servers, no web of trust)
- ✅ Modern cryptography (ChaCha20-Poly1305)
- ✅ Small, auditable codebase
- ✅ Good for user configs (single key)

**Example** (future):

```bash
# Install git-crypt
brew install git-crypt  # macOS
apt-get install git-crypt  # Debian/Ubuntu

# Initialize encryption for project
cd .aida
git-crypt init

# Configure which files to encrypt
echo "config.json filter=git-crypt diff=git-crypt" >> .gitattributes

# Commit encrypted config
git add config.json .gitattributes
git commit -m "Add encrypted config"

# Other team members unlock with their GPG key
git-crypt unlock
```

**Security Considerations**:

| Aspect | Concern | Mitigation |
|--------|---------|------------|
| Key management | Where to store decryption key? | GPG key on user's machine, Age key in keychain |
| Key rotation | How to rotate if key compromised? | git-crypt supports key rotation, history rewrite required |
| Backup | Encrypted config = encrypted backups | Store decryption key separately (recovery phrase) |
| Team access | How do new team members decrypt? | git-crypt add-gpg-user, re-encrypt for new key |

**Recommendation**: **Create Issue #60** for encrypted config support

**Scope for #60**:

- git-crypt integration for project configs
- Age encryption for user configs
- Key management documentation
- Migration from plaintext to encrypted configs
- Recovery procedures (lost key)

**Effort Estimate** (for future Issue #60): 40-50 hours

**Decision for Issue #55**: **OUT OF SCOPE** - Plaintext configs with secrets in env vars is sufficient for v1.0.

---

## 6. Recommendations

### 6.1 Immediate Actions (Issue #55)

**Priority 1: MUST HAVE** (blocking)

1. ✅ **Enhance gitleaks.toml** with config-specific patterns
   - GitHub, Jira, Linear, Anthropic token patterns
   - Path-based rules (`config.json` files)
   - Allowlist for test fixtures

2. ✅ **Create custom config validation script**
   - JSON structure validation (no `api_key` fields)
   - Environment variable reference checking
   - File permission validation

3. ✅ **Implement secure backup/restore**
   - Atomic backup before migrations
   - Validation before AND after backup
   - Automatic rollback on migration failure

4. ✅ **Add file permission enforcement**
   - User config: 600 at creation
   - Project config: 644 at creation
   - Pre-commit validation

**Priority 2: SHOULD HAVE** (high value)

5. ✅ **Environment variable validation**
   - Token format checking (without logging values)
   - Provider-specific validators
   - Secure error messages

6. ✅ **Audit logging**
   - Credential usage metadata (not values)
   - Config change tracking
   - Log rotation (12 months)

7. ✅ **Documentation**
   - Security model (secrets in env vars only)
   - Migration safety (backup/restore)
   - Incident response (historical secrets)

**Priority 3: NICE TO HAVE** (defer if time-constrained)

8. ❌ **Git history scanning** (defer to docs)
   - Detection only (gitleaks)
   - Manual cleanup instructions
   - No automated history rewriting

9. ❌ **Encrypted configs** (defer to Issue #60)
   - Out of scope for v1.0
   - Create separate issue for git-crypt/Age integration

---

### 6.2 Long-Term Improvements (Future Issues)

#### Issue #60: Encrypted Config Support

- git-crypt for project configs (team collaboration)
- Age for user configs (simple, modern)
- Key management and rotation
- Migration from plaintext

#### Issue #61: Advanced Secret Detection

- Entropy-based detection (high-entropy strings)
- Machine learning patterns (anomaly detection)
- Custom provider plugins (extensible)
- Real-time API validation (optional)

#### Issue #62: Security Hardening

- Mandatory code signing for installer scripts
- Integrity verification (checksums, signatures)
- Sandboxed execution (Docker, VMs)
- Security audit mode (comprehensive scanning)

---

### 6.3 Risk Mitigation Strategy

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| **Secrets committed to git** | HIGH | CRITICAL | Pre-commit hooks + gitleaks + custom validation |
| **Race conditions (TOCTOU)** | LOW | MEDIUM | Atomic operations, umask, mktemp |
| **Failed migration (data loss)** | MEDIUM | HIGH | Automatic backups, rollback, validation |
| **Permission issues (cross-platform)** | LOW | MEDIUM | Existing validation.sh handles this |
| **Audit log tampering** | MEDIUM | LOW | 600 permissions, user-only access (acceptable) |
| **False positives (blocks valid configs)** | MEDIUM | LOW | Allowlist, context-aware detection |
| **Historical secrets exposure** | HIGH | CRITICAL | Detection + documentation (no auto-cleanup) |

**Overall Risk**: **MEDIUM** (well-managed with recommended mitigations)

---

## 7. Implementation Checklist

### Phase 1: Core Security (Week 1)

- [ ] Enhance `.gitleaks.toml` with provider-specific patterns
- [ ] Create `scripts/validate-config-security.sh` (JSON structure)
- [ ] Create `scripts/validate-config-permissions.sh` (600/644)
- [ ] Add pre-commit hooks to `.pre-commit-config.yaml`
- [ ] Test pre-commit hooks with fake tokens

### Phase 2: Environment & Backup (Week 2)

- [ ] Create `lib/installer-common/token-validator.sh`
- [ ] Implement `validate_github_token()`, `validate_jira_token()`, `validate_linear_token()`
- [ ] Create `lib/installer-common/config-migration.sh`
- [ ] Implement `create_config_backup()`, `restore_config_backup()`, `migrate_config_with_backup()`
- [ ] Test backup/restore with migrations

### Phase 3: Audit & Documentation (Week 3)

- [ ] Create `lib/installer-common/audit.sh`
- [ ] Implement `log_audit_event()`, `rotate_audit_log()`
- [ ] Document security model (`docs/security/config-security.md`)
- [ ] Document migration safety (`docs/security/config-migrations.md`)
- [ ] Document incident response (`docs/security/removing-secrets-from-history.md`)

### Phase 4: Testing & Validation (Week 4)

- [ ] Create `tests/security/test-token-detection.sh`
- [ ] Create `tests/security/test-file-permissions.sh`
- [ ] Create `tests/security/test-backup-restore.sh`
- [ ] Run security tests on all platforms (macOS, Linux, WSL2)
- [ ] Fix any issues found during testing

---

## Appendix A: Token Format Reference

| Provider | Format | Regex | Length | Example |
|----------|--------|-------|--------|---------|
| **GitHub - Classic PAT** | `ghp_XXXX...` | `^ghp_[A-Za-z0-9]{36}$` | 40 | `ghp_1234567890abcdefghij1234567890abcd` |
| **GitHub - Fine-grained PAT** | `github_pat_XXXX...` | `^github_pat_[A-Za-z0-9_]{82}$` | 93 | `github_pat_11ABCDEF...` |
| **GitHub - OAuth** | `gho_XXXX...` | `^gho_[A-Za-z0-9]{36}$` | 40 | `gho_1234567890abcdefghij1234567890abcd` |
| **Jira - API Token** | `[A-Za-z0-9]{24-32}` | `^[A-Za-z0-9]{24,32}$` | 24-32 | `aBcDeFgHiJkLmNoPqRsTuVwX` |
| **Linear - API Key** | `lin_api_XXXX...` | `^lin_api_[A-Za-z0-9]{40}$` | 48 | `lin_api_1234567890abcdefghij1234567890abcd1234` |
| **Anthropic - API Key** | `sk-ant-XXXX...` | `^sk-ant-[A-Za-z0-9\-_]{95,}$` | 99+ | `sk-ant-api03-abc123...` |

---

## Appendix B: File Permission Matrix

| File Type | Path | User Perms | Group Perms | Other Perms | Octal | Committed to Git |
|-----------|------|-----------|-------------|-------------|-------|------------------|
| User config | `~/.claude/config.json` | rw- | --- | --- | 600 | ❌ NO |
| Project config | `.aida/config.json` | rw- | r-- | r-- | 644 | ✅ YES |
| Schema | `lib/installer-common/config-schema.json` | rw- | r-- | r-- | 644 | ✅ YES |
| Backup (user) | `~/.claude/config.json.backup.*` | rw- | --- | --- | 600 | ❌ NO |
| Backup (project) | `.aida/config.json.backup.*` | rw- | r-- | r-- | 644 | ❌ NO (gitignored) |
| Audit log | `~/.claude/audit.log` | rw- | --- | --- | 600 | ❌ NO |

---

## Appendix C: Security Testing Matrix

| Test Case | Expected Result | Validation Method |
|-----------|----------------|-------------------|
| **Secret Detection - Config with GitHub PAT** | Pre-commit blocks | gitleaks + custom hook |
| **Secret Detection - Config with Jira token in `jira.api_token`** | Pre-commit blocks | Custom JSON validation |
| **Secret Detection - Config with Linear key** | Pre-commit blocks | gitleaks |
| **Secret Detection - Config with example token (`ghp_XXXX...`)** | Pre-commit allows | Allowlist pattern |
| **File Permissions - User config created with 600** | Success | stat command |
| **File Permissions - Project config created with 644** | Success | stat command |
| **File Permissions - World-writable config committed** | Pre-commit blocks | Permission validation hook |
| **Backup/Restore - Backup created before migration** | Backup file exists | Test migration function |
| **Backup/Restore - Migration fails → config restored** | Original config unchanged | Rollback test |
| **Backup/Restore - Backup is valid JSON** | Validation succeeds | jq validation |
| **Environment Validation - Valid GitHub token format** | Success | Token validator |
| **Environment Validation - Invalid GitHub token format** | Error with hint | Token validator |
| **Environment Validation - Missing environment variable** | Error with setup instructions | Token validator |
| **Environment Validation - Token logged in error** | FAIL (security violation) | Log inspection |

---

## End of Analysis

**Next Steps**:

1. Review with Tech Lead for architecture approval
2. Review with DevOps Engineer for CI/CD integration
3. Review with UX Designer for error message templates
4. Create implementation tasks in Issue #55
5. Begin Phase 1: Core Security (estimated 12 hours)

**Estimated Total Implementation**: 46.5 hours (core) + 9 hours (contingency) = **55.5 hours**
