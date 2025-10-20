---
title: "Configuration Specialist - AIDA Project Instructions"
description: "AIDA-specific configuration requirements and standards"
category: "project-agent-instructions"
tags: ["aida", "configuration-specialist", "project-context"]
last_updated: "2025-10-09"
status: "active"
---

# AIDA Configuration Specialist Instructions

Project-specific configuration standards and requirements for the AIDA framework.

## Project Configuration Standards

### Personality YAML Structure

AIDA uses YAML files to define personality configurations. The personality system is a core feature of AIDA.

**Standard Personality Structure**:

```yaml
---
# Personality Metadata
name: "jarvis"
display_name: "JARVIS"
version: "1.0.0"
description: "Professional AI assistant with direct, data-driven communication"

# Core Personality Traits
personality:
  tone: "professional"
  formality: "formal"
  verbosity: "concise"
  approach: "analytical"

# Communication Style
communication:
  greeting: "Good {time_of_day}. {user_name}."
  acknowledgment: "Understood."
  thinking: "Analyzing..."
  error: "Error detected: {error_message}"

# Response Patterns
responses:
  confirmation: "Confirmed. {action} completed."
  question: "Clarification needed: {question}"
  suggestion: "Recommendation: {suggestion}"

# Behavioral Modifiers
behavior:
  proactive: true
  verbose_errors: true
  emoji_usage: false
  humor_level: "minimal"
```

### Template Variable Substitution

AIDA uses a two-phase variable substitution system:

**Install-time Variables** (`{{VAR}}`):

- `{{AIDA_HOME}}` - AIDA installation directory (~/.aida/)
- `{{CLAUDE_CONFIG_DIR}}` - Claude config directory (~/.claude/)
- `{{HOME}}` - User's home directory

**Runtime Variables** (`${VAR}`):

- `${PROJECT_ROOT}` - Current project directory
- `${GIT_ROOT}` - Git repository root
- `$(date)` - Dynamic bash expressions

### Configuration File Locations

**Framework Directories**:

- `~/.aida/` - AIDA framework installation
- `~/.aida/personalities/` - Personality definitions
- `~/.aida/templates/` - Template files

**User Configuration**:

- `~/.claude/` - User Claude configuration
- `~/.claude/agents/` - User-level agents
- `~/.claude/commands/` - User-level commands
- `~/CLAUDE.md` - Main entry point

**Project Configuration**:

- `.claude/agents/` - Project-specific agents
- `.claude/project/agents/` - Project context for global agents
- `.claude/commands/` - Project-specific commands
- `CLAUDE.md` - Project instructions

### Validation Requirements

**Personality YAML Validation**:

1. Required fields: name, display_name, version, description
2. Valid tone values: professional, casual, friendly, formal
3. Valid formality values: formal, neutral, casual
4. Valid verbosity values: concise, moderate, detailed
5. Boolean fields must be true/false

**Template Variable Validation**:

1. Install-time variables must use `{{VAR}}` syntax
2. Runtime variables must use `${VAR}` syntax
3. No mixed syntax (no `{{${VAR}}}`)
4. All variables must be documented in template README

**Configuration Schema**:

- All YAML files must pass `yamllint --strict`
- No document-start markers in docker-compose.yml
- 2-space indentation required
- No trailing whitespace

### Error Message Standards

AIDA error messages must be:

1. **Actionable**: Tell user exactly what to do
2. **Contextual**: Include relevant file paths and values
3. **Friendly**: Match personality tone
4. **Informative**: Explain why the error occurred

**Example**:

```text
Error: Invalid personality configuration

File: ~/.aida/personalities/custom.yml
Issue: Missing required field 'display_name'

Fix: Add the following to your personality file:
  display_name: "Your Personality Name"

See: ~/.aida/personalities/jarvis.yml for example
```

### Configuration Migration

When AIDA framework updates change configuration schemas:

1. **Backward Compatibility**: Support old formats for 1 major version
2. **Auto-Migration**: Attempt automatic upgrade with user confirmation
3. **Validation**: Verify migrated config against new schema
4. **Backup**: Create `.bak` file before migration
5. **Rollback**: Provide easy rollback if migration fails

## AIDA-Specific Configuration Patterns

### Personality Switching

Configuration must support runtime personality switching:

```yaml
# Current personality tracking
current_personality: "jarvis"

# Personality history
personality_history:
  - timestamp: "2025-10-09T10:00:00Z"
    personality: "jarvis"
  - timestamp: "2025-10-09T09:00:00Z"
    personality: "alfred"
```

### Multi-Format Configuration

AIDA uses different formats for different purposes:

- **YAML**: Personalities, agent definitions, workflow commands
- **Markdown**: Documentation, knowledge bases, instructions
- **Shell**: Installation scripts, CLI tools
- **JSON**: Optional for API integrations

### Environment-Specific Configurations

AIDA supports:

- Development mode (--dev flag with symlinks)
- Normal mode (copied files)
- Project-specific overrides
- User-level defaults

## Integration Notes

- **User-level Configuration Patterns**: Load from `~/.claude/agents/configuration-specialist/`
- **Project-specific standards**: This file
- **Combined approach**: User philosophy + AIDA requirements

## Best Practices for AIDA

1. **Personality Files**: Always validate before loading
2. **Template Processing**: Process install-time variables during installation only
3. **Runtime Variables**: Process when commands execute
4. **Schema Validation**: Run on all YAML files in CI/CD
5. **Error Messages**: Match current personality tone

---

**Last Updated**: 2025-10-09
