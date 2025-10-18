---
title: "Snowflake Cost Queries Library"
description: "Ready-to-use SQL query templates for cost analysis using ACCOUNT_USAGE schema"
category: "reference"
tags: ["sql", "account-usage", "monitoring", "cost-analysis"]
version: "1.0.0"
last_updated: "2025-10-07"
---

# Snowflake Cost Queries Library

Comprehensive collection of SQL queries for analyzing Snowflake costs using the `SNOWFLAKE.ACCOUNT_USAGE` schema.

## Quick Reference

### Essential Cost Queries

| Query Purpose | Frequency | Primary Use Case |
|---------------|-----------|------------------|
| Daily Credit Consumption | Daily | Trend monitoring, anomaly detection |
| Storage Breakdown | Weekly | Capacity planning, retention optimization |
| Top Expensive Queries | Daily | Query optimization targets |
| Warehouse Utilization | Weekly | Sizing decisions, idle time reduction |
| Monthly Cost Summary | Monthly | Budget tracking, executive reporting |

---

## Compute Cost Queries

### 1. Daily Credit Consumption by Warehouse

**Purpose**: Track daily credit usage trends and identify cost spikes.

```sql
SELECT
    DATE_TRUNC('day', start_time) AS usage_date,
    warehouse_name,
    SUM(credits_used) AS total_credits,
    COUNT(DISTINCT DATE_TRUNC('hour', start_time)) AS active_hours,
    SUM(credits_used) * 2.5 AS estimated_cost_usd,  -- Adjust rate
    RANK() OVER (PARTITION BY DATE_TRUNC('day', start_time) ORDER BY SUM(credits_used) DESC) AS daily_rank
FROM snowflake.account_usage.warehouse_metering_history
WHERE start_time >= DATEADD('day', -30, CURRENT_TIMESTAMP())
GROUP BY usage_date, warehouse_name
ORDER BY usage_date DESC, total_credits DESC;
```

### 2. Warehouse Credit Summary (Current Month)

**Purpose**: Current month spend tracking against budget.

```sql
SELECT
    warehouse_name,
    SUM(credits_used) AS mtd_credits,
    SUM(credits_used) * 2.5 AS mtd_cost_usd,
    COUNT(DISTINCT DATE_TRUNC('day', start_time)) AS days_active,
    SUM(credits_used) / NULLIF(COUNT(DISTINCT DATE_TRUNC('day', start_time)), 0) AS avg_daily_credits,
    -- Forecast to month end
    (SUM(credits_used) / NULLIF(COUNT(DISTINCT DATE_TRUNC('day', start_time)), 0))
        * DAY(LAST_DAY(CURRENT_DATE())) AS forecasted_monthly_credits
FROM snowflake.account_usage.warehouse_metering_history
WHERE start_time >= DATE_TRUNC('month', CURRENT_TIMESTAMP())
GROUP BY warehouse_name
ORDER BY mtd_credits DESC;
```

### 3. Hourly Credit Consumption Pattern

**Purpose**: Identify peak usage hours for workload scheduling.

```sql
SELECT
    HOUR(start_time) AS hour_of_day,
    DAYNAME(start_time) AS day_of_week,
    warehouse_name,
    AVG(credits_used) AS avg_credits_per_hour,
    SUM(credits_used) AS total_credits
FROM snowflake.account_usage.warehouse_metering_history
WHERE start_time >= DATEADD('day', -30, CURRENT_TIMESTAMP())
GROUP BY hour_of_day, day_of_week, warehouse_name
ORDER BY warehouse_name, day_of_week, hour_of_day;
```

### 4. Warehouse Idle Time Analysis

**Purpose**: Identify warehouses with excessive idle time (poor auto-suspend).

```sql
SELECT
    warehouse_name,
    DATE_TRUNC('day', start_time) AS usage_date,
    COUNT(*) AS hourly_measurements,
    SUM(CASE WHEN credits_used = 0 THEN 1 ELSE 0 END) AS idle_hours,
    SUM(credits_used) AS total_credits,
    (SUM(CASE WHEN credits_used = 0 THEN 1 ELSE 0 END)::FLOAT
        / NULLIF(COUNT(*), 0)) * 100 AS idle_percentage,
    -- Wasted cost estimate
    (SUM(CASE WHEN credits_used = 0 THEN 1 ELSE 0 END) * 2.5) AS potential_savings_usd
FROM snowflake.account_usage.warehouse_metering_history
WHERE start_time >= DATEADD('day', -7, CURRENT_TIMESTAMP())
GROUP BY warehouse_name, usage_date
HAVING idle_percentage > 10  -- > 10% idle
ORDER BY total_credits DESC, idle_percentage DESC;
```

### 5. Credit Cost by User

**Purpose**: Attribute compute costs to users/teams for chargeback.

```sql
WITH user_query_costs AS (
    SELECT
        user_name,
        warehouse_name,
        warehouse_size,
        COUNT(*) AS query_count,
        SUM(execution_time) / 1000 AS total_execution_seconds,
        -- Approximate credits (simplified)
        SUM(
            CASE warehouse_size
                WHEN 'X-Small' THEN execution_time / 1000 / 3600 * 1
                WHEN 'Small' THEN execution_time / 1000 / 3600 * 2
                WHEN 'Medium' THEN execution_time / 1000 / 3600 * 4
                WHEN 'Large' THEN execution_time / 1000 / 3600 * 8
                WHEN 'X-Large' THEN execution_time / 1000 / 3600 * 16
                ELSE execution_time / 1000 / 3600 * 4
            END
        ) AS estimated_credits
    FROM snowflake.account_usage.query_history
    WHERE start_time >= DATE_TRUNC('month', CURRENT_TIMESTAMP())
        AND execution_time > 0
    GROUP BY user_name, warehouse_name, warehouse_size
)
SELECT
    user_name,
    SUM(query_count) AS total_queries,
    SUM(estimated_credits) AS total_credits,
    SUM(estimated_credits) * 2.5 AS estimated_cost_usd,
    RANK() OVER (ORDER BY SUM(estimated_credits) DESC) AS cost_rank
FROM user_query_costs
GROUP BY user_name
ORDER BY total_credits DESC;
```

---

## Storage Cost Queries

### 6. Storage Cost Breakdown

**Purpose**: Monthly storage costs by type (active, time travel, fail-safe).

```sql
SELECT
    DATE_TRUNC('month', usage_date) AS usage_month,
    AVG(storage_bytes) / POWER(1024, 4) AS avg_active_storage_tb,
    AVG(stage_bytes) / POWER(1024, 4) AS avg_stage_storage_tb,
    AVG(failsafe_bytes) / POWER(1024, 4) AS avg_failsafe_storage_tb,
    (AVG(storage_bytes) + AVG(stage_bytes) + AVG(failsafe_bytes)) / POWER(1024, 4) AS avg_total_storage_tb,
    -- Cost estimates (@ $40/TB/month)
    (AVG(storage_bytes) + AVG(stage_bytes) + AVG(failsafe_bytes)) / POWER(1024, 4) * 40 AS estimated_monthly_cost_usd
FROM snowflake.account_usage.storage_usage
WHERE usage_date >= DATEADD('month', -6, CURRENT_DATE())
GROUP BY usage_month
ORDER BY usage_month DESC;
```

### 7. Storage by Database

**Purpose**: Identify largest databases for capacity planning.

```sql
SELECT
    table_catalog AS database_name,
    SUM(active_bytes) / POWER(1024, 3) AS active_storage_gb,
    SUM(time_travel_bytes) / POWER(1024, 3) AS time_travel_gb,
    SUM(failsafe_bytes) / POWER(1024, 3) AS failsafe_gb,
    (SUM(active_bytes) + SUM(time_travel_bytes) + SUM(failsafe_bytes)) / POWER(1024, 3) AS total_storage_gb,
    COUNT(DISTINCT table_name) AS table_count,
    -- Monthly cost estimate
    (SUM(active_bytes) + SUM(time_travel_bytes) + SUM(failsafe_bytes)) / POWER(1024, 4) * 40 AS estimated_monthly_cost_usd
FROM snowflake.account_usage.table_storage_metrics
WHERE active_bytes > 0
GROUP BY database_name
ORDER BY total_storage_gb DESC;
```

### 8. Top 100 Largest Tables

**Purpose**: Identify optimization candidates for storage reduction.

```sql
SELECT
    table_catalog AS database_name,
    table_schema AS schema_name,
    table_name,
    active_bytes / POWER(1024, 3) AS active_gb,
    time_travel_bytes / POWER(1024, 3) AS time_travel_gb,
    failsafe_bytes / POWER(1024, 3) AS failsafe_gb,
    (active_bytes + time_travel_bytes + failsafe_bytes) / POWER(1024, 3) AS total_storage_gb,
    retention_time AS time_travel_days,
    -- Storage cost breakdown
    active_bytes / POWER(1024, 4) * 40 AS active_cost_usd,
    (time_travel_bytes + failsafe_bytes) / POWER(1024, 4) * 40 AS historical_cost_usd,
    (active_bytes + time_travel_bytes + failsafe_bytes) / POWER(1024, 4) * 40 AS total_monthly_cost_usd
FROM snowflake.account_usage.table_storage_metrics
WHERE active_bytes > 0
ORDER BY total_storage_gb DESC
LIMIT 100;
```

### 9. Stage Storage Analysis

**Purpose**: Identify staged files consuming storage (cleanup candidates).

```sql
SELECT
    DATE_TRUNC('month', usage_date) AS usage_month,
    AVG(stage_bytes) / POWER(1024, 3) AS avg_stage_storage_gb,
    AVG(stage_bytes) / POWER(1024, 4) * 40 AS estimated_monthly_cost_usd
FROM snowflake.account_usage.storage_usage
WHERE usage_date >= DATEADD('month', -12, CURRENT_DATE())
GROUP BY usage_month
ORDER BY usage_month DESC;
```

---

## Query Performance Queries

### 10. Top 50 Most Expensive Queries (Last 7 Days)

**Purpose**: Identify optimization targets.

```sql
WITH query_costs AS (
    SELECT
        query_id,
        query_text,
        user_name,
        warehouse_name,
        warehouse_size,
        start_time,
        execution_time / 1000 AS execution_seconds,
        bytes_scanned / POWER(1024, 3) AS gb_scanned,
        rows_produced,
        CASE warehouse_size
            WHEN 'X-Small' THEN execution_seconds / 3600 * 1
            WHEN 'Small' THEN execution_seconds / 3600 * 2
            WHEN 'Medium' THEN execution_seconds / 3600 * 4
            WHEN 'Large' THEN execution_seconds / 3600 * 8
            WHEN 'X-Large' THEN execution_seconds / 3600 * 16
            ELSE execution_seconds / 3600 * 4
        END AS estimated_credits
    FROM snowflake.account_usage.query_history
    WHERE start_time >= DATEADD('day', -7, CURRENT_TIMESTAMP())
        AND execution_time > 10000  -- > 10 seconds
)
SELECT
    query_id,
    LEFT(query_text, 200) AS query_preview,
    user_name,
    warehouse_name,
    warehouse_size,
    start_time,
    execution_seconds,
    gb_scanned,
    rows_produced,
    estimated_credits,
    estimated_credits * 2.5 AS estimated_cost_usd
FROM query_costs
ORDER BY estimated_credits DESC
LIMIT 50;
```

### 11. High-Frequency Query Patterns

**Purpose**: Identify repeated expensive queries for caching/optimization.

```sql
WITH query_patterns AS (
    SELECT
        REGEXP_REPLACE(
            REGEXP_REPLACE(query_text, '\\d+', '<NUM>'),
            '''[^'']*''', '<STRING>'
        ) AS query_pattern,
        COUNT(*) AS execution_count,
        AVG(execution_time) / 1000 AS avg_execution_seconds,
        SUM(execution_time) / 1000 AS total_execution_seconds,
        warehouse_name
    FROM snowflake.account_usage.query_history
    WHERE start_time >= DATEADD('day', -7, CURRENT_TIMESTAMP())
        AND execution_time > 5000  -- > 5 seconds
    GROUP BY query_pattern, warehouse_name
    HAVING execution_count > 10
)
SELECT
    LEFT(query_pattern, 200) AS query_pattern_preview,
    execution_count,
    ROUND(avg_execution_seconds, 2) AS avg_seconds,
    ROUND(total_execution_seconds, 2) AS total_seconds,
    warehouse_name,
    RANK() OVER (ORDER BY total_execution_seconds DESC) AS impact_rank
FROM query_patterns
ORDER BY total_execution_seconds DESC
LIMIT 50;
```

### 12. Queries with Poor Scan Efficiency

**Purpose**: Identify queries scanning excessive data for results produced.

```sql
SELECT
    query_id,
    LEFT(query_text, 200) AS query_preview,
    user_name,
    warehouse_name,
    execution_time / 1000 AS execution_seconds,
    bytes_scanned / POWER(1024, 3) AS gb_scanned,
    rows_produced,
    CASE
        WHEN bytes_scanned > 0 THEN rows_produced / (bytes_scanned / POWER(1024, 3))
        ELSE 0
    END AS rows_per_gb_scanned,
    CASE
        WHEN bytes_scanned > POWER(1024, 3) * 10 AND rows_produced < 1000
            THEN 'INEFFICIENT - Large scan, few rows'
        WHEN bytes_scanned > POWER(1024, 3) * 100
            THEN 'VERY LARGE SCAN'
        WHEN rows_produced = 0 AND bytes_scanned > POWER(1024, 2) * 100
            THEN 'NO RESULTS - Wasted scan'
        ELSE 'Review'
    END AS efficiency_flag
FROM snowflake.account_usage.query_history
WHERE start_time >= DATEADD('day', -7, CURRENT_TIMESTAMP())
    AND bytes_scanned > POWER(1024, 3) * 5  -- > 5 GB scanned
ORDER BY bytes_scanned DESC
LIMIT 100;
```

---

## Warehouse Performance Queries

### 13. Warehouse Utilization & Sizing Recommendations

**Purpose**: Right-size warehouses based on concurrency and queue load.

```sql
WITH warehouse_stats AS (
    SELECT
        warehouse_name,
        DATE_TRUNC('day', start_time) AS usage_date,
        AVG(avg_running) AS avg_concurrency,
        MAX(avg_queued_load) AS max_queue_load,
        SUM(credits_used) AS daily_credits
    FROM snowflake.account_usage.warehouse_load_history
    WHERE start_time >= DATEADD('day', -30, CURRENT_TIMESTAMP())
    GROUP BY warehouse_name, usage_date
)
SELECT
    warehouse_name,
    AVG(avg_concurrency) AS avg_concurrency,
    MAX(max_queue_load) AS peak_queue_load,
    AVG(daily_credits) AS avg_daily_credits,
    CASE
        WHEN AVG(avg_concurrency) < 0.5 AND AVG(daily_credits) > 10 THEN 'DOWNSIZE - Low utilization'
        WHEN MAX(max_queue_load) > 10 THEN 'UPSIZE or ADD MULTI-CLUSTER - High queuing'
        WHEN AVG(avg_concurrency) BETWEEN 0.5 AND 3 THEN 'OPTIMAL - Well-sized'
        ELSE 'REVIEW - Manual analysis needed'
    END AS sizing_recommendation
FROM warehouse_stats
GROUP BY warehouse_name
ORDER BY avg_daily_credits DESC;
```

### 14. Query Queue Wait Times

**Purpose**: Identify warehouses with query queuing issues.

```sql
SELECT
    warehouse_name,
    DATE_TRUNC('hour', start_time) AS hour,
    COUNT(*) AS query_count,
    AVG(queued_provisioning_time + queued_repair_time + queued_overload_time) / 1000 AS avg_queue_seconds,
    MAX(queued_provisioning_time + queued_repair_time + queued_overload_time) / 1000 AS max_queue_seconds,
    SUM(CASE WHEN (queued_provisioning_time + queued_repair_time + queued_overload_time) > 10000 THEN 1 ELSE 0 END) AS queries_queued_10s_plus
FROM snowflake.account_usage.query_history
WHERE start_time >= DATEADD('day', -7, CURRENT_TIMESTAMP())
    AND (queued_provisioning_time + queued_repair_time + queued_overload_time) > 0
GROUP BY warehouse_name, hour
HAVING avg_queue_seconds > 5  -- > 5 seconds average queue
ORDER BY avg_queue_seconds DESC;
```

---

## Serverless Feature Cost Queries

### 15. Automatic Clustering Costs

**Purpose**: Track automatic clustering maintenance costs.

```sql
SELECT
    DATE_TRUNC('day', start_time) AS clustering_date,
    database_name,
    schema_name,
    table_name,
    SUM(credits_used) AS clustering_credits,
    SUM(num_bytes_reclustered) / POWER(1024, 3) AS gb_reclustered,
    SUM(credits_used) * 2.5 AS estimated_cost_usd
FROM snowflake.account_usage.automatic_clustering_history
WHERE start_time >= DATEADD('day', -30, CURRENT_TIMESTAMP())
GROUP BY clustering_date, database_name, schema_name, table_name
HAVING clustering_credits > 1  -- Significant clustering activity
ORDER BY clustering_credits DESC;
```

### 16. Query Acceleration Service Usage

**Purpose**: Track query acceleration costs and benefits.

```sql
SELECT
    warehouse_name,
    DATE_TRUNC('day', start_time) AS usage_date,
    COUNT(*) AS total_queries,
    SUM(CASE WHEN query_acceleration_bytes_scanned > 0 THEN 1 ELSE 0 END) AS accelerated_queries,
    SUM(query_acceleration_bytes_scanned) / POWER(1024, 3) AS acceleration_gb_scanned,
    AVG(CASE WHEN query_acceleration_bytes_scanned > 0
        THEN execution_time / 1000 END) AS avg_accelerated_time_sec,
    -- Approximate credit cost (varies by plan)
    SUM(query_acceleration_bytes_scanned) / POWER(1024, 3) * 0.02 AS estimated_acceleration_cost_usd
FROM snowflake.account_usage.query_history
WHERE start_time >= DATEADD('day', -30, CURRENT_TIMESTAMP())
GROUP BY warehouse_name, usage_date
HAVING accelerated_queries > 0
ORDER BY estimated_acceleration_cost_usd DESC;
```

---

## Budget Monitoring Queries

### 17. Monthly Cost Forecast

**Purpose**: Forecast month-end costs based on current trend.

```sql
WITH daily_spend AS (
    SELECT
        DATE_TRUNC('day', start_time) AS spend_date,
        SUM(credits_used) AS daily_credits
    FROM snowflake.account_usage.warehouse_metering_history
    WHERE start_time >= DATE_TRUNC('month', CURRENT_TIMESTAMP())
    GROUP BY spend_date
)
SELECT
    SUM(daily_credits) AS mtd_credits,
    AVG(daily_credits) AS avg_daily_credits,
    DAY(CURRENT_DATE()) AS days_elapsed,
    DAY(LAST_DAY(CURRENT_DATE())) AS days_in_month,
    AVG(daily_credits) * DAY(LAST_DAY(CURRENT_DATE())) AS forecasted_monthly_credits,
    AVG(daily_credits) * DAY(LAST_DAY(CURRENT_DATE())) * 2.5 AS forecasted_monthly_cost_usd
FROM daily_spend;
```

### 18. Cost Anomaly Detection

**Purpose**: Identify unusual spending days for investigation.

```sql
WITH daily_costs AS (
    SELECT
        DATE_TRUNC('day', start_time) AS usage_date,
        SUM(credits_used) AS daily_credits
    FROM snowflake.account_usage.warehouse_metering_history
    WHERE start_time >= DATEADD('day', -90, CURRENT_TIMESTAMP())
    GROUP BY usage_date
),
cost_stats AS (
    SELECT
        AVG(daily_credits) AS avg_daily_credits,
        STDDEV(daily_credits) AS stddev_daily_credits
    FROM daily_costs
)
SELECT
    dc.usage_date,
    dc.daily_credits,
    cs.avg_daily_credits,
    cs.stddev_daily_credits,
    (dc.daily_credits - cs.avg_daily_credits) / NULLIF(cs.stddev_daily_credits, 0) AS z_score,
    CASE
        WHEN ABS((dc.daily_credits - cs.avg_daily_credits) / NULLIF(cs.stddev_daily_credits, 0)) > 3
        THEN 'CRITICAL ANOMALY - Investigate immediately'
        WHEN ABS((dc.daily_credits - cs.avg_daily_credits) / NULLIF(cs.stddev_daily_credits, 0)) > 2
        THEN 'ANOMALY - Review usage'
        ELSE 'Normal'
    END AS status
FROM daily_costs dc
CROSS JOIN cost_stats cs
WHERE dc.usage_date >= DATEADD('day', -30, CURRENT_TIMESTAMP())
    AND ABS((dc.daily_credits - cs.avg_daily_credits) / NULLIF(cs.stddev_daily_credits, 0)) > 2
ORDER BY ABS(z_score) DESC;
```

---

## Notes

### Data Latency

- `ACCOUNT_USAGE` views have 45-minute to 3-hour latency
- For real-time data, use `INFORMATION_SCHEMA` views (limited history)
- Storage metrics updated once per day

### Credit Cost Assumptions

- Queries use `$2.50/credit` as placeholder
- **Adjust based on your actual Snowflake contract pricing**
- Pricing varies by region, cloud provider, and contract type

### Query Performance

- `ACCOUNT_USAGE` queries can be expensive on large accounts
- Add `LIMIT` clauses for exploratory analysis
- Cache frequently-used results in tables for dashboards

---

**Key Takeaway**: These queries provide the foundation for comprehensive cost monitoring. Schedule critical queries (daily consumption, forecasts) and run optimization queries (expensive queries, storage analysis) weekly as part of regular cost management practices.
