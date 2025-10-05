---
title: "GitHub Project Board Setup"
description: "Documentation for the AIDA Development project board configuration and usage"
category: "development"
tags: ["github", "project-management", "workflow", "kanban"]
last_updated: "2025-10-04"
status: "published"
audience: "developers"
---

# GitHub Project Board Setup

This document describes the setup and usage of the AIDA Development GitHub Project board.

## Overview

The AIDA Development project uses GitHub Projects (v2) with a Kanban-style workflow across two board views:

- **Triage** - Issue intake and evaluation
- **Backlog** - Development workflow and execution

The project tracks issues across multiple repositories in the AIDA ecosystem.

## Why GitHub Projects?

**Benefits:**

- Cross-repository tracking (framework + dotfiles + private configs)
- Custom fields for AIDA-specific categorization
- Multiple views on the same data
- Automation (auto-add, auto-archive, workflows)
- Visual workflow management

**vs Alternatives:**

- Simple GitHub Issues - No cross-repo, limited organization
- External tools (Jira, Linear) - Adds complexity, costs money
- GitHub Projects Classic - Limited features, deprecated

## Board Structure

### Two-View Workflow

**Triage Board** - Issue Evaluation

```text
Parking Lot → Triage → Ready → Won't Fix/Duplicate/Invalid
```

Purpose: Evaluate new issues, decide if/when to work on them

- New issues start in **Triage** (auto-added)
- Review and refine
- Outcome: Advance to **Ready** or close with resolution

**Backlog Board** - Development Execution

```text
Ready → Prioritized → In Progress → In Review → Done
```

Purpose: Execute prioritized work and ship features

- Issues enter at **Ready** (from Triage)
- Clear workflow progression
- Ends at **Done** (completed work)

### Handoff Point: "Ready"

**Ready** appears in both boards - it's the handoff from evaluation to execution:

- Exits Triage board when requirements are complete
- Enters Backlog board ready for prioritization

## Custom Fields

### Type (Single Select)

Categorizes what kind of work the issue represents.

**Values:**

| Type | Description | Use When |
|------|-------------|----------|
| Defect | Issue in released code | Production bug affecting users |
| Bug | Issue in unreleased code | Development bug found before release |
| Feature | New functionality | Building something that didn't exist |
| Enhancement | Improvement to existing | Making something better |
| Task | Development work (non-user-facing) | Refactoring, testing, tooling, maintenance |
| Docs | Documentation only | README, guides, comments |
| Question | Support or clarification | Need help understanding something |

**Note:** Defect vs Bug distinction helps with release urgency and changelog categorization.

### Priority (Single Select)

Indicates urgency and importance.

**Values:**

| Priority | Description | Response Time |
|----------|-------------|---------------|
| P0 | Critical/Blocking | Drop everything |
| P1 | High priority | Next sprint/release |
| P2 | Medium priority | Planned work |
| P3 | Low priority | Nice to have |

**Prioritization Framework:**

- P0: Blocks users, security issues, data loss
- P1: Important features, significant bugs, deadline-driven
- P2: Normal development work
- P3: Improvements, optimizations, future considerations

### Complexity (Single Select)

Estimates effort required.

**Values:**

| Complexity | Time Estimate | Description |
|------------|---------------|-------------|
| XS | 1-2 hours | Quick fix or small change |
| S | 2-4 hours | Half day of work |
| M | 1-2 days | Standard feature or fix |
| L | 3-5 days | Large feature, needs design |
| XL | 1-2 weeks | Complex feature, multiple components |

**T-shirt sizing** allows quick estimation without detailed time tracking.

### Milestone (GitHub Built-in)

Groups issues into releases. See [ROADMAP.md](./ROADMAP.md) for detailed milestone information.

**Active Milestones:**

- 0.1.0 - Foundation (Oct 2025)
- 0.2.0 - Core Features (Nov 2025)
- 0.3.0 - Enhanced Memory & Agents (Dec 2025)
- 0.4.0 - Extended Commands & Obsidian (Jan 2026)
- 0.5.0 - Project Agents (Feb 2026)
- 0.6.0 - Knowledge Sync (Mar 2026)
- 1.0.0 - First Stable Release (Apr 2026)
- Future - Post-1.0 features

### Status (Single Select)

Tracks workflow state and resolution.

**Workflow States:**

| Status | Description | Board | Next Step |
|--------|-------------|-------|-----------|
| Parking Lot | Ideas for future consideration | Triage | Move to Triage when ready to evaluate |
| Triage | Being reviewed and refined | Triage | Define requirements, move to Ready or close |
| Ready | Requirements complete, awaiting prioritization | Both | Prioritize for development |
| Prioritized | Queued for development | Backlog | Start work when ready |
| In Progress | Actively being worked on | Backlog | Complete development |
| In Review | Awaiting review or deployment | Backlog | Get reviewed, test, deploy |

**Resolution States:**

| Status | Description | When to Use |
|--------|-------------|-------------|
| Done | Completed successfully | Feature shipped, bug fixed |
| Won't Fix | Decided not to fix/implement | Not aligned with goals, out of scope |
| Duplicate | Duplicate of another issue | Same as existing issue |
| Invalid | Not a valid issue | Not actually a problem, misunderstanding |

### Sub-issues Progress (Built-in)

Automatically tracks completion of sub-tasks.

- Shows progress bar: "2 of 5 tasks complete"
- Use for breaking down large features
- Sub-issues are created as normal issues, linked via tasklist

## Automation

### Auto-add to Project

**Trigger:** New issue created in linked repository
**Filter:** `is:issue`
**Action:** Add to project with Status: **Triage**

**Why:** Ensures all issues are tracked, no manual step needed.

### Auto-archive Items

**Trigger:** Issue closed for 2+ weeks
**Filter:** `is:issue is:closed updated:<@today-2w`
**Action:** Archive item (hide from board)

**Why:** Keeps board clean, closed issues don't clutter views, but remain searchable.

**Grace Period:** 2 weeks allows recently closed issues to stay visible for reference.

### Item Reopened

**Trigger:** Closed issue is reopened
**Filter:** `is:issue`
**Action:** Set Status to **Triage**

**Why:** Reopened issues need re-evaluation, send back to Triage.

## Workflow Guide

### Creating Issues

1. **Create issue** in GitHub (repo or from project board)
2. **Auto-added** to Triage status
3. **Fill in details:**
   - Clear title and description
   - Set Type
   - Set Priority (if known)
   - Assign to Milestone (if known)
   - Estimate Complexity (optional)

### Triage Process

**Goal:** Decide if/when to work on this issue

1. **Review** the issue in Triage column
2. **Clarify** - Ask questions, gather requirements
3. **Decide:**
   - **Valid and defined?** → Move to **Ready**
   - **Needs more info?** → Leave in **Triage**, request details
   - **Future idea?** → Move to **Parking Lot**
   - **Won't do?** → Move to **Won't Fix**, close issue
   - **Duplicate?** → Move to **Duplicate**, link to original, close issue
   - **Not a real issue?** → Move to **Invalid**, close issue

### Development Workflow

**Ready → Prioritized:**

- Review Ready column
- Decide what to work on next
- Move to Prioritized (creates queue)

**Prioritized → In Progress:**

- Pick top item from Prioritized
- Start work
- Move to In Progress

**In Progress → In Review:**

- Development complete
- Create PR (link to issue)
- Move to In Review
- Request review or deploy

**In Review → Done:**

- Review approved / deployment successful
- Move to Done
- Close issue in GitHub
- Auto-archives after 2 weeks

### Using Sub-tasks

**For large features**, break into sub-issues:

1. Create parent issue (e.g., "Personality Builder")
2. Create sub-issues (e.g., "Create questionnaire", "Design YAML schema")
3. Link via tasklist in parent:

   ```markdown
   ## Sub-tasks
   - [ ] #16 Create questionnaire
   - [ ] #17 Design YAML schema
   - [ ] #18 Implement preview mode
   ```

4. Track progress at both levels
5. Close parent when all sub-issues complete

**Note:** Both parent and sub-issues appear on board with `is:issue` auto-add filter.

## Views & Filtering

### Default Views

**Triage** (Board)

- Group by: Status
- Columns: Parking Lot | Triage | Ready | Won't Fix | Duplicate | Invalid
- Purpose: Issue evaluation

**Backlog** (Board)

- Group by: Status
- Columns: Ready | Prioritized | In Progress | In Review | Done
- Purpose: Development execution

### Additional Views (Optional)

You can create additional views for different perspectives:

**By Priority** (Board)

- Group by: Priority
- Columns: P0 | P1 | P2 | P3
- Purpose: See urgent work

**By Milestone** (Board)

- Group by: Milestone
- Columns: 0.1.0 | 0.2.0 | 0.3.0 | etc.
- Purpose: See release grouping

**All Issues** (Table)

- Layout: Table
- All fields visible
- Purpose: Detailed management, filtering, bulk editing

### Filtering

**Common filters:**

```text
# Only P0 and P1 issues
priority:P0,P1

# Only bugs and defects
type:Bug,Defect

# Only 0.1.0 milestone
milestone:"0.1.0"

# In progress or review
status:"In Progress","In Review"

# Assigned to you
assignee:@me

# High complexity features
type:Feature complexity:L,XL
```

## Labels (Minimal Set)

**GitHub labels are separate from project custom fields.**

We use minimal labels for:

- `good-first-issue` - Shows up in GitHub contributor discovery
- `help-wanted` - Seeking community help
- `breaking-change` - For changelog automation
- `duplicate` - Visual indicator for duplicates
- `wontfix` - Visual indicator for won't fix

**Most categorization happens via custom fields (Type, Priority, etc.).**

## Best Practices

### Issue Hygiene

- ✅ **Clear titles** - Describe the issue concisely
- ✅ **Detailed descriptions** - Include context, steps to reproduce, expected behavior
- ✅ **Set Type** - Always categorize
- ✅ **Set Priority** - For anything not P2 (medium default)
- ✅ **Link to milestones** - Group by release
- ✅ **Estimate complexity** - Helps with planning
- ✅ **Close when done** - Don't leave stale open issues

### Board Management

- ✅ **Regular triage** - Review Triage column daily/weekly
- ✅ **Limit WIP** - Don't overload In Progress
- ✅ **Update status** - Move issues through workflow promptly
- ✅ **Close resolved issues** - Keep board current
- ✅ **Review Parking Lot** - Periodically evaluate if ideas should be promoted

### Using with AIDA

**Future AIDA features could:**

- Auto-suggest Type based on issue content
- Auto-estimate Complexity based on description
- Auto-assign to Milestone based on priority and dependencies
- Suggest which development agents to invoke
- Generate issue summaries and updates
- Track time spent on issues
- Learn prioritization patterns

**For now, include agent mentions in issue descriptions:**

```markdown
## Agents to Invoke
@shell-script-specialist - For install.sh work
@qa-engineer - For testing
@privacy-security-auditor - For security review
```

## Troubleshooting

### Issue Not Auto-Added

**Check:**

- Is repository linked to project?
- Is auto-add workflow enabled?
- Is filter `is:issue` configured correctly?
- Is it actually an issue (not a PR)?

### Can't Find Closed Issue

**Closed issues are archived after 2 weeks.**

**To view:**

- Project → Filters → "Show archived items"
- Or search repo issues directly

### Too Many Sub-issues Cluttering Board

**Options:**

- Filter to hide sub-issues (no built-in filter, would need labels)
- Manually don't add sub-issues to project (skip auto-add)
- Accept granular tracking (recommended)

### Status Not Updating

**Remember:**

- Status is project-level custom field
- Closing issue in GitHub doesn't auto-update Status
- You set Status manually, THEN close issue

## Future Enhancements

**Planned improvements:**

- Issue templates (auto-fill Type, Priority)
- More automation workflows
- GitHub Actions integration
- Changelog generation from closed issues
- Metrics dashboard (velocity, cycle time)
- AIDA-powered project management

## Contributing

When contributing to AIDA:

1. Create or claim an issue
2. Comment to let others know you're working on it
3. Create PR linked to issue
4. Update issue status as you progress
5. Request review when ready

See main [CONTRIBUTING.md](../../CONTRIBUTING.md) for full guidelines.

---

**Questions or suggestions?** Open an issue with Type: Question!
