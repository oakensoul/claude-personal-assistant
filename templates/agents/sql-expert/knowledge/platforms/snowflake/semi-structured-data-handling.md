---
title: "Semi-Structured Data Handling Guide"
description: "Comprehensive guide to FLATTEN, VARIANT, JSON, and ARRAY operations for Segment events and semi-structured data in Snowflake"
agent: "snowflake-sql-expert"
category: "patterns"
tags:
  - flatten
  - variant
  - json
  - semi-structured
  - segment-events
  - array-operations
  - object-construct
last_updated: "2025-10-07"
priority: "high"
use_cases:
  - "Segment event processing"
  - "JSON property extraction"
  - "Nested object handling"
  - "Array aggregation"
  - "API response parsing"
---

# Semi-Structured Data Handling Guide

## Overview

Snowflake's semi-structured data support enables efficient processing of JSON, VARIANT, ARRAY, and OBJECT types. This is critical for the dbt-splash-prod-v2 project's high-volume Segment event data (`tag:source:segment`, `tag:volume:high`).

**Key Data Sources**:
- **Segment events**: Web, iOS, Android tracking (JSON event properties)
- **API responses**: Partner integrations (nested JSON structures)
- **Configuration data**: Feature flags, settings (JSON storage)

## Core Data Types

### VARIANT
Universal semi-structured type that can hold JSON objects, arrays, or primitive values:

```sql
-- VARIANT can hold any JSON structure
select
    event_properties,                    -- VARIANT column
    typeof(event_properties)             -- Returns 'OBJECT', 'ARRAY', or primitive type
from {{ ref('stg_segment__web_events') }}
```

### OBJECT
Key-value pairs (JSON object):

```sql
select
    event_properties:user_id::string,           -- Extract string property
    event_properties:session_id::number,        -- Extract numeric property
    event_properties:metadata::variant          -- Extract nested object
from {{ ref('stg_segment__web_events') }}
```

### ARRAY
Ordered list of values:

```sql
select
    event_properties:tags[0]::string,           -- First element
    array_size(event_properties:tags),          -- Array length
    array_slice(event_properties:tags, 0, 3)    -- First 3 elements
from {{ ref('stg_segment__web_events') }}
```

## Path Notation for Property Access

### Dot Notation
```sql
-- Access nested properties using colon
event_properties:user_id                     -- Top-level property
event_properties:metadata:device_type        -- Nested property
event_properties:nested:deep:property        -- Multiple levels
```

### Array Indexing
```sql
-- Access array elements (0-based indexing)
event_properties:tags[0]                     -- First tag
event_properties:tags[array_size(event_properties:tags) - 1]  -- Last tag
```

### Type Casting (CRITICAL)
```sql
-- ALWAYS cast VARIANT values to proper types
event_properties:user_id::string             -- Cast to string
event_properties:amount::number              -- Cast to number
event_properties:created_at::timestamp       -- Cast to timestamp
event_properties:is_active::boolean          -- Cast to boolean

-- ❌ WRONG: Missing cast (returns VARIANT)
event_properties:user_id

-- ✅ CORRECT: Explicit cast (returns STRING)
event_properties:user_id::string
```

## FLATTEN Function - Core Pattern

### Basic FLATTEN Syntax

```sql
select
    f.key,                               -- Object key name
    f.value,                             -- VARIANT value
    f.value::string as value_string,     -- Cast value
    f.index,                             -- Array index (for arrays)
    f.path,                              -- Full path to element
    f.seq,                               -- Sequence number
    f.this                               -- Parent object/array
from table_name,
    lateral flatten(input => variant_column) f
```

### FLATTEN for Segment Event Properties

**Example 1: Extract all event properties as rows**

```sql
-- Staging model for Segment web events with flattened properties
-- models/dwh/staging/analytics/stg_segment__web_event_properties.sql

{{
    config(
        tags=[
            'group:analytics',
            'layer:staging',
            'business:analytics',
            'source:segment',
            'volume:high',
            'critical:true'
        ]
    )
}}

with base_events as (

    select
        event_id,
        user_id,
        event_name,
        event_timestamp,
        event_properties  -- VARIANT column
    from {{ ref('stg_segment__web_events') }}
    where event_timestamp >= current_date - interval '90 days'

),

flattened_properties as (

    select
        e.event_id,
        e.user_id,
        e.event_name,
        e.event_timestamp,
        f.key as property_name,
        f.value as property_value_variant,
        typeof(f.value) as property_type,
        case
            when typeof(f.value) = 'VARCHAR' then f.value::string
            when typeof(f.value) = 'INTEGER' then f.value::number::string
            when typeof(f.value) = 'BOOLEAN' then f.value::boolean::string
            when typeof(f.value) = 'TIMESTAMP_NTZ' then f.value::timestamp::string
            else f.value::string
        end as property_value_string
    from base_events as e,
        lateral flatten(input => e.event_properties) as f

),

final as (

    select
        event_id,
        user_id,
        event_name,
        event_timestamp,
        property_name,
        property_value_string,
        property_type,
        current_timestamp() as transformed_at
    from flattened_properties

)

select * from final
```

**Example 2: Pivot specific properties into columns**

```sql
-- Extract specific Segment event properties as columns
with base_events as (

    select
        event_id,
        user_id,
        event_name,
        event_timestamp,
        event_properties
    from {{ ref('stg_segment__web_events') }}
    where event_name = 'Contest Entry Submitted'

)

select
    event_id,
    user_id,
    event_name,
    event_timestamp,
    event_properties:contest_id::number as contest_id,
    event_properties:entry_fee_cents::number / 100.0 as entry_fee_usd,
    event_properties:sport::string as sport,
    event_properties:contest_type::string as contest_type,
    event_properties:device_type::string as device_type,
    event_properties:referral_source::string as referral_source
from base_events
```

### Nested FLATTEN

**Example: Flatten nested arrays/objects**

```sql
-- Scenario: event_properties contains nested structure
-- { "metadata": { "tags": ["tag1", "tag2", "tag3"] } }

with nested_data as (

    select
        event_id,
        event_properties
    from {{ ref('stg_segment__web_events') }}

),

-- First FLATTEN: Extract metadata object
level_1_flatten as (

    select
        n.event_id,
        f1.value as metadata_object
    from nested_data as n,
        lateral flatten(input => n.event_properties) as f1
    where f1.key = 'metadata'

),

-- Second FLATTEN: Extract tags array
level_2_flatten as (

    select
        l1.event_id,
        f2.value::string as tag_value,
        f2.index as tag_index
    from level_1_flatten as l1,
        lateral flatten(input => l1.metadata_object:tags) as f2

)

select * from level_2_flatten
```

### FLATTEN with RECURSIVE => TRUE

For deeply nested structures with unknown depth:

```sql
select
    f.key,
    f.value,
    f.path  -- Shows full path through nested structure
from table_name,
    lateral flatten(input => variant_column, recursive => true) f
```

## ARRAY Functions

### ARRAY_AGG - Build Arrays from Rows

```sql
-- Aggregate contest IDs into array per user
select
    user_id,
    array_agg(contest_id) within group (order by entry_timestamp) as contest_ids_array,
    array_agg(
        object_construct(
            'contest_id', contest_id,
            'entry_fee', entry_fee_cents / 100.0,
            'timestamp', entry_timestamp
        )
    ) as contest_entries_json_array
from {{ ref('fct_contest_entries') }}
group by user_id
```

### ARRAY_CONSTRUCT - Create Arrays

```sql
select
    user_id,
    array_construct('web', 'ios', 'android') as platform_array,
    array_construct(
        contest_id_1,
        contest_id_2,
        contest_id_3
    ) as recent_contest_ids
from source_table
```

### ARRAY_SLICE - Extract Subarray

```sql
select
    user_id,
    recent_contest_ids,
    array_slice(recent_contest_ids, 0, 5) as top_5_contests,  -- First 5 (0-based)
    array_slice(recent_contest_ids, -3, 999) as last_3_contests  -- Last 3
from user_aggregates
```

### ARRAY_SIZE - Array Length

```sql
select
    user_id,
    contest_ids_array,
    array_size(contest_ids_array) as total_contests
from user_aggregates
where array_size(contest_ids_array) >= 10  -- Users with 10+ contests
```

### ARRAY_CONTAINS - Check Membership

```sql
select
    user_id,
    platform_tags,
    array_contains('ios'::variant, platform_tags) as has_ios,
    array_contains('web'::variant, platform_tags) as has_web
from user_platform_data
```

## OBJECT Functions

### OBJECT_CONSTRUCT - Build JSON Objects

```sql
-- Build JSON response for API export
select
    user_id,
    object_construct(
        'user_id', user_id,
        'email', email,
        'total_deposits', total_deposits_usd,
        'total_contests', total_contest_entries,
        'created_at', created_at_utc,
        'metadata', object_construct(
            'state', user_state,
            'referral_source', referral_source,
            'is_verified', is_email_verified
        )
    ) as user_json
from {{ ref('dim_user') }}
```

### OBJECT_KEYS - Extract Object Keys

```sql
select
    event_id,
    event_properties,
    object_keys(event_properties) as property_names_array
from {{ ref('stg_segment__web_events') }}
```

### OBJECT_CONSTRUCT_KEEP_NULL - Include NULL Values

```sql
-- Standard OBJECT_CONSTRUCT omits NULL values
select
    object_construct('key1', value1, 'key2', null)
    -- Returns: {"key1": "value"}

-- OBJECT_CONSTRUCT_KEEP_NULL includes NULLs
select
    object_construct_keep_null('key1', value1, 'key2', null)
    -- Returns: {"key1": "value", "key2": null}
```

## Performance Optimization for Semi-Structured Data

### 1. Extract Once, Reference Many Times

```sql
-- ❌ INEFFICIENT: Extracting same property multiple times
select
    event_properties:user_id::string,
    event_properties:user_id::string as uid_copy,
    upper(event_properties:user_id::string) as uid_upper
from events

-- ✅ EFFICIENT: Extract once in CTE
with extracted as (
    select
        event_properties:user_id::string as user_id,
        event_properties
    from events
)

select
    user_id,
    user_id as uid_copy,
    upper(user_id) as uid_upper
from extracted
```

### 2. Materialize Frequently-Accessed Properties

```sql
-- Create materialized staging model with extracted properties
-- models/dwh/staging/analytics/stg_segment__web_events.sql

{{
    config(
        materialized='incremental',
        unique_key='event_id',
        cluster_by=['event_date_et'],
        tags=[
            'group:analytics',
            'layer:staging',
            'source:segment',
            'volume:high',
            'critical:true'
        ]
    )
}}

select
    event_id,
    user_id,
    event_name,
    event_timestamp,
    -- Extract commonly-used properties to columns
    event_properties:contest_id::number as contest_id,
    event_properties:sport::string as sport,
    event_properties:device_type::string as device_type,
    event_properties:platform::string as platform,
    -- Keep full VARIANT for ad-hoc analysis
    event_properties as event_properties_json,
    date(convert_timezone('America/New_York', event_timestamp)) as event_date_et
from source_table
{% if is_incremental() %}
where event_timestamp > (select max(event_timestamp) from {{ this }})
{% endif %}
```

### 3. Use Search Optimization Service for JSON Queries

```sql
-- Enable search optimization for VARIANT column queries
-- Execute in Snowflake (not in dbt model):
alter table PROD.ANALYTICS_STAGING.STG_SEGMENT__WEB_EVENTS
    add search optimization on equality(event_properties:contest_id);

-- Now queries like this are much faster:
select *
from {{ ref('stg_segment__web_events') }}
where event_properties:contest_id::number = 12345
```

### 4. Filter Before FLATTEN

```sql
-- ✅ EFFICIENT: Filter before FLATTEN
with filtered_events as (
    select *
    from {{ ref('stg_segment__web_events') }}
    where event_name = 'Contest Entry Submitted'  -- Filter first
        and event_timestamp >= current_date - interval '7 days'
)

select
    event_id,
    f.key,
    f.value
from filtered_events,
    lateral flatten(input => event_properties) f

-- ❌ INEFFICIENT: FLATTEN entire table then filter
select
    event_id,
    f.key,
    f.value
from {{ ref('stg_segment__web_events') }},
    lateral flatten(input => event_properties) f
where event_name = 'Contest Entry Submitted'
```

## Common Patterns for Segment Events

### Pattern 1: Event Property Extraction (Staging Layer)

```sql
-- models/dwh/staging/analytics/stg_segment__contest_entry_events.sql

{{
    config(
        materialized='incremental',
        unique_key='event_id',
        tags=[
            'group:analytics',
            'layer:staging',
            'source:segment',
            'business:contests',
            'volume:high'
        ]
    )
}}

with base_events as (

    select
        id as event_id,
        user_id,
        event as event_name,
        timestamp as event_timestamp_utc,
        properties as event_properties
    from {{ source('segment', 'tracks') }}
    where event = 'Contest Entry Submitted'
        {% if is_incremental() %}
        and timestamp > (select max(event_timestamp_utc) from {{ this }})
        {% endif %}

),

extracted_properties as (

    select
        event_id,
        user_id,
        event_name,
        event_timestamp_utc,
        -- Extract critical properties
        event_properties:contest_id::number as contest_id,
        event_properties:entry_fee_cents::number as entry_fee_cents,
        event_properties:sport::string as sport,
        event_properties:contest_type::string as contest_type,
        event_properties:lineup::variant as lineup_json,
        event_properties:device_type::string as device_type,
        event_properties:platform::string as platform,
        -- Timezone handling
        {{ timezone_fields(
            utc_timestamp_column='event_timestamp_utc',
            date_et_column='event_date_et',
            timestamp_et_column='event_timestamp_et'
        ) }},
        current_timestamp() as transformed_at
    from base_events

),

final as (

    select * from extracted_properties

)

select * from final
```

### Pattern 2: Flatten Array Properties (Analytics)

```sql
-- Analyze tags/categories from Segment events
with events_with_tags as (

    select
        event_id,
        user_id,
        event_name,
        event_properties:tags as tags_array  -- Array of tag strings
    from {{ ref('stg_segment__web_events') }}
    where event_properties:tags is not null

)

select
    event_id,
    user_id,
    event_name,
    f.value::string as tag_value,
    f.index as tag_position
from events_with_tags,
    lateral flatten(input => tags_array) f
```

### Pattern 3: Build Aggregated JSON for Export

```sql
-- Create user summary JSON for API export
select
    user_id,
    object_construct(
        'user_id', user_id,
        'total_contests', count(distinct contest_id),
        'total_spent_usd', sum(entry_fee_cents) / 100.0,
        'favorite_sports', array_agg(distinct sport) within group (order by sport),
        'recent_contests', array_agg(
            object_construct(
                'contest_id', contest_id,
                'sport', sport,
                'entry_fee_usd', entry_fee_cents / 100.0,
                'timestamp', entry_timestamp_utc
            )
        ) within group (order by entry_timestamp_utc desc)
    ) as user_summary_json
from {{ ref('fct_contest_entries') }}
group by user_id
```

## Error Handling and NULL Safety

### Safe Property Access

```sql
-- ✅ SAFE: Returns NULL if property doesn't exist
event_properties:missing_property::string

-- ✅ SAFE: Check for NULL before processing
case
    when event_properties:user_id is not null
        then event_properties:user_id::string
    else 'unknown'
end as user_id

-- ✅ SAFE: Use TRY_CAST for uncertain types
try_cast(event_properties:amount as number) as amount_number
```

### Validate VARIANT Structure

```sql
-- Check if VARIANT is an object
select
    event_id,
    event_properties,
    is_object(event_properties) as is_valid_object,
    is_array(event_properties) as is_valid_array,
    typeof(event_properties) as variant_type
from {{ ref('stg_segment__web_events') }}
where not is_object(event_properties)  -- Find malformed events
```

## SQLFluff Compliance

### Formatting FLATTEN Queries

```sql
-- ✅ CORRECT: SQLFluff-compliant FLATTEN syntax
with flattened_data as (

    select
        e.event_id,
        e.user_id,
        f.key as property_name,
        f.value::string as property_value
    from {{ ref('stg_segment__web_events') }} as e,
        lateral flatten(input => e.event_properties) as f
    where f.key in ('contest_id', 'sport', 'device_type')

)

select * from flattened_data
```

### VARIANT Casting Style

```sql
-- ✅ CORRECT: Explicit casting with consistent style
event_properties:user_id::string                 -- Lowercase type
event_properties:amount::number                  -- Lowercase type
event_properties:created_at::timestamp           -- Lowercase type

-- Follow project standards for all semi-structured queries
```

## Testing Semi-Structured Models

```yaml
# models/dwh/staging/analytics/schema.yml
version: 2

models:
  - name: stg_segment__contest_entry_events
    description: "Segment contest entry events with extracted properties"
    columns:
      - name: event_id
        tests:
          - unique
          - not_null

      - name: contest_id
        description: "Extracted from event_properties:contest_id"
        tests:
          - not_null
          - relationships:
              to: ref('dim_contest')
              field: contest_id

      - name: sport
        description: "Extracted from event_properties:sport"
        tests:
          - accepted_values:
              values: ['NFL', 'NBA', 'MLB', 'NHL', 'MMA', 'SOCCER']
```

## When to Use Each Approach

| Scenario | Recommended Approach |
|----------|---------------------|
| Extract 1-5 specific properties | Direct path notation with casting |
| Extract all properties as rows | FLATTEN with lateral join |
| Nested object/array structures | Nested FLATTEN or recursive FLATTEN |
| Build JSON for API export | OBJECT_CONSTRUCT + ARRAY_AGG |
| Aggregate values into arrays | ARRAY_AGG with WITHIN GROUP |
| Frequently-accessed properties | Materialize columns in staging model |
| Ad-hoc analysis | Keep full VARIANT column, query as needed |
| High-volume event processing | Extract to columns + cluster by date |

## Additional Resources

**Snowflake Documentation**:
- [Semi-Structured Data Functions](https://docs.snowflake.com/en/sql-reference/functions-semistructured.html)
- [FLATTEN Function](https://docs.snowflake.com/en/sql-reference/functions/flatten.html)
- [Working with JSON](https://docs.snowflake.com/en/user-guide/querying-semistructured.html)

**Project Integration**:
- Segment events: High-volume JSON processing (`tag:source:segment`)
- API integrations: Partner data ingestion
- Feature flags: Configuration management

---

**Last Updated**: 2025-10-07
**Agent**: snowflake-sql-expert
**Knowledge Category**: Patterns