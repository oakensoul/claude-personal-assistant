---
title: "Contributing to AIDA Framework"
description: "Guidelines for contributing to the Claude Personal Assistant (AIDA) project"
category: "development"
tags: ["contributing", "guidelines", "development", "standards"]
last_updated: "2025-10-18"
status: "published"
audience: "developers"
---

# Contributing to AIDA Framework

Thank you for your interest in contributing to the AIDA (Agentic Intelligence Digital Assistant) Framework!

## Table of Contents

- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Multi-Repo Coordination](#multi-repo-coordination)
- [Code Quality Standards](#code-quality-standards)
- [Markdown Standards](#markdown-standards)
- [Testing Requirements](#testing-requirements)
- [Documentation Standards](#documentation-standards)
- [Commit Message Guidelines](#commit-message-guidelines)
- [Pull Request Process](#pull-request-process)

## Getting Started

### Prerequisites

- macOS 13+ or Linux (Ubuntu 20.04+, Debian 12+)
- Bash 4.0+
- Git
- Pre-commit hooks installed

### Setting Up Development Environment

```bash
# Clone the repository
git clone https://github.com/oakensoul/claude-personal-assistant.git
cd claude-personal-assistant

# Install in dev mode (creates symlinks for live editing)
./install.sh --dev

# Install pre-commit hooks
pre-commit install
```

## Development Workflow

### Branching Strategy

We use milestone-based feature branches:

```text
milestone-v{version}/{type}/{id}-{description}
```

Examples:

- `milestone-v0.1/feature/16-installation-script-foundation`
- `milestone-v0.2/fix/23-personality-loading-bug`
- `milestone-v0.2/docs/45-api-documentation`

### Creating a Branch

```bash
# Start from a clean main branch
git checkout main
git pull origin main

# Create your feature branch
git checkout -b milestone-v0.2/feature/42-your-feature-name
```

## Multi-Repo Coordination

AIDA works with a three-repository ecosystem. Understanding how they interact is critical for development.

### The Three Repositories

**1. claude-personal-assistant (this repo)** - Core AIDA framework

- **Location**: `~/.aida/`
- **Standalone**: Yes - works without dotfiles
- **Dependencies**: None
- **Provides**: AI assistant, personalities, agents, templates

**2. dotfiles (public)** - Base shell/git/vim configurations

- **Location**: `~/dotfiles/` → stowed to `~/`
- **Standalone**: Yes - works without AIDA
- **Dependencies**: Optional AIDA for integration
- **Provides**: Shell configs, git configs, AIDA integration templates

**3. dotfiles-private** - Personal overrides with secrets

- **Location**: `~/dotfiles-private/` → stowed to `~/`
- **Standalone**: No - overlays dotfiles and/or AIDA
- **Dependencies**: Either dotfiles or AIDA (or both)
- **Provides**: API keys, secrets, personal customizations

See [docs/architecture/dotfiles-integration.md](../architecture/dotfiles-integration.md) for complete architecture details.

### Development Order

**When developing features:**

1. **AIDA framework** (this repo):
   - Develop and test standalone
   - Ensure works without dotfiles
   - Document integration points for dotfiles

2. **Dotfiles** (public repo):
   - Develop shell/git/vim standalone
   - Test without AIDA installed
   - Add AIDA integration as optional stow package
   - Test with and without AIDA

3. **Dotfiles-private**:
   - Develop personal overrides as needed
   - Test layering on top of public repos

### Testing Integration

**Test all installation flows:**

```bash
# Flow 1: AIDA only (standalone)
cd ~/.aida && ./install.sh
# Verify: ~/.aida/ created, ~/.claude/ configured
# Verify: Works without dotfiles

# Flow 2: Dotfiles only (standalone)
cd ~/dotfiles && stow shell git vim
# Verify: Shell/git/vim work
# Verify: AIDA package skipped gracefully

# Flow 3: AIDA first, then dotfiles
cd ~/.aida && ./install.sh
cd ~/dotfiles && stow */
# Verify: AIDA integration works
# Verify: Dotfiles detect ~/.aida/

# Flow 4: Dotfiles first, add AIDA later
cd ~/dotfiles && stow shell git vim
cd ~/.aida && ./install.sh
cd ~/dotfiles && stow aida
# Verify: Integration works after both installed

# Flow 5: Full stack with private
cd ~/.aida && ./install.sh
cd ~/dotfiles && stow */
cd ~/dotfiles-private && stow */
# Verify: All layers work together
# Verify: Private overrides public
```

### Version Compatibility

**Semantic versioning across repos:**

- Major versions must match: `dotfiles 0.x.x` ↔ `AIDA 0.x.x`
- Minor versions are forward compatible
- Patch versions are independent
- Document compatibility in changelogs

**Version compatibility matrix:**

| Dotfiles | AIDA | Status | Notes |
|----------|------|--------|-------|
| 0.1.x | 0.1.x | ✅ Tested | Current release |
| 0.1.x | 0.2.x | ⚠️ Partial | May miss features |
| 1.x.x | 0.x.x | ❌ Breaking | Incompatible |

### Coordinating Breaking Changes

**If AIDA changes break dotfiles:**

1. Bump AIDA major version
2. Update compatibility matrix in both repos
3. Create migration guide in AIDA repo
4. Test dotfiles with both old and new AIDA
5. Announce in both repositories
6. Update dotfiles to support migration

**If dotfiles change break AIDA integration:**

1. Bump dotfiles major version
2. Update compatibility matrix in both repos
3. Create migration guide in dotfiles repo
4. Test AIDA with both old and new dotfiles
5. Announce in both repositories

### Creating Cross-Repo Issues

**When changes require updates in multiple repos:**

1. Create primary issue in the repo where work starts
2. Create linked issues in dependent repos
3. Reference issues across repos: `owner/repo#issue`
4. Update all issues when work completes

**Example:**

```markdown
# In claude-personal-assistant
Issue #42: Add personality switching API

Related:
- dotfiles#10: Add shell alias for personality switching
- dotfiles-private#5: Configure default personality

# In dotfiles
Issue #10: Add shell alias for personality switching

Depends on:
- claude-personal-assistant#42: Personality switching API

# In dotfiles-private
Issue #5: Configure default personality

Depends on:
- claude-personal-assistant#42: Personality switching API
- dotfiles#10: Shell aliases
```

### Multi-Repo PR Strategy

**For changes spanning multiple repos:**

1. **Create PRs in dependency order**:
   - AIDA first (no dependencies)
   - Dotfiles second (may depend on AIDA)
   - Dotfiles-private last (depends on both)

2. **Link PRs across repos**:
   - Reference in PR descriptions
   - Note version requirements
   - Document testing across repos

3. **Merge in dependency order**:
   - Merge AIDA first
   - Wait for AIDA release/tag
   - Update dotfiles to reference new version
   - Merge dotfiles
   - Merge dotfiles-private

**Example PR linking:**

```markdown
# PR in claude-personal-assistant
feat: add personality switching API

Related PRs:
- dotfiles#15: Adds shell integration
- dotfiles-private#8: Configures default

Breaking changes: None
Version: 0.2.0

# PR in dotfiles
feat: add shell integration for personality switching

Depends on:
- claude-personal-assistant#42 (merged)
- claude-personal-assistant v0.2.0+ required

Testing:
- Tested with AIDA v0.2.0
- Tested without AIDA (graceful skip)
```

## Code Quality Standards

All code must pass pre-commit hooks before being committed.

### Shell Scripts

**Required:**

- Pass `shellcheck` with zero warnings
- Use Bash 4.0+ features appropriately
- Include comprehensive error handling (`set -euo pipefail`)
- Add clear comments for complex logic
- Use `readonly` for constants
- Validate all user input

**Example:**

```bash
#!/usr/bin/env bash
set -euo pipefail

# Script version
readonly VERSION="0.1.0"

# Validate input
validate_input() {
    local input="${1:-}"
    if [[ -z "${input}" ]]; then
        echo "Error: Input required" >&2
        return 1
    fi
}
```

### YAML Files

**Required:**

- Pass `yamllint` with `--strict` flag
- Use 2-space indentation
- No document-start markers (`---`) in docker-compose.yml
- Proper quoting for strings with special characters
- Consistent key ordering

**Pre-commit validation:**

```bash
pre-commit run yamllint --all-files
```

### Template Variables

**Two types of variable substitution:**

AIDA templates use a hybrid variable substitution strategy with two distinct variable formats that are processed at different times:

#### Install-Time Variables (`{{VAR}}`)

Variables using double-brace syntax are substituted during installation by `sed`.

**Syntax:** `{{VAR_NAME}}`

**When to use:**

- User home directory paths
- AIDA installation location
- Claude configuration directory
- Any path that is fixed at installation time

**Approved variables:**

- `{{AIDA_HOME}}` - AIDA installation directory (e.g., `/Users/username/.aida`)
- `{{CLAUDE_CONFIG_DIR}}` - Claude config directory (e.g., `/Users/username/.claude`)
- `{{HOME}}` - User's home directory (e.g., `/Users/username`)

**Example:**

```markdown
<!-- In template file -->
Read agent config from `{{CLAUDE_CONFIG_DIR}}/agents/tech-lead.md`

<!-- After installation -->
Read agent config from `/Users/username/.claude/agents/tech-lead.md`
```

#### Runtime Variables (`${VAR}`)

Variables using bash syntax are preserved in installed files and resolved when commands execute.

**Syntax:** `${VAR_NAME}` or `$(command)`

**When to use:**

- Project-specific paths that change based on context
- Dynamic values (timestamps, dates)
- Environment-dependent values
- Git repository locations

**Common variables:**

- `${PROJECT_ROOT}` - Current project directory
- `${GIT_ROOT}` - Git repository root
- `$(date +%Y-%m-%d)` - Current date
- Any standard bash variable

**Example:**

```markdown
<!-- In template and installed file (same) -->
Create file at `${PROJECT_ROOT}/docs/README.md`
```

#### Guidelines

**✓ DO:**

```markdown
# Install-time for user paths
{{CLAUDE_CONFIG_DIR}}/knowledge/

# Runtime for project paths
${PROJECT_ROOT}/docs/

# Mixed usage
Copy from `{{AIDA_HOME}}/templates/` to `${PROJECT_ROOT}/`
```

**✗ DON'T:**

```markdown
# Hardcoded paths
/Users/oakensoul/.claude/

# Wrong syntax for templates
${CLAUDE_CONFIG_DIR}/  # Should be {{CLAUDE_CONFIG_DIR}}
```

**Why two types?**

- **Privacy**: No hardcoded user paths in version control
- **Flexibility**: User paths set once, project paths adapt to context
- **Platform agnostic**: Works across different systems and environments

**Validation:**

Template variables are validated by `scripts/validate-templates.sh`:

```bash
# Validate templates before commit
./scripts/validate-templates.sh --verbose
```

See [templates/README.md](../templates/README.md) for complete variable substitution documentation.

## Markdown Standards

**Required for consistency:** All markdown files should pass markdownlint pre-commit hooks. Writing markdown correctly from the start helps keep our codebase clean and saves everyone time!

### Lists

**Always add blank lines before and after lists:**

```markdown
This is text before the list.

- First item
- Second item
- Third item

This is text after the list.
```

### Code Blocks

**Always specify language and add blank lines:**

```markdown
Here is some code:

` ``bash
./install.sh --dev
` ``

The code block above is properly formatted.
```

**Common languages to specify:**

- `bash` - Shell scripts and commands
- `text` - Plain text output
- `yaml` - YAML configuration
- `json` - JSON data
- `markdown` - Markdown examples

### Headings

**Use proper heading hierarchy:**

```markdown
# Main Title (H1)

## Section (H2)

### Subsection (H3)

#### Detail (H4)
```

**Always add blank lines:**

```markdown
Previous paragraph.

## New Section

First paragraph of section.
```

### Common Linting Errors

**MD032**: Lists need blank lines before/after

```markdown
# Bad
Text immediately before list
- Item 1
- Item 2
Text immediately after

# Good
Text before list

- Item 1
- Item 2

Text after list
```

**MD031**: Code blocks need blank lines before/after

```markdown
# Bad
Text before code
` ``bash
code
` ``
Text after

# Good
Text before code

` ``bash
code
` ``

Text after
```

**MD040**: Code blocks need language specifiers

```markdown
# Bad
` ``
code without language
` ``

# Good
` ``bash
code with language
` ``
```

**MD012**: No consecutive blank lines

```markdown
# Bad
Line 1


Line 2 (two blank lines above)

# Good
Line 1

Line 2 (one blank line above)
```

### Validation

**Before committing, always validate:**

```bash
# Check specific file
pre-commit run markdownlint --files path/to/file.md

# Check all markdown files
pre-commit run markdownlint --all-files
```

## Testing Requirements

**CRITICAL**: All code changes must include comprehensive tests. AIDA follows a test-driven development approach with extensive coverage across unit, integration, and cross-platform testing.

### Testing Philosophy

AIDA's testing strategy prioritizes:

1. **User data safety** - Preventing data loss is paramount
2. **Cross-platform compatibility** - Works on macOS, Linux, WSL
3. **Comprehensive coverage** - Unit tests + integration tests + installation tests
4. **CI/CD validation** - All tests must pass before merge
5. **Fast feedback** - Local testing before pushing

**Test Coverage:** 325+ tests across 7 installer modules

### Test Types

#### Unit Tests (`tests/unit/*.bats`)

Test individual shell script modules and functions.

**Location:** `tests/unit/`

**Coverage:**

- `test_prompts.bats` - User prompt functions (34 tests)
- `test_config.bats` - Configuration management (16 tests)
- `test_directories.bats` - Directory creation and validation (40 tests)
- `test_summary.bats` - Installation summary (30 tests)
- `test_templates.bats` - Template installation (48 tests)
- `test_deprecation.bats` - Deprecation handling (74 tests)
- `test_cleanup_deprecated.bats` - Cleanup operations (50 tests)

**Total:** 292 unit tests

**Run unit tests:**

```bash
# All unit tests
make test-unit

# All unit tests (alternative)
bats tests/unit/

# Specific test file
bats tests/unit/test_prompts.bats

# With verbose output
bats -t tests/unit/test_prompts.bats

# Specific test by name
bats -f "prompt_yes_no" tests/unit/test_prompts.bats
```

#### Integration Tests (`tests/integration/*.bats`)

Test upgrade scenarios and user content preservation.

**Location:** `tests/integration/`

**Coverage:**

- Fresh installation tests (5 tests)
- Upgrade preservation tests (6 tests)
- Namespace isolation tests (8 tests)
- User content preservation (7 tests)
- Dev mode tests (4 tests)
- Migration tests (3 tests)

**Total:** 33 integration tests

**What they validate:**

- User content preserved during upgrades
- Namespace isolation (`.aida/` separation)
- Config migration from v0.1.x to v0.2.0
- Complex nested directory structures
- Files with special characters
- Binary files, symlinks, hidden files
- File permissions and timestamps

**Run integration tests:**

```bash
# All integration tests
make test-integration

# Verbose output
bats -t tests/integration/test_upgrade_scenarios.bats

# Specific test category
bats -f "namespace isolation" tests/integration/test_upgrade_scenarios.bats

# Single test
bats -f "user command NOT in .aida/ preserved" tests/integration/test_upgrade_scenarios.bats
```

**See also:** [UPGRADE_TESTING.md](testing/UPGRADE_TESTING.md) for comprehensive upgrade test documentation.

#### Docker Tests (`.github/testing/`)

Containerized cross-platform testing in isolated environments.

**Test Scenarios:**

1. **fresh** - Clean installation on fresh system
2. **upgrade** - Upgrade from v0.1.x to v0.2.x
3. **migration** - Complex migration with user content
4. **dev-mode** - Development mode with symlinks
5. **all** - Complete test suite

**Platforms:**

- Ubuntu 22.04 LTS (primary)
- Ubuntu 24.04 LTS
- Debian 12

**Run Docker tests:**

```bash
# Build test image
make docker-build

# All Docker tests
make docker-test-all

# Specific scenario
make docker-test-fresh
make docker-test-upgrade

# Debug mode (interactive shell)
make docker-debug
```

**See also:** [DOCKER_TESTING.md](../.github/testing/DOCKER_TESTING.md) for complete Docker testing guide.

### Running Tests Locally

#### Quick Start

```bash
# All unit tests
make test-unit

# All integration tests
make test-integration

# All Docker tests
make docker-test-all

# Full test suite (unit + integration)
make test-all

# Complete CI validation (includes linting)
make ci
```

#### Individual Test Files

```bash
# Single test file
bats tests/unit/test_prompts.bats

# With verbose output
bats -t tests/unit/test_prompts.bats

# With line-level debugging
bats -x tests/unit/test_prompts.bats

# Specific test by name
bats -f "prompt_yes_no accepts yes" tests/unit/test_prompts.bats
```

#### Docker Testing

```bash
# Build test image
make docker-build

# Run specific scenario
make docker-test-fresh      # Fresh installation
make docker-test-upgrade    # Upgrade scenario
make docker-test-migration  # Migration with user content
make docker-test-dev-mode   # Dev mode installation

# Debug mode (interactive shell)
make docker-debug

# Manual Docker run
docker run --rm \
  -v $(pwd):/workspace \
  -e DEBUG=true \
  aida-test fresh
```

### Writing Tests

#### Test File Structure

All test files use Bats (Bash Automated Testing System):

```bash
#!/usr/bin/env bats
# Test file description and purpose

load '../helpers/test_helpers'  # Load common helpers

setup() {
  # Runs before each test
  setup_test_environment
}

teardown() {
  # Runs after each test
  teardown_test_environment
}

@test "descriptive test name that explains what is being tested" {
  # Arrange
  local input="test value"

  # Act
  run function_under_test "$input"

  # Assert
  assert_success
  assert_output "expected output"
}
```

#### Best Practices

**1. One assertion per test (when possible)**

```bash
# Good: Single focused assertion
@test "prompt_yes_no: accepts 'yes' input" {
  run prompt_yes_no "Continue?" "n" <<< "yes"
  assert_success
}

@test "prompt_yes_no: outputs prompt message" {
  run prompt_yes_no "Continue?" "n" <<< "yes"
  assert_output --partial "Continue?"
}

# Avoid: Multiple unrelated assertions
@test "prompt_yes_no: works" {
  run prompt_yes_no "Continue?" "n" <<< "yes"
  assert_success
  assert_output --partial "Continue?"
  [ -f "$some_file" ]
}
```

**2. Descriptive test names**

```bash
# Good: Clear and specific
@test "upgrade: preserves user commands outside .aida/ namespace"
@test "namespace isolation: can delete and reinstall .aida/ safely"

# Avoid: Vague names
@test "test upgrade"
@test "it works"
```

**3. Use test helpers for common operations**

```bash
# Good: Use helper functions
@test "config file created with correct format" {
  setup_test_environment
  run create_config_file "$TEST_DIR/.claude/aida-config.json"
  assert_file_exists "$TEST_DIR/.claude/aida-config.json"
  assert_file_contains "$TEST_DIR/.claude/aida-config.json" "version"
}

# Avoid: Duplicating setup code
@test "config file created" {
  mkdir -p "$BATS_TEST_TMPDIR/.claude"
  touch "$BATS_TEST_TMPDIR/.claude/aida-config.json"
  # ... duplicate code
}
```

**4. Clean up test artifacts in teardown()**

```bash
teardown() {
  # Clean up test files
  rm -rf "$TEST_DIR"

  # Restore original state if needed
  if [[ -f "$BACKUP_FILE" ]]; then
    mv "$BACKUP_FILE" "$ORIGINAL_FILE"
  fi
}
```

**5. Test both success and error cases**

```bash
@test "function succeeds with valid input" {
  run function_under_test "valid"
  assert_success
}

@test "function fails with invalid input" {
  run function_under_test "invalid"
  assert_failure
  assert_output --partial "Error:"
}

@test "function fails with missing input" {
  run function_under_test ""
  assert_failure
}
```

#### Example Test

```bash
#!/usr/bin/env bats
# Tests for user prompt functions

load '../helpers/test_helpers'

setup() {
  source "${PROJECT_ROOT}/lib/installer-common/prompts.sh"
}

@test "prompt_yes_no: accepts 'yes' input and returns success" {
  run prompt_yes_no "Continue?" "n" <<< "yes"
  assert_success
  assert_output --partial "Continue?"
}

@test "prompt_yes_no: accepts 'no' input and returns failure" {
  run prompt_yes_no "Continue?" "n" <<< "no"
  assert_failure
}

@test "prompt_yes_no: uses default value on empty input" {
  run prompt_yes_no "Continue?" "y" <<< ""
  assert_success
}
```

### Test Coverage

#### Current Coverage

| Module | Tests | Status |
|--------|-------|--------|
| prompts.sh | 34 | ✅ |
| config.sh | 16 | ✅ |
| directories.sh | 40 | ✅ |
| summary.sh | 30 | ✅ |
| templates.sh | 48 | ✅ |
| deprecation.sh | 74 | ✅ |
| cleanup-deprecated.sh | 50 | ✅ |
| **Unit Total** | **292** | **✅** |
| **Integration Total** | **33** | **✅** |
| **Grand Total** | **325+** | **✅** |

#### Coverage Goals

When adding new code, ensure:

- ✅ All public functions tested
- ✅ Edge cases covered
- ✅ Error conditions validated
- ✅ Cross-platform compatibility verified
- ✅ User data preservation tested (if applicable)
- ✅ Namespace isolation maintained (if applicable)

#### Running Coverage Analysis

```bash
# Generate coverage report
make test-coverage

# View coverage summary
cat test-results/coverage-summary.txt
```

### CI/CD Integration

All tests run automatically on GitHub Actions for every PR and push to main/milestone branches.

#### GitHub Actions Workflow

**Pipeline:** 8 stages, ~9 minutes total

**Stages:**

1. **Lint** - Shellcheck, yamllint, markdownlint
2. **Unit Tests** - 292 tests across 4 platforms (macOS, Ubuntu 22/24)
3. **Integration Tests** - 33 tests, 3 scenarios (fresh, upgrade, migration)
4. **Installation Tests** - Normal and dev mode on macOS and Ubuntu
5. **Docker Tests** - Containerized testing on 3 platforms
6. **Coverage** - Test coverage analysis
7. **Summary** - Aggregate results
8. **PR Comment** - Post summary to pull request

**Test Matrix:**

| Platform | Unit | Integration | Install | Docker |
|----------|------|-------------|---------|--------|
| ubuntu-22.04 | ✅ | ✅ | ✅ | ✅ |
| ubuntu-24.04 | ✅ | - | - | ✅ |
| macos-13 | ✅ | - | ✅ | - |
| macos-14 | ✅ | - | - | - |
| debian-12 | - | - | - | ✅ |

**See also:** [GitHub Actions Workflows](../.github/workflows/README.md) for complete CI/CD documentation.

#### Required Checks

Before merging, all PRs must pass:

- ✅ **Shellcheck** - All shell scripts pass linting
- ✅ **Unit tests** - All 292 tests pass on all platforms
- ✅ **Integration tests** - All 33 upgrade scenarios pass
- ✅ **Installation tests** - Normal and dev mode install successfully
- ✅ **Docker tests** - Containerized tests pass on all platforms
- ✅ **Template validation** - All templates have valid frontmatter
- ✅ **No test regressions** - New changes don't break existing tests

#### Viewing CI Results

**In GitHub UI:**

1. Navigate to pull request
2. Scroll to "Checks" section at bottom
3. View detailed results for each stage
4. Download artifacts for failed tests

**PR Comment:**

CI automatically posts summary to PR:

```markdown
## 🧪 Installer Test Results

| Stage | Status |
|-------|--------|
| Shell Linting | ✅ |
| Template Validation | ✅ |
| Unit Tests (292) | ✅ |
| Integration Tests (33) | ✅ |
| Installation Tests | ✅ |
| Docker Tests | ✅ |
| Coverage | ✅ |

**Overall Status:** ✅ All tests passed!
```

### Debugging Failed Tests

#### Common Issues

**1. Path issues**

**Problem:** Test fails with "file not found"

**Debug:**

```bash
# Run with verbose output
bats -t tests/unit/test_prompts.bats

# Check test directory
echo "TEST_DIR: $BATS_TEST_TMPDIR"
ls -laR "$BATS_TEST_TMPDIR"
```

**Fix:** Verify `$BATS_TEST_TMPDIR` usage, ensure paths are correct

**2. Cleanup issues**

**Problem:** Test fails on second run but passes on first

**Debug:**

```bash
# Check if teardown() is running
@test "my test" {
  echo "Running test" >&3
  # ... test code
}

teardown() {
  echo "Cleanup running" >&3
  rm -rf "$TEST_DIR"
}

# Run with verbose to see teardown
bats -t tests/unit/test_prompts.bats
```

**Fix:** Ensure teardown() removes all test artifacts

**3. Platform differences**

**Problem:** Test passes on macOS but fails on Linux (or vice versa)

**Debug:**

```bash
# Test on both platforms
make test-unit  # Local macOS
make docker-test-fresh  # Linux in Docker

# Check platform-specific commands
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS
else
  # Linux
fi
```

**Fix:** Use cross-platform commands, check stat/sed/date differences

**4. Permissions issues**

**Problem:** "Permission denied" errors

**Debug:**

```bash
# Check file permissions in test
ls -la "$TEST_FILE"
stat "$TEST_FILE"

# Verify user in Docker
docker run --rm -it aida-test whoami
```

**Fix:** Set correct permissions in setup(), run as non-root in Docker

#### Debug Techniques

**1. Add debug output**

```bash
@test "my test" {
  echo "Debug: variable = $variable" >&3
  run function_under_test
  echo "Debug: status = $status" >&3
  echo "Debug: output = $output" >&3
}

# Run with tap output to see debug
bats -t tests/unit/test_prompts.bats
```

**2. Run single test**

```bash
# Focus on failing test
bats -f "specific test name" tests/unit/test_prompts.bats

# With verbose
bats -t -f "specific test name" tests/unit/test_prompts.bats
```

**3. Interactive debugging**

```bash
# Enter Docker container
make docker-debug

# Inside container
cd /workspace
bats tests/unit/test_prompts.bats
# ... debug interactively
```

**4. Check test fixtures**

```bash
# Verify fixtures exist
ls -la .github/testing/fixtures/

# Check fixture content
cat .github/testing/fixtures/v0.1-installation/aida-config.json
tree .github/testing/fixtures/user-content/
```

### Test Helpers

Common helper functions available in `tests/helpers/test_helpers.bash`:

#### Environment Helpers

**`setup_test_environment()`**

Creates isolated test environment:

```bash
setup() {
  setup_test_environment
  # Creates $TEST_DIR with clean state
}
```

**`teardown_test_environment()`**

Cleans up test artifacts:

```bash
teardown() {
  teardown_test_environment
  # Removes $TEST_DIR and all contents
}
```

#### File Creation Helpers

**`create_test_template(path, title)`**

Creates template file with frontmatter:

```bash
@test "template has frontmatter" {
  create_test_template "$TEST_DIR/test.md" "Test Title"
  assert_file_contains "$TEST_DIR/test.md" "title: \"Test Title\""
}
```

**`create_test_config(path)`**

Creates valid config JSON:

```bash
@test "config file created" {
  create_test_config "$TEST_DIR/config.json"
  assert_file_exists "$TEST_DIR/config.json"
}
```

#### Assertion Helpers

**`assert_file_exists(file)`**

Verifies file exists:

```bash
@test "file created" {
  touch "$TEST_DIR/file.txt"
  assert_file_exists "$TEST_DIR/file.txt"
}
```

**`assert_file_contains(file, pattern)`**

Verifies file content:

```bash
@test "config has version field" {
  assert_file_contains "$TEST_DIR/config.json" "\"version\""
}
```

**`assert_file_unchanged(file, checksum)`**

Verifies file hasn't changed (critical for user data preservation):

```bash
@test "user file preserved during upgrade" {
  original_checksum=$(calculate_checksum "$USER_FILE")
  run_upgrade
  assert_file_unchanged "$USER_FILE" "$original_checksum"
}
```

**`assert_namespace_structure(base_dir)`**

Verifies namespace directories exist:

```bash
@test "namespace structure created" {
  assert_namespace_structure "$TEST_DIR/.claude"
  # Checks for .aida/ subdirectories
}
```

#### Utility Helpers

**`calculate_checksum(file)`**

Cross-platform file checksumming:

```bash
checksum=$(calculate_checksum "$file")
```

**`get_file_timestamp(file)`**

Cross-platform modification time:

```bash
timestamp=$(get_file_timestamp "$file")
```

### Test Documentation

When adding features that require new test scenarios, document them in `.github/testing/test-scenarios.md`:

```markdown
## Test Scenario: Feature X

**Purpose:** Validate feature X behavior

**Setup:**

- Fresh Ubuntu 22.04 environment
- AIDA framework not installed

**Steps:**

1. Run `./install.sh`
2. Select "JARVIS" personality
3. Verify `~/.claude/config/` created

**Expected Results:**

- Installation succeeds
- JARVIS configuration loaded
- All directories created with correct permissions

**Validation:**

```bash
# Verify installation
test -d ~/.claude
test -f ~/.claude/aida-config.json
grep -q "JARVIS" ~/.claude/aida-config.json
```
```

### Performance Testing

For performance-critical code, add timing validation:

```bash
@test "installation completes in reasonable time" {
  start_time=$(date +%s)

  run ./install.sh
  assert_success

  end_time=$(date +%s)
  duration=$((end_time - start_time))

  # Should complete in under 30 seconds
  [ "$duration" -lt 30 ]
}
```

### Related Documentation

- [UPGRADE_TESTING.md](testing/UPGRADE_TESTING.md) - Comprehensive upgrade testing guide
- [DOCKER_TESTING.md](../.github/testing/DOCKER_TESTING.md) - Docker testing infrastructure
- [GitHub Actions Workflows](../.github/workflows/README.md) - CI/CD pipeline documentation
- [Bats Documentation](https://bats-core.readthedocs.io/) - Official Bats testing framework docs

## Documentation Standards

### Required Documentation

Every feature must include:

1. **Code comments** - Explain complex logic
2. **README updates** - Document user-facing changes
3. **CHANGELOG entry** - Document all changes
4. **Issue documentation** - Complete resolution section

### Frontmatter

All documentation uses YAML frontmatter:

```yaml
---
title: "Document Title"
description: "Brief description"
category: "getting-started"
tags: ["tag1", "tag2"]
last_updated: "2025-10-05"
status: "published"
audience: "users"
---
```

### README Updates

**When to update README.md:**

- New features added
- Installation process changes
- New requirements
- Version bump

**Recent Changes section:**

Keep the last 2-3 versions visible in README.md. Full history goes in CHANGELOG.md.

## Commit Message Guidelines

### Format

```text
type(scope): brief description

Detailed explanation (optional)

Related: #issue-number
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `chore`: Maintenance tasks (version bump, etc.)
- `test`: Test additions/modifications
- `refactor`: Code refactoring

### Examples

```text
feat(install): add development mode with symlinks

Implemented --dev flag that creates symlinks instead of copying files.
This enables live editing during framework development.

Related: #16
```

```text
fix(yaml): remove document-start marker from docker-compose

Removed --- marker that caused yamllint strict mode to fail in CI.
Updated pre-commit config to match GitHub Actions validation.

Related: #32
```

## Pull Request Process

### Before Creating PR

1. **All tests pass locally**

   ```bash
   pre-commit run --all-files
   ./.github/testing/test-install.sh
   ```

2. **Version bumped** (if applicable)

   ```bash
   # Update version in install.sh
   readonly VERSION="0.2.0"

   # Update CHANGELOG.md
   # Update README.md Recent Changes
   ```

3. **Issue documentation complete**

   ```bash
   # Move issue to completed
   mv .github/issues/in-progress/issue-XX/ .github/issues/completed/

   # Add resolution section
   # Update frontmatter with PR number
   ```

### Creating the PR

Use `/open-pr` command which handles:

- Version bumping
- Changelog updates
- README updates
- Issue documentation
- Reviewer assignment

```bash
# From your feature branch
/open-pr
```

### PR Requirements

**Must have:**

- ✅ All CI checks passing
- ✅ Issue documentation in `completed/` directory
- ✅ CHANGELOG.md updated
- ✅ README.md updated (if user-facing)
- ✅ Test coverage for new features
- ✅ No markdown/yaml/shell linting errors

**Will be rejected if:**

- ❌ Pre-commit hooks failing
- ❌ Tests failing
- ❌ Incomplete documentation
- ❌ Breaking changes without migration guide

### After Merge

Use `/cleanup-main` to:

- Update local main branch
- Delete feature branch
- Clean up local environment

## Questions?

- **Issues**: [GitHub Issues](https://github.com/oakensoul/claude-personal-assistant/issues)
- **Discussions**: [GitHub Discussions](https://github.com/oakensoul/claude-personal-assistant/discussions)
- **Documentation**: See `docs/` directory

---

**Remember**: Quality over speed. Take time to write code correctly the first time, following all linting rules and standards. Pre-commit hooks are there to help, not to fix sloppy work.
