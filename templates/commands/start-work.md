---
name: start-work
description: Automates starting work on a GitHub issue by assigning it, setting up the development environment, and capturing requirements
args:
  issue-id:
    description: GitHub issue number to start work on
    required: true
---

# Start Work Command

Automates the beginning of work on a GitHub issue by assigning it to you, setting up the development environment, and capturing requirements.

## Instructions

1. **Check for issue ID argument**:
   - If no issue ID is provided, display help message and exit
   - Help message should include:

     ```text
     # Start Work

     Automates starting work on a GitHub issue by setting up your development environment.

     ## Usage

     /start-work <issue-id>

     ## Arguments

     issue-id    GitHub issue number (required)
                 Example: 16, 34, 42

     ## What It Does

     1. Fetches issue details from GitHub
     2. Assigns the issue to you automatically
     3. Creates an appropriately named branch
     4. Switches to the new branch
     5. Creates work directory: .github/issues/in-progress/issue-{id}/
     6. Generates README.md with issue details

     ## Examples

     # Start work on issue 16
     /start-work 16

     # Start work on issue 42
     /start-work 42

     ## Work Directory Structure

     .github/issues/in-progress/issue-{id}/
     └── README.md              # Issue details and requirements

     ## Branch Naming Convention

     - Required format: milestone-v{x.y}/{type}/{id}-descriptive-name
     - Examples:
       - milestone-v0.1/feature/19-open-pr-command
       - milestone-v0.1/defect/23-fix-authentication
       - milestone-v1.2/chore/45-update-dependencies
     - Milestone and issue type are extracted from GitHub issue
     - All work must have a milestone assigned

     ## Documentation

     Part of workflow automation suite:
     - /start-work - Initialize work on an issue
     - /business-analysis - Enhance business requirements
     - /technical-analysis - Create implementation plan
     - /open-pr - Create pull request
     - /cleanup-main - Post-merge cleanup
     ```

2. **Parse the issue ID argument**:
   - Extract numeric issue ID from argument
   - Validate it's a positive integer

3. **Fetch GitHub issue details**:
   - Run `gh issue view <issue-id> --json number,title,body,labels,state,assignees,milestone`
   - If issue not found, show error and exit
   - If network error, show error and exit
   - **If no milestone is assigned, halt and show error**: "Issue #{id} must have a milestone assigned. Please assign a milestone before starting work."

4. **Assign issue to current user**:
   - Run `gh issue edit <issue-id> --add-assignee @me`
   - If assignment succeeds: Continue to next step
   - If assignment fails (permissions, network, etc.):
     - Display warning: "Warning: Could not assign issue to you. Continuing with workflow..."
     - Log the error for debugging
     - Continue to next step (non-blocking error)
   - Note: This ensures the issue is tracked to you before you begin work

5. **Check Current State (Idempotency)**:
   - **Determine expected branch name**:
     - Extract milestone version from issue
     - Extract type from issue labels
     - Generate expected branch name: `milestone-v{x.y}/{type}/{id}-{description}`

   - **Check if already working on this issue**:
     - Get current branch: `git branch --show-current`
     - Check if current branch matches expected branch for this issue
     - Check if work directory exists: `.github/issues/in-progress/issue-{id}/`
     - If both match:
       - Display: "✓ Already working on issue #{id}"
       - Display: "  Branch: {current-branch}"
       - Display: "  Work directory: .github/issues/in-progress/issue-{id}/"
       - Exit successfully (true idempotent - nothing to do)

   - **Check if branch exists for this issue**:
     - Search for branch matching pattern for this issue: `git branch --list "*/{id}-*"`
     - If branch exists but not currently on it:
       - Display: "Found existing branch for issue #{id}: {branch-name}"
       - Check for uncommitted changes: `git status --porcelain`
       - If uncommitted changes exist:
         - Display current changes summary
         - Prompt: "You have uncommitted changes. How to proceed?"
           - [s] Stash changes and switch to issue branch
           - [c] Commit changes first, then switch
           - [a] Abort and stay on current branch
         - If stash: Run `git stash push -m "Auto-stash before switching to issue #{id}"`
         - If commit: Prompt for commit message, run `git commit -am "{message}"`
         - If abort: Exit command
       - If no uncommitted changes:
         - Switch to branch: `git checkout {branch-name}`
         - Display: "✓ Switched to existing branch: {branch-name}"
       - Skip to step 8 (check for existing work directory)

   - **Check if on a different issue branch**:
     - Get current branch name
     - Check if it matches pattern `milestone-v*/*/[0-9]*-*` (an issue branch)
     - Extract issue number from current branch if possible
     - If on different issue branch:
       - Display: "Currently working on different issue (branch: {current-branch})"
       - Prompt: "How should we create branch for issue #{id}?"
         - [1] Switch to main, then branch (recommended - clean start)
         - [2] Branch off current branch (keeps current changes)
         - [3] Abort and let me finish current work first
       - Handle choice:
         - Option 1: `git checkout main && git pull` then continue to step 6
         - Option 2: Continue to step 6 (will branch from current)
         - Option 3: Exit command

   - **If none of above apply**: Continue to step 6 normally

6. **Update GitHub Project Status** (if enabled):
   - Read `~/.claude/workflow-config.json` (or `.claude/workflow-config.json` in project root)
   - Check if `workflow.github_project.enabled` is `true`
   - If enabled:
     - Get status transition: `workflow.github_project.status_transitions.start_work`
     - Extract `from` status (e.g., "Prioritized") and `to` status (e.g., "In Progress")
     - Get status field name: `workflow.github_project.status_field` (e.g., "Status")
     - Update issue status using GitHub CLI:

       ```bash
       gh issue edit <issue-id> --add-project-field "<status-field>=<to-status>"
       ```

     - If update succeeds:
       - Display confirmation: "✓ Moved issue to '{to-status}' status"
       - Continue to next step
     - If update fails (permissions, network, project not found, etc.):
       - Display warning: "Warning: Could not update GitHub Project status. Continuing with workflow..."
       - Log the error for debugging
       - Continue to next step (non-blocking error)
   - If not enabled: Skip this step silently
   - Note: This keeps your GitHub Project board in sync with your workflow

7. **Prepare Branch Context**:
   - Extract milestone version (e.g., "v0.1 - Development Infrastructure" → "v0.1")
   - Extract issue type from labels (priority order):
     - "bug" or "defect" → `defect`
     - "enhancement" or "feature" → `feature`
     - "chore" → `chore`
     - "task" → `task`
     - Default to `feature` if no matching label
   - Generate descriptive name from issue title:
     - Convert to lowercase
     - Replace spaces with hyphens
     - Remove special characters
     - Keep first 3-5 words maximum
   - Build branch name suggestion: `milestone-v{x.y}/{type}/{id}-{description}`
   - Example: Issue #19 "Implement /open-pr command" with milestone "v0.1" and label "enhancement" → `milestone-v0.1/feature/19-open-pr-command`

8. **Delegate Branch Creation to devops-engineer**:
   - Invoke `devops-engineer` subagent to create and checkout branch:

     ```text
     Context:
     - Suggested branch name: {branch-name}
     - Issue number: {issue-id}
     - Issue title: {title}
     - Milestone: {milestone}
     - Type: {type}

     Tasks:
     1. Check if branch already exists: git branch --list <branch-name>
     2. If branch exists, ask user if they want to:
        - Switch to existing branch
        - Create new branch with different name
        - Cancel operation
     3. If branch doesn't exist or user wants new name:
        - Create and checkout branch: git checkout -b <branch-name>
        - Confirm branch creation success
     4. Verify current branch: git branch --show-current

     Return: Final branch name created/switched to, confirmation status
     ```

   - If delegation fails or user cancels, halt command
   - Store final branch name for work directory setup

9. **Check for existing work directory**:
   - Check if `.github/issues/in-progress/issue-{id}/` already exists
   - If exists (rare - may have been created manually):
     - Inform user: "Work directory already exists. Using existing README."
     - Skip README generation (preserve existing content)
     - Continue to next step
   - If does not exist (normal case):
     - Create directory: `.github/issues/in-progress/issue-{id}/`
     - Use `mkdir -p` to create parent directories if needed
     - Continue to README generation

10. **Generate README.md with issue details** (only if directory was just created):
    - File: `.github/issues/in-progress/issue-{id}/README.md`
    - **Parse estimated effort from issue body**: Look for "## Estimated Effort" section and extract hours value
    - Format:

      ```markdown
      ---
      issue: {number}
      title: "{title}"
      status: "{state}"
      created: "YYYY-MM-DD HH:MM:SS"
      estimated_effort: {hours}  # Optional: if found in issue body
      ---

      # Issue #{number}: {title}

      **Status**: {state}
      **Labels**: {labels}
      **Milestone**: {milestone}
      **Assignees**: {assignees}

      ## Description

      {body}

      ## Work Tracking

      - Branch: `{branch-name}`
      - Started: {current-date}
      - Work directory: `.github/issues/in-progress/issue-{id}/`

      ## Related Links

      - [GitHub Issue](https://github.com/{owner}/{repo}/issues/{number})
      - [Project Board](https://github.com/{owner}/{repo}/projects)

      ## Notes

      Add your work notes here...
      ```

11. **Confirm success**:
    - Display summary:

      ```text
      ✓ Started work on issue #{number}

      Branch: {branch-name}
      Work directory: .github/issues/in-progress/issue-{id}/
      README: .github/issues/in-progress/issue-{id}/README.md
      Status: {to-status} (if GitHub Project integration enabled)

      Next steps:
      1. Review issue details in work directory README
      2. Use /business-analysis if requirements need clarification
      3. Use /technical-analysis when ready to plan implementation
      4. Commit your work regularly
      5. Use /open-pr when ready to create pull request
      ```

## Examples

```bash
# Start work on issue 16
/start-work 16

# Start work on bug issue 23
/start-work 23
```

## Error Handling

- **No issue ID provided**: Show help message with usage examples
- **Invalid issue ID format**: Show error and valid format (positive integer)
- **Issue not found**: Display error with issue number and suggest checking issue exists
- **No milestone assigned**: Halt and show error "Issue #{id} must have a milestone assigned. Please assign a milestone before starting work."
- **Assignment failure**: Show warning "Warning: Could not assign issue to you. Continuing with workflow..." (non-blocking)
- **GitHub Project status update failure**: Show warning "Warning: Could not update GitHub Project status. Continuing with workflow..." (non-blocking)
- **Network error**: Display error and suggest checking internet connection
- **Branch already exists**: Ask user for action (switch/rename/cancel)
- **Git error**: Display git error message and suggest checking repository state
- **Permission error**: Display error and suggest checking file permissions

## Notes

- This command is designed to work with the project's GitHub workflow
- **Idempotent**: Safe to re-run - detects existing work and offers appropriate actions
- **Automatic assignment**: Issues are automatically assigned to the current GitHub user when work begins
- **GitHub Project integration**: Automatically moves issues from "Prioritized" to "In Progress" status when work begins (if enabled in workflow-config.json)
- **Concurrent work supported**: Can work on multiple issues simultaneously
- **Smart branch switching**: Handles uncommitted changes gracefully (stash/commit/abort)
- **Work directories gitignored**: `.github/issues/in-progress/` is gitignored for local work
- Branch naming follows project conventions in CONTRIBUTING.md
- Part of a comprehensive workflow automation suite
- **Integration with `/publish-issue`**: Works with published GitHub issues (drafts must be published first)

## Related Commands

- `/create-issue` - Create a new GitHub issue with optional estimated effort (stored in issue body)
- `/business-analysis <issue-id>` - Enhance business requirements for an issue
- `/technical-analysis <issue-id>` - Create implementation plan for an issue
- `/open-pr` - Create pull request for current branch
- `/cleanup-main` - Clean up after PR merge
- `/track-time <duration>` - Log development time
