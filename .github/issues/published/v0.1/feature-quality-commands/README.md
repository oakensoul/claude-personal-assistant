---
slug: quality-commands
title: "Create /quality and /docs commands - quality assurance and documentation"
type: feature
milestone: v0.1.0
labels: foundational, commands, quality
estimated_effort: 6
status: draft
created: 2025-10-10
depends_on: ["versioning-system"]
---

# Create /quality and /docs commands - quality assurance and documentation

## Problem

Quality assurance commands are scattered:
- `code-review`, `script-audit`, `config-validate`, `ux-review` - individual commands
- `qa-check`, `test-plan` - separate testing commands
- `generate-docs`, `runbook` - documentation commands not grouped

Need organized quality and documentation commands.

## Solution

Create two consolidated commands for quality assurance and documentation.

### `/quality` Command

```bash
/quality code [path]            # Code review
/quality script [path]          # Shell script audit
/quality config [path]          # Config validation
/quality ux [path]              # UX review
/quality qa                     # QA checks
/quality test [path]            # Test plan generation
/quality all                    # Run all quality checks
```

**Code Review:**
- Security vulnerabilities
- Performance issues
- Code style/standards
- Best practices
- Maintainability

**Script Audit:**
- ShellCheck compliance
- Security issues
- Error handling
- Portability
- Best practices

**Config Validation:**
- YAML/JSON/TOML validation
- Schema compliance
- Security issues
- Best practices

**UX Review:**
- CLI interaction patterns
- Terminal UX design
- Command ergonomics
- Error messages
- Help text clarity

### `/docs` Command

```bash
/docs generate [audience]       # Generate documentation
/docs runbook [name]            # Access/create runbooks
/docs list                      # List all documentation
/docs validate                  # Validate documentation
```

**Audiences:**
- `developers` - Technical documentation
- `customers` - End-user guides
- `partners` - Integration guides
- `internal` - Internal procedures

**Features:**
- Multiple format support (Markdown, HTML, PDF)
- Automatic TOC generation
- Cross-referencing
- Version tracking

## Implementation Tasks

- [ ] **Design `/quality` command**
  - Subcommand routing
  - Agent orchestration
  - Report generation
  - Multi-check aggregation

- [ ] **Implement `/quality code`**
  - Code review workflow
  - Security scanning
  - Style checking
  - Best practices validation
  - Generate actionable report

- [ ] **Implement `/quality script`**
  - ShellCheck integration
  - Security review
  - Error handling validation
  - Portability checks
  - Best practices review

- [ ] **Implement `/quality config`**
  - YAML/JSON/TOML parsing
  - Schema validation
  - Security review
  - Best practices check

- [ ] **Implement `/quality ux`**
  - CLI interaction analysis
  - Error message review
  - Help text validation
  - Consistency checking

- [ ] **Implement `/quality qa` and `/quality test`**
  - QA checklist generation
  - Test plan creation
  - Coverage analysis
  - Edge case identification

- [ ] **Implement `/quality all`**
  - Run all quality checks
  - Aggregate results
  - Generate comprehensive report
  - Prioritize findings

- [ ] **Design `/docs` command**
  - Documentation generation
  - Runbook management
  - Validation workflow

- [ ] **Implement `/docs generate`**
  - Audience selection
  - Content generation
  - Format selection
  - TOC generation
  - Cross-references

- [ ] **Implement `/docs runbook`**
  - List available runbooks
  - Execute runbook steps
  - Create new runbooks
  - Update existing runbooks

- [ ] **Implement `/docs validate`**
  - Link checking
  - Format validation
  - Completeness checking
  - Style consistency

- [ ] **Add comprehensive error handling**
  - Missing tools
  - Invalid paths
  - Parse errors
  - Permission issues

- [ ] **Documentation**
  - Usage examples for each command
  - Quality standards guide
  - Documentation best practices
  - Runbook templates

## Success Criteria

- [ ] All quality checks run successfully
- [ ] Documentation generation works for all audiences
- [ ] Runbook management is intuitive
- [ ] Reports are clear and actionable
- [ ] Tests pass on macOS and Linux
- [ ] Documentation is comprehensive

## Testing Scenarios

```bash
# Test quality checks
/quality code src/
/quality script scripts/install.sh
/quality config .github/workflows/
/quality ux templates/commands/
/quality all

# Test documentation
/docs generate developers
/docs runbook deployment
/docs list
/docs validate

# Test comprehensive quality review
/quality all --report=summary
```

## Dependencies

- Requires: versioning-system (#1)
- Blocks: None (can be developed in parallel with other commands)

## Replaces v1 Commands

- `code-review` → `/quality code`
- `script-audit` → `/quality script`
- `config-validate` → `/quality config`
- `ux-review` → `/quality ux`
- `qa-check` → `/quality qa`
- `test-plan` → `/quality test`
- `generate-docs` → `/docs generate`
- `runbook` → `/docs runbook`

## Notes

- Focus on actionable findings
- Clear priority levels (critical, high, medium, low)
- Generate reports that guide fixes
- Documentation should be audience-appropriate
- Runbooks should be executable, not just reference
