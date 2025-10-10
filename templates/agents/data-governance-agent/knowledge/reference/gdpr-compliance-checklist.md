---
title: "GDPR Compliance Checklist"
description: "Actionable checklist for GDPR compliance in data warehouse"
category: "reference"
tags: [gdpr, compliance, checklist]
last_updated: "2025-10-07"
---

# GDPR Compliance Checklist

## Legal Basis for Processing
- [ ] Document lawful basis for each processing activity (consent, contract, legitimate interest)
- [ ] Privacy policy published and accessible
- [ ] Consent mechanisms for marketing/analytics (where applicable)

## Data Subject Rights Implementation
- [ ] Right to Access: SQL export script generates user data package
- [ ] Right to Erasure: Cascading delete across all tables with audit log
- [ ] Right to Rectification: Update mechanism with change history
- [ ] Right to Data Portability: JSON/CSV export format
- [ ] Right to Object: Opt-out flag enforcement in dbt models
- [ ] Right to Restrict Processing: Freeze flag prevents new processing

## Data Protection by Design
- [ ] PII minimization: Only collect necessary data
- [ ] Pseudonymization in analytics models
- [ ] Encryption at rest (Snowflake native) and in transit (TLS)
- [ ] Access controls: RBAC with least privilege
- [ ] Audit logging: Track all PII access

## Vendor Management
- [ ] Data Processing Agreements (DPAs) with all vendors: Snowflake, Fivetran, Segment
- [ ] Validate vendor GDPR compliance (Sub-processor lists, SCCs)
- [ ] Cross-border transfer mechanisms (Adequacy decisions, SCCs)

## Breach Notification
- [ ] Incident response plan: Detect, contain, investigate
- [ ] 72-hour notification procedure to supervisory authority
- [ ] User notification process if high risk to rights/freedoms

## Records of Processing Activities (Article 30)
- [ ] Register of all processing activities maintained
- [ ] Include: purposes, data categories, recipients, retention, security measures
- [ ] Annual review and updates
