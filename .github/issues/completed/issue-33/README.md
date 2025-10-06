---
issue: 33
title: "Support dotfiles installer integration - shared installer-common library and VERSION file"
status: "COMPLETED"
created: "2025-10-05 00:00:00"
completed: "2025-10-06"
estimated_effort: 2
actual_effort: 10
pr: 36
---

# Issue #33: Support dotfiles installer integration - shared installer-common library and VERSION file

**Status**: COMPLETED
**Labels**: type:task, priority:p1, complexity:S
**Milestone**: 0.1.0 - Foundation
**Assignees**: oakensoul

## Description

## Summary

The dotfiles installer needs to source shared utilities and check version compatibility with the AIDA framework. This requires the claude-personal-assistant repository to provide:

1. A `VERSION` file as single source of truth for AIDA version
2. A `lib/installer-common/` directory with shared installer utilities
3. Compatibility for dotfiles to source these utilities during installation

## Context

The dotfiles installer architecture uses an "inverted template" approach where:

- User's actual configs live in `~/dotfiles-private/` (stowed to `~/`)
- AIDA dotfiles provides templates at `~/dotfiles/` (NOT stowed)
- User configs source AIDA templates

The installer needs to:

- Clone AIDA framework to `~/.aida/`
- Source utilities from `~/.aida/lib/installer-common/`
- Check AIDA version compatibility via `~/.aida/VERSION`

## Requirements

### 1. VERSION File

**Location**: `VERSION` (repository root)

**Format**: Plain text, semantic version

```text
0.1.0
```

**Purpose**:

- Single source of truth for AIDA version
- Read by dotfiles installer for compatibility checks
- Used in release tagging

**Implementation**:

```bash
# In repository root
echo "0.1.0" > VERSION

# Update on each release
git commit -m "Release v0.1.0"
git tag v0.1.0
```

### 2. Shared Installer-Common Library

**Location**: `lib/installer-common/`

**Files needed**:

```text
lib/
└── installer-common/
    ├── colors.sh           # Terminal color utilities
    ├── logging.sh          # Logging and progress functions
    ├── validation.sh       # Input validation
    └── platform-detect.sh  # OS/platform detection (optional for v0.1)
```

**Purpose**:

- Shared utilities for both AIDA and dotfiles installers
- Sourced by dotfiles installer at `~/.aida/lib/installer-common/`
- Single source of truth for common installer code

**Example - colors.sh**:

```bash
#!/usr/bin/env bash
# colors.sh - Terminal color utilities
# Part of AIDA installer-common library v1.0

readonly COLOR_RESET='\033[0m'
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
# ...

color_success() {
    if supports_color; then
        echo -e "${COLOR_GREEN}${1}${COLOR_RESET}"
    else
        echo "$1"
    fi
}
# ... more functions
```

**Example - logging.sh**:

```bash
#!/usr/bin/env bash
# logging.sh - Logging utilities
# Part of AIDA installer-common library v1.0

log_success() {
    echo "$(color_success '✓') $1"
}

log_error() {
    echo "$(color_error '✗') $1" >&2
}
# ... more functions
```

### 3. Dotfiles Integration Pattern

**How dotfiles sources these utilities**:

```bash
# In dotfiles/install.sh

readonly AIDA_PATH="${HOME}/.aida"

# Install AIDA first
git clone --branch v0.1.0 https://github.com/.../claude-personal-assistant.git "$AIDA_PATH"

# Source shared utilities from AIDA
source "${AIDA_PATH}/lib/installer-common/colors.sh"
source "${AIDA_PATH}/lib/installer-common/logging.sh"
source "${AIDA_PATH}/lib/installer-common/validation.sh"

# Check version compatibility
AIDA_VERSION=$(cat "${AIDA_PATH}/VERSION")
# ... version checking logic
```

## Technical Details

**Version Compatibility**:

- Dotfiles specifies required AIDA version range in `.aida-version`
- Installer clones specific AIDA tag (e.g., `v0.1.0`)
- Checks `VERSION` file after clone to verify

**Example dotfiles .aida-version**:

```bash
MIN_VERSION="0.1.0"
MAX_VERSION="0.2.0"
RECOMMENDED_VERSION="v0.1.0"
```

**No Circular Dependency**:

- AIDA installer does NOT depend on dotfiles
- Dotfiles installer DOES depend on AIDA
- Clean one-way dependency

## Estimated Effort

**Hours**: 2

## Acceptance Criteria

- [x] `VERSION` file exists in repository root with current version (0.1.0)
- [x] `lib/installer-common/` directory created
- [x] `lib/installer-common/colors.sh` implemented with color utilities
- [x] `lib/installer-common/logging.sh` implemented with logging functions
- [x] `lib/installer-common/validation.sh` implemented with input validation
- [x] All installer-common files have proper shebang and documentation
- [x] AIDA's own `install.sh` sources from `lib/installer-common/`
- [x] Files pass shellcheck linting
- [x] Version in `VERSION` file matches latest git tag
- [x] Documentation updated explaining installer-common library

## Labels

type:task, priority:p1, complexity:S

## Assignee

@oakensoul

## Related Issues

- oakensoul/dotfiles - Dotfiles installer implementation (blocked by this)

## Suggested Branch Name

When ready to start work, use:
`milestone-v0.1/task/[ISSUE-ID]-installer-common-version`

Example: `milestone-v0.1/task/42-installer-common-version`

## Notes

This is the ONLY hard dependency between AIDA and dotfiles for v0.1.0. Once this is complete, dotfiles can be fully implemented independently.

## Work Tracking

- Branch: `milestone-v0.1/task/33-installer-common-version`
- Started: 2025-10-05
- Completed: 2025-10-06
- Work directory: `.github/issues/completed/issue-33/`

## Related Links

- [GitHub Issue](https://github.com/oakensoul/claude-personal-assistant/issues/33)
- [Pull Request #36](https://github.com/oakensoul/claude-personal-assistant/pull/36)
- [Project Board](https://github.com/oakensoul/claude-personal-assistant/projects)

## Resolution

**Completed**: 2025-10-06
**Pull Request**: #36

### Changes Made

Created `lib/installer-common/` library with reusable shell utilities for AIDA and dotfiles installers:

**New Files**:

- `lib/installer-common/colors.sh` (117 lines) - Terminal color utilities with NO_COLOR support
- `lib/installer-common/logging.sh` (120 lines) - Structured logging to ~/.aida/logs/install.log with path scrubbing
- `lib/installer-common/validation.sh` (305 lines) - Input validation and security controls (Phase 1)
- `lib/installer-common/README.md` (418 lines) - Comprehensive API documentation and integration guide

**Modified Files**:

- `install.sh` - Refactored to source utilities from lib/installer-common/ (+26 insertions, -86 deletions)

**Total**: +986 insertions, -86 deletions across 5 files

### Implementation Details

**Security Features (Phase 1)**:

- Input sanitization with allowlist validation (versions, paths, filenames)
- Path canonicalization using realpath (reject .. traversal)
- File permission validation (reject world-writable files)
- Semantic version compatibility checking (major match, minor forward-compatible)
- Secure logging with path scrubbing (replaces /Users/username/ with ~/)

**Bash 3.2 Compatibility**:

- Replaced `${var,,}` with `$(echo "$var" | tr '[:upper:]' '[:lower:]')`
- Replaced `${var^^}` with `$(echo "$var" | tr '[:lower:]' '[:upper:]')`
- Updated Bash version requirement from 4.0+ to 3.2+ (macOS default)
- Platform-specific stat syntax (macOS BSD vs Linux GNU)

**Quality Assurance**:

- All files pass shellcheck validation (zero warnings)
- Tested on macOS Bash 3.2.57 (default macOS shell)
- Installation script loads utilities correctly
- Comprehensive documentation with API reference

### Key Technical Decisions

1. **Bash 3.2 Compatibility**: Downgraded from Bash 4.0+ to support macOS default shell without Homebrew
2. **Phase 1 Security Only**: Implemented critical security controls (input sanitization, path validation, permissions), deferred Phase 2 (checksums, GPG) to v0.2.0
3. **Semantic Versioning**: Major match required, minor forward-compatible (AIDA 0.2.0 works with dotfiles requiring >=0.1.0)
4. **Two-Tier Logging**: Generic user-facing messages, detailed errors in secure log file (600 permissions)

### Notes

- Ready for dotfiles installer integration
- Enables code reuse between AIDA and dotfiles installers
- Single source of truth for common installer code
- Security-focused design prevents common shell vulnerabilities
- Comprehensive documentation for external consumers
