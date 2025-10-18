# ADR-007: Product/Platform/API Engineering Model

**Status**: Accepted
**Date**: 2025-10-16
**Deciders**: Project Lead
**Context**: Software
**Tags**: architecture, agents, engineering, full-stack

## Context and Problem Statement

Traditional frontend/backend engineering split no longer reflects modern software development. Modern frameworks (Next.js, Remix, SvelteKit) blur the frontend/backend line with full-stack capabilities. Serverless architectures, microservices, and API-first design require engineers to work across the entire stack.

We need to decide how to organize engineering agents to:
- Support modern full-stack development practices
- Clearly define ownership for different types of code
- Match how engineering teams actually organize
- Support microservices, serverless, and monolithic architectures
- Enable engineers to own entire features end-to-end

Without a clear model, we risk:
- Artificial separation between UI and API code in Next.js apps
- Confusion about which agent handles microservices
- Unclear ownership for platform capabilities vs product features
- Agents that don't match real-world engineering roles

## Decision Drivers

- **Modern Frameworks**: Must support Next.js, Remix, serverless (full-stack, not split)
- **Clear Ownership**: Engineers should own complete features or services
- **Real-World Teams**: Should reflect how engineering teams actually organize
- **Flexibility**: Support monoliths, microservices, serverless, hybrid architectures
- **Maintainability**: Clear boundaries prevent agent overlap
- **Scalability**: Easy to understand which agent handles which type of work

## Considered Options

### Option A: Traditional Frontend/Backend Split

**Description**: Separate frontend and backend engineering:

```text
frontend-engineer/
  → Handles: React, Vue, Angular, CSS, browser APIs

backend-engineer/
  → Handles: Python, Node.js, PHP, databases, APIs
```

**Pros**:
- Familiar traditional model
- Clear technology boundaries

**Cons**:
- Doesn't fit Next.js (which is both frontend and backend)
- Artificial split for full-stack features
- Unclear where server components go (frontend or backend?)
- Doesn't handle serverless well (Lambda is backend, but rendering?)
- Microservices span both frontend (dashboard) and backend (API)
- Requires handoff between agents for single feature

**Cost**: Outdated model, doesn't match modern development

### Option B: Single Full-Stack Engineer

**Description**: One general-purpose engineer handles everything:

```text
full-stack-engineer/
→ Handles: Everything (UI, API, database, deployment, infrastructure)
```

**Pros**:
- No artificial splits
- Single agent for entire feature
- Matches "full-stack developer" role

**Cons**:
- Too broad, lacks specialization
- Platform code vs product code blur together
- External APIs vs internal services lack distinction
- Knowledge base would be enormous
- Can't specialize for different contexts

**Cost**: Too generic, lacks focus

### Option C: Product/Platform/API Split (Recommended)

**Description**: Organize by purpose and audience, not by technology layer:

**product-engineer**:
- **Purpose**: User-facing features (full-stack)
- **Audience**: End users
- **Handles**: UI, API endpoints, business logic, tests, monitoring
- **Examples**: Next.js apps, user dashboards, customer-facing features

**platform-engineer**:
- **Purpose**: Platform capabilities and shared services
- **Audience**: Internal engineers
- **Handles**: Libraries, SDKs, internal services, shared infrastructure
- **Examples**: Auth service, notification system, shared UI components

**api-engineer**:
- **Purpose**: External/partner integrations
- **Audience**: External developers, partners
- **Handles**: Public APIs, webhooks, SDKs, API docs, versioning
- **Examples**: REST APIs for partners, GraphQL for mobile apps, webhooks

**data-engineer** (existing):
- **Purpose**: Data pipelines and analytics
- **Audience**: Analysts, data scientists
- **Handles**: ELT, data warehouse, dbt, data quality

**Pros**:
- Matches purpose and audience (product vs platform vs external)
- Full-stack within each domain (no artificial layer split)
- Clear ownership (product features vs platform capabilities vs partner APIs)
- Supports all architectures (monolith, microservices, serverless)
- Engineers own entire context (Next.js product-engineer owns UI + API)
- Scales naturally (add mobile-engineer for mobile-specific needs)

**Cons**:
- Less familiar than frontend/backend
- Requires understanding the distinction
- Some overlap (where does internal admin UI go?)

**Cost**: Learning curve, high clarity once understood

### Option D: Microservices-Based Split

**Description**: Organize by service type:

```text
web-app-engineer/
microservice-engineer/
lambda-engineer/
mobile-engineer/
```

**Pros**:
- Matches deployment architecture

**Cons**:
- Too architecture-specific
- Doesn't help with "what to build"
- Lambdas can be product, platform, or API
- Microservices can be product, platform, or API
- Confusion about which agent for a given feature

**Cost**: Architecture-driven, not purpose-driven

## Decision Outcome

**Chosen option**: Option C - Product/Platform/API Engineering Model

**Rationale**:

1. **Purpose-Driven**: Organizes by WHAT you're building and WHO it's for, not by technology layer
   - Product: For end users
   - Platform: For internal engineers
   - API: For external developers/partners

2. **Full-Stack Within Domain**: Each engineer owns the full stack for their domain:
   - product-engineer owns Next.js UI + API routes + database queries
   - platform-engineer owns auth service (frontend dashboard + backend API)
   - api-engineer owns external API + SDK + documentation

3. **Modern Framework Support**:
   - Next.js app? → product-engineer (owns entire app)
   - Remix app? → product-engineer (owns full-stack feature)
   - Serverless API? → Could be product, platform, or api-engineer (depends on audience)

4. **Clear Ownership**:
   - User feature? → product-engineer
   - Shared library? → platform-engineer
   - Partner integration? → api-engineer
   - Data pipeline? → data-engineer

5. **Architecture Agnostic**: Works with monoliths, microservices, serverless, hybrid:
   - Monolith: product-engineer owns product routes, platform-engineer owns shared modules
   - Microservices: each service owned by appropriate engineer based on purpose
   - Serverless: each Lambda owned by appropriate engineer based on audience

### Consequences

**Positive**:
- Engineers own complete features end-to-end (no handoff between UI and API)
- Clear ownership based on purpose and audience
- Supports modern full-stack frameworks naturally
- Platform capabilities clearly separated from product features
- External APIs have dedicated expertise (versioning, docs, SDKs)
- Flexible across architectures (monolith, microservices, serverless)
- Easier to decide which agent to use (ask "who is this for?")

**Negative**:
- Less familiar than traditional frontend/backend split
  - **Mitigation**: Clear documentation with examples, agent descriptions explain distinction
- Edge cases (where does internal admin UI go?)
  - **Mitigation**: Document decision tree: "internal tooling for ops" → platform-engineer, "user-facing admin" → product-engineer
- Requires understanding purpose/audience distinction
  - **Mitigation**: Agent prompts clarify when to use each, examples in knowledge base

**Neutral**:
- Engineers use same skills (React, Python, etc.) regardless of agent
- Skills become technology-specific (react-patterns, fastapi-async), shared across agents
- Two-tier architecture still applies (user-level + project-level knowledge)

## Validation

- [x] Supports modern full-stack frameworks (Next.js, Remix, SvelteKit)
- [x] Clear ownership by purpose/audience
- [x] Works with all architectures (monolith, microservices, serverless)
- [x] Engineers own complete features (no UI/API handoff)
- [x] Scales naturally (can add mobile-engineer, desktop-engineer if needed)
- [x] Reviewed and approved by project lead

## Implementation Notes

### product-engineer

**Purpose**: Build user-facing features end-to-end

**Audience**: End users, customers

**Scope**:
- Full-stack web applications (Next.js, Remix, SvelteKit)
- User interfaces (React, Vue, Angular)
- API endpoints for product features
- Business logic and data access
- Product-specific integrations
- User-facing workflows

**Examples**:
- "Build a user dashboard showing account activity"
- "Add password reset feature"
- "Create checkout flow"
- "Implement multi-factor authentication for users"

**Technologies**: React, Next.js, TypeScript, Python, Node.js, databases

**Not in Scope**:
- Shared libraries (platform-engineer)
- Partner APIs (api-engineer)
- Data pipelines (data-engineer)

### platform-engineer

**Purpose**: Build platform capabilities and shared services

**Audience**: Internal engineers, other services

**Scope**:
- Shared libraries and SDKs
- Internal services (auth, notifications, email)
- Developer tools and frameworks
- Infrastructure code (CDK, Terraform)
- Internal admin dashboards
- Service mesh, API gateways

**Examples**:
- "Build authentication service used by all apps"
- "Create shared React component library"
- "Implement notification service with email/SMS/push"
- "Build CDK constructs for common patterns"
- "Create internal admin tool for ops team"

**Technologies**: Python, Node.js, Go, CDK, Terraform, Docker, Kubernetes

**Not in Scope**:
- User-facing product features (product-engineer)
- External partner APIs (api-engineer)
- Data warehousing (data-engineer)

### api-engineer

**Purpose**: Build external APIs for partners and third parties

**Audience**: External developers, partners, mobile apps, third-party integrations

**Scope**:
- Public REST APIs
- GraphQL APIs for mobile/web
- Webhooks and event notifications
- API documentation (OpenAPI, GraphQL schema)
- SDK generation and maintenance
- API versioning and deprecation
- Rate limiting and API keys
- Partner integrations

**Examples**:
- "Design REST API for partners to query data"
- "Create GraphQL API for mobile app"
- "Implement webhook system for real-time events"
- "Generate Python SDK for our API"
- "Add API versioning (v2 with breaking changes)"

**Technologies**: REST, GraphQL, OpenAPI, SDK generation, API gateway, documentation

**Not in Scope**:
- Internal service-to-service APIs (platform-engineer)
- Product UI (product-engineer)
- Data pipelines (data-engineer)

### data-engineer (existing)

**Purpose**: Build data pipelines and analytics infrastructure

**Audience**: Analysts, data scientists, business users

**Scope**:
- ELT pipelines (Airbyte, Fivetran)
- Data warehouse (Snowflake, BigQuery)
- dbt models and transformations
- Data quality and testing
- Analytics dashboards (Metabase)
- Data orchestration (Airflow, Dagster)

**Examples**:
- "Build pipeline to ingest Salesforce data"
- "Create dbt dimensional model for sales"
- "Implement data quality tests"

**Technologies**: dbt, SQL, Python, Snowflake, Airbyte, Airflow

## Decision Tree for Agent Selection

Use this flowchart to decide which engineer agent to use:

```text
Is this data/analytics work?
├─ Yes → data-engineer
└─ No
   └─ Who is the primary audience?
      ├─ End users/customers → product-engineer
      ├─ External developers/partners → api-engineer
      └─ Internal engineers → platform-engineer
```

**Examples**:
- "Build user dashboard" → End users → **product-engineer**
- "Create auth service" → Internal services → **platform-engineer**
- "Design partner API" → External developers → **api-engineer**
- "Build ELT pipeline" → Data/analytics → **data-engineer**
- "Add feature to Next.js app" → End users → **product-engineer**
- "Create SDK for partners" → External developers → **api-engineer**
- "Build internal ops dashboard" → Internal ops team → **platform-engineer**

## References

- Modern full-stack frameworks: Next.js, Remix, SvelteKit
- Platform Engineering movement: Building internal developer platforms
- API-first design: APIs as products for external consumption
- Conway's Law: System design reflects organizational structure
- ADR-006: Analyst/Engineer Pattern (defines engineer role within analyst/engineer split)

## Related ADRs

- ADR-006: Analyst/Engineer Agent Pattern (provides context for why engineers own testing)
- ADR-008: Engineers Own Testing Philosophy (engineers in this model write their own tests)

## Updates

None yet
