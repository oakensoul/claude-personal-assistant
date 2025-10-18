---
title: "Expensive Query Detection"
description: "Patterns and SQL templates for identifying, monitoring, and optimizing costly Snowflake queries"
category: "patterns"
tags: ["query-optimization", "monitoring", "performance", "cost-analysis"]
version: "1.0.0"
last_updated: "2025-10-07"
---

# Expensive Query Detection

Identifying and optimizing expensive queries is one of the highest-ROI cost optimization activities. This guide provides patterns and SQL templates for systematic query cost management.

## Detection Strategies

### 1. Execution Time-Based Detection

**Most Expensive Queries (Last 7 Days)**:

```sql
WITH query_costs AS (
    SELECT
        query_id,
        query_text,
        user_name,
        warehouse_name,
        warehouse_size,
        database_name,
        schema_name,
        start_time,
        end_time,
        total_elapsed_time / 1000 AS total_seconds,
        execution_time / 1000 AS execution_seconds,
        queued_provisioning_time / 1000 AS queue_seconds,
        -- Approximate credit cost
        CASE warehouse_size
            WHEN 'X-Small' THEN execution_seconds / 3600 * 1
            WHEN 'Small' THEN execution_seconds / 3600 * 2
            WHEN 'Medium' THEN execution_seconds / 3600 * 4
            WHEN 'Large' THEN execution_seconds / 3600 * 8
            WHEN 'X-Large' THEN execution_seconds / 3600 * 16
            WHEN '2X-Large' THEN execution_seconds / 3600 * 32
            WHEN '3X-Large' THEN execution_seconds / 3600 * 64
            WHEN '4X-Large' THEN execution_seconds / 3600 * 128
            ELSE execution_seconds / 3600 * 1
        END AS estimated_credits,
        bytes_scanned / POWER(1024, 3) AS gb_scanned,
        rows_produced,
        compilation_time / 1000 AS compile_seconds
    FROM snowflake.account_usage.query_history
    WHERE start_time >= DATEADD('day', -7, CURRENT_TIMESTAMP())
        AND execution_time > 10000  -- > 10 seconds
        AND query_type NOT IN ('SHOW', 'DESCRIBE', 'USE')  -- Exclude metadata queries
)
SELECT
    query_id,
    LEFT(query_text, 200) AS query_preview,
    user_name,
    warehouse_name,
    warehouse_size,
    start_time,
    total_seconds,
    execution_seconds,
    queue_seconds,
    estimated_credits,
    gb_scanned,
    rows_produced,
    compile_seconds,
    estimated_credits * 2.5 AS estimated_cost_usd,  -- Adjust rate
    RANK() OVER (ORDER BY estimated_credits DESC) AS cost_rank
FROM query_costs
ORDER BY estimated_credits DESC
LIMIT 100;
```

### 2. Frequency-Based Detection

**High-Frequency Expensive Queries**:

```sql
WITH query_patterns AS (
    SELECT
        REGEXP_REPLACE(
            REGEXP_REPLACE(query_text, '\\d+', '<NUM>'),  -- Replace numbers
            '''[^'']*''', '<STRING>'  -- Replace string literals
        ) AS query_pattern,
        COUNT(*) AS execution_count,
        AVG(execution_time) / 1000 AS avg_execution_seconds,
        SUM(execution_time) / 1000 AS total_execution_seconds,
        AVG(bytes_scanned) / POWER(1024, 3) AS avg_gb_scanned,
        warehouse_name,
        warehouse_size
    FROM snowflake.account_usage.query_history
    WHERE start_time >= DATEADD('day', -7, CURRENT_TIMESTAMP())
        AND execution_time > 5000  -- > 5 seconds
    GROUP BY query_pattern, warehouse_name, warehouse_size
    HAVING execution_count > 10  -- Frequent queries
)
SELECT
    LEFT(query_pattern, 200) AS query_pattern_preview,
    execution_count,
    avg_execution_seconds,
    total_execution_seconds,
    avg_gb_scanned,
    warehouse_name,
    warehouse_size,
    -- Total cost impact
    CASE warehouse_size
        WHEN 'X-Small' THEN total_execution_seconds / 3600 * 1
        WHEN 'Small' THEN total_execution_seconds / 3600 * 2
        WHEN 'Medium' THEN total_execution_seconds / 3600 * 4
        WHEN 'Large' THEN total_execution_seconds / 3600 * 8
        ELSE total_execution_seconds / 3600 * 16
    END AS total_credits,
    RANK() OVER (ORDER BY total_execution_seconds DESC) AS impact_rank
FROM query_patterns
ORDER BY total_execution_seconds DESC
LIMIT 50;
```

### 3. Data Scan Efficiency

**Queries with Poor Scan Efficiency**:

```sql
SELECT
    query_id,
    LEFT(query_text, 200) AS query_preview,
    user_name,
    warehouse_name,
    start_time,
    execution_time / 1000 AS execution_seconds,
    bytes_scanned / POWER(1024, 3) AS gb_scanned,
    rows_produced,
    -- Scan efficiency (rows produced per GB scanned)
    CASE
        WHEN bytes_scanned > 0 THEN rows_produced / (bytes_scanned / POWER(1024, 3))
        ELSE 0
    END AS rows_per_gb,
    -- Flag inefficient scans
    CASE
        WHEN bytes_scanned > POWER(1024, 3) * 10 AND rows_produced < 1000 THEN 'INEFFICIENT - Large scan, few rows'
        WHEN bytes_scanned > POWER(1024, 3) * 100 THEN 'VERY LARGE SCAN'
        WHEN rows_produced = 0 AND bytes_scanned > POWER(1024, 2) * 100 THEN 'NO RESULTS - Wasted scan'
        ELSE 'Review'
    END AS efficiency_flag
FROM snowflake.account_usage.query_history
WHERE start_time >= DATEADD('day', -7, CURRENT_TIMESTAMP())
    AND bytes_scanned > POWER(1024, 3) * 5  -- > 5 GB scanned
    AND execution_time > 10000  -- > 10 seconds
ORDER BY bytes_scanned DESC
LIMIT 100;
```

## Optimization Workflow

### Step 1: Identify Target Queries

**Priority Matrix**:

| Frequency | Execution Time | Priority | Action |
|-----------|----------------|----------|--------|
| High (100+/day) | Long (> 60s) | **Critical** | Optimize immediately |
| High (100+/day) | Medium (10-60s) | **High** | Optimize this sprint |
| Low (< 10/day) | Long (> 60s) | **Medium** | Optimize if user-facing |
| Low (< 10/day) | Short (< 10s) | **Low** | Monitor, defer |

**Selection Query**:

```sql
WITH query_metrics AS (
    SELECT
        REGEXP_REPLACE(
            REGEXP_REPLACE(query_text, '\\d+', '<NUM>'),
            '''[^'']*''', '<STRING>'
        ) AS query_pattern,
        COUNT(*) AS daily_count,
        AVG(execution_time) / 1000 AS avg_seconds,
        SUM(execution_time) / 1000 AS total_seconds,
        warehouse_name
    FROM snowflake.account_usage.query_history
    WHERE start_time >= DATEADD('day', -1, CURRENT_TIMESTAMP())
    GROUP BY query_pattern, warehouse_name
)
SELECT
    LEFT(query_pattern, 200) AS query_pattern,
    daily_count,
    avg_seconds,
    total_seconds,
    warehouse_name,
    CASE
        WHEN daily_count > 100 AND avg_seconds > 60 THEN 'CRITICAL'
        WHEN daily_count > 100 AND avg_seconds > 10 THEN 'HIGH'
        WHEN daily_count < 10 AND avg_seconds > 60 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS priority
FROM query_metrics
WHERE avg_seconds > 5  -- Focus on queries > 5 seconds
ORDER BY
    CASE
        WHEN daily_count > 100 AND avg_seconds > 60 THEN 1
        WHEN daily_count > 100 AND avg_seconds > 10 THEN 2
        WHEN daily_count < 10 AND avg_seconds > 60 THEN 3
        ELSE 4
    END,
    total_seconds DESC
LIMIT 50;
```

### Step 2: Analyze Query Profile

**For Each Target Query**:

1. **Get Query Profile** (Snowflake UI):
   - Navigate to History → Click query ID
   - Review "Profile" tab for execution breakdown
   - Identify bottleneck operator (JOIN, AGG, SCAN)

2. **Check Execution Plan**:

   ```sql
   EXPLAIN USING TEXT
   <your expensive query>;
   ```

3. **Analyze Common Issues**:
   - **Large table scans**: Missing clustering keys or filters
   - **Cartesian joins**: Missing join conditions
   - **Excessive sorting**: Too many ORDER BY columns
   - **Spilling to disk**: Insufficient warehouse size for in-memory operations

### Step 3: Apply Optimization Patterns

**Common Optimizations**:

#### Pattern 1: Add Missing Filters

**Before**:

```sql
SELECT *
FROM large_fact_table
WHERE metric > 100;  -- Non-clustered column
```

**After**:

```sql
SELECT *
FROM large_fact_table
WHERE date_column >= '2024-01-01'  -- Clustered column
    AND metric > 100;
```

#### Pattern 2: Specify Columns (Avoid SELECT *)

**Before**:

```sql
SELECT *
FROM fact_transactions ft
JOIN dim_user du ON ft.user_id = du.user_id;
```

**After**:

```sql
SELECT
    ft.transaction_id,
    ft.amount,
    ft.transaction_date,
    du.user_name,
    du.user_email
FROM fact_transactions ft
JOIN dim_user du ON ft.user_id = du.user_id;
```

**Savings**: 50-90% fewer bytes scanned if tables have many columns.

#### Pattern 3: Filter Early in CTEs

**Before**:

```sql
WITH all_data AS (
    SELECT * FROM large_table
),
filtered AS (
    SELECT * FROM all_data WHERE date_column >= '2024-01-01'
)
SELECT * FROM filtered;
```

**After**:

```sql
WITH filtered AS (
    SELECT * FROM large_table WHERE date_column >= '2024-01-01'
)
SELECT * FROM filtered;
```

#### Pattern 4: Optimize Window Functions

**Before**:

```sql
SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY created_at DESC) AS rn
FROM events
WHERE rn = 1;  -- Incorrect: WHERE after window function
```

**After**:

```sql
SELECT *
FROM (
    SELECT
        event_id,
        user_id,
        created_at,
        ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY created_at DESC) AS rn
    FROM events
)
WHERE rn = 1;  -- Correct: Subquery pattern
```

**Or use QUALIFY (Snowflake-specific)**:

```sql
SELECT
    event_id,
    user_id,
    created_at
FROM events
QUALIFY ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY created_at DESC) = 1;
```

#### Pattern 5: Leverage Clustering Keys

**Identify Candidates**:

```sql
-- Check clustering depth (higher = worse clustering)
SELECT
    table_catalog,
    table_schema,
    table_name,
    clustering_key,
    average_depth,
    average_overlaps
FROM snowflake.account_usage.automatic_clustering_history
WHERE start_time >= DATEADD('day', -7, CURRENT_TIMESTAMP())
    AND average_depth > 10  -- Poor clustering
ORDER BY average_depth DESC;
```

**Add Clustering Key**:

```sql
-- For fact tables with date filtering
ALTER TABLE fct_wallet_transactions
CLUSTER BY (transaction_date);

-- For multi-column filtering
ALTER TABLE fct_user_sessions
CLUSTER BY (session_date, user_id);
```

**Cost-Benefit Analysis**:

- **Benefit**: Faster queries (pruning partitions)
- **Cost**: Automatic clustering maintenance credits
- **ROI**: Only cluster if query savings > maintenance cost

### Step 4: Test & Validate

**A/B Testing**:

```sql
-- Original query
SET start_time = CURRENT_TIMESTAMP();
<original query>;
SET original_time = DATEDIFF('millisecond', $start_time, CURRENT_TIMESTAMP());

-- Optimized query
SET start_time = CURRENT_TIMESTAMP();
<optimized query>;
SET optimized_time = DATEDIFF('millisecond', $start_time, CURRENT_TIMESTAMP());

-- Compare
SELECT
    $original_time AS original_ms,
    $optimized_time AS optimized_ms,
    ($original_time - $optimized_time) / $original_time * 100 AS improvement_pct;
```

**Validate Results Match**:

```sql
-- Ensure row count identical
SELECT COUNT(*) FROM (<original query>);
SELECT COUNT(*) FROM (<optimized query>);

-- Check sample data matches
SELECT * FROM (<original query>) LIMIT 10;
SELECT * FROM (<optimized query>) LIMIT 10;
```

## Monitoring & Alerting

### Daily Cost Anomaly Detection

```sql
WITH daily_costs AS (
    SELECT
        DATE_TRUNC('day', start_time) AS query_date,
        user_name,
        SUM(execution_time) / 1000 AS total_seconds,
        COUNT(*) AS query_count,
        AVG(execution_time) / 1000 AS avg_seconds
    FROM snowflake.account_usage.query_history
    WHERE start_time >= DATEADD('day', -30, CURRENT_TIMESTAMP())
    GROUP BY query_date, user_name
),
user_stats AS (
    SELECT
        user_name,
        AVG(total_seconds) AS avg_daily_seconds,
        STDDEV(total_seconds) AS stddev_seconds
    FROM daily_costs
    GROUP BY user_name
)
SELECT
    dc.query_date,
    dc.user_name,
    dc.total_seconds,
    dc.query_count,
    us.avg_daily_seconds,
    (dc.total_seconds - us.avg_daily_seconds) / NULLIF(us.stddev_seconds, 0) AS z_score,
    CASE
        WHEN ABS((dc.total_seconds - us.avg_daily_seconds) / NULLIF(us.stddev_seconds, 0)) > 3
        THEN 'ANOMALY - Investigate'
        WHEN ABS((dc.total_seconds - us.avg_daily_seconds) / NULLIF(us.stddev_seconds, 0)) > 2
        THEN 'Elevated usage'
        ELSE 'Normal'
    END AS status
FROM daily_costs dc
JOIN user_stats us ON dc.user_name = us.user_name
WHERE dc.query_date >= DATEADD('day', -7, CURRENT_TIMESTAMP())
    AND ABS((dc.total_seconds - us.avg_daily_seconds) / NULLIF(us.stddev_seconds, 0)) > 2
ORDER BY ABS(z_score) DESC;
```

### Dashboard Query Performance

**Metabase Query Monitoring**:

```sql
-- Identify slow dashboard queries (likely from Metabase)
SELECT
    query_id,
    LEFT(query_text, 200) AS query_preview,
    user_name,
    warehouse_name,
    start_time,
    execution_time / 1000 AS execution_seconds,
    bytes_scanned / POWER(1024, 3) AS gb_scanned,
    rows_produced,
    -- Identify potential dashboard queries
    CASE
        WHEN query_text ILIKE '%/* Metabase */%' THEN 'Metabase'
        WHEN user_name ILIKE '%service%' THEN 'Service Account'
        ELSE 'User'
    END AS query_source
FROM snowflake.account_usage.query_history
WHERE start_time >= DATEADD('day', -7, CURRENT_TIMESTAMP())
    AND execution_time > 5000  -- > 5 seconds
    AND (query_text ILIKE '%/* Metabase */%' OR user_name ILIKE '%metabase%')
ORDER BY execution_time DESC
LIMIT 100;
```

## Best Practices

### Prevention Strategies

1. **Code Review Checklist**:
   - [ ] No SELECT * in production queries
   - [ ] Filters on clustered columns where possible
   - [ ] Explicit column selection in joins
   - [ ] Window functions use QUALIFY where applicable
   - [ ] CTEs filter data early in pipeline

2. **dbt Model Standards**:
   - [ ] Incremental models for large fact tables
   - [ ] Clustering keys on high-volume tables
   - [ ] `{{ limit_data_in_dev() }}` macro in development
   - [ ] Appropriate tags (volume, critical) for build optimization

3. **Query Templates**:
   - Provide optimized templates for common patterns
   - Document anti-patterns with examples
   - Automated linting for known issues (SQLFluff)

### Optimization ROI

**Impact Formula**:

```text
Daily Savings (credits) =
    (Original Execution Seconds - Optimized Execution Seconds)
    × Daily Query Count
    × (Warehouse Credits/Hour ÷ 3600)

Annual Savings ($) = Daily Savings × 365 × ($/Credit)
```

**Example**:

- Original: 60 seconds per query
- Optimized: 10 seconds per query (83% improvement)
- Frequency: 100 queries/day
- Warehouse: Medium (4 credits/hour)
- Credit cost: $2.50

```text
Daily Savings = (60 - 10) × 100 × (4 ÷ 3600) = 5.56 credits/day
Annual Savings = 5.56 × 365 × $2.50 = $5,073
```

---

**Key Takeaway**: Expensive query optimization delivers compounding returns. Focus on high-frequency queries first (even moderate savings scale), then tackle long-running queries. Always measure before/after to validate improvements and calculate ROI.
