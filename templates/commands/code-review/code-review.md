---
name: code-review
description: Comprehensive code quality review for security, performance, and maintainability
category: analysis
model: sonnet
args:
  scope:
    description: What to review - "all", "changed", "staged", or specific file/directory path
    required: false
  focus:
    description: Review focus - "security", "performance", "quality", "all" (default)
    required: false
version: 1.0.0
---

# Code Review - Comprehensive Code Quality Analysis

Perform comprehensive code quality review across all technologies with focus on security vulnerabilities, performance bottlenecks, maintainability issues, and best practices adherence. Provides severity-rated findings with actionable fixes and code examples.

## Usage

```bash
# Review all files in project
/code-review
/code-review --scope all

# Review only changed files (uncommitted + staged)
/code-review --scope changed

# Review only staged files
/code-review --scope staged

# Review specific file or directory
/code-review --scope src/components/
/code-review --scope install.sh

# Focus on specific quality dimension
/code-review --focus security
/code-review --focus performance
/code-review --focus quality

# Combined scope and focus
/code-review --scope src/api/ --focus security
/code-review --scope changed --focus performance
```

## Review Scopes

### Scope Options

- **all** - Review entire project codebase (default if no scope specified)
- **changed** - Review uncommitted changes (both staged and unstaged)
- **staged** - Review only staged changes (ready for commit)
- **path** - Review specific file or directory path (e.g., `src/components/`, `install.sh`)

### Focus Areas

- **security** - Security vulnerabilities, injection risks, auth issues, secrets exposure
- **performance** - Performance bottlenecks, N+1 queries, inefficient algorithms, memory leaks
- **quality** - Code complexity, duplication, readability, maintainability, documentation
- **all** - Comprehensive review across all dimensions (default)

## Workflow

### Phase 1: Initialize Review Context

#### 1.1 Parse Arguments & Determine Scope

**Parse command arguments**:

```bash
# Extract scope and focus from args
SCOPE="{{args.scope | default: 'all'}}"
FOCUS="{{args.focus | default: 'all'}}"
```

**Display review plan**:

```text
Code Review Initialized
========================
Scope: {{scope}}
Focus: {{focus}}
Date: {{YYYY-MM-DD}}
Reviewer: code-reviewer agent

Initializing review...
```

#### 1.2 Identify Files to Review

**Based on scope, determine file list**:

#### Scope: all

```bash
# Get all tracked files, exclude common non-code files
git -C ${PROJECT_ROOT} ls-files | grep -v -E '\.(md|txt|json|yaml|yml|lock|sum|mod)$' | grep -v -E '^(\.github|\.vscode|node_modules|vendor|dist|build)/'
```

#### Scope: changed

```bash
# Get uncommitted changes (staged + unstaged)
git -C ${PROJECT_ROOT} diff HEAD --name-only --diff-filter=ACMR
```

#### Scope: staged

```bash
# Get staged changes only
git -C ${PROJECT_ROOT} diff --cached --name-only --diff-filter=ACMR
```

#### Scope: path

```bash
# If path is directory, get all files recursively
if [ -d "${PROJECT_ROOT}/{{scope}}" ]; then
  find "${PROJECT_ROOT}/{{scope}}" -type f | grep -v -E '\.(md|txt|json|yaml|yml|lock|sum|mod)$'
else
  # Single file
  echo "${PROJECT_ROOT}/{{scope}}"
fi
```

**Store file list**:

```text
FILES_TO_REVIEW: {{file_list}}
FILE_COUNT: {{count}}
```

**If no files to review**:

- Display: "No files to review. Scope '{{scope}}' resulted in empty file list."
- Exit command

#### 1.3 Detect Languages & Frameworks

**Analyze file extensions and project structure**:

```bash
# Detect languages from file extensions
LANGUAGES=$(echo "$FILES_TO_REVIEW" | sed 's/.*\.//' | sort -u)

# Detect frameworks from project files
test -f package.json && HAS_NODE=true
test -f go.mod && HAS_GO=true
test -f requirements.txt && HAS_PYTHON=true
test -f Gemfile && HAS_RUBY=true
test -f composer.json && HAS_PHP=true
```

**Store detected technologies**:

```text
DETECTED_LANGUAGES: {{languages}}
DETECTED_FRAMEWORKS: {{frameworks}}
```

**Output**:

```text
Detected Technologies:
  Languages: {{languages}}
  Frameworks: {{frameworks}}
  Files to Review: {{count}}
```

#### 1.4 Create Review Directory

```bash
# Create review output directory
REVIEW_DIR=".code-reviews/$(date +%Y-%m-%d-%H%M%S)"
mkdir -p "$REVIEW_DIR/findings"
mkdir -p "$REVIEW_DIR/reports"
mkdir -p "$REVIEW_DIR/fixes"
```

### Phase 2: Invoke Code Reviewer Agent

**Delegate review to specialized code-reviewer agent**:

```text
Invoking code-reviewer agent for comprehensive analysis...

Review Scope: {{scope}}
Review Focus: {{focus}}
Files: {{file_count}}
Technologies: {{languages}} / {{frameworks}}

The code-reviewer agent will analyze code for:
- Security vulnerabilities and risks
- Performance bottlenecks and inefficiencies
- Code quality and maintainability issues
- Best practices adherence for each language/framework

Please wait while the review is conducted...
```

**Agent Context to Pass**:

```markdown
You are the **code-reviewer** agent, invoked to perform comprehensive code quality review.

## Review Context

**Scope**: {{scope}}
**Focus**: {{focus}}
**Files to Review**: {{file_count}} files
**Technologies**: {{languages}} / {{frameworks}}
**Output Directory**: {{review_dir}}

## Files to Review

{{#each files}}
- {{path}}
{{/each}}

## Review Dimensions

{{#if focus == "security" or focus == "all"}}
### Security Review

Analyze for:

**Injection Vulnerabilities**:
- SQL injection risks (unsanitized queries, string concatenation)
- Cross-Site Scripting (XSS) - unescaped output, innerHTML usage
- Command injection - unsanitized shell commands, exec usage
- Path traversal - unvalidated file paths, directory access
- LDAP/XML/NoSQL injection vectors

**Authentication & Authorization**:
- Missing authentication checks on sensitive endpoints
- Broken access control (horizontal/vertical privilege escalation)
- Insecure session management (weak tokens, no expiration)
- Missing CSRF protection
- Hardcoded credentials or API keys

**Data Protection**:
- Sensitive data in logs (passwords, tokens, PII)
- Unencrypted sensitive data storage
- Insecure cryptography (weak algorithms, hardcoded keys)
- Missing input validation/sanitization
- Information disclosure in error messages

**API Security**:
- Missing rate limiting
- Insecure deserialization
- Missing authentication on API endpoints
- Overly permissive CORS policies
- API keys or secrets in code

**Dependencies**:
- Known vulnerable dependencies (check versions)
- Unused dependencies increasing attack surface
- Missing dependency pinning (version drift risks)
{{/if}}

{{#if focus == "performance" or focus == "all"}}
### Performance Review

Analyze for:

**Database Performance**:
- N+1 query problems (missing eager loading)
- Missing database indexes on frequently queried fields
- Inefficient queries (SELECT *, unnecessary JOINs)
- Missing query result caching
- Database connection pooling issues

**Algorithm Efficiency**:
- Inefficient algorithms (O(n^2) or worse when O(n log n) possible)
- Unnecessary nested loops
- Redundant computations in loops
- Missing memoization for expensive operations
- Inefficient string concatenation in loops

**Resource Management**:
- Memory leaks (unclosed connections, event listeners)
- Large object creation in loops
- Inefficient data structures for use case
- Missing pagination for large datasets
- Unbounded collection growth

**Network Performance**:
- Missing HTTP caching headers
- Synchronous blocking operations
- Missing request batching/debouncing
- Large payload sizes (missing compression)
- Excessive API calls (chattiness)

**Frontend Performance**:
- Large bundle sizes (missing code splitting)
- Blocking render operations
- Unnecessary re-renders (React, Vue)
- Missing lazy loading for images/components
- Inefficient DOM manipulation
{{/if}}

{{#if focus == "quality" or focus == "all"}}
### Code Quality Review

Analyze for:

**Code Complexity**:
- High cyclomatic complexity (> 10)
- Deep nesting (> 4 levels)
- Long functions (> 50 lines)
- Long parameter lists (> 5 parameters)
- God objects/classes (too many responsibilities)

**Code Duplication**:
- Duplicated code blocks (> 5 lines repeated)
- Similar logic that could be abstracted
- Copy-pasted functions with minor variations

**Readability & Maintainability**:
- Poor naming (single-letter variables, unclear names)
- Missing or misleading comments
- Inconsistent code style
- Magic numbers without constants
- Complex boolean expressions (could be extracted)

**Error Handling**:
- Missing error handling (try/catch, error returns)
- Swallowed exceptions (empty catch blocks)
- Generic error messages
- Missing input validation
- Unchecked return values

**Testing & Documentation**:
- Missing unit tests for critical logic
- Low test coverage areas
- Missing function/class documentation
- Unclear API contracts
- Missing examples for complex functions

**Best Practices**:
- Violation of SOLID principles
- Tight coupling between modules
- Missing dependency injection
- Mutable global state
- Not following language idioms
{{/if}}

## Language-Specific Checks

**Shell Scripts** (.sh, .bash):
- Use of `set -euo pipefail` for error handling
- Quoting of variables (prevent word splitting)
- Use of shellcheck recommendations
- Readonly for constants
- Input validation

**JavaScript/TypeScript** (.js, .ts, .tsx):
- Use of strict mode
- Proper async/await error handling
- Avoiding var (use const/let)
- Type safety (TypeScript)
- Proper React hooks usage

**Python** (.py):
- PEP 8 compliance
- Type hints usage
- Proper exception handling
- Context managers for resources
- List comprehension over loops where appropriate

**Go** (.go):
- Proper error handling (check all errors)
- Context usage for cancellation
- Proper defer usage
- Race condition risks (concurrent access)
- Proper interface usage

**Java** (.java):
- Exception handling best practices
- Resource management (try-with-resources)
- Proper null handling
- Thread safety
- Proper generics usage

**Ruby** (.rb):
- Ruby idioms (each vs for, symbols vs strings)
- Proper exception handling
- Avoid mutable class variables
- Proper block usage
- ActiveRecord N+1 queries

## Output Format

For each finding, provide:

```yaml
finding_id: FINDING-{{YYYY-MM-DD}}-{{nnn}}
title: Concise title describing the issue
severity: Critical|High|Medium|Low|Info
category: Security|Performance|Quality
subcategory: SQL Injection|N+1 Query|Code Duplication|etc.
file: path/to/file.ext
line_start: {{line_number}}
line_end: {{line_number}}
language: {{language}}

description: |
  Clear description of the issue and why it's a problem.

risk: |
  What could happen if this issue is not addressed.
  Include potential impact and exploitability.

evidence: |
  {{code_snippet_showing_issue}}

recommendation: |
  Specific steps to fix the issue.

fixed_code: |
  {{corrected_code_example}}

references:
  - https://owasp.org/...
  - https://cwe.mitre.org/...
```

**Severity Guidelines**:

- **Critical**: Exploitable security vulnerability, data loss risk, severe performance degradation
- **High**: Significant security risk, major performance issue, serious maintainability problem
- **Medium**: Moderate security concern, noticeable performance impact, code quality issue
- **Low**: Minor security improvement, small performance optimization, style/convention issue
- **Info**: Informational finding, best practice suggestion, no immediate action required

## Your Mission

1. Read and analyze each file in the review scope
2. Identify issues based on focus area (security, performance, quality, or all)
3. Generate detailed findings with severity ratings
4. Provide actionable fixes with code examples
5. Create summary report with statistics
6. Save findings to `{{review_dir}}/findings/`

**IMPORTANT**:

- Be thorough but avoid false positives
- Provide specific, actionable recommendations
- Include code examples for fixes
- Consider the technology stack and framework best practices
- Prioritize findings by severity and impact
- Focus on real issues, not stylistic preferences (unless focus=quality)

``` <!-- markdownlint-disable-line MD040 -->

### Phase 3: Process Review Results

**After code-reviewer agent completes**:

### 3.1 Collect Findings

**Load findings from review directory**:

```bash
# Count findings by severity
CRITICAL_COUNT=$(grep -r "severity: Critical" "$REVIEW_DIR/findings/" | wc -l)
HIGH_COUNT=$(grep -r "severity: High" "$REVIEW_DIR/findings/" | wc -l)
MEDIUM_COUNT=$(grep -r "severity: Medium" "$REVIEW_DIR/findings/" | wc -l)
LOW_COUNT=$(grep -r "severity: Low" "$REVIEW_DIR/findings/" | wc -l)
INFO_COUNT=$(grep -r "severity: Info" "$REVIEW_DIR/findings/" | wc -l)

TOTAL_FINDINGS=$((CRITICAL_COUNT + HIGH_COUNT + MEDIUM_COUNT + LOW_COUNT + INFO_COUNT))
```

### 3.2 Generate Summary Report

**Create executive summary**:

```markdown
---
title: "Code Review Report"
date: "{{YYYY-MM-DD}}"
scope: "{{scope}}"
focus: "{{focus}}"
reviewer: "code-reviewer agent"
files_reviewed: {{file_count}}
---

# Code Review Report

**Date**: {{YYYY-MM-DD}}
**Scope**: {{scope}}
**Focus**: {{focus}}
**Files Reviewed**: {{file_count}}
**Technologies**: {{languages}} / {{frameworks}}

---

## Executive Summary

### Overall Assessment

{{#if critical_count > 0}}
⚠️ **CRITICAL ISSUES FOUND** - Immediate action required on {{critical_count}} critical findings.
{{else if high_count > 5}}
⚠️ **HIGH PRIORITY ISSUES** - {{high_count}} high-severity issues require prompt attention.
{{else if total_findings == 0}}
✅ **NO ISSUES FOUND** - Code review passed with no findings.
{{else}}
ℹ️ **MINOR ISSUES FOUND** - {{total_findings}} findings identified, primarily low/medium severity.
{{/if}}

### Findings Summary

| Severity | Count | Percentage |
|----------|-------|------------|
| Critical | {{critical_count}} | {{critical_pct}}% |
| High     | {{high_count}} | {{high_pct}}% |
| Medium   | {{medium_count}} | {{medium_pct}}% |
| Low      | {{low_count}} | {{low_pct}}% |
| Info     | {{info_count}} | {{info_pct}}% |
| **Total** | **{{total_findings}}** | **100%** |

### Findings by Category

{{#if focus == "all" or focus == "security"}}
**Security**: {{security_count}} findings
{{/if}}
{{#if focus == "all" or focus == "performance"}}
**Performance**: {{performance_count}} findings
{{/if}}
{{#if focus == "all" or focus == "quality"}}
**Quality**: {{quality_count}} findings
{{/if}}

### Top 5 Critical Issues

{{#each top_critical_issues}}
{{@index + 1}}. **{{title}}** ({{file}}:{{line}})
   - Severity: {{severity}}
   - Category: {{category}}
   - Risk: {{risk_summary}}
{{/each}}

---

## Detailed Findings

{{#each findings}}
### {{finding_id}}: {{title}}

**File**: `{{file}}:{{line_start}}-{{line_end}}`
**Severity**: {{severity}}
**Category**: {{category}} - {{subcategory}}

**Description**:
{{description}}

**Risk**:
{{risk}}

**Evidence**:

```{{language}}
{{evidence}}
```

**Recommendation**:
{{recommendation}}

**Fixed Code**:

```{{language}}
{{fixed_code}}
```

**References**:

{{#each references}}

- {{this}}

{{/each}}

---
{{/each}}

## Remediation Roadmap

### Immediate Priority (Critical)

{{#if critical_count > 0}}

{{#each critical_findings}}

- [ ] {{title}} ({{file}}:{{line}})
  - **Action**: {{recommendation_summary}}
  - **Effort**: {{estimated_effort}}

{{/each}}

{{else}}
No critical issues identified.
{{/if}}

### Short-Term Priority (High)

{{#if high_count > 0}}

{{#each high_findings}}

- [ ] {{title}} ({{file}}:{{line}})
  - **Action**: {{recommendation_summary}}
  - **Effort**: {{estimated_effort}}

{{/each}}

{{else}}
No high-priority issues identified.
{{/if}}

### Medium-Term Priority (Medium)

{{#if medium_count > 0}}
List available in: `{{review_dir}}/findings/medium-severity.md`
{{else}}
No medium-priority issues identified.
{{/if}}

### Long-Term Improvements (Low + Info)

{{#if low_count + info_count > 0}}
List available in: `{{review_dir}}/findings/low-severity.md`
{{else}}
No low-priority issues identified.
{{/if}}

---

## Statistics

**Files Reviewed**: {{file_count}}
**Lines of Code Reviewed**: {{loc_count}}
**Languages**: {{languages}}
**Frameworks**: {{frameworks}}

**Review Timing**:

- Started: {{start_time}}
- Completed: {{end_time}}
- Duration: {{duration}}

---

## Next Steps

1. **Review Critical Issues**: Address all critical findings immediately
2. **Prioritize High Issues**: Create tickets for high-severity findings
3. **Plan Medium Issues**: Schedule remediation in upcoming sprints
4. **Track Progress**: Update this report as issues are resolved
5. **Follow-Up Review**: Schedule follow-up review after remediation

---

**Review Artifacts**:

- Findings: `{{review_dir}}/findings/`
- Reports: `{{review_dir}}/reports/`
- Fixes: `{{review_dir}}/fixes/`

**Generated by**: code-reviewer agent
**Report Date**: {{YYYY-MM-DD HH:MM:SS}}

``` <!-- markdownlint-disable-line MD040 -->

**Save report to**: `{{review_dir}}/reports/summary.md`

### Phase 4: Display Review Summary

**Present results to user**:

```text
╔════════════════════════════════════════════════════════════════════════════╗
║                       ✓ CODE REVIEW COMPLETE                               ║
╚════════════════════════════════════════════════════════════════════════════╝

Review Date: {{YYYY-MM-DD}}
Scope: {{scope}}
Focus: {{focus}}
Files Reviewed: {{file_count}}

FINDINGS SUMMARY:
───────────────────────────────────────────────────────────────────────────

  Critical: {{critical_count}}{{#if critical_count > 0}} ⚠️ IMMEDIATE ACTION REQUIRED{{/if}}
  High: {{high_count}}
  Medium: {{medium_count}}
  Low: {{low_count}}
  Info: {{info_count}}

  Total Findings: {{total_findings}}

{{#if critical_count > 0}}
TOP CRITICAL ISSUES:
───────────────────────────────────────────────────────────────────────────

{{#each top_critical_issues}}
  {{@index + 1}}. {{title}}
     File: {{file}}:{{line}}
     Risk: {{risk_summary}}
{{/each}}
{{/if}}

CATEGORY BREAKDOWN:
───────────────────────────────────────────────────────────────────────────

  Security Issues: {{security_count}}
  Performance Issues: {{performance_count}}
  Quality Issues: {{quality_count}}

REVIEW ARTIFACTS:
───────────────────────────────────────────────────────────────────────────

  Summary Report: {{review_dir}}/reports/summary.md
  Detailed Findings: {{review_dir}}/findings/
  Fix Examples: {{review_dir}}/fixes/

╔════════════════════════════════════════════════════════════════════════════╗
║ NEXT STEPS                                                                 ║
╠════════════════════════════════════════════════════════════════════════════╣
║                                                                            ║
║  1. Review summary report: cat {{review_dir}}/reports/summary.md           ║
║  2. Address critical findings immediately                                  ║
║  3. Create tickets for high-priority issues                                ║
║  4. Plan remediation timeline                                              ║
║                                                                            ║
╚════════════════════════════════════════════════════════════════════════════╝
```

## Examples

### Example 1: Full Project Security Review

```bash
/code-review --focus security

# Output:
Code Review Initialized
========================
Scope: all
Focus: security
Reviewer: code-reviewer agent

Detected Technologies:
  Languages: sh, js, md, yaml
  Files to Review: 47

Invoking code-reviewer agent...

✓ Code Review Complete!
Findings Summary:
  Critical: 2 ⚠️ IMMEDIATE ACTION REQUIRED
  High: 5
  Medium: 12
  Low: 8
  Info: 3

Top Critical Issues:
1. Hardcoded API Key in Configuration File
   File: src/config/api.js:12
   Risk: API key exposure could lead to unauthorized access

2. SQL Injection Vulnerability in User Query
   File: src/db/users.js:45
   Risk: Attacker could execute arbitrary SQL commands

Reports: .code-reviews/2025-10-09-143022/reports/summary.md
```

### Example 2: Performance Review of Changed Files

```bash
/code-review --scope changed --focus performance

# Output:
Code Review Initialized
========================
Scope: changed
Focus: performance
Files to Review: 3

Detected Technologies:
  Languages: js, ts
  Frameworks: React, Express

Invoking code-reviewer agent...

✓ Code Review Complete!
Findings Summary:
  Critical: 0
  High: 1
  Medium: 3
  Low: 2
  Info: 1

Performance Issues Found:
1. N+1 Query in getUserOrders (HIGH)
   File: src/api/orders.js:78
   Fix: Use eager loading with JOIN

2. Missing Memoization in ProductList (MEDIUM)
   File: src/components/ProductList.tsx:34
   Fix: Use React.useMemo for expensive filter operation

Reports: .code-reviews/2025-10-09-143520/reports/summary.md
```

### Example 3: Quality Review of Specific Component

```bash
/code-review --scope src/components/Dashboard/ --focus quality

# Output:
Code Review Initialized
========================
Scope: src/components/Dashboard/
Focus: quality
Files to Review: 8

Detected Technologies:
  Languages: tsx, ts
  Frameworks: React, TypeScript

Invoking code-reviewer agent...

✓ Code Review Complete!
Findings Summary:
  Critical: 0
  High: 0
  Medium: 6
  Low: 15
  Info: 8

Quality Issues Found:
- High Cyclomatic Complexity (6 instances)
- Code Duplication (3 instances)
- Missing Documentation (8 instances)
- Long Functions (4 instances)
- Magic Numbers (5 instances)

Reports: .code-reviews/2025-10-09-144012/reports/summary.md
```

### Example 4: Quick Review of Staged Changes

```bash
# Before committing changes
/code-review --scope staged

# Output:
Code Review Initialized
========================
Scope: staged
Focus: all
Files to Review: 2

Invoking code-reviewer agent...

✓ Code Review Complete!
Findings Summary:
  Critical: 0
  High: 0
  Medium: 1
  Low: 2
  Info: 0

Medium Issues:
1. Missing Error Handling in Async Function
   File: src/utils/api.ts:23
   Fix: Add try/catch block or .catch() handler

✅ No critical issues blocking commit.

Reports: .code-reviews/2025-10-09-144530/reports/summary.md
```

## Agent Requirements

### code-reviewer Agent

**Expected Capabilities**:

- Multi-language code analysis (Shell, JavaScript, TypeScript, Python, Go, Java, Ruby, PHP)
- Security vulnerability detection (OWASP Top 10, CWE)
- Performance analysis (algorithmic complexity, database queries, resource usage)
- Code quality assessment (complexity metrics, duplication detection, maintainability)
- Framework-specific best practices (React, Express, Rails, Django, Spring, etc.)
- Severity rating based on impact and exploitability
- Actionable recommendations with code examples

**Knowledge Base**: Should include:

- OWASP security standards
- Language-specific best practices
- Framework-specific patterns
- Performance optimization techniques
- Code quality metrics and thresholds
- Common vulnerability patterns (CWE/CVE)

**If code-reviewer agent doesn't exist**:

```text
⚠️ Agent Not Found: code-reviewer

The code-reviewer agent is required for comprehensive code review.

OPTIONS:

[1] Create code-reviewer agent now
    → Run /create-agent to create the code-reviewer agent

[2] Use basic built-in analysis (limited capabilities)
    → Perform basic review without specialized agent

[3] Abort review
    → Exit without performing review

Choice [1-3]: _
```

## Error Handling

**No files to review**:

- Display: "No files found for scope '{{scope}}'. Nothing to review."
- Exit command

**Invalid scope path**:

- Display: "Invalid path: '{{scope}}'. Path does not exist."
- Suggest: "Use 'all', 'changed', 'staged', or a valid file/directory path."
- Exit command

**Agent invocation fails**:

- Display error details
- Offer fallback to basic analysis
- Save partial results if any findings generated

**Review directory creation fails**:

- Display permission error
- Suggest alternative output location
- Exit command

## Success Criteria

- File list successfully identified based on scope
- code-reviewer agent invoked successfully
- Findings generated with severity ratings and recommendations
- Summary report created with statistics
- Review artifacts saved to `.code-reviews/` directory
- User presented with actionable next steps

## Configuration

**Optional Configuration File**: `.code-review-config.json`

```json
{
  "severity_thresholds": {
    "max_critical": 0,
    "max_high": 5,
    "max_medium": 20
  },
  "ignored_findings": [
    "FINDING-2025-10-01-042"
  ],
  "excluded_paths": [
    "vendor/",
    "node_modules/",
    "dist/",
    ".git/"
  ],
  "custom_rules": {
    "max_function_length": 50,
    "max_cyclomatic_complexity": 10,
    "max_nesting_depth": 4
  }
}
```

## Integration with Workflow

### Position in Workflow

```text
[code changes] → /code-review → [fix issues] → git commit → /open-pr
```

### Common Workflows

**Pre-Commit Review**:

```bash
# Review staged changes before committing
/code-review --scope staged
# Fix critical/high issues
git add .
git commit -m "fix: address code review findings"
```

**Pre-PR Review**:

```bash
# Review all changes in branch before creating PR
/code-review --scope changed --focus all
# Address findings
/open-pr
```

**Security Audit**:

```bash
# Full security review before release
/code-review --scope all --focus security
# Remediate critical/high security issues
```

**Performance Optimization**:

```bash
# Identify performance bottlenecks
/code-review --scope src/ --focus performance
# Implement optimizations
```

## Related Commands

- `/security-audit` - Comprehensive infrastructure security audit (different from code review)
- `/implement` - Implement fixes for code review findings
- `/open-pr` - Create PR after addressing review findings

## Notes

- **Comprehensive by default**: No focus argument = review all dimensions (security, performance, quality)
- **Language-agnostic**: Adapts to detected languages and frameworks
- **Severity-driven**: Findings prioritized by severity for actionable remediation
- **Code examples**: Every finding includes fixed code example
- **Non-blocking**: Review results inform, don't prevent commits (user decides)
- **Historical tracking**: All reviews saved with timestamps for trend analysis

---

**Design Philosophy**: Provide developers with comprehensive, actionable code quality feedback to catch issues early, improve code health, and maintain high standards across all dimensions of quality (security, performance, maintainability).
