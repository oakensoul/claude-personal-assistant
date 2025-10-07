---
title: "QA Engineer Analysis: Workflow Command Templates"
issue: "#39"
analyst: "qa-engineer"
created: "2025-10-07"
status: "draft"
---

# QA Engineer Analysis: Workflow Command Templates

Technical analysis from QA/testing perspective for Issue #39.

## 1. Implementation Approach

### Testing Strategy for Installation

#### Normal Mode Installation

- Verify command templates copied from `templates/commands/workflows/*.template` to `~/.claude/commands/workflows/`
- Validate variable substitution correctness (PROJECT_ROOT, AIDA_HOME, HOME)
- Check file permissions (644 templates, 600 installed commands)
- Confirm backup creation for existing commands (.bak suffix)
- Test with 0 commands, 4 commands, partial overlap scenarios

#### Dev Mode Installation

- Verify symlinks created instead of copies
- Test live editing (edit template, verify change in ~/.claude/)
- Validate symlink targets point to correct repo paths
- Check behavior when switching normal → dev → normal modes

#### Upgrade Scenarios

- Test fresh install (no existing commands)
- Test upgrade with unmodified commands (overwrite)
- Test upgrade with user-modified commands (backup + overwrite)
- Test upgrade with missing templates (error handling)

### Validation Approach

#### Pre-Commit Hook Integration

- Add shellcheck validation for *.sh.template files
- Add variable substitution validation (detect unresolved {{VAR}} patterns)
- Extend existing validate-templates.sh to check shell templates
- Test hook on commit, manual run, CI execution

#### Runtime Validation

- Test variable resolution during install.sh execution
- Validate command syntax after substitution (shellcheck on installed files)
- Check for edge cases (spaces in paths, special characters)
- Verify no secrets in templates (extend gitleaks config if needed)

### Test Automation Recommendations

#### Unit Tests

- Test variable substitution function in isolation
- Test backup logic with various file states
- Test permission setting for templates and installed files
- Test conflict resolution (keep, overwrite, backup)

#### Integration Tests

- Full install.sh run in test environment
- Verify all 12 commands installed correctly
- Test command execution after installation
- Test dev mode symlink creation and usage

#### CI Pipeline

- Add template validation to pre-commit hook (already exists)
- Add shell template linting (shellcheck)
- Add installation smoke tests (install in clean container)
- Test on macOS and Linux (GitHub Actions matrix)

#### Platform Testing Matrix

```text
Platforms:
  - macOS 13 (Ventura) + bash 3.2
  - macOS 14 (Sonoma) + zsh 5.9
  - Ubuntu 22.04 + bash 5.1
  - Ubuntu 24.04 + bash 5.2

Test scenarios per platform:
  - Fresh install (no existing commands)
  - Upgrade with existing commands
  - Dev mode installation
  - Variable substitution correctness
```

## 2. Technical Concerns

### Test Coverage Requirements

#### Critical Paths (100% coverage)

- Variable substitution logic (all variables: PROJECT_ROOT, AIDA_HOME, HOME)
- File permission setting (644 templates, 600 installed)
- Backup creation when conflicts exist
- Symlink creation in dev mode

#### Important Paths (90%+ coverage)

- Error handling (missing templates, permission denied, disk full)
- Upgrade path testing (existing → new versions)
- Command validation post-installation
- Cross-platform compatibility

#### Edge Cases (80%+ coverage)

- Spaces in PROJECT_ROOT path
- Special characters in paths ($, &, ;, |)
- Missing parent directories
- Partial installation failures

### Edge Cases to Handle

#### File System Edge Cases

- Spaces in PROJECT_ROOT: `/Users/user name/projects/test`
- Special characters: `/path/with&ampersand/project`
- No write permissions to ~/.claude/commands/
- Disk full during installation
- Existing .bak files (backup of backup)

#### Variable Substitution Edge Cases

- Undefined variables (should error)
- Variables with special regex characters
- Nested variable references (not supported, should detect)
- Empty variable values (HOME="" edge case)

#### Installation Mode Edge Cases

- Switch normal → dev with existing commands
- Switch dev → normal (convert symlinks to files)
- Dev mode when repo directory moved
- Concurrent installations (race conditions)

#### Command Content Edge Cases

- Commands with ${VAR} syntax that should NOT be substituted
- Commands with backticks or $() subshells
- Commands with heredocs (<<EOF)
- Commands with arrays or complex bash syntax

### Regression Risk Areas

#### High Risk (requires explicit regression tests)

- Existing command customizations overwritten without backup
- File permissions changed on upgrade (600 → 644 security issue)
- Variable substitution breaking existing commands
- Dev mode symlinks breaking when repo moves

#### Medium Risk

- Pre-commit hooks failing in CI but passing locally (already an issue per .pre-commit-config.yaml)
- Cross-platform differences (BSD sed vs GNU sed)
- Shell compatibility (bash vs zsh)
- Command dependencies (commands calling other commands)

#### Low Risk

- Documentation drift (README vs actual behavior)
- Example commands in docs becoming outdated
- Command naming conventions inconsistency

### Testing Challenges

#### Challenge 1: Variable Substitution Validation

- Cannot easily unit test sed substitution in isolation
- Must test full install.sh run to validate
- Recommendation: Extract substitution to testable function

#### Challenge 2: Cross-Platform Differences

- macOS uses BSD sed (different syntax)
- Linux uses GNU sed
- Recommendation: Use portable sed syntax or detect platform

#### Challenge 3: Dev Mode Symlink Testing

- Requires actual filesystem operations (no mocking)
- Must test in actual dev environment
- Recommendation: Use Docker containers for isolated testing

#### Challenge 4: Pre-Commit Hook CI Failures

- Template validation hook disabled in CI (stages: [manual])
- Must resolve CI failure before adding shell validation
- Recommendation: Debug validate-templates.sh in GitHub Actions

#### Challenge 5: Command Interdependencies

- Commands may call other commands (/create-command → /create-agent)
- Must test in correct order
- Recommendation: Create dependency graph, test in topological order

## 3. Dependencies & Integration

### Testing Dependencies

#### Required Tools

- shellcheck (shell script linting)
- bats or shunit2 (shell test framework)
- pre-commit (hook testing)
- Docker (cross-platform testing)
- GitHub CLI (for commands that use gh)

#### Optional Tools

- shfmt (shell formatting)
- shellharden (shell hardening)
- vale (prose linting for command docs)

### CI Integration Points

#### Existing Hooks to Extend

- validate-templates.sh: Add shell template validation
- shellcheck: Add *.sh.template file pattern
- markdownlint: Validate command README.md

#### New Hooks to Add

- validate-shell-templates: Check *.sh.template files
- validate-variable-syntax: Check {{VAR}} patterns
- test-installation: Run install.sh in test environment

#### GitHub Actions Workflow

```yaml
test-installation:
  strategy:
    matrix:
      os: [macos-13, ubuntu-22.04]
  runs-on: ${{ matrix.os }}
  steps:
    - uses: actions/checkout@v3
    - name: Test fresh install
      run: ./install.sh --test-mode
    - name: Validate installation
      run: ./scripts/validate-installation.sh
```

### Platform Testing (macOS/Linux)

#### macOS-Specific Tests

- BSD sed compatibility
- macOS security permissions (Gatekeeper, etc.)
- Bash 3.2 compatibility (default macOS bash)
- zsh as default shell (macOS Catalina+)

#### Linux-Specific Tests

- GNU sed behavior
- Ubuntu 22.04 and 24.04 compatibility
- Bash 5.x features (if used)
- File permissions on Linux filesystems

#### Cross-Platform Tests

- Variable substitution produces same results
- Commands work identically on both platforms
- File permissions set correctly on both
- Error messages consistent across platforms

## 4. Effort & Complexity

### Estimated Complexity

#### Overall: Medium (M)

Breakdown:

- Installation logic: Small (S) - straightforward copy + sed
- Variable substitution: Small (S) - simple sed replacement
- Testing infrastructure: Medium (M) - requires CI, platform testing
- Pre-commit validation: Medium (M) - extend existing hooks
- Command migration: Small (S) - copy files to templates/

### Key Effort Drivers

#### High Effort

1. Cross-platform testing setup (30% of effort)
   - Docker containers for Linux testing
   - macOS VM or GitHub Actions for macOS testing
   - CI pipeline configuration

2. Pre-commit hook extension (25% of effort)
   - Extend validate-templates.sh for shell files
   - Add shellcheck for *.sh.template files
   - Debug CI failures (template validation currently disabled)

3. Regression testing (20% of effort)
   - Test upgrade paths (existing → new)
   - Test user customizations preserved
   - Test dev mode edge cases

#### Medium Effort

4. Installation testing (15% of effort)
   - Test fresh install, upgrade, dev mode
   - Test variable substitution correctness
   - Test error handling

5. Documentation (10% of effort)
   - Test plan documentation
   - Testing guidelines for contributors
   - CI/CD documentation

### High-Risk Areas

#### Risk 1: Variable Substitution Bugs

- Impact: Commands fail at runtime with unresolved variables
- Likelihood: Medium
- Mitigation: Comprehensive pre-commit validation, test all 12 commands post-install

#### Risk 2: Cross-Platform Differences

- Impact: Commands work on macOS but fail on Linux (or vice versa)
- Likelihood: Medium-High
- Mitigation: Platform matrix testing in CI, use portable shell syntax

#### Risk 3: User Customization Loss

- Impact: Users lose command customizations on upgrade
- Likelihood: High (if backup logic fails)
- Mitigation: Explicit backup testing, clear upgrade documentation

#### Risk 4: Dev Mode Symlink Breakage

- Impact: Dev mode stops working when repo moves
- Likelihood: Medium
- Mitigation: Test symlink behavior, document limitations

#### Risk 5: Security Regression

- Impact: File permissions changed to world-readable (600 → 644)
- Likelihood: Low
- Mitigation: Explicit permission testing in test suite

## 5. Questions & Clarifications

### Testing Questions

#### Q1: How comprehensive should shell template validation be?

- Should we run shellcheck on templates before substitution?
- Should we run shellcheck on installed commands after substitution?
- Should we test command execution or just syntax?

#### Q2: Should we test command functionality or just installation?

- Installation only: Faster, simpler
- Functionality: More comprehensive, catches runtime issues
- Recommendation: Start with installation, add smoke tests for critical commands

#### Q3: What level of cross-platform testing is required for v0.2?

- Minimal: macOS only (primary platform per CLAUDE.md)
- Moderate: macOS + Ubuntu LTS
- Comprehensive: macOS (13, 14) + Ubuntu (22.04, 24.04) + Debian 12
- Recommendation: Moderate for MVP, comprehensive for v1.0

#### Q4: Should we test command interdependencies?

- Commands call other commands (/expert-analysis uses /start-work)
- Should we test full workflows or individual commands?
- Recommendation: Individual commands for MVP, workflow testing post-MVP

### Coverage Decisions

#### Q5: What test coverage threshold is acceptable?

- Critical paths: 100% (variable substitution, permissions, backup)
- Important paths: 90% (error handling, upgrade paths)
- Edge cases: 80% (special characters, platform-specific)
- Recommendation: Use coverage thresholds in CI

#### Q6: Should we test with actual GitHub API or mock?

- Some commands use GitHub CLI (gh)
- Real API: More realistic but requires credentials
- Mock: Faster but may miss integration issues
- Recommendation: Mock for unit tests, real API for integration tests (optional)

### Investigation Needs

#### Q7: Why is template validation disabled in CI?

- .pre-commit-config.yaml has `stages: [manual]` for validate-templates
- Comment says "TODO: Fix CI-specific failure"
- Investigation: Debug validate-templates.sh in GitHub Actions before adding shell validation

#### Q8: Do we need to support Windows (WSL)?

- CLAUDE.md says "macOS primary, Linux support planned"
- No mention of Windows
- Investigation: Clarify Windows support requirements

#### Q9: What is the expected number of workflow commands?

- PRD says "4 workflow commands"
- README shows 8 commands (create-agent, create-command, create-issue, expert-analysis, generate-docs, publish-issue, track-time, workflow-init)
- Plus 3 more mentioned in PRD: cleanup-main, implement, start-work
- Investigation: Confirm final list of commands for v0.2

#### Q10: Should we validate command dependencies?

- Example: /expert-analysis requires /workflow-init and /start-work
- Should install.sh validate dependencies?
- Should pre-commit hook validate dependencies?
- Investigation: Determine dependency validation scope for MVP

---

**Testing Philosophy**: Prioritize installation correctness, variable substitution validation, and user customization preservation. Cross-platform testing is important but can be phased (macOS for MVP, Linux for v1.0). Focus on preventing regressions that affect user experience.
