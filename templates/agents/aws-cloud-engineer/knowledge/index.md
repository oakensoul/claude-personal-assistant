---
title: AWS Cloud Engineer Knowledge Base
description: User-level AWS and CDK knowledge catalog
knowledge_count: 3
last_updated: 2025-10-09
---

# AWS Cloud Engineer Knowledge Base

This knowledge base contains generic AWS and CDK expertise applicable across all AWS-based projects.

## Purpose

Provide reusable AWS architectural patterns, CDK implementation guidance, and Well-Architected Framework best practices that work across all projects. Project-specific AWS configurations (account IDs, resource identifiers, stack architectures) belong in project-level knowledge.

## Knowledge Categories

### Core Concepts (3 files)

Fundamental AWS and CDK documentation:

- **cdk-fundamentals.md** - CDK basics, construct levels (L1/L2/L3), stack patterns
- **aws-services-overview.md** - Overview of key AWS services and when to use them
- **well-architected-framework.md** - AWS Well-Architected Framework principles

### Patterns (5 files)

Reusable infrastructure patterns:

- **multi-stack-architectures.md** - How to organize complex CDK apps with multiple stacks
- **cross-stack-references.md** - Sharing resources between stacks
- **custom-constructs.md** - Creating reusable CDK constructs
- **configuration-management.md** - Managing environment-specific configurations
- **testing-strategies.md** - Testing CDK infrastructure code

### Decisions (3 files)

Decision frameworks and matrices:

- **when-to-use-this-agent.md** - Clear guidance on when to invoke aws-cloud-engineer
- **service-selection-matrix.md** - Decision matrix for selecting AWS services
- **cost-optimization-strategies.md** - Strategies for reducing AWS costs

### Services

Service-specific deep-dive documentation organized by category:

#### Compute (4 files planned)
- EC2 instance selection and configuration
- ECS/Fargate container orchestration
- Lambda serverless patterns
- Auto-scaling strategies

#### Storage (4 files planned)
- S3 bucket policies and lifecycle rules
- EBS volume optimization
- EFS file system configuration
- Glacier archival strategies

#### Networking (4 files planned)
- VPC design patterns
- Route53 DNS configuration
- CloudFront CDN optimization
- Load balancer selection (ALB/NLB)

#### Database (4 files planned)
- RDS vs Aurora selection
- DynamoDB table design
- Database performance tuning
- Backup and recovery strategies

#### Security (4 files planned)
- IAM policy design patterns
- KMS encryption strategies
- Secrets Manager integration
- Security group best practices

## Two-Tier Architecture

### User-Level Knowledge (This Location)

**Location**: `~/.claude/agents/aws-cloud-engineer/knowledge/`

**Contains**: Generic AWS/CDK patterns, service documentation, best practices

**Scope**: All AWS projects

### Project-Level Knowledge

**Location**: `{project}/.claude/agents/aws-cloud-engineer/knowledge/`

**Contains**: Project-specific AWS accounts, resource IDs, stack architectures, naming conventions

**Scope**: Specific CDK project only

**Must be created by users** for each CDK project requiring project-specific context.

## Usage

The aws-cloud-engineer agent automatically loads knowledge from this directory when invoked. Reference specific files when you need:

- AWS service selection guidance: See `decisions/service-selection-matrix.md`
- CDK implementation patterns: See `patterns/multi-stack-architectures.md`
- Cost optimization: See `decisions/cost-optimization-strategies.md`
- Security best practices: See `services/security/`

## Maintenance

**Update when**:
- New AWS services or features released
- CDK patterns proven across projects
- AWS best practices evolve
- Cost optimization strategies discovered
- Security patterns refined

**Review schedule**:
- Monthly: AWS service updates
- Quarterly: Comprehensive CDK pattern review
- Annually: Well-Architected Framework updates

## Getting Started

### For First-Time Setup

1. **Customize user-level knowledge** with your AWS preferences:
   - Preferred AWS services
   - Standard CDK patterns
   - Cost optimization strategies
   - Security baselines

2. **For each CDK project**, create project-specific knowledge:
   ```bash
   cd /path/to/cdk/project
   mkdir -p .claude/agents/aws-cloud-engineer/knowledge/{project-context,standards,cost}
   ```

3. **Document project-specific details**:
   - AWS account IDs and profiles
   - VPC IDs, subnet IDs, security group IDs
   - Existing stack architecture
   - Naming conventions and tagging strategies
   - Cost budgets and thresholds

## Initial Files

The following files have been created to get started:

1. **core-concepts/cdk-fundamentals.md** - CDK basics and patterns
2. **patterns/multi-stack-architectures.md** - Organizing complex CDK apps
3. **decisions/when-to-use-this-agent.md** - Agent invocation guidance

Expand this knowledge base over time as you work on AWS projects and discover new patterns.

---

**Knowledge Base Version**: 1.0
**Agent**: aws-cloud-engineer
**Last Updated**: 2025-10-09