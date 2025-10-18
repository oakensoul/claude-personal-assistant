---
title: "KPI Scorecard Patterns"
description: "Design patterns for KPI cards, metric scorecards, and executive summary visualizations"
category: "design-patterns"
tags: ["kpi", "scorecards", "metrics", "executive"]
last_updated: "2025-10-16"
---

# KPI Scorecard Patterns

KPI scorecards are the most important visualization type for executive dashboards. They provide at-a-glance insights into key business metrics with comparison context.

## When to Use Scorecards

**Best For**:

- Single metric that tells a story
- Executive dashboards (top of page)
- Operational dashboards (alert indicators)
- High-level health checks

**Avoid When**:

- Need to show trends over time (use line chart)
- Comparing multiple categories (use bar chart)
- Showing distributions (use histogram)

## Basic Scorecard Pattern

### Simple Metric

```yaml
- name: "Total Revenue"
  type: "scalar"
  position: {row: 0, col: 0, sizeX: 3, sizeY: 2}
  visualization:
    type: "scalar"
    settings:
      display: "number"
      format: "currency"
      decimals: 0
  query:
    source: "finance_revenue_daily"
    metrics: ["total_revenue"]
    aggregation: "sum"
    filters:
      - field: "date_actual"
        operator: "between"
        value: "{{date_range}}"
```text

**Visual Result**:

```text
┌─────────────────┐
│ Total Revenue   │
│                 │
│   $2,458,392    │
│                 │
└─────────────────┘
```text

## Comparison Patterns

### Period-over-Period Comparison

Most common pattern: Compare current period to previous period.

```yaml
- name: "Daily Active Users"
  type: "scalar"
  position: {row: 0, col: 0, sizeX: 3, sizeY: 2}
  visualization:
    type: "scalar"
    settings:
      display: "number"
      format: "integer"
      comparison: "previous-period"
      comparison_type: "percentage"
      positive_is_good: true  # Green for increase, red for decrease
  query:
    source: "user_activity_daily"
    metrics: ["dau"]
    aggregation: "avg"
    filters:
      - field: "date_actual"
        operator: "between"
        value: "{{date_range}}"
```text

**Visual Result**:

```text
┌─────────────────┐
│ Daily Active    │
│ Users           │
│                 │
│    12,453       │
│    ↑ 8.5%       │ ← Green, up arrow
└─────────────────┘
```text

### Goal-Based Comparison

Compare metric to a target/goal.

```yaml
- name: "Monthly Revenue Target"
  type: "scalar"
  position: {row: 0, col: 3, sizeX: 3, sizeY: 2}
  visualization:
    type: "scalar"
    settings:
      display: "number"
      format: "currency"
      comparison: "goal"
      goal_value: 5000000  # $5M goal
      goal_display: "percentage"
      positive_is_good: true
  query:
    source: "finance_revenue_daily"
    metrics: ["total_revenue"]
    aggregation: "sum"
    filters:
      - field: "date_actual"
        operator: "between"
        value: ["2025-10-01", "2025-10-31"]
```text

**Visual Result**:

```text
┌─────────────────┐
│ Monthly Revenue │
│ Target          │
│                 │
│  $4,245,000     │
│  85% of goal    │ ← Progress indicator
└─────────────────┘
```text

### Multiple Comparisons

Show multiple comparison contexts.

```yaml
- name: "Contest Fill Rate"
  type: "scalar"
  position: {row: 0, col: 6, sizeX: 4, sizeY: 2}
  visualization:
    type: "scalar"
    settings:
      display: "percentage"
      decimals: 1
      comparisons:
        - type: "previous-period"
          label: "vs. Last Month"
        - type: "year-over-year"
          label: "vs. Last Year"
        - type: "goal"
          goal_value: 95
          label: "Target"
  query:
    source: "MART_CONTEST_FILL_ANALYSIS"
    metrics: ["fill_rate_pct"]
    aggregation: "avg"
    filters:
      - field: "date_actual"
        operator: "between"
        value: "{{date_range}}"
```text

**Visual Result**:

```text
┌───────────────────────┐
│ Contest Fill Rate     │
│                       │
│      92.3%            │
│                       │
│ ↑ 2.1% vs Last Month  │
│ ↓ 1.5% vs Last Year   │
│ 97% of Target         │
└───────────────────────┘
```text

## Alert Patterns

### Threshold Alert

Highlight when metric crosses critical threshold.

```yaml
- name: "House ROI %"
  type: "scalar"
  position: {row: 0, col: 0, sizeX: 3, sizeY: 2}
  visualization:
    type: "scalar"
    settings:
      display: "percentage"
      decimals: 2
      alert_threshold: 0
      alert_direction: "above"  # Alert if > 0
      alert_message: "House is losing money!"
      alert_color: "#FF0000"
      positive_is_good: false  # Red for positive, green for negative
  query:
    source: "MART_HOUSE_LIQUIDITY"
    metrics: ["house_roi_pct"]
    aggregation: "avg"
    filters:
      - field: "date_actual"
        operator: "between"
        value: "{{date_range}}"
```text

**Visual Result (Normal)**:

```text
┌─────────────────┐
│ House ROI %     │
│                 │
│    -12.45%      │ ← Green background
│                 │
└─────────────────┘
```text

**Visual Result (Alert)**:

```text
┌─────────────────┐
│ House ROI %     │
│ ⚠ ALERT         │
│                 │
│     +3.21%      │ ← Red background
│                 │
│ House is losing │
│ money!          │
└─────────────────┘
```text

### Multi-Level Alerts

Different alert levels based on severity.

```yaml
- name: "Error Rate"
  type: "scalar"
  position: {row: 0, col: 0, sizeX: 3, sizeY: 2}
  visualization:
    type: "scalar"
    settings:
      display: "percentage"
      decimals: 2
      alerts:
        - level: "warning"
          threshold: 1.0
          color: "#FFA500"
          message: "Elevated error rate"
        - level: "critical"
          threshold: 5.0
          color: "#FF0000"
          message: "Critical error rate!"
  query:
    source: "system_metrics"
    metrics: ["error_rate_pct"]
    aggregation: "avg"
    filters:
      - field: "timestamp"
        operator: "between"
        value: "last-1-hour"
```text

## Formatting Patterns

### Currency Formatting

```yaml
settings:
  display: "number"
  format: "currency"
  currency: "USD"
  decimals: 0  # No cents for large numbers
  prefix: "$"
  suffix: ""
  compact: true  # $2.5M instead of $2,500,000
```text

**Examples**:

- `$2,458,392` (standard)
- `$2.5M` (compact)
- `$2.46M` (compact with decimals)

### Percentage Formatting

```yaml
settings:
  display: "percentage"
  decimals: 1  # One decimal place
  multiply_by_100: true  # If raw value is 0.923
  suffix: "%"
```text

**Examples**:

- `92.3%` (standard)
- `92%` (no decimals)
- `+8.5%` (with sign)

### Number Formatting

```yaml
settings:
  display: "number"
  format: "integer"  # or "decimal"
  decimals: 0
  thousands_separator: ","
  compact: false
```text

**Examples**:

- `12,453` (standard)
- `12.5K` (compact)
- `12.453K` (compact with decimals)

### Duration Formatting

```yaml
settings:
  display: "duration"
  format: "seconds"  # or "minutes", "hours"
  decimals: 1
```text

**Examples**:

- `2.5 seconds`
- `45 minutes`
- `3.2 hours`

## Layout Patterns

### Executive Summary Row (4 KPIs)

```yaml
# Row 0: Top-level KPIs (3 columns each = 12 total)
questions:
  - name: "Total Revenue"
    position: {row: 0, col: 0, sizeX: 3, sizeY: 2}

  - name: "Daily Active Users"
    position: {row: 0, col: 3, sizeX: 3, sizeY: 2}

  - name: "Contest Fill Rate"
    position: {row: 0, col: 6, sizeX: 3, sizeY: 2}

  - name: "House ROI %"
    position: {row: 0, col: 9, sizeX: 3, sizeY: 2}
```text

**Visual Layout**:

```text
┌────────┬────────┬────────┬────────┐
│ Total  │ Daily  │Contest │ House  │
│Revenue │ Active │  Fill  │ ROI %  │
│        │ Users  │  Rate  │        │
│$2.5M   │12,453  │ 92.3%  │-12.5%  │
│↑ 8.5%  │↑ 3.2%  │↓ 1.1%  │↑ 2.3%  │
└────────┴────────┴────────┴────────┘
```text

### Financial Dashboard (3 + Details)

```yaml
# Row 0: Top 3 financial KPIs (4 columns each)
questions:
  - name: "Total Handle"
    position: {row: 0, col: 0, sizeX: 4, sizeY: 2}

  - name: "Total Revenue"
    position: {row: 0, col: 4, sizeX: 4, sizeY: 2}

  - name: "House P&L"
    position: {row: 0, col: 8, sizeX: 4, sizeY: 2}

# Row 2: Detail breakdowns (6 columns each)
  - name: "Revenue by Tier"
    position: {row: 2, col: 0, sizeX: 6, sizeY: 4}

  - name: "Handle Trend"
    position: {row: 2, col: 6, sizeX: 6, sizeY: 4}
```text

### Operational Dashboard (6 KPIs)

```yaml
# Two rows of KPIs (2 columns each = 6 KPIs)
questions:
  - name: "Active Contests"
    position: {row: 0, col: 0, sizeX: 2, sizeY: 2}

  - name: "Fill Rate"
    position: {row: 0, col: 2, sizeX: 2, sizeY: 2}

  - name: "Cancel Rate"
    position: {row: 0, col: 4, sizeX: 2, sizeY: 2}

  - name: "Avg Fill Time"
    position: {row: 0, col: 6, sizeX: 2, sizeY: 2}

  - name: "Autodraft %"
    position: {row: 0, col: 8, sizeX: 2, sizeY: 2}

  - name: "Entries/Hour"
    position: {row: 0, col: 10, sizeX: 2, sizeY: 2}
```text

## Color Strategy

### Semantic Colors

Use colors that convey meaning:

| Meaning | Color | Hex | Use Case |
|---------|-------|-----|----------|
| Success/Good | Green | `#84BB4C` | Positive metrics, targets met |
| Warning | Orange | `#FFA500` | Caution, approaching threshold |
| Danger/Bad | Red | `#FF0000` | Critical alerts, targets missed |
| Neutral | Blue | `#509EE3` | No semantic meaning |
| Highlight | Yellow | `#F9CF48` | Call attention |

### Directional Colors

For metrics where direction matters:

**Positive is Good** (Revenue, Users, Fill Rate):

- Increase = Green
- Decrease = Red

**Negative is Good** (Costs, Errors, Cancel Rate):

- Increase = Red
- Decrease = Green

**Neutral** (Descriptive metrics):

- No color coding

## Advanced Patterns

### Sparkline in Scorecard

Show mini trend line alongside number.

```yaml
- name: "Revenue with Trend"
  type: "scalar"
  position: {row: 0, col: 0, sizeX: 4, sizeY: 2}
  visualization:
    type: "scalar"
    settings:
      display: "number"
      format: "currency"
      show_sparkline: true
      sparkline_color: "#509EE3"
  query:
    source: "finance_revenue_daily"
    dimensions: ["date_actual"]
    metrics: ["total_revenue"]
    aggregation: "sum"
    group_by: ["date_actual"]
    order_by: ["date_actual ASC"]
    filters:
      - field: "date_actual"
        operator: "between"
        value: "last-30-days"
```text

**Visual Result**:

```text
┌───────────────────────┐
│ Revenue               │
│                       │
│   $2,458,392          │
│   ↑ 8.5%              │
│   ╱╲    ╱╲  ╱         │ ← Sparkline
│  ╱  ╲  ╱  ╲╱          │
└───────────────────────┘
```text

### Progress Bar

Show progress toward goal as bar.

```yaml
- name: "Monthly Target Progress"
  type: "scalar"
  position: {row: 0, col: 0, sizeX: 4, sizeY: 2}
  visualization:
    type: "scalar"
    settings:
      display: "progress"
      goal_value: 5000000
      show_percentage: true
      bar_color: "#84BB4C"
      background_color: "#E8E8E8"
  query:
    source: "finance_revenue_daily"
    metrics: ["total_revenue"]
    aggregation: "sum"
    filters:
      - field: "date_actual"
        operator: "between"
        value: ["2025-10-01", "2025-10-31"]
```text

**Visual Result**:

```text
┌───────────────────────┐
│ Monthly Target        │
│ Progress              │
│                       │
│ $4,245,000 / $5.0M    │
│                       │
│ ████████████░░░░ 85%  │ ← Progress bar
└───────────────────────┘
```text

## Best Practices

### Content

1. **One metric per scorecard** - Don't try to show multiple metrics in one card
2. **Meaningful comparisons** - Always show context (vs. goal, vs. previous period)
3. **Clear labels** - Metric name should be immediately understandable
4. **Appropriate precision** - Don't show 8 decimal places for revenue

### Design

1. **Consistent sizing** - Use same size for similar metrics (usually 3x2 or 4x2)
2. **Logical order** - Most important metrics leftmost and top
3. **Color coding** - Use semantic colors for alerts
4. **White space** - Don't cram too much information

### Performance

1. **Pre-aggregated data** - Use marts, not raw fact tables
2. **Appropriate filters** - Always include date range
3. **Caching** - Enable caching for scorecards (they update infrequently)

### Accessibility

1. **Don't rely on color alone** - Use icons/symbols too (↑↓⚠)
2. **High contrast** - Ensure text is readable
3. **Screen reader text** - Include descriptions

---

**Related Documents**:

- [dashboard-layout-patterns.md](dashboard-layout-patterns.md) - Overall layout design
- [time-series-patterns.md](time-series-patterns.md) - Trend visualization
- [executive-dashboard-templates.md](executive-dashboard-templates.md) - Complete templates
