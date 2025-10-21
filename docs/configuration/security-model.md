---
title: "Configuration Security Model"
description: "Security best practices for AIDA configuration system"
category: "security"
tags: ["security", "secrets", "config", "compliance"]
last_updated: "2025-10-20"
status: "published"
audience: "developers"
---

# Configuration Security Model

## Overview

AIDA's configuration system is designed with security-first principles to prevent accidental exposure of secrets. This document outlines the security architecture, threat model, and best practices for managing configuration files safely.

**Core Principle**: Configuration files NEVER contain secrets. They contain metadata and references to secrets stored securely elsewhere.

## Security Principles

### Separation of Config and Secrets

AIDA enforces a strict boundary between configuration metadata and sensitive credentials:

**Configuration** (safe to commit):

- Repository URLs
- Usernames (public identifiers)
- Team settings
- Workflow preferences
- Tool integration settings
- File paths and directories

**Secrets** (never commit):

- API keys
- Access tokens
- Passwords
- Private keys
- OAuth credentials
- Encryption keys

### Where Secrets Belong

Secrets should be stored in secure, purpose-built systems:

1. **Environment variables** (recommended for local development)
   - Isolated per-process
   - Not committed to version control
   - Easy to rotate

2. **Secret managers** (recommended for production and teams)
   - 1Password, AWS Secrets Manager, HashiCorp Vault
   - Audit trails and access controls
   - Automatic rotation support

3. **Encrypted files** (personal use)
   - GPG-encrypted files
   - OS keychain/keyring
   - Password managers

### Where Secrets DON'T Belong

The following locations are UNSAFE for secrets:

- Configuration files (JSON/YAML)
- Git repositories (public or private)
- Shell history
- Log files
- Error messages
- Backup files
- Documentation
- Issue trackers
- Chat systems (Slack, Discord)

## Secret Management

### Supported Secret Types

AIDA's pre-commit hook detects these credential types:

**Version Control Systems**:

- **GitHub**: Personal access tokens (classic: `ghp_*`, fine-grained: `github_pat_*`)
- **GitLab**: Personal/project access tokens (`glpat-*`)
- **Bitbucket**: App passwords

**Project Management**:

- **Jira**: API tokens (context-aware detection)
- **Linear**: API keys (`lin_api_*`)

**Cloud Providers**:

- **AWS**: Access key IDs (`AKIA*`) and secret access keys
- **Anthropic**: API keys (`sk-ant-*`)

**Generic Patterns**:

- Fields named `api_key`, `token`, `password`, `secret`
- Base64-encoded credentials
- JWT tokens

### Environment Variable Pattern

This is the recommended approach for referencing secrets in configuration files.

**In config file** (`~/.claude/config.json` or `.aida/config.json`):

```json
{
  "vcs": {
    "github": {
      "api_token": "${GITHUB_TOKEN}"
    }
  },
  "project_management": {
    "jira": {
      "api_token": "${JIRA_TOKEN}"
    }
  }
}
```

**In shell profile** (`~/.bashrc`, `~/.zshrc`, `~/.profile`):

```bash
# GitHub token for API access
export GITHUB_TOKEN="ghp_your_token_here"

# Jira token for issue management
export JIRA_TOKEN="your_jira_token_here"

# Linear API key
export LINEAR_API_KEY="lin_api_your_key_here"
```

**At runtime**, AIDA replaces `${VAR_NAME}` with the environment variable value.

### Secret Managers

For production environments and teams, use dedicated secret management systems:

#### 1Password CLI

```bash
# Install 1Password CLI
brew install --cask 1password-cli

# Configure shell integration
eval "$(op signin)"

# Reference secrets in shell profile
export GITHUB_TOKEN="$(op read "op://Development/GitHub/token")"
export JIRA_TOKEN="$(op read "op://Work/Jira/api-token")"
```

#### AWS Secrets Manager

```bash
# Retrieve secret at runtime
export GITHUB_TOKEN="$(aws secretsmanager get-secret-value \
  --secret-id aida/github-token \
  --query SecretString \
  --output text)"
```

#### HashiCorp Vault

```bash
# Login to Vault
vault login -method=userpass username=developer

# Read secret
export GITHUB_TOKEN="$(vault kv get -field=token secret/aida/github)"
```

### Secret Rotation Procedures

Regular credential rotation reduces exposure risk:

**Recommended rotation schedule**:

- **GitHub tokens**: Every 90 days or when team members leave
- **API keys**: Every 6 months
- **Passwords**: Every 90 days
- **Immediately**: If compromised, suspected leak, or security incident

**Rotation process**:

1. Generate new credentials in service (GitHub, Jira, etc.)
2. Update environment variables or secret manager
3. Test new credentials work
4. Revoke old credentials
5. Document rotation date and reason

**Example rotation script**:

```bash
#!/bin/bash
# rotate-github-token.sh

# Generate new token manually in GitHub UI
# Then update environment:
echo "Enter new GitHub token:"
read -s NEW_TOKEN

# Update 1Password
op item edit "GitHub Token" token="$NEW_TOKEN"

# Update environment
export GITHUB_TOKEN="$NEW_TOKEN"

# Test
gh auth status

echo "Token rotated. Update shell profile and restart terminal."
```

## File Permissions

### User Configuration

**File**: `~/.claude/config.json`

**Permissions**: `600` (owner read/write only)

**Rationale**: Contains personal settings that should not be readable by other users on the system.

```bash
chmod 600 ~/.claude/config.json
```

**Permission breakdown**:

- Owner: read + write (6)
- Group: no access (0)
- Others: no access (0)

### Project Configuration

**File**: `.aida/config.json`

**Permissions**: `644` (owner write, all read)

**Rationale**: Shared team settings committed to version control. All team members need read access.

```bash
chmod 644 .aida/config.json
```

**Permission breakdown**:

- Owner: read + write (6)
- Group: read only (4)
- Others: read only (4)

### Backup Files

**Files**: `*.backup.*` (timestamped backups)

**Permissions**: Same as original file

```bash
# User config backup
chmod 600 ~/.claude/config.json.backup.20251020_210000

# Project config backup
chmod 644 .aida/config.json.backup.20251020_210000
```

### Why Permissions Matter

**Security benefits**:

- **600**: Prevents other users from reading personal configuration (defense against local account compromise)
- **644**: Allows team to read shared config without accidental modification
- Reduces risk of privilege escalation via config tampering
- Clear ownership model (who can modify)

**Practical benefits**:

- Prevents accidental overwrites by other users
- Makes it obvious who owns each config file
- Simplifies troubleshooting (permissions errors are clear)

**Verification**:

```bash
# Check permissions
ls -l ~/.claude/config.json
# Expected: -rw------- (600)

ls -l .aida/config.json
# Expected: -rw-r--r-- (644)
```

## Pre-commit Hook

### What It Detects

The `scripts/validate-config-security.sh` hook provides comprehensive secret detection:

**High-confidence patterns** (always block):

- GitHub tokens: `ghp_*`, `github_pat_*`
- Linear API keys: `lin_api_*`
- Anthropic API keys: `sk-ant-*`
- AWS access keys: `AKIA*` followed by 16 alphanumeric characters
- Generic API keys in JSON fields: `"api_key": "actual_value"`

**Context-aware patterns** (medium confidence):

- Jira tokens: Only flagged when in `jira` context
- Generic `token` fields: Only flagged with suspicious values
- Base64 strings: Only in credential fields

**Low-confidence patterns** (warn but allow):

- Environment variable references: `${VAR_NAME}` (safe, expected)
- Template placeholders: `{{PLACEHOLDER}}` (safe, for templates)
- Example values: `your_token_here`, `example.com`

### How It Works

**Detection pipeline**:

1. **File identification**: Scans staged `config.json` files
2. **Pattern matching**: Applies regex patterns for known token types
3. **Context analysis**: Checks surrounding JSON structure
4. **Confidence scoring**: Rates matches as high/medium/low
5. **Decision**: Block commit (high), warn (medium), allow (low)

**Implementation approach**:

```bash
# Extract from validate-config-security.sh
detect_secrets() {
  local file="$1"

  # GitHub tokens (high confidence)
  if grep -qE "ghp_[a-zA-Z0-9]{36}" "$file"; then
    echo "GitHub token detected"
    return 1
  fi

  # Context-aware Jira detection (medium confidence)
  if grep -qE '"jira".*"api_token".*"[^$]' "$file"; then
    echo "Jira token detected"
    return 1
  fi

  # Environment variable reference (safe)
  if grep -qE '\$\{[A-Z_]+\}' "$file"; then
    echo "Environment variable reference (safe)"
    return 0
  fi
}
```

### When It Triggers

**Example error output**:

```text
═══════════════════════════════════════════════════════════════
  SECRETS DETECTED - COMMIT BLOCKED
═══════════════════════════════════════════════════════════════

Found in: .aida/config.json
  Line 15: GitHub Personal Access Token [high confidence]
  Pattern: "api_token": "ghp_1234567890abcdef..."

Found in: ~/.claude/config.json
  Line 8: Jira API Token [medium confidence]
  Pattern: "jira": { "api_token": "actual_token_value" }

SECURITY RISK:
Committing secrets exposes them in git history where they:
- Remain forever (even if deleted in later commits)
- Are visible to anyone with repository access
- Can be extracted by automated scanners
- May violate compliance requirements

HOW TO FIX:
1. Remove secret from config file
2. Store in environment variable or secret manager
3. Reference with variable substitution:

   "api_token": "${GITHUB_TOKEN}"

4. Add environment variable to shell profile:

   export GITHUB_TOKEN="ghp_your_token_here"

5. Stage the corrected file and commit again

NEED HELP?
See docs/configuration/security-model.md for detailed guidance.
```

### How to Bypass (Use Sparingly!)

Pre-commit hooks can be bypassed when necessary:

```bash
git commit --no-verify
```

**Only bypass when**:

- **False positive**: Example value like `"your_token_here"`
- **Template file**: Contains `{{PLACEHOLDER}}` variables
- **Documentation**: Showing example config structure
- **You've manually verified**: Absolutely certain it's safe

**NEVER bypass for**:

- Actual API keys or tokens
- Real passwords or credentials
- "Just this once" (it's never just once)
- Because you're in a hurry (security doesn't wait)

**Bypass with documentation**:

```bash
# Safe: committing template file
git commit --no-verify -m "Add config template with placeholders"

# Unsafe: committing actual credentials
git commit --no-verify -m "Add my API key"  # DON'T DO THIS
```

## Git Ignore Patterns

### Recommended `.gitignore`

Add these patterns to your repository's `.gitignore`:

```gitignore
# User configuration (personal settings, not shared)
.claude/config.json

# Backup files (timestamped backups)
*.backup.*
*.bak

# Environment files (contain secrets)
.env
.env.local
.env.*.local

# Private keys
*.key
*.pem
*.p12
*.pfx

# Secret manager files
.vault-token
.op-session-*

# OS keychain exports
keychain-export.txt
```

### User vs Project Config

**User config** (`~/.claude/config.json`):

- **Commit**: NO - personal settings, may contain usernames/preferences
- **Share**: NO - specific to individual developer
- **Backup**: YES - to personal backup system

**Project config** (`.aida/config.json`):

- **Commit**: YES - shared team settings
- **Share**: YES - with team via git
- **Backup**: YES - via git history

**Template config** (`templates/config/*.json`):

- **Commit**: YES - examples and documentation
- **Share**: YES - part of framework
- **Contains**: Placeholder values only (`{{PLACEHOLDER}}`, `${ENV_VAR}`)

### What to Commit

**Safe to commit**:

- Project config with environment variable references
- Template configs with placeholders
- Documentation and examples
- Schema definitions

**Never commit**:

- User config (personal preferences)
- Backup files
- Files with actual secrets
- Environment files (`.env`)
- Private keys

## Threat Model

### Threats Mitigated

#### 1. Accidental Secret Commits

**Threat**: Developer commits config file with hardcoded API key.

**Impact**: Secret exposed in git history, accessible to anyone with repo access.

**Mitigation**:

- Pre-commit hook blocks commits with detected secrets
- Clear error messages with remediation steps
- Pattern detection covers common credential types

**Residual risk**:

- Developer uses `--no-verify` to bypass hook
- New secret pattern not yet detected by hook
- Secret in binary file or encrypted archive

**Additional controls**:

- Code review process
- GitHub secret scanning
- Regular security audits

#### 2. Unauthorized Access to Secrets

**Threat**: Malicious user on shared system reads config file to steal credentials.

**Impact**: Attacker gains access to developer's GitHub/Jira/AWS accounts.

**Mitigation**:

- User config has 600 permissions (owner only)
- No secrets stored in config files (only references)
- Secrets in environment variables (process-isolated)

**Residual risk**:

- Root/admin access can read any file
- Malware running as user can access environment
- Shared user accounts (poor practice)

**Additional controls**:

- Principle of least privilege (minimal sudo)
- Malware protection (antivirus, EDR)
- Separate user accounts per person

#### 3. Secret Exposure in Git History

**Threat**: Secret committed months ago, later removed but still in history.

**Impact**: Attacker clones repository and extracts secrets from old commits.

**Mitigation**:

- Prevention-focused: Pre-commit hook stops initial commit
- Education: Documentation on secret handling
- Scanning: Regular git history scans for leaked secrets

**Residual risk**:

- Secrets already in history (before hook installed)
- Secrets committed to other repos/branches
- Public repositories (irreversible exposure)

**Additional controls**:

- Git history rewriting (BFG, filter-branch)
- Immediate revocation if leak detected
- GitHub secret scanning alerts

#### 4. Credential Sharing

**Threat**: Team shares single API token across multiple developers.

**Impact**: Can't track who did what, can't revoke individual access.

**Mitigation**:

- Documentation encourages individual tokens
- Config supports multiple user contexts
- Secret managers provide shared vaults with audit

**Residual risk**:

- Teams ignore guidance and share anyway
- Legacy systems require shared credentials
- Cost concerns (some APIs charge per token)

**Additional controls**:

- Audit logs of API usage
- Regular access reviews
- Service accounts for automation (not personal tokens)

### Residual Risks

Even with all controls in place, some risks remain:

#### 1. Root/Administrator Access

- **Risk**: Root user can read any file, including 600-permission config
- **Mitigation**: Minimize sudo usage, store secrets in OS keychain
- **Detection**: Monitor sudo usage, audit logs

#### 2. Malware

- **Risk**: Malware running as user can access environment variables
- **Mitigation**: Antivirus, endpoint detection, least privilege
- **Detection**: EDR alerts, unusual API activity

#### 3. Shared Accounts

- **Risk**: Multiple people using same user account
- **Mitigation**: Policy against shared accounts, enforce individual logins
- **Detection**: Monitor login times, unusual locations

#### 4. Social Engineering

- **Risk**: Attacker tricks user into revealing secrets
- **Mitigation**: Security training, phishing awareness
- **Detection**: Unusual API usage patterns, login anomalies

#### 5. Supply Chain Attacks

- **Risk**: Compromised dependency steals secrets from environment
- **Mitigation**: Dependency scanning, checksum verification
- **Detection**: Unexpected network connections, file access

### Mitigation Strategies

**Defense in depth**:

1. **Prevention**: Pre-commit hooks, file permissions, education
2. **Detection**: GitHub scanning, audit logs, monitoring
3. **Response**: Incident procedures, revocation automation
4. **Recovery**: Secret rotation, git history cleanup

**Monitoring and alerting**:

- API usage anomalies (unexpected volume, locations)
- Failed authentication attempts (brute force)
- Privilege escalation (sudo, file permission changes)
- Secret rotation age (notify when credentials are old)

**Regular audits**:

- Weekly: Review git commits for bypassed hooks
- Monthly: Scan git history for leaked secrets
- Quarterly: Review and rotate credentials
- Annually: Comprehensive security review

## Compliance

### GDPR Considerations

The General Data Protection Regulation (GDPR) classifies certain data as Personally Identifiable Information (PII) requiring special handling.

**Personal Data in Config Files**:

**Allowed** (not considered PII):

- ✅ Usernames (public identifiers like GitHub handles)
- ✅ Team roles and organizational structure
- ✅ Project names and repository URLs
- ✅ Workflow preferences and tool settings

**Restricted** (PII, use environment variables):

- ❌ Email addresses (personal contact information)
- ❌ Full legal names (if not public knowledge)
- ❌ Phone numbers (personal contact)
- ❌ Physical addresses
- ❌ Any identifying information for EU residents

**Rationale**: Config files committed to git are effectively public (even in private repos). GDPR requires explicit consent and data minimization for PII storage.

**Best practice**: Store user identifiers by username only, retrieve email from API when needed.

**Example - GDPR compliant**:

```json
{
  "team": {
    "members": [
      {
        "username": "developer123",
        "role": "engineer",
        "github": "developer123"
      }
    ]
  }
}
```

**Example - GDPR violation**:

```json
{
  "team": {
    "members": [
      {
        "name": "John Smith",
        "email": "john.smith@example.com",
        "phone": "+44-20-1234-5678"
      }
    ]
  }
}
```

### Audit Trail

Maintain logs of credential usage without logging the credentials themselves.

**What to log**:

```json
{
  "timestamp": "2025-10-20T21:00:00Z",
  "action": "github_api_call",
  "endpoint": "/repos/oakensoul/aida",
  "user": "developer123",
  "credential_type": "github_personal_access_token",
  "credential_scope": "repo, workflow",
  "result": "success",
  "response_code": 200
}
```

**What NOT to log**:

- ❌ Actual token values (`ghp_1234...`)
- ❌ API responses containing secrets
- ❌ Full config files (may contain sensitive data)
- ❌ Environment variable dumps
- ❌ Stack traces with credentials

**Audit trail requirements**:

- **Retention**: Keep logs for 90 days minimum (compliance may require longer)
- **Access control**: Logs readable only by security team and auditors
- **Integrity**: Tamper-proof (append-only, cryptographically signed)
- **Privacy**: Redact PII, log only what's necessary

**Log rotation**:

```bash
# Rotate audit logs weekly
/var/log/aida/audit.log {
  weekly
  rotate 12
  compress
  delaycompress
  notifempty
  create 0640 aida adm
}
```

### Data Retention Policies

**Credential lifecycle**:

- **Creation**: Log when credential is generated
- **Usage**: Log each API call (timestamp, endpoint, result)
- **Rotation**: Log when credential is replaced
- **Revocation**: Log when credential is deleted
- **Retention**: Keep usage logs for 90 days, credential metadata for 1 year

**Config file retention**:

- **Active config**: Current version in use
- **Backups**: Keep 5 most recent backups
- **Git history**: Unlimited (version control)
- **Deleted files**: Purge from git history after validation

## Incident Response

### If Secrets Are Leaked

Time is critical. Follow this procedure immediately.

#### Immediate Actions (Within 1 Hour)

##### 1. Revoke compromised credentials

Stop the bleeding before cleanup.

**GitHub**:

```bash
# Via web UI
# Settings → Developer settings → Personal access tokens → [token] → Delete

# Via API
gh api -X DELETE /applications/CLIENT_ID/token -f access_token=TOKEN
```

**Jira**:

```bash
# Web UI: Profile → Security → API tokens → [token] → Revoke
```

**AWS**:

```bash
# Deactivate access key
aws iam update-access-key \
  --access-key-id AKIAIOSFODNN7EXAMPLE \
  --status Inactive \
  --user-name developer

# Delete access key
aws iam delete-access-key \
  --access-key-id AKIAIOSFODNN7EXAMPLE \
  --user-name developer
```

##### 2. Generate new credentials

Replace revoked credentials immediately.

```bash
# GitHub: Generate new token
gh auth login --scopes repo,workflow

# AWS: Create new access key
aws iam create-access-key --user-name developer
```

##### 3. Update environment variables

```bash
# Update shell profile
vim ~/.zshrc
# Change: export GITHUB_TOKEN="ghp_OLD..."
# To:     export GITHUB_TOKEN="ghp_NEW..."

# Reload shell
source ~/.zshrc
```

##### 4. Test new credentials

```bash
# GitHub
gh auth status

# AWS
aws sts get-caller-identity

# Jira
curl -u email@example.com:$JIRA_TOKEN \
  https://your-domain.atlassian.net/rest/api/3/myself
```

#### Within 4 Hours

##### 5. Remove from git history

###### Option A: BFG Repo-Cleaner (recommended)

```bash
# Install
brew install bfg

# Clone repository
git clone --mirror https://github.com/user/repo.git

# Create replacements file
cat > passwords.txt << EOF
ghp_OLD_TOKEN_HERE
AKIAIOSFODNN7EXAMPLE
EOF

# Remove secrets
bfg --replace-text passwords.txt repo.git

# Push cleaned history
cd repo.git
git reflog expire --expire=now --all
git gc --prune=now --aggressive
git push --force
```

###### Option B: git filter-branch

```bash
# Remove specific file
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch config/secrets.json' \
  --prune-empty --tag-name-filter cat -- --all

# Push
git push --force --all
git push --force --tags
```

###### Option C: git filter-repo (modern alternative)

```bash
# Install
brew install git-filter-repo

# Remove file
git filter-repo --path config/secrets.json --invert-paths

# Push
git push --force --all
```

##### 6. Force push (DANGEROUS)

**Check first**:

- Is this a shared repository? (notify team first)
- Are there open pull requests? (may break them)
- Do CI/CD pipelines depend on history? (may need updates)

**If safe to proceed**:

```bash
# Force push all branches
git push --force --all

# Force push all tags
git push --force --tags

# Notify team to re-clone
echo "URGENT: Repository history rewritten. Re-clone repository."
```

#### Within 24 Hours

##### 7. Audit for unauthorized usage

Check if leaked credentials were exploited.

**GitHub**:

```bash
# Check recent activity
gh api /user/events | jq '.[] | select(.created_at > "2025-10-20")'

# Review audit log
# Settings → Organizations → Audit log
```

**AWS**:

```bash
# CloudTrail logs
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=Username,AttributeValue=developer \
  --start-time 2025-10-20T00:00:00Z
```

**Jira**:

```bash
# Audit log (requires admin)
# Settings → System → Audit log
```

##### 8. Document incident

Create incident report:

```markdown
# Security Incident Report

**Date**: 2025-10-20
**Severity**: High
**Status**: Resolved

## What Happened

GitHub personal access token with `repo` and `workflow` scopes was
accidentally committed to public repository in commit abc123.

## Timeline

- 14:30 UTC: Secret committed
- 14:45 UTC: Detected by GitHub secret scanning alert
- 15:00 UTC: Token revoked
- 15:15 UTC: New token generated
- 16:00 UTC: Git history cleaned
- 18:00 UTC: Audit completed (no unauthorized usage detected)

## Impact

- Token exposed for 15 minutes in public repository
- No unauthorized usage detected in audit logs
- No data accessed or modified

## Actions Taken

1. Revoked compromised token immediately
2. Generated new token with same scopes
3. Cleaned git history with BFG Repo-Cleaner
4. Force pushed cleaned repository
5. Audited GitHub activity logs (no suspicious activity)
6. Notified team of repository history change

## Root Cause

Developer bypassed pre-commit hook with `--no-verify` flag while
troubleshooting unrelated issue, forgot secret was in file.

## Preventive Measures

1. Updated team documentation to never bypass pre-commit hooks
2. Enabled GitHub secret scanning alerts for organization
3. Scheduled monthly secret rotation reminders
4. Added CI check to fail if secrets detected (backup to local hook)

## Lessons Learned

- Pre-commit hooks are critical but not foolproof
- Need multiple layers of defense (local hook + CI + scanning)
- Incident response was effective (15 minute response time)
- Team notification process worked well
```

##### 9. Notify stakeholders

**Internal notification**:

```bash
# Slack/email to team
Subject: [SECURITY] Git history rewritten - action required

Team,

A security incident required rewriting the git history of repo 'aida'.
All developers must re-clone the repository:

  rm -rf ~/projects/aida
  git clone https://github.com/oakensoul/aida.git

Do NOT pull/rebase existing clones - it will not work correctly.

Details in incident report: [link to report]
```

**External notification** (if required by compliance):

- Affected users (if their data was exposed)
- Security team
- Compliance/legal team
- Regulatory authorities (if GDPR/HIPAA breach)

### Git History Cleanup Tools

**Comparison**:

| Tool | Speed | Ease | Thoroughness | Recommended |
|------|-------|------|--------------|-------------|
| BFG Repo-Cleaner | Fast | Easy | Good | ✅ Yes (best for most) |
| git filter-branch | Slow | Hard | Complete | ⚠️ Legacy (use filter-repo instead) |
| git filter-repo | Fast | Medium | Complete | ✅ Yes (modern alternative) |

**BFG Repo-Cleaner**:

- **Pros**: Fast, simple, designed for secret removal
- **Cons**: Less control than filter-branch
- **Best for**: Removing secrets from large repos

**git filter-branch**:

- **Pros**: Complete control, built-in
- **Cons**: Slow, complex, deprecated
- **Best for**: Complex history rewrites

**git filter-repo**:

- **Pros**: Fast, modern, powerful
- **Cons**: Requires Python, separate install
- **Best for**: Complex rewrites, multiple operations

### Post-Cleanup Validation

**Verify secrets removed**:

```bash
# Clone clean repository
git clone https://github.com/user/repo.git repo-clean
cd repo-clean

# Search entire history for leaked token
git log --all --full-history --source --pretty=format: -S 'ghp_OLD_TOKEN'

# Should return no results
```

**Verify repository integrity**:

```bash
# Check for corruption
git fsck --full

# Verify all branches
git branch -r

# Verify tags
git tag
```

**Team re-clone instructions**:

```markdown
# Re-clone Repository After History Rewrite

**DO NOT** attempt to pull/rebase your existing clone.
You MUST delete and re-clone.

Steps:

1. Commit or stash any local changes
   git commit -am "WIP: save before re-clone"
   # or
   git stash

2. Note your current branch
   git branch --show-current

3. Delete local repository
   cd ~/projects
   rm -rf aida

4. Clone fresh copy
   git clone https://github.com/oakensoul/aida.git
   cd aida

5. Checkout your branch (if not main)
   git checkout feature-branch

6. Cherry-pick or rebase your WIP commits
   # (since old commit SHAs are now invalid)
```

## Best Practices

### 1. Use Secret Managers

Dedicated secret management systems provide security features that environment variables and config files cannot.

**Recommended tools**:

**1Password**:

- **Use case**: Personal and team secret storage
- **Pros**: User-friendly, cross-platform, CLI integration
- **Cons**: Requires subscription

```bash
# Install
brew install --cask 1password-cli

# Sign in
eval "$(op signin)"

# Store secret
op item create --category=login \
  --title="GitHub Token" \
  token=ghp_your_token_here

# Retrieve in shell profile
export GITHUB_TOKEN="$(op read "op://Development/GitHub Token/token")"
```

**AWS Secrets Manager**:

- **Use case**: Cloud-native applications, EC2, Lambda
- **Pros**: Automatic rotation, audit trails, IAM integration
- **Cons**: AWS-specific, costs per secret

```bash
# Create secret
aws secretsmanager create-secret \
  --name aida/github-token \
  --secret-string ghp_your_token_here

# Retrieve
export GITHUB_TOKEN="$(aws secretsmanager get-secret-value \
  --secret-id aida/github-token \
  --query SecretString \
  --output text)"
```

**HashiCorp Vault**:

- **Use case**: Enterprise, multi-cloud, dynamic secrets
- **Pros**: Advanced features, dynamic secrets, encryption as a service
- **Cons**: Complex setup, infrastructure required

```bash
# Login
vault login -method=userpass username=developer

# Write secret
vault kv put secret/aida/github token=ghp_your_token_here

# Read secret
export GITHUB_TOKEN="$(vault kv get -field=token secret/aida/github)"
```

**pass (password-store)**:

- **Use case**: CLI-based, GPG-encrypted, personal use
- **Pros**: Simple, open-source, git-compatible
- **Cons**: No GUI, requires GPG setup

```bash
# Install
brew install pass

# Initialize
pass init your-gpg-key-id

# Store secret
pass insert aida/github-token

# Retrieve
export GITHUB_TOKEN="$(pass show aida/github-token)"
```

### 2. Rotate Credentials Regularly

Regular rotation limits exposure window if credentials are compromised.

**Rotation schedule**:

- **GitHub tokens**: 90 days (or when team members leave)
- **API keys**: 6 months
- **Passwords**: 90 days
- **SSH keys**: 1 year
- **Immediately**: If compromised, leaked, or suspected

**Rotation automation**:

```bash
#!/bin/bash
# ~/.aida/scripts/rotate-credentials.sh

# Check credential age
check_credential_age() {
  local secret_name="$1"
  local max_age_days="$2"

  # Get creation date from 1Password
  created=$(op item get "$secret_name" --fields "created")
  age_days=$(( ($(date +%s) - $(date -j -f "%Y-%m-%d" "$created" +%s)) / 86400 ))

  if [ "$age_days" -gt "$max_age_days" ]; then
    echo "WARNING: $secret_name is $age_days days old (max: $max_age_days)"
    return 1
  fi
}

# Check all credentials
check_credential_age "GitHub Token" 90
check_credential_age "Jira Token" 180
check_credential_age "AWS Access Key" 365
```

**Rotation reminder**:

```bash
# Add to crontab
# Check credential age weekly
0 9 * * 1 ~/.aida/scripts/rotate-credentials.sh | mail -s "Credential Rotation Check" you@example.com
```

### 3. Principle of Least Privilege

Grant minimum required permissions to limit blast radius of compromise.

**GitHub token scopes**:

```text
Required for AIDA:
✅ repo (private repo access)
✅ workflow (GitHub Actions)

NOT required:
❌ admin:org (unless managing org settings)
❌ delete_repo (unless cleanup automation)
❌ admin:public_key (unless managing SSH keys)
```

**AWS IAM policies**:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": "arn:aws:secretsmanager:*:*:secret:aida/*"
    }
  ]
}
```

**Jira permissions**:

- Use project-scoped tokens (not global admin)
- Read-only where possible
- Time-limited tokens for temporary access

### 4. Team Secret Sharing

**DO**:

- ✅ Use shared secret manager vaults (1Password Teams, Vault)
- ✅ Document secret ownership and purpose
- ✅ Revoke access when team members leave
- ✅ Use service accounts for automation (not personal tokens)
- ✅ Rotate shared secrets quarterly

**DON'T**:

- ❌ Share secrets via email, Slack, or other chat
- ❌ Reuse personal credentials for team access
- ❌ Store team secrets in personal accounts
- ❌ Leave secrets accessible after team member departure
- ❌ Use same token across dev/staging/prod

**Example - 1Password shared vault**:

```bash
# Create team vault
op vault create "AIDA Team Secrets"

# Grant access to team
op vault user grant "AIDA Team Secrets" user@example.com

# Store shared secret
op item create --vault="AIDA Team Secrets" \
  --category=login \
  --title="Jira API Token (Team)" \
  token=shared_token_here

# Team member retrieves
export JIRA_TOKEN="$(op read "op://AIDA Team Secrets/Jira API Token (Team)/token")"
```

### 5. Monitor for Leaks

Proactive monitoring detects leaks before they're exploited.

**GitHub secret scanning**:

```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "daily"

# Enabled automatically for public repos
# Enable for private repos: Settings → Security → Secret scanning
```

**gitleaks in CI/CD**:

```yaml
# .github/workflows/security.yml
name: Security Scan

on: [push, pull_request]

jobs:
  gitleaks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Run gitleaks
        uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

**API usage monitoring**:

```bash
# Monitor GitHub API rate limits
gh api rate_limit

# Alert if unusual usage
if [ "$REMAINING" -lt 100 ]; then
  echo "WARNING: Low API rate limit remaining"
fi
```

## Related Documentation

- [Configuration Schema Reference](schema-reference.md) - JSON schema and validation rules
- [Migration Guide](../migration/v0-to-v1-config.md) - Upgrading to new config format
- [Pre-commit Hooks](../../.pre-commit-config.yaml) - Automated quality checks
- [Secret Detection Script](../../scripts/validate-config-security.sh) - Pre-commit hook implementation
- [Installation Guide](../installation.md) - Initial AIDA setup

## Quick Reference

### Safe vs Unsafe Config

**✅ Safe Config** (environment variable reference):

```json
{
  "vcs": {
    "github": {
      "api_token": "${GITHUB_TOKEN}",
      "username": "developer123"
    }
  },
  "project_management": {
    "jira": {
      "url": "https://company.atlassian.net",
      "api_token": "${JIRA_TOKEN}",
      "username": "developer@example.com"
    }
  }
}
```

**❌ Unsafe Config** (hardcoded secrets):

```json
{
  "vcs": {
    "github": {
      "api_token": "ghp_1234567890abcdefghijklmnopqrstuvwxyz",
      "username": "developer123"
    }
  },
  "project_management": {
    "jira": {
      "url": "https://company.atlassian.net",
      "api_token": "ATATTxxxxxxxxxxxxxxxx",
      "username": "developer@example.com"
    }
  }
}
```

### Shell Profile Setup

**~/.bashrc** or **~/.zshrc**:

```bash
# AIDA configuration secrets
# WARNING: These environment variables contain sensitive credentials.
# Do NOT commit this file to version control.

# GitHub API access
export GITHUB_TOKEN="ghp_your_github_token_here"

# Jira API access
export JIRA_TOKEN="your_jira_token_here"

# Linear API access
export LINEAR_API_KEY="lin_api_your_linear_key_here"

# AWS credentials (if not using AWS CLI profiles)
export AWS_ACCESS_KEY_ID="AKIAIOSFODNN7EXAMPLE"
export AWS_SECRET_ACCESS_KEY="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"

# Anthropic API key
export ANTHROPIC_API_KEY="sk-ant-your-anthropic-key-here"
```

### Permission Commands

```bash
# Set correct permissions on user config
chmod 600 ~/.claude/config.json

# Set correct permissions on project config
chmod 644 .aida/config.json

# Verify permissions
ls -l ~/.claude/config.json  # Should show: -rw-------
ls -l .aida/config.json       # Should show: -rw-r--r--

# Fix permissions recursively
find ~/.claude -name "config.json" -exec chmod 600 {} \;
find .aida -name "config.json" -exec chmod 644 {} \;
```

### Emergency Response Commands

```bash
# 1. Revoke GitHub token
gh auth logout
gh auth login  # Creates new token

# 2. Search git history for leaked token
git log --all --full-history -S 'ghp_OLD_TOKEN'

# 3. Remove secret from history (BFG)
brew install bfg
git clone --mirror https://github.com/user/repo.git
echo "ghp_OLD_TOKEN" > passwords.txt
bfg --replace-text passwords.txt repo.git
cd repo.git
git reflog expire --expire=now --all
git gc --prune=now --aggressive
git push --force

# 4. Audit GitHub activity
gh api /user/events | jq '.[] | select(.created_at > "2025-10-20")'
```

## Remember

**When in doubt, don't commit it.**

Secrets belong in secret managers, not source control. The few seconds it takes to set up environment variables can prevent hours of incident response and potential security breaches.

**Security is everyone's responsibility**, but AIDA provides the tools to make it easy and automated.
