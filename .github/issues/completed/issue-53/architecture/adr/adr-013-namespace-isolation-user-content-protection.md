# ADR-013: Namespace Isolation for User Content Protection

**Status**: Proposed
**Date**: 2025-10-18
**Deciders**: System Architect, Tech Lead
**Context**: Software
**Tags**: architecture, safety, user-experience, data-protection

## Context and Problem Statement

AIDA's current installer has a critical safety issue: it overwrites user-created commands, agents, and skills during framework updates. This creates severe data loss risk:

- **User creates custom command**: `~/.claude/commands/my-workflow.md`
- **User runs installer update**: `./install.sh` (to get latest AIDA features)
- **Result**: Custom command overwritten or deleted

Current installer installs framework templates directly into `~/.claude/commands/`, mixing framework content with user content. There is no separation between:

- **Framework-provided templates** (should be replaceable during updates)
- **User-created content** (must be preserved during updates)

This violates fundamental safety principles:

- **Data Loss Prevention**: Users should never lose data from running installer
- **Idempotent Operations**: Re-running installer should be safe
- **Clear Ownership**: Clear distinction between framework and user content
- **Upgrade Safety**: Framework updates should not destroy user work

We need to decide:

- How to separate framework content from user content
- How to protect user content during framework updates
- How to handle deprecated templates
- How to enable safe, idempotent installer reruns
- How to maintain clarity about what content is replaceable

## Decision Drivers

- **Data Safety**: CRITICAL - never destroy user content
- **Idempotency**: Safe to re-run installer multiple times
- **Clarity**: Clear ownership of files (framework vs user)
- **Upgradability**: Framework updates don't affect user content
- **Simplicity**: Easy to understand what's protected and what's not
- **Backward Compatibility**: Migration path for existing users

## Considered Options

### Option A: Status Quo (No Separation)

**Description**: Continue installing framework templates directly into `~/.claude/commands/`

**Current Structure**:

```text
~/.claude/commands/
├── start-work/              # Framework template (AIDA-provided)
│   └── README.md
├── open-pr/                 # Framework template (AIDA-provided)
│   └── README.md
└── my-custom-workflow.md    # User content (user-created)
```

**Behavior on Update**:

```bash
./install.sh   # Overwrites EVERYTHING in commands/
```

**Pros**:

- Simple (flat structure)
- No changes needed

**Cons**:

- **CRITICAL SAFETY ISSUE**: User content destroyed on update
- Not idempotent (re-running installer is dangerous)
- No distinction between framework and user content
- Users afraid to run installer (data loss risk)
- No upgrade path (update = potential data loss)

**Cost**: Unacceptable - data loss is showstopper

### Option B: Prefix-Based Separation

**Description**: Use naming convention to identify framework vs user content

**Structure**:

```text
~/.claude/commands/
├── aida-start-work/         # Framework (prefix = framework-owned)
│   └── README.md
├── aida-open-pr/            # Framework (prefix = framework-owned)
│   └── README.md
└── my-custom-workflow.md    # User content (no prefix)
```

**Behavior on Update**:

```bash
# Installer only touches aida-* prefixed items
./install.sh   # Replaces aida-* commands, preserves others
```

**Pros**:

- Simple to implement
- Clear visual distinction
- Backward compatible (rename on upgrade)

**Cons**:

- **Fragile**: User could accidentally use `aida-` prefix
- **Naming pollution**: All framework commands have `aida-` prefix
- **Claude Code confusion**: `/aida-start-work` is awkward
- **Not foolproof**: Relies on naming convention
- **Deprecated handling unclear**: Where do deprecated items go?

**Cost**: Better than status quo, but fragile and awkward

### Option C: Namespace Isolation via Subdirectories (Recommended)

**Description**: Framework templates in `.aida/` subdirectory, user content in parent

**Structure**:

```text
~/.claude/commands/
├── .aida/                        # Framework namespace (replaceable)
│   ├── start-work/
│   │   └── README.md
│   ├── open-pr/
│   │   └── README.md
│   └── implement/
│       └── README.md
├── .aida-deprecated/             # Deprecated namespace (optional)
│   └── create-issue/             # Old name (deprecated_in: "0.2.0")
│       └── README.md
└── my-custom-workflow.md         # User namespace (preserved)

~/.claude/agents/
├── .aida/                        # Framework namespace
│   ├── secretary/
│   └── file-manager/
├── .aida-deprecated/             # Deprecated namespace
└── my-custom-agent.md            # User namespace

~/.claude/skills/
├── .aida/                        # Framework namespace
│   ├── bash-expert/
│   └── git-workflow/
└── .aida-deprecated/             # Deprecated namespace
```

**Behavior on Update**:

```bash
# Installer ONLY touches .aida/ and .aida-deprecated/
./install.sh

# Safe operations:
rm -rf ~/.claude/commands/.aida/           # Nuke framework
rm -rf ~/.claude/commands/.aida-deprecated/ # Nuke deprecated
# User content untouched!
```

**Pros**:

- **Bulletproof safety**: Framework cannot touch user content
- **Clear ownership**: `.aida/` = framework, parent = user
- **Idempotent**: Safe to re-run installer (deletes and recreates `.aida/`)
- **Deprecated handling**: Separate `.aida-deprecated/` namespace
- **Discovery works**: Claude Code finds commands in subdirectories
- **Visual clarity**: Dotfile convention signals "system/framework"
- **Upgrade safety**: `rm -rf .aida/` is always safe

**Cons**:

- **Directory depth**: Commands at `~/.claude/commands/.aida/start-work/`
  - **Mitigation**: Claude Code already handles nested commands
- **Migration needed**: Existing users need to migrate
  - **Mitigation**: Installer detects and migrates automatically
- **More directories**: 3 subdirectories per type (commands, agents, skills)
  - **Mitigation**: Clear documentation, obvious structure

**Cost**: Migration effort, but massive safety improvement

### Option D: Metadata-Based Ownership

**Description**: Add `.aida-manifest.json` tracking framework-owned files

**Structure**:

```text
~/.claude/commands/
├── .aida-manifest.json          # Lists framework-owned files
├── start-work/                  # Framework (in manifest)
│   └── README.md
├── open-pr/                     # Framework (in manifest)
│   └── README.md
└── my-custom-workflow.md        # User content (not in manifest)
```

**Manifest**:

```json
{
  "framework_owned": [
    "start-work/",
    "open-pr/",
    "implement/"
  ]
}
```

**Behavior on Update**:

```bash
# Installer reads manifest, only touches listed items
./install.sh
```

**Pros**:

- Flexible (any file can be framework-owned)
- No directory nesting

**Cons**:

- **Complex**: Manifest tracking is overhead
- **Fragile**: Manifest could be edited or corrupted
- **Not obvious**: Can't tell ownership by looking at filesystem
- **Sync issues**: Manifest and filesystem could diverge
- **Deprecated unclear**: Need separate manifest for deprecated?

**Cost**: Complexity without clear benefit

## Decision Outcome

**Chosen option**: Option C - Namespace Isolation via Subdirectories

**Rationale**:

1. **Bulletproof Safety**:

   Framework updates can NEVER touch user content:

   ```bash
   # Installer's safe zone (can nuke and recreate)
   ~/.claude/commands/.aida/
   ~/.claude/agents/.aida/
   ~/.claude/skills/.aida/

   # User's protected zone (installer never touches)
   ~/.claude/commands/my-custom-workflow.md
   ~/.claude/agents/my-custom-agent.md
   ~/.claude/config/
   ~/.claude/memory/
   ```

2. **Idempotent Operations**:

   Re-running installer is ALWAYS safe:

   ```bash
   # Safe operation (happens on every install)
   rm -rf ~/.claude/commands/.aida/
   cp -r templates/commands/ ~/.claude/commands/.aida/

   # User content untouched
   ls ~/.claude/commands/my-custom-workflow.md  # Still there!
   ```

3. **Clear Visual Ownership**:

   Dotfile convention signals "system/framework":

   ```text
   .aida/              → Framework content (replaceable)
   .aida-deprecated/   → Old framework content (optional)
   (no prefix)         → User content (protected)
   ```

4. **Deprecation Handling**:

   Separate namespace for deprecated templates:

   ```bash
   # Normal install (skip deprecated)
   ./install.sh
   # Result: Only .aida/ installed

   # With deprecated flag
   ./install.sh --with-deprecated
   # Result: Both .aida/ and .aida-deprecated/ installed
   ```

   Users can:
   - See deprecated commands (if installed with flag)
   - Reference old names during migration
   - Remove deprecated namespace when ready: `rm -rf ~/.claude/commands/.aida-deprecated/`

5. **Claude Code Compatibility**:

   Claude Code discovers commands in subdirectories:

   ```text
   Command paths:
   - /start-work      → ~/.claude/commands/.aida/start-work/README.md
   - /open-pr         → ~/.claude/commands/.aida/open-pr/README.md
   - /my-workflow     → ~/.claude/commands/my-workflow.md
   ```

   Works perfectly (Claude Code scans recursively)

6. **Migration Path**:

   Installer detects existing flat structure and migrates:

   ```bash
   # Before migration
   ~/.claude/commands/
   ├── start-work/     # Old framework template
   └── my-workflow.md  # User content

   # After migration
   ~/.claude/commands/
   ├── .aida/
   │   └── start-work/     # Migrated framework
   └── my-workflow.md      # User content preserved
   ```

### Consequences

**Positive**:

- **Zero data loss risk**: Framework updates CANNOT destroy user content
- **Idempotent installer**: Safe to re-run anytime
- **Clear ownership**: Visual distinction between framework and user
- **Upgrade confidence**: Users can update without fear
- **Deprecation support**: Separate namespace for old templates
- **Simple mental model**: `.aida/` = replaceable, parent = protected
- **Atomic updates**: Can nuke and recreate `.aida/` safely
- **Backward compatible**: Automatic migration from flat structure

**Negative**:

- **Directory nesting**: One extra level (`.aida/`)
  - **Mitigation**: Claude Code already handles nested commands
  - **Mitigation**: Dotfile convention is familiar
- **Migration effort**: Existing users need migration
  - **Mitigation**: Automatic migration in installer
  - **Mitigation**: One-time migration (v0.1.x → v0.2.0)
- **More paths to remember**:
  - **Mitigation**: Clear documentation
  - **Mitigation**: Consistent structure across commands/agents/skills

**Neutral**:

- Dotfile convention (`.aida/`) is standard practice
- Three namespaces: `.aida/`, `.aida-deprecated/`, user content
- Works with both normal and dev installation modes

## Validation

- [x] Framework updates cannot destroy user content (proven by structure)
- [x] Idempotent installer (safe to re-run)
- [x] Clear ownership (visual distinction)
- [x] Claude Code compatible (recursive discovery)
- [x] Deprecation support (separate namespace)
- [x] Migration path defined (automatic)
- [x] Tested with real scenario (user content preserved)
- [x] Reviewed by system architect and tech lead

## Implementation Notes

### Directory Structure

```text
~/.claude/
├── commands/
│   ├── .aida/                    # Framework commands (v0.2.0+)
│   │   ├── start-work/
│   │   ├── implement/
│   │   ├── open-pr/
│   │   └── cleanup-main/
│   ├── .aida-deprecated/         # Deprecated commands (optional)
│   │   └── create-issue/         # Old name for issue-create
│   └── my-custom-workflow.md     # User commands (preserved)
│
├── agents/
│   ├── .aida/                    # Framework agents
│   │   ├── secretary/
│   │   ├── file-manager/
│   │   └── dev-assistant/
│   ├── .aida-deprecated/         # Deprecated agents (optional)
│   └── my-custom-agent.md        # User agents (preserved)
│
├── skills/
│   ├── .aida/                    # Framework skills
│   │   ├── bash-expert/
│   │   ├── git-workflow/
│   │   └── aida-config/
│   └── .aida-deprecated/         # Deprecated skills (optional)
│
├── config/                       # User config (preserved)
├── memory/                       # User memory (preserved)
└── CLAUDE.md                     # Entry point (generated)
```

### Installer Behavior

**Fresh Installation**:

```bash
./install.sh

# Creates namespace directories
mkdir -p ~/.claude/commands/.aida
mkdir -p ~/.claude/agents/.aida
mkdir -p ~/.claude/skills/.aida

# Installs framework templates
cp -r templates/commands/* ~/.claude/commands/.aida/
cp -r templates/agents/* ~/.claude/agents/.aida/
cp -r templates/skills/* ~/.claude/skills/.aida/

# User content: (none yet, fresh install)
```

**Upgrade from v0.1.x**:

```bash
./install.sh

# Detects flat structure
if [[ -d ~/.claude/commands/start-work ]] && [[ ! -d ~/.claude/commands/.aida ]]; then
  echo "Migrating to namespace isolation..."

  # Create namespace
  mkdir -p ~/.claude/commands/.aida

  # Migrate framework templates (known list)
  for cmd in start-work open-pr implement cleanup-main; do
    if [[ -d ~/.claude/commands/$cmd ]]; then
      mv ~/.claude/commands/$cmd ~/.claude/commands/.aida/
    fi
  done

  # User content stays in parent directory
  # (anything not in framework list is user content)
fi
```

**Re-running Installer (Idempotent)**:

```bash
./install.sh

# Safe: Nuke framework namespace
rm -rf ~/.claude/commands/.aida/
rm -rf ~/.claude/agents/.aida/
rm -rf ~/.claude/skills/.aida/

# Recreate with latest templates
cp -r templates/commands/* ~/.claude/commands/.aida/
cp -r templates/agents/* ~/.claude/agents/.aida/
cp -r templates/skills/* ~/.claude/skills/.aida/

# User content: Untouched!
ls ~/.claude/commands/my-workflow.md  # Still exists
```

**With Deprecated Templates**:

```bash
./install.sh --with-deprecated

# Install both namespaces
cp -r templates/commands/* ~/.claude/commands/.aida/
cp -r templates/commands-deprecated/* ~/.claude/commands/.aida-deprecated/
```

### Claude Code Integration

**Command Discovery**:

Claude Code scans `~/.claude/commands/` recursively:

```text
Found commands:
- /start-work        → .aida/start-work/README.md
- /implement         → .aida/implement/README.md
- /open-pr           → .aida/open-pr/README.md
- /my-workflow       → my-workflow.md
- /create-issue      → .aida-deprecated/create-issue/README.md (if --with-deprecated)
```

**No changes needed** - Claude Code already supports nested discovery

### Developer Experience

**Creating Custom Command**:

```bash
# User creates command in parent directory (NOT in .aida/)
cat > ~/.claude/commands/my-workflow.md <<EOF
# My Custom Workflow

Custom command for my specific workflow
EOF

# Now it's protected from framework updates!
```

**Updating AIDA Framework**:

```bash
cd ~/.aida/   # Symlinked to repo
git pull      # Get latest framework

# Framework templates auto-updated (dev mode symlinked)
# User content untouched
```

### Documentation

**User Guide**:

```markdown
## File Organization

AIDA uses namespace isolation to protect your content:

**Framework Content** (`.aida/` directories):
- Provided by AIDA framework
- Replaced during updates
- Safe to delete (will be recreated)

**User Content** (parent directories):
- Your custom commands, agents, skills
- Never touched by installer
- Preserved during updates

**Deprecated Content** (`.aida-deprecated/` directories):
- Old framework templates
- Optional (install with --with-deprecated)
- Reference during migration

## Creating Custom Content

Create your content in parent directory:

```bash
# Custom command (preserved)
~/.claude/commands/my-workflow.md

# Custom agent (preserved)
~/.claude/agents/my-agent.md

# Your config (preserved)
~/.claude/config/
```

## Updating AIDA

Safe to re-run installer:

```bash
./install.sh

# Updates framework (.aida/ directories)
# Preserves your custom content
```
```

### Testing

**Unit Test**:

```bash
test_namespace_isolation() {
  # Setup: Create user content
  echo "user content" > ~/.claude/commands/my-workflow.md

  # Run installer
  ./install.sh

  # Validate: User content preserved
  assert_file_contains ~/.claude/commands/my-workflow.md "user content"

  # Validate: Framework installed
  assert_directory_exists ~/.claude/commands/.aida/start-work
}
```

**Integration Test**:

```bash
test_upgrade_preserves_user_content() {
  # Setup: Simulate v0.1.x installation
  cp -r fixtures/v0.1-structure ~/.claude/

  # Add user content
  echo "custom" > ~/.claude/commands/my-custom.md

  # Run installer (upgrade)
  ./install.sh

  # Validate: User content preserved
  assert_file_contains ~/.claude/commands/my-custom.md "custom"

  # Validate: Framework migrated to namespace
  assert_directory_exists ~/.claude/commands/.aida/start-work
  assert_not_exists ~/.claude/commands/start-work  # Moved
}
```

## Examples

### Example 1: Fresh Install

```bash
# Install AIDA
./install.sh

# Result:
~/.claude/commands/.aida/start-work/       # Framework
~/.claude/commands/.aida/implement/        # Framework
~/.claude/commands/.aida/open-pr/          # Framework

# Create custom command
cat > ~/.claude/commands/deploy.md <<EOF
# My Deploy Workflow
EOF

# Now protected forever!
```

### Example 2: Upgrade from v0.1.x

```bash
# Before upgrade (v0.1.x flat structure)
~/.claude/commands/
├── start-work/              # Framework
├── open-pr/                 # Framework
└── my-workflow.md           # User content

# Run installer
./install.sh

# After upgrade (v0.2.0 namespace isolation)
~/.claude/commands/
├── .aida/
│   ├── start-work/          # Migrated
│   └── open-pr/             # Migrated
└── my-workflow.md           # Preserved!
```

### Example 3: Framework Update

```bash
# User has custom content
~/.claude/commands/my-workflow.md

# Update AIDA framework
cd ~/.aida && git pull

# Re-run installer to update templates
./install.sh

# Result:
# - .aida/ templates updated
# - my-workflow.md untouched
# - Safe, idempotent operation
```

### Example 4: Deprecated Templates

```bash
# Install with deprecated templates
./install.sh --with-deprecated

# Result:
~/.claude/commands/
├── .aida/
│   ├── issue-create/        # New name
│   └── start-work/
├── .aida-deprecated/
│   └── create-issue/        # Old name (deprecated)
└── my-workflow.md           # User content

# User can reference both during migration
# Remove deprecated when ready:
rm -rf ~/.claude/commands/.aida-deprecated/
```

## Migration Path

### v0.1.x → v0.2.0 Automatic Migration

**Installer Detection**:

```bash
# Check for flat structure
if [[ -d ~/.claude/commands/start-work ]] && \
   [[ ! -d ~/.claude/commands/.aida ]]; then
  migrate_to_namespace_isolation
fi
```

**Migration Steps**:

1. **Create namespace directories**
2. **Identify framework templates** (known list from v0.1.x)
3. **Move framework templates** to `.aida/` namespace
4. **Leave user content** in parent directory
5. **Log migration** for user review

**Known Framework Templates** (v0.1.x):

- Commands: `start-work`, `implement`, `open-pr`, `cleanup-main`
- Agents: `secretary`, `file-manager`, `dev-assistant`
- Skills: `bash-expert`, `git-workflow`

**Migration Log**:

```text
Migrating to namespace isolation (v0.2.0)...

Framework templates moved to .aida/:
✓ commands/start-work → commands/.aida/start-work
✓ commands/open-pr → commands/.aida/open-pr
✓ agents/secretary → agents/.aida/secretary

User content preserved:
✓ commands/my-workflow.md
✓ agents/my-agent.md
✓ config/assistant.yaml

Migration complete!
```

## References

- **Issue #53**: Modular Installer Refactoring
- **PRD**: Section on "Zero data loss" requirement
- **Technical Spec**: Section 2.3 - templates.sh (namespace isolation)
- **ADR-011**: Modular Installer Architecture (provides structure)

## Related ADRs

- **ADR-011**: Modular Installer Architecture (enables namespace isolation)
- **ADR-012**: Universal Config Aggregator (templates stay pure)
- **ADR-010**: Command Structure Refactoring (depends on namespace safety)

## Updates

None yet
