---
title: "Start Work Command (v0.1.x)"
description: "Begin work on a GitHub issue (v0.1.6 flat structure)"
category: "workflow"
tags: ["github", "workflow", "issue-tracking"]
version: "0.1.6"
aida_framework: true
---

# Start Work Command

Begin work on a GitHub issue with branch creation and issue tracking.

## Overview

This is the v0.1.x version of the start-work command, living in the flat directory structure at `~/.claude/commands/start-work.md`.

In v0.2.0+, this will be REPLACED by the namespace version at `~/.claude/commands/.aida/start-work.md`.

## Usage

```bash
/start-work <issue-number>
```

## What It Does

1. **Fetch Issue**: Get issue details from GitHub
2. **Create Branch**: Create feature branch from issue title
3. **Update Issue**: Add "in progress" label and assignment
4. **Track Context**: Update local issue tracking

## Implementation (v0.1.x)

When invoked:

```text
Starting work on issue #123...

✓ Fetched issue details
✓ Created branch: feature/123-add-user-authentication
✓ Updated issue labels: in-progress
✓ Assigned issue to: @username
✓ Updated context tracking

Branch: feature/123-add-user-authentication
Ready to begin implementation!
```

## Flat Structure Note

This command lives in the flat directory structure used by v0.1.x:

- Location: `~/.claude/commands/start-work.md`
- No namespace isolation
- Direct command lookup

## Migration Note

In v0.2.0+, this command should be:

- Moved to: `~/.claude/commands/.aida/start-work.md`
- Namespace isolated
- Updated with new features

**IMPORTANT**: This is AIDA framework content that should be REPLACED during upgrade to v0.2.0, not preserved as user content.
