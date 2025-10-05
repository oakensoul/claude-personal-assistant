---
title: "Generate personalized CLI tool"
labels:
  - "type: feature"
  - "priority: p0"
  - "effort: medium"
  - "milestone: 0.1.0"
---

# Generate personalized CLI tool

## Description

Create the CLI tool generation system that produces a personalized executable script named after the user's assistant (e.g., `jarvis`, `alfred`, `friday`). The CLI tool provides basic status checks and command routing.

## Acceptance Criteria

- [ ] Function `create_cli_tool()` generates executable script
- [ ] CLI tool is named after user's assistant (lowercase)
- [ ] CLI tool is created in `~/bin/` or `~/.local/bin/`
- [ ] CLI tool has execute permissions (755)
- [ ] CLI tool includes bash shebang and error handling (`set -e`)
- [ ] CLI tool defines core constants (ASSISTANT_NAME, AIDE_HOME)
- [ ] CLI tool implements basic commands:
  - `status` - Show quick system status
  - `help` - Display available commands
  - `version` - Show AIDA version
- [ ] CLI tool handles unknown commands gracefully
- [ ] CLI tool provides helpful error messages
- [ ] CLI tool sources configuration from `~/.claude/config/`

## Implementation Notes

### CLI Tool Structure

```bash
#!/bin/bash
set -e

ASSISTANT_NAME="jarvis"  # From user input
AIDE_VERSION="0.1.0"
AIDE_HOME="$HOME/.claude"
AIDE_FRAMEWORK="$HOME/.aida"

# Source configuration
if [[ -f "$AIDE_HOME/config/system.yaml" ]]; then
    # Load config (will implement YAML parsing later)
    :
fi

# Command routing
case "$1" in
    "status")
        show_status
        ;;
    "help")
        show_help
        ;;
    "version")
        echo "AIDA v${AIDE_VERSION} (${ASSISTANT_NAME})"
        ;;
    *)
        echo "Command not recognized: $1"
        echo "Use '${ASSISTANT_NAME} help' for available commands"
        exit 1
        ;;
esac
```

### Status Command

Display:

- AIDA version
- Installation path
- Active personality
- Last context update timestamp
- Quick health check (files exist, permissions OK)

### Help Command

Display:

- Available commands
- Brief description of each
- Examples of usage
- Link to documentation

## Dependencies

- #001 (Installation script foundation)
- #002 (Template system - uses cli-tool.template)

## Related Issues

- #004 (PATH configuration)
- #009 (Extended command system)

## Definition of Done

- [ ] CLI tool is generated with correct name
- [ ] All basic commands work (status, help, version)
- [ ] CLI tool is executable and in PATH
- [ ] Error handling is robust
- [ ] Help text is clear and helpful
- [ ] Code is well-commented
- [ ] Works on both macOS and Linux
