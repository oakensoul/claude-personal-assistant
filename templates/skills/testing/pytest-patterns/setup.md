# pytest Setup

Complete guide to installing and configuring pytest in Python projects.

## Installation

### Basic Installation

```bash

# Using pip
pip install pytest

# Using poetry
poetry add --group dev pytest

# Using pipenv
pipenv install --dev pytest

```

### Recommended Plugins

```bash

# Install commonly used plugins
pip install pytest-cov pytest-mock pytest-asyncio pytest-xdist

# Or with poetry
poetry add --group dev pytest-cov pytest-mock pytest-asyncio pytest-xdist

```

**Plugin Descriptions**:

- `pytest-cov`: Coverage reporting
- `pytest-mock`: Simplified mocking
- `pytest-asyncio`: Async test support
- `pytest-xdist`: Parallel test execution

## Project Structure

### Recommended Directory Layout

```

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
├── pyproject.toml           # Modern Python projects
└── setup.py                 # Legacy Python projects

```

### Test File Naming

pytest discovers tests using these patterns:

- Test files: `test_*.py` or `*_test.py`
- Test functions: `test_*`
- Test classes: `Test*`

**Examples**:

- ✅ `test_user_auth.py`, `test_api.py`
- ✅ `def test_login()`, `def test_password_reset()`
- ✅ `class TestUserModel`, `class TestAuthentication`
- ❌ `user_test.py` (use `test_user.py`)
- ❌ `def verify_login()` (use `test_login()`)

## Configuration

### pytest.ini

Create `pytest.ini` in project root:

```ini

[pytest]
# Minimum version
minversion = 7.0

# Test discovery patterns
python_files = test_*.py *_test.py
python_classes = Test*
python_functions = test_*

# Test paths
testpaths = tests

# Command line options (always applied)
addopts =

    --strict-markers
    --verbose
    --color=yes
    --cov=src
    --cov-report=term-missing
    --cov-report=html
    --cov-fail-under=80

# Custom markers
markers =
    slow: marks tests as slow (deselect with '-m "not slow"')
    integration: marks tests as integration tests
    unit: marks tests as unit tests
    smoke: marks tests as smoke tests

# Ignore paths
norecursedirs = .git .tox dist build *.egg

```

### pyproject.toml (Modern Alternative)

```toml

[tool.pytest.ini_options]
minversion = "7.0"
testpaths = ["tests"]
python_files = ["test_*.py", "*_test.py"]
python_classes = ["Test*"]
python_functions = ["test_*"]

addopts = [
    "--strict-markers",
    "--verbose",
    "--color=yes",
    "--cov=src",
    "--cov-report=term-missing",
    "--cov-report=html",
    "--cov-fail-under=80",
]

markers = [
    "slow: marks tests as slow",
    "integration: integration tests",
    "unit: unit tests",
    "smoke: smoke tests",
]

```

## Running Tests

### Basic Commands

```bash

# Run all tests
pytest

# Run specific file
pytest tests/test_user.py

# Run specific test
pytest tests/test_user.py::test_login

# Run tests matching pattern
pytest -k "test_user"

# Run tests with specific marker
pytest -m unit
pytest -m "not slow"

# Verbose output
pytest -v

# Show print statements
pytest -s

# Stop on first failure
pytest -x

# Run last failed tests
pytest --lf

# Run failed tests first, then others
pytest --ff

```

### Parallel Execution

```bash

# Install pytest-xdist
pip install pytest-xdist

# Run tests in parallel (auto-detect CPU count)
pytest -n auto

# Run tests on 4 workers
pytest -n 4

```

### Coverage

```bash

# Run with coverage
pytest --cov=src

# Generate HTML report
pytest --cov=src --cov-report=html

# Open coverage report
open htmlcov/index.html  # macOS

```

## Example Test File

```python

# tests/test_calculator.py
"""Tests for calculator module."""
import pytest
from calculator import Calculator


class TestCalculator:
    """Test suite for Calculator class."""

    @pytest.fixture
    def calc(self):
        """Provide a calculator instance."""
        return Calculator()

    def test_add(self, calc):
        """Test addition."""
        assert calc.add(2, 3) == 5
        assert calc.add(-1, 1) == 0
        assert calc.add(0, 0) == 0

    def test_subtract(self, calc):
        """Test subtraction."""
        assert calc.subtract(5, 3) == 2
        assert calc.subtract(0, 5) == -5

    def test_multiply(self, calc):
        """Test multiplication."""
        assert calc.multiply(2, 3) == 6
        assert calc.multiply(-2, 3) == -6

    def test_divide(self, calc):
        """Test division."""
        assert calc.divide(6, 2) == 3
        assert calc.divide(5, 2) == 2.5

    def test_divide_by_zero(self, calc):
        """Test division by zero raises error."""
        with pytest.raises(ZeroDivisionError):
            calc.divide(10, 0)

    @pytest.mark.slow
    def test_complex_calculation(self, calc):
        """Test complex calculation (marked as slow)."""
        # ... slow test ...
        pass

```

## conftest.py

Create `tests/conftest.py` for shared fixtures:

```python

"""Shared pytest fixtures."""
import pytest
from database import Database
from api_client import APIClient


@pytest.fixture(scope="session")
def database():
    """Provide a test database for entire test session."""
    db = Database(":memory:")
    db.setup()
    yield db
    db.teardown()


@pytest.fixture
def api_client():
    """Provide API client for testing."""
    client = APIClient(base_url="http://localhost:8000")
    yield client
    client.close()


@pytest.fixture
def mock_env(monkeypatch):
    """Set up mock environment variables."""
    monkeypatch.setenv("API_KEY", "test-key")
    monkeypatch.setenv("DEBUG", "true")

```

## Best Practices

### Test Organization

- ✅ Mirror source structure in tests: `src/user.py` → `tests/test_user.py`
- ✅ Group related tests in classes
- ✅ Use descriptive test names: `test_user_login_with_valid_credentials`
- ✅ One assertion per test (generally)
- ✅ Use markers for slow/integration tests

### Test Independence

- ✅ Each test should be independent
- ✅ Don't rely on test execution order
- ✅ Use fixtures for setup/teardown
- ✅ Clean up resources in fixtures
- ❌ Don't share state between tests

### Test Clarity

- ✅ Arrange, Act, Assert pattern
- ✅ Clear test names describe what's being tested
- ✅ Use docstrings for complex tests
- ✅ Keep tests simple and focused
- ❌ Don't test implementation details

## Troubleshooting

### Tests Not Discovered

**Problem**: pytest doesn't find your tests

**Solutions**:

- Check file naming: `test_*.py` or `*_test.py`
- Check function naming: `test_*`
- Verify `testpaths` in configuration
- Ensure `__init__.py` exists in test directories

### Import Errors

**Problem**: `ModuleNotFoundError` when running tests

**Solutions**:

- Install package in editable mode: `pip install -e .`
- Check `PYTHONPATH` includes source directory
- Use `src/` layout (recommended)
- Add `conftest.py` to help with paths

### Fixtures Not Found

**Problem**: `fixture 'db' not found`

**Solutions**:

- Check fixture is defined in `conftest.py` or same file
- Verify fixture name matches exactly
- Check `conftest.py` is in correct directory
- Ensure `conftest.py` has no syntax errors

## References

- [pytest Documentation](https://docs.pytest.org/)
- [pytest Good Integration Practices](https://docs.pytest.org/en/stable/goodpractices.html)
- [Effective Python Testing](https://realpython.com/pytest-python-testing/)
