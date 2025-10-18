---
title: "Warehouse Optimization"
description: "Comprehensive guide to Snowflake warehouse sizing, auto-suspend/resume, scaling, and performance tuning"
category: "core-concepts"
tags: ["warehouse", "sizing", "auto-suspend", "scaling", "performance"]
version: "1.0.0"
last_updated: "2025-10-07"
---

# Warehouse Optimization

Snowflake warehouses are clusters of compute resources that execute queries. Optimizing warehouse configuration is critical for balancing cost and performance.

## Warehouse Fundamentals

### What is a Warehouse?

- **Virtual Warehouse**: Cluster of compute nodes that execute queries
- **Elasticity**: Can be started, stopped, resized dynamically
- **Isolation**: Multiple warehouses can run concurrently without interference
- **Independence**: Each warehouse has dedicated compute resources

### Warehouse Properties

**Key Configuration Settings**:

- **Size**: X-Small to 4X-Large (compute power and cost)
- **Auto-Suspend**: Idle timeout before automatic shutdown
- **Auto-Resume**: Automatically start when query submitted
- **Min/Max Clusters**: For multi-cluster warehouses (Enterprise)
- **Scaling Policy**: How multi-cluster scales (Standard or Economy)

## Warehouse Sizing Strategy

### Size Selection Decision Tree

```text
1. What is query complexity?
   - Simple aggregations, filters → Start X-Small/Small
   - Complex joins, window functions → Start Medium/Large
   - Heavy transformations, ML → Start Large/X-Large

2. What is data volume?
   - < 100K rows → X-Small
   - 100K - 1M rows → Small
   - 1M - 10M rows → Medium
   - 10M - 100M rows → Large
   - 100M+ rows → X-Large+

3. What is concurrency requirement?
   - 1-2 concurrent users → Single X-Small/Small
   - 3-8 concurrent users → Single Medium/Large
   - 8+ concurrent users → Multi-cluster warehouse

4. What is latency requirement?
   - < 5 seconds → Size for peak load
   - 5-30 seconds → Size for average load
   - > 30 seconds → Optimize queries first, then size
```

### Recommended Starting Sizes by Use Case

| Use Case | Starting Size | Rationale |
|----------|---------------|-----------|
| **Development** | X-Small | Low volume, interactive queries, cost-conscious |
| **dbt Staging/Intermediate** | Small | Moderate transformations, frequent builds |
| **dbt Critical Models** | Medium | High-frequency, business-critical data |
| **dbt High-Volume (Segment)** | Large | Massive row counts, complex processing |
| **BI Dashboards (Metabase)** | Small-Medium | Mixed simple/complex queries, caching helps |
| **Ad-hoc Analysis** | Small | Exploratory queries, variable complexity |
| **Data Science** | Medium-Large | Complex computations, ML workloads |
| **Reporting (Scheduled)** | Medium | Consistent workload, predictable resource needs |

### Sizing Performance Characteristics

**Doubling Warehouse Size**:

- **Doubles cost** (credits/hour)
- **Roughly halves execution time** for compute-bound queries
- **Limited benefit** for I/O-bound or network-bound queries
- **Diminishing returns** beyond certain size for small datasets

**Example**:

- Query on Medium (4 credits/hour): 10 minutes = 0.67 credits
- Same query on Large (8 credits/hour): ~5 minutes = 0.67 credits
- **Same cost**, faster result (if compute-bound)

**When Larger Size Helps**:
✅ Large datasets (>10M rows)
✅ Complex joins and aggregations
✅ Window functions, QUALIFY clauses
✅ Heavy CPU processing (JSON parsing, regex)

**When Larger Size Does NOT Help**:
❌ Simple queries on small datasets
❌ Queries waiting on external data (stages, external tables)
❌ Metadata operations (SHOW, DESCRIBE)
❌ Result set limited by LIMIT clause

## Auto-Suspend Configuration

### Auto-Suspend Strategy

**Purpose**: Automatically stop warehouse after idle period to prevent waste

**Recommended Settings**:

| Warehouse Type | Auto-Suspend | Reasoning |
|----------------|--------------|-----------|
| **Development** | 60 seconds | Frequent start/stop, minimize waste |
| **dbt Production** | 60 seconds | Jobs finish, immediate shutdown |
| **BI Dashboards** | 300-600 seconds | Users browsing, brief pauses expected |
| **Ad-hoc Analysis** | 120-300 seconds | Analysts thinking between queries |
| **Scheduled Reports** | 60 seconds | Single job execution, then idle |

**Tradeoff Analysis**:

**Shorter Auto-Suspend (60 seconds)**:

- ✅ Minimizes idle time cost
- ✅ Prevents accidental "left on" scenarios
- ❌ More frequent cold starts (cache loss)
- ❌ Slight delay for query resume (~5-10 seconds)

**Longer Auto-Suspend (600 seconds)**:

- ✅ Maintains query result cache
- ✅ Fewer cold starts for interactive users
- ❌ Higher idle time cost if user leaves
- ❌ Can waste significant credits if forgotten

**Best Practice**: Start with 60 seconds, increase only if cold-start delays impact user experience significantly.

### Auto-Resume Configuration

**Always Enable Auto-Resume**:

- Queries automatically start suspended warehouses
- No manual intervention required
- Slight delay (5-10 seconds) for warehouse startup

```sql
-- Enable auto-suspend and auto-resume
ALTER WAREHOUSE my_warehouse SET
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;
```

## Multi-Cluster Warehouses (Enterprise Feature)

### When to Use Multi-Cluster

**Problem**: Single warehouse has limited concurrency

- Queries queue when all compute slots busy
- User-facing dashboards become slow during peak times
- Cannot scale vertically (size) due to cost

**Solution**: Multi-cluster warehouse

- Dynamically adds clusters during high concurrency
- Automatically scales down when demand drops
- Maintains performance SLAs for interactive workloads

### Multi-Cluster Configuration

**Min/Max Clusters**:

- **Min Clusters**: Always-running clusters (default 1)
- **Max Clusters**: Maximum clusters during peak (set based on budget/peak load)

**Scaling Policy**:

1. **Standard** (default): Aggressively starts clusters when queue forms
2. **Economy**: Waits to fully utilize existing clusters before adding

```sql
-- Create multi-cluster warehouse
CREATE WAREHOUSE bi_warehouse_multi
WITH
    WAREHOUSE_SIZE = 'SMALL'
    MIN_CLUSTER_COUNT = 1
    MAX_CLUSTER_COUNT = 5
    SCALING_POLICY = 'STANDARD'
    AUTO_SUSPEND = 300
    AUTO_RESUME = TRUE;
```

### Multi-Cluster Cost Analysis

**Example**:

- Small warehouse (2 credits/hour)
- Min: 1 cluster, Max: 4 clusters
- Peak hours: 8 hours/day, 4 clusters running
- Off-peak: 16 hours/day, 1 cluster running (@ 50% utilization)

**Calculation**:

```text
Peak cost = 8 hours × 4 clusters × 2 credits/hour = 64 credits/day
Off-peak cost = 16 hours × 1 cluster × 2 credits/hour × 0.5 = 16 credits/day
Total daily cost = 64 + 16 = 80 credits
Monthly cost = 80 × 30 = 2,400 credits @ $2.50 = $6,000/month
```

**Alternative (Single Large Warehouse)**:

```text
Large warehouse = 8 credits/hour
Running 24 hours (auto-suspend not useful for constant queries)
Daily cost = 24 × 8 = 192 credits
Monthly cost = 192 × 30 = 5,760 credits @ $2.50 = $14,400/month
```

**Multi-cluster saves $8,400/month (58%)** in this scenario.

## Query Performance Optimization

### Warehouse Optimization Signals

**Indicators to Upsize**:

- **Queue Load > 10**: Queries consistently waiting
- **Execution Time Variance**: Same query varies wildly
- **Resource Monitor Alerts**: Hitting credit limits due to long-running queries
- **User Complaints**: Dashboard/report slowness

```sql
-- Check warehouse load and queuing
SELECT
    warehouse_name,
    DATE_TRUNC('hour', start_time) AS hour,
    AVG(avg_running) AS avg_concurrency,
    MAX(avg_queued_load) AS max_queue_load,
    COUNT(*) AS query_count
FROM snowflake.account_usage.warehouse_load_history
WHERE start_time >= DATEADD('day', -7, CURRENT_TIMESTAMP())
GROUP BY 1, 2
HAVING max_queue_load > 5
ORDER BY max_queue_load DESC;
```

**Indicators to Downsize**:

- **Low Concurrency**: avg_running < 1 consistently
- **High Idle Time**: > 20% of metered time is idle
- **Small Query Execution**: Queries finish in < 1 second
- **Cost Pressure**: Need to reduce spend, queries are "fast enough"

```sql
-- Check warehouse utilization
WITH warehouse_usage AS (
    SELECT
        warehouse_name,
        DATE_TRUNC('day', start_time) AS usage_date,
        SUM(credits_used) AS daily_credits,
        COUNT(*) AS query_count,
        AVG(avg_running) AS avg_concurrency
    FROM snowflake.account_usage.warehouse_load_history
    WHERE start_time >= DATEADD('day', -30, CURRENT_TIMESTAMP())
    GROUP BY 1, 2
)
SELECT
    warehouse_name,
    AVG(daily_credits) AS avg_daily_credits,
    AVG(avg_concurrency) AS avg_concurrency,
    CASE
        WHEN AVG(avg_concurrency) < 0.5 THEN 'Consider downsizing'
        WHEN AVG(avg_concurrency) BETWEEN 0.5 AND 2 THEN 'Well-sized'
        WHEN AVG(avg_concurrency) > 2 THEN 'Consider multi-cluster or upsize'
    END AS sizing_recommendation
FROM warehouse_usage
GROUP BY warehouse_name
ORDER BY avg_daily_credits DESC;
```

### Query Acceleration Service

**What is Query Acceleration?**

- Serverless compute that offloads query portions to elastic resources
- Helps with unpredictable workload spikes
- Can be more cost-effective than maintaining large warehouse

**When to Enable**:
✅ Occasional complex queries among simple ones
✅ Unpredictable dashboard usage patterns
✅ Want to keep warehouse small but handle spikes

**When to Avoid**:
❌ Consistently heavy workloads (upsize warehouse instead)
❌ All queries are simple (no benefit)
❌ Need predictable costs (acceleration costs vary)

```sql
-- Enable query acceleration
ALTER WAREHOUSE my_warehouse SET
    ENABLE_QUERY_ACCELERATION = TRUE
    QUERY_ACCELERATION_MAX_SCALE_FACTOR = 8;  -- Max 8x warehouse size

-- Monitor query acceleration usage
SELECT
    warehouse_name,
    DATE_TRUNC('day', start_time) AS usage_date,
    COUNT(*) AS total_queries,
    SUM(CASE WHEN query_acceleration_bytes_scanned > 0 THEN 1 ELSE 0 END) AS accelerated_queries,
    SUM(query_acceleration_bytes_scanned) / POWER(1024, 3) AS gb_scanned,
    AVG(CASE WHEN query_acceleration_bytes_scanned > 0
        THEN execution_time / 1000 END) AS avg_accelerated_time_sec
FROM snowflake.account_usage.query_history
WHERE start_time >= DATEADD('day', -30, CURRENT_TIMESTAMP())
GROUP BY 1, 2
HAVING accelerated_queries > 0
ORDER BY 1, 2 DESC;
```

## Warehouse Isolation & Specialization

### Workload Separation Strategy

**Why Separate Warehouses?**

- **Cost Attribution**: Track costs by team/workload
- **Priority Management**: Critical workloads not blocked by ad-hoc
- **Resource Guarantees**: SLA-driven sizing per workload
- **Optimization Flexibility**: Different configs per use case

**Recommended Warehouse Architecture** (dbt-splash-prod-v2):

```yaml
Warehouses:
  DBT_DEV_WH:
    Size: X-Small
    Auto-Suspend: 60
    Purpose: Development dbt builds (exclude high-volume)

  DBT_PROD_CRITICAL_WH:
    Size: Medium
    Auto-Suspend: 60
    Purpose: tag:critical:true models (high-frequency)

  DBT_PROD_HEAVY_WH:
    Size: Large
    Auto-Suspend: 60
    Purpose: tag:volume:high (Segment data)

  DBT_MARTS_WH:
    Size: Small
    Auto-Suspend: 60
    Purpose: tag:layer:marts (business aggregates)

  METABASE_WH:
    Size: Small
    Min-Clusters: 1
    Max-Clusters: 3
    Auto-Suspend: 300
    Purpose: BI dashboard queries (multi-cluster for concurrency)

  ANALYST_WH:
    Size: Small
    Auto-Suspend: 120
    Purpose: Ad-hoc SQL queries (Snowflake worksheets)
```

### Cost Attribution via Warehouses

**Tag Warehouses for Chargeback**:

```sql
-- Tag warehouses for cost tracking
ALTER WAREHOUSE DBT_PROD_CRITICAL_WH SET TAG cost_center = 'data_engineering';
ALTER WAREHOUSE METABASE_WH SET TAG cost_center = 'business_intelligence';
ALTER WAREHOUSE ANALYST_WH SET TAG cost_center = 'analytics_team';

-- Query costs by cost center
SELECT
    w.warehouse_name,
    SYSTEM$GET_TAG('cost_center', w.warehouse_name, 'WAREHOUSE') AS cost_center,
    SUM(m.credits_used) AS total_credits,
    SUM(m.credits_used) * 2.5 AS estimated_cost_usd
FROM snowflake.account_usage.warehouse_metering_history m
JOIN snowflake.account_usage.warehouses w ON m.warehouse_name = w.name
WHERE m.start_time >= DATE_TRUNC('month', CURRENT_TIMESTAMP())
GROUP BY w.warehouse_name, cost_center
ORDER BY total_credits DESC;
```

## Advanced Optimization Techniques

### Result Caching

**Snowflake Result Cache**:

- Automatic 24-hour cache for identical queries
- Zero compute cost for cache hits
- Invalidated when underlying data changes

**Optimization**:

- Encourage dashboard query standardization (same SQL = cache hit)
- Use query result reuse for repeated reports
- Consider scheduled query warming for critical dashboards

### Warehouse Warming

**Cold Start Cost**:

- First query after warehouse start is slower (no cache)
- Data must be loaded into warehouse cache
- Subsequent queries benefit from warm cache

**Warming Strategy**:

```sql
-- Schedule warming query before peak hours
-- Run at 8:00 AM daily to warm cache for business hours
SELECT COUNT(*) FROM critical_fact_table;
SELECT COUNT(*) FROM critical_dimension_table;
```

### Statement Queuing

**Query Queue Management**:

- Snowflake queues queries when warehouse at capacity
- Statement Queue Timeout: Maximum wait time before failure
- Statement Timeout: Maximum execution time

```sql
-- Configure statement parameters
ALTER WAREHOUSE my_warehouse SET
    STATEMENT_QUEUED_TIMEOUT_IN_SECONDS = 120  -- Max 2 min wait
    STATEMENT_TIMEOUT_IN_SECONDS = 3600;  -- Max 1 hour execution
```

## Monitoring & Alerts

### Key Metrics to Monitor

1. **Credit Consumption** (daily/weekly/monthly trends)
2. **Query Queue Load** (indicate need for multi-cluster)
3. **Average Concurrency** (warehouse utilization)
4. **Idle Time Percentage** (auto-suspend effectiveness)
5. **Query Execution Time** (performance SLAs)

### Sample Monitoring Queries

**Warehouse Performance Summary**:

```sql
WITH warehouse_stats AS (
    SELECT
        warehouse_name,
        DATE_TRUNC('week', start_time) AS week,
        SUM(credits_used) AS weekly_credits,
        AVG(avg_running) AS avg_concurrency,
        MAX(avg_queued_load) AS max_queue_load,
        COUNT(*) AS query_count
    FROM snowflake.account_usage.warehouse_load_history
    WHERE start_time >= DATEADD('week', -4, CURRENT_TIMESTAMP())
    GROUP BY 1, 2
)
SELECT
    warehouse_name,
    AVG(weekly_credits) AS avg_weekly_credits,
    AVG(avg_concurrency) AS avg_concurrency,
    MAX(max_queue_load) AS peak_queue_load,
    AVG(query_count) AS avg_weekly_queries,
    CASE
        WHEN AVG(avg_concurrency) < 0.5 AND AVG(weekly_credits) > 10 THEN 'DOWNSIZE'
        WHEN MAX(max_queue_load) > 10 THEN 'ADD MULTI-CLUSTER or UPSIZE'
        WHEN AVG(avg_concurrency) BETWEEN 0.5 AND 3 THEN 'OPTIMAL'
        ELSE 'REVIEW'
    END AS recommendation
FROM warehouse_stats
GROUP BY warehouse_name
ORDER BY avg_weekly_credits DESC;
```

**Idle Time Analysis**:

```sql
SELECT
    warehouse_name,
    DATE_TRUNC('day', start_time) AS usage_date,
    COUNT(*) AS hourly_measurements,
    SUM(CASE WHEN credits_used = 0 THEN 1 ELSE 0 END) AS idle_hours,
    SUM(credits_used) AS total_credits,
    (idle_hours::FLOAT / NULLIF(hourly_measurements, 0)) * 100 AS idle_percentage
FROM snowflake.account_usage.warehouse_metering_history
WHERE start_time >= DATEADD('day', -7, CURRENT_TIMESTAMP())
GROUP BY warehouse_name, usage_date
HAVING idle_percentage > 20  -- > 20% idle time
ORDER BY total_credits DESC, idle_percentage DESC;
```

## Best Practices Summary

### Sizing Best Practices

1. **Start small**, upsize based on actual performance metrics
2. **Measure before optimizing** - use ACCOUNT_USAGE data
3. **Separate workloads** by warehouse for cost attribution and optimization
4. **Use multi-cluster** for concurrency, not single large warehouse

### Configuration Best Practices

1. **Auto-suspend 60 seconds** for most warehouses (adjust for UX if needed)
2. **Always enable auto-resume** for convenience
3. **Statement timeouts** to prevent runaway queries
4. **Resource monitors** on all production warehouses

### Monitoring Best Practices

1. **Weekly reviews** of credit consumption and warehouse utilization
2. **Alert on queue load > 10** (indicates need for scaling)
3. **Track idle time percentage** (should be < 10%)
4. **Monthly cost attribution** reports by team/project

---

**Key Takeaway**: Warehouse optimization is about finding the right balance between cost and performance. Start with conservative sizing, monitor actual usage patterns, and adjust based on data—not assumptions. The goal is efficient resource utilization, not the smallest possible warehouse at all costs.
