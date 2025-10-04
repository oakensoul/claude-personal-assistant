---
title: "Platform Support"
description: "Comprehensive platform support guide for AIDE - macOS, Linux, and Windows/WSL"
category: "getting-started"
tags: ["platform", "macos", "linux", "windows", "wsl", "compatibility"]
last_updated: "2025-10-04"
status: "published"
audience: "users"
---

# Platform Support

AIDE is designed to work across Unix-like environments. Here's what you need to know for your platform.

## Supported Platforms

### ✅ macOS (Primary Platform)

**Fully supported** - AIDE is developed primarily on macOS.

**Requirements:**
- macOS 11 (Big Sur) or later
- Bash or Zsh (included by default)
- Git (install via Xcode Command Line Tools or Homebrew)

**Installation:**
```bash
git clone https://github.com/yourusername/claude-personal-assistant.git ~/.aide
cd ~/.aide
./install.sh
```

**Notes:**
- Works with Apple Silicon (M1/M2/M3) and Intel Macs
- Tested on macOS Sequoia, Sonoma, Ventura

---

### ✅ Linux (Supported)

**Fully supported** - AIDE works great on Linux.

**Tested Distributions:**
- Ubuntu 20.04+
- Debian 11+
- Arch Linux
- Fedora 36+

**Requirements:**
- Bash 4.0+ or Zsh
- Git
- GNU core utilities (usually pre-installed)

**Installation:**
```bash
git clone https://github.com/yourusername/claude-personal-assistant.git ~/.aide
cd ~/.aide
./install.sh
```

**Notes:**
- Should work on any modern Linux distribution
- May need to install `curl` or `wget` if not present
- Tested primarily on Ubuntu and Debian

---

### ⚠️ Windows (Via WSL)

**Supported via WSL** - Use Windows Subsystem for Linux.

**Why WSL?**
- AIDE uses bash scripts and Unix tools
- WSL provides a true Linux environment
- Standard for dev tools on Windows
- Full compatibility with macOS/Linux instructions

**Setup:**

1. **Install WSL** (if not already installed):
   ```powershell
   # Run in PowerShell as Administrator
   wsl --install
   ```

2. **Restart your computer**

3. **Open WSL** (Ubuntu by default):
   ```powershell
   wsl
   ```

4. **Install AIDE**:
   ```bash
   # Now you're in Linux environment
   git clone https://github.com/yourusername/claude-personal-assistant.git ~/.aide
   cd ~/.aide
   ./install.sh
   ```

**Notes:**
- WSL 2 recommended (default on Windows 11)
- Can access Windows files via `/mnt/c/`
- Your AIDE installation is in WSL, not native Windows

**Accessing from Windows:**
- Files: `\\wsl$\Ubuntu\home\yourusername\.aide`
- Terminal: Windows Terminal or WSL terminal

**Alternative: Git Bash** (Not Officially Supported)
- Git Bash *may* work but is not tested
- Some features might not work correctly
- Use WSL for best experience

---

## Not Supported

### ❌ Native Windows (PowerShell)

Native Windows PowerShell scripts are **not currently supported**.

**Why not?**
- AIDE targets developers (comfortable with WSL)
- Maintaining parallel bash and PowerShell codebases doubles work
- WSL is standard for modern dev tools
- Single testing surface keeps quality high

**Future:**
- Native PowerShell support *may* be added in a future release
- Depends on user demand
- Would be Phase 3 or 4 feature

**If you need native Windows:**
- Use WSL (recommended)
- Or wait for potential future PowerShell support

---

## Choosing Your Platform

### Recommendation by Use Case

**Personal laptop/desktop**: Use your native OS
- Mac → macOS installation
- Linux → Linux installation  
- Windows → WSL installation

**Work computer**: Check company policy
- Some companies require WSL on Windows
- Some provide Mac or Linux laptops
- Follow IT guidelines

**Multiple computers**: Use your dotfiles repo
- AIDE config syncs across platforms
- Each machine installs framework normally
- Dotfiles handle machine-specific differences

---

## Platform-Specific Notes

### macOS Specifics

**Homebrew Integration:**
```bash
# AIDE can track Homebrew packages
brew bundle dump --file=~/.aida/Brewfile
```

**Spotlight Integration:**
- CLI tool automatically added to PATH
- Works from Spotlight/Alfred

**iCloud Drive:**
- Can sync `~/.claude/` via iCloud
- Not recommended for memory/ (frequent updates)

### Linux Specifics

**Package Managers:**
- apt, yum, pacman, etc. support varies
- Document your package list manually

**Desktop Environments:**
- Works with GNOME, KDE, Xfce, etc.
- No GUI components (terminal-based)

**systemd:**
- Can set up systemd timers for scheduled tasks
- Example timers included in workflows/

### WSL Specifics

**File System:**
- WSL home: `/home/yourusername/`
- Windows home: `/mnt/c/Users/YourName/`
- Keep AIDE in WSL home for performance

**Integration:**
- Can run Windows apps from WSL
- Can access WSL files from Windows Explorer
- Use Windows Terminal for best experience

**VS Code:**
- Use "Remote - WSL" extension
- Edit AIDE files in VS Code
- Full integration with WSL environment

---

## Testing Your Platform

After installation, verify everything works:

```bash
# Check AIDE installation
jarvis status

# Check all tools available
which git
which bash
bash --version

# Test a simple command
jarvis help
```

**If you encounter issues**, see [Troubleshooting](troubleshooting.md).

---

## Contributing Platform Support

Want to help improve platform support?

**Testing:**
- Test on your platform
- Report issues specific to your OS
- Share workarounds

**Documentation:**
- Improve platform-specific docs
- Add tips for your distribution
- Document known issues

**Development:**
- Fix platform-specific bugs
- Improve cross-platform compatibility
- Add platform detection to install.sh

See [CONTRIBUTING.md](../developer-guide/CONTRIBUTING.md).

---

## FAQ

**Q: Can I use AIDE on ChromeOS?**  
A: Possibly via Linux (Beta) mode, but untested. Try at your own risk.

**Q: Does AIDE work on Raspberry Pi?**  
A: Should work on Raspberry Pi OS (based on Debian). Not officially tested.

**Q: Can I use AIDE on BSD (FreeBSD, OpenBSD)?**  
A: Might work with minor modifications. Not officially supported.

**Q: Will you add PowerShell support?**  
A: Maybe in the future if there's strong demand. For now, use WSL on Windows.

**Q: Why not just use PowerShell?**  
A: AIDE targets developers who are comfortable with Unix tools. WSL provides full compatibility.

**Q: Can I run AIDE in Docker?**  
A: Yes! AIDE works in Docker containers. Useful for testing or isolated environments.

---

## Platform Roadmap

**Current (v0.1.0-0.3.0):**
- macOS (primary)
- Linux (supported)
- Windows via WSL (supported)

**Future Consideration:**
- Native Windows PowerShell (if strong demand)
- Better distribution-specific package management
- Docker/containerized deployment
- Cloud shell integration (Google Cloud Shell, etc.)

---

**Bottom line**: macOS and Linux work great. Windows users should use WSL. We're developer-focused and that's the standard approach for dev tools.