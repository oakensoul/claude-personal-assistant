---
title: "Manual Testing Guide for Modular Installer"
description: "Comprehensive manual verification procedures for AIDA installer QA testing"
category: "development"
tags: ["testing", "qa", "installer", "verification", "quality-assurance"]
last_updated: "2025-10-19"
status: "published"
audience: "developers"
version: "0.2.0"
---

# Manual Testing Guide for Modular Installer

## Table of Contents

- [Introduction](#introduction)
- [Test Environment Setup](#test-environment-setup)
- [Test Scenarios](#test-scenarios)
- [Regression Testing](#regression-testing)
- [Cross-Platform Testing](#cross-platform-testing)
- [User Experience Testing](#user-experience-testing)
- [Smoke Tests](#smoke-tests)
- [Documenting Issues](#documenting-issues)
- [Test Checklist Summary](#test-checklist-summary)
- [Appendix: Test Data](#appendix-test-data)

## Introduction

### Purpose of Manual Testing

While AIDA has comprehensive automated test coverage (273 tests, 100% passing), manual testing is essential for:

- **Real Environment Validation**: Verify automated tests work correctly in actual user environments
- **UX Issue Detection**: Catch user experience problems that automated tests cannot detect
- **Cross-Platform Behavior**: Validate installer behavior across different operating systems and configurations
- **User Experience**: Ensure smooth, intuitive installation process
- **Edge Case Discovery**: Find issues that occur in real-world scenarios

### When to Use Manual Testing

Execute these manual tests:

- **Before Releases**: Complete test suite before any version release
- **After Major Changes**: When installer logic or structure changes significantly
- **On New Platforms**: When adding support for new operating systems
- **User-Reported Issues**: When investigating user-reported installation problems
- **After Refactoring**: When refactoring installer components

### What This Guide Covers

This guide provides step-by-step procedures for testing:

- Fresh installations (normal and dev modes)
- Upgrade paths from v0.1.x to v0.2.0
- Namespace isolation and user content protection
- Configuration aggregator functionality
- Cross-platform compatibility
- User experience quality

## Test Environment Setup

### Prerequisites

**System Requirements**:

- **Operating System**: macOS 13+, Ubuntu 22.04+, or Debian 12+
- **Shell**: Bash 3.2+ (macOS default) or Bash 4.0+ (Linux)
- **Required Tools**: Git, jq, GNU coreutils
- **Disk Space**: ~100MB free space
- **Permissions**: User-level access (no sudo required for installation)

**Recommended Testing Environment**:

For safest testing, use an isolated environment:

- **Virtual Machine** (VMware, VirtualBox, Parallels)
- **Docker Container** (see `.github/testing/test-install.sh`)
- **Test User Account** (separate from your main account)

### Setup Clean Test Environment

#### Option 1: Create Test User (Recommended)

```bash
# Create dedicated test user
sudo useradd -m -s /bin/bash testuser

# Switch to test user
sudo su - testuser

# Verify clean environment
ls -la ~  # Should show minimal files
```

#### Option 2: Clean Existing Installation

**WARNING**: This removes all AIDA data. Only use for testing.

```bash
# Backup any important data first!
# Remove AIDA installation
rm -rf ~/.aida

# Remove user configuration
rm -rf ~/.claude

# Remove entry point
rm -f ~/CLAUDE.md

# Verify clean state
ls -la ~/.aida ~/.claude ~/CLAUDE.md 2>&1 | grep "No such file"
```

#### Option 3: Docker-Based Testing

```bash
# Use AIDA's built-in Docker test environment
cd /path/to/claude-personal-assistant

# Test on all platforms
./.github/testing/test-install.sh

# Test on specific platform
./.github/testing/test-install.sh --env ubuntu-22

# Verbose output for debugging
./.github/testing/test-install.sh --verbose
```

### Verify Prerequisites

Before starting tests, verify all prerequisites are met:

```bash
# Check Bash version (3.2+ required)
bash --version

# Check Git installed
git --version

# Check jq installed
jq --version

# Check disk space (need ~100MB)
df -h ~

# Verify user permissions (should not be root)
whoami  # Should NOT return 'root'
```

All commands should succeed without errors.

## Test Scenarios

### Scenario 1: Fresh Installation (Normal Mode)

**Objective**: Verify clean installation on fresh system with default configuration.

**Time Estimate**: 5-10 minutes

**Prerequisites**: Clean test environment (no existing `~/.aida` or `~/.claude`)

#### Steps

**Step 1: Clone Repository**

```bash
# Clone to default location
git clone https://github.com/oakensoul/claude-personal-assistant.git ~/.aida

# Navigate to installation directory
cd ~/.aida

# Verify repository cloned successfully
ls -la  # Should see install.sh, templates/, lib/, etc.
```

**Step 2: Run Installer**

```bash
# Execute installer in normal mode (default)
./install.sh
```

**Step 3: Answer Interactive Prompts**

The installer will prompt for configuration. Use these test values:

- **Assistant name**: `JARVIS`
- **Personality**: `professional` (or select from menu if prompted)

**Note**: Pay attention to prompt clarity and help text quality.

#### Verification Checklist

After installation completes, verify all components:

**Framework Installation**:

- [ ] Installation completes without errors
- [ ] Exit code is 0: `echo $?` (run immediately after install)
- [ ] `~/.aida/` directory exists: `test -d ~/.aida && echo "✓ PASS" || echo "✗ FAIL"`
- [ ] `~/.aida/` is a real directory (not symlink): `test ! -L ~/.aida && echo "✓ PASS" || echo "✗ FAIL"`

**User Configuration**:

- [ ] `~/.claude/` directory exists: `test -d ~/.claude && echo "✓ PASS" || echo "✗ FAIL"`
- [ ] Entry point created: `test -f ~/CLAUDE.md && echo "✓ PASS" || echo "✗ FAIL"`
- [ ] Entry point is readable: `head -5 ~/CLAUDE.md`

**Namespace Directories**:

- [ ] Commands namespace: `test -d ~/.claude/commands/.aida && echo "✓ PASS" || echo "✗ FAIL"`
- [ ] Agents namespace: `test -d ~/.claude/agents/.aida && echo "✓ PASS" || echo "✗ FAIL"`
- [ ] Skills namespace: `test -d ~/.claude/skills/.aida && echo "✓ PASS" || echo "✗ FAIL"`

**Configuration File**:

- [ ] Config exists: `test -f ~/.claude/aida-config.json && echo "✓ PASS" || echo "✗ FAIL"`
- [ ] Config is valid JSON: `jq . ~/.claude/aida-config.json > /dev/null && echo "✓ PASS" || echo "✗ FAIL"`
- [ ] Config has correct version: `jq -r '.version' ~/.claude/aida-config.json` (should show v0.2.0)
- [ ] Config has assistant name: `jq -r '.user.assistant_name' ~/.claude/aida-config.json` (should show JARVIS)
- [ ] Config has personality: `jq -r '.user.personality' ~/.claude/aida-config.json` (should show professional)

**Version Verification**:

- [ ] Version file exists: `test -f ~/.aida/VERSION && echo "✓ PASS" || echo "✗ FAIL"`
- [ ] Version is v0.2.0: `cat ~/.aida/VERSION` (should show v0.2.0)

**Permissions Verification**:

- [ ] Directories are 755: `stat -c "%a" ~/.claude/commands/.aida` (Linux) or `stat -f "%A" ~/.claude/commands/.aida` (macOS)
- [ ] Files are 644: Check sample file permissions
- [ ] No world-writable files: `find ~/.aida ~/.claude -type f -perm -002 | wc -l` (should be 0)

**Template Content**:

- [ ] Templates copied (not symlinked): `test ! -L ~/.claude/commands/.aida/start-work && echo "✓ PASS" || echo "✗ FAIL"`
- [ ] Sample command exists: `test -d ~/.claude/commands/.aida/start-work && echo "✓ PASS" || echo "✗ FAIL"`
- [ ] Sample agent exists: `test -f ~/.claude/agents/.aida/secretary.md && echo "✓ PASS" || echo "✗ FAIL"`

#### Expected Results

**Installation Speed**:

- Installation should complete in < 30 seconds on modern hardware
- No long pauses or timeouts

**User Experience**:

- All prompts clear and easy to understand
- Progress messages informative (showing what's happening)
- No confusing error messages
- Success message displays with helpful next steps

**Final State**:

- All checklist items pass
- System is ready to use
- No errors in terminal output

#### Common Issues to Watch For

- **Slow installation**: Should complete quickly; delays indicate issues
- **Permission errors**: Should not require sudo
- **Missing directories**: All namespace directories must be created
- **Invalid JSON**: Config file must be valid JSON
- **Symlinks in normal mode**: Templates should be copied, not symlinked

### Scenario 2: Fresh Installation (Dev Mode)

**Objective**: Verify development mode with symlinks for live template editing.

**Time Estimate**: 5-10 minutes

**Prerequisites**: Clean test environment (no existing `~/.aida` or `~/.claude`)

**Use Case**: For AIDA developers who want to edit templates in their dev repository and see changes immediately.

#### Steps

**Step 1: Clone to Development Location**

```bash
# Clone to a development directory (NOT ~/.aida)
mkdir -p ~/dev
git clone https://github.com/oakensoul/claude-personal-assistant.git ~/dev/aida

# Navigate to development directory
cd ~/dev/aida

# Verify repository cloned successfully
ls -la
```

**Step 2: Install in Dev Mode**

```bash
# Execute installer with --dev flag
./install.sh --dev
```

**Step 3: Answer Interactive Prompts**

Use the same test values:

- **Assistant name**: `JARVIS`
- **Personality**: `professional`

#### Verification Checklist

**Symlink Verification**:

- [ ] `~/.aida/` is a symlink: `test -L ~/.aida && echo "✓ PASS" || echo "✗ FAIL"`
- [ ] Symlink points to dev directory: `readlink ~/.aida` (should show ~/dev/aida)
- [ ] Symlink is valid: `test -d ~/.aida && echo "✓ PASS" || echo "✗ FAIL"`

**Template Symlinks**:

- [ ] Command templates are symlinked: `test -L ~/.claude/commands/.aida/start-work && echo "✓ PASS" || echo "✗ FAIL"`
- [ ] Agent templates are symlinked: `test -L ~/.claude/agents/.aida/secretary.md && echo "✓ PASS" || echo "✗ FAIL"`
- [ ] Skill templates are symlinked (if any): `ls -la ~/.claude/skills/.aida/`

**Verify Symlink Targets**:

- [ ] Command symlink points to repo: `readlink ~/.claude/commands/.aida/start-work` (should point to ~/dev/aida/templates/commands/start-work)
- [ ] Agent symlink points to repo: `readlink ~/.claude/agents/.aida/secretary.md` (should point to ~/dev/aida/templates/agents/secretary.md)

**Config is NOT Symlinked** (for safety):

- [ ] Config exists: `test -f ~/.claude/aida-config.json && echo "✓ PASS" || echo "✗ FAIL"`
- [ ] Config is a real file (not symlink): `test ! -L ~/.claude/aida-config.json && echo "✓ PASS" || echo "✗ FAIL"`

**Live Editing Test**:

Test that changes in the repository appear immediately in `~/.claude/`:

```bash
# Make a test change in the repo
echo "# TEST EDIT" >> ~/dev/aida/templates/commands/start-work/README.md

# Verify change appears in ~/.claude/ immediately
tail -1 ~/.claude/commands/.aida/start-work/README.md
# Should show "# TEST EDIT"

# Clean up test edit
git -C ~/dev/aida checkout templates/commands/start-work/README.md
```

- [ ] Test edit appears immediately in `~/.claude/`
- [ ] No cache or copy delay

**Standard Checks** (same as normal mode):

- [ ] `~/.claude/` directory exists
- [ ] Entry point created: `~/CLAUDE.md`
- [ ] Namespace directories exist
- [ ] Config is valid JSON
- [ ] Version is v0.2.0

#### Expected Results

**Symlink Behavior**:

- `~/.aida/` is a symlink to development directory
- All templates in `~/.claude/` are symlinks to repo
- Config file is copied (not symlinked) for safety

**Live Editing**:

- Edits in `~/dev/aida/templates/` appear immediately in `~/.claude/`
- No need to reinstall after template changes
- Can develop templates with live testing

**Safety**:

- Config is NOT symlinked (prevents accidental commit of secrets)
- Can edit config without affecting repository
- Repository stays clean (no user-specific config changes)

#### Common Issues to Watch For

- **Broken symlinks**: All symlinks must point to valid targets
- **Config symlinked**: Config must be copied, not symlinked (security)
- **Relative symlinks**: Symlinks should use absolute paths
- **Wrong symlink targets**: Verify symlinks point to correct repository location

### Scenario 3: Upgrade from v0.1.x

**Objective**: Verify safe upgrade from v0.1.x preserves user content and migrates to namespace structure.

**Time Estimate**: 10-15 minutes

**Prerequisites**: Clean test environment

**Critical Test**: This verifies zero data loss during upgrade.

#### Steps

**Step 1: Simulate v0.1.x Installation**

Create a realistic v0.1.x environment with user content:

```bash
# Create v0.1.x directory structure (flat, no namespaces)
mkdir -p ~/.claude/commands
mkdir -p ~/.claude/agents
mkdir -p ~/.claude/skills

# Create user-created content (simulating real user work)
cat > ~/.claude/commands/my-deploy.md << 'EOF'
---
title: "My Custom Deploy Command"
description: "Custom deployment workflow for my projects"
---

# My Deploy Command

Custom deployment steps:
1. Build project
2. Run tests
3. Deploy to staging
EOF

cat > ~/.claude/agents/my-devops-expert.md << 'EOF'
---
title: "My DevOps Expert"
description: "Custom DevOps agent with my preferences"
---

# My DevOps Expert

Custom agent configuration for infrastructure work.
EOF

cat > ~/.claude/skills/my-docker-skill.md << 'EOF'
---
title: "My Docker Skill"
description: "Custom Docker commands and shortcuts"
---

# My Docker Skill

Custom Docker utilities.
EOF

# Create old AIDA templates (flat structure, no namespace)
# These simulate templates from v0.1.x
cat > ~/.claude/commands/start-work.md << 'EOF'
# Start Work (v0.1.x)
Old version of start-work command.
EOF

cat > ~/.claude/agents/secretary.md << 'EOF'
# Secretary (v0.1.x)
Old version of secretary agent.
EOF

# Verify v0.1.x structure created
echo "Created v0.1.x structure:"
ls -R ~/.claude/
```

**Step 2: Install v0.2.0 (Simulates Upgrade)**

```bash
# Clone v0.2.0 (or git pull if already exists)
git clone https://github.com/oakensoul/claude-personal-assistant.git ~/.aida
cd ~/.aida

# Run installer (this triggers upgrade logic)
./install.sh
```

**Step 3: Observe Upgrade Process**

Watch for these messages during installation:

- Detection of existing installation
- Backup of old templates
- Migration to namespace structure
- Preservation of user content

#### Verification Checklist

**User Content Preserved** (CRITICAL):

- [ ] User command preserved: `test -f ~/.claude/commands/my-deploy.md && echo "✓ PASS" || echo "✗ FAIL"`
- [ ] User command unchanged: `grep "Custom deployment workflow" ~/.claude/commands/my-deploy.md`
- [ ] User agent preserved: `test -f ~/.claude/agents/my-devops-expert.md && echo "✓ PASS" || echo "✗ FAIL"`
- [ ] User agent unchanged: `grep "Custom agent configuration" ~/.claude/agents/my-devops-expert.md`
- [ ] User skill preserved: `test -f ~/.claude/skills/my-docker-skill.md && echo "✓ PASS" || echo "✗ FAIL"`
- [ ] User skill unchanged: `grep "Custom Docker utilities" ~/.claude/skills/my-docker-skill.md`

**Old Templates Backed Up**:

- [ ] Backup directory created: `ls -d ~/.claude/commands/.backup.* 2>/dev/null`
- [ ] Old start-work backed up: `find ~/.claude/commands/.backup.* -name "start-work.md" 2>/dev/null`
- [ ] Old secretary backed up: `find ~/.claude/agents/.backup.* -name "secretary.md" 2>/dev/null`
- [ ] Backup timestamp is recent: Check backup directory name includes current date

**New Templates in Namespace**:

- [ ] New command namespace exists: `test -d ~/.claude/commands/.aida && echo "✓ PASS" || echo "✗ FAIL"`
- [ ] New start-work template: `test -d ~/.claude/commands/.aida/start-work && echo "✓ PASS" || echo "✗ FAIL"`
- [ ] New agent namespace exists: `test -d ~/.claude/agents/.aida && echo "✓ PASS" || echo "✗ FAIL"`
- [ ] New secretary template: `test -f ~/.claude/agents/.aida/secretary.md && echo "✓ PASS" || echo "✗ FAIL"`

**No Nested Directories** (verify flat structure for user content):

- [ ] User content is in parent directory (not nested): `ls ~/.claude/commands/my-*.md`
- [ ] AIDA content is in `.aida/` subdirectory: `ls ~/.claude/commands/.aida/`
- [ ] No accidental nesting: `find ~/.claude/commands -name "*.aida" -type d | wc -l` (should be 0)

**Configuration Updated**:

- [ ] Config exists: `test -f ~/.claude/aida-config.json && echo "✓ PASS" || echo "✗ FAIL"`
- [ ] Version updated to v0.2.0: `jq -r '.version' ~/.claude/aida-config.json`
- [ ] Config is valid JSON: `jq . ~/.claude/aida-config.json > /dev/null && echo "✓ PASS" || echo "✗ FAIL"`

**Verify Directory Structure**:

```bash
# Should show clear separation between user content and AIDA namespace
tree -L 2 ~/.claude/commands/

# Expected structure:
# ~/.claude/commands/
# ├── .aida/              <- AIDA framework templates
# │   └── start-work/
# ├── .backup.YYYYMMDD_HHMMSS/  <- Old templates
# │   └── start-work.md
# └── my-deploy.md        <- User content
```

- [ ] Structure matches expected layout
- [ ] Clear separation between user and AIDA content

#### Expected Results

**Zero Data Loss**:

- All user-created content preserved exactly as it was
- No modifications to user files
- No accidental overwrites

**Clean Migration**:

- Old templates backed up with timestamp
- New templates installed in namespace
- Clear separation between old and new

**User Experience**:

- Clear messages about what's happening
- Backup location shown in output
- No scary error messages
- Upgrade completes successfully

**Post-Upgrade State**:

- User can continue using custom commands/agents
- AIDA templates updated to v0.2.0
- Config reflects new version
- System fully functional

#### Common Issues to Watch For

- **User content overwritten**: Should NEVER happen
- **Missing backups**: Old templates must be backed up
- **Nested directories**: User content should stay in parent directory
- **Broken content**: User files should be unchanged
- **Missing namespace**: `.aida/` directories must be created

### Scenario 4: Namespace Isolation Verification

**Objective**: Verify user content is completely isolated from framework updates.

**Time Estimate**: 5-10 minutes

**Prerequisites**: Completed installation (normal or dev mode)

**Critical Test**: This ensures future updates won't affect user content.

#### Steps

**Step 1: Create User Content Post-Installation**

```bash
# Create user content in parent directories
cat > ~/.claude/commands/user-deploy.md << 'EOF'
---
title: "User Deploy Command"
description: "My custom deployment workflow"
---

# User Deploy

My deployment steps.
EOF

cat > ~/.claude/agents/user-expert.md << 'EOF'
---
title: "User Expert Agent"
description: "My custom expert agent"
---

# User Expert

My expert agent configuration.
EOF

# Verify user content created
ls -la ~/.claude/commands/user-*.md
ls -la ~/.claude/agents/user-*.md
```

**Step 2: Record Content State**

```bash
# Create checksums to verify files don't change
md5sum ~/.claude/commands/user-deploy.md > /tmp/user-content-before.md5
md5sum ~/.claude/agents/user-expert.md >> /tmp/user-content-before.md5

# Display checksums
cat /tmp/user-content-before.md5
```

**Step 3: Simulate Framework Update**

```bash
# Navigate to AIDA installation
cd ~/.aida

# Make a change to a framework template (simulate upstream update)
echo "# Updated Documentation" >> templates/commands/start-work/README.md

# Reinstall (simulates framework update)
./install.sh
```

**Step 4: Verify Content Unchanged**

```bash
# Create new checksums
md5sum ~/.claude/commands/user-deploy.md > /tmp/user-content-after.md5
md5sum ~/.claude/agents/user-expert.md >> /tmp/user-content-after.md5

# Compare checksums (should be identical)
diff /tmp/user-content-before.md5 /tmp/user-content-after.md5
echo $?  # Should be 0 (no differences)
```

#### Verification Checklist

**User Content Isolation**:

- [ ] User content unchanged: `diff` shows no differences (exit code 0)
- [ ] User command still exists: `test -f ~/.claude/commands/user-deploy.md && echo "✓ PASS" || echo "✗ FAIL"`
- [ ] User agent still exists: `test -f ~/.claude/agents/user-expert.md && echo "✓ PASS" || echo "✗ FAIL"`
- [ ] File contents identical: Checksums match exactly

**Framework Updates Applied**:

- [ ] AIDA templates updated: `grep "Updated Documentation" ~/.claude/commands/.aida/start-work/README.md`
- [ ] Framework changes visible in namespace: New content appears in `.aida/` directory

**No Accidental Overwrites**:

- [ ] No prompts about conflicts: Installation should not ask about user files
- [ ] No warnings about existing files: User content should be ignored
- [ ] No backup of user content: Only AIDA templates should be backed up

**Namespace Separation**:

- [ ] User content in parent directory: `ls ~/.claude/commands/*.md` (should show user files)
- [ ] AIDA content in subdirectory: `ls ~/.claude/commands/.aida/` (should show framework files)
- [ ] No mixing of content: Clear separation between user and framework

#### Expected Results

**Complete Isolation**:

- User content never touched by framework updates
- Framework updates only modify `.aida/` namespace
- No conflicts or collisions

**Predictable Behavior**:

- Reinstalling AIDA is safe (won't affect user work)
- Users can update framework without fear
- Clear separation of concerns

**User Experience**:

- No scary warnings about overwrites
- No confusing prompts
- Silent, smooth updates to framework
- User content completely protected

#### Common Issues to Watch For

- **User content modified**: Should NEVER happen - critical bug
- **Prompts about conflicts**: Should not prompt for user files
- **Mixed content**: User files in `.aida/` or vice versa
- **Backup of user content**: Should not back up user files (only AIDA templates)

### Scenario 5: Config Aggregator Testing

**Objective**: Verify configuration aggregator works correctly and provides fast, reliable access to configuration.

**Time Estimate**: 5 minutes

**Prerequisites**: Completed installation

**Background**: The config aggregator (`aida-config-helper.sh`) provides centralized access to AIDA configuration with caching for performance.

#### Steps

**Step 1: Test Config Validation**

```bash
# Validate configuration file
~/.aida/lib/aida-config-helper.sh --validate

# Check exit code (should be 0 for success)
echo "Exit code: $?"
```

Expected output:

```text
Configuration validated successfully
```

**Step 2: Test Single Key Retrieval**

```bash
# Retrieve specific configuration values
~/.aida/lib/aida-config-helper.sh --key paths.aida_home
~/.aida/lib/aida-config-helper.sh --key paths.claude_config_dir
~/.aida/lib/aida-config-helper.sh --key user.assistant_name
~/.aida/lib/aida-config-helper.sh --key user.personality
```

**Step 3: Test Full Config Retrieval**

```bash
# Get complete configuration
~/.aida/lib/aida-config-helper.sh | jq .

# Verify it's valid JSON
~/.aida/lib/aida-config-helper.sh | jq . > /dev/null
echo "Valid JSON: $?"  # Should be 0
```

**Step 4: Test Performance**

```bash
# Measure initial call (cold cache)
time ~/.aida/lib/aida-config-helper.sh --key paths.aida_home > /dev/null

# Measure cached call (warm cache)
time ~/.aida/lib/aida-config-helper.sh --key paths.aida_home > /dev/null

# Second call should be significantly faster
```

**Step 5: Test Error Handling**

```bash
# Test invalid key
~/.aida/lib/aida-config-helper.sh --key invalid.key.path
echo "Exit code: $?"  # Should be non-zero (error)

# Test with corrupted config
cp ~/.claude/aida-config.json ~/.claude/aida-config.json.backup
echo "invalid json" > ~/.claude/aida-config.json

~/.aida/lib/aida-config-helper.sh --validate
echo "Exit code: $?"  # Should be non-zero (error)

# Restore valid config
mv ~/.claude/aida-config.json.backup ~/.claude/aida-config.json
```

#### Verification Checklist

**Validation**:

- [ ] Validation succeeds on valid config: Exit code 0
- [ ] Validation message clear: Shows success message
- [ ] Validation fails on invalid config: Exit code non-zero

**Key Retrieval**:

- [ ] `paths.aida_home` returns correct path: Should show `~/.aida` or dev path
- [ ] `paths.claude_config_dir` returns correct path: Should show `~/.claude`
- [ ] `user.assistant_name` returns correct name: Should show configured name (e.g., JARVIS)
- [ ] `user.personality` returns correct personality: Should show configured personality

**Full Config**:

- [ ] Full config is valid JSON: `jq` parses without error
- [ ] All expected top-level keys present:
  - [ ] `version`
  - [ ] `paths`
  - [ ] `user`
  - [ ] `installation`
- [ ] Path values are absolute: Start with `/` or `~`

**Performance**:

- [ ] Initial call completes quickly: < 500ms (cold cache)
- [ ] Cached call very fast: < 50ms (warm cache)
- [ ] No noticeable delays: Response feels instant

**Error Handling**:

- [ ] Invalid key returns error: Non-zero exit code
- [ ] Invalid key shows helpful message: Indicates what went wrong
- [ ] Corrupted JSON detected: Validation fails
- [ ] Error messages clear: User understands what's wrong

**Config Content**:

```bash
# Verify all expected fields present
CONFIG=$(~/.aida/lib/aida-config-helper.sh)
echo "$CONFIG" | jq -e '.version' > /dev/null && echo "✓ version present" || echo "✗ version missing"
echo "$CONFIG" | jq -e '.paths.aida_home' > /dev/null && echo "✓ aida_home present" || echo "✗ aida_home missing"
echo "$CONFIG" | jq -e '.paths.claude_config_dir' > /dev/null && echo "✓ claude_config_dir present" || echo "✗ claude_config_dir missing"
echo "$CONFIG" | jq -e '.user.assistant_name' > /dev/null && echo "✓ assistant_name present" || echo "✗ assistant_name missing"
echo "$CONFIG" | jq -e '.user.personality' > /dev/null && echo "✓ personality present" || echo "✗ personality missing"
```

#### Expected Results

**Fast Access**:

- First call: < 500ms
- Subsequent calls: < 50ms (cached)
- No noticeable performance impact

**Reliable**:

- Always returns valid JSON
- Always validates correctly
- Handles errors gracefully

**Complete**:

- All configuration values accessible
- Nested keys work correctly
- Paths are resolved

**User-Friendly**:

- Clear error messages
- Helpful validation output
- Easy to debug issues

#### Common Issues to Watch For

- **Slow performance**: Should be fast, especially cached calls
- **Invalid JSON**: Config must always be valid
- **Missing keys**: All expected keys must be present
- **Path issues**: Paths should be absolute and correct
- **Cache issues**: Cached values should be current

## Regression Testing

### Purpose

After ANY code changes to the installer or templates, verify that existing functionality still works correctly. This prevents new features from breaking existing behavior.

### When to Run Regression Tests

Execute full regression suite:

- After modifying installer scripts
- After changing template structure
- After updating configuration logic
- After refactoring any installer component
- Before committing changes
- Before releasing new versions

### Quick Regression Checklist

Run these scenarios in order (stop if any fail):

1. **Fresh Installation (Normal Mode)** - Scenario 1
   - [ ] Install completes successfully
   - [ ] All files created correctly
   - [ ] Config is valid
   - [ ] Namespaces created

2. **Fresh Installation (Dev Mode)** - Scenario 2
   - [ ] Install with `--dev` works
   - [ ] Symlinks created correctly
   - [ ] Config copied (not symlinked)

3. **Upgrade Path** - Scenario 3
   - [ ] User content preserved
   - [ ] Old templates backed up
   - [ ] New templates installed

4. **Namespace Isolation** - Scenario 4
   - [ ] User content protected
   - [ ] Framework updates independent

5. **Config Aggregator** - Scenario 5
   - [ ] Validation works
   - [ ] Key retrieval works
   - [ ] Performance acceptable

### Full Regression Test Script

```bash
#!/bin/bash
# Save as test-regression.sh

set -euo pipefail

echo "=== AIDA Regression Test Suite ==="

# Clean environment
rm -rf ~/.aida ~/.claude ~/CLAUDE.md

# Test 1: Fresh install (normal mode)
echo "Test 1: Fresh Installation (Normal Mode)"
git clone https://github.com/oakensoul/claude-personal-assistant.git ~/.aida
cd ~/.aida
./install.sh <<EOF
JARVIS
professional
EOF
test -d ~/.aida && echo "✓ Framework installed" || exit 1
test -d ~/.claude && echo "✓ Config created" || exit 1
test -f ~/CLAUDE.md && echo "✓ Entry point created" || exit 1
~/.aida/lib/aida-config-helper.sh --validate || exit 1
echo "✓ Test 1 PASSED"

# Clean for next test
rm -rf ~/.aida ~/.claude ~/CLAUDE.md

# Test 2: Fresh install (dev mode)
echo "Test 2: Fresh Installation (Dev Mode)"
mkdir -p ~/dev
git clone https://github.com/oakensoul/claude-personal-assistant.git ~/dev/aida
cd ~/dev/aida
./install.sh --dev <<EOF
JARVIS
professional
EOF
test -L ~/.aida && echo "✓ Framework symlinked" || exit 1
test -L ~/.claude/commands/.aida/start-work && echo "✓ Templates symlinked" || exit 1
test ! -L ~/.claude/aida-config.json && echo "✓ Config copied" || exit 1
echo "✓ Test 2 PASSED"

# Clean for next test
rm -rf ~/.aida ~/.claude ~/CLAUDE.md ~/dev/aida

# Test 3: Upgrade from v0.1.x
echo "Test 3: Upgrade from v0.1.x"
mkdir -p ~/.claude/commands ~/.claude/agents
echo "# User Command" > ~/.claude/commands/my-cmd.md
echo "# Old Template" > ~/.claude/commands/start-work.md
git clone https://github.com/oakensoul/claude-personal-assistant.git ~/.aida
cd ~/.aida
./install.sh <<EOF
JARVIS
professional
EOF
test -f ~/.claude/commands/my-cmd.md && echo "✓ User content preserved" || exit 1
test -d ~/.claude/commands/.backup.* && echo "✓ Old templates backed up" || exit 1
test -d ~/.claude/commands/.aida && echo "✓ New namespace created" || exit 1
echo "✓ Test 3 PASSED"

echo "=== All Regression Tests PASSED ==="
```

Make executable and run:

```bash
chmod +x test-regression.sh
./test-regression.sh
```

### Expected Regression Test Results

All tests should pass with no errors:

- ✓ Test 1 PASSED
- ✓ Test 2 PASSED
- ✓ Test 3 PASSED
- === All Regression Tests PASSED ===

If ANY test fails:

1. Stop and investigate immediately
2. Do NOT commit changes
3. Fix the regression before proceeding
4. Re-run full suite after fix

## Cross-Platform Testing

### Platform Coverage

AIDA officially supports:

- **macOS 13** (Ventura)
- **macOS 14** (Sonoma)
- **macOS 15** (Sequoia) - if available
- **Ubuntu 22.04 LTS**
- **Ubuntu 24.04 LTS**
- **Debian 12** (Bookworm)

### Testing Requirements

Before release, verify ALL scenarios on ALL platforms:

- Scenario 1: Fresh Installation (Normal Mode)
- Scenario 2: Fresh Installation (Dev Mode)
- Scenario 3: Upgrade from v0.1.x
- Scenario 4: Namespace Isolation
- Scenario 5: Config Aggregator

### Platform-Specific Checks

#### macOS-Specific

**Bash Version**:

```bash
# macOS ships with old Bash 3.2 due to GPL3 licensing
bash --version  # Should work with 3.2+
```

**Symlink Behavior**:

```bash
# Test symlink creation and resolution
ln -s ~/dev/aida ~/.aida
readlink ~/.aida  # macOS readlink has no -f flag
```

**Permissions**:

```bash
# macOS stat format different from Linux
stat -f "%A" ~/.claude  # macOS format
```

**Checks**:

- [ ] Works with Bash 3.2 (macOS default)
- [ ] Symlinks created correctly
- [ ] `readlink` works without `-f` flag
- [ ] Permissions set correctly (755 for directories)
- [ ] No GNU-specific tools required (except in Homebrew)

#### Ubuntu-Specific

**Bash Version**:

```bash
# Ubuntu has modern Bash 4.x or 5.x
bash --version  # Should be 4.0+
```

**Symlink Behavior**:

```bash
# Test symlink creation and resolution
ln -s ~/dev/aida ~/.aida
readlink -f ~/.aida  # Linux readlink supports -f
```

**Permissions**:

```bash
# Linux stat format different from macOS
stat -c "%a" ~/.claude  # Linux format
```

**Checks**:

- [ ] Works with Bash 4.x/5.x
- [ ] Symlinks created correctly
- [ ] `readlink -f` works (if used)
- [ ] Permissions set correctly (755 for directories)
- [ ] Standard GNU tools available

#### Debian-Specific

Same as Ubuntu-specific checks (Debian and Ubuntu are similar).

**Additional Checks**:

- [ ] Works on Debian 12 (Bookworm)
- [ ] All dependencies available in default repos
- [ ] No distribution-specific issues

### Quick Cross-Platform Test

Use Docker to test multiple platforms quickly:

```bash
# Test all platforms
./.github/testing/test-install.sh

# Test specific platform
./.github/testing/test-install.sh --env ubuntu-22
./.github/testing/test-install.sh --env ubuntu-24
./.github/testing/test-install.sh --env debian-12

# Verbose output
./.github/testing/test-install.sh --verbose

# Test with cleanup
./.github/testing/test-install.sh --cleanup
```

### Cross-Platform Checklist

Before release, verify on each platform:

#### macOS 13 (Ventura)

- [ ] Fresh install (normal mode)
- [ ] Fresh install (dev mode)
- [ ] Upgrade from v0.1.x
- [ ] Namespace isolation
- [ ] Config aggregator

#### macOS 14 (Sonoma)

- [ ] Fresh install (normal mode)
- [ ] Fresh install (dev mode)
- [ ] Upgrade from v0.1.x
- [ ] Namespace isolation
- [ ] Config aggregator

#### Ubuntu 22.04 LTS

- [ ] Fresh install (normal mode)
- [ ] Fresh install (dev mode)
- [ ] Upgrade from v0.1.x
- [ ] Namespace isolation
- [ ] Config aggregator

#### Ubuntu 24.04 LTS

- [ ] Fresh install (normal mode)
- [ ] Fresh install (dev mode)
- [ ] Upgrade from v0.1.x
- [ ] Namespace isolation
- [ ] Config aggregator

#### Debian 12

- [ ] Fresh install (normal mode)
- [ ] Fresh install (dev mode)
- [ ] Upgrade from v0.1.x
- [ ] Namespace isolation
- [ ] Config aggregator

### Common Cross-Platform Issues

**Path Handling**:

- **Issue**: Spaces in paths (e.g., `/Users/John Doe/`)
- **Test**: Create test user with space in name
- **Fix**: Always quote paths in scripts

**Bash Version**:

- **Issue**: Using Bash 4+ features on macOS (has Bash 3.2)
- **Test**: Run on macOS with default Bash
- **Fix**: Use POSIX-compatible features only

**GNU vs BSD Tools**:

- **Issue**: Different flags for `stat`, `readlink`, `sed`, etc.
- **Test**: Compare behavior on macOS vs Linux
- **Fix**: Use portable flags or detect OS

**Line Endings**:

- **Issue**: CRLF (Windows) vs LF (Unix) line endings
- **Test**: Check files have LF line endings
- **Fix**: Configure Git to use LF: `.gitattributes`

## User Experience Testing

### Purpose

Evaluate the quality of the user experience beyond functional correctness. This tests whether the installer is pleasant, clear, and helpful to use.

### UX Evaluation Criteria

#### Installation Speed

**Target**: < 30 seconds on modern hardware

**Test**:

```bash
# Time the full installation
time ./install.sh <<EOF
JARVIS
professional
EOF
```

**Evaluation**:

- [ ] Installation completes in < 30 seconds
- [ ] No long pauses or timeouts
- [ ] Progress feels continuous (not stuck)
- [ ] No unnecessary delays

**Rating**:

- **Excellent**: < 15 seconds
- **Good**: 15-30 seconds
- **Acceptable**: 30-60 seconds
- **Poor**: > 60 seconds

#### Progress Messages

**Evaluation**:

- [ ] Clear messages about what's happening
- [ ] Messages appear at appropriate times
- [ ] Not too verbose (no spam)
- [ ] Not too quiet (user knows it's working)
- [ ] Messages are grammatically correct
- [ ] Messages are easy to understand

**Test Messages**:

- Installation start message
- Directory creation messages
- Template copying/symlinking messages
- Configuration messages
- Completion message

**Rating**:

- **Excellent**: Always clear what's happening
- **Good**: Mostly clear, occasional confusion
- **Acceptable**: Understandable but could be better
- **Poor**: Confusing or missing messages

#### Error Messages

**Test Error Scenarios**:

```bash
# Missing dependencies
# (Temporarily rename jq to simulate missing)
mv $(which jq) $(which jq).backup
./install.sh
mv $(which jq).backup $(which jq)

# Permission errors
# (Try installing to protected directory)
./install.sh --aida-home /usr/local/aida

# Invalid input
# (Provide invalid personality)
./install.sh <<EOF
JARVIS
invalid-personality
EOF
```

**Evaluation**:

- [ ] Error messages are clear
- [ ] Errors explain WHAT went wrong
- [ ] Errors explain HOW to fix it
- [ ] No cryptic error codes
- [ ] No scary stack traces
- [ ] Exit codes are appropriate (non-zero on error)

**Rating**:

- **Excellent**: Clear, actionable, helpful
- **Good**: Clear but could be more helpful
- **Acceptable**: Understandable with effort
- **Poor**: Confusing or misleading

#### Interactive Prompts

**Evaluation**:

- [ ] Prompts are clear and concise
- [ ] Prompts explain what input is expected
- [ ] Default values shown clearly
- [ ] Help text available if needed
- [ ] Validation provides helpful feedback
- [ ] Easy to understand what to do

**Test Prompts**:

- Assistant name prompt
- Personality selection prompt
- Confirmation prompts (if any)

**Rating**:

- **Excellent**: Immediately obvious what to do
- **Good**: Clear with minimal thought
- **Acceptable**: Requires some thought
- **Poor**: Confusing or unclear

#### Help Text

**Test**:

```bash
# Display help text
./install.sh --help
```

**Evaluation**:

- [ ] Help text is comprehensive
- [ ] All flags documented
- [ ] Examples provided
- [ ] Easy to read and scan
- [ ] Accurate and up-to-date

**Rating**:

- **Excellent**: Complete, clear, helpful examples
- **Good**: Complete but could be clearer
- **Acceptable**: Basic but usable
- **Poor**: Missing info or confusing

#### Success Message

**Evaluation**:

- [ ] Success clearly communicated
- [ ] Next steps provided
- [ ] Helpful suggestions included
- [ ] Not too verbose
- [ ] Professional and friendly tone

**Rating**:

- **Excellent**: Clear, helpful, actionable
- **Good**: Clear but could be more helpful
- **Acceptable**: Basic success message
- **Poor**: Unclear or missing

### UX Test Checklist

Overall user experience evaluation:

- [ ] Installation speed: **[Rating]**
- [ ] Progress messages: **[Rating]**
- [ ] Error messages: **[Rating]**
- [ ] Interactive prompts: **[Rating]**
- [ ] Help text: **[Rating]**
- [ ] Success message: **[Rating]**

**Overall UX Rating**: **[Excellent/Good/Acceptable/Poor]**

### UX Improvement Areas

Document any UX issues found:

1. **Issue**: [Description]
   - **Severity**: [Critical/High/Medium/Low]
   - **Suggestion**: [How to improve]

2. **Issue**: [Description]
   - **Severity**: [Critical/High/Medium/Low]
   - **Suggestion**: [How to improve]

## Smoke Tests

### Purpose

Quick verification that the installation is working correctly. Run these after any installation to verify basic functionality.

### Quick Smoke Test

Run all smoke tests in sequence:

```bash
echo "=== AIDA Installation Smoke Tests ==="

# Test 1: Framework installed
ls ~/.aida > /dev/null && echo "✓ Framework installed" || echo "✗ Framework NOT installed"

# Test 2: Config directory exists
ls ~/.claude > /dev/null && echo "✓ Config directory exists" || echo "✗ Config directory MISSING"

# Test 3: Entry point created
test -f ~/CLAUDE.md && echo "✓ Entry point created" || echo "✗ Entry point MISSING"

# Test 4: Config valid
~/.aida/lib/aida-config-helper.sh --validate > /dev/null && echo "✓ Config valid" || echo "✗ Config INVALID"

# Test 5: Namespace exists
test -d ~/.claude/commands/.aida && echo "✓ Namespace exists" || echo "✗ Namespace MISSING"

# Test 6: Version correct
VERSION=$(cat ~/.aida/VERSION 2>/dev/null)
[ "$VERSION" = "v0.2.0" ] && echo "✓ Version correct (v0.2.0)" || echo "✗ Version INCORRECT ($VERSION)"

# Test 7: Permissions correct
PERMS=$(stat -c "%a" ~/.claude 2>/dev/null || stat -f "%A" ~/.claude 2>/dev/null)
[ "$PERMS" = "755" ] && echo "✓ Permissions correct (755)" || echo "✗ Permissions INCORRECT ($PERMS)"

echo "=== Smoke Tests Complete ==="
```

### Expected Smoke Test Results

All tests should pass:

```text
=== AIDA Installation Smoke Tests ===
✓ Framework installed
✓ Config directory exists
✓ Entry point created
✓ Config valid
✓ Namespace exists
✓ Version correct (v0.2.0)
✓ Permissions correct (755)
=== Smoke Tests Complete ===
```

If ANY test fails, investigate immediately before proceeding.

### Individual Smoke Tests

#### Test 1: Framework Installed

```bash
ls ~/.aida > /dev/null && echo "✓ PASS" || echo "✗ FAIL"
```

**Verifies**: `~/.aida/` directory exists

#### Test 2: Config Directory Exists

```bash
ls ~/.claude > /dev/null && echo "✓ PASS" || echo "✗ FAIL"
```

**Verifies**: `~/.claude/` directory exists

#### Test 3: Entry Point Created

```bash
test -f ~/CLAUDE.md && echo "✓ PASS" || echo "✗ FAIL"
```

**Verifies**: `~/CLAUDE.md` file exists

#### Test 4: Config Valid

```bash
~/.aida/lib/aida-config-helper.sh --validate > /dev/null && echo "✓ PASS" || echo "✗ FAIL"
```

**Verifies**: Configuration is valid JSON and contains required fields

#### Test 5: Namespace Exists

```bash
test -d ~/.claude/commands/.aida && echo "✓ PASS" || echo "✗ FAIL"
```

**Verifies**: Namespace directory structure created

#### Test 6: Version Correct

```bash
VERSION=$(cat ~/.aida/VERSION 2>/dev/null)
[ "$VERSION" = "v0.2.0" ] && echo "✓ PASS" || echo "✗ FAIL (got: $VERSION)"
```

**Verifies**: Correct version installed

#### Test 7: Permissions Correct

```bash
# Linux
PERMS=$(stat -c "%a" ~/.claude 2>/dev/null)
# macOS
PERMS=$(stat -f "%A" ~/.claude 2>/dev/null)

[ "$PERMS" = "755" ] && echo "✓ PASS" || echo "✗ FAIL (got: $PERMS)"
```

**Verifies**: Directory permissions are correct

### Smoke Test Automation

Save smoke tests as a script:

```bash
# Save to ~/.aida/scripts/smoke-test.sh
#!/bin/bash

set -euo pipefail

echo "=== AIDA Installation Smoke Tests ==="

# Test framework
test -d ~/.aida || { echo "✗ Framework NOT installed"; exit 1; }
echo "✓ Framework installed"

# Test config
test -d ~/.claude || { echo "✗ Config directory MISSING"; exit 1; }
echo "✓ Config directory exists"

# Test entry point
test -f ~/CLAUDE.md || { echo "✗ Entry point MISSING"; exit 1; }
echo "✓ Entry point created"

# Test config validity
~/.aida/lib/aida-config-helper.sh --validate > /dev/null || { echo "✗ Config INVALID"; exit 1; }
echo "✓ Config valid"

# Test namespace
test -d ~/.claude/commands/.aida || { echo "✗ Namespace MISSING"; exit 1; }
echo "✓ Namespace exists"

# Test version
VERSION=$(cat ~/.aida/VERSION 2>/dev/null)
[ "$VERSION" = "v0.2.0" ] || { echo "✗ Version INCORRECT ($VERSION)"; exit 1; }
echo "✓ Version correct (v0.2.0)"

echo "=== All Smoke Tests PASSED ==="
```

Run smoke tests:

```bash
chmod +x ~/.aida/scripts/smoke-test.sh
~/.aida/scripts/smoke-test.sh
```

## Documenting Issues

### When You Find a Bug

If you discover a bug during manual testing, document it thoroughly:

1. **Stop Testing**: Don't continue until you document the issue
2. **Document Steps**: Write exact steps to reproduce
3. **Capture Evidence**: Save error messages, screenshots, logs
4. **Note Environment**: Document platform, versions, configuration
5. **Check Automated Tests**: Verify if automated tests caught it
6. **Create Issue**: File GitHub issue with all information

### Bug Report Template

```markdown
## Bug Description

[Clear description of what went wrong]

## Steps to Reproduce

1. [First step]
2. [Second step]
3. [Third step]

## Expected Behavior

[What should have happened]

## Actual Behavior

[What actually happened]

## Environment

- **Platform**: [macOS 14 / Ubuntu 22.04 / etc.]
- **Bash Version**: [Run `bash --version`]
- **Test Scenario**: [Scenario 1 / Scenario 2 / etc.]
- **Installation Mode**: [Normal / Dev]

## Error Messages

```text
[Paste complete error messages here]
```

## Logs/Output

```text
[Paste relevant terminal output]
```

## Automated Test Coverage

- [ ] Automated tests caught this issue
- [ ] Automated tests did NOT catch this issue (regression)

## Additional Context

[Any other relevant information]

## Severity

- [ ] Critical - Blocks installation
- [ ] High - Major functionality broken
- [ ] Medium - Feature not working as expected
- [ ] Low - Minor issue or cosmetic

## Suggested Fix

[If you have ideas for fixing it]
```

### Example Bug Report

```markdown
## Bug Description

User content is overwritten during upgrade from v0.1.x

## Steps to Reproduce

1. Create user content: `echo "# My Command" > ~/.claude/commands/my-cmd.md`
2. Create old AIDA template: `echo "# Old" > ~/.claude/commands/start-work.md`
3. Run installer: `./install.sh`
4. Check user content: `cat ~/.claude/commands/my-cmd.md`

## Expected Behavior

User content should be preserved unchanged.

## Actual Behavior

User content is deleted or overwritten.

## Environment

- **Platform**: macOS 14.1 (Sonoma)
- **Bash Version**: 3.2.57(1)-release
- **Test Scenario**: Scenario 3 (Upgrade from v0.1.x)
- **Installation Mode**: Normal

## Error Messages

No error messages shown.

## Logs/Output

```text
Installing AIDA...
Creating directory structure...
Copying templates...
Done!
```

## Automated Test Coverage

- [ ] Automated tests caught this issue
- [x] Automated tests did NOT catch this issue (regression)

## Additional Context

This is a critical regression. Automated tests should verify user content preservation.

## Severity

- [x] Critical - Blocks installation
- [ ] High - Major functionality broken
- [ ] Medium - Feature not working as expected
- [ ] Low - Minor issue or cosmetic

## Suggested Fix

Add check in installer to preserve files that don't start with `.` or `start-work.md`.
```

### Verifying Automated Test Coverage

When you find a bug, check if automated tests should have caught it:

```bash
# Run relevant automated tests
cd ~/.aida
./scripts/run-bats-tests.sh test/installer-core.bats
./scripts/run-bats-tests.sh test/namespace-isolation.bats

# Check if test exists for this scenario
grep -r "user content" test/
```

If automated tests don't cover this scenario:

1. File bug report
2. Note that test coverage is missing
3. Suggest adding automated test for this case

## Test Checklist Summary

### Pre-Release Testing Checklist

Before releasing v0.2.0, complete ALL items:

#### Functional Testing

- [ ] **Scenario 1**: Fresh Installation (Normal Mode)
- [ ] **Scenario 2**: Fresh Installation (Dev Mode)
- [ ] **Scenario 3**: Upgrade from v0.1.x
- [ ] **Scenario 4**: Namespace Isolation
- [ ] **Scenario 5**: Config Aggregator

#### Cross-Platform Testing

- [ ] macOS 13 (Ventura) - All scenarios
- [ ] macOS 14 (Sonoma) - All scenarios
- [ ] Ubuntu 22.04 LTS - All scenarios
- [ ] Ubuntu 24.04 LTS - All scenarios
- [ ] Debian 12 - All scenarios

#### Regression Testing

- [ ] All regression tests pass
- [ ] No existing functionality broken
- [ ] Upgrade path works correctly
- [ ] User content protected

#### User Experience Testing

- [ ] Installation speed acceptable (< 30 seconds)
- [ ] Progress messages clear and helpful
- [ ] Error messages clear and actionable
- [ ] Interactive prompts intuitive
- [ ] Help text comprehensive
- [ ] Success message informative

#### Smoke Tests

- [ ] All smoke tests pass on all platforms
- [ ] Quick verification successful
- [ ] No obvious issues

#### Documentation

- [ ] All bugs documented
- [ ] GitHub issues created for any bugs found
- [ ] Test results recorded
- [ ] Known issues documented (if any)

#### Automated Tests

- [ ] All automated tests pass (273 tests)
- [ ] Automated tests run on all platforms
- [ ] No test failures or skips
- [ ] Coverage gaps identified and documented

### Sign-Off

**Tester**: [Your name]

**Date**: [Test completion date]

**Result**: [PASS / FAIL]

**Notes**: [Any additional notes or concerns]

## Appendix: Test Data

### Sample User Content for Testing

Use these snippets to create realistic test data:

#### Sample User Command

```bash
cat > ~/.claude/commands/deploy-prod.md << 'EOF'
---
title: "Production Deployment"
description: "Deploy application to production environment"
category: "deployment"
tags: ["deploy", "production", "automation"]
last_updated: "2025-10-19"
status: "published"
audience: "developers"
---

# Production Deployment

Automated production deployment workflow.

## Prerequisites

- Production credentials configured
- All tests passing
- Approval from team lead

## Steps

1. Build production artifacts
2. Run security scans
3. Deploy to staging for validation
4. Deploy to production
5. Run smoke tests
6. Monitor metrics

## Rollback

If issues detected:
1. Trigger automated rollback
2. Notify team
3. Investigate issues
EOF
```

#### Sample User Agent

```bash
cat > ~/.claude/agents/kubernetes-expert.md << 'EOF'
---
title: "Kubernetes Expert"
description: "Expert agent for Kubernetes cluster management"
category: "guide"
tags: ["agent", "kubernetes", "devops"]
last_updated: "2025-10-19"
status: "published"
audience: "developers"
---

# Kubernetes Expert Agent

Specialized agent for Kubernetes operations and troubleshooting.

## Expertise

- Cluster management and scaling
- Deployment strategies
- Service mesh configuration
- Debugging pod issues
- Performance optimization

## Knowledge Base

Custom knowledge for our Kubernetes setup:
- Cluster: production-us-east-1
- Namespace: app-production
- Service mesh: Istio
EOF
```

#### Sample User Skill

```bash
cat > ~/.claude/skills/database-backup.md << 'EOF'
---
title: "Database Backup Skill"
description: "Automated database backup procedures"
category: "guide"
tags: ["skill", "database", "backup"]
last_updated: "2025-10-19"
status: "published"
audience: "developers"
---

# Database Backup Skill

Automated backup procedures for production databases.

## Backup Commands

```bash
# Full backup
pg_dump -h prod-db.example.com -U app_user -d production > backup.sql

# Compressed backup
pg_dump -h prod-db.example.com -U app_user -d production | gzip > backup.sql.gz

# Restore
psql -h prod-db.example.com -U app_user -d production < backup.sql
```

## Schedule

- Full backup: Daily at 2 AM UTC
- Incremental: Every 6 hours
- Retention: 30 days
EOF
```

### Creating Bulk Test Data

Create multiple test files at once:

```bash
# Create multiple user commands
for i in {1..5}; do
  cat > ~/.claude/commands/user-command-$i.md << EOF
---
title: "User Command $i"
description: "Test user command $i"
category: "guide"
tags: ["test", "user"]
last_updated: "2025-10-19"
status: "published"
audience: "developers"
---

# User Command $i

Test command content for verification.
EOF
done

# Create multiple user agents
for i in {1..5}; do
  cat > ~/.claude/agents/user-agent-$i.md << EOF
---
title: "User Agent $i"
description: "Test user agent $i"
category: "guide"
tags: ["test", "user", "agent"]
last_updated: "2025-10-19"
status: "published"
audience: "developers"
---

# User Agent $i

Test agent content for verification.
EOF
done

# Verify created
ls -la ~/.claude/commands/user-*.md
ls -la ~/.claude/agents/user-*.md
```

### Simulating v0.1.x Installation

Create a realistic v0.1.x environment:

```bash
#!/bin/bash
# simulate-v0.1.sh - Create v0.1.x environment for upgrade testing

set -euo pipefail

echo "Creating v0.1.x environment..."

# Create flat directory structure (no namespaces)
mkdir -p ~/.claude/commands
mkdir -p ~/.claude/agents
mkdir -p ~/.claude/skills
mkdir -p ~/.claude/knowledge

# Create old AIDA templates (flat structure)
cat > ~/.claude/commands/start-work.md << 'EOF'
# Start Work Command (v0.1.x)
Old version of start-work command.
EOF

cat > ~/.claude/commands/implement.md << 'EOF'
# Implement Command (v0.1.x)
Old version of implement command.
EOF

cat > ~/.claude/agents/secretary.md << 'EOF'
# Secretary Agent (v0.1.x)
Old version of secretary agent.
EOF

# Create user content (to verify preservation)
cat > ~/.claude/commands/my-deploy.md << 'EOF'
# My Deploy Command
User's custom deployment workflow.
EOF

cat > ~/.claude/agents/my-expert.md << 'EOF'
# My Expert Agent
User's custom expert agent.
EOF

# Create old config (if desired)
cat > ~/.claude/aida-config.json << 'EOF'
{
  "version": "v0.1.5",
  "assistant_name": "JARVIS",
  "personality": "professional"
}
EOF

echo "✓ v0.1.x environment created"
echo "Ready for upgrade testing"
```

Run to create v0.1.x environment:

```bash
chmod +x simulate-v0.1.sh
./simulate-v0.1.sh
```

---

## Related Documentation

- [Automated Testing Guide](../architecture/testing-strategy.md)
- [Installation Guide](../../README.md#installation)
- [Troubleshooting Guide](../TROUBLESHOOTING.md)
- [Contributing Guide](../CONTRIBUTING.md)

## Changelog

- **2025-10-19**: Initial version for v0.2.0 release
- Comprehensive manual test scenarios
- Cross-platform testing procedures
- UX evaluation criteria
- Bug reporting templates
