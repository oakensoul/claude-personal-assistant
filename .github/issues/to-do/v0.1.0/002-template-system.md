---
title: "Implement template copying and variable substitution system"
labels:
  - "type: feature"
  - "priority: p0"
  - "effort: medium"
  - "milestone: 0.1.0"
---

# Implement template copying and variable substitution system

## Description

Create the template processing system that copies template files from the framework to user configuration, replacing variables like `${ASSISTANT_NAME}`, `${PERSONALITY_TONE}`, etc. This enables personalized configuration generation.

## Acceptance Criteria

- [ ] Function `copy_templates()` copies all files from `templates/` to `~/.claude/`
- [ ] Variable substitution supports:
  - `${ASSISTANT_NAME}` - User's chosen assistant name
  - `${ASSISTANT_DISPLAY_NAME}` - Capitalized display name
  - `${PERSONALITY_NAME}` - Chosen personality (jarvis, alfred, etc.)
  - `${USER_HOME}` - User's home directory path
  - `${INSTALL_DATE}` - Installation timestamp
- [ ] Substitution handles multiline content correctly
- [ ] Substitution preserves file formatting and indentation
- [ ] Substitution skips binary files
- [ ] Function provides progress feedback during copying
- [ ] Function validates templates exist before copying
- [ ] Function creates destination directories as needed

## Implementation Notes

### Substitution Strategy

```bash
substitute_variables() {
    local file="$1"
    local assistant_name="$2"
    local personality="$3"

    sed -i.bak \
        -e "s|\${ASSISTANT_NAME}|${assistant_name}|g" \
        -e "s|\${ASSISTANT_DISPLAY_NAME}|${assistant_name^}|g" \
        -e "s|\${PERSONALITY_NAME}|${personality}|g" \
        -e "s|\${USER_HOME}|${HOME}|g" \
        -e "s|\${INSTALL_DATE}|$(date +%Y-%m-%d)|g" \
        "$file"

    rm "${file}.bak"
}
```

### Template Discovery

- Recursively find all `.template` files
- Process in dependency order (config before knowledge)
- Skip files in .templateignore if it exists

### Error Handling

- Verify template file exists before processing
- Check destination directory is writable
- Validate substitution didn't corrupt file
- Rollback on error

## Dependencies

- #001 (Installation script foundation)

## Related Issues

- #005 (CLAUDE.md template)
- #006 (Knowledge templates)
- #007 (Memory templates)

## Definition of Done

- [ ] All template files are copied correctly
- [ ] Variable substitution works for all supported variables
- [ ] No template remnants (${VAR}) remain after installation
- [ ] File permissions are preserved
- [ ] Function is tested with edge cases (special characters in name, etc.)
- [ ] Documentation explains how to add new variables
