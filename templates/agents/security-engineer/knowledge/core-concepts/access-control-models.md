---
title: "Access Control Models"
description: "RBAC, ABAC, least privilege principles, identity management, and access control patterns for data platforms"
category: "core-concepts"
tags:
  - rbac
  - abac
  - access-control
  - identity-management
  - least-privilege
last_updated: "2025-10-07"
---

# Access Control Models

Comprehensive guide to access control models (RBAC, ABAC), least privilege principles, and identity management for cloud data platforms.

## Access Control Fundamentals

### Core Principles
1. **Least Privilege**: Grant minimum necessary permissions for job function
2. **Separation of Duties**: Divide critical tasks among multiple users
3. **Defense in Depth**: Multiple layers of access control (network + application + data)
4. **Zero Trust**: Never trust, always verify (authenticate and authorize every request)

### Access Control Models
- **DAC (Discretionary Access Control)**: Resource owner controls access (file permissions)
- **MAC (Mandatory Access Control)**: System enforces access based on classification (Top Secret, Confidential)
- **RBAC (Role-Based Access Control)**: Permissions assigned to roles, users assigned to roles
- **ABAC (Attribute-Based Access Control)**: Dynamic permissions based on user/resource attributes

## Role-Based Access Control (RBAC)

### RBAC Principles
RBAC is the most common access control model for data platforms, assigning permissions to roles instead of individual users.

**Key Components**:
1. **Users**: Individual identities (humans or service accounts)
2. **Roles**: Named collections of permissions (ANALYST, DATA_ENGINEER, ADMIN)
3. **Permissions**: Specific actions on resources (SELECT, INSERT, CREATE TABLE)
4. **Role Hierarchies**: Roles can inherit from parent roles (SENIOR_ANALYST inherits from ANALYST)

**Benefits**:
- Simplified permission management (update role, not individual users)
- Easier onboarding/offboarding (assign/revoke role membership)
- Clear audit trail (who has which role)
- Supports least privilege (assign minimum necessary role)

### Snowflake RBAC Implementation

#### Role Hierarchy Design
```sql
-- Create role hierarchy for dbt-splash-prod-v2 project
-- Hierarchy: SYSADMIN > TRANSFORMER > ANALYST > REPORTER

-- 1. REPORTER: Read-only access to marts layer
CREATE ROLE REPORTER;
GRANT USAGE ON DATABASE PROD TO ROLE REPORTER;
GRANT USAGE ON SCHEMA PROD.FINANCE_MARTS TO ROLE REPORTER;
GRANT SELECT ON ALL TABLES IN SCHEMA PROD.FINANCE_MARTS TO ROLE REPORTER;
GRANT SELECT ON ALL VIEWS IN SCHEMA PROD.FINANCE_MARTS TO ROLE REPORTER;
GRANT SELECT ON FUTURE TABLES IN SCHEMA PROD.FINANCE_MARTS TO ROLE REPORTER;
GRANT SELECT ON FUTURE VIEWS IN SCHEMA PROD.FINANCE_MARTS TO ROLE REPORTER;

-- 2. ANALYST: Read access to marts + core layer (facts/dimensions)
CREATE ROLE ANALYST;
GRANT ROLE REPORTER TO ROLE ANALYST;  -- Inherit REPORTER permissions
GRANT USAGE ON SCHEMA PROD.FINANCE TO ROLE ANALYST;
GRANT SELECT ON ALL TABLES IN SCHEMA PROD.FINANCE TO ROLE ANALYST;
GRANT SELECT ON ALL VIEWS IN SCHEMA PROD.FINANCE TO ROLE ANALYST;
GRANT SELECT ON FUTURE TABLES IN SCHEMA PROD.FINANCE TO ROLE ANALYST;

-- 3. TRANSFORMER: Read/write access for dbt model development
CREATE ROLE TRANSFORMER;
GRANT ROLE ANALYST TO ROLE TRANSFORMER;  -- Inherit ANALYST permissions
GRANT USAGE ON WAREHOUSE TRANSFORMING TO ROLE TRANSFORMER;
GRANT USAGE ON DATABASE SANDBOX_DEV TO ROLE TRANSFORMER;  -- Dev sandbox
GRANT ALL ON SCHEMA SANDBOX_DEV.FINANCE_STAGING TO ROLE TRANSFORMER;
GRANT ALL ON SCHEMA SANDBOX_DEV.FINANCE TO ROLE TRANSFORMER;
GRANT ALL ON SCHEMA SANDBOX_DEV.FINANCE_MARTS TO ROLE TRANSFORMER;
GRANT CREATE SCHEMA ON DATABASE SANDBOX_DEV TO ROLE TRANSFORMER;

-- 4. DBT_SERVICE_ACCOUNT: Automated dbt Cloud builds in production
CREATE ROLE DBT_SERVICE_ACCOUNT;
GRANT USAGE ON WAREHOUSE TRANSFORMING TO ROLE DBT_SERVICE_ACCOUNT;
GRANT USAGE ON DATABASE PROD TO ROLE DBT_SERVICE_ACCOUNT;
GRANT ALL ON SCHEMA PROD.FINANCE_STAGING TO ROLE DBT_SERVICE_ACCOUNT;
GRANT ALL ON SCHEMA PROD.FINANCE TO ROLE DBT_SERVICE_ACCOUNT;
GRANT ALL ON SCHEMA PROD.FINANCE_MARTS TO ROLE DBT_SERVICE_ACCOUNT;
-- No inherited roles (service account should have minimal, explicit permissions)

-- 5. SYSADMIN: Full admin access (inherited by default)
GRANT ROLE TRANSFORMER TO ROLE SYSADMIN;  -- Admins can do everything
```

#### Functional Role Patterns
```sql
-- Finance Domain Roles
CREATE ROLE FINANCE_ANALYST;
GRANT USAGE ON DATABASE PROD TO ROLE FINANCE_ANALYST;
GRANT USAGE ON SCHEMA PROD.FINANCE_MARTS TO ROLE FINANCE_ANALYST;
GRANT SELECT ON ALL TABLES IN SCHEMA PROD.FINANCE_MARTS TO ROLE FINANCE_ANALYST;
GRANT SELECT ON ALL VIEWS IN SCHEMA PROD.FINANCE_MARTS TO ROLE FINANCE_ANALYST;

-- Product Analytics Roles
CREATE ROLE PRODUCT_ANALYST;
GRANT USAGE ON DATABASE PROD TO ROLE PRODUCT_ANALYST;
GRANT USAGE ON SCHEMA PROD.ANALYTICS_MARTS TO ROLE PRODUCT_ANALYST;
GRANT SELECT ON ALL TABLES IN SCHEMA PROD.ANALYTICS_MARTS TO ROLE PRODUCT_ANALYST;

-- Operations Roles (limited to operations domain)
CREATE ROLE OPERATIONS_ENGINEER;
GRANT USAGE ON DATABASE PROD TO ROLE OPERATIONS_ENGINEER;
GRANT USAGE ON SCHEMA PROD.OPERATIONS TO ROLE OPERATIONS_ENGINEER;
GRANT SELECT ON ALL TABLES IN SCHEMA PROD.OPERATIONS TO ROLE OPERATIONS_ENGINEER;
GRANT USAGE ON SCHEMA PROD.OPERATIONS_STAGING TO ROLE OPERATIONS_ENGINEER;
GRANT SELECT ON ALL TABLES IN SCHEMA PROD.OPERATIONS_STAGING TO ROLE OPERATIONS_ENGINEER;
```

#### Time-Bound Access (Just-In-Time)
```sql
-- Grant temporary elevated access for incident response
-- MANUAL PROCESS (requires ACCOUNTADMIN or SECURITYADMIN role)

-- Step 1: Grant elevated role to user
GRANT ROLE SYSADMIN TO USER john.doe;

-- Step 2: Document access grant in audit log
INSERT INTO SECURITY_AUDIT_LOG (user_name, granted_role, reason, granted_by, granted_at, expires_at)
VALUES ('john.doe', 'SYSADMIN', 'Incident Response: DA-500', 'security_admin', CURRENT_TIMESTAMP(), DATEADD(hour, 8, CURRENT_TIMESTAMP()));

-- Step 3: Set reminder to revoke access after 8 hours
-- (Automated via cron job or Lambda function)

-- Step 4: Revoke access after incident is resolved
REVOKE ROLE SYSADMIN FROM USER john.doe;

-- Audit query: Find users with elevated access granted >24 hours ago
SELECT user_name, granted_role, granted_at, expires_at
FROM SECURITY_AUDIT_LOG
WHERE expires_at < CURRENT_TIMESTAMP()
  AND revoked_at IS NULL;
```

### Metabase RBAC Implementation

#### Metabase Group Permissions
```yaml
# Metabase Groups and Permissions Configuration
# (Configured via Metabase Admin UI or API)

Groups:
  - Name: "Finance Analysts"
    Database_Access:
      - Database: "Snowflake - Production"
        Schemas:
          - Schema: "FINANCE_MARTS"
            Tables: "All"
            Access_Level: "Unrestricted"  # Can query all tables
          - Schema: "FINANCE"
            Tables: "All"
            Access_Level: "Unrestricted"  # Can access facts/dimensions
    Dashboard_Access:
      - Collection: "Finance"
        Access_Level: "View"  # Can view but not edit dashboards

  - Name: "Finance Admins"
    Database_Access:
      - Database: "Snowflake - Production"
        Schemas:
          - Schema: "FINANCE_MARTS"
            Tables: "All"
            Access_Level: "Unrestricted"
          - Schema: "FINANCE"
            Tables: "All"
            Access_Level: "Unrestricted"
          - Schema: "FINANCE_STAGING"
            Tables: "All"
            Access_Level: "Unrestricted"
    Dashboard_Access:
      - Collection: "Finance"
        Access_Level: "Curate"  # Can create/edit dashboards

  - Name: "Executives"
    Database_Access:
      - Database: "Snowflake - Production"
        Schemas:
          - Schema: "FINANCE_MARTS"
            Tables: "Specific"  # Only approved executive dashboards
            Access_Level: "No self-service"  # Cannot write SQL queries
    Dashboard_Access:
      - Collection: "Executive Dashboards"
        Access_Level: "View"  # View-only access

  - Name: "Data Engineers"
    Database_Access:
      - Database: "Snowflake - Production"
        Schemas: "All"
        Tables: "All"
        Access_Level: "Unrestricted"  # Full query access
      - Database: "Snowflake - Sandbox"
        Schemas: "All"
        Tables: "All"
        Access_Level: "Unrestricted"
    Dashboard_Access:
      - Collection: "All"
        Access_Level: "Curate"  # Can create/edit all dashboards
```

#### Row-Level Security (RLS) in Metabase
```sql
-- Metabase Sandboxing: Restrict data access based on user attributes
-- Example: Finance analysts can only see data for their assigned region

-- In Metabase Admin UI:
-- 1. Navigate to Admin > Permissions > Data Sandboxing
-- 2. Select "Finance Analysts" group
-- 3. Choose "FINANCE_MARTS" schema
-- 4. Configure sandboxing rule:

-- Sandboxing Rule for Regional Access
{
  "card_id": null,
  "table_id": "FINANCE_MARTS.MART_DAILY_REVENUE",
  "attribute_remappings": {
    "user_region": ["dimension", ["field-id", "REGION"]]
  }
}

-- User john.doe has user_region = "US_WEST"
-- When john.doe queries MART_DAILY_REVENUE, Metabase automatically appends:
-- WHERE REGION = 'US_WEST'

-- Result: John only sees US_WEST revenue data, not global data
```

### AWS IAM RBAC

#### IAM Role for Snowflake Integration
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowSnowflakeS3Access",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:ListBucket",
        "s3:GetBucketLocation"
      ],
      "Resource": [
        "arn:aws:s3:::dbt-splash-data-lake",
        "arn:aws:s3:::dbt-splash-data-lake/*"
      ]
    },
    {
      "Sid": "AllowKMSDecryptForS3",
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt",
        "kms:DescribeKey"
      ],
      "Resource": "arn:aws:kms:us-east-1:123456789012:key/abcd1234-...",
      "Condition": {
        "StringEquals": {
          "kms:ViaService": "s3.us-east-1.amazonaws.com"
        }
      }
    }
  ]
}
```

#### IAM Role for dbt Cloud Service Account
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowSecretsManagerAccess",
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": [
        "arn:aws:secretsmanager:us-east-1:123456789012:secret:dbt-cloud/snowflake-credentials-*"
      ]
    },
    {
      "Sid": "AllowS3ReadForDbtArtifacts",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::dbt-artifacts",
        "arn:aws:s3:::dbt-artifacts/*"
      ]
    }
  ]
}
```

## Attribute-Based Access Control (ABAC)

### ABAC Principles
ABAC grants access based on attributes of the user, resource, and environment (context).

**Attributes**:
- **User Attributes**: Department, job title, clearance level, location
- **Resource Attributes**: Data classification (public, confidential, PII), domain (finance, operations)
- **Environment Attributes**: Time of day, IP address, device type, MFA status

**Example Policy**:
```text
Allow access to PII data IF:
  - User has "data_steward" role
  - Request originates from corporate VPN (IP allowlist)
  - User has completed MFA within last 8 hours
  - Current time is between 6 AM - 10 PM (business hours)
```

### Snowflake ABAC with Tags

#### Tag-Based Access Control (TBAC)
```sql
-- Create tags for data classification
CREATE TAG DATA_CLASSIFICATION ALLOWED_VALUES 'PUBLIC', 'INTERNAL', 'CONFIDENTIAL', 'PII';
CREATE TAG DATA_DOMAIN ALLOWED_VALUES 'FINANCE', 'OPERATIONS', 'ANALYTICS', 'COMPLIANCE';

-- Apply tags to tables
ALTER TABLE PROD.FINANCE.FCT_WALLET_TRANSACTIONS
  SET TAG DATA_CLASSIFICATION = 'CONFIDENTIAL', DATA_DOMAIN = 'FINANCE';

ALTER TABLE PROD.FINANCE.DIM_USER
  SET TAG DATA_CLASSIFICATION = 'PII', DATA_DOMAIN = 'FINANCE';

ALTER TABLE PROD.FINANCE_MARTS.MART_DAILY_REVENUE
  SET TAG DATA_CLASSIFICATION = 'INTERNAL', DATA_DOMAIN = 'FINANCE';

-- Create masking policy for PII data
CREATE MASKING POLICY MASK_PII AS (val STRING) RETURNS STRING ->
  CASE
    WHEN CURRENT_ROLE() IN ('PII_ADMIN', 'COMPLIANCE_OFFICER') THEN val
    WHEN CURRENT_ROLE() IN ('FINANCE_ANALYST') THEN REGEXP_REPLACE(val, '.{4}$', '****')  -- Mask last 4 chars
    ELSE '***REDACTED***'
  END;

-- Apply masking policy to PII columns
ALTER TABLE PROD.FINANCE.DIM_USER
  MODIFY COLUMN EMAIL SET MASKING POLICY MASK_PII;

ALTER TABLE PROD.FINANCE.DIM_USER
  MODIFY COLUMN PHONE_NUMBER SET MASKING POLICY MASK_PII;

-- Row access policy based on data domain
CREATE ROW ACCESS POLICY FINANCE_DOMAIN_ACCESS AS (DATA_DOMAIN STRING) RETURNS BOOLEAN ->
  CASE
    WHEN CURRENT_ROLE() IN ('SYSADMIN', 'SECURITYADMIN') THEN TRUE
    WHEN CURRENT_ROLE() IN ('FINANCE_ANALYST', 'FINANCE_ADMIN') AND DATA_DOMAIN = 'FINANCE' THEN TRUE
    ELSE FALSE
  END;

-- Apply row access policy
ALTER TABLE PROD.FINANCE.FCT_WALLET_TRANSACTIONS
  ADD ROW ACCESS POLICY FINANCE_DOMAIN_ACCESS ON (DATA_DOMAIN);
```

### AWS IAM ABAC with Tags

#### IAM Policy with Tag-Based Conditions
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowAccessBasedOnResourceTags",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": "arn:aws:s3:::dbt-splash-data-lake/*",
      "Condition": {
        "StringEquals": {
          "s3:ExistingObjectTag/DataClassification": "Internal",
          "s3:ExistingObjectTag/Department": "${aws:PrincipalTag/Department}"
        }
      }
    },
    {
      "Sid": "DenyAccessToPIIWithoutMFA",
      "Effect": "Deny",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::dbt-splash-data-lake/*",
      "Condition": {
        "StringEquals": {
          "s3:ExistingObjectTag/DataClassification": "PII"
        },
        "BoolIfExists": {
          "aws:MultiFactorAuthPresent": "false"
        }
      }
    }
  ]
}
```

## Least Privilege Implementation

### Snowflake Least Privilege Checklist
- [ ] Users have only the roles required for their job function (no ACCOUNTADMIN/SYSADMIN for analysts)
- [ ] Service accounts have explicit permissions (no role inheritance)
- [ ] Read-only roles for reporting users (REPORTER, ANALYST)
- [ ] Separate roles for dev/staging/prod environments (TRANSFORMER_DEV, TRANSFORMER_PROD)
- [ ] Time-bound access for elevated privileges (max 8 hours, documented justification)
- [ ] Future grants prevent permission gaps (`GRANT SELECT ON FUTURE TABLES...`)
- [ ] Network policies restrict access by IP address (VPN required for production)
- [ ] MFA required for all human users accessing production

### Metabase Least Privilege Checklist
- [ ] Executives have no self-service SQL access (dashboard view-only)
- [ ] Analysts have read-only database access (cannot CREATE/DROP tables)
- [ ] Data engineers have full access but in separate sandbox environment
- [ ] Row-level security (RLS) applied for multi-tenant data (regional restrictions)
- [ ] API tokens have minimal scopes (read-only for monitoring, write for automation)
- [ ] Dashboard collections have explicit group permissions (not "Public")
- [ ] Sensitive dashboards require additional approval (PII, financials)

### Service Account Least Privilege
```sql
-- dbt Cloud Service Account (production builds only)
CREATE USER DBT_CLOUD_PROD
  PASSWORD = '...'  -- Rotate every 90 days
  DEFAULT_ROLE = DBT_SERVICE_ACCOUNT
  DEFAULT_WAREHOUSE = TRANSFORMING
  MUST_CHANGE_PASSWORD = FALSE;

GRANT ROLE DBT_SERVICE_ACCOUNT TO USER DBT_CLOUD_PROD;

-- Airbyte Service Account (read source, write staging only)
CREATE USER AIRBYTE_LOADER
  PASSWORD = '...'
  DEFAULT_ROLE = AIRBYTE_LOADER
  DEFAULT_WAREHOUSE = LOADING
  MUST_CHANGE_PASSWORD = FALSE;

GRANT USAGE ON WAREHOUSE LOADING TO ROLE AIRBYTE_LOADER;
GRANT USAGE ON DATABASE PROD TO ROLE AIRBYTE_LOADER;
GRANT ALL ON SCHEMA PROD.FINANCE_STAGING TO ROLE AIRBYTE_LOADER;
-- No access to FINANCE or FINANCE_MARTS schemas (only staging layer)

-- Metabase Service Account (read-only access to marts)
CREATE USER METABASE_READER
  PASSWORD = '...'
  DEFAULT_ROLE = METABASE_READER
  DEFAULT_WAREHOUSE = REPORTING
  MUST_CHANGE_PASSWORD = FALSE;

GRANT USAGE ON WAREHOUSE REPORTING TO ROLE METABASE_READER;
GRANT USAGE ON DATABASE PROD TO ROLE METABASE_READER;
GRANT USAGE ON SCHEMA PROD.FINANCE_MARTS TO ROLE METABASE_READER;
GRANT SELECT ON ALL TABLES IN SCHEMA PROD.FINANCE_MARTS TO ROLE METABASE_READER;
GRANT SELECT ON ALL VIEWS IN SCHEMA PROD.FINANCE_MARTS TO ROLE METABASE_READER;
-- No write permissions, no access to staging/core layers
```

## Identity Management

### Single Sign-On (SSO) Integration

#### Snowflake SSO with Okta (SAML 2.0)
```sql
-- Configure Snowflake as Service Provider (SP) for Okta
ALTER ACCOUNT SET SAML_IDENTITY_PROVIDER = '{
  "certificate": "<X.509 certificate from Okta>",
  "ssoUrl": "https://splash.okta.com/app/snowflake/abc123/sso/saml",
  "type": "OKTA",
  "issuer": "http://www.okta.com/abc123"
}';

-- Enable SAML for specific users
ALTER USER john.doe SET EXT_AUTHN_DUO = FALSE, SAML_IDENTITY = 'john.doe@splash.com';

-- View SAML configuration
SHOW PARAMETERS LIKE 'SAML%' IN ACCOUNT;
```

#### Metabase SSO with Okta (SAML 2.0)
```bash
# Metabase environment variables for SAML SSO
MB_SAML_ENABLED=true
MB_SAML_IDENTITY_PROVIDER_URI="https://splash.okta.com/app/metabase/abc123/sso/saml"
MB_SAML_IDENTITY_PROVIDER_CERTIFICATE="<X.509 certificate>"
MB_SAML_APPLICATION_NAME="Metabase - dbt-splash-prod-v2"
MB_SAML_ATTRIBUTE_EMAIL="email"
MB_SAML_ATTRIBUTE_FIRSTNAME="firstName"
MB_SAML_ATTRIBUTE_LASTNAME="lastName"
MB_SAML_GROUP_SYNC=true
MB_SAML_GROUP_MAPPINGS='{"Finance Analysts": [1], "Data Engineers": [2]}'
```

### Multi-Factor Authentication (MFA)

#### Snowflake MFA with Duo Security
```sql
-- Enable MFA for all users in production
ALTER USER john.doe SET EXT_AUTHN_DUO = TRUE;
ALTER USER jane.smith SET EXT_AUTHN_DUO = TRUE;

-- Configure Duo Security integration
ALTER ACCOUNT SET EXT_AUTHN_DUO_INTEGRATION = 'DUO_SECURITY_PROD';

-- View MFA status for users
SELECT user_name, ext_authn_duo, disabled
FROM SNOWFLAKE.ACCOUNT_USAGE.USERS
WHERE deleted_on IS NULL;
```

#### Time-Based One-Time Password (TOTP)
```bash
# Google Authenticator, Authy, or 1Password for TOTP
# User scans QR code during Snowflake login
# Enters 6-digit code every login (or remember device for 30 days)
```

## Access Control Auditing

### Snowflake Access History
```sql
-- Query access history for sensitive tables (last 30 days)
SELECT
    query_id,
    query_text,
    user_name,
    role_name,
    direct_objects_accessed,
    base_objects_accessed,
    objects_modified,
    start_time,
    end_time,
    execution_status
FROM SNOWFLAKE.ACCOUNT_USAGE.ACCESS_HISTORY
WHERE ARRAY_CONTAINS('PROD.FINANCE.DIM_USER'::VARIANT, base_objects_accessed)
  AND start_time >= DATEADD(day, -30, CURRENT_TIMESTAMP())
ORDER BY start_time DESC;

-- Find users who accessed PII data
SELECT
    user_name,
    COUNT(*) AS access_count,
    MAX(start_time) AS last_access
FROM SNOWFLAKE.ACCOUNT_USAGE.ACCESS_HISTORY
WHERE ARRAY_CONTAINS('PROD.FINANCE.DIM_USER'::VARIANT, base_objects_accessed)
  AND start_time >= DATEADD(day, -90, CURRENT_TIMESTAMP())
GROUP BY user_name
ORDER BY access_count DESC;
```

### Snowflake Grants Audit
```sql
-- Review all grants for a specific role
SHOW GRANTS TO ROLE FINANCE_ANALYST;

-- Find users with ACCOUNTADMIN role (highest privilege)
SHOW GRANTS OF ROLE ACCOUNTADMIN;

-- Find all roles granted to a user
SHOW GRANTS TO USER john.doe;

-- Identify stale users (no login in last 90 days)
SELECT
    name AS user_name,
    last_success_login,
    disabled,
    DATEDIFF(day, last_success_login, CURRENT_TIMESTAMP()) AS days_since_login
FROM SNOWFLAKE.ACCOUNT_USAGE.USERS
WHERE deleted_on IS NULL
  AND disabled = FALSE
  AND (last_success_login IS NULL OR last_success_login < DATEADD(day, -90, CURRENT_TIMESTAMP()));
```

### Metabase Audit Logging
```sql
-- Metabase audit log (stored in Metabase application database)
SELECT
    u.email,
    a.model,
    a.model_id,
    a.details,
    a.timestamp
FROM audit_log a
JOIN core_user u ON a.user_id = u.id
WHERE a.model = 'Card'  -- Dashboard queries
  AND a.timestamp >= NOW() - INTERVAL '30 days'
ORDER BY a.timestamp DESC
LIMIT 100;

-- Find users who accessed sensitive dashboards
SELECT
    u.email,
    COUNT(*) AS access_count,
    MAX(a.timestamp) AS last_access
FROM audit_log a
JOIN core_user u ON a.user_id = u.id
WHERE a.model = 'Card'
  AND a.model_id IN (123, 456, 789)  -- Sensitive dashboard IDs
  AND a.timestamp >= NOW() - INTERVAL '90 days'
GROUP BY u.email
ORDER BY access_count DESC;
```

## Further Reading

- [NIST RBAC Model](https://csrc.nist.gov/projects/role-based-access-control)
- [Snowflake Access Control](https://docs.snowflake.com/en/user-guide/security-access-control)
- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [OWASP Access Control Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Access_Control_Cheat_Sheet.html)
