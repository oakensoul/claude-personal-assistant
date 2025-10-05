---
title: "Contributing to AIDA Framework"
description: "Guidelines for contributing to the Claude Personal Assistant (AIDA) project"
category: "development"
tags: ["contributing", "guidelines", "development", "standards"]
last_updated: "2025-10-05"
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

## Markdown Standards

**CRITICAL**: All markdown files MUST pass markdownlint pre-commit hooks. Write markdown correctly the first time - fixing linting errors wastes time.

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

### Required Tests

All features must include:

1. **Unit tests** - Test individual functions
2. **Integration tests** - Test component interactions
3. **Documentation** - Test scenarios documented

### Shell Script Testing

**Use the provided test infrastructure:**

```bash
# Run all Docker tests
./.github/testing/test-install.sh

# Test specific environment
./.github/testing/test-install.sh --env ubuntu-22

# Verbose output
./.github/testing/test-install.sh --verbose
```

### Test Documentation

Create test scenarios in `.github/testing/test-scenarios.md`:

```markdown
## Test Scenario: Feature X

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
```

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
