---
title: DataDog Tagging Strategy Best Practices
category: Core Concepts
last_updated: 2025-10-09
tags: [tagging, organization, best-practices]
---

# DataDog Tagging Strategy Best Practices

A consistent tagging strategy is foundational to effective observability in DataDog. Tags enable filtering, aggregation, alerting, and cost allocation across your entire infrastructure.

## Why Tagging Matters

### Benefits of Good Tagging
- **Filtering and Search**: Quickly find resources by environment, service, team
- **Aggregation**: Group metrics, logs, and traces by meaningful dimensions
- **Alerting**: Target alerts to specific services, environments, or teams
- **Cost Allocation**: Track DataDog and AWS costs by team or project
- **Troubleshooting**: Correlate issues across related resources
- **Compliance**: Demonstrate security controls by environment or data classification

### Cost of Poor Tagging
- Difficulty filtering and finding resources
- Alerts that fire for wrong environments
- Inability to allocate costs accurately
- Manual effort to correlate related resources
- Reduced team autonomy (can't self-service dashboards)

## Required Tags

Every resource MUST have these tags:

### env (Environment)
- **Values**: `dev`, `staging`, `production`
- **Purpose**: Separate pre-production from production data
- **Example**: `env:production`

### service (Service Name)
- **Values**: Lowercase, kebab-case service names
- **Purpose**: Group related resources by application or service
- **Example**: `service:survivor-atlas`, `service:snowflake-exporter`

### team (Owning Team)
- **Values**: Team names matching organizational structure
- **Purpose**: Route alerts, allocate costs, assign ownership
- **Example**: `team:data-platform`, `team:analytics`

## Recommended Tags

These tags provide additional value and should be used where applicable:

### version (Application Version)
- **Values**: Semantic version or git commit SHA
- **Purpose**: Correlate deployments with performance changes
- **Example**: `version:1.2.3`, `version:a1b2c3d`

### cost-center (Cost Allocation)
- **Values**: Department or project code
- **Purpose**: Charge back AWS and DataDog costs
- **Example**: `cost-center:engineering`, `cost-center:product`

### owner (Technical Owner)
- **Values**: Email or username of primary owner
- **Purpose**: Contact for technical issues
- **Example**: `owner:platform-team@company.com`

### component (Architectural Component)
- **Values**: Specific component within a service
- **Purpose**: Granular filtering within complex services
- **Example**: `component:api`, `component:worker`, `component:database`

### region (AWS Region)
- **Values**: AWS region code
- **Purpose**: Track multi-region deployments
- **Example**: `region:us-east-1`

### data-classification (Data Sensitivity)
- **Values**: `public`, `internal`, `confidential`, `restricted`
- **Purpose**: Security and compliance tracking
- **Example**: `data-classification:confidential`

## Tag Naming Conventions

### Keys
- Use lowercase with hyphens: `cost-center` (not `costCenter` or `cost_center`)
- Be descriptive but concise: `data-classification` (not `data-class` or `classification-level`)
- Avoid abbreviations unless universally understood

### Values
- Use lowercase with hyphens: `survivor-atlas` (not `SurvivorAtlas` or `survivor_atlas`)
- Be consistent: `production` everywhere (not `prod` in some places, `production` in others)
- Avoid special characters (except hyphens)
- Keep values short (under 30 characters if possible)

## CDK Tag Propagation

### Stack-Level Tags
Apply tags to entire stacks:

```typescript
import { Tags } from 'aws-cdk-lib';

export class MyStack extends Stack {
  constructor(scope: Construct, id: string, props: StackProps) {
    super(scope, id, props);

    // Apply to all resources in this stack
    Tags.of(this).add('env', 'production');
    Tags.of(this).add('service', 'survivor-atlas');
    Tags.of(this).add('team', 'data-platform');
    Tags.of(this).add('cost-center', 'engineering');
  }
}
```

### Resource-Level Tags
Override or add tags to specific resources:

```typescript
const myFunction = new lambda.Function(this, 'MyFunction', {
  // ... function config
});

Tags.of(myFunction).add('component', 'api');
Tags.of(myFunction).add('version', '1.2.3');
```

### DataDog Unified Service Tagging
For APM and distributed tracing, use these environment variables:

```typescript
const myFunction = new lambda.Function(this, 'MyFunction', {
  environment: {
    DD_ENV: 'production',           // Maps to env tag
    DD_SERVICE: 'survivor-atlas',   // Maps to service tag
    DD_VERSION: '1.2.3',            // Maps to version tag
    DD_TAGS: 'team:data-platform,cost-center:engineering'
  }
});
```

## Tag Cardinality Considerations

### High-Cardinality Tags (Avoid)
Tags with many unique values increase costs and reduce performance:
- User IDs: `user:12345` (thousands of unique values)
- Request IDs: `request:a1b2c3d4` (infinite unique values)
- Timestamps: `timestamp:2025-10-09T12:00:00Z` (infinite unique values)

### Bounded-Cardinality Tags (Safe)
Tags with limited, known values are safe:
- Environment: `env:production` (3 values)
- Service: `service:survivor-atlas` (dozens of values)
- Region: `region:us-east-1` (20-30 values)
- Team: `team:data-platform` (5-10 values)

### Impact of High Cardinality
- Increased DataDog metric costs (charged per unique metric timeseries)
- Slower queries and dashboard load times
- Difficulty finding relevant data in UI
- Higher storage and indexing costs

## Tag Validation

### Pre-Deployment Checks
Validate tags before deploying:

```typescript
// Custom CDK aspect to enforce required tags
import { IAspect, IConstruct } from 'aws-cdk-lib';

export class RequiredTagsAspect implements IAspect {
  private requiredTags = ['env', 'service', 'team'];

  visit(node: IConstruct): void {
    if (node instanceof CfnResource) {
      const tags = node.tags?.renderTags() || {};
      const missingTags = this.requiredTags.filter(tag => !tags[tag]);

      if (missingTags.length > 0) {
        throw new Error(
          `Resource ${node.node.path} is missing required tags: ${missingTags.join(', ')}`
        );
      }
    }
  }
}

// Apply to stack
Aspects.of(stack).add(new RequiredTagsAspect());
```

### DataDog Tag Validation
Use DataDog API to find untagged resources:

```bash
# Find metrics without required tags
curl -X GET "https://api.datadoghq.com/api/v1/metrics" \
  -H "DD-API-KEY: ${DD_API_KEY}" \
  -H "DD-APPLICATION-KEY: ${DD_APP_KEY}" \
  | jq '.metrics[] | select(.tags | index("env:") == null)'
```

## Tag Organization Patterns

### By Environment
```
env:dev
env:staging
env:production
```

### By Service Architecture
```
service:api-gateway
service:lambda-processor
service:rds-database

component:auth
component:api
component:worker
component:cache
```

### By Team and Ownership
```
team:data-platform
team:analytics
team:infrastructure

owner:platform-team@company.com
cost-center:engineering
```

### By Lifecycle
```
lifecycle:permanent
lifecycle:temporary
lifecycle:ephemeral

managed-by:cdk
deployed-by:github-actions
```

## Common Mistakes

### Inconsistent Casing
```
# Bad - inconsistent casing
env:Production
env:production
env:PRODUCTION

# Good - consistent lowercase
env:production
```

### Abbreviations
```
# Bad - unclear abbreviations
env:prd
env:prod
env:production

# Good - consistent full names
env:production
```

### High Cardinality in Metric Tags
```
# Bad - creates infinite metric timeseries
user_id:12345
request_id:a1b2c3d4

# Good - use as log attributes, not metric tags
env:production
service:api
```

### Missing Required Tags
```
# Bad - can't filter by environment
service:survivor-atlas
team:data-platform

# Good - all required tags present
env:production
service:survivor-atlas
team:data-platform
```

## Tag Governance

### Establish Standards
- Document required and recommended tags in central location
- Create validation rules in CDK aspects or CI/CD pipelines
- Provide tagging templates and examples
- Train teams on tagging strategy

### Monitor Compliance
- Regular audits of untagged or incorrectly tagged resources
- DataDog dashboard showing tag compliance by team/service
- Automated alerts for resources missing required tags
- Cost allocation reports to validate tag accuracy

### Continuous Improvement
- Review tag effectiveness quarterly
- Deprecate unused tags
- Add new tags as organizational needs evolve
- Gather feedback from teams using tags

## Resources

- [DataDog Unified Service Tagging](https://docs.datadoghq.com/getting_started/tagging/unified_service_tagging/)
- [AWS Tagging Best Practices](https://docs.aws.amazon.com/general/latest/gr/aws_tagging.html)
- [DataDog Tag Best Practices](https://docs.datadoghq.com/getting_started/tagging/)

---

**Last Updated**: 2025-10-09
**Category**: Core Concepts
**Related**: datadog-architecture.md, integration-patterns.md
