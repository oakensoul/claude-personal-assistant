#!/usr/bin/env bash
#
# EXAMPLE-config-usage.sh - Config Helper Usage Examples
#
# Description:
#   Demonstrates how workflow commands and install.sh will use the
#   universal config aggregator (aida-config-helper.sh). Shows before/after
#   comparison of variable substitution vs runtime config resolution.
#
# Usage:
#   ./lib/installer-common/EXAMPLE-config-usage.sh
#
# Part of: AIDA installer-common library v1.0
# Author: oakensoul
# License: AGPL-3.0
# Repository: https://github.com/oakensoul/claude-personal-assistant
#

set -euo pipefail

# Script directory detection
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly CONFIG_HELPER="${SCRIPT_DIR}/../aida-config-helper.sh"

# Color codes
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

#######################################
# Print section header
# Arguments:
#   $1 - Section title
#######################################
print_header() {
    echo ""
    echo -e "${BLUE}=========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}=========================================${NC}"
    echo ""
}

#######################################
# Print example title
# Arguments:
#   $1 - Example number
#   $2 - Example title
#######################################
print_example() {
    echo -e "${GREEN}Example $1: $2${NC}"
    echo ""
}

#######################################
# Print code block
# Arguments:
#   $@ - Code lines
#######################################
print_code() {
    echo -e "${YELLOW}Code:${NC}"
    for line in "$@"; do
        echo "  $line"
    done
    echo ""
}

#######################################
# Example 1: Basic config retrieval
#######################################
example_basic_usage() {
    print_example "1" "Basic Config Retrieval"

    echo "Getting AIDA installation directory:"
    aida_home=$("$CONFIG_HELPER" --key paths.aida_home)
    echo "  AIDA_HOME: $aida_home"
    echo ""

    echo "Getting Claude config directory:"
    claude_config_dir=$("$CONFIG_HELPER" --key paths.claude_config_dir)
    echo "  CLAUDE_CONFIG_DIR: $claude_config_dir"
    echo ""

    echo "Getting project root:"
    project_root=$("$CONFIG_HELPER" --key paths.project_root)
    echo "  PROJECT_ROOT: $project_root"
    echo ""
}

#######################################
# Example 2: Namespace retrieval (efficient)
#######################################
example_namespace_usage() {
    print_example "2" "Namespace Retrieval (Efficient)"

    echo "Getting all GitHub config at once:"
    github_config=$("$CONFIG_HELPER" --namespace github)
    echo "$github_config" | jq .
    echo ""

    echo "Extracting individual values:"
    owner=$(echo "$github_config" | jq -r '.owner')
    repo=$(echo "$github_config" | jq -r '.repo')
    main_branch=$(echo "$github_config" | jq -r '.main_branch')
    echo "  Owner: $owner"
    echo "  Repo: $repo"
    echo "  Main branch: $main_branch"
    echo ""
}

#######################################
# Example 3: Full config inspection
#######################################
example_full_config() {
    print_example "3" "Full Config Inspection"

    echo "Getting entire merged config:"
    echo ""
    "$CONFIG_HELPER" | jq '{
        system: .system,
        paths: .paths,
        user: .user,
        git: .git.user
    }'
    echo ""
}

#######################################
# Example 4: Config validation
#######################################
example_validation() {
    print_example "4" "Config Validation"

    echo "Validating configuration:"
    if "$CONFIG_HELPER" --validate; then
        echo -e "  ${GREEN}✓ Configuration is valid${NC}"
    else
        echo -e "  ${YELLOW}⚠ Configuration validation failed${NC}"
    fi
    echo ""
}

#######################################
# Example 5: Environment variable override
#######################################
example_environment_override() {
    print_example "5" "Environment Variable Override"

    echo "Default editor:"
    default_editor=$("$CONFIG_HELPER" --key env.editor || echo "(not set)")
    echo "  EDITOR: $default_editor"
    echo ""

    echo "Overriding with environment variable:"
    custom_editor=$(EDITOR="custom-vim" "$CONFIG_HELPER" --key env.editor)
    echo "  EDITOR=custom-vim"
    echo "  Result: $custom_editor"
    echo ""
}

#######################################
# Example 6: Workflow command pattern
#######################################
example_workflow_pattern() {
    print_example "6" "Workflow Command Pattern"

    print_code \
        "#!/usr/bin/env bash" \
        "# Workflow command using config helper" \
        "" \
        "readonly CONFIG_HELPER=\"\${AIDA_HOME}/lib/aida-config-helper.sh\"" \
        "" \
        "# Get config at start" \
        "GITHUB_CONFIG=\$(\"\$CONFIG_HELPER\" --namespace github)" \
        "OWNER=\$(echo \"\$GITHUB_CONFIG\" | jq -r '.owner')" \
        "REPO=\$(echo \"\$GITHUB_CONFIG\" | jq -r '.repo')" \
        "" \
        "# Use in command" \
        "gh issue list --owner \"\$OWNER\" --repo \"\$REPO\""

    echo "Simulating workflow pattern:"
    github_config=$("$CONFIG_HELPER" --namespace github)
    owner=$(echo "$github_config" | jq -r '.owner')
    repo=$(echo "$github_config" | jq -r '.repo')
    echo "  Would run: gh issue list --owner \"$owner\" --repo \"$repo\""
    echo ""
}

#######################################
# Example 7: Before/After comparison
#######################################
example_before_after() {
    print_example "7" "Before/After Comparison"

    echo -e "${YELLOW}BEFORE (v0.1.x - Variable Substitution):${NC}"
    print_code \
        "# install.sh substitutes at install time" \
        "sed -e \"s|{{AIDA_HOME}}|\${AIDA_HOME}|g\" \\" \
        "    -e \"s|{{CLAUDE_CONFIG_DIR}}|\${CLAUDE_CONFIG_DIR}|g\" \\" \
        "    template.sh > output.sh" \
        "" \
        "# Problem: Stale if directories move"

    echo -e "${YELLOW}AFTER (v0.2.0+ - Runtime Resolution):${NC}"
    print_code \
        "# Template calls config helper at runtime" \
        "readonly CONFIG_HELPER=\"\${AIDA_HOME}/lib/aida-config-helper.sh\"" \
        "" \
        "AIDA_HOME=\$(\"\$CONFIG_HELPER\" --key paths.aida_home)" \
        "CLAUDE_CONFIG_DIR=\$(\"\$CONFIG_HELPER\" --key paths.claude_config_dir)" \
        "" \
        "# Benefit: Always current, adapts to changes"
}

#######################################
# Example 8: Caching demonstration
#######################################
example_caching() {
    print_example "8" "Caching Performance"

    echo "Clearing cache to demonstrate caching effect..."
    "$CONFIG_HELPER" --clear-cache >/dev/null 2>&1
    echo ""

    echo "First call (uncached - reads files, merges config):"
    time "$CONFIG_HELPER" >/dev/null 2>&1
    echo ""

    echo "Second call (cached - returns cached result):"
    time "$CONFIG_HELPER" >/dev/null 2>&1
    echo ""

    echo "Third call (still cached):"
    time "$CONFIG_HELPER" >/dev/null 2>&1
    echo ""

    echo -e "${GREEN}Note: Second and third calls should be significantly faster${NC}"
    echo ""
}

#######################################
# Example 9: Error handling
#######################################
example_error_handling() {
    print_example "9" "Error Handling"

    echo "Attempting to get non-existent key:"
    if ! "$CONFIG_HELPER" --key invalid.key.path 2>/dev/null; then
        echo -e "  ${YELLOW}✓ Correctly returned error for invalid key${NC}"
    fi
    echo ""

    echo "Attempting to get valid key:"
    if value=$("$CONFIG_HELPER" --key paths.home 2>/dev/null); then
        echo -e "  ${GREEN}✓ Got value: $value${NC}"
    fi
    echo ""
}

#######################################
# Example 10: Config priority demonstration
#######################################
example_priority() {
    print_example "10" "Config Priority Demonstration"

    echo "Config priority (highest to lowest):"
    echo "  1. Environment variables"
    echo "  2. Project AIDA config (.aida/config.json)"
    echo "  3. Workflow config (.github/workflow-config.json)"
    echo "  4. GitHub config (.github/GITHUB_CONFIG.json)"
    echo "  5. Git config (~/.gitconfig, .git/config)"
    echo "  6. User AIDA config (~/.claude/aida-config.json)"
    echo "  7. System defaults (built-in)"
    echo ""

    echo "Example: EDITOR setting"
    echo "  System default: (empty)"

    # Try to get from git config
    git_editor=$(git config core.editor 2>/dev/null || echo "(not set in git)")
    echo "  Git config: $git_editor"

    # Try to get from environment
    env_editor="${EDITOR:-(not set in environment)}"
    echo "  Environment: $env_editor"

    # Get from config helper (shows priority resolution)
    final_editor=$("$CONFIG_HELPER" --key env.editor || echo "(not resolved)")
    echo "  Config helper result: $final_editor"
    echo ""

    echo -e "${GREEN}The config helper merged all sources and applied priority${NC}"
    echo ""
}

#######################################
# Main entry point
#######################################
main() {
    print_header "AIDA Config Helper - Usage Examples"

    echo "This script demonstrates various ways to use aida-config-helper.sh"
    echo "in workflow commands, installation scripts, and other contexts."
    echo ""

    # Run all examples
    example_basic_usage
    example_namespace_usage
    example_full_config
    example_validation
    example_environment_override
    example_workflow_pattern
    example_before_after
    example_caching
    example_error_handling
    example_priority

    print_header "Summary"

    echo "Key Takeaways:"
    echo ""
    echo "1. Use --key for single values"
    echo "2. Use --namespace for related config (more efficient)"
    echo "3. Validate config early with --validate"
    echo "4. Environment variables override all other sources"
    echo "5. Caching makes subsequent calls ~90% faster"
    echo "6. No variable substitution needed - runtime resolution"
    echo ""

    echo "For more information:"
    echo "  - Documentation: lib/installer-common/README-config-aggregator.md"
    echo "  - Validation tests: lib/installer-common/validate-config-helper.sh"
    echo "  - API: lib/aida-config-helper.sh --help"
    echo ""
}

# Run main if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
