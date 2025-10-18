---
title: "Audit Trail Architecture"
description: "Comprehensive logging frameworks, compliance reporting, and access tracking for Snowflake data warehouse"
category: "core-concepts"
tags:
  - audit-logging
  - compliance
  - monitoring
  - snowflake
  - access-control
last_updated: "2025-10-07"
---

# Audit Trail Architecture

## Purpose and Requirements

Audit trails provide evidence of compliance with regulatory requirements (GDPR, CCPA, SOC2) and enable security monitoring, forensic analysis, and accountability.

### Regulatory Requirements

**GDPR Article 30**: Records of Processing Activities

- Document all processing activities
- Include purposes, data categories, recipients, retention periods

**CCPA**: Transparency and Accountability

- Track data access and sharing with third parties
- Support data subject request fulfillment

**SOC2 CC6.1**: Logical and Physical Access Controls

- Log all access to sensitive systems and data
- Monitor and review access logs regularly
- Investigate anomalies and unauthorized access

### Business Requirements

1. **Security Monitoring**: Detect unauthorized access, data exfiltration
2. **Compliance Reporting**: Generate audit reports for regulators
3. **Forensic Analysis**: Investigate data breaches or policy violations
4. **User Accountability**: Track who accessed what data when and why
5. **Change Management**: Document all schema changes, permission grants

---

## Audit Logging Framework

### The 5 W's of Audit Logging

#### Who: User or service account performing the action

- User name, role name, authentication method
- Session ID for tracing multi-step operations

#### What: Action performed

- Query type (SELECT, INSERT, UPDATE, DELETE, GRANT, REVOKE)
- SQL text (full query for forensics)
- Objects accessed (database, schema, table, column)

#### When: Timestamp of the action

- UTC timestamp with millisecond precision
- Session start/end times
- Duration of long-running queries

#### Where: System and location

- Database, schema, table, column
- Warehouse used for compute
- Client IP address, application name

#### Why: Business justification (optional but recommended)

- Ticket ID or approval reference
- Business purpose (analytics, reporting, data science)
- Requested by (for delegated access)

---

## Snowflake Audit Data Sources

### 1. QUERY_HISTORY (Account Usage)

**Purpose**: Tracks all SQL statements executed in Snowflake account.

**Key Columns**:

- `QUERY_ID`: Unique identifier for each query
- `USER_NAME`: User who executed the query
- `ROLE_NAME`: Role used for execution
- `QUERY_TEXT`: Full SQL statement
- `EXECUTION_STATUS`: SUCCESS, FAIL, INCIDENT
- `START_TIME`, `END_TIME`: Query execution window
- `ROWS_PRODUCED`, `BYTES_SCANNED`: Data volume metrics
- `DATABASE_NAME`, `SCHEMA_NAME`: Target database/schema
- `WAREHOUSE_NAME`: Compute warehouse used

**Retention**: 365 days in ACCOUNT_USAGE, 7 days in INFORMATION_SCHEMA

**Example Query**:

```sql
-- Audit all queries accessing PII tables in last 30 days
select
    query_id,
    user_name,
    role_name,
    query_type,
    query_text,
    execution_status,
    start_time,
    end_time,
    rows_produced,
    database_name,
    schema_name
from snowflake.account_usage.query_history
where (
    query_text ilike '%dim_user%'
    or query_text ilike '%fct_wallet_transactions%'
)
    and start_time >= dateadd(day, -30, current_timestamp())
order by start_time desc;
```

### 2. ACCESS_HISTORY (Account Usage)

**Purpose**: Column-level access tracking for sensitive data.

**Key Columns**:

- `QUERY_ID`: Links to QUERY_HISTORY
- `USER_NAME`: User who accessed the data
- `DIRECT_OBJECTS_ACCESSED`: Tables/views directly queried
- `BASE_OBJECTS_ACCESSED`: Underlying tables (through views)
- `OBJECTS_MODIFIED`: Tables with INSERT/UPDATE/DELETE
- `QUERY_START_TIME`: When access occurred

**Retention**: 365 days

**Example Query**:

```sql
-- Column-level access to email addresses
select
    ah.query_id,
    ah.user_name,
    ah.query_start_time,
    qh.query_text,
    base_obj.value:objectName::string as table_name,
    col.value:columnName::string as column_name
from snowflake.account_usage.access_history ah
join snowflake.account_usage.query_history qh on ah.query_id = qh.query_id
cross join lateral flatten(input => ah.base_objects_accessed) base_obj
cross join lateral flatten(input => base_obj.value:columns) col
where col.value:columnName::string = 'EMAIL'
    and ah.query_start_time >= dateadd(day, -7, current_timestamp())
order by ah.query_start_time desc;
```

### 3. LOGIN_HISTORY (Account Usage)

**Purpose**: Track authentication events (successful and failed logins).

**Key Columns**:

- `USER_NAME`: User attempting login
- `EVENT_TIMESTAMP`: When login occurred
- `IS_SUCCESS`: TRUE/FALSE
- `ERROR_CODE`, `ERROR_MESSAGE`: Failure reason
- `CLIENT_IP`: Source IP address
- `REPORTED_CLIENT_TYPE`: SnowSQL, JDBC, ODBC, UI

**Retention**: 365 days

**Example Query**:

```sql
-- Failed login attempts (potential brute force)
select
    user_name,
    event_timestamp,
    client_ip,
    reported_client_type,
    error_code,
    error_message,
    count(*) over (
        partition by user_name, client_ip
        order by event_timestamp
        rows between 10 preceding and current row
    ) as failed_attempts_last_10
from snowflake.account_usage.login_history
where is_success = 'NO'
    and event_timestamp >= dateadd(hour, -1, current_timestamp())
order by event_timestamp desc;
```

### 4. GRANTS_TO_USERS / GRANTS_TO_ROLES (Account Usage)

**Purpose**: Track privilege changes (GRANT/REVOKE operations).

**Key Columns**:

- `CREATED_ON`: When grant was created
- `DELETED_ON`: When grant was revoked (NULL if active)
- `PRIVILEGE`: SELECT, INSERT, UPDATE, DELETE, OWNERSHIP, etc.
- `GRANTED_ON`: Object type (TABLE, VIEW, SCHEMA, DATABASE)
- `NAME`: Object name
- `GRANTEE_NAME`: User or role receiving privilege
- `GRANTED_BY`: User who granted privilege

**Retention**: 365 days (deleted grants retained)

**Example Query**:

```sql
-- Recent grants on PII tables
select
    created_on,
    privilege,
    granted_on,
    name as object_name,
    grantee_name,
    granted_by,
    deleted_on
from snowflake.account_usage.grants_to_users
where name ilike '%dim_user%'
    or name ilike '%fct_wallet_transactions%'
order by created_on desc;
```

### 5. SESSIONS (Account Usage)

**Purpose**: Track active and historical user sessions.

**Key Columns**:

- `SESSION_ID`: Unique session identifier
- `USER_NAME`: Session user
- `CREATED_ON`: Session start time
- `LAST_SUCCESS_LOGIN`: Most recent successful login
- `CLIENT_IP`: Source IP
- `CLIENT_APPLICATION_ID`: Application name

**Retention**: 365 days

---

## Audit Data Warehouse Design

### Centralized Audit Schema

Create dedicated schema for audit logs:

```sql
-- Create audit schema
create schema if not exists prod.audit;

-- Grant read access to compliance team
grant usage on schema prod.audit to role compliance_analyst;
grant select on all tables in schema prod.audit to role compliance_analyst;
grant select on future tables in schema prod.audit to role compliance_analyst;
```

### Audit Log Staging Models

#### dbt Staging Model: stg_snowflake__query_history

```sql
-- models/dwh/staging/audit/stg_snowflake__query_history.sql
{{
    config(
        materialized='incremental',
        unique_key='query_id',
        tags=[
            'group:shared',
            'layer:staging',
            'business:compliance',
            'access:restricted',
            'critical:true',
            'source:snowflake_metadata'
        ]
    )
}}

select
    query_id,
    query_text,
    database_name,
    schema_name,
    query_type,
    session_id,
    user_name,
    role_name,
    warehouse_name,
    warehouse_size,
    execution_status,
    error_code,
    error_message,
    start_time,
    end_time,
    total_elapsed_time,
    bytes_scanned,
    rows_produced,
    rows_inserted,
    rows_updated,
    rows_deleted,
    credits_used_cloud_services,
    compilation_time,
    execution_time,
    queued_provisioning_time,
    queued_repair_time,
    queued_overload_time,
    transaction_blocked_time,
    -- Governance metadata
    case
        when query_text ilike '%dim_user%' then true
        when query_text ilike '%email%' then true
        when query_text ilike '%phone%' then true
        else false
    end as accessed_pii,
    current_timestamp() as audit_loaded_at
from {{ source('snowflake', 'query_history') }}
{% if is_incremental() %}
where start_time > (select max(start_time) from {{ this }})
{% endif %}
```

#### dbt Staging Model: stg_snowflake__access_history

```sql
-- models/dwh/staging/audit/stg_snowflake__access_history.sql
{{
    config(
        materialized='incremental',
        unique_key='query_id',
        tags=[
            'group:shared',
            'layer:staging',
            'business:compliance',
            'access:restricted',
            'critical:true',
            'source:snowflake_metadata'
        ]
    )
}}

with base_objects as (
    select
        query_id,
        user_name,
        query_start_time,
        base_obj.value:objectDomain::string as object_domain,
        base_obj.value:objectName::string as object_name,
        col.value:columnName::string as column_name
    from {{ source('snowflake', 'access_history') }}
    cross join lateral flatten(input => base_objects_accessed) base_obj
    cross join lateral flatten(input => base_obj.value:columns) col
    {% if is_incremental() %}
    where query_start_time > (select max(query_start_time) from {{ this }})
    {% endif %}
)

select
    query_id,
    user_name,
    query_start_time,
    object_domain,
    object_name,
    column_name,
    -- Classify column sensitivity
    case
        when lower(column_name) in ('email', 'phone', 'ssn', 'credit_card_number') then 'DIRECT_PII'
        when lower(column_name) in ('user_id', 'birthdate', 'zip_code', 'ip_address') then 'QUASI_IDENTIFIER'
        else 'NON_PII'
    end as pii_classification,
    current_timestamp() as audit_loaded_at
from base_objects
```

### Audit Fact Table

#### Fact Table: fct_data_access

```sql
-- models/dwh/core/audit/fct_data_access.sql
{{
    config(
        materialized='incremental',
        unique_key='access_key',
        tags=[
            'group:shared',
            'layer:core',
            'pattern:fact_transaction',
            'business:compliance',
            'access:restricted',
            'retention:7_years'
        ]
    )
}}

with query_access as (
    select
        qh.query_id,
        qh.user_name,
        qh.role_name,
        qh.query_type,
        qh.execution_status,
        qh.start_time,
        qh.end_time,
        qh.rows_produced,
        qh.accessed_pii,
        ah.object_name,
        ah.column_name,
        ah.pii_classification
    from {{ ref('stg_snowflake__query_history') }} qh
    left join {{ ref('stg_snowflake__access_history') }} ah on qh.query_id = ah.query_id
    {% if is_incremental() %}
    where qh.start_time > (select max(access_timestamp) from {{ this }})
    {% endif %}
)

select
    {{ dbt_utils.generate_surrogate_key(['query_id', 'object_name', 'column_name']) }} as access_key,
    query_id,
    user_name,
    role_name,
    query_type,
    execution_status,
    object_name as table_name,
    column_name,
    pii_classification,
    start_time as access_timestamp,
    end_time as access_end_timestamp,
    datediff(second, start_time, end_time) as duration_seconds,
    rows_produced,
    accessed_pii as pii_accessed_flag,
    current_timestamp() as audit_loaded_at
from query_access
```

---

## Compliance Reporting

### GDPR Article 30: Records of Processing Activities

```sql
-- Report: Processing activities by purpose
select
    'Analytics' as processing_purpose,
    'User behavior analysis' as description,
    'Legitimate interest' as lawful_basis,
    'User activity logs, aggregated metrics' as data_categories,
    'Internal analytics team' as recipients,
    '90 days active, 1 year archive' as retention_period,
    'Encryption at rest, RBAC, audit logging' as security_measures
union all
select
    'Transaction Processing',
    'Payment and wallet management',
    'Contract performance',
    'User PII, payment details, transaction history',
    'Stripe (payment processor)',
    '7 years (financial records)',
    'Encryption, tokenization, SOC2 controls'
union all
select
    'Marketing',
    'Promotional campaigns and newsletters',
    'Consent',
    'Email, name, preferences',
    'SendGrid (email service)',
    'Until consent withdrawn',
    'Opt-out mechanism, consent tracking';
```

### CCPA: Data Inventory Report

```sql
-- Report: Personal information categories collected
select
    'Identifiers' as category,
    'Name, email, phone, user ID' as examples,
    'Account creation, transaction processing' as business_purpose,
    array_construct('Payment processors', 'Analytics platforms') as third_party_recipients
union all
select
    'Commercial information',
    'Transaction history, wallet balance',
    'Payment processing, fraud detection',
    array_construct('Payment processors', 'Fraud detection vendors')
union all
select
    'Internet activity',
    'Browsing history, app usage, clicks',
    'Product improvement, analytics',
    array_construct('Analytics platforms (Segment, Mixpanel)');
```

### SOC2 CC6.3: Access Review Report

```sql
-- Report: Quarterly access review for sensitive data
select
    user_name,
    role_name,
    count(distinct query_id) as queries_executed,
    count(distinct case when pii_accessed_flag then query_id end) as pii_queries,
    min(access_timestamp) as first_access,
    max(access_timestamp) as last_access,
    listagg(distinct table_name, ', ') within group (order by table_name) as tables_accessed
from prod.audit.fct_data_access
where access_timestamp >= dateadd(quarter, -1, current_date())
    and pii_classification in ('DIRECT_PII', 'QUASI_IDENTIFIER')
group by user_name, role_name
order by pii_queries desc;
```

---

## Monitoring and Alerting

### Real-Time Alerts

#### Alert 1: Unusual PII Access Volume

```sql
-- Alert if user accesses >1000 rows of PII in single query
select
    query_id,
    user_name,
    role_name,
    table_name,
    rows_produced,
    access_timestamp
from prod.audit.fct_data_access
where pii_accessed_flag = true
    and rows_produced > 1000
    and access_timestamp >= dateadd(hour, -1, current_timestamp())
order by rows_produced desc;
```

#### Alert 2: Failed Login Attempts (Brute Force)

```sql
-- Alert if >5 failed logins from same IP in 10 minutes
select
    user_name,
    client_ip,
    count(*) as failed_attempts,
    min(event_timestamp) as first_attempt,
    max(event_timestamp) as last_attempt
from snowflake.account_usage.login_history
where is_success = 'NO'
    and event_timestamp >= dateadd(minute, -10, current_timestamp())
group by user_name, client_ip
having count(*) >= 5
order by failed_attempts desc;
```

#### Alert 3: Privilege Escalation

```sql
-- Alert on grants to sensitive tables
select
    created_on,
    privilege,
    granted_on,
    name as object_name,
    grantee_name,
    granted_by
from snowflake.account_usage.grants_to_users
where name in ('DIM_USER', 'FCT_WALLET_TRANSACTIONS')
    and created_on >= dateadd(hour, -24, current_timestamp())
order by created_on desc;
```

### Dashboards

**Compliance Dashboard (Metabase/Tableau)**:

1. **PII Access Trends**: Daily volume of PII queries by user/role
2. **Failed Logins**: Geographic distribution and top offending IPs
3. **Top Data Consumers**: Users with highest query volume
4. **Privilege Changes**: Recent grants/revokes on sensitive tables
5. **Access Anomalies**: Unusual access patterns (time of day, data volume)

---

## Audit Trail Best Practices

### 1. Comprehensive Logging

- **Log Everything**: Query history, access history, login attempts, privilege changes
- **Column-Level Granularity**: Track which columns accessed (not just tables)
- **Retain Long-Term**: 7 years for financial/compliance (archive to S3/Glacier if needed)

### 2. Tamper-Proof Storage

- **Read-Only Access**: Audit logs should be immutable (no UPDATE/DELETE)
- **Separate Schema**: Isolate audit data from operational schemas
- **Restricted Permissions**: Only compliance/security roles can read audit logs

### 3. Regular Reviews

- **Quarterly Access Reviews**: Certify that users still need access
- **Anomaly Detection**: Investigate unusual patterns (volume, time, user)
- **Privilege Audits**: Validate least privilege principle

### 4. Integration with SIEM

- **Export to SIEM**: Stream logs to Splunk, Datadog, or CloudWatch
- **Correlation**: Cross-reference with application logs, network logs
- **Automated Response**: Trigger alerts, lock accounts, escalate to security team

### 5. Documentation

- **Audit Policy**: Document what is logged, retention periods, access controls
- **Incident Response**: Procedures for investigating security events
- **Compliance Mapping**: Map audit logs to regulatory requirements (GDPR, CCPA, SOC2)

---

## Example: Data Subject Request Audit Trail

When user requests data deletion (GDPR Right to Erasure):

### Step 1: Log the Request

```sql
insert into prod.audit.data_subject_requests (
    request_id, user_id, request_type, requested_at, requested_by, status
) values (
    uuid_string(), 12345, 'ERASURE', current_timestamp(), 'support@splash.com', 'PENDING'
);
```

### Step 2: Execute Deletion and Log

```sql
begin transaction;

-- Delete user data
delete from prod.finance.fct_wallet_transactions where user_id = 12345;
delete from prod.contests.fct_contest_entries where user_id = 12345;
delete from prod.finance.dim_user where user_id = 12345;

-- Log deletion
insert into prod.audit.data_deletion_log (
    deletion_id, user_id, tables_deleted, deleted_at, deleted_by, reason, rows_deleted
) values (
    uuid_string(), 12345,
    array_construct('fct_wallet_transactions', 'fct_contest_entries', 'dim_user'),
    current_timestamp(), current_user(), 'GDPR erasure request', 347
);

-- Update request status
update prod.audit.data_subject_requests
set status = 'COMPLETED', completed_at = current_timestamp()
where user_id = 12345 and request_type = 'ERASURE';

commit;
```

### Step 3: Generate Audit Report

```sql
-- Confirm deletion and provide audit trail
select
    r.request_id,
    r.user_id,
    r.request_type,
    r.requested_at,
    r.completed_at,
    d.tables_deleted,
    d.rows_deleted,
    d.deleted_by
from prod.audit.data_subject_requests r
join prod.audit.data_deletion_log d on r.user_id = d.user_id
where r.user_id = 12345;
```

---

## Next Steps

1. **Read**: `privacy-engineering.md` for PIA process and privacy-by-design
2. **Read**: `../patterns/compliance-automation.md` for policy-as-code and automated audits
3. **Implement**: Create audit schema and staging models for Snowflake account usage
4. **Configure**: Set up real-time alerts for unusual PII access
5. **Coordinate**: Work with devops-engineer for SIEM integration
