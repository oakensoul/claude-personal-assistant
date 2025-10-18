# dbt Architecture Patterns

dbt (data build tool) is the industry-standard tool for transforming data in modern data warehouses. This guide covers architectural patterns for organizing dbt projects effectively.

## Overview

dbt enables analytics engineers to transform data using SQL select statements, turning data warehouses into development environments with version control, testing, and documentation.

**Philosophy**: Write transformations as SELECT statements, dbt handles the DDL/DML (CREATE TABLE, INSERT, etc.)

## Project Structure

### Standard dbt Project Layout

```text
dbt_project/
├── dbt_project.yml          # Project configuration
├── packages.yml             # dbt package dependencies
├── profiles.yml             # Connection profiles (NOT in git)
├── models/
│   ├── staging/             # Layer 1: Raw source transformations
│   ├── intermediate/        # Layer 2: Business logic
│   ├── marts/               # Layer 3: Final analytics models
│   └── schema.yml           # Model documentation and tests
├── macros/                  # Reusable SQL functions
├── tests/                   # Custom data tests
├── seeds/                   # CSV files to load
├── snapshots/               # SCD Type 2 tracking
├── analyses/                # Ad-hoc SQL queries
└── target/                  # Compiled SQL (in .gitignore)
```

## Layering Strategy

### The Three Layers

dbt projects should follow a three-layer architecture for clarity and maintainability:

```text
Sources (Raw)
     ↓
Staging Models (stg_*)
     ↓
Intermediate Models (int_*)
     ↓
Mart Models (fct_*, dim_*)
     ↓
BI Tools (Looker, Tableau, etc.)
```

### Layer 1: Staging (`stg_`)

**Purpose**: Light transformations from raw sources

**Grain**: Same as source (1:1 mapping)

**Naming**: `stg_{source}__{table}.sql`

**Materialization**: View or ephemeral (never table)

**Logic Allowed**:

- Renaming columns to standard names
- Type casting
- Basic filtering (remove deleted records)
- Light parsing (split column into parts)

**Logic NOT Allowed**:

- Joins with other tables
- Aggregations
- Complex business logic
- Deduplication

**Example**:

```sql
-- models/staging/salesforce/stg_salesforce__accounts.sql

WITH source AS (
    SELECT * FROM {{ source('salesforce', 'accounts') }}
),

renamed AS (
    SELECT
        -- Keys
        id AS account_id,
        owner_id AS owner_id,

        -- Dimensions
        name AS account_name,
        type AS account_type,
        industry,
        billing_country,
        billing_state,
        billing_city,

        -- Metadata
        created_date,
        last_modified_date,
        is_deleted

    FROM source
    WHERE NOT is_deleted  -- Light filtering only
)

SELECT * FROM renamed
```

**Key Principles**:

- One staging model per source table
- No joins, no aggregations
- Document lineage with `{{ source() }}` function
- Keep it simple (mirror source structure)

### Layer 2: Intermediate (`int_`)

**Purpose**: Business logic, joins, aggregations

**Grain**: Can differ from source

**Naming**: `int_{entity}__{verb}.sql`

**Materialization**: Ephemeral or view (sometimes table)

**Logic Allowed**:

- Joins across sources
- Aggregations and rollups
- Deduplication
- Complex transformations
- Pivots and unpivots
- Window functions

**Logic NOT Allowed**:

- Direct references to sources (must use staging models)
- Final business definitions (save for marts)

**Example**:

```sql
-- models/intermediate/finance/int_revenue__daily.sql

WITH orders AS (
    SELECT * FROM {{ ref('stg_salesforce__opportunities') }}
    WHERE stage_name = 'Closed Won'
),

customers AS (
    SELECT * FROM {{ ref('stg_salesforce__accounts') }}
),

daily_revenue AS (
    SELECT
        o.close_date,
        c.customer_id,
        c.customer_name,
        c.segment,
        SUM(o.amount) AS revenue,
        COUNT(DISTINCT o.opportunity_id) AS order_count

    FROM orders o
    JOIN customers c ON o.account_id = c.account_id

    GROUP BY 1, 2, 3, 4
)

SELECT * FROM daily_revenue
```

**Key Principles**:

- Business logic lives here
- Bridge between staging and marts
- Can be ephemeral (not materialized) if only used by one mart
- Use descriptive names: `int_orders__enriched`, `int_revenue__by_customer`

### Layer 3: Marts (`fct_`, `dim_`)

**Purpose**: Analytics-ready models for BI tools

**Grain**: Business-defined (documented in YAML)

**Naming**: `fct_{entity}.sql` or `dim_{entity}.sql`

**Materialization**: Table or incremental (never view)

**Logic Allowed**:

- Final business definitions
- Renaming for end-user clarity
- Adding calculated fields
- Denormalization
- SCD Type 2 (via snapshots)

**Logic NOT Allowed**:

- Complex transformations (move to intermediate)
- Direct references to sources (must use staging or intermediate)

**Example - Fact Table**:

```sql
-- models/marts/finance/fct_revenue.sql

{{
    config(
        materialized='incremental',
        unique_key='revenue_key',
        on_schema_change='fail'
    )
}}

WITH revenue_data AS (
    SELECT * FROM {{ ref('int_revenue__daily') }}
    {% if is_incremental() %}
    WHERE close_date >= (SELECT MAX(close_date) FROM {{ this }})
    {% endif %}
),

final AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['customer_id', 'close_date']) }} AS revenue_key,

        -- Foreign keys
        {{ dbt_utils.generate_surrogate_key(['customer_id']) }} AS customer_key,
        TO_NUMBER(TO_CHAR(close_date, 'YYYYMMDD')) AS date_key,

        -- Measures
        revenue,
        order_count,

        -- Metadata
        CURRENT_TIMESTAMP() AS loaded_at

    FROM revenue_data
)

SELECT * FROM final
```

**Example - Dimension Table**:

```sql
-- models/marts/finance/dim_customers.sql

{{ config(materialized='table') }}

WITH customers AS (
    SELECT * FROM {{ ref('stg_salesforce__accounts') }}
),

final AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['customer_id']) }} AS customer_key,

        -- Natural key
        customer_id,

        -- Attributes
        customer_name,
        segment,
        industry,
        country,
        state,
        city,

        -- Metadata
        created_date,
        CURRENT_TIMESTAMP() AS loaded_at

    FROM customers
)

SELECT * FROM final
```

**Key Principles**:

- Optimized for BI tool queries
- Denormalized (star schema)
- Well documented (grain, measures, dimensions)
- Tested (not null, unique, relationships)

## Naming Conventions

### Model Names

**Staging**:

- Format: `stg_{source}__{table}.sql`
- Examples: `stg_salesforce__accounts.sql`, `stg_stripe__charges.sql`

**Intermediate**:

- Format: `int_{entity}__{verb}.sql`
- Examples: `int_orders__enriched.sql`, `int_revenue__by_customer.sql`

**Marts - Facts**:

- Format: `fct_{entity}.sql`
- Examples: `fct_orders.sql`, `fct_revenue.sql`, `fct_page_views.sql`

**Marts - Dimensions**:

- Format: `dim_{entity}.sql`
- Examples: `dim_customers.sql`, `dim_products.sql`, `dim_date.sql`

### Column Names

**Use consistent naming**:

- `customer_id` not `customerId` or `cust_id`
- `order_date` not `orderDate` or `dt_order`
- `is_active` not `active` or `isActive`

**Prefix booleans**:

- `is_deleted`, `has_shipped`, `was_refunded`

**Suffix dates**:

- `created_at`, `updated_at`, `deleted_at` (timestamps)
- `created_date`, `order_date`, `ship_date` (dates only)

**Suffix aggregations**:

- `total_revenue`, `avg_order_value`, `min_price`, `max_quantity`

## Materialization Strategies

### View

**Definition**: Runs SELECT query every time it's queried

**When to use**:

- Staging models (fast to run, mirror source)
- Intermediate models used by one downstream model
- Models that run quickly (< 1 second)

**Pros**:

- Always fresh (no stale data)
- No storage cost

**Cons**:

- Slow if complex or large
- Compounds query time for downstream models

**Example**:

```sql
{{ config(materialized='view') }}

SELECT * FROM {{ source('salesforce', 'accounts') }}
```

### Table

**Definition**: Drops and recreates table on every run

**When to use**:

- Mart models (facts and dimensions)
- Models that are queried frequently
- Models with complex transformations

**Pros**:

- Fast queries (table already computed)
- Stable performance

**Cons**:

- Full refresh every run (slow for large tables)
- Potential for stale data between runs
- Storage cost

**Example**:

```sql
{{ config(materialized='table') }}

SELECT * FROM {{ ref('int_revenue__daily') }}
```

### Incremental

**Definition**: Only process new/changed rows

**When to use**:

- Large fact tables (> 1M rows)
- Long-running transformations (> 5 minutes full refresh)
- Append-only data (event streams)

**Pros**:

- Fast runs (only new data)
- Efficient for large tables

**Cons**:

- More complex logic
- Potential for bugs (incorrect incremental logic)
- Requires unique_key for merge

**Strategies**:

- **append**: Only add new rows (event logs)
- **merge**: Upsert based on unique_key (SCD Type 2)
- **delete+insert**: Replace partitions (daily aggregations)

**Example**:

```sql
{{
    config(
        materialized='incremental',
        unique_key='order_id',
        on_schema_change='fail',
        incremental_strategy='merge'
    )
}}

SELECT
    order_id,
    customer_id,
    order_date,
    order_amount
FROM {{ ref('stg_salesforce__orders') }}

{% if is_incremental() %}
    -- Only process new/updated orders
    WHERE order_date >= (SELECT MAX(order_date) FROM {{ this }})
{% endif %}
```

### Ephemeral

**Definition**: Not materialized, compiled as CTE in downstream models

**When to use**:

- Intermediate models used by single downstream model
- Simple transformations
- Avoid creating unnecessary tables

**Pros**:

- No storage
- No separate dbt run (compiled inline)

**Cons**:

- Can't query directly
- Duplicated if used by multiple downstream models

**Example**:

```sql
{{ config(materialized='ephemeral') }}

SELECT * FROM {{ ref('stg_salesforce__accounts') }}
WHERE NOT is_deleted
```

## Incremental Models

### Basic Pattern

```sql
{{
    config(
        materialized='incremental',
        unique_key='order_id'
    )
}}

SELECT
    order_id,
    order_date,
    order_amount
FROM {{ ref('stg_orders') }}

{% if is_incremental() %}
    WHERE order_date >= (SELECT MAX(order_date) FROM {{ this }})
{% endif %}
```

### Strategies

#### Append (Default)

Only add new rows:

```sql
{{ config(
    materialized='incremental',
    incremental_strategy='append'
) }}
```

**Use for**: Event logs, audit trails (immutable data)

#### Merge (Upsert)

Insert new, update existing:

```sql
{{ config(
    materialized='incremental',
    unique_key='order_id',
    incremental_strategy='merge'
) }}
```

**Use for**: SCD Type 2, updating fact tables

#### Delete+Insert

Delete matching partition, insert new data:

```sql
{{ config(
    materialized='incremental',
    unique_key='order_date',
    incremental_strategy='delete+insert'
) }}
```

**Use for**: Daily aggregations, replacing date partitions

### Incremental Best Practices

**Do**:

- Use `unique_key` for merge and delete+insert
- Test incremental logic (run full refresh, compare to incremental)
- Add `on_schema_change='fail'` to detect schema changes
- Document incremental logic in model YAML

**Don't**:

- Use incremental for small tables (< 1M rows)
- Forget to test incremental logic
- Use complex WHERE conditions that might miss data

## Snapshots (SCD Type 2)

### Purpose

Track changes to dimension tables over time using SCD Type 2.

### Example

```sql
-- snapshots/dim_customers_snapshot.sql

{% snapshot dim_customers_snapshot %}

{{
    config(
        target_schema='snapshots',
        target_database='analytics',
        unique_key='customer_id',

        strategy='timestamp',
        updated_at='updated_at',

        invalidate_hard_deletes=True
    )
}}

SELECT * FROM {{ ref('stg_salesforce__accounts') }}

{% endsnapshot %}
```

### Strategy: Timestamp

Uses `updated_at` column to detect changes:

```sql
strategy='timestamp',
updated_at='updated_at'
```

**Pros**: Efficient, only checks updated_at

**Cons**: Requires reliable updated_at column

### Strategy: Check

Compares all columns (or specific columns) to detect changes:

```sql
strategy='check',
check_cols=['customer_name', 'segment', 'tier']
```

**Pros**: Reliable, doesn't need updated_at

**Cons**: Slower (compares all rows)

### Snapshot Result

```sql
SELECT
    customer_id,
    customer_name,
    segment,

    -- SCD Type 2 fields (added by dbt)
    dbt_valid_from,     -- When this version became valid
    dbt_valid_to,       -- When this version became invalid (NULL if current)
    dbt_updated_at,     -- When dbt last checked this record
    dbt_scd_id          -- Unique ID for this version

FROM snapshots.dim_customers_snapshot
```

## Testing

### Schema Tests

Defined in `schema.yml`:

```yaml
# models/schema.yml

version: 2

models:
  - name: fct_orders
    description: "Order transactions"
    config:
      tags: ['finance', 'daily']
    columns:
      - name: order_key
        description: "Surrogate key for order"
        tests:
          - unique
          - not_null

      - name: customer_key
        description: "Foreign key to dim_customers"
        tests:
          - not_null
          - relationships:
              to: ref('dim_customers')
              field: customer_key

      - name: order_amount
        description: "Total order amount in USD"
        tests:
          - not_null
          - dbt_utils.accepted_range:
              min_value: 0
              inclusive: true
```

### Custom Data Tests

```sql
-- tests/assert_revenue_is_positive.sql

SELECT
    order_id,
    order_amount
FROM {{ ref('fct_orders') }}
WHERE order_amount < 0
```

**Test passes if**: Query returns zero rows

## Macros

### Reusable SQL Functions

```sql
-- macros/cents_to_dollars.sql

{% macro cents_to_dollars(column_name, precision=2) %}
    ROUND({{ column_name }} / 100, {{ precision }})
{% endmacro %}
```

**Usage**:

```sql
SELECT
    order_id,
    {{ cents_to_dollars('order_amount_cents') }} AS order_amount_dollars
FROM {{ ref('stg_orders') }}
```

### Common Macros

**dbt_utils** (install via packages.yml):

```yaml
# packages.yml
packages:
  - package: dbt-labs/dbt_utils
    version: 1.1.1
```

**Examples**:

```sql
-- Generate surrogate keys
{{ dbt_utils.generate_surrogate_key(['customer_id', 'order_date']) }}

-- Date spine
{{ dbt_utils.date_spine(
    datepart="day",
    start_date="'2020-01-01'",
    end_date="'2030-12-31'"
) }}

-- Pivot
{{ dbt_utils.pivot(
    column='product_category',
    values=dbt_utils.get_column_values(ref('orders'), 'product_category'),
    agg='sum',
    cte_name='orders',
    prefix='category_',
    suffix='_revenue'
) }}
```

## Documentation

### Model Documentation

```yaml
# models/schema.yml

version: 2

models:
  - name: fct_orders
    description: |
      Order transactions fact table.

      **Grain**: One row per order.

      **Measures**:
      - order_amount: Total order amount in USD
      - quantity: Number of items ordered

      **Dimensions**:
      - customer_key → dim_customers
      - product_key → dim_products
      - date_key → dim_date

    columns:
      - name: order_key
        description: "Surrogate key (generated from order_id + order_date)"

      - name: order_id
        description: "Natural key from source system (degenerate dimension)"

      - name: order_amount
        description: "Total order amount in USD (additive measure)"
```

### Generate Docs Site

```bash
# Generate documentation
dbt docs generate

# Serve docs locally
dbt docs serve
```

## Best Practices

### Do

- **Follow layering** (staging → intermediate → marts)
- **Use consistent naming** (stg_*, int_*, fct_*, dim_*)
- **Document grain** explicitly in model YAML
- **Test critical models** (unique, not_null, relationships)
- **Use refs** (`{{ ref('model') }}`) not direct table names
- **Use sources** (`{{ source('schema', 'table') }}`) for raw data
- **Version control** everything except profiles.yml

### Don't

- **Don't skip staging layer** (tempting to join sources directly)
- **Don't put business logic in staging** (keep it simple)
- **Don't reference sources in marts** (use staging/intermediate)
- **Don't use SELECT *** in marts (be explicit)
- **Don't forget to test** incremental logic
- **Don't commit** profiles.yml or target/ directory

## Common Mistakes

### Mistake 1: Complex Staging Models

**Problem**: Joins and aggregations in staging

**Fix**: Keep staging simple (1:1 with sources), move logic to intermediate

### Mistake 2: No Intermediate Layer

**Problem**: Complex joins in mart models

**Fix**: Extract business logic to intermediate models

### Mistake 3: Circular Dependencies

**Problem**: Model A refs Model B, Model B refs Model A

**Fix**: Restructure models to flow one direction (staging → intermediate → marts)

### Mistake 4: Incorrect Incremental Logic

**Problem**: `WHERE created_at >= MAX(created_at)` misses updates

**Fix**: Use `updated_at` or check cols strategy

## Further Reading

- **dbt Documentation**: <https://docs.getdbt.com/>
- **dbt Best Practices**: <https://docs.getdbt.com/guides/best-practices>
- **dbt Discourse**: <https://discourse.getdbt.com/>
- **dbt Slack Community**: <https://www.getdbt.com/community/>

## Version History

**v1.0** - 2025-10-15

- Initial dbt architecture patterns documentation
- Layering strategy and naming conventions
- Materialization strategies and incremental patterns
- Best practices and common mistakes
