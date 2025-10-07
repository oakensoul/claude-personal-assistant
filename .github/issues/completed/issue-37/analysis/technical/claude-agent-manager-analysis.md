---
title: "Technical Analysis - Claude Agent Manager Perspective"
issue: 37
analyst: "claude-agent-manager"
date: "2025-10-06"
complexity: "M"
---

# Technical Analysis: Archive Global Agents and Commands

## Executive Summary

**Complexity**: M (Medium) - Structure preservation straightforward, but privacy scrubbing and validation add complexity

**Key Challenge**: Balance between archiving working templates vs creating generic sanitized versions

**Critical Risk**: Committing user-specific data (learned patterns, absolute paths, usernames) to public repo

## 1. Implementation Approach

### Agent File Structure Preservation

**Core Agents (6)**:

- **Files**: Agent .md with frontmatter + full knowledge/ hierarchy
- **Frontmatter**: YAML block with name, description, model, color
- **Format**: Exact copies (not .template extension) unless path substitution needed
- **Knowledge**: Complete directory tree (core-concepts/, patterns/, decisions/)
- **Validation**: Frontmatter integrity, kebab-case naming, model field consistency

**Specialized Agents (16)**:

- **Location**: `templates/agents/specialized/` subdirectory
- **Installation**: Optional (not auto-deployed by install.sh)
- **Priority**: Phase 2 (P1), defer to reduce initial scope
- **Documentation**: Catalog in README but mark as optional

**Preservation Requirements**:

- Maintain exact directory structure mirroring ~/.claude/agents/
- Preserve YAML frontmatter exactly (no reformatting)
- Keep agent descriptions and capability documentation intact
- Validate model field = "claude-sonnet-4.5" (standard)

### Knowledge Directory Handling

**Structure to Preserve**:

```text
agents/{agent-name}/
├── {agent-name}.md              # Agent definition
└── knowledge/
    ├── index.md                 # Must have frontmatter: agent, updated, knowledge_count
    ├── core-concepts/           # Fundamental documentation
    ├── patterns/                # Reusable patterns
    └── decisions/               # Decision history
```

**Privacy Considerations**:

- **High Risk**: Knowledge directories contain LEARNED patterns from real usage
- **User-specific**: Decision history may reference actual projects/clients
- **Recommendation**: Empty structure with example files OR heavily sanitized content
- **Alternative**: Create NEW generic knowledge from scratch (safer)

**Knowledge Index Validation**:

- Frontmatter completeness: agent, updated, knowledge_count, memory_type
- knowledge_count accuracy (count actual .md files in subdirectories)
- Updated date matches last modification
- External links valid (non-user-specific)

**Scrubbing Requirements**:

- NO absolute paths with usernames
- NO project-specific examples (use generic placeholders)
- NO company/client names
- NO learned behavior patterns from actual usage
- Generic examples only (create fresh if needed)

### Command Metadata Preservation

**Command Structure**:

```yaml
---
name: command-name
description: What this command does
args:
  argument-name:
    description: Purpose of argument
    required: true/false
---
```

**Path Substitution Patterns**:

```bash
# Before (user-specific):
~/.claude/workflow-config.json
/Users/oakensoul/Developer/oakensoul/claude-personal-assistant/.github/
cat ~/.claude/agents/product-manager/instructions.md

# After (portable):
${CLAUDE_CONFIG_DIR}/workflow-config.json
${PROJECT_ROOT}/.github/
cat ${CLAUDE_CONFIG_DIR}/agents/product-manager/instructions.md
```

**Variable Standards**:

- `${PROJECT_ROOT}` - Git root of current project
- `${CLAUDE_CONFIG_DIR}` - User config directory (~/.claude)
- `${AIDA_HOME}` - Framework installation (~/.aida)

**File Extension**:

- `.md.template` - Files requiring variable substitution (processed by install.sh)
- `.md` - Exact copies with no substitution needed

**Commands Requiring Substitution** (8 generic commands):

- create-agent, create-command, create-issue, publish-issue
- expert-analysis, generate-docs, track-time, workflow-init

**Metadata Preservation**:

- Frontmatter args section (required vs optional)
- Workflow step numbering and structure
- Error handling sections
- Examples and success criteria
- Agent invocation references

### Archival Script Design

**Option A: Manual with Checklist** (Recommended for MVP)

- Copy files manually with validation checklist
- Automated scrubbing validation (pre-commit hook)
- Document substitution pattern in README
- Lower risk of automation errors

#### Option B: Automated Script

- Shell script with path substitution logic
- Privacy scrubbing validation (fail on username/path detection)
- Frontmatter validation (yamllint integration)
- Knowledge count verification
- Higher initial effort, reusable for template updates

**Validation Pipeline**:

```bash
# Pre-commit hook checks:
1. yamllint frontmatter blocks
2. No absolute paths (/Users/, /home/)
3. No usernames in content
4. No email addresses or API keys
5. Variables properly formatted (${VAR_NAME})
6. Knowledge index accuracy
7. Markdown linting (MD032, MD031, MD040)
```

**Recommended Approach**: Manual Phase 1, automated validation, then script for Phase 2

## 2. Technical Concerns

### Agent Integrity Validation

**Frontmatter Requirements**:

- All agents must have: name, description, model
- Optional fields: color, temperature
- Model must be "claude-sonnet-4.5" (project standard)
- Name must be kebab-case (match directory/filename)

**Structure Validation**:

- Agent file exists at `templates/agents/{name}/{name}.md`
- Knowledge directory exists (even if empty)
- Knowledge index.md has required frontmatter
- Directory structure matches standard pattern

**Content Integrity**:

- No broken references to removed knowledge files
- Agent invocation patterns documented correctly
- Capabilities section complete
- Examples use generic placeholders (not user data)

**Validation Script**:

```bash
# Check agent integrity
for agent in templates/agents/*/; do
  name=$(basename "$agent")

  # File exists
  [ -f "$agent/$name.md" ] || echo "ERROR: Missing $name.md"

  # Frontmatter valid
  yamllint "$agent/$name.md" || echo "ERROR: Invalid frontmatter"

  # Knowledge structure
  [ -d "$agent/knowledge" ] || echo "ERROR: Missing knowledge/"
  [ -f "$agent/knowledge/index.md" ] || echo "ERROR: Missing index.md"

  # Name consistency
  grep "^name: $name$" "$agent/$name.md" || echo "ERROR: Name mismatch"
done
```

### Knowledge Cross-References

**Internal References**:

- index.md links to knowledge files (check if files exist)
- Relative paths work from knowledge/ directory
- No absolute paths in documentation

**External References**:

- HTTP/HTTPS links valid (not user-specific services)
- Claude Code docs links current
- No internal corporate documentation links

**Agent-to-Agent References**:

- Commands reference correct agent names
- Agent invocation patterns accurate
- No references to non-archived agents

**Resolution Strategy**:

- Validate all links in knowledge files
- Update index.md to match actual files
- Remove references to user-specific agents not in templates
- Document agent dependencies in README

### Command Dependencies

**Agent Invocations**:

- Commands specify which agent handles work
- Agent must exist in templates/ (or be core Claude Code feature)
- Invocation pattern documented in command workflow

**File Dependencies**:

- Commands reference `.claude/workflow-config.json` (document as requirement)
- workflow-state.json usage (runtime file, not template)
- Directory structure assumptions (.github/ vs .claude/)

**External Tool Dependencies**:

- gh CLI (GitHub operations)
- jq (JSON processing)
- git (version control)
- Document in templates/commands/README.md

**Path Dependencies**:

- All project paths use ${PROJECT_ROOT}
- All config paths use ${CLAUDE_CONFIG_DIR}
- All framework paths use ${AIDA_HOME}
- No hardcoded directory names with user context

### Frontmatter Preservation

**YAML Parsing Risks**:

- Preserve exact indentation (2 spaces standard)
- Quoted vs unquoted values (maintain original)
- Multi-line values (description field) with pipe or fold operators
- Comment preservation (if any)

**Required Fields**:

**Agents**:

```yaml
---
name: agent-name               # REQUIRED: kebab-case
description: Brief description # REQUIRED: when to use
model: claude-sonnet-4.5      # REQUIRED: model version
color: blue                    # OPTIONAL: visual identifier
temperature: 0.7               # OPTIONAL: model setting
---
```

**Commands**:

```yaml
---
name: command-name             # REQUIRED: kebab-case
description: What it does      # REQUIRED: purpose
args:                          # OPTIONAL: command arguments
  arg-name:
    description: Purpose       # If args present, required
    required: true/false       # If args present, required
---
```

**Validation**:

- yamllint --strict (fail on warnings)
- Frontmatter block must be first in file
- Closing `---` required
- No tab characters (spaces only)

## 3. Dependencies & Integration

### Claude Code Agent Discovery

**Current Behavior**:

- Agents loaded from `~/.claude/agents/{name}.md`
- Knowledge loaded from `~/.claude/agents/{name}/knowledge/`
- Commands loaded from `~/.claude/commands/{name}.md`

**Template Integration**:

- install.sh must copy templates/ → ~/.claude/
- Variable substitution at install time (.template → .md)
- Preserve frontmatter during copy
- Maintain directory structure exactly

**Discovery Requirements**:

- Agent names must match filename (agent-name.md)
- Knowledge directories must follow standard structure
- No additional registration required (filesystem-based)

**Testing**:

- Fresh install from templates/ should find all agents
- Commands should discover invoked agents
- Knowledge bases should load correctly

### Command Registration

**Current Mechanism**:

- Slash commands auto-discovered from ~/.claude/commands/
- Command name from frontmatter matches filename
- Arguments parsed from args section
- No central registry required

**Template Format**:

- .md.template extension for substitution files
- install.sh processes → .md during installation
- Frontmatter preserved exactly
- Variable expansion happens at install time

**Integration Points**:

- SlashCommand tool reads from ~/.claude/commands/
- Frontmatter args section defines interface
- Command workflow specifies agent invocation

**Validation**:

- Command name matches filename (create-agent.md → name: create-agent)
- Frontmatter args match usage examples
- Referenced agents exist in templates/

### Knowledge Directory Loading

**Loading Mechanism**:

- Agent-specific knowledge loaded when agent invoked
- index.md provides catalog (not auto-loaded)
- Knowledge files loaded on-demand via agent logic
- Relative paths from knowledge/ directory

**Integration Requirements**:

- index.md frontmatter: agent, updated, knowledge_count
- Knowledge files organized in subdirectories
- Relative links work within knowledge/
- External links absolute (https://)

**Template Considerations**:

- Empty knowledge/ structure valid (no files required)
- index.md can have zero knowledge_count
- Example files helpful but not required
- Agent documentation explains knowledge usage

**Testing Strategy**:

- Agent can reference knowledge files correctly
- index.md links resolve
- No broken internal references
- Knowledge loads without errors

## 4. Effort & Complexity

**Overall Complexity**: M (Medium)

### Effort Drivers

**High Effort**:

- Privacy scrubbing validation (automated check needed)
- Path variable substitution (manual find/replace across 8+ commands)
- Knowledge directory sanitization (review 6 agents × 3-5 knowledge files each)
- Documentation creation (3 comprehensive README files)

**Medium Effort**:

- Agent frontmatter validation (yamllint integration)
- Directory structure setup (automated with mkdir -p)
- Knowledge index accuracy (count verification)
- Cross-reference validation (link checking)

**Low Effort**:

- Agent file copying (cp -r with structure preservation)
- Frontmatter preservation (no transformation needed)
- Command file identification (14 files, known list)
- Basic directory mirroring (rsync or cp)

### Complexity Breakdown

**Phase 1 (Core)**: 6 agents + 8 commands

- **Agent archival**: 2-3 hours (with privacy review)
- **Command substitution**: 2-3 hours (variable replacement + validation)
- **Knowledge sanitization**: 3-4 hours (review + scrub)
- **Documentation**: 2-3 hours (3 README files)
- **Validation setup**: 2-3 hours (pre-commit hook)
- **Total**: 11-16 hours

**Phase 2 (Specialized)**: 16 agents to specialized/

- **Agent archival**: 3-4 hours
- **Privacy review**: 2-3 hours
- **Documentation**: 1-2 hours
- **Total**: 6-9 hours

**Testing & Validation**:

- Fresh install test: 1 hour
- Cross-reference validation: 1 hour
- Documentation review: 1 hour
- **Total**: 3 hours

**Grand Total**: 20-28 hours (split across 2 phases)

### Risk Areas

**High Risk**:

- **Privacy leak**: Committing user-specific data (learned patterns, usernames, paths)
  - Mitigation: Automated scrubbing validation in pre-commit hook
  - Impact: Public exposure of private information
  - Probability: High without validation

- **Broken references**: Knowledge cross-references invalid after archival
  - Mitigation: Link validation script
  - Impact: Agents reference non-existent knowledge
  - Probability: Medium

**Medium Risk**:

- **Path substitution errors**: Variables not properly replaced
  - Mitigation: Test on fresh install with different user
  - Impact: Commands fail with hardcoded paths
  - Probability: Medium

- **Frontmatter corruption**: YAML parsing breaks during copy
  - Mitigation: yamllint validation
  - Impact: Agent/command not discoverable
  - Probability: Low

**Low Risk**:

- **Knowledge count mismatch**: index.md count wrong
  - Mitigation: Automated count verification
  - Impact: Documentation inaccuracy (non-breaking)
  - Probability: Medium but low impact

- **Directory structure variation**: Not exact match to ~/.claude/
  - Mitigation: Follow standard structure explicitly
  - Impact: install.sh integration issues
  - Probability: Low

## 5. Questions & Clarifications

### Technical Questions

#### Q1: Template Philosophy

- **Question**: Archive existing user content or create NEW generic templates?
- **Technical Impact**: Privacy risk vs accuracy of templates
- **Recommendation**: Create generic versions (privacy-first)
- **Validation**: Easier to ensure no user data leaked
- **Effort**: Higher (rewrite content) but safer

#### Q2: Knowledge Directory Content

- **Question**: Include actual knowledge files or empty structure with examples?
- **Options**:
  - A) Exclude knowledge/ entirely (structure only)
  - B) Empty structure + README with examples
  - C) Heavily scrubbed and genericized content
- **Recommendation**: Option B (empty + examples)
- **Rationale**: Knowledge is learned from usage (privacy risk), examples show structure

#### Q3: Variable Expansion Timing

- **Question**: When are ${VARS} replaced - install time or runtime?
- **Technical Impact**: Installation complexity, template processing logic
- **Recommendation**: Install time (install.sh processes .template files)
- **Requirement**: install.sh must support variable substitution
- **Validation**: Test with fresh install on different system

#### Q4: Validation Enforcement

- **Question**: Pre-commit hook mandatory or optional?
- **Technical Impact**: Developer workflow, merge blocking
- **Recommendation**: Mandatory for templates/ directory changes
- **Implementation**: Add to .pre-commit-config.yaml with template-specific checks

#### Q5: Specialized Agent Structure

- **Question**: Flat specialized/ directory or categorized subdirectories?
- **Options**:
  - A) `specialized/agent-name/` (flat)
  - B) `specialized/development/`, `specialized/qa/`, etc (categorized)
- **Recommendation**: Option A (flat) for MVP, categorize in README
- **Rationale**: Simpler structure, categories can evolve

### Decisions to Be Made

#### D1: Archive vs Template Approach (CRITICAL)

- **Decision Needed**: Before implementation starts
- **Options**: Archive user content (scrubbed) OR create fresh generic templates
- **Blocker**: Affects all subsequent work
- **Stakeholders**: Privacy/security, AIDA developers, framework users

#### D2: Knowledge Inclusion Strategy

- **Decision Needed**: Before agent archival
- **Options**: Empty structure, example files, scrubbed content, none
- **Blocker**: Affects agent integrity and usefulness
- **Stakeholders**: Framework users (need examples), privacy

#### D3: install.sh Integration

- **Decision Needed**: Before command substitution
- **Question**: Does install.sh already support .template processing?
- **Investigation**: Review install.sh code for variable substitution
- **Blocker**: Commands unusable without proper variable expansion

#### D4: Validation Strictness

- **Decision Needed**: Before pre-commit hook creation
- **Options**: Fail on any issue OR warn with manual review
- **Recommendation**: Fail on privacy issues (mandatory), warn on structure (advisory)
- **Stakeholders**: Developers, CI/CD pipeline

#### D5: Phase 2 Scope

- **Decision Needed**: After Phase 1 completion
- **Options**: Immediate Phase 2, defer to v0.2, selective agent inclusion
- **Recommendation**: Defer to separate issue after Phase 1 validation
- **Rationale**: Validate approach with core agents before scaling

### Areas Needing Investigation

#### I1: Current install.sh Capabilities

- Does it support .template file processing?
- Variable substitution mechanism present?
- How are agents/commands currently deployed?
- Test on fresh system required

#### I2: Existing Agent Content Privacy

- Audit all 6 core agents for user-specific data
- Review knowledge/ directories for learned patterns
- Check decision history for project/client references
- Document scrubbing requirements per agent

#### I3: Command Path Usage Patterns

- Catalog all path references in 14 commands
- Identify which use absolute vs relative paths
- Determine which commands need .template extension
- Map variables to path types (PROJECT_ROOT vs CLAUDE_CONFIG_DIR)

#### I4: Template Testing Strategy

- How to test templates without polluting ~/.claude/?
- Docker container for isolated testing?
- Test user account on same machine?
- CI/CD pipeline integration for validation?

#### I5: Cross-Repository Dependencies

- Do templates reference dotfiles repo content?
- dotfiles-private overlay considerations?
- Stow package structure compatibility?
- Three-repo integration testing needed?

## Recommendations

### Immediate Actions

1. **Audit existing agents** (1-2 hours)
   - Review all 6 core agents for privacy issues
   - Document scrubbing requirements
   - Identify which knowledge/ content can be kept

2. **Review install.sh** (30 minutes)
   - Check for .template processing support
   - Understand current deployment mechanism
   - Identify integration requirements

3. **Create validation script** (2-3 hours)
   - Privacy scrubbing checks (usernames, paths)
   - Frontmatter validation (yamllint)
   - Knowledge count verification
   - Cross-reference checking

### Implementation Strategy

**Recommended Approach**: Phased with validation-first

**Phase 0: Setup** (2-3 hours)

1. Create validation scripts and pre-commit hooks
2. Audit existing content for privacy issues
3. Document variable substitution patterns
4. Set up testing environment

**Phase 1: Core Templates** (11-16 hours)

1. Create generic versions of 6 core agents (not direct archives)
2. Empty knowledge/ structure with example files
3. Variable substitution for 8 generic commands
4. Create 3 comprehensive README files
5. Validate with automated checks

**Phase 2: Specialized Agents** (Defer to separate issue)

- Deferred until Phase 1 validated
- Separate issue for scope control
- Learn from Phase 1 implementation

### Success Criteria

**Privacy Compliance**:

- [ ] No usernames in any template file
- [ ] No absolute paths with user context
- [ ] No learned patterns from real usage
- [ ] No PII (email, API keys, company names)
- [ ] Automated validation passes

**Structural Integrity**:

- [ ] All agents have valid frontmatter
- [ ] Knowledge/ directories follow standard structure
- [ ] index.md knowledge_count accurate
- [ ] Commands have proper args documentation
- [ ] Cross-references valid

**Portability**:

- [ ] Fresh install works on different user account
- [ ] Variables resolve correctly
- [ ] Commands execute without path errors
- [ ] Agents discoverable after install

**Documentation Quality**:

- [ ] templates/README.md complete with variable reference
- [ ] templates/commands/README.md catalogs all commands
- [ ] templates/agents/README.md explains structure
- [ ] Examples use generic placeholders
- [ ] Customization workflow documented

---

**Analysis Date**: 2025-10-06
**Analyst**: claude-agent-manager
**Status**: Ready for stakeholder review
**Next Step**: Decision on Open Questions (especially OQ-1 and OQ-2 from PRD)
