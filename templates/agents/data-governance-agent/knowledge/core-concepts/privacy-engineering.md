---
title: "Privacy Engineering Principles"
description: "Privacy Impact Assessments, privacy-by-design, and proactive privacy engineering for data warehouse"
category: "core-concepts"
tags:
  - privacy
  - pia
  - privacy-by-design
  - privacy-engineering
  - gdpr
last_updated: "2025-10-07"
---

# Privacy Engineering Principles

## Overview

Privacy engineering is the practice of building privacy protections into systems from the ground up rather than bolting them on afterward. It combines legal compliance, technical controls, and organizational processes.

### Core Principles (Privacy by Design)

**1. Proactive not Reactive; Preventative not Remedial**

- Anticipate privacy risks before they materialize
- Build safeguards into system design (not after incidents)

**2. Privacy as the Default Setting**

- Maximum privacy protection by default
- Users shouldn't need to opt-in to privacy

**3. Privacy Embedded into Design**

- Privacy integral to system architecture and business practices
- Not an add-on module or checkbox

**4. Full Functionality — Positive-Sum, not Zero-Sum**

- Privacy without sacrificing functionality
- Win-win solutions (not privacy vs. utility trade-off)

**5. End-to-End Security — Full Lifecycle Protection**

- Secure data from collection through deletion
- Cradle-to-grave data lifecycle management

**6. Visibility and Transparency — Keep it Open**

- Operations subject to independent verification
- Stakeholders assured that privacy protections are in place

**7. Respect for User Privacy — Keep it User-Centric**

- Strong privacy defaults, user control, notice
- Empower users to manage their data

---

## Privacy Impact Assessment (PIA)

### When to Conduct a PIA

**Mandatory Triggers**:

1. **New Data Source Integration**: Third-party APIs, vendor data feeds
2. **New Processing Purpose**: Using existing data for new purpose (e.g., marketing analytics)
3. **New Data Sharing**: Sharing data with partners, vendors, or affiliates
4. **High-Risk Processing**: Large-scale PII, sensitive data, automated decision-making
5. **Significant System Changes**: Architecture redesign, cloud migration

**Optional but Recommended**:

- Annual review of existing processing activities
- After regulatory changes (new laws, guidance updates)
- Following data breaches or security incidents

### GDPR DPIA (Data Protection Impact Assessment)

**Article 35 Requirements**:

- Mandatory for "high risk" processing:
  - Systematic and extensive automated processing (profiling)
  - Large-scale processing of special categories of data (health, biometrics)
  - Large-scale systematic monitoring of public areas
- Must consult Data Protection Authority (DPA) if high residual risk

### PIA Process

**Step 1: Scoping and Planning**

- Define processing activity (what data, what purpose)
- Identify stakeholders (data subjects, data controllers, processors)
- Determine PIA type (full vs. simplified)

**Step 2: Data Mapping**

- Document data flows (source → processing → storage → sharing → deletion)
- Identify data categories (PII types, sensitivity levels)
- Map data lifecycle stages

**Step 3: Risk Identification**

- Privacy risks to data subjects (unauthorized access, re-identification, function creep)
- Compliance risks (GDPR violations, CCPA non-compliance)
- Security risks (data breaches, insider threats)

**Step 4: Risk Assessment**

- Evaluate likelihood and impact of each risk
- Consider existing controls (encryption, access controls, audit logs)
- Calculate residual risk after controls

**Step 5: Mitigation Planning**

- Propose additional controls to reduce risk
- Architectural changes (e.g., separate PII into dedicated schema)
- Policy changes (e.g., stricter access approval process)

**Step 6: Documentation and Approval**

- Formal PIA report with findings and recommendations
- Sign-off from data protection officer, legal, and business owner
- Periodic review schedule (annually or when processing changes)

---

## PIA Template for Splash Sports

### Section 1: Processing Activity Overview

**Project Name**: [e.g., "Segment Event Tracking Integration"]

**Business Owner**: [e.g., "Product Analytics Team"]

**Data Protection Officer**: [Contact info]

**Processing Purpose**: [e.g., "Track user behavior across web and mobile apps for product improvement and personalized recommendations"]

**Lawful Basis for Processing** (GDPR):

- [ ] Consent
- [ ] Contract performance
- [ ] Legal obligation
- [x] Legitimate interest (specify: product improvement, fraud detection)
- [ ] Vital interests
- [ ] Public task

**Data Categories Processed**:

- [ ] Identifiers (name, email, phone)
- [x] User IDs (pseudonymized)
- [x] Behavioral data (page views, clicks, session duration)
- [x] Device data (OS, browser, IP address)
- [ ] Payment data
- [ ] Health data
- [ ] Special categories (race, religion, sexual orientation)

### Section 2: Data Flow Mapping

**Data Sources**:

1. Segment Web SDK (JavaScript tracking on splash.com)
2. Segment Mobile SDKs (iOS and Android apps)
3. Server-side events from backend API

**Data Processing Steps**:

1. Event collection via Segment libraries
2. Transmission to Segment cloud (TLS encrypted)
3. Synced to Snowflake via Fivetran connector
4. Staged in `staging.segment__tracks` table
5. Transformed into `marts.analytics__user_sessions`
6. Consumed by Metabase dashboards and data science models

**Data Storage Locations**:

- Segment Cloud (AWS US-East-1) - 30 days
- Snowflake (AWS US-West-2) - 90 days active, 1 year archive

**Data Recipients (Third Parties)**:

- Segment (CDP platform, BAA/DPA in place)
- Fivetran (ETL service, DPA in place)
- Snowflake (data warehouse, DPA in place)
- Internal teams (Product, Analytics, Data Science)

**Data Retention**:

- Active: 90 days in production warehouse
- Archive: 1 year in cold storage (Snowflake Time Travel)
- Deletion: Automated purge after retention period

### Section 3: Risk Assessment

| Risk | Likelihood | Impact | Risk Level | Existing Controls |
|------|------------|--------|------------|-------------------|
| **Re-identification of pseudonymized users** | Medium | High | **High** | - User IDs hashed<br>- No direct PII in events<br>- Access restricted to analysts |
| **Unauthorized access to behavioral data** | Low | Medium | **Medium** | - RBAC in Snowflake<br>- MFA required<br>- Audit logging enabled |
| **Data breach during transmission** | Low | High | **Medium** | - TLS encryption in transit<br>- DPAs with vendors |
| **Function creep (using data for unintended purposes)** | Medium | Medium | **Medium** | - Privacy policy specifies allowed uses<br>- Access controls by team |
| **Non-compliance with user opt-out requests** | Low | High | **Medium** | - Consent tracking in dim_user<br>- Exclusion logic in dbt models |

**Risk Scoring**:

- Likelihood: Low (1), Medium (2), High (3)
- Impact: Low (1), Medium (2), High (3)
- Risk Level: Low (1-2), Medium (3-4), High (6-9)

### Section 4: Mitigation Measures

**High Priority (Residual Risk: High)**:

**Risk: Re-identification of pseudonymized users**

- **Mitigation 1**: Implement k-anonymity (ensure ≥5 users per quasi-identifier combination)
  - Technical: Add dbt test for k-anonymity validation
  - Timeline: Before production launch
- **Mitigation 2**: Separate pseudonymization key storage
  - Technical: Store user ID mapping in separate schema with elevated access control
  - Timeline: Q2 2025
- **Mitigation 3**: Regular re-identification testing
  - Process: Quarterly attempt to re-identify sample of users
  - Timeline: Ongoing (quarterly)

**Medium Priority (Residual Risk: Medium)**:

**Risk: Function creep**

- **Mitigation**: Formal data access request process
  - Policy: Require business justification and approval for new use cases
  - Technical: Tag models with `business_purpose` metadata
  - Timeline: Q1 2025

**Risk: Non-compliance with opt-out**

- **Mitigation**: Automated consent enforcement
  - Technical: dbt incremental models exclude opted-out users
  - Testing: dbt test validates no opted-out users in marts
  - Timeline: Before production launch

### Section 5: Data Subject Rights Implementation

**GDPR Rights**:

| Right | Implementation | Timeline |
|-------|----------------|----------|
| **Right to Access** | SQL export script generates user data package | ✅ Implemented |
| **Right to Erasure** | Cascading delete across fact tables, audit log retained | ✅ Implemented |
| **Right to Rectification** | Update user record in dim_user, propagate via SCD Type 2 | Q1 2025 |
| **Right to Data Portability** | Export in JSON format via API endpoint | Q2 2025 |
| **Right to Object** | Opt-out flag in dim_user, exclusion logic in dbt models | ✅ Implemented |
| **Right to Restrict Processing** | Freeze flag prevents new processing while retaining data | Q1 2025 |

### Section 6: PIA Conclusion

**Overall Risk Rating**: Medium (after mitigation)

**Recommended Action**: Proceed with processing activity subject to implementing high-priority mitigations.

**DPA Consultation Required**: No (residual risk is medium, not high)

**PIA Approval**:

- Data Protection Officer: [Signature] [Date]
- Business Owner: [Signature] [Date]
- Legal Counsel: [Signature] [Date]

**Review Schedule**: Annually or when processing materially changes

---

## Privacy-by-Design in Data Warehouse

### Design Pattern 1: Separation of Identifiable and Behavioral Data

**Problem**: Behavioral data is useful for analytics, but linking to PII creates privacy risk.

**Solution**: Store PII and behavioral data in separate schemas with different access controls.

```text
┌─────────────────────────────────────────────┐
│ FINANCE Schema (Restricted Access)         │
│ - dim_user (PII: email, phone, name)       │
│ - fct_wallet_transactions (financial data) │
└─────────────────────────────────────────────┘
                    ▲
                    │ user_id foreign key
                    │
┌─────────────────────────────────────────────┐
│ ANALYTICS Schema (Broader Access)           │
│ - fct_user_sessions (pseudonymized)         │
│ - fct_pageviews (no PII)                    │
│ - mart_user_behavior (aggregated)           │
└─────────────────────────────────────────────┘
```

**Benefits**:

- Analysts can work with behavioral data without PII access
- Finance team has PII access only when needed for transactions
- Reduces blast radius if analytics schema is compromised

### Design Pattern 2: Layered Data Masking

**Problem**: Different roles need different levels of data detail.

**Solution**: Apply progressive masking based on role.

```sql
-- Snowflake masking policy for email
create or replace masking policy email_progressive_mask as (val string) returns string ->
    case
        when current_role() in ('COMPLIANCE_ADMIN', 'FINANCE_ADMIN') then val  -- Full: user@example.com
        when current_role() in ('SUPPORT_AGENT') then regexp_replace(val, '^(.)[^@]*', '\\1***')  -- Partial: u***@example.com
        when current_role() in ('ANALYST_ROLE') then regexp_replace(val, '^.*@', '***@')  -- Domain only: ***@example.com
        else '***@***.***'  -- Fully masked
    end;

alter table dim_user modify column email set masking policy email_progressive_mask;
```

**Role Hierarchy**:

1. **Executive / Compliance**: Full data access (legal/regulatory need)
2. **Support / Operations**: Partial masking (verify identity, troubleshoot)
3. **Analysts / Data Scientists**: Domain-level or aggregated (analytics without PII)
4. **External / Contractors**: Fully masked or no access

### Design Pattern 3: Privacy-Preserving Joins

**Problem**: Joining behavioral data to PII enables re-identification.

**Solution**: Use aggregation and anonymization before joins.

```sql
-- ❌ BAD: Direct join exposes PII in behavioral context
select
    u.email,  -- PII
    s.pageviews,
    s.session_duration
from dim_user u
join fct_user_sessions s on u.user_id = s.user_id
where s.pageviews > 100;

-- ✅ GOOD: Aggregate first, then join on anonymized key
with user_segments as (
    select
        md5(user_id) as user_hash,
        sum(pageviews) as total_pageviews,
        avg(session_duration) as avg_session_duration
    from fct_user_sessions
    group by md5(user_id)
    having count(*) >= 5  -- K-anonymity
)
select
    user_hash,  -- Anonymized
    total_pageviews,
    avg_session_duration
from user_segments
where total_pageviews > 100;
```

### Design Pattern 4: Differential Privacy for Aggregates

**Problem**: Publishing aggregate statistics can leak information about individuals.

**Solution**: Add statistical noise to aggregates (differential privacy).

```sql
-- Add Laplacian noise to protect individual-level data
with contest_stats as (
    select
        contest_id,
        count(distinct user_id) as participant_count,
        sum(entry_fee_usd) as total_revenue
    from fct_contest_entries
    group by contest_id
)

select
    contest_id,
    -- Add noise proportional to sensitivity (± 5% for k-anonymity)
    participant_count + floor((random() - 0.5) * participant_count * 0.05) as participant_count_noisy,
    total_revenue + (random() - 0.5) * total_revenue * 0.05 as total_revenue_noisy
from contest_stats
where participant_count >= 10;  -- Suppress small counts
```

### Design Pattern 5: Temporal Privacy (Retention-Aware Schemas)

**Problem**: Over-retention increases privacy risk and violates GDPR storage limitation.

**Solution**: Embed retention policies in dbt models with automated expiration.

```yaml
# models/schema.yml
models:
  - name: fct_user_sessions
    description: "User session events with 90-day retention"
    config:
      tags:
        - retention:90_days
        - auto_archive:true
    columns:
      - name: session_timestamp
        description: "Session start time (used for retention cutoff)"
        tests:
          - dbt_utils.expression_is_true:
              expression: ">= current_date - interval '90 days'"
```

```sql
-- dbt incremental model with retention enforcement
{{ config(
    materialized='incremental',
    unique_key='session_id',
    tags=['retention:90_days', 'pii:quasi_identifier']
) }}

select
    session_id,
    user_id,
    session_timestamp,
    pageviews,
    session_duration
from {{ source('segment', 'tracks') }}
where session_timestamp >= current_date - interval '90 days'  -- Retention filter
{% if is_incremental() %}
    and session_timestamp > (select max(session_timestamp) from {{ this }})
{% endif %}
```

---

## Privacy Engineering Checklist

### Data Collection

- [ ] Collect only data necessary for stated purpose (data minimization)
- [ ] Obtain valid consent or establish lawful basis (GDPR Article 6)
- [ ] Provide clear privacy notice at collection time
- [ ] Avoid "dark patterns" that manipulate user consent

### Data Storage

- [ ] Encrypt data at rest (Snowflake native encryption)
- [ ] Separate PII from behavioral/analytical data
- [ ] Apply masking policies based on role (Snowflake DDM)
- [ ] Tag tables/columns with sensitivity classification

### Data Processing

- [ ] Pseudonymize or anonymize data when possible
- [ ] Implement k-anonymity for quasi-identifiers (k ≥ 5)
- [ ] Use privacy-preserving joins (aggregate before join)
- [ ] Add differential privacy noise to published aggregates

### Data Sharing

- [ ] Data Processing Agreements (DPAs) with all vendors
- [ ] Validate vendor security controls (SOC2 reports)
- [ ] Restrict cross-border transfers (GDPR adequacy decisions, SCCs)
- [ ] Audit third-party access regularly

### Data Retention

- [ ] Define retention periods for each data category
- [ ] Automate data deletion after retention period
- [ ] Implement legal hold for litigation/investigations
- [ ] Document retention rationale in data catalog

### Data Subject Rights

- [ ] Right to Access: SQL export script ready
- [ ] Right to Erasure: Cascading delete implemented
- [ ] Right to Rectification: Update and audit trail process
- [ ] Right to Data Portability: Machine-readable export (JSON)
- [ ] Right to Object: Opt-out flag and enforcement logic

### Audit and Monitoring

- [ ] Log all access to PII (Snowflake access_history)
- [ ] Alert on unusual data access patterns
- [ ] Quarterly access reviews and recertification
- [ ] Annual PIA review for existing processing

---

## Privacy Engineering in dbt

### Macro: Pseudonymize User ID

```sql
-- macros/pseudonymize_user_id.sql
{% macro pseudonymize_user_id(column_name='user_id', salt='privacy_salt_2025') %}
    md5({{ column_name }} || '{{ salt }}')
{% endmacro %}
```

**Usage**:

```sql
select
    {{ pseudonymize_user_id('user_id') }} as user_hash,
    session_timestamp,
    pageviews
from {{ source('segment', 'tracks') }}
```

### Macro: Enforce K-Anonymity

```sql
-- macros/enforce_k_anonymity.sql
{% macro enforce_k_anonymity(k=5) %}
    having count(*) >= {{ k }}
{% endmacro %}
```

**Usage**:

```sql
select
    zip_prefix,
    birth_year,
    gender,
    count(*) as user_count
from {{ ref('stg_users') }}
group by zip_prefix, birth_year, gender
{{ enforce_k_anonymity(k=5) }}
```

### Test: Detect PII Leakage in Marts

```sql
-- tests/assert_no_pii_in_marts.sql
-- Ensure mart models don't expose direct PII

with mart_models as (
    select
        model_name,
        column_name
    from {{ ref('information_schema_columns') }}
    where schema_name ilike '%_marts'
)

select
    model_name,
    column_name
from mart_models
where lower(column_name) in (
    'email', 'phone', 'ssn', 'credit_card_number',
    'first_name', 'last_name', 'full_name'
)
```

---

## PIA Process Integration with Development Workflow

### Pull Request Checklist for New Data Sources

```markdown
## Privacy Review Checklist

- [ ] **Data Mapping**: Documented all PII fields in schema.yml
- [ ] **Classification**: Applied sensitivity tags (pii:true, pii_type:direct, etc.)
- [ ] **Masking**: Snowflake DDM policies applied to PII columns
- [ ] **Access Controls**: RBAC configured (who can access this data?)
- [ ] **Retention**: Defined retention period and automated expiration
- [ ] **Testing**: dbt tests validate no PII leakage in marts
- [ ] **PIA**: Privacy Impact Assessment completed (if high-risk)
- [ ] **DPA**: Data Processing Agreement signed with vendor (if third-party)
- [ ] **Documentation**: Privacy controls documented in data catalog

**DPO Approval Required**: [ ] Yes (high-risk processing) [ ] No
```

### Pre-Production PIA Gate

**GitHub Actions Workflow**:

```yaml
name: Privacy Compliance Check

on:
  pull_request:
    paths:
      - 'models/sources/**'  # New source integrations
      - 'models/dwh/staging/**'  # New staging models

jobs:
  privacy-check:
    runs-on: ubuntu-latest
    steps:
      - name: Scan for PII fields
        run: |
          python scripts/scan_pii.py --path models/

      - name: Validate PIA completion
        run: |
          if grep -r "pii:true" models/ && ! ls docs/privacy/pia-*.md; then
            echo "ERROR: PII detected but no PIA found in docs/privacy/"
            exit 1
          fi

      - name: Check DDM policies
        run: |
          # Validate Snowflake masking policies exist for PII columns
          python scripts/validate_ddm.py
```

---

## Next Steps

1. **Read**: `../patterns/pii-detection-patterns.md` for automated PII discovery
2. **Read**: `../patterns/data-masking-strategies.md` for Snowflake DDM implementation
3. **Read**: `../decisions/classification-taxonomy.md` for Splash-specific PII catalog
4. **Implement**: Conduct PIA for Segment integration (high-risk processing)
5. **Coordinate**: Work with architect to design privacy-preserving dimensional models
