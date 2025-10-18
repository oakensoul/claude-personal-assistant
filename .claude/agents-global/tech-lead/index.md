---
title: "Tech Lead - AIDA Project Instructions"
description: "AIDA-specific technical requirements and standards"
category: "project-agent-instructions"
tags: ["aida", "tech-lead", "project-context"]
last_updated: "2025-10-06"
status: "active"
---

# AIDA Tech Lead Instructions

Project-specific technical standards and requirements for the AIDA framework.

## Project Technical Standards

### Code Quality (Non-Negotiable)

1. **Everything Must Pass Linting**
   - No half-ass or lazy implementations
   - No exceptions without explicit justification
   - All linters must pass before commit

2. **Code Must Be Composable**
   - Modular design required
   - Reusable components preferred
   - Dependencies clearly defined

3. **Container-Based Testing Required**
   - No screwing up local dev environments
   - No global (-g) environment pollution
   - Test in isolation always

### Agent Architecture Standards

#### Agent Creation Guidelines

**Generic User-Level Agents (Preferred)**:

- Should be made generic when possible
- Stored in `~/.claude/agents/`
- Reusable across projects
- Domain expertise, not project-specific

**Project-Specific Agents (When Required)**:

- Only when truly project-specific
- Stored in `.claude/agents/`
- Clear documentation why project-specific
- Consider genericizing in future

#### Commands Standards

1. **Default Agent Assignment**
   - Every command must have a default agent assigned
   - Agent should match command domain
   - Document agent assignment rationale

2. **Workflow Chain Communication**
   - Workflows must communicate their "next" commands
   - Clear chain documentation required
   - Error states must suggest recovery commands

### Technology Stack

**Primary Stack**:

- Shell/Bash scripting (Bash 3.2+ for macOS compatibility)
- Git (version control)
- Docker (containerization and testing)
- GitHub Actions (CI/CD automation)

**Architecture Pattern**:

- Modular/Plugin architecture
- Agent-based system design
- Personality system overlay

### Testing Requirements

#### Container Testing (Required)

```bash
# All tests must run in containers
docker-compose -f .github/testing/docker-compose.yml up --build

# Example test structure:
.github/testing/
├── docker-compose.yml
├── test-install.sh
├── Dockerfile.macos-bash3
└── Dockerfile.linux-latest
```

#### Test Coverage Standards

1. **Installation Tests**
   - Normal install
   - Dev mode install
   - Clean environment validation
   - Upgrade scenarios

2. **Linting Tests**
   - shellcheck (all shell scripts)
   - yamllint (all YAML files)
   - markdownlint (all docs)
   - actionlint (GitHub Actions)

3. **Integration Tests**
   - Agent loading
   - Command execution
   - Personality switching
   - Dotfiles integration (optional)

### Code Review Standards (AIDA-Specific)

Beyond user-level preferences, AIDA code reviews must verify:

1. **Modularity**: Can this be extracted/reused?
2. **Agent Design**: Is agent assignment appropriate?
3. **Container Compatibility**: Tested in isolation?
4. **Documentation**: Both how-to and integration docs updated?
5. **License Compliance**: AGPL-3.0 compatible?
6. **Semantic Versioning**: Correct version bump?

### Technical Specifications for AIDA

When writing tech specs for AIDA features:

#### Required Sections

1. **Agent Architecture**
   - Which agents involved?
   - New agents needed?
   - Agent interaction patterns

2. **Command Design**
   - Command syntax
   - Default agent assignment
   - Workflow chain integration
   - Error handling and recovery

3. **Personality System Impact**
   - Does this affect personality behavior?
   - Personality-specific responses needed?
   - Customization points

4. **Dotfiles Integration**
   - Standalone behavior
   - Integrated behavior (with dotfiles)
   - Migration path for users

5. **Testing Strategy**
   - Container test scenarios
   - Linting requirements
   - Integration test cases

6. **Documentation Requirements**
   - How-to guide updates
   - Integration guide updates
   - API documentation (if applicable)

### Risk Management (AIDA-Specific)

#### Technical Risks to Watch

1. **Agent Complexity**
   - Risk: Too many agents, confusion
   - Mitigation: Clear agent domain separation

2. **Personality System Fragility**
   - Risk: Personalities break with core changes
   - Mitigation: Stable personality API contract

3. **Dotfiles Coupling**
   - Risk: Tight coupling prevents standalone use
   - Mitigation: Always design standalone-first

4. **License Violations**
   - Risk: Incompatible dependencies
   - Mitigation: License audit in CI/CD

5. **Cross-Platform Compatibility**
   - Risk: macOS-specific assumptions
   - Mitigation: Test on Linux containers

### Decision Framework

#### When to Create New Command

✓ **Yes** if:

- Distinct user workflow
- Clear default agent mapping
- Fits workflow chains
- Passes container tests

✗ **No** if:

- Can extend existing command
- No clear agent ownership
- Breaks existing workflows
- Requires global state

#### When to Modify Core vs. Plugin

**Core Modification** if:

- Affects all users
- Changes fundamental behavior
- Semantic version bump required

**Plugin/Extension** if:

- Optional functionality
- User-specific customization
- Experimental feature

### CI/CD Requirements

All AIDA changes must pass:

```yaml
# .github/workflows/tests.yml
- shellcheck (all .sh files)
- yamllint --strict (all .yml files)
- markdownlint (all .md files)
- actionlint (all workflows)
- docker-compose test suite
- install.sh validation
```

### Integration Notes

- **User-level Tech Lead preferences**: Load from `~/.claude/agents/tech-lead/`
- **Project-specific standards**: This file
- **Combined approach**: User philosophy + AIDA requirements

## AIDA-Specific Best Practices

1. **Shell Script Standards**
   - Use `set -euo pipefail`
   - Pass shellcheck with zero warnings
   - Bash 3.2+ compatibility for macOS
   - Comprehensive error messages

2. **Agent Implementation**
   - Prefer generic over project-specific
   - Clear knowledge base structure
   - Documented decision frameworks
   - Testable in isolation

3. **Command Implementation**
   - Explicit agent assignment
   - Workflow chain documentation
   - Container-testable
   - Error states with next-step guidance

4. **Documentation Requirements**
   - Dual-track docs (how-to + integration)
   - Code examples required
   - Troubleshooting sections
   - Migration guides for breaking changes

---

**Last Updated**: 2025-10-06 via /workflow-init
