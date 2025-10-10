---
title: "Data Governance Agent Knowledge Base"
description: "Comprehensive knowledge catalog for data compliance, privacy, and governance"
agent: "data-governance-agent"
knowledge_count: 14
last_updated: "2025-10-07"
---

# Data Governance Agent Knowledge Base

This knowledge base provides comprehensive guidance on data governance, compliance frameworks, privacy engineering, and audit trail implementation for the Splash Sports data warehouse.

## Core Concepts (4 files)

Foundational knowledge on compliance frameworks, data classification, audit architecture, and privacy engineering.

### [compliance-frameworks.md](core-concepts/compliance-frameworks.md)
**GDPR, CCPA, SOC2, and HIPAA requirements for data governance**

- GDPR principles and data subject rights (access, erasure, portability)
- CCPA consumer rights and business obligations
- SOC2 Trust Services Criteria (security, availability, confidentiality)
- HIPAA Protected Health Information (PHI) requirements
- Compliance decision matrix for Splash Sports

**Key Topics**:
- GDPR Article 30 (Records of Processing Activities)
- DPIA (Data Protection Impact Assessment) requirements
- Data breach notification (72-hour window)
- Cross-framework synergies and implementation priorities

### [data-classification.md](core-concepts/data-classification.md)
**Data sensitivity levels, PII types, and classification tagging strategy**

- Four-level sensitivity framework (Public, Internal, Confidential, Restricted)
- PII classification hierarchy (Direct, Quasi-Identifier, Sensitive)
- Splash Sports PII inventory (splash_production, segment, intercom sources)
- dbt tagging strategy for governance (`pii:true`, `pii_type:direct`, `sensitivity:restricted`)
- Snowflake object tagging for compliance tracking

**Key Topics**:
- K-anonymity for quasi-identifiers (k ≥ 5)
- Automated PII detection (pattern-based, catalog-based, ML-based)
- Data masking decision tree
- Classification review workflow

### [audit-trail-architecture.md](core-concepts/audit-trail-architecture.md)
**Comprehensive logging frameworks, compliance reporting, and access tracking**

- The 5 W's of audit logging (Who, What, When, Where, Why)
- Snowflake audit data sources (QUERY_HISTORY, ACCESS_HISTORY, LOGIN_HISTORY, GRANTS)
- Audit data warehouse design (centralized audit schema, fact tables)
- Compliance reporting templates (GDPR Article 30, CCPA inventory, SOC2 access reviews)
- Real-time monitoring and alerting (unusual PII access, failed logins, privilege escalation)

**Key Topics**:
- Column-level access tracking via ACCESS_HISTORY
- dbt models for audit log staging (`stg_snowflake__query_history`)
- Data subject request audit trail (GDPR erasure example)
- Audit trail best practices (tamper-proof storage, SIEM integration)

### [privacy-engineering.md](core-concepts/privacy-engineering.md)
**Privacy Impact Assessments, privacy-by-design, and proactive privacy engineering**

- Privacy by Design principles (Proactive, Default Privacy, Embedded)
- Privacy Impact Assessment (PIA) process (6-step methodology)
- PIA template for Splash Sports (Segment integration example)
- Privacy-by-design patterns (separation of PII, layered masking, privacy-preserving joins)
- Privacy engineering checklist (collection, storage, processing, sharing, retention)

**Key Topics**:
- GDPR DPIA (Data Protection Impact Assessment) requirements
- dbt macros for privacy (`pseudonymize_user_id`, `enforce_k_anonymity`)
- Differential privacy for aggregates
- Pre-production PIA gate in CI/CD

---

## Patterns (4 files)

Reusable implementation patterns for PII detection, data masking, retention automation, and compliance workflows.

### [pii-detection-patterns.md](patterns/pii-detection-patterns.md)
**Automated and manual methods for discovering PII in data warehouse**

- Multi-layered detection strategy (catalog, pattern, ML, manual review)
- Catalog-based detection with known PII field registry
- Regex pattern matching (email, phone, SSN, credit card, IP address)
- ML-based detection using spaCy NER for unstructured text
- Snowflake Information Schema queries for suspicious column names
- Data profiling for quasi-identifier re-identification risk

**Key Topics**:
- Python script for PII scanning (`scan_pii.py`)
- CI/CD integration (GitHub Actions PII scan workflow)
- Snowflake UDF for ML-based PII detection
- dbt test for PII tagging validation
- Pre-commit hook for PII validation

### [data-masking-strategies.md](patterns/data-masking-strategies.md)
**Tokenization, anonymization, pseudonymization, and Snowflake DDM implementation**

- Masking techniques comparison (static, dynamic, tokenization, pseudonymization, anonymization)
- Snowflake Dynamic Data Masking (DDM) patterns (progressive masking by role, conditional masking)
- Tokenization for payment data (Stripe example, custom tokenization service)
- Pseudonymization with keyed hashing (reversible with secret key)
- Anonymization techniques (generalization, data suppression, k-anonymity)

**Key Topics**:
- DDM deployment pattern (create policies, apply to columns, validate)
- dbt macro for pseudonymization (`pseudonymize_user_id`)
- Privacy-preserving joins (aggregate before join, anonymized keys)
- Differential privacy for published aggregates

### [retention-policy-implementation.md](patterns/retention-policy-implementation.md)
**Automated data lifecycle management and retention enforcement**

- dbt incremental models with retention filters
- Snowflake scheduled tasks for automated deletion
- Retention standards by data type (transactions, logs, PII, audit)
- Legal hold mechanism for litigation/investigations

**Key Topics**:
- Retention-aware dbt models (`retention:90_days` tag)
- Automated purge tasks (weekly/monthly deletion workflows)
- Retention decision matrix (active, archive, deletion)

### [compliance-automation.md](patterns/compliance-automation.md)
**Policy-as-code and automated governance workflows**

- dbt tests for PII tagging enforcement
- GitHub Actions compliance checks (PII scan, DDM validation)
- Snowflake tasks for periodic access reviews and alerts
- Automated compliance reporting dashboards

**Key Topics**:
- Pre-commit hooks for governance validation
- CI/CD gates for new data sources (PIA completion check)
- Quarterly access review automation
- Policy violation alerting (unusual PII access, failed logins)

---

## Decisions (3 files)

Documented governance decisions, classification taxonomy, retention standards, and compliance priorities.

### [classification-taxonomy.md](decisions/classification-taxonomy.md)
**Chosen classification framework and rationale**

- Four-level sensitivity framework decision (Public → Internal → Confidential → Restricted)
- PII type hierarchy (Direct → Quasi → Sensitive)
- Tag-based classification in dbt (`pii:true`, `pii_type:direct`, `sensitivity:restricted`)

**Rationale**: Aligns with industry standards (NIST, ISO 27001), integrates with dbt tagging strategy (DA-257)

### [retention-standards.md](decisions/retention-standards.md)
**Default retention periods by data type**

- Financial transactions: 7 years (IRS, SOX compliance)
- User activity logs: 90 days active, 1 year archive
- PII: Lifecycle-based (until account deletion + GDPR compliance)
- Audit logs: 7 years (SOC2, GDPR Article 30)
- Segment events: 90 days (high volume, analytics use case)

**Decision**: Automated deletion with manual override capability (reduces compliance risk, scales better)

### [compliance-priorities.md](decisions/compliance-priorities.md)
**Implementation roadmap for regulatory compliance**

- **Phase 1 (Q1 2025)**: GDPR & CCPA baseline (CRITICAL)
  - Data classification, DDM policies, data subject request workflows
- **Phase 2 (Q2-Q3 2025)**: SOC2 Type II (HIGH)
  - Control documentation, change management, vendor management
- **Phase 3**: PCI-DSS (MEDIUM, only if storing payment cards directly)
- **Phase 4**: HIPAA (LOW, deferred until health data integration)

**Rationale**: GDPR/CCPA have strictest penalties and immediate applicability

---

## Reference (3 files)

Quick reference materials including checklists, field catalogs, and schema documentation.

### [gdpr-compliance-checklist.md](reference/gdpr-compliance-checklist.md)
**Actionable checklist for GDPR compliance in data warehouse**

- Legal basis for processing documentation
- Data subject rights implementation (access, erasure, rectification, portability)
- Data protection by design (PII minimization, pseudonymization, encryption)
- Vendor management (DPAs, sub-processor validation, cross-border transfers)
- Breach notification procedures (72-hour notification, incident response)
- Records of Processing Activities (Article 30 register)

### [pii-field-catalog.md](reference/pii-field-catalog.md)
**Comprehensive inventory of PII fields across all data sources**

- `splash_production.users`: email, phone, first_name, last_name, birthdate, zip_code, ip_address
- `segment.tracks`: user_id, anonymous_id, context_ip, context_device_id
- `intercom.conversations`: user_email, user_name, conversation_text (potential embedded PII)
- Masking policy assignments for each PII column

### [audit-log-schema.md](reference/audit-log-schema.md)
**Database schemas for audit tables and compliance reporting**

- `prod.audit.fct_data_access`: Query and access tracking fact table
- `prod.audit.data_subject_requests`: GDPR/CCPA request management
- `prod.audit.data_deletion_log`: Deletion audit trail (right-to-be-forgotten)
- Compliance query templates (GDPR Article 30 report, SOC2 access review)

---

## Usage Guidance

### When to Reference Each Category

**Starting a New Data Source Integration?**
1. Read `core-concepts/privacy-engineering.md` for PIA process
2. Read `patterns/pii-detection-patterns.md` for automated scanning
3. Read `reference/pii-field-catalog.md` for known PII fields
4. Update catalog with new PII fields discovered

**Implementing Data Masking?**
1. Read `core-concepts/data-classification.md` for sensitivity levels
2. Read `patterns/data-masking-strategies.md` for DDM implementation
3. Reference `reference/pii-field-catalog.md` for columns to mask

**Setting Up Compliance Reporting?**
1. Read `core-concepts/audit-trail-architecture.md` for logging framework
2. Read `core-concepts/compliance-frameworks.md` for regulatory requirements
3. Reference `reference/audit-log-schema.md` for report queries

**Defining Retention Policies?**
1. Read `decisions/retention-standards.md` for default periods
2. Read `patterns/retention-policy-implementation.md` for automation
3. Coordinate with legal/compliance team for exceptions

**Preparing for Compliance Audit?**
1. Read `reference/gdpr-compliance-checklist.md` for GDPR readiness
2. Read `core-concepts/compliance-frameworks.md` for framework requirements
3. Run compliance reports from `reference/audit-log-schema.md`

---

## Coordination with Other Agents

**With architect**:
- Classification influences dimensional design (SCD Type 2 for audit trails)
- Conformed dimensions must have consistent PII handling
- Reference: `core-concepts/data-classification.md`, `patterns/data-masking-strategies.md`

**With security-engineer**:
- Governance policies require security controls (encryption, RBAC)
- Reference: `core-concepts/compliance-frameworks.md` (SOC2 controls)

**With bi-platform-engineer**:
- BI dashboards must respect DDM policies and RBAC
- Reference: `patterns/data-masking-strategies.md` (Snowflake DDM)

**With data-pipeline-engineer**:
- Source ingestion must apply classification at entry
- Reference: `patterns/pii-detection-patterns.md` (automated scanning)

---

## Maintenance and Updates

**Monthly**:
- Review new PII fields from data source changes
- Update `reference/pii-field-catalog.md`

**Quarterly**:
- Run access reviews from `reference/audit-log-schema.md`
- Update `decisions/retention-standards.md` if business needs change

**Annually**:
- Review compliance priorities in `decisions/compliance-priorities.md`
- Update `core-concepts/compliance-frameworks.md` for new regulations
- Conduct privacy impact assessments for all major processing activities

**Continuous**:
- Monitor `patterns/compliance-automation.md` for CI/CD failures
- Investigate alerts from `core-concepts/audit-trail-architecture.md`

---

## Quick Links to Key Content

- **GDPR Implementation**: `core-concepts/compliance-frameworks.md` (GDPR section)
- **PII Detection**: `patterns/pii-detection-patterns.md` (Python script, CI/CD integration)
- **Data Masking**: `patterns/data-masking-strategies.md` (Snowflake DDM patterns)
- **Audit Logging**: `core-concepts/audit-trail-architecture.md` (Snowflake account usage)
- **Privacy Impact Assessment**: `core-concepts/privacy-engineering.md` (PIA template)
- **Compliance Checklist**: `reference/gdpr-compliance-checklist.md`

---

**Agent Invocation**: Reference this knowledge base when governance, compliance, privacy, or audit requirements are needed for data warehouse design or operations.
