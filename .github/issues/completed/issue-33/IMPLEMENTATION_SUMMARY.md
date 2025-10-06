---
title: "Implementation Summary - Issue #33"
description: "Executive summary of expert analysis and implementation plan"
issue: "#33"
status: "Ready for Implementation"
created: "2025-10-06"
---

# Implementation Summary: Issue #33

**Issue**: Support dotfiles installer integration - shared installer-common library and VERSION file

**Status**: Ready for Implementation

**Complexity**: LARGE (L) - 10-12 hours

## Overview

**What**: Extract shared installer utilities from AIDA's `install.sh` into a reusable `lib/installer-common/` library that the dotfiles installer can source, with semantic version compatibility checking.

**Why**: Enables code reuse between AIDA and dotfiles installers, provides consistent UX, eliminates duplication, and establishes a reusable pattern for the three-repo ecosystem (AIDA, dotfiles, dotfiles-private).

**Approach**: Create modular library (colors.sh, logging.sh, validation.sh) with security controls (input sanitization, path validation, permission checks). Dotfiles sources utilities from `~/.aida/lib/installer-common/` after version compatibility check. One-way dependency: dotfiles → AIDA (AIDA remains standalone).

## Key Decisions

### Critical Technical Decisions (BLOCKING - All Resolved)

#### Decision 1: Bash Version - Require 3.2+ (macOS Compatible)

- **What**: Downgrade from Bash 4.0+ to Bash 3.2+ requirement
- **Why**: macOS default is Bash 3.2.57; claiming "macOS primary" but requiring 4.0+ creates installation friction
- **Impact**: Must replace `${var,,}`, `${var^^}` with `tr` commands, avoid associative arrays
- **Trade-off**: More verbose code, but universal macOS compatibility without Homebrew Bash

#### Decision 2: Version Compatibility - Major Match, Minor Forward-Compatible

- **What**: Semantic versioning with major match required, minor forward-compatible
- **Why**: Standard semver, enables AIDA innovation without breaking dotfiles
- **Example**: AIDA 0.2.0 works with dotfiles requiring >=0.1.0 (forward compatible)
- **Trade-off**: Must maintain API stability within minor versions

#### Decision 3: Security Controls - Phase 1 Mandatory for v0.1.2

- **What**: Implement Phase 1 controls (input sanitization, path canonicalization, permission checks). Defer Phase 2 (checksums, GPG) to v0.2.0
- **Why**: Shared library has 2x blast radius (affects AIDA + dotfiles). Security cannot be "added later"
- **Phase 1**: Input sanitization, realpath canonicalization, world-writable rejection, VERSION validation
- **Phase 2**: Checksum validation, GPG signatures (v0.2.0)
- **Trade-off**: Accept some TOCTOU risk, gain timely delivery with acceptable security posture

#### Decision 4: Effort Estimate - 10-12 hours (Not 2 hours)

- **What**: 6x increase from original estimate
- **Why**: Security (3h), Bash compatibility (2h), Testing (4h), Documentation (1h) not in original estimate
- **Trade-off**: Longer timeline, but production-quality secure implementation

### Product Decisions (from Q&A)

#### Q1: Dotfiles Fallback Utilities - Hard Dependency on AIDA

- **Decision**: Dotfiles requires AIDA (no fallback utilities for v0.1.2)
- **Rationale**: "No reason to use dotfiles without AIDA. Lots of great options out there."
- **Impact**: Clear installation order (AIDA → dotfiles → dotfiles-private), simpler implementation
- **Future**: Can add fallback in v0.2.0 if needed

#### Q2: realpath Requirement - Required Prerequisite

- **Decision**: Require realpath (fail with clear error if missing)
- **Installation**: macOS: `brew install coreutils`, Linux: pre-installed
- **Rationale**: Document prerequisites clearly, fail gracefully with installation instructions
- **Future**: Windows support deferred (not in scope for v0.1.2)

#### Q3: Error Message Verbosity - Generic to User, Detailed to Logs

- **Decision**: Two-tier error system (generic user messages + detailed logs)
- **Log Location**: `~/.aida/logs/install.log` (permissions: 600)
- **Rationale**: Technical users can access logs for debugging, but avoid info disclosure in user-facing messages
- **Requirement**: Document log location prominently in README.md

## Implementation Scope

### In Scope (v0.1.2)

**Core Functionality**:

- ✅ Create `lib/installer-common/` with colors.sh, logging.sh, validation.sh
- ✅ Extract utilities from install.sh (refactor, not rewrite)
- ✅ VERSION file (already exists, bump to 0.1.2)
- ✅ Semantic version compatibility checking
- ✅ AIDA install.sh refactored to source utilities (dogfooding)

**Security (Phase 1 - MANDATORY)**:

- ✅ Input sanitization (allowlist validation for versions, paths, filenames)
- ✅ Path canonicalization (realpath-based, reject `..`)
- ✅ File permission validation (reject world-writable, validate ownership)
- ✅ VERSION file format validation
- ✅ No eval, no unquoted expansions

**Testing**:

- ✅ Unit tests for all utility files (bats framework)
- ✅ Integration tests (AIDA standalone, AIDA + dotfiles)
- ✅ Security tests (command injection, path traversal, permission tampering)
- ✅ Bash 3.2 compatibility testing on macOS

**Documentation**:

- ✅ `lib/installer-common/README.md` with sourcing pattern, API reference, security guidelines
- ✅ Log location documentation
- ✅ Troubleshooting section

**Platform Support**:

- ✅ macOS (primary)
- ✅ Linux (Ubuntu, tested in containers)

### Out of Scope (Deferred)

**Phase 2 Security (v0.2.0)**:

- ❌ Checksum validation for VERSION file
- ❌ GPG signature verification
- ❌ Advanced TOCTOU mitigations

**Advanced Features (v0.2.0+)**:

- ❌ Dotfiles fallback utilities (standalone dotfiles)
- ❌ Auto-upgrade mechanism
- ❌ platform-detect.sh (minimal for v0.1.2, full in v0.2.0)

**Platform Support**:

- ❌ Windows (separate effort, different prerequisites)

## Technical Approach

### Architecture

```text
lib/installer-common/
├── colors.sh      (60 lines)  - Color codes, formatting
├── logging.sh     (80 lines)  - print_message() with log levels
└── validation.sh  (200 lines) - Security controls, version checking
```

**Sourcing Pattern** (for dotfiles):

1. Check AIDA installed at `~/.aida/`
2. Simple version check (before sourcing utilities)
3. Canonicalize paths with realpath
4. Validate library exists
5. Source utilities in dependency order (colors → logging → validation)
6. Use utilities

### Key Components

**colors.sh**:

- Color code constants (RED, GREEN, YELLOW, BLUE, NC)
- No-color terminal detection
- Function-based (not variable exports)

**logging.sh**:

- `print_message()` function with log levels (info, success, warning, error)
- Secure logging to `~/.aida/logs/install.log`
- Path scrubbing (~/... instead of /Users/username/...)

**validation.sh**:

- `validate_version()` - Regex: `^[0-9]+\.[0-9]+\.[0-9]+$`
- `check_version_compatibility()` - Semantic versioning enforcement
- `validate_path()` - realpath canonicalization, reject `..`
- `validate_file_permissions()` - Reject world-writable, validate ownership
- Platform detection for stat syntax (macOS BSD vs Linux GNU)

### Bash 3.2 Compatibility

**Changes Required**:

- Replace `${var,,}` → `$(echo "$var" | tr '[:upper:]' '[:lower:]')`
- Replace `${var^^}` → `$(echo "$var" | tr '[:lower:]' '[:upper:]')`
- Avoid `declare -A` (associative arrays) - use indexed arrays

**Testing**: Run on macOS with Bash 3.2.57 before merge

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Bash 3.2 compatibility breaks functionality | HIGH | Test on macOS default Bash, audit all Bash 4.0+ features |
| Security vulnerabilities affect both repos | CRITICAL | Phase 1 controls mandatory, code review, penetration testing |
| Version skew (dotfiles uses removed function) | HIGH | Semantic versioning, deprecation warnings, compatibility tests |
| Path traversal attacks | HIGH | realpath canonicalization, reject `..`, validate within $HOME |
| Cross-platform stat/realpath syntax | MEDIUM | Platform detection ($OSTYPE), test on macOS + Linux |
| Missing realpath on macOS | MEDIUM | Document prerequisite, fail with clear error + installation instructions |

## Success Criteria

**Functional**:

- ✅ `lib/installer-common/` created with 3 utility files
- ✅ AIDA install.sh sources utilities successfully (dogfooding)
- ✅ AIDA installation works after refactoring (no regressions)
- ✅ Dotfiles can source utilities from `~/.aida/` (integration tested)
- ✅ Version compatibility checking works (5 scenarios tested)
- ✅ Works on Bash 3.2.57 (macOS default)

**Non-Functional**:

- ✅ All shellcheck warnings resolved (zero warnings)
- ✅ Unit tests pass for all utility files
- ✅ Integration tests pass (AIDA standalone, AIDA + dotfiles)
- ✅ Security tests pass (command injection, path traversal, permission tampering)
- ✅ Performance: Sourcing overhead <100ms
- ✅ Documentation: README.md with sourcing pattern, API reference, troubleshooting

**Security**:

- ✅ Phase 1 security controls implemented
- ✅ Malicious input rejected (path traversal, command injection)
- ✅ World-writable files rejected
- ✅ Paths canonicalized before use
- ✅ No eval, no unquoted expansions

## Effort Estimate

**Overall Complexity**: LARGE (L)

**Estimated Hours**: 10-12 hours

**Breakdown**:

| Phase | Effort | Description |
|-------|--------|-------------|
| 1. Library Structure | 1h | Create lib/installer-common/, extract utilities |
| 2. Bash 3.2 Compatibility | 2h | Replace ${var,,}, ${var^^}, test macOS |
| 3. Security Implementation | 3h | Input sanitization, path validation, permissions |
| 4. Version Logic | 1.5h | Semantic versioning compatibility checking |
| 5. Refactor install.sh | 1h | Source utilities, test installation |
| 6. Testing | 4h | Unit, integration, security tests |
| 7. Documentation | 1h | README.md, API reference, troubleshooting |
| **Buffer** | 1.5h | Unknown issues, cross-platform testing |
| **Total** | **15h** | Round to 10-12 hours (aggressive but achievable) |

**Key Effort Drivers**:

- Security implementation (3h) - Critical for shared library
- Testing (4h) - Comprehensive coverage required
- Bash 3.2 compatibility (2h) - Replace features, test macOS
- Cross-platform (embedded) - stat/realpath syntax differences

## Next Steps

### Immediate Actions

1. **Begin Implementation** - Start with Phase 1 (library structure creation)
2. **Create Branch** - Already on `milestone-v0.1/task/33-installer-common-version`
3. **Set Up Testing** - Install bats framework for unit tests

### Implementation Phases

**Phase 1: Foundation** (1h)

- Create `lib/installer-common/` directory
- Extract colors.sh, logging.sh from install.sh
- Create validation.sh skeleton

**Phase 2: Bash Compatibility** (2h)

- Replace Bash 4.0+ features (${var,,}, ${var^^})
- Test on macOS Bash 3.2.57
- Verify no associative arrays in use

**Phase 3: Security** (3h)

- Implement input sanitization functions
- Implement path canonicalization (realpath)
- Implement permission validation (platform detection for stat)
- Add secure logging

**Phase 4: Version Logic** (1.5h)

- Implement `check_version_compatibility()`
- VERSION file validation
- Error messages with upgrade instructions

**Phase 5: Refactor install.sh** (1h)

- Add sourcing logic at top of install.sh
- Remove inline definitions
- Test installation (normal + dev mode)

**Phase 6: Testing** (4h)

- Unit tests (bats framework)
- Integration tests (AIDA + dotfiles)
- Security tests (malicious input)

**Phase 7: Documentation** (1h)

- lib/installer-common/README.md
- API reference
- Troubleshooting section with log location

### Review & Merge

1. **Code Review** - Security-focused review by second developer
2. **Testing Validation** - All tests pass (unit, integration, security)
3. **Linting** - Zero shellcheck warnings
4. **Documentation Review** - Clarity check, log location prominent
5. **Merge** - PR to main branch
6. **Release** - Tag v0.1.2

### Post-Implementation

1. **Monitor** - Watch for issues from dotfiles integration
2. **Document Learnings** - Update `.claude/agents/tech-lead/learnings.md`
3. **Plan v0.2.0** - Phase 2 security controls (checksums, GPG)

## Related Documents

- **Product Requirements**: [PRD.md](PRD.md)
- **Technical Specification**: [TECH_SPEC.md](TECH_SPEC.md)
- **Q&A Log**: [qa-log.md](qa-log.md)
- **Original Issue**: GitHub Issue #33
- **Expert Analyses**: `analysis/product/` and `analysis/technical/`

## Key Takeaways

**What Changed from Original Estimate**:

- Original: 2 hours for "extract utilities"
- Revised: 10-12 hours with security, testing, Bash compatibility
- Reason: Security is non-negotiable for shared infrastructure

**Critical Success Factors**:

1. ✅ All blocking decisions resolved (Bash 3.2, version semantics, security scope)
2. ✅ Security controls mandatory (Phase 1 for v0.1.2)
3. ✅ Test on macOS Bash 3.2.57 before merge
4. ✅ Clear error messages + documented log location
5. ✅ One-way dependency (dotfiles → AIDA, AIDA stays standalone)

**Risk Mitigation**:

- Bash 3.2 testing on macOS required before merge
- Security-focused code review mandatory
- Comprehensive testing (unit, integration, security)
- Platform testing (macOS + Linux containers)

---

**Status**: Ready for Implementation

**Next Action**: Begin Phase 1 (library structure creation)

**Blocking Issues**: None (all decisions resolved)

**Ready to Ship**: After 10-12 hours of implementation + testing + review
