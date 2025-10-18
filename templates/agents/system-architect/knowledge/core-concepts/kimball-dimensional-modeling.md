# Kimball Dimensional Modeling

Kimball dimensional modeling is a data warehouse design technique that optimizes data for analytics and business intelligence through star schema fact and dimension tables.

## Overview

Created by Ralph Kimball, dimensional modeling organizes data into **facts** (business measurements) and **dimensions** (contextual attributes) to make data easy to understand and query efficiently.

**Core Principle**: Design data the way business people think about it, not the way source systems store it.

## Key Concepts

### Star Schema

The fundamental pattern in dimensional modeling:

```text
       ┌─────────────┐
       │  dim_date   │
       └──────┬──────┘
              │
       ┌─────────────┐      ┌─────────────┐
       │dim_customer │──────│ fct_orders  │──────│ dim_product │
       └─────────────┘      └──────┬──────┘      └─────────────┘
                                   │
                            ┌──────────────┐
                            │ dim_location │
                            └──────────────┘
```

**Characteristics**:

- Fact table in center (contains measures)
- Dimension tables surrounding (contain attributes)
- Simple structure (one level of joins)
- Optimized for BI tool queries

### Snowflake Schema (Avoid in most cases)

Normalized dimension tables:

```text
       ┌─────────────┐      ┌──────────────┐
       │ dim_product │──────│ dim_category │
       └──────┬──────┘      └──────────────┘
              │
       ┌─────────────┐
       │ fct_orders  │
       └──────┬──────┘
              │
       ┌──────────────┐      ┌───────────┐
       │ dim_customer │──────│ dim_city  │──────┌──────────┐
       └──────────────┘      └───────────┘      │ dim_state│
                                                 └──────────┘
```

**Why to avoid**:

- More complex queries (multiple joins)
- Slower BI tool performance
- Harder for analysts to understand
- Minimal storage savings in modern data warehouses

**When to use**: Only if storage costs are prohibitive (rare with cloud warehouses)

## Fact Tables

### Definition

Fact tables store **measurements** of business events:

- Numeric values (measures)
- Foreign keys to dimensions
- Grain (level of detail)

### Types of Facts

#### Transaction Facts

**Definition**: One row per business event

**Examples**:

- Orders (one row per order)
- Payments (one row per payment)
- Page views (one row per view)
- API calls (one row per call)

**Characteristics**:

- Most common fact type
- Additive measures (can sum across all dimensions)
- Grain: Individual transaction

**Example**:

```sql
CREATE TABLE marts.fct_orders (
    -- Surrogate key
    order_key NUMBER PRIMARY KEY,

    -- Foreign keys to dimensions
    customer_key NUMBER,
    product_key NUMBER,
    date_key NUMBER,
    location_key NUMBER,

    -- Degenerate dimensions (natural keys from source)
    order_id VARCHAR,

    -- Measures (facts)
    order_amount DECIMAL(10,2),
    quantity NUMBER,
    discount_amount DECIMAL(10,2),
    tax_amount DECIMAL(10,2),
    shipping_cost DECIMAL(10,2),

    -- Metadata
    created_at TIMESTAMP,
    loaded_at TIMESTAMP
);
```

#### Periodic Snapshot Facts

**Definition**: Measurements at regular intervals

**Examples**:

- Account balances (daily snapshot)
- Inventory levels (daily snapshot)
- System metrics (hourly snapshot)
- User counts (monthly snapshot)

**Characteristics**:

- Semi-additive measures (can sum across some dimensions but not time)
- Grain: Time period (daily, monthly, etc.)
- Useful for trend analysis

**Example**:

```sql
CREATE TABLE marts.fct_account_balances_daily (
    -- Surrogate key
    balance_key NUMBER PRIMARY KEY,

    -- Foreign keys
    account_key NUMBER,
    date_key NUMBER,

    -- Degenerate dimensions
    account_id VARCHAR,

    -- Measures (semi-additive - don't sum across dates)
    ending_balance DECIMAL(10,2),
    available_balance DECIMAL(10,2),

    -- Additive measures (can sum)
    deposits_today DECIMAL(10,2),
    withdrawals_today DECIMAL(10,2),
    transaction_count NUMBER,

    -- Metadata
    snapshot_date DATE,
    loaded_at TIMESTAMP
);
```

#### Accumulating Snapshot Facts

**Definition**: Track the lifecycle of a process

**Examples**:

- Order fulfillment pipeline (ordered → paid → shipped → delivered)
- Lead pipeline (lead → qualified → demo → closed)
- Support tickets (opened → assigned → resolved → closed)

**Characteristics**:

- Multiple date foreign keys (one per milestone)
- Rows updated as process progresses
- Lag calculations between milestones

**Example**:

```sql
CREATE TABLE marts.fct_order_fulfillment (
    -- Surrogate key
    fulfillment_key NUMBER PRIMARY KEY,

    -- Foreign keys to dimensions
    customer_key NUMBER,
    product_key NUMBER,

    -- Foreign keys to date dimension (one per milestone)
    order_date_key NUMBER,
    payment_date_key NUMBER,
    ship_date_key NUMBER,
    delivery_date_key NUMBER,

    -- Degenerate dimensions
    order_id VARCHAR,

    -- Measures (lag in days between milestones)
    payment_lag_days NUMBER,      -- payment_date - order_date
    shipping_lag_days NUMBER,     -- ship_date - payment_date
    delivery_lag_days NUMBER,     -- delivery_date - ship_date
    total_fulfillment_days NUMBER, -- delivery_date - order_date

    -- Metadata
    loaded_at TIMESTAMP,
    updated_at TIMESTAMP
);
```

### Fact Table Grain

**Grain** = The level of detail represented by each row

**Critical**: Document grain explicitly in model YAML

**Examples**:

- "One row per order" (transaction grain)
- "One row per order line item" (line item grain)
- "One row per customer per day" (daily snapshot grain)
- "One row per customer per month" (monthly summary grain)

**Rule**: All measures must be consistent with the grain

**Anti-pattern**:

```sql
-- BAD: Mixing grains
SELECT
    customer_id,
    order_date,
    SUM(order_amount) AS total_orders,  -- Order grain
    COUNT(DISTINCT customer_id) AS customer_count  -- Customer grain (doesn't match!)
FROM orders
GROUP BY customer_id, order_date
```

**Correct**:

```sql
-- GOOD: Consistent grain (one row per customer per day)
SELECT
    customer_id,
    order_date,
    SUM(order_amount) AS total_orders,
    COUNT(DISTINCT order_id) AS order_count
FROM orders
GROUP BY customer_id, order_date
```

### Measure Types

#### Additive Measures

**Definition**: Can be summed across all dimensions

**Examples**:

- order_amount (can sum across customers, products, dates)
- quantity (can sum across all dimensions)
- revenue (can sum across all dimensions)

**Usage**: Most common, most flexible

#### Semi-Additive Measures

**Definition**: Can be summed across some dimensions but not all (usually not time)

**Examples**:

- account_balance (can sum across accounts, but NOT across dates)
- inventory_level (can sum across products, but NOT across dates)
- headcount (can sum across departments, but NOT across dates)

**Usage**: Common in snapshot fact tables

**Query pattern**:

```sql
-- WRONG: Summing balances across dates double-counts
SELECT SUM(ending_balance)
FROM fct_account_balances_daily
WHERE date_key BETWEEN 20250101 AND 20250131;

-- RIGHT: Use MAX or AVG for latest snapshot
SELECT SUM(ending_balance)
FROM fct_account_balances_daily
WHERE date_key = 20250131;  -- Latest snapshot only
```

#### Non-Additive Measures

**Definition**: Cannot be summed across any dimension

**Examples**:

- percentages (average_discount_rate)
- ratios (profit_margin_percent)
- rates (conversion_rate)
- unit prices (price_per_unit)

**Usage**: Use AVG or weighted averages, not SUM

## Dimension Tables

### Definition

Dimension tables provide **context** for facts:

- Descriptive attributes
- Surrogate keys (not natural keys)
- Denormalized for performance
- Relatively small (compared to facts)

### Dimension Characteristics

#### Surrogate Keys

**Definition**: Artificial keys assigned by the warehouse (not from source systems)

**Why**:

- Handle slowly changing dimensions (SCD Type 2)
- Avoid natural key collisions across source systems
- Improve join performance
- Handle missing/unknown dimension values

**Example**:

```sql
CREATE TABLE marts.dim_customers (
    customer_key NUMBER PRIMARY KEY,  -- Surrogate key (assigned by warehouse)
    customer_id VARCHAR,               -- Natural key (from source system)
    customer_name VARCHAR,
    email VARCHAR,
    segment VARCHAR,

    -- SCD Type 2 fields
    valid_from TIMESTAMP,
    valid_to TIMESTAMP,
    is_current BOOLEAN
);
```

**Generate surrogate keys in dbt**:

```sql
{{ dbt_utils.generate_surrogate_key(['customer_id', 'valid_from']) }} AS customer_key
```

#### Denormalization

**Principle**: Flatten hierarchies into dimension tables

**Example**:

**Normalized (source system)**:

```text
customer → city → state → country → region
```

**Denormalized (dimension table)**:

```sql
CREATE TABLE marts.dim_customers (
    customer_key NUMBER PRIMARY KEY,
    customer_id VARCHAR,
    customer_name VARCHAR,

    -- All levels of geography denormalized
    city_name VARCHAR,
    state_code VARCHAR,
    state_name VARCHAR,
    country_code VARCHAR,
    country_name VARCHAR,
    region_name VARCHAR
);
```

**Benefits**:

- Simpler queries (one join instead of five)
- Faster query performance
- Easier for analysts

**Trade-offs**:

- More storage (repeated city/state/country names)
- Updates require dimension updates (if city changes state, update all customers)

### Slowly Changing Dimensions (SCD)

Dimensions change over time. SCD patterns handle historical tracking.

#### Type 1: Overwrite (No History)

**When to use**: Don't need history, or changes are corrections

**Example**: Customer email address (only care about current)

**Implementation**:

```sql
-- Update in place (no history)
UPDATE dim_customers
SET email = 'newemail@example.com'
WHERE customer_id = '12345';
```

**In dbt**: Use regular `table` materialization with merge

#### Type 2: Add Row (Full History) ← Most Common

**When to use**: Need full history of changes

**Example**: Customer segment (want to analyze how segment changes affect behavior)

**Implementation**:

```sql
-- Close current row
UPDATE dim_customers
SET valid_to = CURRENT_TIMESTAMP, is_current = FALSE
WHERE customer_id = '12345' AND is_current = TRUE;

-- Insert new row
INSERT INTO dim_customers (customer_key, customer_id, customer_name, segment, valid_from, is_current)
VALUES (999, '12345', 'John Doe', 'PREMIUM', CURRENT_TIMESTAMP, TRUE);
```

**In dbt**: Use `snapshot` materialization

```sql
{% snapshot dim_customers_snapshot %}

{{
    config(
        target_schema='snapshots',
        unique_key='customer_id',
        strategy='timestamp',
        updated_at='updated_at'
    )
}}

SELECT * FROM {{ ref('stg_salesforce__accounts') }}

{% endsnapshot %}
```

**Querying SCD Type 2**:

```sql
-- Current customer segments
SELECT customer_id, segment
FROM dim_customers
WHERE is_current = TRUE;

-- Customer segment on a specific date
SELECT customer_id, segment
FROM dim_customers
WHERE '2025-01-15' BETWEEN valid_from AND COALESCE(valid_to, '9999-12-31');

-- Customer segment history
SELECT customer_id, segment, valid_from, valid_to
FROM dim_customers
WHERE customer_id = '12345'
ORDER BY valid_from;
```

#### Type 3: Add Column (Limited History)

**When to use**: Only need current and previous value

**Example**: Customer tier (current and previous only)

**Implementation**:

```sql
ALTER TABLE dim_customers ADD COLUMN previous_tier VARCHAR;

UPDATE dim_customers
SET previous_tier = current_tier,
    current_tier = 'GOLD'
WHERE customer_id = '12345';
```

**Rare in dbt**: SCD Type 2 is more flexible, storage is cheap

### Special Dimension Types

#### Conformed Dimensions

**Definition**: Shared across multiple fact tables

**Examples**:

- dim_date (used by all fact tables)
- dim_customer (used by fct_orders, fct_payments, fct_support_tickets)
- dim_product (used by fct_orders, fct_returns, fct_inventory)

**Benefit**: Consistent definitions enable cross-fact analysis

**Example**:

```sql
-- Orders and returns both use dim_customer
SELECT
    c.customer_name,
    SUM(o.order_amount) AS total_orders,
    SUM(r.return_amount) AS total_returns
FROM fct_orders o
JOIN dim_customer c ON o.customer_key = c.customer_key
LEFT JOIN fct_returns r ON r.customer_key = c.customer_key
GROUP BY c.customer_name;
```

#### Role-Playing Dimensions

**Definition**: Same dimension used in multiple ways

**Example**: dim_date used as order_date, ship_date, delivery_date

**Implementation**:

```sql
-- Fact table has multiple foreign keys to same dimension
CREATE TABLE fct_orders (
    order_key NUMBER PRIMARY KEY,
    order_date_key NUMBER,      -- FK to dim_date
    ship_date_key NUMBER,       -- FK to dim_date (role-playing)
    delivery_date_key NUMBER,   -- FK to dim_date (role-playing)
    ...
);
```

**Querying**:

```sql
SELECT
    order_dates.month_name AS order_month,
    ship_dates.month_name AS ship_month,
    COUNT(*) AS order_count
FROM fct_orders o
JOIN dim_date order_dates ON o.order_date_key = order_dates.date_key
JOIN dim_date ship_dates ON o.ship_date_key = ship_dates.date_key
GROUP BY 1, 2;
```

#### Junk Dimensions

**Definition**: Combine low-cardinality flags/indicators into one dimension

**When to use**: Avoid polluting fact table with many flag columns

**Example**:

Instead of:

```sql
-- BAD: Many flag columns in fact table
CREATE TABLE fct_orders (
    order_key NUMBER,
    is_gift_wrapped BOOLEAN,
    is_expedited BOOLEAN,
    is_international BOOLEAN,
    is_first_purchase BOOLEAN,
    ...
);
```

Use junk dimension:

```sql
-- GOOD: Junk dimension for flags
CREATE TABLE dim_order_flags (
    order_flag_key NUMBER PRIMARY KEY,
    is_gift_wrapped BOOLEAN,
    is_expedited BOOLEAN,
    is_international BOOLEAN,
    is_first_purchase BOOLEAN
);

CREATE TABLE fct_orders (
    order_key NUMBER,
    order_flag_key NUMBER,  -- FK to junk dimension
    ...
);
```

**Generate in dbt**:

```sql
-- Pre-generate all combinations
WITH flag_combinations AS (
    SELECT
        gift.value AS is_gift_wrapped,
        expedited.value AS is_expedited,
        international.value AS is_international,
        first.value AS is_first_purchase
    FROM (SELECT TRUE AS value UNION ALL SELECT FALSE) gift
    CROSS JOIN (SELECT TRUE AS value UNION ALL SELECT FALSE) expedited
    CROSS JOIN (SELECT TRUE AS value UNION ALL SELECT FALSE) international
    CROSS JOIN (SELECT TRUE AS value UNION ALL SELECT FALSE) first
)
SELECT
    {{ dbt_utils.generate_surrogate_key(['is_gift_wrapped', 'is_expedited', 'is_international', 'is_first_purchase']) }} AS order_flag_key,
    *
FROM flag_combinations;
```

#### Degenerate Dimensions

**Definition**: Dimension key stored directly in fact table (not in separate dimension)

**When to use**: High-cardinality natural keys with no attributes

**Examples**:

- order_id (unique per order, no useful attributes)
- transaction_id
- invoice_number

**Implementation**:

```sql
CREATE TABLE fct_orders (
    order_key NUMBER PRIMARY KEY,  -- Surrogate key
    customer_key NUMBER,            -- FK to dimension
    product_key NUMBER,             -- FK to dimension

    order_id VARCHAR,               -- Degenerate dimension (no FK, no dim table)

    order_amount DECIMAL(10,2)
);
```

**Why**: Creating a dimension with only one column (order_id) is wasteful

## Date Dimension

**Special case**: Always create a date dimension

### Why Date Dimension?

- Pre-calculate attributes (day_of_week, is_weekend, fiscal_quarter)
- Consistent date logic across all fact tables
- Enable date-based filtering and grouping
- Support fiscal calendars

### Example Date Dimension

```sql
CREATE TABLE marts.dim_date (
    date_key NUMBER PRIMARY KEY,        -- 20250115
    date_value DATE,                    -- 2025-01-15

    -- Day attributes
    day_of_week NUMBER,                 -- 3 (Wednesday)
    day_name VARCHAR,                   -- 'Wednesday'
    day_of_month NUMBER,                -- 15
    day_of_year NUMBER,                 -- 15

    -- Week attributes
    week_of_year NUMBER,                -- 3
    week_start_date DATE,               -- 2025-01-13
    week_end_date DATE,                 -- 2025-01-19

    -- Month attributes
    month_number NUMBER,                -- 1
    month_name VARCHAR,                 -- 'January'
    month_abbr VARCHAR,                 -- 'Jan'
    first_day_of_month DATE,            -- 2025-01-01
    last_day_of_month DATE,             -- 2025-01-31

    -- Quarter attributes
    quarter_number NUMBER,              -- 1
    quarter_name VARCHAR,               -- 'Q1 2025'
    first_day_of_quarter DATE,          -- 2025-01-01
    last_day_of_quarter DATE,           -- 2025-03-31

    -- Year attributes
    year_number NUMBER,                 -- 2025

    -- Fiscal calendar (if different from calendar year)
    fiscal_month_number NUMBER,         -- 4 (if fiscal year starts October)
    fiscal_quarter_number NUMBER,       -- 2
    fiscal_year_number NUMBER,          -- 2025

    -- Flags
    is_weekend BOOLEAN,                 -- FALSE
    is_holiday BOOLEAN,                 -- FALSE
    holiday_name VARCHAR,               -- NULL
    is_business_day BOOLEAN             -- TRUE
);
```

### Generate Date Dimension in dbt

Use `dbt_utils.date_spine`:

```sql
{{ config(materialized='table') }}

WITH date_spine AS (
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2020-01-01' as date)",
        end_date="cast('2030-12-31' as date)"
    )
    }}
),

date_dimension AS (
    SELECT
        TO_NUMBER(TO_CHAR(date_day, 'YYYYMMDD')) AS date_key,
        date_day AS date_value,

        DAYOFWEEK(date_day) AS day_of_week,
        DAYNAME(date_day) AS day_name,
        DAY(date_day) AS day_of_month,
        DAYOFYEAR(date_day) AS day_of_year,

        WEEKOFYEAR(date_day) AS week_of_year,
        DATE_TRUNC('week', date_day) AS week_start_date,

        MONTH(date_day) AS month_number,
        MONTHNAME(date_day) AS month_name,

        QUARTER(date_day) AS quarter_number,
        DATE_TRUNC('quarter', date_day) AS first_day_of_quarter,

        YEAR(date_day) AS year_number,

        DAYOFWEEK(date_day) IN (0, 6) AS is_weekend
    FROM date_spine
)

SELECT * FROM date_dimension;
```

## Dimensional Modeling Process

### Step 1: Select Business Process

**Question**: What business activity are we measuring?

**Examples**:

- Order processing
- Customer support tickets
- Website analytics
- Financial transactions

**Outcome**: One fact table per business process

### Step 2: Declare Grain

**Question**: What does one row represent?

**Examples**:

- "One row per order"
- "One row per order line item"
- "One row per customer per day"

**Critical**: Document grain explicitly

### Step 3: Identify Dimensions

**Question**: How do we want to analyze this business process?

**Think**: Who, what, when, where, why, how

**Examples** (for orders):

- **Who**: Customer (dim_customer)
- **What**: Product (dim_product)
- **When**: Order date (dim_date)
- **Where**: Location (dim_location)
- **How**: Order channel (dim_channel)

**Outcome**: List of dimension tables

### Step 4: Identify Facts

**Question**: What are we measuring?

**Must be**: Numeric, consistent with grain

**Examples** (for orders):

- order_amount (additive)
- quantity (additive)
- discount_amount (additive)
- tax_amount (additive)

**Outcome**: List of measures in fact table

## Best Practices

### Do

- **Document grain explicitly** in model YAML
- **Use surrogate keys** for dimensions
- **Denormalize dimensions** for query performance
- **Create date dimension** for every project
- **Use SCD Type 2** for tracking important changes
- **Validate grain** (ensure all measures are consistent)

### Don't

- **Don't use natural keys** as primary keys (use surrogates)
- **Don't normalize dimensions** (avoid snowflake schema)
- **Don't mix grains** in one fact table
- **Don't put low-cardinality attributes** in fact tables (use dimensions)
- **Don't update fact tables** (facts are immutable, dimensions change)

## Common Mistakes

### Mistake 1: Wrong Grain

**Problem**: Mixing order-level and line-item-level measures

**Fix**: Choose one grain and stick to it

### Mistake 2: Natural Keys as Primary Keys

**Problem**: Using customer_id from source system as primary key

**Fix**: Use surrogate keys, store natural key as attribute

### Mistake 3: Normalized Dimensions

**Problem**: Separate tables for city, state, country

**Fix**: Denormalize into dim_customer

### Mistake 4: No Date Dimension

**Problem**: Using raw DATE columns instead of dim_date

**Fix**: Always create dim_date with pre-calculated attributes

## Further Reading

- **The Data Warehouse Toolkit** by Ralph Kimball
- **dbt Dimensional Modeling Guide**: <https://docs.getdbt.com/guides/best-practices/how-we-structure/4-marts>
- **Kimball Group**: <https://www.kimballgroup.com/>

## Version History

**v1.0** - 2025-10-15

- Initial Kimball dimensional modeling documentation
- Fact and dimension patterns
- SCD types and examples
- Best practices and common mistakes
