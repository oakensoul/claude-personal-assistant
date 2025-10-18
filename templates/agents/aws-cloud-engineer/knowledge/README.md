---
title: AWS Cloud Engineer Knowledge Base - Getting Started
description: Guide to setting up and using the aws-cloud-engineer agent
last_updated: 2025-10-09
---

# AWS Cloud Engineer Knowledge Base

## Overview

This knowledge base provides the `aws-cloud-engineer` agent with AWS and CDK expertise across all your projects.

## Two-Tier Architecture

### User-Level Knowledge (This Location)

**Location**: `~/.claude/agents/aws-cloud-engineer/knowledge/`

**Purpose**: Generic AWS knowledge that applies to all projects

**Contains**:
- AWS service documentation and selection guidance
- CDK patterns and best practices
- Well-Architected Framework principles
- Cost optimization strategies
- Security best practices

**Maintained**: Occasionally updated as you learn new AWS patterns

### Project-Level Knowledge

**Location**: `{project}/.claude/agents/aws-cloud-engineer/knowledge/`

**Purpose**: Project-specific AWS configuration and architecture

**Contains**:
- AWS account IDs, profiles, and regions
- VPC IDs, subnet IDs, security group IDs
- Stack architecture and dependencies
- Resource naming conventions
- Tagging strategies
- Cost budgets and thresholds

**Maintained**: Created for each CDK project, updated as infrastructure evolves

## Setting Up Project-Specific Knowledge

When working on a CDK project, create project-specific knowledge to enable context-aware recommendations.

### Step 1: Create Directory Structure

```bash
# From your CDK project root
cd /path/to/your/cdk/project

# Create knowledge directories
mkdir -p .claude/agents/aws-cloud-engineer/knowledge/{project-context,standards,cost}
```

### Step 2: Document AWS Accounts

Create `.claude/agents/aws-cloud-engineer/knowledge/project-context/aws-accounts.md`:

```markdown
---
title: AWS Account Configuration
category: project-context
last_updated: 2025-10-09
---

# AWS Account Configuration

## Development Account

- **Account ID**: 123456789012
- **Profile**: my-project-dev
- **Region**: us-east-1
- **Purpose**: Development and testing

## Production Account

- **Account ID**: 987654321098
- **Profile**: my-project-prod
- **Region**: us-east-1
- **Purpose**: Production workloads

## Cross-Account Roles

### CDKDeployRole

- **ARN**: arn:aws:iam::987654321098:role/CDKDeployRole
- **Purpose**: CI/CD deployments to production
- **Trust**: GitHub Actions OIDC
```

### Step 3: Document Stack Architecture

Create `.claude/agents/aws-cloud-engineer/knowledge/project-context/stack-architecture.md`:

```markdown
---
title: CDK Stack Architecture
category: project-context
last_updated: 2025-10-09
---

# CDK Stack Architecture

## Stack Organization

### NetworkStack

- **Purpose**: VPC, subnets, NAT gateways
- **Update Frequency**: Rarely
- **Exports**: VpcId, PublicSubnetIds, PrivateSubnetIds

### DatabaseStack

- **Purpose**: RDS/Aurora/DynamoDB
- **Dependencies**: NetworkStack
- **Exports**: DatabaseEndpoint

### ApplicationStack

- **Purpose**: ECS/Lambda/API Gateway
- **Dependencies**: NetworkStack, DatabaseStack
- **Exports**: ApiEndpoint, LoadBalancerDns
```

### Step 4: Document Resource Identifiers

Create `.claude/agents/aws-cloud-engineer/knowledge/project-context/resource-identifiers.md`:

```markdown
---
title: AWS Resource Identifiers
category: project-context
last_updated: 2025-10-09
---

# AWS Resource Identifiers

## VPC Resources

- **VPC ID**: vpc-0abc123def456
- **Public Subnet 1**: subnet-0abc123
- **Public Subnet 2**: subnet-0def456
- **Private Subnet 1**: subnet-0ghi789
- **Private Subnet 2**: subnet-0jkl012

## Security Groups

- **ALB Security Group**: sg-0abc123
- **Application Security Group**: sg-0def456
- **Database Security Group**: sg-0ghi789

## KMS Keys

- **Database Encryption**: arn:aws:kms:us-east-1:123456789012:key/abc123-def456
- **S3 Encryption**: arn:aws:kms:us-east-1:123456789012:key/def456-ghi789
```

### Step 5: Document Naming Conventions

Create `.claude/agents/aws-cloud-engineer/knowledge/standards/naming-conventions.md`:

```markdown
---
title: AWS Resource Naming Conventions
category: standards
last_updated: 2025-10-09
---

# AWS Resource Naming Conventions

## Pattern

`{project}-{environment}-{service}-{resource-type}`

## Examples

- **S3 Bucket**: my-project-prod-data-bucket
- **Lambda Function**: my-project-prod-api-function
- **RDS Cluster**: my-project-prod-db-cluster
- **ECS Service**: my-project-prod-web-service

## Stack Names

`{Project}{Environment}{Purpose}Stack`

Examples:

- MyProjectProdNetworkStack
- MyProjectProdDatabaseStack
- MyProjectProdApplicationStack
```

### Step 6: Document Tagging Strategy

Create `.claude/agents/aws-cloud-engineer/knowledge/standards/tagging-strategy.md`:

```markdown
---
title: AWS Resource Tagging Strategy
category: standards
last_updated: 2025-10-09
---

# AWS Resource Tagging Strategy

## Required Tags

All resources MUST have:

- **Project**: my-project
- **Environment**: dev | staging | prod
- **ManagedBy**: cdk
- **CostCenter**: engineering
- **Owner**: team-infra@example.com

## Optional Tags

- **Service**: web | api | worker | database
- **BackupPolicy**: daily | weekly | none
- **Compliance**: hipaa | pci | sox | none
```

## Using the Agent

### Example: Designing Infrastructure

```
You: Design a serverless API using Lambda and API Gateway

Claude invokes aws-cloud-engineer:
1. Loads user-level AWS patterns
2. Loads project-level AWS account configuration (if exists)
3. Recommends Lambda + API Gateway architecture
4. Uses project naming conventions
5. Applies project tagging strategy
6. Provides CDK code
```

### Example: Multi-Stack Organization

```
You: How should I organize my CDK stacks for this application?

Claude invokes aws-cloud-engineer:
1. Loads multi-stack architecture patterns
2. Considers project stack architecture (if exists)
3. Recommends layer-based organization
4. Provides code examples with project naming
```

## Knowledge Organization

### Core Concepts

Fundamental AWS and CDK knowledge:

- `cdk-fundamentals.md` - CDK basics, construct levels, stack patterns
- `aws-services-overview.md` - Key AWS services overview
- `cloudformation-deep-dive.md` - CloudFormation concepts
- `well-architected-framework.md` - AWS best practices

### Patterns

Reusable infrastructure patterns:

- `multi-stack-architectures.md` - Stack organization strategies
- `cross-stack-references.md` - Sharing resources between stacks
- `custom-constructs.md` - Creating reusable CDK constructs
- `configuration-management.md` - Managing environment configs
- `testing-strategies.md` - Testing CDK infrastructure

### Decisions

Decision frameworks and guidance:

- `when-to-use-this-agent.md` - Agent invocation guidance
- `service-selection-matrix.md` - Choosing AWS services
- `cost-optimization-strategies.md` - Reducing AWS costs
- `security-patterns.md` - Security best practices

### Services

Deep-dive documentation organized by service category:

- `compute/` - EC2, ECS, Lambda, Fargate
- `storage/` - S3, EBS, EFS, Glacier
- `networking/` - VPC, Route53, CloudFront, ALB/NLB
- `database/` - RDS, Aurora, DynamoDB
- `security/` - IAM, KMS, Secrets Manager, Security Groups

## Customizing User-Level Knowledge

You can customize this knowledge base with your AWS preferences:

### Add AWS Service Preferences

Create files in `services/{category}/` with your preferred configurations:

```markdown
---
title: Lambda Best Practices
category: compute
last_updated: 2025-10-09
---

# Lambda Best Practices

## My Preferred Settings

- **Runtime**: Node.js 18.x or Python 3.11
- **Memory**: Start with 512MB, optimize from there
- **Timeout**: 30 seconds max for APIs, longer for async tasks
- **Architecture**: ARM (Graviton2) for cost savings
```

### Add Cost Optimization Strategies

Document cost optimization patterns you've discovered:

```markdown
---
title: Cost Optimization Lessons Learned
category: decisions
last_updated: 2025-10-09
---

# Cost Optimization Lessons Learned

## RDS Cost Reduction

- Switched from Multi-AZ to Aurora Serverless v2
- Saved 40% on database costs
- Auto-scales between 0.5 and 2 ACUs based on load
```

### Add Security Patterns

Document security configurations you use across projects:

```markdown
---
title: Standard IAM Policies
category: security
last_updated: 2025-10-09
---

# Standard IAM Policies

## Lambda Execution Role Template

```typescript
new PolicyStatement({
  effect: Effect.ALLOW,
  actions: ['logs:CreateLogGroup', 'logs:CreateLogStream', 'logs:PutLogEvents'],
  resources: ['arn:aws:logs:*:*:*'],
});
```
```

## Maintenance

### User-Level Knowledge

**Update when**:
- Discover new AWS patterns or services
- Learn CDK best practices
- Find cost optimization opportunities
- Refine security standards

**Review schedule**:
- Monthly: Check for AWS service updates
- Quarterly: Comprehensive pattern review
- Annually: Major architectural philosophy updates

### Project-Level Knowledge

**Update when**:
- AWS accounts or regions change
- Infrastructure architecture evolves
- New resources provisioned
- Naming or tagging standards change

**Review schedule**:
- Weekly: During active infrastructure development
- After major deployments: Update resource identifiers

## Current Knowledge Status

**Created Files** (3):
1. `core-concepts/cdk-fundamentals.md` - CDK basics and patterns
2. `patterns/multi-stack-architectures.md` - Stack organization strategies
3. `decisions/when-to-use-this-agent.md` - Agent invocation guidance

**Planned Files**:
- Additional AWS service documentation
- More CDK patterns (custom constructs, testing, configuration)
- Service selection matrices
- Security and cost optimization deep-dives

Expand this knowledge base over time as you work on AWS projects.

## Getting Help

- **Agent file**: `~/.claude/agents/aws-cloud-engineer/aws-cloud-engineer.md`
- **Knowledge index**: `~/.claude/agents/aws-cloud-engineer/knowledge/index.md`
- **Example setups**: See patterns and decisions directories

---

**Last Updated**: 2025-10-09
**Knowledge Base Version**: 1.0
