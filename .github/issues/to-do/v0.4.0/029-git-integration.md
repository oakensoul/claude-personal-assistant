---
title: "Implement git integration and code review assistance"
labels:
  - "type: feature"
  - "priority: p2"
  - "effort: medium"
##   - "milestone: 0.4.0"
# Implement git integration and code review assistance

## Description

Implement git awareness and code review assistance to help developers understand repository context, review changes, suggest commit messages, and assist with git workflows.

## Acceptance Criteria

- [ ] Git repository detection and context awareness
- [ ] Current branch and status display
- [ ] Code review from git diff: `aida review`
- [ ] Commit message suggestions based on changes
- [ ] Branch and PR tracking in knowledge base
- [ ] Integration with Dev Assistant agent
- [ ] Support for common git workflows
- [ ] Automated checks (bugs, style, security)
- [ ] Review summary generation
- [ ] CLI commands for git operations

## Implementation Notes

### Git Context Awareness

**Automatic Detection**:

```python
def detect_git_context():
    if is_git_repository():
        return {
            'repository': get_repo_name(),
            'branch': get_current_branch(),
            'remote': get_remote_url(),
            'status': get_git_status(),
            'uncommitted_changes': has_uncommitted_changes(),
            'unpushed_commits': has_unpushed_commits(),
            'last_commit': get_last_commit()
        }
    return None
```text

**Context Display**:

```bash
$ aida status

# AIDA System Status
Git Context:
  Repository: claude-personal-assistant
  Branch: feature/git-integration
  Status: 3 files modified, 1 file staged
  Unpushed: 2 commits ahead of origin/main

  Recent commits:
    a1b2c3d - Add git integration (2 hours ago)
    d4e5f6g - Update documentation (3 hours ago)

[rest of status...]
```json

### Code Review Assistance

**Review Current Changes**:

```bash
$ aida review

Analyzing uncommitted changes...

Files changed: 3
  • src/git-integration.ts (152 lines added, 23 deleted)
  • src/types.ts (8 lines added)
  • tests/git-integration.test.ts (94 lines added)

Running automated checks...
  ✓ Linting (ESLint)
  ✓ Type checking (TypeScript)
  ✓ Tests (Jest)
  ⚠️  Security scan (1 warning)

# Code Review Summary:
### src/git-integration.ts

**Strengths**:
  ✓ Good error handling
  ✓ Comprehensive TypeScript types
  ✓ Well-documented functions

**Issues Found**:

1. **Potential Bug** (Line 47) - MEDIUM
   ```typescript
   const branch = await execCommand('git branch --show-current');
   return branch.trim();  // Could be empty string in detached HEAD
   ```json

   **Fix**: Check for detached HEAD state

   ```typescript
   const branch = await execCommand('git branch --show-current');
   if (!branch.trim()) {
     const sha = await execCommand('git rev-parse --short HEAD');
     return `detached at ${sha.trim()}`;
   }
   return branch.trim();
   ```

2. **Security Warning** (Line 89) - LOW

   ```typescript
   await execCommand(`git commit -m "${message}"`);  // Injection risk
   ```text

   **Fix**: Use parameterized command or escape properly

   ```typescript
   await execCommand('git', ['commit', '-m', message]);
   ```

3. **Performance** (Line 112) - LOW

   ```typescript
   for (const file of files) {
     await analyzeFile(file);  // Sequential, could be parallel
   }
   ```text

   **Fix**: Use Promise.all for parallel processing

### tests/git-integration.test.ts

**Strengths**:
  ✓ Good test coverage (87%)
  ✓ Tests both success and error cases

**Suggestions**:
  • Add test for detached HEAD scenario
  • Add test for commit message with special characters
  • Consider adding integration tests

# Overall Assessment
**Quality Score**: 8.5/10

**Recommendation**: Fix security warning before committing

Next Steps:

  1. Fix injection vulnerability (line 89)
  2. Add detached HEAD check (line 47)
  3. Consider parallel file processing
  4. Add suggested tests

Would you like me to generate a corrected version?

```text

**Review Specific File**:
```bash
$ aida review src/git-integration.ts --detailed

# Detailed Review: src/git-integration.ts
[Detailed line-by-line analysis]
```

### Commit Message Suggestions

```bash
$ aida commit

Analyzing staged changes...

Staged files (2):
  • src/git-integration.ts
  • tests/git-integration.test.ts

Change summary:
  • Added git context detection
  • Added code review functionality
  • Added unit tests

# Suggested commit messages:
1. Conventional Commits (Recommended):
   ```text

   feat(git): add git integration and code review

- Implement git context detection
- Add code review analysis functionality
- Add unit tests for git integration
- Include security and performance checks

   BREAKING CHANGE: None

   ```text

2. Simple:
   ```

   Add git integration and code review features

   ```text

3. Detailed:
   ```sql

   Add git integration with code review capabilities

   This commit introduces git repository awareness and automated code
   review functionality. The system can now detect git context, analyze
   changes, and provide actionable feedback.

   Features:

- Git repository detection
- Branch and status tracking
- Automated code review with security and performance checks
- Commit message suggestions
- Integration with Dev Assistant agent

   Tests added for all new functionality with 87% coverage.

   ```text

Select option (1-3) or write custom: 1

Committing with message:

feat(git): add git integration and code review

- Implement git context detection
- Add code review analysis functionality
- Add unit tests for git integration
- Include security and performance checks

BREAKING CHANGE: None

Proceed? (Y/n): y

✓ Committed: a1b2c3d
```

### Branch and PR Tracking

**Track Branch Context**:

```markdown
# ~/.claude/memory/context/current.md

## Current Work Context

**Active Branch**: feature/git-integration
**Started**: 2025-10-04 09:00
**Purpose**: Implement git integration and code review assistance

**Related**:
- Issue #029
- ADR-005 (decision to integrate git)
- Project: AIDA Core Features

**Progress**:
- [x] Git context detection
- [x] Code review functionality
- [x] Commit message generation
- [ ] PR review assistance
- [ ] Branch management commands

**Notes**:
- Using simple-git library for git operations
- Security checks integrated via eslint-plugin-security
- Performance analysis uses custom metrics
```

### Git Workflow Support

**Feature Branch Workflow**:

```bash
$ aida git feature start "Add Obsidian integration"

Creating feature branch...

✓ Created branch: feature/obsidian-integration
✓ Switched to new branch

I'll help you track this work:
  • Purpose: Add Obsidian integration
  • Related issue: #028
  • Started: 2025-10-04 10:30

Would you like me to:
  [T] Create task list for this feature
  [D] Document decision to implement
  [P] Create project note in Obsidian
  [N] No, just track the branch

Choice: T

Creating task list...
✓ Added tasks for Obsidian integration feature

  High Priority:
  • Implement bidirectional task sync
  • Add automatic daily note creation
  • Create knowledge sync functionality

  Medium Priority:
  • Add conflict resolution
  • Implement CLI commands
  • Write tests

You're all set! Let me know when you're ready to commit.
```

**Commit and Review Flow**:

```bash
$ aida git commit

Checking before commit...
  ⚠️  3 files modified but not staged
  ⚠️  1 TODO comment added (line 47 in src/obsidian.ts)

Stage all modified files? (Y/n): y

✓ Staged 3 files

Running pre-commit checks...
  ✓ Linting
  ✓ Type checking
  ✓ Unit tests (23 passed)
  ⚠️  Code review found 1 suggestion

Review suggestion:
  Line 47: TODO comment should be tracked
  Would you like me to create a task for this? (Y/n): y

✓ Created task: "Remove TODO in obsidian.ts after implementing error handling"

Generating commit message...
[suggests message]

Commit complete! Next steps:
  • Review changes one more time
  • Push to remote when ready
  • Create PR (I can help with PR description)
```

### PR Review Assistance

```bash
$ aida git pr create

Creating pull request...

Analyzing changes on feature/obsidian-integration:
  • 8 commits
  • 15 files changed (+847, -123)
  • 3 days of work

Generating PR description...

---
Title: Add full Obsidian integration

## Summary

Implements comprehensive Obsidian integration including bidirectional task sync, automatic daily note creation, knowledge management, and decision record synchronization.

## Changes

- **Task Sync**: Bidirectional sync between AIDA and Obsidian
- **Daily Notes**: Automatic creation and updates
- **Knowledge**: Learnings sync to Obsidian vault
- **Decisions**: ADRs exported to Obsidian format
- **CLI**: Added `aida obsidian` commands

## Test Plan

- [x] Unit tests (95% coverage)
- [x] Integration tests with real Obsidian vault
- [x] Manual testing on macOS and Linux
- [x] Conflict resolution tested
- [x] Performance tested (sync < 5 seconds)

## Breaking Changes

None

## Related Issues

Closes #028

---

Push and create PR? (Y/n): y

✓ Pushed to origin/feature/obsidian-integration
✓ Created PR #45: Add full Obsidian integration

PR created: https://github.com/user/repo/pull/45

I'll track this PR in your context. Let me know when you need help with:
  • Responding to review comments
  • Addressing change requests
  • Merging the PR
```

### CLI Commands

```bash
# Git status and context
aida git status                  # Enhanced git status
aida git context                 # Show current git context

# Code review
aida review                      # Review uncommitted changes
aida review --staged             # Review staged changes only
aida review [file]               # Review specific file
aida review --commit [sha]       # Review specific commit

# Commit assistance
aida commit                      # Interactive commit with checks
aida git message                 # Generate commit message only

# Branch management
aida git feature start [name]    # Start new feature branch
aida git feature finish          # Finish feature (merge)
aida git branch track [name]     # Track branch in context

# PR assistance
aida git pr create               # Create PR with generated description
aida git pr review [number]      # Review someone else's PR
aida git pr status               # Status of your PRs

# History and analysis
aida git log                     # Enhanced git log
aida git blame [file]            # Git blame with context
aida git history [file]          # File change history
```

## Dependencies

- #025 (Dev Assistant agent for code review)
- #023 (Knowledge capture for git learnings)
- #022 (Memory for branch tracking)

## Related Issues

- #009 (Dev Assistant agent definition)
- #024 (Decision documentation for architecture decisions)

## Definition of Done

- [ ] Git context detection works
- [ ] Code review provides actionable feedback
- [ ] Commit message suggestions are helpful
- [ ] Branch tracking in memory works
- [ ] Common git workflows supported
- [ ] PR description generation works
- [ ] Automated checks (lint, test, security) run
- [ ] CLI commands are intuitive
- [ ] Performance is acceptable (review < 10 seconds)
- [ ] Documentation explains git features
- [ ] Examples demonstrate workflows
