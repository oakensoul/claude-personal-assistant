---
name: config-validate
description: Validate configuration files for schema compliance, template variables, and consistency across environments
model: sonnet
args:
  scope:
    description: "What to validate - 'all', 'yaml', 'json', 'env', or specific file path (default: all)"
    required: false
    type: string
  check:
    description: "Validation type - 'schema', 'variables', 'secrets', 'all' (default: all)"
    required: false
    type: string
---

# Config Validate Command

Validates configuration files for schema compliance, template variable substitution correctness, secret detection, and consistency across environments by delegating to the `configuration-specialist` agent.

## Command Arguments

**Args Received**: `{{args}}`

### Argument Processing

```yaml
scope: {{args.scope | default: "all"}}
  # all: Validate all configuration files in project
  # yaml: Validate only YAML files
  # json: Validate only JSON files
  # env: Validate only .env files
  # <file-path>: Validate specific file

check: {{args.check | default: "all"}}
  # all: Run all validation checks (default)
  # schema: Schema compliance only
  # variables: Template variable validation only
  # secrets: Secret detection only
```

## Workflow

Execute the following steps systematically to validate project configurations.

---

## STEP 1: Discover Configuration Files

### 1.1 Determine Scope

**Parse scope argument** to determine what to validate:

```bash
SCOPE="{{args.scope | default: 'all'}}"

if [ "$SCOPE" = "all" ]; then
  # Discover all configuration files
  find ${PROJECT_ROOT} -type f \( \
    -name "*.yml" -o \
    -name "*.yaml" -o \
    -name "*.json" -o \
    -name ".env*" -o \
    -name "*.toml" -o \
    -name "*.ini" \
  \) ! -path "*/node_modules/*" ! -path "*/.git/*"

elif [ "$SCOPE" = "yaml" ]; then
  # YAML files only
  find ${PROJECT_ROOT} -type f \( -name "*.yml" -o -name "*.yaml" \) \
    ! -path "*/node_modules/*" ! -path "*/.git/*"

elif [ "$SCOPE" = "json" ]; then
  # JSON files only
  find ${PROJECT_ROOT} -type f -name "*.json" \
    ! -path "*/node_modules/*" ! -path "*/.git/*" ! -path "*/package-lock.json"

elif [ "$SCOPE" = "env" ]; then
  # Environment files only
  find ${PROJECT_ROOT} -type f -name ".env*" \
    ! -path "*/node_modules/*" ! -path "*/.git/*"

else
  # Specific file path
  if [ -f "${PROJECT_ROOT}/$SCOPE" ]; then
    echo "${PROJECT_ROOT}/$SCOPE"
  else
    echo "ERROR: File not found: $SCOPE"
    exit 1
  fi
fi
```

**Expected Output**: List of configuration file paths to validate

**Error Handling**:

- **No files found**: Display notice "No configuration files found in scope: $SCOPE"
- **Invalid scope**: Display error "Invalid scope: $SCOPE. Use 'all', 'yaml', 'json', 'env', or file path"
- **File not found**: Display error with suggested paths

### 1.2 Categorize Files

**Group files by type** for appropriate validation:

```yaml
yaml_files: []      # *.yml, *.yaml
json_files: []      # *.json
env_files: []       # .env*
toml_files: []      # *.toml
ini_files: []       # *.ini
other_files: []     # Unknown formats
```

**Store categorized lists** for delegation to configuration-specialist

---

## STEP 2: Invoke Configuration Specialist

### 2.1 Prepare Agent Context

**Build comprehensive context** for configuration-specialist agent:

```markdown
You are being invoked by the /config-validate command to validate project configuration files.

## Validation Scope

**Scope**: {{scope}}
**Check Type**: {{check}}

## Files to Validate

### YAML Files ({{count}})

{{#each yaml_files}}
- {{path}}
{{/each}}

### JSON Files ({{count}})

{{#each json_files}}
- {{path}}
{{/each}}

### Environment Files ({{count}})

{{#each env_files}}
- {{path}}
{{/each}}

### Other Configuration Files ({{count}})

{{#each other_files}}
- {{path}} ({{format}})
{{/each}}

## Validation Requirements

**Check Type**: {{check}}

{{#if check_all}}
Run ALL validation checks:
1. Schema Compliance
2. Template Variable Validation
3. Secret Detection
4. Environment Consistency
{{/if}}

{{#if check_schema}}
Run SCHEMA validation only:
- Validate YAML/JSON structure
- Check against schemas if available
- Verify required fields
- Validate field types and formats
{{/if}}

{{#if check_variables}}
Run TEMPLATE VARIABLE validation only:
- Identify all template variables ({{VAR}} and ${VAR})
- Classify as install-time vs runtime variables
- Detect undefined variables
- Check for proper escaping
{{/if}}

{{#if check_secrets}}
Run SECRET DETECTION only:
- Scan for hardcoded API keys
- Detect credential patterns
- Find tokens and passwords
- Flag sensitive data in configs
{{/if}}

## Your Mission

1. **Load Files**: Read each configuration file
2. **Parse Format**: Validate syntax for each format (YAML/JSON/TOML/.env/INI)
3. **Run Checks**: Execute requested validation checks
4. **Detect Issues**: Identify errors, warnings, and recommendations
5. **Provide Fixes**: Suggest specific, actionable fixes for each issue
6. **Generate Report**: Comprehensive validation report with findings

## Expected Output Format

For each file, provide:

**File**: path/to/config.yml
**Format**: YAML
**Status**: PASS | WARN | FAIL

**Syntax Validation**:
- ✓ Valid YAML syntax
- ✗ Issue: description → Fix: specific fix

**Schema Validation** (if applicable):
- ✓ All required fields present
- ⚠ Warning: description → Recommendation: suggestion

**Variable Validation**:
- ✓ All variables defined
- ✗ Undefined variable: {{MISSING_VAR}} → Fix: add to environment or defaults

**Secret Detection**:
- ✓ No hardcoded secrets detected
- ⚠ Potential secret: line 42, field api_key → Fix: use environment variable

**Environment Consistency**:
- ✓ Consistent with dev/staging/prod configs
- ⚠ Mismatch: field differs across environments → Fix: align values

**Additional Recommendations**:
- Use {{HOME}} instead of hardcoded /Users/username
- Add schema validation file
- Document available template variables

---

**IMPORTANT Checks**:

### Template Variable Classification

**Install-time variables** (`{{VAR}}`):
- {{AIDA_HOME}} - AIDA installation directory
- {{CLAUDE_CONFIG_DIR}} - Claude config directory
- {{HOME}} - User's home directory
- Any other {{DOUBLE_BRACE}} variables

**Runtime variables** (`${VAR}`):
- ${PROJECT_ROOT} - Current project directory
- ${GIT_ROOT} - Git repository root
- $(date) - Dynamic bash expressions
- ${ENV_VAR} - Environment variables

**Validation Rules**:
1. Install-time variables MUST be defined at installation
2. Runtime variables resolved when commands execute
3. Never mix syntaxes for same purpose
4. Document all custom variables

### Secret Detection Patterns

**High-risk patterns** (FAIL):
- api_key: "sk-..." (OpenAI keys)
- password: "plaintext" (passwords in clear)
- token: "ghp_..." (GitHub tokens)
- secret: "..." (any field named 'secret')
- AWS_SECRET_ACCESS_KEY: "..." (AWS credentials)

**Medium-risk patterns** (WARN):
- api_url: "https://...?key=..." (API keys in URLs)
- connection_string: "...password=..." (credentials in connection strings)
- Hardcoded IP addresses
- Long random-looking strings (potential tokens)

**Acceptable patterns** (PASS):
- api_key: "${API_KEY}" (environment variable reference)
- password_file: "/path/to/secret" (external secret file)
- use_secret_manager: true (secret manager integration)

### Hardcoded Path Detection

**Anti-patterns** (WARN):
- /Users/username/... → Use {{HOME}} or ${HOME}
- /home/username/... → Use {{HOME}} or ${HOME}
- C:\Users\username\... → Use {{HOME}} or ${HOME}
- Absolute paths without variables → Use relative paths or variables

**Good patterns** (PASS):
- {{HOME}}/.aida/
- ${PROJECT_ROOT}/config/
- ./relative/path
- ~/user-relative/path

---

## Common Issues to Check

### YAML-Specific

- Indentation errors (use 2 spaces, not tabs)
- Missing colons after keys
- Unquoted strings with special characters
- Document start markers in docker-compose.yml (not allowed by yamllint)
- Trailing spaces

### JSON-Specific

- Trailing commas (not allowed in JSON)
- Unquoted keys
- Single quotes instead of double quotes
- Comments (not allowed in pure JSON)

### .env-Specific

- Quotes around values (only when necessary)
- Missing export statements (depends on usage)
- Special characters without quotes
- Multi-line values without proper formatting

### Cross-Format Issues

- Inconsistent naming conventions (camelCase vs snake_case)
- Different values for same setting across environments
- Missing required fields in some environments
- Schema drift between config and code

---

**Standards Reference**:

Refer to your knowledge base for:
- Schema design patterns
- Template variable best practices
- Validation techniques
- Format-specific guidelines
- Secret management patterns

**Project Context**:

Load project-specific configuration knowledge if available:
- ${PROJECT_ROOT}/{{CLAUDE_CONFIG_DIR}}/agents-global/configuration-specialist/

If not available, provide general guidance and recommend running `/workflow-init`.
```

### 2.2 Delegate to configuration-specialist

**Invoke agent** with prepared context:

```text
Agent: configuration-specialist
Context: [Full context from above]
Task: Validate all configuration files according to requirements
Output: Comprehensive validation report
```

**Agent will**:

1. Load both user-level and project-level knowledge
2. Read and parse each configuration file
3. Run requested validation checks
4. Detect issues with specific locations
5. Provide actionable fixes
6. Generate detailed report

---

## STEP 3: Process Validation Results

### 3.1 Parse Agent Output

**Extract validation results** from configuration-specialist:

```yaml
results:
  - file: path/to/config.yml
    format: yaml
    status: pass|warn|fail
    checks:
      syntax:
        status: pass|warn|fail
        issues: []
        fixes: []
      schema:
        status: pass|warn|fail
        issues: []
        fixes: []
      variables:
        status: pass|warn|fail
        issues: []
        fixes: []
      secrets:
        status: pass|warn|fail
        issues: []
        fixes: []
```

### 3.2 Categorize Issues

**Group issues by severity**:

```yaml
critical: []    # Must fix (syntax errors, secrets, invalid schemas)
warnings: []    # Should fix (missing best practices, potential issues)
info: []        # Nice to have (recommendations, optimizations)
```

---

## STEP 4: Generate Validation Report

### 4.1 Display Summary

```text
╔════════════════════════════════════════════════════════════════════════════╗
║                     CONFIGURATION VALIDATION REPORT                        ║
╚════════════════════════════════════════════════════════════════════════════╝

Scope: {{scope}}
Check Type: {{check}}
Files Validated: {{file_count}}

OVERALL STATUS: {{overall_status}}
───────────────────────────────────────────────────────────────────────────

  ✓ Passed: {{pass_count}} files
  ⚠ Warnings: {{warn_count}} files
  ✗ Failed: {{fail_count}} files

ISSUE BREAKDOWN:
───────────────────────────────────────────────────────────────────────────

  Critical Issues: {{critical_count}}
  Warnings: {{warning_count}}
  Recommendations: {{info_count}}

╔════════════════════════════════════════════════════════════════════════════╗
║ DETAILED FINDINGS                                                          ║
╚════════════════════════════════════════════════════════════════════════════╝
```

### 4.2 Display File-Level Results

**For each file with issues**:

```text
───────────────────────────────────────────────────────────────────────────
FILE: path/to/config.yml
FORMAT: YAML
STATUS: ✗ FAILED
───────────────────────────────────────────────────────────────────────────

SYNTAX VALIDATION:
  ✓ Valid YAML syntax

SCHEMA VALIDATION:
  ✗ Missing required field: database.host
     Location: database section (line 15)
     Fix: Add 'host' field to database configuration

     database:
       host: localhost  # Add this line
       port: 5432

VARIABLE VALIDATION:
  ⚠ Undefined variable: {{CUSTOM_DIR}}
     Location: paths.custom (line 32)
     Fix: Define CUSTOM_DIR in installation variables or use ${PROJECT_ROOT}

     Before: custom_path: "{{CUSTOM_DIR}}/data"
     After:  custom_path: "${PROJECT_ROOT}/data"

SECRET DETECTION:
  ✗ CRITICAL: Hardcoded API key detected
     Location: api.key (line 45)
     Pattern: "sk-..." (OpenAI API key format)
     Fix: Move to environment variable

     Before: api_key: "sk-1234567890abcdef"
     After:  api_key: "${OPENAI_API_KEY}"

     Then set in .env:
     OPENAI_API_KEY=sk-1234567890abcdef

ADDITIONAL RECOMMENDATIONS:
  • Use {{HOME}} instead of /Users/username (line 12)
  • Add schema validation file: config.schema.json
  • Document custom variables in README.md

───────────────────────────────────────────────────────────────────────────
```

### 4.3 Display Summary Actions

```text
╔════════════════════════════════════════════════════════════════════════════╗
║ RECOMMENDED ACTIONS                                                        ║
╚════════════════════════════════════════════════════════════════════════════╝

CRITICAL (Must Fix):
───────────────────────────────────────────────────────────────────────────

  1. Remove hardcoded secrets from config files
     Files: config/production.yml, .env.example
     Impact: Security risk - credentials exposed in repository

  2. Fix schema validation errors
     Files: workflow-config.json
     Impact: Application may fail at runtime

WARNINGS (Should Fix):
───────────────────────────────────────────────────────────────────────────

  1. Replace hardcoded paths with variables
     Files: 3 configuration files
     Impact: Portability issues across environments

  2. Align environment configurations
     Files: config/dev.yml, config/staging.yml, config/prod.yml
     Impact: Inconsistent behavior across environments

RECOMMENDATIONS (Nice to Have):
───────────────────────────────────────────────────────────────────────────

  1. Add schema validation files
     Impact: Better validation and IDE support

  2. Document template variables
     Impact: Clearer configuration management

╔════════════════════════════════════════════════════════════════════════════╗
║ NEXT STEPS                                                                 ║
╠════════════════════════════════════════════════════════════════════════════╣
║                                                                            ║
║  1. Review critical issues above                                           ║
║  2. Apply suggested fixes to configuration files                           ║
║  3. Re-run validation: /config-validate                                    ║
║  4. Consider adding pre-commit hook for config validation                  ║
║                                                                            ║
╚════════════════════════════════════════════════════════════════════════════╝
```

---

## STEP 5: Save Validation Report

### 5.1 Create Report File

**Save detailed report** for reference:

```bash
# Create reports directory if needed
mkdir -p "${PROJECT_ROOT}/.claude/validation-reports"

# Generate report filename with timestamp
REPORT_FILE="${PROJECT_ROOT}/.claude/validation-reports/config-validation-$(date +%Y%m%d-%H%M%S).md"

# Write report
cat > "$REPORT_FILE" << 'EOF'
---
title: "Configuration Validation Report"
scope: "{{scope}}"
check_type: "{{check}}"
generated_at: "{{timestamp}}"
files_validated: {{file_count}}
status: "{{overall_status}}"
---

# Configuration Validation Report

**Generated**: {{timestamp}}
**Scope**: {{scope}}
**Check Type**: {{check}}
**Status**: {{overall_status}}

## Summary

- Files Validated: {{file_count}}
- Passed: {{pass_count}}
- Warnings: {{warn_count}}
- Failed: {{fail_count}}

## Issue Breakdown

- Critical: {{critical_count}}
- Warnings: {{warning_count}}
- Recommendations: {{info_count}}

## Detailed Findings

{{validation_results_markdown}}

## Recommended Actions

{{recommended_actions_markdown}}

---

**Validation performed by**: configuration-specialist agent
**Command**: /config-validate {{args}}
EOF
```

### 5.2 Confirm Success

```text
✓ Validation complete

  Report saved: .claude/validation-reports/config-validation-{{timestamp}}.md

  Summary:
    Files: {{file_count}}
    Critical Issues: {{critical_count}}
    Warnings: {{warning_count}}
    Status: {{overall_status}}
```

---

## Error Handling

### No Configuration Files Found

```text
╔════════════════════════════════════════════════════════════════════════════╗
║                     NO CONFIGURATION FILES FOUND                           ║
╚════════════════════════════════════════════════════════════════════════════╝

Scope: {{scope}}

No configuration files found matching the scope criteria.

SUGGESTIONS:
───────────────────────────────────────────────────────────────────────────

  • Check scope parameter: /config-validate --scope=all
  • Verify project has configuration files
  • Try specific file: /config-validate --scope=path/to/config.yml

COMMON CONFIGURATION FILE LOCATIONS:
───────────────────────────────────────────────────────────────────────────

  • .claude/workflow-config.json
  • config/*.yml
  • .env*
  • package.json
  • docker-compose.yml

```

### Agent Not Available

**If configuration-specialist agent doesn't exist**:

```text
⚠ WARNING: configuration-specialist agent not found

Expected location: ${CLAUDE_CONFIG_DIR}/agents/configuration-specialist/

The /config-validate command requires the configuration-specialist agent.

RESOLUTION:
───────────────────────────────────────────────────────────────────────────

  1. Verify agent installation
  2. Run agent manager to create agent
  3. Re-run /config-validate

Falling back to basic validation...
```

**Fallback behavior**:

- Run basic syntax validation only
- Check for obvious issues (syntax errors, secrets)
- Recommend installing configuration-specialist agent

### Validation Errors

**If files cannot be read or parsed**:

```text
✗ ERROR: Cannot validate file

File: path/to/config.yml
Reason: {{error_message}}

RESOLUTION:
───────────────────────────────────────────────────────────────────────────

  • Check file exists and is readable
  • Verify file permissions
  • Ensure valid file format
  • Review syntax errors
```

---

## Usage Examples

### Example 1: Validate All Configuration Files

```bash
/config-validate

# Validates all YAML, JSON, .env, TOML, INI files
# Runs all checks: schema, variables, secrets, consistency
```

### Example 2: Validate Only YAML Files

```bash
/config-validate --scope=yaml

# Validates only *.yml and *.yaml files
# Useful for focused YAML validation
```

### Example 3: Check for Secrets Only

```bash
/config-validate --check=secrets

# Runs secret detection only
# Fast scan for hardcoded credentials
```

### Example 4: Validate Specific File

```bash
/config-validate --scope=.claude/workflow-config.json

# Validates single file
# Provides detailed analysis of that file
```

### Example 5: Schema Validation Only

```bash
/config-validate --scope=all --check=schema

# Validates structure and required fields
# Skips variable and secret checks
```

---

## Integration with Workflow

### Position in Development Workflow

```text
Development → /config-validate → Commit → Push → CI/CD
                     ↓
              Fix Issues
                     ↓
              Re-validate
```

### Pre-Commit Integration

**Add to pre-commit hook**:

```yaml
# .pre-commit-config.yaml

- repo: local
  hooks:
    - id: config-validate
      name: Validate Configuration Files
      entry: /config-validate --scope=all
      language: system
      pass_filenames: false
      always_run: true
```

### CI/CD Integration

**Add to CI pipeline**:

```yaml
# .github/workflows/validate-config.yml

name: Validate Configuration

on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Validate Configurations
        run: /config-validate --scope=all
```

---

## Best Practices

### When to Use This Command

**Use /config-validate when**:

- Adding new configuration files
- Modifying existing configurations
- Before committing configuration changes
- After template variable updates
- During code review
- Setting up new environments
- Troubleshooting configuration issues

**Don't use /config-validate when**:

- Configuration format is non-standard
- Files are auto-generated (validate source instead)
- Running in CI without agent available (use fallback tools)

### Tips for Clean Configurations

1. **Use schema validation** - Define schemas for all config files
2. **Document variables** - Maintain list of all template variables
3. **Externalize secrets** - Never commit secrets to configs
4. **Use environment variables** - Reference, don't hardcode
5. **Validate regularly** - Run before commits and in CI
6. **Fix critical issues immediately** - Don't accumulate config debt

---

## Troubleshooting

### Issue: Validation takes too long

**Solution**: Narrow scope to specific files or types

```bash
/config-validate --scope=.claude/workflow-config.json
```

### Issue: Too many false positives

**Solution**: Run specific check types

```bash
/config-validate --check=schema  # Skip secret detection if too noisy
```

### Issue: Agent not finding project schemas

**Solution**: Run /workflow-init to create project context

```bash
/workflow-init
```

### Issue: Custom variables flagged as undefined

**Solution**: Document in project configuration specialist knowledge

```bash
# Add to ${PROJECT_ROOT}/.claude/agents-global/configuration-specialist/variables.md
```

---

## Technical Notes

### Supported Configuration Formats

- **YAML** (*.yml, *.yaml) - Full validation support
- **JSON** (*.json) - Full validation support
- **.env** - Syntax and secret detection
- **TOML** (*.toml) - Syntax validation
- **INI** (*.ini) - Basic validation

### Validation Report Location

- **Directory**: `.claude/validation-reports/`
- **Filename**: `config-validation-YYYYMMDD-HHMMSS.md`
- **Format**: Markdown with frontmatter
- **Retention**: Manual cleanup (not auto-deleted)

### Performance

- **Typical project**: < 5 seconds for ~20 config files
- **Large project**: < 30 seconds for ~100 config files
- **Optimization**: Use --scope to limit files validated

---

## Related Commands

- `/workflow-init` - Initialize project configuration context
- `/implement` - Implementation orchestration (validates configs during tasks)
- `/start-work` - May validate workflow-config.json

---

## Success Criteria

Command succeeds when:

1. ✓ All configuration files discovered
2. ✓ configuration-specialist agent invoked successfully
3. ✓ Validation checks completed
4. ✓ Issues identified with specific locations
5. ✓ Actionable fixes provided
6. ✓ Report generated and saved
7. ✓ User informed of next steps

**User is ready to**: Fix configuration issues and re-validate

---

**Configuration Validation Command**: Validation complete. Awaiting next command.
