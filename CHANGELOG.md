# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
