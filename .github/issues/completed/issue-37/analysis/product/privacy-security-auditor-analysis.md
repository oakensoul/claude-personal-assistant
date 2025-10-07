---
title: "Privacy & Security Analysis - Issue #37"
agent: "privacy-security-auditor"
issue: "Archive global agents and commands to templates folder"
date: "2025-10-06"
status: "analysis"
---

# Privacy & Security Analysis: Archive Global Agents and Commands

## Executive Summary

**CRITICAL RISK**: Archiving user-generated content from `~/.claude/` to public git repository poses significant privacy and security risks. User-specific data, learning patterns, and potentially sensitive information must be scrubbed before committing.

**Recommendation**: Proceed with MANDATORY scrubbing validation and create generic templates, not user-specific archives.

## 1. Domain-Specific Concerns

### Security Concerns

#### Path Disclosure (HIGH)

- 26 instances of username "oakensoul" in commands
- 7 instances in agents
- Absolute paths like `/Users/oakensoul/Developer/oakensoul/claude-personal-assistant/` reveal:
  - Username
  - Directory structure
  - Project organization patterns
- **Risk**: Information disclosure for social engineering or targeted attacks

#### User-Specific Content (MEDIUM)

- Knowledge directories contain learned patterns from actual usage
- Stakeholder templates may reference real organizations/people
- Preferences files capture personal working styles
- **Risk**: Leaking user behavior patterns and organizational relationships

#### Sensitive Markers (MEDIUM)

- Found references to: "internal", "confidential", "company", "client", "customer"
- These may be template placeholders OR actual sensitive references
- **Risk**: Accidental disclosure of business relationships

#### Command Scripts with Hardcoded Paths (HIGH)

- Commands contain examples with full absolute paths
- Git operations reference specific repository locations
- State file paths hardcoded to user directories
- **Risk**: Non-portable code that leaks user information

### Privacy Concerns

#### PII Detection Results

- Username embedded throughout (oakensoul)
- Home directory paths reveal system organization
- No email/phone/SSN detected in samples
- **Classification**: Low-level PII (username, paths) - requires scrubbing

#### Knowledge Base Content (CRITICAL)

- Agent knowledge directories contain LEARNED content
- This is not generic template data - it's accumulated from real usage
- May contain:
  - Project-specific patterns
  - Organization-specific standards
  - User-specific preferences
  - Historical decision context
- **Risk**: Publishing private learning/context as public template

#### Template vs. Archive Confusion (CRITICAL)

- Issue description says "archive" but repo is public framework
- Archives preserve user data; templates are generic starting points
- Current content in `~/.claude/` is USER-GENERATED, not framework template
- **Risk**: Fundamental misunderstanding of public/private boundary

## 2. Stakeholder Impact

### Affected Parties

#### Primary User (oakensoul)

- **Value**: Commits working examples as reference for others
- **Risk**: Exposes personal working patterns, directory structure, username
- **Impact**: Medium - username already public on GitHub, but patterns are private

#### Future AIDA Users

- **Value**: Get real-world examples of commands/agents in use
- **Risk**: May copy user-specific patterns that don't apply to them
- **Impact**: Low-Medium - could lead to confusion if templates too specific

#### Public Repository Consumers

- **Value**: See how framework is actually used
- **Risk**: None - they benefit from examples
- **Impact**: Positive if scrubbed properly

#### Security Researchers

- **Risk**: Could analyze patterns for vulnerabilities
- **Impact**: Low - security through obscurity is not a defense

### Value Proposition

#### Intended Value

- Document current command/agent implementations
- Provide examples for future development
- Preserve working configurations before refactoring

#### Actual Value

- Generic templates with placeholders: HIGH
- User-specific archives with real data: LOW (privacy cost > reference value)
- Knowledge directories as-is: NEGATIVE (leaks learning patterns)

### Risks & Downsides

#### Privacy Erosion

- Sets precedent for publishing user-generated content
- Blurs line between public framework and private usage
- Future users may not realize their `~/.claude/` could be public

#### Non-Portable Templates

- Hardcoded paths make templates unusable by others
- User-specific preferences aren't helpful as defaults
- Knowledge content is context-dependent

#### Maintenance Burden

- Scrubbed templates diverge from actual working versions
- Must maintain both private working copies and public templates
- Version drift between template and reality

## 3. Questions & Clarifications

### Missing Information

#### Intent Clarification

- [ ] Are these meant as TEMPLATES (generic starting points) or ARCHIVES (historical record)?
- [ ] Will `~/.claude/` continue to exist after archiving, or is this a migration?
- [ ] Should knowledge directories be included at all, or only agent definitions?

#### Scope Validation

- [ ] Which agents are "global" vs. "project-specific"?
  - Found 19+ agents, some appear domain-specific (larp-data-architect, mysql-data-engineer)
  - Are domain-specific agents meant for public framework or user-private?
- [ ] What about `.github/` content in `~/.claude/`?
  - Commands reference `.github/issues/` structures
  - Is this project-specific or framework-generic?

#### Knowledge Directory Decision

- [ ] Knowledge dirs contain LEARNED patterns - are these safe to publish?
- [ ] Should knowledge be:
  - **Option A**: Excluded entirely (safest)
  - **Option B**: Replaced with empty template structure
  - **Option C**: Scrubbed and genericized (most work, most value)

### Assumptions to Validate

#### Assumption 1: "Global agents should be in framework repo"

- **Validation needed**: Some agents are domain-specific (LARP, MySQL, Next.js)
- **Question**: Are these truly generic framework agents or user-specific tools?

#### Assumption 2: "Knowledge directories should be archived"

- **Validation needed**: Knowledge is LEARNED, not template
- **Question**: Should framework provide empty knowledge structure only?

#### Assumption 3: "Path substitution makes content generic"

- **Validation needed**: Paths are not the only user-specific content
- **Question**: Are we scrubbing content, or just paths?

#### Assumption 4: "Current ~/.claude/ is suitable for public use"

- **Validation needed**: Contains user-generated learning and patterns
- **Question**: Should we create NEW generic templates instead of archiving existing?

## 4. Recommendations

### Primary Recommendation: CREATE, Don't Archive

#### DO NOT archive user-generated content directly

- `~/.claude/` contains PERSONAL usage data, not generic templates
- Knowledge directories are LEARNED patterns, not starting points
- Preferences/patterns are USER-SPECIFIC, not framework defaults

#### DO create generic templates inspired by working examples

- Use existing agents/commands as REFERENCE
- Write NEW generic versions with placeholders
- Provide empty knowledge structure only
- Document what users should customize

### Scrubbing Requirements (If Archiving Anyway)

#### MANDATORY Scrubbing

1. **Path Sanitization (CRITICAL)**
   - Replace ALL absolute paths with variables:
     - `/Users/oakensoul/Developer/oakensoul/claude-personal-assistant/` → `${PROJECT_ROOT}`
     - `/Users/oakensoul/.claude/` → `${CLAUDE_CONFIG_DIR}`
     - `/Users/oakensoul/.aida/` → `${AIDA_HOME}`
   - Use relative paths where possible
   - Remove hardcoded repository names

2. **Username Removal (HIGH)**
   - Replace "oakensoul" with `${USER}` or `<username>`
   - Check for username in:
     - File paths
     - Git URLs
     - Example commands
     - Documentation

3. **Knowledge Content Review (CRITICAL)**
   - **Option A (RECOMMENDED)**: Exclude knowledge directories entirely
   - **Option B**: Include only empty directory structure
   - **Option C**: Manual review + genericization (labor-intensive)
   - DO NOT commit learned patterns without review

4. **Sensitive Marker Audit (MEDIUM)**
   - Search for: "company", "client", "internal", "confidential", "proprietary"
   - Verify these are PLACEHOLDERS, not actual references
   - Replace real names with generic placeholders

#### Scrubbing Validation Process

```bash
# Pre-commit scrubbing check
templates_scrubbing_check() {
  # Check for absolute paths
  grep -r "/Users/" templates/ && echo "ERROR: Absolute paths found"

  # Check for usernames
  grep -r "oakensoul" templates/ && echo "ERROR: Username found"

  # Check for potential PII
  grep -rE '\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b' templates/

  # Check for sensitive markers
  grep -ri "internal\|confidential\|proprietary" templates/

  # Validate variable substitution
  grep -r '\${PROJECT_ROOT}\|\${CLAUDE_CONFIG_DIR}\|\${AIDA_HOME}' templates/
}
```

### Content Categorization

#### Category 1: Safe to Archive (with path scrubbing)

- Command structures and workflows
- Agent role definitions (not knowledge)
- Empty directory hierarchies

#### Category 2: Requires Review

- Stakeholder templates (may reference real orgs)
- Preference examples (may be too specific)
- Pattern documentation (may reveal internal practices)

#### Category 3: Exclude from Archive

- Knowledge base learned content
- User-specific preferences
- Project-specific configurations
- Historical decision context

### Implementation Approach

#### Phase 1: Prepare Generic Templates

1. Review each command/agent in `~/.claude/`
2. Identify generic vs. user-specific elements
3. Create NEW generic versions in `templates/`
4. Add placeholders and documentation for customization

#### Phase 2: Scrubbing Validation

1. Run automated scrubbing checks
2. Manual review of all content
3. Validate no PII, paths, or sensitive data
4. Test template usability with fresh install

#### Phase 3: Documentation

1. README explaining templates vs. user config
2. Instructions for customizing templates
3. Privacy policy for `~/.claude/` vs. framework
4. Clear separation of public/private data

#### Phase 4: Ongoing Privacy

1. Add pre-commit hook for scrubbing validation
2. Document what NEVER goes in public repo
3. Add `.gitignore` patterns for sensitive files
4. Create privacy review checklist for contributors

### What to Avoid

#### DO NOT

- ✗ Commit knowledge directories with learned content
- ✗ Publish user-specific preferences as defaults
- ✗ Include absolute paths or usernames
- ✗ Archive without scrubbing validation
- ✗ Blur line between template and user data
- ✗ Set precedent for publishing `~/.claude/` content
- ✗ Create templates that only work for one user
- ✗ Include git history with pre-scrubbing versions

#### DO

- ✓ Create generic templates with placeholders
- ✓ Provide empty knowledge structure only
- ✓ Use variable substitution for all paths
- ✓ Document customization points clearly
- ✓ Maintain separation of public/private
- ✓ Validate scrubbing before commit
- ✓ Design for portability across users
- ✓ Preserve user privacy by default

## 5. Security Checklist

### Pre-Commit Validation

- [ ] No absolute paths (all use variables)
- [ ] No usernames in content
- [ ] No email addresses
- [ ] No API keys or tokens
- [ ] No company/client names
- [ ] Knowledge dirs excluded or empty
- [ ] Preferences genericized
- [ ] Examples use placeholders
- [ ] Documentation explains customization
- [ ] Templates tested on clean install

### Privacy Validation

- [ ] No PII (name, email, phone, address)
- [ ] No learned patterns from real usage
- [ ] No business relationships revealed
- [ ] No user behavior patterns
- [ ] No system information disclosed
- [ ] No project-specific context
- [ ] No historical decision data
- [ ] Templates are truly generic

### Portability Validation

- [ ] Templates work for any user
- [ ] No hardcoded paths
- [ ] No user-specific assumptions
- [ ] Clear customization instructions
- [ ] Variable substitution documented
- [ ] Cross-platform compatible
- [ ] No OS-specific assumptions

## Conclusion

This issue requires careful distinction between:

1. **Public Framework Templates** (generic, portable, safe) - BELONGS in repo
2. **User-Generated Archives** (specific, learned, private) - DOES NOT belong in repo

**Recommendation**: Transform user content into generic templates rather than archiving as-is. Protect user privacy by excluding learned knowledge and scrubbing all user-specific data.

**Critical Action**: Establish clear privacy policy for what content belongs in public framework vs. private user config before proceeding with any archiving.
