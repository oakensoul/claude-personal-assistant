---
name: open-pr
description: Automates pull request creation with atomic commits, versioning, changelog updates, issue documentation, and selective change stashing
args:
  reviewers:
    description: "Comma-separated list of GitHub usernames to review the PR (overrides workflow-config.json)"
    required: false
    type: string
---

# Open Pull Request Command

Automates the pull request creation process including atomic commits, versioning, changelog updates, proper PR configuration, and issue documentation finalization.

## Usage

```bash
# Use workflow-config.json reviewer strategy
/open-pr

# Override with specific reviewers
/open-pr reviewers="user1,user2,github-copilot[bot]"

# No reviewers (override any strategy)
/open-pr reviewers=""
```

## Instructions

1. **Validate Work Completion**:
   - Check for unstaged or staged changes: `git status --porcelain`
   - If no uncommitted changes found:
     - Check if there are commits ahead of origin: `git rev-list @{u}..HEAD 2>/dev/null | wc -l`
     - If commits exist: Continue (pushing existing commits without new changes)
     - If no commits: Display error: "No changes to commit and no commits to push. Working directory is clean."
   - Verify not on main branch: `git branch --show-current`
   - If on main, display error: "Cannot create PR from main branch. Please create a feature branch first."

1.5. **Handle Uncommitted Changes** (if any changes found in step 1):

- If no uncommitted changes found in step 1, skip this step
- Otherwise, categorize uncommitted changes:

  ```bash
  git status --porcelain
  ```

  - Staged changes: Lines starting with `M`, `A`, `D`, `R`, `C` (space after letter)
  - Unstaged changes: Lines starting with space then `M`, `??`, space then `D`
  - Mixed: Same file appears with both patterns

- **Present Interactive Menu**:

     ```text
     Found uncommitted changes:

     Staged:
       M  lib/installer-common/colors.sh
       A  templates/commands/cleanup-main.md

     Unstaged:
       ?? .github/issues/completed/issue-33/analysis/
        M install.sh

     What would you like to do?
     1. Review each file/group individually (recommended)
     2. Include all changes in this PR
     3. Stash all changes (useful if already have commits to push)
     4. Cancel PR creation

     Choice [1-4]: _
     ```

- **Option 1: Review Individually** (recommended):

  - Group files by logical category:
    - Source code changes
    - Documentation changes
    - Configuration changes
    - Test files
    - Untracked files
  - For each file/group, prompt:

       ```text
       Include 'lib/installer-common/colors.sh' in this PR? (y/n/view)
       - y: Include in PR (stage if unstaged)
       - n: Stash for later
       - view: Show diff before deciding (git diff <file>)
       ```

  - Track "to-stash" list for files user wants to exclude
  - After all files reviewed:

    - If to-stash list is not empty:

      ```bash
      # Stash excluded files with timestamp and -u flag for untracked
      git stash push -u -m "open-pr-excluded-$(date +%Y%m%d-%H%M%S)" -- <file1> <file2> ...
      ```

    - Display summary:

         ```text
         ✓ Changes organized:
           - Including in PR: 2 files
           - Stashed for later: 1 file

         Stash saved: stash@{0} - "open-pr-excluded-20251006-143022"
         Use /cleanup-main after merge to restore stashed changes.
         ```

- **Option 2: Include All**:

  - Stage all changes: `git add -A`
  - Continue to next step with all changes

- **Option 3: Stash All**:

  - Useful when you already have commits to push but have uncommitted changes
  - Stash everything with descriptive message:

    ```bash
    git stash push -u -m "open-pr-all-excluded-$(date +%Y%m%d-%H%M%S)"
    ```

  - Confirm stash succeeded:

       ```text
       ✓ All changes stashed: stash@{0}

       Note: You must have existing commits to push. If working tree is now
       clean with no commits, the PR creation will fail in step 1.

       Use /cleanup-main after merge to restore stashed changes.
       ```

  - Continue to next step (may hit "no changes" error if no commits exist)

- **Option 4: Cancel**:

  - Display: "PR creation cancelled. No changes were made."
  - Exit command immediately

- **Error Handling**:

  - If stash command fails:
    - Display error: "Failed to stash files: <error message>"
    - Ask: "Continue without stashing? (y/n)"
    - If no: Exit command
    - If yes: Proceed with all changes included
  - If user cancels during review (Ctrl+C):
    - Do not modify working tree
    - Exit cleanly

- After this step completes, proceed to next step

2. **Detect Branch Type**:
   - Get current branch name: `git branch --show-current`
   - Check if branch starts with `time-tracking/`
   - If yes, set `is_time_tracking_branch = true` and jump to **Time-Tracking Branch Workflow** (step 2a)
   - If no, continue to step 3 for standard feature branch workflow

2a. **Time-Tracking Branch Workflow** (simplified workflow for time-tracking branches):

- **Validate Time-Tracking Changes**:

  - Check for changes in `.time-tracking/` directory: `git diff --name-only | grep "^\.time-tracking/"`
  - If no time-tracking changes, display error: "No time-tracking changes detected. Time-tracking branches should only modify .time-tracking/ files."
  - Extract date from branch name (format: `time-tracking/{developer}/{YYYY-MM-DD}`)
  - Extract developer name from branch name

- **Calculate Time Summary**:

  - Read `.time-tracking/summary.json` to get total hours
  - Count number of issues logged
  - List changed files for PR body

- **Delegate Simple Git Operations to devops-engineer**:

  - For time-tracking branches, we can handle this simply but still use devops-engineer
  - Invoke `devops-engineer` subagent with context:

       ```text
       Context:
       - Branch type: time-tracking
       - Date: {date}
       - Developer: {developer}
       - Workflow config: Read .claude/workflow-config.json for reviewers.strategy

       Tasks:
       1. Stage all changes (git add .)
       2. Create commit: "chore(time-tracking): log development time for {date}"
       3. Push branch with tracking: git push -u origin <branch-name>
       4. Determine reviewers:
          - If --reviewers parameter provided: Use that value (override config)
          - Otherwise, read workflow-config.json pull_requests.reviewers.strategy:
            * "none": Skip reviewer assignment
            * "query": Prompt user to select reviewers (show team list if available)
            * "list": Assign ALL reviewers from pull_requests.reviewers.team array
            * "round-robin": Select next reviewer from pull_requests.reviewers.team array
            * "auto": Skip reviewer assignment (let GitHub auto-assign)
            * If config missing: Default to "none"
       5. Create PR with appropriate reviewer flags:
          - No reviewers: gh pr create --title "{title}" --body "{body}" --assignee @me --label time-tracking,chore
          - With reviewers: gh pr create --title "{title}" --body "{body}" --assignee @me --reviewer {reviewer-list} --label time-tracking,chore

       Return: PR number, PR URL, reviewers assigned (or "none"/"auto")
       ```

  - If delegation fails, display error and halt

- **Confirm Success**:

  - Display summary from devops-engineer agent:

       ```text
       ✓ Time-Tracking Pull Request Created Successfully

       Date: {date}
       Developer: {developer}
       Branch: {branch-name}
       Total Hours: {hours}h across {issue_count} issues
       PR: #{pr-number} - {pr-url}
       Reviewer: @{reviewer}

       Next steps:
       1. Wait for review from @{reviewer}
       2. PR will be merged to record time logs
       3. Use /cleanup-main after merge to clean up local branches
       ```

- **END** - Skip all remaining steps (3-15) for time-tracking branches

3. **Parse Branch Information** (feature branches only):
   - Get current branch name: `git branch --show-current`
   - Expected format: `milestone-v{x.y}/{type}/{issue-id}-{description}`
   - Extract issue number from branch name
   - If no issue number found, prompt user:
     - Enter issue number manually
     - Create a new GitHub issue (redirect to `/create-issue` command)
     - **DO NOT proceed without issue number**
   - Extract milestone version from branch name (e.g., "v0.1")
   - If no milestone in branch name, halt: "Branch name must include milestone. Format: milestone-v{x.y}/{type}/{issue-id}-{description}"

4. **Fetch Issue Details**:
   - Run `gh issue view <issue-id> --json number,title,body,labels,milestone,assignees`
   - If issue not found, display error and halt
   - Verify issue has milestone assigned
   - If no milestone on issue, halt: "Issue #{id} must have a milestone assigned before creating PR"
   - Verify milestone matches branch milestone
   - If mismatch, warn user and ask which to use

5. **Delegate Branch Status Check to devops-engineer**:
   - Invoke `devops-engineer` subagent to check branch status with main:

     ```text
     Context:
     - Current branch: {branch-name}
     - Operation: Check if branch is behind main and optionally merge

     Tasks:
     1. Fetch latest main: git fetch origin main
     2. Check if branch is behind main: git rev-list --count HEAD..origin/main
     3. If behind main, ask user: "Your branch is X commits behind main. Would you like to merge main into your branch before creating the PR? (y/n)"
     4. If user chooses yes:
        - Run: git merge origin/main
        - If conflicts occur: Display files with conflicts, halt with message
        - If successful: Continue

     Return: Branch status (up-to-date/merged/conflicts), list of conflicts if any
     ```

   - If conflicts detected, halt with message from devops-engineer
   - If merged or up-to-date, continue

6. **Delegate Atomic Commits to devops-engineer**:
   - Invoke `devops-engineer` subagent to create atomic commits:

     ```text
     Context:
     - Changed files need to be committed
     - Use conventional commit format

     Tasks:
     1. Display all changed files: git status --porcelain
     2. Analyze changes and suggest logical groupings:
        - Command files (.claude/commands/)
        - Documentation files (*.md in .github/issues/)
        - Configuration files (package.json, etc.)
        - Source code changes
        - Test files
     3. For each logical group:
        - Ask user: "Create commit for [group description]? (y/n/skip)"
        - If yes, prompt for commit message following conventional commits:
          - Format: type(scope): description
          - Types: feat, fix, docs, chore, refactor, test, build, ci
          - Example: feat(commands): add /open-pr command for automated PR creation
        - Stage files and create commit
     4. Repeat until all changes are committed
     5. Allow skip option if user wants to handle manually

     Return: List of commits created with messages
     ```

   - Store commit list for version bump analysis
   - If no commits created, halt with error

7. **Determine Version Bump**:
   - Analyze commits to determine change type:
     - `feat:` or `BREAKING CHANGE:` → check for major vs minor
     - `fix:` → patch
     - `docs:`, `chore:`, `refactor:` → patch (or no bump if documentation-only)
   - Extract milestone version (e.g., "v0.1" → "0.1")
   - Read workflow-config.json pull_requests.versioning.files to find version files
   - Check current version from first file in list:
     - package.json: Read "version" field
     - pyproject.toml: Read version in [project] or [tool.poetry]
     - Cargo.toml: Read version in [package]
     - Shell scripts (*.sh): Read `VERSION="X.Y.Z"` or `readonly VERSION="X.Y.Z"`
   - Propose version bump:
     - If milestone is v0.1 and current is 0.0.x → bump to 0.1.0
     - If milestone is v0.1 and current is 0.1.x → bump patch to 0.1.(x+1)
     - If milestone is v1.0 and current is 0.x.x → bump to 1.0.0
   - Ask user to confirm version bump: "Bump version from X.X.X to Y.Y.Y? (y/n/custom)"
   - If custom, prompt for version number
   - Update version in all files from workflow-config.json:
     - package.json: Run `npm version <version> --no-git-tag-version`
     - pyproject.toml: Use sed/awk to replace version string
     - Cargo.toml: Use sed/awk to replace version string
     - Shell scripts: Use sed to replace `VERSION="X.Y.Z"` with `VERSION="Y.Y.Y"`
   - Stage all modified version files

8. **Update CHANGELOG.md**:
   - Read current CHANGELOG.md
   - Generate changelog entry based on commits:

     ```markdown
     ## [X.Y.Z] - YYYY-MM-DD

     ### Added
     - New features from feat: commits

     ### Fixed
     - Bug fixes from fix: commits

     ### Changed
     - Changes from refactor:, chore: commits

     ### Documentation
     - Documentation updates from docs: commits
     ```

   - Insert new entry at the top of the changelog (after title and before previous entries)
   - Stage CHANGELOG.md

9. **Update README.md**:
   - Read current README.md
   - Find the changelog summary section (or create if not exists)
   - Update with latest 3 changelog entries only
   - Maintain format:

     ```markdown
     ## Recent Changes

     ### [X.Y.Z] - YYYY-MM-DD
     - Summary of changes

     ### [X.Y.Z-1] - YYYY-MM-DD
     - Summary of changes

     ### [X.Y.Z-2] - YYYY-MM-DD
     - Summary of changes
     ```

   - Stage README.md

10. **Delegate Version Commit to devops-engineer**:
    - Invoke `devops-engineer` subagent to create version commit:

      ```text
      Context:
      - Files to commit: package.json, CHANGELOG.md, README.md
      - Version: X.Y.Z

      Tasks:
      1. Stage files: git add package.json CHANGELOG.md README.md
      2. Create commit with message: "chore(release): bump version to X.Y.Z"

      Return: Commit hash and confirmation
      ```

11. **🚨 CRITICAL: Update and Move Issue Documentation 🚨**:

    **⚠️ WARNING: This step is MANDATORY and must NEVER be skipped! ⚠️**

    This step MUST complete successfully before creating the PR. The issue documentation
    must be moved from `in-progress/` to `completed/` as part of the PR workflow.

    **Sub-steps (ALL must complete)**:

    a. **Read and Update Issue README**:
       - Read current issue README: `.github/issues/in-progress/issue-{id}/README.md`
       - Check frontmatter for `estimated_effort` field (may exist if created by `/create-issue`)
       - Prompt user: "How many hours did you spend on issue #X?"
         - If `estimated_effort` exists, show as default: "(estimated: {estimated_effort}h, press Enter to use or type actual)"
         - Otherwise: "(e.g., 4.5)"
       - If multiple developers involved, ask for each developer's actual time
       - Update frontmatter:

         ```yaml
         ---
         issue: {number}
         title: "{title}"
         status: "COMPLETED"
         created: "{original-date}"
         completed: "{today-date}"
         pr: "" # Will be filled after PR creation
         actual_effort: {hours}
         estimated_effort: {original_estimate}
         ---
         ```

    b. **Add Resolution Section**:
       - Add **Resolution** section before the closing:

         ```markdown
         ## Resolution

         **Completed**: {today-date}
         **Pull Request**: #{pr-number} (will be filled after creation)

         ### Changes Made
         {AI-generated summary of changes from commits and diffs}

         ### Implementation Details
         {Key technical decisions and approaches}

         ### Notes
         {Any important decisions, trade-offs, or future considerations}
         ```

    c. **🚨 MOVE THE FOLDER (DO NOT SKIP!) 🚨**:
       - Create completed directory: `mkdir -p .github/issues/completed`
       - **CRITICAL**: Move the ENTIRE issue folder:

         ```bash
         mv .github/issues/in-progress/issue-{id} .github/issues/completed/
         ```

       - Verify the move succeeded:

         ```bash
         ls -la .github/issues/completed/issue-{id}/
         ```

       - If the move fails, HALT and report error

    d. **Stage and Commit the Moved Documentation**:
       - Stage ALL files in the moved folder:

         ```bash
         git add .github/issues/completed/issue-{id}/
         ```

       - If in-progress folder is tracked by git, remove it:

         ```bash
         git add .github/issues/in-progress/
         ```

       - Commit with message: `docs(issue): finalize documentation for issue #{id}`
       - If commit fails due to linting errors:
         - **DO NOT** use --no-verify
         - **DO** fix the linting errors in the files
         - Re-commit after fixing

    e. **Verification**:
       - Confirm the folder exists at: `.github/issues/completed/issue-{id}/`
       - Confirm the commit succeeded
       - Confirm no uncommitted changes remain for issue documentation

    **⚠️ FAILURE HANDLING ⚠️**:
    If this step fails for ANY reason:
    - DO NOT proceed to step 12 (PR creation)
    - HALT the workflow
    - Report the specific failure to the user
    - The issue folder MUST be in `completed/` before creating the PR

12. **Delegate Push and PR Creation to devops-engineer**:
    - Generate PR title from issue title or most significant commit
    - Generate PR body based on commits:

      ```markdown
      ## Summary
      {Brief description of changes based on commits}

      ## Changes
      {Bullet list of key changes}

      ## Testing
      - [ ] Code builds successfully
      - [ ] Changes tested locally
      - [ ] Documentation updated
      - [ ] CHANGELOG.md updated

      ## Related Issues
      Closes #{issue-number}

      ## Version
      Bumps version to X.Y.Z (milestone: v{X.Y})
      ```

    - Determine labels from issue labels (enhancement, bug, documentation) and add version label (patch, minor, major)

    - Invoke `devops-engineer` subagent to push and create PR:

      ```text
      Context:
      - Current branch: {branch-name}
      - PR title: {generated-title}
      - PR body: {generated-body}
      - Labels: {labels-list}
      - Issue number: {issue-id}
      - Workflow config: Read .claude/workflow-config.json for reviewers.strategy

      Tasks:
      1. Push branch with tracking: git push -u origin <branch-name>
      2. Determine reviewers:
         - If --reviewers parameter provided: Use that value (override config)
         - Otherwise, read workflow-config.json pull_requests.reviewers.strategy:
           * "none": Skip reviewer assignment
           * "query": Prompt user to select reviewers (show team list if available)
           * "list": Assign ALL reviewers from pull_requests.reviewers.team array
           * "round-robin": Select next reviewer from pull_requests.reviewers.team array
           * "auto": Skip reviewer assignment (let GitHub auto-assign)
           * If config missing: Default to "none"
      3. Create PR with appropriate reviewer flags:
         - No reviewers: gh pr create --title "{title}" --body "{body}" --assignee @me --label {labels}
         - With reviewers: gh pr create --title "{title}" --body "{body}" --assignee @me --reviewer {reviewer-list} --label {labels}
      4. Capture and return PR number from output

      Return: PR number, PR URL, reviewers assigned (or "none"/"auto")
      ```

    - If push or PR creation fails, display error and halt
    - Store PR number for next step

13. **Delegate PR Number Update to devops-engineer**:
    - Invoke `devops-engineer` subagent to update issue README with PR number:

      ```text
      Context:
      - Issue README path: .github/issues/completed/issue-{id}/README.md
      - PR number: {pr-number}
      - Operation: Update frontmatter and Resolution section with PR number

      Tasks:
      1. Update the issue README frontmatter with PR number
      2. Update the Resolution section with PR number
      3. Stage changes: git add .github/issues/completed/issue-{id}/README.md
      4. Amend previous commit: git commit --amend --no-edit
      5. Force push: git push -f origin <branch-name>

      Return: Confirmation of update and force push
      ```

    - If update fails, display warning but continue (PR is already created)

14. **REMOVED** - Functionality moved to step 13

15. **Confirm Success**:
    - Display summary:

      ```text
      ✓ Pull Request Created Successfully

      Issue: #{issue-number} - {issue-title}
      Branch: {branch-name}
      Version: X.Y.Z → Y.Y.Z
      PR: #{pr-number} - {pr-url}

      Commits created: {count}
      Files changed: {count}
      Reviewer: @{reviewer}

      Next steps:
      1. Wait for review from @{reviewer}
      2. Address any feedback
      3. PR will be merged using squash-merge
      4. Use /cleanup-main after merge to clean up local branches
      ```

## Reviewer Assignment Strategies

The command supports five reviewer assignment strategies (configured in `.claude/workflow-config.json`):

### 1. none (default)

No reviewers assigned automatically. PRs are created without reviewers.

```json
{
  "reviewers": {
    "strategy": "none"
  }
}
```

### 2. query (most flexible)

Prompts you to select reviewers when creating the PR. If a team list is configured, it will be shown as suggestions.

```json
{
  "reviewers": {
    "strategy": "query",
    "team": ["user1", "user2", "github-copilot[bot]"]
  }
}
```

**Interactive prompt:**

```text
Who should review this PR?
1. None (no reviewers)
2. Select from team:
   [ ] user1
   [ ] user2
   [ ] github-copilot[bot]
3. All team members
4. Enter custom (comma-separated)
5. Let GitHub auto-assign

Choice [1-5]: _
```

### 3. list

Assigns **all** team members to every PR. Useful for small teams or always including bots.

```json
{
  "reviewers": {
    "strategy": "list",
    "team": ["user1", "github-copilot[bot]"]
  }
}
```

### 4. round-robin

Rotates through team members, assigning one reviewer per PR.

```json
{
  "reviewers": {
    "strategy": "round-robin",
    "team": ["user1", "user2", "user3"]
  }
}
```

Rotation: user1 → user2 → user3 → user1...

### 5. auto

No reviewers assigned. Lets GitHub's auto-assignment (CODEOWNERS, etc.) handle it.

```json
{
  "reviewers": {
    "strategy": "auto"
  }
}
```

### Override with Parameter

You can always override the strategy with the `--reviewers` parameter:

```bash
# Override any strategy with specific reviewers
/open-pr reviewers="user1,github-copilot[bot]"

# Override to no reviewers
/open-pr reviewers=""
```

## Error Handling

### General Errors

- **No changes to commit**: Display error and suggest checking git status
- **On main branch**: Display error and suggest creating feature branch
- **Push failures**: Display error and suggest checking remote access
- **PR creation failures**: Display error and GitHub CLI output

### Feature Branch Errors

- **No issue number in branch**: Prompt for issue number or create new issue
- **Issue not found**: Display error with issue number
- **No milestone on issue**: Halt and require milestone assignment
- **Milestone mismatch**: Ask user which milestone to use
- **Merge conflicts**: Halt and require manual resolution
- **Version bump conflicts**: Prompt user for correct version

### Time-Tracking Branch Errors

- **No time-tracking changes**: Display error if changes are not in `.time-tracking/` directory
- **Invalid branch format**: Display error if branch name doesn't match `time-tracking/{developer}/{YYYY-MM-DD}`
- **Missing summary.json**: Display error if time-tracking summary file is missing

## Examples

```bash
# Create PR using workflow-config.json reviewer strategy
/open-pr

# Override with specific reviewers
/open-pr reviewers="user1,github-copilot[bot]"

# Create PR with no reviewers (override any strategy)
/open-pr reviewers=""

# Create PR from time-tracking branch
# (Branch format: time-tracking/{developer}/{YYYY-MM-DD})
/open-pr

# Examples by reviewer strategy:

# Strategy: none
# → No reviewers assigned

# Strategy: query
# → Prompts you to select reviewers interactively

# Strategy: list (team: ["user1", "github-copilot[bot]"])
# → Assigns both user1 AND github-copilot[bot] to every PR

# Strategy: round-robin (team: ["user1", "user2"])
# → PR #1 gets user1, PR #2 gets user2, PR #3 gets user1...

# Strategy: auto
# → No reviewers assigned, lets GitHub auto-assign
```

## Notes

- This command enforces the full workflow: atomic commits → versioning → documentation → PR
- Uncommitted changes can be selectively included or stashed (step 1.5)
- Stashed changes are automatically offered for restoration by `/cleanup-main`
- Version bump must align with milestone (e.g., v0.1 milestone → 0.1.x version)
- Issue documentation is moved to completed folder as part of PR creation
- The command integrates with `/track-time` through time estimates in issue README
- Uses conventional commits format for better changelog generation
- Automatically links PR to issue using "Closes #X" syntax
- Reviewer assignment supports 5 strategies: none, query, list, round-robin, auto
- `--reviewers` parameter always overrides workflow-config.json strategy
- "query" strategy is most flexible - prompts at PR creation time
- "list" strategy useful for small teams or always including bots like github-copilot[bot]
- **Integration with `/create-issue`**: If `estimated_effort` exists in frontmatter (from `/create-issue`), uses it as default when prompting for actual time spent
- **Time-Tracking Branch Special Handling**: Branches starting with `time-tracking/` bypass the full feature workflow and use a simplified process:
  - No issue number or milestone required
  - No version bumping or changelog updates
  - Single commit format: `chore(time-tracking): log development time for {date}`
  - Simplified PR with time summary
  - Labels: `time-tracking`, `chore`
  - Does not close any issues (metadata only)

## Related Commands

- `/start-work <issue-id>` - Start work on an issue (creates branch and work directory)
- `/create-issue` - Create a new GitHub issue with proper formatting and optional effort estimate
- `/track-time <duration>` - Log development time (references estimates from issue README)
- `/cleanup-main` - Clean up after PR merge (future command)
