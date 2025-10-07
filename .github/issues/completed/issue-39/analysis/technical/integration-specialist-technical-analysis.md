---
title: "Integration Specialist Technical Analysis - Issue #39"
issue: 39
analyst: "integration-specialist"
analysis_type: "technical"
created: "2025-10-07"
status: "completed"
---

# Integration Specialist Technical Analysis: Workflow Commands Template Implementation

## 1. Implementation Approach

### Integration Architecture

#### Current State

- Workflow commands exist in `~/.claude/commands/` (installed system)
- Commands integrate with git, gh CLI, and agents
- No source templates in repository

#### Target State

- Command templates in `templates/commands/workflows/`
- Install script copies templates to `~/.claude/commands/workflows/`
- Dev mode creates symlinks for live editing

#### Migration Strategy

```bash
# Extract from installed system
cp ~/.claude/commands/{cleanup-main,implement,open-pr,start-work}.md \
   templates/commands/workflows/

# Remove hardcoded paths in templates
sed -i '' 's|/Users/oakensoul/Developer/oakensoul/claude-personal-assistant|${PROJECT_ROOT}|g' \
   templates/commands/workflows/*.md
```

### Variable Resolution Strategy

#### Runtime Variables Required

- `${PROJECT_ROOT}` - Current project working directory
- `${CLAUDE_CONFIG_DIR}` - User's ~/.claude directory path
- `${HOME}` - User home directory

#### Resolution Approach

Commands already use environment variable syntax (`${VAR}`). Claude Code resolves these at runtime. No install-time substitution needed.

#### Verification

```bash
# Test variable resolution in command
grep -r '\${PROJECT_ROOT}' templates/commands/workflows/
grep -r '/Users/oakensoul' templates/commands/workflows/  # Should return nothing
```

### Dependency Management

#### Command Chain Dependencies

```text
/start-work creates:
  └── .github/issues/in-progress/issue-{id}/README.md

/expert-analysis reads:
  └── .github/issues/in-progress/issue-{id}/README.md

/implement reads:
  └── .github/issues/in-progress/issue-{id}/analysis/*.md

/open-pr moves:
  └── .github/issues/in-progress/issue-{id}/ → completed/

/cleanup-main restores:
  └── Stashed changes from /open-pr
```

#### State Files Shared Between Commands

- `${PROJECT_ROOT}/.claude/workflow-state.json` - Workflow metadata
- `${PROJECT_ROOT}/.claude/workflow-config.json` - User configuration
- `${PROJECT_ROOT}/.implementation-state.json` - Implementation tracking

#### Integration Risk

Commands must maintain state file compatibility during template migration.

## 2. Technical Concerns

### Integration Breakage Risks

#### Risk 1: Git Integration Failures

- Commands invoke git directly via Bash tool
- Relative path assumptions may break
- Branch switching affects workflow state

#### Mitigation

```bash
# Verify git commands use absolute paths
cd "${PROJECT_ROOT}" || exit 1  # Always establish working directory
git status --porcelain           # Relative to PROJECT_ROOT
```

#### Risk 2: GitHub CLI Integration Failures

- `gh issue view`, `gh pr create`, `gh issue edit` must resolve correctly
- Network failures during command execution
- Token authentication issues

#### Mitigation

```bash
# Verify gh CLI availability and authentication
if ! command -v gh &> /dev/null; then
    echo "Error: GitHub CLI (gh) not found. Install: brew install gh"
    exit 1
fi

if ! gh auth status &> /dev/null; then
    echo "Error: Not authenticated with GitHub. Run: gh auth login"
    exit 1
fi
```

#### Risk 3: Agent Integration Breakpoints

- Commands invoke devops-engineer for git operations
- Commands invoke technical-writer for documentation
- Agent availability must be verified

#### Mitigation

Commands should gracefully degrade if agents unavailable (manual user action).

### Runtime Dependencies

#### Required External Tools

- `git` (version 2.23+ for `git switch`)
- `gh` (GitHub CLI 2.0+)
- `jq` (JSON parsing for workflow state)
- `sed`, `awk` (text processing)

#### Verification in install.sh

```bash
check_command_dependencies() {
    local missing=()

    command -v git >/dev/null || missing+=("git")
    command -v gh >/dev/null || missing+=("gh (GitHub CLI)")
    command -v jq >/dev/null || missing+=("jq")

    if [ ${#missing[@]} -gt 0 ]; then
        echo "Warning: Missing dependencies for workflow commands:"
        printf '  - %s\n' "${missing[@]}"
        echo "Some workflow commands may not function correctly."
    fi
}
```

### Command Chain Coordination

#### Sequential Dependencies

1. `/start-work` must complete before `/expert-analysis`
2. `/expert-analysis` must complete before `/implement`
3. `/implement` must complete before `/open-pr`
4. `/open-pr` must complete before `/cleanup-main`

#### Failure Scenarios

- User runs `/open-pr` without `/start-work` - No issue directory exists
- User runs `/cleanup-main` without `/open-pr` - No stashed changes exist

#### Mitigation Pattern

```bash
# Each command validates prerequisites
if [ ! -d ".github/issues/in-progress/issue-${ISSUE_ID}" ]; then
    echo "Error: Issue directory not found. Run /start-work ${ISSUE_ID} first."
    exit 1
fi
```

### State Management

#### Workflow State File (`${PROJECT_ROOT}/.claude/workflow-state.json`)

```json
{
  "current_issue": 39,
  "branch": "milestone-v0.1.0/chore/39-add-workflow-commands",
  "started": "2025-10-07T10:30:00Z",
  "analysis_complete": false,
  "implementation_complete": false,
  "stashed_changes": []
}
```

#### State File Integration Concerns

- Commands must use consistent JSON schema
- Concurrent command execution may corrupt state
- State file must survive git operations (not .gitignored by default)

#### Mitigation

```bash
# Atomic state updates with jq
update_workflow_state() {
    local key="$1"
    local value="$2"
    local state_file="${PROJECT_ROOT}/.claude/workflow-state.json"

    # Create lock file
    local lock_file="${state_file}.lock"
    while [ -f "${lock_file}" ]; do sleep 0.1; done
    touch "${lock_file}"

    # Update state
    jq --arg k "${key}" --arg v "${value}" '.[$k] = $v' "${state_file}" > "${state_file}.tmp"
    mv "${state_file}.tmp" "${state_file}"

    # Release lock
    rm "${lock_file}"
}
```

## 3. Dependencies & Integration

### External Tool Dependencies

#### Git Integration Points

- `git status --porcelain` - Detect uncommitted changes
- `git branch --show-current` - Validate current branch
- `git switch -c <branch>` - Create feature branch
- `git add -A` - Stage changes
- `git commit -m "message"` - Create commits
- `git push -u origin <branch>` - Push to remote
- `git stash push -u` - Stash excluded changes

#### GitHub CLI Integration Points

- `gh issue view <id> --json <fields>` - Fetch issue details
- `gh issue edit <id> --add-assignee @me` - Assign issue
- `gh pr create --title "..." --body "..."` - Create PR
- `gh pr view --json url` - Get PR URL

#### Tool Version Requirements

```bash
# Minimum versions
git: 2.23.0  # For git switch command
gh: 2.0.0    # For stable JSON output
jq: 1.6      # For JSON processing
```

### Agent Integration Points

#### devops-engineer Agent (used by `/implement`)

- Git operations: commits, branch management
- Pre-commit hook handling
- Conflict resolution

#### technical-writer Agent (used by `/open-pr`)

- Changelog generation
- PR description writing
- README updates

#### Agent Invocation Pattern

```markdown
Execute the following bash commands to perform git operations:
[Commands for devops-engineer to execute]
```

#### Integration Risk

Agent must be available and understand command structure.

### Configuration File Dependencies

#### workflow-config.json (created by `/workflow-init`)

```json
{
  "workflow": {
    "issue_tracking": {
      "enabled": true,
      "directory": ".github/issues"
    },
    "branching": {
      "format": "milestone-v{milestone}/{type}/{id}-{description}"
    },
    "pull_requests": {
      "reviewers": {
        "strategy": "query",
        "team": ["user1", "user2"]
      }
    }
  }
}
```

#### Commands Read Configuration

- `/start-work` - Reads `branching.format`, `issue_tracking.directory`
- `/open-pr` - Reads `pull_requests.reviewers`, `pull_requests.versioning`
- `/track-time` - Reads `time_tracking.enabled`, `time_tracking.directory`

#### Fallback Behavior

Commands use sensible defaults if config missing.

## 4. Effort & Complexity

### Estimated Complexity: MEDIUM (M)

#### Rationale

- Commands already exist (extraction, not creation)
- Integration patterns established
- Main work: path cleanup and install.sh update

#### Breakdown

- Command extraction and path cleanup: 30 minutes
- install.sh update with backup logic: 30 minutes
- Dev mode symlink handling: 15 minutes
- Testing (normal install, dev mode, reinstall): 30 minutes
- Documentation updates: 15 minutes

#### Total Estimate

2 hours

### Integration Effort

#### Template Creation (LOW)

- Copy existing commands to templates/
- Remove hardcoded paths
- Add .template extension if needed

#### install.sh Updates (MEDIUM)

```bash
install_command_templates() {
    local template_dir="${SCRIPT_DIR}/templates/commands/workflows"
    local install_dir="${CLAUDE_DIR}/commands/workflows"

    # Backup existing commands
    if [ -d "${install_dir}" ]; then
        local backup_dir="${CLAUDE_DIR}/commands.backup.$(date +%Y%m%d_%H%M%S)"
        mv "${install_dir}" "${backup_dir}"
        echo "Backed up existing commands to: ${backup_dir}"
    fi

    # Copy or symlink based on mode
    if [ "${DEV_MODE}" = true ]; then
        ln -s "${template_dir}" "${install_dir}"
        echo "Symlinked commands for dev mode"
    else
        cp -r "${template_dir}" "${install_dir}"
        echo "Installed command templates"
    fi
}
```

#### Testing (MEDIUM)

- Fresh install (normal mode)
- Fresh install (dev mode)
- Reinstall with existing commands
- Command execution after install
- State file creation and updates

### High-Risk Areas

#### Risk Area 1: Hardcoded Path Removal

- **Impact**: Commands fail if absolute paths remain
- **Likelihood**: High (multiple commands have hardcoded paths)
- **Mitigation**: Automated search-and-replace + manual verification

```bash
# Automated cleanup
find templates/commands/workflows -type f -name "*.md" -exec sed -i '' \
  's|/Users/[^/]*/Developer/[^/]*/claude-personal-assistant|${PROJECT_ROOT}|g' {} +

# Manual verification
grep -r "Users/" templates/commands/workflows/
```

#### Risk Area 2: State File Corruption

- **Impact**: Workflow state lost, commands fail
- **Likelihood**: Medium (concurrent command execution)
- **Mitigation**: File locking pattern, atomic updates

#### Risk Area 3: Git Integration in Different Contexts

- **Impact**: Commands fail in non-git directories or detached HEAD
- **Likelihood**: Low (users follow workflow)
- **Mitigation**: Validate git context before operations

```bash
# Validate git context
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "Error: Not in a git repository"
    exit 1
fi
```

#### Risk Area 4: GitHub CLI Authentication

- **Impact**: Commands fail silently or with cryptic errors
- **Likelihood**: Medium (users forget to authenticate)
- **Mitigation**: Check authentication before gh commands

## 5. Questions & Clarifications

### Integration Questions

#### Q1: Should commands validate external tool availability?

- Context: git, gh, jq required for commands
- Options: (A) Fail fast with clear error, (B) Attempt operation and handle failure
- Recommendation: Option A - Fail fast with installation instructions

#### Q2: How should commands handle git authentication failures?

- Context: `git push` may fail if SSH keys not configured
- Options: (A) Show error and exit, (B) Prompt for credentials, (C) Fall back to HTTPS
- Recommendation: Option A - User must configure git separately

#### Q3: Should workflow state be committed to git?

- Context: `.claude/workflow-state.json` tracks current work
- Options: (A) Commit (team visibility), (B) Gitignore (local only), (C) Configurable
- Recommendation: Option B - Local state, not shared

#### Q4: How should dev mode handle command modifications?

- Context: Dev mode symlinks commands for live editing
- Options: (A) Changes affect repository, (B) Copy-on-write, (C) Branch-specific commands
- Recommendation: Option A - Dev mode users understand symlink behavior

### Architecture Decisions

#### Decision 1: Template File Extension

- Question: Should command templates use `.template` extension?
- Context: Other templates use `.template`, but commands are markdown
- Options: (A) `.md.template`, (B) `.md` (no extension), (C) `.template.md`
- Recommendation: Option B - Keep `.md` extension, templates are valid markdown

#### Decision 2: Workflow Commands Subdirectory

- Question: Should workflow commands be in `workflows/` subdirectory?
- Context: Separates workflow commands from utility commands
- Options: (A) `templates/commands/workflows/`, (B) `templates/commands/` (flat)
- Recommendation: Option A - Subdirectory for organization

#### Decision 3: Backup Strategy on Reinstall

- Question: How to handle existing commands on reinstall?
- Context: Users may customize commands
- Options: (A) Always overwrite, (B) Backup then overwrite, (C) Three-way merge
- Recommendation: Option B - Backup preserves customizations, users can merge manually

### Testing Needs

#### Integration Testing Required

**Fresh Install Normal Mode**:

- Run `./install.sh`
- Verify commands copied to `~/.claude/commands/workflows/`
- Execute `/start-work 1` (with mock issue)
- Verify git operations succeed

**Fresh Install Dev Mode**:

- Run `./install.sh --dev`
- Verify commands symlinked
- Modify command in repository
- Verify changes reflected in `~/.claude/commands/workflows/`

**Reinstall with Existing Commands**:

- Customize command in `~/.claude/commands/workflows/cleanup-main.md`
- Run `./install.sh` again
- Verify backup created with timestamp
- Verify new commands installed

**Command Chain Execution**:

- Run full workflow: `/start-work` → `/expert-analysis` → `/implement` → `/open-pr` → `/cleanup-main`
- Verify state files created and updated
- Verify git operations succeed
- Verify GitHub integration works

**Error Handling**:

- Run `/open-pr` without `/start-work` - Should error
- Run commands without gh authentication - Should error with clear message
- Run commands in non-git directory - Should error

#### Validation Checklist

- [ ] No hardcoded absolute paths in command templates
- [ ] Commands use runtime variables (`${PROJECT_ROOT}`, `${CLAUDE_CONFIG_DIR}`)
- [ ] install.sh creates backup of existing commands
- [ ] Dev mode creates symlinks, not copies
- [ ] Normal mode copies templates
- [ ] Commands execute successfully after install
- [ ] State files created in correct locations
- [ ] Git operations succeed in test repository
- [ ] GitHub CLI operations succeed with authentication
- [ ] Error messages clear and actionable

## Success Metrics

- **Integration Reliability**: 100% of commands execute successfully after installation (both modes).
- **Path Portability**: Commands work in any project directory without modification.
- **State Management**: No state file corruption during command chain execution.
- **External Tool Integration**: Clear error messages for missing tools (git, gh, jq).
- **Development Workflow**: Dev mode supports live editing of commands.
- **Backup Safety**: Existing commands backed up before reinstall, 0% data loss.

---

**Technical analysis complete**: Integration architecture defined, risks identified, implementation approach validated.
