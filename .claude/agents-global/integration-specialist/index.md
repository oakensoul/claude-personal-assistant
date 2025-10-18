---
title: "Integration Specialist - AIDA Project Instructions"
description: "AIDA-specific external tool integration requirements"
category: "project-agent-instructions"
tags: ["aida", "integration-specialist", "project-context"]
last_updated: "2025-10-09"
status: "active"
---

# AIDA Integration Specialist Instructions

Project-specific integration patterns and requirements for the AIDA framework.

## External Tool Integrations

### Obsidian Integration

AIDA integrates with Obsidian for note-taking, knowledge management, and daily tracking.

**Vault Structure**:
```
~/Documents/Obsidian/Main/
├── Daily Notes/
│   └── YYYY-MM-DD.md          # Daily notes with AIDA context
├── Projects/
│   └── [project-name]/        # Project-specific notes
├── Knowledge/
│   └── AIDA/                  # AIDA framework documentation
└── Dashboard.md               # Main AIDA dashboard
```

**Daily Note Template**:
```markdown
---
date: {{date}}
personality: {{current_personality}}
---

# {{date:YYYY-MM-DD}}

## AIDA Activity Log

- [ ] Tasks tracked by AIDA
- [ ] Decisions documented
- [ ] Knowledge captured

## Notes

[AIDA inserts activity here]

## Links

[[Yesterday]] | [[Tomorrow]]
```

**Integration Points**:
1. **Daily Notes**: AIDA appends activity to current daily note
2. **Project Notes**: Link project work to Obsidian project pages
3. **Knowledge Base**: Sync AIDA knowledge to Obsidian vault
4. **Dashboard**: Auto-update AIDA status dashboard

**API Access**:
- Use Obsidian Local REST API plugin
- Base URL: `http://localhost:27124`
- Authentication: API token in environment variable

### GNU Stow Integration

AIDA can be managed with GNU Stow for dotfiles integration.

**Stow Package Structure**:
```
~/dotfiles/
└── aida/
    ├── .aida/                 # Framework installation
    │   ├── personalities/
    │   ├── templates/
    │   └── lib/
    └── .claude/               # User configuration
        ├── agents/
        ├── commands/
        └── CLAUDE.md
```

**Stow Commands**:
```bash
# Install AIDA via stow
cd ~/dotfiles
stow aida

# Uninstall AIDA
stow -D aida

# Restow (update)
stow -R aida
```

**Integration Requirements**:
1. **Standalone First**: AIDA must work without stow
2. **Stow Optional**: Stow integration is enhancement, not requirement
3. **No Conflicts**: Stow package must not conflict with manual installation
4. **Symlink Awareness**: AIDA must detect and handle stowed vs manual install

### Git Workflow Integration

AIDA integrates with git for version control and collaboration.

**Pre-commit Hooks**:
```bash
#!/bin/bash
# .git/hooks/pre-commit

# Validate AIDA configuration before commit
if [ -f .claude/CLAUDE.md ]; then
    # Run AIDA validation
    ~/.aida/bin/validate-config || exit 1
fi

# Check for personality consistency
if [ -f .aida/personalities/current ]; then
    personality=$(cat .aida/personalities/current)
    echo "Committing as personality: $personality"
fi
```

**Workflow Commands Integration**:
- `/start-work` - Create feature branch from issue
- `/open-pr` - Create pull request with AIDA context
- `/cleanup-main` - Post-merge cleanup automation

**Git Context Tracking**:
```yaml
# AIDA tracks git context
git_context:
  repository: "https://github.com/user/repo"
  branch: "feature/new-feature"
  issue: "#42"
  personality_on_branch: "jarvis"
```

### MCP Server Integration

AIDA can expose Model Context Protocol (MCP) servers for Claude Desktop integration.

**AIDA MCP Server**:
```json
{
  "mcpServers": {
    "aida": {
      "command": "~/.aida/bin/mcp-server",
      "args": [],
      "env": {
        "AIDA_HOME": "~/.aida",
        "CLAUDE_CONFIG": "~/.claude"
      }
    }
  }
}
```

**MCP Tools Provided**:
1. `aida_get_personality` - Get current personality
2. `aida_switch_personality` - Switch to different personality
3. `aida_get_memory` - Retrieve AIDA memory
4. `aida_save_decision` - Document decision in knowledge base
5. `aida_get_context` - Get current project context

### Shell Integration

AIDA integrates with user shell configuration.

**Shell RC Integration** (`.zshrc` / `.bashrc`):
```bash
# AIDA Framework Integration
if [ -f ~/.aida/lib/shell-integration.sh ]; then
    source ~/.aida/lib/shell-integration.sh
fi

# AIDA CLI tool in PATH
export PATH="$PATH:~/.aida/bin"

# AIDA prompt integration (optional)
if command -v aida >/dev/null 2>&1; then
    # Show current personality in prompt
    AIDA_PROMPT=$(aida status --prompt 2>/dev/null || echo "")
    PS1="$AIDA_PROMPT$PS1"
fi
```

**Shell Functions**:
```bash
# Quick personality switching
alias jarvis='aida personality jarvis'
alias alfred='aida personality alfred'
alias friday='aida personality friday'

# AIDA status
alias astatus='aida status'

# AIDA knowledge search
asearch() {
    aida knowledge search "$@"
}
```

## Integration Architecture Patterns

### Bidirectional Sync

AIDA <-> Obsidian sync pattern:

1. **AIDA to Obsidian**: Push decisions, logs, context
2. **Obsidian to AIDA**: Pull notes, tasks, knowledge
3. **Conflict Resolution**: Last-write-wins with backup
4. **Sync Triggers**: On command completion, on personality switch

### Plugin System

AIDA supports external plugins via:

```
~/.aida/plugins/
├── obsidian-sync/
│   ├── plugin.yml         # Plugin metadata
│   ├── install.sh         # Installation script
│   └── lib/              # Plugin code
└── custom-integrations/
```

**Plugin Configuration**:
```yaml
---
name: "obsidian-sync"
version: "1.0.0"
description: "Obsidian vault synchronization"
author: "AIDA Team"
requires:
  - aida: ">=0.1.0"
  - obsidian-api: ">=1.0.0"
hooks:
  post_command: "sync_to_obsidian"
  pre_personality_switch: "update_obsidian_metadata"
```

## Integration Testing

### Test Scenarios

1. **Obsidian API Availability**: Graceful degradation if API unavailable
2. **GNU Stow Conflicts**: Detect and warn about stow conflicts
3. **Git Hook Failures**: Don't block commits, warn user
4. **MCP Server Crashes**: Auto-restart with exponential backoff
5. **Shell Integration Errors**: Don't break shell startup

### Error Handling

**Integration Failure Modes**:
- **Obsidian Offline**: Queue updates, retry on next command
- **Stow Package Conflict**: Warn user, suggest resolution
- **Git Hook Error**: Log error, allow commit to proceed
- **MCP Server Down**: Disable MCP features, continue operation

## Integration Notes

- **User-level Integration Patterns**: Load from `~/.claude/agents/integration-specialist/`
- **Project-specific integrations**: This file
- **Combined approach**: User philosophy + AIDA requirements

## Best Practices for AIDA

1. **Standalone First**: All integrations are optional enhancements
2. **Graceful Degradation**: Continue working if integration fails
3. **User Control**: Allow users to enable/disable integrations
4. **Clear Documentation**: Document all integration points
5. **Testing**: Test with and without each integration

---

**Last Updated**: 2025-10-09
