---
title: "Product Requirements Document Template"
description: "Template for creating concise, actionable PRDs through expert analysis"
version: "1.0.0"
last_updated: "2025-10-05"
---

# Product Requirements Document: [Issue Title]

**Issue**: #[ID]
**Status**: [DRAFT/APPROVED/IN_PROGRESS/COMPLETED]
**Created**: [Date]
**Last Updated**: [Date]
**Product Manager**: [Agent/Person]

## Executive Summary

<!-- 2-3 sentences covering: What is being built, why it matters, and the expected value/outcome -->

**What**: [Brief description of the feature/change]

**Why**: [Business/user value - why this matters]

**Value**: [Expected outcome or benefit]

## Stakeholder Analysis

<!-- For each stakeholder perspective, capture concerns, priorities, and recommendations -->

### Executive Perspective

**Concerns**:

- [Business risk or concern]
- [ROI or resource concern]

**Priorities**:

- [What matters most to executives]
- [Strategic alignment points]

**Recommendations**:

- [Executive's recommended approach]

### Customer/User Perspective

**Concerns**:

- [Usability concern]
- [Value concern]

**Priorities**:

- [What matters most to users]
- [Pain points being solved]

**Recommendations**:

- [User-centric recommendations]

### Engineering Perspective

**Concerns**:

- [Technical feasibility concern]
- [Maintenance concern]

**Priorities**:

- [What matters to engineering team]
- [Technical quality factors]

**Recommendations**:

- [Technical recommendations]

### [Other Stakeholders]

<!-- Add sections for Operations, Security, Marketing, etc. as needed -->

### Synthesis

<!-- PM's consolidated view addressing conflicting priorities -->

**Key Conflicts**:

- [Describe any conflicting stakeholder priorities]

**Resolution**:

- [How conflicts are addressed in the recommendation]

## Requirements

### Functional Requirements

<!-- What the system must do - use "MUST/SHOULD/COULD" for prioritization -->

**MUST** (Critical):

- [Core functionality that must be present]
- [Essential capability]

**SHOULD** (Important):

- [Important but not critical]
- [Can be deferred if needed]

**COULD** (Nice-to-have):

- [Desirable but optional]
- [Enhancement for future]

### Non-Functional Requirements

<!-- Quality attributes, constraints, and standards -->

**Performance**:

- [Response time requirements]
- [Throughput requirements]

**Security**:

- [Authentication/authorization requirements]
- [Data protection requirements]

**Usability**:

- [User experience requirements]
- [Accessibility requirements]

**Compatibility**:

- [Platform/browser requirements]
- [Integration requirements]

**Maintainability**:

- [Code quality standards]
- [Documentation requirements]

## Success Criteria

<!-- Measurable outcomes that define when this is complete and successful -->

**Acceptance Criteria**:

- [ ] [Specific, testable criterion]
- [ ] [Specific, testable criterion]
- [ ] [Specific, testable criterion]

**Key Metrics**:

- [Metric to measure]: [Target value]
- [Metric to measure]: [Target value]

**User Impact**:

- [How user experience improves]
- [Measurable user outcome]

## Scope

### In Scope

<!-- What IS included in this effort -->

- [Feature/capability included]
- [Component included]

### Out of Scope

<!-- What is explicitly NOT included - deferred or excluded -->

- [Feature deferred to future]
- [Component explicitly excluded]

**Rationale for Deferrals**:

- [Why certain items are out of scope]

## Open Questions

<!-- Decisions needed before or during implementation -->

### Product Questions

**Q1**: [Question about requirements or user needs]

- **Impact**: [High/Medium/Low - why this matters]
- **Owner**: [Who should answer this]
- **Status**: [OPEN/ANSWERED]

**Q2**: [Another question]

- **Impact**: [Impact level and reasoning]
- **Owner**: [Decision maker]
- **Status**: [Status]

### Business Questions

**Q1**: [Question about business logic or process]

- **Impact**: [Impact level]
- **Owner**: [Owner]
- **Status**: [Status]

## Assumptions

<!-- Known assumptions being made - should be validated -->

- [Assumption about user behavior]
- [Assumption about technical capability]
- [Assumption about business process]

## Dependencies

<!-- External dependencies that could affect this work -->

- [Dependency on other team/system]
- [Dependency on external service]
- [Dependency on business decision]

## Recommendations

### Recommended Approach

<!-- PM's recommended approach based on stakeholder analysis -->

**Approach**: [High-level approach]

**Rationale**:

- [Why this approach over alternatives]
- [How it addresses stakeholder concerns]

**Phasing** (if applicable):

1. **Phase 1 - MVP**: [Minimal viable scope]
2. **Phase 2 - Enhancement**: [Next iteration]
3. **Phase 3 - Full**: [Complete vision]

### What to Prioritize

- [Item to prioritize and why]
- [Item to prioritize and why]

### What to Defer

- [Item to defer and why]
- [Item to defer and why]

### What to Avoid

- [Approach or pattern to avoid and why]
- [Risk to avoid and why]

## Risks & Mitigations

<!-- Product and business risks -->

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| [Risk description] | H/M/L | H/M/L | [How to mitigate] |
| [Risk description] | H/M/L | H/M/L | [How to mitigate] |

## Timeline & Effort

**Estimated Effort**: [Hours/Story Points]

**Complexity**: [S/M/L/XL]

**Target Completion**: [Date or Sprint]

**Key Milestones**:

1. \[Milestone\]: \[Date\]
2. \[Milestone\]: \[Date\]

## Related Documents

- **Technical Specification**: [Link to TECH_SPEC.md]
- **Implementation Summary**: [Link to IMPLEMENTATION_SUMMARY.md]
- **Original Issue**: [Link to GitHub issue]
- **Design Mockups**: [Link if applicable]

## Revision History

| Date | Author | Changes | Status |
|------|--------|---------|--------|
| [Date] | [PM Agent] | Initial PRD creation | DRAFT |
| [Date] | [PM Agent] | Updated after Q&A | DRAFT |

---

## Notes for Product Managers

**Keep it concise**:

- Use bullet points over paragraphs
- Focus on "what" and "why", not "how" (that's in TECH_SPEC)
- 2-3 pages maximum for most features

**Stakeholder section is key**:

- Capture diverse perspectives
- Identify conflicts early
- Document how conflicts are resolved

**Requirements should be testable**:

- "MUST support user login" ✓
- "Should be easy to use" ✗ (not measurable)

**Open questions are normal**:

- Document them explicitly
- Track status as they're answered
- Update PRD when answers require changes

**PRD is living document**:

- Update as decisions are made
- Track revision history
- Keep team aligned on current state
