---
title: "DevOps Engineer Analysis - Issue #37"
issue: 37
analyst: "devops-engineer"
date: "2025-10-06"
complexity: "M"
---

# DevOps Engineer Analysis: Archive Global Agents and Commands

## 1. Implementation Approach

### Automation Strategy

#### Script-Based Archival Process

- Create `scripts/archive-templates.sh` for automated template archival
- Implement variable substitution engine (sed/awk-based)
- Automated scrubbing validation (check for usernames, absolute paths, PII)
- Dry-run mode for validation before committing

#### CI/CD Integration Points

- Template validation in pre-commit hooks (gitleaks already configured)
- Add custom hook for path variable validation
- Extend lint.yml workflow with template-specific checks
- Test-installation.yml already tests install.sh (templates will flow through)

#### Installation Enhancement

- install.sh already mentions "template copying, variable substitution" (line 8)
- Need to implement .template file processing logic
- Variable expansion at install-time (not runtime)
- Support selective installation (core vs specialized agents)

### Deployment Considerations

#### Zero Impact Deployment

- Archival operation is additive (new templates/ directory)
- No changes to existing installation workflows initially
- Templates become source-of-truth for future installs
- Backward compatible: existing ~/.claude/ installations unaffected

#### Phased Rollout

- Phase 1: Archive to templates/ (this issue)
- Phase 2: Enhance install.sh to process templates (separate issue)
- Phase 3: Deprecate manual agent/command creation (future)

## 2. Technical Concerns

### Build/Release Process Impact

#### Repository Structure Changes

- NEW: templates/ directory (agents/, commands/, README files)
- Size impact: ~6 core agents with knowledge dirs + 8 commands (~500KB estimate)
- Git history: Large initial commit, minimal future changes

#### CI/CD Pipeline Extensions

**Lint Workflow Additions**:

- Template path variable validation (ensure no absolute paths)
- Scrubbing verification (no usernames, email, PII)
- Knowledge directory index.md validation (knowledge_count accuracy)
- YAML frontmatter validation for agents/commands

**Test-Installation Workflow**:

- Already tests across macOS, Windows WSL, Linux (ubuntu-22, ubuntu-20, debian-12, ubuntu-minimal)
- Will automatically test template processing once install.sh enhanced
- No new test environments needed

### Testing Automation

#### Template Validation Tests

- Unit: Variable substitution correctness (${VAR} expansion)
- Integration: Fresh install from templates/ succeeds
- Regression: Existing installs unaffected
- Security: Gitleaks detects any leaked secrets

#### Pre-commit Hook Enhancement

```yaml
# Add to .pre-commit-config.yaml
- repo: local
  hooks:
    - id: validate-templates
      name: Validate template path variables
      entry: scripts/validate-templates.sh
      language: script
      files: ^templates/.*\.(md|template)$
```

### Version Control Considerations

#### Git Strategy

- Templates are committed artifacts (not generated)
- Binary files: None expected (all text/markdown)
- Large files: Knowledge directories could grow (monitor with check-added-large-files hook)
- History: Track template evolution, not user config evolution

#### Merge Conflict Risk

- LOW: Templates change infrequently (stable after initial archival)
- Structure: Separate directories per agent/command (minimal overlap)
- Documentation: README files most likely to conflict (coordinate updates)

### Deployment Risks

#### Risk: Broken Path Variables

- Impact: Install fails due to unresolved ${VAR} references
- Mitigation: Validation script in CI, test-installation workflow catches issues
- Probability: MEDIUM (new feature, easy to miss edge cases)

#### Risk: Privacy Leak

- Impact: PII/secrets committed to public repo
- Mitigation: Gitleaks pre-commit hook (already configured), manual scrubbing review
- Probability: LOW (automated detection + manual review)

#### Risk: Template-User Config Drift

- Impact: Templates outdated, new installs get stale configs
- Mitigation: Document sync workflow, version templates in README
- Probability: MEDIUM (manual sync process)

#### Risk: Installation Script Breakage

- Impact: install.sh doesn't handle .template files correctly
- Mitigation: Defer template processing to separate issue, test thoroughly
- Probability: LOW (out of scope for this issue)

## 3. Dependencies & Integration

### GitHub Actions Integration

#### Existing Workflows (No Changes Needed)

- lint.yml: YAML/shellcheck/markdown/gitleaks already cover templates
- test-installation.yml: Will validate templates once install.sh processes them

#### Recommended Additions

```yaml
# .github/workflows/validate-templates.yml (optional)
name: Validate Templates

on:
  pull_request:
    paths:
      - 'templates/**'
  push:
    paths:
      - 'templates/**'

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Validate path variables
        run: scripts/validate-templates.sh
      - name: Check for PII
        run: scripts/scrub-check.sh templates/
```

### Pre-commit Hook Impact

#### Current Hooks (Already Compatible)

- yamllint: Validates agent/command frontmatter
- shellcheck: N/A (no shell scripts in templates/)
- gitleaks: Detects secrets (critical for privacy)
- markdownlint: Validates README files

#### Recommended Hook

```bash
#!/usr/bin/env bash
# scripts/validate-templates.sh

# Check for absolute paths
if grep -rE "/(Users|home)/[^$]" templates/; then
  echo "ERROR: Absolute paths found in templates"
  exit 1
fi

# Check for common PII patterns
if grep -riE "(oakensoul|[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})" templates/; then
  echo "ERROR: Potential PII found in templates"
  exit 1
fi

# Validate variable substitution syntax
if grep -rE '\$\{[A-Z_]+\}' templates/ | grep -vE '\$\{(PROJECT_ROOT|CLAUDE_CONFIG_DIR|AIDA_HOME)\}'; then
  echo "WARNING: Unknown variable found in templates"
fi

echo "✓ Template validation passed"
```

### Release Workflow Changes

#### No Immediate Impact

- Templates archived but not distributed initially
- Release process unchanged (VERSION file, git tags)
- Future: Templates become part of installation payload

#### Future Release Considerations

- Tag template versions alongside code releases
- Changelog: Document template additions/changes
- Migration guide: How to update from old configs to new templates

## 4. Effort & Complexity

### Complexity Assessment: **MEDIUM (M)**

**Reasoning**:

- Straightforward file copying/archival (LOW complexity)
- Variable substitution requires careful implementation (MEDIUM complexity)
- Privacy scrubbing critical but automatable (MEDIUM complexity)
- CI/CD integration minimal (existing hooks sufficient)
- No architectural changes to install.sh (deferred)

### Effort Drivers

**High Effort**:

- Manual scrubbing review (6 core agents + 8 commands = 14 files minimum)
- Knowledge directory sanitization (each core agent has 3+ subdirectories)
- Documentation creation (3 README files with comprehensive content)
- Validation script development (scrubbing checker, path validator)

**Medium Effort**:

- Variable substitution implementation (sed patterns for ${VAR} replacement)
- Pre-commit hook integration (add custom validation)
- Testing template installation flow (manual verification)

**Low Effort**:

- Directory structure creation (straightforward mkdir/cp)
- Git operations (commit, push - standard workflow)
- CI/CD configuration (minimal changes to existing workflows)

### Estimated Timeline

**Phase 1 (Core - Priority P0)**:

- Archival automation script: 2-3 hours
- Privacy scrubbing + review: 3-4 hours
- README documentation: 2-3 hours
- Validation script: 2 hours
- Testing: 2 hours
- **Total: 11-14 hours** (1.5-2 days)

**Phase 2 (Specialized - Priority P1)**:

- Archive 16 specialized agents: 4-5 hours
- Scrubbing review: 2-3 hours
- Documentation updates: 1 hour
- **Total: 7-9 hours** (1 day)

### Risk Areas

**High Risk**:

- Privacy leak: Committed PII/secrets to public repo (IMPACT: Critical, PROBABILITY: Low)
- Broken variable substitution: Install fails (IMPACT: High, PROBABILITY: Medium)

**Medium Risk**:

- Template-user config drift: Outdated templates (IMPACT: Medium, PROBABILITY: Medium)
- Knowledge directory bloat: Large git commits (IMPACT: Low, PROBABILITY: Medium)

**Low Risk**:

- Merge conflicts in templates/: Rare changes (IMPACT: Low, PROBABILITY: Low)
- CI pipeline performance: Additional validation steps (IMPACT: Negligible, PROBABILITY: Low)

## 5. Questions & Clarifications

### Technical Questions

#### Q1: Variable Expansion Timing

- **Question**: Should install.sh expand ${VAR} at install-time or support runtime expansion?
- **Impact**: Determines if we store resolved paths in ~/.claude/ or keep variables
- **Recommendation**: Install-time expansion (simpler, portable configs after installation)
- **Decision needed**: Before implementing install.sh enhancements (separate issue)

#### Q2: Template Versioning

- **Question**: How to track template version vs framework version?
- **Options**: (A) Same as framework VERSION, (B) Separate TEMPLATE_VERSION, (C) Git commit SHA
- **Recommendation**: Option A (simplicity, single version number)
- **Decision needed**: Before v0.2 release

#### Q3: Selective Installation Mechanism

- **Question**: How should users choose core vs specialized agents?
- **Options**: (A) CLI flags, (B) Interactive prompt, (C) Config file
- **Recommendation**: Option B (consistent with current install.sh UX)
- **Decision needed**: When implementing install.sh template processing

#### Q4: Knowledge Directory Strategy

- **Question**: Should knowledge/ directories be empty structure or pre-populated examples?
- **Options**: (A) Empty with README, (B) Generic examples, (C) Exclude entirely
- **Recommendation**: Option B (per PRD OQ-2, empty structure with examples)
- **Decision needed**: Per-agent basis during archival

### Decisions to Be Made

#### D1: Pre-commit vs CI Validation

- **Decision**: Where to run template validation (pre-commit hook vs GitHub Actions)?
- **Recommendation**: BOTH (pre-commit for fast feedback, CI for enforcement)
- **Owner**: DevOps Engineer + Tech Lead

#### D2: Scrubbing Automation Level

- **Decision**: Fully automated scrubbing or manual review required?
- **Recommendation**: Automated detection + mandatory manual review (privacy-critical)
- **Owner**: Security + Product Manager

#### D3: Template Update Workflow

- **Decision**: How frequently to sync ~/.claude/ changes back to templates/?
- **Options**: (A) Every change, (B) Per-release, (C) On-demand
- **Recommendation**: Option B (per-release, documented in templates/README.md)
- **Owner**: Tech Lead

### Areas Needing Investigation

#### I1: GNU Stow Compatibility

- **Investigation**: Test templates/ directory structure with GNU stow
- **Reason**: Dotfiles integration requires stow compatibility
- **Priority**: HIGH (affects dotfiles repo integration)
- **Estimated effort**: 1-2 hours

#### I2: Large File Handling

- **Investigation**: Measure knowledge/ directory sizes, assess git performance
- **Reason**: Potential repo bloat if knowledge dirs grow large
- **Priority**: MEDIUM (monitor during archival)
- **Estimated effort**: 30 minutes

#### I3: Cross-Platform Path Variables

- **Investigation**: Verify ${VAR} expansion works on Windows (WSL), macOS, Linux
- **Reason**: test-installation.yml covers all platforms
- **Priority**: MEDIUM (already tested by CI once install.sh enhanced)
- **Estimated effort**: 1 hour (piggyback on existing CI)

## Summary & Recommendations

### Key Recommendations

1. **Implement automated scrubbing validation** (CRITICAL for privacy)
   - Pre-commit hook for path/PII detection
   - Gitleaks already handles secrets
   - Manual review required before commit

2. **Extend CI validation minimally**
   - Existing lint.yml + test-installation.yml sufficient
   - Add custom validation script for templates/
   - No new workflows needed immediately

3. **Defer install.sh enhancements**
   - Separate issue for .template file processing
   - This issue focuses on archival only
   - Test installation flow manually first

4. **Document template sync workflow**
   - Clear process in templates/README.md
   - Per-release updates (not continuous)
   - Version tracking via framework VERSION

5. **Phase implementation carefully**
   - Phase 1: Core agents + generic commands (P0)
   - Phase 2: Specialized agents (P1, optional)
   - Validate privacy scrubbing at each phase

### Success Criteria from DevOps Perspective

- [ ] Templates pass all pre-commit hooks (gitleaks, yamllint, markdownlint)
- [ ] No absolute paths or PII detected in automated scans
- [ ] CI pipeline (lint.yml) passes for templates/ directory
- [ ] test-installation.yml continues passing (no regression)
- [ ] Fresh git clone + manual template install succeeds
- [ ] Templates compatible with GNU stow structure (investigation I1)

### Risk Mitigation Summary

| Risk | Mitigation | Status |
|------|------------|--------|
| Privacy leak | Gitleaks + custom scrubbing script + manual review | PLANNED |
| Broken variables | Validation script + test-installation.yml | PLANNED |
| Template drift | Document sync workflow, per-release updates | DOCUMENTED |
| CI performance | Minimal additions, leverage existing workflows | MITIGATED |

---

**Complexity**: MEDIUM (M)
**Estimated Effort**: 11-14 hours (Phase 1), 7-9 hours (Phase 2)
**Key Blocker**: Privacy scrubbing validation must complete before commit
**Next Steps**: Review with Tech Lead, implement scrubbing automation, begin Phase 1 archival
