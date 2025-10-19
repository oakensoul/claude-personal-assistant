---
title: "Create Issue Command (DEPRECATED)"
description: "Create GitHub issue - renamed to issue-create per ADR-010"
category: "workflow"
tags: ["github", "deprecated", "migration"]
deprecated: true
deprecated_in: "0.2.0"
remove_in: "0.4.0"
canonical: "issue-create"
reason: "Renamed to noun-verb convention per ADR-010"
migration_path: "Use /issue-create instead"
---

# Create Issue Command (DEPRECATED)

**DEPRECATED**: This command has been renamed to `issue-create` following ADR-010 (noun-verb naming convention).

## Deprecation Details

**Deprecated In**: v0.2.0
**Remove In**: v0.4.0
**Canonical Name**: `issue-create`
**Reason**: Naming convention change from verb-noun to noun-verb

## Migration Path

Replace usage:

```bash
# OLD (deprecated)
/create-issue

# NEW (canonical)
/issue-create
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

Command '/create-issue' is deprecated and will be removed in v0.4.0.

Please use '/issue-create' instead.

Reason: Naming convention changed to noun-verb format (ADR-010)

Proceeding with command execution...
```

## Why This Changed

**ADR-010: Command Naming Convention**

Standardizes all commands to noun-verb format:

- **Better grouping**: Related commands group by noun (issue-create, issue-publish, issue-list)
- **Clearer hierarchy**: Noun represents the resource, verb the action
- **Consistent discovery**: All issue-related commands start with "issue-"

## Old vs New Naming

**Deprecated (verb-noun)**:

- `/create-issue`
- `/publish-issue`
- `/list-issues`
- `/start-work`
- `/cleanup-main`

**Canonical (noun-verb)**:

- `/issue-create`
- `/issue-publish`
- `/issue-list`
- `/work-start`
- `/main-cleanup`

## Migration Guidance

**For Users**:

1. Update scripts/workflows to use new names
2. Search codebase for old command references
3. Update documentation and team guides

**For Developers**:

1. Update command references in code
2. Update tests to use new names
3. Add migration tests for backward compatibility

## Implementation Note

During v0.2.0-v0.3.x, installer maintains both:

- **Canonical**: `~/.claude/commands/.aida/issue-create.md` (new)
- **Deprecated**: Symlink or alias for backward compatibility

At v0.4.0, deprecated names removed entirely.

## Testing Deprecation

Verify deprecation handling:

```bash
# Should show warning but work
/create-issue

# Should work without warning
/issue-create

# Should be identical functionality
diff <(/create-issue --help) <(/issue-create --help)
```

## Related

- **ADR-010**: Command naming convention decision
- **Migration Guide**: Full list of renamed commands
- **Changelog**: v0.2.0 breaking changes
