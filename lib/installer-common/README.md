# AIDA Installer-Common Library

**Version**: 1.0
**Part of**: AIDA Framework v0.1.2
**Purpose**: Shared installer utilities for AIDA and dotfiles repositories

## Overview

The `installer-common` library provides reusable shell utilities for installation scripts across the AIDA ecosystem. This ensures consistent user experience, reduces code duplication, and maintains a single source of truth for installer logic.

### Key Features

- **Terminal Colors**: Consistent color output with NO_COLOR support
- **Logging**: Structured logging with file output and path scrubbing
- **Validation**: Input sanitization, version compatibility, security controls
- **Security**: Path canonicalization, permission checks, world-writable detection
- **Compatibility**: Bash 3.2+ (macOS compatible)

## Library Files

```text
lib/installer-common/
├── README.md          # This file
├── colors.sh          # Color codes and formatting
├── logging.sh         # Structured logging with file output
└── validation.sh      # Input validation and security controls
```

## Integration Pattern

### For AIDA Installer (Internal Use)

```bash
#!/usr/bin/env bash
set -euo pipefail

# Script directory (repository root)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# Source utilities from local lib/
readonly INSTALLER_COMMON="${SCRIPT_DIR}/lib/installer-common"

source "${INSTALLER_COMMON}/colors.sh" || exit 1
source "${INSTALLER_COMMON}/logging.sh" || exit 1
source "${INSTALLER_COMMON}/validation.sh" || exit 1

# Now use utilities
print_message "info" "Starting installation..."
validate_dependencies || exit 1
```

### For Dotfiles Installer (External Consumer)

```bash
#!/usr/bin/env bash
set -euo pipefail

# Step 1: Check AIDA installed
AIDA_DIR="${HOME}/.aida"
if [[ ! -d "$AIDA_DIR" ]]; then
    echo "Error: AIDA framework required but not found at ${AIDA_DIR}"
    echo "Install AIDA: https://github.com/oakensoul/claude-personal-assistant"
    exit 1
fi

# Step 2: Validate VERSION compatibility
AIDA_VERSION=$(cat "${AIDA_DIR}/VERSION" 2>/dev/null || echo "")
MIN_AIDA_VERSION="0.1.2"

if [[ "$AIDA_VERSION" < "$MIN_AIDA_VERSION" ]]; then
    echo "Error: AIDA version $AIDA_VERSION too old (requires >=${MIN_AIDA_VERSION})"
    echo "Upgrade AIDA: cd ~/.aida && git pull && ./install.sh"
    exit 1
fi

# Step 3: Canonicalize paths (security)
if ! command -v realpath >/dev/null 2>&1; then
    echo "Error: realpath command required"
    echo "Install on macOS: brew install coreutils"
    exit 1
fi

INSTALLER_COMMON=$(realpath "${AIDA_DIR}/lib/installer-common" 2>/dev/null) || {
    echo "Error: Cannot resolve installer-common path"
    exit 1
}

# Step 4: Validate library exists
if [[ ! -d "$INSTALLER_COMMON" ]]; then
    echo "Error: Installer library not found: ${INSTALLER_COMMON}"
    echo "AIDA installation may be corrupted. Reinstall with: cd ~/.aida && ./install.sh"
    exit 1
fi

# Step 5: Source utilities in dependency order
source "${INSTALLER_COMMON}/colors.sh" || exit 1
source "${INSTALLER_COMMON}/logging.sh" || exit 1
source "${INSTALLER_COMMON}/validation.sh" || exit 1

# Step 6: Now safe to use utilities
print_message "success" "AIDA utilities loaded (v${AIDA_VERSION})"
```

## API Reference

### colors.sh

#### Functions

- **`supports_color()`** - Check if terminal supports colors
  - Returns: 0 if colors supported, 1 otherwise
  - Checks: NO_COLOR env var, terminal type, TERM variable

- **`apply_color(color, text)`** - Apply color to text if supported
  - Args: Color code, text string
  - Returns: Colored text if supported, plain text otherwise

- **`color_red(text)`** - Output text in red
- **`color_green(text)`** - Output text in green
- **`color_yellow(text)`** - Output text in yellow
- **`color_blue(text)`** - Output text in blue

#### Color Constants

- `COLOR_RED` - Red color code
- `COLOR_GREEN` - Green color code
- `COLOR_YELLOW` - Yellow color code
- `COLOR_BLUE` - Blue color code
- `COLOR_NC` - No color (reset)

### logging.sh

#### Functions

- **`init_logging()`** - Initialize logging (create log directory)
  - Creates: `~/.aida/logs/` (permissions: 700)
  - Returns: 0 on success

- **`log_to_file(level, message)`** - Write detailed message to log file
  - Args: Log level (INFO, SUCCESS, WARNING, ERROR), message text
  - Output: `~/.aida/logs/install.log` (permissions: 600)
  - Features: Timestamp, path scrubbing (replaces /Users/username/ with ~/)

- **`print_message(type, message)`** - Print formatted message to stdout/stderr
  - Args: Message type (info, success, warning, error), message text
  - Output: Formatted with colored icons (ℹ, ✓, ⚠, ✗)
  - Logging: Automatically logs to file

- **`print_error_with_detail(generic_message, detailed_message)`** - Print generic error with detailed log
  - Args: Generic user-facing message, detailed error message
  - Output: Generic to stderr, detailed to log file
  - Feature: Informs user of log location

#### Log File

- **Location**: `~/.aida/logs/install.log`
- **Permissions**: 600 (owner read/write only)
- **Format**: `[YYYY-MM-DD HH:MM:SS] [LEVEL] message`
- **Path Scrubbing**: `/Users/username/` → `~/`

### validation.sh

#### Version Functions

- **`validate_version(version)`** - Validate semantic version format
  - Args: Version string (e.g., "0.1.2")
  - Returns: 0 if valid (MAJOR.MINOR.PATCH), 1 if invalid
  - Regex: `^[0-9]+\.[0-9]+\.[0-9]+$`

- **`check_version_compatibility(installed_version, required_version)`** - Check semantic version compatibility
  - Args: Installed version, required version
  - Returns: 0 if compatible, 1 if incompatible
  - Logic: Major must match exactly, minor must be >= required (forward compatible)
  - Example: AIDA 0.2.0 is compatible with dotfiles requiring >=0.1.0

- **`validate_version_file(version_file_path)`** - Validate VERSION file and return version
  - Args: Path to VERSION file
  - Returns: 0 if valid, 1 if invalid
  - Output: Version string to stdout if valid
  - Checks: File exists, permissions secure, format valid

#### Path Security Functions

- **`validate_path(path, expected_prefix)`** - Validate and canonicalize path
  - Args: Path to validate, expected prefix (default: $HOME)
  - Returns: 0 if valid, 1 if invalid
  - Output: Canonical path to stdout if valid
  - Security:
    - Rejects paths containing `..` (path traversal)
    - Requires realpath command
    - Validates path is within expected prefix
  - Logs: Security violations to log file

- **`validate_file_permissions(file)`** - Validate file permissions (reject world-writable)
  - Args: File path to check
  - Returns: 0 if valid, 1 if invalid
  - Security:
    - Rejects world-writable files (last octal digit: 2, 3, 6, 7)
    - Platform-specific stat syntax (macOS BSD vs Linux GNU)
  - Logs: Security violations to log file

- **`validate_filename(filename)`** - Validate filename (alphanumeric, underscore, hyphen, dot)
  - Args: Filename to validate
  - Returns: 0 if valid, 1 if invalid
  - Rules:
    - No leading dot
    - Allowlist: `[a-zA-Z0-9._-]+`

#### System Functions

- **`validate_dependencies()`** - Validate system dependencies
  - Returns: 0 on success, number of errors on failure
  - Checks:
    - Bash version >= 3.2 (macOS compatible)
    - Required commands: git, mkdir, chmod, ln, rsync, date, mv, find, realpath
    - Write permissions to $HOME

## Security Guidelines

### For Library Maintainers

**CRITICAL**: This library affects both AIDA and dotfiles installers. Security vulnerabilities have 2x blast radius.

**Security Controls (Phase 1 - Mandatory for v0.1.2)**:

1. **Input Sanitization** - Allowlist validation for all user input
   - Versions: `^[0-9]+\.[0-9]+\.[0-9]+$`
   - Filenames: `^[a-zA-Z0-9._-]+$`, no leading dot
   - Paths: realpath canonicalization, reject `..`

2. **Path Canonicalization** - Use realpath, validate prefix
   - Always canonicalize before use
   - Validate paths are within $HOME
   - Reject paths containing `..`

3. **Permission Validation** - Reject world-writable files
   - Check before every source operation
   - Reject world-writable (last octal digit: 2, 3, 6, 7)
   - Platform-specific stat syntax

4. **Logging** - Two-tier error system
   - Generic user-facing messages
   - Detailed errors to secure log file (600 permissions)
   - Path scrubbing to prevent username exposure

**What NOT to do**:

- ❌ No `eval` or unquoted expansions
- ❌ No optional security controls (users will disable them)
- ❌ No "we'll add security later" mindset
- ❌ No shortcuts on input sanitization

### For External Consumers (Dotfiles)

**MUST Do**:

1. Validate AIDA version compatibility BEFORE sourcing
2. Canonicalize paths with realpath
3. Check file permissions before sourcing
4. Use `set -euo pipefail` for error handling
5. Quote all variable expansions

**MUST NOT Do**:

1. NEVER source from dotfiles if you are AIDA (circular dependency)
2. NEVER skip version validation
3. NEVER source without permission checks
4. NEVER assume AIDA is installed

## Version Compatibility

### Semantic Versioning Rules

- **Major version** must match exactly (0.x → 0.x only)
- **Minor version** must be >= required (forward compatible)
- **Patch version** doesn't affect compatibility

### Compatibility Matrix

| AIDA Version | Dotfiles Requires | Compatible? | Reason |
|--------------|-------------------|-------------|--------|
| 0.1.2        | >=0.1.0           | ✓           | Minor/patch match |
| 0.2.0        | >=0.1.0           | ✓           | Forward compatible (higher minor) |
| 0.1.0        | >=0.1.2           | ✗           | AIDA too old |
| 1.0.0        | >=0.1.0           | ✗           | Major version mismatch |

### API Stability Guarantees

- **Within minor versions** (0.1.x): API stable, no breaking changes
- **Minor version bump** (0.1.x → 0.2.x): May add features, backward compatible
- **Major version bump** (0.x.x → 1.x.x): Breaking changes allowed, migration guide provided

## Prerequisites

### Required Commands

- **bash** (>=3.2) - Shell interpreter
- **realpath** - Path canonicalization (GNU coreutils)
  - macOS: `brew install coreutils`
  - Linux: Pre-installed (usually)
- **stat** - File permissions (POSIX, syntax differs by platform)
- **cat**, **tr**, **head** - POSIX utilities

### Platform Support

- **macOS** - Primary platform (Bash 3.2+ default)
- **Linux** - Supported (Ubuntu, tested in containers)
- **Windows** - Not supported (v0.1.2)

## Troubleshooting

### Log File Location

All installation logs are written to:

```text
~/.aida/logs/install.log
```

Permissions: 600 (owner read/write only)

**View logs**:

```bash
cat ~/.aida/logs/install.log
tail -n 50 ~/.aida/logs/install.log  # Last 50 lines
```

### Common Issues

#### realpath command not found

**Error**: `Required command not found: realpath`

**Solution**:

- macOS: `brew install coreutils`
- Linux: `sudo apt-get install coreutils` (usually pre-installed)

#### Version incompatibility

**Error**: `Version incompatible: installed version too old`

**Solution**:

```bash
cd ~/.aida
git pull
./install.sh
```

#### World-writable file rejected

**Error**: `Security: file is world-writable`

**Solution**:

```bash
chmod go-w /path/to/file
```

#### Path traversal attempt blocked

**Error**: `Invalid path: contains '..' (path traversal attempt)`

**Solution**: Do not use `..` in paths. Use absolute paths or paths relative to $HOME.

### Debug Mode

Enable detailed logging by setting:

```bash
export AIDA_DEBUG=1
./install.sh
```

(Note: Debug mode implementation planned for v0.2.0)

## Changelog

### v1.0 (2025-10-06) - Initial Release

- ✅ colors.sh - Terminal color utilities
- ✅ logging.sh - Structured logging with file output
- ✅ validation.sh - Input validation and security controls
- ✅ Phase 1 security controls (input sanitization, path canonicalization, permissions)
- ✅ Bash 3.2 compatibility (macOS default)
- ✅ Semantic versioning compatibility checking

### Planned for v1.1 (v0.2.0 release)

- Phase 2 security controls (checksum validation, GPG signatures)
- platform-detect.sh utility
- Debug mode support
- Smart version mismatch handling (auto-upgrade option)

## Related Documentation

- **AIDA Framework**: <https://github.com/oakensoul/claude-personal-assistant>
- **Installation Guide**: `docs/installation.md`
- **Security Audit**: `docs/security/SECURITY_AUDIT.md`
- **Architecture**: `docs/architecture/dotfiles-integration.md`

## Support

For issues, questions, or contributions:

- **Issues**: <https://github.com/oakensoul/claude-personal-assistant/issues>
- **Discussions**: <https://github.com/oakensoul/claude-personal-assistant/discussions>

## License

AGPL-3.0 - See LICENSE file in repository root

---

**Note**: This library is foundational infrastructure for the AIDA ecosystem. Changes must maintain backward compatibility within minor versions.
