---
title: "Security Incident Response Playbook"
description: "Step-by-step procedures for security incidents, escalation, and forensics"
category: "reference"
last_updated: "2025-10-07"
---

# Security Incident Response Playbook

## Incident Severity Classification

| Severity | Description | Response Time | Escalation |
|----------|-------------|---------------|------------|
| **P0 - Critical** | Active data breach, production outage | Immediate (24/7) | Security Lead + CTO |
| **P1 - High** | Suspected breach, unauthorized access to PII | <1 hour (business hours) | Security Lead |
| **P2 - Medium** | Vulnerabilities detected, failed security controls | <4 hours | Security Engineer |
| **P3 - Low** | Policy violations, informational findings | <1 business day | Security Engineer |

## P0: Data Breach Response (Active Exfiltration)

### Phase 1: Contain (0-30 minutes)
1. **Isolate Affected Systems**:
   ```bash
   # Revoke Snowflake user access immediately
   ALTER USER <compromised_user> SET DISABLED = TRUE;
   
   # Disable API keys
   aws secretsmanager update-secret --secret-id <secret-name> --secret-string '{"revoked": true}'
   
   # Block IP address in network policy
   ALTER NETWORK POLICY PRODUCTION_ACCESS SET BLOCKED_IP_LIST = ('x.x.x.x');
   ```

2. **Enable Enhanced Logging**:
   ```sql
   -- Capture all queries from suspected compromised account
   SELECT * FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
   WHERE user_name = '<compromised_user>'
     AND start_time >= DATEADD(hour, -24, CURRENT_TIMESTAMP());
   ```

3. **Notify Stakeholders**:
   - Security Lead (immediate)
   - CTO (within 15 minutes)
   - Legal/Compliance (within 30 minutes)

### Phase 2: Eradicate (30 minutes - 2 hours)
1. **Rotate All Credentials**:
   ```bash
   # Emergency KMS key rotation
   aws kms create-key --description "Emergency rotation 2025-10-07"
   
   # Update Snowflake to use new key
   ALTER ACCOUNT SET AWS_KMS_KEY_ARN = 'arn:aws:kms:...new-key...';
   ```

2. **Patch Vulnerability**:
   - Apply security patches
   - Fix SQL injection, authentication bypass, etc.

3. **Review Access Logs**:
   ```sql
   -- Find all tables accessed by compromised account
   SELECT DISTINCT base_objects_accessed
   FROM SNOWFLAKE.ACCOUNT_USAGE.ACCESS_HISTORY
   WHERE user_name = '<compromised_user>'
     AND start_time >= DATEADD(day, -7, CURRENT_TIMESTAMP());
   ```

### Phase 3: Recover (2-6 hours)
1. **Restore Service**:
   - Re-enable accounts with new credentials
   - Validate data integrity (no tampering)

2. **Communication**:
   - Internal: Status updates every 30 minutes
   - External: Customer notification if PII affected (within 72 hours per GDPR)

### Phase 4: Post-Incident Review (1 week)
1. **Root Cause Analysis**: How did breach occur?
2. **Lessons Learned**: What controls failed?
3. **Remediation Plan**: Prevent recurrence
4. **Update Playbook**: Incorporate findings

## P1: Unauthorized Access to PII

### Immediate Actions
1. **Verify Access**: Check `ACCOUNT_USAGE.ACCESS_HISTORY` for table access
2. **Disable Account**: `ALTER USER <user> SET DISABLED = TRUE;`
3. **Review Masking Policies**: Ensure PII masking is active
4. **Notify Compliance Team**: GDPR breach notification assessment

## P2: Critical CVE in Snowflake/Metabase

### Response Steps
1. **Assess Impact**: Does CVE affect our deployment?
2. **Apply Patch**: Within 7 days for critical CVEs
3. **Test in Dev**: Validate no breaking changes
4. **Deploy to Prod**: Schedule maintenance window
5. **Verify**: Scan for vulnerability post-patch

## P3: Policy Violation (e.g., hardcoded secret in Git)

### Response Steps
1. **Revoke Secret**: Immediately rotate exposed credential
2. **Remove from Git History**: `git filter-branch` or BFG Repo-Cleaner
3. **Security Training**: Educate team on secret management
4. **Implement Preventive Controls**: GitHub secret scanning, pre-commit hooks

## Contact Information

| Role | Name | Phone | Email | Escalation Path |
|------|------|-------|-------|-----------------|
| Security Lead | [Name] | [Phone] | [Email] | CTO |
| CTO | [Name] | [Phone] | [Email] | CEO |
| Legal/Compliance | [Name] | [Phone] | [Email] | General Counsel |
| On-Call Engineer | [Rotation] | [PagerDuty] | [Email] | Security Lead |

## Incident Log Template

```markdown
# Incident Report: [INC-2025-001]

**Date**: 2025-10-07 14:30 UTC
**Severity**: P1 - High
**Status**: Resolved

## Summary
Brief description of incident (unauthorized access to FINANCE schema).

## Timeline
- 14:30 UTC: Alert triggered (failed login attempts)
- 14:35 UTC: Investigation started
- 14:40 UTC: Account disabled
- 15:00 UTC: Root cause identified (phishing attack)
- 16:00 UTC: Credentials rotated, service restored

## Root Cause
User credentials stolen via phishing email.

## Impact
No data exfiltration detected. Access logs show user only viewed 2 dashboards.

## Remediation
1. Mandatory MFA enrollment for all users
2. Enhanced phishing awareness training
3. Deploy email filtering rules (block suspicious domains)

## Lessons Learned
- MFA should be enforced, not optional
- Incident response time: 1.5 hours (within SLA)
```

---
Last Updated: 2025-10-07
Next Review: Quarterly (2026-01-07)
