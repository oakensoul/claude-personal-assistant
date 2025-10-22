---
name: security-audit
description: Conduct comprehensive security audit of data platform including Snowflake, Metabase, Airbyte, and dbt Cloud with STRIDE threat modeling
model: sonnet
args:
  scope:
    description: Audit scope (snowflake, metabase, airbyte, dbt-cloud, encryption, access-control, network, api-security, secrets, all)
    required: false
  framework:
    description: Compliance framework to validate against (SOC2, ISO27001, GDPR, HIPAA, all)
    required: false
  comprehensive:
    description: Run comprehensive cross-platform audit with all scopes and frameworks
    required: false
version: 1.0.0
category: analysis
---

# Security Audit & Vulnerability Assessment

Perform comprehensive security audit of the data platform infrastructure, analyzing encryption, access controls, network security, API security, and secret management across Snowflake, Metabase, Airbyte, and dbt Cloud. Applies STRIDE threat modeling methodology and validates compliance against industry frameworks.

## Usage

```bash
# Platform-specific audits
/security-audit --scope snowflake
/security-audit --scope metabase-api
/security-audit --scope airbyte
/security-audit --scope dbt-cloud

# Security domain audits
/security-audit --scope encryption
/security-audit --scope access-control
/security-audit --scope network
/security-audit --scope api-security
/security-audit --scope secrets

# Compliance framework audits
/security-audit --framework SOC2
/security-audit --framework ISO27001
/security-audit --framework GDPR

# Comprehensive audit (all scopes + all frameworks)
/security-audit --comprehensive

# Combined scope and framework
/security-audit --scope metabase --framework SOC2

# Default (comprehensive audit)
/security-audit
```

## Audit Scopes

### Platform Components

- **snowflake** - Snowflake security (encryption, RBAC, network policies, MFA, audit trails)
- **metabase** - Metabase API security, SSO configuration, row-level security, dashboard permissions
- **airbyte** - Airbyte connection security, webhook security, credential management, encryption
- **dbt-cloud** - dbt Cloud API keys, service accounts, OAuth configuration, job security
- **all** - Comprehensive cross-platform audit (default if no scope specified)

### Security Domains

- **encryption** - Data at-rest encryption, in-transit encryption, key management, algorithm standards
- **access-control** - RBAC/ABAC models, least privilege, MFA enforcement, identity management
- **network** - VPC configuration, security groups, IP allowlisting, private endpoints, firewalls
- **api-security** - OAuth/JWT authentication, rate limiting, API key management, token expiration
- **secrets** - Credential storage, secret rotation policies, Vault/Secrets Manager integration

### Compliance Frameworks

- **SOC2** - SOC 2 Type II controls (access, encryption, monitoring, incident response)
- **ISO27001** - ISO 27001 cryptography and access control standards
- **GDPR** - GDPR Article 32 encryption and security requirements
- **HIPAA** - HIPAA Security Rule technical safeguards (if applicable)
- **all** - Validate against all applicable frameworks

## Workflow

### Phase 1: Initialize Audit Context

1. **Parse Arguments & Determine Scope**

   - If `--comprehensive` flag: Set scope to all platforms + all domains + all frameworks
   - If `--scope` provided: Use specified scope (snowflake, metabase, etc.)
   - If `--framework` provided: Use specified framework (SOC2, ISO27001, etc.)
   - If no arguments: Default to comprehensive audit
   - Display audit plan:

     ```text
     🔒 Security Audit Initialized
     ==============================
     Scope: {scope}
     Framework: {framework}
     Date: {YYYY-MM-DD}
     Auditor: security-engineer agent
     ```

2. **Create Audit Directory**
   - Create working directory: `.security-audits/{YYYY-MM-DD}/`
   - Create subdirectories:
     - `findings/` - Vulnerability findings
     - `evidence/` - Supporting evidence (configs, screenshots, logs)
     - `reports/` - Generated reports
     - `threat-models/` - STRIDE analysis results

3. **Load Audit Configuration**
   - Check for audit configuration: `.security-audits/audit-config.json`
   - If exists: Load custom thresholds, ignored findings, remediation tracking
   - If not exists: Use default configuration
   - Example config:

     ```json
     {
       "severity_thresholds": {
         "critical": 9.0,
         "high": 7.0,
         "medium": 4.0,
         "low": 0.1
       },
       "ignored_findings": [
         "FINDING-2025-01-15-001"
       ],
       "remediation_tracking": {
         "enabled": true,
         "sla_days": {
           "critical": 1,
           "high": 7,
           "medium": 30,
           "low": 90
         }
       }
     }
     ```

### Phase 2: Security Context Gathering

Invoke **security-engineer** agent to inventory security controls:

```yaml
Task(
  subagent_type="security-engineer",
  prompt="""
  Gather security context for audit scope: {scope}

  Collect information on:

  1. Snowflake Security (if in scope):
     - Network policies (IP allowlists, blocked IPs)
     - MFA status for all users (especially admin roles)
     - Role hierarchies and privilege assignments
     - Encryption configuration (Tri-Secret Secure, customer-managed keys)
     - Access history and audit trail configuration
     - OAuth/SAML integration status
     - Service account inventory and credential age

  2. Metabase Security (if in scope):
     - SSO configuration (SAML/OAuth provider)
     - API authentication methods (session tokens, API keys)
     - Row-level security (RLS) implementation
     - Dashboard permissions and public access
     - Database connection credentials (age, storage method)
     - Rate limiting configuration
     - Session timeout settings

  3. Airbyte Security (if in scope):
     - Connection credential storage (encrypted, Vault integration)
     - Webhook security (authentication, TLS)
     - Source/destination encryption status
     - API authentication method
     - Network access controls

  4. dbt Cloud Security (if in scope):
     - API key inventory and age
     - Service account permissions
     - OAuth application configuration
     - Job execution security (credential injection)
     - Git integration security (SSH keys, deploy keys)

  5. Secret Management (if in scope):
     - Secret storage method (Vault, Secrets Manager, environment variables)
     - Rotation policies and last rotation dates
     - Access logging and audit trails
     - Encryption of secrets at rest

  Save inventory to: .security-audits/{YYYY-MM-DD}/evidence/security-inventory.md
  """
)
```

**Expected Output**: Structured inventory of all security controls, configurations, and current state.

### Phase 3: STRIDE Threat Modeling

Invoke **security-engineer** agent to perform STRIDE analysis for each component in scope:

```yaml
Task(
  subagent_type="security-engineer",
  prompt="""
  Apply STRIDE threat modeling to: {scope}

  For each threat category, identify vulnerabilities:

  ## Spoofing (Identity)
  - Authentication weaknesses (missing MFA, weak passwords)
  - Service account impersonation risks
  - OAuth/SAML misconfiguration
  - API key sharing or reuse

  ## Tampering (Integrity)
  - Data integrity controls (checksums, digital signatures)
  - Configuration tampering risks
  - Audit log tampering possibilities
  - SQL injection or data manipulation vectors

  ## Repudiation (Audit Trail)
  - Missing or incomplete audit logs
  - Insufficient log retention (< 1 year for compliance)
  - No alerting on privilege escalation
  - Gaps in access history tracking

  ## Information Disclosure (Confidentiality)
  - Encryption gaps (missing TLS, weak algorithms)
  - Publicly accessible dashboards or APIs
  - Credential exposure in logs or configs
  - Insufficient network segmentation

  ## Denial of Service (Availability)
  - Missing rate limiting on APIs
  - Resource exhaustion risks (no query timeouts)
  - Lack of redundancy or failover
  - Insufficient monitoring for service degradation

  ## Elevation of Privilege (Authorization)
  - RBAC misconfigurations (overly permissive roles)
  - Missing least privilege enforcement
  - Service accounts with admin privileges
  - Privilege escalation paths

  For each identified threat:
  - Threat ID: THREAT-{YYYY-MM-DD}-{nnn}
  - Category: Spoofing/Tampering/Repudiation/Disclosure/DoS/Privilege
  - Description: What is the threat?
  - Likelihood: High/Medium/Low
  - Impact: High/Medium/Low
  - Risk Score: (Likelihood × Impact)
  - Affected Component: {component}
  - Mitigation Status: Mitigated/Partially Mitigated/Unmitigated

  Save threat model to: .security-audits/{YYYY-MM-DD}/threat-models/{scope}-stride-analysis.md
  """
)
```

**Expected Output**: STRIDE threat model with categorized threats, risk scores, and mitigation status.

### Phase 4: Compliance Validation

If framework specified, invoke **security-engineer** agent to validate compliance controls:

```yaml
Task(
  subagent_type="security-engineer",
  prompt="""
  Validate compliance controls for framework: {framework}

  ## SOC 2 Type II (if applicable)
  Control Families to Validate:
  - CC6.1: Logical access controls (RBAC, MFA, password policies)
  - CC6.6: Encryption at rest and in transit
  - CC6.7: Encryption key management
  - CC7.2: Audit logging and monitoring
  - CC7.3: Security event alerting
  - CC9.1: Risk assessment process

  For each control:
  - Control ID: {CC-X.X}
  - Control Description: {description}
  - Implementation Status: Implemented/Partially Implemented/Not Implemented
  - Evidence: {reference to security inventory or config}
  - Gaps: {list deficiencies}
  - Remediation: {recommended actions}

  ## ISO 27001 (if applicable)
  Control Domains to Validate:
  - A.9: Access control (user access management, privilege management)
  - A.10: Cryptography (encryption policies, key management)
  - A.12: Operations security (logging, monitoring, malware protection)
  - A.13: Communications security (network security, data transfer)
  - A.14: System acquisition (secure development, change management)

  ## GDPR Article 32 (if applicable)
  Security Measures to Validate:
  - Pseudonymization and encryption of personal data
  - Ongoing confidentiality, integrity, availability
  - Restore availability after incident
  - Regular testing and evaluation

  Save compliance report to: .security-audits/{YYYY-MM-DD}/reports/{framework}-compliance-report.md
  """
)
```

**Expected Output**: Compliance gap analysis with control status, evidence, and remediation recommendations.

### Phase 5: Vulnerability Assessment

Invoke **security-engineer** agent to scan for specific vulnerabilities:

```yaml
Task(
  subagent_type="security-engineer",
  prompt="""
  Scan for vulnerabilities in scope: {scope}

  ## Encryption Vulnerabilities
  - TLS version < 1.2 in use
  - Weak cipher suites (RC4, 3DES, MD5)
  - Missing HSTS headers
  - Expired or self-signed certificates
  - Unencrypted data at rest
  - Missing or outdated encryption algorithms (not AES-256)

  ## Access Control Vulnerabilities
  - Missing MFA enforcement (especially for admin accounts)
  - Weak password policies (< 12 chars, no complexity)
  - Overly permissive roles (admin access granted unnecessarily)
  - Stale user accounts (no activity > 90 days)
  - Shared service account credentials
  - Missing Just-In-Time (JIT) access for elevated privileges

  ## API Security Vulnerabilities
  - API keys not rotated in > 90 days
  - Missing rate limiting (risk of abuse/DoS)
  - OAuth tokens with excessive scopes
  - Long-lived tokens (> 24 hours for sensitive operations)
  - Missing request validation (injection risks)
  - Publicly accessible API endpoints without authentication

  ## Secret Management Vulnerabilities
  - Secrets stored in code or config files
  - Secrets stored in environment variables (unencrypted)
  - No secret rotation policy or automation
  - Secrets shared across environments (dev/prod)
  - Missing access logging for secret retrieval
  - Unencrypted secret storage

  ## Network Security Vulnerabilities
  - Public internet exposure (should use private subnets)
  - Overly permissive security groups (0.0.0.0/0 allowed)
  - Missing IP allowlisting for production access
  - No VPC endpoints (traffic over public internet)
  - Missing network segmentation (flat network)
  - Unnecessary open ports

  For each vulnerability found:
  - Vulnerability ID: VULN-{YYYY-MM-DD}-{nnn}
  - Title: {concise title}
  - Severity: Critical/High/Medium/Low
  - CVSS Score: {0.0-10.0}
  - Affected Component: {component}
  - Description: {what is the vulnerability}
  - Risk: {what could happen if exploited}
  - Evidence: {config snippet, log entry, screenshot}
  - Remediation: {specific steps to fix}
  - Priority: Immediate/Short-term/Medium-term/Long-term

  Save vulnerability report to: .security-audits/{YYYY-MM-DD}/findings/vulnerabilities.md
  """
)
```

**Expected Output**: Detailed vulnerability inventory with CVSS scores, evidence, and remediation steps.

### Phase 6: Risk Scoring & Prioritization

Process all findings and calculate risk scores:

1. **Calculate CVSS Scores**

   - For each vulnerability, compute CVSS 3.1 base score
   - Factors: Attack Vector, Attack Complexity, Privileges Required, User Interaction, Scope, Confidentiality Impact, Integrity Impact, Availability Impact
   - Map to severity:
     - Critical: CVSS ≥ 9.0
     - High: CVSS 7.0-8.9
     - Medium: CVSS 4.0-6.9
     - Low: CVSS 0.1-3.9

2. **Risk Prioritization Matrix**
   - Critical + Easy Exploitability = Immediate (< 1 week)
   - Critical + Moderate/Hard Exploitability = Short-term (1-4 weeks)
   - High + High Business Impact = Short-term (1-4 weeks)
   - High + Medium Business Impact = Medium-term (1-3 months)
   - Medium/Low = Long-term (> 3 months)

3. **Business Impact Assessment**
   - Data Breach: Exposure of PII, financial data, credentials
   - Compliance Violation: Failure to meet SOC 2, GDPR, ISO 27001
   - Service Downtime: Loss of data warehouse, BI platform, ETL pipelines
   - Reputational Damage: Public disclosure, customer trust loss

### Phase 7: Remediation Roadmap

Generate actionable remediation plan organized by timeline:

```markdown
# Security Remediation Roadmap

## Immediate Priority (< 1 week)
Critical vulnerabilities requiring urgent action:

### VULN-2025-10-07-001: Metabase API keys not rotated in 180+ days
- **Severity**: High (CVSS 7.5)
- **Risk**: API key compromise could expose all dashboard data and database credentials
- **Remediation**:
  1. Generate new Metabase API keys for all service accounts
  2. Update dbt Cloud, Airbyte, and internal scripts with new keys
  3. Revoke old API keys (coordinate with teams to minimize downtime)
  4. Implement 90-day rotation policy with calendar reminders
- **Effort**: 4 hours
- **Owner**: DevOps Engineer + Security Engineer

### VULN-2025-10-07-002: Snowflake admin accounts missing MFA
- **Severity**: Critical (CVSS 9.1)
- **Risk**: Account compromise could result in complete data warehouse access and data exfiltration
- **Remediation**:
  1. Enable MFA for all ACCOUNTADMIN and SECURITYADMIN roles
  2. Audit current admin role assignments (revoke unnecessary privileges)
  3. Implement MFA enforcement policy in Snowflake
  4. Document MFA setup process for onboarding
- **Effort**: 2 hours
- **Owner**: Security Engineer

## Short-Term Priority (1-4 weeks)

### VULN-2025-10-07-003: Missing secret rotation automation
- **Severity**: Medium (CVSS 5.5)
- **Risk**: Manual rotation prone to errors and missed deadlines, increasing credential exposure window
- **Remediation**:
  1. Implement HashiCorp Vault with dynamic credential generation
  2. Configure Vault Snowflake secrets engine (24-hour TTL)
  3. Update dbt Cloud, Airbyte, Metabase to fetch credentials from Vault
  4. Automate monthly rotation for non-dynamic secrets
- **Effort**: 40 hours
- **Owner**: DevOps Engineer + Security Engineer

### VULN-2025-10-07-004: Airbyte webhooks missing IP allowlisting
- **Severity**: Medium (CVSS 6.0)
- **Risk**: Unauthorized webhook requests could trigger malicious data sync operations
- **Remediation**:
  1. Configure IP allowlist for Airbyte webhook endpoints
  2. Implement webhook signature validation (HMAC)
  3. Add rate limiting (10 requests/min per source)
  4. Monitor failed authentication attempts
- **Effort**: 8 hours
- **Owner**: Data Engineer + Security Engineer

## Medium-Term Priority (1-3 months)

### VULN-2025-10-07-005: Missing centralized secret management
- **Severity**: Medium (CVSS 5.0)
- **Risk**: Decentralized secret storage increases risk of exposure and complicates rotation
- **Remediation**:
  1. Deploy HashiCorp Vault in production environment
  2. Migrate all secrets from environment variables to Vault
  3. Configure Vault policies for least-privilege access
  4. Implement audit logging for all secret retrieval
- **Effort**: 80 hours
- **Owner**: DevOps Engineer + Security Engineer

### VULN-2025-10-07-006: Snowflake network policies not configured
- **Severity**: Medium (CVSS 5.5)
- **Risk**: Unrestricted network access increases attack surface for credential stuffing
- **Remediation**:
  1. Define IP allowlist for production access (office IPs, VPN, AWS NAT Gateway)
  2. Create Snowflake network policy with allowlist
  3. Apply policy to all production roles
  4. Test connectivity from approved locations
- **Effort**: 16 hours
- **Owner**: Security Engineer + DevOps Engineer

## Long-Term Priority (> 3 months)

### Strategic Initiative: SOC 2 Type II Certification
- **Effort**: 200+ hours
- **Timeline**: 6-12 months
- **Key Milestones**:
  1. Gap analysis and remediation (3 months)
  2. Control implementation and testing (3 months)
  3. Audit readiness review (1 month)
  4. External audit (1-2 months)

### Strategic Initiative: Zero-Trust Network Architecture
- **Effort**: 300+ hours
- **Timeline**: 12+ months
- **Key Components**:
  1. Identity-based access (replace IP allowlisting with identity verification)
  2. Microsegmentation (isolate data warehouse, BI, ETL networks)
  3. Continuous authentication and authorization
  4. Encrypted service mesh (mTLS for all service-to-service communication)
```

### Phase 8: Generate Executive Summary Report

Create comprehensive audit report for stakeholders:

```markdown
# Security Audit Report
**Audit Date**: {YYYY-MM-DD}
**Scope**: {scope}
**Framework**: {framework}
**Auditor**: security-engineer agent

---

## Executive Summary

### Overall Risk Score: 7.2/10 (Medium Risk)

The data platform security audit identified **{count}** vulnerabilities across {scope}. While encryption and network security are generally strong, significant gaps exist in access control (missing MFA) and secret management (unrotated API keys). Immediate action required on {critical_count} critical findings.

### Key Findings
- **Critical**: {critical_count} findings requiring immediate remediation (< 1 week)
- **High**: {high_count} findings requiring short-term remediation (1-4 weeks)
- **Medium**: {medium_count} findings requiring medium-term remediation (1-3 months)
- **Low**: {low_count} findings requiring long-term remediation (> 3 months)

### Top 3 Risks
1. **Metabase API keys not rotated (180+ days)** - CVSS 7.5 (High)
   - Risk: Compromised keys could expose all dashboard data and database credentials
   - Immediate remediation required

2. **Snowflake admin accounts missing MFA** - CVSS 9.1 (Critical)
   - Risk: Account takeover could result in data warehouse breach
   - Immediate remediation required

3. **No centralized secret management** - CVSS 5.5 (Medium)
   - Risk: Decentralized secrets increase exposure risk and complicate rotation
   - Medium-term remediation (deploy HashiCorp Vault)

---

## STRIDE Threat Model Summary

### Spoofing Risks: {count}
- Missing MFA for Snowflake admin accounts (Critical)
- Weak password policies (Medium)

### Tampering Risks: {count}
- Insufficient audit log retention (Medium)

### Repudiation Risks: {count}
- No alerting on privilege escalation events (Low)

### Information Disclosure Risks: {count}
- Metabase API keys unrotated (High)
- Credentials in environment variables (Medium)
- Missing network segmentation (Medium)

### Denial of Service Risks: {count}
- Missing rate limiting on Airbyte webhooks (Medium)

### Elevation of Privilege Risks: {count}
- Overly permissive Snowflake roles (High)
- Service accounts with admin privileges (Medium)

---

## Compliance Status

### SOC 2 Type II
| Control | Status | Gaps |
|---------|--------|------|
| CC6.1 - Logical Access | ⚠️ Partial | MFA not enforced for all admin users |
| CC6.6 - Encryption | ✅ Implemented | None |
| CC6.7 - Key Management | ⚠️ Partial | No documented key rotation policy |
| CC7.2 - Audit Logging | ⚠️ Partial | Log retention < 1 year |
| CC7.3 - Security Alerting | ❌ Not Implemented | No SIEM integration |

**Overall**: 40% compliant, 40% partial, 20% gaps

### GDPR Article 32
| Requirement | Status | Gaps |
|-------------|--------|------|
| Encryption of personal data | ✅ Implemented | None (AES-256 at rest, TLS 1.2+ in transit) |
| Ongoing confidentiality/integrity | ⚠️ Partial | Missing secret rotation policy |
| Restore availability after incident | ⚠️ Partial | No documented disaster recovery plan |
| Regular testing | ❌ Not Implemented | No penetration testing program |

**Overall**: 25% compliant, 50% partial, 25% gaps

### ISO 27001
| Control Domain | Status | Gaps |
|----------------|--------|------|
| A.9 - Access Control | ⚠️ Partial | MFA gaps, overly permissive roles |
| A.10 - Cryptography | ✅ Implemented | Strong encryption standards in place |
| A.12 - Operations Security | ⚠️ Partial | Insufficient logging and monitoring |
| A.13 - Network Security | ⚠️ Partial | Missing IP allowlisting, network segmentation |

**Overall**: 25% compliant, 75% partial

---

## Remediation Roadmap

### Immediate (< 1 week) - {critical_count} items
Total Effort: {hours} hours

1. Rotate all Metabase API keys (4 hours)
2. Enable MFA for Snowflake admin accounts (2 hours)

### Short-Term (1-4 weeks) - {high_count} items
Total Effort: {hours} hours

1. Implement secret rotation automation (40 hours)
2. Configure IP allowlisting for Airbyte webhooks (8 hours)
3. Audit and remediate overly permissive Snowflake roles (16 hours)

### Medium-Term (1-3 months) - {medium_count} items
Total Effort: {hours} hours

1. Deploy HashiCorp Vault for centralized secret management (80 hours)
2. Implement Snowflake network policies (16 hours)
3. Configure SIEM integration for security alerting (40 hours)

### Long-Term (> 3 months) - {low_count} items
Total Effort: {hours} hours

1. Achieve SOC 2 Type II certification (200+ hours)
2. Implement zero-trust network architecture (300+ hours)
3. Establish quarterly penetration testing program (40 hours/quarter)

---

## Risk Acceptance

The following low-priority findings may be accepted with documented justification:

- **VULN-2025-10-07-015**: Snowflake query result cache enabled (Low)
  - Risk: Minimal (cache is encrypted, access controlled by role)
  - Justification: Performance benefits outweigh minimal security risk
  - Review Date: 2026-01-01

---

## Audit Artifacts

- **Security Inventory**: `.security-audits/{YYYY-MM-DD}/evidence/security-inventory.md`
- **STRIDE Analysis**: `.security-audits/{YYYY-MM-DD}/threat-models/{scope}-stride-analysis.md`
- **Vulnerability Report**: `.security-audits/{YYYY-MM-DD}/findings/vulnerabilities.md`
- **Compliance Report**: `.security-audits/{YYYY-MM-DD}/reports/{framework}-compliance-report.md`
- **Executive Summary**: `.security-audits/{YYYY-MM-DD}/reports/executive-summary.md`

---

## Next Steps

1. **Review Report**: Security team + stakeholders review findings
2. **Prioritize Remediation**: Confirm timeline and resource allocation
3. **Assign Ownership**: Assign vulnerabilities to DevOps/Security/Engineering teams
4. **Track Progress**: Create tracking tickets for each remediation item
5. **Follow-Up Audit**: Schedule follow-up audit in 90 days to verify remediation

---

**Report Generated**: {YYYY-MM-DD HH:MM:SS}
**Security Engineer**: security-engineer agent
```

Save executive summary to: `.security-audits/{YYYY-MM-DD}/reports/executive-summary.md`

### Phase 9: Display Audit Summary

Present audit results to user:

```text
✅ Security Audit Complete!
============================

Audit Date: {YYYY-MM-DD}
Scope: {scope}
Framework: {framework}

Overall Risk Score: 7.2/10 (Medium Risk)

Findings Summary:
• Critical: {count} (immediate action required)
• High: {count} (1-4 weeks)
• Medium: {count} (1-3 months)
• Low: {count} (> 3 months)

STRIDE Threat Analysis:
• Spoofing Risks: {count}
• Tampering Risks: {count}
• Repudiation Risks: {count}
• Information Disclosure Risks: {count}
• Denial of Service Risks: {count}
• Elevation of Privilege Risks: {count}

Compliance Status:
• SOC 2: 40% compliant, 40% partial, 20% gaps
• GDPR: 25% compliant, 50% partial, 25% gaps
• ISO 27001: 25% compliant, 75% partial

Top 3 Immediate Priorities:
1. Rotate Metabase API keys (CVSS 7.5) - 4 hours
2. Enable MFA for Snowflake admins (CVSS 9.1) - 2 hours
3. Implement secret rotation automation (CVSS 5.5) - 40 hours

Reports Generated:
✓ Executive Summary: .security-audits/{YYYY-MM-DD}/reports/executive-summary.md
✓ Vulnerability Report: .security-audits/{YYYY-MM-DD}/findings/vulnerabilities.md
✓ STRIDE Analysis: .security-audits/{YYYY-MM-DD}/threat-models/{scope}-stride-analysis.md
✓ Compliance Report: .security-audits/{YYYY-MM-DD}/reports/{framework}-compliance-report.md

Next Steps:
1. Review executive summary with stakeholders
2. Create JIRA tickets for remediation items
3. Assign ownership to DevOps/Security teams
4. Track remediation progress
5. Schedule follow-up audit in 90 days
```

## Examples

### Example 1: Quarterly SOC 2 Audit

```bash
/security-audit --framework SOC2

# Output:
🔒 Security Audit Initialized
==============================
Scope: all (comprehensive)
Framework: SOC 2 Type II
Date: 2025-10-07
Auditor: security-engineer agent

Phase 1: Security Context Gathering...
✓ Snowflake security inventory complete
✓ Metabase security inventory complete
✓ Airbyte security inventory complete
✓ dbt Cloud security inventory complete

Phase 2: STRIDE Threat Modeling...
✓ Spoofing analysis: 2 threats identified
✓ Tampering analysis: 1 threat identified
✓ Repudiation analysis: 1 threat identified
✓ Information Disclosure analysis: 3 threats identified
✓ Denial of Service analysis: 1 threat identified
✓ Elevation of Privilege analysis: 2 threats identified

Phase 3: SOC 2 Compliance Validation...
✓ CC6.1 - Logical Access: Partial (MFA gaps)
✓ CC6.6 - Encryption: Implemented
⚠️ CC6.7 - Key Management: Partial (no rotation policy)
⚠️ CC7.2 - Audit Logging: Partial (retention < 1 year)
❌ CC7.3 - Security Alerting: Not Implemented

Phase 4: Vulnerability Assessment...
✓ Found 15 vulnerabilities (2 critical, 5 high, 6 medium, 2 low)

Phase 5: Remediation Roadmap...
✓ Immediate priority: 2 items (6 hours effort)
✓ Short-term priority: 5 items (64 hours effort)
✓ Medium-term priority: 6 items (136 hours effort)
✓ Long-term priority: 2 items (500+ hours effort)

✅ Security Audit Complete!
Reports: .security-audits/2025-10-07/reports/
```

### Example 2: Metabase API Security Review

```bash
/security-audit --scope metabase-api

# Output:
🔒 Security Audit Initialized
==============================
Scope: metabase-api
Framework: None (best practices)
Date: 2025-10-07
Auditor: security-engineer agent

Phase 1: Metabase API Security Inventory...
✓ API authentication methods documented
✓ Rate limiting configuration reviewed
✓ Token expiration policies checked
✓ OAuth integration status verified

Phase 2: STRIDE Analysis (API-focused)...
✓ API spoofing risks: Missing token validation
✓ API tampering risks: Insufficient request validation
✓ API disclosure risks: Long-lived API keys (180+ days)
✓ API DoS risks: No rate limiting configured

Phase 3: API Vulnerability Scan...
✓ VULN-001: Metabase API keys not rotated (High - CVSS 7.5)
✓ VULN-002: Missing rate limiting (Medium - CVSS 6.0)
✓ VULN-003: OAuth tokens with excessive scopes (Medium - CVSS 5.0)

Phase 4: Remediation Plan...
Immediate:
1. Rotate all Metabase API keys (4 hours)
2. Implement 90-day rotation policy (2 hours)

Short-term:
1. Deploy Kong API Gateway with rate limiting (24 hours)
2. Reduce OAuth token scopes (8 hours)
3. Implement JWT with short-lived tokens (40 hours)

✅ Security Audit Complete!
Reports: .security-audits/2025-10-07/reports/metabase-api-audit.md
```

### Example 3: Encryption Compliance Audit

```bash
/security-audit --scope encryption --framework GDPR

# Output:
🔒 Security Audit Initialized
==============================
Scope: encryption (all platforms)
Framework: GDPR Article 32
Date: 2025-10-07
Auditor: security-engineer agent

Phase 1: Encryption Inventory...
✓ Snowflake: AES-256 at rest, TLS 1.2+ in transit, Tri-Secret Secure enabled
✓ Metabase: Database connections encrypted (TLS 1.2+)
✓ Airbyte: Source/destination encryption enabled
✓ dbt Cloud: Git over SSH, API over HTTPS
✓ AWS S3: Server-side encryption (SSE-S3)

Phase 2: GDPR Article 32 Validation...
✓ Encryption of personal data: COMPLIANT (AES-256)
⚠️ Key management: PARTIAL (no rotation policy documented)
✓ Data in transit: COMPLIANT (TLS 1.2+)

Phase 3: Encryption Vulnerabilities...
⚠️ VULN-001: No documented key rotation policy (Medium - CVSS 5.0)
✓ No weak cipher suites detected
✓ No expired certificates detected
✓ All TLS versions ≥ 1.2

✅ Security Audit Complete!
Overall: GDPR Article 32 compliant (1 minor gap)

Recommendation:
- Document key rotation policy (AWS KMS annual rotation)
- Establish encryption standards document

Reports: .security-audits/2025-10-07/reports/encryption-gdpr-audit.md
```

## Configuration

### Audit Configuration File

Create `.security-audits/audit-config.json` for custom audit settings:

```json
{
  "audit_metadata": {
    "organization": "Splash Sports",
    "data_classification": "Confidential",
    "audit_frequency": "quarterly",
    "last_audit_date": "2025-07-01"
  },
  "severity_thresholds": {
    "critical": 9.0,
    "high": 7.0,
    "medium": 4.0,
    "low": 0.1
  },
  "compliance_frameworks": {
    "required": ["SOC2"],
    "optional": ["ISO27001", "GDPR"]
  },
  "remediation_sla": {
    "critical": {
      "days": 1,
      "requires_approval": false
    },
    "high": {
      "days": 7,
      "requires_approval": false
    },
    "medium": {
      "days": 30,
      "requires_approval": true
    },
    "low": {
      "days": 90,
      "requires_approval": true
    }
  },
  "ignored_findings": [
    {
      "id": "VULN-2025-07-01-015",
      "reason": "Risk accepted - Snowflake query cache provides performance benefit",
      "accepted_by": "Security Team",
      "review_date": "2026-01-01"
    }
  ],
  "notification": {
    "enabled": true,
    "channels": ["email", "slack"],
    "recipients": ["security@example.com", "#security-alerts"]
  }
}
```

## Error Handling

- **Missing security-engineer agent**: Display error, suggest running `/create-agent security-engineer`
- **Invalid scope**: Display valid scopes, suggest `/security-audit --help`
- **Invalid framework**: Display valid frameworks
- **Permission errors**: Display error with file path and required permissions
- **Agent invocation fails**: Log error, continue with available analyses (partial audit)
- **Empty inventory**: Display warning, recommend manual configuration review

## Success Criteria

- Security inventory collected for all in-scope components
- STRIDE threat model generated with risk scores
- Vulnerability assessment completed with CVSS scores
- Compliance status validated (if framework specified)
- Remediation roadmap generated with timeline and effort estimates
- Executive summary report created
- All audit artifacts saved to `.security-audits/{YYYY-MM-DD}/`

## Related Commands

- `/create-agent security-engineer` - Create security-engineer agent if missing
- `/expert-analysis` - Multi-agent analysis (can include security review)
- `/implement` - Implement remediation tasks from audit findings

## Integration with Workflow

1. **Quarterly Security Review**:
   - Run `/security-audit --comprehensive` every quarter
   - Generate JIRA tickets for remediation items
   - Track remediation progress
   - Schedule follow-up audit

2. **Pre-Production Deployment**:
   - Run `/security-audit --scope {new-component}` before deploying new services
   - Ensure compliance before go-live
   - Document security controls

3. **Incident Response**:
   - Run targeted audit after security incident
   - Identify root cause and vulnerabilities exploited
   - Validate remediation effectiveness

4. **Compliance Certification**:
   - Run `/security-audit --framework SOC2` during SOC 2 audit preparation
   - Remediate gaps before external auditor review
   - Document control implementation

## Notes

- **Comprehensive by default**: No arguments = full platform audit
- **STRIDE methodology**: Industry-standard threat modeling for complete coverage
- **CVSS scoring**: Objective vulnerability prioritization
- **Compliance-aware**: Maps findings to SOC 2, ISO 27001, GDPR controls
- **Actionable remediation**: Specific steps, effort estimates, ownership
- **Evidence collection**: Saves inventory, configs, logs for audit trail
- **Executive summary**: Business-friendly report for stakeholder communication

---

**Design Philosophy**: Provide security engineers and stakeholders with comprehensive, actionable security posture assessment using industry-standard methodologies (STRIDE, CVSS) and compliance frameworks (SOC 2, ISO 27001, GDPR).
