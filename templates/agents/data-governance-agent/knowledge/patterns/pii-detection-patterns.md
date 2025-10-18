---
title: "PII Detection Patterns"
description: "Automated and manual methods for discovering PII in data warehouse"
category: "patterns"
tags:
  - pii-detection
  - automation
  - data-classification
  - pattern-matching
last_updated: "2025-10-07"
---

# PII Detection Patterns

## Detection Strategy Overview

**Multi-Layered Approach**:

1. **Catalog-Based**: Known PII fields from data dictionary
2. **Pattern-Based**: Regex patterns for common PII formats
3. **ML-Based**: Machine learning models for unstructured PII
4. **Manual Review**: Data steward classification for edge cases

---

## Pattern 1: Catalog-Based Detection

### Known PII Field Catalog

Maintain curated list of PII field names across all sources:

```yaml
# .claude/governance/pii-catalog.yml
pii_field_registry:
  direct_identifiers:
    - email
    - email_address
    - user_email
    - phone
    - phone_number
    - mobile_number
    - first_name
    - last_name
    - full_name
    - display_name
    - ssn
    - social_security_number
    - driver_license
    - passport_number
    - credit_card_number
    - bank_account_number

  quasi_identifiers:
    - user_id
    - customer_id
    - account_id
    - birthdate
    - birth_date
    - date_of_birth
    - dob
    - zip_code
    - postal_code
    - ip_address
    - ip_addr
    - device_id
    - device_identifier
    - mac_address

  sensitive_pii:
    - health_record_id
    - medical_record_number
    - diagnosis_code
    - prescription
    - biometric_hash
    - fingerprint_hash
    - genetic_data
    - sexual_orientation
    - religious_belief
    - political_affiliation
```

### dbt Test: Validate PII Tagging

```sql
-- tests/governance/assert_pii_fields_tagged.sql
-- Ensure all known PII fields have pii:true tag

with pii_columns as (
    select
        table_catalog,
        table_schema,
        table_name,
        column_name
    from {{ target.database }}.information_schema.columns
    where lower(column_name) in (
        'email', 'email_address', 'user_email',
        'phone', 'phone_number', 'mobile_number',
        'first_name', 'last_name', 'full_name',
        'ssn', 'social_security_number',
        'credit_card_number', 'bank_account_number',
        'birthdate', 'birth_date', 'date_of_birth',
        'zip_code', 'postal_code', 'ip_address'
    )
),

dbt_models as (
    select
        database_name,
        schema_name,
        name as model_name,
        tags
    from {{ target.database }}.information_schema.tables
    where table_type = 'BASE TABLE'
)

select
    p.table_schema,
    p.table_name,
    p.column_name,
    m.tags
from pii_columns p
left join dbt_models m
    on p.table_schema = m.schema_name
    and p.table_name = m.model_name
where not array_contains('pii:true'::variant, m.tags)
    or m.tags is null
```

---

## Pattern 2: Regex Pattern Matching

### Python Script for PII Scanning

```python
# scripts/scan_pii.py
"""
Scan Snowflake tables for PII using regex patterns.
Usage: python scan_pii.py --database PROD --schema FINANCE_STAGING
"""

import re
import snowflake.connector
from typing import Dict, List, Set

PII_PATTERNS = {
    'email': r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,7}\b',
    'phone_us': r'\b(?:\+?1[-.\s]?)?(?:\(?\d{3}\)?[-.\s]?)?\d{3}[-.\s]?\d{4}\b',
    'ssn': r'\b\d{3}[-\s]?\d{2}[-\s]?\d{4}\b',
    'credit_card': r'\b(?:\d{4}[-\s]?){3}\d{4}\b',
    'ip_address': r'\b(?:\d{1,3}\.){3}\d{1,3}\b',
    'zip_code': r'\b\d{5}(?:-\d{4})?\b',
    'date_of_birth': r'\b(?:0[1-9]|1[0-2])[/-](?:0[1-9]|[12][0-9]|3[01])[/-](?:19|20)\d{2}\b',
}

def scan_table_for_pii(
    conn: snowflake.connector.SnowflakeConnection,
    database: str,
    schema: str,
    table: str,
    sample_size: int = 100
) -> Dict[str, Set[str]]:
    """
    Scan sample rows from table for PII patterns.
    Returns dict of {column_name: {pii_types_detected}}.
    """
    cursor = conn.cursor()

    # Get column names
    cursor.execute(f"""
        SELECT column_name, data_type
        FROM {database}.information_schema.columns
        WHERE table_schema = '{schema}'
          AND table_name = '{table}'
          AND data_type IN ('VARCHAR', 'TEXT', 'STRING')
    """)
    columns = [row[0] for row in cursor.fetchall()]

    if not columns:
        return {}

    # Sample data
    column_list = ', '.join([f'"{col}"' for col in columns])
    cursor.execute(f"""
        SELECT {column_list}
        FROM {database}.{schema}.{table}
        SAMPLE ({sample_size} ROWS)
    """)
    rows = cursor.fetchall()

    # Scan for PII patterns
    results = {col: set() for col in columns}

    for row in rows:
        for col_idx, value in enumerate(row):
            if value is None:
                continue

            value_str = str(value)
            col_name = columns[col_idx]

            for pii_type, pattern in PII_PATTERNS.items():
                if re.search(pattern, value_str, re.IGNORECASE):
                    results[col_name].add(pii_type)

    # Filter columns with detected PII
    return {col: pii_types for col, pii_types in results.items() if pii_types}

def scan_schema(database: str, schema: str, sample_size: int = 100):
    """Scan all tables in schema for PII."""
    conn = snowflake.connector.connect(
        account=os.getenv('SNOWFLAKE_ACCOUNT'),
        user=os.getenv('SNOWFLAKE_USER'),
        password=os.getenv('SNOWFLAKE_PASSWORD'),
        warehouse=os.getenv('SNOWFLAKE_WAREHOUSE'),
    )

    cursor = conn.cursor()
    cursor.execute(f"""
        SELECT table_name
        FROM {database}.information_schema.tables
        WHERE table_schema = '{schema}'
          AND table_type = 'BASE TABLE'
    """)
    tables = [row[0] for row in cursor.fetchall()]

    print(f"Scanning {len(tables)} tables in {database}.{schema}...")

    all_results = {}
    for table in tables:
        print(f"  Scanning {table}...")
        pii_detected = scan_table_for_pii(conn, database, schema, table, sample_size)
        if pii_detected:
            all_results[table] = pii_detected
            print(f"    ⚠️  PII detected: {pii_detected}")

    # Generate report
    print("\n" + "="*80)
    print(f"PII Detection Report: {database}.{schema}")
    print("="*80)

    for table, columns in all_results.items():
        print(f"\n📊 {table}")
        for col, pii_types in columns.items():
            print(f"  - {col}: {', '.join(pii_types)}")

    conn.close()
    return all_results

if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument('--database', required=True)
    parser.add_argument('--schema', required=True)
    parser.add_argument('--sample-size', type=int, default=100)
    args = parser.parse_args()

    scan_schema(args.database, args.schema, args.sample_size)
```

### Integration with CI/CD

```yaml
# .github/workflows/pii-scan.yml
name: PII Detection Scan

on:
  pull_request:
    paths:
      - 'models/sources/**'
      - 'models/dwh/staging/**'

jobs:
  pii-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'

      - name: Install dependencies
        run: |
          pip install snowflake-connector-python pyyaml

      - name: Scan for PII patterns
        env:
          SNOWFLAKE_ACCOUNT: ${{ secrets.SNOWFLAKE_ACCOUNT }}
          SNOWFLAKE_USER: ${{ secrets.SNOWFLAKE_CI_USER }}
          SNOWFLAKE_PASSWORD: ${{ secrets.SNOWFLAKE_CI_PASSWORD }}
          SNOWFLAKE_WAREHOUSE: BUILD_WH
        run: |
          python scripts/scan_pii.py --database BUILD --schema FINANCE_STAGING

      - name: Comment on PR with results
        if: always()
        uses: actions/github-script@v6
        with:
          script: |
            const fs = require('fs');
            const report = fs.readFileSync('pii_report.txt', 'utf8');
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `## PII Detection Report\n\n\`\`\`\n${report}\n\`\`\``
            });
```

---

## Pattern 3: ML-Based PII Detection

### Using NLP for Unstructured Text

For free-text fields (e.g., Intercom chat logs, support tickets):

```python
# scripts/ml_pii_detector.py
"""
Machine learning-based PII detection for unstructured text.
Uses spaCy Named Entity Recognition (NER) for detecting names, locations, etc.
"""

import spacy
from typing import List, Dict

# Load pre-trained model
nlp = spacy.load("en_core_web_sm")

PII_ENTITY_TYPES = {
    'PERSON': 'name',
    'GPE': 'location',  # Geopolitical entity (city, country)
    'DATE': 'date_of_birth',  # Potential birthdate
    'CARDINAL': 'potential_id',  # Numbers (could be IDs)
    'PHONE': 'phone_number',  # Custom pattern
    'EMAIL': 'email',  # Custom pattern
}

def detect_pii_in_text(text: str) -> Dict[str, List[str]]:
    """
    Detect PII entities in unstructured text.
    Returns dict of {pii_type: [detected_values]}.
    """
    doc = nlp(text)
    pii_found = {}

    # NER-based detection
    for ent in doc.ents:
        if ent.label_ in PII_ENTITY_TYPES:
            pii_type = PII_ENTITY_TYPES[ent.label_]
            if pii_type not in pii_found:
                pii_found[pii_type] = []
            pii_found[pii_type].append(ent.text)

    # Regex-based augmentation (email, phone)
    import re
    if re.search(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,7}\b', text):
        pii_found['email'] = re.findall(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,7}\b', text)

    if re.search(r'\b\d{3}[-.\s]?\d{3}[-.\s]?\d{4}\b', text):
        pii_found['phone_number'] = re.findall(r'\b\d{3}[-.\s]?\d{3}[-.\s]?\d{4}\b', text)

    return pii_found

# Example usage
chat_log = """
Hi, my name is John Smith. I'm having trouble with my account.
My email is john.smith@example.com and my phone is 555-123-4567.
I was born on 03/15/1985 and live in San Francisco.
"""

pii_detected = detect_pii_in_text(chat_log)
print(pii_detected)
# Output:
# {
#   'name': ['John Smith'],
#   'email': ['john.smith@example.com'],
#   'phone_number': ['555-123-4567'],
#   'date_of_birth': ['03/15/1985'],
#   'location': ['San Francisco']
# }
```

### Snowflake UDF for ML-Based Detection

```sql
-- Create Python UDF for PII detection
create or replace function detect_pii_ml(text string)
returns variant
language python
runtime_version = '3.8'
packages = ('spacy==3.5.0')
handler = 'detect_pii'
as $$
import spacy

nlp = spacy.load("en_core_web_sm")

def detect_pii(text):
    doc = nlp(text)
    pii_entities = []

    for ent in doc.ents:
        if ent.label_ in ['PERSON', 'GPE', 'DATE']:
            pii_entities.append({
                'text': ent.text,
                'label': ent.label_,
                'start': ent.start_char,
                'end': ent.end_char
            })

    return pii_entities
$$;

-- Usage: Scan support chat logs
select
    conversation_id,
    message_text,
    detect_pii_ml(message_text) as pii_detected
from intercom.conversations
where array_size(detect_pii_ml(message_text)) > 0
limit 10;
```

---

## Pattern 4: Snowflake Information Schema Queries

### Find Columns with Suspicious Names

```sql
-- Query: Find columns that might contain PII based on name
select
    table_catalog,
    table_schema,
    table_name,
    column_name,
    data_type,
    case
        when lower(column_name) like '%email%' then 'EMAIL'
        when lower(column_name) like '%phone%' then 'PHONE'
        when lower(column_name) like '%ssn%' then 'SSN'
        when lower(column_name) like '%name%' and lower(column_name) not like '%username%' then 'NAME'
        when lower(column_name) like '%address%' then 'ADDRESS'
        when lower(column_name) like '%birth%' then 'BIRTHDATE'
        when lower(column_name) like '%zip%' or lower(column_name) like '%postal%' then 'ZIP_CODE'
        when lower(column_name) like '%ip_%' or column_name = 'ip' then 'IP_ADDRESS'
        when lower(column_name) like '%credit%card%' then 'CREDIT_CARD'
        when lower(column_name) like '%account%number%' then 'ACCOUNT_NUMBER'
        else 'UNKNOWN'
    end as suspected_pii_type
from prod.information_schema.columns
where table_schema not in ('INFORMATION_SCHEMA', 'ACCOUNT_USAGE')
    and (
        lower(column_name) like '%email%'
        or lower(column_name) like '%phone%'
        or lower(column_name) like '%ssn%'
        or lower(column_name) like '%name%'
        or lower(column_name) like '%address%'
        or lower(column_name) like '%birth%'
        or lower(column_name) like '%zip%'
        or lower(column_name) like '%postal%'
        or lower(column_name) like '%ip_%'
        or lower(column_name) like '%credit%'
        or lower(column_name) like '%account%number%'
    )
order by table_schema, table_name, column_name;
```

### Cross-Reference with dbt Tags

```sql
-- Query: Find PII columns missing dbt pii:true tag
with suspected_pii_columns as (
    select
        table_catalog,
        table_schema,
        table_name,
        column_name
    from prod.information_schema.columns
    where lower(column_name) in (
        'email', 'phone', 'first_name', 'last_name',
        'ssn', 'birthdate', 'zip_code', 'ip_address'
    )
),

dbt_model_tags as (
    select
        database_name,
        schema_name,
        name as model_name,
        parse_json(comment):tags as tags
    from prod.information_schema.tables
    where comment is not null
)

select
    p.table_schema,
    p.table_name,
    p.column_name,
    t.tags
from suspected_pii_columns p
left join dbt_model_tags t
    on p.table_schema = t.schema_name
    and p.table_name = t.model_name
where not array_contains('pii:true'::variant, t.tags)
    or t.tags is null;
```

---

## Pattern 5: Data Profiling for Quasi-Identifiers

### Check for Low-Cardinality Combinations (Re-identification Risk)

```sql
-- Query: Identify quasi-identifier combinations with low uniqueness (k < 5)
-- High risk of re-identification if k-anonymity violated

with user_demographics as (
    select
        left(zip_code, 3) as zip_prefix,
        date_trunc('year', birthdate) as birth_year,
        gender,
        count(*) as user_count
    from prod.finance.dim_user
    group by zip_prefix, birth_year, gender
)

select
    zip_prefix,
    birth_year,
    gender,
    user_count,
    case
        when user_count = 1 then 'CRITICAL (k=1, unique individual)'
        when user_count < 5 then 'HIGH (k<5, re-identification likely)'
        when user_count < 10 then 'MEDIUM (k<10, some risk)'
        else 'LOW (k>=10, acceptable)'
    end as re_identification_risk
from user_demographics
where user_count < 10  -- Flag risky combinations
order by user_count asc;
```

### Snowflake Query for Statistical Disclosure Analysis

```sql
-- Query: Detect rare attribute combinations (statistical disclosure risk)
select
    state,
    age_range,
    occupation,
    count(*) as frequency,
    count(*) * 1.0 / sum(count(*)) over () as proportion
from prod.analytics.mart_user_demographics
group by state, age_range, occupation
having count(*) < 5  -- Small cell suppression threshold
order by frequency asc;
```

---

## Pattern 6: Pre-Commit Hook for PII Validation

### Git Pre-Commit Hook

```bash
#!/bin/bash
# .git/hooks/pre-commit
# Validate PII tagging before commit

echo "Running PII validation checks..."

# Check for new staging models without PII tags
NEW_STAGING_MODELS=$(git diff --cached --name-only | grep 'models/dwh/staging/.*\.sql$')

for MODEL in $NEW_STAGING_MODELS; do
    # Check if model config has pii tag
    if ! grep -q "pii:" "$MODEL"; then
        echo "❌ ERROR: Staging model missing PII tag: $MODEL"
        echo "   Add {{ config(tags=['pii:true']) }} or {{ config(tags=['pii:false']) }}"
        exit 1
    fi
done

# Check for known PII field names in new models
if git diff --cached | grep -E -i '(email|phone|ssn|first_name|last_name|credit_card)' > /dev/null; then
    echo "⚠️  WARNING: Detected potential PII field names in changes"
    echo "   Review: email, phone, ssn, first_name, last_name, credit_card"
    echo "   Ensure proper classification and masking applied"
fi

echo "✅ PII validation passed"
```

---

## Pattern 7: Automated PII Catalog Maintenance

### dbt Macro: Generate PII Catalog

```sql
-- macros/generate_pii_catalog.sql
{% macro generate_pii_catalog() %}
    {% set pii_query %}
        select
            table_schema,
            table_name,
            column_name,
            data_type,
            case
                when lower(column_name) in ('email', 'phone', 'ssn', 'credit_card_number') then 'DIRECT_PII'
                when lower(column_name) in ('user_id', 'birthdate', 'zip_code', 'ip_address') then 'QUASI_IDENTIFIER'
                else 'UNKNOWN'
            end as pii_type
        from {{ target.database }}.information_schema.columns
        where (
            lower(column_name) like '%email%'
            or lower(column_name) like '%phone%'
            or lower(column_name) like '%ssn%'
            or lower(column_name) like '%name%'
            or lower(column_name) like '%birth%'
            or lower(column_name) like '%zip%'
            or lower(column_name) like '%ip%'
        )
        order by table_schema, table_name, column_name
    {% endset %}

    {% set results = run_query(pii_query) %}

    {% if execute %}
        {{ log("PII Catalog Generation", info=True) }}
        {{ log("="*80, info=True) }}
        {% for row in results %}
            {{ log(row['table_schema'] ~ "." ~ row['table_name'] ~ "." ~ row['column_name'] ~ " (" ~ row['pii_type'] ~ ")", info=True) }}
        {% endfor %}
    {% endif %}
{% endmacro %}
```

**Usage**:

```bash
dbt run-operation generate_pii_catalog --target prod
```

---

## Best Practices Summary

**1. Layered Detection**:

- Start with catalog-based (known fields)
- Add pattern-based (regex) for coverage
- Use ML-based for unstructured text
- Manual review for final validation

**2. Continuous Monitoring**:

- Pre-commit hooks for new models
- CI/CD scans for new data sources
- Quarterly catalog reviews

**3. Documentation**:

- Maintain central PII catalog (.claude/governance/pii-catalog.yml)
- Tag all PII models in dbt (pii:true, pii_type:*)
- Document exceptions and edge cases

**4. Validation**:

- dbt tests enforce tagging completeness
- Snowflake queries validate masking policies
- Regular re-identification risk assessments

---

## Next Steps

1. **Read**: `data-masking-strategies.md` for PII protection implementation
2. **Read**: `retention-policy-implementation.md` for automated data lifecycle
3. **Implement**: Run PII scan on production schemas (`scan_pii.py`)
4. **Coordinate**: Work with architect to design PII-aware dimensional models
