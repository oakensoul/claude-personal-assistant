---
title: "Python Expert Skill"
description: "Advanced Python development expertise with focus on data science and ML"
type: "skill"
author: "user"
created: "2024-06-05"
modified: "2024-09-20"
category: "development"
tags: ["python", "data-science", "machine-learning", "pandas", "scikit-learn"]
expertise_level: "advanced"
specializations: ["pandas", "numpy", "scikit-learn", "tensorflow", "asyncio"]
---

# Python Expert Skill

Advanced Python development skill with specialization in data science, machine learning, and async programming.

## Core Competencies

1. **Data Science** - pandas, numpy, data analysis, visualization
2. **Machine Learning** - scikit-learn, tensorflow, model training, evaluation
3. **Async Programming** - asyncio, aiohttp, concurrent processing
4. **Code Quality** - type hints, testing, profiling, optimization
5. **Package Management** - poetry, pip, virtual environments, dependency resolution

## When to Use This Skill

Invoke the `python-expert` skill when working on:

- Data analysis with pandas/numpy
- Machine learning model development
- Async/concurrent Python code
- Performance optimization
- Python package development
- Code refactoring and quality improvements

## Capabilities

### Data Analysis

Expert in:

```python
import pandas as pd
import numpy as np

# Data manipulation
df = pd.read_csv('data.csv')
df.groupby('category').agg({'value': ['mean', 'std', 'count']})

# Time series analysis
df['date'] = pd.to_datetime(df['date'])
df.set_index('date').resample('D').mean()

# Data cleaning
df.fillna(df.median()).dropna(subset=['critical_column'])
```

### Machine Learning

Proficient with:

```python
from sklearn.model_selection import train_test_split, GridSearchCV
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import classification_report

# Model training
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2)
model = RandomForestClassifier(n_estimators=100)
model.fit(X_train, y_train)

# Hyperparameter tuning
param_grid = {'n_estimators': [50, 100, 200], 'max_depth': [10, 20, None]}
grid_search = GridSearchCV(model, param_grid, cv=5)
grid_search.fit(X_train, y_train)
```

### Async Programming

Experienced with:

```python
import asyncio
import aiohttp

async def fetch_data(session, url):
    async with session.get(url) as response:
        return await response.json()

async def fetch_all(urls):
    async with aiohttp.ClientSession() as session:
        tasks = [fetch_data(session, url) for url in urls]
        return await asyncio.gather(*tasks)

# Run concurrent requests
results = asyncio.run(fetch_all(urls))
```

### Code Quality

Best practices:

```python
from typing import List, Optional, Dict
import pytest

def process_data(
    data: List[Dict[str, any]],
    filter_key: Optional[str] = None
) -> pd.DataFrame:
    """
    Process raw data into structured DataFrame.

    Args:
        data: List of data dictionaries
        filter_key: Optional key to filter by

    Returns:
        Processed DataFrame with validated schema
    """
    df = pd.DataFrame(data)

    if filter_key:
        df = df[df['key'] == filter_key]

    return df

# Type-checked testing
@pytest.mark.parametrize("data,expected", [
    ([{'key': 'a', 'val': 1}], 1),
    ([{'key': 'b', 'val': 2}], 1),
])
def test_process_data(data: List[Dict], expected: int):
    result = process_data(data)
    assert len(result) == expected
```

## Development Practices

### Environment Setup

```bash
# Poetry-based project
poetry init
poetry add pandas numpy scikit-learn
poetry add --group dev pytest black mypy ruff

# Virtual environment
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### Testing Strategy

```python
# Unit tests with fixtures
@pytest.fixture
def sample_data():
    return pd.DataFrame({'a': [1, 2, 3], 'b': [4, 5, 6]})

def test_data_processing(sample_data):
    result = process(sample_data)
    assert result.shape == (3, 2)
    assert result['a'].sum() == 6
```

### Performance Optimization

```python
import cProfile
import line_profiler

# Profile function
cProfile.run('expensive_function()')

# Line-by-line profiling
@profile
def expensive_function():
    # Code to profile
    pass
```

## Common Patterns

### Data Pipeline

```python
class DataPipeline:
    def __init__(self, source: str):
        self.source = source

    def extract(self) -> pd.DataFrame:
        return pd.read_csv(self.source)

    def transform(self, df: pd.DataFrame) -> pd.DataFrame:
        return df.dropna().apply(self.normalize)

    def load(self, df: pd.DataFrame, target: str):
        df.to_parquet(target, compression='snappy')

    def run(self, target: str):
        df = self.extract()
        df = self.transform(df)
        self.load(df, target)
```

### ML Model Wrapper

```python
class ModelWrapper:
    def __init__(self, model_type: str = 'random_forest'):
        self.model_type = model_type
        self.model = None

    def train(self, X, y):
        if self.model_type == 'random_forest':
            self.model = RandomForestClassifier(n_estimators=100)
        self.model.fit(X, y)

    def predict(self, X):
        if self.model is None:
            raise ValueError("Model not trained")
        return self.model.predict(X)

    def evaluate(self, X_test, y_test):
        y_pred = self.predict(X_test)
        return classification_report(y_test, y_pred)
```

## User Content Notice

This is a custom skill definition created by the user for Python development work. It represents specialized expertise and user preferences that should be preserved across AIDA framework upgrades.

**Location**: `~/.claude/skills/python-expert.md` (user space, NOT `.aida/` namespace)

**CRITICAL**: This file is user-generated content and must never be modified or replaced by the AIDA installer. It contains personalized coding patterns and preferences.
