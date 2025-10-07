---
name: cleanup-main
description: Automates cleanup after PR merge including branch deletion, main update, optional branch syncing, stash restoration, and context cleanup
args: {}
---

# Cleanup Main Command

Automates the cleanup process after a PR has been squash-merged, including switching to main, updating with latest changes, deleting merged branches, optionally syncing other local branches, and clearing conversation context to prepare for the next task.

## Instructions

1. **Validate Current State**:
   - Get current branch: `git branch --show-current`
   - Store branch name for context
   - If already on main, note that we're just updating main (no branch deletion needed)

2. **Validate Merge Status** (if not on main):
   - Check if current branch exists on remote: `git ls-remote --heads origin <branch-name>`
   - If branch still exists on remote:
     - Display error: "Branch '<branch-name>' still exists on remote. Please ensure PR is merged and remote branch is deleted before running cleanup."
     - Halt execution
   - If branch does not exist on remote, continue (this is expected after squash-merge)

3. **Delegate to devops-engineer Agent**:
   - Invoke the `devops-engineer` subagent with the following context:

     ```text
     Context:
     - Current branch: <branch-name>
     - Remote status: <checked/validated>
     - Operation: Post-merge cleanup after PR squash-merge

     Tasks to execute:
     1. Switch to main branch (if not already on main)
     2. Pull latest changes from origin/main
     3. Delete the merged local branch (force delete if needed due to squash-merge)
     4. Prune stale remote references
     5. Optionally run garbage collection if beneficial
     6. Optionally sync other local branches with latest main

     Expected workflow:
     - For branch deletion: If git reports "not fully merged" error, ask user to confirm force delete (this is safe for squash-merged branches)
     - For garbage collection: Check repo size and ask user if they want to run git gc --auto
     - For branch syncing: Ask user if they want to sync other branches, offer merge/rebase options, handle conflicts gracefully

     Return: Summary of operations performed (switched branch, deleted branch, pruned refs, gc status, synced branches)
     ```

   - The devops-engineer agent will handle:
     - Git checkout and pull operations
     - Branch deletion (including force delete for squash-merged branches)
     - Remote pruning and garbage collection
     - Optional branch syncing with conflict handling

   - If agent invocation fails:
     - Display error: "Failed to delegate to devops-engineer agent. Please run cleanup manually."
     - Exit command

4. **Confirm Success**:
   - Display summary received from devops-engineer agent:

     ```text
     ✓ Cleanup Completed Successfully

     Main branch: Updated to latest
     Deleted branch: <branch-name> (if applicable)
     Pruned remote refs: <count> branches
     Garbage collection: <run/skipped>
     Synced branches: <list or none>

     Your local repository is clean and up to date!

     Next steps:
     1. Use /start-work <issue-id> to begin new work
     2. Continue work on existing branches if any remain
     ```

4.5. **Restore Stashed Changes** (if any stashes from /open-pr exist):

- Check for stashes created by `/open-pr`:

     ```bash
     git stash list | grep -E "open-pr-(excluded|all-excluded)-"
     ```

- If no stashes found, skip this step and proceed to completion

- If stashes found, display interactive menu:

     ```text
     Found stashed changes from previous /open-pr runs:

     stash@{0}: On milestone-v0.1/task/33: open-pr-excluded-20251006-143022
        ?? .github/issues/completed/issue-33/analysis/

     stash@{2}: On milestone-v0.1/task/30: open-pr-all-excluded-20251005-120045
        M  install.sh
        M  lib/installer-common/validation.sh

     What would you like to do?
     1. Apply most recent stash (stash@{0})
     2. Apply specific stash (choose from list)
     3. Apply all stashes (may cause conflicts)
     4. Keep stashes for later
     5. Delete stashes (permanent)

     Choice [1-5]: _
     ```

- **Option 1: Apply Most Recent**:

  - Apply the most recent stash:

       ```bash
       git stash pop stash@{0}
       ```

  - If successful:

       ```text
       ✓ Applied stash@{0} successfully

       Files restored:
         ?? .github/issues/completed/issue-33/analysis/

       Your work-in-progress changes have been restored.
       ```

  - If conflicts occur:

       ```text
       ⚠ Conflicts detected while applying stash:
         CONFLICT (content): Merge conflict in install.sh

       Please resolve conflicts manually:
         1. Edit conflicted files
         2. Stage resolved files: git add <file>
         3. The stash has been kept (not dropped)
         4. Drop stash when done: git stash drop stash@{0}

       Aborting stash apply to avoid losing work.
       ```

    - Run: `git reset --merge` to abort the stash apply
    - Keep the stash for manual application later

- **Option 2: Apply Specific Stash**:

  - Display numbered list of all stashes with `open-pr` prefix:

       ```text
       Select stash to apply:
       1. stash@{0}: open-pr-excluded-20251006-143022 (1 file)
       2. stash@{2}: open-pr-all-excluded-20251005-120045 (2 files)
       3. Cancel

       Choice [1-3]: _
       ```

  - Apply selected stash with same conflict handling as Option 1
  - If successful, offer to apply more stashes:

       ```text
       ✓ Applied stash successfully

       Apply another stash? (y/n): _
       ```

- **Option 3: Apply All Stashes**:

  - Warn about potential conflicts:

       ```text
       ⚠ Warning: Applying multiple stashes may cause conflicts.

       Found 2 stashes to apply. Continue? (y/n): _
       ```

  - If yes, apply stashes in chronological order (oldest first):

       ```bash
       # Get list of stash indices in reverse order
       stash_list=$(git stash list | grep -E "open-pr-(excluded|all-excluded)-" | awk -F: '{print $1}' | tac)

       for stash in $stash_list; do
         git stash pop "$stash"
         if [ $? -ne 0 ]; then
           # Conflict occurred, abort and keep stash
           git reset --merge
           echo "Conflict in $stash, skipping..."
           continue
         fi
       done
       ```

  - Display summary:

       ```text
       ✓ Stash Application Summary

       Successfully applied: 1 stash
       Skipped due to conflicts: 1 stash
       Remaining stashes: 1

       Remaining:
         stash@{0}: open-pr-all-excluded-20251005-120045 (conflicts)

       You can apply remaining stashes manually with:
         git stash pop stash@{0}
       ```

- **Option 4: Keep for Later**:

  - Display confirmation:

       ```text
       Stashes kept for later use.

       You can apply them manually at any time:
         git stash list                    # View all stashes
         git stash show stash@{N}          # Preview stash
         git stash pop stash@{N}           # Apply and remove
         git stash apply stash@{N}         # Apply and keep
       ```

  - Continue to completion

- **Option 5: Delete Stashes**:

  - Show checkboxes for each stash:

       ```text
       Select stashes to delete (space to toggle, enter to confirm):
       [x] stash@{0}: open-pr-excluded-20251006-143022
       [ ] stash@{2}: open-pr-all-excluded-20251005-120045

       Selected: 1 stash
       ```

  - Confirm deletion:

       ```text
       ⚠ WARNING: This will permanently delete selected stashes!

       Delete 1 stash? (y/n): _
       ```

  - If yes, delete selected stashes:

       ```bash
       git stash drop stash@{0}
       ```

  - Display confirmation:

       ```text
       ✓ Deleted 1 stash

       Remaining stashes: 1
       ```

- **Error Handling**:

  - If `git stash pop` fails:
    - Abort the apply: `git reset --merge`
    - Keep the stash (don't drop)
    - Show conflict message
    - Ask if user wants to continue with other stashes
  - If `git stash drop` fails:
    - Display error
    - Show stash list
    - Suggest manual deletion

- After this step completes, proceed to context cleanup step

5. **Clear Context** (if enabled in workflow-config.json):

- Read workflow configuration:

     ```bash
     cat ${PROJECT_ROOT}/.claude/workflow-config.json
     ```

- Check if `workflow.cleanup.clear_context_after` is `true`
- If disabled or config not found, skip this step

- If enabled, check `workflow.cleanup.compact_instead_of_clear`:
  - If `true`: Run `/compact` command to compress context
  - If `false` (default): Run `/clear` command to clear conversation history

- **Option: Clear Context** (default):

     ```text
     Running /clear to clean up conversation context...

     This will clear the conversation history while preserving your code changes.
     ```

  - Execute: `/clear`
  - Note: This removes conversation history but keeps all file changes

- **Option: Compact Context**:

     ```text
     Running /compact to compress conversation context...

     This will compress the conversation history to save context tokens.
     ```

  - Execute: `/compact`
  - Note: This compresses context instead of clearing completely

- If context cleanup succeeds:

     ```text
     ✓ Context cleaned up successfully

     Your conversation context has been refreshed for the next task.
     ```

- If context cleanup fails:

     ```text
     ⚠ Could not clear context automatically

     You can manually run /clear or /compact if desired.
     ```

  - Continue to completion (non-fatal error)

## Error Handling

- **Branch still on remote**: Display error with instructions to complete PR merge
- **Cannot checkout main**: Display error and suggest checking repository state
- **Pull fails**: Display error (conflicts, network) and suggest manual resolution
- **Branch deletion fails**: Offer force delete for squash-merged branches
- **Merge/rebase conflicts**: Abort operation, inform user, continue to next branch
- **Git command errors**: Display error message and command that failed

## Examples

```bash
# After PR is merged and remote branch deleted
/cleanup-main

# The command will:
# 1. Switch to main and pull latest changes
# 2. Delete the merged feature branch
# 3. Clean up stale remote references
# 4. Optionally sync other local branches
```

## Notes

- This command is designed to run after a PR has been squash-merged
- Remote branch should already be deleted (GitHub does this automatically)
- Squash-merged branches may require force deletion (this is safe)
- Branch syncing is optional and interactive
- Handles merge conflicts gracefully by aborting and continuing
- **Stash Restoration**: Automatically detects and offers to restore changes stashed by `/open-pr`
- Stashed changes can be applied selectively or all at once
- Conflict detection prevents data loss when applying stashes
- **Context Cleanup**: Optionally runs `/clear` or `/compact` to clean up conversation context (configurable in workflow-config.json)
- Context cleanup helps maintain a fresh conversation for the next task
- Part of comprehensive workflow automation suite

## Related Commands

- `/start-work <issue-id>` - Start work on a new issue after cleanup
- `/open-pr` - Create pull request (run before cleanup)
- `/track-time <duration>` - Log development time

## Integration Notes

- Complements the squash-merge workflow used in `/open-pr`
- Works with branch protection and GitHub PR workflows
- Helps maintain clean local repository state
- Prepares environment for next development task
