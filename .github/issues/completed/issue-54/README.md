---
issue: 54
title: "Implement discoverability commands (/agent-list, /skill-list, /command-list)"
status: "COMPLETED"
created: "2025-10-20 00:00:00"
completed: "2025-10-20"
pr: "60"
actual_effort: 3
estimated_effort: 3
---

# Issue #54: Implement discoverability commands (/agent-list, /skill-list, /command-list)

**Status**: COMPLETED
**Labels**: type:feature
**Milestone**: 0.1.0
**Assignees**: splash-rob

## Description

Help users explore available agents, skills, and commands with three new discoverability commands. These commands make AIDA more approachable by providing clear visibility into what's available.

Implement:

- `/agent-list` - List all available agents (global + project-level)
- `/skill-list` - List all 177+ skills from the skills catalog
- `/command-list [--category]` - List all commands with optional category filtering

Support optional category filtering for `/command-list` to help users find commands by domain (e.g., issue workflow, repository management, etc.).

## Requirements

### Implementation Strategy

Create the infrastructure that will seamlessly transition when `claude-agent-manager` is renamed to `aida` (issue #55):

1. **CLI Scripts** (`scripts/` directory):
   - [ ] `scripts/list-agents.sh` - Scan `~/.claude/agents/` and `./.claude/agents/` for all agents
   - [ ] `scripts/list-skills.sh` - List all 177+ skills from Claude Code skills catalog
   - [ ] `scripts/list-commands.sh` - Scan `~/.claude/commands/` and `./.claude/commands/` with optional `--category` filter

2. **Skills** (to be created and assigned to `claude-agent-manager`):
   - [ ] Create skill that invokes `list-agents.sh` and formats output
   - [ ] Create skill that invokes `list-skills.sh` and formats output
   - [ ] Create skill that invokes `list-commands.sh` and formats output

3. **Slash Commands** (`templates/commands/.aida/` directory):
   - [ ] `/agent-list` - Delegates to `claude-agent-manager` with agent-listing skill
   - [ ] `/skill-list` - Delegates to `claude-agent-manager` with skill-listing skill
   - [ ] `/command-list [--category]` - Delegates to `claude-agent-manager` with command-listing skill

4. **Agent Configuration**:
   - [ ] Update `claude-agent-manager` agent to include the three new skills
   - [ ] Test commands work with current agent
   - [ ] When issue #55 renames agent to `aida`, commands will automatically work

**Estimated Effort**: 3 hours
**Priority**: MEDIUM - High value for user experience, no blocking dependencies

**Dependencies**: None (builds on existing `claude-agent-manager`, will seamlessly work when renamed to `aida`)

## Work Tracking

- Branch: `milestone-v0.1/feature/54-implement-discoverability-commands`
- Started: 2025-10-20
- Work directory: `.github/issues/in-progress/issue-54/`

## Related Links

- [GitHub Issue](https://github.com/oakensoul/claude-personal-assistant/issues/54)
- [Project Board](https://github.com/oakensoul/claude-personal-assistant/projects)

## Notes

Add your work notes here...

## Resolution

**Completed**: 2025-10-20
**Pull Request**: #60 - <https://github.com/oakensoul/claude-personal-assistant/pull/60>

### Changes Made

Successfully implemented discoverability commands with comprehensive CLI infrastructure:

1. **CLI Scripts** - Created 7 bash scripts for discovery and utilities:
   - `list-agents.sh` - Discovers and lists all agents from user and project levels
   - `list-commands.sh` - Discovers and lists commands with category filtering
   - `list-skills.sh` - Discovers and lists skills by category
   - `frontmatter-parser.sh` - Parses YAML frontmatter from markdown files
   - `json-formatter.sh` - Formats output as structured JSON
   - `path-sanitizer.sh` - Sanitizes paths for privacy protection
   - `readlink-portable.sh` - Cross-platform symlink resolution

2. **Meta-Skills** - Created 5 foundational skills providing AIDA system knowledge:
   - `aida-agents` - Comprehensive agent architecture knowledge
   - `aida-commands` - Command architecture and patterns
   - `aida-skills` - Skill system architecture
   - `aida-config` - Configuration and customization guidance
   - `pytest-patterns` - Testing patterns for developers

3. **Slash Commands** - Created 3 discovery commands:
   - `/agent-list` - Lists all available agents with versions and descriptions
   - `/command-list [--category]` - Lists commands with optional filtering by 8 categories
   - `/skill-list` - Lists all available skills grouped by category

4. **Architecture Documentation** - Created 3 ADRs:
   - ADR-014: Discoverability command architecture
   - ADR-015: Skills system implementation
   - ADR-003: Rename agents-global to project namespace

5. **Installation Fix** - Scripts now install to `~/.claude/scripts/.aida/`:
   - Follows namespace pattern consistent with commands/agents/skills
   - Dev mode uses symlinks, normal mode copies files
   - Updated installer and documentation paths

6. **Quality Improvements**:
   - Added pre-commit setup documentation
   - Fixed markdown linting across all 100+ template files
   - All files pass markdownlint --strict validation

### Implementation Details

**Architecture Pattern**:

- Commands delegate to `claude-agent-manager` agent
- Agent uses meta-skills (`aida-agents`, `aida-commands`, `aida-skills`) for knowledge
- Meta-skills invoke CLI scripts for discovery
- Scripts parse frontmatter and format output (text or JSON)

**Key Technical Decisions**:

- Used meta-skills as single source of truth for AIDA architecture
- CLI scripts provide reusable discovery logic
- Privacy-aware path sanitization protects user information
- Cross-platform compatibility (macOS + Linux)
- Comprehensive error handling and validation

**Testing**:

- All scripts tested in dev and normal installation modes
- Verified JSON and text output formats
- Validated category filtering for commands
- Confirmed symlink deduplication in dev mode

### Notes

- Estimated 3 hours, actual 3 hours - accurate estimate
- All discoverability commands working correctly
- Scripts installation now follows consistent namespace pattern
- Pre-commit infrastructure added for code quality
- Foundation ready for future `claude-agent-manager` → `aida` rename
