---
title: "Create Issue Command (v0.1.x - DEPRECATED)"
description: "Create a new GitHub issue (old verb-noun naming)"
category: "workflow"
tags: ["github", "workflow", "issue-tracking"]
version: "0.1.6"
aida_framework: true
deprecated: true
deprecated_in: "0.2.0"
canonical: "issue-create"
---

# Create Issue Command (DEPRECATED)

Create a new GitHub issue with standardized formatting.

## Deprecation Notice

This command uses the old **verb-noun** naming convention (`create-issue`) which was deprecated in v0.2.0 per ADR-010.

**Canonical Name**: `issue-create` (noun-verb convention)

**Migration Path**: This command will be removed in v0.4.0. Use `/issue-create` instead.

## Overview

This is the v0.1.x version with deprecated naming, living in the flat directory structure.

Should be REPLACED by:

- New location: `~/.claude/commands/.aida/issue-create.md`
- New naming: noun-verb convention
- Namespace isolated

## Usage (OLD)

```bash
/create-issue
```

## What It Does

1. **Gather Details**: Prompt for issue title, description, labels
2. **Format Template**: Apply standardized issue template
3. **Create Draft**: Save local draft for review
4. **Validate**: Check for required fields

## Implementation (v0.1.x)

Interactive prompts:

```text
Creating new GitHub issue...

Title: Add user authentication
Description: Implement JWT-based authentication system
Labels: enhancement, security
Milestone: v0.2.0

✓ Draft created: .github/issues/drafts/add-user-authentication.md
✓ Ready for review

Use /publish-issue to publish to GitHub
```

## Migration Instructions

For users upgrading to v0.2.0+:

1. **New command name**: `/issue-create` (noun-verb)
2. **New location**: `~/.claude/commands/.aida/issue-create.md`
3. **Deprecation timeline**:
   - v0.2.0: Old name still works with warning
   - v0.3.0: Old name shows migration notice
   - v0.4.0: Old name removed

## Flat Structure Note

This command lives in v0.1.x flat structure:

- Location: `~/.claude/commands/create-issue.md`
- Old naming convention
- No namespace isolation

**IMPORTANT**: This is AIDA framework content with deprecated naming. Should be REPLACED (not preserved) during upgrade to v0.2.0.
