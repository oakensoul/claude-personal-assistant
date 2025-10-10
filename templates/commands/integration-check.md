---
name: integration-check
description: Verify external integrations and their configurations
model: sonnet
args:
  integration:
    description: Specific integration to check - "obsidian", "stow", "mcp", "git-hooks", "all" (default)
    required: false
---

# Integration Health Check Command

Verify external integrations (Obsidian, GNU Stow, MCP servers, Git hooks) are properly configured and functioning. This command validates connectivity, configuration, and common issues across AIDA's integration points.

## Usage

```bash
# Check all integrations (default)
/integration-check
/integration-check all

# Check specific integration
/integration-check obsidian
/integration-check stow
/integration-check mcp
/integration-check git-hooks
```

## Overview

The `/integration-check` command ensures AIDA's external integrations are healthy and properly configured. It validates:

**When to run:**

- After initial AIDA installation
- After system updates or configuration changes
- When experiencing integration issues
- As part of regular maintenance (monthly)
- Before important workflows that depend on integrations

**Expected duration:** <2 minutes for all checks, <30 seconds per integration

## Integration Scopes

### Obsidian

Validates Obsidian vault integration:

- Vault directory exists and is accessible
- Daily note template is present
- Required directories exist (daily-notes, projects, dashboards)
- AIDA dashboard file is valid
- File permissions allow read/write
- Obsidian configuration files are valid

### GNU Stow

Validates dotfiles management via GNU Stow:

- GNU Stow is installed
- Package directories exist (dotfiles, dotfiles-private)
- Symlinks are healthy (not broken)
- No conflicts exist between packages
- Stow package structure is valid
- AIDA integration files are properly linked

### MCP Servers

Validates Model Context Protocol servers:

- MCP server configuration file exists
- Server definitions are valid JSON
- Server executables are accessible
- Servers can be started (connectivity test)
- Required environment variables are set
- Tool availability from each server

### Git Hooks

Validates Git hook integration:

- Git hooks directory exists
- Required hooks are installed (pre-commit, commit-msg, etc.)
- Hook scripts have execute permissions
- Hook scripts are not broken symlinks
- Hook functionality test (dry-run validation)
- Hook configuration is valid

## Workflow

### Step 1: Parse Integration Argument

Determine which integration(s) to check:

```bash
INTEGRATION="${1:-all}"

case "$INTEGRATION" in
  all|obsidian|stow|mcp|git-hooks)
    echo "Running integration check for: $INTEGRATION"
    ;;
  *)
    echo "Error: Invalid integration '$INTEGRATION'"
    echo "Valid options: obsidian, stow, mcp, git-hooks, all"
    exit 1
    ;;
esac
```

### Step 2: Create Check Directory

Set up working directory for check results:

```bash
CHECK_DATE=$(date -u +"%Y-%m-%d")
CHECK_DIR="{{CLAUDE_CONFIG_DIR}}/integration-checks/${CHECK_DATE}"
mkdir -p "$CHECK_DIR"

echo "Integration health check: $CHECK_DATE"
echo "Results: $CHECK_DIR"
echo ""
```

### Step 3: Invoke Integration Specialist Agent

Delegate integration checking to the `integration-specialist` agent:

```markdown
Invoke the **integration-specialist** agent with the following task:

Task: Verify integration health for: {integration}

For each integration in scope, perform comprehensive validation:

## Obsidian Integration Check

**Directory Validation:**

1. Check vault directory exists: `{{HOME}}/Documents/Obsidian/AIDA/` (or configured location)
2. Verify directory permissions (read/write access)
3. Validate required subdirectories exist:
   - `daily-notes/`
   - `projects/`
   - `dashboards/`
   - `templates/`

**Template Validation:**

1. Daily note template exists: `templates/daily-note.md`
2. Template contains required frontmatter fields
3. Template variables are valid ({{date}}, {{time}}, etc.)
4. Template is not corrupted (valid markdown)

**Dashboard Validation:**

1. AIDA dashboard exists: `dashboards/AIDA-Dashboard.md`
2. Dashboard has valid structure
3. Dashboard dataview queries are syntactically valid
4. Dashboard links are not broken

**Configuration Validation:**

1. Check `.obsidian/` directory exists
2. Validate `app.json` configuration
3. Check for required plugins (Dataview, Templater)
4. Verify plugin configurations

**Common Issues Detection:**

- Vault directory moved or deleted
- Permission errors (read-only filesystem)
- Template variables not resolving
- Missing required plugins
- Broken internal links

**Remediation Steps:**

Provide specific fix commands for each detected issue.

## GNU Stow Integration Check

**Installation Validation:**

1. Check GNU Stow is installed: `command -v stow`
2. Verify Stow version: `stow --version`
3. Check Stow is accessible in PATH

**Package Structure Validation:**

1. Check dotfiles directory exists: `{{HOME}}/dotfiles/`
2. Verify package structure (directories like `shell/.bashrc`, etc.)
3. Check for stow-local-ignore file
4. Validate package organization (one level deep)

**Symlink Health Check:**

1. List all stowed packages: `stow -n -v -t {{HOME}} -d {{HOME}}/dotfiles *`
2. Detect broken symlinks in home directory
3. Identify conflicts (files that would be overwritten)
4. Verify AIDA integration symlinks are healthy:
   - `{{HOME}}/CLAUDE.md` → dotfiles source
   - `{{HOME}}/.aida/` → installation directory

**Conflict Detection:**

1. Run dry-run stow to detect conflicts
2. Identify files blocking stow operations
3. List files that need manual resolution

**Common Issues Detection:**

- GNU Stow not installed
- Dotfiles directory missing
- Broken symlinks in home directory
- Stow conflicts preventing operations
- Wrong package structure (too many levels)

**Remediation Steps:**

Provide specific fix commands for each detected issue.

## MCP Server Integration Check

**Configuration Validation:**

1. Check MCP config exists: `{{CLAUDE_CONFIG_DIR}}/mcp/config.json`
2. Validate JSON syntax
3. Check server definitions are complete (name, command, args)
4. Verify environment variables are defined

**Server Availability:**

1. For each configured server:
   - Check executable exists and is accessible
   - Verify required dependencies are installed
   - Test server can be invoked (dry-run or health check)

**Connectivity Test:**

1. Attempt to start each MCP server
2. Verify server responds to health check
3. List available tools from each server
4. Test basic tool invocation (non-destructive)

**Environment Validation:**

1. Check required environment variables:
   - `MCP_SERVER_PATH` (if applicable)
   - Server-specific env vars (API keys, etc.)
2. Verify environment variables are set correctly

**Common Issues Detection:**

- MCP config file missing or invalid JSON
- Server executables not found
- Missing dependencies (Python packages, Node modules)
- Environment variables not set
- Server startup failures
- Network connectivity issues

**Remediation Steps:**

Provide specific fix commands for each detected issue.

## Git Hooks Integration Check

**Hook Installation Validation:**

1. Check Git hooks directory exists: `.git/hooks/`
2. Verify required hooks are installed:
   - `pre-commit`
   - `commit-msg`
   - `prepare-commit-msg` (optional)
   - `post-commit` (optional)
3. Check hook scripts have execute permissions: `chmod +x`

**Symlink Health Check:**

1. Identify hooks that are symlinks
2. Verify symlink targets exist
3. Detect broken symlinks

**Hook Functionality Test:**

1. Run pre-commit hook in dry-run mode
2. Validate commit-msg hook logic (test with sample message)
3. Check hook scripts don't have syntax errors

**Configuration Validation:**

1. Check `.pre-commit-config.yaml` exists (if using pre-commit framework)
2. Validate hook configuration syntax
3. Verify hook dependencies are installed

**Common Issues Detection:**

- Git hooks directory missing (not in git repository)
- Required hooks not installed
- Hooks missing execute permissions
- Broken symlinks to hook scripts
- Hook scripts have syntax errors
- Pre-commit framework not installed
- Hook dependencies missing

**Remediation Steps:**

Provide specific fix commands for each detected issue.

## Output Format

For each integration, generate a health report:

```markdown
# Integration: {integration_name}

## Status: ✓ Healthy | ⚠ Warning | ✗ Unhealthy

## Checks Performed

- [x] Check 1: Description - PASS
- [x] Check 2: Description - PASS
- [ ] Check 3: Description - FAIL (reason)
- [~] Check 4: Description - WARNING (reason)

## Issues Detected

### Issue 1: {title}

- **Severity**: Critical/High/Medium/Low
- **Description**: What is wrong
- **Impact**: What doesn't work because of this
- **Remediation**:

  ```bash
  # Specific commands to fix
  command-to-fix
  ```

### Issue 2: {title}

...

## Summary

- Total checks: {count}
- Passed: {count}
- Warnings: {count}
- Failures: {count}

## Overall Health: {percentage}%
```

Save report to: `{{CLAUDE_CONFIG_DIR}}/integration-checks/{date}/{integration}-health-report.md`
```

### Step 4: Aggregate Results

Collect results from all integration checks:

```bash
echo ""
echo "═══════════════════════════════════════════════════════════════════════"
echo "Integration Health Summary"
echo "═══════════════════════════════════════════════════════════════════════"

TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNING_CHECKS=0

# Parse each integration report
for report in "$CHECK_DIR"/*-health-report.md; do
  if [ -f "$report" ]; then
    INTEGRATION_NAME=$(basename "$report" -health-report.md)

    # Extract check counts (parse markdown checkboxes)
    CHECKS=$(grep -c "^- \[.\]" "$report" || echo "0")
    PASS=$(grep -c "^- \[x\]" "$report" || echo "0")
    FAIL=$(grep -c "^- \[ \]" "$report" || echo "0")
    WARN=$(grep -c "^- \[~\]" "$report" || echo "0")

    TOTAL_CHECKS=$((TOTAL_CHECKS + CHECKS))
    PASSED_CHECKS=$((PASSED_CHECKS + PASS))
    FAILED_CHECKS=$((FAILED_CHECKS + FAIL))
    WARNING_CHECKS=$((WARNING_CHECKS + WARN))

    # Determine status icon
    if [ "$FAIL" -gt 0 ]; then
      STATUS="✗"
    elif [ "$WARN" -gt 0 ]; then
      STATUS="⚠"
    else
      STATUS="✓"
    fi

    echo "  $STATUS $INTEGRATION_NAME: $PASS/$CHECKS passed, $WARN warnings, $FAIL failures"
  fi
done

echo ""
echo "Overall Statistics:"
echo "  Total checks: $TOTAL_CHECKS"
echo "  Passed: $PASSED_CHECKS"
echo "  Warnings: $WARNING_CHECKS"
echo "  Failures: $FAILED_CHECKS"

# Calculate health percentage
if [ "$TOTAL_CHECKS" -gt 0 ]; then
  HEALTH_PCT=$((100 * PASSED_CHECKS / TOTAL_CHECKS))
  echo "  Health: ${HEALTH_PCT}%"
fi
```

### Step 5: Display Remediation Actions

Show actionable next steps:

```bash
echo ""
echo "═══════════════════════════════════════════════════════════════════════"
echo "Remediation Actions"
echo "═══════════════════════════════════════════════════════════════════════"

if [ "$FAILED_CHECKS" -gt 0 ]; then
  echo ""
  echo "⚠ Issues detected requiring immediate attention:"
  echo ""

  # Extract remediation steps from reports
  for report in "$CHECK_DIR"/*-health-report.md; do
    if [ -f "$report" ]; then
      INTEGRATION_NAME=$(basename "$report" -health-report.md)

      # Check if report has failures
      if grep -q "^- \[ \]" "$report"; then
        echo "  $INTEGRATION_NAME:"

        # Extract issue titles and remediation commands
        # (Simplified - real implementation would parse markdown more carefully)
        grep -A 10 "^### Issue" "$report" | grep -A 5 "Remediation:" | grep "^\s*\`" | sed 's/^/    /'
        echo ""
      fi
    fi
  done

  echo "Review detailed reports: $CHECK_DIR/"
  echo ""
else
  echo ""
  echo "✓ All integrations healthy - no action required"
  echo ""
fi
```

### Step 6: Exit with Appropriate Status

Set exit code based on check results:

```bash
# Exit status codes:
# 0 = All integrations healthy
# 1 = Warnings detected (some checks failed but not critical)
# 2 = Critical failures detected
# 3 = Error running checks

if [ "$FAILED_CHECKS" -gt 0 ]; then
  echo "Exit status: FAILURES DETECTED (exit 2)"
  exit 2
elif [ "$WARNING_CHECKS" -gt 0 ]; then
  echo "Exit status: WARNINGS DETECTED (exit 1)"
  exit 1
else
  echo "Exit status: ALL HEALTHY (exit 0)"
  exit 0
fi
```

## Exit Status Codes

The command uses these exit codes for automation:

- **0** - All integrations healthy, no issues detected
- **1** - Warnings detected (non-critical issues)
- **2** - Critical failures detected (integrations broken)
- **3** - Error running checks (command failure)

### Usage in Automation

```bash
# Weekly health check
if ! /integration-check; then
  echo "Integration issues detected!"
  # Send notification
fi

# Pre-flight check before workflow
/integration-check || {
  echo "ERROR: Integrations not healthy"
  echo "Run: /integration-check for details"
  exit 1
}

# Check specific integration
/integration-check obsidian && echo "Obsidian integration OK"
```

## Examples

### Example 1: All Integrations Check

```bash
/integration-check

# Output:
Integration health check: 2025-10-09
Results: {{CLAUDE_CONFIG_DIR}}/integration-checks/2025-10-09

Checking Obsidian integration...
✓ Vault directory exists
✓ Daily note template valid
✓ Dashboard file present
✓ Required directories exist
⚠ Warning: Dataview plugin not installed

Checking GNU Stow integration...
✓ GNU Stow installed (v2.3.1)
✓ Dotfiles directory exists
✓ Package structure valid
✓ No broken symlinks detected
✓ No conflicts detected

Checking MCP servers...
✓ MCP config valid
✓ Server 'filesystem' available
✓ Server 'obsidian' available
✗ Server 'github' - connection failed (API key not set)

Checking Git hooks...
✓ Hooks directory exists
✓ pre-commit hook installed
✓ commit-msg hook installed
✓ Hooks have execute permissions
✓ Hook functionality test passed

═══════════════════════════════════════════════════════════════════════
Integration Health Summary
═══════════════════════════════════════════════════════════════════════
  ⚠ obsidian: 4/5 passed, 1 warnings, 0 failures
  ✓ stow: 5/5 passed, 0 warnings, 0 failures
  ✗ mcp: 2/3 passed, 0 warnings, 1 failures
  ✓ git-hooks: 5/5 passed, 0 warnings, 0 failures

Overall Statistics:
  Total checks: 18
  Passed: 16
  Warnings: 1
  Failures: 1
  Health: 89%

═══════════════════════════════════════════════════════════════════════
Remediation Actions
═══════════════════════════════════════════════════════════════════════

⚠ Issues detected requiring immediate attention:

  mcp:
    # Set GitHub API token
    export GITHUB_TOKEN="your-token-here"
    # Or add to ~/.bashrc for persistence
    echo 'export GITHUB_TOKEN="your-token-here"' >> ~/.bashrc

Review detailed reports: {{CLAUDE_CONFIG_DIR}}/integration-checks/2025-10-09/

Exit status: FAILURES DETECTED (exit 2)
```

### Example 2: Obsidian-Only Check

```bash
/integration-check obsidian

# Output:
Integration health check: 2025-10-09
Results: {{CLAUDE_CONFIG_DIR}}/integration-checks/2025-10-09

Checking Obsidian integration...
✓ Vault directory exists: {{HOME}}/Documents/Obsidian/AIDA/
✓ Vault permissions: read/write OK
✓ Required directories present:
  - daily-notes/
  - projects/
  - dashboards/
  - templates/
✓ Daily note template: templates/daily-note.md (valid)
✓ AIDA dashboard: dashboards/AIDA-Dashboard.md (valid)
✓ Obsidian config directory exists
✓ app.json configuration valid
✓ Dataview plugin installed (v0.5.64)
✓ Templater plugin installed (v1.18.3)
✓ No broken internal links detected

═══════════════════════════════════════════════════════════════════════
Integration Health Summary
═══════════════════════════════════════════════════════════════════════
  ✓ obsidian: 10/10 passed, 0 warnings, 0 failures

Overall Statistics:
  Total checks: 10
  Passed: 10
  Warnings: 0
  Failures: 0
  Health: 100%

✓ All integrations healthy - no action required

Exit status: ALL HEALTHY (exit 0)
```

### Example 3: GNU Stow with Conflicts

```bash
/integration-check stow

# Output:
Integration health check: 2025-10-09
Results: {{CLAUDE_CONFIG_DIR}}/integration-checks/2025-10-09

Checking GNU Stow integration...
✓ GNU Stow installed: v2.3.1
✓ Dotfiles directory: {{HOME}}/dotfiles/
✓ Package structure valid
✗ Symlink conflict detected: .bashrc
  - Existing file: {{HOME}}/.bashrc
  - Would link to: {{HOME}}/dotfiles/shell/.bashrc
  - Resolution: Move or backup existing file
✓ AIDA symlinks healthy:
  - {{HOME}}/CLAUDE.md → {{HOME}}/dotfiles/aida/CLAUDE.md

═══════════════════════════════════════════════════════════════════════
Integration Health Summary
═══════════════════════════════════════════════════════════════════════
  ✗ stow: 4/5 passed, 0 warnings, 1 failures

Overall Statistics:
  Total checks: 5
  Passed: 4
  Warnings: 0
  Failures: 1
  Health: 80%

═══════════════════════════════════════════════════════════════════════
Remediation Actions
═══════════════════════════════════════════════════════════════════════

⚠ Issues detected requiring immediate attention:

  stow:
    # Backup conflicting file
    mv {{HOME}}/.bashrc {{HOME}}/.bashrc.backup

    # Re-stow package
    cd {{HOME}}/dotfiles
    stow -v shell

    # Or merge with existing file (manual)
    # Compare: diff {{HOME}}/.bashrc {{HOME}}/dotfiles/shell/.bashrc

Exit status: FAILURES DETECTED (exit 2)
```

## Notes

- **Non-destructive checks**: No modifications made during checks
- **Dry-run validation**: Integration checks use dry-run/test modes where possible
- **Detailed reports**: Each integration generates standalone health report
- **Actionable remediation**: Specific commands provided for each issue
- **Exit codes**: Supports automation and scripting
- **Agent delegation**: Uses integration-specialist agent for expertise

## Agent Integration

This command invokes the **integration-specialist** agent for:

- Integration-specific knowledge and best practices
- Connectivity testing and validation
- Issue detection and diagnosis
- Remediation command generation
- Health report creation

## Related Commands

- `/create-agent integration-specialist` - Create integration-specialist agent if missing
- None (this is a new standalone command)

## Troubleshooting

**Issue**: "integration-specialist agent not found"

- **Fix**: Run `/create-agent integration-specialist` to create the agent

**Issue**: Permission errors accessing directories

- **Fix**: Check directory permissions: `ls -ld {{CLAUDE_CONFIG_DIR}}`

**Issue**: MCP servers fail connectivity tests

- **Fix**: Check environment variables and server dependencies

**Issue**: Reports directory not created

- **Fix**: Command auto-creates directory, check filesystem permissions

---

**Design Philosophy**: Provide comprehensive, automated health checks for all AIDA external integrations with actionable remediation steps to maintain system reliability.
