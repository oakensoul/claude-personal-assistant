---
name: aida-commands
version: 1.0.0
category: meta
description: Comprehensive knowledge about AIDA command architecture, structure, creation, and management
tags: [commands, meta-knowledge, architecture, two-tier, discovery]
used_by: [claude-agent-manager, aida]
last_updated: "2025-10-20"
---

# AIDA Commands Meta-Skill

This skill provides comprehensive knowledge about AIDA's command architecture, enabling intelligent assistance with command creation, validation, discovery, and management.

## Purpose

This meta-skill enables the AIDA system (via `claude-agent-manager`) to:

- **Understand** the complete command architecture and patterns
- **Create** new commands following established conventions
- **Validate** command structure and frontmatter
- **List** all available commands (via `list-commands.sh`)
- **Update** existing commands while maintaining consistency
- **Advise** on best practices for command organization
- **Filter** commands by category

## Command Architecture Overview

### What is an AIDA Command?

An AIDA command is a **slash command** (`/command-name`) that triggers specific functionality. Commands provide:

- Quick access to complex workflows
- Templated prompts for common tasks
- Integration with CLI scripts and agents
- Consistent interfaces for frequent operations
- Namespace organization (.aida prefix for framework commands)

### Commands vs. Agents vs. Skills

**Key Differences**:

| Aspect | Commands | Agents | Skills |
|--------|----------|--------|--------|
| **What** | User-invoked shortcuts | AI personas with reasoning | Knowledge modules |
| **Invocation** | Slash syntax (`/cmd`) | Task delegation | Loaded by agents |
| **Purpose** | Workflow automation | Problem-solving | Capabilities/knowledge |
| **User-facing** | Yes (direct invocation) | Yes (task assignment) | No (used by agents) |
| **Autonomy** | Execute prompt template | Reason and adapt | Static knowledge |

**Relationship**:

- Commands often **delegate** to agents
- Agents **use** skills to complete tasks initiated by commands
- Commands provide **user interface** to agentic workflows

**Example**:

- **Command**: `/start-work <issue>` (user invokes)
- **Agent**: `devops-engineer` (command delegates to)
- **Skill**: `git-workflow` (agent uses for execution)

### Two-Tier Architecture

AIDA uses a **two-tier discovery pattern** (defined in ADR-002):

1. **User-Level** (`~/.claude/commands/`): User-created custom commands
2. **Project-Level** (`./.claude/commands/`): Project-specific commands

**Namespace Separation**:

- **User commands**: Direct in `~/.claude/commands/` (e.g., `my-command.md`)
- **Framework commands**: In `~/.claude/commands/.aida/` namespace (e.g., `.aida/start-work.md`)

**Discovery Order**:

1. Check project-level first (`./.claude/commands/`)
2. Fall back to user-level (`~/.claude/commands/`)
3. Include both user and .aida namespace commands
4. No duplication (project can override user)

## File Structure

### Directory Layout

```text
User-Level Commands:
~/.claude/commands/
├── my-custom-command.md        # User command
├── project-setup.md            # User command
└── .aida/                      # Framework namespace
    ├── start-work.md           # AIDA framework command
    ├── open-pr.md              # AIDA framework command
    ├── implement.md            # AIDA framework command
    └── cleanup-main.md         # AIDA framework command

Project-Level Commands:
./.claude/commands/
├── deploy-staging.md           # Project-specific command
├── run-tests.md                # Project-specific command
└── .aida/                      # Can override framework commands
    └── start-work.md           # Project-specific override
```

### File Naming Convention

- **All commands**: `{command-name}.md` (no subdirectories per command)
- **Framework commands**: Placed in `.aida/` subdirectory for namespace separation
- **User commands**: Direct in `commands/` directory

**Why namespace separation?**:

- Prevents conflicts between user and framework commands
- Clear distinction of ownership
- Framework commands can be updated independently
- Users can override framework commands if needed

## Frontmatter Schema

### Required Fields

```yaml
---
name: command-name              # Lowercase, hyphen-separated
version: 1.0.0                  # Semantic versioning
description: Brief one-line description of command purpose
category: workflow              # One of 8 standard categories (REQUIRED)
---
```

### Category Taxonomy (Required)

**IMPORTANT**: Every command MUST have exactly ONE category from this list:

1. **workflow** - Development workflow automation (start-work, open-pr, implement, cleanup-main)
2. **analysis** - Code analysis, auditing, reviews, security (code-review, security-audit, compliance-check)
3. **meta** - System commands (agent-list, skill-list, command-list, create-agent, create-command)
4. **project** - Project setup, initialization, configuration (workflow-init, github-init, track-time)
5. **testing** - Test execution, validation, quality checks (test-plan)
6. **documentation** - Docs generation, updates, formatting (generate-docs)

**Note**: Additional categories (git, deployment) may be added in future as commands are created for those domains.

**Single category only** - Commands cannot belong to multiple categories. This forces clear categorization and simpler filtering.

### Optional Fields

```yaml
---
# Optional metadata
tags: [tag1, tag2, tag3]        # Searchable tags
scope: user|project|global      # Where command should be available
namespace: .aida                # Framework commands use .aida namespace

# Command behavior
args: "<arg1> <arg2>"           # Expected arguments
args_optional: "[option]"       # Optional arguments
requires_git: true              # Command requires git repository

# Integration
delegates_to: agent-name        # Agent this command delegates to
uses_skills: [skill1, skill2]   # Skills the delegated agent should use
cli_script: script-name.sh      # Associated CLI script (if any)

# Documentation
author: "Author Name"           # Command creator
created: "2025-10-20"           # Creation date
last_updated: "2025-10-20"      # Last modification
---
```

### Frontmatter Examples

**Minimal Command**:

```yaml
---
name: run-tests
version: 1.0.0
description: Execute project test suite
category: testing
---
```

**Full-Featured Framework Command**:

```yaml
---
name: start-work
version: 2.1.0
description: Begin work on a GitHub issue (creates branch, updates tracking)
category: workflow
namespace: .aida
tags: [github, workflow, issue-tracking, git]
scope: user
args: "<issue-number>"
requires_git: true
delegates_to: devops-engineer
uses_skills: [git-workflow, github-integration]
author: "AIDA Framework Team"
created: "2025-01-15"
last_updated: "2025-10-20"
---
```

**Project-Specific Command**:

```yaml
---
name: deploy-staging
version: 1.0.0
description: Deploy current branch to staging environment
category: deployment
scope: project
args: "[branch-name]"
requires_git: true
cli_script: deploy-to-staging.sh
author: "DevOps Team"
created: "2025-10-20"
last_updated: "2025-10-20"
---
```

## Command Categories Explained

### 1. Workflow

**Purpose**: Development workflow automation

**Examples**:

- `/start-work <issue>` - Begin work on issue
- `/implement` - Implement planned features
- `/open-pr` - Create pull request
- `/cleanup-main` - Post-merge cleanup

**When to use**: Commands that manage development lifecycle

### 2. Git

**Purpose**: Git operations and version control

**Examples**:

- `/commit` - Create git commit
- `/branch-cleanup` - Delete merged branches
- `/git-status` - Enhanced git status

**When to use**: Commands primarily focused on git operations

### 3. Project

**Purpose**: Project setup, initialization, configuration

**Examples**:

- `/aida-init` - Initialize AIDA configuration
- `/project-setup` - Set up new project
- `/workflow-init` - Initialize workflow config

**When to use**: Commands for project-level configuration

### 4. Analysis

**Purpose**: Code analysis, auditing, reviews

**Examples**:

- `/code-review` - Review code quality
- `/security-audit` - Security vulnerability scan
- `/pii-scan` - Scan for PII data
- `/cost-review` - Analyze costs

**When to use**: Commands that analyze code, data, or infrastructure

### 5. Deployment

**Purpose**: Deployment, release, environment management

**Examples**:

- `/deploy-staging` - Deploy to staging
- `/deploy-production` - Deploy to production
- `/rollback` - Rollback deployment

**When to use**: Commands that deploy or manage deployments

### 6. Testing

**Purpose**: Test execution, validation, quality checks

**Examples**:

- `/run-tests` - Execute test suite
- `/test-plan` - Generate test plan
- `/validate` - Run validation checks

**When to use**: Commands focused on testing and validation

### 7. Documentation

**Purpose**: Documentation generation, updates, formatting

**Examples**:

- `/generate-docs` - Generate documentation
- `/update-readme` - Update README file
- `/api-docs` - Generate API documentation

**When to use**: Commands that create or update documentation

### 8. Meta

**Purpose**: AIDA system commands

**Examples**:

- `/agent-list` - List available agents
- `/skill-list` - List available skills
- `/command-list` - List available commands
- `/aida-status` - Show AIDA status
- `/help` - Show help information

**When to use**: Commands that operate on AIDA itself

## Creating a New Command

### Step 1: Plan the Command

**Questions to answer**:

1. What task does this command accomplish?
2. What arguments does it need?
3. Which category does it belong to? (choose ONE)
4. Is it user-level (generic) or project-specific?
5. Does it delegate to an agent or invoke a script?
6. Is it a framework command (should go in .aida namespace)?

### Step 2: Choose Location

**For user-level command** (generic, reusable):

```bash
~/.claude/commands/{command-name}.md
```

**For framework command** (AIDA system):

```bash
~/.claude/commands/.aida/{command-name}.md
```

**For project-level command** (project-specific):

```bash
./.claude/commands/{command-name}.md
```

### Step 3: Create Command File

**Template Structure**:

```markdown
---
name: {command-name}
version: 1.0.0
description: {one-line description}
category: {one-of-eight-categories}
args: "<required-arg> [optional-arg]"
delegates_to: {agent-name}
uses_skills: [{skill1}, {skill2}]
---

# {Command Name}

## Purpose

{Explain what this command does and why it exists}

## Usage

```bash
/{command-name} {args}
```

**Arguments**:

- `<required-arg>`: {Description of required argument}
- `[optional-arg]`: {Description of optional argument}

**Examples**:

```bash
/{command-name} example-value
/{command-name} example-value --optional-flag
```

## Behavior

{Describe what happens when command executes}

### Steps

1. {Step 1 description}
2. {Step 2 description}
3. {Step 3 description}

### Expected Output

{What user should see when command completes}

## Delegation

**Delegates to**: `{agent-name}` agent

**Skills used**: `{skill1}`, `{skill2}`

**Prompt Template**:

```text
{The actual prompt that gets sent to the agent}

{Can include variable substitution}
{Can reference context or files}
```

## Error Handling

### Error 1: {Error Condition}

**Symptoms**: {How to recognize this error}

**Solution**: {How to fix it}

### Error 2: {Error Condition}

**Symptoms**: {How to recognize this error}

**Solution**: {How to fix it}

## Examples

### Example 1: {Scenario}

```bash
/{command-name} {example-args}
```

**Context**: {When you'd use this}

**Result**: {What happens}

### Example 2: {Scenario}

```bash
/{command-name} {example-args}
```

**Context**: {When you'd use this}

**Result**: {What happens}

## Related Commands

- `/{related-command-1}` - {Brief description}
- `/{related-command-2}` - {Brief description}

## Notes

{Any additional notes, warnings, or tips}

```bash

### Step 4: Validate Command

**Validation checklist**:

- [ ] Frontmatter contains all required fields
- [ ] Name is lowercase, hyphen-separated
- [ ] Version follows semantic versioning (X.Y.Z)
- [ ] Description is clear and concise
- [ ] Category is ONE of the 8 standard categories
- [ ] Arguments are documented clearly
- [ ] File naming follows conventions
- [ ] Markdown linting passes
- [ ] Command is discoverable by `list-commands.sh`
- [ ] If delegates to agent, agent exists
- [ ] If uses skills, skills exist
- [ ] If uses CLI script, script exists

### Step 5: Test Command

**Test procedure**:

1. Verify command appears in `/command-list`
2. Invoke command with sample arguments
3. Verify delegation works (if applicable)
4. Verify script execution works (if applicable)
5. Test error handling with invalid inputs
6. Verify output matches documentation

## Updating an Existing Command

### When to Update

- Adding new functionality or options
- Refining command behavior
- Fixing errors or bugs
- Improving documentation
- Responding to user feedback
- Changing delegation target
- Project requirements change

### Update Process

1. **Increment version**:
   - Patch (X.Y.Z+1): Bug fixes, doc improvements, minor changes
   - Minor (X.Y+1.0): New arguments/options, backward-compatible
   - Major (X+1.0.0): Breaking changes, argument changes

2. **Update `last_updated` field**

3. **Document changes** in command content or notes section

4. **Test changes** by invoking command

5. **Update related commands** if dependencies change

### Backward Compatibility

**User-level commands**: Maintain backward compatibility when possible

**Project-level commands**: Can break compatibility if project-specific

**Framework commands**: Strong backward compatibility requirement (affects all users)

## Validation Requirements

### Frontmatter Validation

**Required field checks**:

```bash
# Check for required fields
- name: ^[a-z][a-z0-9-]*$  # Lowercase, hyphen-separated
- version: ^\d+\.\d+\.\d+$  # Semantic versioning
- description: .{10,200}    # 10-200 characters
- category: ^(workflow|git|project|analysis|deployment|testing|documentation|meta)$  # One of 8
```

**Validation errors to catch**:

- Missing required fields
- Invalid name format (uppercase, spaces, special chars)
- Invalid version format (not semantic versioning)
- Empty or too-short description
- Invalid category (not one of the 8 standard categories)
- Multiple categories specified (only one allowed)

### Structural Validation

**File structure checks**:

- Command file exists at expected location
- File is markdown with .md extension
- Frontmatter is valid YAML
- Command content follows template structure
- No conflicting commands (user vs. project with same name)

### Content Validation

**Command content checks**:

- Markdown linting passes
- Frontmatter is valid YAML
- Command purpose is clearly documented
- Arguments are documented
- Usage examples are provided
- No hardcoded secrets or credentials
- If delegates to agent, agent name is valid
- If uses skills, skill names are valid
- If uses CLI script, script reference is correct

## Integration with list-commands.sh

### How Discovery Works

The `list-commands.sh` CLI script:

1. **Scans user-level**: `~/.claude/commands/` for `*.md` files (including `.aida/` subdirectory)
2. **Scans project-level**: `./.claude/commands/` for `*.md` files
3. **Parses frontmatter**: Extracts name, version, description, category
4. **Groups by category**: Primary organization by category
5. **Deduplicates**: Project commands override user commands with same name
6. **Formats output**:
   - Plain text table with category grouping (default)
   - JSON format (`--format json`)
7. **Supports filtering**: `--category <name>` filters to specific category

### What Gets Listed

**Per command, the script shows**:

- Name (with namespace prefix if .aida)
- Version
- Category
- Description
- Location (sanitized path: `${CLAUDE_CONFIG_DIR}` or `${PROJECT_ROOT}`)

### Category Filtering

**Filter by category**:

```bash
# Show only workflow commands
list-commands.sh --category workflow

# Show only meta commands
list-commands.sh --category meta

# Show all commands (no filter)
list-commands.sh
```

### Display Format

**Category-grouped display**:

```text
Global Commands (User-Level)
──────────────────────────────────────────────────

Workflow
  .aida/start-work      2.1.0   Begin work on GitHub issue
  .aida/implement       1.5.0   Implement planned features
  .aida/open-pr         1.3.0   Create pull request

Meta
  .aida/agent-list      1.0.0   List all available agents
  .aida/skill-list      1.0.0   List all available skills
  .aida/command-list    1.0.0   List all available commands

Testing
  run-tests             1.0.0   Execute project test suite

Project Commands
──────────────────────────────────────────────────

Deployment
  deploy-staging        1.0.0   Deploy to staging environment
  deploy-production     2.0.0   Deploy to production
```

### Symlink Handling

**Dev mode creates symlinks**:

- `~/.claude/commands/.aida/` → symlinks to `~/.aida/templates/commands/.aida/`
- `list-commands.sh` uses `realpath` to deduplicate
- Only shows canonical path, marks if symlinked

## Best Practices

### Naming Conventions

**✅ Good command names**:

- `start-work` (clear, verb-based)
- `open-pr` (concise, descriptive)
- `deploy-staging` (specific action)
- `security-audit` (clear purpose)

**❌ Bad command names**:

- `SW` (too abbreviated)
- `My_Command` (underscores, capitalization)
- `command-1` (generic, non-descriptive)
- `do-stuff` (vague)

### Description Guidelines

**✅ Good descriptions**:

- "Begin work on a GitHub issue (creates branch, updates tracking)"
- "Create pull request with version bumping and changelog updates"
- "Deploy current branch to staging environment"

**❌ Bad descriptions**:

- "Does stuff" (too vague)
- "A command that helps you do many things including..." (too long)
- "Work command" (no specificity)

### Category Selection Guidelines

**Choose the MOST SPECIFIC category**:

- If command does git operations → **git** (not workflow)
- If command deploys → **deployment** (not workflow)
- If command analyzes → **analysis** (not workflow)
- If command is about AIDA system → **meta** (not workflow)

**Only use workflow for**:

- Multi-step development workflows
- Commands that orchestrate multiple concerns
- Development lifecycle automation

**Examples**:

- `/start-work` → workflow (orchestrates git + issue tracking + branch creation)
- `/commit` → git (pure git operation)
- `/deploy-staging` → deployment (pure deployment)
- `/code-review` → analysis (pure code analysis)
- `/agent-list` → meta (AIDA system command)

### Scope Guidelines

**User-level commands** (in `~/.claude/commands/`):

- Generic, reusable across projects
- No project-specific context
- Broadly applicable
- Examples: `run-tests`, `commit`, `help`

**Framework commands** (in `~/.claude/commands/.aida/`):

- AIDA system commands
- Workflow orchestration
- Maintained by framework
- Examples: `start-work`, `agent-list`, `implement`

**Project-level commands** (in `./.claude/commands/`):

- Project-specific workflows
- Custom deployment procedures
- Company-specific processes
- Examples: `deploy-myapp`, `run-myapp-tests`, `myapp-audit`

### Argument Handling

**Document clearly**:

```yaml
args: "<issue-number> [branch-name]"
```

**In content**:

```markdown
## Usage

```bash
/start-work <issue-number> [branch-name]
```

**Arguments**:

- `<issue-number>` (required): GitHub issue number to work on
- `[branch-name]` (optional): Custom branch name (default: auto-generated)

```yaml

**Use angle brackets `<>` for required**, **square brackets `[]` for optional**

## Common Patterns

### Pattern 1: Agent Delegation Command

**Purpose**: Delegate complex task to specialized agent

**Structure**:

```yaml
---
name: code-review
category: analysis
delegates_to: code-reviewer
uses_skills: [code-quality, security-patterns]
---

# Code Review

Review code for quality, security, and best practices.

**Prompt**: You are the code-reviewer agent with code-quality and security-patterns skills. Please review the current changes for quality issues, security vulnerabilities, and adherence to best practices.
```

**When to use**: Complex tasks requiring agent reasoning

### Pattern 2: Script Execution Command

**Purpose**: Execute CLI script with arguments

**Structure**:

```yaml
---
name: deploy-staging
category: deployment
cli_script: deploy-to-staging.sh
args: "[branch-name]"
---

# Deploy to Staging

Deploy current branch to staging environment.

**Script**: `~/.claude/scripts/deploy-to-staging.sh [branch-name]`
```

**When to use**: Automated scripts, deployment, bulk operations

### Pattern 3: Hybrid Command

**Purpose**: Combine agent reasoning with script execution

**Structure**:

```yaml
---
name: start-work
category: workflow
delegates_to: devops-engineer
uses_skills: [git-workflow, github-integration]
cli_script: github-issue-fetch.sh
args: "<issue-number>"
---

# Start Work

1. Fetch issue details (script)
2. Create feature branch (agent + git-workflow skill)
3. Update issue tracking (agent + github-integration skill)
```

**When to use**: Workflows requiring both automation and intelligence

### Pattern 4: Templated Prompt Command

**Purpose**: Provide structured prompt template

**Structure**:

```yaml
---
name: write-tests
category: testing
---

# Write Tests

Please write comprehensive unit tests for the current changes. Ensure:

```text
- All public functions are tested
- Edge cases are covered
- Mocks are used for external dependencies
- Tests are clear and maintainable
```

Use the project's existing test framework and conventions.

```markdown

**When to use**: Structured tasks with clear requirements

## Troubleshooting

### Command Not Discovered

**Symptoms**: Command doesn't appear in `list-commands.sh` output

**Checks**:

1. File named correctly? (`{command-name}.md`)
2. In correct directory? (`~/.claude/commands/` or `./.claude/commands/`)
3. Frontmatter valid YAML?
4. Required fields present?
5. Category is one of the 8 standard categories?

**Fix**: Verify file location and frontmatter structure

### Command Not Invokable

**Symptoms**: Typing `/command-name` doesn't work

**Checks**:

1. Command discovered successfully?
2. Name matches exactly (case-sensitive)?
3. Namespace prefix correct? (use `.aida/` prefix for framework commands)
4. Claude Code loaded command definition?

**Fix**: Verify command name and reload if necessary

### Category Validation Fails

**Symptoms**: Pre-commit hook rejects command

**Checks**:

1. Category field present?
2. Category is ONE of the 8 standard categories?
3. No typos in category name?
4. Not using custom category?

**Fix**: Update category to one of: workflow, analysis, meta, project, testing, documentation

### Agent Delegation Fails

**Symptoms**: Command doesn't delegate to agent

**Checks**:

1. Agent name correct in frontmatter?
2. Agent exists and is discoverable?
3. Skills referenced exist?
4. Prompt template clear?

**Fix**: Verify agent configuration and skill availability

### Script Execution Fails

**Symptoms**: CLI script doesn't execute

**Checks**:

1. Script path correct in frontmatter?
2. Script exists in `~/.claude/scripts/`?
3. Script has execute permissions?
4. Arguments passed correctly?

**Fix**: Verify script installation and permissions

## Examples

### Example 1: Creating a Simple Command

```bash
# Create command file
cat > ~/.claude/commands/hello.md << 'EOF'
---
name: hello
version: 1.0.0
description: Simple hello world command
category: meta
---

# Hello Command

A simple test command that says hello.

## Usage

```bash
/hello
```

## Behavior

Prints a friendly greeting message.

**Prompt**: Please greet the user warmly and ask how you can help them today.
EOF

```bash

### Example 2: Creating a Workflow Command

```bash
# Create framework command
cat > ~/.claude/commands/.aida/start-work.md << 'EOF'
---
name: start-work
version: 2.1.0
description: Begin work on a GitHub issue (creates branch, updates tracking)
category: workflow
namespace: .aida
args: "<issue-number> [branch-name]"
requires_git: true
delegates_to: devops-engineer
uses_skills: [git-workflow, github-integration]
---

# Start Work

Begin work on a GitHub issue by creating a feature branch and updating issue tracking.

## Usage

```bash
/start-work <issue-number> [branch-name]
```

**Arguments**:

- `<issue-number>` (required): GitHub issue number
- `[branch-name]` (optional): Custom branch name (default: feature/issue-{number})

## Behavior

1. Fetch issue details from GitHub
2. Create feature branch from main
3. Update issue status to "In Progress"
4. Set up local tracking

**Delegates to**: `devops-engineer` agent with `git-workflow` and `github-integration` skills

**Prompt Template**:

```text
You are the devops-engineer agent with git-workflow and github-integration skills.

Task: Start work on GitHub issue #{issue-number}

Steps:
1. Fetch issue details using GitHub CLI
2. Create feature branch: {branch-name} (or auto-generate from issue)
3. Update issue status to "In Progress"
4. Confirm branch created and tracking set up

Please proceed step-by-step and report status at each stage.
```

## Related Commands

- `/open-pr` - Create pull request when work is complete
- `/cleanup-main` - Clean up after PR is merged

## Notes

- Requires GitHub CLI (`gh`) installed and authenticated
- Must be in git repository
- Issue must exist and be accessible
EOF

```bash

### Example 3: Creating a Project-Specific Command

```bash
# Create project command
cat > ./.claude/commands/deploy-staging.md << 'EOF'
---
name: deploy-staging
version: 1.0.0
description: Deploy current branch to staging environment
category: deployment
scope: project
args: "[branch-name]"
requires_git: true
cli_script: deploy-to-staging.sh
---

# Deploy to Staging

Deploy the current branch to the staging environment.

## Usage

```bash
/deploy-staging [branch-name]
```

**Arguments**:

- `[branch-name]` (optional): Branch to deploy (default: current branch)

## Behavior

1. Validate branch exists
2. Run tests
3. Build application
4. Deploy to staging
5. Run smoke tests
6. Report deployment status

**Script**: `~/.claude/scripts/deploy-to-staging.sh [branch-name]`

## Examples

### Deploy Current Branch

```bash
/deploy-staging
```

### Deploy Specific Branch

```bash
/deploy-staging feature/new-feature
```

## Error Handling

### Error: Tests Failed

**Symptoms**: Deployment aborted during test phase

**Solution**: Fix failing tests before deploying

### Error: Build Failed

**Symptoms**: Build process failed

**Solution**: Check build logs, fix build errors

## Related Commands

- `/run-tests` - Run test suite locally before deploying
- `/deploy-production` - Deploy to production (requires approval)

## Notes

- Only works in MyApp project
- Requires AWS credentials configured
- Staging environment: <https://staging.myapp.com>

EOF

```bash

### Example 4: Listing Commands

```bash
# List all commands
~/.claude/scripts/.aida/list-commands.sh

# List only workflow commands
~/.claude/scripts/.aida/list-commands.sh --category workflow

# JSON output
~/.claude/scripts/.aida/list-commands.sh --format json

# JSON output with category filter
~/.claude/scripts/.aida/list-commands.sh --category deployment --format json
```

## Integration with AIDA Commands

### Commands that Use This Skill

- `/command-list` - Lists all available commands
- `/command-list --category <name>` - Lists commands in specific category
- `/create-command` - Creates new command (future)
- `/update-command` - Updates existing command (future)

### How Commands Use This Skill

1. **Command invoked** by user (e.g., `/command-list --category workflow`)
2. **Command delegates** to `claude-agent-manager` agent
3. **Agent loads** this `aida-commands` skill for knowledge
4. **Agent invokes** `list-commands.sh --category workflow` CLI script
5. **Agent formats** and presents results using skill knowledge

## Skill Maintenance

### Updating This Skill

**When to update**:

- Command architecture changes
- Category taxonomy changes
- New patterns emerge
- Validation rules change
- CLI script changes
- User feedback suggests improvements

**Update process**:

1. Increment `version` field
2. Update `last_updated` field
3. Document changes in content
4. Test with `list-commands.sh`
5. Verify `claude-agent-manager` can use updated skill
6. Update category documentation if taxonomy changes

### Versioning

- **Patch** (1.0.X): Clarifications, examples, minor fixes
- **Minor** (1.X.0): New patterns, additional knowledge, compatible changes
- **Major** (X.0.0): Category taxonomy changes, structural changes, breaking updates

## Summary

This skill provides the foundational knowledge about AIDA commands:

- **Architecture**: Two-tier, file-based, frontmatter-driven, namespace-separated
- **Structure**: Single file per command, .aida namespace for framework commands
- **Categories**: 6 active categories (single category per command, expandable to 8+)
- **Creation**: Clear patterns for user, framework, and project commands
- **Validation**: Frontmatter, structure, content, category checks
- **Discovery**: Integration with `list-commands.sh`, category filtering
- **Patterns**: Delegation, script execution, hybrid, templated prompts
- **Best Practices**: Naming, categorization, scope, argument handling

**Next Steps**: Use this knowledge to create, validate, discover, and execute commands within the AIDA system.

---

**Version**: 1.0.0
**Last Updated**: 2025-10-20
**Maintained By**: AIDA Framework Team
