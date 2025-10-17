---
title: "SQL Expert Integration Patterns"
description: "Coordination patterns between metabase-engineer and sql-expert agents for query optimization"
category: "integrations"
tags: ["sql-expert", "collaboration", "query-optimization", "handoff"]
last_updated: "2025-10-16"
---

# SQL Expert Integration Patterns

Guide for effective collaboration between `metabase-engineer` and `sql-expert` agents when building and optimizing Metabase dashboards.

## Division of Responsibilities

### metabase-engineer

**Owns**:
- Metabase YAML specifications
- Dashboard layout and UX
- Visualization configuration
- API deployment
- CI/CD integration
- Metabase-specific features (filters, parameters, drill-through)

**Does NOT own**:
- Complex SQL query logic
- Data model selection decisions
- Advanced Snowflake optimization
- dbt model modifications

### sql-expert

**Owns**:
- SQL query logic and optimization
- Data model selection (which table/mart to use)
- JOIN strategies and performance
- Snowflake-specific optimizations
- Window functions, CTEs, complex aggregations

**Does NOT own**:
- Metabase visualization settings
- Dashboard layout decisions
- Metabase API operations
- YAML specification format

## Collaboration Workflows

### Workflow 1: New Dashboard with Complex Queries

**Scenario**: Building a Market Maker performance dashboard that requires complex financial calculations.

**Step-by-Step**:

```yaml
# 1. metabase-engineer: Define requirements
Dashboard: "Market Maker Financial Performance"
Metrics needed:
  - House ROI % (needs complex calculation)
  - Net House Payout (cumulative over time)
  - Autodraft utilization rate (by contest type)
  - Daily P&L trend with 7-day moving average

Data available:
  - MART_HOUSE_LIQUIDITY
  - fct_house_slips
  - dim_contest_type

Performance requirements:
  - Dashboard must load in <5 seconds
  - Support last 90 days date range

# 2. sql-expert: Develops optimized queries
# Returns SQL for each metric with:
# - Appropriate table selection (mart vs fact)
# - Optimized JOINs and WHERE clauses
# - Window functions for trends
# - Clear comments explaining logic

# 3. metabase-engineer: Integrates into YAML
# Takes SQL from sql-expert and wraps in Metabase specification:
questions:
  - name: "House ROI %"
    type: "scalar"
    visualization:
      type: "scalar"
      settings: {display: "percentage"}
    query:
      sql: |
        -- SQL from sql-expert
        SELECT
          ((SUM(amount_won) / NULLIF(SUM(amount), 0)) - 1) * 100 as house_roi_pct
        FROM MART_HOUSE_LIQUIDITY
        WHERE date_actual BETWEEN {{start_date}} AND {{end_date}}
      parameters:
        - name: "start_date"
          type: "date"
        - name: "end_date"
          type: "date"

# 4. metabase-engineer: Deploys and tests
# 5. If performance issues, return to step 2
```

### Workflow 2: Optimizing Slow Dashboard

**Scenario**: Existing dashboard loading slowly, need to optimize queries.

**metabase-engineer Provides**:
```yaml
Issue: Market Maker dashboard taking 20+ seconds to load

Slow query identification:
  - Question: "Daily P&L Breakdown" - 15 seconds
  - Question: "Autodraft Utilization by Type" - 8 seconds

Current SQL for "Daily P&L Breakdown":
  SELECT
    date_actual,
    user_id,
    amount,
    amount_won,
    amount_won - amount as pnl
  FROM fct_house_slips
  WHERE house_activity_type = 'autodraft'
    AND date_actual >= '2025-01-01'
  ORDER BY date_actual DESC

Snowflake execution stats:
  - Execution time: 15 seconds
  - Rows scanned: 2.1M
  - Partitions scanned: 365
  - Bytes scanned: 2.4 GB

Context:
  - Dashboard filters: last 30 days (default)
  - Visualization: Line chart showing daily totals
  - Users: Finance team (not technical)
```

**sql-expert Returns**:
```sql
-- OPTIMIZED: Use pre-aggregated mart instead of fact table
-- Performance improvement: ~50x faster (15s → 300ms)

SELECT
  date_actual,
  net_house_payout as pnl,
  house_handle
FROM MART_HOUSE_LIQUIDITY
WHERE date_actual BETWEEN {{start_date}} AND {{end_date}}
  AND house_activity_type = 'autodraft'
ORDER BY date_actual DESC;

-- Explanation:
-- 1. MART_HOUSE_LIQUIDITY is pre-aggregated (365 rows vs 2.1M)
-- 2. Partition pruning with date filter
-- 3. Removed user_id as visualization shows daily totals (not needed)
-- 4. Using pre-calculated net_house_payout column

-- Alternative if user-level detail is required:
-- Add drill-through question that uses fct_house_slips with date filter
```

**metabase-engineer Integrates**:
```yaml
# Update YAML specification
- name: "Daily P&L Breakdown"
  type: "timeseries"
  position: {row: 2, col: 0, sizeX: 6, sizeY: 4}
  visualization:
    type: "line"
    settings:
      x_axis: "date_actual"
      y_axis: ["pnl"]
  query:
    sql: |
      -- Optimized by sql-expert (2025-10-16)
      SELECT
        date_actual,
        net_house_payout as pnl,
        house_handle
      FROM MART_HOUSE_LIQUIDITY
      WHERE date_actual BETWEEN {{start_date}} AND {{end_date}}
        AND house_activity_type = 'autodraft'
      ORDER BY date_actual DESC
    parameters:
      - name: "start_date"
        type: "date"
        default: "2025-01-01"
      - name: "end_date"
        type: "date"
        default: "today"
  # Add drill-through for user-level detail
  drill_through:
    target_question: "User-Level P&L Detail"
    pass_parameters: ["date_actual"]
```

### Workflow 3: Complex Metric Definition

**Scenario**: Need to implement a business metric with unclear SQL implementation.

**metabase-engineer Requests**:
```yaml
Metric: "Assisted Fill Rate %"

Business definition (from business-context.md):
  "Percentage of contests that required autodrafts to fill,
   excluding contests that cancelled due to insufficient entries"

Formula (conceptual):
  Assisted Fill Rate % = (Contests with autodrafts / Total filled contests) × 100

Available tables:
  - MART_CONTEST_FILL_ANALYSIS (contest-level aggregates)
    - Fields: contest_id, fill_type, autodraft_count, total_slips
  - fct_contest_entries (entry-level detail)
  - dim_contest_type

Expected output:
  - Single percentage value (KPI scorecard)
  - Filterable by date range, contest type
  - Should match product team's definition

Test case:
  - Date: 2025-10-01
  - Total filled contests: 1,000
  - Contests with autodrafts: 350
  - Expected result: 35%
```

**sql-expert Returns**:
```sql
-- Assisted Fill Rate %
-- Definition: % of successfully filled contests that required autodrafts

SELECT
  (
    COUNT(CASE WHEN fill_type = 'assisted' THEN 1 END) * 100.0 /
    NULLIF(COUNT(CASE WHEN fill_type IN ('organic', 'assisted') THEN 1 END), 0)
  ) AS assisted_fill_rate_pct
FROM MART_CONTEST_FILL_ANALYSIS
WHERE date_actual BETWEEN {{start_date}} AND {{end_date}}
  -- Exclude cancelled and open contests per business definition
  AND fill_type IN ('organic', 'assisted');

-- Explanation:
-- - Numerator: Contests where autodrafts were used (fill_type = 'assisted')
-- - Denominator: All filled contests (organic + assisted)
-- - Excludes 'cancelled_unfilled' and 'open_unfilled'
-- - NULLIF prevents division by zero

-- Note: If you need breakdown by contest type, add:
-- AND contest_type = {{contest_type_filter}}

-- Validation query (test case):
SELECT
  date_actual,
  fill_type,
  COUNT(*) as contest_count
FROM MART_CONTEST_FILL_ANALYSIS
WHERE date_actual = '2025-10-01'
GROUP BY date_actual, fill_type;
```

**metabase-engineer Integrates**:
```yaml
- name: "Assisted Fill Rate"
  type: "scalar"
  position: {row: 0, col: 6, sizeX: 3, sizeY: 2}
  description: "% of filled contests requiring autodrafts (excludes cancelled contests)"
  visualization:
    type: "scalar"
    settings:
      display: "percentage"
      decimals: 1
      comparison: "previous-period"
      goal_value: 30  # Target: <30% assisted (more organic is better)
  query:
    sql: |
      -- Assisted Fill Rate % (validated by sql-expert)
      SELECT
        (
          COUNT(CASE WHEN fill_type = 'assisted' THEN 1 END) * 100.0 /
          NULLIF(COUNT(CASE WHEN fill_type IN ('organic', 'assisted') THEN 1 END), 0)
        ) AS assisted_fill_rate_pct
      FROM MART_CONTEST_FILL_ANALYSIS
      WHERE date_actual BETWEEN {{start_date}} AND {{end_date}}
        AND fill_type IN ('organic', 'assisted')
    parameters:
      - name: "start_date"
        type: "date"
        default: "2025-01-01"
      - name: "end_date"
        type: "date"
        default: "today"
```

## Handoff Templates

### Template: Request Query Optimization

```yaml
To: sql-expert
From: metabase-engineer

Subject: Optimize query for [Dashboard Name] - [Question Name]

Current Performance:
  - Execution time: [X seconds]
  - Rows scanned: [N rows]
  - Data scanned: [GB]

Current SQL:
```sql
[Paste SQL here]
```

Context:
  - Visualization type: [scalar/line/bar/table]
  - Dashboard filters: [date range, categories]
  - Expected result set size: [N rows]
  - User audience: [executives/operations/analysts]
  - Update frequency: [real-time/hourly/daily]

Performance target:
  - Execution time: <[X] seconds
  - Dashboard load: <10 seconds total

Available data models:
  - [List relevant tables/marts]

Please provide:
  1. Optimized SQL query
  2. Explanation of changes
  3. Expected performance improvement
  4. Any caveats or limitations
```

### Template: Request Complex Metric SQL

```yaml
To: sql-expert
From: metabase-engineer

Subject: Implement SQL for metric: [Metric Name]

Business Definition:
  [Description from business-context.md or requirements]

Conceptual Formula:
  [Math/logic in plain English]

Available Tables:
  - [Table 1]: [Description, key fields]
  - [Table 2]: [Description, key fields]

Expected Output:
  - Format: [single value / time series / breakdown by category]
  - Filters needed: [date range, contest type, etc.]
  - Precision: [decimals, formatting]

Validation Test Case:
  - Input: [Specific date/filters]
  - Expected output: [Known correct value]

Please provide:
  1. SQL query implementation
  2. Explanation of logic
  3. Validation query to verify correctness
  4. Performance considerations
```

### Template: Review SQL Before Deployment

```yaml
To: sql-expert
From: metabase-engineer

Subject: Review SQL for new dashboard: [Dashboard Name]

Dashboard Purpose: [Brief description]

Queries to Review:
  1. [Question Name 1]
     - Purpose: [What it shows]
     - SQL: ```sql [SQL here] ```

  2. [Question Name 2]
     - Purpose: [What it shows]
     - SQL: ```sql [SQL here] ```

Concerns:
  - [Any specific concerns about performance, correctness, etc.]

Target Audience: [Who will use this dashboard]
Update Frequency: [How often it will be viewed]

Please review for:
  - Correctness of business logic
  - Performance optimization opportunities
  - Best practices compliance
  - Potential edge cases or issues
```

## Common Collaboration Patterns

### Pattern 1: Incremental Optimization

**When**: Dashboard exists but can be improved.

**Process**:
1. metabase-engineer identifies slowest queries
2. sql-expert optimizes one query at a time
3. metabase-engineer deploys and tests
4. Measure improvement, iterate

**Benefits**: Lower risk, clear attribution of improvements.

### Pattern 2: Dashboard Design Review

**When**: Before building complex dashboard.

**Process**:
1. metabase-engineer drafts YAML specification (without SQL)
2. sql-expert reviews data model selection
3. sql-expert suggests marts vs facts for each question
4. metabase-engineer finalizes design
5. sql-expert provides optimized SQL
6. metabase-engineer implements and deploys

**Benefits**: Prevents rework, catches issues early.

### Pattern 3: Metric Validation

**When**: Implementing critical business metrics.

**Process**:
1. metabase-engineer implements metric based on requirements
2. sql-expert provides validation query
3. metabase-engineer runs both queries, compares results
4. sql-expert adjusts if discrepancy found
5. metabase-engineer documents validation in YAML comments

**Benefits**: Ensures correctness for critical metrics.

## Decision Tree: When to Involve sql-expert

```
Is the query straightforward?
├─ Yes → metabase-engineer implements directly
│         (Simple SELECT from mart, basic aggregation)
│
└─ No → Is it complex SQL or performance-critical?
          ├─ Yes → Involve sql-expert
          │         - Complex JOINs
          │         - Window functions
          │         - CTEs
          │         - Performance optimization
          │         - Metric validation
          │
          └─ No → Is data model selection unclear?
                    ├─ Yes → Consult sql-expert
                    │         "Should I use mart X or fact Y?"
                    │
                    └─ No → metabase-engineer proceeds
```

## Success Metrics

**Effective Collaboration When**:
- Dashboard queries execute in <2 seconds (avg)
- Zero metric accuracy issues reported
- Clear documentation of SQL logic in YAML
- Handoffs are smooth (no back-and-forth)
- Both agents understand their boundaries

**Poor Collaboration When**:
- Same query optimized multiple times
- Metric definitions disputed after deployment
- Unclear who owns what
- Long delays waiting for other agent
- Duplicate work or conflicting changes

## Best Practices

1. **Clear Handoff Context** - Always provide complete context in requests
2. **Document SQL Source** - Add comments in YAML indicating sql-expert involvement
3. **Test Before Handoff** - metabase-engineer tests SQL in Snowflake before YAML
4. **Validate After Integration** - Verify results match after wrapping SQL in Metabase
5. **Performance First** - Optimize queries before visual polish
6. **Single Source of Truth** - SQL in YAML is deployed version, not Snowflake scratch
7. **Version Control** - Track SQL changes in git commits

---

**Related Documents**:
- [query-performance-optimization.md](../troubleshooting/query-performance-optimization.md) - Performance guidelines
- [agent-coordination-patterns.md](agent-coordination-patterns.md) - Other agent integrations
- [yaml-specification-schema.md](../core-concepts/yaml-specification-schema.md) - YAML format
