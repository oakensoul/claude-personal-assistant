---
title: "MCP Servers for AIDE"
description: "Complete guide to setting up Model Context Protocol servers for AIDE"
category: "guide"
tags: ["mcp", "servers", "claude", "integration", "setup"]
last_updated: "2025-10-04"
status: "published"
audience: "users"
---

# MCP Servers for AIDE

**Model Context Protocol (MCP)** servers extend Claude's capabilities with tools and integrations. This guide covers essential MCP servers for getting the most out of AIDE.

---

## What is MCP?

**Model Context Protocol** is Anthropic's standard for connecting Claude to external tools and data sources.

**Benefits for AIDE:**
- Claude can directly read/write files (filesystem access)
- Claude can execute git commands (version control)
- Claude can search the web (real-time information)
- Claude can query databases (data access)
- Claude can automate browsers (web scraping, testing)

**Official Documentation**: https://modelcontextprotocol.io/

---

## Essential MCP Servers for AIDE

### 1. Filesystem Server ⭐⭐⭐ (Critical)

**What it does**: Allows Claude to read, write, and manage files on your computer

**Why you need it**: AIDE needs to:
- Read `~/CLAUDE.md` and `~/.claude/` files
- Update memory and context files
- Create and edit project files
- Organize downloads and documents

**Installation:**

```bash
# Install via npm
npm install -g @modelcontextprotocol/server-filesystem

# Or install via Claude Desktop (recommended)
# It's usually included by default
```

**Configuration** (Claude Desktop):

Add to `~/Library/Application Support/Claude/claude_desktop_config.json` (macOS):

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/Users/yourusername"]
    }
  }
}
```

**For AIDE, configure safe paths:**

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "/Users/yourusername/Development",
        "/Users/yourusername/.claude",
        "/Users/yourusername/Documents",
        "/Users/yourusername/Downloads",
        "/Users/yourusername/Knowledge"
      ]
    }
  }
}
```

**AIDE Usage:**
```
You: "jarvis-cleanup-downloads"
Claude: [Uses filesystem server to analyze Downloads]
        [Moves files to appropriate locations]
        [Updates memory/context.md]
```

### 2. Git Server ⭐⭐⭐ (Critical)

**What it does**: Enables Claude to perform git operations

**Why you need it**: AIDE needs to:
- Commit changes to dotfiles
- Create branches for features
- Push/pull from GitHub
- Check repository status

**Installation:**

```bash
npm install -g @modelcontextprotocol/server-git
```

**Configuration:**

```json
{
  "mcpServers": {
    "git": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-git"]
    }
  }
}
```

**AIDE Usage:**
```
You: "Commit my AIDE configuration changes"
Claude: [Uses git server]
        [Stages ~/.claude/ changes]
        [Creates descriptive commit]
        [Pushes to private repo]
```

### 3. GitHub Server ⭐⭐⭐ (Critical)

**What it does**: Integrates with GitHub (repos, issues, PRs)

**Why you need it**: AIDE development needs:
- Create issues from roadmap
- View and update project boards
- Manage pull requests
- Search repositories

**Installation:**

```bash
npm install -g @modelcontextprotocol/server-github
```

**Configuration:**

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "your_github_personal_access_token"
      }
    }
  }
}
```

**Get GitHub token**: https://github.com/settings/tokens

**AIDE Usage:**
```
You: "Create an issue for implementing install.sh"
Claude: [Uses GitHub server]
        [Creates issue in claude-personal-assistant repo]
        [Adds to roadmap milestone]
```

### 4. Memory Server ⭐⭐ (Highly Recommended)

**What it does**: Persistent memory across Claude sessions

**Why you need it**: AIDE can:
- Remember long-term context
- Store knowledge graphs
- Build relationships between entities
- Maintain state between conversations

**Installation:**

```bash
npm install -g @modelcontextprotocol/server-memory
```

**Configuration:**

```json
{
  "mcpServers": {
    "memory": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"]
    }
  }
}
```

**AIDE Usage:**
```
You: "Remember that I decided to use PostgreSQL for Project Alpha"
Claude: [Stores in memory server]
        [Also updates ~/.claude/memory/decisions.md]

Later...
You: "What database am I using for Project Alpha?"
Claude: [Recalls from memory server]
        "You decided on PostgreSQL on 2025-10-04"
```

### 5. Brave Search Server ⭐⭐ (Recommended)

**What it does**: Web search capabilities

**Why you need it**: AIDE can:
- Look up current information
- Find documentation
- Research technologies
- Verify facts

**Installation:**

```bash
npm install -g @modelcontextprotocol/server-brave-search
```

**Configuration:**

```json
{
  "mcpServers": {
    "brave-search": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-brave-search"],
      "env": {
        "BRAVE_API_KEY": "your_brave_api_key"
      }
    }
  }
}
```

**Get Brave API key**: https://brave.com/search/api/

**AIDE Usage:**
```
You: "What are the best practices for Next.js 14 App Router?"
Claude: [Searches web]
        [Finds latest documentation]
        [Summarizes current best practices]
```

---

## Recommended MCP Servers

### 6. PostgreSQL Server ⭐⭐

**What it does**: Query and manage PostgreSQL databases

**Why useful**: If you store AIDE data in Postgres or work with databases

```bash
npm install -g @modelcontextprotocol/server-postgres
```

```json
{
  "mcpServers": {
    "postgres": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres"],
      "env": {
        "POSTGRES_CONNECTION_STRING": "postgresql://user:pass@localhost/db"
      }
    }
  }
}
```

### 7. SQLite Server ⭐⭐

**What it does**: Query and manage SQLite databases

**Why useful**: Lightweight database for AIDE analytics or local data

```bash
npm install -g @modelcontextprotocol/server-sqlite
```

```json
{
  "mcpServers": {
    "sqlite": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sqlite", "/path/to/database.db"]
    }
  }
}
```

### 8. Puppeteer Server ⭐

**What it does**: Browser automation

**Why useful**: Web scraping, testing, screenshots

```bash
npm install -g @modelcontextprotocol/server-puppeteer
```

```json
{
  "mcpServers": {
    "puppeteer": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-puppeteer"]
    }
  }
}
```

### 9. Slack Server ⭐

**What it does**: Read and send Slack messages

**Why useful**: Integrate AIDE with team communication

```bash
npm install -g @modelcontextprotocol/server-slack
```

```json
{
  "mcpServers": {
    "slack": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-slack"],
      "env": {
        "SLACK_BOT_TOKEN": "xoxb-your-token",
        "SLACK_TEAM_ID": "your-team-id"
      }
    }
  }
}
```

### 10. Google Drive Server ⭐

**What it does**: Access Google Drive files

**Why useful**: Read documents, sync files

```bash
npm install -g @modelcontextprotocol/server-gdrive
```

---

## Complete Configuration Example

Here's a complete `claude_desktop_config.json` for AIDE:

**macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`  
**Windows**: `%APPDATA%\Claude\claude_desktop_config.json`  
**Linux**: `~/.config/Claude/claude_desktop_config.json`

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "/Users/yourusername/Development",
        "/Users/yourusername/.claude",
        "/Users/yourusername/Documents",
        "/Users/yourusername/Downloads",
        "/Users/yourusername/Knowledge"
      ]
    },
    "git": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-git"]
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "ghp_your_token_here"
      }
    },
    "memory": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"]
    },
    "brave-search": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-brave-search"],
      "env": {
        "BRAVE_API_KEY": "your_brave_api_key"
      }
    },
    "sqlite": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-sqlite",
        "/Users/yourusername/.claude/aide.db"
      ]
    }
  },
  "globalShortcut": "Cmd+Shift+Space"
}
```

---

## Installation Quick Start

### Step 1: Install Node.js (if needed)

```bash
# macOS
brew install node

# Ubuntu/Debian
sudo apt install nodejs npm

# Windows (WSL)
sudo apt install nodejs npm
```

### Step 2: Install Essential MCP Servers

```bash
# Install all essential servers at once
npm install -g \
  @modelcontextprotocol/server-filesystem \
  @modelcontextprotocol/server-git \
  @modelcontextprotocol/server-github \
  @modelcontextprotocol/server-memory \
  @modelcontextprotocol/server-brave-search
```

### Step 3: Configure Claude Desktop

1. **Quit Claude Desktop** completely
2. **Edit config file**:
   ```bash
   # macOS
   code ~/Library/Application\ Support/Claude/claude_desktop_config.json
   
   # Linux
   code ~/.config/Claude/claude_desktop_config.json
   
   # Windows
   code %APPDATA%\Claude\claude_desktop_config.json
   ```
3. **Add MCP server configuration** (see example above)
4. **Replace tokens/paths** with your actual values
5. **Save and restart Claude Desktop**

### Step 4: Verify Installation

In Claude Desktop:
```
You: "Can you list the files in my .claude directory?"

If filesystem server is working, Claude will show the files.

You: "What's my current git status?"

If git server is working, Claude will show git status.
```

---

## Security Considerations

### Filesystem Access

**Be careful with paths!** Only grant access to folders AIDE needs:

✅ Safe paths:
- `/Users/you/Development`
- `/Users/you/.claude`
- `/Users/you/Documents`
- `/Users/you/Downloads`
- `/Users/you/Knowledge`

❌ Avoid granting access to:
- Root directory `/`
- Home directory `/Users/you` (too broad)
- System directories `/System`, `/Library`
- `.ssh`, `.aws` (credentials)

### API Keys and Tokens

**Never commit these to git!**

Store in config file (which should be gitignored):
```json
{
  "mcpServers": {
    "github": {
      "env": {
        "GITHUB_TOKEN": "ghp_xxxxxxxxxxxx"  // From environment
      }
    }
  }
}
```

Or use environment variables:
```bash
export GITHUB_TOKEN="ghp_xxxxxxxxxxxx"
export BRAVE_API_KEY="xxxxxxxxxxxx"
```

### Permissions

Grant minimal permissions:
- **GitHub token**: Only `repo` scope (not `admin`, `delete`)
- **Brave API**: Read-only search
- **Database**: Read-only if possible

---

## AIDE-Specific MCP Integration

### Filesystem + Memory Integration

AIDE uses both MCP filesystem and local memory files:

```
~/.claude/memory/context.md  (filesystem - frequently updated)
    ↓
MCP Memory Server (persistent across sessions)
    ↓
Long-term relationship memory
```

**Best practice**: Let Claude update both

### Git + GitHub Integration

```
You: "jarvis-commit-changes"

Claude: 
  1. Uses filesystem to read changed files
  2. Uses git to stage and commit
  3. Uses github to push and create PR if needed
```

### Project Agent + Search Integration

```
You: "What are the latest Next.js 14 patterns?"

Claude:
  1. Reads project-agents/nextjs/CLAUDE.md (filesystem)
  2. Searches web for latest info (brave-search)
  3. Updates project agent with new patterns (filesystem + git)
```

---

## Troubleshooting MCP

### MCP servers not appearing

1. **Check Claude Desktop is completely quit** (not just closed)
2. **Verify config file syntax** (use JSON validator)
3. **Check Node.js is installed**: `node --version`
4. **Check MCP server is installed**: `npm list -g @modelcontextprotocol/server-filesystem`
5. **Check Claude Desktop logs**:
   ```bash
   # macOS
   tail -f ~/Library/Logs/Claude/mcp*.log
   ```

### Filesystem access denied

1. **Check paths in config** are absolute and correct
2. **Check permissions** on directories
3. **Grant Full Disk Access** to Claude Desktop:
   - macOS: System Settings → Privacy & Security → Full Disk Access

### GitHub authentication failing

1. **Verify token** has correct permissions
2. **Check token hasn't expired**
3. **Regenerate token** if needed: https://github.com/settings/tokens

### Performance issues

MCP servers can slow Claude Desktop:

**Solutions:**
- Only enable servers you actively use
- Limit filesystem paths to necessary directories
- Close Claude Desktop when not in use

---

## Advanced: Custom MCP Servers

You can build custom MCP servers for AIDE-specific needs:

### Example: AIDE Status Server

```typescript
// Custom MCP server to check AIDE status
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";

const server = new Server({
  name: "aide-status",
  version: "1.0.0",
}, {
  capabilities: {
    tools: {},
  },
});

server.setRequestHandler("tools/list", async () => ({
  tools: [{
    name: "check_aide_status",
    description: "Check AIDE system status",
    inputSchema: {
      type: "object",
      properties: {},
    },
  }],
}));

// ... implementation
```

See [MCP documentation](https://modelcontextprotocol.io/docs/building-servers) for building custom servers.

---

## Recommended MCP Setup for AIDE

### Minimal Setup (Essential Only)
- ✅ Filesystem
- ✅ Git
- ✅ GitHub

### Standard Setup (Recommended)
- ✅ Filesystem
- ✅ Git
- ✅ GitHub
- ✅ Memory
- ✅ Brave Search

### Power User Setup (All the Tools)
- ✅ Filesystem
- ✅ Git
- ✅ GitHub
- ✅ Memory
- ✅ Brave Search
- ✅ SQLite (for AIDE analytics)
- ✅ Puppeteer (for web automation)
- ✅ Slack (for team integration)

---

## Resources

- **MCP Documentation**: https://modelcontextprotocol.io/
- **MCP Servers Repo**: https://github.com/modelcontextprotocol/servers
- **Building MCP Servers**: https://modelcontextprotocol.io/docs/building-servers
- **Claude Desktop**: https://claude.ai/download

---

## FAQ

**Q: Do I need MCP servers for AIDE to work?**  
A: No, but they make AIDE much more powerful. Filesystem and Git servers are highly recommended.

**Q: Can I use MCP with Claude Code (CLI)?**  
A: MCP is primarily for Claude Desktop. Claude Code has its own file access.

**Q: Are MCP servers secure?**  
A: Yes, if configured properly. Only grant access to necessary directories and use minimal permissions.

**Q: Can I disable MCP servers?**  
A: Yes, just remove them from `claude_desktop_config.json` and restart Claude Desktop.

**Q: Do MCP servers work on Windows?**  
A: Yes, MCP servers work on Windows. Use Windows paths in config.

**Q: Can I create my own MCP server?**  
A: Yes! See the [MCP documentation](https://modelcontextprotocol.io/docs/building-servers) for guides.

---

**With MCP servers, AIDE becomes a true agentic system with real-world capabilities!** 🚀