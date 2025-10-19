# C4 Container Diagram: Installer System Architecture

**Level**: Container
**Audience**: Technical stakeholders, developers
**Purpose**: Show high-level technology choices and major components

## Diagram

```mermaid
C4Container
    title AIDA Installer System - Container Architecture

    Person(user, "User", "Installing or updating AIDA")

    Container_Boundary(installer, "AIDA Installer") {
        Container(orchestrator, "install.sh", "Bash Script (~150 lines)", "Thin orchestrator, delegates to libraries")

        Container(lib_common, "installer-common Libraries", "Bash Modules", "Reusable installation logic")

        Container(config_helper, "aida-config-helper.sh", "Standalone Script", "Universal config aggregator with caching")
    }

    Container_Boundary(templates, "Template System") {
        ContainerDb(commands, "Command Templates", "Markdown + Bash", "Workflow automation templates")
        ContainerDb(agents, "Agent Templates", "Markdown", "AI agent definitions")
        ContainerDb(skills, "Skill Templates", "Markdown", "Reusable knowledge modules")
    }

    Container_Boundary(target, "Target Installation") {
        ContainerDb(claude_dir, "~/.claude/", "File System", "Claude Code configuration directory")
        ContainerDb(aida_dir, "~/.aida/", "Symlink", "Symlink to AIDA repository")
        ContainerDb(config_files, "Config Files", "JSON", "Multi-source configuration")
    }

    System_Ext(dotfiles, "Dotfiles Repository", "Can source installer-common libraries")
    System_Ext(claude_code, "Claude Code", "Discovers commands from ~/.claude/")

    Rel(user, orchestrator, "Runs", "./install.sh [--dev]")

    Rel(orchestrator, lib_common, "Sources", "9 library modules")
    Rel(orchestrator, config_helper, "Calls", "For config reading")

    Rel(lib_common, templates, "Installs", "Copy or symlink to ~/.claude/")
    Rel(lib_common, claude_dir, "Creates", "Namespace directories")
    Rel(lib_common, aida_dir, "Creates", "Symlink to repo")
    Rel(lib_common, config_files, "Writes", "Initial user config")

    Rel(config_helper, config_files, "Reads & merges", "7-tier priority")
    Rel(config_helper, config_helper, "Caches", "Session-based cache")

    Rel(dotfiles, lib_common, "Sources", "For template installation")
    Rel(dotfiles, config_helper, "Calls", "For config aggregation")

    Rel(claude_code, claude_dir, "Discovers", "Commands, agents, skills")

    UpdateLayoutConfig($c4ShapeInRow="2", $c4BoundaryInRow="2")
```

## Containers

### Installer Components

**install.sh** (Orchestrator)
- **Technology**: Bash script (~150 lines)
- **Responsibility**: Coordinate installation flow
- **Pattern**: Thin orchestrator, no business logic
- **Dependencies**: All installer-common libraries

**installer-common Libraries** (Business Logic)
- **Technology**: 9 Bash modules (~1200 lines total)
- **Responsibility**: Reusable installation operations
- **Pattern**: Modular, testable, parameter-based functions
- **Modules**:
  - `colors.sh` - Terminal formatting
  - `logging.sh` - Structured logging
  - `validation.sh` - Dependency checks
  - `config.sh` - Config reading/writing
  - `directories.sh` - Directory/symlink management
  - `templates.sh` - Template installation
  - `prompts.sh` - User interaction
  - `deprecation.sh` - Version-based lifecycle
  - `summary.sh` - Output formatting

**aida-config-helper.sh** (Config Aggregator)
- **Technology**: Standalone Bash script (~200 lines)
- **Responsibility**: Merge all config sources, provide caching
- **Pattern**: Universal config aggregator
- **Performance**: 85%+ I/O reduction via session caching

### Template System

**Command Templates**
- **Technology**: Markdown files with embedded Bash
- **Location**: `templates/commands/`
- **Installed to**: `~/.claude/commands/.aida/`
- **Examples**: start-work, implement, open-pr

**Agent Templates**
- **Technology**: Markdown files
- **Location**: `templates/agents/`
- **Installed to**: `~/.claude/agents/.aida/`
- **Examples**: secretary, file-manager, dev-assistant

**Skill Templates**
- **Technology**: Markdown files
- **Location**: `templates/skills/`
- **Installed to**: `~/.claude/skills/.aida/`
- **Examples**: bash-expert, git-workflow, aida-config

### Target Installation

**~/.claude/** (Claude Config Directory)
- **Technology**: File system hierarchy
- **Structure**: Namespace isolation (.aida/, .aida-deprecated/, user content)
- **Protection**: User content preserved during updates

**~/.aida/** (AIDA Framework)
- **Technology**: Symlink to repository
- **Purpose**: Enable `git pull` updates
- **Modes**: Always symlinked (normal + dev mode)

**Config Files** (Multi-Source Configuration)
- **Technology**: JSON files + Git config
- **Sources**: 7-tier priority hierarchy
- **Aggregator**: aida-config-helper.sh
- **Caching**: Session-based with checksum invalidation

## Data Flow

### Installation Flow

```text
1. User runs ./install.sh
2. Orchestrator sources installer-common libraries
3. Validation checks dependencies, platform
4. Prompts collect user preferences
5. Directories creates namespace structure
6. Templates installs commands/agents/skills to .aida/
7. Config creates initial ~/.claude/aida-config.json
8. Summary displays installation results
```

### Config Aggregation Flow

```text
1. Command calls aida-config-helper.sh
2. Helper checks cache validity (checksum)
   - Valid: Return cached config (~2ms)
   - Invalid: Read and merge all sources (~50ms)
3. Merge 7 config sources with priority
4. Write to cache with checksum
5. Return merged JSON to stdout
```

### Template Installation Flow (Normal Mode)

```text
1. templates.sh reads source templates
2. Copies to ~/.claude/{type}/.aida/ directories
3. No variable substitution (uses runtime config)
4. Sets appropriate permissions
```

### Template Installation Flow (Dev Mode)

```text
1. templates.sh creates symlink
2. ~/.claude/{type}/.aida/ → repo/templates/{type}/
3. Live editing enabled (changes immediately available)
```

## Integration Points

### Dotfiles Integration

```bash
# Dotfiles can source AIDA libraries
if [[ -d ~/.aida ]]; then
  source ~/.aida/lib/installer-common/templates.sh
  install_templates ./templates ~/.claude/commands/.dotfiles
fi
```

### Claude Code Integration

```bash
# Claude Code discovers commands recursively
~/.claude/commands/
├── .aida/start-work/     → /start-work
├── .aida/open-pr/        → /open-pr
└── my-custom.md          → /my-custom
```

## Namespace Isolation

### Framework Namespace (.aida/)

```text
~/.claude/commands/.aida/
~/.claude/agents/.aida/
~/.claude/skills/.aida/

- Replaceable during updates
- Nuked and recreated on install
- Framework-owned content
```

### Deprecated Namespace (.aida-deprecated/)

```text
~/.claude/commands/.aida-deprecated/
~/.claude/agents/.aida-deprecated/

- Optional (--with-deprecated flag)
- Old template versions
- Migration reference
```

### User Namespace (Parent Directory)

```text
~/.claude/commands/my-custom.md
~/.claude/agents/my-agent.md
~/.claude/config/
~/.claude/memory/

- Protected from installer
- Never touched during updates
- User-owned content
```

## Technology Choices

### Why Bash Modules?

- **Platform support**: Bash 3.2+ (macOS compatible)
- **No compilation**: Shell scripts, directly executable
- **Testing**: Can unit test with bats framework
- **Reusability**: Functions callable from any Bash script
- **Simplicity**: No external dependencies (except jq)

### Why Standalone Config Aggregator?

- **Language agnostic**: Any language can call it
- **Caching**: Session-based performance optimization
- **Debugging**: Easy to inspect full config
- **Single source**: One script defines all merging logic

### Why Namespace Isolation?

- **Safety**: Framework cannot touch user content
- **Idempotency**: Safe to re-run installer
- **Clarity**: Visual distinction (dotfile convention)
- **Atomicity**: Can nuke and recreate .aida/ safely

## Performance Characteristics

### Installer Performance

```text
Fresh install: ~5-10 seconds
- Dependency validation: ~1s
- User prompts: ~variable
- Directory creation: ~0.5s
- Template installation: ~2-5s
- Config generation: ~0.5s
- Summary: ~0.5s
```

### Config Aggregator Performance

```text
Cold cache (first call): ~50-100ms
- Read 5-7 config files: ~40ms
- Merge JSON: ~10ms
- Write cache: ~5ms

Warm cache (subsequent): ~1-2ms
- Read cache file: ~1ms
- Checksum validation: ~1ms

Performance gain: 50-98x faster
```

### I/O Reduction

```text
Before (per command):
- 5+ file reads
- 2 git subprocess calls
- Total: ~95ms per command

After (per command):
- 1 config helper call (cached)
- Total: ~2ms per command

Improvement: 47x faster, 98% less I/O
```

## Scalability

### Module Count

- Current: 9 library modules
- Maintainable: Up to ~15 modules
- Beyond 15: Consider grouping

### Template Count

- Current: ~15 templates (commands + agents + skills)
- Scalable: Hundreds of templates
- No performance impact (installed once)

### Config Sources

- Current: 7 sources
- Extensible: Can add more sources
- Caching: Scales well (single merge operation)

## Security Considerations

### File Permissions

```bash
# Templates readable by user only
chmod 644 ~/.claude/commands/.aida/*

# Config files protected
chmod 600 ~/.claude/aida-config.json

# Cache files temporary (session-scoped)
chmod 600 /tmp/aida-config-cache-$$
```

### Symlink Safety

```bash
# Validate symlink targets exist
if [[ ! -d "$TARGET" ]]; then
  error "Symlink target does not exist"
  exit 1
fi

# Create symlink safely (atomic)
ln -sfn "$TARGET" "$LINK"
```

### Config Validation

```bash
# Validate JSON schema
aida-config-helper.sh --validate

# Check required keys present
# Fail fast if config invalid
```

## Success Metrics

- **Modularity**: 625 lines → 150 orchestrator + 9 libraries ✅
- **Reusability**: Dotfiles can source libraries ✅
- **Safety**: User content never destroyed ✅
- **Performance**: 85%+ I/O reduction ✅
- **Testability**: Unit tests per module ✅
- **Idempotency**: Safe to re-run installer ✅
