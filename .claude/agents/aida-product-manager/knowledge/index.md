---
title: "AIDA Product Manager Knowledge Index"
category: "index"
tags: ["index", "knowledge-base", "reference"]
last_updated: "2025-10-04"
knowledge_count: 8
---

# AIDA Product Manager Knowledge Index

## Overview

This knowledge base contains comprehensive product management documentation for the AIDA (Agentic Intelligence Digital Assistant) framework. The knowledge base serves as persistent memory for product decisions, user insights, and strategic direction.

**Total Knowledge Files**: 8
**Last Updated**: 2025-10-04

---

## Core Concepts

Foundation documents defining AIDA's product vision, audience, and principles.

### product-vision.md
**Path**: `/Users/oakensoul/Developer/oakensoul/claude-personal-assistant/.claude/agents/aida-product-manager/knowledge/core-concepts/product-vision.md`

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

**Key Insights**:
- AIDA is conversational operating system, not just AI wrapper
- Persistence across sessions is core differentiator
- Privacy-aware architecture enables professional use
- Focus over breadth (macOS/Linux, not Windows initially)

---

### target-audience.md
**Path**: `/Users/oakensoul/Developer/oakensoul/claude-personal-assistant/.claude/agents/aida-product-manager/knowledge/core-concepts/target-audience.md`

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

**Key Insights**:
- 70%+ of users are developers or tech-savvy power users
- CLI-first fits existing terminal-based workflows
- Privacy-conscious users are key demographic
- Solo developers juggling multiple roles are sweet spot

---

### value-proposition.md
**Path**: `/Users/oakensoul/Developer/oakensoul/claude-personal-assistant/.claude/agents/aida-product-manager/knowledge/core-concepts/value-proposition.md`

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

**Key Insights**:
- Persistent memory is #1 differentiator vs ChatGPT
- Customizable personalities set us apart from generic AI
- Privacy-first enables use on proprietary/sensitive work
- CLI-native is feature, not limitation (fits target audience)

---

### design-principles.md
**Path**: `/Users/oakensoul/Developer/oakensoul/claude-personal-assistant/.claude/agents/aida-product-manager/knowledge/core-concepts/design-principles.md`

**Purpose**: Establishes five core design principles guiding all product decisions

**Key Contents**:
- **Principle 1**: Natural Language Interface (conversational, not command-driven)
- **Principle 2**: Persistence Across Sessions (memory and context)
- **Principle 3**: Modularity & Extensibility (pluggable personalities and agents)
- **Principle 4**: Privacy-Aware Architecture (public framework, private data)
- **Principle 5**: Platform-Focused Development (macOS/Linux, not Windows initially)
- For each principle: definition, examples, design implications, trade-offs, validation
- Conflict resolution priority: Privacy > Persistence > Natural Language > Modularity > Platform
- Anti-patterns to avoid

**When to Reference**:
- Making product decisions (does this align with principles?)
- Resolving conflicting priorities (use conflict resolution priority)
- Evaluating technical approaches (which approach upholds principles?)
- Explaining product philosophy to contributors

**Key Insights**:
- Principles can conflict - we have priority order for resolution
- Privacy is non-negotiable (highest priority)
- Persistence is core differentiator (high priority)
- Platform focus over breadth (quality on 2 platforms vs mediocre on 3)

---

## Patterns

Reusable patterns for user stories, prioritization, and product workflows.

### user-stories.md
**Path**: `/Users/oakensoul/Developer/oakensoul/claude-personal-assistant/.claude/agents/aida-product-manager/knowledge/patterns/user-stories.md`

**Purpose**: Comprehensive collection of user stories for AIDA features

**Key Contents**:
- 22 detailed user stories (US-001 through US-022)
- Story template: Title, Persona, Story, Acceptance Criteria, Priority, Milestone, Dependencies, Effort
- Categories: Installation, personality system, daily workflow, knowledge management, development, project management, privacy, integration, agents, system management
- Prioritization guide: Must-have (P0), nice-to-have (P1), future (P2)
- Story writing guidelines

**When to Reference**:
- Planning milestones (which stories go in which release?)
- Writing new user stories (follow template)
- Understanding user needs (what workflows matter?)
- Creating acceptance criteria for features

**Key Stories**:
- US-001: First-time installation (0.1.0 must-have)
- US-004: Create custom personality (0.1.0 must-have)
- US-008: Quick task capture (0.2.0 must-have)
- US-015: Knowledge sync with privacy (0.6.0 nice-to-have)
- US-019: Invoke specialized agent (0.5.0 nice-to-have)

**Key Insights**:
- Must-have stories for 0.1.0: Installation, personality system, basic CLI, memory foundation
- Personality system is critical MVP feature (core differentiator)
- Task capture demonstrates memory + natural language (0.2.0)
- Privacy scrubbing deferred to 0.6.0 (high complexity, high risk)

---

### prioritization-framework.md
**Path**: `/Users/oakensoul/Developer/oakensoul/claude-personal-assistant/.claude/agents/aida-product-manager/knowledge/patterns/prioritization-framework.md`

**Purpose**: Framework for prioritizing features and making product tradeoffs

**Key Contents**:
- Core principle: User value + technical feasibility + strategic alignment = Priority
- Five evaluation criteria: User Value, Technical Complexity, Strategic Alignment, Dependencies, Risk
- Scoring system: 15-point scale mapping to priority levels (P0, P1, P2, P-)
- Decision framework: 4-step process (score, map, validate principles, consider milestone)
- Prioritization patterns: Foundation before features, core differentiators first, quick wins, deferred complexity
- Prioritization anti-patterns: Feature parity trap, shiny object syndrome, boiling the ocean
- Milestone prioritization guidance (0.1.0 through 1.0.0)

**When to Reference**:
- Evaluating new feature requests
- Scoping milestones (what goes in, what gets deferred?)
- Making tradeoff decisions (feature A vs feature B)
- Explaining prioritization rationale to stakeholders

**Key Insights**:
- User value trumps technical elegance
- Must-have > nice-to-have > future (clear prioritization)
- Foundation features first (memory system before features that use memory)
- Core differentiators first (personality, memory, agents)
- Quick wins for momentum (visible progress each milestone)

---

## Decisions

Historical record of significant product decisions with rationale.

### roadmap.md
**Path**: `/Users/oakensoul/Developer/oakensoul/claude-personal-assistant/.claude/agents/aida-product-manager/knowledge/decisions/roadmap.md`

**Purpose**: Comprehensive product roadmap from 0.1.0 MVP through 1.0.0 and beyond

**Key Contents**:
- Milestone philosophy: Incremental value, learn and adapt, foundation first, quality over quantity
- Release strategy: Semantic versioning, release cadence
- Seven milestones with detailed feature lists:
  - **0.1.0 - Foundation** (6 weeks): Installation, personality system, basic CLI, memory foundation
  - **0.2.0 - Core Features** (4-5 weeks): Task management, memory improvements, workflows
  - **0.3.0 - Enhanced Memory & Agents** (5-6 weeks): Core agents, knowledge capture, decisions
  - **0.4.0 - Extended Commands & Obsidian** (5-6 weeks): Obsidian integration, expanded commands
  - **0.5.0 - Project Agents & Plugin System** (6-8 weeks): Tech-stack agents, plugin architecture
  - **0.6.0 - Knowledge Sync & Privacy** (6-8 weeks): Privacy scrubbing, data audit
  - **1.0.0 - First Stable Release** (8-12 weeks): Polish, documentation, stability
- Post-1.0 future vision: Web dashboard, team features, mobile app, platform expansion
- Roadmap principles and change management

**When to Reference**:
- Planning current and future milestones
- Understanding feature sequencing and dependencies
- Communicating product timeline to stakeholders
- Making scope decisions (what fits in current milestone?)

**Key Insights**:
- 0.1.0 MVP focuses on core value prop (personality + basic CLI)
- Memory system built incrementally across milestones (foundation in 0.1.0, enhanced in 0.2.0-0.3.0)
- Agents introduced in 0.3.0 after memory is stable
- Privacy scrubbing deferred to 0.6.0 (complex, high-risk)
- 1.0.0 is about polish and stability, not new features

---

### personality-builder.md
**Path**: `/Users/oakensoul/Developer/oakensoul/claude-personal-assistant/.claude/agents/aida-product-manager/knowledge/decisions/personality-builder.md`

**Purpose**: Documents decision to use hybrid approach (presets + interactive builder) for personalities

**Key Contents**:
- Context: Need to decide between pre-built personalities only vs custom builder
- Decision: Hybrid approach with 5 presets (JARVIS, Alfred, FRIDAY, Sage, Drill Sergeant) + 12-question builder
- Rationale: Serves different user needs, scalability, community growth, product differentiation
- Why 12 questions: Optimal balance (enough granularity, not analysis paralysis)
- Alternatives considered: Pre-built only (50+ personalities), builder only, templates + modifiers, AI-generated
- Implementation details: Full YAML configs for 5 presets, builder flow, preview system, export/share
- Benefits realized: UX, differentiation, technical, community
- Trade-offs accepted: Complexity, analysis paralysis, maintenance

**When to Reference**:
- Implementing personality system
- Explaining personality approach to users
- Making similar customization decisions for other features
- Understanding why we chose this approach

**Key Insights**:
- Hybrid approach serves both new users (presets) and power users (builder)
- 5 presets cover 80% of users, builder covers remaining 20%
- 12 questions is sweet spot (2-3 minutes to complete)
- Community can share custom personalities (export YAML)
- Personality system is first-class feature, not afterthought

**Status**: ✅ Decided and committed to 0.1.0 roadmap

---

### three-repo-architecture.md
**Path**: `/Users/oakensoul/Developer/oakensoul/claude-personal-assistant/.claude/agents/aida-product-manager/knowledge/decisions/three-repo-architecture.md`

**Purpose**: Documents decision to use three-repository architecture for AIDA

**Key Contents**:
- Context: Need to balance shareability, privacy, and flexibility
- Decision: Three repos - `claude-personal-assistant` (public framework), `dotfiles` (public templates), `dotfiles-private` (secrets)
- Rationale: Separation of concerns, privacy by design, version control benefits, installation model, GNU Stow integration
- Alternatives considered: Single monorepo, two-repo, four-repo, mono-repo with external user data
- Implementation details: Directory structure, repository responsibilities, cross-repo relationships, dev mode
- Benefits realized: Privacy, shareability, collaboration, maintainability
- Trade-offs accepted: Complexity, setup time, coordination

**When to Reference**:
- Understanding repository structure
- Making architecture decisions
- Explaining privacy model to users
- Contributing to framework (understanding what goes where)

**Key Insights**:
- Three repos enable privacy (framework is public, user data is private)
- Clear boundaries: framework code vs public configs vs secrets
- Framework can be shared openly, contributed to by community
- User data never accidentally exposed
- GNU Stow for dotfiles management (symlinks to git repo)

**Status**: ✅ Decided and implemented in repository structure

---

### naming-decisions.md
**Path**: `/Users/oakensoul/Developer/oakensoul/claude-personal-assistant/.claude/agents/aida-product-manager/knowledge/decisions/naming-decisions.md`

**Purpose**: Documents naming evolution from AIDE to AIDA and all naming conventions

**Key Contents**:
- Context: Originally named AIDE (Agentic Intelligence & Digital Environment)
- Decision: Renamed to AIDA (Agentic Intelligence Digital Assistant)
- Rationale: Clearer meaning, pop culture reference (A.I.D.A. from Marvel), better branding, personality alignment, better acronym
- Name components: Directory (~/.aida/), command (aida), user config (~/.claude/), entry point (~/CLAUDE.md)
- Evolution: AIDE → AIDA (confirmed)
- Alternatives considered: CAI, MENTOR, COMPANION, ALLY, CEREBRO
- Naming principles: Clarity over cleverness, consistency, discoverability, pronunciation, branding
- Future naming decisions: Extensions, features, branding elements

**When to Reference**:
- Understanding product naming and branding
- Naming new features or components
- Explaining AIDA name to users
- Creating consistent naming across codebase

**Key Insights**:
- AIDA clearer than AIDE ("Assistant" vs "Environment")
- A.I.D.A. from Agents of S.H.I.E.L.D. fits superhero AI theme
- ~/.aida/ for framework, ~/.claude/ for user config (clear separation)
- Naming consistency: product (AIDA), command (aida), repo (claude-personal-assistant)
- Follow Unix conventions (lowercase commands, dotfiles)

**Status**: ✅ Decided, documented, and consistently applied

---

## External Resources

Links to external documentation, references, and learning resources.

### Product Management
- [Product Management Best Practices](https://www.productplan.com/learn/product-management-best-practices/)
- [Prioritization Frameworks](https://www.productplan.com/glossary/prioritization/)
- [User Story Writing](https://www.mountaingoatsoftware.com/agile/user-stories)
- [Product Roadmap Planning](https://www.aha.io/roadmapping/guide/product-roadmap)

### AI Assistant Market
- [ChatGPT](https://chat.openai.com/) - Primary competitor (generic AI chat)
- [GitHub Copilot](https://github.com/features/copilot) - Code-focused AI
- [Cursor](https://cursor.sh/) - AI-powered IDE
- [Claude](https://claude.ai/) - Underlying AI technology for AIDA

### Technical References
- [Claude AI Documentation](https://docs.anthropic.com/)
- [Claude Code Documentation](https://docs.claude.ai/code)
- [Bash Scripting Guide](https://www.gnu.org/software/bash/manual/bash.html)
- [YAML Specification](https://yaml.org/spec/)
- [GNU Stow](https://www.gnu.org/software/stow/) - Dotfiles management

### Design & UX
- [CLI Design Patterns](https://clig.dev/) - Command-line interface guidelines
- [Conversational UI Design](https://www.nngroup.com/articles/conversational-interfaces/)
- [Privacy by Design](https://www.ipc.on.ca/wp-content/uploads/resources/7foundationalprinciples.pdf)

### Open Source
- [Open Source Guide](https://opensource.guide/) - Best practices for open source
- [Semantic Versioning](https://semver.org/) - Version numbering
- [Keep a Changelog](https://keepachangelog.com/) - Changelog format

---

## Knowledge Base Usage

### When to Reference Knowledge Base

**During Product Decisions**:
- Check if decision aligns with product vision and design principles
- Review past decisions to maintain consistency
- Consult user stories and roadmap for context

**When Prioritizing Features**:
- Use prioritization framework to evaluate requests
- Check target audience to validate user value
- Review roadmap to understand milestone context

**When Writing Requirements**:
- Reference user stories for format and examples
- Check design principles for constraints
- Review target audience for user perspective

**When Communicating Decisions**:
- Reference value proposition for competitive positioning
- Check product vision for messaging
- Review decisions for rationale and context

### When to Add Knowledge

Add new knowledge when:
- **Significant Decision Made**: Document in decisions/ with rationale
- **New Pattern Discovered**: Add to patterns/ for reuse
- **Core Concept Refined**: Update core-concepts/ with learnings
- **External Resource Found**: Add link to relevant section

### Knowledge Priorities

**High Priority** (always maintain):
- Core concepts (vision, audience, value prop, principles)
- Current roadmap
- Recent decisions

**Medium Priority** (update regularly):
- User stories (add new, update existing)
- Prioritization framework (refine based on learnings)
- External resources (keep links current)

**Low Priority** (update as needed):
- Historical decisions (valuable but static)
- Patterns (add when discovered, not forced)

---

## Knowledge Base Maintenance

### Update Cadence

**After Each Milestone** (0.1.0, 0.2.0, etc.):
- Update roadmap with actual vs planned
- Add decision records for significant choices
- Refine user stories based on learnings
- Update product vision if needed (rare)

**Monthly Review**:
- Check external links (fix broken links)
- Update knowledge count in this index
- Add new patterns discovered
- Archive outdated decisions (mark as superseded)

**Quarterly Review**:
- Validate product vision still aligns
- Review design principles (still relevant?)
- Update target audience (market changes?)
- Refresh value proposition (competitive landscape)

### Knowledge Organization

**Core Concepts** (4 files):
- Foundational documents defining AIDA
- Should be relatively stable (infrequent updates)
- Changes should be deliberate and documented

**Patterns** (2 files):
- Reusable templates and frameworks
- Updated as we discover better patterns
- Add new patterns as we learn

**Decisions** (4 files):
- Historical record of significant choices
- Add new decisions, don't modify old ones (append)
- Mark superseded decisions clearly

### Version Control

- Knowledge base is version controlled with agent (in git)
- Each update should have meaningful commit message
- Tag knowledge updates with milestone (e.g., "Updated for 0.2.0")
- Document why knowledge changed, not just what

---

## Memory Philosophy

### Knowledge Base vs Agent Memory

**Knowledge Base** (this):
- Persistent across all sessions
- Curated and structured
- Product management specific
- Manually maintained

**Agent Context** (AIDA's memory):
- Session-specific
- User-specific
- Automatically captured
- Queryable and searchable

**Relationship**:
- Knowledge base informs agent context (provides foundation)
- Agent context may surface insights for knowledge base (learnings)
- Knowledge base is "long-term memory", agent context is "working memory"

### When Knowledge Base Helps

**Product Manager Agent Uses Knowledge Base To**:
- Ground decisions in product vision
- Reference past decisions for consistency
- Apply prioritization framework systematically
- Create user stories following patterns
- Communicate product direction clearly

**Without Knowledge Base**:
- Would need to rediscover rationale each session
- Risk inconsistent decisions
- No historical context for why choices were made
- Harder to onboard new contributors

---

## Contributing to Knowledge Base

### Adding New Knowledge

1. **Identify Gap**: What knowledge is missing?
2. **Choose Category**: core-concepts, patterns, or decisions?
3. **Create File**: Follow naming convention (kebab-case.md)
4. **Add Frontmatter**: Include title, category, tags, last_updated
5. **Write Content**: Clear, structured, actionable
6. **Update Index**: Add entry to this file
7. **Commit**: Meaningful commit message

### Updating Existing Knowledge

1. **Read Current Version**: Understand existing content
2. **Make Changes**: Preserve structure, update content
3. **Update Frontmatter**: Change last_updated date
4. **Update Index**: Reflect changes if needed
5. **Commit**: Explain what changed and why

### Quality Standards

**Knowledge Should Be**:
- **Actionable**: Helps make decisions, not just information
- **Structured**: Clear headings, scannable, organized
- **Contextual**: Includes rationale, not just facts
- **Maintained**: Updated when outdated, marked when superseded
- **Linked**: References related knowledge and external resources

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

- **8 knowledge files** (4 core concepts, 2 patterns, 4 decisions)
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

This knowledge base provides comprehensive product context for the AIDA Product Manager agent. It enables:
- **Consistent decisions** aligned with product vision
- **Historical context** for why choices were made
- **Structured approach** to prioritization and planning
- **Clear communication** of product direction

The knowledge base is a living document - update it as AIDA evolves, decisions are made, and learnings accumulate.

**Last Updated**: 2025-10-04
**Next Review**: After 0.1.0 milestone completion