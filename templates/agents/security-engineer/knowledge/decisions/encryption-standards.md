---

title: "Encryption Standards"
description: "Approved encryption algorithms, key sizes, rotation policies, and compliance requirements"
category: "decisions"
last_updated: "2025-10-07"

---

# Encryption Standards

## Approved Algorithms (2025)

| Use Case | Algorithm | Key Size | Compliance | Notes |
|----------|-----------|----------|------------|-------|
| Data at Rest | AES-GCM | 256-bit | FIPS 140-2, SOC 2 | Snowflake, S3, RDS default |
| Data in Transit | TLS | 1.2+ | PCI DSS, GDPR | Enforce TLS 1.3 where possible |
| Hashing | SHA-2 | 256-bit | NIST approved | For integrity verification |
| Password Hashing | Argon2id | N/A | OWASP recommended | Preferred over bcrypt |
| HMAC Signatures | HMAC-SHA256 | 256-bit | NIST approved | For webhook validation |
| Asymmetric Encryption | RSA | 4096-bit | Quantum-resistant path | Migrate to ECC (P-384) by 2026 |

## Key Rotation Policy

- **Production KMS Keys**: Automatic annual rotation
- **Service Account Passwords**: 90 days
- **API Keys**: 90 days (dbt Cloud, Metabase, Airbyte)
- **TLS Certificates**: 90 days (Let's Encrypt auto-renewal)
- **Emergency Rotation**: Within 24 hours of suspected compromise

## Decision Rationale

**Why AES-256-GCM instead of AES-256-CBC?**
- GCM provides authenticated encryption (integrity + confidentiality)
- Hardware acceleration on modern CPUs (AES-NI)
- Snowflake default, no configuration needed

**Why TLS 1.2+ (deprecate TLS 1.0/1.1)?**
- TLS 1.0/1.1 vulnerable to BEAST, POODLE attacks
- PCI DSS 4.0 requires TLS 1.2+ as of March 2025
- All modern browsers and clients support TLS 1.2+
