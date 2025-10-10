---
title: "Secret Management Patterns"
description: "HashiCorp Vault, AWS Secrets Manager, secret rotation strategies, and credential lifecycle management"
category: "patterns"
tags:
  - secrets-management
  - vault
  - aws-secrets-manager
  - credential-rotation
last_updated: "2025-10-07"
---

# Secret Management Patterns

Comprehensive patterns for managing secrets (API keys, database passwords, certificates) using HashiCorp Vault and AWS Secrets Manager.

## Secret Management Principles

1. **Never Hardcode Secrets**: No secrets in code, config files, or environment variables
2. **Centralized Storage**: Single source of truth for all secrets
3. **Automated Rotation**: Regular rotation without downtime
4. **Least Privilege Access**: Minimum necessary permissions to retrieve secrets
5. **Audit Logging**: Track all secret access and modifications

## AWS Secrets Manager Patterns

### Pattern 1: Database Credentials with Automatic Rotation

```bash
# Create secret for Snowflake service account
aws secretsmanager create-secret \
  --name dbt-cloud/snowflake-credentials \
  --description "Snowflake credentials for dbt Cloud service account" \
  --secret-string '{
    "username": "dbt_cloud_prod",
    "password": "initial_password_123",
    "account": "xyz12345.us-east-1",
    "warehouse": "TRANSFORMING",
    "database": "PROD",
    "role": "DBT_SERVICE_ACCOUNT"
  }'

# Enable automatic rotation (30 days)
aws secretsmanager rotate-secret \
  --secret-id dbt-cloud/snowflake-credentials \
  --rotation-lambda-arn arn:aws:lambda:us-east-1:123456789012:function:SnowflakeSecretRotation \
  --rotation-rules AutomaticallyAfterDays=30
```

### Pattern 2: API Key Storage and Retrieval

```python
import boto3
import json

def get_secret(secret_name):
    """Retrieve secret from AWS Secrets Manager"""
    client = boto3.client('secretsmanager', region_name='us-east-1')
    response = client.get_secret_value(SecretId=secret_name)
    return json.loads(response['SecretString'])

# Usage in dbt profiles.yml
import os
if os.environ.get('DBT_ENVIRONMENT') == 'prod':
    snowflake_creds = get_secret('dbt-cloud/snowflake-credentials')
    SNOWFLAKE_USER = snowflake_creds['username']
    SNOWFLAKE_PASSWORD = snowflake_creds['password']
```

## HashiCorp Vault Patterns

### Pattern 1: Dynamic Database Credentials

```bash
# Enable Snowflake database secrets engine
vault secrets enable database

# Configure Snowflake connection
vault write database/config/snowflake \
  plugin_name=snowflake-database-plugin \
  allowed_roles="dbt-readonly,dbt-readwrite" \
  connection_url="{{username}}:{{password}}@xyz12345.us-east-1.snowflakecomputing.com" \
  username="vault_admin" \
  password="vault_admin_password"

# Create role for read-only access (24-hour TTL)
vault write database/roles/dbt-readonly \
  db_name=snowflake \
  creation_statements="CREATE USER {{name}} PASSWORD='{{password}}'; GRANT ROLE ANALYST TO USER {{name}};" \
  default_ttl="24h" \
  max_ttl="72h"

# Generate dynamic credentials
vault read database/creds/dbt-readonly
# Output:
#   username: v-token-dbt-readonly-abc123
#   password: A1B2C3D4E5F6
# Credentials expire in 24 hours, automatically revoked
```

### Pattern 2: Encryption as a Service

```bash
# Encrypt Metabase API key before storing
vault write transit/encrypt/metabase-api-key \
  plaintext=$(echo -n "mb_abc123def456" | base64)
# Output: vault:v1:8SDd3WHDOjf7mq69CyCqYjBXAiQQAVZRkFM13ok481zoCmHnSeDX9vyf7w==

# Store encrypted key in database
INSERT INTO api_keys (service, encrypted_key)
VALUES ('metabase', 'vault:v1:8SDd3WHDOjf7mq69CyCqYjBXAiQQAVZRkFM13ok481zoCmHnSeDX9vyf7w==');

# Decrypt when needed
vault write transit/decrypt/metabase-api-key \
  ciphertext=vault:v1:8SDd3WHDOjf7mq69CyCqYjBXAiQQAVZRkFM13ok481zoCmHnSeDX9vyf7w==
```

## Secret Rotation Strategies

### Zero-Downtime Rotation (Dual Credentials)

```python
# Phase 1: Generate new credentials
new_password = generate_secure_password()
create_snowflake_user(username="dbt_cloud_prod_v2", password=new_password)

# Phase 2: Update secret with both old and new credentials
update_secret({
    "current": {
        "username": "dbt_cloud_prod",
        "password": "old_password"
    },
    "pending": {
        "username": "dbt_cloud_prod_v2",
        "password": new_password
    }
})

# Phase 3: Applications use "current" credentials, gradually migrate to "pending"

# Phase 4: After 24 hours (all apps migrated), swap current ← pending
swap_credentials()

# Phase 5: Revoke old credentials
revoke_snowflake_user("dbt_cloud_prod")
```

## Further Reading
- [AWS Secrets Manager Rotation](https://docs.aws.amazon.com/secretsmanager/latest/userguide/rotating-secrets.html)
- [HashiCorp Vault Database Secrets Engine](https://developer.hashicorp.com/vault/docs/secrets/databases)
