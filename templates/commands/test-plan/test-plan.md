---
name: test-plan
description: Generate comprehensive test plans with acceptance criteria and cross-platform validation strategies
model: sonnet
args:
  scope:
    description: "What to test - 'feature', 'issue', or 'release' (default: feature)"
    required: false
    type: string
  issue:
    description: GitHub issue number to generate test plan for (optional)
    required: false
    type: number
version: 1.0.0
category: testing
---

# Test Plan Generation Command

Generates comprehensive test plans with test matrices, acceptance criteria, and cross-platform validation strategies. This command invokes the `qa-engineer` agent to create detailed testing documentation.

## Usage

```bash
/test-plan [--scope=feature|issue|release] [--issue=<number>]
```

## Arguments

- **scope** (optional): What to test - `feature`, `issue`, or `release`. Defaults to `feature`.
  - `feature`: Test a specific feature or functionality
  - `issue`: Test based on a GitHub issue
  - `release`: Test an entire release/milestone

- **issue** (optional): GitHub issue number to base the test plan on. If provided, loads issue details automatically.

## Examples

```bash
# Interactive mode - will prompt for details
/test-plan

# Generate test plan for a specific issue
/test-plan --issue=42

# Generate test plan for a feature (interactive)
/test-plan --scope=feature

# Generate test plan for entire release
/test-plan --scope=release
```

## Workflow

This command invokes the **qa-engineer** agent to:

### STEP 1: Gather Context

#### 1.1 Determine Scope

Check the `scope` argument:

- If `scope=issue` and `issue` provided: Load issue details
- If `scope=issue` and no issue: Check for active issue in workflow state
- If `scope=feature`: Prompt for feature details
- If `scope=release`: Check for active milestone

#### 1.2 Load Issue Details (if applicable)

```bash
# Load issue from GitHub or local drafts
gh issue view {{issue_number}} --json title,body,labels,milestone,assignees
```

**Fallback**: Check local issue drafts:

- `.github/issues/drafts/{{milestone}}/{{issue-number}}-*.md`
- `.github/issues/published/{{milestone}}/{{issue-number}}-*.md`

#### 1.3 Load Analysis Documents (if available)

```bash
# Check for analysis directory
ANALYSIS_DIR=".github/issues/in-progress/issue-{{issue_number}}"

# Load PRD if exists
test -f "$ANALYSIS_DIR/PRD.md" && cat "$ANALYSIS_DIR/PRD.md"

# Load TECH_SPEC if exists
test -f "$ANALYSIS_DIR/TECH_SPEC.md" && cat "$ANALYSIS_DIR/TECH_SPEC.md"

# Load IMPLEMENTATION_SUMMARY if exists
test -f "$ANALYSIS_DIR/IMPLEMENTATION_SUMMARY.md" && cat "$ANALYSIS_DIR/IMPLEMENTATION_SUMMARY.md"
```

#### 1.4 Interactive Prompts (if needed)

If scope is `feature` or information is missing:

```text
╔════════════════════════════════════════════════════════════════════════════╗
║                      TEST PLAN GENERATION                                  ║
╚════════════════════════════════════════════════════════════════════════════╝

What would you like to test?

Feature/Functionality: _______________________

Brief Description: _______________________

Platform(s) to test:
  [ ] macOS
  [ ] Linux (Ubuntu)
  [ ] Linux (other distros)
  [ ] Docker environments

Components involved:
  [ ] Shell scripts
  [ ] Installation scripts
  [ ] Templates
  [ ] Agents
  [ ] Commands
  [ ] Documentation
  [ ] CI/CD pipelines

Expected user workflow: _______________________
```

---

### STEP 2: Analyze Requirements

#### 2.1 Extract Functional Requirements

From issue/PRD/feature description:

- Identify all user-facing functionality
- Extract acceptance criteria
- Determine success metrics
- Identify edge cases

#### 2.2 Identify System Components

- List all files/scripts affected
- Identify integration points
- Map dependencies between components
- Determine external dependencies

#### 2.3 Determine Test Platforms

Based on project configuration and requirements:

- macOS versions (if applicable)
- Linux distributions (Ubuntu, CentOS, Fedora, etc.)
- Bash versions (3.x, 4.x, 5.x)
- Docker environments
- CI/CD environments

#### 2.4 Risk Assessment

Identify high-risk areas:

- Critical path functionality
- Complex integrations
- Platform-specific code
- User data handling
- Security-sensitive operations
- Error handling paths

---

### STEP 3: Generate Test Matrix

#### 3.1 Platform Combinations

Create test matrix for cross-platform validation:

```markdown
| Test Scenario | macOS 13+ | Ubuntu 22.04 | Ubuntu 20.04 | Docker | Bash 3.x | Bash 4.x | Bash 5.x |
|---------------|-----------|--------------|--------------|--------|----------|----------|----------|
| Scenario 1    | Required  | Required     | Optional     | N/A    | Required | Required | Required |
| Scenario 2    | Required  | Required     | Required     | N/A    | N/A      | Required | Required |
```

#### 3.2 Test Coverage Matrix

```markdown
| Component        | Unit Tests | Integration Tests | E2E Tests | Manual Tests | Priority |
|------------------|------------|-------------------|-----------|--------------|----------|
| install.sh       | N/A        | Required          | Required  | Required     | P0       |
| Personality load | N/A        | Required          | Optional  | Required     | P1       |
| Agent creation   | N/A        | Required          | Optional  | Required     | P1       |
```

**Priority Levels**:

- **P0**: Critical - must pass before merge
- **P1**: High - should pass before merge
- **P2**: Medium - can be addressed post-merge
- **P3**: Low - nice to have

---

### STEP 4: Define Test Scenarios

For each identified test scenario, create:

#### 4.1 Test Case Template

```markdown
### Test Case TC-{{number}}: {{Test Title}}

**Objective**: {{What this test validates}}

**Type**: Functional | Integration | Regression | Performance | Security

**Priority**: P0 | P1 | P2 | P3

**Platforms**: macOS, Ubuntu 22.04, Docker

**Pre-conditions**:

- System state before test
- Required environment setup
- Dependencies installed
- Sample data available

**Test Steps**:

1. Step 1: {{Action to perform}}
   - Expected result: {{What should happen}}
   - Actual result: [To be filled during testing]

2. Step 2: {{Action to perform}}
   - Expected result: {{What should happen}}
   - Actual result: [To be filled during testing]

**Test Data**:

- Input: {{Sample input data}}
- Expected output: {{Expected result}}
- Edge cases: {{Boundary values}}

**Acceptance Criteria**:

- [ ] Criterion 1: {{Specific pass/fail condition}}
- [ ] Criterion 2: {{Specific pass/fail condition}}

**Post-conditions**:

- Expected system state after test
- Cleanup required
- Side effects to verify

**Notes**:

- Special considerations
- Known limitations
- Dependencies on other tests
```

#### 4.2 Test Scenarios by Category

**Happy Path Tests**:

- Primary user workflow
- Standard inputs
- Expected usage patterns

**Edge Case Tests**:

- Boundary values
- Empty/null inputs
- Maximum/minimum values
- Special characters

**Error Condition Tests**:

- Invalid inputs
- Missing dependencies
- Permission errors
- Network failures
- Disk space issues

**Integration Tests**:

- Component interactions
- External service integration
- Data flow between systems

**Regression Tests**:

- Previously fixed bugs
- Core functionality preservation
- Backward compatibility

**Cross-Platform Tests**:

- Platform-specific behavior
- Shell differences
- File path handling
- Permission models

---

### STEP 5: Create Test Plan Document

#### 5.1 Generate Comprehensive Test Plan

Create test plan at appropriate location:

**For issues**: `.github/issues/in-progress/issue-{{number}}/TEST_PLAN.md`

**For features**: `${PROJECT_ROOT}/.claude/test-plans/feature-{{name}}-{{timestamp}}.md`

**For releases**: `${PROJECT_ROOT}/.claude/test-plans/release-{{milestone}}-{{timestamp}}.md`

#### 5.2 Test Plan Structure

```markdown
---
title: "Test Plan - {{Title}}"
scope: "{{scope}}"
issue: {{issue_number}}
milestone: "{{milestone}}"
created_at: "{{timestamp}}"
status: "draft"
priority: "P0"
platforms: ["macOS", "Ubuntu 22.04", "Ubuntu 20.04", "Docker"]
---

# Test Plan: {{Title}}

## Overview

**Scope**: {{scope}}
**Issue**: #{{issue_number}} - {{issue_title}}
**Milestone**: {{milestone}}
**Created**: {{timestamp}}
**Status**: Draft

## Executive Summary

{{Brief description of what this test plan covers and why it's important}}

### Testing Objectives

1. Validate {{objective_1}}
2. Verify {{objective_2}}
3. Ensure {{objective_3}}

### Success Criteria

- [ ] All P0 tests pass on all required platforms
- [ ] All P1 tests pass on primary platforms (macOS, Ubuntu 22.04)
- [ ] No critical regressions introduced
- [ ] Documentation reflects actual behavior

---

## Requirements Analysis

### Functional Requirements

{{List of functional requirements to be tested}}

1. {{Requirement 1}}
   - **Source**: PRD section X / Issue description
   - **Priority**: P0
   - **Test coverage**: TC-001, TC-002

2. {{Requirement 2}}
   - **Source**: TECH_SPEC section Y
   - **Priority**: P1
   - **Test coverage**: TC-003, TC-004

### Non-Functional Requirements

- **Performance**: {{Performance criteria}}
- **Reliability**: {{Reliability expectations}}
- **Usability**: {{User experience goals}}
- **Security**: {{Security requirements}}
- **Compatibility**: {{Platform compatibility}}

---

## Test Environment

### Required Platforms

**Primary (P0 testing required)**:

- macOS 13+ (Ventura, Sonoma)
- Ubuntu 22.04 LTS
- Bash 5.x

**Secondary (P1 testing recommended)**:

- Ubuntu 20.04 LTS
- Bash 4.x
- Docker (ubuntu:22.04 base)

**Optional (P2 nice-to-have)**:

- Other Linux distributions
- Bash 3.x (if compatibility claimed)

### Environment Setup

**Dependencies**:

```bash
# Required tools
- git 2.x+
- bash 3.x+ / 4.x / 5.x
- curl or wget
- jq (for JSON processing)
- GNU stow (for dotfiles integration)

# Optional tools
- gh (GitHub CLI)
- docker (for containerized testing)
```

**Test Data**:

- Sample configuration files
- Mock API responses
- Test user data (anonymized)

### Test Infrastructure

**Manual Testing**:

- Local development machines
- Virtual machines (VirtualBox/VMware)
- Cloud VMs (EC2, DigitalOcean)

**Automated Testing**:

- GitHub Actions workflows
- Docker containers
- Test harness scripts

---

## Test Matrix

### Cross-Platform Test Matrix

| Test Scenario | macOS 13+ | Ubuntu 22.04 | Ubuntu 20.04 | Docker | Priority |
|---------------|-----------|--------------|--------------|--------|----------|
| {{scenario_1}} | ✓ | ✓ | ✓ | ✓ | P0 |
| {{scenario_2}} | ✓ | ✓ | - | ✓ | P1 |
| {{scenario_3}} | ✓ | - | - | - | P2 |

**Legend**:

- ✓ Required
- - Optional/Not Applicable

### Bash Version Compatibility Matrix

| Test Scenario | Bash 3.x | Bash 4.x | Bash 5.x | Priority |
|---------------|----------|----------|----------|----------|
| {{scenario_1}} | ✓ | ✓ | ✓ | P0 |
| {{scenario_2}} | - | ✓ | ✓ | P1 |

### Component Coverage Matrix

| Component | Unit | Integration | E2E | Manual | Priority |
|-----------|------|-------------|-----|--------|----------|
| {{component_1}} | N/A | ✓ | ✓ | ✓ | P0 |
| {{component_2}} | N/A | ✓ | - | ✓ | P1 |

---

## Test Scenarios

### Happy Path Tests

{{#each happy_path_tests}}

#### TC-{{id}}: {{title}}

**Objective**: {{objective}}

**Type**: Functional

**Priority**: {{priority}}

**Platforms**: {{platforms}}

**Pre-conditions**:

{{pre_conditions}}

**Test Steps**:

{{#each steps}}
{{step_number}}. {{action}}

- Expected: {{expected}}
- Actual: [To be filled]
- Status: [ ] Pass [ ] Fail
{{/each}}

**Test Data**:

- Input: {{input}}
- Expected output: {{output}}

**Acceptance Criteria**:

{{#each acceptance_criteria}}

- [ ] {{criterion}}
{{/each}}

**Post-conditions**:

{{post_conditions}}

---
{{/each}}

### Edge Case Tests

{{#each edge_case_tests}}

#### TC-{{id}}: {{title}}

[Same structure as happy path tests]
{{/each}}

### Error Condition Tests

{{#each error_tests}}

#### TC-{{id}}: {{title}}

**Objective**: Verify system handles {{error_type}} gracefully

**Type**: Negative Testing

**Priority**: {{priority}}

**Test Steps**:

1. Create error condition: {{error_setup}}
2. Execute: {{action}}
3. Verify error handling: {{expected_error}}
4. Verify recovery: {{recovery_expected}}

**Acceptance Criteria**:

- [ ] Clear error message displayed
- [ ] System remains in consistent state
- [ ] No data corruption
- [ ] User can recover gracefully

---
{{/each}}

### Integration Tests

{{#each integration_tests}}

#### TC-{{id}}: {{title}}

**Objective**: Validate {{component_a}} integrates with {{component_b}}

**Type**: Integration

**Priority**: {{priority}}

**Components Involved**: {{components}}

**Test Steps**:

1. Set up {{component_a}}
2. Set up {{component_b}}
3. Execute integration workflow
4. Verify data flow
5. Verify expected behavior

**Acceptance Criteria**:

- [ ] Data flows correctly between components
- [ ] No errors in integration layer
- [ ] Performance within acceptable limits

---
{{/each}}

### Regression Tests

{{#each regression_tests}}

#### TC-{{id}}: {{title}}

**Objective**: Ensure {{functionality}} still works (regression for issue #{{original_issue}})

**Type**: Regression

**Priority**: P0

**Original Bug**: #{{original_issue}} - {{bug_description}}

**Test Steps**:

1. Recreate original bug scenario
2. Verify bug does not reoccur
3. Verify fix still works

**Acceptance Criteria**:

- [ ] Original bug does not reappear
- [ ] Fix continues to work
- [ ] No new bugs introduced

---
{{/each}}

---

## Risk Assessment

### High-Risk Areas

**Risk 1**: {{risk_description}}

- **Impact**: High | Medium | Low
- **Probability**: High | Medium | Low
- **Mitigation**: {{mitigation_strategy}}
- **Test coverage**: TC-{{ids}}

**Risk 2**: {{risk_description}}

- **Impact**: {{impact}}
- **Probability**: {{probability}}
- **Mitigation**: {{mitigation}}
- **Test coverage**: TC-{{ids}}

### Test Coverage Gaps

**Known Gaps**:

1. {{gap_description}}
   - **Reason**: {{why_not_covered}}
   - **Mitigation**: {{mitigation}}
   - **Follow-up**: {{follow_up_plan}}

---

## Test Execution Strategy

### Test Phases

**Phase 1: Smoke Testing** (15 minutes)

- Quick validation of critical paths
- Ensures system is testable
- Tests: TC-001, TC-002, TC-005

**Phase 2: Functional Testing** (2-4 hours)

- Complete happy path validation
- Core functionality testing
- Tests: All P0 functional tests

**Phase 3: Edge Case & Error Testing** (2-3 hours)

- Boundary value testing
- Error condition validation
- Tests: All edge case and error tests

**Phase 4: Integration Testing** (1-2 hours)

- Component integration validation
- End-to-end workflow testing
- Tests: All integration tests

**Phase 5: Regression Testing** (1 hour)

- Verify no existing functionality broken
- Run previous bug reproduction tests
- Tests: All regression tests

**Phase 6: Cross-Platform Testing** (2-4 hours)

- Execute P0 tests on all platforms
- Execute P1 tests on primary platforms
- Document platform-specific issues

### Test Execution Order

**Recommended order**:

1. Smoke tests first (quick validation)
2. Happy path tests (core functionality)
3. Integration tests (component interaction)
4. Edge cases (boundary conditions)
5. Error conditions (negative testing)
6. Regression tests (no breakage)
7. Cross-platform validation (platform compatibility)

### Automation Strategy

**Automated Tests**:

- Installation scripts (via CI/CD)
- Template validation
- Linting and code quality
- Basic functionality checks

**Manual Tests**:

- User experience validation
- Visual/UI checks (for terminal output)
- Complex workflows
- Platform-specific behavior

---

## Acceptance Criteria

### Test Plan Acceptance

**Test plan is complete when**:

- [ ] All functional requirements have test coverage
- [ ] All high-risk areas have test scenarios
- [ ] Cross-platform matrix is defined
- [ ] Test data is prepared
- [ ] Test environment is documented

### Testing Complete When

**P0 (Critical) - Must Pass**:

- [ ] All P0 tests pass on macOS 13+
- [ ] All P0 tests pass on Ubuntu 22.04
- [ ] All P0 tests pass in Docker environment
- [ ] No critical bugs discovered
- [ ] All regression tests pass

**P1 (High) - Should Pass**:

- [ ] All P1 tests pass on primary platforms
- [ ] No high-severity bugs discovered
- [ ] Integration tests pass
- [ ] Documentation matches implementation

**P2 (Medium) - Nice to Have**:

- [ ] P2 tests pass where applicable
- [ ] No medium-severity bugs block release
- [ ] Optional platform testing complete

### Exit Criteria

**Testing can conclude when**:

1. All P0 acceptance criteria met
2. All P1 acceptance criteria met (or documented exceptions)
3. No outstanding critical or high bugs
4. Test report generated and reviewed
5. Sign-off from QA/stakeholders

---

## Test Data

### Sample Inputs

**Valid Inputs**:

```yaml
valid_input_1:
  description: "Standard configuration"
  data: |
    {{sample_data}}
  expected: {{expected_result}}

valid_input_2:
  description: "Alternative configuration"
  data: |
    {{sample_data}}
  expected: {{expected_result}}
```

**Invalid Inputs**:

```yaml
invalid_input_1:
  description: "Missing required field"
  data: |
    {{invalid_data}}
  expected_error: "Error: Required field 'X' is missing"

invalid_input_2:
  description: "Malformed data"
  data: |
    {{malformed_data}}
  expected_error: "Error: Invalid format"
```

### Edge Case Data

```yaml
edge_case_1:
  description: "Empty input"
  data: ""
  expected: {{behavior}}

edge_case_2:
  description: "Maximum size input"
  data: "{{large_data}}"
  expected: {{behavior}}
```

---

## Test Execution Tracking

### Test Results Template

```markdown
## Test Execution Results

**Executed By**: {{tester_name}}
**Date**: {{execution_date}}
**Platform**: {{platform}}
**Environment**: {{environment_details}}

### Summary

- **Total Tests**: {{total}}
- **Passed**: {{passed}}
- **Failed**: {{failed}}
- **Blocked**: {{blocked}}
- **Skipped**: {{skipped}}

### Test Results

| TC ID | Test Name | Status | Notes | Bug ID |
|-------|-----------|--------|-------|--------|
| TC-001 | {{name}} | Pass | - | - |
| TC-002 | {{name}} | Fail | {{failure_reason}} | BUG-123 |
| TC-003 | {{name}} | Blocked | {{blocker}} | - |
```

### Bug Tracking

**Bug Report Template**:

```markdown
### BUG-{{id}}: {{Title}}

**Severity**: Critical | High | Medium | Low

**Priority**: P0 | P1 | P2 | P3

**Test Case**: TC-{{id}}

**Platform**: {{platform}}

**Steps to Reproduce**:

1. {{step_1}}
2. {{step_2}}

**Expected Result**: {{expected}}

**Actual Result**: {{actual}}

**Impact**: {{user_impact}}

**Workaround**: {{workaround_if_available}}
```

---

## Test Schedule

### Timeline

**Test Plan Creation**: {{creation_date}}

**Test Environment Setup**: {{setup_date}}

**Test Execution**:

- Phase 1 (Smoke): {{date_range}}
- Phase 2 (Functional): {{date_range}}
- Phase 3 (Edge/Error): {{date_range}}
- Phase 4 (Integration): {{date_range}}
- Phase 5 (Regression): {{date_range}}
- Phase 6 (Cross-platform): {{date_range}}

**Test Report**: {{report_date}}

**Sign-off**: {{signoff_date}}

### Effort Estimation

**Total Estimated Effort**: {{total_hours}} hours

**Breakdown**:

- Test environment setup: {{hours}} hours
- Test execution: {{hours}} hours
- Bug investigation: {{hours}} hours
- Regression testing: {{hours}} hours
- Documentation: {{hours}} hours

---

## Dependencies

### Blockers

**Hard Dependencies**:

1. {{dependency_1}} - Must be complete before testing
2. {{dependency_2}} - Required for test environment

**Soft Dependencies**:

1. {{dependency_3}} - Testing can proceed with workaround
2. {{dependency_4}} - Nice to have, not blocking

### External Dependencies

- GitHub API (for issue loading)
- Docker Hub (for containerized testing)
- CI/CD system availability

---

## Test Report Template

After test execution, generate test report:

```markdown
---
title: "Test Report - {{Title}}"
test_plan: "{{test_plan_file}}"
executed_by: "{{tester}}"
execution_date: "{{date}}"
status: "{{pass|fail|partial}}"
---

# Test Execution Report: {{Title}}

## Executive Summary

**Overall Status**: {{PASS | FAIL | PARTIAL}}

**Summary**:

- Total test cases: {{total}}
- Passed: {{passed}} ({{percentage}}%)
- Failed: {{failed}} ({{percentage}}%)
- Blocked: {{blocked}}
- Skipped: {{skipped}}

**Recommendation**: {{APPROVE | REJECT | CONDITIONAL APPROVAL}}

## Platform Results

### macOS 13+

- **Status**: {{status}}
- **Tests Passed**: {{count}} / {{total}}
- **Critical Issues**: {{count}}

### Ubuntu 22.04

- **Status**: {{status}}
- **Tests Passed**: {{count}} / {{total}}
- **Critical Issues**: {{count}}

## Issues Discovered

### Critical Issues

1. **BUG-{{id}}**: {{description}}
   - **Impact**: {{impact}}
   - **Must fix**: Yes/No

### High Priority Issues

1. **BUG-{{id}}**: {{description}}
   - **Impact**: {{impact}}

## Recommendations

{{recommendations_for_release}}

---

**Report generated by qa-engineer agent**
**Timestamp**: {{timestamp}}
```

---

## Notes

- **Living Document**: This test plan should evolve as requirements change
- **Automation**: Automate tests where possible to enable CI/CD integration
- **Documentation**: Update test plan as bugs are found and fixed
- **Collaboration**: Share with development team for feedback

---

**Test Plan generated by qa-engineer agent**
**Created**: {{timestamp}}
**Status**: {{status}}

```text

---

### STEP 6: Display Summary

Output comprehensive summary to user:

```text
╔════════════════════════════════════════════════════════════════════════════╗
║                    ✓ TEST PLAN GENERATED                                   ║
╚════════════════════════════════════════════════════════════════════════════╝

Test Plan: {{title}}
Scope: {{scope}}
Issue: #{{issue_number}} (if applicable)

TEST COVERAGE:
───────────────────────────────────────────────────────────────────────────

  Total Test Cases: {{total_count}}
    • Happy Path: {{happy_path_count}}
    • Edge Cases: {{edge_case_count}}
    • Error Conditions: {{error_count}}
    • Integration: {{integration_count}}
    • Regression: {{regression_count}}

PLATFORMS:
───────────────────────────────────────────────────────────────────────────

  Primary (P0 required):
    • macOS 13+
    • Ubuntu 22.04
    • Docker

  Secondary (P1 recommended):
    • Ubuntu 20.04
    • Bash 4.x compatibility

PRIORITY BREAKDOWN:
───────────────────────────────────────────────────────────────────────────

  P0 (Critical): {{p0_count}} tests
  P1 (High): {{p1_count}} tests
  P2 (Medium): {{p2_count}} tests

ESTIMATED EFFORT:
───────────────────────────────────────────────────────────────────────────

  Test Execution: {{execution_hours}} hours
  Total Effort: {{total_hours}} hours

DOCUMENTATION:
───────────────────────────────────────────────────────────────────────────

  Test Plan: {{test_plan_path}}

NEXT STEPS:
───────────────────────────────────────────────────────────────────────────

  1. Review test plan for completeness
  2. Set up test environments
  3. Prepare test data
  4. Execute tests according to phases
  5. Generate test report

╚════════════════════════════════════════════════════════════════════════════╝
```

---

## Error Handling

### Missing Context

**If no issue provided and no active issue**:

- Prompt user for feature description
- Create test plan from description only

### Invalid Issue Number

**If issue doesn't exist**:

- Report error with clear message
- Suggest checking issue number
- Offer to create test plan without issue context

### Analysis Documents Not Found

**If PRD/TECH_SPEC missing**:

- Proceed with issue description only
- Warn that test coverage may be incomplete
- Suggest running `/expert-analysis` first for complex features

### Insufficient Information

**If critical information missing**:

- Prompt user interactively for missing details
- Don't proceed until minimum required information gathered
- Clearly indicate what information is needed

---

## Success Criteria

Test plan command succeeds when:

- [ ] Comprehensive test plan document generated
- [ ] All test scenarios documented with clear steps
- [ ] Acceptance criteria defined for each test
- [ ] Cross-platform matrix created
- [ ] Risk assessment completed
- [ ] Test execution strategy documented
- [ ] Test data defined
- [ ] File saved to appropriate location
- [ ] Summary displayed to user

---

## Integration with Workflow

### Position in Development Workflow

```text
/start-work → [/expert-analysis] → /test-plan → /implement → [execute tests] → /open-pr
```

### Related Commands

- `/expert-analysis` - Generate PRD/TECH_SPEC (provides better test plan input)
- `/implement` - Implementation command (test plan validates implementation)
- `/open-pr` - Create pull request (include test results in PR)

---

## Agent Delegation

**This command delegates all work to the `qa-engineer` agent.**

The qa-engineer agent is responsible for:

- Analyzing requirements for testability
- Identifying test scenarios
- Creating comprehensive test matrices
- Defining acceptance criteria
- Documenting test procedures
- Estimating testing effort
- Risk assessment
- Test report template generation

---

## Best Practices

### When to Use This Command

**Use `/test-plan` when**:

- Starting work on a new feature
- Complex functionality requires comprehensive testing
- Multiple platforms must be validated
- Integration points need testing
- Regression testing is critical
- Release testing is required

**Don't use `/test-plan` when**:

- Trivial change (simple fix)
- Tests are obvious and minimal
- Ad-hoc exploration only

### Tips for Effective Test Planning

1. **Run after `/expert-analysis`** for complex features
   - PRD/TECH_SPEC provide better requirements context
   - More comprehensive test coverage
   - Clearer acceptance criteria

2. **Review test matrix** for completeness
   - Verify all platforms covered
   - Check all components tested
   - Ensure edge cases identified

3. **Prioritize tests** appropriately
   - P0 for critical path
   - P1 for important features
   - P2 for nice-to-have validation

4. **Include regression tests**
   - Test previously fixed bugs
   - Verify core functionality unchanged
   - Catch unexpected breakage

5. **Update test plan** as requirements change
   - Living document, not one-time artifact
   - Track test results
   - Document discovered issues

---

## Notes

- **Interactive**: Prompts for missing information before generating plan
- **Comprehensive**: Covers happy path, edge cases, errors, integration, regression
- **Cross-platform**: Defines platform-specific test requirements
- **Actionable**: Provides clear test steps and acceptance criteria
- **Trackable**: Includes test execution and results tracking templates
