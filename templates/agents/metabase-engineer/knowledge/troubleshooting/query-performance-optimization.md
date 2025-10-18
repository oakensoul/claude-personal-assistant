---
title: "Query Performance Optimization"
description: "Techniques for optimizing slow Metabase queries and improving dashboard load times"
category: "troubleshooting"
tags: ["performance", "optimization", "queries", "sql"]
last_updated: "2025-10-16"
---

# Query Performance Optimization

Comprehensive guide to diagnosing and fixing slow Metabase queries and dashboard performance issues.

## Quick Diagnosis Checklist

**When a dashboard is loading slowly**:
- [ ] Check how many questions are on the dashboard (>15-20 is too many)
- [ ] Look at query execution times in Metabase admin
- [ ] Verify queries have WHERE clauses on date columns
- [ ] Confirm using marts instead of raw fact tables
- [ ] Check for missing indexes on filter columns
- [ ] Review Snowflake query history for actual performance

## Common Performance Issues

### Issue 1: Missing Date Filters

**Problem**: Query scans entire table without date range filter.

**Bad Example**:
```sql
SELECT
  SUM(amount) as total_handle
FROM fct_wallet_transactions
WHERE user_tier = 'premium'
```

**Fixed Example**:
```sql
SELECT
  SUM(amount) as total_handle
FROM fct_wallet_transactions
WHERE user_tier = 'premium'
  AND date_actual BETWEEN '2025-01-01' AND '2025-12-31'
```

**Why It Matters**: Date filters enable partition pruning in Snowflake, dramatically reducing data scanned.

**Always include**:
- Date range filter for time-series data
- Use dashboard date parameter
- Default to reasonable range (last 30 days)

### Issue 2: Using Fact Tables Instead of Marts

**Problem**: Querying large fact tables instead of pre-aggregated marts.

**Bad Example**:
```sql
-- Scanning millions of rows
SELECT
  date_actual,
  SUM(amount) as daily_revenue
FROM fct_wallet_transactions
WHERE transaction_type = 'contest_fee'
  AND date_actual >= '2025-01-01'
GROUP BY date_actual
```

**Fixed Example**:
```sql
-- Using pre-aggregated mart
SELECT
  date_actual,
  total_revenue as daily_revenue
FROM finance_revenue_daily
WHERE date_actual >= '2025-01-01'
```

**Benefits**:
- 100-1000x faster queries
- Consistent business logic
- Reduced Snowflake costs

**When to use marts**:
- Dashboard KPI scorecards
- Time-series trend charts
- Executive summaries

**When to use fact tables**:
- Detailed drill-down queries
- Ad-hoc analysis
- One-off reports

### Issue 3: SELECT * in Native Queries

**Problem**: Selecting all columns when only a few are needed.

**Bad Example**:
```sql
SELECT * FROM dim_user
WHERE user_tier = 'premium'
```

**Fixed Example**:
```sql
SELECT
  user_id,
  username,
  user_tier,
  created_at
FROM dim_user
WHERE user_tier = 'premium'
```

**Why It Matters**:
- Transfers less data over network
- Faster result set processing
- More efficient Snowflake warehouse usage

### Issue 4: No LIMIT on Large Result Sets

**Problem**: Returning millions of rows to Metabase.

**Bad Example**:
```sql
SELECT
  transaction_id,
  user_id,
  amount,
  date_actual
FROM fct_wallet_transactions
WHERE date_actual >= '2025-01-01'
```

**Fixed Example**:
```sql
SELECT
  transaction_id,
  user_id,
  amount,
  date_actual
FROM fct_wallet_transactions
WHERE date_actual >= '2025-01-01'
ORDER BY date_actual DESC
LIMIT 1000  -- Reasonable limit for UI display
```

**Best Practices**:
- Always LIMIT table visualizations
- Use pagination for large datasets
- Consider drill-through instead of one huge table
- 1000-5000 rows max for Metabase tables

### Issue 5: Inefficient JOIN Patterns

**Problem**: JOINing large tables without proper filters.

**Bad Example**:
```sql
SELECT
  u.username,
  SUM(t.amount) as total
FROM fct_wallet_transactions t
JOIN dim_user u ON t.user_id = u.user_id
GROUP BY u.username
```

**Fixed Example**:
```sql
SELECT
  u.username,
  SUM(t.amount) as total
FROM fct_wallet_transactions t
JOIN dim_user u ON t.user_id = u.user_id
WHERE t.date_actual >= '2025-01-01'
  AND u.user_tier IN ('premium', 'vip')  -- Filter dimension early
GROUP BY u.username
LIMIT 100
```

**Optimization Techniques**:
- Filter large tables before JOIN
- Use appropriate JOIN type (INNER vs LEFT)
- Filter dimensions to reduce JOIN cardinality
- Consider pre-joined marts

### Issue 6: Window Functions Without Partitioning

**Problem**: Window functions scanning entire table.

**Bad Example**:
```sql
SELECT
  date_actual,
  amount,
  SUM(amount) OVER (ORDER BY date_actual) as cumulative
FROM fct_wallet_transactions
ORDER BY date_actual
```

**Fixed Example**:
```sql
SELECT
  date_actual,
  amount,
  SUM(amount) OVER (
    PARTITION BY user_tier
    ORDER BY date_actual
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) as cumulative
FROM fct_wallet_transactions
WHERE date_actual >= '2025-01-01'
ORDER BY date_actual
```

**Best Practices**:
- Always include PARTITION BY when possible
- Use explicit frame clause (ROWS BETWEEN)
- Filter data before windowing
- Consider pre-computing in dbt

### Issue 7: Subqueries in SELECT Clause

**Problem**: Correlated subqueries execute for each row.

**Bad Example**:
```sql
SELECT
  u.user_id,
  u.username,
  (
    SELECT SUM(amount)
    FROM fct_wallet_transactions t
    WHERE t.user_id = u.user_id
  ) as total_amount
FROM dim_user u
```

**Fixed Example**:
```sql
SELECT
  u.user_id,
  u.username,
  COALESCE(SUM(t.amount), 0) as total_amount
FROM dim_user u
LEFT JOIN fct_wallet_transactions t
  ON u.user_id = t.user_id
  AND t.date_actual >= '2025-01-01'
GROUP BY u.user_id, u.username
```

**Why It's Faster**: Single JOIN with GROUP BY instead of N subqueries.

## Dashboard-Level Optimizations

### Reduce Question Count

**Problem**: Dashboard with 30+ questions loads slowly.

**Solution**:
1. Combine related metrics into single table question
2. Remove low-value visualizations
3. Split into multiple dashboards by audience
4. Use tabs within dashboard

**Guideline**: 15-20 questions max per dashboard.

### Enable Dashboard Caching

```yaml
# Dashboard specification
name: "Market Maker Performance"
cache_ttl: 3600  # 1 hour cache

questions:
  - name: "Total Handle"
    cache_ttl: 1800  # 30 minute override for this question
```

**Cache Strategy**:
- **Hourly updates**: 3600s (1 hour)
- **Daily updates**: 86400s (24 hours)
- **Real-time**: 60s or disable cache
- **Executive dashboards**: Long cache (multiple hours)

### Async Question Loading

Metabase loads questions sequentially by default. For better UX:

1. Place most important questions first (top row)
2. Use smaller `sizeY` for KPIs (load faster)
3. Consider separating heavy queries to different dashboard

### Pre-filter with Dashboard Parameters

```yaml
filters:
  - name: "Date Range"
    field: "date_actual"
    type: "date-range"
    default: "last-30-days"  # Reasonable default

questions:
  - name: "Revenue Trend"
    query:
      filters:
        - field: "date_actual"
          value: "{{date_range}}"  # Use dashboard filter
```

**Benefits**:
- Users can't accidentally query all data
- Consistent filtering across questions
- Single parameter change updates all questions

## Snowflake-Specific Optimizations

### Use Clustering Keys

For large fact tables, ensure proper clustering:

```sql
-- In dbt model
{{
  config(
    materialized='incremental',
    cluster_by=['date_actual', 'user_tier']
  )
}}
```

**Benefit**: Faster queries when filtering on clustered columns.

### Partition Pruning

Always filter on partition column (usually `date_actual`):

```sql
-- Query plan shows "Partition statistics: 365 total, 30 scanned"
SELECT SUM(amount)
FROM fct_wallet_transactions
WHERE date_actual BETWEEN '2025-10-01' AND '2025-10-31'
```

### Appropriate Warehouse Sizing

**Metabase Query Characteristics**:
- Many small queries (KPI scorecards)
- Occasional large queries (detail tables)
- Dashboard loads = burst of queries

**Recommended**:
- Use X-Small or Small warehouse for Metabase
- Enable auto-suspend (1 minute)
- Auto-resume enabled
- Consider separate warehouse for Metabase vs dbt

### Result Set Caching

Snowflake caches query results for 24 hours.

**Leverage Caching**:
- Use consistent query patterns
- Identical queries return cached results
- Works across Metabase users

## Optimization Workflow

### Step 1: Identify Slow Queries

**Metabase Admin Panel**:
1. Go to Settings → Admin → Performance
2. Review query execution times
3. Sort by duration descending
4. Identify queries >5 seconds

**Snowflake Query History**:
```sql
-- Review Metabase query performance
SELECT
  query_text,
  execution_time / 1000 as seconds,
  warehouse_size,
  bytes_scanned,
  partitions_scanned,
  start_time
FROM snowflake.account_usage.query_history
WHERE user_name = 'METABASE_USER'
  AND start_time >= DATEADD(day, -7, CURRENT_TIMESTAMP())
ORDER BY execution_time DESC
LIMIT 100;
```

### Step 2: Analyze Query Plan

**In Snowflake**:
```sql
EXPLAIN
SELECT ...  -- Your slow query
```

**Look For**:
- Table scans without pruning
- Large number of partitions scanned
- Inefficient JOIN orders
- Missing filters

### Step 3: Apply Optimizations

**Priority Order**:
1. Add date filter (biggest impact)
2. Use mart instead of fact table
3. Add LIMIT clause
4. Optimize JOIN conditions
5. Remove unnecessary columns
6. Add indexes/clustering (if needed)

### Step 4: Measure Improvement

**Before/After Comparison**:
- Query execution time
- Data scanned (GB)
- Partitions scanned
- Dashboard load time

**Target**:
- Queries <2 seconds
- KPIs <500ms
- Dashboard load <10 seconds

## When to Involve sql-expert Agent

**Escalate to sql-expert when**:
- Query requires complex optimization
- Need to refactor SQL structure
- Performance issues despite following guidelines
- Need to modify underlying dbt models
- Advanced Snowflake features needed (clustering, materialization)

**Handoff Pattern**:
```yaml
# metabase-engineer identifies slow query
"This Market Maker dashboard query is taking 15 seconds. Here's the SQL:
[paste SQL]

Context:
- Querying fct_house_slips (2M rows)
- Date filter applied (last 30 days)
- Multiple window functions
- Already using marts where available

Can you optimize this?"
```

## Performance Testing

### Test Query in Snowflake First

```sql
-- Test query before adding to Metabase
SELECT ...
-- Check execution time in Snowflake UI
```

### Load Test Dashboards

```bash
# Simulate multiple users loading dashboard
for i in {1..10}; do
  curl -X GET "https://metabase.example.com/api/dashboard/123" \
    -H "X-Metabase-Session: $SESSION_TOKEN" &
done
wait
```

### Monitor Snowflake Warehouse Usage

```sql
-- Check Metabase warehouse efficiency
SELECT
  DATE_TRUNC('hour', start_time) as hour,
  COUNT(*) as query_count,
  AVG(execution_time) / 1000 as avg_seconds,
  SUM(credits_used_compute) as credits
FROM snowflake.account_usage.query_history
WHERE warehouse_name = 'METABASE_WH'
  AND start_time >= DATEADD(day, -7, CURRENT_TIMESTAMP())
GROUP BY hour
ORDER BY hour DESC;
```

## Best Practices Summary

1. **Always filter by date** - Especially on partitioned tables
2. **Use marts not facts** - For aggregated metrics
3. **Limit result sets** - 1000-5000 rows max for tables
4. **Specify columns** - Avoid SELECT *
5. **Enable caching** - Dashboard and question-level
6. **Reduce question count** - 15-20 max per dashboard
7. **Test in Snowflake** - Before deploying to Metabase
8. **Monitor performance** - Use Metabase admin and Snowflake query history

---

**Related Documents**:
- [sql-expert-integration.md](../integrations/sql-expert-integration.md) - When to get SQL help
- [dashboard-load-issues.md](dashboard-load-issues.md) - Dashboard-specific issues
- [common-api-errors.md](common-api-errors.md) - API performance issues
