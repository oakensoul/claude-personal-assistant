---
issue: 39
title: "Add workflow commands to templates folder for user customization"
status: "COMPLETED"
created: "2025-10-07"
completed: "2025-10-07"
pr: ""
actual_effort: 1
estimated_effort: 1
---

# Issue #39: Add workflow commands to templates folder for user customization

**Status**: OPEN
**Labels**:
**Milestone**: 0.1.0 - Foundation
**Assignees**: oakensoul

## Description

# Add workflow commands to templates folder for user customization

**Type**: chore
**Milestone**: 0.1.0
**Estimated Effort**: 1 hour

## Description

Move workflow-based slash commands from .claude/commands/ to templates/ directory so they can be easily customized by users during installation.

Commands to template:

- cleanup-main - Post-merge cleanup automation
- implement - Task implementation with auto-commit
- open-pr - Pull request creation workflow
- start-work - Begin work on GitHub issue

These commands currently exist in .claude/commands/ but should be provided as templates that users can customize during setup, similar to how agents and knowledge files work.

Benefits:

- Users can customize workflow commands to match their process
- Templates serve as documentation for command structure
- Easier maintenance and updates
- Consistent with existing template patterns

## Requirements

- Move command files from current location to templates/commands/
- Update install.sh to copy command templates during installation
- Ensure commands are properly integrated with existing template system
- Update documentation to reflect new template location
- Test installation workflow with templated commands

## Technical Details

Current structure:
\`\`\`
.claude/commands/
  ├── cleanup-main.md
  ├── implement.md
  ├── open-pr.md
  └── start-work.md
\`\`\`

Proposed structure:
\`\`\`
templates/commands/
  ├── cleanup-main.md
  ├── implement.md
  ├── open-pr.md
  └── start-work.md
\`\`\`

Installation flow should:

1. Copy command templates to ~/.claude/commands/
2. Allow user customization post-install
3. Maintain compatibility with existing workflows

## Success Criteria

- [ ] Command templates moved to templates/commands/
- [ ] install.sh updated to handle command templates
- [ ] Installation workflow verified (both normal and --dev mode)
- [ ] Documentation updated
- [ ] Existing workflow commands continue to function

## Related Issues

None yet

---
**Type**: chore
**Estimated Effort**: 1 hours
**Draft Slug**: add-workflow-commands-to-templates-folder-for-user-customization

## Work Tracking

- Branch: `milestone-v0.1.0/chore/39-add-workflow-commands-to-templates-folder`
- Started: 2025-10-07
- Work directory: `.github/issues/in-progress/issue-39/`

## Related Links

- [GitHub Issue](https://github.com/oakensoul/claude-personal-assistant/issues/39)
- [Project Board](https://github.com/oakensoul/claude-personal-assistant/projects)

## Notes

Add your work notes here...

## Resolution

**Completed**: 2025-10-07
**Pull Request**: # (will be filled after creation)

### Changes Made

- Added 4 workflow command templates to `templates/commands/`:
  - `cleanup-main.md`: Post-PR merge cleanup with stash restoration and context cleanup
  - `implement.md`: Implementation orchestration with task breakdown and agent delegation
  - `open-pr.md`: PR creation with automated checks, file exclusion, and reviewer strategies
  - `start-work.md`: Issue workflow initialization with branch setup and GitHub integration

- Enhanced `install.sh` with `copy_command_templates()` function:
  - Sed-based variable substitution for install-time processing ({{VAR}} → actual values)
  - Timestamped backups of existing commands in `~/.claude/commands/.backups/`
  - Dev mode support with symlinks for live editing
  - Permission enforcement (600) for installed commands
  - Validation of substitution success and detection of unresolved variables

- Enhanced `scripts/validate-templates.sh`:
  - Added `APPROVED_TEMPLATE_VARS` validation list (AIDA_HOME, CLAUDE_CONFIG_DIR, HOME, PROJECT_ROOT)
  - Added `check_template_variables()` function to validate {{VAR}} syntax
  - Integrated validation into main validation workflow

- Updated `.claude/workflow-state.json` to track issue #39

- Fixed all markdown linting errors across 4 command templates:
  - Added blank lines before/after code blocks (MD031)
  - Added language specifiers to all code blocks (MD040)
  - Fixed list indentation to 2-space standard (MD007)
  - Added blank lines around lists (MD032)
  - Fixed spaces in inline code elements (MD038)

### Implementation Details

**Template Variable Substitution Strategy:**

- Install-time substitution: `{{AIDA_HOME}}`, `{{CLAUDE_CONFIG_DIR}}`, `{{HOME}}` replaced by sed during installation
- Runtime substitution: `${PROJECT_ROOT}`, `${GIT_ROOT}` preserved for bash variable resolution
- Validation ensures no unresolved template variables remain after substitution

**Parallel Technical Writing:**

- Used 4 concurrent technical-writer agents to fix markdown linting in parallel
- Each agent handled one command file independently
- Significantly faster than manual/sequential fixes

**Quality Assurance:**

- All changes passed pre-commit hooks including markdownlint validation
- Template privacy validation confirms no hardcoded paths or user-specific data
- Shellcheck validation ensures install.sh function correctness

### Notes

The hybrid variable substitution approach (install-time {{VAR}} + runtime ${VAR}) provides flexibility:

- Install-time variables are fixed at installation (user-specific paths)
- Runtime variables resolve dynamically when commands execute (project-specific paths)

Commands are now customizable templates while maintaining proper variable abstraction for shareability.
