---
title: "Shell Systems UX Designer Analysis - Issue #54"
description: "CLI UX design analysis for discoverability commands"
category: "analysis"
tags: ["cli-ux", "discoverability", "commands", "issue-54"]
analyst: "shell-systems-ux-designer"
issue: "54"
last_updated: "2025-10-20"
status: "draft"
---

# Shell Systems UX Designer Analysis - Issue #54

**Issue**: Implement discoverability commands (/agent-list, /skill-list, /command-list)

**Analyst**: shell-systems-ux-designer

**Date**: 2025-10-20

## 1. Domain-Specific Concerns

### Command Design & Structure

**Core UX Principle**: Discoverability commands should follow "show, don't tell" pattern - present actionable information, not documentation dumps.

**Command Structure**:

- `/agent-list` - Simple list, no filtering needed (small set: ~15 agents)
- `/skill-list` - NEEDS filtering/categorization (177 skills across 28 categories)
- `/command-list [--category]` - Optional filtering (32 commands, consolidating to 10 groups in v0.1.0)

**Key Design Decisions**:

- **Filtering strategy**: Category-based for skills (mandatory), optional for commands
- **Output hierarchy**: Category → Item → Description (not flat lists)
- **Action orientation**: Show "how to use" not just "what exists"

### Output Format & Presentation

**Visual Hierarchy** (in order of importance):

1. **Summary counts** - "15 agents available" (quick overview)
2. **Categorized grouping** - Logical organization (Core Agents, Data Engineering, etc.)
3. **Item name + short description** - Scannable format
4. **Usage hint** - How to invoke/access

**Format Recommendations**:

**Good** (scannable, actionable):

```text
Available Agents (15 total)

Core Agents:
  code-reviewer         Multi-language code quality review
  technical-writer      Documentation for all audiences
  devops-engineer       CI/CD and deployment automation

Data Engineering:
  data-engineer         dbt, Snowflake, pipeline design
  sql-expert            Query optimization and design

→ Learn more: Each agent has specialized knowledge
→ Usage: Agents are invoked automatically by Claude
```

**Bad** (wall of text, overwhelming):

```text
Here are all the available agents in AIDA:
- claude-agent-manager: Meta-agent for creating and managing other agents and commands. This agent helps you...
[continues for pages]
```

**Color Usage**:

- Green: Counts, success indicators ("15 agents available")
- Blue/Cyan: Category headers, informational
- No color: Item names (rely on indentation)
- Yellow: Usage hints ("→ Usage:")

### Filtering & Categorization

**For /skill-list** (177 skills - MUST filter):

**Category-first approach**:

```bash
/skill-list                    # Show categories only (28 categories)
/skill-list style-guides       # Show skills in category
/skill-list --search "python"  # Search across all skills
```

**For /command-list** (32 commands → consolidating to 10):

**Optional filtering**:

```bash
/command-list                  # All commands, grouped by category
/command-list --category quality   # Filter by category
/command-list --search "test"      # Search command names/descriptions
```

**Why category-first?** 177 skills in a flat list is overwhelming. Force users to explore by domain, not scroll through everything.

### Progressive Disclosure

**Level 1**: Counts and categories

```text
Skills Catalog (177 skills across 28 categories)

Top Categories:
  security/       20 skills  - Injection prevention, auth, API security
  frameworks/     12 skills  - React, Next.js, FastAPI, Django
  databases/       8 skills  - Snowflake, PostgreSQL, DynamoDB
  [show top 10 categories]

→ Usage: /skill-list <category> to see skills
→ Search: /skill-list --search <term>
```

**Level 2**: Skills within category

```text
Skills: security/ (20 skills)

  sql-injection-prevention      Parameterized queries, ORM patterns
  prompt-injection-prevention   AI-specific attack prevention (CRITICAL for AIDA!)
  xss-prevention                Cross-site scripting defense
  [continues...]

→ Access: Skills are loaded automatically by agents
```

**Level 3**: Full skill details (not in list command - use separate command or file)

### Consistency with Existing Patterns

**Current AIDA command patterns** (from commands README):

- Simple, descriptive names: `/create-agent`, `/start-work`, `/open-pr`
- Clear purpose in description
- Examples included in help text
- Consistent format across all commands

**Match this pattern**:

- `/agent-list` not `/list-agents` (noun-first is AIDA standard)
- `/skill-list` not `/skills` (consistency)
- `/command-list` not `/commands` (consistency)

## 2. Stakeholder Impact

### Who Is Affected

**Primary Users**:

- New AIDA users exploring what's available (discoverability)
- Developers choosing agents for delegation
- Users looking for specific skills/commands (search)

**Secondary Users**:

- Documentation writers (reference these commands in guides)
- Agent developers (understanding available agents)
- Power users (quick reference without leaving terminal)

### Value Provided

**For New Users**:

- Reduces onboarding friction ("What can AIDA do?")
- Builds mental model of system capabilities
- Encourages exploration and experimentation

**For Experienced Users**:

- Quick reference without context switching
- Discover new skills/commands as system grows
- Validate assumptions ("Does this agent exist?")

**For System**:

- Encourages agent usage (visibility → usage)
- Surfaces underutilized capabilities
- Self-documenting (commands reflect current state)

### Risks & Downsides

**Information Overload**:

- 177 skills is overwhelming if presented poorly
- Risk: Users see massive list and give up
- Mitigation: Category-first, progressive disclosure

**Maintenance Burden**:

- Commands must stay in sync with actual agents/skills/commands
- Risk: Stale information erodes trust
- Mitigation: Generate from filesystem (not hardcoded)

**Duplicate Documentation**:

- Information exists in README files, frontmatter, etc.
- Risk: Conflicting information between sources
- Mitigation: Single source of truth (filesystem), format for display

**Performance**:

- Scanning 177 skill files could be slow
- Risk: Command takes >2 seconds (feels sluggish)
- Mitigation: Cache results, optimize file scanning

## 3. Questions & Clarifications

### Missing Information

**Search Implementation**:

- How should search work? (fuzzy matching? regex? exact?)
- Search only names, or include descriptions?
- Case-sensitive or insensitive?

**Output Format**:

- Plain text only, or support table format?
- Should output be paginated for long lists?
- Color output configurable (for accessibility)?

**Caching**:

- Should results be cached?
- How often to invalidate cache? (on install? daily?)
- Cache shared across users or per-session?

**Integration**:

- How do these commands integrate with existing help system?
- Should `/help` reference these discoverability commands?
- Do we need `/skill-info <name>` for detailed skill view?

### Decisions Needed

**Category Taxonomy**:

- Use existing categories from skills-catalog.md (28 categories)?
- Or create simplified grouping for CLI (e.g., "Development", "Security", "Data")?
- **Recommendation**: Use existing, users need specificity

**Filtering Syntax**:

- `--category <name>` or just positional arg?
- **Recommendation**: Positional (simpler): `/skill-list security/`

**Skill Access Clarification**:

- Skills are loaded by agents automatically (users don't "invoke" skills)
- Does this need to be explained in list output?
- **Recommendation**: Yes, brief usage note at bottom

**Command vs Agent Delegation**:

- Should these be slash commands (`/agent-list`) or natural language ("list agents")?
- **Recommendation**: Both - slash commands that Claude also recognizes naturally

### Assumptions Needing Validation

**Assumption 1**: Users want to see ALL available items

- **Validation needed**: Maybe most users only care about "recommended" or "frequently used"?
- **Alternative**: `/agent-list --popular` shows top 5 most-used

**Assumption 2**: Category is the best grouping for skills

- **Validation needed**: Maybe users think in terms of tasks ("I need testing skills") not categories?
- **Alternative**: Tag-based filtering (`/skill-list --tag python`)

**Assumption 3**: Plain text output is sufficient

- **Validation needed**: Would JSON output be valuable for tooling?
- **Alternative**: `/agent-list --format json` for machine-readable output

**Assumption 4**: Filesystem scanning is fast enough

- **Validation needed**: Test with 177 skill files + 15 agents + 32 commands
- **Alternative**: Pre-generate index file during installation

## 4. Recommendations

### Command Behavior Design

**For /agent-list** (15 agents - show all):

```text
AIDA Agents (15 available)

Core Agents:
  code-reviewer              Code quality, security, and standards
  technical-writer           Documentation for multiple audiences
  devops-engineer            CI/CD and deployment automation
  product-manager            Requirements and PRD creation
  tech-lead                  Architecture and technical design

Data & Analytics:
  data-engineer              dbt, Snowflake, data pipelines
  sql-expert                 Query optimization for Snowflake
  metabase-engineer          BI dashboards and visualizations

Infrastructure:
  aws-cloud-engineer         CDK, CloudFormation, AWS services
  security-engineer          Security hardening and compliance

Specialized:
  [grouped by domain]

→ Agents are invoked automatically by Claude based on task
→ Learn more: ~/.claude/agents/README.md
```

**For /skill-list** (177 skills - require category):

```bash
# No args = show categories
/skill-list

# Output:
Skills Catalog (177 skills across 28 categories)

meta/ (5 skills)              AIDA system development
style-guides/ (8 skills)      Markdown, YAML, code standards
bash-unix/ (7 skills)         Shell scripting, Unix utilities
cli-tools/ (4 skills)         git, gh, aws, docker
testing/ (8 skills)           pytest, Playwright, Jest, k6
frameworks/ (12 skills)       React, FastAPI, Django, Next.js
security/ (20 skills)         Injection prevention, auth patterns
[continues for all 28...]

→ Usage: /skill-list <category> to view skills
→ Search: /skill-list --search <keyword>

# With category = show skills
/skill-list security/

# Output:
Skills: security/ (20 skills)

Injection Attacks:
  sql-injection-prevention        Parameterized queries, ORM safety
  prompt-injection-prevention     AI/LLM attack defense (AIDA-specific!)
  command-injection-prevention    Shell command safety
  xss-prevention                  Cross-site scripting defense
  [continues...]

→ Skills are loaded automatically by relevant agents
→ Location: ~/.claude/skills/<category>/<skill>/
```

**For /command-list** (32 commands, optional filtering):

```bash
# All commands, grouped
/command-list

# Output:
AIDA Commands (32 available, consolidating to 10 groups in v0.1.0)

Core Workflow:
  /start-work <issue>        Begin work on GitHub issue
  /implement                 Guided implementation with auto-commit
  /open-pr [reviewers]       Create pull request with changelog
  /cleanup-main              Post-merge cleanup and branch sync

Development:
  /create-agent [desc]       Create new specialized agent
  /create-command [desc]     Create new workflow command
  /create-issue              Draft GitHub issue locally

Quality & Testing:
  /code-review [focus]       Code review (security/performance/all)
  /test-plan [issue]         Generate comprehensive test plan
  [continues...]

→ Usage: /command-name [args]
→ Help: /command-name --help (for individual command)
→ Consolidation: See milestone v0.1.0 for command restructuring
```

### What Should Be Prioritized

**Phase 1 - MVP** (Week 1):

1. `/agent-list` - Simplest, highest value (small list)
2. Basic `/command-list` - No filtering yet, just grouped display
3. `/skill-list` categories only - Show 28 categories, not individual skills

**Phase 2 - Enhanced** (Week 2):

4. `/skill-list <category>` - Show skills within category
5. `/command-list --category <cat>` - Filter commands
6. Search functionality for both

**Phase 3 - Polish** (Week 3):

7. Performance optimization (caching)
8. Better formatting (tables, colors)
9. Integration with help system

### What Should Be Avoided

**Don't**:

- **Dump all 177 skills in flat list** - Overwhelming, unusable
- **Show full descriptions** - List commands are for scanning, not reading
- **Require exact category names** - Support fuzzy matching ("sec" → "security/")
- **Hardcode lists** - Generate from filesystem for accuracy
- **Make users memorize syntax** - Provide examples in error messages
- **Ignore accessibility** - Ensure screen reader friendly, colorblind safe

**Anti-patterns**:

```bash
# BAD: Wall of text
/skill-list
[177 skills with full descriptions, no grouping]

# BAD: Cryptic names
/sk-ls sec        # Abbreviations are hostile

# BAD: No usage guidance
Available agents: code-reviewer, technical-writer, devops-engineer
[Now what? How do I use these?]
```

**Good patterns**:

```bash
# GOOD: Progressive disclosure
/skill-list                    # Categories only
/skill-list security/          # Skills in category
/skill-list security/sql-injection-prevention  # Specific skill (future)

# GOOD: Clear, full names
/skill-list not /sk-ls

# GOOD: Actionable output
[List with usage hints and next steps]
```

### Implementation Approach

**Recommended Architecture**:

```text
1. CLI Scripts (scripts/discoverability/)
   - scan-agents.sh       # Enumerate ~/.claude/agents/
   - scan-skills.sh       # Enumerate ~/.claude/skills/
   - scan-commands.sh     # Enumerate ~/.claude/commands/

2. Skills (templates/skills/aida-discovery/)
   - agent-lister         # Format agent output
   - skill-lister         # Format skill output (with categorization)
   - command-lister       # Format command output

3. Slash Commands
   - /agent-list          # Invoke skill-lister via claude-agent-manager
   - /skill-list [cat]    # Invoke skill-lister with category filter
   - /command-list [--category cat]  # Invoke command-lister

4. Output Format
   - Use consistent visual hierarchy
   - Color for categories (blue), counts (green)
   - Indentation for grouping
   - Bottom usage hints ("→")
```

**Why this architecture?**

- **Separation of concerns**: Scripts enumerate, skills format, commands invoke
- **Testable**: Each script can be tested independently
- **Cacheable**: Scripts can cache results, skills format from cache
- **Extensible**: Easy to add filtering, search, sorting

### Success Criteria

**Usability**:

- New users can discover agents/skills/commands in <30 seconds
- Experienced users can find specific item in <10 seconds
- Zero-to-useful without reading documentation

**Performance**:

- `/agent-list` completes in <500ms (15 agents, trivial)
- `/skill-list` categories in <1s (28 categories, acceptable)
- `/skill-list <cat>` in <1s (max ~20 skills per category)
- `/command-list` in <500ms (32 commands, trivial)

**Accessibility**:

- Works without color (uses indentation, symbols)
- Screen reader friendly (logical reading order)
- Respects terminal width (no horizontal scrolling)

**Maintainability**:

- Zero manual updates (generates from filesystem)
- Works immediately after adding new agent/skill/command
- Clear error messages when files missing/malformed

## Summary

The discoverability commands are a **critical CLI UX investment** for AIDA's usability. Key success factors:

1. **Category-first for skills** (177 is too many for flat list)
2. **Progressive disclosure** (summary → details on demand)
3. **Actionable output** (show how to use, not just what exists)
4. **Filesystem-driven** (zero manual maintenance)
5. **Consistent with AIDA patterns** (matches existing command style)

The biggest risk is **information overload** with 177 skills. Mitigation: force categorization, make search easy, provide clear visual hierarchy.

**Recommendation**: Implement in 3 phases (MVP → Enhanced → Polish) to validate UX assumptions early and iterate based on real usage.
