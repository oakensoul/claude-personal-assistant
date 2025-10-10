---
slug: work-command
title: "Create /work command - universal development workflow"
type: feature
milestone: v0.1.0
labels: foundational, commands, workflow
estimated_effort: 12
status: draft
created: 2025-10-10
depends_on: ["versioning-system"]
---

# Create /work command - universal development workflow

## Problem

Developers have different workflows:
- Some use issues, some don't
- Some use branches, some don't
- Some use PRs, some commit directly
- Some use Git, some don't

Current commands assume a specific workflow (GitHub + issues + PRs), making AIDA less accessible.

## Solution

Create a flexible `/work` command that adapts to YOUR workflow, whatever it is.

### Core Subcommands

```bash
/work start [issue|description]   # Begin work (flexible!)
/work plan                        # Plan implementation
/work implement                   # Guided implementation
/work save                        # Save progress (WIP)
/work commit                      # Create atomic commits
/work track [time]                # Track time
/work status                      # What am I working on?
/work pause                       # Pause work (stash)
/work resume                      # Resume paused work
/work complete                    # Finish work session
```

### Flexibility Examples

**With Issue Tracking:**
```bash
/work start 42
# → Fetches issue #42
# → Creates branch: feature/42-add-dark-mode
# → Sets up context
```

**Ad-hoc with Branch:**
```bash
/work start "refactor auth system"
# → Creates branch: work/refactor-auth-system
# → No issue tracking
```

**No Branch:**
```bash
/work start "fix typo" --no-branch
# → Stays on current branch
# → Still tracks work
```

**No Git:**
```bash
/work start "design new feature"
# → Creates work session
# → Tracks time and notes
# → No version control needed
```

## Implementation Tasks

- [ ] **Design `/work start` flexibility**
  - Detect if Git available
  - Detect if issue tracking available
  - Parse issue number vs description
  - Handle --no-branch flag
  - Create appropriate context

- [ ] **Implement `/work plan`**
  - Integrate expert-analysis functionality
  - Show planning prompts
  - Generate implementation plan
  - Save plan to work directory

- [ ] **Implement `/work implement`**
  - Show implementation guidance
  - Track progress through tasks
  - Create checkpoints
  - Handle todos

- [ ] **Implement `/work save`**
  - WIP commits for Git users
  - Stash for Git users
  - Session snapshot for non-Git

- [ ] **Implement `/work commit`**
  - Guided atomic commits
  - Conventional commit format
  - Link to issues if applicable
  - Handle non-Git gracefully

- [ ] **Implement `/work track`**
  - Time tracking
  - Work session logging
  - Integration with issue tracking
  - Local-only option

- [ ] **Implement `/work status`**
  - Show current work
  - Show uncommitted changes
  - Show time tracked
  - Show next steps

- [ ] **Implement `/work pause` and `/work resume`**
  - Stash/restore for Git
  - Save/load context
  - Work with multiple sessions

- [ ] **Implement `/work complete`**
  - Finalize work session
  - Summary of work done
  - Suggest next steps (open PR, push, etc.)

- [ ] **Create work session tracking**
  - `.work-sessions/` directory
  - Session metadata
  - Context preservation

- [ ] **Add comprehensive error handling**
  - Git not available
  - Issue tracker not available
  - Branch conflicts
  - Stash conflicts

- [ ] **Documentation**
  - Usage examples for all workflows
  - Flexibility guide
  - Integration guide

## Success Criteria

- [ ] Works with Git + issues
- [ ] Works with Git only (no issues)
- [ ] Works with issues only (no Git)
- [ ] Works with neither (local work)
- [ ] Handles branches correctly
- [ ] Handles no-branch mode
- [ ] Time tracking works in all modes
- [ ] Tests pass on macOS and Linux
- [ ] Documentation covers all scenarios

## Testing Scenarios

```bash
# Test with full integration
/work start 42
/work plan
/work implement
/work track 2h
/work complete

# Test with no issue tracking
/work start "add feature"
/work implement
/work commit
/work complete

# Test with no branch
/work start "quick fix" --no-branch
/work implement
/work commit

# Test with no Git
# (remove .git directory temporarily)
/work start "design work"
/work track 1h
/work status
```

## Dependencies

- Requires: versioning-system (#1)
- Blocks: None (other commands can be built in parallel)

## Notes

- This is the **most important command** - get it right!
- Flexibility is the key feature
- Must handle all workflow combinations gracefully
- Error messages should be helpful, not confusing
- Default to the user's environment, don't force a workflow
