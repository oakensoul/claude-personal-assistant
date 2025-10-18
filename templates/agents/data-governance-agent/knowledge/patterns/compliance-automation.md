---
title: "Compliance Automation"
description: "Policy-as-code and automated governance workflows"
category: "patterns"
tags: [automation, policy-as-code, ci-cd, compliance]
last_updated: "2025-10-07"
---

# Compliance Automation

## dbt Test: PII Tagging Enforcement

```sql
-- tests/governance/assert_pii_models_tagged.sql
with pii_columns as (
    select table_name, column_name
    from information_schema.columns
    where lower(column_name) in ('email', 'phone', 'ssn', 'first_name', 'last_name')
),
model_tags as (
    select name, tags from dbt_models_metadata
)
select p.table_name, p.column_name
from pii_columns p
left join model_tags t on p.table_name = t.name
where not array_contains('pii:true'::variant, t.tags)
```

## GitHub Actions Compliance Check

```yaml
name: Governance Check
on: pull_request
jobs:
  compliance:
    runs-on: ubuntu-latest
    steps:
      - name: Scan for PII
        run: python scripts/scan_pii.py
      - name: Validate DDM Policies
        run: python scripts/validate_masking.py
```

## Snowflake Task: Access Review Alerts

```sql
create or replace task quarterly_access_review
    warehouse = governance_wh
    schedule = 'USING CRON 0 9 1 */3 * America/Los_Angeles'  -- Quarterly
as
select user_name, count(*) as pii_access_count
from prod.audit.fct_data_access
where pii_accessed_flag = true
    and access_timestamp >= dateadd(quarter, -1, current_date())
group by user_name
having count(*) > 1000;  -- Alert threshold
```
