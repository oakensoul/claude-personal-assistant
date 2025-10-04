# Issue Documentation

This directory contains documentation for GitHub issues.

## Structure

- `in-progress/` - Active work on issues
- `completed/` - Completed issues with resolution details

## Workflow

1. Run `/start-work <issue-id>` to begin work
   - Creates: `in-progress/issue-<id>/README.md`
   - Contains issue details and requirements

2. Work on the issue and update notes

3. Run `/open-pr` when ready to create PR
   - Moves to: `completed/issue-<id>/README.md`
   - Adds resolution details and PR link

## Notes

- In-progress issues are in .gitignore (not committed)
- Completed issues are committed with PRs
- Each issue has its own directory for related files