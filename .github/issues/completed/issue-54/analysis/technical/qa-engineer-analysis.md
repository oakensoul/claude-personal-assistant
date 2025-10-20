---
title: "QA Engineer Analysis - Discoverability Commands"
issue: 54
analyst: qa-engineer
created: 2025-10-20
status: draft
---

# QA Engineer Analysis: Discoverability Commands

## 1. Implementation Approach

### Testing Strategy

**Multi-Layer Testing Architecture**:

- **Unit Tests**: Individual functions (frontmatter parsing, path sanitization, deduplication)
- **Integration Tests**: Full command execution across two-tier discovery (`~/.claude/` + `./.claude/`)
- **Cross-Platform Tests**: Docker-based validation (Ubuntu 22.04, 20.04, Debian 12)
- **End-to-End Tests**: Complete user workflows from command invocation to output validation

**Test-First Development Recommended**:

- Create test fixtures BEFORE implementing CLI scripts
- Establish expected output formats early
- Define pass/fail criteria upfront

### Test Coverage Requirements

**Critical Paths (100% coverage required)**:

- Frontmatter parsing with malformed YAML
- Path sanitization (absolute → variable substitution)
- Two-tier scanning and deduplication
- Category filtering logic
- Error handling (missing files, permission errors, symlink loops)

**Important Paths (90%+ coverage)**:

- Output formatting and colorization
- Global vs. project section separation
- Optional argument handling (`--category`)
- Performance with large catalogs (177 skills)

**Nice-to-Have (70%+ coverage)**:

- Edge case handling (unicode names, special characters)
- Verbose/debug output modes
- Future JSON output format

### Validation Approach

**Static Validation**:

- ShellCheck compliance (zero warnings)
- YAML frontmatter schema validation
- Path sanitization pattern validation
- Pre-commit hook integration

**Runtime Validation**:

- Automated test execution in Docker environments
- Performance benchmarking (<500ms for agents/commands, <1s for skills)
- Memory profiling for large catalogs
- Output format validation (table structure, color codes)

**Manual Validation**:

- Usability testing (new user can discover in <30s)
- Screen reader testing (logical reading order)
- Visual inspection of output formatting

## 2. Technical Concerns

### Edge Cases to Test

**Filesystem Edge Cases**:

- Empty directories (`~/.claude/agents/` exists but no agents)
- Missing directories (`./.claude/` doesn't exist in non-projects)
- Symlink loops (dev mode with circular references)
- Permission-denied directories (unreadable agent folders)
- Unicode filenames (emoji in agent names)
- Special characters in paths (spaces, quotes, ampersands)
- Very long paths (>255 characters)
- Case-sensitive vs. case-insensitive filesystems

**Frontmatter Edge Cases**:

- Missing frontmatter delimiters (`---`)
- Malformed YAML (invalid syntax, unclosed quotes)
- Missing required fields (`name`, `description`)
- Duplicate keys in YAML
- Empty values (`description: ""`)
- Multi-line descriptions with special characters
- Frontmatter with embedded code blocks
- Unicode content in frontmatter

**Two-Tier Discovery Edge Cases**:

- Same agent/command in both global and project locations
- Symlinked entries pointing to same target (dev mode)
- Different versions of same agent in global vs. project
- Project location overriding global location
- Multiple project roots (nested git repos)
- Symlink from `~/.claude/` to framework development directory

**Category Filtering Edge Cases**:

- Non-existent category name
- Case sensitivity (`--category Workflow` vs. `--category workflow`)
- Partial matches (`--category work` matching `workflow`)
- Multiple categories per command (if supported)
- Commands without category field (legacy support)

**Path Sanitization Edge Cases**:

- Absolute paths in various formats (`/Users/rob/`, `/home/rob/`, `C:\Users\rob\`)
- Relative paths that shouldn't be sanitized (`./scripts/`)
- Environment variables in paths (`$HOME/.claude/`)
- Tilde expansion (`~/.claude/`)
- Mixed path separators (Windows backslashes)
- Symlinked home directories
- Paths containing variables that look like absolute paths

### Error Scenarios

**Filesystem Errors**:

- Permission denied reading agent/command files
- Broken symlinks in dev mode
- File deleted during scanning
- Disk full when creating output
- Network-mounted home directory timeout

**Parsing Errors**:

- Invalid YAML syntax in frontmatter
- Missing closing frontmatter delimiter
- Corrupted files (binary data instead of text)
- Encoding issues (non-UTF-8 files)
- Files larger than expected (DoS prevention)

**User Input Errors**:

- Invalid command-line arguments
- Conflicting flags (`--category` with multiple values)
- Typos in category names
- Non-existent environment variables in output

**Integration Errors**:

- Claude Code agent manager unavailable
- Git repository detection fails
- Home directory not set (`$HOME` undefined)
- `CLAUDE_CONFIG_DIR` not set or invalid

### Cross-Platform Testing Needs

**macOS-Specific**:

- BSD `stat` command differences
- Case-insensitive filesystem (HFS+/APFS)
- Tilde expansion in zsh vs. bash
- PATH differences affecting command availability
- Gatekeeper/quarantine attributes on scripts

**Linux-Specific**:

- GNU `stat` command format
- Case-sensitive filesystem (ext4)
- SELinux/AppArmor permission contexts
- Different distributions (Ubuntu, Debian, Fedora, Arch)
- Bash version differences (4.x vs. 5.x)

**Shell Compatibility**:

- bash 3.2 (macOS default)
- bash 4.x+ (modern Linux)
- zsh (macOS default since Catalina)
- sh (POSIX compliance for minimal environments)

**Docker Environments** (use existing test-install.sh pattern):

- ubuntu-22.04
- ubuntu-20.04
- debian-12
- ubuntu-minimal (missing dependencies)

### Performance Testing Requirements

**Response Time Targets**:

- `/agent-list`: <500ms (scanning ~15 agents)
- `/command-list`: <500ms (scanning ~32 commands)
- `/skill-list`: <1s (scanning 177 skills across 28 categories)
- Category filtering: <200ms additional overhead

**Performance Test Scenarios**:

- Cold start (no filesystem caches)
- Warm start (files cached in memory)
- Large catalogs (stress test with 1000+ mock agents)
- Slow filesystem (network-mounted home directory)
- Concurrent execution (multiple commands at once)

**Performance Bottlenecks to Monitor**:

- Recursive directory scanning depth
- Full file reads vs. frontmatter-only parsing
- Repeated stat() calls for same files
- String processing for path sanitization
- Subprocess spawning overhead

**Optimization Strategies to Test**:

- Caching parsed frontmatter (Phase 2)
- Parallel file scanning (xargs vs. sequential)
- grep/sed optimization for frontmatter extraction
- Minimizing subshell invocations

## 3. Dependencies & Integration

### Test Fixtures Needed

**Agent Test Fixtures**:

```text
fixtures/agents/
├── valid-agent/
│   └── agent-name.md (valid frontmatter)
├── missing-frontmatter/
│   └── agent.md (no frontmatter)
├── malformed-yaml/
│   └── agent.md (invalid YAML syntax)
├── missing-required-fields/
│   └── agent.md (missing 'name' or 'description')
├── unicode-content/
│   └── agent-🚀.md (emoji in filename/content)
├── special-characters/
│   └── agent-with-spaces.md
└── symlinked-agent/
    └── symlink → valid-agent/
```text

**Command Test Fixtures**:

```text
fixtures/commands/
├── workflow-category/
│   └── start-work.md (category: workflow)
├── no-category/
│   └── legacy-command.md (missing category field)
├── multiple-categories/
│   └── hybrid-command.md (if supported)
└── invalid-category/
    └── bad-command.md (category: invalid-value)
```text

**Two-Tier Test Fixtures**:

```text
fixtures/global-config/
└── .claude/
    ├── agents/
    └── commands/

fixtures/project-config/
└── project-root/
    ├── .git/
    └── .claude/
        ├── agents/
        └── commands/
```text

**Skills Test Fixtures** (Phase 2):

```text
fixtures/skills/
├── small-catalog/
│   └── 5-skills-2-categories.json
├── full-catalog/
│   └── 177-skills-28-categories.json
└── malformed/
    └── invalid-structure.json
```text

### Integration Testing Approach

**Test Hierarchy**:

1. **Component Tests** (isolated functions)
   - `test_parse_frontmatter()`
   - `test_sanitize_path()`
   - `test_deduplicate_entries()`
   - `test_filter_by_category()`

2. **Module Tests** (CLI script functions)
   - `test_list_agents_function()`
   - `test_list_commands_function()`
   - `test_output_formatting()`

3. **Integration Tests** (end-to-end)
   - `test_agent_list_command_full_execution()`
   - `test_command_list_with_category_filter()`
   - `test_two_tier_discovery_and_deduplication()`

4. **System Tests** (Docker environments)
   - `test_ubuntu_22_full_workflow()`
   - `test_macos_compatibility()` (local)
   - `test_minimal_environment_error_handling()`

**Test Execution Order**:

1. Static validation (ShellCheck, YAML lint)
2. Component/unit tests
3. Module tests
4. Integration tests (local environment)
5. Cross-platform tests (Docker)
6. Performance/load tests

**Integration Points to Test**:

- CLI script → slash command invocation
- Slash command → Claude Code agent manager
- Agent manager → skill invocation (future)
- Filesystem scanning → output formatting
- Error handling → user-facing messages

### Pre-commit Hook Impacts

**New Pre-commit Checks Required**:

- Validate command frontmatter has `category` field
- Validate category values against taxonomy enum
- Ensure new agents have required frontmatter fields
- Check for absolute paths in new template files

**Pre-commit Hook Integration**:

```yaml
# .pre-commit-config.yaml additions
- repo: local
  hooks:
     - id: validate-command-frontmatter
      name: Validate command frontmatter
      entry: scripts/validate-command-frontmatter.sh
      language: script
      files: 'templates/commands/.*\.md$'
      pass_filenames: true
```text

**Test Pre-commit Hooks**:

- Run against fixtures to verify catch issues
- Test performance (hook execution <2s)
- Verify doesn't block valid commits
- Confirm helpful error messages

## 4. Effort & Complexity

### Estimated Complexity: **M (Medium)**

**Rationale**:

- **Simple logic**: Filesystem scanning and frontmatter parsing are well-understood
- **Moderate edge cases**: Two-tier discovery, symlink handling, path sanitization add complexity
- **Existing patterns**: Can reuse test-install.sh Docker testing framework
- **Well-defined scope**: Phase 1 defers skills architecture complexity

### Complexity Breakdown

**Low Complexity (S)**:

- Basic frontmatter parsing (grep/sed patterns)
- Output formatting (echo/printf with colors)
- Help message display

**Medium Complexity (M)**:

- Two-tier discovery with deduplication
- Path sanitization logic (multiple OS formats)
- Category filtering implementation
- Error handling for filesystem edge cases
- Cross-platform shell compatibility

**High Complexity (L)** (deferred to Phase 2):

- Skills catalog integration (architecture undefined)
- Caching layer for performance optimization
- JSON output format with schema validation

### Key Effort Drivers

**High Effort**:

1. **Test fixture creation** (8-12 hours)
   - Creating realistic agent/command test fixtures
   - Two-tier directory structures
   - Edge case scenarios (malformed YAML, special characters)

2. **Cross-platform testing** (6-10 hours)
   - Docker environment setup (reuse existing framework)
   - macOS vs. Linux compatibility validation
   - Shell compatibility testing (bash 3.2, 4.x, 5.x, zsh)

3. **Edge case testing** (6-8 hours)
   - Symlink handling in dev mode
   - Permission error scenarios
   - Path sanitization validation across platforms
   - Unicode and special character handling

**Medium Effort**:

4. **Integration testing** (4-6 hours)
   - End-to-end command execution tests
   - Two-tier discovery validation
   - Output format verification

5. **Performance testing** (3-4 hours)
   - Benchmarking response times
   - Large catalog stress testing
   - Performance regression detection

**Low Effort**:

6. **Static validation** (2-3 hours)
   - ShellCheck integration
   - YAML schema validation
   - Pre-commit hook setup

**Total Estimated Testing Effort**: 29-43 hours

### Risk Areas

**High Risk**:

- **Symlink handling in dev mode**: Complex deduplication logic, edge cases with circular refs
- **Path sanitization**: Must work across macOS, Linux, Windows paths; easy to miss edge cases
- **Frontmatter parsing fragility**: YAML parsing with grep/sed can break on unexpected input

**Medium Risk**:

- **Two-tier discovery complexity**: Global vs. project precedence rules, deduplication strategy
- **Performance with large catalogs**: 177 skills could cause slowdowns on slow filesystems
- **Cross-platform compatibility**: Bash version differences, command availability (stat, readlink)

**Low Risk**:

- **Output formatting**: Well-understood terminal color codes, straightforward logic
- **Category filtering**: Simple string matching, low complexity
- **Error messaging**: Standard bash error handling patterns

**Risk Mitigation**:

- **Early test fixture creation**: Identify parsing edge cases before implementation
- **Incremental implementation**: Start with `/agent-list`, validate approach, then `/command-list`
- **Docker testing from day 1**: Catch cross-platform issues early
- **Performance benchmarking**: Establish baseline, monitor for regressions

## 5. Questions & Clarifications

### Critical Questions

#### Q1: Symlink deduplication strategy

- How should we deduplicate when both symlink and target are discovered?
- Show only target location with note "(symlinked)"?
- Show both with indication of relationship?
- **Testing Impact**: Need clear expected behavior for test assertions

#### Q2: Global vs. Project precedence

- When same agent exists in both `~/.claude/` and `./.claude/`, which takes precedence?
- Show both separately under "Global" and "Project" sections?
- Show project version only with note about override?
- **Testing Impact**: Affects integration test expectations

#### Q3: Category taxonomy validation

- Should scripts validate category values against enum during scan?
- Report warnings for invalid categories or silently ignore?
- **Testing Impact**: Need to test validation error messages

#### Q4: Performance thresholds

- What is acceptable response time on slow filesystems (network mounts)?
- Should commands have built-in timeout (e.g., 5s max)?
- **Testing Impact**: Need realistic performance baselines for pass/fail

### Important Questions

#### Q5: Error message verbosity

- How detailed should error messages be without exposing filesystem structure?
- Example: "Permission denied reading agent file" vs. "Permission denied reading ~/.claude/agents/private-agent/agent.md"?
- **Testing Impact**: Validate privacy in error messages

#### Q6: Output format stability

- Should output format be considered stable for scripting/automation?
- Guarantee backward compatibility or allow breaking changes?
- **Testing Impact**: Determines if output format is integration test requirement

#### Q7: Colorization handling

- Should colors be automatically disabled in non-TTY contexts (pipes)?
- Provide `--no-color` flag?
- **Testing Impact**: Test both colorized and plain text output modes

#### Q8: Large catalog handling

- Should `/skill-list` (177 skills) use pagination?
- Implement pager integration (less/more)?
- **Testing Impact**: Test with both small and large catalogs

### Nice-to-Have Questions

#### Q9: Test automation integration

- Should tests be added to GitHub Actions CI?
- Run on pull requests or only on main branch?
- **Testing Impact**: CI integration effort estimate

#### Q10: Version tracking

- Should test fixtures include version field for future compatibility testing?
- **Testing Impact**: Future-proofing test data structures

#### Q11: Performance regression tracking

- Should performance benchmarks be stored and tracked over time?
- Fail tests if performance degrades beyond threshold (e.g., 20% slower)?
- **Testing Impact**: Need baseline performance database

### Areas Needing Investigation

**Investigation 1: Skills Catalog Architecture** (CRITICAL - Phase 2 blocker)

- Where are skills stored? (templates/skills/ vs. external catalog?)
- What is file format? (YAML, JSON, Markdown?)
- How do skills integrate with Claude Code's built-in skills?
- **Testing Impact**: Cannot design `/skill-list` tests until architecture clarified

#### Investigation 2: Existing Test Patterns

- Review test-install.sh for Docker testing patterns to reuse
- Check if there are existing frontmatter parsing utilities
- Identify shared test utilities in .github/testing/
- **Testing Impact**: Determines how much infrastructure exists vs. needs creation

#### Investigation 3: User Environment Variability

- Survey macOS versions in use (Monterey, Ventura, Sonoma)
- Identify Linux distributions users deploy to
- Determine bash/zsh version distribution
- **Testing Impact**: Prioritize cross-platform test coverage

---

## Test Implementation Recommendations

### Phase 1 Testing Priorities

**Week 1**: Test Infrastructure

1. Create test fixture directory structure
2. Implement Docker test framework extensions (reuse test-install.sh pattern)
3. Write frontmatter parsing validation tests
4. Set up pre-commit hooks for command metadata validation

**Week 2**: Component Testing

1. Path sanitization unit tests (all OS formats)
2. Two-tier discovery integration tests
3. Deduplication logic tests (symlinks, duplicates)
4. Category filtering tests

**Week 3**: End-to-End Testing

1. `/agent-list` full execution tests (all edge cases)
2. `/command-list` with filtering tests
3. Cross-platform Docker validation
4. Performance benchmarking

**Week 4**: Refinement

1. Error scenario testing (permissions, missing files)
2. Usability testing (new user discoverability validation)
3. Documentation and test maintenance guides
4. CI integration

### Success Criteria

**MVP Acceptance (Phase 1)**:

- [ ] All component tests pass on macOS and Linux
- [ ] Cross-platform Docker tests pass (ubuntu-22, ubuntu-20, debian-12)
- [ ] Response times meet targets (<500ms agents/commands)
- [ ] Zero absolute paths exposed in output
- [ ] Frontmatter parsing handles malformed input gracefully
- [ ] Two-tier discovery correctly deduplicates symlinked entries
- [ ] Category filtering works as expected
- [ ] Pre-commit hooks validate command frontmatter
- [ ] New user can discover agents in <30 seconds (usability test)

**Phase 2 Requirements** (post-MVP):

- [ ] Skills architecture documented with test approach
- [ ] Performance optimization with caching (if needed)
- [ ] JSON output format with schema validation
- [ ] Automated performance regression tracking

### Testing Anti-Patterns to Avoid

**Don't**:

- Mock filesystem when real file testing is needed (use fixtures instead)
- Test implementation details instead of behavior (e.g., grep pattern vs. parsing result)
- Hard-code expected output strings that include terminal color codes (test structure, not exact bytes)
- Skip cross-platform testing until "later" (catch compatibility issues early)
- Create fixtures with actual user data or paths (always use generic test data)
- Test only happy path (edge cases find the bugs)

**Do**:

- Use realistic test fixtures that represent actual agent/command structures
- Test both success and failure scenarios
- Validate privacy in error messages (no path exposure)
- Test performance with realistic data sizes
- Document test assumptions and expected behaviors
- Keep tests maintainable (clear naming, modular structure)

---

**Estimated Total Testing Effort**: 29-43 hours (3.6-5.4 days)

**Recommended Testing Approach**: Incremental with early Docker validation

**Key Risk Mitigation**: Create test fixtures before implementation to identify edge cases early
