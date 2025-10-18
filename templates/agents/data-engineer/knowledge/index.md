---

title: "Data Engineer - Knowledge Base"
description: "Generic data engineering patterns for orchestration, dbt, ingestion, and data quality"
last_updated: "2025-10-15"

---

# Data Engineer Knowledge Base

This knowledge base contains generic data engineering patterns and best practices that apply universally across all data projects.

## Structure

### Core Concepts
Foundational data engineering knowledge:

- **Orchestration Principles**: DAG design, scheduling strategies, dependency management
- **dbt Framework**: Core concepts, commands, materializations, testing, Jinja
- **Incremental Processing**: Merge strategies, partition-based processing, idempotency
- **Data Quality Frameworks**: Test pyramid, data contracts, reconciliation patterns
- **Pipeline Observability**: Monitoring, alerting, SLA tracking, data freshness

### Patterns
Reusable patterns for common data engineering scenarios:

- **Ingestion Patterns**: CDC, batch loading, stream processing, API polling, file-based
- **Airbyte Integration**: Connector patterns, normalization, webhook orchestration
- **Fivetran Integration**: Sync patterns, soft deletes, schema drift handling
- **dbt Best Practices**: Materialization strategies, testing patterns, macro development
- **dbt Performance Optimization**: Query tuning, incremental strategies, ref optimization
- **CI/CD Pipeline Automation**: GitHub Actions patterns, slim CI, deployment strategies
- **ELT vs ETL**: Modern data stack patterns, when to use each approach

### Decisions
Decision frameworks for data engineering:

- **Materialization Strategy Selection**: When to use table/view/incremental/ephemeral
- **Build Schedule Optimization**: Frequency tradeoffs, resource planning
- **Tool Selection Matrix**: Airflow vs Prefect vs GitHub Actions vs Dagster
- **Incremental Strategy**: Merge vs delete+insert vs append

### Reference
Quick reference materials:

- **dbt Commands Reference**: Selection syntax, target environments, common patterns
- **Orchestrator Command Patterns**: Airflow CLI, Prefect CLI, common troubleshooting
- **Data Engineering Anti-Patterns**: What to avoid in pipeline design

## Usage

Knowledge in this directory is **generic** and **reusable** across all data engineering projects.

Project-specific implementation details (pipeline schedules, source systems, dbt config) should be documented in the project-level configuration at:
`{project}/.claude/agents-global/data-engineer/index.md`

## dbt Knowledge

As the owner of the "T" (Transform) in ELT, this agent includes comprehensive dbt framework knowledge:

### dbt Core Concepts

- Commands: run, test, build, compile, docs generate, source freshness
- Materializations: table, view, incremental, ephemeral
- Testing: schema tests, data tests, singular tests
- Jinja: Templating, macros, control structures
- Packages: Hub packages, dependencies, version management
- Hooks: pre-hook, post-hook, on-run-start, on-run-end
- Seeds & Snapshots: Static data loading, SCD tracking

### dbt Project Patterns

- Layering: staging → intermediate → core → marts
- Naming conventions: stg_, int_, fct_, dim_, rpt_
- Testing strategies: Coverage by layer, test pyramid
- Documentation: Model descriptions, column descriptions
- CI/CD: Slim CI, state-based execution, environment promotion

## Technology Coverage

- ✅ **dbt**: Full coverage (core transformation tool)
- ✅ **Airbyte**: Full coverage (open-source ingestion)
- ✅ **Fivetran**: Full coverage (managed ingestion)
- ✅ **GitHub Actions**: Full coverage (orchestration)
- 🚧 **Airflow**: Partial coverage (to be expanded)
- 🚧 **Prefect**: Partial coverage (to be expanded)
- 🚧 **Dagster**: Basic coverage (to be expanded)

## Contributing

When adding new knowledge:

1. Ensure it's **generic** (applies to ANY data project)
2. Document dbt patterns under relevant sections
3. Document orchestration patterns separately from tool-specific implementation
4. Keep project-specific examples OUT of this knowledge base
5. Focus on patterns and principles, not specific project configurations
