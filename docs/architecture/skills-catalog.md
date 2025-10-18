---
title: "Skills Catalog & Roadmap"
description: "Comprehensive catalog of skills to implement for AIDA system"
category: "architecture"
tags: ["skills", "roadmap", "planning"]
last_updated: "2025-10-16"
status: "draft"
audience: "developers"
---

# Skills Catalog & Roadmap

This document catalogs all skills to be implemented for the AIDA system, organized by category.

**Total Planned Skills**: 177
**Categories**: 28
**Status**: Planning phase - Phase 1 (META) defined, Phase 2/3 in progress

---

## Skills by Category

### 1. style-guides/ (File Formats & Standards)

**Purpose**: Consistent formatting and style across all files

- [ ] **markdown-style-guide** 🔥 **CRITICAL**
    - Used by: technical-writer, ALL agents (everyone writes markdown)
    - Why: Pass markdownlint, consistent docs across AIDA system
    - Files: formatting-rules, lists-and-spacing, code-blocks, headings-and-structure, links-and-references, tables, frontmatter, common-mistakes-md032-md031-md040
    - **Priority**: PHASE 1 - Foundation

- [ ] **frontmatter-patterns** 🔥 **CRITICAL**
    - Used by: technical-writer, ALL agents creating markdown files
    - Why: AIDA requires frontmatter on all markdown docs
    - Files: required-fields, optional-fields, categories, tags, validation, examples
    - **Priority**: PHASE 1 - Foundation

- [ ] **yaml-style-guide**
  - Used by: ALL engineers (docker-compose, GitHub Actions, dbt, configs)
  - Why: Pass yamllint --strict, consistent YAML
  - Files: indentation-rules, structure, quoting-rules, anchors-aliases, docker-compose-patterns, github-actions-yaml, common-mistakes

- [ ] **json-patterns**
  - Used by: ALL engineers
  - Why: JSON structure, schema design, API responses
  - Files: formatting, schema-design, validation, api-responses, config-files

- [ ] **toml-config**
  - Used by: product-engineer, platform-engineer (Python pyproject.toml, Rust Cargo.toml)
  - Why: Configuration file standards
  - Files: structure, sections, python-projects, rust-projects

- [ ] **commit-message-conventions**
  - Used by: ALL engineers
  - Why: Consistent git history, changelog generation
  - Files: conventional-commits, scope-and-type, body-and-footer, examples, aida-conventions

- [ ] **code-comment-standards**
  - Used by: ALL engineers
  - Why: Useful comments vs noise
  - Files: when-to-comment, docstrings, inline-comments, todo-fixme, self-documenting-code

- [ ] **naming-conventions**
  - Used by: ALL engineers
  - Why: Consistent naming across codebase
  - Files: variables-functions, classes-modules, files-directories, databases-tables, api-endpoints, constants

---

### 2. technical-writing/ (Documentation Excellence)

**Purpose**: Clear, effective technical communication

- [ ] **technical-writing-principles**
  - Used by: technical-writer, ALL engineers (writing docs)
  - Why: Clarity, conciseness, audience awareness
  - Files: writing-principles, audience-analysis, clarity-and-conciseness, active-voice, structure-and-flow

- [ ] **diagramming-patterns**
  - Used by: technical-writer, system-architect, tech-lead
  - Why: Visual communication, architecture diagrams
  - Files: mermaid-diagrams, c4-models, ascii-art, sequence-diagrams, flowcharts, entity-relationship, architecture-diagrams

- [ ] **api-documentation**
  - Used by: technical-writer, api-engineer
  - Why: Developer-facing API docs
  - Files: openapi-docs, graphql-docs, sdk-docs, code-examples, authentication-docs, error-documentation, getting-started

- [ ] **readme-templates**
  - Used by: technical-writer, ALL engineers
  - Why: Consistent project documentation
  - Files: project-readme, package-readme, library-readme, getting-started, installation-guide, contributing-guide, badges

- [ ] **tutorial-writing**
  - Used by: technical-writer
  - Why: Step-by-step guides, onboarding
  - Files: tutorial-structure, screenshots-and-visuals, code-samples, prerequisites, troubleshooting, learning-objectives

- [ ] **runbook-templates**
  - Used by: technical-writer, devops-engineer, datadog-observability-engineer
  - Why: Operational documentation
  - Files: incident-runbooks, maintenance-runbooks, deployment-runbooks, troubleshooting-guides, escalation-procedures

- [ ] **adr-patterns**
  - Used by: technical-writer, system-architect, tech-lead
  - Why: Architecture Decision Records (AIDA uses ADRs!)
  - Files: adr-template, decision-drivers, options-analysis, consequences, validation, examples

- [ ] **changelog-patterns**
  - Used by: technical-writer, devops-engineer
  - Why: Release notes, version history
  - Files: keep-a-changelog, semantic-versioning, release-notes, migration-guides, breaking-changes

- [ ] **content-organization**
  - Used by: technical-writer
  - Why: Information architecture, navigation
  - Files: site-structure, navigation-design, search-and-discovery, categorization, tagging-taxonomy

---

### 3. meta/ (Claude Code & AIDA System)

**Purpose**: Creating agents, commands, skills - meta knowledge about AIDA itself

- [ ] **claude-code-setup** 🔥 **CRITICAL**
  - Used by: claude-agent-manager, technical-writer
  - Why: How to set up and configure Claude Code
  - Files: installation, configuration, mcp-setup, claude-md-structure, project-setup

- [ ] **agent-development**
  - Used by: claude-agent-manager
  - Why: Creating effective agents
  - Files: agent-instructions, knowledge-organization, two-tier-architecture, agent-patterns, when-to-create-agent

- [ ] **command-development**
  - Used by: claude-agent-manager
  - Why: Creating slash commands
  - Files: command-structure, workflow-orchestration, agent-invocation, variable-substitution, examples

- [ ] **skill-development**
  - Used by: claude-agent-manager, technical-writer
  - Why: Creating effective skills (meta!)
  - Files: skill-structure, readme-format, content-organization, when-to-create-skill, skill-categories

- [ ] **anthropic-api**
  - Used by: platform-engineer, api-engineer
  - Why: Claude API usage, programmatic access
  - Files: api-basics, prompt-engineering, streaming, function-calling, vision, rate-limits

---

### 4. bash-unix/ (Shell & CLI Mastery)

**Purpose**: Shell scripting, Unix utilities, macOS CLI - agents struggle here!

- [ ] **bash-scripting** 🔥 **HIGH PRIORITY**
  - Used by: ALL engineers
  - Why: Agents frequently make bash mistakes
  - Files: basics, error-handling-set-euo-pipefail, variables-and-quoting, conditionals-and-loops, functions, common-pitfalls

- [ ] **macos-cli**
  - Used by: ALL engineers (macOS development)
  - Why: macOS-specific commands
  - Files: pbcopy-pbpaste, open-command, defaults-command, system-commands, filesystem-specific

- [ ] **unix-utilities**
  - Used by: ALL engineers
  - Why: grep, sed, awk, find, xargs mastery
  - Files: grep-patterns, sed-basics, awk-processing, find-command, xargs-parallel, sort-uniq-cut

- [ ] **jq-patterns**
  - Used by: ALL engineers (JSON manipulation)
  - Why: JSON querying and transformation
  - Files: basic-queries, filters, transformations, arrays-and-objects, aws-cli-integration

- [ ] **shell-debugging**
  - Used by: ALL engineers
  - Why: Debugging bash scripts
  - Files: set-x-tracing, trap-command, debugging-techniques, common-errors

- [ ] **file-operations**
  - Used by: ALL engineers
  - Why: Safe file handling
  - Files: permissions-chmod, symlinks, mv-cp-rm-safely, directories, wildcards-and-globbing

- [ ] **process-management**
  - Used by: devops-engineer, platform-engineer
  - Why: Managing processes
  - Files: ps-command, kill-signals, jobs-bg-fg, nohup-screen-tmux

---

### 5. cli-tools/ (Essential CLI Tools)

**Purpose**: Git, GitHub CLI, AWS CLI, Docker CLI

- [ ] **git-workflows** 🔥 **HIGH PRIORITY**
  - Used by: ALL engineers
  - Why: Branching, merging, rebasing, conflict resolution
  - Files: branching-strategies, merging-rebasing, conflict-resolution, cherry-picking, stashing, bisecting

- [ ] **gh-cli**
  - Used by: ALL engineers
  - Why: GitHub CLI for PRs, issues, releases
  - Files: pr-workflows, issue-management, releases, actions-runs, repo-management

- [ ] **aws-cli**
  - Used by: aws-cloud-engineer, devops-engineer
  - Why: AWS CLI patterns
  - Files: configuration, s3-operations, ec2-instances, lambda-functions, iam-policies, cloudformation

- [ ] **docker-cli**
  - Used by: platform-engineer, devops-engineer
  - Why: Docker command patterns
  - Files: build-run-exec, images-containers, volumes, networks, compose, cleanup

---

### 6. compliance/ (Regulatory Requirements)

**Purpose**: HIPAA, GDPR, PCI, SOC2, SOX compliance

- [ ] **hipaa-compliance** ✅ (CREATED - example)
  - Used by: governance-analyst, compliance-analyst, product-engineer, platform-engineer, data-engineer
  - Why: Healthcare projects require HIPAA compliance
  - Files: requirements, phi-handling, security-rule, privacy-rule, audit-logging, encryption, access-control

- [ ] **gdpr-compliance**
  - Used by: governance-analyst, compliance-analyst, ALL engineers
  - Why: EU customers require GDPR compliance
  - Files: requirements, right-to-deletion, consent-management, data-minimization, privacy-by-design, breach-notification

- [ ] **pci-compliance**
  - Used by: governance-analyst, compliance-analyst, product-engineer, platform-engineer
  - Why: Payment processing requires PCI-DSS
  - Files: requirements, payment-handling, encryption, access-control, network-security, vulnerability-management

- [ ] **soc2-compliance**
  - Used by: governance-analyst, compliance-analyst, ALL engineers
  - Why: Enterprise customers require SOC2
  - Files: requirements, trust-principles, controls, evidence-collection, audit-readiness

- [ ] **sox-compliance**
  - Used by: governance-analyst, compliance-analyst, data-engineer
  - Why: Financial reporting compliance (Sarbanes-Oxley)
  - Files: requirements, internal-controls, audit-trails, change-management, segregation-of-duties

- [ ] **ccpa-compliance**
  - Used by: governance-analyst, compliance-analyst
  - Why: California privacy law
  - Files: requirements, consumer-rights, data-inventory, opt-out-mechanisms

---

### 7. testing/ (Testing Frameworks & Patterns)

**Purpose**: Unit, integration, E2E, performance testing

- [ ] **pytest-patterns** ✅ (CREATED - example)
  - Used by: quality-analyst, product-engineer, platform-engineer, data-engineer
  - Why: Primary Python testing framework
  - Files: setup, fixtures, mocking, parametrize, coverage, ci-integration

- [ ] **playwright-automation**
  - Used by: quality-analyst, product-engineer
  - Why: E2E testing for web applications
  - Files: setup, page-objects, test-patterns, selectors, ci-integration, debugging, visual-regression

- [ ] **jest-testing**
  - Used by: quality-analyst, product-engineer, platform-engineer
  - Why: JavaScript/TypeScript testing
  - Files: setup, mocking, snapshot-testing, async-testing, coverage, react-testing-library

- [ ] **k6-performance**
  - Used by: performance-analyst, ALL engineers
  - Why: Load and performance testing
  - Files: setup, load-test-patterns, metrics-and-thresholds, scenarios, analysis, ci-integration

- [ ] **dbt-testing**
  - Used by: quality-analyst, data-engineer
  - Why: Data quality testing in dbt
  - Files: schema-tests, data-tests, custom-tests, great-expectations, test-coverage, unit-tests

- [ ] **api-testing**
  - Used by: quality-analyst, api-engineer, product-engineer
  - Why: API integration testing
  - Files: rest-testing, graphql-testing, contract-testing, postman-newman, authentication-testing

- [ ] **phpunit-patterns**
  - Used by: quality-analyst, product-engineer
  - Why: PHP testing framework
  - Files: setup, mocking, database-testing, integration-tests

- [ ] **cypress-automation**
  - Used by: quality-analyst, product-engineer
  - Why: Alternative E2E testing framework
  - Files: setup, commands, plugins, ci-integration, component-testing

---

### 8. frameworks/ (Frontend & Backend Frameworks)

**Purpose**: React, Next.js, FastAPI, Django, Vue, Slim, etc.

**Frontend Frameworks**:

- [ ] **react-patterns**
  - Used by: product-engineer, platform-engineer
  - Why: Primary frontend framework
  - Files: component-composition, hooks-patterns, state-management, performance-optimization, context-api, custom-hooks

- [ ] **nextjs-setup**
  - Used by: product-engineer
  - Why: Full-stack React framework
  - Files: app-router, server-components, api-routes, data-fetching, deployment, optimization, middleware

- [ ] **typescript-config**
  - Used by: product-engineer, platform-engineer, api-engineer
  - Why: Type safety for JavaScript projects
  - Files: setup, tsconfig-options, types-and-interfaces, generics, strict-mode, migration-from-js

- [ ] **vue-patterns**
  - Used by: product-engineer
  - Why: Alternative frontend framework
  - Files: composition-api, reactivity-system, components, state-management-pinia, router

- [ ] **css-frameworks** 🔥 **HIGH PRIORITY**
  - Used by: product-engineer
  - Why: UI styling and component libraries
  - Files: tailwind-setup-and-patterns, bootstrap-usage, material-ui, ant-design, chakra-ui, css-in-js-styled-components, utility-first-css, responsive-design

- [ ] **frontend-data-visualization**
  - Used by: product-engineer
  - Why: Implementing charts and graphs in React/TypeScript
  - Files: d3js-patterns, chartjs-integration, recharts-react, victory-charts, plotly-react, choosing-library, responsive-charts, interactive-visualizations, performance-optimization

**Backend Frameworks**:

- [ ] **fastapi-patterns**
  - Used by: product-engineer, platform-engineer, api-engineer
  - Why: Modern async Python API framework
  - Files: setup, routing, dependencies-injection, async-patterns, validation-pydantic, authentication, database-integration

- [ ] **django-patterns**
  - Used by: product-engineer, platform-engineer
  - Why: Full-featured Python web framework
  - Files: setup, models-and-migrations, views-and-templates, serializers, authentication, orm-patterns, django-rest-framework

- [ ] **slim-framework**
  - Used by: product-engineer
  - Why: PHP micro-framework (user uses this!)
  - Files: setup, routing, middleware, dependency-injection, templates, database

- [ ] **nodejs-patterns**
  - Used by: product-engineer, platform-engineer
  - Why: Backend JavaScript/TypeScript
  - Files: express-framework, async-patterns, error-handling, middleware, streams

- [ ] **php-laravel**
  - Used by: product-engineer
  - Why: PHP framework (if still in use)
  - Files: setup, routing, eloquent-orm, middleware, authentication, artisan

---

### 9. api/ (API Design & Implementation)

**Purpose**: REST, GraphQL, OpenAPI, webhooks, authentication

- [ ] **api-design**
  - Used by: api-engineer, platform-engineer, product-engineer
  - Why: Core API design patterns
  - Files: rest-conventions, resource-design, http-methods, status-codes, pagination, filtering-sorting, error-handling

- [ ] **openapi-spec**
  - Used by: api-engineer, platform-engineer
  - Why: API documentation and contracts
  - Files: openapi-3-spec, spec-writing, validation, code-generation, documentation-tools

- [ ] **graphql-schema**
  - Used by: api-engineer, product-engineer
  - Why: GraphQL API design
  - Files: schema-design, resolvers, queries-mutations, subscriptions, federation, performance

- [ ] **api-versioning**
  - Used by: api-engineer
  - Why: API evolution and deprecation
  - Files: versioning-strategies, deprecation-process, migration-guides, backwards-compatibility

- [ ] **webhook-patterns**
  - Used by: api-engineer, platform-engineer
  - Why: Event-driven integrations
  - Files: webhook-design, delivery-guarantees, retry-logic, security-signing, idempotency

- [ ] **authentication-patterns**
  - Used by: api-engineer, platform-engineer, product-engineer
  - Why: Secure authentication and authorization
  - Files: oauth2-flows, jwt-tokens, api-keys, session-management, mfa, rbac

- [ ] **grpc-patterns**
  - Used by: api-engineer, platform-engineer
  - Why: High-performance RPC (if needed)
  - Files: proto-definitions, services, streaming, error-handling, middleware

- [ ] **rate-limiting**
  - Used by: api-engineer, platform-engineer
  - Why: API protection and fair usage
  - Files: strategies, algorithms-token-bucket, implementation, monitoring, quotas

---

### 10. data-engineering/ (Data Pipelines & Transformation)

**Purpose**: dbt, Airbyte, orchestration, data quality

- [ ] **dbt-incremental-strategy**
  - Used by: data-engineer, sql-expert
  - Why: Critical for performance optimization
  - Files: strategies-overview, append-only, merge-upsert, delete-insert, performance-comparison, examples

- [ ] **dbt-modeling-patterns**
  - Used by: data-engineer
  - Why: Core dbt development
  - Files: staging-models, intermediate-models, marts, sources-and-seeds, snapshots, macros, testing

- [ ] **kimball-dimensional-modeling**
  - Used by: data-engineer, system-architect
  - Why: Data warehouse design (Kimball methodology)
  - Files: facts-and-dimensions, slowly-changing-dimensions, star-schema, snowflake-schema, conformed-dimensions, kimball-lifecycle

- [ ] **airbyte-setup**
  - Used by: data-engineer
  - Why: Primary ingestion tool
  - Files: connectors-catalog, configuration, normalization, custom-sources, incremental-sync, troubleshooting

- [ ] **sql-optimization**
  - Used by: data-engineer, sql-expert
  - Why: Query performance tuning
  - Files: query-tuning, indexes-clustering, explain-plans, common-patterns, anti-patterns, window-functions

- [ ] **data-quality-patterns**
  - Used by: data-engineer, quality-analyst
  - Why: Data reliability and trust
  - Files: great-expectations, dbt-tests, assertions, monitoring, anomaly-detection, data-contracts

- [ ] **pii-detection**
  - Used by: data-engineer, governance-analyst
  - Why: Privacy compliance, data protection
  - Files: detection-patterns, masking-techniques, tokenization, anonymization, regex-patterns

- [ ] **airflow-dags**
  - Used by: data-engineer
  - Why: Orchestration patterns
  - Files: dag-design, operators, sensors, dependencies-and-scheduling, testing, monitoring

- [ ] **fivetran-setup**
  - Used by: data-engineer
  - Why: Alternative ingestion tool
  - Files: connectors, configuration, transformations, scheduling

---

### 11. databases/ (Database Platforms)

**Purpose**: Snowflake, PostgreSQL, MySQL, DynamoDB, Redis

- [ ] **snowsql** 🔥 **HIGH PRIORITY**
  - Used by: data-engineer, sql-expert
  - Why: Agents struggle with SnowSQL CLI syntax!
  - Files: connection-setup, query-execution, variables, scripting, output-formats, common-mistakes

- [ ] **snowflake-patterns**
  - Used by: data-engineer, sql-expert
  - Why: Snowflake-specific features and optimization
  - Files: clustering-keys, search-optimization, materialized-views, zero-copy-cloning, time-travel, streams-tasks

- [ ] **snowflake-optimization**
  - Used by: data-engineer, sql-expert
  - Why: Performance tuning and cost optimization
  - Files: query-tuning, warehouse-sizing, clustering, result-caching, cost-optimization

- [ ] **postgresql-patterns**
  - Used by: product-engineer, platform-engineer, data-engineer
  - Why: Postgres-specific features
  - Files: jsonb-operations, arrays, full-text-search, window-functions, indexes, partitioning

- [ ] **mysql-patterns**
  - Used by: product-engineer, platform-engineer
  - Why: MySQL/MariaDB specifics
  - Files: storage-engines, indexes, replication, partitioning, optimization

- [ ] **dynamodb-patterns**
  - Used by: product-engineer, platform-engineer
  - Why: NoSQL patterns, single-table design
  - Files: single-table-design, gsi-lsi, streams, dax-caching, capacity-planning

- [ ] **redis-patterns**
  - Used by: platform-engineer, product-engineer
  - Why: Caching, pub/sub, data structures
  - Files: caching-strategies, data-structures, pub-sub, session-storage, rate-limiting

- [ ] **database-design**
  - Used by: ALL engineers
  - Why: General database design principles
  - Files: normalization, denormalization, indexing-strategies, relationships, migrations

---

### 12. infrastructure/ (Infrastructure as Code)

**Purpose**: CDK, Terraform, Docker, AWS services

- [ ] **cdk-patterns**
  - Used by: aws-cloud-engineer, platform-engineer, devops-engineer
  - Why: Primary IaC for AWS
  - Files: constructs-stacks, custom-constructs, best-practices, testing, cross-stack-references, deployment

- [ ] **github-actions-workflows**
  - Used by: devops-engineer, ALL engineers
  - Why: Primary CI/CD platform
  - Files: workflow-patterns, reusable-workflows, custom-actions, secrets-management, matrix-builds, deployment-strategies

- [ ] **terraform-modules**
  - Used by: aws-cloud-engineer, devops-engineer
  - Why: Alternative IaC (if used)
  - Files: module-design, state-management, workspaces, testing-terratest, best-practices

- [ ] **docker-patterns**
  - Used by: platform-engineer, devops-engineer
  - Why: Containerization best practices
  - Files: dockerfile-best-practices, multi-stage-builds, optimization, security-scanning, compose

- [ ] **lambda-patterns**
  - Used by: aws-cloud-engineer, platform-engineer, product-engineer
  - Why: Serverless compute
  - Files: cold-starts-optimization, layers, powertools, async-invocation, error-handling, packaging

- [ ] **ecs-patterns**
  - Used by: aws-cloud-engineer, platform-engineer
  - Why: Container orchestration on AWS
  - Files: task-definitions, services, autoscaling, deployment-strategies, service-discovery

- [ ] **rds-patterns**
  - Used by: aws-cloud-engineer, data-engineer
  - Why: Relational database management on AWS
  - Files: setup-configuration, backups-snapshots, read-replicas, performance-tuning, migration

---

### 13. security/ (Security Patterns - Comprehensive)

**Purpose**: Application security, vulnerability prevention, AI/LLM security

**Security Foundations**:

- [ ] **encryption-patterns**
  - Used by: security-analyst, ALL engineers
  - Why: Data protection at rest and in transit
  - Files: at-rest-encryption, in-transit-tls, key-management, algorithms-aes-rsa, envelope-encryption

- [ ] **secret-management**
  - Used by: security-analyst, devops-engineer, ALL engineers
  - Why: Secure credential handling
  - Files: aws-secrets-manager, parameter-store, environment-variables, rotation-strategies, vault

- [ ] **penetration-testing**
  - Used by: security-analyst
  - Why: Security validation and testing
  - Files: methodology, tools-burp-zap, vulnerability-scanning, reporting

**Injection Attacks**:

- [ ] **sql-injection-prevention**
  - Used by: security-analyst, ALL engineers
  - Why: Classic attack, still very prevalent
  - Files: parameterized-queries, orm-patterns, input-validation, stored-procedures, detection-prevention, sqlmap-defense

- [ ] **prompt-injection-prevention** 🔥 **CRITICAL for AIDA!**
  - Used by: security-analyst, product-engineer, platform-engineer, claude-agent-manager
  - Why: **AIDA is an AI system!** Prompt injection is a real threat
  - Files: attack-patterns, defense-strategies, input-sanitization, output-validation, context-isolation, system-prompts-protection, indirect-injection

- [ ] **command-injection-prevention**
  - Used by: security-analyst, ALL engineers
  - Why: Shell command injection, subprocess risks
  - Files: subprocess-safety, input-validation, allowlists, shell-escaping, dangerous-functions

- [ ] **nosql-injection**
  - Used by: security-analyst, product-engineer, platform-engineer
  - Why: MongoDB, DynamoDB injection attacks
  - Files: mongodb-injection, dynamodb-risks, input-validation, query-operators

- [ ] **template-injection**
  - Used by: security-analyst, product-engineer
  - Why: Jinja2, ERB, SSTI attacks
  - Files: ssti-prevention, template-escaping, safe-rendering, sandboxing

**Web Application Security**:

- [ ] **xss-prevention**
  - Used by: security-analyst, product-engineer
  - Why: Cross-Site Scripting attacks
  - Files: dom-xss, reflected-xss, stored-xss, content-security-policy, output-encoding, sanitization

- [ ] **csrf-prevention**
  - Used by: security-analyst, product-engineer
  - Why: Cross-Site Request Forgery
  - Files: csrf-tokens, same-site-cookies, double-submit, verification, stateless-csrf

- [ ] **ssrf-prevention**
  - Used by: security-analyst, ALL engineers
  - Why: Server-Side Request Forgery
  - Files: url-validation, allowlists, network-isolation, metadata-protection, cloud-ssrf

- [ ] **cors-security**
  - Used by: security-analyst, api-engineer, product-engineer
  - Why: Cross-Origin Resource Sharing vulnerabilities
  - Files: cors-configuration, origin-validation, credentials-handling, preflight

**API Security**:

- [ ] **api-security-patterns**
  - Used by: security-analyst, api-engineer, platform-engineer
  - Why: API-specific vulnerabilities (OWASP API Top 10)
  - Files: broken-object-level-auth, broken-authentication, excessive-data-exposure, lack-of-resources, mass-assignment, security-misconfiguration, injection, improper-assets-management, insufficient-logging, unsafe-consumption

- [ ] **authentication-oauth2**
  - Used by: security-analyst, platform-engineer, api-engineer
  - Why: Secure OAuth2 authentication flows
  - Files: oauth2-flows, pkce, token-management, refresh-tokens, scopes-permissions, authorization-code

**Authentication & Authorization**:

- [ ] **authentication-vulnerabilities**
  - Used by: security-analyst, ALL engineers
  - Why: Broken auth, session issues
  - Files: session-fixation, session-hijacking, jwt-vulnerabilities, password-storage-bcrypt, brute-force-prevention, credential-stuffing

- [ ] **authorization-patterns**
  - Used by: security-analyst, ALL engineers
  - Why: Broken access control, privilege escalation
  - Files: rbac, abac, idor-prevention, privilege-escalation-prevention, principle-of-least-privilege, vertical-horizontal-escalation

**AI/LLM Security**:

- [ ] **llm-security-patterns** 🔥 **CRITICAL for AIDA!**
  - Used by: security-analyst, claude-agent-manager, product-engineer, platform-engineer
  - Why: **AIDA-specific!** LLM security beyond prompt injection
  - Files: model-poisoning, data-poisoning, adversarial-examples, output-validation, context-leakage, pii-in-prompts, model-denial-of-service, supply-chain-vulnerabilities, insecure-plugin-design, excessive-agency

**Data Security**:

- [ ] **data-leakage-prevention**
  - Used by: security-analyst, ALL engineers
  - Why: Sensitive data exposure
  - Files: error-messages, debug-info, logs-sanitization, api-responses, metadata, stack-traces

- [ ] **insecure-deserialization**
  - Used by: security-analyst, ALL engineers (Python pickle, Java serialization)
  - Why: Remote code execution via deserialization
  - Files: pickle-dangers, yaml-unsafe-load, json-dangers, safe-alternatives, object-injection

- [ ] **path-traversal-prevention**
  - Used by: security-analyst, ALL engineers
  - Why: Directory traversal, file access attacks
  - Files: path-validation, allowlists, chroot, symlink-attacks, zip-slip

---

### 14. observability/ (Monitoring & Operations)

**Purpose**: Logging, metrics, tracing, alerting beyond DataDog

- [ ] **datadog-instrumentation**
  - Used by: datadog-observability-engineer, ALL engineers
  - Why: Primary monitoring platform
  - Files: lambda-instrumentation, ecs-instrumentation, rds-monitoring, custom-metrics, apm-tracing, dashboards, alerting

- [ ] **logging-patterns**
  - Used by: ALL engineers
  - Why: Structured logging, log aggregation
  - Files: structured-logging-json, log-levels, correlation-ids, centralized-logging, cloudwatch-logs

- [ ] **metrics-patterns**
  - Used by: datadog-observability-engineer, ALL engineers
  - Why: Application and system metrics
  - Files: prometheus-metrics, cloudwatch-metrics, custom-metrics, naming-conventions, aggregation

- [ ] **tracing-patterns**
  - Used by: datadog-observability-engineer, platform-engineer
  - Why: Distributed tracing across services
  - Files: opentelemetry, distributed-tracing, spans-traces, context-propagation, debugging

- [ ] **alerting-strategies**
  - Used by: datadog-observability-engineer, devops-engineer
  - Why: Effective alerting, reduce noise
  - Files: alert-design, thresholds, escalation-policies, on-call-runbooks, alert-fatigue

---

### 15. bi/ (Business Intelligence)

**Purpose**: Metabase, dashboards, analytics

- [ ] **data-visualization** 🔥 **HIGH PRIORITY**
  - Used by: metabase-engineer, data-engineer, product-engineer, product-manager
  - Why: "I need to visualize this data, what's the best way to tell the story?"
  - Files: chart-type-selection, data-storytelling-principles, when-to-use-bar-line-scatter, heatmaps-and-distributions, time-series-visualization, comparison-charts, part-to-whole-charts, relationship-charts, common-mistakes, color-theory-for-data, accessibility, interactive-vs-static

- [ ] **metabase-patterns**
  - Used by: metabase-engineer, data-engineer
  - Why: Primary BI tool
  - Files: dashboard-design, yaml-specs, api-automation, visualization-selection, performance-tuning, filters-parameters

- [ ] **dashboard-design**
  - Used by: metabase-engineer, product-manager
  - Why: Effective dashboard composition and layout
  - Files: design-principles, kpi-design, layout-hierarchy, color-theory, responsive-design, information-density

- [ ] **sql-for-analytics**
  - Used by: data-engineer, sql-expert
  - Why: Analytics-specific SQL patterns
  - Files: window-functions, ctes-complex-queries, aggregations, cohort-analysis, pivot-unpivot

---

### 16. project-management/ (Issue Tracking & Documentation)

**Purpose**: GitHub Projects, JIRA, Confluence

- [ ] **github-projects**
  - Used by: product-manager, tech-lead, ALL engineers
  - Why: GitHub Projects for issue tracking and roadmaps
  - Files: project-setup, views-and-fields, automation, roadmaps, issue-templates

- [ ] **jira-patterns**
  - Used by: product-manager, tech-lead
  - Why: JIRA workflows and issue management (includes MCP usage)
  - Files: workflows, jql-queries, dashboards, automation-rules, agile-boards, mcp-integration

- [ ] **confluence-patterns**
  - Used by: technical-writer, product-manager
  - Why: Team documentation in Confluence (includes MCP usage)
  - Files: page-structure, templates, macros, spaces-organization, mcp-integration

---

### 17. methodologies/ (Agile, Scrum, Kanban)

**Purpose**: Process patterns and templates

- [ ] **scrum-ceremonies**
  - Used by: product-manager, tech-lead
  - Why: Sprint planning, standups, retros, refinement
  - Files: sprint-planning-template, daily-standup-format, sprint-review, retrospective-formats, refinement-sessions

- [ ] **kanban-patterns**
  - Used by: product-manager, tech-lead
  - Why: Board structure, WIP limits, flow metrics
  - Files: board-setup, wip-limits, flow-metrics, continuous-delivery, pull-systems

- [ ] **agile-estimation**
  - Used by: product-manager, tech-lead
  - Why: Story points, planning poker, estimation techniques
  - Files: story-points, planning-poker, t-shirt-sizing, fibonacci-sequence, velocity-tracking

---

### 18. marketing-tech/ (Marketing Automation & CRM)

**Purpose**: Braze, Beehiiv, marketing tools

- [ ] **braze-integration**
  - Used by: product-engineer, platform-engineer
  - Why: Marketing campaigns, user engagement
  - Files: campaigns, segments, personalization, api-integration, webhooks, canvas-workflows

- [ ] **beehiiv-patterns**
  - Used by: product-engineer
  - Why: Newsletter platform management
  - Files: api-integration, subscriber-management, campaign-creation, analytics

- [ ] **mailchimp-api**
  - Used by: product-engineer
  - Why: Email marketing automation
  - Files: audiences, campaigns, automation-workflows, api-integration

- [ ] **segment-integration**
  - Used by: product-engineer, platform-engineer
  - Why: Customer data platform
  - Files: event-tracking, destinations, personas, protocols

- [ ] **hubspot-crm**
  - Used by: product-engineer
  - Why: CRM and marketing automation
  - Files: contacts, deals, workflows, api-integration

- [ ] **salesforce-integration**
  - Used by: product-engineer, data-engineer
  - Why: Enterprise CRM
  - Files: sobjects, soql-queries, apex-triggers, api-integration, bulk-api

- [ ] **intercom-patterns**
  - Used by: product-engineer
  - Why: Customer messaging and support
  - Files: messenger, articles, automation, api-integration

---

### 19. analytics/ (Web & Product Analytics)

**Purpose**: Google Analytics, Mixpanel, Amplitude

- [ ] **google-analytics**
  - Used by: product-engineer
  - Why: Web analytics (GA4)
  - Files: ga4-setup, events-and-conversions, custom-dimensions, reports, gtm-integration

- [ ] **mixpanel-integration**
  - Used by: product-engineer
  - Why: Product analytics
  - Files: event-tracking, user-profiles, funnels, cohorts, api-integration

- [ ] **amplitude-patterns**
  - Used by: product-engineer
  - Why: Behavioral analytics
  - Files: event-taxonomy, user-properties, charts, cohorts, api-integration

- [ ] **segment-tracking**
  - Used by: product-engineer
  - Why: Event tracking patterns with Segment
  - Files: event-spec, tracking-plan, sources-destinations, protocols

---

### 20. business-metrics/ (SaaS & Business Metrics)

**Purpose**: Business KPIs, SaaS metrics, financial analysis

- [ ] **saas-metrics**
  - Used by: product-manager, governance-analyst, metabase-engineer
  - Why: SaaS business metrics (ARR, MRR, churn, retention)
  - Files: arr-mrr-calculation, churn-retention, ltv-cac, nrr-grr, quick-ratio, rule-of-40, cohort-analysis

- [ ] **product-metrics**
  - Used by: product-manager, product-engineer, metabase-engineer
  - Why: Product health and engagement
  - Files: dau-mau-wau, activation-rate, feature-adoption, session-metrics, stickiness, north-star-metrics

- [ ] **financial-metrics**
  - Used by: product-manager, governance-analyst, metabase-engineer
  - Why: Financial health and planning
  - Files: burn-rate-runway, gross-margin, cogs, unit-economics, cash-flow, ebitda

- [ ] **engagement-metrics**
  - Used by: product-manager, product-engineer
  - Why: User engagement and behavior
  - Files: session-duration, frequency-recency, engagement-score, retention-curves, power-users

- [ ] **growth-metrics**
  - Used by: product-manager, product-engineer
  - Why: Growth analysis and forecasting
  - Files: viral-coefficient, k-factor, payback-period, magic-number, t2d3-growth

- [ ] **ab-test-metrics**
  - Used by: product-manager, product-engineer, quality-analyst
  - Why: Experimentation and statistical analysis
  - Files: statistical-significance, sample-size, confidence-intervals, multiple-testing, metric-selection, experiment-design

- [ ] **cohort-analysis-patterns**
  - Used by: product-manager, data-engineer, metabase-engineer
  - Why: Cohort-based analysis and retention
  - Files: cohort-definition, retention-analysis, revenue-cohorts, behavioral-cohorts, sql-patterns

---

### 21. payment-processing/ (E-commerce & Payments)

**Purpose**: Stripe, Shopify, subscription billing

- [ ] **stripe-integration**
  - Used by: product-engineer, api-engineer
  - Why: Payment processing
  - Files: checkout, subscriptions, webhooks, payment-intents, customer-management, connect

- [ ] **shopify-integration**
  - Used by: product-engineer
  - Why: E-commerce platform
  - Files: apps, graphql-admin-api, webhooks, products, orders

- [ ] **payment-patterns**
  - Used by: product-engineer, security-analyst
  - Why: General payment processing patterns
  - Files: idempotency, retry-logic, reconciliation, refunds, dispute-handling

- [ ] **subscription-billing**
  - Used by: product-engineer
  - Why: Recurring billing patterns
  - Files: subscription-lifecycle, proration, dunning, upgrades-downgrades

---

### 22. cms-content/ (Content Management Systems)

**Purpose**: WordPress, Contentful, headless CMS

- [ ] **wordpress-patterns**
  - Used by: product-engineer
  - Why: WordPress development
  - Files: plugins, rest-api, custom-post-types, hooks-filters

- [ ] **contentful-cms**
  - Used by: product-engineer
  - Why: Headless CMS
  - Files: content-modeling, api-integration, localization, webhooks

- [ ] **strapi-cms**
  - Used by: product-engineer
  - Why: Open-source headless CMS
  - Files: content-types, api-customization, plugins, deployment

- [ ] **sanity-patterns**
  - Used by: product-engineer
  - Why: Sanity.io CMS
  - Files: schemas, groq-queries, studio-customization, real-time-updates

---

### 23. communication/ (Team Communication Tools)

**Purpose**: Slack, Discord, email automation

- [ ] **slack-integration**
  - Used by: platform-engineer, product-engineer
  - Why: Slack bots and automation
  - Files: bot-development, webhooks, block-kit, slash-commands, events-api

- [ ] **discord-bots**
  - Used by: platform-engineer
  - Why: Discord bot development
  - Files: bot-setup, commands, embeds, webhooks, moderation

- [ ] **email-automation**
  - Used by: product-engineer
  - Why: Transactional and marketing emails
  - Files: templates, deliverability, spf-dkim-dmarc, sendgrid-ses

- [ ] **notification-patterns**
  - Used by: platform-engineer
  - Why: Multi-channel notifications
  - Files: notification-service, preferences, templating, channels-email-sms-push

---

### 24. architecture/ (System Architecture & Design)

**Purpose**: Architecture patterns, technology evaluation, capacity planning

- [ ] **c4-modeling**
  - Used by: system-architect, tech-lead, technical-writer
  - Why: C4 model diagrams for system architecture
  - Files: context-diagrams, container-diagrams, component-diagrams, code-diagrams, notation, examples

- [ ] **architecture-patterns**
  - Used by: system-architect, tech-lead
  - Why: Common architecture patterns
  - Files: microservices, event-driven, domain-driven-design, cqrs-event-sourcing, hexagonal-architecture, layered-architecture, clean-architecture

- [ ] **technology-evaluation**
  - Used by: system-architect, tech-lead
  - Why: How to evaluate and choose technologies
  - Files: evaluation-framework, decision-matrix, proof-of-concept, trade-offs, vendor-evaluation

- [ ] **capacity-planning**
  - Used by: system-architect, performance-analyst
  - Why: System capacity and scalability planning
  - Files: load-forecasting, resource-planning, scalability-patterns, performance-modeling, bottleneck-analysis

---

### 25. leadership/ (Technical Leadership)

**Purpose**: Technical debt, standards, mentoring, code review

- [ ] **technical-debt-management**
  - Used by: tech-lead, system-architect
  - Why: Tracking, prioritizing, and addressing technical debt
  - Files: debt-identification, prioritization, remediation-strategies, tracking, communication

- [ ] **engineering-standards**
  - Used by: tech-lead
  - Why: Defining and enforcing engineering standards
  - Files: coding-standards, architecture-standards, review-standards, documentation-standards, quality-gates

- [ ] **mentoring-patterns**
  - Used by: tech-lead
  - Why: How to mentor junior engineers effectively
  - Files: one-on-one-formats, code-review-feedback, pair-programming, learning-paths, career-development

- [ ] **code-review-patterns**
  - Used by: tech-lead, ALL engineers
  - Why: Effective code review practices
  - Files: review-checklist, feedback-techniques, architecture-review, security-review, performance-review

---

### 26. integrations/ (External Tool Integrations)

**Purpose**: MCP, Obsidian, Stow, Git hooks

- [ ] **mcp-server-development**
  - Used by: integration-specialist, platform-engineer
  - Why: Creating Model Context Protocol servers
  - Files: mcp-basics, server-implementation, tools-resources-prompts, testing, deployment

- [ ] **obsidian-integration**
  - Used by: integration-specialist
  - Why: Obsidian vault integration patterns
  - Files: plugins, templates, dataview-queries, daily-notes, frontmatter-integration, vaults

- [ ] **stow-patterns**
  - Used by: integration-specialist, shell-script-specialist
  - Why: GNU Stow for dotfiles management
  - Files: stow-basics, directory-structure, package-management, conflicts, best-practices

- [ ] **git-hooks**
  - Used by: integration-specialist, devops-engineer
  - Why: Pre-commit, post-commit, pre-push hooks
  - Files: hook-types, pre-commit-framework, custom-hooks, validation, ci-integration

---

### 27. cli-ux/ (Command-Line UX Design)

**Purpose**: CLI design, help docs, autocomplete, error messages

- [ ] **cli-ux-design**
  - Used by: shell-systems-ux-designer, ALL engineers building CLIs
  - Why: Command-line interface design patterns
  - Files: command-structure, flags-and-arguments, subcommands, interactive-prompts, progress-indicators, colors-and-formatting

- [ ] **help-documentation**
  - Used by: shell-systems-ux-designer, technical-writer
  - Why: Effective --help, man pages, documentation
  - Files: help-text-format, man-pages, examples, usage-patterns, documentation-hierarchy

- [ ] **autocomplete-patterns**
  - Used by: shell-systems-ux-designer
  - Why: Shell autocomplete for commands
  - Files: bash-completion, zsh-completion, fish-completion, dynamic-completion, installation

- [ ] **error-messages**
  - Used by: shell-systems-ux-designer, ALL engineers
  - Why: Effective error messages and user prompts
  - Files: error-message-format, actionable-errors, context-provision, suggestion-patterns, examples

---

### 28. foundations/ (Core Technologies & Patterns)

**Purpose**: Fundamental concepts - auth, payments, HTTP, caching, queues

**Authentication Technologies**:

- [ ] **authentication-technologies**
  - Used by: security-analyst, platform-engineer, ALL engineers
  - Why: Core authentication concepts beyond OAuth2
  - Files: session-based-auth, token-based-auth, jwt-deep-dive, cookies-vs-tokens, stateful-vs-stateless, saml, sso, ldap, multi-factor-auth

- [ ] **session-management**
  - Used by: security-analyst, product-engineer, platform-engineer
  - Why: Session handling patterns
  - Files: session-storage, session-lifecycle, distributed-sessions, redis-sessions, jwt-sessions, session-security

**Payment Technologies**:

- [ ] **payment-fundamentals**
  - Used by: product-engineer, api-engineer, security-analyst
  - Why: Core payment concepts
  - Files: payment-flows, settlement, authorization-capture, refunds-disputes, chargebacks, payment-methods, currency-handling

- [ ] **payment-security**
  - Used by: security-analyst, product-engineer
  - Why: Secure payment handling
  - Files: pci-dss-requirements, tokenization, 3d-secure, fraud-detection, payment-validation, cvv-handling

**HTTP & REST Fundamentals**:

- [ ] **http-fundamentals**
  - Used by: ALL engineers
  - Why: Core HTTP protocol knowledge
  - Files: http-methods, status-codes, headers, cookies, caching-headers, content-negotiation, compression

- [ ] **rest-architecture**
  - Used by: api-engineer, platform-engineer, product-engineer
  - Why: REST architectural principles
  - Files: resource-design, hateoas, richardson-maturity-model, rest-constraints, rest-vs-rpc, idempotency, statelessness

**Caching & Performance**:

- [ ] **caching-patterns**
  - Used by: platform-engineer, product-engineer, performance-analyst
  - Why: Caching strategies and invalidation
  - Files: cache-aside, write-through, write-behind, read-through, cache-invalidation, cdn-caching, http-caching, distributed-caching

- [ ] **cache-technologies**
  - Used by: platform-engineer
  - Why: Specific caching technologies
  - Files: redis-caching, memcached, cdn-cloudfront, browser-caching, application-caching, database-query-caching

**Message Queues & Async Processing**:

- [ ] **message-queue-patterns**
  - Used by: platform-engineer, data-engineer
  - Why: Async processing, event-driven architecture
  - Files: pub-sub, point-to-point, fan-out, work-queues, dead-letter-queues, retry-patterns, idempotency

- [ ] **queue-technologies**
  - Used by: platform-engineer, data-engineer
  - Why: Specific queue implementations
  - Files: sqs-sns, rabbitmq, kafka, redis-pub-sub, eventbridge, celery

**Database Fundamentals**:

- [ ] **database-transactions**
  - Used by: ALL engineers
  - Why: ACID properties, transaction management
  - Files: acid-properties, isolation-levels, transaction-patterns, optimistic-pessimistic-locking, distributed-transactions, two-phase-commit

- [ ] **connection-pooling**
  - Used by: platform-engineer, product-engineer
  - Why: Database connection management
  - Files: pool-sizing, connection-lifecycle, pgbouncer, connection-timeouts, connection-leaks

**Concurrency & Threading**:

- [ ] **concurrency-patterns**
  - Used by: platform-engineer, product-engineer
  - Why: Thread-safe code, async programming
  - Files: threads-vs-processes, async-await, promises-futures, locks-mutexes, race-conditions, deadlocks, actor-model

---

## Summary Statistics

**Total Categories**: 26
**Total Skills**: 145+

### Skills Created

- ✅ hipaa-compliance (2 files: README, requirements)
- ✅ pytest-patterns (2 files: README, setup)

### Breakdown by Category

1. style-guides: 8 skills
2. technical-writing: 9 skills
3. meta: 5 skills
4. bash-unix: 7 skills
5. cli-tools: 4 skills
6. compliance: 6 skills
7. testing: 8 skills
8. frameworks: 12 skills
9. api: 8 skills
10. data-engineering: 9 skills
11. databases: 8 skills
12. infrastructure: 7 skills
13. security: 20 skills
14. observability: 5 skills
15. bi: 4 skills
16. project-management: 3 skills
17. methodologies: 3 skills
18. marketing-tech: 7 skills
19. analytics: 4 skills
20. payment-processing: 4 skills
21. cms-content: 4 skills
22. communication: 4 skills
23. architecture: 4 skills
24. leadership: 4 skills
25. integrations: 4 skills
26. cli-ux: 4 skills
27. foundations: 15 skills

**Total**: 170 skills planned

---

## Next Steps

1. ✅ Review Agent List - COMPLETE
2. ✅ Identify Missing Skills - COMPLETE (145 skills identified across 26 categories)
3. **Define Phase 1 (META) Skills** - Foundation for AIDA system itself
4. **Create Implementation Roadmap** - Timeline and dependencies
5. **Begin Creation** - Start with Phase 1 META skills

---

## Phase 1: META Foundation (AIDA System Itself)

**Goal**: Create the foundational skills needed to build and maintain the AIDA system

**Timeline**: 4-6 weeks

### Phase 1 Skills (22 total)

**meta/** (5 skills) - 🔥 CRITICAL
- [ ] claude-code-setup
- [ ] agent-development
- [ ] command-development
- [ ] skill-development
- [ ] anthropic-api

**style-guides/** (8 skills) - 🔥 CRITICAL
- [ ] markdown-style-guide (agents write markdown constantly!)
- [ ] frontmatter-patterns (required for all AIDA markdown)
- [ ] yaml-style-guide
- [ ] json-patterns
- [ ] toml-config
- [ ] commit-message-conventions
- [ ] code-comment-standards
- [ ] naming-conventions

**technical-writing/** (9 skills)
- [ ] technical-writing-principles
- [ ] diagramming-patterns
- [ ] api-documentation
- [ ] readme-templates
- [ ] tutorial-writing
- [ ] runbook-templates
- [ ] adr-patterns (AIDA uses ADRs!)
- [ ] changelog-patterns
- [ ] content-organization

**Why Phase 1 is META**: These are the skills needed to create agents, commands, and skills themselves. Without these, we can't effectively build the rest of the AIDA system. They are the foundation.

---

## Phase 2: AIDA Development (Tools Used Constantly)

**Goal**: Skills for tools and technologies used daily in AIDA development

**Timeline**: 8-12 weeks (can parallelize with Phase 1 completion)

### Phase 2 Skills (75 total)

**bash-unix/** (7 skills) - 🔥 AGENTS STRUGGLE HERE
- [ ] bash-scripting
- [ ] macos-cli
- [ ] unix-utilities
- [ ] jq-patterns
- [ ] shell-debugging
- [ ] file-operations
- [ ] process-management

**cli-tools/** (4 skills) - 🔥 USED DAILY
- [ ] git-workflows
- [ ] gh-cli
- [ ] aws-cli
- [ ] docker-cli

**testing/** (8 skills) - 🔥 CONSTANT USE
- [ ] pytest-patterns ✅
- [ ] playwright-automation
- [ ] jest-testing
- [ ] k6-performance
- [ ] dbt-testing
- [ ] api-testing
- [ ] phpunit-patterns
- [ ] cypress-automation

**frameworks/** (12 skills) - 🔥 CORE DEVELOPMENT
- [ ] react-patterns
- [ ] nextjs-setup
- [ ] typescript-config
- [ ] vue-patterns
- [ ] css-frameworks
- [ ] frontend-data-visualization
- [ ] fastapi-patterns
- [ ] django-patterns
- [ ] slim-framework
- [ ] nodejs-patterns
- [ ] php-laravel

**databases/** (8 skills) - 🔥 DATA WORK
- [ ] snowsql (agents struggle!)
- [ ] snowflake-patterns
- [ ] snowflake-optimization
- [ ] postgresql-patterns
- [ ] mysql-patterns
- [ ] dynamodb-patterns
- [ ] redis-patterns
- [ ] database-design

**data-engineering/** (9 skills) - 🔥 CORE DATA WORK
- [ ] dbt-incremental-strategy
- [ ] dbt-modeling-patterns
- [ ] kimball-dimensional-modeling
- [ ] airbyte-setup
- [ ] sql-optimization
- [ ] data-quality-patterns
- [ ] pii-detection
- [ ] airflow-dags
- [ ] fivetran-setup

**infrastructure/** (6 skills) - 🔥 AWS/CDK WORK
- [ ] cdk-patterns
- [ ] github-actions-workflows
- [ ] terraform-modules
- [ ] docker-patterns
- [ ] lambda-patterns
- [ ] ecs-patterns
- [ ] rds-patterns

**observability/** (5 skills) - 🔥 MONITORING
- [ ] datadog-instrumentation
- [ ] logging-patterns
- [ ] metrics-patterns
- [ ] tracing-patterns
- [ ] alerting-strategies

**api/** (8 skills) - 🔥 API DEVELOPMENT
- [ ] api-design
- [ ] openapi-spec
- [ ] graphql-schema
- [ ] api-versioning
- [ ] webhook-patterns
- [ ] authentication-patterns
- [ ] grpc-patterns
- [ ] rate-limiting

**foundations/** (15 skills) - 🔥 FUNDAMENTAL CONCEPTS
- [ ] authentication-technologies
- [ ] session-management
- [ ] payment-fundamentals
- [ ] payment-security
- [ ] http-fundamentals
- [ ] rest-architecture
- [ ] caching-patterns
- [ ] cache-technologies
- [ ] message-queue-patterns
- [ ] queue-technologies
- [ ] database-transactions
- [ ] connection-pooling
- [ ] concurrency-patterns

**Why Phase 2 is AIDA Development**: These are the skills needed daily when building applications, data pipelines, and infrastructure with AIDA. We constantly work with these technologies.

---

## Phase 3: Domain-Specific (Everything Else)

**Goal**: Specialized skills for specific domains and use cases

**Timeline**: 12-16 weeks (lower priority, build as needed)

### Phase 3 Skills (68 total)

**compliance/** (6 skills) - Project-specific
- [ ] hipaa-compliance ✅
- [ ] gdpr-compliance
- [ ] pci-compliance
- [ ] soc2-compliance
- [ ] sox-compliance
- [ ] ccpa-compliance

**security/** (20 skills) - Comprehensive security
- [ ] encryption-patterns
- [ ] secret-management
- [ ] penetration-testing
- [ ] sql-injection-prevention
- [ ] prompt-injection-prevention 🔥 (AIDA-specific!)
- [ ] command-injection-prevention
- [ ] nosql-injection
- [ ] template-injection
- [ ] xss-prevention
- [ ] csrf-prevention
- [ ] ssrf-prevention
- [ ] cors-security
- [ ] api-security-patterns
- [ ] authentication-oauth2
- [ ] authentication-vulnerabilities
- [ ] authorization-patterns
- [ ] llm-security-patterns 🔥 (AIDA-specific!)
- [ ] data-leakage-prevention
- [ ] insecure-deserialization
- [ ] path-traversal-prevention

**bi/** (4 skills) - Business intelligence
- [ ] data-visualization 🔥 (Important for storytelling!)
- [ ] metabase-patterns
- [ ] dashboard-design
- [ ] sql-for-analytics

**marketing-tech/** (7 skills) - Marketing automation
- [ ] braze-integration
- [ ] beehiiv-patterns
- [ ] mailchimp-api
- [ ] segment-integration
- [ ] hubspot-crm
- [ ] salesforce-integration
- [ ] intercom-patterns

**analytics/** (4 skills) - Product analytics
- [ ] google-analytics
- [ ] mixpanel-integration
- [ ] amplitude-patterns
- [ ] segment-tracking

**payment-processing/** (4 skills) - E-commerce
- [ ] stripe-integration
- [ ] shopify-integration
- [ ] payment-patterns
- [ ] subscription-billing

**cms-content/** (4 skills) - Content management
- [ ] wordpress-patterns
- [ ] contentful-cms
- [ ] strapi-cms
- [ ] sanity-patterns

**communication/** (4 skills) - Team tools
- [ ] slack-integration
- [ ] discord-bots
- [ ] email-automation
- [ ] notification-patterns

**project-management/** (3 skills) - Issue tracking
- [ ] github-projects
- [ ] jira-patterns
- [ ] confluence-patterns

**methodologies/** (3 skills) - Process
- [ ] scrum-ceremonies
- [ ] kanban-patterns
- [ ] agile-estimation

**architecture/** (4 skills) - Advanced architecture
- [ ] c4-modeling
- [ ] architecture-patterns
- [ ] technology-evaluation
- [ ] capacity-planning

**leadership/** (4 skills) - Technical leadership
- [ ] technical-debt-management
- [ ] engineering-standards
- [ ] mentoring-patterns
- [ ] code-review-patterns

**integrations/** (4 skills) - Tool integrations
- [ ] mcp-server-development 🔥 (AIDA-specific!)
- [ ] obsidian-integration
- [ ] stow-patterns
- [ ] git-hooks

**cli-ux/** (4 skills) - CLI design
- [ ] cli-ux-design
- [ ] help-documentation
- [ ] autocomplete-patterns
- [ ] error-messages

**Why Phase 3 is Domain-Specific**: These skills are valuable but not used daily. They're project-specific (compliance, payments, CMS) or advanced topics (architecture, leadership) that we can build as needed.

---

## Implementation Strategy

### Parallel Development

- **Phase 1** must complete first (foundation)
- **Phase 2** can start once Phase 1 style-guides are done (agents need markdown/yaml/commit standards)
- **Phase 3** build on-demand based on project needs

### Priority Within Each Phase

1. **🔥 CRITICAL** - Build first
2. **🔥 HIGH PRIORITY** - Build second
3. Regular priority - Build third

### Skill Creation Velocity

- **Week 1-2**: 1 skill per day (learning curve)
- **Week 3+**: 2-3 skills per day (templates established)
- **Estimated**: ~60 days for all 168 skills (full-time focus)
- **Realistic**: ~120 days (part-time, with other work)

### Success Criteria

- ✅ All Phase 1 skills created (foundation complete)
- ✅ Agents can create new agents/commands/skills (meta-circular!)
- ✅ 80% of Phase 2 skills created (daily tools covered)
- ✅ Phase 3 skills built on-demand (just-in-time learning)

---

## Notes

- 🔥 = Critical/High Priority (agents struggle here OR foundation for AIDA)
- ✅ = Already created
- **Phase 1 = META**: Foundation skills for creating AIDA system itself
- **Phase 2 = CORE**: Daily development skills (frameworks, testing, databases)
- **Phase 3 = DOMAIN**: Specialized domain skills (marketing, payments, CMS)
- Many skills apply to ALL engineers (style guides, bash, git)
- technical-writer uses most documentation-related skills
- Compliance skills used across all engineering agents
