---
title: "QA Engineer - AIDA Project Instructions"
description: "AIDA-specific testing requirements and validation standards"
category: "project-agent-instructions"
tags: ["aida", "qa-engineer", "project-context"]
last_updated: "2025-10-09"
status: "active"
---

# AIDA QA Engineer Instructions

Project-specific testing standards and requirements for the AIDA framework.

## AIDA Testing Philosophy

**Non-Negotiable**: Everything must pass automated testing before merge.

### Core Testing Principles

1. **Container-Based Testing**: All tests run in Docker containers (no local pollution)
2. **Cross-Platform Validation**: Test on macOS and Linux
3. **Linting Required**: Zero tolerance for linting failures
4. **Installation Testing**: Validate both normal and dev modes
5. **Regression Prevention**: Existing functionality never breaks

## Platform Testing Matrix

### Supported Platforms

**macOS**:

- macOS Sonoma (14.x)
- macOS Sequoia (15.x)
- Default shells: bash 3.2, zsh 5.x

**Linux**:

- Ubuntu 22.04 LTS
- Ubuntu 24.04 LTS
- Debian 12
- Default shells: bash 5.x, zsh 5.x

### Shell Compatibility

**Critical**: Must support Bash 3.2 (macOS default)

```bash
# Test across shell versions
shells:
  - bash-3.2  # macOS default (no associative arrays!)
  - bash-5.x  # Linux, Homebrew
  - zsh-5.x   # macOS default since Catalina
```

**Compatibility Requirements**:

- No Bash 4+ features (associative arrays, etc.)
- No Linux-specific commands (use portable alternatives)
- Test `readlink` vs `greadlink` (macOS differences)

## Installation Testing

### Test Scenarios

**Normal Installation**:

```bash
# Test standard installation flow
./install.sh

# Validate structure
test -d ~/.aida/
test -d ~/.claude/
test -f ~/CLAUDE.md
test -f ~/.aida/personalities/jarvis.yml
```

**Dev Mode Installation**:

```bash
# Test development mode with symlinks
./install.sh --dev

# Validate symlinks
test -L ~/.aida/
readlink ~/.aida/ | grep "$(pwd)"
```

**Upgrade Scenarios**:

```bash
# Test upgrade from v0.1.0 to v0.2.0
# 1. Install v0.1.0
# 2. Modify user config
# 3. Install v0.2.0
# 4. Validate config preserved
# 5. Validate new features work
```

### Installation Validation

**Directory Structure**:

```bash
# Validate required directories exist
required_dirs=(
    "~/.aida/"
    "~/.aida/personalities/"
    "~/.aida/templates/"
    "~/.aida/lib/"
    "~/.claude/"
    "~/.claude/agents/"
    "~/.claude/commands/"
)

for dir in "${required_dirs[@]}"; do
    test -d "$dir" || echo "FAIL: Missing $dir"
done
```

**File Permissions**:

```bash
# Validate secure permissions
test "$(stat -f %A ~/.claude)" = "700" || echo "FAIL: Insecure ~/.claude/"
test "$(stat -f %A ~/CLAUDE.md)" = "644" || echo "FAIL: Wrong CLAUDE.md perms"
```

## Linting Requirements

### Automated Linting

**Shell Scripts** (shellcheck):

```bash
# All .sh files must pass
shellcheck --severity=warning install.sh
shellcheck scripts/*.sh
shellcheck lib/**/*.sh
```

**YAML Files** (yamllint):

```yaml
# yamllint --strict required
# .yamllint.yml
---
extends: default
rules:
  line-length:
    max: 120
  document-start: disable  # No --- markers in docker-compose
  indentation:
    spaces: 2
```

**Markdown Files** (markdownlint):

```bash
# All .md files must pass
markdownlint --config .markdownlint.yml **/*.md
```

**GitHub Actions** (actionlint):

```bash
# Validate all workflow files
actionlint .github/workflows/*.yml
```

### Linting Enforcement

**Pre-commit Hooks**:

```bash
#!/bin/bash
# .git/hooks/pre-commit

set -euo pipefail

echo "Running linters..."

# Shell check
find . -name "*.sh" -exec shellcheck {} + || exit 1

# YAML lint
yamllint --strict . || exit 1

# Markdown lint
markdownlint **/*.md || exit 1

echo "✓ All linters passed"
```

**CI/CD Pipeline**:

```yaml
# .github/workflows/lint.yml
name: Lint

on: [push, pull_request]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: ShellCheck
        run: |
          find . -name "*.sh" -exec shellcheck {} +
      - name: YAML Lint
        run: yamllint --strict .
      - name: Markdown Lint
        run: markdownlint **/*.md
```

## Container-Based Testing

### Docker Test Environment

**Test Containers**:

```yaml
# .github/testing/docker-compose.yml
version: '3.8'

services:
  macos-bash3:
    build:
      context: .
      dockerfile: Dockerfile.macos-bash3
    volumes:
      - ../../:/aida
    command: /aida/.github/testing/test-install.sh

  ubuntu-22:
    build:
      context: .
      dockerfile: Dockerfile.ubuntu-22
    volumes:
      - ../../:/aida
    command: /aida/.github/testing/test-install.sh

  debian-12:
    build:
      context: .
      dockerfile: Dockerfile.debian-12
    volumes:
      - ../../:/aida
    command: /aida/.github/testing/test-install.sh
```

### Test Execution

**Local Testing**:

```bash
# Run all platform tests
./.github/testing/test-install.sh --all

# Test specific platform
./.github/testing/test-install.sh --env ubuntu-22

# Verbose output
./.github/testing/test-install.sh --verbose
```

**CI/CD Testing**:

```yaml
# .github/workflows/test.yml
name: Test

on: [push, pull_request]

jobs:
  test-install:
    strategy:
      matrix:
        platform: [macos-bash3, ubuntu-22, ubuntu-24, debian-12]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Test ${{ matrix.platform }}
        run: |
          ./.github/testing/test-install.sh --env ${{ matrix.platform }}
```

## Component Testing

### Personality System Testing

**Personality Loading**:

```bash
# Test personality validation
test_personality_validation() {
    # Valid personality should load
    aida personality jarvis
    [ "$(aida status --personality)" = "jarvis" ]

    # Invalid personality should fail gracefully
    aida personality invalid-personality 2>&1 | grep "not found"
}
```

**Personality Switching**:

```bash
# Test personality switching
test_personality_switch() {
    aida personality jarvis
    [ "$(aida status --personality)" = "jarvis" ]

    aida personality alfred
    [ "$(aida status --personality)" = "alfred" ]

    # History tracking
    aida personality history | grep "jarvis"
    aida personality history | grep "alfred"
}
```

### Template System Testing

**Variable Substitution**:

```bash
# Test install-time variable substitution
test_install_time_variables() {
    # Template should have {{VARIABLES}}
    grep "{{AIDA_HOME}}" templates/agents/example.md

    # Installed file should have expanded variables
    grep "$HOME/.aida" ~/.claude/agents/example.md
    ! grep "{{AIDA_HOME}}" ~/.claude/agents/example.md
}

# Test runtime variable preservation
test_runtime_variables() {
    # ${VARIABLES} should NOT be expanded during install
    grep "\${PROJECT_ROOT}" ~/.claude/commands/example.md
    ! grep "$(pwd)" ~/.claude/commands/example.md
}
```

### Agent System Testing

**Agent Loading**:

```bash
# Test agent discovery
test_agent_discovery() {
    # User-level agents
    test -d ~/.claude/agents/tech-lead/

    # Project-level context
    cd /path/to/project
    test -d .claude/project/agents/tech-lead/

    # Agent should load both
    aida agent list | grep "tech-lead"
}
```

### Command System Testing

**Command Execution**:

```bash
# Test workflow commands
test_workflow_commands() {
    cd /path/to/project

    # /workflow-init should create structure
    aida workflow-init
    test -d .claude/project/agents/
    test -f .claude/CLAUDE.md

    # /start-work should create branch
    aida start-work 42
    git branch | grep "issue-42"
}
```

## Integration Testing

### Obsidian Integration

**API Availability**:

```bash
# Test Obsidian API graceful degradation
test_obsidian_offline() {
    # Mock offline Obsidian
    export OBSIDIAN_API="http://localhost:99999"

    # AIDA should continue working
    aida status
    [ $? -eq 0 ]

    # But warn about Obsidian
    aida status 2>&1 | grep "Obsidian.*unavailable"
}
```

### GNU Stow Integration

**Stow Compatibility**:

```bash
# Test AIDA works standalone
test_standalone() {
    ./install.sh
    aida status
    [ $? -eq 0 ]
}

# Test AIDA works with stow
test_with_stow() {
    cd ~/dotfiles
    stow aida
    aida status
    [ $? -eq 0 ]
}
```

### Git Integration

**Pre-commit Hooks**:

```bash
# Test privacy validation
test_precommit_privacy() {
    cd /path/to/project

    # Add file with PII
    echo "api_key: sk-1234567890" > test.yml
    git add test.yml

    # Commit should fail
    git commit -m "test" 2>&1 | grep "PII detected"
    [ $? -eq 1 ]
}
```

## Regression Testing

### Version Compatibility

**Backward Compatibility**:

```bash
# Test v0.1.x configs work with v0.2.x
test_backward_compat() {
    # Install v0.1.0
    git checkout v0.1.0
    ./install.sh

    # Create user config
    aida personality jarvis

    # Upgrade to v0.2.0
    git checkout v0.2.0
    ./install.sh

    # Old config should still work
    aida personality
    [ "$(aida status --personality)" = "jarvis" ]
}
```

### Feature Preservation

**Critical Features**:

1. Personality switching must always work
2. Installation must never fail silently
3. User configurations must never be lost
4. Linting must always pass

## Test Documentation

### Test Coverage Report

**Required Coverage**:

- Installation: 100% (all scenarios tested)
- Personality System: 100%
- Template System: 100%
- Linting: 100% (all files pass)
- Cross-Platform: 100% (all platforms tested)

### Test Execution Reports

**CI/CD Reports**:

```yaml
# Store test artifacts
- name: Upload test results
  uses: actions/upload-artifact@v4
  with:
    name: test-results-${{ matrix.platform }}
    path: .github/testing/results/
```

## Integration Notes

- **User-level QA Patterns**: Load from `~/.claude/agents/qa-engineer/`
- **Project-specific requirements**: This file
- **Combined approach**: User philosophy + AIDA requirements

## Best Practices for AIDA

1. **Test Everything**: No code ships without tests
2. **Container Isolation**: Never pollute local environment
3. **Cross-Platform**: Test on all supported platforms
4. **Linting**: Zero tolerance for linting failures
5. **Automation**: All tests run in CI/CD

---

**Last Updated**: 2025-10-09
