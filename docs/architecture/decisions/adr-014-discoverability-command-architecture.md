# ADR-014: Discoverability Command Architecture

**Status**: Accepted
**Date**: 2025-10-20
**Deciders**: Project Lead
**Context**: Software
**Tags**: architecture, discoverability, commands, skills, meta-skills

## Context and Problem Statement

AIDA users need to discover what agents, skills, and commands are available without reading extensive documentation. The system should provide:

- Quick discovery of available agents, skills, and commands
- Self-documentation through filesystem scanning
- Category-based filtering for large catalogs (177 skills)
- Both human-readable and machine-readable output

We need to decide:

- How to architecture the discovery system (layers, components)
- Whether to use direct script invocation or AI-enhanced responses
- How to handle large catalogs (177 skills) without overwhelming users
- What metadata to parse and how to format output

Without a discoverability system, users face:

- Inability to discover available agents, skills, commands
- Friction during onboarding (manual documentation reading)
- Documentation drift (hardcoded lists becoming stale)
- No understanding of AIDA's capabilities

## Decision Drivers

- **Discoverability**: New users must discover capabilities in <30 seconds
- **Self-Documentation**: Zero manual updates, filesystem-driven
- **AI-Enhanced Responses**: Intelligent, context-aware assistance vs. static output
- **Progressive Disclosure**: Summary → details on demand (don't overwhelm users)
- **Reusability**: Pattern applicable to other meta-operations
- **Separation of Concerns**: Knowledge layer distinct from execution layer
- **Testability**: Scripts testable standalone, skills provide AI enhancement

## Considered Options

### Option A: Direct Script Invocation

**Description**: Slash commands directly invoke bash scripts, output plain text

**Architecture**:

```text
/agent-list → scripts/list-agents.sh → Plain text output
```

**Pros**:

- Simple, fast (<500ms)
- Standalone scripts (testable independently)
- No agent orchestration overhead

**Cons**:

- Static output (no AI enhancement)
- No intelligent assistance (creation, validation)
- No context-aware recommendations
- Misses opportunity for comprehensive knowledge system

**Cost**: Fast delivery, limited value

### Option B: Agent-Only (No Scripts)

**Description**: Agent directly scans filesystem and formats output

**Architecture**:

```text
/agent-list → claude-agent-manager → AI scans filesystem → Response
```

**Pros**:

- AI-enhanced responses
- Intelligent formatting
- Context-aware recommendations

**Cons**:

- Slow (AI overhead for simple listing)
- Not testable (AI-dependent)
- Reimplements filesystem scanning in AI (inefficient)
- No reusable scripts for automation

**Cost**: High latency, poor separation of concerns

### Option C: Multi-Layer Architecture with AIDA Meta-Skills (Recommended)

**Description**: Multi-layer system with meta-skills containing comprehensive knowledge, CLI scripts for execution, agent orchestration for AI enhancement

**Architecture**:

```text
Layer 1: User Interface
  /agent-list, /skill-list, /command-list

Layer 2: Agent + Skills (Knowledge Layer)
  claude-agent-manager with AIDA meta-skills:
  - aida-agents (comprehensive agent knowledge)
  - aida-skills (comprehensive skill knowledge)
  - aida-commands (comprehensive command knowledge)

Layer 3: CLI Scripts (Execution Layer)
  scripts/list-agents.sh
  scripts/list-skills.sh
  scripts/list-commands.sh

Layer 4: Shared Libraries
  lib/frontmatter-parser.sh
  lib/path-sanitizer.sh
  lib/json-formatter.sh

Layer 5: Filesystem (Two-Tier Discovery)
  ~/.claude/{agents,skills,commands}/ (user-level)
  ./.claude/{agents,skills,commands}/ (project-level)
```

**Pros**:

- AI-enhanced responses (intelligent, context-aware)
- Reusable pattern for meta-operations (create, validate, discover)
- Separation of concerns (knowledge vs execution)
- Testable scripts (standalone CLI tools)
- Extensible (add new meta-skills for workflows, memory, etc.)
- AIDA meta-skills provide foundation for creation assistance
- Validates architectural coherence (agents understand AIDA's object model)

**Cons**:

- More complex (5 layers vs 1)
- Additional effort to create meta-skills (+18-24 hours)
- Need to maintain meta-skills as schemas evolve

**Cost**: Medium complexity, high value, reusable foundation

### Option D: Hybrid (Scripts + Optional Agent Enhancement)

**Description**: Scripts produce output, agent optionally enhances formatting

**Architecture**:

```text
/agent-list → scripts/list-agents.sh → Raw output
             → (optional) claude-agent-manager → Enhanced formatting
```

**Pros**:

- Fast path (direct scripts)
- Optional AI enhancement
- Scripts standalone

**Cons**:

- Inconsistent UX (sometimes AI, sometimes not)
- No comprehensive knowledge layer
- Agent doesn't understand AIDA's object model deeply
- Misses foundation for creation/validation assistance

**Cost**: Moderate complexity, limited AI value

## Decision Outcome

**Chosen option**: Option C - Multi-Layer Architecture with AIDA Meta-Skills

**Rationale**:

1. **Foundation for AIDA Self-Knowledge**: AIDA meta-skills establish a foundational knowledge layer where AIDA deeply understands its own object model (agents, skills, commands). This enables:
   - Intelligent creation assistance (help users create well-formed agents/skills/commands)
   - Comprehensive validation (check structure, schemas, patterns)
   - Discovery with context (explain what agents do, when to use them)
   - Future meta-operations (refactoring, migration, analysis)

2. **AI-Enhanced Responses**: Instead of static script output, users get:
   - Intelligent summaries ("You have 15 agents, 3 are project-specific")
   - Context-aware recommendations ("Missing data-engineer? Add it for data projects")
   - Interactive guidance ("To create a new agent, see /create-agent or...")

3. **Reusable Pattern**: AIDA meta-skills pattern applicable to other meta-operations:
   - `aida-workflows` - comprehensive workflow knowledge
   - `aida-memory` - memory system structure and management
   - `aida-configuration` - configuration schema and validation

4. **Separation of Concerns**:
   - **Knowledge Layer** (skills): Comprehensive schemas, patterns, validation rules
   - **Execution Layer** (scripts): Fast filesystem scanning, data extraction
   - **Orchestration Layer** (agent): Combines knowledge + data for intelligent responses

5. **Testability**: CLI scripts remain standalone (fast unit tests), while AI enhancement adds value layer

6. **Architectural Coherence**: AIDA understands itself - agents know about agents, skills know about skills. This validates the architecture is self-consistent and composable.

### Consequences

**Positive**:

- Users get intelligent, context-aware responses (not just data dumps)
- Foundation for creation/validation assistance (beyond just listing)
- Reusable pattern for other meta-operations
- Scripts testable independently (fast, deterministic)
- AI enhancement adds significant value (recommendations, validation)
- AIDA's self-knowledge grows over time (meta-skills accumulate best practices)

**Negative**:

- More complex than direct script invocation (5 layers)
- **Mitigation**: Clear layer separation, well-documented interfaces
- Additional effort to create meta-skills (+18-24 hours)
- **Mitigation**: Reusable investment, foundation for future features
- Meta-skills need maintenance as schemas evolve
- **Mitigation**: Frontmatter schema changes are infrequent, versioned

**Neutral**:

- Commands delegate to agent (slightly slower than direct scripts, but <1s acceptable)
- Skills installed alongside agents/commands (`~/.claude/skills/`)

## Implementation Notes

### AIDA Meta-Skills (Foundation Layer)

**Location**: `templates/skills/` → installed to `~/.claude/skills/{skill}/{skill.md}`

**Three Foundational Skills**:

1. **aida-agents** - Comprehensive knowledge about agents:
   - Agent file structure and frontmatter schema
   - How to create, update, validate agents
   - Two-tier architecture patterns (user + project)
   - Knowledge base organization
   - Integration with `list-agents.sh` for discovery

2. **aida-skills** - Comprehensive knowledge about skills:
   - Skill file structure and frontmatter schema
   - How to create, update, validate skills
   - Skill categories and organization (28 categories)
   - How to assign skills to agents
   - Integration with `list-skills.sh` for discovery

3. **aida-commands** - Comprehensive knowledge about commands:
   - Command file structure and frontmatter schema
   - How to create, update, validate commands
   - Category taxonomy (8 categories)
   - Argument handling patterns
   - Integration with `list-commands.sh` for discovery

### Layer Responsibilities

**Layer 1: User Interface** (slash commands):

- Thin wrappers, minimal logic
- Delegate to agent with appropriate skill
- Pass arguments (`--category`, `--format`)

**Layer 2: Agent + Skills** (knowledge orchestration):

- `claude-agent-manager` loads appropriate meta-skill
- Invokes CLI scripts to gather data
- Applies knowledge to provide intelligent responses
- Validates data against schemas
- Provides recommendations and context

**Layer 3: CLI Scripts** (data extraction):

- Fast filesystem scanning (<500ms agents/commands, <1s skills)
- Parse frontmatter (YAML between --- markers)
- Deduplicate symlinks (dev mode)
- Format output (plain text tables or JSON)

**Layer 4: Shared Libraries** (reusable utilities):

- `frontmatter-parser.sh` - Extract YAML with sed/awk
- `path-sanitizer.sh` - Replace absolute paths with variables
- `readlink-portable.sh` - Cross-platform symlink resolution
- `json-formatter.sh` - Format output as JSON

**Layer 5: Filesystem** (data source):

- Two-tier discovery (user `~/.claude/` + project `./.claude/`)
- Frontmatter contains metadata
- Directory structure defines categories

### Data Flow Example

**User invokes**: `/agent-list`

1. **Slash command** delegates to `claude-agent-manager` with `aida-agents` skill
2. **Agent** reads `aida-agents` skill (comprehensive agent knowledge)
3. **Agent** invokes `scripts/list-agents.sh` to gather data
4. **CLI script** scans `~/.claude/agents/` and `./.claude/agents/`
5. **CLI script** parses frontmatter, deduplicates symlinks, formats output
6. **CLI script** returns data to agent
7. **Agent** applies knowledge:
   - Validates agent structures
   - Provides context ("15 agents, 3 project-specific")
   - Suggests actions ("Missing data-engineer? Try /create-agent")
8. **Agent** returns intelligent response to user

### Key Patterns

**AIDA Meta-Skills Pattern**:

- Skills that describe AIDA's own object model
- Enable self-knowledge and self-assistance
- Foundation for creation, validation, discovery
- Reusable for other meta-operations

**Two-Tier Discovery**:

- Scan both `~/.claude/` (user-level) and `./.claude/` (project-level)
- Deduplicate symlinks (dev mode creates symlinks)
- Clearly separate global vs project resources in output

**Progressive Disclosure**:

- `/skill-list` shows categories only (28 categories)
- `/skill-list <category>` shows skills within category
- Prevents overwhelming users with 177 skills at once

## Validation

- [x] Consistent with ADR-002 (two-tier agent architecture)
- [x] Consistent with ADR-009 (skills system architecture)
- [x] Enables AI-enhanced responses (vs static script output)
- [x] Provides foundation for future meta-operations
- [x] Scripts remain testable standalone
- [x] Clear separation of concerns (knowledge vs execution)
- [x] Reusable pattern across discovery operations

## References

- ADR-002: Two-Tier Agent Architecture (user + project pattern)
- ADR-009: Skills System Architecture (skills foundation)
- Issue #54: Discoverability Commands Implementation
- PRD: `.github/issues/in-progress/issue-54/PRD.md`
- Technical Spec: `.github/issues/in-progress/issue-54/TECH_SPEC.md`

## Related ADRs

- ADR-002: Two-Tier Agent Architecture (discovery follows same pattern)
- ADR-009: Skills System Architecture (meta-skills are skills)
- ADR-010: Command Structure Refactoring (commands namespace)

## Updates

None yet
