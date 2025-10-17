# System Architect Knowledge Base

This knowledge base contains architecture patterns, decision frameworks, and reference materials for both traditional software and data engineering architecture.

## Purpose

The system-architect agent uses this knowledge base to provide:

- **System Architecture Guidance**: C4 models, microservices, event-driven architecture, domain-driven design
- **Data Architecture Expertise**: Kimball dimensional modeling, Data Vault 2.0, dbt patterns, medallion architecture
- **Architecture Documentation**: ADRs, C4 diagrams, NFR specifications, dimensional model specs
- **Cross-Cutting Concerns**: Authentication, authorization, observability, resilience, security
- **Technology Selection**: Framework evaluation, build vs buy, vendor selection

## Knowledge Organization

### Core Concepts

Foundational architecture knowledge that applies across projects:

- **c4-modeling.md**: C4 (Context, Container, Component, Code) modeling approach
- **architecture-decision-records.md**: ADR format, when to use, examples
- **kimball-dimensional-modeling.md**: Fact/dimension design, grain, measures, slowly changing dimensions
- **data-vault-2.0.md**: Hub/link/satellite patterns for enterprise data warehouses
- **dbt-architecture-patterns.md**: Layering (staging, intermediate, marts), naming conventions
- **microservices-patterns.md**: Service boundaries, communication patterns, data consistency
- **event-driven-architecture.md**: Event sourcing, CQRS, event streaming, message queues
- **domain-driven-design.md**: Bounded contexts, aggregates, entities, value objects

### Patterns

Reusable architecture patterns with examples and guidance:

- **api-design-patterns.md**: REST, GraphQL, gRPC design principles
- **integration-patterns.md**: Point-to-point, publish-subscribe, request-reply, saga pattern
- **resilience-patterns.md**: Circuit breaker, retry, timeout, bulkhead, fallback
- **data-modeling-patterns.md**: Star schema, snowflake schema, fact types, dimension types
- **incremental-strategies.md**: dbt incremental models, append, merge, delete+insert
- **slowly-changing-dimensions.md**: SCD Type 1, 2, 3 implementation patterns
- **medallion-architecture.md**: Bronze/silver/gold layers, data quality zones

### Decisions

Decision frameworks and criteria for architecture choices:

- **when-to-use-this-agent.md**: Software architect vs tech lead, delegation guidelines
- **technology-selection-framework.md**: Evaluation criteria, scoring matrices, risk assessment
- **build-vs-buy-criteria.md**: When to build custom vs use vendor solutions
- **materialization-decision-matrix.md**: dbt view vs table vs incremental strategies

### Reference

Templates, checklists, and quick reference materials:

- **adr-template.md**: Architecture decision record template
- **c4-diagram-examples.md**: Example C4 models with Mermaid/PlantUML
- **dimensional-model-checklist.md**: Checklist for reviewing dimensional models
- **nfr-requirements-template.md**: Non-functional requirements template
- **architecture-review-checklist.md**: Comprehensive architecture review guide

## How to Use This Knowledge Base

### For Generic Architecture Guidance

Read the core concepts and patterns to understand general best practices that apply across projects.

**Example**: Learning Kimball dimensional modeling for the first time → Read `kimball-dimensional-modeling.md`

### For Project-Specific Architecture

Combine this user-level knowledge with project-level architecture documentation in `{project}/.claude/agents-global/system-architect/`:

- Apply patterns from this knowledge base
- Document decisions as ADRs in project
- Reference project-specific C4 models and dimensional models
- Adapt generic patterns to project constraints

**Example**: Designing a new dimensional model for your dbt project → Read generic Kimball patterns here + refer to existing project dimensional models

### For Architecture Decisions

Use decision frameworks to evaluate options systematically:

1. Review relevant decision framework (e.g., `technology-selection-framework.md`)
2. Apply evaluation criteria to your options
3. Document decision as ADR in project (using `adr-template.md`)
4. Update project-level C4 models or dimensional model specs

### For Architecture Reviews

Use reference checklists to ensure comprehensive review:

1. Review `architecture-review-checklist.md`
2. Apply checklist to project architecture
3. Reference patterns from this knowledge base
4. Document findings and recommendations

## Software vs Data Architecture

This knowledge base covers both domains:

### System Architecture Focus

- System design and C4 models
- Microservices and event-driven patterns
- API design and integration patterns
- Non-functional requirements
- Security and resilience patterns

**Use when**: Building traditional software applications, APIs, microservices, web applications

### Data Architecture Focus

- Kimball dimensional modeling
- dbt project structure and layering
- Data Vault 2.0 patterns
- Incremental strategies and materialization
- Data quality and governance

**Use when**: Building dbt projects, data warehouses, analytics platforms, dimensional models

### Hybrid Projects

Many projects need both:

- **Example 1**: Microservices with event streaming + data warehouse consuming events
- **Example 2**: dbt project with custom Python transformations and orchestration
- **Example 3**: API platform with analytics database for product metrics

Apply patterns from both domains as needed.

## Maintenance

### Adding New Patterns

When you discover new architecture patterns that work well:

1. Create a new file in the appropriate category (core-concepts, patterns, decisions, reference)
2. Follow existing file structure and formatting
3. Include examples and when-to-use guidance
4. Link from this index.md

### Updating Existing Knowledge

When patterns evolve or new best practices emerge:

1. Update the relevant knowledge file
2. Document what changed and why (at end of file)
3. Update any related files that reference the changed pattern
4. Consider creating an ADR in active projects if pattern change affects them

### Review Schedule

- **Monthly**: Review new architecture patterns from recent projects
- **Quarterly**: Comprehensive review of all knowledge files
- **Annually**: Major updates to reflect industry trends (new frameworks, deprecated patterns)

## Related Documentation

- **Agent Definition**: `~/.claude/agents/system-architect/system-architect.md`
- **Project Architecture**: `{project}/.claude/agents-global/system-architect/`
- **Tech Lead Knowledge**: `~/.claude/agents/tech-lead/knowledge/` (implementation-focused)
- **Data Governance Knowledge**: `~/.claude/agents/data-governance-agent/knowledge/` (compliance-focused)

## Contributing

This knowledge base grows over time as you work on projects. When you discover valuable architecture patterns or make important decisions:

1. **User-Level Knowledge** (here): Add if pattern is reusable across projects
2. **Project-Level Knowledge**: Add if decision/pattern is project-specific

**Example**:

- Generic Kimball fact table pattern → Add to this knowledge base
- Specific dimensional model for your SaaS product → Add to project knowledge

## Version History

**v1.0** - 2025-10-15

- Initial knowledge base structure
- Core concepts for software and data architecture
- Pattern library for both domains
- Decision frameworks and reference templates
