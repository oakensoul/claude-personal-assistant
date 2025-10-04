---
title: "Claude Plans & Token Usage for AIDE"
description: "Understanding costs, token usage, and optimization strategies for running AIDE"
category: "reference"
tags: ["claude", "tokens", "costs", "optimization", "pricing"]
last_updated: "2025-10-04"
status: "published"
audience: "users"
---

# Claude Plans & Token Usage for AIDE

**Understanding the costs and token requirements for running an agentic assistant system.**

---

## TL;DR Recommendations

**Casual User** (few commands/day): **Claude Pro** ($20/mo) - Should be sufficient  
**Regular User** (daily workflows): **Claude Pro** ($20/mo) - Might hit limits  
**Power User** (heavy agent usage): **Claude for Work** ($30/mo/user) or **API** ($TBD/mo based on usage)  
**Developer** (building AIDE): **API** (pay-as-you-go) - Most flexible

---

## Claude Subscription Plans (2025)

### Free Tier
**Cost**: $0/month  
**Limits**: Very limited usage  
**AIDE Suitability**: ❌ **Not recommended**

**Why not for AIDE:**
- Extremely limited message count
- Can't handle daily workflows
- No sustained usage
- Will hit limits quickly

**OK for:** Testing AIDE installation only

---

### Claude Pro
**Cost**: $20/month  
**Limits**: 
- Usage limits per day (not publicly specified exact tokens)
- Resets every 24 hours
- Rate limiting during high demand

**AIDE Suitability**: ⚠️ **Maybe** - Depends on usage

**Pros:**
- Affordable for individuals
- Access to Claude Desktop (MCP servers)
- Priority access during peak times
- Access to latest models

**Cons:**
- May hit daily limits with heavy agent usage
- No guaranteed token allocation
- Limits reset daily (not rollover)

**Good for:**
- Casual AIDE users
- 3-5 significant workflows per day
- Occasional deep work sessions
- Weekend/hobby use

**Not good for:**
- Heavy daily usage
- All-day coding sessions
- Running many agents
- Large knowledge base syncs

---

### Claude Pro + Projects (coming soon)
**Cost**: $20/month (same as Pro)  
**Additional Features:**
- Project-specific context
- Better organization
- Potentially higher limits per project

**AIDE Suitability**: ⚠️ **Better** - But still may hit limits

---

### Claude for Work (Team Plans)
**Cost**: $30/month per user (minimum 5 users = $150/mo)  
**Limits**: Higher usage limits than Pro

**AIDE Suitability**: ✅ **Good** - For teams or power users

**Pros:**
- Higher token limits
- Team collaboration
- Admin controls
- Better for sustained usage

**Cons:**
- Requires 5+ users minimum
- More expensive
- Overkill for solo users

**Good for:**
- Development teams using AIDE
- Companies deploying AIDE
- Power users who can share with team

---

### Claude API (Sonnet 4)
**Cost**: Pay-per-token  
**Current Pricing** (as of 2025):
- Input: ~$3 per million tokens
- Output: ~$15 per million tokens
- Cached input: ~$0.30 per million tokens (90% discount!)

**AIDE Suitability**: ✅ **Best for power users** - Most flexible

**Pros:**
- Pay only for what you use
- No daily limits (just account limits)
- Prompt caching (huge savings!)
- Can build custom integrations
- Predictable costs

**Cons:**
- Need to build API integration
- No Claude Desktop (unless custom)
- Need to manage API keys
- Can get expensive without caching

**Good for:**
- Developers building AIDE features
- Power users with predictable patterns
- Those who want to optimize costs
- Custom integrations

---

## How AIDE Uses Tokens

### Context Window (What Claude Reads)

Every interaction, Claude reads:

**Base Context** (~5,000-10,000 tokens):
```
~/CLAUDE.md                         ~1,500 tokens
~/.claude/knowledge/system.md       ~800 tokens
~/.claude/knowledge/procedures.md   ~1,200 tokens
~/.claude/knowledge/workflows.md    ~600 tokens
~/.claude/knowledge/projects.md     ~500 tokens
~/.claude/memory/context.md         ~1,000 tokens
Project CLAUDE.md (if in project)   ~800 tokens
```

**With MCP Filesystem** (reads files as needed):
- Can dynamically load files
- Only loads what's relevant
- More efficient than always loading everything

**Total base context**: 5,000-10,000 tokens per interaction

---

## Token Usage by Activity

### Light Activities (Low Token Usage)

**Simple Commands** (~6,000-8,000 tokens total):
```
You: "jarvis-status"
→ Input: ~6,000 (context + command)
→ Output: ~500 (status report)
→ Total: ~6,500 tokens
```

**Quick Questions** (~7,000-10,000 tokens):
```
You: "What should I work on today?"
→ Input: ~7,000 (context + question)
→ Output: ~800 (suggestions)
→ Total: ~7,800 tokens
```

**Cost per interaction (API)**: ~$0.02-0.03

---

### Medium Activities (Moderate Token Usage)

**Daily Workflows** (~10,000-20,000 tokens):
```
You: "jarvis-start-day"
→ Input: ~8,000 (full context + memory)
→ Output: ~2,000 (day plan + updates)
→ File operations: ~1,000 (MCP reads/writes)
→ Total: ~11,000 tokens
```

**File Operations** (~15,000-25,000 tokens):
```
You: "jarvis-cleanup-downloads"
→ Input: ~8,000 (context)
→ MCP file scans: ~3,000 (directory listings)
→ Analysis: ~2,000 (categorization)
→ Output: ~1,500 (report + actions)
→ Total: ~14,500 tokens
```

**Project Work** (~20,000-40,000 tokens):
```
You: "Help me refactor this component"
→ Input: ~10,000 (context + code)
→ Analysis: ~5,000 (understanding code)
→ Output: ~4,000 (suggestions + examples)
→ Total: ~19,000 tokens
```

**Cost per interaction (API)**: ~$0.05-0.12

---

### Heavy Activities (High Token Usage)

**Knowledge Sync** (~50,000-150,000 tokens):
```
You: "jarvis-sync-knowledge"
→ Input: ~10,000 (context)
→ Scanning project: ~20,000 (all docs)
→ Analysis: ~15,000 (extracting patterns)
→ Scrubbing: ~10,000 (processing)
→ Output: ~8,000 (sanitized content)
→ Total: ~63,000 tokens
```

**Deep Coding Session** (~100,000-300,000 tokens):
```
2-hour coding session with continuous interaction:
- 20-30 back-and-forth exchanges
- Reading multiple files
- Generating code
- Debugging
- Testing
→ Total: ~150,000-250,000 tokens
```

**Weekly Review** (~80,000-120,000 tokens):
```
You: "jarvis-weekly-review"
→ Reading: ~30,000 (memory, history, notes)
→ Analysis: ~20,000 (summarizing week)
→ Planning: ~15,000 (next week)
→ Output: ~10,000 (comprehensive report)
→ Total: ~75,000 tokens
```

**Cost per interaction (API)**: $0.20-0.90

---

## Usage Patterns & Recommendations

### Pattern 1: Casual User

**Profile:**
- Check in 2-3 times per day
- Simple commands (status, cleanup, quick questions)
- Occasional project work
- Weekend hobby coding

**Token Usage:**
- ~50,000-100,000 tokens/day
- ~1.5M-3M tokens/month

**Recommended Plan:** **Claude Pro ($20/mo)**
- Should stay within limits
- Cost-effective
- Daily reset works well

**API Cost (if using):** ~$4.50-9/month

---

### Pattern 2: Regular Developer

**Profile:**
- Daily workflows (start-day, end-day)
- 2-4 hours of coding with Claude
- Weekly knowledge syncs
- Active project management

**Token Usage:**
- ~200,000-400,000 tokens/day
- ~6M-12M tokens/month

**Recommended Plan:** **Claude Pro ($20/mo) - will hit limits**
- Will likely hit daily limits
- Consider API for heavy days
- Use caching to reduce costs

**API Cost (if using):** ~$18-36/month (with caching: ~$10-20/month)

**Best Option:** **Hybrid approach**
- Claude Pro for daily use
- API for heavy sessions
- Switch when hitting limits

---

### Pattern 3: Power User / Team

**Profile:**
- All-day coding sessions
- Heavy agent usage
- Multiple projects
- Continuous workflow automation
- Knowledge syncs multiple times/week

**Token Usage:**
- ~500,000-1M+ tokens/day
- ~15M-30M tokens/month

**Recommended Plan:** 
- **Claude for Work ($30/mo)** if team of 5+
- **API (pay-as-you-go)** for solo power users

**API Cost:** ~$45-90/month (with caching: ~$25-50/month)

**Why API is better:**
- No daily limits
- Prompt caching (90% savings on repeated context)
- Predictable scaling
- Can optimize with caching strategies

---

### Pattern 4: AIDE Developer

**Profile:**
- Building AIDE features
- Testing workflows
- Documentation
- Multiple test scenarios

**Token Usage:**
- Highly variable
- ~300,000-800,000 tokens/day during dev
- ~9M-24M tokens/month

**Recommended Plan:** **API (pay-as-you-go)**

**Why:**
- Need flexibility
- Can implement prompt caching
- Can test cost optimizations
- No artificial limits

**Optimization:**
- Use prompt caching aggressively
- Cache AIDE context (rarely changes)
- Can reduce costs by 70-90%

**API Cost:** ~$27-72/month (with caching: ~$8-22/month)

---

## Token Optimization Strategies

### 1. Use Prompt Caching (API Only)

**What is it:**
- Claude caches frequently used context
- 90% cost reduction for cached tokens
- Cache lasts 5 minutes

**How AIDE uses it:**
```
First request:
- ~/CLAUDE.md (1,500 tokens) - CACHED
- ~/.claude/knowledge/* (3,000 tokens) - CACHED
- Total: 4,500 tokens @ $3/M = $0.0135

Next requests (within 5 min):
- Same context (4,500 tokens) - FROM CACHE
- Cost: 4,500 tokens @ $0.30/M = $0.00135
- Savings: 90%!
```

**Impact:**
- Regular user: $18/mo → $10/mo (45% savings)
- Power user: $45/mo → $25/mo (45% savings)

**Best for:**
- API users
- Frequent interactions
- Stable knowledge base

### 2. Minimize Context Size

**Keep configs lean:**
```
❌ Bad: ~/CLAUDE.md with 5,000 tokens
✅ Good: ~/CLAUDE.md with 1,500 tokens

Split into:
- Essential in CLAUDE.md
- Details in knowledge files
- Load only what's needed
```

**Impact:**
- 50% reduction in base context
- Faster responses
- Lower costs

### 3. Use MCP Filesystem Intelligently

**Only load files when needed:**
```
❌ Bad: Always load all knowledge files
✅ Good: Load files dynamically via MCP

Example:
- Base command needs procedures.md only
- Don't load projects.md unless needed
```

**Impact:**
- 30-40% token reduction
- More efficient
- Better for rate limits

### 4. Batch Operations

**Combine related tasks:**
```
❌ Bad: 
  jarvis-cleanup-downloads
  jarvis-organize-screenshots
  jarvis-update-projects
  (3 separate interactions = 3x context)

✅ Good:
  jarvis-daily-maintenance
  (1 interaction = 1x context)
```

**Impact:**
- 66% cost reduction
- Fewer API calls
- Better user experience

### 5. Optimize Knowledge Base

**Keep it focused:**
```
❌ Bad: 10,000 token procedures.md
✅ Good: 
  - 1,000 token procedures.md (essentials)
  - Detailed procedures in separate files
  - Load on demand
```

**Impact:**
- Significant token savings
- Faster loads
- More maintainable

---

## What Happens When You Hit Limits?

### Claude Pro Daily Limits

**Symptoms:**
- "You've reached your usage limit"
- Can't send new messages
- Resets next day

**What to do:**
1. **Wait** - Limits reset every 24 hours
2. **Switch to API** - For urgent work
3. **Optimize** - Reduce token usage
4. **Upgrade** - Consider Claude for Work or API

### API Rate Limits

**Limits:**
- Requests per minute
- Tokens per minute
- Account-level limits

**What to do:**
1. **Implement backoff** - Retry with delays
2. **Batch requests** - Combine operations
3. **Contact Anthropic** - Request limit increase

---

## Cost Comparison Examples

### Scenario 1: Developer Coding Session (2 hours)

**With Claude Pro:**
- Unlimited (within daily limit)
- May hit limit if heavy
- **Cost: $0.67/day** ($20/mo ÷ 30 days)

**With API + Caching:**
- 150,000 tokens (with caching)
- Input: 120,000 @ $0.30/M (cached) = $0.036
- Output: 30,000 @ $15/M = $0.45
- **Cost: ~$0.49/session**

**Verdict:** Pro is better for sustained daily use, API for occasional deep dives

---

### Scenario 2: Daily AIDE Workflows (Month)

**Light Use** (50K tokens/day):
- **Claude Pro**: $20/mo (within limits)
- **API**: ~$4.50/mo with caching
- **Verdict**: API cheaper if you can manage it

**Heavy Use** (500K tokens/day):
- **Claude Pro**: $20/mo (will hit limits)
- **API**: ~$25/mo with caching
- **Verdict**: API more reliable despite higher cost

---

### Scenario 3: Team of 5 Developers

**Each developer:** 300K tokens/day average

**Claude for Work:**
- 5 users × $30/mo = $150/mo
- Higher limits
- Team features

**API (shared account):**
- 300K × 5 × 30 days = 45M tokens/mo
- With caching: ~$135/mo
- Full flexibility

**Verdict:** API slightly cheaper and more flexible, Work better for team features

---

## Recommendations by Use Case

### Solo Developer (You)

**Starting out with AIDE:**
→ **Claude Pro** ($20/mo)
- Try it for a month
- See your usage patterns
- Upgrade if hitting limits

**Heavy AIDE user:**
→ **API** (pay-as-you-go)
- ~$25-50/mo for power user
- Implement prompt caching
- More predictable
- No daily limits

### Small Team (2-4 people)

→ **API** (shared)
- Cheaper than Team plan
- More flexible
- Can scale up/down
- ~$50-100/mo total

### Company/Large Team (5+ people)

→ **Claude for Work** ($30/user/mo)
- Team management
- SSO, admin controls
- Support
- Worth the premium

---

## Token Tracking & Budgeting

### For API Users

**Track usage:**
```python
# In your AIDE integration
import anthropic

client = anthropic.Anthropic(api_key="...")

# Track tokens
response = client.messages.create(...)
print(f"Input tokens: {response.usage.input_tokens}")
print(f"Output tokens: {response.usage.output_tokens}")

# Calculate cost
input_cost = response.usage.input_tokens * 0.000003
output_cost = response.usage.output_tokens * 0.000015
print(f"Total cost: ${input_cost + output_cost:.4f}")
```

**Set budgets:**
```python
# Alert when approaching budget
monthly_budget = 50  # dollars
current_spend = track_usage()

if current_spend > monthly_budget * 0.8:
    print("⚠️ 80% of monthly budget used")
```

### For Claude Pro Users

**Track manually:**
- Note when you hit limits
- Count interactions per day
- Estimate token usage
- Upgrade if consistently hitting limits

---

## Future Considerations

### Claude Team/Enterprise

Anthropic is likely to offer:
- Higher token limits
- Better team features
- Custom models
- Priority support

**Watch for:**
- Announcements at anthropic.com
- Pricing updates
- New tiers

### API Improvements

**Coming:**
- Better prompt caching
- Lower prices (competition)
- Batch API (cheaper bulk requests)
- Fine-tuned models

---

## Bottom Line Recommendations

**Most AIDE Users:**
→ Start with **Claude Pro** ($20/mo)
→ Upgrade to **API** if you hit limits ($25-50/mo typical)

**Power Users:**
→ **API from day one** ($25-75/mo)
→ Implement prompt caching
→ Track and optimize

**Teams:**
→ **5+ users**: Claude for Work ($150/mo)
→ **2-4 users**: Shared API ($50-100/mo)

**Developers:**
→ **API** (pay-as-you-go)
→ Dev/test on lower models (Haiku)
→ Production on Sonnet

---

## FAQ

**Q: Can I use Free Claude with AIDE?**  
A: No, limits are too restrictive. You'll hit them immediately.

**Q: Is Claude Pro enough for daily AIDE use?**  
A: For light-medium use, yes. For heavy use, you'll hit limits.

**Q: How do I know if I need API?**  
A: If you hit Pro daily limits more than 2-3 times/week, get API.

**Q: What's the cheapest way to run AIDE?**  
A: Claude Pro for casual use. API with caching for power users.

**Q: Can I mix Pro and API?**  
A: Yes! Use Pro for regular work, API for heavy sessions.

**Q: How much does a typical developer spend on API?**  
A: $25-50/month with prompt caching. $50-100 without.

**Q: Is AIDE expensive to run?**  
A: Not really. $20-50/mo for most users. Similar to other SaaS tools.

---

## Resources

- [Anthropic Pricing](https://www.anthropic.com/pricing)
- [API Documentation](https://docs.anthropic.com/)
- [Prompt Caching Guide](https://docs.anthropic.com/en/docs/build-with-claude/prompt-caching)
- [Token Counter](https://www.anthropic.com/tools/token-counter)

---

**Plan wisely, optimize aggressively, and AIDE will be cost-effective! 💰**