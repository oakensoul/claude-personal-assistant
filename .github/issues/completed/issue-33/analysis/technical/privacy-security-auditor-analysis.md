---
title: "Technical Security Implementation - Issue #33"
description: "Security implementation guidance for shared installer library and VERSION file"
category: "technical-analysis"
tags: ["security", "implementation", "installer", "validation"]
last_updated: "2025-10-06"
status: "published"
audience: "developers"
issue: 33
---

# Technical Security Implementation Analysis: Issue #33

**Issue**: Support dotfiles installer integration - shared installer-common library and VERSION file
**Analyst**: Privacy & Security Auditor Agent
**Date**: 2025-10-06
**Focus**: Technical implementation of security controls

---

## 1. Implementation Approach

### Input Sanitization in validation.sh

#### Critical Pattern: Command Injection Prevention

```bash
# lib/installer-common/validation.sh

# UNSAFE - DO NOT USE
validate_unsafe() {
    local input="$1"
    result=$(grep "$input" file.txt)  # Command injection risk
}

# SAFE - Use this pattern
validate_input() {
    local input="$1"
    local pattern="$2"

    # Step 1: Allowlist validation with strict regex
    if [[ ! "$input" =~ ^${pattern}$ ]]; then
        return 1
    fi

    # Step 2: Quote properly in any command usage
    result=$(grep -- "${input}" file.txt)  # -- prevents flag injection

    # Step 3: Use printf %q for shell-safe quoting if needed
    local safe_input
    safe_input=$(printf %q "$input")
}

# Specific validators
validate_version() {
    local version="$1"
    # Only allow semver: X.Y.Z where X,Y,Z are digits
    if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        return 1
    fi
    return 0
}

validate_path_component() {
    local component="$1"
    # No special chars, no .., no absolute paths
    if [[ "$component" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        return 0
    fi
    return 1
}

validate_filename() {
    local filename="$1"
    # Only allow safe filenames: alphanumeric, dash, underscore, dot
    if [[ "$filename" =~ ^[a-zA-Z0-9._-]+$ ]]; then
        # Additional check: no leading dots (hidden files)
        if [[ "$filename" =~ ^\. ]]; then
            return 1
        fi
        return 0
    fi
    return 1
}
```

## Implementation Strategy

1. **Allowlist, not blocklist**: Define what IS allowed, reject everything else
2. **Strict regex patterns**: `^[allowed_chars]+$` anchored at both ends
3. **Proper quoting**: Always use `"${variable}"` in commands
4. **Flag injection protection**: Use `--` to separate flags from arguments
5. **Context-specific validators**: Different rules for versions, paths, filenames

### Path Canonicalization

#### Critical Pattern: Path Traversal Prevention

```bash
# lib/installer-common/validation.sh

# Canonicalize and validate path is within expected directory
validate_path_in_directory() {
    local path="$1"
    local expected_dir="$2"

    # Step 1: Reject if path doesn't exist
    if [[ ! -e "$path" ]]; then
        return 1
    fi

    # Step 2: Get canonical absolute path (resolves symlinks, .., .)
    local canonical_path
    canonical_path=$(realpath "$path" 2>/dev/null) || return 1

    local canonical_dir
    canonical_dir=$(realpath "$expected_dir" 2>/dev/null) || return 1

    # Step 3: Verify canonical path starts with canonical directory
    if [[ "$canonical_path" != "$canonical_dir"* ]]; then
        return 1
    fi

    return 0
}

# Safer sourcing pattern
safe_source() {
    local lib_name="$1"
    local lib_dir="${AIDA_DIR}/lib/installer-common"

    # Step 1: Validate filename (no path components)
    if [[ "$lib_name" =~ [/\\] ]]; then
        print_message "error" "Invalid library name"
        return 1
    fi

    # Step 2: Construct path
    local lib_path="${lib_dir}/${lib_name}"

    # Step 3: Validate path is within expected directory
    if ! validate_path_in_directory "$lib_path" "$lib_dir"; then
        print_message "error" "Library path validation failed"
        return 1
    fi

    # Step 4: Validate file permissions (later section)
    if ! validate_file_permissions "$lib_path"; then
        print_message "error" "Library has unsafe permissions"
        return 1
    fi

    # Step 5: Source the file
    source "$lib_path"
}
```

## Implementation Strategy

1. **Use realpath**: Resolves symlinks and canonicalizes paths
2. **Prefix matching**: Verify canonical path starts with expected directory
3. **Reject relative paths**: No `..` or `.` in input
4. **No path separators**: Filenames should not contain `/` or `\`
5. **Exist check first**: Path must exist before canonicalization

## Edge Cases to Handle

- Symlinks to files outside allowed directory
- Case sensitivity on case-insensitive filesystems (macOS)
- Trailing slashes in directory paths
- Non-existent parent directories

### File Permission Validation

#### Critical Pattern: Permission & Ownership Checks

```bash
# lib/installer-common/validation.sh

validate_file_permissions() {
    local filepath="$1"

    # Check file exists
    if [[ ! -f "$filepath" ]]; then
        return 1
    fi

    # Get file permissions and ownership
    local perms
    local owner
    local group

    # macOS compatible stat command
    if [[ "$OSTYPE" == "darwin"* ]]; then
        perms=$(stat -f "%Lp" "$filepath")
        owner=$(stat -f "%u" "$filepath")
    else
        # Linux
        perms=$(stat -c "%a" "$filepath")
        owner=$(stat -c "%u" "$filepath")
    fi

    # Validate ownership (must be current user or root)
    local current_uid
    current_uid=$(id -u)
    if [[ "$owner" != "$current_uid" ]] && [[ "$owner" != "0" ]]; then
        print_message "error" "File not owned by current user: $filepath"
        return 1
    fi

    # Validate permissions (must not be world-writable)
    # Check last digit of octal permissions
    local world_perms="${perms: -1}"
    if [[ "$world_perms" =~ [2367] ]]; then
        print_message "error" "File is world-writable: $filepath"
        return 1
    fi

    # Validate not group-writable unless group is user's primary group
    local group_perms="${perms: -2:1}"
    if [[ "$group_perms" =~ [2367] ]]; then
        local file_group
        if [[ "$OSTYPE" == "darwin"* ]]; then
            file_group=$(stat -f "%g" "$filepath")
        else
            file_group=$(stat -c "%g" "$filepath")
        fi

        local user_group
        user_group=$(id -g)

        if [[ "$file_group" != "$user_group" ]]; then
            print_message "error" "File is group-writable by non-primary group: $filepath"
            return 1
        fi
    fi

    return 0
}

validate_directory_permissions() {
    local dirpath="$1"

    if [[ ! -d "$dirpath" ]]; then
        return 1
    fi

    # Similar logic but for directories
    # Directories need execute bit, so 755 or 750 is acceptable
    # Same ownership and world-writable checks apply

    local perms
    if [[ "$OSTYPE" == "darwin"* ]]; then
        perms=$(stat -f "%Lp" "$dirpath")
    else
        perms=$(stat -c "%a" "$dirpath")
    fi

    # Check not world-writable
    local world_perms="${perms: -1}"
    if [[ "$world_perms" =~ [2367] ]]; then
        print_message "error" "Directory is world-writable: $dirpath"
        return 1
    fi

    return 0
}
```

## Implementation Strategy

1. **Cross-platform stat**: Different syntax for macOS vs Linux
2. **Ownership validation**: User or root only
3. **World-writable check**: Last octal digit must be 0,1,4,5
4. **Group-writable check**: Only if group is user's primary group
5. **Separate directory logic**: Directories need execute bit

## Security Requirements

- Libraries (sourced): 644 (rw-r--r--)
- Scripts (executed): 755 (rwxr-xr-x)
- Never world-writable (no 2,3,6,7 in last digit)
- Must be owned by user or root

### VERSION File Integrity Validation

#### Critical Pattern: Tamper Detection

```bash
# lib/installer-common/validation.sh

# Simple approach for v0.1.0 - validate format and permissions
validate_version_file() {
    local version_file="$1"

    # Step 1: File must exist
    if [[ ! -f "$version_file" ]]; then
        print_message "error" "VERSION file not found"
        return 1
    fi

    # Step 2: Validate permissions
    if ! validate_file_permissions "$version_file"; then
        return 1
    fi

    # Step 3: Read and validate format
    local version
    version=$(cat "$version_file" | head -n1 | tr -d '[:space:]')

    if ! validate_version "$version"; then
        print_message "error" "Invalid version format in VERSION file"
        return 1
    fi

    # Step 4: Store version for later use
    echo "$version"
    return 0
}

# Advanced approach for future - checksum validation
validate_version_file_with_checksum() {
    local version_file="$1"
    local expected_checksum="$2"

    # Basic validation first
    local version
    version=$(validate_version_file "$version_file") || return 1

    # Compute checksum of VERSION file
    local actual_checksum
    if command -v shasum >/dev/null 2>&1; then
        actual_checksum=$(shasum -a 256 "$version_file" | awk '{print $1}')
    elif command -v sha256sum >/dev/null 2>&1; then
        actual_checksum=$(sha256sum "$version_file" | awk '{print $1}')
    else
        print_message "warning" "No SHA256 command available, skipping checksum"
        echo "$version"
        return 0
    fi

    # Compare checksums
    if [[ "$actual_checksum" != "$expected_checksum" ]]; then
        print_message "error" "VERSION file checksum mismatch"
        print_message "error" "Expected: $expected_checksum"
        print_message "error" "Got:      $actual_checksum"
        return 1
    fi

    echo "$version"
    return 0
}
```

## Implementation Phases

## Phase 1 (v0.1.0 - Minimum Viable Security)

- Validate VERSION file permissions
- Validate version format (semver)
- Reject if world-writable or wrong owner

## Phase 2 (v0.2.0 - Enhanced Security)

- Checksum validation against known-good hash
- Checksums distributed via git tags or separate file
- Optional: GPG signature verification

## Checksum Distribution Options

1. **Git commit signatures**: Verify git commit containing VERSION
2. **Separate CHECKSUMS file**: `lib/installer-common/CHECKSUMS` with format:

   ```text
   VERSION:         abc123...
   colors.sh:       def456...
   logging.sh:      789ghi...
   validation.sh:   jkl012...
   ```

3. **Embedded in git tags**: Signed git tags with checksums in message

**Recommendation for v0.1.0**: Implement Phase 1 only. Add Phase 2 in v0.2.0 with proper checksum distribution mechanism.

---

## 2. Technical Concerns

### Bash Security Limitations

## Fundamental Limitations

1. **No built-in sandboxing**: Sourced scripts have full shell access
2. **String-based execution**: Easy to inject if not careful
3. **Implicit variable expansion**: Unquoted variables are word-split
4. **Limited type safety**: Everything is a string
5. **Filesystem race conditions**: No atomic read-validate-execute

## Mitigation Strategies

```bash
# 1. Always use set -euo pipefail
set -euo pipefail  # Exit on error, undefined vars, pipe failures

# 2. Use readonly for constants
readonly AIDA_DIR="${HOME}/.aida"

# 3. Quote all variable expansions
echo "${variable}"        # GOOD
echo $variable            # BAD

# 4. Use arrays for lists
files=("colors.sh" "logging.sh" "validation.sh")
for file in "${files[@]}"; do  # GOOD
    process "$file"
done

# 5. Validate before use
if validate_input "$user_input"; then
    use_input "$user_input"
fi
```

### Race Conditions (TOCTOU)

## Time-Of-Check-Time-Of-Use Vulnerability

```bash
# VULNERABLE: File could change between check and use
if [[ -f "$VERSION_FILE" ]]; then
    # Attacker replaces file here
    VERSION=$(cat "$VERSION_FILE")
fi

# BETTER: Validate after read
VERSION=$(cat "$VERSION_FILE" 2>/dev/null)
if [[ -z "$VERSION" ]]; then
    print_message "error" "Failed to read VERSION file"
    exit 1
fi
if ! validate_version "$VERSION"; then
    print_message "error" "Invalid version format"
    exit 1
fi

# BEST: Atomic read with validation
read_and_validate_version() {
    local version_file="$1"

    # Single read operation
    local content
    content=$(cat "$version_file" 2>/dev/null) || return 1

    # Validate content
    local version
    version=$(echo "$content" | head -n1 | tr -d '[:space:]')

    if ! validate_version "$version"; then
        return 1
    fi

    echo "$version"
    return 0
}
```

## Mitigation Strategies

1. **Read then validate**: Don't check existence separately
2. **Single operation**: Minimize time between operations
3. **Validate content**: Check what was read, not what file is
4. **Accept risk**: Some TOCTOU is unavoidable in shell scripts
5. **Limit damage**: Validation after read catches most tampering

## What We CAN'T Fix

- File could still be modified during read (OS-level race)
- No true atomic read-and-lock in pure bash
- Need root for mandatory locking on most systems

## What We CAN Fix

- Reduce window of vulnerability
- Validate content after reading
- Check permissions match expectations
- Fail safely if validation fails

### Error Handling Without Information Disclosure

## Security vs Usability Tradeoff

```bash
# INSECURE: Too much information
if [[ ! -f "$config_file" ]]; then
    echo "Error: Configuration file not found at $config_file"
    echo "Current user: $USER"
    echo "Home directory: $HOME"
    echo "Full path: $(pwd)/$config_file"
fi

# SECURE BUT FRUSTRATING: Too generic
if [[ ! -f "$config_file" ]]; then
    echo "Error: Configuration failed"
fi

# BALANCED: Generic to user, detailed to log
log_detailed_error() {
    local error_msg="$1"
    local log_file="${HOME}/.aida/logs/install.log"

    # Detailed to log (secure location)
    if [[ -w "$(dirname "$log_file")" ]]; then
        echo "[$(date)] ERROR: $error_msg" >> "$log_file"
        echo "[$(date)]   User: $USER" >> "$log_file"
        echo "[$(date)]   PWD: $(pwd)" >> "$log_file"
        chmod 600 "$log_file"  # Secure permissions
    fi
}

handle_error_securely() {
    local user_msg="$1"
    local detail_msg="$2"

    # Generic message to user
    print_message "error" "$user_msg"
    print_message "info" "Check logs for details: ~/.aida/logs/install.log"

    # Detailed message to log
    log_detailed_error "$detail_msg"
}

# Usage
if [[ ! -f "$config_file" ]]; then
    handle_error_securely \
        "Configuration file not found" \
        "Config file not found: $config_file (user: $USER, pwd: $(pwd))"
    exit 1
fi
```

## Implementation Pattern

1. **Two-tier error messages**:
   - User: Generic, actionable (what to do)
   - Log: Detailed, diagnostic (what went wrong)

2. **Secure log location**:
   - `~/.aida/logs/` with 700 permissions
   - Log files with 600 permissions
   - Never world-readable

3. **Path scrubbing in user messages**:
   - Replace `/Users/john/` with `~/`
   - Don't expose system structure
   - Don't leak usernames

4. **Standard error categories**:

   ```bash
   # User-facing error types
   ERROR_PERMISSION="Permission denied. Check file permissions."
   ERROR_NOT_FOUND="File not found. Check installation."
   ERROR_INVALID="Invalid configuration. Check format."
   ERROR_VERSION="Version mismatch. Update required."
   ```

### Attack Surface Analysis

## Threat Model

```text
Attacker Goal: Execute arbitrary code via installer

Attack Vectors:
1. Modify ~/.aida/lib/installer-common/*.sh
2. Tamper with ~/.aida/VERSION
3. Inject malicious input to installer
4. Symlink attack (point to malicious file)
5. Race condition during installation
6. Social engineering (malicious repo clone)

Attack Surface Components:
- VERSION file reading
- Library file sourcing
- User input processing
- Path construction
- File permission checks
- Version comparison logic
```

## Surface Reduction Strategy

```text
HIGH RISK → MUST MITIGATE:
- sourcing shell scripts → validate perms + canonicalize paths
- reading VERSION file → validate perms + format + (checksum)
- user input → strict allowlist validation

MEDIUM RISK → SHOULD MITIGATE:
- path construction → canonicalize + prefix check
- version comparison → strict semver validation
- error messages → generic to user, detailed to log

LOW RISK → ACCEPT:
- TOCTOU races → validate after read
- local attacker → assume user's home is trusted after initial check
- social engineering → document official repo only
```

## Defense in Depth Layers

1. **Input Validation** (First line of defense)
   - Strict allowlist for all inputs
   - Regex validation before use
   - Reject unexpected formats

2. **Path Security** (Prevent traversal)
   - Canonicalize all paths
   - Validate within expected directory
   - Check for symlinks to outside

3. **Permission Checks** (Prevent tampering)
   - Validate ownership
   - Reject world/group writable
   - Check before every use

4. **Execution Control** (Limit damage)
   - Source only validated files
   - Fail on first error (set -e)
   - No eval or dynamic execution

5. **Logging & Auditing** (Detect attacks)
   - Log all security checks
   - Record failures
   - Secure log storage

---

## 3. Dependencies & Integration

### Required Security Utilities

## Core Dependencies

```bash
# MUST HAVE (fail installation if missing)
- realpath      # Path canonicalization
- stat          # File permissions and ownership
- id            # Current user UID/GID
- chmod         # Set secure permissions
- head          # Safe file reading (limit lines)
- tr            # String sanitization

# SHOULD HAVE (warn if missing)
- shasum        # Checksum validation (macOS)
- sha256sum     # Checksum validation (Linux)

# NICE TO HAVE (optional features)
- gpg           # Signature verification
- flock         # File locking (Linux only)
```

## Dependency Validation

```bash
# In validation.sh
validate_security_dependencies() {
    local errors=0

    # Critical dependencies
    local critical_deps=("realpath" "stat" "id" "chmod" "head" "tr")
    for cmd in "${critical_deps[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            print_message "error" "Required command not found: $cmd"
            errors=$((errors + 1))
        fi
    done

    # Checksum tools (one of)
    if ! command -v shasum >/dev/null 2>&1 && \
       ! command -v sha256sum >/dev/null 2>&1; then
        print_message "warning" "No SHA256 command found"
        print_message "warning" "Checksum validation will be skipped"
    fi

    return "$errors"
}
```

### Integration with Existing Security Controls

## Current AIDA install.sh Security Features

```bash
# Already implemented
- set -euo pipefail (line 19)
- readonly for constants (lines 22-45)
- Input validation for assistant_name (lines 192-226)
- Input validation for personality (lines 240-268)
- Proper quoting throughout
- Permission setting (lines 392-403)

# Needs enhancement
- No path canonicalization before use
- No file permission validation before operations
- No checksum validation
- Generic error handling but no secure logging
```

## Integration Points

1. **Enhance validate_dependencies()** (line 139):

   ```bash
   validate_dependencies() {
       print_message "info" "Validating system dependencies..."

       # Existing checks...

       # ADD: Security dependency validation
       if ! validate_security_dependencies; then
           return 1
       fi

       # ADD: Validate SCRIPT_DIR permissions
       if ! validate_directory_permissions "$SCRIPT_DIR"; then
           print_message "error" "Repository directory has unsafe permissions"
           return 1
       fi
   }
   ```

2. **Enhance VERSION reading** (line 33):

   ```bash
   # CURRENT:
   if [[ -f "$VERSION_FILE" ]]; then
       VERSION="$(cat "$VERSION_FILE")"
   fi

   # ENHANCED:
   if [[ -f "$VERSION_FILE" ]]; then
       # Validate permissions first
       if ! validate_file_permissions "$VERSION_FILE"; then
           echo -e "${RED}Error:${NC} VERSION file has unsafe permissions"
           exit 1
       fi

       # Validate and read
       VERSION=$(validate_version_file "$VERSION_FILE")
       if [[ $? -ne 0 ]]; then
           echo -e "${RED}Error:${NC} VERSION file validation failed"
           exit 1
       fi
   fi
   ```

3. **Add secure logging throughout**:

   ```bash
   # Replace print_message "error" calls with:
   handle_error_securely \
       "User-friendly message" \
       "Detailed diagnostic: $detail"
   ```

### System Tool Dependencies

## Platform Differences

```bash
# macOS vs Linux stat differences
get_file_permissions() {
    local filepath="$1"

    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS: BSD stat
        stat -f "%Lp" "$filepath"
    else
        # Linux: GNU stat
        stat -c "%a" "$filepath"
    fi
}

get_file_owner() {
    local filepath="$1"

    if [[ "$OSTYPE" == "darwin"* ]]; then
        stat -f "%u" "$filepath"
    else
        stat -c "%u" "$filepath"
    fi
}
```

## realpath Availability

```bash
# realpath might not be available on older macOS
safe_realpath() {
    local path="$1"

    if command -v realpath >/dev/null 2>&1; then
        realpath "$path"
    else
        # Fallback for macOS without realpath
        python3 -c "import os; print(os.path.realpath('$path'))" 2>/dev/null || {
            print_message "error" "Cannot canonicalize path: realpath not available"
            return 1
        }
    fi
}
```

**Recommendation**: For v0.1.0, require realpath. Document installation on macOS if needed (brew install coreutils).

---

## 4. Effort & Complexity

### Estimated Complexity: **LARGE (L)**

## Breakdown

| Component | Complexity | Time Estimate |
|-----------|-----------|---------------|
| Input validation functions | Medium | 2 hours |
| Path canonicalization | Medium | 1.5 hours |
| Permission validation | Medium | 1.5 hours |
| VERSION integrity | Small | 1 hour |
| Secure logging | Medium | 1 hour |
| Integration with install.sh | Medium | 1.5 hours |
| Testing & validation | Large | 2 hours |
| Security review | Medium | 1 hour |
| Documentation | Small | 30 mins |
| **TOTAL** | **Large** | **12 hours** |

**Original estimate**: 2 hours (shared library creation)
**With security**: 12 hours (6x increase)
**Justification**: Security implementation is not optional

### Key Effort Drivers

1. **Cross-platform compatibility** (macOS vs Linux):
   - Different stat syntax
   - Different tool availability
   - Testing on both platforms
   - **Impact**: +3 hours

2. **Comprehensive validation functions**:
   - Input sanitization patterns
   - Path canonicalization
   - Permission checking
   - Error handling
   - **Impact**: +4 hours

3. **Testing with malicious input**:
   - Command injection attempts
   - Path traversal attempts
   - Permission tampering
   - Race condition testing
   - **Impact**: +2 hours

4. **Integration complexity**:
   - Update existing install.sh
   - Maintain backward compatibility
   - Test integration with dotfiles
   - **Impact**: +2 hours

### Risk Areas

## High Risk (Likely to cause delays)

1. **Platform inconsistencies**:
   - macOS BSD tools vs Linux GNU tools
   - Different default permissions
   - Filesystem differences (case sensitivity)
   - **Mitigation**: Test on both platforms early

2. **Race condition testing**:
   - Hard to reproduce reliably
   - Requires timing-based attacks
   - May need specialized tools
   - **Mitigation**: Accept some TOCTOU risk, focus on validation-after-read

3. **Error handling complexity**:
   - Balancing security vs usability
   - Deciding what to log vs display
   - Path scrubbing implementation
   - **Mitigation**: Define clear categories early

## Medium Risk (May cause issues)

1. **Validation function completeness**:
   - May miss edge cases initially
   - Requires iterative testing
   - **Mitigation**: Comprehensive test suite

2. **Integration with existing code**:
   - May break existing functionality
   - Requires careful testing
   - **Mitigation**: Test install.sh thoroughly

## Low Risk (Unlikely to cause problems)

1. **Documentation**:
   - Clear implementation patterns
   - Well-understood security principles
   - **Mitigation**: Follow existing patterns

---

## 5. Questions & Clarifications

### Technical Questions Needing Answers

## 1. Checksum Distribution Mechanism

**Question**: How should we distribute checksums for validation?

## Options

- **Option A**: Separate `CHECKSUMS` file in repository
  - Pro: Simple to implement
  - Con: CHECKSUMS file itself could be tampered

- **Option B**: Git tag signatures with embedded checksums
  - Pro: Leverages git's security
  - Con: Requires GPG setup, more complex

- **Option C**: Hardcoded in dotfiles installer
  - Pro: Can't be tampered after install
  - Con: Requires dotfiles update for each AIDA version

**Recommendation**: **Option A for v0.1.0**, Option B for v0.2.0. Document in implementation.

## 2. Validation Failure Behavior

**Question**: Should validation failures be fatal or allow override?

## Options

- **Option A**: Always fatal (no override)
  - Pro: Maximum security
  - Con: Breaks if user has non-standard setup

- **Option B**: Fatal by default, `--force` flag to override
  - Pro: Flexible for edge cases
  - Con: Users will always use --force

- **Option C**: Warnings only, continue
  - Pro: Maximum compatibility
  - Con: Defeats purpose of validation

**Recommendation**: **Option A for v0.1.0**. If users report legitimate failures, add `--force` in v0.1.1 with scary warning.

## 3. Logging Verbosity

**Question**: How verbose should security validation logs be?

## Options

- **Option A**: Log every validation check
  - Pro: Complete audit trail
  - Con: Large log files, performance impact

- **Option B**: Log only failures
  - Pro: Minimal overhead
  - Con: Can't prove successful validations

- **Option C**: Log summary + failures
  - Pro: Balance of detail and size
  - Con: Middle ground may not satisfy either need

**Recommendation**: **Option C for v0.1.0**. Log summary at start (what will be validated), then only failures.

## 4. realpath Fallback

**Question**: What if realpath is not available?

## Options

- **Option A**: Require realpath, fail if missing
  - Pro: Consistent behavior
  - Con: May break on older macOS

- **Option B**: Fallback to Python realpath
  - Pro: Works on most systems
  - Con: Adds Python dependency

- **Option C**: Skip canonicalization if unavailable
  - Pro: Always works
  - Con: Security vulnerability

**Recommendation**: **Option A** with clear error message: "Install coreutils: brew install coreutils"

### Decisions to Be Made

## 1. Checksum Algorithm

**Decision**: Which hashing algorithm to use?

## Options

- SHA256: Industry standard, good balance
- SHA512: More secure, slower
- SHA1: Faster, but deprecated for security

**Recommendation**: **SHA256** (standard, widely available, sufficient security)

## 2. GPG Signing for v0.1.0

**Decision**: Should we implement GPG signature verification in v0.1.0?

## Options

- **Yes**: Maximum security from day one
- **No**: Add in v0.2.0 after core functionality proven

**Recommendation**: **No for v0.1.0**, add in v0.2.0. Reason: GPG adds complexity (key distribution, user setup) that may delay release.

## 3. Validation Strictness

**Decision**: How strict should validation be?

**Example**: If VERSION file has extra newlines, should we:

- **A**: Reject (strict)
- **B**: Strip and continue (lenient)

**Recommendation**: **Lenient for format, strict for content**. Strip whitespace from version string, but reject if format is invalid after stripping.

## 4. Log Rotation

**Decision**: Should we implement log rotation for security logs?

## Options

- **Yes**: Keep logs manageable
- **No**: Let user manage

**Recommendation**: **No for v0.1.0**. Document that logs are in ~/.aida/logs/ and user should manage. Add rotation in v0.2.0 if needed.

### Areas Needing Investigation

## 1. macOS Gatekeeper Interaction

**Investigation**: Does macOS Gatekeeper interfere with sourcing shell scripts?

## Questions

- Are scripts quarantined when cloned from GitHub?
- Does this affect sourcing behavior?
- Do we need special handling?

**Action**: Test on fresh macOS install, document findings.

## 2. SELinux/AppArmor Compatibility

**Investigation**: Do Linux security modules affect installer?

## Questions

- Are there contexts/labels we need to set?
- Can scripts source from ~/.aida/ under strict policies?
- Do we need documentation for SELinux users?

**Action**: Test on Fedora (SELinux) and Ubuntu with AppArmor, document any issues.

## 3. Performance Impact of Validation

**Investigation**: How much does comprehensive validation slow installation?

## Questions

- Acceptable overhead? (Target: <5% increase)
- Which validations are expensive?
- Can we optimize without compromising security?

**Action**: Benchmark with and without validation, optimize if >5% overhead.

## 4. Filesystem Race Conditions

**Investigation**: How exploitable are TOCTOU races in practice?

## Questions

- Can we reproduce reliably?
- What's the actual risk level?
- Are mitigations effective?

**Action**: Write exploit script to test race conditions, measure effectiveness of mitigations.

---

## Implementation Checklist

### Phase 1: Foundation (Critical - Do First)

- [ ] Create `lib/installer-common/validation.sh` with functions:
  - [ ] `validate_input()` - Generic input validation
  - [ ] `validate_version()` - Semver validation
  - [ ] `validate_path_component()` - Safe path components
  - [ ] `validate_filename()` - Safe filenames
  - [ ] `validate_path_in_directory()` - Path canonicalization
  - [ ] `validate_file_permissions()` - Permission checking
  - [ ] `validate_directory_permissions()` - Directory permission checking
  - [ ] `validate_security_dependencies()` - Validate required tools

- [ ] All functions pass shellcheck
- [ ] All functions tested with malicious input
- [ ] Cross-platform testing (macOS + Linux)

### Phase 2: VERSION Security (Critical - Do Second)

- [ ] Implement `validate_version_file()` in validation.sh
- [ ] Update install.sh to use validation function
- [ ] Test with tampered VERSION file
- [ ] Test with wrong permissions
- [ ] Document VERSION file requirements

### Phase 3: Secure Logging (High Priority)

- [ ] Create `log_detailed_error()` function
- [ ] Create `handle_error_securely()` function
- [ ] Update all error messages to use secure logging
- [ ] Create ~/.aida/logs/ with 700 permissions
- [ ] Set log files to 600 permissions
- [ ] Test path scrubbing in messages

### Phase 4: Integration (High Priority)

- [ ] Update install.sh validate_dependencies()
- [ ] Add security validation to install.sh
- [ ] Test complete installation flow
- [ ] Test dev mode installation
- [ ] Test with dotfiles integration
- [ ] Verify no regression in existing functionality

### Phase 5: Testing & Validation (Critical - Before Merge)

- [ ] Unit tests for each validation function
- [ ] Integration tests for install.sh
- [ ] Malicious input testing:
  - [ ] Command injection attempts
  - [ ] Path traversal attempts
  - [ ] Permission tampering
  - [ ] VERSION file tampering

- [ ] Cross-platform testing:
  - [ ] macOS (Intel and ARM)
  - [ ] Linux (Ubuntu, Fedora)

- [ ] Performance benchmarks
- [ ] Security review by second developer

### Phase 6: Documentation (Before Merge)

- [ ] Document all validation functions
- [ ] Document error handling patterns
- [ ] Document security requirements
- [ ] Update CONTRIBUTING.md with security guidelines
- [ ] Create SECURITY.md if not exists
- [ ] Document platform-specific requirements

---

## Summary

## Security Implementation is CRITICAL and COMPLEX

- **Effort**: 12 hours (6x original estimate)
- **Complexity**: Large (L)
- **Risk**: High (security vulnerabilities = complete compromise)

## Core Implementation Requirements

1. **Input sanitization**: Allowlist validation for all user input
2. **Path canonicalization**: Prevent traversal attacks
3. **Permission validation**: Prevent tampering
4. **VERSION integrity**: Validate format and permissions (checksums in v0.2.0)
5. **Secure logging**: Generic to user, detailed to secure log

## Technical Challenges

1. Cross-platform compatibility (macOS vs Linux)
2. TOCTOU race conditions (accept with validation-after-read)
3. Error handling (balance security vs usability)
4. Attack surface reduction (defense in depth)

## Phased Approach

- **v0.1.0**: Core validation (input, paths, permissions, VERSION format)
- **v0.2.0**: Enhanced security (checksums, GPG signatures, log rotation)

## Critical Message

Security cannot be added later. Implement comprehensive validation from the start, test thoroughly, and accept that this takes 6x longer than the basic feature. This is not optional.

---

## Next Steps

1. Get approval on technical approach
2. Get decisions on open questions (checksum distribution, GPG for v0.1)
3. Implement validation.sh with full security controls
4. Integrate with install.sh
5. Test with malicious input
6. Security review before merge

## Files to Create

- `/Users/oakensoul/Developer/oakensoul/claude-personal-assistant/lib/installer-common/validation.sh`
- `/Users/oakensoul/Developer/oakensoul/claude-personal-assistant/lib/installer-common/logging.sh` (secure logging functions)
- Tests for all validation functions

## Files to Modify

- `/Users/oakensoul/Developer/oakensoul/claude-personal-assistant/install.sh` (integrate security validation)
- `/Users/oakensoul/Developer/oakensoul/claude-personal-assistant/VERSION` (ensure correct format and permissions)
