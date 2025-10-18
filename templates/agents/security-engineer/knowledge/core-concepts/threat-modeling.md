---
title: "Threat Modeling"
description: "STRIDE methodology, attack trees, risk assessment, and threat analysis for data platforms"
category: "core-concepts"
tags:
  - threat-modeling
  - stride
  - risk-assessment
  - security-analysis
last_updated: "2025-10-07"
---

# Threat Modeling

Comprehensive guide to threat modeling methodologies (STRIDE), attack trees, and risk assessment for cloud data platforms.

## Threat Modeling Fundamentals

### Goals of Threat Modeling
1. **Identify threats** before they become vulnerabilities
2. **Prioritize security controls** based on risk
3. **Design secure architecture** from the ground up
4. **Communicate security risks** to stakeholders

### Threat Modeling Process
1. **Define Security Objectives**: What are we protecting? (confidentiality, integrity, availability)
2. **Create Architecture Diagram**: Data flows, trust boundaries, entry points
3. **Identify Threats**: Use STRIDE methodology
4. **Assess Risk**: Likelihood × Impact = Risk Score
5. **Mitigate Threats**: Implement security controls
6. **Validate**: Penetration testing, security audits

## STRIDE Methodology

STRIDE is a threat classification framework developed by Microsoft for identifying security threats.

### STRIDE Threat Categories

| Threat | Description | Example | Mitigation |
|--------|-------------|---------|------------|
| **S**poofing | Impersonating another user/service | Attacker uses stolen API key to impersonate dbt service account | MFA, OAuth 2.0, certificate-based authentication |
| **T**ampering | Modifying data or code | Attacker modifies SQL query in transit (MITM attack) | TLS encryption, HMAC signatures, code signing |
| **R**epudiation | Denying an action occurred | User claims they didn't delete sensitive data | Audit logging, digital signatures, immutable logs |
| **I**nformation Disclosure | Exposing sensitive data | PII leaked through unencrypted API response | Encryption (TLS, at-rest), access controls, data masking |
| **D**enial of Service | Making system unavailable | Attacker floods API with requests, exhausting resources | Rate limiting, resource quotas, DDoS protection |
| **E**levation of Privilege | Gaining unauthorized permissions | Analyst escalates to SYSADMIN role through SQL injection | Least privilege, input validation, RBAC enforcement |

### Applying STRIDE to dbt-splash-prod-v2

#### Component: Snowflake Data Warehouse

**Spoofing Threats**:
- Attacker uses stolen username/password to access production data
- Service account credentials leaked in GitHub repository
- **Mitigations**:
  - MFA required for all human users
  - OAuth 2.0 for service accounts (dbt Cloud, Airbyte)
  - Network policies (IP allowlisting)
  - Secrets stored in AWS Secrets Manager (not code)

**Tampering Threats**:
- Attacker modifies data in Snowflake tables (e.g., alters financial transactions)
- SQL injection in dbt models or Metabase queries
- **Mitigations**:
  - Audit logging (`SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY`)
  - Read-only roles for analysts (`SELECT` only, no `INSERT/UPDATE/DELETE`)
  - Parameterized queries (no dynamic SQL with user input)
  - Version control for dbt models (Git audit trail)

**Repudiation Threats**:
- User deletes sensitive data and claims they didn't
- Admin changes permissions without audit trail
- **Mitigations**:
  - Immutable audit logs (`ACCOUNT_USAGE` views with 1-year retention)
  - CloudTrail logging for AWS KMS key access
  - Snowflake access history for table-level auditing

**Information Disclosure Threats**:
- PII exposed to unauthorized users (email, phone, SSN)
- Financial data accessible by non-finance teams
- **Mitigations**:
  - Data masking policies for PII columns
  - RBAC with least privilege (finance analysts can't see operations data)
  - Encryption at-rest (Tri-Secret Secure with AWS KMS)
  - TLS 1.2+ for all data in transit

**Denial of Service Threats**:
- Runaway query consumes all warehouse credits
- Attacker floods API with authentication attempts
- **Mitigations**:
  - Resource monitors with credit quotas (suspend at 90%)
  - Query timeout limits (max 1 hour)
  - Statement timeout (30 minutes for long-running queries)
  - Rate limiting on Snowflake API endpoints

**Elevation of Privilege Threats**:
- Analyst grants themselves `SYSADMIN` role
- SQL injection escalates to `ACCOUNTADMIN`
- **Mitigations**:
  - Role grants audited (`SHOW GRANTS` reviewed quarterly)
  - `BLOCKED_ROLES_LIST` in OAuth integration (prevent ACCOUNTADMIN via OAuth)
  - Separation of duties (grant/revoke requires SECURITYADMIN)

#### Component: Metabase BI Platform

**Spoofing**: Attacker impersonates executive to view sensitive dashboards
- **Mitigation**: SAML SSO with Okta, MFA required

**Tampering**: Attacker modifies dashboard query to return unauthorized data
- **Mitigation**: Dashboard queries stored in PostgreSQL with audit log, version control

**Repudiation**: User claims they didn't access PII dashboard
- **Mitigation**: Metabase audit log tracks all dashboard views

**Information Disclosure**: Public dashboard link exposes sensitive financial data
- **Mitigation**: Dashboard collections require authentication, no public links for sensitive data

**Denial of Service**: Complex query locks Snowflake warehouse
- **Mitigation**: Query timeout (10 minutes), warehouse auto-suspend after 5 minutes idle

**Elevation of Privilege**: Analyst grants themselves "Data Engineer" permissions
- **Mitigation**: Group membership managed by Okta (not Metabase), SSO group sync

## Attack Trees

Attack trees model the paths an attacker might take to compromise a system.

### Example: Unauthorized Access to Snowflake Production Data

```
Goal: Access sensitive financial data in PROD.FINANCE schema

OR
├── [1] Compromise User Credentials
│   OR
│   ├── [1.1] Phishing attack (steal username/password)
│   │   ├── Mitigation: Security awareness training, email filtering
│   ├── [1.2] Credential stuffing (reused passwords from data breach)
│   │   ├── Mitigation: MFA required, password complexity requirements
│   ├── [1.3] Keylogger malware on employee laptop
│   │   ├── Mitigation: Endpoint protection (antivirus, EDR), device encryption
│
├── [2] Exploit Service Account
│   OR
│   ├── [2.1] API key leaked in GitHub repository
│   │   ├── Mitigation: GitHub secret scanning, Secrets Manager, .gitignore
│   ├── [2.2] Service account credentials in plaintext config file
│   │   ├── Mitigation: Environment variables, Vault, never hardcode secrets
│   ├── [2.3] Stolen OAuth refresh token (no expiration)
│   │   ├── Mitigation: Refresh token rotation, 24-hour validity
│
├── [3] SQL Injection
│   OR
│   ├── [3.1] Inject malicious SQL in Metabase custom query
│   │   ├── Mitigation: Parameterized queries, input validation
│   ├── [3.2] Inject SQL in dbt macro (dynamic SQL)
│   │   ├── Mitigation: Code review, SQLFluff linting, avoid dynamic SQL
│
└── [4] Insider Threat
    OR
    ├── [4.1] Employee with legitimate access exfiltrates data
    │   ├── Mitigation: Audit logging, DLP (Data Loss Prevention), access reviews
    ├── [4.2] Contractor escalates privileges (ANALYST → SYSADMIN)
    │   ├── Mitigation: Quarterly access reviews, time-bound access, separation of duties
```

## Risk Assessment

### Risk Calculation
**Risk Score = Likelihood × Impact**

**Likelihood Scale (1-5)**:
- 1 = Rare (once every 5+ years)
- 2 = Unlikely (once every 2-5 years)
- 3 = Possible (once every 1-2 years)
- 4 = Likely (once every 6-12 months)
- 5 = Almost Certain (multiple times per year)

**Impact Scale (1-5)**:
- 1 = Negligible (no data loss, <1 hour downtime)
- 2 = Minor (limited data exposure, <4 hours downtime)
- 3 = Moderate (PII exposure for <100 users, <1 day downtime)
- 4 = Major (PII exposure for >100 users, financial impact $10k-$100k)
- 5 = Catastrophic (complete data breach, financial impact >$100k, regulatory fines)

### Risk Matrix Example

| Threat | Likelihood | Impact | Risk Score | Priority | Mitigation Status |
|--------|------------|--------|------------|----------|-------------------|
| Phishing attack (steal credentials) | 4 | 4 | 16 | High | ✅ MFA enforced, security training |
| API key leaked in GitHub | 3 | 5 | 15 | High | ✅ Secret scanning, Secrets Manager |
| SQL injection in Metabase | 2 | 5 | 10 | Medium | ✅ Parameterized queries, input validation |
| Runaway query (DoS) | 4 | 2 | 8 | Medium | ✅ Resource monitors, query timeouts |
| Insider threat (data exfiltration) | 2 | 4 | 8 | Medium | ⚠️ Audit logging (need DLP solution) |
| TLS downgrade attack | 1 | 4 | 4 | Low | ✅ TLS 1.2+ enforced, HSTS enabled |

**Priority Levels**:
- **Critical** (Risk Score 20-25): Immediate action required (within 24 hours)
- **High** (Risk Score 12-19): Address within 1 week
- **Medium** (Risk Score 6-11): Address within 1 month
- **Low** (Risk Score 1-5): Address within 3 months or accept risk

## Threat Modeling for Common Scenarios

### Scenario 1: New dbt Model with PII
**Question**: "We're creating a new dbt model that joins user PII (email, phone) with financial transactions. What security controls are needed?"

**Threat Model**:
1. **Information Disclosure**: PII accessible to unauthorized users
   - **Mitigation**: Model placed in `PROD.FINANCE` schema with `FINANCE_ANALYST` role required
   - **Mitigation**: Data masking policy on email/phone columns
   - **Mitigation**: Tag model with `access:restricted` in dbt

2. **Elevation of Privilege**: Analyst grants themselves access to PII
   - **Mitigation**: Role grants audited quarterly, separation of duties (SECURITYADMIN required)

3. **Repudiation**: User accesses PII and claims they didn't
   - **Mitigation**: `ACCOUNT_USAGE.ACCESS_HISTORY` tracks all table access with user/role/timestamp

### Scenario 2: Metabase Dashboard for Executives
**Question**: "Executives need a dashboard with real-time revenue data. How do we secure it?"

**Threat Model**:
1. **Spoofing**: Attacker impersonates executive to view dashboard
   - **Mitigation**: SAML SSO with Okta, MFA required, executive group membership

2. **Information Disclosure**: Dashboard link shared externally
   - **Mitigation**: Dashboard in "Executive" collection (not public), view-only permissions

3. **Tampering**: Attacker modifies dashboard query to expose more data
   - **Mitigation**: Executives have "No self-service" permissions (cannot edit queries)

4. **Denial of Service**: Complex dashboard query locks warehouse
   - **Mitigation**: Use pre-aggregated mart table (`MART_DAILY_REVENUE`), query timeout 10 minutes

### Scenario 3: Airbyte Integration with Third-Party API
**Question**: "We're syncing data from Stripe API to Snowflake via Airbyte. What are the security risks?"

**Threat Model**:
1. **Spoofing**: Attacker impersonates Airbyte to access Stripe API
   - **Mitigation**: Stripe API key stored in AWS Secrets Manager, rotated every 90 days

2. **Information Disclosure**: Stripe data (credit card info) exposed in logs
   - **Mitigation**: Airbyte logs redact sensitive fields, CloudWatch encryption at-rest

3. **Tampering**: Man-in-the-middle attack intercepts Stripe data
   - **Mitigation**: TLS 1.2+ enforced for Stripe API, certificate validation enabled

4. **Denial of Service**: Airbyte sync overwhelms Snowflake warehouse
   - **Mitigation**: Airbyte uses dedicated `LOADING` warehouse with resource monitor

## Threat Modeling Tools

### Microsoft Threat Modeling Tool
- Visual diagramming for architecture
- Built-in STRIDE threat library
- Generates threat report with mitigations

### OWASP Threat Dragon
- Open-source web-based tool
- STRIDE and other methodologies
- Integrates with GitHub for version control

### Manual Threat Modeling Template
```markdown
# Threat Model: [Component Name]

## Architecture Diagram
[Insert diagram showing data flows, trust boundaries, entry points]

## Assets
- What data/systems are we protecting?
- What is the business impact if compromised?

## Threats (STRIDE)
| Threat Category | Threat Description | Likelihood | Impact | Risk | Mitigation |
|-----------------|--------------------|-----------| -------|------|------------|
| Spoofing | ... | ... | ... | ... | ... |
| Tampering | ... | ... | ... | ... | ... |
| Repudiation | ... | ... | ... | ... | ... |
| Information Disclosure | ... | ... | ... | ... | ... |
| Denial of Service | ... | ... | ... | ... | ... |
| Elevation of Privilege | ... | ... | ... | ... | ... |

## Assumptions
- What security controls are already in place?
- What is out of scope?

## Recommendations
- High priority security controls to implement
- Acceptance of low-risk threats
```

## Further Reading

- [STRIDE Threat Modeling (Microsoft)](https://learn.microsoft.com/en-us/azure/security/develop/threat-modeling-tool-threats)
- [OWASP Threat Modeling](https://owasp.org/www-community/Threat_Modeling)
- [Attack Trees (Bruce Schneier)](https://www.schneier.com/academic/archives/1999/12/attack_trees.html)
- [NIST Risk Management Framework](https://csrc.nist.gov/projects/risk-management/about-rmf)
