---
title: "dbt Framework Overview"
description: "Core dbt concepts, commands, and workflow patterns"
category: "core-concepts"
last_updated: "2025-10-15"
---

# dbt Framework Overview

## What is dbt?

dbt (data build tool) is a transformation framework that enables data analysts and engineers to transform data in their warehouse using SQL and software engineering best practices.

## Core Concepts

### The "T" in ELT
dbt handles the **Transform** step in Extract, Load, Transform:
- **Extract**: Ingestion tools (Airbyte, Fivetran) pull data from sources
- **Load**: Data is loaded into the warehouse (Snowflake, BigQuery, Redshift)
- **Transform**: dbt transforms raw data into analytics-ready models

### Models
Models are SELECT statements that define transformations:
```sql
-- models/staging/stg_orders.sql
WITH source AS (
    SELECT * FROM {{ source('raw', 'orders') }}
),

renamed AS (
    SELECT
        id AS order_id,
        user_id,
        order_date,
        order_amount
    FROM source
)

SELECT * FROM renamed
```

### Materializations
How dbt persists models in the warehouse:

**Table** - Full refresh, creates physical table:
```sql
{{ config(materialized='table') }}
```

**View** - Virtual table, no data stored:
```sql
{{ config(materialized='view') }}
```

**Incremental** - Only processes new/changed data:
```sql
{{ config(
    materialized='incremental',
    unique_key='order_id'
) }}
```

**Ephemeral** - CTE only, not persisted:
```sql
{{ config(materialized='ephemeral') }}
```

## Key Commands

### Core Workflow Commands
```bash
# Compile models (generate SQL)
dbt compile

# Run all models
dbt run

# Run tests
dbt test

# Run + test in one command
dbt build

# Generate documentation
dbt docs generate

# Serve docs locally
dbt docs serve
```

### Selection Syntax
```bash
# Run specific model
dbt run --select my_model

# Run model + downstream
dbt run --select my_model+

# Run upstream + model
dbt run --select +my_model

# Run tag-based selection
dbt run --select tag:finance

# Run modified models (slim CI)
dbt build --select state:modified+ --defer --state prod-manifest/
```

### Target Environments
```bash
# Run against dev environment
dbt run --target dev

# Run against production
dbt run --target prod

# Run against CI/CD build environment
dbt run --target build
```

## Testing Framework

### Schema Tests (built-in)
```yaml
models:
  - name: stg_orders
    columns:
      - name: order_id
        tests:
          - unique
          - not_null
      - name: user_id
        tests:
          - relationships:
              to: ref('stg_users')
              field: user_id
```

### Data Tests (custom SQL)
```sql
-- tests/assert_positive_order_amounts.sql
SELECT *
FROM {{ ref('stg_orders') }}
WHERE order_amount <= 0
```

### Singular Tests
One-off tests for specific business logic.

## Jinja Templating

### ref() Function
Reference other dbt models (creates dependencies):
```sql
SELECT * FROM {{ ref('stg_orders') }}
```

### source() Function
Reference raw data sources:
```sql
SELECT * FROM {{ source('raw', 'orders') }}
```

### Macros
Reusable SQL snippets:
```sql
{% macro cents_to_dollars(column_name) %}
    ({{ column_name }} / 100)::decimal(10,2)
{% endmacro %}

-- Usage
SELECT {{ cents_to_dollars('order_amount') }} AS order_amount
```

### Control Structures
```sql
{% if target.name == 'prod' %}
    WHERE is_deleted = FALSE
{% else %}
    -- Include deleted records in dev
{% endif %}
```

## Project Structure

```
dbt_project/
├── dbt_project.yml       # Project configuration
├── profiles.yml          # Connection profiles
├── models/
│   ├── staging/          # 1:1 with sources
│   ├── intermediate/     # Business logic
│   ├── core/             # Facts and dimensions
│   └── marts/            # Domain-specific models
├── tests/                # Custom data tests
├── macros/               # Reusable SQL snippets
├── seeds/                # Static CSV data
├── snapshots/            # SCD tracking
└── analyses/             # Ad-hoc queries
```

## dbt Packages

### Installing Packages
```yaml
# packages.yml
packages:
  - package: dbt-labs/dbt_utils
    version: 1.1.1
  - package: calogica/dbt_expectations
    version: 0.10.0
```

```bash
dbt deps  # Install packages
```

### Common Packages
- **dbt_utils**: Utility macros (surrogate keys, date spine, etc.)
- **dbt_expectations**: Great Expectations-style tests
- **dbt_project_evaluator**: Project quality checks
- **codegen**: Code generation utilities

## Hooks

### Pre/Post Hooks
Run SQL before or after model execution:
```sql
{{ config(
    pre_hook="GRANT USAGE ON SCHEMA {{ target.schema }} TO analyst_role",
    post_hook="GRANT SELECT ON {{ this }} TO analyst_role"
) }}
```

### on-run-start / on-run-end
Run at project level:
```yaml
# dbt_project.yml
on-run-start:
  - "{{ log_run_start() }}"

on-run-end:
  - "{{ log_run_end() }}"
```

## Best Practices

### Layering
- **Staging**: 1:1 with sources, light transformations
- **Intermediate**: Business logic, joins (no direct BI access)
- **Core**: Facts and dimensions (Kimball methodology)
- **Marts**: Domain-specific, BI-ready

### Naming Conventions
- `stg_` - Staging models
- `int_` - Intermediate models
- `fct_` - Fact tables
- `dim_` - Dimension tables
- `rpt_` - Report models

### CTE Patterns
- `base_*` - Initial CTEs pulling from sources
- `renamed` - Column renaming
- `filtered` - WHERE clause filters
- `joined` - JOIN operations
- `aggregated` - GROUP BY aggregations
- `final` - Final CTE before SELECT

### Documentation
Every model should have:
- Model-level description
- Column-level descriptions for key fields
- Tags for organization and selective builds

## Common Pitfalls

1. **SELECT * in final models** - Always select explicit columns
2. **No tests on staging models** - Every source should have freshness and schema tests
3. **Circular dependencies** - ref() must form DAG (no cycles)
4. **Missing unique_key on incremental** - Required for merge strategies
5. **Hard-coded values** - Use variables or macros instead
6. **No environment separation** - Always have dev/prod targets

## Resources

- [dbt Documentation](https://docs.getdbt.com/)
- [dbt Discourse Community](https://discourse.getdbt.com/)
- [dbt Slack Community](https://www.getdbt.com/community/join-the-community/)
- [dbt Style Guide](https://github.com/dbt-labs/corp/blob/main/dbt_style_guide.md)
