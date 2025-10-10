---
title: "PII Field Catalog for Splash Sports"
description: "Comprehensive inventory of PII fields across all data sources"
category: "reference"
tags: [pii, catalog, inventory]
last_updated: "2025-10-07"
---

# PII Field Catalog

## splash_production.users

| Column | PII Type | Sensitivity | Treatment |
|--------|----------|-------------|-----------|
| user_id | Quasi-Identifier | Restricted | Pseudonymize in analytics |
| email | Direct Identifier | Restricted | DDM masking policy |
| phone | Direct Identifier | Restricted | DDM masking policy |
| first_name | Direct Identifier | Restricted | DDM masking policy |
| last_name | Direct Identifier | Restricted | DDM masking policy |
| birthdate | Quasi-Identifier | Confidential | Generalize to year in marts |
| zip_code | Quasi-Identifier | Internal | Generalize to 3-digit prefix |
| ip_address | Quasi-Identifier | Internal | Hash or exclude |
| created_at | Non-PII | Internal | No masking |

## segment.tracks

| Column | PII Type | Sensitivity | Treatment |
|--------|----------|-------------|-----------|
| user_id | Quasi-Identifier | Restricted | Links to users table |
| anonymous_id | Quasi-Identifier | Internal | Cookie-based identifier |
| context_ip | Quasi-Identifier | Internal | Hash before storing |
| context_device_id | Quasi-Identifier | Internal | Hash if stored |
| event_name | Non-PII | Internal | No PII |
| event_properties | **Potential PII** | Internal | Scan for embedded PII |

## intercom.conversations

| Column | PII Type | Sensitivity | Treatment |
|--------|----------|-------------|-----------|
| user_email | Direct Identifier | Restricted | DDM masking |
| user_name | Direct Identifier | Restricted | DDM masking |
| conversation_text | **Potential PII** | Restricted | NLP scan for SSN, cards, etc. |
| support_agent_email | Direct Identifier | Internal | Internal staff, no masking |

## Masking Policy Assignment

```sql
-- Apply to all direct PII columns
alter table prod.finance.dim_user modify column email set masking policy prod.governance.pii_email_mask;
alter table prod.finance.dim_user modify column phone set masking policy prod.governance.pii_phone_mask;
alter table prod.finance.dim_user modify column first_name set masking policy prod.governance.pii_name_mask;
alter table prod.finance.dim_user modify column last_name set masking policy prod.governance.pii_name_mask;
```
