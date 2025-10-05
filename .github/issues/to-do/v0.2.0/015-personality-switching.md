---
title: "Implement personality switching functionality"
labels:
  - "type: feature"
  - "priority: p2"
  - "effort: medium"
  - "milestone: 0.2.0"
---

# Implement personality switching functionality

## Description

Enable users to switch between personalities after installation without re-running the full install script. This allows users to try different communication styles and find what works best for them.

## Acceptance Criteria

- [ ] Function to switch personalities added to CLI tool
- [ ] Command `{assistant-name} personality switch [new-personality]` works
- [ ] Command `{assistant-name} personality list` shows available personalities
- [ ] Command `{assistant-name} personality current` shows active personality
- [ ] Switching updates `~/.claude/config/personality.yaml`
- [ ] Switching regenerates `~/CLAUDE.md` with new personality
- [ ] CLI tool name can optionally change (if assistant name changes)
- [ ] Backup created before switching
- [ ] User can switch back to previous personality
- [ ] Memory and knowledge are preserved during switch
- [ ] Clear confirmation before switching

## Implementation Notes

### CLI Commands

Add to CLI tool template:

```bash
# Personality management
personality() {
    case "${1:-}" in
        "switch")
            switch_personality "$2"
            ;;
        "list")
            list_personalities
            ;;
        "current")
            show_current_personality
            ;;
        *)
            error "Unknown personality command: $1"
            echo "Usage: ${ASSISTANT_NAME} personality [switch|list|current]"
            ;;
    esac
}

list_personalities() {
    info "Available personalities:"
    echo ""

    for yaml in "$AIDE_FRAMEWORK"/personalities/*.yaml; do
        local name=$(basename "$yaml" .yaml)
        local display=$(grep "name:" "$yaml" | head -1 | cut -d'"' -f2)
        local desc=$(grep "description:" "$yaml" | head -1 | cut -d'"' -f2)

        if [[ "$name" == "$(get_current_personality)" ]]; then
            echo "  * $display ($name) - CURRENT"
        else
            echo "    $display ($name)"
        fi
        echo "    $desc"
        echo ""
    done
}

show_current_personality() {
    local current=$(get_current_personality)
    local display=$(grep "name:" "$AIDE_HOME/config/personality.yaml" | head -1 | cut -d'"' -f2)

    info "Current personality: $display ($current)"
}

get_current_personality() {
    grep "^personality_name:" "$AIDE_HOME/config/system.yaml" 2>/dev/null | cut -d':' -f2 | tr -d ' '
}

switch_personality() {
    local new_personality="$1"

    if [[ -z "$new_personality" ]]; then
        error "Please specify a personality to switch to"
        echo "Use: ${ASSISTANT_NAME} personality list"
        exit 1
    fi

    # Check if personality exists
    if [[ ! -f "$AIDE_FRAMEWORK/personalities/${new_personality}.yaml" ]]; then
        error "Personality '${new_personality}' not found"
        list_personalities
        exit 1
    fi

    local current=$(get_current_personality)

    if [[ "$current" == "$new_personality" ]]; then
        info "Already using ${new_personality} personality"
        exit 0
    fi

    # Confirm switch
    echo ""
    warn "This will switch from ${current} to ${new_personality}"
    echo "Your memory and knowledge will be preserved."
    echo ""
    read -p "Continue? (y/N): " -n 1 -r
    echo ""

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "Personality switch cancelled"
        exit 0
    fi

    # Backup current config
    backup_dir="$AIDE_HOME/backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    cp "$AIDE_HOME/config/personality.yaml" "$backup_dir/"
    cp "$HOME/CLAUDE.md" "$backup_dir/"

    # Copy new personality
    cp "$AIDE_FRAMEWORK/personalities/${new_personality}.yaml" "$AIDE_HOME/config/personality.yaml"

    # Update system config
    sed -i.bak "s/personality_name: .*/personality_name: ${new_personality}/" "$AIDE_HOME/config/system.yaml"
    rm "$AIDE_HOME/config/system.yaml.bak"

    # Regenerate CLAUDE.md
    info "Regenerating CLAUDE.md with new personality..."
    generate_claude_md

    success "Switched to ${new_personality} personality"
    info "Backup saved to: $backup_dir"
    echo ""
    info "Start a new conversation with Claude to experience the new personality"
}

generate_claude_md() {
    # Load personality and current config
    local assistant_name=$(grep "assistant_name:" "$AIDE_HOME/config/system.yaml" | cut -d':' -f2 | tr -d ' ')
    local personality_name=$(get_current_personality)

    # Copy template
    cp "$AIDE_FRAMEWORK/templates/CLAUDE.md.template" "$HOME/CLAUDE.md.tmp"

    # Substitute variables
    sed -i.bak \
        -e "s|\${ASSISTANT_NAME}|${assistant_name}|g" \
        -e "s|\${ASSISTANT_DISPLAY_NAME}|${assistant_name^}|g" \
        -e "s|\${PERSONALITY_NAME}|${personality_name}|g" \
        -e "s|\${USER_HOME}|${HOME}|g" \
        -e "s|\${INSTALL_DATE}|$(date +%Y-%m-%d)|g" \
        "$HOME/CLAUDE.md.tmp"

    # Replace original
    mv "$HOME/CLAUDE.md.tmp" "$HOME/CLAUDE.md"
    rm -f "$HOME/CLAUDE.md.tmp.bak"
}
```

### System Config File

Create `~/.claude/config/system.yaml` to track configuration:

```yaml
# AIDA System Configuration
aida_version: "0.2.0"
assistant_name: "jarvis"
personality_name: "jarvis"
install_date: "2025-10-04"
install_mode: "normal"  # or "dev"
```

### Optional: Assistant Name Change

Allow changing the assistant name (advanced):

```bash
rename_assistant() {
    local new_name="$1"

    # Validate name
    if [[ ! "$new_name" =~ ^[a-z][a-z0-9-]{2,19}$ ]]; then
        error "Invalid name format"
        exit 1
    fi

    warn "This will rename your assistant and CLI tool"
    read -p "Continue? (y/N): " -n 1 -r
    echo ""

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi

    local old_name=$(grep "assistant_name:" "$AIDE_HOME/config/system.yaml" | cut -d':' -f2 | tr -d ' ')

    # Rename CLI tool
    mv "$HOME/bin/$old_name" "$HOME/bin/$new_name"

    # Update system config
    sed -i.bak "s/assistant_name: .*/assistant_name: ${new_name}/" "$AIDE_HOME/config/system.yaml"

    # Regenerate CLAUDE.md
    generate_claude_md

    success "Assistant renamed from $old_name to $new_name"
    info "Use '$new_name' for CLI commands now"
}
```

### User Workflow

```bash
# List available personalities
$ jarvis personality list

Available personalities:

  * JARVIS (jarvis) - CURRENT
    A snarky but supremely capable AI assistant

    Alfred (alfred)
    A distinguished, professional butler

    FRIDAY (friday)
    An enthusiastic, friendly AI

    Sage (sage)
    A calm, mindful assistant

    Sarge (drill-sergeant)
    A no-nonsense drill sergeant

# Switch personality
$ jarvis personality switch alfred

⚠ This will switch from jarvis to alfred
Your memory and knowledge will be preserved.

Continue? (y/N): y

Regenerating CLAUDE.md with new personality...
✓ Switched to alfred personality
Backup saved to: /Users/you/.claude/backups/20251004_143022

Start a new conversation with Claude to experience the new personality

# Check current
$ jarvis personality current
Current personality: Alfred (alfred)
```

## Dependencies

- #008 (JARVIS personality)
- #014 (Additional personalities)
- #010 (CLI tool template)

## Related Issues

- #001 (Installation script for initial personality)

## Definition of Done

- [ ] Personality switching commands implemented
- [ ] All commands work correctly
- [ ] Backup created before switching
- [ ] CLAUDE.md regenerated properly
- [ ] System config tracks current personality
- [ ] User can switch between all personalities
- [ ] Memory and knowledge preserved
- [ ] Documentation explains how to switch
- [ ] Tested with all personalities
