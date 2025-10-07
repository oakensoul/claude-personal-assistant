---
title: "Shell Script Specialist Analysis: Issue #33"
description: "Technical analysis of shared installer-common library implementation"
issue: "#33"
analyst: "shell-script-specialist"
created: "2025-10-06"
status: "DRAFT"
---

# Shell Script Specialist Technical Analysis: Issue #33

**Issue**: Support dotfiles installer integration - shared installer-common library and VERSION file

**Analysis Date**: 2025-10-06

**Analyst**: shell-script-specialist

## 1. Implementation Approach

### Recommended Shell Scripting Approach

**Modularization Strategy**:

- Extract self-contained utility functions into separate sourced files
- Each file = single responsibility (colors, logging, validation, platform detection)
- Use shell functions (not global variables) for maximum flexibility
- Implement defensive coding: check dependencies before executing

**Sourcing Pattern** (for dotfiles installer):

```bash
# Safe sourcing with validation
AIDA_DIR="${HOME}/.aida"
INSTALLER_COMMON="${AIDA_DIR}/lib/installer-common"

# Check AIDA installation exists
if [[ ! -d "$AIDA_DIR" ]]; then
    echo "Error: AIDA framework not found at $AIDA_DIR"
    echo "Please install AIDA first: https://github.com/oakensoul/claude-personal-assistant"
    exit 1
fi

# Validate lib/installer-common/ exists
if [[ ! -d "$INSTALLER_COMMON" ]]; then
    echo "Error: AIDA installation incomplete (missing lib/installer-common)"
    exit 1
fi

# Source utilities with error checking
source "${INSTALLER_COMMON}/colors.sh" || exit 1
source "${INSTALLER_COMMON}/logging.sh" || exit 1
source "${INSTALLER_COMMON}/validation.sh" || exit 1
source "${INSTALLER_COMMON}/platform-detect.sh" || exit 1  # Optional for v0.1.2
```

**File Structure**:

```text
lib/installer-common/
├── README.md              # Sourcing pattern documentation, API contract
├── colors.sh              # Color codes + formatting functions
├── logging.sh             # print_message() function (depends on colors.sh)
├── validation.sh          # Input validation, version checking
└── platform-detect.sh     # OS/platform detection (defer to v0.2.0)
```

### Key Technical Decisions

#### Decision 1: Bash 3.2+ Compatibility (not 4.0+)

- **Rationale**: Current install.sh requires 4.0+ but macOS default is Bash 3.2
- **Issue**: Bash 4.0 check at line 145 blocks macOS default shell
- **Recommendation**: Downgrade requirement to 3.2+, avoid Bash 4.0+ features
- **Impact**: Must test all associative arrays, ${var,,} lowercase expansion, etc.

**Critical Compatibility Notes**:

```bash
# AVOID (Bash 4.0+)
declare -A assoc_array  # Associative arrays
${var,,}                # Lowercase expansion
${var^^}                # Uppercase expansion

# USE INSTEAD (Bash 3.2 compatible)
declare -a indexed_array
echo "$var" | tr '[:upper:]' '[:lower:]'  # Lowercase
echo "$var" | tr '[:lower:]' '[:upper:]'  # Uppercase
```

**Conflicts Found in Current install.sh**:

- Line 145: Requires Bash 4.0+ but rejects macOS default shell
- Line 211: `${name,,}` lowercase expansion (Bash 4.0+)
- Line 430: `${ASSISTANT_NAME^^}` uppercase expansion (Bash 4.0+)

#### Decision 2: Function-Based Architecture (not variable exports)

- **Rationale**: Functions can be tested independently, don't pollute global namespace
- **Pattern**: Each utility file exports functions, not variables (except readonly constants)
- **Example**:

```bash
# colors.sh exports functions, not variables
color_red() { echo -e "\033[0;31m${1}\033[0m"; }
color_green() { echo -e "\033[0;32m${1}\033[0m"; }

# NOT: export RED='\033[0;31m' (pollution risk)
```

#### Decision 3: Security-First Implementation

- **Rationale**: Shared library = 2x impact of vulnerabilities (AIDA + dotfiles)
- **Controls**:
  - Input sanitization for all user-provided values
  - Path canonicalization before sourcing files
  - File permission validation (reject world-writable libraries)
  - No eval, no unquoted expansions, no command injection vectors

- **Testing**: Security-focused unit tests for each validation function

#### Decision 4: Version Compatibility Semantics

- **Recommendation**: Major.minor match required (0.1.x ↔ 0.1.x only) for v0.1.2
- **Rationale**: Conservative approach during initial release, relax later when API stable
- **Implementation**:

```bash
# validation.sh
check_version_compatibility() {
    local required_version="$1"
    local actual_version="$2"

    # Extract major.minor (ignore patch)
    local req_major_minor="${required_version%.*}"
    local act_major_minor="${actual_version%.*}"

    if [[ "$req_major_minor" != "$act_major_minor" ]]; then
        return 1  # Incompatible
    fi
    return 0  # Compatible
}
```

### Modularization Strategy

#### Phase 1: Extract to lib/installer-common/

1. **colors.sh** (60 lines) - Self-contained, no dependencies
   - Color code constants (RED, GREEN, YELLOW, BLUE, NC)
   - Optional: Color formatting functions (color_info, color_success, etc.)
   - Terminal capability detection (no-color mode for CI)

2. **logging.sh** (80 lines) - Depends on colors.sh
   - `print_message()` function (lines 105-126 from install.sh)
   - Log levels: info, success, warning, error
   - Optional: Log file output (600 permissions)

3. **validation.sh** (150 lines) - Most complex, security-critical
   - Input validation functions (name, path, version format)
   - Version compatibility checking
   - Path canonicalization (realpath-based)
   - File permission checking
   - Dependency checking (validate_dependencies() from lines 139-172)

4. **platform-detect.sh** (50 lines) - Defer to v0.2.0
   - OS detection (macOS/Linux)
   - Shell detection (bash/zsh)
   - Package manager detection (brew/apt/yum)

#### Phase 2: Refactor install.sh to Use Library

- Replace lines 26-30 (color codes) with `source lib/installer-common/colors.sh`
- Replace lines 105-126 (print_message) with `source lib/installer-common/logging.sh`
- Replace lines 139-172 (validate_dependencies) with `source lib/installer-common/validation.sh`
- Add sourcing logic with error handling at top of install.sh

**Effort Breakdown**:

- Extract utilities: 2 hours (careful function extraction, preserve behavior)
- Security hardening: 2 hours (input sanitization, path canonicalization, permission checks)
- Refactor install.sh: 1 hour (source utilities, test installation)
- Unit tests: 1.5 hours (test each utility file independently)
- Integration tests: 1 hour (test AIDA install → dotfiles source)
- Documentation: 0.5 hours (README.md with sourcing pattern)

**Total: 8 hours** (conservative estimate with security focus)

## 2. Technical Concerns

### Bash Compatibility Issues

#### CRITICAL: Bash Version Mismatch

- Current install.sh requires Bash 4.0+ (line 145)
- macOS default shell is Bash 3.2.57 (2007 vintage, Apple frozen for licensing)
- PRD states "Bash 4.0+ required" but project claims macOS primary platform
- **Resolution Required**: Either require users install Bash 4.0+ via Homebrew OR downgrade to Bash 3.2 compatibility

**Bash 3.2 Compatibility Checklist** (if downgrading):

```bash
# REPLACE THESE IN install.sh
Line 211: ${name,,}          → $(echo "$name" | tr '[:upper:]' '[:lower:]')
Line 430: ${ASSISTANT_NAME^^} → $(echo "$ASSISTANT_NAME" | tr '[:lower:]' '[:upper:]')

# AVOID IN NEW CODE
declare -A assoc_array       # Use indexed arrays instead
[[ ${array[@]} ]]            # Use [[ ${#array[@]} -gt 0 ]]
${var@Q}                     # Quote escaping (Bash 4.4+)
readarray / mapfile          # Use while read loops instead
```

**Recommendation**: Downgrade to Bash 3.2+ for true macOS compatibility, document Bash 4.0+ as "recommended but optional"

### Security Considerations (CRITICAL)

**Command Injection Risks**:

```bash
# VULNERABLE (from install.sh line 193)
read -rp "Enter assistant name: " name
mkdir -p "${HOME}/.claude/${name}"  # What if name="../../../tmp/evil"?

# SECURE (validation.sh must implement)
validate_name() {
    local name="$1"
    # Allowlist: only lowercase alphanumeric + hyphens
    if [[ ! "$name" =~ ^[a-z][a-z0-9-]*$ ]]; then
        return 1
    fi
    # Length check
    if [[ ${#name} -lt 3 || ${#name} -gt 20 ]]; then
        return 1
    fi
    return 0
}
```

**Path Traversal Risks**:

```bash
# VULNERABLE
source "${AIDA_DIR}/lib/installer-common/colors.sh"
# What if AIDA_DIR="../../malicious"?

# SECURE (validation.sh must implement)
canonicalize_path() {
    local path="$1"

    # Use realpath if available (GNU coreutils)
    if command -v realpath &>/dev/null; then
        realpath -e "$path" 2>/dev/null
        return $?
    fi

    # Fallback: Python-based canonicalization
    python3 -c "import os; print(os.path.realpath('$path'))" 2>/dev/null
}

# Usage
AIDA_DIR=$(canonicalize_path "${HOME}/.aida") || exit 1
if [[ ! "$AIDA_DIR" =~ ^${HOME}/ ]]; then
    echo "Error: AIDA_DIR must be under home directory"
    exit 1
fi
```

**File Permission Validation**:

```bash
# validation.sh must check library files not world-writable
check_file_permissions() {
    local file="$1"

    # Check exists and readable
    if [[ ! -r "$file" ]]; then
        return 1
    fi

    # Check not world-writable (security risk)
    local perms
    perms=$(stat -f "%Lp" "$file" 2>/dev/null || stat -c "%a" "$file" 2>/dev/null)

    # Reject if world-writable (last digit = 2, 3, 6, 7)
    if [[ "$perms" =~ [2367]$ ]]; then
        echo "Error: $file is world-writable (insecure)" >&2
        return 1
    fi

    return 0
}
```

**Code Execution via eval/source**:

- **Risk**: Sourcing attacker-controlled files = arbitrary code execution
- **Mitigation**:
  - Validate AIDA_DIR path before sourcing (realpath-based)
  - Check file permissions before sourcing (not world-writable)
  - Checksum validation for VERSION file (optional but recommended)

- **Never use eval()**: No dynamic code generation in utilities

### Maintainability Concerns

**API Stability Requirements**:

- Once dotfiles depends on installer-common, breaking changes require coordinated releases
- **Solution**: Semantic versioning + documented deprecation policy
- **Example**: If changing function signature, keep old version with deprecation warning for 1 minor version

**Testing Complexity**:

- Unit tests must mock sourced dependencies (colors.sh in logging.sh tests)
- Integration tests must test both AIDA standalone and dotfiles sourcing scenarios
- Version compatibility tests require multiple AIDA versions installed

**Documentation Burden**:

- Every exported function needs documented API contract (parameters, return codes, side effects)
- Sourcing pattern must be documented with examples
- Version compatibility rules must be clear and testable

### Technical Risks

#### Risk 1: Dev Mode Symlink Sourcing

- **Scenario**: AIDA installed with `--dev` (symlink to repo), dotfiles sources utilities
- **Question**: Does `source` follow symlinks correctly?
- **Test Required**: Verify sourcing works when `~/.aida/` is symlink to dev directory
- **Mitigation**: Use realpath-based canonicalization before sourcing

#### Risk 2: Circular Dependency via Version Checking

- **Scenario**: AIDA checks dotfiles version, dotfiles checks AIDA version → deadlock
- **Mitigation**: AIDA never checks for dotfiles (one-way dependency)
- **Enforcement**: Code review + integration tests

#### Risk 3: Race Conditions During Installation

- **Scenario**: User runs AIDA install + dotfiles install simultaneously
- **Impact**: File conflicts, partial installations, corrupted state
- **Mitigation**: Lock file mechanism (flock or directory-based lock)
- **Example**:

```bash
# validation.sh
acquire_lock() {
    local lockfile="${HOME}/.aida/.install.lock"
    local timeout=60
    local elapsed=0

    while [[ -f "$lockfile" ]]; do
        if [[ $elapsed -ge $timeout ]]; then
            echo "Error: Another installation in progress (timeout after ${timeout}s)"
            return 1
        fi
        sleep 1
        elapsed=$((elapsed + 1))
    done

    echo "$$" > "$lockfile"
    trap "rm -f '$lockfile'" EXIT INT TERM
}
```

#### Risk 4: Shell Compatibility Between Bash and Zsh

- **Scenario**: macOS users may use zsh (default since Catalina), dotfiles may run in zsh
- **Impact**: Bash-specific constructs fail in zsh
- **Mitigation**: Test utilities in both bash and zsh, avoid shell-specific features
- **Note**: Current install.sh uses `#!/usr/bin/env bash` shebang → forces bash execution

## 3. Dependencies & Integration

### Systems/Components Affected

**Direct Impact**:

1. **AIDA install.sh** - Refactored to source lib/installer-common/
2. **lib/installer-common/** - New directory structure
3. **VERSION file** - Already exists (no changes needed)
4. **Dotfiles installer** - External repository (separate PR)

**Indirect Impact**:

1. **CI/CD workflows** - Must test installer refactoring
2. **Documentation** - Installation docs reference install.sh behavior
3. **User configurations** - Existing ~/.aida/ installations unaffected (forward compatibility)

### Integration Points and Concerns

#### Integration Point 1: AIDA Internal (Dogfooding)

- **Pattern**: install.sh sources from `${SCRIPT_DIR}/lib/installer-common/`
- **Concern**: Must work in both repository and installed contexts
- **Solution**:

```bash
# Detect if running from repository or installed location
if [[ -f "${SCRIPT_DIR}/lib/installer-common/colors.sh" ]]; then
    # Running from repository (or dev mode)
    INSTALLER_COMMON="${SCRIPT_DIR}/lib/installer-common"
elif [[ -f "${HOME}/.aida/lib/installer-common/colors.sh" ]]; then
    # Running from installed location
    INSTALLER_COMMON="${HOME}/.aida/lib/installer-common"
else
    echo "Error: installer-common library not found"
    exit 1
fi

source "${INSTALLER_COMMON}/colors.sh" || exit 1
source "${INSTALLER_COMMON}/logging.sh" || exit 1
source "${INSTALLER_COMMON}/validation.sh" || exit 1
```

#### Integration Point 2: Dotfiles External (Cross-Repo)

- **Pattern**: Dotfiles sources from `${HOME}/.aida/lib/installer-common/`
- **Concerns**:
  - AIDA not installed → clear error message
  - AIDA version incompatible → version check + actionable guidance
  - Partial AIDA installation → validate lib/installer-common/ exists

- **Solution**: Version compatibility checking in dotfiles installer

```bash
# dotfiles install.sh
AIDA_DIR="${HOME}/.aida"
REQUIRED_AIDA_VERSION="0.1.2"

# Check AIDA installed
if [[ ! -d "$AIDA_DIR" ]]; then
    echo "Error: AIDA framework required but not found"
    echo "Install AIDA first: https://github.com/oakensoul/claude-personal-assistant"
    exit 1
fi

# Check version compatibility
AIDA_VERSION=$(cat "${AIDA_DIR}/VERSION" 2>/dev/null)
if ! check_version_compatibility "$REQUIRED_AIDA_VERSION" "$AIDA_VERSION"; then
    echo "Error: AIDA version $AIDA_VERSION incompatible (requires $REQUIRED_AIDA_VERSION)"
    echo "Upgrade AIDA: cd ~/.aida && git pull && ./install.sh"
    exit 1
fi

# Source utilities
source "${AIDA_DIR}/lib/installer-common/colors.sh" || exit 1
source "${AIDA_DIR}/lib/installer-common/logging.sh" || exit 1
```

#### Integration Point 3: Version File Usage

- **Current**: VERSION file at repository root (single line: "0.1.1")
- **Usage**: Read once at install.sh start (lines 33-40)
- **New Usage**: Dotfiles reads VERSION to check compatibility
- **Concern**: VERSION file format must remain stable (single-line semantic version)
- **Recommendation**: Document VERSION format in lib/installer-common/README.md

### How to Safely Source Utilities

**Safety Checklist**:

1. **Validate AIDA_DIR exists and is under $HOME**:

```bash
if [[ ! -d "$AIDA_DIR" ]] || [[ ! "$AIDA_DIR" =~ ^${HOME}/ ]]; then
    echo "Error: Invalid AIDA_DIR: $AIDA_DIR"
    exit 1
fi
```

2. **Canonicalize paths before sourcing**:

```bash
AIDA_DIR=$(realpath "${HOME}/.aida" 2>/dev/null) || exit 1
```

3. **Check file permissions before sourcing**:

```bash
check_file_permissions "${AIDA_DIR}/lib/installer-common/colors.sh" || exit 1
```

4. **Source with error handling**:

```bash
source "${AIDA_DIR}/lib/installer-common/colors.sh" || {
    echo "Error: Failed to source colors.sh"
    exit 1
}
```

5. **Validate functions available after sourcing**:

```bash
if ! declare -f print_message &>/dev/null; then
    echo "Error: print_message function not loaded from logging.sh"
    exit 1
fi
```

**Complete Safe Sourcing Pattern** (for lib/installer-common/README.md):

```bash
#!/usr/bin/env bash
set -euo pipefail

# Configuration
readonly AIDA_DIR="${HOME}/.aida"
readonly INSTALLER_COMMON="${AIDA_DIR}/lib/installer-common"

# Validate AIDA installation
if [[ ! -d "$AIDA_DIR" ]]; then
    echo "Error: AIDA not installed at $AIDA_DIR"
    exit 1
fi

if [[ ! -d "$INSTALLER_COMMON" ]]; then
    echo "Error: AIDA installation incomplete (missing lib/installer-common/)"
    exit 1
fi

# Canonicalize path (security)
AIDA_CANONICAL=$(realpath "$AIDA_DIR" 2>/dev/null) || {
    echo "Error: Cannot resolve AIDA_DIR path"
    exit 1
}

if [[ ! "$AIDA_CANONICAL" =~ ^${HOME}/ ]]; then
    echo "Error: AIDA_DIR must be under home directory"
    exit 1
fi

# Source utilities with error handling
for lib in colors logging validation; do
    libfile="${INSTALLER_COMMON}/${lib}.sh"

    if [[ ! -r "$libfile" ]]; then
        echo "Error: Cannot read $libfile"
        exit 1
    fi

    # Check not world-writable (security)
    perms=$(stat -f "%Lp" "$libfile" 2>/dev/null || stat -c "%a" "$libfile" 2>/dev/null)
    if [[ "$perms" =~ [2367]$ ]]; then
        echo "Error: $libfile is world-writable (security risk)"
        exit 1
    fi

    source "$libfile" || {
        echo "Error: Failed to source $libfile"
        exit 1
    }
done

# Validate functions loaded
required_functions=(print_message check_version_compatibility)
for func in "${required_functions[@]}"; do
    if ! declare -f "$func" &>/dev/null; then
        echo "Error: Required function not loaded: $func"
        exit 1
    fi
done

# Version compatibility check
REQUIRED_VERSION="0.1.2"
ACTUAL_VERSION=$(cat "${AIDA_DIR}/VERSION" 2>/dev/null || echo "unknown")

if ! check_version_compatibility "$REQUIRED_VERSION" "$ACTUAL_VERSION"; then
    echo "Error: AIDA version incompatible"
    echo "  Required: $REQUIRED_VERSION"
    echo "  Actual:   $ACTUAL_VERSION"
    exit 1
fi

# Ready to use utilities
print_message "success" "AIDA utilities loaded successfully"
```

## 4. Effort & Complexity

### Estimated Complexity

#### Overall Complexity: MEDIUM

**Breakdown**:

- **Core Logic**: LOW (extraction straightforward, functions already exist)
- **Security Hardening**: HIGH (path validation, input sanitization, permission checks)
- **Testing**: MEDIUM (unit tests simple, integration tests require AIDA + dotfiles)
- **Documentation**: LOW (sourcing pattern clear, API contract simple)

### Key Effort Drivers

#### Driver 1: Security Implementation (40% of effort)

- Input sanitization for all user-provided values
- Path canonicalization (realpath-based)
- File permission checking before sourcing
- Version file checksum validation (optional)
- Security-focused unit tests

#### Driver 2: Bash Compatibility Resolution (20% of effort)

- Determine Bash 3.2 vs 4.0+ requirement
- Replace Bash 4.0+ features if downgrading to 3.2
- Test on macOS default Bash 3.2.57
- Test on Linux Bash 5.x
- Document compatibility requirements

#### Driver 3: Testing Infrastructure (25% of effort)

- Unit tests for each utility file (colors.sh, logging.sh, validation.sh)
- Integration tests (AIDA install → dotfiles source)
- Version compatibility tests (multiple AIDA versions)
- Security tests (command injection, path traversal)
- CI/CD integration

#### Driver 4: Refactoring install.sh (15% of effort)

- Extract functions to lib/installer-common/
- Add sourcing logic with error handling
- Test installation still works
- Handle both repository and installed contexts
- Maintain backward compatibility

### Risk Areas

**High Risk**:

1. **Security vulnerabilities** - Command injection, path traversal, code execution via sourcing
2. **Bash compatibility** - Bash 3.2 vs 4.0+ feature usage
3. **Version compatibility** - Breaking changes affect dotfiles installer

**Medium Risk**:

1. **Dev mode symlink sourcing** - Does source follow symlinks correctly?
2. **Concurrent installations** - Race conditions, file conflicts
3. **Shell compatibility** - Bash vs zsh differences

**Low Risk**:

1. **API stability** - Functions simple, unlikely to change frequently
2. **Documentation** - Sourcing pattern straightforward

## 5. Questions & Clarifications

### Technical Questions Needing Answers

#### Q1: Bash Version Requirement - 3.2 or 4.0+?

- **Current State**: install.sh requires 4.0+ (line 145) but uses Bash 4.0+ features (lines 211, 430)
- **Conflict**: PRD states Bash 4.0+ but project claims macOS primary (default Bash 3.2)
- **Impact**: CRITICAL - determines feature set and macOS compatibility
- **Options**:
  - A: Require Bash 4.0+ (users must install via Homebrew)
  - B: Downgrade to Bash 3.2 (replace Bash 4.0+ features)
  - C: Detect version and use feature-appropriate code paths

- **Recommendation**: Option B for widest compatibility, document Bash 4.0+ as "recommended"
- **Decision Owner**: Product Manager + Configuration Specialist

#### Q2: Checksum Validation for VERSION File?

- **Context**: PRD recommends checksum validation for security
- **Question**: Should VERSION file have companion VERSION.sha256 checksum?
- **Impact**: MEDIUM - security enhancement but adds complexity
- **Trade-off**: Security vs simplicity
- **Recommendation**: Defer to v0.2.0, focus on path/input validation for v0.1.2
- **Decision Owner**: Privacy & Security Auditor

#### Q3: Bundled Fallback Utilities in Dotfiles?

- **Context**: PRD suggests dotfiles bundle fallback utilities for standalone use
- **Question**: Should dotfiles work without AIDA (fallback mode)?
- **Impact**: HIGH - affects architecture (one-way vs optional dependency)
- **Options**:
  - A: Hard dependency (dotfiles requires AIDA)
  - B: Soft dependency (dotfiles bundles minimal utilities, uses AIDA if available)

- **Recommendation**: Option A for v0.1.2 (simpler), Option B for v0.2.0 (flexible)
- **Decision Owner**: Product Manager + Integration Specialist

#### Q4: Separate API Version for installer-common?

- **Context**: VERSION reflects AIDA framework version (0.1.1), not library API version
- **Question**: Should lib/installer-common/ have its own API_VERSION?
- **Impact**: MEDIUM - enables independent library versioning
- **Trade-off**: Complexity (2 versions) vs flexibility (library evolves independently)
- **Recommendation**: Defer to v0.2.0, use AIDA VERSION for v0.1.2
- **Decision Owner**: Configuration Specialist

### Decisions to Be Made

#### Decision 1: Version Compatibility Semantics

- **Question**: Major.minor match (strict) or major match with minor forward-compatibility?
- **Options**:
  - A: Strict major.minor match (0.1.x ↔ 0.1.x only)
  - B: Major match, minor forward-compatible (AIDA 0.2 works with dotfiles 0.1)

- **Recommendation**: Option A for v0.1.2 (conservative), relax to B once API stable
- **Impact**: Determines upgrade/blocking behavior
- **Owner**: Product Manager

#### Decision 2: Error Verbosity Level

- **Question**: Verbose errors (helps debugging) vs generic errors (security-conscious)?
- **Options**:
  - A: Verbose to stdout (user-friendly debugging)
  - B: Generic to stdout, detailed to log file (600 permissions)

- **Recommendation**: Option B (security-conscious UX)
- **Impact**: User experience vs information disclosure
- **Owner**: Shell Systems UX Designer + Privacy & Security Auditor

#### Decision 3: Lock File Mechanism

- **Question**: Should installers use lock files to prevent concurrent execution?
- **Impact**: Prevents race conditions but adds complexity
- **Recommendation**: Yes, implement simple directory-based lock (mkdir atomic)
- **Owner**: Shell Script Specialist (implementation decision)

### Areas Needing Investigation

#### Investigation 1: Dev Mode Symlink Behavior

- **Question**: Does `source` command follow symlinks when AIDA_DIR is symlink to repo?
- **Test**: Install AIDA with `--dev`, verify sourcing works from dotfiles
- **Timeline**: Before implementation starts
- **Owner**: Shell Script Specialist

#### Investigation 2: macOS Bash 3.2 Feature Compatibility

- **Question**: Which Bash 4.0+ features are used in current install.sh?
- **Audit Required**: Scan for associative arrays, ${var,,}, ${var^^}, etc.
- **Timeline**: Before refactoring starts
- **Owner**: Shell Script Specialist

#### Investigation 3: realpath Availability

- **Question**: Is realpath available on macOS by default or requires coreutils?
- **Context**: macOS lacks GNU realpath, may need Python fallback
- **Test**: Check `/usr/bin/realpath` on clean macOS vs Linux
- **Timeline**: Before validation.sh implementation
- **Owner**: Shell Script Specialist

#### Investigation 4: stat Command Portability

- **Question**: Does file permission checking work on both macOS (BSD stat) and Linux (GNU stat)?
- **Context**: BSD stat uses `-f`, GNU stat uses `-c`
- **Test**: `stat -f "%Lp" file` (macOS) vs `stat -c "%a" file` (Linux)
- **Timeline**: Before validation.sh implementation
- **Owner**: Shell Script Specialist

## Summary & Recommendations

### Implementation Readiness

**Confidence Level**: HIGH (80%)

- Core logic straightforward (extract existing functions)
- Security patterns well-understood (input validation, path canonicalization)
- Testing strategy clear (unit + integration tests)
- Documentation pattern simple (sourcing example + API contract)

**Blocking Issues**:

1. **Bash version requirement decision** (3.2 vs 4.0+) - CRITICAL
2. **Version compatibility semantics** (strict vs forward-compatible) - HIGH

### Recommended Next Steps

1. **Immediate** (before implementation):
   - Resolve Bash version requirement (Q1)
   - Audit install.sh for Bash 4.0+ features
   - Test dev mode symlink sourcing (Investigation 1)
   - Test realpath/stat portability (Investigations 3, 4)

2. **Phase 1 Implementation** (v0.1.2):
   - Create lib/installer-common/ structure
   - Extract colors.sh (self-contained)
   - Extract logging.sh (depends on colors.sh)
   - Extract validation.sh (security-critical, most complex)
   - Implement security controls (input sanitization, path canonicalization)
   - Refactor install.sh to source utilities
   - Unit tests + integration tests
   - Documentation (README.md with sourcing pattern)

3. **Phase 2 Enhancements** (v0.2.0):
   - Add platform-detect.sh
   - Implement checksum validation for VERSION file
   - Smart version mismatch handling (auto-upgrade option)
   - Bundled fallback utilities in dotfiles
   - Separate API version for installer-common

### Key Takeaways

**Strengths**:

- Clean modularization opportunity (functions already exist)
- Clear separation of concerns (colors, logging, validation)
- Strong security focus in PRD (input sanitization, path validation)
- Dogfooding approach (AIDA uses its own library)

**Challenges**:

- Bash compatibility mismatch (claims macOS primary but requires Bash 4.0+)
- Security implementation adds significant complexity (40% of effort)
- Version compatibility coordination between repos
- Testing requires both AIDA and dotfiles installations

**Critical Success Factors**:

1. Resolve Bash version requirement before starting
2. Implement security controls from day one (no shortcuts)
3. Test on both macOS (Bash 3.2) and Linux (Bash 5.x)
4. Document sourcing pattern clearly with security guidelines
5. Comprehensive integration tests (AIDA → dotfiles sourcing)

---

## Appendices

### A. Bash 3.2 Compatibility Reference

**Features to AVOID** (Bash 4.0+ only):

```bash
# Associative arrays
declare -A assoc=(["key"]="value")

# Case modification
${var,,}    # Lowercase
${var^^}    # Uppercase
${var~}     # Toggle case

# Globstar
shopt -s globstar
**/*.sh

# readarray/mapfile
readarray -t lines < file
```

**Bash 3.2 Compatible ALTERNATIVES**:

```bash
# Use indexed arrays instead of associative
declare -a array
array[0]="value"

# Use tr for case modification
lowercase=$(echo "$var" | tr '[:upper:]' '[:lower:]')
uppercase=$(echo "$var" | tr '[:lower:]' '[:upper:]')

# Use find instead of globstar
find . -name "*.sh"

# Use while read instead of readarray
while IFS= read -r line; do
    lines+=("$line")
done < file
```

### B. Security Testing Checklist

**Command Injection Tests**:

```bash
# Test 1: Malicious assistant name
./install.sh
# Enter: "test; rm -rf /"
# Expected: Rejected (name validation)

# Test 2: Path traversal in AIDA_DIR
AIDA_DIR="../../etc/passwd" ./install.sh
# Expected: Rejected (path canonicalization)

# Test 3: World-writable library file
chmod 666 ~/.aida/lib/installer-common/colors.sh
./dotfiles/install.sh
# Expected: Rejected (permission check)
```

**Path Traversal Tests**:

```bash
# Test 4: Symlink to /etc
ln -s /etc ~/.aida/lib/installer-common/colors.sh
./dotfiles/install.sh
# Expected: Rejected (canonicalization + home directory check)

# Test 5: Relative path with ..
AIDA_DIR="~/.aida/../.aida" ./install.sh
# Expected: Canonicalized to ~/.aida
```

### C. Shellcheck Configuration

**Recommended .shellcheckrc**:

```text
# Disable SC1090 (can't follow sourced files)
disable=SC1090

# Disable SC2034 (unused variables) for exports
disable=SC2034

# Enable all optional checks
enable=all
```

**Run Shellcheck**:

```bash
shellcheck -x install.sh
shellcheck lib/installer-common/*.sh
```

---

**Analysis Complete**: Ready for technical specification development

**Estimated Implementation Time**: 8 hours (with security hardening)

**Risk Level**: MEDIUM (security complexity, bash compatibility)

**Recommendation**: Proceed with Phase 1 implementation after resolving Bash version requirement
