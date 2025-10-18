---
title: "MATCH_RECOGNIZE Pattern Matching Guide"
description: "Comprehensive guide to Snowflake's MATCH_RECOGNIZE for time-series pattern analysis in contests and user behavior data"
agent: "snowflake-sql-expert"
category: "patterns"
tags:
  - match-recognize
  - time-series
  - pattern-matching
  - contests
  - user-behavior
  - sequential-events
last_updated: "2025-10-07"
priority: "high"
use_cases:
  - "Contest winning/losing streaks"
  - "User engagement patterns"
  - "Transaction fraud detection"
  - "Session analysis"
---

# MATCH_RECOGNIZE Pattern Matching Guide

## Overview

`MATCH_RECOGNIZE` is a powerful Snowflake SQL clause for detecting patterns in sequential data. It's particularly valuable for time-series analysis in contests, user behavior tracking, and event stream processing.

**Key Use Cases in dbt-splash-prod-v2**:

- Contest performance patterns (winning streaks, losing streaks)
- User engagement sequences (signup → deposit → first contest)
- Wallet transaction patterns (rapid deposits, withdrawal sequences)
- Session analysis (multi-event user journeys)

## Basic Syntax Structure

```sql
SELECT *
FROM source_table
    MATCH_RECOGNIZE (
        PARTITION BY partition_columns      -- Group sequences
        ORDER BY sequence_column            -- Define order
        MEASURES                            -- Define output columns
            measure_definitions
        ONE ROW PER MATCH                   -- Or ALL ROWS PER MATCH
        AFTER MATCH SKIP TO NEXT ROW        -- Or other skip options
        PATTERN (pattern_definition)        -- Define the pattern
        DEFINE                              -- Define pattern variables
            variable_definitions
    )
```

## Core Components Explained

### 1. PARTITION BY

Groups rows into separate sequences for pattern matching:

```sql
PARTITION BY user_id  -- Each user analyzed independently
```

### 2. ORDER BY

Defines the sequence order (typically timestamp):

```sql
ORDER BY contest_entry_timestamp
```

### 3. MEASURES

Defines the output columns from the matched pattern:

```sql
MEASURES
    FIRST(contest_entry_timestamp) as streak_start_timestamp,
    LAST(contest_entry_timestamp) as streak_end_timestamp,
    COUNT(*) as streak_length,
    SUM(win_amount) as total_winnings
```

### 4. PATTERN

Defines the sequence pattern using regular expression-like syntax:

```sql
PATTERN (win_event{3,})  -- 3 or more consecutive wins
PATTERN (deposit_event free_contest_event+ paid_contest_event)  -- Specific sequence
```

### 5. DEFINE

Specifies conditions for each pattern variable:

```sql
DEFINE
    win_event AS contest_result = 'win',
    loss_event AS contest_result = 'loss'
```

## Pattern Quantifiers

| Quantifier | Meaning | Example |
|------------|---------|---------|
| `*` | Zero or more | `win_event*` (0+ wins) |
| `+` | One or more | `win_event+` (1+ wins) |
| `?` | Zero or one | `deposit_event?` (optional deposit) |
| `{n}` | Exactly n | `win_event{5}` (exactly 5 wins) |
| `{n,}` | n or more | `win_event{3,}` (3+ wins) |
| `{n,m}` | Between n and m | `win_event{2,5}` (2-5 wins) |
| `\|` | Alternation | `(win_event \| loss_event)` |

## Practical Examples for dbt-splash-prod-v2

### Example 1: Contest Winning Streaks

**Use Case**: Identify users with 3+ consecutive contest wins

```sql
-- Analysis query for winning streak detection
-- File: .jira/2-active/DA-XXX/queries/winning_streaks_analysis.sql

with contest_results as (

    select
        user_id,
        contest_id,
        entry_timestamp,
        case
            when final_rank <= prize_positions then 'win'
            else 'loss'
        end as contest_result,
        prize_amount_cents / 100.0 as prize_amount_usd
    from {{ ref('fct_contest_entries') }}
    where entry_timestamp >= current_date - interval '90 days'

)

select
    user_id,
    streak_start,
    streak_end,
    streak_length,
    total_prize_usd,
    datediff('day', streak_start, streak_end) as streak_duration_days
from contest_results
    match_recognize (
        partition by user_id
        order by entry_timestamp
        measures
            first(entry_timestamp) as streak_start,
            last(entry_timestamp) as streak_end,
            count(*) as streak_length,
            sum(prize_amount_usd) as total_prize_usd
        one row per match
        after match skip to next row
        pattern (win_event{3,})                      -- 3+ consecutive wins
        define
            win_event as contest_result = 'win'
    ) as streaks
where streak_length >= 3
order by user_id, streak_start
```

### Example 2: User Engagement Funnel

**Use Case**: Track signup → deposit → first paid contest sequence

```sql
-- User activation funnel analysis
-- File: analyses/user_activation_funnel_pattern.sql

with user_events as (

    select
        user_id,
        event_timestamp,
        event_type,  -- 'signup', 'deposit', 'free_contest', 'paid_contest'
        event_value_cents / 100.0 as event_value_usd
    from {{ ref('fct_user_events') }}
    where event_timestamp >= current_date - interval '30 days'

)

select
    user_id,
    signup_timestamp,
    first_deposit_timestamp,
    first_paid_contest_timestamp,
    datediff('hour', signup_timestamp, first_deposit_timestamp) as hours_to_deposit,
    datediff('hour', first_deposit_timestamp, first_paid_contest_timestamp) as hours_to_first_contest,
    total_free_contests_before_paid,
    first_deposit_amount_usd
from user_events
    match_recognize (
        partition by user_id
        order by event_timestamp
        measures
            signup.event_timestamp as signup_timestamp,
            deposit.event_timestamp as first_deposit_timestamp,
            paid.event_timestamp as first_paid_contest_timestamp,
            count(free.*) as total_free_contests_before_paid,
            deposit.event_value_usd as first_deposit_amount_usd
        one row per match
        pattern (signup deposit free* paid)
        define
            signup as event_type = 'signup',
            deposit as event_type = 'deposit',
            free as event_type = 'free_contest',
            paid as event_type = 'paid_contest'
    ) as funnel
```

### Example 3: Rapid Deposit Detection (Fraud Pattern)

**Use Case**: Identify users making 3+ deposits within 1 hour

```sql
-- Rapid deposit pattern detection for fraud analysis
-- File: analyses/rapid_deposit_detection.sql

with wallet_deposits as (

    select
        user_id,
        transaction_timestamp,
        transaction_type,
        amount_cents / 100.0 as amount_usd
    from {{ ref('fct_wallet_transactions') }}
    where transaction_type = 'deposit'
        and transaction_timestamp >= current_date - interval '7 days'

)

select
    user_id,
    rapid_deposit_start,
    rapid_deposit_end,
    deposit_count,
    total_deposit_amount_usd,
    time_window_minutes
from wallet_deposits
    match_recognize (
        partition by user_id
        order by transaction_timestamp
        measures
            first(transaction_timestamp) as rapid_deposit_start,
            last(transaction_timestamp) as rapid_deposit_end,
            count(*) as deposit_count,
            sum(amount_usd) as total_deposit_amount_usd,
            datediff('minute', first(transaction_timestamp), last(transaction_timestamp)) as time_window_minutes
        one row per match
        pattern (deposit_event{3,})
        define
            deposit_event as
                transaction_type = 'deposit'
                and datediff('hour', first(transaction_timestamp), transaction_timestamp) <= 1
    ) as rapid_deposits
where deposit_count >= 3
order by user_id, rapid_deposit_start
```

### Example 4: Session Boundary Detection

**Use Case**: Identify user sessions based on event gaps (30+ min = new session)

```sql
-- Session analysis with MATCH_RECOGNIZE
-- File: analyses/user_session_patterns.sql

with user_events as (

    select
        user_id,
        event_timestamp,
        event_name,
        page_url
    from {{ ref('stg_segment__web_events') }}
    where event_timestamp >= current_date - interval '7 days'

)

select
    user_id,
    session_start,
    session_end,
    session_duration_minutes,
    event_count,
    unique_pages
from user_events
    match_recognize (
        partition by user_id
        order by event_timestamp
        measures
            first(event_timestamp) as session_start,
            last(event_timestamp) as session_end,
            datediff('minute', first(event_timestamp), last(event_timestamp)) as session_duration_minutes,
            count(*) as event_count,
            count(distinct page_url) as unique_pages
        one row per match
        after match skip to next row
        pattern (session_event+)
        define
            session_event as
                datediff('minute', lag(event_timestamp), event_timestamp) <= 30
                or lag(event_timestamp) is null  -- First event
    ) as sessions
order by user_id, session_start
```

## Advanced Patterns

### Pattern with Multiple Event Types

```sql
-- Complex pattern: deposit → (free contest OR paid contest) → withdraw
pattern (
    deposit_event
    (free_contest_event | paid_contest_event)+
    withdrawal_event
)

define
    deposit_event as transaction_type = 'deposit',
    free_contest_event as contest_type = 'free' and transaction_type = 'contest_entry',
    paid_contest_event as contest_type = 'paid' and transaction_type = 'contest_entry',
    withdrawal_event as transaction_type = 'withdraw'
```

### Using ALL ROWS PER MATCH

```sql
-- Return all rows in the matched pattern, not just summary
select *
from source_table
    match_recognize (
        partition by user_id
        order by event_timestamp
        measures
            classifier() as event_role,  -- Shows which pattern variable matched
            match_number() as match_id   -- Unique ID for each match
        all rows per match               -- Returns all matching rows
        pattern (win_event{3,})
        define
            win_event as contest_result = 'win'
    )
```

### Greedy vs Reluctant Quantifiers

```sql
-- Greedy (default): Matches as many as possible
pattern (win_event{3,})

-- Reluctant: Matches as few as possible
pattern (win_event{3,}?)

-- Example: Find shortest winning streak of 3+
pattern (win_event{3,}? loss_event)  -- Stops at first loss after 3 wins
```

## Performance Optimization Tips

### 1. Partition Wisely

```sql
-- ✅ GOOD: Reasonable partition size
PARTITION BY user_id  -- Thousands of users, manageable sequences

-- ⚠️ CAREFUL: Very large partitions
PARTITION BY contest_type  -- Only a few partitions, very long sequences
```

### 2. Order by Indexed/Clustered Columns

```sql
-- ✅ GOOD: Use clustered timestamp column
ORDER BY transaction_timestamp  -- Clustered in fct_wallet_transactions

-- ❌ LESS EFFICIENT: Non-clustered column
ORDER BY secondary_sort_key
```

### 3. Use Time Windows to Limit Pattern Search

```sql
-- ✅ GOOD: Time-bounded pattern matching
define
    win_event as
        contest_result = 'win'
        and datediff('day', first(entry_timestamp), entry_timestamp) <= 30  -- Max 30-day streak
```

### 4. Filter Before MATCH_RECOGNIZE

```sql
-- ✅ GOOD: Pre-filter to reduce input rows
with recent_contests as (
    select *
    from {{ ref('fct_contest_entries') }}
    where entry_timestamp >= current_date - interval '90 days'  -- Filter first
)

select *
from recent_contests
    match_recognize (...)
```

## Common Pitfalls

### 1. Forgetting PARTITION BY

```sql
-- ❌ WRONG: No partition, analyzes ALL users as one sequence
select *
from user_events
    match_recognize (
        order by event_timestamp  -- Missing PARTITION BY user_id
        ...
    )

-- ✅ CORRECT: Partition by user_id for per-user analysis
select *
from user_events
    match_recognize (
        partition by user_id
        order by event_timestamp
        ...
    )
```

### 2. Incorrect Quantifier Usage

```sql
-- ❌ WRONG: {3,} requires 3 or more, won't match 1-2 wins
pattern (win_event{3,})

-- ✅ CORRECT: Use {1,} or + for 1 or more
pattern (win_event+)
```

### 3. Missing DEFINE for All Pattern Variables

```sql
-- ❌ WRONG: Pattern uses 'loss_event' but DEFINE doesn't include it
pattern (win_event+ loss_event)
define
    win_event as contest_result = 'win'
    -- loss_event not defined!

-- ✅ CORRECT: Define all variables
pattern (win_event+ loss_event)
define
    win_event as contest_result = 'win',
    loss_event as contest_result = 'loss'
```

## Integration with dbt Models

### Staging Layer

MATCH_RECOGNIZE is NOT typically used in staging - staging should be 1:1 with source.

### Core Layer (Facts/Dimensions)

Use MATCH_RECOGNIZE for derived facts:

```sql
-- Example: Create fact table for user streaks
-- models/dwh/core/contests/fct_user_contest_streaks.sql

{{
    config(
        materialized='table',
        tags=[
            'group:contests',
            'layer:core',
            'pattern:fact_transaction',
            'business:analytics',
            'critical:false',
            'volume:low'
        ]
    )
}}

with contest_results as (
    select
        user_id,
        contest_id,
        entry_timestamp,
        case when final_rank <= prize_positions then 'win' else 'loss' end as result
    from {{ ref('fct_contest_entries') }}
)

select
    {{ dbt_utils.generate_surrogate_key(['user_id', 'streak_start']) }} as streak_key,
    user_id,
    streak_start,
    streak_end,
    streak_type,
    streak_length,
    current_timestamp() as transformed_at
from contest_results
    match_recognize (
        partition by user_id
        order by entry_timestamp
        measures
            first(entry_timestamp) as streak_start,
            last(entry_timestamp) as streak_end,
            classifier() as streak_type,
            count(*) as streak_length
        one row per match
        pattern (win_event{3,} | loss_event{3,})
        define
            win_event as result = 'win',
            loss_event as result = 'loss'
    ) as streaks
```

### Marts Layer

Use MATCH_RECOGNIZE for business intelligence aggregations:

```sql
-- Example: User engagement metrics mart
-- models/dwh/marts/analytics/mart_user_engagement_patterns.sql

{{
    config(
        materialized='table',
        tags=[
            'group:analytics',
            'layer:marts',
            'business:analytics',
            'business:reporting',
            'critical:false'
        ]
    )
}}

-- Use MATCH_RECOGNIZE to identify activation patterns
-- Then aggregate for BI dashboards
```

## Testing Patterns

```yaml
# models/dwh/core/contests/schema.yml
version: 2

models:
  - name: fct_user_contest_streaks
    description: "User contest winning/losing streaks detected via MATCH_RECOGNIZE"
    columns:
      - name: streak_key
        description: "Surrogate key for the streak"
        tests:
          - unique
          - not_null

      - name: streak_length
        description: "Number of consecutive wins/losses"
        tests:
          - dbt_utils.expression_is_true:
              expression: ">= 3"  # Pattern only matches 3+ events

      - name: streak_type
        description: "Type of streak (win_event or loss_event)"
        tests:
          - accepted_values:
              values: ['win_event', 'loss_event']
```

## When to Use MATCH_RECOGNIZE vs Window Functions

| Scenario | Recommended Approach |
|----------|---------------------|
| Simple ranking/ordering | Window functions (ROW_NUMBER, RANK) + QUALIFY |
| Complex sequential patterns | MATCH_RECOGNIZE |
| Single-event filtering | WHERE clause |
| Multi-event sequence detection | MATCH_RECOGNIZE |
| Running totals/averages | Window functions (SUM/AVG OVER) |
| Fraud detection patterns | MATCH_RECOGNIZE |
| Session analysis | MATCH_RECOGNIZE |
| Simple aggregations | GROUP BY |

## Additional Resources

**Snowflake Documentation**:

- [MATCH_RECOGNIZE Official Docs](https://docs.snowflake.com/en/sql-reference/constructs/match_recognize.html)
- [Pattern Matching Tutorial](https://docs.snowflake.com/en/user-guide/querying-pattern-matching.html)

**Project Integration**:

- Contests domain: User behavior analysis, streak detection
- Finance domain: Transaction fraud patterns, wallet analysis
- Analytics domain: User engagement funnels, session analysis

---

**Last Updated**: 2025-10-07
**Agent**: snowflake-sql-expert
**Knowledge Category**: Patterns
