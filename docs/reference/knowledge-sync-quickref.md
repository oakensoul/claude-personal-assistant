---
title: "Knowledge Sync - Quick Reference"
description: "Quick guide to extracting learnings from projects into your PKM safely"
category: "reference"
tags: ["knowledge-sync", "pkm", "obsidian", "privacy", "quickref"]
last_updated: "2025-10-04"
status: "published"
audience: "users"
---

# Knowledge Sync - Quick Reference

Extract learnings from projects into your PKM while automatically scrubbing sensitive data.

---

## The Problem

- You learn valuable patterns and solutions at work
- But they're mixed with proprietary code and company data
- You want to remember the **patterns**, not leak the **secrets**
- Your PKM should be safe to share

## The Solution

```
cd ~/Development/work/my-project/
jarvis-sync-knowledge

→ Extracts patterns, scrubs sensitive data, saves to PKM
```

---

## What Gets Synced

✅ **Preserved:**
- Architecture patterns
- Technical solutions
- Problem-solving approaches
- Technology-agnostic learnings
- Code patterns (if generic)
- Best practices

❌ **Scrubbed:**
- Company names → `[COMPANY]`
- Employee names → `[DEVELOPER]`
- Internal URLs → `[INTERNAL]`
- API keys → `[REDACTED]`
- Customer data → `[CUSTOMER]`
- Proprietary algorithms → `[IMPLEMENTATION]`

---

## Quick Examples

### Example 1: API Pattern

**Before (in project):**
```javascript
// Acme Corp rate limiting for api.acme.com
function rateLimit() {
  return new RateLimiter({
    endpoint: 'https://redis.acme.internal',
    limit: ACME_API_LIMIT
  });
}
```

**After (in PKM):**
```javascript
// Rate limiting pattern
function rateLimit() {
  return new RateLimiter({
    endpoint: '[REDIS_ENDPOINT]',
    limit: RATE_LIMIT_VALUE
  });
}
```

### Example 2: Architecture Decision

**Before:**
```markdown
We chose PostgreSQL for the Acme customer database 
because John Smith found that MongoDB couldn't handle 
our complex customer relationships with GlobalMegaCorp.
```

**After:**
```markdown
Chose PostgreSQL over MongoDB for this use case because:
- Complex relational data model
- Need for ACID compliance
- Better support for complex queries
```

---

## Common Use Cases

### 1. End of Project
```
You: "Project complete, let's preserve learnings"
jarvis-sync-knowledge

→ Extracts: patterns, decisions, solutions
→ Saves to: Tech-Knowledge/
```

### 2. Solved Tricky Problem
```
You: "Just fixed that memory leak"
jarvis-sync-knowledge --extract-pattern

→ Documents: problem-solving approach
→ Saves to: Problem-Solutions/
```

### 3. Learning from Open Source
```
You: "Studied Next.js codebase"
jarvis-sync-knowledge --profile=open-source

→ No scrubbing needed (public)
→ Saves patterns to PKM
```

### 4. Weekly Review
```
You: "Review this week's work"
jarvis-sync-knowledge --week

→ Scans week's commits
→ Identifies learnings
→ Preserves knowledge
```

---

## Commands

### Basic
```bash
jarvis-sync-knowledge              # Sync current project
```

### With Options
```bash
jarvis-sync-knowledge --dry-run    # Preview what would sync
jarvis-sync-knowledge --review     # Review before saving
jarvis-sync-knowledge --profile=work  # Use work scrubbing profile
```

### Selective
```bash
jarvis-sync-knowledge --topics="api,caching"  # Only specific topics
jarvis-sync-knowledge --files="docs/api.md"   # Only specific files
```

---

## PKM Structure

```
~/Knowledge/Obsidian-Vault/Tech-Knowledge/
├── Backend-Patterns/
│   ├── api-design.md
│   ├── rate-limiting.md
│   └── caching-strategies.md
├── Frontend-Patterns/
│   ├── react-patterns.md
│   └── state-management.md
├── Problem-Solutions/
│   ├── memory-leaks.md
│   └── race-conditions.md
└── Index.md
```

---

## Safety Checklist

Before syncing, ask yourself:

- [ ] Is this a general pattern or proprietary logic?
- [ ] Could I have learned this from public sources?
- [ ] Would my employer be okay with this?
- [ ] Have I reviewed what will be scrubbed?
- [ ] Is my PKM in a private repo?

**When in doubt, extract the pattern, not the implementation.**

---

## Configuration

**`~/.claude/config/sync-settings.yaml`:**

```yaml
sync:
  default_profile: work
  scrubbing:
    company_name: "[COMPANY]"
    always_scrub:
      - employee_names: true
      - emails: true
      - api_keys: true
  pkm:
    base_path: "~/Knowledge/Obsidian-Vault/Tech-Knowledge"
  safety:
    require_review: true
```

---

## Legal Note

⚠️ **Your Responsibility:**

This tool helps scrub identifiers, but **you** must:
- Understand your employment agreement
- Know what's proprietary vs public knowledge
- Make the final call on what to preserve
- Ensure compliance with company policies

**Extract patterns, not secrets. When unsure, don't sync.**

---

## Resources

- [Full Guide](knowledge-sync.md) - Complete documentation
- [Obsidian Integration](obsidian-integration.md) - PKM setup
- [Privacy & Security](../architecture/ARCHITECTURE.md#security-model)

---

**Build your knowledge base safely and systematically.** 🧠✨