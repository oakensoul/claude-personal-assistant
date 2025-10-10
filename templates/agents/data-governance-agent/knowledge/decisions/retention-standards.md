---
title: "Data Retention Standards"
description: "Default retention periods by data type"
category: "decisions"
tags: [retention, compliance, gdpr]
last_updated: "2025-10-07"
---

# Data Retention Standards

## Retention Periods by Data Type

| Data Category | Active Retention | Archive | Total | Rationale |
|---------------|------------------|---------|-------|-----------|
| **Financial Transactions** | 2 years | 5 years | 7 years | IRS, SOX compliance |
| **User Activity Logs** | 90 days | 9 months | 1 year | Operational need + compliance buffer |
| **PII (user profiles)** | Until account deletion | - | Lifecycle-based | GDPR Article 5(1)(e) storage limitation |
| **Audit Logs** | 2 years | 5 years | 7 years | SOC2, GDPR Article 30 |
| **Marketing Data** | Until consent withdrawn | - | Consent-based | GDPR lawful basis |
| **Segment Events** | 90 days | - | 90 days | High volume, analytics use case |

## Decision: Automated Deletion vs Manual Review

**Chosen**: Automated deletion with manual override capability

**Rationale**:
- Reduces compliance risk (no forgotten data)
- Scales better than manual processes
- Legal hold mechanism preserves data when needed
- Audit trail documents all deletions
