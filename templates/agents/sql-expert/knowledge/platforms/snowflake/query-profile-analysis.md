---
title: "Snowflake Query Profile Analysis Guide"
description: "Step-by-step guide to interpreting Snowflake query execution plans, identifying bottlenecks, and optimizing performance"
agent: "snowflake-sql-expert"
category: "core-concepts"
tags:
  - query-profile
  - execution-plan
  - performance-tuning
  - bottleneck-analysis
  - optimization
  - spillage
  - pruning
last_updated: "2025-10-07"
priority: "high"
---

# Snowflake Query Profile Analysis Guide

## Overview

The Snowflake Query Profile is a visual execution plan that shows exactly how Snowflake executed a query. Understanding how to read and interpret query profiles is essential for performance optimization in the dbt-splash-prod-v2 project.

**Access Query Profile**:
1. Execute query in Snowflake UI
2. Click on query ID in "History" tab
3. View "Query Profile" tab

## Query Profile Structure

### Execution Operators (Nodes)

Each node in the query profile represents an operation:

| Operator | Description | Performance Impact |
|----------|-------------|-------------------|
| **TableScan** | Read data from table | High if scanning many partitions |
| **Filter** | Apply WHERE conditions | Low (pushed down to scan) |
| **Join** | Combine tables | High for large tables |
| **Aggregate** | GROUP BY operations | Medium to high |
| **Sort** | ORDER BY operations | Medium (uses memory/disk) |
| **WindowFunction** | OVER clause operations | Medium to high |
| **UnionAll** | Combine result sets | Low to medium |
| **Result** | Final output | Low |

### Key Metrics Per Node

- **Time**: Execution time for this operator
- **Rows**: Number of rows produced
- **Bytes**: Data volume processed
- **% of Total Time**: Relative cost
- **Partitions Scanned**: Micro-partitions read (lower is better)
- **Partitions Total**: Total partitions in table
- **Bytes Spilled**: Data written to disk (avoid if possible)

## Step-by-Step Profile Analysis

### Step 1: Identify Expensive Operators

Look for nodes with:
- **High % of Total Time** (>20% indicates bottleneck)
- **Large "Time" values** compared to total query time
- **Red or orange coloring** (indicates high cost)

**Example**:
```
Join [Hash] - 85% of query time - BOTTLENECK
├─ TableScan [FCT_CONTEST_ENTRIES] - 10% of query time
└─ TableScan [DIM_USER] - 5% of query time
```

**Analysis**: Join is the bottleneck (85% of time). Optimize join conditions or pre-filter tables.

### Step 2: Check Partition Pruning

**What to Look For**:
- **Partitions Scanned** vs **Partitions Total** ratio
- Lower is better (indicates effective pruning)

**Example Good Pruning**:
```
TableScan [FCT_WALLET_TRANSACTIONS]
Partitions Scanned: 45 of 1,200 (3.75%)  ✅ GOOD
Bytes Scanned: 1.2 GB of 320 GB
```

**Example Poor Pruning**:
```
TableScan [FCT_WALLET_TRANSACTIONS]
Partitions Scanned: 1,180 of 1,200 (98.3%)  ❌ BAD
Bytes Scanned: 315 GB of 320 GB
```

**How to Fix Poor Pruning**:
- Add WHERE clause on clustered column (typically `transaction_date_et`)
- Ensure filter uses clustered column

```sql
-- ❌ BAD: No filter, scans all partitions
select *
from {{ ref('fct_wallet_transactions') }}

-- ✅ GOOD: Filter on clustered column
select *
from {{ ref('fct_wallet_transactions') }}
where transaction_date_et >= current_date - interval '30 days'
```

### Step 3: Identify Spillage (Disk I/O)

**What is Spillage?**
When query operations exceed available memory, Snowflake writes intermediate results to disk (local or remote storage). This SIGNIFICANTLY slows queries.

**Types of Spillage**:
- **Local Spillage**: Writes to SSD (moderately slow)
- **Remote Spillage**: Writes to S3 (VERY slow)

**Where to Look**:
```
WindowFunction [ROW_NUMBER OVER ...]
Bytes Spilled to Local Storage: 12.5 GB     ⚠️ WARNING
Bytes Spilled to Remote Storage: 0 B        ✅ OK
```

**How to Fix Spillage**:

1. **Reduce data volume before operation**:
```sql
-- ❌ BAD: Window function on full table
select
    user_id,
    transaction_id,
    row_number() over (partition by user_id order by transaction_timestamp) as rn
from {{ ref('fct_wallet_transactions') }}  -- 50M rows

-- ✅ GOOD: Filter first, then window function
select
    user_id,
    transaction_id,
    row_number() over (partition by user_id order by transaction_timestamp) as rn
from {{ ref('fct_wallet_transactions') }}
where transaction_date_et >= current_date - interval '90 days'  -- 5M rows
```

2. **Use larger warehouse**:
```sql
-- Increase warehouse size for memory-intensive queries
-- In Snowflake UI or SnowSQL:
use warehouse COMPUTE_WH_LARGE;  -- More memory available
```

3. **Break into multiple steps**:
```sql
-- Instead of complex single query with spillage:
-- Step 1: Pre-aggregate to reduce data volume
create or replace temp table user_aggregates as
select
    user_id,
    count(*) as transaction_count,
    sum(amount_cents) as total_amount_cents
from {{ ref('fct_wallet_transactions') }}
where transaction_date_et >= current_date - interval '90 days'
group by user_id;

-- Step 2: Join to smaller temp table
select *
from user_aggregates
join {{ ref('dim_user') }} using (user_id)
```

### Step 4: Analyze Join Performance

**Join Types in Snowflake**:

| Join Type | Description | Performance |
|-----------|-------------|-------------|
| **Hash Join** | Build hash table on smaller table | Fast for large-large joins |
| **Nested Loop** | Check each row against other table | Slow, avoid for large tables |
| **Merge Join** | Join sorted tables | Fast if tables pre-sorted |

**Good Join Pattern**:
```
Join [Hash]
├─ TableScan [DIM_USER] - 1M rows (build table)
└─ TableScan [FCT_CONTEST_ENTRIES] - 50M rows (probe table)
```
Snowflake builds hash table on smaller table (dim_user), then probes with larger table.

**Bad Join Pattern**:
```
Join [Nested Loop]  ❌ VERY SLOW
├─ TableScan [FCT_WALLET_TRANSACTIONS] - 100M rows
└─ TableScan [FCT_CONTEST_ENTRIES] - 50M rows
```

**How to Fix Slow Joins**:

1. **Ensure join keys have same data type**:
```sql
-- ❌ BAD: Type mismatch causes slow join
select *
from {{ ref('fct_contest_entries') }} as e  -- contest_id is NUMBER
join {{ ref('dim_contest') }} as c
    on e.contest_id::string = c.contest_id  -- Implicit conversion

-- ✅ GOOD: Same types
select *
from {{ ref('fct_contest_entries') }} as e
join {{ ref('dim_contest') }} as c
    on e.contest_id = c.contest_id  -- Both NUMBER
```

2. **Pre-filter before joining**:
```sql
-- ✅ GOOD: Filter before join
with recent_entries as (
    select *
    from {{ ref('fct_contest_entries') }}
    where entry_date_et >= current_date - interval '7 days'  -- Reduce from 50M to 500K
)

select *
from recent_entries as e
join {{ ref('dim_contest') }} as c
    on e.contest_id = c.contest_id
```

3. **Use smaller dimension tables**:
```sql
-- Consider creating filtered dimension for specific use case
-- Instead of joining full dim_user (10M rows), create active users only
```

### Step 5: Check Aggregation Performance

**Aggregation Operators**:
- **Aggregate**: Standard GROUP BY
- **AggregatePartial** + **AggregateFinal**: Distributed aggregation (good for large data)

**Good Aggregation**:
```
Aggregate
Input: 1M rows
Output: 100K rows
Time: 2.5s
```

**Expensive Aggregation**:
```
Aggregate
Input: 100M rows
Output: 50M rows (high cardinality)
Time: 45s
Bytes Spilled: 15 GB  ❌ PROBLEM
```

**How to Optimize Aggregations**:

1. **Pre-filter to reduce input**:
```sql
-- ✅ GOOD: Filter before aggregation
select
    user_id,
    count(*) as contest_count,
    sum(entry_fee_cents) as total_spent_cents
from {{ ref('fct_contest_entries') }}
where entry_date_et >= current_date - interval '30 days'  -- Filter first
group by user_id
```

2. **Use incremental aggregation in dbt**:
```sql
-- Maintain running aggregates instead of scanning full history
{{
    config(
        materialized='incremental',
        unique_key='user_id'
    )
}}

-- Aggregate only new data, merge with existing
```

### Step 6: Evaluate Sort Performance

**When Sorting Occurs**:
- ORDER BY clause
- Window functions with ORDER BY
- Merge joins
- DISTINCT (implicit sort)

**Expensive Sort Example**:
```
Sort
Input: 50M rows
Output: 50M rows
Time: 35s
Bytes Spilled to Local: 25 GB  ❌ EXPENSIVE
```

**How to Optimize Sorts**:

1. **Reduce rows before sorting**:
```sql
-- ❌ BAD: Sort all transactions
select *
from {{ ref('fct_wallet_transactions') }}
order by transaction_timestamp desc
limit 100

-- ✅ GOOD: Filter first, then sort
select *
from {{ ref('fct_wallet_transactions') }}
where transaction_date_et >= current_date - interval '7 days'
order by transaction_timestamp desc
limit 100
```

2. **Use QUALIFY for window function filtering** (avoids sorting entire result):
```sql
-- ✅ BETTER: Use QUALIFY
select
    user_id,
    contest_id,
    entry_timestamp
from {{ ref('fct_contest_entries') }}
qualify row_number() over (partition by user_id order by entry_timestamp desc) = 1
```

## Common Bottleneck Patterns

### Pattern 1: Full Table Scan on Large Fact

**Symptom**:
```
TableScan [FCT_WALLET_TRANSACTIONS]
Partitions Scanned: 2,500 of 2,500 (100%)
Time: 2 minutes
```

**Fix**: Add date filter on clustered column:
```sql
where transaction_date_et >= current_date - interval '90 days'
```

### Pattern 2: Segment Event Processing (High Volume)

**Symptom**:
```
TableScan [STG_SEGMENT__WEB_EVENTS]
Partitions Scanned: 5,000 of 5,000
Bytes Scanned: 800 GB
Time: 5 minutes
```

**Fix**: Always filter Segment data by date:
```sql
-- ✅ REQUIRED for Segment queries
where event_date_et >= current_date - interval '7 days'
```

### Pattern 3: Large Join with Spillage

**Symptom**:
```
Join [Hash]
Bytes Spilled to Remote: 50 GB
Time: 10 minutes
```

**Fix**: Pre-aggregate or filter before joining:
```sql
-- Pre-aggregate large table before join
with aggregated_entries as (
    select
        user_id,
        count(*) as entry_count
    from {{ ref('fct_contest_entries') }}
    group by user_id
)

select *
from aggregated_entries
join {{ ref('dim_user') }} using (user_id)
```

### Pattern 4: Expensive Window Function

**Symptom**:
```
WindowFunction [ROW_NUMBER OVER (PARTITION BY user_id ...)]
Input: 100M rows
Bytes Spilled: 30 GB
Time: 8 minutes
```

**Fix**: Filter before window function:
```sql
-- ✅ GOOD: Reduce input rows
with recent_data as (
    select *
    from {{ ref('fct_contest_entries') }}
    where entry_date_et >= current_date - interval '30 days'  -- 100M → 5M
)

select
    user_id,
    contest_id,
    row_number() over (partition by user_id order by entry_timestamp) as rn
from recent_data
```

## Using Query Profile for Incremental Models

### Validate Incremental Logic

**Check that incremental filter is working**:

```sql
-- dbt model with incremental logic
{% if is_incremental() %}
where transaction_timestamp > (select max(transaction_timestamp) from {{ this }})
{% endif %}
```

**In Query Profile**:
```
Filter
Condition: transaction_timestamp > '2025-10-06 15:30:00'
Partitions Scanned: 15 of 2,500 (0.6%)  ✅ GOOD - Incremental working
```

If you see `Partitions Scanned: 2,500 of 2,500`, incremental logic is NOT working.

## Clustering Analysis

### Check Clustering Effectiveness

**Query `system$clustering_information`**:
```sql
select system$clustering_information('fct_wallet_transactions', '(transaction_date_et)');
```

**Output**:
```json
{
  "cluster_by_keys": "(TRANSACTION_DATE_ET)",
  "total_partition_count": 2500,
  "total_constant_partition_count": 200,
  "average_overlaps": 1.2,
  "average_depth": 2.1,
  "partition_depth_histogram": {
    "00000": 0,
    "00001": 1800,
    "00002": 500,
    "00003": 150,
    "00004": 50
  }
}
```

**Key Metrics**:
- **average_depth**: Lower is better (1.0 = perfect, >4.0 = needs reclustering)
- **average_overlaps**: How many partitions contain same key value (lower is better)
- **partition_depth_histogram**: Distribution of clustering depth

**Good Clustering**:
```
average_depth: 1.5 (most partitions in depth 1-2)
Partitions Scanned: 50 of 2,500 when filtering on clustered column
```

**Poor Clustering**:
```
average_depth: 5.2 (high depth indicates fragmentation)
Partitions Scanned: 1,200 of 2,500 (clustering not effective)
```

**When to Recluster**:
- Average depth > 4.0
- Queries scan many more partitions than expected
- Table has had many DML operations

## SnowSQL Commands for Query Profile Analysis

### Get Query ID
```bash
# Execute query and capture query ID
snowsql -c prod -q "SELECT * FROM table WHERE ..." -o output_format=tsv | head -1
```

### Get Query Statistics
```sql
-- In Snowsql or Snowflake UI
select
    query_id,
    query_text,
    total_elapsed_time / 1000 as execution_time_seconds,
    bytes_scanned / (1024*1024*1024) as gb_scanned,
    partitions_scanned,
    partitions_total,
    bytes_spilled_to_local_storage / (1024*1024*1024) as gb_spilled_local,
    bytes_spilled_to_remote_storage / (1024*1024*1024) as gb_spilled_remote
from table(information_schema.query_history())
where query_text ilike '%fct_wallet_transactions%'
order by start_time desc
limit 10;
```

### Compare Before/After Optimization
```sql
-- Track improvements
select
    'before_optimization' as version,
    total_elapsed_time / 1000 as execution_time_seconds,
    bytes_scanned / (1024*1024*1024) as gb_scanned
from table(information_schema.query_history())
where query_id = 'QUERY_ID_BEFORE'

union all

select
    'after_optimization' as version,
    total_elapsed_time / 1000 as execution_time_seconds,
    bytes_scanned / (1024*1024*1024) as gb_scanned
from table(information_schema.query_history())
where query_id = 'QUERY_ID_AFTER';
```

## Quick Optimization Checklist

When analyzing a slow query:

- [ ] **Check partition pruning** - Are most partitions scanned? Add date filter.
- [ ] **Check for spillage** - Any bytes spilled to disk? Reduce data volume or increase warehouse.
- [ ] **Check join types** - Hash join preferred. Nested loop is slow.
- [ ] **Check aggregation cardinality** - High output row count? Pre-filter input.
- [ ] **Check sort operations** - Large sorts? Use QUALIFY or reduce input rows.
- [ ] **Check filter pushdown** - Are filters applied at TableScan? Move filters to WHERE clause.
- [ ] **Check data types** - Join keys same type? Implicit conversions are slow.
- [ ] **Check clustering** - `average_depth` < 4.0? Consider reclustering.

## Real-World Example: Optimizing Contest Entry Query

### Before Optimization

**Query**:
```sql
select
    u.user_id,
    u.email,
    count(*) as total_entries
from {{ ref('dim_user') }} as u
join {{ ref('fct_contest_entries') }} as e
    on u.user_id = e.user_id
group by u.user_id, u.email
```

**Query Profile**:
```
Total Time: 8 minutes 30 seconds

Join [Hash] - 85% of time
├─ TableScan [DIM_USER] - 5% (10M rows, all partitions)
└─ TableScan [FCT_CONTEST_ENTRIES] - 10% (150M rows, all partitions)
    Partitions Scanned: 3,500 of 3,500 (100%)
    Bytes Scanned: 950 GB

Aggregate - 5% of time
Bytes Spilled to Local: 12 GB
```

**Problems**:
1. Full table scan on fact table (no date filter)
2. Joining dimension with all users (including inactive)
3. Spillage during aggregation

### After Optimization

**Optimized Query**:
```sql
with recent_entries as (
    select
        user_id,
        contest_id
    from {{ ref('fct_contest_entries') }}
    where entry_date_et >= current_date - interval '90 days'  -- Filter to recent
),

entry_counts as (
    select
        user_id,
        count(*) as total_entries
    from recent_entries
    group by user_id  -- Aggregate before join
)

select
    u.user_id,
    u.email,
    c.total_entries
from entry_counts as c
join {{ ref('dim_user') }} as u
    on u.user_id = c.user_id
where u.is_active = true  -- Only active users
```

**Query Profile**:
```
Total Time: 18 seconds

Filter + TableScan [FCT_CONTEST_ENTRIES] - 40% of time
    Partitions Scanned: 180 of 3,500 (5.1%)  ✅ GREAT PRUNING
    Bytes Scanned: 52 GB

Aggregate - 30% of time
    Input: 8M rows
    Output: 500K rows
    No spillage  ✅

Join [Hash] - 30% of time
    Build: 500K rows (aggregated)
    Probe: 8M rows (filtered users)
```

**Improvements**:
- **28x faster** (8m 30s → 18s)
- **95% less data scanned** (950 GB → 52 GB)
- **No spillage** (memory-efficient)
- **Effective partition pruning** (5.1% scanned)

## Additional Resources

**Snowflake Documentation**:
- [Query Profile Overview](https://docs.snowflake.com/en/user-guide/ui-query-profile.html)
- [Understanding the Query Profile](https://docs.snowflake.com/en/user-guide/ui-query-profile-details.html)
- [Micro-Partition Pruning](https://docs.snowflake.com/en/user-guide/tables-clustering-micropartitions.html)

**Project Integration**:
- Use for optimizing `tag:critical:true` models (15-20 min build cycles)
- Essential for `tag:volume:high` Segment data processing
- Critical for incremental model validation

---

**Last Updated**: 2025-10-07
**Agent**: snowflake-sql-expert
**Knowledge Category**: Core Concepts