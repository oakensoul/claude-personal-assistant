---
title: "Implement File Manager agent"
labels:
  - "type: feature"
  - "priority: p1"
  - "effort: medium"
  - "milestone: 0.3.0"
---

# Implement File Manager agent

## Description

Implement the File Manager agent responsible for file organization, cleanup, system maintenance, and file discovery. This agent keeps the filesystem organized and handles Downloads cleanup, Desktop management, and file categorization.

## Acceptance Criteria

- [ ] File Manager agent fully functional
- [ ] Downloads cleanup works correctly
- [ ] Desktop clearing works correctly
- [ ] File categorization accurate
- [ ] File naming conventions applied
- [ ] Batch file operations safe and reliable
- [ ] System health checks functional
- [ ] Agent integrates with memory system
- [ ] Agent applies personality appropriately
- [ ] Agent performance acceptable (<3 seconds for analysis)

## Implementation Notes

### Agent Definition

Location: `~/.claude/agents/core/file-manager/CLAUDE.md`

```markdown
---
title: "File Manager Agent"
description: "File organization and system maintenance"
category: "agent"
version: "0.3.0"
---

# File Manager Agent

## Role

I am your file management specialist, responsible for keeping your filesystem organized, clean, and efficient. I ensure files are in the right places and the system stays healthy.

## Responsibilities

- Downloads folder cleanup and organization
- Desktop minimization
- Screenshot organization
- File categorization and naming
- Disk space monitoring
- Backup coordination
- System health checks

## When to Invoke

**Explicit**: @file-manager
**Keywords**: file, folder, directory, organize (files), cleanup (files), find (files), Downloads, Desktop
**Commands**: cleanup-downloads, clear-desktop, organize-screenshots, file-this, system-health

## Capabilities

### 1. Downloads Cleanup
- Scan and categorize files
- Apply naming conventions
- Suggest destinations
- Safe batch operations
- Update tracking

### 2. Desktop Clearing
- List Desktop items
- Categorize by type and age
- Suggest destinations
- Keep essential shortcuts
- Archive temp files

### 3. File Organization
- Analyze file type/contents
- Apply naming conventions
- Suggest destinations
- Safe move operations
- Update project notes

### 4. System Health
- Disk space monitoring
- File count tracking
- Organization status
- Cleanup recommendations
```

### Downloads Cleanup Implementation

**Trigger**: `aida cleanup-downloads` or `@file-manager cleanup downloads`

**Procedure**:
1. Scan `~/Downloads/` for files
2. Categorize by type and content
3. Apply file naming conventions from preferences
4. Suggest destinations based on content
5. Move files with user confirmation
6. Update `~/.claude/memory/context/current.md` with timestamp
7. Report summary with personality

**Categorization Logic**:
```python
def categorize_file(filepath):
    """Categorize file by extension and content."""
    ext = get_extension(filepath)

    categories = {
        'documents': ['.pdf', '.doc', '.docx', '.txt', '.rtf'],
        'images': ['.jpg', '.jpeg', '.png', '.gif', '.svg'],
        'archives': ['.zip', '.tar', '.gz', '.rar', '.7z'],
        'installers': ['.dmg', '.pkg', '.deb', '.rpm', '.exe'],
        'code': ['.json', '.yaml', '.yml', '.sh', '.py', '.js'],
        'media': ['.mp4', '.mov', '.mp3', '.wav'],
    }

    for category, extensions in categories.items():
        if ext in extensions:
            return category

    return 'miscellaneous'

def suggest_destination(filepath, category):
    """Suggest destination based on category and content."""
    filename = get_filename(filepath)

    destinations = {
        'documents': {
            'invoice': '~/Documents/Invoices/',
            'receipt': '~/Documents/Receipts/',
            'manual': '~/Documents/Manuals/',
            'default': '~/Documents/Downloads-Archive/'
        },
        'images': {
            'screenshot': '~/Pictures/Screenshots/',
            'default': '~/Pictures/'
        },
        'installers': {
            'default': '~/.Trash'  # if app already installed
        },
        'code': {
            'default': '~/Development/sandbox/'
        }
    }

    # Check filename for hints
    for hint, dest in destinations.get(category, {}).items():
        if hint in filename.lower():
            return dest

    return destinations.get(category, {}).get('default', '~/Documents/')
```

**Example Output**:
```
Your Downloads folder has 47 items. I'm sure they're all exactly where they should be, sir.

**Categorization**:
📄 Documents: 12 files
  - 5 invoices → ~/Documents/Invoices/
  - 3 receipts → ~/Documents/Receipts/
  - 4 misc PDFs → ~/Documents/Downloads-Archive/

🖼️  Images: 8 files
  - 8 screenshots → ~/Pictures/Screenshots/

📦 Archives: 5 files
  - 5 .zip files → [Need to inspect contents]

💿 Installers: 3 files
  - Slack.dmg (Slack already installed) → Trash
  - VSCode.dmg (VSCode already installed) → Trash
  - Firefox.dmg (not installed) → Keep

📁 Miscellaneous: 19 files
  - Various files → [Need review]

**Suggested Actions**:
1. Move 12 documents to appropriate folders (auto-rename by date)
2. Move 8 screenshots to Pictures/Screenshots/
3. Extract and evaluate 5 archives
4. Delete 2 installers (apps already installed)
5. Review 19 miscellaneous files individually

Estimated cleanup time: 3 minutes
Disk space to recover: ~450 MB

Shall I proceed with these suggestions?
```

### Desktop Clearing Implementation

**Trigger**: `aida clear-desktop` or `@file-manager clear desktop`

**Procedure**:
1. List all items on Desktop
2. Categorize by type and age
3. Identify essential vs temporary
4. Suggest destinations
5. Move with confirmation
6. Report clean status

**Example Output**:
```
Desktop Analysis (23 items)
===========================

**Essential** (Keep):
- Applications folder alias
- Documents folder alias

**Temporary Files** (Archive):
- screenshot-2025-10-01.png (3 days old) → ~/Pictures/Screenshots/
- meeting-notes.txt (1 day old) → ~/Documents/Notes/
- download.zip (2 days old) → Extract and delete

**Old Files** (>7 days):
- project-draft.pdf (14 days old) → ~/Documents/Archive/
- random-image.jpg (30 days old) → ~/Pictures/Archive/

**Folders**:
- temp-work/ (contains 12 files) → Review and organize

Cleaning desktop will:
- Keep 2 essential aliases
- Archive 18 temporary files
- Review 1 folder (temp-work)

Target: Empty desktop (except aliases)

Proceed with cleanup? (Y/n)
```

### File Naming Conventions

Apply user preferences from `~/.claude/memory/preferences/preferences.md`:

```markdown
## File Naming Conventions

**Documents**:
- Pattern: `YYYY-MM-DD-category-description.ext`
- Example: `2025-10-04-invoice-aws-services.pdf`

**Screenshots**:
- Pattern: `YYYY-MM-DD-HH-MM-description.png`
- Example: `2025-10-04-14-30-bug-reproduction.png`

**Code Files**:
- Pattern: `descriptive-kebab-case.ext`
- Example: `user-authentication-service.py`

**Archives**:
- Pattern: `YYYY-MM-DD-content-description.zip`
- Example: `2025-10-04-project-alpha-backup.zip`
```

### System Health Check

**Trigger**: `aida system-health` or `@file-manager system health`

**Procedure**:
1. Check disk space usage
2. Count files in common locations
3. Identify large files
4. Suggest cleanups
5. Report overall health

**Example Output**:
```
System Health Check
===================

**Disk Space**:
Total: 500 GB
Used: 225 GB (45%)
Free: 275 GB (55%)
Status: ✓ Healthy

**File Counts**:
Downloads: 47 files (! cleanup recommended)
Desktop: 23 items (! cleanup recommended)
Documents: 1,247 files (✓ organized)
Development: 89 projects (✓ good)

**Large Files** (>1GB):
1. ~/Downloads/ubuntu-desktop.iso (2.8 GB) - 30 days old
2. ~/Movies/project-demo.mov (1.4 GB) - 15 days old
3. ~/Documents/backup.zip (1.2 GB) - 60 days old

**Recommendations**:
1. 🔴 Cleanup Downloads (47 files, ~2.5 GB recoverable)
2. 🟡 Clear Desktop (23 items)
3. 🟢 Archive large old files (3 files, ~5.4 GB recoverable)

Potential space recovery: ~7.9 GB

Would you like me to help with these cleanups?
```

### Personality Integration

Apply active personality (example: JARVIS):
```
JARVIS tone for file management:
- Snarky about messy folders: "I'm sure they're all exactly where they should be"
- Witty about file accumulation: "47 files in Downloads. Impressive restraint, sir."
- Gentle mockery: "Only 23 items on Desktop today. You're improving."
- Satisfaction: "Desktop clear. As it should be."
- British precision: "Shall I proceed with surgical precision?"
```

## Dependencies

- #039 (Agent framework and routing)
- #009 (Agent templates)
- #031 (Memory system for context)

## Related Issues

- Part of #025 (Core agents implementation epic)
- #040 (Secretary agent)
- #042 (Dev Assistant agent)
- #043 (Agent collaboration)

## Definition of Done

- [ ] File Manager agent fully implemented
- [ ] Downloads cleanup functional
- [ ] Desktop clearing functional
- [ ] File categorization accurate
- [ ] Naming conventions applied correctly
- [ ] Batch operations safe
- [ ] System health checks work
- [ ] Memory integration complete
- [ ] Personality integration works
- [ ] Documentation complete
- [ ] Examples demonstrate capabilities
