---
title: "Product Manager - AIDA Project Instructions"
description: "AIDA-specific product requirements and context"
category: "project-agent-instructions"
tags: ["aida", "product-management", "project-context"]
last_updated: "2025-10-06"
status: "active"
---

# AIDA Product Manager Instructions

Project-specific product management context for the AIDA framework.

## Project Overview

**Name**: AIDA (Agentic Intelligence Digital Assistant)
**Domain**: Developer Tools + System Utilities
**License**: AGPL-3.0
**Versioning**: Semantic versioning (REQUIRED)

## Product Requirements

### Core Principles

1. **Developer Experience is Paramount**
   - End users are tech-savvy software engineers
   - Primary stakeholders/users: Software engineers
   - Respect their intelligence and technical capability
   - No hand-holding, assume competence

2. **Adaptability is Key**
   - System must be highly adaptable for end-user modifications
   - User experience must be customizable
   - Framework should be flexible, not prescriptive

3. **Documentation is Critical**
   - Two documentation tracks required:
     - **How-to guides**: For AIDA users (with dotfiles integration)
     - **Integration guides**: For AIDA framework standalone (without dotfiles)
   - Both must be comprehensive and maintained

### Product Differentiators

**Primary Selling Points** (in order of importance):

1. **Agents / Commands and Their Versatility** (Most Important)
   - Agent system is the core value proposition
   - Commands must be flexible and powerful
   - Extensibility is critical

2. **Personality / Digital Assistant Experience** (Major Selling Point)
   - The "digital assistant" UX is unique
   - Personality system differentiates us from other CLI tools
   - Must feel conversational and intelligent

### Product Patterns

- ✓ **Dogfooding**: We use what we build
- ✓ **Open Source**: Community-driven development
- ✓ **Privacy-Focused**: Data protection is non-negotiable

## Requirements Definition

### Must-Haves (P0)

- AGPL-3.0 license compliance
- Semantic versioning
- Agent system versatility
- Personality system functionality
- Standalone operation (works without dotfiles)
- Integration with dotfiles (optional but recommended)

### Success Metrics

- **Developer adoption**: Engineers actually use it
- **Extensibility**: Users create custom agents/commands
- **Personality engagement**: Users switch/customize personalities
- **Documentation quality**: Users can integrate without support

### Out of Scope

- Non-technical users (not our audience)
- GUI/visual interfaces (CLI-first always)
- Proprietary integrations requiring paid licenses

## Stakeholder Communication

### Primary Stakeholder: Software Engineers

- **Tone**: Technical, direct, no fluff
- **Format**: Code examples, clear documentation
- **Expectations**: High technical literacy, problem-solving ability

### Secondary Stakeholder: Open Source Community

- **Engagement**: GitHub issues, discussions, contributions
- **Transparency**: Open roadmap, public decision-making
- **Support**: Community-first, documentation-driven

## PRD Requirements for AIDA

When creating PRDs for AIDA features:

### Required Sections

1. **Problem Statement**: What user pain point does this solve?
2. **User Stories**: Specific engineer workflows
3. **Technical Requirements**:
   - Agent/Command requirements
   - Personality system integration
   - Dotfiles integration points
4. **Documentation Requirements**:
   - How-to guides needed
   - Integration guide updates
5. **Success Criteria**: How we measure success
6. **Extensibility**: How users can customize/extend

### AIDA-Specific Considerations

- **Agent System Impact**: How does this affect existing agents?
- **Personality System**: Does this require personality updates?
- **Dotfiles Integration**: Standalone vs. integrated behavior
- **License Compliance**: AGPL-3.0 requirements met?
- **Semantic Versioning**: Breaking change? Minor? Patch?

## Decision Framework for AIDA

### When to Add a Feature

✓ **Yes** if:

- Enhances agent/command versatility
- Improves personality/assistant experience
- Solves real engineer pain points (dogfooding test)
- Maintains/improves adaptability
- Preserves privacy

✗ **No** if:

- Reduces extensibility
- Limits user customization
- Requires proprietary dependencies
- Violates AGPL-3.0 spirit
- Dumbs down for non-technical users

### When to Create New Agent vs. Extend Existing

**New Agent** if:

- Distinct domain expertise required
- Independent decision-making needed
- Can be made generic for user-level reuse

**Extend Existing** if:

- Overlaps with existing agent domain
- Same expertise/knowledge required
- Temporary project-specific need

## Integration Notes

- **User-level PM preferences**: Load from `~/.claude/agents/product-manager/`
- **Project-specific context**: This file
- **Combined approach**: User philosophy + AIDA requirements

---

**Last Updated**: 2025-10-06 via /workflow-init
