---
name: aws-review
description: Review AWS infrastructure and CDK stacks for cost optimization, security best practices, and architectural improvements
model: sonnet
args:
  scope:
    description: What to review - "all" (default), "cdk", "cost", "security", or specific stack name
    required: false
version: 1.0.0
category: analysis
---

# AWS Infrastructure Review Command

Comprehensive review of AWS infrastructure and CDK stacks for cost optimization opportunities, security best practices, and architectural improvements aligned with the AWS Well-Architected Framework.

## Usage

```bash
# Review all AWS infrastructure (default)
/aws-review
/aws-review --scope all

# Review CDK stacks specifically
/aws-review --scope cdk

# Cost-focused review
/aws-review --scope cost

# Security-focused review
/aws-review --scope security

# Review specific CDK stack
/aws-review --scope MyStackName
```

## Review Scopes

### Comprehensive Review (all)

- CDK stack architecture and structure
- Cost optimization opportunities
- Security best practices
- Well-Architected Framework compliance
- Service selection and configuration
- Performance optimization
- Operational excellence

### CDK-Focused Review (cdk)

- CDK stack structure and organization
- Multi-stack architecture patterns
- Custom construct implementations
- Resource naming conventions
- Stack dependencies and references
- CDK best practices

### Cost-Focused Review (cost)

- Right-sizing opportunities (EC2, RDS, Lambda)
- Unused or underutilized resources
- Reserved Instance and Savings Plans recommendations
- Data transfer optimization
- Storage optimization (S3, EBS)
- Lambda memory and timeout configuration
- CloudWatch logs retention policies

### Security-Focused Review (security)

- IAM policies and least privilege
- Encryption at rest and in transit
- Network security (VPC, Security Groups, NACLs)
- Secret management
- Public exposure risks
- Logging and monitoring configuration
- Compliance with security standards

## Workflow

### Phase 1: Initialize Review Context

#### 1.1 Parse Arguments & Determine Scope

**Process command arguments:**

```bash
# Extract scope argument
SCOPE="${args.scope:-all}"

# Validate scope
case "$SCOPE" in
  all|cdk|cost|security)
    echo "Valid scope: $SCOPE"
    ;;
  *)
    # Assume it's a stack name
    echo "Assuming stack-specific review: $SCOPE"
    ;;
esac
```

**Display review plan:**

```text
AWS Infrastructure Review Initialized
=====================================
Scope: ${SCOPE}
Date: $(date +%Y-%m-%d)
Reviewer: aws-cloud-engineer agent

Review Areas:
${REVIEW_AREAS}
```

#### 1.2 Create Review Directory

Create working directory for review artifacts:

```bash
# Create review directory
REVIEW_DIR=".aws-reviews/$(date +%Y-%m-%d)"
mkdir -p "$REVIEW_DIR"/{findings,recommendations,evidence,reports}

# Create subdirectories
mkdir -p "$REVIEW_DIR/findings/cost"
mkdir -p "$REVIEW_DIR/findings/security"
mkdir -p "$REVIEW_DIR/findings/architecture"
mkdir -p "$REVIEW_DIR/recommendations"
mkdir -p "$REVIEW_DIR/evidence"
mkdir -p "$REVIEW_DIR/reports"
```

**Directory structure:**

```text
.aws-reviews/YYYY-MM-DD/
├── findings/
│   ├── cost/              # Cost optimization findings
│   ├── security/          # Security findings
│   └── architecture/      # Architecture findings
├── recommendations/       # Prioritized recommendations
├── evidence/              # Configuration snapshots, diagrams
└── reports/               # Summary reports
```

#### 1.3 Load Review Configuration

Check for review configuration:

```bash
# Check for review config
if [ -f ".aws-reviews/review-config.json" ]; then
  cat .aws-reviews/review-config.json
else
  # Use default configuration
  echo "Using default review configuration"
fi
```

**Example configuration:**

```json
{
  "cost_thresholds": {
    "high_impact": 500,
    "medium_impact": 100,
    "low_impact": 20
  },
  "excluded_resources": [
    "arn:aws:s3:::my-excluded-bucket"
  ],
  "well_architected_pillars": [
    "operational_excellence",
    "security",
    "reliability",
    "performance_efficiency",
    "cost_optimization",
    "sustainability"
  ],
  "notification": {
    "enabled": true,
    "channels": ["slack"],
    "recipients": ["#aws-alerts"]
  }
}
```

### Phase 2: AWS Environment Discovery

Invoke **aws-cloud-engineer** agent to inventory AWS resources:

**Agent Task:**

```text
Task: Discover and inventory AWS resources in current environment

Context:
- Review Scope: ${SCOPE}
- Review Directory: ${REVIEW_DIR}

Discovery Tasks:

1. CDK Stacks Inventory:
   - Locate all CDK stack files (lib/stacks/*.ts, lib/*.ts)
   - Parse stack definitions
   - Identify stack dependencies and references
   - Map resource types used in each stack
   - Document naming conventions

2. AWS Resources Inventory (if AWS credentials available):
   - CloudFormation stacks (deployed CDK stacks)
   - EC2 instances (instance types, utilization)
   - Lambda functions (memory, timeout, invocations)
   - RDS instances (instance types, storage)
   - S3 buckets (size, storage class, lifecycle policies)
   - VPCs and networking (subnets, route tables, security groups)
   - IAM roles and policies
   - CloudWatch logs (retention periods)
   - Cost and Usage reports (last 30 days)

3. Configuration Evidence:
   - Export CDK synth output (CloudFormation templates)
   - Capture resource tags
   - Document account structure (if multi-account)
   - Save to: ${REVIEW_DIR}/evidence/

Output:
- Save inventory to: ${REVIEW_DIR}/evidence/aws-inventory.md
- Save CDK structure to: ${REVIEW_DIR}/evidence/cdk-structure.md
```

**Expected Output:**

Structured inventory of all AWS resources, CDK stacks, and current configurations.

### Phase 3: Well-Architected Framework Review

Invoke **aws-cloud-engineer** agent to review against AWS Well-Architected Framework:

**Agent Task:**

```text
Task: Review infrastructure against AWS Well-Architected Framework

Context:
- Inventory: ${REVIEW_DIR}/evidence/aws-inventory.md
- CDK Structure: ${REVIEW_DIR}/evidence/cdk-structure.md

Review Each Pillar:

## Operational Excellence
- Infrastructure as Code maturity (CDK usage)
- Deployment automation
- Monitoring and observability
- Change management processes
- Documentation quality

## Security
- Identity and access management (IAM)
- Detective controls (CloudTrail, CloudWatch)
- Infrastructure protection (VPC, Security Groups)
- Data protection (encryption, backups)
- Incident response readiness

## Reliability
- Service limits and quotas
- Backup and recovery
- Multi-AZ deployment
- Auto-scaling configuration
- Error handling and retries

## Performance Efficiency
- Right-sizing (compute, database, storage)
- Caching strategies
- Database optimization
- Network optimization
- Serverless usage patterns

## Cost Optimization
- Right-sizing recommendations
- Reserved capacity and Savings Plans
- Data transfer costs
- Storage optimization
- Lambda cost optimization

## Sustainability
- Region selection for carbon footprint
- Efficient resource utilization
- Serverless over server-based when appropriate
- Storage lifecycle policies

For each pillar:
- Identify current state
- List gaps or areas for improvement
- Provide specific recommendations
- Estimate impact (High/Medium/Low)

Output:
- Save analysis to: ${REVIEW_DIR}/findings/architecture/well-architected-review.md
```

**Expected Output:**

Comprehensive Well-Architected Framework assessment with gaps and recommendations.

### Phase 4: Cost Optimization Analysis

Invoke **aws-cloud-engineer** agent to identify cost optimization opportunities:

**Agent Task:**

```text
Task: Identify AWS cost optimization opportunities

Context:
- AWS Inventory: ${REVIEW_DIR}/evidence/aws-inventory.md
- Cost Data: Last 30 days usage and costs

Analysis Areas:

## Right-Sizing Opportunities

### EC2 Instances
- Identify underutilized instances (< 40% CPU average)
- Recommend smaller instance types
- Calculate potential savings

### RDS Instances
- Analyze database utilization metrics
- Identify oversized instances
- Recommend storage optimization (gp2 -> gp3)

### Lambda Functions
- Analyze memory usage vs configured
- Identify over-provisioned functions
- Optimize timeout settings
- Calculate potential savings

## Unused Resources

- Unattached EBS volumes
- Unused Elastic IPs
- Idle Load Balancers
- Empty S3 buckets with lifecycle policies disabled
- Unused NAT Gateways
- Old CloudWatch Logs (excessive retention)

## Reserved Capacity & Savings Plans

- Analyze steady-state workloads
- Calculate Reserved Instance recommendations
- Evaluate Savings Plans opportunities
- Project 1-year and 3-year savings

## Data Transfer Costs

- Analyze inter-AZ data transfer
- Identify public internet data transfer
- Recommend VPC Endpoints for AWS services
- Suggest S3 Transfer Acceleration alternatives

## Storage Optimization

### S3
- Identify buckets without lifecycle policies
- Recommend transitions to Glacier/Deep Archive
- Calculate storage class optimization savings
- Identify incomplete multipart uploads

### EBS
- Identify gp2 volumes (recommend gp3)
- Find snapshots without retention policy
- Recommend snapshot lifecycle automation

## Lambda Optimization

- Analyze invocation patterns
- Identify functions with excessive memory
- Recommend Graviton2 for arm64 compatibility
- Calculate memory/duration optimization savings

For each opportunity:
- Opportunity ID: COST-{YYYY-MM-DD}-{nnn}
- Resource: {resource_arn_or_identifier}
- Current Cost: ${monthly_cost}
- Recommended Action: {specific_action}
- Potential Savings: ${monthly_savings} (${annual_savings}/year)
- Effort: Low/Medium/High
- Risk: Low/Medium/High
- Priority: Immediate/Short-term/Long-term

Output:
- Save cost analysis to: ${REVIEW_DIR}/findings/cost/optimization-opportunities.md
```

**Expected Output:**

Detailed cost optimization opportunities with estimated savings and effort.

### Phase 5: Security Best Practices Review

If scope includes security, invoke **aws-cloud-engineer** agent for security review:

**Agent Task:**

```text
Task: Review AWS infrastructure security best practices

Context:
- AWS Inventory: ${REVIEW_DIR}/evidence/aws-inventory.md
- CDK Stacks: ${REVIEW_DIR}/evidence/cdk-structure.md

Security Assessment:

## IAM Security

### Policies and Permissions
- Identify overly permissive policies (wildcards in actions/resources)
- Check for least privilege violations
- Review service roles and trust relationships
- Identify unused IAM roles and users
- Check for MFA enforcement gaps

### Access Keys and Credentials
- Identify long-lived access keys (> 90 days)
- Check for embedded credentials in code
- Review secrets management (Secrets Manager vs hardcoded)

## Network Security

### VPC Configuration
- Review security group rules (broad ranges, 0.0.0.0/0)
- Analyze NACL configurations
- Identify public subnets with sensitive resources
- Check VPC Flow Logs enablement

### Network Access
- Identify publicly accessible RDS instances
- Check S3 buckets with public access
- Review API Gateway authorization
- Analyze ALB/NLB security group rules

## Data Protection

### Encryption at Rest
- S3 bucket encryption (missing or default)
- EBS volume encryption status
- RDS encryption enabled
- DynamoDB encryption
- Secrets Manager encryption with KMS

### Encryption in Transit
- ALB/NLB HTTPS listeners only
- RDS SSL/TLS enforcement
- API Gateway TLS version (require 1.2+)
- CloudFront HTTPS-only

## Logging and Monitoring

### CloudTrail
- Verify CloudTrail enabled for all regions
- Check S3 bucket logging for audit trail
- Ensure log file validation enabled

### CloudWatch Logs
- Verify VPC Flow Logs enabled
- Check Lambda function logging
- Review log retention policies (compliance requirements)

### Monitoring and Alerting
- Check for CloudWatch alarms on critical resources
- Verify SNS notifications configured
- Review EventBridge rules for security events

## Compliance and Standards

- CIS AWS Foundations Benchmark
- AWS Security Best Practices
- Industry-specific compliance (GDPR, HIPAA, SOC 2)

For each finding:
- Finding ID: SEC-{YYYY-MM-DD}-{nnn}
- Severity: Critical/High/Medium/Low
- Resource: {resource_identifier}
- Issue: {description}
- Risk: {what_could_happen}
- Recommendation: {specific_remediation}
- Effort: Low/Medium/High
- Compliance Impact: {frameworks_affected}

Output:
- Save security review to: ${REVIEW_DIR}/findings/security/security-assessment.md
```

**Expected Output:**

Security assessment with findings, risks, and remediation recommendations.

### Phase 6: CDK Stack Analysis

If scope includes CDK, invoke **aws-cloud-engineer** agent for CDK-specific review:

**Agent Task:**

```text
Task: Review CDK stack architecture and best practices

Context:
- CDK Structure: ${REVIEW_DIR}/evidence/cdk-structure.md
- Stack Files: lib/stacks/*.ts

CDK Review Areas:

## Stack Structure

### Organization
- Single-stack vs multi-stack architecture
- Stack responsibilities and boundaries
- Cross-stack references usage
- Stack dependencies management

### Naming Conventions
- Resource naming patterns
- Stack naming consistency
- Logical ID patterns
- Export naming for cross-stack references

## CDK Best Practices

### Resource Management
- Use of CDK constructs vs raw CloudFormation
- Custom construct creation (reusability)
- Removal policy configuration
- Resource tagging strategy

### Configuration Management
- Environment-specific configuration (dev/staging/prod)
- Context usage patterns
- SSM Parameter Store integration
- Secrets management in CDK

### Stack Patterns
- Stateful vs stateless stacks
- Shared infrastructure stacks
- Application stacks
- Pipeline stacks

## Code Quality

### TypeScript Patterns
- Type safety usage
- Interface definitions for props
- Error handling
- Documentation (JSDoc comments)

### Testing
- Unit tests for constructs
- Integration tests
- Snapshot tests
- Test coverage

## Deployment Considerations

### CI/CD Integration
- CDK pipeline usage
- Deployment automation
- Pre-deployment validation
- Rollback strategies

### Change Management
- CDK diff review process
- Breaking change handling
- Migration strategies
- Blue/green deployment support

For each finding:
- Finding ID: CDK-{YYYY-MM-DD}-{nnn}
- Category: Structure/BestPractice/CodeQuality/Deployment
- Stack: {stack_name}
- Issue: {description}
- Recommendation: {specific_improvement}
- Example: {code_example}
- Effort: Low/Medium/High
- Priority: High/Medium/Low

Output:
- Save CDK review to: ${REVIEW_DIR}/findings/architecture/cdk-stack-analysis.md
```

**Expected Output:**

CDK-specific analysis with architectural recommendations and code improvements.

### Phase 7: Prioritize and Consolidate Recommendations

Process all findings and create prioritized action plan:

#### 7.1 Categorize Findings

**Organize by impact and effort:**

```text
High Impact + Low Effort (Quick Wins):
- Immediate implementation
- High value, minimal risk

High Impact + High Effort (Strategic Initiatives):
- Plan for upcoming sprints
- Significant value but requires resources

Low Impact + Low Effort (Nice to Have):
- Implement when convenient
- Minor improvements

Low Impact + High Effort (Reconsider):
- Evaluate necessity
- May defer or eliminate
```

#### 7.2 Calculate Total Potential Savings

**For cost optimizations:**

```bash
# Sum all cost optimization opportunities
TOTAL_MONTHLY_SAVINGS=0
TOTAL_ANNUAL_SAVINGS=0

# Parse findings and calculate totals
# Output summary statistics
```

#### 7.3 Generate Prioritized Recommendations

Create actionable recommendations document:

```markdown
# AWS Infrastructure Review Recommendations

**Review Date**: {YYYY-MM-DD}
**Scope**: {scope}
**Total Findings**: {count}

---

## Executive Summary

### Overall Assessment

Infrastructure maturity: {score}/10

The AWS infrastructure review identified **{total_findings}** opportunities for improvement:
- **Cost Optimization**: ${total_monthly_savings}/month (${total_annual_savings}/year potential savings)
- **Security**: {security_findings_count} findings ({critical_count} critical)
- **Architecture**: {architecture_findings_count} recommendations
- **CDK Best Practices**: {cdk_findings_count} improvements

### Top 3 Priorities

1. **{priority_1_title}** - {category}
   - Impact: {impact}
   - Estimated Savings/Benefit: {benefit}
   - Effort: {effort}
   - Timeline: {timeline}

2. **{priority_2_title}** - {category}
   - Impact: {impact}
   - Estimated Savings/Benefit: {benefit}
   - Effort: {effort}
   - Timeline: {timeline}

3. **{priority_3_title}** - {category}
   - Impact: {impact}
   - Estimated Savings/Benefit: {benefit}
   - Effort: {effort}
   - Timeline: {timeline}

---

## Cost Optimization Recommendations

### Immediate Actions (< 1 week) - ${immediate_savings}/month

#### COST-{ID}: {Title}
- **Resource**: {resource_identifier}
- **Current Cost**: ${monthly_cost}
- **Recommended Action**: {action}
- **Potential Savings**: ${monthly_savings}/month (${annual_savings}/year)
- **Effort**: {effort}
- **Risk**: {risk}
- **Implementation Steps**:
  1. {step_1}
  2. {step_2}

### Short-Term Actions (1-4 weeks) - ${short_term_savings}/month

[Similar structure for short-term recommendations]

### Long-Term Strategic Initiatives (> 1 month) - ${long_term_savings}/month

[Similar structure for long-term recommendations]

---

## Security Recommendations

### Critical Findings (Immediate Action Required)

#### SEC-{ID}: {Title}
- **Severity**: Critical
- **Resource**: {resource}
- **Issue**: {description}
- **Risk**: {potential_impact}
- **Remediation**:
  1. {step_1}
  2. {step_2}
- **Compliance Impact**: {frameworks}

### High Priority Findings

[Similar structure]

### Medium Priority Findings

[Similar structure]

---

## Architecture Recommendations

### Well-Architected Framework Gaps

#### Operational Excellence
- {recommendation_1}
- {recommendation_2}

#### Reliability
- {recommendation_1}
- {recommendation_2}

#### Performance Efficiency
- {recommendation_1}
- {recommendation_2}

[Continue for other pillars]

### CDK Stack Improvements

#### CDK-{ID}: {Title}
- **Stack**: {stack_name}
- **Category**: {category}
- **Current State**: {description}
- **Recommended Improvement**: {recommendation}
- **Code Example**:

```typescript
// Before
{current_code}

// After
{recommended_code}
```

- **Benefits**: {benefits}
- **Effort**: {effort}

---

## Implementation Roadmap

### Phase 1: Quick Wins (Week 1)

**Estimated Savings**: ${phase_1_savings}/month
**Estimated Effort**: {hours} hours

1. {task_1}
2. {task_2}

### Phase 2: Security Hardening (Weeks 2-4)

**Risk Reduction**: {risk_score_improvement}
**Estimated Effort**: {hours} hours

1. {task_1}
2. {task_2}

### Phase 3: Architecture Optimization (Months 2-3)

**Estimated Savings**: ${phase_3_savings}/month
**Estimated Effort**: {hours} hours

1. {task_1}
2. {task_2}

### Phase 4: Strategic Initiatives (Months 4-6)

**Long-term Benefits**: {description}
**Estimated Effort**: {hours} hours

1. {task_1}
2. {task_2}

---

## Specific Code Changes for CDK Improvements

### Change 1: {Title}

**File**: `{file_path}`

```typescript
// Current Implementation
{current_code}

// Recommended Implementation
{recommended_code}
```

**Rationale**: {explanation}

**Testing**:

```bash
{test_commands}
```

[Repeat for additional code changes]

---

## Appendices

### Appendix A: Full Findings List

- Cost Optimization: {count} findings
- Security: {count} findings
- Architecture: {count} findings
- CDK Best Practices: {count} findings

### Appendix B: Review Artifacts

- AWS Inventory: `.aws-reviews/{YYYY-MM-DD}/evidence/aws-inventory.md`
- CDK Structure: `.aws-reviews/{YYYY-MM-DD}/evidence/cdk-structure.md`
- Well-Architected Review: `.aws-reviews/{YYYY-MM-DD}/findings/architecture/well-architected-review.md`
- Cost Analysis: `.aws-reviews/{YYYY-MM-DD}/findings/cost/optimization-opportunities.md`
- Security Assessment: `.aws-reviews/{YYYY-MM-DD}/findings/security/security-assessment.md`
- CDK Analysis: `.aws-reviews/{YYYY-MM-DD}/findings/architecture/cdk-stack-analysis.md`

---

**Review Completed**: {YYYY-MM-DD HH:MM:SS}
**Reviewed By**: aws-cloud-engineer agent

<!-- markdownlint-disable-next-line MD040 -->
```

Save to: `${REVIEW_DIR}/reports/recommendations.md`

### Phase 8: Display Review Summary

Present review results to user:

```text
✓ AWS Infrastructure Review Complete!
======================================

Review Date: {YYYY-MM-DD}
Scope: {scope}

Overall Assessment:
-------------------
Infrastructure Maturity: {score}/10

Findings Summary:
-----------------
• Cost Optimization: {count} opportunities (${monthly_savings}/month potential)
• Security: {count} findings ({critical} critical, {high} high)
• Architecture: {count} recommendations
• CDK Best Practices: {count} improvements

Top 3 Priorities:
-----------------
1. {priority_1} - {impact} impact, {effort} effort
2. {priority_2} - {impact} impact, {effort} effort
3. {priority_3} - {impact} impact, {effort} effort

Cost Optimization Potential:
-----------------------------
Monthly Savings: ${monthly_savings}
Annual Savings: ${annual_savings}

Quick Wins (< 1 week):
• {quick_win_1}
• {quick_win_2}
• {quick_win_3}

Critical Security Findings:
---------------------------
• {critical_security_1}
• {critical_security_2}

Reports Generated:
------------------
✓ Recommendations: .aws-reviews/{YYYY-MM-DD}/reports/recommendations.md
✓ Cost Analysis: .aws-reviews/{YYYY-MM-DD}/findings/cost/optimization-opportunities.md
✓ Security Assessment: .aws-reviews/{YYYY-MM-DD}/findings/security/security-assessment.md
✓ Well-Architected Review: .aws-reviews/{YYYY-MM-DD}/findings/architecture/well-architected-review.md
✓ CDK Analysis: .aws-reviews/{YYYY-MM-DD}/findings/architecture/cdk-stack-analysis.md

Next Steps:
-----------
1. Review detailed recommendations: .aws-reviews/{YYYY-MM-DD}/reports/recommendations.md
2. Prioritize implementation based on impact/effort matrix
3. Create GitHub issues for high-priority items
4. Schedule follow-up review in 90 days
```

## Examples

### Example 1: Comprehensive Review

```bash
/aws-review

# Output:
AWS Infrastructure Review Initialized
=====================================
Scope: all (comprehensive)
Date: 2025-10-09
Reviewer: aws-cloud-engineer agent

Review Areas:
• Cost Optimization
• Security Best Practices
• Architecture (Well-Architected Framework)
• CDK Stack Review

Phase 1: AWS Environment Discovery...
✓ CDK stacks inventory complete (5 stacks found)
✓ AWS resources inventory complete (127 resources)

Phase 2: Well-Architected Framework Review...
✓ Operational Excellence: 7/10
✓ Security: 6/10
✓ Reliability: 8/10
✓ Performance Efficiency: 7/10
✓ Cost Optimization: 5/10
✓ Sustainability: 6/10

Phase 3: Cost Optimization Analysis...
✓ Found 23 optimization opportunities
✓ Potential savings: $1,247/month ($14,964/year)

Phase 4: Security Assessment...
✓ Found 8 security findings (1 critical, 3 high, 4 medium)

Phase 5: CDK Stack Analysis...
✓ Analyzed 5 CDK stacks
✓ Found 12 improvement opportunities

✓ AWS Infrastructure Review Complete!
Reports: .aws-reviews/2025-10-09/reports/recommendations.md
```

### Example 2: Cost-Focused Review

```bash
/aws-review --scope cost

# Output:
AWS Infrastructure Review Initialized
=====================================
Scope: cost
Date: 2025-10-09
Reviewer: aws-cloud-engineer agent

Phase 1: Cost Analysis...
✓ Right-sizing analysis complete
✓ Unused resources identified
✓ Reserved capacity recommendations generated
✓ Data transfer analysis complete
✓ Storage optimization opportunities identified

Cost Optimization Summary:
--------------------------
Immediate Savings (< 1 week): $427/month
  • Delete 3 unused Elastic IPs: $109/month
  • Right-size Lambda functions: $218/month
  • Delete unattached EBS volumes: $100/month

Short-term Savings (1-4 weeks): $520/month
  • Migrate gp2 to gp3 volumes: $180/month
  • Implement S3 lifecycle policies: $240/month
  • Right-size RDS instance: $100/month

Strategic Initiatives (> 1 month): $300/month
  • Reserved Instances for steady-state workloads: $300/month

Total Potential Savings: $1,247/month ($14,964/year)

✓ Cost Review Complete!
Report: .aws-reviews/2025-10-09/findings/cost/optimization-opportunities.md
```

### Example 3: Security-Focused Review

```bash
/aws-review --scope security

# Output:
AWS Infrastructure Review Initialized
=====================================
Scope: security
Date: 2025-10-09
Reviewer: aws-cloud-engineer agent

Phase 1: Security Assessment...
✓ IAM security review complete
✓ Network security analysis complete
✓ Data protection assessment complete
✓ Logging and monitoring review complete

Security Findings Summary:
--------------------------
Critical (Immediate Action): 1 finding
  • SEC-001: S3 bucket with public read access

High Priority (1 week): 3 findings
  • SEC-002: IAM role with overly permissive policy
  • SEC-003: RDS instance not encrypted at rest
  • SEC-004: Security group allows 0.0.0.0/0 on SSH port

Medium Priority: 4 findings
  • SEC-005: CloudTrail not enabled in all regions
  • SEC-006: Lambda functions without VPC configuration
  • SEC-007: Missing VPC Flow Logs
  • SEC-008: Old access keys (> 90 days)

✓ Security Review Complete!
Report: .aws-reviews/2025-10-09/findings/security/security-assessment.md
```

### Example 4: Specific Stack Review

```bash
/aws-review --scope ApiGatewayStack

# Output:
AWS Infrastructure Review Initialized
=====================================
Scope: ApiGatewayStack (specific stack)
Date: 2025-10-09
Reviewer: aws-cloud-engineer agent

Phase 1: Stack Discovery...
✓ Located CDK stack: lib/stacks/api-gateway-stack.ts
✓ Analyzed stack structure and resources

Phase 2: Stack Review...
✓ Cost analysis for stack resources
✓ Security review for API Gateway configuration
✓ Architecture review for stack design

Stack-Specific Findings:
------------------------
Cost Optimization (2 findings):
  • API Gateway logs retention too long (365 days -> 30 days): $15/month
  • Consider switching to HTTP API for lower cost: $45/month

Security (3 findings):
  • API Gateway throttling not configured
  • Missing WAF integration
  • API key rotation policy not implemented

Architecture (4 findings):
  • Stack should be split (API + Lambda concerns)
  • Custom domain not using Route53 alias
  • Missing environment-specific configuration
  • Lack of integration tests

✓ Stack Review Complete!
Report: .aws-reviews/2025-10-09/reports/ApiGatewayStack-review.md
```

## Configuration

### Review Configuration File

Create `.aws-reviews/review-config.json` for custom review settings:

```json
{
  "review_metadata": {
    "organization": "Your Organization",
    "environment": "production",
    "review_frequency": "quarterly",
    "last_review_date": "2025-07-01"
  },
  "cost_thresholds": {
    "high_impact": 500,
    "medium_impact": 100,
    "low_impact": 20
  },
  "excluded_resources": [
    "arn:aws:s3:::production-backups",
    "arn:aws:ec2:us-east-1:123456789012:instance/i-1234567890abcdef0"
  ],
  "well_architected_pillars": [
    "operational_excellence",
    "security",
    "reliability",
    "performance_efficiency",
    "cost_optimization",
    "sustainability"
  ],
  "security_standards": [
    "CIS_AWS_Foundations",
    "AWS_Best_Practices",
    "SOC2",
    "GDPR"
  ],
  "notification": {
    "enabled": true,
    "channels": ["slack", "email"],
    "recipients": ["#aws-reviews", "engineering@example.com"],
    "critical_only": false
  },
  "cdk_preferences": {
    "enforce_naming_convention": true,
    "require_removal_policies": true,
    "require_stack_tags": true,
    "max_resources_per_stack": 50
  }
}
```

## Error Handling

- **No CDK stacks found**: Display warning, offer to review deployed CloudFormation stacks only
- **AWS credentials not configured**: Skip live resource discovery, review CDK code only
- **Invalid stack name**: Display available stacks, prompt for correct name
- **Missing aws-cloud-engineer agent**: Display error, suggest creating agent with `/create-agent aws-cloud-engineer`
- **Agent invocation fails**: Log error, continue with available analyses (partial review)
- **Permission errors**: Display specific AWS permission requirements
- **Empty findings**: Display message indicating infrastructure is well-optimized

## Success Criteria

- AWS resource inventory collected (CDK and/or deployed resources)
- Cost optimization opportunities identified with estimated savings
- Security findings documented with severity and remediation steps
- Architecture recommendations aligned with Well-Architected Framework
- CDK best practices review completed (if in scope)
- Prioritized recommendations generated
- Implementation roadmap created
- All review artifacts saved to `.aws-reviews/{YYYY-MM-DD}/`

## Related Commands

- `/create-agent aws-cloud-engineer` - Create AWS cloud engineer agent if missing
- `/implement` - Implement recommendations from review findings
- `/security-audit` - Comprehensive security audit (broader than AWS security review)

## Integration with Workflow

### When to Run Reviews

**Regular Schedule:**

- Quarterly infrastructure reviews (comprehensive)
- Monthly cost optimization reviews
- After major deployments or architecture changes

**Triggered Reviews:**

- Before major cost commitments (Reserved Instances)
- Before compliance audits
- When cost anomalies detected
- After security incidents

**Pre-Production:**

- Before deploying new CDK stacks
- As part of PR review for infrastructure changes
- Before migrating to new AWS services

### Integration Points

1. **CI/CD Pipeline**:
   - Run cost-focused review on infrastructure PRs
   - Block deployments with critical security findings

2. **Issue Tracking**:
   - Create GitHub issues from high-priority findings
   - Track remediation progress
   - Link to review artifacts

3. **Cost Management**:
   - Feed recommendations into FinOps processes
   - Track savings from implemented recommendations
   - Measure infrastructure optimization over time

4. **Security Posture**:
   - Integrate findings with security monitoring
   - Track security score improvements
   - Feed into compliance reporting

## Notes

- **Comprehensive by default**: No arguments runs full infrastructure review
- **Agent-driven**: Delegates all analysis to aws-cloud-engineer for specialized expertise
- **Actionable recommendations**: Every finding includes specific remediation steps
- **Cost-aware**: Estimates potential savings for all cost optimizations
- **Well-Architected aligned**: Reviews against AWS best practices framework
- **Evidence-based**: Saves configuration snapshots for audit trail
- **Prioritized output**: Organizes recommendations by impact and effort
- **CDK-native**: Deep understanding of CDK patterns and best practices

---

**Design Philosophy**: Provide comprehensive, actionable AWS infrastructure review that combines cost optimization, security hardening, and architectural improvements with specific, implementable recommendations and clear ROI.
