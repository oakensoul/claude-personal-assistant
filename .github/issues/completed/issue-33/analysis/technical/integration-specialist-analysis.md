---
title: "Integration Specialist Technical Analysis: Issue #33"
description: "Cross-repository integration patterns and runtime sourcing for shared installer library"
issue: "#33"
analyst: "integration-specialist"
created: "2025-10-06"
status: "DRAFT"
---

# Integration Specialist Analysis: Issue #33

**Issue**: Support dotfiles installer integration - shared installer-common library and VERSION file

**Focus**: Cross-repository integration patterns, runtime sourcing security, version coupling, and filesystem dependencies

## 1. Implementation Approach

### Safe Sourcing Pattern

**Core sourcing mechanism** for dotfiles to use AIDA utilities:

```bash
# dotfiles/install.sh - Safe sourcing pattern

# Step 1: Check if AIDA is installed
AIDA_DIR="${HOME}/.aida"
INSTALLER_COMMON="${AIDA_DIR}/lib/installer-common"

if [[ ! -d "$AIDA_DIR" ]]; then
    echo "AIDA framework not found at ${AIDA_DIR}"
    echo "Install AIDA first: https://github.com/oakensoul/claude-personal-assistant"
    exit 1
fi

# Step 2: Validate VERSION compatibility BEFORE sourcing utilities
AIDA_VERSION_FILE="${AIDA_DIR}/VERSION"
if [[ ! -f "$AIDA_VERSION_FILE" ]]; then
    echo "Error: VERSION file missing from AIDA installation"
    exit 1
fi

AIDA_VERSION=$(cat "$AIDA_VERSION_FILE")
DOTFILES_REQUIRED_VERSION="0.1.0"  # Minimum AIDA version required

# Step 3: Check version compatibility (implemented in utility)
# NOTE: Cannot use validation.sh until version check passes
if ! check_version_compatibility "$AIDA_VERSION" "$DOTFILES_REQUIRED_VERSION"; then
    echo "Error: AIDA version incompatible"
    echo "  Found: ${AIDA_VERSION}"
    echo "  Required: ${DOTFILES_REQUIRED_VERSION}+"
    exit 1
fi

# Step 4: Canonicalize paths (security control)
INSTALLER_COMMON=$(realpath "$INSTALLER_COMMON")

# Step 5: Validate library exists and is readable
if [[ ! -d "$INSTALLER_COMMON" ]] || [[ ! -r "$INSTALLER_COMMON" ]]; then
    echo "Error: Installer library not found or not readable: ${INSTALLER_COMMON}"
    exit 1
fi

# Step 6: Source utilities in dependency order
source "${INSTALLER_COMMON}/colors.sh"     || exit 1
source "${INSTALLER_COMMON}/logging.sh"    || exit 1
source "${INSTALLER_COMMON}/validation.sh" || exit 1

# Step 7: Now safe to use utilities
print_message "success" "AIDA installer utilities loaded (v${AIDA_VERSION})"
```

**Key security controls**:

- Version validation BEFORE sourcing (prevents API mismatches)
- Path canonicalization with `realpath` (prevents path traversal)
- Existence and readability checks (prevents sourcing from invalid paths)
- Exit on source failure (fail-fast, don't continue with broken state)

### Version Checking Implementation

**Bootstrap version check** (cannot use utilities yet):

```bash
# lib/installer-common/version-bootstrap.sh
# Minimal version checking before sourcing utilities

check_version_compatibility() {
    local found_version="$1"
    local required_version="$2"

    # Parse versions (MAJOR.MINOR.PATCH)
    IFS='.' read -r found_major found_minor found_patch <<< "$found_version"
    IFS='.' read -r req_major req_minor req_patch <<< "$required_version"

    # Major version must match exactly
    if [[ "$found_major" != "$req_major" ]]; then
        return 1
    fi

    # Minor version: found >= required (forward compatibility)
    if [[ "$found_minor" -lt "$req_minor" ]]; then
        return 1
    fi

    # Patch version: ignored for compatibility (API stable within minor)
    return 0
}
```

**Full version checking** (in validation.sh):

```bash
# lib/installer-common/validation.sh

validate_aida_version() {
    local version_file="${1:-${HOME}/.aida/VERSION}"
    local required_major="$2"
    local required_minor="$3"

    # Validate VERSION file exists and is readable
    if [[ ! -f "$version_file" ]] || [[ ! -r "$version_file" ]]; then
        print_message "error" "VERSION file not found or not readable: ${version_file}"
        return 1
    fi

    # Validate file permissions (should not be world-writable)
    local perms
    perms=$(stat -f %Mp%Lp "$version_file" 2>/dev/null)
    if [[ "$perms" =~ [2367]$ ]]; then  # World-writable bit set
        print_message "error" "VERSION file is world-writable (security risk): ${version_file}"
        return 1
    fi

    # Read version
    local version
    version=$(cat "$version_file")

    # Validate format (MAJOR.MINOR.PATCH)
    if ! [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        print_message "error" "Invalid version format: ${version}"
        return 1
    fi

    # Parse and compare
    IFS='.' read -r major minor patch <<< "$version"

    if [[ "$major" -ne "$required_major" ]]; then
        print_message "error" "AIDA major version mismatch (found: ${major}, required: ${required_major})"
        return 1
    fi

    if [[ "$minor" -lt "$required_minor" ]]; then
        print_message "error" "AIDA minor version too old (found: ${minor}, required: ${required_minor}+)"
        return 1
    fi

    print_message "success" "AIDA version compatible: ${version}"
    return 0
}
```

### Error Handling for Missing/Incompatible AIDA

**Graceful degradation strategy**:

```bash
# dotfiles/install.sh - Graceful AIDA handling

install_with_aida_check() {
    if ! check_aida_available; then
        print_warning "AIDA framework not found or incompatible"
        print_info "Proceeding with dotfiles installation only"
        print_info "To enable AIDA integration:"
        print_info "  1. Install AIDA: https://github.com/oakensoul/claude-personal-assistant"
        print_info "  2. Re-run dotfiles install: cd ~/dotfiles && ./install.sh"

        # Use bundled minimal utilities
        source "${DOTFILES_DIR}/lib/minimal-utils.sh"
        install_dotfiles_standalone
        return 0
    fi

    # AIDA available - use full integration
    source_aida_utilities
    install_dotfiles_with_aida
}
```

### Offline Installation Considerations

**Challenge**: Dotfiles installer may need to clone AIDA (requires internet)

**Solution options**:

1. **v0.1.2 (MVP)**: Require AIDA pre-installed (no auto-clone)
2. **v0.2.0**: Bundle minimal utilities for offline fallback
3. **v0.3.0**: Support USB/offline installer bundle

**Recommended for v0.1.2**:

```bash
# Fail fast with clear instructions
if [[ ! -d "${HOME}/.aida" ]]; then
    echo "AIDA framework required but not found."
    echo ""
    echo "Installation options:"
    echo "  1. Online: git clone https://github.com/oakensoul/claude-personal-assistant ~/.aida"
    echo "  2. Offline: Copy AIDA directory from USB to ~/.aida"
    echo ""
    echo "After AIDA installation, re-run: cd ~/dotfiles && ./install.sh"
    exit 1
fi
```

## 2. Technical Concerns

### Bash Sourcing Security

**Threat model**:

- Malicious code in sourced files → arbitrary code execution
- Path traversal → source unintended files
- TOCTOU races → file swapped between check and source
- Symlink attacks → source from unexpected location

**Mitigations**:

```bash
# 1. Canonicalize paths before sourcing
INSTALLER_COMMON=$(realpath "${AIDA_DIR}/lib/installer-common")

# 2. Validate directory ownership (should be user)
owner=$(stat -f %Su "$INSTALLER_COMMON")
if [[ "$owner" != "$USER" ]]; then
    echo "Error: Installer library not owned by current user"
    exit 1
fi

# 3. Validate no world-writable permissions
perms=$(stat -f %Mp%Lp "$INSTALLER_COMMON")
if [[ "$perms" =~ [2367] ]]; then
    echo "Error: Installer library has world-writable permissions"
    exit 1
fi

# 4. Source with subshell test first (validates syntax)
if ! bash -n "${INSTALLER_COMMON}/colors.sh" 2>/dev/null; then
    echo "Error: Syntax error in colors.sh"
    exit 1
fi

# 5. Now safe to source
source "${INSTALLER_COMMON}/colors.sh"
```

### Path Resolution Edge Cases

**Scenarios to handle**:

1. **Symlinked ~/.aida/** (dev mode)

   ```bash
   # Dev mode: ~/.aida/ → ~/Developer/oakensoul/claude-personal-assistant
   # Solution: realpath follows symlinks correctly
   INSTALLER_COMMON=$(realpath "${AIDA_DIR}/lib/installer-common")
   # Result: /Users/oakensoul/Developer/oakensoul/claude-personal-assistant/lib/installer-common
   ```

2. **Relative paths in sourced scripts**

   ```bash
   # Inside colors.sh, references to other files must use absolute paths
   # BAD:  source ../validation.sh
   # GOOD: source "${BASH_SOURCE[0]%/*}/validation.sh"
   #       (resolves relative to script location)
   ```

3. **Non-canonical paths** (contains `.` or `..`)

   ```bash
   # User passes: ~/.aida/../.aida/lib/installer-common
   # Canonicalize: /Users/oakensoul/.aida/lib/installer-common
   INSTALLER_COMMON=$(realpath -e "$INSTALLER_COMMON")  # -e: must exist
   ```

4. **Spaces in paths**

   ```bash
   # Always quote variables
   source "${INSTALLER_COMMON}/colors.sh"  # NOT: source $INSTALLER_COMMON/colors.sh
   ```

### Version Compatibility Semantics

**Semantic versioning application**:

- **MAJOR** (0.x → 1.x): Breaking changes to installer API
  - Dotfiles MUST match major version
  - Example: Change function signatures, remove functions

- **MINOR** (0.1.x → 0.2.x): New features, backward-compatible additions
  - Dotfiles CAN use older minor (forward compatibility)
  - Example: Add new utility functions, add optional parameters

- **PATCH** (0.1.1 → 0.1.2): Bug fixes, no API changes
  - Dotfiles IGNORES patch version (always compatible)
  - Example: Fix logging bug, improve error messages

**Compatibility matrix**:

| AIDA Version | Dotfiles 0.1.x | Dotfiles 0.2.x | Dotfiles 1.0.x |
|--------------|----------------|----------------|----------------|
| 0.1.0        | ✓              | ✗              | ✗              |
| 0.1.5        | ✓              | ✗              | ✗              |
| 0.2.0        | ✓ (compat)     | ✓              | ✗              |
| 1.0.0        | ✗              | ✗              | ✓              |

**Key rule**: AIDA minor can be HIGHER than dotfiles requires (new features ignored), but NOT lower (missing required functions)

### Technical Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| **Code execution via malicious utilities** | CRITICAL | LOW | Path validation, ownership checks, syntax validation before sourcing |
| **Path traversal in sourcing** | HIGH | MEDIUM | realpath canonicalization, reject paths with `..` |
| **Version skew (dotfiles uses removed function)** | HIGH | MEDIUM | Semantic versioning enforcement, compatibility testing, deprecation warnings |
| **Circular dependencies (AIDA sources dotfiles)** | MEDIUM | LOW | Architectural enforcement (AIDA NEVER sources external code), code review |
| **TOCTOU race (file modified between check and source)** | MEDIUM | LOW | Minimize time between check and source, use atomic operations |
| **Symlink following to unintended files** | MEDIUM | MEDIUM | Validate canonical path is within expected directory tree |
| **Dev mode path confusion (symlinks vs copies)** | LOW | HIGH | Consistent use of realpath, document dev mode implications |

## 3. Dependencies & Integration

### Git Requirements

**AIDA repository access**:

- Dotfiles installer MAY clone AIDA if not present (v0.2.0 feature)
- AIDA must be public GitHub repository (already is)
- Version tags must exist for version pinning

**Version pinning strategy**:

```bash
# Dotfiles install.sh - Auto-install AIDA with version pinning
install_aida_if_missing() {
    if [[ -d "${HOME}/.aida" ]]; then
        return 0  # Already installed
    fi

    print_info "AIDA framework not found. Installing compatible version..."

    local required_version="0.1.0"
    local repo_url="https://github.com/oakensoul/claude-personal-assistant.git"

    # Clone specific version tag
    if git clone --branch "v${required_version}" --depth 1 "$repo_url" "${HOME}/.aida"; then
        print_success "AIDA v${required_version} installed"
        return 0
    else
        print_error "Failed to install AIDA"
        return 1
    fi
}
```

### Filesystem Requirements

**Directory structure dependencies**:

```text
~/.aida/                      # REQUIRED: Fixed location (not configurable)
├── VERSION                   # REQUIRED: Single-line semantic version
├── lib/                      # REQUIRED: Library directory
│   └── installer-common/     # REQUIRED: Shared utilities
│       ├── colors.sh         # REQUIRED: Color codes and formatting
│       ├── logging.sh        # REQUIRED: print_message() function
│       └── validation.sh     # REQUIRED: Version and input validation
└── install.sh                # Optional: Not used by dotfiles

~/.claude/                    # Created by AIDA install, not used by dotfiles
~/CLAUDE.md                   # Created by AIDA install, not used by dotfiles
```

**Filesystem permissions**:

- `~/.aida/`: 755 (rwxr-xr-x) - user owns, others can read
- `~/.aida/lib/`: 755 (rwxr-xr-x)
- `~/.aida/lib/installer-common/*.sh`: 644 (rw-r--r--) - not executable (sourced, not run)
- `~/.aida/VERSION`: 644 (rw-r--r--)

**Why not executable**: Sourced files should NOT have execute bit (security best practice)

### Integration with GNU Stow

**Key insight**: `lib/installer-common/` is NOT stowed

**Reason**: Utilities are sourced at install time, not part of user's dotfiles

**Stow package structure**:

```text
~/dotfiles/
├── aida/                     # Stow package for AIDA integration
│   └── .config/
│       └── aida/
│           └── config.yml    # User AIDA config (stowed to ~/.config/aida/)
└── shell/                    # Stow package for shell config
    ├── .bashrc               # Stowed to ~/.bashrc
    └── .zshrc                # Stowed to ~/.zshrc
```

**What gets stowed**: User configuration files
**What doesn't get stowed**: AIDA framework files (live in `~/.aida/`, managed by AIDA installer)

**Sourcing timing**:

1. **Install time**: Dotfiles installer sources from `~/.aida/lib/installer-common/`
2. **Runtime**: Shell configs DON'T source utilities (not needed)
3. **Future installs**: Each install sources utilities fresh

### Dependencies on External Tools

**Required for sourcing pattern**:

- `bash` 4.0+ (version checking, array support)
- `realpath` (path canonicalization) - GNU coreutils
- `stat` (permission checking) - POSIX standard
- `cat` (read VERSION file) - POSIX standard

**Optional for enhanced features**:

- `git` (auto-clone AIDA if missing) - v0.2.0 feature
- `curl`/`wget` (download AIDA tarball) - offline alternative to git

**Platform compatibility**:

- **macOS**: `realpath` not in default install → requires `brew install coreutils`
  - Alternative: `readlink -f` (not portable)
  - Fallback: Pure bash implementation (slower, complex)

- **Linux**: All tools available by default

**Recommendation**: Add `realpath` availability check to `validate_dependencies()`

## 4. Effort & Complexity

### Complexity Estimate: **MEDIUM**

**Breakdown**:

- **Simple parts** (30%):
  - Create directory structure
  - Copy existing functions to utilities
  - Update install.sh to source utilities

- **Medium parts** (50%):
  - Version checking logic (bootstrap + full)
  - Path canonicalization and validation
  - Error handling for edge cases

- **Complex parts** (20%):
  - Security controls (ownership, permissions, TOCTOU)
  - Cross-platform compatibility (macOS vs Linux)
  - Integration testing (version combinations)

### Effort Estimate: **6-8 hours**

**Task breakdown**:

1. **Library structure creation** (1 hour)
   - Create `lib/installer-common/` directory
   - Extract functions from install.sh
   - Split into colors.sh, logging.sh, validation.sh

2. **Version checking implementation** (2 hours)
   - Bootstrap version check (minimal, pre-sourcing)
   - Full version validation (in validation.sh)
   - Compatibility matrix testing

3. **Security hardening** (2 hours)
   - Path canonicalization
   - Ownership and permission validation
   - Syntax checking before sourcing
   - Unit tests for security controls

4. **AIDA installer refactoring** (1 hour)
   - Update install.sh to source utilities
   - Validate installation still works
   - Handle dev mode (symlinks)

5. **Documentation** (1 hour)
   - `lib/installer-common/README.md`
   - Sourcing pattern examples
   - Version compatibility rules

6. **Testing** (1-2 hours)
   - Unit tests for each utility
   - Integration tests (AIDA install → dotfiles sources)
   - Edge case testing (missing files, wrong versions)

### Key Effort Drivers

1. **Security controls** (40% of effort)
   - Must get right first time (no "add security later")
   - Multiple validation layers
   - Platform-specific security checks

2. **Version compatibility logic** (25% of effort)
   - Bootstrap vs full validation (chicken-and-egg)
   - Semantic versioning enforcement
   - Clear error messages for mismatches

3. **Cross-platform compatibility** (20% of effort)
   - macOS lacks `realpath` by default
   - Different `stat` command syntax
   - Platform detection and fallbacks

4. **Testing** (15% of effort)
   - Version combination matrix
   - Edge cases (symlinks, missing files, corrupted VERSION)
   - Integration testing across repositories

### Risk Areas

**High-risk areas requiring extra care**:

1. **Path canonicalization** - Security critical, platform differences
2. **Version checking** - Must work BEFORE utilities loaded (bootstrap problem)
3. **Error messages** - User experience depends on clear guidance
4. **Dev mode** - Symlinks introduce edge cases

**Mitigation**: Allocate 50% extra time for security and testing

## 5. Questions & Clarifications

### Q1: Should dotfiles bundle fallback utilities?

**Context**: If AIDA missing or incompatible, should dotfiles have its own utilities?

**Options**:

- **A**: Hard dependency (dotfiles REQUIRES AIDA)
  - **Pros**: Simpler, no code duplication, guaranteed consistency
  - **Cons**: Cannot install dotfiles standalone, installation order forced

- **B**: Bundled fallback (dotfiles includes minimal utilities)
  - **Pros**: Dotfiles works standalone, flexible installation order
  - **Cons**: Code duplication, drift risk, larger dotfiles repo

- **C**: Hybrid (bundle bootstrap, source rest from AIDA)
  - **Pros**: Best of both (standalone bootstrap, full features with AIDA)
  - **Cons**: Most complex, two code paths to maintain

**Recommendation for v0.1.2**: **Option A** (hard dependency)

**Rationale**:

- Simpler implementation (fewer edge cases)
- Dotfiles installer IS installing AIDA integration (logical dependency)
- Can add fallback in v0.2.0 if user feedback demands it
- Clear error message guides user to install AIDA first

**For v0.2.0**: Revisit Option B if users request dotfiles-first installation

### Q2: Version compatibility rules (semver semantics)?

**Context**: How strict should version matching be?

**Options**:

- **A**: Strict major.minor match (0.1.x ↔ 0.1.x only)
  - **Pros**: Safest (no surprises), easiest to understand
  - **Cons**: Blocks dotfiles from working with newer AIDA (forces upgrades)

- **B**: Major match, minor forward-compatible (AIDA 0.2 works with dotfiles 0.1)
  - **Pros**: Flexible (AIDA can add features without breaking dotfiles)
  - **Cons**: Requires careful API stability guarantees

- **C**: Range-based (dotfiles specifies "0.1.0 - 0.3.0")
  - **Pros**: Most flexible (dotfiles declares known compatible versions)
  - **Cons**: Complex to implement, error-prone, hard to test all combinations

**Recommendation**: **Option B** (major match, minor forward-compatible)

**Rationale**:

- Standard semantic versioning practice
- Allows AIDA innovation without breaking dotfiles
- Dotfiles can be conservative (require older version), still works with newer
- Requires API stability discipline (breaking changes = major bump)

**Implementation**:

```bash
# Dotfiles declares: "Requires AIDA 0.1.0+"
# Compatible with: 0.1.0, 0.1.5, 0.2.0, 0.3.0
# Incompatible with: 1.0.0 (major bump = breaking changes)
```

### Q3: What if ~/.aida/ exists but is corrupted?

**Scenarios**:

1. `~/.aida/` exists but VERSION file missing
2. `~/.aida/` exists but lib/installer-common/ missing
3. `~/.aida/` exists but files have syntax errors
4. `~/.aida/` is a file, not a directory
5. `~/.aida/` has wrong permissions (not owned by user)

**Recommendation**: Validate thoroughly, offer repair

```bash
validate_aida_installation() {
    local aida_dir="${HOME}/.aida"

    # Check 1: Is it a directory?
    if [[ ! -d "$aida_dir" ]]; then
        if [[ -e "$aida_dir" ]]; then
            print_error "${aida_dir} exists but is not a directory"
            print_info "Fix: rm ${aida_dir} && git clone ..."
        else
            print_error "AIDA not installed at ${aida_dir}"
        fi
        return 1
    fi

    # Check 2: Ownership
    local owner
    owner=$(stat -f %Su "$aida_dir")
    if [[ "$owner" != "$USER" ]]; then
        print_error "AIDA directory not owned by current user: ${aida_dir}"
        print_info "Fix: sudo chown -R ${USER} ${aida_dir}"
        return 1
    fi

    # Check 3: VERSION file
    if [[ ! -f "${aida_dir}/VERSION" ]]; then
        print_error "AIDA installation corrupted (VERSION file missing)"
        print_info "Fix: cd ${aida_dir} && git pull"
        return 1
    fi

    # Check 4: installer-common library
    if [[ ! -d "${aida_dir}/lib/installer-common" ]]; then
        print_error "AIDA installation corrupted (installer-common missing)"
        print_info "Fix: cd ${aida_dir} && git pull"
        return 1
    fi

    # Check 5: Required utility files
    local required_files=("colors.sh" "logging.sh" "validation.sh")
    for file in "${required_files[@]}"; do
        local filepath="${aida_dir}/lib/installer-common/${file}"
        if [[ ! -f "$filepath" ]]; then
            print_error "AIDA installation corrupted (${file} missing)"
            print_info "Fix: cd ${aida_dir} && git pull"
            return 1
        fi

        # Syntax check
        if ! bash -n "$filepath" 2>/dev/null; then
            print_error "AIDA installation corrupted (syntax error in ${file})"
            print_info "Fix: cd ${aida_dir} && git reset --hard && git pull"
            return 1
        fi
    done

    print_success "AIDA installation validated"
    return 0
}
```

### Q4: Upgrade path for existing installations?

**Scenario**: User has AIDA 0.1.0 installed, wants to use dotfiles requiring 0.1.2

**Options**:

- **Manual upgrade**: User runs `cd ~/.aida && git pull`
- **Automatic upgrade**: Dotfiles installer offers to upgrade AIDA
- **Smart detection**: Check if it's a git repo, offer appropriate upgrade

**Recommendation**: Smart detection with automatic upgrade (v0.2.0)

```bash
upgrade_aida_if_needed() {
    local current_version="$1"
    local required_version="$2"

    print_warning "AIDA version ${current_version} is older than required ${required_version}"

    # Check if it's a git repository
    if [[ -d "${HOME}/.aida/.git" ]]; then
        print_info "AIDA is a git repository. Upgrade available."
        read -rp "Upgrade AIDA now? [Y/n] " response
        if [[ "$response" =~ ^[Yy]?$ ]]; then
            cd "${HOME}/.aida" && git pull
            print_success "AIDA upgraded to $(cat VERSION)"
            return 0
        fi
    else
        print_info "AIDA is not a git repository (dev mode or manual install)"
        print_info "Please upgrade manually:"
        print_info "  cd ~/.aida && git pull"
    fi

    return 1
}
```

**For v0.1.2**: Detect version mismatch, display clear instructions (no auto-upgrade)

## Summary

**Integration pattern**: One-way dependency (dotfiles → AIDA)

**Key decision**: Dotfiles REQUIRES AIDA for v0.1.2 (hard dependency, simple)

**Security focus**: Path validation, ownership checks, syntax validation before sourcing

**Version strategy**: Major match, minor forward-compatible (semantic versioning)

**Effort**: 6-8 hours (medium complexity, security-focused)

**Risk areas**: Path canonicalization, bootstrap version checking, cross-platform compatibility

## Files Referenced

- `/Users/oakensoul/Developer/oakensoul/claude-personal-assistant/install.sh` - Current installer (functions to extract)
- `/Users/oakensoul/Developer/oakensoul/claude-personal-assistant/VERSION` - Version file (0.1.1)
- `/Users/oakensoul/Developer/oakensoul/claude-personal-assistant/docs/architecture/dotfiles-integration.md` - Integration architecture

## Next Steps

1. **Product Manager**: Decide on Q1-Q4 (fallback utilities, version rules, error verbosity, upgrade path)
2. **Shell Script Specialist**: Implement lib/installer-common/ with security controls
3. **Privacy & Security Auditor**: Review security controls before merge
4. **Configuration Specialist**: Validate version compatibility logic
5. **Integration testing**: Test with dotfiles repository integration
