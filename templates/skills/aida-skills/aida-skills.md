---
name: aida-skills
version: 1.0.0
category: meta
description: Comprehensive knowledge about AIDA skill architecture, structure, creation, and management
tags: [skills, meta-knowledge, architecture, two-tier, discovery]
used_by: [claude-agent-manager, aida]
last_updated: "2025-10-20"
---

# AIDA Skills Meta-Skill

This skill provides comprehensive knowledge about AIDA's skill architecture, enabling intelligent assistance with skill creation, validation, discovery, and management.

## Purpose

This meta-skill enables the AIDA system (via `claude-agent-manager`) to:

- **Understand** the complete skill architecture and patterns
- **Create** new skills following established conventions
- **Validate** skill structure and frontmatter
- **List** all available skills (via `list-skills.sh`)
- **Update** existing skills while maintaining consistency
- **Advise** on best practices for skill organization
- **Assign** skills to agents appropriately

## Skill Architecture Overview

### What is an AIDA Skill?

An AIDA skill is **specialized knowledge or capability** that agents can use to perform tasks. Skills provide:

- Domain-specific knowledge and procedures
- Reusable patterns and templates
- Step-by-step guidance for complex tasks
- Integration with CLI tools and scripts
- Composable expertise (agents can use multiple skills)

### Skills vs. Agents

**Key Differences**:

| Aspect | Agents | Skills |
|--------|--------|--------|
| **What** | AI personas with reasoning | Knowledge modules |
| **Purpose** | Problem-solving, decision-making | Specific capabilities/knowledge |
| **Usage** | Invoked by user or system | Loaded by agents |
| **Cardinality** | One agent active at a time | Agents can use multiple skills |
| **Autonomy** | Can reason and adapt | Static knowledge reference |

**Relationship**: Agents **use** skills. Skills **empower** agents.

**Example**:

- **Agent**: `aws-cloud-engineer` (reasoning entity)
- **Skills**: `cdk-patterns`, `cost-optimization`, `service-selection` (knowledge modules)

### Two-Tier Architecture

AIDA uses a **two-tier discovery pattern** (defined in ADR-002):

1. **User-Level** (`~/.claude/skills/`): Generic, reusable skills for all projects
2. **Project-Level** (`./.claude/skills/` or `./.claude/skills-global/`): Project-specific overrides and custom skills

**Discovery Order**:

1. Check project-level first (`./.claude/skills-global/`)
2. Fall back to user-level (`~/.claude/skills/`)
3. Merge knowledge from both if skill exists at both levels

## File Structure

### Directory Layout

```text
User-Level Skills:
~/.claude/skills/
├── aws-service-selection/
│   ├── aws-service-selection.md    # Skill definition
│   └── knowledge/                   # Optional supporting knowledge
│       ├── decision-trees/
│       └── comparison-matrices/
├── cdk-patterns/
│   └── cdk-patterns.md
└── sql-optimization/
    ├── sql-optimization.md
    └── knowledge/
        ├── query-patterns/
        └── index-strategies/

Project-Level Skills:
./.claude/skills-global/
├── myapp-deployment/
│   └── index.md                    # Project-specific deployment knowledge
└── company-compliance/
    └── index.md                    # Company-specific compliance rules
```

### File Naming Convention

- **User-level**: `{skill-name}/{skill-name}.md`
- **Project-level**: `{skill-name}/index.md`

**Why different naming?**:

- User-level uses `{name}.md` for clarity and IDE indexing
- Project-level uses `index.md` to allow future expansion (README, examples, etc.)

## Frontmatter Schema

### Required Fields

```yaml
---
name: skill-name                # Lowercase, hyphen-separated
version: 1.0.0                  # Semantic versioning
description: Brief one-line description of skill
category: domain                # Skill category
---
```

### Optional Fields

```yaml
---
# Optional metadata
tags: [tag1, tag2, tag3]        # Searchable tags
scope: user|project|global      # Where skill should be available

# Skill relationships
used_by: [agent1, agent2]       # Agents that use this skill
depends_on: [skill1, skill2]    # Skills this one depends on
related_skills: [skill3]        # Related but independent skills

# Integration
cli_script: script-name.sh      # Associated CLI script (if any)
external_tools: [tool1, tool2]  # External tools used

# Documentation
author: "Author Name"           # Skill creator
created: "2025-10-20"           # Creation date
last_updated: "2025-10-20"      # Last modification
---
```

### Frontmatter Examples

**Minimal Skill**:

```yaml
---
name: markdown-formatting
version: 1.0.0
description: Markdown syntax, linting rules, and formatting best practices
category: documentation
---
```

**Full-Featured Skill**:

```yaml
---
name: aws-service-selection
version: 2.1.0
description: Decision framework for selecting appropriate AWS services
category: cloud-architecture
tags: [aws, architecture, service-selection, decision-framework]
scope: user
used_by: [aws-cloud-engineer, tech-lead, solution-architect]
depends_on: [aws-fundamentals, cost-optimization]
related_skills: [cdk-patterns, terraform-patterns]
author: "Cloud Architecture Team"
created: "2025-01-15"
last_updated: "2025-10-20"
---
```

## Skill Categories

Common skill categories (not exhaustive, can create custom):

### Technical Skills

- **cloud-architecture**: AWS, Azure, GCP service patterns
- **infrastructure-as-code**: CDK, Terraform, CloudFormation
- **data-engineering**: ETL, pipelines, warehouse design
- **backend-development**: API design, microservices, databases
- **frontend-development**: UI frameworks, state management
- **devops**: CI/CD, deployment, monitoring
- **security**: Threat modeling, compliance, encryption

### Process Skills

- **requirements-analysis**: User stories, acceptance criteria
- **testing**: Test strategies, frameworks, patterns
- **code-review**: Review checklists, quality standards
- **documentation**: Technical writing, API docs
- **project-management**: Planning, estimation, tracking

### Domain Skills

- **finance**: Financial modeling, reporting, compliance
- **healthcare**: HIPAA, medical workflows, privacy
- **compliance**: Regulatory frameworks, audit procedures
- **analytics**: Metrics, dashboards, BI

### Meta Skills

- **aida-agents**: Knowledge about AIDA agents (like this skill, but for agents)
- **aida-commands**: Knowledge about AIDA commands
- **aida-skills**: Knowledge about AIDA skills (this skill!)
- **system-administration**: AIDA system management

## Creating a New Skill

### Step 1: Plan the Skill

**Questions to answer**:

1. What specific capability or knowledge does this skill provide?
2. Which agents would benefit from this skill?
3. What is the scope? (user-level generic or project-specific)
4. Does this skill depend on other skills?
5. Is there an associated CLI script?

### Step 2: Create Directory Structure

**For user-level skill** (generic, reusable):

```bash
mkdir -p ~/.claude/skills/{skill-name}/knowledge
```

**For project-level skill** (project-specific):

```bash
mkdir -p ./.claude/skills-global/{skill-name}
```

### Step 3: Create Skill Definition File

**User-level** (`~/.claude/skills/{skill-name}/{skill-name}.md`):

```markdown
---
name: {skill-name}
version: 1.0.0
description: {one-line description}
category: {category}
tags: [{relevant-tags}]
used_by: [{agents-that-use-this}]
---

# {Skill Name}

## Overview

{Brief explanation of what this skill provides}

## Purpose

{Why this skill exists and what problems it solves}

## Key Concepts

### Concept 1

{Explain foundational concepts}

### Concept 2

{Explain additional concepts}

## Procedures

### Procedure 1: {Task Name}

**When to use**: {Scenario description}

**Steps**:

1. {Step 1}
2. {Step 2}
3. {Step 3}

**Expected outcome**: {What success looks like}

### Procedure 2: {Task Name}

{Additional procedures...}

## Patterns

### Pattern 1: {Pattern Name}

**Problem**: {What problem does this pattern solve?}

**Solution**: {How does the pattern address it?}

**Example**:

```{language}
{Code or configuration example}
```

**When to use**: {Guidance on applicability}

**Trade-offs**: {Pros and cons}

## Decision Frameworks

### Decision 1: {Decision Name}

**Question**: {What needs to be decided?}

**Factors to consider**:

- Factor 1: {Explanation}
- Factor 2: {Explanation}

**Decision tree**:

```text
If {condition A}:
  → Choose {option 1}
Else if {condition B}:
  → Choose {option 2}
Else:
  → Choose {option 3}
```

## Integration

### CLI Tools

**Associated script**: `{script-name}.sh` (if applicable)

**Usage**:

```bash
{script-name}.sh [options]
```

**Parameters**:

- `--param1`: {Description}
- `--param2`: {Description}

### External Dependencies

**Required tools**:

- {Tool 1}: {Purpose}
- {Tool 2}: {Purpose}

**Installation**:

```bash
{Installation commands}
```

## Best Practices

### ✅ Do

- {Best practice 1}
- {Best practice 2}
- {Best practice 3}

### ❌ Don't

- {Anti-pattern 1}
- {Anti-pattern 2}
- {Anti-pattern 3}

## Examples

### Example 1: {Scenario}

**Context**: {Situation description}

**Approach**:

{Step-by-step walkthrough}

**Result**:

{Outcome and learnings}

### Example 2: {Scenario}

{Additional examples...}

## Troubleshooting

### Issue 1: {Problem}

**Symptoms**: {How to recognize this issue}

**Cause**: {Why this happens}

**Solution**: {How to fix it}

### Issue 2: {Problem}

{Additional troubleshooting...}

## References

- [Resource 1](URL)
- [Resource 2](URL)
- Related skills: {skill-name}, {skill-name}
- Used by agents: {agent-name}, {agent-name}

## Changelog

### Version 1.0.0 (2025-10-20)

- Initial release
- {Key capabilities}

```markdown

**Project-level** (`./.claude/skills-global/{skill-name}/index.md`):

```markdown
---
name: {skill-name}
version: 1.0.0
description: {project-specific description}
category: {category}
scope: project
extends: {user-level-skill}  # Optional: extends user-level skill
---

# {Skill Name} - Project Configuration

## Project Context

{Explain project-specific context and why this skill is needed}

## Project-Specific Knowledge

### {Project Aspect 1}

{Detailed project-specific information}

### {Project Aspect 2}

{Additional project-specific knowledge}

## Overrides

{Any modifications to base skill behavior, if extending user-level skill}

## Integration

### Project Tools

{Project-specific tools, scripts, or systems}

### Project Standards

{Company or project conventions that apply}

## Examples

### Example: {Project Scenario}

{Project-specific example}
```

### Step 4: Add Knowledge Base (Optional)

Organize supporting knowledge in subdirectories:

```bash
mkdir -p ~/.claude/skills/{skill-name}/knowledge/{subdomain}
```

**Knowledge organization patterns**:

- `patterns/` - Reusable patterns and templates
- `frameworks/` - Decision frameworks and methodologies
- `references/` - Reference documentation and cheat sheets
- `examples/` - Example code, configurations, architectures
- `troubleshooting/` - Common issues and solutions
- `checklists/` - Validation and review checklists

### Step 5: Validate Skill

**Validation checklist**:

- [ ] Frontmatter contains all required fields
- [ ] Name is lowercase, hyphen-separated
- [ ] Version follows semantic versioning (X.Y.Z)
- [ ] Description is clear and concise
- [ ] Category is appropriate
- [ ] File structure follows conventions
- [ ] Markdown linting passes
- [ ] Skill is discoverable by `list-skills.sh`
- [ ] If CLI script referenced, script exists
- [ ] No hardcoded secrets or credentials

## Updating an Existing Skill

### When to Update

- Adding new procedures or patterns
- Refining existing knowledge
- Fixing errors or outdated information
- Responding to user feedback
- New tools or techniques emerge
- Project requirements change

### Update Process

1. **Increment version**:
   - Patch (X.Y.Z+1): Bug fixes, clarifications, minor additions
   - Minor (X.Y+1.0): New procedures/patterns, backward-compatible
   - Major (X+1.0.0): Breaking changes, major restructuring

2. **Update `last_updated` field**

3. **Document changes** in Changelog section

4. **Test changes** by having agent use updated skill

5. **Notify dependent agents** if breaking changes

### Backward Compatibility

**User-level skills**: Maintain backward compatibility when possible

**Project-level skills**: Can break compatibility if project-specific

## Validation Requirements

### Frontmatter Validation

**Required field checks**:

```bash
# Check for required fields
- name: ^[a-z][a-z0-9-]*$  # Lowercase, hyphen-separated
- version: ^\d+\.\d+\.\d+$  # Semantic versioning
- description: .{10,200}    # 10-200 characters
- category: ^[a-z-]+$       # Lowercase category
```

**Validation errors to catch**:

- Missing required fields
- Invalid name format (uppercase, spaces, special chars)
- Invalid version format (not semantic versioning)
- Empty or too-short description
- Unknown category

### Structural Validation

**Directory structure checks**:

- Skill directory exists
- Definition file exists (`.md` for user, `index.md` for project)
- No conflicting files (both user and project with same name)
- Knowledge base organized (if present)
- CLI script exists (if referenced)

### Content Validation

**Skill content checks**:

- Markdown linting passes
- Frontmatter is valid YAML
- Skill purpose is clearly documented
- Procedures have clear steps
- Examples are provided
- No hardcoded secrets or credentials
- External links are valid (when possible)

## Integration with list-skills.sh

### How Discovery Works

The `list-skills.sh` CLI script:

1. **Scans user-level**: `~/.claude/skills/*/` for `{skill-name}.md` files
2. **Scans project-level**: `./.claude/skills-global/*/` for `index.md` files
3. **Parses frontmatter**: Extracts name, version, description, category
4. **Groups by category**: Primary organization by category
5. **Deduplicates**: Uses `realpath` to detect symlinks (dev mode)
6. **Formats output**:
   - Plain text table with category grouping (default)
   - JSON format (`--format json`)
7. **Separates sections**: Global vs. Project skills clearly distinguished

### What Gets Listed

**Per skill, the script shows**:

- Name
- Version
- Category
- Description
- Location (sanitized path: `${CLAUDE_CONFIG_DIR}` or `${PROJECT_ROOT}`)
- Used by (which agents use this skill)

### Category-First Display

Skills are organized by category for easier discovery:

```text
Global Skills (User-Level)
──────────────────────────────────────────────────

Cloud Architecture
  aws-service-selection   2.1.0   Decision framework for AWS services
  cdk-patterns            1.5.0   CDK implementation patterns

Data Engineering
  sql-optimization        1.3.0   SQL query optimization techniques
  dbt-patterns            2.0.0   dbt modeling best practices

Documentation
  markdown-formatting     1.0.0   Markdown syntax and linting

Project Skills
──────────────────────────────────────────────────

Deployment
  myapp-deployment        1.0.0   MyApp deployment procedures
```

### Symlink Handling

**Dev mode creates symlinks**:

- `~/.claude/skills/` → symlinks to `~/.aida/templates/skills/`
- `list-skills.sh` uses `realpath` to deduplicate
- Only shows canonical path, marks if symlinked

## Best Practices

### Naming Conventions

**✅ Good skill names**:

- `aws-service-selection` (clear, specific)
- `cdk-patterns` (focused domain)
- `sql-optimization` (clear purpose)
- `api-design-principles` (descriptive)

**❌ Bad skill names**:

- `AWS` (too broad, uppercase)
- `my_skill` (underscores, non-descriptive)
- `skill-1` (generic, non-descriptive)
- `advanced-techniques` (vague)

### Description Guidelines

**✅ Good descriptions**:

- "Decision framework for selecting appropriate AWS services"
- "SQL query optimization techniques and index strategies"
- "CDK implementation patterns for multi-stack architectures"

**❌ Bad descriptions**:

- "AWS stuff" (too vague)
- "Everything you need to know about..." (too broad)
- "Skill for doing things" (no specificity)

### Scope Guidelines

**User-level skills** (in `~/.claude/skills/`):

- Generic, reusable across projects
- No project-specific context
- Broadly applicable knowledge
- Examples: `sql-optimization`, `api-design`, `security-patterns`

**Project-level skills** (in `./.claude/skills-global/`):

- Project-specific procedures
- Company-specific standards
- Custom workflows
- Examples: `myapp-deployment`, `company-compliance`, `internal-api-standards`

### Knowledge Organization

**Keep skills focused**:

- One domain per skill
- Clear scope and boundaries
- Avoid overlap with other skills
- Compose multiple skills instead of one mega-skill

**Knowledge base example**:

```text
~/.claude/skills/aws-service-selection/knowledge/
├── decision-trees/
│   ├── compute-selection.md
│   ├── database-selection.md
│   └── storage-selection.md
├── comparison-matrices/
│   ├── lambda-vs-fargate.md
│   └── rds-vs-aurora.md
└── cost-analysis/
    └── service-pricing-guide.md
```

## Common Patterns

### Pattern 1: Procedural Skill

**Purpose**: Step-by-step procedures for specific tasks

**Structure**:

- Clear procedures with numbered steps
- Expected outcomes defined
- Troubleshooting guidance
- Examples: `deployment-procedures`, `incident-response`

### Pattern 2: Decision Framework Skill

**Purpose**: Guidance for making complex decisions

**Structure**:

- Decision criteria clearly defined
- Decision trees or flowcharts
- Trade-off analysis
- Examples: `service-selection`, `architecture-decisions`

### Pattern 3: Pattern Library Skill

**Purpose**: Collection of reusable patterns

**Structure**:

- Pattern catalog
- When to use each pattern
- Code/config examples
- Examples: `cdk-patterns`, `sql-patterns`, `api-patterns`

### Pattern 4: Reference Skill

**Purpose**: Quick reference and cheat sheets

**Structure**:

- Concise reference material
- Lookup tables
- Command references
- Examples: `git-commands`, `bash-scripting`, `regex-patterns`

### Pattern 5: Integration Skill

**Purpose**: Integration with external tools/systems

**Structure**:

- Tool setup and configuration
- Integration procedures
- CLI script coordination
- Examples: `github-workflows`, `datadog-monitoring`

## Skill Assignment to Agents

### How Agents Use Skills

Agents declare skills in their frontmatter:

```yaml
---
name: aws-cloud-engineer
skills: [aws-service-selection, cdk-patterns, cost-optimization]
---
```

### Guidelines for Assignment

**Assign skills to agents when**:

- Agent frequently needs this knowledge
- Skill aligns with agent's domain
- Agent should have this expertise by default

**Don't assign skills when**:

- Skill is only occasionally needed (load on-demand)
- Skill is too specialized
- Creates circular dependencies

### Skill Loading Strategies

**Pre-loaded** (in agent frontmatter):

- Core skills agent always needs
- Frequently used knowledge
- Agent's primary expertise

**On-demand** (loaded during conversation):

- Specialized skills for specific tasks
- Large knowledge bases
- Rarely used capabilities

## Troubleshooting

### Skill Not Discovered

**Symptoms**: Skill doesn't appear in `list-skills.sh` output

**Checks**:

1. File named correctly? (`{skill-name}.md` or `index.md`)
2. In correct directory? (`~/.claude/skills/` or `./.claude/skills-global/`)
3. Frontmatter valid YAML?
4. Required fields present?

**Fix**: Verify file location and frontmatter structure

### Agent Can't Use Skill

**Symptoms**: Agent doesn't have access to skill knowledge

**Checks**:

1. Skill assigned in agent's frontmatter?
2. Skill file exists and is readable?
3. Skill name matches exactly (case-sensitive)?
4. Skill loaded successfully (check logs)?

**Fix**: Verify agent configuration and skill availability

### Symlink Confusion

**Symptoms**: Skill appears twice in dev mode

**Checks**:

1. Running in dev mode?
2. Symlinks created correctly?
3. `list-skills.sh` using `realpath`?

**Fix**: Use `realpath` for deduplication, verify symlink targets

### CLI Script Not Found

**Symptoms**: Skill references script that doesn't exist

**Checks**:

1. Script path correct in frontmatter?
2. Script installed in `~/.claude/scripts/`?
3. Script has execute permissions?

**Fix**: Install script or update frontmatter reference

## Examples

### Example 1: Creating a Procedural Skill

```bash
# Create directory
mkdir -p ~/.claude/skills/git-workflow

# Create skill file
cat > ~/.claude/skills/git-workflow/git-workflow.md << 'EOF'
---
name: git-workflow
version: 1.0.0
description: Git branching, commit conventions, and pull request workflows
category: development
tags: [git, workflow, version-control]
used_by: [devops-engineer, tech-lead]
---

# Git Workflow Skill

## Overview

Standard Git workflow procedures for feature development, code review,
and deployment.

## Purpose

Ensures consistent Git practices across all projects and team members.

## Procedures

### Procedure 1: Feature Branch Workflow

**When to use**: Starting work on a new feature or bug fix

**Steps**:

1. Update main branch: `git checkout main && git pull`
2. Create feature branch: `git checkout -b feature/short-description`
3. Make changes and commit frequently
4. Push branch: `git push -u origin feature/short-description`
5. Create pull request when ready

**Expected outcome**: Clean feature branch ready for review

### Procedure 2: Commit Message Format

**When to use**: Every commit

**Format**:

```text
type(scope): brief description

Longer explanation if needed

- Bullet points for details
- Multiple points as needed
```

**Types**: feat, fix, docs, refactor, test, chore

**Expected outcome**: Clear, searchable commit history

## Best Practices

### ✅ Do

- Commit frequently with clear messages
- Keep branches short-lived (< 3 days)
- Rebase before merging to keep history clean
- Squash fixup commits before merging

### ❌ Don't

- Force push to main/master
- Commit secrets or credentials
- Use generic commit messages ("update", "fix")
- Work on main branch directly

## References

- [Conventional Commits](https://www.conventionalcommits.org/)
- Used by agents: devops-engineer, tech-lead
EOF

```bash

### Example 2: Creating a Decision Framework Skill

```bash
# Create directory
mkdir -p ~/.claude/skills/database-selection/knowledge/decision-trees

# Create skill file
cat > ~/.claude/skills/database-selection/database-selection.md << 'EOF'
---
name: database-selection
version: 1.0.0
description: Framework for selecting appropriate database technology
category: data-architecture
tags: [database, architecture, decision-framework]
used_by: [data-engineer, tech-lead, aws-cloud-engineer]
depends_on: [data-modeling-fundamentals]
---

# Database Selection Skill

## Overview

Decision framework for choosing the right database technology based on
use case, scale, and requirements.

## Purpose

Helps architects and engineers make informed database technology decisions
by evaluating key factors and trade-offs.

## Decision Frameworks

### Decision 1: SQL vs. NoSQL

**Question**: Should we use a relational or non-relational database?

**Factors to consider**:

- **Data structure**: Structured/relational vs. flexible schema
- **Transactions**: ACID requirements vs. eventual consistency
- **Queries**: Complex joins vs. key-value lookups
- **Scale**: Vertical scaling vs. horizontal scaling

**Decision tree**:

```text
Does data have complex relationships and require strict consistency?
  YES → Evaluate SQL options (PostgreSQL, MySQL, Aurora)
  NO  → Continue to NoSQL decision tree

Is data primarily key-value or document-based?
  YES → Evaluate DynamoDB, DocumentDB
  NO  → Consider time-series (Timestream) or graph (Neptune)
```

### Decision 2: Managed vs. Self-Managed

**Question**: Should we use a managed database service or self-manage?

**Factors**:

- **Operational overhead**: Team capacity for DB administration
- **Cost**: Managed service premium vs. operational cost
- **Customization**: Standard config vs. specific requirements
- **Compliance**: Data residency, audit requirements

**Recommendation**:

- **Managed** (RDS, Aurora, DynamoDB): 90% of use cases
- **Self-managed** (EC2 + database): Only when managed doesn't support requirements

## Comparison Matrices

See `knowledge/comparison-matrices/` for detailed comparisons:

- PostgreSQL vs. MySQL
- DynamoDB vs. DocumentDB
- Aurora vs. RDS
- Timestream vs. DynamoDB for time-series

## Best Practices

### ✅ Do

- Start with managed services (RDS, DynamoDB)
- Prototype with representative data
- Load test before production
- Consider future scale (3-5 years)

### ❌ Don't

- Choose database based on hype
- Underestimate operational complexity
- Ignore cost at scale
- Skip proof-of-concept for critical workloads

## References

- AWS Database Decision Guide
- Used by agents: data-engineer, tech-lead, aws-cloud-engineer
- Depends on: data-modeling-fundamentals
EOF

```bash

### Example 3: Listing All Skills

```bash
# Plain text output (category-grouped)
~/.claude/scripts/.aida/list-skills.sh

# JSON output
~/.claude/scripts/.aida/list-skills.sh --format json

# Example output (plain text):
# Global Skills (User-Level)
# ──────────────────────────────────────────────────
#
# Cloud Architecture
#   aws-service-selection   2.1.0   AWS service decision framework
#   cdk-patterns            1.5.0   CDK implementation patterns
#
# Development
#   git-workflow            1.0.0   Git branching and commit workflows
#
# Data Architecture
#   database-selection      1.0.0   Database technology selection framework
#
# Project Skills
# ──────────────────────────────────────────────────
#
# Deployment
#   myapp-deployment        1.0.0   MyApp deployment procedures
```

## Integration with AIDA Commands

### Commands that Use This Skill

- `/skill-list` - Lists all available skills
- `/create-skill` - Creates new skill (future)
- `/update-skill` - Updates existing skill (future)
- `/assign-skill` - Assigns skill to agent (future)

### How Commands Use This Skill

1. **Command invoked** by user (e.g., `/skill-list`)
2. **Command delegates** to `claude-agent-manager` agent
3. **Agent loads** this `aida-skills` skill for knowledge
4. **Agent invokes** `list-skills.sh` CLI script
5. **Agent formats** and presents results using skill knowledge

## Skill Maintenance

### Updating This Skill

**When to update**:

- Skill architecture changes
- New patterns emerge
- Validation rules change
- CLI script changes
- User feedback suggests improvements

**Update process**:

1. Increment `version` field
2. Update `last_updated` field
3. Document changes in content
4. Test with `list-skills.sh`
5. Verify `claude-agent-manager` can use updated skill
6. Update dependent skills if needed

### Versioning

- **Patch** (1.0.X): Clarifications, examples, minor fixes
- **Minor** (1.X.0): New patterns, additional knowledge
- **Major** (X.0.0): Structural changes, breaking updates

## Summary

This skill provides the foundational knowledge about AIDA skills:

- **Architecture**: Two-tier, file-based, frontmatter-driven, composable
- **Structure**: Directory per skill, markdown definition, optional knowledge
- **Creation**: Clear patterns for user-level and project-level skills
- **Validation**: Frontmatter, structure, content checks
- **Discovery**: Integration with `list-skills.sh`, category-first display
- **Assignment**: How agents use skills, loading strategies
- **Best Practices**: Naming, scope, organization, patterns

**Next Steps**: Use this knowledge to create, validate, discover, and assign skills within the AIDA system.

---

**Version**: 1.0.0
**Last Updated**: 2025-10-20
**Maintained By**: AIDA Framework Team
