---

title: "SQL Expert - Knowledge Base"
description: "Generic SQL patterns and platform-specific features for query optimization"
last_updated: "2025-10-15"

---

# SQL Expert Knowledge Base

This knowledge base contains generic SQL patterns and platform-specific features that apply universally across projects.

## Structure

### Core Concepts

Foundational SQL knowledge that applies to all platforms:

- SQL fundamentals (ANSI SQL standard)
- Query optimization principles
- Indexing strategies
- Transaction management

### Patterns

Reusable SQL patterns for common scenarios:

- CTE patterns (WITH clauses)
- Window functions (ROW_NUMBER, RANK, LAG, LEAD)
- Join patterns (INNER, LEFT, CROSS, SELF)
- Aggregation patterns (GROUP BY, HAVING, rollups)

### Platforms

Platform-specific features and optimizations:

- **Snowflake**: QUALIFY, FLATTEN, time travel, clustering, warehouse optimization
- **PostgreSQL**: jsonb operators, extensions, index types, materialized views
- **BigQuery**: Nested/repeated fields, partitioning, slots, UDFs
- **Redshift**: DISTKEY, SORTKEY, Spectrum, WLM

### Decisions

Decision frameworks for SQL architecture:

- When to use which optimization technique
- Platform feature comparison
- Materialization strategy selection

### Reference

Quick reference materials:

- SQL syntax reference by platform
- Query optimization cookbook
- Common anti-patterns to avoid

## Usage

Knowledge in this directory is **generic** and **reusable** across all projects.

Project-specific SQL standards (SQLFluff rules, CTE naming conventions, performance benchmarks) should be documented in the project-level configuration at:
`{project}/.claude/project/context/sql-expert/index.md`

## Platform Coverage

- ✅ **Snowflake**: Full coverage (data warehousing)
- ✅ **PostgreSQL**: Full coverage (transactional databases)
- 🚧 **BigQuery**: Partial coverage (to be expanded)
- 🚧 **Redshift**: Partial coverage (to be expanded)

## Contributing

When adding new knowledge:

1. Ensure it's **generic** (applies to ANY project using the platform)
2. Document platform-specific features under `platforms/{platform}/`
3. Document cross-platform patterns under `patterns/`
4. Keep project-specific examples OUT of this knowledge base
