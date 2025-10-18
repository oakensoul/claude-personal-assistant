# ADR-009: Skills System Architecture

**Status**: Accepted
**Date**: 2025-10-16
**Deciders**: Project Lead
**Context**: Software
**Tags**: architecture, skills, knowledge-management, reusability

## Context and Problem Statement

AIDA agents need access to specific technical patterns and implementation knowledge. Currently, this knowledge is either duplicated across agent knowledge bases or doesn't exist at all. Multiple agents need the same technical patterns:

- Multiple agents need HIPAA compliance knowledge (governance-analyst, product-engineer, data-engineer, platform-engineer)
- Multiple agents need testing patterns (quality-analyst for analysis, engineers for implementation)
- Multiple agents need framework-specific knowledge (React patterns, API design, dbt strategies)

We need to decide:

- How to organize reusable technical knowledge
- How skills differ from agent knowledge
- Where skills live in the filesystem
- How agents discover and load skills
- Whether skills should have two-tier architecture (user + project)

Without a skills system, we risk:

- Duplicating same knowledge across multiple agents
- Inconsistent patterns across different implementations
- Difficulty updating shared knowledge
- No way to capture project-specific technical patterns

## Decision Drivers

- **Reusability**: Technical patterns should be defined once, used by many agents
- **Consistency**: All agents should use same patterns for same technologies
- **Maintainability**: Update pattern once, applies to all agents using it
- **Discoverability**: Agents should easily find relevant skills
- **Flexibility**: Support both generic and project-specific patterns
- **Clarity**: Clear distinction between agent knowledge and skills

## Considered Options

### Option A: No Skills (Current State)

**Description**: Keep all knowledge in agent knowledge bases

**Pros**:

- Simple (one knowledge location per agent)
- No new concepts to learn

**Cons**:

- Duplicates HIPAA knowledge across 4+ agents
- Duplicates testing patterns across engineers
- Hard to keep patterns consistent
- Can't capture project-specific technical patterns
- No reusability

**Cost**: High duplication, inconsistency

### Option B: Skills as Centralized Knowledge Base

**Description**: Single skills directory, all agents reference it

**Structure**:

```text
~/.claude/skills/
  ├── hipaa-compliance/
  ├── pytest-patterns/
  └── react-patterns/
```

**Pros**:

- Single source of truth
- No duplication
- Easy to update

**Cons**:

- No project-specific skills
- All-or-nothing (can't have project overrides)
- Doesn't fit two-tier philosophy

**Cost**: No project specificity

### Option C: Two-Tier Skills Architecture (Recommended)

**Description**: Skills mirror agent two-tier architecture with user-level and project-level

**Structure**:

```text
User-Level (generic patterns):
~/.claude/skills/
  ├── compliance/
  │   ├── hipaa-compliance/
  │   ├── gdpr-compliance/
  │   └── pci-compliance/
  ├── testing/
  │   ├── pytest-patterns/
  │   ├── playwright-automation/
  │   └── k6-performance/
  └── frameworks/
      ├── react-patterns/
      └── nextjs-setup/

Project-Level (project-specific):
{project}/.claude/skills/
  ├── company-ui-library/     (Company-specific React patterns)
  ├── internal-api-standards/ (Company API conventions)
  └── warehouse-patterns/     (Project-specific dbt patterns)
```

**Pros**:

- Reusability (user-level shared across projects)
- Project-specific patterns (project-level)
- Consistent with two-tier agent architecture
- Agents can combine both tiers
- Easy to promote project skills to user skills

**Cons**:

- Two locations to check
- More complex than single location

**Cost**: Medium complexity, high value

### Option D: Skills Inside Agent Directories

**Description**: Skills live inside agent directories as shared knowledge

**Structure**:

```text
~/.claude/agents/product-engineer/skills/
  ├── react-patterns/
  └── api-design/
```

**Pros**:

- Colocated with agent
- Clear ownership

**Cons**:

- Skills can't be shared across agents (defeats purpose)
- Duplicates skills across multiple agents
- Unclear which agent "owns" a skill

**Cost**: Doesn't solve sharing problem

## Decision Outcome

**Chosen option**: Option C - Two-Tier Skills Architecture

**Rationale**:

1. **Mirrors Agent Architecture**: Skills use same two-tier pattern as agents (ADR-002), creating consistency

2. **Reusability**: User-level skills shared across all projects:
   - `hipaa-compliance` used in healthcare projects
   - `pytest-patterns` used in all Python projects
   - `react-patterns` used in all React projects

3. **Project Specificity**: Project-level skills capture company/project patterns:
   - Company-specific UI component library
   - Internal API design standards
   - Project-specific dbt macro patterns

4. **Gradual Refinement**:
   - Start with generic user-level skills
   - Add project-specific skills as needed
   - Promote good project skills to user-level

5. **Clear Separation**:
   - **Agent knowledge**: HOW to be that agent (role, responsibilities, when to invoke)
   - **Skills**: WHAT technical patterns to apply (HIPAA rules, pytest setup, React hooks)

### Consequences

**Positive**:

- Technical patterns defined once, reused everywhere
- Consistent implementations across agents
- Easy to update patterns (change once, applies everywhere)
- Project-specific patterns captured and shared within project
- Good project patterns can be promoted to user-level
- Clear mental model (same as agent two-tier architecture)

**Negative**:

- Two locations to check (user + project)
  - **Mitigation**: Agents automatically check both, transparent to user
- New concept to learn (what goes in skills vs agent knowledge)
  - **Mitigation**: Clear guidelines, examples, documentation
- Need to organize skills into categories
  - **Mitigation**: Predefined category structure

**Neutral**:

- Skills are markdown files (same as agent knowledge)
- Skills loaded on-demand by agents
- Skills can reference other skills

## Validation

- [x] Consistent with ADR-002 two-tier agent architecture
- [x] Solves knowledge duplication problem
- [x] Supports both generic and project-specific patterns
- [x] Clear guidelines for what goes in skills vs agents
- [x] Scalable (easy to add new skills)
- [x] Reviewed and approved by project lead

## Implementation Notes

### What IS a Skill?

**Definition**: A skill is reusable technical knowledge that multiple agents can use

**Characteristics**:

- **Reusable**: Used by 2+ agents
- **Technical**: Specific implementation knowledge (not strategic)
- **Passive**: No decision-making, just patterns/templates
- **Scoped**: Focused on one technology or pattern

**Examples**:

- ✅ `hipaa-compliance` - HIPAA requirements and patterns
- ✅ `pytest-patterns` - pytest setup and test patterns
- ✅ `api-design` - REST API design conventions
- ❌ `how-to-be-product-engineer` - This is agent knowledge, not a skill
- ❌ `code-review-checklist` - This is analyst knowledge, not a skill

### What is NOT a Skill?

**Agent Knowledge** (lives in agent directory):

- How to be that agent (role definition)
- When to invoke that agent
- Responsibilities and boundaries
- Coordination with other agents

**Example**: `product-engineer/instructions.md`

- "You are a full-stack engineer building user-facing features"
- "Use skills like react-patterns and api-design"
- "Coordinate with platform-engineer for shared services"

**Skills** (lives in skills directory):

- Technical patterns and templates
- Framework-specific knowledge
- Compliance requirements
- Testing patterns

**Example**: `skills/react-patterns/`

- "Component composition patterns"
- "Custom hooks best practices"
- "State management strategies"

### Skill Directory Structure

```text
~/.claude/skills/                      (User-level, generic)
├── compliance/
│   ├── hipaa-compliance/
│   │   ├── README.md                  (Overview, when to use)
│   │   ├── requirements.md            (HIPAA requirements)
│   │   ├── patient-data-handling.md   (PHI handling patterns)
│   │   ├── audit-logging.md           (Audit trail requirements)
│   │   └── encryption.md              (Encryption standards)
│   ├── gdpr-compliance/
│   │   ├── README.md
│   │   ├── requirements.md
│   │   ├── right-to-deletion.md
│   │   ├── consent-management.md
│   │   └── data-minimization.md
│   └── pci-compliance/
│       ├── README.md
│       ├── requirements.md
│       └── payment-handling.md
│
├── testing/
│   ├── pytest-patterns/
│   │   ├── README.md
│   │   ├── setup.md                   (pytest configuration)
│   │   ├── fixtures.md                (Fixture patterns)
│   │   ├── mocking.md                 (Mock/stub patterns)
│   │   └── coverage.md                (Coverage configuration)
│   ├── playwright-automation/
│   │   ├── README.md
│   │   ├── setup.md
│   │   ├── page-objects.md
│   │   ├── test-patterns.md
│   │   └── ci-integration.md
│   └── k6-performance/
│       ├── README.md
│       ├── setup.md
│       ├── load-test-patterns.md
│       ├── metrics.md
│       └── analysis.md
│
├── frameworks/
│   ├── react-patterns/
│   │   ├── README.md
│   │   ├── component-composition.md
│   │   ├── hooks.md
│   │   ├── state-management.md
│   │   └── performance.md
│   ├── nextjs-setup/
│   │   ├── README.md
│   │   ├── app-router.md
│   │   ├── server-components.md
│   │   ├── api-routes.md
│   │   └── deployment.md
│   ├── django-patterns/
│   └── fastapi-patterns/
│
├── api/
│   ├── api-design/
│   │   ├── README.md
│   │   ├── rest-conventions.md
│   │   ├── graphql-schema.md
│   │   ├── versioning.md
│   │   └── documentation.md
│   ├── openapi-spec/
│   └── webhook-patterns/
│
├── data-engineering/
│   ├── dbt-incremental-strategy/
│   │   ├── README.md
│   │   ├── strategies.md             (Full refresh, append, merge)
│   │   ├── performance.md
│   │   └── examples.md
│   ├── airbyte-setup/
│   └── snowflake-optimization/
│
└── infrastructure/
    ├── cdk-patterns/
    ├── terraform-modules/
    └── github-actions-workflows/

{project}/.claude/skills/              (Project-level, specific)
├── acme-ui-library/                   (Company React component library)
│   ├── README.md
│   ├── components.md
│   ├── theming.md
│   └── patterns.md
├── acme-api-standards/                (Company API conventions)
│   ├── README.md
│   ├── naming-conventions.md
│   ├── error-handling.md
│   └── authentication.md
└── warehouse-patterns/                (Project-specific dbt patterns)
    ├── README.md
    ├── naming-conventions.md
    ├── custom-macros.md
    └── testing-strategy.md
```

### Skill README Format

Every skill should have a README.md with:

```markdown
---
title: "Skill Name"
description: "Brief description"
category: "compliance|testing|frameworks|api|data-engineering|infrastructure"
used_by: ["agent-name", "agent-name"]
tags: ["tag1", "tag2"]
last_updated: "YYYY-MM-DD"
---

# Skill Name

## Overview
Brief description of what this skill provides

## When to Use
- Scenario 1
- Scenario 2

## Used By
- agent-name: For specific purpose
- agent-name: For different purpose

## Contents
- [File 1](file1.md) - Description
- [File 2](file2.md) - Description

## Related Skills
- [Other Skill](../other-skill/) - Relationship

## Examples
Practical examples of using this skill
```

### How Agents Use Skills

**Automatic Loading** (agents specify in instructions):

```markdown
# product-engineer Instructions

You are a full-stack engineer building user-facing features.

## Skills You Use

- react-patterns (for React component development)
- api-design (for API endpoint design)
- pytest-patterns (for testing)
- hipaa-compliance (when building healthcare features)
```

**On-Demand Loading** (agents reference as needed):

```markdown
When building React components, consult the react-patterns skill.
When implementing HIPAA-compliant features, consult hipaa-compliance skill.
```

**Project Override** (project skill overrides user skill):

```text
User skill: ~/.claude/skills/frameworks/react-patterns/
Project skill: {project}/.claude/skills/acme-ui-library/

→ Agent uses acme-ui-library for project-specific React patterns
→ Falls back to react-patterns for generic React knowledge
```

### Skill Categories

#### compliance/

- Regulatory compliance (HIPAA, GDPR, PCI, SOC2)
- Used by: governance-analyst, compliance-analyst, all engineers

#### testing/

- Testing frameworks and patterns
- Used by: quality-analyst (defines scenarios), all engineers (implement tests)

#### frameworks/

- Frontend/backend framework patterns
- Used by: product-engineer, platform-engineer, api-engineer

#### api/

- API design and documentation
- Used by: api-engineer, platform-engineer, product-engineer

#### data-engineering/

- Data pipeline patterns
- Used by: data-engineer, sql-expert

#### infrastructure/

- Infrastructure as code patterns
- Used by: aws-cloud-engineer, devops-engineer, platform-engineer

### Agent Knowledge vs Skills Decision Tree

```text
Is this knowledge about HOW to be the agent?
├─ Yes → Agent Knowledge
│  Examples:
│  - "You are a product engineer building user-facing features"
│  - "Coordinate with platform-engineer for shared services"
│  - "Use skills X, Y, Z when appropriate"
│
Is this WHAT technical pattern to apply?
├─ Yes → Skill
│  Examples:
│  - "HIPAA requires encryption at rest and in transit"
│  - "pytest fixtures should use function scope by default"
│  - "React hooks must follow rules of hooks"
│
Is this used by multiple agents?
├─ Yes → Probably a Skill
├─ No → Maybe Agent Knowledge
│
Does it contain autonomous decision-making?
├─ Yes → Agent Knowledge (agents decide, skills don't)
└─ No → Skill (passive knowledge)
```

### Skill Metadata and Discovery

Agents discover skills through:

1. **Explicit references in agent instructions**
2. **Skill README frontmatter** (agents can search by category, tags)
3. **Project context** (project-level skills auto-discovered in project directory)

### Promoting Skills

**Project → User** (good pattern becomes reusable):

```bash
# Copy project skill to user level
cp -r {project}/.claude/skills/good-pattern ~/.claude/skills/category/

# Make generic (remove project-specific details)
# Update README to indicate it's now user-level
```

**User → Project** (override generic pattern):

```bash
# Copy user skill to project
cp -r ~/.claude/skills/category/pattern {project}/.claude/skills/

# Customize for project
# Add project-specific conventions
```

## Migration Plan

### Phase 1: Create Skills Directory Structure

- [ ] Create `~/.claude/skills/` with category structure
- [ ] Create `templates/skills/` with example skills
- [ ] Document skill creation guidelines

### Phase 2: Create Initial Skills

- [ ] Compliance: hipaa-compliance, gdpr-compliance, pci-compliance
- [ ] Testing: pytest-patterns, playwright-automation, k6-performance
- [ ] Frameworks: react-patterns, nextjs-setup
- [ ] API: api-design, openapi-spec
- [ ] Data: dbt-incremental-strategy

### Phase 3: Update Agents to Reference Skills

- [ ] Update agent instructions to list skills they use
- [ ] Remove duplicated knowledge from agents
- [ ] Point agents to skills instead

### Phase 4: Document and Validate

- [ ] Create skill development guide
- [ ] Create examples showing skills in use
- [ ] Validate agents successfully use skills

## Examples

### Example 1: HIPAA Skill Used by Multiple Agents

**Skill**: `~/.claude/skills/compliance/hipaa-compliance/`

**Used by**:

- `governance-analyst` - Audits HIPAA compliance
- `product-engineer` - Implements HIPAA-compliant features
- `data-engineer` - Handles PHI in data pipelines
- `platform-engineer` - Builds HIPAA-compliant services

**Content**:

- requirements.md - HIPAA requirements
- patient-data-handling.md - How to handle PHI
- audit-logging.md - Audit trail requirements
- encryption.md - Encryption standards

### Example 2: Project-Specific React Patterns

**User Skill**: `~/.claude/skills/frameworks/react-patterns/`

- Generic React patterns (hooks, composition, state)

**Project Skill**: `{project}/.claude/skills/acme-ui-library/`

- Company-specific component library
- Overrides generic React patterns with company standards

**product-engineer uses**:

- Project skill for company UI patterns
- Falls back to user skill for generic React knowledge

### Example 3: Testing Skill Chain

**Workflow**:

1. `quality-analyst` uses `pytest-patterns` skill to recommend test structure
2. `product-engineer` uses `pytest-patterns` skill to implement tests
3. Both use same skill, different purposes

## References

- ADR-002: Two-Tier Agent Architecture (established two-tier pattern)
- ADR-006: Analyst/Engineer Pattern (multiple agents need same knowledge)
- ADR-008: Engineers Own Testing (engineers use testing skills)
- Claude Code skills.md system (inspiration)

## Related ADRs

- ADR-002: Two-Tier Agent Architecture (skills follow same pattern)
- ADR-006: Analyst/Engineer Agent Pattern (why multiple agents need same skills)

## Updates

None yet
