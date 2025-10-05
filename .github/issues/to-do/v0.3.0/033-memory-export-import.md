---
title: "Implement memory export and import functionality"
labels:
  - "type: feature"
  - "priority: p2"
  - "effort: small"
  - "milestone: 0.3.0"
---

# Implement memory export and import functionality

## Description

Implement export and import functionality for memory backup, portability, and restoration. Supports both full memory export and category-specific exports in multiple formats.

## Acceptance Criteria

- [ ] Export all memory categories to archive format
- [ ] Export specific categories to JSON or markdown
- [ ] Import memory from archive
- [ ] Import specific categories
- [ ] Export preserves all metadata
- [ ] Import validates data before applying
- [ ] Export creates timestamped archives
- [ ] Import handles conflicts gracefully (merge vs replace)
- [ ] CLI commands are intuitive
- [ ] Export/import operations are logged

## Implementation Notes

### Export Functionality

```bash
# Export all memory
aida memory export --output ~/backups/memory-2025-10-04.tar.gz

# Export specific category
aida memory export --category knowledge --output ~/knowledge-export.json

# Export with date range
aida memory export --from 2025-10-01 --to 2025-10-31 --output ~/october-memory.tar.gz

# Export format options
aida memory export --format json --output memory.json
aida memory export --format markdown --output memory.md
aida memory export --format tar.gz --output memory.tar.gz  # default
```python

### Import Functionality

```bash
# Import all memory (with merge strategy)
aida memory import ~/backups/memory-2025-10-04.tar.gz

# Import with replace strategy
aida memory import --replace ~/backups/memory-2025-10-04.tar.gz

# Import specific category
aida memory import --category knowledge ~/knowledge-export.json

# Dry run (preview without applying)
aida memory import --dry-run ~/backups/memory-2025-10-04.tar.gz
```

### Export Format

**Archive Structure (tar.gz)**:

```text
memory-export-2025-10-04/
├── manifest.json          # Export metadata
├── tasks/
│   ├── active.md
│   ├── completed.md
│   └── archived.md
├── knowledge/
│   └── ...
├── decisions/
│   └── ...
└── ...
```

**Manifest Format**:

```json
{
  "export_date": "2025-10-04T10:30:00Z",
  "aida_version": "0.3.0",
  "categories": ["tasks", "knowledge", "decisions", "preferences", "context", "history"],
  "entry_count": {
    "tasks": 142,
    "knowledge": 67,
    "decisions": 12,
    "preferences": 8,
    "context": 5,
    "history": 3
  },
  "date_range": {
    "oldest": "2025-09-01",
    "newest": "2025-10-04"
  }
}
```python

### Import Conflict Handling

**Merge Strategy (default)**:

- Keep existing entries
- Add new entries from import
- For duplicates (same date + title), keep most recent

**Replace Strategy**:

- Remove existing category data
- Replace with import data
- Create backup before replacing

**Interactive Mode**:

```
Found 3 conflicts:

1. Task "Fix auth bug" exists in both
   Current: 2025-10-04 10:00 (completed)
   Import:  2025-10-04 09:30 (active)

   Keep: [C]urrent, [I]mport, [B]oth?

2. Knowledge "React hooks pattern" exists in both
   Current: 2025-10-04 (more detailed)
   Import:  2025-10-03 (original)

   Keep: [C]urrent, [I]mport, [B]oth?

...
```text

## Dependencies

- #031 (Memory categories structure)
- #032 (Search helps identify duplicates)

## Related Issues

- Part of #022 (Enhanced memory system epic)
- #012 (Installation testing should verify export/import)

## Definition of Done

- [ ] Export all categories works
- [ ] Export specific categories works
- [ ] Import with merge works correctly
- [ ] Import with replace works correctly
- [ ] Conflict detection implemented
- [ ] Archive format documented
- [ ] Validation prevents corrupted imports
- [ ] Operations are logged
- [ ] CLI commands documented
- [ ] Error messages are helpful
