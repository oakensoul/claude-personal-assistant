---
title: "Issue #33 - Shell/CLI UX Analysis"
description: "UX analysis for shared installer-common library and VERSION file"
issue: 33
analyst: "Shell Systems UX Designer"
date: "2025-10-06"
category: "product-analysis"
tags: ["ux", "cli", "installer", "dotfiles", "version-management"]
---

# Shell/CLI UX Analysis: Shared Installer Library

## Executive Summary

This change creates shared installer utilities that bridge AIDA and dotfiles repos. From a UX perspective, this is **critical infrastructure** that determines whether users have a smooth or frustrating installation experience.

**Key UX Principle**: Installation is the first impression. Get it wrong, and users never see your product's value.

## 1. Domain-Specific Concerns

### CLI Interaction Patterns

**Installation Flow UX**:

- Users expect installers to be **self-explanatory** and **fault-tolerant**
- Clear progress indication prevents "is this working?" anxiety
- Version mismatches should **inform, not block** (unless truly incompatible)
- Error messages must provide **actionable next steps**

**Current State Analysis**:

- AIDA installer (install.sh) has excellent UX: colored output, clear messages, validation
- Functions like `print_message()` with info/success/warning/error types are solid patterns
- VERSION file already exists (0.1.1) - good foundation

**Concerns for Shared Library**:

- **Consistency**: Both installers must have identical look/feel
- **Source detection**: When dotfiles sources lib/installer-common/, failure modes must be clear
- **Dependency direction**: Dotfiles depends on AIDA → what if AIDA not installed?
- **Version display**: Users need to know which versions they're installing

### Output Formatting Standards

**Current AIDA patterns** (from install.sh):

```bash
# Symbols + colors work well
✓ Success (green)
ℹ Info (blue)
⚠ Warning (yellow)
✗ Error (red)
```

**Requirements for shared library**:

- Preserve this visual language
- Support both AIDA and dotfiles context
- Allow context-aware prefixes (e.g., "[AIDA]" vs "[dotfiles]")
- Handle no-color environments (CI/CD, terminal limitations)

### Error Handling Philosophy

**User mental model**:

1. "I ran the installer"
2. "It's checking things..."
3. "Something went wrong - what do I do?"

**Critical UX moments**:

- **Version mismatch detection**: Don't panic users. Show current vs required, offer upgrade path
- **Missing dependencies**: List what's missing + how to install
- **Permission errors**: Explain which paths need access + why
- **Partial failures**: Can installation continue? Should it? Let user decide

## 2. Stakeholder Impact

### Who Is Affected?

**Primary Users** (Software Engineers):

- Installing AIDA standalone → needs version displayed clearly
- Installing dotfiles → needs to know if AIDA is compatible/required
- Installing both → needs smooth integration
- Troubleshooting → needs clear error messages and logs

**Secondary Users** (Contributors):

- Developing installers → shared lib reduces code duplication
- Testing → consistent error handling easier to test
- Documenting → one set of behaviors to document

### Value Provided

**For End Users**:

- Consistent experience across AIDA and dotfiles installers
- Clear version compatibility feedback
- Better error messages (shared validation logic)
- Reduced "works on my machine" issues

**For Maintainers**:

- Single source of truth for installer utilities
- Easier to fix bugs (fix once, both benefit)
- Reduced code duplication
- Standard logging format aids debugging

### Risks & Downsides

**Coupling Risk**:

- Dotfiles now depends on AIDA repo structure
- Changes to lib/installer-common/ affect both installers
- Breaking changes require coordination

**Installation Order Complexity**:

- If user installs dotfiles first → must source from AIDA repo (which may not exist)
- If AIDA installs later → version mismatch possible
- Users installing only dotfiles (not AIDA) → what happens?

**Version Compatibility Confusion**:

- Two repos, two versions, one compatibility check
- Users may not understand major.minor.patch semantics
- "Why won't 0.1.2 work with 0.2.0?" requires explanation

## 3. Questions & Clarifications

### Installation Flow Questions

**Q1**: When dotfiles installer runs, how does it source lib/installer-common/?

- If AIDA not installed → does dotfiles bring its own copy? Or fail gracefully?
- If AIDA installed but old version → use old lib or fail?
- If AIDA in dev mode (symlinked) → source from dev repo?

**Q2**: What's the minimum viable version check?

- Hard requirement: major version must match?
- Soft warning: minor version mismatch OK but notify?
- Patch differences always compatible?

**Q3**: How do users know which versions they have?

- Should there be a `--version` flag for install.sh?
- Should version be displayed prominently at installer start?
- Should installed systems have a `aida --version` command?

### Error Handling Decisions

**Q4**: Version mismatch - what happens?

```bash
# Scenario: dotfiles 0.2.0 with AIDA 0.1.1
# Option A: Block with error
ERROR: Version mismatch. dotfiles 0.2.0 requires AIDA 0.2.x
       Current AIDA: 0.1.1
       Run: cd ~/.aida && git pull && ./install.sh

# Option B: Warn and continue
WARNING: Version mismatch detected
         dotfiles 0.2.0 | AIDA 0.1.1
         Some features may not work. Continue? [y/N]

# Option C: Smart handling
INFO: dotfiles 0.2.0 is newer than AIDA 0.1.1
      Would you like to upgrade AIDA now? [Y/n]
```

**Recommendation**: Option C for best UX, fallback to A for major version mismatches.

**Q5**: What if lib/installer-common/ sourcing fails?

```bash
# Current risk
source ~/.aida/lib/installer-common/colors.sh || {
    echo "ERROR: Can't load installer library"
    exit 1
}

# User sees
ERROR: Can't load installer library

# Better UX
if [[ ! -f ~/.aida/lib/installer-common/colors.sh ]]; then
    echo "ERROR: AIDA framework not found or incomplete"
    echo ""
    echo "Expected: ~/.aida/lib/installer-common/"
    echo "Found:    $(ls -d ~/.aida 2>/dev/null || echo 'not installed')"
    echo ""
    echo "Please install AIDA first:"
    echo "  git clone <repo> ~/.aida && cd ~/.aida && ./install.sh"
    exit 1
fi
```

### Architecture Decisions

**Q6**: Should VERSION file support metadata?

```bash
# Current: Simple version
0.1.1

# Alternative: Richer metadata
VERSION=0.1.1
RELEASE_DATE=2025-10-06
COMPATIBLE_DOTFILES=0.1.x

# Or JSON
{"version":"0.1.1","date":"2025-10-06","compat":{"dotfiles":"0.1.x"}}
```

**Q7**: Should lib/installer-common/ be versioned independently?

- Shared lib could have its own version
- Both repos declare which lib version they need
- Allows lib to evolve separately

**Q8**: How to handle "dotfiles without AIDA" scenario?

Per architecture doc, dotfiles should work standalone. Options:

- **A**: Dotfiles bundles a minimal copy of installer-common
- **B**: Dotfiles detects AIDA and uses its lib, or falls back to bundled copy
- **C**: Dotfiles has its own utilities, only sources AIDA lib for AIDA-specific tasks

## 4. Recommendations

### Prioritize These Approaches

**1. Version Display & Awareness** (HIGH PRIORITY)

```bash
# Both installers should show versions prominently
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  AIDA Framework Installer v0.1.1
  Agentic Intelligence Digital Assistant
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# dotfiles should show both versions
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Dotfiles Installer v0.1.1
  Integrating with AIDA Framework v0.1.1
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Why**: Users need immediate context about what they're installing.

**2. Graceful Version Compatibility Checking** (HIGH PRIORITY)

```bash
# In lib/installer-common/validation.sh

check_version_compatibility() {
    local required_version="$1"
    local actual_version="$2"
    local component_name="$3"

    # Parse versions
    local req_major="${required_version%%.*}"
    local act_major="${actual_version%%.*}"

    # Major version mismatch = hard error
    if [[ "$req_major" != "$act_major" ]]; then
        print_message "error" "Incompatible $component_name version"
        echo ""
        echo "  Required: $required_version (major version $req_major)"
        echo "  Found:    $actual_version (major version $act_major)"
        echo ""
        echo "This is a breaking change. Please upgrade $component_name:"
        echo "  cd ~/.aida && git pull && ./install.sh"
        echo ""
        return 1
    fi

    # Minor/patch differences = warning only
    if [[ "$required_version" != "$actual_version" ]]; then
        print_message "warning" "Version mismatch detected (non-breaking)"
        echo ""
        echo "  Expected: $required_version"
        echo "  Found:    $actual_version"
        echo ""
        echo "Installation will continue, but consider upgrading for best compatibility."
        echo ""
    fi

    return 0
}
```

**Why**: Reduces user anxiety, provides clear upgrade path.

**3. Smart Library Sourcing** (MEDIUM PRIORITY)

```bash
# In dotfiles/install.sh

# Try to source AIDA installer lib
AIDA_LIB_DIR="${HOME}/.aida/lib/installer-common"

if [[ -d "$AIDA_LIB_DIR" ]]; then
    # AIDA installed - use its library
    for lib_file in colors.sh logging.sh validation.sh platform-detect.sh; do
        if [[ -f "$AIDA_LIB_DIR/$lib_file" ]]; then
            # shellcheck source=/dev/null
            source "$AIDA_LIB_DIR/$lib_file"
        else
            echo "WARNING: Missing library file: $lib_file"
            echo "AIDA installation may be incomplete. Reinstall AIDA:"
            echo "  cd ~/.aida && ./install.sh"
        fi
    done

    USING_AIDA_LIB=true
else
    # AIDA not installed - use bundled minimal lib
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$SCRIPT_DIR/lib/installer-minimal.sh"

    USING_AIDA_LIB=false

    echo "Note: AIDA framework not detected. Using standalone mode."
    echo "To enable AIDA integration, install AIDA first:"
    echo "  git clone <repo> ~/.aida && cd ~/.aida && ./install.sh"
    echo ""
fi
```

**Why**: Handles both standalone and integrated scenarios gracefully.

**4. Consistent Error Message Format** (HIGH PRIORITY)

```bash
# Standard error template in logging.sh

log_error_with_help() {
    local error_msg="$1"
    local help_msg="$2"

    print_message "error" "$error_msg"
    echo ""
    if [[ -n "$help_msg" ]]; then
        echo "$help_msg"
        echo ""
    fi
}

# Usage
log_error_with_help \
    "Failed to create directory: $dir" \
    "Check permissions: ls -ld $(dirname "$dir")
Ensure parent directory exists and is writable."
```

**Why**: Actionable errors reduce support burden and user frustration.

**5. Platform Detection Transparency** (MEDIUM PRIORITY)

```bash
# In platform-detect.sh

detect_platform() {
    print_message "info" "Detecting platform..."

    case "$(uname -s)" in
        Darwin*)
            PLATFORM="macos"
            print_message "success" "Platform: macOS ($(sw_vers -productVersion))"
            ;;
        Linux*)
            PLATFORM="linux"
            print_message "success" "Platform: Linux ($(uname -r))"
            ;;
        *)
            PLATFORM="unsupported"
            print_message "warning" "Platform: $(uname -s) (experimental support)"
            ;;
    esac

    export PLATFORM
}
```

**Why**: Users should know if they're on a supported platform before errors occur.

### What to Avoid

## DON'T: Silent Failures

```bash
# BAD
source ~/.aida/lib/installer-common/colors.sh 2>/dev/null

# GOOD
if ! source ~/.aida/lib/installer-common/colors.sh; then
    echo "ERROR: Failed to load installer library"
    exit 1
fi
```

## DON'T: Assume User Knowledge

```bash
# BAD
echo "Version mismatch: 0.1.1 vs 0.2.0"

# GOOD
echo "Version mismatch detected:"
echo "  AIDA version:     0.1.1"
echo "  Required version: 0.2.0"
echo ""
echo "What this means: The dotfiles installer needs a newer AIDA version."
echo "How to fix: cd ~/.aida && git pull && ./install.sh"
```

## DON'T: Block Without Explanation

```bash
# BAD
[[ $version_ok ]] || exit 1

# GOOD
if ! check_version_compatibility "$required" "$actual" "AIDA"; then
    echo "Installation cannot continue due to version incompatibility."
    echo "Please resolve the version mismatch and try again."
    exit 1
fi
```

## DON'T: Duplicate Code

```bash
# BAD: Each installer has its own print_message()

# GOOD: Shared lib/installer-common/logging.sh
# Both installers source and use the same function
```

## DON'T: Over-Engineer Initially

- Start with simple VERSION file (just version number)
- Add metadata later if needed
- Don't create 5 utility files if 2 would suffice
- Focus on the critical path: colors, logging, validation

### Implementation Priority

**Phase 1 - Foundation** (MVP for issue #33):

1. Create VERSION file (already exists ✓)
2. Create lib/installer-common/ with:
   - colors.sh (color codes, already in install.sh)
   - logging.sh (print_message function)
   - validation.sh (version checking)

3. Update AIDA install.sh to source from lib/
4. Document sourcing pattern for dotfiles

**Phase 2 - Enhanced UX** (v0.2):

5. Add platform-detect.sh
6. Add detailed version compatibility matrix
7. Implement smart version mismatch handling
8. Add --version flag to installers

**Phase 3 - Polish** (v0.3):

9. Add installation telemetry (opt-in)
10. Create troubleshooting command (aida doctor)
11. Add rollback capability for failed installs

## Testing Recommendations

**UX Testing Scenarios**:

1. **Happy path**: Fresh install, both versions match → should feel effortless
2. **Version mismatch**: AIDA 0.1.0, dotfiles expects 0.2.0 → clear error + upgrade instructions
3. **Missing AIDA**: Install dotfiles without AIDA → graceful fallback or clear error
4. **Partial AIDA**: lib/installer-common/ incomplete → detect and report specifically
5. **No-color terminal**: Installation should work without color codes
6. **Permission errors**: Clear explanation of which paths need access

**User Feedback Metrics**:

- Can a new user complete install without documentation?
- Are error messages sufficient to self-recover?
- Does output provide confidence (or anxiety)?

## Conclusion

This shared library is **critical UX infrastructure**. Done right, users barely notice it. Done wrong, they abandon installation.

**Key Success Criteria**:

- Clear version visibility
- Graceful error handling with actionable steps
- Consistent look/feel across installers
- Support for standalone and integrated scenarios

**Biggest Risk**:

- Coupling between repos creating fragile installation flows
- Mitigate with: thorough testing, clear documentation, graceful degradation

**Recommendation**: Proceed with implementation, prioritize Phase 1 (foundation) for v0.1.2, add Phase 2 (enhanced UX) for v0.2.
