---
title: "Privacy & Security Analysis - Configuration System (Issue #55)"
agent: "privacy-security-auditor"
issue: 55
analysis_type: "product"
date: "2025-10-20"
status: "draft"
---

# Privacy & Security Analysis: Configuration System

## Context Detection

**Project-level privacy config**: Found at `.claude/project/context/privacy-security-auditor/`
**User-level knowledge**: Not found (using generic best practices)

Proceeding with project-specific privacy standards and generic security principles.

---

## 1. Domain-Specific Security Concerns

### Credential Storage Architecture

**CRITICAL SEPARATION REQUIRED**:

- **Environment variables ONLY**: `GITHUB_TOKEN`, `JIRA_TOKEN`, `LINEAR_API_KEY`, `VCS_TOKEN`
- **Config files (safe)**: Usernames, repo names, team lists, project keys, preferences
- **NEVER in config files**: API keys, tokens, passwords, secrets

**File Permission Requirements**:

- User-level config (`~/.claude/config.yml`): `600` (owner read/write only)
- Project-level config (`.github/workflow-config.json`): `644` (readable by team, not writable)
- Reason: User config may contain personal preferences; project config is team-shared

### Token Validation & Rotation

**Validation Framework Must Check**:

- Tokens exist in environment (not in config files)
- Token format validation (GitHub: `ghp_*`, Jira: bearer tokens)
- Token expiry detection (if provider supports it)
- **Warning if sensitive data detected in config files**

**Rotation Strategy**:

- Document token rotation procedures (update env vars, not config)
- Validate commands work after rotation (no hardcoded tokens)
- Config files should reference env var names, never values

### Secret Detection Patterns

**Implement pre-commit validation**:

```bash
# Patterns to flag in config files
secret_patterns = {
    'github_token': r'ghp_[a-zA-Z0-9]{36}',
    'jira_token': r'[A-Za-z0-9_-]{20,}',  # Generic bearer token
    'api_key': r'(api[_-]?key|secret[_-]?key).*[:=]\s*["\']?[A-Za-z0-9_-]{20,}',
}
```

**Action on detection**:

- Block commit if secrets found in config
- Provide clear error message with remediation
- Suggest environment variable alternative

---

## 2. Stakeholder Impact Analysis

### Users (Individual Developers)

#### Risk: Accidental Secret Commits

- **Likelihood**: HIGH - copy/paste tokens into config files
- **Impact**: CRITICAL - exposed credentials in git history
- **Mitigation**:
  - Add `.claude/config.yml` to `.gitignore` by default
  - Validation warns on secret-like patterns
  - Clear documentation: "Never put tokens in config files"

#### Risk: Insecure File Permissions

- **Likelihood**: MEDIUM - users may not set restrictive permissions
- **Impact**: MEDIUM - local privilege escalation or data exposure
- **Mitigation**:
  - Installer sets `chmod 600 ~/.claude/config.yml` automatically
  - Validation checks and warns on permissive permissions

### Teams (Shared Projects)

#### Risk: Sharing Config Without Exposing Tokens

- **Solution**: Project-level config contains NO secrets
- **Architecture**:
  - `.github/workflow-config.json` - Team metadata (repo, reviewers, preferences)
  - Environment variables per developer - Personal tokens
- **Benefit**: Config can be committed to git safely

#### Risk: Token Confusion (Which token for which project?)

- **Solution**: Standardize env var names in config
- **Pattern**:

  ```yaml
  vcs:
    provider: github
    token_env_var: GITHUB_TOKEN  # Document which env var to set
  ```

### CI/CD Systems

#### Risk: Secure Token Injection

- **Solution**: GitHub Actions secrets, not config files
- **Pattern**:

  ```yaml
  - name: Run workflow command
    env:
      GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      JIRA_TOKEN: ${{ secrets.JIRA_TOKEN }}
    run: ./scripts/workflow-command.sh
  ```

#### Risk: Config validation in CI

- **Solution**: Run security checks in CI
- **Validation**:
  - Confirm no secrets in config files
  - Verify required env vars are set
  - Check file permissions (if applicable)

---

## 3. Questions & Clarifications

### Validation Strategy

**Q: Should we validate that tokens are in environment (not in files)?**

- **A: YES - MANDATORY**
- Scan config files for secret patterns on save/commit
- Fail validation if secrets detected
- Provide clear remediation: "Move X to environment variable Y"

**Q: What warnings to show if sensitive data detected in config?**

- **A: Blocking errors, not warnings**

  ```text
  ERROR: Potential secret detected in config file
  File: ~/.claude/config.yml
  Line: 12
  Pattern: API key or token

  REMEDIATION:
  1. Remove the secret from the config file
  2. Set environment variable: export GITHUB_TOKEN="your-token"
  3. Reference in config: token_env_var: "GITHUB_TOKEN"
  ```

**Q: How to handle multi-user access to shared config?**

- **A: Two-tier architecture**
  - **User config** (`~/.claude/config.yml`): Personal preferences, `600` permissions
  - **Project config** (`.github/workflow-config.json`): Team settings, `644` permissions, committed to git
  - **Rule**: Project config NEVER contains secrets

**Q: Should config files be in .gitignore by default?**

- **A: PARTIAL**
  - User config (`~/.claude/config.yml`): YES - personal, not committed
  - Project config (`.github/workflow-config.json`): NO - shared, committed to git
  - Current `.gitignore` already includes `.claude/workflow-config.json` ✅

---

## 4. Security Recommendations

### Credential Management Strategy

**1. Strict Separation**:

```yaml
# SAFE - Project config (.github/workflow-config.json, committed to git)
workflow:
  vcs:
    provider: github
    owner: oakensoul
    repo: claude-personal-assistant
  reviewers:
    - github-copilot[bot]
  jira:
    project_key: AIDA
    base_url: https://company.atlassian.net

# SAFE - User config (~/.claude/config.yml, NOT committed, references env vars)
credentials:
  github_token_env: GITHUB_TOKEN
  jira_token_env: JIRA_TOKEN

# UNSAFE - NEVER DO THIS
credentials:
  github_token: ghp_1234567890abcdef  # ❌ WRONG - secrets in config
```

**2. Environment Variable Pattern**:

- Standardize env var names: `GITHUB_TOKEN`, `JIRA_TOKEN`, `LINEAR_API_KEY`, `VCS_TOKEN`
- Document in README: "Required environment variables"
- Validation checks env vars exist before running commands
- Fail fast with clear error if missing

**3. Token Storage Options** (in order of preference):

- **Best**: OS keychain/keyring (macOS Keychain, Linux Secret Service)
- **Good**: Environment variables in secure shell (`~/.zshrc.local`, not committed)
- **Acceptable**: Encrypted dotfiles-private repo
- **NEVER**: Plain text in config files or git repositories

### Config File Security Guidelines

**File Permissions (Automated)**:

```bash
# Installer must set permissions
chmod 600 ~/.claude/config.yml           # User config (personal)
chmod 644 .github/workflow-config.json   # Project config (team-readable)
```

**Validation Checks (Pre-commit Hook)**:

- Scan for secret patterns before commit
- Verify file permissions on sensitive files
- Check `.gitignore` includes user config
- Fail commit if issues found

**Security Validation Script** (`scripts/validate-config-security.sh`):

```bash
#!/usr/bin/env bash
# Validate config files for security issues

check_secrets_in_config() {
  # Scan for tokens, API keys, passwords
  if grep -qE '(ghp_|api[_-]?key.*[:=]|token.*[:=]|password.*[:=])' "$1"; then
    echo "ERROR: Potential secret detected in $1"
    return 1
  fi
}

check_file_permissions() {
  # Verify restrictive permissions on user config
  perms=$(stat -f "%A" ~/.claude/config.yml 2>/dev/null || stat -c "%a" ~/.claude/config.yml 2>/dev/null)
  if [ "$perms" != "600" ]; then
    echo "WARNING: ~/.claude/config.yml has permissive permissions ($perms), should be 600"
  fi
}
```

### Documentation for Secure Setup

**README Section: "Security & Credentials"**:

```markdown
## Security & Credentials

### Required Environment Variables

Set these in your shell configuration (~/.zshrc, ~/.bashrc):

export GITHUB_TOKEN="ghp_your_github_token"
export JIRA_TOKEN="your_jira_token"

NEVER commit tokens to git. Store in environment variables or OS keychain.

### Configuration Files

- User config (~/.claude/config.yml): Personal settings, NOT committed
- Project config (.github/workflow-config.json): Team settings, committed to git

Project config contains NO secrets - only metadata like repo names and team members.

### Token Rotation

To rotate credentials:
1. Generate new token in provider (GitHub, Jira, etc.)
2. Update environment variable: export GITHUB_TOKEN="new_token"
3. Test: ./scripts/validate-config.sh
4. Revoke old token in provider

No config file changes needed.
```

### Validation Warnings for Security Issues

**Implement in config validation**:

```python
def validate_config_security(config_file):
    """
    Security validation for config files.
    Returns list of security issues found.
    """
    issues = []

    # Check for secrets in config
    with open(config_file) as f:
        content = f.read()
        if re.search(r'ghp_[a-zA-Z0-9]{36}', content):
            issues.append("ERROR: GitHub token detected in config - move to GITHUB_TOKEN env var")
        if re.search(r'(api[_-]?key|token|password).*[:=]\s*["\']?[A-Za-z0-9_-]{20,}', content):
            issues.append("ERROR: Potential secret detected - move to environment variable")

    # Check file permissions (user config only)
    if config_file.endswith('config.yml'):
        perms = os.stat(config_file).st_mode & 0o777
        if perms != 0o600:
            issues.append(f"WARNING: File permissions {oct(perms)} too permissive - should be 0600")

    return issues
```

---

## 5. Compliance Considerations

### GDPR & Privacy

**Personal Data in Config**:

- **Usernames**: Low risk (public identifiers)
- **Email addresses**: Medium risk (PII) - avoid in committed config
- **Team member lists**: Use GitHub handles, not real names

**Recommendation**:

- Project config uses GitHub usernames (public)
- User config may contain email (not committed)
- Never commit user config to git

### Audit Trail

**Log credential usage** (not values):

```text
2025-10-20 10:30:00 - GitHub API called with token from env:GITHUB_TOKEN
2025-10-20 10:30:01 - Token validated successfully
```

**Do NOT log**:

- Token values
- API responses containing sensitive data
- Failed authentication details (info disclosure)

---

## Priority Security Requirements

### MUST HAVE (Blocking)

1. ✅ **`.gitignore` includes user config** - Already done (`.claude/workflow-config.json`)
2. ⚠️ **Secret detection pre-commit hook** - Not yet implemented
3. ⚠️ **File permission enforcement** - Not yet implemented (installer should set)
4. ⚠️ **Environment variable validation** - Not yet implemented

### SHOULD HAVE (High Priority)

1. Documentation: Security & credentials section in README
2. Validation script: `validate-config-security.sh`
3. Clear error messages for missing env vars
4. Token rotation documentation

### NICE TO HAVE (Future)

1. OS keychain integration (macOS Keychain, Linux Secret Service)
2. Token expiry detection and warnings
3. Automated token refresh (OAuth flows)
4. Encrypted config backup (for user preferences)

---

## Next Steps

1. **Implement secret detection**: Pre-commit hook to scan config files
2. **Enforce file permissions**: Installer sets `chmod 600` on user config
3. **Document security model**: Add security section to README
4. **Create validation script**: `scripts/validate-config-security.sh`
5. **Update .gitignore**: Ensure all user configs excluded
6. **Test token rotation**: Verify commands work after env var update

---

## Risk Assessment Summary

| Risk | Likelihood | Impact | Mitigation Status |
|------|-----------|--------|-------------------|
| Secrets committed to git | HIGH | CRITICAL | ⚠️ Partial (.gitignore exists, pre-commit hook needed) |
| Insecure file permissions | MEDIUM | MEDIUM | ⚠️ Not implemented (installer should enforce) |
| Token confusion (wrong env var) | MEDIUM | LOW | ⚠️ Documentation needed |
| Token exposure in logs | LOW | HIGH | ✅ Good (not logging tokens) |
| Multi-user config conflicts | LOW | LOW | ✅ Good (two-tier architecture) |

**Overall Risk Level**: MEDIUM
**Blockers**: Secret detection, file permissions, documentation

---

**Generated by**: privacy-security-auditor agent
**Date**: 2025-10-20
**Project Context**: AIDA framework - public repository with team collaboration
