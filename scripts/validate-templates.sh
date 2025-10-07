#!/usr/bin/env bash
#
# validate-templates.sh - Privacy validation for AIDA template files
#
# Scans template files for privacy issues including hardcoded paths,
# usernames, and user-specific identifiers.
#
# Exit codes:
#   0 - All templates pass validation
#   1 - Privacy issues found
#   2 - Script error or invalid usage
#
# Usage:
#   ./scripts/validate-templates.sh [--verbose] [--fix]
#
# Options:
#   --verbose    Show detailed scanning progress
#   --fix        Show suggestions for fixing issues (default: enabled)
#   --quiet      Only show errors, suppress suggestions
#

set -euo pipefail

# Script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly PROJECT_ROOT
readonly TEMPLATES_DIR="${PROJECT_ROOT}/templates"

# Approved variable patterns that should be used in templates
# shellcheck disable=SC2016
readonly APPROVED_VARS=(
  '${CLAUDE_CONFIG_DIR}'
  '${PROJECT_ROOT}'
  '${AIDA_HOME}'
  '${USER}'
  '${HOME}'
  '~'
)

# Approved template variables for install-time substitution
readonly APPROVED_TEMPLATE_VARS=(
  'AIDA_HOME'
  'CLAUDE_CONFIG_DIR'
  'HOME'
  'PROJECT_ROOT'
)

# Color codes for output (disable if not a tty)
if [[ -t 1 ]]; then
  readonly RED='\033[0;31m'
  readonly GREEN='\033[0;32m'
  readonly YELLOW='\033[1;33m'
  readonly BLUE='\033[0;34m'
  readonly BOLD='\033[1m'
  readonly NC='\033[0m' # No Color
else
  readonly RED=''
  readonly GREEN=''
  readonly YELLOW=''
  readonly BLUE=''
  readonly BOLD=''
  readonly NC=''
fi

# Configuration
VERBOSE=false
SHOW_SUGGESTIONS=true
ISSUE_COUNT=0

# Parse arguments
parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --verbose)
        VERBOSE=true
        shift
        ;;
      --fix)
        SHOW_SUGGESTIONS=true
        shift
        ;;
      --quiet)
        SHOW_SUGGESTIONS=false
        shift
        ;;
      --help|-h)
        show_usage
        exit 0
        ;;
      *)
        echo -e "${RED}Error: Unknown option: $1${NC}" >&2
        show_usage
        exit 2
        ;;
    esac
  done
}

# Show usage information
show_usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Privacy validation for AIDA template files.

OPTIONS:
  --verbose     Show detailed scanning progress
  --fix         Show suggestions for fixing issues (default)
  --quiet       Only show errors, suppress suggestions
  --help, -h    Show this help message

EXIT CODES:
  0 - All templates pass validation
  1 - Privacy issues found
  2 - Script error or invalid usage

EXAMPLES:
  # Run validation with suggestions
  ./scripts/validate-templates.sh

  # Run in CI/CD (quiet mode)
  ./scripts/validate-templates.sh --quiet

  # Verbose output for debugging
  ./scripts/validate-templates.sh --verbose
EOF
}

# Log verbose messages
log_verbose() {
  if [[ "${VERBOSE}" == "true" ]]; then
    echo -e "${BLUE}[VERBOSE]${NC} $*"
  fi
}

# Log error with formatting
log_error() {
  local file="$1"
  local line_num="$2"
  local message="$3"
  local suggestion="${4:-}"

  echo ""
  echo -e "${RED}✗${NC} ${BOLD}${file}:${line_num}${NC}"
  echo -e "  ${message}"

  if [[ -n "${suggestion}" && "${SHOW_SUGGESTIONS}" == "true" ]]; then
    echo -e "  ${YELLOW}Suggestion:${NC} ${suggestion}"
  fi

  ISSUE_COUNT=$((ISSUE_COUNT + 1))
}

# Check for hardcoded absolute paths
check_hardcoded_paths() {
  local file="$1"
  local line_num=0

  while IFS= read -r line; do
    ((line_num++))

    # Skip empty lines and comments
    [[ -z "${line}" || "${line}" =~ ^[[:space:]]*# ]] && continue

    # Detect /Users/ paths (macOS)
    if echo "${line}" | grep -qE '(^|[^$])/Users/[^/]+(/|$)'; then
      # Extract the problematic path
      local path
      path=$(echo "${line}" | grep -oE '/Users/[^/]+[^[:space:]]*' | head -1)
      log_error "${file}" "${line_num}" \
        "Found hardcoded macOS path: ${path}" \
        "Replace with \${HOME} or appropriate variable"
    fi

    # Detect /home/ paths (Linux)
    if echo "${line}" | grep -qE '(^|[^$])/home/[^/]+(/|$)'; then
      local path
      path=$(echo "${line}" | grep -oE '/home/[^/]+[^[:space:]]*' | head -1)
      log_error "${file}" "${line_num}" \
        "Found hardcoded Linux path: ${path}" \
        "Replace with \${HOME} or appropriate variable"
    fi

    # Detect ~/.claude/ without variable substitution
    # shellcheck disable=SC2088
    if echo "${line}" | grep -qE '~/.claude([^/]|$)' && ! echo "${line}" | grep -qE '\$\{CLAUDE_CONFIG_DIR\}'; then
      log_error "${file}" "${line_num}" \
        "Found hardcoded config path: ~/.claude" \
        "Replace with \${CLAUDE_CONFIG_DIR} or ~/.claude/ references should use variables"
    fi

    # Detect ~/.aida/ without variable substitution
    # shellcheck disable=SC2088
    if echo "${line}" | grep -qE '~/.aida([^/]|$)' && ! echo "${line}" | grep -qE '\$\{AIDA_HOME\}'; then
      log_error "${file}" "${line_num}" \
        "Found hardcoded AIDA path: ~/.aida" \
        "Replace with \${AIDA_HOME}"
    fi
  done < "$file"
}

# Check for specific usernames
check_usernames() {
  local file="$1"
  local line_num=0

  # List of usernames to detect (add more as needed)
  local usernames=(
    "oakensoul"
  )

  while IFS= read -r line; do
    ((line_num++))

    # Skip empty lines and comments
    [[ -z "${line}" || "${line}" =~ ^[[:space:]]*# ]] && continue

    for username in "${usernames[@]}"; do
      # Case-insensitive search, but not in variable names or email domains
      if echo "${line}" | grep -qiE "(^|[^a-zA-Z0-9_-])${username}([^a-zA-Z0-9_-]|$)"; then
        # Skip if it's part of a variable name like ${OAKENSOUL_VAR}
        if echo "${line}" | grep -qE '\$\{[^}]*'"${username}"'[^}]*\}'; then
          continue
        fi

        log_error "${file}" "${line_num}" \
          "Found username: ${username}" \
          "Replace with \${USER} or generic placeholder"
      fi
    done
  done < "$file"
}

# Check for email addresses
check_emails() {
  local file="$1"
  local line_num=0

  while IFS= read -r line; do
    ((line_num++))

    # Skip empty lines and comments
    [[ -z "${line}" || "${line}" =~ ^[[:space:]]*# ]] && continue

    # Detect email patterns
    if echo "${line}" | grep -qE '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'; then
      local email
      email=$(echo "${line}" | grep -oE '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' | head -1)

      # Allow example emails
      if echo "${email}" | grep -qE '(example\.com|example\.org|user@|admin@.*example)'; then
        continue
      fi

      log_error "${file}" "${line_num}" \
        "Found email address: ${email}" \
        "Replace with example email (user@example.com) or remove"
    fi
  done < "$file"
}

# Check for potential API keys or credentials
check_credentials() {
  local file="$1"
  local line_num=0

  while IFS= read -r line; do
    ((line_num++))

    # Skip empty lines and comments
    [[ -z "${line}" || "${line}" =~ ^[[:space:]]*# ]] && continue

    # Check for common credential patterns
    if echo "${line}" | grep -qiE '(api[_-]?key|api[_-]?secret|password|token|secret[_-]?key)[[:space:]]*[:=][[:space:]]*['\''"][^'\''"]+['\''"]'; then
      # Allow placeholder values
      if echo "${line}" | grep -qiE '(your[_-]|my[_-]|example|placeholder|xxx|***|\.\.\.)'; then
        continue
      fi

      log_error "${file}" "${line_num}" \
        "Potential credential found" \
        "Use placeholder value or reference environment variable"
    fi

    # Check for long alphanumeric strings that might be keys (32+ chars)
    if echo "${line}" | grep -qE '['\''"][a-zA-Z0-9]{32,}['\''"]'; then
      # Skip if it looks like a hash example or placeholder
      if echo "${line}" | grep -qiE '(example|placeholder|hash|checksum|xxx|abc|123)'; then
        continue
      fi

      log_error "${file}" "${line_num}" \
        "Suspicious long alphanumeric string (possible API key)" \
        "Verify this is not a real credential"
    fi
  done < "$file"
}

# Check for user-specific learned patterns
check_learned_patterns() {
  local file="$1"
  local line_num=0

  while IFS= read -r line; do
    ((line_num++))

    # Skip empty lines and comments
    [[ -z "${line}" || "${line}" =~ ^[[:space:]]*# ]] && continue

    # Check for references to specific projects (that might be personal)
    # This is a heuristic - may need tuning
    if echo "${line}" | grep -qE '(my-project|personal-project|client-name)'; then
      log_error "${file}" "${line_num}" \
        "Found reference to specific project" \
        "Use generic placeholder or {project-name} variable"
    fi
  done < "$file"
}

# Check template variable syntax in command templates
check_template_variables() {
  local file="$1"
  local line_num=0

  # Only check files in templates/commands/ directory
  if [[ "${file}" != *"/templates/commands/"* ]]; then
    return 0
  fi

  while IFS= read -r line; do
    ((line_num++))

    # Skip empty lines and comments
    [[ -z "${line}" || "${line}" =~ ^[[:space:]]*# ]] && continue

    # Check for {{VAR}} template variables
    if echo "${line}" | grep -qE '\{\{[A-Z_]+\}\}'; then
      # Extract all template variables from this line
      local vars
      vars=$(echo "${line}" | grep -oE '\{\{[A-Z_]+\}\}')

      # Check each variable against approved list
      while IFS= read -r var; do
        # Remove {{ and }}
        local var_name
        var_name=$(echo "${var}" | sed 's/{{//g; s/}}//g')

        # Check if variable is approved
        local approved=false
        for approved_var in "${APPROVED_TEMPLATE_VARS[@]}"; do
          if [[ "${var_name}" == "${approved_var}" ]]; then
            approved=true
            break
          fi
        done

        if [[ "${approved}" == "false" ]]; then
          log_error "${file}" "${line_num}" \
            "Unknown template variable: ${var}" \
            "Only approved variables are allowed: $(printf "{{%s}} " "${APPROVED_TEMPLATE_VARS[@]}")"
        fi
      done <<< "${vars}"
    fi
  done < "$file"
}

# Validate a single template file
validate_file() {
  local file="$1"

  log_verbose "Scanning: ${file}"

  # Run all checks
  check_hardcoded_paths "$file"
  check_usernames "$file"
  check_emails "$file"
  check_credentials "$file"
  check_learned_patterns "$file"
  check_template_variables "$file"
}

# Find and validate all template files
validate_templates() {
  echo -e "${BOLD}Validating templates for privacy issues...${NC}"
  echo ""

  # Check templates directory exists
  if [[ ! -d "${TEMPLATES_DIR}" ]]; then
    echo -e "${RED}Error: Templates directory not found: ${TEMPLATES_DIR}${NC}" >&2
    exit 2
  fi

  # Find all .md files in templates/
  local template_files=()
  while IFS= read -r file; do
    template_files+=("$file")
  done < <(find "${TEMPLATES_DIR}" -type f -name "*.md" | sort)

  if [[ ${#template_files[@]} -eq 0 ]]; then
    echo -e "${YELLOW}Warning: No template files found in ${TEMPLATES_DIR}${NC}"
    exit 0
  fi

  log_verbose "Found ${#template_files[@]} template files to validate"

  # Validate each file
  for file in "${template_files[@]}"; do
    # Convert to relative path for cleaner output (not used currently)
    # local rel_path="${file#"${PROJECT_ROOT}"/}"
    validate_file "$file"
  done
}

# Main execution
main() {
  parse_args "$@"

  # Run validation
  validate_templates

  # Report results
  echo ""
  if [[ ${ISSUE_COUNT} -eq 0 ]]; then
    echo -e "${GREEN}✓ SUCCESS:${NC} All templates passed privacy validation"
    exit 0
  else
    echo -e "${RED}✗ FAILED:${NC} ${ISSUE_COUNT} privacy issue(s) found"
    echo ""
    echo -e "${BOLD}Next steps:${NC}"
    echo "  1. Review the issues listed above"
    echo "  2. Replace hardcoded paths with variables:"
    echo "     - Use \${CLAUDE_CONFIG_DIR} for ~/.claude/"
    echo "     - Use \${AIDA_HOME} for ~/.aida/"
    echo "     - Use \${PROJECT_ROOT} for project paths"
    echo "     - Use \${HOME} or ~ for home directory"
    echo "  3. Remove or anonymize usernames and personal data"
    echo "  4. Use placeholder values for examples"
    echo ""
    exit 1
  fi
}

# Run main function
main "$@"
