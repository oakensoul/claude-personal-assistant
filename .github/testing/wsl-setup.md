---
title: "WSL Testing Guide"
description: "Testing AIDA framework installation on Windows Subsystem for Linux"
category: "testing"
tags: ["wsl", "windows", "testing", "qa"]
last_updated: "2025-10-05"
status: "published"
audience: "developers"
---

# WSL Testing Guide

This guide covers testing the AIDA framework installation on Windows Subsystem for Linux (WSL).

## Prerequisites

### Windows Requirements

- Windows 10 version 2004+ (Build 19041+) or Windows 11
- WSL2 installed and configured
- Windows Terminal (recommended)

### Installing WSL2

If WSL is not already installed:

```powershell
# Run in PowerShell as Administrator
wsl --install

# Or install specific distribution
wsl --install -d Ubuntu-22.04
```

For existing WSL1, upgrade to WSL2:

```powershell
wsl --set-default-version 2
wsl --set-version Ubuntu-22.04 2
```

## WSL Distributions for Testing

### Ubuntu on WSL

#### Ubuntu 22.04 LTS (Recommended)

```powershell
wsl --install -d Ubuntu-22.04
```

#### Ubuntu 20.04 LTS

```powershell
wsl --install -d Ubuntu-20.04
```

### Debian on WSL

```powershell
wsl --install -d Debian
```

### List Available Distributions

```powershell
wsl --list --online
```

## Testing Setup

### 1. Launch WSL

```powershell
# Start default distribution
wsl

# Or start specific distribution
wsl -d Ubuntu-22.04
```

### 2. Update Package Lists

```bash
sudo apt update
sudo apt upgrade -y
```

### 3. Install Dependencies

The AIDA installer checks for these dependencies:

```bash
# Install all required dependencies
sudo apt install -y git rsync

# Verify installations
git --version
rsync --version
bash --version  # Should be >= 4.0
```

### 4. Clone Repository

```bash
# Clone to WSL filesystem (recommended for performance)
cd ~
git clone https://github.com/oakensoul/claude-personal-assistant.git
cd claude-personal-assistant

# Or clone to Windows filesystem (accessible from both)
cd /mnt/c/Users/YourUsername/Developer
git clone https://github.com/oakensoul/claude-personal-assistant.git
cd claude-personal-assistant
```

**Note**: For best performance, keep files in the WSL filesystem (`~/`) rather than the Windows filesystem (`/mnt/c/`).

## Test Scenarios

### Test 1: Fresh Installation

```bash
cd ~/claude-personal-assistant
./install.sh
```

#### Expected behavior

- Prompts for assistant name (validates input)
- Prompts for personality selection
- Creates `~/.aida/` directory
- Creates `~/.claude/` directory structure
- Creates `~/CLAUDE.md`
- Sets proper permissions
- Shows success message

#### Verification

```bash
# Check directories
ls -la ~/.aida
ls -la ~/.claude
ls -la ~/CLAUDE.md

# Check permissions
stat -c '%a %n' ~/.aida
stat -c '%a %n' ~/.claude

# View generated CLAUDE.md
cat ~/CLAUDE.md
```

### Test 2: Development Mode

```bash
cd ~/claude-personal-assistant
./install.sh --dev
```

#### Expected behavior

- Same prompts as normal installation
- Creates `~/.aida/` as a **symlink** to repository
- Creates `~/.claude/` as a normal directory (copied)
- Shows "Development mode is active" warning

#### Verification

```bash
# Verify symlink
ls -la ~/.aida
readlink ~/.aida  # Should show repository path

# Verify real directory
ls -la ~/.claude
readlink ~/.claude  # Should show nothing (not a symlink)
```

### Test 3: Re-installation (Backup Test)

```bash
cd ~/claude-personal-assistant

# First installation
./install.sh
# (complete installation)

# Second installation
./install.sh
# (should create backups)
```

#### Expected behavior

- Detects existing installation
- Creates timestamped backups:
  - `~/.aida.backup.YYYYMMDD_HHMMSS`
  - `~/.claude.backup.YYYYMMDD_HHMMSS`
  - `~/CLAUDE.md.backup.YYYYMMDD_HHMMSS`
- Proceeds with new installation

#### Verification

```bash
# Check for backups
ls -la ~/ | grep backup
```

### Test 4: Help Flag

```bash
./install.sh --help
```

#### Expected behavior

- Displays comprehensive help documentation
- Shows usage examples
- Exits without prompting

### Test 5: Invalid Inputs

Test input validation:

```bash
./install.sh

# Try invalid names:
# - "my assistant" (has spaces)
# - "ab" (too short)
# - "MyAssistant" (uppercase)
# - "assistant-name-that-is-way-too-long" (>20 chars)

# Verify error messages are clear and helpful
```

## WSL-Specific Considerations

### File Permissions

WSL handles permissions differently than native Linux:

```bash
# Check umask
umask

# Verify file permissions are set correctly
find ~/.aida -type f -exec stat -c '%a %n' {} \; | head
find ~/.claude -type f -exec stat -c '%a %n' {} \; | head
```

Expected:

- Directories: `755`
- Files: `644`

### Symlinks

WSL2 fully supports symlinks:

```bash
# Test symlink functionality in dev mode
./install.sh --dev

# Verify symlink works
ls -la ~/.aida
cd ~/.aida
ls  # Should show repository contents
```

### Line Endings

Git may convert line endings (CRLF ↔ LF). Ensure install.sh uses LF:

```bash
# Check line endings
file install.sh  # Should show "Unix" or "LF"

# If CRLF, convert to LF
dos2unix install.sh

# Or configure git
git config core.autocrlf input
```

### Path Considerations

WSL provides access to Windows filesystem:

```bash
# Windows C: drive
/mnt/c/

# Windows user directory
/mnt/c/Users/YourUsername/

# WSL home directory (recommended)
~/
```

## Common Issues and Solutions

### Issue: "git: command not found"

```bash
sudo apt update
sudo apt install -y git
```

### Issue: "rsync: command not found"

```bash
sudo apt install -y rsync
```

### Issue: "Permission denied" when creating directories

```bash
# Check home directory permissions
ls -la ~/

# Fix if needed
chmod 755 ~/
```

### Issue: Line ending errors

```bash
# Convert script to Unix line endings
dos2unix install.sh

# Or use sed
sed -i 's/\r$//' install.sh
```

### Issue: Slow performance

If repository is on Windows filesystem (`/mnt/c/`):

```bash
# Move to WSL filesystem for better performance
mv /mnt/c/Users/YourUsername/claude-personal-assistant ~/
cd ~/claude-personal-assistant
```

## Testing Checklist

Use this checklist when testing on WSL:

- [ ] WSL2 is installed and running
- [ ] Dependencies installed (git, rsync, bash >= 4.0)
- [ ] Repository cloned to WSL filesystem
- [ ] `./install.sh --help` displays correctly
- [ ] Fresh installation completes successfully
- [ ] Dev mode installation creates symlink
- [ ] Re-installation creates backups
- [ ] Invalid input validation works
- [ ] File permissions are correct (755/644)
- [ ] Generated files have LF line endings
- [ ] `~/.aida/`, `~/.claude/`, `~/CLAUDE.md` created
- [ ] No errors in installation output

## Accessing WSL Files from Windows

### Windows Explorer

Access WSL files in Windows Explorer:

```text
\\wsl$\Ubuntu-22.04\home\username\
```

Or:

```powershell
# Open WSL home in Explorer
explorer.exe .
```

### Visual Studio Code

Open WSL project in VS Code:

```bash
# From WSL terminal
code .
```

## Multiple WSL Distributions

Test on multiple distributions:

```powershell
# List installed distributions
wsl --list -v

# Start specific distribution
wsl -d Ubuntu-22.04
wsl -d Ubuntu-20.04
wsl -d Debian

# Set default distribution
wsl --set-default Ubuntu-22.04
```

## Automated Testing on WSL

Run automated tests from PowerShell:

```powershell
# Run test script in WSL
wsl -d Ubuntu-22.04 bash -c "cd ~/claude-personal-assistant && ./.github/testing/test-wsl.sh"
```

Or from WSL:

```bash
cd ~/claude-personal-assistant
./.github/testing/test-wsl.sh
```

## Cleanup

### Remove Installation

```bash
# Remove installed directories
rm -rf ~/.aida ~/.claude ~/CLAUDE.md

# Remove backups
rm -rf ~/.aida.backup.* ~/.claude.backup.* ~/CLAUDE.md.backup.*
```

### Uninstall WSL Distribution

```powershell
# From PowerShell
wsl --unregister Ubuntu-22.04
```

## Next Steps

After successful WSL testing:

1. Test on Git Bash (Windows native)
2. Document any WSL-specific issues
3. Update installation script if needed
4. Add WSL-specific notes to README

## Related Documentation

- [Docker Testing Guide](../docker/README.md)
- [Git Bash Testing Guide](gitbash-setup.md)
- [Test Scenarios](test-scenarios.md)
- [Microsoft WSL Documentation](https://docs.microsoft.com/en-us/windows/wsl/)
