---
title: "Agent Migration Plan"
description: "Step-by-step plan for migrating to the Analyst/Engineer agent pattern"
category: "architecture"
tags: ["agents", "migration", "planning"]
last_updated: "2025-10-16"
status: "published"
audience: "developers"
---

# Agent Migration Plan

This document provides a step-by-step plan for migrating AIDA agents from the current structure to the new Analyst/Engineer pattern defined in [ADR-006](./decisions/adr-006-analyst-engineer-agent-pattern.md).

## Overview

**Goal**: Reorganize agents to clearly separate requirements definition (analysts) from implementation (engineers).

**Scope**: 21 existing agents → Reorganized with clear responsibilities

**Timeline**: Phased approach over multiple releases

**Impact**: Major reorganization affecting agent names, responsibilities, and knowledge bases

## Current State Analysis

### Existing Agents by Category

**Leadership & Architecture (4)**:
- system-architect ✅ (keep as-is)
- tech-lead ✅ (keep as-is, enhance with code review responsibilities)
- product-manager ✅ (keep as-is)
- claude-agent-manager ✅ (keep as-is)

**Application Development (3)**:
- code-reviewer ❌ (DELETE - distribute responsibilities)
- security-engineer ✏️ (RENAME to security-analyst)
- qa-engineer ✏️ (RENAME to quality-analyst)

**Data Engineering (3)**:
- data-engineer ✅ (keep as-is, already follows pattern)
- sql-expert ✅ (keep as-is)
- metabase-engineer ✅ (keep as-is)

**Infrastructure & Operations (3)**:
- devops-engineer ✅ (keep as-is)
- aws-cloud-engineer ✅ (keep as-is)
- datadog-observability-engineer ✅ (keep as-is)

**Compliance & Governance (3)**:
- privacy-security-auditor ✏️ (RENAME to compliance-analyst)
- data-governance-agent ✏️ (RENAME to governance-analyst)
- cost-optimization-agent ✅ (keep as-is)

**Specialized (5)**:
- technical-writer ✅ (keep as-is)
- integration-specialist ✅ (keep as-is)
- configuration-specialist ✅ (keep as-is, may merge later)
- shell-script-specialist ✅ (keep as-is)
- shell-systems-ux-designer ✅ (keep as-is)

### Agents to Create

**New Analyst Agents (1)**:
- performance-analyst (NEW)

**New Engineer Agents (3)**:
- product-engineer (NEW)
- platform-engineer (NEW)
- api-engineer (NEW)

## Migration Phases

### Phase 1: Rename Existing Agents (v0.2.0)

**Goal**: Rename agents to match new naming conventions

**Timeline**: 1 week

**Changes**:

| Current Name | New Name | Reason |
|--------------|----------|--------|
| `security-engineer` | `security-analyst` | Defines security requirements, doesn't implement |
| `qa-engineer` | `quality-analyst` | Defines quality requirements, doesn't implement tests |
| `privacy-security-auditor` | `compliance-analyst` | Clearer purpose, no acronyms |
| `data-governance-agent` | `governance-analyst` | Consistent naming, broader scope |

**Tasks**:
- [ ] Rename agent directories in `templates/agents/`
- [ ] Update agent instruction files
- [ ] Update references in CLAUDE.md
- [ ] Update command definitions that reference these agents
- [ ] Create backward compatibility aliases (temporary)
- [ ] Update all documentation

**Backward Compatibility**:
- Keep symlinks from old names → new names for 2 releases
- Add deprecation warnings when old names used
- Document migration in release notes

**Validation**:
- [ ] All commands still work with new names
- [ ] Agent descriptions reflect new analyst role
- [ ] Documentation updated

### Phase 2: Create New Engineering Agents (v0.2.0)

**Goal**: Add new engineering agents for modern development patterns

**Timeline**: 2 weeks

**New Agents**:

#### product-engineer

**Purpose**: Full-stack feature development for end users

**Knowledge Base**:
```
templates/agents/product-engineer/
├── instructions.md
└── knowledge/
    ├── full-stack-patterns.md
    ├── testing-practices.md
    ├── ownership-model.md
    └── skill-integration.md
```

**Responsibilities**:
- User-facing features (Next.js, React, full-stack apps)
- Feature code + tests + monitoring
- Integration with platform services
- End-to-end ownership

**Skills Used**:
- react-patterns, nextjs-setup
- pytest-patterns, playwright-automation
- api-testing, database-patterns

#### platform-engineer

**Purpose**: Build platform capabilities and shared services

**Knowledge Base**:
```
templates/agents/platform-engineer/
├── instructions.md
└── knowledge/
    ├── platform-patterns.md
    ├── service-architecture.md
    ├── internal-apis.md
    └── shared-libraries.md
```

**Responsibilities**:
- Shared services (auth, notifications, email)
- Internal libraries and SDKs
- Developer tools and frameworks
- Infrastructure code (CDK, Terraform)

**Skills Used**:
- microservices-patterns
- cdk-constructs
- service-mesh
- internal-api-design

#### api-engineer

**Purpose**: Build external APIs for partners and third parties

**Knowledge Base**:
```
templates/agents/api-engineer/
├── instructions.md
└── knowledge/
    ├── external-api-patterns.md
    ├── api-versioning.md
    ├── sdk-generation.md
    └── documentation-standards.md
```

**Responsibilities**:
- Public REST/GraphQL APIs
- API documentation (OpenAPI)
- SDK generation and maintenance
- Partner integrations
- Webhooks and events

**Skills Used**:
- api-design
- openapi-spec
- graphql-schema
- webhook-patterns
- sdk-generation

**Tasks**:
- [ ] Create agent directories and instructions
- [ ] Write knowledge base content
- [ ] Define skill dependencies
- [ ] Create example usage scenarios
- [ ] Update CLAUDE.md with new agents
- [ ] Add to agent interaction patterns

**Validation**:
- [ ] Agents can be invoked successfully
- [ ] Knowledge bases provide clear guidance
- [ ] Skills integrate properly
- [ ] Examples demonstrate value

### Phase 3: Create New Analyst Agent (v0.2.0)

**Goal**: Add performance-analyst for performance requirements

**Timeline**: 1 week

**New Agent**: performance-analyst

**Knowledge Base**:
```
templates/agents/performance-analyst/
├── instructions.md
└── knowledge/
    ├── performance-requirements.md
    ├── sla-definitions.md
    ├── load-testing-scenarios.md
    └── performance-metrics.md
```

**Responsibilities**:
- Define performance targets (latency, throughput)
- Set SLAs and error budgets
- Identify performance risks
- Recommend load testing strategies
- Analyze performance test results

**Output**:
- Performance requirements
- SLA definitions
- Load test scenarios
- Performance risk assessments

**Tasks**:
- [ ] Create agent directory and instructions
- [ ] Write knowledge base content
- [ ] Define integration with engineers
- [ ] Create example scenarios
- [ ] Update CLAUDE.md

**Validation**:
- [ ] Can define clear performance requirements
- [ ] Integrates with engineers for implementation
- [ ] Provides actionable guidance

### Phase 4: Remove code-reviewer Agent (v0.2.0)

**Goal**: Distribute code-reviewer responsibilities to specialized analysts

**Timeline**: 1 week

**Current Responsibility Distribution**:

| Concern | Current Agent | New Owner |
|---------|---------------|-----------|
| Architecture review | code-reviewer | tech-lead |
| Design patterns | code-reviewer | tech-lead |
| Security vulnerabilities | code-reviewer | security-analyst |
| OWASP issues | code-reviewer | security-analyst |
| Test coverage | code-reviewer | quality-analyst |
| Edge cases | code-reviewer | quality-analyst |
| Performance issues | code-reviewer | performance-analyst |
| Complexity | code-reviewer | performance-analyst |

**New `/review code` Command Orchestration**:
```
/review code → Orchestrates:
  1. tech-lead (architecture and design)
  2. security-analyst (security vulnerabilities)
  3. quality-analyst (test coverage, edge cases)
  4. performance-analyst (performance, complexity)

→ Combined review report
```

**Tasks**:
- [ ] Update tech-lead to include architecture review responsibility
- [ ] Update security-analyst to include code security review
- [ ] Update quality-analyst to include test coverage review
- [ ] Create performance-analyst with performance review responsibility
- [ ] Update `/review code` command to orchestrate multiple agents
- [ ] Remove code-reviewer agent directory
- [ ] Update all documentation removing code-reviewer references

**Validation**:
- [ ] `/review code` produces comprehensive review
- [ ] All review aspects covered by specialized analysts
- [ ] No loss of functionality from code-reviewer removal

### Phase 5: Create Initial Skills (v0.2.1)

**Goal**: Create foundational skills for common patterns

**Timeline**: 2 weeks

**Skills to Create**:

#### Compliance Skills
```
templates/skills/hipaa-compliance/
├── requirements.md
├── patient-data-handling.md
├── audit-logging.md
└── encryption.md

templates/skills/gdpr-compliance/
├── requirements.md
├── right-to-deletion.md
├── consent-management.md
└── data-minimization.md

templates/skills/pci-compliance/
├── requirements.md
└── payment-handling.md
```

#### Testing Skills
```
templates/skills/pytest-patterns/
├── setup.md
├── fixtures.md
├── mocking.md
└── coverage.md

templates/skills/playwright-automation/
├── setup.md
├── page-objects.md
├── test-patterns.md
└── ci-integration.md

templates/skills/k6-performance/
├── setup.md
├── load-test-patterns.md
├── metrics.md
└── analysis.md
```

#### Framework Skills
```
templates/skills/react-patterns/
├── component-composition.md
├── hooks.md
├── state-management.md
└── performance.md

templates/skills/nextjs-setup/
├── app-router.md
├── server-components.md
├── api-routes.md
└── deployment.md

templates/skills/api-design/
├── rest-conventions.md
├── graphql-schema.md
├── versioning.md
└── documentation.md
```

**Tasks**:
- [ ] Create skills directory structure
- [ ] Write skill content for each pattern
- [ ] Document which agents use which skills
- [ ] Create examples of skill usage
- [ ] Update agent knowledge bases to reference skills

**Validation**:
- [ ] Skills provide clear, actionable patterns
- [ ] Multiple agents can use same skill
- [ ] Skills integrate with agent workflows

### Phase 6: Update Documentation (v0.2.1)

**Goal**: Comprehensive documentation updates

**Timeline**: 1 week

**Documentation to Update**:

#### Primary Documentation
- [ ] README.md - Update agent list
- [ ] CLAUDE.md - Update all agent references
- [ ] docs/CONTRIBUTING.md - Update agent development guidelines

#### Architecture Documentation
- [ ] docs/architecture/README.md - Update architecture overview
- [ ] docs/architecture/c4-system-context.md - Update agent relationships
- [ ] Create new C4 container diagram showing agent types

#### Agent Documentation
- [ ] Each agent README.md - Update descriptions
- [ ] Agent interaction examples
- [ ] Skill integration examples

#### Command Documentation
- [ ] Update all command .md files referencing agents
- [ ] Update `/review code` to show multi-agent orchestration
- [ ] Update `/implement` workflow

**Tasks**:
- [ ] Audit all documentation for agent references
- [ ] Update to new agent names
- [ ] Add examples of new patterns
- [ ] Create migration guide for users

**Validation**:
- [ ] No references to old agent names (except deprecation docs)
- [ ] All examples use correct agents
- [ ] Migration guide is clear and actionable

## Rollback Plan

If critical issues arise during migration:

### Phase 1-2 Rollback
- Restore old agent names from backup
- Revert CLAUDE.md changes
- Keep new engineering agents (no conflicts)

### Phase 3-4 Rollback
- Restore code-reviewer agent
- Remove performance-analyst
- Revert `/review code` command

### Phase 5-6 Rollback
- Skills are additive (no rollback needed)
- Documentation can be reverted via git

## Success Criteria

Migration is successful when:

### Technical Success
- [ ] All renamed agents work correctly
- [ ] New engineering agents functional
- [ ] New analyst agents provide value
- [ ] Skills properly integrated
- [ ] `/review code` orchestrates multiple analysts
- [ ] No functionality regression

### Documentation Success
- [ ] All agent names updated
- [ ] Clear migration guide for users
- [ ] Examples demonstrate new patterns
- [ ] ADRs document decisions

### User Success
- [ ] Users understand analyst vs engineer distinction
- [ ] Clear guidance on which agent to use
- [ ] Improved agent selection (less confusion)
- [ ] Better quality outcomes

## Timeline Summary

| Phase | Version | Duration | Key Deliverables |
|-------|---------|----------|------------------|
| Phase 1 | v0.2.0 | 1 week | Renamed analysts (4 agents) |
| Phase 2 | v0.2.0 | 2 weeks | New engineers (3 agents) |
| Phase 3 | v0.2.0 | 1 week | performance-analyst |
| Phase 4 | v0.2.0 | 1 week | Remove code-reviewer, update /review |
| Phase 5 | v0.2.1 | 2 weeks | Initial skills (15+ skills) |
| Phase 6 | v0.2.1 | 1 week | Documentation update |
| **Total** | **v0.2.1** | **8 weeks** | **Complete migration** |

## Next Steps After Migration

Once migration is complete:

### Continuous Improvement
1. Gather feedback on new agent pattern
2. Refine analyst/engineer boundaries
3. Add more skills as patterns emerge
4. Create project-specific agent knowledge

### Future Enhancements
1. Command consolidation (per issue #44)
2. More specialized analysts (accessibility, cost, etc.)
3. Mobile-engineer for mobile-specific development
4. Enhanced C4 diagrams with agent flows

### Monitoring & Metrics
1. Track agent usage patterns
2. Identify which agents are most valuable
3. Find gaps in coverage
4. Measure user satisfaction

## References

- [ADR-006: Analyst/Engineer Agent Pattern](./decisions/adr-006-analyst-engineer-agent-pattern.md)
- [ADR-007: Product/Platform/API Engineering Model](./decisions/adr-007-product-platform-api-engineering.md)
- [ADR-008: Engineers Own Testing Philosophy](./decisions/adr-008-engineers-own-testing.md)
- [Agent Interaction Patterns](./agent-interaction-patterns.md)
- Issue #44: Command Consolidation (future work)

## Version History

- 2025-10-16: Initial migration plan created
