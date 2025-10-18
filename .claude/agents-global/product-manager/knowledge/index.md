---
title: "AIDA Product Manager Knowledge Index"
category: "index"
tags: ["index", "knowledge-base", "reference", "aida"]
last_updated: "2025-10-06"
knowledge_count: 10
---

# AIDA Product Manager Knowledge Index

## Overview

This knowledge base contains project-specific product management documentation for the AIDA (Agentic Intelligence Digital Assistant) framework. This is **project-level knowledge** that supplements the user-level product manager agent at `~/.claude/agents/product-manager/`.

**Total Knowledge Files**: 10
**Last Updated**: 2025-10-06

---

## Core Concepts

Foundation documents defining AIDA's product vision, audience, and principles.

### product-vision.md

**Path**: `./core-concepts/product-vision.md`

**Purpose**: Defines AIDA's overall vision, mission, goals, and success criteria

**Key Contents**:

- Vision statement: "AIDA makes AI assistance feel like your own personal assistant"
- Mission: Empower users to customize, extend, and own their AI experience
- Five core goals: Natural language, persistence, modularity, privacy, platform focus
- Success criteria for user experience, technical excellence, community growth
- Non-goals (what AIDA explicitly doesn't aim to do)

**When to Reference**:

- Evaluating new feature requests against product vision
- Making strategic product decisions
- Explaining AIDA's purpose to stakeholders
- Resolving conflicts between competing priorities

---

### target-audience.md

**Path**: `./core-concepts/target-audience.md`

**Purpose**: Defines who AIDA is for, user personas, and use cases

**Key Contents**:

- Primary audience: Developers and tech-savvy power users
- Secondary audience: Solo developers, team leads, knowledge workers
- Anti-personas: Non-technical users, Windows-primary, enterprise teams (initially)
- Four detailed personas: Sarah (solo dev), David (DevOps), Maria (tech lead), Alex (researcher)
- Use cases by category: Daily workflow, development, knowledge management, project management

**When to Reference**:

- Prioritizing features (which users benefit?)
- Writing user stories and requirements
- Making UX decisions (what does target user expect?)
- Evaluating feature complexity (is this worth it for our audience?)

---

### value-proposition.md

**Path**: `./core-concepts/value-proposition.md`

**Purpose**: Articulates AIDA's competitive differentiation and value vs alternatives

**Key Contents**:

- Core value prop: "AI assistant that feels like yours - personal, persistent, private"
- Competitive analysis: vs ChatGPT, Copilot, Cursor, Claude, Perplexity
- Six key differentiators: Memory, personalities, privacy, multi-agent, terminal-native, workflow integration
- Positioning matrix: AIDA occupies "Personal + Local-first" quadrant
- Use cases where AIDA excels: Developer workflow, proprietary code, multi-domain, long-term projects

**When to Reference**:

- Explaining why someone should use AIDA
- Making feature decisions (does this reinforce our differentiators?)
- Competitive positioning and messaging
- Identifying market opportunities

---

### design-principles.md

**Path**: `./core-concepts/design-principles.md`

**Purpose**: Establishes five core design principles guiding all product decisions

**Key Contents**:

- **Principle 1**: Natural Language Interface (conversational, not command-driven)
- **Principle 2**: Persistence Across Sessions (memory and context)
- **Principle 3**: Modularity & Extensibility (pluggable personalities and agents)
- **Principle 4**: Privacy-Aware Architecture (public framework, private data)
- **Principle 5**: Platform-Focused Development (macOS/Linux, not Windows initially)
- Conflict resolution priority: Privacy > Persistence > Natural Language > Modularity > Platform

**When to Reference**:

- Making product decisions (does this align with principles?)
- Resolving conflicting priorities (use conflict resolution priority)
- Evaluating technical approaches (which approach upholds principles?)
- Explaining product philosophy to contributors

---

## Patterns

Reusable patterns for user stories, prioritization, and product workflows.

### user-stories.md

**Path**: `./patterns/user-stories.md`

**Purpose**: Comprehensive collection of user stories for AIDA features

**Key Contents**:

- 22 detailed user stories (US-001 through US-022)
- Story template: Title, Persona, Story, Acceptance Criteria, Priority, Milestone, Dependencies, Effort
- Categories: Installation, personality system, daily workflow, knowledge management, development, project management, privacy, integration, agents, system management
- Prioritization guide: Must-have (P0), nice-to-have (P1), future (P2)

**When to Reference**:

- Planning milestones (which stories go in which release?)
- Writing new user stories (follow template)
- Understanding user needs (what workflows matter?)
- Creating acceptance criteria for features

---

### prioritization-framework.md

**Path**: `./patterns/prioritization-framework.md`

**Purpose**: Framework for prioritizing features and making product tradeoffs

**Key Contents**:

- Core principle: User value + technical feasibility + strategic alignment = Priority
- Five evaluation criteria: User Value, Technical Complexity, Strategic Alignment, Dependencies, Risk
- Scoring system: 15-point scale mapping to priority levels (P0, P1, P2, P-)
- Decision framework: 4-step process (score, map, validate principles, consider milestone)
- Prioritization patterns: Foundation before features, core differentiators first, quick wins, deferred complexity

**When to Reference**:

- Evaluating new feature requests
- Scoping milestones (what goes in, what gets deferred?)
- Making tradeoff decisions (feature A vs feature B)
- Explaining prioritization rationale to stakeholders

---

## Decisions

Historical record of significant product decisions with rationale.

### roadmap.md

**Path**: `./decisions/roadmap.md`

**Purpose**: Comprehensive product roadmap from 0.1.0 MVP through 1.0.0 and beyond

**Key Contents**:

- Milestone philosophy: Incremental value, learn and adapt, foundation first, quality over quantity
- Release strategy: Semantic versioning, release cadence
- Seven milestones with detailed feature lists (0.1.0 through 1.0.0)
- Post-1.0 future vision: Web dashboard, team features, mobile app, platform expansion

**When to Reference**:

- Planning current and future milestones
- Understanding feature sequencing and dependencies
- Communicating product timeline to stakeholders
- Making scope decisions (what fits in current milestone?)

---

### personality-builder.md

**Path**: `./decisions/personality-builder.md`

**Purpose**: Documents decision to use hybrid approach (presets + interactive builder) for personalities

**Key Contents**:

- Decision: Hybrid approach with 5 presets + 12-question builder
- Rationale: Serves different user needs, scalability, community growth, product differentiation
- Why 12 questions: Optimal balance (enough granularity, not analysis paralysis)
- Alternatives considered: Pre-built only, builder only, templates + modifiers, AI-generated

**When to Reference**:

- Implementing personality system
- Explaining personality approach to users
- Making similar customization decisions for other features

---

### three-repo-architecture.md

**Path**: `./decisions/three-repo-architecture.md`

**Purpose**: Documents decision to use three-repository architecture for AIDA

**Key Contents**:

- Decision: Three repos - claude-personal-assistant (public framework), dotfiles (public templates), dotfiles-private (secrets)
- Rationale: Separation of concerns, privacy by design, version control benefits, installation model
- Alternatives considered: Single monorepo, two-repo, four-repo, mono-repo with external user data
- Implementation details: Directory structure, repository responsibilities, cross-repo relationships

**When to Reference**:

- Understanding repository structure
- Making architecture decisions
- Explaining privacy model to users
- Contributing to framework (understanding what goes where)

---

### naming-decisions.md

**Path**: `./decisions/naming-decisions.md`

**Purpose**: Documents naming evolution from AIDE to AIDA and all naming conventions

**Key Contents**:

- Decision: Renamed from AIDE to AIDA (Agentic Intelligence Digital Assistant)
- Rationale: Clearer meaning, pop culture reference (A.I.D.A. from Marvel), better branding, personality alignment
- Name components: Directory (~/.aida/), command (aida), user config (~/.claude/), entry point (~/CLAUDE.md)
- Naming principles: Clarity over cleverness, consistency, discoverability, pronunciation, branding

**When to Reference**:

- Understanding product naming and branding
- Naming new features or components
- Explaining AIDA name to users
- Creating consistent naming across codebase

---

## Knowledge Base Usage

### Integration with User-Level Knowledge

This project-specific knowledge base works in conjunction with the user-level product manager agent:

**User-level** (`~/.claude/agents/product-manager/`):

- Generic product management practices and philosophy
- Personal PM preferences and approaches
- Reusable frameworks applicable to any project

**Project-level** (this knowledge base):

- AIDA-specific vision, goals, and requirements
- AIDA product decisions and roadmap
- AIDA-specific user personas and use cases
- AIDA design principles and differentiators

### When to Reference This Knowledge Base

**During Product Decisions**:

- Check if decision aligns with AIDA's product vision and design principles
- Review past AIDA-specific decisions to maintain consistency
- Consult AIDA user stories and roadmap for context

**When Prioritizing Features**:

- Use prioritization framework to evaluate AIDA feature requests
- Check AIDA target audience to validate user value
- Review AIDA roadmap to understand milestone context

**When Writing Requirements**:

- Reference AIDA user stories for format and examples
- Check AIDA design principles for constraints
- Review AIDA target audience for user perspective

### Knowledge Priorities

**High Priority** (always maintain):

- Core concepts (vision, audience, value prop, principles)
- Current roadmap status
- Recent decisions

**Medium Priority** (update regularly):

- User stories (add new, update existing)
- Prioritization framework (refine based on learnings)

**Low Priority** (update as needed):

- Historical decisions (valuable but static)
- Patterns (add when discovered)

---

## Quick Reference

### Core Documents

| Document | Purpose | When to Use |
|----------|---------|-------------|
| product-vision.md | Overall direction | Strategic decisions, explaining AIDA |
| target-audience.md | Who we serve | Prioritization, requirements |
| value-proposition.md | Competitive position | Messaging, feature decisions |
| design-principles.md | Guiding constraints | Technical decisions, tradeoffs |
| user-stories.md | Feature requirements | Planning, acceptance criteria |
| prioritization-framework.md | Decision making | Evaluating features |
| roadmap.md | Release planning | Milestone scoping, timelines |
| personality-builder.md | Customization approach | Implementation guidance |
| three-repo-architecture.md | Code organization | Architecture decisions |
| naming-decisions.md | Branding & naming | Naming new components |

### Key Numbers

- **10 knowledge files** (4 core concepts, 2 patterns, 4 decisions)
- **5 pre-built personalities** (JARVIS, Alfred, FRIDAY, Sage, Drill Sergeant)
- **12 personality questions** (optimal for builder)
- **3 repositories** (framework, dotfiles, dotfiles-private)
- **7 milestones** (0.1.0 through 1.0.0)
- **22 user stories** (documented and prioritized)
- **5 design principles** (guide all decisions)

### Priority Hierarchy

When principles conflict:

1. **Privacy** (non-negotiable)
2. **Persistence** (core differentiator)
3. **Natural Language** (user experience)
4. **Modularity** (long-term value)
5. **Platform Focus** (practical constraint)

---

## Conclusion

This knowledge base provides AIDA-specific product context for the product manager agent. It enables:

- **Consistent decisions** aligned with AIDA's product vision
- **Historical context** for why AIDA-specific choices were made
- **Structured approach** to AIDA feature prioritization and planning
- **Clear communication** of AIDA product direction

The knowledge base is a living document - update it as AIDA evolves, decisions are made, and learnings accumulate.

**Last Updated**: 2025-10-06
**Next Review**: After 0.1.0 milestone completion
