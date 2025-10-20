---
title: "Q&A Log - Discoverability Commands"
issue: 54
date: 2025-10-20
session: 1
---

# Q&A Session Log

## Question 1: Skills Catalog Location & Architecture ⚠️ CRITICAL

**Question**: Where are the 177 skills stored? What is the file format? How do they integrate with claude-agent-manager?

**Answer**: Skills will be stored in `templates/skills/` and installed to `~/.claude/skills/{skill}/{skill.md}`

**Impact**:

- Unblocks `/skill-list` implementation
- Confirms filesystem-based approach (consistent with agents/commands)
- File naming pattern: `{skill}/{skill.md}` (matches agent pattern)

**Action Items**:

- Update architecture to include `~/.claude/skills/` scanning
- Implement `scripts/list-skills.sh` with same pattern as agents/commands
- Move `/skill-list` from Phase 2 to Phase 1

---

## Question 2: Category Taxonomy

**Question**: Single category per command or multiple categories? Approve 8-category taxonomy?

**Answer**: **Single category only**

**Rationale**: Forces clarity, simpler filtering, no ambiguity

**Impact**:

- Frontmatter: `category: workflow` (string, not array)
- Validation: Reject multi-value categories
- Filtering: Simpler implementation

---

## Question 3: Output Format

**Question**: Plain text, markdown tables, or both? Pagination? JSON support?

**Answer**: **Plain text tables by default, `--format json` optional**

**Impact**:

- Default: Human-readable tables with colors
- Optional: `--format json` for automation
- Both formats must be implemented in Phase 1 (not deferred)
- Increases Phase 1 effort by ~4-6 hours

**Implementation**:

```bash
/agent-list                    # Plain text table
/agent-list --format json      # JSON output
/command-list --category workflow --format json
```text

---

## Question 4: Symlink Handling

**Question**: How to deduplicate symlinks in dev mode?

**Answer**: **Use realpath for deduplication**

**Implementation**:

- Canonicalize paths with `realpath` (or portable fallback)
- Track seen canonical paths in associative array
- Show canonical path in output (not symlink)

---

## Question 5: Version Display

**Question**: Should listings show agent/command/skill versions?

**Answer**: **Yes, add version field and show in output**

**Impact**:

- Add `version` field to frontmatter schema
- Display version in output tables
- Migration: Add version to existing commands (default: "1.0.0"?)
- Increases migration effort by ~1 hour

**Frontmatter**:

```yaml
---
name: agent-list
version: 1.0.0
category: meta
description: List all available agents
---
```text

**Output**:

```text
Name         Version  Category  Description
agent-list   1.0.0    meta      List all available agents
```text

---

## Question 6: Error Handling Severity

**Question**: Missing/malformed frontmatter - error or warning?

**Answer**: **Warning when reading lists** (don't fail, graceful degradation)

**Implementation**:

- Parse frontmatter, validate required fields
- If missing/invalid: Print warning, skip entry, continue
- Collect all warnings, display at end
- Exit code 0 (success with warnings)

**Example**:

```text
⚠ Warning: Invalid frontmatter in ~/.claude/agents/broken-agent/broken-agent.md
  Missing required field: description

Agents Found: 14 (1 skipped due to errors)
```text

---

## Question 7: Caching Strategy

**Question**: Should discovery results be cached?

**Answer**: **No caching needed** - shouldn't take up significant resources

**Rationale**:

- Fast filesystem scans (<500ms agents, <1s skills)
- Low resource usage
- Always fresh results (no cache invalidation complexity)

**Action**: Remove caching from roadmap entirely

---

## Question 8: JSON Output Support

**Question**: Support `--format json` for automation?

**Answer**: **Yes, must support `--format json` in Phase 1**

**Impact**:

- JSON output required for all three commands
- Phase 1 scope increase (was deferred to Phase 2)
- Additional effort: ~4-6 hours (JSON formatting + validation)

**JSON Schema**:

```json
{
  "type": "agents",
  "count": 15,
  "global": [
    {
      "name": "product-manager",
      "version": "1.0.0",
      "description": "Product requirements and stakeholder analysis",
      "path": "${CLAUDE_CONFIG_DIR}/agents/product-manager"
    }
  ],
  "project": [
    {
      "name": "custom-agent",
      "version": "1.0.0",
      "description": "Project-specific agent",
      "path": "${PROJECT_ROOT}/.claude/agents/custom-agent"
    }
  ]
}
```text

---

## Question 9: AIDA Meta-Skills (Added During Analysis)

**Question**: Should we create foundational skills that contain comprehensive knowledge about agents, skills, and commands?

**Answer**: **Yes, create three AIDA meta-skills** (aida-agents, aida-skills, aida-commands)

**Rationale**:

- Provides `claude-agent-manager` (aida) with deep knowledge about AIDA's object model
- Enables intelligent assistance with creation, validation, and discovery
- Slash commands delegate to agent with skills (not direct scripts)
- AI-enhanced responses instead of static script output

**Impact**:

- Adds foundational knowledge layer
- Commands invoke agent with skills → agent invokes scripts
- Phase 1 effort increase: +18-24 hours

**Skills to Create**:

1. `aida-agents.md` - Complete knowledge about agent structure, creation, validation, listing
2. `aida-skills.md` - Complete knowledge about skill structure, creation, validation, listing
3. `aida-commands.md` - Complete knowledge about command structure, creation, validation, listing

---

## Summary of Decisions

### Scope Changes

**Added to Phase 1** (originally Phase 2 or not in scope):

- ✅ AIDA meta-skills (aida-agents, aida-skills, aida-commands)
- ✅ `/skill-list` command (skills location clarified)
- ✅ `--format json` support (must-have for automation)
- ✅ Version field and display

**Phase 1 Effort Increases**:

- Meta-skills: +18-24 hours
- Skills listing: +4-6 hours
- JSON output: +3-4 hours
- Version field migration: +1-2 hours
- **Total increase**: +29-39 hours

**New Phase 1 Estimate**: 59-85 hours (was 30-46 hours initially)

### Architecture Decisions

1. **Skills location**: `templates/skills/` → `~/.claude/skills/{skill}/{skill.md}`
2. **Category model**: Single category only (string, not array)
3. **Output formats**: Plain text (default) + JSON (--format json)
4. **Symlink handling**: Realpath deduplication
5. **Version display**: Required field, shown in output
6. **Error handling**: Warning + skip (graceful degradation)
7. **Caching**: Not implemented (unnecessary)

### Updated Requirements

**AIDA meta-skills required**:

- `aida-agents.md` - Agent knowledge + list-agents.sh integration
- `aida-skills.md` - Skill knowledge + list-skills.sh integration
- `aida-commands.md` - Command knowledge + list-commands.sh integration

**All three commands must**:

- Delegate to claude-agent-manager with appropriate skill
- Support two-tier scanning (user + project)
- Support plain text table output (default)
- Support JSON output (`--format json`)
- Display version field
- Handle errors gracefully (warnings, not failures)

---

## Next Steps

1. Update PRD with skills location decision
2. Update TECH_SPEC with JSON output requirement (Phase 1)
3. Add version field to frontmatter schema
4. Update effort estimates for Phase 1
5. Proceed to implementation summary
