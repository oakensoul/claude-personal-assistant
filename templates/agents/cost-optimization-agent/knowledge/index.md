---
title: "Cost Optimization Agent Knowledge Base"
description: "Comprehensive Snowflake cost management, warehouse optimization, and resource efficiency knowledge"
agent: "cost-optimization-agent"
version: "1.0.0"
knowledge_count: 14
last_updated: "2025-10-07"
categories:
  - cost-analysis
  - warehouse-optimization
  - storage-management
  - query-performance
  - budget-monitoring
tags:
  - snowflake
  - cost-optimization
  - warehouse-sizing
  - resource-monitors
  - materialization-strategy
---

# Cost Optimization Agent Knowledge Base

This knowledge base provides comprehensive guidance for Snowflake cost management, warehouse optimization, query performance tuning, and resource efficiency.

## Knowledge Organization

### Core Concepts (4 files)

Foundational knowledge about Snowflake cost models and optimization principles:

- **snowflake-cost-model.md** - Compute vs storage pricing, credit consumption, cost drivers
- **warehouse-optimization.md** - Sizing strategies, auto-suspend, multi-cluster warehouses
- **cost-attribution-frameworks.md** - Tagging, chargeback models, team/project allocation
- **cost-forecasting.md** - Trend analysis, predictive models, budget planning

### Patterns (4 files)

Reusable patterns and SQL templates for cost management:

- **expensive-query-detection.md** - Monitoring, alerting, optimization workflows
- **storage-optimization-patterns.md** - Clustering, retention, archival strategies
- **materialization-cost-analysis.md** - Incremental vs full refresh ROI, view vs table
- **cost-allocation-tagging.md** - Resource tagging, cost attribution, chargeback

### Decisions (3 files)

Documented standards and decision frameworks:

- **warehouse-sizing-standards.md** - Default sizes by workload, scaling triggers
- **retention-policy-costs.md** - Time-travel vs storage cost tradeoffs
- **materialization-thresholds.md** - When to materialize vs compute on-demand

### Reference (3 files)

Quick reference materials and checklists:

- **snowflake-cost-queries.md** - ACCOUNT_USAGE query library, cost analysis SQL
- **cost-optimization-checklist.md** - Monthly review tasks, optimization opportunities
- **warehouse-sizing-calculator.md** - Formulas, sizing decision trees

## Quick Reference

### Common Cost Analysis Queries

**Daily Credit Consumption**:

```sql
SELECT
    DATE_TRUNC('day', start_time) AS usage_date,
    warehouse_name,
    SUM(credits_used) AS total_credits
FROM snowflake.account_usage.warehouse_metering_history
WHERE start_time >= DATEADD('day', -30, CURRENT_TIMESTAMP())
GROUP BY 1, 2
ORDER BY 1 DESC, 3 DESC;
```

**Most Expensive Queries**:

```sql
SELECT
    query_id,
    LEFT(query_text, 100) AS query_preview,
    execution_time / 1000 AS execution_seconds,
    warehouse_name
FROM snowflake.account_usage.query_history
WHERE start_time >= DATEADD('day', -7, CURRENT_TIMESTAMP())
ORDER BY execution_time DESC
LIMIT 50;
```

**Storage Breakdown**:

```sql
SELECT
    table_catalog,
    SUM(active_bytes) / POWER(1024, 3) AS active_gb,
    SUM(time_travel_bytes) / POWER(1024, 3) AS time_travel_gb,
    SUM(failsafe_bytes) / POWER(1024, 3) AS failsafe_gb
FROM snowflake.account_usage.table_storage_metrics
GROUP BY 1
ORDER BY SUM(active_bytes + time_travel_bytes + failsafe_bytes) DESC;
```

### Warehouse Sizing Quick Guide

| Size | Credits/Hour | Use Case | Typical Workload |
|------|--------------|----------|------------------|
| X-Small | 1 | Development, testing | < 1K rows/sec |
| Small | 2 | Standard dev, small marts | 1K-10K rows/sec |
| Medium | 4 | Production analytics, ETL | 10K-50K rows/sec |
| Large | 8 | Heavy ETL, complex transforms | 50K-200K rows/sec |
| X-Large | 16 | High-volume processing | > 200K rows/sec |

### Auto-Suspend Recommendations

| Warehouse Type | Auto-Suspend | Rationale |
|----------------|--------------|-----------|
| Interactive (BI) | 300-600 sec | User sessions with pauses |
| ETL (dbt) | 60 sec | Minimal idle between runs |
| Ad-hoc Analysis | 120-300 sec | Balance startup vs idle |
| Development | 60 sec | Frequent start/stop |

### Cost Optimization Checklist

**Weekly**:

- [ ] Review top 10 most expensive queries
- [ ] Check warehouse idle time percentages
- [ ] Validate auto-suspend configurations

**Monthly**:

- [ ] Analyze monthly credit consumption vs budget
- [ ] Review table storage costs (top 50 tables)
- [ ] Evaluate materialization strategy ROI
- [ ] Update cost forecasts for next quarter

**Quarterly**:

- [ ] Comprehensive warehouse sizing review
- [ ] Storage retention policy optimization
- [ ] Cost attribution accuracy validation
- [ ] Executive cost dashboard review

## Integration with Project

### dbt Cost Optimization

**Tagging for Cost Attribution**:

```yaml
# models/dwh/core/finance/fct_wallet_transactions.sql
{{
    config(
        tags=['group:finance', 'critical:true', 'volume:high'],
        # Cost implications:
        # - critical:true → runs every 15 min → high compute cost
        # - volume:high → large data scans → requires larger warehouse
    )
}}
```

**Materialization Strategy**:

```yaml
# High-frequency, high-volume → Incremental (reduce recomputation)
{{ config(materialized='incremental', unique_key='transaction_key') }}

# Low-frequency, simple logic → View (avoid storage cost)
{{ config(materialized='view') }}

# High-query-frequency aggregates → Table (avoid redundant computation)
{{ config(materialized='table') }}
```

### Warehouse Assignments

**Recommended Warehouse Mapping**:

- `DBT_DEV_WH` (Small): Development builds, exclude high-volume models
- `DBT_PROD_WH` (Medium): Production critical models (tag:critical:true)
- `DBT_PROD_HEAVY_WH` (Large): High-volume segment data (tag:volume:high)
- `DBT_MARTS_WH` (Small): Business marts, aggregates (tag:layer:marts)

### Cost Monitoring Integration

**Resource Monitor Example**:

```sql
CREATE RESOURCE MONITOR dbt_prod_monitor
WITH CREDIT_QUOTA = 5000
    FREQUENCY = MONTHLY
    START_TIMESTAMP = IMMEDIATELY
    TRIGGERS
        ON 75 PERCENT DO NOTIFY
        ON 90 PERCENT DO SUSPEND;

ALTER WAREHOUSE DBT_PROD_WH SET RESOURCE_MONITOR = dbt_prod_monitor;
```

## External Resources

### Snowflake Documentation

- [Snowflake Pricing](https://www.snowflake.com/pricing/)
- [Understanding Compute Cost](https://docs.snowflake.com/en/user-guide/cost-understanding-compute)
- [Resource Monitors](https://docs.snowflake.com/en/user-guide/resource-monitors)
- [Warehouse Considerations](https://docs.snowflake.com/en/user-guide/warehouses-considerations)

### Cost Optimization Guides

- [Cost Management Best Practices](https://www.snowflake.com/blog/cost-management-best-practices/)
- [Query Performance Optimization](https://docs.snowflake.com/en/user-guide/query-performance)
- [Storage Cost Optimization](https://docs.snowflake.com/en/user-guide/tables-storage-considerations)

### Analytics & Monitoring

- [ACCOUNT_USAGE Views Reference](https://docs.snowflake.com/en/sql-reference/account-usage)
- [Query Profile Analysis](https://docs.snowflake.com/en/user-guide/ui-query-profile)

## Usage Guidelines

### When to Reference This Knowledge Base

1. **Cost Analysis**: Need SQL templates for cost queries → Reference **reference/snowflake-cost-queries.md**
2. **Warehouse Sizing**: Unsure what warehouse size to use → Reference **decisions/warehouse-sizing-standards.md**
3. **Storage Optimization**: High storage costs → Reference **patterns/storage-optimization-patterns.md**
4. **Materialization Decision**: Table vs view tradeoff → Reference **patterns/materialization-cost-analysis.md**
5. **Budget Setup**: Creating resource monitors → Reference **core-concepts/cost-forecasting.md**
6. **Query Optimization**: Expensive queries → Reference **patterns/expensive-query-detection.md**

### Knowledge Base Maintenance

**Update Triggers**:

- Snowflake pricing changes → Update **core-concepts/snowflake-cost-model.md**
- New cost optimization discovered → Document in **patterns/**
- Warehouse sizing adjustments → Update **decisions/warehouse-sizing-standards.md**
- Monthly cost reviews → Add learnings to **decisions/**

**Quality Standards**:

- All SQL examples must be tested against ACCOUNT_USAGE schema
- Cost calculations should include pricing assumptions ($/credit)
- Patterns should include ROI analysis where applicable
- Reference Snowflake documentation for authoritative guidance

---

**Last Updated**: 2025-10-07
**Knowledge Files**: 14
**Agent**: cost-optimization-agent v1.0.0
