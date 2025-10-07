---
title: "Templates Directory"
description: "Version-controlled baseline templates for AIDA agents and commands"
category: "meta"
tags: ["templates", "installation", "baseline", "agents", "commands"]
last_updated: "2025-10-06"
status: "published"
audience: "developers"
---

# Templates Directory

This directory contains **version-controlled baseline templates** for AIDA's agents and commands. These templates serve as the source of truth for AIDA installations, providing privacy-safe, generic configurations that can be customized by users.

## Purpose

Templates exist to solve four key challenges:

1. **Version Control**: Maintain a canonical, version-controlled source of truth for all AIDA components
2. **Installation Source**: Provide clean baseline configurations for new AIDA installations
3. **Update Mechanism**: Enable users to refresh their configurations with the latest improvements
4. **Privacy Safety**: Ensure all shared templates contain no user-specific data, paths, or learned patterns

## Directory Structure

```text
templates/
├── README.md                    # This file
├── agents/                      # Agent definition templates
│   ├── claude-agent-manager/
│   │   ├── claude-agent-manager.md
│   │   └── knowledge/
│   │       ├── README.md
│   │       ├── core-concepts/
│   │       ├── patterns/
│   │       └── decisions/
│   ├── code-reviewer/
│   ├── devops-engineer/
│   ├── product-manager/
│   ├── tech-lead/
│   └── technical-writer/
├── commands/                    # Command templates
│   ├── create-agent.md
│   ├── create-command.md
│   ├── create-issue.md
│   ├── expert-analysis.md
│   ├── generate-docs.md
│   ├── publish-issue.md
│   ├── track-time.md
│   └── workflow-init.md
└── documents/                   # Document templates
    ├── PRD_TEMPLATE.md
    └── TECH_SPEC_TEMPLATE.md
```

## Template Categories

### Agents (`agents/`)

Agent templates define specialized AI personas that handle specific domains:

- **claude-agent-manager**: Meta-agent for creating and managing other agents
- **code-reviewer**: Code review, quality assurance, best practices validation
- **devops-engineer**: Infrastructure, deployment, monitoring, CI/CD
- **product-manager**: Requirements, user stories, roadmap planning
- **tech-lead**: Architecture, technical decisions, team coordination
- **technical-writer**: Documentation creation for multiple audiences

Each agent template includes:

- **Agent definition file** (`{agent-name}.md`): Complete agent specification with frontmatter, capabilities, usage guidelines
- **Knowledge directory** (`knowledge/`): Structured knowledge base with core concepts, patterns, and decisions
- **Knowledge index** (`knowledge/README.md`): Organized index of agent-specific knowledge

### Commands (`commands/`)

Command templates define workflow automations and project management tools:

- **create-agent.md**: Interactive agent creation with proper structure
- **create-command.md**: Scaffold new workflow commands
- **create-issue.md**: Create standardized GitHub issue drafts
- **expert-analysis.md**: Multi-agent analysis for requirements and specifications
- **generate-docs.md**: Automated documentation generation
- **publish-issue.md**: Publish local issue drafts to GitHub
- **track-time.md**: Time tracking and allocation across issues
- **workflow-init.md**: Initialize workflow configuration for projects

### Documents (`documents/`)

Document templates provide standardized formats for project artifacts:

- **PRD_TEMPLATE.md**: Product Requirements Document template
- **TECH_SPEC_TEMPLATE.md**: Technical Specification template

## Variable Substitution

Templates use a **hybrid variable substitution strategy** with two types of variables that are processed at different times. This ensures templates remain privacy-safe, platform-agnostic, and context-aware.

### Two Types of Variables

#### 1. Install-Time Variables (`{{VAR}}`)

These variables are substituted by `sed` during installation (`./install.sh`). They are replaced with actual values when templates are copied from `templates/` to `~/.claude/`.

**Syntax:** `{{VAR_NAME}}`

**Supported variables:**

| Variable | Description | Example Value |
|----------|-------------|---------------|
| `{{AIDA_HOME}}` | AIDA installation directory | `/Users/username/.aida` |
| `{{CLAUDE_CONFIG_DIR}}` | Claude configuration directory | `/Users/username/.claude` |
| `{{HOME}}` | User's home directory | `/Users/username` |

**When to use:** For user-specific paths that are fixed at installation and don't change.

**Example in template:**

```markdown
Reference the knowledge base at `{{CLAUDE_CONFIG_DIR}}/knowledge/`
```

**After installation:**

```markdown
Reference the knowledge base at `/Users/username/.claude/knowledge/`
```

#### 2. Runtime Variables (`${VAR}`)

These variables use standard bash syntax and are resolved by Claude Code when commands execute. They remain as variables in the installed files.

**Syntax:** `${VAR_NAME}` or `$(command)`

**Supported variables:**

| Variable | Description | Resolved At Runtime |
|----------|-------------|---------------------|
| `${PROJECT_ROOT}` | Current project root directory | `/path/to/current/project` |
| `${GIT_ROOT}` | Git repository root | `/path/to/git/repo` |
| `$(date +%Y-%m-%d)` | Command substitution | Current date |
| Any bash variable | Standard bash variables | Environment-specific |

**When to use:** For context-specific values that change based on where/when the command runs.

**Example in template and installed file:**

```markdown
Create documentation at `${PROJECT_ROOT}/docs/README.md`
```

**This remains unchanged after installation and resolves when the command executes.**

### Why Two Types?

This hybrid approach provides:

1. **Privacy Safety**: Templates contain no hardcoded user paths
2. **Platform Agnostic**: Works across different operating systems
3. **User Customization**: Fixed paths are set once at installation
4. **Context Awareness**: Runtime variables adapt to current project/environment
5. **Flexibility**: Best of both worlds - fixed user config + dynamic context

### Variable Usage Guidelines

**Use install-time variables (`{{VAR}}`) for:**

- User home directory paths
- AIDA installation location
- Claude configuration directory
- Paths that never change after installation

**Use runtime variables (`${VAR}`) for:**

- Project-specific paths
- Git repository locations
- Dynamic timestamps or dates
- Environment-dependent values
- Paths that change based on context

**Examples:**

```markdown
# ✓ CORRECT: Install-time for user config
Read agent config from `{{CLAUDE_CONFIG_DIR}}/agents/tech-lead.md`

# ✓ CORRECT: Runtime for project path
Create file at `${PROJECT_ROOT}/docs/architecture.md`

# ✓ CORRECT: Mixed usage
Copy template from `{{AIDA_HOME}}/templates/` to `${PROJECT_ROOT}/docs/`

# ✗ WRONG: Hardcoded path
Read config from `/Users/oakensoul/.claude/agents/tech-lead.md`

# ✗ WRONG: Using runtime syntax for user paths in templates
Read config from `${CLAUDE_CONFIG_DIR}/agents/tech-lead.md`
```

### Installation Processing

During `./install.sh`:

1. **Template files** in `templates/` contain both `{{VAR}}` and `${VAR}` syntax
2. **Install-time variables** (`{{VAR}}`) are replaced by `sed` with actual paths
3. **Runtime variables** (`${VAR}`) are preserved as-is in installed files
4. **Installed files** in `~/.claude/` have concrete user paths + runtime variables

Example transformation:

**Before (template):**

```markdown
Read from `{{CLAUDE_CONFIG_DIR}}/knowledge/` and write to `${PROJECT_ROOT}/docs/`
```

**After (installed):**

```markdown
Read from `/Users/username/.claude/knowledge/` and write to `${PROJECT_ROOT}/docs/`
```

## Installation Flow

### How Templates Are Used

When a user runs `./install.sh`, the installation process:

1. **Creates directories**:
   - `~/.aida/` - Framework installation (copy or symlink in dev mode)
   - `~/.claude/` - User configuration directory

2. **Copies templates**:
   - Agents: `templates/agents/` → `~/.claude/agents/`
   - Commands: `templates/commands/` → `~/.claude/commands/`

3. **Resolves variables**:
   - Claude Code processes templates at runtime
   - Variables are substituted based on actual environment
   - User-specific paths are dynamically generated

4. **Generates entry point**:
   - Creates `~/CLAUDE.md` with links to user configuration
   - Includes agent invocations and command references

### Development Mode

Development mode (`./install.sh --dev`) uses symlinks for live editing:

```bash
# Framework symlink (for template development)
~/.aida/ -> /path/to/claude-personal-assistant/

# User config still copied (to prevent accidental commits)
~/.claude/ (copied from templates)
```

This allows template developers to edit files in the repository and see changes immediately.

## Privacy and Security

### Privacy Validation

All templates are validated for privacy issues using `scripts/validate-templates.sh`:

```bash
# Run privacy validation
./scripts/validate-templates.sh

# Verbose output for debugging
./scripts/validate-templates.sh --verbose

# CI/CD quiet mode
./scripts/validate-templates.sh --quiet
```

### What Gets Checked

The validation script detects:

- ✅ **Hardcoded paths**: Absolute paths with specific usernames
- ✅ **Usernames**: Specific user identifiers
- ✅ **Email addresses**: Personal or organizational emails (except example.com)
- ✅ **Credentials**: API keys, tokens, passwords, secrets
- ✅ **Learned patterns**: User-specific project references or terminology

### What Should Be In Templates

**✓ ALLOWED:**

- Generic instructions and documentation
- Runtime variables (`${CLAUDE_CONFIG_DIR}`, `${HOME}`, etc.)
- Example placeholders (`user@example.com`, `{project-name}`)
- Technical patterns and best practices
- Workflow procedures and guidelines

**✗ NOT ALLOWED:**

- Hardcoded absolute paths
- Real usernames or email addresses
- API keys or credentials
- User-specific learned patterns
- Private project references

## Updating Templates

### Archiving Active Configurations

When agents or commands are improved through use, updates can be archived back to templates:

1. **Test changes** in your active configuration (`~/.claude/`)
2. **Verify privacy** - remove any user-specific data
3. **Replace variables** - use `${CLAUDE_CONFIG_DIR}` instead of hardcoded paths
4. **Copy to templates** - update the appropriate template file
5. **Validate** - run `./scripts/validate-templates.sh`
6. **Commit** - version control the improved template

### Template Update Workflow

```bash
# 1. Make improvements in your active config
vim ~/.claude/agents/tech-lead/tech-lead.md

# 2. Copy to templates (after removing user-specific data)
cp ~/.claude/agents/tech-lead/tech-lead.md templates/agents/tech-lead/

# 3. Replace hardcoded paths with variables
# Change: /Users/oakensoul/.claude/
# To: ${CLAUDE_CONFIG_DIR}/

# 4. Validate privacy
./scripts/validate-templates.sh --verbose

# 5. Commit if validation passes
git add templates/agents/tech-lead/
git commit -m "feat(templates): improve tech-lead agent with <feature>"
```

### Version Control Best Practices

- **Test first**: Always test changes in active config before updating templates
- **Privacy check**: Run validation before committing
- **Clear commits**: Describe what improved in the template
- **Breaking changes**: Document any breaking changes in commit messages
- **User migration**: Provide migration guides for significant template changes

## Contributing New Templates

### Adding a New Agent Template

1. **Create agent directory structure**:

```bash
mkdir -p templates/agents/{agent-name}/knowledge/{core-concepts,patterns,decisions}
```

2. **Create agent definition** (`templates/agents/{agent-name}/{agent-name}.md`):

```markdown
---
name: agent-name
description: Brief description of agent purpose
model: claude-sonnet-4.5
color: blue
temperature: 0.7
---

# Agent Name

[Agent documentation following template standards...]
```

3. **Create knowledge index** (`templates/agents/{agent-name}/knowledge/README.md`):

```markdown
---
title: "{Agent Name} Knowledge Base"
description: "Knowledge index for {agent-name} agent"
category: "knowledge"
tags: ["agent", "knowledge-base"]
last_updated: "YYYY-MM-DD"
status: "published"
audience: "developers"
---

# Knowledge Base: {Agent Name}

[Knowledge documentation...]
```

4. **Validate and commit**:

```bash
./scripts/validate-templates.sh --verbose
git add templates/agents/{agent-name}/
git commit -m "feat(templates): add {agent-name} agent template"
```

### Adding a New Command Template

1. **Create command file** (`templates/commands/{command-name}.md`):

```markdown
---
name: command-name
description: What this command does
args:
  arg1:
    description: Argument description
    required: false
---

# Command Name

[Command documentation following template standards...]
```

2. **Validate and commit**:

```bash
./scripts/validate-templates.sh
git add templates/commands/{command-name}.md
git commit -m "feat(templates): add {command-name} command template"
```

## Validation Reference

### Running Validation

```bash
# Standard validation with fix suggestions
./scripts/validate-templates.sh

# Verbose mode (shows scanning progress)
./scripts/validate-templates.sh --verbose

# Quiet mode (CI/CD friendly)
./scripts/validate-templates.sh --quiet
```

### Understanding Validation Errors

**Hardcoded path detected:**

```text
✗ templates/agents/example/example.md:42
  Found hardcoded macOS path: /path/to/.claude
  Suggestion: Replace with ${CLAUDE_CONFIG_DIR} or appropriate variable
```

**Username detected:**

```text
✗ templates/commands/example.md:15
  Found username: specific-username
  Suggestion: Replace with ${USER} or generic placeholder
```

**Email detected:**

```text
✗ templates/agents/example/knowledge/README.md:8
  Found email address: user@company.com
  Suggestion: Replace with example email (user@example.com) or remove
```

### Fixing Validation Issues

1. **Replace hardcoded paths** with appropriate variables:
   - User config paths → `{{CLAUDE_CONFIG_DIR}}/` (install-time)
   - AIDA installation → `{{AIDA_HOME}}/` (install-time)
   - User home directory → `{{HOME}}/` (install-time)
   - Project paths → `${PROJECT_ROOT}/` (runtime)
   - Git repository paths → `${GIT_ROOT}` (runtime)

2. **Remove or generify usernames**:
   - Specific usernames → `{{USER}}` or generic placeholder
   - Use `{username}` for examples

3. **Use example emails**:
   - Real emails → `user@example.com`
   - Support emails → `support@example.com`

4. **Replace credentials** with placeholders:
   - `api_key: abc123...` → `api_key: {your-api-key}`
   - `token: real_token` → `token: ${API_TOKEN}`

**Remember:** Choose the right variable type based on when the value should be resolved:

- **Install-time (`{{VAR}}`)**: User-specific paths that are fixed at installation
- **Runtime (`${VAR}`)**: Context-specific values that change per execution

## Template Standards

### Frontmatter Requirements

All template files must include YAML frontmatter:

**Agent templates:**

```yaml
---
name: agent-name
description: Brief agent description
model: claude-sonnet-4.5
color: blue
temperature: 0.7
---
```

**Command templates:**

```yaml
---
name: command-name
description: What this command does
args:
  arg_name:
    description: Argument description
    required: true/false
---
```

**Document templates:**

```yaml
---
title: "Document Title"
description: "Document description"
category: "meta"
tags: ["tag1", "tag2"]
last_updated: "YYYY-MM-DD"
status: "published"
audience: "developers"
---
```

### Documentation Standards

All templates should include:

1. **Clear purpose statement**: What the template is for
2. **Usage instructions**: How to use the agent/command
3. **Examples**: Practical usage examples
4. **Configuration**: Available options and settings
5. **Best practices**: Guidelines for effective use

### Code Quality

Templates must pass all validation checks:

- ✅ Privacy validation (`./scripts/validate-templates.sh`)
- ✅ Markdown linting (`pre-commit run markdownlint`)
- ✅ YAML validation (`pre-commit run yamllint`)
- ✅ No hardcoded paths or user data

## Troubleshooting

### Common Issues

#### Q: Template validation fails with hardcoded paths

A: Replace all absolute paths with runtime variables:

- Use `${CLAUDE_CONFIG_DIR}` for `~/.claude/`
- Use `${AIDA_HOME}` for `~/.aida/`
- Use `${PROJECT_ROOT}` for project paths
- Use `${HOME}` or `~` for home directory

#### Q: How do I test template changes?

A: Use development mode to test changes:

```bash
# Install in dev mode
./install.sh --dev

# Edit templates in repository
vim templates/agents/example/example.md

# Changes reflect immediately in ~/.aida/ (symlinked)

# Test in active config
# Copy to ~/.claude/ and test workflow
```

#### Q: Can I use templates from ~/.claude/ instead of templates/?

A: The `templates/` directory is the canonical source. While `~/.claude/` contains your active configuration, it may have user-specific customizations. Always archive from `~/.claude/` to `templates/` after removing personalization.

#### Q: What happens if I commit a template with private data?

A: The CI/CD pipeline runs `validate-templates.sh` and will fail the build. Fix validation errors before the PR can merge. For sensitive data already committed, contact maintainers for history rewriting.

## Advanced Topics

### Template Inheritance

Future versions may support template inheritance:

```yaml
---
name: custom-agent
extends: technical-writer
overrides:
  temperature: 0.9
  color: green
---
```

This is not yet implemented but is being considered for template extensibility.

### Template Versioning

Templates follow AIDA's semantic versioning:

- **Major version** (1.0.0 → 2.0.0): Breaking changes to template structure
- **Minor version** (1.0.0 → 1.1.0): New features, backward compatible
- **Patch version** (1.0.0 → 1.0.1): Bug fixes, clarifications

Users can opt-in to template updates or pin to specific versions.

### Custom Template Directories

Advanced users can maintain custom template directories:

```bash
# Set custom template source
export AIDA_TEMPLATE_DIR="/path/to/custom/templates"

# Install uses custom templates
./install.sh
```

This allows organizations to maintain internal template libraries.

## Related Documentation

- **[CLAUDE.md](/CLAUDE.md)**: Project overview and development guidelines
- **[docs/CONTRIBUTING.md](/docs/CONTRIBUTING.md)**: Contribution standards and code quality
- **[docs/architecture/dotfiles-integration.md](/docs/architecture/dotfiles-integration.md)**: Integration architecture
- **[scripts/validate-templates.sh](/scripts/validate-templates.sh)**: Privacy validation script

## Support

For questions or issues with templates:

1. **Check documentation**: Review this README and related docs
2. **Run validation**: Use `./scripts/validate-templates.sh --verbose`
3. **Review examples**: Look at existing templates for patterns
4. **Open an issue**: Create a GitHub issue with `[templates]` prefix

---

**Remember**: Templates are the foundation of AIDA. Keep them clean, privacy-safe, and well-documented to ensure a great experience for all users.
