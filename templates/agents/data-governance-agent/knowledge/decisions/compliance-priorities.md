---
title: "Compliance Framework Priorities"
description: "Implementation roadmap for regulatory compliance"
category: "decisions"
tags: [compliance, roadmap, priorities]
last_updated: "2025-10-07"
---

# Compliance Framework Priorities

## Phase 1: Foundation (Q1 2025) - CRITICAL

**Focus**: GDPR & CCPA baseline compliance

**Deliverables**:
- [ ] Data classification and PII inventory complete
- [ ] Snowflake RBAC and DDM policies deployed
- [ ] Data subject request workflows (access, deletion)
- [ ] Privacy policy updates
- [ ] Basic audit logging (query history, access history)

**Rationale**: GDPR/CCPA have strictest penalties and apply immediately

## Phase 2: SOC2 Type II (Q2-Q3 2025) - HIGH

**Focus**: Enterprise customer requirements

**Deliverables**:
- [ ] Control documentation and evidence collection (6-12 months)
- [ ] Change management formalization (PR approvals, testing)
- [ ] Backup/recovery testing and DR plan
- [ ] Vendor management program (DPAs, security assessments)

**Rationale**: Required for enterprise sales, 6-12 month audit period

## Phase 3: PCI-DSS (if needed) - MEDIUM

**Focus**: Only if storing payment card data directly

**Decision**: Use Stripe tokenization → NO raw card data in warehouse → PCI scope reduced

## Phase 4: HIPAA (if needed) - LOW

**Focus**: Only if integrating health/fitness data

**Decision**: Deferred until product roadmap includes health data
