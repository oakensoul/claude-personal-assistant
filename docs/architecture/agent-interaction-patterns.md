---
title: "Agent Interaction Patterns"
description: "How AIDA agents collaborate and delegate to accomplish tasks"
category: "architecture"
tags: ["agents", "patterns", "collaboration", "workflow"]
last_updated: "2025-10-16"
status: "published"
audience: "developers"
---

# Agent Interaction Patterns

This document describes how AIDA agents interact, delegate, and collaborate to accomplish tasks.

## Core Principles

### 1. Analyst/Engineer Separation

Agents are organized into two clear categories:

**Analysts** (Requirements Definition):

- Define WHAT needs to be done
- Output requirements, scenarios, constraints
- Do NOT implement

**Engineers** (Implementation):

- Implement HOW based on all analyst requirements
- Own code, tests, deployment, monitoring
- Write all implementation artifacts

See [ADR-006](./decisions/adr-006-analyst-engineer-agent-pattern.md) for rationale.

### 2. Multi-Input Collaboration

A single engineer receives requirements from multiple analysts:

```text
quality-analyst ─────┐
security-analyst ────┤
governance-analyst ──┼──> product-engineer ──> Implementation
performance-analyst ─┤
product-manager ─────┘
```

The engineer integrates ALL requirements into a cohesive implementation.

### 3. Skills as Shared Knowledge

Skills are reusable patterns that multiple agents can use:

```text
Skill: hipaa-compliance

Used by:
- governance-analyst (to audit compliance)
- product-engineer (to implement compliant features)
- platform-engineer (to build compliant services)
- data-engineer (to handle PHI correctly)
```

## Agent Interaction Patterns

### Pattern 1: Feature Development (Multi-Analyst → Engineer)

**Flow**: Multiple analysts provide requirements, engineer implements everything

**Example**: "Add password reset feature"

```text
┌──────────────────┐
│ product-manager  │ → "Users need password reset via email"
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ quality-analyst  │ → "Test 20 scenarios: expired tokens, invalid emails,
└────────┬─────────┘    concurrent requests, malformed input, etc."
         │
         ▼
┌──────────────────┐
│ security-analyst │ → "Use bcrypt, 15-minute token expiry, rate limiting,
└────────┬─────────┘    prevent token reuse, secure random generation"
         │
         ▼
┌───────────────────┐
│ governance-analyst│ → "Log all attempts for SOC2, mask PII in logs,
└────────┬──────────┘    90-day retention, audit trail"
         │
         ▼
┌─────────────────────┐
│ performance-analyst │ → "Complete in <2s for 1000 concurrent users,
└────────┬────────────┘    p95 latency < 500ms"
         │
         ▼
┌──────────────────┐
│ product-engineer │ → Implements EVERYTHING:
└──────────────────┘    - Password reset flow (feature code)
                        - Tests for 20 scenarios (quality requirement)
                        - bcrypt + rate limiting (security requirement)
                        - Audit logging with PII masking (governance req)
                        - Load test for 1000 concurrent users (perf req)
                        - Monitoring for p95 latency

                        Uses skills:
                        - pytest-patterns (testing)
                        - bcrypt-hashing (security)
                        - rate-limiting (security)
                        - audit-logging (governance)
                        - k6-performance (performance testing)
```

**Key Points**:

- Engineer receives requirements from multiple analysts
- Engineer owns complete implementation (feature + tests + security + monitoring)
- Skills provide reusable patterns
- No handoffs between analysts and engineer

### Pattern 2: Architecture Review (Multi-Analyst Collaboration)

**Flow**: Multiple analysts review from different perspectives

**Example**: "/review code" command

```text
User: /review code

Command orchestrates:

┌──────────────┐
│  tech-lead   │ → Reviews architecture and design patterns
└──────┬───────┘    "Use dependency injection here"
       │            "This violates single responsibility principle"
       │
       ▼
┌─────────────────┐
│ security-analyst│ → Reviews security vulnerabilities
└──────┬──────────┘    "SQL injection risk on line 45"
       │                "Missing input validation"
       │
       ▼
┌──────────────────┐
│ quality-analyst  │ → Reviews test coverage and edge cases
└──────┬───────────┘    "Missing tests for error conditions"
       │                "No test for concurrent access"
       │
       ▼
┌─────────────────────┐
│ performance-analyst │ → Reviews performance issues
└─────────────────────┘    "O(n²) complexity in loop"
                            "Database query in loop (N+1 problem)"

All feedback combined into single review report
```

**Key Points**:

- Multiple analysts each provide specialized perspective
- No single "code-reviewer" agent (distributed responsibility)
- Command orchestrates multiple analyst reviews
- Engineer receives integrated feedback

### Pattern 3: Platform Capability Development

**Flow**: Platform-engineer builds capability used by other engineers

**Example**: "Build authentication service"

```text
Step 1: Requirements from analysts
┌──────────────────┐
│ security-analyst │ → "Use OAuth2, JWT tokens, secure storage,
└────────┬─────────┘    MFA support, session management"
         │
         ▼
┌───────────────────┐
│ governance-analyst│ → "Log authentication events, SOC2 compliance,
└────────┬──────────┘    data residency requirements"
         │
         ▼
┌─────────────────────┐
│ performance-analyst │ → "Token validation <50ms, support 10k concurrent
└────────┬────────────┘    sessions, cache tokens"
         │
         ▼

Step 2: platform-engineer implements
┌────────────────────┐
│ platform-engineer  │ → Builds auth service:
└────────────────────┘    - OAuth2 implementation
                          - Token management
                          - MFA support
                          - Monitoring
                          - Documentation for other engineers

Step 3: Other engineers consume
┌──────────────────┐
│ product-engineer │ → Uses auth service in product features
└──────────────────┘    (no need to reimplement auth)

┌─────────────────┐
│ api-engineer    │ → Uses auth service for API authentication
└─────────────────┘
```

**Key Points**:

- platform-engineer builds reusable capabilities
- Other engineers consume platform capabilities
- Avoids duplicate implementation
- Platform capabilities have same quality standards (tests, security, monitoring)

### Pattern 4: API Development (External Focus)

**Flow**: api-engineer builds for external consumption

**Example**: "Create partner API for data access"

```text
Step 1: Requirements
┌──────────────────┐
│ product-manager  │ → "Partners need to query user data, real-time
└────────┬─────────┘    webhook events, bulk export"
         │
         ▼
┌──────────────────┐
│ security-analyst │ → "API keys with rate limiting, OAuth for sensitive
└────────┬─────────┘    data, IP allowlisting, audit all access"
         │
         ▼
┌───────────────────┐
│ governance-analyst│ → "GDPR compliance, data minimization, user consent
└────────┬──────────┘    verification, right to deletion support"
         │
         ▼

Step 2: api-engineer implements
┌───────────────┐
│ api-engineer  │ → Builds partner API:
└───────────────┘    - REST API endpoints (OpenAPI spec)
                     - Authentication (API keys + OAuth)
                     - Webhook system
                     - Rate limiting
                     - SDK generation (Python, JavaScript)
                     - API documentation
                     - Versioning strategy (v1, v2 support)
                     - Tests (contract tests, integration tests)
                     - Monitoring (API usage, errors, latency)

                     Uses skills:
                     - api-design (REST patterns)
                     - openapi-spec (documentation)
                     - rate-limiting (security)
                     - webhook-patterns (event delivery)
                     - sdk-generation (client libraries)
```

**Key Points**:

- api-engineer focuses on external developer experience
- Includes documentation, SDKs, versioning
- Different from internal service APIs (which platform-engineer handles)
- Same quality standards (tests, security, monitoring)

### Pattern 5: Data Pipeline Development

**Flow**: data-engineer builds pipelines with governance

**Example**: "Build pipeline to ingest Salesforce data"

```text
Step 1: Requirements
┌──────────────────┐
│ product-manager  │ → "Need Salesforce opportunities, contacts, accounts
└────────┬─────────┘    in warehouse for reporting"
         │
         ▼
┌───────────────────┐
│ governance-analyst│ → "PII in contacts, must mask emails, GDPR applies,
└────────┬──────────┘    7-year retention for opportunities"
         │
         ▼
┌──────────────────┐
│ quality-analyst  │ → "Validate data quality: no nulls in required fields,
└────────┬─────────┘    referential integrity, duplicate detection"
         │
         ▼
┌─────────────────────┐
│ performance-analyst │ → "Full refresh in <1 hour, incremental every 15
└────────┬────────────┘    minutes, handle 1M+ records"
         │
         ▼

Step 2: data-engineer implements
┌────────────────┐
│ data-engineer  │ → Builds ELT pipeline:
└────────────────┘    - Airbyte connector (Salesforce → Snowflake)
                      - dbt models (staging, dimensional model)
                      - PII masking in dbt
                      - Data quality tests (dbt tests)
                      - Incremental strategy (optimization)
                      - Orchestration (Airflow DAG)
                      - Monitoring (data freshness, row counts, failures)

                      Uses skills:
                      - airbyte-setup (ingestion)
                      - dbt-incremental-strategy (optimization)
                      - dbt-testing (data quality)
                      - pii-masking (governance)
                      - airflow-dag (orchestration)

Step 3: BI consumption
┌────────────────────┐
│ metabase-engineer  │ → Builds dashboards on top of clean data
└────────────────────┘
```

**Key Points**:

- data-engineer owns complete pipeline (ingestion → transformation → quality)
- Governance integrated (PII masking in dbt)
- Quality integrated (dbt tests)
- Performance optimized (incremental strategy)

### Pattern 6: Skill Usage (Cross-Agent)

**Flow**: Multiple agents use the same skill for different purposes

**Example**: HIPAA compliance skill

```text
Skill: hipaa-compliance
├── requirements.md          (HIPAA rules and requirements)
├── patient-data-handling.md (How to handle PHI)
├── audit-logging.md         (Audit trail requirements)
└── encryption.md            (Encryption standards)

Used by different agents:

┌───────────────────┐
│ governance-analyst│ → Uses skill to:
└───────────────────┘    - Audit HIPAA compliance
                         - Identify compliance gaps
                         - Define requirements for engineers

┌──────────────────┐
│ product-engineer │ → Uses skill to:
└──────────────────┘    - Implement HIPAA-compliant features
                        - Encrypt PHI correctly
                        - Add audit logging

┌─────────────────┐
│ data-engineer   │ → Uses skill to:
└─────────────────┘    - Handle PHI in pipelines
                       - Mask sensitive data
                       - Ensure compliant retention

┌──────────────────┐
│ platform-engineer│ → Uses skill to:
└──────────────────┘    - Build HIPAA-compliant auth service
                        - Implement secure storage
                        - Create audit trail infrastructure
```

**Key Points**:

- Single skill, multiple consumers
- Analysts use skills to define requirements
- Engineers use skills to implement requirements
- Consistent compliance across all agents

### Pattern 7: Command Orchestration

**Flow**: Commands orchestrate complex workflows across agents

**Example**: "/implement" command

```text
User: /implement "Add multi-factor authentication"

Command orchestrates workflow:

Step 1: Expert Analysis
┌──────────────────┐
│ product-manager  │ → Defines functional requirements
└──────────────────┘

┌──────────────────┐
│ quality-analyst  │ → Identifies test scenarios
└──────────────────┘

┌──────────────────┐
│ security-analyst │ → Defines security requirements
└──────────────────┘

Step 2: Implementation
┌──────────────────┐
│ product-engineer │ → Implements feature with all requirements
└──────────────────┘

Step 3: Infrastructure
┌─────────────────┐
│ devops-engineer │ → Updates CI/CD for deployment
└─────────────────┘

┌─────────────────────────────┐
│ datadog-observability-engineer│ → Adds monitoring
└─────────────────────────────┘

Step 4: Documentation
┌────────────────────┐
│ technical-writer   │ → Documents feature
└────────────────────┘

Step 5: Commit
Git commit with changes
```

**Key Points**:

- Commands provide high-level workflow orchestration
- Commands invoke multiple agents in sequence
- Each agent contributes their expertise
- Workflow automation reduces manual coordination

## Delegation Guidelines

### When to Delegate

**Analysts delegate to engineers**:

- analyst defines requirements → engineer implements

**Engineers delegate to other engineers**:

- product-engineer needs auth → platform-engineer provides auth service
- product-engineer needs external API → api-engineer designs API

**Architects coordinate**:

- system-architect coordinates cross-cutting concerns
- tech-lead enforces standards across all engineers

**Commands orchestrate**:

- Complex workflows involving multiple agents
- Standardized processes (implement, review, deploy)

### When NOT to Delegate

**Don't delegate within same tier**:

- quality-analyst should NOT delegate to security-analyst (same tier)
- Instead, both provide requirements to engineer independently

**Don't create circular dependencies**:

- engineer → analyst → engineer (avoid ping-pong)
- Instead, analyst provides complete requirements upfront

**Don't fragment implementation**:

- ONE engineer owns feature (not split across multiple engineers)
- Exception: Platform capabilities consumed by product engineers

## Anti-Patterns to Avoid

### Anti-Pattern 1: Analyst Implements

**Wrong**:

```text
quality-analyst writes tests
security-analyst implements security features
```

**Right**:

```text
quality-analyst defines test scenarios
security-analyst defines security requirements
engineer implements BOTH
```

### Anti-Pattern 2: Engineer Defines Requirements

**Wrong**:

```text
product-engineer decides what to test
product-engineer decides security requirements
```

**Right**:

```text
quality-analyst defines what to test
security-analyst defines security requirements
product-engineer implements both
```

### Anti-Pattern 3: Split Implementation

**Wrong**:

```text
product-engineer writes feature code
test-automation-engineer writes tests (HANDOFF)
```

**Right**:

```text
quality-analyst defines test scenarios
product-engineer writes feature code AND tests (NO HANDOFF)
```

### Anti-Pattern 4: Unclear Agent Selection

**Wrong**:

```text
User: "Build API"
→ Which engineer? product? platform? api?
```

**Right**:

```text
User: "Build API for partners" → api-engineer (external audience)
User: "Build API for user dashboard" → product-engineer (internal to product)
User: "Build API for service-to-service" → platform-engineer (internal platform)
```

## Agent Selection Decision Trees

### Which Engineer for Implementation?

```text
Is this data/analytics work?
├─ Yes → data-engineer
└─ No → Who is the primary audience?
         ├─ End users/customers → product-engineer
         ├─ External developers/partners → api-engineer
         └─ Internal engineers/services → platform-engineer
```

### Which Analyst for Requirements?

```text
What type of requirements?
├─ Functional (features, user stories) → product-manager
├─ Quality (test scenarios, coverage) → quality-analyst
├─ Security (vulnerabilities, threats) → security-analyst
├─ Compliance (GDPR, HIPAA, SOC2) → governance-analyst / compliance-analyst
└─ Performance (latency, throughput, SLAs) → performance-analyst
```

### Skill vs Agent?

```text
Is this reusable knowledge?
├─ Yes → Skill (e.g., hipaa-compliance, react-patterns)
│
Is this autonomous decision-making?
├─ Yes → Agent (e.g., security-analyst, product-engineer)
│
Is this a workflow?
└─ Yes → Command (e.g., /implement, /review)
```

## Two-Tier Architecture Integration

Both analysts and engineers use two-tier architecture:

**User-Level** (`~/.claude/agents/{agent}/`):

- Generic knowledge for that agent type
- Reusable patterns and frameworks

**Project-Level** (`{project}/.claude/project/context/{agent}/`):

- Project-specific context
- Project standards and decisions

**Skills** (`~/.claude/skills/` or project-level):

- Reusable patterns shared across agents
- Can also be two-tier (user + project)

See [ADR-002](./decisions/adr-002-two-tier-agent-architecture.md) for details.

## Examples

### Example 1: Simple Feature

```text
User: "Add dark mode toggle"

Flow:
1. product-manager → "Toggle in settings, persists preference"
2. quality-analyst → "Test toggle works, persists on refresh, applies across app"
3. product-engineer → Implements feature + tests + monitoring
```

### Example 2: Complex Security Feature

```text
User: "Implement OAuth2 authentication"

Flow:
1. product-manager → "Users authenticate with Google/GitHub"
2. security-analyst → "Use OAuth2, secure token storage, PKCE flow, validate state"
3. governance-analyst → "Consent screen required, log auth events, GDPR compliance"
4. performance-analyst → "Token validation <50ms, support 10k concurrent sessions"
5. platform-engineer → Implements auth service (platform capability)
6. product-engineer → Integrates auth service into product features
```

### Example 3: Data Pipeline

```text
User: "Build customer analytics pipeline"

Flow:
1. product-manager → "Need customer behavior metrics for product decisions"
2. governance-analyst → "Customer data has PII, GDPR applies, 2-year retention"
3. quality-analyst → "Validate data freshness, no duplicate customers, referential integrity"
4. performance-analyst → "Incremental updates every hour, handle 10M+ customers"
5. data-engineer → Implements pipeline + transformation + quality tests + governance
6. metabase-engineer → Builds dashboards on clean data
```

## Related Documentation

- [ADR-006: Analyst/Engineer Agent Pattern](./decisions/adr-006-analyst-engineer-agent-pattern.md)
- [ADR-007: Product/Platform/API Engineering Model](./decisions/adr-007-product-platform-api-engineering.md)
- [ADR-008: Engineers Own Testing Philosophy](./decisions/adr-008-engineers-own-testing.md)
- [ADR-002: Two-Tier Agent Architecture](./decisions/adr-002-two-tier-agent-architecture.md)
