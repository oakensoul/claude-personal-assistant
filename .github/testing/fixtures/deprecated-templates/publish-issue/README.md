---
title: "Publish Issue Command (DEPRECATED)"
description: "Publish issue to GitHub - renamed to issue-publish per ADR-010"
category: "workflow"
tags: ["github", "deprecated", "migration"]
deprecated: true
deprecated_in: "0.2.0"
remove_in: "0.4.0"
canonical: "issue-publish"
reason: "Renamed to noun-verb convention per ADR-010"
migration_path: "Use /issue-publish instead"
---

# Publish Issue Command (DEPRECATED)

**DEPRECATED**: This command has been renamed to `issue-publish` following ADR-010 (noun-verb naming convention).

## Deprecation Details

**Deprecated In**: v0.2.0
**Remove In**: v0.4.0
**Canonical Name**: `issue-publish`
**Reason**: Naming convention change from verb-noun to noun-verb

## Migration Path

Replace usage:

```bash
# OLD (deprecated)
/publish-issue my-issue-slug

# NEW (canonical)
/issue-publish my-issue-slug
```

## Deprecation Timeline

**v0.2.0** (current):

- Command still works but shows deprecation warning
- Warning message directs to new command name
- Both names functional (backward compatibility)

**v0.3.0** (next):

- Deprecated name shows migration notice
- Encourages updating to new name
- Functionality unchanged

**v0.4.0** (removal):

- Old name removed completely
- Only canonical name works
- Breaking change for old usage

## Deprecation Warning

When invoked in v0.2.0+:

```text
⚠️  DEPRECATION WARNING

Command '/publish-issue' is deprecated and will be removed in v0.4.0.

Please use '/issue-publish' instead.

Reason: Naming convention changed to noun-verb format (ADR-010)

Proceeding with command execution...
```

## Why This Changed

**ADR-010: Command Naming Convention**

Standardizes all commands to noun-verb format for better organization:

**Old Structure (verb-noun)**:

```text
/create-issue
/publish-issue
/create-pr
/publish-pr
```

**New Structure (noun-verb)**:

```text
/issue-create
/issue-publish
/pr-create
/pr-publish
```

**Benefits**:

- **Grouping**: All issue commands start with "issue-"
- **Discovery**: Easier to find related commands
- **Consistency**: Uniform pattern across all commands

## Command Alias Table

| Deprecated (OLD)    | Canonical (NEW)    | Status      |
| ------------------- | ------------------ | ----------- |
| `/publish-issue`    | `/issue-publish`   | v0.2.0-v0.3.x |
| `/create-issue`     | `/issue-create`    | v0.2.0-v0.3.x |
| `/list-issues`      | `/issue-list`      | v0.2.0-v0.3.x |
| `/create-pr`        | `/pr-create`       | v0.2.0-v0.3.x |
| `/cleanup-main`     | `/main-cleanup`    | v0.2.0-v0.3.x |

## Migration Guidance

### For Individual Users

**Step 1**: Find old command usage

```bash
# Search shell history
history | grep "publish-issue"

# Search scripts
grep -r "publish-issue" ~/scripts/
```

**Step 2**: Update to new names

```bash
# Replace in scripts
sed -i 's/publish-issue/issue-publish/g' ~/scripts/*.sh

# Update aliases
sed -i 's/publish-issue/issue-publish/g' ~/.bashrc
```

**Step 3**: Verify changes

```bash
# Test new command
/issue-publish --help

# Check functionality matches
diff <(/publish-issue --help) <(/issue-publish --help)
```

### For Teams

**Step 1**: Communication

- Announce deprecation timeline
- Share migration guide
- Provide support period

**Step 2**: Update Documentation

- Update team wiki
- Update onboarding docs
- Update example scripts

**Step 3**: Gradual Migration

- v0.2.0-v0.3.x: Both work (transition period)
- Encourage new name usage
- v0.4.0: Only new name works

## Implementation Details

### Backward Compatibility (v0.2.0-v0.3.x)

Installer creates alias/symlink:

```text
~/.claude/commands/
├── .aida/
│   └── issue-publish.md         # Canonical version
└── publish-issue -> .aida/issue-publish.md  # Deprecated symlink
```

### Deprecation Handler

Command execution wrapper:

```python
def execute_command(cmd_name: str, args: list):
    deprecated_map = {
        'publish-issue': 'issue-publish',
        'create-issue': 'issue-create',
    }

    if cmd_name in deprecated_map:
        canonical = deprecated_map[cmd_name]
        show_deprecation_warning(cmd_name, canonical)
        cmd_name = canonical  # Execute canonical version

    return run_command(cmd_name, args)
```

## Testing Deprecation

### Manual Testing

```bash
# Test deprecated name (should warn)
/publish-issue my-issue-slug

# Test canonical name (should not warn)
/issue-publish my-issue-slug

# Verify identical behavior
diff <(/publish-issue my-slug --dry-run) \
     <(/issue-publish my-slug --dry-run)
```

### Automated Testing

```python
def test_deprecated_publish_issue():
    """Verify deprecated command shows warning but works."""
    output = run_command('/publish-issue', 'test-slug')

    assert 'DEPRECATION WARNING' in output
    assert 'issue-publish' in output
    assert command_succeeded(output)

def test_canonical_issue_publish():
    """Verify canonical command works without warning."""
    output = run_command('/issue-publish', 'test-slug')

    assert 'DEPRECATION WARNING' not in output
    assert command_succeeded(output)
```

## Related Documentation

- **ADR-010**: Command naming convention decision
- **Migration Guide**: Complete list of renamed commands
- **Changelog v0.2.0**: Breaking changes and deprecations
- **Upgrade Guide**: Step-by-step upgrade instructions

## Frequently Asked Questions

**Q: Do I need to change immediately?**
A: No, deprecated names work until v0.4.0. But updating now is recommended.

**Q: Will this break my scripts?**
A: Not until v0.4.0. You have v0.2.x and v0.3.x to migrate.

**Q: Can I use both names?**
A: Yes, during v0.2.0-v0.3.x both names work identically.

**Q: How do I know when it's removed?**
A: Check changelog for v0.4.0 release notes.
