# When to Use the System Architect Agent

This document clarifies when to use the system-architect agent vs other agents (especially tech-lead).

## Quick Decision Tree

```
Are you asking about...

├── System-wide patterns, C4 models, or ADRs?
│   └── Use SYSTEM-ARCHITECT
│
├── Feature implementation or code structure?
│   └── Use TECH-LEAD
│
├── Security threats or encryption standards?
│   └── Use SECURITY-ENGINEER
│
├── AWS infrastructure or CDK patterns?
│   └── Use AWS-CLOUD-ENGINEER
│
├── Data governance or compliance?
│   └── Use DATA-GOVERNANCE-AGENT
│
└── Snowflake cost optimization?
    └── Use COST-OPTIMIZATION-AGENT
```

## System Architect vs Tech Lead

### Use System Architect When

**Architecture Documentation**:

- Creating C4 system context, container, or component diagrams
- Writing architecture decision records (ADRs)
- Documenting non-functional requirements
- Creating dimensional model specifications (for data projects)

**System-Wide Patterns**:

- Should we use microservices or monolith?
- What API design pattern (REST, GraphQL, gRPC)?
- How should services communicate (sync vs async)?
- What dimensional modeling approach (Kimball, Data Vault, hybrid)?

**Cross-Cutting Concerns**:

- Authentication and authorization strategy
- Logging and observability architecture
- Caching strategy across services
- Data lineage and governance framework

**Technology Selection**:

- Evaluate framework options (Next.js vs Remix vs SvelteKit)
- Build vs buy decisions
- Orchestration tool selection (Airflow vs Dagster vs Prefect)
- Database selection (PostgreSQL vs DynamoDB vs Snowflake)

**Data Architecture (dbt Projects)**:

- Dimensional model design (facts, dimensions, grain)
- dbt project structure and layering decisions
- SCD type selection (Type 1, 2, or 3)
- Incremental strategy for large fact tables
- Data quality framework design

### Use Tech Lead When

**Implementation Details**:

- How should I structure this React component?
- What's the best way to implement authentication in this API?
- How should I organize code in this module?
- What design pattern fits this feature (Strategy, Factory, etc.)?

**Code Review**:

- Review my pull request for code quality
- Check if code follows project standards
- Validate error handling approach
- Assess test coverage

**Technical Specifications**:

- Turn requirements into detailed technical specs
- Plan implementation phases for a feature
- Estimate technical complexity
- Identify technical risks for a sprint

**Feature Development**:

- Implement user registration flow
- Add pagination to API endpoint
- Optimize database query performance
- Refactor messy code

### Use Both Together

**Best Practice**: Software architect defines patterns → Tech lead implements them

**Example Workflow**:

1. **System Architect**: "Use event-driven architecture with EventBridge for service integration" (ADR created)
2. **Tech Lead**: "Implement EventBridge publisher in Order Service using AWS SDK" (technical spec created)

## System Architect vs Other Agents

### vs Security Engineer

**System Architect**:

- High-level security architecture (OAuth 2.0 vs SAML)
- Authentication strategy across services
- Data encryption at rest/in transit (strategy)

**Security Engineer**:

- Deep security analysis (threat modeling, penetration testing)
- Encryption implementation details (key rotation, algorithms)
- Security audit and compliance (SOC 2, HIPAA)
- Vulnerability assessment and remediation

**Overlap**: Security architecture decisions

**Example**:

- **Architect**: "Use OAuth 2.0 for API authentication" (ADR)
- **Security**: "Implement OAuth 2.0 with PKCE, 15-minute access tokens, rotate refresh tokens" (security spec)

### vs AWS Cloud Engineer

**System Architect**:

- Multi-cloud strategy (AWS vs Azure vs GCP)
- High-level cloud architecture (serverless vs containers)
- Service selection (Lambda vs ECS vs EC2)

**AWS Cloud Engineer**:

- AWS-specific implementation (CDK stacks, CloudFormation)
- Service configuration (VPC setup, IAM policies)
- Cost optimization (instance sizing, reserved capacity)
- AWS Well-Architected review

**Overlap**: Cloud service selection

**Example**:

- **Architect**: "Use serverless architecture for API" (ADR)
- **AWS Engineer**: "Implement with Lambda + API Gateway + DynamoDB" (CDK stack)

### vs Data Governance Agent

**System Architect**:

- Data architecture patterns (Kimball, Data Vault)
- Data quality framework design
- Dimensional model design

**Data Governance Agent**:

- Compliance implementation (GDPR, CCPA)
- PII detection and masking strategies
- Audit trail implementation
- Data classification and tagging

**Overlap**: Data governance architecture

**Example**:

- **Architect**: "Implement data quality framework with dbt tests" (ADR)
- **Governance**: "Add PII detection tests for email, SSN, phone fields" (compliance spec)

### vs Cost Optimization Agent

**System Architect**:

- Incremental strategy for dbt models
- Materialization decisions (view vs table)
- Partitioning and clustering strategy

**Cost Optimization Agent**:

- Snowflake warehouse sizing
- Query cost analysis
- Storage optimization
- Credit consumption monitoring

**Overlap**: Performance vs cost trade-offs

**Example**:

- **Architect**: "Use incremental models for facts > 1M rows" (ADR)
- **Cost Optimizer**: "fct_orders uses 12 credits/day, consider daily partitioning instead of merge" (cost analysis)

## When to Use System Architect for Data Projects

### Always Use for

**Dimensional Modeling**:

- Designing fact and dimension tables
- Choosing grain for fact tables
- Deciding SCD type for dimensions
- Designing conformed dimensions

**dbt Project Structure**:

- Layering strategy (staging → intermediate → marts)
- Naming conventions
- Incremental strategies
- Snapshot configuration

**Architecture Documentation**:

- ERD diagrams for dimensional models
- ADRs for modeling decisions
- Data lineage documentation
- Business logic documentation

### Sometimes Use for

**Data Quality**:

- Framework design (use system-architect)
- Specific test implementation (use tech-lead)

**Performance Optimization**:

- Clustering and partitioning strategy (use system-architect)
- Warehouse sizing (use cost-optimization-agent)
- Query optimization (use tech-lead)

### Don't Use for

**Tactical Decisions**:

- Column naming in specific model (use tech-lead)
- Specific SQL optimization (use tech-lead)
- dbt macro implementation (use tech-lead)

## Example Questions

### System Architect Questions

**Software Projects**:

- "Should we use microservices or a monolith for this project?"
- "What's the best authentication strategy for our API (OAuth, JWT, SAML)?"
- "How should our services communicate (REST, gRPC, message queue)?"
- "Create a C4 container diagram for our system"
- "Document the decision to use PostgreSQL over DynamoDB"

**Data Projects**:

- "Design a dimensional model for our e-commerce orders"
- "Should we use Kimball or Data Vault for our data warehouse?"
- "What SCD type should we use for customer dimensions?"
- "How should we structure our dbt project (layering, naming)?"
- "What incremental strategy for our large fact tables?"

### Tech Lead Questions

**Software Projects**:

- "How should I implement password reset in this Node.js API?"
- "Review my React component for code quality"
- "What's the best way to handle errors in this Lambda function?"
- "Help me refactor this messy service layer"

**Data Projects**:

- "How do I implement SCD Type 2 in this dbt model?"
- "Optimize this slow dbt incremental model"
- "Review my dbt macro for code quality"
- "Help me debug this failing dbt test"

## Delegation Patterns

### Parallel Consultation

Use multiple agents in parallel when you need different perspectives:

**Example**: Designing authentication system

1. **System Architect**: High-level auth strategy, system-wide patterns
2. **Security Engineer**: Security requirements, threat model
3. **AWS Cloud Engineer**: AWS implementation (Cognito vs custom)
4. **Tech Lead**: Implementation details, code structure

### Sequential Delegation

**Pattern**: Architect → Specialist → Tech Lead

**Example**: New microservice

1. **System Architect**: System architecture, service boundaries, integration patterns (ADR)
2. **AWS Cloud Engineer**: Infrastructure design (CDK stack)
3. **Security Engineer**: Security requirements (threat model)
4. **Tech Lead**: Technical spec, implementation plan

### Project Type Specific

**dbt Data Warehouse**:

1. **System Architect**: Dimensional models, dbt structure
2. **Data Governance Agent**: Compliance, PII handling
3. **Cost Optimization Agent**: Warehouse sizing, incremental strategies
4. **Tech Lead**: dbt implementation, SQL optimization

**Microservices API**:

1. **System Architect**: System architecture, API design
2. **AWS Cloud Engineer**: Infrastructure (Lambda, API Gateway)
3. **Security Engineer**: Authentication, authorization
4. **Tech Lead**: Service implementation

## Version History

**v1.0** - 2025-10-15

- Initial documentation of agent boundaries
- Decision tree for agent selection
- Examples for software and data projects
- Delegation patterns