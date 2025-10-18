---
title: "Snowflake Security Hardening"
description: "Snowflake-specific security configurations, best practices, and compliance settings"
category: "reference"
last_updated: "2025-10-07"
---

# Snowflake Security Hardening

## Network Security

### IP Allowlisting
```sql
-- Create network policy for production access (corporate VPN only)
CREATE NETWORK POLICY CORP_VPN_ONLY
  ALLOWED_IP_LIST = ('203.0.113.0/24', '198.51.100.0/24')  -- Corporate IP ranges
  BLOCKED_IP_LIST = ();

-- Apply to account
ALTER ACCOUNT SET NETWORK_POLICY = CORP_VPN_ONLY;

-- Allow specific users to bypass (e.g., dbt Cloud service account)
ALTER USER dbt_cloud_prod SET NETWORK_POLICY = '';
```

### MFA Enforcement
```sql
-- Require MFA for all users (Duo Security integration)
ALTER USER john.doe SET EXT_AUTHN_DUO = TRUE;
ALTER ACCOUNT SET SAML_IDENTITY_PROVIDER = '<Okta SAML config>';
```

## Access Control

### Recommended Role Hierarchy
```
ACCOUNTADMIN (break-glass only, 2-3 users)
  └── SECURITYADMIN (security team, 3-5 users)
        └── SYSADMIN (data engineers, 5-10 users)
              ├── DBT_SERVICE_ACCOUNT (service account, no inheritance)
              └── TRANSFORMER (dbt developers)
                    └── ANALYST (read-only to marts + core)
                          └── REPORTER (read-only to marts only)
```

### Data Masking for PII
```sql
CREATE MASKING POLICY MASK_EMAIL AS (val STRING) RETURNS STRING ->
  CASE
    WHEN CURRENT_ROLE() IN ('PII_ADMIN', 'COMPLIANCE_OFFICER') THEN val
    WHEN CURRENT_ROLE() IN ('FINANCE_ANALYST') THEN REGEXP_REPLACE(val, '@.*', '@***')
    ELSE '***@***.com'
  END;

ALTER TABLE PROD.FINANCE.DIM_USER
  MODIFY COLUMN EMAIL SET MASKING POLICY MASK_EMAIL;
```

## Encryption

```sql
-- Enable Tri-Secret Secure (customer-managed keys)
ALTER ACCOUNT SET ENCRYPTION = 'TRI_SECRET_SECURE';
ALTER ACCOUNT SET AWS_KMS_KEY_ARN = 'arn:aws:kms:us-east-1:123456789012:key/...';
```

## Monitoring

```sql
-- Audit failed login attempts (last 30 days)
SELECT user_name, reported_client_type, first_authentication_factor, error_message, COUNT(*) AS failed_attempts
FROM SNOWFLAKE.ACCOUNT_USAGE.LOGIN_HISTORY
WHERE is_success = 'NO'
  AND event_timestamp >= DATEADD(day, -30, CURRENT_TIMESTAMP())
GROUP BY 1, 2, 3, 4
ORDER BY failed_attempts DESC;
```
