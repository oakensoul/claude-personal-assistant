---
title: "Window Function Optimization Patterns"
description: "Best practices for window functions in Snowflake including QUALIFY usage, partition optimization, and performance tuning"
category: "patterns"
tags:
  - window-functions
  - qualify-clause
  - performance-optimization
  - row-number
  - rank
last_updated: "2025-10-07"
---

# Window Function Optimization Patterns

Window functions are powerful but can be expensive. This guide covers optimization patterns specific to Snowflake and the dbt-splash-prod-v2 project.

## QUALIFY Clause - Snowflake's Best Feature

QUALIFY is Snowflake-specific syntax that filters window function results **without requiring a subquery**. This is more efficient and dramatically improves readability.

### Basic QUALIFY Pattern

**❌ TRADITIONAL (Less Efficient):**
```sql
-- Subquery required to filter window function results
select
    user_id,
    contest_id,
    entry_date,
    entry_fee
from (
    select
        user_id,
        contest_id,
        entry_date,
        entry_fee,
        row_number() over (partition by user_id order by entry_date) as rn
    from {{ ref('fct_contest_entries') }}
)
where rn = 1
```

**✅ OPTIMIZED (QUALIFY):**
```sql
-- Direct filtering with QUALIFY - cleaner and more efficient
select
    user_id,
    contest_id,
    entry_date,
    entry_fee
from {{ ref('fct_contest_entries') }}
qualify row_number() over (partition by user_id order by entry_date) = 1
```

**Benefits:**
- No subquery nesting reduces query complexity
- Snowflake optimizes QUALIFY execution internally
- Clearer intent (filtering window results, not general WHERE)
- Easier to maintain and understand

### QUALIFY with Multiple Conditions

```sql
-- Find first and last entry per user within date range
select
    user_id,
    contest_id,
    entry_date,
    entry_fee,
    row_number() over (partition by user_id order by entry_date) as entry_sequence
from {{ ref('fct_contest_entries') }}
where entry_date >= '2025-01-01'
qualify entry_sequence in (1, (max(entry_sequence) over (partition by user_id)))
```

### QUALIFY with Complex Logic

```sql
-- Get users' most recent high-value entry (>$50)
select
    user_id,
    contest_id,
    entry_date,
    entry_fee
from {{ ref('fct_contest_entries') }}
where entry_fee > 50
qualify row_number() over (
    partition by user_id
    order by entry_date desc, entry_fee desc
) = 1
```

## Common Window Function Patterns

### 1. Row Number - Sequential Ordering

**Use Case:** Rank items within a group with no ties

```sql
-- Assign sequence number to user entries
select
    user_id,
    contest_id,
    entry_date,
    row_number() over (
        partition by user_id
        order by entry_date
    ) as entry_sequence
from {{ ref('fct_contest_entries') }}
```

**Project Example: First Entry Detection**
```sql
-- Tag first-time contest entries (common BI metric)
with entry_sequence as (

    select
        entry_id,
        user_id,
        contest_id,
        entry_date,
        entry_fee,
        row_number() over (
            partition by user_id
            order by entry_date
        ) as entry_number
    from {{ ref('fct_contest_entries') }}

),

final as (

    select
        *,
        case
            when entry_number = 1
                then 1
            else 0
        end as is_first_entry
    from entry_sequence

)

select * from final
```

### 2. Rank vs. Dense_Rank - Handling Ties

**RANK:** Leaves gaps after ties (1, 2, 2, 4)
**DENSE_RANK:** No gaps after ties (1, 2, 2, 3)

```sql
-- Compare rank vs dense_rank behavior
select
    user_id,
    contest_id,
    entry_fee,
    rank() over (partition by user_id order by entry_fee desc) as rank_with_gaps,
    dense_rank() over (partition by user_id order by entry_fee desc) as rank_no_gaps
from {{ ref('fct_contest_entries') }}
qualify rank_with_gaps <= 3  -- Top 3 entries (may return more than 3 if ties)
```

**When to Use:**
- **RANK:** Leaderboards, competitive rankings (ties should "count")
- **DENSE_RANK:** Categorical groupings (no gaps preferred)

### 3. Lead/Lag - Access Adjacent Rows

**Use Case:** Calculate time between events, deltas, session gaps

```sql
-- Calculate days between consecutive entries per user
with entry_timeline as (

    select
        user_id,
        entry_id,
        entry_date,
        lag(entry_date) over (
            partition by user_id
            order by entry_date
        ) as previous_entry_date
    from {{ ref('fct_contest_entries') }}

),

final as (

    select
        user_id,
        entry_id,
        entry_date,
        previous_entry_date,
        datediff(
            day,
            previous_entry_date,
            entry_date
        ) as days_since_last_entry
    from entry_timeline

)

select * from final
```

**Project Example: User Retention Metrics**
```sql
-- Identify users who returned within 7 days
select
    user_id,
    entry_date,
    lead(entry_date) over (partition by user_id order by entry_date) as next_entry_date,
    datediff(day, entry_date, next_entry_date) as days_to_next_entry
from {{ ref('fct_contest_entries') }}
qualify days_to_next_entry <= 7  -- Returned within 7 days
```

### 4. Cumulative Aggregations

**Use Case:** Running totals, cumulative counts, moving averages

```sql
-- Calculate cumulative spend per user over time
select
    user_id,
    entry_date,
    entry_fee,
    sum(entry_fee) over (
        partition by user_id
        order by entry_date
        rows between unbounded preceding and current row
    ) as cumulative_spend,
    count(*) over (
        partition by user_id
        order by entry_date
        rows between unbounded preceding and current row
    ) as cumulative_entries
from {{ ref('fct_contest_entries') }}
```

**Moving Average Pattern:**
```sql
-- 7-day moving average of daily entry fees
select
    user_id,
    entry_date,
    entry_fee,
    avg(entry_fee) over (
        partition by user_id
        order by entry_date
        rows between 6 preceding and current row
    ) as avg_entry_fee_7d
from {{ ref('fct_contest_entries') }}
```

## Performance Optimization Techniques

### 1. Partition Size Matters

**❌ ANTI-PATTERN: Tiny partitions (over-partitioning)**
```sql
-- Creates millions of single-row partitions (slow!)
select
    entry_id,  -- Unique per row!
    row_number() over (partition by entry_id order by entry_date) as rn
from {{ ref('fct_contest_entries') }}
```

**✅ OPTIMIZED: Logical partition sizes**
```sql
-- Reasonable partition sizes (hundreds to thousands of rows per user)
select
    user_id,
    entry_id,
    row_number() over (partition by user_id order by entry_date) as rn
from {{ ref('fct_contest_entries') }}
```

**Guideline:** Partition sizes of 100-10,000 rows are optimal. Avoid partitions with <10 or >100,000 rows.

### 2. Pre-Filter Before Window Functions

```sql
-- ✅ OPTIMIZED: Filter BEFORE window function
with recent_entries as (

    select *
    from {{ ref('fct_contest_entries') }}
    where entry_date >= dateadd(month, -6, current_date())  -- Reduce data volume first

)

select
    user_id,
    entry_date,
    row_number() over (partition by user_id order by entry_date) as entry_sequence
from recent_entries
```

### 3. Avoid Multiple Window Functions with Different Partitions

**❌ LESS EFFICIENT: Multiple window functions, different partitions**
```sql
select
    user_id,
    contest_id,
    row_number() over (partition by user_id order by entry_date) as user_seq,
    row_number() over (partition by contest_id order by entry_date) as contest_seq,
    row_number() over (partition by user_id, contest_id order by entry_date) as combined_seq
from {{ ref('fct_contest_entries') }}
```

**✅ OPTIMIZED: Separate CTEs if partitions differ significantly**
```sql
with user_sequences as (

    select
        entry_id,
        user_id,
        row_number() over (partition by user_id order by entry_date) as user_seq
    from {{ ref('fct_contest_entries') }}

),

contest_sequences as (

    select
        entry_id,
        contest_id,
        row_number() over (partition by contest_id order by entry_date) as contest_seq
    from {{ ref('fct_contest_entries') }}

)

select
    e.*,
    u.user_seq,
    c.contest_seq
from {{ ref('fct_contest_entries') }} as e
left join user_sequences as u using (entry_id)
left join contest_sequences as c using (entry_id)
```

### 4. CLUSTER BY for Window Function Columns

```sql
-- models/dwh/core/finance/fct_wallet_transactions.sql
{{
    config(
        materialized='incremental',
        unique_key='transaction_key',
        cluster_by=['user_id', 'transaction_date'],  -- Aligns with window partitioning
        tags=['group:finance', 'layer:core', 'pattern:fact_transaction']
    )
}}

-- Window function benefits from clustering on user_id
select
    user_id,
    transaction_date,
    amount,
    row_number() over (partition by user_id order by transaction_date) as txn_sequence
from source_data
```

## QUALIFY Advanced Patterns

### Pattern 1: Top N per Group

```sql
-- Top 3 highest entry fees per user
select
    user_id,
    contest_id,
    entry_date,
    entry_fee
from {{ ref('fct_contest_entries') }}
qualify row_number() over (
    partition by user_id
    order by entry_fee desc
) <= 3
```

### Pattern 2: First and Last in Group

```sql
-- First and last entry per user per month
select
    user_id,
    date_trunc('month', entry_date) as entry_month,
    entry_date,
    entry_fee
from {{ ref('fct_contest_entries') }}
qualify row_number() over (
    partition by user_id, date_trunc('month', entry_date)
    order by entry_date
) = 1
or row_number() over (
    partition by user_id, date_trunc('month', entry_date)
    order by entry_date desc
) = 1
```

### Pattern 3: Deduplication

```sql
-- Remove duplicate entries (keep most recent)
select
    user_id,
    contest_id,
    entry_date,
    entry_fee
from {{ ref('fct_contest_entries') }}
qualify row_number() over (
    partition by user_id, contest_id
    order by entry_date desc
) = 1
```

### Pattern 4: Running Calculations with Filtering

```sql
-- Users with cumulative spend > $500 at any point
select
    user_id,
    entry_date,
    entry_fee,
    sum(entry_fee) over (
        partition by user_id
        order by entry_date
        rows between unbounded preceding and current row
    ) as cumulative_spend
from {{ ref('fct_contest_entries') }}
qualify cumulative_spend > 500
```

## Project-Specific Examples

### Example 1: User Lifecycle Stages
```sql
-- Categorize users by entry frequency
with user_entry_metrics as (

    select
        user_id,
        count(*) as total_entries,
        min(entry_date) as first_entry_date,
        max(entry_date) as last_entry_date,
        datediff(day, min(entry_date), max(entry_date)) as days_active
    from {{ ref('fct_contest_entries') }}
    group by user_id

),

final as (

    select
        user_id,
        total_entries,
        first_entry_date,
        last_entry_date,
        days_active,
        case
            when total_entries >= 100 then 'Power User'
            when total_entries >= 20 and days_active >= 30 then 'Active User'
            when total_entries >= 5 then 'Engaged User'
            else 'New User'
        end as user_lifecycle_stage
    from user_entry_metrics

)

select * from final
```

### Example 2: Contest Performance Ranking
```sql
-- Rank contests by total handle, partition by sport
select
    contest_id,
    contest_name,
    contest_sport,
    total_handle,
    rank() over (
        partition by contest_sport
        order by total_handle desc
    ) as sport_rank,
    percent_rank() over (
        partition by contest_sport
        order by total_handle desc
    ) as sport_percentile
from {{ ref('fct_contest_summary') }}
qualify sport_rank <= 10  -- Top 10 per sport
```

## Common Pitfalls

### Pitfall 1: QUALIFY with Aggregates (Doesn't Work)
```sql
-- ❌ WRONG: QUALIFY cannot reference aggregates directly
select
    user_id,
    count(*) as entry_count
from {{ ref('fct_contest_entries') }}
group by user_id
qualify entry_count > 10  -- ERROR: Column not found

-- ✅ CORRECT: Use HAVING for aggregate filtering
select
    user_id,
    count(*) as entry_count
from {{ ref('fct_contest_entries') }}
group by user_id
having count(*) > 10
```

### Pitfall 2: Window Function in WHERE Clause
```sql
-- ❌ WRONG: Window functions not allowed in WHERE
select
    user_id,
    entry_date
from {{ ref('fct_contest_entries') }}
where row_number() over (partition by user_id order by entry_date) = 1  -- ERROR

-- ✅ CORRECT: Use QUALIFY
select
    user_id,
    entry_date
from {{ ref('fct_contest_entries') }}
qualify row_number() over (partition by user_id order by entry_date) = 1
```

### Pitfall 3: Inefficient QUALIFY Logic
```sql
-- ❌ LESS EFFICIENT: Complex QUALIFY logic
select *
from {{ ref('fct_contest_entries') }}
qualify row_number() over (partition by user_id order by entry_date) = 1
    and dense_rank() over (partition by contest_id order by entry_fee desc) <= 5

-- ✅ OPTIMIZED: Separate CTEs for clarity and potential performance
with first_entries as (
    select *
    from {{ ref('fct_contest_entries') }}
    qualify row_number() over (partition by user_id order by entry_date) = 1
),

top_fees as (
    select *
    from first_entries
    qualify dense_rank() over (partition by contest_id order by entry_fee desc) <= 5
)

select * from top_fees
```

## Summary

**Key Takeaways:**
1. **Always use QUALIFY** instead of subqueries for window function filtering
2. **Partition size matters** - aim for 100-10,000 rows per partition
3. **Pre-filter data** before applying window functions to reduce compute
4. **Cluster tables** on window partition columns for large tables
5. **Use LEAD/LAG** for sequential analysis (time between events, deltas)
6. **ROW_NUMBER for deduplication**, RANK for competitive ordering

**Next Steps:**
- Review core-concepts/snowflake-query-optimization-fundamentals.md for clustering
- Check decisions/performance-anti-patterns.md for common mistakes
- Apply QUALIFY patterns in dbt core and marts layer models