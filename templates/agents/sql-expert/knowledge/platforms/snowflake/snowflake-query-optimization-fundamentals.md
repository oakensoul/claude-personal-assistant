---
title: "Snowflake Query Optimization Fundamentals"
description: "Core concepts for Snowflake query performance tuning including micro-partitions, clustering, and execution model"
category: "core-concepts"
tags:
  - snowflake-architecture
  - query-optimization
  - performance-tuning
  - micro-partitions
  - clustering
last_updated: "2025-10-07"
---

# Snowflake Query Optimization Fundamentals

Understanding Snowflake's architecture is critical for writing efficient SQL queries in the dbt-splash-prod-v2 project.

## Snowflake Architecture Overview

### Micro-Partitions
Snowflake automatically divides tables into immutable micro-partitions (50-500 MB compressed):

**Key Characteristics:**
- Automatic partitioning based on data ingestion order
- Cannot be manually controlled or modified
- Contain metadata (min/max values, distinct counts, NULL counts)
- Enable efficient partition pruning during query execution

**Optimization Strategy:**
```sql
-- ✅ GOOD: Filter on clustered/ordered columns for partition pruning
select
    user_id,
    transaction_date,
    amount
from {{ ref('fct_wallet_transactions') }}
where transaction_date >= '2025-01-01'  -- Prunes partitions efficiently
    and transaction_date < '2025-02-01'

-- ❌ LESS EFFICIENT: Filter on non-ordered columns
select
    user_id,
    transaction_date,
    amount
from {{ ref('fct_wallet_transactions') }}
where user_state = 'CA'  -- Scans all partitions
```

### Clustering Keys
Improve query performance by organizing micro-partitions based on frequently filtered columns:

**When to Use Clustering:**
- Large tables (multi-TB scale)
- Frequent filtering on specific columns
- Time-series data with date-based queries
- High-cardinality columns used in WHERE/JOIN clauses

**Project Example:**
```sql
-- models/dwh/core/finance/fct_wallet_transactions.sql
{{
    config(
        materialized='incremental',
        unique_key='transaction_key',
        cluster_by=['transaction_date', 'user_id'],  -- Cluster on common filters
        tags=[
            'group:finance',
            'layer:core',
            'pattern:fact_transaction',
            'critical:true',
            'volume:high'
        ]
    )
}}
```

**Clustering Best Practices:**
1. Cluster on 1-4 columns maximum
2. Put lowest cardinality column first (e.g., date before user_id)
3. Avoid clustering on very high cardinality columns (UUIDs)
4. Monitor clustering depth (SYSTEM$CLUSTERING_DEPTH)

## Query Execution Model

### Three-Layer Architecture

**1. Cloud Services Layer:**
- Query compilation and optimization
- Metadata management
- Authentication and access control
- Query plan generation

**2. Compute Layer (Virtual Warehouses):**
- Query execution
- Independently scalable (XS to 6XL)
- Auto-suspend and auto-resume
- Charged per-second (minimum 60 seconds)

**3. Storage Layer:**
- Columnar storage with micro-partitions
- Automatic compression
- Separate from compute (storage costs independent)

### Query Optimization Process

**Step 1: Parsing & Compilation**
```sql
-- Snowflake compiles dbt-generated SQL with Jinja templates resolved
-- {{ ref() }} becomes fully-qualified table references
```

**Step 2: Query Rewrite**
- Predicate pushdown (move filters closer to data)
- Join reordering (optimize join sequence)
- CTE inlining or materialization decisions

**Step 3: Execution Plan Generation**
- Determine partition pruning strategy
- Select join algorithms (hash join, nested loop, merge join)
- Plan parallelization across compute nodes

**Step 4: Execution**
- Parallel query execution across warehouse nodes
- Results caching (24-hour result cache)
- Metadata-only operations when possible

## Performance Optimization Strategies

### 1. Partition Pruning
Maximize partition pruning by filtering on clustered or time-ordered columns:

```sql
-- ✅ OPTIMIZED: Date-based filtering enables partition pruning
with daily_transactions as (

    select
        transaction_date,
        user_id,
        amount,
        transaction_type
    from {{ ref('fct_wallet_transactions') }}
    where transaction_date >= dateadd(day, -30, current_date())  -- Prunes old partitions

)
```

### 2. Column Selection
Snowflake is columnar storage - only selected columns are scanned:

```sql
-- ❌ ANTI-PATTERN: SELECT * reads all columns
select * from {{ ref('fct_contest_entries') }}

-- ✅ OPTIMIZED: Explicit column selection
select
    entry_id,
    contest_id,
    user_id,
    entry_date
from {{ ref('fct_contest_entries') }}
```

### 3. Join Optimization
Order joins from smallest to largest table:

```sql
-- ✅ OPTIMIZED: Small dimension first, then fact table
with user_details as (

    select
        user_id,
        user_email,
        user_state
    from {{ ref('dim_user') }}  -- Small dimension (thousands of rows)

),

entry_facts as (

    select
        entry_id,
        user_id,
        contest_id,
        entry_date
    from {{ ref('fct_contest_entries') }}  -- Large fact (millions of rows)

)

select
    e.entry_id,
    e.contest_id,
    u.user_email,
    u.user_state,
    e.entry_date
from entry_facts as e
inner join user_details as u
    on e.user_id = u.user_id  -- Efficient hash join
```

### 4. Aggregation Optimization
Pre-aggregate in CTEs when reusing aggregated data:

```sql
-- ✅ OPTIMIZED: Aggregate once, reuse in final query
with user_stats as (

    select
        user_id,
        count(distinct contest_id) as contests_entered,
        sum(entry_fee) as total_spend,
        min(entry_date) as first_entry_date
    from {{ ref('fct_contest_entries') }}
    group by user_id

),

final as (

    select
        user_id,
        contests_entered,
        total_spend,
        datediff(day, first_entry_date, current_date()) as days_since_first_entry,
        case
            when contests_entered > 100 then 'Power User'
            when contests_entered > 10 then 'Active User'
            else 'Casual User'
        end as user_segment
    from user_stats

)

select * from final
```

### 5. Incremental Model Efficiency
Use incremental materialization with proper filtering:

```sql
{{
    config(
        materialized='incremental',
        unique_key='entry_id',
        cluster_by=['entry_date']
    )
}}

with source_data as (

    select * from {{ ref('stg_splash_production__contest_entries') }}

    {% if is_incremental() %}
        -- Only process new data since last run
        where entry_date > (select max(entry_date) from {{ this }})
    {% endif %}

)

select * from source_data
```

## Warehouse Sizing Guidelines

### Project-Specific Warehouse Strategy

**High-Frequency Builds (15-20 min cycles):**
- Warehouse: MEDIUM or LARGE
- Models: tag:critical:true
- Auto-suspend: 1 minute

**Medium-Frequency Builds (2 hour cycles):**
- Warehouse: SMALL or MEDIUM
- Models: tag:layer:intermediate, tag:layer:marts
- Auto-suspend: 5 minutes

**Daily Full Builds:**
- Warehouse: LARGE or X-LARGE
- Models: All models, including tag:volume:high
- Auto-suspend: 10 minutes

### Right-Sizing Strategy
1. Start with SMALL warehouse
2. Monitor query queue time
3. Scale up if queries wait for compute resources
4. Scale down if warehouse is underutilized (<50% CPU)

## Query Profile Analysis

### Key Metrics to Monitor

**1. Query Duration:**
- Total execution time
- Compilation time (should be <5% of total)
- Execution time breakdown by operator

**2. Bytes Scanned:**
- Partition pruning effectiveness
- Column selection efficiency
- Compare to table size for scan percentage

**3. Spillage:**
- Disk spillage indicates insufficient memory
- Consider larger warehouse or query optimization
- Common causes: Large joins, window functions on unsorted data

**4. Remote Disk I/O:**
- Data not cached in warehouse SSD
- Indicates cold start or new data access pattern

### Example Query Profile Analysis
```sql
-- Check clustering effectiveness
select system$clustering_information('PROD.FINANCE.FCT_WALLET_TRANSACTIONS', '(TRANSACTION_DATE, USER_ID)');

-- Monitor warehouse load
show warehouses;

-- Analyze query performance
select *
from table(information_schema.query_history())
where query_text ilike '%fct_wallet_transactions%'
order by start_time desc
limit 10;
```

## Cost Optimization Strategies

### 1. Result Caching
Snowflake caches query results for 24 hours:
- Identical queries return cached results (no compute cost)
- Works across warehouses and users
- Invalidated when underlying data changes

### 2. Materialized Views (Use Sparingly)
- Automatically updated when base tables change
- Incur maintenance costs on every update
- Use for complex aggregations queried frequently

### 3. Clustering Cost vs. Benefit
- Clustering has automatic reclustering cost
- Only cluster tables >1TB with clear filter patterns
- Monitor clustering health and costs

### 4. Auto-Suspend & Auto-Resume
- Set aggressive auto-suspend for dev environments (1 min)
- Balance resume time vs. cost for prod (5-10 min)
- No cost when warehouse is suspended

## Project Integration

### dbt Model Optimization
Apply these patterns when writing dbt models:

**Staging Layer:**
- Minimal transformations
- Explicit column selection
- Simple type casting and renaming

**Core Layer (Facts & Dimensions):**
- Incremental materialization for large fact tables
- Clustering keys on frequently filtered columns
- Efficient window functions with QUALIFY

**Marts Layer:**
- Pre-aggregated for BI tool performance
- Table materialization for small result sets
- Consider caching frequently accessed marts

### Tagging for Build Optimization
Use volume tags to control compute resources:
```yaml
tags:
  - volume:low     # Lookup tables, config data (XS warehouse)
  - volume:medium  # Core business data (SMALL/MEDIUM warehouse)
  - volume:high    # Segment events (LARGE/X-LARGE warehouse)
```

## Summary

**Key Takeaways:**
1. Understand micro-partitions and enable partition pruning through filtering
2. Use clustering keys for large tables with clear access patterns
3. Explicit column selection reduces data scanned and improves performance
4. Right-size warehouses based on query patterns and frequency
5. Monitor query profiles to identify optimization opportunities
6. Leverage incremental models and result caching for cost efficiency

**Next Steps:**
- Review patterns/window-function-optimization.md for QUALIFY usage
- Check decisions/performance-anti-patterns.md to avoid common pitfalls
- Apply these fundamentals when writing SQL for dbt models
