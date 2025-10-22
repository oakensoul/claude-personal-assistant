---
name: install-agent
description: Install a global two-tier agent into the current project with intelligent project scanning and knowledge generation
agent: claude-agent-manager
model: sonnet
args:
  agent_name:
    description: Agent name to install (or 'list' to see available agents, or '--all' to install all)
    required: false
version: 1.0.0
category: meta
---

# Install Agent Command

Installs a global two-tier agent into the current project by creating project-specific configuration at `.claude/project/context/{agent}/index.md` with automatically generated knowledge based on project scanning.

This command is executed by the `claude-agent-manager` agent.

## Directory Structure

- **User-level agents**: `~/.claude/agents/{agent}/{agent}.md` (generic knowledge, shared across all projects)
- **Project-level configs**: `.claude/project/context/{agent}/index.md` (project-specific context, created in current working directory)

## Usage

```bash
/install-agent [agent-name]
/install-agent list
/install-agent --all
```

## Arguments

- **agent_name** (optional): Name of the agent to install. If not provided, will show interactive list.
  - Use `list` to see available two-tier agents
  - Use `--all` to install all available two-tier agents
  - Use agent name directly (e.g., `data-engineer`, `sql-expert`, `aws-cloud-engineer`)

## Examples

```bash
# Interactive mode (shows list of agents)
/install-agent

# Install specific agent
/install-agent data-engineer

# List available agents
/install-agent list

# Install all two-tier agents
/install-agent --all
```

## Workflow

### 0. Detect Project Directory

**Determine project root and config location:**

```bash
# Check if we're in a project directory
if [ -d ".git" ]; then
  PROJECT_ROOT=$(git rev-parse --show-toplevel)
elif [ -f "dbt_project.yml" ] || [ -f "cdk.json" ] || [ -f "package.json" ]; then
  PROJECT_ROOT=$(pwd)
else
  # Warn: Not clearly in a project, but allow current directory
  PROJECT_ROOT=$(pwd)
fi

# Project-specific config location
CLAUDE_PROJECT_CONFIG="${PROJECT_ROOT}/.claude"
AGENTS_GLOBAL_DIR="${CLAUDE_PROJECT_CONFIG}/project/context"
```

**Validation:**

- If not in a recognizable project type, warn but allow installation
- Create `.claude/` directory if it doesn't exist
- All project-level agent configs will be created in `${AGENTS_GLOBAL_DIR}/{agent}/`

**Note:** This is different from the user-level config at `~/.claude/` which contains user-level agent definitions.

### 1. Detect Available Two-Tier Agents

Scan `~/.claude/agents/` for agents with two-tier architecture:

**Detection Criteria**:

- Agent definition file exists: `~/.claude/agents/{agent}/{agent}.md`
- Agent description or content mentions "two-tier" or "Tier: 2-tier"
- Agent has user-level knowledge base: `~/.claude/agents/{agent}/knowledge/`

**Known Two-Tier Agents**:

- `data-engineer` - Data engineering, orchestration, dbt, ELT pipelines
- `sql-expert` - SQL query optimization across multiple platforms
- `aws-cloud-engineer` - AWS infrastructure, CDK, CloudFormation
- `system-architect` - System architecture, C4 models, ADRs, Kimball modeling
- `datadog-observability-engineer` - DataDog monitoring and observability
- `product-manager` - Product management (if user-level agent exists)
- `tech-lead` - Technical leadership (if user-level agent exists)

### 2. Parse Command Arguments

**If no argument provided**:

- Display interactive list of available agents (numbered)
- Allow user to select by number or name
- Option to install multiple agents (comma-separated)
- Option to cancel

**If `list` provided**:

- Display table of available agents with:
  - Agent name
  - Version (from agent frontmatter)
  - Description
  - Installation status in current project (installed/not installed/outdated)
- Exit after display

**If `--all` provided**:

- Install all detected two-tier agents
- Show progress for each agent
- Skip agents already installed (unless outdated)
- Prompt for upgrade if version mismatch detected

**If agent name provided**:

- Validate agent exists and is two-tier
- Check if already installed
- Proceed with installation

### 3. Check Installation Status

For the selected agent(s):

**Check if already installed**:

- Look for `.claude/project/context/{agent}/index.md` in the current project directory

**If exists**:

- Read `agent_version` from frontmatter
- Compare with version in `~/.claude/agents/{agent}/{agent}.md`
- Determine status:
  - **Up to date**: Versions match
  - **Outdated**: Project version < agent version
  - **Unknown**: No version in agent definition

**Prompt user**:

```text
Agent '{agent}' is already installed in this project.

Current version: 1.0.0
Available version: 1.2.0

Options:
  (u) Upgrade to latest version
  (r) Reinstall current version (regenerate knowledge)
  (s) Skip (keep existing)
  (c) Cancel

Choice [u/r/s/c]:
```

**If upgrading**:

- Backup existing index.md to `index.md.backup.{timestamp}`
- Regenerate with latest knowledge
- Update `agent_version` in frontmatter

### 4. Scan Project Context

**Detect Project Type**:

Run intelligent project scanning to understand context:

**dbt Project Detection**:

```bash
# Check for dbt project
if [ -f "dbt_project.yml" ]; then
  PROJECT_TYPE="dbt"
  # Extract project name from dbt_project.yml
  DBT_PROJECT_NAME=$(grep "^name:" dbt_project.yml | awk '{print $2}')
  # Scan for sources
  SOURCES=$(find models -name "sources.yml" -o -name "_sources.yml" 2>/dev/null)
  # Detect profiles
  if [ -f "profiles.yml" ]; then
    PROFILES="$(grep -A 5 "^  target:" profiles.yml)"
  fi
fi
```

**AWS/CDK Project Detection**:

```bash
# Check for CDK project
if [ -f "cdk.json" ]; then
  PROJECT_TYPE="aws-cdk"
  # Extract app entry point
  CDK_APP=$(jq -r '.app' cdk.json)
  # Scan for stack files
  STACKS=$(find lib -name "*-stack.ts" -o -name "*-stack.js" 2>/dev/null)
fi

# Check for CloudFormation
if [ -d "cloudformation" ] || [ -f "template.yaml" ]; then
  PROJECT_TYPE="aws-cloudformation"
fi
```

**Software Project Detection**:

```bash
# Node.js/JavaScript
if [ -f "package.json" ]; then
  TECH_STACK+=("node.js")
  PACKAGE_NAME=$(jq -r '.name' package.json)
fi

# Python
if [ -f "pyproject.toml" ] || [ -f "setup.py" ]; then
  TECH_STACK+=("python")
fi

# Documentation scan
if [ -d "docs" ]; then
  DOCS_FILES=$(find docs -type f -name "*.md" | head -10)
fi
```

**Scan Documentation**:

```bash
# Look for relevant documentation
ARCHITECTURE_DOCS=$(find docs -name "*architecture*" -o -name "*design*" 2>/dev/null)
README_FILES=$(find . -maxdepth 2 -name "README.md" -o -name "readme.md" 2>/dev/null)
```

**Technology Stack Detection**:

```bash
# Detect tools and frameworks
[ -f ".sqlfluff" ] && TECH_STACK+=("sqlfluff")
[ -f "docker-compose.yml" ] && TECH_STACK+=("docker")
[ -d ".github/workflows" ] && TECH_STACK+=("github-actions")
[ -f "Airflowfile" ] || [ -d "dags" ] && TECH_STACK+=("airflow")
```

### 5. Generate Project-Specific Knowledge

**Agent-Specific Knowledge Generation**:

#### For data-engineer

**If dbt project detected**:

```markdown
---
title: "Data Engineer - {Project Name} Configuration"
project: "{project-name}"
agent: "data-engineer"
agent_version: "{version-from-agent-definition}"
created: "{current-date}"
last_updated: "{current-date}"
scope: "project-only"
---

# Data Engineer - {Project Name}

Project-specific pipeline architecture, orchestration, source systems, and dbt configuration.

## Project Overview

- **Type**: dbt + {detected-platform} data warehouse
- **Orchestration**: {detected-orchestration-tool}
- **Ingestion**: {detected-ingestion-tools}
- **Transformation**: dbt
- **BI Platform**: {placeholder-or-detected}

## Pipeline Architecture

### Orchestration Strategy
**Current**: {detected-from-.github/workflows-or-dags}
- **Tool**: {GitHub Actions | Airflow | Prefect | Dagster}
- **Workflow Count**: {count-of-workflow-files}
- **Strategy**: {placeholder - needs manual update}

### Build Schedules

**TODO**: Define build schedules for your project
- Critical builds (high-frequency)
- Standard marts (hourly/daily)
- Batch processing (nightly)

## Source Systems

### Active Connections

**TODO**: Document your source systems:
1. **{source-name}** ({connection-type})
   - Purpose: {description}
   - Sync Mode: {CDC | Polling | Batch}
   - Frequency: {schedule}

{repeat-for-each-detected-source}

## dbt Configuration

### Target Environments

**Detected from profiles.yml**:

```yaml
{paste-relevant-profiles-config}
```

### Project Structure

**Detected from dbt_project.yml**:

- Project name: {dbt-project-name}
- Models directory: {models-path}
- {other-relevant-config}

### Tagging Strategy

**TODO**: Document your tagging strategy for selective builds

- Domain tags (finance, marketing, etc.)
- Layer tags (staging, intermediate, marts)
- Build frequency tags (critical, standard, batch)

## Architecture References

**Detected Documentation**:
{list-files-found-in-docs/}

**Configuration Files**:

- dbt project: `dbt_project.yml`
- profiles: `profiles.yml`
- workflows: `.github/workflows/` {or-other-orchestration}

## Related Project Knowledge

- **sql-expert**: {platform} SQL optimization, dbt model query tuning
- **system-architect**: Dimensional modeling, layering architecture

```text
(End of dbt project template)
```

**If NOT dbt project**:

```markdown
# Data Engineer - {Project Name}

This project does not appear to be a dbt project.

## Project Overview

**Detected Technologies**:
{list-detected-tech-stack}

**Documentation**:
{list-found-docs}

## Setup Instructions

To enable data-engineer agent for this project, please document:

1. **Pipeline Architecture**:
   - What orchestration tool do you use?
   - How are data pipelines scheduled?
   - What is the data flow?

2. **Source Systems**:
   - What data sources does this project integrate?
   - How is data ingested?

3. **Transformation Layer**:
   - What transformation tool/framework is used?
   - Are there any custom data processing scripts?

4. **Target Systems**:
   - Where does processed data go?
   - What BI tools or applications consume the data?

Update this file with project-specific information to enable context-aware assistance.
```

### sql-expert

**If dbt project with .sqlfluff**:

```markdown
---
title: "SQL Expert - {Project Name} Configuration"
project: "{project-name}"
agent: "sql-expert"
agent_version: "{version}"
created: "{current-date}"
last_updated: "{current-date}"
scope: "project-only"
---

# SQL Expert - {Project Name}

Project-specific SQL standards, platform configuration, and performance benchmarks.

## Platform Configuration

### Primary Platform: {Snowflake | PostgreSQL | BigQuery | Redshift}
**Detected from**: {.sqlfluff dialect or profiles.yml}

- **Purpose**: {Data warehouse | Application database | Analytics}
- **Account/Database**: {detected-or-placeholder}

### Key Platform Features in Use

**TODO**: Document platform-specific features used in this project:
- {QUALIFY, FLATTEN, jsonb, nested/repeated, DISTKEY/SORTKEY, etc.}

## Project SQL Standards

### SQLFluff Configuration
**Detected from .sqlfluff**:
```ini
{paste-relevant-.sqlfluff-config}
```

### CTE Naming Conventions

**TODO**: Document your CTE naming patterns:

- `base_*` - Initial CTEs pulling from sources
- `renamed` - Column renaming layer
- `filtered` - WHERE clause filters
- `joined` - JOIN operations
- `aggregated` - GROUP BY aggregations
- `final` - Final CTE before SELECT

### SQL Formatting Standards

**TODO**: Document project-specific SQL standards:

- Column naming conventions
- Date/timestamp handling
- Business terminology preferences

## Performance Benchmarks

### Query Performance Targets

**TODO**: Define your performance SLAs:

- Critical queries (dashboards): < {X} seconds
- Standard queries (reports): < {X} seconds
- Heavy analytics: < {X} minutes

## Architecture References

**Detected Documentation**:
{list-relevant-docs}

**Configuration Files**:

- SQLFluff config: `.sqlfluff`
- dbt project: `dbt_project.yml` {if-exists}

```text
(End of sql-expert with sqlfluff template)
```

**If NO .sqlfluff**:

```markdown
# SQL Expert - {Project Name}

## Platform Configuration

**Primary Platform**: {Unknown - please specify}

**TODO**: To enable sql-expert agent for this project, document:

1. **Platform**: Which SQL platform do you use? (Snowflake, PostgreSQL, BigQuery, Redshift)
2. **SQL Standards**: Are there coding standards or style guides?
3. **Performance Targets**: What are acceptable query performance benchmarks?
4. **Common Patterns**: Are there project-specific SQL patterns or anti-patterns?

Update this file with project-specific information to enable context-aware assistance.
```

### aws-cloud-engineer

**If CDK project detected**:

```markdown
---
title: "AWS Cloud Engineer - {Project Name} Configuration"
project: "{project-name}"
agent: "aws-cloud-engineer"
agent_version: "{version}"
created: "{current-date}"
last_updated: "{current-date}"
scope: "project-only"
---

# AWS Cloud Engineer - {Project Name}

Project-specific AWS infrastructure, CDK stacks, and resource configurations.

## Project Overview

- **Type**: AWS CDK Infrastructure
- **CDK App**: {detected-from-cdk.json}
- **Deployment Tool**: AWS CDK

## Infrastructure Architecture

### CDK Stacks

**Detected Stacks**:
{list-detected-stack-files}

**TODO**: Document stack purposes:
1. **{stack-name}**:
   - Purpose: {description}
   - Resources: {list-main-resources}
   - Dependencies: {other-stacks}

### AWS Accounts and Environments

**TODO**: Document your AWS environments:
- **Production**: Account ID {placeholder}, Region {placeholder}
- **Staging**: Account ID {placeholder}, Region {placeholder}
- **Development**: Account ID {placeholder}, Region {placeholder}

### Resource Naming Conventions

**TODO**: Document naming patterns:
- Resource prefix: {placeholder}
- Environment suffix: {placeholder}
- Tagging strategy: {placeholder}

## Architecture References

**Detected Documentation**:
{list-architecture-docs}

**CDK Configuration**:
- CDK config: `cdk.json`
- Stacks: {list-stack-locations}
```

**If NO CDK**:

```markdown
# AWS Cloud Engineer - {Project Name}

This project does not appear to use AWS CDK.

**TODO**: Document your AWS infrastructure approach:
- Do you use CloudFormation, Terraform, or other IaC?
- What AWS services does this project use?
- How is infrastructure deployed?

Update this file to enable aws-cloud-engineer agent for this project.
```

#### For system-architect

**Always create**:

```markdown
---
title: "System Architect - {Project Name} Configuration"
project: "{project-name}"
agent: "system-architect"
agent_version: "{version}"
created: "{current-date}"
last_updated: "{current-date}"
scope: "project-only"
---

# System Architect - {Project Name}

Project-specific architectural context and documentation pointers.

## Project Type

**Detected Type**: {Software | Data | Hybrid}

**Technology Stack**:
{list-detected-technologies}

## Architecture Patterns in Use

**TODO**: Document architectural patterns used in this project:
- [ ] Microservices
- [ ] Event-driven
- [ ] Domain-driven design
- [ ] Layered architecture
- [ ] Kimball dimensional modeling (for data projects)
- [ ] Other: {specify}

## Architecture Documentation

**Recommended Structure**:

```text
docs/architecture/
├── c4-system-context.md      # System context diagram
├── c4-container.md            # Container diagram
├── c4-component.md            # Component diagram (optional)
├── decisions/                 # Architecture Decision Records
│   ├── README.md             # ADR index
│   ├── adr-001-*.md          # Individual ADRs
│   └── adr-002-*.md
└── specifications/
    ├── non-functional-requirements.md
    └── integration-specifications.md
```

**Detected Documentation**:
{list-existing-architecture-docs}

**TODO**: Create missing architecture documentation:

- [ ] C4 system context diagram
- [ ] C4 container diagram
- [ ] Architecture Decision Records (ADRs)
- [ ] Non-functional requirements
- [ ] Integration specifications

## Integration Points

**TODO**: Document external system integrations:

- {System Name}: {Purpose} via {Protocol/Method}

## Non-Functional Requirements

**TODO**: Define NFRs for this project:

- **Scalability**: {targets}
- **Performance**: {SLAs}
- **Security**: {requirements}
- **Reliability**: {SLAs}
- **Maintainability**: {standards}

## Architecture References

**Documentation**:

- Architecture docs: `docs/architecture/` {if-exists}
- README: `README.md`

**Related Agents**:

- **tech-lead**: Implementation standards
- **data-engineer**: Pipeline architecture (if data project)
- **aws-cloud-engineer**: Cloud infrastructure (if AWS project)

```text
(End of system-architect template)
```

### datadog-observability-engineer

**Create monitoring configuration template**:

```markdown
---
title: "DataDog Observability Engineer - {Project Name} Configuration"
project: "{project-name}"
agent: "datadog-observability-engineer"
agent_version: "{version}"
created: "{current-date}"
last_updated: "{current-date}"
scope: "project-only"
---

# DataDog Observability Engineer - {Project Name}

Project-specific DataDog monitoring configuration and observability patterns.

## Project Overview

**Project Type**: {detected-project-type}
**Infrastructure**: {AWS | GCP | Azure | On-premises}

## Monitoring Strategy

**TODO**: Document your monitoring approach:

### Service-Level Objectives (SLOs)

- **{Service/Component Name}**:
  - Availability: {target}%
  - Latency (p99): < {X}ms
  - Error rate: < {X}%

### Alert Strategy

**Critical Alerts** (PagerDuty):
- {Define critical alert conditions}

**High Alerts** (Slack @channel):
- {Define high-priority alert conditions}

**Medium Alerts** (Slack #channel):
- {Define medium-priority alert conditions}

## DataDog Configuration

**TODO**: Document DataDog setup for this project:

### Tagging Strategy

**Standard Tags**:
- `env:{environment}`
- `service:{service-name}`
- `version:{version}`
- Custom: {project-specific-tags}

### Dashboards

**Required Dashboards**:
- [ ] Service health overview
- [ ] Infrastructure metrics
- [ ] Application performance (APM)
- [ ] Business metrics
- [ ] {Project-specific dashboards}

### Instrumentation

**Services to Monitor**:
{list-detected-services-or-components}

**TODO**: Document DataDog instrumentation:
- Lambda functions: {DataDog Lambda layer version}
- ECS tasks: {DataDog agent sidecar configuration}
- {Other services}: {Instrumentation approach}

## Cost Optimization

**TODO**: Document cost optimization strategies:
- Log sampling rate: {percentage}
- Metric cardinality limits: {strategy}
- APM trace retention: {duration}

## Architecture References

**Infrastructure Code**:
{list-relevant-infrastructure-files}
```

### 6. Create Project-Level Configuration

**Create directory structure**:

```bash
# Create in current project directory
mkdir -p ".claude/project/context/{agent}"
mkdir -p ".claude/project/context/{agent}/knowledge" # Optional, for future use
```

**Write index.md**:

- Use agent-specific template generated in step 5
- Include frontmatter with version tracking
- Populate with detected project information
- Add placeholders for manual updates

**Set permissions**:

```bash
chmod 644 ".claude/project/context/{agent}/index.md"
```

### 7. Display Installation Summary

**Success message**:

```text
✓ Installed {agent} agent for project: {project-name}

Agent Configuration:
- Agent: {agent}
- Version: {version}
- Project: {project-name}
- Type: {detected-project-type}

Created:
- .claude/project/context/{agent}/index.md

Detected Context:
- Platform: {platform}
- Technology Stack: {comma-separated-list}
- Documentation: {count} files found

Next Steps:
1. Review the generated configuration:
   cat .claude/project/context/{agent}/index.md

2. Update TODO sections with project-specific information:
   - {list-key-todos-from-template}

3. Invoke the agent to test:
   {Example invocation based on agent type}

4. (Optional) Add additional knowledge files:
   .claude/project/context/{agent}/knowledge/

The {agent} agent is now aware of your project context!
```

**If installing multiple agents**:

```text
✓ Installed 3 agents for project: {project-name}

Summary:
✓ data-engineer (v1.0.0) - dbt project detected
✓ sql-expert (v1.0.0) - Snowflake platform detected
✓ system-architect (v1.1.0) - Architecture docs template created

Total agents installed: 3
Review configurations in: .claude/project/context/

Next steps: Review and update TODO sections in each index.md
```

## Agent-Specific Scanning Logic

### data-engineer Scanner

**Files to scan**:

- `dbt_project.yml` - Project name, model paths, vars
- `profiles.yml` - Target environments, warehouse config
- `.github/workflows/` - Orchestration patterns
- `dags/` - Airflow DAGs
- `models/sources.yml` - Source systems
- `docs/` - Pipeline documentation

**Extract**:

- dbt project name
- Target environments (prod, dev, build)
- Orchestration tool and workflow count
- Source systems (from sources.yml)
- Technology stack (Snowflake, BigQuery, Redshift from dialect)

### sql-expert Scanner

**Files to scan**:

- `.sqlfluff` - Dialect, formatting rules
- `profiles.yml` - Database platform
- `dbt_project.yml` - dbt integration
- Database connection strings in code

**Extract**:

- SQL platform (Snowflake, PostgreSQL, BigQuery, Redshift)
- SQLFluff configuration
- Formatting standards (indentation, keywords case)
- CTE naming patterns (from existing SQL files)

### aws-cloud-engineer Scanner

**Files to scan**:

- `cdk.json` - CDK app entry point
- `lib/*-stack.ts` - CDK stack files
- `template.yaml` - CloudFormation templates
- `terraform/` - Terraform files (if present)
- `docs/architecture/` - Infrastructure docs

**Extract**:

- CDK app configuration
- Stack names and purposes
- AWS services in use
- Deployment tool (CDK, CloudFormation, Terraform)

### system-architect Scanner

**Files to scan**:

- `docs/architecture/` - Existing architecture docs
- `README.md` - Project overview
- `dbt_project.yml` - If data project
- `package.json`, `pyproject.toml` - If software project
- Technology markers (frameworks, languages)

**Extract**:

- Project type (software, data, hybrid)
- Technology stack
- Existing architecture documentation
- Architecture patterns in use

### datadog-observability-engineer Scanner

**Files to scan**:

- `lib/*-stack.ts` - Infrastructure code (Lambda, ECS)
- `serverless.yml` - Serverless framework
- `docker-compose.yml` - Services to monitor
- `.github/workflows/` - CI/CD monitoring points

**Extract**:

- Services/components to monitor
- Infrastructure type (Lambda, ECS, EC2, containers)
- Existing monitoring configuration

## Version Tracking Schema

### Agent Definition Frontmatter

**User-level agent** (`~/.claude/agents/{agent}/{agent}.md`):

```yaml
---
name: agent-name
version: 1.0.0               # NEW: Semantic version
description: Agent description
model: claude-sonnet-4.5
color: blue
temperature: 0.7
---
```

**Version format**: `MAJOR.MINOR.PATCH` (semantic versioning)

- **MAJOR**: Breaking changes to agent capabilities or interface
- **MINOR**: New features, enhanced knowledge, backward-compatible
- **PATCH**: Bug fixes, documentation updates, minor improvements

### Project Configuration Frontmatter

**Project-level index** (`.claude/project/context/{agent}/index.md` in current project):

```yaml
---
title: "{Agent Name} - {Project Name} Configuration"
project: "{project-name}"
agent: "{agent-name}"
agent_version: "1.0.0"       # Version of agent at installation time
created: "2025-10-15"
last_updated: "2025-10-15"
scope: "project-only"
---
```

**Tracking**:

- `agent_version` tracks which version of the agent was used to generate this config
- Compare with current agent version to detect upgrades available
- Backup old config before upgrading to preserve manual customizations

## Error Handling

**Agent not found**:

```text
ERROR: Agent '{agent}' not found.

Available two-tier agents:
- data-engineer (v1.0.0)
- sql-expert (v1.0.0)
- aws-cloud-engineer (v1.2.0)
- system-architect (v1.1.0)

Run: /install-agent list
```

**Agent is not two-tier**:

```text
ERROR: Agent '{agent}' does not support two-tier architecture.

This agent is user-level only and does not require project installation.
It works globally across all projects without project-specific configuration.

Two-tier agents available:
- data-engineer
- sql-expert
- aws-cloud-engineer
```

**Not in a project directory**:

```text
ERROR: Not in a project directory.

The /install-agent command must be run from within a project directory.

Current directory: {cwd}

To install an agent:
1. Navigate to your project directory (cd /path/to/project)
2. Run: /install-agent {agent}
```

**Project config directory doesn't exist**:

```text
WARNING: Project Claude config directory does not exist.

Creating: .claude/

This directory will contain project-specific agent configurations.
(Location: {absolute-path-to-project}/.claude/)
```

**Installation failed**:

```text
ERROR: Failed to install {agent} agent.

Reason: {error-message}

Troubleshooting:
- Check write permissions for .claude/ in current project directory
- Ensure agent definition exists: ~/.claude/agents/{agent}/{agent}.md
- Check disk space availability
- Verify you're in a valid project directory

Please resolve the issue and try again.
```

## Success Criteria

- Agent-specific index.md created with proper frontmatter
- Project context intelligently detected and documented
- Version tracking properly initialized
- Relevant project files scanned and referenced
- TODO sections clearly marked for manual updates
- Installation summary displayed with next steps
- Agent immediately usable with project context

## Related Commands

- `/create-agent` - Create a new user-level agent
- `/workflow-init` - Initialize project workflow configuration
- `/expert-analysis` - Run multi-agent analysis using installed agents

## Integration Notes

- Works with two-tier agent architecture (user-level + project-level)
- Scans project files to generate intelligent initial configuration
- Tracks agent versions for upgrade management
- Creates project-specific knowledge that complements user-level knowledge
- Enables context-aware agent invocation within projects

## Future Enhancements

**Upgrade Management** (future `/upgrade-agent` command):

- Detect when agent version in `~/.claude/agents/` > project version
- Show changelog between versions
- Safely upgrade project configuration
- Preserve manual customizations

**Knowledge Sync** (future enhancement):

- Sync project knowledge back to user-level patterns
- Identify reusable patterns from project-specific work
- Build knowledge base over time

**Validation** (future enhancement):

- Validate that TODOs are completed
- Check for stale agent configurations
- Suggest updates when project structure changes

## Notes

- **Intelligent, not perfect**: Generated knowledge is a starting point, not a complete solution
- **TODO-driven**: Clearly marks sections needing manual updates
- **Context-aware**: Uses project scanning to populate relevant information
- **Version-tracked**: Enables upgrade path for future improvements
- **Preserves manual work**: Backups existing config before regenerating
- **Idempotent**: Can be run multiple times safely (prompts for action)

**Related Files**:

- User-level agents: `~/.claude/agents/{agent}/{agent}.md` (shared across all projects)
- Project-level config: `.claude/project/context/{agent}/index.md` (in current project directory)

**Commands**: `/install-agent`, `/create-agent`, `/workflow-init`

**Agents**: claude-agent-manager (executes this command)
