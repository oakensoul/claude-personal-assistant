---
title: "Audit Log Schema Reference"
description: "Database schemas for audit tables and compliance reporting"
category: "reference"
tags: [audit, schema, compliance]
last_updated: "2025-10-07"
---

# Audit Log Schema Reference

## prod.audit.fct_data_access

```sql
create table prod.audit.fct_data_access (
    access_key varchar primary key,
    query_id varchar not null,
    user_name varchar not null,
    role_name varchar not null,
    query_type varchar,  -- SELECT, INSERT, UPDATE, DELETE
    execution_status varchar,  -- SUCCESS, FAIL
    table_name varchar,
    column_name varchar,
    pii_classification varchar,  -- DIRECT_PII, QUASI_IDENTIFIER, NON_PII
    access_timestamp timestamp_ntz not null,
    access_end_timestamp timestamp_ntz,
    duration_seconds number,
    rows_produced number,
    pii_accessed_flag boolean,
    audit_loaded_at timestamp_ntz default current_timestamp()
);
```

## prod.audit.data_subject_requests

```sql
create table prod.audit.data_subject_requests (
    request_id varchar primary key,
    user_id number not null,
    request_type varchar not null,  -- ACCESS, ERASURE, RECTIFICATION, PORTABILITY
    requested_at timestamp_ntz not null,
    requested_by varchar not null,  -- Email of requester
    status varchar not null,  -- PENDING, IN_PROGRESS, COMPLETED, REJECTED
    completed_at timestamp_ntz,
    response_data variant,  -- JSON export for access requests
    notes varchar
);
```

## prod.audit.data_deletion_log

```sql
create table prod.audit.data_deletion_log (
    deletion_id varchar primary key,
    user_id number not null,
    tables_deleted array,
    deleted_at timestamp_ntz not null,
    deleted_by varchar not null,
    reason varchar not null,  -- GDPR_ERASURE, RETENTION_POLICY, USER_REQUEST
    rows_deleted number,
    audit_checksum varchar  -- Hash of deleted data for verification
);
```

## Compliance Queries

```sql
-- GDPR Article 30: Processing activities report
select request_type, count(*) as request_count, avg(datediff(day, requested_at, completed_at)) as avg_days_to_complete
from prod.audit.data_subject_requests
where requested_at >= dateadd(year, -1, current_date())
group by request_type;

-- SOC2: Quarterly access review
select user_name, role_name, count(distinct table_name) as tables_accessed, sum(rows_produced) as total_rows
from prod.audit.fct_data_access
where pii_accessed_flag = true and access_timestamp >= dateadd(quarter, -1, current_date())
group by user_name, role_name
order by total_rows desc;
```
