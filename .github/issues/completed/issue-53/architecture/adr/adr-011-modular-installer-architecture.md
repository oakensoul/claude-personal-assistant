# ADR-011: Modular Installer Architecture

**Status**: Proposed
**Date**: 2025-10-18
**Deciders**: System Architect, Tech Lead
**Context**: Software
**Tags**: architecture, installation, modularity, maintainability

## Context and Problem Statement

AIDA's installer has grown to 625 lines of monolithic shell script with business logic, user interaction, directory management, template installation, and variable substitution all intertwined. This creates several problems:

- **Maintainability**: Difficult to understand, modify, and test a 625-line monolithic script
- **Reusability**: Cannot reuse installation logic from dotfiles repository
- **Testability**: Cannot unit test individual concerns in isolation
- **Data Loss Risk**: No namespace isolation means user content can be overwritten during updates
- **Coupling**: Installation logic tightly coupled to orchestration flow

The dotfiles repository needs to reuse AIDA's installation libraries for consistent template installation, variable substitution, and user interaction. Without modular libraries, dotfiles would need to duplicate 400+ lines of complex logic.

We need to decide:

- How to decompose the monolithic installer into reusable modules
- Where to place shared installation libraries
- How to enable cross-repository code reuse (AIDA ↔ dotfiles)
- How to protect user content during framework updates
- How to maintain API stability for external consumers

## Decision Drivers

- **Maintainability**: Smaller, focused modules easier to understand and modify
- **Reusability**: Dotfiles repo needs to reuse installation logic without duplication
- **Testability**: Unit test individual modules in isolation
- **Safety**: Prevent data loss during framework updates
- **API Stability**: Provide stable API contract for dotfiles integration
- **Separation of Concerns**: Orchestration vs business logic vs user interaction
- **Single Responsibility**: Each module does one thing well

## Considered Options

### Option A: Keep Monolithic Installer (Current State)

**Description**: Keep all installation logic in single 625-line `install.sh` script

**Structure**:

```bash
install.sh (625 lines)
├── Argument parsing
├── Dependency validation
├── User prompts
├── Directory creation
├── Symlink management
├── Variable substitution
├── Template installation
├── Deprecation handling
└── Summary display
```

**Pros**:

- Simple (one file)
- No refactoring needed
- All logic in one place

**Cons**:

- Unmaintainable (625 lines is too large)
- Untestable (cannot unit test individual concerns)
- Not reusable (dotfiles cannot use logic)
- Risky (user content can be overwritten)
- Difficult to understand flow
- Difficult to add features

**Cost**: Technical debt accumulates, blocks dotfiles integration

### Option B: Split into Multiple Scripts

**Description**: Break into separate top-level scripts by phase

**Structure**:

```text
scripts/
├── 01-validate-dependencies.sh
├── 02-prompt-user.sh
├── 03-create-directories.sh
├── 04-install-templates.sh
└── 05-display-summary.sh

install.sh
└── calls scripts in sequence
```

**Pros**:

- Smaller files
- Clear phases

**Cons**:

- Not reusable by dotfiles (would need to source 5 scripts)
- Shared state between scripts (globals, env vars)
- No clear API contract
- Still difficult to test
- Scripts depend on execution order

**Cost**: Doesn't solve reusability or testing

### Option C: Modular Library Architecture (Recommended)

**Description**: Extract business logic into reusable library modules, `install.sh` becomes thin orchestrator

**Structure**:

```text
lib/installer-common/
├── colors.sh (existing - terminal colors)
├── logging.sh (existing - structured logging)
├── validation.sh (existing - dependency checks)
├── config.sh (new - config reading/writing)
├── directories.sh (new - directory/symlink management)
├── templates.sh (new - template installation)
├── prompts.sh (new - user interaction)
├── deprecation.sh (new - version-based lifecycle)
└── summary.sh (new - output formatting)

install.sh (~150 lines)
└── Thin orchestrator that sources modules
```

**Pros**:

- **Maintainability**: Each module ~100-200 lines, single responsibility
- **Reusability**: Dotfiles can source specific modules as needed
- **Testability**: Unit test each module independently
- **API Stability**: Clear public API for each module
- **Safety**: Namespace isolation prevents data loss
- **Flexibility**: Modules can be used independently or together
- **Separation**: Orchestration separate from business logic

**Cons**:

- More files to manage
- Need to define stable API contract
- Requires refactoring effort
- Module dependencies must be clear

**Cost**: Upfront refactoring (53 hours), long-term maintainability gains

### Option D: Object-Oriented Approach (Classes/Namespaces)

**Description**: Use Bash 4+ features for pseudo-OOP organization

**Structure**:

```bash
# Requires Bash 4+
declare -A Installer
Installer[create_directories]() { ... }
Installer[install_templates]() { ... }
```

**Pros**:

- Modern approach
- Encapsulation

**Cons**:

- **Incompatible with macOS** (ships Bash 3.2 for licensing)
- Overly complex for shell scripting
- No real benefit over sourced functions
- Blocks macOS support

**Cost**: Platform incompatibility is showstopper

## Decision Outcome

**Chosen option**: Option C - Modular Library Architecture

**Rationale**:

1. **Decomposition**: 625 lines → 6 focused modules + thin orchestrator
   - Each module: 100-200 lines, single responsibility
   - `install.sh` orchestrator: ~150 lines, no business logic

2. **Reusability**: Dotfiles integration enabled
   - Dotfiles sources `lib/installer-common/templates.sh` for consistency
   - Dotfiles sources `lib/installer-common/config.sh` for config management
   - Conditional sourcing with version checking
   - Graceful fallback if AIDA not installed

3. **Namespace Isolation**: User content protected
   - Framework templates: `~/.claude/commands/.aida/` (replaceable)
   - User content: `~/.claude/commands/` (preserved)
   - Deprecated templates: `~/.claude/commands/.aida-deprecated/` (optional)

4. **Module Organization**:

   **Core Infrastructure** (existing):
   - `colors.sh` - Terminal colors and formatting
   - `logging.sh` - Structured logging (info, warning, error)
   - `validation.sh` - Dependency checks and platform detection

   **New Modules**:
   - `config.sh` - Config file reading/writing (JSON)
   - `directories.sh` - Directory creation, symlink management
   - `templates.sh` - Template installation orchestration
   - `prompts.sh` - User interaction and input validation
   - `deprecation.sh` - Version comparison, frontmatter parsing
   - `summary.sh` - Installation summary and next steps

5. **API Contract**:
   - Functions accept parameters (not just globals)
   - Clear return codes (0 = success, 1 = failure)
   - No assumptions about `$PWD` or repo location
   - Semantic versioning for breaking changes

6. **Installation Flow**:

```bash
#!/usr/bin/env bash
# install.sh (~150 lines)

# Source modules
source lib/installer-common/colors.sh
source lib/installer-common/logging.sh
source lib/installer-common/validation.sh
source lib/installer-common/config.sh
source lib/installer-common/directories.sh
source lib/installer-common/templates.sh
source lib/installer-common/prompts.sh
source lib/installer-common/deprecation.sh
source lib/installer-common/summary.sh

main() {
  # Pre-flight checks
  validate_dependencies
  detect_platform

  # User interaction
  ASSISTANT_NAME=$(prompt_assistant_name)
  PERSONALITY=$(prompt_personality)

  # Directory setup
  create_aida_dir "${SCRIPT_DIR}" "${AIDA_DIR}"
  create_claude_dirs "${CLAUDE_DIR}"
  create_namespace_dirs "${CLAUDE_DIR}" ".aida"

  # Template installation
  install_templates "${SCRIPT_DIR}/templates/commands" \
                    "${CLAUDE_DIR}/commands/.aida"

  # Summary
  display_summary "${AIDA_DIR}" "${CLAUDE_DIR}"
}
```

### Consequences

**Positive**:

- **85% reduction in install.sh complexity**: 625 lines → ~150 lines orchestrator
- **Testable**: Each module unit testable independently
- **Reusable**: Dotfiles repo sources libraries for consistency
- **Maintainable**: Small, focused modules with single responsibility
- **Safe**: Namespace isolation prevents user data loss
- **Flexible**: Modules can be used independently or together
- **Clear API**: Stable contract for dotfiles integration
- **Better error handling**: Each module handles its own errors
- **Easier debugging**: Smaller scope, clearer logs

**Negative**:

- **More files**: 1 file → 9 library modules + orchestrator
  - **Mitigation**: Clear organization, consistent naming, good documentation
- **Module dependencies**: Must source modules in correct order
  - **Mitigation**: Documented dependency tree, validation on load
- **API stability required**: Breaking changes affect dotfiles repo
  - **Mitigation**: Semantic versioning, backward compatibility
- **Refactoring effort**: 53 hours to extract and test modules
  - **Mitigation**: Phased approach, preserve existing functionality

**Neutral**:

- Modules use Bash functions (standard approach)
- Each module has clear public API
- Modules are stateless where possible
- All modules support Bash 3.2+ (macOS compatible)

## Validation

- [x] Decomposition reduces complexity (625 → 150 lines orchestrator)
- [x] Enables dotfiles integration via library sourcing
- [x] Namespace isolation prevents user data loss
- [x] Each module has single responsibility
- [x] Testable in isolation (unit tests possible)
- [x] Bash 3.2+ compatible (macOS support)
- [x] Clear API contract for external consumers
- [x] Reviewed by system architect and tech lead

## Implementation Notes

### Module Dependency Tree

```text
install.sh
├── colors.sh (no dependencies)
├── logging.sh (depends: colors.sh)
├── validation.sh (depends: logging.sh)
├── config.sh (depends: logging.sh, validation.sh)
├── directories.sh (depends: logging.sh, validation.sh)
├── templates.sh (depends: logging.sh, directories.sh)
├── prompts.sh (depends: logging.sh)
├── deprecation.sh (depends: logging.sh, validation.sh)
└── summary.sh (depends: logging.sh)
```

### Namespace Isolation

**Framework Content** (replaceable during updates):

```text
~/.claude/commands/.aida/
~/.claude/agents/.aida/
~/.claude/skills/.aida/
```

**User Content** (preserved during updates):

```text
~/.claude/commands/my-custom-command.md
~/.claude/agents/my-custom-agent.md
~/.claude/config/
~/.claude/memory/
```

**Deprecated Content** (optional, separate namespace):

```text
~/.claude/commands/.aida-deprecated/
~/.claude/agents/.aida-deprecated/
```

### Dotfiles Integration Pattern

```bash
#!/usr/bin/env bash
# ~/dotfiles/install.sh

# Check if AIDA installed
if [[ -d "${HOME}/.aida" ]]; then
  INSTALLER_COMMON="${HOME}/.aida/lib/installer-common"

  # Version check
  source "${INSTALLER_COMMON}/validation.sh"
  if check_version_compatibility "$(cat ~/.aida/VERSION)" "0.2.0"; then
    # Source needed modules
    source "${INSTALLER_COMMON}/templates.sh"
    source "${INSTALLER_COMMON}/config.sh"
    AIDA_AVAILABLE=true
  fi
fi

# Install dotfiles templates
if [[ "$AIDA_AVAILABLE" == true ]]; then
  install_templates "${PWD}/templates" "${HOME}/.claude/commands/.dotfiles"
else
  # Fallback: manual installation
  cp -r "${PWD}/templates" "${HOME}/.claude/commands/.dotfiles"
fi
```

### Testing Strategy

**Unit Tests** (per module):

```bash
# test/unit/test-templates.sh
test_install_templates_copies_files() {
  install_templates "/tmp/src" "/tmp/dst" false
  assert_file_exists "/tmp/dst/command/README.md"
}
```

**Integration Tests** (full flow):

```bash
# test/integration/test-install.sh
test_fresh_installation() {
  ./install.sh --non-interactive
  assert_directory_exists ~/.claude/commands/.aida
  assert_file_exists ~/.claude/commands/.aida/start-work/README.md
}
```

**Upgrade Tests** (preserve user content):

```bash
# test/integration/test-upgrade.sh
test_upgrade_preserves_user_content() {
  # Setup: Pre-seed user content
  echo "custom" > ~/.claude/commands/my-command.md

  # Run installer
  ./install.sh --non-interactive

  # Validate: User content preserved
  assert_file_contains ~/.claude/commands/my-command.md "custom"
}
```

### Migration Plan

**Phase 1: Foundation** (Week 1, 20h)

- Extract `prompts.sh` (lowest risk)
- Extract `directories.sh`
- Extract `summary.sh`
- Refactor `install.sh` to orchestrator
- Basic unit tests

**Phase 2: Advanced Features** (Week 2, 20h)

- Extract `templates.sh` with namespace isolation
- Extract `deprecation.sh` with frontmatter parsing
- Integration tests
- Upgrade tests

**Phase 3: CI/CD** (Week 3, 15h)

- Comprehensive test fixtures
- GitHub Actions updates
- Cross-platform validation
- Documentation

## Examples

### Example 1: Before (Monolithic)

```bash
#!/usr/bin/env bash
# install.sh - 625 lines

# Dependency validation
check_dependencies() { ... }

# User prompts
prompt_assistant_name() { ... }

# Directory creation
create_directories() { ... }

# Variable substitution
substitute_variables() { ... }

# Template installation
install_templates() { ... }

# Deprecation handling
handle_deprecated() { ... }

# Summary
display_summary() { ... }

# Main flow (all logic inline)
main() {
  check_dependencies
  ASSISTANT=$(prompt_assistant_name)
  create_directories
  substitute_variables
  install_templates
  handle_deprecated
  display_summary
}
```

### Example 2: After (Modular)

```bash
#!/usr/bin/env bash
# install.sh - ~150 lines (orchestrator only)

# Source modules (business logic in libraries)
source lib/installer-common/validation.sh
source lib/installer-common/prompts.sh
source lib/installer-common/directories.sh
source lib/installer-common/templates.sh
source lib/installer-common/deprecation.sh
source lib/installer-common/summary.sh

# Main flow (delegates to modules)
main() {
  validate_dependencies
  ASSISTANT=$(prompt_assistant_name)
  create_claude_dirs "${CLAUDE_DIR}"
  install_templates "${SRC}" "${DST}"
  display_summary "${AIDA_DIR}" "${CLAUDE_DIR}"
}
```

### Example 3: Dotfiles Integration

```bash
#!/usr/bin/env bash
# ~/dotfiles/install.sh

# Reuse AIDA libraries (no duplication!)
if [[ -d ~/.aida ]]; then
  source ~/.aida/lib/installer-common/templates.sh
  install_templates ./templates ~/.claude/commands/.dotfiles
else
  # Fallback if AIDA not installed
  cp -r ./templates ~/.claude/commands/.dotfiles
fi
```

## References

- **Issue #53**: Modular Installer with Deprecation Support
- **ADR-010**: Command Structure Refactoring (namespace isolation needed)
- **PRD**: Modular Installer Refactoring (stakeholder requirements)
- **Technical Spec**: Detailed module specifications
- **Bash Best Practices**: Modular shell script design
- **Dotfiles Integration**: docs/architecture/dotfiles-integration.md

## Related ADRs

- **ADR-012**: Universal Config Aggregator Pattern (unified config system)
- **ADR-013**: Namespace Isolation for User Content Protection (safety system)
- **ADR-010**: Command Structure Refactoring (depends on namespace isolation)

## Updates

None yet
