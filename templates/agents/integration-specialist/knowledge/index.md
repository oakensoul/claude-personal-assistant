---
agent: integration-specialist
updated: "2025-10-04"
knowledge_count: 0
memory_type: "agent-specific"
---

# Knowledge Index for Integration Specialist

This index catalogs all knowledge resources available to the integration-specialist agent. These act as persistent memories that the agent can reference during execution for Obsidian integration, MCP (Model Context Protocol), GNU Stow, and git workflow automation.

## Local Knowledge Files

### Core Concepts
<!-- Add core concept files here as they are created -->

### Patterns
<!-- Add pattern files here as they are created -->

### Decisions
<!-- Add decision files here as they are created -->

## External Documentation Links

### Obsidian Integration

- [Obsidian API](https://github.com/obsidianmd/obsidian-api) - Official Obsidian plugin API
- [Dataview Plugin](https://blacksmithgu.github.io/obsidian-dataview/) - Query and display data from notes
- [Templater Plugin](https://silentvoid13.github.io/Templater/) - Advanced template system for Obsidian
- [QuickAdd Plugin](https://quickadd.obsidian.guide/) - Automation and macro system
- [Obsidian URI](https://help.obsidian.md/Advanced+topics/Using+obsidian+URI) - URL scheme for external integration

### Model Context Protocol (MCP)

- [MCP Specification](https://modelcontextprotocol.io/introduction) - Official MCP protocol docs
- [MCP Servers](https://github.com/modelcontextprotocol/servers) - Reference server implementations
- [Claude Desktop MCP](https://modelcontextprotocol.io/quickstart/user) - Claude Desktop integration guide
- [Building MCP Servers](https://modelcontextprotocol.io/quickstart/server) - Server development guide

### GNU Stow

- [GNU Stow Manual](https://www.gnu.org/software/stow/manual/stow.html) - Official Stow documentation
- [Dotfiles with Stow](https://brandon.invergo.net/news/2012-05-26-using-gnu-stow-to-manage-your-dotfiles.html) - Dotfile management patterns
- [Stow Best Practices](https://alexpearce.me/2016/02/managing-dotfiles-with-stow/) - Common patterns and pitfalls
- [Multiple Stow Directories](https://venthur.de/2021-12-19-managing-dotfiles-with-stow.html) - Advanced Stow configurations

### Git Automation

- [Git Hooks](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks) - Automation with git hooks
- [Git Configuration](https://git-scm.com/docs/git-config) - Git config reference
- [Worktrees](https://git-scm.com/docs/git-worktree) - Multiple working directories
- [Git Attributes](https://git-scm.com/docs/gitattributes) - File-specific git behavior

### Shell Integration

- [Shell RC Files](https://blog.flowblok.id.au/2013-02/shell-startup-scripts.html) - Shell initialization order
- [Bash Completion](https://github.com/scop/bash-completion) - Command completion system
- [Zsh Completion](https://github.com/zsh-users/zsh-completions) - Zsh completion functions
- [Environment Modules](https://modules.readthedocs.io/en/latest/) - Dynamic environment management

### API Integration Patterns

- [REST API Best Practices](https://stackoverflow.blog/2020/03/02/best-practices-for-rest-api-design/) - RESTful design patterns
- [CLI Tool Integration](https://clig.dev/#integration) - Integrating with other CLI tools
- [IPC Patterns](https://beej.us/guide/bgipc/) - Inter-process communication
- [Webhook Patterns](https://webhooks.fyi/) - Event-driven integration

### File Watching & Automation

- [fswatch](https://github.com/emcrisostomo/fswatch) - Cross-platform file change monitor
- [entr](https://github.com/eradman/entr) - Run commands when files change
- [watchman](https://facebook.github.io/watchman/) - File watching service
- [inotify](https://man7.org/linux/man-pages/man7/inotify.7.html) - Linux kernel file monitoring

### Data Synchronization

- [rsync](https://rsync.samba.org/documentation.html) - File synchronization tool
- [unison](https://www.cis.upenn.edu/~bcpierce/unison/) - Bi-directional sync
- [Live Sync for Obsidian](https://github.com/vrtmrz/obsidian-livesync) - Obsidian synchronization
- [Git Sync Patterns](https://stackoverflow.com/questions/4043609/getting-git-to-work-with-a-proxy-server) - Git-based synchronization

## Usage Notes

### When to Add Knowledge

- New integration pattern discovered → Add to patterns section
- Important integration decision made → Record in decisions history
- Useful integration tool found → Add to external links
- API integration pattern developed → Document in patterns
- Workflow automation created → Add to core concepts

### Knowledge Maintenance

- Update this index.md when adding/removing files
- Increment knowledge_count in frontmatter
- Update the `updated` date
- Keep knowledge focused on integration and automation topics
- Link to official documentation rather than duplicating it

### Memory Philosophy

- **CLAUDE.md**: Quick reference for when to use integration-specialist agent (always in context)
- **Knowledge Base**: Detailed integration patterns, API specs, decision history (loaded when agent invokes)
- Both systems work together for efficient context management

## Knowledge Priorities

### High Priority Knowledge

1. Obsidian daily note automation and templating
2. MCP server implementation for AIDA
3. GNU Stow dotfile management patterns
4. Git automation and hook integration
5. Shell RC file integration patterns

### Medium Priority Knowledge

1. File watching and event-driven automation
2. API integration patterns for external tools
3. Data synchronization strategies
4. Cross-platform compatibility for integrations

### Low Priority Knowledge

1. Platform-specific integration details (document as needed)
2. Advanced tool-specific features (focus on core patterns)
3. Generic integration concepts (focus on AIDA-specific needs)
