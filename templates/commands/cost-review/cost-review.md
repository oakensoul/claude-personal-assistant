---
name: cost-review
description: Analyze Snowflake costs, track budget compliance, identify optimization opportunities, and forecast spend
model: sonnet
type: global
args:
  period:
    description: Time period for cost analysis (current-month, last-month, last-7-days, last-30-days, custom)
    required: false
  breakdown-by:
    description: Cost breakdown dimension (warehouse, team, domain, user, query-type)
    required: false
---

# Snowflake Cost Review & Analysis

Comprehensive monthly cost review workflow for analyzing Snowflake spend, tracking budget compliance, identifying optimization opportunities, and forecasting future costs.

## Purpose

This command provides executive-level cost visibility and actionable optimization recommendations by:

1. Breaking down costs by warehouse, team, domain, or query type
2. Tracking budget compliance and variance analysis
3. Identifying top expensive queries and optimization opportunities
4. Analyzing storage costs and cleanup recommendations
5. Forecasting month-end spend and detecting anomalies

## Usage

```bash
# Default: current month, warehouse breakdown
/cost-review

# Specific period
/cost-review --period last-month
/cost-review --period last-7-days
/cost-review --period last-30-days

# Custom breakdown dimension
/cost-review --period current-month --breakdown-by team
/cost-review --period last-month --breakdown-by domain
/cost-review --period last-7-days --breakdown-by warehouse
/cost-review --period current-month --breakdown-by user
/cost-review --period last-month --breakdown-by query-type
```

## Options

### Time Periods

- `current-month` - Month-to-date analysis (default)
- `last-month` - Previous calendar month
- `last-7-days` - Rolling 7-day window
- `last-30-days` - Rolling 30-day window
- `custom` - Specify custom date range (will prompt)

### Breakdown Dimensions

- `warehouse` - Cost by warehouse (PROD_DBT, DEV, BI, etc.) [default]
- `team` - Cost attribution by team tags
- `domain` - Business domain (finance, contests, partners)
- `user` - Top users by compute consumption
- `query-type` - dbt, Metabase, ad-hoc, ETL

## Workflow

### Phase 1: Initialize Cost Review

1. **Validate Parameters**
   - Confirm time period (default: current-month)
   - Confirm breakdown dimension (default: warehouse)
   - Calculate start/end dates for analysis period

2. **Set Context**
   - Determine budget baseline for comparison
   - Identify cost thresholds and alert criteria
   - Prepare ACCOUNT_USAGE queries

### Phase 2: Data Collection

**Invoke cost-optimization-agent** to gather Snowflake cost data:

```yaml
Task(subagent_type="cost-optimization-agent", prompt="""
Query Snowflake ACCOUNT_USAGE for {period} cost data:

1. **Warehouse Credit Consumption**
   - Query: WAREHOUSE_METERING_HISTORY
   - Metrics: Credits consumed, warehouse size, execution time
   - Group by: Warehouse name, day

2. **Query Execution Costs**
   - Query: QUERY_HISTORY
   - Metrics: Credits, execution time, rows processed
   - Join with: Warehouse metadata
   - Top 50 most expensive queries

3. **Storage Costs**
   - Query: STORAGE_USAGE, TABLE_STORAGE_METRICS
   - Metrics: Active storage, time-travel, fail-safe
   - Calculate: Storage costs (active, time-travel, fail-safe)

4. **Serverless Feature Costs**
   - Query: AUTOMATIC_CLUSTERING_HISTORY, MATERIALIZED_VIEW_REFRESH_HISTORY
   - Metrics: Clustering credits, MV refresh credits
   - Breakdown by: Table, feature type

5. **Calculate Totals**
   - Sum total credits consumed
   - Convert to dollar spend (credit rate: $1/credit for analysis)
   - Calculate daily burn rate
""")
```

**Expected Output:**

- Daily credit consumption timeseries
- Warehouse utilization metrics
- Storage cost breakdown
- Top expensive queries with context
- Total spend and burn rate

### Phase 3: Cost Breakdown Analysis

Analyze costs by selected breakdown dimension:

#### Warehouse Breakdown (default)

```yaml
For_Each_Warehouse:
  Metrics:
    - Total credits consumed
    - Percentage of total spend
    - Average utilization (query time / warehouse uptime)
    - Peak vs off-peak usage
    - Auto-suspend compliance

  Status_Assessment:
    - ✅ HEALTHY: 60-80% utilization, reasonable cost
    - ⚠️  UNDERUTILIZED: <50% utilization (downsize candidate)
    - ⚠️  OVERUTILIZED: >85% utilization (upsize candidate)
    - 🔴 IDLE: <10% utilization (shutdown candidate)
```

#### Team Breakdown

```yaml
Team_Attribution:
  Method: Warehouse tags, query comments, user patterns
  Metrics:
    - Credits attributed to team
    - Cost allocation percentage
    - Primary warehouses used
    - Query patterns (dbt, Metabase, ad-hoc)

  Chargeback_Report:
    - Team-specific cost invoice
    - Month-over-month trending
    - Budget compliance per team
```

#### Domain Breakdown

```yaml
Business_Domain_Costs:
  Domains: [finance, contests, partners, shared]
  Attribution:
    - Models tagged with domain tags
    - Domain-specific warehouses
    - Cross-domain shared costs allocation

  Metrics:
    - Domain-specific spend
    - Cost per domain capability
    - ROI analysis (cost vs business value)
```

#### User Breakdown

```yaml
Top_Users_by_Cost:
  Metrics:
    - Credits consumed per user
    - Query patterns (efficiency)
    - Warehouse usage
    - Ad-hoc vs scheduled queries

  Identify:
    - Top 10 users by spend
    - Inefficient query patterns
    - Training opportunities
```

#### Query Type Breakdown

```yaml
Query_Type_Classification:
  Categories:
    - dbt: Scheduled transformations
    - Metabase: BI dashboard queries
    - Ad-hoc: Manual analyst queries
    - ETL: Data pipeline jobs

  Metrics:
    - Cost per query type
    - Query efficiency (credits per row processed)
    - Optimization opportunities per type
```

### Phase 4: Budget Compliance Analysis

1. **Budget Comparison**

   ```yaml
   Budget_Metrics:
     - Actual spend vs budgeted spend
     - Variance amount and percentage
     - Budget utilization percentage
     - Days remaining in period
   ```

2. **Variance Analysis**
   - Identify cost drivers for over/under budget
   - Categorize variances (expected vs unexpected)
   - Calculate variance impact by dimension

3. **Budget Alerts**

   ```yaml
   Alert_Criteria:
     🔴 CRITICAL: >95% budget consumed with >7 days remaining
     ⚠️  WARNING: >85% budget consumed, trending over
     ✅ ON_TRACK: <85% budget, trending within limits
     💚 UNDER: <70% budget, significant savings
   ```

### Phase 5: Optimization Opportunities

**Invoke cost-optimization-agent** for savings analysis:

```yaml
Task(subagent_type="cost-optimization-agent", prompt="""
Identify Snowflake cost optimization opportunities:

1. **Warehouse Right-Sizing**
   - Find warehouses with <50% utilization → Downsize candidates
   - Find warehouses with >85% utilization → Upsize candidates
   - Estimate savings from right-sizing

2. **Auto-Suspend Optimization**
   - Identify warehouses with idle time >5 minutes
   - Calculate wasted credits from late suspension
   - Recommend optimal auto-suspend settings

3. **Query Optimization**
   - Top 20 most expensive queries
   - Queries with full table scans
   - Queries eligible for incremental materialization
   - Queries needing clustering keys
   - Estimate savings per optimization

4. **Storage Cleanup**
   - Tables with excessive time-travel retention
   - Unused tables (no queries in 30 days)
   - Fail-safe data eligible for archival
   - Estimate storage cost savings

5. **Incremental Materialization**
   - dbt models doing full refreshes
   - Models eligible for incremental strategy
   - Estimate compute savings

6. **Clustering Optimization**
   - High-volume tables without clustering
   - Tables with poor clustering depth
   - Estimate query performance improvement

Calculate total potential monthly savings across all opportunities.
""")
```

**Expected Output:**

- Prioritized list of optimization recommendations
- Estimated savings per recommendation
- Implementation effort (low/medium/high)
- Total potential savings amount

### Phase 6: Forecast & Trending

1. **Cost Trending Analysis**

   ```yaml
   Trending_Metrics:
     - Week-over-week change (amount and percentage)
     - Month-over-month change (vs previous month)
     - Year-over-year change (if historical data available)
     - Identify cost trend (increasing/decreasing/stable)
   ```

2. **Anomaly Detection**

   ```yaml
   Anomaly_Criteria:
     - Daily spend >2x average (spike)
     - Daily spend <0.5x average (drop)
     - Unusual warehouse activity
     - Unexpected query patterns

   For_Each_Anomaly:
     - Date and magnitude
     - Root cause investigation
     - One-time vs recurring issue
     - Action required (if any)
   ```

3. **Month-End Forecast**

   ```yaml
   Forecasting_Method:
     - Calculate average daily burn rate
     - Adjust for known upcoming events
     - Factor in trending patterns
     - Project to end of month

   Forecast_Output:
     - Projected month-end spend
     - Confidence level (based on variance)
     - Budget compliance forecast
     - Risk assessment (over/under budget risk)
   ```

4. **Quarterly Run Rate**
   - Project quarterly spend based on current trends
   - Annual run rate extrapolation
   - Budget planning recommendations

### Phase 7: Executive Summary Report

Generate comprehensive cost review report:

```yaml
Cost_Review_Executive_Summary:

  Header:
    Period: "{Month Year} (MTD through {Date})"
    Total_Spend: "${amount}"
    Budget: "${budget_amount}"
    Variance: "${variance_amount} ({variance_pct}% {over/under} budget)"
    Forecast_Month_End: "${forecast} ({forecast_pct}% {over/under} budget)"

  Cost_Breakdown:
    # By selected dimension (warehouse, team, domain, etc.)
    Dimension_Items:
      - Name: "{dimension_value}"
        Credits: {credits}
        Cost: "${cost}"
        Percentage: {pct}%
        Utilization: {util}%  # For warehouses
        Status: {status_icon} {status_message}

  Storage_Costs:
    Active_Storage: "${amount} ({pct}%)"
    Time_Travel: "${amount} ({pct}%)"
    Fail_Safe: "${amount} ({pct}%)"
    Total: "${total} ({pct}%)"

  Top_Expensive_Queries:
    - Query: "{query_description}"
      Credits: {credits}
      Frequency: {frequency}x/{period}
      Optimization: "{recommendation} (save ~${savings}/{period})"

  Optimization_Opportunities:
    Total_Potential_Savings: "${total_savings}/month ({savings_pct}%)"

    Recommendations:
      - Priority: HIGH
        Action: "{specific_action}"
        Savings: "${monthly_savings}/month"
        Effort: {LOW/MEDIUM/HIGH}

      - Priority: MEDIUM
        Action: "{specific_action}"
        Savings: "${monthly_savings}/month"
        Effort: {LOW/MEDIUM/HIGH}

  Budget_Status:
    Status: {icon} {status_message}
    Forecast: "${forecast} ({pct}% of budget)"
    Risk: {LOW/MEDIUM/HIGH} - {risk_description}

  Trending_Analysis:
    Week_over_Week: "{+/-}{pct}% (${amount} {increase/decrease})"
    Month_over_Month: "{+/-}{pct}% (${amount} {increase/decrease} vs {prev_month})"
    Driver_of_Change: "{primary_driver_description}"

  Anomalies_Detected:
    - Date: "{date}"
      Spike: "{+/-}${amount} ({multiplier}x daily average)"
      Cause: "{root_cause}"
      Action: "{action_required}"
```

### Phase 8: Output & Next Actions

1. **Display Executive Summary**
   - Show formatted report in terminal
   - Highlight key metrics and alerts

2. **Save Report**

   ```bash
   # Save to project documentation
   File: docs/cost-analysis/cost-review-{YYYY-MM}.md
   Format: Markdown with YAML frontmatter
   ```

3. **Generate Recommendations Document**

   ```bash
   # Detailed optimization plan
   File: docs/cost-analysis/optimization-recommendations-{YYYY-MM}.md
   Contents:
     - Prioritized recommendations
     - Implementation steps
     - Estimated savings
     - Effort and timeline
   ```

4. **Create Follow-Up Tasks** (if needed)
   - High-priority optimizations → Create JIRA tickets
   - Budget alerts → Notify stakeholders
   - Anomalies requiring investigation → Assign owners

## Error Handling

```yaml
Error_Scenarios:

  Missing_Snowflake_Access:
    Error: "Cannot access ACCOUNT_USAGE schema"
    Action: "Verify Snowflake credentials and ACCOUNTADMIN role"
    Fallback: "Use cached data from last successful run"

  Invalid_Period:
    Error: "Period parameter not recognized"
    Action: "Prompt user for valid period selection"
    Valid_Options: [current-month, last-month, last-7-days, last-30-days, custom]

  No_Budget_Baseline:
    Error: "Budget baseline not configured"
    Action: "Prompt user for monthly budget amount"
    Save_To: "~/.claude/config/snowflake-budget-config.json"

  Insufficient_Data:
    Error: "Not enough historical data for trending analysis"
    Action: "Skip trending section, note in report"
    Minimum_Required: "7 days of data"

  Cost_Spike_Alert:
    Trigger: "Daily spend >2x average"
    Action: "Flag in report, investigate top queries for that day"
    Notify: "Include in anomalies section with root cause"
```

## Success Criteria

- ✅ Complete cost breakdown by selected dimension
- ✅ Budget variance analysis with clear over/under status
- ✅ Top 10 optimization opportunities with savings estimates
- ✅ Storage cost breakdown and cleanup recommendations
- ✅ Month-end forecast with confidence level
- ✅ Anomaly detection and root cause analysis
- ✅ Executive summary report saved to docs/cost-analysis/
- ✅ Actionable recommendations with implementation steps

## Examples

### Example 1: Monthly Cost Review (Default)

```bash
/cost-review
```

**Output:**

```yaml
Cost_Review_Report:
  Period: "October 2025 (MTD through 10/07)"
  Total_Spend: "$8,450"
  Budget: "$10,000"
  Variance: "-$1,550 (15.5% under budget)"
  Forecast_Month_End: "$9,200 (8% under budget)"

  Cost_Breakdown_by_Warehouse:
    - Warehouse: PROD_DBT
      Credits: 3,250
      Cost: "$3,250"
      Percentage: 38.5%
      Utilization: 72%
      Status: ✅ HEALTHY

    - Warehouse: BI_METABASE
      Credits: 2,100
      Cost: "$2,100"
      Percentage: 24.9%
      Utilization: 45%
      Status: ⚠️  UNDERUTILIZED (consider downsizing)

    - Warehouse: DEV_SANDBOX
      Credits: 1,800
      Cost: "$1,800"
      Percentage: 21.3%
      Utilization: 88%
      Status: ⚠️  HIGH UTILIZATION (consider upsizing)

  Storage_Costs:
    Active_Storage: "$950 (11.2%)"
    Time_Travel: "$150 (1.8%)"
    Fail_Safe: "$100 (1.2%)"
    Total: "$1,200 (14.2%)"

  Top_Expensive_Queries:
    - Query: "mart_daily_revenue full refresh"
      Credits: 85
      Frequency: 24x/day (hourly)
      Optimization: "Change to incremental model (save ~$50/month)"

    - Query: "stg_segment_tracks full scan"
      Credits: 62
      Frequency: 8x/day
      Optimization: "Add clustering key on event_timestamp (save ~$40/month)"

  Optimization_Opportunities:
    Total_Potential_Savings: "$1,250/month (12.5%)"

    Recommendations:
      - Priority: HIGH
        Action: "Downsize BI_METABASE warehouse from L to M"
        Savings: "$400/month"
        Effort: LOW

      - Priority: HIGH
        Action: "Convert 5 marts to incremental materialization"
        Savings: "$250/month"
        Effort: MEDIUM

      - Priority: MEDIUM
        Action: "Implement auto-suspend 5 min for DEV warehouses"
        Savings: "$300/month"
        Effort: LOW

      - Priority: MEDIUM
        Action: "Archive time-travel data older than 7 days"
        Savings: "$150/month"
        Effort: LOW

      - Priority: LOW
        Action: "Add clustering keys to 3 high-volume tables"
        Savings: "$150/month"
        Effort: HIGH

  Budget_Status:
    Status: ✅ ON TRACK
    Forecast: "$9,200 (92% of budget)"
    Risk: LOW - Comfortably under budget

  Trending_Analysis:
    Week_over_Week: "+8% ($650 increase)"
    Month_over_Month: "-5% ($450 decrease vs Sept)"
    Driver_of_Change: "New dbt models in contests domain"

  Anomalies_Detected:
    - Date: "2025-10-03"
      Spike: "+$450 (3.5x daily average)"
      Cause: "Backfill of fct_contest_entries for Q3 data"
      Action: "One-time spike, no ongoing concern"

✅ Cost review report saved to: docs/cost-analysis/cost-review-2025-10.md
✅ Optimization recommendations saved to: docs/cost-analysis/optimization-recommendations-2025-10.md
```

### Example 2: Team Chargeback Report

```bash
/cost-review --period last-month --breakdown-by team
```

**Output:**

```yaml
Cost_Review_Report:
  Period: "September 2025"
  Total_Spend: "$9,150"
  Budget: "$10,000"
  Variance: "-$850 (8.5% under budget)"

  Cost_Breakdown_by_Team:
    - Team: Data Engineering
      Credits: 4,200
      Cost: "$4,200"
      Percentage: 45.9%
      Primary_Warehouses: [PROD_DBT, DEV_SANDBOX]
      Query_Patterns: "75% dbt, 15% ad-hoc, 10% ETL"
      Status: ✅ WITHIN TEAM BUDGET

    - Team: Analytics
      Credits: 2,800
      Cost: "$2,800"
      Percentage: 30.6%
      Primary_Warehouses: [BI_METABASE, ANALYTICS_WH]
      Query_Patterns: "60% Metabase, 30% ad-hoc, 10% dbt"
      Status: ✅ WITHIN TEAM BUDGET

    - Team: Finance
      Credits: 1,500
      Cost: "$1,500"
      Percentage: 16.4%
      Primary_Warehouses: [FINANCE_WH]
      Query_Patterns: "50% scheduled, 40% ad-hoc, 10% reporting"
      Status: ✅ WITHIN TEAM BUDGET

  Team_Chargeback_Invoices:
    - Team: Data Engineering
      Invoice_Amount: "$4,200"
      Budget_Allocated: "$4,500"
      Variance: "-$300 (6.7% under)"

    - Team: Analytics
      Invoice_Amount: "$2,800"
      Budget_Allocated: "$3,000"
      Variance: "-$200 (6.7% under)"

    - Team: Finance
      Invoice_Amount: "$1,500"
      Budget_Allocated: "$2,000"
      Variance: "-$500 (25% under)"

✅ Team chargeback report saved to: docs/cost-analysis/team-chargeback-2025-09.md
```

### Example 3: Cost Spike Investigation

```bash
/cost-review --period last-7-days --breakdown-by query-type
```

**Output:**

```yaml
Cost_Review_Report:
  Period: "Last 7 Days (2025-10-01 to 2025-10-07)"
  Total_Spend: "$2,450"
  Daily_Average: "$350"

  Cost_Breakdown_by_Query_Type:
    - Query_Type: dbt (scheduled)
      Credits: 1,200
      Cost: "$1,200"
      Percentage: 49%
      Query_Count: 1,680
      Avg_Credits_per_Query: 0.71
      Status: ✅ NORMAL

    - Query_Type: Ad-hoc (analyst queries)
      Credits: 850
      Cost: "$850"
      Percentage: 35%
      Query_Count: 245
      Avg_Credits_per_Query: 3.47
      Status: ⚠️  SPIKE DETECTED

    - Query_Type: Metabase (dashboards)
      Credits: 250
      Cost: "$250"
      Percentage: 10%
      Query_Count: 8,400
      Avg_Credits_per_Query: 0.03
      Status: ✅ NORMAL

    - Query_Type: ETL (data pipelines)
      Credits: 150
      Cost: "$150"
      Percentage: 6%
      Query_Count: 48
      Avg_Credits_per_Query: 3.13
      Status: ✅ NORMAL

  Anomaly_Investigation:
    - Date: "2025-10-03"
      Query_Type: Ad-hoc
      Spike: "+$450 (3.2x normal ad-hoc spend)"
      Top_Expensive_Queries:
        - User: analyst@example.com
          Query: "Full table scan on segment_tracks (6 months)"
          Credits: 180
          Recommendation: "Add date filter, use incremental mart"

        - User: bi-team@example.com
          Query: "Cross-database join with no filter"
          Credits: 125
          Recommendation: "Use pre-joined mart, add filters"

      Action: "Training opportunity for analyst team on query optimization"

✅ Cost spike analysis saved to: docs/cost-analysis/cost-spike-investigation-2025-10-03.md
```

## Integration Points

- **Snowflake ACCOUNT_USAGE**: Primary data source for cost metrics
- **cost-optimization-agent**: Expert analysis and recommendations
- **Budget Configuration**: `~/.claude/config/snowflake-budget-config.json`
- **Cost Analysis Docs**: `docs/cost-analysis/` for historical reports
- **JIRA Integration**: Auto-create tickets for high-priority optimizations

## Related Commands

- `/warehouse-audit` - Deep-dive warehouse performance analysis
- `/query-optimization` - Optimize specific expensive queries
- `/storage-cleanup` - Storage cost reduction workflow

## Notes

- Cost data refreshes in ACCOUNT_USAGE with ~1-2 hour latency
- Credit rate defaults to $1/credit (adjust in budget config if different)
- Recommendations prioritized by savings amount and implementation effort
- Historical reports enable month-over-month trending analysis
- Anomaly detection requires at least 7 days of baseline data

---

**Agent Invocations:**

- `cost-optimization-agent` → Snowflake cost analysis and optimization recommendations
- `data-engineer` → Query optimization guidance
- `architect` → Data model efficiency review
