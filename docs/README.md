---
title: "AIDA Documentation Index"
description: "Complete documentation guide for the AIDA framework"
category: "guide"
tags: ["documentation", "guide", "index", "navigation"]
last_updated: "2025-10-04"
status: "published"
audience: "users"
---

# AIDA Documentation

Welcome to the AIDA documentation! This guide will help you get started, understand the system, and make the most of your agentic assistant.

## Quick Navigation

**New to AIDA?** Start here:
- [Prerequisites](getting-started/prerequisites.md) - Required and recommended tools
- [Platform Support](getting-started/platform-support.md) - macOS, Linux, Windows/WSL
- [Installation](getting-started/installation.md) - Complete installation guide

**Using AIDA:**
- [MCP Servers Guide](guides/mcp-servers.md) - Essential Claude extensions
- [Knowledge Sync](guides/knowledge-sync.md) - Extract learnings to your PKM safely
- [Knowledge Sync Quick Reference](reference/knowledge-sync-quickref.md) - Quick command reference

**Understanding AIDA:**
- [Architecture](architecture/ARCHITECTURE.md) - Complete system architecture
- [Requirements](reference/requirements.md) - Detailed requirements document
- [Project Agents](../project-agents/README.md) - Tech stack-specific agents

**For Developers:**
- [Development Roadmap](development/ROADMAP.md) - What we're building
- [Tools Summary](reference/tools-summary.md) - Quick tools checklist
- [Token Usage Guide](reference/token-usage.md) - Claude plans and costs

**Meta/Reference:**
- [Repository Descriptions](meta/repo-descriptions.md) - GitHub repo metadata
- [Repository READMEs](meta/repo-readmes.md) - README templates

---

## Documentation Structure

```
docs/
├── getting-started/       # New user onboarding
│   ├── prerequisites.md   # Required & recommended tools
│   ├── platform-support.md # macOS, Linux, Windows guidance
│   └── installation.md    # Complete setup instructions
│
├── guides/                # Practical how-to guides
│   ├── mcp-servers.md     # Model Context Protocol setup
│   └── knowledge-sync.md  # Extract & store project learnings
│
├── architecture/          # Technical design
│   └── ARCHITECTURE.md    # Complete system architecture
│
├── development/           # For contributors
│   └── ROADMAP.md        # Development plan and tasks
│
├── reference/             # Reference materials
│   ├── requirements.md         # Detailed requirements
│   ├── tools-summary.md        # Tools checklist
│   ├── token-usage.md          # Claude costs and optimization
│   └── knowledge-sync-quickref.md # Quick knowledge sync guide
│
└── meta/                  # Repository documentation
    ├── repo-descriptions.md    # GitHub descriptions
    └── repo-readmes.md         # README templates
```

---

## Getting Started Path

### For New Users

1. **Prerequisites** → Check you have [required tools](getting-started/prerequisites.md)
2. **Platform** → Review [platform-specific guidance](getting-started/platform-support.md)
3. **Install** → Follow [installation guide](getting-started/installation.md)
4. **MCP Setup** → Configure [MCP servers](guides/mcp-servers.md)
5. **Start Using** → Begin with daily workflows

### For Developers

1. **Architecture** → Read [architecture documentation](architecture/ARCHITECTURE.md)
2. **Requirements** → Review [detailed requirements](reference/requirements.md)
3. **Roadmap** → Check [development roadmap](development/ROADMAP.md)
4. **Tools** → Install [development tools](reference/tools-summary.md)
5. **Contribute** → Start with Phase 1 tasks from roadmap

---

## Key Concepts

### AIDA Framework
AIDA (Agentic Intelligence Digital Assistant) is a conversational operating system for managing digital life through Claude AI. Unlike traditional dotfiles, AIDA provides natural language interface to projects, files, tasks, and workflows.

### Three-Repo Ecosystem
- **claude-personal-assistant** (this repo) - Public framework
- **dotfiles** - Public configuration templates
- **dotfiles-private** - Private personal configurations

### Core Components
- **Knowledge Base** - Static documentation about your system
- **Memory System** - Dynamic current state and history
- **Personality System** - How your assistant communicates
- **Agent System** - Role-based specialized behaviors
- **Project Agents** - Tech stack-specific guidance

---

## Documentation Standards

### Writing Style
- **Clear and concise** - Get to the point quickly
- **Examples first** - Show, don't just tell
- **Actionable** - Users should know what to do next
- **Tested** - All commands and examples verified

### Document Format
- Use `#` for page title (one per page)
- Use `##` for major sections
- Use `###` for subsections
- Code blocks with language: ` ```bash `
- Link with relative paths: `[text](../path/to/doc.md)`

---

## Contributing to Documentation

We welcome documentation contributions!

**How to contribute:**
1. Fix typos and errors
2. Add examples and clarifications
3. Create new guides for features
4. Improve navigation

**Before submitting:**
- Test all commands
- Check all links work
- Follow style guide
- Preview Markdown rendering

See [ROADMAP.md](development/ROADMAP.md) for contribution guidelines.

---

## Getting Help

Can't find what you need?
- Check this index for the right document
- Search within docs (most editors have search)
- Check [GitHub Issues](https://github.com/yourusername/claude-personal-assistant/issues)
- Ask in [GitHub Discussions](https://github.com/yourusername/claude-personal-assistant/discussions)

---

## Documentation Maintenance

### Keeping Docs Updated

When you change AIDA:
- Update relevant user guides
- Update architecture if structure changed
- Update roadmap if priorities changed
- Update examples if affected

### Review Schedule
- **Getting Started**: Review quarterly
- **Architecture**: Update with major changes
- **Development**: Update with process changes
- **Reference**: Verify accuracy annually

---

**This documentation is a living system. Your feedback and contributions make it better!**