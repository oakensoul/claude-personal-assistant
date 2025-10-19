#!/usr/bin/env bash
#
# demo-summary-integration.sh - Demonstration of summary.sh Integration
#
# Description:
#   Demonstrates how summary.sh integrates into an installer script.
#   Shows realistic installation flow with summary display.
#
# Usage:
#   ./demo-summary-integration.sh
#
# Author: oakensoul
# License: AGPL-3.0
# Repository: https://github.com/oakensoul/claude-personal-assistant
#

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# Source dependencies
# shellcheck source=lib/installer-common/colors.sh
source "${SCRIPT_DIR}/colors.sh"
# shellcheck source=lib/installer-common/logging.sh
source "${SCRIPT_DIR}/logging.sh"
# shellcheck source=lib/installer-common/summary.sh
source "${SCRIPT_DIR}/summary.sh"

# Demo configuration
readonly VERSION="v0.2.0"
readonly DEMO_MODE="${1:-normal}"  # normal or dev

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║       INSTALLATION SUMMARY INTEGRATION DEMONSTRATION           ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Simulate installation steps
print_message "info" "Starting AIDA framework installation..."
echo ""

print_message "info" "Creating directories..."
sleep 0.5
print_message "success" "Directories created"
echo ""

print_message "info" "Copying framework files..."
sleep 0.5
print_message "success" "Framework files copied"
echo ""

print_message "info" "Installing templates..."
sleep 0.5
print_message "success" "Templates installed"
echo ""

print_message "info" "Generating configuration..."
sleep 0.5
print_message "success" "Configuration generated"
echo ""

# Display installation summary
display_summary "$DEMO_MODE" \
    "$HOME/.aida" \
    "$HOME/.claude" \
    "$VERSION"

# Display next steps
display_next_steps "$DEMO_MODE"

# Final success message
display_success "Installation completed successfully!" \
    "You're all set! Start using AIDA by opening a new Claude Code session."

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "DEMONSTRATION COMPLETE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "This demonstrates how summary.sh integrates into install.sh:"
echo ""
echo "1. Installation steps use print_message() from logging.sh"
echo "2. Summary displays all installation details"
echo "3. Next steps provide actionable guidance"
echo "4. Final success message confirms completion"
echo ""
echo "Run with different modes:"
echo "  $0 normal  # Normal installation mode"
echo "  $0 dev     # Development installation mode"
echo ""
