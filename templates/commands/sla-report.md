---
name: sla-report
description: Generate SLA compliance reports, track error budgets, and identify SLA breach risks with executive dashboards
model: sonnet
type: global
---

# SLA Compliance Reporting

Comprehensive SLA monitoring and reporting for data platform service level agreements.

## Purpose

Generate detailed SLA compliance reports including:
1. SLA compliance tracking (data freshness, availability, accuracy)
2. Error budget consumption analysis
3. SLA breach detection and alerting
4. Trend analysis and forecasting
5. Executive dashboards and stakeholder reports

**Agent Invocation**: This command invokes the `datadog-observability-engineer` agent to collect monitoring data, analyze SLA compliance, calculate error budgets, and generate comprehensive SLA reports.

## Usage

```bash
/sla-report [--period PERIOD] [--domain DOMAIN] [--format FORMAT]
/sla-report --period last-week --domain finance
/sla-report --period current-month --format executive
/sla-report --all --export
```

## Arguments

```yaml
period:
  description: "Reporting time period"
  required: false
  default: "current-week"
  options:
    - today
    - yesterday
    - last-week
    - current-week
    - last-month
    - current-month
    - last-quarter

domain:
  description: "Business domain filter"
  required: false
  default: "all"
  options:
    - all
    - finance
    - contests
    - partners
    - operations

format:
  description: "Report output format"
  required: false
  default: "technical"
  options:
    - executive     # High-level summary for leadership
    - technical     # Detailed metrics for engineering
    - stakeholder   # Domain-specific business context

export:
  description: "Export report to file"
  required: false
  type: boolean
  default: false
```

## SLA Definitions

### Finance Data SLA (4-hour freshness)
- **Target**: All finance data < 4 hours old
- **Measurement**: Last refresh timestamp vs current time
- **Error Budget**: 99.5% uptime (< 1.8 hours downtime/month)
- **Breach Severity**: P1 if > 4 hours stale
- **Business Impact**: Finance team unable to reconcile daily transactions

### Executive Dashboard SLA (95% availability)
- **Target**: Dashboards load successfully 95%+ of time
- **Measurement**: HTTP 200 responses vs total requests
- **Error Budget**: 5% failure rate (< 36 hours/month)
- **Breach Severity**: P2 if < 95% availability
- **Business Impact**: Leadership unable to access key metrics

### Data Quality SLA (99% test pass rate)
- **Target**: 99%+ dbt tests pass
- **Measurement**: Passing tests / total tests
- **Error Budget**: 1% test failures allowed
- **Breach Severity**: P2 if < 99% pass rate
- **Business Impact**: Data accuracy concerns, audit risk

### Contest Data SLA (15-minute freshness)
- **Target**: Contest results < 15 minutes old
- **Measurement**: Event timestamp vs ingestion timestamp
- **Error Budget**: 99.9% uptime (< 45 min downtime/month)
- **Breach Severity**: P0 if > 15 minutes stale during live events
- **Business Impact**: Users see incorrect/stale contest standings

## Workflow

### Phase 1: SLA Metric Collection

1. **Initialize Reporting Context**
   ```yaml
   Collect_Parameters:
     - Reporting period (from args)
     - Domain filter (from args)
     - Report format (from args)
     - Current timestamp (for calculations)
   ```

2. **Query SLI Data Sources**

   Task with `datadog-observability-engineer` agent to collect:

   **Data Freshness Metrics**:
   - Query dbt logs for last successful run timestamps
   - Calculate time since last refresh for each critical model
   - Identify stale data (exceeds SLA threshold)

   **Dashboard Availability Metrics**:
   - Query Metabase access logs (if available)
   - Calculate uptime percentage from monitoring
   - Identify downtime incidents

   **Data Quality Metrics**:
   - Query dbt test results from logs
   - Calculate pass rate (passing tests / total tests)
   - Identify failing test patterns

   **Pipeline Performance Metrics**:
   - Query Snowflake query history
   - Calculate pipeline execution times
   - Identify performance degradation

3. **Calculate SLA Compliance Percentages**
   ```yaml
   For_Each_SLA:
     Actual_Performance = successful_measurements / total_measurements
     Compliance_Percentage = (Actual_Performance / SLA_Target) × 100
     Status =
       - EXCELLENT if Actual >= SLA_Target + 1%
       - HEALTHY if Actual >= SLA_Target
       - DEGRADED if Actual < SLA_Target but >= SLA_Target - 2%
       - CRITICAL if Actual < SLA_Target - 2%
   ```

### Phase 2: Error Budget Analysis

For each SLA, calculate error budget consumption:

1. **Calculate Monthly Error Budget**
   ```yaml
   Error_Budget_Calculation:
     Budget_Allowance = (1 - SLA_Target) × Time_Period

     Examples:
       Finance_Freshness_SLA:
         Target: 99.5%
         Budget: (1 - 0.995) × 730 hours/month = 3.65 hours/month

       Dashboard_Availability_SLA:
         Target: 95.0%
         Budget: (1 - 0.95) × 730 hours/month = 36.5 hours/month

       Data_Quality_SLA:
         Target: 99.0%
         Budget: (1 - 0.99) × 1000 tests = 10 failed tests allowed
   ```

2. **Calculate Consumed Budget**
   ```yaml
   Budget_Consumption:
     Consumed = Actual_Downtime / Total_Time_Period
     Remaining = Budget_Allowance - Consumed
     Percentage_Consumed = (Consumed / Budget_Allowance) × 100

     Alert_Thresholds:
       - 50% consumed → INFO (monitoring)
       - 80% consumed → WARNING (action recommended)
       - 100% consumed → CRITICAL (SLA breach)
   ```

3. **Project End-of-Period Status**
   ```yaml
   Forecasting:
     Current_Burn_Rate = Consumed / Days_Elapsed
     Projected_Total = Current_Burn_Rate × Total_Days_In_Period
     Projected_Budget_Status = Projected_Total / Budget_Allowance

     Risk_Assessment:
       - LOW if Projected < 70%
       - MEDIUM if Projected 70-90%
       - HIGH if Projected 90-100%
       - CRITICAL if Projected > 100%
   ```

### Phase 3: Breach Detection

1. **Identify SLA Breaches**
   ```yaml
   Breach_Detection:
     For_Each_Measurement:
       If Measurement < SLA_Target:
         Classify_Breach:
           - Breach_ID (unique identifier)
           - SLA_Name
           - Occurred_At (timestamp)
           - Duration (time below SLA)
           - Severity (P0/P1/P2 based on SLA definition)
   ```

2. **Classify Breach Severity**
   ```yaml
   Severity_Classification:
     P0_Critical:
       - Contest data > 15 min stale during live events
       - Finance data > 8 hours stale
       - All dashboards down > 4 hours

     P1_High:
       - Finance data 4-8 hours stale
       - Dashboard availability < 90%
       - Data quality < 97%

     P2_Medium:
       - Finance data 2-4 hours stale
       - Dashboard availability 90-95%
       - Data quality 97-99%
   ```

3. **Link to Incident Reports**
   ```yaml
   Incident_Correlation:
     For_Each_Breach:
       Search_Incident_Database:
         - Match by timestamp (±30 minutes)
         - Match by affected system/domain
         - Link Breach_ID to Incident_ID

       Enrich_With_Incident_Data:
         - Root cause analysis
         - Resolution steps taken
         - Time to resolution
         - Post-incident review status
   ```

4. **Calculate Business Impact**
   ```yaml
   Impact_Analysis:
     For_Each_Breach:
       Business_Impact =
         - Affected_Users (count)
         - Affected_Domains (finance, contests, etc.)
         - Business_Operations_Impacted (list)
         - Revenue_Impact (if quantifiable)
         - Compliance_Risk (regulatory concerns)
   ```

### Phase 4: Trend Analysis

1. **Week-over-Week Compliance Trends**
   ```yaml
   WoW_Analysis:
     For_Each_SLA:
       Current_Week_Compliance = Calculate()
       Last_Week_Compliance = Query_Historical_Data()
       Change = Current - Last

       Trend_Direction:
         - IMPROVING if Change > +0.5%
         - STABLE if Change between -0.5% and +0.5%
         - DEGRADING if Change < -0.5%

       Trend_Indicator:
         - "↑" for IMPROVING
         - "→" for STABLE
         - "↓" for DEGRADING
   ```

2. **Month-over-Month Error Budget Consumption**
   ```yaml
   MoM_Budget_Analysis:
     For_Each_SLA:
       Current_Month_Consumption = Calculate()
       Last_Month_Consumption = Query_Historical_Data()

       Budget_Trend:
         - "Improving" if Current < Last (less budget consumed)
         - "Stable" if within ±10%
         - "Degrading" if Current > Last + 10%
   ```

3. **Identify Degrading SLAs**
   ```yaml
   Degradation_Detection:
     For_Each_SLA:
       Historical_Data = Query_Last_4_Weeks()
       Calculate_Trend_Line:
         - Linear regression on compliance percentages
         - Slope indicates trend direction

       If Slope < -0.1:  # Declining trend
         Flag_As_Degrading:
           - SLA_Name
           - Degradation_Rate (% per week)
           - Root_Cause_Analysis (if known)
           - Recommended_Actions
   ```

4. **Forecast Breach Risk**
   ```yaml
   Breach_Forecasting:
     For_Each_SLA:
       If Trend = DEGRADING:
         Extrapolate_Trend:
           - Days_Until_Breach = Calculate_Intersection(Trend_Line, SLA_Target)
           - Breach_Probability = Calculate_Based_On_Historical_Variance()

         Risk_Level:
           - IMMINENT if Days_Until_Breach < 7
           - HIGH if Days_Until_Breach 7-14
           - MEDIUM if Days_Until_Breach 14-30
           - LOW if Days_Until_Breach > 30
   ```

### Phase 5: Report Generation

Generate reports based on requested format:

#### Executive Format
```yaml
Executive_Report:
  Summary:
    - Overall compliance percentage (all SLAs)
    - Total breaches this period
    - Error budget consumption trend
    - Top 3 risks

  Business_Impact:
    - User-facing impact summary
    - Revenue/compliance implications
    - Stakeholder communication needs

  Action_Items:
    - High-level recommendations
    - Required investments (time/resources)
    - Expected ROI on improvements

  Length: 1-2 pages max
  Audience: C-level, VP Engineering, Product Leadership
```

#### Technical Format
```yaml
Technical_Report:
  Detailed_Metrics:
    - Per-SLA compliance breakdown
    - Error budget consumption charts
    - Breach timeline with root causes
    - System performance metrics

  Root_Cause_Analysis:
    - Common failure patterns
    - Infrastructure bottlenecks
    - Code/pipeline issues

  Recommendations:
    - Specific technical improvements
    - Monitoring enhancements
    - Architecture changes needed
    - Automation opportunities

  Length: 5-10 pages
  Audience: Data Engineering, DevOps, Platform Teams
```

#### Stakeholder Format
```yaml
Stakeholder_Report:
  Domain_Specific:
    - Filter to requested domain (finance, contests, etc.)
    - Business context for that domain
    - Domain-specific impact analysis

  Operational_Impact:
    - How SLA breaches affected their workflows
    - Data trustworthiness concerns
    - Recommended compensating controls

  Communication:
    - Non-technical language
    - Visual charts/graphs
    - Clear action items for stakeholders

  Length: 2-3 pages
  Audience: Finance Team, Product Managers, Business Analysts
```

## Output Format

```yaml
SLA_Compliance_Report:
  Report_Metadata:
    Period: "October 2025 (Week 1)"
    Report_Generated: "2025-10-07 16:00 UTC"
    Domain_Filter: "all" | "finance" | "contests" | "partners"
    Report_Type: "executive" | "technical" | "stakeholder"

  Executive_Summary:
    Overall_Health: "GOOD (94% compliance)" | "DEGRADED" | "CRITICAL"
    Total_Breaches: 2
    Error_Budget_Status: "65% consumed (WARNING)"
    Key_Achievements:
      - "Contest data maintaining 99.95% freshness"
      - "Data quality improving (+0.8% WoW)"
    Areas_of_Concern:
      - "Finance SLA degrading (-0.9% WoW)"
      - "Error budget 65% consumed with 75% of month remaining"

  SLA_Summary:
    - SLA_Name: "Finance Data Freshness (4-hour)"
      Target: "99.5%"
      Actual: "98.2%"
      Status: "⚠️  DEGRADED (below target)"
      Error_Budget:
        Total_Monthly: "3.65 hours"
        Consumed: "2.37 hours (65%)"
        Remaining: "1.28 hours (35%)"
        Projected_End_of_Month: "90% consumed"
      Breaches_This_Period: 2
      Trend: "↓ Declining (was 99.1% last week)"
      Forecast: "HIGH RISK - likely to breach again"

    - SLA_Name: "Executive Dashboard Availability (95%)"
      Target: "95.0%"
      Actual: "97.5%"
      Status: "✅ HEALTHY"
      Error_Budget:
        Total_Monthly: "36.5 hours"
        Consumed: "5.5 hours (15%)"
        Remaining: "31 hours (85%)"
        Projected_End_of_Month: "20% consumed"
      Breaches_This_Period: 0
      Trend: "→ Stable"
      Forecast: "LOW RISK"

    - SLA_Name: "Data Quality Tests (99% pass rate)"
      Target: "99.0%"
      Actual: "99.7%"
      Status: "✅ HEALTHY"
      Error_Budget:
        Total_Monthly: "10 failed tests"
        Consumed: "3 failed tests (30%)"
        Remaining: "7 failed tests (70%)"
        Projected_End_of_Month: "40% consumed"
      Breaches_This_Period: 0
      Trend: "↑ Improving (was 98.9% last week)"
      Forecast: "LOW RISK"

    - SLA_Name: "Contest Data Freshness (15-minute)"
      Target: "99.9%"
      Actual: "99.95%"
      Status: "✅ EXCELLENT"
      Error_Budget:
        Total_Monthly: "43.8 minutes"
        Consumed: "2.2 minutes (5%)"
        Remaining: "41.6 minutes (95%)"
        Projected_End_of_Month: "7% consumed"
      Breaches_This_Period: 0
      Trend: "→ Stable"
      Forecast: "LOW RISK"

  Breach_Details:
    - Breach_ID: "SLA-2025-10-03-001"
      SLA: "Finance Data Freshness"
      Occurred_At: "2025-10-03 14:30 UTC"
      Detected_At: "2025-10-03 18:45 UTC"
      Duration: "6.5 hours"
      Severity: "P1"
      Business_Impact:
        Description: "Finance team unable to reconcile daily revenue"
        Affected_Users: 12
        Affected_Domains: ["finance"]
        Operations_Impacted:
          - "Daily revenue reconciliation"
          - "Wallet balance verification"
          - "Transaction audit trail"
        Revenue_Impact: "None (manual workaround used)"
        Compliance_Risk: "LOW (resolved within 24 hours)"
      Root_Cause: "dbt build failure due to unexpected schema change in source table"
      Resolution:
        Actions_Taken:
          - "Schema change reverted by data engineering"
          - "dbt models updated to handle new schema"
          - "Full data refresh executed"
        Resolved_At: "2025-10-03 21:00 UTC"
        Time_To_Resolution: "6.5 hours"
        Incident_ID: "INC-2025-10-03-001"
        Post_Incident_Review: "Pending"

    - Breach_ID: "SLA-2025-10-05-002"
      SLA: "Finance Data Freshness"
      Occurred_At: "2025-10-05 09:00 UTC"
      Detected_At: "2025-10-05 13:15 UTC"
      Duration: "5.2 hours"
      Severity: "P1"
      Business_Impact:
        Description: "Stale wallet balance data"
        Affected_Users: 15
        Affected_Domains: ["finance", "operations"]
        Operations_Impacted:
          - "Real-time wallet balance reporting"
          - "User account verification"
        Revenue_Impact: "None"
        Compliance_Risk: "MEDIUM (audit trail gap)"
      Root_Cause: "Snowflake warehouse suspended due to credit limit reached"
      Resolution:
        Actions_Taken:
          - "Snowflake warehouse credits increased"
          - "Warehouse auto-resume enabled"
          - "Pipeline re-run manually triggered"
        Resolved_At: "2025-10-05 14:12 UTC"
        Time_To_Resolution: "5.2 hours"
        Incident_ID: "INC-2025-10-05-001"
        Post_Incident_Review: "Completed (see INC-2025-10-05-001)"

  Risk_Assessment:
    High_Risk_SLAs:
      - SLA: "Finance Data Freshness"
        Current_Status: "DEGRADED (98.2% vs 99.5% target)"
        Risk_Level: "HIGH"
        Risk_Factors:
          - "65% error budget consumed with 75% of month remaining"
          - "2 breaches in 7 days (increasing frequency)"
          - "Declining trend (-0.9% WoW, -1.3% MoM)"
        Forecast: "90%+ budget consumption by month-end if trend continues"
        Breach_Probability: "75% likely within next 14 days"
        Recommended_Actions:
          Priority_1:
            - "Implement automated schema validation in CI/CD (pre-merge)"
            - "Add real-time monitoring for source schema changes"
          Priority_2:
            - "Configure Snowflake credit alerts and auto-scaling"
            - "Review pipeline dependencies for single points of failure"
          Priority_3:
            - "Document manual workaround procedures for finance team"
            - "Create runbook for common failure scenarios"
        Estimated_Effort: "40 engineering hours over 2 sprints"
        Expected_ROI: "Reduce breach frequency by 80%, improve compliance to 99.8%+"

    Medium_Risk_SLAs:
      - SLA: "Data Quality Tests"
        Current_Status: "HEALTHY (99.7% vs 99.0% target)"
        Risk_Level: "MEDIUM"
        Risk_Factors:
          - "30% error budget consumed (acceptable)"
          - "Improving trend (+0.8% WoW)"
        Forecast: "40% budget consumption by month-end (within SLA)"
        Breach_Probability: "10% likely this month"
        Recommended_Actions:
          - "Continue monitoring failing test patterns"
          - "Quarterly review of test coverage"
        Estimated_Effort: "Monitoring only (no immediate action)"

    Low_Risk_SLAs:
      - "Executive Dashboard Availability (97.5% vs 95.0%)"
      - "Contest Data Freshness (99.95% vs 99.9%)"

  Trending_Analysis:
    Improving:
      - SLA: "Data Quality Tests"
        Change: "+0.8% from last week"
        Contributing_Factors:
          - "New dbt tests added for wallet transactions"
          - "Fixed flaky tests in contest models"
        Sustainability: "HIGH (systematic improvements)"

      - SLA: "Dashboard Availability"
        Change: "+2.5% from last month"
        Contributing_Factors:
          - "Metabase infrastructure upgrade"
          - "Query optimization reducing timeouts"
        Sustainability: "MEDIUM (infrastructure-dependent)"

    Stable:
      - SLA: "Contest Data Freshness"
        Performance: "Consistently 99.9%+ for 3 months"
        Contributing_Factors:
          - "Dedicated pipeline with redundancy"
          - "Real-time monitoring and alerting"
        Sustainability: "HIGH (mature system)"

    Degrading:
      - SLA: "Finance Data Freshness"
        Change: "-0.9% from last week, -1.3% from last month"
        Contributing_Factors:
          - "Increased frequency of source schema changes (5 in last month)"
          - "Snowflake credit limit reached twice"
          - "Pipeline complexity increased (new data sources)"
        Root_Cause: "Lack of schema change management process"
        Urgency: "HIGH - immediate action required"
        Recommended_Investment: "40 engineering hours + process implementation"

  Recommendations_By_Priority:
    Critical_This_Week:
      - Action: "Implement automated schema validation in CI/CD"
        SLA_Impact: "Finance Data Freshness"
        Effort: "16 hours"
        Expected_Benefit: "Prevent 80% of schema-related failures"
        Assigned_To: "Data Engineering Team"
        Due_Date: "2025-10-14"

      - Action: "Configure Snowflake credit monitoring and auto-scaling"
        SLA_Impact: "Finance Data Freshness"
        Effort: "8 hours"
        Expected_Benefit: "Eliminate warehouse suspension incidents"
        Assigned_To: "DevOps Team"
        Due_Date: "2025-10-14"

    High_Priority_This_Sprint:
      - Action: "Create real-time SLA monitoring dashboards in Metabase"
        SLA_Impact: "All SLAs"
        Effort: "24 hours"
        Expected_Benefit: "Reduce detection time from hours to minutes"
        Assigned_To: "Business Intelligence Team"
        Due_Date: "2025-10-21"

      - Action: "Document manual workaround procedures for finance team"
        SLA_Impact: "Finance Data Freshness"
        Effort: "4 hours"
        Expected_Benefit: "Reduce business impact during incidents"
        Assigned_To: "Data Product Manager"
        Due_Date: "2025-10-18"

    Medium_Priority_Next_Sprint:
      - Action: "Review and optimize pipeline dependencies"
        SLA_Impact: "Finance Data Freshness, Contest Data Freshness"
        Effort: "32 hours"
        Expected_Benefit: "Reduce single points of failure, improve resilience"
        Assigned_To: "Data Architecture Team"
        Due_Date: "2025-10-31"

      - Action: "Quarterly test coverage review and optimization"
        SLA_Impact: "Data Quality Tests"
        Effort: "16 hours"
        Expected_Benefit: "Maintain improving trend, catch regressions earlier"
        Assigned_To: "Quality Assurance Team"
        Due_Date: "2025-11-15"
```

## Examples

### Example 1: Weekly Finance SLA Review

**Command:**
```bash
/sla-report --period last-week --domain finance --format technical
```

**Output:**
```yaml
SLA_Compliance_Report:
  Period: "2025-09-30 to 2025-10-06"
  Domain_Filter: "finance"
  Report_Type: "technical"

  Finance_SLA_Metrics:
    Finance_Data_Freshness:
      Target: 99.5%
      Actual: 98.2%
      Status: DEGRADED
      Breaches: 2
      Error_Budget_Consumed: 65%

      Detailed_Breakdown:
        Monday: 100% (no issues)
        Tuesday: 100% (no issues)
        Wednesday: 89% (6.5 hour breach - schema change)
        Thursday: 100% (no issues)
        Friday: 91% (5.2 hour breach - warehouse suspension)
        Saturday: 100% (no issues)
        Sunday: 100% (no issues)

      Breach_Analysis:
        Breach_1:
          Date: 2025-10-03
          Duration: 6.5 hours
          Root_Cause: "Unexpected schema change in splash_production.wallet_transactions"
          Technical_Details:
            - "New column 'transaction_type_v2' added without notification"
            - "dbt model fct_wallet_transactions failed on column reference"
            - "Downstream models blocked until resolution"
          Resolution:
            - "Schema change reverted by backend team"
            - "dbt model updated to handle new column"
            - "Full data refresh (3 hours runtime)"
          Prevention:
            - "Implement schema registry with versioning"
            - "Add pre-merge schema validation in CI/CD"
            - "Backend team to notify data team of schema changes 48 hours in advance"

        Breach_2:
          Date: 2025-10-05
          Duration: 5.2 hours
          Root_Cause: "Snowflake warehouse FINANCE_WH suspended (credit limit)"
          Technical_Details:
            - "Monthly credit limit reached at 09:00 UTC"
            - "Scheduled dbt runs failed until warehouse resumed"
            - "Manual intervention required to increase credits"
          Resolution:
            - "Credit limit increased from $500 to $750/month"
            - "Auto-resume enabled for FINANCE_WH"
            - "Alerting added for 80% credit consumption"
          Prevention:
            - "Implement auto-scaling for production warehouses"
            - "Add cost monitoring dashboard"
            - "Review query efficiency (reduce compute waste)"

      Performance_Trends:
        Week_Over_Week: -0.9% (degrading)
        Month_Over_Month: -1.3% (degrading)
        Contributing_Factors:
          - "Increased schema change frequency (5 changes in 30 days)"
          - "Pipeline complexity growth (3 new data sources added)"
          - "Insufficient infrastructure monitoring"

      Recommendations:
        Immediate:
          - "Implement schema change management process"
          - "Add real-time alerting for warehouse status"
        Short_Term:
          - "Optimize high-cost queries in finance domain"
          - "Add redundancy for critical finance pipelines"
        Long_Term:
          - "Migrate to event-driven architecture for real-time freshness"
          - "Implement blue-green deployment for schema changes"
```

### Example 2: Executive Monthly Report

**Command:**
```bash
/sla-report --period last-month --format executive --export
```

**Output:**
```yaml
SLA_Compliance_Report:
  Period: "September 2025"
  Report_Type: "executive"
  Generated: "2025-10-01 09:00 UTC"
  Exported_To: "/reports/sla-compliance-2025-09-executive.pdf"

  Executive_Summary:
    Overall_Compliance: "92% (GOOD)"
    Status_Indicator: "🟡 CAUTION - Trending downward"

    Key_Highlights:
      Strengths:
        - "Contest data maintained 99.95% freshness (critical for live events)"
        - "Data quality improved 2.1% month-over-month"
        - "Zero P0 incidents (no critical business disruptions)"

      Concerns:
        - "Finance SLA degraded 1.3% month-over-month (5 breaches)"
        - "Error budget 78% consumed with 1 week remaining in month"
        - "Increasing frequency of infrastructure-related incidents"

      Business_Impact:
        User_Facing:
          - "Finance team experienced 4 delays in daily reconciliation (avg 5 hours)"
          - "No customer-facing impact (contests remained operational)"

        Operational:
          - "Manual workarounds required 5 times (finance team)"
          - "Audit trail gaps during 2 incidents (compliance risk)"

        Financial:
          - "Engineering time spent on incident response: 32 hours"
          - "Snowflake cost overrun: $150 (credit limit breaches)"
          - "No revenue impact (workarounds prevented customer disruption)"

    Recommended_Investments:
      Priority_1:
        Investment: "Schema Change Management Process"
        Effort: "40 engineering hours + $5K tooling"
        Expected_ROI: "Prevent 80% of finance SLA breaches, reduce incident response time by 50%"
        Payback_Period: "2 months"

      Priority_2:
        Investment: "Real-Time SLA Monitoring Infrastructure"
        Effort: "60 engineering hours + $2K/month operational cost"
        Expected_ROI: "Reduce incident detection time from 4 hours to <15 minutes"
        Payback_Period: "3 months"

      Priority_3:
        Investment: "Pipeline Reliability Engineering (SRE) role"
        Effort: "1 FTE hire"
        Expected_ROI: "Improve overall SLA compliance from 92% to 98%+"
        Payback_Period: "6 months"

    Action_Items_for_Leadership:
      - "Approve $5K budget for schema management tooling (VP Engineering)"
      - "Prioritize SRE hire in Q4 headcount plan (CTO)"
      - "Schedule quarterly SLA review with finance stakeholders (Data PM)"
```

### Example 3: Real-Time SLA Status

**Command:**
```bash
/sla-report --period today --all
```

**Output:**
```yaml
SLA_Compliance_Report:
  Period: "2025-10-07 (Real-Time)"
  Report_Generated: "2025-10-07 16:30 UTC"
  Report_Type: "real-time"

  Current_SLA_Status:
    Finance_Data_Freshness:
      Status: "✅ HEALTHY"
      Current_Freshness: "2.3 hours (within 4-hour SLA)"
      Last_Refresh: "2025-10-07 14:12 UTC"
      Next_Scheduled_Refresh: "2025-10-07 18:00 UTC"
      Error_Budget_Burn_Today: "0 hours (0%)"
      Active_Alerts: None

    Executive_Dashboards:
      Status: "✅ HEALTHY"
      Current_Availability: "100% (last 24 hours)"
      Last_Successful_Load: "2025-10-07 16:25 UTC"
      Average_Load_Time: "2.3 seconds"
      Active_Alerts: None

    Data_Quality_Tests:
      Status: "✅ HEALTHY"
      Last_Test_Run: "2025-10-07 14:15 UTC"
      Pass_Rate: "99.8% (1,245 / 1,248 tests)"
      Failed_Tests:
        - "stg_contests__contest_entries: null_check_user_id (3 nulls found)"
        - "fct_wallet_transactions: relationship_dim_user (2 orphaned records)"
        - "dim_contest: unique_contest_key (1 duplicate)"
      Error_Budget_Consumed_Today: "0.24% (3 failed tests)"
      Active_Alerts: "WARNING - 3 failing tests (below 99.9% target)"

    Contest_Data_Freshness:
      Status: "✅ EXCELLENT"
      Current_Freshness: "4 minutes (within 15-minute SLA)"
      Last_Event_Ingested: "2025-10-07 16:26 UTC"
      Pipeline_Lag: "4 minutes"
      Active_Alerts: None

  Active_Incidents:
    - None

  Error_Budget_Burn_Rate:
    Finance_Data_Freshness:
      Monthly_Budget: "3.65 hours"
      Consumed_To_Date: "2.37 hours (65%)"
      Days_Elapsed: 7 of 31 (23%)
      Burn_Rate: "0.34 hours/day"
      Projected_End_of_Month: "10.5 hours (288% - BREACH LIKELY)"
      Alert: "🚨 CRITICAL - Burn rate 2.8x expected, breach highly likely"

    Executive_Dashboards:
      Monthly_Budget: "36.5 hours"
      Consumed_To_Date: "5.5 hours (15%)"
      Days_Elapsed: 7 of 31 (23%)
      Burn_Rate: "0.79 hours/day"
      Projected_End_of_Month: "24.5 hours (67% - HEALTHY)"
      Alert: None

    Data_Quality_Tests:
      Monthly_Budget: "10 failed tests"
      Consumed_To_Date: "3 failed tests (30%)"
      Days_Elapsed: 7 of 31 (23%)
      Burn_Rate: "0.43 tests/day"
      Projected_End_of_Month: "13.3 tests (133% - SLIGHT BREACH RISK)"
      Alert: "⚠️  WARNING - Burn rate slightly elevated, monitor closely"

    Contest_Data_Freshness:
      Monthly_Budget: "43.8 minutes"
      Consumed_To_Date: "2.2 minutes (5%)"
      Days_Elapsed: 7 of 31 (23%)
      Burn_Rate: "0.31 minutes/day"
      Projected_End_of_Month: "9.7 minutes (22% - EXCELLENT)"
      Alert: None

  Immediate_Action_Items:
    Critical:
      - Action: "Investigate Finance Data Freshness error budget burn rate"
        Urgency: "IMMEDIATE"
        Reason: "Burn rate 2.8x expected, indicates systemic issue"
        Owner: "Data Engineering Team"
        Due: "EOD 2025-10-07"

      - Action: "Review and resolve 3 failing dbt tests"
        Urgency: "HIGH"
        Reason: "Approaching 99% quality SLA threshold"
        Owner: "Data Quality Team"
        Due: "2025-10-08 12:00 UTC"

    Monitoring:
      - Action: "Continue monitoring Data Quality burn rate"
        Urgency: "MEDIUM"
        Reason: "Slightly elevated but within acceptable range"
        Owner: "Data Quality Team"
        Review_Date: "2025-10-10"
```

## Error Handling

### Missing Data Sources
```yaml
Error_Scenario: "Unable to query dbt logs"
Fallback_Strategy:
  - Use cached data from last successful query
  - Indicate data staleness in report
  - Alert data engineering team
  - Recommend manual verification
```

### Incomplete Historical Data
```yaml
Error_Scenario: "Historical data unavailable for trend analysis"
Mitigation:
  - Report available data only
  - Clearly mark gaps in data
  - Use shorter time window for trends
  - Note limitation in report caveats
```

### Calculation Errors
```yaml
Error_Scenario: "Error budget calculation fails"
Handling:
  - Log error with context
  - Use last known good calculation
  - Flag report section as "ESTIMATED"
  - Trigger investigation workflow
```

## Integration Points

### Incident Management
- Link SLA breaches to incident database
- Cross-reference breach IDs with incident IDs
- Enrich breach reports with root cause analysis
- Track post-incident review status

### Monitoring Systems
- Query Metabase for dashboard uptime metrics
- Query Snowflake for pipeline performance data
- Query dbt logs for test results and freshness
- Query alerting system for active incidents

### Reporting Infrastructure
- Export reports to PDF for stakeholder distribution
- Send email summaries to leadership
- Post critical alerts to Slack
- Store historical reports for trend analysis

## Success Criteria

Report successfully generated when:
1. All SLA metrics collected and calculated
2. Error budget analysis completed for each SLA
3. Breach detection and classification performed
4. Trend analysis and forecasting completed
5. Report formatted correctly for requested audience
6. Actionable recommendations provided
7. Export successful (if requested)

## Notes

- **Data Sources**: Assumes access to dbt logs, Snowflake query history, Metabase logs
- **Historical Data**: Requires at least 4 weeks of data for meaningful trend analysis
- **Forecasting**: Uses simple linear regression; consider ML models for complex patterns
- **Business Impact**: Requires manual input for revenue/compliance impact quantification
- **Stakeholder Communication**: Coordinate with datadog-observability-engineer for breach notifications and monitoring alerts
- **Primary Agent**: `datadog-observability-engineer`
