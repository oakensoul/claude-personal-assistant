---
title: "AIDA Configuration Templates"
description: "Template configuration files for various VCS and work tracker combinations"
category: "reference"
tags: ["configuration", "templates", "vcs", "work-tracker"]
last_updated: "2025-10-20"
status: "published"
audience: "developers"
---

# AIDA Configuration Templates

This directory contains template configuration files for common AIDA workflow scenarios.

## Available Templates

### 1. `config.json.template` - Generic Template

**Purpose**: Complete template showing all available configuration options with placeholders and inline documentation.

**Use case**: Creating custom configurations or understanding all available options.

**Features**:

- All four namespaces (vcs, work_tracker, team, workflow)
- Clear `{{PLACEHOLDER}}` markers for required values
- Inline comments with `_comment` and `_description` fields
- Shows all provider-specific options

### 2. `config-github-simple.json` - Minimal GitHub Setup

**Purpose**: Simple GitHub repository with GitHub Issues work tracking.

**Use case**: Individual developers or small teams using GitHub for everything.

**Features**:

- GitHub VCS (github.com, not enterprise)
- GitHub Issues work tracker
- List-based reviewer strategy (static list of reviewers)
- Minimal required configuration

**Example values**:

- Owner: `example-user`
- Repo: `my-project`
- Reviewers: `tech-lead`, `senior-dev`

### 3. `config-github-enterprise.json` - GitHub Enterprise

**Purpose**: GitHub Enterprise deployment with team-based round-robin reviews.

**Use case**: Organizations using GitHub Enterprise with multiple team members.

**Features**:

- GitHub Enterprise (custom domain)
- GitHub Issues work tracker
- Round-robin review strategy (rotates through team members)
- Full team member configuration with roles and availability

**Example values**:

- Enterprise URL: `https://github.acme-corp.com`
- Owner: `acme-corp`
- Repo: `enterprise-platform`
- Team: 4 members with different roles and availability

### 4. `config-gitlab-jira.json` - GitLab + Jira Integration

**Purpose**: GitLab VCS with Jira work tracking (self-hosted GitLab).

**Use case**: Organizations using GitLab for code and Jira for issue tracking.

**Features**:

- GitLab VCS (self-hosted)
- Jira work tracker integration
- Round-robin review strategy
- Full team member configuration
- Draft PRs by default

**Example values**:

- GitLab URL: `https://gitlab.company.io`
- Project ID: `engineering-team/api-platform`
- Jira URL: `https://company.atlassian.net`
- Jira Project: `API`

### 5. `config-bitbucket.json` - Bitbucket Configuration

**Purpose**: Bitbucket VCS with query-based reviewer selection.

**Use case**: Teams using Bitbucket who prefer to select reviewers manually.

**Features**:

- Bitbucket VCS (workspace-based)
- GitHub Issues work tracker (cross-provider example)
- Query review strategy (prompts for reviewers)
- Minimal team configuration

**Example values**:

- Workspace: `startup-company`
- Repo slug: `web-application`

## Schema Compliance

All templates validate against the JSON Schema defined in:

`/Users/rob/Develop/oakensoul/claude-personal-assistant/lib/installer-common/config-schema.json`

## Using Templates

### Option 1: Copy and Customize

```bash
# Copy template to your project
cp templates/config/config-github-simple.json .claude/config.yml

# Edit with your values
vim .claude/config.yml
```

### Option 2: Use Installer (when available)

The AIDA installer will offer template selection during interactive setup.

### Option 3: Manual Creation

Use `config.json.template` as a reference and create your own:

1. Start with the generic template
2. Replace all `{{PLACEHOLDERS}}` with actual values
3. Remove unused provider sections
4. Remove `_comment` and `_description` fields (optional)
5. Validate against schema (Task 1.3 will provide validation tools)

## Template Design Notes

### Placeholder Convention

- Install-time variables use `{{DOUBLE_BRACES}}`
- Runtime variables use `${SINGLE_BRACES}`

### Comment Fields

Templates include `_comment` and `_description` fields for documentation. These are not part of the schema and can be removed from production configs.

### Provider-Specific Fields

Each template only populates fields relevant to the selected provider:

- **GitHub**: Uses `owner`, `repo`, optional `enterprise_url`
- **GitLab**: Uses `owner`, `repo`, required `project_id`, optional `self_hosted_url`
- **Bitbucket**: Uses `workspace`, `repo_slug` (not `owner`/`repo`)

### Review Strategies

**list** - Use predefined list of reviewers (simple, consistent)

**round-robin** - Rotate through team members (distributes load)

**query** - Prompt user each time (maximum flexibility)

**none** - No automatic reviewer assignment

## Validation

Validation tools will be provided in Task 1.3. Until then, verify:

1. JSON syntax is valid (`python3 -m json.tool file.json`)
2. Required fields are present for your provider
3. Values match pattern requirements (URLs, usernames, etc.)

## Related Files

- JSON Schema: `/Users/rob/Develop/oakensoul/claude-personal-assistant/lib/installer-common/config-schema.json`
- Validation script: (Task 1.3 - not yet created)
- Installer integration: (Future task)

## Contributing

When adding new templates:

1. Validate against schema
2. Use realistic example values (not real secrets)
3. Include inline documentation
4. Update this README
5. Test with validation script (when available)
