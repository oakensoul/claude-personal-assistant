---
title: "Sample Test Command"
description: "A sample command template for testing purposes"
category: "test"
tags: ["test", "sample", "fixture"]
---

# Sample Test Command

This is a sample command template used for testing template processing and validation.

## Purpose

This template exists solely for testing purposes and demonstrates the expected structure of a command template.

## Variables

The following variables should be available:

- `{{CLAUDE_CONFIG_DIR}}` - Claude configuration directory
- `{{AIDA_HOME}}` - AIDA framework home directory
- `{{HOME}}` - User's home directory

## Usage

```bash
# Example usage
/sample-command
```

## Expected Behavior

This command should:

1. Load successfully
2. Parse template variables correctly
3. Execute without errors

## Test Scenarios

- Template variable substitution
- Markdown parsing
- Frontmatter extraction
- Command registration
