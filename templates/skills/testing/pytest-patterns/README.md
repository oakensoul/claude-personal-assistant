---
title: "pytest Patterns"
description: "pytest testing framework patterns, configuration, and best practices for Python projects"
category: "testing"
used_by: ["quality-analyst", "product-engineer", "platform-engineer", "data-engineer"]
tags: ["python", "testing", "pytest", "unit-testing"]
last_updated: "2025-10-16"
---

# pytest Patterns

## Overview

This skill provides pytest testing patterns, configuration, and best practices for Python projects. pytest is the most popular Python testing framework, known for its simple syntax, powerful fixtures, and excellent plugin ecosystem.

Use this skill when:
- Setting up pytest in a new Python project
- Writing unit tests for Python code
- Creating reusable test fixtures
- Mocking external dependencies
- Configuring test coverage reporting

## When to Use

- **New Python project**: Setting up testing infrastructure
- **Writing unit tests**: Testing functions, classes, and modules
- **Integration testing**: Testing API endpoints, database interactions
- **Test organization**: Structuring test files and directories
- **CI/CD integration**: Running tests in GitHub Actions, GitLab CI, etc.
- **Coverage analysis**: Measuring and improving test coverage

## Used By

- **quality-analyst**: Recommends test structure, identifies test scenarios, analyzes coverage gaps
- **product-engineer**: Implements tests for product features, APIs, business logic
- **platform-engineer**: Tests platform services, libraries, shared components
- **data-engineer**: Tests data transformations, pipeline logic, data quality

## Contents

- [setup.md](setup.md) - pytest installation, configuration, and project structure
- [fixtures.md](fixtures.md) - Fixture patterns, scopes, and best practices
- [mocking.md](mocking.md) - Mocking with pytest-mock, monkeypatch, and unittest.mock
- [parametrize.md](parametrize.md) - Parametrized tests for testing multiple scenarios
- [coverage.md](coverage.md) - Coverage configuration, analysis, and reporting
- [ci-integration.md](ci-integration.md) - Running tests in CI/CD pipelines

## Related Skills

- [playwright-automation](../../testing/playwright-automation/) - E2E browser testing
- [api-testing](../../api/api-testing/) - API integration testing patterns
- [k6-performance](../../testing/k6-performance/) - Load and performance testing

## Examples

### Basic Test Structure

```python
# tests/test_calculator.py
import pytest
from calculator import Calculator

def test_add():
    calc = Calculator()
    result = calc.add(2, 3)
    assert result == 5

def test_divide_by_zero():
    calc = Calculator()
    with pytest.raises(ZeroDivisionError):
        calc.divide(10, 0)
```

### Using Fixtures

```python
# tests/conftest.py
import pytest
from database import Database

@pytest.fixture
def db():
    """Provide a test database instance."""
    database = Database(":memory:")
    database.setup()
    yield database
    database.teardown()

# tests/test_users.py
def test_create_user(db):
    user = db.create_user("alice@example.com")
    assert user.email == "alice@example.com"
```

### Parametrized Tests

```python
import pytest

@pytest.mark.parametrize("input,expected", [
    (2, 4),
    (3, 9),
    (4, 16),
    (5, 25),
])
def test_square(input, expected):
    assert input ** 2 == expected
```

### Mocking External Dependencies

```python
def test_api_call(mocker):
    # Mock external HTTP call
    mock_get = mocker.patch('requests.get')
    mock_get.return_value.json.return_value = {'status': 'success'}

    result = fetch_data()
    assert result['status'] == 'success'
```

## References

- [pytest Documentation](https://docs.pytest.org/)
- [pytest-mock Documentation](https://pytest-mock.readthedocs.io/)
- [pytest-cov Documentation](https://pytest-cov.readthedocs.io/)
- [Effective Python Testing With Pytest](https://realpython.com/pytest-python-testing/)
