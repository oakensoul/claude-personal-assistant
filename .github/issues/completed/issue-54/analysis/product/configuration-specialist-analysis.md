---
title: "Configuration Specialist Analysis - Issue #54"
description: "Configuration design analysis for discoverability commands"
issue: 54
analyst: configuration-specialist
created: 2025-10-20
status: draft
---

# Configuration Specialist Analysis: Discoverability Commands

**Issue**: #54 - Implement discoverability commands (/agent-list, /skill-list, /command-list)
**Analyst**: configuration-specialist
**Date**: 2025-10-20

## 1. Domain-Specific Concerns

### Configuration & Metadata Structure

**Agent Metadata**:

- Agents use YAML frontmatter (name, description, model, color, temperature)
- Agent directory naming convention: kebab-case matches frontmatter `name` field
- Current count: 21 agent directories in templates/agents/
- Two-tier architecture: user-level (~/.claude/agents/) + project-level (./.claude/agents/)
- Knowledge bases may contain 100+ markdown files per agent

**Command Metadata**:

- Commands use YAML frontmatter (name, description, args)
- Command file naming: {name}.md in templates/commands/
- Current count: Commands exist but need inventory
- Variable types: Install-time ({{VAR}}) vs runtime (${VAR})
- Optional category metadata NOT currently in frontmatter

**Skills Metadata**:

- 177+ skills from Claude Code skills catalog
- No local storage - external catalog
- Unknown schema/structure without examination

### Metadata Concerns

**Missing Category Metadata**:

- Commands have no `category` field in frontmatter
- `/command-list --category` requires categorization scheme
- Options:

  1. Add `category` to command frontmatter (recommended)
  2. Infer from directory structure (templates/commands/{category}/{command}.md)
  3. Maintain separate category mapping file (config overhead)

**Agent Discovery Challenges**:

- Global agents: ~/.claude/agents/{name}/{name}.md
- Project agents: ./.claude/agents/{name}/{name}.md
- Validation: Ensure {name}.md exists (not just directory)
- Description extraction: Parse frontmatter from .md files

**Skills Discovery Challenges**:

- External catalog (not local files)
- Unknown schema format
- May require API call or catalog file access
- Formatting: Need consistent structure for display

### Configuration Requirements

**Directory Structure Validation**:

- Agent directories must contain {name}.md file
- Frontmatter must be valid YAML
- Required fields: name, description, model
- Optional fields: color, temperature

**Output Format Standardization**:

- Consistent table/list format across all three commands
- Columns: Name, Description, Source (global/project for agents)
- Category filtering for commands
- Human-readable vs machine-parseable output

## 2. Stakeholder Impact

### Who Is Affected

**Primary Users**:

- New AIDA users discovering what's available
- Experienced users finding specific agents/commands
- Developers creating new agents/commands (need to understand existing patterns)

**Secondary Users**:

- Documentation maintainers (automated catalog generation)
- CI/CD pipelines (validation of available resources)

### Value Provided

**User Experience**:

- Reduces friction: "What can AIDA do?" answered immediately
- Discoverability: Find relevant agent/command without reading docs
- Self-documentation: System describes itself accurately
- Confidence: Users know what tools are available

**Developer Experience**:

- Inventory validation: Ensure all agents/commands properly registered
- Category insights: Understand command organization
- Naming conflicts: Detect duplicate names
- Quality checks: Identify agents missing required metadata

### Risks & Downsides

**Configuration Drift**:

- Commands may be added without category metadata
- Agents may have inconsistent frontmatter
- Skills catalog may change externally without notice

**Performance**:

- Scanning 21+ agent directories with 100+ files each
- Parsing YAML frontmatter for every agent/command
- Skills catalog fetch (if external API)

**Maintenance Burden**:

- Category taxonomy needs governance
- Metadata schema may evolve
- Scripts need updating if structure changes

## 3. Questions & Clarifications

### Information Gaps

**Skills Catalog**:

- Where is the 177+ skills catalog stored?
- What is the schema/format?
- Is it local file or external API?
- How should skills be categorized?

**Command Categories**:

- Should category be added to frontmatter?
- What categories exist? (workflow, quality, security, operations, infrastructure, data)
- Who maintains category taxonomy?
- Should commands be allowed multiple categories?

**Agent Filtering**:

- Should /agent-list support filtering (e.g., by model, color)?
- Should it show agent count in knowledge base?
- Should it distinguish user-created vs framework agents?

**Output Format**:

- Table format (markdown, ASCII table, JSON)?
- Human-readable vs machine-parseable?
- Should output be sorted (alphabetical, by creation date)?
- Color-coded output in terminal?

### Decisions Needed

**Category Implementation**:

1. **Option A**: Add `category` field to command frontmatter (recommended)

   - Pros: Explicit, self-documenting, version-controlled
   - Cons: Migration required for existing commands

2. **Option B**: Directory-based (templates/commands/{category}/{command}.md)

   - Pros: File system organization, no frontmatter change
   - Cons: Restructure required, breaks existing paths

3. **Option C**: Separate category.json mapping file

   - Pros: No command file changes
   - Cons: Drift risk, maintenance overhead

**Skills Discovery Strategy**:

1. Locate skills catalog (file vs API)
2. Define skills schema if creating local catalog
3. Determine skills categorization approach

**Output Format Standard**:

1. Define table schema (columns, sorting)
2. Choose human-readable vs JSON option
3. Decide on color/formatting for terminal output

### Assumptions Requiring Validation

- Assumption: All agents have valid frontmatter with required fields
- Assumption: Agent {name} directory contains {name}.md file
- Assumption: Commands will accept category metadata addition
- Assumption: Skills catalog is accessible without authentication
- Assumption: Users want tabular output (not tree/hierarchical)

## 4. Recommendations

### Approach

#### 1. Command Category Implementation

#### Recommended: Add category to frontmatter

```yaml

---
name: create-issue
description: Create local issue drafts with standardized formatting
category: workflow
args: {}
---

```text

**Category Taxonomy** (based on commands/README.md analysis):

- `workflow` - Core development workflow (start-work, implement, open-pr)
- `quality` - Code review, testing, QA (code-review, script-audit, test-plan)
- `security` - Security and compliance (security-audit, compliance-check, pii-scan)
- `operations` - Incident, debugging, runbooks (incident, debug, runbook)
- `infrastructure` - AWS, GitHub, DevOps (aws-review, github-init)
- `data` - Data and analytics (metric-audit, cost-review, optimize-warehouse)
- `documentation` - Docs generation (generate-docs)
- `meta` - System commands (workflow-init, create-agent, create-command)

**Migration Strategy**:

1. Add category field to all existing command frontmatter
2. Update command creation template to include category
3. Validate category values during command scanning

#### 2. Script Design

**scripts/list-agents.sh**:

```bash

#!/usr/bin/env bash

# Scan global and project-level agents

# Output: Name | Description | Source | Model

# Check ~/.claude/agents/ (global)

# Check ./.claude/agents/ (project) if exists

# Parse frontmatter from {name}.md files

# Validate required fields exist

# Output sorted table

```text

**scripts/list-skills.sh**:

```bash

#!/usr/bin/env bash

# List Claude Code skills catalog

# Output: Name | Description | Category

# Decision needed: Locate skills catalog

# Parse skills schema

# Format as table

```text

**scripts/list-commands.sh**:

```bash

#!/usr/bin/env bash

# Scan global and project-level commands with optional category filter

# Output: Name | Description | Category

# Usage: list-commands.sh [--category workflow]

# Check ~/.claude/commands/ (global)

# Check ./.claude/commands/ (project) if exists

# Parse frontmatter from .md files

# Filter by category if provided

# Output sorted table

```text

#### 3. Output Format

**Standard Table Format** (all three commands):

```text

NAME                  DESCRIPTION                                    SOURCE/CATEGORY
--------------------------------------------------------------------------------
agent-name            Brief description of agent purpose             global
another-agent         Another agent description                      project

```text

**Category-Filtered Command Output**:

```text

$ /command-list --category workflow

NAME                  DESCRIPTION                                    CATEGORY
--------------------------------------------------------------------------------
start-work            Begin work on GitHub issue                     workflow
implement             Guided implementation workflow                 workflow
open-pr               Create pull request with versioning           workflow
cleanup-main          Post-merge cleanup                             workflow

```text

**JSON Output Option** (for automation):

```bash

list-agents.sh --format json

# Output: [{"name": "...", "description": "...", "source": "global"}]

```text

### Prioritization

**High Priority (Must-Have)**:

1. Add category field to command frontmatter (enables filtering)
2. Implement list-agents.sh with global + project scanning
3. Implement list-commands.sh with category filtering
4. Validate frontmatter parsing works reliably

**Medium Priority (Should-Have)**:

1. Implement list-skills.sh (depends on locating catalog)
2. Add JSON output format option (--format json)
3. Validate all existing commands have category metadata
4. Add color-coded terminal output

**Low Priority (Nice-to-Have)**:

1. Agent filtering by model/color
2. Show knowledge base file count per agent
3. Tree/hierarchical output format
4. Auto-detect outdated agent metadata

### What to Avoid

**Anti-Patterns**:

- **Directory restructuring**: Don't move commands into category subdirectories (breaks existing paths)
- **External dependencies**: Don't require network calls for basic listing (skills catalog exception)
- **Hardcoded lists**: Don't maintain manual registries (scan file system instead)
- **Complex parsing**: Don't implement full YAML parser (use grep/sed for frontmatter)
- **Inconsistent formats**: Each command should use same table layout
- **Silent failures**: Scripts must report missing/invalid frontmatter

**Performance Pitfalls**:

- Don't recursively scan entire knowledge bases (only read {name}.md files)
- Don't parse every markdown file (only frontmatter)
- Cache results if called repeatedly (future optimization)

**Configuration Smells**:

- Multiple sources of truth (frontmatter + separate config file)
- Unconstrained category values (use enum validation)
- Missing required fields (validate on scan)

## Summary

This feature requires adding configuration metadata (category) to commands while maintaining backward compatibility. The shell scripts should:

1. **Scan file system** (not rely on registries)
2. **Parse frontmatter** (validate schema)
3. **Support filtering** (category for commands)
4. **Standardize output** (consistent table format)
5. **Handle two-tier architecture** (global + project-level)

**Key Risk**: Skills catalog location/format unknown - requires investigation.

**Key Decision**: Category implementation approach (frontmatter recommended).

**Next Steps**:

1. Locate skills catalog and examine schema
2. Define category taxonomy and add to command frontmatter
3. Implement parsing scripts with validation
4. Test against all existing agents/commands
5. Update command creation template to include category

---

**Related Files**:

- `/Users/rob/Develop/oakensoul/claude-personal-assistant/templates/agents/README.md`
- `/Users/rob/Develop/oakensoul/claude-personal-assistant/templates/commands/README.md`
- `/Users/rob/Develop/oakensoul/claude-personal-assistant/.github/issues/in-progress/issue-54/README.md`
