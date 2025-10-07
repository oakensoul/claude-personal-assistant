---
title: "Privacy & Security Auditor - Technical Analysis"
description: "Technical security implementation analysis for workflow command templates"
issue: 39
agent: "privacy-security-auditor"
date: "2025-10-07"
status: "completed"
---

# Technical Security Analysis: Workflow Command Templates

## 1. Implementation Approach

### Security Implementation Strategy

#### Multi-Layer Validation

- Pre-install validation: Verify template integrity before copying
- Post-install validation: Confirm secure permissions after installation
- Runtime validation: Sanitize input before command execution
- Pre-commit validation: Catch security issues before repository commit

#### Defense in Depth

- Layer 1: Template validation (syntax, structure, dangerous patterns)
- Layer 2: Input sanitization (prevent injection attacks)
- Layer 3: Permission enforcement (644 templates, 600 commands)
- Layer 4: Runtime monitoring (audit logging, suspicious operation detection)

#### Secure by Default

- Templates contain no secrets or hardcoded credentials
- All user input validated before use in shell commands
- File operations use absolute paths with validation
- Git operations prompt before destructive actions

### Permission Management Approach

#### Template Files (644)

```bash
# In templates/commands/workflows/
-rw-r--r-- cleanup-main.sh.template
-rw-r--r-- create-agent.sh.template
-rw-r--r-- workflow-init.sh.template
```

#### Installed Commands (600)

```bash
# In ~/.claude/commands/workflows/
-rw------- cleanup-main.sh
-rw------- create-agent.sh
-rw------- workflow-init.sh
```

#### Permission Enforcement Logic

```bash
# In install.sh
set_command_permissions() {
    local target="$1"

    # Validate file exists
    if [[ ! -f "${target}" ]]; then
        print_message "error" "Cannot set permissions: ${target} not found"
        return 1
    fi

    # Set user-only read/write (600)
    chmod 600 "${target}" || {
        print_message "error" "Failed to set permissions on ${target}"
        return 1
    }

    # Verify permissions were set correctly
    local perms
    perms=$(stat -f "%p" "${target}" 2>/dev/null || stat -c "%a" "${target}" 2>/dev/null)
    if [[ "${perms}" != *"600" ]]; then
        print_message "error" "Permission verification failed for ${target}"
        return 1
    fi

    return 0
}
```

### Input Validation Techniques

#### Path Validation

```bash
validate_path() {
    local path="$1"
    local description="$2"

    # Reject empty paths
    if [[ -z "${path}" ]]; then
        print_message "error" "${description}: Path cannot be empty"
        return 1
    fi

    # Reject path traversal attempts
    if [[ "${path}" =~ \.\. ]]; then
        print_message "error" "${description}: Path traversal detected"
        return 1
    fi

    # Reject absolute paths outside allowed directories
    case "${path}" in
        "${HOME}"/.aida/*|"${HOME}"/.claude/*|"${HOME}"/CLAUDE.md)
            return 0
            ;;
        *)
            print_message "error" "${description}: Path outside allowed directories"
            return 1
            ;;
    esac
}
```

#### Command Argument Sanitization

```bash
sanitize_argument() {
    local arg="$1"

    # Remove shell metacharacters
    arg="${arg//[;&|<>$(){}]/}"

    # Remove control characters
    arg="${arg//[$'\t\r\n']/}"

    # Limit length
    if [[ ${#arg} -gt 256 ]]; then
        print_message "error" "Argument too long (max 256 characters)"
        return 1
    fi

    echo "${arg}"
}
```

#### Template Variable Validation

```bash
validate_template_variables() {
    local template="$1"

    # Check for required variables
    local required_vars=("PROJECT_ROOT" "AIDA_HOME" "HOME")
    for var in "${required_vars[@]}"; do
        if ! grep -q "{{${var}}}" "${template}"; then
            print_message "warning" "Template missing variable: {{${var}}}"
        fi
    done

    # Check for unknown variables
    local unknown_vars
    unknown_vars=$(grep -oE '\{\{[A-Z_]+\}\}' "${template}" | \
                   grep -vE '\{\{(PROJECT_ROOT|AIDA_HOME|HOME|USER)\}\}')

    if [[ -n "${unknown_vars}" ]]; then
        print_message "error" "Template contains unknown variables: ${unknown_vars}"
        return 1
    fi

    return 0
}
```

## 2. Technical Concerns

### Command Injection Vectors

#### Variable Substitution Injection

```bash
# VULNERABLE: Direct substitution without validation
sed "s|{{PROJECT_ROOT}}|${PROJECT_ROOT}|g" template.sh > command.sh

# Attack: PROJECT_ROOT="; rm -rf /tmp/*; echo "
# Result: Injected commands execute during sed operation

# SECURE: Validate before substitution
validate_path "${PROJECT_ROOT}" "PROJECT_ROOT" || exit 1
sed "s|{{PROJECT_ROOT}}|${PROJECT_ROOT}|g" template.sh > command.sh
```

#### Unquoted Variables

```bash
# VULNERABLE: Unquoted variable allows word splitting
cp $SOURCE_FILE $DEST_FILE

# Attack: SOURCE_FILE="file.txt /etc/passwd"
# Result: Copies multiple files, including /etc/passwd

# SECURE: Quote all variables
cp "${SOURCE_FILE}" "${DEST_FILE}"
```

#### User Input in Commands

```bash
# VULNERABLE: User input directly in git commands
git commit -m "$USER_MESSAGE"

# Attack: USER_MESSAGE="; rm -rf .git; echo "
# Result: Repository destruction

# SECURE: Use git's argument handling
git commit -m "${USER_MESSAGE//\"/\\\"}"  # Escape quotes
# OR: Use heredoc to avoid shell interpretation
git commit -m "$(cat <<'EOF'
${USER_MESSAGE}
EOF
)"
```

### File Permission Issues

#### Race Conditions (TOCTOU)

```bash
# VULNERABLE: Check-then-use race condition
if [[ -f "${target}" ]]; then
    chmod 600 "${target}"
fi

# Attack: Replace target file between check and chmod
# Result: Wrong file gets permission change

# SECURE: Use atomic operations
chmod 600 "${target}" 2>/dev/null || true
```

#### Insecure Temporary Files

```bash
# VULNERABLE: Predictable temp file name
TEMP_FILE="/tmp/command-${USER}.tmp"
echo "data" > "${TEMP_FILE}"

# Attack: Symlink attack, predictable name
# Result: Overwrite arbitrary file

# SECURE: Use mktemp with restrictive permissions
TEMP_FILE="$(mktemp)"
chmod 600 "${TEMP_FILE}"
echo "data" > "${TEMP_FILE}"
trap 'rm -f "${TEMP_FILE}"' EXIT
```

#### Symlink Validation in Dev Mode

```bash
# VULNERABLE: Follow symlinks without validation
ln -sf "${SCRIPT_DIR}" "${AIDA_DIR}"

# Attack: SCRIPT_DIR points to malicious directory
# Result: Framework runs attacker code

# SECURE: Validate symlink target
validate_directory "${SCRIPT_DIR}" || exit 1
if [[ ! -d "${SCRIPT_DIR}" ]]; then
    print_message "error" "Script directory not found"
    exit 1
fi
# Canonicalize path to prevent traversal
SCRIPT_DIR="$(cd "${SCRIPT_DIR}" && pwd)"
ln -sf "${SCRIPT_DIR}" "${AIDA_DIR}"
```

### Secret Exposure Risks

#### Template Secret Detection

```bash
# Patterns to detect secrets in templates
detect_secrets_in_template() {
    local template="$1"
    local secrets_found=false

    # API key patterns
    if grep -qE 'sk-ant-[a-zA-Z0-9-_]{95}' "${template}"; then
        print_message "error" "Anthropic API key detected in template"
        secrets_found=true
    fi

    if grep -qE 'ghp_[a-zA-Z0-9]{36}' "${template}"; then
        print_message "error" "GitHub token detected in template"
        secrets_found=true
    fi

    # Generic secret patterns
    if grep -qiE '(password|secret|token|api[_-]?key)\s*=\s*["\x27][^"\x27]+["\x27]' "${template}"; then
        print_message "error" "Potential secret detected in template"
        secrets_found=true
    fi

    if [[ "${secrets_found}" == "true" ]]; then
        return 1
    fi

    return 0
}
```

#### GitHub Token Handling

```bash
# INSECURE: Token in command file
GITHUB_TOKEN="ghp_xxxxxxxxxxxx"

# SECURE: Token from environment or keychain
if [[ -z "${GITHUB_TOKEN}" ]]; then
    # Try to get from keychain
    if command -v security &>/dev/null; then
        GITHUB_TOKEN="$(security find-generic-password -s github-token -w 2>/dev/null)"
    fi

    if [[ -z "${GITHUB_TOKEN}" ]]; then
        print_message "error" "GITHUB_TOKEN not found in environment or keychain"
        exit 1
    fi
fi
```

#### Logging Sensitive Data

```bash
# VULNERABLE: Logs may contain secrets
print_message "debug" "Running: gh auth login --with-token ${TOKEN}"

# SECURE: Redact secrets from logs
print_message "debug" "Running: gh auth login --with-token [REDACTED]"

# SECURE: Don't log secret values
log_command_execution() {
    local cmd="$1"
    # Redact common secret patterns
    cmd="${cmd//ghp_[a-zA-Z0-9]*/[GITHUB_TOKEN]}"
    cmd="${cmd//sk-ant-[a-zA-Z0-9-_]*/[ANTHROPIC_KEY]}"
    print_message "debug" "Executing: ${cmd}"
}
```

### Attack Surfaces

#### External Input Sources

- User-provided arguments to workflow commands
- GitHub API responses (issue titles, PR descriptions)
- Git repository data (commit messages, branch names)
- File system paths (project directories, file names)
- Environment variables (PROJECT_ROOT, AIDA_HOME)

#### Trust Boundaries

- Templates (framework-provided, trusted)
- Installed commands (user-writable, trust verification needed)
- Command arguments (user-provided, untrusted)
- Git data (potentially malicious, validate before use)
- GitHub data (external source, validate all responses)

#### Critical Operations

- Shell command execution (highest risk)
- File system modifications (high risk)
- Git operations (medium risk, can be destructive)
- GitHub API calls (medium risk, authentication required)
- State file modifications (low risk, local only)

## 3. Dependencies & Integration

### Security Validation Tools

#### Required Tools

```bash
# Shellcheck - Shell script static analysis
brew install shellcheck

# Yamllint - YAML validation
pip install yamllint

# Git-secrets - Prevent committing secrets
brew install git-secrets
```

#### Template Validation Script

```bash
#!/usr/bin/env bash
# validate-template.sh

set -euo pipefail

readonly TEMPLATE="$1"

# Run shellcheck on template
shellcheck -x "${TEMPLATE}" || {
    echo "ERROR: Shellcheck failed for ${TEMPLATE}"
    exit 1
}

# Check for secrets
if grep -qE 'sk-ant-|ghp_|AKIA' "${TEMPLATE}"; then
    echo "ERROR: Potential secret detected in ${TEMPLATE}"
    exit 1
fi

# Validate template variables
if grep -qE '\{\{[^}]+\}\}' "${TEMPLATE}"; then
    unknown_vars=$(grep -oE '\{\{[A-Z_]+\}\}' "${TEMPLATE}" | \
                   grep -vE '\{\{(PROJECT_ROOT|AIDA_HOME|HOME|USER)\}\}' || true)
    if [[ -n "${unknown_vars}" ]]; then
        echo "ERROR: Unknown variables in ${TEMPLATE}: ${unknown_vars}"
        exit 1
    fi
fi

echo "SUCCESS: ${TEMPLATE} passed validation"
```

### Pre-Commit Hook Integration

#### Hook Configuration

```yaml
# .pre-commit-config.yaml
repos:
  - repo: local
    hooks:
      - id: validate-command-templates
        name: Validate command templates
        entry: scripts/validate-template.sh
        language: script
        files: ^templates/commands/.*\.template$
        pass_filenames: true

      - id: shellcheck-templates
        name: Shellcheck command templates
        entry: shellcheck
        language: system
        files: ^templates/commands/.*\.template$
        args: ['-x']

      - id: detect-secrets-templates
        name: Detect secrets in templates
        entry: scripts/detect-secrets.sh
        language: script
        files: ^templates/commands/.*\.template$
        pass_filenames: true
```

#### Secret Detection Hook

```bash
#!/usr/bin/env bash
# scripts/detect-secrets.sh

set -euo pipefail

readonly FILE="$1"

# Anthropic API keys
if grep -qE 'sk-ant-[a-zA-Z0-9-_]{95}' "${FILE}"; then
    echo "ERROR: Anthropic API key detected in ${FILE}"
    exit 1
fi

# GitHub tokens
if grep -qE 'ghp_[a-zA-Z0-9]{36}' "${FILE}"; then
    echo "ERROR: GitHub token detected in ${FILE}"
    exit 1
fi

# AWS keys
if grep -qE 'AKIA[0-9A-Z]{16}' "${FILE}"; then
    echo "ERROR: AWS key detected in ${FILE}"
    exit 1
fi

# Generic secrets
if grep -qiE '(password|secret|api[_-]?key)\s*=\s*["\x27][^"\x27]{8,}["\x27]' "${FILE}"; then
    echo "WARNING: Potential secret pattern detected in ${FILE}"
    # Warning only, don't fail
fi

exit 0
```

### Audit Logging Needs

#### Security Audit Log Structure

```json
{
  "timestamp": "2025-10-07T14:30:00Z",
  "event_type": "command_execution",
  "command": "workflow-init",
  "user": "oakensoul",
  "success": true,
  "security_context": {
    "template_hash": "abc123...",
    "permissions_validated": true,
    "input_sanitized": true
  }
}
```

#### Audit Events to Log

- Template installation (source, destination, hash)
- Permission changes (file, old_perms, new_perms)
- Validation failures (template, reason)
- Secret detection (file, pattern_matched)
- Command execution (command, arguments, result)
- Dev mode activation (repository, symlink_target)

#### Log Location and Retention

```bash
# Audit log location
readonly AUDIT_LOG="${CLAUDE_DIR}/security/audit.log"

# Log with structured format
log_security_event() {
    local event_type="$1"
    local details="$2"
    local timestamp
    timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

    echo "{\"timestamp\":\"${timestamp}\",\"event\":\"${event_type}\",\"details\":\"${details}\"}" >> "${AUDIT_LOG}"
}

# Retention: 90 days
rotate_audit_log() {
    if [[ -f "${AUDIT_LOG}" ]]; then
        find "${CLAUDE_DIR}/security" -name "audit.log.*" -mtime +90 -delete
        mv "${AUDIT_LOG}" "${AUDIT_LOG}.$(date +%Y%m%d)"
    fi
}
```

## 4. Effort & Complexity

### Estimated Complexity

#### Overall: LARGE (L)

**Breakdown by component**:

- Template validation framework: Medium (M)
- Permission management: Small (S)
- Input sanitization: Medium (M)
- Secret detection: Small (S)
- Pre-commit integration: Medium (M)
- Audit logging: Small (S)
- Documentation: Medium (M)
- Testing: Medium (M)

### Security Implementation Effort

#### Phase 1: Core Security (P0)

**Estimated**: 8-12 hours

- Input validation functions: 2 hours
- Permission enforcement: 2 hours
- Basic secret detection: 2 hours
- Template validation: 3 hours
- Testing: 3 hours

#### Phase 2: Validation Pipeline (P1)

**Estimated**: 6-8 hours

- Pre-commit hooks: 2 hours
- Validation scripts: 3 hours
- Integration testing: 3 hours

#### Phase 3: Audit & Monitoring (P2)

**Estimated**: 4-6 hours

- Audit logging: 2 hours
- Log rotation: 1 hour
- Security documentation: 3 hours

#### Total Estimated Effort

18-26 hours

### High-Risk Areas

#### Critical Risk: Command Injection

- Likelihood: High (user customization increases attack surface)
- Impact: Critical (arbitrary code execution)
- Mitigation effort: Medium (validate all input, quote variables)
- Testing complexity: High (need comprehensive injection test cases)

#### High Risk: Secret Exposure

- Likelihood: Medium (users may hardcode secrets)
- Impact: High (credential compromise)
- Mitigation effort: Low (pattern detection, documentation)
- Testing complexity: Low (regex pattern matching)

#### High Risk: Permission Bypass

- Likelihood: Low (race conditions, implementation bugs)
- Impact: High (unauthorized modification of commands)
- Mitigation effort: Medium (atomic operations, verification)
- Testing complexity: Medium (need concurrent access tests)

#### Medium Risk: Path Traversal

- Likelihood: Medium (symlinks, relative paths)
- Impact: Medium (unauthorized file access)
- Mitigation effort: Low (path validation, canonicalization)
- Testing complexity: Low (straightforward test cases)

## 5. Questions & Clarifications

### Security Implementation Questions

#### Validation Strictness

- Q: Should template validation be enforced (block) or advisory (warn)?
- Recommendation: Enforce critical checks (secrets, injection), warn for style issues
- Rationale: Prevents security vulnerabilities without blocking development

#### Permission Recovery

- Q: How to handle commands with incorrect permissions?
- Options: (1) Auto-fix on detection, (2) Prompt user, (3) Block execution
- Recommendation: Auto-fix with audit log entry and user notification

#### Sandboxing Approach

- Q: Should commands run in restricted environment?
- Options: (1) Full shell access, (2) Restricted PATH, (3) Containerized execution
- Recommendation: Phase 1 full access, Phase 2 restricted PATH, Phase 3 evaluate containers

### Validation Decisions

#### Template Modification Detection

- Q: How to detect if user modified installed command vs framework template?
- Options: (1) Hash comparison, (2) Version markers, (3) No detection
- Recommendation: Hash comparison stored in metadata file

#### Validation Bypass

- Q: Should there be escape hatch for validation (--force flag)?
- Security concern: Reduces validation effectiveness
- Recommendation: No bypass for secret detection, allow override for other checks with explicit consent

#### Third-Party Templates

- Q: How to handle templates from external sources?
- Security concern: Malicious template distribution
- Recommendation: Phase 1 framework-only, Phase 2 add signing/verification

### Audit Requirements

#### Log Sensitivity

- Q: What level of detail should audit logs contain?
- Privacy concern: Command arguments may contain sensitive data
- Recommendation: Log command names and success/failure, redact arguments

#### Log Access

- Q: Who can access security audit logs?
- Options: (1) User only (600 permissions), (2) Admin readable (640), (3) System logs (syslog)
- Recommendation: User only (600) in ~/.claude/security/audit.log

#### Compliance Logging

- Q: Are there compliance requirements for audit logs?
- Context: GDPR, SOC2, etc.
- Recommendation: Document what is logged, provide export capability, honor retention policies

## Implementation Priority

### Phase 1: Critical Security (MVP)

1. Input validation functions
2. Permission enforcement (644/600)
3. Basic secret detection
4. Template variable validation
5. Core security tests

### Phase 2: Validation Pipeline

1. Pre-commit hook integration
2. Shellcheck validation
3. Secret scanning automation
4. Integration tests

### Phase 3: Monitoring & Audit

1. Audit logging implementation
2. Security documentation
3. Incident response procedures
4. Penetration testing

## Success Criteria

Security implementation successful when:

- Zero command injection vulnerabilities in templates
- 100% of templates pass secret detection
- All installed commands have 600 permissions
- Pre-commit hooks catch security issues before commit
- Audit logs capture all security-relevant events
- Documentation explains security model clearly
- Test suite validates all security controls
