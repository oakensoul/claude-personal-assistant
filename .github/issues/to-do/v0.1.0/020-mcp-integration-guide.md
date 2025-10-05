---
title: "Create MCP servers integration guide"
labels:
  - "type: documentation"
  - "priority: p1"
  - "effort: small"
  - "milestone: 0.1.0"
---

# Create MCP servers integration guide

## Description

Create comprehensive documentation for setting up Model Context Protocol (MCP) servers with Claude Desktop to enable seamless AIDA integration. MCP servers allow Claude to directly read/write files, use git, access memory, etc., making the AIDA experience much smoother.

## Acceptance Criteria

- [ ] File `docs/guides/mcp-servers.md` created
- [ ] Documentation covers MCP server concept and benefits
- [ ] Step-by-step installation for essential MCP servers:
  - Filesystem server
  - Git server
  - Memory server (if available)
- [ ] Configuration examples for AIDA-specific paths
- [ ] Troubleshooting section for common MCP issues
- [ ] Comparison: with MCP vs without MCP
- [ ] Security and permission considerations explained

## Implementation Notes

### MCP Servers Guide

Create `docs/guides/mcp-servers.md`:

```markdown
# MCP Servers Integration Guide

## What are MCP Servers?

Model Context Protocol (MCP) servers are tools that extend Claude's capabilities by giving it access to your local system through well-defined protocols. For AIDA, MCP servers enable Claude to:

- Read and write AIDA configuration and memory files automatically
- Execute git commands without manual copy-paste
- Access your Obsidian vault
- Maintain persistent memory across sessions

## Benefits for AIDA

**Without MCP**:
- You manually copy content from `~/CLAUDE.md` and paste into Claude
- You manually update memory files
- You copy Claude's responses and save them
- Git operations require manual commands

**With MCP**:
- Claude automatically reads `~/CLAUDE.md` and all knowledge files
- Claude updates memory and context automatically
- Claude commits changes to git when appropriate
- Seamless, conversational experience

## Recommended MCP Servers

### 1. Filesystem Server (Essential)

**Purpose**: Allows Claude to read/write files in specified directories

**What it enables**:
- Read ~/CLAUDE.md automatically
- Read ~/.claude/knowledge/* files
- Update ~/.claude/memory/context.md
- Create/update Obsidian daily notes

**Installation**:

```bash
# Install filesystem MCP server (via Claude Desktop settings)
# Or via command line if available:
npm install -g @modelcontextprotocol/server-filesystem
```json

**Configuration** (`~/Library/Application Support/Claude/claude_desktop_config.json` on macOS):

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/Users/YOUR-USERNAME"],
      "env": {}
    }
  }
}
```

**For AIDA, grant access to**:

- `~/` (home directory) - for CLAUDE.md
- `~/.claude/` - for all AIDA files
- `~/Knowledge/Obsidian-Vault/` - for Obsidian integration
- `~/Development/` - for project work

### 2. Git Server (Highly Recommended)

**Purpose**: Allows Claude to execute git commands

**What it enables**:

- Commit changes to dotfiles automatically
- Create branches and PRs
- Check git status
- Manage project repositories

**Installation**:

```bash
npm install -g @modelcontextprotocol/server-git
```json

**Configuration**:

```json
{
  "mcpServers": {
    "git": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-git"],
      "env": {}
    }
  }
}
```

### 3. Memory Server (Recommended)

**Purpose**: Provides persistent memory across Claude sessions

**What it enables**:

- Claude remembers context from previous conversations
- No need to re-explain setup each time
- Continuity in multi-day workflows

**Installation**:

Check if available in Claude Desktop settings or:

```bash
npm install -g @modelcontextprotocol/server-memory
```json

**Configuration**:

```json
{
  "mcpServers": {
    "memory": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"],
      "env": {}
    }
  }
}
```

## Complete Configuration Example

`~/Library/Application Support/Claude/claude_desktop_config.json` (macOS):

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "/Users/YOUR-USERNAME"
      ]
    },
    "git": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-git"]
    },
    "memory": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"]
    }
  }
}
```html

**Important**: Replace `YOUR-USERNAME` with your actual username.

## Setup Steps

### 1. Install Claude Desktop

Download from: <https://claude.ai/download>

### 2. Install Node.js (if not already installed)

MCP servers require Node.js:

```bash
# macOS (with Homebrew)
brew install node

# Linux (Ubuntu/Debian)
sudo apt install nodejs npm

# Verify installation
node --version  # Should be v16+
npm --version
```

### 3. Configure MCP Servers

**On macOS**:

```bash
# Create config file if it doesn't exist
mkdir -p ~/Library/Application\ Support/Claude/
nano ~/Library/Application\ Support/Claude/claude_desktop_config.json
```text

**On Linux**:

```bash
mkdir -p ~/.config/Claude/
nano ~/.config/Claude/claude_desktop_config.json
```

**On Windows**:

```text
%APPDATA%\Claude\claude_desktop_config.json
```

### 4. Paste Configuration

Copy the complete configuration example above, replacing `YOUR-USERNAME`.

### 5. Restart Claude Desktop

Completely quit and restart Claude Desktop app.

### 6. Verify MCP Servers

In Claude Desktop, check for indicators that MCP servers are active:

- Filesystem icon or mention
- Git capabilities available
- No permission errors when accessing files

### 7. Test with AIDA

Start conversation:

```text
Please read ~/CLAUDE.md and introduce yourself
```

Claude should automatically read the file without you copying/pasting it.

## Usage with AIDA

### First Conversation

```text
Read ~/CLAUDE.md and introduce yourself as my assistant
```

Claude will:

1. Read ~/CLAUDE.md via filesystem MCP
2. Load personality from ~/.claude/config/personality.yaml
3. Introduce itself with appropriate personality

### Daily Workflow

```text
jarvis start day
```

Claude will:

1. Read memory/context.md
2. Read knowledge/projects.md
3. Create/update today's Obsidian daily note (via filesystem)
4. Update memory/context.md
5. Optionally commit changes (via git)

### Project Work

```text
I'm working on Project Alpha. Update its status to 80% complete.
```

Claude will:

1. Read knowledge/projects.md
2. Update Project Alpha entry
3. Write file back (via filesystem)
4. Update memory/context.md
5. Commit changes (via git if configured)

## Troubleshooting

### MCP Server Not Found

**Symptom**: "Server not available" or similar error

**Solutions**:

1. Verify Node.js is installed: `node --version`
2. Check config file path is correct
3. Ensure JSON is valid (no trailing commas, proper quotes)
4. Restart Claude Desktop completely

### Permission Denied

**Symptom**: "Cannot read file" or "Permission denied"

**Solutions**:

1. Check filesystem server has access to directory
2. Verify file permissions: `ls -la ~/.claude/`
3. Grant Claude Desktop full disk access (macOS System Preferences > Security & Privacy)

### Git Commands Fail

**Symptom**: Git operations don't work

**Solutions**:

1. Verify git is installed: `git --version`
2. Check git server is in config
3. Ensure repository has proper remote configured
4. Restart Claude Desktop

### Config File Not Loaded

**Symptom**: MCP servers don't seem to activate

**Solutions**:

1. Verify config file location (different per OS)
2. Check JSON syntax with validator
3. Ensure file is named exactly `claude_desktop_config.json`
4. Try creating file from scratch
5. Check Claude Desktop logs for errors

## Security Considerations

### Filesystem Access

**What Claude can do**:

- Read files in specified directories
- Write to specified directories
- Create/delete files

**Recommendations**:

- Grant access only to needed directories
- Don't grant root access
- Review filesystem server permissions
- Keep sensitive files in non-accessible directories

### Git Access

**What Claude can do**:

- Read repository status
- Create commits
- Push to remotes (if credentials available)

**Recommendations**:

- Review commits before pushing
- Use separate git user for Claude commits (optional)
- Don't grant access to repositories with secrets
- Configure git signing if needed

### Memory Persistence

**What Claude remembers**:

- Information from previous conversations
- Preferences and context
- Project details

**Recommendations**:

- Don't share extremely sensitive information
- Review memory occasionally
- Clear memory if switching contexts

## Best Practices

1. **Start Simple**: Begin with just filesystem MCP server
2. **Test Gradually**: Verify each server works before adding more
3. **Review Changes**: Check what Claude modifies, especially with git
4. **Backup Important Data**: Before enabling write access
5. **Update Regularly**: Keep MCP servers updated
6. **Monitor Usage**: Check Claude Desktop activity

## Alternative: Without MCP Servers

If you prefer not to use MCP servers or they're not available:

1. **Manual Context Loading**:
   - Copy ~/CLAUDE.md content
   - Paste into Claude chat
   - Manually provide context

2. **Manual File Updates**:
   - Claude provides updated content
   - You copy and save to files
   - You commit changes

3. **CLI Tool Usage**:
   - Use `jarvis status` for quick checks
   - Still get AIDA structure benefits
   - Less automation, more control

## References

- [MCP Documentation](https://modelcontextprotocol.io/)
- [Claude Desktop Download](https://claude.ai/download)
- [AIDA Architecture](../architecture/ARCHITECTURE.md)

---

**Recommended Setup**: Filesystem + Git servers minimum for best AIDA experience.

```text

## Dependencies

None - documentation only

## Related Issues

- #005 (CLAUDE.md references MCP usage)
- #011 (Procedures assume MCP for file updates)

## Definition of Done

- [ ] MCP servers guide created
- [ ] All essential servers documented
- [ ] Installation steps are clear
- [ ] Configuration examples provided
- [ ] Troubleshooting covers common issues
- [ ] Security considerations explained
- [ ] Tested on macOS
- [ ] Tested on Linux (if possible)
- [ ] Ready for MVP documentation
