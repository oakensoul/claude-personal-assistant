---
name: incident
description: Declare and manage production incidents with automated runbook execution, escalation, and stakeholder communication
model: sonnet
type: global
args:
  severity:
    description: Incident severity level (P0/P1/P2/P3)
    required: false
  description:
    description: Brief description of the incident
    required: false
---

# Production Incident Management

Manage active production incidents with automated runbook execution, escalation protocols, and stakeholder communication.

## Command Usage

```bash
# Interactive mode (recommended)
/incident

# Quick declaration
/incident [severity] "[incident_description]"

# Examples
/incident P1 "Finance dashboard showing zero revenue"
/incident P0 "Snowflake warehouse suspended - all queries failing"
/incident P2 "Metabase dashboards loading slowly"
```

## Severity Classification

### P0 - Critical Outage

**Criteria:**

- Platform completely down or unavailable
- All data pipelines halted
- Data warehouse inaccessible
- Critical business operations blocked

**Impact:**

- Executive visibility required
- Immediate escalation to leadership
- All-hands response
- SLA: 15-minute response time

**Examples:**

- Snowflake warehouse suspended, all dbt runs failing
- Complete data platform outage
- Security breach with data exposure
- Production database corruption

### P1 - Major Impact

**Criteria:**

- Critical business data affected
- Key dashboards incorrect or unavailable
- Finance/compliance reporting impacted
- Revenue calculation errors

**Impact:**

- Senior leadership notified
- Cross-functional coordination required
- Business operations degraded
- SLA: 30-minute response time

**Examples:**

- Finance dashboard data incorrect (wrong revenue figures)
- Wallet balances showing incorrect amounts
- Critical dbt models failing (fct_wallet_transactions)
- Compliance reporting data missing or wrong

### P2 - Moderate Impact

**Criteria:**

- Degraded performance but functional
- Non-critical dashboards affected
- Workarounds available
- Limited user impact

**Impact:**

- Team notification
- Standard escalation
- Business can continue with workarounds
- SLA: 2-hour response time

**Examples:**

- Metabase dashboards loading slowly (60s vs 10s)
- Non-critical marts delayed (analytics marts)
- Airbyte sync delays on low-priority sources
- Development environment issues

### P3 - Minor Issue

**Criteria:**

- Low business impact
- No immediate user impact
- Can be scheduled for regular sprint
- Documentation or quality improvements

**Impact:**

- No escalation required
- Schedule for next sprint
- Track as regular ticket
- SLA: Next business day

**Examples:**

- Non-critical mart refresh delayed
- Documentation gaps
- Code quality improvements
- Performance optimization opportunities

## Incident Workflow

### Phase 1: Incident Declaration (2-5 minutes)

**If severity/description not provided, gather interactively:**

1. **Classify Severity** - Ask user:

   ```text
   What is the incident severity?

   P0 - Critical Outage (platform down, all pipelines halted)
   P1 - Major Impact (critical data incorrect, key dashboards down)
   P2 - Moderate Impact (degraded performance, workarounds available)
   P3 - Minor Issue (low impact, schedule for sprint)

   Enter severity level (P0/P1/P2/P3):
   ```

2. **Gather Incident Details** - Ask user:

   ```text
   Describe the incident:
   - What is not working or incorrect?
   - When did this start?
   - What is the business impact?
   - Any error messages or symptoms?
   ```

3. **Create Incident Record:**
   - Generate unique incident ID: `INC-YYYY-MM-DD-NNN` (e.g., INC-2025-10-07-001)
   - Create incident file: `.incidents/active/INC-YYYY-MM-DD-NNN.md`
   - Start incident timer for SLA tracking

4. **Initial Notification:**
   - Display incident summary to user
   - Suggest stakeholder notification (don't send automatically)
   - Provide communication template

### Phase 2: Runbook Selection & Diagnostics (5-10 minutes)

**Based on incident description, select appropriate runbook:**

#### Available Runbooks

**dbt Build Failure Runbook:**

- Symptoms: "dbt run failing", "model compilation error", "circular dependency"
- Diagnostics:
  1. Check recent git commits in dbt project
  2. Review dbt run logs: `dbt run --target dev --select <failing_model>`
  3. Check for schema changes in source systems
  4. Validate model tags and configurations
- Route to: `data-engineer` + `snowflake-sql-expert`

**Snowflake Warehouse Timeout Runbook:**

- Symptoms: "warehouse timeout", "query timeout", "warehouse suspended"
- Diagnostics:
  1. Check Snowflake warehouse status
  2. Review query history for long-running queries
  3. Check warehouse size vs. workload
  4. Identify blocking queries or resource contention
- Route to: `cost-optimization-agent` + `snowflake-sql-expert`

**Metabase Dashboard Outage Runbook:**

- Symptoms: "dashboard not loading", "metabase error", "query timeout"
- Diagnostics:
  1. Check Metabase application status
  2. Review underlying SQL query performance
  3. Validate data source connections
  4. Check for schema changes in referenced models
- Route to: `bi-platform-engineer` + `metabase-expert`

**Data Quality Incident Runbook:**

- Symptoms: "incorrect data", "missing records", "duplicate records", "wrong calculations"
- Diagnostics:
  1. Identify affected models and tables
  2. Run data quality tests: `dbt test --select <affected_models>`
  3. Compare current vs. historical data volumes
  4. Check for upstream source data changes
  5. Review recent model changes in git history
- Route to: `data-engineer` + `architect` + `quality-assurance-expert`

**Airbyte Sync Failure Runbook:**

- Symptoms: "airbyte sync failed", "source connection error", "replication delayed"
- Diagnostics:
  1. Check Airbyte connection status
  2. Review sync logs for error messages
  3. Validate source system availability
  4. Check for schema changes in source
- Route to: `data-engineer`

**Security Incident Runbook:**

- Symptoms: "unauthorized access", "data exposure", "permission error"
- Diagnostics:
  1. Identify scope of potential exposure
  2. Review access logs and query history
  3. Validate current permissions and roles
  4. Check for recent permission changes
- Route to: `security-engineer-agent` + `data-governance-agent`

**Display Selected Runbook:**

```text
✓ Runbook Selected: Data Quality Incident - Duplicate Records

Diagnostic Steps:
1. Identifying affected models...
2. Running data quality tests...
3. Comparing data volumes...
4. Checking for upstream changes...

Routing to specialist agents for resolution...
```

### Phase 3: Resolution Coordination (15-60 minutes)

**Route to specialist agents based on incident type:**

**For dbt failures:**

```text
Invoking specialist agents:
- data-engineer: Analyze model logic and dependencies
- snowflake-sql-expert: Optimize query performance and syntax
```

**For warehouse issues:**

```text
Invoking specialist agents:
- cost-optimization-agent: Analyze warehouse sizing and costs
- snowflake-sql-expert: Identify problematic queries
```

**For dashboard outages:**

```text
Invoking specialist agents:
- bi-platform-engineer: Diagnose Metabase application issues
- metabase-expert: Optimize dashboard queries
```

**For data quality:**

```text
Invoking specialist agents:
- data-engineer: Investigate data pipeline logic
- architect: Validate dimensional model design
- quality-assurance-expert: Implement additional tests
```

**Resolution Actions:**

- Execute recommended fixes
- Validate resolution with tests
- Document root cause
- Update incident record with resolution details

### Phase 4: Communication & Postmortem (10-30 minutes)

**1. Generate Incident Timeline:**

```yaml
Incident_Timeline:
  - "14:30 UTC - Incident declared (P1)"
  - "14:35 UTC - Runbook applied: Data Quality Incident"
  - "14:40 UTC - Root cause identified: Schema change introduced duplicates"
  - "14:50 UTC - Fix applied: Deduplication logic added to model"
  - "15:00 UTC - Data reprocessed successfully"
  - "15:15 UTC - Validation complete, incident resolved"
```

**2. Communicate Resolution:**

- Display resolution summary
- Provide stakeholder notification template (don't send automatically)
- Suggest follow-up actions

**3. Postmortem (P0/P1 only):**

- For P0/P1 incidents, create postmortem document
- Include:
  - Incident summary
  - Timeline of events
  - Root cause analysis
  - Resolution steps
  - Prevention measures
  - Action items
- Save to: `.incidents/postmortems/INC-YYYY-MM-DD-NNN-postmortem.md`

**4. Archive Incident:**

- Move incident file from `.incidents/active/` to `.incidents/resolved/`
- Update SLA compliance tracking
- Record learnings for runbook improvements

## Output Format

### Incident Declaration Output

```yaml
🚨 INCIDENT DECLARED

Incident_ID: "INC-2025-10-07-001"
Severity: P1
Status: INVESTIGATING
Declared_At: "2025-10-07 14:30 UTC"
Description: "Finance dashboard showing $0 revenue for today"

Business_Impact:
  - Finance team unable to reconcile daily revenue
  - Stakeholders requesting urgent explanation
  - Potential compliance reporting delay

Initial_Assessment:
  - Affected Models: fct_wallet_transactions, mart_daily_revenue
  - Suspected Cause: Recent schema change in splash_production.wallet_transactions
  - SLA Target: Resolution within 2 hours (by 16:30 UTC)

Next_Steps:
  1. Applying "Data Quality Incident" runbook
  2. Running diagnostic tests on affected models
  3. Routing to data-engineer + architect for resolution

Stakeholder_Communication:
  Template: |
    🚨 [P1 INCIDENT] Finance Dashboard Data Incorrect
    Status: INVESTIGATING
    Impact: Finance team unable to reconcile daily revenue
    ETA: 60 minutes
    Incident Lead: @data-team
    Updates: Every 15 minutes in #incidents

Incident_File: .incidents/active/INC-2025-10-07-001.md
```

### Resolution Output

```yaml
✅ INCIDENT RESOLVED

Incident_ID: "INC-2025-10-07-001"
Severity: P1
Status: RESOLVED
Declared_At: "2025-10-07 14:30 UTC"
Resolved_At: "2025-10-07 15:15 UTC"
Duration: "45 minutes"

Root_Cause:
  Category: "Schema Change"
  Details: |
    Upstream schema change in splash_production.wallet_transactions
    added new transaction_type values without notification.
    Model logic did not account for new values, causing duplicate
    records in aggregation logic.

Resolution:
  - Updated fct_wallet_transactions model with comprehensive transaction_type handling
  - Added deduplication logic to prevent future issues
  - Reprocessed affected data for current day
  - Validated output against expected revenue figures

Validation:
  - ✓ dbt tests passing on fct_wallet_transactions
  - ✓ Data volumes match expected ranges
  - ✓ Finance dashboard showing correct revenue figures
  - ✓ No duplicate records detected

SLA_Compliance:
  Target: "2 hours (by 16:30 UTC)"
  Actual: "45 minutes (15:15 UTC)"
  Status: "MET (75 minutes under SLA)"

Prevention_Measures:
  1. Add schema change monitoring for critical source tables
  2. Implement automated alerts for transaction_type additions
  3. Add data quality test for duplicate detection
  4. Document transaction_type logic in model

Postmortem:
  Required: true (P1 severity)
  File: .incidents/postmortems/INC-2025-10-07-001-postmortem.md
  Scheduled: "2025-10-08 10:00 AM"

Stakeholder_Communication:
  Template: |
    ✅ [RESOLVED] Finance Dashboard Data Incorrect
    Duration: 45 minutes (14:30-15:15 UTC)
    Root Cause: Schema change introduced duplicate records in aggregation
    Fix: Updated model logic, reprocessed data, added monitoring
    Validation: All tests passing, dashboard showing correct data
    Postmortem: Scheduled for 2025-10-08 10:00 AM
    Prevention: Schema monitoring + automated alerts implemented

Incident_File_Moved:
  From: .incidents/active/INC-2025-10-07-001.md
  To: .incidents/resolved/INC-2025-10-07-001.md
```

## Communication Templates

### P0 - Critical Outage

**Initial Notification:**

```text
🚨🚨🚨 [P0 CRITICAL] Snowflake Warehouse Suspended - All Data Pipelines Halted

Status: INVESTIGATING - ALL HANDS
Impact: Complete data platform outage
 - All dbt runs failing
 - All dashboards unable to refresh
 - Business intelligence unavailable

Incident Lead: @data-team
Executive Sponsor: @cto
Response Team: @data-eng, @analytics, @devops

ETA: 30 minutes for initial assessment
Updates: Every 10 minutes in #critical-incidents

Current Actions:
 - Contacting Snowflake support
 - Investigating warehouse suspension cause
 - Preparing failover procedures

DO NOT attempt manual queries until further notice.
```

**Resolution Notification:**

```text
✅ [RESOLVED] Snowflake Warehouse Suspended

Duration: 1 hour 15 minutes
Root Cause: Credit limit exceeded due to unexpected query volume spike
Resolution:
 - Increased credit limit with Snowflake
 - Warehouse resumed operation
 - All pipelines restarted successfully
 - Backlog processing in progress (ETA: 2 hours)

All systems operational. Normal operations resumed.

Postmortem: Required - Scheduled for tomorrow 9:00 AM
Prevention: Implementing automated credit monitoring and query governance
```

### P1 - Major Impact

**Initial Notification:**

```text
🚨 [P1 INCIDENT] Wallet Balance Calculations Incorrect

Status: INVESTIGATING
Impact: Critical financial data affected
 - User wallet balances showing incorrect amounts
 - Finance reconciliation blocked
 - Customer support receiving inquiries

Affected Systems:
 - fct_wallet_transactions
 - dim_wallet_balance
 - Finance dashboards

Incident Lead: @data-team
ETA: 60 minutes for resolution
Updates: Every 15 minutes in #incidents

Current Actions:
 - Identifying root cause in transaction processing
 - Analyzing recent model changes
 - Coordinating with finance team on workarounds
```

**Progress Update:**

```text
📊 [UPDATE] Wallet Balance Calculations - Root Cause Identified

Status: MITIGATING
Elapsed Time: 30 minutes
Root Cause: Recent schema change introduced duplicate transaction records

Resolution in Progress:
 ✓ Deduplication logic implemented
 ✓ Testing on sample data complete
 ⏳ Reprocessing full dataset (ETA: 20 minutes)
 ⏳ Validation against known balances

Next Update: 15 minutes
```

**Resolution Notification:**

```text
✅ [RESOLVED] Wallet Balance Calculations Incorrect

Duration: 55 minutes
Root Cause: Schema change in source data introduced duplicate records
Resolution:
 - Applied deduplication logic to fct_wallet_transactions
 - Reprocessed all transactions for affected period
 - Validated against finance team's manual reconciliation
 - All balances now accurate

Validation:
 ✓ Data quality tests passing
 ✓ Finance team confirmed accuracy
 ✓ Dashboards showing correct balances

Impact: Met 2-hour SLA (5 minutes under)
Postmortem: Scheduled for 2025-10-08 2:00 PM
Prevention: Schema change monitoring + duplicate detection tests added
```

### P2 - Moderate Impact

**Initial Notification:**

```text
⚠️ [P2 INCIDENT] Metabase Dashboards Loading Slowly

Status: INVESTIGATING
Impact: Degraded dashboard performance (60s vs. 10s load times)
 - Analytics dashboards affected
 - Business operations can continue with delays
 - Workaround: Use cached data where available

Affected Dashboards:
 - User Analytics Dashboard
 - Contest Performance Dashboard
 - Marketing Attribution Dashboard

Incident Lead: @bi-team
ETA: 2 hours for resolution
Updates: Every 30 minutes in #incidents
```

**Resolution Notification:**

```text
✅ [RESOLVED] Metabase Dashboards Loading Slowly

Duration: 1 hour 20 minutes
Root Cause: Missing index on high-volume dimension table
Resolution:
 - Added index to dim_user on user_id + created_at
 - Optimized underlying SQL queries in dashboards
 - Dashboard load times restored to normal (8-12s)

Validation:
 ✓ All dashboards tested and performing normally
 ✓ No user complaints since fix

No postmortem required (P2 severity)
Follow-up: Scheduled index review for all dimension tables
```

### P3 - Minor Issue

**Notification:**

```text
ℹ️ [P3 ISSUE] Analytics Mart Refresh Delayed

Status: TRACKING
Impact: Low - non-critical analytics delayed by 3 hours
 - No immediate business impact
 - Users can continue with previous day's data
 - Scheduled for next sprint fix

Root Cause: Incremental model logic needs optimization
Action: Created ticket DA-XXX for next sprint
No further updates required.
```

## Incident File Structure

### Active Incident File (`.incidents/active/INC-YYYY-MM-DD-NNN.md`)

```markdown
---
incident_id: INC-2025-10-07-001
severity: P1
status: investigating
declared_at: "2025-10-07T14:30:00Z"
incident_lead: data-team
tags:
  - data-quality
  - finance
  - critical
---

# INC-2025-10-07-001: Finance Dashboard Data Incorrect

## Incident Summary
Finance dashboard showing $0 revenue for 2025-10-07. Finance team unable to reconcile daily revenue. Critical impact to financial reporting.

## Timeline
- **14:30 UTC** - Incident declared by finance team
- **14:35 UTC** - Data team notified, investigation started
- **14:40 UTC** - Root cause identified: duplicate records in fct_wallet_transactions
- **14:50 UTC** - Fix applied: deduplication logic added
- **15:00 UTC** - Data reprocessing complete
- **15:15 UTC** - Validation complete, incident resolved

## Root Cause
Upstream schema change in `splash_production.wallet_transactions` added new `transaction_type` values without notification. Model aggregation logic did not account for new values, causing duplicate records.

## Resolution
1. Updated `fct_wallet_transactions` model with comprehensive transaction_type handling
2. Added deduplication logic to prevent future duplicates
3. Reprocessed affected data for 2025-10-07
4. Validated output against expected revenue figures from finance team

## Affected Systems
- `models/dwh/core/finance/fct_wallet_transactions.sql`
- `models/dwh/marts/finance/mart_daily_revenue.sql`
- Metabase Finance Dashboard (ID: 42)

## Prevention Measures
1. Add schema change monitoring for `splash_production.wallet_transactions`
2. Implement automated alerts for new transaction_type values
3. Add data quality test for duplicate detection in fct_wallet_transactions
4. Document transaction_type handling logic in model documentation

## SLA Compliance
- **Target:** 2 hours (by 16:30 UTC)
- **Actual:** 45 minutes (resolved at 15:15 UTC)
- **Status:** MET (75 minutes under SLA)

## Postmortem Required
Yes - P1 severity requires postmortem
Scheduled: 2025-10-08 10:00 AM
```

## Directory Structure

The command will create and maintain:

```text
.incidents/
├── active/                          # Currently active incidents
│   └── INC-YYYY-MM-DD-NNN.md
├── resolved/                        # Resolved incidents (archive)
│   ├── INC-2025-10-07-001.md
│   └── INC-2025-10-07-002.md
├── postmortems/                     # Postmortem documents (P0/P1)
│   ├── INC-2025-10-07-001-postmortem.md
│   └── INC-2025-10-07-002-postmortem.md
└── runbooks/                        # Incident response runbooks
    ├── dbt-build-failure.md
    ├── snowflake-warehouse-timeout.md
    ├── metabase-dashboard-outage.md
    ├── data-quality-incident.md
    ├── airbyte-sync-failure.md
    └── security-incident.md
```

## Success Criteria

**Incident Declaration:**

- ✓ Severity correctly classified
- ✓ Incident ID generated and file created
- ✓ Stakeholder notification template provided
- ✓ SLA timer started

**Resolution:**

- ✓ Root cause identified and documented
- ✓ Fix applied and validated
- ✓ All affected systems tested
- ✓ SLA compliance tracked
- ✓ Postmortem scheduled (P0/P1)
- ✓ Prevention measures documented

**Communication:**

- ✓ Clear, concise incident descriptions
- ✓ Regular status updates (per severity SLA)
- ✓ Resolution summary with learnings
- ✓ Stakeholder templates ready (not auto-sent)

## Error Handling

**Invalid Severity:**

```text
❌ Invalid severity level: "P5"
Valid levels: P0, P1, P2, P3

P0 - Critical Outage (platform down)
P1 - Major Impact (critical data incorrect)
P2 - Moderate Impact (degraded performance)
P3 - Minor Issue (low impact)

Please specify a valid severity level.
```

**Missing Incident Description:**

```text
Please provide an incident description:
- What is not working or incorrect?
- When did this start?
- What is the business impact?
```

**Runbook Not Found:**

```text
⚠️ No exact runbook match for this incident type.
Using generic incident response workflow.

Suggested runbook creation:
- Document this incident pattern
- Create dedicated runbook for future incidents
- File: .incidents/runbooks/[incident-type].md
```

## Examples

### Example 1: P0 Critical Outage

```bash
$ /incident P0 "Snowflake warehouse suspended - all dbt runs failing"

🚨🚨🚨 CRITICAL INCIDENT DECLARED

Incident_ID: INC-2025-10-07-001
Severity: P0 - CRITICAL OUTAGE
Status: INVESTIGATING
Declared_At: 2025-10-07 14:30 UTC

Description: Snowflake warehouse suspended - all dbt runs failing

Business_Impact:
  - Complete data platform outage
  - All data pipelines halted
  - All dashboards unable to refresh
  - Business intelligence unavailable

SLA_Target: 15-minute response time

✓ Runbook Selected: Snowflake Warehouse Timeout

Diagnostic Steps:
1. Checking Snowflake warehouse status...
   Status: SUSPENDED
   Reason: Credit limit exceeded

2. Reviewing query history...
   Found: Runaway query from 14:15 UTC consuming excessive credits

3. Checking warehouse size vs. workload...
   Warehouse: X-LARGE
   Unexpected query volume: 10x normal

Immediate Actions:
1. Contacting Snowflake support for credit increase
2. Killing runaway query
3. Preparing warehouse restart procedure

Routing to specialist agents:
- cost-optimization-agent: Analyze credit consumption
- snowflake-sql-expert: Identify and kill problematic queries

Stakeholder Notification Template:
---
🚨🚨🚨 [P0 CRITICAL] Snowflake Warehouse Suspended
Status: INVESTIGATING - ALL HANDS
Impact: Complete data platform outage
ETA: 30 minutes for warehouse restart
Updates: Every 10 minutes in #critical-incidents
Incident Lead: @data-team
---

Incident File: .incidents/active/INC-2025-10-07-001.md
```

### Example 2: P1 Data Quality Issue

```bash
$ /incident

What is the incident severity?

P0 - Critical Outage (platform down, all pipelines halted)
P1 - Major Impact (critical data incorrect, key dashboards down)
P2 - Moderate Impact (degraded performance, workarounds available)
P3 - Minor Issue (low impact, schedule for sprint)

Enter severity level (P0/P1/P2/P3): P1

Describe the incident:
> Finance dashboard showing $0 revenue for today. Finance team can't reconcile. Started around 2 hours ago.

🚨 INCIDENT DECLARED

Incident_ID: INC-2025-10-07-002
Severity: P1 - MAJOR IMPACT
Status: INVESTIGATING
Declared_At: 2025-10-07 16:45 UTC

Description: Finance dashboard showing $0 revenue for today

Business_Impact:
  - Finance team unable to reconcile daily revenue
  - Critical financial reporting blocked
  - Potential compliance delay

SLA_Target: 2-hour resolution (by 18:45 UTC)

✓ Runbook Selected: Data Quality Incident - Missing/Incorrect Data

Diagnostic Steps:
1. Identifying affected models...
   Affected: fct_wallet_transactions, mart_daily_revenue

2. Running data quality tests...
   $ dbt test --select fct_wallet_transactions mart_daily_revenue
   FAIL - fct_wallet_transactions: duplicate records detected

3. Comparing data volumes...
   Expected rows: ~50,000
   Actual rows: 98,543
   Discrepancy: 48,543 duplicate records (97% increase)

4. Checking recent git changes...
   Found: Schema change in splash_production.wallet_transactions (2 hours ago)
   Change: Added new transaction_type values

Root Cause Identified:
  Category: Schema Change
  Details: New transaction_type values not handled in aggregation logic
  Result: Duplicate records causing incorrect revenue calculations

Resolution Plan:
1. Update fct_wallet_transactions with comprehensive transaction_type handling
2. Add deduplication logic
3. Reprocess data for affected period
4. Validate against finance team reconciliation

Routing to specialist agents:
- data-engineer: Fix model logic and reprocess
- architect: Review dimensional model design
- quality-assurance-expert: Add duplicate detection tests

Estimated Resolution: 45 minutes

Stakeholder Notification Template:
---
🚨 [P1 INCIDENT] Finance Dashboard Data Incorrect
Status: INVESTIGATING - ROOT CAUSE IDENTIFIED
Impact: Finance team unable to reconcile daily revenue
Root Cause: Schema change introduced duplicate records
Resolution In Progress: Fixing model logic and reprocessing data
ETA: 45 minutes (by 17:30 UTC)
Updates: Every 15 minutes in #incidents
Incident Lead: @data-team
---

Incident File: .incidents/active/INC-2025-10-07-002.md
```

### Example 3: P2 Performance Degradation

```bash
$ /incident P2 "Metabase dashboards loading very slowly (60s vs normal 10s)"

⚠️ INCIDENT DECLARED

Incident_ID: INC-2025-10-07-003
Severity: P2 - MODERATE IMPACT
Status: INVESTIGATING
Declared_At: 2025-10-07 11:20 UTC

Description: Metabase dashboards loading very slowly (60s vs normal 10s)

Business_Impact:
  - Degraded dashboard performance
  - Users experiencing delays but can work with workarounds
  - No critical business operations blocked

SLA_Target: 2-hour response time

✓ Runbook Selected: Metabase Dashboard Performance Issues

Diagnostic Steps:
1. Checking Metabase application status...
   Status: HEALTHY
   Response Time: Normal

2. Reviewing underlying SQL query performance...
   Found: Queries on dim_user taking 45s (normally 2s)
   Affected Dashboards: 5 dashboards using dim_user

3. Analyzing query execution plans...
   Issue: Missing index on dim_user (user_id, created_at)
   Result: Full table scan on 10M+ rows

Resolution Plan:
1. Add missing index to dim_user
2. Optimize dashboard SQL queries
3. Test performance improvement
4. Monitor dashboard load times

Routing to specialist agents:
- bi-platform-engineer: Diagnose Metabase performance
- snowflake-sql-expert: Add index and optimize queries
- metabase-expert: Review and optimize dashboard SQL

Estimated Resolution: 1 hour

Stakeholder Notification Template:
---
⚠️ [P2 INCIDENT] Metabase Dashboards Loading Slowly
Status: INVESTIGATING - ROOT CAUSE IDENTIFIED
Impact: Dashboard load times degraded (60s vs 10s normal)
Root Cause: Missing database index on high-volume table
Workaround: Use cached data where available
Resolution In Progress: Adding index and optimizing queries
ETA: 1 hour (by 12:20 UTC)
Updates: Every 30 minutes in #incidents
---

Incident File: .incidents/active/INC-2025-10-07-003.md
```

## Notes

- **Stakeholder notifications are provided as templates only** - the command does NOT automatically send notifications
- **Postmortems are required for P0/P1 incidents** and optional for P2/P3
- **SLA tracking is automatic** based on severity level
- **Runbooks are applied automatically** based on incident symptoms
- **Specialist agents are invoked** for resolution coordination
- **All incidents are archived** for learning and pattern analysis
- **Communication templates follow severity-appropriate tone** and update frequency

---

**Related Commands:**

- `/start-work` - Resume work after incident resolution
- `/create-issue` - Create follow-up tickets for prevention measures
- `/expert-analysis` - Deep-dive analysis for complex root causes
