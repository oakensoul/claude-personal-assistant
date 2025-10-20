---
title: "Product Requirements Document - Modular Installer Refactoring"
issue: 53
document_type: "PRD"
created: "2025-10-18"
version: "1.0"
status: "draft"
---

# Product Requirements Document

## Issue #53: Modular Installer with Deprecation Support

## Executive Summary

Refactor AIDA's monolithic 625-line installer into modular, reusable components with namespace isolation, version-based deprecation, and cross-platform testing. This enables safe backward-compatible command renames, preserves user customizations, and supports dotfiles repo integration.

**Value**: Foundation for ADR-010 command migration, enables bi-directional integration with dotfiles repo, prevents user data loss during updates.

**Approach**: `.aida/` namespace isolation + modular `lib/installer-common/` libraries + universal config aggregator + comprehensive testing infrastructure.

---

## Architecture Decision Records

This work is governed by three foundational Architecture Decision Records:

- **[ADR-011: Modular Installer Architecture](../../docs/architecture/decisions/adr-011-modular-installer-architecture.md)** - Modular, reusable installer components
- **[ADR-012: Universal Config Aggregator Pattern](../../docs/architecture/decisions/adr-012-universal-config-aggregator-pattern.md)** - Single source of truth for all configuration
- **[ADR-013: Namespace Isolation for User Content Protection](../../docs/architecture/decisions/adr-013-namespace-isolation-user-content-protection.md)** - Zero data loss guarantee

For implementation details, see [TECH_SPEC.md](./TECH_SPEC.md) and [Architecture Summary](./architecture/ARCHITECTURE_SUMMARY.md).

---

## Stakeholder Analysis

### 1. End Users (AIDA Installers)

**Concerns**:

- 🚨 **CRITICAL**: Current installer destroys custom commands/agents/skills
- Data loss risk when running `./install.sh` multiple times
- No warning before overwriting existing installations
- Unclear what happens during re-installation

**Priorities**:

- Safe, idempotent installation (can re-run without data loss)
- Clear feedback about what will be modified
- Easy recovery from installation errors

**Recommendations**:

- `.aida/` namespace protects user content (separate from `.aida-deprecated/`)
- Confirmation prompts before destructive operations
- Pre-flight installation plan showing what changes
- Progress indicators for long-running operations

### 2. Dotfiles Repo Maintainers

**Concerns**:

- Need to reuse AIDA installation logic without code duplication
- Installation order dependencies (AIDA first vs dotfiles first)
- API stability for `lib/installer-common/` modules
- Version compatibility across repos

**Priorities**:

- Stable API contract for library functions
- Conditional integration (works with or without AIDA)
- Version checking to ensure compatibility

**Recommendations**:

- All logic in reusable `lib/installer-common/` modules
- `install.sh` becomes thin ~150-line orchestrator
- Semantic versioning for library API
- Graceful degradation if AIDA not installed

### 3. Framework Developers

**Concerns**:

- Maintainability of 625-line monolith
- Cross-platform testing (Linux/macOS/Windows)
- Managing command/agent/skill deprecation
- CI/CD validation before PRs merge

**Priorities**:

- Modular, testable code
- Automated testing across platforms
- Clear deprecation lifecycle

**Recommendations**:

- 6 focused modules (templates.sh, deprecation.sh, variables.sh, prompts.sh, directories.sh, summary.sh)
- Docker + Makefile + GitHub Actions testing
- Frontmatter-based deprecation schema

### 4. Claude Code Integration

**Concerns**:

- Templates must be discoverable in `~/.claude/` (NOT `~/.aida/`)
- Variable substitution timing affects path references
- Frontmatter requirements for command metadata

**Priorities**:

- Templates installed to correct locations
- Variables properly substituted before Claude Code reads them

**Recommendations**:

- Install templates to `~/.claude/{commands,agents,skills}/.aida/`
- Normal mode: Copy with variable substitution
- Dev mode: Symlink for live editing

---

## Requirements

### Functional Requirements

#### Core Installation

- **FR-1**: Install AIDA templates into `.aida/` namespace within `~/.claude/`
  - `~/.claude/commands/.aida/` - AIDA commands
  - `~/.claude/agents/.aida/` - AIDA agents
  - `~/.claude/skills/.aida/` - AIDA skills
  - User content in parent directories (preserved)

- **FR-2**: Always symlink `~/.aida/` to repository (both dev and normal mode)
  - Enables `git pull` to update framework
  - Reduces disk space usage
  - Simplifies update workflow

- **FR-3**: Installation modes determine template handling
  - **Normal mode**: Copy templates as-is (no substitution)
  - **Dev mode**: Symlink templates for live editing
  - Templates stay pure in both modes

- **FR-4**: Universal config aggregator for all AIDA configuration
  - **Single source of truth**: Merges 7 config sources (AIDA, workflow, GitHub, Git, env)
  - **7-tier priority resolution**: Environment → Project → Workflow → GitHub → Git → User → System
  - **Session caching**: Checksum-based invalidation for performance
  - **Runtime variable resolution**: Templates use `aida-config-helper.sh` to resolve paths
  - **85%+ I/O reduction**: All workflow commands use aggregator (no duplicate file reads)
  - **Cross-command consistency**: All commands read identical config values
  - **Skill-based access**: `aida-config` skill provides helper functions for agents

#### Modular Architecture

- **FR-5**: Extract installer logic into reusable `lib/installer-common/` modules
  - `templates.sh` - Template installation logic (no variable substitution)
  - `deprecation.sh` - Version comparison, deprecation management
  - `config.sh` - Config reader/writer (wraps aida-config-helper.sh)
  - `prompts.sh` - User interaction
  - `directories.sh` - Directory management
  - `summary.sh` - Installation summary

- **FR-6**: `install.sh` becomes thin orchestrator (~150 lines)
  - Sources modules
  - Orchestrates installation flow
  - No business logic embedded

- **FR-7**: Modules accept parameters (not just globals) for reusability
  - Functions can be called from external scripts
  - No hardcoded paths assuming repo root
  - No assumptions about `$PWD`

#### Deprecation System

- **FR-8**: Support `--with-deprecated` flag to install deprecated templates
  - Installs to `~/.claude/{commands,agents,skills}/.aida-deprecated/`
  - Default: Do NOT install deprecated templates

- **FR-9**: Deprecation metadata in template frontmatter

  ```yaml
  deprecated: true
  deprecated_in: "0.2.0"
  remove_in: "0.4.0"
  canonical: "issue-create"
  reason: "Renamed to noun-verb convention"
  ```

- **FR-10**: Automated cleanup script removes deprecated items based on version
  - Reads `VERSION` file
  - Scans `templates/*-deprecated/` folders
  - Removes items where `current_version >= remove_in`

#### Cross-Platform Testing

- **FR-11**: Docker testing environment for clean installations
  - Linux/Ubuntu Dockerfile
  - Windows Dockerfile (PowerShell + bash)
  - Test fixtures for upgrade scenarios

- **FR-12**: Makefile with test targets
  - `make test-install` - Normal mode
  - `make test-install-dev` - Dev mode
  - `make test-install-deprecated` - With deprecated
  - `make test-upgrade` - Upgrade over existing
  - `make test-user-content` - User content preservation
  - `make test-all` - Full suite

- **FR-13**: GitHub Actions CI/CD workflow
  - Test on Ubuntu, macOS, Windows
  - Matrix: platforms × modes (normal/dev/deprecated)
  - Report test results in PR comments

#### Dotfiles Integration

- **FR-14**: Stable API for `lib/installer-common/` modules
  - Semantic versioning (MAJOR.MINOR.PATCH)
  - Version checking function
  - Breaking changes only in major versions

- **FR-15**: Libraries can be sourced from `~/.aida/lib/installer-common/`
  - Dotfiles repo sources modules conditionally
  - Graceful fallback if AIDA not installed
  - No coupling between repos

### Non-Functional Requirements

#### Safety & Idempotency

- **NFR-1**: Idempotent installation (safe to re-run)
  - Re-running installer doesn't destroy data
  - `.aida/` namespace can be nuked and reinstalled
  - User content in parent directories preserved

- **NFR-2**: User confirmation before destructive operations
  - Warn before overwriting existing installations
  - Show pre-flight installation plan
  - Safe defaults (default to NO on overwrites)

#### User Experience

- **NFR-3**: Clear progress feedback
  - Spinner/progress for long operations
  - Step-by-step messages
  - Estimated time remaining (if possible)

- **NFR-4**: Helpful error messages with recovery guidance
  - Explain why error occurred
  - Suggest next steps
  - Link to troubleshooting docs

- **NFR-5**: Comprehensive help documentation
  - `./install.sh --help` explains all flags
  - In-terminal guidance during prompts
  - Error recovery instructions

#### Maintainability

- **NFR-6**: Modular, testable code
  - Each module has single responsibility
  - Functions can be unit tested independently
  - Clear module dependencies

- **NFR-7**: Cross-platform compatibility
  - Bash 3.2+ (macOS compatibility)
  - Works on Linux, macOS, Windows (WSL/PowerShell)
  - Path handling across platforms

#### Performance

- **NFR-8**: Fast installation
  - Symlinks > copies where appropriate
  - Parallel operations where safe
  - Minimal redundant file I/O

---

## Success Criteria

### Must Have (Blocking Release)

1. ✅ **Zero data loss**: User's custom commands/agents/skills preserved during install/update
2. ✅ **Modular architecture**: `install.sh` < 150 lines, logic in lib modules
3. ✅ **Dotfiles integration**: Libraries successfully sourced from dotfiles repo
4. ✅ **All tests pass**: Docker tests + CI/CD tests on all platforms
5. ✅ **Namespace isolation**: `.aida/` and `.aida-deprecated/` folders work correctly

### Should Have (Important)

6. ✅ User confirmation before destructive operations
7. ✅ Progress indicators for long operations
8. ✅ Helpful error messages with recovery guidance
9. ✅ Deprecation system working end-to-end
10. ✅ Dev mode `git pull` auto-updates

### Nice to Have (Defer if Needed)

11. Pre-flight installation plan
12. Automatic cleanup script integration in CI/CD
13. Installation time estimates
14. Rollback capability

---

## Open Questions

### Critical (Need Answers Before Implementation)

1. **Dev mode variable substitution**:
   - Problem: Dev mode symlinks can't have substituted variables
   - Question: Do we need runtime variable resolution wrapper?
   - Impact: Affects cross-repo compatibility

2. **Deprecation blocking**:
   - Question: Should installer refuse to install if deprecated templates would conflict?
   - Example: User has `issue-create` and `create-issue`, both try to install
   - Options: Block, warn, or overwrite?

3. **Version compatibility checking**:
   - Question: How strict should version validation be?
   - Example: Dotfiles requires lib v0.2.0, installed is v0.1.9
   - Options: Hard fail, warn and continue, or skip integration?

### Important (Can Defer Decision)

4. **Template registry**:
   - Question: Track installed templates in manifest file?
   - Benefit: Know what was installed by AIDA vs user
   - Cost: Additional complexity

5. **Rollback capability**:
   - Question: Support rollback to previous installation?
   - Benefit: Safety net for failed installations
   - Cost: Implementation complexity

6. **Windows testing**:
   - Question: Test on native Windows or just WSL?
   - Impact: Broader platform support vs complexity

---

## Recommendations

### MVP Scope (v0.1.0)

**Include**:

- ✅ Modular installer with lib/installer-common/
- ✅ `.aida/` namespace isolation
- ✅ Basic deprecation support (frontmatter schema)
- ✅ Docker + Makefile testing (Linux + macOS)
- ✅ Dev mode and normal mode working
- ✅ Dotfiles integration (source libraries)

**Defer**:

- ❌ Automated cleanup script (manual for v0.1.0)
- ❌ Windows testing (focus Linux/macOS first)
- ❌ Pre-flight installation plan (show changes before applying)
- ❌ Rollback capability

### Prioritization Rationale

1. **Namespace isolation is critical** - Without it, data loss continues
2. **Modular architecture enables future work** - Foundational requirement
3. **Dotfiles integration drives architecture** - Must design for reusability
4. **Testing prevents regressions** - Essential for confidence

### Recommended Approach

**Phase 1** (Foundation):

- Refactor to modular architecture
- Implement `.aida/` namespace isolation
- Basic testing harness

**Phase 2** (Integration):

- Dotfiles repo integration
- Comprehensive testing (Docker + CI/CD)
- Deprecation system

**Phase 3** (Polish):

- UX improvements (progress, confirmations, help)
- Windows support
- Advanced features (pre-flight plan, rollback)

---

## Notes

### Configuration Specialist Insights

- Schema-first design for template configuration
- Three-tier variable resolution (install/runtime/computed)
- Template registry for tracking what's installed
- Modular configuration management vs monolithic

### Shell UX Designer Insights

- Current installer risks: silent overwrites, no warnings, unclear idempotency
- Need: Confirmation prompts, progress feedback, recovery guidance
- Cross-platform concerns: Windows symlinks, Bash 3.2 compatibility
- Testing UX: Intuitive Make targets, verbosity levels

### Integration Specialist Insights

- Claude Code does NOT recursively discover `~/.aida/` - must install to `~/.claude/`
- Dotfiles integration: Conditional sourcing with version checking
- CI/CD: Matrix testing (platforms × modes × scenarios)
- Version management: VERSION file as source of truth

---

**Next Steps**: Create Technical Specification with implementation details for each module.
