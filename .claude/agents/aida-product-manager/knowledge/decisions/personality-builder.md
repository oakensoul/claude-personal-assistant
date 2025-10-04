---
title: "Personality Builder Decision"
category: "decisions"
tags: ["personality", "customization", "decision-record", "UX"]
last_updated: "2025-10-04"
decision_date: "2025-10-04"
status: "decided"
---

# Decision: Interactive Personality Builder vs Pre-Built Only

## Context

AIDA's core differentiator is customizable AI personalities. We needed to decide between two approaches:

**Option A**: Pre-built personalities only (JARVIS, Alfred, FRIDAY, etc.)
**Option B**: Interactive personality builder allowing infinite customization

## Decision

**We chose Option B**: Hybrid approach with 5 pre-built personalities AND interactive custom builder.

Users can either:
1. Choose from 5 curated presets (JARVIS, Alfred, FRIDAY, Sage, Drill Sergeant)
2. Create fully custom personality via 12-question interactive builder

## Rationale

### Why Hybrid Approach?

**1. Serves Different User Needs**
- **New Users**: Want quick start, pre-built personalities are perfect
- **Power Users**: Want exact customization, builder provides infinite possibilities
- **Explorers**: Want to tweak presets, builder allows starting from preset and modifying

**2. Scalability**
- Pre-built only: Would need 50+ personalities to cover all use cases (unmaintainable)
- Builder only: Too much friction for new users (analysis paralysis)
- Hybrid: 5 presets cover 80% of users, builder covers remaining 20%

**3. Community Growth**
- Users can share custom personalities (export YAML)
- Community can contribute personalities without our maintenance
- Encourages experimentation and creativity

**4. Product Differentiation**
- Most AI tools: One fixed personality or basic "custom instructions"
- AIDA: True personality system with structured customization
- Builder makes personality a first-class feature, not afterthought

### Why 12 Questions?

The builder asks 12 questions covering:

1. **Formality** (formal / casual / balanced)
2. **Expertise Level** (explain like expert / explain simply / balanced)
3. **Humor** (witty / serious / occasional)
4. **Proactivity** (suggest improvements / wait for requests / balanced)
5. **Detail Level** (concise / comprehensive / adaptive)
6. **Communication Style** (direct / supportive / socratic)
7. **Response Format** (structured / conversational / mixed)
8. **Technical Depth** (deep / surface / adaptive)
9. **Verbosity** (brief / detailed / context-dependent)
10. **Creativity** (innovative / traditional / balanced)
11. **Questioning** (challenge assumptions / accept as-is / balanced)
12. **Tone** (professional / friendly / mixed)

**Why 12?**
- Fewer than 12: Not enough granularity (personalities feel samey)
- More than 12: Analysis paralysis, user fatigue
- 12 questions ~= 2-3 minutes to complete (acceptable friction)
- Each question meaningfully impacts personality

**Three-Option Pattern**:
Each question offers 3 choices (e.g., formal/casual/balanced). This:
- Avoids binary thinking (not just yes/no)
- Provides middle ground ("balanced" is valid choice)
- Makes questions quick to answer (not open-ended)

## Alternatives Considered

### Alternative 1: Pre-Built Only (50+ Personalities)

**Approach**: Curate extensive library of pre-built personalities
- JARVIS (professional assistant)
- Alfred (butler style)
- FRIDAY (friendly assistant)
- Sage (wise advisor)
- Drill Sergeant (motivational)
- Professor (educational)
- Therapist (supportive)
- Comedian (humorous)
- Minimalist (concise)
- Verbose (detailed)
- ... (50+ total to cover use cases)

**Pros**:
- Zero friction for users (just pick one)
- No analysis paralysis
- Easier to test and maintain (finite set)
- Clear personality descriptions

**Cons**:
- Impossible to cover all use cases (infinite combinations)
- High maintenance burden (need to create and document 50+ personalities)
- Users forced into closest match (not perfect fit)
- Doesn't differentiate much from "custom instructions" in other tools
- Community can't contribute without our approval and maintenance

**Why Rejected**: Doesn't scale, requires ongoing maintenance, limits customization

### Alternative 2: Builder Only (No Presets)

**Approach**: All users create custom personality via builder
- No pre-built personalities
- Mandatory 12-question setup during installation
- Users must understand personality dimensions to configure

**Pros**:
- Every user gets exactly what they want
- No maintenance of preset personalities
- Demonstrates customization power immediately
- Encourages thoughtful personality design

**Cons**:
- High friction for new users (analysis paralysis)
- Users don't know what they want until they've tried AIDA
- Some users just want "good default" (overthinking is barrier)
- Harder to explain AIDA without concrete examples ("What's JARVIS like?")
- No shared language (can't say "I use JARVIS personality")

**Why Rejected**: Too much friction, no defaults for quick start

### Alternative 3: Templates + Modifiers

**Approach**: Start with template, apply modifiers
- Choose base template (Professional, Casual, Educational)
- Apply modifiers (more formal, more detailed, more humorous)
- Modifiers stack to create customization

**Pros**:
- Combines benefits of presets and customization
- Incremental customization (easy to understand)
- Visual/interactive UI possible (sliders, checkboxes)

**Cons**:
- Complexity in modifier interactions (how do "more formal" + "more humorous" combine?)
- Less predictable than builder (hard to know outcome of modifiers)
- Technical complexity (modifier composition logic)
- Doesn't provide full coverage (limited by modifier combinations)

**Why Rejected**: Complex to implement, less predictable outcomes

### Alternative 4: AI-Generated Personality (Meta)

**Approach**: Use AI to generate personality based on user description
- "I want an assistant that's professional but friendly, concise but thorough when needed"
- AI interprets and generates personality YAML
- User can refine through conversation

**Pros**:
- Most flexible (natural language input)
- Zero friction (just describe what you want)
- Could be very powerful for power users
- On-brand for AI product

**Cons**:
- Unpredictable results (AI might misinterpret)
- Hard to debug (why did AI generate this config?)
- Requires validation (AI might generate invalid config)
- Not available offline (need API call)
- Less educational (user doesn't learn personality dimensions)

**Why Rejected**: Too unpredictable, harder to debug, over-engineered for 0.1.0 (could revisit post-1.0)

## Implementation Details

### Pre-Built Personalities

#### JARVIS (Professional Assistant)
Inspired by Iron Man's JARVIS - professional, efficient, intelligent.

```yaml
name: JARVIS
formality: formal
expertise: balanced
humor: occasional
proactivity: suggest_improvements
detail_level: adaptive
communication_style: direct
response_format: structured
technical_depth: deep
verbosity: context_dependent
creativity: balanced
questioning: balanced
tone: professional
```

**Use Cases**: Work projects, professional communication, technical tasks

#### Alfred (Butler Style)
Inspired by Batman's Alfred - supportive, wise, refined.

```yaml
name: Alfred
formality: formal
expertise: balanced
humor: witty
proactivity: balanced
detail_level: comprehensive
communication_style: supportive
response_format: conversational
technical_depth: adaptive
verbosity: detailed
creativity: balanced
questioning: balanced
tone: professional
```

**Use Cases**: Personal assistance, thoughtful guidance, sophisticated help

#### FRIDAY (Friendly Assistant)
Inspired by Iron Man's FRIDAY - casual, approachable, helpful.

```yaml
name: FRIDAY
formality: casual
expertise: explain_simply
humor: witty
proactivity: suggest_improvements
detail_level: concise
communication_style: supportive
response_format: conversational
technical_depth: surface
verbosity: brief
creativity: innovative
questioning: accept_as_is
tone: friendly
```

**Use Cases**: Personal projects, learning, casual conversations

#### Sage (Wise Advisor)
Philosophy and wisdom oriented - thoughtful, questioning, educational.

```yaml
name: Sage
formality: balanced
expertise: explain_like_expert
humor: serious
proactivity: balanced
detail_level: comprehensive
communication_style: socratic
response_format: conversational
technical_depth: deep
verbosity: detailed
creativity: balanced
questioning: challenge_assumptions
tone: professional
```

**Use Cases**: Learning, philosophy, deep thinking, decision-making

#### Drill Sergeant (Motivational)
Motivational and direct - pushes you, holds accountable, results-focused.

```yaml
name: Drill_Sergeant
formality: casual
expertise: balanced
humor: occasional
proactivity: suggest_improvements
detail_level: concise
communication_style: direct
response_format: structured
technical_depth: surface
verbosity: brief
creativity: traditional
questioning: challenge_assumptions
tone: mixed
```

**Use Cases**: Productivity, motivation, accountability, getting things done

### Interactive Builder

**Builder Flow**:
1. Welcome message explaining personality builder
2. 12 questions (one at a time, clear explanations)
3. Preview generated personality (sample responses)
4. Name your personality
5. Save and activate
6. Option to export/share

**Builder UI** (CLI):
```
AIDA Personality Builder
━━━━━━━━━━━━━━━━━━━━━━━━

Let's create your perfect AI assistant personality.
This will take about 2-3 minutes.

Question 1 of 12: Formality
───────────────────────────

How formal should AIDA be?

  [1] Formal     - Professional language, proper grammar, respectful
  [2] Casual     - Conversational, relaxed, uses contractions
  [3] Balanced   - Mix of formal and casual depending on context

Your choice (1-3):
```

**Preview System**:
After answering all questions, show sample responses:

```
Preview Your Personality
━━━━━━━━━━━━━━━━━━━━━━

Here's how your assistant would respond:

You: "Help me plan my day"
AIDA: [Sample response in configured style]

You: "Explain how React hooks work"
AIDA: [Sample response showing expertise level and detail]

You: "I'm stuck on this bug"
AIDA: [Sample response showing proactivity and support style]

Satisfied with this personality? (y/n):
```

**YAML Generation**:
Builder generates YAML configuration:

```yaml
name: [user_chosen_name]
formality: [choice]
expertise: [choice]
# ... all 12 dimensions
```

**Export/Share**:
Users can export YAML to share with others:

```bash
aida personality export my_custom > my_personality.yaml

# Others can import:
aida personality import my_personality.yaml
```

## Benefits Realized

### User Experience
- **Quick Start**: New users can pick JARVIS and start immediately
- **Customization**: Power users can create exact personality they want
- **Iteration**: Users can start with preset, then customize later
- **Shareability**: Users can share custom personalities

### Product Differentiation
- **First-Class Feature**: Personality is core value prop, not afterthought
- **Infinite Possibilities**: Not limited to our 5 presets
- **Community Growth**: Users create and share personalities
- **Competitive Moat**: Most AI tools don't offer this level of customization

### Technical Implementation
- **YAML-Based**: Easy to read, edit, share, version control
- **Extensible**: Can add new personality dimensions later
- **Testable**: Can test each personality configuration
- **Maintainable**: 5 presets is manageable, community handles custom

### Community Impact
- **Shared Language**: "I use JARVIS personality" is understandable
- **Creativity**: Users experiment with unique combinations
- **Contributions**: Community shares interesting personalities
- **Personalization**: AIDA feels truly personal, not generic

## Trade-offs Accepted

### Complexity
- Builder adds complexity to codebase (but worth it for UX)
- Need to maintain 5 presets (but 5 is manageable)
- Preview system requires sample responses (but improves UX)

**Mitigation**: Keep builder simple, iterate based on feedback

### Analysis Paralysis
- Some users may struggle with 12 questions (too many choices)
- Users might not know what they want until they try AIDA

**Mitigation**:
- Presets for quick start (no builder required)
- Builder is optional (not mandatory)
- Preview system helps validate choices
- Can change personality anytime (not permanent decision)

### Maintenance
- 5 presets need documentation and testing
- Builder needs clear explanations for each question
- Preview system needs sample responses

**Mitigation**:
- 5 presets is small enough to maintain
- Documentation is one-time cost
- Preview samples can be templated

## Success Metrics

Track these metrics to validate decision:

**Adoption**:
- What % of users use presets vs custom builder?
- Which presets are most popular?
- How many users create custom personalities?

**Engagement**:
- Do users switch personalities?
- Do users iterate on custom personalities (refine over time)?
- Do users share custom personalities?

**Satisfaction**:
- User feedback on personality system
- Do users cite personality as reason for using AIDA?
- Community discussion about personalities

**Expected Results**:
- 70-80% of users start with preset (JARVIS most popular)
- 20-30% use custom builder
- 10-15% create multiple personalities for different contexts
- Community shares 10+ custom personalities in first 3 months

## Future Iterations

### Post-1.0 Enhancements

**Context-Aware Switching**:
Auto-switch personality based on context:
- Morning = JARVIS (professional)
- Evening = FRIDAY (casual)
- Learning mode = Sage
- Productivity mode = Drill Sergeant

**Advanced Builder**:
- AI-assisted builder (describe personality in natural language)
- Visual builder (web UI with sliders/toggles)
- Personality templates (community-contributed)

**Personality Marketplace**:
- Browse and install community personalities
- Rate and review personalities
- Personality collections (e.g., "Developer Pack" with 5 dev-focused personalities)

**Dynamic Personalities**:
- Personality learns from feedback ("be more concise", "explain in more detail")
- A/B testing personalities (try two, pick favorite)
- Personality evolution (gradually shifts based on preferences)

## Related Decisions

- **Naming Decision**: See `/Users/oakensoul/Developer/oakensoul/claude-personal-assistant/.claude/agents/aida-product-manager/knowledge/decisions/naming-decisions.md` (superhero AI theme)
- **Roadmap**: See `/Users/oakensoul/Developer/oakensoul/claude-personal-assistant/.claude/agents/aida-product-manager/knowledge/decisions/roadmap.md` (personality in 0.1.0)
- **Design Principles**: See `/Users/oakensoul/Developer/oakensoul/claude-personal-assistant/.claude/agents/aida-product-manager/knowledge/core-concepts/design-principles.md` (modularity principle)

## Conclusion

The hybrid approach (5 presets + interactive builder) provides:
- **Low friction** for new users (presets)
- **Infinite customization** for power users (builder)
- **Scalability** without maintenance burden
- **Community growth** through sharing
- **Product differentiation** as first-class feature

This decision positions AIDA's personality system as a core competitive advantage and enables community-driven growth.

**Status**: ✅ Decided and committed to 0.1.0 roadmap