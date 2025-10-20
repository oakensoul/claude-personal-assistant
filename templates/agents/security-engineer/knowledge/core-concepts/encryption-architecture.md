---
title: "Encryption Architecture"
description: "Data at-rest and in-transit encryption strategies, key management, and compliance requirements"
category: "core-concepts"
tags:
  - encryption
  - key-management
  - compliance
  - data-protection
last_updated: "2025-10-07"
---

# Encryption Architecture

Comprehensive guide to encryption strategies for data at-rest, in-transit, and key management for cloud data platforms.

## Encryption Fundamentals

### Encryption Goals

1. **Confidentiality**: Protect data from unauthorized access
2. **Integrity**: Detect unauthorized modifications
3. **Compliance**: Meet regulatory requirements (GDPR, SOC 2, HIPAA)
4. **Defense in Depth**: Multiple layers of encryption (transport + storage)

### Encryption Types

- **Symmetric Encryption**: Same key for encryption/decryption (AES-256)
- **Asymmetric Encryption**: Public/private key pairs (RSA-2048/4096)
- **Hashing**: One-way transformation for integrity verification (SHA-256)
- **Key Derivation**: Generate keys from passwords (PBKDF2, Argon2)

## Data at Rest Encryption

### Snowflake Encryption

Snowflake provides automatic encryption for all data stored in the platform.

#### Standard Encryption

```sql
-- Snowflake automatically encrypts all data with AES-256
-- No additional configuration required for standard encryption
-- Keys managed by Snowflake (envelope encryption)

-- View encryption status
SHOW PARAMETERS LIKE 'ENCRYPTION' IN ACCOUNT;
```

**Features**:

- AES-256 encryption in GCM mode (Galois/Counter Mode)
- Hierarchical key model (account master key → table keys → file keys)
- Automatic key rotation managed by Snowflake
- Zero performance overhead (hardware-accelerated encryption)

#### Tri-Secret Secure (Customer-Managed Keys)

```sql
-- Enable Tri-Secret Secure with AWS KMS customer master key
ALTER ACCOUNT SET ENCRYPTION = 'TRI_SECRET_SECURE';

-- Configure AWS KMS key ARN
ALTER ACCOUNT SET AWS_KMS_KEY_ARN = 'arn:aws:kms:us-east-1:123456789012:key/abcd1234-...';

-- Verify Tri-Secret Secure is enabled
SHOW PARAMETERS LIKE 'ENCRYPTION' IN ACCOUNT;
-- Expected: ENCRYPTION = TRI_SECRET_SECURE
```

**Tri-Secret Architecture**:

1. **Snowflake Account Master Key**: Managed by Snowflake
2. **Customer Master Key (CMK)**: Managed by customer in AWS KMS
3. **Composite Master Key**: Combination of both keys using XOR operation

**Benefits**:

- Customer retains control over encryption keys
- Key rotation managed by AWS KMS (automatic annual rotation)
- Compliance requirements for key management (SOC 2, ISO 27001)
- Ability to revoke Snowflake's access to data (emergency key rotation)

**Implementation Checklist**:

- [ ] Create AWS KMS customer master key (CMK) with automatic rotation
- [ ] Grant Snowflake IAM role access to KMS key (kms:Decrypt, kms:DescribeKey)
- [ ] Enable Tri-Secret Secure on Snowflake account
- [ ] Configure KMS key ARN in Snowflake
- [ ] Test data loading and querying with Tri-Secret Secure
- [ ] Document key rotation policy (annual or per compliance requirements)
- [ ] Set up CloudWatch alarms for KMS key usage anomalies

### S3 Bucket Encryption (Data Lake)

```bash
# Enable default S3 bucket encryption with SSE-S3 (AWS-managed keys)
aws s3api put-bucket-encryption \
  --bucket dbt-splash-data-lake \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Or use SSE-KMS for customer-managed keys
aws s3api put-bucket-encryption \
  --bucket dbt-splash-data-lake \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "aws:kms",
        "KMSMasterKeyID": "arn:aws:kms:us-east-1:123456789012:key/12345678-abcd-1234-abcd-1234567890ab"
      },
      "BucketKeyEnabled": true
    }]
  }'

# Verify encryption is enabled
aws s3api get-bucket-encryption --bucket dbt-splash-data-lake
```

**S3 Encryption Options**:

- **SSE-S3** (Server-Side Encryption with S3-managed keys): AWS manages keys, AES-256
- **SSE-KMS** (Server-Side Encryption with KMS): Customer-managed keys in AWS KMS
- **SSE-C** (Server-Side Encryption with Customer-Provided Keys): Customer provides keys per request
- **Client-Side Encryption**: Encrypt data before uploading to S3

**Recommendation**: Use SSE-KMS with S3 Bucket Keys for cost efficiency and compliance.

### RDS/PostgreSQL Encryption

```bash
# Enable encryption at-rest for RDS PostgreSQL (must be set at instance creation)
aws rds create-db-instance \
  --db-instance-identifier metabase-postgres \
  --db-instance-class db.t3.medium \
  --engine postgres \
  --master-username admin \
  --master-user-password '...' \
  --allocated-storage 100 \
  --storage-encrypted \
  --kms-key-id arn:aws:kms:us-east-1:123456789012:key/12345678-abcd-1234-abcd-1234567890ab \
  --backup-retention-period 7 \
  --storage-type gp3

# Verify encryption is enabled
aws rds describe-db-instances \
  --db-instance-identifier metabase-postgres \
  --query 'DBInstances[0].[StorageEncrypted,KmsKeyId]'
```

**Note**: Encryption cannot be enabled on existing RDS instances. Must create encrypted snapshot and restore to new instance.

## Data in Transit Encryption

### TLS/SSL Configuration

#### Snowflake TLS

```python
# Python Snowflake connector with TLS enforcement
import snowflake.connector

conn = snowflake.connector.connect(
    user='dbt_service_account',
    password=os.environ.get('SNOWFLAKE_PASSWORD'),  # Use environment variable or OAuth/key-pair authentication
    account='xyz12345.us-east-1',
    warehouse='TRANSFORMING',
    database='PROD',
    schema='FINANCE',
    # TLS is enforced by default (TLS 1.2+)
    # No additional configuration needed
)

# Verify TLS version
cursor = conn.cursor()
cursor.execute("SELECT CURRENT_VERSION(), CURRENT_CLIENT()")
print(cursor.fetchone())
```

**Snowflake TLS Enforcement**:

- TLS 1.2+ required for all connections (TLS 1.0/1.1 deprecated)
- Certificate validation enabled by default
- OCSP (Online Certificate Status Protocol) for certificate revocation checking
- Perfect Forward Secrecy (PFS) for key exchange (ECDHE ciphers)

#### Metabase TLS

```yaml
# docker-compose.yml for Metabase with TLS
version: '3.8'
services:
  metabase:
    image: metabase/metabase:latest
    environment:
      MB_DB_TYPE: postgres
      MB_DB_DBNAME: metabase
      MB_DB_PORT: 5432
      MB_DB_USER: metabase
      MB_DB_PASS: ${METABASE_DB_PASSWORD}  # From Secrets Manager
      MB_DB_HOST: metabase-postgres.xyz.us-east-1.rds.amazonaws.com
      # Force HTTPS/TLS for database connections
      MB_DB_CONNECTION_URI: "postgres://metabase-postgres.xyz.us-east-1.rds.amazonaws.com:5432/metabase?ssl=true&sslmode=require"
      # Enforce HTTPS for Metabase web interface
      MB_JETTY_SSL: true
      MB_JETTY_SSL_PORT: 8443
      MB_JETTY_SSL_KEYSTORE: /etc/metabase/keystore.jks
      MB_JETTY_SSL_KEYSTORE_PASSWORD: ${KEYSTORE_PASSWORD}
    volumes:
      - ./ssl/keystore.jks:/etc/metabase/keystore.jks:ro
    ports:
      - "8443:8443"
```

**Metabase TLS Best Practices**:

- Use AWS Application Load Balancer (ALB) for TLS termination
- Enforce HTTPS-only (redirect HTTP to HTTPS)
- Use ACM (AWS Certificate Manager) for SSL certificates
- Enable HTTP Strict Transport Security (HSTS) headers

#### Airbyte TLS

```yaml
# Airbyte connection configuration with TLS
# Snowflake destination with TLS enforcement
{
  "destinationType": "snowflake",
  "connectionConfiguration": {
    "host": "xyz12345.us-east-1.snowflakecomputing.com",
    "database": "PROD",
    "schema": "FINANCE_STAGING",
    "username": "airbyte_service_account",
    "credentials": {
      "auth_type": "OAuth2.0",
      "client_id": "...",
      "client_secret": "...",
      "refresh_token": "..."
    },
    # TLS is enforced by default in Snowflake connector
    # No additional SSL configuration needed
  }
}

# PostgreSQL source with TLS enforcement
{
  "sourceType": "postgres",
  "connectionConfiguration": {
    "host": "source-db.xyz.us-east-1.rds.amazonaws.com",
    "port": 5432,
    "database": "production",
    "username": "airbyte_reader",
    "password": "...",
    "ssl_mode": {
      "mode": "require"  # Force TLS, reject unencrypted connections
    }
  }
}
```

**Airbyte TLS Requirements**:

- All database connections must use TLS (PostgreSQL, MySQL, Snowflake)
- API connections to Stripe, Salesforce, etc. use HTTPS by default
- Webhook endpoints must use HTTPS with valid certificates
- Internal Airbyte components use TLS for communication (worker ↔ server)

## Key Management

### AWS Key Management Service (KMS)

#### KMS Key Creation

```bash
# Create customer master key (CMK) for data encryption
aws kms create-key \
  --description "Snowflake Tri-Secret Secure CMK for dbt-splash-prod-v2" \
  --key-usage ENCRYPT_DECRYPT \
  --origin AWS_KMS \
  --multi-region false \
  --tags TagKey=Project,TagValue=dbt-splash-prod-v2 \
         TagKey=Environment,TagValue=production \
         TagKey=ManagedBy,TagValue=security-team

# Create alias for easier reference
aws kms create-alias \
  --alias-name alias/snowflake-prod-cmk \
  --target-key-id <key-id-from-above>

# Enable automatic key rotation (annual)
aws kms enable-key-rotation --key-id <key-id>

# Verify rotation is enabled
aws kms get-key-rotation-status --key-id <key-id>
```

#### KMS Key Policy for Snowflake

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Allow Snowflake to use the key",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::123456789012:role/snowflake-s3-integration-role"
      },
      "Action": [
        "kms:Decrypt",
        "kms:DescribeKey"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "kms:ViaService": [
            "s3.us-east-1.amazonaws.com"
          ]
        }
      }
    },
    {
      "Sid": "Allow CloudWatch Logs to use the key",
      "Effect": "Allow",
      "Principal": {
        "Service": "logs.us-east-1.amazonaws.com"
      },
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:CreateGrant",
        "kms:DescribeKey"
      ],
      "Resource": "*"
    },
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::123456789012:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    }
  ]
}
```

#### Key Rotation Policy

```bash
# Automatic annual rotation (recommended for compliance)
aws kms enable-key-rotation --key-id <key-id>

# Manual rotation (for emergency key compromise)
# 1. Create new CMK
aws kms create-key --description "Snowflake CMK - Rotated 2025-10-07"

# 2. Update Snowflake to use new CMK
ALTER ACCOUNT SET AWS_KMS_KEY_ARN = 'arn:aws:kms:us-east-1:123456789012:key/new-key-id';

# 3. Wait 24 hours for Snowflake to re-encrypt all data

# 4. Disable old CMK (do not delete for 30 days)
aws kms disable-key --key-id <old-key-id>

# 5. After 30 days, schedule key deletion
aws kms schedule-key-deletion --key-id <old-key-id> --pending-window-in-days 30
```

**Key Rotation Best Practices**:

- Enable automatic rotation for all production KMS keys
- Document rotation policy (annual minimum, quarterly recommended)
- Test rotation procedure in dev/staging before production
- Maintain audit log of all key rotations (who, when, why)
- Keep old keys disabled (not deleted) for 90 days for disaster recovery

### HashiCorp Vault (Alternative Key Management)

#### Vault Encryption Engine

```bash
# Enable transit secrets engine for encryption-as-a-service
vault secrets enable transit

# Create encryption key for Snowflake credentials
vault write -f transit/keys/snowflake-credentials \
  type=aes256-gcm96 \
  exportable=false \
  allow_plaintext_backup=false

# Encrypt a plaintext value
vault write transit/encrypt/snowflake-credentials \
  plaintext=$(echo -n "my-snowflake-password" | base64)

# Decrypt ciphertext
vault write transit/decrypt/snowflake-credentials \
  ciphertext=vault:v1:8SDd3WHDOjf7mq69CyCqYjBXAiQQAVZRkFM13ok481zoCmHnSeDX9vyf7w==

# Rotate encryption key
vault write -f transit/keys/snowflake-credentials/rotate

# View key versions
vault read transit/keys/snowflake-credentials
```

**Vault Use Cases**:

- Encrypt API keys and database passwords before storing in config files
- Dynamic secret generation for short-lived credentials
- Centralized key management across multiple environments
- Audit logging for all encryption/decryption operations

## Encryption Standards and Compliance

### Algorithm Selection

| Use Case | Algorithm | Key Size | Rationale |
|----------|-----------|----------|-----------|
| Data at Rest | AES-GCM | 256-bit | NIST approved, authenticated encryption, hardware acceleration |
| Data in Transit | TLS 1.2+ | 2048-bit RSA or 256-bit ECDSA | Industry standard, PFS support, wide compatibility |
| Password Hashing | Argon2id | N/A | Winner of Password Hashing Competition, resistant to GPU attacks |
| HMAC Signatures | SHA-256 | 256-bit | Collision-resistant, FIPS 140-2 approved |
| Asymmetric Encryption | RSA | 4096-bit | Long-term security, quantum-resistant migration path |

### Compliance Requirements

#### SOC 2 Type II

**Control**: CC6.7 - The entity restricts the transmission, movement, and removal of information to authorized internal and external users and processes.

**Implementation**:

- TLS 1.2+ for all data in transit (Snowflake, Metabase, Airbyte)
- AES-256 encryption for all data at rest (S3, RDS, Snowflake)
- Customer-managed keys (Tri-Secret Secure) for sensitive financial data
- Quarterly access reviews for KMS key usage

#### GDPR Article 32

**Requirement**: Implement appropriate technical measures to ensure security of processing, including encryption of personal data.

**Implementation**:

- Encrypt all PII fields in Snowflake (email, phone, address)
- Use Tri-Secret Secure for right to erasure (customer can revoke key access)
- TLS encryption for all data transfers (EU to US data transfers)
- Document encryption algorithms and key management procedures

#### ISO 27001 (A.10 Cryptography)

**Control**: A.10.1.1 - Policy on the use of cryptographic controls

**Implementation**:

- Documented encryption policy (this document)
- Approved cryptographic algorithms (AES-256, RSA-4096, TLS 1.2+)
- Key management procedures (creation, rotation, revocation)
- Annual review of encryption standards and compliance

## Encryption Performance Considerations

### Snowflake Encryption Performance

- **Zero overhead**: Hardware-accelerated AES-NI instruction set
- **No configuration needed**: Encryption is always enabled, transparent to users
- **Tri-Secret Secure**: <5% performance impact for key lookup (negligible for large queries)

### S3 Encryption Performance

- **SSE-S3**: No performance impact (server-side encryption)
- **SSE-KMS**: <10ms latency per object for key retrieval (use S3 Bucket Keys to reduce KMS calls)
- **Client-Side Encryption**: 10-30% performance overhead (CPU-bound encryption)

**Recommendation**: Use SSE-KMS with S3 Bucket Keys for optimal performance and compliance.

### TLS Performance

- **Handshake overhead**: 1-2 RTT (round-trip time) for initial connection
- **Session resumption**: Reuse TLS session to avoid repeated handshakes
- **Hardware acceleration**: Modern CPUs have AES-NI and hardware TLS offload
- **Connection pooling**: Reuse encrypted connections (Snowflake, PostgreSQL)

## Encryption Monitoring and Auditing

### CloudWatch Metrics for KMS

```bash
# Create CloudWatch alarm for unauthorized KMS key usage
aws cloudwatch put-metric-alarm \
  --alarm-name "KMS-Unauthorized-Access-Snowflake-CMK" \
  --alarm-description "Alert on unauthorized KMS key access attempts" \
  --metric-name UserErrorCount \
  --namespace AWS/KMS \
  --statistic Sum \
  --period 300 \
  --threshold 5 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 1 \
  --dimensions Name=KeyId,Value=<key-id> \
  --alarm-actions arn:aws:sns:us-east-1:123456789012:security-alerts
```

### CloudTrail Logging for Encryption Events

```bash
# Query CloudTrail for KMS key usage
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=ResourceName,AttributeValue=<key-id> \
  --max-results 50 \
  --output json | jq '.Events[] | {Time: .EventTime, User: .Username, Event: .EventName}'
```

### Snowflake Audit Logging

```sql
-- Query Snowflake access history for encryption events
SELECT
    query_id,
    query_text,
    user_name,
    role_name,
    execution_status,
    start_time,
    end_time
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE query_text ILIKE '%ALTER ACCOUNT%ENCRYPTION%'
   OR query_text ILIKE '%AWS_KMS_KEY_ARN%'
ORDER BY start_time DESC
LIMIT 100;
```

## Emergency Procedures

### Key Compromise Response

1. **Immediate**: Disable compromised KMS key (prevents new encryption operations)
2. **Within 1 hour**: Create new KMS key with updated access policies
3. **Within 4 hours**: Update Snowflake/S3 to use new KMS key
4. **Within 24 hours**: Re-encrypt all data with new key (Snowflake automatic, S3 manual)
5. **Within 7 days**: Complete incident report and post-mortem

### Certificate Expiration

```bash
# Check SSL certificate expiration (Metabase, ALB)
echo | openssl s_client -connect metabase.splash.com:443 2>/dev/null | openssl x509 -noout -dates

# Renew ACM certificate (automatic renewal 60 days before expiration)
aws acm describe-certificate --certificate-arn arn:aws:acm:us-east-1:123456789012:certificate/abc123

# Manual certificate renewal with Let's Encrypt
certbot renew --force-renewal
```

## Further Reading

- [NIST Special Publication 800-57: Key Management](https://csrc.nist.gov/publications/detail/sp/800-57-part-1/rev-5/final)
- [Snowflake Encryption Documentation](https://docs.snowflake.com/en/user-guide/security-encryption)
- [AWS KMS Best Practices](https://docs.aws.amazon.com/kms/latest/developerguide/best-practices.html)
- [OWASP Cryptographic Storage Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Cryptographic_Storage_Cheat_Sheet.html)
