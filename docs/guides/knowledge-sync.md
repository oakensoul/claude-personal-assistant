---
title: "Knowledge Sync System"
description: "Safely extract and store project knowledge in your PKM with automatic data scrubbing"
category: "guide"
tags: ["knowledge-sync", "pkm", "obsidian", "privacy", "data-scrubbing"]
last_updated: "2025-10-04"
status: "published"
audience: "users"
---

# Knowledge Sync System

**Safely extract and store knowledge from project repositories into your Personal Knowledge Management system.**

---

## Overview

The Knowledge Sync system helps you build a comprehensive personal knowledge base by extracting useful information from projects you work on while automatically scrubbing sensitive corporate data, PII, and proprietary information.

### The Problem

You work on many projects and repositories:

- Each has valuable docs, patterns, solutions
- You want to remember these learnings
- But they contain corporate data, internal URLs, PII
- Your PKM should be "safe to share"

### The Solution

```text
You: "jarvis-sync-knowledge"

Claude:
1. Scans current project for knowledge artifacts
2. Identifies useful documentation
3. Scrubs sensitive information
4. Converts to your PKM format
5. Saves to ~/Knowledge/Obsidian-Vault/
6. Updates index and links
```

---

## Command: jarvis-sync-knowledge

### Basic Usage

```bash
# In a project directory
cd ~/Development/work/company-api/
jarvis-sync-knowledge
```

### What It Does

**1. Discovery Phase:**

- Scans for documentation:
  - `README.md`, `DOCS/`, `docs/`
  - Architecture decision records (ADRs)
  - API documentation
  - Setup guides, troubleshooting docs
  - Code comments with valuable patterns
  - Wiki pages (if available)

**2. Analysis Phase:**

- Identifies valuable knowledge:
  - Architecture patterns
  - Technical decisions
  - Common problems and solutions
  - Best practices
  - Gotchas and pitfalls
  - Setup procedures
  - Testing strategies

**3. Scrubbing Phase:**

- Removes sensitive information:
  - Company names and internal URLs
  - Employee names and contact info
  - API keys, tokens, credentials
  - Internal system names
  - Proprietary algorithms
  - Customer data
  - Financial information
  - IP addresses and hostnames

**4. Transformation Phase:**

- Converts to your PKM format:
  - Obsidian markdown format
  - Adds tags and metadata
  - Creates backlinks
  - Structures hierarchically
  - Adds "Source" attribution (sanitized)

**5. Storage Phase:**

- Saves to your PKM:
  - `~/Knowledge/Obsidian-Vault/Tech-Knowledge/`
  - Organized by topic/technology
  - Linked to related notes
  - Indexed for search

---

## Configuration

### In `~/.claude/knowledge/procedures.md`

```markdown
## jarvis-sync-knowledge

**Trigger**: User says "jarvis-sync-knowledge" in a project directory

**Procedure**:

1. **Discovery** - Scan project for knowledge artifacts:

   ```text
   Find:
   - README.md, CONTRIBUTING.md
   - docs/, documentation/, wiki/
   - ADRs (Architecture Decision Records)
   - API specs (OpenAPI, GraphQL schemas)
   - ARCHITECTURE.md, DESIGN.md
   - Common problem solutions in issues/discussions
   ```

2. **Categorization** - Identify knowledge types:

   - Architecture & Design
   - Technical Patterns
   - Problem-Solution pairs
   - Setup & Configuration
   - Testing Strategies
   - Performance Optimizations
   - Security Practices

3. **Scrubbing** - Remove sensitive information:

   **Always Scrub:**

   - Company name → [COMPANY]
   - Employee names → [DEVELOPER], [TEAM]
   - Email addresses → [EMAIL]
   - Internal domains → [INTERNAL]
   - API keys/tokens → [REDACTED]
   - Customer names → [CUSTOMER]
   - Specific IP addresses → [IP]
   - Internal tool names → [TOOL]
   - Proprietary algorithms → [IMPLEMENTATION]

   **Preserve:**

   - Technology names (React, PostgreSQL, etc.)
   - Open source library names
   - Public documentation links
   - General architecture patterns
   - Problem-solving approaches
   - Code patterns (if non-proprietary)

4. **Transform** - Convert to PKM format:

   ```markdown
   ---
   title: [Topic] - [Pattern/Solution]
   tags: [tech-stack, pattern-type, problem-area]
   source: [Sanitized project description]
   date: YYYY-MM-DD
   ---

   # [Topic]

   ## Context
   [What problem this solves]

   ## Pattern/Solution
   [The approach, sanitized]

   ## Implementation Notes
   [Key points, sanitized]

   ## Related
   [[Other relevant notes]]
   ```

5. **Save** - Store in PKM:

   - Determine category (e.g., Backend Patterns, React Patterns, DevOps)
   - Save to appropriate folder
   - Update index notes
   - Create backlinks

6. **Report**:

   ```text
   Synced knowledge from [Project]:
   - 3 architecture patterns
   - 5 problem-solution pairs
   - 2 setup procedures
   - 1 performance optimization

   Saved to: ~/Knowledge/Obsidian-Vault/Tech-Knowledge/
   - Backend-Patterns/api-rate-limiting.md
   - React-Patterns/server-components.md
   - ...

   Scrubbed: 15 company references, 8 internal URLs, 3 names
   ```

**Safety Check**:

Before saving, ask user:
"Ready to sync? Review scrubbed content? (y/n/review)"

---

## Scrubbing Rules

### Corporate Information

**Scrub:**

```text
Acme Corp → [COMPANY]
acme.internal → [INTERNAL]
api.acme.com → [API_ENDPOINT]
John Smith, Senior Engineer → [TEAM_MEMBER]
<john.smith@acme.com> → [EMAIL]
```

**Keep:**

```text
This API uses REST
Built with Node.js and Express
Deployed on AWS
Uses PostgreSQL 14
```

### URLs and Endpoints

**Scrub:**

```text
<https://internal.company.com/docs> → [INTERNAL_DOCS]
<https://jira.company.com/PROJECT-123> → [TICKET_SYSTEM]
ssh://git@internal-git.company.com → [INTERNAL_GIT]
```

**Keep:**

```text
<https://docs.aws.amazon.com/>...
<https://reactjs.org/docs/>...
<https://github.com/public-org/public-repo>
```

### Code Examples

**Scrub proprietary business logic:**

```javascript
// BEFORE (proprietary)
function calculateAcmeRevenue(customer) {
  return customer.sales * ACME_MARGIN * PROPRIETARY_COEFFICIENT;
}

// AFTER (sanitized)
function calculateMetric(data) {
  return data.value * CONSTANT * FACTOR;
  // Pattern: multiplication-based calculation
}
```

**Keep general patterns:**

```javascript
// Pattern: Rate limiting with Redis
const rateLimit = require('express-rate-limit');
const RedisStore = require('rate-limit-redis');

const limiter = rateLimit({
  store: new RedisStore({ client: redis }),
  windowMs: 15 * 60 * 1000,
  max: 100
});
```

### Names and Identifiers

**Scrub:**

- Employee names
- Customer names
- Project codenames
- Internal team names
- Service names (if proprietary)

**Keep:**

- Role descriptions ("the backend team")
- Generic terms ("the client", "the service")
- Technology names

---

## PKM Organization

### Folder Structure

```text
~/Knowledge/Obsidian-Vault/
├── Tech-Knowledge/
│   ├── Backend-Patterns/
│   │   ├── api-design.md
│   │   ├── database-optimization.md
│   │   └── caching-strategies.md
│   ├── Frontend-Patterns/
│   │   ├── react-state-management.md
│   │   ├── component-architecture.md
│   │   └── performance-tips.md
│   ├── DevOps/
│   │   ├── ci-cd-patterns.md
│   │   ├── deployment-strategies.md
│   │   └── monitoring-setup.md
│   ├── Problem-Solutions/
│   │   ├── debugging-memory-leaks.md
│   │   ├── handling-race-conditions.md
│   │   └── optimizing-queries.md
│   └── Index.md              # Master index
│
└── Projects/
    └── Work/
        └── Project-Learnings.md  # High-level learnings (sanitized)
```

### Note Template

````markdown
---
title: Rate Limiting with Redis
tags: [backend, api, redis, rate-limiting, performance]
source: Internal API project
date: 2025-10-04
status: validated
related: [[API Design]], [[Redis Patterns]], [[Performance]]
---

# Rate Limiting with Redis

## Context

Need to prevent API abuse while maintaining good UX for legitimate users.

## Problem

- API endpoints were getting hammered
- No rate limiting in place
- Needed distributed solution (multiple servers)

## Solution

Used Redis-backed rate limiting with express-rate-limit:

```javascript
// Pattern implementation
const rateLimit = require('express-rate-limit');
const RedisStore = require('rate-limit-redis');

const limiter = rateLimit({
  store: new RedisStore({
    client: redisClient,
    prefix: 'rl:'
  }),
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each key to 100 requests per window
  message: 'Too many requests, please try again later'
});

app.use('/api/', limiter);
```

## Key Insights

- Redis provides distributed state across servers
- Sliding window is more fair than fixed window
- Different endpoints need different limits
- Include rate limit info in response headers

## Gotchas

- Redis must be highly available (rate limiting fails open if Redis is down)
- Need monitoring on rate limit hits
- Consider different limits for authenticated vs anonymous
- Include client-friendly error messages

## Related Patterns

- [[API Circuit Breakers]]
- [[Redis Caching]]
- [[API Gateway Patterns]]

## References

- [Express Rate Limit Docs](https://www.npmjs.com/package/express-rate-limit)
- [Redis Best Practices](https://redis.io/docs/manual/patterns/)

---

**Source**: Learned from [COMPANY] API project
**Sanitized**: 2025-10-04
**Validated**: Works in production-scale applications
````

---

## Advanced Features

### Selective Sync

```bash
# Sync specific topics
jarvis-sync-knowledge --topics="api-design,caching"

# Sync specific files
jarvis-sync-knowledge --files="docs/architecture.md,docs/api.md"

# Dry run (preview what would be synced)
jarvis-sync-knowledge --dry-run
```

### Sync Profiles

Define different scrubbing profiles for different contexts:

**`~/.claude/config/sync-profiles.yaml`:**

```yaml
profiles:
  work:
    scrub_company: true
    scrub_names: true
    scrub_internal_urls: true
    preserve_architecture: true

  open-source:
    scrub_company: false
    scrub_names: false
    scrub_internal_urls: true
    preserve_all: true

  learning:
    scrub_company: true
    scrub_names: true
    extract_patterns_only: true
```

**Usage:**

```bash
jarvis-sync-knowledge --profile=work
jarvis-sync-knowledge --profile=open-source
```

### Conflict Resolution

If knowledge already exists:

```text
Found existing note: "API Rate Limiting"

Options:
1. Merge (combine with existing)
2. Replace (overwrite existing)
3. Create new version (api-rate-limiting-v2.md)
4. Skip (don't sync this)

Choose: _
```

---

## Safety & Best Practices

### Before Syncing

**Review the project:**

- Is this work/proprietary or open source?
- What information is sensitive?
- What can be safely extracted?

**Check your employment agreement:**

- Some companies restrict taking any work-related knowledge
- When in doubt, be more conservative with scrubbing
- Consider whether the pattern is truly public/common knowledge

### During Sync

**Review scrubbed content:**

```bash
jarvis-sync-knowledge --review
# Shows side-by-side: original vs scrubbed
# You approve each piece before saving
```

**Err on the side of caution:**

- When unsure, scrub it
- Better to lose some context than leak sensitive data
- You can always add back non-sensitive details later

### After Sync

**Audit occasionally:**

```bash
jarvis-audit-knowledge --check-sensitive
# Scans your PKM for patterns that might be sensitive:
# - Company names that slipped through
# - Internal URLs
# - Potential PII
```

**Keep PKM private:**

- Your Obsidian vault should be in a private repo
- Don't share your entire PKM publicly
- Individual notes can be shared if reviewed

---

## Integration with AIDE

### Project Agents Can Trigger Sync

When finishing a project:

```text
You: "jarvis-project-complete ProjectAlpha"

Claude:
1. Updates project status to Complete
2. Asks: "Sync learnings to PKM? (y/n)"
3. If yes, runs jarvis-sync-knowledge
4. Extracts key learnings automatically
5. Archives project with sanitized summary
```

### Weekly Knowledge Reviews

In `~/.claude/knowledge/workflows.md`:

```markdown
## Weekly Review Workflow

Every Sunday:
1. Review completed work
2. Identify knowledge worth preserving
3. Run jarvis-sync-knowledge for key projects
4. Update Tech-Knowledge index
5. Create links between related learnings
```

### Memory Integration

```text
jarvis-sync-knowledge also updates memory:

~/.claude/memory/context.md:
- Last knowledge sync: 2025-10-04
- Synced from: 3 projects
- Added: 8 patterns, 5 solutions
- PKM size: 234 notes
```

---

## Example Workflows

### Workflow 1: End of Project

```text
You: "Just finished the API refactor project"

jarvis: "Nice work! Want to preserve learnings for your PKM?"

You: "Yes"

jarvis: "Scanning project for valuable knowledge..."

        Found:
        - API design patterns (new)
        - Rate limiting implementation (update existing)
        - Error handling approach (new)
        - Testing strategy (new)

        Scrubbing company references...

        Preview:
        1. API Design: RESTful patterns for [SERVICE_TYPE]
        2. Rate Limiting: Redis-backed distributed limiting
        3. Error Handling: Consistent error response format
        4. Testing: Integration test patterns

        Looks good? (y/n/review)

You: "y"

jarvis: "✅ Synced to Tech-Knowledge/
        - Backend-Patterns/api-design-rest.md
        - Backend-Patterns/rate-limiting-redis.md
        - Testing/integration-test-patterns.md

        Updated index and created backlinks.
        Your PKM now has 237 notes."
```

### Workflow 2: Learning from Open Source

```text
You: "Just read through the Next.js codebase, lots of good patterns"

jarvis-sync-knowledge --profile=open-source

jarvis: "Scanning Next.js source for patterns..."

        Found valuable patterns:
        - Server Components architecture
        - Build optimization techniques
        - Route handling
        - Caching strategies

        No scrubbing needed (open source).

        Synced to Frontend-Patterns/:
        - nextjs-server-components.md
        - nextjs-build-optimization.md
        - nextjs-caching.md
```

### Workflow 3: Solving a Problem

```text
You: "Just figured out how to fix that memory leak"

jarvis: "Great! Want to document this for future reference?"

You: "Yes, but it's in our proprietary code"

jarvis-sync-knowledge --extract-pattern

jarvis: "I'll extract just the problem-solving approach,
        not the specific implementation.

        Creating note:
        Title: Debugging Memory Leaks in [FRAMEWORK]

        Pattern:
        1. Used heap snapshots to identify growth
        2. Tracked object retention
        3. Found event listeners not being cleaned up
        4. Solution: useEffect cleanup functions

        Saved to Problem-Solutions/debugging-memory-leaks.md"
```

---

## Configuration

### Default Settings

**`~/.claude/config/sync-settings.yaml`:**

```yaml
sync:
  default_profile: work

  scrubbing:
    company_name: "[COMPANY]"
    internal_domain_pattern: "*.company.com"
    always_scrub:
      - employee_names: true
      - emails: true
      - api_keys: true
      - customer_data: true

  pkm:
    base_path: "~/Knowledge/Obsidian-Vault/Tech-Knowledge"
    create_backlinks: true
    update_index: true
    add_metadata: true

  extraction:
    include_code_examples: true
    max_code_length: 50  # lines
    include_architecture_diagrams: true
    include_problem_solutions: true

  safety:
    dry_run_by_default: false
    require_review: true  # Show preview before saving
    create_backup: true
```

---

## Roadmap

### Phase 2: Basic Implementation

- [ ] Implement jarvis-sync-knowledge command
- [ ] Basic scrubbing rules
- [ ] Simple PKM storage
- [ ] Manual review process

### Phase 3: Enhanced Features

- [ ] Automatic scrubbing profiles
- [ ] Intelligent pattern extraction
- [ ] Conflict resolution
- [ ] Knowledge audit tools

### Phase 4: Advanced

- [ ] AI-powered scrubbing (detect sensitive patterns)
- [ ] Knowledge graph building
- [ ] Automatic categorization
- [ ] Similar pattern detection
- [ ] Knowledge recommendations

---

## Privacy & Legal

### What's Legal?

**Generally OK to extract:**

- Common design patterns
- General problem-solving approaches
- Technology-agnostic learnings
- Public knowledge (from open source)

**Generally NOT OK:**

- Proprietary algorithms
- Business logic specific to your employer
- Customer data
- Trade secrets
- Anything in your NDA

### Best Practice

**When in doubt:**

1. Extract the **pattern**, not the **implementation**
2. Make it **generic**, not **specific**
3. Ask yourself: "Could I have learned this from public sources?"
4. If uncertain, don't sync it

### Your Responsibility

AIDE helps you scrub technical identifiers, but **you** are responsible for:

- Understanding your employment agreement
- Knowing what's proprietary vs public knowledge
- Making the final call on what to preserve
- Ensuring compliance with your company's policies

**This tool is for preserving general learnings, not circumventing NDAs.**

---

## See Also

- [Obsidian Integration](obsidian-integration.md)
- [Project Agents](../project-agents/README.md)
- [Memory System](../architecture/ARCHITECTURE.md#memory-system)
- [Privacy & Security](../architecture/ARCHITECTURE.md#security-model)

---

**Knowledge Sync: Build your PKM safely and systematically.** 🧠✨
