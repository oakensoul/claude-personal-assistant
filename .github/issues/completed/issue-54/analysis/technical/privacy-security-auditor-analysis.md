---
issue: 54
title: "Technical Analysis - Privacy & Security Implementation for Discoverability Commands"
analyst: privacy-security-auditor
date: 2025-10-20
status: complete
---

# Technical Analysis: Privacy & Security Implementation

## 1. Implementation Approach

### Security Implementation Requirements

**Frontmatter-Only Parsing** (CRITICAL):

- Use `sed -n '/^---$/,/^---$/p'` to extract only content between YAML markers
- NEVER read full file content into variables
- Validate extracted content is valid YAML before parsing
- Limit frontmatter size (max 4KB) to prevent memory exhaustion attacks
- Use `head -n 200` as safety limit on frontmatter extraction

**Input Validation**:

- Validate directory paths before scanning (canonicalize, check existence)
- Sanitize file paths to prevent path traversal (reject `..`, absolute paths outside expected dirs)
- Validate filenames match expected pattern (`*.md`, no special chars)
- Reject symlinks that escape expected directories

**Error Handling**:

- All error messages MUST be generic (no path disclosure)
- Permission denied: "Unable to scan directory" (NOT "Permission denied: /path/to/dir")
- File not found: "Resource not available" (NOT "File not found: /path/to/file.md")
- Malformed YAML: "Invalid metadata format" (NOT "YAML parse error at line 5")

### Path Sanitization Technical Approach

**Replacement Patterns**:

```bash

# Replace absolute paths with variables

sanitize_path() {
  local path="$1"

  # Replace home directory variations
  path="${path/#${HOME}/\${HOME}}"
  path="${path/#~\//${HOME}\/}"

  # Replace CLAUDE_CONFIG_DIR (after resolving symlinks)
  local claude_dir
  claude_dir="$(realpath "${CLAUDE_CONFIG_DIR}" 2>/dev/null || echo "${CLAUDE_CONFIG_DIR}")"
  path="${path/#${claude_dir}/\${CLAUDE_CONFIG_DIR}}"

  # Replace AIDA_HOME
  local aida_home
  aida_home="$(realpath "${AIDA_HOME}" 2>/dev/null || echo "${AIDA_HOME}")"
  path="${path/#${aida_home}/\${AIDA_HOME}}"

  # Replace current project root
  if [[ -n "${PROJECT_ROOT:-}" ]]; then
    path="${path/#${PROJECT_ROOT}/\${PROJECT_ROOT}}"
  fi

  echo "${path}"
}

```

**Sanitization Points**:

- Agent/command file paths in output listings
- Directory headers in output sections
- Error messages (if paths must be shown)
- Debug logs (if verbose mode enabled)

### Frontmatter-Only Parsing Validation

**Safe Extraction Pattern**:

```bash

# Extract frontmatter safely (with size limit)

extract_frontmatter() {
  local file="$1"
  local max_lines=200  # ~4KB at 20 chars/line

  # Verify file exists and is readable
  [[ -f "${file}" && -r "${file}" ]] || return 1

  # Extract only between first two --- markers, limit size
  sed -n '/^---$/,/^---$/p' "${file}" | head -n "${max_lines}" | grep -v '^---$'
}

# Parse specific field from frontmatter

get_field() {
  local file="$1"
  local field="$2"

  local frontmatter
  frontmatter="$(extract_frontmatter "${file}")" || return 1

  # Extract field value, trim whitespace
  echo "${frontmatter}" | grep "^${field}:" | cut -d: -f2- | xargs
}

# Validate frontmatter is valid YAML (structure check only)

validate_frontmatter() {
  local file="$1"

  local frontmatter
  frontmatter="$(extract_frontmatter "${file}")" || return 1

  # Basic structure check (key: value format)
  if ! echo "${frontmatter}" | grep -qE '^[a-zA-Z0-9_-]+:'; then
    log_error "Invalid frontmatter structure in ${file}"
    return 1
  fi

  return 0
}

```

**Validation Tests**:

- Empty frontmatter (missing --- markers)
- Malformed YAML (syntax errors)
- Missing required fields (name, description)
- Oversized frontmatter (>4KB)
- Frontmatter with embedded scripts (injection attempts)

## 2. Technical Concerns

### Security Vulnerabilities to Prevent

**Path Traversal (HIGH RISK)**:

- User provides malicious filename: `../../etc/passwd`
- Symlink escape: `~/.claude/agents/malicious -> /etc/`
- **Mitigation**: Canonicalize paths, validate within expected directories, reject symlinks escaping boundaries

**Command Injection (MEDIUM RISK)**:

- Malicious frontmatter: `description: "Test $(rm -rf /tmp/*)"`
- Filename injection: `agent-name; rm -rf /tmp/*`
- **Mitigation**: Never eval or execute strings from frontmatter, quote all variables, use `read -r`

**Information Disclosure (MEDIUM RISK)**:

- Error messages expose filesystem structure
- Verbose output shows absolute paths
- Debug logs contain sensitive metadata
- **Mitigation**: Sanitize all output, generic error messages, optional privacy filtering

**Denial of Service (LOW RISK)**:

- Extremely large frontmatter (memory exhaustion)
- Infinite loop in malformed YAML parsing
- Excessive file scanning (thousands of agents)
- **Mitigation**: Size limits on frontmatter, timeouts on operations, pagination for large results

### Privacy Leakage Risks

**User-Specific Data in Output**:

- Usernames in paths: `/Users/oakensoul/.claude/`
- Project names: `/Develop/client-confidential-project/.claude/`
- Agent names revealing proprietary systems: `internal-trading-system-agent`
- **Mitigation**: Path sanitization, optional privacy markers, warn users before sharing output

**Cross-Context Contamination**:

- Global agents (private) mixed with project agents (shared)
- Personal preferences exposed when listing project agents
- **Mitigation**: Clear section separation, label scope explicitly (Global/Project/Built-in)

**Metadata Leakage**:

- Agent descriptions contain sensitive business logic
- Command args documentation reveals internal APIs
- Knowledge base paths expose project structure
- **Mitigation**: Parse only required fields (name, description), optional privacy markers, truncate long descriptions

### Input Validation Requirements

**Directory Path Validation**:

```bash

validate_scan_directory() {
  local dir="$1"

  # Must be absolute path
  [[ "${dir}" =~ ^/ ]] || return 1

  # Canonicalize (resolve symlinks)
  local canonical
  canonical="$(realpath "${dir}" 2>/dev/null)" || return 1

  # Must be within expected directories
  if [[ "${canonical}" != "${HOME}/.claude/"* &&
        "${canonical}" != "${HOME}/.aida/"* &&
        "${canonical}" != "${PWD}/.claude/"* ]]; then
    return 1
  fi

  # Must be readable directory
  [[ -d "${canonical}" && -r "${canonical}" ]] || return 1

  echo "${canonical}"
  return 0
}

```

**Filename Validation**:

```bash

validate_agent_file() {
  local file="$1"

  # Must end in .md
  [[ "${file}" == *.md ]] || return 1

  # Filename must be alphanumeric, dash, underscore only
  local basename
  basename="$(basename "${file}")"
  [[ "${basename}" =~ ^[a-zA-Z0-9_-]+\.md$ ]] || return 1

  # Must be regular file (not symlink, device, etc.)
  [[ -f "${file}" && ! -L "${file}" ]] || return 1

  # Must be readable
  [[ -r "${file}" ]] || return 1

  return 0
}

```

### Error Message Security (No Path Exposure)

**Generic Error Messages**:

```bash

# BAD - exposes path

echo "Error: Permission denied reading /Users/oakensoul/.claude/agents/secret-agent.md"

# GOOD - generic

echo "Error: Unable to read agent metadata"

# BAD - exposes directory structure

echo "Error: Directory not found: /Users/oakensoul/.claude/agents/proprietary/"

# GOOD - generic with context

echo "Error: Agent directory not accessible (check permissions)"

# BAD - exposes scanning logic

echo "Error: Symlink target outside allowed directories: /etc/passwd"

# GOOD - generic security boundary

echo "Error: Invalid agent configuration detected"

```

**Error Logging vs. User Output**:

- User-facing errors: Generic, no paths, actionable guidance
- Debug logs: Detailed, full paths, for troubleshooting only
- Separate log levels: ERROR (generic) vs. DEBUG (detailed)

## 3. Dependencies & Integration

### Security Validation Tools Needed

**Pre-Commit Hooks**:

- `shellcheck` - shell script linting (existing)
- `yamllint` - YAML validation (existing)
- `markdownlint` - markdown validation (existing)
- **NEW**: `scripts/validate-discoverability-output.sh` - test output sanitization

**Testing Requirements**:

```bash

# Test frontmatter parsing with malicious input

test_malicious_frontmatter() {
  # Embedded commands
  echo -e "---\ndescription: Test \$(whoami)\n---" | validate_frontmatter

  # Oversized frontmatter
  yes "key: value" | head -n 1000 | validate_frontmatter

  # Path traversal in filename
  validate_agent_file "../../etc/passwd"

  # Symlink escape
  ln -s /etc ~/.claude/agents/escape
  validate_agent_file ~/.claude/agents/escape/passwd
}

# Test path sanitization

test_path_sanitization() {
  local output
  output="$(list_agents | grep -E '/Users/|/home/')"

  if [[ -n "${output}" ]]; then
    echo "FAIL: Absolute paths leaked in output"
    echo "${output}"
    return 1
  fi
}

# Test error message sanitization

test_error_messages() {
  # Trigger permission error
  chmod 000 ~/.claude/agents/test-agent.md
  local error
  error="$(list_agents 2>&1 | grep "Permission denied")"

  if echo "${error}" | grep -qE '/(Users|home)/'; then
    echo "FAIL: Error message leaked path"
    return 1
  fi

  chmod 644 ~/.claude/agents/test-agent.md
}

```

### Integration with Existing Security Patterns

**Reuse from `validate-templates.sh`**:

- Path sanitization patterns (lines 157-202)
- Email detection (lines 238-263)
- Credential detection (lines 266-304)
- Error formatting (lines 138-154)

**Reuse from `lib/installer-common/validation.sh`**:

- Path canonicalization pattern (lines 97+)
- Version validation (lines 32-41)
- Input sanitization principles

**New Patterns to Add**:

- Frontmatter-only extraction (not in existing code)
- YAML structure validation (minimal implementation)
- Privacy marker support (`privacy: private` in frontmatter)

### Pre-Commit Security Checks

**Add to `.pre-commit-config.yaml`**:

```yaml

- id: validate-discoverability

  name: Validate Discoverability Security
  entry: scripts/validate-discoverability-security.sh
  language: script
  pass_filenames: false
  stages: [commit]

```

**New Script: `scripts/validate-discoverability-security.sh`**:

- Test frontmatter parsing with malicious input
- Verify path sanitization works correctly
- Check error messages don't leak paths
- Validate privacy markers are respected

## 4. Effort & Complexity

### Estimated Complexity: **MEDIUM (M)**

**Justification**:

- Frontmatter parsing is straightforward (sed + grep)
- Path sanitization patterns exist (reuse from validate-templates.sh)
- Input validation follows existing patterns (lib/installer-common/)
- Error handling requires careful implementation but not complex
- Testing requires multiple security test cases

**Not XL because**:

- No cryptography or complex security protocols
- No network security concerns (local-only)
- No authentication/authorization system
- Existing security patterns to reuse

**Not S because**:

- Multiple security controls required (input validation, sanitization, error handling)
- Security testing needs comprehensive coverage
- Edge cases require careful handling (symlinks, permissions, malformed input)

### Key Effort Drivers

**High Effort**:

1. **Comprehensive testing** - Multiple attack vectors to test (path traversal, injection, info disclosure)
2. **Error handling** - Every failure path must be secure (no path leakage)
3. **Path sanitization** - Handle all path variations (absolute, relative, symlinked, ~, ${VAR})

**Medium Effort**:

4. **Input validation** - Directory paths, filenames, frontmatter structure
5. **Frontmatter parsing** - Safe extraction, size limits, validation
6. **Integration** - Reuse existing patterns, add new pre-commit hooks

**Low Effort**:

7. **Documentation** - Security considerations for each script
8. **Privacy markers** - Simple boolean flag in frontmatter

### Risk Areas

**HIGH RISK**:

- **Path traversal** - Malicious symlinks or `..` in paths could expose system files
- **Information disclosure** - Error messages or output accidentally leaking sensitive paths

**MEDIUM RISK**:

- **Command injection** - Malformed frontmatter could execute arbitrary commands
- **Denial of service** - Oversized frontmatter or excessive scanning could hang scripts

**LOW RISK**:

- **Privacy metadata leakage** - Agent names/descriptions revealing sensitive info (user controls this)
- **Cross-context contamination** - Global vs. project separation (clear in design)

## 5. Questions & Clarifications

### Technical Questions Needing Answers

**Frontmatter Parsing**:

1. Should we use `yq` (YAML parser) or stick with `sed`/`grep` for simplicity?

   - **Recommendation**: `sed`/`grep` for better portability, no external dependencies

2. What is maximum acceptable frontmatter size? (4KB recommended)
3. How to handle multi-line values in frontmatter (description with line breaks)?

   - **Recommendation**: Extract full YAML block, parse with `awk` or `yq` if needed

**Path Sanitization**:

4. Should sanitization happen in each script or centralized utility function?

   - **Recommendation**: Centralized in `lib/installer-common/validation.sh`

5. What if `${CLAUDE_CONFIG_DIR}` is undefined? (fallback to `~/.claude/`?)
6. Should we sanitize paths in debug/verbose logs? (YES for privacy, NO for troubleshooting)

   - **Recommendation**: Separate log destinations (user-facing vs. debug logs)

**Privacy Markers**:

7. How should `privacy: private` be enforced? (filter from default output, show with `--include-private` flag?)
8. Should privacy markers be validated during installation? (warn if public agent marked private?)
9. Should project-level agents inherit privacy from global context? (NO, explicit only)

### Decisions to Be Made

**Error Handling Strategy**:

- **Option A**: Silent failures (skip unreadable files, continue)
- **Option B**: Fail fast (exit on first error)
- **Option C**: Collect errors, report at end (RECOMMENDED)

**Verbosity Levels**:

- **Default**: Sanitized output, no paths, generic errors
- **`--verbose`**: Show sanitized paths, detailed progress
- **`--debug`**: Show full paths, diagnostic info (warn: not for sharing)

**Privacy Filtering**:

- **Default**: Show all agents/commands (global + project)
- **`--public-only`**: Filter out agents with `privacy: private` marker
- **`--no-sanitize`**: Disable path sanitization (for local debugging only)

### Areas Needing Investigation

**Symlink Handling**:

- Dev mode creates symlinks from `~/.claude/` to framework templates
- How to detect and deduplicate symlinked entries?
- Should symlink targets be validated within boundaries?
- **Investigation needed**: Test dev mode installation, examine symlink structure

**Skills Catalog Architecture**:

- Where are skills stored? (framework templates, external catalog, generated?)
- Are skills static metadata or dynamically discovered?
- Do skills have frontmatter like agents/commands?
- **Investigation needed**: Examine claude-agent-manager skills integration

**Performance Optimization**:

- Should results be cached? (privacy implications if cache persists)
- Should scanning be parallelized? (watchout for race conditions)
- What if there are 100+ custom agents? (pagination needed?)
- **Investigation needed**: Performance testing with large agent counts

## Implementation Checklist

**Core Security Controls** (MUST implement):

- [ ] Frontmatter-only parsing (no full file content)
- [ ] Path sanitization in all output
- [ ] Input validation (directories, filenames)
- [ ] Generic error messages (no path exposure)
- [ ] Global vs. project section separation

**Additional Security** (SHOULD implement):

- [ ] Privacy markers support (`privacy: private`)
- [ ] Size limits on frontmatter extraction
- [ ] Credential detection in frontmatter (warn only)
- [ ] Symlink boundary validation
- [ ] Verbose mode warnings (output not for sharing)

**Testing & Validation** (MUST implement):

- [ ] Security test suite (malicious input, path traversal, injection)
- [ ] Path sanitization tests (all path variations)
- [ ] Error message sanitization tests
- [ ] Pre-commit security validation hook
- [ ] Integration tests with existing scripts

**Documentation** (SHOULD implement):

- [ ] Security considerations in script headers
- [ ] Usage warnings (`--help` mentions privacy)
- [ ] Developer guide for maintaining security controls
- [ ] Incident response (what to do if vulnerability found)

## References

**Existing Security Patterns**:

- `/Users/rob/Develop/oakensoul/claude-personal-assistant/scripts/validate-templates.sh`
- `/Users/rob/Develop/oakensoul/claude-personal-assistant/lib/installer-common/validation.sh`
- `/Users/rob/Develop/oakensoul/claude-personal-assistant/lib/installer-common/logging.sh`

**Related Analysis**:

- `.github/issues/in-progress/issue-54/analysis/product/privacy-security-auditor-analysis.md` (product requirements)
- `.github/issues/in-progress/issue-54/prd.md` (privacy/security section)

**Security Standards**:

- OWASP Shell Injection Prevention Cheat Sheet
- NIST SP 800-53 Input Validation (SI-10)
- CWE-22 (Path Traversal), CWE-78 (Command Injection), CWE-200 (Information Exposure)

---

**Analysis Complete**: Technical security implementation approach defined with clear patterns, validation requirements, and testing strategy. Primary technical risks are path traversal and information disclosure, both mitigable with established security controls. Estimated complexity is MEDIUM (M) due to comprehensive testing requirements and multiple security controls, but leveraging existing patterns reduces implementation effort.

**Next Steps**:

1. Create centralized path sanitization utility in `lib/installer-common/validation.sh`
2. Implement frontmatter-only parsing with size limits
3. Add security test suite for all attack vectors
4. Create pre-commit security validation hook
5. Document security considerations in script headers
