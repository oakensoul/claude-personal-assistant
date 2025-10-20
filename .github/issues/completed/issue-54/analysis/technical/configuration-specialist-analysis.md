---
title: "Configuration Specialist Technical Analysis - Issue #54"
issue: 54
analyst: "configuration-specialist"
created: "2025-10-20"
status: "complete"
---

# Configuration Specialist Analysis: Discoverability Commands

**Issue**: #54 - Implement discoverability commands (/agent-list, /skill-list, /command-list)

**Focus**: Frontmatter schema design, category taxonomy validation, migration strategy

## 1. Implementation Approach

### Frontmatter Schema Design

**Recommended Schema (JSON Schema draft-07)**:

```yaml

# commands/{name}.md

---
name: "command-name"                    # Required, kebab-case, matches filename
description: "Brief description"        # Required, used in listings
category: "workflow"                    # Required, enum validation
privacy: "private"                      # Optional, default: public
model: "sonnet"                         # Optional, existing field
args:                                   # Optional, existing structure
  arg-name:
    description: "..."
    required: true|false
---

```text

**New Fields**:

- `category` (required): Single category from taxonomy (8 values)
- `privacy` (optional): "private" flag to exclude from public listings

**Existing Fields** (preserved):

- `name`, `description`, `args`, `model` (all existing)

### Category Taxonomy (8 Categories)

**Proposed Taxonomy** (from PRD):

```yaml

categories:
   - workflow        # Issue lifecycle, branch management, PR creation
   - quality         # Code review, testing, linting, validation
   - security        # Audits, compliance, PII scanning
   - operations      # Incidents, debugging, runbooks
   - infrastructure  # AWS, GitHub, deployment, cost analysis
   - data            # Metrics, warehouses, analytics (domain-specific)
   - documentation   # Doc generation, README creation
   - meta            # System commands (create-command, create-agent)

```text

**Validation Strategy**:

- Enum validation in JSON Schema
- Pre-commit hook validation
- Migration script validates all existing commands
- Error messages suggest valid categories

### Backward Compatibility

**Existing Commands Without Categories**:

- 30+ existing command templates require migration
- Migration approach: Add `category` field to frontmatter
- No file moves or renames (maintain existing paths)
- Commands without categories fail validation (blocking)

**Safe Migration Path**:

1. Add `category` to all existing commands first (PR prerequisite)
2. Add validation after all commands migrated
3. Update command creation template to require category
4. Pre-commit hook enforces category on new commands

## 2. Technical Concerns

### Schema Validation Approach

#### Option 1: JSON Schema + yamllint (Recommended)

**Pros**:

- Standardized validation format
- Supports enum validation for categories
- Works with existing yamllint pre-commit hook
- Machine-readable schema for tooling
- Can generate documentation from schema

**Cons**:

- Requires JSON Schema → YAML Schema adapter
- Additional dependency for validation

**Implementation**:

```bash

# Pre-commit hook addition

- repo: local

  hooks:
     - id: validate-command-frontmatter
      name: Validate command frontmatter schema
      entry: scripts/validate-command-frontmatter.sh
      language: script
      files: ^templates/commands/.*\.md$

```text

#### Option 2: Bash-based Frontmatter Parsing

**Pros**:

- No additional dependencies
- Fast execution
- Simple to implement

**Cons**:

- Custom validation logic (not standardized)
- Harder to maintain as schema evolves
- No IDE support for schema validation

**Recommendation**: Use Option 1 (JSON Schema) for robustness

### Migration Path for Existing Commands

**Two-Phase Migration**:

#### Phase 1: Add Categories (Non-Breaking)

- Create migration script: `scripts/migrate-command-categories.sh`
- Interactive mode: Suggest category based on command name/description
- Batch mode: Accept category mapping JSON file
- Validation: Ensure all 30+ commands have categories

#### Phase 2: Enable Validation (Breaking)

- Add pre-commit hook for category validation
- Update command creation template
- Document category taxonomy in templates/commands/README.md

**Migration Script Requirements**:

- Idempotent (safe to re-run)
- Validates frontmatter after modification
- Creates backup before changes
- Supports dry-run mode
- Outputs summary of changes

### Frontmatter Parsing Reliability

**Risks**:

- YAML parsing edge cases (multiline strings, special characters)
- Frontmatter delimiters (--- vs ===)
- Comments in frontmatter
- Nested structures in `args` field

**Mitigation**:

- Use `yq` for YAML parsing (not grep/sed for frontmatter)
- Validate YAML after parsing
- Test with edge cases (multiline descriptions, special chars)
- Fallback to manual review if parsing fails

**Robust Parsing Pattern**:

```bash

# Extract frontmatter with yq

extract_frontmatter() {
  local file="$1"

  # Use yq to parse frontmatter
  yq eval '.' "$file" 2>/dev/null || {
    echo "ERROR: Failed to parse frontmatter in $file" >&2
    return 1
  }
}

# Validate category field

validate_category() {
  local file="$1"
  local category

  category=$(yq eval '.category' "$file" 2>/dev/null)

  # Check if category exists
  if [[ -z "$category" || "$category" == "null" ]]; then
    echo "ERROR: Missing category field in $file" >&2
    return 1
  fi

  # Validate against taxonomy
  case "$category" in
    workflow|quality|security|operations|infrastructure|data|documentation|meta)
      return 0
      ;;
    *)
      echo "ERROR: Invalid category '$category' in $file" >&2
      echo "Valid categories: workflow, quality, security, operations, infrastructure, data, documentation, meta" >&2
      return 1
      ;;
  esac
}

```text

## 3. Dependencies & Integration

### Tools Needed

**Required**:

- `yq` (YAML processor) - for frontmatter parsing
- `jq` (JSON processor) - for category validation
- Existing: `yamllint` (YAML linting)
- Existing: `markdownlint` (Markdown linting)

**Optional**:

- `ajv-cli` (JSON Schema validator) - for schema validation
- `jsonschema` (Python) - alternative validator

### Impact on Existing Command Templates

**Files Affected** (30+ commands):

- `templates/commands/**/*.md` (all command files)
- `templates/commands/README.md` (add category taxonomy docs)
- `templates/commands/create-command/create-command.md` (add category prompt)

**Changes Required**:

1. Add `category` field to all command frontmatter
2. Update README.md with category definitions
3. Update create-command template to prompt for category
4. Add validation to scripts/validate-templates.sh

### Pre-Commit Validation Hooks

**New Hook** (scripts/validate-command-frontmatter.sh):

```bash

#!/usr/bin/env bash

# Validate command frontmatter schema

set -euo pipefail

readonly VALID_CATEGORIES=(
  "workflow"
  "quality"
  "security"
  "operations"
  "infrastructure"
  "data"
  "documentation"
  "meta"
)

validate_command_frontmatter() {
  local file="$1"
  local errors=0

  # Extract frontmatter
  local name description category privacy
  name=$(yq eval '.name' "$file" 2>/dev/null)
  description=$(yq eval '.description' "$file" 2>/dev/null)
  category=$(yq eval '.category' "$file" 2>/dev/null)
  privacy=$(yq eval '.privacy' "$file" 2>/dev/null)

  # Validate required fields
  [[ -z "$name" || "$name" == "null" ]] && {
    echo "ERROR: Missing 'name' field in $file" >&2
    ((errors++))
  }

  [[ -z "$description" || "$description" == "null" ]] && {
    echo "ERROR: Missing 'description' field in $file" >&2
    ((errors++))
  }

  [[ -z "$category" || "$category" == "null" ]] && {
    echo "ERROR: Missing 'category' field in $file" >&2
    echo "Add one of: ${VALID_CATEGORIES[*]}" >&2
    ((errors++))
  }

  # Validate category enum
  if [[ -n "$category" && "$category" != "null" ]]; then
    local valid=false
    for valid_cat in "${VALID_CATEGORIES[@]}"; do
      if [[ "$category" == "$valid_cat" ]]; then
        valid=true
        break
      fi
    done

    if [[ "$valid" == "false" ]]; then
      echo "ERROR: Invalid category '$category' in $file" >&2
      echo "Valid categories: ${VALID_CATEGORIES[*]}" >&2
      ((errors++))
    fi
  fi

  return "$errors"
}

# Validate all staged command files

main() {
  local exit_code=0

  while IFS= read -r file; do
    if [[ -f "$file" ]]; then
      validate_command_frontmatter "$file" || exit_code=1
    fi
  done

  exit "$exit_code"
}

main "$@"

```text

**Integration with Existing Hooks**:

- Add to `.pre-commit-config.yaml`
- Run after yamllint, before markdownlint
- Fail build if validation fails

## 4. Effort & Complexity

### Estimated Complexity: **MEDIUM (M)**

**Rationale**:

- Schema design: Low complexity (1 new required field, 1 optional field)
- Migration: Medium complexity (30+ files to modify, but straightforward)
- Validation: Medium complexity (requires yq parsing, enum validation)
- Testing: Medium complexity (edge cases in frontmatter parsing)

### Key Effort Drivers

**1. Migration of 30+ Commands** (Highest Effort)

- Manual categorization required (automated suggestions possible)
- Validation after each migration
- Testing each command still works after frontmatter change
- Estimated: 2-3 hours (6 min/command × 30 commands)

**2. Frontmatter Validation Script** (Medium Effort)

- Write validation script (scripts/validate-command-frontmatter.sh)
- Handle edge cases (multiline strings, special chars)
- Test with malformed frontmatter
- Estimated: 1-2 hours

**3. Pre-Commit Hook Integration** (Low Effort)

- Add hook to .pre-commit-config.yaml
- Test hook triggers on command file changes
- Estimated: 30 minutes

**4. Documentation Updates** (Low Effort)

- Update templates/commands/README.md with category taxonomy
- Update create-command template to include category prompt
- Estimated: 30 minutes

**Total Estimated Effort**: 4-6 hours

### Risk Areas

**High Risk**:

- Category taxonomy disagreement (8 categories may not cover all cases)
- Frontmatter parsing failures (malformed YAML in existing commands)
- Migration errors (incorrect categorization of commands)

**Medium Risk**:

- Pre-commit hook performance (30+ files = slow validation)
- yq dependency not installed (CI/CD and developer machines)
- Privacy field misuse (marking public commands as private)

**Low Risk**:

- Schema evolution (future category additions require migration)
- Backward compatibility (old commands without categories)

**Mitigation**:

- Validate category taxonomy with stakeholders before migration
- Test frontmatter parsing on all existing commands before migration
- Provide migration script with dry-run mode for validation
- Cache validation results for performance
- Document yq installation in CONTRIBUTING.md

## 5. Questions & Clarifications

### Critical Questions (Blocking)

#### Q1: Category Taxonomy Finalization

- Are 8 categories sufficient for all 30+ commands?
- Should commands support multiple categories (e.g., `["workflow", "quality"]`)?
- How to handle commands that span categories?

**Recommendation**: Single category only (simplifies filtering), expand taxonomy if needed

#### Q2: Privacy Field Semantics

- What does `privacy: private` mean?

  - Exclude from /command-list output?
  - Prevent command from executing?
  - Hide from documentation?

- Should privacy be per-command or per-project?

**Recommendation**: `privacy: private` → exclude from /command-list, but command still executable

#### Q3: Migration Strategy Decision

- Automated categorization vs. manual review?
- Interactive mode for each command vs. batch mode?
- Who reviews suggested categories?

**Recommendation**: Interactive mode with suggestions, manual review required

### Important Questions (Design Decisions)

#### Q4: Multi-Category Support

- Should commands belong to multiple categories?
- Example: `/implement` could be `["workflow", "quality"]`

**Recommendation**: No - forces clear categorization, simplifies filtering

#### Q5: Category Validation Timing

- Validate on file write (IDE/editor)?
- Validate on commit (pre-commit hook)?
- Validate on CI/CD build?

**Recommendation**: All three - fail fast at each stage

#### Q6: Unknown Categories Handling

- Error (block commit)?
- Warning (log but allow)?
- Auto-suggest nearest category?

**Recommendation**: Error on commit, suggest valid categories in error message

### Nice to Have (Future Enhancements)

#### Q7: JSON Schema Generation

- Auto-generate JSON schema from category taxonomy?
- Publish schema for IDE validation?

**Recommendation**: Yes - Phase 2 enhancement

#### Q8: Category Metrics

- Track category usage distribution?
- Identify over/under-used categories?

**Recommendation**: Yes - helps refine taxonomy over time

## Summary

**Configuration Design Assessment**: Well-scoped, low risk, medium effort

**Key Recommendations**:

1. Use JSON Schema for frontmatter validation (standardized, toolable)
2. Single required `category` field (enum validation, 8 values)
3. Two-phase migration: Add categories → Enable validation
4. Pre-commit hook for enforcement (fail fast)
5. Interactive migration script (suggests categories, requires review)

**Critical Path**:

1. Finalize category taxonomy with stakeholders
2. Create migration script with dry-run mode
3. Migrate all 30+ commands (interactive review)
4. Add validation script and pre-commit hook
5. Update documentation and templates

**Success Criteria**:

- 100% of commands have valid category
- Pre-commit hook blocks invalid categories
- Migration script tested on all existing commands
- Zero parsing failures on frontmatter
- Category filtering works in /command-list

**Next Steps**:

1. Review and approve category taxonomy
2. Define privacy field semantics
3. Create migration script (scripts/migrate-command-categories.sh)
4. Test frontmatter parsing on all existing commands
5. Execute migration with manual review

---

**Analysis Complete**: Configuration design is straightforward, main effort is migration execution
