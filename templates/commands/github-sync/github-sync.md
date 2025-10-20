---
name: github-sync
description: Verify and sync GitHub configuration (labels, config, automations)
args:
  mode:
    description: "check (default), fix, report"
    required: false
version: 1.0.0
category: workflow
---

# GitHub Configuration Sync Command

Verify and synchronize GitHub configuration against the specification defined in `workflow-config.json`. Detects drift, validates configuration, and can auto-fix common issues.

## Overview

The `/github-sync` command ensures your GitHub repository configuration matches the documented specification. It verifies labels, validates configuration files, checks cache freshness, and detects symptoms of missing automations.

**When to run:**

- Weekly as part of maintenance routine
- After manual GitHub configuration changes
- Before important PR workflows
- When label-related issues are reported
- After updating `workflow-config.json`

**Expected duration:** <30 seconds for check mode, <60 seconds for fix mode

## Modes of Operation

### check (default)

Non-destructive verification mode:

- Verify labels exist with correct colors and descriptions
- Check workflow-config.json validity
- Verify verification cache freshness (<30 days)
- Report discrepancies without making changes
- Exit with status code (0=synced, 1=drift detected)

**Usage:**

```bash
/github-sync
/github-sync check
```

### fix

Auto-remediation mode:

- Run all check mode verifications first
- Auto-fix label colors and descriptions
- Create missing labels
- Update verification cache
- Report what was fixed
- Exit with status code (2=fixes applied, 0=no fixes needed)

**Usage:**

```bash
/github-sync fix
```

### report

Detailed analysis mode:

- Generate comprehensive drift report
- Show all differences in detail with full context
- Suggest manual remediation steps
- Update verification cache timestamp
- Save report to `.github/reports/drift-report-{timestamp}.md`
- Exit with status code (0=synced, 1=drift detected)

**Usage:**

```bash
/github-sync report
```

## Implementation Workflow

### Step 1: Parse Mode Argument

```bash
MODE="${1:-check}"

case "$MODE" in
  check|fix|report)
    echo "Running github-sync in '$MODE' mode..."
    ;;
  *)
    echo "Error: Invalid mode '$MODE'. Use: check, fix, or report"
    exit 4
    ;;
esac
```

### Step 2: Verify Prerequisites

Check required tools and files exist:

```bash
# Check gh CLI
if ! command -v gh &> /dev/null; then
  echo "Error: GitHub CLI (gh) not installed"
  echo "Install: brew install gh"
  exit 4
fi

# Check jq
if ! command -v jq &> /dev/null; then
  echo "Error: jq not installed"
  echo "Install: brew install jq"
  exit 4
fi

# Check workflow-config.json exists
if [ ! -f ".claude/config/workflow-config.json" ]; then
  echo "Error: workflow-config.json not found"
  echo "Expected location: .claude/config/workflow-config.json"
  exit 4
fi

# Check verification cache exists
if [ ! -f ".github/.verification-cache.json" ]; then
  echo "Warning: Verification cache not found"
  echo "Creating new cache..."
  mkdir -p .github
  echo '{"last_verified": null, "labels": {}, "config": {}}' > .github/.verification-cache.json
fi

# Ensure reports directory exists
mkdir -p .github/reports
```

### Step 3: Load Configuration

Extract expected configuration from workflow-config.json:

```bash
CONFIG_FILE=".claude/config/workflow-config.json"

# Extract label arrays
VERSION_LABELS=$(jq -r '.github.labels.version_labels[]' "$CONFIG_FILE")
BUILD_LABELS=$(jq -r '.github.labels.build_labels[]' "$CONFIG_FILE")
BUILD_OVERRIDE_LABELS=$(jq -r '.github.labels.build_override_labels[]' "$CONFIG_FILE")

# Build complete expected labels list with colors and descriptions
# Version labels
EXPECTED_LABELS='[]'
EXPECTED_LABELS=$(jq -n '
  [
    {name: "version:patch", color: "0366d6", description: "Patch version bump (bug fixes)"},
    {name: "version:minor", color: "0052cc", description: "Minor version bump (features)"},
    {name: "version:major", color: "003d99", description: "Major version bump (breaking)"},
    {name: "build:surgical", color: "0e8a16", description: "Build only changed models"},
    {name: "build:domain", color: "22863a", description: "Build entire domain"},
    {name: "build:full", color: "2ea44f", description: "Full warehouse rebuild"},
    {name: "build:critical", color: "168f3d", description: "Critical models only"},
    {name: "build:validation", color: "1c7f37", description: "Validation build"},
    {name: "override:no-build", color: "b60205", description: "Skip dbt build"},
    {name: "override:no-test", color: "d93f0b", description: "Skip dbt tests"},
    {name: "override:no-version", color: "e99695", description: "Skip version bump"}
  ]
')

# Also extract from config dynamically for future-proofing
# (In case labels are added to config without updating this command)

echo "Loaded configuration from $CONFIG_FILE"
echo "Expected labels: $(echo "$EXPECTED_LABELS" | jq 'length')"
```

### Step 4: Fetch Current GitHub State

Retrieve actual labels from GitHub:

```bash
echo "Fetching current GitHub labels..."

# Get all labels with details
gh label list --json name,color,description --limit 1000 > /tmp/github-labels-$$.json

ACTUAL_LABEL_COUNT=$(jq 'length' /tmp/github-labels-$$.json)
echo "Found $ACTUAL_LABEL_COUNT labels in GitHub"
```

### Step 5: Check 1 - Label Configuration Verification

Compare expected vs actual labels:

```bash
echo ""
echo "═══════════════════════════════════════════════════════════════════════"
echo "Check 1: Label Configuration"
echo "═══════════════════════════════════════════════════════════════════════"

MISSING_LABELS=()
COLOR_MISMATCHES=()
DESCRIPTION_MISMATCHES=()
OK_LABELS=()

# Check each expected label
while IFS= read -r label; do
  NAME=$(echo "$label" | jq -r '.name')
  EXPECTED_COLOR=$(echo "$label" | jq -r '.color')
  EXPECTED_DESC=$(echo "$label" | jq -r '.description')

  # Find label in actual GitHub labels
  ACTUAL=$(jq --arg name "$NAME" '.[] | select(.name == $name)' /tmp/github-labels-$$.json)

  if [ -z "$ACTUAL" ]; then
    # Label missing
    MISSING_LABELS+=("$label")
    echo "  ✗ $NAME - MISSING"
  else
    # Label exists, check color and description
    ACTUAL_COLOR=$(echo "$ACTUAL" | jq -r '.color')
    ACTUAL_DESC=$(echo "$ACTUAL" | jq -r '.description')

    HAS_ISSUE=false
    ISSUES=""

    # Check color (case-insensitive, normalize)
    if [ "${EXPECTED_COLOR,,}" != "${ACTUAL_COLOR,,}" ]; then
      COLOR_MISMATCHES+=("$NAME|$EXPECTED_COLOR|$ACTUAL_COLOR")
      HAS_ISSUE=true
      ISSUES="Color: expected #$EXPECTED_COLOR, got #$ACTUAL_COLOR"
    fi

    # Check description (optional - some labels may not have descriptions)
    if [ -n "$EXPECTED_DESC" ] && [ "$EXPECTED_DESC" != "$ACTUAL_DESC" ]; then
      DESCRIPTION_MISMATCHES+=("$NAME|$EXPECTED_DESC|$ACTUAL_DESC")
      if [ "$HAS_ISSUE" = true ]; then
        ISSUES="$ISSUES; Description mismatch"
      else
        HAS_ISSUE=true
        ISSUES="Description mismatch"
      fi
    fi

    if [ "$HAS_ISSUE" = true ]; then
      echo "  ✗ $NAME - $ISSUES"
    else
      OK_LABELS+=("$NAME")
      echo "  ✓ $NAME - OK"
    fi
  fi
done < <(echo "$EXPECTED_LABELS" | jq -c '.[]')

# Summary
echo ""
echo "Label Verification Summary:"
echo "───────────────────────────────────────────────────────────────────────"
echo "  Found: ${#OK_LABELS[@]}/$(echo "$EXPECTED_LABELS" | jq 'length') labels OK"
echo "  Missing: ${#MISSING_LABELS[@]} labels"
echo "  Color mismatches: ${#COLOR_MISMATCHES[@]}"
echo "  Description mismatches: ${#DESCRIPTION_MISMATCHES[@]}"

if [ ${#MISSING_LABELS[@]} -eq 0 ] && [ ${#COLOR_MISMATCHES[@]} -eq 0 ]; then
  echo "  Status: ✓ SYNCED"
  LABELS_STATUS="synced"
else
  echo "  Status: ✗ DRIFT DETECTED"
  LABELS_STATUS="drift"
fi
```

### Step 6: Check 2 - Configuration File Validation

Validate workflow-config.json structure:

```bash
echo ""
echo "═══════════════════════════════════════════════════════════════════════"
echo "Check 2: Configuration File Validation"
echo "═══════════════════════════════════════════════════════════════════════"

CONFIG_VALID=true

# Check JSON syntax
if ! jq empty "$CONFIG_FILE" 2>/dev/null; then
  echo "  ✗ JSON syntax invalid"
  CONFIG_VALID=false
else
  echo "  ✓ JSON syntax valid"
fi

# Check required sections exist
if jq -e '.github' "$CONFIG_FILE" >/dev/null 2>&1; then
  echo "  ✓ github section exists"
else
  echo "  ✗ github section missing"
  CONFIG_VALID=false
fi

if jq -e '.github.labels' "$CONFIG_FILE" >/dev/null 2>&1; then
  echo "  ✓ labels section exists"
else
  echo "  ✗ labels section missing"
  CONFIG_VALID=false
fi

if jq -e '.github.project' "$CONFIG_FILE" >/dev/null 2>&1; then
  echo "  ✓ project section exists"
else
  echo "  ✗ project section missing"
  CONFIG_VALID=false
fi

# Check issue type mappings (should have 8)
MAPPING_COUNT=$(jq '.github.labels.issue_to_pr_mapping | length' "$CONFIG_FILE" 2>/dev/null || echo "0")
if [ "$MAPPING_COUNT" -eq 8 ]; then
  echo "  ✓ 8/8 issue type mappings defined"
else
  echo "  ✗ Expected 8 issue type mappings, found $MAPPING_COUNT"
  CONFIG_VALID=false
fi

# Check build logic exists
if jq -e '.github.build_logic' "$CONFIG_FILE" >/dev/null 2>&1; then
  echo "  ✓ build_logic section exists"
else
  echo "  ✗ build_logic section missing"
  CONFIG_VALID=false
fi

echo ""
if [ "$CONFIG_VALID" = true ]; then
  echo "  Status: ✓ VALID"
  CONFIG_STATUS="valid"
else
  echo "  Status: ✗ INVALID"
  CONFIG_STATUS="invalid"
fi
```

### Step 7: Check 3 - Verification Cache Freshness

Check cache age and validity:

```bash
echo ""
echo "═══════════════════════════════════════════════════════════════════════"
echo "Check 3: Verification Cache Freshness"
echo "═══════════════════════════════════════════════════════════════════════"

CACHE_FILE=".github/.verification-cache.json"
CURRENT_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

LAST_VERIFIED=$(jq -r '.last_verified // "null"' "$CACHE_FILE")

if [ "$LAST_VERIFIED" = "null" ] || [ -z "$LAST_VERIFIED" ]; then
  echo "  Cache never verified"
  echo "  Status: ⚠ STALE (never verified)"
  CACHE_STATUS="stale"
  CACHE_AGE_DAYS=999
else
  # Calculate age in days (cross-platform compatible)
  if date --version >/dev/null 2>&1; then
    # GNU date (Linux)
    LAST_EPOCH=$(date -d "$LAST_VERIFIED" +%s)
    CURRENT_EPOCH=$(date -d "$CURRENT_TIME" +%s)
  else
    # BSD date (macOS)
    LAST_EPOCH=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$LAST_VERIFIED" +%s)
    CURRENT_EPOCH=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$CURRENT_TIME" +%s)
  fi

  CACHE_AGE_DAYS=$(( ($CURRENT_EPOCH - $LAST_EPOCH) / 86400 ))

  echo "  Last verified: $LAST_VERIFIED ($CACHE_AGE_DAYS days ago)"
  echo "  Location: $CACHE_FILE"

  if [ "$CACHE_AGE_DAYS" -gt 30 ]; then
    echo "  Status: ⚠ STALE (>30 days)"
    CACHE_STATUS="stale"
  else
    echo "  Status: ✓ FRESH"
    CACHE_STATUS="fresh"
  fi
fi
```

### Step 8: Check 4 - Symptom Detection

Detect symptoms of missing manual automations:

```bash
echo ""
echo "═══════════════════════════════════════════════════════════════════════"
echo "Check 4: Symptom Detection (Manual Automation Checks)"
echo "═══════════════════════════════════════════════════════════════════════"

# Check for issues without project assignment (symptom of missing auto-add)
echo "  Checking for unassigned issues..."
UNASSIGNED_ISSUES=$(gh issue list --json number,projectItems --jq '[.[] | select(.projectItems | length == 0)] | length' 2>/dev/null || echo "0")

if [ "$UNASSIGNED_ISSUES" -gt 5 ]; then
  echo "  ⚠ $UNASSIGNED_ISSUES issues not assigned to project"
  echo "    Possible cause: Missing 'Auto-add to project' automation"
  echo "    Fix: Configure in Project → Settings → Workflows"
  SYMPTOMS_DETECTED=true
else
  echo "  ✓ Issue project assignment looks healthy ($UNASSIGNED_ISSUES unassigned)"
  SYMPTOMS_DETECTED=false
fi

echo ""
echo "  Manual verification recommended for:"
echo "    • Workflow automations (10 rules in specification)"
echo "    • Branch protection rules"
echo "    • Project status transitions"
echo ""

if [ "$LAST_VERIFIED" = "null" ] || [ -z "$LAST_VERIFIED" ]; then
  echo "  Last manual verification: Never"
else
  echo "  Last manual verification: $LAST_VERIFIED"
fi

echo "  Recommendation: Update cache with: /github-init verify"
```

### Step 9: Determine Overall Status

Calculate overall drift status:

```bash
echo ""
echo "═══════════════════════════════════════════════════════════════════════"
echo "Overall Status"
echo "═══════════════════════════════════════════════════════════════════════"

DRIFT_DETECTED=false

if [ "$LABELS_STATUS" != "synced" ]; then
  DRIFT_DETECTED=true
  echo "  ✗ Labels: $LABELS_STATUS"
else
  echo "  ✓ Labels: $LABELS_STATUS"
fi

if [ "$CONFIG_STATUS" != "valid" ]; then
  DRIFT_DETECTED=true
  echo "  ✗ Configuration: $CONFIG_STATUS"
else
  echo "  ✓ Configuration: $CONFIG_STATUS"
fi

if [ "$CACHE_STATUS" != "fresh" ]; then
  echo "  ⚠ Cache: $CACHE_STATUS"
  # Don't count stale cache as drift, just a warning
fi

if [ "$SYMPTOMS_DETECTED" = true ]; then
  echo "  ⚠ Automation symptoms detected"
fi

echo ""
if [ "$DRIFT_DETECTED" = true ]; then
  echo "  Overall: ✗ DRIFT DETECTED"
  OVERALL_STATUS="drift"
else
  echo "  Overall: ✓ SYNCED"
  OVERALL_STATUS="synced"
fi
```

### Step 10: Execute Mode-Specific Actions

Handle each mode appropriately:

#### Check Mode

```bash
if [ "$MODE" = "check" ]; then
  echo ""
  echo "═══════════════════════════════════════════════════════════════════════"
  echo "Check Mode: Verification Complete"
  echo "═══════════════════════════════════════════════════════════════════════"

  if [ "$DRIFT_DETECTED" = true ]; then
    echo ""
    echo "Recommended actions:"
    echo "  • Run '/github-sync fix' to auto-fix label issues"
    echo "  • Run '/github-sync report' for detailed analysis"
    echo "  • Review .claude/config/workflow-config.json"
    echo ""

    # Update cache with drift status
    jq --arg time "$CURRENT_TIME" \
       --arg status "$OVERALL_STATUS" \
       '.last_verified = $time | .status = $status' \
       "$CACHE_FILE" > "$CACHE_FILE.tmp" && mv "$CACHE_FILE.tmp" "$CACHE_FILE"

    # Cleanup
    rm -f /tmp/github-labels-$$.json

    exit 1  # Drift detected
  else
    echo ""
    echo "No action needed. Configuration is synced."
    echo ""

    # Update cache with synced status
    jq --arg time "$CURRENT_TIME" \
       --arg status "$OVERALL_STATUS" \
       '.last_verified = $time | .status = $status' \
       "$CACHE_FILE" > "$CACHE_FILE.tmp" && mv "$CACHE_FILE.tmp" "$CACHE_FILE"

    # Cleanup
    rm -f /tmp/github-labels-$$.json

    exit 0  # Synced
  fi
fi
```

#### Fix Mode

```bash
if [ "$MODE" = "fix" ]; then
  echo ""
  echo "═══════════════════════════════════════════════════════════════════════"
  echo "Fix Mode: Auto-Remediation"
  echo "═══════════════════════════════════════════════════════════════════════"

  FIXES_APPLIED=false

  # Fix 1: Create missing labels
  if [ ${#MISSING_LABELS[@]} -gt 0 ]; then
    echo ""
    echo "Creating missing labels..."
    for label in "${MISSING_LABELS[@]}"; do
      NAME=$(echo "$label" | jq -r '.name')
      COLOR=$(echo "$label" | jq -r '.color')
      DESC=$(echo "$label" | jq -r '.description')

      if gh label create "$NAME" --color "$COLOR" --description "$DESC" --force 2>/dev/null; then
        echo "  ✓ Created: $NAME (#$COLOR)"
        FIXES_APPLIED=true
      else
        echo "  ✗ Failed to create: $NAME"
      fi
    done
  fi

  # Fix 2: Update incorrect label colors
  if [ ${#COLOR_MISMATCHES[@]} -gt 0 ]; then
    echo ""
    echo "Updating label colors..."
    for mismatch in "${COLOR_MISMATCHES[@]}"; do
      IFS='|' read -r NAME EXPECTED_COLOR ACTUAL_COLOR <<< "$mismatch"

      if gh label edit "$NAME" --color "$EXPECTED_COLOR" 2>/dev/null; then
        echo "  ✓ Updated color: $NAME (#$ACTUAL_COLOR → #$EXPECTED_COLOR)"
        FIXES_APPLIED=true
      else
        echo "  ✗ Failed to update: $NAME"
      fi
    done
  fi

  # Fix 3: Update incorrect descriptions
  if [ ${#DESCRIPTION_MISMATCHES[@]} -gt 0 ]; then
    echo ""
    echo "Updating label descriptions..."
    for mismatch in "${DESCRIPTION_MISMATCHES[@]}"; do
      IFS='|' read -r NAME EXPECTED_DESC ACTUAL_DESC <<< "$mismatch"

      if gh label edit "$NAME" --description "$EXPECTED_DESC" 2>/dev/null; then
        echo "  ✓ Updated description: $NAME"
        FIXES_APPLIED=true
      else
        echo "  ✗ Failed to update: $NAME"
      fi
    done
  fi

  # Fix 4: Update verification cache
  echo ""
  echo "Updating verification cache..."
  jq --arg time "$CURRENT_TIME" \
     --arg status "synced" \
     '.last_verified = $time | .status = $status | .labels.verified_at = $time | .labels.status = "synced"' \
     "$CACHE_FILE" > "$CACHE_FILE.tmp" && mv "$CACHE_FILE.tmp" "$CACHE_FILE"
  echo "  ✓ Cache updated"

  echo ""
  echo "═══════════════════════════════════════════════════════════════════════"
  echo "Fix Summary"
  echo "═══════════════════════════════════════════════════════════════════════"
  echo "  Created labels: ${#MISSING_LABELS[@]}"
  echo "  Updated colors: ${#COLOR_MISMATCHES[@]}"
  echo "  Updated descriptions: ${#DESCRIPTION_MISMATCHES[@]}"
  echo "  Verification cache: Updated"
  echo ""

  if [ "$FIXES_APPLIED" = true ]; then
    echo "  Status: ✓ FIXES APPLIED"

    # Cleanup
    rm -f /tmp/github-labels-$$.json

    exit 2  # Fixes applied
  else
    echo "  Status: ✓ NO FIXES NEEDED"

    # Cleanup
    rm -f /tmp/github-labels-$$.json

    exit 0  # No fixes needed
  fi
fi
```

#### Report Mode

```bash
if [ "$MODE" = "report" ]; then
  echo ""
  echo "═══════════════════════════════════════════════════════════════════════"
  echo "Report Mode: Generating Detailed Analysis"
  echo "═══════════════════════════════════════════════════════════════════════"

  # Generate timestamp for report filename
  REPORT_TIMESTAMP=$(date -u +"%Y%m%d-%H%M%S")
  REPORT_FILE=".github/reports/drift-report-$REPORT_TIMESTAMP.md"

  # Get repo info
  REPO_ORG=$(gh repo view --json owner --jq '.owner.login')
  REPO_NAME=$(gh repo view --json name --jq '.name')

  # Start building report
  cat > "$REPORT_FILE" << EOF
---
title: "GitHub Configuration Drift Report"
generated: "$CURRENT_TIME"
mode: "report"
status: "$OVERALL_STATUS"
repository: "$REPO_ORG/$REPO_NAME"
---

# GitHub Configuration Drift Report

**Repository**: $REPO_ORG/$REPO_NAME
**Generated**: $CURRENT_TIME
**Overall Status**: $([ "$OVERALL_STATUS" = "synced" ] && echo "✓ SYNCED" || echo "✗ DRIFT DETECTED")

## Executive Summary

EOF

  # Add summary
  if [ ${#MISSING_LABELS[@]} -gt 0 ] || [ ${#COLOR_MISMATCHES[@]} -gt 0 ]; then
    echo "**Action Required**: Drift detected in label configuration." >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "- Missing labels: ${#MISSING_LABELS[@]}" >> "$REPORT_FILE"
    echo "- Color mismatches: ${#COLOR_MISMATCHES[@]}" >> "$REPORT_FILE"
    echo "- Description mismatches: ${#DESCRIPTION_MISMATCHES[@]}" >> "$REPORT_FILE"
  else
    echo "**Status**: All label configuration matches specification." >> "$REPORT_FILE"
  fi

  echo "" >> "$REPORT_FILE"

  # Label Verification Section
  cat >> "$REPORT_FILE" << EOF

## Label Verification

### Version Labels

| Label | Status | Expected Color | Actual Color | Issue |
|-------|--------|----------------|--------------|-------|
EOF

  # Add version labels to table
  for label_name in "version:patch" "version:minor" "version:major"; do
    LABEL_INFO=$(echo "$EXPECTED_LABELS" | jq -r --arg name "$label_name" '.[] | select(.name == $name)')
    EXPECTED_COLOR=$(echo "$LABEL_INFO" | jq -r '.color')

    ACTUAL=$(jq --arg name "$label_name" '.[] | select(.name == $name)' /tmp/github-labels-$$.json)

    if [ -z "$ACTUAL" ]; then
      echo "| $label_name | ✗ MISSING | $EXPECTED_COLOR | - | Not created |" >> "$REPORT_FILE"
    else
      ACTUAL_COLOR=$(echo "$ACTUAL" | jq -r '.color')
      if [ "${EXPECTED_COLOR,,}" = "${ACTUAL_COLOR,,}" ]; then
        echo "| $label_name | ✓ OK | $EXPECTED_COLOR | $ACTUAL_COLOR | - |" >> "$REPORT_FILE"
      else
        echo "| $label_name | ✗ MISMATCH | $EXPECTED_COLOR | $ACTUAL_COLOR | Color drift |" >> "$REPORT_FILE"
      fi
    fi
  done

  # Build Labels Section
  cat >> "$REPORT_FILE" << EOF

### Build Labels

| Label | Status | Expected Color | Actual Color | Issue |
|-------|--------|----------------|--------------|-------|
EOF

  # Add build labels to table
  for label_name in "build:surgical" "build:domain" "build:full" "build:critical" "build:validation"; do
    LABEL_INFO=$(echo "$EXPECTED_LABELS" | jq -r --arg name "$label_name" '.[] | select(.name == $name)')
    EXPECTED_COLOR=$(echo "$LABEL_INFO" | jq -r '.color')

    ACTUAL=$(jq --arg name "$label_name" '.[] | select(.name == $name)' /tmp/github-labels-$$.json)

    if [ -z "$ACTUAL" ]; then
      echo "| $label_name | ✗ MISSING | $EXPECTED_COLOR | - | Not created |" >> "$REPORT_FILE"
    else
      ACTUAL_COLOR=$(echo "$ACTUAL" | jq -r '.color')
      if [ "${EXPECTED_COLOR,,}" = "${ACTUAL_COLOR,,}" ]; then
        echo "| $label_name | ✓ OK | $EXPECTED_COLOR | $ACTUAL_COLOR | - |" >> "$REPORT_FILE"
      else
        echo "| $label_name | ✗ MISMATCH | $EXPECTED_COLOR | $ACTUAL_COLOR | Color drift |" >> "$REPORT_FILE"
      fi
    fi
  done

  # Override Labels Section
  cat >> "$REPORT_FILE" << EOF

### Override Labels

| Label | Status | Expected Color | Actual Color | Issue |
|-------|--------|----------------|--------------|-------|
EOF

  # Add override labels to table
  for label_name in "override:no-build" "override:no-test" "override:no-version"; do
    LABEL_INFO=$(echo "$EXPECTED_LABELS" | jq -r --arg name "$label_name" '.[] | select(.name == $name)')
    EXPECTED_COLOR=$(echo "$LABEL_INFO" | jq -r '.color')

    ACTUAL=$(jq --arg name "$label_name" '.[] | select(.name == $name)' /tmp/github-labels-$$.json)

    if [ -z "$ACTUAL" ]; then
      echo "| $label_name | ✗ MISSING | $EXPECTED_COLOR | - | Not created |" >> "$REPORT_FILE"
    else
      ACTUAL_COLOR=$(echo "$ACTUAL" | jq -r '.color')
      if [ "${EXPECTED_COLOR,,}" = "${ACTUAL_COLOR,,}" ]; then
        echo "| $label_name | ✓ OK | $EXPECTED_COLOR | $ACTUAL_COLOR | - |" >> "$REPORT_FILE"
      else
        echo "| $label_name | ✗ MISMATCH | $EXPECTED_COLOR | $ACTUAL_COLOR | Color drift |" >> "$REPORT_FILE"
      fi
    fi
  done

  # Configuration Validation Section
  cat >> "$REPORT_FILE" << EOF

## Configuration Validation

- [$([ "$CONFIG_STATUS" = "valid" ] && echo "x" || echo " ")] JSON syntax valid
- [$(jq -e '.github' "$CONFIG_FILE" >/dev/null 2>&1 && echo "x" || echo " ")] GitHub section exists
- [$([ "$MAPPING_COUNT" -eq 8 ] && echo "x" || echo " ")] Label mappings complete (8/8)
- [$(jq -e '.github.build_logic' "$CONFIG_FILE" >/dev/null 2>&1 && echo "x" || echo " ")] Build logic defined
- [$(jq -e '.github.project' "$CONFIG_FILE" >/dev/null 2>&1 && echo "x" || echo " ")] Project configuration present

## Verification Cache

- **Last verified**: $([ "$LAST_VERIFIED" = "null" ] && echo "Never" || echo "$LAST_VERIFIED ($CACHE_AGE_DAYS days ago)")
- **Status**: $CACHE_STATUS
- **Location**: $CACHE_FILE

## Recommendations

EOF

  # Add recommendations based on findings
  if [ ${#MISSING_LABELS[@]} -gt 0 ] || [ ${#COLOR_MISMATCHES[@]} -gt 0 ]; then
    cat >> "$REPORT_FILE" << EOF
### High Priority

1. **Fix label configuration**: Run \`/github-sync fix\` to auto-fix all label issues
2. **Verify fixes**: Run \`/github-sync check\` after applying fixes

EOF
  fi

  if [ "$CACHE_STATUS" = "stale" ]; then
    cat >> "$REPORT_FILE" << EOF
### Medium Priority

1. **Update verification cache**: Regular checks ensure drift is caught early
2. **Verify manual automations**: Check GitHub Project workflows (see specification)

EOF
  fi

  cat >> "$REPORT_FILE" << EOF
### Low Priority

1. **Review deprecated labels**: Consider cleanup with custom script
2. **Document changes**: Update specification if intentional drift exists

## Remediation Commands

\`\`\`bash
# Auto-fix all label issues
/github-sync fix

# Verify configuration after fixes
/github-sync check

# Re-run full initialization (if major drift detected)
/github-init
\`\`\`

## Symptom Analysis

EOF

  if [ "$UNASSIGNED_ISSUES" -gt 5 ]; then
    cat >> "$REPORT_FILE" << EOF
**Unassigned Issues**: $UNASSIGNED_ISSUES issues not assigned to project board

This suggests the "Auto-add to project" automation may not be configured. Verify in:
- GitHub Project → Settings → Workflows → "Item added to project"

EOF
  else
    cat >> "$REPORT_FILE" << EOF
**Issue Assignment**: Healthy ($UNASSIGNED_ISSUES unassigned issues)

EOF
  fi

  cat >> "$REPORT_FILE" << EOF

## Manual Verification Checklist

The following cannot be verified automatically and require manual review:

- [ ] GitHub Project automations (10 workflow rules)
- [ ] Branch protection rules
- [ ] Required status checks
- [ ] CODEOWNERS file
- [ ] Repository settings (merge strategies, etc.)

**Last manual verification**: $([ "$LAST_VERIFIED" = "null" ] && echo "Never" || echo "$LAST_VERIFIED")

---

**Report generated by**: \`/github-sync report\`
**Report saved to**: \`$REPORT_FILE\`
**Next steps**: Review recommendations above and run \`/github-sync fix\` if needed
EOF

  echo "  ✓ Report generated: $REPORT_FILE"
  echo ""

  # Update cache
  jq --arg time "$CURRENT_TIME" \
     --arg status "$OVERALL_STATUS" \
     --arg report "$REPORT_FILE" \
     '.last_verified = $time | .status = $status | .last_report = $report' \
     "$CACHE_FILE" > "$CACHE_FILE.tmp" && mv "$CACHE_FILE.tmp" "$CACHE_FILE"

  echo "  ✓ Verification cache updated"
  echo ""
  echo "═══════════════════════════════════════════════════════════════════════"
  echo "Report Complete"
  echo "═══════════════════════════════════════════════════════════════════════"
  echo ""
  echo "Review the detailed report at: $REPORT_FILE"
  echo ""

  if [ "$DRIFT_DETECTED" = true ]; then
    echo "Next steps:"
    echo "  1. Review the report for specific issues"
    echo "  2. Run '/github-sync fix' to auto-remediate"
    echo "  3. Verify manual automations as documented"
    echo ""
  fi

  # Cleanup
  rm -f /tmp/github-labels-$$.json

  # Exit with appropriate status
  if [ "$DRIFT_DETECTED" = true ]; then
    exit 1  # Drift detected
  else
    exit 0  # Synced
  fi
fi
```

## Exit Status Codes

The command uses these exit codes for automation and scripting:

- **0** - Configuration synced, no drift detected
- **1** - Drift detected (check/report mode)
- **2** - Fixes applied successfully (fix mode)
- **3** - Error during verification (fatal error)
- **4** - Missing prerequisites (gh CLI, config file, etc.)

### Usage in Automation

```bash
# Weekly cron job - alert on drift
if ! /github-sync check; then
  echo "GitHub configuration drift detected!"
  /github-sync report
  # Send notification to team
fi

# CI/CD pipeline - auto-fix drift
if ! /github-sync check; then
  echo "Drift detected, attempting auto-fix..."
  /github-sync fix
fi

# Pre-deployment validation
/github-sync check || {
  echo "ERROR: GitHub configuration out of sync"
  echo "Run: /github-sync fix"
  exit 1
}
```

## Notes

- **Non-destructive by default**: Check and report modes make no changes
- **Idempotent**: Fix mode can be run multiple times safely
- **Cache updates**: Every run updates verification cache timestamp
- **Cross-platform**: Works on macOS and Linux (handles date command differences)
- **Temporary files**: Uses PID-based temp files to avoid conflicts
- **Color normalization**: Case-insensitive color comparison
- **Detailed logging**: Clear status indicators (✓, ✗, ⚠) for readability

## Agent Integration

This command should be executed by the **devops-engineer** agent for:

- Shell script execution
- GitHub CLI operations
- JSON manipulation with jq
- File system operations
- Cache management

## Related Commands

- `/github-init` - Initial GitHub configuration setup
- `/workflow-init` - Initialize workflow system
- `/cleanup-main` - Post-merge cleanup automation

## Troubleshooting

**Issue**: "gh: command not found"

- **Fix**: Install GitHub CLI: `brew install gh`

**Issue**: "jq: command not found"

- **Fix**: Install jq: `brew install jq`

**Issue**: Label creation fails with "already exists"

- **Fix**: Use `--force` flag (already included in fix mode)

**Issue**: Cache file permissions error

- **Fix**: Ensure `.github/` directory is writable

**Issue**: Report directory doesn't exist

- **Fix**: Command auto-creates `.github/reports/` directory
