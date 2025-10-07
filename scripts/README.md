---
title: "Scripts Directory"
description: "Utility scripts for AIDA development and maintenance"
category: "development"
tags: ["scripts", "utilities", "validation", "testing"]
last_updated: "2025-10-06"
status: "published"
audience: "developers"
---

# Scripts Directory

This directory contains utility scripts for AIDA development, maintenance, and validation.

## Available Scripts

### validate-templates.sh

Privacy validation script for AIDA template files.

**Purpose**: Scans template files for privacy issues including hardcoded paths, usernames, and user-specific identifiers.

**Usage**:

```bash
# Run validation with suggestions (default)
./scripts/validate-templates.sh

# Run in CI/CD (quiet mode - no suggestions)
./scripts/validate-templates.sh --quiet

# Verbose output for debugging
./scripts/validate-templates.sh --verbose

# Show help
./scripts/validate-templates.sh --help
```

**Exit Codes**:

- `0` - All templates pass validation
- `1` - Privacy issues found
- `2` - Script error or invalid usage

**What it checks**:

1. **Hardcoded Paths**:
   - Detects `/Users/username/` patterns (macOS)
   - Detects `/home/username/` patterns (Linux)
   - Flags `~/.claude` without `${CLAUDE_CONFIG_DIR}`
   - Flags `~/.aida` without `${AIDA_HOME}`

2. **Usernames**:
   - Detects specific usernames (e.g., "oakensoul")
   - Suggests replacing with `${USER}` or generic placeholders

3. **Email Addresses**:
   - Detects email patterns
   - Allows example emails (example.com, example.org)

4. **Credentials**:
   - Detects potential API keys or credentials
   - Flags suspicious long alphanumeric strings

5. **User-Specific Patterns**:
   - Detects references to specific projects
   - Flags learned patterns that might be personal

**Approved Variables**:

Templates should use these runtime variables instead of hardcoded paths:

- `${CLAUDE_CONFIG_DIR}` - User's Claude configuration directory (~/.claude)
- `${AIDA_HOME}` - AIDA installation directory (~/.aida)
- `${PROJECT_ROOT}` - Current project root
- `${USER}` - Current user
- `${HOME}` or `~` - Home directory

**Example Output**:

```text
Validating templates for privacy issues...

✗ templates/commands/create-issue.md:42
  Found hardcoded path: /Users/oakensoul/.claude
  Suggestion: Replace with ${CLAUDE_CONFIG_DIR}

✗ templates/agents/tech-lead/tech-lead.md:156
  Found username: oakensoul
  Suggestion: Use generic placeholder or ${USER}

✗ FAILED: 2 privacy issue(s) found

Next steps:
  1. Review the issues listed above
  2. Replace hardcoded paths with variables
  3. Remove or anonymize usernames and personal data
  4. Use placeholder values for examples
```

**Integration with Pre-commit**:

This script can be integrated into pre-commit hooks to automatically validate templates before commits:

```yaml
# .pre-commit-config.yaml
- repo: local
  hooks:
    - id: validate-templates
      name: Validate Templates Privacy
      entry: ./scripts/validate-templates.sh --quiet
      language: script
      pass_filenames: false
      always_run: true
```

**Best Practices**:

1. **Run before committing template changes**
2. **Use in CI/CD to catch privacy leaks**
3. **Fix all issues before archiving commands/agents to templates/**
4. **Review suggestions carefully - some may be false positives**

## Adding New Scripts

When adding new scripts to this directory:

1. **Follow naming conventions**: Use kebab-case (e.g., `validate-templates.sh`)
2. **Include usage documentation**: Add `--help` flag with clear examples
3. **Use proper exit codes**:
   - `0` for success
   - `1` for operational errors
   - `2` for usage errors
4. **Pass shellcheck**: Run `shellcheck script-name.sh` with zero warnings
5. **Use strict error handling**: Include `set -euo pipefail`
6. **Make executable**: `chmod +x script-name.sh`
7. **Document in this README**: Add section above

**Script template**:

```bash
#!/usr/bin/env bash
#
# script-name.sh - Brief description
#
# Detailed description of what this script does
#
# Exit codes:
#   0 - Success
#   1 - Operational error
#   2 - Usage error
#
# Usage:
#   ./scripts/script-name.sh [OPTIONS]
#

set -euo pipefail

# Your script here
```

## Script Standards

All scripts in this directory must:

1. **Pass shellcheck** with zero warnings
2. **Use `set -euo pipefail`** for error handling
3. **Use `readonly`** for constants
4. **Include comprehensive comments**
5. **Validate all user input**
6. **Provide helpful error messages**
7. **Support `--help` flag**
8. **Be executable** (chmod +x)
9. **Be Bash 3.2+ compatible** (for macOS support)

See [docs/CONTRIBUTING.md](../docs/CONTRIBUTING.md) for full development standards.

## Related Documentation

- [CONTRIBUTING.md](../docs/CONTRIBUTING.md) - Development guidelines
- [docs/architecture/](../docs/architecture/) - Architecture documentation
- [.pre-commit-config.yaml](../.pre-commit-config.yaml) - Pre-commit configuration
