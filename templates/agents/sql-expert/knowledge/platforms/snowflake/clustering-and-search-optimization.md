---
title: "Clustering Keys and Search Optimization Guide"
description: "Comprehensive guide to Snowflake clustering keys, search optimization service, and performance tuning strategies"
agent: "snowflake-sql-expert"
category: "patterns"
tags:
  - clustering
  - search-optimization
  - performance
  - micro-partitions
  - pruning
  - indexing
last_updated: "2025-10-07"
priority: "high"
use_cases:
  - "Large fact table optimization"
  - "Time-series query performance"
  - "Point lookup optimization"
  - "Partition pruning improvement"
---

# Clustering Keys and Search Optimization Guide

## Overview

Snowflake uses micro-partitions for data storage, and clustering keys help organize data within those partitions for optimal query performance. This guide covers when and how to use clustering keys and search optimization in the dbt-splash-prod-v2 project.

## Understanding Micro-Partitions

### What are Micro-Partitions?

Snowflake automatically divides tables into compressed, immutable micro-partitions:

- **Size**: 50-500 MB uncompressed data each
- **Automatic**: Created automatically during data load/insert
- **Immutable**: Once written, never modified (only replaced)
- **Metadata**: Snowflake maintains min/max values, distinct counts, NULL counts per partition

### Partition Pruning

When executing a query, Snowflake uses partition metadata to skip (prune) partitions that don't contain relevant data:

```sql
-- Query with date filter
select *
from {{ ref('fct_wallet_transactions') }}
where transaction_date_et = '2025-10-07'
```

**Without clustering**: May scan 1,000+ partitions
**With clustering on transaction_date_et**: Scans 5-10 partitions
**Result**: 100x faster query execution

## Clustering Keys - When to Use

### Decision Matrix

| Table Characteristic | Use Clustering? | Recommended Key |
|---------------------|-----------------|-----------------|
| **Size < 1 GB** | ❌ No | N/A - overhead not worth it |
| **Size > 1 GB, frequent time filters** | ✅ Yes | Date/timestamp column |
| **Size > 10 GB, high cardinality ID lookups** | ✅ Yes | ID column + date |
| **Append-only fact table** | ✅ Yes | Date column |
| **Frequently updated dimension** | ⚠️ Maybe | Depends on query patterns |
| **Small dimension (< 100K rows)** | ❌ No | Full scan is fast enough |

### Project-Specific Guidance

**Always Cluster**:
- `fct_wallet_transactions` - By `transaction_date_et` (100M+ rows, time-based queries)
- `fct_contest_entries` - By `entry_date_et` (50M+ rows, time-based queries)
- `stg_segment__web_events` - By `event_date_et` (500M+ rows, high-volume)

**Consider Clustering**:
- `fct_user_sessions` - By `session_date_et` if > 10M rows
- `fct_partner_transactions` - By `transaction_date_et` if > 5M rows

**Don't Cluster**:
- `dim_user` - Small dimension, full scan is fast
- `dim_contest` - Lookup table, not large enough
- `stg_splash_production__users` - Staging is 1:1 with source, queries are simple

## Defining Clustering Keys in dbt

### Single Column Clustering

```sql
-- models/dwh/core/finance/fct_wallet_transactions.sql

{{
    config(
        materialized='incremental',
        unique_key='transaction_key',
        cluster_by=['transaction_date_et'],  -- Single column clustering
        tags=[
            'group:finance',
            'layer:core',
            'pattern:fact_transaction',
            'business:finance',
            'critical:true',
            'volume:high'
        ]
    )
}}

select
    {{ dbt_utils.generate_surrogate_key(['transaction_id']) }} as transaction_key,
    user_id,
    transaction_id,
    transaction_type,
    amount_cents,
    transaction_timestamp_utc,
    {{ timezone_fields(
        utc_timestamp_column='transaction_timestamp_utc',
        date_et_column='transaction_date_et',
        timestamp_et_column='transaction_timestamp_et'
    ) }},
    current_timestamp() as transformed_at
from {{ ref('stg_splash_wallet__transactions') }}

{% if is_incremental() %}
where transaction_timestamp_utc > (select max(transaction_timestamp_utc) from {{ this }})
{% endif %}
```

### Multi-Column Clustering

```sql
-- models/dwh/core/contests/fct_contest_entries.sql

{{
    config(
        materialized='incremental',
        unique_key='entry_key',
        cluster_by=['entry_date_et', 'contest_id'],  -- Multi-column clustering
        tags=[
            'group:contests',
            'layer:core',
            'pattern:fact_transaction',
            'business:contests',
            'critical:true',
            'volume:high'
        ]
    )
}}

-- Queries filtering by both entry_date_et AND contest_id benefit most
```

**Column Order Matters**:
1. **First column**: Most selective filter (usually date)
2. **Second column**: Next most common filter
3. **Limit to 3-4 columns**: More columns = higher maintenance cost

### Expression-Based Clustering

```sql
-- Cluster by derived column
{{
    config(
        cluster_by=['date(event_timestamp_et)']  -- Cluster by date part only
    )
}}
```

## Monitoring Clustering Health

### Check Clustering Information

```sql
-- Check clustering statistics for a table
select system$clustering_information('fct_wallet_transactions', '(transaction_date_et)');
```

**Example Output**:
```json
{
  "cluster_by_keys": "(TRANSACTION_DATE_ET)",
  "total_partition_count": 2500,
  "total_constant_partition_count": 200,
  "average_overlaps": 1.8,
  "average_depth": 2.3,
  "partition_depth_histogram": {
    "00000": 0,
    "00001": 1500,
    "00002": 700,
    "00003": 250,
    "00004": 50
  }
}
```

### Key Metrics Explained

**average_depth**:
- **1.0**: Perfect clustering (each partition contains unique range of values)
- **2-3**: Good clustering (acceptable for most use cases)
- **4-6**: Moderate clustering (consider reclustering)
- **>6**: Poor clustering (reclustering recommended)

**average_overlaps**:
- Number of partitions that contain the same clustering key value
- Lower is better (1.0 = no overlaps)
- High overlaps = more partitions scanned per query

**partition_depth_histogram**:
- Shows distribution of clustering depth across partitions
- Most partitions should be in depth 1-2 buckets

### Monitoring Query (Run Daily)

```sql
-- Create monitoring view for clustering health
-- models/dwh/marts/operations/mart_clustering_health.sql

{{
    config(
        materialized='table',
        tags=['group:operations', 'layer:marts', 'business:operations']
    )
}}

with table_list as (

    select
        'FINANCE' as domain,
        'FCT_WALLET_TRANSACTIONS' as table_name,
        '(TRANSACTION_DATE_ET)' as cluster_key
    union all
    select
        'CONTESTS' as domain,
        'FCT_CONTEST_ENTRIES' as table_name,
        '(ENTRY_DATE_ET)' as cluster_key
    union all
    select
        'ANALYTICS' as domain,
        'STG_SEGMENT__WEB_EVENTS' as table_name,
        '(EVENT_DATE_ET)' as cluster_key

),

clustering_stats as (

    select
        domain,
        table_name,
        cluster_key,
        parse_json(system$clustering_information(table_name, cluster_key)) as clustering_info
    from table_list

)

select
    domain,
    table_name,
    cluster_key,
    clustering_info:average_depth::float as average_depth,
    clustering_info:average_overlaps::float as average_overlaps,
    clustering_info:total_partition_count::int as total_partitions,
    case
        when clustering_info:average_depth::float <= 2.0 then '✅ Excellent'
        when clustering_info:average_depth::float <= 4.0 then '✓ Good'
        when clustering_info:average_depth::float <= 6.0 then '⚠️ Fair'
        else '❌ Poor - Recluster Needed'
    end as clustering_health,
    current_timestamp() as measured_at
from clustering_stats
order by average_depth desc
```

## Automatic vs Manual Reclustering

### Automatic Reclustering (Recommended)

Snowflake automatically reclusters tables in the background when clustering depth degrades:

```sql
-- Enable automatic reclustering (default for tables with cluster keys)
alter table fct_wallet_transactions resume recluster;
```

**Automatic reclustering triggers when**:
- Clustering depth increases beyond thresholds
- Table has cluster key defined
- Reclustering is not suspended

### Manual Reclustering

```sql
-- Suspend automatic reclustering
alter table fct_wallet_transactions suspend recluster;

-- Manually trigger reclustering
alter table fct_wallet_transactions recluster;

-- Resume automatic reclustering
alter table fct_wallet_transactions resume recluster;
```

**When to use manual reclustering**:
- Large data load just completed (force immediate reclustering)
- Testing clustering effectiveness
- Cost optimization (schedule during off-hours)

## Clustering Cost Optimization

### Cost Considerations

**Reclustering Credits**:
- Automatic reclustering consumes compute credits
- Cost = warehouse size × time spent reclustering
- Larger tables = higher reclustering cost

**Optimization Strategies**:

1. **Cluster only large, frequently-queried tables** (> 1 GB)
2. **Use appropriate warehouse for reclustering**:
```sql
alter table fct_wallet_transactions
    set recluster_warehouse = 'COMPUTE_WH_MEDIUM';  -- Dedicated warehouse
```

3. **Monitor reclustering costs**:
```sql
-- Query reclustering history
select
    table_name,
    start_time,
    end_time,
    credits_used,
    rows_reclustered
from table(information_schema.automatic_clustering_history(
    date_range_start => dateadd('day', -7, current_date)
))
order by credits_used desc;
```

4. **Suspend reclustering for rarely-queried tables**:
```sql
-- If table is only queried monthly, suspend reclustering
alter table fct_historical_contests suspend recluster;
```

## Search Optimization Service

### What is Search Optimization?

Search Optimization Service creates a **search access path** (like an index) for:
- **Equality filters** (`WHERE column = value`)
- **IN filters** (`WHERE column IN (value1, value2)`)
- **SUBSTRING/LIKE filters** (`WHERE column LIKE '%pattern%'`)
- **VARIANT/JSON property filters** (`WHERE variant_column:property = value`)

### When to Use Search Optimization

| Use Case | Use Search Optimization? | Why |
|----------|-------------------------|-----|
| **Point lookups** (WHERE user_id = 123) | ✅ Yes | Dramatically faster |
| **Small result sets** (LIMIT 10) from large table | ✅ Yes | Avoids full scan |
| **VARIANT column queries** | ✅ Yes | Optimizes JSON property access |
| **Substring searches** | ✅ Yes | LIKE '%pattern%' becomes fast |
| **Time-range queries** | ❌ No | Use clustering instead |
| **Full table scans** | ❌ No | No benefit |
| **Small tables** (< 100K rows) | ❌ No | Overhead not worth it |

### Enabling Search Optimization

```sql
-- Enable on specific columns
alter table dim_user
    add search optimization on equality(user_id, email);

-- Enable on VARIANT column properties
alter table stg_segment__web_events
    add search optimization on equality(event_properties:contest_id);

-- Enable on all supported columns (use cautiously)
alter table fct_wallet_transactions
    add search optimization;

-- Check search optimization status
show tables like 'DIM_USER';
-- Look for SEARCH_OPTIMIZATION column
```

### Search Optimization in dbt

**Not directly supported in dbt config** - Must enable via Snowflake SQL post-deployment:

```sql
-- Post-deployment script (run manually or via CI/CD)
-- scripts/snowflake/enable_search_optimization.sql

-- User dimension - for point lookups
alter table {{ target.database }}.SHARED.DIM_USER
    add search optimization on equality(user_id, email);

-- Contest dimension - for contest_id lookups
alter table {{ target.database }}.CONTESTS.DIM_CONTEST
    add search optimization on equality(contest_id);

-- Segment events - for JSON property lookups
alter table {{ target.database }}.ANALYTICS_STAGING.STG_SEGMENT__WEB_EVENTS
    add search optimization on equality(event_properties:contest_id, event_properties:user_id);
```

### Monitoring Search Optimization

```sql
-- Check search optimization maintenance
select
    table_name,
    search_optimization_progress,
    search_optimization_bytes
from information_schema.tables
where table_catalog = current_database()
    and search_optimization = 'ON'
order by search_optimization_bytes desc;

-- Check search optimization benefit
select
    query_id,
    query_text,
    execution_time,
    partitions_scanned,
    partitions_total
from table(information_schema.query_history())
where query_text ilike '%dim_user%'
    and query_text ilike '%user_id =%'
order by start_time desc
limit 10;
```

## Practical Examples

### Example 1: Large Fact Table Clustering

```sql
-- models/dwh/core/finance/fct_wallet_transactions.sql

{{
    config(
        materialized='incremental',
        unique_key='transaction_key',
        cluster_by=['transaction_date_et'],  -- Cluster by date for time-based queries
        tags=[
            'group:finance',
            'layer:core',
            'pattern:fact_transaction',
            'business:finance',
            'critical:true',
            'volume:high'
        ]
    )
}}

-- Table size: 100M+ rows, 50+ GB
-- Query pattern: 95% of queries filter by transaction_date_et
-- Clustering benefit: 50x faster queries (from 2 min to 2-3 sec)
```

**Before clustering**:
```
Partitions Scanned: 2,500 of 2,500 (100%)
Bytes Scanned: 52 GB
Execution Time: 2m 15s
```

**After clustering**:
```
Partitions Scanned: 50 of 2,500 (2%)
Bytes Scanned: 1.2 GB
Execution Time: 2.8s
```

### Example 2: Segment Events with Multi-Column Clustering

```sql
-- models/dwh/staging/analytics/stg_segment__web_events.sql

{{
    config(
        materialized='incremental',
        unique_key='event_id',
        cluster_by=['event_date_et', 'event_name'],  -- Date + event type
        tags=[
            'group:analytics',
            'layer:staging',
            'source:segment',
            'volume:high',
            'critical:true'
        ]
    )
}}

-- Table size: 500M+ rows, 800+ GB
-- Query pattern: Filter by date AND event_name (e.g., 'Contest Entry Submitted')
-- Clustering benefit: 100x faster event-specific queries
```

### Example 3: User Dimension with Search Optimization

```sql
-- Enable search optimization for user lookups
alter table PROD.SHARED.DIM_USER
    add search optimization on equality(user_id, email);

-- Query benefit
select *
from {{ ref('dim_user') }}
where user_id = 123456;  -- Point lookup
-- Before: 5 seconds (full scan of 10M rows)
-- After: 0.2 seconds (search optimization index)
```

## Best Practices Summary

### Clustering Keys

- [ ] **Only cluster large tables** (> 1 GB)
- [ ] **Use 1-3 columns** (more = higher maintenance cost)
- [ ] **First column = most selective** (typically date)
- [ ] **Monitor clustering health** (average_depth < 4.0)
- [ ] **Let automatic reclustering run** (don't suspend unless needed)
- [ ] **Cluster on query-filtered columns** (not random columns)

### Search Optimization

- [ ] **Enable for point lookups** on large tables
- [ ] **Use for VARIANT property queries** (Segment events)
- [ ] **Monitor optimization progress** (can take hours/days to build)
- [ ] **Check query performance improvement** (before/after comparison)
- [ ] **Consider cost** (additional storage and maintenance)

### Anti-Patterns to Avoid

❌ **Don't cluster small tables** (< 1 GB)
❌ **Don't cluster on high-cardinality columns only** (e.g., transaction_id)
❌ **Don't cluster dimensions** (unless very large > 10M rows)
❌ **Don't use 5+ clustering columns** (diminishing returns)
❌ **Don't enable search optimization on all tables** (expensive)

## Decision Tree

```
Is table > 1 GB?
├─ No → Don't cluster
└─ Yes → Are queries filtered by date/time?
    ├─ Yes → Cluster by date column
    │   └─ Are queries also filtered by another column?
    │       ├─ Yes → Add second clustering column
    │       └─ No → Single-column clustering
    └─ No → Are there frequent point lookups (WHERE id = value)?
        ├─ Yes → Consider search optimization
        └─ No → Monitor query patterns, may not need optimization
```

## Additional Resources

**Snowflake Documentation**:
- [Clustering Keys](https://docs.snowflake.com/en/user-guide/tables-clustering-keys.html)
- [Search Optimization Service](https://docs.snowflake.com/en/user-guide/search-optimization-service.html)
- [Micro-Partitions](https://docs.snowflake.com/en/user-guide/tables-clustering-micropartitions.html)

**Project Integration**:
- All large fact tables (> 1 GB) should have clustering keys
- Monitor clustering health in `mart_clustering_health`
- Enable search optimization post-deployment for dimensions

---

**Last Updated**: 2025-10-07
**Agent**: snowflake-sql-expert
**Knowledge Category**: Patterns