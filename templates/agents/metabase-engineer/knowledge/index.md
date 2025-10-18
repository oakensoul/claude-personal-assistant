---
title: "Metabase Engineer Knowledge Base"
description: "Comprehensive knowledge base for Metabase BI platform engineering"
category: "knowledge-index"
last_updated: "2025-10-16"
knowledge_count: 24
agent: "metabase-engineer"
---

# Metabase Engineer Knowledge Base

Comprehensive documentation for Metabase reports-as-code development, API operations, visualization design, and deployment automation.

## Knowledge Categories

### Core Concepts (8 documents)

Foundational knowledge about Metabase architecture and reports-as-code methodology.

- **[metabase-architecture.md](core-concepts/metabase-architecture.md)** - Metabase data model, collections, dashboards, questions, and database connections
- **[reports-as-code-methodology.md](core-concepts/reports-as-code-methodology.md)** - Version control, CI/CD, and infrastructure-as-code principles for BI
- **[yaml-specification-schema.md](core-concepts/yaml-specification-schema.md)** - Complete YAML schema reference for dashboards and questions
- **[dashboard-architecture.md](core-concepts/dashboard-architecture.md)** - Dashboard structure, layout grid system, and organization patterns
- **[question-types.md](core-concepts/question-types.md)** - Native queries, GUI queries, and model-based questions
- **[visualization-types.md](core-concepts/visualization-types.md)** - Complete reference of Metabase chart types and when to use them
- **[filters-and-parameters.md](core-concepts/filters-and-parameters.md)** - Dashboard filters, parameter passing, and cross-filtering
- **[collections-and-permissions.md](core-concepts/collections-and-permissions.md)** - Collection organization and access control

### API Reference (6 documents)

Complete Metabase REST API documentation and usage patterns.

- **[api-authentication.md](api-reference/api-authentication.md)** - Session tokens, API keys, and credential management
- **[api-dashboards.md](api-reference/api-dashboards.md)** - Dashboard CRUD operations and card management
- **[api-questions.md](api-reference/api-questions.md)** - Question CRUD, query execution, and result retrieval
- **[api-collections.md](api-reference/api-collections.md)** - Collection management and organization
- **[api-databases.md](api-reference/api-databases.md)** - Database connections and schema synchronization
- **[api-error-handling.md](api-reference/api-error-handling.md)** - Common errors, rate limiting, and retry strategies

### Design Patterns (5 documents)

Dashboard and visualization design best practices.

- **[kpi-scorecard-patterns.md](design-patterns/kpi-scorecard-patterns.md)** - KPI cards, comparison values, and executive scorecards
- **[time-series-patterns.md](design-patterns/time-series-patterns.md)** - Line charts, area charts, and temporal analysis
- **[dashboard-layout-patterns.md](design-patterns/dashboard-layout-patterns.md)** - Grid layouts, responsive design, and visual hierarchy
- **[executive-dashboard-templates.md](design-patterns/executive-dashboard-templates.md)** - High-level KPI dashboards for leadership
- **[operational-dashboard-templates.md](design-patterns/operational-dashboard-templates.md)** - Detailed analytical dashboards for operators

### Deployment Automation (4 documents)

Python scripts, CI/CD pipelines, and deployment strategies.

- **[python-deployment-scripts.md](deployment-automation/python-deployment-scripts.md)** - Script architecture, API interaction, and idempotent deployments
- **[cicd-pipeline-patterns.md](deployment-automation/cicd-pipeline-patterns.md)** - GitHub Actions, GitLab CI, and deployment workflows
- **[environment-configuration.md](deployment-automation/environment-configuration.md)** - Dev/staging/prod setup and credential management
- **[rollback-strategies.md](deployment-automation/rollback-strategies.md)** - Version control and disaster recovery

### Question Patterns (3 documents)

Reusable SQL query patterns and question templates.

- **[reusable-question-library.md](question-patterns/reusable-question-library.md)** - Shared questions and template questions
- **[parameter-passing-patterns.md](question-patterns/parameter-passing-patterns.md)** - Dashboard-to-question and question-to-question parameters
- **[drill-through-configuration.md](question-patterns/drill-through-configuration.md)** - Click-through navigation and detail views

### Troubleshooting (4 documents)

Common issues, debugging techniques, and performance optimization.

- **[common-api-errors.md](troubleshooting/common-api-errors.md)** - Authentication failures, rate limiting, and API errors
- **[query-performance-optimization.md](troubleshooting/query-performance-optimization.md)** - Slow queries, caching, and optimization techniques
- **[dashboard-load-issues.md](troubleshooting/dashboard-load-issues.md)** - Too many questions, inefficient layouts, and rendering problems
- **[deployment-failures.md](troubleshooting/deployment-failures.md)** - CI/CD issues, validation errors, and rollback procedures

### Integrations (2 documents)

Patterns for coordinating with other agents and tools.

- **[sql-expert-integration.md](integrations/sql-expert-integration.md)** - Query optimization workflow and handoff patterns
- **[agent-coordination-patterns.md](integrations/agent-coordination-patterns.md)** - Working with product-manager, tech-lead, and data-engineer

### External Links (2 documents)

References to official documentation and community resources.

- **[official-documentation.md](external-links/official-documentation.md)** - Metabase docs, API reference, and community forums
- **[tools-and-libraries.md](external-links/tools-and-libraries.md)** - Python libraries, CLI tools, and development resources

## Quick Reference

### Most Used Documents

1. **[yaml-specification-schema.md](core-concepts/yaml-specification-schema.md)** - When creating new dashboards
2. **[api-dashboards.md](api-reference/api-dashboards.md)** - When deploying via API
3. **[kpi-scorecard-patterns.md](design-patterns/kpi-scorecard-patterns.md)** - When designing executive dashboards
4. **[python-deployment-scripts.md](deployment-automation/python-deployment-scripts.md)** - When building automation
5. **[query-performance-optimization.md](troubleshooting/query-performance-optimization.md)** - When dashboards are slow

### By Use Case

**Creating a New Dashboard**:
1. [yaml-specification-schema.md](core-concepts/yaml-specification-schema.md) - Schema reference
2. [dashboard-layout-patterns.md](design-patterns/dashboard-layout-patterns.md) - Layout design
3. [kpi-scorecard-patterns.md](design-patterns/kpi-scorecard-patterns.md) - KPI cards
4. [api-dashboards.md](api-reference/api-dashboards.md) - API deployment

**Optimizing Performance**:
1. [query-performance-optimization.md](troubleshooting/query-performance-optimization.md) - Query tuning
2. [dashboard-load-issues.md](troubleshooting/dashboard-load-issues.md) - Dashboard optimization
3. [sql-expert-integration.md](integrations/sql-expert-integration.md) - Get SQL expert help

**Setting Up CI/CD**:
1. [python-deployment-scripts.md](deployment-automation/python-deployment-scripts.md) - Script development
2. [cicd-pipeline-patterns.md](deployment-automation/cicd-pipeline-patterns.md) - Pipeline configuration
3. [environment-configuration.md](deployment-automation/environment-configuration.md) - Environment setup

**Troubleshooting Deployments**:
1. [deployment-failures.md](troubleshooting/deployment-failures.md) - Failure diagnosis
2. [common-api-errors.md](troubleshooting/common-api-errors.md) - API error resolution
3. [rollback-strategies.md](deployment-automation/rollback-strategies.md) - Recovery procedures

## Knowledge Base Maintenance

**Update Frequency**: Review and update monthly or when major Metabase versions are released

**Contribution**: Add new patterns as they emerge from real projects

**Deprecation**: Mark outdated patterns and provide migration guidance

---

**Last Updated**: 2025-10-16
**Next Review**: 2025-11-16
**Agent**: metabase-engineer
