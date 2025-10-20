---
title: "Integration Specialist Analysis - Issue #53"
description: "Modular installer with deprecation support and .aida namespace - Integration analysis"
issue: 53
category: "analysis"
tags: ["integration", "installer", "dotfiles", "claude-code", "ci-cd"]
analyst: "integration-specialist"
date: "2025-10-18"
status: "draft"
---

# Integration Specialist Analysis - Issue #53

**Issue**: Modular installer with deprecation support and .aida namespace installation

**Analysis Focus**: External integrations, contracts, discovery mechanisms, and CI/CD patterns

---

## 1. Dotfiles Integration

### How dotfiles repo should source AIDA libraries

**Current State**:

- AIDA installs to `~/.aida/`
- Shared utilities in `~/.aida/lib/installer-common/`
- Dotfiles is standalone but can optionally integrate with AIDA

**Recommended Pattern**:

```bash
# In dotfiles/install.sh - Source AIDA libraries conditionally

# Check if AIDA framework is installed
if [[ -d "${HOME}/.aida" ]]; then
    # Source shared installer-common library
    readonly AIDA_INSTALLER_LIB="${HOME}/.aida/lib/installer-common"

    # Check library version compatibility before sourcing
    if [[ -f "${AIDA_INSTALLER_LIB}/version.sh" ]]; then
        # shellcheck source=/dev/null
        source "${AIDA_INSTALLER_LIB}/version.sh"

        # Validate minimum version required
        if check_library_version "0.2.0"; then
            # Source required modules
            source "${AIDA_INSTALLER_LIB}/colors.sh"
            source "${AIDA_INSTALLER_LIB}/logging.sh"
            source "${AIDA_INSTALLER_LIB}/validation.sh"

            AIDA_INTEGRATION=true
        else
            echo "Warning: AIDA installer-common version incompatible. Using fallback."
            AIDA_INTEGRATION=false
        fi
    fi
else
    # AIDA not installed - use standalone dotfiles utilities
    AIDA_INTEGRATION=false
    source "$(dirname "$0")/lib/colors.sh"  # Dotfiles-local copy
    source "$(dirname "$0")/lib/logging.sh"  # Dotfiles-local copy
fi
```

**Key Integration Points**:

- **Conditional sourcing**: Only load AIDA libraries if framework exists
- **Version checking**: Validate compatibility before sourcing modules
- **Graceful degradation**: Fallback to dotfiles-local utilities if AIDA unavailable
- **Shared namespace**: Both repos use same function signatures for portability

### Contract between repos

**Library API Contract** (`~/.aida/lib/installer-common/`):

**Stability Guarantees**:

- **Function signatures**: MUST NOT change within major version
- **Return codes**: MUST maintain semantic meaning (0 = success, 1 = error)
- **Global variables**: MUST be documented and readonly
- **Side effects**: MUST be documented (file writes, logging)

**Required Modules** (v0.2.0+):

```bash
# colors.sh - Color code constants
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# logging.sh - Logging functions
print_message() {
    # Args: $1=level (info|success|warning|error), $2=message
    # Returns: 0 always
    # Side effects: Writes to stdout/stderr, may write to log file
}

log_to_file() {
    # Args: $1=level, $2=message
    # Returns: 0 on success, 1 on failure
    # Side effects: Appends to ${LOG_FILE} if set
}

# validation.sh - Input validation
validate_version() {
    # Args: $1=version string (MAJOR.MINOR.PATCH)
    # Returns: 0 if valid, 1 if invalid
}

check_version_compatibility() {
    # Args: $1=installed_version, $2=required_version
    # Returns: 0 if compatible, 1 if incompatible
    # Output: Error messages to stderr
}

validate_path() {
    # Args: $1=path, $2=expected_prefix (default: $HOME)
    # Returns: 0 if valid, 1 if invalid
    # Output: Canonical path to stdout if valid
}

validate_dependencies() {
    # Args: None
    # Returns: 0 on success, error count on failure
    # Side effects: Prints validation messages
}
```

**Version File Contract** (`~/.aida/lib/installer-common/VERSION`):

```text
# Format: MAJOR.MINOR.PATCH
0.2.0
```

**Semantic Versioning**:

- **Major**: Breaking API changes (dotfiles MUST update)
- **Minor**: New features, backward compatible (dotfiles MAY use)
- **Patch**: Bug fixes, fully compatible (transparent)

### Installation order dependencies

**Scenario 1: AIDA first, dotfiles second (RECOMMENDED)**:

```bash
# User installs AIDA framework
cd ~/.aida && ./install.sh
# Creates: ~/.aida/, ~/.claude/, ~/CLAUDE.md

# User later installs dotfiles
git clone https://github.com/user/dotfiles ~/dotfiles
cd ~/dotfiles && ./install.sh
# Detects ~/.aida/, sources installer-common libraries
# Stows aida/ package with integration configs
```

**Dependencies**: None - dotfiles installer detects AIDA at runtime

**Scenario 2: Dotfiles first, AIDA second**:

```bash
# User installs dotfiles
cd ~/dotfiles && ./install.sh
# Creates shell/git/vim configs (standalone)
# Skips AIDA package (not detected)

# User later installs AIDA
git clone https://github.com/user/aida ~/.aida
cd ~/.aida && ./install.sh
# Creates: ~/.aida/, ~/.claude/, ~/CLAUDE.md

# User re-runs dotfiles to integrate
cd ~/dotfiles && stow aida
```

**Dependencies**: Requires manual `stow aida` after AIDA install

**Scenario 3: Dotfiles prompts for AIDA install (FUTURE)**:

```bash
# User installs dotfiles
cd ~/dotfiles && ./install.sh
# Prompts: "Install AIDA framework? [Y/n]"
# If yes: clones claude-personal-assistant, runs install.sh
# Then: automatically stows aida/ package
```

**Dependencies**: Coordinated install scripts (v0.3 feature)

**Critical Integration Rule**:

- **Neither repo should REQUIRE the other**
- **Both should ENHANCE when together**
- **Installation order should NOT matter** (with proper detection)

---

## 2. Claude Code Integration

### .aida namespace discovery - recursive behavior

**Current Behavior** (Claude Code discovery):

Claude Code looks for configuration in:

1. `~/CLAUDE.md` - Entry point
2. `~/.claude/` - User configuration directory
3. Slash commands: `~/.claude/commands/*.md`
4. Agents: `~/.claude/agents/*/` directories

**Question**: Does Claude Code recursively discover in `~/.aida/`?

**Answer**: **NO** - Claude Code does NOT automatically discover `~/.aida/`

**Integration Pattern Required**:

```markdown
# ~/CLAUDE.md - Entry point generated by AIDA installer

---
title: "CLAUDE.md - Assistant Configuration"
description: "Personal AIDA assistant configuration"
---

# Your AIDA Assistant

## Configuration Locations

- **Framework**: `~/.aida/` (templates, personalities, shared libraries)
- **User Config**: `~/.claude/` (your commands, agents, knowledge)
- **Memory**: `~/.claude/memory/` (persistent state)

## Available Commands

Commands are loaded from:
- `~/.claude/commands/` (installed from `~/.aida/templates/commands/`)

See available commands: Run `/help` or list `~/.claude/commands/`

## Available Agents

Agents are loaded from:
- `~/.claude/agents/` (installed from `~/.aida/templates/agents/`)

Invoke agents: Use agent name in conversation (e.g., "secretary", "file-manager")
```

**Discovery Mechanism**:

- **Templates in `~/.aida/`**: NOT discovered by Claude Code
- **Installed to `~/.claude/`**: Discovered by Claude Code
- **Variable substitution**: Connects `~/.claude/` → `~/.aida/` via absolute paths

**Example: Command template references framework**:

```markdown
# ~/.claude/commands/workflow-init.md
# (Generated from ~/.aida/templates/commands/workflow-init.md)

## Workflow Initialization

Load shared workflow libraries from: `/Users/rob/.aida/lib/workflows/`

```bash
# Source shared workflow utilities
source "/Users/rob/.aida/lib/workflows/common.sh"
```

**Absolute paths enable `~/.claude/` to reference `~/.aida/` resources**

### Variable substitution impact on Claude Code

**Install-time variables** (`{{VAR}}`):

- Substituted during `install.sh`
- Claude Code sees resolved absolute paths
- **Impact**: Commands can reference framework files reliably

**Runtime variables** (`${VAR}`):

- Preserved in installed commands
- Resolved by bash when command executes
- **Impact**: Commands can adapt to project context

**Example template**:

```markdown
# ~/.aida/templates/commands/example.md (TEMPLATE)

Load knowledge from {{AIDA_HOME}}/templates/knowledge/

Current project: ${PROJECT_ROOT}
```

**After installation**:

```markdown
# ~/.claude/commands/example.md (INSTALLED)

Load knowledge from /Users/rob/.aida/templates/knowledge/

Current project: ${PROJECT_ROOT}
```

**Claude Code behavior**:

- Sees: `/Users/rob/.aida/templates/knowledge/` (absolute path)
- Can read: Files in AIDA framework directly
- Runtime: Bash resolves `${PROJECT_ROOT}` when executed

**Critical Impact**:

- **Templates MUST use `{{VAR}}` for AIDA paths** (install-time)
- **Templates MUST use `${VAR}` for project paths** (runtime)
- **Claude Code needs absolute paths to cross-reference files**

### Template frontmatter requirements

**Current Pattern** (from existing templates):

```yaml
---
title: "Command Title"
description: "Brief description"
category: "workflow|utility|automation"
tags: ["tag1", "tag2"]
last_updated: "2025-10-18"
status: "published"
---
```

**Required for Claude Code**:

- **Frontmatter is OPTIONAL** for command discovery
- **Title/description help Claude understand purpose**
- **Does NOT affect command loading** (filename is key)

**Recommended Frontmatter** (for maintainability):

```yaml
---
title: "Workflow Init"
description: "Initialize project workflow configuration"
category: "workflow"
requires: ["git"]
version: "0.2.0"
---
```

**Additional Fields** (for integration):

- `requires: []` - Dependencies (commands, tools)
- `version: "X.Y.Z"` - Template version (for deprecation)
- `deprecated: true` - Mark for cleanup
- `replacement: "new-command"` - Migration path

**Validation Pattern**:

```bash
# In install.sh - validate frontmatter before copying
validate_template_frontmatter() {
    local template="$1"

    # Check for required fields
    if ! grep -q "^title:" "$template"; then
        print_message "warning" "Template missing title: $(basename "$template")"
    fi

    # Check for deprecation marker
    if grep -q "^deprecated: true" "$template"; then
        print_message "info" "Skipping deprecated template: $(basename "$template")"
        return 1  # Skip installation
    fi

    return 0
}
```

---

## 3. CI/CD Integration

### GitHub Actions workflow design

**Current State**: `.github/workflows/test-installation.yml` tests across platforms

**Proposed Modular Structure** (post-refactor):

```yaml
name: Installation Tests

on:
  push:
    paths:
      - 'install.sh'
      - 'lib/installer-common/**'
      - 'scripts/deprecation-cleanup.sh'
      - '.github/workflows/test-installation.yml'

jobs:
  # 1. Lint all installer components
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Shellcheck all scripts
        run: |
          shellcheck install.sh
          shellcheck lib/installer-common/*.sh
          shellcheck scripts/deprecation-cleanup.sh
      - name: Validate VERSION file
        run: |
          ./lib/installer-common/validation.sh validate_version_file VERSION

  # 2. Test installer-common library isolation
  test-library:
    runs-on: ubuntu-latest
    needs: lint
    steps:
      - uses: actions/checkout@v4
      - name: Test library modules can be sourced
        run: |
          source lib/installer-common/colors.sh
          source lib/installer-common/logging.sh
          source lib/installer-common/validation.sh
          validate_version "0.2.0" && echo "PASS"
      - name: Test version compatibility
        run: |
          source lib/installer-common/validation.sh
          check_version_compatibility "0.2.1" "0.2.0" && echo "PASS"

  # 3. Test installation (existing matrix)
  test-install:
    strategy:
      matrix:
        platform: [ubuntu-22, ubuntu-20, debian-12, macos-latest]
    runs-on: ${{ matrix.platform }}
    needs: test-library
    # ... existing test steps

  # 4. Test upgrade path (NEW)
  test-upgrade:
    runs-on: ubuntu-latest
    needs: lint
    steps:
      - name: Checkout v0.1.6
        uses: actions/checkout@v4
        with:
          ref: v0.1.6
      - name: Install v0.1.6
        run: echo -e "test\n1\n" | ./install.sh
      - name: Checkout current version
        uses: actions/checkout@v4
      - name: Upgrade to current
        run: ./install.sh --upgrade
      - name: Verify deprecation cleanup
        run: |
          # Old structure should be migrated
          test ! -d ~/.claude/old_structure && echo "PASS: old structure removed"

  # 5. Test deprecation cleanup (NEW)
  test-deprecation:
    runs-on: ubuntu-latest
    needs: lint
    steps:
      - uses: actions/checkout@v4
      - name: Create fixture with v0.1 structure
        run: |
          mkdir -p ~/.claude/old_dir
          echo "old" > ~/.claude/old_file
      - name: Run deprecation cleanup
        run: |
          ./scripts/deprecation-cleanup.sh --dry-run
      - name: Apply cleanup
        run: |
          ./scripts/deprecation-cleanup.sh --apply
      - name: Verify removal
        run: |
          test ! -d ~/.claude/old_dir && echo "PASS"
```

### Matrix testing strategy (platforms × modes)

**Testing Dimensions**:

1. **Platforms**: Ubuntu 22/20, Debian 12, macOS, WSL
2. **Installation Modes**: Normal, Dev, Upgrade
3. **Scenarios**: Fresh install, Upgrade from v0.1.x, Deprecation cleanup

**Matrix Expansion**:

```yaml
strategy:
  matrix:
    platform: [ubuntu-22, debian-12, macos-latest]
    mode: [normal, dev]
    scenario: [fresh, upgrade]
    exclude:
      # Dev mode not applicable to upgrade scenarios
      - mode: dev
        scenario: upgrade
```

**Test Coverage**:

- **Fresh install + Normal**: Standard user flow
- **Fresh install + Dev**: Developer workflow
- **Upgrade + Normal**: Version migration testing
- **Platform × All**: Cross-platform compatibility

### Test result reporting

**Artifact Collection**:

```yaml
- name: Upload test logs
  if: always()
  uses: actions/upload-artifact@v4
  with:
    name: test-logs-${{ matrix.platform }}-${{ matrix.mode }}
    path: |
      .github/testing/logs/
      ~/.aida/install.log
      ~/.claude/migration.log
    retention-days: 7
```

**Summary Job**:

```yaml
test-summary:
  runs-on: ubuntu-latest
  needs: [lint, test-library, test-install, test-upgrade, test-deprecation]
  if: always()
  steps:
    - name: Check all results
      run: |
        echo "## Test Results" >> $GITHUB_STEP_SUMMARY
        echo "- Lint: ${{ needs.lint.result }}" >> $GITHUB_STEP_SUMMARY
        echo "- Library: ${{ needs.test-library.result }}" >> $GITHUB_STEP_SUMMARY
        echo "- Install: ${{ needs.test-install.result }}" >> $GITHUB_STEP_SUMMARY
        echo "- Upgrade: ${{ needs.test-upgrade.result }}" >> $GITHUB_STEP_SUMMARY
        echo "- Deprecation: ${{ needs.test-deprecation.result }}" >> $GITHUB_STEP_SUMMARY
```

---

## 4. Docker Testing Integration

### Makefile targets for different scenarios

**Proposed Makefile** (`.github/testing/Makefile`):

```makefile
# AIDA Framework Testing Makefile

.PHONY: help test test-all test-platform test-scenario clean

# Configuration
DOCKER_COMPOSE := $(shell command -v docker-compose 2>/dev/null || echo "docker compose")
PLATFORMS := ubuntu-22 ubuntu-20 debian-12 ubuntu-minimal
SCENARIOS := fresh upgrade deprecation

help:
    @echo "AIDA Framework Testing"
    @echo ""
    @echo "Targets:"
    @echo "  test-all           - Run all tests on all platforms"
    @echo "  test-platform      - Test specific platform (PLATFORM=ubuntu-22)"
    @echo "  test-scenario      - Test specific scenario (SCENARIO=upgrade)"
    @echo "  test-fresh         - Test fresh installation"
    @echo "  test-upgrade       - Test upgrade from v0.1.x"
    @echo "  test-deprecation   - Test deprecation cleanup"
    @echo "  clean              - Remove test artifacts and logs"
    @echo ""
    @echo "Examples:"
    @echo "  make test-platform PLATFORM=ubuntu-22"
    @echo "  make test-scenario SCENARIO=upgrade"

test-all:
    @echo "Running all tests..."
    ./test-install.sh

test-platform:
    @echo "Testing platform: $(PLATFORM)"
    ./test-install.sh --env $(PLATFORM) --verbose

test-scenario:
    @echo "Testing scenario: $(SCENARIO)"
    ./test-install.sh --scenario $(SCENARIO) --verbose

test-fresh:
    @echo "Testing fresh installation..."
    @for platform in $(PLATFORMS); do \
        echo "Platform: $$platform"; \
        $(DOCKER_COMPOSE) -f ../docker/docker-compose.yml run --rm $$platform \
            bash -c "echo -e 'test\n1\n' | ./install.sh"; \
    done

test-upgrade:
    @echo "Testing upgrade path..."
    @for platform in $(PLATFORMS); do \
        echo "Platform: $$platform"; \
        $(DOCKER_COMPOSE) -f ../docker/docker-compose.yml run --rm $$platform \
            bash -c "./test-upgrade.sh"; \
    done

test-deprecation:
    @echo "Testing deprecation cleanup..."
    ./test-deprecation.sh --all-platforms

clean:
    @echo "Cleaning test artifacts..."
    rm -rf logs/*.log
    $(DOCKER_COMPOSE) -f ../docker/docker-compose.yml down -v
    docker system prune -f
```

### Fixture management for upgrade tests

**Test Fixtures** (`.github/testing/fixtures/`):

```bash
fixtures/
├── v0.1.6/
│   ├── .aida/          # Old AIDA structure
│   ├── .claude/        # Old Claude config
│   └── CLAUDE.md       # Old entry point
├── v0.2.0/
│   ├── .aida/          # New AIDA structure
│   ├── .claude/        # New Claude config
│   └── CLAUDE.md       # New entry point
└── deprecated/
    ├── old-commands/   # Commands to be removed
    └── old-agents/     # Agents to be removed
```

**Fixture Setup Script**:

```bash
#!/usr/bin/env bash
# .github/testing/setup-fixture.sh

setup_v016_fixture() {
    local home_dir="$1"

    # Install v0.1.6 structure
    mkdir -p "${home_dir}/.aida"
    mkdir -p "${home_dir}/.claude/commands"

    # Copy v0.1.6 fixture files
    cp -r fixtures/v0.1.6/.aida/* "${home_dir}/.aida/"
    cp -r fixtures/v0.1.6/.claude/* "${home_dir}/.claude/"
    cp fixtures/v0.1.6/CLAUDE.md "${home_dir}/"

    # Add version marker
    echo "0.1.6" > "${home_dir}/.aida/VERSION"
}

setup_deprecated_fixture() {
    local home_dir="$1"

    # Create deprecated structure
    mkdir -p "${home_dir}/.claude/old_commands"
    cp fixtures/deprecated/old-commands/* "${home_dir}/.claude/old_commands/"
}
```

### Cross-platform Docker images

**Dockerfile Strategy**:

```dockerfile
# .github/docker/Dockerfile.ubuntu-22
FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    bash \
    git \
    rsync \
    coreutils \
    && rm -rf /var/lib/apt/lists/*

# Create test user
RUN useradd -m -s /bin/bash testuser

# Set up test environment
USER testuser
WORKDIR /home/testuser

# Copy AIDA framework
COPY --chown=testuser:testuser . /home/testuser/.aida/

# Entry point for tests
CMD ["/bin/bash"]
```

**docker-compose.yml**:

```yaml
services:
  ubuntu-22:
    build:
      context: ../..
      dockerfile: .github/docker/Dockerfile.ubuntu-22
    volumes:
      - ../../:/workspace:ro
    working_dir: /workspace

  ubuntu-20:
    build:
      context: ../..
      dockerfile: .github/docker/Dockerfile.ubuntu-20
    volumes:
      - ../../:/workspace:ro

  debian-12:
    build:
      context: ../..
      dockerfile: .github/docker/Dockerfile.debian-12
    volumes:
      - ../../:/workspace:ro

  ubuntu-minimal:
    build:
      context: ../..
      dockerfile: .github/docker/Dockerfile.ubuntu-minimal
    volumes:
      - ../../:/workspace:ro
```

---

## 5. Version Management

### VERSION file as source of truth

**Location**: `/Users/rob/Develop/oakensoul/claude-personal-assistant/VERSION`

**Current Content**: `0.1.6`

**Integration Points**:

1. **install.sh**: Reads VERSION for banner and logging
2. **deprecation-cleanup.sh**: Checks VERSION to determine cleanup rules
3. **CI/CD**: Uses VERSION for tagging and release
4. **installer-common library**: Has its own VERSION for library compatibility

**Recommended Structure**:

```text
# Repository root
VERSION                         # Framework version (0.2.0)

# Library versioning
lib/installer-common/VERSION    # Library version (0.2.0)

# Deprecation mapping
scripts/deprecation-map.yml     # Version → cleanup rules
```

**deprecation-map.yml**:

```yaml
---
# Deprecation mapping: version → items to remove
deprecations:
  "0.2.0":
    removed:
      - path: "~/.claude/commands/old-command.md"
        reason: "Replaced by new-command.md"
        replacement: "~/.claude/commands/new-command.md"
      - path: "~/.claude/agents/old-agent/"
        reason: "Agent framework refactored"
        replacement: "~/.claude/agents/new-agent/"
    migrated:
      - from: "~/.aida/templates/old-location/"
        to: "~/.aida/templates/new-location/"
        strategy: "move"  # move|copy|merge
  "0.1.0":
    removed:
      - path: "~/.claude/old-structure/"
        reason: "Pre-modular architecture"
```

### How to trigger cleanup script

**Automatic Trigger** (recommended):

```bash
# In install.sh - after successful installation
run_deprecation_cleanup() {
    local cleanup_script="${AIDA_DIR}/scripts/deprecation-cleanup.sh"

    if [[ -x "$cleanup_script" ]]; then
        print_message "info" "Running deprecation cleanup for v${VERSION}..."

        if "$cleanup_script" --version "$VERSION" --auto; then
            print_message "success" "Deprecation cleanup completed"
        else
            print_message "warning" "Deprecation cleanup had warnings (see log)"
        fi
    fi
}

# Call during installation
main() {
    # ... existing installation steps

    # Run cleanup for upgrades
    if [[ -f "${AIDA_DIR}/.installed_version" ]]; then
        local old_version
        old_version=$(cat "${AIDA_DIR}/.installed_version")

        if [[ "$old_version" != "$VERSION" ]]; then
            print_message "info" "Upgrading from v${old_version} to v${VERSION}"
            run_deprecation_cleanup
        fi
    fi

    # Record installed version
    echo "$VERSION" > "${AIDA_DIR}/.installed_version"
}
```

**Manual Trigger**:

```bash
# User-initiated cleanup
~/.aida/scripts/deprecation-cleanup.sh --version 0.2.0 --dry-run
~/.aida/scripts/deprecation-cleanup.sh --version 0.2.0 --apply
```

**CI/CD Trigger**:

```yaml
# In .github/workflows/test-installation.yml
- name: Test deprecation cleanup
  run: |
    ./scripts/deprecation-cleanup.sh --version 0.2.0 --dry-run
```

### Semantic versioning validation

**Validation Function** (in `lib/installer-common/validation.sh`):

```bash
# Already exists - validates MAJOR.MINOR.PATCH format
validate_version() {
    local version="$1"
    if [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        return 0
    else
        return 1
    fi
}
```

**Enhanced Version Comparison**:

```bash
# Compare two semantic versions
# Returns: 0 if v1 < v2, 1 if v1 == v2, 2 if v1 > v2
compare_versions() {
    local v1="$1"
    local v2="$2"

    IFS='.' read -r v1_major v1_minor v1_patch <<< "$v1"
    IFS='.' read -r v2_major v2_minor v2_patch <<< "$v2"

    if [[ $v1_major -lt $v2_major ]]; then return 0; fi
    if [[ $v1_major -gt $v2_major ]]; then return 2; fi

    if [[ $v1_minor -lt $v2_minor ]]; then return 0; fi
    if [[ $v1_minor -gt $v2_minor ]]; then return 2; fi

    if [[ $v1_patch -lt $v2_patch ]]; then return 0; fi
    if [[ $v1_patch -gt $v2_patch ]]; then return 2; fi

    return 1  # Equal
}
```

**Pre-commit Hook Validation**:

```yaml
# .pre-commit-config.yaml
- repo: local
  hooks:
    - id: validate-version
      name: Validate VERSION file
      entry: bash -c 'source lib/installer-common/validation.sh && validate_version_file VERSION'
      language: system
      files: ^VERSION$
```

---

## 6. Questions & Recommendations

### Integration Risks

**High Risk**:

1. **Breaking library API changes**
   - **Risk**: Dotfiles repo breaks when AIDA installer-common changes
   - **Mitigation**: Strict semantic versioning + compatibility checking
   - **Detection**: CI tests dotfiles integration on every AIDA change

2. **Variable substitution failures**
   - **Risk**: Templates with unsubstituted `{{VAR}}` break Claude Code
   - **Mitigation**: Validation in `install.sh` before installing templates
   - **Detection**: Pre-commit hook checks for unsubstituted install-time vars

3. **Cross-platform path issues**
   - **Risk**: Hardcoded `/Users/rob/` paths fail on Linux/Windows
   - **Mitigation**: Always use `{{HOME}}` and `${HOME}` appropriately
   - **Detection**: Docker tests on Ubuntu/Debian catch hardcoded paths

**Medium Risk**:

4. **VERSION file desync**
   - **Risk**: Framework VERSION ≠ Library VERSION causes confusion
   - **Mitigation**: Single VERSION file, library imports it
   - **Detection**: CI validates VERSION consistency

5. **Upgrade path failures**
   - **Risk**: Users upgrading from v0.1.x lose configurations
   - **Mitigation**: Backup before upgrade + deprecation cleanup script
   - **Detection**: Fixture-based upgrade tests in CI

**Low Risk**:

6. **Claude Code discovery limitations**
   - **Risk**: Users expect `~/.aida/` to be auto-discovered
   - **Mitigation**: Clear documentation + variable substitution links
   - **Detection**: Documentation review

### Recommended Integration Patterns

#### Pattern 1: Library Versioning with Compatibility Checks

```bash
# lib/installer-common/version.sh
readonly INSTALLER_COMMON_VERSION="0.2.0"

check_library_version() {
    local required_version="$1"
    check_version_compatibility "$INSTALLER_COMMON_VERSION" "$required_version"
}
```

#### Pattern 2: Graceful Degradation in Dotfiles

```bash
# dotfiles/install.sh
if [[ -d ~/.aida ]] && source ~/.aida/lib/installer-common/colors.sh 2>/dev/null; then
    print_message "info" "Using AIDA installer-common library"
else
    # Fallback to dotfiles-local utilities
    print_msg() { echo "$2"; }  # Simplified fallback
fi
```

#### Pattern 3: Template Validation Pipeline

```bash
# install.sh - before copying templates
validate_all_templates() {
    local template_dir="$1"
    local errors=0

    for template in "$template_dir"/*.md; do
        # Check for unsubstituted install-time variables
        if grep -qE '\{\{(AIDA_HOME|CLAUDE_CONFIG_DIR|HOME)\}\}' "$template"; then
            print_message "error" "Template has unsubstituted variables: $(basename "$template")"
            errors=$((errors + 1))
        fi

        # Check for deprecated marker
        if grep -q "^deprecated: true" "$template"; then
            print_message "info" "Skipping deprecated template: $(basename "$template")"
            continue
        fi
    done

    return $errors
}
```

#### Pattern 4: Deprecation-Safe Installation

```bash
# install.sh - installation with version tracking
install_with_version_tracking() {
    # Check for existing installation
    if [[ -f "${AIDA_DIR}/.installed_version" ]]; then
        local old_version
        old_version=$(cat "${AIDA_DIR}/.installed_version")

        print_message "info" "Detected existing installation: v${old_version}"
        print_message "info" "Upgrading to: v${VERSION}"

        # Run deprecation cleanup
        if [[ -x "${SCRIPT_DIR}/scripts/deprecation-cleanup.sh" ]]; then
            "${SCRIPT_DIR}/scripts/deprecation-cleanup.sh" \
                --from-version "$old_version" \
                --to-version "$VERSION" \
                --auto
        fi
    fi

    # Perform installation
    # ...

    # Record new version
    echo "$VERSION" > "${AIDA_DIR}/.installed_version"
}
```

### Testing Needed

**Unit Tests** (new requirement):

```bash
# tests/test-installer-common.sh
test_validate_version() {
    source lib/installer-common/validation.sh

    validate_version "0.2.0" || fail "Valid version rejected"
    ! validate_version "0.2" || fail "Invalid version accepted"
    ! validate_version "v0.2.0" || fail "Version with prefix accepted"
}

test_version_compatibility() {
    source lib/installer-common/validation.sh

    check_version_compatibility "0.2.1" "0.2.0" || fail "Compatible versions rejected"
    ! check_version_compatibility "0.1.9" "0.2.0" || fail "Incompatible versions accepted"
}
```

**Integration Tests**:

```bash
# .github/testing/test-dotfiles-integration.sh
test_dotfiles_sources_aida_library() {
    # Setup: Install AIDA
    ./install.sh <<< "test\n1\n"

    # Simulate dotfiles install script
    if source ~/.aida/lib/installer-common/colors.sh; then
        echo "PASS: Dotfiles can source AIDA library"
    else
        echo "FAIL: Dotfiles cannot source AIDA library"
        exit 1
    fi
}

test_dotfiles_graceful_without_aida() {
    # Setup: NO AIDA installed
    rm -rf ~/.aida

    # Simulate dotfiles with fallback
    if [[ -d ~/.aida ]]; then
        source ~/.aida/lib/installer-common/colors.sh
    else
        # Fallback works
        echo "PASS: Dotfiles fallback works without AIDA"
    fi
}
```

**Upgrade Tests**:

```bash
# .github/testing/test-upgrade.sh
test_upgrade_from_v016() {
    # Setup v0.1.6 fixture
    setup_v016_fixture "$HOME"

    # Run installer (should trigger deprecation cleanup)
    ./install.sh <<< "test\n1\n"

    # Verify cleanup
    if [[ ! -d ~/.claude/old_structure ]]; then
        echo "PASS: Deprecated structure removed"
    else
        echo "FAIL: Deprecated structure still exists"
        exit 1
    fi

    # Verify new structure
    if [[ -d ~/.claude/commands ]] && [[ -f ~/.aida/VERSION ]]; then
        echo "PASS: New structure installed"
    else
        echo "FAIL: New structure missing"
        exit 1
    fi
}
```

**Cross-Platform Tests**:

- **Existing**: `.github/workflows/test-installation.yml` covers Ubuntu/Debian/macOS/WSL
- **New**: Add dotfiles integration tests to matrix
- **New**: Add upgrade path tests with fixtures

---

## Summary & Next Steps

### Critical Integration Points

1. **Dotfiles ↔ AIDA**: Conditional sourcing with version compatibility checks
2. **Templates → Claude Code**: Variable substitution creates absolute path references
3. **VERSION file**: Single source of truth for deprecation cleanup
4. **CI/CD**: Expanded test matrix for platforms × scenarios

### Key Recommendations

1. **Add `lib/installer-common/version.sh`** with library version
2. **Create `scripts/deprecation-map.yml`** for version-based cleanup
3. **Enhance `install.sh`** with upgrade detection and cleanup trigger
4. **Expand CI tests** for upgrade paths and library integration
5. **Document library API contract** for dotfiles consumers

### Integration Checklist

- [ ] Library version file created
- [ ] Deprecation mapping defined
- [ ] Template validation added to install.sh
- [ ] Upgrade path testing in CI
- [ ] Dotfiles integration documented
- [ ] Cross-platform Docker fixtures created
- [ ] API contract documented for external consumers

---

**Analysis Complete**: Integration risks identified, patterns recommended, testing strategy defined.
