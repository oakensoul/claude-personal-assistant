---
title: "System Architect - claude-personal-assistant Configuration"
project: "claude-personal-assistant"
agent: "system-architect"
agent_version: "1.0.0"
created: "2025-10-15"
last_updated: "2025-10-15"
scope: "project-only"
---

# System Architect - claude-personal-assistant

Project-specific architectural context and documentation pointers for the AIDA (Agentic Intelligence Digital Assistant) framework.

## Project Type

**Detected Type**: Software

**Technology Stack**:

- Shell scripting (Bash)
- YAML configuration
- Markdown documentation
- GitHub Actions (CI/CD)
- Docker (testing)
- Pre-commit hooks (quality)

## Architecture Patterns in Use

**Documented patterns**:

- [x] Template-based code generation
- [x] Two-tier architecture (user-level + project-level)
- [x] Configuration over code
- [x] Modular plugin system
- [ ] Microservices
- [ ] Event-driven
- [ ] Domain-driven design
- [ ] Layered architecture

**Framework-Specific**:

- Template pattern for agents, commands, and knowledge
- Two-tier knowledge architecture (user-level + project-level)
- Configuration-driven agent definitions
- Pluggable personalities and agents

## Architecture Documentation

**Recommended Structure**:

```text
docs/architecture/
├── c4-system-context.md      # System context diagram
├── c4-container.md            # Container diagram
├── c4-component.md            # Component diagram (optional)
├── decisions/                 # Architecture Decision Records
│   ├── README.md             # ADR index
│   ├── adr-001-*.md          # Individual ADRs
│   └── adr-002-*.md
└── specifications/
    ├── non-functional-requirements.md
    └── integration-specifications.md
```

**Detected Documentation**:

- docs/architecture/ARCHITECTURE.md
- docs/architecture/c4-system-context.md
- docs/architecture/decisions/README.md
- docs/architecture/decisions/adr-002-two-tier-agent-architecture.md
- docs/architecture/dotfiles-integration.md

**TODO**: Create missing architecture documentation:

- [ ] C4 container diagram
- [ ] C4 component diagram (optional)
- [x] Architecture Decision Records (ADRs) - started
- [ ] Non-functional requirements specification
- [ ] Integration specifications
- [ ] Security requirements specification

**Note**: ADR-002 exists. Additional ADRs should be created for:

- Shell script framework choice
- YAML configuration system
- GNU Stow integration
- Template variable substitution strategy

## Integration Points

**External System Integrations**:

- **Claude AI**: Conversational AI engine via Claude Code CLI
- **Obsidian**: Optional integration for daily notes and project tracking
- **GNU Stow**: Dotfiles management and installation
- **GitHub**: Issue tracking, PR workflow automation
- **Docker**: Cross-platform testing environments

**Integration Architecture**:

- AIDA works standalone (does not require dotfiles)
- Dotfiles can optionally install AIDA
- Bidirectional integration possible
- See: docs/architecture/dotfiles-integration.md

## Non-Functional Requirements

**TODO**: Define NFRs for this project:

- **Scalability**: Not applicable (single-user CLI tool)
- **Performance**:
  - Installation: < 30 seconds (target)
  - Command execution: < 2 seconds for most commands
- **Security**:
  - No secrets in repository
  - File permissions: 600 for user configs
  - Template validation before installation
  - Privacy scrubbing for knowledge sync
- **Reliability**:
  - Error handling: `set -euo pipefail` in all scripts
  - Pre-commit hooks for quality gates
  - Cross-platform testing (macOS, Linux)
- **Maintainability**:
  - Shellcheck compliance (zero warnings)
  - YAML lint compliance
  - Markdown lint compliance
  - Semantic versioning

## Project Structure

**Key Directories**:

```text
claude-personal-assistant/
├── .claude/                    # Project-level agent configs
│   └── agents-global/         # Two-tier agent project configs
├── .github/                   # CI/CD and issue templates
│   ├── testing/              # Docker-based testing
│   └── workflows/            # GitHub Actions
├── docs/                      # Documentation
│   ├── architecture/         # Architecture docs and ADRs
│   └── CONTRIBUTING.md       # Contribution guidelines
├── lib/                       # Shared library functions
│   └── installer-common/     # Installation utilities
├── scripts/                   # Utility scripts
│   └── validate-templates.sh # Template validation
├── templates/                 # Installation templates
│   ├── agents/              # Agent templates
│   ├── commands/            # Command templates
│   └── documents/           # Document templates
├── install.sh                 # Main installation script
├── CLAUDE.md                  # Project instructions for Claude
└── README.md                  # User-facing documentation
```

**Installation Model**:

- Framework installs to `~/.aida/` (system-level)
- User configuration generates in `~/.claude/` (user-level)
- Main entry point generated at `~/CLAUDE.md`
- Dev mode uses symlinks for live editing

## Technology Decisions

**Core Framework**:

- **Language**: Bash (macOS/Linux compatibility)
- **Configuration**: YAML (agents, personalities, commands)
- **Templating**: Sed-based variable substitution
- **Version Control**: Git

**Quality Tools**:

- **Testing**: Pre-commit hooks (shellcheck, yamllint, markdownlint)
- **CI/CD**: GitHub Actions
- **Validation**: Template variable validation script

**Integrations**:

- **Obsidian**: Daily notes, project tracking, dashboard views
- **GNU Stow**: Manages dotfiles integration
- **GitHub**: Issue tracking, PR workflow
- **Docker**: Cross-platform testing (Ubuntu, macOS)

## Architecture References

**Documentation**:

- Architecture docs: `docs/architecture/`
- README: `README.md`
- Project instructions: `CLAUDE.md`
- Contributing guide: `docs/CONTRIBUTING.md`

**Related Agents**:

- **tech-lead**: Implementation standards and code review
- **shell-script-specialist**: Shell scripting best practices
- **configuration-specialist**: YAML configuration design
- **qa-engineer**: Testing strategies and validation
- **integration-specialist**: External tool integration patterns

## Cross-Cutting Concerns

**Error Handling**:

- All scripts use `set -euo pipefail`
- User input validation in all scripts
- Template variable validation before installation
- Exit codes for all commands

**Testing Strategy**:

- Pre-commit hooks (static analysis)
- Docker-based integration tests
- Manual testing on macOS and Linux
- Template validation script

**Documentation**:

- Markdown everywhere with frontmatter
- Inline code comments in shell scripts
- YAML frontmatter in agents and commands
- Architecture docs in docs/architecture/
- User-facing README files

## Version History

**Current Installation**: v1.0.0 (upgraded 2025-10-15)

- Updated to standardized two-tier agent format
- Enhanced project scanning and context detection
- Improved architecture documentation references
- Added cross-cutting concerns section
- Added project structure overview
