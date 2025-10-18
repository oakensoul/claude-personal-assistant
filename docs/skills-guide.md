---
title: "Skills Development Guide"
description: "How to create, organize, and use skills in AIDA"
category: "guides"
tags: ["skills", "development", "patterns"]
last_updated: "2025-10-16"
status: "published"
audience: "developers"
---

# Skills Development Guide

This guide explains how to create, organize, and use skills in the AIDA framework.

## What are Skills?

**Skills** are reusable technical knowledge that multiple agents can use. They contain specific implementation patterns, compliance requirements, framework conventions, and other technical knowledge that doesn't belong in agent definitions.

### Skills vs Agent Knowledge

| Aspect | Skills | Agent Knowledge |
|--------|--------|-----------------|
| **Purpose** | WHAT patterns to apply | HOW to be that agent |
| **Content** | Technical patterns, templates | Role definition, responsibilities |
| **Reusability** | Used by multiple agents | Used by single agent |
| **Decision-making** | No (passive knowledge) | Yes (active decision-making) |
| **Examples** | HIPAA compliance, pytest patterns | "You are a product engineer" |

### When to Create a Skill

Create a skill when:

- ✅ Multiple agents need the same technical knowledge
- ✅ Pattern is specific and actionable (not strategic)
- ✅ Knowledge is about HOW to implement something
- ✅ Content is reusable across projects (or specific to one project)

Do NOT create a skill when:

- ❌ Knowledge is about an agent's role or responsibilities
- ❌ Only one agent needs this knowledge
- ❌ Content is strategic decision-making (that's agent knowledge)
- ❌ Too broad or generic (break into smaller skills)

## Skill Directory Structure

### User-Level Skills (Generic)

Location: `~/.claude/skills/`

These are generic, reusable patterns that apply across all projects.

```text
~/.claude/skills/
├── compliance/          (Regulatory compliance)
│   ├── hipaa-compliance/
│   ├── gdpr-compliance/
│   └── pci-compliance/
├── testing/            (Testing frameworks)
│   ├── pytest-patterns/
│   ├── playwright-automation/
│   └── k6-performance/
├── frameworks/         (Frontend/backend frameworks)
│   ├── react-patterns/
│   ├── nextjs-setup/
│   ├── django-patterns/
│   └── fastapi-patterns/
├── api/               (API design)
│   ├── api-design/
│   ├── openapi-spec/
│   └── webhook-patterns/
├── data-engineering/  (Data patterns)
│   ├── dbt-incremental-strategy/
│   ├── airbyte-setup/
│   └── snowflake-optimization/
└── infrastructure/    (Infrastructure as code)
    ├── cdk-patterns/
    ├── terraform-modules/
    └── github-actions-workflows/
```

### Project-Level Skills (Specific)

Location: `{project}/.claude/skills/`

These are project or company-specific patterns that override or extend user-level skills.

```text
{project}/.claude/skills/
├── acme-ui-library/           (Company React component library)
├── acme-api-standards/        (Company API conventions)
└── warehouse-patterns/        (Project-specific dbt patterns)
```

## Creating a Skill

### Step 1: Choose Category and Name

**Category**: One of: compliance, testing, frameworks, api, data-engineering, infrastructure

**Name**: Descriptive, lowercase with hyphens

- ✅ `pytest-patterns`
- ✅ `hipaa-compliance`
- ✅ `dbt-incremental-strategy`
- ❌ `testing` (too broad)
- ❌ `HIPAA` (wrong case)
- ❌ `pytest_patterns` (use hyphens, not underscores)

### Step 2: Create Directory Structure

```bash
# User-level skill
mkdir -p ~/.claude/skills/category/skill-name

# Project-level skill
mkdir -p .claude/skills/skill-name
```

### Step 3: Create README.md

Every skill MUST have a README.md with frontmatter:

```markdown
---
title: "Skill Name"
description: "Brief description of what this skill provides"
category: "compliance|testing|frameworks|api|data-engineering|infrastructure"
used_by: ["agent1", "agent2"]
tags: ["tag1", "tag2"]
last_updated: "YYYY-MM-DD"
---

# Skill Name

## Overview
1-2 paragraph description of what this skill provides and why it exists.

## When to Use
List specific scenarios when this skill should be used:
- Scenario 1
- Scenario 2
- Scenario 3

## Used By
List which agents use this skill and for what purpose:
- **agent-name**: Purpose and context for using this skill
- **agent-name**: Different purpose

## Contents
List and describe all files in this skill:
- [File 1](file1.md) - Description of what's in this file
- [File 2](file2.md) - Description of what's in this file

## Related Skills
Link to related skills:
- [Other Skill](../other-skill/) - How they relate
- [Another Skill](../another-skill/) - How they relate

## Examples
Provide practical examples of using this skill in context.

## References
- External documentation
- Standards or specifications
- Related resources
```

### Step 4: Create Content Files

Create focused markdown files for each aspect of the skill:

```text
skill-name/
├── README.md              (Overview, index)
├── getting-started.md     (Quick start guide)
├── patterns.md            (Common patterns)
├── best-practices.md      (Recommendations)
├── examples.md            (Code examples)
├── troubleshooting.md     (Common issues)
└── reference.md           (Complete reference)
```

Keep files focused:

- ✅ Each file covers one topic
- ✅ Files are 200-500 lines max
- ✅ Use clear headings and examples
- ❌ Don't create monolithic files
- ❌ Don't duplicate content across files

### Step 5: Update Agent Instructions

Update agents that should use this skill:

```markdown
# Agent Instructions

## Skills You Use

- skill-name: Description of when/how you use this skill
```

## Skill Categories

### compliance/

**Purpose**: Regulatory compliance requirements and patterns

**Examples**:

- `hipaa-compliance`: Healthcare data compliance
- `gdpr-compliance`: EU data privacy
- `pci-compliance`: Payment card industry standards

**Used by**: governance-analyst, compliance-analyst, all engineers

**Content**: Requirements, handling procedures, audit requirements

### testing/

**Purpose**: Testing framework patterns and configurations

**Examples**:

- `pytest-patterns`: Python testing with pytest
- `playwright-automation`: E2E browser testing
- `k6-performance`: Load and performance testing

**Used by**: quality-analyst (for recommendations), all engineers (for implementation)

**Content**: Setup, patterns, fixtures, mocking, CI integration

### frameworks/

**Purpose**: Frontend and backend framework patterns

**Examples**:

- `react-patterns`: React component patterns
- `nextjs-setup`: Next.js configuration and patterns
- `django-patterns`: Django application patterns
- `fastapi-patterns`: FastAPI async patterns

**Used by**: product-engineer, platform-engineer

**Content**: Setup, conventions, best practices, performance

### api/

**Purpose**: API design and implementation patterns

**Examples**:

- `api-design`: REST/GraphQL design conventions
- `openapi-spec`: OpenAPI specification patterns
- `webhook-patterns`: Webhook implementation

**Used by**: api-engineer, platform-engineer, product-engineer

**Content**: Design patterns, documentation, versioning, error handling

### data-engineering/

**Purpose**: Data pipeline and transformation patterns

**Examples**:

- `dbt-incremental-strategy`: dbt incremental model patterns
- `airbyte-setup`: Airbyte connector configuration
- `snowflake-optimization`: Snowflake performance tuning

**Used by**: data-engineer, sql-expert

**Content**: Strategies, configurations, optimization, testing

### infrastructure/

**Purpose**: Infrastructure as code patterns

**Examples**:

- `cdk-patterns`: AWS CDK construct patterns
- `terraform-modules`: Terraform module patterns
- `github-actions-workflows`: CI/CD workflow templates

**Used by**: aws-cloud-engineer, devops-engineer, platform-engineer

**Content**: Templates, patterns, best practices, examples

## Using Skills in Agents

### Explicit Reference in Agent Instructions

```markdown
# product-engineer

You are a full-stack engineer building user-facing features.

## Skills You Use

- **react-patterns**: When building React components
- **api-design**: When creating API endpoints
- **pytest-patterns**: When writing tests
- **hipaa-compliance**: When handling healthcare data (if applicable)

When implementing features, consult relevant skills for patterns and best practices.
```

### On-Demand Loading

Agents can reference skills in their responses:

```markdown
When building a React component, refer to the react-patterns skill for:
- Component composition patterns
- Hook usage guidelines
- State management strategies
```

### Project Override Pattern

When both user-level and project-level skills exist with the same purpose:

```text
User skill: ~/.claude/skills/frameworks/react-patterns/
Project skill: {project}/.claude/skills/acme-ui-library/

Agent behavior:
1. Check for project-level skill first
2. Use project skill if it exists (company-specific patterns)
3. Fall back to user skill for generic knowledge
4. Can reference both if needed
```

## Promoting and Demoting Skills

### Project → User (Promote)

When a project-specific skill becomes generally useful:

```bash
# 1. Copy to user-level skills
cp -r {project}/.claude/skills/good-pattern \
     ~/.claude/skills/category/pattern-name

# 2. Generalize content (remove project-specific details)
# Edit files to be project-agnostic

# 3. Update README frontmatter
# Remove project-specific tags, update description

# 4. Optionally keep project version as override
# Project version can extend user version with specifics
```

### User → Project (Specialize)

When you need to customize a generic skill for a project:

```bash
# 1. Copy to project skills
cp -r ~/.claude/skills/category/pattern \
     {project}/.claude/skills/custom-pattern

# 2. Customize for project
# Add company standards, project conventions

# 3. Update README
# Document how this differs from user-level version
```

## Examples

### Example 1: Creating pytest-patterns Skill

**Directory**: `~/.claude/skills/testing/pytest-patterns/`

**Files**:

```text
pytest-patterns/
├── README.md              (Overview, when to use)
├── setup.md               (pytest installation and configuration)
├── fixtures.md            (Fixture patterns and best practices)
├── mocking.md             (Mock/stub/patch patterns)
├── parametrize.md         (Parametrized test patterns)
├── coverage.md            (Coverage configuration and analysis)
└── ci-integration.md      (Running in CI/CD)
```

**README.md** (excerpt):

```markdown
---
title: "pytest Patterns"
description: "pytest testing framework patterns and best practices"
category: "testing"
used_by: ["quality-analyst", "product-engineer", "platform-engineer", "data-engineer"]
tags: ["python", "testing", "pytest"]
last_updated: "2025-10-16"
---

# pytest Patterns

## Overview
This skill provides pytest testing patterns, configuration, and best practices
for Python projects.

## When to Use
- Setting up pytest in a Python project
- Writing unit tests for Python code
- Creating test fixtures
- Mocking dependencies
- Configuring test coverage

## Used By
- **quality-analyst**: Recommends test structure and patterns
- **product-engineer**: Implements tests for product features
- **platform-engineer**: Tests platform services
- **data-engineer**: Tests data pipelines and transformations
```

### Example 2: Creating hipaa-compliance Skill

**Directory**: `~/.claude/skills/compliance/hipaa-compliance/`

**Files**:

```text
hipaa-compliance/
├── README.md                (Overview)
├── requirements.md          (HIPAA requirements summary)
├── patient-data-handling.md (PHI handling procedures)
├── audit-logging.md         (Audit trail requirements)
├── encryption.md            (Encryption standards)
├── access-control.md        (Access control requirements)
└── breach-notification.md   (Breach response procedures)
```

**Used by**:

- `governance-analyst`: Audits HIPAA compliance
- `product-engineer`: Implements HIPAA-compliant features
- `data-engineer`: Handles PHI in pipelines
- `platform-engineer`: Builds HIPAA-compliant services

### Example 3: Project-Specific UI Library Skill

**Directory**: `{project}/.claude/skills/acme-ui-library/`

**Files**:

```text
acme-ui-library/
├── README.md           (Overview of Acme UI library)
├── components.md       (Available components)
├── theming.md          (Acme theme system)
├── patterns.md         (Acme-specific patterns)
└── migration.md        (Migrating from generic React)
```

**Relationship to User Skills**:

- Extends `~/.claude/skills/frameworks/react-patterns/`
- Provides Acme-specific component implementations
- Overrides generic React patterns with company standards

## Best Practices

### Content Organization

**DO**:

- ✅ One skill per technology or pattern
- ✅ Break large skills into multiple focused files
- ✅ Use clear headings and examples
- ✅ Include code snippets and practical examples
- ✅ Reference official documentation
- ✅ Update last_updated date when changing

**DON'T**:

- ❌ Create monolithic skills covering too much
- ❌ Duplicate content across multiple skills
- ❌ Include agent role definition in skills
- ❌ Make skills too generic or too specific
- ❌ Forget to update README when adding files

### Naming Conventions

**DO**:

- ✅ Use lowercase with hyphens: `pytest-patterns`
- ✅ Be descriptive: `dbt-incremental-strategy` not `dbt-patterns`
- ✅ Use singular for frameworks: `react-patterns` not `react-pattern`
- ✅ Use category prefixes when needed: `api-design`, `api-versioning`

**DON'T**:

- ❌ Use underscores: `pytest_patterns`
- ❌ Use camelCase: `pytestPatterns`
- ❌ Be too generic: `testing`, `python`
- ❌ Include version numbers: `pytest-7-patterns` (keep current)

### Documentation Quality

**DO**:

- ✅ Include frontmatter in README
- ✅ List all agents that use the skill
- ✅ Provide concrete examples
- ✅ Explain WHY not just WHAT
- ✅ Link to official docs
- ✅ Include troubleshooting section

**DON'T**:

- ❌ Copy-paste official docs (link instead)
- ❌ Provide only theory without examples
- ❌ Assume prior knowledge
- ❌ Forget to explain when to use
- ❌ Leave content outdated

## Skill Development Workflow

### 1. Identify Need

- Multiple agents need same knowledge
- Knowledge is technical and specific
- Pattern is reusable

### 2. Plan Structure

- Choose category
- Name the skill
- List content files needed
- Identify which agents will use it

### 3. Create Skeleton

```bash
# Create directory
mkdir -p ~/.claude/skills/category/skill-name

# Create README
cat > ~/.claude/skills/category/skill-name/README.md << 'EOF'
---
title: "Skill Name"
description: ""
category: "category"
used_by: []
tags: []
last_updated: "2025-10-16"
---

# Skill Name

## Overview

## When to Use

## Used By

## Contents

## Examples
EOF
```

### 4. Write Content

- Fill in README
- Create content files
- Add examples
- Test with agents

### 5. Update Agents

- Add skill reference to agent instructions
- Remove duplicated knowledge from agents
- Test agent can use skill successfully

### 6. Document

- Update this guide if needed
- Add examples
- Create migration notes

## Troubleshooting

### Skill Not Loading

**Problem**: Agent can't find skill

**Solutions**:

- Check skill directory name matches reference
- Verify README.md exists
- Check file permissions
- Ensure category directory exists

### Duplicate Skills

**Problem**: Same knowledge in multiple skills

**Solutions**:

- Merge skills into one comprehensive skill
- Use one skill and reference it from others
- Split into more focused skills

### Skill Too Broad

**Problem**: Skill covers too many topics

**Solutions**:

- Break into multiple focused skills
- Create category with multiple related skills
- Use clear file organization within skill

### Agent Not Using Skill

**Problem**: Agent doesn't reference skill when it should

**Solutions**:

- Add explicit skill reference in agent instructions
- Provide examples of when to use skill
- Check skill name matches agent reference

## References

- [ADR-009: Skills System Architecture](./architecture/decisions/adr-009-skills-system-architecture.md)
- [ADR-002: Two-Tier Agent Architecture](./architecture/decisions/adr-002-two-tier-agent-architecture.md)
- [Agent Interaction Patterns](./architecture/agent-interaction-patterns.md)
