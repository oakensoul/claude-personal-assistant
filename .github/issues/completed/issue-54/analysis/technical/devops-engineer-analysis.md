---
title: "DevOps Engineer Analysis - Issue #54"
issue: 54
analyst: devops-engineer
created: 2025-10-20
status: draft
complexity: M
---

# DevOps Engineer Analysis - Discoverability Commands

## 1. Implementation Approach

### Deployment & Distribution Strategy

**CLI Script Packaging**:

- Scripts install to `${AIDA_DIR}/scripts/` (copied/symlinked)
- Symlinked into `~/.claude/` namespace (`.aida/scripts/`) for discoverability
- No PATH manipulation required (invoked via slash commands)
- Scripts must be self-contained with no external dependencies

**Installation Integration**:

- Add to `install.sh` template installation flow (already established pattern)
- Use existing `templates.sh` module's `install_templates()` function
- Install scripts to `~/.claude/scripts/.aida/` using namespace isolation
- Scripts are executable after installation (chmod 755 in `create_directories()`)

**Environment Portability**:

- Target platforms: macOS (primary), Linux (planned)
- Use `bash` (not `zsh`/`fish`) for maximum compatibility
- Avoid GNU-specific tools (`greadlink`, `gsed`, `ggrep`) - use POSIX alternatives
- Test with shellcheck for cross-platform issues
- Leverage existing `lib/installer-common/` modules for consistency

### Dev Mode Considerations

**Symlink Handling**:

- Dev mode creates symlinks: `~/.aida/` → repo, `~/.claude/` → `~/.aida/templates/`
- Scripts must detect and deduplicate symlinked agents/commands
- Use `realpath` or `readlink -f` to resolve symlinks before comparison
- Critical: Avoid showing same agent/command twice in listings

**Live Editing**:

- Dev mode enables live script updates (no reinstall needed)
- Changes to `scripts/*.sh` immediately available
- Validates installer integration without full reinstallation

## 2. Technical Concerns

### CI/CD Impacts

**Validation Pipeline** (`.github/workflows/lint.yml`):

- Add shellcheck validation for new scripts (already in pre-commit hooks)
- Add functional tests: scripts exit cleanly, parse frontmatter correctly
- Test two-tier scanning (global + project contexts)
- Validate path sanitization in output (no absolute paths exposed)

**Testing Requirements**:

- Unit tests: Frontmatter parsing edge cases (malformed YAML, missing fields)
- Integration tests: Scripts work in both normal and dev modes
- Privacy tests: Output contains no absolute paths, usernames, secrets
- Performance tests: Execution completes within SLA (<500ms agents, <1s commands)

**Pre-commit Hook Updates**:

```yaml
# Add to .pre-commit-config.yaml
- id: shellcheck
  files: 'scripts/(list-agents|list-commands|list-skills)\.sh'
  args: ['--severity=warning']
```

### Installation Script Updates

**Changes Required** (`install.sh`):

1. **Directory Creation**: Add `~/.claude/scripts/.aida/` to `create_claude_dirs()`
2. **Template Installation**: Install scripts using existing pattern:

```bash
# Add after documents installation (line ~444)
install_templates \
    "${SCRIPT_DIR}/scripts" \
    "${CLAUDE_DIR}/scripts" \
    "$DEV_MODE" \
    ".aida" || {
    print_message "error" "Failed to install CLI scripts"
    exit 1
}
```

3. **Permissions**: Add scripts to executable chmod (line ~258):

```bash
find "${CLAUDE_DIR}/scripts/.aida" -type f -name "*.sh" -exec chmod 755 {} \;
```

**No Breaking Changes**:

- Existing installations upgrade cleanly (adds scripts directory)
- User content in `~/.claude/` preserved (namespace isolation)
- Backward compatible (missing scripts don't break existing workflows)

### Performance Implications

**Filesystem Scanning**:

- Agent count: ~15 (negligible scan time)
- Command count: ~32 (negligible scan time)
- Skill count: 177 across 28 categories (potential bottleneck)

**Optimization Strategy**:

- Parse frontmatter only (not full files) using `sed`/`awk`
- Limit depth: Scan only `agents/`, not `agents/*/knowledge/**`
- Avoid recursive glob (`**`) - use explicit paths
- Cache skills catalog metadata (Phase 2 - if needed)

**Performance Targets**:

- `/agent-list`: <500ms (15 files × 2 tiers = 30 file reads)
- `/command-list`: <500ms (32 files × 2 tiers = 64 file reads)
- `/skill-list` (categories): <1s (1 catalog file read, not 177 files)

**Performance Anti-Patterns to Avoid**:

- ❌ Recursive knowledge base scanning
- ❌ Full markdown file parsing (use frontmatter only)
- ❌ Spawning subshells per file (use while loops)
- ❌ Complex YAML parsing (use grep/sed for simple extraction)

## 3. Dependencies & Integration

### Affected Systems

**Installer Pipeline**:

- `install.sh` - add scripts installation step
- `lib/installer-common/templates.sh` - reuse existing template installation
- `lib/installer-common/directories.sh` - add scripts directory creation

**Validation Pipeline**:

- `scripts/validate-templates.sh` - extend to validate script templates
- `.pre-commit-config.yaml` - add shellcheck for discovery scripts
- `.github/workflows/lint.yml` - validate scripts in CI

**Slash Commands**:

- Add 3 new commands to `templates/commands/.aida/`:
  - `agent-list.md`
  - `command-list.md`
  - `skill-list.md` (deferred - Phase 2)
- Commands delegate to CLI scripts (no Claude-specific logic in scripts)

### Integration Points

**Two-Tier Scanning** (Critical):

- Scan both `~/.claude/` (user-level) and `./.claude/` (project-level)
- Detect project context: Check for `./.claude/` directory existence
- Separate output sections: "User Agents" vs. "Project Agents"
- Handle missing directories gracefully (don't error if `./.claude/` absent)

**Frontmatter Parsing** (Critical):

- Extract required fields: `name`, `description`
- Extract optional fields: `category` (commands), `model` (agents)
- Validate YAML correctness (fail gracefully on malformed frontmatter)
- Handle missing frontmatter (warn, don't crash)

**Path Sanitization** (Security):

- Replace `${HOME}/.claude/` with `${CLAUDE_CONFIG_DIR}`
- Replace `${HOME}/.aida/` with `${AIDA_HOME}`
- Replace `$(pwd)` with `${PROJECT_ROOT}`
- Generic error messages (don't expose filesystem structure)

**Symlink Resolution** (Dev Mode):

- Use `realpath` to resolve symlinks before deduplication
- Check if two paths point to same inode (`ls -i`)
- Show target location in output (helpful debugging in dev mode)

### Template System Impacts

**New Template Categories**:

- `templates/scripts/` - CLI scripts (new directory)
- Templates namespace: `.aida/` subdirectory pattern
- Installation destination: `~/.claude/scripts/.aida/`

**Frontmatter Schema Updates**:

**Commands** (`templates/commands/.aida/*.md`):

```yaml
---
name: command-name
description: Command description
category: workflow  # NEW FIELD (required)
args:
  arg_name:
    description: Argument description
    required: boolean
---
```

**Categories Taxonomy** (add to `templates/commands/README.md`):

- `workflow` - Development workflow automation
- `quality` - Code review, testing, validation
- `security` - Security scanning, auditing
- `operations` - Deployment, monitoring, incident response
- `infrastructure` - Cloud infrastructure, database
- `data` - Data engineering, analytics, reports
- `documentation` - Documentation generation, updates
- `meta` - AIDA system management, configuration

**Migration Strategy**:

- Add `category` field to all 32 existing commands
- Update command creation template to prompt for category
- Validate category against taxonomy in scripts
- Non-breaking change (existing commands work without category, show as "uncategorized")

## 4. Effort & Complexity

### Complexity Rating: M (Medium)

**Justification**:

- **Not S (Small)**: Requires installer integration, CI/CD updates, new script development, frontmatter parsing logic
- **Not L (Large)**: Well-scoped, reuses existing patterns, no new infrastructure, defers complex features (skills)
- **Medium**: Moderate implementation (3-4 scripts, installer updates, template changes), established patterns, clear requirements

### Effort Breakdown

**Phase 1 (MVP)** - Estimated 3-4 days:

1. **CLI Script Development** (1.5 days):
   - `scripts/list-agents.sh` - 4 hours (simple, no filtering)
   - `scripts/list-commands.sh` - 6 hours (category filtering, validation)
   - Frontmatter parsing library (`lib/frontmatter-parser.sh`) - 2 hours
   - Path sanitization utilities - 1 hour

2. **Installer Integration** (0.5 days):
   - Update `install.sh` - 1 hour
   - Update `lib/installer-common/directories.sh` - 1 hour
   - Update permissions logic - 0.5 hours
   - Test normal + dev mode installation - 1.5 hours

3. **Template Updates** (0.5 days):
   - Add `category` field to 32 commands - 2 hours
   - Update command creation template - 0.5 hours
   - Document category taxonomy in README - 0.5 hours
   - Create slash command templates (2 files) - 1 hour

4. **CI/CD Updates** (0.5 days):
   - Add shellcheck validation - 0.5 hours
   - Add functional tests - 2 hours
   - Update pre-commit config - 0.5 hours
   - Test CI pipeline - 1 hour

**Phase 2 (Skills)** - Deferred (1-2 days):

- Investigate skills catalog architecture - 4 hours
- Implement `scripts/list-skills.sh` - 4 hours
- Add category-first progressive disclosure - 2 hours
- Create `/skill-list` slash command - 1 hour

### Key Effort Drivers

1. **Frontmatter Parsing Robustness**: Handling malformed YAML, missing fields, edge cases
2. **Two-Tier Scanning Logic**: Detecting project context, deduplicating entries, separating output
3. **Path Sanitization**: Comprehensive variable replacement without breaking legitimate paths
4. **Testing Coverage**: Unit tests, integration tests, CI validation, dev mode validation
5. **Template Migration**: Adding `category` to 32 commands, validating taxonomy

### Risk Areas

**Medium Risk**:

- **Symlink Deduplication**: Complex logic, edge cases (circular symlinks, broken symlinks)
- **Frontmatter Parsing**: YAML edge cases, multiline strings, special characters
- **Path Sanitization**: False positives (legitimate paths that look like absolute paths)

**Low Risk**:

- Installer integration (established pattern, well-tested)
- CI/CD validation (existing hooks, known tools)
- Script portability (bash standard, no exotic tools)

**Mitigation**:

- Reuse existing installer modules (`lib/installer-common/`)
- Leverage `validate-templates.sh` patterns for path sanitization
- Comprehensive test suite (unit + integration)
- Incremental rollout (Phase 1 without skills, validate before Phase 2)

## 5. Questions & Clarifications

### Technical Questions

**Skills Catalog Architecture** (Blocking Phase 2):

- **Q**: Where is the skills catalog stored? (`templates/skills/` or external?)
- **Q**: What is the skill file format? (YAML, Markdown, JSON?)
- **Q**: Are AIDA skills separate from Claude Code's built-in skills?
- **Q**: How do skills integrate with `claude-agent-manager`?
- **Action**: Investigate skills catalog before implementing `/skill-list`

**Frontmatter Parsing Approach**:

- **Q**: Should scripts use `yq` (external dependency) or `sed`/`awk` (POSIX)?
- **Recommendation**: Use `sed`/`awk` for simplicity (avoids yq dependency)
- **Trade-off**: Less robust YAML parsing, but sufficient for simple frontmatter

**Category Validation Strictness**:

- **Q**: Should invalid categories fail hard (error) or soft (warning)?
- **Recommendation**: Soft fail (show as "uncategorized", warn in output)
- **Reason**: Non-breaking for existing commands, graceful degradation

**Symlink Resolution**:

- **Q**: Use `realpath` (GNU coreutils) or `readlink -f` (may not work on macOS)?
- **Recommendation**: Implement portable fallback:

```bash
# Portable symlink resolution
resolve_path() {
    local path="$1"
    if command -v realpath &>/dev/null; then
        realpath "$path"
    elif [[ "$(uname)" == "Darwin" ]]; then
        # macOS: Use Python as fallback
        python3 -c "import os; print(os.path.realpath('$path'))"
    else
        readlink -f "$path"
    fi
}
```

### Decisions Needed

**Output Format**:

- **Q**: Plain text tables, markdown tables, or both?
- **Recommendation**: Plain text with color (current), add JSON in Phase 2
- **Reason**: Simplicity, no external formatting tools needed

**Privacy Frontmatter Marker**:

- **Q**: Support optional `privacy: private` field to hide from listings?
- **Recommendation**: Defer to Phase 2 (not critical for MVP)
- **Use Case**: Private agents/commands that shouldn't appear in discovery

**Caching Strategy**:

- **Q**: Cache listings for performance optimization?
- **Recommendation**: Defer to Phase 2 (only needed if performance issues)
- **Implementation**: Use `~/.claude/.cache/` with TTL (5 minutes)

**Version Display**:

- **Q**: Show agent/command versions in listings?
- **Recommendation**: Defer to Phase 2 (requires frontmatter schema change)
- **Use Case**: Track which version of agent is installed

### Areas Needing Investigation

**Skills Integration** (Phase 2):

- Document skills architecture in `templates/skills/README.md`
- Define skill schema and frontmatter requirements
- Clarify skill discovery mechanism (filesystem vs. registry)
- Coordinate with `claude-agent-manager` integration

**Performance Optimization** (Phase 2):

- Benchmark actual scan times on large installations
- Implement caching if needed (unlikely for <100 files)
- Consider parallel scanning (probably overkill)

**Search Functionality** (Phase 3):

- Full-text search within descriptions
- Filter by multiple criteria (category + model)
- Interactive selection mode (fzf integration)

## Recommendations

### Implementation Strategy

**Phase 1 (Recommended for MVP)**:

1. ✅ Implement `/agent-list` and `/command-list` first
2. ✅ Add `category` field to command frontmatter (non-breaking)
3. ✅ Create CLI scripts with frontmatter parsing
4. ✅ Integrate with installer using existing patterns
5. ✅ Add CI/CD validation (shellcheck, functional tests)
6. ✅ Document category taxonomy in templates README
7. ⏸️ Defer `/skill-list` until skills architecture clarified

**Phase 2 (After Skills Investigation)**:

1. Document skills catalog architecture
2. Implement `/skill-list` with category-first approach
3. Add JSON output format (`--format json`)
4. Add privacy markers (`privacy: private`)
5. Performance optimization (caching if needed)

**Phase 3 (Future Enhancements)**:

1. Search functionality (`--search <term>`)
2. Version tracking display
3. Interactive selection mode
4. Knowledge base file count per agent

### Deployment Best Practices

**Installation**:

- Use namespace isolation (`.aida/` subdirectory) to avoid conflicts
- Set proper permissions (755 for scripts, 644 for templates)
- Handle existing installations gracefully (preserve user content)
- Support both normal and dev modes equally

**Validation**:

- Run shellcheck on all scripts before commit
- Test in both normal and dev modes
- Validate privacy (no absolute paths in output)
- Test two-tier scanning (global + project)

**Documentation**:

- Add usage examples to slash command templates
- Document category taxonomy in templates README
- Add troubleshooting section for common errors
- Include performance characteristics in docs

### CI/CD Best Practices

**Automated Testing**:

- Pre-commit hooks: shellcheck, markdownlint
- CI pipeline: Functional tests, privacy validation
- Installation tests: Normal mode, dev mode
- Integration tests: Two-tier scanning, frontmatter parsing

**Quality Gates**:

- Zero shellcheck warnings (severity: warning+)
- All scripts exit cleanly (exit code 0 on success)
- Privacy validation passes (no absolute paths)
- Performance targets met (<500ms agents, <1s commands)

**Release Process**:

- Version bump in VERSION file
- Update CHANGELOG.md with new features
- Tag release with semantic version
- Deploy via installer (users run `./install.sh` to upgrade)

## Success Metrics

**Technical Metrics**:

- Scripts execute in <500ms (agents), <1s (commands)
- Zero external dependencies (bash + standard tools only)
- 100% frontmatter parsing success (no crashes on malformed YAML)
- Global vs. project agents clearly distinguished in output
- Zero absolute paths exposed in output (privacy validated)

**CI/CD Metrics**:

- Pre-commit hooks pass on all commits
- CI pipeline validates scripts on every PR
- Installation tests pass in normal + dev modes
- Zero regressions in existing functionality

**Deployment Metrics**:

- Scripts install cleanly via `./install.sh`
- Dev mode enables live editing (no reinstall needed)
- Existing installations upgrade without conflicts
- Scripts work immediately after installation

## Conclusion

**Complexity**: Medium (M) - Well-scoped, reuses patterns, clear requirements

**Effort**: 3-4 days (Phase 1 MVP only)

**Risk**: Low - Established patterns, incremental rollout, comprehensive testing

**Recommendation**: **Approve for implementation** with Phase 1 scope (agents + commands), defer skills to Phase 2 after architecture investigation.

This is a solid DevOps implementation with good CI/CD practices, clear deployment strategy, and well-defined testing requirements. The phased approach mitigates risk by deferring complex features until dependencies are clarified.

---

**Next Steps**:

1. Review and approve analysis
2. Assign to shell-systems-ux-designer for CLI script development
3. Coordinate with configuration-specialist for template migration
4. Update installer with script installation (devops-engineer support)
5. Add CI/CD validation pipeline
6. Test in normal + dev modes before merge
