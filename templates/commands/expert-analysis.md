---
name: expert-analysis
description: Run multi-agent expert analysis on current issue to generate PRD and technical specifications
args: {}
---

# Expert Analysis Command

Orchestrates multi-agent analysis of the current issue to produce Product Requirements Document (PRD) and Technical Specification. Coordinates Product Manager, Tech Lead, and specialist agents to ensure comprehensive requirement analysis and technical planning.

## Usage

```bash
/expert-analysis
```text

**Prerequisites**:

- Must have run `/start-work <issue-id>` first (requires active issue)
- Expert analysis must be enabled in `${CLAUDE_CONFIG_DIR}/workflow-config.json`
- Product Manager and Tech Lead agents must be configured

## Instructions

### 1. Validate Prerequisites

- **Check Active Issue**:
  - Verify `${CLAUDE_CONFIG_DIR}/workflow-config.json` exists and has `expert_analysis.enabled = true`
  - Check for active issue in configured issue tracking directory
  - Pattern: `{issue_tracking.directory}/{in_progress}/issue-{id}/`
  - If no active issue found: Display error and suggest running `/start-work <issue-id>` first
  - If multiple active issues: Ask user which one to analyze

- **Load Configuration**:
  - Read `${CLAUDE_CONFIG_DIR}/workflow-config.json`
  - Extract `expert_analysis` section
  - Validate Product Manager agent exists: `~/${CLAUDE_CONFIG_DIR}/agents/product-manager/`
  - Validate Tech Lead agent exists: `~/${CLAUDE_CONFIG_DIR}/agents/tech-lead/`
  - If either missing: Display error and suggest running `/workflow-init` first

- **Load Issue Details**:
  - Read `{issue_tracking.directory}/{in_progress}/issue-{id}/README.md`
  - Extract issue metadata (title, description, requirements, labels)
  - Store for agent context

### 2. Check for Existing Analysis (Idempotency)

- **Check for existing documents**:
  - Check if `{issue-folder}/PRD.md` exists
  - Check if `{issue-folder}/TECH_SPEC.md` exists
  - Check if `{issue-folder}/IMPLEMENTATION_SUMMARY.md` exists

- **If all documents exist** (complete analysis):
  - Display:

    ```
    ✓ Expert analysis already complete for issue #{id}

    Existing Documents:
    • PRD.md
    • TECH_SPEC.md
    • IMPLEMENTATION_SUMMARY.md

    How would you like to proceed?
    [1] Skip - Use existing analysis (recommended)
    [2] Update - Re-run Q&A and update documents
    [3] Regenerate - Start fresh, overwrite all documents
    [4] Cancel
    ```

  - Handle choice:
    - Option 1 (Skip): Exit successfully (true idempotent)
    - Option 2 (Update): Skip to step 5 (Q&A phase), update documents based on new answers
    - Option 3 (Regenerate): Continue to step 3 normally
    - Option 4 (Cancel): Exit command

- **If partial documents exist** (incomplete analysis):
  - Detect which documents are missing
  - Display:

    ```
    ⚠ Partial analysis detected for issue #{id}

    Existing: {list existing docs}
    Missing: {list missing docs}

    How would you like to proceed?
    [1] Resume - Continue from where left off
    [2] Regenerate - Start fresh, overwrite existing
    [3] Cancel
    ```

  - Handle choice:
    - Option 1 (Resume):
      - If PRD exists, skip to step 4 (Technical Analysis)
      - If TECH_SPEC exists but no summary, skip to step 6 (Implementation Summary)
    - Option 2 (Regenerate): Continue to step 3 normally
    - Option 3 (Cancel): Exit command

- **If no documents exist**: Continue to step 3 normally

### 3. Display Analysis Plan

```text
🔬 Expert Analysis Workflow
============================

Analyzing: Issue #{id} - {title}

Configuration:
• Product Manager: {pm-agent}
• Tech Lead: {tech-lead-agent}
• Product Agents: {count} ({list})
• Technical Agents: {count} ({list})
• Q&A Mode: {interactive|batch}
• Document Format: {concise|comprehensive}

Workflow:
1. Product Analysis (parallel agent invocation)
2. Product Manager synthesizes PRD
3. Technical Analysis (parallel agent invocation)
4. Tech Lead synthesizes technical spec
5. Q&A iteration (until complete)
6. Implementation summary

Working Directory: {issue-folder}

Ready to begin analysis? [Y/n]
```text

- If user declines: Exit command
- If user accepts: Continue to step 4

### 4. Product Analysis Phase

- **Display Phase Header**:

  ```text
  📋 Phase 1: Product Analysis
  =============================
  ```

- **Invoke Product Agents in Parallel**:
  - Create working directory: `{issue-folder}/analysis/product/`
  - For each product agent in config (`expert_analysis.agents.product`):
    - Invoke agent with Task tool
    - Prompt template:

      ```text
      Analyze this requirement from your domain expertise perspective.

      Issue: #{id} - {title}
      {issue-description}

      Requirements:
      {requirements-section}

      Provide analysis covering:
      1. Domain-Specific Concerns
         - What concerns does this raise in your area?
         - What constraints or requirements apply?

      2. Stakeholder Impact
         - Who is affected by this change?
         - What value does it provide?
         - What risks or downsides exist?

      3. Questions & Clarifications
         - What information is missing?
         - What decisions need to be made?
         - What assumptions need validation?

      4. Recommendations
         - What approach do you recommend?
         - What should be prioritized?
         - What should be avoided?

      Keep analysis CONCISE - use bullet points. Save your analysis to:
      {issue-folder}/analysis/product/{agent-name}-analysis.md
      ```

  - Wait for all product agents to complete
  - Display progress: `✓ {agent-name} analysis complete`

- **Product Manager Synthesis**:
  - Display: `📝 Product Manager synthesizing PRD...`
  - Invoke Product Manager agent with Task tool
  - Prompt template:

    ```text
    Review all product agent analyses and synthesize into a Product Requirements Document (PRD).

    Issue: #{id} - {title}

    Agent Analyses:
    {Read all files from analysis/product/*.md}

    Create a CONCISE PRD covering:

    ## Executive Summary
    - 2-3 sentences: What, why, value

    ## Stakeholder Analysis
    For each stakeholder perspective (executive, customer, engineer, etc.):
    - Key concerns
    - Priorities
    - Recommendations

    ## Requirements
    ### Functional Requirements
    - Bullet list of what system must do

    ### Non-Functional Requirements
    - Performance, security, usability constraints

    ## Success Criteria
    - Measurable outcomes that define success

    ## Open Questions
    - Decisions needed before implementation
    - Information gaps
    - Assumptions to validate

    ## Recommendations
    - Recommended approach
    - MVP scope (if applicable)
    - What to prioritize/defer

    Save PRD to: {issue-folder}/PRD.md

    Use PRD_TEMPLATE.md as reference for structure.
    ```

  - Wait for PM to complete
  - Display: `✓ PRD created: {issue-folder}/PRD.md`

### 5. Technical Analysis Phase

- **Display Phase Header**:

  ```text
  🔧 Phase 2: Technical Analysis
  ===============================
  ```

- **Invoke Technical Agents in Parallel**:
  - Create working directory: `{issue-folder}/analysis/technical/`
  - For each technical agent in config (`expert_analysis.agents.technical`):
    - Invoke agent with Task tool
    - Prompt template:

      ```text
      Analyze this requirement from your technical expertise perspective.

      Issue: #{id} - {title}
      {issue-description}

      Requirements:
      {requirements-section}

      PRD Summary:
      {executive-summary-from-PRD}

      Provide technical analysis covering:

      1. Implementation Approach
         - Recommended technical approach
         - Key technical decisions
         - Technology/tool choices

      2. Technical Concerns
         - Performance implications
         - Security considerations
         - Scalability/maintainability
         - Technical risks

      3. Dependencies & Integration
         - What systems/components affected?
         - What dependencies required?
         - Integration points and concerns

      4. Effort & Complexity
         - Estimated complexity (S/M/L/XL)
         - Key effort drivers
         - Risk areas

      5. Questions & Clarifications
         - Technical questions needing answers
         - Decisions to be made
         - Areas needing investigation

      Keep analysis CONCISE - use bullet points. Save your analysis to:
      {issue-folder}/analysis/technical/{agent-name}-analysis.md
      ```

  - Wait for all technical agents to complete
  - Display progress: `✓ {agent-name} analysis complete`

- **Tech Lead Synthesis**:
  - Display: `🔧 Tech Lead synthesizing technical specification...`
  - Invoke Tech Lead agent with Task tool
  - Prompt template:

    ```text
    Review all technical agent analyses and synthesize into a Technical Specification.

    Issue: #{id} - {title}

    PRD Summary:
    {Read PRD.md executive summary and requirements}

    Technical Analyses:
    {Read all files from analysis/technical/*.md}

    Create a CONCISE Technical Specification covering:

    ## Architecture Overview
    - High-level approach (2-3 sentences)
    - Key components and their interactions
    - Architecture diagram (optional, if helpful)

    ## Technical Decisions
    For each major decision:
    - Decision: What was decided
    - Rationale: Why this approach
    - Alternatives: What else was considered
    - Trade-offs: Pros/cons

    ## Implementation Plan
    ### Components to Build/Modify
    - Component name: Brief description of changes

    ### Dependencies
    - External dependencies required
    - Internal components affected

    ### Integration Points
    - How this integrates with existing systems
    - APIs or interfaces to create/modify

    ## Technical Risks & Mitigations
    - Risk: Description
    - Impact: High/Medium/Low
    - Mitigation: How to address

    ## Testing Strategy
    - Unit testing approach
    - Integration testing needs
    - Edge cases to cover

    ## Open Technical Questions
    - Questions needing answers before implementation
    - Investigation needed
    - POC/spike work recommended

    ## Effort Estimate
    - Overall complexity: S/M/L/XL
    - Key effort drivers
    - Recommended breakdown (if helpful)

    Save Technical Spec to: {issue-folder}/TECH_SPEC.md

    Use TECH_SPEC_TEMPLATE.md as reference for structure.
    ```

  - Wait for Tech Lead to complete
  - Display: `✓ Technical Spec created: {issue-folder}/TECH_SPEC.md`

### 6. Q&A Iteration Phase

- **Display Phase Header**:

  ```text
  ❓ Phase 3: Q&A Iteration
  ==========================
  ```

- **Collect All Open Questions**:
  - Read PRD.md "Open Questions" section
  - Read TECH_SPEC.md "Open Technical Questions" section
  - Compile into numbered list
  - If no questions: Skip to step 6

- **Q&A Mode: Interactive**:
  - Display all questions with numbers
  - For each question:
    - Display question
    - Ask user for answer/decision
    - Record answer in `{issue-folder}/qa-log.md`
    - Append to running Q&A context

- **Q&A Mode: Batch**:
  - Display all questions at once
  - Collect all answers in single prompt
  - Record in `{issue-folder}/qa-log.md`

- **Re-Analysis Decision**:
  - After answering questions, show summary:

    ```text
    Q&A Summary:
    • {count} questions answered
    • Key decisions: {list major decisions}

    Do answers require re-analysis? [y/N]
    - y: PM/Tech Lead review answers, update PRD/TECH_SPEC
    - N: Proceed to implementation summary
    ```

  - If re-analysis requested:
    - Invoke PM to update PRD with Q&A context
    - Invoke Tech Lead to update TECH_SPEC with Q&A context
    - Check for new questions
    - Repeat Q&A iteration if new questions exist

### 7. Implementation Summary

- **Display Phase Header**:

  ```text
  📊 Phase 4: Implementation Summary
  ===================================
  ```

- **Generate Summary**:
  - Read PRD.md
  - Read TECH_SPEC.md
  - Read qa-log.md (if exists)
  - Create `{issue-folder}/IMPLEMENTATION_SUMMARY.md`:

    ```markdown
    # Implementation Summary: Issue #{id}

    ## Overview
    - **What**: {1-sentence description}
    - **Why**: {1-sentence value}
    - **Approach**: {1-sentence technical approach}

    ## Key Decisions
    1. {Decision}: {Rationale}
    2. {Decision}: {Rationale}
    ...

    ## Implementation Scope
    ### In Scope
    - {Item}
    - {Item}

    ### Out of Scope (Deferred)
    - {Item}
    - {Item}

    ## Technical Approach
    - {Component}: {What will be done}
    - {Component}: {What will be done}

    ## Risks & Mitigations
    | Risk | Impact | Mitigation |
    |------|--------|------------|
    | {Risk} | {H/M/L} | {Mitigation} |

    ## Success Criteria
    - {Criterion}
    - {Criterion}

    ## Effort Estimate
    - Complexity: {S/M/L/XL}
    - Estimated Hours: {hours} (from issue metadata)
    - Key Effort Drivers: {list}

    ## Next Steps
    1. {Action item}
    2. {Action item}
    ```

### 8. Final Summary & Next Steps

- **Display Complete Summary**:

  ```text
  ✅ Expert Analysis Complete!
  ============================

  Documents Created:
  ✓ PRD.md - Product Requirements Document
  ✓ TECH_SPEC.md - Technical Specification
  {If Q&A occurred:}
  ✓ qa-log.md - Q&A Log ({count} questions answered)
  {End if}
  ✓ IMPLEMENTATION_SUMMARY.md - Implementation Summary

  Agent Contributions:
  • Product Analysis: {count} agents
  • Technical Analysis: {count} agents
  • Q&A Iterations: {count}

  Key Decisions Made:
  {List 3-5 most important decisions}

  Next Steps:
  1. Review documents in: {issue-folder}/
  2. Update issue README.md with summary (if needed)
  3. Begin implementation
  4. Run /track-time as you work
  5. Run /open-pr when ready

  Location: {issue-folder}/
  ```

- **Optional: Update Issue README**:
  - Ask: "Append implementation summary to issue README? [Y/n]"
  - If yes:
    - Append link to IMPLEMENTATION_SUMMARY.md
    - Add note: "Expert analysis completed on {date}"

## Configuration

Uses `${CLAUDE_CONFIG_DIR}/workflow-config.json`:

```json
{
  "workflow": {
    "expert_analysis": {
      "enabled": true,
      "product_manager": {
        "agent": "product-manager",
        "domain": "Developer Tools",
        "patterns": ["open source"]
      },
      "tech_lead": {
        "agent": "tech-lead",
        "philosophy": "pragmatic",
        "tech_stack": ["bash", "javascript"]
      },
      "agents": {
        "product": ["configuration-specialist", "integration-specialist"],
        "technical": ["shell-script-specialist", "devops-engineer"]
      },
      "qa_mode": "interactive",
      "document_format": "concise"
    }
  }
}
```text

## Document Templates

### PRD_TEMPLATE.md

Located at: `templates/documents/PRD_TEMPLATE.md`

Defines structure for Product Requirements Documents:

- Executive Summary
- Stakeholder Analysis
- Requirements (Functional & Non-Functional)
- Success Criteria
- Open Questions
- Recommendations

### TECH_SPEC_TEMPLATE.md

Located at: `templates/documents/TECH_SPEC_TEMPLATE.md`

Defines structure for Technical Specifications:

- Architecture Overview
- Technical Decisions
- Implementation Plan
- Technical Risks
- Testing Strategy
- Effort Estimate

## Examples

### Basic Usage

```bash
# After starting work on issue
/start-work 42

# Run expert analysis
/expert-analysis

# System orchestrates:
# 1. Product agents analyze requirements
# 2. PM creates PRD
# 3. Technical agents analyze implementation
# 4. Tech Lead creates TECH_SPEC
# 5. Q&A iteration
# 6. Implementation summary

# Review results
cat .github/issues/in-progress/issue-42/PRD.md
cat .github/issues/in-progress/issue-42/TECH_SPEC.md
cat .github/issues/in-progress/issue-42/IMPLEMENTATION_SUMMARY.md
```text

### With Custom Agents

```bash
# workflow-config.json configured with domain-specific agents
{
  "expert_analysis": {
    "agents": {
      "product": [
        "larp-product-manager",
        "privacy-security-auditor"
      ],
      "technical": [
        "php-engineer",
        "strapi-backend-engineer",
        "api-design-architect"
      ]
    }
  }
}

# Analysis uses LARP-specific product expertise
# and PHP/Strapi technical expertise
/expert-analysis
```text

## Error Handling

- **No active issue**: Display error, suggest `/start-work <issue-id>`
- **Expert analysis disabled**: Display error, suggest `/workflow-init`
- **Missing PM/Tech Lead**: Display error, suggest `/workflow-init`
- **Agent invocation fails**: Log error, continue with available analyses
- **Document template missing**: Use inline template structure
- **Permission errors**: Display error with file path and permissions needed

## Performance Notes

- **Parallel agent execution**: Product and technical agents run in parallel for speed
- **Large issue context**: May hit token limits with very large requirements
- **Agent selection**: More agents = more comprehensive but slower analysis
- **Document format**: "concise" mode significantly reduces token usage

## Integration with Workflow

1. `/workflow-init` - Configures expert analysis, creates PM/Tech Lead agents
2. `/create-issue` - Creates issue (optional: run expert analysis automatically?)
3. `/start-work` - Starts work on issue, sets up issue folder
4. `/expert-analysis` - **THIS COMMAND** - Analyzes issue, creates PRD/TECH_SPEC
5. Implementation work - Developer codes based on PRD/TECH_SPEC
6. `/track-time` - Logs time during implementation
7. `/open-pr` - Creates PR with links to PRD/TECH_SPEC

## Related Commands

- `/workflow-init` - Configure expert analysis workflow
- `/start-work <issue-id>` - Required before running expert analysis
- `/open-pr` - Can reference PRD/TECH_SPEC in PR body

## Notes

- **Concise documents**: User preference is bullet points over flowery prose
- **Parallel execution**: Agents work simultaneously, PM/Tech Lead consolidate
- **Iterative Q&A**: Ensures all questions answered before implementation
- **Agent expertise**: Product agents focus on requirements, technical agents focus on implementation
- **Knowledge accumulation**: PM and Tech Lead learn from each analysis (stored in agent knowledge)

---

**Design Philosophy**: Automate comprehensive requirement analysis through coordinated expert agents while maintaining human decision-making on key questions.
