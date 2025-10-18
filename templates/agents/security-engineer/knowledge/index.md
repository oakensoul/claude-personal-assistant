---
title: "Security Engineer Knowledge Base"
description: "Comprehensive security knowledge for data platform encryption, access controls, and threat modeling"
agent: "security-engineer"
knowledge_count: 14
last_updated: "2025-10-07"
categories:
  - core-concepts
  - patterns
  - decisions
  - reference
---

# Security Engineer Knowledge Base

Comprehensive security documentation for the dbt-splash-prod-v2 data platform, covering encryption architecture, access control systems, API security, secret management, and vulnerability management.

## Knowledge Categories

### Core Concepts (4 files)
Fundamental security principles and architectural patterns:
- **encryption-architecture.md** - Data at-rest, in-transit encryption, key management strategies
- **access-control-models.md** - RBAC, ABAC, least privilege, identity management
- **api-security-patterns.md** - OAuth, JWT, API keys, rate limiting, authentication methods
- **threat-modeling.md** - STRIDE methodology, attack trees, risk assessment frameworks

### Patterns (4 files)
Reusable security implementation patterns:
- **secret-management-patterns.md** - Vault, AWS Secrets Manager, rotation strategies
- **network-security-patterns.md** - VPC design, security groups, private endpoints, IP allowlisting
- **security-monitoring.md** - SIEM integration, alerting, anomaly detection, dashboards
- **vulnerability-management.md** - Scanning tools, patch management, CVE tracking, remediation

### Decisions (3 files)
Security architecture decisions and rationale:
- **encryption-standards.md** - Algorithm selection, key sizes, rotation policies, compliance
- **secret-management-strategy.md** - Centralized vs distributed, tool selection, rotation frequency
- **api-security-requirements.md** - Authentication methods by service, token policies, rate limits

### Reference (3 files)
Quick reference guides and checklists:
- **security-checklist.md** - Quarterly security review checklist, audit procedures
- **incident-response-playbook.md** - Security incident procedures, escalation, forensics
- **snowflake-security-hardening.md** - Snowflake-specific security configurations and best practices

## How to Use This Knowledge Base

### For Encryption Design
1. Review `core-concepts/encryption-architecture.md` for architectural patterns
2. Check `decisions/encryption-standards.md` for approved algorithms and policies
3. Reference `reference/snowflake-security-hardening.md` for Snowflake-specific encryption

### For Access Control Implementation
1. Study `core-concepts/access-control-models.md` for RBAC/ABAC principles
2. Review `patterns/network-security-patterns.md` for IP allowlisting and VPC setup
3. Apply `reference/snowflake-security-hardening.md` for Snowflake role hierarchies

### For API Security
1. Read `core-concepts/api-security-patterns.md` for authentication methods
2. Check `decisions/api-security-requirements.md` for service-specific requirements
3. Implement `patterns/security-monitoring.md` for API access logging and alerts

### For Secret Management
1. Review `patterns/secret-management-patterns.md` for Vault/Secrets Manager setup
2. Check `decisions/secret-management-strategy.md` for rotation policies
3. Apply automated rotation with zero-downtime strategies

### For Security Audits
1. Use `reference/security-checklist.md` for quarterly reviews
2. Follow `patterns/vulnerability-management.md` for scanning and patching
3. Document findings and remediation in decision records

### For Incident Response
1. Follow `reference/incident-response-playbook.md` for security incidents
2. Use `patterns/security-monitoring.md` for detection and alerting
3. Conduct post-incident review and update playbooks

## Integration with Project Architecture

### Snowflake Security
- Network policies for IP allowlisting
- OAuth integration with Okta/Auth0
- Tri-Secret Secure encryption with AWS KMS
- Role-based access control (RBAC) hierarchies
- MFA enforcement for production access

### Metabase Security
- SSO integration (SAML/OAuth)
- API token management and rotation
- Row-level security (RLS) for sensitive data
- Rate limiting for API endpoints
- Audit logging for dashboard access

### Airbyte Security
- Encrypted connections to sources and destinations
- Secret management for API keys and database credentials
- VPC deployment with private endpoints
- IP allowlisting for source systems
- Webhook security with HMAC signatures

### dbt Cloud Security
- Service account authentication
- API key rotation policies
- GitHub integration with OAuth
- Job-level access controls
- Audit logs for model deployments

## Security Standards Applied

### Encryption Standards
- **Data at Rest**: AES-256-GCM (Snowflake, S3, RDS)
- **Data in Transit**: TLS 1.2+ (all services)
- **Key Management**: AWS KMS with automatic rotation
- **Hashing**: bcrypt/Argon2 for passwords, SHA-256 for integrity

### Access Control Standards
- **Principle of Least Privilege**: Minimal necessary permissions
- **Role Hierarchies**: Functional roles with inheritance (Snowflake)
- **Time-Bound Access**: JIT access for elevated privileges (max 8 hours)
- **MFA Enforcement**: Required for production data warehouse access

### API Security Standards
- **Authentication**: OAuth 2.0 for users, API keys for service accounts
- **Token Expiration**: 7-day validity for user tokens, 90-day for service accounts
- **Rate Limiting**: 100 requests/minute per client (adjustable per service)
- **Request Validation**: Input sanitization, parameter validation, content-type checks

### Network Security Standards
- **VPC Design**: Private subnets for all data services, public subnet for bastion only
- **Security Groups**: Port 443 only (HTTPS), IP allowlisting for production
- **Private Endpoints**: AWS PrivateLink for S3, Secrets Manager, KMS
- **Firewall Rules**: Deny all by default, explicit allow rules only

## Compliance Frameworks

### SOC 2 Type II
- Encryption controls (CC6.1, CC6.6, CC6.7)
- Access controls (CC6.2, CC6.3)
- Monitoring and logging (CC7.2, CC7.3)
- Incident response (CC7.4, CC7.5)

### GDPR
- Data encryption (Article 32)
- Access controls and authentication (Article 32)
- Breach notification procedures (Article 33)
- Data retention and deletion (Article 17)

### ISO 27001
- Information security policies (A.5)
- Access control (A.9)
- Cryptography (A.10)
- Incident management (A.16)

## Version History

- **v1.0.0** (2025-10-07) - Initial knowledge base creation
  - Core concepts: Encryption, access control, API security, threat modeling
  - Patterns: Secret management, network security, monitoring, vulnerability management
  - Decisions: Encryption standards, secret management strategy, API security requirements
  - Reference: Security checklist, incident response playbook, Snowflake hardening

## Contributing to This Knowledge Base

When adding new security knowledge:
1. **Categorize Correctly**: Core concepts vs patterns vs decisions vs reference
2. **Include Examples**: Snowflake, Metabase, Airbyte, dbt Cloud specific examples
3. **Document Rationale**: Explain "why" not just "how" for security decisions
4. **Update Index**: Keep this index.md current with file counts and descriptions
5. **Cross-Reference**: Link related concepts across categories
6. **Compliance Mapping**: Note which compliance requirements are addressed

## Quick Links

- [Security Engineer Agent Definition](../security-engineer.md)
- [Project CLAUDE.md](../../../../CLAUDE.md)
- [Architecture Documentation](../../../../docs/architecture/)
- [Snowflake Security Best Practices](https://docs.snowflake.com/en/user-guide/security)
- [AWS Security Best Practices](https://aws.amazon.com/architecture/security-identity-compliance/)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
