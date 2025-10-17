---
title: "HIPAA Compliance"
description: "HIPAA requirements, PHI handling procedures, and compliance patterns for healthcare applications"
category: "compliance"
used_by: ["governance-analyst", "compliance-analyst", "product-engineer", "platform-engineer", "data-engineer"]
tags: ["hipaa", "healthcare", "compliance", "phi", "privacy"]
last_updated: "2025-10-16"
---

# HIPAA Compliance

## Overview

This skill provides Health Insurance Portability and Accountability Act (HIPAA) compliance requirements, Protected Health Information (PHI) handling procedures, and implementation patterns for healthcare applications.

HIPAA is a U.S. federal law that establishes national standards for protecting sensitive patient health information. Any system that creates, receives, maintains, or transmits PHI must comply with HIPAA regulations.

Use this skill when:
- Building healthcare applications that handle patient data
- Designing systems that store or transmit PHI
- Auditing healthcare applications for HIPAA compliance
- Implementing security controls for patient data
- Creating audit trails for PHI access

## When to Use

- **Healthcare applications**: Any system handling patient health information
- **Data pipelines**: Processing or storing healthcare data
- **APIs**: Exposing patient data to authorized users
- **Compliance audits**: Verifying HIPAA compliance
- **Security reviews**: Ensuring proper PHI protection
- **Third-party integrations**: Connecting to healthcare systems (EHR, lab systems)

## Used By

- **governance-analyst**: Defines HIPAA compliance requirements for projects
- **compliance-analyst**: Audits applications for HIPAA compliance
- **product-engineer**: Implements HIPAA-compliant features
- **platform-engineer**: Builds HIPAA-compliant platform services
- **data-engineer**: Handles PHI in data pipelines

## Contents

- [requirements.md](requirements.md) - HIPAA requirements summary and compliance checklist
- [phi-handling.md](phi-handling.md) - Protected Health Information identification and handling
- [security-rule.md](security-rule.md) - HIPAA Security Rule technical safeguards
- [privacy-rule.md](privacy-rule.md) - HIPAA Privacy Rule and patient rights
- [audit-logging.md](audit-logging.md) - Audit trail requirements and implementation
- [encryption.md](encryption.md) - Encryption standards for PHI at rest and in transit
- [access-control.md](access-control.md) - Access control and authentication requirements
- [breach-notification.md](breach-notification.md) - Breach detection and notification procedures

## Related Skills

- [gdpr-compliance](../gdpr-compliance/) - EU data privacy compliance
- [pci-compliance](../pci-compliance/) - Payment card data compliance
- [audit-logging](../../infrastructure/audit-logging/) - General audit logging patterns
- [encryption-patterns](../../infrastructure/encryption-patterns/) - Encryption implementation

## What is PHI?

**Protected Health Information (PHI)** is any information about health status, provision of healthcare, or payment for healthcare that can be linked to a specific individual.

### PHI Includes

- **Demographic Information**:
  - Names, addresses, phone numbers, email addresses
  - Social Security numbers, medical record numbers
  - Account numbers, certificate/license numbers
  - Vehicle identifiers, device identifiers
  - URLs, IP addresses, biometric identifiers
  - Full-face photos, fingerprints, voice recordings

- **Health Information**:
  - Diagnoses, treatment information, test results
  - Prescriptions, immunization records
  - Mental health information
  - Insurance information, billing information

- **18 HIPAA Identifiers**: See [phi-handling.md](phi-handling.md) for complete list

### PHI Does NOT Include

- De-identified data (properly de-identified per HIPAA Safe Harbor or Expert Determination)
- Employment records held by employer
- Education records covered by FERPA
- Aggregate data with no individual identifiers

## HIPAA Rules Summary

### Privacy Rule

Establishes national standards for protecting PHI:
- **Minimum Necessary**: Only access/use minimum PHI needed
- **Patient Rights**: Access, amendment, accounting of disclosures
- **Authorization**: Written authorization for most PHI disclosures
- **Business Associate Agreements (BAAs)**: Required for third parties

### Security Rule

Protects electronic PHI (ePHI) with technical safeguards:
- **Access Control**: Unique user IDs, emergency access, encryption
- **Audit Controls**: Logs of system activity
- **Integrity Controls**: Ensure ePHI not improperly altered
- **Transmission Security**: Encrypt PHI in transit

### Breach Notification Rule

Requires notification of PHI breaches:
- **Affected individuals**: Within 60 days
- **HHS**: For breaches affecting 500+ individuals
- **Media**: For large breaches
- **Documentation**: Maintain breach log

## Common HIPAA Requirements

### Encryption

**At Rest**:
- AES-256 encryption for databases storing PHI
- Encrypted file systems or volumes
- Encrypted backups

**In Transit**:
- TLS 1.2+ for all PHI transmissions
- VPNs for internal network traffic
- Encrypted email for PHI communications

### Access Control

- Unique user identification (no shared accounts)
- Role-based access control (RBAC)
- Automatic logoff after inactivity
- Emergency access procedures
- Multi-factor authentication (recommended)

### Audit Logging

Must log and retain:
- PHI access (who, what, when, where)
- PHI modifications
- System access (logins, logouts, failed attempts)
- Administrative changes
- Retention: Minimum 6 years

### Data Residency

- PHI must remain in US (or country with adequate protections)
- Cloud providers must sign Business Associate Agreement (BAA)
- Document where PHI is stored and transmitted

## Quick Implementation Checklist

### Application Development

- [ ] Identify all PHI in system
- [ ] Encrypt PHI at rest (AES-256)
- [ ] Encrypt PHI in transit (TLS 1.2+)
- [ ] Implement role-based access control
- [ ] Add audit logging for all PHI access
- [ ] Implement session timeouts
- [ ] Add multi-factor authentication
- [ ] Create patient consent workflows
- [ ] Implement data retention policies
- [ ] Add breach detection monitoring

### Data Engineering

- [ ] Mask or de-identify PHI in non-production environments
- [ ] Encrypt data pipelines end-to-end
- [ ] Log all PHI access and transformations
- [ ] Implement row-level security in data warehouse
- [ ] Add data quality checks for PHI
- [ ] Create secure data sharing mechanisms
- [ ] Document data lineage for PHI
- [ ] Implement automated PHI detection

### Platform Services

- [ ] Obtain BAA from cloud provider (AWS, Azure, GCP)
- [ ] Configure encrypted storage volumes
- [ ] Enable CloudTrail/audit logging
- [ ] Implement VPC with private subnets
- [ ] Use security groups/firewalls
- [ ] Enable encryption for databases
- [ ] Configure automated backups (encrypted)
- [ ] Implement disaster recovery

## Examples

### Detecting PHI in Data

```python
import re

PHI_PATTERNS = {
    'ssn': r'\b\d{3}-\d{2}-\d{4}\b',
    'email': r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b',
    'phone': r'\b\d{3}-\d{3}-\d{4}\b',
    'mrn': r'\bMRN\d{6,}\b',
}

def contains_phi(text):
    """Check if text contains potential PHI."""
    for phi_type, pattern in PHI_PATTERNS.items():
        if re.search(pattern, text):
            return True, phi_type
    return False, None
```

### Audit Logging PHI Access

```python
import logging
from datetime import datetime

def log_phi_access(user_id, patient_id, action, resource):
    """Log PHI access for HIPAA compliance."""
    logging.info({
        'event_type': 'phi_access',
        'timestamp': datetime.utcnow().isoformat(),
        'user_id': user_id,
        'patient_id': patient_id,  # May need to hash
        'action': action,  # 'read', 'write', 'delete'
        'resource': resource,
        'ip_address': get_request_ip(),
        'user_agent': get_user_agent(),
    })
```

### Encrypting PHI at Rest

```python
from cryptography.fernet import Fernet

class PHIEncryption:
    """Encrypt/decrypt PHI using Fernet (symmetric encryption)."""

    def __init__(self, key):
        self.cipher = Fernet(key)

    def encrypt_phi(self, phi_data):
        """Encrypt PHI data."""
        return self.cipher.encrypt(phi_data.encode())

    def decrypt_phi(self, encrypted_data):
        """Decrypt PHI data."""
        return self.cipher.decrypt(encrypted_data).decode()
```

### De-identifying Patient Data

```python
import hashlib

def de_identify_patient(patient_data):
    """Remove direct identifiers from patient data."""
    # Remove 18 HIPAA identifiers
    de_identified = {
        # Keep clinical data
        'diagnosis': patient_data['diagnosis'],
        'age_range': get_age_range(patient_data['age']),  # 10-year ranges
        'zip3': patient_data['zip'][:3],  # First 3 digits of ZIP
        'admission_year': patient_data['admission_date'].year,

        # Hash unique identifiers (for linkage)
        'patient_hash': hashlib.sha256(
            patient_data['mrn'].encode()
        ).hexdigest(),
    }
    return de_identified
```

## Penalties for Non-Compliance

**Civil Penalties** (per violation):
- Tier 1 (Unknowing): $100 - $50,000
- Tier 2 (Reasonable cause): $1,000 - $50,000
- Tier 3 (Willful neglect, corrected): $10,000 - $50,000
- Tier 4 (Willful neglect, not corrected): $50,000 - $1.9M

**Criminal Penalties**:
- Up to $50,000 and 1 year in prison
- Up to $100,000 and 5 years (under false pretenses)
- Up to $250,000 and 10 years (with intent to sell PHI)

**Annual Maximum**: $1.9 million per violation type

## References

- [HHS HIPAA Website](https://www.hhs.gov/hipaa/)
- [HIPAA Security Rule](https://www.hhs.gov/hipaa/for-professionals/security/)
- [HIPAA Privacy Rule](https://www.hhs.gov/hipaa/for-professionals/privacy/)
- [Breach Notification Rule](https://www.hhs.gov/hipaa/for-professionals/breach-notification/)
- [NIST HIPAA Security Guidance](https://www.nist.gov/healthcare)
- [AWS HIPAA Compliance](https://aws.amazon.com/compliance/hipaa-compliance/)

## Disclaimer

This skill provides general guidance on HIPAA compliance. It is NOT legal advice. Consult with qualified healthcare compliance attorneys and privacy professionals for specific compliance requirements. HIPAA regulations are complex and subject to change.
