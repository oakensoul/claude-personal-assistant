---
title: "Agent Templates"
description: "Specialized AI agent templates for AIDA task delegation"
category: "reference"
tags: ["agents", "templates", "delegation", "aida"]
last_updated: "2025-10-06"
status: "published"
audience: "developers"
---

# Agent Templates

Agent templates are specialized AI personalities designed for specific tasks within the AIDA framework. This directory contains privacy-safe, generic agent definitions that are installed to user configurations and customized for individual projects.

## Table of Contents

- [What Are Agents?](#what-are-agents)
- [When to Use Agents](#when-to-use-agents)
- [Agent Architecture](#agent-architecture)
- [Available Agents](#available-agents)
- [Two-Tier Knowledge System](#two-tier-knowledge-system)
- [Agent Structure](#agent-structure)
- [Runtime Variables](#runtime-variables)
- [Installation and Setup](#installation-and-setup)
- [Invoking Agents](#invoking-agents)
- [Creating New Agents](#creating-new-agents)
- [Knowledge Management](#knowledge-management)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

## What Are Agents?

Agents are specialized AI personalities that Claude Code can invoke to handle specific types of tasks. Unlike slash commands (which define workflows), agents define expertise, responsibilities, and decision-making frameworks for particular domains.

**Key Characteristics:**

- **Specialized**: Each agent focuses on a specific domain (code review, devops, documentation)
- **Stateful**: Agents maintain knowledge bases that persist across invocations
- **Contextual**: Agents have access to both generic knowledge and project-specific context
- **Composable**: Multiple agents can work together on complex tasks

**Agents vs. Commands:**

| Feature | Agents | Commands |
|---------|--------|----------|
| Purpose | Expertise and decision-making | Workflow execution |
| Invocation | Via Task tool (internal) | Via `/command` (user-facing) |
| Knowledge | Has dedicated knowledge base | References agents for expertise |
| State | Maintains persistent knowledge | Stateless workflow steps |
| Example | `code-reviewer` agent | `/create-issue` command |

## When to Use Agents

Use agents for tasks requiring:

- **Domain expertise**: Code review, architecture design, documentation writing
- **Complex decision-making**: Prioritization, trade-off analysis, design choices
- **Contextual knowledge**: Project-specific patterns, standards, or conventions
- **Multi-step reasoning**: Requirements analysis, technical specifications, debugging
- **Continuous learning**: Accumulating project knowledge over time

Use commands for tasks requiring:

- **Structured workflows**: Step-by-step procedures with clear outputs
- **User interaction**: Gathering input, confirming actions
- **Orchestration**: Coordinating multiple agents or tools
- **Repeatability**: Consistent execution of defined processes

## Agent Architecture

### Core Components

Each agent consists of:

1. **Agent Definition File**: `{agent-name}.md` with frontmatter and instructions
2. **Knowledge Directory**: `knowledge/` containing domain-specific documentation
3. **Knowledge Index**: `knowledge/README.md` cataloging available knowledge

### Agent Lifecycle

```text
1. Installation
   - Templates copied from templates/agents/ to ~/.claude/agents/
   - Generic knowledge structures created
   - Runtime variables remain unexpanded

2. Project Initialization (optional)
   - Project-specific agent directories created via /workflow-init
   - Project knowledge accumulated in .claude/agents/{name}/knowledge/
   - Agent behavior adapts to project context

3. Invocation
   - Claude Code invokes agent via Task tool
   - Agent loads generic knowledge from ~/.claude/agents/{name}/knowledge/
   - Agent checks for project knowledge in {project}/.claude/agents/{name}/knowledge/
   - Agent executes with combined context

4. Knowledge Accumulation
   - Agents document decisions, patterns, learnings
   - Project knowledge stored in project .claude/ directory
   - Generic knowledge may be added to user ~/.claude/ directory
```

## Available Agents

### Core Agents

#### claude-agent-manager

**Purpose**: Meta-agent for creating and managing other agents and commands

**When to Use**:

- Creating new agents or commands
- Modifying existing agent configurations
- Setting up knowledge bases
- Managing agent standards and documentation

**Example Invocation Pattern**:

```text
User: "I need an agent to handle API design"
→ Claude invokes claude-agent-manager via Task tool
→ Agent gathers requirements interactively
→ Creates new agent with proper structure
```

#### code-reviewer

**Purpose**: Multi-language code quality review and standards enforcement

**When to Use**:

- Reviewing code for quality, security, performance
- Enforcing coding standards and best practices
- Identifying bugs, vulnerabilities, or architectural issues
- Validating test coverage and documentation

**Example Invocation Pattern**:

```text
User: "Review this PHP code for security issues"
→ Claude invokes code-reviewer via Task tool
→ Agent performs security-focused analysis
→ Returns findings with specific recommendations
```

**Languages Supported**: PHP, JavaScript/TypeScript, Python, Go, Rust, and more

#### devops-engineer

**Purpose**: CI/CD, infrastructure management, and deployment automation

**When to Use**:

- Setting up GitHub Actions workflows
- Configuring deployment pipelines
- Managing infrastructure as code
- Container orchestration (Docker, Kubernetes)
- Monitoring and observability setup

**Example Invocation Pattern**:

```text
User: "Set up CI/CD for this project"
→ Claude invokes devops-engineer via Task tool
→ Agent analyzes project structure
→ Creates appropriate workflow files
→ Documents deployment procedures
```

#### product-manager

**Purpose**: Requirements analysis, PRD creation, and feature prioritization

**When to Use**:

- Creating Product Requirements Documents (PRDs)
- Analyzing user needs and feature requests
- Prioritizing features and defining success criteria
- Managing stakeholder communication
- Defining project scope and trade-offs

**Example Invocation Pattern**:

```text
User: "Help me write a PRD for dark mode feature"
→ Claude invokes product-manager via Task tool
→ Agent gathers requirements through questions
→ Creates structured PRD with user stories
→ Defines success criteria and out-of-scope items
```

#### tech-lead

**Purpose**: Architecture design, technical specifications, and system design

**When to Use**:

- Designing system architecture
- Creating technical specifications
- Making technology stack decisions
- Reviewing architectural patterns
- Planning technical implementations

**Example Invocation Pattern**:

```text
User: "Design the architecture for a real-time chat system"
→ Claude invokes tech-lead via Task tool
→ Agent analyzes requirements
→ Proposes architecture with diagrams
→ Documents design decisions and trade-offs
```

#### technical-writer

**Purpose**: Multi-audience documentation creation (developers, customers, partners)

**When to Use**:

- Creating API documentation
- Writing user guides and tutorials
- Developing integration documentation
- Producing developer guides
- Maintaining documentation standards

**Example Invocation Pattern**:

```text
User: "Create API documentation for our REST endpoints"
→ Claude invokes technical-writer via Task tool
→ Agent analyzes API structure
→ Generates comprehensive documentation
→ Includes examples and best practices
```

**Audience Types**: Developers, end-users, integration partners, stakeholders

## Two-Tier Knowledge System

AIDA uses a two-tier knowledge architecture to balance reusability with project-specificity:

### Tier 1: User-Level Knowledge (Generic, Reusable)

**Location**: `~/.claude/agents/{agent-name}/knowledge/`

**Purpose**: Generic, privacy-safe knowledge applicable across all projects

**Contains**:

- General best practices and patterns
- Framework-level documentation
- Language-agnostic concepts
- Reusable decision frameworks

**Example**:

```text
~/.claude/agents/code-reviewer/knowledge/
├── README.md
├── core-concepts/
│   ├── code-quality-principles.md
│   ├── security-patterns.md
│   └── performance-optimization.md
├── patterns/
│   ├── review-checklists.md
│   └── feedback-templates.md
└── decisions/
    └── when-to-escalate.md
```

### Tier 2: Project-Level Knowledge (Project-Specific)

**Location**: `{project}/.claude/agents/{agent-name}/knowledge/`

**Purpose**: Project-specific context and learned patterns

**Contains**:

- Project-specific coding standards
- Architectural patterns used in the project
- Team conventions and preferences
- Project-specific tool configurations
- Historical decisions and their rationale

**Example**:

```text
{project}/.claude/agents/code-reviewer/knowledge/
├── README.md
├── standards/
│   ├── react-patterns.md
│   └── api-conventions.md
├── metrics/
│   └── performance-baselines.md
└── decisions/
    └── typescript-migration.md
```

### Knowledge Resolution Order

When an agent is invoked in a project context:

1. **Check for project knowledge**: `{project}/.claude/agents/{name}/knowledge/`
2. **Merge with user knowledge**: `~/.claude/agents/{name}/knowledge/`
3. **Project knowledge takes precedence** when conflicts exist
4. **Agent adapts behavior** based on available context

## Agent Structure

### Agent Definition File

Every agent has a markdown file with YAML frontmatter:

```yaml
---
name: agent-name               # kebab-case identifier
description: Brief description # When to use this agent
model: claude-sonnet-4.5      # AI model to use
color: blue                    # Optional visual identifier
temperature: 0.7               # Optional creativity setting
---

# Agent Name

Agent instructions, responsibilities, and behavior...
```

**Required Fields**:

- `name`: Kebab-case identifier (matches directory name)
- `description`: Clear explanation of when to use this agent
- `model`: AI model (default: `claude-sonnet-4.5`)

**Optional Fields**:

- `color`: Visual identifier for UI/logging
- `temperature`: Model creativity setting (0.0-1.0)

### Knowledge Directory Structure

Standard structure for agent knowledge bases:

```text
{agent-name}/
├── {agent-name}.md          # Agent definition file
└── knowledge/
    ├── README.md            # Knowledge index and guide
    ├── core-concepts/       # Fundamental concepts
    │   └── *.md
    ├── patterns/            # Reusable patterns
    │   └── *.md
    ├── decisions/           # Decision history
    │   └── *.md
    └── external-links/      # External references (optional)
        └── *.md
```

**Directory Purposes**:

- `core-concepts/`: Fundamental domain knowledge (principles, architectures, frameworks)
- `patterns/`: Reusable patterns and templates (code patterns, workflows, checklists)
- `decisions/`: Decision history and rationale (architecture decisions, tool choices)
- `external-links/`: Curated external resources (documentation, articles, tools)

### Knowledge README Template

Each knowledge directory includes a README with:

```markdown
---
title: "{Agent Name} Knowledge Base"
description: "Domain knowledge for {agent-name} agent"
category: "reference"
tags: ["knowledge", "agent-name"]
last_updated: "YYYY-MM-DD"
status: "published"
audience: "developers"
---

# {Agent Name} Knowledge Base

## Purpose

What this knowledge base provides...

## Directory Structure

### `core-concepts/`

What's in core concepts...

### `patterns/`

What's in patterns...

### `decisions/`

What's in decisions...

## Usage

How the agent uses this knowledge...
```

## Runtime Variables

Agents use runtime variables that are expanded when AIDA is installed:

| Variable | Expands To | Purpose |
|----------|-----------|---------|
| `${CLAUDE_CONFIG_DIR}` | `~/.claude` | User configuration directory |
| `${AIDA_HOME}` | `~/.aida` | AIDA installation directory |
| `${PROJECT_ROOT}` | Current git root | Project root directory |

**Example in Agent File**:

```markdown
This agent references its knowledge base at `${CLAUDE_CONFIG_DIR}/agents/code-reviewer/knowledge/`
```

**After Installation**:

```markdown
This agent references its knowledge base at `~/.claude/agents/code-reviewer/knowledge/`
```

**In Project Context**:

Agent automatically checks:

1. `${PROJECT_ROOT}/.claude/agents/code-reviewer/knowledge/` (project-specific)
2. `${CLAUDE_CONFIG_DIR}/agents/code-reviewer/knowledge/` (user-level)

## Installation and Setup

### Standard Installation

During AIDA installation (`./install.sh`):

```bash
# Agent templates copied to user configuration
templates/agents/{agent-name}/ → ~/.claude/agents/{agent-name}/

# Runtime variables expanded
${CLAUDE_CONFIG_DIR} → ~/.claude
${AIDA_HOME} → ~/.aida

# Knowledge directories created with generic templates
```

### Development Mode Installation

During development mode installation (`./install.sh --dev`):

```bash
# Agent templates symlinked for live editing
~/.claude/agents/{agent-name}/ → /path/to/dev/templates/agents/{agent-name}/

# Changes to templates immediately reflected
# No need to reinstall during agent development
```

### Project Initialization

When running `/workflow-init` in a project:

```bash
# Optional: Create project-specific agent directories
project/.claude/agents/code-reviewer/knowledge/
project/.claude/agents/tech-lead/knowledge/
# etc.

# Populated with project-specific knowledge over time
```

## Invoking Agents

### Internal Invocation (Task Tool)

Agents are invoked by Claude Code using the Task tool with `subagent_type` parameter:

```python
# Claude Code internal invocation
Task(
    task="Review this code for security issues",
    subagent_type="code-reviewer"
)
```

Users don't invoke agents directly - Claude Code decides when to use them based on task requirements.

### User-Initiated Workflows

Users trigger agent work through:

1. **Natural requests**: "Review my code" → Claude invokes `code-reviewer`
2. **Slash commands**: `/create-issue` → Command invokes `product-manager`
3. **Expert analysis**: `/expert-analysis` → Invokes multiple agents

### Agent Invocation Examples

**Code Review Request**:

```text
User: "Can you review this authentication code for security issues?"

Claude's Process:
1. Recognizes need for code review expertise
2. Invokes code-reviewer agent via Task tool
3. Agent loads knowledge from:
   - ~/.claude/agents/code-reviewer/knowledge/
   - project/.claude/agents/code-reviewer/knowledge/ (if exists)
4. Agent performs security-focused review
5. Returns findings to Claude
6. Claude presents results to user
```

**Architecture Design Request**:

```text
User: "Help me design a microservices architecture for this system"

Claude's Process:
1. Recognizes need for architecture expertise
2. Invokes tech-lead agent via Task tool
3. Agent analyzes requirements
4. Agent references architecture patterns from knowledge base
5. Agent proposes design with diagrams
6. Returns architecture specification to Claude
7. Claude presents design to user
```

**Documentation Creation Request**:

```text
User: "Create API documentation for developers and customers"

Claude's Process:
1. Recognizes multi-audience documentation need
2. Invokes technical-writer agent via Task tool
3. Agent determines audience-specific approaches
4. Agent generates separate docs for each audience
5. Returns documentation to Claude
6. Claude presents docs to user
```

## Creating New Agents

### Using /create-agent Command

The recommended way to create new agents:

```bash
# Interactive agent creation
/create-agent

# With initial description
/create-agent "API design specialist for RESTful systems"
```

The `claude-agent-manager` agent handles the creation process:

1. **Gathers Requirements**: Asks about purpose, responsibilities, knowledge needs
2. **Validates Input**: Ensures proper naming, checks for duplicates
3. **Creates Structure**: Agent file, knowledge directory, README
4. **Updates Documentation**: Adds agent to appropriate indexes

### Manual Agent Creation

If creating agents manually:

```bash
# 1. Create agent directory
mkdir -p ~/.claude/agents/my-agent/knowledge/{core-concepts,patterns,decisions}

# 2. Create agent definition file
cat > ~/.claude/agents/my-agent/my-agent.md << 'EOF'
---
name: my-agent
description: Brief description of when to use this agent
model: claude-sonnet-4.5
---

# My Agent

Agent instructions and responsibilities...
EOF

# 3. Create knowledge README
cat > ~/.claude/agents/my-agent/knowledge/README.md << 'EOF'
---
title: "My Agent Knowledge Base"
description: "Knowledge for my-agent"
category: "reference"
tags: ["knowledge", "my-agent"]
last_updated: "2025-10-06"
status: "published"
audience: "developers"
---

# My Agent Knowledge Base

Documentation of knowledge structure...
EOF
```

### Agent Creation Checklist

When creating a new agent, ensure:

- [ ] Proper frontmatter with all required fields
- [ ] Clear description of when to use the agent
- [ ] Knowledge directory structure created
- [ ] Knowledge README with proper frontmatter
- [ ] Agent knows how to reference its knowledge base
- [ ] Core responsibilities documented
- [ ] Example invocation patterns included
- [ ] Integration with related agents described

## Knowledge Management

### Populating Agent Knowledge

**User-Level Knowledge** (`~/.claude/agents/{name}/knowledge/`):

Add generic, reusable knowledge:

```bash
# Core concepts
~/.claude/agents/code-reviewer/knowledge/core-concepts/
├── security-best-practices.md
├── performance-patterns.md
└── code-quality-principles.md

# Patterns
~/.claude/agents/code-reviewer/knowledge/patterns/
├── review-checklists.md
└── feedback-templates.md

# Decisions
~/.claude/agents/code-reviewer/knowledge/decisions/
└── when-to-escalate-issues.md
```

**Project-Level Knowledge** (created by `/workflow-init`):

Add project-specific context:

```bash
# Created in project directory
project/.claude/agents/code-reviewer/knowledge/
├── README.md
├── standards/
│   ├── project-coding-standards.md
│   └── typescript-conventions.md
├── metrics/
│   └── performance-baselines.md
└── decisions/
    └── architecture-choices.md
```

### Knowledge Organization Best Practices

**Core Concepts**:

- Fundamental principles and theories
- Domain-specific terminology and definitions
- Conceptual frameworks and models
- Architecture overviews

**Patterns**:

- Reusable templates and checklists
- Code patterns and snippets
- Workflow templates
- Communication templates

**Decisions**:

- Historical context for major decisions
- Trade-off analyses
- Lessons learned
- Evolution of approaches

### Maintaining Knowledge Quality

**Keep Knowledge Current**:

- Update `last_updated` dates in frontmatter
- Remove obsolete information
- Document when patterns change

**Maintain Privacy**:

- User-level knowledge: No user-specific data
- Project-level knowledge: No secrets or credentials
- Use placeholders for sensitive information

**Ensure Discoverability**:

- Use clear, descriptive filenames
- Include proper frontmatter
- Cross-reference related knowledge
- Update knowledge indexes when adding files

## Best Practices

### When to Create New Agents

Create a new agent when:

- **Domain expertise needed**: Specialized knowledge required (security, performance, etc.)
- **Complex decision-making**: Multi-step reasoning with trade-offs
- **Persistent context**: Need to accumulate knowledge over time
- **Reusable across projects**: Logic applies to multiple use cases

Don't create an agent when:

- **Simple workflow**: Step-by-step process is sufficient (use command instead)
- **One-time task**: Won't be reused
- **No specialized knowledge**: General Claude capabilities sufficient

### Agent Design Principles

**Single Responsibility**:

- Each agent has one clear purpose
- Focused expertise area
- Well-defined boundaries

**Clear Invocation**:

- Obvious when to use this agent
- Distinct from other agents
- Documented with examples

**Knowledge-Driven**:

- Behavior informed by knowledge base
- Accumulates learnings over time
- Adapts to project context

**Composable**:

- Works well with other agents
- Clear delegation patterns
- Documented integration points

### Knowledge Base Design

**Balance Depth and Breadth**:

- Core concepts: Deep, comprehensive
- Patterns: Practical, reusable
- Decisions: Historical, contextual

**Maintain Separation**:

- Generic knowledge: User-level
- Project knowledge: Project-level
- No duplication between tiers

**Enable Discovery**:

- Clear directory structure
- Descriptive filenames
- Comprehensive indexes
- Cross-references

## Troubleshooting

### Agent Not Using Knowledge Base

**Problem**: Agent doesn't reference its knowledge during execution

**Solutions**:

1. **Check knowledge exists**:

   ```bash
   ls -la ~/.claude/agents/{agent-name}/knowledge/
   ```

2. **Verify agent references knowledge**:

   ```bash
   grep -i "knowledge" ~/.claude/agents/{agent-name}/{agent-name}.md
   ```

3. **Ensure proper frontmatter** in knowledge files

4. **Check agent instructions** mention knowledge usage

### Project Knowledge Not Loading

**Problem**: Agent ignores project-specific knowledge

**Solutions**:

1. **Verify project knowledge exists**:

   ```bash
   ls -la .claude/agents/{agent-name}/knowledge/
   ```

2. **Check you're in project root**:

   ```bash
   git rev-parse --show-toplevel
   ```

3. **Ensure proper directory structure** matches user-level template

4. **Review agent detection logic** in agent file

### Agent Not Being Invoked

**Problem**: Claude doesn't invoke agent for relevant tasks

**Solutions**:

1. **Check agent description** is clear about when to use

2. **Verify agent is installed**:

   ```bash
   ls ~/.claude/agents/
   ```

3. **Review invocation patterns** in agent documentation

4. **Ensure task matches agent's domain**

### Knowledge Files Not Found

**Problem**: Agent references missing knowledge files

**Solutions**:

1. **Create missing files** following template structure

2. **Check file paths** in agent instructions

3. **Verify runtime variables** were expanded during installation

4. **Re-run installation** if needed:

   ```bash
   ./install.sh  # or ./install.sh --dev
   ```

### Conflicting Knowledge

**Problem**: User-level and project-level knowledge conflict

**Resolution**:

- **Project knowledge takes precedence** by design
- Document differences in project knowledge README
- Consider moving project pattern to user-level if universally applicable

## Advanced Topics

### Multi-Agent Coordination

Some tasks require multiple agents working together:

**Example: Feature Implementation**:

1. `product-manager`: Creates PRD with requirements
2. `tech-lead`: Designs architecture and technical spec
3. `code-reviewer`: Reviews implementation code
4. `technical-writer`: Creates user documentation
5. `devops-engineer`: Sets up CI/CD for deployment

**Coordination Pattern**:

```text
User: "Implement real-time notifications feature"

Claude's Process:
1. Invokes product-manager for requirements
2. Invokes tech-lead for architecture design
3. Implements feature with code-reviewer oversight
4. Invokes technical-writer for documentation
5. Invokes devops-engineer for deployment setup
```

### Custom Knowledge Categories

Beyond `core-concepts/`, `patterns/`, `decisions/`, agents may add:

- `integrations/`: Third-party tool integrations
- `metrics/`: Performance baselines and measurements
- `templates/`: Reusable file templates
- `workflows/`: Multi-step procedures
- `troubleshooting/`: Common issues and solutions

### Agent Evolution

As agents accumulate knowledge, they improve over time:

**Learning Cycle**:

1. **Execute**: Agent performs task
2. **Document**: Record patterns, decisions, outcomes
3. **Refine**: Update knowledge base with learnings
4. **Improve**: Next invocation benefits from accumulated knowledge

**Knowledge Refinement**:

- Move effective project patterns to user-level knowledge
- Archive obsolete patterns
- Document evolution of approaches
- Maintain decision history

## Related Documentation

- [Commands Documentation](../commands/README.md) - Slash command reference
- [Workflows Documentation](../workflows/README.md) - Workflow templates
- [Knowledge Documentation](../knowledge/README.md) - System knowledge base
- [CLAUDE.md](../../CLAUDE.md) - Main project instructions

## See Also

- `/create-agent` - Create new agent interactively
- `/workflow-init` - Initialize project with agent directories
- `/expert-analysis` - Multi-agent collaborative analysis
- [Agent Manager Knowledge](./claude-agent-manager/knowledge/README.md) - Meta-agent patterns

---

**Note**: Agent templates in this directory are privacy-safe, generic templates. User-specific agents are installed to `~/.claude/agents/`, and project-specific knowledge accumulates in `{project}/.claude/agents/`.
