---
title: When to Use AWS Cloud Engineer Agent
category: decisions
tags: [agent-invocation, guidance, workflow]
last_updated: 2025-10-09
---

# When to Use AWS Cloud Engineer Agent

## Agent Purpose

The `aws-cloud-engineer` agent provides AWS-specific infrastructure expertise, focusing on:

- **Infrastructure Definition**: What to build (CDK stacks, AWS services)
- **Service Selection**: Which AWS services to use and why
- **Architecture Design**: How to structure AWS infrastructure
- **Cost Optimization**: How to reduce AWS costs
- **Security Hardening**: How to secure AWS resources

## Invoke This Agent When...

### 1. Designing AWS Infrastructure

**Scenarios**:
- "Design a serverless API using Lambda and API Gateway"
- "What's the best way to host a containerized application on AWS?"
- "Design a multi-tier web application on AWS"
- "I need to store and process large amounts of data on AWS"

**Example**:
```
User: Design the AWS infrastructure for a web application with a database

→ Invoke aws-cloud-engineer
→ Agent analyzes requirements
→ Recommends: ECS Fargate (app), Aurora Serverless (DB), ALB (load balancing)
→ Designs VPC, security groups, IAM roles
→ Provides CDK code
```

### 2. Implementing or Optimizing CDK Stacks

**Scenarios**:
- "How do I create a CDK stack for this infrastructure?"
- "My CDK deployment is failing with dependency issues"
- "How do I share a VPC between multiple CDK stacks?"
- "Optimize this CDK code for better maintainability"

**Example**:
```
User: How do I organize my CDK app with network, database, and application layers?

→ Invoke aws-cloud-engineer
→ Agent loads multi-stack architecture patterns
→ Recommends layer-based stack organization
→ Provides code example with cross-stack references
→ Explains deployment order
```

### 3. Selecting AWS Services

**Scenarios**:
- "Should I use RDS or DynamoDB for this use case?"
- "What's the difference between ECS and EKS?"
- "Which storage service should I use: S3, EBS, or EFS?"
- "Lambda vs Fargate vs EC2 for this workload?"

**Example**:
```
User: Should I use Lambda or Fargate for a long-running background job?

→ Invoke aws-cloud-engineer
→ Agent evaluates requirements (execution time, memory, concurrency)
→ Recommends Fargate (Lambda has 15-minute timeout limit)
→ Explains trade-offs (cost, scalability, complexity)
```

### 4. Troubleshooting CloudFormation Deployments

**Scenarios**:
- "My CDK deployment failed with 'resource limit exceeded'"
- "CloudFormation stack is stuck in UPDATE_ROLLBACK_FAILED"
- "Cross-stack reference error during deployment"
- "IAM permission denied during CDK deploy"

**Example**:
```
User: CDK deploy failing with "Cannot exceed quota for Resources in stack"

→ Invoke aws-cloud-engineer
→ Agent diagnoses: Stack has too many resources (200+ limit)
→ Recommends: Split into multiple stacks
→ Provides multi-stack architecture pattern
```

### 5. Optimizing AWS Costs

**Scenarios**:
- "How can I reduce my EC2 costs?"
- "What are cost-effective options for this workload?"
- "Analyze my infrastructure for cost optimization opportunities"
- "Should I use Reserved Instances or Savings Plans?"

**Example**:
```
User: My Lambda costs are high, how can I reduce them?

→ Invoke aws-cloud-engineer
→ Agent analyzes: Memory allocation, execution time, invocation frequency
→ Recommends:
  - Use ARM (Graviton2) for 20% cost reduction
  - Optimize memory/CPU allocation
  - Implement caching to reduce invocations
  - Consider provisioned concurrency for predictable workloads
```

### 6. Hardening Security Configurations

**Scenarios**:
- "Design IAM policies with least privilege"
- "How do I encrypt data at rest and in transit?"
- "Secure S3 bucket configuration"
- "VPC security group rules best practices"

**Example**:
```
User: What IAM permissions does my Lambda need to access S3 and DynamoDB?

→ Invoke aws-cloud-engineer
→ Agent designs least-privilege IAM policy
→ Provides specific S3 and DynamoDB permissions
→ Includes CDK code for IAM role
→ Adds encryption and network security recommendations
```

### 7. Designing Multi-Stack or Multi-Account Architectures

**Scenarios**:
- "How do I organize CDK stacks for a large application?"
- "Design a multi-account AWS setup for dev/staging/prod"
- "Share VPC across multiple applications"
- "Cross-account access patterns"

**Example**:
```
User: How do I share a VPC between multiple CDK applications?

→ Invoke aws-cloud-engineer
→ Agent recommends:
  - Separate NetworkStack exporting VPC
  - Application stacks import VPC via cross-stack reference
  - Shows SSM Parameter Store alternative for loose coupling
→ Provides code examples
```

### 8. Creating Custom CDK Constructs

**Scenarios**:
- "Create a reusable CDK construct for a common pattern"
- "How do I encapsulate multiple resources into a construct?"
- "Design a construct library for my organization"

**Example**:
```
User: Create a reusable construct for a Lambda function with API Gateway

→ Invoke aws-cloud-engineer
→ Agent designs custom L3 construct
→ Includes Lambda, API Gateway, IAM role, CloudWatch logs
→ Provides TypeScript code with props interface
→ Adds testing examples
```

### 9. Performance Tuning and Scaling

**Scenarios**:
- "How do I auto-scale this ECS service?"
- "Optimize Lambda cold start times"
- "Design caching strategy for API"
- "RDS performance tuning recommendations"

**Example**:
```
User: My Lambda has high cold start latency, how can I fix it?

→ Invoke aws-cloud-engineer
→ Agent analyzes causes (large package size, VPC, language runtime)
→ Recommends:
  - Use Lambda SnapStart (for Java)
  - Minimize package size
  - Remove VPC if not needed
  - Use provisioned concurrency for critical paths
  - Consider switching to Node.js or Python if using Java
```

## DO NOT Invoke This Agent When...

### 1. Deployment Automation (Use devops-engineer instead)

**Scenarios**:
- "Create a GitHub Actions workflow to deploy CDK"
- "Setup CI/CD pipeline for AWS deployments"
- "Automate deployment to multiple environments"

**Why**: DevOps engineer handles CI/CD, deployment automation, and GitHub Actions

**Correct flow**:
```
User: Deploy my CDK stack via GitHub Actions

→ Invoke devops-engineer (NOT aws-cloud-engineer)
→ DevOps engineer creates GitHub Actions workflow
→ Workflow runs `cdk deploy` commands
```

### 2. Application Code (Use tech-lead or specialist engineers)

**Scenarios**:
- "Write the Lambda function code for this API"
- "Debug application code running in ECS"
- "Implement business logic for the service"

**Why**: AWS cloud engineer focuses on infrastructure, not application code

**Correct flow**:
```
User: Write Lambda code to process S3 events

→ Invoke tech-lead or nextjs-engineer (NOT aws-cloud-engineer)
→ Specialist writes application code
→ Can invoke aws-cloud-engineer for Lambda configuration (memory, timeout, permissions)
```

### 3. General Technical Questions (Use tech-lead)

**Scenarios**:
- "What architecture should I use for this project?"
- "Review my overall system design"
- "Technology selection for a new project"

**Why**: Tech-lead handles overall technical architecture, not just AWS

**Correct flow**:
```
User: What architecture should I use for a real-time chat application?

→ Invoke tech-lead (NOT aws-cloud-engineer)
→ Tech-lead analyzes requirements
→ Recommends overall architecture (WebSockets, message queue, database)
→ May then invoke aws-cloud-engineer for AWS implementation details
```

### 4. Non-AWS Cloud Platforms

**Scenarios**:
- "Deploy to Vercel"
- "Configure Google Cloud Platform"
- "Azure infrastructure design"

**Why**: This agent is AWS-specific

**Correct flow**:
```
User: Deploy my Next.js app to Vercel

→ Invoke devops-engineer or nextjs-engineer (NOT aws-cloud-engineer)
→ These agents handle non-AWS deployments
```

### 5. Database Schema Design (Use data-architect)

**Scenarios**:
- "Design the database schema for my application"
- "Optimize SQL queries"
- "Data modeling and normalization"

**Why**: Data-architect handles database design; aws-cloud-engineer handles AWS database service selection and configuration

**Correct flow**:
```
User: Design my database schema for an e-commerce application

→ Invoke data-architect (NOT aws-cloud-engineer)
→ Data-architect designs schema, relationships, indexes
→ Can then invoke aws-cloud-engineer to select RDS vs Aurora vs DynamoDB
```

## Differentiation from Other Agents

### vs DevOps Engineer

| Aspect | AWS Cloud Engineer | DevOps Engineer |
|--------|-------------------|-----------------|
| **Focus** | Infrastructure **definition** | Infrastructure **deployment** |
| **Scope** | CDK code, AWS services | CI/CD, GitHub Actions |
| **Output** | CDK stacks, CloudFormation | Deployment pipelines |
| **Example** | "Design ECS cluster stack" | "Deploy ECS via GitHub Actions" |

**Collaboration**:
1. AWS Cloud Engineer designs CDK stack
2. DevOps Engineer creates CI/CD to deploy it

### vs Tech Lead

| Aspect | AWS Cloud Engineer | Tech Lead |
|--------|-------------------|-----------|
| **Focus** | AWS-specific infrastructure | Overall technical architecture |
| **Scope** | AWS services and patterns | All technology decisions |
| **Output** | AWS architectures, CDK code | Technical specifications |
| **Example** | "Use Aurora Serverless" | "Use serverless architecture" |

**Collaboration**:
1. Tech Lead defines overall architecture
2. AWS Cloud Engineer implements AWS infrastructure

### vs Security Engineer

| Aspect | AWS Cloud Engineer | Security Engineer |
|--------|-------------------|-------------------|
| **Focus** | AWS security best practices | Deep security analysis |
| **Scope** | IAM, encryption, security groups | Threat modeling, compliance |
| **Output** | Secure AWS configurations | Security audit reports |
| **Example** | "Encrypt S3 with KMS" | "HIPAA compliance audit" |

**Collaboration**:
1. AWS Cloud Engineer implements baseline security
2. Security Engineer performs deep security review

### vs Cost Optimization Agent

| Aspect | AWS Cloud Engineer | Cost Optimization Agent |
|--------|-------------------|------------------------|
| **Focus** | AWS cost best practices | Deep FinOps analysis |
| **Scope** | Service selection, basic optimization | Comprehensive cost analysis |
| **Output** | Cost-effective architectures | Detailed cost reports |
| **Example** | "Use Spot Instances" | "Analyze 6-month cost trends" |

**Collaboration**:
1. AWS Cloud Engineer builds cost-aware infrastructure
2. Cost Optimization Agent analyzes and optimizes costs

## Agent Invocation Examples

### Good Invocations

```
✓ "Design a CDK stack for a serverless API"
✓ "How do I share a VPC between multiple stacks?"
✓ "Should I use RDS or DynamoDB for this use case?"
✓ "My CDK deployment is failing with circular dependency"
✓ "Create IAM policy with least privilege for Lambda"
✓ "Optimize my ECS task definition for cost"
✓ "How do I implement auto-scaling for this workload?"
```

### Poor Invocations (Use Different Agent)

```
✗ "Create GitHub Actions workflow to deploy CDK" → Use devops-engineer
✗ "Write Lambda function code for API" → Use tech-lead or specialist engineer
✗ "What overall architecture should I use?" → Use tech-lead
✗ "Design my database schema" → Use data-architect
✗ "Deploy to Vercel" → Use devops-engineer or nextjs-engineer
✗ "Perform security audit" → Use security-engineer
✗ "Analyze 6-month cost trends" → Use cost-optimization-agent
```

## Context Requirements

### Minimal Context (Generic Guidance)

Agent can provide generic AWS/CDK guidance without project context:

- General AWS service recommendations
- CDK patterns and best practices
- CloudFormation troubleshooting
- Security baseline recommendations

### Full Context (Project-Specific Recommendations)

For project-specific recommendations, agent needs:

**From project-level knowledge** (`.claude/agents/aws-cloud-engineer/knowledge/`):
- AWS account IDs and profiles
- Existing VPC and subnet IDs
- Stack architecture and dependencies
- Resource naming conventions
- Cost budgets and thresholds
- Security requirements

**From codebase**:
- `cdk.json` configuration
- Existing stack definitions
- Current AWS resources

## Agent Workflow

### Typical Workflow

1. **Load Knowledge**:
   - User-level AWS patterns and best practices
   - Project-level AWS account configuration (if exists)
   - CDK fundamentals and Well-Architected Framework

2. **Analyze Requirements**:
   - Understand user's AWS infrastructure needs
   - Identify constraints (cost, security, performance)
   - Check project context availability

3. **Design Solution**:
   - Apply AWS Well-Architected Framework
   - Select appropriate AWS services
   - Design CDK stack structure
   - Consider cost and security implications

4. **Provide Implementation**:
   - CDK code examples
   - CloudFormation explanations
   - Deployment instructions
   - Best practices and trade-offs

5. **Update Knowledge** (if applicable):
   - Document new patterns (user-level)
   - Update project architecture (project-level)

## Decision Tree

```
Does the task involve AWS infrastructure?
├─ No → Use different agent (tech-lead, devops-engineer, etc.)
└─ Yes
   ├─ Is it about DEFINING infrastructure (CDK, services)?
   │  └─ Yes → Use aws-cloud-engineer ✓
   │
   └─ Is it about DEPLOYING infrastructure (CI/CD)?
      └─ Yes → Use devops-engineer (not aws-cloud-engineer)
```

## Success Metrics

Agent is effective when:

1. **Correct Service Selection**: Recommends appropriate AWS services for requirements
2. **Well-Architected**: Designs follow AWS Well-Architected Framework
3. **Cost-Aware**: Considers cost implications in recommendations
4. **Secure by Default**: Implements security best practices
5. **Context-Aware**: Uses project-specific knowledge when available
6. **Maintainable**: Produces clean, well-organized CDK code
7. **Knowledge Growth**: Accumulates AWS patterns over time

## Related Knowledge

- **core-concepts/cdk-fundamentals.md** - CDK basics
- **patterns/multi-stack-architectures.md** - Stack organization
- **decisions/service-selection-matrix.md** - AWS service selection
- **decisions/cost-optimization-strategies.md** - Cost reduction strategies

---

**Category**: Decisions
**Last Updated**: 2025-10-09
**Status**: Complete