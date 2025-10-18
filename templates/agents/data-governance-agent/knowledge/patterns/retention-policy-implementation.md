---
title: "Retention Policy Implementation"
description: "Automated data lifecycle management and retention enforcement"
category: "patterns"
tags: [retention, lifecycle, automation, compliance]
last_updated: "2025-10-07"
---

# Retention Policy Implementation

## dbt Incremental Model with Retention

```sql
{{ config(
    materialized='incremental',
    unique_key='event_id',
    tags=['retention:90_days', 'pii:true']
) }}

select *
from {{ source('segment', 'tracks') }}
where event_timestamp >= current_date - interval '90 days'
{% if is_incremental() %}
    and event_timestamp > (select max(event_timestamp) from {{ this }})
{% endif %}
```

## Snowflake Retention Enforcement

```sql
-- Automated deletion task
create or replace task prod.governance.purge_old_events
    warehouse = governance_wh
    schedule = 'USING CRON 0 2 * * SUN America/Los_Angeles'  -- Weekly Sunday 2am
as
delete from prod.analytics.fct_user_events
where event_timestamp < current_date - interval '90 days';

-- Enable task
alter task prod.governance.purge_old_events resume;
```

## Retention Standards

- **Transaction Data**: 7 years (financial compliance)
- **User Activity Logs**: 90 days active, 1 year archive
- **PII**: Minimum necessary + GDPR right-to-be-forgotten
- **Audit Logs**: 7 years (SOC2 compliance)
