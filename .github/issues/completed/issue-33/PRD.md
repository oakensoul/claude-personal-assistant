---
title: "Product Requirements Document: Shared Installer Library"
description: "Dotfiles installer integration via shared installer-common library and VERSION file"
issue: "#33"
status: "DRAFT"
created: "2025-10-06"
last_updated: "2025-10-06"
product_manager: "aida-product-manager"
---

# Product Requirements Document: Issue #33

**Issue**: Support dotfiles installer integration - shared installer-common library and VERSION file
**Status**: DRAFT
**Milestone**: v0.1.2

## Executive Summary

**What**: Extract shared installer utilities from AIDA's `install.sh` into a reusable `lib/installer-common/` library that the dotfiles installer can source, ensuring version compatibility via the existing `VERSION` file.

**Why**: The dotfiles repository needs to integrate with AIDA by sourcing common utilities (logging, colors, validation) to provide a consistent installation experience. Without shared utilities, code duplication increases maintenance burden and creates inconsistent user experiences across installers.

**Value**: Single source of truth for installer logic reduces bugs, ensures consistent UX across AIDA and dotfiles installers, and establishes a reusable integration pattern for future repositories.

## Stakeholder Analysis

### End Users / Engineers

**Concerns**:

- Installation must be straightforward and error-free
- Version incompatibilities could block installation
- Error messages must be actionable, not cryptic
- Installation order matters (AIDA first, dotfiles second)

**Priorities**:

- Consistent experience across AIDA and dotfiles installers
- Clear version compatibility feedback
- Graceful handling of missing dependencies
- Installation "just works" without reading documentation

**Recommendations**:

- Display versions prominently at installer start
- Provide smart version mismatch handling with upgrade instructions
- Support both standalone (AIDA without dotfiles) and integrated scenarios
- Never assume user knowledge - explain what errors mean and how to fix them

### Dotfiles Developers

**Concerns**:

- Dotfiles installer now depends on AIDA repository structure
- Changes to installer-common API can break dotfiles installer
- Need clear documentation of sourcing pattern
- Version coordination between repos required

**Priorities**:

- Well-defined sourcing pattern with examples
- Stable API within minor versions (semantic versioning)
- Clear error messages when AIDA not installed or incompatible
- Testing scenarios for all version combinations

**Recommendations**:

- Document sourcing pattern in `lib/installer-common/README.md`
- Define version compatibility rules (major match required, minor forward-compatible)
- Provide example integration code for dotfiles installer
- Create integration tests covering version mismatches

### AIDA Maintainers

**Concerns**:

- Security vulnerabilities in shared library affect multiple repos (2x impact)
- API stability critical once dotfiles depends on it
- Must maintain backward compatibility carefully
- Breaking changes require coordinated releases

**Priorities**:

- Security-first implementation (input sanitization, path validation)
- Comprehensive testing before external consumption
- Clear versioning strategy and compatibility rules
- No circular dependencies (AIDA must remain standalone)

**Recommendations**:

- Implement security controls from SECURITY_AUDIT.md (Phase 1 mandatory)
- Refactor AIDA's install.sh to dogfood the shared library
- Document breaking change policy and upgrade paths
- Never let AIDA depend on dotfiles (one-way dependency only)

## Requirements

### Functional Requirements

**MUST** (Critical for v0.1.2):

- Extract utilities from `install.sh` into `lib/installer-common/`:
  - `colors.sh` - Terminal color codes and formatting
  - `logging.sh` - `print_message()` function with info/success/warning/error types
  - `validation.sh` - Input validation and version compatibility checking
- Refactor AIDA `install.sh` to source utilities from `lib/installer-common/`
- VERSION file remains single-line semantic version (already exists at 0.1.1)
- Version compatibility checking prevents incompatible AIDA/dotfiles combinations
- Clear error messages when dotfiles sources from missing/incomplete AIDA installation

**SHOULD** (Important, can defer to v0.2.0):

- Add `platform-detect.sh` for OS detection (macOS/Linux)
- Smart version mismatch handling (offer to upgrade AIDA automatically)
- Separate API version for installer-common library
- Bundled fallback utilities in dotfiles for standalone mode

**COULD** (Nice-to-have, future):

- VERSION file metadata (release date, compatibility range)
- Installation telemetry (opt-in)
- Rollback capability for failed installations
- Plugin system for third-party repos to source utilities

### Non-Functional Requirements

**Performance**:

- Sourcing utilities adds negligible overhead (<100ms)
- Version checking completes in <500ms
- No external dependencies (network calls, external commands)

**Security**:

- Input sanitization for all user-provided values (CRITICAL)
- Path canonicalization before sourcing files (CRITICAL)
- File permission validation (644 for libraries, not world-writable)
- Checksum validation for VERSION file (RECOMMENDED for v0.1.2)
- No command injection vulnerabilities in validation functions

**Usability**:

- Error messages provide actionable next steps
- Version display prominent at installer start
- Support no-color terminals (CI/CD environments)
- Path scrubbing in logs (no username exposure)

**Compatibility**:

- Bash 4.0+ required
- macOS primary platform (Linux future)
- Works with AIDA dev mode (symlinked installations)
- No circular dependencies between repos

**Maintainability**:

- All scripts pass `shellcheck` with zero warnings
- Comprehensive unit tests for each utility file
- Clear documentation of API contract
- Semantic versioning for breaking changes

## Success Criteria

**Acceptance Criteria**:

- [ ] `lib/installer-common/` created with colors.sh, logging.sh, validation.sh
- [ ] AIDA `install.sh` refactored to source from lib/installer-common/
- [ ] AIDA installation still works after refactoring (dogfooding proof)
- [ ] Unit tests exist for each utility file
- [ ] All scripts pass shellcheck
- [ ] Documentation created: `lib/installer-common/README.md` with sourcing pattern
- [ ] Security controls implemented: input sanitization, path canonicalization, permission checks
- [ ] Version compatibility checking detects and reports mismatches clearly
- [ ] Integration tests cover: happy path, missing AIDA, version mismatch scenarios

**Key Metrics**:

- Installation success rate: >95% on clean systems
- Time to resolve installation errors: <5 minutes (via clear error messages)
- Code duplication reduction: 100+ lines eliminated between installers
- Security vulnerabilities: Zero critical/high findings

**User Impact**:

- Consistent visual experience across AIDA and dotfiles installers (same colors, formats)
- Clear understanding of version compatibility before installation proceeds
- Actionable error messages reduce support burden
- Users can troubleshoot installation issues without maintainer help

## Open Questions

### Product Questions

**Q1**: Should dotfiles bundle a fallback copy of installer-common?

- **Impact**: HIGH - affects standalone dotfiles functionality
- **Options**:
  - A: Dotfiles requires AIDA (hard dependency)
  - B: Dotfiles bundles minimal utilities, uses AIDA's if available
  - C: Dotfiles has its own utilities, only sources AIDA for AIDA-specific tasks
- **Owner**: Product Manager + Integration Specialist
- **Status**: OPEN
- **Recommendation**: Option B for v0.2.0 (allows dotfiles-first installation), Option A acceptable for v0.1.2 (simpler)

**Q2**: What version compatibility semantics?

- **Impact**: CRITICAL - determines upgrade/blocking behavior
- **Options**:
  - A: Strict major.minor match (0.1.x ↔ 0.1.x only)
  - B: Major match, minor forward-compatible (AIDA 0.2 works with dotfiles 0.1)
  - C: Range-based specification (0.1.0 - 0.3.0)
- **Owner**: Product Manager + Configuration Specialist
- **Status**: OPEN
- **Recommendation**: Option B with documented breaking changes

**Q3**: How verbose should error messages be?

- **Impact**: MEDIUM - affects user experience vs information disclosure
- **Options**:
  - A: Verbose errors (helps debugging, potential info disclosure)
  - B: Generic errors to user, detailed to log file (600 permissions)
- **Owner**: UX Designer + Security Auditor
- **Status**: OPEN
- **Recommendation**: Option B (security-conscious UX)

## Assumptions

- AIDA always installs to `~/.aida/` (not user-configurable)
- Dotfiles installer will clone specific AIDA version tag if not present
- VERSION format never changes (single line, semantic version: MAJOR.MINOR.PATCH)
- Installer-common API is stable within minor versions (0.1.0 → 0.1.x safe)
- Shell compatibility: Bash 4.0+, utilities work in zsh
- Dev mode symlinks work for utility sourcing (`source` follows symlinks)

## Dependencies

- Existing VERSION file (already present at repository root)
- AIDA `install.sh` refactoring (internal to this issue)
- Dotfiles repository integration (external, separate PR)
- Security audit recommendations from SECURITY_AUDIT.md

## Recommendations

### Recommended Approach

**Approach**: Phased implementation starting with minimal viable library for v0.1.2, enhanced UX for v0.2.0

**Rationale**:

- Security vulnerabilities in installer = complete system compromise → security-first approach mandatory
- Dotfiles integration blocks on this issue → prioritize core functionality over enhancements
- AIDA should dogfood its own library (refactor install.sh) to prove stability before external use
- Start simple (3 utility files) and add complexity based on actual dotfiles needs

**Phasing**:

1. **Phase 1 - MVP (v0.1.2)**: Core utilities + security controls
   - Create lib/installer-common/ with colors.sh, logging.sh, validation.sh
   - Refactor AIDA install.sh to source utilities
   - Implement critical security controls (input sanitization, path canonicalization)
   - Document sourcing pattern for dotfiles
   - Estimated: 6 hours (includes security hardening)

2. **Phase 2 - Enhanced UX (v0.2.0)**: Platform detection + smart version handling
   - Add platform-detect.sh (macOS/Linux detection)
   - Smart version mismatch handling (offer to upgrade AIDA)
   - Bundled fallback utilities in dotfiles
   - Advanced compatibility checking
   - Estimated: 4 hours

3. **Phase 3 - Future (v1.0+)**: Advanced features
   - Separate API versioning for installer-common
   - Offline installation support
   - Auto-upgrade mechanism
   - Plugin system for third-party integrations

### What to Prioritize

**Priority 1 (Critical - Blocking v0.1.2)**:

1. Security controls implementation (input sanitization, path canonicalization, permission checks)
2. Extract utilities from install.sh into lib/installer-common/
3. Version compatibility checking function
4. Clear error messaging framework
5. Refactor AIDA install.sh to dogfood shared library

**Priority 2 (High - Recommended for v0.1.2)**:

1. Checksum validation for VERSION file
2. Integration testing (AIDA install → dotfiles sources utilities)
3. Unit tests for each utility file
4. Documentation: lib/installer-common/README.md

**Priority 3 (Medium - Defer to v0.2.0)**:

1. platform-detect.sh utility
2. Smart version mismatch handling (auto-upgrade option)
3. Bundled fallback utilities in dotfiles
4. Separate API version for installer-common

### What to Defer

- **Platform detection** (v0.2.0) - macOS-only for v0.1.2, add Linux support later
- **VERSION file metadata** (v1.0) - keep simple single-line format initially
- **Auto-upgrade mechanism** (v0.3.0) - complex, requires careful UX design
- **Plugin system** (post-v1.0) - not needed until third-party integrations emerge
- **Installation telemetry** (v0.3.0) - opt-in logging for debugging, privacy review required

### What to Avoid

**CRITICAL: Do NOT compromise on security**:

- No shortcuts on input sanitization (command injection = system compromise)
- No optional security controls (users will disable them)
- No "we'll add security later" mindset (bake it in from start)

**Do NOT create circular dependencies**:

- AIDA must remain standalone (never depend on dotfiles)
- Dotfiles can depend on AIDA (one-way only)
- Never make AIDA check for dotfiles presence

**Do NOT overcomplicate VERSION file**:

- Keep single-line semantic version format
- No JSON/YAML/TOML complexity (shell must parse easily)
- Metadata can be added in separate files if needed later

**Do NOT ignore dev mode**:

- Test utility sourcing with symlinked ~/.aida/ (dev mode scenario)
- Ensure relative paths work correctly
- Symlinks must be followed by source command

**Do NOT duplicate code between installers**:

- All shared logic goes in lib/installer-common/
- Both installers use the same functions (consistency)
- Bug fixes benefit both installers automatically

## Risks & Mitigations

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Security vulnerabilities in shared lib affect multiple repos | CRITICAL | MEDIUM | Implement all Phase 1 security controls, comprehensive testing, security review before merge |
| Breaking changes to installer-common API break dotfiles | HIGH | MEDIUM | Semantic versioning, compatibility testing, documented deprecation process |
| Version lock-in between repos limits flexibility | MEDIUM | HIGH | Clear compatibility rules, version range specifications, upgrade guidance |
| Dotfiles installation blocked if AIDA missing/incompatible | HIGH | HIGH | Clear error messages with resolution steps, consider bundled fallback (v0.2.0) |
| Path traversal via malicious filenames | CRITICAL | LOW | Path canonicalization with realpath, reject paths containing .. |
| Command injection in validation functions | CRITICAL | MEDIUM | Strict input sanitization, allowlist validation, proper quoting |
| TOCTOU race conditions during file operations | MEDIUM | LOW | Atomic operations, validate after reading, lock files during critical ops |

## Timeline & Effort

**Estimated Effort**: 6 hours (Phase 1 MVP with security controls)

**Complexity**: MEDIUM (core logic simple, security hardening adds complexity)

**Target Completion**: v0.1.2 release

**Key Milestones**:

1. lib/installer-common/ structure created with 3 utility files (1 hour)
2. Security controls implemented (input sanitization, path validation) (2 hours)
3. AIDA install.sh refactored to source utilities (1 hour)
4. Unit tests + integration tests (1.5 hours)
5. Documentation + security review (0.5 hours)

## Related Documents

- **Technical Specification**: `.github/issues/in-progress/issue-33/TECH_SPEC.md` (to be created by shell-script-specialist)
- **Implementation Summary**: `.github/issues/in-progress/issue-33/IMPLEMENTATION_SUMMARY.md` (post-implementation)
- **Original Issue**: GitHub Issue #33
- **Architecture Documentation**: `docs/architecture/dotfiles-integration.md`
- **Security Audit**: `docs/security/SECURITY_AUDIT.md`
- **Versioning Strategy**: `docs/architecture/versioning.md` (to be created)

## Product Analysis Sources

This PRD synthesizes insights from the following expert analyses:

- **Configuration Specialist**: Version management, shared library patterns, validation requirements
- **Integration Specialist**: Cross-repository integration, one-way dependency architecture, sourcing patterns
- **Privacy & Security Auditor**: Security vulnerabilities (code execution, command injection), privacy concerns (log scrubbing)
- **Shell Systems UX Designer**: Installation flow UX, error messaging, version visibility, graceful degradation

---

## Revision History

| Date | Author | Changes | Status |
|------|--------|---------|--------|
| 2025-10-06 | aida-product-manager | Initial PRD creation from expert analyses | DRAFT |

---

## Notes

**This is foundational infrastructure** for the three-repo ecosystem (AIDA, dotfiles, dotfiles-private). Getting it right matters:

- First impression (installation) determines user adoption
- Security vulnerabilities here = system compromise
- API stability critical once dotfiles depends on it
- Establishes pattern for future third-party integrations

**Key Success Factor**: Balance simplicity (don't over-engineer) with robustness (don't cut security corners).

**Next Steps**:

1. Product Manager decision on open questions (Q1, Q2, Q3)
2. Technical Specification by shell-script-specialist
3. Security implementation plan by privacy-security-auditor
4. Implementation by development team
5. Integration testing with dotfiles repository
