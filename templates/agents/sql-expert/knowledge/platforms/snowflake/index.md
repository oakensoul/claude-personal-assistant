---
title: "Snowflake SQL - Platform-Specific Knowledge"
description: "Snowflake-specific features, optimizations, and patterns"
platform: "snowflake"
last_updated: "2025-10-15"
---

# Snowflake SQL - Platform-Specific Knowledge

This directory contains Snowflake-specific SQL features, optimization techniques, and patterns.

## Core Concepts

- **snowflake-query-optimization-fundamentals.md** - Micro-partitions, clustering, query execution model, warehouse sizing, cost optimization
- **query-profile-analysis.md** - Query execution plan interpretation, bottleneck identification, spillage analysis, partition pruning validation

## Patterns & Techniques

- **window-function-optimization.md** - QUALIFY usage, partition optimization, ROW_NUMBER/RANK patterns, LEAD/LAG examples
- **semi-structured-data-handling.md** - FLATTEN operations, VARIANT/JSON property extraction, nested object handling, ARRAY/OBJECT functions
- **match-recognize-patterns.md** - Time-series pattern matching, contest streaks, user engagement funnels, fraud detection
- **clustering-and-search-optimization.md** - Clustering key strategies, search optimization service, partition pruning, performance tuning
- **snowsql-automation-patterns.md** - CI/CD pipeline integration, bash scripting, parallel execution, error handling

## Decisions

- **performance-anti-patterns.md** - 20+ anti-patterns with corrected examples (SELECT *, implicit conversions, inefficient joins, etc.)

## Snowflake-Specific Features

### QUALIFY Clause
Filter window function results without subquery:
```sql
SELECT customer_id, order_date, order_amount,
       ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date DESC) as rn
FROM orders
QUALIFY rn = 1  -- Get most recent order per customer
```

### FLATTEN Function
Expand semi-structured data:
```sql
SELECT
    f.value:name::STRING as event_name,
    f.value:timestamp::TIMESTAMP as event_timestamp
FROM raw_events,
LATERAL FLATTEN(input => event_data:events) f
```

### Time Travel
Query historical data:
```sql
SELECT * FROM orders
AT(TIMESTAMP => '2025-01-01 00:00:00'::TIMESTAMP)
```

### Zero-Copy Cloning
Instant table/database copies:
```sql
CREATE DATABASE dev_clone CLONE production
```

## When to Use Snowflake-Specific Features

- **QUALIFY**: When filtering window function results (avoid subqueries)
- **FLATTEN**: When working with JSON/VARIANT data from APIs, event streams
- **CLUSTER BY**: For large tables with time-based queries
- **Time Travel**: For data recovery, auditing, point-in-time analysis
- **Warehouse Sizing**: Balance cost vs performance based on query patterns

## Integration with dbt

Snowflake features work seamlessly with dbt:
- Use QUALIFY in dbt models for cleaner code
- FLATTEN in staging models for semi-structured data
- Clustering keys in dbt model config
- Incremental models leverage micro-partitions

## Cost Optimization

- **Auto-suspend**: Set warehouses to suspend after 5-10 minutes of inactivity
- **Auto-resume**: Enable for on-demand compute
- **Right-sizing**: Use smallest warehouse that meets performance SLAs
- **Clustering**: Only for large tables (>1TB) with clear access patterns
- **Search Optimization**: For point lookups on large tables

## External References

- [Snowflake Documentation](https://docs.snowflake.com/)
- [Snowflake Best Practices](https://docs.snowflake.com/en/user-guide/ui-snowsight-query-optimize)
- [dbt + Snowflake Guide](https://docs.getdbt.com/reference/warehouse-setups/snowflake-setup)
