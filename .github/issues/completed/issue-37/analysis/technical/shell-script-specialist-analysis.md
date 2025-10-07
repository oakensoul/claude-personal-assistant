---
title: "Shell Script Specialist Analysis - Issue #37"
date: "2025-10-06"
issue: 37
agent: "shell-script-specialist"
status: "draft"
---

# Shell Script Specialist Technical Analysis

## 1. Implementation Approach

### Recommended Strategy

**Archive script approach** (not manual copy):

- Single shell script (`scripts/archive-templates.sh`) for reproducibility and validation
- Separate functions for commands vs agents (different processing rules)
- Privacy scrubbing integrated into copy process (not post-processing)
- Validation phase after archiving (verify no PII, valid paths, correct structure)

### Key Technical Decisions

**Path Substitution Method**:

- Use `sed` with multiple `-e` expressions for clarity and maintainability
- Process `.template` files only (commands need substitution, agents typically don't)
- Pattern: `s|/Users/[^/]*/Developer/[^/]*/claude-personal-assistant|${PROJECT_ROOT}|g`
- Pattern: `s|/Users/[^/]*/.claude|${CLAUDE_CONFIG_DIR}|g`
- Pattern: `s|/Users/[^/]*/.aida|${AIDA_HOME}|g`

**File Processing Flow**:

```bash
# Commands: Copy -> Substitute -> Validate
cp ~/.claude/commands/foo.md templates/commands/foo.md.template
sed -i.bak 's|absolute-paths|${VARS}|g' templates/commands/foo.md.template
validate_no_absolute_paths templates/commands/foo.md.template

# Agents: Copy -> Validate (no substitution needed)
cp -R ~/.claude/agents/foo templates/agents/foo
validate_no_pii templates/agents/foo/
```

**Tool Choices**:

- `sed` - Path substitution (portable, POSIX-compliant)
- `grep` - Privacy validation (find absolute paths, usernames, emails)
- `find` - Recursive file operations (knowledge directory traversal)
- `cp -R` - Directory preservation (maintains structure, permissions)
- `mktemp` - Safe intermediate file creation (atomic operations)

### Script Structure

```bash
#!/usr/bin/env bash
set -euo pipefail

# Configuration
readonly SOURCE_DIR="${HOME}/.claude"
readonly TARGET_DIR="./templates"
readonly USERNAME="$(whoami)"

# Main functions
archive_commands()    # 14 commands with path substitution
archive_core_agents() # 6 agents with knowledge dirs
validate_privacy()    # Check for PII, absolute paths
create_readmes()      # Generate documentation

# Validation functions
check_absolute_paths() # Fail if /Users/... found
check_usernames()      # Fail if actual username found
check_email_addresses() # Fail if email patterns found

main() {
  archive_commands
  archive_core_agents
  validate_privacy
  create_readmes
}
```

## 2. Technical Concerns

### Path Substitution Edge Cases

**Complex path patterns**:

- Paths with spaces: `/Users/foo bar/Developer/...` (handle with proper quoting)
- Symbolic links: `readlink -f` to resolve before substitution (macOS vs Linux differences)
- Relative vs absolute: Only substitute absolute paths starting with `/Users/`
- Multiple path components: `/Users/oakensoul/Developer/oakensoul/...` vs `/Users/oakensoul/...`

**macOS vs Linux path conventions**:

- Home directory expansion: `~` vs `$HOME` vs `/Users/username` vs `/home/username`
- Case sensitivity: macOS (case-insensitive by default), Linux (case-sensitive)
- Symlink resolution: `readlink -f` (GNU) vs `readlink` (BSD) - need fallback

**Substitution failures**:

- Partial matches: `/Users/oakensoul/Documents` shouldn't match if not project-related
- Nested variables: Don't substitute paths inside variable definitions
- Escaped paths: Handle quoted paths in markdown code blocks

### File Permission Handling

**Permission preservation**:

- Commands: 644 (read/write owner, read others)
- Agents: 644 for .md files
- Knowledge: 644 for .md files, 755 for directories
- Scripts: 755 if executable (shouldn't be any in templates/)

**Ownership concerns**:

- Source: owned by current user (`oakensoul`)
- Target: committed to git (ownership irrelevant)
- No `chown` needed (git preserves permissions not ownership)

### Symlink Handling

**Detection and resolution**:

- Check if `~/.claude/agents/foo` is symlink before copying
- Use `cp -L` to follow symlinks (copy targets, not links)
- Alternative: Use `rsync -L` for more control
- Validate no symlinks in templates/ (would break on other systems)

**Dev mode consideration**:

- User might have `~/.claude/` as symlink (dev mode installation)
- Resolve actual files before archiving
- Document source location in commit message

### Error Conditions

**Missing source files**:

- Command doesn't exist: Warning and skip (don't fail entire archive)
- Agent directory missing: Error (required for Phase 1)
- Knowledge directory incomplete: Warning and document

**Permission denied**:

- Can't read source file: Error with clear message
- Can't write target: Error (check disk space, permissions)
- Can't create directories: Error (check parent directory exists)

**Validation failures**:

- Absolute path found: Error with file and line number
- Username found: Error with context (surrounding text)
- Email found: Error with pattern matched
- PII detected: Error with scrubbing instructions

## 3. Dependencies & Integration

### Systems/Components Affected

**Source dependencies**:

- `~/.claude/commands/` - 14 command files to archive
- `~/.claude/agents/` - 6 core agents + 16 specialized agents
- Knowledge directories - Full hierarchy (core-concepts/, patterns/, decisions/)

**Target impact**:

- `templates/` directory - New structure created
- `install.sh` - Future: Will process .template files (not this issue)
- Pre-commit hooks - Need template validation rules
- CI/CD - Should validate templates on PR

**External tools**:

- `sed` - Must be available (POSIX standard, should exist)
- `grep` - Validation patterns (POSIX standard)
- `find` - Directory traversal (POSIX standard)
- `readlink` - Symlink resolution (handle BSD vs GNU)

### Integration with install.sh

**Current state**:

- install.sh copies framework to `~/.aida/`
- install.sh generates config in `~/.claude/`
- Does NOT currently process templates/

**Future integration** (out of scope for #37):

- install.sh should copy templates/ to `~/.claude/`
- Process `.template` files: Replace `${VARS}` with actual paths
- Timing: During initial installation (not runtime)
- Separate issue needed for install.sh enhancement

**Variable expansion mechanism**:

```bash
# install.sh will need this logic (future work)
process_template() {
  local template="$1"
  local output="${template%.template}"

  sed -e "s|\${PROJECT_ROOT}|${PROJECT_ROOT}|g" \
      -e "s|\${CLAUDE_CONFIG_DIR}|${CLAUDE_CONFIG_DIR}|g" \
      -e "s|\${AIDA_HOME}|${AIDA_HOME}|g" \
      "$template" > "$output"
}
```

### Testing Requirements

**Unit testing** (validation functions):

- `check_absolute_paths()` - Detect /Users/..., /home/...
- `check_usernames()` - Detect actual username in content
- `check_email_addresses()` - Detect email patterns
- `substitute_paths()` - Verify ${VAR} replacement

**Integration testing**:

- Archive on clean checkout (no local modifications)
- Validate all 14 commands archived correctly
- Validate all 6 core agents with knowledge/ complete
- Confirm no PII in resulting templates/

**Cross-platform testing**:

- macOS (BSD tools): Primary development environment
- Linux (GNU tools): CI environment validation
- Path substitution works on both platforms
- Symlink resolution handles both readlink versions

**Privacy validation**:

- Automated check: `grep -r "oakensoul" templates/` returns nothing
- Automated check: `grep -r "/Users/" templates/` only finds ${} patterns
- Automated check: No email addresses in templates/
- Manual review: Knowledge content is generic, not user-specific

## 4. Effort & Complexity

### Estimated Complexity: MEDIUM

**Justification**:

- Not trivial: Path substitution has edge cases, privacy critical
- Not complex: Well-defined scope, straightforward shell script
- Moderate risk: Privacy mistakes could leak PII to public repo

**Size breakdown**:

- Archive script: ~200-300 lines (well-structured functions)
- Validation logic: ~100 lines (multiple checks)
- README generation: ~50 lines (template-based)
- Testing: ~100 lines (validation test cases)
- **Total**: ~450-550 lines of shell script

### Key Effort Drivers

**High effort areas**:

1. **Privacy scrubbing validation** (40% of effort)
   - Multiple pattern checks (paths, usernames, emails, API keys)
   - Context-aware detection (don't flag ${VAR} patterns)
   - Clear error messages with remediation steps
   - Test coverage for false positives/negatives

2. **Path substitution correctness** (30% of effort)
   - Handle edge cases (spaces, symlinks, relative paths)
   - Cross-platform compatibility (macOS vs Linux)
   - Multiple path patterns (project root, config dir, aida home)
   - Validation that substitution worked correctly

3. **Knowledge directory handling** (20% of effort)
   - Recursive copy with structure preservation
   - Validate index.md knowledge_count matches actual files
   - Decision: Empty structure vs sanitized content
   - Documentation of knowledge organization

4. **README generation** (10% of effort)
   - Template system overview with examples
   - Variable reference documentation
   - Command/agent catalogs (file listings + descriptions)
   - Cross-references between related items

### Risk Areas

**Critical risks**:

1. **PII leakage** - Absolute paths contain usernames, directory structure reveals organization
   - Mitigation: Multi-layer validation, pre-commit hook, manual review
   - Severity: HIGH (public repo exposure)

2. **Path substitution breaks templates** - Incorrect patterns could leave broken references
   - Mitigation: Integration test (install from templates on clean system)
   - Severity: MEDIUM (breaks user experience)

3. **Knowledge directory privacy** - User-learned patterns not generic templates
   - Mitigation: Decision needed (empty structure vs sanitized content)
   - Severity: HIGH (could reveal proprietary information)

**Moderate risks**:

1. **Cross-platform incompatibility** - BSD vs GNU tool differences
   - Mitigation: Test on both macOS and Linux, use portable constructs
   - Severity: LOW (easily detectable, fixable)

2. **Symlink handling** - Dev mode installations have symlinks
   - Mitigation: Detect and resolve symlinks before copying
   - Severity: LOW (affects dev workflow only)

## 5. Questions & Clarifications

### Technical Questions Needing Answers

**Q1: Knowledge directory content strategy?**

- Option A: Empty structure with README placeholders (safest for privacy)
- Option B: Sanitized and genericized content (requires manual review)
- Option C: Full archive of current knowledge (privacy risk)
- **Recommendation**: Option A for Phase 1, Option B for select agents in Phase 2
- **Decision owner**: Product manager / privacy-security-auditor

**Q2: Template file naming convention?**

- Commands: Always `.template` extension (need path substitution)
- Agents: No `.template` (exact copies, no substitution)
- Knowledge: No `.template` (markdown content, no paths)
- **Confirm**: Is this correct interpretation of PRD?

**Q3: Variable substitution scope?**

- Substitute in commands only (not agents, not knowledge)
- Three variables: `${PROJECT_ROOT}`, `${CLAUDE_CONFIG_DIR}`, `${AIDA_HOME}`
- **Question**: Are there other paths that need substitution?
- **Example**: Home directory (`~/`), system tools paths (`/usr/local/bin`)

**Q4: Symlink resolution approach?**

- Use `cp -L` to follow symlinks (simple)
- Use `rsync -L` for more control (overkill?)
- Detect symlinks and error out (safest but restrictive)
- **Recommendation**: `cp -L` for simplicity, document in script

**Q5: Archive script execution context?**

- Run manually by developer during issue work
- Run in CI to validate no drift (future)
- Idempotent (can re-run safely)
- **Question**: Should script be committed to `scripts/` for future use?

### Decisions to Be Made

#### D1: Knowledge directory inclusion

- **Issue**: Knowledge dirs contain user-learned patterns (privacy concern)
- **Options**: Empty structure, sanitized content, full archive
- **Blocker**: Cannot proceed with agent archiving until decided
- **Owner**: Privacy-security-auditor + product-manager

#### D2: Specialized agents location

- **Issue**: 16 specialized agents - archive now or Phase 2?
- **Options**: All in templates/agents/, separate specialized/ subdir, defer to Phase 2
- **PRD says**: Phase 2 (optional installation)
- **Confirm**: Implement Phase 1 only (6 core agents + 8 commands)?

#### D3: Pre-commit hook scope

- **Issue**: Should template validation be pre-commit hook or CI only?
- **Options**: Pre-commit (catches early), CI only (less friction), both
- **Recommendation**: Both (pre-commit for developer, CI for enforcement)
- **Owner**: DevOps engineer

#### D4: README generation approach

- **Issue**: Generate programmatically or write manually?
- **Options**: Script generates from frontmatter, manual with validation, hybrid
- **Recommendation**: Manual for Phase 1 (6 agents, 8 commands manageable)
- **Future**: Script for Phase 2 (22 total agents)

### Areas Needing Investigation

#### I1: Existing path patterns in commands

- **Action**: Survey all 14 commands for path usage patterns
- **Why**: Ensure substitution patterns catch all cases
- **Deliverable**: List of unique path patterns found
- **Effort**: 30 minutes

#### I2: Agent frontmatter consistency

- **Action**: Validate all agent .md files have valid frontmatter
- **Why**: Ensure archiving preserves structure
- **Deliverable**: Report any missing/invalid frontmatter
- **Effort**: 15 minutes

#### I3: Knowledge directory size

- **Action**: Measure total size of knowledge dirs (disk space, file count)
- **Why**: Understand repo size impact
- **Deliverable**: File count and total MB for each core agent
- **Effort**: 5 minutes

#### I4: Symlink usage in ~/.claude/

- **Action**: Check if any files/dirs are symlinks
- **Why**: Determine if symlink handling needed
- **Deliverable**: List of symlinks found (if any)
- **Effort**: 5 minutes

#### I5: GNU Stow compatibility

- **Action**: Test stow with templates/ structure
- **Why**: Ensure dotfiles integration works
- **Deliverable**: Validation that stow can install from templates/
- **Effort**: 20 minutes (out of scope for #37, defer to integration-specialist)

---

## Recommended Next Steps

1. **Investigate path patterns** (I1) - 30 min
2. **Decide on knowledge directory strategy** (D1) - Blocker
3. **Create archive script skeleton** - 1 hour
4. **Implement command archiving** - 2 hours
5. **Implement agent archiving** - 2 hours (depends on D1)
6. **Add privacy validation** - 2 hours
7. **Generate READMEs** - 1 hour
8. **Integration testing** - 1 hour
9. **Cross-platform testing** - 1 hour

**Total effort**: ~10-12 hours for Phase 1 (6 core agents + 8 commands)

**Critical path**: Knowledge directory decision (D1) blocks agent archiving
