# ADR-002: Two-Tier Agent Architecture

**Status**: Accepted
**Date**: 2025-10-15
**Deciders**: Project Lead
**Context**: Software
**Tags**: architecture, agents, knowledge-management

## Context and Problem Statement

AIDA agents need knowledge to provide context-aware assistance. We need to decide how to organize agent knowledge to balance:

- Reusability across projects (generic knowledge)
- Project-specific context (custom knowledge)
- User preferences and personal philosophy
- Maintainability and clarity

Without a clear architecture, we risk:

- Duplicating generic knowledge in every project
- Mixing user-level preferences with project-specific details
- Making agents unable to detect when project context is missing
- Confusing users about where to add knowledge

## Decision Drivers

- **Reusability**: Generic patterns should be reusable across all projects
- **Context Awareness**: Agents should know when project context is available vs missing
- **User Preferences**: Capture user's personal technical philosophy (coding standards, preferred patterns)
- **Project Specificity**: Support project-specific details (tech stack, architecture decisions, naming conventions)
- **Clarity**: Clear separation of concerns (what goes where)
- **Maintainability**: Easy to update both generic and project knowledge independently

## Considered Options

### Option A: Single-Tier (Project-Only)

**Description**: All agent knowledge lives in project directories only (`.claude/agents/{agent}/`)

**Pros**:

- Simple (one location per project)
- All knowledge is project-specific
- No confusion about where to add knowledge

**Cons**:

- Must duplicate generic knowledge in every project
- No way to capture user preferences across projects
- Agents can't provide generic guidance outside project context
- High maintenance burden (update same knowledge in N projects)

**Cost**: High maintenance, no cross-project reusability

### Option B: Single-Tier (User-Only)

**Description**: All agent knowledge lives in user home directory only (`~/.claude/agents/{agent}/`)

**Pros**:

- Simple (one location globally)
- Reusable across all projects
- Captures user preferences

**Cons**:

- No project-specific context
- All projects get same generic guidance
- Can't document project-specific decisions (tech stack, ADRs, C4 models)
- Agents can't tailor recommendations to project constraints

**Cost**: No project specificity, generic recommendations only

### Option C: Two-Tier Architecture (User + Project)

**Description**: Separate user-level knowledge (generic, reusable) from project-level knowledge (specific context)

**Structure**:

```text
User-Level (generic):
~/.claude/agents/{agent}/knowledge/
  - Generic patterns
  - User preferences
  - Reusable templates
  - Evaluation frameworks

Project-Level (specific):
{project}/.claude/agents-global/{agent}/
  - Project tech stack
  - Architecture decisions (ADRs)
  - C4 models
  - Project-specific standards
```

**Pros**:

- Clear separation (generic vs specific)
- Generic knowledge reusable across projects
- Project knowledge tailored to constraints
- Agents can combine both tiers for optimal guidance
- Agents can detect when project context is missing
- User preferences apply to all projects
- Easy to maintain (update generic once, applies everywhere)

**Cons**:

- More complex (two locations to manage)
- Agents must check both locations
- Need clear guidelines on what goes where

**Cost**: Medium complexity, high value

### Option D: Three-Tier Architecture (User + Org + Project)

**Description**: Add organization-level knowledge between user and project

**Structure**:

```text
~/.claude/agents/{agent}/knowledge/          (user)
~/org/.claude/agents/{agent}/knowledge/      (organization)
{project}/.claude/agents-global/{agent}/     (project)
```

**Pros**:

- Support organization-level standards
- Good for enterprise/team use

**Cons**:

- Overly complex for individual use
- Hard to manage three tiers
- Organization concept doesn't fit AIDA (personal assistant)

**Cost**: High complexity, overkill for personal assistant

## Decision Outcome

**Chosen option**: Option C - Two-Tier Architecture (User + Project)

**Rationale**:

- Balances reusability (user-level) with specificity (project-level)
- Agents can provide intelligent guidance both inside and outside projects
- User preferences captured once, apply everywhere
- Project-specific details don't pollute generic knowledge
- Clear guidelines prevent confusion (what goes where)
- Agents can warn when project context is missing (helpful UX)
- Industry pattern (similar to VSCode user settings vs workspace settings)

### Consequences

**Positive**:

- Generic patterns documented once, reused across all projects
- User's technical philosophy captured (coding standards, preferred patterns)
- Project-specific context enables tailored recommendations
- Agents provide better guidance with full context
- Easy to maintain (update generic or project knowledge independently)
- Clear separation of concerns

**Negative**:

- More complex than single-tier (two locations)
- **Mitigation**: Clear documentation on what goes where (documented in agent definitions)
- Agents must check both locations (implementation complexity)
- **Mitigation**: Standardize context-loading pattern across all agents
- Users need to understand two-tier concept
- **Mitigation**: Agents warn when project context is missing, guide users to run `/workflow-init`

**Neutral**:

- Adds `/workflow-init` command to create project-level configuration
- Need to document tier separation in all agent definitions

## Validation

- [x] Aligned with AIDA's personal assistant philosophy (user preferences + project context)
- [x] Reviewed by development team
- [x] Implementation pattern proven (tech-lead agent already uses two-tier)
- [x] Similar to industry patterns (VSCode, Git configs)

## Implementation Notes

**User-Level Knowledge** (`~/.claude/agents/{agent}/knowledge/`):

- Generic architecture patterns (microservices, event-driven, DDD)
- User's coding standards and preferences
- Reusable templates (ADRs, C4 diagrams)
- Technology evaluation frameworks
- Cross-project best practices

**Project-Level Knowledge** (`{project}/.claude/agents-global/{agent}/`):

- Project-specific architecture (C4 models, ADRs)
- Technology stack and rationale
- Project coding standards (if different from user preferences)
- Integration specifications
- Non-functional requirements

**Agent Behavior**:

1. Always load user-level knowledge
2. Check if in project directory (`.git` exists)
3. Check if project-level knowledge exists (`.claude/agents-global/{agent}/`)
4. Combine both tiers if available
5. Warn if in project but no project-level knowledge

**Commands**:

- `/workflow-init`: Creates project-level agent configurations

## References

- Similar pattern: VSCode user settings (`~/.config/Code/User/settings.json`) vs workspace settings (`.vscode/settings.json`)
- Similar pattern: Git global config (`~/.gitconfig`) vs project config (`.git/config`)
- tech-lead agent: First implementation of two-tier architecture
- aws-cloud-engineer agent: Second implementation, proven pattern

## Updates

None yet
