---
name: metric-audit
description: Audit metric definitions for consistency across dashboards, validate semantic layer alignment, and detect metric sprawl
model: sonnet
type: global
---

# Metric Consistency Audit

Comprehensive metric validation across dashboards, semantic layer, and ad-hoc reports.

## Purpose

Ensure metric consistency and prevent metric sprawl by:
1. Validating metric definitions across all sources (dbt, Metabase, notebooks)
2. Detecting inconsistencies in formulas, filters, and grain
3. Identifying duplicate/conflicting metric definitions
4. Verifying semantic layer alignment and usage
5. Providing remediation roadmap for consolidation

## Usage

```bash
# Audit specific metric across all sources
/metric-audit [METRIC_NAME]
/metric-audit revenue
/metric-audit "Active Users"

# Audit specific metric in specific dashboards
/metric-audit revenue --dashboards all
/metric-audit "Daily Active Users" --dashboards "Executive Dashboard,Finance Daily"

# Detect metric sprawl across all metrics
/metric-audit --all --detect-sprawl

# Check semantic layer coverage
/metric-audit --semantic-layer-check

# Full audit with business logic validation
/metric-audit revenue --validate-logic
```

## Workflow

**Agent Invocation**: This command invokes the `data-governance-agent` to perform comprehensive metric consistency auditing across all data sources.

### Phase 1: Metric Discovery & Inventory

1. **Identify all metric sources**:

   ```yaml
   Sources_to_Scan:
     - dbt_Semantic_Layer:
         Location: "models/metrics/*.yml"
         Priority: CANONICAL
     - Metabase_Dashboards:
         Location: "Metabase dashboard SQL queries"
         Priority: SECONDARY
     - Ad_Hoc_Reports:
         Location: "Jupyter notebooks, one-off queries"
         Priority: TERTIARY
     - Legacy_Reports:
         Location: "Deprecated dashboards, archived queries"
         Priority: ARCHIVE
   ```

2. **Extract metric definitions**:

- For dbt metrics: Parse `metrics.yml` files
- For Metabase: Query Metabase API for dashboard SQL
- For notebooks: Scan `.ipynb` and `.sql` files
- For legacy: Check archived documentation

3. **Normalize metric metadata**:

   ```yaml
   Metric_Metadata:
     - Name: "Revenue"
       Source: "dbt_metrics"
       SQL_Definition: "SUM(transaction_amount)"
       Grain: "daily"
       Filters: ["transaction_type = 'DEPOSIT'"]
       Dimensions: ["user_id", "transaction_date"]
       Unit: "dollars"
       Created_Date: "2024-01-15"
       Owner: "finance-team"
   ```

### Phase 2: Consistency Validation

For each metric concept (e.g., "Revenue", "Active Users"):

1. **Compare SQL definitions**:

   - Extract SELECT clause (aggregation function)
   - Extract FROM clause (source tables)
   - Extract WHERE clause (filters)
   - Extract GROUP BY clause (grain/dimensions)

2. **Identify inconsistencies**:

```yaml
   Inconsistency_Types:
     - Formula_Mismatch: "SUM(amount) vs SUM(transaction_amount)"
     - Filter_Mismatch: "type = 'DEPOSIT' vs type IN ('DEPOSIT', 'WITHDRAWAL')"
     - Grain_Mismatch: "daily vs monthly aggregation"
     - Unit_Mismatch: "dollars vs cents (100x difference)"
     - Dimension_Mismatch: "grouped by user vs grouped by user + cohort"
```

3. **Calculate consistency score**:

```text
   Consistency_Score = (Matching_Definitions / Total_Definitions) × 100%

   Rating_Scale:
     90-100%: ✅ EXCELLENT (minor differences only)
     70-89%:  ⚠️  NEEDS IMPROVEMENT (some inconsistencies)
     50-69%:  ❌ POOR (major inconsistencies)
     0-49%:   🚨 CRITICAL (definitions completely misaligned)
```

### Phase 3: Metric Sprawl Detection

1. **Identify duplicate metrics**:

   - Same business concept, different names
   - Example: "Revenue", "Total Revenue", "Gross Revenue" all calculate same thing
   - Recommendation: Consolidate to single canonical name

2. **Detect conflicting definitions**:

   - Same name, different calculation logic
   - Example: "Revenue" includes/excludes refunds in different dashboards
   - Severity: CRITICAL (business decisions based on wrong numbers)

3. **Find orphaned metrics**:

   - Metrics defined but not used in any dashboard
   - Metrics in deprecated dashboards
   - Recommendation: Archive or deprecate

4. **Calculate sprawl score**:

```text
   Sprawl_Score = (Unique_Metric_Definitions / Total_Metric_Instances) × 100%

   Targets:
     0-25%:   ✅ EXCELLENT (high consolidation)
     25-50%:  ⚠️  MODERATE (some duplication)
     50-75%:  ❌ HIGH (significant sprawl)
     75-100%: 🚨 CRITICAL (almost no consolidation)
```

### Phase 4: Semantic Layer Alignment

1. **Check dbt metrics coverage**:

   ```yaml
   Coverage_Analysis:
     Total_Metrics_in_Use: 45
     Defined_in_dbt: 30 (67%)
     Missing_from_dbt: 15 (33%)

     Missing_Metrics:
       - "Contest Participation Rate"
       - "Average Wallet Balance"
       - "Referral Conversion Rate"
       # ... etc
   ```

2. **Verify dashboard usage**:

   ```yaml
   Dashboard_Alignment:
     Total_Dashboards: 25
     Using_dbt_Metrics: 12 (48%)
     Bypassing_Semantic_Layer: 13 (52%)

     Bypassing_Dashboards:
       - Dashboard: "Executive Revenue"
         Reason: "Custom SQL with complex filters"
         Impact: "Revenue numbers differ from dbt metric by 15%"
         Recommendation: "Migrate to dbt metric, add filters to metric definition"
   ```

3. **Calculate alignment percentage**:

```text
   Alignment_Score = (Dashboards_Using_dbt / Total_Dashboards) × 100%

   Targets:
     80-100%: ✅ EXCELLENT (strong semantic layer adoption)
     60-79%:  ⚠️  MODERATE (some bypassing)
     40-59%:  ❌ LOW (significant bypassing)
     0-39%:   🚨 CRITICAL (semantic layer underutilized)
```

### Phase 5: Business Logic Validation

1. **Test metric calculations**:

   ```yaml
   Validation_Tests:
     - Test: "Daily revenue sums match monthly total"
       Query_Daily: "SELECT SUM(revenue) FROM fct_daily_revenue WHERE month = '2025-09'"
       Query_Monthly: "SELECT revenue FROM fct_monthly_revenue WHERE month = '2025-09'"
       Result: PASS/FAIL
       Discrepancy: "$X difference (Y%)"

     - Test: "Revenue by source sums to total revenue"
       Query_Total: "SELECT SUM(revenue) FROM fct_revenue"
       Query_Breakdown: "SELECT source, SUM(revenue) FROM fct_revenue GROUP BY source"
       Result: PASS/FAIL
       Discrepancy: "$X difference (Y%)"
   ```

2. **Verify edge cases**:

   ```yaml
   Edge_Case_Tests:
     - Null_Handling: "How are NULL values treated?"
     - Zero_Handling: "Are zero values excluded or included?"
     - Negative_Values: "Are refunds/withdrawals negative or separate?"
     - Timezone_Handling: "Which timezone for daily boundaries?"
     - Partial_Periods: "How are incomplete months handled?"
   ```

3. **Check temporal consistency**:

   - Do daily rollups match weekly aggregates?
   - Do weekly rollups match monthly aggregates?
   - Are there data gaps or duplicates?

4. **Validate dimensional slicing**:

   - Does revenue by segment sum to total revenue?
   - Does revenue by geography sum to total revenue?
   - Are there overlapping segments causing double-counting?

### Phase 6: Remediation Recommendations

1. **Immediate fixes** (critical issues):

   - Unit mismatches (100x differences)
   - Filter conflicts (inclusion/exclusion errors)
   - Broken metric references

2. **Short-term improvements** (1-2 sprints):

   - Migrate dashboards to dbt metrics
   - Consolidate duplicate metrics
   - Standardize metric naming

3. **Long-term initiatives** (strategic):

   - Implement metric governance policy
   - Build metric catalog with approval workflow
   - Add CI/CD validation for metric consistency
   - Establish metric ownership and SLAs

## Output Format

### Metric Audit Report

```yaml
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
METRIC CONSISTENCY AUDIT REPORT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Metric: Revenue
Audit Date: 2025-10-07
Auditor: Claude Code (metric-audit command)
Consistency Score: 75% ⚠️  NEEDS IMPROVEMENT

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 DEFINITIONS FOUND: 4
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[1] SOURCE: dbt_metrics
    Location: models/metrics/finance_metrics.yml
    Status: ✅ CANONICAL (preferred source of truth)

    Definition:
      SELECT: SUM(transaction_amount)
      FROM: {{ ref('fct_wallet_transactions') }}
      WHERE: transaction_type = 'DEPOSIT'
      GRAIN: daily
      DIMENSIONS: user_id, transaction_date
      UNIT: dollars
      OWNER: finance-team
      CREATED: 2024-01-15

[2] SOURCE: metabase_dashboard (Executive Revenue Dashboard)
    Location: Dashboard ID 42, Card ID 156
    Status: ❌ INCONSISTENT (includes withdrawals)

    Definition:
      SELECT: SUM(amount)
      FROM: wallet_transactions
      WHERE: type IN ('DEPOSIT', 'WITHDRAWAL')
      GRAIN: daily
      DIMENSIONS: user_id, date
      UNIT: dollars

    🚨 ISSUES:
      - Filter mismatch: Includes WITHDRAWAL transactions
      - Impact: Revenue 15% higher than dbt metric ($175k vs $150k)
      - Severity: HIGH
      - Recommendation: Update WHERE clause to match dbt metric

[3] SOURCE: metabase_dashboard (Finance Daily Dashboard)
    Location: Dashboard ID 58, Card ID 203
    Status: ⚠️  UNIT MISMATCH (cents vs dollars)

    Definition:
      SELECT: SUM(transaction_amount) / 100
      FROM: wallet_transactions
      WHERE: transaction_type = 'DEPOSIT'
      GRAIN: daily
      DIMENSIONS: user_id, transaction_date
      UNIT: cents (converted to dollars via /100)

    ⚠️  ISSUES:
      - Unit conversion applied (assumes source in cents)
      - Impact: Revenue displayed 100x lower ($1,500 vs $150k)
      - Severity: CRITICAL
      - Root Cause: Source data changed from cents to dollars in Jan 2024
      - Recommendation: Remove /100 conversion, standardize to dollars

[4] SOURCE: finance_notebook (Monthly Revenue Analysis)
    Location: notebooks/finance/monthly_revenue.ipynb
    Status: ⚠️  GRAIN MISMATCH (monthly vs daily)

    Definition:
      SELECT: SUM(CASE WHEN type = 'DEPOSIT' THEN amount ELSE 0 END)
      FROM: wallet_transactions
      WHERE: None
      GRAIN: monthly (aggregated from daily)
      DIMENSIONS: month
      UNIT: dollars

    ⚠️  ISSUES:
      - Different aggregation grain (monthly vs daily)
      - Impact: Cannot compare directly to daily dashboards
      - Severity: MEDIUM
      - Recommendation: Add monthly grain to dbt metrics

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 CONSISTENCY ISSUES (3 found)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Issue #1: Filter Inconsistency
  Affected: Executive Revenue Dashboard
  Type: Filter Mismatch
  Impact: Revenue overstated by 15% ($25k/day)
  Severity: HIGH

  Details:
    - dbt metric: WHERE transaction_type = 'DEPOSIT'
    - Dashboard: WHERE type IN ('DEPOSIT', 'WITHDRAWAL')
    - Result: Withdrawals incorrectly counted as revenue

  Recommendation:
    1. Update Executive Dashboard SQL to exclude withdrawals
    2. Add validation test to ensure dashboard matches dbt metric
    3. Document expected variance if withdrawals are intentional

Issue #2: Unit Mismatch
  Affected: Finance Daily Dashboard
  Type: Unit Conversion Error
  Impact: Revenue displayed 100x lower than actual
  Severity: CRITICAL

  Details:
    - Source data changed from cents to dollars in Jan 2024
    - Dashboard still applying /100 conversion
    - Finance team making decisions on incorrect numbers

  Recommendation:
    1. IMMEDIATE: Remove /100 conversion from Finance Daily Dashboard
    2. Add unit validation test (revenue > $1000/day sanity check)
    3. Standardize all revenue metrics to dollars in dbt
    4. Add comment documenting unit expectations

Issue #3: Grain Mismatch
  Affected: Monthly Revenue Analysis Notebook
  Type: Temporal Grain Difference
  Impact: Cannot compare monthly aggregates to daily dashboards
  Severity: MEDIUM

  Details:
    - Notebook uses monthly grain
    - dbt metric only provides daily grain
    - Manual rollup introduces risk of errors

  Recommendation:
    1. Add monthly grain to dbt revenue metric
    2. Migrate notebook to use dbt monthly metric
    3. Add validation: monthly metric = SUM(daily metrics)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📈 METRIC SPRAWL ANALYSIS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Total Revenue Metric Instances: 4
Unique Definitions: 3
Sprawl Score: 75% ❌ HIGH SPRAWL

Recommendation: Consolidate to single dbt metric, deprecate 3 duplicates

Duplication Breakdown:
  - Exact duplicates: 0
  - Near-duplicates (minor filter differences): 2
  - Completely different (grain/unit differences): 1

Consolidation Plan:
  1. Keep: dbt_metrics definition (canonical)
  2. Migrate: Executive Dashboard → use dbt metric
  3. Fix: Finance Daily Dashboard → remove unit conversion
  4. Enhance: Add monthly grain to dbt metric for notebook

Expected Benefit:
  - Single source of truth
  - 75% reduction in maintenance effort
  - Eliminates 15% variance between dashboards

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 SEMANTIC LAYER ALIGNMENT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Metric Definition:
  Defined in dbt: ✅ YES
  dbt Metrics File: models/metrics/finance_metrics.yml
  Created: 2024-01-15
  Owner: finance-team

Dashboard Usage Analysis:
  Total Dashboards Using Revenue Metric: 3
  Using dbt Metric: 0 (0%)
  Bypassing Semantic Layer: 3 (100%)

  Alignment Score: 0% 🚨 CRITICAL (no adoption)

Bypassing Dashboards:
  [1] Executive Revenue Dashboard
      Reason: Custom SQL with withdrawal filter
      Impact: 15% variance from dbt metric
      Migration Effort: LOW (update WHERE clause)

  [2] Finance Daily Dashboard
      Reason: Unit conversion logic
      Impact: 100x display error
      Migration Effort: LOW (remove /100, use dbt metric)

  [3] Monthly Revenue Notebook
      Reason: Monthly grain not available in dbt
      Impact: Manual rollup risk
      Migration Effort: MEDIUM (add monthly metric to dbt first)

Migration Roadmap:
  Phase 1 (Week 1):
    - Add monthly grain to dbt revenue metric
    - Update Executive Dashboard to use dbt metric
    - Fix Finance Daily Dashboard unit conversion

  Phase 2 (Week 2):
    - Migrate notebook to dbt monthly metric
    - Add validation tests (dashboard = dbt metric ± 1%)
    - Document semantic layer usage policy

  Expected Outcome:
    - 100% semantic layer adoption for revenue
    - Single source of truth
    - Zero variance across dashboards

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ BUSINESS LOGIC VALIDATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Test #1: Daily Revenue Sums Match Monthly Total
  Status: ❌ FAIL
  Expected Monthly Total: $4,500,000 (Sept 2025)
  Actual (SUM of daily): $4,275,000
  Discrepancy: -$225,000 (-5%)

  Root Cause Analysis:
    - Weekend data missing in daily aggregation
    - Sept 6-7 (Sat-Sun): $75k missing
    - Sept 13-14 (Sat-Sun): $75k missing
    - Sept 20-21 (Sat-Sun): $75k missing

  Recommendation:
    - Fix daily revenue model to include weekends
    - Add data quality test: "revenue > 0 for all dates in month"
    - Document weekend transaction handling

Test #2: Revenue by Source Sums to Total Revenue
  Status: ✅ PASS
  Total Revenue: $4,500,000

  Breakdown:
    - Mobile App: $2,700,000 (60%)
    - Web Platform: $1,350,000 (30%)
    - API/Partners: $450,000 (10%)
    - Total: $4,500,000 (100%) ✅

  Validation: All sources accounted for, no double-counting

Test #3: Null Handling Consistency
  Status: ⚠️  WARNING

  Null Value Treatment:
    - dbt metric: Excludes NULLs (SUM ignores NULL)
    - Executive Dashboard: Excludes NULLs (explicit WHERE amount IS NOT NULL)
    - Finance Dashboard: **Includes NULLs as zero** (COALESCE(amount, 0))

  Impact:
    - 0.1% variance (300 transactions/month with NULL amounts)
    - $15k difference/month

  Recommendation:
    - Standardize: Exclude NULLs across all metrics
    - Update Finance Dashboard to match dbt metric
    - Add data quality test: "transaction_amount should not be NULL"

Test #4: Timezone Consistency
  Status: ✅ PASS

  All metrics use: America/New_York (ET)
  Daily boundaries: Consistent across all sources
  No timezone-related discrepancies detected

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🛠️  REMEDIATION PLAN
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

IMMEDIATE (Fix this week - CRITICAL):
  ✓ Priority 1: Fix Finance Daily Dashboard unit conversion
    - Remove /100 conversion
    - Validate: revenue > $100k/day (sanity check)
    - Estimated Time: 30 minutes
    - Assigned To: @finance-team

  ✓ Priority 2: Update Executive Dashboard filter
    - Change WHERE clause to exclude withdrawals
    - Add comment documenting DEPOSIT-only logic
    - Estimated Time: 1 hour
    - Assigned To: @analytics-team

SHORT TERM (Complete within 2 sprints):
  □ Task 1: Add monthly grain to dbt revenue metric
    - Create monthly_revenue metric in finance_metrics.yml
    - Validate: SUM(daily) = monthly
    - Estimated Time: 4 hours
    - Assigned To: @data-engineer

  □ Task 2: Migrate 3 dashboards to dbt metrics
    - Executive Dashboard → use dbt daily metric
    - Finance Dashboard → use dbt daily metric
    - Notebook → use dbt monthly metric
    - Add validation tests for each
    - Estimated Time: 1 sprint
    - Assigned To: @analytics-team

  □ Task 3: Fix weekend data gaps
    - Update daily revenue model
    - Add data quality test for date continuity
    - Estimated Time: 3 hours
    - Assigned To: @data-engineer

  □ Task 4: Standardize NULL handling
    - Document NULL treatment policy
    - Update Finance Dashboard to exclude NULLs
    - Add dbt test: transaction_amount not null
    - Estimated Time: 2 hours
    - Assigned To: @data-quality-team

LONG TERM (Strategic initiatives - 3-6 months):
  □ Initiative 1: Metric Governance Policy
    - All new metrics MUST be defined in dbt first
    - Dashboard SQL can only use dbt metrics (no custom SQL)
    - Approval workflow for new metric creation
    - Metric ownership and SLA documentation

  □ Initiative 2: Metric Catalog
    - Build searchable metric catalog (dbt Docs + custom UI)
    - Include business definitions, SQL, owners, SLAs
    - Version history and deprecation policy

  □ Initiative 3: CI/CD Validation
    - Add pre-commit hook: validate metric references
    - Add CI test: dashboard SQL matches dbt metric (±1%)
    - Add monitoring: alert on >5% variance

  □ Initiative 4: Semantic Layer Enforcement
    - Deprecate direct SQL in Metabase (read-only dbt metrics)
    - Implement MetricFlow for advanced metric logic
    - Train analysts on semantic layer usage

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 SUMMARY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Metric: Revenue
Overall Health: ⚠️  NEEDS IMPROVEMENT (75% consistency score)

Key Findings:
  ❌ 3 inconsistent definitions found
  🚨 1 critical issue (100x unit error)
  ⚠️  2 high-priority issues (filter/grain mismatch)
  📈 75% metric sprawl (high duplication)
  🎯 0% semantic layer adoption (all dashboards bypass dbt)

Expected Impact After Remediation:
  ✅ 100% consistency score
  ✅ Single source of truth (dbt metric)
  ✅ Zero variance across dashboards
  ✅ 100% semantic layer adoption
  ✅ 75% reduction in maintenance effort

Next Steps:
  1. Review and approve remediation plan
  2. Assign tasks to responsible teams
  3. Execute immediate fixes (this week)
  4. Track progress on short-term tasks (2 sprints)
  5. Plan long-term governance initiatives

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Examples

### Example 1: Single Metric Audit (Revenue)

```bash
/metric-audit revenue
```

**Output**:

- Scans dbt metrics, Metabase dashboards, notebooks
- Finds 4 revenue definitions
- Identifies 3 inconsistencies (filter, unit, grain)
- Calculates 75% consistency score
- Provides immediate fixes and migration roadmap

### Example 2: Metric Sprawl Detection

```bash
/metric-audit --all --detect-sprawl
```

**Output**:

```yaml
Metric_Sprawl_Report:
  Total_Metrics_Scanned: 67
  Unique_Metric_Concepts: 45
  Total_Metric_Instances: 127
  Sprawl_Score: 65% (HIGH)

  Top_Sprawl_Offenders:
    - Metric: "Active Users"
      Instances: 12
      Unique_Definitions: 8
      Sprawl: 67%
      Recommendation: "Consolidate to 2 metrics (daily, monthly)"

    - Metric: "Revenue"
      Instances: 4
      Unique_Definitions: 3
      Sprawl: 75%
      Recommendation: "Consolidate to single dbt metric"

    - Metric: "Contest Participation"
      Instances: 7
      Unique_Definitions: 5
      Sprawl: 71%
      Recommendation: "Standardize participation definition"

  Consolidation_Opportunities:
    - Potential Reduction: 127 → 50 instances (-61%)
    - Effort: 3 sprints
    - Expected Benefit: "Single source of truth for all metrics"
```

### Example 3: Semantic Layer Coverage Check

```bash
/metric-audit --semantic-layer-check
```

**Output**:

```yaml
Semantic_Layer_Coverage_Report:
  Total_Metrics_in_Use: 67
  Defined_in_dbt: 45 (67%)
  Missing_from_dbt: 22 (33%)

  Dashboard_Adoption:
    Total_Dashboards: 35
    Using_dbt_Metrics: 18 (51%)
    Bypassing_Semantic_Layer: 17 (49%)
    Alignment_Score: 51% (MODERATE)

  Missing_Metrics_Priority_List:
    HIGH_PRIORITY (used in 5+ dashboards):
      - "Contest Participation Rate" (8 dashboards)
      - "Average Wallet Balance" (6 dashboards)
      - "Referral Conversion Rate" (5 dashboards)

    MEDIUM_PRIORITY (used in 2-4 dashboards):
      - "Weekly Active Users" (4 dashboards)
      - "Churn Rate" (3 dashboards)
      - "LTV per User" (2 dashboards)

    LOW_PRIORITY (used in 1 dashboard):
      - 16 metrics (likely candidates for deprecation)

  Migration_Roadmap:
    Phase_1: Add 3 high-priority metrics to dbt
    Phase_2: Migrate 8 dashboards to use new dbt metrics
    Phase_3: Add 5 medium-priority metrics to dbt
    Phase_4: Migrate remaining 9 dashboards
    Phase_5: Deprecate 16 low-priority metrics

    Expected_Timeline: 6 sprints
    Expected_Alignment: 90%+ (excellent)
```

### Example 4: Full Audit with Business Logic Validation

```bash
/metric-audit revenue --validate-logic
```

**Output**: (Full report as shown above with all 6 phases)

## Integration Points

### With Other Commands

- **`/dashboard-audit`**: Use metric audit findings to fix dashboard inconsistencies
- **`/semantic-layer-check`**: Deep dive on dbt metrics coverage
- **`/data-quality-check`**: Validate metric calculations against known values

### With Agents

This command primarily invokes the **data-governance-agent** for:
- dbt metrics implementation guidance
- Dashboard SQL migration and optimization
- Business logic validation and testing
- Metric consistency validation
- Semantic layer alignment checks

## Success Criteria

- **Consistency Score**: Target 90%+ for all critical metrics
- **Sprawl Score**: Target <25% (high consolidation)
- **Semantic Layer Alignment**: Target 80%+ dashboard adoption
- **Zero Critical Issues**: No unit mismatches or filter conflicts
- **Single Source of Truth**: All dashboards reference dbt metrics

## Error Handling

- **Metabase API unavailable**: Scan local dashboard exports or skip Metabase
- **dbt metrics not found**: Prompt to create dbt metrics first
- **No metric definitions found**: Suggest metric name variations or broader search
- **Validation tests fail**: Provide detailed root cause analysis and remediation steps

---

**Related Commands**: `/dashboard-audit`, `/semantic-layer-check`, `/data-quality-check`
**Primary Agent**: `data-governance-agent`
**Documentation**: `docs/metrics/metric-governance.md`, `docs/metrics/semantic-layer-adoption.md`
