---
title: "Shell Script Specialist Technical Analysis"
issue: 53
document_type: "technical-analysis"
created: "2025-10-18"
version: "1.0"
status: "draft"
agent: "shell-script-specialist"
---

# Shell Script Specialist Analysis: Modular Installer Refactoring

**Issue**: #53 - Modular installer refactoring with deprecation support
**Current State**: 625-line monolithic install.sh
**Target**: Modular lib/installer-common/ with ~150-line orchestrator
**Platforms**: Bash 3.2+, Linux/macOS/Windows WSL

---

## 1. Implementation Approach

### Modular Design Patterns

**Module initialization order** (critical for dependencies):

```bash
# install.sh orchestrator pattern
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly INSTALLER_COMMON="${SCRIPT_DIR}/lib/installer-common"

# Source order (dependencies first)
source "${INSTALLER_COMMON}/colors.sh"      # No deps
source "${INSTALLER_COMMON}/logging.sh"     # Requires colors.sh
source "${INSTALLER_COMMON}/validation.sh"  # Requires logging.sh
source "${INSTALLER_COMMON}/variables.sh"   # Requires validation.sh
source "${INSTALLER_COMMON}/directories.sh" # Requires logging.sh, variables.sh
source "${INSTALLER_COMMON}/templates.sh"   # Requires directories.sh, variables.sh
source "${INSTALLER_COMMON}/prompts.sh"     # Requires logging.sh
source "${INSTALLER_COMMON}/deprecation.sh" # Requires validation.sh, variables.sh
source "${INSTALLER_COMMON}/summary.sh"     # Requires logging.sh
```

**Function naming conventions**:

- `verb_noun()` - Public API (e.g., `install_templates`, `check_version`)
- `_verb_noun()` - Internal helpers (e.g., `_parse_frontmatter`, `_substitute_vars`)
- `validate_*()` - Validation functions (return 0/1)
- `check_*()` - Boolean checks (return 0/1)
- `print_*()` - Output functions (side effects only)

**Module responsibility boundaries**:

```bash
# templates.sh - Template installation
install_templates()      # Main entry point
install_template_file()  # Single file installation
create_namespace_dirs()  # .aida/ namespace creation

# deprecation.sh - Deprecation management
check_deprecated_status()  # Parse frontmatter
move_to_deprecated()       # Relocate to .aida-deprecated/
cleanup_deprecated()       # Remove based on remove_in version

# variables.sh - Variable substitution
substitute_install_vars()  # {{VAR}} -> actual paths
preserve_runtime_vars()    # ${VAR} kept for bash resolution
validate_substitution()    # Check no {{VAR}} remain

# prompts.sh - User interaction
prompt_assistant_name()
prompt_personality()
prompt_confirm()          # Generic Y/N confirmation
prompt_multiselect()      # Menu-based selection

# directories.sh - Directory management
create_aida_dir()         # ~/.aida/ (symlink or copy)
create_claude_dirs()      # ~/.claude/{commands,agents,skills}/
backup_existing()         # Timestamp-based backups

# summary.sh - Output formatting
display_summary()         # Installation summary
display_changes()         # What changed (idempotent re-runs)
display_next_steps()      # Actionable next steps
```

### Parameter-Based Design (Not Globals)

**Current problem**: Functions rely on globals, not reusable

**Solution**: Pass parameters explicitly

```bash
# Bad (current pattern)
copy_command_templates() {
  local template_dir="${SCRIPT_DIR}/templates/commands"
  local install_dir="${CLAUDE_DIR}/commands"
  # Uses globals: SCRIPT_DIR, CLAUDE_DIR, DEV_MODE, HOME
}

# Good (reusable pattern)
install_templates() {
  local src_dir="$1"
  local dst_dir="$2"
  local dev_mode="${3:-false}"
  local namespace="${4:-.aida}"

  # All inputs explicit, no global assumptions
}
```

**Benefits**:

- Dotfiles repo can call with different paths
- Unit testable with mock directories
- No assumptions about `$PWD` or repo root

---

## 2. Technical Decisions

### Symlink vs Copy Implementation

**Recommendation**: ALWAYS symlink `~/.aida/`, mode controls template behavior

```bash
# install.sh flow
if [[ "$DEV_MODE" == true ]]; then
  # Symlink framework
  ln -s "${SCRIPT_DIR}" "${AIDA_DIR}"

  # Symlink templates for live editing
  ln -s "${AIDA_DIR}/templates/commands" "${CLAUDE_DIR}/commands/.aida"
  ln -s "${AIDA_DIR}/templates/agents" "${CLAUDE_DIR}/agents/.aida"
else
  # Symlink framework (enables git pull updates)
  ln -s "${SCRIPT_DIR}" "${AIDA_DIR}"

  # Copy templates with variable substitution
  copy_templates_with_substitution \
    "${AIDA_DIR}/templates/commands" \
    "${CLAUDE_DIR}/commands/.aida"
fi
```

**Rationale**:

- PRD now specifies: "Always symlink ~/.aida/ to repository"
- Normal mode: Framework updates via `git pull`, templates static (substituted)
- Dev mode: Both framework AND templates live-edit
- Reduces disk usage (framework ~10MB, templates ~100KB)

### Variable Substitution Strategy

**Three-tier variable system**:

| Type | Pattern | When Resolved | Example |
|------|---------|---------------|---------|
| Install-time | `{{VAR}}` | During install.sh | `{{AIDA_HOME}}` → `/Users/rob/.aida` |
| Runtime | `${VAR}` | When command runs | `${PROJECT_ROOT}` → `$(git rev-parse --show-toplevel)` |
| Computed | `$(cmd)` | When command runs | `$(date +%Y-%m-%d)` → `2025-10-18` |

**Implementation** (sed-based, Bash 3.2 compatible):

```bash
substitute_install_vars() {
  local src_file="$1"
  local dst_file="$2"
  local aida_home="$3"
  local claude_dir="$4"
  local home_dir="$5"

  # Substitute ONLY install-time variables
  # Preserve ${VAR} and $(cmd) for runtime resolution
  sed \
    -e "s|{{AIDA_HOME}}|${aida_home}|g" \
    -e "s|{{CLAUDE_CONFIG_DIR}}|${claude_dir}|g" \
    -e "s|{{HOME}}|${home_dir}|g" \
    "${src_file}" > "${dst_file}"

  # Validation: ensure install-time vars substituted
  if grep -qE '\{\{(AIDA_HOME|CLAUDE_CONFIG_DIR|HOME)\}\}' "${dst_file}"; then
    print_message "error" "Unresolved install-time variables in ${dst_file}"
    return 1
  fi
}
```

**Why sed over envsubst**:

- envsubst would replace ALL ${VAR}, breaking runtime variables
- sed gives precise control over ONLY install-time patterns
- Bash 3.2 compatible (macOS default)
- No additional dependencies

**Dev mode consideration**:

- Problem: Symlinked templates can't have substituted variables
- Solution: Runtime wrapper resolves variables on-the-fly

```bash
# For dev mode, create runtime resolution wrapper
resolve_dev_vars() {
  local template="$1"

  # Export variables for envsubst
  export AIDA_HOME="${HOME}/.aida"
  export CLAUDE_CONFIG_DIR="${HOME}/.claude"

  # Substitute and output to stdout
  envsubst < "$template"
}
```

### Path Normalization Across Platforms

**Cross-platform path handling**:

```bash
# Canonical path resolution (Bash 3.2 compatible)
canonicalize_path() {
  local path="$1"

  # Tilde expansion
  path="${path/#\~/$HOME}"

  # Convert to absolute
  if [[ "$path" != /* ]]; then
    path="$(pwd)/$path"
  fi

  # Platform-specific canonicalization
  if command -v realpath >/dev/null 2>&1; then
    # Linux/macOS with coreutils
    realpath -m "$path"
  elif command -v python3 >/dev/null 2>&1; then
    # Fallback: Python (always available)
    python3 -c "import os; print(os.path.realpath('$path'))"
  else
    # Last resort: manual normalization
    echo "$path" | sed -e 's|/\./|/|g' -e 's|//|/|g'
  fi
}
```

**Symlink handling** (platform differences):

```bash
# macOS: readlink doesn't have -f flag
get_symlink_target() {
  local symlink="$1"

  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS (BSD readlink)
    readlink "$symlink"
  else
    # Linux (GNU readlink)
    readlink -f "$symlink"
  fi
}
```

---

## 3. Key Technical Risks

### Bash 3.2 Limitations (macOS Default)

**Missing features** (vs Bash 4+):

- No associative arrays (`declare -A`)
- No `&>` redirection shorthand
- No `|&` pipe shorthand
- No `**` globstar

**Workarounds**:

```bash
# Bad (Bash 4+): Associative arrays
declare -A config
config[key]="value"

# Good (Bash 3.2): Simulated with strings
config_keys="key1 key2 key3"
config_key1="value1"
config_key2="value2"
lookup_config() {
  local key="$1"
  eval echo "\$config_${key}"
}

# Bad (Bash 4+): &> redirection
command &> /dev/null

# Good (Bash 3.2): Explicit redirection
command > /dev/null 2>&1

# Bad (Bash 4+): Globstar
shopt -s globstar
files=( **/*.md )

# Good (Bash 3.2): find
mapfile -t files < <(find . -name "*.md")  # Bash 4+
# OR
files=()
while IFS= read -r file; do
  files+=("$file")
done < <(find . -name "*.md")
```

**Testing strategy**: CI matrix MUST include macOS with default Bash 3.2

### Cross-Platform Symlink Handling

**Risk areas**:

1. **Windows WSL** - Symlinks may not cross filesystem boundaries
2. **macOS case-insensitive** - Filesystem may be case-insensitive APFS
3. **Symlink loop detection** - Prevent circular references

**Mitigation**:

```bash
# Safe symlink creation
create_symlink() {
  local target="$1"
  local link_name="$2"

  # Check if target exists
  if [[ ! -e "$target" ]]; then
    print_message "error" "Symlink target does not exist: ${target}"
    return 1
  fi

  # Remove existing symlink (idempotent)
  if [[ -L "$link_name" ]]; then
    rm "$link_name"
  elif [[ -e "$link_name" ]]; then
    # Existing file/directory - backup first
    backup_existing "$link_name"
  fi

  # Create symlink
  ln -s "$target" "$link_name" || {
    print_message "error" "Failed to create symlink: ${link_name} -> ${target}"
    return 1
  }

  # Validate symlink
  if [[ ! -L "$link_name" ]]; then
    print_message "error" "Symlink creation failed silently"
    return 1
  fi
}
```

**Windows-specific considerations**:

- WSL: Symlinks work within WSL filesystem (`/home/user/`)
- WSL: Symlinks MAY fail crossing to Windows mounts (`/mnt/c/`)
- Testing: Require WSL testing in CI/CD

### Variable Substitution Edge Cases

**Risk scenarios**:

1. **User paths with spaces** - `/Users/John Doe/.aida/`
2. **Variable name collisions** - Template has `{{HOME}}` AND `${HOME}`
3. **Escaped braces** - `\{\{VAR\}\}` should NOT be substituted
4. **Partial patterns** - `{{AIDA` or `AIDA_HOME}}` (incomplete)

**Test cases required**:

```bash
# Test: Paths with spaces
HOME="/Users/John Doe"
install_templates "/path/to/templates" "${HOME}/.claude/commands/.aida"

# Test: Variable collision (runtime ${HOME} preserved)
template='Path: {{HOME}}/.aida and current $HOME'
# After substitution should be:
# Path: /Users/rob/.aida and current $HOME

# Test: Escaped braces (don't substitute)
template='Literal: \{\{HOME\}\}'
# Should remain: Literal: {{HOME}}

# Test: Incomplete patterns (error detection)
template='Bad: {{AIDA_HOME missing close'
# Should fail validation
```

**Robust sed pattern**:

```bash
# Substitute ONLY complete {{VAR}} patterns
# Preserve ${VAR} and escaped \{\{VAR\}\}
sed \
  -e 's|{{AIDA_HOME}}|'"${aida_home}"'|g' \
  -e 's|{{CLAUDE_CONFIG_DIR}}|'"${claude_dir}"'|g' \
  -e 's|{{HOME}}|'"${home_dir}"'|g'

# Note: Use |'"${var}"'| instead of |${var}|
# Prevents sed from interpreting special chars in paths
```

---

## 4. Dependencies & Integration

### External Tools Required

**Core dependencies** (install.sh):

```bash
required_commands=(
  "git"       # Version control
  "mkdir"     # Directory creation
  "chmod"     # Permissions
  "ln"        # Symlinks
  "rsync"     # File copying (preserves metadata)
  "sed"       # Variable substitution
  "find"      # File discovery
  "date"      # Timestamps
  "mv"        # Backups
  "realpath"  # Path canonicalization (macOS: brew install coreutils)
)
```

**Optional dependencies** (enhanced features):

```bash
optional_commands=(
  "python3"   # Fallback for path canonicalization
  "tput"      # Terminal color support
  "column"    # Table formatting (summary display)
)
```

**Validation pattern**:

```bash
validate_dependencies() {
  local errors=0

  for cmd in "${required_commands[@]}"; do
    if ! command -v "$cmd" &> /dev/null; then
      print_message "error" "Required: $cmd"
      errors=$((errors + 1))
    fi
  done

  for cmd in "${optional_commands[@]}"; do
    if ! command -v "$cmd" &> /dev/null; then
      print_message "warning" "Optional: $cmd (some features disabled)"
    fi
  done

  return "$errors"
}
```

### Integration with Existing lib/installer-common/

**Current modules** (already implemented):

- `colors.sh` - Terminal color utilities
- `logging.sh` - Message output and log file management
- `validation.sh` - Input validation, version checking, security

**New modules to add**:

```bash
lib/installer-common/
├── colors.sh           # (existing)
├── logging.sh          # (existing)
├── validation.sh       # (existing)
├── variables.sh        # (new) Variable substitution
├── directories.sh      # (new) Directory/symlink management
├── templates.sh        # (new) Template installation
├── prompts.sh          # (new) User interaction
├── deprecation.sh      # (new) Deprecation lifecycle
└── summary.sh          # (new) Output formatting
```

**Dependency graph**:

```text
colors.sh (no deps)
  └── logging.sh
      ├── validation.sh
      │   ├── variables.sh
      │   └── deprecation.sh
      ├── prompts.sh
      ├── directories.sh
      └── summary.sh
templates.sh (requires: directories.sh, variables.sh)
```

### Dotfiles Repo Sourcing Pattern

**Dotfiles installer flow**:

```bash
#!/usr/bin/env bash
# ~/dotfiles/install.sh

set -euo pipefail

# Check if AIDA installed
if [[ -d "${HOME}/.aida" ]]; then
  readonly INSTALLER_COMMON="${HOME}/.aida/lib/installer-common"

  # Version check
  if [[ -f "${HOME}/.aida/VERSION" ]]; then
    AIDA_VERSION=$(cat "${HOME}/.aida/VERSION")
    REQUIRED_VERSION="0.2.0"

    # Source validation module to check compatibility
    source "${INSTALLER_COMMON}/colors.sh"
    source "${INSTALLER_COMMON}/logging.sh"
    source "${INSTALLER_COMMON}/validation.sh"

    if check_version_compatibility "$AIDA_VERSION" "$REQUIRED_VERSION"; then
      # Source additional modules
      source "${INSTALLER_COMMON}/templates.sh"
      source "${INSTALLER_COMMON}/variables.sh"
      AIDA_AVAILABLE=true
    else
      print_message "warning" "AIDA version incompatible, using fallback"
      AIDA_AVAILABLE=false
    fi
  fi
else
  echo "AIDA not installed, using standalone mode"
  AIDA_AVAILABLE=false
fi

# Install dotfiles
if [[ "$AIDA_AVAILABLE" == true ]]; then
  # Use AIDA libraries for consistency
  install_templates \
    "${PWD}/templates/commands" \
    "${HOME}/.claude/commands/.dotfiles"
else
  # Fallback: manual installation
  cp -r "${PWD}/templates/commands" "${HOME}/.claude/commands/.dotfiles"
fi
```

**API contract** (semantic versioning):

- **MAJOR version** - Breaking changes to function signatures
- **MINOR version** - New features, backward compatible
- **PATCH version** - Bug fixes, no API changes

**Version checking**:

```bash
# validation.sh provides this function
check_version_compatibility() {
  local installed="$1"  # e.g., "0.2.1"
  local required="$2"   # e.g., "0.2.0"

  # Major must match exactly
  # Minor must be >= required
  # Patch doesn't matter

  # Returns 0 if compatible, 1 if not
}
```

---

## 5. Testing Strategy

### Unit Testing Bash Functions

**Testing framework**: bats (Bash Automated Testing System)

```bash
# tests/lib/variables.bats
#!/usr/bin/env bats

load test_helper

@test "substitute_install_vars replaces install-time variables" {
  # Setup
  cat > /tmp/test_template.md <<EOF
Path: {{AIDA_HOME}}/lib
Config: {{CLAUDE_CONFIG_DIR}}/config
Home: {{HOME}}/documents
Runtime: \${PROJECT_ROOT}/src
EOF

  # Execute
  run substitute_install_vars \
    /tmp/test_template.md \
    /tmp/test_output.md \
    "/Users/test/.aida" \
    "/Users/test/.claude" \
    "/Users/test"

  # Assert
  [ "$status" -eq 0 ]
  grep -q "Path: /Users/test/.aida/lib" /tmp/test_output.md
  grep -q "Runtime: \${PROJECT_ROOT}/src" /tmp/test_output.md
}

@test "substitute_install_vars preserves runtime variables" {
  # Test that ${VAR} and $(cmd) are NOT substituted
}

@test "substitute_install_vars handles spaces in paths" {
  # Test with path="/Users/John Doe/.aida"
}
```

**Test coverage targets**:

- `variables.sh` - 90%+ (critical substitution logic)
- `deprecation.sh` - 85%+ (version parsing, frontmatter)
- `validation.sh` - 95%+ (security-critical)
- `templates.sh` - 80%+ (integration focus)

### Integration Test Scenarios

**Docker-based testing** (clean environments):

```bash
# .github/testing/test-install.sh
#!/usr/bin/env bash

test_fresh_install() {
  # Clean environment
  docker run --rm -v "${PWD}:/repo" ubuntu:22.04 bash -c "
    cd /repo
    ./install.sh
    test -L ~/.aida || exit 1
    test -d ~/.claude/commands/.aida || exit 1
    test -f ~/CLAUDE.md || exit 1
  "
}

test_dev_mode_install() {
  # Dev mode: symlinks for live editing
  docker run --rm -v "${PWD}:/repo" ubuntu:22.04 bash -c "
    cd /repo
    ./install.sh --dev
    test -L ~/.claude/commands/.aida || exit 1
    target=\$(readlink ~/.claude/commands/.aida)
    test \"\$target\" = \"/repo/templates/commands\" || exit 1
  "
}

test_upgrade_over_existing() {
  # Upgrade: user content preserved
  docker run --rm -v "${PWD}:/repo" ubuntu:22.04 bash -c "
    # First install
    cd /repo
    ./install.sh

    # User adds custom command
    echo 'test' > ~/.claude/commands/my-command.md

    # Re-install (upgrade)
    ./install.sh

    # User content must still exist
    test -f ~/.claude/commands/my-command.md || exit 1
    grep -q 'test' ~/.claude/commands/my-command.md || exit 1
  "
}

test_user_content_preservation() {
  # .aida/ namespace can be nuked, user content safe
  docker run --rm -v "${PWD}:/repo" ubuntu:22.04 bash -c "
    cd /repo
    ./install.sh

    # User content outside .aida/
    echo 'user' > ~/.claude/commands/user-cmd.md

    # Delete .aida/ namespace
    rm -rf ~/.claude/commands/.aida

    # User content still exists
    test -f ~/.claude/commands/user-cmd.md || exit 1

    # Re-install restores .aida/
    ./install.sh
    test -d ~/.claude/commands/.aida || exit 1
    test -f ~/.claude/commands/user-cmd.md || exit 1
  "
}

test_deprecated_flag() {
  # --with-deprecated flag installs to .aida-deprecated/
  docker run --rm -v "${PWD}:/repo" ubuntu:22.04 bash -c "
    cd /repo
    ./install.sh --with-deprecated
    test -d ~/.claude/commands/.aida-deprecated || exit 1
  "
}
```

**Test matrix** (platforms × modes):

| Platform | Normal Mode | Dev Mode | With Deprecated | Upgrade |
|----------|-------------|----------|-----------------|---------|
| Ubuntu 22.04 | ✅ | ✅ | ✅ | ✅ |
| macOS 13 (Bash 3.2) | ✅ | ✅ | ✅ | ✅ |
| macOS 14 (Bash 5) | ✅ | ✅ | ✅ | ✅ |
| Windows WSL2 | ✅ | ✅ | ❌ | ✅ |

### Cross-Platform Validation

**CI/CD workflow** (.github/workflows/test-install.yml):

```yaml
name: Installation Tests

on: [push, pull_request]

jobs:
  test-install:
    strategy:
      matrix:
        os: [ubuntu-22.04, macos-13, macos-14]
        mode: [normal, dev, deprecated, upgrade]

    runs-on: ${{ matrix.os }}

    steps:
      - uses: actions/checkout@v4

      - name: Install dependencies (macOS)
        if: runner.os == 'macOS'
        run: brew install coreutils  # for realpath

      - name: Test ${{ matrix.mode }} mode
        run: |
          if [[ "${{ matrix.mode }}" == "normal" ]]; then
            ./install.sh
          elif [[ "${{ matrix.mode }}" == "dev" ]]; then
            ./install.sh --dev
          elif [[ "${{ matrix.mode }}" == "deprecated" ]]; then
            ./install.sh --with-deprecated
          elif [[ "${{ matrix.mode }}" == "upgrade" ]]; then
            ./install.sh
            echo "test" > ~/.claude/commands/my-cmd.md
            ./install.sh  # Re-run
            test -f ~/.claude/commands/my-cmd.md
          fi

      - name: Validate installation
        run: |
          test -L ~/.aida
          test -d ~/.claude/commands/.aida
          test -f ~/CLAUDE.md

          # Verify user content preserved (upgrade mode)
          if [[ "${{ matrix.mode }}" == "upgrade" ]]; then
            test -f ~/.claude/commands/my-cmd.md
            grep -q "test" ~/.claude/commands/my-cmd.md
          fi

      - name: Upload logs on failure
        if: failure()
        uses: actions/upload-artifact@v4
        with:
          name: install-logs-${{ matrix.os }}-${{ matrix.mode }}
          path: ~/.aida/logs/install.log
```

**Local testing** (Makefile):

```makefile
.PHONY: test test-install test-dev test-upgrade test-all

test: test-install

test-install:
    @echo "Testing normal installation..."
    @./.github/testing/test-install.sh --mode normal

test-dev:
    @echo "Testing dev mode installation..."
    @./.github/testing/test-install.sh --mode dev

test-deprecated:
    @echo "Testing deprecated installation..."
    @./.github/testing/test-install.sh --mode deprecated

test-upgrade:
    @echo "Testing upgrade over existing..."
    @./.github/testing/test-install.sh --mode upgrade

test-user-content:
    @echo "Testing user content preservation..."
    @./.github/testing/test-install.sh --mode user-content

test-all: test-install test-dev test-deprecated test-upgrade test-user-content
    @echo "All tests passed!"
```

---

## 6. Effort Estimate

### Complexity: **LARGE**

**Breakdown by module**:

| Module | Lines | Complexity | Effort | Risk |
|--------|-------|------------|--------|------|
| `variables.sh` | ~150 | Medium | 4h | Medium (edge cases) |
| `directories.sh` | ~200 | Medium | 5h | Medium (symlinks) |
| `templates.sh` | ~250 | High | 8h | High (integration) |
| `prompts.sh` | ~120 | Low | 3h | Low |
| `deprecation.sh` | ~180 | High | 6h | High (version logic) |
| `summary.sh` | ~100 | Low | 2h | Low |
| Refactor `install.sh` | ~150 | Medium | 4h | Medium (orchestration) |
| Unit tests (bats) | ~400 | Medium | 8h | Low |
| Integration tests | ~300 | High | 8h | Medium (Docker setup) |
| CI/CD workflows | ~100 | Medium | 4h | Low |
| Documentation | ~200 | Low | 3h | Low |
| **TOTAL** | **~2150** | **N/A** | **55h** | **N/A** |

### Key Effort Drivers

1. **Template installation logic** (8h)
   - Normal vs dev mode handling
   - Variable substitution integration
   - Namespace isolation (.aida/ vs .aida-deprecated/)
   - Idempotent re-installation

2. **Integration testing** (8h)
   - Docker environment setup
   - Test scenarios (fresh, upgrade, user content)
   - Cross-platform validation
   - CI/CD integration

3. **Deprecation system** (6h)
   - Frontmatter parsing (YAML)
   - Version comparison logic
   - Migration warnings
   - Cleanup automation

4. **Cross-platform compatibility** (ongoing)
   - Bash 3.2 constraints
   - macOS vs Linux path handling
   - Symlink behavior differences
   - Windows WSL testing

### Risk Areas Requiring Spikes

**Spike 1: Dev mode variable substitution** (4h)

- **Problem**: Symlinked templates can't have substituted variables
- **Question**: Runtime resolution wrapper? Double-install pattern?
- **Output**: Proof-of-concept for dev mode variable handling

**Spike 2: Frontmatter parsing in pure Bash** (3h)

- **Problem**: YAML frontmatter parsing without external tools (yq, python)
- **Question**: Regex-based extraction? sed/awk patterns?
- **Output**: Robust frontmatter parser in Bash 3.2

**Spike 3: Windows symlink support** (2h)

- **Problem**: Windows symlinks require admin privileges OR developer mode
- **Question**: Fall back to copies on Windows? Detect and warn?
- **Output**: Windows compatibility strategy

**Total spike effort**: ~9h (included in 55h estimate)

### Critical Path

1. **Phase 1** (Foundation) - 20h
   - Extract `variables.sh`, `directories.sh`, `prompts.sh`
   - Basic unit tests (bats)
   - Refactor `install.sh` to orchestrator

2. **Phase 2** (Advanced Features) - 20h
   - Implement `templates.sh` with namespace isolation
   - Implement `deprecation.sh` with frontmatter parsing
   - Integration tests (Docker)

3. **Phase 3** (CI/CD & Documentation) - 15h
   - CI/CD workflows (GitHub Actions)
   - Cross-platform testing
   - Documentation and examples

**Timeline**: ~7 days (assuming 8h/day, single developer)

---

## Key Recommendations

### Must Have (Blocking)

1. ✅ **Bash 3.2 compatibility testing** - CI matrix includes macOS default Bash
2. ✅ **User content preservation tests** - Validate .aida/ namespace isolation
3. ✅ **Idempotent installation** - Safe to re-run without data loss
4. ✅ **Dotfiles integration validation** - Test sourcing from external repo

### Should Have (Important)

5. ✅ **Progress indicators** - Long operations show spinner/percentage
6. ✅ **Helpful error messages** - Include recovery instructions
7. ✅ **Pre-flight validation** - Check dependencies before starting
8. ✅ **Comprehensive logging** - All operations logged to ~/.aida/logs/install.log

### Nice to Have (Defer if needed)

9. ❌ **Pre-flight installation plan** - Show what will change before applying
10. ❌ **Rollback capability** - Undo failed installations
11. ❌ **Installation time estimates** - Progress with ETA
12. ❌ **Interactive mode** - Step-by-step with confirmations

---

## Next Steps

1. **Implement spikes** - Resolve open questions (dev mode vars, frontmatter parsing)
2. **Create module skeletons** - Stub out all 6 new modules with function signatures
3. **Extract one module** - Start with `prompts.sh` (lowest risk, no deps)
4. **Add unit tests** - bats framework for extracted module
5. **Iterate** - Extract remaining modules one at a time with tests

**Recommended order**:

1. `prompts.sh` (low risk, standalone)
2. `variables.sh` (foundational for templates)
3. `directories.sh` (foundational for templates)
4. `summary.sh` (low risk, standalone)
5. `templates.sh` (integration of variables + directories)
6. `deprecation.sh` (highest complexity, depends on variables)

---

**Author**: shell-script-specialist agent
**Date**: 2025-10-18
**Status**: Ready for implementation
