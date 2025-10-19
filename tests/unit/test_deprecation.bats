#!/usr/bin/env bats
#
# Unit tests for deprecation.sh module
# Tests version comparison, frontmatter parsing, deprecation detection, and installation logic

# Load test helpers
load ../helpers/test_helpers

setup() {
  # Load required dependencies
  source "${PROJECT_ROOT}/lib/installer-common/colors.sh"
  source "${PROJECT_ROOT}/lib/installer-common/logging.sh"
  source "${PROJECT_ROOT}/lib/installer-common/validation.sh"
  source "${PROJECT_ROOT}/lib/installer-common/deprecation.sh"

  # Create temporary test directory
  setup_test_dir
}

teardown() {
  teardown_test_dir
}

#######################################
# Tests for compare_versions
#######################################

@test "compare_versions: equal versions return 0" {
  run compare_versions "0.1.6" "0.1.6"

  [ "$status" -eq 0 ]
}

@test "compare_versions: v1 > v2 returns 1 (major)" {
  run compare_versions "1.0.0" "0.9.9"

  [ "$status" -eq 1 ]
}

@test "compare_versions: v1 > v2 returns 1 (minor)" {
  run compare_versions "0.2.0" "0.1.9"

  [ "$status" -eq 1 ]
}

@test "compare_versions: v1 > v2 returns 1 (patch)" {
  run compare_versions "0.1.7" "0.1.6"

  [ "$status" -eq 1 ]
}

@test "compare_versions: v1 < v2 returns 2 (major)" {
  run compare_versions "0.9.9" "1.0.0"

  [ "$status" -eq 2 ]
}

@test "compare_versions: v1 < v2 returns 2 (minor)" {
  run compare_versions "0.1.9" "0.2.0"

  [ "$status" -eq 2 ]
}

@test "compare_versions: v1 < v2 returns 2 (patch)" {
  run compare_versions "0.1.6" "0.1.7"

  [ "$status" -eq 2 ]
}

@test "compare_versions: rejects empty v1" {
  run compare_versions "" "0.1.6"

  [ "$status" -eq 3 ]
  [[ "$output" =~ "Both version parameters required" ]]
}

@test "compare_versions: rejects empty v2" {
  run compare_versions "0.1.6" ""

  [ "$status" -eq 3 ]
  [[ "$output" =~ "Both version parameters required" ]]
}

@test "compare_versions: rejects invalid v1 format" {
  run compare_versions "invalid" "0.1.6"

  [ "$status" -eq 3 ]
  [[ "$output" =~ "Invalid version format" ]]
}

@test "compare_versions: rejects invalid v2 format" {
  run compare_versions "0.1.6" "invalid"

  [ "$status" -eq 3 ]
  [[ "$output" =~ "Invalid version format" ]]
}

@test "compare_versions: handles large version numbers" {
  run compare_versions "10.20.30" "10.20.29"

  [ "$status" -eq 1 ]
}

@test "compare_versions: handles version with leading zeros" {
  run compare_versions "0.01.6" "0.1.6"

  # 01 vs 1 - numeric comparison should handle this
  [ "$status" -eq 0 ]
}

#######################################
# Tests for parse_deprecation_metadata
#######################################

@test "parse_deprecation_metadata: extracts all fields from valid frontmatter" {
  local template="$TEST_DIR/template.md"

  cat > "$template" <<'EOF'
---
deprecated: true
deprecated_in: "0.2.0"
remove_in: "0.4.0"
canonical: "issue-create"
reason: "Renamed to noun-verb convention"
---

# Template Content
EOF

  run parse_deprecation_metadata "$template"

  [ "$status" -eq 0 ]
  [[ "$output" =~ "deprecated=true" ]]
  [[ "$output" =~ "deprecated_in=0.2.0" ]]
  [[ "$output" =~ "remove_in=0.4.0" ]]
  [[ "$output" =~ "canonical=issue-create" ]]
  [[ "$output" =~ "reason=Renamed to noun-verb convention" ]]
}

@test "parse_deprecation_metadata: handles partial frontmatter (only deprecated)" {
  local template="$TEST_DIR/template.md"

  cat > "$template" <<'EOF'
---
deprecated: true
---

# Template Content
EOF

  run parse_deprecation_metadata "$template"

  [ "$status" -eq 0 ]
  [[ "$output" =~ "deprecated=true" ]]
  [[ ! "$output" =~ "canonical=" ]]
}

@test "parse_deprecation_metadata: returns error for missing file" {
  run parse_deprecation_metadata "$TEST_DIR/nonexistent.md"

  [ "$status" -eq 1 ]
}

@test "parse_deprecation_metadata: returns error for empty parameter" {
  run parse_deprecation_metadata ""

  [ "$status" -eq 1 ]
  [[ "$output" =~ "template_file required" ]]
}

@test "parse_deprecation_metadata: handles template without frontmatter" {
  local template="$TEST_DIR/template.md"

  cat > "$template" <<'EOF'
# Template Content

No frontmatter here.
EOF

  run parse_deprecation_metadata "$template"

  [ "$status" -eq 1 ]
}

@test "parse_deprecation_metadata: handles template with other frontmatter fields" {
  local template="$TEST_DIR/template.md"

  cat > "$template" <<'EOF'
---
name: test-command
description: A test command
deprecated: true
canonical: "new-command"
---

# Template Content
EOF

  run parse_deprecation_metadata "$template"

  [ "$status" -eq 0 ]
  [[ "$output" =~ "deprecated=true" ]]
  [[ "$output" =~ "canonical=new-command" ]]
  # Should not include non-deprecation fields
  [[ ! "$output" =~ "name=" ]]
  [[ ! "$output" =~ "description=" ]]
}

@test "parse_deprecation_metadata: strips quotes from values" {
  local template="$TEST_DIR/template.md"

  cat > "$template" <<'EOF'
---
deprecated: "true"
deprecated_in: "0.2.0"
canonical: "issue-create"
---

# Template Content
EOF

  run parse_deprecation_metadata "$template"

  [ "$status" -eq 0 ]
  # Values should be returned without quotes
  [[ "$output" =~ 'deprecated_in=0.2.0' ]]
  [[ "$output" =~ 'canonical=issue-create' ]]
}

@test "parse_deprecation_metadata: handles reason with spaces" {
  local template="$TEST_DIR/template.md"

  cat > "$template" <<'EOF'
---
deprecated: true
reason: "Renamed to follow noun-verb convention for consistency"
---

# Template Content
EOF

  run parse_deprecation_metadata "$template"

  [ "$status" -eq 0 ]
  [[ "$output" =~ "reason=Renamed to follow noun-verb convention for consistency" ]]
}

#######################################
# Tests for is_deprecated
#######################################

@test "is_deprecated: returns 0 for deprecated template" {
  local template="$TEST_DIR/template.md"

  cat > "$template" <<'EOF'
---
deprecated: true
---

# Template Content
EOF

  run is_deprecated "$template"

  [ "$status" -eq 0 ]
}

@test "is_deprecated: returns 1 for non-deprecated template" {
  local template="$TEST_DIR/template.md"

  cat > "$template" <<'EOF'
---
deprecated: false
---

# Template Content
EOF

  run is_deprecated "$template"

  [ "$status" -eq 1 ]
}

@test "is_deprecated: returns 1 for template without frontmatter" {
  local template="$TEST_DIR/template.md"

  cat > "$template" <<'EOF'
# Template Content

No frontmatter.
EOF

  run is_deprecated "$template"

  [ "$status" -eq 1 ]
}

@test "is_deprecated: returns 1 for template without deprecated field" {
  local template="$TEST_DIR/template.md"

  cat > "$template" <<'EOF'
---
name: test-command
description: A test command
---

# Template Content
EOF

  run is_deprecated "$template"

  [ "$status" -eq 1 ]
}

@test "is_deprecated: returns 1 for missing file" {
  run is_deprecated "$TEST_DIR/nonexistent.md"

  [ "$status" -eq 1 ]
}

@test "is_deprecated: returns 1 for empty parameter" {
  run is_deprecated ""

  [ "$status" -eq 1 ]
}

#######################################
# Tests for should_remove_deprecated
#######################################

@test "should_remove_deprecated: returns 0 when current >= remove_in (equal)" {
  run should_remove_deprecated "0.4.0" "0.4.0"

  [ "$status" -eq 0 ]
}

@test "should_remove_deprecated: returns 0 when current > remove_in" {
  run should_remove_deprecated "0.5.0" "0.4.0"

  [ "$status" -eq 0 ]
}

@test "should_remove_deprecated: returns 1 when current < remove_in" {
  run should_remove_deprecated "0.3.0" "0.4.0"

  [ "$status" -eq 1 ]
}

@test "should_remove_deprecated: returns 2 for invalid current version" {
  run should_remove_deprecated "invalid" "0.4.0"

  [ "$status" -eq 2 ]
}

@test "should_remove_deprecated: returns 2 for invalid remove_in version" {
  run should_remove_deprecated "0.4.0" "invalid"

  [ "$status" -eq 2 ]
}

@test "should_remove_deprecated: returns 2 for empty current version" {
  run should_remove_deprecated "" "0.4.0"

  [ "$status" -eq 2 ]
}

@test "should_remove_deprecated: returns 2 for empty remove_in version" {
  run should_remove_deprecated "0.4.0" ""

  [ "$status" -eq 2 ]
}

#######################################
# Tests for get_canonical_name
#######################################

@test "get_canonical_name: extracts canonical name from deprecated template" {
  local template="$TEST_DIR/template.md"

  cat > "$template" <<'EOF'
---
deprecated: true
canonical: "issue-create"
---

# Template Content
EOF

  run get_canonical_name "$template"

  [ "$status" -eq 0 ]
  [[ "$output" == "issue-create" ]]
}

@test "get_canonical_name: strips quotes from canonical name" {
  local template="$TEST_DIR/template.md"

  cat > "$template" <<'EOF'
---
deprecated: true
canonical: "issue-create"
---

# Template Content
EOF

  run get_canonical_name "$template"

  [ "$status" -eq 0 ]
  # Should not contain quotes
  [[ "$output" == "issue-create" ]]
  [[ ! "$output" =~ '"' ]]
}

@test "get_canonical_name: returns 1 if canonical field missing" {
  local template="$TEST_DIR/template.md"

  cat > "$template" <<'EOF'
---
deprecated: true
---

# Template Content
EOF

  run get_canonical_name "$template"

  [ "$status" -eq 1 ]
}

@test "get_canonical_name: returns 1 for template without frontmatter" {
  local template="$TEST_DIR/template.md"

  cat > "$template" <<'EOF'
# Template Content

No frontmatter.
EOF

  run get_canonical_name "$template"

  [ "$status" -eq 1 ]
}

@test "get_canonical_name: returns 1 for missing file" {
  run get_canonical_name "$TEST_DIR/nonexistent.md"

  [ "$status" -eq 1 ]
}

@test "get_canonical_name: returns 1 for empty parameter" {
  run get_canonical_name ""

  [ "$status" -eq 1 ]
}

#######################################
# Tests for scan_deprecated_templates
#######################################

@test "scan_deprecated_templates: finds deprecated templates in directory" {
  local templates_dir="$TEST_DIR/templates"
  mkdir -p "$templates_dir"

  # Create deprecated template
  cat > "$templates_dir/deprecated1.md" <<'EOF'
---
deprecated: true
---

# Deprecated Template 1
EOF

  # Create non-deprecated template
  cat > "$templates_dir/active.md" <<'EOF'
---
deprecated: false
---

# Active Template
EOF

  # Create deprecated template
  cat > "$templates_dir/deprecated2.md" <<'EOF'
---
deprecated: true
---

# Deprecated Template 2
EOF

  run scan_deprecated_templates "$templates_dir"

  [ "$status" -eq 0 ]
  # Should find both deprecated templates
  [[ "$output" =~ "deprecated1.md" ]]
  [[ "$output" =~ "deprecated2.md" ]]
  # Should not find active template
  [[ ! "$output" =~ "active.md" ]]
}

@test "scan_deprecated_templates: returns 0 even if no deprecated templates found" {
  local templates_dir="$TEST_DIR/templates"
  mkdir -p "$templates_dir"

  # Create only non-deprecated template
  cat > "$templates_dir/active.md" <<'EOF'
---
deprecated: false
---

# Active Template
EOF

  run scan_deprecated_templates "$templates_dir"

  [ "$status" -eq 0 ]
  # Output should be empty
  [[ -z "$output" ]]
}

@test "scan_deprecated_templates: returns 1 for missing directory" {
  run scan_deprecated_templates "$TEST_DIR/nonexistent"

  [ "$status" -eq 1 ]
}

@test "scan_deprecated_templates: returns 1 for empty parameter" {
  run scan_deprecated_templates ""

  [ "$status" -eq 1 ]
}

@test "scan_deprecated_templates: handles nested directories" {
  local templates_dir="$TEST_DIR/templates"
  mkdir -p "$templates_dir/subdir"

  # Create deprecated template in subdirectory
  cat > "$templates_dir/subdir/deprecated.md" <<'EOF'
---
deprecated: true
---

# Deprecated Template
EOF

  run scan_deprecated_templates "$templates_dir"

  [ "$status" -eq 0 ]
  # Should find deprecated template in subdirectory
  [[ "$output" =~ "subdir/deprecated.md" ]]
}

@test "scan_deprecated_templates: ignores non-.md files" {
  local templates_dir="$TEST_DIR/templates"
  mkdir -p "$templates_dir"

  # Create deprecated .txt file (should be ignored)
  cat > "$templates_dir/deprecated.txt" <<'EOF'
---
deprecated: true
---

# Deprecated Template
EOF

  # Create deprecated .md file (should be found)
  cat > "$templates_dir/deprecated.md" <<'EOF'
---
deprecated: true
---

# Deprecated Template
EOF

  run scan_deprecated_templates "$templates_dir"

  [ "$status" -eq 0 ]
  # Should only find .md file
  [[ "$output" =~ "deprecated.md" ]]
  [[ ! "$output" =~ "deprecated.txt" ]]
}

#######################################
# Tests for handle_deprecation_conflicts
#######################################

@test "handle_deprecation_conflicts: detects conflict when both versions exist" {
  local claude_dir="$TEST_DIR/claude"
  mkdir -p "$claude_dir/commands/.aida-deprecated/create-issue-draft"
  mkdir -p "$claude_dir/commands/.aida/issue-create"

  # Create deprecated template with canonical reference
  cat > "$claude_dir/commands/.aida-deprecated/create-issue-draft/README.md" <<'EOF'
---
deprecated: true
canonical: "issue-create"
---

# Deprecated Template
EOF

  # Create canonical template
  cat > "$claude_dir/commands/.aida/issue-create/README.md" <<'EOF'
---
name: issue-create
---

# Canonical Template
EOF

  run handle_deprecation_conflicts "$claude_dir"

  [ "$status" -eq 0 ]
  [[ "$output" =~ "Conflict detected" ]]
  [[ "$output" =~ "create-issue-draft" ]]
  [[ "$output" =~ "issue-create" ]]
}

@test "handle_deprecation_conflicts: returns 1 when no conflicts exist" {
  local claude_dir="$TEST_DIR/claude"
  mkdir -p "$claude_dir/commands/.aida-deprecated/create-issue-draft"

  # Create deprecated template but no canonical version
  cat > "$claude_dir/commands/.aida-deprecated/create-issue-draft/README.md" <<'EOF'
---
deprecated: true
canonical: "issue-create"
---

# Deprecated Template
EOF

  run handle_deprecation_conflicts "$claude_dir"

  [ "$status" -eq 1 ]
  [[ ! "$output" =~ "Conflict detected" ]]
}

@test "handle_deprecation_conflicts: returns 1 for missing directory" {
  run handle_deprecation_conflicts "$TEST_DIR/nonexistent"

  [ "$status" -eq 1 ]
}

@test "handle_deprecation_conflicts: returns 1 for empty parameter" {
  run handle_deprecation_conflicts ""

  [ "$status" -eq 1 ]
}

@test "handle_deprecation_conflicts: returns 1 when .aida-deprecated namespace missing" {
  local claude_dir="$TEST_DIR/claude"
  mkdir -p "$claude_dir/commands/.aida"

  run handle_deprecation_conflicts "$claude_dir"

  [ "$status" -eq 1 ]
}

#######################################
# Tests for should_install_deprecated
#######################################

@test "should_install_deprecated: installs when with_deprecated=true" {
  local template="$TEST_DIR/template.md"

  cat > "$template" <<'EOF'
---
deprecated: true
deprecated_in: "0.2.0"
remove_in: "0.4.0"
---

# Deprecated Template
EOF

  run should_install_deprecated "true" "0.3.0" "$template"

  [ "$status" -eq 0 ]
}

@test "should_install_deprecated: does NOT install when current >= remove_in" {
  local template="$TEST_DIR/template.md"

  cat > "$template" <<'EOF'
---
deprecated: true
deprecated_in: "0.2.0"
remove_in: "0.4.0"
---

# Deprecated Template
EOF

  run should_install_deprecated "false" "0.4.0" "$template"

  [ "$status" -eq 1 ]
}

@test "should_install_deprecated: installs when current < remove_in (grace period)" {
  local template="$TEST_DIR/template.md"

  cat > "$template" <<'EOF'
---
deprecated: true
deprecated_in: "0.2.0"
remove_in: "0.4.0"
---

# Deprecated Template
EOF

  run should_install_deprecated "false" "0.3.0" "$template"

  [ "$status" -eq 0 ]
}

@test "should_install_deprecated: installs when no remove_in specified" {
  local template="$TEST_DIR/template.md"

  cat > "$template" <<'EOF'
---
deprecated: true
deprecated_in: "0.2.0"
---

# Deprecated Template
EOF

  run should_install_deprecated "false" "0.3.0" "$template"

  [ "$status" -eq 0 ]
}

@test "should_install_deprecated: installs non-deprecated template" {
  local template="$TEST_DIR/template.md"

  cat > "$template" <<'EOF'
---
name: active-command
---

# Active Template
EOF

  run should_install_deprecated "false" "0.3.0" "$template"

  [ "$status" -eq 0 ]
}

@test "should_install_deprecated: returns 2 for empty with_deprecated_flag" {
  local template="$TEST_DIR/template.md"

  cat > "$template" <<'EOF'
---
deprecated: true
---

# Template
EOF

  run should_install_deprecated "" "0.3.0" "$template"

  [ "$status" -eq 2 ]
}

@test "should_install_deprecated: returns 2 for invalid with_deprecated_flag" {
  local template="$TEST_DIR/template.md"

  cat > "$template" <<'EOF'
---
deprecated: true
---

# Template
EOF

  run should_install_deprecated "invalid" "0.3.0" "$template"

  [ "$status" -eq 2 ]
}

@test "should_install_deprecated: returns 2 for empty current_version" {
  local template="$TEST_DIR/template.md"

  cat > "$template" <<'EOF'
---
deprecated: true
---

# Template
EOF

  run should_install_deprecated "false" "" "$template"

  [ "$status" -eq 2 ]
}

@test "should_install_deprecated: returns 2 for empty template_file" {
  run should_install_deprecated "false" "0.3.0" ""

  [ "$status" -eq 2 ]
}

#######################################
# Tests for get_deprecation_reason
#######################################

@test "get_deprecation_reason: extracts reason from deprecated template" {
  local template="$TEST_DIR/template.md"

  cat > "$template" <<'EOF'
---
deprecated: true
reason: "Renamed to noun-verb convention"
---

# Template Content
EOF

  run get_deprecation_reason "$template"

  [ "$status" -eq 0 ]
  [[ "$output" == "Renamed to noun-verb convention" ]]
}

@test "get_deprecation_reason: strips quotes from reason" {
  local template="$TEST_DIR/template.md"

  cat > "$template" <<'EOF'
---
deprecated: true
reason: "Renamed to noun-verb convention"
---

# Template Content
EOF

  run get_deprecation_reason "$template"

  [ "$status" -eq 0 ]
  [[ ! "$output" =~ '"' ]]
}

@test "get_deprecation_reason: returns 1 if reason field missing" {
  local template="$TEST_DIR/template.md"

  cat > "$template" <<'EOF'
---
deprecated: true
---

# Template Content
EOF

  run get_deprecation_reason "$template"

  [ "$status" -eq 1 ]
}

@test "get_deprecation_reason: returns 1 for empty parameter" {
  run get_deprecation_reason ""

  [ "$status" -eq 1 ]
}

#######################################
# Tests for get_deprecated_in_version
#######################################

@test "get_deprecated_in_version: extracts deprecated_in version" {
  local template="$TEST_DIR/template.md"

  cat > "$template" <<'EOF'
---
deprecated: true
deprecated_in: "0.2.0"
---

# Template Content
EOF

  run get_deprecated_in_version "$template"

  [ "$status" -eq 0 ]
  [[ "$output" == "0.2.0" ]]
}

@test "get_deprecated_in_version: strips quotes from version" {
  local template="$TEST_DIR/template.md"

  cat > "$template" <<'EOF'
---
deprecated: true
deprecated_in: "0.2.0"
---

# Template Content
EOF

  run get_deprecated_in_version "$template"

  [ "$status" -eq 0 ]
  [[ ! "$output" =~ '"' ]]
}

@test "get_deprecated_in_version: returns 1 if deprecated_in field missing" {
  local template="$TEST_DIR/template.md"

  cat > "$template" <<'EOF'
---
deprecated: true
---

# Template Content
EOF

  run get_deprecated_in_version "$template"

  [ "$status" -eq 1 ]
}

@test "get_deprecated_in_version: returns 1 for empty parameter" {
  run get_deprecated_in_version ""

  [ "$status" -eq 1 ]
}

#######################################
# Tests for get_remove_in_version
#######################################

@test "get_remove_in_version: extracts remove_in version" {
  local template="$TEST_DIR/template.md"

  cat > "$template" <<'EOF'
---
deprecated: true
remove_in: "0.4.0"
---

# Template Content
EOF

  run get_remove_in_version "$template"

  [ "$status" -eq 0 ]
  [[ "$output" == "0.4.0" ]]
}

@test "get_remove_in_version: strips quotes from version" {
  local template="$TEST_DIR/template.md"

  cat > "$template" <<'EOF'
---
deprecated: true
remove_in: "0.4.0"
---

# Template Content
EOF

  run get_remove_in_version "$template"

  [ "$status" -eq 0 ]
  [[ ! "$output" =~ '"' ]]
}

@test "get_remove_in_version: returns 1 if remove_in field missing" {
  local template="$TEST_DIR/template.md"

  cat > "$template" <<'EOF'
---
deprecated: true
---

# Template Content
EOF

  run get_remove_in_version "$template"

  [ "$status" -eq 1 ]
}

@test "get_remove_in_version: returns 1 for empty parameter" {
  run get_remove_in_version ""

  [ "$status" -eq 1 ]
}

#######################################
# Integration Tests
#######################################

@test "integration: full deprecation workflow with grace period" {
  local template="$TEST_DIR/create-issue-draft.md"

  cat > "$template" <<'EOF'
---
deprecated: true
deprecated_in: "0.2.0"
remove_in: "0.4.0"
canonical: "issue-create"
reason: "Renamed to noun-verb convention"
---

# Create Issue Draft (Deprecated)
EOF

  # Template is deprecated
  run is_deprecated "$template"
  [ "$status" -eq 0 ]

  # Extract metadata
  local canonical
  canonical=$(get_canonical_name "$template")
  [[ "$canonical" == "issue-create" ]]

  local reason
  reason=$(get_deprecation_reason "$template")
  [[ "$reason" == "Renamed to noun-verb convention" ]]

  # Check installation decision at different versions
  # v0.3.0 - still in grace period, should install
  run should_install_deprecated "false" "0.3.0" "$template"
  [ "$status" -eq 0 ]

  # v0.4.0 - reached remove_in, should NOT install
  run should_install_deprecated "false" "0.4.0" "$template"
  [ "$status" -eq 1 ]

  # v0.5.0 - past remove_in, should NOT install
  run should_install_deprecated "false" "0.5.0" "$template"
  [ "$status" -eq 1 ]

  # with_deprecated=true overrides version check
  run should_install_deprecated "true" "0.5.0" "$template"
  [ "$status" -eq 0 ]
}

@test "integration: scan and detect multiple deprecated templates" {
  local templates_dir="$TEST_DIR/templates"
  mkdir -p "$templates_dir"

  # Create deprecated template 1
  cat > "$templates_dir/create-issue-draft.md" <<'EOF'
---
deprecated: true
deprecated_in: "0.2.0"
remove_in: "0.4.0"
canonical: "issue-create"
---

# Deprecated 1
EOF

  # Create deprecated template 2
  cat > "$templates_dir/start-issue-work.md" <<'EOF'
---
deprecated: true
deprecated_in: "0.2.0"
remove_in: "0.4.0"
canonical: "issue-work-start"
---

# Deprecated 2
EOF

  # Create active template
  cat > "$templates_dir/issue-create.md" <<'EOF'
---
name: issue-create
---

# Active Template
EOF

  # Scan for deprecated templates
  local deprecated_list
  deprecated_list=$(scan_deprecated_templates "$templates_dir")

  # Should find both deprecated templates
  [[ "$deprecated_list" =~ "create-issue-draft.md" ]]
  [[ "$deprecated_list" =~ "start-issue-work.md" ]]
  [[ ! "$deprecated_list" =~ "issue-create.md" ]]
}
