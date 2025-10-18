---
title: "Data Classification Taxonomy Decisions"
description: "Chosen classification framework and rationale"
category: "decisions"
tags: [classification, taxonomy, decisions]
last_updated: "2025-10-07"
---

# Classification Taxonomy Decisions

## Decision: Four-Level Sensitivity Framework

**Chosen Approach**: Public, Internal, Confidential, Restricted

**Rationale**:
- Aligns with industry standards (NIST, ISO 27001)
- Simple enough for consistent application
- Maps cleanly to RBAC roles in Snowflake
- Supports GDPR/CCPA compliance requirements

## Decision: PII Type Hierarchy

**Direct Identifiers** → **Quasi-Identifiers** → **Sensitive PII**

**Rationale**:
- Direct PII requires strongest controls (DDM, encryption)
- Quasi-identifiers need aggregation/generalization
- Sensitive PII (health, financial) has additional regulatory requirements

## Decision: Tag-Based Classification in dbt

**Tags**: `pii:true`, `pii_type:direct`, `sensitivity:restricted`

**Rationale**:
- Integrates with existing dbt tagging strategy (DA-257)
- Enables selective builds (exclude PII in dev)
- Supports automated validation via dbt tests
- Propagates through lineage automatically
