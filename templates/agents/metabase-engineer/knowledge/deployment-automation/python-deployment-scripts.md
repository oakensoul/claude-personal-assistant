---
title: "Python Deployment Scripts"
description: "Architecture and patterns for Python-based Metabase deployment automation"
category: "deployment-automation"
tags: ["python", "deployment", "automation", "api", "ci-cd"]
last_updated: "2025-10-16"
---

# Python Deployment Scripts

Comprehensive guide to building Python scripts for deploying Metabase dashboards and questions from YAML specifications via the REST API.

## Architecture Overview

```text
┌─────────────────────┐
│  YAML Specification │
│  (Dashboard Def)    │
└──────────┬──────────┘
           │
           ↓
┌─────────────────────┐
│  YAML Parser        │
│  (PyYAML)           │
└──────────┬──────────┘
           │
           ↓
┌─────────────────────┐
│  Validation Layer   │
│  (JSON Schema)      │
└──────────┬──────────┘
           │
           ↓
┌─────────────────────┐
│  Deployment Engine  │
│  - Auth             │
│  - Create/Update    │
│  - Idempotency      │
└──────────┬──────────┘
           │
           ↓
┌─────────────────────┐
│  Metabase API       │
│  (REST Requests)    │
└─────────────────────┘
```

## Core Script Structure

### deployment.py

```python
#!/usr/bin/env python3
"""
Metabase Dashboard Deployment Script

Deploys YAML dashboard specifications to Metabase via REST API.
Supports idempotent deployments (create or update).
"""

import os
import sys
import logging
import argparse
from pathlib import Path
from typing import Dict, Any, Optional, List

import yaml
import requests
from jsonschema import validate, ValidationError


class MetabaseClient:
    """Client for Metabase REST API operations."""

    def __init__(self, base_url: str, username: str, password: str):
        """
        Initialize Metabase client.

        Args:
            base_url: Metabase instance URL (e.g., https://metabase.example.com)
            username: Username for authentication
            password: Password for authentication
        """
        self.base_url = base_url.rstrip('/')
        self.session_token = None
        self.session = requests.Session()

        # Authenticate
        self._authenticate(username, password)

    def _authenticate(self, username: str, password: str) -> None:
        """Authenticate and obtain session token."""
        url = f"{self.base_url}/api/session"
        payload = {"username": username, "password": password}

        response = self.session.post(url, json=payload)
        response.raise_for_status()

        self.session_token = response.json()["id"]
        self.session.headers.update({"X-Metabase-Session": self.session_token})

        logging.info("Successfully authenticated with Metabase")

    def get_database_id(self, database_name: str) -> int:
        """Get database ID by name."""
        url = f"{self.base_url}/api/database"
        response = self.session.get(url)
        response.raise_for_status()

        databases = response.json()["data"]
        for db in databases:
            if db["name"] == database_name:
                return db["id"]

        raise ValueError(f"Database '{database_name}' not found")

    def get_collection_id(self, collection_path: str) -> Optional[int]:
        """
        Get collection ID by path.

        Args:
            collection_path: Collection path (e.g., "Finance/Market Maker")

        Returns:
            Collection ID or None for root collection
        """
        if not collection_path or collection_path == "Root":
            return None

        url = f"{self.base_url}/api/collection"
        response = self.session.get(url)
        response.raise_for_status()

        collections = response.json()

        # Handle nested paths
        parts = collection_path.split("/")
        parent_id = None

        for part in parts:
            found = False
            for coll in collections:
                if coll["name"] == part and coll.get("parent_id") == parent_id:
                    parent_id = coll["id"]
                    found = True
                    break

            if not found:
                raise ValueError(f"Collection '{collection_path}' not found")

        return parent_id

    def find_dashboard(self, name: str, collection_id: Optional[int]) -> Optional[Dict]:
        """Find dashboard by name in collection."""
        url = f"{self.base_url}/api/dashboard"
        params = {"f": "all"}

        response = self.session.get(url, params=params)
        response.raise_for_status()

        dashboards = response.json()["data"]
        for dash in dashboards:
            if dash["name"] == name and dash["collection_id"] == collection_id:
                return dash

        return None

    def create_dashboard(self, spec: Dict[str, Any]) -> Dict:
        """Create new dashboard from specification."""
        url = f"{self.base_url}/api/dashboard"

        collection_id = self.get_collection_id(spec["collection"])

        payload = {
            "name": spec["name"],
            "description": spec.get("description", ""),
            "collection_id": collection_id,
            "parameters": self._build_parameters(spec.get("filters", [])),
        }

        response = self.session.post(url, json=payload)
        response.raise_for_status()

        dashboard = response.json()
        logging.info(f"Created dashboard: {spec['name']} (ID: {dashboard['id']})")

        return dashboard

    def update_dashboard(self, dashboard_id: int, spec: Dict[str, Any]) -> Dict:
        """Update existing dashboard."""
        url = f"{self.base_url}/api/dashboard/{dashboard_id}"

        collection_id = self.get_collection_id(spec["collection"])

        payload = {
            "name": spec["name"],
            "description": spec.get("description", ""),
            "collection_id": collection_id,
            "parameters": self._build_parameters(spec.get("filters", [])),
        }

        response = self.session.put(url, json=payload)
        response.raise_for_status()

        dashboard = response.json()
        logging.info(f"Updated dashboard: {spec['name']} (ID: {dashboard_id})")

        return dashboard

    def create_question(self, spec: Dict[str, Any], database_id: int) -> Dict:
        """Create question (card) from specification."""
        url = f"{self.base_url}/api/card"

        collection_id = self.get_collection_id(spec.get("collection", ""))

        payload = {
            "name": spec["name"],
            "description": spec.get("description", ""),
            "collection_id": collection_id,
            "database_id": database_id,
            "dataset_query": self._build_query(spec["query"], database_id),
            "display": spec["visualization"]["type"],
            "visualization_settings": spec["visualization"].get("settings", {}),
        }

        response = self.session.post(url, json=payload)
        response.raise_for_status()

        question = response.json()
        logging.info(f"Created question: {spec['name']} (ID: {question['id']})")

        return question

    def add_card_to_dashboard(
        self,
        dashboard_id: int,
        card_id: int,
        position: Dict[str, int]
    ) -> Dict:
        """Add card to dashboard at specified position."""
        url = f"{self.base_url}/api/dashboard/{dashboard_id}/cards"

        payload = {
            "cardId": card_id,
            "row": position["row"],
            "col": position["col"],
            "sizeX": position["sizeX"],
            "sizeY": position["sizeY"],
        }

        response = self.session.post(url, json=payload)
        response.raise_for_status()

        return response.json()

    def _build_parameters(self, filters: List[Dict]) -> List[Dict]:
        """Build Metabase parameter definitions from filter specs."""
        parameters = []

        for f in filters:
            param = {
                "name": f["name"],
                "slug": f["field"],
                "id": f["field"],
                "type": self._map_filter_type(f["type"]),
                "default": f.get("default"),
            }
            parameters.append(param)

        return parameters

    def _build_query(self, query_spec: Dict, database_id: int) -> Dict:
        """Build Metabase query object from specification."""
        if "sql" in query_spec:
            # Native SQL query
            return {
                "type": "native",
                "native": {
                    "query": query_spec["sql"],
                    "template-tags": self._build_template_tags(
                        query_spec.get("parameters", [])
                    ),
                },
                "database": database_id,
            }
        else:
            # GUI query
            return {
                "type": "query",
                "query": {
                    "source-table": self._get_table_id(
                        database_id, query_spec["source"]
                    ),
                    "aggregation": self._build_aggregation(query_spec),
                    "breakout": self._build_breakout(query_spec),
                    "filter": self._build_filter(query_spec.get("filters", [])),
                },
                "database": database_id,
            }

    def _map_filter_type(self, filter_type: str) -> str:
        """Map specification filter type to Metabase parameter type."""
        mapping = {
            "date-range": "date/range",
            "date": "date/single",
            "category": "category",
            "number": "number",
            "text": "string/=",
        }
        return mapping.get(filter_type, "string/=")

    def _build_template_tags(self, parameters: List[Dict]) -> Dict:
        """Build template tags for native query parameters."""
        tags = {}

        for param in parameters:
            tags[param["name"]] = {
                "id": param["name"],
                "name": param["name"],
                "display-name": param.get("display_name", param["name"]),
                "type": param["type"],
                "default": param.get("default"),
                "required": param.get("required", True),
            }

        return tags

    def _get_table_id(self, database_id: int, table_name: str) -> int:
        """Get table ID by name."""
        url = f"{self.base_url}/api/database/{database_id}/metadata"
        response = self.session.get(url)
        response.raise_for_status()

        metadata = response.json()
        for table in metadata["tables"]:
            if table["name"] == table_name:
                return table["id"]

        raise ValueError(f"Table '{table_name}' not found")

    def _build_aggregation(self, query_spec: Dict) -> List:
        """Build aggregation clause for GUI query."""
        # Simplified - expand based on needs
        if "aggregation" in query_spec:
            return [[query_spec["aggregation"], ["field", query_spec["metrics"][0]]]]
        return []

    def _build_breakout(self, query_spec: Dict) -> List:
        """Build breakout (GROUP BY) clause for GUI query."""
        if "dimensions" in query_spec:
            return [["field", dim] for dim in query_spec["dimensions"]]
        return []

    def _build_filter(self, filters: List[Dict]) -> List:
        """Build filter clause for GUI query."""
        # Simplified - expand based on needs
        filter_clauses = []
        for f in filters:
            filter_clauses.append([
                f["operator"],
                ["field", f["field"]],
                f["value"]
            ])

        if len(filter_clauses) == 1:
            return filter_clauses[0]
        elif len(filter_clauses) > 1:
            return ["and"] + filter_clauses
        return []


class DashboardDeployer:
    """Orchestrates dashboard deployment from YAML specifications."""

    def __init__(self, client: MetabaseClient):
        self.client = client

    def deploy(self, spec_path: Path, force_update: bool = False) -> None:
        """
        Deploy dashboard from YAML specification.

        Args:
            spec_path: Path to YAML specification file
            force_update: If True, update existing dashboard; if False, skip
        """
        # Load specification
        with open(spec_path, 'r') as f:
            spec = yaml.safe_load(f)

        # Validate specification
        self._validate_spec(spec)

        # Get database ID
        database_id = self.client.get_database_id(spec["database"])
        collection_id = self.client.get_collection_id(spec["collection"])

        # Check if dashboard exists
        existing = self.client.find_dashboard(spec["name"], collection_id)

        if existing:
            if force_update:
                logging.info(f"Updating existing dashboard: {spec['name']}")
                dashboard = self.client.update_dashboard(existing["id"], spec)
                dashboard_id = existing["id"]

                # Remove existing cards
                self._remove_dashboard_cards(dashboard_id)
            else:
                logging.info(f"Dashboard exists, skipping: {spec['name']}")
                return
        else:
            # Create new dashboard
            dashboard = self.client.create_dashboard(spec)
            dashboard_id = dashboard["id"]

        # Deploy questions and add to dashboard
        for question_spec in spec.get("questions", []):
            # Create question
            question = self.client.create_question(question_spec, database_id)

            # Add to dashboard
            self.client.add_card_to_dashboard(
                dashboard_id,
                question["id"],
                question_spec["position"]
            )

        dashboard_url = f"{self.client.base_url}/dashboard/{dashboard_id}"
        logging.info(f"Successfully deployed dashboard: {dashboard_url}")

    def _validate_spec(self, spec: Dict) -> None:
        """Validate specification against JSON schema."""
        # Load schema (simplified - implement full schema validation)
        required_fields = ["name", "description", "collection", "database", "questions"]

        for field in required_fields:
            if field not in spec:
                raise ValueError(f"Missing required field: {field}")

        logging.info("Specification validation passed")

    def _remove_dashboard_cards(self, dashboard_id: int) -> None:
        """Remove all cards from dashboard."""
        url = f"{self.client.base_url}/api/dashboard/{dashboard_id}"
        response = self.client.session.get(url)
        response.raise_for_status()

        dashboard = response.json()

        for card in dashboard.get("ordered_cards", []):
            card_url = f"{url}/cards"
            self.client.session.delete(f"{card_url}/{card['id']}")

        logging.info(f"Removed existing cards from dashboard {dashboard_id}")


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Deploy Metabase dashboards from YAML specifications"
    )
    parser.add_argument(
        "spec_path",
        type=Path,
        help="Path to YAML specification file or directory"
    )
    parser.add_argument(
        "--env",
        choices=["dev", "staging", "prod"],
        default="dev",
        help="Target environment"
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Force update existing dashboards"
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Enable verbose logging"
    )

    args = parser.parse_args()

    # Configure logging
    log_level = logging.DEBUG if args.verbose else logging.INFO
    logging.basicConfig(
        level=log_level,
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    )

    # Load environment configuration
    metabase_url = os.environ.get(f"METABASE_{args.env.upper()}_URL")
    metabase_user = os.environ.get(f"METABASE_{args.env.upper()}_USER")
    metabase_pass = os.environ.get(f"METABASE_{args.env.upper()}_PASSWORD")

    if not all([metabase_url, metabase_user, metabase_pass]):
        logging.error(f"Missing required environment variables for {args.env}")
        sys.exit(1)

    # Initialize client
    client = MetabaseClient(metabase_url, metabase_user, metabase_pass)
    deployer = DashboardDeployer(client)

    # Deploy specification(s)
    if args.spec_path.is_file():
        deployer.deploy(args.spec_path, args.force)
    elif args.spec_path.is_dir():
        for spec_file in args.spec_path.glob("**/*.yaml"):
            logging.info(f"Processing {spec_file}")
            deployer.deploy(spec_file, args.force)
    else:
        logging.error(f"Invalid path: {args.spec_path}")
        sys.exit(1)


if __name__ == "__main__":
    main()
```

## Supporting Scripts

### validate_specs.py

```python
#!/usr/bin/env python3
"""Validate YAML specifications against schema."""

import sys
from pathlib import Path
import yaml
from jsonschema import validate, ValidationError


def validate_spec(spec_path: Path) -> bool:
    """Validate a single specification file."""
    try:
        with open(spec_path, 'r') as f:
            spec = yaml.safe_load(f)

        # Validate required fields
        required = ["name", "description", "collection", "database"]
        for field in required:
            if field not in spec:
                print(f"❌ {spec_path}: Missing required field '{field}'")
                return False

        # Validate questions
        if "questions" in spec:
            for i, q in enumerate(spec["questions"]):
                if "name" not in q or "query" not in q:
                    print(f"❌ {spec_path}: Question {i} missing required fields")
                    return False

        print(f"✓ {spec_path}: Valid")
        return True

    except yaml.YAMLError as e:
        print(f"❌ {spec_path}: YAML parsing error: {e}")
        return False
    except Exception as e:
        print(f"❌ {spec_path}: Validation error: {e}")
        return False


def main():
    """Validate all specifications in directory."""
    specs_dir = Path("specifications/dashboards")

    all_valid = True
    for spec_file in specs_dir.glob("**/*.yaml"):
        if not validate_spec(spec_file):
            all_valid = False

    if not all_valid:
        sys.exit(1)


if __name__ == "__main__":
    main()
```

## Environment Configuration

### .env.template

```bash
# Development
METABASE_DEV_URL=https://metabase-dev.betterpool.com
METABASE_DEV_USER=deployer@betterpool.com
METABASE_DEV_PASSWORD=<secret>

# Staging
METABASE_STAGING_URL=https://metabase-staging.betterpool.com
METABASE_STAGING_USER=deployer@betterpool.com
METABASE_STAGING_PASSWORD=<secret>

# Production
METABASE_PROD_URL=https://metabase.betterpool.com
METABASE_PROD_USER=deployer@betterpool.com
METABASE_PROD_PASSWORD=<secret>
```

### requirements.txt

```text
pyyaml>=6.0.1
requests>=2.31.0
jsonschema>=4.19.1
python-dotenv>=1.0.0
click>=8.1.7
```

## Usage Examples

### Deploy Single Dashboard

```bash
# Deploy to development
python scripts/deploy.py specifications/dashboards/finance/market_maker.yaml --env dev

# Deploy to production
python scripts/deploy.py specifications/dashboards/finance/market_maker.yaml --env prod

# Force update existing dashboard
python scripts/deploy.py specifications/dashboards/finance/market_maker.yaml --env dev --force
```

### Deploy All Dashboards

```bash
# Deploy all dashboards in directory
python scripts/deploy.py specifications/dashboards/ --env dev

# Deploy specific domain
python scripts/deploy.py specifications/dashboards/finance/ --env prod
```

### Validate Specifications

```bash
# Validate all specifications
python scripts/validate_specs.py

# Validate specific file
python scripts/validate_specs.py specifications/dashboards/finance/market_maker.yaml
```

## Best Practices

### Idempotency

- Check if dashboard exists before creating
- Use find-or-create pattern
- Support both create and update operations
- Make deployments repeatable

### Error Handling

- Catch and log API errors gracefully
- Provide meaningful error messages
- Support partial rollback on failure
- Validate specifications before deployment

### Performance

- Batch operations when possible
- Cache database/collection IDs
- Use connection pooling
- Implement retry logic with exponential backoff

### Security

- Never commit credentials
- Use environment variables
- Support API key authentication
- Implement proper session management

### Logging

- Log all operations
- Include timestamps
- Different log levels (DEBUG, INFO, ERROR)
- Support verbose mode for debugging

---

**Related Documents**:

- [cicd-pipeline-patterns.md](cicd-pipeline-patterns.md) - CI/CD integration
- [environment-configuration.md](environment-configuration.md) - Environment setup
- [api-dashboards.md](../api-reference/api-dashboards.md) - API reference
