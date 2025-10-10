---
name: compliance-check
description: Validate GDPR, CCPA, SOC2, and HIPAA compliance with automated audit trail verification and gap analysis
model: claude-opus-4-20250514
type: global
args:
  framework:
    description: Compliance framework to validate (GDPR, CCPA, SOC2, HIPAA, or ALL)
    required: false
    default: ALL
  scope:
    description: Domain scope to audit (finance, contests, partners, shared, or all)
    required: false
    default: all
  comprehensive:
    description: Run comprehensive audit with full DSR testing and penetration checks
    required: false
    default: false
---

# Compliance Validation & Audit Command

**Purpose**: GDPR/CCPA/SOC2/HIPAA compliance validation with automated audit trail verification and gap analysis

**Model**: `opus` (regulatory compliance requires precision and thoroughness)

## Overview

Validate regulatory compliance across:
1. **GDPR** (General Data Protection Regulation) - EU data privacy
2. **CCPA** (California Consumer Privacy Act) - California data privacy
3. **SOC 2 Type II** (Security & Availability) - Trust service criteria
4. **HIPAA** (Health Insurance Portability and Accountability Act) - Healthcare data protection

Includes:
- Data classification verification
- PII detection and handling validation
- Audit trail completeness
- Data subject rights implementation
- Compliance gap analysis and remediation roadmap

## Usage

```bash
# Full compliance audit across all frameworks
/compliance-check

# GDPR audit only
/compliance-check --framework GDPR

# Finance domain SOC2 audit
/compliance-check --framework SOC2 --scope finance

# Comprehensive GDPR audit with DSR testing
/compliance-check --framework GDPR --comprehensive
```

## Compliance Frameworks

### GDPR (General Data Protection Regulation)

**Key Articles**:
- **Article 6**: Lawful basis for processing (consent, contract, legal obligation)
- **Article 15**: Right of access (data subject requests)
- **Article 17**: Right to erasure ("right to be forgotten")
- **Article 25**: Privacy by design and default
- **Article 30**: Records of processing activities
- **Article 32**: Security of processing (encryption, pseudonymization)
- **Article 33**: Breach notification (72-hour requirement)
- **Article 35**: Data protection impact assessments (DPIA)

**Penalties**: Up to €20M or 4% of global annual revenue

### CCPA (California Consumer Privacy Act)

**Consumer Rights**:
- **Right to Know**: What personal information is collected and how it's used
- **Right to Delete**: Request deletion of personal information
- **Right to Opt-Out**: Opt-out of sale of personal information
- **Right to Non-Discrimination**: No penalty for exercising privacy rights

**Requirements**:
- Privacy notice at collection
- 12-month lookback for data access requests
- 45-day response window for consumer requests

**Penalties**: Up to $7,500 per intentional violation

### SOC 2 Type II

**Trust Service Criteria**:
- **Security (CC6)**: Logical and physical access controls
  - CC6.1: Access controls
  - CC6.6: Encryption of data at rest and in transit
  - CC6.7: Data retention and disposal
  - CC7.2: System monitoring and incident response
- **Availability**: System uptime and reliability
- **Processing Integrity**: Complete, accurate, timely processing
- **Confidentiality**: Designated confidential information protected
- **Privacy**: Personal information handled per privacy notice

**Audit Period**: Minimum 6 months of operational evidence

### HIPAA (Health Insurance Portability and Accountability Act)

**Applicable if handling Protected Health Information (PHI)**:
- **Privacy Rule**: PHI use and disclosure restrictions
- **Security Rule**: Administrative, physical, technical safeguards
- **Breach Notification Rule**: 60-day notification requirement

**Requirements**:
- Business Associate Agreements (BAAs)
- Risk assessments
- Encryption of PHI at rest and in transit
- Access controls and audit logs

## Workflow

### Phase 1: Data Discovery & Classification

**Step 1: Invoke Security Engineer Agent**
```yaml
Task:
  subagent_type: security-engineer
  prompt: |
    Conduct comprehensive data discovery and classification scan:

    1. Scan all Snowflake schemas in scope (${scope})
    2. Identify PII fields using pattern matching:
       - Email addresses (regex: /\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b/)
       - Phone numbers (regex: /\b\d{3}[-.]?\d{3}[-.]?\d{4}\b/)
       - SSN (regex: /\b\d{3}-\d{2}-\d{4}\b/)
       - Credit card numbers (Luhn algorithm)
       - IP addresses
       - Physical addresses
       - Date of birth
    3. Verify data classification tags in dbt models:
       - Check for `access:restricted` tags
       - Validate `pii:true` metadata
    4. Check Snowflake Dynamic Data Masking policies:
       - Query INFORMATION_SCHEMA.MASKING_POLICIES
       - Verify policies applied to PII columns
    5. Generate PII inventory report with:
       - Table name, column name, PII type, masking status
       - Data volume estimates
       - Access control validation
```

**Step 2: Generate PII Inventory**
```yaml
Expected_Output:
  PII_Inventory:
    Total_PII_Fields: 47
    Tables_With_PII: 23
    Classifications:
      - pii_type: email
        occurrences: 12
        tables: [stg_users, dim_user, fct_registrations, ...]
        masked: true
      - pii_type: phone_number
        occurrences: 8
        tables: [stg_users, dim_user, ...]
        masked: true
      - pii_type: payment_info
        occurrences: 5
        tables: [fct_wallet_transactions, dim_payment_method, ...]
        masked: true
        encrypted: true
      - pii_type: ssn
        occurrences: 2
        tables: [stg_kyc_data, dim_user_identity, ...]
        masked: true
        encrypted: true
        access_restricted: true
```

### Phase 2: Framework-Specific Compliance Validation

#### GDPR Validation

**Step 1: Lawful Basis Verification (Article 6)**
```yaml
Task:
  subagent_type: data-governance
  prompt: |
    Validate lawful basis for each data source:

    1. Check dbt source metadata for lawful_basis field
    2. Verify one of six legal bases documented:
       - Consent (user opt-in)
       - Contract (necessary for service delivery)
       - Legal obligation (regulatory requirement)
       - Vital interests (life/death situations)
       - Public task (official authority)
       - Legitimate interests (business need with privacy assessment)
    3. Validate consent management:
       - Is consent freely given, specific, informed, unambiguous?
       - Can users withdraw consent easily?
       - Is consent tracked with timestamp and version?
    4. Generate lawful basis compliance matrix
```

**Step 2: Privacy Rights Implementation (Articles 15, 17, 20)**
```yaml
Task:
  subagent_type: security-engineer
  prompt: |
    Test GDPR data subject rights implementation:

    RIGHT OF ACCESS (Article 15):
    1. Simulate data subject access request (DSAR)
    2. Query all tables for test user_id: 'test_gdpr_user_123'
    3. Verify can retrieve:
       - All personal data
       - Processing purposes
       - Data recipients
       - Retention periods
       - Right to lodge complaint
    4. Measure response time (must be < 30 days)

    RIGHT TO ERASURE (Article 17):
    1. Check for user deletion workflow in dbt
    2. Verify cascading deletes across all tables
    3. Test deletion execution:
       - Hard delete vs. soft delete (flag)
       - Backup retention policies
       - Audit trail preservation
    4. Validate exceptions (legal obligation, public interest)

    RIGHT TO PORTABILITY (Article 20):
    1. Check for data export functionality
    2. Verify machine-readable format (JSON, CSV)
    3. Test export completeness
```

**Step 3: Security Controls (Article 32)**
```yaml
Task:
  subagent_type: security-engineer
  prompt: |
    Validate technical and organizational security measures:

    ENCRYPTION:
    1. Verify Snowflake encryption at-rest enabled
       - Query: SHOW PARAMETERS LIKE 'ENCRYPTION' IN ACCOUNT;
    2. Verify TLS 1.2+ for data in-transit
       - Check Snowflake connection settings
       - Verify Airbyte/Fivetran use HTTPS
    3. Check key rotation policies
       - Snowflake automatic key rotation enabled
       - Customer-managed keys (BYOK) if applicable

    PSEUDONYMIZATION:
    1. Check for tokenization/hashing of identifiers
    2. Verify can re-identify when necessary (legal obligation)

    ACCESS CONTROLS:
    1. Verify RBAC implementation in Snowflake
    2. Check principle of least privilege
    3. Validate MFA enforcement for admin accounts
```

**Step 4: Breach Notification (Article 33)**
```yaml
Task:
  subagent_type: security-engineer
  prompt: |
    Verify breach notification readiness:

    1. Check incident response plan exists and is tested
    2. Verify 72-hour notification procedure documented
    3. Validate breach detection capabilities:
       - Snowflake audit log monitoring
       - Failed login alerts
       - Unusual data access patterns
    4. Check DPA (Data Protection Authority) contact info updated
```

#### CCPA Validation

**Step 1: Consumer Rights Verification**
```yaml
Task:
  subagent_type: data-governance
  prompt: |
    Validate CCPA consumer rights implementation:

    RIGHT TO KNOW:
    1. Verify privacy notice at collection
    2. Check disclosure of:
       - Categories of personal information collected
       - Business/commercial purposes for collection
       - Categories of third parties data shared with
    3. Validate 12-month lookback capability

    RIGHT TO DELETE:
    1. Test consumer deletion request workflow
    2. Verify 45-day response window tracking
    3. Check exceptions documented (legal obligation)

    RIGHT TO OPT-OUT:
    1. Check "Do Not Sell My Personal Information" link
    2. Verify opt-out mechanism functional
    3. Validate no sale of personal information after opt-out

    NON-DISCRIMINATION:
    1. Verify no penalty for exercising rights
    2. Check no differential pricing/service quality
```

#### SOC 2 Type II Validation

**Step 1: Security Controls (CC6)**
```yaml
Task:
  subagent_type: security-engineer
  prompt: |
    Validate SOC 2 security trust service criteria:

    CC6.1 - LOGICAL AND PHYSICAL ACCESS CONTROLS:
    1. Check Snowflake role-based access control (RBAC)
       - Query: SHOW GRANTS TO USER <username>;
    2. Verify MFA enforcement
       - Query: SHOW PARAMETERS LIKE 'MFA' IN ACCOUNT;
    3. Validate access reviews conducted quarterly
    4. Check physical security for data centers (Snowflake SOC 2 report)

    CC6.6 - ENCRYPTION:
    1. Verify encryption at-rest (Snowflake default)
    2. Verify encryption in-transit (TLS 1.2+)
    3. Check key management (automatic rotation)

    CC6.7 - DATA RETENTION AND DISPOSAL:
    1. Verify data retention policies documented
    2. Check secure deletion procedures
    3. Validate backup retention limits

    CC7.2 - SYSTEM MONITORING:
    1. Check audit logging enabled
       - Snowflake: ACCOUNT_USAGE schema populated
       - Metabase: Audit logs enabled
       - Airbyte: Sync logs retained
    2. Verify monitoring and alerting configured
    3. Check incident response playbooks exist
```

**Step 2: Organizational Controls**
```yaml
Task:
  subagent_type: data-governance
  prompt: |
    Validate SOC 2 organizational controls:

    1. SECURITY POLICIES:
       - Information Security Policy documented
       - Acceptable Use Policy published
       - Data Classification Policy enforced
       - Last review date within 12 months

    2. EMPLOYEE ACCESS MANAGEMENT:
       - Onboarding checklist (access provisioning)
       - Offboarding checklist (access revocation)
       - Quarterly access reviews completed
       - Segregation of duties enforced

    3. VENDOR RISK MANAGEMENT:
       - Vendor security assessments (SOC 2 reports)
       - Business Associate Agreements (BAAs)
       - Vendor access monitoring

    4. INCIDENT RESPONSE:
       - Incident response plan documented
       - Tabletop exercises conducted annually
       - Breach notification procedures tested
```

### Phase 3: Audit Trail Verification

**Step 1: Audit Log Completeness Check**
```yaml
Task:
  subagent_type: security-engineer
  prompt: |
    Verify audit trail completeness and integrity:

    SNOWFLAKE AUDIT LOGS:
    1. Query ACCOUNT_USAGE.LOGIN_HISTORY
       - Verify captures all login attempts (success/failure)
       - Check timestamps, IP addresses, MFA status
    2. Query ACCOUNT_USAGE.QUERY_HISTORY
       - Verify captures all data access (SELECT, INSERT, UPDATE, DELETE)
       - Check user, role, query text, execution time
    3. Query ACCOUNT_USAGE.ACCESS_HISTORY
       - Verify captures object-level access (tables, views)
       - Validate column-level lineage (PII access tracking)
    4. Check retention period:
       - Default: 365 days for ACCOUNT_USAGE
       - Requirement: 12+ months for SOC 2

    METABASE AUDIT LOGS:
    1. Verify audit logging enabled (Settings > Admin > Audit)
    2. Check captures dashboard/question access
    3. Validate user activity tracking

    AIRBYTE/FIVETRAN LOGS:
    1. Verify sync logs retained
    2. Check error logs for data quality issues
    3. Validate data lineage tracking

    AUDIT LOG INTEGRITY:
    1. Check for tampering protection (append-only)
    2. Verify log export capability (compliance evidence)
    3. Test log search and filtering
```

**Step 2: Audit Log Retention Validation**
```yaml
SQL_Query: |
  -- Check Snowflake audit log retention
  SELECT
    table_name,
    MIN(start_time) AS oldest_record,
    MAX(start_time) AS newest_record,
    DATEDIFF(day, MIN(start_time), CURRENT_TIMESTAMP()) AS retention_days
  FROM snowflake.account_usage.query_history
  GROUP BY table_name
  HAVING retention_days < 365;  -- Flag if < 1 year

Expected:
  - All audit tables: 365+ days retention
  - If < 365 days: SOC 2 non-compliance
```

### Phase 4: Data Subject Rights Testing

**Step 1: Simulate GDPR Data Subject Access Request (DSAR)**
```yaml
Task:
  subagent_type: security-engineer
  prompt: |
    Execute end-to-end DSAR simulation:

    1. Create test user account:
       - user_id: 'compliance_test_user_${timestamp}'
       - email: 'gdpr.test@example.com'
       - Generate sample data across all domains

    2. Execute data subject access request:
       - Query all tables containing user_id
       - Retrieve personal data fields:
         * Identifiers (email, phone, user_id)
         * Profile data (name, address, DOB)
         * Behavioral data (contest entries, wallet transactions)
         * Technical data (IP addresses, device IDs)
       - Format as JSON export

    3. Validate completeness:
       - Cross-reference with PII inventory
       - Ensure no PII fields missed
       - Include metadata (processing purpose, retention period)

    4. Measure performance:
       - Query execution time
       - Data export generation time
       - Total response time (must be < 30 days, target < 24 hours)

    5. Cleanup test data
```

**Step 2: Simulate Right to Erasure**
```yaml
Task:
  subagent_type: security-engineer
  prompt: |
    Execute user deletion workflow:

    1. Identify all tables with user_id foreign key
       - Query INFORMATION_SCHEMA for FK relationships

    2. Execute deletion in dependency order:
       - Fact tables first (transactions, events)
       - Dimension tables last (dim_user)
       - Validate cascading deletes configured

    3. Verify deletion completeness:
       - Query all tables for user_id
       - Expect zero results

    4. Check audit trail preservation:
       - Deletion event logged with timestamp, user, reason
       - Cannot reverse deletion (GDPR requirement)

    5. Validate exceptions:
       - Legal hold (ongoing litigation)
       - Regulatory retention (tax records: 7 years)
       - Legitimate business interest (fraud prevention)

    6. Measure deletion time:
       - Target: < 24 hours for non-exceptional cases
       - Maximum: 30 days (GDPR requirement)
```

**Step 3: Test Data Portability**
```yaml
Task:
  subagent_type: data-engineer
  prompt: |
    Validate data portability implementation:

    1. Execute data export for test user
    2. Verify machine-readable format:
       - JSON or CSV (structured data)
       - Include schema definitions
       - Human-readable field names
    3. Check export completeness:
       - All personal data included
       - No business logic/proprietary algorithms
    4. Validate export security:
       - Encrypted download link
       - Time-limited access (24-hour expiry)
       - Authentication required
```

### Phase 5: Gap Analysis & Remediation Planning

**Step 1: Compliance Gap Identification**
```yaml
Task:
  subagent_type: data-governance
  prompt: |
    Analyze compliance gaps across People, Process, Technology:

    PEOPLE GAPS:
    - Training: Are employees trained on data privacy?
    - Awareness: Do teams understand GDPR/CCPA requirements?
    - Accountability: Is there a designated Data Protection Officer (DPO)?

    PROCESS GAPS:
    - Policies: Are privacy policies documented and current?
    - Procedures: Are DSR workflows documented and tested?
    - Reviews: Are privacy impact assessments (PIAs) conducted?

    TECHNOLOGY GAPS:
    - Automation: Are DSRs automated or manual?
    - Controls: Are all PII fields masked/encrypted?
    - Monitoring: Is PII access monitored and alerted?
```

**Step 2: Risk Prioritization**
```yaml
Risk_Matrix:
  High_Priority_Gaps:
    - criteria: Regulatory violation + High likelihood + Severe penalty
    - examples:
      * Missing breach notification procedure (GDPR Article 33)
      * PII not encrypted at-rest (SOC 2 CC6.6)
      * No MFA for admin accounts (SOC 2 CC6.1)

  Medium_Priority_Gaps:
    - criteria: Compliance requirement + Manual process + Medium likelihood
    - examples:
      * Right to erasure not automated (GDPR Article 17)
      * Audit logs retention < 12 months (SOC 2)
      * No quarterly access reviews (SOC 2)

  Low_Priority_Gaps:
    - criteria: Best practice + Low likelihood + Minor impact
    - examples:
      * Privacy notice not updated in 12 months
      * Data retention policy not documented
      * No differential privacy for analytics
```

**Step 3: Remediation Roadmap**
```yaml
Remediation_Plan:
  Immediate_Actions:  # 0-30 days
    - action: "Extend Snowflake audit log retention to 365 days"
      owner: "DevOps Engineer"
      effort: "2 hours"
      impact: "SOC 2 compliance requirement"

    - action: "Enable MFA for all admin Snowflake accounts"
      owner: "Security Engineer"
      effort: "1 day"
      impact: "SOC 2 CC6.1 requirement"

    - action: "Document lawful basis for all data sources"
      owner: "Data Governance Lead"
      effort: "3 days"
      impact: "GDPR Article 6 requirement"

  Short_Term_Actions:  # 30-90 days
    - action: "Automate GDPR user deletion workflow in dbt"
      owner: "Data Engineer"
      effort: "2 weeks"
      impact: "Reduce DSAR response time from 7 days to < 24 hours"

    - action: "Implement deletion logging for all tables with PII"
      owner: "Data Engineer"
      effort: "1 week"
      impact: "Audit trail completeness"

    - action: "Conduct privacy impact assessment (PIA) for new data sources"
      owner: "Data Protection Officer"
      effort: "1 week per source"
      impact: "GDPR Article 35 requirement"

  Medium_Term_Actions:  # 90-180 days
    - action: "Build self-service data subject request portal"
      owner: "Product Manager + Engineering"
      effort: "6 weeks"
      impact: "Scale DSAR processing, reduce manual effort"

    - action: "Implement differential privacy for analytics dashboards"
      owner: "Data Scientist + BI Analyst"
      effort: "8 weeks"
      impact: "Privacy-preserving analytics, reduce PII exposure"

    - action: "Achieve SOC 2 Type II certification"
      owner: "Security Engineer + External Auditor"
      effort: "6 months"
      impact: "Customer trust, enterprise sales enablement"
```

## Output Format

```yaml
Compliance_Audit_Report:
  Metadata:
    Framework: ${framework}  # GDPR | CCPA | SOC2 | HIPAA | ALL
    Scope: ${scope}  # finance | contests | partners | shared | all
    Audit_Date: "2025-10-07"
    Auditor: "Claude Code (Opus)"
    Audit_Duration: "47 minutes"
    Overall_Compliance_Score: 85%  # Good (70-89%), Excellent (90-100%)

  Executive_Summary:
    Status: "GOOD"  # Excellent | Good | Needs Improvement | Non-Compliant
    Key_Findings:
      - "85% overall compliance across GDPR, CCPA, SOC 2"
      - "47 PII fields identified, 43 properly masked (91%)"
      - "Right to Erasure not fully automated (7-day manual process)"
      - "Audit log retention meets SOC 2 requirement (365+ days)"
    Critical_Gaps: 2
    High_Priority_Gaps: 4
    Medium_Priority_Gaps: 7
    Estimated_Remediation_Effort: "6 weeks"

  PII_Inventory:
    Total_PII_Fields: 47
    Tables_With_PII: 23
    Properly_Masked: 43 (91%)
    Unmasked_PII: 4  # ACTION REQUIRED
    Classifications:
      - pii_type: email
        occurrences: 12
        tables: [stg_users, dim_user, fct_registrations]
        masked: true
        encryption: false
        access_restricted: false
      - pii_type: phone_number
        occurrences: 8
        tables: [stg_users, dim_user, fct_kyc_verification]
        masked: true
        encryption: false
        access_restricted: false
      - pii_type: payment_info
        occurrences: 5
        tables: [fct_wallet_transactions, dim_payment_method]
        masked: true
        encryption: true  # Snowflake encryption at-rest
        access_restricted: true
      - pii_type: ssn
        occurrences: 2
        tables: [stg_kyc_data, dim_user_identity]
        masked: true
        encryption: true
        access_restricted: true
      - pii_type: ip_address
        occurrences: 16
        tables: [fct_page_views, fct_login_events]
        masked: false  # ⚠️ GAP IDENTIFIED
        encryption: false
        access_restricted: false
      - pii_type: device_id
        occurrences: 4
        tables: [fct_mobile_events, dim_device]
        masked: false  # ⚠️ GAP IDENTIFIED
        encryption: false
        access_restricted: false

  Framework_Compliance:
    GDPR:
      Overall: 82% (Good)
      Article_6_Lawful_Basis: ✅ PASS (100%)
        - status: "All sources have documented lawful basis"
        - lawful_bases:
          * Consent: User opt-in for marketing communications
          * Contract: Contest participation, wallet transactions
          * Legal Obligation: Tax reporting, AML compliance
      Article_15_Access_Rights: ✅ PASS (100%)
        - status: "Data subject access request functional"
        - response_time: "45 minutes (target < 24 hours)"
        - completeness: "All PII fields retrieved"
      Article_17_Erasure_Rights: ⚠️ PARTIAL (60%)
        - status: "Manual deletion process takes 7+ days"
        - gap: "Not automated, requires engineering effort"
        - recommendation: "Build automated user deletion workflow in dbt"
      Article_20_Portability: ✅ PASS (100%)
        - status: "JSON export available"
        - format: "Machine-readable, structured schema"
      Article_25_Privacy_by_Design: ✅ PASS (90%)
        - status: "Masking policies applied to most PII"
        - gap: "IP addresses and device IDs not masked"
      Article_30_Records_of_Processing: ⚠️ PARTIAL (70%)
        - status: "Processing activities documented"
        - gap: "Not maintained in centralized register"
      Article_32_Security: ✅ PASS (95%)
        - encryption_at_rest: true (Snowflake default)
        - encryption_in_transit: true (TLS 1.2+)
        - mfa_enforced: true (admin accounts)
        - key_rotation: true (automatic)
      Article_33_Breach_Notification: ✅ PASS (100%)
        - status: "Incident response plan documented and tested"
        - notification_procedure: "72-hour window tracked"
        - detection_capability: "Snowflake audit log monitoring + alerts"

    CCPA:
      Overall: 88% (Good)
      Right_to_Know: ✅ PASS (100%)
        - privacy_notice: "Published at collection"
        - disclosures: "Categories of PI, purposes, third parties documented"
        - lookback_capability: "12+ months of data retention"
      Right_to_Delete: ⚠️ PARTIAL (60%)
        - status: "Manual process, 7-day turnaround"
        - gap: "Not automated, same as GDPR Article 17"
      Right_to_Opt_Out: ✅ PASS (100%)
        - status: "Do Not Sell link available"
        - verification: "No sale of personal information confirmed"
      Non_Discrimination: ✅ PASS (100%)
        - status: "No penalty for exercising rights"
        - pricing: "No differential pricing/service quality"

    SOC2:
      Overall: 87% (Good)
      Security_CC6:
        CC6.1_Access_Controls: ⚠️ PARTIAL (80%)
          - rbac_implemented: true
          - mfa_enforced: true (admin only)
          - gap: "MFA not enforced for all users, only admins"
          - access_reviews: "Quarterly reviews conducted"
        CC6.6_Encryption: ✅ PASS (100%)
          - encryption_at_rest: true (Snowflake, S3)
          - encryption_in_transit: true (TLS 1.2+)
          - key_management: "Automatic rotation enabled"
        CC6.7_Retention_Disposal: ✅ PASS (95%)
          - retention_policies: "Documented for all data sources"
          - secure_deletion: "Procedures documented"
          - gap: "Backup retention not automated"
        CC7.2_Monitoring: ✅ PASS (90%)
          - audit_logging: true (Snowflake, Metabase, Airbyte)
          - retention: "365+ days (compliant)"
          - alerting: "Configured for failed logins, unusual access"
          - gap: "No SIEM integration for centralized monitoring"

      Availability: ✅ PASS (95%)
        - uptime_sla: "99.9% (Snowflake SLA)"
        - disaster_recovery: "Snowflake automatic failover"
        - backup_frequency: "Continuous (Snowflake Time Travel)"

      Processing_Integrity: ✅ PASS (88%)
        - dbt_tests: "1,247 data quality tests configured"
        - test_coverage: "82% of models have uniqueness/not_null tests"
        - gap: "No automated reconciliation for source → staging"

      Confidentiality: ⚠️ PARTIAL (75%)
        - data_classification: "Implemented via dbt tags"
        - access_controls: "RBAC enforced"
        - gap: "No DLP (Data Loss Prevention) for data exfiltration"

      Privacy: ✅ PASS (85%)
        - privacy_notice: "Published and up-to-date"
        - consent_management: "Opt-in tracked with timestamp"
        - gap: "No privacy impact assessments (PIAs) for new data sources"

  Audit_Trail_Validation:
    Snowflake:
      LOGIN_HISTORY:
        status: ✅ COMPLETE
        retention_days: 412
        records_count: 47823
        coverage: "All login attempts (success/failure)"
      QUERY_HISTORY:
        status: ✅ COMPLETE
        retention_days: 398
        records_count: 1283947
        coverage: "All SQL queries (SELECT, INSERT, UPDATE, DELETE)"
      ACCESS_HISTORY:
        status: ✅ COMPLETE
        retention_days: 387
        records_count: 892374
        coverage: "Object-level and column-level access"
      RETENTION_COMPLIANCE:
        soc2_requirement: 365 days
        actual_retention: 387 days
        compliant: true

    Metabase:
      audit_logging_enabled: true
      coverage: "Dashboard/question access, user activity"
      retention_days: 180
      gap: "Retention < 365 days (SOC 2 requirement)"

    Airbyte_Fivetran:
      sync_logs_retained: true
      error_logs_available: true
      retention_days: 90
      gap: "Retention < 365 days (SOC 2 requirement)"

  DSR_Test_Results:
    GDPR_Right_of_Access:
      status: ✅ PASS
      test_user_id: "compliance_test_user_1728345678"
      records_retrieved: 247
      tables_queried: 23
      export_format: "JSON (machine-readable)"
      response_time: "45 minutes"
      completeness: "100% (all PII fields retrieved)"

    GDPR_Right_to_Erasure:
      status: ⚠️ PARTIAL
      test_user_id: "compliance_test_user_1728345678"
      tables_deleted_from: 23
      deletion_method: "Manual SQL execution"
      deletion_time: "7 days (manual approval + execution)"
      audit_trail_preserved: true
      gap: "Not automated, exceeds 24-hour target"

    GDPR_Right_to_Portability:
      status: ✅ PASS
      export_format: "JSON"
      schema_included: true
      completeness: "100%"
      security: "Encrypted download link, 24-hour expiry"

  Compliance_Gaps:
    Critical:  # Immediate action required (0-30 days)
      - gap_id: GAP-001
        title: "IP addresses and device IDs not masked"
        framework: GDPR
        requirement: "Article 32 - Security of processing"
        current_state: "IP addresses in 16 tables, device IDs in 4 tables - no masking"
        target_state: "Dynamic data masking applied to all PII fields"
        risk: HIGH
        impact: "PII exposure to unauthorized users, GDPR violation"
        remediation:
          action: "Create Snowflake masking policies for ip_address and device_id columns"
          owner: "Security Engineer"
          effort: "2 days"
          priority: 1

      - gap_id: GAP-002
        title: "Metabase and Airbyte audit log retention < 365 days"
        framework: SOC2
        requirement: "CC7.2 - System monitoring (12+ month retention)"
        current_state: "Metabase: 180 days, Airbyte: 90 days"
        target_state: "365+ days retention for all audit logs"
        risk: MEDIUM
        impact: "SOC 2 non-compliance, insufficient audit trail"
        remediation:
          action: "Configure log export to S3 with 365-day retention policy"
          owner: "DevOps Engineer"
          effort: "3 days"
          priority: 2

    High_Priority:  # 30-90 days
      - gap_id: GAP-003
        title: "Right to erasure not automated"
        framework: GDPR, CCPA
        requirement: "GDPR Article 17, CCPA Right to Delete"
        current_state: "Manual deletion process, 7-day turnaround"
        target_state: "Automated user deletion workflow, < 24 hour turnaround"
        risk: MEDIUM
        impact: "Slow response to DSRs, potential GDPR fine"
        remediation:
          action: "Build dbt macro for cascading user deletion with audit logging"
          owner: "Data Engineer"
          effort: "2 weeks"
          priority: 3
          implementation_steps:
            - "Identify all tables with user_id foreign keys"
            - "Create dbt macro: delete_user(user_id, reason, requester)"
            - "Implement dependency-ordered deletion"
            - "Add audit logging (deletion timestamp, reason, approver)"
            - "Create Airflow DAG for scheduled deletion execution"
            - "Test with synthetic users"

      - gap_id: GAP-004
        title: "MFA not enforced for all Snowflake users"
        framework: SOC2
        requirement: "CC6.1 - Logical access controls"
        current_state: "MFA required for admins only"
        target_state: "MFA required for all Snowflake users"
        risk: MEDIUM
        impact: "Unauthorized access risk, SOC 2 non-compliance"
        remediation:
          action: "Enable MFA enforcement via Snowflake account parameter"
          owner: "Security Engineer"
          effort: "1 day (+ user communication)"
          priority: 4

      - gap_id: GAP-005
        title: "No privacy impact assessments (PIAs) for new data sources"
        framework: GDPR
        requirement: "Article 35 - Data protection impact assessment"
        current_state: "No formal PIA process"
        target_state: "PIA conducted for all high-risk data sources"
        risk: MEDIUM
        impact: "Privacy risks not identified proactively"
        remediation:
          action: "Develop PIA template and require for new data source onboarding"
          owner: "Data Protection Officer"
          effort: "1 week (template) + 1 day per PIA"
          priority: 5

      - gap_id: GAP-006
        title: "Records of processing activities not centralized"
        framework: GDPR
        requirement: "Article 30 - Records of processing activities"
        current_state: "Processing activities documented in multiple locations"
        target_state: "Centralized ROPA (Record of Processing Activities) register"
        risk: LOW
        impact: "Difficulty demonstrating GDPR compliance to regulators"
        remediation:
          action: "Create ROPA spreadsheet/database with all processing activities"
          owner: "Data Governance Lead"
          effort: "3 days"
          priority: 6

    Medium_Priority:  # 90-180 days
      - gap_id: GAP-007
        title: "No SIEM integration for centralized security monitoring"
        framework: SOC2
        requirement: "CC7.2 - System monitoring (best practice)"
        current_state: "Siloed monitoring (Snowflake, Metabase, Airbyte)"
        target_state: "SIEM (e.g., Splunk, Datadog) aggregates all security logs"
        risk: LOW
        impact: "Delayed threat detection, fragmented incident response"
        remediation:
          action: "Evaluate SIEM vendors and implement centralized logging"
          owner: "Security Engineer"
          effort: "6 weeks"
          priority: 7

      - gap_id: GAP-008
        title: "No DLP (Data Loss Prevention) for data exfiltration"
        framework: SOC2
        requirement: "Confidentiality - Data exfiltration prevention"
        current_state: "No monitoring for unusual data exports"
        target_state: "DLP alerts for large data exports, PII downloads"
        risk: MEDIUM
        impact: "Insider threat, accidental PII disclosure"
        remediation:
          action: "Implement Snowflake object access monitoring with anomaly detection"
          owner: "Security Engineer"
          effort: "4 weeks"
          priority: 8

      - gap_id: GAP-009
        title: "No differential privacy for analytics dashboards"
        framework: GDPR
        requirement: "Article 25 - Privacy by design (best practice)"
        current_state: "Analytics queries expose individual-level data"
        target_state: "Differential privacy (noise injection) for aggregate queries"
        risk: LOW
        impact: "Re-identification risk in public-facing dashboards"
        remediation:
          action: "Research differential privacy libraries (e.g., Google DP, OpenDP)"
          owner: "Data Scientist + BI Analyst"
          effort: "8 weeks"
          priority: 9

  Remediation_Roadmap:
    Immediate_Actions:  # 0-30 days (Critical + Quick Wins)
      - action: "Apply Snowflake masking policies to ip_address columns (16 tables)"
        gap_id: GAP-001
        owner: "Security Engineer"
        effort: "1 day"
        priority: 1
        impact: "Eliminate PII exposure for IP addresses"

      - action: "Apply Snowflake masking policies to device_id columns (4 tables)"
        gap_id: GAP-001
        owner: "Security Engineer"
        effort: "1 day"
        priority: 1
        impact: "Eliminate PII exposure for device IDs"

      - action: "Configure Metabase audit log export to S3 (365-day retention)"
        gap_id: GAP-002
        owner: "DevOps Engineer"
        effort: "1 day"
        priority: 2
        impact: "SOC 2 compliance for Metabase audit logs"

      - action: "Configure Airbyte sync log export to S3 (365-day retention)"
        gap_id: GAP-002
        owner: "DevOps Engineer"
        effort: "1 day"
        priority: 2
        impact: "SOC 2 compliance for Airbyte audit logs"

      - action: "Enable MFA enforcement for all Snowflake users"
        gap_id: GAP-004
        owner: "Security Engineer"
        effort: "1 day (+ 1 week user rollout)"
        priority: 4
        impact: "SOC 2 CC6.1 compliance, reduced unauthorized access risk"

    Short_Term_Actions:  # 30-90 days (High Priority)
      - action: "Build automated user deletion workflow (dbt macro + Airflow DAG)"
        gap_id: GAP-003
        owner: "Data Engineer"
        effort: "2 weeks"
        priority: 3
        impact: "GDPR/CCPA compliance, reduce DSR response time to < 24 hours"
        milestones:
          - week_1: "Identify all user_id foreign keys, design deletion dependency graph"
          - week_2: "Implement dbt macro with audit logging, test with synthetic users"

      - action: "Develop PIA template and conduct PIAs for 5 highest-risk data sources"
        gap_id: GAP-005
        owner: "Data Protection Officer"
        effort: "2 weeks (template + 5 PIAs)"
        priority: 5
        impact: "GDPR Article 35 compliance, proactive privacy risk management"

      - action: "Create centralized ROPA (Record of Processing Activities) register"
        gap_id: GAP-006
        owner: "Data Governance Lead"
        effort: "3 days"
        priority: 6
        impact: "GDPR Article 30 compliance, easier regulatory audits"

    Medium_Term_Actions:  # 90-180 days (Medium Priority + Strategic)
      - action: "Evaluate and implement SIEM solution (Splunk, Datadog, or similar)"
        gap_id: GAP-007
        owner: "Security Engineer"
        effort: "6 weeks"
        priority: 7
        impact: "SOC 2 best practice, faster threat detection and incident response"

      - action: "Implement DLP monitoring for Snowflake data exports"
        gap_id: GAP-008
        owner: "Security Engineer"
        effort: "4 weeks"
        priority: 8
        impact: "SOC 2 confidentiality, insider threat mitigation"

      - action: "Research and pilot differential privacy for public analytics dashboards"
        gap_id: GAP-009
        owner: "Data Scientist + BI Analyst"
        effort: "8 weeks"
        priority: 9
        impact: "GDPR Article 25 best practice, reduce re-identification risk"

    Long_Term_Goals:  # 180+ days (Strategic Initiatives)
      - action: "Achieve SOC 2 Type II certification"
        owner: "Security Engineer + External Auditor"
        effort: "6 months"
        impact: "Customer trust, enterprise sales enablement, insurance discounts"

      - action: "Implement zero-trust architecture for data access"
        owner: "Security Architect"
        effort: "9 months"
        impact: "Defense-in-depth, reduced blast radius of breaches"

  Estimated_Remediation_Timeline:
    Immediate: "4 weeks (5 critical actions)"
    Short_Term: "12 weeks (3 high-priority actions)"
    Medium_Term: "24 weeks (3 strategic actions)"
    Total: "40 weeks (10 months) to full compliance"

  Estimated_Remediation_Cost:
    Engineering_Effort:
      - immediate: "5 days (0.5 FTE-weeks)"
      - short_term: "7 weeks (1.75 FTE-months)"
      - medium_term: "18 weeks (4.5 FTE-months)"
      - total: "6.75 FTE-months"

    Tooling_Costs:
      - SIEM: "$5,000-$15,000/year (Datadog, Splunk)"
      - DLP: "$3,000-$10,000/year (Snowflake feature upgrade)"
      - SOC2_Audit: "$25,000-$50,000 (one-time)"

    Total_Estimated_Cost: "$50,000-$100,000 (tooling + audit + 6.75 FTE-months)"

  Recommendations:
    Prioritization:
      - "Focus on Critical gaps first (GAP-001, GAP-002) - quick wins with high impact"
      - "Automate Right to Erasure (GAP-003) - highest ROI for GDPR/CCPA compliance"
      - "Defer differential privacy (GAP-009) until core compliance achieved"

    Risk_Mitigation:
      - "Conduct quarterly compliance audits (not just annual)"
      - "Assign Data Protection Officer (DPO) if processing >50k EU residents' data/year"
      - "Purchase cyber insurance to mitigate breach financial impact"

    Process_Improvements:
      - "Integrate compliance checks into CI/CD pipeline (detect new PII fields)"
      - "Require PIAs for all new data sources (shift-left privacy)"
      - "Automate compliance reporting (monthly compliance dashboard)"

    Training:
      - "Conduct GDPR/CCPA training for all employees handling data (annual)"
      - "Train engineering team on privacy-by-design principles"
      - "Simulate breach response annually (tabletop exercise)"
```

## Success Criteria

1. **Compliance Score ≥ 90%** across all frameworks
2. **Zero Critical Gaps** remaining
3. **Audit Log Retention ≥ 365 days** for all systems
4. **DSR Response Time < 24 hours** (automated)
5. **100% PII Masking** for all sensitive fields
6. **MFA Enforced** for all data access
7. **SOC 2 Type II Certification** achieved (if applicable)

## Notes

- **Opus Model Rationale**: Compliance audits require deep analysis, legal interpretation, and comprehensive gap identification. Opus provides superior precision and thoroughness compared to Sonnet.
- **Frequency**: Run quarterly or after significant architecture changes
- **Scope**: Can be domain-specific (--scope finance) or comprehensive (--scope all)
- **Evidence Retention**: Save compliance reports for regulatory audits (7+ year retention)
- **Legal Disclaimer**: This command provides technical compliance guidance. Consult legal counsel for regulatory interpretation.

## Related Commands

- `/security-audit` - Technical security vulnerability scanning
- `/data-quality-check` - Data integrity and quality validation
- `/schema-governance` - dbt schema and lineage validation
- `/generate-docs` - Generate compliance documentation

## References

- [GDPR Official Text](https://gdpr-info.eu/)
- [CCPA Official Text](https://oag.ca.gov/privacy/ccpa)
- [SOC 2 Trust Service Criteria](https://www.aicpa.org/content/dam/aicpa/interestareas/frc/assuranceadvisoryservices/downloadabledocuments/trust-services-criteria.pdf)
- [HIPAA Security Rule](https://www.hhs.gov/hipaa/for-professionals/security/index.html)
- [Snowflake Security & Compliance](https://docs.snowflake.com/en/user-guide/security)
