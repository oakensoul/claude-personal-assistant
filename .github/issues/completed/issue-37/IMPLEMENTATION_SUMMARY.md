# Implementation Summary: Issue #37

## Overview

- **What**: Archive agents/commands from ~/.claude/ to templates/ as version-controlled baseline
- **Why**: Enable portable, reusable templates across AIDA ecosystem (framework, dotfiles, private configs)
- **Approach**: Create generic templates with runtime variable resolution by Claude (no install-time processing)

## Key Decisions

### 1. **Generic Templates with Selective Learning Preservation** (Q1)

- Create NEW generic templates (not direct user content archives)
- Preserve learnings that are NOT privacy risks (generic patterns, best practices)
- Remove user-specific content (usernames, paths, personal examples)

### 2. **Scrubbed Knowledge Content** (Q2)

- Include genericized knowledge/ content where valuable
- Scrub all privacy violations (usernames, learned patterns from usage)
- Provide examples using placeholders and generic scenarios

### 3. **Runtime Variable Resolution** (Q3) ⭐ MAJOR SIMPLIFICATION

- Claude resolves ${VARS} intelligently at runtime (not install-time)
- Commands remain "globally useable" across different projects
- **No .template extension needed** - just .md files with ${VARS}
- **No install-time processing** - simpler install.sh
- Variables:
  - `${PROJECT_ROOT}` - Resolved from current working directory/git root
  - `${CLAUDE_CONFIG_DIR}` - Resolved from environment (~/.claude)
  - `${AIDA_HOME}` - Resolved from environment (~/.aida)

### 4. **Core vs Specialized Agents** (Q4)

- 6 core agents installed by default (universally applicable)
- 16 specialized agents in templates/agents/specialized/ (optional)

### 5. **Strict Error Handling** (Q5)

- Fail with clear error if PROJECT_ROOT undefined
- No silent fallback - explicit user feedback

### 6. **Manual Template Sync** (Q6)

- Manual sync workflow for v0.1
- Document when/how to update templates/
- Automated sync deferred to future iteration

### 7. **Experimental Architecture** (Q7)

- Try `.aida/` → stow → `.claude/` flow
- Iterate based on what works
- Simplified by Q3 decision (just copy .md files, no processing)

### 8. **Private Override via Stow** (Q8)

- dotfiles-private/.claude/ overlays public templates
- Consistent with dotfiles approach

## Implementation Scope

### In Scope

- ✅ Archive 6 core agents to templates/agents/
- ✅ Archive 8 generic commands to templates/commands/
- ✅ Create scrubbed, genericized knowledge/ content
- ✅ Privacy validation script (detect violations)
- ✅ Documentation (3 README files with catalogs)
- ✅ Keep ${VARS} as-is in .md files (no .template extension)

### Out of Scope (Deferred)

- ❌ install.sh template processing (no longer needed for v0.1)
- ❌ Automated template sync workflow
- ❌ 16 specialized agents (Phase 2)
- ❌ GNU stow package creation (dotfiles repo)
- ❌ Template versioning strategy

## Technical Approach

### Simplified Architecture

```text
Repository (templates/)
    ↓
templates/commands/*.md (with ${VARS})
templates/agents/*.md
    ↓ [install.sh - simple copy]
~/.aida/commands/*.md (with ${VARS})
~/.aida/agents/*.md
    ↓ [stow/symlink - experimental]
~/.claude/commands/*.md
~/.claude/agents/*.md
    ↓ [Claude reads and resolves ${VARS} at runtime]
Execution with correct context
```

### Components to Build

1. **templates/commands/** (8 files)
   - create-agent.md
   - create-command.md
   - create-issue.md
   - publish-issue.md
   - expert-analysis.md
   - generate-docs.md
   - track-time.md
   - workflow-init.md

2. **templates/agents/** (6 core agents)
   - claude-agent-manager/
   - code-reviewer/
   - devops-engineer/
   - product-manager/
   - tech-lead/
   - technical-writer/

3. **scripts/validate-templates.sh**
   - Detect absolute paths (/Users/, /home/)
   - Detect usernames in content
   - Detect PII (emails, phone numbers)
   - Validate YAML frontmatter
   - Check knowledge/ structure integrity

4. **Documentation**
   - templates/README.md - Variable reference, installation
   - templates/commands/README.md - Command catalog
   - templates/agents/README.md - Agent structure guide

5. **Pre-commit Integration**
   - Add validation hook for templates/
   - Block commits with privacy violations

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Privacy leak (usernames, learned patterns) | HIGH | Three-layer validation, manual review, genericize content |
| Knowledge content too generic (not useful) | MEDIUM | Balance: include valuable patterns, scrub user-specific data |
| Runtime variable resolution doesn't work | HIGH | Test with Claude, document expected behavior |
| Stow integration issues | MEDIUM | Experimental approach, iterate based on results |

## Success Criteria

- [ ] Fresh install creates working ~/.claude/ from templates
- [ ] No privacy violations (automated scan passes)
- [ ] Commands contain ${VARS} that Claude can resolve at runtime
- [ ] Knowledge directories have useful genericized content
- [ ] Documentation enables users to discover/customize agents
- [ ] All linting passes (markdownlint, yamllint, shellcheck)

## Effort Estimate

**Total**: 16-20 hours (reduced from original 18-24 due to Q3 simplification)

### Breakdown

1. **Privacy Validation Infrastructure** (4-5 hours)
   - Write validation script
   - Add pre-commit hooks
   - Test validation logic

2. **Command Archival** (3-4 hours)
   - Copy 8 commands to templates/commands/
   - Keep ${VARS} as-is (no processing)
   - Validate each command

3. **Agent Archival** (4-5 hours)
   - Copy 6 core agent definitions
   - Genericize knowledge/ content
   - Scrub privacy violations

4. **Documentation** (3-4 hours)
   - templates/README.md (variable reference)
   - commands/README.md (catalog)
   - agents/README.md (structure guide)

5. **Testing & Validation** (2-3 hours)
   - Privacy scan
   - Manual review
   - Documentation review

## Next Steps

1. Create privacy validation script (blocks all other work)
2. Audit existing ~/.claude/ content for privacy violations
3. Archive commands (keep ${VARS}, no .template extension)
4. Archive agents with genericized knowledge
5. Write comprehensive README documentation
6. Test with Claude to verify runtime variable resolution
7. Manual review and iteration

## Notes

**Key Insight**: Runtime variable resolution by Claude eliminates need for complex install-time template processing, significantly simplifying the architecture and making commands truly "globally useable."

**Experimental Elements**: The .aida/ → stow → .claude/ flow needs validation. Be prepared to iterate based on what works in practice.

**Privacy Priority**: Better to over-scrub than risk leaking user data. When in doubt, genericize or exclude content.

---

**Location**: `.github/issues/in-progress/issue-37/`
**Branch**: `milestone-v0.1/task/37-archive-global-agents-and-commands`
**Related Documents**: PRD.md, TECH_SPEC.md, qa-log.md
