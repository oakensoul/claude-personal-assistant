# Workflow Configuration Schema

This document describes all available options for `.claude/workflow-config.json`.

## Full Schema

```json
{
  "workflow": {
    "issue_tracking": {
      "enabled": true,
      "directory": ".github/issues",
      "states": {
        "in_progress": "in-progress",
        "completed": "completed"
      }
    },
    "time_tracking": {
      "enabled": true,
      "directory": ".time-tracking",
      "branch_prefix": "time-tracking"
    },
    "branching": {
      "format": "milestone-v{milestone}/{type}/{id}-{description}",
      "requires_milestone": true
    },
    "pull_requests": {
      "versioning": {
        "enabled": true,
        "files": ["package.json"],
        "changelog": "CHANGELOG.md",
        "readme_summary": true,
        "readme_path": "README.md"
      },
      "reviewers": {
        "strategy": "none",
        "team": []
      },
      "merge_strategy": "squash"
    },
    "issue_creation": {
      "requires_milestone": true,
      "auto_assign": false,
      "templates": {
        "use_structured_body": true
      }
    }
  }
}
```

## Reviewer Strategy Options

The `pull_requests.reviewers.strategy` field supports five strategies:

### 1. none (default)

No reviewers assigned automatically.

```json
{
  "reviewers": {
    "strategy": "none"
  }
}
```

**Use case:** Solo projects, manual assignment, or when you don't want automatic reviewers.

### 2. query (most flexible)

Prompts you to select reviewers when running `/open-pr`. Shows team list as suggestions if configured.

```json
{
  "reviewers": {
    "strategy": "query",
    "team": ["user1", "user2", "github-copilot[bot]"]
  }
}
```

**Use case:** When you want flexibility to choose different reviewers per PR, but want quick access to a common team list.

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

Assigns **all** team members to every PR.

```json
{
  "reviewers": {
    "strategy": "list",
    "team": ["user1", "user2", "github-copilot[bot]"]
  }
}
```

**Use case:** Small teams where everyone should review everything, or when you always want specific reviewers (e.g., human + bot).

**Example:** With the config above, every PR gets assigned to user1, user2, AND github-copilot[bot].

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

**Use case:** Larger teams where you want to distribute review load evenly.

**Rotation:**

- PR #1 → user1
- PR #2 → user2
- PR #3 → user3
- PR #4 → user1
- ...and so on

### 5. auto

No reviewers assigned by the command. Lets GitHub's auto-assignment handle it (CODEOWNERS, repo settings, etc.).

```json
{
  "reviewers": {
    "strategy": "auto"
  }
}
```

**Use case:** When you have GitHub auto-assignment configured (CODEOWNERS file, repository settings) and want to use that instead.

## Overriding Reviewer Strategy

You can always override the configured strategy using the `--reviewers` parameter:

```bash
# Override with specific reviewers
/open-pr reviewers="user1,github-copilot[bot]"

# Override to no reviewers
/open-pr reviewers=""
```

## Common Team Configurations

### Solo Developer

```json
{
  "reviewers": {
    "strategy": "none"
  }
}
```

### Solo Developer with GitHub Copilot

```json
{
  "reviewers": {
    "strategy": "list",
    "team": ["github-copilot[bot]"]
  }
}
```

### Small Team (2-3 people)

```json
{
  "reviewers": {
    "strategy": "list",
    "team": ["alice", "bob", "github-copilot[bot]"]
  }
}
```

### Larger Team (4+ people)

```json
{
  "reviewers": {
    "strategy": "round-robin",
    "team": ["alice", "bob", "charlie", "dana"]
  }
}
```

### Flexible Assignment

```json
{
  "reviewers": {
    "strategy": "query",
    "team": ["alice", "bob", "charlie", "github-copilot[bot]"]
  }
}
```

### Using CODEOWNERS

```json
{
  "reviewers": {
    "strategy": "auto"
  }
}
```

## Other Configuration Options

### Branching Format Placeholders

- `{milestone}` - Milestone version (e.g., "v0.1")
- `{type}` - Branch type (feature, bugfix, hotfix, etc.)
- `{id}` - Issue number
- `{description}` - Issue description (kebab-case)

**Examples:**

- `milestone-v{milestone}/{type}/{id}-{description}` → `milestone-v0.1/feature/42-add-login`
- `{type}/{id}-{description}` → `feature/42-add-login`
- `{type}/{id}` → `feature/42`
- `{id}-{description}` → `42-add-login`

### Merge Strategy Options

- `squash` - Squash all commits into one when merging (recommended)
- `merge` - Standard merge commit
- `rebase` - Rebase and merge

### Versioning Files

The `pull_requests.versioning.files` array can include any files that contain version numbers:

- Node.js: `package.json`
- Python: `pyproject.toml`, `setup.py`
- Rust: `Cargo.toml`
- PHP: `composer.json`
- Ruby: `*.gemspec`
- Generic: `VERSION`, `version.txt`

## Integration with Commands

- **`/workflow-init`** - Creates initial configuration
- **`/start-work <issue-id>`** - Uses `branching` and `issue_tracking` config
- **`/open-pr`** - Uses `versioning`, `reviewers`, and `merge_strategy` config
- **`/track-time <hours>`** - Uses `time_tracking` config
- **`/create-issue`** - Uses `issue_creation` config
- **`/cleanup-main`** - Uses `merge_strategy` config

## See Also

- [workflow-init.md](~/.claude/commands/workflow-init.md) - Configure workflow interactively
- [open-pr.md](~/.claude/commands/open-pr.md) - Create pull requests with automation
