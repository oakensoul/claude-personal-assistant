---
name: create-issue
description: Creates local issue draft with standardized formatting for later publishing to GitHub
args: {}
---

# Create Issue Command

Creates a local issue draft with standardized formatting, type determination, milestone assignment, and effort estimation. Drafts are stored locally for refinement before publishing to GitHub via `/publish-issue`.

## Instructions

1. **Display Welcome Message**:
    - Show command purpose: Creating a local issue draft
    - Explain: Draft will be saved in `.github/issues/drafts/` (gitignored)
    - Inform: Use `/publish-issue` to publish draft to GitHub
    - Note: Milestone is required for organization

2. **Gather Issue Title**:
    - Prompt: "Enter issue title:"
    - Validate title is not empty
    - Suggest improvements if title is too vague or unclear
    - Confirm or allow user to refine

3. **Gather Issue Description**:
    - Prompt: "Enter issue description/body (press Ctrl+D when finished):"
    - Allow multi-line input
    - Validate description is not empty
    - Suggest adding more detail if too brief

4. **Delegate to devops-engineer for Type Analysis**:
    - Invoke `devops-engineer` subagent to analyze issue type:

    ```text
    Context:
    - Issue title: {title}
    - Issue description: {description}
    - Operation: Determine issue type and check if domain consultation needed

    Tasks:
    1. Analyze title and description to determine likely type:
       - Types: feature, enhancement, bug, defect, chore, task, documentation
       - Detection heuristics:
         - Keywords like "implement", "add", "create" → feature/enhancement
         - Keywords like "fix", "broken", "error", "bug" → bug/defect
         - Keywords like "update", "upgrade", "refactor" → chore
         - Keywords like "document", "docs", "readme" → documentation
    2. Display suggested type with reasoning
    3. Check if issue involves specific domains that would benefit from consultation:
       - Documentation-focused: Suggest consulting technical-writer agent
       - Agent/command creation: Suggest consulting claude-agent-manager agent
       - Product/business requirements: Suggest consulting domain expert if available
    4. If consultation recommended, ask user: "This seems to be about [domain]. Should I consult the [agent-name] agent for additional context? (y/n)"
    5. If yes, invoke suggested agent for input, then continue
    6. Prompt: "Suggested type: {type} (because: {reason}). Accept or choose different? [accept/feature/bug/chore/task/documentation]"
    7. Allow user to override suggestion

    Return: Selected type, consultation results (if any)
    ```

    - Store selected type for labeling
    - Store any consultation insights for issue body

5. **Gather Milestone**:
    - Try to fetch from GitHub (optional): `gh api repos/:owner/:repo/milestones --jq '.[] | {number, title}' 2>/dev/null`
    - If GitHub available and milestones exist:
        - Display milestones in numbered list:

        ```text
        Available Milestones:
        1. 0.1.0 - Foundation
        2. 0.2.0 - Enhancement
        ```

        - Prompt: "Select milestone number (or enter custom milestone like '0.1.0'):"
    - If GitHub unavailable or no milestones:
        - Prompt: "Enter milestone (e.g., 0.1.0, 0.2.0):"
    - Validate format (semantic version preferred: X.Y.Z or X.Y)
    - Store milestone value (e.g., "0.1.0")
    - Note: Milestone must be created on GitHub before `/publish-issue` succeeds

6. **Gather Estimated Effort** (Optional):
    - Prompt: "Estimated effort for this issue in hours? (optional, e.g., 4.5, or press Enter to skip):"
    - If provided, validate it's a positive number
    - Store effort value (or null if skipped)
    - This will be included in issue body in parseable format

7. **Determine Suggested Labels** (for later publishing):
    - Start with type-based label: `type:{type}`
    - Analyze description for technology keywords:
        - "javascript", "js", "node" → `javascript`
        - "typescript", "ts" → `typescript`
        - "bash", "shell" → `shell`
        - "react", "nextjs" → `react`
        - "api", "rest", "graphql" → `api`
        - "database", "sql", "mysql" → `database`
    - Detect priority keywords:
        - "urgent", "critical", "blocker" → `priority:high`
        - "nice to have", "future", "optional" → `priority:low`
    - Detect complexity keywords:
        - "simple", "trivial", "quick" → `complexity:S`
        - "complex", "large", "significant" → `complexity:L`
    - Store suggested labels in metadata (will be applied during `/publish-issue`)

8. **Optional: Ask About Assignee**:
    - Prompt: "Assignee for this issue? (leave empty for unassigned, or enter GitHub username):"
    - If empty: Leave unassigned (will be set during `/publish-issue`)
    - If username provided: Store in metadata
    - Note: Assignee will be validated when publishing

9. **Generate Slug from Title**:
    - Convert title to slug:
        - Convert to lowercase
        - Replace spaces with hyphens
        - Remove special characters (keep only alphanumeric and hyphens)
        - Remove consecutive hyphens
        - Trim hyphens from start/end
        - Example: "Add Dark Mode Support" → "add-dark-mode-support"
    - Store slug for folder naming

10. **Create Draft Folder**:
    - Build folder path: `.github/issues/drafts/milestone-v{milestone}/{type}-{slug}/`
    - Create directory if it doesn't exist
    - If folder already exists:
        - Display: "Draft already exists at {path}"
        - Prompt: "Overwrite existing draft? (y/n)"
        - If no: Exit command
        - If yes: Proceed

11. **Build Issue README with Metadata**:
    - Create README.md in draft folder with frontmatter and body:

    ```markdown
    ---
    slug: "{slug}"
    title: "{title}"
    type: "{type}"
    status: "DRAFT"
    milestone: "{milestone}"
    created: "{current-date}"
    estimated_effort: {effort or null}
    labels: "{comma-separated labels}"
    assignee: "{assignee or empty}"
    ---

    # {title}

    **Status**: DRAFT (not yet published to GitHub)
    **Type**: {type}
    **Milestone**: {milestone}
    **Labels**: {labels}
    {If assignee:}**Assignee**: @{assignee}{endif}
    {If effort:}**Estimated Effort**: {effort} hours{endif}

    ## Description

    {User-provided description}

    ## Requirements

    {Placeholder or extracted from description}

    ## Technical Details

    {Placeholder for technical notes}

    ## Success Criteria

    - [ ] {Suggested criterion 1}
    - [ ] {Suggested criterion 2}

    ## Related Issues

    {Placeholder}

    ## Notes

    This is a draft issue. Use `/publish-issue {slug}` to publish to GitHub.
    ```

    - Write README.md to draft folder

12. **Display Preview**:
    - Show draft preview:

    ```text
    ========================================
    DRAFT ISSUE PREVIEW
    ========================================

    Title: {title}
    Type: {type}
    Milestone: {milestone}
    Labels: {labels}
    Assignee: {assignee or "Unassigned"}
    Estimated Effort: {effort or "Not specified"}

    Draft Location:
    .github/issues/drafts/milestone-v{milestone}/{type}-{slug}/

    ========================================
    ```

    - Prompt: "Create this draft? (y/n)"
    - If n: Cancel and exit
    - If y: Proceed to creation

13. **Save Draft**:
    - Write README.md to draft folder
    - Confirm file was created successfully

14. **Display Success Message**:
    - Show summary:

    ```text
    ✓ Draft Issue Created Successfully!

    Draft: {title}
    Location: .github/issues/drafts/milestone-v{milestone}/{type}-{slug}/
    Slug: {slug}
    Milestone: {milestone}
    Labels: {labels}
    {If assignee:}Assignee: @{assignee}{endif}
    {If effort:}Estimated Effort: {effort} hours{endif}

    Next steps:
    1. Refine the draft by editing:
       .github/issues/drafts/milestone-v{milestone}/{type}-{slug}/README.md

    2. When ready, publish to GitHub:
       /publish-issue {slug}
       or
       /publish-issue --milestone {milestone}
       or
       /publish-issue --all

    3. After publishing, start work with:
       /start-work <github-issue-number>

    Note: Draft is gitignored - it exists only on your local machine.
    ```

## Examples

```bash
# Create a new draft issue interactively
/create-issue

# The command will guide you through:
# 1. Entering title and description
# 2. Selecting type (feature/bug/chore/etc.)
# 3. Choosing milestone (required)
# 4. Estimating effort (optional)
# 5. Configuring labels and assignee (optional)
# 6. Previewing and confirming

# Result: Creates draft in .github/issues/drafts/milestone-v0.1/feature-add-dark-mode/

# Refine the draft
vim .github/issues/drafts/milestone-v0.1/feature-add-dark-mode/README.md

# Publish when ready
/publish-issue add-dark-mode

# Or publish all drafts for a milestone
/publish-issue --milestone 0.1.0
```

## Error Handling

- **Empty title**: Prompt again with validation message
- **Empty description**: Prompt again with validation message
- **Invalid milestone format**: Show error and prompt again
- **Invalid effort value**: Show error and prompt again (or allow skip)
- **Draft folder already exists**: Prompt to overwrite or cancel
- **Cannot create directory**: Display filesystem error and suggest checking permissions
- **Cannot write README**: Display error and suggest checking disk space/permissions
- **Invalid slug characters**: Sanitize automatically and show result

## Notes

- **Drafts are local only**: Saved in `.github/issues/drafts/` which is gitignored
- **Slug-based folders**: No issue numbers until published to GitHub
- **Milestone required**: Organizes drafts and ensures proper versioning
- **Estimated effort optional**: Recommended for project planning
- **Labels auto-suggested**: Based on type, description, and keywords
- **Assignee optional**: Can be set now or during publish
- **Drafts are mutable**: Edit README.md anytime before publishing
- **Safe to experiment**: Create drafts, refine them, delete unwanted ones
- **Publish when ready**: Use `/publish-issue` to push to GitHub
- **No GitHub dependency**: Create drafts offline, publish when connected

## Related Commands

- `/publish-issue <slug>` - Publish draft to GitHub (creates issue, deletes draft)
- `/start-work <github-id>` - Start work on published issue (creates branch and work directory)
- `/open-pr` - Create pull request for issue
- `/track-time <duration>` - Log development time
- `/cleanup-main` - Clean up after PR merge

## Integration Notes

- **Drafts workflow**: create-issue → refine locally → publish-issue → start-work
- **Gitignored**: Drafts never committed, safe for experimentation
- **Offline capable**: Create drafts without GitHub connection
- **Team-friendly**: Each developer has their own local drafts
- **Publish validation**: Labels, assignee, and milestone validated when publishing
