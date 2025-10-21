---
title: "Changelog"
description: "Version history and release notes for AIDA framework"
category: "meta"
tags: ["changelog", "releases", "versions", "history"]
last_updated: "2025-10-21"
status: "published"
audience: "developers"
---

# Changelog

All notable changes to the AIDA framework will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2025-10-21

### Added

#### Configuration System (Issue #55)

- **VCS Provider Abstraction**: Complete provider abstraction system supporting GitHub, GitLab, and Bitbucket
  - Auto-detection from git remote URLs with confidence scoring (high/medium/low)
  - Provider-specific configuration under unified `vcs.*` namespace
  - Extensible architecture for adding new VCS providers

- **Three-Tier Validation Framework**:
  - **Tier 1**: JSON Schema validation (structure, types, required fields)
  - **Tier 2**: Provider-specific rules validation
  - **Tier 3**: Connectivity validation stub (opt-in with `--verify-connection`)
  - User-friendly error messages with auto-detected fix suggestions

- **Safe Configuration Migration**:
  - Automatic migration from schema v1.0 → v2.0
  - Backup before migration with timestamped files
  - Automatic rollback on validation failure
  - Data integrity verification (no data loss)
  - Dry-run mode for testing migrations
  - Migration report generation

- **New Configuration Namespaces**:
  - `vcs.*` - Version control configuration (replaces `github.*`)
  - `work_tracker.*` - Issue tracking system configuration
  - `team.*` - Team configuration (reviewers, members, timezone)
  - Config version tracking for migration management

- **Security Enhancements**:
  - Config files have 600 permissions (owner read/write only)
  - Automatic .gitignore entries for config.json and backups
  - Pre-commit hook for secret detection in config files
  - Secrets validated against GitHub, Jira, Linear, Anthropic, AWS patterns

- **Core Libraries** (6 new files, 6,500+ lines):
  - `lib/installer-common/config-schema.json` (2,800 lines) - JSON Schema Draft-07
  - `lib/installer-common/vcs-detector.sh` (547 lines) - VCS auto-detection
  - `lib/installer-common/config-validator.sh` (1,449 lines) - 3-tier validation
  - `lib/installer-common/config-migration.sh` (1,223 lines) - Safe migration
  - `lib/installer-common/error-templates.sh` (389 lines) - User-friendly errors
  - `scripts/validate-config-security.sh` - Pre-commit secret detection

- **Configuration Templates** (5 templates):
  - Generic template with all options
  - Simple GitHub configuration
  - GitHub Enterprise configuration
  - GitLab + Jira cross-provider example
  - Bitbucket configuration

- **Comprehensive Documentation** (4 guides, 5,600+ lines):
  - Schema reference (1,738 lines) - Complete field documentation
  - Security model (1,700 lines) - Best practices and incident response
  - VCS provider integration guide (1,550 lines) - Adding new providers
  - Migration guide (400+ lines) - v1.0 → v2.0 migration

- **Test Suite** (198 unit + 60+ integration tests, 100% passing):
  - 75 VCS detection tests (GitHub, GitLab, Bitbucket)
  - 94 validation tests (3-tier framework)
  - 29 migration tests (workflow, rollback, idempotency)
  - 7 integration scenarios (end-to-end workflows)
  - Cross-platform CI/CD (macOS BSD + Linux GNU)

### Changed

- **Config File Location**: Renamed `~/.claude/aida-config.json` → `~/.claude/config.json`
- **Config Helper Integration**: Updated `lib/aida-config-helper.sh` with auto-migration and VCS detection
- **Installer Updates**: Added migration check, security permissions, and .gitignore management
- **Pre-commit Hooks**: Added config security validation hook

### Breaking Changes

- **GitHub Namespace**: `github.*` → `vcs.github.*` (auto-migrated)
- **Reviewers Location**: `workflow.pull_requests.reviewers` → `team.default_reviewers` (auto-migrated)
- **Config Version**: Now requires `config_version: "2.0"` field

### Migration

All changes include automatic migration support:

- Migration runs automatically on install/upgrade
- Backward compatible until v0.4.0
- Safe migration with backup and rollback
- See `docs/migration/config-v1-to-v2.md` for details

### Deprecation Timeline

- **v0.2.0**: Auto-migration introduced (backward compatible)
- **v0.3.0**: Old schema deprecated (warnings shown)
- **v0.4.0**: Old schema removed (migration required)

## [0.1.2] - 2025-10-07

### Added

#### Template System

- **Command Templates**: Archived 8 core commands to `templates/commands/` with runtime variable substitution:
  - create-agent, create-command, create-issue, expert-analysis
  - generate-docs, publish-issue, track-time, workflow-init
  - All hardcoded paths replaced with `${CLAUDE_CONFIG_DIR}`, `${PROJECT_ROOT}`, `${AIDA_HOME}`

- **Agent Templates**: Archived 6 core agents to `templates/agents/` with knowledge structures:
  - claude-agent-manager, code-reviewer, devops-engineer
  - product-manager, tech-lead, technical-writer
  - Each includes knowledge directory with privacy-safe placeholders (core-concepts/, patterns/, decisions/)

- **Privacy Validation Infrastructure**:
  - `scripts/validate-templates.sh` - Comprehensive privacy validation script
  - Pre-commit hook for automated template privacy checking
  - Detects hardcoded paths, usernames, credentials, email addresses
  - CI/CD integration with proper exit codes

### Documentation

- **Template Documentation**: Comprehensive README files (56KB total):
  - `templates/README.md` (16KB) - Template system overview, runtime variables, installation flow
  - `templates/commands/README.md` (15KB) - All 8 commands documented with examples
  - `templates/agents/README.md` (25KB) - All 6 agents, two-tier knowledge system explained
  - `scripts/README.md` (4.8KB) - Privacy validation script usage

- **Expert Analysis Documentation**: Added documentation for `/expert-analysis` command workflow

### Changed

- **CI/CD**: Added template privacy validation to pre-commit hooks
- **Workflow**: Added context cleanup option to `/cleanup-main` command
- **Cleanup**: Removed extraneous template file, maintained consistent structure

### Technical Details

- **Runtime Variable Resolution**: Templates use `${VAR}` syntax, resolved by Claude at runtime (no .template extensions)
- **Privacy-Safe**: All templates pass comprehensive privacy validation
- **Quality**: All markdown files pass linting, shellcheck passes with zero warnings
- **Structure**: Templates mirror `~/.claude/` installation structure

## [0.1.1] - 2025-10-05

### Added

#### Installation & Testing

- **Installation Script** (`install.sh`): Complete foundational installation script with:
  - Interactive assistant name and personality selection
  - Comprehensive input validation (3-20 chars, lowercase, no spaces)
  - Directory structure creation (`~/.aida/`, `~/.claude/`)
  - Development mode support (`--dev` flag with symlinks)
  - Automatic backup of existing installations
  - Idempotent design (safe to run multiple times)
  - Full dependency validation (Bash >= 4.0, git, rsync, etc.)
  - Passes shellcheck with zero warnings

- **Testing Infrastructure**: Comprehensive cross-platform testing:
  - 4 Docker test environments (Ubuntu 22.04, Ubuntu 20.04, Debian 12, minimal)
  - Automated test runner (`.github/testing/test-install.sh`)
  - GitHub Actions CI/CD workflow for automated testing
  - Platform-specific guides (WSL, Git Bash, Docker)
  - Test scenarios documentation with 10+ comprehensive tests
  - Test results: 11 passed, 0 failed, 5 skipped (expected)

- **Documentation**: Comprehensive testing and platform guides:
  - WSL setup and testing guide
  - Git Bash setup and testing guide
  - Test scenarios with validation checklist
  - Docker testing infrastructure README

### Changed

- **CI/CD**: Enhanced pre-commit hooks to match GitHub Actions:
  - Added `--strict` flag to yamllint (warnings now fail locally like in CI)
  - Ensures local validation exactly matches CI validation

- **Workflow Configuration**: Enhanced reviewer strategies:
  - Added 5 reviewer strategies (none, query, list, round-robin, auto)
  - Support for GitHub Copilot as reviewer (`github-copilot[bot]`)
  - Added `--reviewers` parameter to `/open-pr` for per-PR overrides
  - Created comprehensive schema documentation

### Fixed

- **YAML Linting**: Removed `---` document-start marker from docker-compose.yml
- **Pre-commit**: Fixed strict mode mismatch between local and CI validation

### Infrastructure

- **Cross-Platform Support**: Validated on macOS, Ubuntu 22.04/20.04, Debian 12, WSL2
- **CI/CD**: Automated testing on every push and PR
- **Quality Gates**: Pre-commit hooks with strict mode enforcement

## [0.1.0] - 2025-10-04

### Added

#### Agents & Framework

- **AIDA Product Manager Agent**: Comprehensive product management capabilities including product strategy, roadmap planning, market analysis, and stakeholder management
- **Technical Writer Agent**: Template for documentation-focused agent definitions
- **Project-Specific Development Agents**: Six specialized agents for AIDA framework development:
  - Shell Script Specialist: Bash scripting, install scripts, CLI tools
  - Shell Systems UX Designer: UX for shell interactions and prompts
  - Privacy & Security Auditor: Security review, secrets, privacy
  - Configuration Specialist: YAML configs, personalities, templates
  - Integration Specialist: Obsidian, dotfiles, MCP integration
  - QA Engineer: Testing strategies, validation, QA
- **Knowledge Base Structure**: Created knowledge folder structures for all agents with core-concepts, patterns, decisions subdirectories, and index files

#### Infrastructure & Tooling

- **Linting Infrastructure**: Pre-commit hooks and GitHub Actions CI/CD for yamllint, shellcheck, markdownlint, and gitleaks
- **Secret Detection**: Integrated gitleaks for credential and secret scanning in codebase
- **Configuration Files**: Added linting rules (.yamllint, .shellcheckrc, .markdownlint.json)
- **GitHub Issue Forms**: Templates for bugs, defects, features, and questions with proper labeling
- **Pull Request Template**: Standardized PR description format
- **GitHub Issues Infrastructure**: Directory structure for issue management with README and in-progress tracking

#### Documentation

- **Linting Setup Guide**: Comprehensive documentation for installation, usage, and troubleshooting
- **Project Board Setup**: Documentation for GitHub Projects workflow, custom fields, and automation
- **Personality Builder Requirements**: Complete feature specification including user stories, schema, validation, workflow, testing, and implementation phases
- **Issue Definitions**: 30 comprehensive issue definitions organized by milestone (v0.1.0 to v1.0.0) with acceptance criteria, implementation notes, and dependency graph

### Changed

- **Project Rename**: Changed from AIDE (Agentic Intelligence & Digital Environment) to AIDA (Agentic Intelligence Digital Assistant) across all documentation
- **Installation Paths**: Updated from `~/.aide/` to `~/.aida/` throughout documentation
- **Gitignore Configuration**: Modified `.claude/` pattern to allow project-specific agents while excluding user settings
  - Excluded: `.claude/settings.local.json`, `.claude/workflow-config.json`
  - Allowed: `.claude/agents/` for project development agents
- **Issue Creation**: Disabled blank GitHub issues (web UI uses forms only)

### Infrastructure

- **CI/CD**: All pull requests now automatically validated against linting rules
- **Quality Gates**: Pre-commit hooks enforce code quality before commits
- **Issue Management**: Standardized issue creation and tracking workflow
- **Time Tracking**: Added `.time-tracking/*.md` to gitignore for local time logs
- **Security**: Automated secret detection prevents credential leaks

### Project Milestones

- Total estimated effort: 350-400 hours across 6 milestones
- v0.1.0 issues (#16-#30) created in GitHub
- Foundation established for milestone-driven development

[0.1.0]: https://github.com/oakensoul/claude-personal-assistant/releases/tag/v0.1.0
