---
name: runbook
description: Execute operational runbooks for common production issues with systematic diagnostic and resolution steps
model: sonnet
type: global
args:
  runbook_name:
    description: Name of the runbook to execute or 'list' to see available runbooks
    required: false
---

# Operational Runbook Execution

Execute proven runbooks for common production scenarios with systematic diagnostic procedures, automated resolution steps, validation, and incident documentation.

## Usage

```bash
/runbook list                           # Show all available runbooks
/runbook "dbt Build Failure"           # Execute specific runbook
/runbook "Snowflake Warehouse Timeout" # Warehouse performance issues
/runbook "Data Quality Incident"       # Data quality problems
```

## Available Runbooks

### 📊 Data Pipeline Runbooks

**1. dbt Build Failure**
- **Symptoms**: Failed dbt runs, compilation errors, dependency issues
- **Time**: 15-30 minutes
- **Access**: dbt Cloud, Snowflake query logs, Git history

**2. dbt Test Failure**
- **Symptoms**: Data quality tests failing, uniqueness violations, referential integrity
- **Time**: 20-45 minutes
- **Access**: dbt test results, affected model data, lineage

**3. Airbyte Sync Failure**
- **Symptoms**: Source connectors failing, incomplete syncs, schema drift
- **Time**: 15-40 minutes
- **Access**: Airbyte UI, source system logs, connection credentials

**4. Source Schema Change**
- **Symptoms**: Upstream schema evolution breaking downstream models
- **Time**: 30-60 minutes
- **Access**: Source schema documentation, dbt models, data lineage

### ❄️ Snowflake Runbooks

**5. Snowflake Warehouse Timeout**
- **Symptoms**: Query timeouts, long-running queries, warehouse saturation
- **Time**: 20-45 minutes
- **Access**: Snowflake ACCOUNT_USAGE, query history, warehouse metrics

**6. Snowflake Credit Exhaustion**
- **Symptoms**: Budget alerts, warehouse suspension, cost overruns
- **Time**: 15-30 minutes
- **Access**: Snowflake usage reports, resource monitors, warehouse configs

**7. Slow Query Performance**
- **Symptoms**: Dashboard timeouts, degraded query performance, user complaints
- **Time**: 30-90 minutes
- **Access**: Query profiles, execution plans, table statistics

### 📈 BI & Dashboard Runbooks

**8. Metabase Dashboard Outage**
- **Symptoms**: Dashboards unavailable, error messages, connection failures
- **Time**: 15-30 minutes
- **Access**: Metabase logs, Snowflake connection status, database permissions

**9. Metabase Query Timeout**
- **Symptoms**: Dashboard load failures, timeout errors, slow rendering
- **Time**: 20-45 minutes
- **Access**: Metabase query logs, underlying SQL, warehouse performance

**10. Dashboard Data Incorrect**
- **Symptoms**: Wrong numbers, missing data, stale metrics
- **Time**: 30-60 minutes
- **Access**: Dashboard SQL, source data validation, dbt model lineage

### 🔍 Data Quality Runbooks

**11. Duplicate Records**
- **Symptoms**: Unexpected duplicates in fact tables, grain violations
- **Time**: 25-50 minutes
- **Access**: Affected tables, incremental logic, unique key definitions

**12. Null Values in Required Fields**
- **Symptoms**: Data completeness issues, missing critical fields
- **Time**: 20-40 minutes
- **Access**: Source data validation, transformation logic, schema tests

**13. Referential Integrity Failure**
- **Symptoms**: Orphaned foreign keys, missing dimension records
- **Time**: 30-60 minutes
- **Access**: Fact/dimension relationships, join analysis, data lineage

### 🚨 Infrastructure Runbooks

**14. GitHub Actions Build Failure**
- **Symptoms**: CI/CD pipeline failures, deployment blocked
- **Time**: 15-35 minutes
- **Access**: GitHub Actions logs, workflow files, test results

**15. Production Deployment Rollback**
- **Symptoms**: Bad deployment causing issues, need to revert
- **Time**: 10-25 minutes
- **Access**: Git history, deployment logs, production access

## Runbook Structure

Each runbook follows this systematic pattern:

### Phase 1: Initial Assessment (3-5 minutes)
- **Gather context**: When did issue start? What changed recently?
- **Identify scope**: Which systems/models/dashboards affected?
- **Check monitoring**: Review alerts, logs, metrics
- **Estimate impact**: User-facing? Data quality? Cost?

### Phase 2: Diagnostic Investigation (10-20 minutes)
- **Collect evidence**: Logs, error messages, query results
- **Trace dependencies**: Model lineage, data flows, system connections
- **Identify root cause**: What broke? Why? When?
- **Document findings**: Timeline, symptoms, hypothesis

### Phase 3: Resolution Execution (10-30 minutes)
- **Immediate mitigation**: Stop the bleeding (disable models, upsize warehouse)
- **Root cause fix**: Address underlying issue
- **Automated steps**: SQL queries, dbt commands, API calls
- **Manual steps**: Require user confirmation before execution

### Phase 4: Validation & Verification (5-15 minutes)
- **Test fix works**: Re-run failed operations
- **Check downstream**: Verify dependent systems unaffected
- **Monitor metrics**: Ensure issue resolved
- **User acceptance**: Confirm stakeholders satisfied

### Phase 5: Documentation & Learning (5-10 minutes)
- **Update incident timeline**: Record actions taken
- **Add lessons learned**: What went wrong? How to prevent?
- **Improve runbook**: Add steps if manual intervention needed
- **Share findings**: Update team documentation

## Workflow

When `/runbook` is invoked:

### Step 1: Runbook Selection

If `runbook_name` argument provided:
1. Load the specified runbook
2. Display runbook overview (title, estimated time, required access)
3. Ask user to confirm execution: "Ready to execute [Runbook Name]? (y/n)"

If `runbook_name` is "list" or not provided:
1. Display all available runbooks grouped by category
2. Show symptoms, time estimate, required access for each
3. Ask user: "Which runbook would you like to execute?"

### Step 2: Context Gathering

Ask user for incident details:
1. **When did the issue start?** (timestamp, recent changes)
2. **What symptoms are observed?** (error messages, user reports)
3. **Which systems/models are affected?** (scope of impact)
4. **Has anything changed recently?** (deployments, config changes, schema updates)

### Step 3: Execute Diagnostic Phase

Run systematic diagnostic steps from the runbook:

**For dbt failures:**
- Check dbt Cloud run logs or local dbt_build.log
- Identify failed model(s) and extract error messages
- Query git history: `git log --oneline --since="2 days ago" -- models/`
- Check Snowflake warehouse status and query history

**For Snowflake issues:**
- Query ACCOUNT_USAGE views for warehouse metrics
- Identify long-running queries and resource consumers
- Check warehouse size vs workload patterns
- Review recent query performance trends

**For dashboard issues:**
- Check Metabase application logs
- Test underlying SQL queries directly in Snowflake
- Validate data freshness and completeness
- Review dashboard permissions and filters

**For data quality:**
- Query affected table for issue samples
- Trace data lineage to source systems
- Check dbt tests and validation logic
- Compare current vs historical data patterns

### Step 4: Route to Specialist Agents

Based on runbook type and diagnostic findings, invoke appropriate agents:

**dbt Build Failures:**
- `data-engineer` - Implementation and dbt best practices
- `snowflake-sql-expert` - SQL syntax and performance
- `architect` - Model dependencies and lineage

**Warehouse Performance:**
- `snowflake-sql-expert` - Query optimization and execution plans
- `cost-optimization-agent` - Warehouse sizing and budgets
- `devops-engineer` - Infrastructure and scaling

**Dashboard Issues:**
- `bi-platform-engineer` - Metabase configuration and troubleshooting
- `business-intelligence-analyst` - Dashboard design and metrics
- `snowflake-sql-expert` - SQL query optimization

**Data Quality:**
- `data-engineer` - Data validation and testing
- `architect` - Data modeling and grain analysis
- `quality-assurance-expert` - Testing frameworks and standards

### Step 5: Execute Resolution Steps

Follow the runbook's resolution procedure:

**Automated steps** (execute immediately):
- SQL diagnostic queries
- dbt commands (compile, run, test)
- Log file analysis
- Git history checks

**Manual steps** (require confirmation):
- Schema changes
- Warehouse resizing
- Model deployment
- Configuration updates
- Data backfills

**Example confirmation prompt:**
```
⚠️ MANUAL STEP REQUIRED:
Action: Increase warehouse size from MEDIUM to LARGE
Impact: +$2/hour compute cost, faster query execution
Duration: Temporary (will resize down after issue resolved)

Execute this step? (y/n)
```

### Step 6: Validate Resolution

Systematic validation checks:

**For dbt builds:**
1. Re-run failed model: `dbt run --select <failed_model>`
2. Run downstream tests: `dbt test --select <failed_model>+`
3. Verify data freshness: Check latest timestamps
4. Monitor next scheduled run

**For Snowflake performance:**
1. Re-execute previously slow queries
2. Check warehouse utilization metrics
3. Verify query execution times within SLA
4. Monitor for 24 hours to ensure stability

**For dashboards:**
1. Refresh affected dashboards
2. Verify data loads correctly
3. Check query execution times acceptable
4. Confirm with business stakeholders

**For data quality:**
1. Run all dbt tests for affected models
2. Query for issue samples (should return 0 rows)
3. Check downstream marts for propagation
4. Validate business metrics unchanged

### Step 7: Document & Learn

Create incident summary:

```yaml
Incident_Report:
  Runbook: "[Runbook Name]"
  Started: "[Timestamp]"
  Resolved: "[Timestamp]"
  Duration: "[Total time]"
  Severity: "[Critical|High|Medium|Low]"

  Timeline:
    - "[Time] - Issue detected: [initial symptom]"
    - "[Time] - Diagnostic started: [investigation approach]"
    - "[Time] - Root cause identified: [what broke]"
    - "[Time] - Mitigation applied: [immediate fix]"
    - "[Time] - Resolution completed: [root cause fix]"
    - "[Time] - Validation passed: [all checks green]"

  Root_Cause:
    What: "[Technical description of failure]"
    Why: "[Underlying reason for failure]"
    When: "[Trigger event or timing]"

  Resolution_Summary:
    Immediate_Actions: "[What stopped the bleeding]"
    Root_Fix: "[How underlying issue was resolved]"
    Agents_Involved: ["[Agent 1]", "[Agent 2]"]

  Validation_Results:
    - ✅ "[Check 1]: PASS"
    - ✅ "[Check 2]: PASS"
    - ✅ "[Check 3]: PASS"

  Lessons_Learned:
    - "[Prevention measure 1]"
    - "[Monitoring improvement 2]"
    - "[Process update 3]"

  Follow_Up_Actions:
    - "[ ] [Action item 1] - Owner: [Name] - Due: [Date]"
    - "[ ] [Action item 2] - Owner: [Name] - Due: [Date]"
```

Suggest runbook improvements if manual steps were needed or diagnostics took longer than expected.

## Detailed Runbook Examples

### RUNBOOK: dbt Build Failure

**Estimated Time:** 15-30 minutes
**Required Access:** dbt Cloud, Snowflake query logs, Git repository

#### Diagnostic Steps

1. **Check dbt logs:**
   ```bash
   # Local development
   cat logs/dbt.log | grep ERROR | tail -20

   # dbt Cloud
   # Navigate to Run > View Logs > Filter for ERROR
   ```

2. **Identify failed model(s):**
   - Extract model name from error message
   - Note error type: SQL, schema, dependency, resource

3. **Extract full error message:**
   ```sql
   -- Example error types:
   -- "Database 'PROD.FINANCE_STAGING' does not exist" → Schema error
   -- "SQL compilation error: invalid identifier 'TRANSACTION_FEE'" → Column missing
   -- "Compilation Error: Cycle detected" → Circular dependency
   ```

4. **Check recent changes:**
   ```bash
   git log --oneline --since="2 days ago" -- models/
   git diff HEAD~5 models/path/to/failed_model.sql
   ```

5. **Query Snowflake warehouse status:**
   ```sql
   SELECT
       warehouse_name,
       state,
       size,
       running_queries,
       queued_queries
   FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_LOAD_HISTORY
   WHERE warehouse_name = 'PROD_DBT'
   ORDER BY start_time DESC
   LIMIT 10;
   ```

#### Root Cause Classification

**SQL Compilation Error:**
- Invoke: `snowflake-sql-expert` (parse SQL syntax, identify issue)
- Common causes: Invalid column references, syntax errors, CTE issues
- Fix approach: Correct SQL, validate against schema

**Schema Error:**
- Invoke: `architect` (trace model dependencies, check schema config)
- Common causes: Wrong group tag, missing upstream model, schema name typo
- Fix approach: Correct tags, verify ref() calls, check schema.yml

**Circular Dependency:**
- Invoke: `architect` (analyze dependency graph, identify cycle)
- Common causes: Mutual ref() calls, incorrect layer hierarchy
- Fix approach: Refactor model references, respect layer patterns

**Resource Timeout:**
- Invoke: `snowflake-sql-expert` (optimize query), `devops-engineer` (warehouse sizing)
- Common causes: Large data volumes, inefficient SQL, undersized warehouse
- Fix approach: Optimize query, increase warehouse size, add incremental logic

#### Resolution Steps

**For SQL errors:**
1. **Automated:** Compile model to see full SQL: `dbt compile --select <model_name>`
2. **Manual:** Fix SQL syntax or column references
3. **Automated:** Test fix: `dbt run --select <model_name> --target dev`

**For schema errors:**
1. **Automated:** Check model config:
   ```bash
   cat models/path/to/model.sql | grep "config(" -A 10
   ```
2. **Manual:** Correct group tag or schema configuration
3. **Automated:** Verify schema exists in target environment

**For circular dependencies:**
1. **Automated:** Visualize lineage: `dbt list --select <model_name> --resource-type model`
2. **Manual:** Refactor model to break cycle (move logic to intermediate layer)
3. **Automated:** Validate no cycles: `dbt compile`

**For resource timeouts:**
1. **Immediate:** Increase warehouse size (confirm with user)
2. **Short-term:** Add `where` clause to limit data during development
3. **Long-term:** Optimize SQL (invoke snowflake-sql-expert for query plan analysis)

#### Validation

1. **Re-run failed model:**
   ```bash
   dbt run --select <failed_model> --target dev
   # Expected: ✅ SUCCESS
   ```

2. **Run downstream tests:**
   ```bash
   dbt test --select <failed_model>+
   # Expected: All tests pass
   ```

3. **Verify data quality:**
   ```sql
   SELECT
       COUNT(*) AS row_count,
       COUNT(DISTINCT primary_key) AS unique_keys,
       MAX(updated_at) AS latest_timestamp
   FROM {{ ref('failed_model') }};
   ```

4. **Check downstream impacts:**
   ```bash
   dbt list --select <failed_model>+ --resource-type model
   # Verify all downstream models can compile
   ```

#### Lessons Learned Template

- **Prevention:** Add schema test for required columns in staging models
- **Monitoring:** Set up dbt Cloud alerts for build failures
- **Process:** Update pre-commit hook to validate column dependencies
- **Documentation:** Add common error patterns to troubleshooting guide

---

### RUNBOOK: Snowflake Warehouse Timeout

**Estimated Time:** 20-45 minutes
**Required Access:** Snowflake ACCOUNT_USAGE, warehouse configuration

#### Diagnostic Steps

1. **Check warehouse utilization:**
   ```sql
   SELECT
       warehouse_name,
       TO_CHAR(start_time, 'YYYY-MM-DD HH24:MI') AS time_bucket,
       AVG(avg_running) AS avg_running_queries,
       AVG(avg_queued_load) AS avg_queued_queries,
       MAX(avg_running) AS peak_running
   FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_LOAD_HISTORY
   WHERE warehouse_name = 'PROD_DBT'
       AND start_time >= DATEADD(hour, -24, CURRENT_TIMESTAMP())
   GROUP BY warehouse_name, time_bucket
   ORDER BY time_bucket DESC;
   ```

2. **Identify long-running queries:**
   ```sql
   SELECT
       query_id,
       user_name,
       warehouse_name,
       execution_status,
       total_elapsed_time / 1000 AS elapsed_seconds,
       SUBSTR(query_text, 1, 100) AS query_preview
   FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
   WHERE warehouse_name = 'PROD_DBT'
       AND start_time >= DATEADD(hour, -2, CURRENT_TIMESTAMP())
       AND total_elapsed_time > 300000  -- > 5 minutes
   ORDER BY total_elapsed_time DESC
   LIMIT 20;
   ```

3. **Check warehouse size vs workload:**
   ```sql
   SELECT
       warehouse_name,
       warehouse_size,
       COUNT(*) AS query_count,
       AVG(total_elapsed_time / 1000) AS avg_duration_sec,
       SUM(CASE WHEN execution_status = 'SUCCESS' THEN 1 ELSE 0 END) AS successful,
       SUM(CASE WHEN execution_status = 'TIMEOUT' THEN 1 ELSE 0 END) AS timeouts
   FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
   WHERE warehouse_name = 'PROD_DBT'
       AND start_time >= DATEADD(day, -1, CURRENT_TIMESTAMP())
   GROUP BY warehouse_name, warehouse_size;
   ```

4. **Review recent query patterns:**
   ```sql
   SELECT
       DATE_TRUNC('hour', start_time) AS hour,
       COUNT(*) AS queries_per_hour,
       AVG(execution_time / 1000) AS avg_duration_sec
   FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
   WHERE warehouse_name = 'PROD_DBT'
       AND start_time >= DATEADD(day, -7, CURRENT_TIMESTAMP())
   GROUP BY hour
   ORDER BY hour DESC;
   ```

#### Root Cause Classification

**Undersized Warehouse:**
- Symptoms: Consistent queue buildup, many concurrent queries, peak hour saturation
- Invoke: `devops-engineer` (warehouse scaling strategy)
- Fix: Increase warehouse size or enable auto-scaling

**Inefficient Queries:**
- Symptoms: Few queries consuming most time, specific models timing out
- Invoke: `snowflake-sql-expert` (query optimization, execution plan analysis)
- Fix: Optimize SQL, add clustering keys, improve join strategies

**High Concurrency:**
- Symptoms: Many users/jobs competing for resources
- Invoke: `devops-engineer` (multi-cluster warehouse setup)
- Fix: Enable auto-scaling, separate workloads into dedicated warehouses

**Resource Contention:**
- Symptoms: Timeouts during specific time windows, batch job conflicts
- Invoke: `devops-engineer` (scheduling optimization)
- Fix: Stagger batch jobs, separate interactive vs batch warehouses

#### Resolution Steps

**Immediate Mitigation (stop the bleeding):**

1. **Upsize warehouse temporarily:**
   ```sql
   ALTER WAREHOUSE PROD_DBT SET WAREHOUSE_SIZE = 'LARGE';
   -- Confirm with user: "Upsizing PROD_DBT from MEDIUM to LARGE (+$2/hour). Confirm? (y/n)"
   ```

2. **Cancel blocking queries (if identified):**
   ```sql
   -- Only after user confirmation
   SELECT SYSTEM$CANCEL_QUERY('<query_id>');
   ```

**Short-term Fix (address immediate cause):**

1. **Optimize expensive queries:**
   - Invoke: `snowflake-sql-expert` with query text
   - Get optimized SQL with better join strategies, CTEs, or clustering
   - Test optimized query in dev environment
   - Deploy to production

2. **Adjust warehouse auto-suspend:**
   ```sql
   ALTER WAREHOUSE PROD_DBT SET AUTO_SUSPEND = 60;  -- 1 minute idle
   -- Reduces cost while maintaining responsiveness
   ```

**Long-term Solution (prevent recurrence):**

1. **Implement warehouse auto-scaling:**
   ```sql
   ALTER WAREHOUSE PROD_DBT SET
       MIN_CLUSTER_COUNT = 1
       MAX_CLUSTER_COUNT = 3
       SCALING_POLICY = 'STANDARD';
   -- Invoke: cost-optimization-agent for budget impact analysis
   ```

2. **Separate workloads:**
   - Create dedicated warehouse for high-volume Segment models
   - Move critical finance models to separate warehouse
   - Configure dbt profiles to use appropriate warehouses by tag

3. **Schedule batch jobs:**
   - Stagger dbt runs to avoid peak concurrency
   - Run high-volume models during off-hours
   - Use dbt Cloud job scheduling

#### Validation

1. **Verify queries complete successfully:**
   ```bash
   dbt run --select tag:critical:true --target prod
   # Expected: All models complete within SLA
   ```

2. **Check warehouse utilization returned to normal:**
   ```sql
   SELECT
       AVG(avg_running) AS current_avg_running,
       MAX(avg_queued_load) AS current_max_queued
   FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_LOAD_HISTORY
   WHERE warehouse_name = 'PROD_DBT'
       AND start_time >= DATEADD(minute, -30, CURRENT_TIMESTAMP());
   -- Expected: avg_running < 5, max_queued = 0
   ```

3. **Validate cost impact acceptable:**
   - Query warehouse credit usage for past 24 hours
   - Compare to baseline and budget
   - Invoke: `cost-optimization-agent` if over budget

4. **Monitor for 24 hours:**
   - Set up alerts for queue depth > 5
   - Track query timeouts (should be 0)
   - Review next day's metrics

---

### RUNBOOK: Data Quality Incident - Duplicate Records

**Estimated Time:** 25-50 minutes
**Required Access:** Affected table data, dbt models, data lineage

#### Diagnostic Steps

1. **Identify duplicate scope:**
   ```sql
   -- Find duplicate records
   SELECT
       primary_key,
       COUNT(*) AS duplicate_count
   FROM {{ ref('fact_table_name') }}
   GROUP BY primary_key
   HAVING COUNT(*) > 1
   ORDER BY duplicate_count DESC
   LIMIT 100;
   ```

2. **Analyze duplicate patterns:**
   ```sql
   -- Sample duplicate records to understand pattern
   WITH duplicates AS (
       SELECT primary_key
       FROM {{ ref('fact_table_name') }}
       GROUP BY primary_key
       HAVING COUNT(*) > 1
   )
   SELECT t.*
   FROM {{ ref('fact_table_name') }} t
   INNER JOIN duplicates d ON t.primary_key = d.primary_key
   ORDER BY t.primary_key, t.updated_at DESC
   LIMIT 500;
   ```

3. **Check data lineage:**
   ```bash
   dbt list --select +fact_table_name --resource-type model
   # Trace back to source systems
   ```

4. **Review incremental logic:**
   ```bash
   cat models/path/to/fact_table_name.sql | grep "is_incremental" -A 20
   # Check merge strategy, unique_key, and filter logic
   ```

5. **Query source data for duplicates:**
   ```sql
   -- Check if duplicates exist in source
   SELECT
       source_key,
       COUNT(*) AS count
   FROM {{ source('splash_production', 'source_table') }}
   GROUP BY source_key
   HAVING COUNT(*) > 1;
   ```

#### Root Cause Classification

**Incremental Logic Error:**
- Symptoms: Duplicates after incremental runs, full refresh is clean
- Common causes: Wrong unique_key, missing deduplication, incorrect merge strategy
- Invoke: `data-engineer` (incremental pattern review)

**Source Data Duplicates:**
- Symptoms: Duplicates in source system propagate downstream
- Common causes: Application bug, ETL duplicate writes, Airbyte sync issues
- Invoke: `data-engineer` (source validation), `architect` (data quality strategy)

**Grain Violation:**
- Symptoms: Fact table grain doesn't match unique_key definition
- Common causes: Missing grain dimensions, incorrect join logic
- Invoke: `architect` (grain analysis, Kimball methodology review)

**Race Condition:**
- Symptoms: Intermittent duplicates, timing-dependent
- Common causes: Concurrent dbt runs, overlapping incremental windows
- Invoke: `devops-engineer` (job scheduling), `data-engineer` (idempotency)

#### Resolution Steps

**Immediate Mitigation:**

1. **Add uniqueness test (if missing):**
   ```yaml
   # models/schema.yml
   models:
     - name: fact_table_name
       columns:
         - name: primary_key
           tests:
             - unique
             - not_null
   ```

2. **Run test to confirm issue:**
   ```bash
   dbt test --select fact_table_name
   # Should fail with duplicate count
   ```

**Short-term Fix:**

1. **Deduplicate affected table:**
   ```sql
   -- Create temporary deduplicated version
   CREATE OR REPLACE TABLE PROD.SCHEMA.FACT_TABLE_NAME_DEDUPED AS
   SELECT *
   FROM (
       SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY primary_key
               ORDER BY updated_at DESC
           ) AS row_num
       FROM PROD.SCHEMA.FACT_TABLE_NAME
   )
   WHERE row_num = 1;

   -- Confirm with user before swapping tables
   -- Swap tables (requires user confirmation)
   ALTER TABLE PROD.SCHEMA.FACT_TABLE_NAME RENAME TO FACT_TABLE_NAME_OLD;
   ALTER TABLE PROD.SCHEMA.FACT_TABLE_NAME_DEDUPED RENAME TO FACT_TABLE_NAME;
   ```

**Root Cause Fix:**

**For incremental logic errors:**
1. Update unique_key definition in model config
2. Add deduplication CTE to model SQL:
   ```sql
   WITH source_deduped AS (
       SELECT *
       FROM (
           SELECT *,
               ROW_NUMBER() OVER (
                   PARTITION BY unique_key
                   ORDER BY updated_at DESC
               ) AS row_num
           FROM source_table
       )
       WHERE row_num = 1
   )
   ```
3. Test incremental logic in dev:
   ```bash
   dbt run --select fact_table_name --full-refresh --target dev
   dbt run --select fact_table_name --target dev  # Incremental
   dbt test --select fact_table_name --target dev
   ```

**For source data duplicates:**
1. Add dbt source test for uniqueness
2. Implement deduplication in staging layer
3. Coordinate with source system team to fix root cause

**For grain violations:**
1. Invoke: `architect` to analyze proper grain
2. Refactor model to match correct grain
3. Update unique_key to match grain dimensions
4. Add grain documentation to model

**Long-term Prevention:**

1. **Add monitoring:**
   ```sql
   -- Create data quality check
   CREATE OR REPLACE VIEW PROD.MONITORING.DUPLICATE_ALERTS AS
   SELECT
       'fact_table_name' AS table_name,
       COUNT(*) AS duplicate_count,
       CURRENT_TIMESTAMP() AS check_time
   FROM (
       SELECT primary_key
       FROM PROD.SCHEMA.FACT_TABLE_NAME
       GROUP BY primary_key
       HAVING COUNT(*) > 1
   );
   ```

2. **Update dbt tests:**
   - Add uniqueness tests to all fact tables
   - Add grain validation tests
   - Add source freshness checks

3. **Improve documentation:**
   - Document table grain in schema.yml
   - Add grain validation logic to model
   - Update data quality standards

#### Validation

1. **Run uniqueness test:**
   ```bash
   dbt test --select fact_table_name
   # Expected: ✅ PASS (unique test passes)
   ```

2. **Verify duplicate count = 0:**
   ```sql
   SELECT COUNT(*) AS duplicate_count
   FROM (
       SELECT primary_key
       FROM {{ ref('fact_table_name') }}
       GROUP BY primary_key
       HAVING COUNT(*) > 1
   );
   -- Expected: 0 duplicates
   ```

3. **Check downstream marts not affected:**
   ```bash
   dbt test --select fact_table_name+
   # Expected: All downstream tests pass
   ```

4. **Validate business metrics unchanged:**
   ```sql
   -- Compare key metrics before/after deduplication
   SELECT
       DATE_TRUNC('day', transaction_date) AS date,
       COUNT(*) AS transaction_count,
       SUM(amount) AS total_amount
   FROM {{ ref('fact_table_name') }}
   GROUP BY date
   ORDER BY date DESC
   LIMIT 30;
   -- Compare to historical values (should be similar)
   ```

5. **Monitor next incremental run:**
   ```bash
   dbt run --select fact_table_name --target prod
   dbt test --select fact_table_name --target prod
   # Expected: No new duplicates introduced
   ```

---

## Success Criteria

A runbook execution is successful when:

1. ✅ **Issue Resolved**: Root cause identified and fixed
2. ✅ **Validation Passed**: All validation checks complete successfully
3. ✅ **No Regressions**: Downstream systems unaffected
4. ✅ **Documented**: Incident report created with timeline and lessons learned
5. ✅ **Preventive Measures**: Follow-up actions identified to prevent recurrence

## Output Format

```yaml
Runbook_Execution_Report:
  Runbook: "[Runbook Name]"
  Execution_ID: "[UUID or timestamp-based ID]"
  Started: "[ISO 8601 timestamp]"
  Completed: "[ISO 8601 timestamp]"
  Duration: "[HH:MM:SS]"
  Severity: "[Critical|High|Medium|Low]"

  Context:
    Issue_Start: "[When issue was first detected]"
    Symptoms: "[User-reported symptoms or monitoring alerts]"
    Affected_Systems: ["[System 1]", "[System 2]"]
    Recent_Changes: "[Deployments, config updates, schema changes]"

  Diagnostic_Findings:
    Investigation_Time: "[Duration of diagnostic phase]"
    Root_Cause_Type: "[SQL Error|Schema Issue|Performance|Data Quality|Infrastructure]"
    Root_Cause_Detail: "[Technical description of what broke]"
    Affected_Components: ["[Model/Table 1]", "[Model/Table 2]"]
    Evidence:
      - "[Log excerpt or error message]"
      - "[Query result showing issue]"
      - "[Metric showing deviation]"

  Resolution_Steps:
    Immediate_Mitigation:
      - "[Action 1] - Time: [Duration]"
      - "[Action 2] - Time: [Duration]"
    Root_Fix:
      - "[Fix 1] - Time: [Duration]"
      - "[Fix 2] - Time: [Duration]"
    Agents_Involved:
      - agent: "[Agent Name]"
        role: "[What agent helped with]"
        duration: "[Time spent]"

  Validation_Results:
    - check: "[Validation check 1]"
      status: "✅ PASS"
      detail: "[Specific result]"
    - check: "[Validation check 2]"
      status: "✅ PASS"
      detail: "[Specific result]"

  Lessons_Learned:
    What_Went_Wrong: "[Root cause explanation]"
    Why_It_Happened: "[Contributing factors]"
    How_To_Prevent:
      - "[Prevention measure 1]"
      - "[Monitoring improvement 2]"
      - "[Process update 3]"

  Follow_Up_Actions:
    - action: "[Action item 1]"
      owner: "[Person or team]"
      due_date: "[YYYY-MM-DD]"
      priority: "[High|Medium|Low]"
    - action: "[Action item 2]"
      owner: "[Person or team]"
      due_date: "[YYYY-MM-DD]"
      priority: "[High|Medium|Low]"

  Runbook_Improvements:
    - "[Suggestion for improving diagnostic steps]"
    - "[Additional validation check to add]"
    - "[Automation opportunity identified]"
```

## Notes

- **Systematic Approach**: Follow runbook steps in order; don't skip diagnostic phase
- **User Confirmation**: Always confirm before executing manual steps with impact
- **Documentation**: Create incident report even for quick fixes
- **Continuous Improvement**: Update runbooks based on real incidents
- **Agent Collaboration**: Leverage specialist agents for domain expertise
- **Validation Critical**: Don't declare success until all checks pass
- **Learn & Share**: Every incident is opportunity to improve monitoring and prevention