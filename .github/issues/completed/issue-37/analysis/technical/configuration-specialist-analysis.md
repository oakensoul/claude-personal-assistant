---
title: "Configuration Specialist Technical Analysis - Issue #37"
issue: 37
agent: configuration-specialist
date: "2025-10-06"
---

# Configuration Specialist Analysis: Archive Global Agents and Commands

## 1. Implementation Approach

### Template Engine Selection

#### RECOMMENDED: Install-time substitution (simple shell-based)

- Use `.template` extension ONLY for files requiring variable substitution
- Process during `install.sh` execution with `envsubst` or sed
- Generated files have NO `.template` extension in `~/.claude/`
- Most agents don't need templates (no path references)

**Variable Substitution Mechanism:**

```bash
# In install.sh
export PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
export CLAUDE_CONFIG_DIR="${HOME}/.claude"
export AIDA_HOME="${HOME}/.aida"

# Process .template files
for template in templates/commands/*.template; do
  output="${CLAUDE_CONFIG_DIR}/commands/$(basename "$template" .template)"
  envsubst < "$template" > "$output"
done
```

**File Format Decisions:**

- **Commands**: Use `.md.template` for files with path references
  - Example: `create-issue.md.template` → `create-issue.md`
  - Replace `.github/issues/drafts/` → `${PROJECT_ROOT}/.github/issues/drafts/`

- **Agents**: Keep as `.md` (exact copies, no substitution needed)
  - Agent definitions describe behavior, not file paths
  - Exception: If agent invokes tools with hardcoded paths (rare)

- **Knowledge directories**: Exact copies (no variables in documentation)
  - Sanitize user-specific content manually
  - Structure preserved verbatim

### Variable Naming Convention

**Three core variables (from PRD):**

```bash
${PROJECT_ROOT}          # Git repository root
${CLAUDE_CONFIG_DIR}     # User config directory (~/.claude)
${AIDA_HOME}             # Framework installation (~/.aida)
```

**Usage patterns:**

- `${PROJECT_ROOT}/.github/` - Project-specific paths (workflows, issues)
- `${CLAUDE_CONFIG_DIR}/workflow-config.json` - User config files
- `${AIDA_HOME}/templates/` - Framework resources (when cross-referencing)

**AVOID runtime substitution** - Increases complexity, hard to debug

## 2. Technical Concerns

### Template Validation

**Critical validation requirements:**

- **Variable completeness check**: All `${VAR}` have corresponding exports
- **Syntax validation**: Proper variable syntax (no typos like `$PROJECT_ROOT` vs `${PROJECT_ROOT}`)
- **Path existence check**: After substitution, referenced paths should exist or be creatable
- **Frontmatter preservation**: Variable substitution must not break YAML frontmatter

**Validation script (pre-commit hook):**

```bash
#!/bin/bash
# .pre-commit-config.yaml addition

validate_templates() {
  local errors=0

  # Check for unresolved variables after substitution
  for file in templates/**/*.template; do
    # Extract variables used
    vars=$(grep -o '\${[^}]*}' "$file" | sort -u)

    # Check each variable is documented
    for var in $vars; do
      if ! grep -q "^export ${var#\$\{}" install.sh; then
        echo "ERROR: Undefined variable $var in $file"
        ((errors++))
      fi
    done
  done

  # Check for absolute paths that should be variables
  if grep -r "/Users/\|/home/" templates/; then
    echo "ERROR: Absolute paths found in templates/"
    ((errors++))
  fi

  return $errors
}
```

### Variable Resolution Errors

**Common failure scenarios:**

1. **Missing environment variable**: `${PROJECT_ROOT}` not set → empty path
2. **Incorrect escaping**: Frontmatter breaks if `${VAR}` in YAML string
3. **Circular references**: `${VAR1}` contains `${VAR2}`
4. **Platform differences**: Path separators on Windows (if Linux support added)

**Error handling approach:**

```bash
# Defensive substitution in install.sh
substitute_template() {
  local template=$1
  local output=$2

  # Validate required variables exist
  : "${PROJECT_ROOT:?ERROR: PROJECT_ROOT not set}"
  : "${CLAUDE_CONFIG_DIR:?ERROR: CLAUDE_CONFIG_DIR not set}"
  : "${AIDA_HOME:?ERROR: AIDA_HOME not set}"

  # Perform substitution
  envsubst < "$template" > "$output.tmp"

  # Check for unresolved variables
  if grep -q '\${' "$output.tmp"; then
    echo "ERROR: Unresolved variables in $output"
    cat "$output.tmp" | grep '\${'
    rm "$output.tmp"
    return 1
  fi

  mv "$output.tmp" "$output"
}
```

### Default Value Handling

**Configuration defaults:**

- `PROJECT_ROOT`: Auto-detect via `git rev-parse` or fallback to `pwd`
- `CLAUDE_CONFIG_DIR`: Always `${HOME}/.claude` (standard location)
- `AIDA_HOME`: Always `${HOME}/.aida` (standard location)

**No user override needed** - These are architectural constants, not preferences

**Dev mode consideration:**

```bash
# Dev mode uses symlinks, not variable substitution
if [[ "$DEV_MODE" == "true" ]]; then
  # Skip template processing
  # Use symlinks to development directory
  ln -sf "$DEV_DIR/templates" "$AIDA_HOME/templates"
fi
```

## 3. Dependencies & Integration

### Template Processing Tools

**Required tools (already available on macOS/Linux):**

- `envsubst` - GNU gettext utilities (variable substitution)
  - macOS: `brew install gettext` (may need explicit install)
  - Linux: Pre-installed on most distros

**Alternative: Pure shell substitution** (if envsubst unavailable)

```bash
# Fallback implementation
substitute_vars() {
  local content
  content=$(cat "$1")

  # Replace variables manually
  content="${content//\$\{PROJECT_ROOT\}/$PROJECT_ROOT}"
  content="${content//\$\{CLAUDE_CONFIG_DIR\}/$CLAUDE_CONFIG_DIR}"
  content="${content//\$\{AIDA_HOME\}/$AIDA_HOME}"

  echo "$content" > "$2"
}
```

### Installation-Time Substitution

**Integration with install.sh:**

1. **Setup phase**: Export all variables
2. **Template discovery**: Find `*.template` files
3. **Substitution phase**: Process each template
4. **Validation phase**: Check outputs have no unresolved vars
5. **Cleanup phase**: Remove `.tmp` files if errors

**Pseudocode integration:**

```bash
# In install.sh, after directory creation

log_info "Processing command templates..."
process_templates "templates/commands" "$CLAUDE_CONFIG_DIR/commands"

log_info "Copying agent definitions..."
copy_agents "templates/agents" "$CLAUDE_CONFIG_DIR/agents"

log_info "Validating installation..."
validate_config "$CLAUDE_CONFIG_DIR"
```

### Validation Tools

**CI/CD validation (GitHub Actions):**

```yaml
# .github/workflows/validate-templates.yml
name: Validate Templates

on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Check for absolute paths
        run: |
          if grep -r "/Users/\|/home/\|/Developer/" templates/; then
            echo "ERROR: Absolute paths found in templates/"
            exit 1
          fi

      - name: Validate template variables
        run: |
          ./scripts/validate-templates.sh

      - name: Test template substitution
        run: |
          export PROJECT_ROOT="/test/repo"
          export CLAUDE_CONFIG_DIR="/test/config"
          export AIDA_HOME="/test/aida"

          # Test substitution works
          ./install.sh --test-templates
```

**Pre-commit hook (local validation):**

```yaml
# .pre-commit-config.yaml
- repo: local
  hooks:
    - id: validate-templates
      name: Validate template variables
      entry: scripts/validate-templates.sh
      language: script
      files: ^templates/.*\.template$
```

## 4. Effort & Complexity

### Complexity Estimate: **MEDIUM** (M)

**Breakdown:**

- **Template creation**: LOW - Mostly copying existing files
- **Variable substitution**: LOW - Simple pattern replacement
- **Privacy scrubbing**: MEDIUM - Manual review of all content required
- **Validation implementation**: MEDIUM - Pre-commit hooks, CI checks
- **Knowledge directory handling**: MEDIUM - Decide what to include/sanitize
- **Documentation**: MEDIUM - Three comprehensive READMEs
- **Testing**: MEDIUM - Fresh install validation

**Total effort: 8-12 hours** (Phase 1 only)

### Key Effort Drivers

**HIGH effort areas:**

1. **Privacy scrubbing** (3-4 hours)
   - Manual review of 22 agent files + 14 commands
   - Sanitize knowledge directories (learned patterns, user examples)
   - Validate no PII, usernames, absolute paths
   - Risk: Accidental disclosure if incomplete

2. **Knowledge directory decisions** (2-3 hours)
   - Per-agent decision: Include full, structure only, or exclude?
   - Sanitization if including content
   - Update knowledge_count in index.md files
   - Balance usefulness vs privacy

3. **Documentation** (2-3 hours)
   - `templates/README.md` - Variable reference, installation process
   - `templates/commands/README.md` - Command catalog
   - `templates/agents/README.md` - Agent structure, categories

**MEDIUM effort areas:**

4. **Template processing logic** (1-2 hours)
   - Add to install.sh (already has directory creation)
   - Handle .template files vs exact copies
   - Error handling for missing variables

5. **Validation scripts** (1-2 hours)
   - Pre-commit hook for absolute paths
   - CI workflow for template validation
   - Test script for fresh install

**LOW effort areas:**

6. **File copying** (1 hour)
   - Automated copy with variable substitution
   - Directory structure mirrors ~/.claude/

### Risk Areas

**CRITICAL RISKS:**

1. **Privacy breach** - User-specific data in public repo
   - **Mitigation**: Mandatory scrubbing checklist, automated checks
   - **Severity**: HIGH (reputational damage, security concern)

2. **Broken templates** - Variables don't resolve on fresh install
   - **Mitigation**: CI validation, test installation on clean system
   - **Severity**: MEDIUM (framework doesn't work for new users)

**MODERATE RISKS:**

3. **Knowledge directory size** - Repo bloat if including full content
   - **Mitigation**: Empty structure with examples (PRD recommendation)
   - **Severity**: LOW (storage, not functionality)

4. **Maintenance burden** - Templates diverge from working ~/.claude/
   - **Mitigation**: Document sync workflow, accept manual updates
   - **Severity**: LOW (version drift acceptable for v0.1)

## 5. Questions & Clarifications

### Technical Decisions Needed

#### TD-1: Knowledge Directory Content Strategy

- **Question**: Include full knowledge/ content, empty structure, or exclude entirely?
- **Options**:
  - A) Full content (scrubbed) - Most useful, highest privacy risk
  - B) Empty structure + README examples - Safe, less useful
  - C) Exclude knowledge/ entirely - Safest, users create own
- **Recommendation**: **Option B** - Empty structure with templated examples
- **Rationale**: Balance between usefulness and privacy protection
- **Impact**: Determines archiving scope and privacy review effort

#### TD-2: Template Processing Tool Choice

- **Question**: Use `envsubst`, sed, or pure shell substitution?
- **Options**:
  - A) envsubst - Standard tool, may need brew install on macOS
  - B) sed - Universal, more complex syntax
  - C) Pure shell - No dependencies, limited functionality
- **Recommendation**: **envsubst with shell fallback**
- **Rationale**: Best tool for job, graceful degradation
- **Impact**: install.sh dependencies, error handling complexity

#### TD-3: .template Extension Scope

- **Question**: Which files get .template extension?
- **Current thinking**: ONLY commands with path references
- **Validation needed**: Review all 14 commands for path usage
- **Examples**:
  - `create-issue.md` → `create-issue.md.template` (has `.github/` paths)
  - `create-agent.md` → `create-agent.md` (no paths, exact copy)
- **Impact**: Number of template files to process

### Areas Needing Investigation

#### INV-1: Existing Path References Audit

- **Task**: Grep all commands/agents for absolute paths
- **Priority**: HIGH (must complete before implementation)
- **Command**: `grep -r "/Users/\|/Developer/\|\.github/" ~/.claude/`
- **Output**: List of files needing variable substitution

#### INV-2: envsubst Availability on macOS

- **Task**: Test if envsubst ships with macOS or requires gettext
- **Priority**: MEDIUM (determines install.sh logic)
- **Test**: `which envsubst` on clean macOS system
- **Fallback**: Implement pure shell version if unavailable

#### INV-3: Knowledge Directory Survey

- **Task**: Inventory knowledge/ content across 6 core agents
- **Priority**: MEDIUM (determines archiving scope)
- **Questions**:
  - How much content exists? (line count, file count)
  - Is content generic or user-specific?
  - Are there privacy concerns in existing knowledge?
- **Output**: Decision matrix (include full/structure/exclude per agent)

#### INV-4: Frontmatter Variable Safety

- **Task**: Test if `${VAR}` in YAML frontmatter breaks parsing
- **Priority**: LOW (can avoid variables in frontmatter)
- **Test case**:

  ```yaml
  ---
  name: test
  path: ${PROJECT_ROOT}/.github
  ---
  ```

- **Validation**: Ensure frontmatter parsers handle this correctly

### Critical Path Blockers

#### BLOCKER-1: Privacy scrubbing checklist approval

- **Issue**: Need agreed criteria for what to scrub
- **Stakeholder**: Privacy/security team (or lead developer)
- **Timeline**: Before copying any files
- **Deliverable**: Approved scrubbing checklist

#### BLOCKER-2: Knowledge directory inclusion decision

- **Issue**: OQ-2 from PRD unresolved (include full/structure/exclude)
- **Impact**: Determines archiving scope (affects effort by 2-4 hours)
- **Decision maker**: Product owner or lead developer
- **Timeline**: Before starting agent archival

## Summary

### Configuration Specialist Perspective

From a configuration management standpoint, this is a **well-scoped archival task** with moderate complexity:

**STRENGTHS:**

- Clear variable naming convention (`${PROJECT_ROOT}`, etc.)
- Simple substitution mechanism (install-time, not runtime)
- Separation of templates (mutable) from generated config (immutable)
- Validation checkpoints (pre-commit, CI, install test)

**CONCERNS:**

- Privacy scrubbing is manual and error-prone (highest risk)
- Knowledge directory decision affects 30% of effort
- Template validation needs automated checks (can't rely on manual review)
- Dev mode compatibility (symlinks bypass template system)

**RECOMMENDATIONS:**

1. **Start with commands** - Fewer files, clearer path substitution needs
2. **Implement validation FIRST** - Automated checks prevent privacy leaks
3. **Empty knowledge structure** - Add examples, not real content
4. **Test early** - Fresh install validation after first 3 commands archived
5. **Document sync workflow** - Accept manual updates for v0.1

**CONFIDENCE LEVEL: HIGH** - Standard configuration archival with good tooling support

---

**Files Referenced:**

- `/Users/oakensoul/.claude/commands/*.md` (14 commands)
- `/Users/oakensoul/.claude/agents/*.md` (22+ agents)
- `/Users/oakensoul/Developer/oakensoul/claude-personal-assistant/templates/`
- `/Users/oakensoul/Developer/oakensoul/claude-personal-assistant/install.sh`
