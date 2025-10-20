# ADR-015: Skills System Implementation Plan

**Status**: Accepted
**Date**: 2025-10-20
**Deciders**: Project Lead
**Context**: Software
**Tags**: architecture, skills, implementation, meta-skills, discoverability

## Context and Problem Statement

ADR-009 defined the skills system architecture (two-tier, filesystem-based, markdown format). Now we need to implement the first skills as part of Issue #54 (Discoverability Commands). This implementation must establish:

- Skills location and file structure
- First skills to implement (AIDA meta-skills)
- How agents "use" skills (invocation pattern)
- Skills discovery mechanism
- Category structure and organization

We need to decide:

- Where skills are stored (filesystem paths)
- What the first skills should be (foundation layer)
- How skills are structured (directory layout, file format)
- How agents discover and load skills
- How skills relate to CLI scripts (execution layer)

Without clear implementation guidance, we risk:

- Inconsistent skill structure
- Poor skill organization
- Unclear agent-skill integration
- Difficulty discovering and using skills

## Decision Drivers

- **Foundation First**: Start with AIDA meta-skills (self-knowledge)
- **Filesystem-Based**: Consistent with agents/commands patterns
- **Two-Tier**: User-level + project-level (ADR-002 pattern)
- **Markdown Format**: Readable, versionable, AI-friendly
- **Category Structure**: Organized by domain (28 categories from skills catalog)
- **Agent Integration**: Clear pattern for how agents "use" skills
- **Discoverability**: Skills easily discovered via `/skill-list`

## Considered Options

### Option A: Flat Skills Directory

**Description**: All skills in `~/.claude/skills/` without categorization

**Structure**:

```text
~/.claude/skills/
├── aida-agents.md
├── aida-skills.md
├── aida-commands.md
├── hipaa-compliance.md
├── pytest-patterns.md
└── react-patterns.md
```

**Pros**:

- Simple (no category directories)
- Easy to list all skills

**Cons**:

- No organization (177 skills in one directory)
- Difficult to browse
- No category-based filtering
- Doesn't scale

**Cost**: Poor usability at scale

### Option B: Category Directories

**Description**: Skills organized by category subdirectories

**Structure**:

```text
~/.claude/skills/
├── aida-meta/
│   ├── aida-agents/aida-agents.md
│   ├── aida-skills/aida-skills.md
│   └── aida-commands/aida-commands.md
├── compliance/
│   ├── hipaa-compliance/hipaa-compliance.md
│   └── gdpr-compliance/gdpr-compliance.md
└── testing/
    └── pytest-patterns/pytest-patterns.md
```

**Pros**:

- Organized by domain
- Supports category filtering
- Scales to 177 skills
- Clear browsing structure

**Cons**:

- More complex file paths
- Need to define category taxonomy

**Cost**: Medium complexity, good organization

### Option C: Single Skill File (No Directories)

**Description**: Each skill is a single markdown file (no skill subdirectories)

**Structure**:

```text
~/.claude/skills/
├── aida-meta/
│   ├── aida-agents.md
│   ├── aida-skills.md
│   └── aida-commands.md
├── compliance/
│   ├── hipaa-compliance.md
│   └── gdpr-compliance.md
```

**Pros**:

- Simpler file structure
- Faster to navigate

**Cons**:

- No room for additional files (examples, templates)
- Doesn't match agent pattern (agent/agent.md)
- Harder to extend skills with supporting files

**Cost**: Limited extensibility

### Option D: Skill Directories with Supporting Files (Recommended)

**Description**: Each skill is a directory containing main file + supporting files

**Structure**:

```text
~/.claude/skills/
├── aida-meta/
│   ├── aida-agents/
│   │   ├── aida-agents.md (main skill file)
│   │   ├── examples.md (optional)
│   │   └── templates/ (optional)
│   ├── aida-skills/
│   │   └── aida-skills.md
│   └── aida-commands/
│       └── aida-commands.md
├── compliance/
│   └── hipaa-compliance/
│       ├── hipaa-compliance.md
│       ├── requirements.md
│       └── audit-checklist.md
```

**Pros**:

- Consistent with agent pattern (`agent/agent.md`)
- Room for supporting files (examples, templates, references)
- Extensible (add files without breaking structure)
- Organized by category

**Cons**:

- Deeper file hierarchy
- More directories to manage

**Cost**: Higher complexity, better extensibility

## Decision Outcome

**Chosen option**: Option D - Skill Directories with Supporting Files

**Rationale**:

1. **Consistency**: Matches agent pattern (`agent/agent.md`, `skill/skill.md`)

2. **Extensibility**: Skills can grow with supporting files:
   - `examples.md` - Practical examples
   - `templates/` - Reusable templates
   - `reference.md` - External references
   - `changelog.md` - Skill evolution history

3. **Organization**: Category structure scales to 177 skills:
   - 28 categories (from Claude Code skills catalog)
   - ~6 skills per category average
   - Clear browsing structure

4. **Two-Tier Support**: User + project levels:
   - `~/.claude/skills/{category}/{skill}/{skill.md}` (user-level)
   - `./.claude/skills/{category}/{skill}/{skill.md}` (project-level)

5. **Discovery**: `/skill-list` can:
   - Show categories only (28 categories)
   - `/skill-list <category>` shows skills in category
   - Progressive disclosure (don't overwhelm with 177 skills)

### Consequences

**Positive**:

- Organized, scalable skill structure
- Consistent with agent pattern (familiar to users)
- Extensible (add supporting files without breaking changes)
- Category-based filtering works naturally
- Two-tier architecture supported
- Skills can evolve (add examples, templates, references)

**Negative**:

- Deeper file hierarchy (more directories)
- **Mitigation**: Clear category taxonomy, good documentation
- Need to maintain category taxonomy
- **Mitigation**: Categories defined upfront, stable over time
- More complex than flat structure
- **Mitigation**: Tooling (`/skill-list`) makes discovery easy

**Neutral**:

- Skills installed by `install.sh` (same as agents/commands)
- Skills stored in `templates/skills/` in repo
- Skills copied to `~/.claude/skills/` during installation

## Implementation Details

### Skills Location

**Repository** (templates):

```text
templates/skills/
├── aida-meta/
│   ├── aida-agents/
│   │   └── aida-agents.md
│   ├── aida-skills/
│   │   └── aida-skills.md
│   └── aida-commands/
│       └── aida-commands.md
├── compliance/
├── testing/
├── frameworks/
├── api/
├── data-engineering/
└── infrastructure/
```

**Installed** (user system):

```text
~/.claude/skills/
├── aida-meta/
│   ├── aida-agents/
│   │   └── aida-agents.md
│   ├── aida-skills/
│   │   └── aida-skills.md
│   └── aida-commands/
│       └── aida-commands.md
```

**Project-specific** (optional):

```text
{project}/.claude/skills/
└── custom-category/
    └── custom-skill/
        └── custom-skill.md
```

### Skill File Structure

**Frontmatter Schema**:

```yaml
---
name: "skill-name"
version: "1.0.0"
category: "aida-meta|compliance|testing|frameworks|api|data-engineering|infrastructure"
description: "Brief description of skill"
used_by: ["agent-name", "agent-name"]
tags: ["tag1", "tag2"]
last_updated: "YYYY-MM-DD"
---
```

**Content Structure**:

```markdown
---
name: "aida-agents"
version: "1.0.0"
category: "aida-meta"
description: "Comprehensive knowledge about AIDA agent structure, creation, and validation"
used_by: ["claude-agent-manager"]
tags: ["meta", "agents", "discoverability"]
last_updated: "2025-10-20"
---

# Skill Name

## Overview

Brief description of what this skill provides

## When to Use

- Scenario 1
- Scenario 2

## Used By

- agent-name: For specific purpose
- agent-name: For different purpose

## Core Knowledge

[Main content: schemas, patterns, workflows, validation rules]

## How This Skill Works

[Integration with CLI scripts, usage patterns]

## Examples

[Practical examples]

## Related Skills

- [Other Skill](../other-skill/other-skill.md) - Relationship

## References

- External documentation
- Related ADRs
```

### First Skills: AIDA Meta-Skills

**Priority**: Create three foundational skills first (Issue #54)

**1. aida-agents** - Agent knowledge:

- **Location**: `templates/skills/aida-meta/aida-agents/aida-agents.md`
- **Purpose**: Comprehensive knowledge about AIDA agents
- **Content**:
  - Agent file structure and frontmatter schema
  - How to create, update, validate agents
  - Two-tier architecture patterns (user + project)
  - Knowledge base organization
  - Integration with `list-agents.sh` for discovery
- **Used By**: `claude-agent-manager` (for agent operations)

**2. aida-skills** - Skill knowledge:

- **Location**: `templates/skills/aida-meta/aida-skills/aida-skills.md`
- **Purpose**: Comprehensive knowledge about AIDA skills
- **Content**:
  - Skill file structure and frontmatter schema
  - How to create, update, validate skills
  - Skill categories and organization (28 categories)
  - How to assign skills to agents
  - Integration with `list-skills.sh` for discovery
- **Used By**: `claude-agent-manager` (for skill operations)

**3. aida-commands** - Command knowledge:

- **Location**: `templates/skills/aida-meta/aida-commands/aida-commands.md`
- **Purpose**: Comprehensive knowledge about AIDA commands
- **Content**:
  - Command file structure and frontmatter schema
  - How to create, update, validate commands
  - Category taxonomy (8 categories)
  - Argument handling patterns
  - Integration with `list-commands.sh` for discovery
- **Used By**: `claude-agent-manager` (for command operations)

### How Agents "Use" Skills

**Pattern**: Agent reads skill markdown, applies knowledge to provide context-aware assistance

**Example Flow** (`/agent-list`):

1. User invokes `/agent-list`
2. Slash command delegates to `claude-agent-manager` with `aida-agents` skill
3. Agent reads `~/.claude/skills/aida-meta/aida-agents/aida-agents.md`
4. Agent learns:
   - Agent frontmatter schema (required fields: name, version, description)
   - Valid agent structures
   - Two-tier architecture patterns
   - How to validate agents
5. Agent invokes `scripts/list-agents.sh` to gather data
6. CLI script returns raw data (agents found, frontmatter parsed)
7. Agent applies knowledge:
   - Validates agent structures against schema
   - Identifies missing required fields
   - Provides context ("15 agents, 3 project-specific")
   - Suggests actions ("Missing data-engineer? Try /create-agent")
8. Agent returns intelligent response (not just data dump)

**Key Insight**: Skills provide comprehensive knowledge that agents apply, scripts provide data that agents validate

### Category Structure (28 Categories)

Derived from Claude Code skills catalog:

**AIDA Meta** (3 skills):

- aida-agents, aida-skills, aida-commands

**Development** (40+ skills):

- Languages: python, javascript, typescript, go, rust, java
- Frameworks: react, vue, django, fastapi, nextjs, express
- Testing: pytest, jest, playwright, k6

**Data Engineering** (30+ skills):

- Warehouses: snowflake, bigquery, redshift
- Pipelines: dbt, airbyte, fivetran
- Modeling: kimball, data-vault, medallion

**Infrastructure** (25+ skills):

- Cloud: aws, azure, gcp
- IaC: terraform, cdk, cloudformation
- CI/CD: github-actions, gitlab-ci

**Compliance** (10+ skills):

- Regulations: hipaa, gdpr, pci, sox
- Security: owasp, nist, cis-benchmarks

**Quality** (15+ skills):

- Code quality: linting, formatting, complexity
- Testing: unit, integration, e2e, performance

**Observability** (12+ skills):

- Monitoring: datadog, prometheus, grafana
- Logging: splunk, elasticsearch
- Tracing: opentelemetry, jaeger

**API Design** (10+ skills):

- Protocols: rest, graphql, grpc
- Documentation: openapi, swagger

### Skills Discovery Mechanism

**Via `/skill-list`**:

```bash
/skill-list                    # Shows 28 categories (summary)
/skill-list aida-meta          # Shows 3 skills in aida-meta category
/skill-list --format json      # JSON output for automation
```

**Implementation**:

1. `scripts/list-skills.sh` scans `~/.claude/skills/` and `./.claude/skills/`
2. Parses frontmatter (category, name, description, version)
3. Groups by category
4. Formats output (plain text table or JSON)
5. Returns to `claude-agent-manager` with `aida-skills` skill
6. Agent provides intelligent response

**Progressive Disclosure**:

- Default: Show categories only (28 categories, not 177 skills)
- With argument: Show skills within category
- Prevents overwhelming users

### Integration with CLI Scripts

**Skills contain knowledge, scripts execute operations**:

**aida-agents skill**:

- Knows: Agent frontmatter schema, validation rules, two-tier patterns
- Does NOT: Scan filesystem (that's `list-agents.sh`)

**list-agents.sh script**:

- Does: Scan filesystem, parse frontmatter, format output
- Does NOT: Validate schemas (that's agent with aida-agents skill)

**Division of Labor**:

- **Skills**: Comprehensive domain knowledge (schemas, patterns, validation)
- **Scripts**: Fast data extraction (filesystem scanning, parsing)
- **Agent**: Orchestration (combines knowledge + data for intelligent responses)

## Validation

- [x] Consistent with ADR-002 (two-tier architecture)
- [x] Consistent with ADR-009 (skills system architecture)
- [x] First skills are foundational (AIDA meta-skills)
- [x] Category structure supports 177 skills
- [x] Agent-skill integration pattern clear
- [x] Discovery mechanism defined (`/skill-list`)
- [x] Extensible (supporting files, additional skills)

## Migration Plan

### Phase 1: Create AIDA Meta-Skills (Issue #54)

**Timeline**: 18-24 hours

**Deliverables**:

- [ ] Create `templates/skills/aida-meta/` directory
- [ ] Create `aida-agents/aida-agents.md` (6-8 hours)
- [ ] Create `aida-skills/aida-skills.md` (6-8 hours)
- [ ] Create `aida-commands/aida-commands.md` (6-8 hours)
- [ ] Update `install.sh` to install skills
- [ ] Update `claude-agent-manager` to include meta-skills
- [ ] Test skill invocation from commands

### Phase 2: Add Domain Skills (Future)

**Timeline**: Incremental, as needed

**Categories to prioritize**:

1. **Compliance**: hipaa-compliance, gdpr-compliance, pci-compliance
2. **Testing**: pytest-patterns, playwright-automation, k6-performance
3. **Frameworks**: react-patterns, nextjs-setup, django-patterns
4. **Data Engineering**: dbt-incremental-strategy, kimball-modeling

### Phase 3: Project-Specific Skills (Future)

**Timeline**: On-demand, as projects need custom skills

**Examples**:

- Company UI component library
- Internal API standards
- Project-specific dbt macros

## Examples

### Example 1: AIDA Agents Meta-Skill

**File**: `templates/skills/aida-meta/aida-agents/aida-agents.md`

**Purpose**: Comprehensive knowledge about AIDA agents

**Content**:

```markdown
---
name: "aida-agents"
version: "1.0.0"
category: "aida-meta"
description: "Comprehensive knowledge about AIDA agent structure, creation, and validation"
used_by: ["claude-agent-manager"]
tags: ["meta", "agents", "discoverability"]
last_updated: "2025-10-20"
---

# AIDA Agents Meta-Skill

## Overview

This skill provides comprehensive knowledge about AIDA agents: their structure,
creation, validation, and discovery. Used by claude-agent-manager to provide
intelligent assistance with agent operations.

## Agent File Structure

Agents follow this structure:
- Location: `~/.claude/agents/{agent}/{agent.md}` (user-level)
- Location: `./.claude/agents/{agent}/{agent.md}` (project-level)
- Main file: `{agent}.md` (agent instructions)
- Knowledge base: `knowledge/` subdirectory (optional)

## Frontmatter Schema

Required fields:
- name: Agent name (kebab-case)
- version: Semantic version (e.g., "1.0.0")
- description: Brief description
- model: Claude model to use
- color: Terminal color for agent messages

Optional fields:
- temperature: Model temperature (default: 1.0)
- max_tokens: Max response tokens
- tags: Array of tags

[... comprehensive knowledge continues ...]

## Integration with list-agents.sh

When listing agents, this skill enables:
- Validation of agent structures against schema
- Identification of missing required fields
- Intelligent recommendations (suggest missing agents)
- Context-aware responses (explain agent purposes)

## Examples

[Practical examples of agent creation, validation]

## Related Skills

- [aida-skills](../aida-skills/aida-skills.md) - Skill knowledge
- [aida-commands](../aida-commands/aida-commands.md) - Command knowledge
```

**Usage**: `claude-agent-manager` reads this skill when handling `/agent-list`, `/create-agent`, etc.

### Example 2: Project-Specific Skill

**File**: `{project}/.claude/skills/custom/warehouse-patterns/warehouse-patterns.md`

**Purpose**: Project-specific dbt patterns

**Content**:

```yaml
---
name: "warehouse-patterns"
version: "1.0.0"
category: "custom"
description: "Project-specific dbt patterns and naming conventions"
used_by: ["data-engineer", "sql-expert"]
tags: ["dbt", "snowflake", "project-specific"]
last_updated: "2025-10-20"
---
```

**Used By**: `data-engineer` agent reads this for project-specific dbt guidance

## References

- ADR-002: Two-Tier Agent Architecture (skills follow same pattern)
- ADR-009: Skills System Architecture (defines skills system)
- ADR-014: Discoverability Command Architecture (uses meta-skills)
- Issue #54: Discoverability Commands Implementation
- Claude Code Skills Catalog (28 categories)

## Related ADRs

- ADR-002: Two-Tier Agent Architecture (two-tier skills)
- ADR-009: Skills System Architecture (skills foundation)
- ADR-014: Discoverability Command Architecture (AIDA meta-skills usage)

## Updates

None yet
