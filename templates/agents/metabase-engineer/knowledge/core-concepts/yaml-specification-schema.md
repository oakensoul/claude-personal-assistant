---

title: "YAML Specification Schema Reference"
description: "Complete schema reference for Metabase dashboard and question YAML specifications"
category: "core-concepts"
tags: ["yaml", "schema", "specification", "dashboards", "questions"]
last_updated: "2025-10-16"

---

# YAML Specification Schema Reference

Complete reference for defining Metabase dashboards and questions in YAML format for reports-as-code deployments.

## Dashboard Specification Schema

### Complete Example

```yaml


---

name: "Market Maker Performance Dashboard"
description: "Financial performance metrics for Market Maker autodraft system"
collection: "Finance"
tags: ["finance", "market-maker", "executive"]
database: "Snowflake DWH"
environment: "prod"
version: "1.2.0"
last_updated: "2025-10-16"
author: "data-team"

# Global dashboard filters
filters:

  - name: "Date Range"

    field: "date_actual"
    type: "date-range"
    default: "last-30-days"
    widget_type: "date/range"

  - name: "User Tier"

    field: "user_tier"
    type: "category"
    values: ["free", "premium", "vip"]
    default: "all"
    widget_type: "category"

# Dashboard layout (12-column grid)
layout:
  rows: 4
  columns: 12

# Questions (charts/visualizations)
questions:
  # KPI Scorecards (Row 1)

  - name: "Total House Handle"

    description: "Total amount wagered by Market Maker"
    type: "scalar"
    position: {row: 0, col: 0, sizeX: 3, sizeY: 2}
    visualization:
      type: "scalar"
      settings:
        display: "number"
        format: "currency"
        comparison: "previous-period"
        comparison_type: "percentage"
    query:
      source: "MART_HOUSE_LIQUIDITY"
      metrics: ["house_handle"]
      aggregation: "sum"
      filters:

        - field: "date_actual"

          operator: "between"
          value: "{{date_range}}"

  - name: "Net House Payout"

    description: "House P&L (should be negative = profit)"
    type: "scalar"
    position: {row: 0, col: 3, sizeX: 3, sizeY: 2}
    visualization:
      type: "scalar"
      settings:
        display: "number"
        format: "currency"
        comparison: "previous-period"
        alert_threshold: 0  # Alert if positive (house losing money)
        alert_direction: "above"
    query:
      source: "MART_HOUSE_LIQUIDITY"
      metrics: ["net_house_payout"]
      aggregation: "sum"
      filters:

        - field: "date_actual"

          operator: "between"
          value: "{{date_range}}"

  - name: "House ROI %"

    description: "Return on investment for Market Maker"
    type: "scalar"
    position: {row: 0, col: 6, sizeX: 3, sizeY: 2}
    visualization:
      type: "scalar"
      settings:
        display: "percentage"
        decimals: 2
        comparison: "previous-period"
        alert_threshold: 0  # Alert if positive
        alert_direction: "above"
    query:
      source: "MART_HOUSE_LIQUIDITY"
      metrics: ["house_roi_pct"]
      aggregation: "avg"
      filters:

        - field: "date_actual"

          operator: "between"
          value: "{{date_range}}"

  - name: "Autodraft Count"

    description: "Number of automated slips generated"
    type: "scalar"
    position: {row: 0, col: 9, sizeX: 3, sizeY: 2}
    visualization:
      type: "scalar"
      settings:
        display: "number"
        format: "integer"
        comparison: "previous-period"
    query:
      source: "MART_HOUSE_LIQUIDITY"
      metrics: ["autodraft_count"]
      aggregation: "sum"
      filters:

        - field: "date_actual"

          operator: "between"
          value: "{{date_range}}"

  # Time Series Charts (Row 2-3)

  - name: "Daily House Handle Trend"

    description: "House handle over time"
    type: "timeseries"
    position: {row: 2, col: 0, sizeX: 6, sizeY: 4}
    visualization:
      type: "line"
      settings:
        x_axis: "date_actual"
        y_axis: ["house_handle"]
        y_axis_format: "currency"
        show_points: true
        show_trend_line: true
        colors: ["#509EE3"]
    query:
      source: "MART_HOUSE_LIQUIDITY"
      dimensions: ["date_actual"]
      metrics: ["house_handle"]
      aggregation: "sum"
      group_by: ["date_actual"]
      order_by: ["date_actual ASC"]
      filters:

        - field: "date_actual"

          operator: "between"
          value: "{{date_range}}"

  - name: "Cumulative House P&L"

    description: "Running total of house profit/loss"
    type: "timeseries"
    position: {row: 2, col: 6, sizeX: 6, sizeY: 4}
    visualization:
      type: "area"
      settings:
        x_axis: "date_actual"
        y_axis: ["cumulative_pnl"]
        y_axis_format: "currency"
        fill_opacity: 0.3
        colors: ["#84BB4C"]
    query:
      source: "MART_HOUSE_LIQUIDITY"
      dimensions: ["date_actual"]
      metrics: ["net_house_payout"]
      aggregation: "sum"
      group_by: ["date_actual"]
      order_by: ["date_actual ASC"]
      window_function:
        type: "cumulative_sum"
        partition_by: []
        order_by: ["date_actual"]
      filters:

        - field: "date_actual"

          operator: "between"
          value: "{{date_range}}"

  # Detail Table (Row 4)

  - name: "Daily Breakdown"

    description: "Daily detail of Market Maker activity"
    type: "table"
    position: {row: 6, col: 0, sizeX: 12, sizeY: 4}
    visualization:
      type: "table"
      settings:
        columns:

          - field: "date_actual"

            display_name: "Date"
            format: "date"

          - field: "house_handle"

            display_name: "Handle"
            format: "currency"

          - field: "net_house_payout"

            display_name: "Net Payout"
            format: "currency"

          - field: "house_roi_pct"

            display_name: "ROI %"
            format: "percentage"

          - field: "autodraft_count"

            display_name: "Autodrafts"
            format: "integer"
        conditional_formatting:

          - column: "house_roi_pct"

            condition: "greater_than"
            value: 0
            style: {background: "#FFE4E1", color: "#FF0000"}

          - column: "net_house_payout"

            condition: "greater_than"
            value: 0
            style: {background: "#FFE4E1", color: "#FF0000"}
    query:
      source: "MART_HOUSE_LIQUIDITY"
      dimensions: ["date_actual"]
      metrics: ["house_handle", "net_house_payout", "house_roi_pct", "autodraft_count"]
      aggregation: "sum"
      group_by: ["date_actual"]
      order_by: ["date_actual DESC"]
      limit: 100
      filters:

        - field: "date_actual"

          operator: "between"
          value: "{{date_range}}"

# Access control
permissions:
  view: ["finance-team", "executives", "data-team"]
  edit: ["data-team"]

```

## Question Specification Schema

### Native SQL Query Question

```yaml


---

name: "Market Maker ROI by Contest Type"
description: "House ROI percentage broken down by contest type"
collection: "Finance/Shared Questions"
database: "Snowflake DWH"
type: "native"
version: "1.0.0"

query:
  sql: |
    SELECT
      c.contest_type,
      SUM(h.amount) AS house_handle,
      SUM(h.amount_won) AS house_winnings,
      ((SUM(h.amount_won) / NULLIF(SUM(h.amount), 0)) - 1) * 100 AS house_roi_pct
    FROM MART_HOUSE_LIQUIDITY h
    JOIN dim_contest_type c ON h.contest_type_key = c.contest_type_key
    WHERE h.date_actual BETWEEN {{date_start}} AND {{date_end}}
    GROUP BY c.contest_type
    ORDER BY house_roi_pct ASC

  parameters:

    - name: "date_start"

      type: "date"
      default: "2025-01-01"
      required: true

    - name: "date_end"

      type: "date"
      default: "today"
      required: true

visualization:
  type: "bar"
  settings:
    x_axis: "contest_type"
    y_axis: "house_roi_pct"
    y_axis_format: "percentage"
    colors: ["#509EE3"]
    goal_line:
      value: 0
      label: "Break Even"
      style: "dashed"

```

### GUI-Based Question

```yaml


---

name: "Daily Revenue by User Tier"
description: "Revenue trends segmented by user tier"
collection: "Finance/Shared Questions"
database: "Snowflake DWH"
type: "gui"
version: "1.0.0"

query:
  source_table: "finance_revenue_daily"

  aggregations:

    - metric: "total_revenue"

      function: "sum"

  breakouts:

    - field: "date_actual"

      temporal_unit: "day"

    - field: "user_tier"

  filters:

    - field: "date_actual"

      operator: "between"
      value: ["2025-01-01", "2025-12-31"]

    - field: "revenue_type"

      operator: "equals"
      value: "contest_fee"

  order_by:

    - field: "date_actual"

      direction: "ascending"

visualization:
  type: "line"
  settings:
    x_axis: "date_actual"
    y_axis: ["total_revenue"]
    series: "user_tier"
    y_axis_format: "currency"
    show_legend: true
    legend_position: "bottom"
    colors:
      free: "#84BB4C"
      premium: "#509EE3"
      vip: "#F9CF48"

```

## Schema Field Reference

### Dashboard Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Dashboard display name |
| `description` | string | Yes | Dashboard purpose/context |
| `collection` | string | Yes | Collection path (e.g., "Finance") |
| `tags` | array[string] | No | Tags for organization |
| `database` | string | Yes | Database connection name |
| `environment` | string | No | Target environment (dev/staging/prod) |
| `version` | string | No | Semantic version |
| `last_updated` | date | No | Last modification date |
| `author` | string | No | Dashboard creator |
| `filters` | array[filter] | No | Dashboard-level filters |
| `layout` | object | No | Layout configuration |
| `questions` | array[question] | Yes | Dashboard questions |
| `permissions` | object | No | Access control |

### Question Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Question display name |
| `description` | string | Yes | Question purpose |
| `type` | enum | Yes | Question type (scalar, timeseries, table, etc.) |
| `position` | object | Yes | Grid position {row, col, sizeX, sizeY} |
| `visualization` | object | Yes | Visualization configuration |
| `query` | object | Yes | Query definition |

### Filter Types

| Type | Description | Example |
|------|-------------|---------|
| `date-range` | Date range picker | Last 30 days, custom range |
| `date` | Single date picker | 2025-10-16 |
| `category` | Dropdown/multi-select | User tier, contest type |
| `number` | Numeric input | > 1000 |
| `text` | Text search | User name contains "john" |
| `boolean` | Checkbox | Is verified? |

### Visualization Types

| Type | Use Case | Best For |
|------|----------|----------|
| `scalar` | Single metric (KPI) | Key metrics, scorecards |
| `line` | Trend over time | Time series, trends |
| `area` | Cumulative trends | Running totals, accumulation |
| `bar` | Categorical comparison | Comparing categories |
| `combo` | Multiple metrics | Combined trends |
| `pie` | Proportional breakdown | Part-to-whole (use sparingly) |
| `table` | Detailed data | Drill-down, exports |
| `pivot` | Cross-tab analysis | Multi-dimensional |

### Query Operators

| Operator | Description | Example |
|----------|-------------|---------|
| `equals` | Exact match | contest_type = 'QuickPick' |
| `not_equals` | Not equal | status != 'cancelled' |
| `between` | Range (inclusive) | date BETWEEN '2025-01-01' AND '2025-01-31' |
| `greater_than` | > | amount > 100 |
| `less_than` | < | count < 10 |
| `contains` | Substring match | name CONTAINS 'test' |
| `is_null` | NULL check | email IS NULL |
| `is_not_null` | NOT NULL check | verified_at IS NOT NULL |
| `in` | List match | tier IN ('premium', 'vip') |

## Validation Rules

### Required Frontmatter

All YAML specifications MUST include frontmatter with:

- `name` (unique within collection)
- `description` (clear, concise purpose)
- `collection` (valid collection path)
- `database` (valid database connection)

### Naming Conventions

- **Dashboard names**: Human-readable, sentence case ("Market Maker Performance Dashboard")
- **Question names**: Descriptive, concise ("Daily House Handle")
- **Collection paths**: Use forward slashes ("Finance/Market Maker")
- **Field names**: snake_case matching database schema

### Layout Rules

- Grid is 12 columns wide
- Minimum question size: 2x2
- KPI scorecards typically: 3x2 or 4x2
- Charts typically: 6x4 or 12x4
- Tables typically: 12x4 or wider

### Performance Considerations

- Limit dashboards to 15-20 questions max
- Use pre-aggregated marts when possible
- Always include date range filters
- Avoid SELECT * in native queries
- Limit result sets (LIMIT clause)

## Parameter Passing

### Dashboard-to-Question Parameters

```yaml

# Dashboard filter
filters:

  - name: "Date Range"

    field: "date_actual"
    type: "date-range"
    default: "last-30-days"

# Question using filter
questions:

  - name: "Revenue Trend"

    query:
      filters:

        - field: "date_actual"

          operator: "between"
          value: "{{date_range}}"  # References dashboard filter

```

### Question Parameters

```yaml

query:
  sql: |
    SELECT * FROM revenue
    WHERE user_tier = {{tier}}
    AND date >= {{start_date}}

  parameters:

    - name: "tier"

      type: "category"
      values: ["free", "premium", "vip"]
      default: "premium"

    - name: "start_date"

      type: "date"
      default: "2025-01-01"

```

## Best Practices

### YAML Structure

1. Always include complete frontmatter
2. Comment complex queries
3. Use consistent indentation (2 spaces)
4. Group related questions logically
5. Order fields consistently

### Query Design

1. Use marts over raw facts when possible
2. Always include date filters for large tables
3. Test queries in Snowflake before YAML
4. Use explicit column names (not SELECT *)
5. Add comments for complex logic

### Visualization Selection

1. Scalars for single metrics
2. Lines for trends over time
3. Bars for categorical comparisons
4. Tables for drill-down and exports
5. Avoid pie charts (bars are clearer)

### Documentation

1. Description explains "why" not "what"
2. Include metric definitions in descriptions
3. Document expected value ranges
4. Note alert thresholds and why they matter

---

**Related Documents**:

- [metabase-architecture.md](metabase-architecture.md) - Metabase data model
- [dashboard-architecture.md](dashboard-architecture.md) - Layout patterns
- [python-deployment-scripts.md](../deployment-automation/python-deployment-scripts.md) - Deploying YAML specs
