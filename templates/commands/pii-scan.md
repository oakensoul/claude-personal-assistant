---
name: pii-scan
description: Scan tables/schemas for PII fields, apply data classification tags, and recommend Snowflake Dynamic Data Masking policies
model: sonnet
type: global
args:
  target:
    description: Table name, schema pattern, or --all flag
    required: false
  domain:
    description: Business domain filter (finance, contests, partners, shared)
    required: false
---

# PII Detection & Data Classification

Automated PII discovery and classification system that scans database tables for personally identifiable information, applies data classification tags, generates Snowflake Dynamic Data Masking policies, and validates GDPR/CCPA compliance.

## Purpose

This command provides comprehensive data governance automation:

1. **PII Pattern Detection** - Regex patterns, column name heuristics, sample data analysis
2. **Data Classification** - Apply 4-level taxonomy (Public → Regulated PII)
3. **Masking Policy Generation** - Snowflake DDM SQL for role-based access
4. **Compliance Validation** - GDPR/CCPA/SOC2 requirement checks
5. **Documentation Update** - PII inventory catalog and audit trails

**Agent Invocation**: This command invokes the `privacy-security-auditor` agent to perform PII detection, data classification, masking policy generation, and compliance validation.

## Usage

```bash
# Scan specific table
/pii-scan staging.stg_new_users

# Scan schema pattern (all tables in schema)
/pii-scan finance_staging.*

# Scan all tables in domain
/pii-scan --all --domain finance

# Scan all tables (use with caution)
/pii-scan --all
```

## PII Detection Methods

### Pattern-Based Detection (Regex)

**Email Addresses**:

```regex
Pattern: [a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}
Examples: user@example.com, john.doe+tag@domain.co.uk
Confidence: 95% if pattern matches + column name contains "email"
```

**Phone Numbers**:

```regex
US_Pattern: ^\(?([0-9]{3})\)?[-. ]?([0-9]{3})[-. ]?([0-9]{4})$
International: ^\+?[1-9]\d{1,14}$
Examples: 555-123-4567, (555) 123-4567, +1-555-123-4567
Confidence: 90% if pattern matches + column name contains "phone"
```

**Social Security Numbers (SSN)**:

```regex
Pattern: ^(?!000|666)[0-8][0-9]{2}-(?!00)[0-9]{2}-(?!0000)[0-9]{4}$
Examples: 123-45-6789
Confidence: 99% (highly specific pattern)
```

**Credit Card Numbers**:

```regex
Pattern: ^(?:4[0-9]{12}(?:[0-9]{3})?|5[1-5][0-9]{14}|3[47][0-9]{13})$
Validation: Luhn algorithm checksum
Examples: 4111-1111-1111-1111 (Visa), 5500-0000-0000-0004 (Mastercard)
Confidence: 95% with Luhn validation
```

**IP Addresses**:

```regex
IPv4: ^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$
IPv6: ^(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|...)$
Examples: 192.168.1.1, 2001:0db8:85a3:0000:0000:8a2e:0370:7334
Confidence: 85% (can be used for non-PII purposes)
```

**Cryptocurrency Wallet Addresses**:

```regex
Bitcoin: ^[13][a-km-zA-HJ-NP-Z1-9]{25,34}$
Ethereum: ^0x[a-fA-F0-9]{40}$
Examples: 1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa, 0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb
Confidence: 80% (blockchain context required)
```

### Column Name Heuristics

**Direct Matches** (100% confidence if pattern also matches):

- `email`, `email_address`, `user_email`, `customer_email`
- `phone`, `phone_number`, `mobile`, `mobile_number`
- `ssn`, `social_security_number`, `national_id`
- `credit_card`, `card_number`, `payment_card`
- `address`, `street_address`, `home_address`
- `passport`, `passport_number`, `drivers_license`

**Pattern Matches** (80% confidence):

- `*_email` → Email field
- `*_phone` → Phone field
- `*_ssn` → Social Security Number
- `*_address` → Physical address
- `*_ip` → IP address
- `wallet_*` → Cryptocurrency wallet

**Financial Identifiers**:

- `account_number`, `routing_number`, `iban`, `swift_code`
- `bank_account`, `payment_method`, `billing_info`

**Identity Fields**:

- `first_name`, `last_name`, `full_name`, `legal_name`
- `date_of_birth`, `dob`, `birth_date`
- `gender`, `sex`, `ethnicity`, `race`

### Sample-Based Analysis

**Methodology**:

1. Query first 1000 rows from table
2. Apply pattern detection to actual data values
3. Calculate PII confidence score (0-100%)
4. Flag high-confidence matches (>80%)

**Confidence Scoring Algorithm**:

```python
confidence_score = (
    pattern_match_weight * 0.4 +
    column_name_weight * 0.3 +
    data_sample_weight * 0.3
)

# Example:
# - Pattern match: 95% (email regex matches)
# - Column name: 100% (column = "user_email")
# - Data sample: 98% (990/1000 rows match pattern)
# → Final confidence: 97.7%
```

## Classification Taxonomy

### Level 1 - Public Data

**Definition**: No PII or sensitive information

**Access**: Broad access, no restrictions

**Examples**:


- Product catalogs
- Public event schedules
- Contest rules and descriptions
- Marketing content

**Snowflake Tag**: `classification:public`

### Level 2 - Internal Data

**Definition**: Business data with no PII

**Access**: Restricted to employees

**Examples**:


- Revenue aggregates (no user-level detail)
- Contest performance metrics
- Operational dashboards
- System logs (anonymized)

**Snowflake Tag**: `classification:internal`

### Level 3 - Sensitive Data

**Definition**: Contains PII but not regulated

**Access**: Role-based access controls required

**Examples**:


- User behavior analytics (pseudonymized)
- Wallet balances (no payment methods)
- Contest history (user-level)
- Geolocation data (city-level)

**Snowflake Tag**: `classification:sensitive`

### Level 4 - Regulated PII

**Definition**: GDPR/CCPA protected data

**Access**: Strict access controls + masking policies

**Examples**:


- Email addresses
- Phone numbers
- Payment methods (credit cards, bank accounts)
- Precise geolocation (latitude/longitude)
- Biometric data
- Health information

**Snowflake Tag**: `classification:regulated_pii`

## Workflow

### Phase 1: Table Discovery

**Interactive Mode**:

```yaml
Assistant: "What would you like to scan for PII?"
Options:
  1. Specific table (e.g., staging.stg_new_users)
  2. Schema pattern (e.g., finance_staging.*)
  3. Domain-wide (all tables in finance, contests, partners)
  4. Full scan (all tables in warehouse)

User: "/pii-scan staging.stg_new_users"
Assistant_Actions:
  1. Parse target specification
  2. Query Snowflake INFORMATION_SCHEMA for table metadata
  3. Extract column names and data types
  4. Generate column inventory
```

**Steps**:

1. Parse user input (table, schema pattern, domain filter, or --all)
2. Query Snowflake `INFORMATION_SCHEMA.TABLES` and `INFORMATION_SCHEMA.COLUMNS`
3. Build list of tables to scan
4. Extract column metadata for each table

**Example Snowflake Query**:

```sql
-- Get all columns in finance_staging schema
SELECT
    table_schema,
    table_name,
    column_name,
    data_type,
    ordinal_position
FROM INFORMATION_SCHEMA.COLUMNS
WHERE table_schema = 'FINANCE_STAGING'
ORDER BY table_schema, table_name, ordinal_position;
```

### Phase 2: PII Pattern Detection

**Invoke Data Governance Agent**:

```yaml
Task:
  subagent_type: "security-engineer"
  prompt: |
    Analyze the following table for PII:

    Table: staging.stg_new_users
    Columns: [user_id, email, phone_number, first_name, last_name, created_at, ip_address]

    Apply PII detection methods:
    1. Pattern-based detection (regex matching)
    2. Column name heuristics
    3. Sample data analysis (first 1000 rows)

    Return PII confidence scores for each column.
```

**Detection Steps**:

1. **Column Name Analysis** - Check for PII keywords
2. **Pattern Matching** - Apply regex to sample data
3. **Confidence Scoring** - Calculate weighted confidence
4. **High-Confidence Flagging** - Mark columns >80% confidence

**Sample Data Query** (for each suspicious column):

```sql
-- Get sample data for pattern matching
SELECT
    email,
    COUNT(*) as sample_count
FROM staging.stg_new_users
LIMIT 1000;

-- Apply pattern detection
-- Example: Count rows matching email pattern
SELECT
    COUNT(*) as total_rows,
    SUM(CASE WHEN REGEXP_LIKE(email, '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}') THEN 1 ELSE 0 END) as pattern_matches,
    (pattern_matches / total_rows * 100) as match_percentage
FROM staging.stg_new_users
LIMIT 1000;
```

### Phase 3: Data Classification

**Classification Decision Logic**:

```python
def classify_column(pii_type, confidence_score):
    if pii_type is None:
        return "Level 1 - Public Data"

    # Regulated PII (GDPR/CCPA protected)
    regulated_pii_types = [
        'email', 'phone', 'ssn', 'credit_card',
        'passport', 'drivers_license', 'precise_geolocation',
        'biometric', 'health_info'
    ]

    if pii_type in regulated_pii_types and confidence_score > 80:
        return "Level 4 - Regulated PII"

    # Sensitive PII (not regulated but requires access controls)
    sensitive_pii_types = [
        'ip_address', 'user_agent', 'wallet_address',
        'first_name', 'last_name', 'city_geolocation'
    ]

    if pii_type in sensitive_pii_types and confidence_score > 70:
        return "Level 3 - Sensitive Data"

    # Internal data (business data, no PII)
    return "Level 2 - Internal Data"
```

**Snowflake Tagging**:

```sql
-- Apply classification tag to column
ALTER TABLE staging.stg_new_users
MODIFY COLUMN email
SET TAG classification = 'regulated_pii';

-- Apply PII type tag
ALTER TABLE staging.stg_new_users
MODIFY COLUMN email
SET TAG pii_type = 'email_address';
```

### Phase 4: Masking Policy Recommendations

**Masking Policy Templates**:

**Email Masking (Partial)**:


```sql
CREATE OR REPLACE MASKING POLICY mask_email_partial AS (val STRING)
RETURNS STRING ->
  CASE
    WHEN CURRENT_ROLE() IN ('FINANCE_ADMIN', 'DBA', 'COMPLIANCE_OFFICER') THEN val
    ELSE REGEXP_REPLACE(val, '(.).*@', '\\1***@')
  END
COMMENT = 'Partial email masking: u***@example.com';

-- Apply to column
ALTER TABLE staging.stg_new_users
MODIFY COLUMN email
SET MASKING POLICY mask_email_partial;
```

**Phone Number Masking (Full)**:

```sql
CREATE OR REPLACE MASKING POLICY mask_phone_full AS (val STRING)
RETURNS STRING ->
  CASE
    WHEN CURRENT_ROLE() IN ('FINANCE_ADMIN', 'DBA', 'COMPLIANCE_OFFICER') THEN val
    ELSE 'XXX-XXX-XXXX'
  END
COMMENT = 'Full phone number masking';

-- Apply to column
ALTER TABLE staging.stg_new_users
MODIFY COLUMN phone_number
SET MASKING POLICY mask_phone_full;
```

**SSN Masking (Full)**:

```sql
CREATE OR REPLACE MASKING POLICY mask_ssn_full AS (val STRING)
RETURNS STRING ->
  CASE
    WHEN CURRENT_ROLE() IN ('FINANCE_ADMIN', 'DBA', 'COMPLIANCE_OFFICER', 'LEGAL') THEN val
    ELSE 'XXX-XX-XXXX'
  END
COMMENT = 'Full SSN masking for GDPR/CCPA compliance';
```

**Credit Card Masking (Partial - Last 4 Digits)**:

```sql
CREATE OR REPLACE MASKING POLICY mask_credit_card_partial AS (val STRING)
RETURNS STRING ->
  CASE
    WHEN CURRENT_ROLE() IN ('FINANCE_ADMIN', 'DBA', 'PAYMENT_PROCESSOR') THEN val
    ELSE 'XXXX-XXXX-XXXX-' || RIGHT(val, 4)
  END
COMMENT = 'Credit card masking showing last 4 digits';
```

**IP Address Masking (Partial)**:

```sql
CREATE OR REPLACE MASKING POLICY mask_ip_partial AS (val STRING)
RETURNS STRING ->
  CASE
    WHEN CURRENT_ROLE() IN ('SECURITY_ADMIN', 'DBA', 'FRAUD_TEAM') THEN val
    ELSE REGEXP_REPLACE(val, '([0-9]+\\.[0-9]+\\.).*', '\\1XXX.XXX')
  END
COMMENT = 'IP address masking: 192.168.XXX.XXX';
```

**Cryptocurrency Wallet Masking**:

```sql
CREATE OR REPLACE MASKING POLICY mask_wallet_partial AS (val STRING)
RETURNS STRING ->
  CASE
    WHEN CURRENT_ROLE() IN ('FINANCE_ADMIN', 'DBA', 'FRAUD_TEAM') THEN val
    ELSE LEFT(val, 6) || '***' || RIGHT(val, 4)
  END
COMMENT = 'Crypto wallet masking: 0x742d***bEb';
```

**Role-Based Access Matrix**:

```yaml
Unmasked_Access_Roles:
  FINANCE_ADMIN:
    - All financial PII (email, phone, payment methods)
  DBA:
    - All PII (administrative access)
  COMPLIANCE_OFFICER:
    - Regulated PII for audit purposes
  LEGAL:
    - SSN, regulated identifiers
  PAYMENT_PROCESSOR:
    - Credit card numbers (payment processing)
  SECURITY_ADMIN:
    - IP addresses, security logs
  FRAUD_TEAM:
    - IP addresses, wallet addresses, transaction PII

Masked_Access_Roles:
  ANALYST:
    - Partial masking on all PII
  BI_DEVELOPER:
    - Partial masking on all PII
  REPORT_VIEWER:
    - Full masking on all PII
```

### Phase 5: Compliance Validation

**GDPR Requirements Check**:

```yaml
GDPR_Article_32_Security:
  Requirement: "Encryption of personal data"
  Check: Snowflake encryption at-rest (AES-256)
  Status: ✅ PASS
  Evidence: "Snowflake default encryption enabled"

GDPR_Article_15_Access:
  Requirement: "Data subject access request (DSAR) workflow"
  Check: Process to retrieve user PII on request
  Status: ⚠️  REVIEW
  Action: "Implement DSAR automation (export user PII by user_id)"

GDPR_Article_17_Erasure:
  Requirement: "Right to be forgotten (data deletion)"
  Check: Process to delete user PII on request
  Status: ⚠️  REVIEW
  Action: "Implement deletion workflow with audit trail"

GDPR_Article_30_Records:
  Requirement: "Records of processing activities"
  Check: PII inventory catalog maintained
  Status: ✅ PASS
  Evidence: "PII inventory updated in data governance catalog"

GDPR_Article_33_Breach:
  Requirement: "Data breach notification (72 hours)"
  Check: Incident response plan documented
  Status: ⚠️  REVIEW
  Action: "Document PII breach notification workflow"
```

**CCPA Requirements Check**:

```yaml
CCPA_Section_1798_100_Disclosure:
  Requirement: "Disclosure of PII collection to consumers"
  Check: Privacy notice lists PII categories
  Status: ✅ PASS
  Evidence: "Privacy notice includes email, phone, wallet transactions"

CCPA_Section_1798_110_Access:
  Requirement: "Consumer right to know (DSAR)"
  Check: Process to provide PII copy to consumer
  Status: ⚠️  REVIEW
  Action: "Same as GDPR Article 15 - implement DSAR automation"

CCPA_Section_1798_105_Deletion:
  Requirement: "Consumer right to delete"
  Check: Process to delete consumer PII on request
  Status: ⚠️  REVIEW
  Action: "Same as GDPR Article 17 - implement deletion workflow"

CCPA_Section_1798_120_Opt_Out:
  Requirement: "Right to opt-out of sale of personal information"
  Check: Opt-out mechanism implemented
  Status: ✅ PASS (if applicable)
  Evidence: "No sale of personal information (N/A)"
```

**SOC 2 Data Classification Check**:

```yaml
SOC2_CC6_7_Data_Classification:
  Requirement: "Data classification controls"
  Check: PII tagged with classification levels
  Status: ✅ PASS
  Evidence: "4-level classification taxonomy applied"

SOC2_CC6_1_Logical_Access:
  Requirement: "Role-based access controls (RBAC)"
  Check: Masking policies enforce least privilege
  Status: ✅ PASS
  Evidence: "Role-based masking policies generated"

SOC2_CC7_2_System_Monitoring:
  Requirement: "Monitoring of PII access"
  Check: Snowflake query history audit log enabled
  Status: ✅ PASS
  Evidence: "QUERY_HISTORY view tracks PII access"
```

### Phase 6: Documentation Update

**PII Inventory Catalog Update**:

```markdown
# PII Inventory Catalog

## Table: staging.stg_new_users

**Classification**: Level 4 - Regulated PII
**Last Scanned**: 2025-10-07
**PII Columns**: 5 of 23 total columns

| Column | PII Type | Confidence | Classification | Masking Policy |
|--------|----------|------------|----------------|----------------|
| email | Email Address | 98% | Regulated PII | mask_email_partial |
| phone_number | Phone Number | 95% | Regulated PII | mask_phone_full |
| ip_address | IP Address | 85% | Sensitive | mask_ip_partial |
| first_name | First Name | 100% | Sensitive | mask_name_partial |
| last_name | Last Name | 100% | Sensitive | mask_name_partial |

**Compliance Requirements**:
- GDPR Article 15: Implement DSAR automation
- GDPR Article 17: Implement deletion workflow
- CCPA Section 1798.110: Same DSAR process
- SOC 2 CC6.7: Classification tags applied

**Access Controls**:
- Unmasked: FINANCE_ADMIN, DBA, COMPLIANCE_OFFICER
- Partial Masking: ANALYST, BI_DEVELOPER
- Full Masking: REPORT_VIEWER

**Data Retention**:
- Active Users: Indefinite (operational requirement)
- Deleted Users: 30-day soft delete, then permanent deletion
```

**Audit Trail Entry**:

```yaml
PII_Scan_Audit_Log:
  Timestamp: 2025-10-07T14:32:15Z
  Operator: rob@betterpool.com
  Action: PII_SCAN
  Target: staging.stg_new_users
  PII_Detected: 5 columns
  Classification_Applied: Level 4 (Regulated PII)
  Masking_Policies_Generated: 3
  Compliance_Status:
    GDPR: "2 action items (DSAR, deletion workflow)"
    CCPA: "2 action items (same as GDPR)"
    SOC2: "PASS (classification applied)"
  Next_Review: 2025-11-07 (30 days)
```

## Output Format

### Standard Scan Report

```yaml
PII_Scan_Report:
  Scan_ID: "pii-scan-20251007-143215"
  Timestamp: "2025-10-07T14:32:15Z"
  Operator: "rob@betterpool.com"
  Target: "finance_staging.stg_wallet_transactions"

  Table_Summary:
    Total_Columns: 23
    PII_Detected: 5
    High_Confidence_PII: 4 (>80%)
    Medium_Confidence_PII: 1 (50-80%)
    Classification_Level: "Level 4 - Regulated PII"

  PII_Columns:
    - Column: user_email
      Data_Type: VARCHAR(255)
      PII_Type: Email Address
      Confidence: 98%
      Detection_Methods:
        - Pattern_Match: ✅ (email regex)
        - Column_Name: ✅ (contains "email")
        - Sample_Analysis: ✅ (990/1000 rows match)
      Sample_Data: "user@example.com" (masked for report)
      Classification: "Level 4 - Regulated PII"
      Recommended_Masking: "Partial (u***@example.com)"
      Masking_Policy: "mask_email_partial"
      Unmasked_Roles: [FINANCE_ADMIN, DBA, COMPLIANCE_OFFICER]

    - Column: phone_number
      Data_Type: VARCHAR(20)
      PII_Type: Phone Number
      Confidence: 95%
      Detection_Methods:
        - Pattern_Match: ✅ (US phone regex)
        - Column_Name: ✅ (contains "phone")
        - Sample_Analysis: ✅ (950/1000 rows match)
      Sample_Data: "555-123-4567" (masked for report)
      Classification: "Level 4 - Regulated PII"
      Recommended_Masking: "Full (XXX-XXX-XXXX)"
      Masking_Policy: "mask_phone_full"
      Unmasked_Roles: [FINANCE_ADMIN, DBA, COMPLIANCE_OFFICER]

    - Column: wallet_address
      Data_Type: VARCHAR(42)
      PII_Type: Cryptocurrency Wallet (Ethereum)
      Confidence: 85%
      Detection_Methods:
        - Pattern_Match: ✅ (Ethereum address regex)
        - Column_Name: ✅ (contains "wallet")
        - Sample_Analysis: ✅ (850/1000 rows match)
      Sample_Data: "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb" (masked)
      Classification: "Level 3 - Sensitive Data"
      Recommended_Masking: "Partial (0x742d***bEb)"
      Masking_Policy: "mask_wallet_partial"
      Unmasked_Roles: [FINANCE_ADMIN, DBA, FRAUD_TEAM]

    - Column: ip_address
      Data_Type: VARCHAR(45)
      PII_Type: IP Address (IPv4/IPv6)
      Confidence: 82%
      Detection_Methods:
        - Pattern_Match: ✅ (IPv4 regex)
        - Column_Name: ✅ (contains "ip")
        - Sample_Analysis: ✅ (820/1000 rows match IPv4)
      Sample_Data: "192.168.1.1" (masked for report)
      Classification: "Level 3 - Sensitive Data"
      Recommended_Masking: "Partial (192.168.XXX.XXX)"
      Masking_Policy: "mask_ip_partial"
      Unmasked_Roles: [SECURITY_ADMIN, DBA, FRAUD_TEAM]

    - Column: transaction_note
      Data_Type: TEXT
      PII_Type: Possible Free-Text PII
      Confidence: 65%
      Detection_Methods:
        - Pattern_Match: ⚠️  (email pattern found in 15% of rows)
        - Column_Name: ❌ (no PII keyword)
        - Sample_Analysis: ⚠️  (mixed content, some PII leakage)
      Sample_Data: "Payment for contest entry, contact: user@example.com"
      Classification: "Level 3 - Sensitive Data (review required)"
      Recommended_Masking: "Manual review + redaction policy"
      Masking_Policy: "MANUAL_REVIEW_REQUIRED"
      Action_Required: "Review free-text field for PII leakage, consider NLP-based redaction"

  Masking_Policies_Generated:
    - Policy_Name: mask_email_partial
      SQL: |
        CREATE OR REPLACE MASKING POLICY mask_email_partial AS (val STRING)
        RETURNS STRING ->
          CASE
            WHEN CURRENT_ROLE() IN ('FINANCE_ADMIN', 'DBA', 'COMPLIANCE_OFFICER') THEN val
            ELSE REGEXP_REPLACE(val, '(.).*@', '\\1***@')
          END
        COMMENT = 'Partial email masking: u***@example.com';

      Apply_To:
        - "finance_staging.stg_wallet_transactions.user_email"

      Apply_SQL: |
        ALTER TABLE finance_staging.stg_wallet_transactions
        MODIFY COLUMN user_email
        SET MASKING POLICY mask_email_partial;

    - Policy_Name: mask_phone_full
      SQL: |
        CREATE OR REPLACE MASKING POLICY mask_phone_full AS (val STRING)
        RETURNS STRING ->
          CASE
            WHEN CURRENT_ROLE() IN ('FINANCE_ADMIN', 'DBA', 'COMPLIANCE_OFFICER') THEN val
            ELSE 'XXX-XXX-XXXX'
          END
        COMMENT = 'Full phone number masking';

      Apply_To:
        - "finance_staging.stg_wallet_transactions.phone_number"

      Apply_SQL: |
        ALTER TABLE finance_staging.stg_wallet_transactions
        MODIFY COLUMN phone_number
        SET MASKING POLICY mask_phone_full;

    - Policy_Name: mask_wallet_partial
      SQL: |
        CREATE OR REPLACE MASKING POLICY mask_wallet_partial AS (val STRING)
        RETURNS STRING ->
          CASE
            WHEN CURRENT_ROLE() IN ('FINANCE_ADMIN', 'DBA', 'FRAUD_TEAM') THEN val
            ELSE LEFT(val, 6) || '***' || RIGHT(val, 4)
          END
        COMMENT = 'Crypto wallet masking: 0x742d***bEb';

      Apply_To:
        - "finance_staging.stg_wallet_transactions.wallet_address"

      Apply_SQL: |
        ALTER TABLE finance_staging.stg_wallet_transactions
        MODIFY COLUMN wallet_address
        SET MASKING POLICY mask_wallet_partial;

  Compliance_Validation:
    GDPR_Compliance:
      Article_32_Encryption:
        Status: ✅ PASS
        Evidence: "Snowflake AES-256 encryption at-rest enabled"

      Article_15_Access_Request:
        Status: ⚠️  ACTION REQUIRED
        Action: "Implement DSAR automation to export user PII by user_id"
        Priority: HIGH
        Deadline: "2025-11-07 (30 days)"

      Article_17_Erasure:
        Status: ⚠️  ACTION REQUIRED
        Action: "Implement right-to-be-forgotten deletion workflow with audit trail"
        Priority: HIGH
        Deadline: "2025-11-07 (30 days)"

      Article_30_Records:
        Status: ✅ PASS
        Evidence: "PII inventory catalog updated with scan results"

      Article_33_Breach_Notification:
        Status: ⚠️  REVIEW
        Action: "Document PII breach notification workflow (72-hour requirement)"
        Priority: MEDIUM
        Deadline: "2025-12-07 (60 days)"

    CCPA_Compliance:
      Section_1798_100_Disclosure:
        Status: ✅ PASS
        Evidence: "Privacy notice discloses PII collection (email, phone, wallet transactions)"

      Section_1798_110_Access:
        Status: ⚠️  ACTION REQUIRED
        Action: "Same as GDPR Article 15 - DSAR automation"
        Priority: HIGH
        Deadline: "2025-11-07 (30 days)"

      Section_1798_105_Deletion:
        Status: ⚠️  ACTION REQUIRED
        Action: "Same as GDPR Article 17 - deletion workflow"
        Priority: HIGH
        Deadline: "2025-11-07 (30 days)"

      Section_1798_120_Opt_Out:
        Status: ✅ PASS (N/A)
        Evidence: "No sale of personal information (sports betting platform)"

    SOC2_Compliance:
      CC6_7_Data_Classification:
        Status: ✅ PASS
        Evidence: "4-level classification taxonomy applied to all PII columns"

      CC6_1_Logical_Access:
        Status: ✅ PASS
        Evidence: "Role-based masking policies enforce least privilege access"

      CC7_2_System_Monitoring:
        Status: ✅ PASS
        Evidence: "Snowflake QUERY_HISTORY audit log tracks PII access"

  Compliance_Summary:
    Total_Checks: 12
    Passed: 7
    Action_Required: 4
    Under_Review: 1
    Overall_Status: ⚠️  COMPLIANT WITH ACTION ITEMS

  Action_Items:
    - Priority: HIGH
      Action: "Implement DSAR automation (GDPR Art. 15, CCPA 1798.110)"
      Owner: "Data Governance Team"
      Deadline: "2025-11-07"
      Ticket: "Create JIRA ticket for DSAR workflow implementation"

    - Priority: HIGH
      Action: "Implement right-to-be-forgotten deletion workflow (GDPR Art. 17, CCPA 1798.105)"
      Owner: "Data Governance Team"
      Deadline: "2025-11-07"
      Ticket: "Create JIRA ticket for deletion workflow implementation"

    - Priority: MEDIUM
      Action: "Document PII breach notification workflow (GDPR Art. 33)"
      Owner: "Security Team"
      Deadline: "2025-12-07"
      Ticket: "Create JIRA ticket for breach notification documentation"

    - Priority: LOW
      Action: "Review free-text field 'transaction_note' for PII leakage"
      Owner: "Data Engineering Team"
      Deadline: "2025-11-07"
      Ticket: "Manual review + NLP redaction policy evaluation"

  Next_Steps:
    1. "Review masking policies with Legal and Compliance teams"
    2. "Apply masking policies to production (SQL provided above)"
    3. "Create JIRA tickets for GDPR/CCPA action items (HIGH priority)"
    4. "Update data retention policy for Level 4 Regulated PII"
    5. "Schedule PII scan review in 30 days (2025-11-07)"
    6. "Add to privacy notice: Cryptocurrency wallet addresses collected"

  Documentation_Updated:
    - "PII Inventory Catalog: finance_staging.stg_wallet_transactions entry created"
    - "Audit Trail: PII scan log entry added"
    - "Compliance Dashboard: Action items tracked"

  Scan_Duration: "3.2 seconds"
  Rows_Sampled: 1000
  Next_Review_Date: "2025-11-07"
```

## Examples

### Example 1: New Staging Table Scan

**Command**:

```bash
/pii-scan staging.stg_new_user_signups
```

**User Interaction**:

```yaml
Assistant: "Scanning staging.stg_new_user_signups for PII..."

Phase_1_Discovery:
  Tables_Found: 1
  Total_Columns: 15

Phase_2_Detection:
  PII_Detected: 4 columns
  - email (98% confidence - Email Address)
  - phone (95% confidence - Phone Number)
  - ip_address (85% confidence - IP Address)
  - user_agent (70% confidence - Browser User Agent)

Phase_3_Classification:
  Classification_Level: "Level 4 - Regulated PII"
  Reason: "Email and phone are GDPR/CCPA protected"

Phase_4_Masking:
  Policies_Generated: 3
  - mask_email_partial (email column)
  - mask_phone_full (phone column)
  - mask_ip_partial (ip_address column)

Phase_5_Compliance:
  GDPR_Status: ⚠️  2 action items (DSAR, deletion workflow)
  CCPA_Status: ⚠️  2 action items (same as GDPR)
  SOC2_Status: ✅ PASS

Phase_6_Documentation:
  PII_Inventory: ✅ Updated
  Audit_Trail: ✅ Logged

Summary:
  "4 PII columns detected in staging.stg_new_user_signups"
  "3 masking policies generated (SQL provided)"
  "2 HIGH priority action items for GDPR/CCPA compliance"

Would you like me to:
1. Generate JIRA tickets for compliance action items?
2. Apply masking policies to production?
3. Export full PII scan report?
```

### Example 2: Domain-Wide Scan

**Command**:

```bash
/pii-scan --all --domain finance
```

**User Interaction**:

```yaml
Assistant: "Scanning all tables in finance domain for PII..."

Phase_1_Discovery:
  Tables_Scanned: 12
  Total_Columns: 287
  Domains: [finance_staging, finance, finance_marts]

Phase_2_Detection:
  PII_Detected: 47 columns across 12 tables
  High_Confidence: 38 columns (>80%)
  Medium_Confidence: 9 columns (50-80%)

Phase_3_Classification:
  Level_4_Regulated_PII: 8 tables
  Level_3_Sensitive: 4 tables
  Level_2_Internal: 0 tables

Phase_4_Masking:
  Policies_Generated: 15
  New_Policies: 8 (unique PII types)
  Reusable_Policies: 7 (applied to multiple columns)

Phase_5_Compliance:
  GDPR_Action_Items: 2 (domain-wide DSAR and deletion)
  CCPA_Action_Items: 2 (same as GDPR)
  SOC2_Status: ✅ PASS (all tables classified)

Phase_6_Documentation:
  PII_Inventory_Entries: 12 tables documented
  Audit_Trail: ✅ Domain-wide scan logged

Summary:
  "47 PII columns detected across 12 finance domain tables"
  "15 masking policies generated (8 unique, 7 reusable)"
  "2 HIGH priority compliance action items (DSAR, deletion)"

Bulk_Application_Plan:
  "Apply masking policies in phases:"
  Phase_1: "Staging tables (3 tables, 12 PII columns)"
  Phase_2: "Core tables (5 tables, 23 PII columns)"
  Phase_3: "Marts (4 tables, 12 PII columns)"

  Estimated_Time: "15 minutes (policy creation + application)"
  Rollback_Plan: "DROP MASKING POLICY commands provided"

Would you like me to:
1. Generate bulk masking policy application script?
2. Create JIRA epic for finance domain PII governance?
3. Export domain-wide PII inventory report?
```

### Example 3: Airbyte Source Validation

**Command**:

```bash
/pii-scan staging.stg_airbyte_new_source_*
```

**User Interaction**:

```yaml
Assistant: "Scanning new Airbyte source tables for unexpected PII..."

Phase_1_Discovery:
  Tables_Matched: 8 (stg_airbyte_new_source_*)
  Total_Columns: 143
  Source_System: "Airbyte connector: Stripe Payments"

Phase_2_Detection:
  Expected_PII: 12 columns (documented in Stripe schema)
  Unexpected_PII: 3 columns ⚠️
    - customer_notes (free-text field with email leakage)
    - transaction_metadata (JSON field with IP addresses)
    - webhook_payload (raw webhook data with credit card last-4)

Phase_3_Classification:
  Level_4_Regulated_PII: 5 tables ⚠️
  Unexpected_PII_Risk: "HIGH (undocumented PII in free-text fields)"

Phase_4_Masking:
  Standard_Policies: 10 (email, phone, credit card)
  Custom_Policies_Required: 3 (free-text redaction)
    - Redact emails in customer_notes
    - Redact IP from JSON metadata
    - Redact credit card from webhook payload

Phase_5_Compliance:
  GDPR_Risk: ⚠️  HIGH (unexpected PII not disclosed)
  CCPA_Risk: ⚠️  HIGH (privacy notice outdated)
  SOC2_Risk: ⚠️  MEDIUM (data classification incomplete)

Phase_6_Documentation:
  PII_Inventory: ✅ Updated with unexpected findings
  Audit_Trail: ⚠️  Flagged for security review

Summary:
  "⚠️  UNEXPECTED PII DETECTED IN NEW AIRBYTE SOURCE"
  "3 columns contain undocumented PII in free-text/JSON fields"
  "Compliance risk: Privacy notice does not disclose this PII collection"

Recommended_Actions:
  1. "URGENT: Apply masking policies to unexpected PII columns"
  2. "Update privacy notice with new PII categories"
  3. "Review Airbyte source configuration (filter sensitive fields at source)"
  4. "Notify Legal and Compliance teams of unexpected PII"
  5. "Consider NLP-based redaction for free-text fields"

Would you like me to:
1. Generate emergency masking policies for unexpected PII?
2. Create incident report for compliance team?
3. Recommend Airbyte source-level filters?
```

## Error Handling

**Missing Snowflake Credentials**:

```yaml
Error: "Snowflake connection failed"
Action:
  1. Check ~/.dbt/profiles.yml configuration
  2. Verify Snowflake account credentials
  3. Test connection: dbt debug --target dev
```

**Table Not Found**:

```yaml
Error: "Table 'staging.stg_nonexistent' does not exist"
Action:
  1. Verify table name and schema
  2. Check user has SELECT privilege on table
  3. Use SHOW TABLES IN SCHEMA to list available tables
```

**Insufficient Privileges**:

```yaml
Error: "Insufficient privileges to apply masking policy"
Action:
  1. Masking policy creation requires OWNERSHIP or CREATE MASKING POLICY privilege
  2. Contact Snowflake admin for privilege grant
  3. Workaround: Export masking policy SQL for admin to apply
```

**Sample Data Query Timeout**:

```yaml
Error: "Query timeout on table with 100M+ rows"
Action:
  1. Reduce sample size (LIMIT 100 instead of 1000)
  2. Skip sample-based detection for very large tables
  3. Rely on pattern matching and column name heuristics only
```

**Free-Text PII Detection Ambiguity**:

```yaml
Warning: "Free-text field 'notes' may contain PII but confidence low (45%)"
Action:
  1. Manual review required
  2. Consider NLP-based PII redaction tools (AWS Comprehend, Google DLP API)
  3. Recommend application-level input validation to prevent PII leakage
```

## Integration with Existing Workflows

**Post-Airbyte Sync**:

```bash
# After new Airbyte source connection
/pii-scan staging.stg_airbyte_new_source_*
→ Validate expected vs. unexpected PII
→ Apply masking policies before downstream consumption
→ Update compliance documentation
```

**Pre-Production Deployment**:

```bash
# Before deploying new models to production
/pii-scan dwh/staging/finance/*.sql
→ Scan new staging models for PII
→ Generate masking policies
→ Update PII inventory catalog
→ Validate GDPR/CCPA compliance
```

**Quarterly Compliance Audit**:

```bash
# Quarterly PII inventory review
/pii-scan --all --domain finance
/pii-scan --all --domain contests
/pii-scan --all --domain partners
→ Update PII inventory catalog
→ Validate masking policies still applied
→ Check for new PII columns (schema drift)
→ Generate compliance audit report
```

## Success Criteria

- All PII columns detected with >80% confidence
- Classification levels applied to all tables
- Masking policies generated for all Regulated PII (Level 4)
- GDPR/CCPA/SOC2 compliance validated
- PII inventory catalog updated
- Audit trail logged
- Action items prioritized and assigned

---

**Command Type**: Global (available in all projects)
**Primary Agent**: `privacy-security-auditor`
**Model**: Sonnet (pattern detection and classification)
**Dependencies**: Snowflake connection, dbt profiles.yml
**Output**: PII scan report + masking policy SQL + compliance checklist
