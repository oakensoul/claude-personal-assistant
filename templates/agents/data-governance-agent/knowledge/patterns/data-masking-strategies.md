---
title: "Data Masking Strategies"
description: "Tokenization, anonymization, pseudonymization, and Snowflake Dynamic Data Masking implementation"
category: "patterns"
tags:
  - data-masking
  - snowflake-ddm
  - tokenization
  - anonymization
last_updated: "2025-10-07"
---

# Data Masking Strategies

## Masking Techniques Overview

| Technique | Reversible | Use Case | Example |
|-----------|------------|----------|---------|
| **Static Masking** | No | Dev/test environments | `john.doe@example.com` → `user***@example.com` |
| **Dynamic Masking (DDM)** | Yes (with privilege) | Production role-based access | Mask based on current_role() |
| **Tokenization** | Yes (with key) | Payment data | 4111-1111-1111-1111 → tok_abc123 |
| **Pseudonymization** | Yes (with key) | Analytics with traceability | user_id=12345 → hash_xyz789 |
| **Anonymization** | No (irreversible) | Public datasets | Remove all identifiers permanently |

## Snowflake Dynamic Data Masking (DDM)

### Pattern: Progressive Masking by Role

```sql
-- Email masking policy: Show different detail levels by role
create or replace masking policy email_progressive_mask as (val string) returns string ->
    case
        when current_role() in ('ACCOUNTADMIN', 'COMPLIANCE_ADMIN') then val  -- john.doe@example.com
        when current_role() in ('FINANCE_ADMIN', 'SUPPORT_LEAD') then
            regexp_replace(val, '^(.)[^@]*', '\\1***')  -- j***@example.com
        when current_role() in ('ANALYST_ROLE', 'DATA_SCIENTIST') then
            regexp_replace(val, '^.*@', '***@')  -- ***@example.com
        else '***MASKED***'
    end;

-- Apply to column
alter table prod.finance.dim_user
    modify column email set masking policy email_progressive_mask;
```

### Pattern: Conditional Masking (Business Logic)

```sql
-- Mask based on row-level attributes (e.g., only mask VIP users)
create or replace masking policy vip_user_mask as (val string, is_vip boolean) returns string ->
    case
        when current_role() = 'VIP_SUPPORT' then val  -- Full access for VIP support
        when is_vip = true then '***MASKED***'  -- Mask VIP users for regular roles
        else val  -- Non-VIP users visible to all
    end;

alter table prod.finance.dim_user
    modify column email set masking policy vip_user_mask using (email, is_vip_user);
```

### DDM Deployment Pattern

```sql
-- Step 1: Create masking policies (in dedicated schema)
create schema if not exists prod.governance;

create or replace masking policy prod.governance.pii_email_mask as (val string) returns string ->
    case when current_role() in ('COMPLIANCE_ADMIN', 'FINANCE_ADMIN') then val else '***@***.***' end;

create or replace masking policy prod.governance.pii_phone_mask as (val string) returns string ->
    case when current_role() in ('COMPLIANCE_ADMIN', 'SUPPORT_ADMIN') then val else '***-***-****' end;

create or replace masking policy prod.governance.pii_name_mask as (val string) returns string ->
    case when current_role() in ('COMPLIANCE_ADMIN') then val else '***MASKED***' end;

-- Step 2: Apply to all PII columns across schemas
alter table prod.finance.dim_user modify column email set masking policy prod.governance.pii_email_mask;
alter table prod.finance.dim_user modify column phone set masking policy prod.governance.pii_phone_mask;
alter table prod.finance.dim_user modify column first_name set masking policy prod.governance.pii_name_mask;
alter table prod.finance.dim_user modify column last_name set masking policy prod.governance.pii_name_mask;

-- Step 3: Validate masking is applied
show masking policies in schema prod.governance;
```

## Tokenization (External Vault)

### Payment Data Tokenization (Stripe Example)

```sql
-- NEVER store raw credit card numbers
-- Store tokenized references from payment processor

{{ config(tags=['pii:false', 'pci_compliant:true']) }}

select
    transaction_id,
    user_id,
    stripe_payment_intent_id,  -- Tokenized reference (safe)
    stripe_payment_method_id,  -- Tokenized reference (safe)
    card_last4,  -- Only last 4 digits (PCI-DSS compliant)
    card_brand,  -- Visa, Mastercard (safe)
    amount_usd,
    transaction_timestamp
from {{ source('stripe', 'charges') }}
-- NO raw card numbers stored in warehouse
```

### Custom Tokenization Server Pattern

```python
# services/tokenization_service.py
"""
Tokenization service for reversible PII masking.
Store token mappings in separate secure database.
"""

import hashlib
import secrets
from typing import Dict

class TokenizationService:
    def __init__(self, token_db_connection):
        self.token_db = token_db_connection

    def tokenize(self, pii_value: str, pii_type: str) -> str:
        """Replace PII with random token, store mapping securely."""
        # Generate random token
        token = f"tok_{secrets.token_urlsafe(16)}"

        # Store mapping in secure database (NOT data warehouse)
        self.token_db.execute("""
            INSERT INTO token_vault (token, pii_value, pii_type, created_at)
            VALUES (%s, %s, %s, NOW())
        """, (token, pii_value, pii_type))

        return token

    def detokenize(self, token: str, requesting_user: str) -> str:
        """Reverse token to original PII (requires authorization)."""
        # Audit detokenization request
        self.token_db.execute("""
            INSERT INTO detokenization_audit (token, requested_by, requested_at)
            VALUES (%s, %s, NOW())
        """, (token, requesting_user))

        # Retrieve original value
        result = self.token_db.execute("""
            SELECT pii_value FROM token_vault WHERE token = %s
        """, (token,))

        return result[0]['pii_value'] if result else None
```

## Pseudonymization (Hash with Salt)

### dbt Macro: Pseudonymize User ID

```sql
-- macros/pseudonymize.sql
{% macro pseudonymize(column_name, salt='splash_privacy_2025') %}
    sha2({{ column_name }} || '{{ salt }}', 256)
{% endmacro %}

-- Usage in model
select
    {{ pseudonymize('user_id') }} as user_hash,
    session_timestamp,
    pageviews,
    session_duration
from {{ source('segment', 'tracks') }}
```

### Keyed Pseudonymization (Reversible with Key)

```sql
-- Snowflake UDF for keyed pseudonymization
create or replace secure function pseudonymize_with_key(
    val string,
    key string
)
returns string
as $$
    sha2_hex(val || key)
$$;

-- Usage with externally managed key
select
    pseudonymize_with_key(user_id, '{{env_var("PSEUDONYM_KEY")}}') as user_pseudo_id,
    event_type,
    event_timestamp
from segment_raw.tracks;
```

## Anonymization (Irreversible)

### Generalization

```sql
-- Generalize quasi-identifiers to prevent re-identification
select
    left(zip_code, 3) as zip_prefix,  -- 12345 → 123
    date_trunc('year', birthdate) as birth_year,  -- 1990-05-15 → 1990-01-01
    case
        when age < 25 then '18-24'
        when age < 35 then '25-34'
        when age < 45 then '35-44'
        when age < 55 then '45-54'
        else '55+'
    end as age_range,
    count(*) as user_count
from {{ ref('stg_users') }}
group by 1, 2, 3
having count(*) >= 5;  -- K-anonymity (k=5)
```

### Data Suppression (Small Cell Removal)

```sql
-- Suppress rare combinations to prevent statistical disclosure
with demographic_groups as (
    select
        state,
        age_range,
        gender,
        count(*) as group_size
    from {{ ref('mart_user_demographics') }}
    group by state, age_range, gender
)

select
    state,
    age_range,
    gender,
    case
        when group_size < 5 then null  -- Suppress small cells
        else group_size
    end as user_count
from demographic_groups;
```

---

**Reference**: See `../reference/gdpr-compliance-checklist.md` and `pii-field-catalog.md` for implementation details.
