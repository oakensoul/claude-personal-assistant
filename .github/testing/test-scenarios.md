---
title: "Test Scenarios"
description: "Comprehensive test scenarios for AIDA framework installation"
category: "testing"
tags: ["testing", "qa", "scenarios", "validation"]
last_updated: "2025-10-05"
status: "published"
audience: "developers"
---

# AIDA Framework Test Scenarios

Comprehensive test scenarios for validating the AIDA framework installation across all supported platforms.

## Test Environment Matrix

| Platform | Environment | Status | Documentation |
|----------|-------------|--------|---------------|
| Linux | Ubuntu 22.04 | ✅ Supported | [Docker](../docker/README.md) |
| Linux | Ubuntu 20.04 | ✅ Supported | [Docker](../docker/README.md) |
| Linux | Debian 12 | ✅ Supported | [Docker](../docker/README.md) |
| Linux | Minimal (deps test) | ✅ Test only | [Docker](../docker/README.md) |
| Windows | WSL2 Ubuntu | ✅ Supported | [WSL Guide](wsl-setup.md) |
| Windows | WSL2 Debian | ✅ Supported | [WSL Guide](wsl-setup.md) |
| Windows | Git Bash | ⚠️ Limited | [Git Bash Guide](gitbash-setup.md) |
| macOS | macOS 13+ | ✅ Supported | Manual testing |

## Core Test Scenarios

### Scenario 1: Fresh Installation

**Objective:** Verify clean installation on a fresh system

**Prerequisites:**

- No existing `~/.aida` directory
- No existing `~/.claude` directory
- No existing `~/CLAUDE.md` file

**Steps:**

1. Run installation script:

   ```bash
   ./install.sh
   ```

2. Provide inputs:
   - Assistant name: `testassistant`
   - Personality: `1` (jarvis)

3. Verify output shows:
   - Dependency validation success
   - Directory creation messages
   - Permission setting messages
   - Installation complete message

4. Verify filesystem:

   ```bash
   # Check directories exist
   test -d ~/.aida && echo "✓ ~/.aida exists"
   test -d ~/.claude && echo "✓ ~/.claude exists"
   test -d ~/.claude/config && echo "✓ config exists"
   test -d ~/.claude/knowledge && echo "✓ knowledge exists"
   test -d ~/.claude/memory && echo "✓ memory exists"
   test -d ~/.claude/agents && echo "✓ agents exists"

   # Check CLAUDE.md
   test -f ~/CLAUDE.md && echo "✓ CLAUDE.md exists"

   # Check permissions
   stat -c '%a' ~/.aida | grep -q 755 && echo "✓ .aida permissions correct"
   stat -c '%a' ~/.claude | grep -q 755 && echo "✓ .claude permissions correct"
   ```

**Expected Results:**

- ✅ All directories created
- ✅ Permissions set to 755 (directories) and 644 (files)
- ✅ CLAUDE.md contains personalized content
- ✅ No errors in output

---

### Scenario 2: Development Mode Installation

**Objective:** Verify dev mode creates symlink for framework

**Prerequisites:**

- Repository checked out
- No existing installation

**Steps:**

1. Run installation in dev mode:

   ```bash
   ./install.sh --dev
   ```

2. Provide inputs:
   - Assistant name: `devtest`
   - Personality: `2` (alfred)

3. Verify symlink:

   ```bash
   # Check .aida is symlink
   test -L ~/.aida && echo "✓ .aida is symlink"

   # Verify symlink target
   readlink ~/.aida
   # Should point to repository directory

   # Check .claude is NOT a symlink
   test ! -L ~/.claude && echo "✓ .claude is not symlink"
   ```

4. Verify dev mode warning in output

**Expected Results:**

- ✅ `~/.aida` is symlink to repository
- ✅ `~/.claude` is regular directory (copied)
- ✅ Dev mode warning displayed
- ✅ Changes to repository reflected in `~/.aida`

---

### Scenario 3: Re-installation with Backup

**Objective:** Verify backup creation when re-installing

**Prerequisites:**

- Existing installation from Scenario 1

**Steps:**

1. Note current timestamp:

   ```bash
   date +%Y%m%d_%H%M%S
   ```

2. Run installation again:

   ```bash
   ./install.sh
   ```

3. Verify backup messages in output

4. Check for backups:

   ```bash
   ls -la ~/ | grep backup

   # Should show:
   # .aida.backup.YYYYMMDD_HHMMSS/
   # .claude.backup.YYYYMMDD_HHMMSS/
   # CLAUDE.md.backup.YYYYMMDD_HHMMSS
   ```

5. Verify backup contents:

   ```bash
   # Check backup contains old data
   ls -la ~/.aida.backup.*/
   ```

**Expected Results:**

- ✅ Backups created with timestamp
- ✅ Backup contains previous installation
- ✅ New installation proceeds successfully
- ✅ No data loss

---

### Scenario 4: Dependency Validation

**Objective:** Verify dependency checking works correctly

#### Test 4A: Missing Dependencies

Use minimal Docker environment:

```bash
docker-compose run ubuntu-minimal
./install.sh
```

**Expected Results:**

- ❌ Installation fails
- ✅ Clear error message about missing dependencies
- ✅ Lists: `git`, `rsync`

#### Test 4B: Old Bash Version

Modify Docker image to use Bash 3.x:

```dockerfile
RUN apt-get install -y bash=3.x
```

**Expected Results:**

- ❌ Installation fails
- ✅ Error message about Bash version requirement

#### Test 4C: No Write Permission

```bash
# Remove write permission from home
chmod 555 ~

# Try installation
./install.sh
```

**Expected Results:**

- ❌ Installation fails
- ✅ Error message about write permissions

---

### Scenario 5: Input Validation

**Objective:** Verify all input validation rules

#### Test 5A: Assistant Name - Too Short

```bash
./install.sh
# Enter: "ab"
```

**Expected Result:**

- ❌ Rejected with message: "Name must be 3-20 characters"

#### Test 5B: Assistant Name - Too Long

```bash
./install.sh
# Enter: "verylongassistantnamethatexceedslimit"
```

**Expected Result:**

- ❌ Rejected with message: "Name must be 3-20 characters"

#### Test 5C: Assistant Name - Contains Spaces

```bash
./install.sh
# Enter: "my assistant"
```

**Expected Result:**

- ❌ Rejected with message: "Name cannot contain spaces"

#### Test 5D: Assistant Name - Contains Uppercase

```bash
./install.sh
# Enter: "MyAssistant"
```

**Expected Result:**

- ❌ Rejected with message: "Name must be lowercase"

#### Test 5E: Assistant Name - Invalid Characters

```bash
./install.sh
# Enter: "assistant@123" or "assistant_name"
```

**Expected Result:**

- ❌ Rejected with message about allowed characters

#### Test 5F: Assistant Name - Valid

```bash
./install.sh
# Enter: "jarvis" or "assistant-one" or "test123"
```

**Expected Result:**

- ✅ Accepted and proceeds to personality selection

#### Test 5G: Personality - Invalid Choice

```bash
./install.sh
# Enter valid name
# Enter: "6" or "abc" or "0"
```

**Expected Result:**

- ❌ Rejected with message: "Invalid choice. Please enter a number between 1 and 5"

#### Test 5H: Personality - Valid Choice

```bash
./install.sh
# Enter valid name
# Enter: "1" through "5"
```

**Expected Result:**

- ✅ Accepted and proceeds with installation

---

### Scenario 6: Help and Documentation

**Objective:** Verify help flag works correctly

#### Test 6A: Help Flag

```bash
./install.sh --help
```

**Expected Results:**

- ✅ Displays usage information
- ✅ Shows options (--dev, --help)
- ✅ Shows description
- ✅ Shows examples
- ✅ Exits without prompting
- ✅ Exit code 0

#### Test 6B: Unknown Option

```bash
./install.sh --unknown
```

**Expected Results:**

- ✅ Error message about unknown option
- ✅ Displays usage help
- ✅ Exit code 1

---

### Scenario 7: Idempotency

**Objective:** Verify script can be run multiple times safely

**Steps:**

1. First installation:

   ```bash
   ./install.sh
   # Name: test1, Personality: 1
   ```

2. Second installation (same inputs):

   ```bash
   ./install.sh
   # Name: test1, Personality: 1
   ```

3. Third installation (different inputs):

   ```bash
   ./install.sh
   # Name: test2, Personality: 2
   ```

**Expected Results:**

- ✅ Each run creates backups of previous installation
- ✅ Each run completes successfully
- ✅ Final state reflects last installation inputs
- ✅ All backups preserved

---

### Scenario 8: File and Directory Permissions

**Objective:** Verify correct permissions are set

**Steps:**

1. Install framework:

   ```bash
   ./install.sh
   ```

2. Check directory permissions:

   ```bash
   find ~/.aida -type d -exec stat -c '%a %n' {} \;
   find ~/.claude -type d -exec stat -c '%a %n' {} \;
   ```

3. Check file permissions:

   ```bash
   find ~/.aida -type f -exec stat -c '%a %n' {} \;
   find ~/.claude -type f -exec stat -c '%a %n' {} \;
   stat -c '%a' ~/CLAUDE.md
   ```

**Expected Results:**

- ✅ All directories: `755`
- ✅ All files: `644`
- ✅ `install.sh`: `755` (executable)

---

### Scenario 9: Generated Content Validation

**Objective:** Verify generated CLAUDE.md is correct

**Steps:**

1. Install with specific inputs:

   ```bash
   ./install.sh
   # Name: myassistant
   # Personality: jarvis (1)
   ```

2. Verify CLAUDE.md content:

   ```bash
   cat ~/CLAUDE.md
   ```

**Expected Content:**

- ✅ Contains assistant name: "myassistant"
- ✅ Contains personality: "jarvis"
- ✅ Contains current date
- ✅ Contains configuration paths
- ✅ Contains usage examples
- ✅ Valid YAML frontmatter

---

### Scenario 10: Platform-Specific Tests

#### Test 10A: macOS

```bash
# Test on macOS
./install.sh

# Verify BSD vs GNU command differences handled
# Check if script works with macOS versions of: chmod, find, stat
```

#### Test 10B: WSL

```bash
# Test on WSL2
wsl -d Ubuntu-22.04
./install.sh

# Verify Windows path integration
ls -la /mnt/c/Users/$USER/

# Verify symlinks work in WSL
./install.sh --dev
readlink ~/.aida
```

#### Test 10C: Git Bash

```bash
# Test on Git Bash
./install.sh

# Check rsync availability
command -v rsync || echo "rsync not available"

# Check symlink support (may require admin)
./install.sh --dev
ls -la ~/.aida
```

---

## Automated Test Execution

### Docker Automated Tests

```bash
# Run all Docker tests
./.github/testing/test-install.sh

# Run specific environment
./.github/testing/test-install.sh --env ubuntu-22

# Verbose output
./.github/testing/test-install.sh --verbose
```

### Manual Test Checklist

When testing manually, use this checklist:

#### Pre-Installation

- [ ] Repository cloned
- [ ] Dependencies installed
- [ ] `install.sh` is executable
- [ ] No existing installation (or testing re-install)

#### Installation Testing

- [ ] Help flag works (`--help`)
- [ ] Dependency validation works
- [ ] Input validation works (name, personality)
- [ ] Normal installation succeeds
- [ ] Dev mode installation succeeds
- [ ] Re-installation creates backups
- [ ] Permissions are correct (755/644)

#### Post-Installation

- [ ] All directories created
- [ ] CLAUDE.md generated correctly
- [ ] File contents are correct
- [ ] Symlinks work (dev mode)
- [ ] No errors in logs

#### Platform-Specific

- [ ] Test on primary platform (macOS/Linux/Windows)
- [ ] Test on secondary platforms
- [ ] Document platform-specific issues

---

## Test Results Template

Use this template to document test results:

```markdown
## Test Run: [Date]

**Environment:** [Ubuntu 22.04 / WSL / macOS / etc.]
**Tester:** [Name]

### Test Results

| Scenario | Result | Notes |
|----------|--------|-------|
| Fresh Installation | ✅/❌ | |
| Dev Mode | ✅/❌ | |
| Re-installation | ✅/❌ | |
| Dependency Validation | ✅/❌ | |
| Input Validation | ✅/❌ | |
| Help Flag | ✅/❌ | |
| Permissions | ✅/❌ | |
| Generated Content | ✅/❌ | |

### Issues Found

1. [Issue description]
   - Severity: [Low/Medium/High]
   - Platform: [Specific platform or All]
   - Steps to reproduce: [...]

### Recommendations

- [Any recommendations for improvements]
```

---

## Continuous Integration

### GitHub Actions (Future)

```yaml
# .github/workflows/test-install.yml
name: Installation Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-22.04, ubuntu-20.04, macos-latest]

    steps:
      - uses: actions/checkout@v3
      - name: Run installation tests
        run: ./.github/testing/test-install.sh
```

---

## Related Documentation

- [Docker Testing](../docker/README.md)
- [WSL Testing](wsl-setup.md)
- [Git Bash Testing](gitbash-setup.md)
- [Installation Script](../../install.sh)
