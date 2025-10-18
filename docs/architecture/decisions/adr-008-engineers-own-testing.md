# ADR-008: Engineers Own Testing Philosophy

**Status**: Accepted
**Date**: 2025-10-16
**Deciders**: Project Lead
**Context**: Software
**Tags**: architecture, agents, testing, quality, ownership

## Context and Problem Statement

Testing is a critical part of software development. Traditionally, some organizations separate testing into a dedicated QA role where QA engineers write automated tests for code written by software engineers. This creates handoffs, delays, and split ownership.

Modern software practices emphasize that engineers should own all aspects of their code, including tests. Testing is just another form of code, requiring the same skills as feature implementation.

We need to decide:
- Who writes automated tests (unit, integration, E2E, performance)?
- What role does QA play in modern development?
- Should we have a dedicated test-automation-engineer agent?
- How do quality concerns integrate into engineering?

Without clarity, we risk:
- Creating handoff delays between feature code and test code
- Engineers not owning quality of their work
- QA becoming a bottleneck instead of a quality multiplier
- Confusion about which agent writes which tests

## Decision Drivers

- **Ownership**: Engineers should own all aspects of their code
- **Speed**: No handoff delays between feature and test implementation
- **Modern Practices**: Shift-left testing, test-driven development, DevOps culture
- **Quality Integration**: Quality built in, not bolted on
- **Skills**: Testing is code, uses same skills as feature code
- **Responsibility**: Who writes code should ensure it works

## Considered Options

### Option A: Dedicated Test-Automation Engineer Writes All Tests

**Description**: Separate agent writes all automated tests:

```text
Engineers write feature code
    ↓
test-automation-engineer writes tests for that code
```

**Pros**:
- Dedicated testing expertise
- Engineers focus on features only
- Tests written by testing specialist

**Cons**:
- Handoff delay (feature ready, waiting for tests)
- Split ownership (engineer doesn't own quality)
- Testing is still code (same skills needed)
- Creates bottleneck (one test engineer, many feature engineers)
- Tests written by someone who didn't write the code
- Waterfall-style handoff (anti-pattern in modern development)
- Engineers learn to rely on others for quality

**Cost**: Handoff delays, split ownership, bottleneck

### Option B: Mixed Ownership (Engineers Write Unit, QA Writes Integration/E2E)

**Description**: Split testing by type:

```text
Engineers write unit tests
qa-engineer writes integration/E2E tests
```

**Pros**:
- Engineers write some tests
- QA adds higher-level tests

**Cons**:
- Still split ownership
- Arbitrary boundary (why is unit different from integration?)
- Integration/E2E tests often need code context
- Creates handoff for some tests
- Confusion about boundary (is API test integration or unit?)
- Engineers still don't own full quality

**Cost**: Partial handoff, unclear boundaries

### Option C: Engineers Own All Testing (Quality-Analyst Defines Requirements)

**Description**: Engineers write ALL tests, quality-analyst defines WHAT to test:

```text
quality-analyst identifies test scenarios, edge cases, coverage requirements
    ↓
Engineers implement ALL tests (unit, integration, E2E, performance)
    + Engineers use testing skills for framework-specific patterns
```

**Pros**:
- Engineers own all code (features + tests)
- No handoff delays
- Quality integrated into engineering
- Testing uses same skills as feature code
- quality-analyst provides valuable expertise (identifying edge cases)
- Faster feedback loop
- Clear separation: quality-analyst defines WHAT, engineers implement HOW

**Cons**:
- Engineers must learn testing practices
  - **Mitigation**: Testing skills provide patterns, quality-analyst provides guidance
- No dedicated test-automation expertise
  - **Mitigation**: quality-analyst provides strategic expertise, testing skills provide tactical patterns

**Cost**: Engineers learn testing, high quality ownership

### Option D: Separate Testing Team (Waterfall-Style)

**Description**: Entirely separate QA team writes all tests after features complete:

**Pros**:
- None in modern context

**Cons**:
- Waterfall anti-pattern
- Massive handoff delays
- No modern organization uses this
- Engineers don't own quality

**Cost**: Rejected, outdated model

## Decision Outcome

**Chosen option**: Option C - Engineers Own All Testing (Quality-Analyst Defines Requirements)

**Rationale**:

1. **Testing Is Code**: Writing tests requires the same skills as writing feature code (programming, logic, problem-solving). Engineers already have these skills.

2. **Ownership**: Engineers who write feature code are best positioned to test it because they understand:
   - Implementation details
   - Edge cases and boundary conditions
   - Dependencies and integration points
   - Performance characteristics

3. **Speed**: No handoff delays. Feature and tests written together, often test-first (TDD).

4. **Modern Practices**:
   - **Shift-left testing**: Test early, in development, not after
   - **Test-driven development (TDD)**: Write tests first
   - **DevOps culture**: You build it, you test it, you run it

5. **Quality-Analyst Value**: quality-analyst provides expertise in:
   - Identifying test scenarios engineers might miss
   - Edge cases and failure modes
   - Coverage analysis and gaps
   - Testing strategy and approach
   - Quality metrics and goals

   This is valuable analytical work, distinct from test implementation.

6. **Clear Separation**:
   - **quality-analyst** (requirements): "Here are 20 test scenarios, including edge cases for concurrent users, timeout handling, and malformed input"
   - **engineer** (implementation): "I'll write tests covering those scenarios using pytest and Playwright"

7. **Performance Testing**: Same pattern applies:
   - **performance-analyst**: "Must handle 1000 concurrent users with <2s response time"
   - **engineer**: "I'll implement load tests using k6 to verify those targets"

### Consequences

**Positive**:
- Engineers own complete quality of their code
- No handoff delays between feature and test implementation
- Faster feedback loops (test while developing)
- Quality integrated from the start
- quality-analyst can focus on strategic quality (scenarios, coverage, risk) rather than tactical implementation
- Supports test-driven development (write test first)
- Engineers learn quality practices (makes them better engineers)
- Testing skills provide framework-specific patterns
- Clear separation: quality-analyst analyzes WHAT to test, engineers implement HOW to test

**Negative**:
- Engineers must invest time learning testing practices
  - **Mitigation**: Testing skills provide patterns (pytest-patterns, playwright-automation, k6-performance)
  - **Mitigation**: quality-analyst provides guidance and best practices
  - **Mitigation**: Engineers already know how to code, testing is just code
- No dedicated test-automation specialist
  - **Mitigation**: quality-analyst provides strategic testing expertise
  - **Mitigation**: Testing skills encapsulate tactical patterns
  - **Mitigation**: Tech-lead enforces testing standards

**Neutral**:
- Different from traditional "QA writes tests" model
- Requires cultural shift if coming from traditional QA model
- Quality-analyst role is advisory/analytical, not implementation

## Validation

- [x] Aligned with modern DevOps practices (you build it, you test it)
- [x] Aligned with shift-left testing (test early, in development)
- [x] Supports test-driven development (TDD)
- [x] Engineers own complete quality
- [x] No handoff delays
- [x] Clear separation of requirements (quality-analyst) vs implementation (engineers)
- [x] Reviewed and approved by project lead

## Implementation Notes

### quality-analyst Agent

**Purpose**: Define quality requirements, identify test scenarios, analyze coverage gaps

**Responsibilities**:
- Identify test scenarios (happy path, edge cases, error cases)
- Analyze code coverage and identify gaps
- Define quality gates (coverage thresholds, complexity limits)
- Suggest testing strategies (unit, integration, E2E mix)
- Identify edge cases engineers might miss
- Risk analysis (which areas need more testing)
- Review test implementation for completeness

**Does NOT**:

- Write test code
- Implement test automation
- Configure test frameworks

**Output**:
- Test scenario lists
- Coverage gap analysis
- Quality recommendations
- Risk assessments

**Example**:

```text
User: "Review testing for password reset feature"

quality-analyst output:
"Test scenarios to cover:
1. Happy path: valid email, token flow works
2. Invalid email: non-existent user
3. Expired token: token older than 15 minutes
4. Malformed token: invalid format, SQL injection attempts
5. Concurrent requests: same user requests reset twice
6. Rate limiting: too many reset attempts
7. Missing email field: validation error
8. Database down: graceful failure
9. Email service down: queuing and retry
10. Token already used: prevent reuse

Coverage gaps:
- No tests for concurrent token usage
- Missing error handling tests for email service failure
- Performance test for concurrent reset requests needed

Recommended: Add integration tests for scenarios 8-9,
performance test for scenario 10"
```

### performance-analyst Agent

**Purpose**: Define performance requirements, SLAs, and load expectations

**Responsibilities**:
- Define performance targets (response time, throughput)
- Set SLAs and error budgets
- Identify performance risks
- Recommend performance testing strategy
- Analyze performance test results

**Does NOT**:

- Write performance test code
- Implement load tests
- Configure performance tools

**Output**:
- Performance requirements
- SLA definitions
- Load testing scenarios
- Performance risk assessment

**Example**:

```text
User: "What are performance requirements for API?"

performance-analyst output:
"Performance requirements:
- Response time: p95 < 200ms, p99 < 500ms
- Throughput: 1000 requests/second sustained
- Error rate: < 0.1% under normal load
- Availability: 99.9% uptime (8.76 hours downtime/year)

Load testing scenarios:
1. Baseline: 100 concurrent users, 5-minute duration
2. Load test: 1000 concurrent users, 15-minute duration
3. Stress test: Gradually increase to failure point
4. Spike test: Sudden 10x traffic increase
5. Soak test: 500 users for 4 hours (memory leaks)

Recommended tools: k6 for API load testing

SLA: 99.9% availability, p95 < 200ms response time"
```

### Engineering Agents (Implementation)

**Responsibilities**: ALL engineers write ALL tests for their code

**product-engineer, platform-engineer, api-engineer, data-engineer**:

- Write unit tests
- Write integration tests
- Write E2E tests
- Write performance tests
- Implement test scenarios from quality-analyst
- Meet performance targets from performance-analyst
- Use testing skills for framework-specific patterns

**Testing Skills Used**:

- `pytest-patterns` - Python unit testing
- `jest-testing` - JavaScript unit testing
- `playwright-automation` - E2E testing
- `api-testing` - API integration testing
- `k6-performance` - Load and performance testing
- `dbt-testing` - dbt data quality tests

**Example**:

```text
User: "Implement password reset feature"

Workflow:
1. quality-analyst → "Here are 10 test scenarios to cover..."
2. performance-analyst → "Must handle 100 resets/second with p95 < 2s"
3. product-engineer implements:
   - Password reset feature code
   - Unit tests covering 10 scenarios (using pytest-patterns skill)
   - Integration tests for email/database (using api-testing skill)
   - Load test for 100 resets/second (using k6-performance skill)
   - Monitoring to track p95 latency
```

### Test Infrastructure

**Who**: platform-engineer (if test infrastructure is shared across teams)

**What**:

- Set up test frameworks (pytest, jest, Playwright)
- Configure CI/CD test execution
- Create test databases and environments
- Build test data factories
- Set up coverage reporting

**Why Platform Engineer**: Test infrastructure is a platform capability (used by all engineers)

### Testing Workflow

```text
1. Requirements Phase:
   product-manager → "Users need password reset"
   quality-analyst → "Test these 10 scenarios..."
   performance-analyst → "Must handle 100 resets/second"

2. Implementation Phase:
   product-engineer:
   - Write feature code
   - Write unit tests (10 scenarios)
   - Write integration tests
   - Write load tests
   - Add monitoring

3. Review Phase:
   quality-analyst → "Coverage looks good, but you missed the concurrent reset scenario"
   product-engineer → "Adding test for concurrent resets now"

   performance-analyst → "Load test shows p95 at 3s, target is 2s"
   product-engineer → "Optimizing database query, adding caching"
```

### No test-automation-engineer

We explicitly do NOT create a test-automation-engineer agent because:

- Testing is implementation (engineers own implementation per ADR-006)
- Testing uses same skills as feature code
- Creates handoff delays if separate
- Engineers closest to code best positioned to test it
- quality-analyst provides strategic testing guidance
- Testing skills provide tactical testing patterns

## References

- Modern DevOps culture: "You build it, you test it, you run it"
- Shift-left testing: Test early in development, not after
- Test-driven development (TDD): Write tests first
- Google Testing Blog: Engineers own testing
- Accelerate (book): High-performing teams integrate testing into development
- ADR-006: Analyst/Engineer Pattern (engineers implement, analysts define requirements)
- ADR-007: Product/Platform/API Engineering (defines engineer types who own testing)

## Related ADRs

- ADR-006: Analyst/Engineer Agent Pattern (provides context for engineer ownership)
- ADR-007: Product/Platform/API Engineering Model (defines engineer agents who write tests)

## Updates

None yet
