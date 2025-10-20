---
title: "AIDA Prioritization Framework"
category: "patterns"
tags: ["prioritization", "decision-making", "roadmap", "features"]
last_updated: "2025-10-04"
---

# AIDA Prioritization Framework

## Overview

This framework guides feature prioritization decisions for AIDA. Use it to evaluate feature requests, scope milestones, and make product tradeoffs.

## Core Principle

### User value + technical feasibility + strategic alignment = Priority

Features should maximize user value while being technically feasible and aligned with AIDA's vision and design principles.

## Prioritization Matrix

### Priority Levels

### Must-Have (P0)

- Required for milestone to be considered complete
- Users cannot accomplish core workflows without this
- Blocking other must-have features
- High user value, feasible to build

### Nice-to-Have (P1)

- Enhances user experience significantly
- Not blocking core workflows
- Moderate user value, feasible to build
- Can be deferred to next milestone if needed

### Future (P2)

- Interesting but not critical
- Low urgency, can wait for post-1.0
- May require dependencies not yet built
- Speculative or unvalidated user value

### Won't-Do (P-)

- Does not align with product vision
- Too complex relative to value
- Out of scope for AIDA
- Better served by other tools

## Evaluation Criteria

### 1. User Value (High / Medium / Low)

**Questions to Ask**:

- How many users benefit from this feature?
- How much time/frustration does this save users?
- Is this a "painkiller" (solves real problem) or "vitamin" (nice but optional)?
- Do users request this frequently?
- Does this enable new workflows or just enhance existing ones?

**High Value Examples**:

- First-time installation (US-001)
- Personality system (US-003, US-004)
- Task capture (US-008)
- Memory/persistence features

**Medium Value Examples**:

- Morning/evening routines (US-006, US-007)
- Obsidian integration (US-017)
- Code review assistance (US-011)

**Low Value Examples**:

- Edge case features used by <10% of users
- Minor UI polish
- Niche integrations

### 2. Technical Complexity (Low / Medium / High)

**Questions to Ask**:

- How many person-days to implement?
- What dependencies exist? Are they ready?
- How risky is the implementation?
- What's the testing burden?
- Does this require new infrastructure?

**Low Complexity Examples**:

- Simple CLI commands (status, help)
- Configuration file changes
- Small bash script additions
- Text processing/formatting

**Medium Complexity Examples**:

- Personality switching system
- Task tracking and memory
- Git integration
- Obsidian integration

**High Complexity Examples**:

- Full memory system with persistence
- Privacy scrubbing system
- Plugin architecture
- Multi-agent orchestration
- Code analysis for reviews

### 3. Strategic Alignment (Strong / Moderate / Weak)

**Questions to Ask**:

- Does this align with AIDA's design principles?
- Does this advance our product vision?
- Does this differentiate us from competitors?
- Does this enable future features?
- Does this fit our target audience?

**Strong Alignment Examples**:

- Personality customization (modularity principle)
- Memory system (persistence principle)
- Privacy features (privacy principle)
- Natural language commands (NL principle)

**Moderate Alignment Examples**:

- Git integration (developer workflow)
- Obsidian integration (knowledge management)
- Code review (developer assistance)

**Weak Alignment Examples**:

- Windows support (violates platform focus)
- Web dashboard (violates CLI-first)
- Team collaboration (violates individual focus)

### 4. Dependencies (None / Few / Many / Blocking)

**Questions to Ask**:

- What features must exist before this?
- Are those dependencies ready or planned?
- Does this block other important features?
- Can we build this incrementally?

**No Dependencies Examples**:

- Basic CLI commands
- Help documentation
- Simple config changes

**Few Dependencies Examples**:

- Personality switching (needs personality system)
- Morning routine (needs memory system)

**Many Dependencies Examples**:

- Custom agent creation (needs plugin system, agent framework, testing)
- Knowledge sync (needs memory, scrubbing, export, Obsidian)

**Blocking Others Examples**:

- Memory system (required for most features)
- Personality system (core differentiator)
- Install script (can't use AIDA without it)

### 5. Risk (Low / Medium / High)

**Questions to Ask**:

- What could go wrong?
- How critical is this to get right?
- What's the impact of bugs/failures?
- How well do we understand the requirements?
- Is the technology proven or experimental?

**Low Risk Examples**:

- Simple CLI commands
- Documentation changes
- UI text updates

**Medium Risk Examples**:

- Git integration (many edge cases)
- Obsidian integration (file format dependencies)
- Personality builder (complex UI)

**High Risk Examples**:

- Privacy scrubbing (mistakes expose sensitive data)
- Memory system (data loss would be catastrophic)
- API key storage (security vulnerabilities)
- Plugin system (untrusted code execution)

## Decision Framework

### Step 1: Score the Feature

Score each criterion:

- User Value: H=3, M=2, L=1
- Technical Complexity: L=3, M=2, H=1 (inverted - lower complexity scores higher)
- Strategic Alignment: Strong=3, Moderate=2, Weak=1
- Dependencies: None=3, Few=2, Many=1, Blocking=0
- Risk: L=3, M=2, H=1 (inverted - lower risk scores higher)

**Total Score**: Sum of all scores (max 15)

### Step 2: Apply Priority Mapping

- **13-15 points**: Must-Have (P0)
- **9-12 points**: Nice-to-Have (P1)
- **5-8 points**: Future (P2)
- **<5 points**: Won't-Do (P-)

### Step 3: Validate Against Principles

Does this feature:

- Align with natural language interface principle?
- Support persistence across sessions?
- Enable modularity/extensibility?
- Respect privacy boundaries?
- Work on target platforms (macOS/Linux)?

If "no" to multiple principles, consider downgrading priority or rejecting.

### Step 4: Consider Milestone Context

**For 0.1.0 MVP**:

- Only P0 features (must-haves)
- Focus on core value proposition
- Get to usable state quickly
- Prove concept and gather feedback

**For 0.2.0 - 0.6.0**:

- Mix of P0 and P1 features
- Build out feature depth
- Address top user requests
- Improve polish and completeness

**For 1.0.0**:

- Production-ready quality
- All P0 features complete
- Top P1 features complete
- Documentation and testing complete

**Post-1.0.0**:

- P1 features not yet completed
- P2 features validated by users
- Experimental/innovative features
- Platform expansion (Windows)

## Example Prioritization

### Example 1: Web Dashboard

**Evaluation**:

- User Value: High (3) - Visual interface is appealing
- Technical Complexity: High (1) - Requires web framework, auth, API
- Strategic Alignment: Weak (1) - Conflicts with CLI-first principle
- Dependencies: Many (1) - Needs stable CLI first
- Risk: Medium (2) - Not critical path, can iterate

**Score**: 3+1+1+1+2 = 8 points → Future (P2)

**Decision**: Defer to post-1.0. Web dashboard is valuable but conflicts with CLI-first philosophy and requires significant investment. Focus on excellent CLI experience first.

### Example 2: Personality Builder

**Evaluation**:

- User Value: High (3) - Core differentiator
- Technical Complexity: Medium (2) - Interactive CLI, YAML generation
- Strategic Alignment: Strong (3) - Aligns with modularity principle
- Dependencies: Few (2) - Needs personality system framework
- Risk: Medium (2) - Must get UX right

**Score**: 3+2+3+2+2 = 12 points → Nice-to-Have (P1)

**Principle Check**: Aligns with modularity, extensibility, natural language
**Milestone Context**: Critical for 0.1.0 (personality is core value prop)

**Decision**: Upgrade to Must-Have for 0.1.0. Despite scoring as P1, personality customization is a core differentiator and essential for MVP. Without it, AIDA is just another AI wrapper.

### Example 3: Privacy Scrubbing

**Evaluation**:

- User Value: Medium (2) - Important for subset of users
- Technical Complexity: High (1) - Complex NLP, many edge cases
- Strategic Alignment: Strong (3) - Core privacy principle
- Dependencies: Many (1) - Needs memory, knowledge sync
- Risk: High (1) - Mistakes expose sensitive data

**Score**: 2+1+3+1+1 = 8 points → Future (P2)

**Principle Check**: Critical for privacy principle
**Risk Assessment**: High-risk features need more time and testing

**Decision**: Keep as Future (0.6.0). Privacy scrubbing is strategically important but complex and high-risk. Users can work around it (manual scrubbing) until automated solution is robust. Build simpler features first, tackle this when architecture is stable.

### Example 4: Quick Task Capture

**Evaluation**:

- User Value: High (3) - Frequent use case
- Technical Complexity: Medium (2) - NLP parsing, memory storage
- Strategic Alignment: Strong (3) - Natural language, persistence
- Dependencies: Few (2) - Needs memory system
- Risk: Low (3) - Non-critical if buggy

**Score**: 3+2+3+2+3 = 13 points → Must-Have (P0)

**Principle Check**: Aligns with natural language, persistence
**Milestone Context**: Demonstrates core value (memory + NL)

**Decision**: Must-Have for 0.2.0. Task capture is high-value, demonstrates AIDA's persistence advantage, and is feasible once memory system exists. Not needed for 0.1.0 (personality is more critical), but essential for 0.2.0.

## Prioritization Patterns

### Pattern 1: Foundation Before Features

Build infrastructure before features that depend on it.

**Example Sequence**:

1. Memory system (foundation)
2. Task capture (uses memory)
3. Morning routine (uses tasks + memory)

**Anti-Pattern**:
Building morning routine before memory system exists (would need to refactor later)

### Pattern 2: Core Differentiators First

Prioritize features that make AIDA unique.

**AIDA Differentiators**:

1. Personality system (unique)
2. Persistent memory (unique)
3. Multi-agent architecture (unique)

**Generic Features** (lower priority):

- Basic CLI commands (not unique)
- Configuration files (not unique)
- Help documentation (necessary but not differentiating)

### Pattern 3: Quick Wins for Momentum

Include some quick wins in each milestone.

**Quick Win Characteristics**:

- High user value
- Low technical complexity
- Visible/impactful
- Low risk

**Example Quick Wins**:

- Status command (shows AIDA is working)
- Personality switching (demonstrates customization)
- Help command improvements (makes AIDA more usable)

### Pattern 4: Deferred Complexity

Push complex/risky features to later milestones.

**Defer When**:

- High complexity + uncertain value
- High risk + alternatives exist
- Many dependencies not yet ready
- Requires significant R&D

**Examples to Defer**:

- Plugin system (complex, can add agents manually first)
- Privacy scrubbing (high-risk, can scrub manually first)
- Web dashboard (complex, CLI-first is sufficient)

### Pattern 5: User-Driven Reprioritization

Adjust priorities based on user feedback.

**Signals to Reprioritize**:

- Multiple users request same feature
- Users abandon AIDA due to missing feature
- Workarounds are painful/common
- Competition ships similar feature

**Example**:
If users heavily request Obsidian integration, consider moving from 0.4.0 to 0.2.0

## Prioritization Anti-Patterns

### Anti-Pattern 1: Feature Parity Trap

**Mistake**: Adding features just because competitors have them
**Why Bad**: Violates strategic alignment, dilutes focus
**Example**: Adding Windows support in 0.1.0 because ChatGPT runs on Windows
**Better**: Focus on differentiators (personality, memory), defer platform expansion

### Anti-Pattern 2: Shiny Object Syndrome

**Mistake**: Prioritizing cool/novel features over valuable ones
**Why Bad**: Doesn't serve users, wastes development time
**Example**: Building AI image generation when users need task management
**Better**: Prioritize based on user value, not technical novelty

### Anti-Pattern 3: Boiling the Ocean

**Mistake**: Trying to build everything in early milestones
**Why Bad**: Nothing gets finished, quality suffers
**Example**: Including all agents, all personalities, all integrations in 0.1.0
**Better**: MVP mindset - minimum viable set to prove value

### Anti-Pattern 4: Premature Optimization

**Mistake**: Over-engineering before understanding requirements
**Why Bad**: Wastes time, may need to refactor anyway
**Example**: Building plugin system before knowing what plugins are needed
**Better**: Build simple agents directly, extract plugin system later

### Anti-Pattern 5: Ignoring Dependencies

**Mistake**: Scheduling features before dependencies are ready
**Why Bad**: Causes delays, forces hacky workarounds
**Example**: Building knowledge sync before memory system exists
**Better**: Sequence features based on dependencies (foundation first)

## Milestone Prioritization

### 0.1.0 - Foundation (Must-Have Only)

**Goal**: Prove core value proposition (personality + memory + CLI)

**Must-Have**:

- Installation (US-001)
- Personality system (US-003, US-004, US-005)
- Basic CLI (status, help, personality commands)
- Memory system (foundation, may not be feature-complete)

**Explicitly Defer**:

- Agents (except minimal conversational agent)
- Integrations (Obsidian, git)
- Advanced features (knowledge sync, scrubbing)

### 0.2.0 - Core Features

**Goal**: Daily usability (task management, basic workflows)

**Must-Have**:

- Task capture and management (US-008)
- Memory system improvements
- Basic workflow automation

**Nice-to-Have**:

- Morning/evening routines (US-006, US-007)
- Update mechanism (US-022)

### 0.3.0 - Enhanced Memory & Agents

**Goal**: Specialized assistance and better memory

**Must-Have**:

- Core agents (Secretary, File Manager, Dev Assistant)
- Knowledge capture (US-009)
- Decision documentation (US-010)

**Nice-to-Have**:

- Git integration (US-018)
- Code review (US-011)

### 0.4.0 - Extended Commands & Obsidian

**Goal**: Full workflow integration

**Must-Have**:

- Obsidian integration (US-017)
- Expanded command set

**Nice-to-Have**:

- Documentation generation (US-012)
- Roadmap planning (US-013)

### 0.5.0 - Project Agents

**Goal**: Tech-stack specific expertise

**Must-Have**:

- Project-specific agent framework
- Initial project agents (kubernetes, react, etc.)

**Nice-to-Have**:

- Agent invocation improvements
- Agent marketplace preparation

### 0.6.0 - Knowledge Sync

**Goal**: Privacy-aware knowledge sharing

**Must-Have**:

- Knowledge export/import
- Privacy scrubbing (US-015)

**Nice-to-Have**:

- Data audit (US-016)
- Community knowledge sharing

### 1.0.0 - First Stable Release

**Goal**: Production-ready, polished experience

**Must-Have**:

- All P0 features from 0.1-0.6 complete and polished
- Comprehensive documentation
- Stable API/config format (no breaking changes post-1.0)

**Nice-to-Have**:

- Top P1 features from backlog
- Performance optimizations
- Additional agents and personalities

## Decision Log

Document significant prioritization decisions:

**When**: Date of decision
**What**: Feature/decision
**Why**: Rationale
**Alternatives**: What else was considered
**Outcome**: What priority/milestone was assigned

See `/Users/oakensoul/Developer/oakensoul/claude-personal-assistant/.claude/agents/product-manager/knowledge/decisions/` for decision history.

## References

- **Roadmap**: See `/Users/oakensoul/Developer/oakensoul/claude-personal-assistant/.claude/agents/product-manager/knowledge/decisions/roadmap.md`
- **User Stories**: See `/Users/oakensoul/Developer/oakensoul/claude-personal-assistant/.claude/agents/product-manager/knowledge/patterns/user-stories.md`
- **Product Vision**: See `/Users/oakensoul/Developer/oakensoul/claude-personal-assistant/.claude/agents/product-manager/knowledge/core-concepts/product-vision.md`
- **Design Principles**: See `/Users/oakensoul/Developer/oakensoul/claude-personal-assistant/.claude/agents/product-manager/knowledge/core-concepts/design-principles.md`
