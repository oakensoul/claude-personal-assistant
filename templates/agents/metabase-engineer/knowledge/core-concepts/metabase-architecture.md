---

title: "Metabase Architecture & Data Model"
description: "Understanding Metabase's internal data model, collections, dashboards, questions, and database connections"
category: "core-concepts"
tags: ["architecture", "data-model", "collections", "dashboards"]
last_updated: "2025-10-16"

---

# Metabase Architecture & Data Model

Understanding Metabase's internal architecture is essential for effective API operations and reports-as-code development.

## High-Level Architecture

```

┌─────────────────────────────────────────────────────┐
│                  Metabase Web UI                    │
│            (React Frontend Application)             │
└─────────────────────────────────────────────────────┘
                         ↕
┌─────────────────────────────────────────────────────┐
│              Metabase REST API                      │
│         (Clojure Backend Application)               │
└─────────────────────────────────────────────────────┘
                         ↕
┌─────────────────────────────────────────────────────┐
│           Metabase Application Database             │
│          (PostgreSQL - Metadata Storage)            │
│  - Users, permissions, collections                  │
│  - Dashboard definitions, question definitions      │
│  - Query cache, audit logs                          │
└─────────────────────────────────────────────────────┘
                         ↕
┌─────────────────────────────────────────────────────┐
│          Connected Data Sources                     │
│  - Snowflake (dataops-splash-dwh)                   │
│  - PostgreSQL, MySQL, BigQuery, etc.                │
└─────────────────────────────────────────────────────┘

```

## Core Data Model

### Hierarchy

```

Database Connection
  └── Schema
      └── Table/View
          └── Column
              └── Field Metadata

Collection
  └── Sub-Collection
      ├── Dashboard
      │   └── Dashboard Card (Question Instance)
      └── Question (Saved Query)

```

## Entity Relationships

### Collections

Collections organize dashboards and questions hierarchically.

```

Root Collection (Your company)
├── Finance
│   ├── Executive Dashboards
│   ├── Revenue Reporting
│   └── Shared Questions
├── Contests
│   ├── Performance Dashboards
│   └── Fill Rate Analysis
└── Partners
    └── Partner Analytics

```

**Key Properties**:

- `id`: Unique collection identifier
- `name`: Display name
- `slug`: URL-friendly identifier
- `parent_id`: Parent collection (null = root)
- `archived`: Boolean (soft delete)
- `personal_owner_id`: User ID if personal collection

**API Endpoint**: `/api/collection`

### Dashboards

Dashboards are containers for questions (visualizations) with shared filters and layout.

**Key Properties**:

- `id`: Unique dashboard identifier
- `name`: Dashboard title
- `description`: Purpose and context
- `collection_id`: Parent collection
- `creator_id`: User who created it
- `parameters`: Dashboard-level filters
- `archived`: Boolean (soft delete)
- `cache_ttl`: Cache time-to-live (seconds)
- `enable_embedding`: Public embedding flag

**API Endpoint**: `/api/dashboard`

### Dashboard Cards

Dashboard cards represent question instances placed on a dashboard with position and size.

**Key Properties**:

- `id`: Unique card identifier
- `dashboard_id`: Parent dashboard
- `card_id`: Question being displayed (null for text cards)
- `row`: Grid row position (0-indexed)
- `col`: Grid column position (0-indexed)
- `sizeX`: Width in grid units (12-column grid)
- `sizeY`: Height in grid units
- `parameter_mappings`: Connect dashboard filters to question parameters
- `visualization_settings`: Override question visualization settings

**Grid System**: 12 columns, variable rows

```

┌────┬────┬────┬────┬────┬────┬────┬────┬────┬────┬────┬────┐
│ 0  │ 1  │ 2  │ 3  │ 4  │ 5  │ 6  │ 7  │ 8  │ 9  │ 10 │ 11 │
├────┴────┴────┴────┼────┴────┴────┴────┼────┴────┴────┴────┤
│   KPI Card (4x2)  │   KPI Card (4x2)  │   KPI Card (4x2)  │
│                   │                   │                   │
├────────────────────┴────────────────────┴───────────────────┤
│                  Chart (12x4)                               │
│                                                             │
│                                                             │
└─────────────────────────────────────────────────────────────┘

```

**API Endpoint**: `/api/dashboard/{id}/cards`

### Questions (Cards)

Questions are saved queries with visualization configuration. Also called "Cards" in Metabase's API.

**Question Types**:

1. **Native Query**: Raw SQL queries
2. **GUI Query**: Built with Metabase query builder
3. **Model**: Reusable query foundation (Metabase Models)

**Key Properties**:

- `id`: Unique question identifier
- `name`: Question title
- `description`: What this question shows
- `collection_id`: Parent collection
- `database_id`: Data source connection
- `dataset_query`: Query definition (SQL or GUI)
- `display`: Visualization type (scalar, line, bar, table, etc.)
- `visualization_settings`: Chart configuration
- `result_metadata`: Column types and formatting
- `archived`: Boolean (soft delete)

**API Endpoint**: `/api/card`

### Query Structure

#### Native Query Example

```json

{
  "database": 2,
  "type": "native",
  "native": {
    "query": "SELECT date_actual, SUM(revenue) as total_revenue FROM finance_revenue_daily WHERE date_actual >= {{start_date}} GROUP BY date_actual ORDER BY date_actual",
    "template-tags": {
      "start_date": {
        "id": "abc123",
        "name": "start_date",
        "display-name": "Start Date",
        "type": "date",
        "default": "2025-01-01",
        "required": true
      }
    }
  }
}

```

#### GUI Query Example

```json

{
  "database": 2,
  "type": "query",
  "query": {
    "source-table": 42,
    "aggregation": [["sum", ["field", 123, null]]],
    "breakout": [["field", 456, {"temporal-unit": "day"}]],
    "filter": ["between", ["field", 456, null], "2025-01-01", "2025-12-31"]
  }
}

```

### Database Connections

Database connections link Metabase to data sources.

**Key Properties**:

- `id`: Unique database identifier
- `name`: Display name (e.g., "Snowflake DWH")
- `engine`: Database type (snowflake, postgres, mysql, etc.)
- `details`: Connection parameters (host, port, database, etc.)
- `is_sample`: Sample database flag
- `is_full_sync`: Whether to sync all tables
- `cache_field_values_schedule`: Metadata sync schedule

**API Endpoint**: `/api/database`

### Schemas & Tables

After connecting a database, Metabase syncs schema metadata.

**Schema Hierarchy**:

```

Database: Snowflake DWH
├── Schema: PUBLIC
│   ├── Table: finance_revenue_daily
│   ├── Table: MART_HOUSE_LIQUIDITY
│   └── Table: fct_wallet_transactions
└── Schema: ANALYTICS
    └── Table: dim_user

```

**Field Metadata**:

- Field name and display name
- Data type (integer, float, text, date, etc.)
- Semantic type (PK, FK, category, metric, etc.)
- Special types (latitude, longitude, URL, email, etc.)

**API Endpoints**:

- `/api/database/{id}/metadata` - Full schema metadata
- `/api/database/{id}/schemas` - List schemas
- `/api/table/{id}` - Table details
- `/api/field/{id}` - Field details

## Permissions Model

### Permission Levels

**Collection Permissions**:

- **View**: Can see and use dashboards/questions
- **Edit**: Can modify dashboards/questions
- **Curate**: Can manage collection structure

**Database Permissions**:

- **No Access**: Cannot see database
- **Limited Access**: Can see specific tables
- **Unrestricted Access**: Can query any table
- **Native Query**: Can write raw SQL

**Groups**:

- Users belong to groups
- Permissions assigned to groups
- Special groups: "All Users", "Administrators"

### Access Control Best Practice

```

Group: Finance Team
├── Collection: Finance → Edit
├── Database: Snowflake DWH → Unrestricted
└── Database: Snowflake DWH (Native) → Allowed

Group: Executives
├── Collection: Finance → View
├── Collection: Shared → View
└── Database: Snowflake DWH → No Access (use saved questions only)

```

## Caching Architecture

### Query Result Cache

Metabase caches query results to improve performance.

**Cache Strategies**:

1. **TTL-based**: Cache expires after N seconds
2. **Adaptive**: Cache duration based on query execution time
3. **Dashboard-level**: Cache entire dashboard
4. **Question-level**: Cache individual questions

**Configuration**:

- Global default TTL
- Per-database TTL
- Per-dashboard TTL override
- Per-question TTL override

**Cache Invalidation**:

- Automatic: After TTL expires
- Manual: Clear cache via API
- On-demand: Refresh button in UI

### Field Values Cache

Metabase caches distinct values for dropdown filters.

**Sync Schedule**:

- Hourly, daily, or custom cron schedule
- Scans low-cardinality fields for filter values
- Stores top N values by frequency

## Data Model in Application Database

Metabase stores its metadata in PostgreSQL.

**Key Tables**:

- `metabase_database`: Database connections
- `collection`: Collection hierarchy
- `report_dashboard`: Dashboard definitions
- `report_dashboardcard`: Dashboard cards (question placements)
- `report_card`: Question definitions
- `query_execution`: Query execution logs
- `query_cache`: Cached query results
- `core_user`: User accounts
- `permissions_group`: User groups
- `permissions`: Permission mappings

**Note**: Direct database access is discouraged. Use REST API instead.

## API Authentication

### Session-Based Authentication

```bash

# Login
curl -X POST \
  https://metabase.example.com/api/session \

  -H 'Content-Type: application/json' \
  -d '{"username": "user@example.com", "password": "password"}'

# Response
{"id": "session-token-here"}

# Use session token
curl -X GET \
  https://metabase.example.com/api/dashboard/123 \

  -H 'X-Metabase-Session: session-token-here'


```

### API Key Authentication (Enterprise)

```bash

curl -X GET \
  https://metabase.example.com/api/dashboard/123 \

  -H 'X-API-KEY: your-api-key-here'


```

## Visualization Settings

Each visualization type has specific settings.

### Scalar (Number)

```json

{
  "scalar.field": "total_revenue",
  "scalar.comparisons": [{
    "id": "prev-period",
    "name": "vs. Previous Period",
    "color": "#509EE3"
  }]
}

```

### Line Chart

```json

{
  "graph.dimensions": ["date_actual"],
  "graph.metrics": ["total_revenue"],
  "graph.show_values": true,
  "graph.colors": ["#509EE3", "#84BB4C"],
  "graph.y_axis.scale": "linear",
  "graph.y_axis.auto_range": true
}

```

### Table

```json

{
  "table.columns": [
    {"name": "date_actual", "enabled": true, "fieldRef": ["field", 123, null]},
    {"name": "revenue", "enabled": true, "fieldRef": ["field", 456, null]}
  ],
  "table.column_formatting": [{
    "columns": ["revenue"],
    "type": "currency",
    "currency": "USD"
  }]
}

```

## Performance Considerations

### Query Performance

- Always include WHERE clauses on large tables
- Use indexed columns in filters
- Prefer marts over raw fact tables
- Limit result sets (LIMIT clause)
- Avoid SELECT * (specify columns)

### Dashboard Performance

- Limit to 15-20 questions per dashboard
- Use dashboard-level caching
- Optimize individual queries first
- Consider async loading for heavy queries
- Use scalars instead of tables for KPIs

### API Performance

- Batch operations when possible
- Use pagination for large result sets
- Implement exponential backoff for retries
- Monitor rate limits
- Cache API responses client-side

## Related Concepts

### Metabase Models (v42+)

Models are curated, reusable queries that serve as data sources for questions.

**Benefits**:

- Hide complexity from end users
- Enforce business logic in one place
- Performance optimization layer
- Documentation and metadata

**Use Case**: Create model for "Market Maker Daily Summary", then build multiple visualizations from it.

### Public Sharing

Dashboards and questions can be shared publicly via:

- **Public Links**: Anyone with link can view
- **Embedded Dashboards**: iFrame embedding with signed JWT
- **Static Embeds**: Pre-rendered images

**Security**: Use signed embedding for access control.

---

**Related Documents**:

- [yaml-specification-schema.md](yaml-specification-schema.md) - YAML spec reference
- [api-dashboards.md](../api-reference/api-dashboards.md) - Dashboard API operations
- [collections-and-permissions.md](collections-and-permissions.md) - Access control
