---
title: "Integration Specialist Analysis - Issue #33"
issue: 33
agent: "integration-specialist"
date: "2025-10-06"
status: "draft"
---

# Integration Specialist Analysis - Issue #33

## Domain-Specific Concerns

### Integration Architecture

- **One-way dependency pattern**: AIDA provides shared library, dotfiles consumes it. Clean separation.
- **Version coupling**: Dotfiles tightly coupled to specific AIDA versions via `.aida-version` file.
- **Runtime sourcing**: Dotfiles installer sources utilities from `~/.aida/lib/installer-common/` at runtime.
- **No circular dependency**: AIDA standalone, dotfiles depend on AIDA (good design).
- **Installation order matters**: AIDA must be cloned/installed before dotfiles can source utilities.

### GNU Stow Integration Implications

- **Stow package independence**: `lib/installer-common/` lives in AIDA repository, NOT in dotfiles stow packages.
- **No stow conflicts**: Utilities sourced at runtime during install, not stowed to home directory.
- **Private overlay compatibility**: dotfiles-private can still overlay dotfiles without touching AIDA lib.
- **Template sourcing pattern**: Aligns with "inverted template" model - AIDA provides templates, user configs source them.

### Cross-Repository Integration

- **Three-repo coordination**:
  - `claude-personal-assistant` (this repo): Provides `VERSION` + `lib/installer-common/`
  - `dotfiles`: Consumes utilities, specifies version requirements via `.aida-version`
  - `dotfiles-private`: Unaffected, overlays dotfiles only

- **Version synchronization**: Must coordinate releases between AIDA and dotfiles repos.
- **Breaking changes**: Changes to installer-common API require coordinated updates across repos.

### Installation Flow Impact

**Current AIDA-first flow**:

```bash
# 1. Clone AIDA → 2. Run AIDA install → 3. Optional: dotfiles
```

**New dotfiles-first flow enabled**:

```bash
# 1. Clone dotfiles → 2. Dotfiles installer clones AIDA → 3. Sources lib/ → 4. Proceeds
```

**Key integration point**: Dotfiles installer must clone specific AIDA version tag before sourcing utilities.

## Stakeholder Impact

### Affected Parties

- **End users**: Installation experience improves with consistent logging/colors across installers.
- **Dotfiles maintainer**: Can now implement dotfiles installer with shared utilities.
- **AIDA maintainer**: Must maintain installer-common API stability for external consumers.
- **Contributors**: New contributors need to understand shared library sourcing pattern.

### Value Provided

- **Code reuse**: Shared utilities eliminate duplication between installers.
- **Consistent UX**: Same logging, colors, validation across AIDA and dotfiles installers.
- **Version safety**: Explicit version checking prevents incompatible combinations.
- **Maintainability**: Bug fixes to installer-common benefit both repos.

### Risks & Downsides

- **API stability requirement**: Changes to installer-common break dotfiles installer.
- **Version lock-in**: Dotfiles tied to specific AIDA versions, limits flexibility.
- **Testing complexity**: Must test multiple AIDA/dotfiles version combinations.
- **Git clone dependency**: Dotfiles installer requires internet to clone AIDA (can't be fully offline).
- **Failed clone scenario**: If AIDA clone fails, dotfiles installer is blocked.

## Questions & Clarifications

### Missing Information

- **Offline installation**: How to handle environments without internet access? Pre-bundled AIDA?
- **Version upgrade path**: When user has old AIDA, how does dotfiles installer handle upgrade?
- **Library versioning**: Should installer-common have its own version separate from AIDA version?
- **Error handling**: What if specific AIDA version tag doesn't exist when dotfiles tries to clone?
- **Fallback mechanism**: Should dotfiles have vendored copy of installer-common as fallback?

### Decisions Needed

1. **Library API stability guarantee**:
   - Option A: Semantic versioning for installer-common (major.minor.patch)
   - Option B: Pin to AIDA version (installer-common v0.1.0 = AIDA v0.1.0)
   - **Recommendation**: Option B for simplicity in v0.1, consider Option A for v1.0+

2. **Clone strategy in dotfiles**:
   - Option A: Always clone specific tag (`git clone --branch v0.1.0`)
   - Option B: Clone main, check VERSION, abort if mismatch
   - **Recommendation**: Option A - safer, explicit version control

3. **Existing AIDA handling**:
   - Scenario: User already has `~/.aida/` from previous install
   - Option A: Check version, abort if incompatible
   - Option B: Backup and re-clone required version
   - Option C: Upgrade in place if possible
   - **Recommendation**: Option A for v0.1 (simplest), Option C for future

4. **Failed sourcing recovery**:
   - Option A: Abort dotfiles install if AIDA clone/source fails
   - Option B: Warn and continue with basic functionality
   - **Recommendation**: Option A - safer, clearer dependencies

### Assumptions to Validate

- **Assumption**: Dotfiles installer will always clone fresh AIDA, not use existing `~/.aida/`
  - **Validate**: What if user already installed AIDA standalone?

- **Assumption**: `lib/installer-common/` utilities have no dependencies beyond bash builtins
  - **Validate**: Ensure no external command dependencies (jq, curl, etc.)

- **Assumption**: Version format is strict semantic versioning (MAJOR.MINOR.PATCH)
  - **Validate**: Confirm no pre-release tags (alpha, beta, rc) for v0.1

- **Assumption**: Dotfiles will source ALL files from installer-common/
  - **Validate**: Or should dotfiles cherry-pick only needed utilities?

## Recommendations

### Prioritized Approach

#### Phase 1: Core Structure (P0 - Blocking)

1. **Create `lib/installer-common/` with minimal utilities**:
   - `colors.sh` - Terminal color functions
   - `logging.sh` - Success/error/info/warning logging
   - `validation.sh` - Basic input validation (non-empty, regex match)

2. **Refactor AIDA `install.sh` to use installer-common**:
   - Replace inline functions with sourced utilities
   - Validates library is self-contained and functional

3. **VERSION file already exists** (0.1.1) - good!

#### Phase 2: Integration Testing (P0 - Blocking)

4. **Test sourcing from external script**:
   - Create test script outside repo that sources from `~/.aida/lib/`
   - Validates dotfiles sourcing pattern works

5. **Document sourcing pattern**:
   - Add README in `lib/installer-common/` explaining usage
   - Document version compatibility contract

#### Phase 3: Future Enhancements (P1 - Post v0.1)

6. **Add platform detection** (`platform-detect.sh`):
   - macOS detection (primary)
   - Linux detection (future)
   - Currently not needed for v0.1 (macOS only)

7. **Library versioning metadata**:
   - Add `lib/installer-common/VERSION` with API version
   - Separate from AIDA version for better API stability

### What to Prioritize

**MUST HAVE for v0.1.0**:

- `lib/installer-common/colors.sh`
- `lib/installer-common/logging.sh`
- `lib/installer-common/validation.sh`
- AIDA `install.sh` refactored to use library
- Unit tests for each utility file
- Clear documentation of sourcing pattern

**NICE TO HAVE for v0.1.0**:

- `lib/installer-common/platform-detect.sh` (defer to v0.2 - not needed yet)
- Separate API version for installer-common (defer to v1.0)
- Offline installation support (defer to v0.3)

**DEFER to future versions**:

- Fallback mechanisms for failed clones (v0.2)
- In-place AIDA version upgrades (v0.3)
- Advanced version compatibility checks (v1.0)

### What to Avoid

**Anti-patterns to avoid**:

1. **Over-engineering**: Don't create complex dependency management system for v0.1
2. **Feature creep**: Don't add platform-detect.sh unless actually needed now
3. **Tight coupling**: Don't reference AIDA-specific paths/configs in installer-common
4. **Hidden dependencies**: Don't use external commands (jq, curl) without checking availability
5. **Silent failures**: Don't continue dotfiles install if AIDA sourcing fails

**Specific guidance**:

- **Keep utilities pure**: No side effects, just function definitions
- **No global state**: Each utility should be independently sourceable
- **Document assumptions**: What bash version, what commands available
- **Test in isolation**: Each utility file should work standalone
- **Version carefully**: Once dotfiles depends on it, API is locked

### Implementation Pattern

**Recommended file structure**:

```bash
lib/
└── installer-common/
    ├── README.md              # Usage documentation
    ├── colors.sh              # Color/formatting utilities
    ├── logging.sh             # Logging functions (depends on colors.sh)
    ├── validation.sh          # Input validation (standalone)
    └── tests/                 # Unit tests for utilities
        ├── test-colors.sh
        ├── test-logging.sh
        └── test-validation.sh
```

**Sourcing pattern for dotfiles**:

```bash
#!/usr/bin/env bash
# In dotfiles/install.sh

set -euo pipefail

readonly AIDA_REQUIRED_VERSION="v0.1.0"
readonly AIDA_PATH="${HOME}/.aida"

# Check if AIDA exists, clone if not
if [[ ! -d "$AIDA_PATH" ]]; then
    git clone --depth 1 --branch "$AIDA_REQUIRED_VERSION" \
        https://github.com/oakensoul/claude-personal-assistant.git \
        "$AIDA_PATH"
fi

# Verify version
AIDA_VERSION=$(cat "${AIDA_PATH}/VERSION")
if [[ "$AIDA_VERSION" != "0.1.0" ]]; then
    echo "Error: AIDA version mismatch. Required: 0.1.0, Found: $AIDA_VERSION"
    exit 1
fi

# Source utilities
source "${AIDA_PATH}/lib/installer-common/colors.sh"
source "${AIDA_PATH}/lib/installer-common/logging.sh"
source "${AIDA_PATH}/lib/installer-common/validation.sh"

# Now use utilities
log_success "AIDA utilities loaded successfully"
```

### Success Criteria

**Integration success indicators**:

- ✓ Dotfiles installer can source utilities without errors
- ✓ Both installers produce consistent output (same colors, formats)
- ✓ Version mismatch detected and reported clearly
- ✓ No code duplication between installers
- ✓ Unit tests pass for all utilities
- ✓ shellcheck passes for all library files
- ✓ Documentation is clear and complete

## Summary

**Bottom line**: This is a clean, well-designed integration pattern. The one-way dependency (AIDA provides, dotfiles consumes) avoids complexity. Primary risks are version lock-in and API stability requirements.

**Recommendation**: Implement minimal viable library for v0.1.0 (colors, logging, validation only). Defer platform detection and advanced features. Focus on API stability and clear documentation.

**Next steps**:

1. Create `lib/installer-common/` directory structure
2. Extract existing functions from `install.sh` into library
3. Refactor `install.sh` to source library
4. Write unit tests for utilities
5. Document sourcing pattern for dotfiles team
6. Coordinate with dotfiles repo on version strategy

---

**Integration Specialist**: Ready to implement once decisions confirmed on version strategy and existing AIDA handling.
