---
name: aida-agents
version: 1.0.0
category: meta
description: Comprehensive knowledge about AIDA agent architecture, structure, creation, and management
tags: [agents, meta-knowledge, architecture, two-tier, discovery]
used_by: [claude-agent-manager, aida]
last_updated: "2025-10-20"
---

# AIDA Agents Meta-Skill

This skill provides comprehensive knowledge about AIDA's agent architecture, enabling intelligent assistance with agent creation, validation, discovery, and management.

## Purpose

This meta-skill enables the AIDA system (via `claude-agent-manager`) to:

- **Understand** the complete agent architecture and patterns
- **Create** new agents following established conventions
- **Validate** agent structure and frontmatter
- **List** all available agents (via `list-agents.sh`)
- **Update** existing agents while maintaining consistency
- **Advise** on best practices for agent organization

## Agent Architecture Overview

### What is an AIDA Agent?

An AIDA agent is a **specialized AI persona** with domain expertise, configured via markdown files with YAML frontmatter. Agents provide:

- Domain-specific knowledge and context
- Specialized problem-solving approaches
- Consistent expertise across sessions
- Reusable patterns and templates

### Two-Tier Architecture

AIDA uses a **two-tier discovery pattern** (defined in ADR-002):

1. **User-Level** (`~/.claude/agents/`): Generic, reusable agents for all projects
2. **Project-Level** (`./.claude/project/context/`): Project-specific context and knowledge for agents

**Discovery Order**:

1. Check project-level context first (`./.claude/project/context/`)
2. Fall back to user-level (`~/.claude/agents/`)
3. Merge knowledge from both if agent exists at both levels

## File Structure

### Directory Layout

```text
User-Level Agents:
~/.claude/agents/
├── product-manager/
│   ├── product-manager.md          # Agent definition
│   └── knowledge/                   # Optional knowledge base
│       ├── patterns/
│       ├── frameworks/
│       └── templates/

Project-Level Context:
./.claude/project/context/
├── product-manager/
│   └── index.md                    # Project-specific context
│       # Provides context for user-level agent
└── custom-project-agent/
    └── index.md                    # Project-only context
```

### File Naming Convention

- **User-level**: `{agent-name}/{agent-name}.md`
- **Project-level**: `{agent-name}/index.md`

**Why different naming?**

- User-level uses `{name}.md` for clarity and IDE indexing
- Project-level uses `index.md` to allow future expansion (README, examples, etc.)

## Frontmatter Schema

### Required Fields

```yaml
---
name: agent-name                # Lowercase, hyphen-separated
version: 1.0.0                  # Semantic versioning
description: Brief one-line description of agent purpose
category: domain                # Agent domain category
---
```

### Optional Fields

```yaml
---
# Optional metadata
tags: [tag1, tag2, tag3]        # Searchable tags
model: claude-3-5-sonnet        # Preferred model (if specific requirements)
temperature: 0.7                # Preferred temperature (if non-default)
scope: user|project|global      # Where agent should be available

# Agent behavior
proactive: true                 # Agent can initiate actions without prompting
autonomous: false               # Agent can make decisions independently

# Integration
used_by: [other-agent]          # Agents that reference this one
depends_on: [dependency]        # Agents this one depends on
skills: [skill1, skill2]        # Skills this agent uses

# Documentation
author: "Author Name"           # Agent creator
created: "2025-10-20"           # Creation date
last_updated: "2025-10-20"      # Last modification
---
```

### Frontmatter Examples

**Minimal Agent**:

```yaml
---
name: code-reviewer
version: 1.0.0
description: Reviews code for quality, security, and best practices
category: quality
---
```

**Full-Featured Agent**:

```yaml
---
name: aws-cloud-engineer
version: 2.1.0
description: AWS infrastructure design, CDK implementation, and cloud architecture expertise
category: infrastructure
tags: [aws, cdk, cloudformation, infrastructure-as-code]
model: claude-3-5-sonnet
scope: user
proactive: true
skills: [aws-service-selection, cdk-patterns, cost-optimization]
used_by: [tech-lead, devops-engineer]
author: "Platform Team"
created: "2025-01-15"
last_updated: "2025-10-20"
---
```

## Agent Categories

Common agent categories (not exhaustive):

- **product**: Product management, requirements, stakeholder analysis
- **technical**: Technical leadership, architecture, code review
- **infrastructure**: Cloud, DevOps, CI/CD, deployment
- **data**: Data engineering, analytics, warehousing
- **quality**: QA, testing, validation
- **security**: Security auditing, compliance, threat modeling
- **documentation**: Technical writing, docs generation
- **domain**: Domain-specific experts (finance, healthcare, etc.)
- **meta**: Meta-agents (like claude-agent-manager/aida)

## Creating a New Agent

### Step 1: Plan the Agent

**Questions to answer**:

1. What domain expertise does this agent provide?
2. What problems does it solve?
3. Who will use this agent?
4. What scope? (user-level or project-specific)
5. What skills or knowledge does it need?

### Step 2: Create Directory Structure

**For user-level agent** (generic, reusable):

```bash
mkdir -p ~/.claude/agents/{agent-name}/knowledge
```

**For project-level context** (project-specific):

```bash
mkdir -p ./.claude/project/context/{agent-name}
```

### Step 3: Create Agent Definition File

**User-level** (`~/.claude/agents/{agent-name}/{agent-name}.md`):

```markdown
---
name: {agent-name}
version: 1.0.0
description: {one-line description}
category: {category}
tags: [{relevant-tags}]
---

# {Agent Name} Agent

## Purpose

{Explain what this agent does and why it exists}

## Expertise

{List areas of expertise}

## When to Use This Agent

{Describe scenarios where this agent should be invoked}

## Approach

{Explain the agent's methodology or problem-solving approach}

## Key Responsibilities

- {Responsibility 1}
- {Responsibility 2}

## Knowledge Base

{If agent has knowledge base, describe organization}

## Integration Points

{How this agent works with other agents or systems}

## Examples

### Example 1: {Scenario}

{Show how agent handles this scenario}

### Example 2: {Scenario}

{Show how agent handles this scenario}

## References

- {Links to relevant documentation}
- {Related agents}
```

**Project-level** (`./.claude/project/context/{agent-name}/index.md`):

```markdown
---
name: {agent-name}
version: 1.0.0
description: {project-specific description}
category: {category}
scope: project
extends: {user-level-agent}  # Optional: extends user-level agent
---

# {Agent Name} - Project Configuration

## Project Context

{Explain project-specific context}

## Project-Specific Knowledge

{What makes this agent unique to this project?}

## Overrides

{Any behavior overrides from user-level agent}

## Examples

{Project-specific examples}
```

### Step 4: Add Knowledge Base (Optional)

Organize knowledge in subdirectories:

```bash
mkdir -p ~/.claude/agents/{agent-name}/knowledge/{subdomain}
```

**Knowledge organization patterns**:

- `patterns/` - Reusable patterns and templates
- `frameworks/` - Frameworks and methodologies
- `references/` - Reference documentation
- `examples/` - Example code, architectures, etc.
- `decisions/` - Past decisions and rationale

### Step 5: Validate Agent

**Validation checklist**:

- [ ] Frontmatter contains all required fields
- [ ] Name is lowercase, hyphen-separated
- [ ] Version follows semantic versioning (X.Y.Z)
- [ ] Description is clear and concise
- [ ] Category is appropriate
- [ ] File structure follows conventions
- [ ] Markdown linting passes
- [ ] Agent is discoverable by `list-agents.sh`

## Updating an Existing Agent

### When to Update

- Adding new knowledge or capabilities
- Refining agent behavior
- Fixing errors or inconsistencies
- Responding to user feedback
- Project requirements change

### Update Process

1. **Increment version**:
   - Patch (X.Y.Z+1): Bug fixes, minor clarifications
   - Minor (X.Y+1.0): New capabilities, backward-compatible
   - Major (X+1.0.0): Breaking changes, major refactor

2. **Update `last_updated` field**

3. **Document changes** in agent content or knowledge base

4. **Test changes** by invoking agent and verifying behavior

### Backward Compatibility

**User-level agents**: Maintain backward compatibility when possible

**Project-level agents**: Can break compatibility if project-specific

## Validation Requirements

### Frontmatter Validation

**Required field checks**:

```bash
# Check for required fields
- name: ^[a-z][a-z0-9-]*$  # Lowercase, hyphen-separated
- version: ^\d+\.\d+\.\d+$  # Semantic versioning
- description: .{10,200}    # 10-200 characters
- category: ^[a-z]+$        # Lowercase category
```

**Validation errors to catch**:

- Missing required fields
- Invalid name format (uppercase, spaces, special chars)
- Invalid version format (not semantic versioning)
- Empty or too-short description
- Unknown category

### Structural Validation

**Directory structure checks**:

- Agent directory exists
- Definition file exists (`.md` for user, `index.md` for project)
- No conflicting files (both user and project with same name)
- Knowledge base organized (if present)

### Content Validation

**Agent content checks**:

- Markdown linting passes
- Frontmatter is valid YAML
- Agent purpose is clearly documented
- Examples are provided
- No hardcoded secrets or credentials

## Integration with list-agents.sh

### How Discovery Works

The `list-agents.sh` CLI script:

1. **Scans user-level**: `~/.claude/agents/*/` for `{agent-name}.md` files
2. **Scans project-level**: `./.claude/project/context/*/` for `index.md` files
3. **Parses frontmatter**: Extracts name, version, description, category
4. **Deduplicates**: Uses `realpath` to detect symlinks (dev mode)
5. **Formats output**:
   - Plain text table (default)
   - JSON format (`--format json`)
6. **Separates sections**: Global vs. Project agents clearly distinguished

### What Gets Listed

**Per agent, the script shows**:

- Name
- Version
- Category
- Description
- Location (sanitized path: `${CLAUDE_CONFIG_DIR}` or `${PROJECT_ROOT}`)

### Symlink Handling

**Dev mode creates symlinks**:

- `~/.claude/agents/` → symlinks to `~/.aida/templates/agents/`
- `list-agents.sh` uses `realpath` to deduplicate
- Only shows canonical path, marks if symlinked

## Best Practices

### Naming Conventions

**✅ Good agent names**:

- `product-manager` (clear, descriptive)
- `aws-cloud-engineer` (specific domain)
- `sql-expert` (focused expertise)
- `code-reviewer` (clear purpose)

**❌ Bad agent names**:

- `PM` (too abbreviated)
- `My_Agent` (underscores, capitalization)
- `agent-1` (generic, non-descriptive)
- `super-awesome-agent` (subjective, non-informative)

### Description Guidelines

**✅ Good descriptions**:

- "Reviews code for quality, security, and performance issues"
- "AWS infrastructure design and CDK implementation expert"
- "SQL query optimization and database performance tuning"

**❌ Bad descriptions**:

- "Helps with stuff" (too vague)
- "An agent that does many things including..." (too long)
- "Expert" (no domain specified)

### Scope Guidelines

**User-level agents** (in `~/.claude/agents/`):

- Generic, reusable across projects
- No project-specific context
- Broadly applicable knowledge
- Examples: `code-reviewer`, `sql-expert`, `devops-engineer`

**Project-level context** (in `./.claude/project/context/`):

- Project-specific context
- Custom workflows or patterns
- Provides context for user-level agents
- Examples: `myapp-backend-engineer`, `project-specific-auditor`

### Knowledge Organization

**Keep knowledge modular**:

- One topic per file
- Clear file naming (`pattern-name.md`, not `doc1.md`)
- Use subdirectories for organization
- Link between related knowledge files

**Knowledge base example**:

```text
~/.claude/agents/aws-cloud-engineer/knowledge/
├── services/
│   ├── lambda.md
│   ├── ecs.md
│   └── rds.md
├── patterns/
│   ├── multi-stack-cdk.md
│   └── custom-constructs.md
└── decisions/
    └── service-selection-matrix.md
```

## Common Patterns

### Pattern 1: Specialist Agent

**Purpose**: Deep expertise in one domain

**Structure**:

- Focused scope
- Comprehensive knowledge in domain
- Clear invocation criteria
- Examples: `sql-expert`, `security-auditor`

### Pattern 2: Orchestrator Agent

**Purpose**: Coordinates multiple specialist agents

**Structure**:

- Delegates to other agents
- Synthesizes results
- Manages workflow
- Example: `tech-lead`, `product-manager`

### Pattern 3: Meta Agent

**Purpose**: Understands and manages the AIDA system itself

**Structure**:

- Knowledge about AIDA architecture
- Can create/modify other agents
- System-level operations
- Example: `claude-agent-manager` (soon `aida`)

### Pattern 4: Project-Specific Agent

**Purpose**: Extends generic agent with project context

**Structure**:

- `extends` field references user-level agent
- Adds project-specific knowledge
- Overrides behavior if needed
- Example: `myproject-backend-engineer` extends `backend-engineer`

## Troubleshooting

### Agent Not Discovered

**Symptoms**: Agent doesn't appear in `list-agents.sh` output

**Checks**:

1. File named correctly? (`{agent-name}.md` or `index.md`)
2. In correct directory? (`~/.claude/agents/` or `./.claude/project/context/`)
3. Frontmatter valid YAML?
4. Required fields present?

**Fix**: Verify file location and frontmatter structure

### Agent Behavior Inconsistent

**Symptoms**: Agent behaves differently than expected

**Checks**:

1. Multiple versions present? (user + project)
2. Knowledge base outdated?
3. Agent description unclear?
4. Missing context in knowledge?

**Fix**: Review agent definition, update knowledge, clarify purpose

### Symlink Confusion

**Symptoms**: Agent appears twice in dev mode

**Checks**:

1. Running in dev mode?
2. Symlinks created correctly?
3. `list-agents.sh` using `realpath`?

**Fix**: Use `realpath` for deduplication, verify symlink targets

## Examples

### Example 1: Creating a Simple Agent

```bash
# Create directory
mkdir -p ~/.claude/agents/markdown-expert

# Create agent file
cat > ~/.claude/agents/markdown-expert/markdown-expert.md << 'EOF'
---
name: markdown-expert
version: 1.0.0
description: Markdown formatting, linting, and best practices specialist
category: documentation
tags: [markdown, formatting, linting]
---

# Markdown Expert Agent

## Purpose

Provides expertise in markdown formatting, linting rules, and best practices
for documentation.

## Expertise

- Markdown syntax and formatting
- CommonMark specification
- Markdownlint rules and configuration
- GitHub-flavored markdown extensions

## When to Use

- Writing or reviewing markdown documentation
- Fixing markdown linting errors
- Structuring documentation files
- Ensuring consistent markdown style

## Approach

Focus on readability, consistency, and adherence to linting rules while
maintaining practical usability.

## Key Responsibilities

- Fix markdown linting errors
- Suggest formatting improvements
- Explain markdown best practices
- Configure markdownlint rules

## References

- [CommonMark Spec](https://commonmark.org/)
- [markdownlint rules](https://github.com/DavidAnson/markdownlint/blob/main/doc/Rules.md)
EOF

# Validate
cat ~/.claude/agents/markdown-expert/markdown-expert.md
```

### Example 2: Creating a Project-Specific Agent

```bash
# Create directory
mkdir -p ./.claude/project/context/myapp-api-specialist

# Create context file
cat > ./.claude/project/context/myapp-api-specialist/index.md << 'EOF'
---
name: myapp-api-specialist
version: 1.0.0
description: MyApp REST API design, implementation, and testing expert
category: backend
scope: project
extends: api-specialist
tags: [myapp, api, rest, nodejs]
---

# MyApp API Specialist

## Project Context

MyApp is a Node.js/Express REST API with PostgreSQL database.

## Project-Specific Knowledge

**Tech Stack**:
- Node.js 18+
- Express 4.x
- PostgreSQL 14
- JWT authentication
- Jest for testing

**API Conventions**:
- RESTful endpoints
- JSON:API format
- Versioned routes (/v1/...)
- Rate limiting with redis

**Authentication**:
- JWT tokens (15min expiry)
- Refresh tokens (7 days)
- Role-based access control

## Overrides

Extends `api-specialist` with MyApp-specific patterns and constraints.

## Examples

### Example: Create New Endpoint

```javascript
// routes/v1/users.js
router.get('/v1/users/:id', authenticate, async (req, res) => {
  // MyApp pattern
});
```

EOF

```bash

### Example 3: Listing All Agents

```bash
# Plain text output
~/.claude/scripts/.aida/list-agents.sh

# JSON output
~/.claude/scripts/.aida/list-agents.sh --format json

# Example output (plain text):
# Global Agents (User-Level)
# ─────────────────────────────────────────────────
# Name                  Version  Category        Description
# code-reviewer         1.0.0    quality         Reviews code for quality and security
# sql-expert            2.1.0    data            SQL optimization and database tuning
#
# Project Agents
# ─────────────────────────────────────────────────
# Name                  Version  Category        Description
# myapp-api-specialist  1.0.0    backend         MyApp REST API specialist
```

## Integration with AIDA Commands

### Commands that Use This Skill

- `/agent-list` - Lists all available agents
- `/create-agent` - Creates new agent (future)
- `/update-agent` - Updates existing agent (future)

### How Commands Use This Skill

1. **Command invoked** by user (e.g., `/agent-list`)
2. **Command delegates** to `claude-agent-manager` agent
3. **Agent loads** this `aida-agents` skill for knowledge
4. **Agent invokes** `list-agents.sh` CLI script
5. **Agent formats** and presents results using skill knowledge

## Skill Maintenance

### Updating This Skill

**When to update**:

- Agent architecture changes
- New patterns emerge
- Validation rules change
- User feedback suggests improvements

**Update process**:

1. Increment `version` field
2. Update `last_updated` field
3. Document changes in content
4. Test with `list-agents.sh`
5. Verify `claude-agent-manager` can use updated skill

### Versioning

- **Patch** (1.0.X): Clarifications, examples, minor fixes
- **Minor** (1.X.0): New patterns, additional knowledge
- **Major** (X.0.0): Structural changes, breaking updates

## Summary

This skill provides the foundational knowledge about AIDA agents:

- **Architecture**: Two-tier, file-based, frontmatter-driven
- **Structure**: Directory per agent, markdown definition, optional knowledge
- **Creation**: Clear patterns for user-level and project-level agents
- **Validation**: Frontmatter, structure, content checks
- **Discovery**: Integration with `list-agents.sh`
- **Best Practices**: Naming, scope, organization

**Next Steps**: Use this knowledge to create, validate, and discover agents within the AIDA system.

---

**Version**: 1.0.0
**Last Updated**: 2025-10-20
**Maintained By**: AIDA Framework Team
