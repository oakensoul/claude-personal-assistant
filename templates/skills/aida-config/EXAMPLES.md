---
title: "AIDA Config Skill - Extended Examples"
description: "Real-world usage examples for the AIDA Config skill"
category: "guide"
tags: ["skill", "configuration", "examples", "recipes"]
last_updated: "2025-10-18"
status: "published"
audience: "developers"
---

# AIDA Config Skill - Extended Examples

Real-world usage examples for common scenarios.

## Command Implementation Examples

### Example 1: Start Work Command

Complete implementation showing configuration usage throughout.

```bash
#!/bin/bash
set -euo pipefail

# Load configuration once at start
readonly CONFIG=$(aida-config-helper.sh)

# Extract all needed values
readonly PROJECT_ROOT=$(echo "$CONFIG" | jq -r '.paths.project_root')
readonly OWNER=$(echo "$CONFIG" | jq -r '.github.owner')
readonly REPO=$(echo "$CONFIG" | jq -r '.github.repo')
readonly MAIN_BRANCH=$(echo "$CONFIG" | jq -r '.github.main_branch')
readonly BRANCH_PREFIX=$(echo "$CONFIG" | jq -r '.workflow.branch.prefix // "feature"')
readonly INCLUDE_ISSUE=$(echo "$CONFIG" | jq -r '.workflow.branch.include_issue_number // true')

# Get issue number from argument
readonly ISSUE_NUM="$1"

# Construct branch name
if [[ "$INCLUDE_ISSUE" == "true" ]]; then
  readonly BRANCH_NAME="${BRANCH_PREFIX}/issue-${ISSUE_NUM}"
else
  readonly BRANCH_NAME="${BRANCH_PREFIX}/${ISSUE_NUM}"
fi

# Fetch latest from remote
git fetch origin "$MAIN_BRANCH"

# Create and checkout new branch
git checkout -b "$BRANCH_NAME" "origin/${MAIN_BRANCH}"

# Update issue status on GitHub
gh api "repos/${OWNER}/${REPO}/issues/${ISSUE_NUM}" \
  --method PATCH \
  --field state="open" \
  --field labels[]="in-progress"

# Create issue directory
readonly ISSUE_DIR="${PROJECT_ROOT}/.github/issues/in-progress/issue-${ISSUE_NUM}"
mkdir -p "$ISSUE_DIR"

# Initialize issue tracking
cat > "${ISSUE_DIR}/info.json" <<EOF
{
  "issue_number": ${ISSUE_NUM},
  "branch": "${BRANCH_NAME}",
  "started_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "owner": "${OWNER}",
  "repo": "${REPO}"
}
EOF

echo "Started work on issue #${ISSUE_NUM}"
echo "Branch: ${BRANCH_NAME}"
echo "Tracking: ${ISSUE_DIR}"
```

### Example 2: Implement Command with Auto-Commit

Shows conditional behavior based on configuration.

```bash
#!/bin/bash
set -euo pipefail

# Load configuration
readonly CONFIG=$(aida-config-helper.sh)

# Extract workflow settings
readonly AUTO_COMMIT=$(echo "$CONFIG" | jq -r '.workflow.commit.auto_commit // true')
readonly COMMIT_PREFIX=$(echo "$CONFIG" | jq -r '.workflow.commit.message_prefix // "feat"')
readonly PROJECT_ROOT=$(echo "$CONFIG" | jq -r '.paths.project_root')
readonly GIT_USER=$(echo "$CONFIG" | jq -r '.git.user.name')
readonly GIT_EMAIL=$(echo "$CONFIG" | jq -r '.git.user.email')

# Task implementation
implement_task() {
  local task_description="$1"

  echo "Implementing: $task_description"

  # ... implementation logic ...

  # Conditional auto-commit
  if [[ "$AUTO_COMMIT" == "true" ]]; then
    git add .
    git commit -m "${COMMIT_PREFIX}: ${task_description}" \
      --author="${GIT_USER} <${GIT_EMAIL}>"
    echo "✓ Changes committed automatically"
  else
    echo "! Changes staged but not committed (auto_commit=false)"
    git add .
  fi
}

# Process tasks
implement_task "add user authentication"
implement_task "implement password reset flow"
implement_task "add email verification"
```

### Example 3: Open PR Command

Shows GitHub integration and PR creation.

```bash
#!/bin/bash
set -euo pipefail

# Load configuration
readonly CONFIG=$(aida-config-helper.sh)

# Extract GitHub and workflow settings
readonly OWNER=$(echo "$CONFIG" | jq -r '.github.owner')
readonly REPO=$(echo "$CONFIG" | jq -r '.github.repo')
readonly MAIN_BRANCH=$(echo "$CONFIG" | jq -r '.github.main_branch')
readonly DRAFT=$(echo "$CONFIG" | jq -r '.workflow.pr.draft // false')
readonly AUTO_REVIEWERS=$(echo "$CONFIG" | jq -r '.workflow.pr.auto_reviewers[]? // empty')
readonly PROJECT_ROOT=$(echo "$CONFIG" | jq -r '.paths.project_root')

# Get current branch
readonly CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Extract issue number from branch name
readonly ISSUE_NUM=$(echo "$CURRENT_BRANCH" | grep -oE '[0-9]+' | head -1)

# Fetch issue details
readonly ISSUE_DATA=$(gh api "repos/${OWNER}/${REPO}/issues/${ISSUE_NUM}")
readonly ISSUE_TITLE=$(echo "$ISSUE_DATA" | jq -r '.title')

# Push branch
git push -u origin "$CURRENT_BRANCH"

# Build PR command
PR_CMD="gh pr create --base ${MAIN_BRANCH} --title \"${ISSUE_TITLE}\""

# Add draft flag if configured
if [[ "$DRAFT" == "true" ]]; then
  PR_CMD="${PR_CMD} --draft"
fi

# Add reviewers if configured
if [[ -n "$AUTO_REVIEWERS" ]]; then
  for reviewer in $AUTO_REVIEWERS; do
    PR_CMD="${PR_CMD} --reviewer ${reviewer}"
  done
fi

# Generate PR body
PR_BODY="Closes #${ISSUE_NUM}

## Summary
$(git log ${MAIN_BRANCH}..HEAD --pretty=format:'- %s')

## Test Plan
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing completed"

# Create PR
eval "$PR_CMD" --body "$PR_BODY"

echo "✓ Pull request created"
echo "  Branch: ${CURRENT_BRANCH} → ${MAIN_BRANCH}"
echo "  Issue: #${ISSUE_NUM}"
[[ "$DRAFT" == "true" ]] && echo "  Status: Draft"
```

## Agent Integration Examples

### Example 4: Agent Loading Configuration

How an agent should load and use configuration.

```markdown
# Technical Writer Agent

## Initialization

When invoked, load configuration to understand context:

```bash
# Load configuration
CONFIG=$(aida-config-helper.sh)

# Extract paths
AIDA_HOME=$(echo "$CONFIG" | jq -r '.paths.aida_home')
CLAUDE_CONFIG=$(echo "$CONFIG" | jq -r '.paths.claude_config_dir')
PROJECT_ROOT=$(echo "$CONFIG" | jq -r '.paths.project_root')

# Determine context
if [[ "$PROJECT_ROOT" != "null" ]] && [[ -d "${PROJECT_ROOT}/.aida" ]]; then
  CONTEXT="project"
  echo "Working in project context: $PROJECT_ROOT"
else
  CONTEXT="generic"
  echo "Working in generic context (no project detected)"
fi

# Load knowledge bases
if [[ "$CONTEXT" == "project" ]]; then
  # Load both user and project knowledge
  USER_KNOWLEDGE="${CLAUDE_CONFIG}/agents/technical-writer/knowledge"
  PROJECT_KNOWLEDGE="${PROJECT_ROOT}/.aida/agents/technical-writer/knowledge"
else
  # Load only user knowledge
  USER_KNOWLEDGE="${CLAUDE_CONFIG}/agents/technical-writer/knowledge"
fi
```

## Task Implementation

Use configuration throughout agent operation:

```bash
# Get user preferences
PERSONALITY=$(echo "$CONFIG" | jq -r '.user.personality')
ASSISTANT_NAME=$(echo "$CONFIG" | jq -r '.user.assistant_name')

# Generate documentation with personality
generate_documentation() {
  local doc_type="$1"

  case "$PERSONALITY" in
    JARVIS)
      tone="professional and concise"
      ;;
    Alfred)
      tone="warm and helpful"
      ;;
    *)
      tone="neutral and technical"
      ;;
  esac

  echo "Generating ${doc_type} documentation with ${tone} tone..."
}
```
```

### Example 5: Multi-Source Configuration Override

Shows how configuration priority works in practice.

```bash
#!/bin/bash
set -euo pipefail

# Scenario: Override project settings with environment variables

# System default (lowest priority)
# ~/.aida/config.json:
# {
#   "workflow": {
#     "commit": {
#       "auto_commit": true,
#       "message_prefix": "feat"
#     }
#   }
# }

# Project override (medium priority)
# ./.aida/config.json:
# {
#   "workflow": {
#     "commit": {
#       "message_prefix": "chore"
#     }
#   }
# }

# Environment override (highest priority)
export WORKFLOW_COMMIT_AUTO_COMMIT=false

# Load merged configuration
CONFIG=$(aida-config-helper.sh)

# Result:
# - auto_commit: false (from environment)
# - message_prefix: "chore" (from project)

AUTO_COMMIT=$(echo "$CONFIG" | jq -r '.workflow.commit.auto_commit')
PREFIX=$(echo "$CONFIG" | jq -r '.workflow.commit.message_prefix')

echo "Auto-commit: $AUTO_COMMIT"  # false
echo "Prefix: $PREFIX"             # chore
```

## Advanced Usage Examples

### Example 6: Configuration Validation in CI/CD

Ensure valid configuration before running workflows.

```bash
#!/bin/bash
set -euo pipefail

# CI/CD workflow validation script

validate_config() {
  echo "Validating AIDA configuration..."

  # Validate configuration syntax
  if ! aida-config-helper.sh --validate; then
    echo "ERROR: Invalid configuration" >&2
    return 1
  fi

  # Load config
  CONFIG=$(aida-config-helper.sh)

  # Check required fields
  local required_fields=(
    "paths.project_root"
    "github.owner"
    "github.repo"
    "github.main_branch"
  )

  for field in "${required_fields[@]}"; do
    value=$(echo "$CONFIG" | jq -r ".${field}")
    if [[ "$value" == "null" ]] || [[ -z "$value" ]]; then
      echo "ERROR: Required field missing: ${field}" >&2
      return 1
    fi
  done

  echo "✓ Configuration valid"
  return 0
}

# Run validation
if validate_config; then
  echo "Proceeding with workflow..."
else
  echo "Fix configuration errors before continuing" >&2
  exit 1
fi
```

### Example 7: Dynamic Configuration Based on Environment

Adjust behavior based on detected environment.

```bash
#!/bin/bash
set -euo pipefail

# Load configuration
CONFIG=$(aida-config-helper.sh)

# Detect environment
detect_environment() {
  local project_root=$(echo "$CONFIG" | jq -r '.paths.project_root')

  # Check for CI environment
  if [[ -n "${CI:-}" ]] || [[ -n "${GITHUB_ACTIONS:-}" ]]; then
    echo "ci"
    return
  fi

  # Check for project context
  if [[ "$project_root" != "null" ]] && [[ -d "$project_root" ]]; then
    echo "project"
    return
  fi

  # Default to user context
  echo "user"
}

ENVIRONMENT=$(detect_environment)

# Adjust behavior based on environment
case "$ENVIRONMENT" in
  ci)
    echo "Running in CI environment"
    # Disable interactive prompts
    AUTO_COMMIT=true
    DRAFT_PR=false
    ;;
  project)
    echo "Running in project context"
    # Use project configuration
    AUTO_COMMIT=$(echo "$CONFIG" | jq -r '.workflow.commit.auto_commit')
    DRAFT_PR=$(echo "$CONFIG" | jq -r '.workflow.pr.draft')
    ;;
  user)
    echo "Running in user context"
    # Use conservative defaults
    AUTO_COMMIT=false
    DRAFT_PR=true
    ;;
esac

echo "Settings:"
echo "  Auto-commit: $AUTO_COMMIT"
echo "  Draft PR: $DRAFT_PR"
```

### Example 8: Configuration Export for External Tools

Export configuration for use by external tools.

```bash
#!/bin/bash
set -euo pipefail

# Export AIDA configuration as environment variables

export_config() {
  local config=$(aida-config-helper.sh)

  # Export paths
  export AIDA_HOME=$(echo "$config" | jq -r '.paths.aida_home')
  export CLAUDE_CONFIG_DIR=$(echo "$config" | jq -r '.paths.claude_config_dir')
  export PROJECT_ROOT=$(echo "$config" | jq -r '.paths.project_root')

  # Export GitHub settings
  export GITHUB_OWNER=$(echo "$config" | jq -r '.github.owner')
  export GITHUB_REPO=$(echo "$config" | jq -r '.github.repo')
  export GITHUB_MAIN_BRANCH=$(echo "$config" | jq -r '.github.main_branch')

  # Export Git identity
  export GIT_AUTHOR_NAME=$(echo "$config" | jq -r '.git.user.name')
  export GIT_AUTHOR_EMAIL=$(echo "$config" | jq -r '.git.user.email')
  export GIT_COMMITTER_NAME=$(echo "$config" | jq -r '.git.user.name')
  export GIT_COMMITTER_EMAIL=$(echo "$config" | jq -r '.git.user.email')

  echo "✓ Configuration exported as environment variables"
}

# Export configuration
export_config

# Now external tools can use standard environment variables
echo "Repository: ${GITHUB_OWNER}/${GITHUB_REPO}"
echo "Committer: ${GIT_AUTHOR_NAME} <${GIT_AUTHOR_EMAIL}>"
```

### Example 9: Configuration Migration Script

Help users migrate from old config format to new.

```bash
#!/bin/bash
set -euo pipefail

# Migrate old configuration format to new

migrate_config() {
  local old_config="$HOME/.aida/old-config.json"
  local new_config="$HOME/.claude/config.json"

  if [[ ! -f "$old_config" ]]; then
    echo "No old configuration to migrate"
    return 0
  fi

  echo "Migrating configuration from $old_config to $new_config..."

  # Read old config
  local old=$(cat "$old_config")

  # Transform to new format
  local new=$(jq '{
    user: {
      assistant_name: .assistant_name,
      personality: .personality
    },
    workflow: {
      commit: {
        auto_commit: .auto_commit,
        message_prefix: .commit_prefix
      }
    }
  }' <<< "$old")

  # Write new config
  echo "$new" | jq . > "$new_config"

  # Validate new config
  if aida-config-helper.sh --validate; then
    echo "✓ Migration successful"
    echo "  Old config: $old_config"
    echo "  New config: $new_config"
    echo ""
    echo "Backup old config and remove it:"
    echo "  mv $old_config ${old_config}.backup"
  else
    echo "ERROR: Migration produced invalid configuration" >&2
    rm "$new_config"
    return 1
  fi
}

migrate_config
```

### Example 10: Configuration Debugging Tool

Diagnose configuration issues.

```bash
#!/bin/bash
set -euo pipefail

# Debug AIDA configuration

debug_config() {
  echo "=== AIDA Configuration Debug ==="
  echo ""

  # Check helper script
  echo "1. Helper Script Status:"
  if command -v aida-config-helper.sh &> /dev/null; then
    echo "   ✓ Found in PATH"
  elif [[ -x "$HOME/.aida/lib/aida-config-helper.sh" ]]; then
    echo "   ✓ Found at ~/.aida/lib/aida-config-helper.sh"
  else
    echo "   ✗ Not found or not executable"
    return 1
  fi
  echo ""

  # Check configuration files
  echo "2. Configuration Files:"
  local config_files=(
    "$HOME/.aida/config.json:System"
    "$HOME/.claude/config.json:User"
    "$(pwd)/.aida/config.json:Project"
    "$(pwd)/.aida/workflow-config.json:Workflow"
    "$(pwd)/.aida/github-config.json:GitHub"
  )

  for entry in "${config_files[@]}"; do
    IFS=: read -r file label <<< "$entry"
    if [[ -f "$file" ]]; then
      if jq . "$file" &> /dev/null; then
        echo "   ✓ ${label}: Valid JSON"
      else
        echo "   ✗ ${label}: Invalid JSON"
      fi
    else
      echo "   - ${label}: Not found"
    fi
  done
  echo ""

  # Validate merged config
  echo "3. Merged Configuration:"
  if aida-config-helper.sh --validate; then
    echo "   ✓ Valid"
  else
    echo "   ✗ Invalid"
    return 1
  fi
  echo ""

  # Show merged config
  echo "4. Merged Configuration Output:"
  aida-config-helper.sh | jq .
  echo ""

  # Check cache
  echo "5. Cache Status:"
  local cache_file="/tmp/aida-config-cache-$$"
  if [[ -f "$cache_file" ]]; then
    echo "   ✓ Cache exists"
    echo "   Size: $(stat -f%z "$cache_file" 2>/dev/null || stat -c%s "$cache_file" 2>/dev/null) bytes"
    echo "   Modified: $(stat -f%Sm "$cache_file" 2>/dev/null || stat -c%y "$cache_file" 2>/dev/null)"
  else
    echo "   - No cache (will be created on first call)"
  fi
  echo ""

  echo "✓ Debug complete"
}

debug_config
```

## Testing Examples

### Example 11: Unit Tests for Config Usage

```bash
#!/bin/bash
set -euo pipefail

# Unit tests for configuration usage

test_config_loading() {
  echo "Testing: Config loading..."

  local config=$(aida-config-helper.sh)

  # Should return valid JSON
  if ! echo "$config" | jq . &> /dev/null; then
    echo "  ✗ Invalid JSON returned"
    return 1
  fi

  echo "  ✓ Valid JSON returned"
  return 0
}

test_key_extraction() {
  echo "Testing: Key extraction..."

  local aida_home=$(aida-config-helper.sh --key paths.aida_home)

  # Should not be null or empty
  if [[ "$aida_home" == "null" ]] || [[ -z "$aida_home" ]]; then
    echo "  ✗ Failed to extract key"
    return 1
  fi

  # Should be a valid directory
  if [[ ! -d "$aida_home" ]]; then
    echo "  ✗ Path does not exist: $aida_home"
    return 1
  fi

  echo "  ✓ Key extracted: $aida_home"
  return 0
}

test_namespace_extraction() {
  echo "Testing: Namespace extraction..."

  local github_config=$(aida-config-helper.sh --namespace github)

  # Should return valid JSON
  if ! echo "$github_config" | jq . &> /dev/null; then
    echo "  ✗ Invalid JSON returned"
    return 1
  fi

  # Should contain expected keys
  local owner=$(echo "$github_config" | jq -r '.owner')
  if [[ "$owner" == "null" ]]; then
    echo "  ✗ Missing expected key: owner"
    return 1
  fi

  echo "  ✓ Namespace extracted: owner=$owner"
  return 0
}

# Run tests
test_config_loading
test_key_extraction
test_namespace_extraction

echo ""
echo "All tests passed!"
```

## See Also

- [README.md](./README.md) - Complete skill documentation
- [QUICKREF.md](./QUICKREF.md) - Quick reference guide
