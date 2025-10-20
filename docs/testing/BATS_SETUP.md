---
title: "Bats Testing Framework Setup"
description: "Installation and configuration guide for Bats (Bash Automated Testing System)"
category: "testing"
tags: ["bats", "testing", "setup", "installation"]
last_updated: "2025-10-18"
status: "published"
audience: "developers"
---

# Bats Testing Framework Setup

This guide covers installing and configuring **Bats** (Bash Automated Testing System) for testing AIDA installer modules.

## What is Bats?

**Bats** is a TAP-compliant testing framework for Bash scripts that provides:

- **Structured test cases** with `@test` blocks
- **Setup/teardown hooks** for test isolation
- **Assertion helpers** for common checks
- **CI/CD integration** for automated testing
- **Human-readable output** for debugging

Official repository: <https://github.com/bats-core/bats-core>

## Installation

### macOS

#### Recommended method: Homebrew

```bash
brew install bats-core
```

#### Verify installation

```bash
bats --version
# Output: Bats 1.x.x
```

### Ubuntu/Debian Linux

#### Option 1: APT package manager

```bash
sudo apt-get update
sudo apt-get install bats
```

#### Option 2: NPM (if Node.js installed)

```bash
npm install -g bats
```

#### Option 3: From source (recommended for latest version)

```bash
git clone https://github.com/bats-core/bats-core.git
cd bats-core
sudo ./install.sh /usr/local
```

#### Verify installation

```bash
bats --version
# Output: Bats 1.x.x
```

### Red Hat/Fedora Linux

#### Option 1: DNF package manager

```bash
sudo dnf install bats
```

#### Option 2: From source

```bash
git clone https://github.com/bats-core/bats-core.git
cd bats-core
sudo ./install.sh /usr/local
```

#### Verify installation

```bash
bats --version
# Output: Bats 1.x.x
```

### From Source (All Platforms)

For the latest version or if package managers don't have bats:

```bash
# Clone repository
git clone https://github.com/bats-core/bats-core.git
cd bats-core

# Install to /usr/local (requires sudo)
sudo ./install.sh /usr/local

# OR install to user directory (no sudo required)
./install.sh ~/.local
export PATH="$HOME/.local/bin:$PATH"  # Add to ~/.bashrc or ~/.zshrc
```

## Verifying Installation

After installation, verify bats is working:

```bash
# Check version
bats --version

# Run a simple test
echo '@test "addition" { [ $((1 + 1)) -eq 2 ] }' > test.bats
bats test.bats
rm test.bats
```

Expected output:

```text
✓ addition

1 test, 0 failures
```

## Optional: Install Bats Helper Libraries

Bats has helpful extension libraries for common assertions:

### bats-support

Provides better output formatting and test helpers:

```bash
# macOS
brew install bats-support

# Linux (manual installation)
git clone https://github.com/bats-core/bats-support.git ~/.bats/bats-support
```

### bats-assert

Provides assertion functions like `assert_equal`, `assert_success`, etc:

```bash
# macOS
brew install bats-assert

# Linux (manual installation)
git clone https://github.com/bats-core/bats-assert.git ~/.bats/bats-assert
```

### bats-file

Provides file system assertion helpers:

```bash
# macOS
brew install bats-file

# Linux (manual installation)
git clone https://github.com/bats-core/bats-file.git ~/.bats/bats-file
```

**Note**: These libraries are **optional** for AIDA testing. Our test helpers provide similar functionality.

## Running AIDA Tests

Once bats is installed, you can run AIDA tests:

```bash
# Run all unit tests
make test-unit

# Run all integration tests
make test-integration

# Run all tests
make test-all

# Run specific test file
bats tests/unit/test_prompts.bats

# Run with verbose output
bats --verbose tests/unit/test_prompts.bats

# Run with TAP output (for CI/CD)
bats --tap tests/unit/*.bats
```

## Troubleshooting

### bats: command not found

**Cause**: Bats not in PATH

**Solutions:**

1. **Homebrew (macOS)**: Ensure Homebrew bin directory is in PATH:

   ```bash
   echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bashrc
   source ~/.bashrc
   ```

2. **APT (Linux)**: Ensure /usr/bin is in PATH:

   ```bash
   echo $PATH | grep /usr/bin
   # If not found, add to ~/.bashrc
   ```

3. **Manual install**: Add installation directory to PATH:

   ```bash
   echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
   source ~/.bashrc
   ```

### Tests fail with "No such file or directory"

**Cause**: Module paths not resolving correctly

**Solution**: Run tests from project root:

```bash
cd /path/to/claude-personal-assistant
make test-unit
```

### Tests hang on interactive prompts

**Cause**: Test not providing input to prompt functions

**Solution**: Use heredoc or pipe to provide input:

```bash
# Good: Provides input
run prompt_yes_no "Continue?" <<< "y"

# Bad: Hangs waiting for input
run prompt_yes_no "Continue?"
```

### Permission denied errors

**Cause**: Test trying to write to protected directory

**Solution**: Use temporary test directory in `setup()`:

```bash
setup() {
  TEST_DIR="$(mktemp -d)"
  cd "$TEST_DIR"
}

teardown() {
  rm -rf "$TEST_DIR"
}
```

## CI/CD Integration

Bats integrates seamlessly with GitHub Actions:

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install Bats
        run: |
          sudo apt-get update
          sudo apt-get install -y bats
      - name: Run unit tests
        run: make test-unit
      - name: Run integration tests
        run: make test-integration
```

## Next Steps

- Read [UNIT_TESTING.md](./UNIT_TESTING.md) for writing tests
- See [tests/README.md](../../tests/README.md) for test organization
- Review existing tests in `tests/unit/` for examples

## Resources

- **Bats Documentation**: <https://bats-core.readthedocs.io/>
- **Bats GitHub**: <https://github.com/bats-core/bats-core>
- **Bats Tutorial**: <https://opensource.com/article/19/2/testing-bash-bats>
- **TAP Protocol**: <https://testanything.org/>

## Version Requirements

- **Minimum**: Bats 1.2.0 (for modern features)
- **Recommended**: Bats 1.10.0+ (latest stable)
- **Bash**: 3.2+ (macOS compatibility)
