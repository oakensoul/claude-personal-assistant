---
name: create-agent
description: Interactive command for creating new Claude Code agents with proper structure, documentation, and knowledge management
args:
  description:
    description: Initial agent description and purpose (optional - will prompt if not provided)
    required: false
version: 1.0.0
category: meta
---

# Create Agent Command

Creates a new Claude Code agent with proper frontmatter, knowledge directory, and CLAUDE.md documentation. This command invokes the `claude-agent-manager` subagent to handle the creation process.

## Usage

```bash
/create-agent [description]
```

## Arguments

- **description** (optional): Brief description of what the agent should do and when to use it. If not provided, the command will prompt you interactively.

## Examples

```bash
# Interactive mode (will prompt for all details)
/create-agent

# With initial description
/create-agent "Agent for handling database migrations and schema changes"
```

## Workflow

This command invokes the **claude-agent-manager** subagent to:

1. **Gather Information**
    - Prompt for agent name (if not inferrable from description)
    - Prompt for full description
    - Ask about core responsibilities
    - Confirm when to use this agent
    - Identify required knowledge/documentation
    - Ask about special configuration (color, temperature)

2. **Validate Input**
    - Ensure name uses kebab-case
    - Check if agent already exists (offer to update or choose new name)
    - Confirm all required information is provided
    - Validate frontmatter format

3. **Create Agent Resources**
    - Generate agent file at `${CLAUDE_CONFIG_DIR}/agents/{name}.md` with:
        - Proper frontmatter (name, description, model: claude-sonnet-4.5, color)
        - Complete agent specification
        - Capabilities and usage guidelines
        - Examples and best practices

    - Create knowledge directory structure:
        - `${CLAUDE_CONFIG_DIR}/agents/{name}/knowledge/`
        - `${CLAUDE_CONFIG_DIR}/agents/{name}/knowledge/core-concepts/`
        - `${CLAUDE_CONFIG_DIR}/agents/{name}/knowledge/patterns/`
        - `${CLAUDE_CONFIG_DIR}/agents/{name}/knowledge/decisions/`

    - Generate knowledge index at `${CLAUDE_CONFIG_DIR}/agents/{name}/knowledge/index.md` with:
        - Proper frontmatter (agent, updated, knowledge_count, memory_type)
        - Initial categories and structure
        - External documentation links
        - Usage notes

4. **Update CLAUDE.md**
    - Add new section under "Project Agents"
    - Include:
        - **Invocation**: How to call the agent
        - **When to Use**: Specific scenarios
        - **Capabilities**: What the agent can do
        - **Knowledge Base**: Path to knowledge directory
        - **Example**: Usage pattern

5. **Confirm Success**
    - Display summary of created files:

    ```text
    ✓ Created {agent-name} agent

    Files created:
    - ${CLAUDE_CONFIG_DIR}/agents/{agent-name}.md
    - ${CLAUDE_CONFIG_DIR}/agents/{agent-name}/knowledge/index.md
    - CLAUDE.md (updated)

    Knowledge directories:
    - ${CLAUDE_CONFIG_DIR}/agents/{agent-name}/knowledge/core-concepts/
    - ${CLAUDE_CONFIG_DIR}/agents/{agent-name}/knowledge/patterns/
    - ${CLAUDE_CONFIG_DIR}/agents/{agent-name}/knowledge/decisions/

    Next steps:
    1. Add documentation to knowledge/core-concepts/
    2. Document patterns in knowledge/patterns/
    3. Record design decisions in knowledge/decisions/
    4. Test agent invocation
    ```

## Agent Standards

The command ensures the created agent follows these standards:

### Frontmatter

```yaml
---
name: agent-name               # kebab-case
description: Brief description # When to use this agent
model: claude-sonnet-4.5      # Always default to this
color: blue                    # Visual identifier
---
```

### Knowledge Index

```yaml
---
agent: agent-name
updated: "YYYY-MM-DD"
knowledge_count: 0
memory_type: "agent-specific"
---
```

### CLAUDE.md Entry

```markdown
### Agent Name

**Invocation**: Use the `agent-name` subagent for...

**When to Use**:

- Specific scenario 1
- Specific scenario 2

**Capabilities**:

- What the agent can do
- Key responsibilities

**Knowledge Base**: Located at `${CLAUDE_CONFIG_DIR}/agents/agent-name/knowledge/`
```

## Interactive Prompts

The claude-agent-manager will ask questions like:

1. **Agent Name**: "What should this agent be called?" (suggests kebab-case from description)
2. **Purpose**: "What is the primary purpose of this agent?"
3. **Responsibilities**: "What are the core responsibilities? (comma-separated list)"
4. **When to Use**: "In what scenarios should Claude invoke this agent?"
5. **Knowledge Needs**: "What knowledge/documentation will this agent need?"
6. **Configuration**: "Special configuration? (color: blue, temperature: 0.7, or press Enter for defaults)"

## Error Handling

- **Agent Already Exists**: Prompt user to update existing agent or choose new name
- **Invalid Name Format**: Suggest kebab-case alternative
- **Missing Information**: Re-prompt for required details
- **CLAUDE.md Update Failure**: Display error and suggest manual update
- **Directory Creation Failure**: Check permissions and suggest resolution

## Success Criteria

- Agent file created with proper frontmatter
- Knowledge directory structure created
- Knowledge index.md generated
- CLAUDE.md updated with agent documentation
- Agent can be invoked by name
- Knowledge base ready for population

## Related Commands

- `/create-command` - Create a new Claude Code command
- `/memory` - View loaded memory files
- `/config` - Configure Claude Code settings

## Integration Notes

- This command delegates all work to the `claude-agent-manager` subagent
- Ensures consistency across all project agents
- Follows Claude Code best practices for memory management
- Integrates with the two-tier memory system (CLAUDE.md + knowledge bases)

## Notes

- **Always interactive**: Gathers all necessary information before creating files
- **Validation first**: Checks for conflicts and validates input before proceeding
- **Complete creation**: Creates agent file, knowledge structure, AND updates CLAUDE.md
- **Ready to use**: Agent is immediately available for invocation after creation
