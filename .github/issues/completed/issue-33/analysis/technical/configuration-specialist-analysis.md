---
title: "Configuration Specialist Technical Analysis - Issue #33"
description: "Technical implementation guidance for shared installer-common library and VERSION file"
issue: "#33"
analyst: "configuration-specialist"
date: "2025-10-06"
analysis_type: "technical"
status: "draft"
---

# Configuration Specialist Technical Analysis - Issue #33

## Executive Summary

Technical implementation analysis for shared installer utilities library and VERSION-based compatibility checking. Focus: configuration file formats, version parsing algorithms, validation patterns, and integration architecture.

## 1. Implementation Approach

### VERSION File Structure

## Current State

```text
0.1.1

```

## Technical Specification

- Format: Plain text, single line, semantic version
- Pattern: `MAJOR.MINOR.PATCH` (no prefixes like 'v')
- Encoding: UTF-8
- Line ending: Single newline (POSIX compliant)
- Size: ~10 bytes (minimal overhead)
- Parsing: Shell-native (no external tools needed)

## Why This Format

- Shell-friendly: `VERSION=$(cat VERSION)` works directly
- Human-readable: No JSON/YAML complexity
- Git-friendly: Easy to track changes
- Tool-friendly: Works with standard version tools
- POSIX-compliant: Works on all platforms

### Configuration File Format - Version Requirements

**Location:** `lib/installer-common/version-requirements.txt` (optional)

**Format:** Plain text, one requirement per line

```text
# Version requirements format
# Supported operators: ==, >=, <=, >, <, !=
# Examples
aida>=0.1.0
aida<1.0.0
```

**Alternative:** Embedded in installer script (simpler for v0.1.2)

```bash
# Embedded version requirements
readonly MIN_AIDA_VERSION="0.1.0"
readonly MAX_AIDA_VERSION="1.0.0"
readonly REQUIRED_MAJOR="0"
```

**Recommendation:** Embedded constants for v0.1.2 (simpler, no external file to parse)

### Version Compatibility Algorithm

## Semantic Versioning Rules

```bash
# Version compatibility function
# Returns: 0 (compatible), 1 (incompatible)
check_version_compatibility() {
    local installed_version="$1"
    local required_version="$2"

    # Parse versions into components
    local -a installed=(${installed_version//./ })
    local -a required=(${required_version//./ })

    local installed_major="${installed[0]}"
    local installed_minor="${installed[1]}"
    local installed_patch="${installed[2]}"

    local required_major="${required[0]}"
    local required_minor="${required[1]}"
    local required_patch="${required[2]}"

    # Rule: Major version must match
    if [[ "$installed_major" != "$required_major" ]]; then
        return 1  # Incompatible
    fi

    # Rule: Minor version must be >= required (forward compatible)
    if [[ "$installed_minor" -lt "$required_minor" ]]; then
        return 1  # Incompatible (too old)
    fi

    # Rule: If minor matches, patch must be >= required
    if [[ "$installed_minor" -eq "$required_minor" ]] && \
       [[ "$installed_patch" -lt "$required_patch" ]]; then
        return 1  # Incompatible (patch too old)
    fi

    return 0  # Compatible
}
```

## Compatibility Matrix

| AIDA Version | Dotfiles Requires | Compatible? | Reason |
|--------------|-------------------|-------------|--------|
| 0.1.1        | >=0.1.0           | ✓           | Minor/patch match |
| 0.2.0        | >=0.1.0           | ✓           | Forward compatible (higher minor) |
| 0.1.0        | >=0.1.1           | ✗           | Patch too old |
| 0.1.5        | >=0.2.0           | ✗           | Minor too old |
| 1.0.0        | >=0.1.0           | ✗           | Major version mismatch |

## Version Parsing Edge Cases

```bash
# Handle malformed versions
validate_version_format() {
    local version="$1"

    # Check format: X.Y.Z where X, Y, Z are integers
    if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Error: Invalid version format '$version'. Expected: MAJOR.MINOR.PATCH" >&2
        return 1
    fi

    return 0
}

# Edge cases to handle
# - Empty version: "0.0.0" (invalid)
# - Missing VERSION file: assume "0.0.0" or fail
# - Version with 'v' prefix: strip it (v0.1.1 → 0.1.1)
# - Extra segments: 0.1.1.beta → reject (strict)
# - Leading zeros: 0.01.1 → accept (parse as integer)
```

### Configuration Validation Approach

## Three-Level Validation

1. **Pre-Installation Validation** (before sourcing utilities)
   - Verify `~/.aida/` exists
   - Verify `~/.aida/VERSION` exists and is readable
   - Verify VERSION format is valid
   - Verify version compatibility

2. **Library Validation** (during sourcing)
   - Verify required utility files exist
   - Verify utilities are readable (permissions)
   - Verify utilities are not world-writable (security)
   - Test that functions loaded correctly

3. **Post-Source Validation** (after sourcing)
   - Verify expected functions are defined
   - Test a sample function call
   - Log which utilities were loaded

## Validation Implementation

```bash
# lib/installer-common/validation.sh

validate_aida_installation() {
    local aida_dir="${HOME}/.aida"
    local errors=0

    # Level 1: Directory structure
    if [[ ! -d "$aida_dir" ]]; then
        echo "Error: AIDA not installed. Directory not found: $aida_dir" >&2
        echo "  Solution: Install AIDA first with: ./install.sh" >&2
        return 1
    fi

    # Level 2: VERSION file
    local version_file="${aida_dir}/VERSION"
    if [[ ! -f "$version_file" ]]; then
        echo "Error: VERSION file missing: $version_file" >&2
        return 1
    fi

    if [[ ! -r "$version_file" ]]; then
        echo "Error: VERSION file not readable: $version_file" >&2
        echo "  Solution: Fix permissions with: chmod 644 $version_file" >&2
        return 1
    fi

    # Level 3: VERSION format
    local version
    version=$(cat "$version_file" | tr -d '[:space:]')

    if ! validate_version_format "$version"; then
        echo "Error: Invalid VERSION format in $version_file" >&2
        echo "  Found: '$version'" >&2
        echo "  Expected: MAJOR.MINOR.PATCH (e.g., 0.1.1)" >&2
        return 1
    fi

    # Level 4: Version compatibility
    if ! check_version_compatibility "$version" "$MIN_AIDA_VERSION"; then
        echo "Error: AIDA version $version is incompatible" >&2
        echo "  Installed: $version" >&2
        echo "  Required:  >=${MIN_AIDA_VERSION}" >&2
        echo "  Solution:  Upgrade AIDA with: cd ~/.aida && git pull && ./install.sh" >&2
        return 1
    fi

    # Level 5: Library files
    local lib_dir="${aida_dir}/lib/installer-common"
    if [[ ! -d "$lib_dir" ]]; then
        echo "Error: Installer library directory missing: $lib_dir" >&2
        echo "  Your AIDA installation may be corrupted." >&2
        echo "  Solution: Reinstall AIDA with: cd ~/.aida && ./install.sh" >&2
        return 1
    fi

    local required_libs=("colors.sh" "logging.sh" "validation.sh")
    for lib in "${required_libs[@]}"; do
        local lib_path="${lib_dir}/${lib}"
        if [[ ! -f "$lib_path" ]]; then
            echo "Error: Required library missing: $lib_path" >&2
            errors=$((errors + 1))
        elif [[ ! -r "$lib_path" ]]; then
            echo "Error: Library not readable: $lib_path" >&2
            echo "  Solution: Fix permissions with: chmod 644 $lib_path" >&2
            errors=$((errors + 1))
        fi

        # Security check: reject world-writable files
        if [[ -w "$lib_path" ]] && [[ $(stat -f "%OLp" "$lib_path") =~ .*[2367].* ]]; then
            echo "Error: Library is world-writable (security risk): $lib_path" >&2
            echo "  Solution: Fix permissions with: chmod 644 $lib_path" >&2
            errors=$((errors + 1))
        fi
    done

    if [[ $errors -gt 0 ]]; then
        return 1
    fi

    return 0
}

# Post-source validation
validate_utilities_loaded() {
    # Check that expected functions exist
    local required_functions=("print_message" "validate_command")

    for func in "${required_functions[@]}"; do
        if ! declare -F "$func" > /dev/null; then
            echo "Error: Required function not loaded: $func" >&2
            return 1
        fi
    done

    return 0
}
```

## 2. Technical Concerns

### Version Parsing Edge Cases

**Issue:** Shell string comparison vs numeric comparison

```bash
# WRONG: String comparison fails
if [[ "0.2.0" > "0.10.0" ]]; then
    # This evaluates TRUE (wrong!) because "2" > "1" lexically
fi

# CORRECT: Numeric comparison
local -a v1=(0 2 0)
local -a v2=(0 10 0)
if [[ "${v1[1]}" -gt "${v2[1]}" ]]; then
    # This evaluates FALSE (correct!)
fi
```

**Solution:** Always parse into integer arrays and compare numerically

**Issue:** Leading zeros

```bash
# Version: 0.01.1 (has leading zero in minor)
# Parse as integer: 0.1.1 (correct)
# Must use arithmetic evaluation to strip leading zeros
local minor=$((10#${version_parts[1]}))  # Force base-10 interpretation
```

**Issue:** Missing VERSION file

```bash
# Fail fast with clear error
version=$(cat ~/.aida/VERSION 2>/dev/null)
if [[ -z "$version" ]]; then
    echo "Error: Could not read AIDA VERSION file" >&2
    echo "  Possible causes:" >&2
    echo "    - AIDA not installed" >&2
    echo "    - VERSION file deleted" >&2
    echo "    - Permission denied" >&2
    exit 1
fi
```

### Configuration File Precedence

**Problem:** Multiple configuration sources

```text
Priority (highest to lowest):
1. Environment variables (AIDA_MIN_VERSION)
2. Command-line arguments (--require-version 0.2.0)
3. Dotfiles configuration file (.aida-requirements)
4. Embedded defaults in script (MIN_AIDA_VERSION)
```

## Implementation

```bash
# Precedence resolution
resolve_version_requirement() {
    # Priority 1: Environment variable
    if [[ -n "${AIDA_MIN_VERSION:-}" ]]; then
        echo "$AIDA_MIN_VERSION"
        return 0
    fi

    # Priority 2: Config file (if exists)
    local config_file=".aida-requirements"
    if [[ -f "$config_file" ]]; then
        local version
        version=$(grep "^min_version=" "$config_file" | cut -d= -f2)
        if [[ -n "$version" ]]; then
            echo "$version"
            return 0
        fi
    fi

    # Priority 3: Default
    echo "$DEFAULT_MIN_VERSION"
}
```

**Recommendation for v0.1.2:** Skip environment/config file, use embedded defaults only (simpler)

### Error Handling for Malformed Versions

**Scenario:** User manually edits VERSION file incorrectly

```bash
# Defensive parsing with detailed errors
parse_version() {
    local version="$1"

    # Strip whitespace
    version=$(echo "$version" | tr -d '[:space:]')

    # Check for common mistakes
    if [[ "$version" =~ ^v ]]; then
        echo "Warning: Stripping 'v' prefix from version" >&2
        version="${version#v}"
    fi

    if [[ "$version" =~ ^[0-9]+\.[0-9]+$ ]]; then
        echo "Error: Version missing PATCH component: $version" >&2
        echo "  Expected: MAJOR.MINOR.PATCH (e.g., 0.1.0)" >&2
        return 1
    fi

    if [[ "$version" =~ [^0-9.] ]]; then
        echo "Error: Version contains invalid characters: $version" >&2
        echo "  Only digits and dots allowed" >&2
        return 1
    fi

    if ! [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Error: Invalid version format: $version" >&2
        echo "  Expected: MAJOR.MINOR.PATCH (e.g., 0.1.1)" >&2
        return 1
    fi

    echo "$version"
}
```

### Technical Risks

## Risk 1: TOCTOU (Time-of-check to time-of-use)

```bash
# BAD: Check then use (race condition)
if [[ -f ~/.aida/VERSION ]]; then
    # File could be deleted here!
    version=$(cat ~/.aida/VERSION)
fi

# GOOD: Try to use, handle failure
version=$(cat ~/.aida/VERSION 2>/dev/null) || {
    echo "Error: Could not read VERSION file" >&2
    exit 1
}
```

## Risk 2: Command injection via version string

```bash
# BAD: Unsafe use of version in command
version=$(cat VERSION)
eval "echo Version: $version"  # DANGEROUS if VERSION contains shell code

# GOOD: Validate before use
if validate_version_format "$version"; then
    echo "Version: $version"  # Safe (no eval)
fi
```

## Risk 3: Symlink following in dev mode

```bash
# Verify source command follows symlinks correctly
# Test case: ~/.aida -> /path/to/repo
source ~/.aida/lib/installer-common/colors.sh  # Should resolve symlink

# Bash's source command DOES follow symlinks by default
# No special handling needed
```

## 3. Dependencies & Integration

### Configuration Files Needed

## Essential (v0.1.2)

1. `VERSION` - Already exists at repository root
2. `lib/installer-common/colors.sh` - Extracted from install.sh
3. `lib/installer-common/logging.sh` - Extracted from install.sh
4. `lib/installer-common/validation.sh` - Extracted + enhanced
5. `lib/installer-common/README.md` - Integration documentation

## Optional (v0.2.0)

6. `lib/installer-common/platform-detect.sh` - OS detection
7. `lib/installer-common/version-check.sh` - Dedicated version logic
8. `.aida-version` - Alternative location for version metadata

## Not Needed

- Configuration YAML/JSON files (too complex for shell)
- Version range files (embedded constants simpler)
- Checksum files (defer to v0.2.0)

### Integration with Existing AIDA Config

## Current AIDA Configuration

```text
~/.aida/
├── VERSION (new, from repository)
├── lib/
│   └── installer-common/ (new)
│       ├── colors.sh
│       ├── logging.sh
│       └── validation.sh
├── personalities/
├── agents/
└── ...

~/.claude/
├── config/
│   └── assistant.yml (existing, unchanged)
└── ...
```

## Integration Points

- VERSION file copied from repo to `~/.aida/VERSION` during install
- Utilities copied/symlinked to `~/.aida/lib/installer-common/`
- No changes to existing configuration files
- Backward compatible (older AIDA installations without lib/ still work)

## Dotfiles Integration

```bash
# In dotfiles installer (pseudo-code)
#!/usr/bin/env bash

# Step 1: Validate AIDA installation
if ! source ~/.aida/lib/installer-common/validation.sh; then
    echo "Error: Could not load AIDA validation utilities" >&2
    exit 1
fi

if ! validate_aida_installation; then
    # Detailed error already printed by validation function
    exit 1
fi

# Step 2: Source utilities
source ~/.aida/lib/installer-common/colors.sh
source ~/.aida/lib/installer-common/logging.sh

# Step 3: Use utilities
print_message "info" "Installing dotfiles with AIDA integration..."
```

### Dependencies on Version Parsing Tools

## No External Dependencies

- Pure Bash implementation (no Python, Ruby, etc.)
- No semver libraries needed
- String manipulation only
- Arithmetic evaluation for numeric comparison

## Why No External Tools

- Reduces installation dependencies
- Works on minimal systems
- Faster (no subprocess overhead)
- Simpler to debug
- More portable

## Bash Version Requirement

- Minimum: Bash 4.0 (for array features)
- Already required by AIDA
- Available on macOS (with Homebrew), Linux (default)

## 4. Effort & Complexity

### Estimated Complexity: **MEDIUM**

## Breakdown

| Component | Complexity | Effort | Rationale |
|-----------|------------|--------|-----------|
| Extract utilities from install.sh | LOW | 1 hour | Straightforward refactoring |
| Create version parsing logic | MEDIUM | 2 hours | Edge case handling |
| Create validation framework | MEDIUM | 2 hours | Multi-level validation |
| Security hardening | MEDIUM | 1 hour | Path validation, permissions |
| Testing | MEDIUM | 2 hours | Multiple scenarios |
| Documentation | LOW | 1 hour | README + integration guide |
| **Total** | **MEDIUM** | **9 hours** | Includes buffer for issues |

## Complexity Drivers

1. **Version Parsing** (HIGH) - Edge cases, numeric comparison vs string comparison
2. **Error Messaging** (MEDIUM) - Clear, actionable errors with context
3. **Security** (HIGH) - Path validation, permission checks, TOCTOU prevention
4. **Testing** (MEDIUM) - Multiple scenarios, edge cases, integration tests

## Low Complexity

- VERSION file format (already exists, no changes)
- Utility extraction (mostly copy-paste)
- Documentation (straightforward)

### Risk Areas

## High Risk

1. **Version Comparison Logic** - Off-by-one errors, incorrect semantics
2. **Security Vulnerabilities** - Command injection, path traversal
3. **Breaking Changes** - Changing API breaks dotfiles

## Medium Risk

4. **Dev Mode Symlinks** - Sourcing from symlinked directories
5. **Platform Differences** - macOS vs Linux stat commands
6. **Missing Error Cases** - Unhandled edge cases cause failures

## Mitigation

- Comprehensive unit tests for version comparison
- Security review before merge
- Semantic versioning + deprecation policy
- Test dev mode explicitly
- Conditional platform detection for stat/etc
- Defensive programming (validate all inputs)

## 5. Questions & Clarifications

### Q1: Should .aida-version be in AIDA or dotfiles repo?

**Context:** VERSION file currently in AIDA root. Should dotfiles have its own?

## Options

- **A:** Single VERSION in AIDA (dotfiles reads it)
- **B:** VERSION in AIDA, .aida-version in dotfiles (dotfiles tracks required AIDA version)
- **C:** VERSION in both (synchronized versions)

**Recommendation:** **Option B**

- AIDA: `VERSION` = "0.1.1" (AIDA framework version)
- Dotfiles: `.aida-version` = ">=0.1.0" (required AIDA version)
- Clear separation of concerns
- Dotfiles can specify version requirements
- AIDA version advances independently

## Implementation

```bash
# In dotfiles installer
REQUIRED_AIDA_VERSION=$(cat .aida-version)  # ">=0.1.0"
INSTALLED_AIDA_VERSION=$(cat ~/.aida/VERSION)  # "0.1.1"

if ! check_version_compatibility "$INSTALLED_AIDA_VERSION" "$REQUIRED_AIDA_VERSION"; then
    echo "Error: AIDA version mismatch"
    exit 1
fi
```

### Q2: Version Compatibility Semantics?

**Context:** Define major.minor.patch compatibility rules

## Options

- **A:** Strict major.minor match (0.1.x ↔ 0.1.x only)
- **B:** Major match, minor forward-compatible (AIDA 0.2 works with dotfiles 0.1)
- **C:** Range-based specification (0.1.0 - 0.3.0)

**Recommendation:** **Option B** (standard semantic versioning)

## Rules

- **Major version** (0 → 1): Breaking changes, must match exactly
- **Minor version** (0.1 → 0.2): New features, backward compatible (forward compatible in direction: newer AIDA works with older dotfiles)
- **Patch version** (0.1.0 → 0.1.1): Bug fixes, fully compatible

## Example

- AIDA 0.2.0 works with dotfiles requiring >=0.1.0 ✓
- AIDA 0.1.0 FAILS with dotfiles requiring >=0.2.0 ✗
- AIDA 1.0.0 FAILS with dotfiles requiring >=0.1.0 ✗ (major mismatch)

**Documentation:** Create `docs/architecture/versioning.md`

### Q3: Configuration Format?

**Context:** How to specify version requirements in dotfiles

## Options

- **A:** YAML config file
- **B:** Environment variables only
- **C:** Shell script with embedded constants
- **D:** Plain text file with version string

**Recommendation:** **Option C for v0.1.2, Option D for v0.2.0**

## Rationale (v0.1.2)

```bash
# In dotfiles installer (embedded constants)
readonly MIN_AIDA_VERSION="0.1.0"
readonly MAX_AIDA_VERSION="1.0.0"

# Simple, no parsing needed
# Easy to update
# No external file dependencies
```

## Future (v0.2.0)

```text
# .aida-version file (plain text)
>=0.1.0
<1.0.0
```

**Why not YAML:** Too complex for simple version string, requires parser

### Q4: What Metadata Beyond Version Number?

**Context:** Should VERSION file include more information?

## Options

- **A:** Plain version only: "0.1.1"
- **B:** Version + date: "0.1.1 2025-10-06"
- **C:** Version + compatibility: "0.1.1 compatible:>=0.1.0"
- **D:** Separate metadata file: VERSION.meta.yml

**Recommendation:** **Option A for now, Option D later**

## Rationale

- Single-line version is simplest to parse
- Date/compatibility can be in Git tags
- If metadata needed later, create separate file (VERSION.meta.yml)
- Don't over-engineer for v0.1.2

## Future Metadata (v1.0+)

```yaml
# VERSION.meta.yml (optional)
version: "0.1.1"
release_date: "2025-10-06"
compatibility_range: ">=0.1.0,<1.0.0"
release_notes: "Added installer-common library"
checksum: "sha256:abc123..."
```

Keep VERSION file simple, add metadata file if needed.

### Q5: How to Handle Version Mismatch?

**Context:** Dotfiles requires AIDA 0.2.0, user has 0.1.1 installed

## Options

- **A:** Hard fail with error message
- **B:** Warn but continue (degraded mode)
- **C:** Auto-upgrade AIDA
- **D:** Prompt user to upgrade

**Recommendation:** **Option A for v0.1.2, Option D for v0.2.0**

## v0.1.2 Implementation

```bash
if ! check_version_compatibility "$aida_version" "$MIN_AIDA_VERSION"; then
    echo "Error: AIDA version $aida_version is too old" >&2
    echo "  Installed: $aida_version" >&2
    echo "  Required:  >=${MIN_AIDA_VERSION}" >&2
    echo "" >&2
    echo "To upgrade AIDA:" >&2
    echo "  cd ~/.aida" >&2
    echo "  git pull origin main" >&2
    echo "  ./install.sh" >&2
    exit 1
fi
```

## v0.2.0 Enhancement

```bash
# Offer to auto-upgrade
echo "AIDA upgrade available: $aida_version → $latest_version"
read -p "Upgrade now? [y/N]: " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
    cd ~/.aida && git pull && ./install.sh
fi
```

## Implementation Checklist

## Phase 1: Core Utilities (3 hours)

- [ ] Create `lib/installer-common/` directory
- [ ] Extract `colors.sh` from install.sh (lines 26-30)
- [ ] Extract `logging.sh` from install.sh (lines 105-126)
- [ ] Extract validation utilities (lines 139-172)
- [ ] Refactor install.sh to source utilities
- [ ] Test AIDA installation still works

## Phase 2: Version Logic (3 hours)

- [ ] Create version parsing functions
- [ ] Create version comparison functions
- [ ] Add version compatibility checking
- [ ] Handle edge cases (malformed versions)
- [ ] Add detailed error messages

## Phase 3: Integration & Documentation (3 hours)

- [ ] Create `lib/installer-common/README.md`
- [ ] Document sourcing pattern for dotfiles
- [ ] Add integration tests
- [ ] Security review (path validation, permissions)
- [ ] Test dev mode (symlinked installation)

## Total Estimated Effort: 9 hours

## Related Files

- `/Users/oakensoul/Developer/oakensoul/claude-personal-assistant/VERSION`
- `/Users/oakensoul/Developer/oakensoul/claude-personal-assistant/install.sh`
- `.github/issues/in-progress/issue-33/prd.md`
- `.github/issues/in-progress/issue-33/analysis/product/configuration-specialist-analysis.md`

## Next Steps

1. **Product Manager**: Resolve open questions (Q1-Q5)
2. **Shell Script Specialist**: Create technical specification
3. **Implementation**: Extract utilities, create version logic
4. **Testing**: Validate all scenarios
5. **Documentation**: Integration guide for dotfiles
