---
name: pytest-patterns
version: 1.0.0
category: testing
description: pytest testing framework patterns, configuration, and best practices for Python projects
short_description: pytest patterns and best practices for Python testing
tags: [python, testing, pytest, unit-testing, tdd, fixtures]
used_by: [qa-engineer, code-reviewer, data-engineer]
last_updated: "2025-10-20"
---

# pytest Patterns Skill

This skill provides comprehensive knowledge about pytest testing framework patterns, configuration, and best practices for Python projects.

## Purpose

This skill enables agents to:

- **Setup** pytest in new and existing Python projects
- **Configure** pytest with optimal settings and plugins
- **Write** effective unit and integration tests
- **Structure** test files and directories properly
- **Create** reusable test fixtures
- **Mock** external dependencies correctly
- **Report** test coverage and results
- **Integrate** tests with CI/CD pipelines

## What is pytest?

**pytest** is the most popular Python testing framework, known for:

- Simple, pythonic test syntax
- Powerful fixture system for test setup/teardown
- Rich plugin ecosystem
- Detailed failure reporting
- Parallel test execution support
- Excellent integration with CI/CD

## When to Use This Skill

### New Project Setup

- Setting up pytest infrastructure
- Configuring pytest.ini or pyproject.toml
- Installing pytest plugins
- Organizing test directories

### Writing Tests

- Creating unit tests for functions and classes
- Writing integration tests for APIs
- Testing async code
- Parameterizing tests
- Using fixtures effectively

### Test Maintenance

- Organizing test files
- Creating shared fixtures
- Refactoring test code
- Optimizing test performance

### CI/CD Integration

- Running tests in GitHub Actions
- Generating coverage reports
- Parallel test execution
- Test result reporting

## Core Concepts

### Test Discovery

pytest automatically discovers tests using these patterns:

- **Test files**: `test_*.py` or `*_test.py`
- **Test functions**: `test_*()`
- **Test classes**: `Test*`
- **Test methods**: `test_*()` in `Test*` classes

### Fixtures

Fixtures provide reusable test setup and teardown:

```python
import pytest

@pytest.fixture
def database():
    """Provide a test database."""
    db = Database(":memory:")
    db.setup()
    yield db
    db.teardown()

def test_query(database):
    """Test database query."""
    result = database.query("SELECT 1")
    assert result == 1
```

### Markers

Markers categorize and filter tests:

```python
@pytest.mark.slow
def test_complex_operation():
    """Slow test marked for selective execution."""
    pass

@pytest.mark.integration
def test_api_endpoint():
    """Integration test marked separately from unit tests."""
    pass
```

### Parametrization

Run same test with multiple inputs:

```python
@pytest.mark.parametrize("input,expected", [
    (2, 4),
    (3, 9),
    (4, 16),
])
def test_square(input, expected):
    """Test square function with multiple inputs."""
    assert square(input) == expected
```

## Project Structure

### Recommended Layout

```text
project/
├── src/
│   └── mypackage/
│       ├── __init__.py
│       ├── module1.py
│       └── module2.py
├── tests/
│   ├── __init__.py
│   ├── conftest.py          # Shared fixtures
│   ├── test_module1.py
│   └── test_module2.py
├── pytest.ini               # pytest configuration
└── pyproject.toml           # Modern Python projects
```

### Configuration Files

**pytest.ini** (traditional):

```ini
[pytest]
minversion = 7.0
testpaths = tests
addopts = --strict-markers --verbose --cov=src
markers =
    slow: marks tests as slow
    integration: integration tests
    unit: unit tests
```

**pyproject.toml** (modern):

```toml
[tool.pytest.ini_options]
minversion = "7.0"
testpaths = ["tests"]
addopts = [
    "--strict-markers",
    "--verbose",
    "--cov=src",
]
markers = [
    "slow: marks tests as slow",
    "integration: integration tests",
]
```

## Common Plugins

### Essential Plugins

- **pytest-cov**: Coverage reporting
- **pytest-mock**: Simplified mocking
- **pytest-asyncio**: Async test support
- **pytest-xdist**: Parallel execution

### Installation

```bash
pip install pytest pytest-cov pytest-mock pytest-asyncio pytest-xdist
```

## Testing Patterns

### Unit Testing

```python
def test_function():
    """Test a simple function."""
    result = add(2, 3)
    assert result == 5

class TestCalculator:
    """Test suite for Calculator class."""

    def test_add(self):
        calc = Calculator()
        assert calc.add(2, 3) == 5
```

### Mocking

```python
def test_api_call(mocker):
    """Test function with mocked API call."""
    mock_response = mocker.Mock()
    mock_response.json.return_value = {"status": "ok"}

    mocker.patch("requests.get", return_value=mock_response)

    result = fetch_data()
    assert result["status"] == "ok"
```

### Async Testing

```python
@pytest.mark.asyncio
async def test_async_function():
    """Test async function."""
    result = await async_operation()
    assert result == "success"
```

### Fixtures with Scope

```python
@pytest.fixture(scope="session")
def database():
    """Database fixture for entire test session."""
    db = Database()
    yield db
    db.close()

@pytest.fixture(scope="module")
def api_client():
    """API client fixture for test module."""
    client = APIClient()
    yield client
    client.cleanup()

@pytest.fixture
def temp_file(tmp_path):
    """Temporary file fixture (function scope)."""
    file = tmp_path / "test.txt"
    file.write_text("test content")
    return file
```

## Running Tests

### Basic Commands

```bash
# Run all tests
pytest

# Run specific file
pytest tests/test_module.py

# Run specific test
pytest tests/test_module.py::test_function

# Run with markers
pytest -m unit
pytest -m "not slow"

# Parallel execution
pytest -n auto

# With coverage
pytest --cov=src --cov-report=html
```

### Common Options

- `-v`: Verbose output
- `-s`: Show print statements
- `-x`: Stop on first failure
- `--lf`: Run last failed
- `--ff`: Run failed first
- `-k PATTERN`: Run tests matching pattern

## Best Practices

### Test Organization

- Mirror source structure in tests
- Group related tests in classes
- Use descriptive test names
- One assertion per test (generally)

### Test Independence

- Each test should be independent
- Don't rely on test execution order
- Use fixtures for setup/teardown
- Clean up resources

### Test Clarity

- Arrange, Act, Assert pattern
- Clear test names describing what's tested
- Use docstrings for complex tests
- Keep tests simple and focused

## Supporting Documentation

This skill is supported by detailed documentation:

- **README.md** - Overview and when to use
- **setup.md** - Detailed setup and configuration guide

## Common Issues

### Tests Not Discovered

**Cause**: File/function naming doesn't match patterns

**Solution**:

- Use `test_*.py` for files
- Use `test_*()` for functions
- Add `testpaths = tests` to config

### Import Errors

**Cause**: Package not installed or PYTHONPATH issues

**Solution**:

- Install package: `pip install -e .`
- Use src/ layout
- Check PYTHONPATH

### Fixtures Not Found

**Cause**: Fixture not in scope

**Solution**:

- Define in `conftest.py` for shared fixtures
- Check fixture name matches exactly
- Verify `conftest.py` location

## Summary

The pytest Patterns skill provides:

- **Setup guidance** for new and existing projects
- **Configuration examples** for optimal pytest usage
- **Testing patterns** for unit and integration tests
- **Fixture patterns** for reusable test setup
- **CI/CD integration** examples
- **Troubleshooting** common issues

**Key Principle**: Write simple, focused tests with clear naming and proper use of fixtures for maintainability.

---

**Version**: 1.0.0
**Last Updated**: 2025-10-20
**Maintained By**: AIDA Framework Team
