---
title: "QA Engineer Analysis - Modular Installer Refactoring"
issue: 53
analyst: "qa-engineer"
created: "2025-10-18"
version: "1.0"
status: "draft"
---

# QA Engineer Analysis: Modular Installer Refactoring

**Issue**: #53 - Modular installer with deprecation support
**Critical Focus**: Data loss prevention, idempotency, cross-platform compatibility

---

## 1. Test Coverage Requirements

### Core Installation Scenarios

**Fresh Installation (Normal Mode)**:

- Clean system with no existing `~/.aida/` or `~/.claude/`
- All directories created with correct permissions (755 dirs, 644 files)
- Templates copied to `.aida/` namespace subdirectories
- Variable substitution completed correctly
- `~/CLAUDE.md` generated with user preferences
- No errors in installation log
- Installation completes within expected time (<30 seconds)

**Fresh Installation (Dev Mode)**:

- `~/.aida/` symlinked to repository directory
- Templates symlinked to `.aida/` subdirectories (not copied)
- Symlink targets are correct and accessible
- No variable substitution in symlinked templates (runtime resolution)
- Can modify template in repo and see changes immediately

**Upgrade Over Existing Installation**:

- User-created custom commands preserved in `~/.claude/commands/`
- User-created custom agents preserved in `~/.claude/agents/`
- User-created custom skills preserved in `~/.claude/skills/`
- `.aida/` namespace directories completely replaced (expected)
- No data loss outside `.aida/` namespace
- Backup created with timestamp
- Custom `~/CLAUDE.md` preserved or upgraded gracefully

**Installation with Deprecated Templates**:

- `--with-deprecated` flag installs to `.aida-deprecated/` subdirectories
- Default installation (no flag) excludes deprecated templates
- Both canonical and deprecated can coexist without conflicts
- Deprecated template frontmatter correctly warns users
- Correct namespace separation (`.aida/` vs `.aida-deprecated/`)

### Variable Substitution

**Install-Time Variables** (must be substituted):

- `{{AIDA_HOME}}` → Actual `~/.aida/` path
- `{{CLAUDE_CONFIG_DIR}}` → Actual `~/.claude/` path
- `{{HOME}}` → User's home directory
- No unresolved `{{VAR}}` patterns remain
- Paths are absolute (not relative)
- Paths work on macOS and Linux

**Runtime Variables** (must be preserved):

- `${PROJECT_ROOT}` preserved for runtime resolution
- `${GIT_ROOT}` preserved for runtime resolution
- `$(date)` preserved for runtime resolution
- Other bash expressions untouched

**Edge Cases**:

- Variables in frontmatter YAML
- Variables in markdown code blocks
- Variables in quoted strings
- Variables with special characters in paths
- Paths with spaces (e.g., `/Users/John Doe/.aida/`)

### Modular Library Integration

**Library Sourcing**:

- All `lib/installer-common/*.sh` modules source successfully
- No circular dependencies between modules
- Functions can be called in isolation (unit testable)
- No assumptions about `$PWD` or repo location
- Works when sourced from dotfiles repo

**Function Parameter Handling**:

- Functions accept parameters (not just globals)
- Optional parameters have sensible defaults
- Invalid parameters fail gracefully with error messages
- Functions return correct exit codes (0 success, 1+ failure)

**Cross-Script Reusability**:

- Libraries can be sourced from `~/.aida/lib/installer-common/`
- Functions work when called from external scripts
- No hardcoded paths assuming repo root
- Version checking function works correctly

### Deprecation System

**Frontmatter Parsing**:

- `deprecated: true` correctly detected
- `deprecated_in` version extracted accurately
- `remove_in` version compared correctly
- `canonical` field points to correct replacement
- Malformed frontmatter handled gracefully

**Version Comparison**:

- Semantic version parsing (MAJOR.MINOR.PATCH)
- Correctly compares: 0.1.0 < 0.2.0 < 0.10.0
- Edge cases: 0.2.0-alpha < 0.2.0
- Pre-release versions handled correctly
- Invalid version strings fail gracefully

**Cleanup Script**:

- Reads current version from `VERSION` file
- Scans all `templates/*-deprecated/` folders
- Identifies items where `current_version >= remove_in`
- Removes deprecated items from repository
- Does NOT affect installed user directories
- Dry-run mode shows what would be removed

### Negative Test Cases

**Invalid User Input**:

- Assistant name too short (<3 chars) - rejected
- Assistant name too long (>20 chars) - rejected
- Assistant name with spaces - rejected
- Assistant name with uppercase - rejected
- Assistant name with special chars - rejected
- Invalid personality choice (not 1-5) - rejected

**Missing Dependencies**:

- Installation fails if `git` not found
- Installation fails if `rsync` not found
- Clear error messages with recovery guidance
- Exit code non-zero

**Permission Errors**:

- Read-only home directory - fails gracefully
- Cannot create `~/.aida/` - error message explains issue
- Cannot write `~/CLAUDE.md` - error message helpful
- Partial installation doesn't leave broken state

**Corrupted State**:

- Existing `~/.aida/` is a file (not directory/symlink)
- Existing `~/.aida/` symlink is broken
- Existing `~/.claude/` has wrong permissions
- Existing templates have corrupted frontmatter

**Resource Constraints**:

- Insufficient disk space - detected and fails cleanly
- Very slow I/O (network home directories) - timeout handling
- Concurrent installations - file locking or detection

---

## 2. Quality Validation Strategy

### User Content Preservation

**Detection Method**:

- Create test fixtures with custom commands/agents/skills
- Run installer upgrade over fixtures
- Verify all custom content still exists after upgrade
- Verify custom content readable and executable
- Verify custom content permissions unchanged

**Test Fixtures**:

```bash
# Before installation
~/.claude/
├── commands/
│   ├── my-custom-command/
│   │   └── README.md          # User-created
│   └── .aida/                 # AIDA-managed (will be replaced)
│       └── issue-create/
├── agents/
│   └── my-custom-agent/       # User-created
```

**Validation**:

```bash
# After installation
test -f ~/.claude/commands/my-custom-command/README.md || fail
grep -q "my custom content" ~/.claude/commands/my-custom-command/README.md || fail
```

### Variable Substitution Validation

**Automated Checks**:

```bash
# Scan installed templates for unresolved install-time variables
grep -r '{{AIDA_HOME}}' ~/.claude/commands/.aida/ && fail
grep -r '{{CLAUDE_CONFIG_DIR}}' ~/.claude/commands/.aida/ && fail
grep -r '{{HOME}}' ~/.claude/commands/.aida/ && fail

# Verify runtime variables preserved
grep -q '${PROJECT_ROOT}' ~/.claude/commands/.aida/some-command/README.md || fail
```

**Path Resolution**:

- Substituted paths are absolute (start with `/`)
- Paths exist on filesystem
- Paths are accessible (readable)
- Symlinks resolve correctly

**Special Character Handling**:

- Test paths with spaces: `/Users/John Doe/.aida/`
- Test paths with special chars: `/home/user&name/.aida/`
- Verify quoting in generated scripts

### Idempotency Validation

**Repeat Installation Test**:

```bash
# Install once
./install.sh < input.txt
snapshot_before=$(ls -lR ~/.claude/)

# Install again (same inputs)
./install.sh < input.txt
snapshot_after=$(ls -lR ~/.claude/)

# Compare snapshots (should be identical for user content)
diff <(echo "$snapshot_before") <(echo "$snapshot_after") || fail
```

**Verification**:

- User content unchanged after re-installation
- `.aida/` namespace updated correctly
- No duplicate files created
- No permission changes on user content
- Exit code is 0 (success)

### Symlink Integrity (Dev Mode)

**Symlink Validation**:

```bash
# Verify ~/.aida/ is symlink to repo
test -L ~/.aida/ || fail
readlink ~/.aida/ | grep -q "$REPO_DIR" || fail

# Verify template symlinks
test -L ~/.claude/commands/.aida || fail
readlink ~/.claude/commands/.aida | grep -q "templates/commands" || fail

# Verify symlinks are accessible
test -r ~/.claude/commands/.aida/issue-create/README.md || fail
```

**Broken Symlink Detection**:

- Test recovery if symlink target deleted
- Test recovery if symlink target moved
- Installer detects and repairs broken symlinks

---

## 3. Regression Testing

### Existing Functionality (Must Not Break)

**Current Features to Preserve**:

- ✅ `./install.sh --help` shows usage information
- ✅ `./install.sh --dev` enables development mode
- ✅ User prompts for assistant name and personality
- ✅ Input validation (name length, lowercase, no spaces)
- ✅ Backup creation with timestamp
- ✅ `~/CLAUDE.md` generation with frontmatter
- ✅ Installation summary display
- ✅ Dependency validation (git, rsync, etc.)
- ✅ Cross-platform compatibility (macOS bash 3.2)

**Behavioral Consistency**:

- Exit codes unchanged (0 = success, 1+ = failure)
- Output format consistent (colors, symbols, messages)
- Backup directory naming convention unchanged
- Installation locations unchanged (`~/.aida/`, `~/.claude/`)

**Performance Benchmarks**:

- Fresh installation completes in <30 seconds (current baseline)
- Dev mode installation faster than normal mode (symlinks)
- Upgrade installation not significantly slower than fresh install

### Backward Compatibility Scenarios

**Dotfiles Integration**:

- Dotfiles repo can source `~/.aida/lib/installer-common/*`
- Functions called from dotfiles work identically
- Version checking prevents incompatibilities
- Graceful degradation if AIDA not installed

**Template Format**:

- Existing templates continue to work
- New frontmatter fields are optional
- Missing deprecation fields don't break installation
- Old-style file-based templates migrate cleanly

**Upgrade Paths**:

- v0.1.x → v0.2.x upgrade preserves user data
- Old `.aida/` installation cleanly replaced
- Old command format (if changed) still readable
- Migration guidance provided for breaking changes

### Test Data Sets

**Fresh Install**:

- No existing `~/.aida/` or `~/.claude/`
- Clean user home directory

**Upgrade from v0.1.x**:

- Existing `~/.aida/` directory (not symlink)
- Existing `~/.claude/` with old structure
- User-created custom commands

**Upgrade with Custom Content**:

- Custom commands in `~/.claude/commands/`
- Custom agents in `~/.claude/agents/`
- Modified templates in `.aida/` (should be nuked safely)

**Corrupted Installation**:

- Broken symlinks
- Wrong file permissions
- Missing directories
- Partially completed installations

---

## 4. Cross-Platform Testing

### Platform-Specific Test Cases

**macOS (Bash 3.2)**:

- Bash 3.2 compatibility (no associative arrays)
- BSD `stat` command (different from GNU)
- BSD `readlink` without `-f` flag
- BSD `sed` in-place editing quirks
- Case-insensitive filesystem by default
- Symlink creation and resolution

**Ubuntu/Debian (Bash 5.x)**:

- GNU `stat` command format
- GNU `readlink -f` available
- GNU `sed` behavior
- Case-sensitive filesystem
- Standard Linux file permissions

**Windows WSL**:

- Windows filesystem paths (`/mnt/c/Users/...`)
- CRLF vs LF line endings
- Permission emulation in WSL
- Symlink support in WSL (may require admin)
- Case sensitivity configurable

**Windows PowerShell** (if supported):

- PowerShell script execution policy
- Path separators (backslash vs forward slash)
- Environment variable syntax (`$env:HOME`)
- Symlink creation (requires admin or developer mode)
- Command availability (no rsync by default)

### Shell Compatibility

**Bash 3.2 (macOS Default)**:

- No associative arrays (use indexed arrays)
- No `readarray` / `mapfile` (use while loop)
- Older `declare` syntax
- Parameter expansion quirks
- Process substitution availability

**Bash 5.x (Linux)**:

- Modern features available
- Better error messages
- Improved array handling

**Zsh (macOS Default Since Catalina)**:

- Array indexing starts at 1 (not 0)
- Different `setopt` behavior
- Compatibility mode when running bash scripts
- Test in `bash` explicitly (shebang: `#!/usr/bin/env bash`)

**POSIX sh (Minimal)**:

- No arrays
- Limited string manipulation
- No `local` keyword (some versions)
- Minimal built-ins

### Platform-Specific Edge Cases

**macOS**:

- User home on APFS (case-insensitive but preserving)
- Network home directories (slow I/O)
- FileVault encrypted homes
- Symlinks across volumes
- BSD command quirks

**Linux**:

- Network home directories (NFS, CIFS)
- Various filesystems (ext4, btrfs, xfs)
- SELinux contexts
- AppArmor policies
- Symlinks across mount points

**Windows WSL**:

- Windows filesystem vs WSL filesystem
- Permission mapping WSL↔Windows
- Symlink behavior between filesystems
- Line ending conversion
- Command availability

### Windows WSL vs PowerShell Considerations

**WSL (Recommended Path)**:

- Native bash support
- Standard Unix tools available
- Symlinks work reliably (in WSL filesystem)
- Performance better than PowerShell for file ops
- `~/.aida/` and `~/.claude/` in WSL home

**PowerShell (Alternative)**:

- Would require PowerShell port of install script
- Limited Unix tool availability
- Different path conventions
- Symlink creation restricted (admin/dev mode)
- Significantly more effort to support

**Recommendation**: Target WSL only for Windows support (MVP). PowerShell support deferred to future release.

---

## 5. User Acceptance Criteria

### Successful Installation Defined

**Functional Success**:

- ✅ All directories created with correct structure
- ✅ All templates installed to correct locations
- ✅ Variables substituted correctly
- ✅ User content preserved (if upgrading)
- ✅ No errors in installation log
- ✅ Exit code 0
- ✅ Installation summary displayed

**User Experience Success**:

- ✅ Clear progress indicators throughout
- ✅ Helpful prompts for user input
- ✅ Confirmation before destructive operations
- ✅ Comprehensive installation summary
- ✅ Next steps guidance provided
- ✅ Installation completes in reasonable time (<30s fresh, <60s upgrade)

**Technical Success**:

- ✅ File permissions correct (755 dirs, 644 files)
- ✅ Symlinks point to correct targets (dev mode)
- ✅ Templates readable and executable
- ✅ Frontmatter valid YAML
- ✅ No security issues (permissions, path traversal)

### Data Safety Measurement

**Zero Data Loss**:

- User custom commands: 100% preserved
- User custom agents: 100% preserved
- User custom skills: 100% preserved
- User's `~/CLAUDE.md`: Preserved or upgraded gracefully
- User's `.claude/memory/`: 100% preserved
- User's `.claude/knowledge/`: 100% preserved

**Namespace Isolation Validation**:

- `.aida/` namespace completely replaced: ✅ Expected
- `.aida-deprecated/` namespace replaced: ✅ Expected
- User content outside namespace: ✅ Preserved

**Recovery Capability**:

- Backups created before destructive operations
- Backup directory naming convention: `.backup.YYYYMMDD_HHMMSS`
- Restore instructions provided if failure occurs
- Partial installations don't leave unusable state

### Performance Benchmarks

**Installation Time**:

- Fresh install (normal mode): <30 seconds
- Fresh install (dev mode): <10 seconds (symlinks)
- Upgrade install (normal mode): <60 seconds
- Upgrade install (dev mode): <15 seconds

**Resource Usage**:

- Disk space (normal mode): ~5MB (templates copied)
- Disk space (dev mode): <100KB (symlinks only)
- Memory usage: <50MB peak
- No resource leaks (file descriptors, temp files)

**Responsiveness**:

- User prompts appear within 1 second
- Progress indicators update every 2-5 seconds
- Long operations (>5s) show spinner or progress
- Installation doesn't hang or freeze

---

## 6. Test Automation Gaps

### What CAN Be Automated

**Docker Container Tests**:

- ✅ Fresh installation on clean Ubuntu/Debian
- ✅ Upgrade installation with test fixtures
- ✅ Dev mode symlink creation
- ✅ Variable substitution validation
- ✅ Dependency validation (missing tools)
- ✅ File permission verification
- ✅ User content preservation
- ✅ Exit code validation

**GitHub Actions CI/CD**:

- ✅ Matrix testing (Ubuntu × macOS × platforms)
- ✅ All installation modes (normal, dev, deprecated)
- ✅ Regression tests on every PR
- ✅ Performance benchmarking
- ✅ ShellCheck linting
- ✅ YAML frontmatter validation

**Unit Tests (for library functions)**:

- ✅ Version comparison logic
- ✅ Frontmatter parsing
- ✅ Variable substitution
- ✅ Path handling
- ✅ Input validation

### What CANNOT Be Automated (Manual Testing Required)

**Interactive User Experience**:

- ❌ User prompt clarity and helpfulness
- ❌ Error message understandability
- ❌ Recovery guidance effectiveness
- ❌ Installation summary readability
- ❌ Progress indicator smoothness

**Platform-Specific Edge Cases**:

- ❌ Network home directories (NFS, CIFS)
- ❌ Encrypted home directories (FileVault, LUKS)
- ❌ Non-standard shells (fish, tcsh)
- ❌ Unusual filesystem configurations
- ❌ Corporate VPN/proxy environments

**Real-World Scenarios**:

- ❌ User workflow interruptions (Ctrl+C during install)
- ❌ System crashes mid-installation
- ❌ Disk full during installation
- ❌ Permission changes during installation
- ❌ Concurrent modifications by other processes

**Accessibility**:

- ❌ Screen reader compatibility
- ❌ Color-blind friendly output
- ❌ Terminal emulator compatibility (iTerm, Windows Terminal, etc.)

### Manual Testing Requirements

**Before Each Release**:

- [ ] Fresh install on macOS (latest)
- [ ] Fresh install on macOS (previous major version)
- [ ] Fresh install on Ubuntu LTS (current)
- [ ] Fresh install on Debian stable
- [ ] Upgrade install over v0.1.x (macOS)
- [ ] Upgrade install over v0.1.x (Linux)
- [ ] Dev mode on macOS
- [ ] Dev mode on Linux
- [ ] With deprecated templates flag
- [ ] Error recovery (simulate failures)

**Platform-Specific**:

- [ ] Test on actual macOS (not Docker)
- [ ] Test on actual Ubuntu (not Docker)
- [ ] Test on Windows WSL (if supported)
- [ ] Test with bash 3.2 explicitly
- [ ] Test with zsh (macOS default)

**User Acceptance Testing**:

- [ ] Non-technical user can complete installation
- [ ] Error messages are helpful to novices
- [ ] Recovery guidance is actionable
- [ ] Documentation is accurate

### User Testing Needed

**Beta Testing Phase**:

- External users install on diverse environments
- Collect feedback on user experience
- Identify unexpected edge cases
- Validate documentation accuracy

**User Personas**:

- **Novice**: First time installing AIDA
- **Upgrader**: Has existing v0.1.x installation
- **Developer**: Uses dev mode for live editing
- **Power User**: Customizes templates extensively

---

## 7. Quality Risks

### Highest Risk Areas

**CRITICAL Risk: User Data Loss** 🔴

- **Scenario**: Installer deletes custom commands/agents/skills
- **Impact**: Loss of user work, trust, reputation damage
- **Probability**: High (if namespace isolation fails)
- **Mitigation**:
  - Namespace isolation (`.aida/` subdirectories)
  - Pre-flight validation (detect user content)
  - Confirmation prompts before overwrites
  - Comprehensive automated tests with fixtures
  - Manual QA testing before every release

**HIGH Risk: Cross-Platform Compatibility** 🟠

- **Scenario**: Works on Linux, breaks on macOS (or vice versa)
- **Impact**: Installation fails for half of users
- **Probability**: Medium (bash 3.2 quirks, BSD commands)
- **Mitigation**:
  - Test on actual macOS and Linux (not just Docker)
  - GitHub Actions matrix (Ubuntu + macOS runners)
  - Bash 3.2 linting and validation
  - Platform-specific test cases
  - Manual testing on both platforms

**HIGH Risk: Variable Substitution Bugs** 🟠

- **Scenario**: Paths not substituted, broken templates
- **Impact**: Commands reference wrong paths, don't work
- **Probability**: Medium (complex regex, edge cases)
- **Mitigation**:
  - Automated validation (grep for unresolved variables)
  - Test with paths containing spaces/special chars
  - Comprehensive test fixtures
  - Clear distinction (install-time vs runtime vars)

**MEDIUM Risk: Symlink Issues (Dev Mode)** 🟡

- **Scenario**: Broken symlinks, permission issues, wrong targets
- **Impact**: Dev mode doesn't work, confusing errors
- **Probability**: Medium (especially on Windows WSL)
- **Mitigation**:
  - Symlink validation after creation
  - Broken symlink detection and repair
  - Clear error messages if symlinks fail
  - Test on WSL specifically

**MEDIUM Risk: Dotfiles Integration** 🟡

- **Scenario**: Libraries don't work when sourced from dotfiles repo
- **Impact**: Dotfiles integration broken, code duplication needed
- **Probability**: Medium (assumptions about $PWD, globals)
- **Mitigation**:
  - Design libraries for external sourcing
  - Accept parameters instead of globals
  - Test sourcing from different directory
  - Version checking for compatibility

**LOW Risk: Performance Degradation** 🟢

- **Scenario**: Modular architecture slower than monolith
- **Impact**: Installation takes longer, user frustration
- **Probability**: Low (file I/O dominates, not function calls)
- **Mitigation**:
  - Performance benchmarking in tests
  - Optimize file operations (rsync, symlinks)
  - Avoid unnecessary disk I/O

### Mitigation Strategies

**For User Data Loss**:

1. **Namespace isolation** - All AIDA content in `.aida/` subdirectories
2. **Automated testing** - Test fixtures with custom content
3. **Manual QA** - Visual inspection of preserved content
4. **User confirmation** - Prompt before destructive operations
5. **Backup system** - Create timestamped backups
6. **Documentation** - Warn users not to modify `.aida/` folders

**For Cross-Platform Issues**:

1. **CI/CD matrix** - Test Ubuntu + macOS on every PR
2. **Platform-specific tests** - BSD vs GNU command handling
3. **Bash 3.2 compatibility** - Lint and test on macOS
4. **Manual testing** - Actual macOS/Linux before release
5. **Platform detection** - Adapt behavior to OS

**For Variable Substitution**:

1. **Automated validation** - Scan for unresolved variables
2. **Test coverage** - Edge cases (spaces, special chars)
3. **Clear separation** - Install-time `{{VAR}}` vs runtime `${VAR}`
4. **Validation feedback** - Show substituted paths in summary

**For Symlink Issues**:

1. **Symlink validation** - Verify targets exist and accessible
2. **Broken symlink detection** - Check with `test -L` and `readlink`
3. **Repair capability** - Recreate broken symlinks
4. **Clear errors** - Explain symlink failures with recovery steps

**For Dotfiles Integration**:

1. **Parameter-based functions** - No globals or $PWD assumptions
2. **Cross-script testing** - Source from different directory
3. **Version checking** - Validate library compatibility
4. **Documentation** - API contract for library functions

---

## 8. Effort Estimate

### Test Development Complexity

**MODERATE to HIGH Complexity** (6-8 hours test development)

**Breakdown**:

- **Docker test environment setup**: 2-3 hours
  - Dockerfile creation (Ubuntu/Debian)
  - Makefile with test targets
  - Test fixture creation (custom commands/agents/skills)

- **Automated test scripts**: 2-3 hours
  - Fresh install test
  - Upgrade install test
  - Dev mode test
  - Deprecated templates test
  - Variable substitution validation

- **GitHub Actions CI/CD**: 1-2 hours
  - Workflow YAML creation
  - Matrix configuration (platforms × modes)
  - Test result reporting

- **Manual test procedures**: 1 hour
  - Document manual test scenarios
  - Create test checklists
  - User acceptance test plan

### Key Effort Drivers

**High Effort**:

1. **Cross-platform testing** - Need actual macOS and Linux environments
2. **User content preservation** - Complex test fixtures and validation
3. **Variable substitution validation** - Many edge cases to cover
4. **Symlink validation** - Platform-specific behaviors

**Medium Effort**:

5. **Dotfiles integration testing** - External sourcing scenarios
6. **Deprecation system testing** - Version comparison, cleanup script
7. **Performance benchmarking** - Timing measurements, baselines

**Low Effort**:

8. **Basic functionality regression** - Existing tests can be adapted
9. **Input validation** - Straightforward unit tests
10. **Dependency validation** - Simple negative tests

### Testing Timeline

**Phase 1: Foundation (Week 1)**:

- [ ] Docker environment setup
- [ ] Basic automated tests (fresh install)
- [ ] GitHub Actions workflow skeleton

**Phase 2: Core Tests (Week 2)**:

- [ ] Upgrade install tests with fixtures
- [ ] Variable substitution validation
- [ ] User content preservation tests
- [ ] Dev mode symlink tests

**Phase 3: Advanced Tests (Week 3)**:

- [ ] Deprecation system tests
- [ ] Dotfiles integration tests
- [ ] Performance benchmarking
- [ ] Cross-platform CI/CD

**Phase 4: Manual QA (Week 4)**:

- [ ] Manual testing on macOS and Linux
- [ ] User acceptance testing
- [ ] Documentation validation
- [ ] Final release testing

---

## Summary

**Test Strategy**: Comprehensive automated testing via Docker + GitHub Actions, supplemented with critical manual testing on actual platforms.

**Quality Focus**: Zero data loss (highest priority), cross-platform compatibility, idempotent installation.

**Risk Mitigation**: Namespace isolation prevents user data loss, CI/CD matrix catches platform issues early, comprehensive test coverage validates all scenarios.

**Success Criteria**:

- ✅ 100% user content preservation
- ✅ All automated tests pass on Ubuntu and macOS
- ✅ Manual QA confirms usability and error recovery
- ✅ Performance within benchmarks (<30s fresh install)
- ✅ Zero critical bugs in release

**Estimated Test Development**: 6-8 hours automated + 2-4 hours manual testing per release.

**Recommendation**: Invest heavily in automated testing infrastructure now to prevent regressions and enable rapid iteration in future releases.
