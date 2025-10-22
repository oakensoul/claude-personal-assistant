# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.7] - 2025-10-20

### Added

- **Scripts Installation Fix**:
  - Scripts now install to `~/.claude/scripts/.aida/` following namespace pattern
  - Consistent with commands, agents, skills installation structure
  - Dev mode uses symlinks, normal mode copies files
- **Pre-commit Setup**:
  - Added pre-commit installation instructions to CONTRIBUTING.md
  - Documented Homebrew (macOS) and pip (Linux) installation methods
  - Fixed markdown linting issues across all templates
- **Discoverability Commands** (Issue #54):
  - `/command-list` - List all available commands with category filtering
  - `/agent-list` - List all available agents
  - `/skill-list` - List all available skills
  - **Configuration Migration**: All 29 commands now have category and version frontmatter
  - **Category Taxonomy**: Finalized 6 active categories (analysis, workflow, meta, project, testing, documentation)
  - **Installer Integration**: Discovery scripts configured and made executable during installation
  - **Component Counts**: Installer displays installed agents, skills, and commands using discovery scripts
- **CLI Scripts** (`~/.claude/scripts/.aida/`):
  - `list-commands.sh` - Text and JSON output, category filtering
  - `list-agents.sh` - Text and JSON output
  - `list-skills.sh` - Placeholder for future implementation
- **Shared Libraries** (`~/.claude/scripts/.aida/lib/`):
  - `frontmatter-parser.sh` - Parse YAML frontmatter from markdown
  - `json-formatter.sh` - Format output as valid JSON
  - `path-sanitizer.sh` - Privacy-aware path sanitization
  - `readlink-portable.sh` - Cross-platform symlink resolution
- **Architecture Decision Record**:
  - ADR-003: Rename agents-global to project/context
- **Migration System**:
  - Automatic migration from `.claude/agents-global/` to `.claude/project/context/`
  - `lib/installer-common/migrations.sh` module
  - Backward compatibility for v0.1.x installations

### Changed

- **BREAKING**: Directory structure renamed for clarity:
  - `.claude/agents-global/` → `.claude/project/context/`
  - Rationale: "agents-global" was semantically incorrect (implied global scope for project-specific content)
  - Migration: Automatic via installer, manual: `mv .claude/agents-global .claude/project/context`
  - See [ADR-003](docs/architecture/decisions/adr-003-rename-agents-global-to-project-agents.md) for details

### Fixed

- `list-agents.sh` now correctly filters out:
  - Knowledge base files (`*/knowledge/*`)
  - README documentation files
  - Project configuration files (files with `project:` frontmatter)
- Empty array handling in JSON output (macOS compatibility)
- Cross-platform compatibility (`head -n -0` issue on macOS)

### Documentation

- Updated ADR-002 with new directory paths
- Added migration guide for v0.1.x → v0.2.0
- Updated all template references (41 files, 181 occurrences)

## [0.1.6] - 2025-10-18

### Added

- **ADR-010: Command Structure Refactoring** - Complete redesign of 70 commands with:
  - Workflow-oriented naming (issue/repository/ssh prefixes)
  - Noun-verb convention (/agent-create not /create-agent)
  - 13-step issue workflow with trust-building granularity
  - 11 repository management commands (VCS-agnostic)
  - 6 SSH key management commands with security-first design
  - Progress management: checkpoint, pause, resume workflows
  - Automation modes: autopilot, yolo for high-trust scenarios
- **Architecture Decision Records** (5 ADRs):
  - ADR-002: Two-Tier Agent Architecture (global vs project)
  - ADR-006: Analyst/Engineer Agent Pattern (separation of concerns)
  - ADR-007: Product/Platform/API Engineering Model (team structure)
  - ADR-008: Engineers Own Testing Philosophy (no separate QA team)
  - ADR-009: Skills System Architecture (knowledge management)
- **Skills System** - 177 reusable knowledge modules across 28 categories:
  - Testing: pytest, jest, rspec, playwright, cypress patterns
  - Infrastructure: terraform, kubernetes, docker, observability
  - Data: dbt, airflow, data-quality, dimensional-modeling
  - Cloud: aws-services, gcp-services, azure-services
  - Security: encryption, access-control, threat-modeling
  - Compliance: GDPR, HIPAA, PCI-DSS, SOC2
  - Analytics: metabase, looker, tableau, powerbi
  - Business: saas-metrics, product-metrics, financial-metrics
  - 20 additional categories
- **New Agent Templates** (4):
  - data-engineer: Data pipeline orchestration, dbt, ELT, data quality
  - metabase-engineer: BI platform, YAML specs, API operations, visualization
  - sql-expert: Query optimization, platform-specific best practices
  - system-architect: Architecture patterns, ADRs, C4 models, system design
- **Architecture Documentation**:
  - C4 system context diagram for AIDA framework
  - Agent interaction patterns and coordination workflows
  - Agent migration plan for new structure
  - Skills catalog with complete reference
  - Skills guide for using knowledge modules
- **VCS Provider Configuration System**:
  - Auto-detection from git remote (GitHub/GitLab/Bitbucket)
  - Quick setup modes: /aida-init [provider]
  - Configuration hierarchy (project > user)
  - Support for any VCS/work tracker combination
- **system-architect agent** installed globally for architecture reviews

### Changed

- Reorganized commands per ADR-008 (Engineers Own Testing):
  - Removed specialist commands: config-validate, integration-check, qa-check, ux-review
  - Validation now part of analyst workflows
  - Engineers own quality, no separate QA team
- Updated agent templates for ADR alignment:
  - aws-cloud-engineer: Enhanced two-tier architecture documentation
  - datadog-observability-engineer: Updated proactive behavior patterns
- install-agent command added for installing global agent templates to projects

### Documentation

- Complete command reference (70 commands) with categories and examples
- Trust-building philosophy: "Granularity builds trust" - baby steps for AI adoption
- Dopamine gamification through multiple workflow checkpoints
- Repository management vs GitHub integration distinction
- SSH key security philosophy and pain points addressed
- VCS provider configuration best practices

## [0.1.5] - 2025-10-15

### Fixed

- workflow-init command now creates agents in correct `.claude/project/context/` directory (not `.claude/agents/`)
- workflow-init now creates `index.md` files (not `instructions.md`) for two-tier architecture
- publish-issue command updated to move (not delete) published drafts to `.github/issues/published/`

### Documentation

- Added "Directory Safety" best practice to command writing guidelines
- Added best practices section to implement command documenting directory safety
- Updated commands README with directory safety guidelines

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
- Two-tier agent architecture documentation in .claude/project/context/README.md
- 7 v0.1.0 milestone issues published (#44-#50) defining command consolidation plan

### Changed

- Reorganized agents to two-tier architecture:
  - Global agents moved to .claude/project/context/ with project-specific context
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
