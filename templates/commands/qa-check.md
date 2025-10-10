---
name: qa-check
description: Run comprehensive QA checks for linting, testing, and cross-platform compatibility
model: sonnet
args:
  scope:
    description: "What to check: 'all', 'lint', 'test', 'compatibility' (default: all)"
    required: false
    type: string
  platform:
    description: "Platform to validate: 'macos', 'linux', 'all' (default: all)"
    required: false
    type: string
---

# QA Check Command

Runs comprehensive quality assurance checks including linting, testing, and cross-platform compatibility validation. This command invokes the `qa-engineer` agent to perform systematic quality verification.

## Command Arguments

**Args Received**: `{{args}}`

### Argument Processing

```yaml
scope: {{args.scope | default: 'all'}}
  # Options: 'all', 'lint', 'test', 'compatibility'
  # Controls which types of checks to run

platform: {{args.platform | default: 'all'}}
  # Options: 'macos', 'linux', 'all'
  # Platform-specific compatibility checks
```

## Instructions

### STEP 1: Validate Prerequisites

**1.1 Check Git Repository**

```bash
# Verify we're in a git repository
git rev-parse --git-dir 2>/dev/null
```

**Error Handling**:

- **Not a git repo**: Display error "QA checks require a git repository. Initialize with 'git init'."
- **No git installed**: Display error "Git not found. Please install git to run QA checks."

**1.2 Determine Check Scope**

Parse the `scope` argument to determine which checks to run:

```yaml
scope_config:
  all:
    - linting
    - testing
    - compatibility
    - permissions
  lint:
    - linting
  test:
    - testing
  compatibility:
    - compatibility
```

**1.3 Determine Platform Scope**

Parse the `platform` argument:

```yaml
platform_config:
  all:
    - macos
    - linux
  macos:
    - macos
  linux:
    - linux
```

**1.4 Detect Project Type**

Identify project characteristics to tailor checks:

```bash
# Check for different project types
test -f "package.json" && echo "nodejs"
test -f "setup.py" || test -f "pyproject.toml" && echo "python"
test -f "go.mod" && echo "golang"
test -f "Cargo.toml" && echo "rust"
test -f "install.sh" && echo "shell"
```

**Store Project Context**:

```text
PROJECT_TYPE: {{detected_type}}
HAS_PRE_COMMIT: {{true|false}}
HAS_TESTS: {{true|false}}
HAS_BUILD: {{true|false}}
```

---

### STEP 2: Initialize QA Report

**2.1 Create Report File**

```bash
# Create temporary report file
REPORT_FILE="/tmp/qa-report-$(date +%s).md"
cat > "$REPORT_FILE" << 'EOF'
---
title: "QA Check Report"
generated_at: "{{timestamp}}"
scope: "{{scope}}"
platform: "{{platform}}"
---

# QA Check Report

**Generated**: {{timestamp}}
**Scope**: {{scope}}
**Platform**: {{platform}}
**Project**: {{project_root}}

## Summary

**Status**: In Progress...

EOF
```

**2.2 Display Check Plan**

```text
╔════════════════════════════════════════════════════════════════════════════╗
║                          QA CHECKS STARTING                                ║
╚════════════════════════════════════════════════════════════════════════════╝

Scope: {{scope}}
Platform: {{platform}}
Project Type: {{project_type}}

CHECKS PLANNED:
───────────────────────────────────────────────────────────────────────────

  {{#each checks}}
  [{{index}}] {{check_name}}
  {{/each}}

Starting quality assurance validation...

───────────────────────────────────────────────────────────────────────────
```

---

### STEP 3: Invoke qa-engineer Agent

**3.1 Check for qa-engineer Agent**

```bash
# Check if qa-engineer agent exists
test -f "{{CLAUDE_CONFIG_DIR}}/agents/qa-engineer.md"
```

**If agent does NOT exist**:

Display warning and fallback plan:

```text
╔════════════════════════════════════════════════════════════════════════════╗
║                      ⚠ QA ENGINEER AGENT NOT FOUND                        ║
╚════════════════════════════════════════════════════════════════════════════╝

The qa-engineer agent is recommended for comprehensive quality checks.

OPTIONS:
───────────────────────────────────────────────────────────────────────────

  [1] Continue with basic QA checks (no agent)
      → Run standard linting, testing, and compatibility checks

  [2] Create qa-engineer agent now
      → Invoke /create-agent to set up qa-engineer agent

  [3] Abort QA checks
      → Exit without running checks

───────────────────────────────────────────────────────────────────────────

Choice [1-3]: _
```

**Handle user choice**:

- **Choice 1**: Continue with basic checks (proceed to Step 4)
- **Choice 2**: Run `/create-agent qa-engineer` then return to this command
- **Choice 3**: Exit command

**3.2 Prepare Agent Context**

If qa-engineer agent exists, prepare comprehensive context:

```markdown
You are being invoked by the /qa-check command to perform comprehensive quality assurance.

## QA Check Configuration

**Scope**: {{scope}}
**Platform**: {{platform}}
**Project Type**: {{project_type}}
**Project Root**: {{project_root}}

## Your Mission

Perform systematic quality checks across the following areas:

### Linting Checks (if scope includes 'lint' or 'all')

1. **Shell Scripts**: Run ShellCheck with zero warnings requirement
2. **YAML Files**: Run yamllint in strict mode
3. **Markdown Files**: Run markdownlint with project configuration
4. **GitHub Workflows**: Run actionlint for CI/CD validation

### Testing Checks (if scope includes 'test' or 'all')

1. **Unit Tests**: Run project-specific test suite
2. **Integration Tests**: Run integration tests if available
3. **Installation Tests**: Run container-based installation tests

### Compatibility Checks (if scope includes 'compatibility' or 'all')

1. **Bash 3.2 Compatibility**: Verify macOS default shell compatibility
2. **Command Availability**: Check for platform-specific commands
3. **Path Handling**: Validate handling of spaces and special characters
4. **Cross-Platform**: Test on {{platform_list}}

### Permission Checks

1. **Executable Permissions**: Verify scripts have correct permissions
2. **File Ownership**: Check file ownership consistency

## Requirements

- Record all check results with pass/fail status
- Capture detailed error messages for failures
- Provide remediation steps for each failure
- Generate comprehensive summary report
- Save report to: {{report_file}}

## Expected Output

Comprehensive QA report with:
- Overall pass/fail status
- Individual check results
- Error details and remediation steps
- Recommendations for improvements
```

**3.3 Execute Agent Delegation**

- Pass context to qa-engineer agent
- Agent executes systematic quality checks
- Capture all results and output

---

### STEP 4: Run Quality Checks

**Execute checks based on scope** (if no agent, or agent delegates back):

**4.1 LINTING CHECKS**

Run if scope includes 'lint' or 'all':

#### Shell Script Linting

```bash
# Find all shell scripts
git ls-files '*.sh' '*.bash' | while read -r script; do
  echo "Checking: $script"
  shellcheck "$script" 2>&1
  if [ $? -eq 0 ]; then
    echo "✓ PASS: $script"
  else
    echo "✗ FAIL: $script"
  fi
done
```

**Record Results**:

```yaml
linting:
  shellcheck:
    status: "pass|fail"
    files_checked: {{count}}
    files_passed: {{count}}
    files_failed: {{count}}
    errors: [...]
```

#### YAML Linting

```bash
# Find all YAML files
git ls-files '*.yml' '*.yaml' | while read -r yamlfile; do
  echo "Checking: $yamlfile"
  yamllint --strict "$yamlfile" 2>&1
  if [ $? -eq 0 ]; then
    echo "✓ PASS: $yamlfile"
  else
    echo "✗ FAIL: $yamlfile"
  fi
done
```

**Record Results**:

```yaml
linting:
  yamllint:
    status: "pass|fail"
    files_checked: {{count}}
    files_passed: {{count}}
    files_failed: {{count}}
    errors: [...]
```

#### Markdown Linting

```bash
# Run markdownlint on all markdown files
git ls-files '*.md' | while read -r mdfile; do
  echo "Checking: $mdfile"
  markdownlint "$mdfile" 2>&1
  if [ $? -eq 0 ]; then
    echo "✓ PASS: $mdfile"
  else
    echo "✗ FAIL: $mdfile"
  fi
done
```

**Record Results**:

```yaml
linting:
  markdownlint:
    status: "pass|fail"
    files_checked: {{count}}
    files_passed: {{count}}
    files_failed: {{count}}
    errors: [...]
```

#### GitHub Workflow Linting

```bash
# Run actionlint on GitHub workflows
if [ -d ".github/workflows" ]; then
  actionlint .github/workflows/*.yml 2>&1
  if [ $? -eq 0 ]; then
    echo "✓ PASS: GitHub workflows"
  else
    echo "✗ FAIL: GitHub workflows"
  fi
fi
```

**Record Results**:

```yaml
linting:
  actionlint:
    status: "pass|fail|skipped"
    files_checked: {{count}}
    errors: [...]
```

#### Pre-commit Hooks

```bash
# Run pre-commit if available
if [ -f ".pre-commit-config.yaml" ]; then
  pre-commit run --all-files 2>&1
  if [ $? -eq 0 ]; then
    echo "✓ PASS: Pre-commit hooks"
  else
    echo "✗ FAIL: Pre-commit hooks"
  fi
fi
```

**Record Results**:

```yaml
linting:
  pre_commit:
    status: "pass|fail|skipped"
    hooks_run: {{count}}
    errors: [...]
```

**4.2 TESTING CHECKS**

Run if scope includes 'test' or 'all':

#### Unit Tests

```bash
# Detect and run test framework
case "$PROJECT_TYPE" in
  nodejs)
    npm test 2>&1
    ;;
  python)
    pytest 2>&1 || python -m unittest discover 2>&1
    ;;
  golang)
    go test ./... 2>&1
    ;;
  rust)
    cargo test 2>&1
    ;;
  shell)
    if [ -f "tests/run-tests.sh" ]; then
      bash tests/run-tests.sh 2>&1
    fi
    ;;
esac
```

**Record Results**:

```yaml
testing:
  unit_tests:
    status: "pass|fail|skipped"
    tests_run: {{count}}
    tests_passed: {{count}}
    tests_failed: {{count}}
    tests_skipped: {{count}}
    duration: "{{duration}}"
    errors: [...]
```

#### Integration Tests

```bash
# Run integration tests if available
if [ -d "tests/integration" ]; then
  bash tests/integration/run-tests.sh 2>&1
  TEST_STATUS=$?
fi
```

**Record Results**:

```yaml
testing:
  integration_tests:
    status: "pass|fail|skipped"
    tests_run: {{count}}
    tests_passed: {{count}}
    tests_failed: {{count}}
    errors: [...]
```

#### Installation Tests

```bash
# Run container-based installation tests if available
if [ -f ".github/testing/test-install.sh" ]; then
  .github/testing/test-install.sh --verbose 2>&1
  TEST_STATUS=$?
fi
```

**Record Results**:

```yaml
testing:
  installation_tests:
    status: "pass|fail|skipped"
    environments_tested: [...]
    environments_passed: [...]
    environments_failed: [...]
    errors: [...]
```

**4.3 COMPATIBILITY CHECKS**

Run if scope includes 'compatibility' or 'all':

#### Bash Version Compatibility

```bash
# Check for Bash 4+ specific features in scripts
git ls-files '*.sh' '*.bash' | while read -r script; do
  # Check for associative arrays (Bash 4+)
  if grep -q "declare -A" "$script"; then
    echo "⚠ WARNING: $script uses Bash 4+ features (associative arrays)"
  fi

  # Check for [[ ]] extended test (Bash-specific)
  if grep -q '\[\[' "$script"; then
    echo "ℹ INFO: $script uses Bash-specific [[ ]] syntax"
  fi
done
```

**Record Results**:

```yaml
compatibility:
  bash_version:
    status: "pass|warning|fail"
    bash_3_2_compatible: {{true|false}}
    issues: [...]
```

#### Command Availability

```bash
# Check for platform-specific commands
REQUIRED_COMMANDS="git stow awk sed grep find"

for cmd in $REQUIRED_COMMANDS; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "✗ FAIL: Required command not found: $cmd"
  else
    echo "✓ PASS: Command available: $cmd"
  fi
done
```

**Record Results**:

```yaml
compatibility:
  commands:
    status: "pass|fail"
    required_commands: [...]
    missing_commands: [...]
    platform_specific: [...]
```

#### Path Handling

```bash
# Test path handling with spaces and special characters
TEST_DIR=$(mktemp -d "/tmp/qa test with spaces.XXXXXX")

# Try to create and access file with spaces
touch "$TEST_DIR/test file.txt"
if [ -f "$TEST_DIR/test file.txt" ]; then
  echo "✓ PASS: Path handling with spaces works"
else
  echo "✗ FAIL: Path handling with spaces broken"
fi

# Clean up
rm -rf "$TEST_DIR"
```

**Record Results**:

```yaml
compatibility:
  path_handling:
    status: "pass|fail"
    spaces_supported: {{true|false}}
    special_chars_supported: {{true|false}}
    issues: [...]
```

#### Cross-Platform Testing

```bash
# Run cross-platform tests if Docker available
if command -v docker >/dev/null 2>&1; then
  case "$PLATFORM" in
    macos|all)
      echo "Testing macOS compatibility..."
      # Run macOS-specific tests
      ;;
    linux|all)
      echo "Testing Linux compatibility..."
      # Run Linux-specific tests
      ;;
  esac
fi
```

**Record Results**:

```yaml
compatibility:
  cross_platform:
    status: "pass|fail|skipped"
    platforms_tested: [...]
    platforms_passed: [...]
    platforms_failed: [...]
    issues: [...]
```

**4.4 PERMISSION CHECKS**

Always run:

#### Executable Permissions

```bash
# Find scripts that should be executable
git ls-files '*.sh' '*.bash' 'install.sh' | while read -r script; do
  if [ -x "$script" ]; then
    echo "✓ PASS: $script is executable"
  else
    echo "⚠ WARNING: $script is not executable"
  fi
done
```

**Record Results**:

```yaml
permissions:
  executable:
    status: "pass|warning"
    scripts_checked: {{count}}
    non_executable: [...]
```

#### File Ownership

```bash
# Check for consistent file ownership
OWNER=$(stat -f "%u:%g" . 2>/dev/null || stat -c "%u:%g" .)
git ls-files | while read -r file; do
  FILE_OWNER=$(stat -f "%u:%g" "$file" 2>/dev/null || stat -c "%u:%g" "$file")
  if [ "$FILE_OWNER" != "$OWNER" ]; then
    echo "⚠ WARNING: $file has different ownership: $FILE_OWNER (expected $OWNER)"
  fi
done
```

**Record Results**:

```yaml
permissions:
  ownership:
    status: "pass|warning"
    inconsistent_files: [...]
```

---

### STEP 5: Generate QA Report

**5.1 Aggregate Results**

Combine all check results into comprehensive report:

```markdown
---
title: "QA Check Report"
generated_at: "{{timestamp}}"
scope: "{{scope}}"
platform: "{{platform}}"
overall_status: "{{pass|warning|fail}}"
---

# QA Check Report

**Generated**: {{timestamp}}
**Scope**: {{scope}}
**Platform**: {{platform}}
**Project**: {{project_root}}
**Overall Status**: {{status_emoji}} {{status}}

## Summary

{{#if overall_pass}}
✓ All quality checks passed successfully.
{{else}}
✗ Quality checks found {{issue_count}} issues requiring attention.
{{/if}}

### Check Results

| Category | Status | Pass | Fail | Warnings |
|----------|--------|------|------|----------|
| Linting | {{status}} | {{pass}} | {{fail}} | {{warn}} |
| Testing | {{status}} | {{pass}} | {{fail}} | {{warn}} |
| Compatibility | {{status}} | {{pass}} | {{fail}} | {{warn}} |
| Permissions | {{status}} | {{pass}} | {{fail}} | {{warn}} |

## Detailed Results

### Linting Checks

#### ShellCheck
**Status**: {{status}}
**Files Checked**: {{count}}
**Files Passed**: {{pass_count}}
**Files Failed**: {{fail_count}}

{{#if errors}}
**Errors**:
{{#each errors}}
- `{{file}}`: {{error_message}}
{{/each}}
{{/if}}

#### yamllint
**Status**: {{status}}
**Files Checked**: {{count}}
**Files Passed**: {{pass_count}}
**Files Failed**: {{fail_count}}

{{#if errors}}
**Errors**:
{{#each errors}}
- `{{file}}`: {{error_message}}
{{/each}}
{{/if}}

#### markdownlint
**Status**: {{status}}
**Files Checked**: {{count}}
**Files Passed**: {{pass_count}}
**Files Failed**: {{fail_count}}

{{#if errors}}
**Errors**:
{{#each errors}}
- `{{file}}`: {{error_message}}
{{/each}}
{{/if}}

#### actionlint
**Status**: {{status}}
**Files Checked**: {{count}}

{{#if errors}}
**Errors**:
{{#each errors}}
- {{error_message}}
{{/each}}
{{/if}}

### Testing Checks

#### Unit Tests
**Status**: {{status}}
**Tests Run**: {{count}}
**Passed**: {{pass_count}}
**Failed**: {{fail_count}}
**Skipped**: {{skip_count}}
**Duration**: {{duration}}

{{#if failures}}
**Failed Tests**:
{{#each failures}}
- {{test_name}}: {{error_message}}
{{/each}}
{{/if}}

#### Integration Tests
**Status**: {{status}}
**Tests Run**: {{count}}
**Passed**: {{pass_count}}
**Failed**: {{fail_count}}

{{#if failures}}
**Failed Tests**:
{{#each failures}}
- {{test_name}}: {{error_message}}
{{/each}}
{{/if}}

#### Installation Tests
**Status**: {{status}}
**Environments Tested**: {{env_list}}
**Passed**: {{pass_list}}
**Failed**: {{fail_list}}

{{#if failures}}
**Failed Environments**:
{{#each failures}}
- {{env_name}}: {{error_message}}
{{/each}}
{{/if}}

### Compatibility Checks

#### Bash Version Compatibility
**Status**: {{status}}
**Bash 3.2 Compatible**: {{compatible}}

{{#if issues}}
**Issues**:
{{#each issues}}
- `{{file}}`: {{issue_description}}
{{/each}}
{{/if}}

#### Command Availability
**Status**: {{status}}
**Required Commands**: {{command_list}}
**Missing Commands**: {{missing_list}}

{{#if missing}}
**Missing Commands**:
{{#each missing}}
- `{{command}}`: {{description}}
{{/each}}
{{/if}}

#### Path Handling
**Status**: {{status}}
**Spaces Supported**: {{spaces_ok}}
**Special Characters Supported**: {{special_chars_ok}}

{{#if issues}}
**Issues**:
{{#each issues}}
- {{issue_description}}
{{/each}}
{{/if}}

#### Cross-Platform
**Status**: {{status}}
**Platforms Tested**: {{platform_list}}
**Platforms Passed**: {{pass_list}}
**Platforms Failed**: {{fail_list}}

{{#if failures}}
**Platform Issues**:
{{#each failures}}
- {{platform}}: {{issue_description}}
{{/each}}
{{/if}}

### Permission Checks

#### Executable Permissions
**Status**: {{status}}
**Scripts Checked**: {{count}}
**Non-Executable**: {{non_exec_count}}

{{#if non_executable}}
**Non-Executable Scripts**:
{{#each non_executable}}
- `{{file}}`
{{/each}}
{{/if}}

#### File Ownership
**Status**: {{status}}
**Inconsistent Files**: {{count}}

{{#if inconsistent}}
**Files with Different Ownership**:
{{#each inconsistent}}
- `{{file}}`: {{ownership}}
{{/each}}
{{/if}}

## Remediation Steps

{{#if has_errors}}
### Critical Issues (Must Fix)

{{#each critical_issues}}
**{{category}}**: {{issue}}

**Fix**:
```bash
{{remediation_command}}
```

**Explanation**: {{explanation}}

---
{{/each}}

### Warnings (Should Fix)

{{#each warnings}}
**{{category}}**: {{issue}}

**Fix**:
```bash
{{remediation_command}}
```

**Explanation**: {{explanation}}

---
{{/each}}

{{else}}
No remediation steps required. All checks passed!
{{/if}}

## Recommendations

{{#each recommendations}}
- {{recommendation}}
{{/each}}

## Next Steps

{{#if overall_pass}}
✓ Quality checks passed. Safe to proceed with:
- Committing changes
- Creating pull request
- Merging to main branch

{{else}}
⚠ Address quality issues before proceeding:
1. Review remediation steps above
2. Fix critical issues
3. Re-run QA checks: `/qa-check`
4. Verify all checks pass before committing
{{/if}}

---

**QA Check completed at**: {{timestamp}}
**Report generated by**: qa-engineer agent
```

**5.2 Save Report**

```bash
# Save report to file
cp "$REPORT_FILE" "${PROJECT_ROOT}/qa-report.md"

# Also save to work directory if active issue
if [ -f "${PROJECT_ROOT}/.claude/workflow-state.json" ]; then
  ISSUE_NUM=$(jq -r '.active_issue.number' "${PROJECT_ROOT}/.claude/workflow-state.json")
  if [ -n "$ISSUE_NUM" ] && [ "$ISSUE_NUM" != "null" ]; then
    cp "$REPORT_FILE" "${PROJECT_ROOT}/.github/issues/in-progress/issue-${ISSUE_NUM}/qa-report.md"
  fi
fi
```

**5.3 Display Summary**

```text
╔════════════════════════════════════════════════════════════════════════════╗
║                        QA CHECKS COMPLETE                                  ║
╚════════════════════════════════════════════════════════════════════════════╝

Overall Status: {{status_emoji}} {{status}}

RESULTS:
───────────────────────────────────────────────────────────────────────────

  Linting:        {{status}} ({{pass}}/{{total}} passed)
  Testing:        {{status}} ({{pass}}/{{total}} passed)
  Compatibility:  {{status}} ({{pass}}/{{total}} passed)
  Permissions:    {{status}} ({{pass}}/{{total}} passed)

{{#if has_errors}}
ISSUES FOUND:
───────────────────────────────────────────────────────────────────────────

  Critical: {{critical_count}}
  Warnings: {{warning_count}}

See detailed report for remediation steps.
{{/if}}

REPORT SAVED:
───────────────────────────────────────────────────────────────────────────

  {{project_root}}/qa-report.md
  {{#if work_dir}}
  {{work_dir}}/qa-report.md
  {{/if}}

{{#if overall_pass}}
✓ All quality checks passed. Safe to proceed!
{{else}}
⚠ Fix issues before committing. Run `/qa-check` again after fixes.
{{/if}}

───────────────────────────────────────────────────────────────────────────
```

---

### STEP 6: Clean Up

**6.1 Remove Temporary Files**

```bash
# Clean up temporary report file
rm -f "$REPORT_FILE"

# Clean up any test artifacts
rm -rf /tmp/qa-test-*
```

**6.2 Exit with Appropriate Status**

```bash
# Exit with status based on results
if [ "$OVERALL_STATUS" = "pass" ]; then
  exit 0
elif [ "$OVERALL_STATUS" = "warning" ]; then
  exit 0  # Warnings don't fail the command
else
  exit 1  # Failures fail the command
fi
```

---

## Examples

### Example 1: Run All Checks

```bash
# Run complete QA suite on all platforms
/qa-check

# Runs:
# - Linting (ShellCheck, yamllint, markdownlint, actionlint)
# - Testing (unit, integration, installation)
# - Compatibility (Bash 3.2, commands, paths, cross-platform)
# - Permissions (executable, ownership)
```

### Example 2: Lint Only

```bash
# Run linting checks only
/qa-check --scope=lint

# Runs:
# - ShellCheck on all shell scripts
# - yamllint on all YAML files
# - markdownlint on all markdown files
# - actionlint on GitHub workflows
```

### Example 3: Test Only

```bash
# Run testing checks only
/qa-check --scope=test

# Runs:
# - Unit tests
# - Integration tests
# - Installation tests
```

### Example 4: macOS Compatibility

```bash
# Run compatibility checks for macOS only
/qa-check --scope=compatibility --platform=macos

# Runs:
# - Bash 3.2 compatibility checks
# - macOS-specific command availability
# - Path handling on macOS
```

### Example 5: Linux Compatibility

```bash
# Run compatibility checks for Linux only
/qa-check --scope=compatibility --platform=linux

# Runs:
# - Linux-specific compatibility checks
# - Command availability on Linux
# - Path handling on Linux
```

---

## Error Handling

- **No git repository**: Exit with error message
- **Missing dependencies**: List missing tools, provide installation instructions
- **qa-engineer agent missing**: Offer to create agent or continue with basic checks
- **Check failures**: Record in report, continue with remaining checks
- **Invalid scope**: Display error with valid options
- **Invalid platform**: Display error with valid options

---

## Integration with Workflow

### Position in Workflow

```text
[/implement] → /qa-check → /open-pr → [merge] → /cleanup-main
```

Or standalone:

```text
[development] → /qa-check → [fix issues] → /qa-check → [commit]
```

### When to Use

**Use `/qa-check` when**:

- Before committing changes
- Before creating a pull request
- After implementing new features
- Before merging to main branch
- As part of CI/CD validation
- When troubleshooting quality issues

**Integration Points**:

- **`/implement`**: Run automatically after implementation completes
- **`/open-pr`**: Run before creating pull request
- **Pre-commit hooks**: Run linting subset automatically
- **CI/CD**: Run full suite in GitHub Actions

---

## Configuration

### Default Configuration

Created in `~/.claude/workflow-config.json` if not exists:

```json
{
  "qa": {
    "enabled": true,
    "default_scope": "all",
    "default_platform": "all",
    "fail_on_warnings": false,
    "auto_fix": true,
    "report_format": "markdown",
    "checks": {
      "linting": {
        "enabled": true,
        "shellcheck": true,
        "yamllint": true,
        "markdownlint": true,
        "actionlint": true
      },
      "testing": {
        "enabled": true,
        "unit": true,
        "integration": true,
        "installation": true
      },
      "compatibility": {
        "enabled": true,
        "bash_version": "3.2",
        "required_commands": ["git", "stow", "awk", "sed", "grep", "find"],
        "platforms": ["macos", "linux"]
      },
      "permissions": {
        "enabled": true,
        "check_executable": true,
        "check_ownership": true
      }
    }
  }
}
```

---

## Notes

- This command is designed for comprehensive quality assurance
- **Delegates to qa-engineer agent** for systematic checks
- **Idempotent**: Safe to run multiple times
- **Non-destructive**: Only reads and analyzes, doesn't modify files
- **Auto-fix capable**: Can fix some linting issues automatically
- **Platform-aware**: Adapts checks based on target platform
- **Extensible**: Easy to add new check types

---

## Related Commands

- `/implement` - Implementation with built-in quality checks
- `/open-pr` - Create pull request (runs QA checks first)
- `/start-work` - Begin work on issue
- `/create-agent` - Create qa-engineer agent if missing
