---
title: DataDog Log Cost Optimization Strategies
category: Cost Optimization
last_updated: 2025-10-09
tags: [logs, cost-optimization, indexing, sampling]
---

# DataDog Log Cost Optimization Strategies

Comprehensive guide to optimizing DataDog log costs without sacrificing critical visibility. Logs are often the largest component of DataDog spend.

## Understanding Log Costs

### DataDog Log Pricing Model

- **Ingestion**: Cost per GB of logs sent to DataDog
- **Indexing**: Cost per GB of logs indexed (searchable)
- **Retention**: Cost varies by retention period (3, 7, 15, 30, 90 days)
- **Archives**: Separate cost for long-term archive storage

### Typical Cost Breakdown

For most organizations:

- 60-70%: Log indexing costs
- 20-30%: APM and infrastructure metrics
- 10-15%: Synthetic monitoring and other features

**Key Insight**: You can ingest ALL logs but index only what you need. This is the primary cost optimization lever.

## Cost Optimization Framework

### 1. Ingest vs Index Strategy

**Ingest Everything** (relatively cheap):

- All logs sent to DataDog
- Available for live tail and debugging
- Can be archived for compliance
- Not searchable unless indexed

**Index Selectively** (expensive):

- Only critical logs are searchable
- Retained for configured period
- Enable alerts and analytics
- This is where costs escalate

### 2. Log Pipeline Architecture

```text
Application Logs
    |
    v
Ingestion (low cost)
    |
    v
Exclusion Filters (remove noise)
    |
    v
Indexing (high cost) + Archives (medium cost)
    |                       |
    v                       v
Search & Alert        Compliance Storage
```

## Exclusion Filter Strategies

### Priority 1: Exclude Health Checks and Heartbeats

Health check logs provide no value in DataDog:

```text
# Exclude AWS ALB health checks
source:alb AND @http.status_code:200 AND @http.url_details.path:/health

# Exclude Lambda warmup invocations
source:lambda AND @aws.lambda.cold_start:false AND @duration:<100

# Exclude successful API health checks
service:api AND @http.url_details.path:"/health" AND @http.status_code:200
```

**Impact**: Can reduce log volume by 30-50% for services behind load balancers.

### Priority 2: Exclude Debug and Verbose Logs in Production

Debug logs are useful in development but create noise in production:

```text
# Exclude debug logs from production
env:production AND status:debug

# Exclude verbose Lambda logs
service:lambda AND @message:"Lambda execution environment*"

# Exclude CloudWatch subscription filter logs
@message:"[CloudWatch Subscription Filter]"
```

**Impact**: 10-20% reduction for services with verbose logging.

### Priority 3: Exclude Successful Operations (Conditional)

For high-volume services, exclude successful operations and only index failures:

```text
# Index only errors and warnings
-(status:info OR status:ok)

# For specific high-volume services, exclude successful responses
service:high-volume-api AND -(@http.status_code:[200 TO 299])

# Exclude successful database queries
service:database AND -(@db.response_time:<100 AND @db.error:false)
```

**Impact**: 40-60% reduction for high-volume services.

**Warning**: Use carefully. You lose ability to calculate success rates and investigate historical successful requests.

### Priority 4: Sample High-Volume Logs

For extremely high-volume logs, keep a representative sample:

```text
# Keep 10% of successful API requests
service:api AND @http.status_code:[200 TO 299] AND sample:10

# Keep 1% of routine Lambda executions
service:lambda AND status:info AND sample:1
```

**Impact**: 50-90% reduction for specific high-volume sources.

## Indexing Strategy

### Multi-Index Approach

Create multiple indexes with different retention policies:

#### Index: critical-logs (30-day retention)

- Errors and warnings from production
- Security events
- Authentication failures
- Payment processing logs
- Data quality issues

#### Index: standard-logs (7-day retention)

- Info-level production logs
- Successful API requests (sampled)
- Application events
- Non-critical warnings

#### Index: short-term-logs (3-day retention)

- Development and staging logs
- Verbose debug logs
- High-volume operational logs

**Cost Savings**: 7-day retention is ~40% cheaper than 30-day. 3-day is ~60% cheaper.

### Index Configuration Example

In DataDog UI: Logs > Configuration > Indexes

```text
Index: critical-logs
  Filter: (status:error OR status:critical) AND env:production
  Retention: 30 days
  Daily Volume: 50 GB
  Monthly Cost: $X

Index: standard-logs
  Filter: status:info AND env:production
  Retention: 7 days
  Daily Volume: 200 GB
  Monthly Cost: $Y (< $X despite higher volume)

Index: dev-logs
  Filter: env:(dev OR staging)
  Retention: 3 days
  Daily Volume: 100 GB
  Monthly Cost: $Z (lowest)
```

## Application-Level Optimization

### Structured Logging

Efficient structured logs vs wasteful unstructured logs:

**Bad (wasteful)**:

```python
logger.info(f"User {user_id} performed action {action} on resource {resource_id} at {timestamp} with result {result}")
```

- Long message strings
- Difficult to parse
- Hard to exclude or sample

**Good (efficient)**:

```python
logger.info("User action completed", extra={
    'user_id': user_id,
    'action': action,
    'resource_id': resource_id,
    'result': result
})
```

- Shorter message
- Easy to filter and aggregate
- Can exclude by attribute

### Log Level Discipline

Set appropriate log levels by environment:

```typescript
const logLevel = process.env.ENV === 'production' ? 'INFO' : 'DEBUG';

// Only send INFO and above to DataDog in production
logger.setLevel(logLevel);
```

### Conditional Logging

Don't log information you can derive from metrics:

**Bad**:

```python
# This creates a log entry for every API call
logger.info(f"API call to {endpoint} returned {status_code}")
```

**Good**:

```python
# Send a metric instead
statsd.increment('api.requests', tags=[f'endpoint:{endpoint}', f'status:{status_code}'])

# Only log errors
if status_code >= 400:
    logger.error(f"API error for {endpoint}", extra={'status': status_code})
```

## Lambda-Specific Optimization

### Extension vs Forwarder

**DataDog Lambda Extension** (recommended):

- Sends logs directly to DataDog
- Lower latency, less volume (no CloudWatch duplication)
- Lower costs

**Forwarder Pattern** (legacy):

- Logs go to CloudWatch, then Forwarder Lambda
- Higher volume (stored in CloudWatch + DataDog)
- Higher costs

**Migrate to Extension**: Can reduce Lambda logging costs by 30-40%.

### Log Sampling in Lambda

For high-invocation functions:

```python
import random

def handler(event, context):
    # Sample 10% of invocations for logging
    if random.random() < 0.1:
        logger.info("Sampled invocation", extra={'event': event})
    else:
        # Only log errors
        try:
            result = process(event)
        except Exception as e:
            logger.error("Error processing event", exc_info=True)
```

### Exclude Lambda Platform Logs

Lambda generates platform logs that are often not useful:

```text
# Exclude Lambda START/END/REPORT lines
@message:"START RequestId:*" OR @message:"END RequestId:*" OR @message:"REPORT RequestId:*"
```

## Archive Strategy

### Configure Archives

For compliance, archive ingested logs to S3 (much cheaper than DataDog indexing):

**DataDog Archive to S3**:

- Ingest all logs to DataDog (low cost)
- Exclude most from indexing (high cost)
- Archive everything to S3 (medium cost)
- Re-ingest from S3 if needed for investigations

**Cost Comparison**:

- DataDog 30-day index: $1.27/GB/month
- DataDog 7-day index: ~$0.50/GB/month
- S3 archive: ~$0.02/GB/month (98% cheaper!)

### Archive Configuration

In DataDog UI: Logs > Configuration > Archives

```yaml
Archive Name: production-logs-archive
S3 Bucket: s3://datadog-logs-archive/production/
Filter: env:production
Retention: 1 year (S3 lifecycle policy)
Rehydration: Available on-demand for investigations
```

## Monitoring Your Log Costs

### Daily Cost Dashboard

Create a dashboard to track log costs:

**Metrics to Track**:

- Daily log ingestion volume (GB)
- Daily log indexing volume (GB) by index
- Logs indexed vs logs excluded (ratio)
- Top log sources by volume
- Cost per service/team (using tags)

### Cost Alerts

Set up alerts for unexpected log volume:

```text
Alert: High log volume
Metric: logs.estimated.usage
Condition: Above 1.5x rolling average (7 days)
Notification: Platform team + FinOps
```

### Cardinality Analysis

Identify logs with high unique message counts (expensive to index):

```text
# In DataDog Logs Explorer
Group by: @service, @message
Aggregation: Unique count
Sort: Descending
```

Services with high unique message counts are candidates for:

- Better structured logging
- Message parameterization
- Sampling or exclusion

## Cost Optimization Checklist

### Immediate Actions (Quick Wins)

- [ ] Exclude health check logs
- [ ] Exclude debug logs from production
- [ ] Exclude Lambda START/END/REPORT logs
- [ ] Set production log level to INFO or higher
- [ ] Migrate Lambda functions to DataDog Extension (from Forwarder)

### Short-Term (1-2 Weeks)

- [ ] Implement multi-index strategy (critical, standard, short-term)
- [ ] Configure S3 archives for compliance
- [ ] Create log cost monitoring dashboard
- [ ] Set up cost anomaly alerts
- [ ] Review top 10 log sources and optimize each

### Long-Term (1-3 Months)

- [ ] Implement structured logging standards
- [ ] Sample high-volume successful operations
- [ ] Replace log-based metrics with actual metrics
- [ ] Train teams on cost-effective logging
- [ ] Quarterly log cost review and optimization

## ROI Calculation

### Example Scenario

**Before Optimization**:

- 500 GB/day indexed at $1.27/GB = $19,050/month
- No exclusion filters
- All logs 30-day retention

**After Optimization**:

- 500 GB/day ingested
- 100 GB/day indexed (critical, 30-day) = $3,810/month
- 200 GB/day indexed (standard, 7-day) = $3,000/month
- 200 GB/day excluded
- 500 GB/day archived to S3 = $300/month
- **Total: $7,110/month (63% savings)**

## Common Mistakes

### Over-Optimization

Excluding too much can blind you during incidents. Always retain:

- All ERROR and CRITICAL logs
- Authentication and authorization events
- Security events
- Data quality issues
- Payment processing logs

### Under-Tagging

Without proper tags (`service`, `env`, `team`), you can't:

- Allocate costs by team
- Create service-specific exclusion filters
- Identify high-cost sources

### Ignoring Archives

Teams often pay for 30-day indexing when they could:

- Index for 7 days (recent investigations)
- Archive for 1 year (compliance)
- Re-ingest on-demand (rare deep investigations)

## Resources

- [DataDog Log Management Pricing](https://www.datadoghq.com/pricing/?product=log-management)
- [DataDog Exclusion Filters Documentation](https://docs.datadoghq.com/logs/log_configuration/indexes/#exclusion-filters)
- [DataDog Archives Documentation](https://docs.datadoghq.com/logs/log_configuration/archives/)

---

**Last Updated**: 2025-10-09
**Category**: Cost Optimization
**Related**: metric-cardinality-management.md, apm-sampling-strategies.md
