---

slug: operations-commands
title: "Create /incident, /debug, /security commands - operations management"
type: feature
milestone: v0.1.0
labels: foundational, commands, operations
estimated_effort: 8
status: draft
created: 2025-10-10
depends_on: ["versioning-system"]

---

# Create /incident, /debug, /security commands - operations management

## Problem

Current operations commands exist but need consolidation and enhancement:

- `incident` - exists but needs subcommands
- `debug` - exists but needs subcommands
- Multiple security commands scattered: `security-audit`, `compliance-check`, `pii-scan`

Need organized, comprehensive operations commands with proper structure.

## Solution

Create three consolidated operations commands with subcommands.

### `/incident` Command

```bash

/incident start [type]          # Start incident (ops, security, data, defect)
/incident status                # Show active incidents
/incident update [notes]        # Update incident status
/incident resolve               # Resolve incident
/incident postmortem            # Generate postmortem

```

**Incident Types:**

- `ops` - Operational incidents (outages, performance)
- `security` - Security incidents (breaches, vulnerabilities)
- `data` - Data quality/pipeline incidents
- `defect` - Critical bug/defect incidents

**Features:**

- Severity levels (P0, P1, P2, P3)
- Timeline tracking
- Automated postmortem generation
- Integration with issue tracking

### `/debug` Command

```bash

/debug production               # Debug production issues
/debug local                    # Debug local development
/debug data                     # Debug data pipelines (dbt, SQL)
/debug performance              # Debug performance problems
/debug test                     # Debug test failures

```

**Production Debugging:**

- Log analysis
- Error correlation
- Service health checks
- Dependency analysis

**Data Debugging:**

- dbt test failures
- SQL query problems
- Data quality issues
- Pipeline failures

### `/security` Command

```bash

/security audit                 # Full security audit
/security compliance [framework] # Compliance checks
/security pii [domain]          # PII scanning
/security scan                  # Quick security scan
/security report                # Generate security report

```

**Frameworks:**

- GDPR
- HIPAA
- SOC 2
- ISO 27001
- Custom policies

**Features:**

- Cross-platform security checks
- Data privacy validation
- Access control review
- Vulnerability scanning

## Implementation Tasks

- [ ] **Design `/incident` command**
  - Incident types and severities
  - Timeline tracking
  - Postmortem generation
  - Integration with forges

- [ ] **Implement `/incident start`**
  - Interactive prompts
  - Incident type selection
  - Severity assignment
  - Initial context capture

- [ ] **Implement `/incident status` and `/incident update`**
  - Show active incidents
  - Update timeline
  - Track actions taken
  - Communication helpers

- [ ] **Implement `/incident resolve` and `/incident postmortem`**
  - Incident resolution workflow
  - Generate comprehensive postmortem
  - Root cause analysis
  - Action items extraction

- [ ] **Enhance `/debug` command**
  - Add subcommand routing
  - Production debugging workflow
  - Local debugging workflow
  - Data pipeline debugging
  - Test failure debugging

- [ ] **Implement debug agent orchestration**
  - Intelligent agent selection
  - Multi-agent coordination
  - Context passing between agents
  - Results aggregation

- [ ] **Consolidate security commands**
  - Merge `security-audit`, `compliance-check`, `pii-scan`
  - Add subcommand routing
  - Unified security reporting

- [ ] **Implement `/security audit`**
  - Comprehensive security checks
  - Multi-framework support
  - Scope selection
  - Report generation

- [ ] **Implement `/security compliance`**
  - Framework selection
  - Compliance validation
  - Gap analysis
  - Remediation recommendations

- [ ] **Implement `/security pii`**
  - Domain filtering
  - PII detection
  - False positive handling
  - Remediation tracking

- [ ] **Add comprehensive error handling**
  - Missing tools/dependencies
  - Permission errors
  - Network failures
  - Invalid configurations

- [ ] **Documentation**
  - Usage examples for each command
  - Incident response playbooks
  - Debugging guides
  - Security best practices

## Success Criteria

- [ ] `/incident` tracks incidents end-to-end
- [ ] `/debug` handles all debugging scenarios
- [ ] `/security` consolidates all security operations
- [ ] All commands work on macOS and Linux
- [ ] Tests pass for all subcommands
- [ ] Documentation is comprehensive

## Testing Scenarios

```bash

# Test incident management
/incident start ops --severity=P0 --title="Database down"
/incident status
/incident update "Identified root cause"
/incident resolve
/incident postmortem

# Test debugging
/debug production --service=api
/debug data --model=user_metrics
/debug test --file=test_auth.py

# Test security
/security audit --scope=full
/security compliance gdpr
/security pii --domain=finance

```

## Dependencies

- Requires: versioning-system (#1)
- Blocks: None (can be developed in parallel with other commands)

## Replaces v1 Commands

- Enhances existing `incident` command
- Enhances existing `debug` command
- `security-audit` → `/security audit`
- `compliance-check` → `/security compliance`
- `pii-scan` → `/security pii`

## Notes

- Focus on operational reliability
- Comprehensive incident tracking critical
- Security commands must be thorough
- Debugging workflows need intelligent agent orchestration
- All operations commands should generate actionable reports
