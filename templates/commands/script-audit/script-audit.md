---
name: script-audit
description: Audit shell scripts for Bash 3.2 compatibility, cross-platform support, and best practices
model: sonnet
args:
  scope:
    description: What to audit - "all" (default), or specific script/directory path
    required: false
  check:
    description: Check type - "compatibility", "security", "style", "all" (default)
    required: false
version: 1.0.0
category: analysis
---

# Shell Script Audit Command

Perform comprehensive audits of shell scripts to ensure Bash 3.2 compatibility, cross-platform support (macOS/Linux), security best practices, and consistent code style. This command invokes the **shell-script-specialist** agent to systematically analyze scripts and provide actionable remediation guidance.

## Usage

```bash
# Audit all shell scripts in project
/script-audit

# Audit all scripts with specific check type
/script-audit --check compatibility
/script-audit --check security
/script-audit --check style

# Audit specific script
/script-audit --scope install.sh
/script-audit --scope scripts/validate-templates.sh

# Audit specific directory
/script-audit --scope scripts/
/script-audit --scope lib/installer-common/

# Comprehensive audit (all checks on all scripts)
/script-audit --scope all --check all
```

## Audit Scopes

### Scope Options

- **all** (default) - Audit all shell scripts in the project (`.sh` files + executable scripts with shebang)
- **path/to/script.sh** - Audit specific script file
- **path/to/directory/** - Audit all scripts in directory and subdirectories

### Check Types

- **compatibility** - Bash 3.2 compatibility, no Bash 4+ features
- **security** - Input validation, quote safety, error handling
- **style** - ShellCheck compliance, consistent formatting, best practices
- **all** (default) - Run all check types comprehensively

## Workflow

Execute the following steps systematically to complete the shell script audit.

---

## STEP 1: Initialize Audit Context

### 1.1 Parse Arguments

**Extract command arguments**:

```yaml
SCOPE: {{args.scope | default: "all"}}
CHECK: {{args.check | default: "all"}}
```

**Validate arguments**:

- `scope`: Must be "all", valid file path, or valid directory path
- `check`: Must be one of: "compatibility", "security", "style", "all"

**Error Handling**:

- Invalid scope: Report error and suggest valid options
- Invalid check type: Report error and suggest valid check types

### 1.2 Display Audit Plan

```text
╔════════════════════════════════════════════════════════════════════════════╗
║                      SHELL SCRIPT AUDIT INITIALIZED                        ║
╚════════════════════════════════════════════════════════════════════════════╝

Scope: {{scope}}
Check Type: {{check}}
Date: {{YYYY-MM-DD}}
Auditor: shell-script-specialist agent

Initializing audit...
```

### 1.3 Create Audit Directory

Create working directory for audit artifacts:

```bash
# Create audit directory structure
AUDIT_DIR=".script-audits/$(date +%Y-%m-%d)"
mkdir -p "${AUDIT_DIR}"/{findings,reports,evidence}

echo "Audit directory created: ${AUDIT_DIR}"
```

**Directory Structure**:

- `findings/` - Individual script audit findings
- `reports/` - Summary reports and remediation plans
- `evidence/` - Script snippets, examples, before/after comparisons

---

## STEP 2: Discover Shell Scripts

### 2.1 Find All Shell Scripts

**Determine scope and locate scripts**:

**If scope is "all"**:

```bash
# Find all .sh files
find ${PROJECT_ROOT} -type f -name "*.sh" ! -path "*/.git/*" ! -path "*/node_modules/*" > "${AUDIT_DIR}/scripts-list.txt"

# Find all executable files with shell shebang
find ${PROJECT_ROOT} -type f -executable ! -path "*/.git/*" ! -path "*/node_modules/*" -exec grep -l "^#!/bin/bash\|^#!/bin/sh\|^#!/usr/bin/env bash\|^#!/usr/bin/env sh" {} \; >> "${AUDIT_DIR}/scripts-list.txt"

# Remove duplicates and sort
sort -u "${AUDIT_DIR}/scripts-list.txt" -o "${AUDIT_DIR}/scripts-list.txt"
```

**If scope is specific file**:

```bash
# Validate file exists and is a shell script
if [[ ! -f "${SCOPE}" ]]; then
    echo "Error: File not found: ${SCOPE}"
    exit 1
fi

# Check if it's a shell script
if head -1 "${SCOPE}" | grep -q "^#!/bin/bash\|^#!/bin/sh\|^#!/usr/bin/env bash\|^#!/usr/bin/env sh" || [[ "${SCOPE}" == *.sh ]]; then
    echo "${SCOPE}" > "${AUDIT_DIR}/scripts-list.txt"
else
    echo "Error: ${SCOPE} does not appear to be a shell script"
    exit 1
fi
```

**If scope is directory**:

```bash
# Find all scripts in directory
find "${SCOPE}" -type f \( -name "*.sh" -o -executable \) ! -path "*/.git/*" ! -path "*/node_modules/*" > "${AUDIT_DIR}/scripts-list.txt"

# Filter for shell scripts only
while IFS= read -r file; do
    if head -1 "$file" | grep -q "^#!/bin/bash\|^#!/bin/sh\|^#!/usr/bin/env bash\|^#!/usr/bin/env sh" || [[ "$file" == *.sh ]]; then
        echo "$file"
    fi
done < "${AUDIT_DIR}/scripts-list.txt" > "${AUDIT_DIR}/scripts-list-filtered.txt"

mv "${AUDIT_DIR}/scripts-list-filtered.txt" "${AUDIT_DIR}/scripts-list.txt"
```

### 2.2 Inventory Scripts

**Count and categorize discovered scripts**:

```bash
# Count total scripts
SCRIPT_COUNT=$(wc -l < "${AUDIT_DIR}/scripts-list.txt")

echo "Discovered ${SCRIPT_COUNT} shell scripts for audit"
```

**Output inventory**:

```text
✓ Script discovery complete
  Total scripts found: {{count}}
  Scripts list: {{audit_dir}}/scripts-list.txt
```

---

## STEP 3: Invoke Shell Script Specialist Agent

Delegate the audit to the **shell-script-specialist** agent with comprehensive audit instructions.

### 3.1 Prepare Agent Context

**Agent Invocation**:

```markdown
You are the **shell-script-specialist** agent, invoked to audit shell scripts for compatibility, security, and style issues.

## Audit Context

**Scope**: {{scope}}
**Check Type**: {{check}}
**Scripts to Audit**: {{script_count}} files
**Audit Directory**: {{audit_dir}}

## Scripts List

{{scripts_list_content}}

## Your Mission

Perform comprehensive audit of the listed shell scripts according to the check type specified.

### Audit Criteria by Check Type

#### COMPATIBILITY Checks (Bash 3.2)

Verify scripts are compatible with Bash 3.2 (macOS default until macOS Catalina):

**Bash 4+ Features to Flag**:

- **Associative arrays** (`declare -A`)
- **Case modification** (`${var^^}`, `${var,,}`, `${var~}`, `${var~~}`)
- **Negative substring expansion** (`${var: -1}`)
- **`;;&` and `;&` in case statements**
- **`|&` operator**
- **`**` globstar pattern**
- **`[[` conditional with `=~` BASH_REMATCH without manual extraction**

**Cross-Platform Compatibility**:

- **readlink** - Use `readlink` without `-f` (not available on macOS)
  - Prefer portable alternatives or check platform first
- **stat** - Different syntax on macOS vs GNU/Linux
  - macOS: `stat -f %m`
  - Linux: `stat -c %Y`
- **date** - Different options between BSD (macOS) and GNU
- **sed** - Avoid GNU-specific extensions, use portable syntax
- **grep** - Use basic regex, avoid GNU-specific flags

**Recommended Patterns**:

```bash
# Instead of readlink -f (not on macOS)
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Instead of associative arrays
# Use indexed arrays with delimiter-based parsing or case statements

# Instead of ${var^^} (uppercase)
var_upper="$(echo "$var" | tr '[:lower:]' '[:upper:]')"

# Instead of ${var: -1} (last char)
var_last="${var:${#var}-1:1}"
```

#### SECURITY Checks

Identify security vulnerabilities and unsafe patterns:

**Input Validation**:

- Missing validation of user input
- Unchecked command-line arguments
- No sanitization of external data

**Quote Safety**:

- Unquoted variables (e.g., `$var` instead of `"$var"`)
- Unquoted command substitution
- Word splitting risks

**Error Handling**:

- Missing `set -euo pipefail` at script start
- Commands without error checking
- Missing validation of critical operations

**Path Safety**:

- Unsafe path operations (e.g., `rm -rf $var/` without validation)
- Missing directory existence checks
- Unsafe use of `eval`

**Credential Exposure**:

- Secrets in logs or error messages
- Passwords in command-line arguments
- API keys in environment without protection

**Recommended Patterns**:

```bash
# Strict error handling
set -euo pipefail

# Quote all variables
echo "Value: ${var}"
rm -rf "${dir:?}/subdir"  # :? ensures var is set

# Validate input
if [[ -z "${1:-}" ]]; then
    echo "Error: Missing required argument" >&2
    exit 1
fi

# Check command success
if ! command -v git >/dev/null 2>&1; then
    echo "Error: git not found" >&2
    exit 1
fi
```

#### STYLE Checks

Enforce consistent code style and best practices:

**ShellCheck Compliance**:

- Run ShellCheck on all scripts
- Report all warnings and errors
- Categorize by severity

**Consistent Formatting**:

- Function definitions: `function_name() {` vs `function function_name {`
- Indentation: 2 spaces or 4 spaces (consistent within project)
- Line length: <= 100 characters (recommended)

**Best Practices**:

- Use `readonly` for constants
- Use local variables in functions (`local var=value`)
- Proper use of `[[ ]]` vs `[ ]`
- Use `$()` instead of backticks for command substitution
- Include comprehensive comments for complex logic

**Code Organization**:

- Functions before main code
- Clear separation of concerns
- Descriptive function names
- Proper use of return codes

**Recommended Patterns**:

```bash
#!/usr/bin/env bash
#
# Script description
#
# Usage: script.sh [options]

set -euo pipefail

# Constants
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DEFAULT_TIMEOUT=30

# Functions
function show_usage() {
    cat << EOF
Usage: ${0##*/} [OPTIONS]

OPTIONS:
    -h, --help      Show this help message
    -v, --verbose   Enable verbose output
EOF
}

function main() {
    local verbose=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_usage
                exit 0
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            *)
                echo "Unknown option: $1" >&2
                show_usage >&2
                exit 1
                ;;
        esac
    done

    # Main logic here
}

# Script entry point
main "$@"
```

### For Each Script, Perform

1. **Read script contents**
2. **Run checks appropriate to check type**:
   - If `check=compatibility`: Focus on Bash 3.2 and cross-platform issues
   - If `check=security`: Focus on security vulnerabilities
   - If `check=style`: Focus on ShellCheck and code style
   - If `check=all`: Run all check types

3. **Document findings** in structured format:

```markdown
# Audit Findings: {{script_name}}

**Script Path**: {{path}}
**Audit Date**: {{date}}
**Check Type**: {{check}}

## Summary

- **Critical Issues**: {{critical_count}}
- **High Issues**: {{high_count}}
- **Medium Issues**: {{medium_count}}
- **Low Issues**: {{low_count}}

## Findings

### CRITICAL: {{issue_title}}

**Issue ID**: SCRIPT-{{YYYY-MM-DD}}-{{nnn}}
**Severity**: Critical
**Category**: {{compatibility|security|style}}
**Line**: {{line_number}}

**Description**:
{{what_is_wrong}}

**Current Code**:
```bash
{{problematic_code}}
```

**Risk/Impact**:
{{why_this_matters}}

**Recommended Fix**:

```bash
{{corrected_code}}
```

**Explanation**:
{{why_this_fix_works}}

---

[Repeat for each finding]

---

## ShellCheck Output

```text
{{shellcheck_output}}
```

## Compliance Status

- **Bash 3.2 Compatible**: {{yes|no}}
- **Cross-Platform Safe**: {{yes|no}}
- **Security Hardened**: {{yes|no}}
- **Style Compliant**: {{yes|no}}

## Recommendations

1. {{recommendation_1}}
2. {{recommendation_2}}

```text

Save findings to: `{{audit_dir}}/findings/{{script_name}}.md`

## Additional Requirements

- **Severity Classification**:
  - **Critical**: Script will fail or has serious security vulnerability
  - **High**: Major compatibility issue or security risk
  - **Medium**: Portability concern or style violation
  - **Low**: Minor improvement or optional best practice

- **Prioritization**: Focus on critical and high-severity issues first

- **Code Examples**: Always provide both problematic and corrected code

- **Context**: Explain why each issue matters and how fix resolves it

## Output Requirements

After auditing all scripts, create:

1. **Individual findings**: `{{audit_dir}}/findings/{{script_name}}.md` for each script
2. **Summary report**: `{{audit_dir}}/reports/audit-summary.md`
3. **Remediation plan**: `{{audit_dir}}/reports/remediation-plan.md`
```

### 3.2 Execute Agent Delegation

**Invoke agent**:

- Load shell-script-specialist agent instructions
- Pass audit context and scripts list
- Execute audit for each script
- Capture all findings and reports

**Progress Tracking**:

```text
Auditing scripts...

[1/{{total}}] {{script_name}} - {{status}}
[2/{{total}}] {{script_name}} - {{status}}
...
[{{total}}/{{total}}] {{script_name}} - {{status}}

✓ Audit complete
```

---

## STEP 4: Generate Summary Report

After all scripts audited, create comprehensive summary report.

### 4.1 Aggregate Findings

**Collect statistics across all scripts**:

```bash
# Count findings by severity
CRITICAL_COUNT=$(grep -r "Severity: Critical" "${AUDIT_DIR}/findings/" | wc -l)
HIGH_COUNT=$(grep -r "Severity: High" "${AUDIT_DIR}/findings/" | wc -l)
MEDIUM_COUNT=$(grep -r "Severity: Medium" "${AUDIT_DIR}/findings/" | wc -l)
LOW_COUNT=$(grep -r "Severity: Low" "${AUDIT_DIR}/findings/" | wc -l)

# Count findings by category
COMPAT_COUNT=$(grep -r "Category: compatibility" "${AUDIT_DIR}/findings/" | wc -l)
SECURITY_COUNT=$(grep -r "Category: security" "${AUDIT_DIR}/findings/" | wc -l)
STYLE_COUNT=$(grep -r "Category: style" "${AUDIT_DIR}/findings/" | wc -l)
```

### 4.2 Create Summary Report

Save comprehensive summary to `{{audit_dir}}/reports/audit-summary.md`:

```markdown
---
title: "Shell Script Audit Summary"
date: "{{YYYY-MM-DD}}"
scope: "{{scope}}"
check_type: "{{check}}"
auditor: "shell-script-specialist"
---

# Shell Script Audit Summary

**Audit Date**: {{date}}
**Scope**: {{scope}}
**Check Type**: {{check}}
**Scripts Audited**: {{script_count}}

---

## Executive Summary

### Overall Health Score: {{score}}/100

The audit identified **{{total_issues}}** issues across **{{script_count}}** shell scripts. Key focus areas include {{primary_concerns}}.

### Findings by Severity

| Severity | Count | Percentage |
|----------|-------|------------|
| Critical | {{critical_count}} | {{critical_pct}}% |
| High     | {{high_count}}     | {{high_pct}}% |
| Medium   | {{medium_count}}   | {{medium_pct}}% |
| Low      | {{low_count}}      | {{low_pct}}% |

### Findings by Category

| Category       | Count | Percentage |
|----------------|-------|------------|
| Compatibility  | {{compat_count}}   | {{compat_pct}}% |
| Security       | {{security_count}} | {{security_pct}}% |
| Style          | {{style_count}}    | {{style_pct}}% |

---

## Top Issues Across Scripts

### Most Common Critical Issues

1. **{{issue_title}}** - Found in {{count}} scripts
   - Scripts affected: {{script_list}}
   - Impact: {{impact}}
   - Fix: {{fix_summary}}

### Most Common High Issues

1. **{{issue_title}}** - Found in {{count}} scripts
   - Scripts affected: {{script_list}}
   - Impact: {{impact}}
   - Fix: {{fix_summary}}

---

## Scripts by Health Status

### Clean Scripts (0 issues)

{{#if clean_scripts}}
- {{script_1}}
- {{script_2}}
{{else}}
No scripts are completely clean.
{{/if}}

### Scripts with Critical Issues

{{#each critical_scripts}}
- **{{script_name}}** - {{critical_count}} critical, {{high_count}} high, {{medium_count}} medium, {{low_count}} low
  - Primary issues: {{issue_summary}}
{{/each}}

### Scripts with High Issues

{{#each high_scripts}}
- **{{script_name}}** - {{high_count}} high, {{medium_count}} medium, {{low_count}} low
{{/each}}

---

## Compatibility Summary

### Bash 3.2 Compliance

- **Fully Compatible**: {{compat_count}} scripts
- **Incompatible**: {{incompat_count}} scripts

**Common Bash 4+ Features Found**:

- Associative arrays: {{count}} occurrences
- Case modification operators: {{count}} occurrences
- Negative substring expansion: {{count}} occurrences

### Cross-Platform Compatibility

- **Portable**: {{portable_count}} scripts
- **Platform-Specific Issues**: {{platform_count}} scripts

**Common Cross-Platform Issues**:

- `readlink -f` (not on macOS): {{count}} occurrences
- GNU-specific `stat` syntax: {{count}} occurrences
- GNU `sed` extensions: {{count}} occurrences

---

## Security Summary

### Critical Security Issues

{{#each critical_security_issues}}
- **{{issue_title}}**: Found in {{count}} scripts
  - Risk: {{risk}}
  - Recommendation: {{fix}}
{{/each}}

### Common Security Gaps

- **Unquoted variables**: {{count}} occurrences
- **Missing error handling**: {{count}} scripts without `set -euo pipefail`
- **Unsafe path operations**: {{count}} occurrences
- **Missing input validation**: {{count}} occurrences

---

## Style Summary

### ShellCheck Compliance

- **Clean**: {{clean_count}} scripts
- **Warnings**: {{warning_count}} scripts
- **Errors**: {{error_count}} scripts

**Most Common ShellCheck Issues**:

- SC2086 (unquoted variable): {{count}} occurrences
- SC2155 (declare and assign separately): {{count}} occurrences
- SC2164 (cd without error check): {{count}} occurrences

### Code Style Consistency

- **Consistent indentation**: {{yes|no}}
- **Consistent function syntax**: {{yes|no}}
- **Modern syntax usage**: {{yes|no}} (`$()` vs backticks)

---

## Detailed Findings

See individual script reports:

{{#each scripts}}
- [{{script_name}}](../findings/{{script_name}}.md) - {{issue_count}} issues
{{/each}}

---

## Recommendations

### Immediate Actions (Critical Issues)

1. {{recommendation_1}}
2. {{recommendation_2}}

### Short-Term Improvements (High/Medium Issues)

1. {{recommendation_1}}
2. {{recommendation_2}}

### Long-Term Enhancements (Low Issues + Best Practices)

1. {{recommendation_1}}
2. {{recommendation_2}}

---

**Report Generated**: {{timestamp}}
**Shell Script Specialist**: shell-script-specialist agent
```

---

## STEP 5: Generate Remediation Plan

Create actionable remediation roadmap.

### 5.1 Prioritize Issues

**Group issues by priority**:

- **Immediate** (< 1 week): Critical issues blocking functionality or major security risks
- **Short-Term** (1-4 weeks): High-priority compatibility and security issues
- **Medium-Term** (1-3 months): Medium-priority improvements
- **Long-Term** (> 3 months): Low-priority style improvements

### 5.2 Create Remediation Plan

Save to `{{audit_dir}}/reports/remediation-plan.md`:

```markdown
# Shell Script Remediation Plan

**Generated**: {{date}}
**Scripts Audited**: {{count}}
**Total Issues**: {{count}}

---

## Immediate Priority (< 1 week) - {{critical_count}} Issues

### SCRIPT-{{date}}-001: {{issue_title}}

**Scripts Affected**: {{script_list}}
**Severity**: Critical
**Category**: {{category}}

**Issue**:
{{description}}

**Remediation**:
```bash
{{fix_code}}
```

**Effort**: {{hours}} hours
**Owner**: {{suggested_owner}}

---

[Repeat for each immediate priority issue]

---

## Short-Term Priority (1-4 weeks) - {{high_count}} Issues

### SCRIPT-{{date}}-nnn: {{issue_title}}

**Scripts Affected**: {{script_list}}
**Severity**: High
**Category**: {{category}}

**Issue**:
{{description}}

**Remediation**:
{{fix_summary}}

**Effort**: {{hours}} hours
**Owner**: {{suggested_owner}}

---

## Medium-Term Priority (1-3 months) - {{medium_count}} Issues

### Cross-Script Improvements

**Goal**: Improve overall code quality and consistency

**Tasks**:

1. Standardize error handling across all scripts
2. Ensure consistent code style (indentation, function syntax)
3. Add comprehensive comments and documentation
4. Implement input validation patterns

**Effort**: {{hours}} hours

---

## Long-Term Priority (> 3 months) - {{low_count}} Issues

### Best Practices Adoption

**Goal**: Achieve 100% ShellCheck compliance and modern shell scripting practices

**Tasks**:

1. Refactor all scripts to use modern syntax
2. Create shared library for common functions
3. Implement comprehensive testing
4. Establish code review process

**Effort**: {{hours}} hours

---

## Summary

**Total Estimated Effort**: {{total_hours}} hours

**Recommended Approach**:

1. Address all critical issues immediately ({{critical_hours}} hours)
2. Tackle high-priority issues in next sprint ({{high_hours}} hours)
3. Plan medium-term improvements over next quarter ({{medium_hours}} hours)
4. Incorporate long-term enhancements into ongoing development

---

**Remediation Roadmap**: Generated by shell-script-specialist agent

```text

---

## STEP 6: Display Audit Results

Present audit results to user with actionable summary.

```text
╔════════════════════════════════════════════════════════════════════════════╗
║                    ✓ SHELL SCRIPT AUDIT COMPLETE                           ║
╚════════════════════════════════════════════════════════════════════════════╝

Audit Date: {{date}}
Scope: {{scope}}
Check Type: {{check}}
Scripts Audited: {{count}}

Overall Health Score: {{score}}/100

FINDINGS SUMMARY:
───────────────────────────────────────────────────────────────────────────

  By Severity:
  • Critical: {{critical_count}} (immediate action required)
  • High: {{high_count}} (short-term)
  • Medium: {{medium_count}} (medium-term)
  • Low: {{low_count}} (long-term)

  By Category:
  • Compatibility: {{compat_count}} issues
  • Security: {{security_count}} issues
  • Style: {{style_count}} issues

TOP PRIORITY ISSUES:
───────────────────────────────────────────────────────────────────────────

  1. {{issue_1_title}} (Critical) - {{script_count}} scripts affected
  2. {{issue_2_title}} (Critical) - {{script_count}} scripts affected
  3. {{issue_3_title}} (High) - {{script_count}} scripts affected

COMPATIBILITY STATUS:
───────────────────────────────────────────────────────────────────────────

  Bash 3.2 Compatible: {{compat_count}}/{{total_count}} scripts
  Cross-Platform Safe: {{portable_count}}/{{total_count}} scripts

SECURITY STATUS:
───────────────────────────────────────────────────────────────────────────

  Scripts with Critical Security Issues: {{count}}
  Common Gaps:
  • Unquoted variables: {{count}} occurrences
  • Missing error handling: {{count}} scripts
  • Unsafe path operations: {{count}} occurrences

REPORTS GENERATED:
───────────────────────────────────────────────────────────────────────────

  ✓ Audit Summary: {{audit_dir}}/reports/audit-summary.md
  ✓ Remediation Plan: {{audit_dir}}/reports/remediation-plan.md
  ✓ Individual Findings: {{audit_dir}}/findings/ ({{count}} files)

NEXT STEPS:
───────────────────────────────────────────────────────────────────────────

  1. Review audit summary for overview
  2. Address critical issues immediately ({{critical_count}} issues)
  3. Plan remediation sprints for high-priority issues
  4. Integrate remediation plan into project backlog

ESTIMATED REMEDIATION EFFORT:
───────────────────────────────────────────────────────────────────────────

  Immediate (< 1 week): {{critical_hours}} hours
  Short-Term (1-4 weeks): {{high_hours}} hours
  Medium-Term (1-3 months): {{medium_hours}} hours
  Long-Term (> 3 months): {{low_hours}} hours

  Total Estimated Effort: {{total_hours}} hours

╔════════════════════════════════════════════════════════════════════════════╗
║ Audit artifacts saved to: {{audit_dir}}                                   ║
╚════════════════════════════════════════════════════════════════════════════╝
```

---

## Examples

### Example 1: Audit All Scripts

```bash
/script-audit

# Output:
╔════════════════════════════════════════════════════════════════════════════╗
║                      SHELL SCRIPT AUDIT INITIALIZED                        ║
╚════════════════════════════════════════════════════════════════════════════╝

Scope: all
Check Type: all
Date: 2025-10-09
Auditor: shell-script-specialist agent

Initializing audit...

✓ Script discovery complete
  Total scripts found: 12
  Scripts list: .script-audits/2025-10-09/scripts-list.txt

Auditing scripts...

[1/12] install.sh - ✓ Complete (3 issues)
[2/12] scripts/validate-templates.sh - ✓ Complete (1 issue)
[3/12] lib/installer-common/utils.sh - ✓ Complete (5 issues)
...

╔════════════════════════════════════════════════════════════════════════════╗
║                    ✓ SHELL SCRIPT AUDIT COMPLETE                           ║
╚════════════════════════════════════════════════════════════════════════════╝

Scripts Audited: 12
Overall Health Score: 72/100

FINDINGS SUMMARY:
  • Critical: 2
  • High: 5
  • Medium: 8
  • Low: 3

TOP PRIORITY ISSUES:
  1. Unquoted variables in install.sh (Critical)
  2. Missing set -euo pipefail in 3 scripts (Critical)
  3. readlink -f not portable (High) - 5 scripts affected

Reports: .script-audits/2025-10-09/reports/
```

### Example 2: Compatibility Check Only

```bash
/script-audit --check compatibility

# Output:
Scope: all
Check Type: compatibility

Auditing for Bash 3.2 and cross-platform compatibility...

✓ Audit complete

COMPATIBILITY FINDINGS:
  • Bash 4+ features found: 3 scripts
    - Associative arrays: 2 occurrences
    - Case modification: 1 occurrence
  • Cross-platform issues: 5 scripts
    - readlink -f: 5 occurrences
    - GNU stat syntax: 2 occurrences

Scripts with compatibility issues:
  • lib/installer-common/utils.sh - Bash 4+ associative array
  • install.sh - readlink -f (not on macOS)
  • scripts/validate-templates.sh - GNU stat syntax

Recommendations:
  1. Replace associative arrays with indexed arrays or case statements
  2. Use portable readlink alternative
  3. Add platform detection for stat command
```

### Example 3: Security Audit of Specific Script

```bash
/script-audit --scope install.sh --check security

# Output:
Scope: install.sh
Check Type: security

Auditing install.sh for security issues...

✓ Audit complete

SECURITY FINDINGS (install.sh):

  Critical Issues: 1
  • Unquoted variable in rm command (line 45)
    Risk: Could delete unintended files if variable is empty
    Fix: Use ${var:?} to ensure variable is set

  High Issues: 2
  • Missing input validation for user-provided path (line 30)
  • No error handling - missing set -euo pipefail (line 1)

  Recommendations:
  1. Add set -euo pipefail at script start
  2. Validate all user input before use
  3. Quote all variable expansions
  4. Use ${var:?} for critical path operations

Detailed findings: .script-audits/2025-10-09/findings/install.sh.md
```

---

## Configuration

### Audit Severity Thresholds

Default severity classification:

```yaml
severity_thresholds:
  critical:
    - Script will fail to execute
    - Serious security vulnerability (data loss, unauthorized access)
    - Bash 4+ feature that breaks Bash 3.2 compatibility
  high:
    - Major cross-platform incompatibility
    - Security risk (unquoted variables in dangerous contexts)
    - Missing critical error handling
  medium:
    - Portability concerns (platform-specific commands)
    - Style violations caught by ShellCheck
    - Missing best practices
  low:
    - Minor style improvements
    - Optional optimizations
    - Code readability enhancements
```

---

## Error Handling

- **shell-script-specialist agent not found**: Display error, provide agent creation instructions
- **No scripts found**: Display warning, verify scope is correct
- **Invalid scope**: Show error with valid scope options
- **Invalid check type**: Show error with valid check types
- **Script read errors**: Skip script, log error, continue with remaining scripts
- **ShellCheck not installed**: Warn user, skip ShellCheck analysis, continue with other checks

---

## Success Criteria

- All scripts in scope discovered and inventoried
- Audit checks completed for each script
- Findings documented with severity, category, and recommended fixes
- Summary report generated with aggregate statistics
- Remediation plan created with prioritized action items
- All audit artifacts saved to `.script-audits/{{date}}/`

---

## Related Commands

- `/create-agent shell-script-specialist` - Create shell-script-specialist agent if missing
- `/implement` - Implement remediation tasks from audit findings
- `/security-audit` - Broader security audit including infrastructure

---

## Integration with Development Workflow

### Pre-Commit Integration

Run audit before committing shell script changes:

```bash
# Add to pre-commit hook
/script-audit --scope scripts/changed-file.sh --check all
```

### CI/CD Integration

Include audit in continuous integration pipeline:

```bash
# Add to CI workflow
/script-audit --check all
# Fail build if critical or high issues found
```

### Periodic Audits

Schedule regular audits to maintain code quality:

```bash
# Weekly comprehensive audit
/script-audit --check all

# Monthly compatibility review
/script-audit --check compatibility
```

---

## Notes

- **Bash 3.2 is default on macOS** until macOS Catalina - critical for cross-platform scripts
- **ShellCheck is recommended** - install via `brew install shellcheck` (macOS) or package manager
- **Portable scripting is hard** - use audit to catch platform-specific issues early
- **Security first** - always address critical security issues before compatibility/style
- **Incremental improvement** - use audit to gradually improve script quality over time

---

**Design Philosophy**: Ensure shell scripts are robust, portable, secure, and maintainable through systematic auditing and actionable remediation guidance.
