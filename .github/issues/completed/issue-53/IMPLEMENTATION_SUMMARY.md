---
title: "Implementation Summary - Issue #53"
issue: 53
document_type: "implementation-summary"
created: "2025-10-18"
version: "1.0"
status: "draft"
---

# Implementation Summary: Modular Installer Refactoring

**Issue**: #53 - Modular installer with deprecation support and .aida namespace installation
**Target Version**: v0.2.0
**Estimated Effort**: 87-100 hours (11-13 days) + 20% buffer = 105-120 hours

---

## Executive Summary

Transform AIDA's 625-line monolithic installer into a modular, reusable architecture that:

- **Prevents user data loss** through namespace isolation (`.aida/` subdirectories)
- **Enables dotfiles integration** via reusable `lib/installer-common/` libraries
- **Supports deprecation lifecycle** with version-based frontmatter metadata
- **Provides comprehensive testing** across Linux, macOS, and Windows platforms
- **Maintains backward compatibility** while enabling future command migrations

### Key Outcomes

- ✅ **Zero data loss**: User content outside `.aida/` namespace always preserved
- ✅ **Safe framework updates**: `~/.aida/` symlinked to repo for `git pull` updates
- ✅ **Bi-directional integration**: AIDA ↔ dotfiles repo (reusable libraries)
- ✅ **Foundation for ADR-010**: Command rename migration path established

---

## Architecture Overview

### Before (Current State)

```text
install.sh (625 lines)
└── Monolithic script
    ├── Prompts user input
    ├── Creates directories
    ├── Copies templates (file-by-file)
    ├── Backs up ENTIRE ~/.claude/ (dangerous)
    └── No namespace isolation (data loss risk)

Problem: Nukes entire ~/.claude/, destroys user content
```

### After (Target State)

```text
install.sh (~150 lines)
└── Thin orchestrator
    └── sources lib/installer-common/
        ├── colors.sh (existing)
        ├── logging.sh (existing)
        ├── validation.sh (existing)
        ├── variables.sh (new) - Variable substitution
        ├── directories.sh (new) - Directory/symlink mgmt
        ├── templates.sh (new) - Template installation
        ├── prompts.sh (new) - User interaction
        ├── deprecation.sh (new) - Deprecation lifecycle
        └── summary.sh (new) - Output formatting

~/.claude/
├── commands/
│   ├── my-custom-command.md    # User content (SAFE)
│   ├── .aida/                  # AIDA framework (replaceable)
│   │   └── start-work/
│   └── .aida-deprecated/       # Optional deprecated templates
│       └── create-issue/
├── agents/
│   ├── my-custom-agent.md      # User content (SAFE)
│   └── .aida/                  # AIDA framework (replaceable)
│       └── secretary/
└── skills/
    └── .aida/                  # AIDA framework (replaceable)
        └── bash-expert/

Solution: Namespace isolation protects user content
```

---

## Key Deliverables

### 1. Six New Library Modules

| Module | Purpose | LOC | Effort | Risk |
|--------|---------|-----|--------|------|
| `variables.sh` | Install-time `{{VAR}}` substitution | ~150 | 4h | MEDIUM |
| `directories.sh` | Directory/symlink management | ~200 | 5h | MEDIUM |
| `templates.sh` | Template installation orchestration | ~250 | 8h | HIGH |
| `prompts.sh` | User interaction and validation | ~120 | 3h | LOW |
| `deprecation.sh` | Version-based deprecation lifecycle | ~180 | 6h | HIGH |
| `summary.sh` | Installation summary and next steps | ~100 | 2h | LOW |

**Total**: ~1000 lines of new library code

### 2. Refactored Install Script

- **From**: 625 lines of monolithic code
- **To**: ~150 lines of orchestration logic
- **Change**: 75% reduction in installer complexity
- **Benefit**: All business logic in reusable, testable modules

### 3. Testing Infrastructure

| Component | Description | Effort |
|-----------|-------------|--------|
| **Makefile** | Test orchestration with intuitive targets | 2-3h |
| **Docker Fixtures** | Simulated upgrade scenarios with user content | 6-8h |
| **Upgrade Tests** | User content preservation validation | 8-10h |
| **GitHub Actions** | Extended CI/CD matrix (platforms × scenarios) | 4-6h |
| **Test Validation** | Automated preservation checks | 2h |

**Total**: 22-29 hours of testing infrastructure

### 4. Documentation

- Updated `docs/CONTRIBUTING.md` with testing guide
- New `docs/testing/UPGRADE_TESTING.md`
- Dotfiles integration examples in `docs/integrations/DOTFILES.md`
- Troubleshooting guide for common issues

---

## Implementation Phases

### Phase 1: Foundation (20 hours) - Week 1

**Goal**: Extract core modules, establish testing framework

**Tasks**:

1. ✅ Extract `prompts.sh` - User interaction (3h)
2. ✅ Extract `variables.sh` - Variable substitution (4h)
3. ✅ Extract `directories.sh` - Directory management (5h)
4. ✅ Extract `summary.sh` - Output formatting (2h)
5. ✅ Refactor `install.sh` to orchestrator (4h)
6. ✅ Setup bats unit testing framework (2h)

**Success Criteria**:

- All existing functionality preserved
- Modular architecture working
- Unit tests for extracted modules
- No regressions in existing tests

**Deliverables**:

- 4 new library modules
- Refactored `install.sh` (~150 lines)
- bats unit test framework
- Updated module documentation

---

### Phase 2: Advanced Features (20 hours) - Week 2

**Goal**: Implement namespace isolation, deprecation system

**Tasks**:

1. ✅ Implement `templates.sh` with namespace isolation (8h)
   - Folder-based installation (not file-based)
   - `.aida/` subdirectory creation
   - Normal vs dev mode handling
   - Variable substitution integration

2. ✅ Implement `deprecation.sh` with version logic (6h)
   - Frontmatter parsing (pure Bash, no yq/python)
   - Semantic version comparison
   - Deprecated template installation to `.aida-deprecated/`
   - Cleanup script for repository maintenance

3. ✅ Create Docker test fixtures (3h)
   - Simulated v0.1.x installation
   - User-created custom content
   - Deprecated templates
   - Upgrade scenario configurations

4. ✅ Integration tests for upgrade scenarios (3h)
   - Fresh install validation
   - Upgrade with user content preservation
   - Dev mode symlink validation
   - Deprecated template installation

**Success Criteria**:

- Namespace isolation working (`.aida/` vs user content)
- User content 100% preserved during upgrades
- Deprecation system functional end-to-end
- Integration tests passing in Docker

**Deliverables**:

- 2 new library modules (`templates.sh`, `deprecation.sh`)
- Test fixture directory structure
- Upgrade test scenarios
- Integration test suite

---

### Phase 3: CI/CD & Documentation (15 hours) - Week 3

**Goal**: Comprehensive testing, cross-platform validation

**Tasks**:

1. ✅ Create Makefile with test targets (2-3h)
   - `make test-all`, `make test-upgrade`, etc.
   - Parameterized targets (VERBOSE, ENVIRONMENT)
   - Self-documenting help

2. ✅ Enhance Docker testing environments (4-6h)
   - Upgrade test Dockerfile with pre-seeded fixtures
   - Volume mount strategy for user content
   - Windows container setup (optional v0.3.0)

3. ✅ Update GitHub Actions workflow (4-6h)
   - Upgrade scenario testing job
   - Test matrix expansion (platforms × scenarios)
   - PR comment reporter (optional v0.3.0)
   - Artifact collection and reporting

4. ✅ Cross-platform validation (3-4h)
   - macOS GitHub runner tests
   - Windows WSL tests
   - Platform-specific edge cases

5. ✅ Documentation updates (2-3h)
   - Testing guide
   - Troubleshooting guide
   - Dotfiles integration examples
   - API contract for libraries

**Success Criteria**:

- All tests passing on Linux, macOS, Windows
- Makefile provides intuitive test interface
- CI/CD pipeline comprehensive and reliable
- Documentation complete and accurate

**Deliverables**:

- Makefile with test orchestration
- Extended GitHub Actions workflow
- Cross-platform test validation
- Comprehensive documentation

---

## Testing Strategy

### Automated Testing

**Docker Container Tests**:

- ✅ Fresh installation on clean Ubuntu/Debian
- ✅ Upgrade installation with test fixtures
- ✅ User content preservation validation
- ✅ Dev mode symlink creation and validation
- ✅ Variable substitution validation
- ✅ Dependency validation (missing tools)
- ✅ File permission verification

**GitHub Actions CI/CD**:

- ✅ Matrix testing (Ubuntu 22/20, Debian 12, macOS)
- ✅ All installation modes (normal, dev, deprecated)
- ✅ Upgrade scenarios (fresh, upgrade, mode-switch)
- ✅ Performance benchmarking
- ✅ ShellCheck linting
- ✅ YAML frontmatter validation

**Unit Tests (bats framework)**:

- ✅ Version comparison logic
- ✅ Frontmatter parsing
- ✅ Variable substitution
- ✅ Path handling across platforms
- ✅ Input validation

### Manual Testing (Before Release)

**Platform Testing**:

- [ ] Fresh install on macOS (latest + previous major version)
- [ ] Fresh install on Ubuntu LTS (current)
- [ ] Upgrade install over v0.1.x (macOS + Linux)
- [ ] Dev mode on macOS + Linux
- [ ] Windows WSL (if supported)

**User Experience Testing**:

- [ ] Non-technical user can complete installation
- [ ] Error messages are helpful and actionable
- [ ] Recovery guidance is clear
- [ ] Documentation is accurate and complete

---

## Risk Management

### Critical Risks & Mitigations

**1. User Data Loss** 🔴 **HIGHEST PRIORITY**

- **Risk**: Installer overwrites custom commands/agents/skills
- **Impact**: Loss of user work, trust, reputation damage
- **Mitigation**:
  - ✅ Namespace isolation (`.aida/` subdirectories)
  - ✅ Pre-flight validation (detect user content)
  - ✅ Confirmation prompts before overwrites
  - ✅ Comprehensive automated tests with fixtures
  - ✅ Manual QA testing before every release

**2. Cross-Platform Compatibility** 🟠

- **Risk**: Works on Linux, breaks on macOS (or vice versa)
- **Impact**: Installation fails for half of users
- **Mitigation**:
  - ✅ CI/CD matrix (Ubuntu + macOS runners)
  - ✅ Bash 3.2 linting and validation
  - ✅ Platform-specific test cases
  - ✅ Manual testing on both platforms

**3. Variable Substitution Bugs** 🟠

- **Risk**: Paths not substituted correctly, broken templates
- **Impact**: Commands reference wrong paths, don't work
- **Mitigation**:
  - ✅ Automated validation (grep for unresolved `{{VAR}}`)
  - ✅ Test with paths containing spaces/special chars
  - ✅ Comprehensive test fixtures
  - ✅ Clear distinction (install-time vs runtime)

**4. Symlink Issues (Dev Mode)** 🟡

- **Risk**: Broken symlinks, permission issues, wrong targets
- **Impact**: Dev mode doesn't work, confusing errors
- **Mitigation**:
  - ✅ Symlink validation after creation
  - ✅ Broken symlink detection and repair
  - ✅ Clear error messages if symlinks fail
  - ✅ WSL-specific testing

**5. Dotfiles Integration** 🟡

- **Risk**: Libraries don't work when sourced from dotfiles repo
- **Impact**: Dotfiles integration broken, code duplication needed
- **Mitigation**:
  - ✅ Parameter-based functions (no globals)
  - ✅ Test sourcing from different directory
  - ✅ Version checking for compatibility
  - ✅ API contract documentation

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

11. ❌ Pre-flight installation plan (show changes before applying)
12. ❌ Automated cleanup script integration in CI/CD
13. ❌ Installation time estimates
14. ❌ Rollback capability

---

## Open Questions (Require Resolution)

### Critical (Block Implementation Start)

**Q1: Dev mode variable substitution**

- **Problem**: Symlinked templates can't have substituted variables
- **Options**:
  1. Runtime wrapper resolves variables on-the-fly
  2. Double-install pattern (symlink + generated files)
  3. Require dev users to manually substitute
- **Action**: Spike 1 (4h) - POC runtime wrapper
- **Decision Needed By**: Phase 1 start

**Q2: Deprecation blocking behavior**

- **Question**: Should installer refuse if deprecated templates conflict?
- **Example**: User has `issue-create` and `create-issue` both trying to install
- **Options**:
  1. Block installation with error
  2. Warn and skip deprecated
  3. Warn and overwrite
- **Recommendation**: Option 2 (safest)
- **Decision Needed By**: Phase 2 start

**Q3: Version compatibility strictness**

- **Question**: How strict should version validation be?
- **Example**: Dotfiles requires lib v0.2.0, installed is v0.1.9
- **Options**:
  1. Hard fail (prevent subtle bugs)
  2. Warn and continue (flexible)
  3. Skip integration (degraded)
- **Recommendation**: Option 1 (hard fail)
- **Decision Needed By**: Phase 2 start

---

## Dependencies & Integration Points

### Dotfiles Repo Integration

**API Contract** (semantic versioning):

```bash
# Dotfiles installer sources AIDA libraries
source "${HOME}/.aida/lib/installer-common/templates.sh"
source "${HOME}/.aida/lib/installer-common/variables.sh"

# Use AIDA functions for consistency
install_templates \
  "${PWD}/templates/commands" \
  "${HOME}/.claude/commands/.dotfiles"
```

**Version Compatibility**:

- MAJOR version: Breaking changes to function signatures
- MINOR version: New features, backward compatible
- PATCH version: Bug fixes, no API changes

**Graceful Degradation**:

- Dotfiles works standalone (AIDA not required)
- Version checking prevents incompatible usage
- Clear error messages if integration fails

### Template Frontmatter Schema

**Deprecation Metadata**:

```yaml
---
title: "Create Issue Command"
deprecated: true
deprecated_in: "0.2.0"
remove_in: "0.4.0"
canonical: "issue-create"
reason: "Renamed to noun-verb convention (ADR-010)"
---
```

**Installation Behavior**:

- Default: Only install non-deprecated templates
- `--with-deprecated`: Install both to separate namespaces

---

## Effort Summary

| Phase | Tasks | Estimated Hours | Buffer (20%) | Total |
|-------|-------|-----------------|--------------|-------|
| **Phase 1: Foundation** | Module extraction, unit tests | 20h | 4h | 24h |
| **Phase 2: Advanced Features** | Templates, deprecation, fixtures | 20h | 4h | 24h |
| **Phase 3: CI/CD & Docs** | Testing infrastructure, docs | 15h | 3h | 18h |
| **Testing Infrastructure** | Makefile, Docker, GitHub Actions | 22-29h | 5-6h | 27-35h |
| **Spikes & Unknowns** | Dev mode vars, frontmatter parsing | 9h | 2h | 11h |
| **TOTAL** | **All work** | **86-94h** | **18-19h** | **104-113h** |

**Timeline**: 13-14 days (assuming 8h/day, single developer)

**Recommended Approach**: 3 weeks with buffer for unexpected issues and thorough testing

---

## Next Steps

### Immediate Actions

1. **Review and approve this implementation plan**
2. **Resolve open questions Q1-Q3** via spikes and team discussion
3. **Create implementation branch**: `53-modular-installer`
4. **Set up bats testing framework**
5. **Begin Phase 1**: Extract `prompts.sh` module (lowest risk)

### Implementation Sequence

**Week 1 (Foundation)**:

- Extract `prompts.sh`, `variables.sh`, `directories.sh`, `summary.sh`
- Refactor `install.sh` to orchestrator
- Setup unit testing framework

**Week 2 (Advanced Features)**:

- Implement `templates.sh` with namespace isolation
- Implement `deprecation.sh` with version logic
- Create test fixtures and integration tests

**Week 3 (CI/CD & Polish)**:

- Create Makefile orchestration
- Enhance Docker testing environments
- Update GitHub Actions workflow
- Complete documentation

### Validation Milestones

- **After Phase 1**: All existing functionality preserved, no regressions
- **After Phase 2**: Namespace isolation working, user content preserved
- **After Phase 3**: All platforms tested, documentation complete

---

## Related Documents

- **PRD**: `.github/issues/in-progress/issue-53/PRD.md`
- **Technical Spec**: `.github/issues/in-progress/issue-53/TECH_SPEC.md`
- **Product Analyses**: `.github/issues/in-progress/issue-53/analysis/product/`
- **Technical Analyses**: `.github/issues/in-progress/issue-53/analysis/technical/`
- **Work Tracking**: `.github/issues/in-progress/issue-53/README.md`

---

**Created**: 2025-10-18
**Status**: Draft - Ready for review and approval
**Next Review**: Resolve open questions, approve for implementation
