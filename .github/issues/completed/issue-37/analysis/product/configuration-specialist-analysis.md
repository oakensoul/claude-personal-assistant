---
title: "Configuration Specialist Analysis - Issue #37"
issue: 37
agent: configuration-specialist
date: 2025-10-06
status: completed
---

# Configuration Specialist Analysis: Archive Global Agents and Commands

## 1. Domain-Specific Concerns

### Template vs. Exact Copy Decision

**Critical configuration concern**: Over-templating creates maintenance burden

- **Commands**: MUST use `.template` with variable substitution (contain absolute paths)
- **Agents**: Should use exact copies (rarely need substitution)
- **Knowledge directories**: Exact copies (pure documentation)

**Why**:

- Commands reference file paths: `${PROJECT_ROOT}/.claude/workflow-config.json`
- Agents describe behavior: No environment-specific paths
- Knowledge is content: No substitution needed

### Variable Substitution Patterns

**Standardize on these variables**:

- `${PROJECT_ROOT}` - Project directory (replaces `/Users/oakensoul/Developer/oakensoul/claude-personal-assistant`)
- `${CLAUDE_CONFIG_DIR}` - User config directory (replaces `~/.claude`)
- `${AIDA_HOME}` - Framework installation (replaces `~/.aida`)
- `${HOME}` - User home directory (standard environment variable)

**Pattern examples from commands**:

```bash
# Current (absolute):
cat ~/.claude/workflow-config.json

# Template (relative):
cat ${CLAUDE_CONFIG_DIR}/workflow-config.json

# Current (project-specific):
/Users/oakensoul/Developer/oakensoul/claude-personal-assistant/.github/

# Template (portable):
${PROJECT_ROOT}/.github/
```

### Configuration Validation Requirements

**Must validate during installation**:

- All template variables defined in installation context
- No unresolved `${VAR}` placeholders after substitution
- Paths resolve to actual directories/files
- No hardcoded user-specific paths remain

**Validation checklist**:

- [ ] `${PROJECT_ROOT}` resolves to git repository root
- [ ] `${CLAUDE_CONFIG_DIR}` resolves to `~/.claude` or equivalent
- [ ] `${AIDA_HOME}` resolves to `~/.aida` installation directory
- [ ] All substituted paths are valid after generation

### Template Processing Pipeline

**Installation flow**:

1. **Copy exact files**: Agents, knowledge directories → `~/.claude/`
2. **Process templates**: Commands with `.template` extension
3. **Substitute variables**: Replace `${VAR}` with actual values
4. **Remove `.template` extension**: Save as `.md` files
5. **Validate**: Check for unresolved variables

**Example**:

```bash
# Source: templates/commands/cleanup-main.md.template
# Processing: Replace ${PROJECT_ROOT} with actual project path
# Output: ~/.claude/commands/cleanup-main.md
```

## 2. Stakeholder Impact

### Affected Parties

**Framework developers** (high impact):

- Provides historical record of all shipped agents/commands
- Enables comparison between template and generated versions
- Supports versioning and migration strategies

**New users** (medium impact):

- Templates become source of truth for fresh installations
- Clear distinction between what's templated vs. static
- Better understanding of customization points

**Existing users** (low impact):

- No change to their `~/.claude/` directory
- May want to compare their versions with templates
- Could use templates to reset/repair corrupted configs

### Value Delivered

**Version control benefits**:

- Track evolution of commands/agents over time
- Review changes in git history
- Enable rollback if issues discovered

**Installation improvements**:

- Source of truth for generating user configs
- Consistent output across installations
- Easier to test installation process

**Documentation enhancements**:

- Examples of proper agent/command structure
- Reference for creating new agents/commands
- Clear templates for contributors

### Risks and Downsides

**Drift between template and reality**:

- Risk: Templates in repo diverge from `~/.claude/` during development
- Mitigation: Regularly sync or use templates as source during dev mode

**Confusion about which to edit**:

- Risk: Users edit templates instead of their `~/.claude/` files
- Mitigation: Clear README explaining templates vs. user configs

**Maintenance burden**:

- Risk: Every agent/command change needs template update
- Mitigation: Use exact copies where possible (only commands need templates)

## 3. Questions & Clarifications

### Missing Information

**Installation substitution logic**:

- Who performs the variable substitution? (`install.sh` script?)
- When does substitution happen? (During `./install.sh` or on-demand?)
- How are defaults determined? (Environment variables, detection, prompts?)

**Template organization**:

- Should commands be in `templates/commands/` or `templates/.claude/commands/`?
- Mirror `~/.claude/` structure or organize by type?
- How to handle agents with knowledge directories?

**Existing content**:

- Are current `templates/agents/technical-writer.md.template` files following the same pattern?
- Should we align with existing template structure or redesign?

### Decisions Needed

**Directory structure decision**:

```text
Option A: Mirror ~/.claude/ structure
templates/
├── commands/           # Direct mirror
│   ├── cleanup-main.md.template
│   └── ...
└── agents/            # Direct mirror
    ├── product-manager/
    │   ├── product-manager.md
    │   └── knowledge/
    └── ...

Option B: Organized by purpose
templates/
├── user-config/       # What goes in ~/.claude/
│   ├── commands/
│   └── agents/
└── framework/         # What stays in ~/.aida/
    └── ...
```

**Recommendation**: Option A (mirror structure) - easier to understand, simpler install script

**Template naming convention**:

- Commands: `{name}.md.template` (needs substitution)
- Agents: `{name}.md` (exact copy)
- Knowledge: Exact directory copy

**Documentation locations**:

- `templates/README.md` - Overview of template system
- `templates/commands/README.md` - Command-specific guidance
- `templates/agents/README.md` - Agent-specific guidance

### Assumptions Needing Validation

**Assumption 1**: Commands contain project-specific paths

- Validate: Check all 14 commands for absolute paths
- Impact: Determines which need `.template` extension

**Assumption 2**: Agents are environment-agnostic

- Validate: Scan agents for hardcoded paths
- Impact: May need some agents as templates too

**Assumption 3**: Knowledge directories are pure content

- Validate: Check for any path references in knowledge files
- Impact: Determines if knowledge needs processing

**Assumption 4**: Installation script can handle variable substitution

- Validate: Review `install.sh` capabilities
- Impact: May need to enhance installation logic

## 4. Recommendations

### Recommended Approach

**Phase 1: Audit and Categorize** (prerequisite)

1. Scan all 14 commands for variable patterns:
   - Absolute paths → Need `${PROJECT_ROOT}`
   - `~/.claude/` → Need `${CLAUDE_CONFIG_DIR}`
   - `~/.aida/` → Need `${AIDA_HOME}`
2. Scan all agents for hardcoded paths (expect none)
3. Scan knowledge directories for path references

#### Phase 2: Archive with Proper Extension

1. Copy commands → `templates/commands/{name}.md.template`
   - Replace absolute paths with variables
   - Keep everything else identical
2. Copy agents → `templates/agents/{name}/`
   - Exact copy (no `.template` extension)
   - Include entire directory structure
3. Copy knowledge → `templates/agents/{name}/knowledge/`
   - Exact directory copy
   - Preserve all subdirectories

#### Phase 3: Documentation

1. Create `templates/README.md`:
   - Explain template vs. exact copy distinction
   - Document variable substitution patterns
   - Show installation process overview
2. Create `templates/commands/README.md`:
   - List all command templates
   - Document required variables
   - Show example substitution
3. Create `templates/agents/README.md`:
   - List all agent types (core vs. specialized)
   - Explain knowledge directory structure
   - Note that agents are exact copies

#### Phase 4: Validation

1. Create validation script:
   - Check all `.template` files for known variables
   - Detect any remaining absolute paths
   - Verify knowledge directories are complete
2. Test installation:
   - Process templates with test values
   - Verify no unresolved variables
   - Compare output with existing `~/.claude/`

### Structure Recommendation

```text
templates/
├── README.md                          # Template system overview
├── commands/                          # Commands with substitution
│   ├── README.md                      # Command variables and usage
│   ├── cleanup-main.md.template
│   ├── create-agent.md.template
│   ├── create-command.md.template
│   ├── create-issue.md.template
│   ├── expert-analysis.md.template
│   ├── generate-docs.md.template
│   ├── implement.md.template
│   ├── open-pr.md.template
│   ├── publish-issue.md.template
│   ├── start-work.md.template
│   ├── track-time.md.template
│   └── workflow-init.md.template
└── agents/                            # Agents as exact copies
    ├── README.md                      # Agent structure and types
    ├── product-manager/               # Core agent example
    │   ├── product-manager.md
    │   ├── README.md
    │   └── knowledge/
    │       ├── index.md
    │       ├── preferences.md
    │       ├── patterns.md
    │       └── stakeholders.md
    ├── tech-lead/                     # Another core agent
    │   ├── tech-lead.md
    │   └── knowledge/
    │       └── ...
    ├── devops-engineer/               # Specialized agent
    │   ├── devops-engineer.md
    │   └── knowledge/
    │       └── ...
    └── [... all other agents ...]
```

### Prioritization

**High Priority** (must have):

1. Archive all 14 commands with variable substitution
2. Create `templates/README.md` explaining system
3. Document variable patterns clearly

**Medium Priority** (should have):

1. Archive all agents with full directory structure
2. Create command/agent specific READMEs
3. Validate no hardcoded paths remain

**Low Priority** (nice to have):

1. Automated validation script
2. Installation test suite
3. Template comparison tool

### What to Avoid

**Don't over-template**:

- Only use `.template` for files needing substitution
- Keep agents as exact copies (no unnecessary variables)
- Avoid inventing variables that aren't needed

**Don't restructure unnecessarily**:

- Mirror `~/.claude/` structure in templates
- Keep existing agent organization
- Don't rename or reorganize during archival

**Don't lose information**:

- Include ALL knowledge subdirectories
- Preserve directory structure exactly
- Keep all documentation and examples

**Don't skip validation**:

- Check for remaining absolute paths
- Verify all variables are documented
- Test installation process before committing

## Configuration System Integration

### Template Processing Engine

**Recommended implementation** (for install.sh):

```bash
# Variable substitution function
substitute_template_vars() {
    local template_file="$1"
    local output_file="$2"

    # Read template
    local content
    content=$(cat "$template_file")

    # Substitute variables
    content="${content//\${PROJECT_ROOT}/$PROJECT_ROOT}"
    content="${content//\${CLAUDE_CONFIG_DIR}/$CLAUDE_CONFIG_DIR}"
    content="${content//\${AIDA_HOME}/$AIDA_HOME}"
    content="${content//\${HOME}/$HOME}"

    # Write output
    echo "$content" > "$output_file"
}

# Process all command templates
for template in templates/commands/*.template; do
    output="${template%.template}"
    output="${output/templates\/commands/$CLAUDE_CONFIG_DIR/commands}"
    substitute_template_vars "$template" "$output"
done
```

### Validation Rules

**Pre-commit validation** (prevent bad templates):

- All `.template` files must use only documented variables
- No absolute paths except in comments/examples
- All referenced variables must be in substitution list

**Post-installation validation** (ensure correct output):

- No `${VAR}` patterns remain in generated files
- All paths resolve to actual locations
- Generated files match expected structure

## Success Criteria

**Archival complete when**:

- All 14 commands archived with proper variable substitution
- All agents archived with complete knowledge directories
- Three README files created (main, commands, agents)
- No hardcoded user-specific paths in templates
- Directory structure mirrors `~/.claude/` organization

**Quality indicators**:

- Can generate fresh `~/.claude/` from templates alone
- Installation script handles all variable substitution
- Validation catches template errors before commit
- Documentation explains system clearly to contributors

---

**Next Steps**: Review this analysis with team, make structure decisions, then proceed with systematic archival following the phased approach.
