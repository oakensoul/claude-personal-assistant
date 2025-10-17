# ADR Template

Use this template when creating architecture decision records (ADRs) in project-level documentation.

## Minimal Template

Use this for quick decisions:

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
- [Benefit 2]

**Negative**:
- [Drawback 1]
- **Mitigation**: [How to address]
```

## Full Template

Use this for significant architecture decisions:

```markdown
# ADR-XXX: [Decision Title]

**Status**: [Proposed | Accepted | Deprecated | Superseded by ADR-YYY]
**Date**: YYYY-MM-DD
**Deciders**: [Names or roles]
**Context**: [Software | Data | Infrastructure]
**Tags**: [microservices, api-design, data-modeling, security, etc.]

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

**Description**: [How this option works]

**Pros**:
- [Pro 1]
- [Pro 2]

**Cons**:
- [Con 1]
- [Con 2]

**Cost**: [Time/money/complexity]

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

## Usage Instructions

### Creating a New ADR

1. **Copy template** to your project:

   ```bash
   cp ~/.claude/agents/system-architect/knowledge/reference/adr-template.md \
      .claude/agents-global/system-architect/decisions/adr-XXX-title.md
   ```

2. **Number sequentially**: Use next available number (ADR-001, ADR-002, etc.)

3. **Fill in template**:
   - Replace `[Decision Title]` with descriptive title
   - Set status to "Proposed" initially
   - Document context, options, and rationale
   - Include at least 2-3 considered options

4. **Review and accept**:
   - Get stakeholder review
   - Update status to "Accepted"
   - Implement decision

5. **Update index**:
   - Add to `.claude/agents-global/system-architect/decisions/README.md`

### When to Use Which Template

**Minimal Template**:

- Quick decisions with obvious choice
- Limited options to consider
- Low impact decisions
- Tactical changes within existing architecture

**Full Template**:

- Significant architecture decisions
- Multiple viable options
- High impact decisions
- Technology stack changes
- New patterns or approaches

## Example ADRs

### Example 1: Technology Selection (Full Template)

```markdown
# ADR-001: Use Kimball Dimensional Modeling for Data Warehouse

**Status**: Accepted
**Date**: 2025-02-01
**Deciders**: Data Team, Analytics Director
**Context**: Data
**Tags**: data-modeling, kimball, dimensional-modeling, dbt

## Context and Problem Statement

We're building a data warehouse in Snowflake using dbt. We need to decide on a data modeling approach that balances query performance, maintainability, and analytical flexibility for our business intelligence use cases.

Our analysts use Looker and need sub-second dashboard performance. The team has intermediate SQL skills. We need to track historical changes for key dimensions (customer segments, product categories).

## Decision Drivers

- BI tool query performance (target: < 1 second for dashboards)
- Analyst SQL skill level (intermediate, familiar with star schema)
- Ease of onboarding new analysts
- Historical tracking requirements (SCD Type 2 for customers and products)
- dbt best practices and community patterns
- Warehouse query costs (Snowflake credit consumption)

## Considered Options

### Option A: Kimball Dimensional Modeling

**Description**: Star schema with fact and dimension tables following Ralph Kimball's methodology

**Pros**:
- Optimized for BI tool query performance (single-level joins)
- Analysts already familiar with star schema patterns
- Clear separation of measures (facts) and attributes (dimensions)
- Well-documented SCD Type 2 patterns for historical tracking
- Strong dbt community support (dbt-utils, examples)

**Cons**:
- Requires denormalization (some data redundancy)
- Dimension updates need SCD handling (complexity in dbt)
- Not optimized for operational queries (OLTP)

**Cost**: Medium implementation complexity, low query costs (efficient joins)

### Option B: Data Vault 2.0

**Description**: Hub, link, satellite pattern for enterprise data warehousing

**Pros**:
- Extremely flexible for changing requirements
- Complete historical tracking (all changes captured)
- Audit-friendly (full data lineage)

**Cons**:
- Complex queries (many joins required for business questions)
- Steep learning curve for analysts
- Poor BI tool performance (7-10 joins typical)
- Limited dbt community examples

**Cost**: High implementation complexity, high query costs (many joins)

### Option C: Normalized 3NF

**Description**: Traditional normalized relational database model

**Pros**:
- Familiar to database developers
- No data redundancy (storage efficient)
- Good for operational queries

**Cons**:
- Poor BI query performance (5+ joins typical)
- Complex SQL for business questions
- Not aligned with dbt best practices
- Analysts struggle with complex joins

**Cost**: Low implementation complexity, high query costs (many joins)

## Decision Outcome

**Chosen option**: Option A - Kimball Dimensional Modeling

**Rationale**:
- BI tool performance is critical (dashboards load < 1 second with star schema)
- Analysts already understand dimensional modeling from previous training
- dbt has strong patterns and community support (dbt-utils for SCD, snapshot feature)
- Query cost is lower with star schema (fewer joins = fewer credits)
- Trade-off of denormalization is acceptable (Snowflake storage is cheap, compute is expensive)

### Consequences

**Positive**:
- Fast BI query performance (meets < 1 second target)
- Easy for analysts to write SQL (simple star schema joins)
- Clear data model structure (facts vs dimensions)
- Well-supported by dbt community (examples, packages, patterns)
- Lower Snowflake credit consumption (efficient queries)

**Negative**:
- Denormalization increases storage costs
- **Mitigation**: Snowflake storage is inexpensive ($23/TB/month compressed), query performance matters more
- Dimension updates require SCD Type 2 logic
- **Mitigation**: Use dbt snapshots for SCD Type 2 (built-in feature, well-documented)
- Not suitable for operational queries (OLTP use cases)
- **Mitigation**: Data warehouse is for analytics only (OLTP handled by source systems)

**Neutral**:
- Need to train team on dimensional modeling best practices (grain, measures, SCD)
- Requires documentation of business logic in dimensional models

## Validation

- [x] Aligned with non-functional requirements (< 1 second dashboard performance)
- [x] Reviewed by analytics team and stakeholders
- [x] Cost impact assessed (storage increase acceptable, query cost decrease)
- [x] dbt patterns available (snapshots, incremental models, dbt-utils)
- [x] Team training planned (Kimball methodology workshop)

## Implementation Notes

- Use dbt snapshots for SCD Type 2 dimensions (customer, product, location)
- Follow naming convention: `fct_*` for facts, `dim_*` for dimensions
- Document grain and measures in model YAML (critical for maintainability)
- Use `dbt-utils.generate_surrogate_key()` for surrogate key generation
- Create intermediate layer for complex business logic (staging → intermediate → marts)

## References

- The Data Warehouse Toolkit by Ralph Kimball (book)
- dbt dimensional modeling guide: https://docs.getdbt.com/guides/best-practices/how-we-structure/4-marts
- dbt snapshot docs: https://docs.getdbt.com/docs/build/snapshots
- Related ADR-002: dbt Layering Strategy
- Related ADR-003: SCD Type 2 for Customer Dimension
```

### Example 2: Pattern Decision (Minimal Template)

```markdown
# ADR-005: Use REST APIs for Third-Party Integrations

**Status**: Accepted
**Date**: 2025-03-15
**Deciders**: Engineering Team
**Context**: Software

## Context and Problem Statement

We need to integrate with Stripe (payments), Salesforce (CRM), and SendGrid (email). We need a consistent integration pattern that the team can implement efficiently and maintain easily.

## Decision

Use REST APIs for all third-party integrations.

## Consequences

**Positive**:
- Team has strong REST API experience (faster implementation)
- All vendors support REST (Stripe, Salesforce, SendGrid)
- Simple debugging with curl, Postman, browser dev tools
- Wide ecosystem of client libraries and tooling

**Negative**:
- Not ideal for real-time streaming use cases
- **Mitigation**: Use webhooks where vendors support them (Stripe webhooks for payment events)
```

## Common Mistakes to Avoid

### Don't: Write Implementation Details

**Bad**:

```markdown
## Implementation Notes

Use React.useState to manage form state. Initialize with empty string.
Call API with fetch() using POST method. Handle 401 errors by redirecting to login.
```

**Good**:

```markdown
## Implementation Notes

Use React for frontend framework due to team expertise and component ecosystem.
API authentication uses OAuth 2.0 (see ADR-003 for details).
```

### Don't: Skip Alternatives

**Bad**:

```markdown
## Decision

We chose PostgreSQL.
```

**Good**:

```markdown
## Considered Options

### Option A: PostgreSQL
[Pros, cons, cost]

### Option B: MongoDB
[Pros, cons, cost]

### Option C: DynamoDB
[Pros, cons, cost]

## Decision Outcome

Chosen: PostgreSQL

Rationale: [Why PostgreSQL is best given our drivers]
```

### Don't: Forget to Update Status

**Bad**: ADR created 6 months ago, still says "Proposed" even though decision is implemented

**Good**: Update status to "Accepted" when decision is approved and implemented

## Version History

**v1.0** - 2025-10-15

- Initial ADR template documentation
- Minimal and full template variants
- Usage instructions and examples
- Common mistakes to avoid