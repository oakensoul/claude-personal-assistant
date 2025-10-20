---
title: "Product Requirements Document - Discoverability Commands"
issue: 54
product_owner: product-manager
created: 2025-10-20
status: approved
---

# PRD: Discoverability Commands

## Executive Summary

Implement three discoverability commands (`/agent-list`, `/skill-list`, `/command-list`) to improve AIDA's self-documentation and reduce onboarding friction. Users need to quickly discover what agents, skills, and commands are available without reading documentation. The commands will scan the filesystem for metadata and present organized, actionable output with category filtering where appropriate.

**Value**: Reduces cognitive load for new users, provides quick reference for experienced users, and eliminates documentation drift through auto-discovery.

**Approach**: Filesystem-based scanning with frontmatter parsing, progressive disclosure for large catalogs (177 skills), and consistent output formatting across all three commands.

## Stakeholder Analysis

### New AIDA Users

**Concerns**: What can the system do? How do I discover features?
**Priorities**: Simple, scannable output; clear usage instructions; fast onboarding
**Recommendations**: Category-first organization for skills, progressive disclosure, actionable usage hints

### Experienced Users

**Concerns**: Quick reference without context switching; finding specific agents/commands
**Priorities**: Fast execution (<1s); optional filtering; machine-readable output (future)
**Recommendations**: Category filtering for commands, search functionality (Phase 2), optional JSON output

### Agent/Command Developers

**Concerns**: Avoid naming conflicts; understand existing patterns; validate installations
**Priorities**: Comprehensive listings; metadata validation; detect missing frontmatter
**Recommendations**: Distinguish global vs. project agents, validate required fields, support for private markers

### Privacy & Security

**Concerns**: Information disclosure (paths, project names); sensitive metadata exposure
**Priorities**: Path sanitization; frontmatter-only parsing (not full file content); clear global/project separation
**Recommendations**: Replace absolute paths with variables, add optional `privacy: private` marker, generic error messages

## Requirements

### Functional Requirements

**Core Discovery**:

- Scan `~/.claude/agents/` and `./.claude/agents/` for agent metadata
- Scan `~/.claude/commands/` and `./.claude/commands/` for command metadata
- Scan skills catalog (177 skills across 28 categories)
- Parse YAML frontmatter only (never full file content)
- Detect and deduplicate symlinked entries (dev mode)
- Validate required fields exist (name, description)

**Output Formatting**:

- Consistent table/list format across all three commands
- Separate global (user-level) and project (project-level) sections
- Category-based grouping with summary counts
- Color-coded output (green: counts, blue: categories, yellow: usage hints)
- Bottom usage hints ("→ Usage: ...")

**Category System**:

- Add `category` field to command frontmatter
- Implement category taxonomy: workflow, quality, security, operations, infrastructure, data, documentation, meta
- Support category filtering: `/command-list --category workflow`
- Skills use existing 28-category structure from Claude Code skills catalog

**Filtering & Search**:

- `/skill-list` without args shows categories only (not 177 skills)
- `/skill-list <category>` shows skills within category
- `/command-list --category <name>` filters commands
- No filtering for agents (small set: 15 agents)

**Privacy & Security**:

- Sanitize absolute paths to variables (`${CLAUDE_CONFIG_DIR}`, `${PROJECT_ROOT}`)
- Parse frontmatter only (no full file reads)
- Handle permission errors gracefully (no path exposure in error messages)
- Support optional `privacy: private` frontmatter flag
- Validate frontmatter doesn't contain obvious secrets (warn, don't block)

### Non-Functional Requirements

**Performance**:

- `/agent-list` completes in <500ms
- `/skill-list` (categories) completes in <1s
- `/command-list` completes in <500ms
- Consider caching for repeated invocations (future optimization)

**Usability**:

- Zero-to-useful without reading documentation
- Progressive disclosure (summary → details on demand)
- Actionable output (show how to use, not just what exists)
- Screen reader friendly (logical reading order, works without color)

**Maintainability**:

- Zero manual updates (generates from filesystem)
- Works immediately after adding new agent/skill/command
- Clear error messages for missing/malformed frontmatter
- Validates against category taxonomy (enum validation)

**Security**:

- Scripts run with user permissions only (no sudo)
- No external network calls (local-only)
- Output never auto-committed to git
- No privilege escalation

## Success Criteria

**Usability Metrics**:

- New users discover agents/skills/commands in <30 seconds
- Experienced users find specific items in <10 seconds
- Category filtering reduces skills output from 177 to <20 per category

**Technical Metrics**:

- All commands execute in <1 second
- Zero hardcoded agent/skill/command lists (filesystem-driven)
- 100% frontmatter parsing success (no crashes on malformed YAML)
- Global vs. project agents clearly distinguished in output

**Security Metrics**:

- No absolute paths exposed (replaced with variables)
- No full file content parsed (frontmatter only)
- No permission errors leak filesystem structure

## Open Questions

### Critical (Blocking Implementation)

**Skills Catalog Location**:

- Where are the 177 skills stored? (templates/skills/ or external catalog?)
- What is the skill file format? (YAML, Markdown, JSON?)
- How do skills integrate with claude-agent-manager?
- Are AIDA skills separate from Claude Code's built-in skills?
- **Action**: Investigate skills catalog before implementing `/skill-list`

**Category Implementation**:

- Confirm category taxonomy (8 proposed categories acceptable?)
- Should commands allow multiple categories (comma-separated, array)?
- **Decision**: Add `category` field to command frontmatter (recommended over directory restructuring)

### Important (Design Decisions)

**Output Format**:

- Plain text, markdown tables, or both?
- Should output be paginated for long lists?
- JSON output option for automation (`--format json`)?
- **Recommendation**: Start with plain text, add JSON in Phase 2

**Symlink Handling**:

- Dev mode creates symlinks from `~/.claude/` → framework templates
- How to deduplicate entries when both symlink and target exist?
- **Recommendation**: Show target location, note if symlinked

**Version Display**:

- Should listings show agent/command versions?
- Add `version` field to frontmatter?
- **Recommendation**: Defer to Phase 2

### Nice to Have (Future Enhancements)

- Search within listings (`/agent-list --search "sql"`)
- Filter by model (`/agent-list --model sonnet`)
- Show knowledge base file count per agent
- Interactive selection mode
- Export to JSON for automation

## Recommendations

### MVP Scope (Phase 1)

**Implement First** (highest value, proven patterns):

1. Add `category` field to all command frontmatter (enables filtering)
2. Implement `/agent-list` (simple, 15 agents, no filtering needed)
3. Implement `/command-list` with optional category filtering
4. Create CLI scripts: `scripts/list-agents.sh`, `scripts/list-commands.sh`
5. Validate frontmatter parsing with error handling
6. Path sanitization in output (replace absolute paths with variables)
7. Global vs. project section separation

**Defer** (depends on skills architecture clarification):

- `/skill-list` implementation
- Skills catalog investigation
- Skills integration pattern documentation

### Enhanced Features (Phase 2)

**After MVP validated**:

1. Investigate and document skills catalog architecture
2. Implement `/skill-list` with category-first approach
3. Add search functionality (`--search <term>`)
4. JSON output format option (`--format json`)
5. Performance optimization (caching)
6. Privacy markers (`privacy: private` in frontmatter)

### Phase 3 (Polish)

**Future enhancements**:

1. Version tracking display
2. Interactive selection mode
3. Agent filtering by model/color
4. Knowledge base file count per agent
5. Diff mode (show changes since last check)

### Recommended Architecture

```text
Layer 1: CLI Scripts (filesystem scanning)
   - scripts/list-agents.sh
   - scripts/list-commands.sh
   - scripts/list-skills.sh (deferred)

Layer 2: Skills (output formatting - optional)
   - templates/skills/aida-discovery/agent-lister
   - templates/skills/aida-discovery/command-lister
   - templates/skills/aida-discovery/skill-lister

Layer 3: Slash Commands (user interface)
   - templates/commands/.aida/agent-list.md
   - templates/commands/.aida/command-list.md
   - templates/commands/.aida/skill-list.md (deferred)

Layer 4: Agent Orchestration
   - claude-agent-manager invokes skills/scripts
```

### What to Avoid

**Anti-Patterns**:

- Dumping all 177 skills in flat list (overwhelming)
- Hardcoding agent/skill/command lists (maintenance nightmare)
- Directory restructuring for categories (breaks existing paths)
- Complex YAML parsing (use grep/sed for frontmatter)
- Exposing full file content (privacy risk)
- Silent failures on missing/invalid metadata
- Inconsistent output formats between commands

**Performance Pitfalls**:

- Recursive scanning of entire knowledge bases (only read `{name}.md`)
- Parsing full markdown files (frontmatter only)
- No caching for repeated invocations (optimize in Phase 2)

**Security Risks**:

- Absolute path exposure in output
- Full file content parsing (vs. frontmatter-only)
- Detailed error messages leaking filesystem structure
- Running scripts with elevated privileges

### Implementation Strategy

**Recommended Sequence**:

1. **Add Category Metadata** (non-breaking change)
   - Add `category` field to all existing command frontmatter
   - Update command creation template to include category
   - Document category taxonomy in templates/commands/README.md

2. **Create CLI Scripts** (no agent/skill dependency)
   - Implement `scripts/list-agents.sh` with global + project scanning
   - Implement `scripts/list-commands.sh` with category filtering
   - Add frontmatter validation and error handling

3. **Create Slash Commands** (direct script invocation)
   - `templates/commands/.aida/agent-list.md`
   - `templates/commands/.aida/command-list.md`
   - Delegate to claude-agent-manager with script invocation

4. **Test Two-Tier Discovery**
   - Validate deduplication of symlinked entries
   - Test global vs. project separation in output
   - Verify permission error handling

5. **Document Skills Architecture** (before implementing)
   - Investigate skills catalog location and format
   - Define skill schema in templates/skills/README.md
   - Document skill lifecycle (discovery → registration → invocation)

6. **Implement Skills Listing** (Phase 2, after architecture clarified)
   - Create `scripts/list-skills.sh`
   - Implement category-first progressive disclosure
   - Add `/skill-list` slash command

### Migration Strategy

**Existing Commands**:

- Add `category` field to frontmatter (32 commands)
- Category values: workflow, quality, security, operations, infrastructure, data, documentation, meta
- No file moves or renames (maintain existing paths)
- Validate via pre-commit hook (future enhancement)

**Template Updates**:

- Update `templates/commands/.aida/create-command.md` to include category prompt
- Add category taxonomy documentation to templates/commands/README.md
- Update validation scripts to check category field

## Success Validation

**Phase 1 Acceptance Criteria**:

- [ ] `/agent-list` shows all user + project agents without duplicates
- [ ] Output clearly separates global vs. project agents
- [ ] `/command-list --category workflow` filters correctly
- [ ] Scripts are executable standalone (not Claude-dependent)
- [ ] Frontmatter parsing handles missing/invalid fields gracefully
- [ ] Absolute paths sanitized in output (replaced with variables)
- [ ] Permission errors don't expose filesystem structure
- [ ] Category field added to all existing command frontmatter

**Phase 2 Acceptance Criteria** (deferred):

- [ ] Skills architecture documented in templates/skills/README.md
- [ ] `/skill-list` shows categories only (not 177 skills)
- [ ] `/skill-list <category>` shows skills within category
- [ ] Skills catalog source identified and integrated
- [ ] JSON output format option available (`--format json`)

---

**Next Actions**:

1. Add category field to command frontmatter (configuration-specialist)
2. Implement CLI scripts with frontmatter parsing (shell-systems-ux-designer)
3. Create slash command definitions (integration-specialist)
4. Investigate skills catalog architecture (integration-specialist)
5. Add privacy controls and path sanitization (privacy-security-auditor)

**Estimated Effort**: 5-8 days (Phase 1 MVP only)

**Dependencies**: None for agents/commands; skills catalog investigation required for `/skill-list`

**Risks**: Skills architecture undefined (mitigated by deferring `/skill-list` to Phase 2)
