---
name: ux-review
description: Review CLI UX patterns, personality consistency, and error message quality for conversational interfaces
model: sonnet
agent: shell-systems-ux-designer
type: global
args:
  scope:
    description: What to review - "all", "commands", "errors", "personality", "interactive"
    required: false
    default: "all"
---

# UX Review Command

Reviews CLI user experience patterns, personality consistency, and error message quality for conversational interfaces. Ensures commands provide excellent UX aligned with configured personality (JARVIS, Alfred, FRIDAY, etc.).

## Instructions

1. **Check for scope argument**:
   - If no scope provided, default to "all"
   - Valid scopes:
     - `all` - Comprehensive review of all UX aspects
     - `commands` - Command structure, naming, and help text
     - `errors` - Error message clarity and recovery guidance
     - `personality` - Tone consistency with configured personality
     - `interactive` - User prompts, confirmations, and input validation
   - If invalid scope provided:

     ```text
     Invalid scope: {scope}

     Valid scopes:
     - all          Review all UX aspects (default)
     - commands     Command structure and help text
     - errors       Error messages and recovery
     - personality  Tone and personality consistency
     - interactive  Prompts and user interactions

     Usage: /ux-review [scope]
     Example: /ux-review errors
     ```

2. **Identify target for review**:
   - Prompt user to specify what to review:

     ```text
     What would you like me to review?

     Options:
     1. Specific command file(s) - Provide file path(s)
     2. All commands in directory - Review entire commands/ directory
     3. Specific agent file(s) - Provide agent file path(s)
     4. Error messages in script(s) - Provide script path(s)
     5. Entire project - Comprehensive UX audit

     Enter choice (1-5):
     ```

   - Based on choice:
     - **Option 1**: Prompt for comma-separated file paths
     - **Option 2**: Use `{{CLAUDE_CONFIG_DIR}}/commands/` or `${PROJECT_ROOT}/.claude/commands/`
     - **Option 3**: Prompt for agent file paths
     - **Option 4**: Prompt for script paths
     - **Option 5**: Review project root

3. **Load personality configuration** (for personality scope):
   - Read `~/CLAUDE.md` or `{{HOME}}/CLAUDE.md` for personality settings
   - Extract configured personality (JARVIS, Alfred, FRIDAY, Sage, etc.)
   - Load personality definition from `{{AIDA_HOME}}/personalities/{personality}.yaml`
   - Note personality traits:
     - Tone (formal, casual, military, etc.)
     - Response style (concise, detailed, etc.)
     - Characteristic phrases
     - Emotional intelligence level

4. **Invoke shell-systems-ux-designer agent**:
   - Provide context:

     ```text
     UX Review Request

     Scope: {scope}
     Target: {target-description}
     Configured Personality: {personality-name}

     Review the following for UX quality:

     {file-contents-or-directory-structure}

     Focus Areas:
     {scope-specific-focus-areas}

     Personality Traits to Check:
     - Tone: {personality-tone}
     - Style: {personality-style}
     - Phrases: {personality-phrases}

     Provide detailed UX review with specific improvement recommendations.
     ```

5. **Review CLI patterns** (for "all" or "commands" scope):
   - **Command Structure**:
     - Naming consistency (kebab-case, verb-noun pattern)
     - Argument handling (required vs optional)
     - Help text completeness
     - Usage examples clarity
     - Default values documented
   - **Output Formatting**:
     - Readability and visual hierarchy
     - Consistent formatting (bullets, tables, code blocks)
     - Color usage (if applicable)
     - Emoji usage (appropriate to personality)
   - **Progress Indicators**:
     - Long operations show progress
     - Clear status messages
     - Completion confirmations
     - Step-by-step feedback

6. **Check personality consistency** (for "all" or "personality" scope):
   - **Tone Analysis**:
     - Messages match configured personality tone
     - Consistency across different message types
     - Appropriate formality level
     - Emotional intelligence in responses
   - **Language Style**:
     - Conversational vs mechanical language
     - Active vs passive voice
     - Technical jargon appropriate to audience
     - Personality-specific phrases present
   - **Contextual Awareness**:
     - Responses adapt to user context
     - Acknowledgment of previous interactions
     - Appropriate level of detail for situation
     - Empathy in error situations

7. **Audit error messages** (for "all" or "errors" scope):
   - **Clarity**:
     - Error clearly explains what went wrong
     - Technical details provided but not overwhelming
     - Root cause identified when possible
     - No cryptic error codes without explanation
   - **Helpfulness**:
     - Suggested next steps included
     - Recovery guidance provided
     - Links to documentation when relevant
     - Examples of correct usage
   - **Tone**:
     - Personality-appropriate language
     - Empathetic and supportive
     - Not blaming the user
     - Encouraging retry with guidance
   - **Structure**:
     - Consistent error format across commands
     - Exit codes documented
     - Severity levels clear (warning vs error vs fatal)

8. **Review interactive features** (for "all" or "interactive" scope):
   - **Confirmation Prompts**:
     - Clear about consequences of action
     - Sensible defaults offered
     - Easy to understand options
     - Escape/cancel option available
   - **User Input Validation**:
     - Validation happens before processing
     - Clear feedback on invalid input
     - Format examples provided
     - Retries allowed with helpful hints
   - **Graceful Degradation**:
     - Handles edge cases (empty input, special characters)
     - Timeout handling for long operations
     - Partial success scenarios handled
     - Rollback options when applicable

9. **Generate UX review report**:
   - Format report:

     ```markdown
     # UX Review Report

     **Date**: {current-date}
     **Scope**: {scope}
     **Target**: {target-description}
     **Personality**: {configured-personality}

     ## Executive Summary

     {high-level-findings}

     ## Findings by Category

     ### Command Structure (if in scope)
     - **Strengths**: {what-works-well}
     - **Issues**: {problems-found}
     - **Recommendations**: {specific-improvements}

     ### Personality Consistency (if in scope)
     - **Strengths**: {personality-wins}
     - **Issues**: {personality-mismatches}
     - **Recommendations**: {tone-improvements}

     ### Error Messages (if in scope)
     - **Strengths**: {good-error-handling}
     - **Issues**: {poor-error-messages}
     - **Recommendations**: {error-improvements}

     ### Interactive Features (if in scope)
     - **Strengths**: {good-interactions}
     - **Issues**: {interaction-problems}
     - **Recommendations**: {interaction-improvements}

     ## Detailed Findings

     ### Critical Issues
     {must-fix-problems}

     ### Improvement Opportunities
     {nice-to-have-enhancements}

     ### Best Practices Observed
     {examples-to-replicate}

     ## Prioritized Action Items

     1. {highest-priority-fix}
     2. {second-priority-fix}
     3. {third-priority-fix}
     ...

     ## Examples

     ### Before (Current)
     ```text
     {example-of-current-ux}
     ```

     ### After (Recommended)
     ```text
     {example-of-improved-ux}
     ```

     ## References

     - Configured personality: `{{AIDA_HOME}}/personalities/{personality}.yaml`
     - UX best practices: {relevant-docs}
     - Related patterns: {similar-good-examples}
     ```

10. **Save review report**:
    - If reviewing specific command/agent:
      - Save to: `${PROJECT_ROOT}/.github/reviews/ux-review-{target-name}-{date}.md`
    - If reviewing entire project:
      - Save to: `${PROJECT_ROOT}/.github/reviews/ux-review-comprehensive-{date}.md`
    - Create `.github/reviews/` directory if it doesn't exist
    - Add frontmatter to report with review metadata

11. **Provide actionable summary**:
    - Display summary:

      ```text
      ✓ UX Review Complete

      Scope: {scope}
      Target: {target-description}
      Issues Found: {count}
      - Critical: {critical-count}
      - Moderate: {moderate-count}
      - Minor: {minor-count}

      Top 3 Recommendations:
      1. {top-recommendation-1}
      2. {top-recommendation-2}
      3. {top-recommendation-3}

      Full Report: {report-path}

      Next Steps:
      - Review detailed findings in report
      - Prioritize critical issues for immediate fix
      - Consider improvement opportunities for future iterations
      - Update personality configuration if misalignment found
      ```

## Examples

```bash
# Comprehensive UX review of entire project
/ux-review all

# Review error messages only
/ux-review errors

# Review personality consistency across commands
/ux-review personality

# Review specific command
/ux-review commands
# Then select option 1 and provide: ~/.claude/commands/start-work.md

# Review interactive features
/ux-review interactive
```

## Error Handling

- **Invalid scope**: Show valid scope options and usage examples
- **No target specified**: Prompt user to choose target for review
- **File not found**: Display error and ask user to verify path
- **Personality config not found**: Warn and proceed with generic UX review
- **Permission error**: Display error and suggest checking file permissions
- **shell-systems-ux-designer agent not available**: Provide fallback basic UX checklist

## Success Criteria

- Report identifies specific UX issues with examples
- Recommendations are actionable and prioritized
- Personality alignment is verified against configuration
- Error messages evaluated for clarity and helpfulness
- Interactive patterns follow best practices
- Report saved to reviewable location

## Notes

- This command works with any personality configuration (JARVIS, Alfred, FRIDAY, etc.)
- Reviews are saved for historical tracking and trend analysis
- Can be run at any stage of development (pre-commit, PR review, periodic audits)
- Complements code quality tools (shellcheck, yamllint) with UX focus
- Part of the AIDA quality assurance toolkit
- Agent invocation ensures specialized UX expertise is applied
- Reviews consider both technical correctness and user experience

## Related Commands

- `/create-command` - Create new command (use UX review to validate)
- `/create-agent` - Create new agent (ensure agent UX is consistent)
- `/security-audit` - Security-focused review (complementary to UX)
- `/implement` - Implementation workflow (run UX review before completion)

## Integration with Workflow

**When to use UX review**:

1. **Before opening PR**: Run `/ux-review all` to catch UX issues early
2. **After creating command**: Run `/ux-review commands` to validate new command UX
3. **Periodic audits**: Monthly `/ux-review all` to maintain UX quality
4. **User feedback**: Run `/ux-review errors` if users report confusing messages
5. **Personality changes**: Run `/ux-review personality` after switching personalities

**Typical workflow**:

```bash
# Create new command
/create-command analyze-logs

# Implement command logic
# ... edit command file ...

# Review UX before committing
/ux-review commands
# Select the new command file

# Address critical findings
# ... fix UX issues ...

# Commit with confidence
git add templates/commands/analyze-logs.md
git commit -m "Add analyze-logs command with UX review"
```
