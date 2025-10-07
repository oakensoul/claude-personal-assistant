---
title: "Privacy & Security Auditor Analysis - Issue #37"
agent: "privacy-security-auditor"
issue: 37
date: "2025-10-06"
status: "approved"
complexity: "Medium"
---

# Privacy & Security Auditor Analysis - Archive Global Agents and Commands

## Executive Summary

**Critical Finding**: Archiving user content from `~/.claude/` to `templates/` without scrubbing creates SEVERE privacy risk. Knowledge directories contain user-generated content with PII, absolute paths revealing usernames, and learned patterns from real usage.

**Recommended Approach**: Create NEW generic templates (not archive user content) with mandatory scrubbing validation via pre-commit hooks.

**Complexity**: Medium (M)

**Key Risk**: Accidental commit of PII/username data to public repository.

## 1. Implementation Approach

### Privacy Scrubbing Implementation

#### Three-Layer Scrubbing Strategy

##### Layer 1: Pattern-Based Automated Scrubbing

```python
# Scrubbing patterns for archival process
PII_PATTERNS = {
    'username': r'/Users/([^/]+)/',
    'home_dir': r'~([^/]+)/',
    'email': r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b',
    'absolute_path': r'/Users/[^/\s]+(/[^/\s]+)*',
}

VARIABLE_SUBSTITUTIONS = {
    'project_root': (r'/Users/[^/]+/Developer/[^/]+/[^/\s]+', '${PROJECT_ROOT}'),
    'claude_config': (r'/Users/[^/]+/\.claude', '${CLAUDE_CONFIG_DIR}'),
    'aida_home': (r'/Users/[^/]+/\.aida', '${AIDA_HOME}'),
    'home': (r'/Users/[^/]+', '~'),
}
```

##### Layer 2: Context-Aware Validation

- Check for "Owner:" fields in knowledge index files (found: `**Owner**: User (oakensoul)`)
- Detect system-specific paths in examples
- Flag company/project names that aren't "AIDA" or generic

##### Layer 3: Manual Review Checklist

- Knowledge directories need COMPLETE review (contain user-specific learnings)
- Commands with project paths need ${PROJECT_ROOT} substitution
- Agent definitions should describe behavior (not reference specific locations)

### Automated Validation Approach

#### Script-Based Validation: `scripts/validate-templates.sh`

```bash
#!/usr/bin/env bash
# Validate templates for privacy compliance

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly TEMPLATES_DIR="${SCRIPT_DIR}/../templates"

validate_no_usernames() {
  local violations
  violations=$(grep -r "/Users/[^/]*/" "${TEMPLATES_DIR}" 2>/dev/null || true)

  if [[ -n "${violations}" ]]; then
    echo "ERROR: Absolute paths with usernames found:"
    echo "${violations}"
    return 1
  fi
}

validate_no_pii() {
  local patterns=(
    '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}'  # Email
    '\b\d{3}-\d{2}-\d{4}\b'                            # SSN
    '\b(?:\+?1[-.]?)?\(?\d{3}\)?[-.]?\d{3}[-.]?\d{4}\b' # Phone
  )

  for pattern in "${patterns[@]}"; do
    if grep -rE "${pattern}" "${TEMPLATES_DIR}" 2>/dev/null; then
      echo "ERROR: PII pattern detected: ${pattern}"
      return 1
    fi
  done
}

validate_variable_usage() {
  # Check commands have ${PROJECT_ROOT} not absolute paths
  local bad_paths
  bad_paths=$(grep -r "Developer/oakensoul" "${TEMPLATES_DIR}/commands" 2>/dev/null || true)

  if [[ -n "${bad_paths}" ]]; then
    echo "ERROR: Commands contain absolute paths instead of variables:"
    echo "${bad_paths}"
    return 1
  fi
}

validate_knowledge_sanitized() {
  # Check knowledge/index.md for "Owner:" fields
  find "${TEMPLATES_DIR}/agents" -name "index.md" -exec grep -H "Owner:" {} \; && {
    echo "ERROR: Knowledge index contains Owner field (user-specific)"
    return 1
  } || true
}

main() {
  echo "Validating templates for privacy compliance..."

  validate_no_usernames
  validate_no_pii
  validate_variable_usage
  validate_knowledge_sanitized

  echo "✓ All privacy validations passed"
}

main "$@"
```

### Pre-commit Hook Design

#### Integration with Existing `.pre-commit-config.yaml`

```yaml
# Add to existing pre-commit config
repos:
  # ... existing hooks ...

  # Custom privacy validation for templates
  - repo: local
    hooks:
      - id: validate-templates-privacy
        name: Validate templates privacy compliance
        entry: scripts/validate-templates.sh
        language: system
        files: ^templates/
        pass_filenames: false

      - id: no-absolute-paths-in-templates
        name: Check for absolute paths in templates
        entry: '/Users/[^/]+/'
        language: pygrep
        files: ^templates/
        types: [text]

      - id: no-owner-fields-in-knowledge
        name: Check for Owner fields in knowledge
        entry: '^\*\*Owner\*\*:'
        language: pygrep
        files: ^templates/agents/.*/knowledge/.*\.md$
        types: [markdown]
```

#### Why This Approach

- Leverages existing gitleaks hook (already detects API keys/tokens)
- Adds template-specific validations for paths/usernames
- Runs automatically on commit (prevents accidental leaks)
- Fast (only checks templates/ directory)

## 2. Technical Concerns

### PII Detection Patterns

#### Critical PII Categories for This Task

1. **Username Leakage** (HIGH RISK - confirmed present)
   - Pattern: `/Users/oakensoul/` in paths
   - Found in: knowledge/index.md ("Owner: User (oakensoul)")
   - Mitigation: Replace with generic "User" or remove Owner field entirely

2. **Absolute Paths** (HIGH RISK)
   - Pattern: Full paths to Developer directories
   - Found in: Commands (create-agent.md, etc.)
   - Mitigation: Variable substitution (${PROJECT_ROOT}, ${CLAUDE_CONFIG_DIR})

3. **System Organization** (MEDIUM RISK)
   - Reveals: Directory structure, project organization
   - Example: `/Users/oakensoul/Developer/oakensoul/claude-personal-assistant`
   - Mitigation: Use variables consistently

4. **Learned Content** (HIGH RISK)
   - Knowledge directories are USER-GENERATED (not templates)
   - May contain: Company names, project specifics, personal preferences
   - Mitigation: Create EMPTY knowledge structure with README examples

#### Lower Risk (but still check)

- Email addresses: Unlikely in templates (but validate)
- API keys: Already covered by gitleaks pre-commit hook
- Phone numbers: Unlikely in technical documentation

### Path Sanitization Techniques

#### Command File Sanitization (*.md.template)

```bash
# Input (user's ~/.claude/commands/create-agent.md):
cat ~/.claude/workflow-config.json
/Users/oakensoul/Developer/oakensoul/claude-personal-assistant/.github/

# Output (templates/commands/create-agent.md.template):
cat ${CLAUDE_CONFIG_DIR}/workflow-config.json
${PROJECT_ROOT}/.github/
```

#### Agent File Sanitization

- Agent definitions: Describe behavior generically (no path substitution needed)
- Knowledge index: Remove "Owner:" field, genericize descriptions
- Knowledge content: Use EMPTY templates with example structure (don't archive user content)

#### Substitution Rules

```bash
# Priority order (most specific first)
1. ${PROJECT_ROOT}       -> Project git root (any project)
2. ${CLAUDE_CONFIG_DIR}  -> User config (~/.claude)
3. ${AIDA_HOME}          -> Framework install (~/.aida)
4. ~                     -> Generic home (if no username revealed)
```

### Knowledge Directory Scrubbing

#### CRITICAL DECISION NEEDED: How to handle knowledge/ directories?

##### Option A: Empty Structure (RECOMMENDED)

```text
templates/agents/product-manager/
├── product-manager.md          # Agent definition (exact copy)
└── knowledge/
    ├── README.md               # Structure explanation + examples
    ├── core-concepts/.gitkeep
    ├── patterns/.gitkeep
    └── decisions/.gitkeep
```

**Pros**: Zero privacy risk, clear template purpose, users customize

**Cons**: No example content (but README can explain)

##### Option B: Genericized Content

- Scrub all user-specific references
- Replace learned patterns with generic examples
- Review EVERY file manually

**Pros**: Richer templates with examples

**Cons**: HIGH manual effort, privacy risk of missed content

##### Option C: Exclude Entirely

- No knowledge/ in templates
- Agent creates knowledge/ on first invocation

**Pros**: Simplest, zero risk

**Cons**: Users don't see expected structure

##### RECOMMENDATION: Option A (empty structure with README examples)

**Rationale**:

- Knowledge is user-generated (by definition contains learned patterns)
- PRD explicitly warns: "Knowledge directories are LEARNED from usage (privacy risk)"
- Empty structure shows organization, README provides guidance
- Zero risk of leaking user-specific learnings

### Security Validation

#### Multi-Layer Security Checks

1. **Pre-commit Hooks** (Developer workstation)
   - Runs on `git commit`
   - Blocks commit if validation fails
   - Fast feedback loop

2. **CI/CD Pipeline** (GitHub Actions)
   - Runs on PR creation
   - Independent validation (not just local)
   - Prevents merge if fails

3. **Manual Review** (PR Review Process)
   - Reviewer checks for privacy issues
   - Second pair of eyes on knowledge content
   - Validates variable substitution correctness

#### CI Workflow (`.github/workflows/validate-templates.yml`)

```yaml
name: Validate Templates

on:
  pull_request:
    paths:
      - 'templates/**'
  push:
    branches:
      - main
    paths:
      - 'templates/**'

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Run template privacy validation
        run: ./scripts/validate-templates.sh

      - name: Check for absolute paths
        run: |
          if grep -r "/Users/" templates/; then
            echo "ERROR: Absolute paths found in templates"
            exit 1
          fi

      - name: Verify variable substitution
        run: |
          # Check commands use ${PROJECT_ROOT} not hardcoded paths
          if grep -r "Developer/oakensoul" templates/commands/; then
            echo "ERROR: Hardcoded paths in commands"
            exit 1
          fi
```

## 3. Dependencies & Integration

### Pre-commit Integration

#### Existing Infrastructure

`.pre-commit-config.yaml` already has:

- `gitleaks` (secret detection) ✓
- `check-yaml`, `check-json` (file integrity) ✓
- `shellcheck` (if adding validation scripts) ✓
- `markdownlint` (template documentation) ✓

#### Required Additions

1. Custom local hook for `scripts/validate-templates.sh`
2. Pygrep patterns for absolute paths
3. Pygrep patterns for "Owner:" fields

**Installation**: Developers already have pre-commit installed (per CONTRIBUTING.md)

**No additional dependencies needed**.

### Validation Tooling

#### Bash Script: `scripts/validate-templates.sh`

- Dependencies: `grep`, `find` (standard Unix tools)
- Exit codes: 0 (pass), 1 (fail with details)
- Output: Clear error messages with file locations

#### Alternative Python Implementation (if needed later)

```python
#!/usr/bin/env python3
# scripts/validate-templates.py

import re
import sys
from pathlib import Path

TEMPLATES_DIR = Path(__file__).parent.parent / "templates"

PII_PATTERNS = {
    "username": re.compile(r"/Users/([^/]+)/"),
    "email": re.compile(r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b"),
    "owner_field": re.compile(r"^\*\*Owner\*\*:", re.MULTILINE),
}

def validate_file(filepath: Path) -> list[str]:
    """Return list of privacy violations in file."""
    violations = []
    content = filepath.read_text()

    for name, pattern in PII_PATTERNS.items():
        if pattern.search(content):
            violations.append(f"{filepath}: {name} pattern detected")

    return violations

def main():
    violations = []
    for md_file in TEMPLATES_DIR.rglob("*.md"):
        violations.extend(validate_file(md_file))

    if violations:
        print("Privacy violations found:")
        for v in violations:
            print(f"  {v}")
        sys.exit(1)

    print("✓ All privacy validations passed")
    sys.exit(0)

if __name__ == "__main__":
    main()
```

#### Trade-off

Bash simpler (no dependencies), Python more powerful (but requires Python in CI)

**RECOMMENDATION**: Start with Bash (simple, sufficient for patterns), upgrade to Python if complex logic needed.

### CI/CD Security Checks

#### GitHub Actions Workflow (new)

- Triggers: PR to main, push to main (paths: templates/**)
- Runs: Template validation script
- Blocks: Merge if validation fails
- Notifies: PR comments with specific violations

#### Integration Points

- Existing test workflow (`.github/workflows/test.yml`)
- Can run in parallel with other tests
- Fast (only validates templates/, not entire codebase)

**Required Permissions**: Read-only (no secrets needed for validation)

## 4. Effort & Complexity

### Complexity Assessment: Medium (M)

#### Rationale

- **Not Small**: Requires scrubbing validation tooling + pre-commit integration
- **Not Large**: Existing pre-commit infrastructure, straightforward patterns
- **Medium because**:
  - Custom validation script needed (new code)
  - Knowledge directory decision requires judgment
  - Manual review of 6 core agents for privacy issues
  - Pre-commit hook testing and integration

### Effort Breakdown

#### Privacy Scrubbing Implementation: 4-6 hours

- Write `scripts/validate-templates.sh`: 2 hours
- Test against real agent/command files: 1 hour
- Integrate with pre-commit: 1 hour
- Document validation patterns: 1-2 hours

#### Knowledge Directory Sanitization: 3-4 hours

- Review 6 core agent knowledge dirs: 2 hours (manual)
- Create empty structure + README examples: 1 hour
- Validate no user-specific content: 1 hour

#### Pre-commit Integration: 2-3 hours

- Add custom hooks to `.pre-commit-config.yaml`: 30 min
- Test hook execution: 1 hour
- Document for contributors: 1 hour
- CI workflow creation: 30-60 min

#### Testing & Validation: 2-3 hours

- Test on clean system (no ~/.claude/): 1 hour
- Variable substitution validation: 1 hour
- Privacy violation testing (intentional bad data): 1 hour

#### Documentation: 1-2 hours

- Update CONTRIBUTING.md with privacy guidelines
- Add templates/README.md section on validation
- Document scrubbing patterns

#### Total Estimated Effort

12-18 hours (1.5-2 days for one developer)

### Key Effort Drivers

1. **Manual Knowledge Review** (largest variable)
   - 6 core agents × 3-5 knowledge files each = 18-30 files
   - Each file needs human judgment (not just regex)
   - Decision: Empty structure reduces to near-zero effort

2. **Validation Script Robustness**
   - Need comprehensive pattern coverage
   - Clear error messages for developers
   - Testing against edge cases

3. **Pre-commit Testing**
   - Ensure hooks don't break developer workflow
   - Fast execution (templates/ only, not full repo)
   - Clear failure messages

### Risk Areas

#### HIGH RISK: Knowledge Directory Content

- **Risk**: Accidental commit of user-specific learnings
- **Impact**: Privacy violation, username exposure
- **Mitigation**: Use empty structure (Option A), mandatory manual review
- **Likelihood**: High if using Option B/C, Low if using Option A

#### MEDIUM RISK: Incomplete Path Substitution

- **Risk**: Missed absolute paths in command files
- **Impact**: Templates fail on other systems, username exposure
- **Mitigation**: Automated validation catches these
- **Likelihood**: Medium (14 commands to review)

#### MEDIUM RISK: Pre-commit Hook Breakage

- **Risk**: Hook too slow or triggers false positives
- **Impact**: Developer friction, hook disabled
- **Mitigation**: Test thoroughly, clear documentation on bypassing if needed
- **Likelihood**: Low (simple patterns, fast grep)

#### LOW RISK: False Positives

- **Risk**: Validation flags legitimate content as PII
- **Example**: Email format in documentation examples
- **Impact**: Developer confusion, manual override needed
- **Mitigation**: Use specific file paths (exclude docs/), clear error messages
- **Likelihood**: Low (templates/ is small, controlled scope)

## 5. Questions & Clarifications

### Technical Questions

#### Q1: Knowledge Directory Strategy (CRITICAL)

- **Question**: Empty structure (Option A), genericized content (Option B), or exclude entirely (Option C)?
- **Impact**: Effort (2h vs 20h), privacy risk (zero vs medium), template usefulness
- **Recommendation**: Option A (empty structure with README examples)
- **Decision needed before**: Starting agent archival
- **Decision maker**: Product manager + privacy/security sign-off

#### Q2: Variable Expansion Timing

- **Question**: When are ${VARS} replaced - install.sh or runtime?
- **Impact**: Template processing complexity, installation behavior
- **Current assumption**: Install-time (install.sh processes .template files)
- **Validation needed**: Confirm with shell-script-specialist
- **Blocked by**: Issue scope (PRD defers install.sh changes to future)

#### Q3: Validation Script Language

- **Question**: Bash (simple) or Python (powerful)?
- **Impact**: Maintainability, CI dependencies
- **Recommendation**: Start Bash, upgrade if needed
- **Decision point**: During validation script implementation
- **Trade-off**: Simplicity vs extensibility

#### Q4: Pre-commit Hook Strictness

- **Question**: Block all violations or warn + require manual override?
- **Impact**: Developer experience, safety guarantees
- **Recommendation**: Block on clear violations (usernames, paths), warn on ambiguous
- **Rationale**: Privacy is non-negotiable, templates are public-facing

### Decisions to Be Made

#### D1: Knowledge Content Policy (HIGH PRIORITY)

- **Decision**: How to handle user-generated knowledge directories?
- **Options**:
  - A: Empty structure only (RECOMMENDED)
  - B: Genericized examples (HIGH manual effort)
  - C: Exclude entirely (users don't see structure)
- **Timeline**: Before Phase 1 agent archival
- **Stakeholders**: Product manager, privacy/security auditor, tech lead

#### D2: Scrubbing Automation Level

- **Decision**: Fully automated scrubbing or require manual review?
- **Options**:
  - A: Automated + manual review (RECOMMENDED)
  - B: Automated only (faster but risky)
  - C: Manual only (slow but thorough)
- **Recommendation**: A (automated catches 95%, manual review for knowledge/)
- **Timeline**: During validation script design

#### D3: CI Blocking Behavior

- **Decision**: Should CI block PR merge on template validation failure?
- **Recommendation**: YES (privacy non-negotiable for templates/)
- **Alternative**: Warn only + require manual approval (less safe)
- **Rationale**: Templates are public-facing, privacy violations unacceptable

#### D4: .template Extension Usage

- **Decision**: Which files get .template extension?
- **Current PRD guidance**: Only files needing variable substitution
- **Clarification needed**:
  - Commands: YES (.template, need ${PROJECT_ROOT})
  - Agents: NO (exact copy, no path substitution)
  - Knowledge: NO (empty structure, no content to substitute)
- **Validation**: Shell-script-specialist confirms install.sh behavior

### Areas Needing Investigation

#### I1: Existing Knowledge Directory Content

- **Investigation**: Manual audit of 6 core agent knowledge/ dirs
- **Purpose**: Identify user-specific content patterns
- **Method**: Grep for username, company names, absolute paths, learned patterns
- **Deliverable**: Privacy risk assessment per agent
- **Timeline**: Before archival implementation
- **Preliminary findings**: "Owner: oakensoul" confirmed in index.md (must scrub)

#### I2: Command Path Usage Patterns

- **Investigation**: Analyze 14 commands for path usage
- **Purpose**: Identify which commands need variable substitution
- **Method**: Grep for /Users/, Developer/, .claude/, .aida/
- **Deliverable**: List of commands needing .template extension
- **Timeline**: During Phase 1 implementation
- **Preliminary estimate**: 8/14 commands need substitution (per PRD)

#### I3: Variable Resolution Mechanism

- **Investigation**: How does install.sh currently handle templates?
- **Purpose**: Confirm variable substitution implementation exists
- **Method**: Review install.sh source code
- **Blocker**: PRD explicitly defers install.sh changes to future issue
- **Action**: Document assumption (install-time substitution) for future implementer

#### I4: Pre-commit Hook Performance

- **Investigation**: Test validation script execution time
- **Purpose**: Ensure hooks don't slow developer workflow
- **Method**: Benchmark against templates/ directory (small, <100 files)
- **Acceptance criteria**: <2 seconds for template-only validation
- **Timeline**: During pre-commit integration testing

## Appendix: Privacy Patterns Reference

### Absolute Path Patterns

```regex
# macOS paths
/Users/[^/]+/                    # Username in home directory
/Users/[^/]+/Developer/          # Developer workspace
/Users/[^/]+/\.claude/           # Config directory
/Users/[^/]+/\.aida/             # Framework install

# Linux paths (future)
/home/[^/]+/                     # Username in home directory
```

### PII Patterns

```regex
# Email addresses
\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b

# Phone numbers (US format)
\b(?:\+?1[-.]?)?\(?\d{3}\)?[-.]?\d{3}[-.]?\d{4}\b

# SSN (unlikely but check)
\b\d{3}-\d{2}-\d{4}\b

# Owner/Author fields
^\*\*Owner\*\*:\s*(.+)$
^\*\*Author\*\*:\s*(.+)$
```

### Variable Substitution Patterns

```bash
# Project root (git repository)
s|/Users/[^/]+/Developer/[^/]+/[^/\s]+|${PROJECT_ROOT}|g

# Claude config directory
s|/Users/[^/]+/\.claude|${CLAUDE_CONFIG_DIR}|g

# AIDA framework home
s|/Users/[^/]+/\.aida|${AIDA_HOME}|g

# Generic home (last resort)
s|/Users/[^/]+|~|g
```

## Recommendations Summary

1. **Use Empty Knowledge Structure** (Option A) - Zero privacy risk, clear template purpose
2. **Implement Three-Layer Scrubbing** - Automated patterns + context validation + manual review
3. **Integrate with Pre-commit** - Leverage existing infrastructure, add custom hooks
4. **Block CI on Violations** - Privacy non-negotiable for public templates
5. **Start with Bash Validation** - Simple, sufficient, no new dependencies
6. **Mandatory Manual Review** - Human judgment required for knowledge directories
7. **Clear Documentation** - Privacy guidelines in CONTRIBUTING.md, validation patterns documented

**Priority**: Address D1 (knowledge content policy) before starting implementation.
