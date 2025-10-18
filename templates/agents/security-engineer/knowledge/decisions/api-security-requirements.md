---
title: "API Security Requirements"
description: "Authentication methods by service, token policies, and rate limiting standards"
category: "decisions"
last_updated: "2025-10-07"
---

# API Security Requirements

## Service-Specific Authentication

| Service | Authentication Method | Token Validity | Rotation Frequency | MFA Required |
|---------|----------------------|----------------|-------------------|--------------|
| Snowflake (humans) | OAuth 2.0 + MFA | 10 minutes | Automatic (OAuth) | Yes |
| Snowflake (service accounts) | OAuth 2.0 client credentials | 10 minutes | Automatic (OAuth) | No |
| Metabase (users) | SAML SSO (Okta) | Session-based | N/A (SSO managed) | Yes |
| Metabase API | API Key | 7 days | 90 days | No |
| dbt Cloud | Service Token | 90 days | 90 days | No |
| Airbyte | API Key | 180 days | 180 days | No |

## Rate Limiting Standards

- **Production APIs**: 100 requests/minute per client (burst: 20 requests)
- **Development APIs**: 1000 requests/minute (no production impact)
- **Webhook Endpoints**: 10 requests/second (HMAC signature required)

## Decision Rationale

**Why OAuth for Snowflake instead of username/password?**

- Short-lived tokens (10 minutes) reduce credential theft risk
- Automatic rotation, no manual password changes
- Revoke access by disabling OAuth integration (no password reset)
