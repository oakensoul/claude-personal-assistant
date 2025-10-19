# Architecture Documentation: Issue #53 - Modular Installer Refactoring

**Issue**: #53
**Version**: v0.2.0
**Date**: 2025-10-18
**Status**: Proposed

---

## Quick Navigation

### Executive Summary

**Start here**: [ARCHITECTURE_SUMMARY.md](./ARCHITECTURE_SUMMARY.md)

Comprehensive overview of all architectural decisions, impact assessment, and recommendations.

**Key Highlights**:

- 85% reduction in installer complexity (625 → 150 lines)
- 85%+ I/O reduction via universal config aggregator
- Zero data loss guarantee via namespace isolation
- Enables dotfiles integration via reusable libraries

---

## Architecture Decision Records (ADRs)

### ADR-011: Modular Installer Architecture

**File**: [adr/adr-011-modular-installer-architecture.md](./adr/adr-011-modular-installer-architecture.md)

**Problem**: 625-line monolithic installer is unmaintainable and not reusable

**Decision**: Extract into 6 focused library modules + thin orchestrator

**Impact**:

- Testable (unit tests per module)
- Reusable (dotfiles can source libraries)
- Maintainable (single responsibility modules)

---

### ADR-012: Universal Config Aggregator Pattern

**File**: [adr/adr-012-universal-config-aggregator-pattern.md](./adr/adr-012-universal-config-aggregator-pattern.md)

**Problem**: Every command reads 5-7 config files independently (duplicate I/O)

**Decision**: Standalone script merges all configs with session-based caching

**Impact**:

- 85%+ I/O reduction (98%+ on warm cache)
- Single source of truth for configuration
- 47-98x performance improvement via caching

---

### ADR-013: Namespace Isolation for User Content Protection

**File**: [adr/adr-013-namespace-isolation-user-content-protection.md](./adr/adr-013-namespace-isolation-user-content-protection.md)

**Problem**: Installer overwrites user content during framework updates (CRITICAL SAFETY ISSUE)

**Decision**: Framework templates in `.aida/` subdirectory, user content in parent

**Impact**:

- Zero data loss guarantee
- Idempotent installer (safe to re-run)
- Clear ownership (framework vs user)

---

## C4 Architecture Diagrams

### Level 1: System Context

**File**: [diagrams/c4-context-aida-ecosystem.md](./diagrams/c4-context-aida-ecosystem.md)

**Audience**: All stakeholders

**Shows**: How AIDA installer fits into broader ecosystem

**Key Elements**:

- AIDA Framework, Dotfiles Repository, Claude Code
- Integration patterns (standalone, dotfiles-first, bi-directional)
- Namespace isolation structure

---

### Level 2: Container Architecture

**File**: [diagrams/c4-container-installer-system.md](./diagrams/c4-container-installer-system.md)

**Audience**: Technical stakeholders, developers

**Shows**: High-level technology choices and major components

**Key Containers**:

- `install.sh` (orchestrator)
- `installer-common` libraries (business logic)
- `aida-config-helper.sh` (config aggregator)
- Template system (commands, agents, skills)
- Target installation (`~/.claude/`, `~/.aida/`)

---

### Level 3: Component Architecture

**File**: [diagrams/c4-component-config-aggregator.md](./diagrams/c4-component-config-aggregator.md)

**Audience**: Developers, tech leads

**Shows**: Internal structure of universal config aggregator

**Key Components**:

- CLI Interface (argument parsing)
- Cache Manager (session-based caching)
- Config Reader (7 sources)
- Config Merger (priority resolution)
- Config Validator (schema validation)

---

## Architecture Patterns

### 1. Thin Orchestrator Pattern

**Definition**: Separate orchestration from business logic

**Implementation**:

- `install.sh`: Orchestrates (~150 lines)
- `lib/installer-common/*`: Implements (~1200 lines)

**Benefits**: Testable, reusable, maintainable

---

### 2. Universal Aggregator Pattern

**Definition**: Single script merges all config sources with caching

**Implementation**:

- `aida-config-helper.sh`: 7-tier merge + session cache
- Commands: Single call gets all config

**Benefits**: Single source of truth, 85%+ I/O reduction, extensible

---

### 3. Namespace Isolation Pattern

**Definition**: Separate framework content from user content

**Implementation**:

- `.aida/`: Framework (replaceable)
- `.aida-deprecated/`: Old templates (optional)
- Parent: User content (protected)

**Benefits**: Safety, idempotency, clarity

---

### 4. Session-Based Caching Pattern

**Definition**: Cache per shell session with checksum invalidation

**Implementation**:

- Cache: `/tmp/aida-config-cache-$$`
- Invalidation: Config file mtime checksum

**Benefits**: Isolated, fast (50-98x speedup), automatic cleanup

---

### 5. Priority Resolution Pattern

**Definition**: Merge configs with explicit priority hierarchy

**Implementation**:

- 7 sources with documented priority
- jq merging with `*` operator

**Benefits**: Predictable, flexible, debuggable

---

## Related Documentation

### PRD & Technical Spec

- [PRD.md](../PRD.md) - Product requirements and stakeholder analysis
- [TECH_SPEC.md](../TECH_SPEC.md) - Detailed technical specifications

### Implementation Files

**Library Modules** (to be created):

```text
lib/installer-common/
├── directories.sh (~200 lines)
├── templates.sh (~200 lines)
├── prompts.sh (~120 lines)
├── deprecation.sh (~180 lines)
├── summary.sh (~100 lines)
└── config.sh (~50 lines)

lib/
└── aida-config-helper.sh (~200 lines)
```

**Templates** (to be updated):

```text
templates/commands/    → Installed to ~/.claude/commands/.aida/
templates/agents/      → Installed to ~/.claude/agents/.aida/
templates/skills/      → Installed to ~/.claude/skills/.aida/
```

### Existing Architecture Docs (Need Updates)

1. **docs/architecture/ARCHITECTURE.md**
   - Add modular installer section
   - Add configuration system section
   - Add namespace isolation section

2. **docs/architecture/dotfiles-integration.md**
   - Update library sourcing section
   - Add config aggregator integration
   - Update installation flow

3. **docs/architecture/c4-system-context.md**
   - Merge with issue #53 context diagram

### New Architecture Docs (To Create)

1. **docs/architecture/configuration-system.md**
   - Universal config aggregator documentation
   - 7-tier priority resolution
   - Usage examples and debugging

2. **docs/architecture/installation-safety.md**
   - Namespace isolation explained
   - Safety guarantees
   - Migration guide (v0.1.x → v0.2.0)

---

## Implementation Roadmap

### Phase 1: Foundation (Week 1, 20h)

- Extract `prompts.sh`, `directories.sh`, `summary.sh`
- Refactor `install.sh` to orchestrator
- Basic unit tests
- **Milestone**: Modular architecture working

### Phase 2: Advanced Features (Week 2, 20h)

- Implement `templates.sh` with namespace isolation
- Implement `deprecation.sh` with frontmatter parsing
- Create `aida-config-helper.sh` with caching
- Integration tests
- **Milestone**: All features implemented

### Phase 3: CI/CD & Documentation (Week 3, 15h)

- Comprehensive test fixtures
- GitHub Actions updates
- Cross-platform validation
- Documentation updates
- **Milestone**: Production-ready

**Total Effort**: 55 hours (core implementation)

---

## Success Criteria

### Must Have (Blocking Release)

- ✅ Zero data loss: User content preserved during upgrades
- ✅ Modular architecture: `install.sh` < 150 lines, logic in modules
- ✅ Dotfiles integration: Libraries successfully sourced from dotfiles repo
- ✅ All tests pass: Docker tests + CI/CD tests on all platforms
- ✅ Namespace isolation: `.aida/` and `.aida-deprecated/` folders work correctly

### Should Have (Important)

- ✅ User confirmation before destructive operations
- ✅ Progress indicators for long operations
- ✅ Helpful error messages with recovery guidance
- ✅ Deprecation system working end-to-end
- ✅ Dev mode `git pull` auto-updates

### Performance Targets

- ✅ Config aggregator: <100ms cold, <5ms warm
- ✅ I/O reduction: 85%+ across all commands
- ✅ Installer complexity: 76%+ reduction (625 → 150 lines)
- ✅ Cache hit rate: >95% after first call

---

## Questions & Decisions

### Resolved Questions

**Q1: Dev mode variable substitution**

- **Problem**: Symlinked templates can't have substituted variables
- **Solution**: Universal config aggregator (runtime resolution)
- **Status**: ✅ RESOLVED

**Q2: Deprecation blocking**

- **Question**: Should installer refuse if deprecated templates conflict?
- **Decision**: Warn and skip (safest approach)
- **Status**: ✅ RESOLVED

**Q3: Version compatibility strictness**

- **Question**: How strict should version validation be?
- **Decision**: Hard fail (prevents bugs from mismatches)
- **Status**: ✅ RESOLVED

---

## Review Status

**Created**: 2025-10-18
**Author**: System Architect
**Status**: Awaiting approval

**Reviewers**:

- [ ] Tech Lead - ADR approval
- [ ] Platform Engineer - Implementation review
- [ ] DevOps Engineer - CI/CD impact
- [ ] QA - Testing strategy

**Approval Criteria**:

- ADRs are architecturally sound
- C4 diagrams accurately represent system
- Implementation plan is realistic
- Success criteria are measurable
- Risk mitigation is adequate

---

## Feedback & Iteration

### Open Questions for Reviewers

1. **Config aggregator caching**: Is session-based caching sufficient, or do we need persistent cache?
2. **Migration UX**: Is automatic migration sufficient, or should we require explicit opt-in?
3. **Testing coverage**: Is >90% unit test coverage realistic given shell script limitations?
4. **Documentation scope**: Should we create video walkthrough in addition to written docs?

### Next Steps After Approval

1. Update ADR index in `docs/architecture/decisions/README.md`
2. Create implementation branch: `53-modular-installer`
3. Begin Phase 1: Extract library modules
4. Weekly progress updates to stakeholders

---

**For questions or feedback, reference this documentation package and file issues on GitHub.**
