---
title: "Compliance Frameworks Overview"
description: "GDPR, CCPA, SOC2, and HIPAA requirements for data governance"
category: "core-concepts"
tags:
  - compliance
  - gdpr
  - ccpa
  - soc2
  - hipaa
  - regulations
last_updated: "2025-10-07"
---

# Compliance Frameworks Overview

## GDPR (General Data Protection Regulation)

### Scope and Applicability

**Geographic Scope**:
- Applies to organizations processing data of EU residents
- Applies regardless of where the organization is located
- Triggered by offering goods/services to EU or monitoring EU residents

**Territorial Application for Splash Sports**:
- If Splash has EU users → GDPR applies
- If Splash monitors EU user behavior → GDPR applies
- Even if servers are in US, EU data subject rights must be honored

### Core Principles

**1. Lawfulness, Fairness, Transparency**
- Must have lawful basis for processing (consent, contract, legal obligation, vital interests, public task, legitimate interest)
- Users must understand how their data is used
- Privacy policies must be clear and accessible

**2. Purpose Limitation**
- Data collected for specific, explicit, legitimate purposes
- Cannot reuse data for incompatible purposes without new consent
- Analytics use case must be disclosed at collection time

**3. Data Minimization**
- Only collect data that is necessary for the purpose
- Avoid "nice to have" data collection
- Regularly review and purge unnecessary data

**4. Accuracy**
- Keep personal data accurate and up-to-date
- Provide mechanisms for users to correct inaccuracies
- Implement data quality checks

**5. Storage Limitation**
- Retain data only as long as necessary for the purpose
- Define retention periods for each data category
- Implement automated deletion workflows

**6. Integrity and Confidentiality**
- Protect data against unauthorized access, loss, or damage
- Encryption, access controls, audit trails
- Regular security assessments

**7. Accountability**
- Demonstrate compliance with all principles
- Maintain documentation, policies, and records of processing
- Appoint Data Protection Officer (DPO) if required

### Data Subject Rights

**1. Right to Access (Art. 15)**
- Users can request copy of their personal data
- Must provide within 1 month (extendable to 3 months)
- Free of charge for first request

**Implementation**:
```sql
-- Generate user data export
select
    user_id,
    email,
    phone,
    created_at,
    last_login_at,
    account_status,
    marketing_consent,
    analytics_consent
from prod.finance.dim_user
where user_id = :user_id;

-- Include all related transaction data
select * from prod.finance.fct_wallet_transactions where user_id = :user_id;
select * from prod.contests.fct_contest_entries where user_id = :user_id;
```

**2. Right to Rectification (Art. 16)**
- Users can request correction of inaccurate data
- Must update within 1 month

**3. Right to Erasure / "Right to be Forgotten" (Art. 17)**
- Users can request deletion of their data
- Exceptions: legal obligations, public interest, legitimate interests
- Must delete within 1 month

**Implementation Considerations**:
- Cascade deletes across fact tables (transactions, events)
- Preserve audit trails (log deletion, retain anonymized aggregates)
- Notify downstream processors (third-party partners)

**4. Right to Restrict Processing (Art. 18)**
- Users can request suspension of processing
- Data can be stored but not processed
- Use case: Dispute over data accuracy

**5. Right to Data Portability (Art. 20)**
- Users can request data in machine-readable format (JSON, CSV)
- Must support transfer to another controller

**6. Right to Object (Art. 21)**
- Users can object to processing based on legitimate interest
- Absolute right to object to direct marketing

**7. Rights Related to Automated Decision-Making (Art. 22)**
- Users can opt-out of fully automated decisions with legal/significant effect
- Example: AI-based credit scoring, fraud detection

### Compliance Obligations

**Data Protection Impact Assessment (DPIA)** (Art. 35):
- Required for high-risk processing (large-scale sensitive data, systematic monitoring, automated decision-making)
- Assess risks to data subjects, mitigation measures
- Consult supervisory authority if high residual risk

**Data Breach Notification** (Art. 33-34):
- Notify supervisory authority within 72 hours of becoming aware
- Notify affected individuals if high risk to rights and freedoms
- Document all breaches (even if not reported)

**Records of Processing Activities** (Art. 30):
- Maintain register of all processing activities
- Include: purposes, categories of data, recipients, retention periods, security measures

**Data Protection Officer (DPO)** (Art. 37):
- Required for public authorities or large-scale monitoring/sensitive data
- Independent oversight, advises on compliance

### Penalties

- **Tier 1**: Up to €10 million or 2% of global annual turnover (whichever is higher)
- **Tier 2**: Up to €20 million or 4% of global annual turnover (for serious violations)

---

## CCPA (California Consumer Privacy Act)

### Scope and Applicability

**Thresholds (any one triggers CCPA)**:
1. Annual gross revenue > $25 million
2. Buy, sell, or share personal information of 100,000+ California residents/households
3. Derive 50%+ of annual revenue from selling personal information

**Definition of "Sale"**:
- Sharing personal information for monetary or other valuable consideration
- Includes data sharing with advertising partners (even without direct payment)

### Consumer Rights

**1. Right to Know**
- What personal information is collected
- Categories of sources
- Business/commercial purposes for collection
- Categories of third parties with whom data is shared

**2. Right to Delete**
- Request deletion of personal information
- Exceptions: complete transaction, detect fraud, comply with legal obligations

**3. Right to Opt-Out of Sale**
- Must provide "Do Not Sell My Personal Information" link
- Cannot discriminate against users who opt-out

**4. Right to Non-Discrimination**
- Cannot deny goods/services for exercising CCPA rights
- Cannot charge different prices or provide different quality

**5. Right to Limit Use of Sensitive Personal Information** (CPRA amendment):
- Sensitive categories: SSN, financial account, precise geolocation, health data, biometrics, etc.

### Business Obligations

**Privacy Policy Requirements**:
- List categories of personal information collected
- Describe how to exercise consumer rights
- Include 12-month lookback period for disclosures

**Verifiable Consumer Requests**:
- Implement process to verify identity for data requests
- Respond within 45 days (extendable to 90 days)
- Toll-free number or online mechanism required

**Do Not Sell Opt-Out**:
- Prominent link on homepage
- No opt-in required for users under 16 (COPPA alignment)

**Service Provider Agreements**:
- Contracts must prohibit data use beyond specified purposes
- Regular audits of service provider compliance

### CPRA (California Privacy Rights Act) Enhancements (2023)

- Created California Privacy Protection Agency (enforcement)
- New category: "Sensitive Personal Information" with enhanced protections
- Right to correction (not just deletion)
- Stronger opt-out for automated decision-making

---

## SOC2 (Service Organization Control 2)

### Trust Services Criteria

**1. Security**
- Protect against unauthorized access (logical and physical)
- Access controls, authentication, encryption
- Network security, firewalls, intrusion detection

**2. Availability**
- System available for operation and use as committed
- Uptime SLAs, redundancy, disaster recovery
- Monitoring and incident response

**3. Processing Integrity**
- System processing is complete, valid, accurate, timely
- Data validation, error handling, reconciliation
- Change management and version control

**4. Confidentiality**
- Information designated as confidential is protected
- Data classification, encryption, access controls
- NDA enforcement, secure data disposal

**5. Privacy**
- Personal information collected, used, retained, disclosed per commitments
- Notice, choice, access, retention, disclosure practices
- Monitoring and enforcement of privacy policies

### SOC2 Types

**Type I**: Design of controls at a point in time
- Auditor evaluates control design on a specific date
- Less comprehensive, faster to achieve

**Type II**: Operating effectiveness over time (6-12 months)
- Auditor evaluates controls over extended period
- More rigorous, demonstrates sustained compliance
- Preferred by enterprise customers

### Key Controls for Data Warehouse

**Access Controls**:
- Role-based access control (RBAC) for Snowflake
- Multi-factor authentication (MFA) for privileged accounts
- Quarterly access reviews and recertification
- Principle of least privilege

**Change Management**:
- All schema changes via pull requests with approval
- Automated testing in CI/CD pipeline (dbt tests)
- Rollback procedures for failed deployments
- Change log and audit trail

**Data Backup and Recovery**:
- Snowflake Time Travel (1-90 days retention)
- Fail-safe period (7 days after Time Travel)
- Disaster recovery plan with RTO/RPO targets
- Regular restore testing

**Monitoring and Logging**:
- Snowflake query history for all SQL execution
- Access history for sensitive table access
- Alerting for anomalous behavior (unusual data access, failed logins)
- Log retention per compliance requirements

**Vendor Management**:
- SOC2 reports from third-party vendors (Fivetran, Airbyte, dbt Cloud)
- Regular security assessments of vendors
- Data processing agreements (DPAs)

---

## HIPAA (Health Insurance Portability and Accountability Act)

**Note**: Only applicable if Splash processes Protected Health Information (PHI).

### Protected Health Information (PHI)

**18 HIPAA Identifiers**:
1. Names
2. Geographic subdivisions smaller than state
3. Dates (birth, admission, discharge, death) - except year
4. Telephone numbers
5. Fax numbers
6. Email addresses
7. Social Security numbers
8. Medical record numbers
9. Health plan beneficiary numbers
10. Account numbers
11. Certificate/license numbers
12. Vehicle identifiers
13. Device identifiers/serial numbers
14. Web URLs
15. IP addresses
16. Biometric identifiers (fingerprints, retina scans)
17. Full-face photos
18. Any other unique identifying characteristic

### De-Identification Methods

**Safe Harbor Method**:
- Remove all 18 identifiers
- No actual knowledge that residual information can re-identify

**Expert Determination Method**:
- Statistical/scientific analysis by qualified expert
- Very small risk of re-identification

### HIPAA Security Rule

**Administrative Safeguards**:
- Security management process
- Workforce security (authorization, clearance)
- Information access management
- Security awareness training
- Contingency planning (backup, disaster recovery)

**Physical Safeguards**:
- Facility access controls
- Workstation use policies
- Device and media controls

**Technical Safeguards**:
- Access controls (unique user IDs, encryption)
- Audit controls (log all PHI access)
- Integrity controls (prevent unauthorized alteration)
- Transmission security (encryption for PHI in transit)

### Business Associate Agreements (BAA)

**Required Elements**:
- Permitted uses and disclosures of PHI
- Safeguards to protect PHI
- Reporting obligations for breaches
- Return or destruction of PHI upon termination

**Splash Context**:
- If Splash stores health data (e.g., fitness tracking integration), BAAs required with cloud providers (Snowflake, AWS)

---

## Compliance Decision Matrix for Splash Sports

| Regulation | Applicability | Likelihood | Priority | Rationale |
|------------|---------------|------------|----------|-----------|
| **GDPR** | High | High | **Critical** | If any EU users exist, GDPR applies. Global standard. |
| **CCPA** | High | Medium | **High** | California users common in sports betting. CPRA strengthens. |
| **SOC2** | Medium | High | **High** | Enterprise customers expect SOC2 Type II certification. |
| **HIPAA** | Low | Low | **Low** | Only if integrating health/fitness data (wearables, etc.). |

### Recommended Implementation Order

**Phase 1: Foundation (Months 1-3)**
- Data classification and PII inventory
- Snowflake RBAC and access controls
- Basic audit logging (query history, access history)

**Phase 2: GDPR/CCPA Compliance (Months 3-6)**
- Data subject request workflows (access, deletion, portability)
- Consent management system
- Privacy policy updates
- Retention policy implementation

**Phase 3: SOC2 Preparation (Months 6-12)**
- Control documentation and evidence collection
- Change management formalization
- Backup/recovery testing
- Vendor management program

**Phase 4: Continuous Compliance (Ongoing)**
- Quarterly access reviews
- Annual privacy impact assessments
- Regular penetration testing
- Compliance monitoring dashboards

---

## Cross-Framework Synergies

Many controls satisfy multiple frameworks:

| Control | GDPR | CCPA | SOC2 | HIPAA |
|---------|------|------|------|-------|
| **Data Encryption** | ✓ (Security) | ✓ (Security) | ✓ (Security, Confidentiality) | ✓ (Encryption) |
| **Access Controls** | ✓ (Integrity) | ✓ (Security) | ✓ (Security) | ✓ (Access Control) |
| **Audit Logging** | ✓ (Accountability) | ✓ (Transparency) | ✓ (Security) | ✓ (Audit Controls) |
| **Data Retention** | ✓ (Storage Limitation) | ✓ (Deletion Rights) | ✓ (Privacy) | ✓ (Retention) |
| **Breach Notification** | ✓ (72 hours) | ✓ (Notification) | ✓ (Incident Response) | ✓ (Breach Notification) |

**Efficiency Strategy**: Implement once, satisfy multiple frameworks through comprehensive documentation and mapping.

---

## Next Steps for Implementation

1. **Read**: `data-classification.md` for taxonomy and PII field catalog
2. **Read**: `audit-trail-architecture.md` for logging implementation
3. **Read**: `privacy-engineering.md` for PIA process and privacy-by-design
4. **Implement**: Start with data classification and access controls (foundational)
5. **Coordinate**: Work with security-engineer for encryption, architect for schema design
