---
title: "AIDE Requirements Document"
description: "Detailed requirements and specifications for the AIDE framework"
category: "reference"
tags: ["requirements", "specifications", "architecture", "planning"]
last_updated: "2025-10-04"
version: "0.1.0"
status: "draft"
audience: "developers"
---

# AIDE Requirements Document

**Project**: AIDE - Agentic Intelligence Digital Assistant
**Repository**: `claude-personal-assistant`
**Version**: 0.1.0
**Status**: Draft
**Last Updated**: 2025-10-04

---

## 1. Project Overview

### 1.1 Vision

Create a conversational, agentic operating system for managing digital life. Unlike traditional dotfiles (shell configurations), AIDE provides a natural language interface to manage projects, files, tasks, and daily workflows through Claude AI.

**Repository Name**: `claude-personal-assistant` (for discoverability)
**Project Name**: AIDE (what users call it)

### 1.2 Core Philosophy

- **Conversational over Command-line**: Talk naturally instead of memorizing commands
- **Memory over Execution**: AI builds context over time instead of just running scripts
- **Personal but Shareable**: Framework is open-source, but configuration and memory are private
- **Personality-Driven**: Users choose how their AI assistant behaves

### 1.3 Target Users

- Developers managing multiple projects
- Knowledge workers with complex file structures
- Anyone wanting AI assistance for daily digital tasks
- People who forget where they put things (all of us)

---

## 2. Core Concepts

### 2.1 The Shift from Dotfiles

**Traditional Dotfiles**:

```bash
alias eod="cd ~/notes && ./end-of-day.sh"
```

**AIDE**:

```text
You: "End of day summary"
Assistant: [Reads your daily notes, understands context,
            summarizes work, prepares tomorrow's focus]
```

### 2.2 Key Components

1. **Knowledge Base**: Documentation about your system, procedures, preferences
2. **Memory**: Living record of current state, decisions, history
3. **Agents**: Role-based behaviors (secretary, file manager, dev assistant)
4. **Personality**: How the AI communicates with you
5. **Tools**: Optional scripts that agents can use when needed

---

## 3. System Requirements

### 3.1 Platform Support

- **Primary**: macOS (initial target)
- **Future**: Linux, Windows (WSL)

### 3.2 Dependencies

- Git (for version control)
- Shell environment (bash/zsh)
- Claude AI access (via chat interface, API, or Claude Code)
- Optional: Obsidian (for knowledge management)

### 3.3 Directory Structure

**CRITICAL DESIGN DECISION**: AIDE lives at `~/.aida/` (hidden dotfile folder at HOME level) so Claude can naturally access all your folders without complex path navigation. The main config `~/AIDE.md` serves as an entry point.

```text
~/                              # Home directory (Claude's natural starting point)
├── CLAUDE.md                  # Main configuration (Claude Code finds this automatically!)
├── .aideignore               # Global ignore patterns (like .gitignore)
│
├── .aida/                     # AIDA framework (hidden, at HOME level)
│   ├── README.md             # Framework documentation
│   ├── LICENSE
│   ├── install.sh            # Installation script
│   ├── update.sh             # Update script
│   ├── aida                  # CLI tool (symlinked to PATH)
│   │
│   ├── config/               # Configuration
│   │   ├── personality.yaml # User's personality config
│   │   └── system.yaml      # System paths & settings
│   │
│   ├── knowledge/            # User's knowledge base (gitignored)
│   │   ├── system.md        # How your system is organized
│   │   ├── procedures.md    # How to do recurring tasks
│   │   ├── projects.md      # Active projects index
│   │   └── preferences.md   # Personal preferences
│   │
│   ├── memory/               # User's memory (gitignored)
│   │   ├── context.md       # Current state
│   │   ├── decisions.md     # Decision log
│   │   └── history/
│   │       └── 2025-10.md
│   │
│   ├── agents/               # Agent definitions
│   │   ├── templates/       # Shareable templates (in git)
│   │   │   ├── secretary.md
│   │   │   ├── file-manager.md
│   │   │   └── dev-assistant.md
│   │   └── user/            # User's customized agents (gitignored)
│   │
│   ├── personalities/        # Pre-built personality packs (in git)
│   │   ├── jarvis.yaml
│   │   ├── alfred.yaml
│   │   ├── friday.yaml
│   │   ├── zen.yaml
│   │   └── drill-sergeant.yaml
│   │
│   ├── workflows/            # Automation scripts (in git)
│   │   ├── cleanup-downloads.sh
│   │   ├── backup-obsidian.sh
│   │   └── weekly-maintenance.sh
│   │
│   └── .git/                # Git repo for framework only
│       └── .gitignore       # Ignores personal data (knowledge/, memory/, etc.)
│
├── Downloads/                # Claude can see this naturally
├── Development/              # Claude can see this naturally
│   ├── personal/
│   │   └── project-a/
│   │       └── CLAUDE.md    # Project-specific guidance
│   └── work/
├── Knowledge/                # Claude can see this naturally
│   └── Obsidian-Vault/
└── Documents/                # Claude can see this naturally
```

**Why this structure:**

- `~/.aida/` at HOME level = Claude can access ALL folders with simple paths
- Hidden folder (`.aida/`) = Follows dotfile convention, stays out of the way
- `~/AIDE.md` = Visible entry point, like a README
- Git repo is `.aida/` itself = Framework is version-controlled
- Personal data in `.aida/knowledge/`, `.aida/memory/` = Gitignored
- Natural paths: `Downloads/`, not `../Downloads/` ✅

### 3.4 User Directory Structure (Created by AIDA)

```text
~/
├── aida/                      # AIDA framework
├── Knowledge/                 # Obsidian vault
│   └── Obsidian-Vault/
│       ├── Daily/
│       │   └── Templates/     # Symlinked from aida
│       ├── Projects/
│       │   ├── Active/
│       │   ├── Backlog/
│       │   └── Archive/
│       └── Index/
│           └── Dashboard.md
├── Development/
│   ├── personal/
│   ├── work/
│   ├── experiments/
│   ├── forks/
│   └── sandbox/
├── Media/
│   ├── Screenshots/
│   ├── Recordings/
│   └── Archive/
├── Documents/
│   ├── Personal/
│   ├── Work/
│   ├── Templates/
│   └── Archive/
├── Downloads/                 # Managed by AIDE
└── Desktop/                   # Keep minimal
```

---

## 4. Functional Requirements

### 4.1 Installation & Setup

**FR-1.1**: First-time installation wizard

- Clone repository
- Run `./install.sh`
- Choose personality
- Set user preferences
- Create directory structure
- Generate initial knowledge base

**FR-1.2**: Personality selection

- Interactive menu to choose from pre-built personalities
- Option to customize existing personality
- Ability to create custom personality from scratch
- Switch personalities at any time

**FR-1.3**: System configuration

- Set user name, timezone, work hours
- Define folder structure preferences
- Configure NAS mounts (if applicable)
- Set up Obsidian vault location

### 4.2 Knowledge Management

**FR-2.1**: System knowledge

- Document folder structure and conventions
- Define file organization rules
- Specify ignore patterns (like .gitignore)
- Describe how the system is set up

**FR-2.2**: Procedures documentation

- Common workflows (cleanup, backup, maintenance)
- File handling rules (where to save what)
- Project setup procedures
- Deployment processes

**FR-2.3**: Project tracking

- Active projects list with status
- Project templates
- Links to related resources
- Progress tracking

**FR-2.4**: Preferences

- Communication style preferences
- Tool preferences
- Workflow preferences
- Personal context

### 4.3 Memory System

**FR-3.1**: Context tracking

- Current state of all active projects
- Recent decisions and rationale
- Pending items and blockers
- System state (disk space, updates needed)

**FR-3.2**: History logging

- Automated daily/weekly activity logs
- Project milestones
- Decisions archive
- System changes

**FR-3.3**: Memory updates

- AI automatically updates context after conversations
- User can manually update context
- History is automatically appended
- Old context archived periodically

### 4.4 Agent Behaviors

**FR-4.1**: Secretary Agent

- Daily workflow management
- Review yesterday, suggest today's focus
- End of day summaries
- Weekly/monthly reviews
- Task tracking and reminders

**FR-4.2**: File Manager Agent

- Monitor folder states
- Suggest cleanups when needed
- Auto-organize based on rules
- Archive old files
- Disk space monitoring

**FR-4.3**: Dev Assistant Agent

- Project context awareness
- Code workflow assistance
- Git operations guidance
- Deployment help
- Documentation updates

**FR-4.4**: Custom Agents

- Users can define their own agents
- Agent templates provided
- Agents can reference knowledge and memory
- Agents can invoke tools

### 4.5 Obsidian Integration

**FR-5.1**: Daily notes

- Template-based daily notes
- Automatic creation
- Link to previous/next day
- Project status updates
- Work logging

**FR-5.2**: Project notes

- Project templates
- Progress tracking
- Task lists
- Timeline tracking
- Decision logging

**FR-5.3**: Dashboard

- Overview of active work
- Recent activity
- Quick links to common notes
- Status summaries

### 4.6 File & Folder Management

**FR-6.1**: Downloads management

- Automated cleanup suggestions
- Archive old files
- Reorganize based on content type
- Delete temporary files

**FR-6.2**: Screenshot organization

- Move to organized folders
- Rename with timestamps
- Archive old screenshots

**FR-6.3**: Document scanning (NAS integration)

- Naming conventions
- Destination folders based on type
- OCR processing
- Index updates

**FR-6.4**: Application management

- Track installed applications (via Homebrew)
- Cleanup unused apps
- Update tracking
- Brewfile maintenance

### 4.7 Maintenance & Operations

**FR-7.1**: Daily tasks

- Desktop cleanup
- Quick file organization
- Status checks

**FR-7.2**: Weekly tasks

- Downloads cleanup
- System updates
- Backup verification
- Progress review

**FR-7.3**: Monthly tasks

- Disk space analysis
- Application cleanup
- Archive old files
- Deep maintenance

**FR-7.4**: Manual operations

- NAS mount/unmount
- Backup operations
- System diagnostics
- Emergency procedures

---

## 5. Technical Architecture

### 5.1 Core Technologies

**Language**: Shell scripts (bash/zsh) for CLI and automation
**Configuration**: YAML for settings, Markdown for knowledge/memory
**AI Interface**: Claude (via chat, API, or Claude Code)
**Version Control**: Git for framework, .gitignore for personal data

### 5.2 CLI Tool

```bash
aide <command> [options]

Commands:
  init              First-time setup
  personality       Manage personality settings
  knowledge         View/edit knowledge base
  memory            View/update memory
  agent             Manage agents
  tool              Run automation tools
  status            System status check
  help              Show help
```

### 5.3 File Formats

**YAML**: Configuration files (personality, system settings)
**Markdown**: Knowledge, memory, agent definitions
**Shell Scripts**: Automation tools

### 5.4 Data Flow

```text
User Input (Natural Language)
    ↓
Claude AI (reads knowledge + memory)
    ↓
Understanding & Decision
    ↓
Actions (update memory, run tools, respond)
    ↓
User Output (Natural Language)
```

---

## 6. Personality System

### 6.1 Personality Configuration

```yaml
assistant:
  name: "JARVIS"
  formal_name: "Just A Rather Very Intelligent System"

personality:
  tone: "snarky"              # snarky, professional, enthusiastic, zen, direct
  formality: "casual"         # formal, casual, friendly
  verbosity: "concise"        # concise, detailed, minimal
  humor: true                 # true/false
  encouragement: "tough-love" # supportive, tough-love, neutral, demanding

responses:
  greeting: "Custom greeting template"
  farewell: "Custom farewell template"
  task_complete: "Custom celebration template"
  procrastination: "Custom reminder template"
  file_mess: "Custom cleanup prompt"

preferences:
  address_user_as: "sir"      # sir, boss, chief, name, nothing
  emoji_usage: "minimal"      # none, minimal, frequent
```

### 6.2 Pre-built Personalities

1. **JARVIS**: Snarky British AI (helpful but judgmental)
2. **Alfred**: Dignified butler (professional, respectful)
3. **FRIDAY**: Enthusiastic helper (upbeat, encouraging)
4. **Sage**: Zen guide (calm, mindful, gentle)
5. **Drill Sergeant**: No-nonsense coach (intense, demanding)

### 6.3 Response Templates

Templates use variables like:

- `{user.name}` - User's name
- `{project}` - Project name
- `{duration}` - Time elapsed
- `{count}` - Number of items
- `{folder}` - Folder name
- `{time_delta}` - Difference from estimate

---

## 7. User Experience Requirements

### 7.1 Conversational Interface

**UX-1.1**: Natural language understanding

- User speaks naturally, no special syntax required
- AI infers intent from context
- Handles ambiguity gracefully

**UX-1.2**: Context awareness

- AI remembers previous conversations
- Understands what "the project" refers to
- Maintains conversation continuity

**UX-1.3**: Personality consistency

- Responses match chosen personality
- Tone is consistent throughout interactions
- Personality can be changed without losing functionality

### 7.2 Common Workflows

**Morning routine**:

```text
User: "Good morning"
AI: [Reviews yesterday, suggests today's focus]

User: "What should I work on?"
AI: [Recommends based on priorities and context]
```

**During work**:

```text
User: "I'm working on Project Alpha"
AI: [Loads project context, offers relevant help]

User: "Where did I put that file?"
AI: [Searches based on context and recent activity]
```

**End of day**:

```text
User: "End of day summary"
AI: [Reviews accomplishments, updates projects,
     prepares tomorrow's focus]
```

**File management**:

```text
User: "Clean up my downloads"
AI: [Analyzes, categorizes, suggests actions]

User: "File this receipt"
AI: [OCRs, renames, moves to appropriate location]
```

---

## 8. Security & Privacy

### 8.1 Data Privacy

**SEC-1.1**: Personal data stays local

- Memory files are gitignored
- No personal data in shared framework
- User controls what's in version control

**SEC-1.2**: Sensitive information

- `.aida/secrets/` for API keys, tokens (gitignored)
- Environment variables for credentials
- Never commit passwords or keys

**SEC-1.3**: NAS security

- Credentials stored securely
- No plaintext passwords in configs
- Use system keychain when possible

### 8.2 Shareable vs Private

**Shareable** (in git):

- Framework code
- Templates
- Pre-built personalities
- Documentation

**Private** (gitignored):

- Personal knowledge base
- Memory files
- Customized agents
- Secrets and credentials
- Personal configurations

---

## 9. Installation Process

### 9.1 Installation Flow

```text
$ git clone https://github.com/yourusername/claude-personal-assistant ~/.aida
$ cd ~/.aida
$ ./install.sh

🤖 Welcome to AIDA - Agentic Intelligence Digital Assistant

Setting up your personal AI assistant...

1. Choose a personality:
   [Interactive selection]

2. Configure your preferences:
   - What should I call you? [name]
   - Timezone? [EST]
   - Work hours? [9-17]

3. Create directory structure:
   - Creating ~/Development/...
   - Creating ~/Knowledge/...
   - Setting up Obsidian templates...

4. Initialize knowledge base:
   - Copying templates...
   - Creating initial system.md...

✅ Installation complete!

[Personality]: "Hello, [name]. All systems operational."

Try these commands:
  aide status        - Check system status
  aide knowledge     - View knowledge base
  aide help          - Get help
```

### 9.2 Update Process

```text
$ cd ~/aide
$ git pull
$ ./update.sh

📦 Updating AIDE framework...

- New personalities available: [list]
- New tools added: [list]
- Knowledge templates updated

Your personal data is safe (not touched during updates).

✅ Update complete!
```

---

## 10. Future Considerations

### 10.1 Phase 1 (MVP)

- Basic installation and setup
- 2-3 core personalities
- Secretary agent only
- Manual file operations
- Basic Obsidian integration

### 10.2 Phase 2

- All pre-built personalities
- File Manager agent
- Dev Assistant agent
- Automated workflows
- CLI tool completion

### 10.3 Phase 3

- Calendar integration
- Email triage
- Advanced agent behaviors
- Task management integration
- Plugin system

### 10.4 Phase 4

- Multi-user support (teams)
- Cloud sync options
- Advanced automation
- Learning from patterns
- Predictive suggestions

### 10.5 Platform Expansion

- Linux support
- Windows (WSL) support
- Mobile companion app?
- Web interface?

---

## 11. Success Metrics

### 11.1 User Goals

**Time saved**:

- Reduce time finding files
- Faster project context switching
- Less time on repetitive tasks

**Better organization**:

- Clean folders maintained
- Projects tracked consistently
- Clear daily focus

**Reduced cognitive load**:

- AI remembers details
- Less mental overhead
- Clear priorities

### 11.2 Technical Goals

**Reliability**:

- Scripts run without errors
- Knowledge always accessible
- Memory stays synchronized

**Maintainability**:

- Easy to update framework
- Simple to customize
- Clear documentation

**Extensibility**:

- Easy to add new agents
- Simple to create tools
- Custom personalities possible

---

## 12. Context Hierarchy & Scope

### 12.1 Separation of Concerns

**AIDE** (`~/aide/`):

- **Scope**: Personal life management, system-wide assistant
- **Role**: Secretary, file manager, daily workflow coordinator
- **Personality**: User's chosen personality (persistent across all contexts)
- **Knowledge**: System structure, procedures, project tracking (high-level)

**Project Configs** (`~/Development/project-*/CLAUDE.md` or `.cursorrules`):

- **Scope**: Project-specific development guidance
- **Role**: Code assistant, architecture guide, convention enforcer
- **Personality**: Inherits AIDE personality but can adjust formality
- **Knowledge**: Codebase specifics, tech stack, team conventions

### 12.2 Context Loading Rules

**Priority Order**:

1. AIDE personality (never overridden)
2. AIDE system knowledge (always loaded)
3. AIDE project index (if discussing projects)
4. Project-specific config (if in project directory or explicitly referenced)

**Merge Strategy**:

- **Personality**: AIDE personality always applies (JARVIS stays JARVIS)
- **Knowledge**: Additive (project knowledge supplements AIDE knowledge)
- **Procedures**: Project-specific overrides general (more specific wins)
- **Tone**: Can adjust formality for work contexts while keeping personality

### 12.3 Example Scenarios

**Scenario A - General Life Management**:

```text
User: "What should I work on today?"
Context: ~/aide/ only
Agent: JARVIS (personal assistant mode)
```

**Scenario B - Project Work**:

```text
User: "Help me refactor this API in Project Alpha"
Context: ~/aide/ + ~/Development/project-alpha/CLAUDE.md
Agent: JARVIS (with project architecture knowledge)
```

**Scenario C - Cross-Project Question**:

```text
User: "Which of my projects uses PostgreSQL?"
Context: ~/aide/knowledge/projects.md
Agent: JARVIS (consulting project index)
```

### 12.4 Avoiding Conflicts

**Problem**: User has project CLAUDE.md with different personality preference

**Solution**:

- AIDE personality is system-wide (user chose it once)
- Project configs can request tone adjustments only:

  ```yaml
  # In project CLAUDE.md
  context:
    formality: professional  # Adjust formality
    # NOT: personality: different-personality  # This is ignored
  ```

**Problem**: Multiple agents trying to manage the same thing

**Solution**:

- AIDE manages: life, workflow, system
- Project configs manage: code, architecture, conventions
- Clear boundaries prevent overlap

### 12.5 CLI Context Switching

```bash
# Global context (AIDE only)
$ aide status

# Project context (AIDE + project config)
$ cd ~/Development/project-alpha
$ aide project-status

# Explicit project reference
$ aide project project-alpha "what's the tech stack?"
```

---

## 13. Open Questions

1. How to handle Claude API usage vs chat interface?
2. Should we support multiple AI providers (GPT, etc.)?
3. What's the best way to sync memory across devices?
4. How to handle version conflicts in knowledge base?
5. Should agents be able to modify knowledge autonomously?
6. What level of automation is safe vs requiring confirmation?
7. How to handle sensitive operations (deletions, etc.)?
8. Should there be an undo mechanism for agent actions?
9. Should project CLAUDE.md files be symlinked to AIDE knowledge or independent?
10. How to handle team projects where others also use AIDE?

---

## 13. Next Steps

1. ✅ Create requirements document (this)
2. ⬜ Set up repository structure
3. ⬜ Build basic install.sh script
4. ⬜ Create first personality (JARVIS)
5. ⬜ Build knowledge base templates
6. ⬜ Implement memory system
7. ⬜ Create Secretary agent
8. ⬜ Build CLI tool basics
9. ⬜ Write comprehensive README
10. ⬜ Test with real usage

---

**Document Status**: Draft - Ready for review and iteration
**Contributors**: [Your name]
**License**: MIT (proposed)
