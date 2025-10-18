---
title: "Data Classification Taxonomy"
description: "Data sensitivity levels, PII types, and classification tagging strategy for Splash Sports data warehouse"
category: "core-concepts"
tags:
  - classification
  - pii
  - sensitivity
  - taxonomy
  - data-catalog
last_updated: "2025-10-07"
---

# Data Classification Taxonomy

## Classification Framework Overview

Data classification is the foundation of data governance, enabling appropriate security controls, access policies, and compliance measures based on data sensitivity.

### Classification Dimensions

**1. Sensitivity Level**: Public, Internal, Confidential, Restricted
**2. PII Type**: None, Quasi-Identifier, Direct Identifier, Sensitive PII
**3. Regulatory Scope**: GDPR, CCPA, SOC2, HIPAA, PCI-DSS
**4. Business Criticality**: Low, Medium, High, Critical
**5. Data Domain**: Finance, Contests, Operations, Analytics, Partners

---

## Sensitivity Levels

### Level 1: Public

**Definition**: Data intended for public consumption with no confidentiality requirements.

**Characteristics**:
- No harm from unauthorized disclosure
- Publicly available or intended for publication
- No access restrictions required

**Examples**:
- Marketing materials, blog posts
- Public API documentation
- Published game rules and contest structures
- Aggregated, anonymized statistics (no PII)

**Controls**:
- Access: Open to all authenticated users
- Encryption: Optional (TLS in transit)
- Retention: Business need basis
- Logging: Basic access logs

**dbt Tagging**:

```yaml
{{ config(
    tags=['sensitivity:public', 'pii:false']
) }}
```

### Level 2: Internal

**Definition**: General business data for internal use, low to moderate impact if disclosed.

**Characteristics**:
- Not intended for public disclosure
- Minimal risk if accessed by unauthorized internal users
- May include aggregated business metrics, internal reports

**Examples**:
- Non-PII user activity logs (pageviews, feature usage)
- Aggregated contest metrics (without user identification)
- Internal analytics dashboards (anonymized)
- Non-financial operational data

**Controls**:
- Access: Authenticated employees, role-based restrictions
- Encryption: At rest and in transit
- Retention: 1-2 years typical
- Logging: Access logs for audit

**dbt Tagging**:

```yaml
{{ config(
    tags=['sensitivity:internal', 'pii:false', 'access:public']
) }}
```

### Level 3: Confidential

**Definition**: Sensitive business data requiring protection, moderate to high impact if disclosed.

**Characteristics**:
- Competitive advantage or business-sensitive information
- Financial data, contracts, strategic plans
- May include pseudonymized user data

**Examples**:
- Revenue reports, financial forecasts
- Partner agreements and commission structures
- Detailed contest economics (margins, payouts)
- Pseudonymized user behavior (hashed user IDs)

**Controls**:
- Access: Need-to-know basis, manager approval
- Encryption: Strong encryption at rest and in transit
- Retention: 5-7 years (financial records)
- Logging: Detailed access logs, quarterly reviews

**dbt Tagging**:

```yaml
{{ config(
    tags=['sensitivity:confidential', 'business:finance', 'access:private']
) }}
```

### Level 4: Restricted

**Definition**: Highly sensitive data subject to regulatory requirements, severe impact if disclosed.

**Characteristics**:
- Personally Identifiable Information (PII)
- Payment card data (PCI-DSS)
- Protected Health Information (HIPAA, if applicable)
- Authentication credentials

**Examples**:
- User names, emails, phone numbers, addresses
- Social Security numbers, government IDs
- Credit card numbers, bank account information
- Passwords, API keys, authentication tokens
- Health data (if Splash integrates fitness tracking)

**Controls**:
- Access: Highly restricted, elevated privileges required
- Encryption: End-to-end encryption, key rotation
- Masking: Dynamic Data Masking (DDM) in Snowflake
- Retention: Minimum necessary, GDPR/CCPA compliance
- Logging: Comprehensive audit trail, real-time alerts

**dbt Tagging**:

```yaml
{{ config(
    tags=[
        'sensitivity:restricted',
        'pii:true',
        'pii_type:direct',
        'access:restricted',
        'compliance:gdpr',
        'compliance:ccpa'
    ]
) }}
```

---

## PII Classification

### PII Type 1: Non-PII

**Definition**: Data that cannot identify an individual directly or indirectly.

**Examples**:
- Aggregated contest statistics (total entries, average bet size)
- Device types (iOS vs Android) without user linkage
- Geographic aggregations (state-level data)
- Feature flags, application configuration

**Risk**: None (data cannot re-identify individuals)

**Treatment**: Standard business data controls

### PII Type 2: Quasi-Identifiers

**Definition**: Data that can re-identify individuals when combined with other data points.

**Examples**:
- Zip code (especially granular 9-digit)
- Birthdate (month/day/year)
- Gender
- Age range
- IP address (can be linked to ISP records)

**Risk**: Medium (re-identification possible with auxiliary data)

**Treatment**:
- Generalization (zip code → state, birthdate → year)
- Aggregation (age ranges instead of exact age)
- Suppression (remove low-frequency combinations)

**K-Anonymity**: Ensure at least K individuals share same quasi-identifier combination (typically K ≥ 5).

**Example**:

```sql
-- Quasi-identifier generalization
select
    user_id,
    left(zip_code, 3) as zip_prefix,  -- 12345 → 123
    date_trunc('year', birthdate) as birth_year,  -- 1990-05-15 → 1990-01-01
    case
        when age between 18 and 24 then '18-24'
        when age between 25 and 34 then '25-34'
        when age between 35 and 44 then '35-44'
        else '45+'
    end as age_range
from dim_user;
```

### PII Type 3: Direct Identifiers

**Definition**: Data that uniquely identifies an individual on its own.

**Examples**:
- Full name (first + last)
- Email address
- Phone number
- Social Security Number (SSN)
- Government-issued ID (driver's license, passport)
- User account ID (when linkable to identity)

**Risk**: High (direct identification)

**Treatment**:
- **Tokenization**: Replace with random token, store mapping securely
- **Hashing**: One-way hash with salt (irreversible)
- **Pseudonymization**: Replace with pseudonym, key stored separately
- **Masking**: Show only partial data (email: j***@example.com)

**Snowflake DDM Example**:

```sql
-- Masking policy for email
create or replace masking policy email_mask as (val string) returns string ->
    case
        when current_role() in ('COMPLIANCE_ADMIN', 'FINANCE_ADMIN') then val
        when current_role() in ('ANALYST_ROLE') then regexp_replace(val, '^(.)[^@]*', '\\1***')
        else '***@***.***'
    end;

alter table dim_user modify column email set masking policy email_mask;
```

### PII Type 4: Sensitive PII

**Definition**: PII with heightened privacy/security concerns due to potential harm from disclosure.

**Examples**:
- Financial account numbers
- Credit card numbers (PCI-DSS)
- Biometric data (fingerprints, facial recognition)
- Health information (HIPAA)
- Genetic data
- Sexual orientation, religious beliefs (GDPR special categories)
- Criminal history

**Risk**: Critical (severe harm from disclosure, regulatory penalties)

**Treatment**:
- **Never store** unless absolutely necessary
- **Tokenization via third-party**: Payment processors (Stripe tokens), identity providers
- **Encryption**: Strong encryption with key separation (different key management system)
- **Access logging**: Full audit trail, real-time monitoring

**PCI-DSS Compliance for Payment Data**:

```sql
-- NEVER store full credit card numbers in data warehouse
-- Use tokenized references from payment processor

select
    transaction_id,
    user_id,
    stripe_payment_token,  -- Safe: tokenized reference
    amount_usd,
    transaction_timestamp
from fct_wallet_deposits
-- NO: credit_card_number column (PCI-DSS violation)
```

---

## Splash Sports PII Inventory

### Source: splash_production

| Table | Column | PII Type | Sensitivity | Treatment |
|-------|--------|----------|-------------|-----------|
| **users** | user_id | Quasi-Identifier | Restricted | Pseudonymize in analytics |
| | email | Direct Identifier | Restricted | Mask in non-prod, DDM in prod |
| | phone | Direct Identifier | Restricted | Mask in non-prod, DDM in prod |
| | first_name | Direct Identifier | Restricted | Mask in non-prod |
| | last_name | Direct Identifier | Restricted | Mask in non-prod |
| | birthdate | Quasi-Identifier | Confidential | Generalize to year in marts |
| | zip_code | Quasi-Identifier | Internal | Generalize to 3-digit prefix |
| | ip_address | Quasi-Identifier | Internal | Hash or truncate last octet |
| | ssn | Sensitive PII | Restricted | **Should not be stored** |
| **wallet_transactions** | user_id | Quasi-Identifier | Restricted | Foreign key to dim_user |
| | stripe_payment_token | Non-PII | Confidential | Tokenized by Stripe (safe) |
| | bank_account_last4 | Quasi-Identifier | Confidential | Only last 4 digits (acceptable) |

### Source: segment (event tracking)

| Table | Column | PII Type | Sensitivity | Treatment |
|-------|--------|----------|-------------|-----------|
| **tracks** | anonymous_id | Quasi-Identifier | Internal | Cookie-based, not linked to user |
| | user_id | Quasi-Identifier | Restricted | Links to splash_production.users |
| | context_ip | Quasi-Identifier | Internal | Hash or exclude from warehouse |
| | context_device_id | Quasi-Identifier | Internal | Hash if stored |
| | context_user_agent | Non-PII | Internal | Browser string (no PII) |

### Source: intercom

| Table | Column | PII Type | Sensitivity | Treatment |
|-------|--------|----------|-------------|-----------|
| **conversations** | user_email | Direct Identifier | Restricted | Mask in non-prod |
| | user_name | Direct Identifier | Restricted | Mask in non-prod |
| | conversation_text | **Potential PII** | Restricted | Scan for SSN, credit cards, etc. |

---

## Classification Tagging Strategy

### dbt Model Tags

**Required Tags for PII Models**:

```yaml
{{ config(
    tags=[
        'pii:true',                      # Flag as containing PII
        'pii_type:direct',               # Type: direct, quasi, sensitive
        'sensitivity:restricted',        # Sensitivity level
        'compliance:gdpr',               # Applicable regulations
        'compliance:ccpa',
        'access:restricted',             # Access control level
        'retention:7_years'              # Data retention period
    ]
) }}
```

**Example: Staging User Model**:
```sql
-- models/dwh/staging/shared/stg_splash_production__users.sql
{{
    config(
        tags=[
            'group:shared',
            'layer:staging',
            'pii:true',
            'pii_type:direct',
            'sensitivity:restricted',
            'compliance:gdpr',
            'compliance:ccpa',
            'access:restricted',
            'retention:7_years',
            'consumed_by:finance',
            'consumed_by:contests',
            'consumed_by:partners'
        ]
    )
}}

select
    user_id,
    email,                               -- Direct PII
    phone,                               -- Direct PII
    first_name || ' ' || last_name as full_name,  -- Direct PII
    birthdate,                           -- Quasi-identifier
    zip_code,                            -- Quasi-identifier
    created_at,
    updated_at
from {{ source('splash_production', 'users') }}
```

**Example: De-identified Analytics Model**:
```sql
-- models/dwh/marts/analytics/mart_user_demographics.sql
{{
    config(
        tags=[
            'group:shared',
            'layer:marts',
            'pii:false',                 -- De-identified
            'sensitivity:internal',
            'access:public'
        ]
    )
}}

select
    md5(user_id) as user_hash,          -- Pseudonymized
    date_trunc('year', birthdate) as birth_year,  -- Generalized
    left(zip_code, 3) as zip_prefix,    -- Generalized
    case
        when age < 25 then '18-24'
        when age < 35 then '25-34'
        when age < 45 then '35-44'
        else '45+'
    end as age_range,
    count(*) as user_count
from {{ ref('stg_splash_production__users') }}
group by 1, 2, 3, 4
having count(*) >= 5  -- K-anonymity (k=5)
```

### Snowflake Object Tagging

**Tag Creation**:

```sql
-- Create classification tags in Snowflake
create tag if not exists pii_classification
    allowed_values 'NONE', 'QUASI_IDENTIFIER', 'DIRECT_IDENTIFIER', 'SENSITIVE_PII';

create tag if not exists sensitivity_level
    allowed_values 'PUBLIC', 'INTERNAL', 'CONFIDENTIAL', 'RESTRICTED';

create tag if not exists compliance_scope
    allowed_values 'GDPR', 'CCPA', 'SOC2', 'HIPAA', 'PCI_DSS';
```

**Apply Tags to Tables/Columns**:

```sql
-- Tag entire table
alter table prod.finance.dim_user set tag pii_classification = 'DIRECT_IDENTIFIER';
alter table prod.finance.dim_user set tag sensitivity_level = 'RESTRICTED';
alter table prod.finance.dim_user set tag compliance_scope = 'GDPR,CCPA';

-- Tag specific columns
alter table prod.finance.dim_user modify column email
    set tag pii_classification = 'DIRECT_IDENTIFIER';

alter table prod.finance.dim_user modify column birthdate
    set tag pii_classification = 'QUASI_IDENTIFIER';
```

**Query Tags for Governance**:
```sql
-- Find all tables with PII
select
    tag_database,
    tag_schema,
    tag_name,
    tag_value,
    object_database,
    object_schema,
    object_name,
    column_name
from snowflake.account_usage.tag_references
where tag_name = 'PII_CLASSIFICATION'
    and tag_value != 'NONE'
order by object_database, object_schema, object_name;
```

---

## Automated PII Detection

### Pattern-Based Detection

**Regex Patterns for Common PII**:
```python
# Python script for PII detection in dbt models

import re

PII_PATTERNS = {
    'email': r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b',
    'phone': r'\b(\+?1[-.\s]?)?(\(?\d{3}\)?[-.\s]?)?\d{3}[-.\s]?\d{4}\b',
    'ssn': r'\b\d{3}-\d{2}-\d{4}\b',
    'credit_card': r'\b\d{4}[-\s]?\d{4}[-\s]?\d{4}[-\s]?\d{4}\b',
    'ip_address': r'\b(?:\d{1,3}\.){3}\d{1,3}\b',
}

def scan_column_for_pii(column_name: str, sample_values: list) -> dict:
    """Scan column for PII patterns."""
    results = {'column': column_name, 'pii_detected': []}

    for value in sample_values:
        if not value:
            continue
        value_str = str(value)

        for pii_type, pattern in PII_PATTERNS.items():
            if re.search(pattern, value_str):
                results['pii_detected'].append(pii_type)

    return results
```

### Catalog-Based Detection

Maintain curated list of known PII fields:

```yaml
# .claude/governance/pii-catalog.yml
known_pii_fields:
  direct_identifiers:
    - email
    - phone
    - first_name
    - last_name
    - full_name
    - ssn
    - driver_license
    - passport_number

  quasi_identifiers:
    - user_id
    - birthdate
    - birth_date
    - zip_code
    - postal_code
    - ip_address
    - device_id

  sensitive_pii:
    - credit_card_number
    - bank_account_number
    - routing_number
    - health_record_id
    - biometric_hash
```

### dbt Test for PII Detection

```sql
-- tests/assert_pii_models_tagged.sql
-- Ensure all models with PII columns have pii:true tag

with pii_columns as (
    select distinct
        model_name,
        column_name
    from {{ ref('information_schema_columns') }}
    where lower(column_name) in (
        'email', 'phone', 'first_name', 'last_name',
        'ssn', 'credit_card_number', 'bank_account_number'
    )
),

model_tags as (
    select
        model_name,
        tags
    from {{ ref('dbt_models_metadata') }}
)

select
    p.model_name,
    p.column_name,
    t.tags
from pii_columns p
left join model_tags t on p.model_name = t.model_name
where not array_contains('pii:true'::variant, t.tags)
```

---

## Data Masking Decision Tree

```
┌─────────────────────────────┐
│ Does column contain PII?    │
└──────────┬──────────────────┘
           │
    ┌──────┴──────┐
    │ YES         │ NO → No masking required
    │             │
    ▼             │
┌────────────────────────────────┐
│ What PII type?                 │
└────┬────────────────────┬──────┘
     │                    │
     ▼                    ▼
┌─────────────┐   ┌──────────────────┐
│ Direct PII  │   │ Quasi-Identifier │
└──────┬──────┘   └────────┬─────────┘
       │                   │
       ▼                   ▼
┌──────────────┐   ┌────────────────────┐
│ Mask in      │   │ Generalize in      │
│ non-prod     │   │ analytics marts    │
│              │   │                    │
│ Apply DDM in │   │ - Zip → prefix     │
│ prod for     │   │ - Birthdate → year │
│ analysts     │   │ - Age → range      │
└──────────────┘   └────────────────────┘
```

---

## Classification Review Workflow

**1. Automated Classification** (dbt build):
- Scan column names against PII catalog
- Pattern-match sample values for PII
- Flag models missing required tags

**2. Manual Review** (quarterly):
- Data steward reviews flagged models
- Validates auto-classification accuracy
- Documents exceptions and edge cases

**3. Continuous Monitoring**:
- dbt tests fail if PII models lack tags
- Pre-commit hooks validate tag completeness
- Snowflake audit logs track access to restricted data

**4. Documentation**:
- Update `pii-field-catalog.md` with new PII fields
- Document classification decisions in `decisions/classification-taxonomy.md`
- Maintain lineage of PII propagation (staging → core → marts)

---

## Next Steps

1. **Read**: `audit-trail-architecture.md` for access logging and monitoring
2. **Read**: `../patterns/pii-detection-patterns.md` for automated detection implementation
3. **Read**: `../patterns/data-masking-strategies.md` for masking/pseudonymization techniques
4. **Implement**: Start PII inventory for Splash data sources
5. **Coordinate**: Work with architect to design conformed dim_user with proper masking
