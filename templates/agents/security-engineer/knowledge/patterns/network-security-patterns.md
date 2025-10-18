---
title: "Network Security Patterns"
description: "VPC design, security groups, private endpoints, IP allowlisting, and network segmentation"
category: "patterns"
last_updated: "2025-10-07"
---

# Network Security Patterns

## VPC Architecture for Data Platform

```text
                    ┌─────────────────────────────────────┐
                    │  VPC (10.0.0.0/16)                  │
                    │                                     │
    ┌───────────────┼─────────────────┬──────────────────┤
    │ Public Subnet │                 │ Private Subnet A │
    │ 10.0.1.0/24   │                 │ 10.0.10.0/24     │
    │               │                 │                  │
    │ ┌───────────┐ │                 │ ┌──────────────┐ │
    │ │ Bastion   │ │                 │ │ Airbyte      │ │
    │ │ Host      │ │                 │ │ (Docker)     │ │
    │ └───────────┘ │                 │ └──────────────┘ │
    │               │                 │                  │
    │ ┌───────────┐ │                 │ ┌──────────────┐ │
    │ │ NAT       │◄┼─────────────────┼─│ Metabase     │ │
    │ │ Gateway   │ │                 │ │ (RDS access) │ │
    │ └───────────┘ │                 │ └──────────────┘ │
    │               │                 │                  │
    └───────────────┴─────────────────┴──────────────────┤
                                      │ Private Subnet B │
                                      │ 10.0.20.0/24     │
                                      │                  │
                                      │ ┌──────────────┐ │
                                      │ │ Metabase RDS │ │
                                      │ │ (PostgreSQL) │ │
                                      │ └──────────────┘ │
                                      └──────────────────┘
                    VPC Endpoints:
                    - S3 (Gateway Endpoint)
                    - Secrets Manager (Interface Endpoint)
                    - KMS (Interface Endpoint)
```

## Security Group Patterns

```json
# Metabase Security Group
{
  "GroupName": "metabase-app",
  "IngressRules": [
    {
      "FromPort": 443,
      "ToPort": 443,
      "IpProtocol": "tcp",
      "CidrIp": "203.0.113.0/24"  # Corporate VPN only
    },
    {
      "FromPort": 3000,
      "ToPort": 3000,
      "IpProtocol": "tcp",
      "SourceSecurityGroupId": "sg-alb-12345"  # ALB only
    }
  ],
  "EgressRules": [
    {
      "FromPort": 5432,
      "ToPort": 5432,
      "IpProtocol": "tcp",
      "DestinationSecurityGroupId": "sg-rds-67890"  # PostgreSQL RDS
    },
    {
      "FromPort": 443,
      "ToPort": 443,
      "IpProtocol": "tcp",
      "CidrIp": "0.0.0.0/0"  # Snowflake API (TLS only)
    }
  ]
}
```

## Snowflake IP Allowlisting

```sql
-- Corporate VPN + dbt Cloud IPs only
CREATE NETWORK POLICY PRODUCTION_ACCESS
  ALLOWED_IP_LIST = (
    '203.0.113.0/24',     -- Corporate VPN
    '52.45.144.63/32',    -- dbt Cloud (us-east-1)
    '54.81.134.249/32'    -- dbt Cloud backup
  )
  BLOCKED_IP_LIST = ();

ALTER ACCOUNT SET NETWORK_POLICY = PRODUCTION_ACCESS;
```
