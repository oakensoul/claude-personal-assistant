---
title: "Security Checklist"
description: "Quarterly security review checklist for data platform infrastructure and access controls"
category: "reference"
tags:
  - security-audit
  - checklist
  - compliance
  - quarterly-review
last_updated: "2025-10-07"
---

# Quarterly Security Checklist

Comprehensive security review checklist for dbt-splash-prod-v2 data platform (Snowflake, Metabase, Airbyte, dbt Cloud).

## Encryption & Key Management

- [ ] Verify Snowflake Tri-Secret Secure is enabled (`SHOW PARAMETERS LIKE 'ENCRYPTION'`)
- [ ] Check AWS KMS key rotation is enabled (automatic annual rotation)
- [ ] Confirm S3 bucket encryption with SSE-KMS for all data lakes
- [ ] Review TLS 1.2+ enforcement for all services (Snowflake, Metabase, Airbyte)
- [ ] Audit certificate expiration dates (renew 30 days before expiry)
- [ ] Verify RDS encryption at-rest for Metabase PostgreSQL database

## Access Control & RBAC

- [ ] Review Snowflake role grants (`SHOW GRANTS TO ROLE [role_name]`)
- [ ] Audit users with ACCOUNTADMIN/SYSADMIN roles (should be <5 users)
- [ ] Check for stale users (no login in 90+ days), disable accounts
- [ ] Verify MFA is enabled for all production users
- [ ] Review Metabase group permissions (finance, analytics, executives)
- [ ] Audit service account permissions (dbt Cloud, Airbyte, Metabase)
- [ ] Confirm least privilege for all roles (no excessive permissions)

## Secret Management

- [ ] Rotate all API keys (Metabase, Airbyte, dbt Cloud) - quarterly minimum
- [ ] Verify no secrets in GitHub repository (run `git secrets --scan`)
- [ ] Check AWS Secrets Manager rotation status (all secrets rotated <90 days ago)
- [ ] Audit secret access logs (CloudWatch for Secrets Manager, Vault audit logs)
- [ ] Confirm service account passwords rotated (Snowflake, PostgreSQL)

## Network Security

- [ ] Review Snowflake network policies (IP allowlist up-to-date)
- [ ] Verify security group rules (minimum ports open, no 0.0.0.0/0 for production)
- [ ] Check VPC configuration (private subnets for data services)
- [ ] Audit bastion host access logs (who accessed production via SSH)
- [ ] Confirm PrivateLink/VPC endpoints for AWS services (S3, Secrets Manager)

## Vulnerability Management

- [ ] Run dependency scan (Snyk, Dependabot) for dbt packages and Python libraries
- [ ] Check for critical CVEs in Docker images (Metabase, Airbyte)
- [ ] Review Snowflake security bulletins (apply patches within 7 days)
- [ ] Audit OS patches for EC2 instances (auto-patching enabled)
- [ ] Penetration testing completed (annual or after major architecture changes)

## Logging & Monitoring

- [ ] Verify CloudTrail logging enabled for KMS, Secrets Manager, IAM
- [ ] Check Snowflake query history retention (1 year for compliance)
- [ ] Review Metabase audit log for suspicious activity (failed logins, unauthorized access)
- [ ] Confirm CloudWatch alarms configured (KMS unauthorized access, high error rates)
- [ ] Test security incident alerting (Slack/PagerDuty integration)

## Compliance & Audit

- [ ] Document security controls for SOC 2 Type II audit
- [ ] Review GDPR compliance (encryption, access controls, data retention)
- [ ] Update security policies and procedures documentation
- [ ] Complete quarterly access review (who has access to what)
- [ ] Generate compliance reports (access logs, encryption status, vulnerability scans)

## Incident Response

- [ ] Review incident response playbook (ensure up-to-date contact info)
- [ ] Test security incident escalation process (tabletop exercise)
- [ ] Audit incident response logs (lessons learned from previous incidents)
- [ ] Verify backup and disaster recovery procedures (monthly test restores)

## Findings & Remediation

| Finding | Severity | Owner | Due Date | Status |
|---------|----------|-------|----------|--------|
| Example: API key not rotated in 120 days | Medium | Security Engineer | 2025-10-15 | Open |
| ... | ... | ... | ... | ... |

---
Completed by: [Name]
Review Date: [YYYY-MM-DD]
Next Review: [YYYY-MM-DD] (3 months from now)
