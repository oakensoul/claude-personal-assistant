---
title: "Implement memory search and filtering"
labels:
  - "type: feature"
  - "priority: p1"
  - "effort: medium"
  - "milestone: 0.3.0"
---

# Implement memory search and filtering

## Description

Implement comprehensive search and filtering capabilities across all memory categories with relevance ranking, multiple filter criteria, and both CLI and natural language interfaces.

## Acceptance Criteria

- [ ] Memory search works across all categories
- [ ] Search supports keyword matching
- [ ] Search includes relevance ranking
- [ ] Filtering by date range supported
- [ ] Filtering by category supported
- [ ] Filtering by tags supported
- [ ] Filtering by project supported
- [ ] Combined filters work correctly (AND logic)
- [ ] Search results show context/snippets
- [ ] Performance is acceptable (<1 second for 1000 entries)
- [ ] Both CLI and natural language interfaces work

## Implementation Notes

### CLI Interface

```bash
# Keyword search
aida memory search "React patterns"

# Category filter
aida memory search --category knowledge --tag react

# Date and project filters
aida memory search --date 2025-10 --project alpha

# Combined filters
aida memory search "hooks" --category knowledge --tag react --project alpha
```

### Natural Language Interface

```
"What did I learn about React hooks last week?"
"Show me decisions from October"
"Find tasks related to project alpha"
"Search memory for PostgreSQL patterns"
```

### Search Algorithm

1. **Text Matching**:
   - Search in title/summary
   - Search in content
   - Search in tags
   - Weight title matches higher

2. **Relevance Ranking**:
   - Exact matches: highest score
   - Title matches: high score
   - Tag matches: medium score
   - Content matches: base score
   - Recent entries: slight boost
   - Multiple term matches: cumulative boost

3. **Filtering**:
   - Apply filters first to reduce search space
   - Then perform text search within filtered results
   - Return sorted by relevance

### Search Results Format

```
Found 5 results for "React hooks":

1. ⭐⭐⭐ React useEffect Cleanup Functions [Knowledge]
   Date: 2025-10-04 | Tags: #react #useEffect #hooks
   "React useEffect needs cleanup functions for subscriptions to prevent..."
   → ~/.claude/memory/knowledge/learnings.md:42

2. ⭐⭐ Custom React Hooks Pattern [Knowledge]
   Date: 2025-10-03 | Tags: #react #hooks #patterns
   "Best practices for creating reusable custom hooks..."
   → ~/.claude/memory/knowledge/patterns.md:156

3. ⭐⭐ Fix hooks dependency bug [Task - Completed]
   Date: 2025-10-02 | Project: alpha
   "Updated useEffect dependencies to prevent stale closure..."
   → ~/.claude/memory/tasks/completed.md:89

[Show all 5 results? (y/N)]
```

## Dependencies

- #031 (Memory categories provide search targets)
- #007 (Memory templates)

## Related Issues

- Part of #022 (Enhanced memory system epic)
- #023 (Knowledge capture uses search)
- #024 (Decision documentation uses search)

## Definition of Done

- [ ] Search implementation complete and tested
- [ ] All filter criteria work correctly
- [ ] Relevance ranking produces useful results
- [ ] Performance meets requirements (<1 second)
- [ ] CLI commands documented
- [ ] Natural language patterns recognized
- [ ] Search results are well-formatted
- [ ] Edge cases handled (empty results, special characters, etc.)
