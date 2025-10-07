---
title: "QA Engineer Technical Analysis - Issue #37"
issue: 37
analyst: "qa-engineer"
date: "2025-10-06"
status: "draft"
---

# QA Engineer Technical Analysis: Archive Global Agents and Commands

## 1. Implementation Approach

### Testing Strategy

**Multi-Layer Validation**:

- **Syntax Validation**: Pre-commit hooks validate markdown, YAML, path variables
- **Privacy Scrubbing**: Automated checks for usernames, absolute paths, PII
- **Template Processing**: Test variable substitution works correctly
- **Installation Testing**: Fresh install from templates validates end-to-end

**Test Pyramid**:

```text
├── Unit Tests: Variable substitution, path pattern matching
├── Integration Tests: Template → ~/.claude/ installation
└── E2E Tests: Cross-platform installation validation
```

### Validation Approach

**Pre-Archive Validation**:

- Scan source files for privacy violations (usernames, emails, API keys)
- Identify absolute paths requiring variable substitution
- Validate YAML frontmatter integrity
- Check knowledge directory structure completeness

**Post-Archive Validation**:

- Verify all path variables use correct syntax: `${VAR_NAME}`
- Confirm no hardcoded paths remain
- Test template processing on clean system
- Validate README documentation accuracy

**Installation Validation**:

- Test on macOS (bash 3.2, bash 5.x, zsh)
- Test on Linux (Ubuntu 22/24, Debian 12)
- Verify file permissions (644 for files, 755 for dirs)
- Confirm symlinks resolve correctly in dev mode

### Test Automation Needs

**New Test Scripts Required**:

1. **Privacy Scrubbing Validator** (`tests/validate-templates-privacy.sh`)
   - Scan for usernames, emails, absolute paths
   - Pattern matching for common PII leaks
   - Exit non-zero if violations found

2. **Variable Substitution Tester** (`tests/test-variable-substitution.sh`)
   - Mock environment with test paths
   - Process .template files
   - Verify correct variable expansion

3. **Template Installation Tester** (`tests/test-template-installation.sh`)
   - Install from templates/ to test directory
   - Validate file structure matches expected
   - Check all commands/agents accessible

4. **Knowledge Directory Validator** (`tests/validate-knowledge-structure.sh`)
   - Check index.md knowledge_count accuracy
   - Validate required subdirectories exist
   - Confirm markdown syntax in knowledge files

**CI/CD Integration**:

- Add `.github/workflows/validate-templates.yml`
- Run on every PR touching `templates/`
- Block merge if validation fails
- Upload test artifacts for debugging

## 2. Technical Concerns

### Test Coverage Requirements

**Critical Paths (100% coverage required)**:

- Path variable substitution in all 8 commands
- Privacy scrubbing for all 22 agents
- Knowledge directory structure for 6 core agents
- README file generation

**Important Paths (>90% coverage)**:

- Template file processing (.template extension handling)
- Cross-platform path resolution
- Symlink creation in dev mode
- Error handling for missing variables

**Edge Cases (>75% coverage)**:

- Special characters in paths
- Spaces in directory names
- Unicode in content
- Empty knowledge directories

### Edge Cases to Test

**Path Variable Substitution**:

- Undefined variables (should fail gracefully)
- Nested variable expansion: `${${VAR}_PATH}`
- Variables in different contexts (code blocks, inline code, regular text)
- Escaped dollar signs: `\${NOT_A_VAR}`

**Privacy Scrubbing**:

- Username in different formats: `/Users/oakensoul`, `~oakensoul`, `oakensoul@`
- Email variants: `user@domain.com`, `user [at] domain [dot] com`
- Absolute paths in code examples vs actual paths
- API keys in various formats (Bearer tokens, X-API-Key, etc.)

**Knowledge Directory Handling**:

- Empty knowledge/ directories (just README)
- Partial knowledge/ (missing subdirectories)
- Large knowledge bases (>100 files)
- Symlinked knowledge directories

**File System Edge Cases**:

- Read-only template files
- Case-sensitive vs case-insensitive filesystems
- Long file paths (>255 chars)
- Concurrent installations (race conditions)

### Validation Scenarios

#### Scenario 1: Fresh Install on Clean System

```bash
# Setup: No ~/.aida/, no ~/.claude/
./install.sh
# Validate:
- All templates processed correctly
- Variables expanded to actual paths
- Commands executable
- Agents discoverable
```

#### Scenario 2: Install Over Existing Config

```bash
# Setup: Existing ~/.claude/ with custom agents
./install.sh
# Validate:
- Backup created before overwrite
- User prompted for conflicts
- Custom configs preserved
- Template configs available
```

#### Scenario 3: Dev Mode Installation

```bash
# Setup: In git repo
./install.sh --dev
# Validate:
- Templates symlinked (not copied)
- Edits to repo visible in ~/.aida/
- Variable substitution still works
- No permission issues
```

#### Scenario 4: Cross-Platform Portability

```bash
# Setup: Different users, different systems
# User A: /Users/alice on macOS
# User B: /home/bob on Ubuntu
# Validate:
- Same templates work on both
- No hardcoded paths
- Commands resolve correctly
- No platform-specific failures
```

#### Scenario 5: Variable Expansion Timing

```bash
# Test: When are ${VARS} replaced?
# Install time: .template → processed file
# Runtime: Variables expanded when command runs
# Validate:
- Install-time vars resolved correctly
- Runtime vars remain as ${VAR}
- No double-expansion issues
```

### Quality Risks

**High Risk**:

- **Privacy Leak**: Committing user-specific content to public repo
  - *Mitigation*: Mandatory pre-commit privacy scan, blocking CI check
- **Broken Templates**: Variables not resolving, causing runtime errors
  - *Mitigation*: Integration test with fresh install before merge

**Medium Risk**:

- **Incomplete Knowledge Dirs**: Missing files break agent behavior
  - *Mitigation*: Structural validation, knowledge_count accuracy check
- **Platform Incompatibility**: Templates work on macOS but fail on Linux
  - *Mitigation*: Multi-platform CI testing (already exists)

**Low Risk**:

- **Documentation Drift**: README doesn't match actual templates
  - *Mitigation*: Generate README programmatically from templates/
- **Template Versioning**: Future updates conflict with user customizations
  - *Mitigation*: Document in templates/README.md (defer full solution)

## 3. Dependencies & Integration

### Test Framework Needs

**Existing Infrastructure (Reuse)**:

- `.github/workflows/test-installation.yml` - Multi-platform testing
- `.github/testing/test-install.sh` - Docker-based test harness
- `.pre-commit-config.yaml` - Markdown/YAML linting
- Pre-commit hooks - Shellcheck, yamllint

**New Testing Components**:

1. **Privacy Validation Library** (`lib/privacy-validator.sh`)
   - Pattern database for PII detection
   - Configurable allow-list for false positives
   - JSON/YAML report output

2. **Template Testing Framework** (`lib/template-tester.sh`)
   - Variable substitution engine
   - Template processing simulator
   - Diff comparison utilities

3. **Knowledge Validator** (`lib/knowledge-validator.sh`)
   - Markdown structure validation
   - Cross-reference checking
   - Index.md accuracy verification

### CI/CD Test Integration

**New Workflow: `.github/workflows/validate-templates.yml`**

```yaml
name: Validate Templates

on:
  pull_request:
    paths:
      - 'templates/**'
  push:
    branches:
      - 'milestone-*/task/*-archive-*'

jobs:
  privacy-scan:
    runs-on: ubuntu-latest
    steps:
      - name: Scan for privacy violations
        run: ./tests/validate-templates-privacy.sh

  variable-substitution:
    runs-on: ubuntu-latest
    steps:
      - name: Test variable expansion
        run: ./tests/test-variable-substitution.sh

  cross-platform-install:
    strategy:
      matrix:
        os: [macos-latest, ubuntu-22.04]
    runs-on: ${{ matrix.os }}
    steps:
      - name: Install from templates
        run: ./tests/test-template-installation.sh
```

**Integration with Existing CI**:

- Add template validation to `test-installation.yml`
- Run privacy scan on every commit (fast check)
- Full template install test on PR (comprehensive)
- Block merge if any validation fails

### Manual Testing Requirements

**Pre-Merge Manual Validation**:

1. **Visual Inspection**: Review each archived file for obvious privacy leaks
2. **Spot Check**: Manually test 3 commands, 2 agents on clean system
3. **README Accuracy**: Verify examples work as documented
4. **Knowledge Structure**: Check 2 core agents have complete knowledge dirs

**Post-Merge Validation**:

1. **Fresh Install**: Test on actual clean VM (not CI environment)
2. **User Acceptance**: Install on different user account
3. **Documentation Review**: Does README match what was actually committed?
4. **Regression Check**: Existing workflows still work?

**Platform-Specific Manual Testing**:

- **macOS**: Test with default bash 3.2 AND Homebrew bash 5.x
- **Linux**: Test on actual Ubuntu desktop (not just Docker)
- **WSL**: Test Windows WSL integration (if supported)

## 4. Effort & Complexity

### Estimated Complexity: **MEDIUM (M)**

**Justification**:

- Not algorithmically complex (file copying + variable substitution)
- BUT: High precision required (privacy risk)
- AND: Extensive validation needed (22 agents, 14 commands)
- AND: New test infrastructure required

**Complexity Breakdown**:

- **Implementation**: S (straightforward file operations)
- **Privacy Scrubbing**: M (pattern matching, edge cases)
- **Testing**: M (comprehensive validation, multi-platform)
- **Documentation**: S (README generation)
- **Overall**: M (testing effort dominates)

### Key Effort Drivers

**High Effort**:

1. **Privacy Scrubbing Validation** (40% of effort)
   - Manual review of 22 agents for user-specific content
   - Pattern database creation for automated scanning
   - False positive tuning (allow-list maintenance)

2. **Test Infrastructure** (30% of effort)
   - New validation scripts (privacy, variables, knowledge)
   - CI workflow configuration
   - Cross-platform test matrix

3. **Knowledge Directory Handling** (20% of effort)
   - 6 core agents × complete knowledge hierarchies
   - Sanitization vs exclusion decisions
   - Structural validation scripts

**Medium Effort**:

4. **Variable Substitution** (10% of effort)
   - Pattern replacement in 8 commands
   - .template file processing
   - Edge case handling

**Total Estimated Effort**: 12-16 hours

- Implementation: 3-4 hours
- Testing: 5-7 hours
- Documentation: 2-3 hours
- Review/Iteration: 2-2 hours

### Risk Areas

**High Risk (Blocking Issues)**:

1. **Privacy Leak Discovery During Review**
   - *Impact*: Must sanitize or exclude content
   - *Likelihood*: High (user-generated content)
   - *Mitigation*: Generic templates instead of user archives (per PRD OQ-1)

2. **Variable Substitution Edge Cases**
   - *Impact*: Broken templates on installation
   - *Likelihood*: Medium (complex path patterns)
   - *Mitigation*: Comprehensive integration testing

**Medium Risk (Workaround Available)**:

3. **Knowledge Directory Incompleteness**
   - *Impact*: Agents work but missing examples
   - *Likelihood*: Medium (manual validation needed)
   - *Mitigation*: Empty structure with README (per PRD OQ-2)

4. **Platform-Specific Path Issues**
   - *Impact*: Works on macOS, fails on Linux (or vice versa)
   - *Likelihood*: Low (existing CI covers this)
   - *Mitigation*: Multi-platform testing in CI

**Low Risk (Nice to Have)**:

5. **Documentation Accuracy Drift**
   - *Impact*: README doesn't match templates
   - *Likelihood*: Low (one-time archiving)
   - *Mitigation*: Manual review before merge

## 5. Questions & Clarifications

### Technical Questions Needing Answers

**TQ-1**: Variable Expansion Timing (Critical)

- **Question**: When are `${VARS}` replaced - install time or runtime?
- **Context**: PRD OQ-5 recommends install time (install.sh processes .template)
- **Impact**: Determines whether we need .template extension or not
- **Testing Impact**: How to validate correct expansion timing
- **Need**: Confirmation from install.sh maintainer before implementing

**TQ-2**: Knowledge Directory Strategy (Critical)

- **Question**: Include full knowledge/ dirs or empty structure only?
- **Context**: PRD OQ-2 recommends empty structure with README examples
- **Impact**: Privacy risk vs template usefulness
- **Testing Impact**: Different validation for empty vs full structures
- **Need**: Decision per-agent basis (some may need examples)

**TQ-3**: Template vs Archive Philosophy (Blocking)

- **Question**: Create NEW generic templates or archive existing user content?
- **Context**: PRD OQ-1 recommends generic templates (privacy-first)
- **Impact**: High effort to genericize vs high privacy risk to archive
- **Testing Impact**: Different validation approaches
- **Need**: Decision before any archiving begins

**TQ-4**: Specialized Agent Installation (Medium Priority)

- **Question**: Install all 22 agents by default or selective?
- **Context**: PRD OQ-3 recommends core agents default, specialized optional
- **Impact**: Determines if we need installation flags in install.sh
- **Testing Impact**: Test both full and selective installation
- **Need**: Decision before creating specialized/ subdirectory

### Decisions to be Made

**D-1**: Privacy Scrubbing Automation Level

- **Options**:
  - A) Fully automated with pre-commit hook
  - B) Automated scan + manual review
  - C) Manual review only
- **Recommendation**: B (automated + manual for first pass)
- **Rationale**: Catch obvious violations automatically, human review for context

**D-2**: Template Validation Enforcement

- **Options**:
  - A) Blocking pre-commit hook (fail fast)
  - B) CI check only (catch in PR)
  - C) Manual validation (trust but verify)
- **Recommendation**: A for privacy, B for structure
- **Rationale**: Privacy violations are non-negotiable, structure can be fixed in PR

**D-3**: Knowledge Directory Inclusion Criteria

- **Options**:
  - A) Include all knowledge (after scrubbing)
  - B) Empty structure only
  - C) Per-agent decision based on generic-ness
- **Recommendation**: C (case-by-case evaluation)
- **Rationale**: Some agents (code-reviewer) have generic patterns worth including

**D-4**: Test Coverage Threshold

- **Options**:
  - A) 100% coverage (all templates tested)
  - B) 80% coverage (critical paths only)
  - C) Smoke tests only (basic validation)
- **Recommendation**: A for privacy, B for functionality
- **Rationale**: Privacy leaks are binary (present or not), functionality can have edge cases

### Areas Needing Investigation

**I-1**: Existing Privacy Violations in Source

- **What**: Scan current ~/.claude/ for privacy violations
- **Why**: Understand scope of scrubbing required
- **How**: Run privacy validator against source before archiving
- **Timeline**: Before implementation starts

**I-2**: Variable Substitution Patterns in Commands

- **What**: Catalog all absolute paths in 14 commands
- **Why**: Determine which need ${PROJECT_ROOT} vs ${CLAUDE_CONFIG_DIR}
- **How**: Grep for `/Users/`, `/home/`, `~/.claude/`, `~/.aida/`
- **Timeline**: During implementation planning

**I-3**: Knowledge Directory Dependencies

- **What**: Which agents REQUIRE knowledge/ to function?
- **Why**: Empty vs full structure decision
- **How**: Review agent definitions, test without knowledge/
- **Timeline**: Per-agent during archiving

**I-4**: Cross-Reference Validation

- **What**: Do commands reference specific agents, or vice versa?
- **Why**: Ensure cross-references remain valid after archiving
- **How**: Grep for agent names in commands, command names in agents
- **Timeline**: Before creating README documentation

## Testing Checklist

### Pre-Implementation Testing

- [ ] Scan ~/.claude/ for privacy violations (establish baseline)
- [ ] Catalog absolute paths requiring variable substitution
- [ ] Identify knowledge/ dependencies for each agent
- [ ] Document cross-references between commands/agents

### Implementation Testing

- [ ] Validate YAML frontmatter integrity (all agents)
- [ ] Test variable substitution patterns (all commands)
- [ ] Verify knowledge/ structure completeness (6 core agents)
- [ ] Check README accuracy (all 3 README files)

### Post-Implementation Testing

- [ ] Privacy scan passes (zero violations)
- [ ] Fresh install test (clean VM, no ~/.claude/)
- [ ] Cross-platform test (macOS + Linux)
- [ ] Dev mode test (symlinks work correctly)
- [ ] Selective install test (core vs specialized agents)

### Pre-Merge Validation

- [ ] Manual code review (visual inspection for privacy)
- [ ] Spot check installation (2 agents, 3 commands)
- [ ] Documentation review (README accuracy)
- [ ] CI passing (all automated checks green)

## Test Deliverables

### New Test Scripts

1. `/tests/validate-templates-privacy.sh` - Privacy violation scanner
2. `/tests/test-variable-substitution.sh` - Variable expansion tester
3. `/tests/test-template-installation.sh` - Fresh install validator
4. `/tests/validate-knowledge-structure.sh` - Knowledge directory checker

### New CI Workflow

1. `/.github/workflows/validate-templates.yml` - Template validation pipeline

### Test Libraries

1. `/lib/privacy-validator.sh` - Shared privacy scanning functions
2. `/lib/template-tester.sh` - Template processing utilities
3. `/lib/knowledge-validator.sh` - Knowledge structure validation

### Test Documentation

1. `/templates/README.md` - Template system overview (includes testing section)
2. `/tests/README.md` - Test infrastructure documentation
3. This analysis document - QA perspective and test strategy

## Success Metrics

**Quality Gates**:

- Zero privacy violations detected by automated scan
- 100% of templates install successfully on clean system
- All cross-platform tests passing (macOS, Linux, WSL)
- Documentation accuracy verified by manual spot check

**Regression Prevention**:

- Pre-commit hook blocks commits with privacy violations
- CI blocks PRs with broken templates
- Installation test catches variable expansion issues
- Knowledge validator prevents incomplete structures

**Test Coverage**:

- 100% of commands tested for variable substitution
- 100% of agents scanned for privacy violations
- 100% of core agents validated for knowledge structure
- 80% automated test coverage for edge cases

---

**Next Steps**:

1. Answer TQ-1 (variable expansion timing) - blocks implementation
2. Decide D-1 (privacy scrubbing automation level) - affects tooling
3. Investigate I-1 (existing privacy violations) - scopes effort
4. Create privacy validation script - first deliverable
5. Manual review of source content - privacy-first approach
