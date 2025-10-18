---
slug: workflow-commands
title: "Create /issue, /review, /project commands - workflow management"
type: feature
milestone: v0.1.0
labels: foundational, commands, workflow
estimated_effort: 10
status: draft
created: 2025-10-10
depends_on: ["versioning-system"]
---

# Create /issue, /review, /project commands - workflow management

## Problem

Current workflow commands are scattered and GitHub-specific:

- `create-issue`, `publish-issue` - individual commands
- `open-pr`, `cleanup-main` - separate commands
- `workflow-init`, `github-init`, `github-sync` - redundant/overlapping

Users need platform-agnostic workflow commands that work with GitHub, GitLab, Bitbucket, or local-only development.

## Solution

Create three consolidated workflow commands with subcommands.

### `/issue` Command

```bash
/issue create [title]          # Create local issue draft
/issue edit [slug]              # Edit existing draft
/issue list                     # List all drafts
/issue publish [slug|--all]     # Publish to forge (GitHub/GitLab/etc)
/issue close [number]           # Close issue
/issue view [number]            # View issue details
```

**Flexibility:**

- Works with local drafts (no forge needed)
- Publishes to GitHub, GitLab, or Bitbucket
- Falls back gracefully if no forge configured

### `/review` Command

```bash
/review submit                  # Create PR/MR
/review status                  # Check review status
/review update                  # Update based on feedback
/review merge                   # Merge when approved
/review cleanup                 # Post-merge cleanup
```

**Flexibility:**

- Detects forge type (GitHub/GitLab/Bitbucket)
- Adapts to workflow (PR, MR, patch submission)
- Works with or without CI/CD
- Gracefully handles local-only repositories

### `/project` Command

```bash
/project init                   # Initialize project
/project sync                   # Sync with forge
/project status                 # Project status
/project config                 # View/edit configuration
```

**Flexibility:**

- Detects available forges
- Works with multiple remotes
- Handles local-only projects
- Adapts to existing project structure

## Implementation Tasks

- [ ] **Design `/issue` command**
  - Local draft creation
  - Forge detection (gh, glab, bb)
  - Publishing workflow
  - Status tracking
  - Template support

- [ ] **Implement `/issue create`**
  - Interactive prompts
  - Slug generation
  - Frontmatter handling
  - Local storage in `.github/issues/drafts/`

- [ ] **Implement `/issue publish`**
  - Detect forge type
  - Convert draft to forge format
  - Handle labels/milestones
  - Track published issues

- [ ] **Implement `/issue list` and `/issue view`**
  - List local drafts
  - Show draft details
  - Display published status

- [ ] **Design `/review` command**
  - Forge detection
  - PR/MR creation
  - Status checking
  - Merge handling
  - Cleanup workflow

- [ ] **Implement `/review submit`**
  - Generate PR/MR title and body
  - Detect base branch
  - Push to remote
  - Create PR/MR via CLI tool

- [ ] **Implement `/review status`**
  - Show review comments
  - Display CI/CD status
  - List required approvals
  - Show merge conflicts

- [ ] **Implement `/review merge` and `/review cleanup`**
  - Merge PR/MR
  - Delete remote branch
  - Update local main
  - Restore stashed work
  - Clean up context

- [ ] **Design `/project` command**
  - Project initialization
  - Forge sync
  - Configuration management
  - Status reporting

- [ ] **Implement `/project init`**
  - Detect existing structure
  - Create necessary directories
  - Initialize forge integration
  - Set up configuration

- [ ] **Implement `/project sync`**
  - Sync labels
  - Sync milestones
  - Sync project boards
  - Verify webhooks

- [ ] **Add comprehensive error handling**
  - Forge not available
  - Authentication failures
  - Network issues
  - Configuration errors

- [ ] **Documentation**
  - Usage examples for each command
  - Platform-specific guides
  - Migration from v1 commands

## Success Criteria

- [ ] All three commands work with GitHub
- [ ] Commands adapt to GitLab
- [ ] Commands work locally without forge
- [ ] Zero functionality lost from v1 commands
- [ ] Tests pass on macOS and Linux
- [ ] Documentation covers all platforms

## Testing Scenarios

```bash
# Test with GitHub
/issue create "New feature"
/issue publish feature-slug
/review submit
/review merge

# Test with GitLab
# (configure GitLab remote)
/issue publish feature-slug
/review submit

# Test local-only
# (no remote configured)
/issue create "Local work"
/issue list
/project status
```

## Dependencies

- Requires: versioning-system (#1)
- Blocks: None (can be developed in parallel with other commands)

## Replaces v1 Commands

- `create-issue` → `/issue create`
- `publish-issue` → `/issue publish`
- `open-pr` → `/review submit`
- `cleanup-main` → `/review cleanup`
- `workflow-init` → `/project init`
- `github-init` → `/project init`
- `github-sync` → `/project sync`

## Notes

- Focus on platform-agnostic design
- Graceful fallbacks when tools unavailable
- Clear error messages guide users to install missing tools
- Default to detected environment
