---
title: "API Security Patterns"
description: "OAuth 2.0, JWT, API keys, rate limiting, and authentication patterns for data platform APIs"
category: "core-concepts"
tags:
  - api-security
  - oauth
  - jwt
  - authentication
  - rate-limiting
last_updated: "2025-10-07"
---

# API Security Patterns

Comprehensive guide to API security patterns including OAuth 2.0, JWT tokens, API keys, rate limiting, and authentication methods for data platform APIs (Metabase, Airbyte, dbt Cloud, Snowflake).

## API Security Fundamentals

### Security Goals

1. **Authentication**: Verify the identity of API clients (who are you?)
2. **Authorization**: Verify permissions to access resources (what can you do?)
3. **Confidentiality**: Protect data in transit (TLS encryption)
4. **Integrity**: Detect tampering with API requests/responses (HMAC signatures)
5. **Availability**: Prevent abuse and denial-of-service (rate limiting)

### Authentication Methods

- **API Keys**: Simple static tokens for service-to-service authentication
- **OAuth 2.0**: Delegated authorization with access tokens
- **JWT (JSON Web Tokens)**: Self-contained tokens with claims
- **mTLS (Mutual TLS)**: Certificate-based authentication for high-security environments
- **SAML 2.0**: Enterprise SSO for web applications

## OAuth 2.0

### OAuth 2.0 Fundamentals
OAuth 2.0 is an authorization framework that enables third-party applications to obtain limited access to resources without exposing user credentials.

**Key Components**:

1. **Resource Owner**: User who owns the data (e.g., Snowflake user)
2. **Client**: Application requesting access (e.g., dbt Cloud, Metabase)
3. **Authorization Server**: Issues access tokens (e.g., Okta, Auth0, Snowflake OAuth)
4. **Resource Server**: API that validates tokens and serves data (e.g., Snowflake API)

### OAuth 2.0 Grant Types

#### Authorization Code Flow (User Authentication)

```text
User → Client: Click "Login with Snowflake"
Client → Authorization Server: Redirect to /authorize?client_id=...&redirect_uri=...&response_type=code
User → Authorization Server: Enter username/password (+ MFA)
Authorization Server → Client: Redirect to callback with authorization code
Client → Authorization Server: POST /token with authorization code + client_secret
Authorization Server → Client: Return access_token + refresh_token
Client → Resource Server: API request with Authorization: Bearer <access_token>
```

**Example: Metabase OAuth with Okta**

```bash
# Step 1: User clicks "Sign in with Okta" in Metabase
# Step 2: Metabase redirects to Okta authorization endpoint
https://splash.okta.com/oauth2/v1/authorize?
  client_id=0oa123abc456
  &redirect_uri=https://metabase.splash.com/auth/okta/callback
  &response_type=code
  &scope=openid%20email%20profile
  &state=random_csrf_token

# Step 3: User authenticates with Okta (username/password + MFA)

# Step 4: Okta redirects back to Metabase with authorization code
https://metabase.splash.com/auth/okta/callback?
  code=abc123def456
  &state=random_csrf_token

# Step 5: Metabase exchanges code for access token
curl -X POST https://splash.okta.com/oauth2/v1/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=authorization_code" \
  -d "code=abc123def456" \
  -d "redirect_uri=https://metabase.splash.com/auth/okta/callback" \
  -d "client_id=0oa123abc456" \
  -d "client_secret=secret123"

# Response:
{
  "access_token": "eyJraWQiOiJT...",
  "token_type": "Bearer",
  "expires_in": 3600,
  "refresh_token": "v1.MjFiYTU...",
  "id_token": "eyJraWQiOiJT...",
  "scope": "openid email profile"
}

# Step 6: Metabase uses access_token to fetch user profile
curl https://splash.okta.com/oauth2/v1/userinfo \
  -H "Authorization: Bearer eyJraWQiOiJT..."

# Step 7: Metabase creates session for user
```

#### Client Credentials Flow (Service-to-Service)

```text
Client → Authorization Server: POST /token with client_id + client_secret
Authorization Server → Client: Return access_token
Client → Resource Server: API request with Authorization: Bearer <access_token>
```

**Example: dbt Cloud to Snowflake OAuth**

```bash
# dbt Cloud service account authenticates with Snowflake OAuth
curl -X POST https://xyz12345.snowflakecomputing.com/oauth/token-request \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=ABC123DEF456" \
  -d "client_secret=secret789" \
  -d "scope=session:role:DBT_SERVICE_ACCOUNT"

# Response:
{
  "access_token": "ver:3-hint:12345-ETMsDgAAAY...",
  "token_type": "Bearer",
  "expires_in": 600,
  "refresh_token": null
}

# dbt Cloud uses access_token for Snowflake queries
# Token expires in 10 minutes (600 seconds), must refresh before expiration
```

### Snowflake OAuth Configuration

#### Create OAuth Integration
```sql
-- Create OAuth integration for dbt Cloud (client credentials flow)
CREATE SECURITY INTEGRATION DBT_CLOUD_OAUTH
  TYPE = OAUTH
  ENABLED = TRUE
  OAUTH_CLIENT = CUSTOM
  OAUTH_CLIENT_TYPE = 'CONFIDENTIAL'
  OAUTH_REDIRECT_URI = 'https://cloud.getdbt.com/oauth/callback'
  OAUTH_ISSUE_REFRESH_TOKENS = FALSE
  OAUTH_REFRESH_TOKEN_VALIDITY = 0
  OAUTH_ENFORCE_PKCE = FALSE
  BLOCKED_ROLES_LIST = ('ACCOUNTADMIN', 'SECURITYADMIN');

-- View OAuth integration details
DESC SECURITY INTEGRATION DBT_CLOUD_OAUTH;
-- Copy OAUTH_CLIENT_ID and OAUTH_CLIENT_SECRET to dbt Cloud settings

-- Create OAuth integration for Metabase (authorization code flow)
CREATE SECURITY INTEGRATION METABASE_OAUTH
  TYPE = OAUTH
  ENABLED = TRUE
  OAUTH_CLIENT = CUSTOM
  OAUTH_CLIENT_TYPE = 'CONFIDENTIAL'
  OAUTH_REDIRECT_URI = 'https://metabase.splash.com/auth/snowflake/callback'
  OAUTH_ISSUE_REFRESH_TOKENS = TRUE
  OAUTH_REFRESH_TOKEN_VALIDITY = 86400  -- 24 hours
  OAUTH_ENFORCE_PKCE = TRUE
  BLOCKED_ROLES_LIST = ('ACCOUNTADMIN');

-- Grant usage on integration to roles
GRANT USAGE ON INTEGRATION DBT_CLOUD_OAUTH TO ROLE DBT_SERVICE_ACCOUNT;
GRANT USAGE ON INTEGRATION METABASE_OAUTH TO ROLE METABASE_READER;
```

## JSON Web Tokens (JWT)

### JWT Structure

JWT is a compact, URL-safe token format consisting of three Base64-encoded parts separated by dots:

```text
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c

Header:    {"alg":"HS256","typ":"JWT"}
Payload:   {"sub":"1234567890","name":"John Doe","iat":1516239022}
Signature: HMACSHA256(base64UrlEncode(header) + "." + base64UrlEncode(payload), secret)
```

### JWT Claims (Payload)

```json
{
  "iss": "https://auth.splash.com",  // Issuer
  "sub": "user@splash.com",          // Subject (user identifier)
  "aud": "metabase-api",             // Audience (intended recipient)
  "exp": 1735689600,                 // Expiration time (Unix timestamp)
  "iat": 1735603200,                 // Issued at time
  "nbf": 1735603200,                 // Not before time
  "jti": "abc123def456",             // JWT ID (unique identifier)
  "scope": "read:dashboards write:queries",  // Permissions
  "role": "FINANCE_ANALYST"          // User role
}
```

### Metabase JWT Authentication

```python
# Generate JWT token for embedding Metabase dashboards
import jwt
import time

# Metabase embedding secret (from Metabase settings)
METABASE_SECRET_KEY = "abc123def456789..."

# JWT payload
payload = {
    "resource": {"dashboard": 123},  # Dashboard ID to embed
    "params": {
        "user_region": "US_WEST"  # Row-level security parameter
    },
    "exp": int(time.time()) + 600  # Expires in 10 minutes
}

# Generate signed JWT token
token = jwt.encode(payload, METABASE_SECRET_KEY, algorithm="HS256")

# Embed dashboard with JWT token
iframe_url = f"https://metabase.splash.com/embed/dashboard/{token}#bordered=true&titled=true"
```

### JWT Validation Best Practices

```python
import jwt
from jwt import PyJWKClient

# Validate JWT signature with JWKS (JSON Web Key Set)
def validate_jwt_token(token):
    # Fetch public keys from authorization server
    jwks_client = PyJWKClient("https://splash.okta.com/oauth2/v1/keys")
    signing_key = jwks_client.get_signing_key_from_jwt(token)

    # Validate token signature and claims
    try:
        decoded_token = jwt.decode(
            token,
            signing_key.key,
            algorithms=["RS256"],
            audience="metabase-api",
            issuer="https://splash.okta.com",
            options={"verify_exp": True}  # Verify expiration
        )
        return decoded_token
    except jwt.ExpiredSignatureError:
        raise Exception("Token has expired")
    except jwt.InvalidAudienceError:
        raise Exception("Invalid audience")
    except jwt.InvalidIssuerError:
        raise Exception("Invalid issuer")
    except Exception as e:
        raise Exception(f"Token validation failed: {str(e)}")
```

## API Keys

### API Key Characteristics

- **Static tokens**: Long-lived credentials (90-365 days)
- **Simple authentication**: Pass in header or query parameter
- **Service accounts**: Machine-to-machine authentication
- **Revocable**: Can be revoked without changing code (rotate via secrets manager)

### Metabase API Key Authentication

```bash
# Create API key in Metabase (Admin Settings > API Keys)
# API key format: mb_abc123def456789...

# Use API key for programmatic access
curl https://metabase.splash.com/api/dashboard/123 \
  -H "X-Metabase-Session: mb_abc123def456789..."

# Or use basic authentication
curl https://metabase.splash.com/api/dashboard/123 \
  -u "api_key:mb_abc123def456789..."
```

### dbt Cloud API Key Authentication

```bash
# Create service account token in dbt Cloud (Account Settings > Service Tokens)

# Trigger dbt Cloud job via API
curl -X POST https://cloud.getdbt.com/api/v2/accounts/12345/jobs/67890/run/ \
  -H "Authorization: Token abc123def456..." \
  -H "Content-Type: application/json" \
  -d '{
    "cause": "API trigger from Airflow",
    "git_branch": "main",
    "schema_override": "PROD"
  }'
```

### Airbyte API Key Authentication

```bash
# Create API key in Airbyte (Settings > API Keys)

# Trigger Airbyte sync via API
curl -X POST https://airbyte.splash.com/api/v1/connections/abc-123-def/sync \
  -H "X-API-Key: airbyte_api_key_123..." \
  -H "Content-Type: application/json"

# Get sync status
curl https://airbyte.splash.com/api/v1/jobs/456 \
  -H "X-API-Key: airbyte_api_key_123..."
```

### API Key Security Best Practices

1. **Use environment variables or secrets manager** (never hardcode in code)
2. **Rotate keys regularly** (every 90 days minimum)
3. **Scope API keys** to minimum necessary permissions
4. **Monitor API key usage** (alert on anomalies)
5. **Revoke immediately** upon employee offboarding or suspected compromise
6. **Use separate keys per environment** (dev/staging/prod)

## Rate Limiting

### Rate Limiting Strategies

#### Fixed Window

```text
Limit: 100 requests per minute
Window: 00:00-00:59, 01:00-01:59, ...

Request at 00:58 (count: 99) → ALLOW
Request at 00:59 (count: 100) → ALLOW
Request at 01:00 (count: 1) → ALLOW (new window, counter reset)
```

**Pros**: Simple to implement

**Cons**: Burst traffic at window boundaries (200 requests in 2 seconds)

#### Sliding Window

```text
Limit: 100 requests per 60-second rolling window

Request at 00:58 → Check requests from 23:58-00:58 → ALLOW if <100
Request at 01:00 → Check requests from 00:00-01:00 → ALLOW if <100
```

**Pros**: Prevents burst traffic at boundaries

**Cons**: More complex to implement (requires timestamp tracking)

#### Token Bucket

```text
Bucket capacity: 100 tokens
Refill rate: 10 tokens per second

Request → Consume 1 token → ALLOW if tokens available
Empty bucket → Wait for refill or DENY
```

**Pros**: Allows controlled bursts

**Cons**: Complex configuration (capacity + refill rate)

### Metabase Rate Limiting

```nginx
# Nginx rate limiting for Metabase API
# /etc/nginx/conf.d/metabase.conf

# Define rate limit zone (10MB memory, ~160k IP addresses)
limit_req_zone $binary_remote_addr zone=metabase_api:10m rate=100r/m;

server {
    listen 443 ssl;
    server_name metabase.splash.com;

    location /api/ {
        # Apply rate limit with burst allowance
        limit_req zone=metabase_api burst=20 nodelay;
        limit_req_status 429;  # Return 429 Too Many Requests

        proxy_pass http://metabase-backend:3000;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    location / {
        # No rate limit for dashboard UI
        proxy_pass http://metabase-backend:3000;
    }
}
```

### Kong API Gateway Rate Limiting

```bash
# Kong rate limiting plugin for Airbyte API
curl -X POST http://kong-admin:8001/services/airbyte-api/plugins \
  --data "name=rate-limiting" \
  --data "config.second=10" \
  --data "config.minute=100" \
  --data "config.hour=1000" \
  --data "config.policy=local" \
  --data "config.fault_tolerant=true" \
  --data "config.hide_client_headers=false"

# Response headers show rate limit status
HTTP/1.1 200 OK
X-RateLimit-Limit-Minute: 100
X-RateLimit-Remaining-Minute: 87
RateLimit-Reset: 45  # Seconds until reset
```

### Snowflake Query Rate Limiting

```sql
-- Resource monitors to limit query consumption
CREATE RESOURCE MONITOR DAILY_QUERY_LIMIT
  WITH CREDIT_QUOTA = 1000  -- 1000 credits per day
  FREQUENCY = DAILY
  START_TIMESTAMP = IMMEDIATELY
  TRIGGERS
    ON 75 PERCENT DO NOTIFY  -- Alert at 75% quota
    ON 90 PERCENT DO SUSPEND  -- Suspend at 90% quota
    ON 100 PERCENT DO SUSPEND_IMMEDIATE;  -- Hard stop at 100%

-- Apply monitor to warehouse
ALTER WAREHOUSE TRANSFORMING SET RESOURCE_MONITOR = DAILY_QUERY_LIMIT;

-- View resource monitor usage
SELECT *
FROM SNOWFLAKE.ACCOUNT_USAGE.RESOURCE_MONITOR_USAGE
WHERE resource_monitor_name = 'DAILY_QUERY_LIMIT'
ORDER BY start_time DESC;
```

## Request Validation and Input Sanitization

### SQL Injection Prevention

```python
# BAD: SQL injection vulnerable
def get_user_data(user_id):
    query = f"SELECT * FROM users WHERE user_id = '{user_id}'"  # DANGEROUS!
    return execute_query(query)

# Attacker input: user_id = "1' OR '1'='1"
# Executed query: SELECT * FROM users WHERE user_id = '1' OR '1'='1'
# Result: Returns ALL users (data breach)

# GOOD: Parameterized queries
def get_user_data(user_id):
    query = "SELECT * FROM users WHERE user_id = ?"
    return execute_query(query, params=[user_id])

# Attacker input: user_id = "1' OR '1'='1"
# Executed query: SELECT * FROM users WHERE user_id = '1'' OR ''1''=''1'
# Result: No rows (literal string match)
```

### API Input Validation

```python
from pydantic import BaseModel, validator, Field
from datetime import datetime

class DashboardQueryRequest(BaseModel):
    dashboard_id: int = Field(..., ge=1, le=99999)  # Must be 1-99999
    start_date: datetime
    end_date: datetime
    region: str = Field(..., regex="^(US_WEST|US_EAST|EU|APAC)$")

    @validator('end_date')
    def end_date_after_start_date(cls, v, values):
        if 'start_date' in values and v < values['start_date']:
            raise ValueError('end_date must be after start_date')
        return v

    @validator('start_date')
    def start_date_not_too_old(cls, v):
        if v < datetime.now() - timedelta(days=365):
            raise ValueError('start_date cannot be more than 1 year ago')
        return v

# Usage in FastAPI endpoint
@app.post("/api/dashboard/query")
async def query_dashboard(request: DashboardQueryRequest):
    # Input is automatically validated
    # Invalid input returns 422 Unprocessable Entity with error details
    return execute_dashboard_query(request)
```

### Content-Type Validation

```python
# Reject requests with unexpected Content-Type
@app.middleware("http")
async def validate_content_type(request: Request, call_next):
    if request.method in ["POST", "PUT", "PATCH"]:
        content_type = request.headers.get("Content-Type", "")
        if not content_type.startswith("application/json"):
            return JSONResponse(
                status_code=415,
                content={"error": "Unsupported Media Type. Expected application/json"}
            )
    response = await call_next(request)
    return response
```

## API Security Headers

### Security Headers for API Responses

```python
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware

app = FastAPI()

# CORS (Cross-Origin Resource Sharing)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://metabase.splash.com"],  # Specific origins only
    allow_credentials=True,
    allow_methods=["GET", "POST"],  # No DELETE/PUT from browser
    allow_headers=["Authorization", "Content-Type"],
    max_age=3600  # Cache preflight for 1 hour
)

# Trusted Host (prevent host header injection)
app.add_middleware(
    TrustedHostMiddleware,
    allowed_hosts=["api.splash.com", "*.splash.com"]
)

# Add security headers to all responses
@app.middleware("http")
async def add_security_headers(request: Request, call_next):
    response = await call_next(request)
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["X-XSS-Protection"] = "1; mode=block"
    response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
    response.headers["Content-Security-Policy"] = "default-src 'self'"
    return response
```

## Webhook Security

### HMAC Signature Validation (Airbyte Webhooks)

```python
import hmac
import hashlib

def validate_webhook_signature(payload: bytes, signature: str, secret: str) -> bool:
    """
    Validate HMAC signature for webhook payload

    Airbyte webhook format:
    X-Airbyte-Signature: sha256=abc123def456...
    """
    # Extract signature algorithm and hash
    algorithm, provided_signature = signature.split("=")

    # Compute expected signature
    expected_signature = hmac.new(
        key=secret.encode(),
        msg=payload,
        digestmod=hashlib.sha256
    ).hexdigest()

    # Constant-time comparison (prevent timing attacks)
    return hmac.compare_digest(expected_signature, provided_signature)

# Usage in webhook endpoint
@app.post("/webhooks/airbyte")
async def handle_airbyte_webhook(request: Request):
    # Read raw payload
    payload = await request.body()

    # Get signature from header
    signature = request.headers.get("X-Airbyte-Signature")
    if not signature:
        raise HTTPException(status_code=401, detail="Missing signature")

    # Validate signature
    secret = os.environ["AIRBYTE_WEBHOOK_SECRET"]
    if not validate_webhook_signature(payload, signature, secret):
        raise HTTPException(status_code=401, detail="Invalid signature")

    # Process webhook
    event = json.loads(payload)
    process_airbyte_event(event)

    return {"status": "received"}
```

## Further Reading

- [OAuth 2.0 RFC 6749](https://datatracker.ietf.org/doc/html/rfc6749)
- [JWT RFC 7519](https://datatracker.ietf.org/doc/html/rfc7519)
- [OWASP API Security Top 10](https://owasp.org/www-project-api-security/)
- [Snowflake OAuth Documentation](https://docs.snowflake.com/en/user-guide/oauth)
- [Kong API Gateway Rate Limiting](https://docs.konghq.com/hub/kong-inc/rate-limiting/)
