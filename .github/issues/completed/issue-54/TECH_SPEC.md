---
title: "Technical Specification - Discoverability Commands"
issue: 54
created: 2025-10-20
status: approved
complexity: M
estimated_effort: 3-5 days (Phase 1 MVP)
---

# Technical Specification: Discoverability Commands

## Architecture Overview

**Approach**: Multi-layer CLI-based discovery system with filesystem scanning, frontmatter parsing, and two-tier aggregation (user-level + project-level). Commands invoke standalone bash scripts that scan metadata, deduplicate symlinks, and format output consistently.

**Key Components**:

- **CLI Scripts** (`scripts/`): Bash scripts that scan directories and parse YAML frontmatter
- **Slash Commands** (`templates/commands/.aida/`): Thin wrappers that invoke CLI scripts
- **Shared Libraries** (`scripts/lib/`): Reusable frontmatter parser, path sanitizer, symlink deduplicator

**Architecture Diagram**:

```text

┌─────────────────────────────────────────────────────────────┐
│ User Interface Layer                                        │
│  /agent-list    /command-list    /skill-list (Phase 2)     │
└──────────────────────┬──────────────────────────────────────┘
                       │ invokes
┌──────────────────────▼──────────────────────────────────────┐
│ CLI Script Layer                                            │
│  scripts/list-agents.sh                                     │
│  scripts/list-commands.sh                                   │
│  scripts/list-skills.sh (Phase 2)                           │
└──────────────────────┬──────────────────────────────────────┘
                       │ uses
┌──────────────────────▼──────────────────────────────────────┐
│ Shared Library Layer                                        │
│  lib/frontmatter-parser.sh    (extract YAML frontmatter)    │
│  lib/path-sanitizer.sh        (replace absolute paths)      │
│  lib/readlink-portable.sh     (cross-platform symlinks)     │
└──────────────────────┬──────────────────────────────────────┘
                       │ scans
┌──────────────────────▼──────────────────────────────────────┐
│ Filesystem Layer (Two-Tier Discovery)                      │
│  ~/.claude/{agents,commands}/   (user-level)               │
│  ./.claude/{agents,commands}/   (project-level)            │
│  ~/.claude/skills/ (Phase 2)                                │
└─────────────────────────────────────────────────────────────┘

```

## Technical Decisions

### Decision 1: Frontmatter Parsing - sed/awk (NOT yq)

**Decision**: Use `sed` and `awk` for YAML frontmatter extraction, avoid `yq` dependency

**Rationale**:

- Simple key-value YAML (98% of cases)
- POSIX-compliant tools (maximum portability)
- No external dependencies (yq version fragmentation issues)
- Sufficient for metadata extraction (not full YAML parsing)

**Alternatives**:

- `yq` (YAML processor): Rejected due to version compatibility (v3 vs v4 syntax differences)
- `jq` with YAML plugin: Rejected due to added complexity

**Trade-offs**:

- **Pro**: Zero dependencies, fast, portable across macOS/Linux
- **Con**: Manual quote handling, limited support for complex YAML (multiline, arrays)
- **Mitigation**: Validate 90% case works, document limitations, warn on complex YAML

### Decision 2: Two-Tier Discovery with Symlink Deduplication

**Decision**: Scan both `~/.claude/` and `./.claude/`, deduplicate symlinks using `realpath`

**Rationale**:

- Aligns with ADR-002 (user-level + project-level architecture)
- Dev mode creates symlinks that would show duplicates
- Users need to see separation between global and project resources

**Alternatives**:

- Single-tier scanning: Rejected (doesn't support project-specific agents)
- Show symlinks separately: Rejected (confusing, violates DRY)

**Trade-offs**:

- **Pro**: Clear context separation, handles dev mode correctly
- **Con**: macOS lacks `readlink -f` (requires Python fallback)
- **Mitigation**: Portable `readlink_portable()` function with Python fallback

### Decision 3: Path Sanitization for Privacy

**Decision**: Replace all absolute paths with variables (`${CLAUDE_CONFIG_DIR}`, `${PROJECT_ROOT}`)

**Rationale**:

- Prevents username/project name exposure in output
- Safe for sharing command output (screenshots, documentation)
- Consistent with template variable substitution pattern

**Alternatives**:

- No sanitization: Rejected (privacy risk, usernames in output)
- Sanitize only on `--public` flag: Rejected (easy to forget)

**Trade-offs**:

- **Pro**: Privacy-by-default, safe for sharing
- **Con**: Additional string processing overhead (~10ms)
- **Mitigation**: Optimize replacement patterns, cache git root

### Decision 4: Direct Script Invocation (NOT Agent Orchestration)

**Decision**: Slash commands directly invoke bash scripts, no agent wrapper

**Rationale**:

- Simplicity and performance (<500ms target)
- Scripts are standalone and testable independently
- No need for AI decision-making in data display

**Alternatives**:

- Agent orchestration: Rejected for Phase 1 (adds latency, complexity)
- Skills-based approach: Considered for Phase 2 (AI-enhanced filtering)

**Trade-offs**:

- **Pro**: Fast, testable, loosely coupled, no agent overhead
- **Con**: No AI-enhanced formatting, static output
- **Future**: Phase 2 can add optional agent enhancement

### Decision 5: Category Field in Command Frontmatter

**Decision**: Add required `category` field to command frontmatter (8-value enum)

**Rationale**:

- Enables category filtering (`/command-list --category workflow`)
- Forces clear categorization (single category only)
- Non-breaking (commands without categories show as "uncategorized")

**Alternatives**:

- Multiple categories per command: Rejected (complicates filtering)
- Directory-based categories: Rejected (breaks existing paths)

**Trade-offs**:

- **Pro**: Simple filtering, clear organization, extensible taxonomy
- **Con**: Requires migration of 32 existing commands (2-3 hours)
- **Mitigation**: Migration script with suggestions, manual review

### Decision 6: Defer /skill-list to Phase 2

**Decision**: Implement `/agent-list` and `/command-list` in Phase 1, defer `/skill-list` to Phase 2

**Rationale**:

- Skills architecture (ADR-009) is defined but NOT implemented
- No `~/.claude/skills/` directory exists
- Skills loading mechanism undefined (how agents "use" skills)
- 177 skills catalog unverified (source unclear)

**Alternatives**:

- Implement all three commands together: Rejected (blocks delivery on undefined architecture)
- Implement skills infrastructure first: Rejected (15-28 days effort)

**Trade-offs**:

- **Pro**: Fast delivery of high-value commands, validates approach before scaling
- **Con**: `/skill-list` delivered later (lower impact per PRD)
- **Mitigation**: Phase 2 plan documented, architecture investigation in parallel

## Implementation Plan

### Components to Build

**CLI Scripts** (`scripts/`):

- `list-agents.sh` - Scan agents, parse frontmatter, format output (4-6 hours)
- `list-commands.sh` - Scan commands, parse frontmatter, filter by category (8-12 hours)
- `list-skills.sh` - Deferred to Phase 2

**Shared Libraries** (`scripts/lib/`):

- `frontmatter-parser.sh` - Extract YAML frontmatter with sed/awk (2-3 hours)
- `path-sanitizer.sh` - Replace absolute paths with variables (1-2 hours)
- `readlink-portable.sh` - Cross-platform symlink resolution (1 hour)

**Slash Commands** (`templates/commands/.aida/`):

- `agent-list.md` - Invoke `scripts/list-agents.sh` (30 min)
- `command-list.md` - Invoke `scripts/list-commands.sh` with optional `--category` (30 min)
- `skill-list.md` - Deferred to Phase 2

**Configuration Updates**:

- Add `category` field to 32 existing command frontmatter files (2-3 hours)
- Update `create-command` template to include category prompt (30 min)
- Document category taxonomy in `templates/commands/README.md` (30 min)

**Validation Scripts**:

- `scripts/validate-command-frontmatter.sh` - Pre-commit hook for category validation (1-2 hours)
- Add shellcheck validation for new scripts (pre-commit integration)

**Installer Integration** (`install.sh`):

- Add `~/.claude/scripts/.aida/` directory creation
- Install scripts with executable permissions (755)
- Support dev mode (symlinks from `~/.aida/scripts/` → repo)

### Dependencies

**External Tools Required**:

- `bash` 3.2+ (macOS default)
- `sed`, `awk`, `grep` (POSIX standard)
- `find`, `readlink` or `python` (symlink resolution)
- Existing: `shellcheck`, `yamllint`, `markdownlint` (pre-commit)

**Internal Components Affected**:

- `install.sh` - Add scripts installation step
- `lib/installer-common/directories.sh` - Add scripts directory
- `.pre-commit-config.yaml` - Add command frontmatter validation
- All command templates - Add `category` field

**No New Dependencies**: Reuses existing POSIX tools and installer patterns

### Integration Points

**1. Frontmatter Parsing Pattern** (reusable across agents/commands/skills):

```bash

# Extract YAML frontmatter between --- markers

extract_frontmatter() {
    local file="$1"
    sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$file" | head -n 100
}

# Get specific field from frontmatter

get_field() {
    local frontmatter="$1"
    local field="$2"
    echo "$frontmatter" | awk -F': ' -v field="$field" \
        '$0 ~ "^" field ":" { sub("^" field ": *", ""); gsub(/^["'\'']|["'\'']$/, ""); print }'
}

```

**2. Two-Tier Scanning Pattern** (user + project discovery):

```bash

scan_two_tier() {
    local type="$1"  # agents or commands
    declare -A seen_paths  # Deduplication

    # Scan user-level
    for item in "${HOME}/.claude/${type}/.aida"/*; do
        local canonical=$(readlink_portable "$item")
        [[ -z "${seen_paths[$canonical]:-}" ]] && {
            seen_paths["$canonical"]="user"
            process_item "$item" "user"
        }
    done

    # Scan project-level (if different)
    for item in "./.claude/${type}/.aida"/*; do
        local canonical=$(readlink_portable "$item")
        [[ -z "${seen_paths[$canonical]:-}" ]] && {
            seen_paths["$canonical"]="project"
            process_item "$item" "project"
        }
    done
}

```

**3. Path Sanitization** (privacy protection):

```bash

sanitize_path() {
    local path="$1"

    # Replace paths with variables (most specific first)
    path="${path//${HOME}\/.claude/\${CLAUDE_CONFIG_DIR}}"
    path="${path//${HOME}\/.aida/\${AIDA_HOME}}"

    # Git root (only if in git repo)
    if git rev-parse --git-dir >/dev/null 2>&1; then
        local git_root=$(git rev-parse --show-toplevel)
        path="${path//${git_root}/\${PROJECT_ROOT}}"
    fi

    echo "$path"
}

```

**4. Category Taxonomy** (command filtering):

```yaml

# 8 categories for command classification

categories:
   - workflow        # Issue lifecycle, PR creation, branch management
   - quality         # Code review, testing, linting
   - security        # Audits, compliance, PII scanning
   - operations      # Incidents, debugging, runbooks
   - infrastructure  # AWS, GitHub, deployment
   - data            # Metrics, warehouses, analytics
   - documentation   # Doc generation, README updates
   - meta            # System commands (create-command, create-agent)

```

## Technical Risks & Mitigations

### Risk 1: Symlink Deduplication Failures in Dev Mode (HIGH)

**Impact**: High - Would show duplicate agents/commands in listings

**Scenario**: Dev mode creates symlinks `~/.claude/agents/` → `~/.aida/templates/agents/`. Without deduplication, same agent appears twice.

**Mitigation**:

- Use `realpath` or Python fallback to canonicalize paths
- Track seen paths in associative array
- Prefer real file over symlink in output
- Test extensively in dev mode

**Validation**: Integration tests with dev mode installation

### Risk 2: Frontmatter Parsing Edge Cases (HIGH)

**Impact**: High - Script crashes on malformed YAML, missing fields

**Scenario**: Complex YAML (multiline strings, special chars) breaks sed/awk parser

**Mitigation**:

- Validate frontmatter structure before parsing
- Handle missing fields gracefully (warn, don't crash)
- Test with edge cases (quotes, colons, multiline)
- Limit frontmatter size (200 lines / 4KB max)

**Validation**: Unit tests with malformed YAML fixtures

### Risk 3: macOS readlink Compatibility (MEDIUM)

**Impact**: Medium - Symlink deduplication fails on macOS (no `readlink -f`)

**Scenario**: macOS lacks GNU `readlink -f` flag for canonical path resolution

**Mitigation**:

- Detect `readlink -f` availability
- Fallback to `greadlink` (Homebrew) or Python
- Document in CONTRIBUTING.md

**Validation**: Test on macOS Sonoma, cross-platform Docker tests

### Risk 4: Performance with Large Catalogs (MEDIUM)

**Impact**: Medium - Commands exceed 1s response time with 177 skills

**Scenario**: Scanning 177 skills + parsing frontmatter could exceed performance target

**Mitigation**:

- Parse frontmatter only (not full files)
- Limit scan depth (`find -maxdepth 1`)
- Progressive disclosure for skills (categories first)
- Defer caching to Phase 2 if needed

**Validation**: Benchmark with full skills catalog (Phase 2)

### Risk 5: Path Sanitization False Positives (LOW)

**Impact**: Low - Legitimate paths accidentally sanitized

**Scenario**: Variable names in descriptions match replacement patterns

**Mitigation**:

- Only sanitize output paths (not frontmatter content)
- Test with edge cases (paths in descriptions)
- Order replacements (most specific first)

**Validation**: Privacy validation tests

### Risk 6: Category Taxonomy Drift (LOW)

**Impact**: Low - Commands use undefined categories over time

**Scenario**: Developers add commands with custom categories, bypassing validation

**Mitigation**:

- Pre-commit hook validates categories against enum
- Fail commits with invalid categories
- Suggest valid categories in error messages

**Validation**: Pre-commit hook tests

## Testing Strategy

### Unit Testing

**Frontmatter Parsing**:

- Valid YAML extraction
- Missing frontmatter (empty, no delimiters)
- Malformed YAML (syntax errors, unclosed quotes)
- Missing required fields (name, description)
- Multi-line values, special characters
- Oversized frontmatter (>4KB)

**Path Sanitization**:

- HOME directory replacement
- CLAUDE_CONFIG_DIR replacement
- PROJECT_ROOT replacement (git repos only)
- Symlinked paths
- Relative paths (should NOT be sanitized)

**Symlink Deduplication**:

- Normal files (no symlinks)
- Symlinks to same target
- Broken symlinks
- Circular symlinks (edge case)

### Integration Testing

**Two-Tier Discovery**:

- User-level only (no project context)
- Project-level only (no user context)
- Both tiers present (deduplicate correctly)
- Dev mode (handle symlinks)

**Category Filtering**:

- Valid category (show matching commands)
- Invalid category (error with suggestions)
- No category argument (show all with grouping)
- Commands without category field (show as "uncategorized")

**Output Formatting**:

- Global vs. project section separation
- Category grouping
- Color codes (with and without TTY)
- Usage hints at bottom

### Cross-Platform Testing

**Environments** (reuse test-install.sh Docker pattern):

- ubuntu-22.04 (GNU tools, bash 5.x)
- ubuntu-20.04 (GNU tools, bash 5.x)
- debian-12 (GNU tools, bash 5.x)
- macOS Sonoma (BSD tools, bash 3.2)

**Shell Compatibility**:

- bash 3.2 (macOS default)
- bash 4.x+ (modern Linux)
- zsh (macOS default shell, but scripts use bash)

**Tool Availability**:

- `readlink -f` presence (Linux yes, macOS no)
- `greadlink` availability (Homebrew on macOS)
- Python fallback (available everywhere)

### Edge Cases to Cover

**Filesystem**:

- Empty directories (no agents/commands found)
- Missing directories (`./.claude/` doesn't exist)
- Permission errors (unreadable files/directories)
- Unicode filenames (emoji in agent names)
- Special characters in paths (spaces, quotes)

**Frontmatter**:

- Empty frontmatter (no --- markers)
- Single delimiter (missing closing ---)
- Comments in frontmatter (# lines)
- Nested YAML structures (args field)

**Privacy**:

- No absolute paths in output
- Error messages don't leak paths
- Verbose mode warnings about sharing

## Open Technical Questions

### Question 1: Skills Catalog Source (CRITICAL - Phase 2)

**Question**: Where are the 177 skills stored? What is the file format?

**Impact**: Blocks `/skill-list` implementation

**Options**:

- A) `templates/skills/` directory (filesystem-based)
- B) External skills catalog URL (API-based)
- C) Claude Code built-in skills (external reference)

**Recommendation**: Investigate in parallel, document in ADR-015

### Question 2: Error Handling Severity

**Question**: Should missing frontmatter be error (exit 1) or warning (continue)?

**Options**:

- A) Error - fail fast, require valid metadata
- B) Warning - skip invalid entries, continue scanning
- C) Silent - ignore invalid entries entirely

**Recommendation**: Option B (warn and skip) for graceful degradation

### Question 3: Output Format Options (Phase 2)

**Question**: Should commands support JSON output (`--format json`)?

**Options**:

- A) Yes - add now for automation use cases
- B) Yes - defer to Phase 2 after validating text format
- C) No - text only, no automation needs identified

**Recommendation**: Option B (defer to Phase 2, validate demand)

### Question 4: Caching Strategy (Phase 2)

**Question**: Should discovery results be cached?

**Options**:

- A) Yes - cache in `/tmp/` with 5-minute TTL
- B) Yes - cache in `~/.claude/.cache/` with invalidation on changes
- C) No - always scan fresh (fast enough without caching)

**Recommendation**: Option C for Phase 1, revisit if performance issues

## Effort Estimate

### Overall Complexity: M (Medium)

**Justification**:

- Well-scoped feature with clear requirements
- Reuses existing patterns (frontmatter parsing, two-tier discovery)
- Proven bash scripting approach
- Incremental delivery (Phase 1 vs Phase 2)

**Not S (Small)** because:

- Multiple scripts and integration points
- Security controls required (path sanitization, error handling)
- Cross-platform testing needed
- Configuration migration (32 commands)

**Not L (Large)** because:

- No new infrastructure required
- Established patterns (ADR-002, template system)
- Defers complex features (skills) to Phase 2
- Limited external dependencies

### Detailed Effort Breakdown

#### Phase 1: MVP (Agents + Commands)

| Task | Effort | Complexity |
|------|--------|------------|
| Shared libraries (frontmatter, path, symlink) | 4-6 hours | S-M |
| `scripts/list-agents.sh` | 4-6 hours | S |
| `scripts/list-commands.sh` | 8-12 hours | M |
| Slash commands (2 files) | 1 hour | S |
| Command category migration (32 files) | 2-3 hours | S |
| Pre-commit validation hook | 1-2 hours | S |
| Installer integration | 2-3 hours | S |
| Testing (unit + integration) | 6-10 hours | M |
| Documentation (README, usage) | 2-3 hours | S |
| **Phase 1 Total** | **30-46 hours** | **3-6 days** |

#### Phase 2: Skills System (Deferred)

| Task | Effort | Complexity |
|------|--------|------------|
| Skills architecture investigation | 8 hours | M |
| Skills infrastructure implementation | 12-20 hours | L |
| `scripts/list-skills.sh` | 8-12 hours | M |
| Slash command (`/skill-list`) | 1 hour | S |
| Progressive disclosure implementation | 3-4 hours | S-M |
| Testing (skills catalog) | 6-10 hours | M |
| **Phase 2 Total** | **38-55 hours** | **5-7 days** |

### Key Effort Drivers

**High Effort**:

1. **Frontmatter Parsing Robustness** - Handle edge cases (quotes, multiline, special chars)
2. **Cross-Platform Testing** - Validate on macOS + Linux, Docker environments
3. **Configuration Migration** - Add `category` to 32 commands (manual review)

**Medium Effort**:

4. **Symlink Deduplication** - Portable implementation, dev mode testing
5. **Path Sanitization** - Comprehensive replacement patterns, privacy validation
6. **Integration Testing** - Two-tier discovery, category filtering, output formatting

**Low Effort**:

7. **Slash Command Creation** - Thin wrappers (2 files)
8. **Documentation** - Usage examples, troubleshooting guide

### Recommended Breakdown

**Sprint 1 (2 days)**:

- Shared libraries (frontmatter, path, symlink)
- `scripts/list-agents.sh` (simpler, no filtering)
- Slash command `/agent-list`
- Unit tests for libraries

**Sprint 2 (2 days)**:

- Command category migration (32 files)
- `scripts/list-commands.sh` (with filtering)
- Slash command `/command-list`
- Pre-commit validation hook

**Sprint 3 (1-2 days)**:

- Installer integration
- Cross-platform testing (Docker)
- Integration tests (two-tier, dev mode)
- Documentation

**Phase 2** (separate issue):

- Skills architecture investigation
- Skills infrastructure implementation
- `/skill-list` command

---

## Success Criteria

**Phase 1 Acceptance**:

- [ ] `/agent-list` shows all user + project agents without duplicates
- [ ] `/command-list --category workflow` filters correctly
- [ ] Scripts are executable standalone (not Claude-dependent)
- [ ] Frontmatter parsing handles malformed YAML gracefully
- [ ] Absolute paths sanitized in output (no usernames/project names)
- [ ] Permission errors don't expose filesystem structure
- [ ] Dev mode symlinks deduplicated correctly
- [ ] Pre-commit hook validates command categories
- [ ] All commands have valid `category` field
- [ ] Scripts execute in <500ms (agents/commands)
- [ ] Cross-platform tests pass (ubuntu-22, ubuntu-20, debian-12, macOS)

**Phase 2 Acceptance** (deferred):

- [ ] Skills architecture documented (ADR-015)
- [ ] `/skill-list` shows categories only by default
- [ ] `/skill-list <category>` shows skills within category
- [ ] Skills infrastructure functional (agents can "use" skills)
- [ ] Performance <1s for skills catalog (177 skills)

---

## Next Steps

**Immediate Actions**:

1. **configuration-specialist**: Migrate 32 commands to add `category` field
2. **shell-script-specialist**: Implement shared libraries + CLI scripts
3. **devops-engineer**: Update installer with scripts installation
4. **qa-engineer**: Create test fixtures and validation suite
5. **privacy-security-auditor**: Review path sanitization and error messages

**Phase 2 Preparation** (parallel):

1. **integration-specialist**: Investigate skills catalog architecture
2. **system-architect**: Draft ADR-015 for skills implementation
3. **product-manager**: Validate skills catalog requirements

---

**Specification Approved**: Ready for implementation - Phase 1 MVP scope

**Estimated Delivery**: 3-6 days (30-46 hours)

**Dependencies**: None (existing POSIX tools, installer patterns)

**Risks**: Manageable (symlink deduplication, frontmatter parsing edge cases)
