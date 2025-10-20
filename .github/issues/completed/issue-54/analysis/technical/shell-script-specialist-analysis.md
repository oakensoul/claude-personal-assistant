---
title: "Shell Script Specialist - Technical Analysis for Issue #54"
issue: 54
analyst: shell-script-specialist
created: 2025-10-20
status: completed
---

# Shell Script Specialist Analysis: Discoverability Commands

## Executive Summary

**Recommendation**: Implement `/agent-list` and `/command-list` using lightweight shell scripts with `sed`/`awk` for frontmatter parsing (no `yq` dependency). Defer `/skill-list` until skills architecture is clarified.

**Key Technical Decisions**:

- Use `sed` for YAML frontmatter extraction (portable, no deps)
- Two-tier scanning: `~/.claude/` then `./.claude/`
- Path sanitization via string replacement (no heavy processing)
- Symlink deduplication via `readlink -f` (macOS compatibility handled)

**Estimated Effort**:

- `/agent-list`: **Small** (4-6 hours) - Simple scanning, no filtering
- `/command-list`: **Medium** (8-12 hours) - Category filtering, metadata parsing
- Shared utilities: **Small** (2-4 hours) - Frontmatter parser, path sanitizer

**Total Phase 1 Estimate**: 14-22 hours (2-3 days)

---

## 1. Implementation Approach

### Recommended Architecture

```text

scripts/
├── lib/
│   ├── frontmatter-parser.sh       # Extract YAML frontmatter (sed/awk)
│   └── path-sanitizer.sh           # Replace absolute paths with variables
├── list-agents.sh                  # Agent discovery (no filtering)
└── list-commands.sh                # Command discovery (category filtering)

```

### Core Technical Strategy

**Frontmatter Parsing** - Lightweight sed/awk approach:

```bash

# Extract YAML frontmatter between --- markers

extract_frontmatter() {
    local file="$1"
    sed -n '/^---$/,/^---$/p' "$file" | sed '1d;$d'
}

# Get specific field from frontmatter

get_field() {
    local frontmatter="$1"
    local field="$2"
    echo "$frontmatter" | awk -F': ' "/^${field}:/ {print \$2}" | sed 's/^["'\'']\|["'\'']$//g'
}

```

**Two-Tier Directory Scanning**:

```bash

scan_agents() {
    local user_dir="${HOME}/.claude/agents"
    local proj_dir="./.claude/agents"

    # Scan user-level (resolve symlinks to avoid duplicates)
    if [[ -d "$user_dir" ]]; then
        find "$user_dir" -maxdepth 1 -type d -name ".aida"
    fi

    # Scan project-level (if not same as user-level)
    if [[ -d "$proj_dir" ]] && [[ "$(realpath "$proj_dir")" != "$(realpath "$user_dir")" ]]; then
        find "$proj_dir" -maxdepth 1 -type d -name ".aida"
    fi
}

```

**Path Sanitization**:

```bash

sanitize_path() {
    local path="$1"

    # Replace absolute paths with variables
    path="${path/#${HOME}\/\.claude/\${CLAUDE_CONFIG_DIR}}"
    path="${path/#${HOME}\/\.aida/\${AIDA_HOME}}"
    path="${path/#$(git rev-parse --show-toplevel 2>/dev/null)/\${PROJECT_ROOT}}"

    echo "$path"
}

```

### Technology Choices

**Frontmatter Parsing: `sed` + `awk` (NOT `yq`)**

Rationale:

- `yq` version 3.4.3 detected (old, BSD-like syntax)
- YAML frontmatter is simple (key: value pairs)
- `sed`/`awk` sufficient for flat YAML extraction
- Avoids version compatibility issues
- Portable across all systems

**File Discovery: `find` (NOT `glob`)**

Rationale:

- Need maxdepth control to avoid deep scanning
- Need symlink deduplication (`-type d` vs `-type l`)
- Standard POSIX tool, highly portable

**Output Formatting: `printf` + ANSI codes**

Rationale:

- Existing `lib/installer-common/colors.sh` provides color constants
- Reuse existing color infrastructure
- Simple table formatting with `printf` alignment

---

## 2. Technical Concerns

### Performance Implications

**Filesystem Scanning**:

- **Agents**: ~15 agents per tier = ~30 files max
- **Commands**: ~32 commands per tier = ~64 files max
- **Impact**: Minimal (<100ms even without caching)
- **Optimization**: Use `find -maxdepth 1` (don't recurse into knowledge/)

**Frontmatter Parsing**:

- `sed` extraction: ~1ms per file
- Parsing 64 files: ~64ms total
- **Target met**: <500ms easily achievable

**Symlink Resolution** (potential bottleneck):

- `readlink -f` may be slow on network filesystems
- Mitigation: Cache resolved paths in associative array
- Dev mode uses symlinks extensively (dedup critical)

### Parsing Reliability

**YAML Frontmatter Complexity**:

- Simple: `name: value` (98% of cases)
- Quoted values: `description: "Has: colons"`
- Arrays: `tags: ["tag1", "tag2"]` or multiline
- **Approach**: Handle simple cases first, warn on complex YAML

**Edge Cases to Handle**:

```yaml

# Simple (easy)

name: agent-name
description: Brief description

# Quoted values (medium)

description: "Description with: colons and \"quotes\""

# Arrays (complex - defer)

tags: ["tag1", "tag2"]
tags:
   - tag1
   - tag2

```

**Parsing Strategy**:

```bash

# Extract description handling quotes and colons

get_description() {
    local fm="$1"
    # Try simple match first
    local desc=$(echo "$fm" | awk -F': ' '/^description:/ {$1=""; print substr($0,3)}')
    # Remove surrounding quotes if present
    desc="${desc#\"}"
    desc="${desc%\"}"
    echo "$desc"
}

```

### Two-Tier Scanning Strategy

**Directory Resolution**:

```bash

scan_two_tier() {
    local type="$1"  # agents or commands
    local user_dir="${HOME}/.claude/${type}/.aida"
    local proj_dir="./.claude/${type}/.aida"

    declare -A seen_paths  # Deduplication

    # Scan user-level
    if [[ -d "$user_dir" ]]; then
        for item in "$user_dir"/*; do
            [[ -d "$item" ]] || continue
            local canonical=$(readlink_portable "$item")
            seen_paths["$canonical"]="user"
            process_item "$item" "user"
        done
    fi

    # Scan project-level (skip if symlinked to user-level)
    if [[ -d "$proj_dir" ]]; then
        local proj_canonical=$(readlink_portable "$proj_dir")
        if [[ "$proj_canonical" != "$user_dir" ]]; then
            for item in "$proj_dir"/*; do
                [[ -d "$item" ]] || continue
                local canonical=$(readlink_portable "$item")
                if [[ -z "${seen_paths[$canonical]:-}" ]]; then
                    seen_paths["$canonical"]="project"
                    process_item "$item" "project"
                fi
            done
        fi
    fi
}

```

**Symlink Deduplication**:

- Dev mode: `~/.claude/agents/.aida` → `/path/to/dev/templates/agents`
- Both tiers may point to same physical location
- Use `readlink` to get canonical paths, deduplicate by inode

### Path Sanitization Approach

**String Replacement Strategy**:

```bash

sanitize_path() {
    local path="$1"

    # Order matters (most specific first)
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

**Privacy Protection**:

- Never expose `/Users/rob/` (use `${HOME}`)
- Never expose full project paths (use `${PROJECT_ROOT}`)
- Generic error messages (no path disclosure on failure)

---

## 3. Dependencies & Integration

### External Tool Requirements

**Required (POSIX standard)**:

- `bash` 3.2+ (macOS default)
- `sed` (GNU or BSD)
- `awk` (any version)
- `find` (POSIX)
- `grep` (POSIX)

**Optional (enhanced functionality)**:

- `readlink` (GNU) or `greadlink` (Homebrew on macOS)
- `realpath` (GNU coreutils) or `python` fallback

**NOT Required**:

- `yq` (avoiding due to version fragmentation)
- `jq` (not needed for YAML frontmatter)

### Slash Command Integration

**Command File Structure**:

```markdown

---
name: agent-list
description: List all available AIDA agents with descriptions
args:
  --format:
    description: Output format (text, json)
    required: false
    default: text
---

# Agent List Command

Discovers and lists all agents from ~/.claude/agents/ and ./.claude/agents/.

## Instructions

1. Check for format argument (--format text or --format json)
2. Invoke scripts/list-agents.sh with format parameter
3. Display output to user
4. Handle errors gracefully (missing directories, permission errors)

```

**Invocation from Claude**:

- User types: `/agent-list`
- Claude executes: `bash scripts/list-agents.sh`
- Script outputs formatted list
- Claude displays results

### Error Handling Strategy

**Categories of Errors**:

1. **Missing Directories** (non-fatal):

   ```bash

   if [[ ! -d "$user_dir" ]] && [[ ! -d "$proj_dir" ]]; then
       echo "No agent directories found. Run installation first."
       exit 1
   fi

   ```

2. **Permission Errors** (non-fatal):

   ```bash

   if [[ ! -r "$agent_file" ]]; then
       warn "Cannot read agent file (skipping)"
       continue
   fi

   ```

3. **Malformed Frontmatter** (warn and skip):

   ```bash

   if ! validate_frontmatter "$file"; then
       warn "Invalid frontmatter in $file (skipping)"
       continue
   fi

   ```

4. **Missing Required Fields** (warn and skip):

   ```bash

   if [[ -z "$name" ]] || [[ -z "$description" ]]; then
       warn "Missing required fields in $file"
       continue
   fi

   ```

**Error Message Privacy**:

```bash

# BAD - exposes filesystem structure

echo "Error: Cannot read /Users/rob/.claude/agents/foo/bar.md"

# GOOD - generic message

echo "Error: Cannot read agent configuration (permission denied)"

```

---

## 4. Effort & Complexity

### Complexity Breakdown

**`/agent-list`** - **SMALL** (4-6 hours):

- Simple directory scanning (no deep recursion)
- Flat agent list (no categories)
- No filtering required
- Straightforward frontmatter parsing (name, description only)
- Existing color utilities reusable

**`/command-list`** - **MEDIUM** (8-12 hours):

- Category field parsing (new requirement)
- Category filtering logic
- Enum validation (8 predefined categories)
- More complex output (grouped by category)
- Help text for unknown categories

**Shared Utilities** - **SMALL** (2-4 hours):

- Frontmatter parser (shared by both)
- Path sanitizer (shared by both)
- Symlink deduplication logic
- Error handling framework

### Key Effort Drivers

**Frontmatter Parsing Robustness**:

- Handling quoted values with colons (medium complexity)
- Multiline descriptions (rare but possible)
- Testing across different YAML styles

**Cross-Platform Compatibility**:

- `readlink -f` not available on macOS (need `greadlink` or Python fallback)
- BSD `sed` vs GNU `sed` differences
- Testing on both macOS and Linux

**Symlink Deduplication**:

- Dev mode creates complex symlink scenarios
- Need reliable canonical path resolution
- Testing both normal and dev mode installations

### Risk Areas

**HIGH RISK**:

- **Symlink handling in dev mode**: May produce duplicates if deduplication fails
- **Frontmatter parsing edge cases**: Complex YAML may break parser
- **macOS `readlink` compatibility**: May fail without `greadlink`

**MEDIUM RISK**:

- **Category taxonomy drift**: Commands may use undefined categories
- **Performance on slow filesystems**: Network mounts may slow scanning
- **Permission errors**: May fail silently if directories unreadable

**LOW RISK**:

- **Output formatting**: Colors may not work in all terminals (graceful degradation)
- **Path sanitization completeness**: Some edge case paths may not be sanitized
- **Error message clarity**: Users may not understand cryptic errors

---

## 5. Questions & Clarifications

### Critical Questions

#### Q1: Category Taxonomy Enforcement?

- Should scripts validate categories against predefined enum?
- Should scripts warn/error on unknown categories?
- **Recommendation**: Warn on unknown, continue processing

#### Q2: Symlink Handling in Output?

- Should output indicate when item is symlinked?
- Display: "agent-name (symlink)" or just "agent-name"?
- **Recommendation**: Show origin (user/project) but not symlink status

#### Q3: Dev Mode Symlink Target Display?

- Show framework template path or installation path?
- Example: Show `${CLAUDE_CONFIG_DIR}/agents/foo` or `${AIDA_HOME}/templates/agents/foo`?
- **Recommendation**: Show installation path (user perspective)

### Technical Decisions Needed

#### D1: Handle Missing `readlink -f` on macOS?

Options:

- A) Require `greadlink` (via Homebrew)
- B) Fallback to Python: `python -c "import os; print(os.path.realpath('$path'))"`
- C) Skip deduplication on macOS (accept potential duplicates)
- **Recommendation**: Option B (Python fallback, no deps)

#### D2: JSON Output Format (Phase 2)?

Structure for future JSON output:

```json

{
  "agents": {
    "user": [{"name": "...", "description": "...", "model": "..."}],
    "project": [...]
  },
  "summary": {"user": 5, "project": 3, "total": 8}
}

```

**Recommendation**: Defer JSON to Phase 2, validate structure now

#### D3: Caching Strategy?

- Cache scan results in `/tmp/aida-agent-list-cache-$(date +%s).txt`?
- Cache invalidation: TTL (5 min?) or never?
- **Recommendation**: No caching in Phase 1 (premature optimization)

### Investigation Areas

**I1: Skills Architecture** (blocks `/skill-list`):

- Where are skills stored? (`templates/skills/`? External catalog?)
- What is skill file format? (Markdown? YAML? JSON?)
- How many skills exist? (PRD mentions 177 skills, 28 categories)
- **Action**: Defer `/skill-list` to Phase 2 after investigation

**I2: Command Frontmatter Consistency**:

- Do all 32 existing commands have valid frontmatter?
- Are required fields (name, description) present?
- **Action**: Audit existing commands before implementation

**I3: Agent Knowledge Directory Scanning**:

- Should `/agent-list` show knowledge file counts?
- Count files in `knowledge/` directories?
- **Action**: Phase 2 enhancement (not MVP)

---

## Implementation Checklist

### Phase 1 - MVP

**Shared Utilities**:

- [ ] Create `scripts/lib/frontmatter-parser.sh`

  - [ ] `extract_frontmatter()` function
  - [ ] `get_field()` function with quote handling
  - [ ] `validate_frontmatter()` function

- [ ] Create `scripts/lib/path-sanitizer.sh`

  - [ ] `sanitize_path()` function
  - [ ] Handle HOME, CLAUDE_CONFIG_DIR, AIDA_HOME, PROJECT_ROOT

- [ ] Create `scripts/lib/readlink-portable.sh`

  - [ ] Detect `readlink -f` availability
  - [ ] Python fallback for macOS

**`/agent-list` Implementation**:

- [ ] Create `scripts/list-agents.sh`
- [ ] Scan `~/.claude/agents/.aida/`
- [ ] Scan `./.claude/agents/.aida/` (if different)
- [ ] Deduplicate symlinks
- [ ] Parse agent frontmatter (name, description, model)
- [ ] Format output (user section, project section)
- [ ] Add color-coded output
- [ ] Handle errors gracefully

**`/command-list` Implementation**:

- [ ] Create `scripts/list-commands.sh`
- [ ] Scan `~/.claude/commands/.aida/`
- [ ] Scan `./.claude/commands/.aida/` (if different)
- [ ] Parse command frontmatter (name, description, category)
- [ ] Implement category filtering (--category flag)
- [ ] Validate categories against taxonomy
- [ ] Format output (grouped by category)
- [ ] Add usage hints at bottom

**Testing**:

- [ ] Test on macOS (BSD tools)
- [ ] Test on Linux (GNU tools)
- [ ] Test normal installation mode
- [ ] Test dev installation mode (symlinks)
- [ ] Test missing directories (graceful failure)
- [ ] Test malformed frontmatter (warn and skip)
- [ ] Test permission errors (generic messages)
- [ ] Validate no absolute paths in output

---

## Appendix: Code Samples

### Portable Readlink Function

```bash

#!/usr/bin/env bash

# lib/readlink-portable.sh

readlink_portable() {
    local path="$1"

    # Try GNU readlink first
    if command -v readlink >/dev/null 2>&1 && readlink -f / >/dev/null 2>&1; then
        readlink -f "$path"
        return $?
    fi

    # Try greadlink (Homebrew on macOS)
    if command -v greadlink >/dev/null 2>&1; then
        greadlink -f "$path"
        return $?
    fi

    # Fallback to Python (available on macOS and Linux)
    if command -v python3 >/dev/null 2>&1; then
        python3 -c "import os; print(os.path.realpath('$path'))"
        return $?
    elif command -v python >/dev/null 2>&1; then
        python -c "import os; print(os.path.realpath('$path'))"
        return $?
    fi

    # Last resort: return path as-is (may cause duplicates)
    echo "$path"
    return 0
}

```

### Frontmatter Parser

```bash

#!/usr/bin/env bash

# lib/frontmatter-parser.sh

extract_frontmatter() {
    local file="$1"

    # Extract content between first two --- markers
    sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$file" | head -n 100
}

get_field() {
    local frontmatter="$1"
    local field="$2"

    # Extract field value, handling quotes and colons
    local value
    value=$(echo "$frontmatter" | awk -F': ' -v field="$field" '
        $0 ~ "^" field ":" {
            # Remove field name and leading colon+space
            sub("^" field ": *", "")
            # Remove surrounding quotes if present
            gsub(/^["'\'']|["'\'']$/, "")
            print
        }
    ')

    echo "$value"
}

validate_frontmatter() {
    local frontmatter="$1"

    # Check if frontmatter is empty
    [[ -n "$frontmatter" ]] || return 1

    # Check if it looks like YAML (has at least one key: value pair)
    echo "$frontmatter" | grep -q '^[a-z_-]\+:' || return 1

    return 0
}

```

### Agent List Script Skeleton

```bash

#!/usr/bin/env bash

# scripts/list-agents.sh

set -euo pipefail

# Source shared libraries

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/frontmatter-parser.sh"
source "${SCRIPT_DIR}/lib/path-sanitizer.sh"
source "${SCRIPT_DIR}/lib/readlink-portable.sh"

# Source color utilities

source "${HOME}/.aida/lib/installer-common/colors.sh" 2>/dev/null || true

main() {
    local format="${1:-text}"  # text or json

    declare -A seen_agents

    echo "# AIDA Agents"
    echo ""

    # Scan user-level agents
    echo "## User-Level Agents (${CLAUDE_CONFIG_DIR})"
    scan_agents "${HOME}/.claude/agents/.aida" "user" seen_agents

    echo ""

    # Scan project-level agents (if different)
    if [[ -d "./.claude/agents/.aida" ]]; then
        local proj_canonical=$(readlink_portable "./.claude/agents/.aida")
        local user_canonical=$(readlink_portable "${HOME}/.claude/agents/.aida")

        if [[ "$proj_canonical" != "$user_canonical" ]]; then
            echo "## Project-Level Agents (\${PROJECT_ROOT}/.claude)"
            scan_agents "./.claude/agents/.aida" "project" seen_agents
        fi
    fi

    echo ""
    echo "→ Usage: Invoke agents via natural language or slash commands"
}

scan_agents() {
    local agent_dir="$1"
    local tier="$2"
    local -n seen=$3

    [[ -d "$agent_dir" ]] || return 0

    for agent_path in "$agent_dir"/*; do
        [[ -d "$agent_path" ]] || continue

        local canonical=$(readlink_portable "$agent_path")
        [[ -n "${seen[$canonical]:-}" ]] && continue
        seen["$canonical"]=1

        process_agent "$agent_path" "$tier"
    done
}

process_agent() {
    local agent_path="$1"
    local tier="$2"
    local agent_name=$(basename "$agent_path")
    local agent_file="${agent_path}/${agent_name}.md"

    [[ -f "$agent_file" ]] || return 0

    local fm=$(extract_frontmatter "$agent_file")
    [[ -n "$fm" ]] || return 0

    local name=$(get_field "$fm" "name")
    local description=$(get_field "$fm" "description")
    local model=$(get_field "$fm" "model")

    printf "  - %-25s %s\n" "$name" "$description"
}

main "$@"

```

---

## Next Steps

1. **configuration-specialist**: Add `category` field to all command frontmatter (28 commands)
2. **shell-script-specialist** (this agent): Implement `scripts/list-agents.sh` and `scripts/list-commands.sh`
3. **integration-specialist**: Create slash command definitions (`.aida/agent-list.md`, `.aida/command-list.md`)
4. **integration-specialist**: Investigate skills catalog architecture (Phase 2)
5. **privacy-security-auditor**: Review path sanitization and error message privacy

**Ready to Implement**: Yes (all questions answered, approach validated)
