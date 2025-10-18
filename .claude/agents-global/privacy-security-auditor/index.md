---
title: "Privacy Security Auditor - AIDA Project Instructions"
description: "AIDA-specific privacy and security requirements"
category: "project-agent-instructions"
tags: ["aida", "privacy-security-auditor", "project-context"]
last_updated: "2025-10-09"
status: "active"
---

# AIDA Privacy Security Auditor Instructions

Project-specific privacy and security standards for the AIDA framework.

## Three-Repo Privacy Architecture

AIDA uses a three-repository model to enforce privacy separation:

### Repository Roles

**1. claude-personal-assistant (Public Framework)**
- **Privacy Level**: PUBLIC - No user data, no secrets
- **Contains**: Framework code, templates, generic agents
- **Validation**: Templates must use placeholder variables
- **Install Location**: `~/.aida/`

**2. dotfiles (Public Configurations)**
- **Privacy Level**: PUBLIC - Generic configs, no secrets
- **Contains**: Shell configs, git configs, AIDA templates
- **Validation**: No API keys, no personal data
- **Managed With**: GNU Stow

**3. dotfiles-private (Private Overrides)**
- **Privacy Level**: PRIVATE - User data and secrets
- **Contains**: API keys, personal customizations, secrets
- **Validation**: Never commit to public repos
- **Managed With**: GNU Stow (stowed last, overrides both)

### Privacy Boundaries

**Public Framework (claude-personal-assistant)**:
```yaml
# Template with placeholders - OK for public repo
api_key: "{{OPENAI_API_KEY}}"
user_name: "{{USER_NAME}}"
vault_path: "{{OBSIDIAN_VAULT}}"
```

**User Configuration (Generated, Private)**:
```yaml
# Generated from template - stays local
api_key: "sk-real-key-here"
user_name: "Rob"
vault_path: "/Users/rob/Documents/Obsidian/Main"
```

## PII Detection for AIDA

### AIDA-Specific PII Patterns

**User Identification**:
- User names in personality greetings
- Email addresses in git configs
- Home directory paths (`/Users/rob/`)
- API keys and tokens

**System Information**:
- Machine hostnames
- Local file paths
- IP addresses in MCP configs
- Obsidian vault locations

**Usage Data**:
- Command history
- Personality switching patterns
- Project names and paths
- Decision logs with personal context

### Privacy Scrubbing Rules

**Template Variables** (Install-time):
```bash
# Before scrubbing (contains PII)
home_dir: "/Users/rob"
vault: "/Users/rob/Documents/Obsidian/Main"

# After scrubbing (privacy-safe)
home_dir: "{{HOME}}"
vault: "{{OBSIDIAN_VAULT}}"
```

**Configuration Files**:
```yaml
# Before scrubbing
user:
  name: "Rob"
  email: "rob@example.com"
  api_key: "sk-1234567890"

# After scrubbing
user:
  name: "{{USER_NAME}}"
  email: "{{USER_EMAIL}}"
  api_key: "{{API_KEY}}"
```

### Knowledge Sync Security

When syncing AIDA knowledge between devices or to Obsidian:

**Privacy-First Approach**:
1. **Scrub Before Sync**: Remove PII before syncing to cloud
2. **Encrypt Sensitive**: Encrypt personal decisions and logs
3. **Selective Sync**: Only sync non-sensitive knowledge
4. **User Control**: Allow users to mark content as private

**Knowledge Classification**:
```markdown
---
privacy: public
shareable: true
---
# Generic Pattern (OK to sync)

This is a reusable pattern...
```

```markdown
---
privacy: private
shareable: false
pii: true
---
# Personal Decision (Do NOT sync)

I decided to use API key sk-1234...
```

## AIDA Security Requirements

### Installation Security

**install.sh Security**:
1. **No Sudo Required**: Framework installs to user directory
2. **Permission Validation**: Check directory permissions before install
3. **Symlink Safety**: Validate symlink targets in dev mode
4. **Path Traversal**: Prevent `../../../` attacks in paths
5. **Script Injection**: Sanitize all user inputs

**Directory Permissions**:
```bash
# Secure defaults
chmod 755 ~/.aida/                    # Framework directory
chmod 644 ~/.aida/personalities/*.yml # Personality files (read-only)
chmod 700 ~/.claude/                  # User config (private)
chmod 600 ~/.claude/secrets.yml       # Secrets (user-only)
```

### Runtime Security

**Environment Variables**:
```bash
# Sensitive data in environment, not files
export AIDA_API_KEY="sk-..."
export OBSIDIAN_API_TOKEN="token-..."
export GIT_TOKEN="ghp_..."

# Referenced in configs
api_key: "${AIDA_API_KEY}"
```

**Secrets Management**:
- Never log API keys or tokens
- Mask secrets in error messages
- Clear sensitive data from memory after use
- Support external secret managers (1Password, Bitwarden)

### Git Security

**Pre-commit Validation**:
```bash
#!/bin/bash
# Prevent committing secrets to public repos

# Check for API keys
if git diff --cached | grep -i "api[_-]key.*sk-"; then
    echo "ERROR: API key detected in commit"
    exit 1
fi

# Check for personal paths
if git diff --cached | grep "/Users/[^{]"; then
    echo "ERROR: Personal path detected (use {{HOME}})"
    exit 1
fi
```

**Repository Classification**:
```yaml
# .aida/repo-config.yml
repository:
  type: "public"  # public, private, or local-only
  privacy_checks:
    - "no-api-keys"
    - "no-personal-paths"
    - "no-email-addresses"
  auto_scrub: true
```

## Data Retention and Privacy

### Local Data Storage

**Persistent Data**:
- Memory logs: `~/.claude/memory/` (user-only, 700 permissions)
- Decision history: `~/.claude/decisions/` (user-only)
- Activity logs: `~/.claude/logs/` (rotated, cleaned after 30 days)

**Temporary Data**:
- Command outputs: `/tmp/aida-*` (cleaned on exit)
- Personality switches: `/tmp/aida-personality-*` (ephemeral)
- Cache: `~/.aida/cache/` (cleaned weekly)

### Privacy Controls

**User Privacy Settings**:
```yaml
# ~/.claude/privacy.yml
privacy:
  logging:
    enabled: true
    retention_days: 30
    redact_pii: true

  sync:
    obsidian: "selective"  # all, selective, or none
    cloud: false
    encrypt: true

  telemetry:
    enabled: false
    anonymous_only: true
```

## Compliance Requirements

### AIDA License Compliance

**AGPL-3.0 License**:
- All AIDA code is AGPL-3.0
- Modifications must be open-sourced if distributed
- User data remains user's property
- No data collection without explicit consent

### Data Portability

Users must be able to:
1. **Export All Data**: `aida export --all`
2. **Delete All Data**: `aida cleanup --purge`
3. **View Data**: `aida data list`
4. **Control Sharing**: Explicit opt-in for any sync

## Testing Requirements

### Privacy Test Scenarios

1. **Template Scrubbing**: Validate all templates use `{{VARIABLES}}`
2. **PII Detection**: Scan all files for common PII patterns
3. **Permission Validation**: Check file permissions are secure
4. **Secret Leakage**: Ensure no secrets in logs or errors
5. **Git Hooks**: Validate pre-commit hooks catch PII

### Security Test Scenarios

1. **Path Traversal**: Attempt `../../../` attacks in paths
2. **Symlink Attacks**: Validate symlink targets in dev mode
3. **Environment Injection**: Test with malicious env vars
4. **Permission Escalation**: Ensure no sudo required
5. **Code Injection**: Sanitize all user inputs

## Incident Response

### Privacy Breach Protocol

If PII is committed to public repo:

1. **Immediate**: Remove from commit history (git filter-branch)
2. **Notify**: Alert users if their data was exposed
3. **Rotate**: Rotate any exposed API keys/tokens
4. **Document**: Log incident and prevention measures
5. **Prevent**: Add automated checks to prevent recurrence

### Security Vulnerability Protocol

If security issue discovered:

1. **Assess**: Determine scope and severity
2. **Patch**: Develop and test fix immediately
3. **Notify**: Security advisory to users
4. **Release**: Emergency release if critical
5. **Document**: Post-mortem and prevention

## Integration Notes

- **User-level Privacy Patterns**: Load from `~/.claude/agents/privacy-security-auditor/`
- **Project-specific requirements**: This file
- **Combined approach**: User philosophy + AIDA requirements

## Best Practices for AIDA

1. **Privacy by Default**: All features respect privacy first
2. **User Control**: Users control all data sharing
3. **Transparency**: Clear documentation of data handling
4. **Security First**: Validate all inputs, sanitize outputs
5. **Regular Audits**: Automated privacy and security scanning

---

**Last Updated**: 2025-10-09
