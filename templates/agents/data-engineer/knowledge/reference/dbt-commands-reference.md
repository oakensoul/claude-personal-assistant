---
title: "dbt Commands Reference"
description: "Quick reference for common dbt CLI commands and patterns"
category: "reference"
last_updated: "2025-10-15"
---

# dbt Commands Reference

## Core Commands

### run
Execute models (creates tables/views in warehouse):
```bash
# Run all models
dbt run

# Run specific model
dbt run --select my_model

# Run model + downstream dependencies
dbt run --select my_model+

# Run upstream dependencies + model
dbt run --select +my_model

# Run all models in directory
dbt run --select staging.*

# Run by tag
dbt run --select tag:finance
```

### test
Run data tests:
```bash
# Run all tests
dbt test

# Test specific model
dbt test --select my_model

# Run only schema tests
dbt test --select test_type:schema

# Run only data tests
dbt test --select test_type:data
```

### build
Run models + tests in dependency order:
```bash
# Build all
dbt build

# Build specific model with tests
dbt build --select my_model

# Build modified models (slim CI)
dbt build --select state:modified+ --defer --state prod-manifest/
```

### compile
Generate SQL without executing:
```bash
# Compile all models
dbt compile

# Compile specific model
dbt compile --select my_model

# View compiled SQL
cat target/compiled/my_project/models/my_model.sql
```

## Documentation Commands

### docs generate
Generate documentation:
```bash
dbt docs generate

# With custom target
dbt docs generate --target prod
```

### docs serve
Serve documentation locally:
```bash
dbt docs serve

# Custom port
dbt docs serve --port 8001
```

## Source Commands

### source freshness
Check source data freshness:
```bash
# Check all sources
dbt source freshness

# Check specific source
dbt source freshness --select source:raw
```

### list sources
List all sources:
```bash
dbt list --resource-type source
```

## Selection Syntax

### Graph Operators

**Downstream (+)**:
```bash
# Model + all downstream
dbt run --select my_model+

# Model + 2 levels downstream
dbt run --select my_model+2
```

**Upstream (+)**:
```bash
# All upstream + model
dbt run --select +my_model

# 2 levels upstream + model
dbt run --select 2+my_model
```

**Both (@)**:
```bash
# All upstream, model, all downstream
dbt run --select @my_model
```

### Intersections

**AND (,)**:
```bash
# Finance AND staging layer
dbt run --select tag:finance,tag:staging
```

**UNION (space)**:
```bash
# Finance OR staging layer
dbt run --select tag:finance tag:staging
```

**EXCLUDE (--exclude)**:
```bash
# All finance models except staging
dbt run --select tag:finance --exclude tag:staging
```

### Resource Types

```bash
# Select by resource type
dbt list --resource-type model
dbt list --resource-type test
dbt list --resource-type source
dbt list --resource-type exposure
```

### State-based Selection (Slim CI)

```bash
# Modified models + downstream
dbt build --select state:modified+ --defer --state ./prod-manifest/

# New models only
dbt build --select state:new --defer --state ./prod-manifest/

# Modified or new
dbt build --select state:modified+ state:new --defer --state ./prod-manifest/
```

## Target Environments

### Using targets
```bash
# Run against dev
dbt run --target dev

# Run against prod
dbt run --target prod

# Check current target
dbt debug
```

### profiles.yml structure
```yaml
my_project:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: my_account
      database: DEV_DB
      warehouse: DEV_WH
      schema: dbt_{{ env_var('USER') }}

    prod:
      type: snowflake
      account: my_account
      database: PROD_DB
      warehouse: PROD_WH
      schema: analytics
```

## Advanced Patterns

### Parallel Execution
```bash
# Run with 8 threads (faster)
dbt run --threads 8
```

### Partial Parsing
```bash
# Disable partial parsing (troubleshooting)
dbt run --no-partial-parse
```

### Fail Fast
```bash
# Stop on first failure
dbt test --fail-fast
```

### Full Refresh
```bash
# Force full refresh of incremental models
dbt run --full-refresh

# Full refresh specific model
dbt run --select my_model --full-refresh
```

### Seed Data
```bash
# Load CSV files from seeds/ directory
dbt seed

# Load specific seed
dbt seed --select my_seed
```

### Snapshot
```bash
# Run snapshots (SCD Type 2)
dbt snapshot

# Snapshot specific table
dbt snapshot --select my_snapshot
```

## Debugging Commands

### debug
Validate connection and configuration:
```bash
dbt debug

# Test specific profile
dbt debug --profiles-dir ./custom-profiles/
```

### list
List resources:
```bash
# List all models
dbt list

# List models matching selection
dbt list --select tag:finance

# Output as JSON
dbt list --output json

# Show resource paths
dbt list --output path
```

### show
Preview query results (without materializing):
```bash
# Show first 5 rows
dbt show --select my_model

# Show first 10 rows
dbt show --select my_model --limit 10
```

### run-operation
Execute macros:
```bash
# Run macro
dbt run-operation my_macro

# Run macro with arguments
dbt run-operation grant_select --args '{role: analyst}'
```

## Package Management

```bash
# Install packages from packages.yml
dbt deps

# Clean installed packages
dbt clean
```

## Global Flags

```bash
# Verbose logging
dbt run --debug

# Quiet mode (minimal output)
dbt run --quiet

# Log to file
dbt run --log-path ./custom-logs/

# Custom profiles directory
dbt run --profiles-dir ./profiles/

# Custom project directory
dbt run --project-dir ./my-dbt-project/

# Print JSON logs
dbt run --log-format json
```

## CI/CD Patterns

### Slim CI (GitHub Actions)
```bash
# 1. Download production manifest
# 2. Run only changed models
dbt build \
  --select state:modified+ \
  --defer \
  --state ./prod-manifest/ \
  --target build
```

### Production Run
```bash
# Full build with tests
dbt build --target prod

# Run only, skip tests
dbt run --target prod
```

### Selective Build by Domain
```bash
# Finance domain
dbt build --select tag:domain:finance

# Critical models only
dbt build --select tag:critical:true
```

## Common Combinations

### Full Model Lifecycle
```bash
# Compile → Run → Test → Generate Docs
dbt compile && \
dbt run && \
dbt test && \
dbt docs generate
```

### Modified Models with Tests
```bash
# CI/CD pattern
dbt build --select state:modified+ --defer --state prod/
```

### Tag-based Production Build
```bash
# Build finance domain
dbt build --select tag:group:finance --target prod
```

### Development Workflow
```bash
# Compile specific model
dbt compile --select my_model

# Run with tests
dbt build --select my_model

# View docs
dbt docs generate && dbt docs serve
```

## Environment Variables

```bash
# Use env vars in profiles.yml
export DBT_USER=my_username
export DBT_PASSWORD=my_password

# Reference in profiles.yml
user: "{{ env_var('DBT_USER') }}"
password: "{{ env_var('DBT_PASSWORD') }}"
```

## Tips

- **Use `dbt build` instead of `dbt run && dbt test`** - Runs in dependency order
- **Use state-based selection for CI** - Only build/test changed models
- **Tag models appropriately** - Enables selective builds
- **Use `--fail-fast` in CI** - Fail immediately on first error
- **Increase threads for large projects** - `--threads 8` for faster builds
- **Use `dbt show` for quick previews** - No materialization needed
