---
title: "Prerequisites & Recommended Tools"
description: "Complete guide to required and recommended tools for AIDA installation"
category: "getting-started"
tags: ["prerequisites", "tools", "installation", "setup", "requirements"]
last_updated: "2025-10-04"
status: "published"
audience: "users"
---

# Prerequisites & Recommended Tools

Everything you need to get the most out of AIDA.

---

## Required (Bare Minimum)

These are **absolutely required** for AIDA to work:

### 1. Git

**What it is**: Version control system  
**Why you need it**: Clone AIDE, manage your dotfiles, track changes

**Installation:**

```bash
# macOS (via Xcode Command Line Tools)
xcode-select --install

# macOS (via Homebrew)
brew install git

# Ubuntu/Debian
sudo apt install git

# Fedora
sudo dnf install git

# Windows (WSL)
sudo apt install git
```

**Verify:**
```bash
git --version
# Should show: git version 2.x.x or higher
```

### 2. Bash or Zsh

**What it is**: Shell environment  
**Why you need it**: AIDE uses bash scripts

**Check what you have:**
```bash
echo $SHELL
# Should show: /bin/bash or /bin/zsh
```

**Notes:**
- macOS: Zsh is default (works perfectly)
- Linux: Usually bash (works perfectly)
- Windows: Use WSL (provides bash)

### 3. A Terminal

**What it is**: Command-line interface  
**Why you need it**: Run AIDE commands

**You already have one:**
- macOS: Terminal.app (built-in)
- Linux: GNOME Terminal, Konsole, etc. (built-in)
- Windows: Windows Terminal (recommended for WSL)

---

## Highly Recommended

These make AIDE **much better**:

### 1. GitHub CLI (gh)

**What it is**: GitHub command-line tool  
**Why you need it**: Manage repos, issues, PRs from terminal

**Installation:**

```bash
# macOS
brew install gh

# Ubuntu/Debian
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh

# Windows (WSL)
# Same as Ubuntu/Debian above

# Or download from: https://github.com/cli/cli/releases
```

**Setup:**
```bash
gh auth login
# Follow prompts to authenticate
```

**Verify:**
```bash
gh --version
```

**Usage with AIDE:**
```bash
# Create issues from roadmap tasks
gh issue create --title "Implement install.sh" --body "..."

# View your repos
gh repo list

# Clone your dotfiles
gh repo clone yourusername/dotfiles
```

### 2. Claude Code

**What it is**: Anthropic's CLI tool for agentic coding  
**Why you need it**: Best way to use Claude with AIDE

**Installation:**

```bash
# macOS/Linux - Use official installer (NOT Homebrew)
curl -fsSL https://claude.ai/install.sh | sh

# Or download from: https://docs.claude.com/en/docs/claude-code
```

**Important**: Don't use Homebrew for Claude Code - use the official installer

**Setup:**
```bash
# Login with your Anthropic account
claude auth login

# Test it works
claude --version
```

**Using with AIDE:**
```bash
# Work in your project with AIDE context
cd ~/Development/personal/my-project/
claude "Help me implement the authentication flow"

# Claude will read ~/CLAUDE.md and project context automatically
```

### 3. A Good Code Editor

**What it is**: IDE or text editor  
**Why you need it**: Edit your AIDE configs, dotfiles, and code

**Recommended Options:**

**VS Code** (Most popular):
```bash
# macOS
brew install --cask visual-studio-code

# Ubuntu/Debian
sudo snap install code --classic

# Or download: https://code.visualstudio.com/
```

**Cursor** (AI-native, great with Claude):
```bash
# Download from: https://cursor.sh/
```

**Vim/Neovim** (Terminal-based):
```bash
# macOS
brew install neovim

# Ubuntu/Debian
sudo apt install neovim
```

**Other good options**: Sublime Text, Zed, JetBrains IDEs

### 4. Obsidian (For Knowledge Management)

**What it is**: Markdown-based knowledge management  
**Why you need it**: AIDE integrates with Obsidian for daily notes and project tracking

**Installation:**
```bash
# macOS
brew install --cask obsidian

# Or download from: https://obsidian.md/
```

**Setup with AIDE:**
1. Create vault at `~/Knowledge/Obsidian-Vault/`
2. AIDE will create daily note templates
3. Use for project tracking and daily summaries

### 5. MCP Servers (Model Context Protocol)

**What it is**: Extensions that give Claude real capabilities (filesystem, git, search, etc.)  
**Why you need it**: Makes AIDE actually work with your files and tools

**Essential MCP Servers:**
- **Filesystem** - Claude can read/write files
- **Git** - Claude can commit, push, pull
- **GitHub** - Claude can create issues, PRs
- **Memory** - Persistent context across sessions
- **Brave Search** - Web search capabilities

**Quick Install:**
```bash
npm install -g \
  @modelcontextprotocol/server-filesystem \
  @modelcontextprotocol/server-git \
  @modelcontextprotocol/server-github \
  @modelcontextprotocol/server-memory \
  @modelcontextprotocol/server-brave-search
```

**See [MCP Servers Guide](mcp-servers.md) for complete setup and configuration.**

---

## Recommended Enhancements

Make your terminal experience better:

### 1. Better Terminal App

**macOS:**

**iTerm2** (Most popular):
```bash
brew install --cask iterm2
```

**Warp** (AI-native terminal):
```bash
brew install --cask warp
```

**Alacritty** (Fast, minimal):
```bash
brew install --cask alacritty
```

**Windows:**

**Windows Terminal** (Essential for WSL):
```bash
# Install from Microsoft Store
# Or: winget install Microsoft.WindowsTerminal
```

**Linux:**

Most built-in terminals are great, but consider:
- **Alacritty** (fast and customizable)
- **Kitty** (GPU-accelerated)
- **WezTerm** (Rust-based, lots of features)

### 2. Starship Prompt

**What it is**: Fast, customizable shell prompt  
**Why it's great**: Shows git status, language versions, and more

**Installation:**
```bash
# macOS/Linux
curl -sS https://starship.rs/install.sh | sh

# Or via Homebrew (macOS)
brew install starship
```

**Setup:**
```bash
# Add to ~/.zshrc or ~/.bashrc
echo 'eval "$(starship init zsh)"' >> ~/.zshrc
# or
echo 'eval "$(starship init bash)"' >> ~/.bashrc

# Reload shell
source ~/.zshrc  # or ~/.bashrc
```

**Customize:**
```bash
# Create config
mkdir -p ~/.config
starship preset nerd-font-symbols > ~/.config/starship.toml

# Edit to your liking
vim ~/.config/starship.toml
```

**Recommended for AIDE:**
- Shows git branch and status
- Shows current directory
- Fast and clean
- Works great with JARVIS/Alfred personas

### 3. Oh My Zsh (Alternative to Starship)

**What it is**: Zsh configuration framework  
**Why it's great**: Plugins, themes, and productivity features

**Installation:**
```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

**Recommended plugins:**
```bash
# Edit ~/.zshrc
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  docker
  kubectl
)
```

**Note**: Can't use both Oh My Zsh and Starship - choose one!

### 4. GNU Stow (For Dotfiles)

**What it is**: Symlink manager for dotfiles  
**Why you need it**: Manage your dotfiles with AIDE

**Installation:**
```bash
# macOS
brew install stow

# Ubuntu/Debian
sudo apt install stow

# Fedora
sudo dnf install stow
```

**Usage:**
```bash
cd ~/dotfiles
stow shell    # Symlinks shell configs
stow aida     # Symlinks AIDE configs
```

See [Dotfiles Integration](dotfiles-integration.md) for more.

---

## Claude Configuration

### Custom Instructions

Add this to your Claude custom instructions for best AIDE experience:

```markdown
# AIDE System

I use AIDE (Agentic Intelligence Digital Assistant) to manage my digital life.

**My Assistant**: JARVIS (snarky British AI)
**Config Location**: ~/CLAUDE.md and ~/.claude/

When I'm working on my computer:
1. Always check ~/CLAUDE.md for my main configuration
2. Check ~/.claude/knowledge/ for system information
3. Check ~/.claude/memory/context.md for current state
4. If in a project directory, check for project-specific CLAUDE.md

**Commands**: 
I use commands like "jarvis-start-day" or "jarvis cleanup downloads"
These are conversational triggers, not shell scripts.

**Personality**:
Be helpful but slightly snarky (JARVIS style). 
Example: "Your Downloads folder has 73 files. Again."
```

### Statusline Templates

Use `/statusline` in Claude to set context for your session. Here are recommended templates:

#### Daily Work Session
```
/statusline Working on [Project Name]. Current status: [brief status]. 
Today's focus: [main goals]. Blockers: [any issues]. 
Use JARVIS personality (snarky but helpful).
```

Example:
```
/statusline Working on Project Alpha. Current status: API integration 80% complete. 
Today's focus: finish testing and deploy to staging. No blockers. 
Use JARVIS personality.
```

#### Deep Focus / Coding
```
/statusline Deep work session on [specific task]. 
Minimize conversation, focus on implementation. 
If I'm stuck, be direct with solutions. JARVIS mode: helpful, less snark.
```

#### Planning / Architecture
```
/statusline Architecture planning for [project/feature]. 
Be thorough, ask clarifying questions, suggest alternatives. 
Help me think through tradeoffs. Full JARVIS personality welcome.
```

#### End of Day
```
/statusline End of day wrap-up. 
Review what I accomplished, update project statuses, 
prepare tomorrow's priorities. JARVIS: time for your usual assessment.
```

#### Learning / Exploration
```
/statusline Learning [technology/concept]. 
I need clear explanations with examples. 
Be encouraging but still keep the JARVIS edge.
```

#### Quick Task
```
/statusline Quick task: [specific thing]. 
I just need this done fast and correctly. 
Minimal explanation, maximum efficiency.
```

#### Using AIDE Commands
```
/statusline Using AIDE system. I'll use commands like 'jarvis-[action]'. 
Read ~/CLAUDE.md and ~/.claude/ for context. 
Execute procedures from ~/.claude/knowledge/procedures.md.
```

**Pro Tip**: Save statuslines you use often:
```bash
# Add to your AIDE procedures
vim ~/.claude/knowledge/statuslines.md
```

---

## Optional But Nice

### fzf (Fuzzy Finder)
```bash
brew install fzf
# Adds amazing command history search
```

### bat (Better cat)
```bash
brew install bat
alias cat="bat"  # Add to ~/.zshrc
```

### exa (Better ls)
```bash
brew install exa
alias ls="exa"  # Add to ~/.zshrc
```

### ripgrep (Better grep)
```bash
brew install ripgrep
# Much faster searching
```

### tldr (Simplified man pages)
```bash
brew install tldr
# Better than man pages for quick reference
```

---

## Verification Checklist

After installing, verify everything works:

```bash
# Required
✓ git --version
✓ bash --version  # or zsh --version
✓ echo $SHELL

# Highly Recommended
✓ gh --version
✓ claude --version
✓ code --version  # or your editor
✓ obsidian  # or open the app

# Recommended
✓ starship --version  # or oh-my-zsh
✓ stow --version

# Optional
✓ fzf --version
✓ bat --version
✓ exa --version
```

---

## Quick Setup Script

Want to install everything at once? Here's a script:

```bash
#!/bin/bash
# setup-tools.sh - Install AIDE prerequisites

echo "🚀 Installing AIDE prerequisites..."

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    echo "📦 Installing via Homebrew..."
    
    # Install Homebrew if needed
    if ! command -v brew &> /dev/null; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    
    # Install tools
    brew install git gh stow starship fzf bat exa ripgrep tldr
    brew install --cask visual-studio-code iterm2 obsidian
    
    # Install Claude Code (official installer, not Homebrew)
    curl -fsSL https://claude.ai/install.sh | sh
    
elif [[ -f /etc/debian_version ]]; then
    # Ubuntu/Debian
    echo "📦 Installing via apt..."
    sudo apt update
    sudo apt install -y git gh stow curl
    
    # Starship
    curl -sS https://starship.rs/install.sh | sh
    
    # Claude Code
    curl -fsSL https://claude.ai/install.sh | sh
    
else
    echo "⚠️  Unsupported OS. Install tools manually."
    exit 1
fi

echo "✅ Prerequisites installed!"
echo "📝 Next steps:"
echo "  1. gh auth login"
echo "  2. claude auth login"
echo "  3. Install AIDE: git clone https://github.com/you/claude-personal-assistant ~/.aide"
```

---

## Getting Help

**If installation fails:**
1. Check [Troubleshooting](troubleshooting.md)
2. Check tool-specific docs
3. Ask in GitHub Discussions
4. Create an issue

**Useful commands:**
```bash
# Check what's installed
which git gh claude code

# Check versions
git --version
gh --version
claude --version

# Check PATH
echo $PATH

# Reload shell config
source ~/.zshrc  # or ~/.bashrc
```

---

## Next Steps

Once you have these tools installed:

1. **Install AIDE**: Follow [Installation Guide](installation.md)
2. **Set up dotfiles**: Follow [Dotfiles Guide](dotfiles-integration.md)
3. **Configure Claude**: Add custom instructions and statuslines
4. **Start using**: Try `jarvis-start-day`

---

**With these tools, you're ready for the full AIDE experience!**