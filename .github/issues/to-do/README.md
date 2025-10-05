# AIDA Issue Definitions - To Do

This directory contains issue definition files for the AIDA framework implementation. These files are used by the devops-engineer agent to create actual GitHub issues with proper custom field mapping.

## Organization

Issues are organized into milestone-based subdirectories for better clarity and navigation:

```
.github/issues/to-do/
├── v0.1.0/          # Foundation (15 issues)
├── v0.2.0/          # Core Features (6 issues)
├── v0.3.0/          # Enhanced Memory & Agents (4 issues)
├── v0.4.0/          # Extended Commands & Obsidian (2 issues)
├── v0.5.0/          # Project Agents (1 issue)
├── v0.6.0/          # Knowledge Sync (1 issue)
└── v1.0.0/          # Stable Release (1 issue)
```

### Milestone v0.1.0 - Foundation (MVP)

**Goal**: Prove core value proposition with installable, personality-driven AI assistant

**Issues**: 15 (located in `v0.1.0/`)
- #001: Installation script foundation
- #002: Template system
- #003: CLI tool generation
- #004: PATH configuration
- #005: CLAUDE.md template
- #006: Knowledge templates
- #007: Memory templates
- #008: JARVIS personality
- #009: Agent templates
- #010: CLI tool template
- #011: Core procedures documentation
- #012: Installation testing
- #013: User documentation
- #020: MCP integration guide
- #021: MVP release checklist

### Milestone v0.2.0 - Core Features

**Goal**: Daily usability with task management and workflow automation

**Issues**: 6 (located in `v0.2.0/`)
- #014: Additional personalities (Alfred, FRIDAY, Sage, Drill Sergeant)
- #015: Personality switching
- #016: Obsidian templates
- #017: Extended command system
- #026: Task management system
- #027: Workflow automation system

### Milestone v0.3.0 - Enhanced Memory & Agents

**Goal**: Specialized assistance with richer memory and knowledge management

**Issues**: 4 (located in `v0.3.0/`)
- #022: Enhanced memory system
- #023: Knowledge capture system
- #024: Decision documentation system
- #025: Core agents implementation

### Milestone v0.4.0 - Extended Commands & Obsidian

**Goal**: Full workflow integration with comprehensive Obsidian support

**Issues**: 2 (located in `v0.4.0/`)
- #028: Obsidian full integration
- #029: Git integration

### Milestone v0.5.0 - Project Agents

**Goal**: Tech-stack specific expertise and extensibility

**Issues**: 1 (located in `v0.5.0/`)
- #018: Project-specific agents system (React, Next.js, Go, Python, etc.)

### Milestone v0.6.0 - Knowledge Sync & Privacy

**Goal**: Privacy-aware knowledge sharing and data control

**Issues**: 1 (located in `v0.6.0/`)
- #019: Knowledge sync and scrubbing system

### Milestone v1.0.0 - First Stable Release

**Goal**: Production-ready, polished experience with stability guarantees

**Issues**: 1 (located in `v1.0.0/`)
- #030: v1.0.0 release preparation

## Priority Legend

- **P0**: Critical - Blocking MVP release
- **P1**: High - Important for user experience
- **P2**: Medium - Valuable but not blocking
- **P3**: Low - Nice to have

## Effort Legend

- **Small**: < 4 hours
- **Medium**: 4-8 hours
- **Large**: 8-16 hours
- **XLarge**: 16+ hours

## Issue File Format

Each issue file follows this structure:

```markdown
---
title: "Issue title"
labels:
  - "type: feature|bug|documentation|testing|release"
  - "priority: p0|p1|p2|p3"
  - "effort: small|medium|large|xlarge"
  - "milestone: 0.1.0|0.2.0|..."
---

# Issue Title

## Description
[Detailed description]

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2

## Implementation Notes
[Technical details, code examples, design decisions]

## Dependencies
[Other issues that must be completed first]

## Related Issues
[Issues that are related but not dependencies]

## Definition of Done
[Final checklist for completion]
```

## Dependency Graph

```
v0.1.0 Dependencies:

#001 (Installation foundation)
  ├─→ #002 (Template system)
  │    ├─→ #005 (CLAUDE.md template)
  │    ├─→ #006 (Knowledge templates)
  │    ├─→ #007 (Memory templates)
  │    └─→ #010 (CLI tool template)
  ├─→ #003 (CLI generation)
  │    └─→ #004 (PATH config)
  └─→ #008 (JARVIS personality)

#006 (Knowledge templates)
  └─→ #011 (Core procedures)
       ├─→ #009 (Agent templates)
       └─→ #012 (Testing)

#012 (Testing)
  └─→ #013 (Documentation)
       └─→ #021 (Release checklist)

#020 (MCP guide) - Parallel to main flow

---

v0.2.0 Dependencies:

#007 (Memory templates) + #022 (Enhanced memory) → #026 (Task management)
#009 (Agent templates) → #027 (Workflow automation)
#008 (JARVIS) → #014 (Additional personalities) → #015 (Personality switching)
#006 (Knowledge) → #016 (Obsidian templates)
#011 (Core procedures) → #017 (Extended commands)

---

v0.3.0 Dependencies:

#007 (Memory templates) → #022 (Enhanced memory system)
#022 (Enhanced memory) → #023 (Knowledge capture)
#022 (Enhanced memory) → #024 (Decision documentation)
#009 (Agent templates) + #022 (Enhanced memory) → #025 (Core agents)

---

v0.4.0 Dependencies:

#016 (Obsidian templates) + #026 (Tasks) + #023 (Knowledge) → #028 (Obsidian full)
#025 (Core agents) + #023 (Knowledge) → #029 (Git integration)

---

v0.5.0 Dependencies:

#025 (Core agents) + #009 (Agent templates) → #018 (Project agents)

---

v0.6.0 Dependencies:

#016 (Obsidian templates) + #023 (Knowledge) → #019 (Knowledge sync)

---

v1.0.0 Dependencies:

ALL prior milestones (v0.1.0 through v0.6.0) → #030 (v1.0.0 release)
```

## Usage with devops-engineer

To create GitHub issues from these definitions:

```bash
# Process all to-do issues
@devops-engineer create GitHub issues from .github/issues/to-do/

# Process specific milestone
@devops-engineer create GitHub issues from .github/issues/to-do/v0.1.0/

# Process specific issue
@devops-engineer create GitHub issue from .github/issues/to-do/v0.1.0/001-installation-script-foundation.md
```

The devops-engineer agent will:
1. Read the issue definition file
2. Parse frontmatter for labels, priority, effort, milestone
3. Create GitHub issue with proper formatting
4. Apply labels and custom fields
5. Link dependencies (if issues exist)
6. Move file to appropriate status folder

## Current Status

**Total Issues**: 30
**Total Estimated Effort**: ~350-400 hours for complete implementation

**Breakdown by Milestone**:
- v0.1.0 Foundation: 15 issues (~40-50 hours)
- v0.2.0 Core Features: 6 issues (~50-60 hours)
- v0.3.0 Enhanced Memory & Agents: 4 issues (~65-75 hours)
- v0.4.0 Extended Commands & Obsidian: 2 issues (~35-40 hours)
- v0.5.0 Project Agents: 1 issue (~20-25 hours)
- v0.6.0 Knowledge Sync: 1 issue (~20-25 hours)
- v1.0.0 Stable Release: 1 issue (~80-100 hours)

**Breakdown by Type**:
- Features: 24 issues (80%)
- Documentation: 3 issues (10%)
- Testing: 1 issue (3%)
- Release: 2 issues (7%)

**Breakdown by Priority**:
- P0 (Critical): 14 issues (47%)
- P1 (High): 9 issues (30%)
- P2 (Medium): 7 issues (23%)
- P3 (Low): 0 issues

## Next Steps

1. Create GitHub project board
2. Run devops-engineer to create actual issues
3. Assign issues to milestones in GitHub
4. Begin implementation in priority order
5. Move completed issues to `/completed/` directory

## Notes

- Issues are comprehensive with detailed implementation notes
- Each issue includes acceptance criteria and definition of done
- Dependencies are clearly documented
- Examples and code snippets provided where helpful
- Ready for devops-engineer processing
