# Q&A Log - Issue #37

**Date**: 2025-10-06

**Participants**: User, Expert Analysis System (PM, Tech Lead, 10 specialist agents)

## Question Responses

### Q1: Template vs Archive Philosophy

**Decision**: **A** (Create generic templates) with caveat

- Create NEW generic templates (privacy-first)
- **BUT**: Preserve any learnings that are NOT privacy risks
- **Action**: Manual review during archival - keep generic patterns, remove user-specific content

### Q2: Knowledge Directory Content Strategy

**Decision**: **C** (Scrubbed and genericized content)

- Include knowledge content where it adds value
- Scrub all privacy violations (usernames, paths, learned patterns from real usage)
- Genericize examples and patterns

### Q3: Variable Expansion Timing

**Decision**: **RUNTIME (by Claude's intelligence)**

- Variables resolved at runtime when Claude executes commands
- Claude intelligently determines context (project root, config dir, etc.)
- Commands remain "globally useable" across different projects
- **No install-time processing needed** - simpler architecture
- **Implication**: No .template extension needed (just .md files with ${VARS})

### Q4: Specialized Agent Installation

**Decision**: **A** (Core default, specialized optional)

- 6 core agents installed by default
- 16 specialized agents in `templates/agents/specialized/` (optional)

### Q5: Variable Resolution Error Handling

**Decision**: **B** (Fail with clear error message)

- If PROJECT_ROOT undefined: fail install with helpful error
- Safer than silent fallback to $HOME
- Provides clear feedback to user

### Q6: Template Update Mechanism

**Decision**: **A** (Manual sync for now)

- Manual sync when agents stabilize
- Automated workflow deferred to future iteration

### Q7: Dev Mode Template Processing

**Decision**: **EXPERIMENTAL - TRY AND ITERATE**

- Need to experiment with architecture to see what works
- Proposed: Process/install to `.aida/` folder structure
- Stow from `.aida/{agents|commands}/` into `.claude/{agents|commands}/`
- **Action**: Implement initial approach, iterate based on what works
- **Note**: Combined with Q3 decision, this becomes simpler - just copy .md files (no processing)

### Q8: Private Command Override Mechanism

**Decision**: **A** (Stow overlay)

- `dotfiles-private/.claude/` overlays via stow
- Consistent with dotfiles approach

## Follow-up Actions

1. ~~**Q3 Deep Dive**~~: RESOLVED - Runtime resolution by Claude
2. **Q7 Architecture**: Implement and iterate - try `.aida/` → stow → `.claude/` flow
3. **Q1/Q2 Implementation**: Create scrubbing checklist that preserves generic learnings

## Architecture Implications

### Simplified Flow (based on Q3 + Q7 decisions)

```text
templates/commands/*.md (with ${VARS} as-is)
templates/agents/*.md
    ↓ [install.sh - simple copy, no processing]
~/.aida/commands/*.md (still contains ${VARS})
~/.aida/agents/*.md
    ↓ [stow/symlink]
~/.claude/commands/*.md → symlink to ~/.aida/commands/*.md
~/.claude/agents/*.md → symlink to ~/.aida/agents/*.md
    ↓ [Claude reads and resolves ${VARS} intelligently at runtime]
Command executes with correct context
```

### Key Benefits

- No .template extension needed (just .md files)
- No install-time variable processing (simpler install.sh)
- Commands remain globally useable across projects
- Claude resolves ${PROJECT_ROOT} based on current working directory
- Claude resolves ${CLAUDE_CONFIG_DIR} and ${AIDA_HOME} from environment

## Key Insights

- **Privacy-first but practical**: Keep valuable generic patterns while scrubbing user-specific data
- **Installation flow needs clarity**: `.template` files → processed in `.aida/` → stowed to `.claude/`
- **Variable expansion is nuanced**: Not one-size-fits-all, needs per-command evaluation
