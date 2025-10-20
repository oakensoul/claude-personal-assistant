---
title: "Shell Systems UX Analysis - Modular Installer Refactoring"
issue: 53
analyst: "shell-systems-ux-designer"
date: "2025-10-18"
status: "draft"
---

# Shell Systems UX Analysis - Modular Installer Refactoring

**Issue #53**: Modular installer with deprecation support and .aida namespace installation

**Analysis Date**: 2025-10-18

## 1. CLI UX Concerns

### Flag Naming and Consistency

**Current flags:**

- `./install.sh --dev` (existing, well-named)
- `./install.sh --help` (existing, standard)

**Proposed flags:**

- `./install.sh --with-deprecated` (NEW)

**Assessment:**

- ✅ `--dev` - Clear, standard dev mode convention
- ✅ `--help` - Universal standard
- ⚠️ `--with-deprecated` - Verbose but explicit (good for clarity)
- ✅ Flags can be combined: `./install.sh --dev --with-deprecated`

**Alternative considerations:**

- `--include-deprecated` - More grammatically correct
- `--legacy` - Shorter but less clear about what's included
- `--all` - Too vague, unclear what "all" means

**Recommendation**: Keep `--with-deprecated` - explicitness wins over brevity for infrequent operations.

### Error Messages and Guidance

**Current state (install.sh):**

- ✅ Uses logging.sh with symbols (✓, ✗, ⚠, ℹ)
- ✅ Color-aware (respects NO_COLOR)
- ✅ Logs to ~/.aida/logs/install.log
- ⚠️ Generic errors lack recovery guidance

**Examples needing improvement:**

```bash
# Current (line 52):
print_message "error" "VERSION file not found at $VERSION_FILE"
exit 1

# Better:
print_message "error" "VERSION file not found"
echo "Expected location: $VERSION_FILE"
echo ""
echo "This indicates a corrupted installation or incomplete git clone."
echo "To fix:"
echo "  1. Re-clone repository: git clone <url>"
echo "  2. Or download release: https://github.com/..."
echo ""
echo "For help: https://github.com/.../issues"
exit 1
```

**Recommendations:**

1. **Add recovery guidance** - Every error should suggest next steps
2. **Reference docs/logs** - Point users to troubleshooting resources
3. **Contextual help** - Explain why error occurred, not just what failed
4. **Use print_error_with_detail()** - Already exists in logging.sh but underutilized

### Progress Feedback During Installation

**Current state:**

- ✅ Step-by-step messages with symbols
- ✅ Backup timestamps shown
- ⚠️ No progress indication for long operations (rsync)
- ⚠️ Silent operations feel "stuck" (variable substitution)

**Missing feedback for:**

- `rsync` copying framework files (line 304-308)
- Variable substitution in templates (line 407-413)
- Permission setting with find (line 334-341)

**Recommendations:**

1. **Add spinner for indefinite operations:**

   ```bash
   show_spinner() {
       local pid=$1
       local delay=0.1
       local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
       while ps -p $pid > /dev/null; do
           local temp=${spinstr#?}
           printf " [%c]  " "$spinstr"
           spinstr=$temp${spinstr%"$temp"}
           sleep $delay
           printf "\b\b\b\b\b\b"
       done
   }

   # Usage:
   rsync ... & show_spinner $!
   ```

2. **Add counts for batch operations:**

   ```bash
   print_message "info" "Processing command templates..."
   total=$(find "${template_dir}" -name "*.md" | wc -l)
   current=0
   for template in "${template_dir}"/*.md; do
       current=$((current + 1))
       echo "  Processing ${current}/${total}: $(basename "$template")"
   done
   ```

3. **Silence verbose find commands** - Add `2>/dev/null` to reduce noise

## 2. Idempotency & Safety

### User Runs Installer Multiple Times

**Current behavior:**

- ✅ Detects existing installation (line 222-275)
- ⚠️ BACKS UP AND NUKES entire `~/.claude/` directory (line 251-258)
- ⚠️ NO WARNING about data loss before backup
- ⚠️ Silent data loss if user created custom agents/commands

**Critical UX failure:**

```bash
# Current (line 251-258):
if [[ -d "${CLAUDE_DIR}" ]]; then
    print_message "warning" "Existing Claude configuration found at ${CLAUDE_DIR}"
    backup_needed=true
    local backup_dir="${CLAUDE_DIR}.backup.${backup_timestamp}"
    print_message "info" "Creating backup: ${backup_dir}"
    mv "${CLAUDE_DIR}" "${backup_dir}"  # <-- NUKES EVERYTHING
    print_message "success" "Backup created"
fi
```

**What this destroys:**

- User's custom commands (`~/.claude/commands/my-custom/`)
- User's custom agents (`~/.claude/agents/my-agent/`)
- Claude Code settings and history
- Memory from previous sessions

**User expectation vs reality:**

| User Thinks | What Actually Happens |
|-------------|----------------------|
| "Update AIDA templates" | "Nuke everything in ~/.claude/" |
| "Safe to re-run" | "All custom work backed up (not restored)" |
| "Backup = safety" | "Backup = footnote in log file" |

### Warnings Needed Before Nuking .aida/

**Proposed new flow:**

```bash
check_existing_install() {
    # ... existing detection code ...

    if [[ -d "${CLAUDE_DIR}" ]]; then
        echo ""
        print_message "warning" "Existing Claude configuration detected"
        echo ""
        echo "Location: ${CLAUDE_DIR}"
        echo ""
        echo "⚠️  IMPORTANT: Re-running the installer will:"
        echo "  • Update AIDA templates in ~/.claude/commands/.aida/"
        echo "  • Update AIDA agents in ~/.claude/agents/.aida/"
        echo "  • Preserve your custom commands and agents outside .aida/"
        echo ""

        if [[ -d "${CLAUDE_DIR}/commands" ]] && ls "${CLAUDE_DIR}/commands" | grep -v "^\.aida" > /dev/null; then
            print_message "info" "Custom commands detected (will be preserved):"
            ls -1 "${CLAUDE_DIR}/commands" | grep -v "^\.aida" | sed 's/^/    • /'
            echo ""
        fi

        read -rp "Continue with installation? [y/N]: " confirm
        if [[ "$confirm" != "y" ]] && [[ "$confirm" != "Y" ]]; then
            print_message "info" "Installation cancelled"
            exit 0
        fi
        echo ""
    fi
}
```

**Benefits:**

- ✅ **Explicit consent** - User must confirm
- ✅ **Shows impact** - Lists what will be preserved
- ✅ **Educates** - Explains .aida/ namespace
- ✅ **Safe default** - Default is NO (protect user data)

### Communication About What Will Happen

**Current problems:**

1. No **preview** of what will be installed/updated
2. No **diff** showing what changed since last install
3. No **summary** of what was preserved vs overwritten
4. No **version comparison** (updating from X to Y)

**Recommendations:**

1. **Pre-flight summary:**

   ```bash
   echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
   echo "  Installation Plan"
   echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
   echo ""
   echo "What will be installed:"
   echo "  • AIDA framework → ~/.aida/ (symlink to repo)"
   echo "  • Command templates → ~/.claude/commands/.aida/"
   echo "  • Agent templates → ~/.claude/agents/.aida/"
   if [[ "$WITH_DEPRECATED" == true ]]; then
       echo "  • Deprecated commands → ~/.claude/commands/.aida-deprecated/"
   fi
   echo ""
   echo "What will be preserved:"
   echo "  • Your custom commands in ~/.claude/commands/"
   echo "  • Your custom agents in ~/.claude/agents/"
   echo "  • Claude Code settings and history"
   echo ""
   ```

2. **Post-install summary:**

   ```bash
   echo "Installation Summary:"
   echo "  Templates installed:   15 commands, 8 agents"
   echo "  Deprecated installed:  5 commands (via --with-deprecated)"
   echo "  User content preserved: 3 custom commands, 2 custom agents"
   echo ""
   ```

## 3. Help & Documentation

### `./install.sh --help` Output

**Current state (lines 77-109):**

- ✅ Clear structure (Usage, Options, Description, Examples)
- ✅ Shows version
- ✅ Links to documentation
- ⚠️ Missing `--with-deprecated` flag (not yet implemented)

**Proposed enhanced help:**

```text
AIDA Framework Installation Script v0.2.0

Usage: install.sh [OPTIONS]

Options:
    --dev                   Install in development mode (symlinks for live editing)
    --with-deprecated       Include deprecated commands for backward compatibility
    --help                  Display this help message and exit

Description:
    Installs the AIDA (Agentic Intelligence Digital Assistant) framework.

    Normal installation creates:
        ~/.aida/                    Symlink to framework repository
        ~/.claude/commands/.aida/   AIDA command templates
        ~/.claude/agents/.aida/     AIDA agent definitions
        ~/CLAUDE.md                 Main entry point file

    Your custom commands, agents, and Claude Code settings are always preserved.

Installation Modes:
    Normal mode (default)
        • Copies templates with variable substitution
        • Templates are stable, not live-editable
        • Update requires re-running ./install.sh

    Development mode (--dev)
        • Symlinks templates for live editing
        • Changes to templates immediately active
        • Update via git pull (no reinstall needed)

    With deprecated (--with-deprecated)
        • Includes deprecated commands for backward compatibility
        • Shows migration warnings when deprecated commands used
        • Recommended during transition periods only

Examples:
    install.sh                           # Normal installation
    install.sh --dev                     # Development mode
    install.sh --with-deprecated         # Include deprecated commands
    install.sh --dev --with-deprecated   # Dev mode + deprecated

Re-running the installer:
    Safe to re-run. Your custom content outside ~/.claude/*/.aida/ is preserved.
    AIDA-managed templates in .aida/ folders are replaced with latest versions.

For more information:
    https://github.com/oakensoul/claude-personal-assistant
    Documentation: ~/.aida/docs/
    Logs: ~/.aida/logs/install.log
```

**Key improvements:**

- ✅ Explains what happens on re-run (idempotency safety)
- ✅ Clarifies normal vs dev mode tradeoffs
- ✅ Shows flag combinations
- ✅ Documents preservation guarantees
- ✅ Points to logs for troubleshooting

### In-Terminal Guidance

**Opportunities for better guidance:**

1. **Assistant name prompt** (line 122-167):

   ```bash
   # Current:
   echo "The assistant name will be used throughout the AIDA framework."
   echo "Requirements: lowercase, no spaces, 3-20 characters"

   # Enhanced:
   echo "The assistant name will be used throughout the AIDA framework."
   echo ""
   echo "Requirements:"
   echo "  • 3-20 characters"
   echo "  • Lowercase letters, numbers, hyphens only"
   echo "  • Must start with a letter"
   echo ""
   echo "Examples: jarvis, alfred, friday, my-assistant"
   echo ""
   ```

2. **Personality selection** (line 180-209):

   ```bash
   # Current: Brief one-liners
   echo "  1) jarvis         - Snarky British AI (helpful but judgmental)"

   # Enhanced with preview:
   echo "Available personalities:"
   echo ""
   echo "  1) JARVIS         - Snarky British AI"
   echo "     Helpful but judgmental. Will point out inefficiencies with dry wit."
   echo ""
   echo "  2) Alfred         - Dignified butler"
   echo "     Professional and respectful. Quietly efficient, never intrusive."
   echo ""
   # ... etc for all options
   ```

3. **Post-install next steps** (line 543-547):

   ```bash
   # Current: Generic bullet points
   echo "Next Steps:"
   echo "  1. Review your configuration in ${CLAUDE_DIR}"

   # Enhanced with specific commands:
   echo "Next Steps:"
   echo ""
   echo "  1. Try talking to your assistant:"
   echo "     Open Claude Code and say 'Hello!'"
   echo ""
   echo "  2. Explore available commands:"
   echo "     Type '/' in Claude Code to see all commands"
   echo ""
   echo "  3. View your configuration:"
   echo "     cat ~/CLAUDE.md"
   echo "     ls ~/.claude/commands/.aida/"
   echo ""
   echo "  4. Join the community:"
   echo "     https://github.com/.../discussions"
   echo ""
   ```

### Error Recovery Instructions

**Pattern to adopt throughout:**

```bash
# Template for all errors:
print_message "error" "[What went wrong]"
echo ""
echo "[Why this happened - root cause]"
echo ""
echo "To fix this:"
echo "  1. [First recovery option]"
echo "  2. [Alternative approach]"
echo ""
echo "Still stuck?"
echo "  • Check logs: ~/.aida/logs/install.log"
echo "  • Documentation: ~/.aida/docs/troubleshooting.md"
echo "  • Get help: https://github.com/.../issues"
```

**Example for dependency errors:**

```bash
# Current (validation.sh handles this)
Required command not found: git

# Enhanced:
print_message "error" "Required dependencies missing"
echo ""
echo "The following commands are required but not found:"
echo "  • git"
echo "  • rsync"
echo ""
echo "To fix this:"
echo ""
echo "  Ubuntu/Debian:"
echo "    sudo apt update && sudo apt install -y git rsync"
echo ""
echo "  macOS (Homebrew):"
echo "    brew install git rsync"
echo ""
echo "  macOS (without Homebrew):"
echo "    Install Xcode Command Line Tools:"
echo "    xcode-select --install"
echo ""
echo "After installing dependencies, re-run:"
echo "  ./install.sh"
```

## 4. Testing Workflow UX

### Make Targets: Intuitive Naming

**Proposed Makefile targets** (from issue notes):

```makefile
make test-install                # Test normal mode
make test-install-dev            # Test dev mode
make test-install-deprecated     # Test --with-deprecated
make test-upgrade                # Test over existing install
make test-user-content           # Verify preservation
make test-all                    # Full suite
make test-windows                # Windows-specific
```

**Analysis:**

- ✅ Consistent `test-` prefix
- ✅ Descriptive suffixes
- ⚠️ `test-install-deprecated` is long but clear
- ⚠️ No `make clean` or `make help` mentioned

**Recommendations:**

1. **Add standard targets:**

   ```makefile
   make help                    # Show all targets with descriptions
   make clean                   # Clean up Docker containers/images
   make test                    # Alias for test-all (convention)
   ```

2. **Shorter aliases for common operations:**

   ```makefile
   make test                    # Same as test-all
   make ti                      # Alias for test-install (quick typing)
   make td                      # Alias for test-install-dev
   ```

3. **Add `make help` as default target:**

   ```makefile
   .DEFAULT_GOAL := help

   help:  ## Show this help
       @echo "AIDA Framework Testing"
       @echo ""
       @echo "Available targets:"
       @echo ""
       @grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
           awk 'BEGIN {FS = ":.*?## "}; {printf "  %-25s %s\n", $$1, $$2}'
   ```

### Output Verbosity Levels

**Current state** (test-install.sh):

- ✅ Has `--verbose` flag
- ✅ Suppresses some output by default
- ⚠️ Binary choice (verbose or not)
- ⚠️ No `--quiet` mode for CI

**Recommendations:**

1. **Three verbosity levels:**

   ```bash
   # Quiet mode (CI-friendly)
   ./test-install.sh --quiet
   # Only shows: PASS/FAIL summary, no progress

   # Normal mode (default)
   ./test-install.sh
   # Shows: Test headers, pass/fail per test, summary

   # Verbose mode (debugging)
   ./test-install.sh --verbose
   # Shows: All output, docker logs, detailed errors
   ```

2. **Progress indicators for normal mode:**

   ```bash
   # Normal mode output:
   Testing environment: ubuntu-22
   [1/4] Help flag test............... ✓ PASS
   [2/4] Dependency validation........ - SKIP (expected)
   [3/4] Normal installation.......... ✓ PASS
   [4/4] Dev mode installation........ ✓ PASS
   ```

3. **Summary table:**

   ```bash
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
     Test Results Summary
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   Environment          Pass    Fail    Skip    Total
   ────────────────────────────────────────────────────────────
   ubuntu-22              3       0       1        4
   ubuntu-20              3       0       1        4
   debian-12              3       0       1        4
   ubuntu-minimal         1       0       3        4
   ────────────────────────────────────────────────────────────
   TOTAL                 10       0       6       16

   ✓ All tests passed!
   ```

### CI/CD Feedback in PRs

**Current state:**

- ⚠️ No CI/CD workflow mentioned in current codebase
- Issue #53 proposes `.github/workflows/test-installer.yml`

**Recommendations for PR comments:**

1. **Compact summary in PR comment:**

   ```markdown
   ## 🤖 Installer Test Results

   | Platform | Normal | Dev | Deprecated | Status |
   |----------|--------|-----|------------|--------|
   | Ubuntu 22.04 | ✅ | ✅ | ✅ | **PASS** |
   | Ubuntu 20.04 | ✅ | ✅ | ✅ | **PASS** |
   | Debian 12 | ✅ | ✅ | ✅ | **PASS** |
   | macOS | ✅ | ✅ | ✅ | **PASS** |
   | Windows WSL | ✅ | ✅ | ⚠️ | **PARTIAL** |

   **Summary**: 19/20 tests passed

   <details>
   <summary>View detailed logs</summary>

   [Full test output](link-to-artifact)
   </details>
   ```

2. **Failure details:**

   ```markdown
   ## ❌ Installer Test Failures

   **Windows WSL - Deprecated installation failed**

   Error: Symlink creation not supported on this filesystem
   Location: lib/installer-common/templates.sh:145

   Logs: [View artifact](link)
   ```

3. **Annotations on files:**

   Use GitHub Actions annotations to highlight specific lines:

   ```bash
   echo "::error file=install.sh,line=294::Symlink creation failed on Windows"
   ```

## 5. Cross-Platform Considerations

### Windows PowerShell + Bash Users

**Challenges:**

1. **Path separators** - Windows uses `\`, Unix uses `/`
2. **Line endings** - CRLF vs LF
3. **Symlinks** - Require admin on Windows or Developer Mode
4. **Case sensitivity** - Windows filesystems case-insensitive
5. **Home directory** - `$HOME` vs `%USERPROFILE%`

**Recommendations:**

1. **Detect Windows environment:**

   ```bash
   is_windows() {
       [[ "$(uname -s)" == MINGW* ]] || \
       [[ "$(uname -s)" == MSYS* ]] || \
       [[ -n "${WSL_DISTRO_NAME:-}" ]]
   }

   is_wsl() {
       [[ -n "${WSL_DISTRO_NAME:-}" ]]
   }
   ```

2. **Symlink handling:**

   ```bash
   create_link() {
       local src="$1"
       local dest="$2"

       if is_windows && ! is_wsl; then
           # Check if symlinks supported
           if ! cmd.exe /c mklink /? > /dev/null 2>&1; then
               print_message "warning" "Symlinks not supported on this Windows system"
               print_message "info" "Falling back to copy mode"
               cp -r "$src" "$dest"
               return
           fi
       fi

       ln -s "$src" "$dest"
   }
   ```

3. **Path normalization:**

   ```bash
   normalize_path() {
       local path="$1"
       # Convert to Unix-style path
       echo "$path" | sed 's|\\|/|g'
   }
   ```

4. **User guidance for Windows:**

   ```bash
   if is_windows && ! is_wsl; then
       echo ""
       print_message "info" "Windows detected"
       echo ""
       echo "For best experience on Windows:"
       echo "  • Enable Developer Mode (for symlink support)"
       echo "  • Use WSL2 (Windows Subsystem for Linux)"
       echo "  • Or run in Git Bash with admin privileges"
       echo ""
   fi
   ```

### Different Shell Behaviors

**Bash version differences:**

| Feature | Bash 3.2 (macOS default) | Bash 4.0+ (Linux) | Impact |
|---------|--------------------------|-------------------|--------|
| `[[` conditionals | ✅ | ✅ | Safe |
| Arrays | ✅ | ✅ | Safe |
| Associative arrays | ❌ | ✅ | **Avoid** |
| `${var,,}` lowercase | ❌ | ✅ | **Avoid** |
| `readarray` | ❌ | ✅ | **Avoid** |

**Current code uses Bash 3.2 compatible syntax** - ✅ Good!

Example from install.sh (lines 149-151):

```bash
# Bash 3.2 compatible (GOOD):
name_lower=$(echo "$name" | tr '[:upper:]' '[:lower:]')

# Bash 4.0+ only (would break on macOS):
# name_lower="${name,,}"
```

**Recommendations:**

1. **Document Bash version requirement:**

   ```bash
   # In install.sh header:
   # Requirements:
   #   - Bash 3.2+ (macOS compatible)
   ```

2. **Check Bash version at runtime:**

   ```bash
   check_bash_version() {
       local major="${BASH_VERSINFO[0]}"
       local minor="${BASH_VERSINFO[1]}"

       if [[ "$major" -lt 3 ]] || [[ "$major" -eq 3 && "$minor" -lt 2 ]]; then
           print_message "error" "Bash 3.2 or higher required (found $BASH_VERSION)"
           echo "On macOS, the default bash should work (/bin/bash)"
           exit 1
       fi
   }
   ```

3. **Avoid shell-specific features:**

   ```bash
   # DON'T:
   local -A assoc_array  # Bash 4+ only
   readarray lines < file  # Bash 4+ only

   # DO:
   while IFS= read -r line; do
       # Process line
   done < file
   ```

### Path Handling Differences

**Issues to handle:**

1. **Home directory variations:**

   ```bash
   # Unix/macOS: /home/user or /Users/user
   # Windows Git Bash: /c/Users/user
   # WSL: /home/user (but can access Windows at /mnt/c/)
   ```

2. **Absolute path detection:**

   ```bash
   is_absolute_path() {
       local path="$1"
       # Unix/macOS starts with /
       # Windows can start with C:/ or /c/
       [[ "$path" =~ ^/ ]] || [[ "$path" =~ ^[A-Za-z]:/ ]]
   }
   ```

3. **Path expansion in variables:**

   ```bash
   # PROBLEM: Tilde doesn't expand in quotes
   path="~/Documents"  # Stays as literal ~

   # SOLUTION: Use $HOME
   path="${HOME}/Documents"  # Expands correctly
   ```

**Current code handles this well** - uses `${HOME}` throughout (line 57-59).

## 6. Questions & Recommendations

### UX Improvements

**High Priority:**

1. ✅ **Add confirmation prompt** before re-running installer over existing installation
2. ✅ **Show pre-flight plan** of what will be installed/preserved
3. ✅ **Enhance error messages** with recovery instructions
4. ✅ **Add progress indicators** for long operations (rsync, template processing)
5. ✅ **Improve --help output** to explain idempotency and preservation guarantees

**Medium Priority:**

6. ✅ **Add `make help`** as default Makefile target
7. ✅ **Add `--quiet` mode** for CI/CD environments
8. ✅ **Post-install summary** showing counts (templates installed, preserved, etc.)
9. ✅ **Enhanced personality descriptions** with multi-line previews
10. ✅ **Better assistant name guidance** with examples

**Low Priority:**

11. ⚠️ **Installation wizard mode** - Interactive walkthrough for first-time users
12. ⚠️ **Dry-run mode** - `./install.sh --dry-run` to preview without changes
13. ⚠️ **Rollback capability** - `./install.sh --rollback` to undo last installation
14. ⚠️ **Version update notifications** - Check for newer versions before install

### Common Pitfalls to Avoid

#### 1. Silent Data Loss

- ❌ Current: Backs up `~/.claude/` without warning
- ✅ Fix: Explicit confirmation + show what will be preserved

#### 2. Unclear Idempotency

- ❌ Current: No guidance on what happens when re-run
- ✅ Fix: Document in --help and show preview before proceeding

#### 3. Windows Compatibility Assumed

- ❌ Risk: Symlinks fail silently on some Windows configs
- ✅ Fix: Detect Windows, check symlink support, fallback to copy

#### 4. Dev Mode Surprise

- ❌ Risk: User doesn't understand templates are live-editable
- ✅ Fix: Clear warning when entering dev mode, explain tradeoffs

#### 5. Deprecated Flag Confusion

- ❌ Risk: Users don't know when to use `--with-deprecated`
- ✅ Fix: Help text explains transition period usage

#### 6. No Escape Hatch

- ❌ Risk: User runs installer, realizes mistake, no way to abort safely
- ✅ Fix: Confirmation prompts with clear cancellation option

#### 7. Log File Overwhelm

- ❌ Risk: Logs contain user paths (privacy issue)
- ✅ Fix: Already handled! logging.sh scrubs paths (line 62)

### User Education Needed

**Topics for documentation:**

1. **Installation modes** - When to use normal vs dev vs deprecated
2. **AIDA namespace** - What `.aida/` folders mean and why not to modify
3. **Idempotency** - Why re-running is safe and what gets preserved
4. **Update workflow** - How to update AIDA (git pull + reinstall vs dev mode)
5. **Troubleshooting** - Common errors and how to fix them
6. **Multi-repo ecosystem** - How AIDA, dotfiles, and dotfiles-private interact

**Recommended documentation structure:**

```text
docs/
├── installation/
│   ├── quick-start.md           # 5-minute installation guide
│   ├── installation-modes.md    # Normal vs dev vs deprecated
│   ├── updating.md              # How to update AIDA
│   └── uninstalling.md          # Clean removal
├── troubleshooting/
│   ├── common-errors.md         # Error messages and fixes
│   ├── windows-setup.md         # Windows-specific guidance
│   └── logs.md                  # How to read install.log
└── reference/
    ├── directory-structure.md   # What goes where
    └── cli-reference.md         # All flags and options
```

**In-terminal education opportunities:**

1. **First-time install** - Show welcome message explaining AIDA
2. **Re-run detection** - Explain preservation and upgrade process
3. **Dev mode** - Warn about live template editing
4. **Post-install** - Show "What's next?" with specific commands to try

### Critical UX Decisions

#### Decision 1: Confirmation prompts

- **Question**: Always prompt, or add `--yes` flag to skip?
- **Recommendation**: Prompt by default, add `--yes` for CI/CD automation
- **Rationale**: Safety first, but enable scripted installs

#### Decision 2: Backup restoration

- **Question**: Should installer offer to restore from backup on error?
- **Recommendation**: No automatic restoration, but document manual steps
- **Rationale**: Automatic restoration is complex and error-prone

#### Decision 3: Deprecated template installation

- **Question**: Install deprecated by default or opt-in with flag?
- **Recommendation**: Opt-in with `--with-deprecated` (already planned)
- **Rationale**: Clean installs should not include deprecated cruft

#### Decision 4: Dev mode symlink behavior

- **Question**: Should dev mode symlink entire directory or individual templates?
- **Recommendation**: Symlink individual template folders (`.aida/` level)
- **Rationale**: Preserves user content safety, enables live editing

#### Decision 5: Windows support level

- **Question**: First-class Windows support or best-effort WSL?
- **Recommendation**: Document WSL2 as recommended, Git Bash as fallback
- **Rationale**: WSL2 provides full Unix compatibility, Git Bash has limitations

## Summary

### Strengths of Current Design

- ✅ Strong foundation with modular utilities (colors, logging, validation)
- ✅ Bash 3.2 compatibility for macOS
- ✅ Color-aware output with NO_COLOR support
- ✅ Logging to file with path scrubbing
- ✅ Dev mode concept for live editing
- ✅ Clear separation of concerns (utilities in lib/)

### Critical Issues to Address

1. 🚨 **Data loss risk** - Nuking `~/.claude/` without clear warning
2. 🚨 **No confirmation** - Silent overwrite of existing installations
3. 🚨 **Unclear idempotency** - Users don't know what happens on re-run
4. ⚠️ **Missing progress feedback** - Long operations feel stuck
5. ⚠️ **Error messages lack recovery guidance** - Users get stuck

### Top Recommendations

**Must Have (for v0.2):**

1. Add confirmation prompt before overwriting existing installation
2. Show pre-flight installation plan
3. Enhance error messages with recovery instructions
4. Update --help output to explain preservation guarantees
5. Add progress indicators for long operations

**Should Have (for v0.3):**

6. Implement `--quiet` mode for CI/CD
7. Add `make help` target
8. Post-install summary with counts
9. Windows compatibility warnings and fallbacks

**Nice to Have (for v1.0):**

10. Dry-run mode
11. Interactive wizard for first-time users
12. Version update notifications

---

**Analysis complete.** This refactoring significantly improves installer modularity and template management, but UX must be enhanced to prevent user confusion and data loss. The `.aida/` namespace approach is excellent for safety - focus education on this contract.
