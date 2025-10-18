---
agent: datadog-observability-engineer
knowledge_count: 6
last_updated: 2025-10-09
categories:
  - Core Concepts
  - AWS Integrations
  - Cost Optimization
  - Alert Patterns
  - Dashboard Templates
  - Troubleshooting
---

# DataDog Observability Engineer - Knowledge Base

This knowledge base provides comprehensive reference material for DataDog monitoring and observability best practices across AWS infrastructure.

## Knowledge Organization

### Core Concepts

Fundamental DataDog architecture, agent types, and integration patterns that apply universally.

- **datadog-architecture.md** - DataDog platform overview, agent types, data flow
- **integration-patterns.md** - Common patterns for integrating DataDog with AWS services
- **tagging-strategy.md** - Best practices for consistent tagging across infrastructure
- **observability-pillars.md** - Metrics, logs, traces, and how they interconnect

### AWS Integrations

Service-specific guides for instrumenting AWS resources with DataDog.

- **lambda-instrumentation.md** - DataDog Lambda Extension, layers, async log forwarding
- **ecs-fargate-monitoring.md** - Sidecar container patterns, task-level metrics
- **rds-monitoring.md** - Enhanced monitoring, slow query logs, custom metrics
- **api-gateway-monitoring.md** - Access logs, execution logs, custom metrics
- **s3-monitoring.md** - CloudTrail integration, request metrics
- **eventbridge-monitoring.md** - Custom event metrics and tracing
- **step-functions-monitoring.md** - Execution tracing and state metrics

### Cost Optimization

Strategies and techniques for optimizing DataDog spend without sacrificing visibility.

- **log-cost-optimization.md** - Sampling, exclusion filters, retention policies
- **metric-cardinality-management.md** - Controlling high-cardinality metrics
- **apm-sampling-strategies.md** - Intelligent trace sampling configurations
- **cost-analysis-framework.md** - How to analyze and justify DataDog costs
- **retention-policies.md** - Appropriate retention by data type and compliance needs

### Alert Patterns

Common alert configurations, anti-patterns, and best practices for reducing alert fatigue.

- **alert-design-principles.md** - Threshold selection, evaluation windows, recovery
- **composite-monitors.md** - Multi-signal alerts to reduce noise
- **runbook-templates.md** - Standard runbook format for alert resolution
- **escalation-policies.md** - On-call rotation and escalation strategies
- **slo-monitoring.md** - Service Level Objective tracking and error budgets

### Dashboard Templates

Reusable dashboard examples and design patterns for different audiences.

- **service-health-dashboard.md** - RED/USE metrics for engineering teams
- **executive-dashboard.md** - Business KPIs and system health for leadership
- **infrastructure-dashboard.md** - Resource utilization and cost tracking
- **incident-response-dashboard.md** - Real-time troubleshooting views
- **sla-compliance-dashboard.md** - SLA tracking and reporting

### Troubleshooting

Common issues, debugging techniques, and resolution steps.

- **agent-connectivity-issues.md** - Diagnosing DataDog agent connection problems
- **missing-metrics-logs.md** - Why data isn't appearing in DataDog
- **high-cardinality-debugging.md** - Identifying and fixing cardinality explosions
- **apm-trace-gaps.md** - Debugging missing or incomplete traces
- **integration-validation.md** - Testing DataDog integrations before production

## How This Knowledge Base is Used

### During Agent Invocation

When the `datadog-observability-engineer` agent is invoked, it can reference these knowledge files to:

- Provide detailed, service-specific instrumentation guidance
- Offer cost optimization strategies based on current spend patterns
- Suggest alert configurations from proven patterns
- Generate dashboard templates for specific use cases
- Troubleshoot monitoring issues systematically

### Relationship to CLAUDE.md

- **CLAUDE.md** (always loaded): High-level agent description, when to use, core capabilities
- **Knowledge Base** (reference): Detailed how-to guides, code examples, troubleshooting steps

This separation keeps the always-loaded context lean while maintaining comprehensive documentation.

## Knowledge Maintenance

### Adding New Knowledge

When adding new knowledge files:

1. Place in appropriate category directory
2. Add frontmatter with title, description, last_updated
3. Update this index.md with file description
4. Increment knowledge_count in frontmatter

### Updating Existing Knowledge

When updating knowledge files:

1. Update the last_updated date in file frontmatter
2. Update last_updated in this index if significant changes
3. Maintain backward compatibility with existing references

### Knowledge Sources

- DataDog official documentation
- AWS service integration guides
- Real-world production experience
- Cost optimization case studies
- Incident postmortem lessons learned

## Future Knowledge Areas

Potential areas for expansion:

- **Security Monitoring**: SIEM integration, threat detection, compliance
- **Multi-Cloud**: Azure and GCP monitoring patterns
- **Kubernetes**: EKS/K8s cluster monitoring and helm charts
- **Serverless Frameworks**: Serverless Framework, SAM, CDK integration
- **CI/CD Integration**: Automated monitoring validation in pipelines
- **Machine Learning**: Anomaly detection, forecasting, intelligent alerting

---

**Last Updated**: 2025-10-09
**Knowledge Count**: 6 categories, 30+ planned files
**Maintainer**: claude-agent-manager
