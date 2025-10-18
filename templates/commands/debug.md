---
name: debug
description: Debug production dbt/SQL failures with intelligent agent orchestration and automated postmortem generation
model: sonnet[1m+]
type: global
---

# Debug Production Failures

Systematically debug production dbt/SQL/data pipeline failures by orchestrating specialist agents, following debugging runbooks, and generating comprehensive resolution reports with root cause analysis.

## Usage

```bash
/debug [error_description_or_model_name]
/debug "fct_wallet_transactions failed with schema error"
/debug fct_wallet_transactions
/debug "warehouse timeout on critical models"
```

## Workflow

### Phase 1: Error Analysis & Context Gathering

**Automatic Error Detection:**

- Parse error type: SQL syntax, schema change, resource limit, data quality, upstream failure
- Gather context: dbt logs, Snowflake warehouse state, model dependencies, recent changes
- Classify severity: P0 (platform down), P1 (critical data), P2 (degraded), P3 (minor)

**Context Collection:**

1. Check dbt logs for error messages and stack traces
2. Review recent git commits affecting related models
3. Examine model dependencies via lineage (`dbt ls --select +model+`)
4. Check Snowflake query history and warehouse state
5. Identify recent schema changes in source systems

### Phase 2: Agent Orchestration (Context-Aware)

#### SQL Compilation Errors

```yaml
Orchestration_Sequence:
  1. Task(subagent_type="snowflake-sql-expert")
     - Parse SQL error messages
     - Identify syntax issues (UNION, CTE, window functions)
     - Check Snowflake-specific syntax violations

  2. Task(subagent_type="architect")
     - Trace model dependencies via ref() changes
     - Check for circular dependencies
     - Validate layer architecture (staging → core → marts)

  3. Task(subagent_type="data-engineer")
     - Review recent dbt model changes in git history
     - Check sqlfluff compliance
     - Validate tagging strategy
```

#### Schema Change Errors

```yaml
Orchestration_Sequence:
  1. Task(subagent_type="architect")
     - Analyze upstream schema changes
     - Perform impact analysis across lineage
     - Identify affected downstream models

  2. Task(subagent_type="data-pipeline-engineer")
     - Check Airbyte/Fivetran schema evolution
     - Validate source system DDL changes
     - Review sync history for schema drift

  3. Task(subagent_type="snowflake-sql-expert")
     - Recommend schema migration strategy
     - Suggest ALTER TABLE vs rebuild approach
     - Validate data type compatibility
```

#### Resource/Performance Issues

```yaml
Orchestration_Sequence:
  1. Task(subagent_type="cost-optimization-agent")
     - Check Snowflake warehouse credit limits
     - Analyze warehouse sizing (XS → 3XL)
     - Review query queueing and concurrency

  2. Task(subagent_type="snowflake-sql-expert")
     - Analyze query execution plans
     - Identify expensive operations (cross joins, subqueries)
     - Recommend query optimization (CTEs, materialization)

  3. Task(subagent_type="architect")
     - Review materialization strategy (table vs incremental)
     - Check partition strategy for large tables
     - Validate volume tags and build frequency
```

#### Data Quality Issues

```yaml
Orchestration_Sequence:
  1. Task(subagent_type="data-engineer")
     - Run dbt tests (unique, not_null, relationships)
     - Check referential integrity across facts/dimensions
     - Validate incremental model logic

  2. Task(subagent_type="data-pipeline-engineer")
     - Validate source data quality in Airbyte/Fivetran
     - Check for upstream data truncation/deletion
     - Review extraction patterns and sync modes

  3. Task(subagent_type="architect")
     - Review grain definitions in fact tables
     - Validate SCD Type 2 logic in dimensions
     - Check conformed dimension integrity
```

#### Upstream Pipeline Failures

```yaml
Orchestration_Sequence:
  1. Task(subagent_type="data-pipeline-engineer")
     - Check Airbyte/Fivetran sync status
     - Review connector health and error logs
     - Validate source system connectivity

  2. Task(subagent_type="devops-engineer")
     - Check GitHub Actions workflow status
     - Review CI/CD pipeline logs
     - Validate environment variables and secrets

  3. Task(subagent_type="architect")
     - Assess downstream impact of delayed data
     - Recommend fallback or backfill strategy
```

### Phase 3: Incident Management (Auto-triggered for P0/P1)

**P0 - Platform Down (Complete Outage):**

```yaml
Incident_Protocol:
  1. Task(subagent_type="incident-manager-agent")
     - Declare major incident
     - Apply P0 runbook (immediate escalation)
     - Coordinate war room

  2. Stakeholder_Communication:
     - Notify executive leadership
     - Update status page
     - Brief customer support team

  3. Resolution_Timeline:
     - Track incident events with timestamps
     - Document mitigation attempts
     - Record final resolution
```

**P1 - Critical Data Missing (Revenue/Compliance Impact):**

```yaml
Incident_Protocol:
  1. Task(subagent_type="incident-manager-agent")
     - Declare critical incident
     - Apply P1 runbook (escalate to on-call)
     - Coordinate response team

  2. Stakeholder_Communication:
     - Notify data consumers (finance, BI team)
     - Provide ETA for resolution
     - Offer manual workaround if available

  3. Resolution_Timeline:
     - Document incident progression
     - Track resolution steps
```

### Phase 4: Resolution & Postmortem

**Resolution Report Generation:**

```yaml
Report_Contents:
  Error_Summary:
    - Error type and severity
    - Affected models/systems
    - Detection timestamp

  Root_Cause_Analysis:
    - Primary cause (what failed)
    - Contributing factors (why it failed)
    - Detection gaps (why not caught earlier)

  Resolution_Steps:
    - Immediate fix applied
    - Validation performed
    - Rollback plan (if needed)

  Prevention_Recommendations:
    - Schema tests to add
    - Pre-commit hooks to enhance
    - Monitoring/alerting improvements
    - Documentation updates
```

**Postmortem Creation (P0/P1 Only):**

```yaml
Postmortem_Workflow:
  1. Task(subagent_type="product-manager")
     - Generate blameless postmortem document
     - Include timeline, root cause, prevention
     - Coordinate postmortem review meeting

  2. Postmortem_Sections:
     - Incident summary
     - Timeline of events
     - Root cause analysis (5 Whys)
     - What went well / What went wrong
     - Action items with owners and due dates

  3. Follow_Up:
     - Track action items in JIRA
     - Update runbooks with learnings
     - Schedule follow-up review (2 weeks)
```

**Runbook Updates:**

- Capture new failure patterns
- Document resolution procedures
- Update troubleshooting guides
- Enhance monitoring coverage

## Output Format

```yaml
Debug_Report:
  Error_Type: [SQL_Compilation | Schema_Change | Resource_Limit | Data_Quality | Upstream_Failure]
  Severity: [P0 | P1 | P2 | P3]
  Affected_Models:
    - "fct_wallet_transactions"
    - "mart_daily_revenue"

  Root_Cause: |
    Detailed explanation of what caused the failure,
    including upstream dependencies and contributing factors.

  Resolution_Steps:
    - "Step 1: Identified missing column in stg_wallet_transactions"
    - "Step 2: Added column to staging model with default value"
    - "Step 3: Ran dbt run --select +fct_wallet_transactions"
    - "Step 4: Validated downstream marts refreshed successfully"

  Prevention_Recommendations:
    - "Add schema test for required columns in staging layer"
    - "Update pre-commit hook to validate ref() dependencies"
    - "Enable Airbyte schema change alerts"
    - "Document column addition process in runbook"

  Incident_ID: "#INC-12345" # (if P0/P1)
  Postmortem_Link: "https://confluence.company.com/postmortem/12345" # (if created)

  Agent_Consultations:
    - agent: snowflake-sql-expert
      finding: "SQL syntax error in UNION ALL statement"
    - agent: architect
      finding: "Downstream impact to 12 marts"
    - agent: data-engineer
      finding: "Missing column added in recent Airbyte sync"
```

## Examples

### Example 1: dbt Compilation Error

**User Request:**
```bash
/debug "fct_wallet_transactions compilation failed"
```

**Orchestration:**
```yaml
Step_1: Error Analysis
  - Detected: SQL compilation error
  - Severity: P2 (single model affected)
  - Context: Recent merge to main branch

Step_2: Agent Consultation
  - Task(subagent_type="snowflake-sql-expert")
    Finding: "Blank line before UNION ALL causing compilation failure"

  - Task(subagent_type="architect")
    Finding: "No dependency changes, isolated to single model"

  - Task(subagent_type="data-engineer")
    Finding: "Recent refactoring introduced formatting issue"

Step_3: Resolution
  - Removed blank lines around UNION ALL
  - Ran sqlfluff fix for formatting
  - Validated with dbt compile --select fct_wallet_transactions

Step_4: Prevention
  - Enhanced sqlfluff rule for UNION syntax
  - Updated developer guide with example
```

**Output:**
```yaml
Debug_Report:
  Error_Type: SQL_Compilation
  Severity: P2
  Root_Cause: "Blank lines before UNION ALL violate dbt compilation rules"
  Resolution_Steps:
    - "Removed blank lines in fct_wallet_transactions.sql (lines 45-47)"
    - "Applied sqlfluff fix --dialect snowflake"
    - "Validated compilation: dbt compile --select fct_wallet_transactions"
  Prevention_Recommendations:
    - "Update .sqlfluff config to enforce UNION syntax rules"
    - "Add pre-commit hook to catch blank line violations"
  Agent_Consultations:
    - snowflake-sql-expert: "Identified UNION syntax violation"
    - architect: "Confirmed isolated impact"
```

### Example 2: Schema Change Cascade

**User Request:**
```bash
/debug mart_daily_revenue
```

**Orchestration:**
```yaml
Step_1: Error Analysis
  - Detected: Schema error in mart layer
  - Severity: P1 (critical revenue reporting)
  - Context: Column missing in upstream staging model

Step_2: Agent Consultation
  - Task(subagent_type="architect")
    Finding: "Airbyte added 'payment_processor_fee' column to source"
    Impact: "12 downstream marts need column added"

  - Task(subagent_type="data-pipeline-engineer")
    Finding: "Airbyte schema evolution added column 3 days ago"
    Recommendation: "Enable schema change notifications"

  - Task(subagent_type="snowflake-sql-expert")
    Finding: "Column type is NUMBER(10,2), needs NULL handling"
    Recommendation: "Add COALESCE for historical backfill"

Step_3: Resolution
  - Added column to stg_splash_wallet__transactions
  - Backfilled historical data with COALESCE(payment_processor_fee, 0)
  - Rebuilt fct_wallet_transactions and downstream marts
  - Validated data integrity with dbt tests

Step_4: Prevention
  - Enabled Airbyte schema change alerts (Slack webhook)
  - Added dbt test for required columns
  - Documented column addition workflow
```

**Output:**
```yaml
Debug_Report:
  Error_Type: Schema_Change
  Severity: P1
  Affected_Models:
    - stg_splash_wallet__transactions
    - fct_wallet_transactions
    - mart_daily_revenue
    - (9 additional marts)
  Root_Cause: |
    Airbyte schema evolution added 'payment_processor_fee' column
    to source table 3 days ago. Staging model not updated, causing
    downstream marts to fail when attempting to reference column.
  Resolution_Steps:
    - "Added payment_processor_fee to stg_splash_wallet__transactions"
    - "Applied backfill logic: COALESCE(payment_processor_fee, 0)"
    - "Rebuilt: dbt run --select +mart_daily_revenue+"
    - "Validated: dbt test --select +mart_daily_revenue+"
  Prevention_Recommendations:
    - "Enable Airbyte schema change notifications (Slack #data-alerts)"
    - "Add dbt test: required_columns(['payment_processor_fee'])"
    - "Document schema evolution process in runbook"
    - "Consider schema-on-read pattern for new columns"
  Agent_Consultations:
    - architect: "Impact analysis: 12 models affected"
    - data-pipeline-engineer: "Schema change 3 days ago in Airbyte"
    - snowflake-sql-expert: "Backfill strategy with COALESCE"
```

### Example 3: Warehouse Timeout (P1 Incident)

**User Request:**
```bash
/debug "All dbt models timing out"
```

**Orchestration:**
```yaml
Step_1: Error Analysis
  - Detected: Resource limit / warehouse timeout
  - Severity: P1 (complete platform impact)
  - Context: All dbt builds failing across environments

Step_2: Incident Declaration
  - Task(subagent_type="incident-manager-agent")
    Action: "Declared P1 incident #INC-789"
    Runbook: "Applied P1 resource escalation procedure"
    War_Room: "Created Slack channel #incident-789"

Step_3: Agent Consultation
  - Task(subagent_type="cost-optimization-agent")
    Finding: "Snowflake credit limit exhausted (100% of monthly quota)"
    Recommendation: "Increase credit limit or upgrade to BUSINESS_CRITICAL"

  - Task(subagent_type="snowflake-sql-expert")
    Finding: "Query queueing due to warehouse size (X-Small)"
    Recommendation: "Scale warehouse to Large for critical builds"

  - Task(subagent_type="architect")
    Finding: "High-volume Segment models consuming 80% of credits"
    Recommendation: "Move Segment builds to dedicated warehouse"

Step_4: Resolution
  - Immediate: Increased credit limit by 50% (emergency approval)
  - Short-term: Scaled warehouse from X-Small to Large
  - Long-term: Created separate warehouse for Segment data
  - Validation: All critical models built successfully

Step_5: Postmortem
  - Task(subagent_type="product-manager")
    Created: "Blameless postmortem document"
    Meeting: "Scheduled postmortem review (2024-10-10)"
    Action_Items:
      - "Implement credit monitoring alerts (owner: DevOps)"
      - "Document warehouse sizing guidelines (owner: Architect)"
      - "Create budget forecasting dashboard (owner: BI)"
```

**Output:**
```yaml
Debug_Report:
  Error_Type: Resource_Limit
  Severity: P1
  Incident_ID: "#INC-789"

  Root_Cause: |
    Monthly Snowflake credit limit exhausted due to:
    1. Undersized warehouse (X-Small) for production workload
    2. High-volume Segment models consuming 80% of credits
    3. No credit monitoring or alerts configured

  Resolution_Steps:
    - "Emergency credit limit increase: +50% (approved by CFO)"
    - "Warehouse scaling: X-Small → Large for critical builds"
    - "Created dedicated warehouse for Segment data processing"
    - "Validated: dbt run --select tag:critical:true (SUCCESS)"

  Prevention_Recommendations:
    - "Implement Snowflake credit monitoring with 80% threshold alert"
    - "Document warehouse sizing guidelines in architecture docs"
    - "Create monthly budget forecasting dashboard"
    - "Segregate high-volume workloads to dedicated warehouses"
    - "Enable auto-suspend (5 min) and auto-resume on all warehouses"

  Postmortem_Link: "https://confluence.company.com/postmortem/INC-789"

  Agent_Consultations:
    - incident-manager-agent: "P1 incident declared, war room coordinated"
    - cost-optimization-agent: "Credit limit analysis and recommendations"
    - snowflake-sql-expert: "Warehouse sizing and query optimization"
    - architect: "Workload segregation strategy"
    - product-manager: "Postmortem creation and action tracking"

  Timeline:
    - "14:23 UTC: First warehouse timeout detected"
    - "14:25 UTC: P1 incident declared (#INC-789)"
    - "14:30 UTC: Root cause identified (credit limit)"
    - "14:45 UTC: Emergency credit increase approved"
    - "15:00 UTC: Warehouse scaled to Large"
    - "15:15 UTC: All critical models built successfully"
    - "15:30 UTC: Incident resolved, postmortem scheduled"
```

### Example 4: Data Quality Failure

**User Request:**
```bash
/debug "fct_contest_entries has duplicate keys"
```

**Orchestration:**
```yaml
Step_1: Error Analysis
  - Detected: Data quality issue (unique test failure)
  - Severity: P2 (data integrity issue)
  - Context: Incremental model producing duplicates

Step_2: Agent Consultation
  - Task(subagent_type="data-engineer")
    Finding: "unique_key definition incorrect for SCD Type 2"
    Recommendation: "Use surrogate key combining natural key + valid_from"

  - Task(subagent_type="architect")
    Finding: "Grain definition unclear in fact table"
    Recommendation: "Document grain: one row per contest entry per day"

  - Task(subagent_type="data-pipeline-engineer")
    Finding: "Source data has late-arriving updates"
    Recommendation: "Implement late-arriving fact pattern"

Step_3: Resolution
  - Updated unique_key: contest_entry_id || '_' || valid_from_date
  - Added grain documentation to model YAML
  - Implemented late-arriving fact logic with merge strategy
  - Validated uniqueness: dbt test --select fct_contest_entries
```

**Output:**
```yaml
Debug_Report:
  Error_Type: Data_Quality
  Severity: P2
  Root_Cause: |
    Incremental fact table using natural key (contest_entry_id) as unique_key,
    but SCD Type 2 pattern requires surrogate key combining natural key + timestamp.
    Late-arriving updates from source causing duplicate rows.
  Resolution_Steps:
    - "Updated unique_key: contest_entry_id || '_' || valid_from_date"
    - "Added grain documentation: 'One row per contest entry per day'"
    - "Implemented late-arriving fact merge logic"
    - "Full refresh: dbt run --select fct_contest_entries --full-refresh"
    - "Validated: dbt test --select fct_contest_entries (PASS)"
  Prevention_Recommendations:
    - "Add grain documentation to all fact table schema.yml files"
    - "Create dbt test macro: test_fact_grain_unique()"
    - "Document SCD Type 2 pattern in architecture guide"
    - "Add pre-merge validation for unique_key definition"
  Agent_Consultations:
    - data-engineer: "Unique key definition pattern error"
    - architect: "Grain documentation and SCD guidance"
    - data-pipeline-engineer: "Late-arriving fact pattern"
```

## Error Pattern Catalog

### Common Error Signatures

**SQL Compilation Errors:**

- `Database 'X' does not exist` → Check `group:` tag and schema mapping
- `Object 'Y' does not exist` → Check ref() dependencies and upstream builds
- Blank lines around UNION → Remove whitespace before/after UNION ALL
- `ambiguous column reference` → Qualify columns with table aliases

**Schema Errors:**

- `Invalid identifier 'Z'` → Column added/removed in source system
- `Column count mismatch` → Upstream schema evolution in Airbyte/Fivetran
- `Data type mismatch` → Source system changed column type

**Resource Errors:**

- `Warehouse timeout` → Check warehouse size, credit limits
- `Out of memory` → Review query complexity, join strategies
- `Query queueing` → Scale warehouse or reduce concurrency

**Data Quality Errors:**

- `Unique test failed` → Check grain definition, SCD logic
- `Not null test failed` → Source data issue or missing default
- `Referential integrity failed` → Orphaned records in fact tables

## Success Criteria

**Effective Debugging:**

- Root cause identified within 15 minutes (P1/P2)
- Resolution applied with validation
- Prevention measures documented
- Runbooks updated with learnings

**Incident Management (P0/P1):**

- Incident declared within 5 minutes of detection
- Stakeholders notified within 10 minutes
- Postmortem created within 24 hours
- Action items tracked to completion

**Knowledge Capture:**

- Debug report generated for all failures
- Common patterns added to catalog
- Runbooks enhanced with new procedures
- Team knowledge shared in postmortem reviews
