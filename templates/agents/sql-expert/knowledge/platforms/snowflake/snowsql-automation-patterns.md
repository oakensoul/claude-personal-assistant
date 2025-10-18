---
title: "SnowSQL Automation Patterns"
description: "Advanced SnowSQL automation patterns for CI/CD pipelines, bash scripting, parallel execution, and operational workflows"
agent: "snowflake-sql-expert"
category: "patterns"
tags:
  - snowsql
  - automation
  - ci-cd
  - bash-scripting
  - parallel-execution
  - error-handling
  - github-actions
last_updated: "2025-10-07"
priority: "high"
use_cases:
  - "CI/CD pipeline integration"
  - "Data quality validation"
  - "Batch query execution"
  - "Multi-environment deployments"
  - "Operational monitoring"
---

# SnowSQL Automation Patterns

## Overview

This guide covers advanced SnowSQL automation patterns for integrating Snowflake operations into CI/CD pipelines, bash scripts, and operational workflows in the dbt-splash-prod-v2 project.

## Connection Management for Automation

### Environment-Based Connection Selection

```bash
#!/usr/bin/env bash
# Script: scripts/snowflake/run_query.sh

set -euo pipefail

# Determine environment from argument or default to dev
ENVIRONMENT="${1:-dev}"

# Validate environment
case "$ENVIRONMENT" in
    dev|prod|build)
        echo "Using environment: $ENVIRONMENT"
        ;;
    *)
        echo "Error: Invalid environment '$ENVIRONMENT'. Use: dev, prod, or build"
        exit 1
        ;;
esac

# Execute query using environment-specific connection
snowsql -c "$ENVIRONMENT" -f analyses/my_query.sql
```

### Using Environment Variables for Credentials

```bash
#!/usr/bin/env bash
# Script: scripts/snowflake/validate_data.sh

# Set Snowflake credentials from environment variables (CI/CD secrets)
export SNOWSQL_ACCOUNT="${SNOWFLAKE_ACCOUNT}"
export SNOWSQL_USER="${SNOWFLAKE_USER}"
export SNOWSQL_PWD="${SNOWFLAKE_PASSWORD}"
export SNOWSQL_ROLE="${SNOWFLAKE_ROLE}"
export SNOWSQL_WAREHOUSE="${SNOWFLAKE_WAREHOUSE}"
export SNOWSQL_DATABASE="${SNOWFLAKE_DATABASE}"

# Execute query without named connection
snowsql \
    -a "$SNOWSQL_ACCOUNT" \
    -u "$SNOWSQL_USER" \
    -r "$SNOWSQL_ROLE" \
    -w "$SNOWSQL_WAREHOUSE" \
    -d "$SNOWSQL_DATABASE" \
    -q "SELECT COUNT(*) FROM fct_wallet_transactions WHERE transaction_date_et = CURRENT_DATE();"
```

### Connection Pooling Pattern

```bash
#!/usr/bin/env bash
# Script: scripts/snowflake/multi_connection_workflow.sh

# Function to execute query with specific connection
execute_with_connection() {
    local connection_name="$1"
    local query_file="$2"

    echo "Executing $query_file with connection $connection_name..."
    snowsql -c "$connection_name" -f "$query_file" -o quiet=true -o output_format=tsv
}

# Execute queries across multiple connections/roles
execute_with_connection "prod_transformer" "queries/transform_data.sql"
execute_with_connection "prod_reporter" "queries/generate_report.sql"
execute_with_connection "prod_admin" "queries/grant_permissions.sql"
```

## Error Handling & Exit Codes

### Robust Error Handling Pattern

```bash
#!/usr/bin/env bash
# Script: scripts/snowflake/safe_query_execution.sh

set -euo pipefail

QUERY_FILE="${1:?Query file required}"
LOG_FILE="logs/snowsql_$(date +%Y%m%d_%H%M%S).log"

mkdir -p logs

# Execute with error handling
if snowsql -c prod -f "$QUERY_FILE" -o log_level=DEBUG -o log_file="$LOG_FILE"; then
    echo "✅ Query executed successfully: $QUERY_FILE"
    echo "Log: $LOG_FILE"
    exit 0
else
    EXIT_CODE=$?
    echo "❌ Query failed with exit code $EXIT_CODE: $QUERY_FILE"
    echo "Check log: $LOG_FILE"

    # Send alert (example: Slack webhook)
    if [ -n "${SLACK_WEBHOOK_URL:-}" ]; then
        curl -X POST "$SLACK_WEBHOOK_URL" \
            -H 'Content-Type: application/json' \
            -d "{\"text\": \"SnowSQL query failed: $QUERY_FILE (exit code $EXIT_CODE)\"}"
    fi

    exit "$EXIT_CODE"
fi
```

### Retry Logic for Transient Failures

```bash
#!/usr/bin/env bash
# Script: scripts/snowflake/retry_query.sh

set -euo pipefail

MAX_RETRIES=3
RETRY_DELAY=5

execute_with_retry() {
    local query_file="$1"
    local attempt=1

    while [ $attempt -le $MAX_RETRIES ]; do
        echo "Attempt $attempt of $MAX_RETRIES: $query_file"

        if snowsql -c prod -f "$query_file" -o quiet=true; then
            echo "✅ Success on attempt $attempt"
            return 0
        else
            EXIT_CODE=$?
            echo "⚠️  Failed with exit code $EXIT_CODE"

            if [ $attempt -lt $MAX_RETRIES ]; then
                echo "Retrying in ${RETRY_DELAY}s..."
                sleep $RETRY_DELAY
                attempt=$((attempt + 1))
            else
                echo "❌ All $MAX_RETRIES attempts failed"
                return $EXIT_CODE
            fi
        fi
    done
}

# Usage
execute_with_retry "queries/critical_data_load.sql"
```

## Parallel Query Execution

### Basic Parallel Pattern with GNU Parallel

```bash
#!/usr/bin/env bash
# Script: scripts/snowflake/parallel_validation.sh

set -euo pipefail

# Array of validation queries
VALIDATION_QUERIES=(
    "analyses/validate_wallet_transactions.sql"
    "analyses/validate_contest_entries.sql"
    "analyses/validate_user_data.sql"
    "analyses/validate_partner_data.sql"
)

# Function to execute single validation
run_validation() {
    local query_file="$1"
    local query_name=$(basename "$query_file" .sql)

    echo "Running: $query_name"
    if snowsql -c prod -f "$query_file" -o quiet=true -o output_format=tsv > "results/${query_name}.tsv"; then
        echo "✅ $query_name completed"
    else
        echo "❌ $query_name failed"
        return 1
    fi
}

export -f run_validation

mkdir -p results

# Execute validations in parallel (4 at a time)
parallel -j 4 run_validation ::: "${VALIDATION_QUERIES[@]}"

echo "All validations complete. Results in results/"
```

### Parallel Execution with Background Jobs (No GNU Parallel)

```bash
#!/usr/bin/env bash
# Script: scripts/snowflake/parallel_queries_native.sh

set -euo pipefail

MAX_PARALLEL=4
PIDS=()

# Function to execute query in background
execute_async() {
    local query_file="$1"
    local output_file="$2"

    snowsql -c prod -f "$query_file" -o quiet=true -o output_format=csv > "$output_file" 2>&1 &
    PIDS+=($!)
}

# Submit queries
execute_async "queries/daily_revenue.sql" "results/daily_revenue.csv"
execute_async "queries/daily_users.sql" "results/daily_users.csv"
execute_async "queries/daily_contests.sql" "results/daily_contests.csv"
execute_async "queries/daily_transactions.sql" "results/daily_transactions.csv"

# Wait for all background jobs to complete
echo "Waiting for ${#PIDS[@]} queries to complete..."
FAILED=0

for pid in "${PIDS[@]}"; do
    if wait "$pid"; then
        echo "✅ Process $pid completed"
    else
        echo "❌ Process $pid failed"
        FAILED=$((FAILED + 1))
    fi
done

if [ $FAILED -eq 0 ]; then
    echo "✅ All queries completed successfully"
    exit 0
else
    echo "❌ $FAILED queries failed"
    exit 1
fi
```

## Variable Substitution for Parameterized Queries

### Using SnowSQL Variables (-D flag)

```bash
#!/usr/bin/env bash
# Script: scripts/snowflake/daily_report.sh

REPORT_DATE="${1:-$(date +%Y-%m-%d)}"

echo "Generating report for $REPORT_DATE..."

snowsql -c prod \
    -D report_date="'$REPORT_DATE'" \
    -D min_transaction_amount=10.00 \
    -f queries/daily_finance_report.sql \
    -o output_format=csv \
    -o output_file="reports/finance_report_${REPORT_DATE}.csv"
```

**Query file** (queries/daily_finance_report.sql):
```sql
-- Variable substitution using &{variable_name}
select
    transaction_date_et,
    count(*) as transaction_count,
    sum(amount_cents) / 100.0 as total_amount_usd
from {{ ref('fct_wallet_transactions') }}
where transaction_date_et = &{report_date}
    and amount_cents / 100.0 >= &{min_transaction_amount}
group by transaction_date_et;
```

### Environment Variable Substitution in Bash

```bash
#!/usr/bin/env bash
# Script: scripts/snowflake/templated_query.sh

START_DATE="${1:?Start date required (YYYY-MM-DD)}"
END_DATE="${2:?End date required (YYYY-MM-DD)}"
OUTPUT_FILE="results/transactions_${START_DATE}_to_${END_DATE}.csv"

# Generate SQL from template using envsubst
export START_DATE END_DATE

cat > /tmp/query_$$.sql <<'EOF'
select
    transaction_date_et,
    transaction_type,
    count(*) as transaction_count,
    sum(amount_cents) / 100.0 as total_amount_usd
from {{ ref('fct_wallet_transactions') }}
where transaction_date_et between '${START_DATE}' and '${END_DATE}'
group by transaction_date_et, transaction_type
order by transaction_date_et, transaction_type;
EOF

# Substitute environment variables
envsubst < /tmp/query_$$.sql > /tmp/query_final_$$.sql

# Execute
snowsql -c prod -f /tmp/query_final_$$.sql -o output_format=csv -o output_file="$OUTPUT_FILE"

# Cleanup
rm /tmp/query_$$.sql /tmp/query_final_$$.sql

echo "Results written to: $OUTPUT_FILE"
```

## CI/CD Integration Patterns

### GitHub Actions - Data Validation Workflow

```yaml
# .github/workflows/data-validation.yml
name: Snowflake Data Validation

on:
  schedule:
    - cron: '0 */6 * * *'  # Every 6 hours
  workflow_dispatch:

jobs:
  validate-data:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Install SnowSQL
        run: |
          curl -O https://sfc-repo.snowflakecomputing.com/snowsql/bootstrap/1.2/linux_x86_64/snowsql-1.2.24-linux_x86_64.bash
          SNOWSQL_DEST=~/bin SNOWSQL_LOGIN_SHELL=~/.profile bash snowsql-1.2.24-linux_x86_64.bash
          ~/bin/snowsql --version

      - name: Configure SnowSQL
        env:
          SNOWFLAKE_ACCOUNT: ${{ secrets.SNOWFLAKE_ACCOUNT }}
          SNOWFLAKE_USER: ${{ secrets.SNOWFLAKE_USER }}
          SNOWFLAKE_PASSWORD: ${{ secrets.SNOWFLAKE_PASSWORD }}
          SNOWFLAKE_ROLE: ${{ secrets.SNOWFLAKE_ROLE }}
          SNOWFLAKE_WAREHOUSE: ${{ secrets.SNOWFLAKE_WAREHOUSE }}
          SNOWFLAKE_DATABASE: PROD
        run: |
          mkdir -p ~/.snowsql
          cat > ~/.snowsql/config <<EOF
          [connections.prod]
          accountname = ${SNOWFLAKE_ACCOUNT}
          username = ${SNOWFLAKE_USER}
          password = ${SNOWFLAKE_PASSWORD}
          rolename = ${SNOWFLAKE_ROLE}
          warehousename = ${SNOWFLAKE_WAREHOUSE}
          dbname = ${SNOWFLAKE_DATABASE}

          [options]
          exit_on_error = true
          EOF

      - name: Run wallet transaction validation
        run: |
          ~/bin/snowsql -c prod -f analyses/validate_wallet_transactions.sql -o quiet=true

      - name: Run contest entry validation
        run: |
          ~/bin/snowsql -c prod -f analyses/validate_contest_entries.sql -o quiet=true

      - name: Notify on failure
        if: failure()
        uses: slackapi/slack-github-action@v1
        with:
          webhook-url: ${{ secrets.SLACK_WEBHOOK_URL }}
          payload: |
            {
              "text": "❌ Data validation failed in ${{ github.repository }}",
              "blocks": [
                {
                  "type": "section",
                  "text": {
                    "type": "mrkdwn",
                    "text": "Data validation workflow failed. Check logs: ${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}"
                  }
                }
              ]
            }
```

### GitHub Actions - Query Execution with Results Upload

```yaml
# .github/workflows/daily-report.yml
name: Daily Finance Report

on:
  schedule:
    - cron: '0 9 * * *'  # 9 AM UTC daily
  workflow_dispatch:

jobs:
  generate-report:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Install SnowSQL
        run: |
          curl -O https://sfc-repo.snowflakecomputing.com/snowsql/bootstrap/1.2/linux_x86_64/snowsql-1.2.24-linux_x86_64.bash
          SNOWSQL_DEST=~/bin SNOWSQL_LOGIN_SHELL=~/.profile bash snowsql-1.2.24-linux_x86_64.bash

      - name: Generate daily finance report
        env:
          SNOWSQL_ACCOUNT: ${{ secrets.SNOWFLAKE_ACCOUNT }}
          SNOWSQL_USER: ${{ secrets.SNOWFLAKE_USER }}
          SNOWSQL_PWD: ${{ secrets.SNOWFLAKE_PASSWORD }}
          SNOWSQL_ROLE: ${{ secrets.SNOWFLAKE_ROLE }}
          SNOWSQL_WAREHOUSE: ${{ secrets.SNOWFLAKE_WAREHOUSE }}
          SNOWSQL_DATABASE: PROD
        run: |
          REPORT_DATE=$(date +%Y-%m-%d)
          mkdir -p reports

          ~/bin/snowsql \
            -c prod \
            -D report_date="'$REPORT_DATE'" \
            -f queries/daily_finance_report.sql \
            -o output_format=csv \
            -o output_file="reports/finance_report_${REPORT_DATE}.csv"

      - name: Upload report to S3
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        run: |
          REPORT_DATE=$(date +%Y-%m-%d)
          aws s3 cp "reports/finance_report_${REPORT_DATE}.csv" \
            "s3://splash-reports/finance/daily/${REPORT_DATE}.csv"

      - name: Upload artifact
        uses: actions/upload-artifact@v3
        with:
          name: daily-finance-report
          path: reports/*.csv
          retention-days: 30
```

## Output Processing Patterns

### Parse CSV Output in Bash

```bash
#!/usr/bin/env bash
# Script: scripts/snowflake/process_query_results.sh

set -euo pipefail

OUTPUT_FILE="results/user_counts.csv"

# Execute query
snowsql -c prod \
    -q "SELECT user_state, COUNT(*) as user_count FROM dim_user GROUP BY user_state ORDER BY user_state" \
    -o output_format=csv \
    -o header=true \
    -o output_file="$OUTPUT_FILE"

# Process CSV results
echo "User counts by state:"
while IFS=, read -r state count; do
    if [ "$state" != "USER_STATE" ]; then  # Skip header
        printf "  %s: %'d users\n" "$state" "$count"
    fi
done < "$OUTPUT_FILE"

# Check for critical threshold
TOTAL_USERS=$(tail -n +2 "$OUTPUT_FILE" | awk -F, '{sum += $2} END {print sum}')
THRESHOLD=100000

if [ "$TOTAL_USERS" -lt "$THRESHOLD" ]; then
    echo "❌ WARNING: Total users ($TOTAL_USERS) below threshold ($THRESHOLD)"
    exit 1
else
    echo "✅ Total users: $TOTAL_USERS"
fi
```

### JSON Output Processing with jq

```bash
#!/usr/bin/env bash
# Script: scripts/snowflake/json_results.sh

set -euo pipefail

# Execute query with JSON output
snowsql -c prod \
    -q "SELECT contest_id, contest_name, entry_count FROM dim_contest ORDER BY entry_count DESC LIMIT 10" \
    -o output_format=json \
    -o quiet=true > results/top_contests.json

# Process with jq
echo "Top 10 contests by entries:"
jq -r '.[] | "\(.CONTEST_NAME): \(.ENTRY_COUNT) entries"' results/top_contests.json

# Extract specific fields
TOP_CONTEST=$(jq -r '.[0].CONTEST_NAME' results/top_contests.json)
TOP_COUNT=$(jq -r '.[0].ENTRY_COUNT' results/top_contests.json)

echo ""
echo "Most popular contest: $TOP_CONTEST ($TOP_COUNT entries)"
```

## Logging and Monitoring Patterns

### Comprehensive Logging Script

```bash
#!/usr/bin/env bash
# Script: scripts/snowflake/logged_execution.sh

set -euo pipefail

QUERY_FILE="${1:?Query file required}"
QUERY_NAME=$(basename "$QUERY_FILE" .sql)
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_DIR="logs/snowsql"
LOG_FILE="${LOG_DIR}/${QUERY_NAME}_${TIMESTAMP}.log"

mkdir -p "$LOG_DIR"

# Log execution start
{
    echo "==================================="
    echo "Query: $QUERY_NAME"
    echo "File: $QUERY_FILE"
    echo "Started: $(date +'%Y-%m-%d %H:%M:%S')"
    echo "==================================="
} | tee "$LOG_FILE"

# Execute with timing
START_TIME=$(date +%s)

if snowsql -c prod -f "$QUERY_FILE" -o timing=true 2>&1 | tee -a "$LOG_FILE"; then
    EXIT_CODE=0
    STATUS="✅ SUCCESS"
else
    EXIT_CODE=$?
    STATUS="❌ FAILED (exit code $EXIT_CODE)"
fi

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

# Log execution end
{
    echo ""
    echo "==================================="
    echo "Status: $STATUS"
    echo "Duration: ${DURATION}s"
    echo "Completed: $(date +'%Y-%m-%d %H:%M:%S')"
    echo "Log: $LOG_FILE"
    echo "==================================="
} | tee -a "$LOG_FILE"

# Store metrics
cat >> "${LOG_DIR}/execution_metrics.csv" <<EOF
$TIMESTAMP,$QUERY_NAME,$DURATION,$EXIT_CODE
EOF

exit $EXIT_CODE
```

### Query Performance Tracking

```bash
#!/usr/bin/env bash
# Script: scripts/snowflake/track_performance.sh

set -euo pipefail

QUERY_ID_FILE=$(mktemp)

# Execute query and capture query ID
snowsql -c prod -f "$1" -o output_format=tsv | tee >(head -1 > "$QUERY_ID_FILE")

# Get query ID (from query_history or output)
QUERY_ID=$(cat "$QUERY_ID_FILE")

# Fetch performance metrics
snowsql -c prod -q "
SELECT
    query_id,
    query_text,
    total_elapsed_time / 1000 as execution_time_seconds,
    bytes_scanned / (1024*1024*1024) as gb_scanned,
    partitions_scanned,
    partitions_total,
    bytes_spilled_to_local_storage / (1024*1024*1024) as gb_spilled_local
FROM table(information_schema.query_history())
WHERE query_id = '$QUERY_ID'
" -o output_format=json -o quiet=true > "metrics/query_${QUERY_ID}.json"

rm "$QUERY_ID_FILE"

echo "Performance metrics saved: metrics/query_${QUERY_ID}.json"
```

## Data Export Patterns

### Export to Multiple Formats

```bash
#!/usr/bin/env bash
# Script: scripts/snowflake/multi_format_export.sh

set -euo pipefail

QUERY_FILE="$1"
OUTPUT_BASE="results/$(basename "$QUERY_FILE" .sql)"

mkdir -p results

# Export to CSV
snowsql -c prod -f "$QUERY_FILE" \
    -o output_format=csv \
    -o header=true \
    -o output_file="${OUTPUT_BASE}.csv"

# Export to JSON
snowsql -c prod -f "$QUERY_FILE" \
    -o output_format=json \
    -o output_file="${OUTPUT_BASE}.json"

# Export to TSV
snowsql -c prod -f "$QUERY_FILE" \
    -o output_format=tsv \
    -o output_file="${OUTPUT_BASE}.tsv"

echo "Exported to:"
echo "  - ${OUTPUT_BASE}.csv"
echo "  - ${OUTPUT_BASE}.json"
echo "  - ${OUTPUT_BASE}.tsv"
```

### Large Result Set Pagination

```bash
#!/usr/bin/env bash
# Script: scripts/snowflake/paginated_export.sh

set -euo pipefail

TABLE_NAME="$1"
ROWS_PER_PAGE=100000
OUTPUT_DIR="results/paginated"

mkdir -p "$OUTPUT_DIR"

# Get total row count
TOTAL_ROWS=$(snowsql -c prod \
    -q "SELECT COUNT(*) FROM $TABLE_NAME" \
    -o output_format=tsv \
    -o quiet=true)

echo "Total rows: $TOTAL_ROWS"
TOTAL_PAGES=$(( (TOTAL_ROWS + ROWS_PER_PAGE - 1) / ROWS_PER_PAGE ))

# Export in pages
for ((PAGE=0; PAGE<TOTAL_PAGES; PAGE++)); do
    OFFSET=$((PAGE * ROWS_PER_PAGE))
    echo "Exporting page $((PAGE + 1)) of $TOTAL_PAGES (offset $OFFSET)..."

    snowsql -c prod \
        -q "SELECT * FROM $TABLE_NAME ORDER BY id LIMIT $ROWS_PER_PAGE OFFSET $OFFSET" \
        -o output_format=csv \
        -o header=true \
        -o output_file="${OUTPUT_DIR}/page_$(printf '%04d' $PAGE).csv"
done

echo "Export complete: $TOTAL_PAGES files in $OUTPUT_DIR"
```

## Maintenance and Operational Patterns

### Warehouse Management

```bash
#!/usr/bin/env bash
# Script: scripts/snowflake/manage_warehouse.sh

set -euo pipefail

WAREHOUSE="${1:-COMPUTE_WH}"
ACTION="${2:-status}"

case "$ACTION" in
    status)
        snowsql -c prod -q "SHOW WAREHOUSES LIKE '$WAREHOUSE'"
        ;;
    suspend)
        echo "Suspending warehouse: $WAREHOUSE"
        snowsql -c prod -q "ALTER WAREHOUSE $WAREHOUSE SUSPEND"
        ;;
    resume)
        echo "Resuming warehouse: $WAREHOUSE"
        snowsql -c prod -q "ALTER WAREHOUSE $WAREHOUSE RESUME"
        ;;
    resize)
        SIZE="${3:?Size required (XSMALL, SMALL, MEDIUM, LARGE, XLARGE)}"
        echo "Resizing warehouse $WAREHOUSE to $SIZE"
        snowsql -c prod -q "ALTER WAREHOUSE $WAREHOUSE SET WAREHOUSE_SIZE = '$SIZE'"
        ;;
    *)
        echo "Usage: $0 WAREHOUSE_NAME [status|suspend|resume|resize SIZE]"
        exit 1
        ;;
esac
```

### Scheduled Cleanup Operations

```bash
#!/usr/bin/env bash
# Script: scripts/snowflake/cleanup_old_data.sh

set -euo pipefail

RETENTION_DAYS="${1:-90}"

echo "Cleaning up data older than $RETENTION_DAYS days..."

# Drop old staging tables
snowsql -c prod -q "
SHOW TABLES IN SCHEMA ANALYTICS_STAGING LIKE 'TEMP_%';
" -o output_format=csv | tail -n +2 | while IFS=, read -r table_name created_on rest; do
    CREATED=$(date -d "$created_on" +%s 2>/dev/null || echo 0)
    CUTOFF=$(date -d "$RETENTION_DAYS days ago" +%s)

    if [ "$CREATED" -lt "$CUTOFF" ]; then
        echo "Dropping old temp table: $table_name"
        snowsql -c prod -q "DROP TABLE IF EXISTS ANALYTICS_STAGING.$table_name"
    fi
done

echo "Cleanup complete"
```

## Best Practices Summary

### Security
- [ ] Store credentials in environment variables or CI/CD secrets
- [ ] Never commit passwords to version control
- [ ] Use role-based access control (RBAC)
- [ ] Rotate credentials regularly
- [ ] Use named connections for local development only

### Error Handling
- [ ] Always use `set -euo pipefail` in bash scripts
- [ ] Implement retry logic for transient failures
- [ ] Log all executions with timestamps
- [ ] Send alerts on critical failures
- [ ] Capture exit codes and handle appropriately

### Performance
- [ ] Use parallel execution for independent queries
- [ ] Limit parallelism to avoid overwhelming warehouse
- [ ] Use appropriate warehouse size for workload
- [ ] Suspend warehouses when not in use
- [ ] Page large result sets to avoid memory issues

### Maintainability
- [ ] Use meaningful log file names with timestamps
- [ ] Document variable substitution patterns
- [ ] Keep scripts modular and reusable
- [ ] Version control all automation scripts
- [ ] Test scripts in dev before production use

## Additional Resources

**SnowSQL Documentation**:
- [SnowSQL Command Reference](https://docs.snowflake.com/en/user-guide/snowsql-use.html)
- [SnowSQL Configuration](https://docs.snowflake.com/en/user-guide/snowsql-config.html)
- [Exit Codes](https://docs.snowflake.com/en/user-guide/snowsql-use.html#exit-codes)

**Project Integration**:
- CI/CD: GitHub Actions for data validation
- Monitoring: Daily report generation
- Operations: Warehouse management, cleanup tasks

---

**Last Updated**: 2025-10-07
**Agent**: snowflake-sql-expert
**Knowledge Category**: Patterns
