---
agent: qa-engineer
updated: "2025-10-04"
knowledge_count: 0
memory_type: "agent-specific"
---

# Knowledge Index for QA Engineer

This index catalogs all knowledge resources available to the qa-engineer agent. These act as persistent memories that the agent can reference during execution for AIDA testing, cross-platform validation, installation testing, and quality assurance.

## Local Knowledge Files

### Core Concepts
<!-- Add core concept files here as they are created -->

### Patterns
<!-- Add pattern files here as they are created -->

### Decisions
<!-- Add decision files here as they are created -->

## External Documentation Links

### Shell Script Testing

- [BATS](https://github.com/bats-core/bats-core) - Bash Automated Testing System
- [shUnit2](https://github.com/kward/shunit2) - Unit testing framework for shell scripts
- [ShellSpec](https://github.com/shellspec/shellspec) - BDD-style shell script testing
- [Shell Script Testing Guide](https://www.shellcheck.net/wiki/Testing) - Testing best practices

### Cross-Platform Testing

- [Testing on Multiple OS](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions#jobsjob_idruns-on) - GitHub Actions matrix testing
- [Docker for Testing](https://docs.docker.com/get-started/) - Containerized test environments
- [Vagrant for Testing](https://www.vagrantup.com/docs) - VM-based testing
- [macOS Testing Considerations](https://developer.apple.com/forums/tags/testing) - Platform-specific testing

### Installation Testing

- [Test Harness Patterns](https://en.wikipedia.org/wiki/Test_harness) - Installation test frameworks
- [Destructive Testing](https://softwaretestingfundamentals.com/destructive-testing/) - Breaking installation scenarios
- [Idempotency Testing](https://stackoverflow.com/questions/1077412/what-is-an-idempotent-operation) - Re-run safety validation
- [Rollback Testing](https://www.guru99.com/rollback-testing.html) - Uninstall and cleanup validation

### Test Automation

- [GitHub Actions](https://docs.github.com/en/actions) - CI/CD automation platform
- [pre-commit Framework](https://pre-commit.com/) - Git hook management for testing
- [Act](https://github.com/nektos/act) - Run GitHub Actions locally
- [Test Automation Patterns](https://martinfowler.com/articles/practical-test-pyramid.html) - Testing strategies

### Quality Metrics

- [Code Coverage](https://github.com/SimonKagstrom/kcov) - Shell script coverage tool
- [Static Analysis](https://www.shellcheck.net/) - ShellCheck for quality
- [Complexity Metrics](https://github.com/terryyin/lizard) - Code complexity analysis
- [Quality Gates](https://docs.sonarqube.org/latest/user-guide/quality-gates/) - Quality threshold patterns

### Error Scenario Testing

- [Chaos Engineering](https://principlesofchaos.org/) - Failure testing principles
- [Error Injection](https://github.com/Netflix/chaosmonkey) - Failure simulation patterns
- [Negative Testing](https://www.guru99.com/negative-testing.html) - Invalid input testing
- [Edge Case Testing](https://www.softwaretestinghelp.com/what-is-boundary-value-analysis-and-equivalence-partitioning/) - Boundary condition testing

### Documentation Testing

- [README Testing](https://github.com/testthedocs/rakpart) - Documentation validation
- [Link Checking](https://github.com/tcort/markdown-link-check) - Broken link detection
- [Documentation Linting](https://github.com/DavidAnson/markdownlint) - Markdown quality
- [Example Code Testing](https://doc.rust-lang.org/rustdoc/documentation-tests.html) - Validating code examples

### Performance Testing

- [Shell Script Profiling](https://www.shellcheck.net/wiki/SC2034) - Performance analysis
- [Benchmark Testing](https://github.com/sharkdp/hyperfine) - Command-line benchmarking
- [Resource Monitoring](https://github.com/nicolargo/glances) - System resource tracking
- [Load Testing](https://github.com/tsenart/vegeta) - Stress testing patterns

### Security Testing

- [Security Scanning](https://github.com/koalaman/shellcheck/wiki/SC2086) - Shell security checks
- [Vulnerability Testing](https://owasp.org/www-project-top-ten/) - Security test patterns
- [Privilege Testing](https://www.cyberciti.biz/tips/linux-security.html) - Permission validation
- [Input Validation Testing](https://owasp.org/www-project-web-security-testing-guide/) - Security input testing

## Usage Notes

### When to Add Knowledge

- New test pattern discovered → Add to patterns section
- Important QA decision made → Record in decisions history
- Useful testing tool found → Add to external links
- Test automation created → Document in patterns
- Quality issue resolved → Add to core concepts

### Knowledge Maintenance

- Update this index.md when adding/removing files
- Increment knowledge_count in frontmatter
- Update the `updated` date
- Keep knowledge focused on QA and testing topics
- Link to official documentation rather than duplicating it

### Memory Philosophy

- **CLAUDE.md**: Quick reference for when to use qa-engineer agent (always in context)
- **Knowledge Base**: Detailed test patterns, validation strategies, decision history (loaded when agent invokes)
- Both systems work together for efficient context management

## Knowledge Priorities

### High Priority Knowledge

1. Shell script testing frameworks (BATS, shUnit2)
2. Cross-platform installation validation (macOS/Linux)
3. Idempotency and rollback testing patterns
4. Error scenario and edge case testing
5. Quality metrics and coverage analysis

### Medium Priority Knowledge

1. CI/CD automation with GitHub Actions
2. Performance and benchmark testing
3. Security testing and validation
4. Documentation testing and validation

### Low Priority Knowledge

1. Platform-specific testing details (document as needed)
2. Advanced testing frameworks (focus on shell-specific tools)
3. Generic QA concepts (focus on AIDA-specific testing needs)
