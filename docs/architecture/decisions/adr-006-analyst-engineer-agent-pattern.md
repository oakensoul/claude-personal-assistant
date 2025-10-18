# ADR-006: Agent Reorganization to Analyst/Engineer Pattern

**Status**: Accepted
**Date**: 2025-10-16
**Deciders**: Project Lead
**Context**: Software
**Tags**: architecture, agents, organization, sdlc

## Context and Problem Statement

AIDA's current agent structure mixes requirements definition with implementation responsibilities. Agents like `security-engineer`, `qa-engineer`, and `code-reviewer` blur the line between identifying WHAT needs to be done and HOW to implement it. This creates confusion about agent responsibilities and doesn't reflect how modern software teams actually work.

We need to decide how to organize agents to:

- Clearly separate requirements definition from implementation
- Mirror real-world software team structures
- Enable multiple domain experts to feed requirements to implementers
- Ensure engineers own all aspects of their code (tests, security, monitoring)

Without a clear separation, we risk:

- Agents with unclear, overlapping responsibilities
- Engineers not owning their test implementation
- Security/quality becoming separate handoffs rather than integrated
- Confusion about which agent to invoke for a given task

## Decision Drivers

- **Clarity**: Each agent should have a clear, non-overlapping purpose
- **Reality**: Should mirror how modern software teams actually work
- **Ownership**: Engineers should own all aspects of their code
- **Integration**: Security, quality, performance should integrate into engineering, not be separate
- **Scalability**: Easy to add new domain experts without creating implementation silos
- **Maintainability**: Clear patterns for agent interaction and delegation

## Considered Options

### Option A: Keep Current Mixed-Responsibility Model

**Description**: Continue with agents that both define requirements and implement solutions (e.g., `security-engineer`, `qa-engineer`)

**Pros**:

- No migration needed
- Familiar to existing users
- Simple one-agent-per-concern model

**Cons**:

- Unclear whether agent defines requirements or implements them
- Creates handoff delays (QA writes tests, not engineers)
- Doesn't reflect modern practices (engineers own their tests)
- Overlapping responsibilities (code-reviewer vs tech-lead)
- Hard to combine multiple concerns (security + quality + performance)

**Cost**: Continued confusion, doesn't scale

### Option B: Functional Split (Frontend/Backend/QA/Security)

**Description**: Organize by traditional functional roles:

```text
frontend-engineer/
backend-engineer/
qa-engineer/
security-engineer/
```

**Pros**:

- Familiar traditional model
- Clear functional boundaries

**Cons**:

- Frontend/backend split doesn't fit modern full-stack development
- Perpetuates separate QA (engineers should own tests)
- Security remains a handoff, not integrated
- Doesn't reflect how modern teams work (full-stack, DevOps culture)
- Doesn't handle microservices, serverless well

**Cost**: Outdated model, doesn't match modern practices

### Option C: Analyst/Engineer Pattern (Recommended)

**Description**: Split agents into two clear categories:

**Analysts** (Requirements Definition):

- Define WHAT needs to be done from their domain expertise
- Output requirements, scenarios, constraints
- Do NOT implement
- Examples: quality-analyst, security-analyst, governance-analyst, performance-analyst

**Engineers** (Implementation):

- Implement HOW based on ALL analyst requirements
- Own code AND tests AND security AND monitoring
- Write all implementation artifacts
- Examples: product-engineer, platform-engineer, api-engineer, data-engineer

**Pros**:

- Crystal clear separation: analysts define requirements, engineers implement
- Mirrors real-world teams (business analysts, security analysts, engineers)
- Multiple analysts can feed one engineer (quality + security + governance → product-engineer)
- Engineers own ALL aspects (no testing handoff)
- Scales naturally (add new analyst types without implementation silos)
- Integration over handoff (security/quality integrated into engineering)

**Cons**:

- Requires renaming/reorganizing existing agents
- Users need to learn new pattern
- More agents overall (but clearer responsibilities)

**Cost**: Medium migration effort, high long-term clarity

### Option D: Extreme Specialization

**Description**: Create highly specialized agents for every concern:

```text
unit-test-engineer/
integration-test-engineer/
e2e-test-engineer/
api-security-engineer/
frontend-security-engineer/
etc.
```

**Pros**:

- Deep expertise per narrow domain

**Cons**:

- Agent explosion (20+ agents)
- Coordination nightmare
- Fragmentation of knowledge
- Hard to understand which agent to use
- Doesn't reflect team structure

**Cost**: Too complex, unmanageable

## Decision Outcome

**Chosen option**: Option C - Analyst/Engineer Pattern

**Rationale**:

1. **Mirrors Modern Teams**: Real software teams have business analysts who define requirements and engineers who implement everything. This pattern reflects reality.

2. **Clear Separation of Concerns**:
   - **Analysts**: WHAT needs to be done (requirements, scenarios, constraints)
   - **Engineers**: HOW to implement it (code, tests, deployment, monitoring)

3. **Engineers Own Quality**: Testing is just code. Engineers who write features also write tests. No handoff delays.

4. **Multi-Concern Integration**: A single engineer can receive requirements from multiple analysts:
   - quality-analyst: "Test these 20 edge cases"
   - security-analyst: "Use bcrypt, rate limiting, input validation"
   - governance-analyst: "Log for audit, mask PII"
   - performance-analyst: "Must handle 1000 concurrent users"
   - product-engineer: Implements ALL requirements together

5. **Scalable**: Easy to add new analyst types (accessibility-analyst, cost-analyst) without creating new implementation silos.

6. **Industry Alignment**: Matches shift-left practices (security/quality integrated from the start, not bolted on later).

### Consequences

**Positive**:

- Clear, non-overlapping agent responsibilities
- Analysts can specialize deeply in their domain
- Engineers have full ownership of their code
- No testing handoff delays (engineers write their own tests)
- Multiple analyst perspectives integrated into implementation
- Easy to add new analyst types
- Matches how modern software teams actually work
- Supports full-stack engineering (not artificial frontend/backend split)

**Negative**:

- Requires renaming existing agents (migration effort)
  - **Mitigation**: Provide clear migration guide, maintain backward compatibility temporarily
- More total agents than current structure
  - **Mitigation**: Clearer responsibilities mean easier to understand which agent to use
- Users need to learn analyst vs engineer distinction
  - **Mitigation**: Document pattern clearly, update all agent descriptions
- Existing agent knowledge needs reorganization
  - **Mitigation**: Phased migration, one agent at a time

**Neutral**:

- Commands orchestrate analyst + engineer workflows
- Skills become shared knowledge across both analysts and engineers
- Two-tier architecture still applies (user-level + project-level)

## Validation

- [x] Aligned with modern software team practices (DevOps, shift-left, full-stack)
- [x] Clear separation of requirements vs implementation
- [x] Supports multiple analyst inputs to single engineer
- [x] Engineers own all aspects of their code (tests, security, monitoring)
- [x] Scalable (easy to add new analyst types)
- [x] Reviewed and approved by project lead

## Implementation Notes

### Analyst Agents (Requirements Definition)

**Naming Convention**: `{domain}-analyst`

**Purpose**: Define WHAT needs to be done from their domain expertise

**Output**: Requirements documents, scenarios, constraints, checklists

**Examples**:

- **quality-analyst**: Identifies test scenarios, edge cases, coverage requirements
- **security-analyst**: Defines security requirements, threat models, vulnerabilities
- **governance-analyst**: Defines compliance rules, data handling policies
- **performance-analyst**: Defines performance targets, SLAs, load requirements
- **compliance-analyst**: Verifies compliance with regulations (GDPR, HIPAA, SOC2)

**Does NOT**: Write implementation code or tests

### Engineer Agents (Implementation)

**Naming Convention**: `{domain}-engineer`

**Purpose**: Implement HOW based on ALL analyst requirements

**Output**: Code, tests, deployment configs, monitoring setup

**Examples**:

- **product-engineer**: Full-stack feature implementation (UI + API + tests + monitoring)
- **platform-engineer**: Shared services, libraries, internal tools
- **api-engineer**: External/partner APIs, SDKs, public contracts
- **data-engineer**: Data pipelines, ELT, data quality

**Responsibilities**:

- Write feature code
- Write ALL tests (unit, integration, E2E, performance)
- Implement security requirements
- Add monitoring/observability
- Ensure compliance with governance policies
- Meet performance targets

### Agent Interaction Pattern

```text
User Request: "Add password reset feature"
    ↓
product-manager (functional requirements)
    → "Users need password reset via email"
    ↓
quality-analyst (quality requirements)
    → "Test 20 scenarios: expired tokens, invalid emails, concurrent requests"
    ↓
security-analyst (security requirements)
    → "bcrypt hashing, 15-minute token expiry, rate limiting"
    ↓
governance-analyst (compliance requirements)
    → "Log all attempts for SOC2, mask PII, 90-day retention"
    ↓
performance-analyst (performance requirements)
    → "Complete in <2 seconds for 1000 concurrent users"
    ↓
product-engineer (implementation)
    → Implements feature with ALL requirements:
       - Builds password reset flow
       - Writes tests covering 20 scenarios
       - Implements bcrypt + rate limiting
       - Adds audit logging with PII masking
       - Ensures performance targets met
       - Uses skills: pytest-patterns, bcrypt-hashing, rate-limiting
```

### Migration Plan

#### Phase 1: Rename Existing Agents

- `security-engineer` → `security-analyst`
- `qa-engineer` → `quality-analyst`
- `privacy-security-auditor` → `compliance-analyst`
- `data-governance-agent` → `governance-analyst`

#### Phase 2: Create New Engineering Agents

- Create `product-engineer` (full-stack features)
- Create `platform-engineer` (platform services)
- Create `api-engineer` (external APIs)
- Enhance `data-engineer` (already follows pattern)

#### Phase 3: Remove Redundant Agents

- Delete `code-reviewer` (distribute to tech-lead, security-analyst, quality-analyst)

#### Phase 4: Update Documentation

- Update all agent descriptions
- Update command definitions
- Create agent interaction pattern documentation
- Update CLAUDE.md with new agent list

## References

- Modern DevOps practices: Engineers own testing, security, deployment
- Shift-left security: Security integrated from design, not bolted on later
- Full-stack engineering: Engineers own entire feature, not split frontend/backend
- Similar pattern: Business analysts define requirements, engineers implement
- ADR-002: Two-tier agent architecture (still applies at both analyst and engineer levels)

## Related ADRs

- ADR-007: Product/Platform/API Engineering Model (defines engineer agent types)
- ADR-008: Engineers Own Testing Philosophy (explains why engineers write tests)

## Updates

None yet
