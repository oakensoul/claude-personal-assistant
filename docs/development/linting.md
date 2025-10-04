---
title: "Linting and Code Quality"
description: "How to use linting tools for AIDA development"
category: "development"
tags: ["linting", "code-quality", "pre-commit", "ci-cd"]
last_updated: "2025-10-04"
status: "published"
audience: "developers"
---

# Linting and Code Quality

AIDA uses automated linting to ensure code quality and consistency across YAML configurations, shell scripts, and documentation.

## Tools Used

### yamllint
- **What:** YAML syntax and style checker
- **Validates:** Issue templates, agent configs, personality files, CI workflows
- **Config:** `.yamllint`

### ShellCheck
- **What:** Shell script analysis tool
- **Validates:** install.sh, CLI tools, helper scripts
- **Config:** `.shellcheckrc`

### markdownlint
- **What:** Markdown formatting and style checker
- **Validates:** Documentation, README files
- **Config:** `.markdownlint.json`

### gitleaks
- **What:** Secret and credential detection tool
- **Validates:** Prevents committing API keys, passwords, tokens, and other secrets
- **Config:** Built-in rules (no config file needed)

### pre-commit
- **What:** Git hook framework that runs linters before commits
- **Config:** `.pre-commit-config.yaml`

## Setup

### Local Development (Recommended)

**Install pre-commit:**

```bash
# macOS
brew install pre-commit

# or with pip
pip install pre-commit
```

**Install the git hooks:**

```bash
cd /path/to/claude-personal-assistant
pre-commit install
```

**That's it!** Linters will now run automatically before each commit.

### Manual Installation (Optional)

If you want to run linters manually without pre-commit:

**Install yamllint:**
```bash
# macOS
brew install yamllint

# or with pip
pip install yamllint
```

**Install shellcheck:**
```bash
# macOS
brew install shellcheck

# Ubuntu/Debian
apt-get install shellcheck
```

**Install markdownlint:**
```bash
npm install -g markdownlint-cli
```

**Install gitleaks:**
```bash
# macOS
brew install gitleaks

# Linux
# Download from https://github.com/gitleaks/gitleaks/releases
```

## Usage

### Automatic (via pre-commit)

Once installed, linters run automatically when you commit:

```bash
git add .
git commit -m "feat: add new feature"

# Pre-commit hooks run here automatically
# If linting fails, commit is blocked
```

**Bypass (not recommended):**
```bash
git commit --no-verify -m "skip linting"
```

### Manual Linting

**Run all linters:**
```bash
pre-commit run --all-files
```

**Run specific linter:**
```bash
# YAML only
yamllint .

# Shell scripts only
shellcheck **/*.sh

# Markdown only
markdownlint **/*.md

# Secret detection only
gitleaks detect --verbose
```

**Run on specific files:**
```bash
yamllint .github/ISSUE_TEMPLATE/bug-report.yml
shellcheck install.sh
markdownlint README.md
```

### Fix Issues Automatically

Some linters can auto-fix:

```bash
# Fix trailing whitespace, end-of-file, etc.
pre-commit run --all-files

# Fix markdown formatting
markdownlint --fix **/*.md
```

## CI/CD Integration

### GitHub Actions

Linting runs automatically on every PR via `.github/workflows/lint.yml`:

**Jobs:**
1. **yaml-lint** - Validates all YAML files
2. **shellcheck** - Validates all shell scripts
3. **markdown-lint** - Validates all markdown files
4. **pre-commit** - Runs all pre-commit hooks
5. **gitleaks** - Scans for secrets and credentials

**PRs cannot merge if linting fails.**

### Viewing Results

**In PR:**
- GitHub shows ✅ or ❌ next to "Lint" check
- Click "Details" to see which files failed
- Fix issues and push to update PR

**Locally:**
```bash
# See what would fail in CI
pre-commit run --all-files
```

## Configuration

### yamllint (.yamllint)

**Key rules:**
- Max line length: 120 characters (warning)
- Indentation: 2 spaces
- Allow both single/double quotes
- Allow `yes/no` and `true/false`
- Unix line endings (LF)

**Ignored paths:**
- `.github/workflows/` (handled by GitHub's validator)
- `node_modules/`
- `.venv/`

**Customize:**
```yaml
# .yamllint
rules:
  line-length:
    max: 100  # Change max line length
```

### ShellCheck (.shellcheckrc)

**Key settings:**
- Shell dialect: bash
- Severity: warning (not style suggestions)
- Disabled warnings:
  - SC2034 (unused variables - intentional for docs)
  - SC2154 (sourced variables)
  - SC1090/SC1091 (can't follow source)

**Customize:**
```bash
# .shellcheckrc
disable=SC2086  # Disable specific warning
severity=info    # Show more suggestions
```

### markdownlint (.markdownlint.json)

**Disabled rules:**
- MD013 (line length) - Allow long lines
- MD033 (HTML) - Allow HTML in markdown
- MD041 (first line heading) - Not required

**Customize:**
```json
{
  "MD013": { "line_length": 100 }
}
```

### Pre-commit (.pre-commit-config.yaml)

**Hooks included:**
- trailing-whitespace
- end-of-file-fixer
- check-yaml
- check-json
- check-added-large-files
- check-merge-conflict
- mixed-line-ending
- yamllint
- shellcheck
- gitleaks
- markdownlint

**Add new hooks:**
```yaml
repos:
  - repo: https://github.com/example/new-linter
    rev: v1.0.0
    hooks:
      - id: new-linter-id
```

## Common Issues

### Pre-commit hook fails on commit

**Error:** `yamllint....................................................Failed`

**Solution:**
1. See which file failed: `pre-commit run --all-files`
2. Fix the issue manually
3. Re-commit

**Quick fix:**
```bash
# Auto-fix what can be fixed
pre-commit run --all-files

# Review remaining issues
git diff

# Commit fixes
git add .
git commit -m "fix: resolve linting issues"
```

### ShellCheck warnings in new scripts

**Error:** `SC2086: Double quote to prevent globbing`

**Solution:**
```bash
# Before (warning)
echo $variable

# After (fixed)
echo "$variable"
```

**Common fixes:**
- Quote variables: `"$var"`
- Quote arrays: `"${array[@]}"`
- Check file exists: `[[ -f "$file" ]]`

### YAML indentation errors

**Error:** `[error] wrong indentation: expected 2 but found 4`

**Solution:**
- AIDA uses 2-space indentation
- Check for tabs (should be spaces)
- Use editor auto-format

**Quick fix in VSCode:**
```
Cmd+Shift+P → "Format Document"
```

### Markdown link warnings

**Error:** `MD051: Link fragments should be valid`

**Solution:**
- Fix broken links
- Or disable check if intentional:
```json
{
  "MD051": false
}
```

### Gitleaks detects a false positive

**Error:** `gitleaks....................................................Failed`

**Solution:**
1. Verify it's actually a false positive (not a real secret)
2. Add to `.gitleaksignore` file:
```
# False positive: example API key in documentation
docs/examples/api-example.md:12
```

**Common false positives:**
- Example code with placeholder tokens
- Public test keys
- Hash values that look like secrets

**Never ignore real secrets!** If gitleaks finds an actual secret:
1. Remove it from the file
2. Rotate the credential immediately
3. Use environment variables or secret management instead

## Best Practices

### Before Committing

✅ **DO:**
- Run `pre-commit run --all-files` on large changes
- Fix linting issues before requesting review
- Add `.shellcheckrc` exceptions with comments explaining why

❌ **DON'T:**
- Use `--no-verify` to bypass linting (creates tech debt)
- Disable linting rules without documenting why
- Commit files with known linting errors

### Writing Shell Scripts

**Use shellcheck directives:**
```bash
#!/usr/bin/env bash

# shellcheck disable=SC2034  # Variable used in sourced file
UNUSED_VAR="value"

# shellcheck source=/dev/null  # Can't validate sourced file
source ./config.sh
```

### Writing YAML

**Follow conventions:**
```yaml
# Good - 2 space indentation, quoted strings
name: Example
description: "This is a description"
options:
  - option1
  - option2

# Bad - 4 space indentation, inconsistent quotes
name:    Example
description:    'This is a description'
options:
    -    option1
    -    option2
```

### Updating Linting Rules

**When to update:**
- Rule is too strict for AIDA's use case
- Rule blocks valid patterns
- Project conventions change

**How to update:**
1. Edit config file (`.yamllint`, `.shellcheckrc`, etc.)
2. Document reason in comments
3. Run `pre-commit run --all-files` to test
4. Commit config change

## Troubleshooting

### Pre-commit not running

**Check installation:**
```bash
pre-commit --version
ls .git/hooks/pre-commit
```

**Reinstall:**
```bash
pre-commit install
```

### Linting passes locally but fails in CI

**Likely cause:** Different versions of linters

**Solution:**
```bash
# Update pre-commit hooks to match CI
pre-commit autoupdate

# Run with same config as CI
pre-commit run --all-files
```

### Too many linting errors on existing files

**Solution:** Fix incrementally
```bash
# Only lint staged files
pre-commit run

# Or fix file by file
yamllint path/to/file.yml
# Fix issues
git add path/to/file.yml
```

## Resources

**Documentation:**
- [yamllint docs](https://yamllint.readthedocs.io/)
- [ShellCheck wiki](https://www.shellcheck.net/wiki/)
- [markdownlint rules](https://github.com/DavidAnson/markdownlint/blob/main/doc/Rules.md)
- [pre-commit hooks](https://pre-commit.com/hooks.html)

**Quick reference:**
```bash
# List all available linters
pre-commit run --help

# Update all hooks
pre-commit autoupdate

# Clean hook cache
pre-commit clean

# Uninstall hooks
pre-commit uninstall
```

## Contributing

When contributing to AIDA:
1. ✅ Install pre-commit hooks
2. ✅ Ensure linting passes before pushing
3. ✅ Fix any CI linting failures promptly
4. ✅ Document any linting exceptions

See [CONTRIBUTING.md](../../CONTRIBUTING.md) for full guidelines.

---

**Questions about linting?** Open an issue with `type:question`!
