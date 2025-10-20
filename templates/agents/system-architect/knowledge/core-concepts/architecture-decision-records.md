# Architecture Decision Records (ADRs)

Architecture Decision Records (ADRs) are lightweight documents that capture important architectural decisions, their context, and their consequences.

## What is an ADR?

An ADR is a document that describes a significant architecture decision, the context and constraints that led to it, the options considered, and the rationale for the chosen solution.

**Purpose**:

- Capture **why** decisions were made (not just what was decided)
- Provide historical context for future team members
- Enable informed evolution of architecture
- Create accountability for architecture choices
- Facilitate architecture reviews

## ADR Format

### Minimal Template

```markdown
# ADR-XXX: [Decision Title]

**Status**: [Proposed | Accepted | Deprecated | Superseded by ADR-YYY]
**Date**: YYYY-MM-DD
**Deciders**: [Names or roles]
**Context**: [Software | Data | Infrastructure]

## Context and Problem Statement

[Describe the problem requiring a decision]

## Decision

[Describe the chosen solution]

## Consequences

**Positive**:
- [Benefit 1]

**Negative**:
- [Drawback 1]
```

### Full Template

```markdown
# ADR-XXX: [Decision Title]

**Status**: [Proposed | Accepted | Deprecated | Superseded by ADR-YYY]
**Date**: YYYY-MM-DD
**Deciders**: [Names or roles]
**Context**: [Software | Data | Infrastructure]
**Tags**: [microservices, api-design, data-modeling, etc.]

## Context and Problem Statement

[Describe the context and the problem requiring a decision. Include:
- What triggered this decision?
- What constraints exist?
- What requirements must be met?]

## Decision Drivers

- [Driver 1: e.g., Performance requirements]
- [Driver 2: e.g., Team expertise]
- [Driver 3: e.g., Budget constraints]
- [Driver 4: e.g., Time to market]

## Considered Options

### Option A: [Name]

**Description**: [How this option works]

**Pros**:
- [Pro 1]
- [Pro 2]

**Cons**:
- [Con 1]
- [Con 2]

**Cost**: [Time/money/complexity]

### Option B: [Name]

[Same structure as Option A]

### Option C: [Name]

[Same structure as Option A]

## Decision Outcome

**Chosen option**: Option X - [Name]

**Rationale**:
- [Reason 1: Why this option is best given the drivers]
- [Reason 2: How it addresses the problem]
- [Reason 3: Trade-offs we're willing to accept]

### Consequences

**Positive**:
- [Positive consequence 1]
- [Positive consequence 2]

**Negative**:
- [Negative consequence 1]
- **Mitigation**: [How we'll address this drawback]

**Neutral**:
- [Neutral consequence 1: Things that change but aren't clearly good/bad]

## Validation

- [ ] Aligned with non-functional requirements
- [ ] Reviewed by stakeholders
- [ ] Cost impact assessed
- [ ] Security implications reviewed
- [ ] Documented in C4 models (if applicable)
- [ ] Team has necessary skills/training

## Implementation Notes

[Optional: Specific guidance for implementing this decision]
- [Note 1]
- [Note 2]

## References

- [Link to C4 model]
- [Link to related ADRs]
- [External documentation]
- [RFC or industry standards]
```

## When to Create an ADR

### Always Create an ADR

**System Architecture**:

- Technology stack selection (framework, language, database)
- Architectural pattern adoption (microservices, event-driven, etc.)
- Authentication/authorization strategy
- API design approach (REST vs GraphQL vs gRPC)
- Data storage strategy (SQL vs NoSQL, sharding approach)
- Integration pattern decisions (sync vs async, message queue selection)
- Deployment model changes

**Data Architecture**:

- Data modeling approach (Kimball vs Inmon vs Data Vault)
- dbt project structure and layering strategy
- Incremental strategy for large fact tables
- SCD (Slowly Changing Dimension) type selection
- Partitioning and clustering strategies
- Data quality framework adoption
- Orchestration tool selection (Airflow, Dagster, Prefect)

### Sometimes Create an ADR

**System Architecture**:

- Third-party library selection (if critical to architecture)
- Caching strategy
- Logging and monitoring approach
- Security hardening measures

**Data Architecture**:

- Naming conventions for dbt models
- Materialization thresholds (view vs table vs incremental)
- Data retention policies
- Test coverage standards

### Don't Create an ADR

**Tactical Decisions** (use tech-lead instead):

- Coding style preferences
- Variable naming conventions
- Code organization within a file
- Specific algorithm implementation choices
- Feature implementation details

**Temporary Decisions**:

- Workarounds or quick fixes
- Decisions that will be revisited soon
- Experimental features not yet production-ready

## ADR Lifecycle

### Status Values

**Proposed**: Decision is being considered, not yet final

- Use when: Gathering feedback, evaluating options
- Next step: Accept or reject

**Accepted**: Decision is approved and should be followed

- Use when: Decision is final and team agrees
- Next step: Implement decision

**Deprecated**: Decision no longer applies but not replaced

- Use when: Technology is end-of-life, approach is no longer valid
- Next step: May be superseded or left deprecated

**Superseded by ADR-XXX**: Decision replaced by a newer decision

- Use when: New ADR changes or replaces this decision
- Next step: Follow the superseding ADR

### Updating ADRs

**When to Update**:

- Status changes (Proposed → Accepted)
- New information emerges
- Consequences are discovered
- Implementation notes are added

**How to Update**:

- Add "Update" section at the end with date and changes
- Don't delete original content (preserve history)
- Link to any superseding ADRs

**Example Update Section**:

```markdown
## Updates

**2025-03-15**: Added security review notes after penetration test
**2025-06-01**: Status changed from Accepted to Superseded by ADR-027
```

## ADR Numbering

### Sequential Numbering

Most common approach: `ADR-001`, `ADR-002`, `ADR-003`

**Pros**:

- Simple and clear
- Easy to reference
- Shows chronological order

**Cons**:

- Doesn't show category

### Categorized Numbering

Use prefixes for categories: `ADR-SOFT-001`, `ADR-DATA-001`, `ADR-INFRA-001`

**Pros**:

- Groups related decisions
- Shows decision domain

**Cons**:

- More complex
- Categories may overlap

**Recommendation**: Use sequential numbering unless you have a large number of ADRs across very different domains.

## Organizing ADRs

### File Structure

```text
.claude/project/agents/system-architect/decisions/
├── README.md (index of all ADRs)
├── adr-001-technology-stack.md
├── adr-002-authentication-strategy.md
├── adr-003-dimensional-modeling-approach.md
├── adr-004-dbt-layering-strategy.md
├── adr-005-incremental-strategy-large-facts.md
└── ...
```

### README.md Index

Keep an index of all ADRs:

```markdown
# Architecture Decision Records

## Active ADRs

- [ADR-001: Technology Stack](adr-001-technology-stack.md) - Accepted - 2025-01-15
- [ADR-002: Authentication Strategy](adr-002-authentication-strategy.md) - Accepted - 2025-01-20
- [ADR-004: dbt Layering Strategy](adr-004-dbt-layering-strategy.md) - Accepted - 2025-02-10

## Superseded ADRs

- [ADR-003: Dimensional Modeling Approach](adr-003-dimensional-modeling-approach.md) - Superseded by ADR-008 - 2025-02-01

## Deprecated ADRs

- [ADR-005: Legacy API Design](adr-005-legacy-api-design.md) - Deprecated - 2025-03-01
```

## Example ADRs

### Example 1: System Architecture

```markdown
# ADR-001: Use REST APIs for External Integrations

**Status**: Accepted
**Date**: 2025-01-15
**Deciders**: Engineering team, CTO
**Context**: Software

## Context and Problem Statement

We need to integrate with multiple third-party services (Stripe, Salesforce, SendGrid). We need to decide on a consistent integration pattern that the team can follow.

## Decision Drivers

- Team familiarity with integration patterns
- Third-party API support (what protocols do vendors offer?)
- Need for real-time vs batch integrations
- Maintenance and debugging complexity

## Considered Options

### Option A: REST APIs

**Pros**:
- Team has strong REST experience
- All vendors support REST
- Simple debugging (curl, Postman)
- Wide tooling support

**Cons**:
- Not ideal for real-time streaming
- Requires polling for some use cases

### Option B: GraphQL

**Pros**:
- Flexible data fetching
- Reduces over-fetching

**Cons**:
- Not all vendors support GraphQL
- Team lacks GraphQL experience
- More complex debugging

### Option C: gRPC

**Pros**:
- High performance
- Strong typing

**Cons**:
- No vendor support
- Team lacks gRPC experience
- Overkill for our use cases

## Decision Outcome

**Chosen option**: Option A - REST APIs

**Rationale**:
- All third-party vendors support REST
- Team has strong REST experience (faster implementation)
- Mature tooling ecosystem
- We don't have real-time requirements yet

### Consequences

**Positive**:
- Faster integration development
- Easy debugging and monitoring
- Consistent pattern across integrations

**Negative**:
- Polling required for some near-real-time use cases
- **Mitigation**: Use webhooks where vendors support them

**Neutral**:
- May need to revisit if we add real-time requirements

## Validation

- [x] Aligned with non-functional requirements (performance is acceptable)
- [x] Reviewed by engineering team
- [x] All vendors support REST
- [x] Team has necessary skills

## References

- Stripe API Docs: https://stripe.com/docs/api
- Salesforce REST API: https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/
```

### Example 2: Data Architecture

```markdown
# ADR-003: Use Kimball Dimensional Modeling for Data Warehouse

**Status**: Accepted
**Date**: 2025-02-01
**Deciders**: Data team, Analytics director
**Context**: Data

## Context and Problem Statement

We're building a data warehouse in Snowflake using dbt. We need to decide on a data modeling approach that balances query performance, maintainability, and analytical flexibility.

## Decision Drivers

- BI tool query performance (sub-second response)
- Analyst SQL skill level (intermediate)
- Ease of onboarding new analysts
- Historical tracking requirements (SCD Type 2)
- dbt best practices and patterns

## Considered Options

### Option A: Kimball Dimensional Modeling

**Description**: Star schema with fact and dimension tables

**Pros**:
- Optimized for BI tool queries
- Analysts familiar with star schema
- Clear separation of measures (facts) and attributes (dimensions)
- Well-documented SCD patterns

**Cons**:
- Some data denormalization required
- Dimension updates need SCD handling

### Option B: Data Vault 2.0

**Description**: Hub, link, satellite pattern

**Pros**:
- Highly flexible for changing requirements
- Complete historical tracking

**Cons**:
- Complex queries (many joins)
- Steep learning curve for analysts
- Not optimized for BI tool performance

### Option C: Normalized 3NF

**Description**: Traditional normalized relational model

**Pros**:
- Familiar to database developers
- No data redundancy

**Cons**:
- Poor BI query performance (many joins)
- Complex SQL for business questions
- Not aligned with dbt patterns

## Decision Outcome

**Chosen option**: Option A - Kimball Dimensional Modeling

**Rationale**:
- BI tools perform best against star schema
- Analysts already understand dimensional modeling
- dbt has strong patterns for dimensional models (dbt-utils, SCD macros)
- Meets performance requirements (< 1 second for dashboard queries)

### Consequences

**Positive**:
- Fast BI query performance
- Easy for analysts to write SQL
- Clear data model structure
- Well-supported by dbt community

**Negative**:
- Denormalization increases storage costs
- **Mitigation**: Snowflake storage is cheap, compute is expensive (query perf matters more)
- Dimension updates require SCD logic
- **Mitigation**: Use dbt snapshot for SCD Type 2

**Neutral**:
- Need to train team on dimensional modeling best practices

## Validation

- [x] Aligned with performance NFRs (< 1 second dashboard loads)
- [x] Reviewed by analytics team
- [x] Cost impact assessed (storage increase acceptable)
- [x] dbt patterns available (snapshots, incremental models)

## Implementation Notes

- Use dbt snapshots for SCD Type 2 dimensions
- Follow naming convention: `fct_*` for facts, `dim_*` for dimensions
- Document grain and measures in model YAML
- Use `dbt-utils` for surrogate key generation

## References

- The Data Warehouse Toolkit by Ralph Kimball
- dbt dimensional modeling guide: https://docs.getdbt.com/guides/best-practices/how-we-structure/4-marts
- dbt snapshot docs: https://docs.getdbt.com/docs/build/snapshots
- Related ADR-004: dbt Layering Strategy
```

## ADRs for dbt Projects

dbt projects benefit from ADRs for:

**Modeling Decisions**:

- Dimensional modeling approach (Kimball, Data Vault, hybrid)
- SCD type selection for dimensions
- Fact table grain definitions
- Conformed dimension strategy

**Technical Decisions**:

- dbt layering strategy (staging → intermediate → marts)
- Incremental strategy for large models
- Materialization thresholds (view vs table)
- Partitioning and clustering strategies
- Data quality testing standards

**Organizational Decisions**:

- Naming conventions
- dbt project structure
- Documentation standards
- Code review requirements

## Common Mistakes

### Mistake 1: Too Much Detail

**Problem**: ADR reads like implementation documentation

**Fix**: Focus on **why** not **how**. Implementation details go in tech specs or code comments.

**Example**:

- **Too detailed**: "Use React.useState for component state, with initial value set to null"
- **Right level**: "Use React for frontend framework due to team expertise and component ecosystem"

### Mistake 2: Not Updating Status

**Problem**: Accepted ADR is no longer being followed

**Fix**: Update status to Deprecated or Superseded when decisions change

### Mistake 3: Trivial Decisions

**Problem**: Creating ADRs for minor decisions that don't affect architecture

**Fix**: Reserve ADRs for architecturally significant decisions

**Example**:

- **Not an ADR**: Variable naming convention
- **Is an ADR**: API authentication strategy

### Mistake 4: No Alternatives Considered

**Problem**: ADR only describes chosen option

**Fix**: Always document at least 2-3 alternatives and why they weren't chosen

## Benefits of ADRs

### For Current Team

- Understand **why** architecture decisions were made
- Avoid re-litigating past decisions
- Reference when making related decisions
- Onboard new team members faster

### For Future Team

- Historical context for architecture evolution
- Understanding of constraints at time of decision
- Rationale for technology choices
- Lessons learned

### For Architecture Reviews

- Audit trail of decisions
- Evidence of thoughtful decision-making
- Identify architectural drift
- Support compliance requirements

## Tools and Automation

### ADR Tools

**adr-tools** (Command-line):

```bash
# Install
brew install adr-tools

# Initialize
adr init docs/decisions

# Create new ADR
adr new "Use REST APIs for External Integrations"
```

**Manual** (Recommended for most projects):

- Create ADRs as markdown files
- Store in git
- Use template from this knowledge base
- Maintain README.md index

### Linking ADRs

Reference related ADRs:

```markdown
## References

- Related to [ADR-001: Technology Stack](adr-001-technology-stack.md)
- Supersedes [ADR-005: Legacy API Design](adr-005-legacy-api-design.md)
- See also [ADR-008: Authentication Strategy](adr-008-authentication-strategy.md)
```

## Version History

**v1.0** - 2025-10-15

- Initial ADR documentation
- Templates for software and data architecture
- Best practices and examples
- Common mistakes and fixes
