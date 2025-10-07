---
title: "Command Templates"
description: "Slash command templates for AIDA workflow automation"
category: "reference"
tags: ["commands", "templates", "workflows", "automation"]
last_updated: "2025-10-06"
status: "published"
audience: "developers"
---

# Command Templates

Slash command templates for AIDA (Agentic Intelligence Digital Assistant) workflow automation. These commands provide pre-built workflows for common development tasks that can be invoked with `/command-name` in Claude conversations.

## What Are Slash Commands?

Slash commands are markdown-based templates that expand to full prompts at runtime. When you type `/command-name` in a Claude conversation, the command file is read and its content replaces your message, providing Claude with detailed instructions for executing a complex workflow.

**Key Benefits**:

- **Reusable Workflows**: Capture complex multi-step processes in a single command
- **Consistent Execution**: Commands follow the same pattern every time
- **Composable**: Commands can delegate to agents for specialized work
- **Privacy-Safe**: Templates are generic and contain no sensitive data
- **Version Controlled**: Commands live in your codebase and evolve with your project

## Command Structure

Each command is a markdown file with YAML frontmatter:

```markdown
---
name: command-name
description: What this command does
args:
  argument-name:
    description: What this argument does
    required: true|false
---

# Command Name

Command documentation and instructions for Claude...
```

### Frontmatter Fields

- **name**: Command identifier (kebab-case, matches filename without .md)
- **description**: Brief description shown in command lists
- **args**: Optional arguments the command accepts (can be empty `{}`)

### Runtime Variables

Commands can reference these variables which are resolved by Claude at runtime:

- `${CLAUDE_CONFIG_DIR}`: User's Claude configuration directory (`~/.claude/`)
- `${PROJECT_ROOT}`: Current project root directory
- `${AIDA_HOME}`: AIDA installation directory (`~/.aida/`)

## Available Commands

AIDA includes 8 core commands for workflow automation:

### 1. create-agent

**Purpose**: Create new Claude Code agents with proper structure and documentation

**Invocation**:

```bash
/create-agent
/create-agent "Agent for handling database migrations"
```

**What It Does**:

- Interactive wizard for agent creation
- Generates agent file with proper frontmatter
- Creates knowledge directory structure
- Updates CLAUDE.md with agent documentation

**When to Use**: When you need a specialized agent for a specific domain (database, API design, deployment, etc.)

**Type**: Interactive, agent-delegating (delegates to `claude-agent-manager`)

### 2. create-command

**Purpose**: Create new slash commands with proper structure and workflow definition

**Invocation**:

```bash
/create-command
/create-command "Command for analyzing performance metrics"
```

**What It Does**:

- Interactive wizard for command creation
- Generates command file with frontmatter and workflow
- Defines arguments (required and optional)
- Specifies agent delegation (if applicable)

**When to Use**: When you have a repeatable workflow that should be a first-class command

**Type**: Interactive, agent-delegating (delegates to `claude-agent-manager`)

### 3. create-issue

**Purpose**: Create local issue drafts with standardized formatting for later GitHub publishing

**Invocation**:

```bash
/create-issue
```

**What It Does**:

- Interactive issue creation wizard
- Collects title, description, type, milestone
- Auto-suggests labels based on content
- Stores draft locally (gitignored)
- Optionally consults domain-specific agents

**When to Use**: When you want to create a GitHub issue but need time to refine it locally first

**Type**: Interactive, self-contained (optionally delegates to `devops-engineer` for type analysis)

**Key Feature**: Drafts are gitignored - refine locally, publish when ready

### 4. expert-analysis

**Purpose**: Multi-agent expert analysis to generate PRD and technical specifications

**Invocation**:

```bash
/expert-analysis
```

**What It Does**:

- Orchestrates Product Manager and Tech Lead agents
- Coordinates specialist agents (product and technical)
- Generates Product Requirements Document (PRD)
- Creates Technical Specification (TECH_SPEC)
- Facilitates Q&A iteration for open questions
- Produces implementation summary

**When to Use**: After `/start-work` on complex issues requiring comprehensive analysis

**Type**: Automated orchestration, multi-agent (PM, Tech Lead, specialists)

**Prerequisites**: Requires `/workflow-init` and `/start-work` to be run first

### 5. generate-docs

**Purpose**: AI-powered documentation generation with intelligent scope detection

**Invocation**:

```bash
/generate-docs
/generate-docs --branch --type api
/generate-docs --project --type user --audience customers
/generate-docs --files "src/components/**/*.tsx" --type developer
```

**What It Does**:

- Detects current context (branch, issue)
- Prompts for scope (branch changes, entire project, specific files)
- Prompts for documentation type (API, user guide, integration, developer, README)
- Prompts for target audience (developers, customers, partners)
- Delegates to `technical-writer` agent
- Generates comprehensive documentation with frontmatter
- Stages files for git commit

**When to Use**: After implementing a feature, before creating a PR

**Type**: Automated, agent-delegating (delegates to `technical-writer`)

**Arguments**:

- `--branch`: Document changes in current branch only (default on feature branches)
- `--project`: Document entire project
- `--files <pattern>`: Document specific file pattern
- `--type <type>`: Documentation type (api, user, integration, developer, readme)
- `--audience <audience>`: Target audience (developers, customers, partners)

### 6. publish-issue

**Purpose**: Publish local issue drafts to GitHub

**Invocation**:

```bash
/publish-issue add-dark-mode
/publish-issue add-dark-mode refactor-auth fix-login-bug
/publish-issue --milestone 0.1.0
/publish-issue --all
```

**What It Does**:

- Reads local draft metadata
- Validates milestone exists on GitHub
- Creates GitHub issues with proper labels
- Deletes local drafts on success
- Preserves drafts if publishing fails (for retry)

**When to Use**: When local issue draft is ready to publish to GitHub

**Type**: Automated, self-contained

**Arguments**:

- `<slug>`: One or more issue slugs to publish
- `--milestone X.Y`: Publish all drafts for a specific milestone
- `--all`: Publish all drafts

### 7. track-time

**Purpose**: Log development time with automatic activity detection

**Invocation**:

```bash
/track-time 2.5h
/track-time 3h --date yesterday
/track-time 2h --date 2025-10-01
/track-time 1.5h --issue 34
/track-time 3h --interactive
```

**What It Does**:

- Creates/checks out time-tracking branch (`time-tracking/{developer}/{date}`)
- Analyzes git commits for the date
- Fetches GitHub issue details
- Auto-allocates time across issues (or prompts interactively)
- Writes to monthly log file (`.time-tracking/YYYY-MM.md`)
- Updates summary statistics (`.time-tracking/summary.json`)
- Compares actual vs. estimated time

**When to Use**: At the end of a work session to log time spent

**Type**: Automated with optional interactivity, self-contained

**Arguments**:

- `<duration>`: Time spent (required) - formats: "2.5h", "2.5", "90m", "1h30m"
- `--date <value>`: Date for entry (default: today, accepts "yesterday" or YYYY-MM-DD)
- `--issue <number>`: Attribute all time to specific issue
- `--interactive`: Manually allocate time across issues

### 8. workflow-init

**Purpose**: Initialize workflow configuration for a project with interactive setup

**Invocation**:

```bash
/workflow-init
```

**What It Does**:

- Interactive configuration wizard
- Configures issue tracking directories
- Configures time tracking settings
- Configures branch naming conventions
- Configures pull request automation (versioning, reviewers, merge strategy)
- Configures issue creation preferences
- Creates user-level Product Manager agent (reused across all projects)
- Creates user-level Tech Lead agent (reused across all projects)
- Creates project-specific PM/Tech Lead knowledge
- Configures expert analysis workflow
- Generates `workflow-config.json`

**When to Use**: When setting up a new project or when reconfiguring workflow preferences

**Type**: Interactive, self-contained (creates agents as part of setup)

**Key Feature**: Two-tier agent configuration - user-level philosophy (all projects) + project-specific requirements (this project only)

## Command Types

### Interactive vs. Automated

**Interactive Commands**:

- Prompt user for information during execution
- Examples: `/create-agent`, `/create-command`, `/create-issue`, `/workflow-init`
- Use case: When decisions or input are needed

**Automated Commands**:

- Execute with minimal user interaction
- Examples: `/generate-docs`, `/publish-issue`, `/expert-analysis`, `/track-time`
- Use case: When workflow is well-defined and repeatable

### Agent-Delegating vs. Self-Contained

**Agent-Delegating**:

- Invoke specialized agents to perform work
- Examples: `/create-agent`, `/create-command` (→ `claude-agent-manager`), `/generate-docs` (→ `technical-writer`), `/expert-analysis` (→ PM, Tech Lead, specialists)
- Use case: When specialized expertise is needed

**Self-Contained**:

- Execute workflow directly without agent delegation
- Examples: `/publish-issue`, `/track-time`, `/create-issue` (with optional delegation)
- Use case: When workflow is straightforward and doesn't require specialized knowledge

## Installation

Commands are installed to `~/.claude/commands/` during AIDA installation:

```bash
# Normal install
./install.sh

# Dev mode (symlinks for live editing)
./install.sh --dev
```

After installation, commands are immediately available in any Claude conversation.

## Creating New Commands

### Option 1: Use the Command Wizard (Recommended)

```bash
/create-command "Command for analyzing test coverage"
```

The wizard will guide you through:

1. Command name and description
2. Required and optional arguments
3. Workflow steps
4. Agent delegation (if needed)
5. Error handling
6. Success criteria

### Option 2: Manual Creation

Create a new file in `templates/commands/`:

```markdown
---
name: my-command
description: What my command does
args:
  input:
    description: Input parameter
    required: true
---

# My Command

Command instructions for Claude...

## Workflow

1. Step one
2. Step two
3. Step three

## Examples

```bash
/my-command value
```

## Notes

- Important note 1
- Important note 2

## Best Practices

### When to Create a Command

**Create a Command When**:

- You have a multi-step workflow you run repeatedly
- The workflow has a clear start and end
- The workflow follows the same pattern each time
- You want to ensure consistency across executions
- The workflow can be parameterized with arguments

**Create an Agent Instead When**:

- You need ongoing consultation throughout a conversation
- The work requires deep domain expertise
- The agent should maintain context across multiple tasks
- You need the agent available for ad-hoc questions

### Writing Effective Commands

1. **Clear Instructions**: Write detailed step-by-step workflows for Claude
2. **Error Handling**: Specify what to do when things go wrong
3. **User Feedback**: Include progress messages and summaries
4. **Idempotency**: Design commands to be safely re-runnable
5. **Validation**: Check prerequisites before executing
6. **Documentation**: Include examples and usage notes

### Command Naming

- Use kebab-case: `create-issue`, `generate-docs`, `track-time`
- Be descriptive but concise: `publish-issue` not `pub-iss`
- Use verbs: `create-agent` not `agent-creator`
- Avoid abbreviations: `generate-docs` not `gen-docs`

## Command Workflow Integration

Commands work together to form complete development workflows:

### Feature Development Workflow

```bash
# 1. Initialize project workflow (one-time setup)
/workflow-init

# 2. Create and publish issue
/create-issue
# ... refine draft locally ...
/publish-issue add-feature-x

# 3. Start work on issue
/start-work 42

# 4. Run expert analysis (optional, for complex issues)
/expert-analysis

# 5. Implement feature
# ... write code ...

# 6. Generate documentation
/generate-docs

# 7. Track time
/track-time 3.5h

# 8. Create pull request
/open-pr

# 9. Clean up after merge
/cleanup-main
```

### Agent Creation Workflow

```bash
# Create a specialized agent
/create-agent "Agent for GraphQL API design and optimization"

# Create a command that uses the agent
/create-command "Command for reviewing GraphQL schemas"
```

### Documentation Workflow

```bash
# Document feature changes
/generate-docs --branch --type api

# Document entire project
/generate-docs --project --type developer

# Document specific components
/generate-docs --files "src/components/**/*.tsx" --type readme
```

## Runtime Behavior

### Command Expansion

When you invoke a command, Claude:

1. Reads the command file from `~/.claude/commands/{name}.md`
2. Resolves runtime variables (`${CLAUDE_CONFIG_DIR}`, etc.)
3. Replaces your message with the command content
4. Processes the command as a normal prompt

### Error Handling

Commands should specify error handling for common scenarios:

- Missing prerequisites (tools, configuration, active issues)
- Validation failures (invalid input, missing files)
- External service errors (GitHub API, git operations)
- Permission errors (file system, git)

### Success Criteria

Each command should define what successful execution looks like:

- Files created or modified
- Git operations completed
- External resources created (GitHub issues, PRs)
- User feedback provided

## Related Documentation

- **Agent System**: See `.claude/agents/README.md` for agent documentation
- **Workflow Guide**: See `docs/workflows/` for complete workflow guides
- **Contributing**: See `docs/CONTRIBUTING.md` for development guidelines

## Troubleshooting

### Command Not Found

If `/command-name` doesn't work:

1. Verify command exists: `ls ~/.claude/commands/`
2. Check command name matches file name (without .md)
3. Ensure AIDA is properly installed: `./install.sh`

### Command Fails to Execute

If command execution fails:

1. Check prerequisites (GitHub CLI, git, project configuration)
2. Verify runtime variables resolve correctly
3. Check for missing agents (if command delegates to agents)
4. Review error messages for specific issues

### Commands Missing After Install

If commands aren't available after installation:

1. Re-run installation: `./install.sh`
2. Check installation directory: `ls ~/.claude/commands/`
3. Verify symlinks (dev mode): `ls -la ~/.claude/commands/`

## Future Enhancements

Planned improvements to the command system:

- **Command Aliases**: Short aliases for frequently used commands
- **Command Composition**: Chain commands together
- **Command History**: Track command usage and success rates
- **Command Validation**: Pre-flight checks before execution
- **Command Templates**: Templates for creating new commands

---

**Remember**: Commands are powerful workflow automation tools. Use them to capture and standardize your development processes, ensuring consistency and reducing cognitive load.
