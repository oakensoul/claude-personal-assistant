---

title: "Performance Anti-Patterns to Avoid"
description: "Common SQL anti-patterns that hurt Snowflake performance and how to fix them"
category: "decisions"
tags:

  - anti-patterns
  - performance-optimization
  - best-practices
  - snowflake
  - sql-optimization

last_updated: "2025-10-07"

---

# Performance Anti-Patterns to Avoid

This document catalogs common SQL anti-patterns observed in data warehouse development and provides optimized alternatives specific to Snowflake and the dbt-splash-prod-v2 project.

## Anti-Pattern 1: SELECT * in Production Models

### The Problem
Using `SELECT *` in production dbt models is a major performance anti-pattern:

**❌ ANTI-PATTERN:**

```sql


-- Reads all columns, even those not needed downstream

select * from {{ ref('stg_splash_production__contest_entries') }}

```

**Why It's Bad:**

- Snowflake reads ALL columns from storage (expensive)
- Breaks downstream models when columns are added/removed upstream
- Wastes compute reading unused data
- Makes query intent unclear

**✅ CORRECT:**

```sql


-- Explicit column selection - only read what you need

select
    entry_id,
    user_id,
    contest_id,
    entry_date,
    entry_fee,
    entry_status
from {{ ref('stg_splash_production__contest_entries') }}

```

**When SELECT * Is Acceptable:**

- Temporary exploration in worksheets/analyses
- Initial CTE grabbing all columns for subsequent filtering: `with base as (select * from source) select col1, col2 from base`

### Project Rule

**All production dbt models MUST use explicit column selection in the final SELECT.**

---

## Anti-Pattern 2: Implicit Data Type Conversions

### The Problem
Snowflake performs implicit type conversions which can hurt performance:

**❌ ANTI-PATTERN:**

```sql


-- Implicit conversion: entry_fee (NUMBER) to VARCHAR for comparison

select
    user_id,
    entry_fee
from {{ ref('fct_contest_entries') }}
where entry_fee::varchar = '50.00'  -- Converts NUMBER to VARCHAR!

```

**Why It's Bad:**

- Prevents partition pruning
- Disables index usage
- Slower comparisons (string vs numeric)

**✅ CORRECT:**

```sql


-- Explicit numeric comparison

select
    user_id,
    entry_fee
from {{ ref('fct_contest_entries') }}
where entry_fee = 50.00  -- Native NUMBER comparison

```

### Common Conversion Pitfalls

**Date/Timestamp Comparisons:**

```sql


-- ❌ ANTI-PATTERN: String comparison

where entry_date = '2025-01-01'  -- Implicit conversion

-- ✅ CORRECT: Explicit date casting

where entry_date = '2025-01-01'::date

-- OR

where entry_date::date = '2025-01-01'

```

**NULL Handling in UNION:**

```sql


-- ❌ ANTI-PATTERN: Ambiguous NULL type

select user_id, amount, NULL as category from table1
union all
select user_id, amount, category from table2  -- What type is category?

-- ✅ CORRECT: Explicit NULL typing

select user_id, amount, NULL::varchar as category from table1
union all
select user_id, amount, category::varchar from table2

```

---

## Anti-Pattern 3: Inefficient JOIN Patterns

### Problem 3A: Large Table First in JOIN

**❌ ANTI-PATTERN:**

```sql


-- Fact table first (millions of rows)

select
    e.entry_id,
    e.user_id,
    u.user_email,
    u.user_state
from {{ ref('fct_contest_entries') }} as e  -- 10M rows
left join {{ ref('dim_user') }} as u         -- 100K rows
    on e.user_id = u.user_id

```

**✅ OPTIMIZED:**

```sql


-- Dimension first when possible (build hash table on small table)

select
    e.entry_id,
    e.user_id,
    u.user_email,
    u.user_state
from {{ ref('dim_user') }} as u              -- 100K rows (small hash table)
right join {{ ref('fct_contest_entries') }} as e  -- 10M rows
    on u.user_id = e.user_id

```

**Note:** Modern Snowflake query optimizer often handles this automatically, but explicit ordering can help with complex queries.

### Problem 3B: Multiple Joins Without Filtering

**❌ ANTI-PATTERN:**

```sql


-- No WHERE clause - joins entire tables

select
    e.entry_id,
    u.user_email,
    c.contest_name
from {{ ref('fct_contest_entries') }} as e
left join {{ ref('dim_user') }} as u on e.user_id = u.user_id
left join {{ ref('dim_contest') }} as c on e.contest_id = c.contest_id

```

**✅ OPTIMIZED:**

```sql


-- Pre-filter before joining

with recent_entries as (

    select *
    from {{ ref('fct_contest_entries') }}
    where entry_date >= dateadd(month, -3, current_date())  -- Reduce data volume

)

select
    e.entry_id,
    u.user_email,
    c.contest_name
from recent_entries as e
left join {{ ref('dim_user') }} as u on e.user_id = u.user_id
left join {{ ref('dim_contest') }} as c on e.contest_id = c.contest_id

```

### Problem 3C: JOIN on Functions/Expressions

**❌ ANTI-PATTERN:**

```sql


-- JOIN on transformed columns prevents optimization

select
    e.entry_id,
    u.user_email
from {{ ref('fct_contest_entries') }} as e
left join {{ ref('dim_user') }} as u
    on lower(e.user_email) = lower(u.user_email)  -- Function on both sides!

```

**✅ OPTIMIZED:**

```sql


-- Normalize in staging layer, join on clean keys
-- In staging model:

select
    user_id,
    lower(user_email) as user_email_normalized
from source_table

-- In downstream model:

select
    e.entry_id,
    u.user_email
from {{ ref('fct_contest_entries') }} as e
left join {{ ref('dim_user') }} as u
    on e.user_id = u.user_id  -- Direct key join

```

---

## Anti-Pattern 4: Suboptimal Subquery Usage

### Problem 4A: Correlated Subqueries

**❌ ANTI-PATTERN:**

```sql


-- Correlated subquery executes once PER ROW (expensive!)

select
    user_id,
    entry_date,
    (
        select count(*)
        from {{ ref('fct_contest_entries') }} as e2
        where e2.user_id = e1.user_id
            and e2.entry_date < e1.entry_date
    ) as prior_entries
from {{ ref('fct_contest_entries') }} as e1

```

**✅ OPTIMIZED:**

```sql


-- Window function - single pass through data

select
    user_id,
    entry_date,
    row_number() over (
        partition by user_id
        order by entry_date
    ) - 1 as prior_entries
from {{ ref('fct_contest_entries') }}

```

### Problem 4B: Scalar Subqueries in SELECT

**❌ ANTI-PATTERN:**

```sql

select
    user_id,
    entry_date,
    (select max(entry_date) from {{ ref('fct_contest_entries') }}) as latest_entry_date
from {{ ref('fct_contest_entries') }}

```

**✅ OPTIMIZED:**

```sql


-- Calculate once in CTE, cross join or use window function

with max_date as (
    select max(entry_date) as latest_entry_date
    from {{ ref('fct_contest_entries') }}
)

select
    e.user_id,
    e.entry_date,
    m.latest_entry_date
from {{ ref('fct_contest_entries') }} as e
cross join max_date as m

```

---

## Anti-Pattern 5: Inefficient Aggregations

### Problem 5A: Multiple Aggregation Passes

**❌ ANTI-PATTERN:**

```sql


-- Multiple aggregation queries combined with UNION

select 'total_entries' as metric, count(*) as value
from {{ ref('fct_contest_entries') }}
union all
select 'total_revenue' as metric, sum(entry_fee) as value
from {{ ref('fct_contest_entries') }}
union all
select 'avg_entry_fee' as metric, avg(entry_fee) as value
from {{ ref('fct_contest_entries') }}

```

**✅ OPTIMIZED:**

```sql


-- Single pass aggregation, then unpivot

with aggregated as (
    select
        count(*) as total_entries,
        sum(entry_fee) as total_revenue,
        avg(entry_fee) as avg_entry_fee
    from {{ ref('fct_contest_entries') }}
)

select 'total_entries' as metric, total_entries as value from aggregated
union all
select 'total_revenue' as metric, total_revenue as value from aggregated
union all
select 'avg_entry_fee' as metric, avg_entry_fee as value from aggregated

```

### Problem 5B: Aggregating Before Filtering

**❌ ANTI-PATTERN:**

```sql


-- Aggregate all data, then filter aggregates

with user_totals as (
    select
        user_id,
        count(*) as total_entries,
        sum(entry_fee) as total_spend
    from {{ ref('fct_contest_entries') }}
    group by user_id
)

select * from user_totals
where total_entries > 10

```

**✅ OPTIMIZED:**

```sql


-- Filter BEFORE aggregating when possible

with eligible_users as (
    select user_id
    from {{ ref('fct_contest_entries') }}
    group by user_id
    having count(*) > 10  -- Filter during aggregation
),

user_totals as (
    select
        e.user_id,
        count(*) as total_entries,
        sum(e.entry_fee) as total_spend
    from {{ ref('fct_contest_entries') }} as e
    inner join eligible_users as u on e.user_id = u.user_id
    group by e.user_id
)

select * from user_totals

```

---

## Anti-Pattern 6: Inefficient DISTINCT Operations

### The Problem
`SELECT DISTINCT` forces expensive deduplication across all columns:

**❌ ANTI-PATTERN:**

```sql


-- DISTINCT on all columns (expensive!)

select distinct
    user_id,
    user_email,
    user_state,
    created_at,
    updated_at,
    ...  -- 20+ columns
from {{ ref('stg_splash_production__users') }}

```

**✅ OPTIMIZED:**

```sql


-- Use QUALIFY with ROW_NUMBER for controlled deduplication

select
    user_id,
    user_email,
    user_state,
    created_at,
    updated_at
from {{ ref('stg_splash_production__users') }}
qualify row_number() over (
    partition by user_id  -- Define deduplication key explicitly
    order by updated_at desc  -- Keep most recent
) = 1

```

**When DISTINCT Is Acceptable:**

- Small dimension tables with few columns
- Exploratory analysis in worksheets
- Simple deduplication on 1-2 columns

---

## Anti-Pattern 7: UNION vs. UNION ALL

### The Problem
`UNION` performs implicit `DISTINCT`, which is expensive:

**❌ ANTI-PATTERN:**

```sql


-- UNION performs automatic deduplication (expensive!)

select user_id, entry_date from {{ ref('fct_contest_entries_2024') }}
union
select user_id, entry_date from {{ ref('fct_contest_entries_2025') }}

```

**✅ OPTIMIZED:**

```sql


-- Use UNION ALL if duplicates are impossible or acceptable

select user_id, entry_date from {{ ref('fct_contest_entries_2024') }}
union all  -- No deduplication overhead
select user_id, entry_date from {{ ref('fct_contest_entries_2025') }}

-- If deduplication is required, make it explicit:

select distinct user_id, entry_date from (
    select user_id, entry_date from {{ ref('fct_contest_entries_2024') }}
    union all
    select user_id, entry_date from {{ ref('fct_contest_entries_2025') }}
)

```

**Project Rule:**

**Default to UNION ALL unless you have a specific reason to deduplicate.**

---

## Anti-Pattern 8: Complex CASE Statements in GROUP BY

### The Problem

**❌ ANTI-PATTERN:**

```sql


-- Complex CASE in SELECT and GROUP BY (duplicated logic)

select
    case
        when entry_fee = 0 then 'Free'
        when entry_fee < 10 then 'Low'
        when entry_fee < 50 then 'Medium'
        else 'High'
    end as fee_tier,
    count(*) as entry_count
from {{ ref('fct_contest_entries') }}
group by
    case
        when entry_fee = 0 then 'Free'
        when entry_fee < 10 then 'Low'
        when entry_fee < 50 then 'Medium'
        else 'High'
    end

```

**✅ OPTIMIZED:**

```sql


-- Calculate in CTE, then aggregate

with categorized_entries as (

    select
        entry_id,
        case
            when entry_fee = 0 then 'Free'
            when entry_fee < 10 then 'Low'
            when entry_fee < 50 then 'Medium'
            else 'High'
        end as fee_tier
    from {{ ref('fct_contest_entries') }}

),

final as (

    select
        fee_tier,
        count(*) as entry_count
    from categorized_entries
    group by fee_tier

)

select * from final

```

---

## Anti-Pattern 9: Overuse of ILIKE for Case-Insensitive Matching

### The Problem

**❌ ANTI-PATTERN:**

```sql


-- ILIKE prevents index usage and is slower than exact match

select
    user_id,
    user_email
from {{ ref('dim_user') }}
where user_email ilike 'john@example.com'  -- ILIKE for exact match (unnecessary)

```

**✅ OPTIMIZED:**

```sql


-- Normalize in staging, use exact match downstream
-- Staging model:

select
    user_id,
    lower(user_email) as user_email
from source_table

-- Downstream query:

select
    user_id,
    user_email
from {{ ref('dim_user') }}
where user_email = 'john@example.com'  -- Exact match on normalized data

```

**When ILIKE Is Appropriate:**

- Pattern matching: `where status ilike 'REFUND%'`
- User-provided search inputs
- Ad-hoc analysis where normalization isn't feasible

---

## Anti-Pattern 10: Large IN Clauses

### The Problem

**❌ ANTI-PATTERN:**

```sql


-- IN clause with hundreds of values (hard to maintain, slow)

select *
from {{ ref('fct_contest_entries') }}
where contest_id in (1001, 1002, 1003, ..., 9999)  -- 500+ IDs

```

**✅ OPTIMIZED:**

```sql


-- Use temp table or CTE for large lists

with target_contests as (

    select contest_id
    from {{ ref('dim_contest') }}
    where contest_type = 'High Value'  -- Filter logic instead of hardcoded list

)

select e.*
from {{ ref('fct_contest_entries') }} as e
inner join target_contests as t on e.contest_id = t.contest_id

```

**Alternative: Use LATERAL FLATTEN for hardcoded lists:**

```sql

with contest_list as (
    select value::int as contest_id
    from table(flatten(input => parse_json('[1001, 1002, 1003, ...]')))
)

select e.*
from {{ ref('fct_contest_entries') }} as e
inner join contest_list as c on e.contest_id = c.contest_id

```

---

## Anti-Pattern 11: Unnecessary QUALIFY Complexity

### The Problem

**❌ ANTI-PATTERN:**

```sql


-- Overly complex QUALIFY logic (hard to debug)

select *
from {{ ref('fct_contest_entries') }}
qualify row_number() over (partition by user_id order by entry_date) = 1
    and dense_rank() over (partition by contest_id order by entry_fee desc) <= 5
    and percent_rank() over (partition by user_state order by entry_date desc) < 0.1

```

**✅ OPTIMIZED:**

```sql


-- Break into separate CTEs for clarity

with first_entries as (
    select *
    from {{ ref('fct_contest_entries') }}
    qualify row_number() over (partition by user_id order by entry_date) = 1
),

top_fees as (
    select *
    from first_entries
    qualify dense_rank() over (partition by contest_id order by entry_fee desc) <= 5
),

final as (
    select *
    from top_fees
    qualify percent_rank() over (partition by user_state order by entry_date desc) < 0.1
)

select * from final

```

---

## Summary: Anti-Pattern Quick Reference

| Anti-Pattern | Problem | Solution |
|--------------|---------|----------|
| SELECT * | Reads all columns | Explicit column selection |
| Implicit conversions | Slow comparisons, no pruning | Explicit casting, normalize in staging |
| Large table first | Inefficient hash table | Small table first when possible |
| Correlated subquery | Executes per row | Window functions or CTEs |
| Multiple aggregation passes | Scans table multiple times | Single aggregation + unpivot |
| DISTINCT on many columns | Expensive deduplication | QUALIFY with ROW_NUMBER |
| UNION instead of UNION ALL | Unnecessary deduplication | UNION ALL (default) |
| CASE in GROUP BY | Duplicated logic | CTE with calculated column |
| ILIKE for exact match | Slower than exact match | Normalize in staging, use = |
| Large IN clauses | Hard to maintain, slow | Temp table or CTE with JOIN |
| Complex QUALIFY | Hard to debug | Multiple CTEs with simple QUALIFY |

**Key Principle:**

**Optimize for readability first, then performance. Clear SQL is easier to optimize later.**

**Next Steps:**

- Review patterns/window-function-optimization.md for QUALIFY best practices
- Check core-concepts/snowflake-query-optimization-fundamentals.md for architecture
- Apply these patterns when writing dbt models in core and marts layers
