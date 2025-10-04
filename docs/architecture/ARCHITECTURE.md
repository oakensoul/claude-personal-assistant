---
title: "AIDA Architecture"
description: "Complete technical architecture documentation for the AIDA framework"
category: "architecture"
tags: ["architecture", "system-design", "technical", "framework"]
last_updated: "2025-10-04"
version: "0.1.0"
status: "published"
audience: "developers"
---

# AIDA Architecture

**Agentic Intelligence Digital Assistant - Technical Architecture**

Version: 0.1.0
Last Updated: 2025-10-04

---

## Table of Contents

1. [System Overview](#system-overview)
2. [Core Concepts](#core-concepts)
3. [Directory Structure](#directory-structure)
4. [Component Architecture](#component-architecture)
5. [Data Flow](#data-flow)
6. [Integration Points](#integration-points)
7. [Command System](#command-system)
8. [Security Model](#security-model)

---

## System Overview

AIDA is a conversational operating system layer that sits on top of a user's digital life. Unlike traditional dotfiles (shell scripts and configs), AIDA provides a natural language interface to Claude AI for managing projects, files, tasks, and daily workflows.

### Platform Support

- **Primary**: macOS
- **Supported**: Linux (Ubuntu, Debian, Arch, etc.)
- **Windows**: Via WSL (Windows Subsystem for Linux)

**Note**: AIDA uses bash scripts and expects a Unix-like environment. Windows users should use WSL. Native PowerShell support may be added in future releases if there is strong demand.

### Key Principles

1. **Conversational First**: Natural language over shell commands
2. **Memory Over Execution**: Build context over time, not just run scripts
3. **Personal but Shareable**: Framework is public, configuration is private
4. **Personality-Driven**: User chooses how their assistant behaves

### The Three-Repo Ecosystem

```
claude-personal-assistant (public)
    ↓ installs to
~/.aida/ (framework installation)
    ↓ generates
~/.claude/ (user's personal data - NOT in git)
    ↓ reads
Claude AI (via chat, Claude Code, or API)
```

**Separate but Related:**
```
dotfiles (public templates)
    ↓ stow into ~/
dotfiles-private (private configs)
    ↓ stow into ~/ (overrides public)
```

---

## Core Concepts

### 1. Knowledge Base

**Location**: `~/.claude/knowledge/`

Static documentation about the user's system, procedures, and preferences.

**Files:**
- `system.md` - How the computer is organized
- `procedures.md` - How to perform tasks
- `workflows.md` - When to do things
- `projects.md` - Active project index
- `preferences.md` - Personal preferences

**Purpose**: Provides Claude with reference information that changes rarely.

### 2. Memory System

**Location**: `~/.claude/memory/`

Dynamic, living record of current state and history.

**Files:**
- `context.md` - Current state (updated frequently)
- `decisions.md` - Decision log with rationale
- `history/YYYY-MM.md` - Monthly activity logs

**Purpose**: Provides Claude with current context and historical information.

### 3. Personality System

**Location**: `~/.aida/personalities/` and `~/.claude/config/personality.yaml`

Defines how the assistant communicates and behaves.

**Structure:**
```yaml
assistant:
  name: "JARVIS"
  formal_name: "Just A Rather Very Intelligent System"

personality:
  tone: "snarky"
  formality: "casual"
  humor: true
  encouragement: "tough-love"

responses:
  greeting: "Good morning, sir. Ready to disappoint me again?"
  task_complete: "Excellent. Only {time_delta} longer than estimated."
  # ... more response templates
```

**Purpose**: Makes the assistant feel personal and unique to each user.

### 4. Agent System

**Location**: `~/.claude/agents/`

Role-based behavior definitions for specialized tasks.

**Agents:**
- `secretary.md` - Daily workflow management
- `file-manager.md` - File organization
- `dev-assistant.md` - Coding assistance

**Purpose**: Provides focused, specialized behaviors for different types of tasks.

### 5. Command System

Structured commands that Claude recognizes as triggers for specific procedures.

**Format**: `{assistant-name}-{action}` or `{assistant-name} {action}`

**Examples:**
- `jarvis-start-day` or `jarvis start day`
- `alfred-cleanup-downloads` or `alfred cleanup downloads`

**Purpose**: Provides predictable, discoverable interface while maintaining conversational flexibility.

---

## Directory Structure

### Framework Repository (`claude-personal-assistant`)

```
claude-personal-assistant/
├── README.md                       # User-facing documentation
├── LICENSE
├── .gitignore
│
├── docs/                           # All documentation
│   ├── README.md                  # Documentation index
│   ├── architecture/              # Technical architecture
│   │   ├── ARCHITECTURE.md       # Complete system architecture
│   │   ├── data-flow.md          # Data flow diagrams
│   │   ├── component-details.md  # Component deep dives
│   │   └── integration-points.md # Integration documentation
│   ├── user-guide/                # End-user documentation
│   │   ├── getting-started.md    # Quick start
│   │   ├── installation.md       # Installation guide
│   │   ├── daily-workflows.md    # Daily usage
│   │   ├── commands.md           # Command reference
│   │   ├── personalities.md      # Personality guide
│   │   ├── customization.md      # Customization guide
│   │   ├── obsidian-integration.md
│   │   ├── troubleshooting.md
│   │   └── faq.md
│   ├── developer-guide/           # Developer documentation
│   │   ├── ROADMAP.md            # Development roadmap
│   │   ├── CONTRIBUTING.md       # Contributing guide
│   │   ├── development-setup.md  # Dev environment setup
│   │   ├── adding-features.md    # Feature development
│   │   ├── testing.md            # Testing guidelines
│   │   └── code-style.md         # Code style guide
│   ├── project-agents/            # Project agent documentation
│   │   ├── README.md             # Overview
│   │   ├── react.md              # React agent guide
│   │   ├── nextjs.md             # Next.js agent guide
│   │   ├── golang.md             # Go agent guide
│   │   ├── python.md             # Python agent guide
│   │   └── creating-agents.md    # Custom agent creation
│   └── examples/                  # Example configurations
│       ├── personalities/
│       ├── workflows/
│       └── integrations/
│
├── install.sh                      # Installation script
├── update.sh                       # Update script
│
├── templates/                      # Shareable templates
│   ├── CLAUDE.md.template         # Main config template
│   ├── cli-tool.template          # CLI tool template
│   ├── knowledge/
│   │   ├── system.md.template
│   │   ├── procedures.md.template
│   │   ├── workflows.md.template
│   │   ├── projects.md.template
│   │   └── preferences.md.template
│   ├── agents/
│   │   ├── secretary.md.template
│   │   ├── file-manager.md.template
│   │   └── dev-assistant.md.template
│   └── memory/
│       └── context.md.template
│
├── personalities/                  # Pre-built personalities
│   ├── jarvis.yaml
│   ├── alfred.yaml
│   ├── friday.yaml
│   ├── zen.yaml
│   └── drill-sergeant.yaml
│
├── project-agents/                 # Project-specific agents
│   ├── README.md                  # Agent system overview
│   ├── _template/                 # Template for new agents
│   │   └── CLAUDE.md
│   ├── react/
│   │   └── CLAUDE.md
│   ├── nextjs/
│   │   └── CLAUDE.md
│   ├── golang/
│   │   └── CLAUDE.md
│   ├── python/
│   │   └── CLAUDE.md
│   ├── nodejs/
│   │   └── CLAUDE.md
│   ├── typescript/
│   │   └── CLAUDE.md
│   └── docker/
│       └── CLAUDE.md
│
└── workflows/                      # Optional automation scripts
    ├── backup-example.sh
    └── cleanup-example.sh
```

### User Installation (`~/.aida/` and `~/.claude/`)

```
~/
├── CLAUDE.md                       # Main entry point (generated)
├── .aidaignore                    # Ignore patterns
│
├── .aida/                          # Framework (from repo)
│   ├── README.md
│   ├── install.sh
│   ├── templates/
│   ├── personalities/
│   └── workflows/
│
├── .claude/                        # User's personal config (gitignored)
│   ├── config/
│   │   ├── personality.yaml       # Chosen personality
│   │   └── system.yaml            # System settings
│   │
│   ├── knowledge/                 # User's knowledge base
│   │   ├── system.md
│   │   ├── procedures.md
│   │   ├── workflows.md
│   │   ├── projects.md
│   │   └── preferences.md
│   │
│   ├── memory/                    # User's memory
│   │   ├── context.md
│   │   ├── decisions.md
│   │   └── history/
│   │       └── 2025-10.md
│   │
│   └── agents/                    # User's agents
│       ├── secretary.md
│       ├── file-manager.md
│       └── dev-assistant.md
│
└── bin/
    └── jarvis                      # Personalized CLI tool (or alfred, friday, etc.)
```

### User's Folder Structure (Managed by AIDA)

```
~/
├── Development/
│   ├── personal/
│   ├── work/
│   ├── experiments/
│   ├── forks/
│   └── sandbox/
│
├── Knowledge/
│   └── Obsidian-Vault/
│       ├── Daily/
│       │   ├── Templates/         # Symlinked from AIDA
│       │   └── YYYY-MM-DD.md
│       ├── Projects/
│       │   ├── Active/
│       │   ├── Backlog/
│       │   └── Archive/
│       └── Index/
│           └── Dashboard.md
│
├── Media/
│   ├── Screenshots/
│   ├── Recordings/
│   └── Archive/
│
├── Documents/
│   ├── Personal/
│   ├── Work/
│   ├── Templates/
│   └── Archive/
│
├── Downloads/                      # Managed by AIDA
└── Desktop/                        # Keep minimal
```

### 8. Project-Specific Agents

**Location**: `project-agents/` in framework, installed to project directories

**Purpose**: Pre-built agent configurations for specific tech stacks and project types.

**Structure:**
```
project-agents/
├── README.md
├── react/
│   └── CLAUDE.md              # React project agent
├── nextjs/
│   └── CLAUDE.md              # Next.js project agent
├── golang/
│   └── CLAUDE.md              # Go project agent
├── python/
│   └── CLAUDE.md              # Python project agent
└── nodejs/
    └── CLAUDE.md              # Node.js project agent
```

**Installation:**
```bash
cd ~/Development/personal/my-react-app/
jarvis agent install react
```

**What it does:**
1. Copies `project-agents/react/CLAUDE.md` to project directory
2. Merges with existing project CLAUDE.md if present
3. Provides tech-stack-specific guidance

**Example React Agent:**
```markdown
# React Project Agent

## Project Type: React Application

**Tech Stack**: React, JavaScript/TypeScript

## Best Practices

### Component Structure
- Use functional components with hooks
- Keep components small and focused
- Separate business logic from presentation
- Use composition over inheritance

### State Management
- useState for local state
- useContext for shared state
- Consider Redux/Zustand for complex state
- Avoid prop drilling

### Common Patterns
- Custom hooks for reusable logic
- HOCs for cross-cutting concerns
- Render props when appropriate
- Error boundaries for error handling

## Code Conventions

### File Structure
```
src/
├── components/
│   ├── common/        # Reusable components
│   └── features/      # Feature-specific components
├── hooks/             # Custom hooks
├── context/           # Context providers
├── utils/             # Utility functions
└── styles/            # Global styles
```

### Naming Conventions
- PascalCase for components: `UserProfile.jsx`
- camelCase for functions: `getUserData()`
- UPPER_CASE for constants: `API_URL`

## Development Commands

### Start Development
```bash
npm run dev
```

### Testing
```bash
npm test              # Run tests
npm run test:watch   # Watch mode
npm run test:coverage # Coverage report
```

### Building
```bash
npm run build        # Production build
npm run preview      # Preview build
```

## Common Issues

### Problem: Component re-renders too often
**Solution**: Use React.memo, useMemo, or useCallback

### Problem: State updates don't reflect
**Solution**: Remember setState is async, use functional updates

## Project-Specific Commands

When working in this React project, I understand:
- Component patterns and anti-patterns
- React 18 features (Suspense, Transitions, etc.)
- Performance optimization techniques
- Testing best practices with React Testing Library
- Common library patterns (React Router, React Query, etc.)
```

**Benefits:**
- ✅ Tech-stack-specific guidance
- ✅ Best practices for that framework
- ✅ Common patterns and anti-patterns
- ✅ Project structure conventions
- ✅ Testing and deployment guidance
- ✅ Quick reference for common commands

**User Workflow:**
```
User: "Install React agent in this project"
jarvis agent install react

User: "How should I structure this component?"
Claude: [Reads project CLAUDE.md with React agent]
        "For this React project, I recommend using a functional 
        component with hooks..."
```

---

## Component Architecture

### 1. Installation System

**File**: `install.sh`

**Responsibilities:**
- Prompt user for assistant name
- Prompt for personality selection
- Create directory structure
- Copy templates to `~/.claude/`
- Generate personalized `CLAUDE.md`
- Create CLI tool with assistant's name
- Add CLI tool to PATH
- Run first-time setup

**Key Functions:**
```bash
prompt_assistant_name()    # Get user's choice
prompt_personality()       # Select personality
create_directories()       # Set up ~/.claude/
copy_templates()          # Populate with templates
generate_claude_md()      # Personalize main config
create_cli_tool()         # Generate CLI
setup_path()              # Add to PATH
```

**Modes:**
- Normal install: Copies framework to `~/.aida/`
- Dev mode (`--dev`): Symlinks to development directory

### 2. Personality System

**Files**: `personalities/*.yaml` and `~/.claude/config/personality.yaml`

**Responsibilities:**
- Define communication style
- Provide response templates
- Set behavioral parameters

**Structure:**
```yaml
assistant:
  name: string
  formal_name: string

personality:
  tone: enum[snarky, professional, enthusiastic, zen, direct]
  formality: enum[formal, casual, friendly]
  verbosity: enum[concise, detailed, minimal]
  humor: boolean
  encouragement: enum[supportive, tough-love, neutral, demanding]

responses:
  greeting: template_string
  farewell: template_string
  task_complete: template_string
  procrastination: template_string
  file_mess: template_string
  # ... more responses

preferences:
  address_user_as: string
  emoji_usage: enum[none, minimal, frequent]
```

**Template Variables:**
- `{user.name}` - User's name
- `{project}` - Project name
- `{duration}` - Time elapsed
- `{count}` - Number of items
- `{folder}` - Folder name
- `{time_delta}` - Difference from estimate

### 3. Knowledge Management System

**Location**: `~/.claude/knowledge/`

**Components:**

#### system.md
Documents the user's computer organization:
- Folder structure and conventions
- File naming patterns
- Ignore patterns
- Tool locations
- NAS mounts

#### procedures.md
Defines how to perform tasks:
- Command procedures (aide-start-day, etc.)
- File organization rules
- Cleanup procedures
- Backup processes

#### workflows.md
Describes when to do things:
- Daily routines
- Weekly maintenance
- Monthly reviews
- Project workflows

#### projects.md
Indexes active projects:
- Project list with status
- Progress tracking
- Links to resources
- Next actions

#### preferences.md
Personal preferences:
- Communication style details
- Tool preferences
- Work hours
- Personal context

### 4. Memory Management System

**Location**: `~/.claude/memory/`

**Components:**

#### context.md
Current state (frequently updated):
```markdown
# Current Context

Last updated: YYYY-MM-DD HH:MM

## Active Work
- Project Alpha: API integration, 80% complete
- Project Beta: Frontend refactor, 35% complete

## Recent Decisions
- 2025-10-03: Chose PostgreSQL over MongoDB
- 2025-10-02: Refactoring auth before new features

## Pending Items
- Code review for teammate (low priority)
- Deploy Alpha to staging (blocked on testing)

## System State
- Downloads: 47 files
- Last cleanup: 2025-10-01
- Disk space: 456GB free
- Last backup: 2025-10-03
```

#### decisions.md
Decision log with rationale:
```markdown
# Decision Log

## 2025-10-03: Database Choice

**Decision**: Use PostgreSQL instead of MongoDB

**Rationale**:
- Need ACID compliance
- Complex relational queries
- Better tooling support
- Team experience

**Alternatives Considered**:
- MongoDB (too flexible, schema issues)
- MySQL (considered but Postgres has better features)
```

#### history/YYYY-MM.md
Monthly activity log (auto-generated):
```markdown
# October 2025

## 2025-10-04
- Completed Project Alpha API integration
- Fixed Project Beta auth bug
- Updated documentation

## 2025-10-03
- Researched database options
- Decided on PostgreSQL
- Started migration planning
```

### 5. Agent System

**Location**: `~/.claude/agents/`

**Structure:**
```markdown
# Agent Name

## Role
Brief description of agent's purpose

## Responsibilities
- Responsibility 1
- Responsibility 2

## Knowledge Sources
- Files this agent reads
- Data this agent uses

## Behaviors
### Trigger Pattern
When to activate this behavior

### Procedure
Step-by-step process

### Example Output
What the user sees
```

**Agents:**

- **Secretary**: Daily workflow, planning, summaries
- **File Manager**: Organization, cleanup, maintenance
- **Dev Assistant**: Coding help, git operations, deployment

### 6. Command System

**Implementation**: Documented in `~/CLAUDE.md` and `~/.claude/knowledge/procedures.md`

**Command Format:**
```
{assistant-name}-{verb}-{object}
or
{assistant-name} {verb} {object}
```

**Examples:**
- `jarvis-start-day` → `jarvis start day`
- `jarvis-cleanup-downloads` → `jarvis cleanup downloads`
- `jarvis-project-status Alpha` → `jarvis project status Alpha`

**Command Categories:**

1. **File Management**
   - cleanup-downloads
   - clear-desktop
   - organize-screenshots
   - file-this

2. **Daily Workflow**
   - start-day
   - end-day
   - status
   - focus

3. **Project Management**
   - project-status
   - project-update
   - projects-list
   - blockers

4. **Memory & Context**
   - remember
   - recall
   - context

5. **System Operations**
   - backup-vault
   - mount-nas
   - system-health

### 7. CLI Tool

**Location**: `~/bin/{assistant-name}`

**Structure:**
```bash
#!/bin/bash

ASSISTANT_NAME="jarvis"  # Or alfred, friday, etc.
AIDE_HOME="$HOME/.claude"

# Command routing
case "$1" in
  "start-day"|"start"|"morning")
    # Trigger start-day procedure
    ;;
  "end-day"|"end"|"eod")
    # Trigger end-day procedure
    ;;
  "status")
    # Show quick status
    ;;
  "cleanup")
    case "$2" in
      "downloads")
        # Trigger downloads cleanup
        ;;
      "desktop")
        # Trigger desktop clear
        ;;
    esac
    ;;
  *)
    # Pass to Claude as natural language
    echo "Processing: $@"
    ;;
esac
```

**Capabilities:**
- Route structured commands
- Pass natural language to Claude
- Quick status checks
- Configuration management

---

## Data Flow

### Installation Flow

```
User runs install.sh
    ↓
Prompt for name & personality
    ↓
Create ~/.claude/ structure
    ↓
Copy templates from ~/.aida/templates/
    ↓
Replace ${ASSISTANT_NAME} in templates
    ↓
Apply personality settings
    ↓
Generate CLAUDE.md
    ↓
Create CLI tool: ~/bin/{name}
    ↓
Add to PATH
    ↓
Installation complete
```

### Command Execution Flow

```
User types command
    ↓
{assistant-name}-{action} or {assistant-name} {action}
    ↓
Claude reads ~/CLAUDE.md
    ↓
Claude identifies command in procedures.md
    ↓
Claude reads relevant knowledge files
    ↓
Claude reads memory/context.md for current state
    ↓
Claude executes procedure steps
    ↓
Claude updates memory if needed
    ↓
Claude responds to user
```

### Knowledge Access Flow

```
Claude starts conversation
    ↓
Read ~/CLAUDE.md (main config)
    ↓
Load personality from ~/.claude/config/personality.yaml
    ↓
Read ~/.claude/knowledge/* (as needed)
    ↓
Read ~/.claude/memory/context.md (current state)
    ↓
Process user request
    ↓
Execute actions
    ↓
Update memory if significant
```

### Memory Update Flow

```
Significant event occurs
    ↓
Claude reads current context.md
    ↓
Claude updates relevant sections:
  - Active Work (project status)
  - Recent Decisions (if decision made)
  - Pending Items (add/remove items)
  - System State (if changed)
    ↓
Claude writes updated context.md
    ↓
If end-of-day, append to history/YYYY-MM.md
```

---

## Integration Points

### 1. Claude AI Integration

**Methods:**
- Chat interface (manual, via Claude.ai)
- Claude Desktop (with MCP servers - recommended)
- Claude Code (automated, CLI)
- API (programmatic)

**Recommended Setup: Claude Desktop + MCP Servers**

Essential MCP servers for AIDA:
- **Filesystem** - Read/write AIDA config and memory files
- **Git** - Commit changes to dotfiles and repos
- **GitHub** - Create issues, manage PRs
- **Memory** - Persistent context across sessions

See [MCP Servers Guide](../user-guide/mcp-servers.md) for complete setup.

**Context Loading:**
Claude should be pointed to:
1. `~/CLAUDE.md` (main entry point)
2. `~/.claude/knowledge/` (system knowledge)
3. `~/.claude/memory/context.md` (current state)

**With MCP Filesystem Server:**
Claude can automatically read these files without manual copying.

**Best Practice:**
```
User: "jarvis-start-day"

Claude automatically (via MCP):
1. Reads ~/CLAUDE.md
2. Identifies command in procedures.md
3. Reads memory/context.md for current state
4. Updates daily note in Obsidian vault
5. Updates memory with today's plan
6. Commits changes via MCP Git server
```

### 2. Obsidian Integration

**Integration Method**: File-based, via templates

**Files:**
- Daily notes: `~/Knowledge/Obsidian-Vault/Daily/YYYY-MM-DD.md`
- Project notes: `~/Knowledge/Obsidian-Vault/Projects/Active/*.md`
- Dashboard: `~/Knowledge/Obsidian-Vault/Index/Dashboard.md`

**Templates:**
AIDA provides templates that Obsidian uses:
```
~/.aida/templates/obsidian/
├── Daily-Note.md
├── Project.md
└── Dashboard.md
```

**Workflow:**
1. User: "jarvis-start-day"
2. Claude creates/updates today's daily note
3. Claude reads project notes
4. Claude suggests priorities
5. Updates dashboard if needed

### 3. Dotfiles Integration

**Integration Method**: GNU Stow symlinks

**Setup:**
```bash
# Public dotfiles (base layer)
cd ~/dotfiles
stow aida  # Stows aida/ package to ~/

# Private dotfiles (override layer)
cd ~/dotfiles-private
stow aida  # Stows aida/ package to ~/ (overrides public)
```

**File Precedence:**
```
dotfiles/aida/CLAUDE.md.template
    ↓ (public, generic)
dotfiles-private/aida/CLAUDE.md
    ↓ (private, actual config - wins!)
~/CLAUDE.md
    ↓ (symlink to private version)
```

### 4. Filesystem Integration

**Managed Folders:**
- `~/Downloads/` - Monitored for cleanup
- `~/Desktop/` - Monitored to keep minimal
- `~/Development/` - Project tracking
- `~/Knowledge/` - Obsidian vault
- `~/Documents/` - Document organization

**Operations:**
- File organization (move, rename, archive)
- Directory health checks
- Disk space monitoring
- Backup operations

---

## Command System

### Command Structure

**Full Format:**
```
{assistant-name}-{verb}-{object}-{modifier}
```

**Examples:**
- `jarvis-cleanup-downloads`
- `jarvis-project-status-alpha`
- `jarvis-remember-decision`

**Natural Format:**
```
{assistant-name} {verb} {object} {modifier}
```

**Examples:**
- `jarvis cleanup downloads`
- `jarvis project status alpha`
- `jarvis remember "use PostgreSQL"`

### Command Registry

Stored in `~/CLAUDE.md` and `~/.claude/knowledge/procedures.md`

**Format:**
```markdown
## Command: aida-start-day

**Aliases**: start-day, start, morning

**Trigger**: User says "{assistant-name}-start-day" or "{assistant-name} start day"

**Description**: Morning routine - review yesterday, plan today

**Procedure**:
1. Read ~/.claude/memory/context.md
2. Read today's Obsidian note
3. List active projects
4. Suggest priorities
5. Update daily note
6. Update memory

**Example Output**:
[Example here]
```

### Command Discovery

Users can discover commands by:
1. Reading `~/CLAUDE.md`
2. Running `{assistant-name} help`
3. Asking Claude "what commands do you support?"

---

## Security Model

### Public vs Private

**Public (in GitHub):**
- Framework code
- Templates
- Personalities
- Documentation

**Private (NOT in git):**
- `~/.claude/` (all user data)
- `~/CLAUDE.md` (after personalization)
- Memory files
- Personal knowledge
- API keys

### Sensitive Data Handling

**Never Commit:**
- API keys
- Passwords
- Personal information
- Project details
- Memory/history

**Gitignore Pattern:**
```gitignore
# In framework repo
.claude/
CLAUDE.md
*.local
*_personal.md
config/*.yaml
memory/
knowledge/system.md
knowledge/projects.md
```

### Multi-User Considerations

Each user has completely separate:
- `~/.claude/` directory
- Personality config
- Memory
- Knowledge base

Framework is shared, data is isolated.

---

## Extension Points

### Adding New Personalities

1. Create `personalities/new-personality.yaml`
2. Define tone, responses, preferences
3. Test with `./install.sh`
4. Submit PR

### Adding New Commands

1. Add to `templates/procedures.md.template`
2. Define trigger, procedure, output
3. Update `templates/CLAUDE.md.template`
4. Test with Claude
5. Document in README

### Adding New Agents

1. Create `templates/agents/new-agent.md.template`
2. Define role, responsibilities, behaviors
3. User can customize in `~/.claude/agents/`
4. Reference in procedures

### Custom Workflows

Users can add custom automation:
1. Create script in `~/.claude/workflows/`
2. Document in `knowledge/procedures.md`
3. Claude can invoke when appropriate

---

## Performance Considerations

### Context Size

Claude has token limits. Keep documents focused:
- `CLAUDE.md`: < 2000 tokens
- Each knowledge file: < 1000 tokens
- Memory/context: < 1500 tokens

**Total context budget**: ~5000 tokens for AIDA system files

### Update Frequency

- **Context**: Updated multiple times per day
- **Knowledge**: Updated weekly/monthly
- **History**: Appended daily
- **Decisions**: Appended as needed

### File Operations

- Most operations are read-only
- Writes only to memory and history
- Never modify knowledge unless explicitly requested
- Backup before any destructive operations

---

## Error Handling

### Missing Files

If expected files don't exist:
1. Check if AIDA is installed: `~/.claude/` exists?
2. Check if templates were copied
3. Offer to run `install.sh` again

### Corrupted Memory

If `context.md` is corrupted:
1. Load from backup if available
2. Regenerate from history
3. Ask user for current state

### Command Not Found

If command not recognized:
1. Check `procedures.md` for typos
2. Suggest similar commands
3. Fall back to natural language processing

---

## Future Architecture Considerations

### Multi-Device Sync

Options for syncing `~/.claude/` across devices:
- Private git repo
- Cloud storage (Dropbox, iCloud)
- Custom sync service

### API Integration

Direct Claude API integration:
- CLI tool calls API directly
- Faster than copy/paste
- Better for automation

### Plugin System

Allow third-party extensions:
- Custom agents
- Custom commands
- Integration with other tools

### Web Interface

Potential web dashboard:
- View memory/context
- Manage projects
- Run commands
- Configure settings

---

## Glossary

- **AIDA**: The framework name (Agentic Intelligence Digital Assistant)
- **Assistant**: The personalized instance (JARVIS, Alfred, etc.)
- **Framework**: The public code repository
- **Installation**: User's `~/.aida/` and `~/.claude/` setup
- **Knowledge**: Static reference documentation
- **Memory**: Dynamic state and history
- **Personality**: Communication style and behavior
- **Agent**: Role-based behavior specialization
- **Command**: Structured trigger for procedures
- **Procedure**: Step-by-step process for tasks

---

**This architecture is a living document. Update as the system evolves.**