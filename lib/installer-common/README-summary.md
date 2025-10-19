---
title: "Summary Module Documentation"
description: "Installation summary display with professional visual formatting"
category: "installer-library"
tags: ["installer-common", "ui", "ux", "summary", "display"]
last_updated: "2025-10-18"
status: "published"
audience: "developers"
---

# Summary Module (`summary.sh`)

Professional installation summary display with visual formatting for AIDA and dotfiles installers.

## Overview

The summary module provides user-friendly output functions for displaying installation results, next steps, success messages, error messages with recovery guidance, and upgrade summaries. It uses Unicode box drawing characters and color formatting to create a polished, professional user experience.

## Dependencies

- `colors.sh` - Terminal color utilities and color support detection
- `logging.sh` - Logging utilities for message output

## Source Order

```bash
source "${INSTALLER_COMMON}/colors.sh"
source "${INSTALLER_COMMON}/logging.sh"
source "${INSTALLER_COMMON}/summary.sh"
```

## Core Functions

### Installation Summary

#### `display_summary()`

Display complete installation summary with all relevant details.

**Signature:**

```bash
display_summary() {
  local install_mode="$1"      # "normal" or "dev"
  local aida_dir="$2"           # Path to AIDA framework directory
  local claude_dir="$3"         # Path to Claude config directory
  local version="$4"            # AIDA version string (e.g., "v0.2.0")
}
```

**Usage:**

```bash
display_summary "normal" "$HOME/.aida" "$HOME/.claude" "v0.2.0"
display_summary "dev" "$HOME/.aida" "$HOME/.claude" "v0.2.0"
```

**Output:**

```text
╔════════════════════════════════════════════════════════════════╗
║              AIDA FRAMEWORK INSTALLATION COMPLETE              ║
╚════════════════════════════════════════════════════════════════╝

Installation Details:
─────────────────────────────────────────────────────────────────

  Version:        v0.2.0
  Mode:           Development mode (symlinked)
  Installed:      2025-10-18 20:00:00

  Framework:      ~/.aida
                  (symlinked to repository)
  Configuration:  ~/.claude
  Entry Point:    ~/CLAUDE.md

Installed Templates:
─────────────────────────────────────────────────────────────────

  Commands:       12 templates
  Agents:         8 agents
```

**Features:**

- Automatically counts installed templates and agents
- Displays installation timestamp
- Shows mode (normal vs dev) with appropriate messaging
- Highlights symlink status in dev mode
- Responsive to terminal width

#### `display_next_steps()`

Display recommended next steps after installation.

**Signature:**

```bash
display_next_steps() {
  local install_mode="$1"      # "normal" or "dev"
}
```

**Usage:**

```bash
display_next_steps "normal"
display_next_steps "dev"
```

**Output:**

```text
╔════════════════════════════════════════════════════════════════╗
║ NEXT STEPS                                                     ║
╠════════════════════════════════════════════════════════════════╣
║                                                                ║
║  1. Review configuration: ~/.claude/aida-config.json           ║
║  2. Try a command: /start-work                                 ║
║  3. Read documentation: ~/.aida/README.md                      ║
║                                                                ║
║  Development mode: Changes to templates take effect           ║
║  immediately (no reinstall needed)                             ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝
```

**Features:**

- Provides actionable next steps
- Adjusts messaging for dev vs normal mode
- Uses box drawing for visual emphasis

### Success and Error Messages

#### `display_success()`

Display success message with optional details.

**Signature:**

```bash
display_success() {
  local message="$1"
  local details="${2:-}"  # Optional details
}
```

**Usage:**

```bash
display_success "Installation completed successfully!"

display_success "Configuration updated" \
  "Your assistant is now configured with the 'jarvis' personality.
All templates have been installed to ~/.claude/commands/"
```

**Features:**

- Uses green checkmark icon
- Supports optional detail text
- Logs to file via logging.sh

#### `display_error()`

Display error message with optional recovery guidance.

**Signature:**

```bash
display_error() {
  local error_message="$1"
  local recovery_steps="${2:-}"  # Optional recovery guidance (newline-separated)
}
```

**Usage:**

```bash
display_error "Failed to create directory"

display_error "Failed to create symlink" \
  "1. Check ~/.aida doesn't already exist
2. Ensure you have write permissions to $HOME
3. Run: rm -rf ~/.aida and try again
4. If problem persists, check disk space"
```

**Output:**

```text
✗ Failed to create symlink

Recovery steps:

  1. Check ~/.aida doesn't already exist
  2. Ensure you have write permissions to /Users/username
  3. Run: rm -rf ~/.aida and try again
  4. If problem persists, check disk space
```

**Features:**

- Outputs to stderr
- Formats recovery steps with clear numbering
- Uses red color for emphasis
- Provides actionable guidance

### Upgrade Summary

#### `display_upgrade_summary()`

Display summary for upgrade installations.

**Signature:**

```bash
display_upgrade_summary() {
  local previous_version="$1"
  local new_version="$2"
  local preserved_files_count="$3"
}
```

**Usage:**

```bash
display_upgrade_summary "v0.1.6" "v0.2.0" "3"
display_upgrade_summary "v0.1.5" "v0.2.0" "0"
```

**Output:**

```text
╔════════════════════════════════════════════════════════════════╗
║              AIDA FRAMEWORK UPGRADE COMPLETE                   ║
╚════════════════════════════════════════════════════════════════╝

Upgrade Details:
─────────────────────────────────────────────────────────────────

  Previous Version: v0.1.6
  New Version:      v0.2.0

  User Files:       3 files preserved

What Changed:
─────────────────────────────────────────────────────────────────

  ✓ Framework files updated to v0.2.0
  ✓ Your configuration and customizations preserved
  ✓ 3 user files backed up and restored
```

**Features:**

- Shows version upgrade path
- Displays number of preserved user files
- Summarizes what changed
- Provides reassurance about preserved customizations

## Helper Functions

### `get_terminal_width()`

Get terminal width for responsive output.

**Returns:** Terminal width in columns (default: 80)

**Usage:**

```bash
local width
width=$(get_terminal_width)
```

### `draw_horizontal_line()`

Draw a horizontal line with box drawing characters.

**Arguments:**

- `$1` - Width (optional, defaults to terminal width)
- `$2` - Character to use (optional, defaults to `─`)

**Usage:**

```bash
draw_horizontal_line              # Full width with default character
draw_horizontal_line 60           # 60 characters wide
draw_horizontal_line 60 "="       # 60 equals signs
```

### `draw_box_header()`

Draw a box header with title.

**Arguments:**

- `$1` - Title text

**Usage:**

```bash
draw_box_header "INSTALLATION COMPLETE"
```

### `draw_box()`

Draw a complete box with title and content.

**Arguments:**

- `$1` - Title text
- stdin - Content lines (via here-doc)

**Usage:**

```bash
draw_box "NEXT STEPS" <<EOF
  1. Review configuration
  2. Start using AIDA
  3. Read documentation
EOF
```

### `count_templates()`

Count template files in a directory.

**Arguments:**

- `$1` - Template directory path

**Returns:** Number of `.md` files (0 if directory doesn't exist)

**Usage:**

```bash
local count
count=$(count_templates "${CLAUDE_DIR}/commands")
echo "Found $count command templates"
```

### `count_agents()`

Count agent directories.

**Arguments:**

- `$1` - Agents directory path

**Returns:** Number of subdirectories (0 if directory doesn't exist)

**Usage:**

```bash
local count
count=$(count_agents "${CLAUDE_DIR}/agents")
echo "Found $count agents"
```

## Color Scheme

The summary module uses a consistent color scheme for professional appearance:

- **Titles/Headers**: BOLD + BLUE
- **Success messages**: GREEN
- **Info/Details**: CYAN
- **Labels**: CYAN
- **Warnings**: YELLOW
- **Errors**: RED
- **Paths**: MAGENTA
- **Commands**: WHITE (bold)

## Visual Design

### Box Drawing Characters

Unicode box drawing characters create clean, professional borders:

```text
╔═══╗  ╠═══╣  ║ Text ║  ─────
║   ║  Top   Bottom  Line
╚═══╝  Border Border
```

### Responsive Layout

All output functions adapt to terminal width automatically:

- Detects terminal width via `tput cols`
- Falls back to 80 columns if detection fails
- Centers text in boxes
- Adjusts padding dynamically

### Graceful Degradation

The module gracefully handles terminals without color support:

- Detects color support via `supports_color()` from `colors.sh`
- Respects `NO_COLOR` environment variable
- Falls back to plain text when colors unavailable
- Box drawing characters work in monochrome

## Testing

### Visual Test Suite

Run comprehensive visual tests:

```bash
./lib/installer-common/test-summary-output.sh
```

Test without colors:

```bash
./lib/installer-common/test-summary-output.sh --no-color
```

### Test Coverage

The test suite validates:

1. `display_summary` - Normal installation mode
2. `display_summary` - Development mode
3. `display_next_steps` - Normal mode
4. `display_next_steps` - Development mode
5. `display_success` - Simple success
6. `display_success` - Success with details
7. `display_error` - Simple error
8. `display_error` - Error with recovery steps
9. `display_upgrade_summary` - With preserved files
10. `display_upgrade_summary` - Without preserved files
11. `get_terminal_width` - Terminal width detection
12. `count_templates` - Template counting
13. `count_agents` - Agent counting
14. `draw_box_header` - Header rendering
15. `draw_box` - Box with content
16. `draw_horizontal_line` - Line drawing variations
17. Full installation flow - Normal mode
18. Full installation flow - Development mode

## Usage Examples

### Basic Installation Summary

```bash
#!/usr/bin/env bash
source "${INSTALLER_COMMON}/colors.sh"
source "${INSTALLER_COMMON}/logging.sh"
source "${INSTALLER_COMMON}/summary.sh"

# At end of installation
display_summary "normal" "$AIDA_DIR" "$CLAUDE_DIR" "$VERSION"
display_next_steps "normal"
display_success "Installation completed successfully!"
```

### Development Mode Installation

```bash
display_summary "dev" "$AIDA_DIR" "$CLAUDE_DIR" "$VERSION"
display_next_steps "dev"
display_success "Development installation complete!" \
  "Changes to templates will take effect immediately."
```

### Error Handling with Recovery

```bash
if ! create_symlink "$AIDA_DIR"; then
    display_error "Failed to create AIDA symlink" \
      "1. Ensure ~/.aida doesn't already exist
2. Check write permissions to $HOME
3. Run: rm -rf ~/.aida
4. Try installation again"
    exit 1
fi
```

### Upgrade Installation

```bash
# Detect previous version
if [[ -f "$AIDA_DIR/VERSION" ]]; then
    PREVIOUS_VERSION=$(cat "$AIDA_DIR/VERSION")

    # Count preserved files
    PRESERVED_COUNT=3

    # Show upgrade summary
    display_upgrade_summary "$PREVIOUS_VERSION" "$VERSION" "$PRESERVED_COUNT"
else
    # Show regular installation summary
    display_summary "$INSTALL_MODE" "$AIDA_DIR" "$CLAUDE_DIR" "$VERSION"
fi

display_next_steps "$INSTALL_MODE"
```

## Design Principles

### User-First Design

- **Clear hierarchy**: Important information stands out visually
- **Actionable guidance**: Next steps are concrete and specific
- **Recovery support**: Errors include helpful recovery instructions
- **Professional appearance**: Polished output builds user confidence

### Visual Excellence

- **Consistent styling**: Uniform color scheme and formatting
- **Clean layout**: Proper spacing and alignment
- **Responsive design**: Adapts to terminal width
- **Accessible**: Works with and without color support

### Information Architecture

- **Logical flow**: Information presented in order of importance
- **Scannable**: Users can quickly find what they need
- **Complete**: All relevant information provided
- **Concise**: No unnecessary verbosity

## Best Practices

### When to Use Each Function

**`display_summary()`**

- End of successful installation
- Shows complete installation details
- Always pair with `display_next_steps()`

**`display_next_steps()`**

- Immediately after `display_summary()`
- Provides actionable guidance
- Adjusts for install mode

**`display_success()`**

- Individual operation success
- Can include optional details
- Use sparingly for important milestones

**`display_error()`**

- Any error that stops installation
- Always include recovery steps when possible
- Write to stderr, not stdout

**`display_upgrade_summary()`**

- Only for upgrade installations
- Shows version transition
- Highlights preserved user files

### Color Usage Guidelines

- **Don't overuse colors** - Reserve for emphasis
- **Maintain consistency** - Use color scheme consistently
- **Test without colors** - Ensure readable in monochrome
- **Respect NO_COLOR** - Honor user preferences

### Box Drawing Guidelines

- **Use for major sections** - Headers, next steps, summaries
- **Don't overuse** - Too many boxes create visual clutter
- **Ensure alignment** - Test at different terminal widths
- **Keep content clear** - Don't sacrifice readability for style

## Platform Compatibility

### Terminal Support

- **macOS Terminal.app**: Full support (colors + Unicode)
- **iTerm2**: Full support (colors + Unicode)
- **Linux terminals**: Full support (colors + Unicode)
- **SSH sessions**: Degrades gracefully based on TERM
- **CI/CD environments**: Respects NO_COLOR

### Character Encoding

- Requires UTF-8 terminal for box drawing
- Falls back gracefully on ASCII-only terminals
- Unicode box characters widely supported (2020+)

## Version History

- **v1.0** (2025-10-18): Initial implementation
  - Installation summary display
  - Next steps guidance
  - Success/error messaging
  - Upgrade summary support
  - Visual test suite

## Related Modules

- `colors.sh` - Color utilities and support detection
- `logging.sh` - Logging and message output
- `prompts.sh` - Interactive user prompts

## References

- [Unicode Box Drawing](https://en.wikipedia.org/wiki/Box-drawing_character)
- [NO_COLOR standard](https://no-color.org/)
- [ANSI color codes](https://en.wikipedia.org/wiki/ANSI_escape_code)
