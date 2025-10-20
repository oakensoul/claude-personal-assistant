---
title: "Configuration Specialist Analysis - Issue #53 Modular Installer"
issue: 53
analysis_type: "configuration-design"
analyzed_by: "configuration-specialist"
date: "2025-10-18"
status: "draft"
---

# Configuration Design Analysis: Modular Installer Refactoring

## Executive Summary

The installer refactoring presents **critical configuration architecture decisions** that will impact maintainability, multi-repo integration, and backward compatibility. Key concerns: variable substitution strategy, deprecation metadata schema, and configuration contract for dotfiles integration.

**Primary Risk**: Inconsistent variable substitution between dev/normal modes and install-time/runtime contexts could break cross-repo compatibility.

**Primary Opportunity**: Well-designed deprecation system enables smooth migration path for future breaking changes.

---

## 1. Configuration Design Concerns

### Current Architecture Assessment

**Strengths**:

- Clear variable substitution boundary (`{{VAR}}` install-time, `${VAR}` runtime)
- Existing validation for approved template variables
- Backup mechanism preserves user data

**Anti-Patterns Identified**:

- **Monolithic configuration**: Single 625-line install.sh mixes concerns (UI, file operations, validation, substitution)
- **Implicit defaults**: Template variable validation hardcoded in script (lines 424-428)
- **No schema validation**: Templates lack formal schema definition
- **Tight coupling**: Variable substitution logic embedded in copy function (lines 410-413)
- **Missing abstraction**: No configuration layer between installer modules

### Recommended Configuration Patterns

#### Pattern 1: Configuration Schema First

```yaml
# lib/installer-common/schema/template-config.schema.yaml
$schema: "http://json-schema.org/draft-07/schema#"
title: "AIDA Template Configuration"
type: object

properties:
  template_type:
    enum: ["command", "agent", "skill", "knowledge"]
    description: "Template category for installation routing"

  install_location:
    type: object
    properties:
      namespace:
        type: string
        enum: [".aida", "user"]
        default: ".aida"
      subdirectory:
        type: string
        pattern: "^[a-z][a-z0-9-]*$"
    required: ["namespace"]

  substitution_vars:
    type: object
    properties:
      install_time:
        type: array
        items:
          enum: ["AIDA_HOME", "CLAUDE_CONFIG_DIR", "HOME"]
      runtime:
        type: array
        items:
          type: string
    description: "Variables used in this template"

  deprecation:
    type: object
    properties:
      deprecated_in:
        type: string
        pattern: "^\\d+\\.\\d+\\.\\d+$"
      remove_in:
        type: string
        pattern: "^\\d+\\.\\d+\\.\\d+$"
      canonical:
        type: string
        description: "Replacement template path"
      reason:
        type: string
    required: ["deprecated_in", "canonical", "reason"]

required: ["template_type", "install_location"]
```

#### Pattern 2: Modular Configuration Management

```bash
# lib/installer-common/config.sh

# Configuration state for installer
declare -A INSTALLER_CONFIG=(
    [VERSION]=""
    [INSTALL_MODE]="normal"  # normal | dev
    [AIDA_DIR]=""
    [CLAUDE_DIR]=""
    [NAMESPACE]=".aida"
    [WITH_DEPRECATED]="false"
)

# Load configuration from environment or defaults
load_installer_config() {
    INSTALLER_CONFIG[AIDA_DIR]="${AIDA_DIR:-${HOME}/.aida}"
    INSTALLER_CONFIG[CLAUDE_DIR]="${CLAUDE_DIR:-${HOME}/.claude}"
    # Override from environment if set
    INSTALLER_CONFIG[WITH_DEPRECATED]="${WITH_DEPRECATED:-false}"
}

# Get configuration value with validation
get_config() {
    local key="$1"
    local default="${2:-}"

    if [[ -z "${INSTALLER_CONFIG[$key]:-}" ]]; then
        if [[ -n "$default" ]]; then
            echo "$default"
            return 0
        fi
        print_message "error" "Configuration key not found: $key"
        return 1
    fi

    echo "${INSTALLER_CONFIG[$key]}"
}

# Set configuration value with validation
set_config() {
    local key="$1"
    local value="$2"

    # Validate configuration keys
    case "$key" in
        VERSION)
            if ! validate_version "$value"; then
                return 1
            fi
            ;;
        INSTALL_MODE)
            if [[ ! "$value" =~ ^(normal|dev)$ ]]; then
                print_message "error" "Invalid install mode: $value"
                return 1
            fi
            ;;
        WITH_DEPRECATED)
            if [[ ! "$value" =~ ^(true|false)$ ]]; then
                print_message "error" "Invalid boolean: $value"
                return 1
            fi
            ;;
    esac

    INSTALLER_CONFIG[$key]="$value"
}

# Export configuration for subprocesses
export_config() {
    export AIDA_DIR="${INSTALLER_CONFIG[AIDA_DIR]}"
    export CLAUDE_DIR="${INSTALLER_CONFIG[CLAUDE_DIR]}"
    export INSTALL_MODE="${INSTALLER_CONFIG[INSTALL_MODE]}"
    export WITH_DEPRECATED="${INSTALLER_CONFIG[WITH_DEPRECATED]}"
}
```

#### Pattern 3: Template Registry

```bash
# lib/installer-common/registry.sh

# Template registry tracking installed templates
readonly REGISTRY_FILE="${CLAUDE_DIR}/.aida-registry.json"

# Register installed template
register_template() {
    local template_path="$1"
    local template_type="$2"
    local version="$3"
    local namespace="${4:-.aida}"

    # Read existing registry or create new
    local registry
    if [[ -f "$REGISTRY_FILE" ]]; then
        registry=$(cat "$REGISTRY_FILE")
    else
        registry='{"templates":[],"version":"","installed_at":""}'
    fi

    # Add template entry
    local entry
    entry=$(jq -n \
        --arg path "$template_path" \
        --arg type "$template_type" \
        --arg ver "$version" \
        --arg ns "$namespace" \
        --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        '{
            path: $path,
            type: $type,
            version: $ver,
            namespace: $ns,
            installed_at: $ts
        }')

    # Merge into registry
    registry=$(echo "$registry" | jq \
        --argjson entry "$entry" \
        '.templates += [$entry]')

    echo "$registry" > "$REGISTRY_FILE"
}

# Check if template is installed
is_template_installed() {
    local template_path="$1"

    if [[ ! -f "$REGISTRY_FILE" ]]; then
        return 1
    fi

    jq -e --arg path "$template_path" \
        '.templates[] | select(.path == $path)' \
        "$REGISTRY_FILE" >/dev/null
}

# Get installed template version
get_template_version() {
    local template_path="$1"

    if [[ ! -f "$REGISTRY_FILE" ]]; then
        return 1
    fi

    jq -r --arg path "$template_path" \
        '.templates[] | select(.path == $path) | .version' \
        "$REGISTRY_FILE"
}
```

### Module Configuration Responsibilities

**templates.sh**:

- Load template metadata (frontmatter)
- Validate template structure
- Route templates to correct install location
- Apply namespace isolation (`.aida/`)

**deprecation.sh**:

- Parse deprecation metadata from frontmatter
- Filter templates by `--with-deprecated` flag
- Display deprecation warnings
- Suggest canonical replacements

**variables.sh**:

- Define approved variable sets (install-time vs runtime)
- Substitute install-time variables (`{{VAR}}`)
- Validate runtime variables remain unsubstituted (`${VAR}`)
- Context-aware substitution (dev vs normal mode)

**validation.sh** (extend existing):

- Validate template metadata schema
- Check for unresolved variables
- Verify namespace consistency
- Validate deprecation metadata

---

## 2. Variable Substitution Strategy

### Current State Analysis

**Existing Variables** (from validate-templates.sh):

```bash
# Install-time ({{VAR}}) - substituted during installation
AIDA_HOME       # ~/.aida/ or symlink target
CLAUDE_CONFIG_DIR  # ~/.claude/
HOME            # User home directory

# Runtime (${VAR}) - resolved when command executes
PROJECT_ROOT    # Current project directory
USER            # Current username
```

**Current substitution logic** (install.sh:410-413):

```bash
sed -e "s|{{AIDA_HOME}}|${AIDA_DIR}|g" \
    -e "s|{{CLAUDE_CONFIG_DIR}}|${CLAUDE_DIR}|g" \
    -e "s|{{HOME}}|${HOME}|g" \
    "${template}" > "${target}"
```

### New Variables for .aida Namespace

**Required additions**:

```bash
# Install-time variables
{{AIDA_NAMESPACE}}         # ".aida" (for future flexibility)
{{AIDA_VERSION}}           # Version installed
{{INSTALL_TIMESTAMP}}      # ISO-8601 timestamp
{{INSTALL_MODE}}           # "dev" or "normal"

# Runtime variables (preserve ${VAR} syntax)
${AIDA_COMMANDS_DIR}       # ${CLAUDE_CONFIG_DIR}/commands/.aida
${AIDA_AGENTS_DIR}         # ${CLAUDE_CONFIG_DIR}/agents/.aida
${AIDA_SKILLS_DIR}         # ${CLAUDE_CONFIG_DIR}/skills/.aida
```

### Recommended Substitution Architecture

**Three-tier variable resolution**:

```bash
# lib/installer-common/variables.sh

# Tier 1: Install-time variables ({{VAR}})
declare -A INSTALL_TIME_VARS=(
    [AIDA_HOME]="System variable: AIDA installation directory"
    [CLAUDE_CONFIG_DIR]="System variable: Claude configuration directory"
    [HOME]="System variable: User home directory"
    [AIDA_NAMESPACE]="System constant: Namespace for AIDA templates"
    [AIDA_VERSION]="System variable: AIDA framework version"
    [INSTALL_TIMESTAMP]="System variable: Installation timestamp"
    [INSTALL_MODE]="System variable: Installation mode (dev/normal)"
)

# Tier 2: Runtime variables (${VAR})
declare -A RUNTIME_VARS=(
    [PROJECT_ROOT]="Project variable: Current project directory"
    [GIT_ROOT]="Project variable: Git repository root"
    [USER]="System variable: Current username"
    [CLAUDE_CONFIG_DIR]="System variable: Claude config (for commands)"
    [AIDA_COMMANDS_DIR]="System variable: AIDA commands directory"
    [AIDA_AGENTS_DIR]="System variable: AIDA agents directory"
    [AIDA_SKILLS_DIR]="System variable: AIDA skills directory"
)

# Tier 3: Computed variables (evaluated at substitution time)
declare -A COMPUTED_VARS=(
    [INSTALL_TIMESTAMP]='$(date -u +%Y-%m-%dT%H:%M:%SZ)'
    [AIDA_NAMESPACE]='".aida"'
)

# Substitute install-time variables in template
substitute_install_time_vars() {
    local template="$1"
    local output="$2"
    local mode="${3:-normal}"

    # Build sed command for all install-time variables
    local sed_cmd=()

    # Standard variables
    sed_cmd+=(-e "s|{{AIDA_HOME}}|${AIDA_DIR}|g")
    sed_cmd+=(-e "s|{{CLAUDE_CONFIG_DIR}}|${CLAUDE_DIR}|g")
    sed_cmd+=(-e "s|{{HOME}}|${HOME}|g")

    # New namespace variables
    sed_cmd+=(-e "s|{{AIDA_NAMESPACE}}|.aida|g")
    sed_cmd+=(-e "s|{{AIDA_VERSION}}|${VERSION}|g")
    sed_cmd+=(-e "s|{{INSTALL_MODE}}|${mode}|g")

    # Computed variables
    local timestamp
    timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    sed_cmd+=(-e "s|{{INSTALL_TIMESTAMP}}|${timestamp}|g")

    # Execute substitution
    sed "${sed_cmd[@]}" "$template" > "$output"
}

# Validate template variables before installation
validate_template_vars() {
    local template="$1"
    local errors=0

    # Check for unsubstituted install-time variables after processing
    local unsubstituted
    unsubstituted=$(grep -oE '\{\{[A-Z_]+\}\}' "$template" || true)

    if [[ -n "$unsubstituted" ]]; then
        print_message "error" "Unsubstituted install-time variables in $template:"
        echo "$unsubstituted" | sort -u
        errors=$((errors + 1))
    fi

    # Verify runtime variables are preserved (not accidentally substituted)
    # Check that ${VAR} patterns exist where expected
    if ! grep -q '\${CLAUDE_CONFIG_DIR}' "$template"; then
        print_message "warning" "Template missing expected runtime variable: \${CLAUDE_CONFIG_DIR}"
    fi

    return "$errors"
}

# Document variables in template comments
generate_variable_documentation() {
    cat << 'EOF'
# Variable Substitution Reference

## Install-time Variables ({{VAR}})
Substituted during installation. Do not use these in user-editable configs.

- {{AIDA_HOME}} - AIDA installation directory (e.g., ~/.aida/)
- {{CLAUDE_CONFIG_DIR}} - Claude config directory (e.g., ~/.claude/)
- {{HOME}} - User home directory
- {{AIDA_NAMESPACE}} - Namespace for templates (.aida)
- {{AIDA_VERSION}} - Installed version (e.g., 0.2.0)
- {{INSTALL_TIMESTAMP}} - Installation timestamp (ISO-8601)
- {{INSTALL_MODE}} - Installation mode (dev or normal)

## Runtime Variables (${VAR})
Resolved when commands execute. Safe for user customization.

- ${PROJECT_ROOT} - Current project directory
- ${GIT_ROOT} - Git repository root
- ${USER} - Current username
- ${CLAUDE_CONFIG_DIR} - Claude config directory
- ${AIDA_COMMANDS_DIR} - AIDA commands (${CLAUDE_CONFIG_DIR}/commands/.aida)
- ${AIDA_AGENTS_DIR} - AIDA agents (${CLAUDE_CONFIG_DIR}/agents/.aida)
- ${AIDA_SKILLS_DIR} - AIDA skills (${CLAUDE_CONFIG_DIR}/skills/.aida)

## Usage Examples

Install-time (substituted during install.sh):

    source {{AIDA_HOME}}/lib/installer-common/logging.sh

Runtime (resolved when command runs):

    cd ${PROJECT_ROOT}
    source ${AIDA_COMMANDS_DIR}/common.sh

EOF
}
```

### Dev Mode vs Normal Mode Considerations

**Critical difference**:

- **Dev mode**: Symlink templates → NO substitution (use repo directly)
- **Normal mode**: Copy templates → FULL substitution

**Problem**: Commands in dev mode won't have variables substituted!

**Solution**: Conditional substitution wrapper

```bash
# In installed commands (both modes)
# Detect mode and resolve variables

# Check if running in dev mode (via symlink)
if [[ -L "${BASH_SOURCE[0]}" ]]; then
    # Dev mode: variables not substituted, resolve at runtime
    AIDA_HOME="$(readlink -f ~/.aida)"
    CLAUDE_CONFIG_DIR="${HOME}/.claude"
else
    # Normal mode: variables substituted at install-time
    AIDA_HOME="{{AIDA_HOME}}"
    CLAUDE_CONFIG_DIR="{{CLAUDE_CONFIG_DIR}}"
fi
```

---

## 3. Deprecation Schema Design

### Recommended Frontmatter Schema

**Full deprecation metadata**:

```yaml
---
name: "old-command"
description: "Legacy command (deprecated)"
deprecated: true
deprecation:
  deprecated_in: "0.2.0"
  remove_in: "0.3.0"
  removal_reason: "breaking-change"  # enum: breaking-change, superseded, unused
  canonical: "commands/.aida/new-command.md"
  migration_guide: "docs/migrations/old-to-new-command.md"
  announcement: "https://github.com/org/repo/discussions/123"
  severity: "warning"  # enum: info, warning, error
  auto_migrate: false  # if true, installer attempts automatic migration
---
```

**Validation schema** (JSON Schema format):

```yaml
deprecation:
  type: object
  required:
    - deprecated_in
    - remove_in
    - canonical
    - removal_reason
  properties:
    deprecated_in:
      type: string
      pattern: "^\\d+\\.\\d+\\.\\d+$"
      description: "Version when deprecation started"

    remove_in:
      type: string
      pattern: "^\\d+\\.\\d+\\.\\d+$"
      description: "Version when template will be removed"

    removal_reason:
      type: string
      enum:
        - "breaking-change"
        - "superseded"
        - "unused"
        - "security"
      description: "Why this template is deprecated"

    canonical:
      type: string
      pattern: "^(commands|agents|skills)/.aida/[a-z][a-z0-9-]+\\.md$"
      description: "Path to replacement template"

    migration_guide:
      type: string
      pattern: "^docs/migrations/.*\\.md$"
      description: "Documentation for migration path"

    announcement:
      type: string
      format: uri
      description: "URL to deprecation announcement"

    severity:
      type: string
      enum: ["info", "warning", "error"]
      default: "warning"
      description: "How prominently to warn users"

    auto_migrate:
      type: boolean
      default: false
      description: "Whether installer should auto-migrate"
```

### Additional Metadata for Lifecycle Management

**Status tracking**:

```yaml
status:
  lifecycle: "deprecated"  # enum: active, deprecated, removed
  maturity: "stable"       # enum: experimental, beta, stable, deprecated
  support_until: "2025-12-31"

maintenance:
  owner: "team-name"
  last_verified: "2025-10-01"
  verification_frequency: "quarterly"
```

**Version constraints**:

```yaml
compatibility:
  min_version: "0.1.0"
  max_version: "0.3.0"
  requires:
    - "lib/installer-common >= 1.0.0"
  conflicts_with:
    - "old-agent-name < 1.0.0"
```

### Deprecation Display Strategy

**Three-tier warning system**:

```bash
# lib/installer-common/deprecation.sh

display_deprecation_warning() {
    local template="$1"
    local severity="$2"
    local deprecated_in="$3"
    local remove_in="$4"
    local canonical="$5"
    local reason="$6"

    case "$severity" in
        info)
            print_message "info" "Template deprecated: ${template}"
            ;;
        warning)
            print_message "warning" "DEPRECATED: ${template}"
            echo "  Deprecated in: v${deprecated_in}"
            echo "  Will be removed in: v${remove_in}"
            echo "  Reason: ${reason}"
            echo "  Use instead: ${canonical}"
            ;;
        error)
            print_message "error" "DEPRECATED (CRITICAL): ${template}"
            echo "  Deprecated in: v${deprecated_in}"
            echo "  WILL BE REMOVED in: v${remove_in}"
            echo "  Reason: ${reason}"
            echo "  REQUIRED ACTION: Migrate to ${canonical}"
            echo ""
            read -rp "Install anyway? (not recommended) [y/N]: " response
            if [[ ! "$response" =~ ^[Yy]$ ]]; then
                return 1
            fi
            ;;
    esac
}

# Calculate deprecation severity based on version proximity
calculate_severity() {
    local current_version="$1"
    local remove_in="$2"

    local curr_major curr_minor curr_patch
    IFS='.' read -r curr_major curr_minor curr_patch <<< "$current_version"

    local rem_major rem_minor rem_patch
    IFS='.' read -r rem_major rem_minor rem_patch <<< "$remove_in"

    # If removal version is next major/minor, severity = error
    if [[ "$rem_major" -eq "$curr_major" ]] && \
       [[ "$rem_minor" -le $((curr_minor + 1)) ]]; then
        echo "error"
    else
        echo "warning"
    fi
}
```

---

## 4. Multi-Repo Integration Configuration

### Configuration Contract for Dotfiles Integration

**Critical requirement**: Dotfiles repo must be able to source `lib/installer-common/` from AIDA repo without tight coupling.

**Contract interface**:

```bash
# ~/.aida/lib/installer-common/api.sh
# Stable API for external consumers (dotfiles repo)

INSTALLER_COMMON_API_VERSION="1.0.0"

# Initialize installer-common library
init_installer_common() {
    local library_root="$1"

    # Source required modules in dependency order
    source "${library_root}/colors.sh"
    source "${library_root}/logging.sh"
    source "${library_root}/validation.sh"
    source "${library_root}/config.sh"
    source "${library_root}/variables.sh"
    source "${library_root}/templates.sh"
    source "${library_root}/deprecation.sh"

    # Initialize configuration
    load_installer_config

    print_message "info" "Installer-common v${INSTALLER_COMMON_API_VERSION} loaded"
}

# Validate API compatibility
check_api_compatibility() {
    local required_version="$1"

    check_version_compatibility \
        "$INSTALLER_COMMON_API_VERSION" \
        "$required_version"
}

# Export public functions for external use
export -f init_installer_common
export -f check_api_compatibility
```

**Dotfiles integration pattern**:

```bash
# ~/dotfiles/scripts/install-aida-templates.sh

set -euo pipefail

# Detect AIDA installation
readonly AIDA_HOME="${HOME}/.aida"
readonly INSTALLER_COMMON="${AIDA_HOME}/lib/installer-common"

if [[ ! -d "$INSTALLER_COMMON" ]]; then
    echo "Error: AIDA not found at ${AIDA_HOME}"
    echo "Install AIDA first: https://github.com/oakensoul/claude-personal-assistant"
    exit 1
fi

# Check if API exists (backward compatibility)
if [[ -f "${INSTALLER_COMMON}/api.sh" ]]; then
    source "${INSTALLER_COMMON}/api.sh"

    # Verify compatibility
    if ! check_api_compatibility "1.0.0"; then
        echo "Error: AIDA version incompatible"
        echo "Required: installer-common API >= 1.0.0"
        echo "Upgrade AIDA: cd ~/.aida && git pull && ./install.sh"
        exit 1
    fi

    # Initialize library
    init_installer_common "$INSTALLER_COMMON"
else
    # Fallback for older AIDA versions
    echo "Warning: Using legacy AIDA integration (pre-API)"
    source "${INSTALLER_COMMON}/colors.sh"
    source "${INSTALLER_COMMON}/logging.sh"
    source "${INSTALLER_COMMON}/validation.sh"
fi

# Now use installer-common functions
print_message "info" "Installing dotfiles AIDA templates..."
```

### Backward Compatibility Strategy

**Version detection pattern**:

```bash
# Detect installed AIDA version and adapt
detect_aida_version() {
    local version_file="${AIDA_HOME}/VERSION"

    if [[ ! -f "$version_file" ]]; then
        echo "unknown"
        return 1
    fi

    cat "$version_file"
}

# Check feature support
supports_namespace_installation() {
    local version
    version=$(detect_aida_version)

    # Namespace support added in 0.2.0
    check_version_compatibility "$version" "0.2.0"
}

supports_deprecation_system() {
    local version
    version=$(detect_aida_version)

    # Deprecation system added in 0.2.0
    check_version_compatibility "$version" "0.2.0"
}

# Conditional installation based on features
install_templates_with_fallback() {
    if supports_namespace_installation; then
        # Use new .aida namespace
        install_to_namespace ".aida"
    else
        # Fallback to root-level installation
        install_to_root
    fi
}
```

### Configuration File for Integration

**Shared configuration format**:

```yaml
# ~/.aida/config/installer.yml

aida:
  version: "0.2.0"
  install_mode: "normal"
  installation_date: "2025-10-18T12:00:00Z"

paths:
  aida_home: "~/.aida"
  claude_config: "~/.claude"
  namespace: ".aida"

features:
  namespace_isolation: true
  deprecation_system: true
  template_registry: true
  auto_migration: false

integrations:
  dotfiles:
    enabled: true
    repo: "~/dotfiles"
    templates_dir: "aida-templates"

api:
  version: "1.0.0"
  compatibility:
    min_consumer_version: "1.0.0"
```

**Loading configuration**:

```bash
# lib/installer-common/config.sh

load_installer_config_file() {
    local config_file="${AIDA_HOME}/config/installer.yml"

    if [[ ! -f "$config_file" ]]; then
        # Generate default config
        generate_default_config "$config_file"
    fi

    # Parse YAML (requires yq or python)
    if command -v yq &>/dev/null; then
        INSTALLER_CONFIG[VERSION]=$(yq '.aida.version' "$config_file")
        INSTALLER_CONFIG[NAMESPACE]=$(yq '.paths.namespace' "$config_file")
    else
        # Fallback: use defaults
        print_message "warning" "yq not found, using default configuration"
    fi
}
```

---

## 5. Questions & Recommendations

### Critical Questions

**Q1: How should dev mode handle variable substitution?**

- **Issue**: Symlinked templates can't have substituted variables
- **Recommendation**: Add runtime variable resolution wrapper in commands
- **Trade-off**: Slight performance cost vs maintainability

**Q2: Should deprecation warnings block installation?**

- **Issue**: Balancing user freedom vs preventing technical debt
- **Recommendation**: Three-tier severity (info/warning/error), only error blocks
- **Trade-off**: Flexibility vs safety

**Q3: How to handle namespace migration for existing users?**

- **Issue**: Users upgrading from 0.1.x to 0.2.x need templates moved
- **Recommendation**: Auto-detect old structure, prompt for migration
- **Trade-off**: Complexity vs user experience

**Q4: Should template registry use JSON or YAML?**

- **Issue**: JSON easier to parse in bash (jq), YAML more human-friendly
- **Recommendation**: JSON for machine-readable registry, YAML for config
- **Trade-off**: Consistency vs optimal tools

**Q5: How to version the installer-common API?**

- **Issue**: Breaking changes to lib/ functions affect dotfiles integration
- **Recommendation**: Semantic versioning with compatibility checks
- **Trade-off**: API stability vs rapid iteration

### Missing Configuration Aspects

#### 1. Template Categories/Tags

```yaml
# Add to template frontmatter
category: "workflow"
tags: ["git", "github", "automation"]
platforms: ["macos", "linux"]  # windows excluded
```

#### 2. Installation Profiles

```yaml
# ~/.aida/config/profiles.yml
profiles:
  minimal:
    templates: ["essential"]
  developer:
    templates: ["essential", "git", "github"]
  full:
    templates: ["*"]
    with_deprecated: false
```

#### 3. Post-Install Validation

```bash
# Validate installation integrity
validate_installation() {
    local errors=0

    # Check namespace structure
    if [[ ! -d "${CLAUDE_DIR}/commands/.aida" ]]; then
        print_message "error" "Missing namespace: commands/.aida"
        errors=$((errors + 1))
    fi

    # Verify registry
    if [[ ! -f "${CLAUDE_DIR}/.aida-registry.json" ]]; then
        print_message "warning" "Template registry not found"
    fi

    # Check variable substitution
    for template in "${CLAUDE_DIR}"/commands/.aida/*.md; do
        if grep -q '{{[A-Z_]*}}' "$template"; then
            print_message "error" "Unsubstituted variables in: $template"
            errors=$((errors + 1))
        fi
    done

    return "$errors"
}
```

#### 4. Rollback Configuration

```yaml
# ~/.aida/config/rollback.yml
rollback:
  enabled: true
  max_backups: 3
  backup_location: "~/.aida-backups"

  on_failure:
    action: "restore"  # restore | prompt | abort
    preserve_user_changes: true
```

### Recommended Patterns

#### Pattern 1: Configuration-driven installation

- Use YAML/JSON config to define what/how to install
- Make installer a "config interpreter" not "script executor"
- Easier to test, validate, and extend

#### Pattern 2: Registry-based tracking

- Track all installed templates in central registry
- Enable queries: "what's installed?", "what version?", "what's deprecated?"
- Support uninstall, upgrade, and migration

#### Pattern 3: Schema-first design

- Define JSON schemas for all config/metadata
- Validate before processing (fail fast)
- Auto-generate documentation from schemas

#### Pattern 4: Feature flags for backward compatibility

```bash
# Detect feature support before using
if supports_feature "namespace_isolation"; then
    install_to_namespace ".aida"
else
    install_to_root
fi
```

#### Pattern 5: Idempotent installation

```bash
# Re-running installer should be safe
install_template() {
    local template="$1"

    # Check if already installed
    if is_template_installed "$template"; then
        local installed_version
        installed_version=$(get_template_version "$template")

        if [[ "$installed_version" == "$VERSION" ]]; then
            print_message "info" "Template up-to-date: $template"
            return 0
        fi

        print_message "info" "Upgrading template: $template ($installed_version → $VERSION)"
    fi

    # Install/upgrade template
    # ...
}
```

### What to Avoid

#### Anti-Pattern 1: Hardcoded paths

```bash
# BAD: Hardcoded path
source ~/.aida/lib/installer-common/logging.sh

# GOOD: Variable-based path
source "${AIDA_HOME}/lib/installer-common/logging.sh"
```

#### Anti-Pattern 2: String-based validation

```bash
# BAD: Fragile string matching
if [[ "$template" == *"deprecated"* ]]; then

# GOOD: Structured metadata
if is_template_deprecated "$template"; then
```

#### Anti-Pattern 3: Silent failures

```bash
# BAD: Swallow errors
substitute_vars "$template" 2>/dev/null || true

# GOOD: Explicit error handling
if ! substitute_vars "$template"; then
    print_message "error" "Variable substitution failed: $template"
    return 1
fi
```

#### Anti-Pattern 4: Mixed concerns

```bash
# BAD: UI + logic + validation in one function
install_template() {
    echo "Installing..."
    if [[ ! -f "$template" ]]; then
        echo "Error"
        return 1
    fi
    cp "$template" "$dest"
    echo "Done"
}

# GOOD: Separated concerns
install_template() {
    validate_template "$template" || return 1
    copy_template "$template" "$dest" || return 1
    register_template "$template"
}
```

#### Anti-Pattern 5: Version-specific code

```bash
# BAD: Version-specific branches
if [[ "$version" == "0.2.0" ]]; then
    # special case
fi

# GOOD: Feature detection
if supports_namespace_installation; then
    # use feature
fi
```

---

## Configuration Architecture Recommendations

### High-Level Architecture

```text
┌─────────────────────────────────────────────────────────────┐
│                     Configuration Layer                      │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌────────────────┐  ┌─────────────────┐  ┌──────────────┐ │
│  │ installer.yml  │  │ profiles.yml   │  │ registry.json│ │
│  │ (system cfg)   │  │ (user prefs)   │  │ (state)      │ │
│  └────────────────┘  └─────────────────┘  └──────────────┘ │
│                                                               │
├─────────────────────────────────────────────────────────────┤
│                      Validation Layer                         │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────────┐  ┌──────────────────┐                 │
│  │ Schema Validator │  │ Variable Checker │                 │
│  │ (JSON Schema)    │  │ (install/runtime)│                 │
│  └──────────────────┘  └──────────────────┘                 │
│                                                               │
├─────────────────────────────────────────────────────────────┤
│                   Business Logic Layer                        │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐  ┌────────────────┐  ┌────────────────┐  │
│  │ templates.sh │  │ deprecation.sh │  │ variables.sh   │  │
│  └──────────────┘  └────────────────┘  └────────────────┘  │
│                                                               │
│  ┌──────────────┐  ┌────────────────┐  ┌────────────────┐  │
│  │ config.sh    │  │ registry.sh    │  │ migration.sh   │  │
│  └──────────────┘  └────────────────┘  └────────────────┘  │
│                                                               │
├─────────────────────────────────────────────────────────────┤
│                    Infrastructure Layer                       │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐  ┌────────────────┐  ┌────────────────┐  │
│  │ colors.sh    │  │ logging.sh     │  │ validation.sh  │  │
│  └──────────────┘  └────────────────┘  └────────────────┘  │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

### Module Dependency Graph

```text
api.sh
  └─> config.sh
       ├─> logging.sh
       │    └─> colors.sh
       └─> validation.sh
            └─> logging.sh

templates.sh
  ├─> variables.sh
  │    ├─> config.sh
  │    └─> validation.sh
  ├─> deprecation.sh
  │    ├─> config.sh
  │    └─> logging.sh
  └─> registry.sh
       └─> config.sh

migration.sh
  ├─> templates.sh
  ├─> registry.sh
  └─> validation.sh
```

### Configuration File Hierarchy

```text
~/.aida/
├── config/
│   ├── installer.yml       # System configuration
│   ├── profiles.yml        # Installation profiles
│   ├── api.yml             # API versioning config
│   └── rollback.yml        # Backup/rollback settings
├── schema/
│   ├── template.schema.json
│   ├── deprecation.schema.json
│   └── config.schema.json
└── lib/
    └── installer-common/
        ├── api.sh
        ├── config.sh
        ├── variables.sh
        ├── templates.sh
        ├── deprecation.sh
        ├── registry.sh
        ├── migration.sh
        └── validation.sh (extended)

~/.claude/
├── .aida-registry.json     # Template installation registry
├── commands/.aida/         # AIDA command templates
├── agents/.aida/           # AIDA agent templates
└── skills/.aida/           # AIDA skill templates
```

---

## Success Metrics

**Installation success rate**: 100% clean installs on supported platforms
**Backward compatibility**: Zero breaking changes for dotfiles integration
**Variable substitution accuracy**: Zero unresolved install-time variables
**Deprecation coverage**: 100% deprecated templates tracked in registry
**Configuration validation**: All config files pass schema validation
**Cross-repo integration**: Dotfiles can source lib/installer-common/ without modification

---

## Next Steps

**Immediate (blocking)**:

1. Define JSON schemas for template metadata and deprecation
2. Design variable substitution strategy for dev vs normal mode
3. Create configuration module (config.sh) with installer state management

**Short-term (v0.2.0)**:

1. Implement template registry system
2. Build deprecation detection and warning system
3. Create dotfiles integration API (api.sh)

**Long-term (v0.3.0+)**:

1. Add template migration automation
2. Implement installation profiles
3. Create rollback/restore functionality

---

## Related Files

- `/Users/rob/Develop/oakensoul/claude-personal-assistant/install.sh` - Current monolithic installer
- `/Users/rob/Develop/oakensoul/claude-personal-assistant/lib/installer-common/validation.sh` - Existing validation utilities
- `/Users/rob/Develop/oakensoul/claude-personal-assistant/scripts/validate-templates.sh` - Template validation script
- `/Users/rob/Develop/oakensoul/claude-personal-assistant/templates/commands/` - Command templates with variable substitution

**Configuration Specialist**: `/Users/rob/Develop/oakensoul/claude-personal-assistant/templates/agents/configuration-specialist/`
