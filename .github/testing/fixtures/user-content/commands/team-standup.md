---
title: "Team Standup Command"
description: "Generate team standup notes with activity summary"
author: "user"
created: "2024-08-20"
modified: "2024-09-28"
category: "team"
tags: ["standup", "team", "reporting", "custom"]
team: "engineering"
---

# Team Standup Command

Custom command for generating engineering team standup notes.

## What This Does

Aggregates team activity from multiple sources:

- GitHub PR activity across team repositories
- JIRA ticket updates
- Slack discussions in team channels
- Deployment activity from CI/CD

## Usage

Run before daily standup meeting:

```bash
/team-standup --date today --team engineering
```

## Output Format

Generates markdown summary:

```markdown
# Engineering Standup - 2024-10-18

## Yesterday's Accomplishments
- [PR #123] Feature X shipped to production
- [JIRA-456] Bug fix completed
- [Deploy] Staging environment updated

## Today's Focus
- [PR #124] Feature Y code review
- [JIRA-457] Performance investigation

## Blockers
- None
```

## Configuration

Team-specific configuration in `~/.config/team-standup.yml`:

```yaml
team: engineering
repositories:
  - org/repo1
  - org/repo2
jira_project: ENG
slack_channels:
  - "#engineering"
  - "#deployments"
```

## Integration

This command integrates with:

- GitHub API for PR/issue activity
- JIRA API for ticket updates
- Slack API for channel summaries

Requires API tokens configured in environment variables.

## User Content Notice

This is a team-specific custom command created by the user. It should be preserved during any AIDA framework upgrades and never modified by the installer.

**Location**: `~/.claude/commands/team-standup.md` (user space, NOT `.aida/` namespace)
