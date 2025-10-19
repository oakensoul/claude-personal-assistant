---
issue: 53
title: "Modular installer with deprecation support and .aida namespace installation"
status: "COMPLETED"
created: "2025-10-18 17:47:18"
completed: "2025-10-19"
pr: 59
estimated_effort: 2
actual_effort: 14
---

# Issue #53: Modular installer with deprecation support and .aida namespace installation

**Status**: COMPLETED
**Labels**: type:feature
**Milestone**: 0.1.0
**Assignees**: splash-rob

## Description

Enable backward compatibility during command renames by adding alias support to the command loading mechanism. This allows users to continue using old command names while the system redirects them to the new canonical names.

Modify the command loading mechanism to:
- Check frontmatter for `aliases: []` field in command files
- Redirect when users type an alias to the canonical command
- Provide seamless backward compatibility for renamed commands

This is a foundational feature that unblocks all future command renames in Phase 2 and beyond.

## Requirements

### Core Functionality

- [ ] Refactor install.sh into modular components (~150 lines, orchestrator only)
- [ ] **Make install.sh a "dumb" wrapper** - All logic in lib/installer-common/ for reuse
- [ ] Change from file-based to folder-based template installation
- [ ] Add support for installing commands/agents/skills templates
- [ ] Implement version-based deprecation system
- [ ] Add `--with-deprecated` installation flag
- [ ] Create automated cleanup script for deprecated items
- [ ] Install templates into `.aida/` namespace (preserve user content)
- [ ] Always symlink `~/.aida/` to repo (regardless of mode)
- [ ] **Ensure lib/installer-common/ can be sourced by dotfiles repo**

### Installer Modules (lib/installer-common/)

- [ ] Create `templates.sh` - Template installation logic
- [ ] Create `deprecation.sh` - Version comparison and deprecation management
- [ ] Create `variables.sh` - Enhanced variable substitution
- [ ] Create `prompts.sh` - User interaction functions
- [ ] Create `directories.sh` - Directory management
- [ ] Create `summary.sh` - Installation summary display

### Deprecated Template Support

- [ ] Create `templates/commands-deprecated/` folder structure
- [ ] Create `templates/agents-deprecated/` folder structure
- [ ] Create `templates/skills-deprecated/` folder structure
- [ ] Define frontmatter schema for deprecation metadata
- [ ] Implement selective installation of deprecated items

### Scripts

- [ ] Create `scripts/cleanup-deprecated.sh` for automated cleanup
- [ ] Update main `install.sh` to orchestrate new modules

### Docker Testing Environment

- [ ] Create `Dockerfile` for clean testing environment (Linux/Ubuntu)
- [ ] Create Windows Dockerfile (PowerShell + bash support)
- [ ] Create `Makefile` with test targets
- [ ] Add `make test-install` - Test normal mode installation
- [ ] Add `make test-install-dev` - Test dev mode installation
- [ ] Add `make test-install-deprecated` - Test with `--with-deprecated` flag
- [ ] Add `make test-upgrade` - Test upgrade over existing installation
- [ ] Add `make test-user-content` - Verify user content preservation
- [ ] Add `make test-all` - Run full test suite across platforms
- [ ] Add `make test-windows` - Run Windows-specific tests
- [ ] Document Docker testing workflow

### CI/CD Testing (GitHub Actions)

- [ ] Create `.github/workflows/test-installer.yml`
- [ ] Test on Ubuntu container (latest)
- [ ] Test on macOS runner (latest)
- [ ] Test on Windows container (PowerShell + bash)
- [ ] Run on pull requests to main branch
- [ ] Run on pushes to main branch
- [ ] Matrix testing: normal mode, dev mode, with-deprecated
- [ ] Report test results in PR comments

### Documentation

- [ ] Document deprecation workflow
- [ ] Document folder-based template structure
- [ ] Update installation guide with new flags
- [ ] Document Docker testing process

**Original Effort**: 2 hours
**Revised Effort**: 12-16 hours (including Docker testing + CI/CD + Windows support)
**Priority**: HIGH - This is the critical first step that unblocks all subsequent command renames.

## Work Tracking

- Branch: `milestone-v0.1/feature/53-modular-installer`
- Started: 2025-10-18 17:47:18
- Work directory: `.github/issues/in-progress/issue-53/`

## Related Links

- [GitHub Issue](https://github.com/oakensoul/claude-personal-assistant/issues/53)
- [Project Board](https://github.com/oakensoul/claude-personal-assistant/projects)

## Notes

### Design Discussion (2025-10-18)

#### CRITICAL: Don't Nuke User's .claude/ Folder!

**Problem**: Current installer backs up and replaces `~/.claude/` entirely (line 251-258 in install.sh)

**Why this is wrong**:
- Users might have custom agents they created
- Users might have custom commands they wrote
- Users might have custom skills
- Other Claude Code settings and configurations
- Personal history/memory from previous sessions
- We can't just delete all that!

**Solution 1**: Surgical installation approach
- Install our template folders **into** existing structure
- Don't replace the entire `~/.claude/` directory
- Create subdirectories if they don't exist
- Preserve existing user content
- Only overwrite files we explicitly manage (our templates)

**Example**: Instead of this:
```bash
# BAD: Nukes everything
mv ~/.claude ~/.claude.backup.TIMESTAMP
mkdir ~/.claude
```

Do this:
```bash
# GOOD: Surgical installation
mkdir -p ~/.claude/commands/issue-create/
cp templates/commands/issue-create/README.md ~/.claude/commands/issue-create/
```

**Solution 2 (BETTER!)**: Use .aida subdirectory to namespace our templates

Since Claude Code searches recursively in the commands/agents/skills folders, we can install into subdirectories:

```bash
# Install AIDA templates into namespaced subdirectories
~/.claude/
├── commands/
│   ├── .aida/                      # AIDA-provided commands
│   │   ├── issue-create/
│   │   │   └── README.md
│   │   └── issue-publish/
│   │       └── README.md
│   └── my-custom-command/          # User's custom commands (preserved)
│       └── README.md
├── agents/
│   ├── .aida/                      # AIDA-provided agents
│   │   ├── tech-lead/
│   │   └── product-manager/
│   └── my-custom-agent/            # User's custom agents (preserved)
└── skills/
    ├── .aida/                      # AIDA-provided skills
    └── my-custom-skill/            # User's custom skills (preserved)
```

**Benefits of .aida subdirectory approach**:
- ✅ **Zero conflict risk** - Our templates physically separated from user's
- ✅ **Obvious ownership** - Clear what's AIDA vs user-created
- ✅ **Easy cleanup** - Just delete `.aida/` subdirectories
- ✅ **Easy updates** - Can replace `.aida/` folder entirely without worrying about user content
- ✅ **Still works** - Claude Code finds commands recursively
- ✅ **Deprecation-friendly** - Can have `.aida-deprecated/` subfolder too

**Installation becomes simpler**:
```bash
# Normal mode: Copy AIDA templates into namespaced folder
mkdir -p ~/.claude/commands/.aida/
cp -r templates/commands/* ~/.claude/commands/.aida/

# With deprecated templates
mkdir -p ~/.claude/commands/.aida-deprecated/
cp -r templates/commands-deprecated/* ~/.claude/commands/.aida-deprecated/

# Dev mode: Symlink namespaced folders
ln -s ~/path/to/repo/templates/commands ~/.claude/commands/.aida
```

**This is the winner!** Use `.aida/` and `.aida-deprecated/` subdirectories.

**Installation becomes much simpler** (less surgical precision needed):

```bash
# Just nuke our namespace and reinstall - user content is safe!
rm -rf ~/.claude/commands/.aida/
rm -rf ~/.claude/commands/.aida-deprecated/
rm -rf ~/.claude/agents/.aida/
rm -rf ~/.claude/agents/.aida-deprecated/
rm -rf ~/.claude/skills/.aida/
rm -rf ~/.claude/skills/.aida-deprecated/

# Fresh install of AIDA templates
cp -r templates/commands/ ~/.claude/commands/.aida/
cp -r templates/agents/ ~/.claude/agents/.aida/
cp -r templates/skills/ ~/.claude/skills/.aida/

# Optional: deprecated templates
if [[ "$INSTALL_DEPRECATED" == "true" ]]; then
    cp -r templates/commands-deprecated/ ~/.claude/commands/.aida-deprecated/
    cp -r templates/agents-deprecated/ ~/.claude/agents/.aida-deprecated/
    cp -r templates/skills-deprecated/ ~/.claude/skills/.aida-deprecated/
fi
```

**No need to**:
- ❌ Track which templates are ours vs user's (manifest file)
- ❌ Check frontmatter markers
- ❌ Prompt before overwriting
- ❌ Merge or resolve conflicts
- ❌ Backup user's .claude/ directory

**We can be "nuclear" within our namespace** - it's safe because user content is outside `.aida/`!

**The Contract**:

```
AIDA owns:     ~/.claude/commands/.aida/
               ~/.claude/agents/.aida/
               ~/.claude/skills/.aida/
               ~/.claude/commands/.aida-deprecated/
               ~/.claude/agents/.aida-deprecated/
               ~/.claude/skills/.aida-deprecated/

User owns:     Everything else in ~/.claude/
```

**When user runs installer/updater**:
- We **nuke** `.aida/` folders completely
- We **reinstall** fresh from templates
- **Zero guilt** - it's our namespace, we own it
- If user modified something in `.aida/`? Their problem - docs will warn them

**Documentation will say**:

> ⚠️ **Warning**: The `.aida/` and `.aida-deprecated/` folders are managed by AIDA. Any modifications will be lost on update. Create your custom commands/agents/skills in the parent directories instead:
> - Custom commands: `~/.claude/commands/my-command/`
> - Custom agents: `~/.claude/agents/my-agent/`
> - Custom skills: `~/.claude/skills/my-skill/`

This approach makes installation **dramatically simpler** - no surgical precision, no tracking, no prompts, no backups!

#### Installation Structure: Always Symlink ~/.aida/

**Key insight**: `~/.aida/` should ALWAYS be a symlink to the repo, regardless of mode.

**The mode only affects how templates are installed to `~/.claude/`:**

```bash
# ALWAYS (both modes):
ln -s ${SCRIPT_DIR} ~/.aida

# Then depending on mode:

# Normal Mode - COPY templates with variable substitution
cp -r ~/.aida/templates/commands/ ~/.claude/commands/.aida/
cp -r ~/.aida/templates/agents/ ~/.claude/agents/.aida/
cp -r ~/.aida/templates/skills/ ~/.claude/skills/.aida/
# Then substitute variables in the copied files

# Dev Mode - SYMLINK templates for live editing
ln -s ~/.aida/templates/commands ~/.claude/commands/.aida
ln -s ~/.aida/templates/agents ~/.claude/agents/.aida
ln -s ~/.aida/templates/skills ~/.claude/skills/.aida
```

**Visual Flow**:

```
Always:
  Repo → [SYMLINK] → ~/.aida/

Normal Mode:
  ~/.aida/templates/ → [COPY + SUBSTITUTE] → ~/.claude/commands/.aida/
  (Stable, substituted templates)

Dev Mode:
  ~/.aida/templates/ → [SYMLINK] → ~/.claude/commands/.aida/
  (Live editing of templates)
```

**Benefits**:
- ✅ Simpler - `~/.aida/` is just a pointer to repo
- ✅ Less disk space - No copying entire repo
- ✅ Easier updates - Just `git pull` in repo
- ✅ Clear distinction - Dev vs normal is ONLY about live template editing

#### Update Workflow

**Dev Mode - Automatic Updates** 🚀

```bash
cd ~/path/to/repo
git pull

# That's it! Everything auto-updates because:
# ~/.aida/ → symlink → repo (now updated)
# ~/.claude/commands/.aida/ → symlink → ~/.aida/templates/commands (now updated)
```

**No reinstall needed** unless:
- New installer features (new CLI flags, new modules, etc.)
- New directory structure changes
- Variable substitution logic changes

**Just `git pull` updates**:
- Command template content changes
- New commands added
- Agent updates
- Skill updates
- All template content

**Normal Mode - Manual Updates**

```bash
cd ~/path/to/repo
git pull

# Then MUST re-run installer to update templates
./install.sh
```

**Why?** Because `~/.claude/commands/.aida/` is a COPY, not a symlink.

**Summary**:

| Mode | Update Method | Reinstall Needed? |
|------|---------------|-------------------|
| **Dev** | `git pull` | Only for installer features |
| **Normal** | `git pull` + `./install.sh` | Every time for template updates |

**This is why dev mode is awesome for development!** Live on the bleeding edge with zero friction.

#### Dotfiles Integration: Reusable Installation Libraries

**Critical requirement**: `install.sh` must be a "dumb" wrapper that calls smart libraries in `lib/installer-common/`.

**Why?**

This project is part of a three-repo ecosystem:

1. **claude-personal-assistant** (this repo) - Core AIDA framework with `install.sh`
2. **dotfiles** (public repo) - Can optionally install AIDA, needs to call AIDA installation logic
3. **dotfiles-private** - Personal overrides

Without reusable libraries, we'd duplicate installation logic across repos. Changes and bug fixes would need to be synchronized manually.

**The solution**: Make `lib/installer-common/` the single source of truth:

```bash
# This repo: install.sh (dumb wrapper ~150 lines)
source lib/installer-common/*.sh
main() {
    create_directories
    install_templates "commands"
    install_templates "agents"
    install_templates "skills"
}
```

```bash
# Dotfiles repo: install-aida.sh (calls same libraries)
source ~/.aida/lib/installer-common/*.sh
install_aida_from_dotfiles() {
    create_directories
    install_templates "commands"
    # ... etc
}
```

**Benefits**:
- ✅ One place for all installation logic
- ✅ Dotfiles repo can source `~/.aida/lib/installer-common/*`
- ✅ No code duplication
- ✅ Bug fixes automatically benefit both repos
- ✅ Either install order works (AIDA first or dotfiles first)

**Additional requirements**:
- Libraries can be sourced from external scripts
- No hardcoded paths that assume running from repo root
- Functions accept parameters (not just globals)
- Libraries are self-contained (minimal dependencies)

**Testing**:
- Test sourcing libraries from different directory
- Test calling functions with parameters
- Verify no assumptions about `$PWD`

This ensures the dotfiles integration works seamlessly!

#### Docker Testing Environment

**Critical requirement**: We need to test installation in clean environments to ensure:
- Fresh install works correctly
- Upgrade over existing `.claude/` preserves user content
- Dev mode and normal mode both work
- Deprecated templates install correctly with `--with-deprecated`

**Solution**: Docker + Makefile

**Proposed structure**:
```
.github/testing/
├── Dockerfile              # Clean Ubuntu/Debian environment
├── Makefile               # Test targets (make test-all, etc.)
├── fixtures/
│   ├── user-commands/     # Mock user content for upgrade tests
│   ├── user-agents/
│   └── user-skills/
└── test-scenarios/
    ├── fresh-install.sh
    ├── upgrade.sh
    └── user-content-preservation.sh
```

**Makefile targets**:
```makefile
test-install:            # Test normal mode installation
test-install-dev:        # Test dev mode installation
test-install-deprecated: # Test with --with-deprecated flag
test-upgrade:           # Test upgrade over existing .claude/
test-user-content:      # Verify user files preserved
test-all:               # Run full test suite
```

**Benefits**:
- ✅ Repeatable testing in clean environment
- ✅ Verify user content preservation
- ✅ Can run before every commit/PR
- ✅ Documents expected behavior
- ✅ Catches regressions early

**Note**: Project already has `.github/testing/test-install.sh` - can be enhanced/integrated with Makefile approach.

**Cross-Platform CI/CD Testing**:

Beyond local Docker testing, we need GitHub Actions to test every PR:

```yaml
# .github/workflows/test-installer.yml
Platform Matrix:
- Ubuntu (latest container)
- macOS (latest runner)
- Windows (PowerShell + bash container)

Mode Matrix:
- Normal installation
- Dev mode installation
- With deprecated templates

Test Scenarios per Platform:
- Fresh install
- Upgrade install (preserve user content)
- Variable substitution
- Symlink creation (dev mode)
```

**Why Windows + PowerShell + bash?**
- Many users run Windows Subsystem for Linux (WSL)
- Need to ensure bash scripts work on Windows
- PowerShell may be default shell for some users
- Test both environments to maximize compatibility

**CI/CD Benefits**:
- ✅ Every PR tested before merge
- ✅ Catches platform-specific issues early
- ✅ Prevents regressions
- ✅ Documents supported platforms
- ✅ PR comments show test results

#### Scope Expansion

**Original scope**: Add alias support to command loader (2 hours)

**Expanded scope**: This ticket now includes:
1. **Refactor install.sh** into modular components
2. **Create deprecation system** with version tracking
3. **Support deprecated templates** with `--with-deprecated` flag
4. **Folder-based structure** (commands/agents/skills are folders, not files)
5. **Automated cleanup script** based on versions
6. **Frontmatter schema** for deprecation metadata

**Revised estimate**: 8-12 hours

#### Key Insights

**Claude Code's role**:
- Claude Code provides basic slash command loading from `.claude/commands/*/README.md`
- When you type `/command-name`, it looks for `command-name/README.md`
- **No built-in alias support** - we need to build this ourselves

**What we're building**:
- NOT relying on Claude Code built-in features
- Building our own deprecation/alias system on top of Claude Code's basic loading

#### Design Decision: Deprecated Template Folders

**Rejected approaches**:
1. ❌ **Symlinks** - Too seamless, users never learn new names, no deprecation warnings
2. ❌ **Auto-generated stubs** - Complex, unclear where they come from
3. ❌ **Aliases in frontmatter only** - Would require runtime alias resolution

**Chosen approach**: Separate deprecated template folders with explicit stub files

```
templates/
├── commands/                      # Current canonical commands
│   ├── issue-create/
│   │   └── README.md
│   └── issue-publish/
│       └── README.md
│
└── commands-deprecated/           # Deprecated commands (optional install)
    ├── create-issue/
    │   └── README.md              # Stub with deprecation warning
    └── publish-issue/
        └── README.md
```

**Why this works**:
- ✅ **User choice** - Install with `--with-deprecated` flag or not
- ✅ **Explicit deprecation** - Stubs show clear warnings and migration path
- ✅ **Version controlled** - All deprecated items tracked in repo
- ✅ **Folder-based** - Each command/agent/skill is a folder with README
- ✅ **Easy cleanup** - Delete entire folder when ready
- ✅ **Clear for new users** - Default install has no deprecated cruft

#### Frontmatter Schema for Deprecation

**Deprecated command** (`templates/commands-deprecated/create-issue/README.md`):

```yaml
---
title: "Create Issue (DEPRECATED)"
deprecated: true
deprecated_in: "0.2.0"        # Version when deprecated
remove_in: "0.4.0"            # Version when it will be removed
canonical: "issue-create"      # Points to new command
reason: "Renamed to follow noun-verb convention (ADR-010)"
---
```

**Deprecation lifecycle**:
- **v0.2.0**: Command renamed, deprecated version available with `--with-deprecated`
- **v0.3.0**: Deprecation warning period continues
- **v0.4.0**: Automated cleanup script removes deprecated items

#### Modular Install Script Structure

**Current state**: `install.sh` is 625 lines - getting unwieldy

**Proposed modular structure**:

```bash
install.sh (slim orchestrator ~150 lines)

lib/installer-common/
├── colors.sh              # ✓ Existing
├── logging.sh             # ✓ Existing
├── validation.sh          # ✓ Existing
├── prompts.sh             # NEW - User interaction
├── directories.sh         # NEW - Directory management
├── templates.sh           # NEW - Template installation
├── deprecation.sh         # NEW - Deprecation management
├── variables.sh           # NEW - Variable substitution
└── summary.sh             # NEW - Installation summary
```

**Benefits**:
- ✅ Single responsibility per module
- ✅ Testable independently
- ✅ Reusable across scripts
- ✅ Main install.sh becomes orchestrator (~150 lines vs 625)
- ✅ Easy to extend with new features

#### Automated Cleanup Script

**`scripts/cleanup-deprecated.sh`**:
- Reads current version from `VERSION` file
- Scans `templates/*/deprecated/` folders
- Extracts `remove_in` from frontmatter
- Removes items where `current_version >= remove_in`
- Can be integrated into CI/CD for automatic cleanup

#### Installation Options

```bash
# Default: Only canonical commands
./install.sh

# Include deprecated commands for backward compatibility
./install.sh --with-deprecated

# Development mode with deprecated commands
./install.sh --dev --with-deprecated
```

### Current Installer Analysis

**What it does** (install.sh - 625 lines):

1. **Setup** (lines 19-54)
   - Sources utility modules: colors.sh, logging.sh, validation.sh
   - Reads VERSION file
   - Validates dependencies

2. **User Input** (lines 122-209)
   - Prompts for assistant name (3-20 chars, lowercase)
   - Prompts for personality (5 choices: jarvis, alfred, friday, sage, drill-sergeant)

3. **Backup** (lines 222-275)
   - ❌ **PROBLEM**: Backs up entire `~/.aida/` and `~/.claude/` directories
   - This is too aggressive - destroys user customizations

4. **Directory Creation** (lines 288-345)
   - **Normal mode**: rsync entire repo to `~/.aida/`
   - **Dev mode (`--dev`)**: Symlinks `~/.aida/` → repo
   - Creates `~/.claude/` subdirectories (config, knowledge, memory, agents)

5. **Template Installation** (lines 358-436)
   - **`copy_command_templates()`** function
   - ❌ **PROBLEM**: Only processes `*.md` files (line 391: `for template in "${template_dir}"/*.md`)
   - Won't work with folder structure (commands/issue-create/README.md)
   - ❌ **PROBLEM**: Only handles commands, no agents or skills
   - **Normal mode**: Copies each .md file with variable substitution
   - **Dev mode**: Symlinks entire commands directory
   - Variable substitution: {{AIDA_HOME}}, {{CLAUDE_CONFIG_DIR}}, {{HOME}}

6. **Entry Point** (lines 449-512)
   - Generates `~/CLAUDE.md` with frontmatter and configuration

7. **Summary** (lines 523-558)
   - Displays installation summary

**What it doesn't do**:

❌ No folder-based template installation
❌ No agent template installation
❌ No skill template installation
❌ No deprecation support
❌ No `--with-deprecated` flag
❌ No version-based cleanup
❌ No surgical installation (nukes entire directories)
❌ No protection for user customizations

**What works well**:

✅ Modular utilities exist (colors, logging, validation)
✅ Dev mode symlinks work
✅ Backup system uses timestamps
✅ User prompts are validated
✅ Variable substitution concept works (just needs expansion)

### Implementation Plan

**Phase 1: Refactor to Modular Structure**

1. Extract functions from install.sh into modules:
   - `lib/installer-common/prompts.sh` - User interaction (prompt_assistant_name, prompt_personality)
   - `lib/installer-common/directories.sh` - Directory management (create_directories, check_existing_install)
   - `lib/installer-common/variables.sh` - Variable substitution logic
   - `lib/installer-common/summary.sh` - Installation summary display

2. Slim down install.sh to ~150 lines (orchestrator only)

**Phase 2: Add Folder-Based Template System**

3. Create `lib/installer-common/templates.sh`:
   - `install_templates(type, dev_mode, with_deprecated)` - Main entry point
   - `install_template_type(type)` - Install commands/agents/skills
   - `install_canonical_templates(type)` - Install from templates/commands/
   - `install_deprecated_templates(type)` - Install from templates/commands-deprecated/
   - `copy_template_folder(src, dest, dev_mode)` - Copy or symlink folder
   - `should_install_template(folder)` - Check if template should be installed

4. Handle folder structure:
   - Process `templates/commands/*/README.md` (not `templates/commands/*.md`)
   - Process `templates/agents/*/index.md`
   - Process `templates/skills/*/README.md`

**Phase 3: Add Deprecation System**

5. Create `lib/installer-common/deprecation.sh`:
   - `version_compare(v1, v2)` - Semantic version comparison
   - `should_install_deprecated(current_version)` - Check if deprecated items install
   - `check_removal_version(frontmatter_file)` - Extract remove_in version
   - `parse_frontmatter_version(file, field)` - Parse version from frontmatter

6. Define frontmatter schema for deprecated templates:
```yaml
---
deprecated: true
deprecated_in: "0.2.0"
remove_in: "0.4.0"
canonical: "issue-create"
reason: "Renamed to follow noun-verb convention"
---
```

**Phase 4: Surgical Installation**

7. Change directory management:
   - ❌ Remove: `mv ~/.claude ~/.claude.backup.TIMESTAMP`
   - ✅ Add: Surgical installation of individual template folders
   - ✅ Check: Don't overwrite user-created content
   - ✅ Preserve: Existing custom agents/commands/skills

8. Installation approach:
```bash
# For each template folder
mkdir -p ~/.claude/commands/issue-create/
cp -r templates/commands/issue-create/ ~/.claude/commands/issue-create/
# Substitute variables in copied files
```

**Phase 5: Automated Cleanup**

9. Create `scripts/cleanup-deprecated.sh`:
   - Read current version from VERSION file
   - Scan templates/*/deprecated/ folders
   - Extract remove_in from frontmatter
   - Remove items where current_version >= remove_in

10. Optional: Add CI/CD integration for automatic cleanup

**Phase 6: Testing & Documentation**

11. Test installation scenarios:
   - Fresh install (no existing .claude/)
   - Upgrade install (existing .claude/ with custom content)
   - Dev mode with deprecated templates
   - Normal mode without deprecated templates

12. Update documentation:
   - Installation guide with new flags
   - Deprecation workflow documentation
   - Folder-based template structure guide

### Questions for Expert Analysis

1. Should we use semantic versioning library or simple string comparison for version_compare()?
2. How should we handle deprecation warnings when commands are invoked?
3. Should cleanup script run automatically in CI/CD or manually?
4. Do we need migration tooling to help users update their workflows?
5. Should we track usage of deprecated commands for analytics?
6. **Surgical installation strategy**: How do we determine if a template is "ours" vs user-created?
   - Option A: Track installed templates in a manifest file (`.claude/.aida-installed-templates.json`)
   - Option B: Check frontmatter for AIDA-specific markers
   - Option C: Always prompt user before overwriting any existing content
7. **Dev mode with surgical installation**: Should dev mode still symlink entire directories, or symlink individual template folders?
8. **Backup strategy**: Should we still backup .claude/ or trust surgical installation?
9. **Version conflicts**: What if user has older version of our template installed? Overwrite, merge, or skip?
10. **Template dependencies**: Do templates ever depend on each other? Need dependency resolution?

### Related ADRs

- **ADR-010**: Command Structure Refactoring (defines the command renames)
- This ticket enables the migration path described in ADR-010 Phase 1

## Resolution

**Completed**: 2025-10-19
**Pull Request**: #59 - https://github.com/oakensoul/claude-personal-assistant/pull/59

### Changes Made

Successfully refactored the monolithic AIDA installer (625 lines) into a modular, reusable architecture with comprehensive testing infrastructure:

**Modular Architecture** (8 library modules):
- `lib/installer-common/colors.sh` - Terminal color output
- `lib/installer-common/logging.sh` - Message formatting  
- `lib/installer-common/validation.sh` - Input validation
- `lib/installer-common/prompts.sh` - User interaction (34 bats tests)
- `lib/installer-common/directories.sh` - Directory management
- `lib/installer-common/config.sh` - Configuration writing (9 bats tests)
- `lib/installer-common/summary.sh` - Installation summary
- `lib/installer-common/templates.sh` - Template installation (48 bats tests)

**Universal Config Aggregator** (ADR-012):
- `lib/aida-config-helper.sh` - 7-tier configuration merging
- Session-scoped caching with 85%+ I/O reduction
- Eliminates variable substitution in templates

**Namespace Isolation** (ADR-013):
- Install templates to `.aida/` subdirectories within `~/.claude/`
- Prevents conflicts with user's custom content
- Clear ownership boundary (AIDA owns `.aida/`, user owns everything else)
- Support for `.aida-deprecated/` namespace

**Deprecation System**:
- Version-based deprecation with frontmatter schema
- `scripts/cleanup-deprecated.sh` for automated cleanup
- Frontmatter fields: `deprecated`, `deprecated_in`, `remove_in`, `canonical`, `reason`

**Testing Infrastructure**:
- 98 bats unit tests (100% pass rate)
- Docker-based cross-platform testing
- Upgrade scenario testing with user content preservation
- CI/CD workflows for Ubuntu/macOS/Windows

**Documentation**:
- `docs/INSTALLATION.md` (1,040 lines) - Comprehensive user installation guide
- `docs/testing/MANUAL_TESTING.md` (985 lines) - QA verification procedures
- ADR-011 (Modular Installer Architecture)
- ADR-012 (Universal Config Aggregator)
- ADR-013 (Namespace Isolation)
- C4 diagrams for system context

### Implementation Details

**Architecture Decisions**:
- Chose namespace isolation (`.aida/` subdirectories) over surgical installation
- 7-tier config merging eliminates need for variable substitution
- Session-scoped caching with PID-based cleanup
- Templates as folders (not flat files) for better organization

**Key Technical Approaches**:
- All business logic extracted to `lib/installer-common/` for dotfiles reuse
- `install.sh` reduced to thin orchestrator (~150 lines)
- Normal mode: Copy templates with variable substitution
- Dev mode: Symlink templates for live editing
- Both modes: Always symlink `~/.aida/` to repo

**Testing Methodology**:
- Bats (Bash Automated Testing System) for unit tests
- Docker containers for isolated integration testing
- Upgrade scenarios with pre-populated user content
- Dead code removal after identifying untestable tests

### Notes

**Scope Evolution**: Originally scoped as "add alias support to command loader" (2 hours), this evolved into a comprehensive installer refactoring addressing multiple critical issues:

1. Monolithic installer (625 lines) → Modular architecture (8 libraries)
2. Destroys user content → Namespace isolation preserves everything
3. Only handles commands → Supports commands/agents/skills
4. File-based → Folder-based template structure
5. No deprecation support → Full deprecation system with version tracking
6. No testing → 98 unit tests + Docker + CI/CD
7. No dotfiles integration → Reusable libraries for multi-repo ecosystem

**Effort Tracking**:
- Estimated: 2 hours (original scope)
- Actual: 14 hours (expanded scope with architecture, testing, documentation)
- Complexity increased 7x but delivered foundational improvements

**Trade-offs**:
- Removed 4 unused config wrapper functions (discovered during testing)
- Removed 8 untestable tests (interactive prompts, readonly variables)
- Fixed critical `cp -a` bug that created nested directories during upgrades

**Future Considerations**:
- Windows testing infrastructure in place but not yet validated
- Alias loading mechanism still needed (deferred to future ticket)
- Multi-domain detection for build labels (Phase 2 planned)
- Deprecation cleanup automation via CI/CD (infrastructure ready)
