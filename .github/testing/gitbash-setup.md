---
title: "Git Bash Testing Guide"
description: "Testing AIDA framework installation on Git Bash for Windows"
category: "testing"
tags: ["git-bash", "windows", "mingw", "testing", "qa"]
last_updated: "2025-10-05"
status: "published"
audience: "developers"
---

# Git Bash Testing Guide

This guide covers testing the AIDA framework installation on Git Bash (MINGW64) for Windows.

## Overview

Git Bash provides a Bash emulation environment on Windows using MINGW64. It has **limitations** compared to WSL or native Linux, so testing is important to identify compatibility issues.

## Prerequisites

### Required Software

1. **Git for Windows** (includes Git Bash)
   - Download: <https://git-scm.com/download/win>
   - Minimum version: 2.30+
   - Installation: Use recommended settings

2. **Windows Terminal** (Optional but recommended)
   - Download from Microsoft Store
   - Provides better terminal experience

### Installation

Download and install Git for Windows:

```text
https://git-scm.com/download/win
```

#### Important Installation Options

- ✅ Select "Git Bash Here" context menu option
- ✅ Select "Use Git from Git Bash only" or "Use Git from the command line"
- ✅ Choose "Checkout as-is, commit Unix-style line endings"

## Launching Git Bash

### Method 1: Start Menu

```text
Start Menu → Git → Git Bash
```

### Method 2: Context Menu

Right-click in any folder → "Git Bash Here"

### Method 3: Windows Terminal

```text
Windows Terminal → New Tab → Git Bash
```

## Git Bash Environment

### Understanding MINGW Paths

Git Bash uses MINGW path format:

| Windows Path | Git Bash Path |
|--------------|---------------|
| `C:\Users\Username` | `/c/Users/Username` |
| `D:\Projects` | `/d/Projects` |
| `C:\Program Files` | `/c/Program Files` |

#### Home Directory

```bash
echo $HOME
# Output: /c/Users/Username

cd ~
pwd
# Output: /c/Users/Username
```

### Available Commands

Git Bash includes many Unix commands:

```bash
# Check available commands
bash --version     # Bash version
git --version      # Git version
ls --version       # Coreutils version

# Commonly available:
mkdir, chmod, cat, grep, find, sed, awk, etc.
```

### Check rsync Availability

```bash
# rsync may not be included by default
rsync --version

# If missing, install via:
# 1. Git for Windows SDK, OR
# 2. Download rsync binary for Windows
```

## Installation Testing

### Verify Prerequisites

Before testing, verify all required tools:

```bash
# Check Bash version (need >= 4.0)
bash --version

# Check Git
git --version

# Check rsync (IMPORTANT - may be missing)
rsync --version

# If rsync is missing, see "Installing rsync" section below
```

### Installing rsync (If Missing)

Git Bash doesn't include rsync by default. Options:

#### Option 1: Git for Windows SDK

```bash
# Download and run Git for Windows SDK installer
# https://github.com/git-for-windows/build-extra/releases
```

#### Option 2: Manual rsync Binary

1. Download rsync for Windows: <https://github.com/cwRsync/cwRsync>
2. Extract and copy `rsync.exe` to Git Bash bin directory:

   ```text
   C:\Program Files\Git\usr\bin\
   ```

#### Option 3: Use Cygwin rsync

Or note in documentation that Git Bash users should use WSL instead.

## Test Scenarios

### Test 1: Clone Repository

```bash
# Navigate to desired location
cd ~
# or
cd /c/Users/YourUsername/Developer

# Clone repository
git clone https://github.com/oakensoul/claude-personal-assistant.git
cd claude-personal-assistant

# Verify files
ls -la
```

### Test 2: Help Flag

```bash
./install.sh --help
```

#### Expected Issues

- ✅ Should work (basic script execution)

#### Possible Issues

- ❌ Line ending issues (CRLF vs LF)
- ❌ Path interpretation issues

### Test 3: Dependency Check

```bash
./install.sh
```

#### Expected behavior

- Script validates bash version
- Checks for required commands
- If rsync is missing, should fail with clear error

#### Verification

```bash
# Manually check dependencies
command -v git && echo "git: OK" || echo "git: MISSING"
command -v rsync && echo "rsync: OK" || echo "rsync: MISSING"
command -v mkdir && echo "mkdir: OK" || echo "mkdir: MISSING"
```

### Test 4: Full Installation (if rsync available)

```bash
./install.sh
```

#### Expected behavior

- Prompts for assistant name
- Prompts for personality
- Creates directories in `$HOME` (`/c/Users/Username/`)
- Sets permissions (may not work exactly like Linux)
- Shows success message

#### Verification

```bash
# Check installation
ls -la ~/.aida
ls -la ~/.claude
cat ~/CLAUDE.md

# Check permissions (limited in Git Bash)
stat ~/.aida
```

### Test 5: Development Mode

```bash
./install.sh --dev
```

#### Expected Issues

- ⚠️ Symlinks may not work properly on Windows
- ⚠️ NTFS symlinks require admin privileges
- ⚠️ May fall back to copying instead of symlinking

#### Verification

```bash
# Check if symlink was created
ls -la ~/.aida

# On Windows, symlinks show differently
# May appear as regular directory if symlink creation failed
```

### Test 6: Re-installation

```bash
# First installation
./install.sh
# (complete installation)

# Second installation
./install.sh
# (should create backups)
```

#### Verification

```bash
# Check for backups
ls -la ~ | grep backup
```

## Git Bash Limitations

### 1. Symlinks

**Issue:** Windows symlinks require administrator privileges

**Solutions:**

- Enable Developer Mode in Windows 10/11
- Run Git Bash as Administrator
- Or, install script could detect and copy instead

**Enable Developer Mode:**

```text
Settings → Update & Security → For Developers → Developer Mode: ON
```

### 2. File Permissions

**Issue:** NTFS permissions differ from Unix permissions

**Impact:**

- `chmod` may not work as expected
- Permission checks may behave differently

**Testing:**

```bash
# Test chmod
mkdir test_dir
chmod 755 test_dir
stat test_dir
```

### 3. Path Separators

**Issue:** Mixed path separators (Windows `\` vs Unix `/`)

**Impact:**

- Most Git Bash commands handle this
- But some edge cases may fail

### 4. rsync Availability

**Issue:** rsync not included by default

**Impact:**

- Installation script will fail dependency check
- Users must install rsync separately

### 5. Line Endings

**Issue:** Git may convert LF to CRLF on checkout

**Solution:**

```bash
# Check line endings
cat -A install.sh | head -5
# LF: shows $
# CRLF: shows ^M$

# Fix if needed
dos2unix install.sh
# or
sed -i 's/\r$//' install.sh

# Or configure git
git config --global core.autocrlf input
```

## Common Issues and Solutions

### Issue: "bash: ./install.sh: Permission denied"

```bash
# Make executable
chmod +x install.sh

# Run directly
bash install.sh
```

### Issue: "bash: rsync: command not found"

```bash
# Install rsync (see "Installing rsync" section above)
# Or use WSL instead for full Linux compatibility
```

### Issue: "cannot create symbolic link: Operation not permitted"

```bash
# Option 1: Enable Developer Mode (Windows 10/11)
# Settings → For Developers → Developer Mode

# Option 2: Run as Administrator
# Right-click Git Bash → "Run as Administrator"

# Option 3: Script could detect and copy instead of symlink
```

### Issue: Line ending errors

```bash
# Convert to Unix line endings
dos2unix install.sh

# Or manually
sed -i 's/\r$//' install.sh

# Configure git
git config core.autocrlf input
```

### Issue: Path issues with spaces

```bash
# Quote paths
cd "/c/Program Files/Git"

# Use tab completion
cd /c/Prog[TAB]
```

## Testing Checklist

- [ ] Git Bash installed (Git for Windows)
- [ ] Bash version >= 4.0
- [ ] git command available
- [ ] rsync command available (or documented as missing)
- [ ] Repository cloned successfully
- [ ] `./install.sh --help` works
- [ ] Line endings are LF (not CRLF)
- [ ] Dependency validation works
- [ ] Full installation completes (if rsync available)
- [ ] Dev mode tested (symlink or copy fallback)
- [ ] Backup functionality works
- [ ] Permissions set (or documented as limited)
- [ ] Documentation updated with Git Bash limitations

## Recommendations for Git Bash Users

Based on testing, document recommendations:

### ✅ Recommended: Use WSL

For best experience on Windows:

```text
Install WSL2 → Ubuntu 22.04 → Follow WSL testing guide
```

### ⚠️ Limited Support: Git Bash

Git Bash is supported with limitations:

- ✅ Basic installation works
- ⚠️ rsync must be installed separately
- ⚠️ Symlinks require Developer Mode or Admin
- ⚠️ File permissions may not work exactly like Linux

### Documentation Updates

Add to installation guide:

```markdown
## Windows Users

**Recommended:** Use WSL2 for full Linux compatibility

**Git Bash:** Supported with limitations:
- Install rsync separately
- Enable Developer Mode for symlinks
- Some permission features may not work
```

## Automated Testing Script

Create Git Bash specific test script:

```bash
#!/usr/bin/env bash
# .github/testing/test-gitbash.sh

# Check Git Bash environment
if [[ ! "$OSTYPE" =~ "msys" ]] && [[ ! "$OSTYPE" =~ "mingw" ]]; then
    echo "This script is for Git Bash on Windows only"
    exit 1
fi

# Run tests with Git Bash considerations
# ... test logic here ...
```

## Performance Considerations

Git Bash performance on Windows:

- Slower than WSL or native Linux
- File I/O operations are slower
- Large repositories may take longer to clone

## Related Tools

### Alternative Windows Bash Environments

1. **WSL2** (Recommended)
   - Full Linux compatibility
   - Better performance
   - Native rsync, symlinks, permissions

2. **Cygwin**
   - More complete Unix environment
   - Includes rsync
   - Better POSIX compatibility

3. **MSYS2**
   - Similar to Git Bash
   - More packages available

## Next Steps

1. Test installation on fresh Git Bash
2. Document all limitations found
3. Update install.sh with Git Bash detection/warnings
4. Create fallback for missing features (rsync, symlinks)
5. Update README with Windows-specific instructions

## Related Documentation

- [WSL Testing Guide](wsl-setup.md)
- [Docker Testing Guide](../docker/README.md)
- [Test Scenarios](test-scenarios.md)
- [Git for Windows Documentation](https://git-scm.com/doc)
