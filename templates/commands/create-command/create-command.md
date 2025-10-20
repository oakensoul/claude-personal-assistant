---
name: create-command
description: Interactive command for creating new Claude Code commands with proper structure, documentation, and workflow definition
args:
  description:
    description: Initial command description and purpose (optional - will prompt if not provided)
    required: false
version: 1.0.0
category: meta
---

# Create Command

Creates a new Claude Code command with proper frontmatter, comprehensive workflow documentation, and integration with appropriate agents. This command invokes the `claude-agent-manager` subagent to handle the creation process.

## Usage

```bash
/create-command [description]
```

## Arguments

- **description** (optional): Brief description of what the command should do. If not provided, the command will prompt you interactively.

## Examples

```bash
# Interactive mode (will prompt for all details)
/create-command

# With initial description
/create-command "Command for analyzing application performance metrics"
```

## Workflow

This command invokes the **claude-agent-manager** subagent to:

1. **Gather Information**
    - Prompt for command name (if not inferrable from description)
    - Prompt for full description
    - Ask what the command should accomplish
    - Ask about required arguments
    - Ask about optional arguments
    - Ask about workflow steps
    - Ask about error handling needs
    - Identify which agent(s) should handle the work
    - Ask about related commands/integrations

2. **Validate Input**
    - Ensure name uses kebab-case
    - Check if command already exists (offer to update or choose new name)
    - Confirm all required information is provided
    - Validate frontmatter format
    - Ensure workflow is complete and logical

3. **Create Command Resources**
    - Generate command file at `${CLAUDE_CONFIG_DIR}/commands/{name}.md` with:
        - Proper frontmatter (name, description, args)
        - Complete command specification
        - Detailed workflow steps
        - Usage examples
        - Error handling documentation
        - Success criteria
        - Integration notes

4. **Confirm Success**
    - Display summary of created file:

    ```text
    ✓ Created {command-name} command

    File created:
    - ${CLAUDE_CONFIG_DIR}/commands/{command-name}.md

    Integration:
    - Invokes: {agent-name} agent
    - Arguments: {list of arguments}

    Usage:
    /{command-name} [arguments]

    Next steps:
    1. Test command invocation
    2. Verify agent integration
    3. Document any edge cases
    ```

## Command Standards

The command ensures the created command follows these standards:

### Frontmatter

```yaml
---
name: command-name             # kebab-case
description: Brief description # What this command does
args:                          # Optional section
  required-arg:
    description: What this argument does
    required: true
  optional-arg:
    description: What this argument does
    required: false
---
```

### Command Structure

```markdown
# Command Name

Brief overview of what the command does.

## Usage

Command invocation syntax

## Arguments

Detailed argument descriptions

## Examples

Usage examples

## Workflow

Numbered steps the command follows

## Error Handling

How errors are handled

## Success Criteria

What defines successful completion

## Related Commands

Other related commands

## Integration Notes

How the command integrates with agents/systems
```

## Interactive Prompts

The claude-agent-manager will ask questions like:

1. **Command Name**: "What should this command be called?" (suggests kebab-case from description)
2. **Purpose**: "What should this command accomplish?"
3. **Required Arguments**: "What required arguments does this command need? (comma-separated, or 'none')"
4. **Optional Arguments**: "What optional arguments should be available? (comma-separated, or 'none')"
5. **Workflow**: "Describe the workflow steps this command should follow (will prompt for details)"
6. **Agent Integration**: "Which agent should handle the work? (or 'none' for direct execution)"
7. **Error Scenarios**: "What error scenarios should be handled?"
8. **Related Commands**: "Are there related commands this integrates with?"

## Error Handling

- **Command Already Exists**: Prompt user to update existing command or choose new name
- **Invalid Name Format**: Suggest kebab-case alternative
- **Missing Information**: Re-prompt for required details
- **Invalid Agent Reference**: Suggest available agents or offer to create new agent
- **Incomplete Workflow**: Request additional workflow details

## Success Criteria

- Command file created with proper frontmatter
- Comprehensive workflow documented
- Arguments clearly defined (if any)
- Error handling specified
- Agent integration documented (if applicable)
- Usage examples provided
- Success criteria defined
- Command can be invoked by name

## Related Commands

- `/create-agent` - Create a new Claude Code agent
- `/memory` - View loaded memory files
- `/config` - Configure Claude Code settings

## Integration Notes

- This command delegates all work to the `claude-agent-manager` subagent
- Ensures consistency across all project commands
- Follows Claude Code best practices for command structure
- Integrates with existing agent ecosystem

## Notes

- **Always interactive**: Gathers all necessary information before creating files
- **Validation first**: Checks for conflicts and validates input before proceeding
- **Complete creation**: Creates command file with all required sections
- **Ready to use**: Command is immediately available for invocation after creation
- **Agent-aware**: Commands know which agents to invoke for specialized work
