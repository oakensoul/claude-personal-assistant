---
name: publish-issue
description: Publishes local issue drafts to GitHub and moves them to published/ for historical reference
args:
  slugs:
    description: "One or more slugs to publish, or --milestone X.Y, or --all"
    required: false
version: 1.0.0
category: workflow
---

# Publish Issue Command

Publishes local issue drafts to GitHub. Reads draft metadata, creates GitHub issues, and moves local drafts to `.github/issues/published/` on success.

## Usage

```bash
# Publish single draft by slug
/publish-issue add-dark-mode

# Publish multiple drafts
/publish-issue add-dark-mode refactor-auth fix-login-bug

# Publish all drafts in a milestone
/publish-issue --milestone 0.1.0

# Publish all drafts
/publish-issue --all
```

## Instructions

### 1. Parse Arguments

- Check for flags:
  - `--milestone X.Y`: Publish all drafts in specified milestone
  - `--all`: Publish all drafts in all milestones
- If no flags:
  - Treat all arguments as slugs
  - If no arguments provided: Display error and usage

### 2. Find Draft Folders

**For slug-based publishing**:

- For each slug provided:
  - Search in `.github/issues/drafts/**/{type}-{slug}/`
  - Use find or glob to locate matching folders
  - If not found: Display warning "Draft '{slug}' not found", continue with others
  - If found: Add to publish list

**For milestone-based publishing** (`--milestone X.Y`):

- Scan `.github/issues/drafts/milestone-vX.Y/*/`
- Find all draft folders in that milestone
- Add all to publish list
- If no drafts found: Display error "No drafts found for milestone X.Y", exit

**For all drafts** (`--all`):

- Scan `.github/issues/drafts/*/*/`
- Find all draft folders recursively
- Add all to publish list
- If no drafts found: Display error "No drafts found", exit

### 3. Read Draft Metadata

For each draft folder found:

- Read `README.md` frontmatter
- Extract metadata:
  - `slug`
  - `title`
  - `type`
  - `milestone`
  - `labels` (comma-separated)
  - `assignee` (optional)
  - `estimated_effort` (optional)
- Read body content (everything after frontmatter)
- Store draft info for processing

### 4. Display Publishing Plan

Show what will be published:

```text
========================================
PUBLISH PLAN
========================================

Found {count} draft(s) to publish:

1. {title}
   Slug: {slug}
   Type: {type}
   Milestone: {milestone}
   Labels: {labels}

2. {title}
   ...

========================================
```

- Prompt: "Publish these {count} issue(s) to GitHub? (y/n)"
- If no: Exit without publishing
- If yes: Continue

### 5. Validate Prerequisites

For each draft:

- **Check milestone exists on GitHub**:

  - Run: `gh api repos/:owner/:repo/milestones --jq '.[] | select(.title=="{milestone}") | .number'`
  - If not found: Display error "Milestone '{milestone}' not found on GitHub. Create it first.", skip this draft
- **Check labels exist** (optional validation):

  - Can fetch existing labels: `gh label list --json name`
  - If label doesn't exist, it will be created or warning shown
- **Validate assignee** (if provided):

  - Run: `gh api users/{assignee}` to check user exists
  - If not found: Display warning "User @{assignee} not found, skipping assignee", continue

### 6. Publish Each Draft

For each draft in list:

1. **Build GitHub issue body**

    - Use body from README.md (content after frontmatter)
    - Optionally enhance with metadata section at bottom:

    ```markdown
    ---
    **Type**: {type}
    **Estimated Effort**: {effort} hours
    **Draft Slug**: {slug}
    ```

2. **Create GitHub issue**

    - Build `gh issue create` command:

    ```bash
    gh issue create \
      --title "{title}" \
      --body "{body}" \
      --milestone "{milestone}" \
      --label "{label1,label2,label3}" \
      {--assignee "{assignee}" if provided}
    ```

    - Execute command and capture output
    - Parse issue number from output (format: "<https://github.com/.../issues/{number}>")

3. **Handle creation result**

    **On success**:

    - Display: `✓ Published: {title} → Issue #{number}`
    - Store issue number and URL
    - Move draft to published folder:

      ```bash
      # Create published directory structure
      mkdir -p .github/issues/published/{milestone}/

      # Move draft folder
      mv {draft-folder} .github/issues/published/{milestone}/{type}-{slug}/

      # Update README.md status and add GitHub URL
      sed -i '' 's/status: DRAFT/status: PUBLISHED/' .github/issues/published/{milestone}/{type}-{slug}/README.md
      echo -e "\n---\n\n**GitHub Issue**: {issue-url}" >> .github/issues/published/{milestone}/{type}-{slug}/README.md
      ```

    - Verify move successful
    - Display: `Moved draft to: .github/issues/published/{milestone}/{type}-{slug}/`

    **On failure**:

    - Display: `✗ Failed to publish: {title}`
    - Show error message from `gh issue create`
    - DO NOT delete or move draft folder (preserve for retry)
    - Continue with next draft

### 7. Display Summary

After all publishing attempts:

```text
========================================
PUBLISH SUMMARY
========================================

Successfully Published ({success-count}):
✓ Issue #42: Add Dark Mode Support
  https://github.com/owner/repo/issues/42

✓ Issue #43: Refactor Authentication
  https://github.com/owner/repo/issues/43

{If failures exist:}
Failed ({failure-count}):
✗ {title} - {error-reason}
  Draft preserved at: {path}
{endif}

========================================

Next Steps:
1. Start work on an issue:
   /start-work <issue-number>

2. View issues on GitHub:
   gh issue list --milestone "{milestone}"
```

## Examples

### Publish Single Draft

```bash
/publish-issue add-dark-mode

# Output:
# ✓ Published: Add Dark Mode Support → Issue #42
# Moved draft to: .github/issues/published/milestone-v0.1/feature-add-dark-mode/
```

### Publish Multiple Drafts

```bash
/publish-issue add-dark-mode refactor-auth fix-login-bug

# Publishes all three drafts in one command
```

### Publish by Milestone

```bash
/publish-issue --milestone 0.1.0

# Finds all drafts in .github/issues/drafts/milestone-v0.1/
# Publishes all of them
```

### Publish Everything

```bash
/publish-issue --all

# Publishes every draft in drafts/
# Useful for batch operations
```

## Error Handling

- **No drafts found**: Display helpful error with suggestion to use `/create-issue`
- **Milestone not found on GitHub**: Skip draft with error, suggest creating milestone first
- **Assignee not found**: Warn and continue without assignee
- **GitHub CLI error**: Display error message, preserve draft for retry
- **Network error**: Display error, preserve all unpublished drafts
- **Permission error**: Display error about GitHub token permissions
- **Partial failure**: Display which succeeded and which failed, preserve failed drafts

## Directory Structure

**Before publishing**:

```text
.github/issues/drafts/milestone-v0.1/
├── feature-add-dark-mode/
│   └── README.md (status: DRAFT)
└── bug-fix-login/
    └── README.md (status: DRAFT)
```

**After publishing**:

```text
.github/issues/published/milestone-v0.1/
├── feature-add-dark-mode/
│   └── README.md (status: PUBLISHED, includes GitHub URL)
└── bug-fix-login/
    └── README.md (status: PUBLISHED, includes GitHub URL)
```

**Git tracking**:

- `.github/issues/drafts/` - Gitignored (local only)
- `.github/issues/published/` - Committed to repo (shared history)

## Notes

- **Drafts moved on success**: Once published, local draft is moved to `.github/issues/published/` for historical reference
- **Status updated**: README.md status changes from "DRAFT" to "PUBLISHED" with GitHub issue URL appended
- **Failures preserved**: If publish fails, draft remains in `drafts/` for retry
- **Idempotent-ish**: Re-running publishes only remaining drafts
- **Atomic per-draft**: Each draft publishes independently
- **Batch operations**: Use `--milestone` or `--all` for efficiency
- **Validation before publish**: Checks milestone exists before attempting
- **Safe to retry**: Failed publishes can be retried without duplicates
- **Preserves history**: Both GitHub issues and local published drafts maintain permanent record
- **Team visibility**: Published folder should be committed so team can see what was created

## Related Commands

- `/create-issue` - Create local draft (prerequisite for this command)
- `/start-work <issue-id>` - Start work on published issue
- `/workflow-init` - Configure workflow (creates gitignore for drafts/)

## Integration Notes

- **Requires GitHub connection**: Cannot publish without network
- **Milestone must exist**: Create milestone on GitHub before publishing
- **Labels auto-created**: Non-existent labels may be created automatically
- **Gitignore integration**: Drafts folder should be in .gitignore
- **Team workflow**: Each developer publishes their own drafts independently
