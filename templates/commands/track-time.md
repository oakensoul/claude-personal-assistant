---
name: track-time
description: Log development time with automatic activity detection from git commits and GitHub issues
args:
  duration:
    description: Time spent (e.g., "2.5h", "1.5", "90m")
    required: false
  date:
    description: Date for time entry (defaults to today, accepts "yesterday" or YYYY-MM-DD)
    required: false
  issue:
    description: Specific issue number to attribute all time to
    required: false
  interactive:
    description: Use interactive mode to manually allocate time across issues
    required: false
---

# Track Time Command

Log development time with automatic context detection from git commits and GitHub issues. Automatically creates and checks out a time-tracking branch for the session.

## Instructions

1. **Check for duration argument**:
   - If no duration is provided, display help message and exit
   - Help message should include:

     ```text
     # Time Tracking

     Track development time with automatic activity detection from git commits and GitHub issues.
     Automatically creates/checks out time-tracking branch: time-tracking/{developer}/{date}

     ## Usage

     /track-time <duration> [options]

     ## Arguments

     duration    Time spent (required)
                 Formats: "2.5h", "2.5", "90m", "1h30m"

     ## Options

     --date <value>        Date for time entry
                          Values: "yesterday", "YYYY-MM-DD"
                          Default: today

     --issue <number>      Attribute all time to specific issue
                          Example: --issue 34

     --interactive         Manually allocate time across issues

     ## Examples

     # Log 2.5 hours for today
     /track-time 2.5h

     # Log 3 hours for yesterday
     /track-time 3h --date yesterday

     # Log time for specific date
     /track-time 2h --date 2025-10-01

     # Attribute to specific issue
     /track-time 1.5h --issue 34

     # Interactive allocation
     /track-time 3h --interactive

     ## What Gets Tracked

     - Duration: Total hours worked
     - Issues: GitHub issue numbers from commits
     - Commits: Related commit hashes and messages
     - Breakdown: Time allocated per issue
     - Branch: Automatic time-tracking branch creation

     Time entries stored in: .time-tracking/YYYY-MM.md
     Summary statistics in: .time-tracking/summary.json

     ## Documentation

     Full guide: docs/contributing/time-tracking.md
     ```

2. **Parse the duration argument**:
   - Support formats: "2.5h", "2.5", "90m", "1h30m"
   - Convert to decimal hours for storage

3. **Determine the date**:
   - Default to today's date
   - If `--date yesterday`, use yesterday's date
   - If `--date YYYY-MM-DD`, use that specific date
   - Format: YYYY-MM-DD

4. **Get the current developer**:
   - Run `git config user.name` to get developer name
   - Run `git config user.email` for additional context

5. **Create/checkout time-tracking branch**:
   - Format branch name: `time-tracking/{developer}/{date}`
     - {developer}: git user.name lowercased, spaces replaced with hyphens
     - {date}: YYYY-MM-DD format from step 3
     - Example: `time-tracking/john-smith/2025-10-03`
   - Check if branch exists: `git rev-parse --verify time-tracking/{developer}/{date} 2>/dev/null`
   - If branch exists:
     - Checkout existing branch: `git checkout time-tracking/{developer}/{date}`
     - If checkout fails, warn user but continue: "Warning: Could not checkout existing time-tracking branch, continuing on current branch"
   - If branch doesn't exist:
     - Create new branch from current location: `git checkout -b time-tracking/{developer}/{date}`
     - If creation fails, warn user but continue: "Warning: Could not create time-tracking branch, continuing on current branch"
   - Display success message: "Switched to time-tracking branch: time-tracking/{developer}/{date}" or "Continuing on current branch: {current-branch}"

6. **Analyze git activity for the date**:
   - Run `git log --since="YYYY-MM-DD 00:00" --until="YYYY-MM-DD 23:59" --author="<email>" --pretty=format:"%H::%s"`
   - Parse commit hashes and messages (split on `::`)
   - Extract issue numbers from commit messages (e.g., #34, #30)

7. **Fetch GitHub issue details**:
   - For each unique issue number found in commits, run `gh issue view <number> --json number,title`
   - Collect issue titles for better context

8. **Check for issue activity**:
   - Run `gh issue list --assignee @me --state all --search "updated:>YYYY-MM-DD" --json number,title,updatedAt`
   - Cross-reference with commit-based issues
   - **Check for issue estimates**: For each issue, look for `.github/issues/completed/issue-{id}/README.md` and extract time estimates from frontmatter if available

9. **Determine time allocation**:
   - If `--issue <number>` provided: attribute all time to that issue
   - If `--interactive` flag: prompt user to allocate time across issues
   - Otherwise: auto-allocate based on commit count per issue

10. **Format the time entry**:

   ```markdown
   ## YYYY-MM-DD - Developer Name

   **Duration**: X.X hours
   **Session**: Auto-detected or "Manual entry"

   ### Work Completed
   - Issues: #X, #Y, #Z
   - Commits:
     - hash: commit message
     - hash: commit message

   ### Breakdown
   - #X (Issue Title): X.Xh (Estimated: X.Xh) *if estimate available*
   - #Y (Issue Title): X.Xh (Estimated: X.Xh) *if estimate available*
   - General development: X.Xh
   ```

   **Note**: If issue estimates are found in `.github/issues/completed/issue-{id}/README.md`, display them alongside actual time for comparison

11. **Write to monthly log file**:

- File: `.time-tracking/YYYY-MM.md`
- If file doesn't exist, create it with frontmatter:

     ```markdown
     ---
     title: "Time Tracking - Month YYYY-MM"
     type: "time-tracking"
     month: "YYYY-MM"
     ---

     # Time Tracking - Month YYYY-MM

     ```

- Append the time entry to the file
- Add a blank line separator between entries

12. **Update summary.json**:
    - File: `.time-tracking/summary.json`
    - Structure:

      ```json
      {
        "developers": {
          "Developer Name": {
            "totalHours": 0,
            "issues": {
              "34": {
                "title": "Issue title",
                "hours": 0,
                "estimated": 0,
                "entries": 0
              }
            },
            "months": {
              "2025-10": {
                "hours": 0,
                "entries": 0
              }
            }
          }
        },
        "issues": {
          "34": {
            "title": "Issue title",
            "totalHours": 0,
            "estimated": 0,
            "developers": {
              "Developer Name": 0
            }
          }
        },
        "lastUpdated": "YYYY-MM-DD HH:MM:SS"
      }
      ```

    - Update totals appropriately
    - Include `estimated` field when estimate data is available from issue README
    - If file doesn't exist, create initial structure

13. **Confirm success**:
    - Display summary: "Logged X.X hours for YYYY-MM-DD"
    - Show breakdown by issue
    - Provide path to updated files

## Examples

```bash
# Log 2.5 hours for today
/track-time 2.5h

# Log 3 hours for yesterday
/track-time 3h --date yesterday

# Log 1.5 hours for a specific date
/track-time 1.5h --date 2025-10-01

# Attribute all time to a specific issue
/track-time 2h --issue 34

# Interactive time allocation
/track-time 3h --interactive
```text

## Error Handling

- Invalid duration format: Show error and examples
- Invalid date format: Show error and expected format
- No git activity found: Warn user and ask if they want to continue with manual entry
- Git or GitHub CLI not available: Show error and required tools
- Branch creation/checkout fails: Warn user but continue with time tracking on current branch (non-blocking error)

## Notes

- All times are stored in decimal hours (e.g., 1.5 for 1 hour 30 minutes)
- Time entries are immutable once written (edit the markdown file manually if corrections needed)
- The command automatically detects context but allows manual override
- Summary data is regenerated from log files if corrupted or deleted
- **Integration with `/open-pr`**: Time estimates captured during PR creation are stored in issue README frontmatter and used for estimate vs. actual comparison
- Estimate tracking helps improve future estimation accuracy over time
- **Automatic branching**: Creates/checks out `time-tracking/{developer}/{date}` branch for isolating time tracking commits
- Branch creation is non-blocking - if it fails, time tracking continues on the current branch
- Multiple time entries for the same date will use the same time-tracking branch
