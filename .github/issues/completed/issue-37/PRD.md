---
title: "Product Requirements Document - Issue #37"
issue: 37
version: "1.0"
date: "2025-10-06"
status: "approved"
---

# PRD: Archive Global Agents and Commands to Templates

## Executive Summary

Archive existing agents and commands from `~/.claude/` to `templates/` directory to create version-controlled reference baseline for AIDA framework. Critical for: (1) Fresh installations get proven templates, (2) Development team has committed reference state, (3) Portability through variable substitution enables multi-environment deployment.

**Value**: Establishes foundation for portable, reusable templates distributed via install.sh, dotfiles integration, and private configuration overlays.

**Critical Success Factor**: Path variable substitution MUST work correctly across three-repo ecosystem (AIDA, dotfiles, dotfiles-private).

## Stakeholder Analysis

### Framework Users (Primary)

**Concerns**:

- Need working templates, not broken absolute paths
- Want examples for creating custom agents/commands
- Require clear documentation on customization

**Priorities**:

- Zero-friction installation
- Portable templates across systems
- Discoverable commands/agents

**Recommendations**:

- Use `${PROJECT_ROOT}`, `${CLAUDE_CONFIG_DIR}`, `${AIDA_HOME}` consistently
- Create comprehensive README with variable documentation
- Test installation on clean system

### AIDA Developers (Secondary)

**Concerns**:

- Maintenance burden of dual locations (templates/ and ~/.claude/)
- Version drift between template and working copies
- Clear structure for future agent development

**Priorities**:

- Committed baseline for regression testing
- Template structure consistency
- Pre-commit validation prevents broken templates

**Recommendations**:

- Archive as committed snapshot, not active workspace
- Document sync workflow (when to update templates/)
- Add validation to CI pipeline

### Dotfiles Users (Integration)

**Concerns**:

- GNU stow compatibility with templates
- Private overlay without conflicts
- Consistent environment across machines

**Priorities**:

- Templates work via stow installation
- Private configs can override public templates
- Updates propagate cleanly

**Recommendations**:

- Test stow integration separately
- Document override mechanism
- Support selective installation

### Privacy/Security (Critical)

**Concerns**:

- User-generated content contains learned patterns (NOT generic templates)
- Absolute paths reveal username, directory structure, system organization
- Knowledge directories are LEARNED from usage (privacy risk)

**Priorities**:

- NO user-specific data in public repo
- Generic templates with placeholders (not archives)
- Clear public/private boundary

**Recommendations**:

- Create NEW generic templates (don't directly archive user content)
- Mandatory scrubbing: username, paths, learned patterns
- Exclude or sanitize knowledge/ directories

## Requirements

### Functional Requirements

**FR-1**: Archive 14 commands with path variable substitution

- Replace absolute paths with `${PROJECT_ROOT}`, `${CLAUDE_CONFIG_DIR}`, `${AIDA_HOME}`
- Use `.template` extension ONLY for files needing substitution
- Preserve frontmatter, args, instruction content exactly

**FR-2**: Archive agents with complete directory structure

- Core agents (6): Full knowledge/ hierarchy preserved
- Specialized agents (16): Archive to specialized/ subdirectory (optional install)
- Exact copies (not .template) unless path substitution needed
- Preserve YAML frontmatter integrity

**FR-3**: Create documentation hierarchy

- `templates/README.md` - Template system overview, variable reference, installation process
- `templates/commands/README.md` - Command catalog, variable usage, examples
- `templates/agents/README.md` - Agent structure, knowledge directories, categories

**FR-4**: Knowledge directory handling

- Preserve full hierarchy (core-concepts/, patterns/, decisions/)
- Sanitize user-specific content before archiving
- Validate index.md knowledge_count accuracy
- Use exact copies (no variable substitution in knowledge/)

**FR-5**: Variable substitution pattern

- `${PROJECT_ROOT}` - Project git root directory
- `${CLAUDE_CONFIG_DIR}` - User config directory (~/.claude)
- `${AIDA_HOME}` - Framework installation (~/.aida)
- Document in templates/README.md with examples

### Non-Functional Requirements

**NFR-1**: Portability

- Templates work on any system (no hardcoded paths)
- Cross-platform compatible (macOS, Linux)
- No OS-specific assumptions

**NFR-2**: Privacy Protection

- NO usernames in content
- NO absolute paths with user info
- NO learned patterns from real usage
- NO PII (email, API keys, company names)

**NFR-3**: Maintainability

- Mirror ~/.claude/ structure in templates/
- Clear separation: core vs specialized agents
- Validation prevents broken templates (CI check)

**NFR-4**: Installation Compatibility

- install.sh can process templates correctly
- GNU stow compatible structure
- Selective installation supported (core vs specialized)

**NFR-5**: Documentation Quality

- Variable substitution clearly explained
- Examples for customization
- Cross-references between related commands/agents

## Success Criteria

**SC-1**: Installation Test

- Fresh install from templates/ creates working ~/.claude/
- All path variables resolve correctly
- Commands execute without path errors

**SC-2**: Portability Validation

- Templates install on different user accounts
- Different directory structures work correctly
- No hardcoded user-specific data

**SC-3**: Documentation Completeness

- New user can discover available commands/agents
- Variable substitution pattern documented with examples
- Customization workflow clear

**SC-4**: Privacy Compliance

- Automated scrubbing check passes (no usernames, paths, PII)
- Knowledge directories sanitized or excluded
- Pre-commit hook validates templates

**SC-5**: Structural Integrity

- All knowledge/ hierarchies complete
- Agent frontmatter validated
- README files in all directories

## Open Questions

**OQ-1**: Template vs Archive Philosophy

- **Question**: Create NEW generic templates or archive existing user content?
- **Impact**: Privacy risk vs development effort
- **Recommendation**: Create generic templates (privacy-first approach)
- **Decision needed**: Before implementation starts

**OQ-2**: Knowledge Directory Inclusion

- **Question**: Include full knowledge/ dirs or empty structure only?
- **Options**: (A) Exclude entirely, (B) Empty structure, (C) Scrubbed and genericized
- **Impact**: Privacy, repo size, template usefulness
- **Recommendation**: Option B (empty structure with README examples)
- **Decision needed**: Per-agent basis

**OQ-3**: Specialized Agent Installation

- **Question**: Install all 22 agents by default or selective?
- **Impact**: Namespace pollution vs completeness
- **Recommendation**: Core agents default, specialized optional
- **Decision needed**: During install.sh enhancement

**OQ-4**: Template Update Mechanism

- **Question**: How do ~/.claude/ changes propagate to templates/?
- **Impact**: Maintenance burden, version drift
- **Recommendation**: Manual sync when agents stabilize (not automatic)
- **Decision needed**: Document in templates/README.md

**OQ-5**: Variable Expansion Timing

- **Question**: When are ${VARS} replaced - install time or runtime?
- **Impact**: Installation complexity, portability
- **Recommendation**: Install time (install.sh processes .template files)
- **Decision needed**: Confirm with install.sh maintainer

## Recommendations

### Recommended Approach

**Two-Phase Strategy**:

**Phase 1: Core Framework** (Priority: P0)

1. Archive 6 core agents with knowledge/ (claude-agent-manager, code-reviewer, devops-engineer, product-manager, tech-lead, technical-writer)
2. Archive 8 generic commands with ${PROJECT_ROOT} substitution (create-agent, create-command, create-issue, publish-issue, expert-analysis, generate-docs, track-time, workflow-init)
3. Create templates/README.md with variable documentation
4. Create command/agent README files with catalogs
5. Mandatory scrubbing validation (no usernames, paths, PII)

**Phase 2: Specialized Agents** (Priority: P1)

1. Archive 16 specialized agents to templates/agents/specialized/
2. Document in README but don't auto-install
3. Enhanced discovery (categorization, usage examples)

**Rationale**:

- Prioritize quality over completeness
- Protect user privacy (generic templates not user archives)
- Core agents universally applicable
- Specialized agents optional (domain-specific)

### MVP Scope

**In Scope**:

- ✅ Archive 6 core agents + 8 generic commands
- ✅ Path variable substitution in commands
- ✅ Basic README with file listings + variable reference
- ✅ Scrubbing validation (automated check)
- ✅ Empty knowledge/ structure with examples

**Out of Scope** (Future):

- ❌ Template processing in install.sh (separate issue)
- ❌ Automated sync workflow (manual for now)
- ❌ Rich command catalog with examples (basic listing sufficient)
- ❌ Template versioning strategy (v0.2 feature)
- ❌ GNU stow package creation (dotfiles repo)

### Prioritization

**P0 - Must Have**:

1. Archive 6 core agents with full knowledge/ structure
2. Archive 8 generic commands with ${PROJECT_ROOT} substitution
3. Scrubbing validation (no usernames, absolute paths, PII)
4. templates/README.md with variable reference
5. templates/commands/README.md with command catalog
6. templates/agents/README.md with agent catalog

**P1 - Should Have**:

1. Archive 16 specialized agents to specialized/ subdirectory
2. Knowledge directory sanitization (remove user-specific content)
3. Pre-commit validation hook
4. Installation test (fresh ~/.claude/ from templates/)

**P2 - Nice to Have**:

1. Agent categorization (core/development/quality/documentation)
2. Cross-references between related commands
3. CI workflow for template validation
4. Migration guide for template updates

### What to Defer

**Defer to Future Issues**:

- Template installation logic in install.sh (requires separate design)
- Stow package in dotfiles repo (integration work)
- Template version management (premature)
- Automated template sync workflow (manual sufficient for v0.1)
- Command discovery mechanism (CLI enhancement)

---

## Implementation Notes

### Directory Structure

```text
templates/
├── README.md                          # System overview, variables, installation
├── commands/                          # Commands with substitution
│   ├── README.md                      # Command catalog, variable usage
│   ├── create-agent.md.template
│   ├── create-command.md.template
│   ├── create-issue.md.template
│   ├── expert-analysis.md.template
│   ├── generate-docs.md.template
│   ├── publish-issue.md.template
│   ├── track-time.md.template
│   └── workflow-init.md.template
└── agents/                            # Agents as exact copies
    ├── README.md                      # Agent structure, categories
    ├── claude-agent-manager/
    │   ├── claude-agent-manager.md
    │   └── knowledge/
    │       ├── index.md
    │       ├── core-concepts/
    │       ├── patterns/
    │       └── decisions/
    ├── code-reviewer/
    ├── devops-engineer/
    ├── product-manager/
    ├── tech-lead/
    ├── technical-writer/
    └── specialized/                   # Optional agents
        ├── README.md
        └── [16 specialized agents]
```

### Scrubbing Checklist

**Pre-commit validation must check**:

- [ ] No absolute paths (all use ${VARS})
- [ ] No usernames in content
- [ ] No email addresses
- [ ] No API keys or tokens
- [ ] No company/client names
- [ ] Knowledge dirs sanitized or empty
- [ ] Examples use placeholders
- [ ] Templates tested on clean install

### Variable Substitution Examples

**Commands** (use .template extension):

```markdown
# Before (user-specific):
cat ~/.claude/workflow-config.json
/Users/oakensoul/Developer/oakensoul/claude-personal-assistant/.github/

# After (portable):
cat ${CLAUDE_CONFIG_DIR}/workflow-config.json
${PROJECT_ROOT}/.github/
```

**Agents** (exact copy, no .template):

- No path substitution needed (describe behavior, not locations)
- Preserve frontmatter exactly
- Knowledge/ directories copied as-is (after sanitization)

---

**Next Steps**: Review PRD with team, make decisions on open questions (especially OQ-1 and OQ-2), then proceed with Phase 1 implementation following the phased approach.
