---
agent: privacy-security-auditor
updated: "2025-10-04"
knowledge_count: 0
memory_type: "agent-specific"
---

# Knowledge Index for Privacy & Security Auditor

This index catalogs all knowledge resources available to the privacy-security-auditor agent. These act as persistent memories that the agent can reference during execution for PII detection, data scrubbing, security auditing, and privacy compliance.

## Local Knowledge Files

### Core Concepts
<!-- Add core concept files here as they are created -->

### Patterns
<!-- Add pattern files here as they are created -->

### Decisions
<!-- Add decision files here as they are created -->

## External Documentation Links

### PII & Data Privacy
- [NIST PII Guide](https://www.nist.gov/privacy-framework/nist-pii-guide) - Official guidance on personally identifiable information
- [GDPR Guidelines](https://gdpr.eu/what-is-gdpr/) - General Data Protection Regulation overview
- [CCPA Overview](https://oag.ca.gov/privacy/ccpa) - California Consumer Privacy Act guidance
- [PII Detection Patterns](https://github.com/mazen160/secrets-patterns-db) - Common PII and secret patterns

### Data Scrubbing & Sanitization
- [OWASP Data Sanitization](https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html#data-to-exclude) - What to exclude from logs
- [Regex for PII](https://github.com/openai/gpt-3.5-turbo/blob/main/docs/guides/safety-best-practices.md) - Pattern matching for sensitive data
- [Microsoft Presidio](https://github.com/microsoft/presidio) - Data protection and anonymization patterns

### Security Best Practices
- [OWASP Top 10](https://owasp.org/www-project-top-ten/) - Web application security risks
- [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks/) - Security configuration best practices
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework) - Risk management framework

### Secrets Management
- [Git Secrets](https://github.com/awslabs/git-secrets) - Prevent committing secrets
- [detect-secrets](https://github.com/Yelp/detect-secrets) - Enterprise-grade secret detection
- [Secret Scanning Patterns](https://github.com/mazen160/secrets-patterns-db) - Database of secret patterns
- [.gitignore Security Patterns](https://github.com/github/gitignore/blob/main/Global/Archives.gitignore) - Files that commonly contain secrets

### Environment & Configuration Security
- [12 Factor App - Config](https://12factor.net/config) - Configuration management best practices
- [Environment Variable Security](https://blog.gitguardian.com/secrets-credentials-in-environment-variables/) - Secure env var handling
- [dotenv Security](https://github.com/motdotla/dotenv#should-i-commit-my-env-file) - .env file best practices

### Audit Logging & Monitoring
- [OWASP Logging Guide](https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html) - Secure logging practices
- [Audit Log Design](https://www.cloudflare.com/learning/security/what-is-audit-log/) - Effective audit trail patterns
- [SIEM Best Practices](https://www.sans.org/white-papers/best-practices-for-siem/) - Security information and event management

### Compliance Frameworks
- [SOC 2 Trust Principles](https://www.aicpa.org/resources/article/5-trust-services-criteria-under-soc-2) - Security and privacy criteria
- [HIPAA Security Rule](https://www.hhs.gov/hipaa/for-professionals/security/index.html) - Healthcare data protection
- [ISO 27001](https://www.iso.org/isoiec-27001-information-security.html) - Information security management

## Usage Notes

**When to Add Knowledge:**
- New PII pattern discovered → Add to patterns section
- Important security decision made → Record in decisions history
- Useful privacy tool or technique found → Add to external links
- Data scrubbing pattern developed → Document in patterns
- Compliance requirement identified → Add to core concepts

**Knowledge Maintenance:**
- Update this index.md when adding/removing files
- Increment knowledge_count in frontmatter
- Update the `updated` date
- Keep knowledge focused on privacy and security topics
- Link to official documentation rather than duplicating it

**Memory Philosophy:**
- **CLAUDE.md**: Quick reference for when to use privacy-security-auditor agent (always in context)
- **Knowledge Base**: Detailed PII patterns, scrubbing templates, decision history (loaded when agent invokes)
- Both systems work together for efficient context management

## Knowledge Priorities

**High Priority Knowledge:**
1. PII detection patterns and regex for AIDA project
2. Data scrubbing and sanitization techniques
3. Secret detection and prevention patterns
4. .gitignore patterns for sensitive files
5. Environment variable security best practices

**Medium Priority Knowledge:**
1. Audit logging requirements and patterns
2. Compliance framework requirements (GDPR, CCPA)
3. Security testing and validation procedures
4. Encryption and data protection strategies

**Low Priority Knowledge:**
1. Platform-specific security features (document as needed)
2. Industry-specific compliance (focus on applicable standards)
3. Generic security concepts (focus on AIDA-specific applications)