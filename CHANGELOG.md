# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.4] - 2025-10-10

### Added

- 23 new command templates for comprehensive workflow coverage:
  - Quality assurance: code-review, script-audit, config-validate, ux-review, qa-check, test-plan
  - Security & compliance: security-audit, compliance-check, pii-scan
  - Operations: incident, debug, runbook
  - Infrastructure: aws-review, github-init, github-sync
  - Data & analytics: metric-audit, optimize-warehouse, cost-review, sla-report
- 11 new agent templates with comprehensive knowledge bases:
  - aws-cloud-engineer: AWS service expertise and CDK patterns
  - datadog-observability-engineer: Monitoring and observability
  - cost-optimization-agent: Snowflake cost analysis
  - data-governance-agent: Data compliance and privacy
  - security-engineer: Security and threat modeling
  - configuration-specialist, integration-specialist, privacy-security-auditor, qa-engineer, shell-script-specialist, shell-systems-ux-designer
- Two-tier agent architecture documentation in .claude/agents-global/README.md
- 7 v0.1.0 milestone issues published (#44-#50) defining command consolidation plan

### Changed

- Reorganized agents to two-tier architecture:
  - Global agents moved to .claude/agents-global/ with project-specific context
  - Product-manager and tech-lead converted to two-tier structure
  - AIDA framework agents now use global templates
- Updated templates/commands/README.md to document all 32 current commands
- Archived published v0.1.0 issue drafts to .github/issues/published/v0.1/

### Documentation

- Added categorization of 32 commands by function (quality, security, operations, etc.)
- Added note about v0.1.0 command consolidation plan
- Linked to GitHub milestone 16 for consolidation details

## [0.1.3] - 2025-10-07

### Added

- Workflow command templates with variable substitution system
- Four core workflow commands now available as templates:
  - `cleanup-main.md`: Post-PR merge cleanup with stash restoration
  - `implement.md`: Implementation orchestration with task breakdown
  - `open-pr.md`: PR creation with automated checks and file exclusion
  - `start-work.md`: Issue workflow initialization with branch setup
- Template variable validation in `scripts/validate-templates.sh`
- Command template installation function in `install.sh` with:
  - Sed-based variable substitution ({{VAR}} → actual values)
  - Timestamped backups of existing commands
  - Dev mode support with symlinks for live editing
  - Permission enforcement (600 for installed commands)

### Changed

- Workflow state tracking updated to reflect issue #39

### Fixed

- All markdown linting errors in command templates (MD031, MD040, MD007, MD032, MD038)

## [0.1.2] - 2025-10-07

Previous releases...
