---
title: "Essential Tools for AIDE - Quick Reference"
description: "Quick checklist of required and recommended tools for AIDE setup"
category: "reference"
tags: ["tools", "setup", "prerequisites", "checklist"]
last_updated: "2025-10-04"
status: "published"
audience: "users"
---

# Essential Tools for AIDE - Quick Reference

Save this as a checklist when setting up AIDE.

## ✅ Installation Checklist

### Required (Must Have)

- [ ] **Git** - `git --version`
- [ ] **Bash/Zsh** - `echo $SHELL`
- [ ] **Terminal** - Built-in terminal app

### Highly Recommended

- [ ] **GitHub CLI** - `gh --version`
- [ ] **Claude Code** - `claude --version` (use official installer, NOT Homebrew!)
- [ ] **MCP Servers** - Essential extensions for Claude Desktop
  - [ ] Filesystem server
  - [ ] Git server
  - [ ] GitHub server
  - [ ] Memory server
- [ ] **VS Code or Cursor** - `code --version`
- [ ] **Obsidian** - For knowledge management

### Recommended Enhancements

- [ ] **Starship** - Beautiful prompt (`starship --version`)
- [ ] **GNU Stow** - For dotfiles (`stow --version`)
- [ ] **Better Terminal** - iTerm2 (Mac), Windows Terminal (Windows)

---

## 🚀 One-Command Install (macOS)

```bash
# Install core tools via Homebrew
brew install git gh stow starship fzf bat exa ripgrep tldr
brew install --cask visual-studio-code iterm2 obsidian

# Claude Code (separate - use official installer, NOT Homebrew)
curl -fsSL https://claude.ai/install.sh | sh

# MCP Servers (essential for AIDE)
npm install -g @modelcontextprotocol/server-filesystem \
               @modelcontextprotocol/server-git \
               @modelcontextprotocol/server-github \
               @modelcontextprotocol/server-memory \
               @modelcontextprotocol/server-brave-search
```

**After install:** Configure MCP servers in Claude Desktop. See [MCP Servers Guide](docs/user-guide/mcp-servers.md).

---

## 💡 Claude Configuration Quick Setup

### Custom Instructions

Add to Claude's custom instructions:

```text
I use AIDE (Agentic Intelligence Digital Assistant).
My assistant: JARVIS
Config: ~/CLAUDE.md and ~/.claude/
When working, check ~/CLAUDE.md for my configuration.
Use JARVIS personality (snarky but helpful).
```

### Common Statuslines

**Daily Work:**

```text
/statusline Working on [Project]. Focus: [goals]. JARVIS mode.
```

**Deep Focus:**

```text
/statusline Deep work on [task]. Minimal chat, direct solutions.
```

**End of Day:**

```text
/statusline End of day wrap-up. Review accomplishments, prepare tomorrow.
```

---

## 🔧 Quick Verification

Run this to verify everything:

```bash
echo "=== Required ==="
git --version && echo "✅ Git" || echo "❌ Git"
bash --version && echo "✅ Bash" || echo "❌ Bash"

echo "=== Highly Recommended ==="
gh --version && echo "✅ GitHub CLI" || echo "❌ GitHub CLI"
claude --version && echo "✅ Claude Code" || echo "❌ Claude Code"
code --version && echo "✅ VS Code" || echo "❌ VS Code"

echo "=== MCP Servers (check in Claude Desktop) ==="
npm list -g @modelcontextprotocol/server-filesystem && echo "✅ Filesystem" || echo "❌ Filesystem"
npm list -g @modelcontextprotocol/server-git && echo "✅ Git" || echo "❌ Git"
npm list -g @modelcontextprotocol/server-github && echo "✅ GitHub" || echo "❌ GitHub"

echo "=== Recommended ==="
starship --version && echo "✅ Starship" || echo "⚠️  Starship (optional)"
stow --version && echo "✅ Stow" || echo "⚠️  Stow (optional)"
```

**Then in Claude Desktop:** Ask "Can you list files in my .claude directory?" to verify MCP filesystem server works.

---

## 📚 Full Documentation

See [Prerequisites & Recommended Tools](docs/user-guide/prerequisites.md) for:

- Detailed installation instructions for each tool
- Platform-specific guidance
- Advanced configuration
- Troubleshooting

---

## ⏭️ Next Steps

Once tools are installed:

1. **Install AIDA**:

   ```bash
   git clone https://github.com/you/claude-personal-assistant ~/.aida
   cd ~/.aida && ./install.sh
   ```

2. **Authenticate tools**:

   ```bash
   gh auth login
   claude auth login
   ```

3. **Set up dotfiles** (optional):

   ```bash
   git clone git@github.com:you/dotfiles.git ~/dotfiles
   cd ~/dotfiles && stow */
   ```

4. **Configure Claude**: Add custom instructions and statuslines

5. **Start using**: `jarvis-start-day`

---

**🎉 You're ready for AIDE!**
