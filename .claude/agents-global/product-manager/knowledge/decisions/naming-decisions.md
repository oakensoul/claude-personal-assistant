---
title: "Naming Decisions"
category: "decisions"
tags: ["naming", "branding", "decision-record", "identity"]
last_updated: "2025-10-04"
decision_date: "2025-10-04"
status: "decided"
---

# Decision: AIDE → AIDA Naming Evolution

## Context

During initial development, the project was named AIDE (Agentic Intelligence & Digital Environment). After consideration, we changed to AIDA (Agentic Intelligence Digital Assistant).

## Decision

**We renamed from AIDE to AIDA**.

**AIDA** stands for: **Agentic Intelligence Digital Assistant**

## Rationale

### Why AIDA Over AIDE?

#### 1. Clearer Meaning

**AIDE**:

- Acronym: Agentic Intelligence & Digital Environment
- "Environment" is vague - what kind of environment?
- Sounds medical (aide = healthcare worker, nurse's aide)
- Less immediately clear what it does

**AIDA**:

- Acronym: Agentic Intelligence Digital Assistant
- "Assistant" is crystal clear - it assists you
- Immediately understandable (everyone knows what an assistant does)
- No confusion with other meanings

**Result**: AIDA is more intuitive for new users.

#### 2. Pop Culture Reference

**AIDE**:

- No strong pop culture connections
- Generic term

**AIDA**:

- **A.I.D.A.** from Marvel's Agents of S.H.I.E.L.D. (AI assistant character)
- Fits superhero AI assistant theme:
  - JARVIS (Iron Man)
  - FRIDAY (Iron Man)
  - Alfred (Batman)
  - AIDA (Agents of S.H.I.E.L.D.)
- Creates emotional connection for Marvel fans
- Reinforces "AI assistant" positioning

**Result**: AIDA is more memorable and on-brand.

#### 3. Branding & Marketability

**AIDE**:

- Sounds like "aid" (help, assistance)
- But also sounds like "aide" (helper, assistant person)
- Ambiguous pronunciation and meaning

**AIDA**:

- Sounds like "eye-da" (clear pronunciation)
- Also a common name (Aida, the opera)
- Easier to search (fewer naming conflicts)
- Better for branding (distinctive, memorable)

**Result**: AIDA is more marketable.

#### 4. Personality System Alignment

**Pre-Built Personalities**:

- JARVIS (Iron Man's AI)
- FRIDAY (Iron Man's second AI)
- Alfred (Batman's butler)
- Sage (wise advisor)
- Drill Sergeant (motivational)

**Theme**: Superhero AI assistants and helpful characters

**AIDA Fit**:

- A.I.D.A. from Agents of S.H.I.E.L.D. fits this theme
- AIDE doesn't have pop culture connection
- AIDA reinforces "you can have different AI personalities" concept

**Result**: AIDA aligns better with personality system.

#### 5. Acronym Quality

**AIDE**:

- A.I.D.E. = Agentic Intelligence & Digital Environment
- "& Digital Environment" feels forced
- "Environment" too abstract

**AIDA**:

- A.I.D.A. = Agentic Intelligence Digital Assistant
- Flows naturally
- Every word pulls its weight
- "Assistant" is concrete and clear

**Result**: AIDA is a better acronym.

## Name Components

### Directory Naming: `~/.aida/`

**Decision**: Use `~/.aida/` for framework installation directory

**Why `.aida` not `.aide`**:

- Matches product name (AIDA)
- Clear and consistent
- Avoids confusion

**Why lowercase**:

- Unix convention (dotfiles are lowercase)
- Consistent with other tools (.vim, .zsh, .config)

**Alternative Considered**: `~/.AIDA/` (uppercase)

- **Rejected**: Unconventional for Unix dotfiles
- Looks out of place next to `.vim`, `.zsh`, etc.

### Command Naming: `aida`

**Decision**: CLI command is `aida` (lowercase)

**Why lowercase**:

- Unix convention (commands are lowercase)
- Easier to type (no shift key)
- Consistent with other tools (vim, git, npm)

**Usage Examples**:

```bash
aida                    # Start conversational mode
aida status             # System status
aida personality list   # List personalities
aida help              # Help documentation
```text

**Alternative Considered**: `AIDA` (uppercase)

- **Rejected**: Unconventional for CLI tools
- Harder to type (requires shift key)

### User Config Directory: `~/.claude/`

**Decision**: User configuration in `~/.claude/` (not `~/.aida/user/`)

**Rationale**:

- Powered by Claude AI (acknowledges underlying technology)
- Separates framework (`~/.aida/`) from user data (`~/.claude/`)
- Aligns with Claude branding (Claude Code, Claude API)
- Future-proof: If user has multiple Claude-based tools, configs can coexist

**Why not `~/.aida/user/`**:

- Less clear separation between framework and user data
- Mixing framework code and user data in same directory
- Harder to back up user data separately

**Structure**:

```text
~/.aida/          # Framework (from claude-personal-assistant repo)
~/.claude/        # User config and data (user-specific)
```

### Repository Naming

**Decision**: `claude-personal-assistant` for framework repo

**Rationale**:

- Descriptive: Makes it clear what the repo contains
- Claude-branded: Acknowledges underlying AI technology
- Personal: Emphasizes individual use (not team/enterprise)
- Assistant: Reinforces product positioning

**Why not `aida`**:

- Too generic (hard to find in searches)
- Doesn't explain what it is
- Could conflict with other "aida" projects

**Why not `aida-framework`**:

- Less discoverable
- "Framework" is technical (may deter non-developers)

**Result**: `claude-personal-assistant` is clear and discoverable.

### Entry Point File: `~/CLAUDE.md`

**Decision**: Main entry point is `~/CLAUDE.md` (uppercase)

**Rationale**:

- High visibility in home directory (uppercase files sort first)
- Clearly Claude-related
- Markdown format (easy to read and edit)
- Convention established by Claude Code

**Why uppercase**:

- Stands out in `ls` output (similar to README.md, LICENSE)
- Signals importance (main entry point)
- Consistent with other "important" files (README, LICENSE, CONTRIBUTING)

**Alternative Considered**: `~/.aida/AIDA.md`

- **Rejected**: Hidden in dotfile directory (less visible)
- Users less likely to discover it

## Evolution of Naming

### Original Concept: AIDE

**When**: Initial brainstorming
**Name**: AIDE (Agentic Intelligence & Digital Environment)
**Why**: Emphasized "environment" aspect (operating system for digital life)

**Problems Identified**:

- "Environment" too vague
- No emotional connection
- Ambiguous meaning (aid vs aide vs AIDE)

### First Iteration: AIDA

**When**: Early development (before 0.1.0)
**Name**: AIDA (Agentic Intelligence Digital Assistant)
**Why**: Clearer meaning, pop culture reference, better branding

**Improvements**:

- "Assistant" is concrete and understandable
- A.I.D.A. from Marvel (emotional connection)
- Better acronym quality

### Current State: AIDA (Confirmed)

**When**: Product vision solidified
**Name**: AIDA (Agentic Intelligence Digital Assistant)
**Status**: ✅ Decided and committed

**Consistency Across**:

- Product name: AIDA
- Repository: claude-personal-assistant
- Directory: ~/.aida/
- Command: aida
- User config: ~/.claude/
- Entry point: ~/CLAUDE.md

## Alternatives Considered

### Alternative Names Brainstormed

**CAI** (Claude AI)

- ❌ Too generic
- ❌ Doesn't convey "assistant" or "personal"
- ❌ No personality

#### MENTOR

- ❌ Implies teaching/education focus (too narrow)
- ❌ Doesn't convey AI or assistant
- ❌ No acronym creativity

#### COMPANION

- ❌ Long word, harder to type
- ❌ Sounds lonely (implies user has no friends)
- ❌ No acronym

#### ALLY

- ✅ Short, easy to remember
- ❌ Doesn't convey AI or technical nature
- ❌ No clear acronym

**CEREBRO** (X-Men reference)

- ❌ Too specific to X-Men (doesn't fit superhero assistant theme)
- ❌ Implies telepathy/mind-reading (privacy concerns?)
- ✅ Memorable pop culture reference

**Why AIDA Won**:

- Clear meaning (Digital Assistant)
- Pop culture connection (A.I.D.A. from Marvel)
- Fits superhero AI theme (JARVIS, FRIDAY, Alfred)
- Great acronym (Agentic Intelligence Digital Assistant)
- Memorable and marketable

## Naming Principles

When choosing names for AIDA components, follow these principles:

### 1. Clarity Over Cleverness

- Clear meaning beats clever wordplay
- Users should understand what something does from its name
- Example: `aida status` (clear) vs `aida check` (vague)

### 2. Consistency

- Follow Unix conventions (lowercase commands, dotfiles)
- Be consistent across documentation, code, CLI
- Example: Always `aida` not sometimes `AIDA` or `Aida`

### 3. Discoverability

- Use searchable, unique names
- Avoid overly generic terms
- Example: `claude-personal-assistant` (discoverable) vs `assistant` (generic)

### 4. Pronunciation

- Easy to pronounce (one obvious pronunciation)
- Works across languages/accents
- Example: AIDA ("eye-da") vs AIDE ("aid" or "aid-ee"?)

### 5. Branding

- Memorable and distinctive
- Emotional connection (pop culture references)
- Aligned with product vision

## Future Naming Decisions

### Potential Extensions

**If we build web dashboard**:

- `aida-web` or `aida-dashboard`
- Not just "web" (too generic)

**If we build mobile app**:

- "AIDA" (same brand, different platform)
- Not "AIDA Mobile" (redundant)

**If we build plugin marketplace**:

- `aida-plugins` or `aida-extensions`
- Not "marketplace" (too commercial)

**If we build team version**:

- `aida-teams` or `aida-pro`
- Not "AIDA Enterprise" (too corporate for initial offering)

### Naming New Features

**Commands**: Verb-based, clear action

- `aida status` (check status)
- `aida update` (update framework)
- `aida personality switch` (change personality)

**Agents**: Role-based, clear expertise

- `dev-assistant` (development help)
- `secretary` (organization and communication)
- `kubernetes-expert` (k8s specific)

**Personalities**: Character-based, evocative

- JARVIS (professional, Iron Man)
- Alfred (sophisticated, Batman)
- FRIDAY (friendly, Iron Man)

## Branding Elements

### Visual Identity (Future)

**Colors** (ideas, not decided):

- Primary: Blue (trust, intelligence, calm)
- Secondary: Purple (creativity, wisdom)
- Accent: Green (growth, progress)

**Logo** (ideas, not decided):

- Abstract AI symbol
- Or: Stylized "AIDA" wordmark
- Or: Blend of both

**Tagline** (ideas, not decided):

- "Your Personal AI Assistant"
- "AI That Feels Like Yours"
- "Conversational AI for Digital Life"

### Voice & Tone

**Brand Voice**:

- Intelligent but approachable
- Professional but friendly
- Technical but not jargon-heavy
- Empowering (you control the AI)

**Documentation Tone**:

- Clear and concise
- Helpful and supportive
- Assumes technical competence
- Explains "why" not just "how"

## Success Metrics

Naming is successful when:

**Clarity**:

- New users understand what AIDA is
- "AIDA" clearly conveys "AI assistant"
- No confusion with other products

**Memorability**:

- Users remember the name
- Word-of-mouth referrals use correct name
- Community discusses "AIDA" consistently

**Searchability**:

- Google search for "AIDA AI assistant" finds us
- GitHub search for "claude-personal-assistant" finds repo
- Low naming conflicts

**Emotional Connection**:

- Marvel fans recognize A.I.D.A. reference
- Users feel personality through name
- Brand voice resonates with target audience

## Related Decisions

- **Personality Builder**: See `/Users/oakensoul/Developer/oakensoul/claude-personal-assistant/.claude/agents/product-manager/knowledge/decisions/personality-builder.md` (superhero AI theme)
- **Three-Repo Architecture**: See `/Users/oakensoul/Developer/oakensoul/claude-personal-assistant/.claude/agents/product-manager/knowledge/decisions/three-repo-architecture.md` (directory naming)
- **Product Vision**: See `/Users/oakensoul/Developer/oakensoul/claude-personal-assistant/.claude/agents/product-manager/knowledge/core-concepts/product-vision.md` (positioning)

## Conclusion

**AIDA** (Agentic Intelligence Digital Assistant) is the right name because:

- ✅ Clear meaning (Digital Assistant)
- ✅ Pop culture connection (A.I.D.A. from Marvel)
- ✅ Better acronym (natural flow)
- ✅ Fits superhero AI assistant theme
- ✅ Memorable and marketable
- ✅ Easy to pronounce and spell

**Naming Consistency**:

- Product: AIDA
- Repository: claude-personal-assistant
- Framework directory: ~/.aida/
- User config: ~/.claude/
- Command: aida
- Entry point: ~/CLAUDE.md

**Status**: ✅ Decided, documented, and consistently applied across project
