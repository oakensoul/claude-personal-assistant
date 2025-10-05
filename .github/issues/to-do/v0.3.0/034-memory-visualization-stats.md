---
title: "Implement memory visualization and statistics"
labels:
  - "type: feature"
  - "priority: p2"
  - "effort: small"
  - "milestone: 0.3.0"
---

# Implement memory visualization and statistics

## Description

Implement memory statistics and visualization features to help users understand their memory usage patterns, identify trends, and monitor memory health.

## Acceptance Criteria

- [ ] Memory statistics show total entries by category
- [ ] Memory statistics show distribution percentages
- [ ] Memory statistics show entries by time period (month/week)
- [ ] Memory statistics show storage size
- [ ] Memory statistics show most active tags
- [ ] Memory statistics show most active projects
- [ ] CLI command provides clear visualization
- [ ] Support for detailed vs summary views
- [ ] Statistics calculate quickly (<1 second)
- [ ] Output is well-formatted and readable

## Implementation Notes

### CLI Interface

```bash
# Summary statistics
aida memory stats

# Detailed statistics
aida memory stats --detailed

# Category-specific stats
aida memory stats --category knowledge

# Time-based stats
aida memory stats --month 2025-10
aida memory stats --since 2025-09-01
```

### Statistics Output Format

**Summary View**:
```
Memory Statistics
==================

Total Entries: 1,247

By Category:
  Tasks:       342 (27%) ███████░░░
  Knowledge:   508 (41%) ██████████
  Decisions:    67 (5%)  █░░░░░░░░░
  Preferences:  23 (2%)  ░░░░░░░░░░
  Context:     307 (25%) ██████░░░░

By Month:
  2025-10:     423 entries
  2025-09:     387 entries
  2025-08:     247 entries
  [older: 190 entries]

Storage:       12.3 MB

Most Active Tags:
  #react        147 entries
  #golang        89 entries
  #architecture  72 entries
  #api-design    56 entries
  #testing       43 entries
```

**Detailed View**:
```
Memory Statistics (Detailed)
============================

Total Entries: 1,247
Storage: 12.3 MB (12,883,456 bytes)
Average Entry Size: 10.3 KB

Categories:
┌─────────────┬─────────┬────────┬──────────┬────────────┐
│ Category    │ Entries │ %      │ Size     │ Avg Size   │
├─────────────┼─────────┼────────┼──────────┼────────────┤
│ Tasks       │     342 │ 27.4%  │  2.8 MB  │  8.4 KB    │
│ Knowledge   │     508 │ 40.7%  │  6.2 MB  │ 12.5 KB    │
│ Decisions   │      67 │  5.4%  │  1.1 MB  │ 16.8 KB    │
│ Preferences │      23 │  1.8%  │  0.2 MB  │  8.9 KB    │
│ Context     │     307 │ 24.6%  │  2.0 MB  │  6.7 KB    │
└─────────────┴─────────┴────────┴──────────┴────────────┘

Monthly Activity:
┌──────────┬─────────┬──────────┬──────────────────────────────┐
│ Month    │ Entries │ Change   │ Activity                     │
├──────────┼─────────┼──────────┼──────────────────────────────┤
│ 2025-10  │     423 │  +9.3%   │ ████████████████████████████ │
│ 2025-09  │     387 │ +56.7%   │ █████████████████████░░░░░░░ │
│ 2025-08  │     247 │ +29.5%   │ ████████████░░░░░░░░░░░░░░░░ │
│ 2025-07  │     190 │     -    │ ██████████░░░░░░░░░░░░░░░░░░ │
└──────────┴─────────┴──────────┴──────────────────────────────┘

Top Tags (Top 10):
┌─────────────────┬─────────┬────────┐
│ Tag             │ Entries │ %      │
├─────────────────┼─────────┼────────┤
│ #react          │     147 │ 11.8%  │
│ #golang         │      89 │  7.1%  │
│ #architecture   │      72 │  5.8%  │
│ #api-design     │      56 │  4.5%  │
│ #testing        │      43 │  3.4%  │
│ #database       │      38 │  3.0%  │
│ #deployment     │      34 │  2.7%  │
│ #performance    │      29 │  2.3%  │
│ #security       │      24 │  1.9%  │
│ #debugging      │      21 │  1.7%  │
└─────────────────┴─────────┴────────┘

Active Projects:
┌──────────────┬─────────┬──────────────────┐
│ Project      │ Entries │ Categories       │
├──────────────┼─────────┼──────────────────┤
│ alpha        │      89 │ T:42, K:31, D:16 │
│ beta         │      67 │ T:38, K:25, D:4  │
│ gamma        │      43 │ T:22, K:18, D:3  │
│ infrastructure│     28 │ T:12, K:14, D:2  │
└──────────────┴─────────┴──────────────────┘

Health Indicators:
  ✓ Regular activity (entries added daily)
  ✓ Balanced category distribution
  ✓ Knowledge capture active (40.7% of entries)
  ! Decisions could use more documentation (5.4%)
  ✓ Storage within healthy limits (<100 MB)
```

### Calculation Logic

**Entry Counting**:
- Parse all markdown files in memory categories
- Count entries by detecting `## [Title]` headers
- Extract metadata from each entry

**Size Calculation**:
- Use file system stats for accurate sizes
- Calculate averages and totals
- Format using human-readable units (KB, MB)

**Tag Frequency**:
- Extract all tags (#word) from entries
- Count occurrences
- Sort by frequency

**Project Activity**:
- Extract project references from metadata
- Group entries by project
- Show category breakdown per project

**Trend Analysis**:
- Group entries by month based on date metadata
- Calculate growth/decline percentages
- Detect activity patterns

## Dependencies

- #031 (Memory categories to analyze)
- #032 (Search functionality for data extraction)

## Related Issues

- Part of #022 (Enhanced memory system epic)
- Complements #032 (Search helps find specific data, stats show overall patterns)

## Definition of Done

- [ ] Summary statistics implemented
- [ ] Detailed statistics implemented
- [ ] Category breakdowns accurate
- [ ] Time-based analysis works
- [ ] Tag frequency analysis works
- [ ] Project activity tracking works
- [ ] Performance is acceptable (<1 second)
- [ ] Output formatting is clear and readable
- [ ] CLI commands documented
- [ ] Edge cases handled (empty categories, no tags, etc.)
