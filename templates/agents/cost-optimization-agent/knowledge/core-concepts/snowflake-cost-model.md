---
title: "Snowflake Cost Model"
description: "Comprehensive guide to Snowflake pricing structure, credit consumption, and cost drivers"
category: "core-concepts"
tags: ["pricing", "credits", "compute", "storage", "cost-model"]
version: "1.0.0"
last_updated: "2025-10-07"
---

# Snowflake Cost Model

Understanding Snowflake's cost structure is essential for effective cost optimization. Snowflake uses a credit-based pricing model with separate charges for compute and storage.

## Cost Components

### 1. Compute Costs (Credits)

**What is a Snowflake Credit?**
- Virtual currency representing compute resources
- Pricing varies by region and cloud provider (~$2-4/credit typical)
- Credits consumed based on:
  - Warehouse size (credits per hour)
  - Warehouse run time
  - Serverless features (auto-clustering, materialized views, search optimization)

**Warehouse Credit Consumption**:

| Warehouse Size | Credits/Hour | Relative Cost | Compute Power |
|----------------|--------------|---------------|---------------|
| X-Small | 1 | 1x | 1 server |
| Small | 2 | 2x | 2 servers |
| Medium | 4 | 4x | 4 servers |
| Large | 8 | 8x | 8 servers |
| X-Large | 16 | 16x | 16 servers |
| 2X-Large | 32 | 32x | 32 servers |
| 3X-Large | 64 | 64x | 64 servers |
| 4X-Large | 128 | 128x | 128 servers |

**Credit Consumption Formula**:
```
Total Credits = (Credits/Hour for Warehouse Size) × (Runtime in Hours)
```

**Example**:
- Medium warehouse (4 credits/hour)
- Running for 30 minutes (0.5 hours)
- Cost: 4 × 0.5 = **2 credits**

**Minimum Billing**:
- Warehouses billed in 1-minute increments (after initial 1-minute minimum)
- Example: 10-second query = 1 minute of billing
- Example: 90-second query = 2 minutes of billing

### 2. Storage Costs

**Storage Pricing**:
- **On-Demand**: ~$40/TB/month (varies by region/cloud)
- **Capacity**: Pre-purchased storage at discounted rate
- **Billed Monthly**: Average daily storage consumption

**Storage Types**:

1. **Active Storage** (Standard Rate)
   - Current table data
   - Staged files (internal/external stages)
   - Micro-partitions containing data

2. **Time Travel Storage** (Standard Rate)
   - Historical data within retention period
   - 0-90 days (0-1 for Standard Edition, 0-90 for Enterprise)
   - Enables query-able historical snapshots

3. **Fail-Safe Storage** (Higher Rate)
   - 7-day disaster recovery period after time travel
   - Non-query-able, Snowflake-managed recovery
   - Begins after time travel period expires

**Storage Cost Formula**:
```
Monthly Storage Cost = (Average Daily Storage TB) × (Storage Rate $/TB/month)

Total Storage GB = Active Storage + Time Travel + Fail-Safe
```

**Example**:
- Database: 500 GB active data
- Time Travel (1 day): 50 GB changed daily = 50 GB
- Fail-Safe (7 days): 50 GB × 7 = 350 GB
- **Total Storage**: 500 + 50 + 350 = **900 GB** billed

### 3. Data Transfer Costs

**Replication & Data Sharing**:
- Cross-region replication: Compute credits + transfer fees
- Data sharing (within same region/cloud): Free
- Data sharing (cross-region/cloud): Transfer fees apply

**External Data Transfer**:
- **Ingress (loading data)**: Free
- **Egress (unloading data)**: Charged per GB (varies by cloud/region)
- **Unload to cloud storage**: Typically $0.02-0.05/GB

### 4. Serverless Feature Costs

**Automatic Clustering**:
- Credits consumed for background clustering maintenance
- Based on table size, clustering keys, data change rate
- Billed per warehouse credit (same rate as virtual warehouses)

**Materialized Views**:
- Background refresh consumes credits
- Depends on base table changes and view complexity
- Query against materialized view may use additional credits

**Search Optimization Service**:
- Credits for building/maintaining search access paths
- Improves point lookup query performance
- Billed based on table size and update frequency

**Snowpipe (Continuous Data Loading)**:
- Credits per 1,000 files loaded
- Serverless compute for ingestion
- Typically more cost-effective than warehouse-based loading

**Query Acceleration Service**:
- Credits for offloading query portions to elastic compute
- Charged per GB scanned by acceleration service
- Can be more economical than constant warehouse upsize

## Cost Drivers & Optimization Levers

### Compute Cost Drivers

1. **Warehouse Size Selection**
   - **Driver**: Size determines credits/hour
   - **Optimization**: Right-size based on workload, not peak capacity

2. **Warehouse Runtime**
   - **Driver**: Total hours warehouses are active
   - **Optimization**: Auto-suspend, consolidate workloads, optimize queries

3. **Query Efficiency**
   - **Driver**: Poorly written queries run longer
   - **Optimization**: Query tuning, clustering keys, appropriate joins

4. **Concurrency**
   - **Driver**: Queued queries indicate undersized warehouse
   - **Optimization**: Multi-cluster warehouses, workload separation

5. **Serverless Features**
   - **Driver**: Automatic background processing
   - **Optimization**: Disable clustering if maintenance exceeds query savings

### Storage Cost Drivers

1. **Data Volume**
   - **Driver**: Total GB/TB stored
   - **Optimization**: Archive old data, drop unused tables, compression

2. **Time Travel Retention**
   - **Driver**: Retention period (0-90 days)
   - **Optimization**: Set retention based on actual recovery needs (0, 1, 7, 30 days)

3. **Fail-Safe Storage**
   - **Driver**: Automatic 7-day fail-safe after time travel
   - **Optimization**: Reduce time travel retention to minimize fail-safe period

4. **Table Design**
   - **Driver**: Inefficient data types, unnecessary columns
   - **Optimization**: Use appropriate data types (DATE vs TIMESTAMP), drop unused columns

5. **Staged Files**
   - **Driver**: Files left in internal stages
   - **Optimization**: Regular cleanup of staged files after loading

## Cost Formulas & Examples

### Example 1: Daily dbt Build Cost

**Scenario**:
- Medium warehouse (4 credits/hour)
- dbt build runs every 15 minutes (96 runs/day)
- Average run time: 3 minutes

**Calculation**:
```
Runtime per build = 3 minutes = 0.05 hours
Credits per build = 4 credits/hour × 0.05 hours = 0.2 credits
Daily credits = 0.2 credits × 96 builds = 19.2 credits
Monthly credits = 19.2 × 30 = 576 credits
Monthly cost (@ $2.50/credit) = $1,440
```

**Optimization Opportunity**:
- Reduce build frequency for non-critical models (tag:critical:false)
- If critical models only = 3 minutes every 15 min → 288 credits/month = **$720** (50% savings)

### Example 2: Storage Cost Analysis

**Scenario**:
- 2 TB active data
- 7-day time travel retention
- ~100 GB data changes daily

**Calculation**:
```
Active Storage = 2,000 GB
Time Travel (7 days) = 100 GB/day × 7 = 700 GB
Fail-Safe (7 days after time travel) = 100 GB/day × 7 = 700 GB
Total Storage = 2,000 + 700 + 700 = 3,400 GB = 3.4 TB

Monthly Cost (@ $40/TB) = 3.4 TB × $40 = $136
```

**Optimization Option**:
- Reduce time travel to 1 day (still Enterprise standard)
```
Time Travel (1 day) = 100 GB
Fail-Safe (7 days) = 700 GB  (unchanged)
Total Storage = 2,000 + 100 + 700 = 2,800 GB = 2.8 TB
Monthly Cost = 2.8 TB × $40 = $112 (savings: $24/month = 18%)
```

### Example 3: Warehouse Idle Time Cost

**Scenario**:
- Large warehouse (8 credits/hour)
- Used for 2 hours/day actual query execution
- Auto-suspend set to 10 minutes (600 seconds)
- Idle periods: 4 × 10 minutes = 40 minutes/day additional runtime

**Calculation**:
```
Actual query time = 2 hours/day = 2 × 8 = 16 credits
Idle time = 40 minutes/day = 0.67 hours/day = 0.67 × 8 = 5.36 credits
Total daily credits = 16 + 5.36 = 21.36 credits
Monthly credits = 21.36 × 30 = 640.8 credits
Monthly cost (@ $2.50/credit) = $1,602

Idle cost percentage = 5.36 / 21.36 = 25% wasted
```

**Optimization**:
- Reduce auto-suspend to 1 minute (60 seconds)
```
Idle time (optimized) = 4 minutes/day = 0.067 hours = 0.54 credits/day
Monthly idle credits = 0.54 × 30 = 16.2 credits (vs 160.8)
Monthly savings = (160.8 - 16.2) × $2.50 = $361
```

## Cost Monitoring Queries

### Current Month Credit Usage

```sql
SELECT
    warehouse_name,
    SUM(credits_used) AS total_credits,
    SUM(credits_used) * 2.5 AS estimated_cost_usd  -- Adjust rate
FROM snowflake.account_usage.warehouse_metering_history
WHERE start_time >= DATE_TRUNC('month', CURRENT_TIMESTAMP())
GROUP BY warehouse_name
ORDER BY total_credits DESC;
```

### Storage Cost Breakdown

```sql
SELECT
    DATE_TRUNC('month', usage_date) AS usage_month,
    AVG(storage_bytes + stage_bytes + failsafe_bytes) / POWER(1024, 4) AS avg_storage_tb,
    AVG(storage_bytes + stage_bytes + failsafe_bytes) / POWER(1024, 4) * 40 AS estimated_cost_usd
FROM snowflake.account_usage.storage_usage
WHERE usage_date >= DATEADD('month', -3, CURRENT_DATE())
GROUP BY 1
ORDER BY 1 DESC;
```

### Serverless Feature Costs

```sql
-- Automatic Clustering Credits
SELECT
    DATE_TRUNC('day', start_time) AS clustering_date,
    database_name,
    schema_name,
    table_name,
    SUM(credits_used) AS clustering_credits,
    SUM(credits_used) * 2.5 AS estimated_cost_usd
FROM snowflake.account_usage.automatic_clustering_history
WHERE start_time >= DATEADD('day', -30, CURRENT_TIMESTAMP())
GROUP BY 1, 2, 3, 4
ORDER BY clustering_credits DESC;
```

## Pricing Variations

### By Cloud Provider

**Approximate Credit Pricing** (Standard On-Demand, US regions):
- **AWS**: $2.00 - $3.00/credit (varies by region)
- **Azure**: $2.00 - $3.00/credit
- **GCP**: $2.00 - $3.00/credit

**Regional Variations**:
- US regions: Typically lower rates
- Europe: 10-20% higher
- Asia-Pacific: 15-25% higher

### By Edition

**Snowflake Editions** (features impact cost drivers):
1. **Standard**: Basic features, 0-1 day time travel
2. **Enterprise**: Advanced security, 0-90 day time travel, multi-cluster warehouses
3. **Business Critical**: Enhanced security, data protection (HIPAA, PCI)
4. **Virtual Private Snowflake**: Dedicated infrastructure, highest security

**Cost Implications**:
- Enterprise features (extended time travel) increase storage costs
- Business Critical has higher credit rates
- VPS has additional infrastructure costs

## Cost Optimization Principles

### 1. Compute Optimization
- **Right-size warehouses** based on actual workload, not perceived needs
- **Aggressive auto-suspend** (60-300 seconds typical)
- **Optimize queries** to reduce execution time
- **Separate workloads** by warehouse (ETL, BI, ad-hoc)

### 2. Storage Optimization
- **Set appropriate retention** (0, 1, 7, 30, 90 days based on actual needs)
- **Archive historical data** to separate low-access databases
- **Drop unused tables** immediately (fail-safe charges for 7 days after drop)
- **Clean staged files** regularly

### 3. Monitoring & Governance
- **Resource monitors** on all warehouses (credit quotas)
- **Regular cost reviews** (weekly/monthly)
- **Cost attribution** via tags (team/project chargeback)
- **Anomaly detection** (automated alerts for unusual spend)

### 4. Architectural Decisions
- **Materialization strategy** (incremental vs full, table vs view)
- **Clustering keys** (only when query savings exceed maintenance)
- **Serverless features** (evaluate ROI for each feature)

## References

- [Snowflake Pricing Documentation](https://www.snowflake.com/pricing/)
- [Understanding Compute Cost](https://docs.snowflake.com/en/user-guide/cost-understanding-compute)
- [Understanding Storage Cost](https://docs.snowflake.com/en/user-guide/cost-understanding-storage)
- [Warehouse Considerations](https://docs.snowflake.com/en/user-guide/warehouses-considerations)

---

**Key Takeaway**: Snowflake costs are driven by compute (warehouse runtime) and storage (data volume × retention). The credit-based model provides flexibility, but requires active monitoring and optimization to control spend. Understanding the cost model is the foundation for all optimization efforts.
