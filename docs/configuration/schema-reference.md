---
title: "Configuration Schema Reference"
description: "Complete reference for AIDA configuration system including all namespaces, fields, and provider-specific settings"
category: "configuration"
tags: ["config", "schema", "reference", "vcs", "work-tracker", "team", "workflow"]
last_updated: "2025-10-20"
status: "published"
audience: "developers"
---

# Configuration Schema Reference

Complete technical reference for AIDA's configuration system. This document describes every available configuration field, validation rules, and provider-specific requirements.

## Overview

AIDA uses a JSON-based configuration system with a well-defined schema that supports multiple VCS providers, work trackers, team structures, and workflow automation settings.

### Configuration Files

AIDA supports a two-tier configuration hierarchy:

**User Configuration**:

- **Location**: `~/.claude/config.json`
- **Scope**: Personal preferences and defaults
- **Version Control**: Never committed to git (personal settings)
- **Purpose**: Your individual workflow preferences

**Project Configuration**:

- **Location**: `{project}/.aida/config.json`
- **Scope**: Project-wide team settings
- **Version Control**: Committed to git (shared with team)
- **Purpose**: Team collaboration and project-specific workflows

### Configuration Hierarchy

Settings are resolved in this order (later overrides earlier):

1. Schema defaults (built-in defaults)
2. User configuration (`~/.claude/config.json`)
3. Project configuration (`.aida/config.json`)
4. Environment variables (highest priority)

**Example**: If user config sets `workflow.commit.auto_commit: false` but project config sets it to `true`, the project setting wins for that project.

---

## Schema Version

**Current Version**: `1.0`

The schema version must be specified in all configuration files to ensure compatibility.

**Field**: `config_version`

- **Type**: `string`
- **Required**: Yes
- **Pattern**: `^\d+\.\d+$` (semantic versioning: major.minor)
- **Example**: `"1.0"`

---

## Namespaces

AIDA configuration is organized into four top-level namespaces:

1. **`vcs.*`** - Version Control System configuration
2. **`work_tracker.*`** - Issue/task tracking system configuration
3. **`team.*`** - Team members and code review configuration
4. **`workflow.*`** - Workflow automation behavior settings

---

## VCS Namespace

**Namespace**: `vcs.*`

**Purpose**: Configure your Version Control System provider (GitHub, GitLab, or Bitbucket) including repository location, enterprise hosting, and auto-detection settings.

### Common Fields

#### vcs.provider

**Type**: `string`

**Required**: Yes

**Valid Values**: `github`, `gitlab`, `bitbucket`

**Description**: The VCS provider hosting your repository. Determines which provider-specific fields are required and used by AIDA commands.

**Example**:

```json
{
  "vcs": {
    "provider": "github"
  }
}
```

#### vcs.owner

**Type**: `string`

**Required**: Yes (for GitHub and GitLab)

**Pattern**: `^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$` or single character

**Description**: Repository owner, organization name, or group. For GitHub/GitLab this is the username or organization. For Bitbucket, use `bitbucket.workspace` instead.

**Examples**:

- `"oakensoul"` (GitHub user)
- `"my-org"` (GitHub organization)
- `"engineering-team"` (GitLab group)

**Validation**:

- Must start and end with alphanumeric character
- May contain hyphens in the middle
- Single character names allowed

#### vcs.repo

**Type**: `string`

**Required**: Yes (for GitHub and GitLab)

**Pattern**: `^[a-zA-Z0-9][a-zA-Z0-9._-]*$`

**Description**: Repository name (not including owner). For Bitbucket, use `bitbucket.repo_slug` instead.

**Examples**:

- `"claude-personal-assistant"`
- `"my-project"`
- `"web.app"`

**Validation**:

- Must start with alphanumeric character
- May contain dots, underscores, hyphens
- Case-sensitive

#### vcs.main_branch

**Type**: `string`

**Required**: No

**Default**: `"main"`

**Pattern**: `^[a-zA-Z0-9][a-zA-Z0-9/_.-]*$`

**Description**: The primary branch name for your repository. Used by workflow commands for creating feature branches and pull requests.

**Common Values**:

- `"main"` (default, modern standard)
- `"master"` (legacy standard)
- `"develop"` (gitflow workflow)

**Example**:

```json
{
  "vcs": {
    "main_branch": "develop"
  }
}
```

#### vcs.auto_detect

**Type**: `boolean`

**Required**: No

**Default**: `true`

**Description**: Automatically detect VCS configuration from git remote URL. When enabled, AIDA will attempt to parse your git remote and populate owner/repo automatically.

**When to disable**:

- Using complex git remote structures
- Managing multiple remotes
- Prefer explicit configuration

**Example**:

```json
{
  "vcs": {
    "auto_detect": false
  }
}
```

---

### GitHub Provider

**Configuration**: `vcs.github.*`

**Used when**: `vcs.provider` is `"github"`

**Overview**: GitHub.com or GitHub Enterprise configuration for repositories hosted on GitHub.

#### Required Fields (GitHub)

When `vcs.provider` is `"github"`, these fields are required:

- `vcs.owner` - GitHub username or organization
- `vcs.repo` - Repository name

#### GitHub-Specific Fields

##### vcs.github.enterprise_url

**Type**: `string` or `null`

**Required**: No

**Default**: `null` (uses github.com)

**Pattern**: `^https://[a-zA-Z0-9][a-zA-Z0-9.-]*[a-zA-Z0-9](:[0-9]+)?(/.*)?$`

**Description**: GitHub Enterprise Server URL. Set to `null` or omit for github.com. Must use HTTPS protocol.

**Examples**:

- `null` (github.com)
- `"https://github.company.com"`
- `"https://github.acme-corp.com:8443"`

**Validation**:

- Must start with `https://`
- Must be valid domain or IP
- Optional port number
- Optional path component

#### Complete GitHub Example

**GitHub.com (public/private repos)**:

```json
{
  "config_version": "1.0",
  "vcs": {
    "provider": "github",
    "owner": "oakensoul",
    "repo": "claude-personal-assistant",
    "main_branch": "main",
    "auto_detect": true,
    "github": {
      "enterprise_url": null
    }
  }
}
```

**GitHub Enterprise**:

```json
{
  "config_version": "1.0",
  "vcs": {
    "provider": "github",
    "owner": "acme-corp",
    "repo": "enterprise-platform",
    "main_branch": "develop",
    "auto_detect": true,
    "github": {
      "enterprise_url": "https://github.acme-corp.com"
    }
  }
}
```

#### Common GitHub Issues

**Issue**: `owner` field validation fails

**Solution**: Ensure username/org doesn't have special characters other than hyphens, and doesn't start/end with hyphen

**Issue**: Enterprise URL validation fails

**Solution**: Ensure URL uses `https://` protocol (HTTP not allowed)

---

### GitLab Provider

**Configuration**: `vcs.gitlab.*`

**Used when**: `vcs.provider` is `"gitlab"`

**Overview**: GitLab.com or self-hosted GitLab configuration with project ID tracking.

#### Required Fields (GitLab)

When `vcs.provider` is `"gitlab"`, these fields are required:

- `vcs.owner` - GitLab username or group name
- `vcs.repo` - Repository/project name
- `vcs.gitlab.project_id` - GitLab project ID (numeric or full path)

#### GitLab-Specific Fields

##### vcs.gitlab.project_id

**Type**: `string`

**Required**: Yes (when provider is gitlab)

**Pattern**: `^[0-9]+$` or `^[a-zA-Z0-9][a-zA-Z0-9._-]*/[a-zA-Z0-9][a-zA-Z0-9._-]*$`

**Description**: GitLab project identifier. Can be numeric ID or full path format (group/project).

**Examples**:

- `"12345"` (numeric project ID)
- `"engineering-team/api-platform"` (full path)
- `"my-group/sub-group/project"` (nested groups)

**How to find**:

- GitLab UI: Settings > General > Project ID
- GitLab API: `GET /projects/:path` response includes `id`

##### vcs.gitlab.self_hosted_url

**Type**: `string` or `null`

**Required**: No

**Default**: `null` (uses gitlab.com)

**Pattern**: `^https://[a-zA-Z0-9][a-zA-Z0-9.-]*[a-zA-Z0-9](:[0-9]+)?(/.*)?$`

**Description**: Self-hosted GitLab instance URL. Set to `null` or omit for gitlab.com. Must use HTTPS.

**Examples**:

- `null` (gitlab.com)
- `"https://gitlab.company.io"`
- `"https://gitlab.acme.com:8443"`

##### vcs.gitlab.group

**Type**: `string` or `null`

**Required**: No

**Default**: `null` (inferred from owner)

**Pattern**: `^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$` or single character

**Description**: GitLab group name. Usually inferred from `vcs.owner`, but can be explicitly set for clarity.

**Example**:

```json
{
  "vcs": {
    "gitlab": {
      "group": "engineering-team"
    }
  }
}
```

#### Complete GitLab Example

**GitLab.com**:

```json
{
  "config_version": "1.0",
  "vcs": {
    "provider": "gitlab",
    "owner": "my-group",
    "repo": "my-project",
    "main_branch": "main",
    "auto_detect": true,
    "gitlab": {
      "project_id": "12345",
      "self_hosted_url": null,
      "group": null
    }
  }
}
```

**Self-Hosted GitLab**:

```json
{
  "config_version": "1.0",
  "vcs": {
    "provider": "gitlab",
    "owner": "engineering-team",
    "repo": "api-platform",
    "main_branch": "develop",
    "auto_detect": true,
    "gitlab": {
      "project_id": "engineering-team/api-platform",
      "self_hosted_url": "https://gitlab.company.io",
      "group": "engineering-team"
    }
  }
}
```

#### Common GitLab Issues

**Issue**: `project_id` validation fails

**Solution**: Use numeric ID from GitLab UI or full path format (group/project)

**Issue**: Can't find project ID

**Solution**: GitLab UI > Settings > General, look for "Project ID" field

---

### Bitbucket Provider

**Configuration**: `vcs.bitbucket.*`

**Used when**: `vcs.provider` is `"bitbucket"`

**Overview**: Bitbucket Cloud or Server configuration with workspace-based structure.

#### Required Fields (Bitbucket)

When `vcs.provider` is `"bitbucket"`, these fields are required:

- `vcs.bitbucket.workspace` - Bitbucket workspace slug
- `vcs.bitbucket.repo_slug` - Repository slug (lowercase)

**Note**: Bitbucket does NOT use `vcs.owner` or `vcs.repo` fields.

#### Bitbucket-Specific Fields

##### vcs.bitbucket.workspace

**Type**: `string`

**Required**: Yes (when provider is bitbucket)

**Pattern**: `^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$` or single character

**Description**: Bitbucket workspace slug. This is the workspace identifier visible in Bitbucket URLs.

**Examples**:

- `"my-workspace"`
- `"startup-company"`
- `"team-alpha"`

**How to find**:

- Bitbucket URL: `https://bitbucket.org/{workspace}/`
- Workspace Settings > Workspace details

##### vcs.bitbucket.repo_slug

**Type**: `string`

**Required**: Yes (when provider is bitbucket)

**Pattern**: `^[a-z0-9][a-z0-9-]*[a-z0-9]$` or single character

**Description**: Repository slug (lowercase with hyphens). This is the URL-safe repository identifier.

**Examples**:

- `"my-project"`
- `"web-app"`
- `"api-service"`

**Validation**:

- Must be lowercase
- Must start and end with alphanumeric
- May contain hyphens in the middle

**How to find**:

- Bitbucket URL: `https://bitbucket.org/{workspace}/{repo_slug}`
- Repository Settings > Repository details

#### Complete Bitbucket Example

```json
{
  "config_version": "1.0",
  "vcs": {
    "provider": "bitbucket",
    "main_branch": "main",
    "auto_detect": true,
    "bitbucket": {
      "workspace": "startup-company",
      "repo_slug": "web-application"
    }
  }
}
```

**Note**: Do not include `owner` or `repo` fields when using Bitbucket provider.

#### Common Bitbucket Issues

**Issue**: `repo_slug` validation fails

**Solution**: Ensure slug is lowercase. Convert `My-Project` to `my-project`

**Issue**: Using `owner`/`repo` instead of Bitbucket fields

**Solution**: Remove `owner`/`repo`, use `bitbucket.workspace` and `bitbucket.repo_slug` instead

---

## Work Tracker Namespace

**Namespace**: `work_tracker.*`

**Purpose**: Configure your issue/task tracking system for work management integration with AIDA workflows.

### Common Fields

#### work_tracker.provider

**Type**: `string`

**Required**: Yes

**Valid Values**: `github_issues`, `jira`, `linear`, `none`

**Description**: Work tracking provider type. Use `none` to disable work tracking integration entirely.

**Examples**:

- `"github_issues"` - Use GitHub Issues
- `"jira"` - Use Jira Cloud or Server
- `"linear"` - Use Linear issue tracker
- `"none"` - Disable work tracking

#### work_tracker.auto_detect

**Type**: `boolean`

**Required**: No

**Default**: `true`

**Description**: Automatically detect work tracker from VCS configuration. When enabled and `provider` is `github_issues`, AIDA will use the GitHub repository's issue tracker.

**When to disable**:

- Using different tracker than VCS (e.g., GitHub VCS + Jira)
- Prefer explicit configuration
- Testing different trackers

**Example**:

```json
{
  "work_tracker": {
    "provider": "jira",
    "auto_detect": false
  }
}
```

---

### GitHub Issues Provider

**Configuration**: `work_tracker.github_issues.*`

**Used when**: `work_tracker.provider` is `"github_issues"`

**Overview**: Use GitHub's built-in issue tracking system for work management.

#### GitHub Issues Fields

##### work_tracker.github_issues.enabled

**Type**: `boolean`

**Required**: No

**Default**: `true`

**Description**: Enable GitHub Issues integration. Set to `false` to temporarily disable without changing provider.

**Example**:

```json
{
  "work_tracker": {
    "provider": "github_issues",
    "github_issues": {
      "enabled": true
    }
  }
}
```

#### Complete GitHub Issues Example

```json
{
  "config_version": "1.0",
  "work_tracker": {
    "provider": "github_issues",
    "auto_detect": true,
    "github_issues": {
      "enabled": true
    }
  }
}
```

---

### Jira Provider

**Configuration**: `work_tracker.jira.*`

**Used when**: `work_tracker.provider` is `"jira"`

**Overview**: Jira Cloud or Jira Server integration for enterprise issue tracking.

#### Required Fields (Jira)

When `work_tracker.provider` is `"jira"`, these fields are required:

- `work_tracker.jira.base_url` - Jira instance URL
- `work_tracker.jira.project_key` - Jira project identifier

#### Jira-Specific Fields

##### work_tracker.jira.base_url

**Type**: `string`

**Required**: Yes (when provider is jira)

**Pattern**: `^https://[a-zA-Z0-9][a-zA-Z0-9.-]*[a-zA-Z0-9](:[0-9]+)?(/.*)?$`

**Description**: Jira instance base URL. Must use HTTPS protocol. Supports both Jira Cloud (Atlassian-hosted) and Jira Server/Data Center (self-hosted).

**Examples**:

- `"https://company.atlassian.net"` (Jira Cloud)
- `"https://jira.company.com"` (Jira Server)
- `"https://jira.acme.io:8443"` (custom port)

**Validation**:

- Must start with `https://`
- Must be valid domain
- Optional port number
- Optional path component

##### work_tracker.jira.project_key

**Type**: `string`

**Required**: Yes (when provider is jira)

**Pattern**: `^[A-Z0-9]{1,10}$`

**Description**: Jira project key (uppercase alphanumeric, 1-10 characters). This appears in issue identifiers like `PROJ-123`.

**Examples**:

- `"PROJ"`
- `"TEAM123"`
- `"WEB"`
- `"API"`

**Validation**:

- Must be uppercase
- Only letters and numbers
- Maximum 10 characters

**How to find**:

- Jira UI: Project Settings > Details > Key
- Issue URLs: `{base_url}/browse/{PROJECT_KEY}-123`

#### Complete Jira Example

**Jira Cloud**:

```json
{
  "config_version": "1.0",
  "work_tracker": {
    "provider": "jira",
    "auto_detect": false,
    "jira": {
      "base_url": "https://company.atlassian.net",
      "project_key": "PROJ"
    }
  }
}
```

**Jira Server (Self-Hosted)**:

```json
{
  "config_version": "1.0",
  "work_tracker": {
    "provider": "jira",
    "auto_detect": false,
    "jira": {
      "base_url": "https://jira.company.io",
      "project_key": "API"
    }
  }
}
```

#### Common Jira Issues

**Issue**: `project_key` validation fails

**Solution**: Ensure key is uppercase and alphanumeric only (no special characters)

**Issue**: `base_url` validation fails

**Solution**: Ensure URL uses `https://` protocol (HTTP not allowed)

**Issue**: Can't find project key

**Solution**: Check Jira issue URLs - key appears before hyphen in issue IDs (e.g., `PROJ-123` → key is `PROJ`)

---

### Linear Provider

**Configuration**: `work_tracker.linear.*`

**Used when**: `work_tracker.provider` is `"linear"`

**Overview**: Linear issue tracking platform integration for modern development teams.

#### Required Fields (Linear)

When `work_tracker.provider` is `"linear"`, these fields are required:

- `work_tracker.linear.team_id` - Linear team UUID
- `work_tracker.linear.board_id` - Linear board UUID

#### Linear-Specific Fields

##### work_tracker.linear.team_id

**Type**: `string`

**Required**: Yes (when provider is linear)

**Pattern**: `^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$`

**Description**: Linear team UUID (universally unique identifier). Identifies which Linear team to use for issue tracking.

**Example**:

```json
{
  "work_tracker": {
    "linear": {
      "team_id": "123e4567-e89b-12d3-a456-426614174000"
    }
  }
}
```

**Validation**:

- Must be valid UUID v4 format
- Lowercase hexadecimal
- Standard UUID hyphen positions

**How to find**:

- Linear UI: Team Settings > General > Team ID
- Linear API: `GET /teams` response
- Browser URL: Settings page URL parameters

##### work_tracker.linear.board_id

**Type**: `string`

**Required**: Yes (when provider is linear)

**Pattern**: `^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$`

**Description**: Linear board UUID. Identifies which Linear board/project to track issues from.

**Example**:

```json
{
  "work_tracker": {
    "linear": {
      "board_id": "987fcdeb-51a2-43f1-9876-543210fedcba"
    }
  }
}
```

**Validation**:

- Must be valid UUID v4 format
- Lowercase hexadecimal
- Standard UUID hyphen positions

**How to find**:

- Linear UI: Board Settings > Board ID
- Linear API: `GET /projects` response
- Browser URL: Board page URL parameters

#### Complete Linear Example

```json
{
  "config_version": "1.0",
  "work_tracker": {
    "provider": "linear",
    "auto_detect": false,
    "linear": {
      "team_id": "123e4567-e89b-12d3-a456-426614174000",
      "board_id": "987fcdeb-51a2-43f1-9876-543210fedcba"
    }
  }
}
```

#### Common Linear Issues

**Issue**: UUID validation fails

**Solution**: Ensure UUIDs are lowercase and properly formatted with hyphens in correct positions

**Issue**: Can't find team or board ID

**Solution**: Check Linear Settings or use Linear API with authentication to list teams/boards

---

## Team Namespace

**Namespace**: `team.*`

**Purpose**: Configure team member information and code review assignment strategies.

### Team Fields

#### team.review_strategy

**Type**: `string`

**Required**: No

**Default**: `"list"`

**Valid Values**: `list`, `round-robin`, `query`, `none`

**Description**: Code review assignment strategy that determines how reviewers are selected for pull requests.

**Strategies**:

**`list`** (default):

- Use predefined list of reviewers from `default_reviewers`
- Same reviewers assigned to every PR
- Best for: Small teams with dedicated reviewers

**`round-robin`**:

- Rotate through team members from `members` list
- Distributes review load evenly
- Respects `availability` status
- Best for: Larger teams wanting to distribute reviews

**`query`**:

- Prompt user to select reviewers each time
- Maximum flexibility
- Best for: Ad-hoc review selection, varying expertise needs

**`none`**:

- No automatic reviewer assignment
- Manually assign reviewers after PR creation
- Best for: Teams managing reviews outside AIDA

**Example**:

```json
{
  "team": {
    "review_strategy": "round-robin"
  }
}
```

#### team.default_reviewers

**Type**: `array` of strings

**Required**: No (required when `review_strategy` is `"list"`)

**Items Pattern**: `^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$` or single character

**Description**: List of default reviewer usernames (VCS usernames). Used when `review_strategy` is `"list"`.

**Examples**:

```json
{
  "team": {
    "default_reviewers": ["tech-lead", "senior-dev"]
  }
}
```

```json
{
  "team": {
    "default_reviewers": ["alice", "bob", "carol"]
  }
}
```

**Validation**:

- Must be unique (no duplicates)
- Must be valid VCS usernames
- Must match pattern (alphanumeric + hyphens)

#### team.members

**Type**: `array` of objects

**Required**: No (required when `review_strategy` is `"round-robin"`)

**Description**: List of team members with roles and availability status. Used for round-robin review assignment.

**Member Object Structure**:

Each member must have:

- `username` (string, required) - VCS username
- `role` (string, required) - Team role
- `availability` (string, optional) - Availability status

**Example**:

```json
{
  "team": {
    "members": [
      {
        "username": "alice",
        "role": "tech-lead",
        "availability": "available"
      },
      {
        "username": "bob",
        "role": "developer",
        "availability": "limited"
      },
      {
        "username": "carol",
        "role": "reviewer",
        "availability": "available"
      }
    ]
  }
}
```

##### Member Fields

###### username

**Type**: `string`

**Required**: Yes

**Pattern**: `^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$` or single character

**Description**: Team member's VCS username (GitHub/GitLab/Bitbucket username).

**Example**: `"alice"`, `"bob-smith"`

###### role

**Type**: `string`

**Required**: Yes

**Valid Values**: `developer`, `tech-lead`, `reviewer`

**Description**: Team member's role in the project.

**Roles**:

- `developer` - Regular contributor
- `tech-lead` - Technical lead/architect
- `reviewer` - Dedicated code reviewer

**Example**: `"tech-lead"`

###### availability

**Type**: `string`

**Required**: No

**Default**: `"available"`

**Valid Values**: `available`, `limited`, `unavailable`

**Description**: Team member's availability status for review assignments. Round-robin strategy respects this status.

**Availability Statuses**:

- `available` - Fully available for reviews (default)
- `limited` - Reduced capacity, assign fewer reviews
- `unavailable` - Temporarily unavailable, skip in rotation

**Example**: `"limited"`

### Complete Team Examples

**List Strategy** (small team):

```json
{
  "team": {
    "review_strategy": "list",
    "default_reviewers": ["tech-lead", "senior-dev"]
  }
}
```

**Round-Robin Strategy** (larger team):

```json
{
  "team": {
    "review_strategy": "round-robin",
    "default_reviewers": [],
    "members": [
      {
        "username": "emily-tech-lead",
        "role": "tech-lead",
        "availability": "available"
      },
      {
        "username": "frank-backend",
        "role": "developer",
        "availability": "available"
      },
      {
        "username": "grace-frontend",
        "role": "developer",
        "availability": "limited"
      },
      {
        "username": "henry-reviewer",
        "role": "reviewer",
        "availability": "available"
      }
    ]
  }
}
```

**Query Strategy** (flexible):

```json
{
  "team": {
    "review_strategy": "query"
  }
}
```

**No Strategy** (manual):

```json
{
  "team": {
    "review_strategy": "none"
  }
}
```

---

## Workflow Namespace

**Namespace**: `workflow.*`

**Purpose**: Configure workflow automation behavior for commits, pull requests, and other AIDA-managed workflows.

### Commit Workflow

**Namespace**: `workflow.commit.*`

**Purpose**: Configure git commit automation settings.

#### workflow.commit.auto_commit

**Type**: `boolean`

**Required**: No

**Default**: `true`

**Description**: Automatically commit changes after each task completion. When enabled, AIDA workflows will create commits automatically as tasks are completed.

**Use Cases**:

**`true`** (default):

- Automatic commit after each task
- Clean commit history with task-level granularity
- Recommended for most workflows

**`false`**:

- Manual commit control
- Batch multiple tasks into single commit
- Review changes before committing

**Example**:

```json
{
  "workflow": {
    "commit": {
      "auto_commit": true
    }
  }
}
```

### Pull Request Workflow

**Namespace**: `workflow.pr.*`

**Purpose**: Configure pull request automation settings.

#### workflow.pr.auto_version_bump

**Type**: `boolean`

**Required**: No

**Default**: `true`

**Description**: Automatically bump version in package files when creating PR. AIDA will update version numbers in `package.json`, `pyproject.toml`, or other package manifests.

**Use Cases**:

**`true`** (default):

- Automatic semantic versioning
- Version bumps included in PR
- Recommended for projects with regular releases

**`false`**:

- Manual version control
- Version bumped separately from PR
- Use for non-released packages

**Example**:

```json
{
  "workflow": {
    "pr": {
      "auto_version_bump": true
    }
  }
}
```

#### workflow.pr.update_changelog

**Type**: `boolean`

**Required**: No

**Default**: `true`

**Description**: Automatically update CHANGELOG.md when creating PR. AIDA will add PR summary to changelog in appropriate format.

**Use Cases**:

**`true`** (default):

- Automatic changelog maintenance
- Changelog updated with each PR
- Recommended for projects maintaining changelogs

**`false`**:

- Manual changelog management
- Changelog updated separately
- Use for projects not maintaining changelogs

**Example**:

```json
{
  "workflow": {
    "pr": {
      "update_changelog": false
    }
  }
}
```

#### workflow.pr.draft_by_default

**Type**: `boolean`

**Required**: No

**Default**: `false`

**Description**: Create pull requests as drafts by default. Draft PRs don't trigger CI/CD or request reviews until marked ready.

**Use Cases**:

**`true`**:

- Create PRs early for visibility
- Don't trigger CI or reviews immediately
- Recommended for work-in-progress sharing

**`false`** (default):

- Create ready-for-review PRs
- Trigger CI/CD and request reviews immediately
- Recommended for completed work

**Example**:

```json
{
  "workflow": {
    "pr": {
      "draft_by_default": true
    }
  }
}
```

### Complete Workflow Example

```json
{
  "workflow": {
    "commit": {
      "auto_commit": true
    },
    "pr": {
      "auto_version_bump": true,
      "update_changelog": true,
      "draft_by_default": false
    }
  }
}
```

---

## Complete Configuration Examples

### Minimal Configuration

Bare minimum configuration for GitHub with GitHub Issues:

```json
{
  "config_version": "1.0",
  "vcs": {
    "provider": "github",
    "owner": "my-user",
    "repo": "my-project"
  },
  "work_tracker": {
    "provider": "github_issues"
  }
}
```

**Features**:

- Uses all defaults (main branch, auto-detect enabled, etc.)
- GitHub.com (not enterprise)
- GitHub Issues work tracking
- No team configuration (manual reviewer selection)
- Default workflow settings (auto-commit, version bump, changelog)

### Complete Configuration

Full configuration with all options specified:

```json
{
  "config_version": "1.0",
  "vcs": {
    "provider": "github",
    "owner": "acme-corp",
    "repo": "enterprise-platform",
    "main_branch": "develop",
    "auto_detect": true,
    "github": {
      "enterprise_url": "https://github.acme-corp.com"
    }
  },
  "work_tracker": {
    "provider": "jira",
    "auto_detect": false,
    "jira": {
      "base_url": "https://acme-corp.atlassian.net",
      "project_key": "PLAT"
    }
  },
  "team": {
    "review_strategy": "round-robin",
    "default_reviewers": [],
    "members": [
      {
        "username": "alice-lead",
        "role": "tech-lead",
        "availability": "available"
      },
      {
        "username": "bob-dev",
        "role": "developer",
        "availability": "available"
      },
      {
        "username": "carol-reviewer",
        "role": "reviewer",
        "availability": "limited"
      }
    ]
  },
  "workflow": {
    "commit": {
      "auto_commit": true
    },
    "pr": {
      "auto_version_bump": true,
      "update_changelog": true,
      "draft_by_default": true
    }
  }
}
```

**Features**:

- GitHub Enterprise with custom domain
- Jira work tracking (cross-provider setup)
- Round-robin code reviews with 3-person team
- Auto-commit enabled
- Version bumping and changelog updates
- Draft PRs by default

### Cross-Provider Configuration

GitLab VCS with GitHub Issues work tracking:

```json
{
  "config_version": "1.0",
  "vcs": {
    "provider": "gitlab",
    "owner": "my-group",
    "repo": "my-project",
    "main_branch": "main",
    "gitlab": {
      "project_id": "12345",
      "self_hosted_url": null,
      "group": null
    }
  },
  "work_tracker": {
    "provider": "github_issues",
    "auto_detect": false,
    "github_issues": {
      "enabled": true
    }
  },
  "team": {
    "review_strategy": "list",
    "default_reviewers": ["tech-lead"]
  }
}
```

**Features**:

- GitLab.com for VCS
- GitHub Issues for work tracking (different providers)
- Auto-detect disabled (prevents confusion)
- Simple list-based reviews

### Open Source Project Configuration

Public GitHub repository with query-based reviews:

```json
{
  "config_version": "1.0",
  "vcs": {
    "provider": "github",
    "owner": "oakensoul",
    "repo": "claude-personal-assistant",
    "main_branch": "main",
    "auto_detect": true,
    "github": {
      "enterprise_url": null
    }
  },
  "work_tracker": {
    "provider": "github_issues",
    "auto_detect": true,
    "github_issues": {
      "enabled": true
    }
  },
  "team": {
    "review_strategy": "query"
  },
  "workflow": {
    "commit": {
      "auto_commit": true
    },
    "pr": {
      "auto_version_bump": true,
      "update_changelog": true,
      "draft_by_default": false
    }
  }
}
```

**Features**:

- Public GitHub repository
- Auto-detection enabled
- Query-based reviewer selection (flexible for varied contributors)
- Standard workflow automation

---

## Validation

AIDA uses a three-tier validation system to ensure configuration correctness.

### Three-Tier Validation

#### Tier 1: JSON Syntax Validation

Validates that the configuration file is valid JSON.

**Checks**:

- Well-formed JSON syntax
- Proper bracket/brace matching
- Valid string escaping
- No trailing commas

**Tools**:

```bash
python3 -m json.tool config.json
```

#### Tier 2: JSON Schema Validation

Validates configuration structure against the JSON Schema.

**Checks**:

- Required fields present
- Field types correct (string, boolean, array, etc.)
- Enum values valid
- Patterns matched (URLs, usernames, UUIDs)
- Additional properties not allowed

**Tools**:

```bash
lib/installer-common/validate-config.sh config.json
```

#### Tier 3: Provider-Specific Validation

Validates provider-specific conditional requirements.

**Checks**:

- GitHub: `owner` and `repo` required
- GitLab: `owner`, `repo`, and `gitlab.project_id` required
- Bitbucket: `bitbucket.workspace` and `bitbucket.repo_slug` required
- Jira: `jira.base_url` and `jira.project_key` required
- Linear: `linear.team_id` and `linear.board_id` required

**Tools**:

```bash
lib/installer-common/validate-config.sh --strict config.json
```

### Common Validation Errors

#### Error: Missing required field

**Message**: `"config_version" is required`

**Solution**: Add `config_version` field with value `"1.0"`

#### Error: Invalid pattern

**Message**: `"owner" does not match pattern`

**Solution**: Ensure owner/username doesn't start/end with hyphen or contain special characters

#### Error: Invalid enum value

**Message**: `"provider" must be one of: github, gitlab, bitbucket`

**Solution**: Check spelling and use lowercase provider names

#### Error: Provider mismatch

**Message**: `When provider is "github", fields "owner" and "repo" are required`

**Solution**: Add missing required fields for your selected provider

#### Error: Invalid URL format

**Message**: `"enterprise_url" does not match pattern (must be HTTPS)`

**Solution**: Ensure URL starts with `https://` (not `http://`)

#### Error: Invalid UUID format

**Message**: `"team_id" must be valid UUID`

**Solution**: Verify UUID format (lowercase hex with hyphens in correct positions)

---

## Best Practices

### Security

**Never store secrets in configuration files**:

```json
{
  "WRONG": {
    "github_token": "ghp_secret123",
    "api_key": "sk_live_abc123"
  }
}
```

**Use environment variables instead**:

```bash
export GITHUB_TOKEN="ghp_secret123"
export JIRA_API_TOKEN="abc123"
```

**Set appropriate file permissions**:

```bash
chmod 600 ~/.claude/config.json
chmod 644 .aida/config.json  # Project config is committed
```

**Add user config to .gitignore**:

```gitignore
# In your dotfiles or home directory .gitignore
.claude/config.json
```

### Team Collaboration

**Commit project configuration to git**:

```bash
git add .aida/config.json
git commit -m "feat: add AIDA project configuration"
```

**Don't commit user configuration**:

```bash
# .gitignore
.claude/
```

**Document team-specific settings**:

```markdown
# Project README

## AIDA Configuration

This project uses round-robin code reviews. See `.aida/config.json` for team member list.
```

**Use consistent review strategy**:

- Small teams (2-3): Use `list` strategy with static reviewers
- Medium teams (4-8): Use `round-robin` for even distribution
- Large teams (9+): Use `query` or domain-specific reviewer groups

### Configuration Management

**Start with templates**:

```bash
cp templates/config/config-github-simple.json .aida/config.json
```

**Validate before committing**:

```bash
lib/installer-common/validate-config.sh .aida/config.json
```

**Document deviations from defaults**:

```json
{
  "workflow": {
    "pr": {
      "draft_by_default": true,
      "_comment": "We create draft PRs to prevent premature CI runs"
    }
  }
}
```

**Note**: `_comment` fields are ignored by validation and can be used for documentation.

### Version Control

**Update config with project changes**:

- Change main branch: Update `vcs.main_branch`
- Team member leaves: Update `team.members` availability to `unavailable`
- Migration to enterprise: Update provider-specific URLs

**Track configuration history**:

```bash
git log -- .aida/config.json
```

**Test configuration changes**:

```bash
# Validate before committing
lib/installer-common/validate-config.sh .aida/config.json

# Test with dry-run (when available)
aida validate-config --verbose
```

---

## Related Documentation

**Configuration System**:

- [Security Model](security-model.md) - Configuration security, secrets management, file permissions
- [Migration Guide](../migration/v0-to-v1-config.md) - Migrating from legacy configuration format
- [Provider Integration](../integration/vcs-providers.md) - VCS provider setup and API details

**Template Files**:

- [Configuration Templates](../../templates/config/README.md) - Pre-built configuration examples
- [JSON Schema](../../lib/installer-common/config-schema.json) - Complete schema definition

**Workflow Documentation**:

- [Workflow Commands](../workflows/README.md) - Using AIDA workflow commands
- [Team Setup](../team/setup.md) - Configuring team members and reviews

---

## Summary

This schema reference documents AIDA's configuration system with:

- **4 namespaces**: VCS, work tracker, team, workflow
- **3 VCS providers**: GitHub, GitLab, Bitbucket
- **4 work trackers**: GitHub Issues, Jira, Linear, none
- **4 review strategies**: List, round-robin, query, none
- **35+ configuration fields** with types, patterns, and examples
- **3-tier validation** for correctness and safety
- **Security best practices** for production use

For hands-on examples, see the [configuration templates](../../templates/config/README.md).

For migration from legacy configs, see the [migration guide](../migration/v0-to-v1-config.md).
