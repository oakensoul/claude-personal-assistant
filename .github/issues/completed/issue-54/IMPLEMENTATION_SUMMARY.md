---
title: "Implementation Summary - Discoverability Commands"
issue: 54
created: 2025-10-20
status: ready_for_implementation
complexity: M
estimated_effort: 59-85 hours (7.5-10.5 days)
---

# Implementation Summary: Issue #54

## Overview

**What**: Three discoverability commands (`/agent-list`, `/skill-list`, `/command-list`) for exploring AIDA's agents, skills, and commands

**Why**: Reduce onboarding friction, provide self-documentation, eliminate documentation drift through filesystem-based auto-discovery

**Approach**: Multi-layer system with meta-skills containing comprehensive knowledge about agents/skills/commands, CLI scripts for filesystem scanning, and dual output formats (tables/JSON)

## Key Decisions

### 1. Skills Architecture Clarified ✅

**Decision**: Skills stored in `templates/skills/` → installed to `~/.claude/skills/{skill}/{skill.md}`

**Impact**: Unblocks `/skill-list` implementation, moves from Phase 2 to Phase 1

### 2. Single Category Model

**Decision**: Commands have single category only (not multi-category arrays)

**Rationale**: Forces clear categorization, simpler filtering logic

### 3. Dual Output Format (Plain Text + JSON)

**Decision**: Support both plain text tables (default) and JSON (`--format json`)

**Rationale**: Human-readable by default, machine-readable for automation

**Scope Change**: JSON output moved from Phase 2 to Phase 1 (+4-6 hours effort)

### 4. Symlink Deduplication

**Decision**: Use `realpath` to canonicalize paths and deduplicate

**Implementation**: Portable `readlink_portable()` with Python fallback for macOS

### 5. Version Field Required

**Decision**: Add `version` field to frontmatter, display in output

**Scope Change**: Adds version field migration to 32+ existing commands (+1-2 hours)

### 6. Graceful Error Handling

**Decision**: Malformed/missing frontmatter generates warnings, not errors

**Behavior**: Skip invalid entries, collect warnings, display at end, exit 0

### 7. No Caching

**Decision**: No caching layer - direct filesystem scanning is fast enough

**Rationale**: <500ms for agents/commands, <1s for skills - caching adds complexity for minimal gain

### 8. AIDA Meta-Skills (Foundation Layer)

**Decision**: Create three foundational skills with comprehensive knowledge about AIDA's architecture

**Skills to Create**:

- `aida-agents` - Complete knowledge about agent structure, creation, validation, listing
- `aida-skills` - Complete knowledge about skill structure, creation, validation, listing
- `aida-commands` - Complete knowledge about command structure, creation, validation, listing

**Rationale**: These meta-skills provide the `claude-agent-manager` (soon `aida`) agent with deep knowledge about AIDA's object model, enabling intelligent assistance with creation, validation, and discovery

**Scope Change**: Adds meta-skills layer (+21-27 hours effort)

**Impact**: Slash commands invoke agent with skills (not direct scripts), enabling AI-enhanced responses

## Implementation Scope

### Phase 1: All Three Commands (MVP)

**Components to Build**:

1. **AIDA Meta-Skills** (`templates/skills/`) - **NEW**:
   - `aida-agents/aida-agents.md` - Comprehensive knowledge about agents (6-8 hours)
     - Agent file structure and frontmatter schema
     - How to create, update, and validate agents
     - Two-tier architecture patterns
     - Knowledge base organization
     - Integration with `list-agents.sh` for listing
   - `aida-skills/aida-skills.md` - Comprehensive knowledge about skills (6-8 hours)
     - Skill file structure and frontmatter schema
     - How to create, update, and validate skills
     - Skill categories and organization
     - How to assign skills to agents
     - Integration with `list-skills.sh` for listing
   - `aida-commands/aida-commands.md` - Comprehensive knowledge about commands (6-8 hours)
     - Command file structure and frontmatter schema
     - How to create, update, and validate commands
     - Category taxonomy (8 categories)
     - Argument handling patterns
     - Integration with `list-commands.sh` for listing

2. **CLI Scripts** (`scripts/`):
   - `list-agents.sh` - Scan and list agents (4-6 hours)
   - `list-commands.sh` - Scan and list commands with category filtering (8-12 hours)
   - `list-skills.sh` - Scan and list skills with category-first approach (6-10 hours)

3. **Shared Libraries** (`scripts/lib/`):
   - `frontmatter-parser.sh` - Extract YAML frontmatter with sed/awk (2-3 hours)
   - `path-sanitizer.sh` - Replace absolute paths with variables (1-2 hours)
   - `readlink-portable.sh` - Cross-platform symlink resolution (1 hour)
   - `json-formatter.sh` - Format output as JSON (2-3 hours)

4. **Slash Commands** (`templates/commands/.aida/`):
   - `agent-list.md` - Delegate to claude-agent-manager with aida-agents skill (30 min)
   - `command-list.md` - Delegate to claude-agent-manager with aida-commands skill (30 min)
   - `skill-list.md` - Delegate to claude-agent-manager with aida-skills skill (30 min)

5. **Agent Configuration**:
   - Update `claude-agent-manager` to include three new skills (1 hour)
   - Test skill invocation from commands (1 hour)

6. **Configuration Updates**:
   - Add `category` and `version` fields to 32 existing commands (3-4 hours)
   - Update command creation template to include new fields (30 min)
   - Document category taxonomy in `templates/commands/README.md` (30 min)

7. **Validation & Testing**:
   - Pre-commit hook for frontmatter validation (1-2 hours)
   - Unit tests for parsing, sanitization, deduplication (4-6 hours)
   - Integration tests for two-tier discovery, formatting (4-6 hours)
   - Cross-platform tests (Docker + macOS) (2-3 hours)

8. **Installer Integration**:
   - Add `~/.claude/scripts/.aida/` directory creation (1 hour)
   - Install scripts with permissions (install.sh update) (1-2 hours)
   - Support dev mode symlinks (30 min)

### In Scope (Phase 1)

- ✅ Three AIDA meta-skills: `aida-agents`, `aida-skills`, `aida-commands`
- ✅ All three commands: `/agent-list`, `/skill-list`, `/command-list`
- ✅ Commands delegate to claude-agent-manager with skills (not direct script invocation)
- ✅ Two-tier discovery (user `~/.claude/` + project `./.claude/`)
- ✅ Plain text table output (default)
- ✅ JSON output (`--format json`)
- ✅ Category filtering for commands
- ✅ Version display
- ✅ Path sanitization for privacy
- ✅ Symlink deduplication (dev mode)
- ✅ Graceful error handling (warnings)
- ✅ Cross-platform support (macOS + Linux)

### Out of Scope (Future)

- ❌ Search functionality (`--search <term>`)
- ❌ Interactive selection mode
- ❌ Pagination for long lists
- ❌ Caching layer
- ❌ Agent filtering by model/color
- ❌ Knowledge base file counts
- ❌ Diff mode (changes since last check)

## Technical Approach

### Multi-Layer Architecture

```text

┌─────────────────────────────────────────────────────────┐
│ User Interface Layer                                    │
│  /agent-list    /skill-list    /command-list           │
└────────────────────┬────────────────────────────────────┘
                     │ delegates to
┌────────────────────▼────────────────────────────────────┐
│ Agent Layer                                             │
│  claude-agent-manager (aida) with skills:               │
│  - aida-agents    (agent knowledge)                     │
│  - aida-skills    (skill knowledge)                     │
│  - aida-commands  (command knowledge)                   │
└────────────────────┬────────────────────────────────────┘
                     │ invokes
┌────────────────────▼────────────────────────────────────┐
│ CLI Script Layer                                        │
│  scripts/list-agents.sh                                 │
│  scripts/list-skills.sh                                 │
│  scripts/list-commands.sh                               │
└────────────────────┬────────────────────────────────────┘
                     │ uses
┌────────────────────▼────────────────────────────────────┐
│ Shared Library Layer                                    │
│  lib/frontmatter-parser.sh    (extract YAML)            │
│  lib/path-sanitizer.sh        (privacy protection)      │
│  lib/readlink-portable.sh     (symlink resolution)      │
│  lib/json-formatter.sh        (JSON output)             │
└────────────────────┬────────────────────────────────────┘
                     │ scans
┌────────────────────▼────────────────────────────────────┐
│ Filesystem Layer (Two-Tier Discovery)                  │
│  ~/.claude/{agents,skills,commands}/   (user-level)    │
│  ./.claude/{agents,skills,commands}/   (project-level) │
└─────────────────────────────────────────────────────────┘

```

### Key Technical Choices

1. **sed/awk for Parsing** (not yq): Zero dependencies, portable, fast
2. **realpath for Deduplication**: Canonical paths prevent duplicates
3. **Direct Script Invocation**: No agent orchestration overhead (<500ms target)
4. **Frontmatter-Only Parsing**: Never read full file content (privacy + performance)
5. **Path Sanitization**: Replace absolute paths with `${CLAUDE_CONFIG_DIR}`, `${PROJECT_ROOT}`, etc.

## Success Criteria

### Functional Requirements ✅

- [ ] `/agent-list` shows all user + project agents without duplicates
- [ ] `/skill-list` shows all user + project skills with category grouping
- [ ] `/command-list --category workflow` filters correctly
- [ ] All commands support `--format json` for machine-readable output
- [ ] Version displayed for all agents/skills/commands
- [ ] Scripts executable standalone (not Claude-dependent)
- [ ] Frontmatter parsing handles malformed YAML gracefully (warnings)
- [ ] Absolute paths sanitized in output (no usernames/project names)

### Non-Functional Requirements ✅

- [ ] `/agent-list` executes in <500ms
- [ ] `/skill-list` executes in <1s
- [ ] `/command-list` executes in <500ms
- [ ] Permission errors don't expose filesystem structure
- [ ] Dev mode symlinks deduplicated correctly
- [ ] Cross-platform tests pass (ubuntu-22, ubuntu-20, debian-12, macOS)
- [ ] Pre-commit hook validates command categories and versions

### Security Requirements ✅

- [ ] No absolute paths exposed in output
- [ ] No full file content parsed (frontmatter only)
- [ ] Generic error messages (no path leakage)
- [ ] Scripts run with user permissions only (no sudo)

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Symlink deduplication failures | HIGH | Use realpath, test extensively in dev mode |
| Frontmatter parsing edge cases | HIGH | Validate structure, handle gracefully, limit size |
| macOS readlink compatibility | MEDIUM | Python fallback, test on macOS Sonoma |
| Performance with large catalogs | MEDIUM | Frontmatter-only, progressive disclosure, <1s target |
| Path sanitization false positives | LOW | Order replacements, test edge cases |
| Category taxonomy drift | LOW | Pre-commit validation, enum checking |

## Effort Estimate

### Overall Complexity: M (Medium)

**Phase 1 Total**: **59-85 hours (7.5-10.5 days)**

| Component | Effort | Notes |
|-----------|--------|-------|
| AIDA meta-skills (3) | 18-24 hours | aida-agents (6-8h), aida-skills (6-8h), aida-commands (6-8h) |
| Shared libraries | 6-9 hours | Frontmatter, sanitizer, formatter, symlinks |
| CLI scripts (3) | 18-28 hours | Agents (4-6h), Commands (8-12h), Skills (6-10h) |
| Slash commands (3) | 1.5 hours | Delegate to agent with skills |
| Agent configuration | 2 hours | Add skills to claude-agent-manager, test invocation |
| Configuration migration | 3-4 hours | Add category + version to 32 commands |
| Validation hooks | 1-2 hours | Pre-commit frontmatter validation |
| Installer integration | 2-3 hours | Scripts directory, permissions, dev mode |
| Testing | 10-15 hours | Unit, integration, cross-platform |
| Documentation | 2-3 hours | Usage, troubleshooting, category taxonomy |

### Key Effort Drivers

**High Effort**:

1. **AIDA meta-skills** - Three comprehensive skill documents (+18-24 hours)
2. **Skills listing** - Moved from Phase 2 to Phase 1 (+6-10 hours)
3. **JSON output formatting** - Added to Phase 1, dual format support (+4-6 hours)
4. **Frontmatter parsing robustness** - Edge case handling
5. **Cross-platform testing** - macOS + 3 Linux flavors

**Medium Effort**:

6. **Configuration migration** - 32 commands need category + version fields
7. **Symlink deduplication** - Portable implementation, dev mode testing
8. **Path sanitization** - Comprehensive replacement patterns
9. **Agent integration** - Wire up skills to claude-agent-manager

### Comparison to Original Estimate

- **Original Issue Estimate**: 3 hours (too low - didn't account for all requirements)
- **Initial Phase 1 Estimate**: 30-46 hours (before Q&A clarifications)
- **After Q&A Estimate**: 38-58 hours (includes JSON, skills listing, version field)
- **Final Phase 1 Estimate**: 59-85 hours (includes meta-skills layer)
- **Total Increase**: +29-39 hours due to scope additions:

  - Meta-skills: +18-24 hours
  - JSON output: +4-6 hours
  - Skills listing: +6-10 hours
  - Version field: +1-2 hours

## Next Steps

### Immediate Actions (Day 1-2)

1. **AIDA meta-skills creation** (PRIORITY):

   - Create `templates/skills/aida-agents/aida-agents.md`
   - Create `templates/skills/aida-skills/aida-skills.md`
   - Create `templates/skills/aida-commands/aida-commands.md`
   - Document: file structure, schemas, validation rules, creation workflows

2. **configuration-specialist**:

   - Add `category` and `version` fields to 32 existing commands
   - Document category taxonomy in `templates/commands/README.md`
   - Update command creation template

3. **shell-script-specialist**:

   - Implement shared libraries (frontmatter parser, path sanitizer, symlink handler)
   - Create `scripts/list-agents.sh` (simplest, validate approach)

### Day 3-4

4. **shell-script-specialist**:

   - Implement `scripts/list-commands.sh` with category filtering
   - Implement `scripts/list-skills.sh` with category-first approach
   - Add JSON formatter library

5. **devops-engineer**:

   - Update `install.sh` to install scripts directory
   - Add `~/.claude/scripts/.aida/` directory creation
   - Test dev mode symlink handling

### Day 5-7

6. **integration-specialist**:

   - Create slash command templates (3 files)
   - Test command → script invocation
   - Validate argument passing (--category, --format)

7. **claude-agent-manager update**:

   - Add three skills to agent configuration
   - Test skill invocation from slash commands
   - Validate CLI script execution from skills

8. **qa-engineer**:

   - Create test fixtures (valid/invalid frontmatter, symlinks)
   - Write unit tests (parsing, sanitization, deduplication)
   - Write integration tests (two-tier discovery, filtering)

### Day 8-10

9. **privacy-security-auditor**:

   - Validate path sanitization (no absolute paths in output)
   - Review error messages (no path leakage)
   - Test permission error handling

10. **qa-engineer**:

- Run cross-platform tests (Docker + macOS)
- Performance validation (<500ms agents/commands, <1s skills)
- Create pre-commit hook for frontmatter validation

11. **Final validation**:

- All acceptance criteria met
- Documentation complete
- Ready for PR

## Related Documents

- **PRD**: `.github/issues/in-progress/issue-54/PRD.md`
- **Technical Spec**: `.github/issues/in-progress/issue-54/TECH_SPEC.md`
- **Q&A Log**: `.github/issues/in-progress/issue-54/qa-log.md`
- **Product Analyses**: `.github/issues/in-progress/issue-54/analysis/product/`
- **Technical Analyses**: `.github/issues/in-progress/issue-54/analysis/technical/`

## Acceptance Checklist

### Functional ✅

- [ ] `/agent-list` works (plain text + JSON)
- [ ] `/skill-list` works (plain text + JSON)
- [ ] `/command-list` works (plain text + JSON)
- [ ] `/command-list --category <name>` filters correctly
- [ ] Version displayed for all items
- [ ] Two-tier discovery (user + project)
- [ ] Symlink deduplication works in dev mode
- [ ] Malformed frontmatter handled gracefully (warnings)

### Non-Functional ✅

- [ ] Performance targets met (<500ms agents/commands, <1s skills)
- [ ] Path sanitization (no absolute paths in output)
- [ ] Generic error messages (no path leakage)
- [ ] Cross-platform compatibility (macOS + Linux)
- [ ] Pre-commit validation enabled

### Configuration ✅

- [ ] All 32 commands have `category` field
- [ ] All 32 commands have `version` field
- [ ] Category taxonomy documented
- [ ] Command creation template updated

### Testing ✅

- [ ] Unit tests pass (parsing, sanitization, deduplication)
- [ ] Integration tests pass (two-tier, filtering, formatting)
- [ ] Cross-platform tests pass (ubuntu-22, ubuntu-20, debian-12, macOS)
- [ ] Performance tests pass

### Documentation ✅

- [ ] Usage examples in command files
- [ ] Category taxonomy in README
- [ ] Troubleshooting guide
- [ ] CONTRIBUTING.md updated (frontmatter requirements)

---

**Status**: ✅ Ready for implementation

**Estimated Delivery**: 7.5-10.5 days (59-85 hours)

**Dependencies**: None (uses POSIX tools, existing installer patterns)

**Risks**: Manageable (documented with mitigations)

**Priority**: Create AIDA meta-skills FIRST (foundation for everything else)

**Next**: Assign to implementation team, begin Day 1-2 tasks (meta-skills)
