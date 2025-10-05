---
title: "Configure PATH and shell integration"
labels:
  - "type: feature"
  - "priority: p0"
  - "effort: small"
  - "milestone: 0.1.0"
---

# Configure PATH and shell integration

## Description

Ensure the generated CLI tool is accessible from anywhere by adding it to the user's PATH. Detect the user's shell and update the appropriate configuration file.

## Acceptance Criteria

- [ ] Function `setup_path()` detects user's shell (bash, zsh, fish)
- [ ] For bash: adds PATH to `~/.bashrc` or `~/.bash_profile`
- [ ] For zsh: adds PATH to `~/.zshrc`
- [ ] For fish: adds PATH to `~/.config/fish/config.fish`
- [ ] Creates `~/bin/` directory if it doesn't exist
- [ ] Adds `~/bin` to PATH only if not already present
- [ ] Uses `export PATH="$HOME/bin:$PATH"` format
- [ ] Includes comment marker to identify AIDA addition
- [ ] Sources updated config file OR instructs user to restart shell
- [ ] Verifies CLI tool is accessible after PATH update

## Implementation Notes

**Shell Detection:**
```bash
detect_shell() {
    local shell_name
    shell_name=$(basename "$SHELL")
    echo "$shell_name"
}

get_shell_config() {
    local shell_name="$1"
    case "$shell_name" in
        bash)
            if [[ -f "$HOME/.bashrc" ]]; then
                echo "$HOME/.bashrc"
            else
                echo "$HOME/.bash_profile"
            fi
            ;;
        zsh)
            echo "$HOME/.zshrc"
            ;;
        fish)
            echo "$HOME/.config/fish/config.fish"
            ;;
        *)
            echo ""
            ;;
    esac
}
```

**PATH Addition:**
```bash
# AIDA - Added by installation
export PATH="$HOME/bin:$PATH"
```

**Idempotency:**
- Check if PATH addition already exists
- Use marker comment to identify AIDA's additions
- Don't add duplicate entries

**Verification:**
```bash
# Verify CLI is in PATH
if command -v "$ASSISTANT_NAME" &> /dev/null; then
    echo "✓ CLI tool is accessible"
else
    echo "✗ CLI tool not found in PATH"
    exit 1
fi
```

## Dependencies

- #003 (CLI tool generation)

## Related Issues

- #001 (Installation script foundation)

## Definition of Done

- [ ] PATH is correctly updated for bash users
- [ ] PATH is correctly updated for zsh users
- [ ] PATH is correctly updated for fish users
- [ ] Script doesn't create duplicate PATH entries
- [ ] CLI tool is immediately accessible after installation
- [ ] Works on macOS and Linux
- [ ] Clear messaging about shell restart if needed
