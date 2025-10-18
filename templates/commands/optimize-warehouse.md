---
name: optimize-warehouse
description: Analyze Snowflake warehouse utilization and provide right-sizing, auto-suspend, and multi-cluster recommendations
model: sonnet
type: global
---

# Warehouse Optimization & Right-Sizing

Optimize Snowflake warehouse configuration by analyzing utilization patterns, providing sizing recommendations, and identifying cost-saving opportunities.

## Usage

```bash
/optimize-warehouse [WAREHOUSE_NAME] [--analysis-period DAYS]
/optimize-warehouse PROD_DBT
/optimize-warehouse BI_METABASE --analysis-period 30
/optimize-warehouse --all
```

## Options

**Warehouse Selection**:
- `WAREHOUSE_NAME` - Specific warehouse to analyze
- `--all` - Analyze all warehouses in the account

**Analysis Period**:
- `--analysis-period 7` - Last 7 days (default)
- `--analysis-period 30` - Last 30 days (recommended for trend analysis)
- `--analysis-period 90` - Quarterly analysis (best for seasonal patterns)

## Workflow

### Phase 1: Utilization Data Collection

1. **Task(subagent_type="cost-optimization-agent")** - Query warehouse metrics:
   - Average CPU and memory load
   - Queue load and query wait times
   - Query execution time trends
   - Idle time and auto-suspend efficiency
   - Concurrency patterns (avg and peak)
   - Credit consumption by warehouse size

2. **Queries to Execute**:
   ```sql
   -- Warehouse utilization metrics
   SELECT
       warehouse_name,
       AVG(avg_running) as avg_load,
       MAX(avg_running) as peak_load,
       AVG(avg_queued_load) as avg_queue_load,
       SUM(credits_used) as total_credits,
       COUNT(DISTINCT DATE(start_time)) as analysis_days
   FROM snowflake.account_usage.warehouse_load_history
   WHERE start_time >= DATEADD('day', -<analysis_period>, CURRENT_TIMESTAMP())
     AND warehouse_name = '<WAREHOUSE_NAME>'
   GROUP BY warehouse_name;

   -- Idle time analysis
   SELECT
       warehouse_name,
       SUM(CASE WHEN avg_running = 0 THEN 1 ELSE 0 END) / COUNT(*) * 100 as idle_percentage
   FROM snowflake.account_usage.warehouse_load_history
   WHERE start_time >= DATEADD('day', -<analysis_period>, CURRENT_TIMESTAMP())
   GROUP BY warehouse_name;

   -- Concurrency patterns
   SELECT
       warehouse_name,
       AVG(avg_running) as avg_concurrency,
       MAX(avg_running) as peak_concurrency
   FROM snowflake.account_usage.warehouse_load_history
   WHERE start_time >= DATEADD('day', -<analysis_period>, CURRENT_TIMESTAMP())
   GROUP BY warehouse_name;
   ```

### Phase 2: Performance Analysis

**cost-optimization-agent** analyzes utilization patterns:

1. **Sizing Health Assessment**:
   - **Underutilized** (< 50% avg load) → Downsize candidate
   - **Healthy** (50-80% avg load) → Well-sized
   - **Overloaded** (> 80% avg load) → Upsize candidate
   - **Queueing** (queries waiting) → Needs multi-cluster or larger size

2. **Performance Bottleneck Identification**:
   - Query queue wait times
   - Execution time degradation trends
   - Concurrency ceiling reached
   - Memory spilling incidents

3. **Efficiency Metrics**:
   - Credits per query executed
   - Idle time ratio
   - Auto-suspend effectiveness
   - Warehouse start/stop frequency

### Phase 3: Cost-Benefit Calculation

For each sizing recommendation, calculate:

1. **Current State**:
   - Warehouse size and cost (credits/hour)
   - Monthly credit consumption
   - Average monthly cost
   - Queries executed per day

2. **Recommended State**:
   - New warehouse size
   - Projected credit consumption
   - Projected monthly cost
   - Expected performance impact

3. **ROI Analysis**:
   - Monthly savings (or cost increase)
   - Performance gain/loss (% faster/slower)
   - Business impact assessment
   - Implementation effort required
   - Payback period

### Phase 4: Configuration Recommendations

#### 1. Size Recommendations

**Upsize Scenarios**:
- Current load > 80% consistently
- Queue wait times > 1 minute
- Peak concurrency exceeds capacity
- Critical business queries slowing down

**Downsize Scenarios**:
- Current load < 50% consistently
- No queueing observed
- Idle time > 30%
- Non-critical workloads with flexible SLAs

**Sizing Options**:
- XS → S (2x increase)
- S → M (2x increase)
- M → L (2x increase)
- L → XL (2x increase)
- Or reverse for downsizing

#### 2. Auto-Suspend Optimization

**Recommendations Based on Idle Patterns**:
- **High idle time (> 30%)**: Reduce auto-suspend from 10 min to 5 min or 3 min
- **Moderate idle (15-30%)**: Reduce to 5 min
- **Low idle (< 15%)**: Keep current setting or increase to reduce start/stop overhead
- **Development warehouses**: Aggressive auto-suspend (1-2 min)
- **Production warehouses**: Balanced auto-suspend (5 min)

**Considerations**:
- Start/stop overhead (typically 3-5 seconds)
- Query frequency patterns
- Cost of idle credits vs resume overhead

#### 3. Multi-Cluster Recommendations

**Enable Multi-Cluster When**:
- High concurrency (> 10 concurrent queries)
- Queueing observed during peak hours
- Variable workload patterns (peak/off-peak)
- Multiple user groups competing for resources

**Configuration Options**:
- **Min Clusters**: Start with 1 (or 2 for always-on production)
- **Max Clusters**: Based on peak concurrency (typically 3-5)
- **Scaling Policy**:
  - **Standard**: Faster scale-up, more responsive (recommended for production)
  - **Economy**: Slower scale-up, cost-optimized (recommended for BI/analytics)

**Cost Impact Example**:
- Single LARGE warehouse: $4/hour
- Multi-cluster (1-3 LARGE, Economy mode): $4-12/hour during peaks
- Benefit: Eliminate queue wait times, improve user experience

### Phase 5: Query Optimization Opportunities

**Task(subagent_type="snowflake-sql-expert")** - Identify expensive queries:

1. **Top Queries by Cost**:
   ```sql
   SELECT
       query_text,
       COUNT(*) as execution_count,
       AVG(execution_time) as avg_execution_ms,
       SUM(credits_used_cloud_services) as total_credits,
       warehouse_name
   FROM snowflake.account_usage.query_history
   WHERE start_time >= DATEADD('day', -<analysis_period>, CURRENT_TIMESTAMP())
     AND warehouse_name = '<WAREHOUSE_NAME>'
   GROUP BY query_text, warehouse_name
   ORDER BY total_credits DESC
   LIMIT 20;
   ```

2. **Inefficient Query Patterns**:
   - Full table scans (no clustering or pruning)
   - Cartesian joins (missing join conditions)
   - Excessive data spilling to disk
   - Repeated similar queries (caching opportunities)
   - SELECT * without column pruning

3. **Optimization Recommendations**:
   - Add clustering keys for range-filtered queries
   - Create materialized views for repeated aggregations
   - Optimize join order and conditions
   - Enable result caching for identical queries
   - Convert full refreshes to incremental patterns

### Phase 6: Implementation Plan

Generate step-by-step implementation with risk assessment:

#### Low-Risk Changes (Immediate Implementation)
1. **Auto-Suspend Adjustments**:
   - Change requires seconds, no downtime
   - Monitor for 1 week to validate savings
   - Rollback if suspend/resume overhead > 5%

2. **Query Result Caching**:
   - Enable USE_CACHED_RESULT = TRUE
   - No performance risk, immediate savings

#### Medium-Risk Changes (Test First)
1. **Warehouse Downsizing**:
   - Test during low-traffic period
   - Monitor query performance for 24 hours
   - Rollback if execution times increase > 20%

2. **Multi-Cluster Enablement**:
   - Start with conservative settings (1-2 clusters)
   - Monitor cost and queueing for 1 week
   - Adjust max clusters based on actual usage

#### High-Risk Changes (Architecture Review Required)
1. **Major Size Changes** (> 2x upsize/downsize):
   - Coordinate with data engineering team
   - Test with representative workload
   - Have rollback plan ready

2. **Query Rewrites & Clustering**:
   - Validate with snowflake-sql-expert agent
   - Test in development environment
   - Measure performance impact before production

## Output Format

```yaml
Warehouse_Optimization_Report:
  Warehouse: PROD_DBT
  Current_Size: LARGE
  Analysis_Period: "30 days (2025-09-08 to 2025-10-07)"

  Utilization_Metrics:
    Average_Load: 68%
    Peak_Load: 92%
    Queue_Load: 12% (2-5 min avg wait during peak)
    Idle_Time: 15% (excessive for production workload)
    Concurrency: 8 queries avg, 15 queries peak
    Total_Credits_Used: 1,440 credits
    Cost_Per_Credit: $2.50
    Total_Cost: $3,600

  Sizing_Recommendation:
    Current: LARGE ($4/hour, $2,880/month at 100% usage)
    Recommended: LARGE (no change)
    Reason: "Load at 68% is healthy, peak at 92% requires current capacity"
    Alternative: "Consider XLARGE during peak hours (7-9 AM) if queueing becomes critical"
    Risk_Level: Low (status quo)

  Configuration_Optimization:
    Auto_Suspend:
      Current: 10 minutes
      Recommended: 5 minutes
      Rationale: "15% idle time indicates opportunities for faster suspend"
      Savings: "$120/month (reduce idle credits by 50%)"
      Risk_Level: Low
      Implementation: "ALTER WAREHOUSE PROD_DBT SET AUTO_SUSPEND = 300;"

    Multi_Cluster:
      Current: Single cluster
      Recommended: Enable multi-cluster (1-3 clusters, Economy mode)
      Rationale: "Peak concurrency (15 queries) causes queueing"
      Cost_Impact: "+$50/month during peak hours (2 hours/day avg scale-up)"
      Performance_Gain: "Eliminate 2-5 min queue wait times"
      Risk_Level: Medium
      Implementation: |
        ALTER WAREHOUSE PROD_DBT SET
          MIN_CLUSTER_COUNT = 1
          MAX_CLUSTER_COUNT = 3
          SCALING_POLICY = 'ECONOMY';

  Query_Optimization_Opportunities:
    Total_Potential_Savings: "$180/month"

    Top_Opportunities:
      - Query_Pattern: "SELECT * FROM fct_wallet_transactions WHERE transaction_date > '2024-01-01'"
        Current_Cost: "$15/day (45 executions × 900 credits/month)"
        Issue: "Full table scan (no clustering key)"
        Fix: "Add clustering key on transaction_date"
        Savings: "$120/month (80% faster execution, reduce credits by 80%)"
        Implementation: "ALTER TABLE fct_wallet_transactions CLUSTER BY (transaction_date);"
        Risk_Level: Low (performance-only improvement)

      - Query_Pattern: "mart_daily_revenue full refresh"
        Current_Cost: "$8/day (24 executions × 480 credits/month)"
        Issue: "Full refresh when incremental possible"
        Fix: "Convert to incremental model in dbt"
        Savings: "$60/month (reduce from full to incremental)"
        Implementation: "Coordinate with data-engineer for dbt model update"
        Risk_Level: Medium (requires testing)

  Cost_Benefit_Analysis:
    Current_Monthly_Cost: "$3,600"
    Optimized_Monthly_Cost: "$3,530 (base) + $180 savings from queries = $3,350"
    Total_Monthly_Savings: "$250"
    Implementation_Effort: "4 hours total (2 hrs config + 2 hrs query optimization)"
    Annual_Savings: "$3,000"
    ROI: "750x (savings of $3,000/year for 4 hours work)"
    Payback_Period: "Immediate (changes take effect within minutes)"

  Implementation_Plan:
    Phase_1_Low_Risk_Immediate:
      Timeline: "Week 1"
      Tasks:
        - "Reduce auto-suspend from 10 min to 5 min"
        - "Monitor for 1 week, ensure no performance degradation"
        - "Validate savings in billing dashboard"
      Expected_Savings: "$120/month"
      Rollback_Criteria: "If suspend/resume overhead > 5% of execution time"

    Phase_2_Medium_Risk_Testing:
      Timeline: "Week 2-3"
      Tasks:
        - "Enable multi-cluster (1-3 clusters, Economy mode) in development warehouse first"
        - "Test during peak hours (7-9 AM) for 3 days"
        - "If successful, enable in production warehouse"
        - "Monitor cost and queueing for 1 week"
      Expected_Savings: "Queueing elimination (user experience gain)"
      Expected_Cost: "+$50/month"
      Rollback_Criteria: "If monthly cost increase > $100"

    Phase_3_Query_Optimization:
      Timeline: "Week 4-6"
      Tasks:
        - "Add clustering key to fct_wallet_transactions (coordinate with data-engineer)"
        - "Test clustering performance in development"
        - "Promote to production after validation"
        - "Convert mart_daily_revenue to incremental (validate with architect)"
      Expected_Savings: "$180/month"
      Rollback_Criteria: "No rollback needed for clustering (performance-only)"

  Rollback_Procedures:
    Auto_Suspend: "ALTER WAREHOUSE PROD_DBT SET AUTO_SUSPEND = 600; (increase back to 10 min)"
    Multi_Cluster: "ALTER WAREHOUSE PROD_DBT SET MIN_CLUSTER_COUNT = 1 MAX_CLUSTER_COUNT = 1; (disable multi-cluster)"
    Clustering: "ALTER TABLE fct_wallet_transactions SUSPEND RECLUSTER; (stop clustering, no data impact)"

  Monitoring_Metrics:
    Track_Weekly:
      - "Average warehouse load (%)"
      - "Queue wait times (minutes)"
      - "Idle time (%)"
      - "Credit consumption (total credits/week)"
      - "Cost ($USD/week)"

    Alert_Thresholds:
      - "Average load > 85% (consider upsize)"
      - "Queue wait > 3 minutes (enable multi-cluster or upsize)"
      - "Idle time > 30% (reduce auto-suspend further)"
      - "Weekly cost increase > 10% (investigate cause)"
```

## Examples

### Example 1: Production Warehouse Analysis

```bash
/optimize-warehouse PROD_DBT --analysis-period 30
```

**Expected Output**:
- 30-day utilization trends and patterns
- Sizing recommendation (upsize/downsize/no change)
- Auto-suspend optimization (10 min → 5 min saves $120/month)
- Multi-cluster recommendation (enable for peak concurrency)
- Query optimization opportunities (clustering, incremental models)
- Total savings: $250/month with 4 hours implementation effort

### Example 2: BI Warehouse Optimization

```bash
/optimize-warehouse BI_METABASE
```

**Expected Output**:
- Analyzes Metabase query patterns
- Likely underutilized (45% avg load, 10% peak)
- Recommends downsize from LARGE to MEDIUM
- Savings: $1,440/month (50% cost reduction)
- Performance impact: Minimal (queries < 5 seconds increase to < 7 seconds)
- Recommendation: Implement immediately (low risk)

### Example 3: All Warehouses Review

```bash
/optimize-warehouse --all --analysis-period 30
```

**Expected Output**:
- Portfolio-wide warehouse optimization report
- Identifies underutilized warehouses (downsize candidates)
- Identifies overloaded warehouses (upsize or multi-cluster candidates)
- Prioritizes recommendations by ROI (highest savings first)
- Total savings potential: $500-1,000/month across 5 warehouses
- Implementation roadmap with phased rollout

## Success Criteria

1. **Cost Reduction**: Achieve 10-30% monthly warehouse cost savings
2. **Performance Maintained**: No query execution time degradation > 10%
3. **Queueing Eliminated**: Reduce queue wait times to < 30 seconds
4. **Utilization Optimized**: Target 60-80% average warehouse load
5. **Idle Time Minimized**: Reduce idle time to < 15% of warehouse runtime

## Error Handling

**Missing Permissions**:
- Requires `ACCOUNTADMIN` or `MONITOR USAGE` role for account_usage views
- Fallback: Use information_schema.warehouse_load_history (90-day limit)

**Insufficient Data**:
- If analysis_period > available data, use maximum available period
- Warn user if < 7 days of data available (trends unreliable)

**Warehouse Not Found**:
- List all available warehouses for user to select
- Suggest `--all` option to analyze entire portfolio

## Integration Points

- **cost-optimization-agent**: Utilization analysis and cost-benefit calculations
- **snowflake-sql-expert**: Query optimization recommendations
- **data-engineer**: dbt model optimization (incremental, clustering)
- **architect**: Architecture review for major sizing changes

## Related Commands

- `/analyze-query-performance` - Deep-dive into specific query optimization
- `/snowflake-cost-analysis` - Account-wide cost analysis
- `/dbt-performance-tuning` - dbt model optimization

---

**Model**: sonnet (optimization and cost analysis focus)
**Type**: global (available in all projects)
**Agent Integration**: cost-optimization-agent (primary), snowflake-sql-expert (query analysis)
