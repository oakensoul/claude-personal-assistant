---
issue: 54
title: "Privacy & Security Analysis - Discoverability Commands"
analyst: privacy-security-auditor
date: 2025-10-20
status: complete
---

# Privacy & Security Analysis: Discoverability Commands

## 1. Domain-Specific Concerns

### Information Disclosure Risks

**Path Exposure**:

- Agent/command listings may expose filesystem structure (`~/.claude/agents/`, `./.claude/agents/`)
- Project-level agent discovery reveals project-specific configurations
- Skills catalog (177+ skills) exposes Claude Code capabilities inventory

**Sensitive Metadata in Frontmatter**:

- Agent descriptions may contain domain-specific context (company names, proprietary systems)
- Command descriptions may reveal internal workflows or business logic
- Args documentation may expose system architecture details

**Global vs. Project Context Boundary**:

- `/agent-list` scanning both global (`~/.claude/`) and project-level (`./.claude/`) creates risk of cross-contamination
- Project-specific agents may reveal confidential project names or domains
- Global agents in user home directory are personal/private, project agents are potentially shared

### Secret Management Concerns

**Low Risk but Validate**:

- Scripts should NOT read agent/command file CONTENT, only metadata (frontmatter)
- Ensure scripts don't accidentally log or expose agent definitions
- No credentials or API keys should be in agent/command frontmatter (validation needed)

### Privacy Compliance

**User Privacy**:

- Global agent listing reveals user's custom agents (personal workflow preferences)
- Should NOT sync global agent list to version control or share externally
- Project-level listings are safe to share within project team

**Access Control**:

- Skills listing (177+ skills from catalog) is public information (Claude Code feature)
- Agent listings respect filesystem permissions (if user can't read ~/.claude/, command won't expose it)
- No privilege escalation - scripts run with user's permissions

## 2. Stakeholder Impact

### Affected Parties

**End Users (Developers)**:

- **Value**: Improved discoverability reduces cognitive load, easier to find tools
- **Risk**: May accidentally share sensitive agent configurations when debugging

**Project Teams**:

- **Value**: Shared visibility into available project-specific agents/commands
- **Risk**: Project agents may reveal internal architecture or business domain

**AIDA Framework Maintainers**:

- **Value**: Standard discoverability interface, easier support/documentation
- **Risk**: None significant

### Value Proposition

**Positive**:

- Reduces friction for new users exploring AIDA capabilities
- Eliminates need to manually browse filesystem for available agents/commands
- Supports self-service learning (users discover tools without documentation deep-dive)
- Category filtering (`/command-list --category`) improves targeted discovery

**Negative**:

- Potential information disclosure if users share command output publicly
- May expose existence of private/proprietary agents in multi-tenant scenarios

## 3. Questions & Clarifications

### Security Questions

1. **Output Filtering**: Should `/agent-list` have a `--public-only` flag to filter out agents marked as private/confidential?
2. **Metadata Sanitization**: Should scripts strip potentially sensitive info from descriptions before display?
3. **Logging**: Will command output be logged? If so, ensure logs respect privacy boundaries.
4. **Error Messages**: If script encounters permission denied on agent directory, does error message expose path?

### Design Questions

1. **Global vs. Project Separation**: Should `/agent-list` display results in two separate sections (Global vs. Project) to clarify scope?
2. **Frontmatter Validation**: Should scripts validate that agent/command frontmatter doesn't contain obvious secrets (API keys, tokens)?
3. **Output Format**: Plain text? JSON? Markdown table? Consider machine-readable format for automation.
4. **Caching**: Will command output be cached? Privacy implications if cached results persist across projects.

### Assumptions to Validate

1. **No Content Parsing**: Confirming scripts only read frontmatter, NOT full agent definitions (which may contain sensitive logic)
2. **User-Level Execution**: Scripts run as user, not with elevated privileges
3. **No Network Calls**: Scripts are local-only, don't send data to external services
4. **Version Control Safety**: Command output never auto-committed to git

## 4. Recommendations

### High Priority (Must Implement)

**Frontmatter-Only Parsing**:

- Scripts MUST parse only YAML frontmatter, never full file content
- Use `sed -n '/^---$/,/^---$/p'` or equivalent to extract frontmatter safely
- Prevent accidental exposure of sensitive agent logic or implementation details

**Path Sanitization in Output**:

- Replace absolute paths with variables in output:

  - `~/.claude/agents/` → `${CLAUDE_CONFIG_DIR}/agents/`
  - `./.claude/agents/` → `${PROJECT_ROOT}/.claude/agents/`

- Prevents exposing usernames or sensitive directory structures

**Section Separation**:

- `/agent-list` output should clearly separate:

  - **Global Agents** (user-level, from `~/.claude/agents/`)
  - **Project Agents** (project-level, from `./.claude/agents/`)
  - **Built-in Agents** (AIDA framework defaults)

- Helps users understand scope and privacy boundaries

**Error Handling**:

- If permission denied on directory, generic error: "Unable to scan agent directory"
- DO NOT expose full paths in error messages (avoid leaking filesystem structure)

### Medium Priority (Should Implement)

**Privacy Markers**:

- Support optional `privacy: private` flag in agent/command frontmatter
- `/agent-list --public` filters to only agents without private flag
- Useful when sharing screenshots or documentation

**Output Format Options**:

- Default: Human-readable table/list
- `--json` flag: Machine-readable JSON for automation
- `--markdown` flag: Formatted markdown for documentation
- JSON format should include `scope` field (global/project/builtin)

**Validation Layer**:

- Script validates frontmatter doesn't contain obvious patterns:

  - API keys: `sk-[a-zA-Z0-9]`, `ghp_`, `AKIA`
  - Tokens: `token`, `secret`, `password` in values
  - Log warning if detected, don't fail command (false positives possible)

**Skills Catalog Source**:

- Confirm skills list (177+) comes from Claude Code public documentation, not scraped from private configs
- If scraped from user environment, apply same privacy controls as agents

### Low Priority (Nice to Have)

**Search/Filter**:

- `/agent-list --filter "aws"` - substring search in name/description
- `/command-list --category workflow` - category-based filtering (already planned)
- Improves discoverability without privacy impact

**Usage Statistics**:

- Track which agents/commands are most frequently listed (analytics)
- Privacy consideration: Don't track search terms or filter patterns

**Description Length Limits**:

- Truncate long descriptions in list view (full detail on demand)
- Prevents oversharing in casual screenshots

### Must Avoid

**Content Exposure**:

- NEVER output full agent definitions or command workflows
- NEVER parse or display anything beyond frontmatter metadata
- NEVER log sensitive paths or directory structures

**Privilege Escalation**:

- Scripts must NOT require sudo
- Scripts must NOT attempt to read directories outside user's permissions
- Scripts must NOT modify agent/command files (read-only operations)

**External Data Sharing**:

- No telemetry or analytics that report agent names/descriptions to external services
- No auto-sync of agent lists to cloud storage or shared locations
- No cross-user agent discovery (multi-user systems)

## Implementation Guidance

### Script Security Checklist

```bash

# list-agents.sh security requirements
- [ ] Parse only YAML frontmatter (sed/awk, not full file read)
- [ ] Sanitize paths in output (replace absolute with variables)
- [ ] Handle permission errors gracefully (no path exposure)
- [ ] Separate global vs. project agents in output
- [ ] Validate no obvious secrets in frontmatter (warn only)
- [ ] Exit cleanly on missing directories (no errors if .claude/ doesn't exist)
- [ ] Run with user permissions only (no sudo)
- [ ] Output respects terminal width (no line wrapping sensitive info)

```

### Frontmatter Parsing Pattern

```bash

# Safe frontmatter extraction

extract_frontmatter() {
  local file="$1"
  # Extract only content between --- markers
  sed -n '/^---$/,/^---$/p' "$file" | grep -v '^---$'
}

# Parse specific field

get_field() {
  local file="$1"
  local field="$2"
  extract_frontmatter "$file" | grep "^${field}:" | cut -d: -f2- | xargs
}

```

### Output Format Example

```text

=== Global Agents (User-Level) ===
${CLAUDE_CONFIG_DIR}/agents/

Name                    Description
----                    -----------
aws-cloud-engineer      AWS service expertise, CDK implementation patterns
product-manager         Product strategy and requirement analysis
tech-lead              Technical leadership and architecture decisions

=== Project Agents (Project-Level) ===
${PROJECT_ROOT}/.claude/agents/

Name                    Description
----                    -----------
analytics-engineer      dbt development, Snowflake, data modeling

=== Skills Catalog ===
177 skills available. Use claude-agent-manager to invoke skills.
(Run '/skill-list' for complete list)

```

## Privacy Risk Matrix

| Component | Risk Level | Mitigation |
|-----------|-----------|------------|
| Global agent listing | MEDIUM | Path sanitization, no content exposure |
| Project agent listing | LOW | Project-scoped, team-shared |
| Skills catalog | NONE | Public Claude Code feature |
| Command listing | LOW | Workflow commands are non-sensitive |
| Error messages | LOW | Generic errors, no path exposure |
| Script logging | MEDIUM | Disable verbose logging, sanitize if enabled |

## Compliance Notes

**GDPR Considerations**:

- Agent names/descriptions may contain user data (personal preferences)
- If system is multi-user, agent discovery must respect user boundaries
- No data processing or profiling based on agent usage patterns

**Data Minimization**:

- Only display metadata necessary for discoverability (name, description)
- Don't expose internal implementation details, file sizes, modification dates
- Don't track or store command usage beyond ephemeral session

**Transparency**:

- Document in command help text what data is collected/displayed
- Make clear distinction between global (private) and project (shared) agents

## Success Criteria (Privacy & Security)

- [ ] Scripts parse frontmatter only, never full file content
- [ ] Output sanitizes absolute paths to variables
- [ ] Global vs. project agents clearly distinguished in output
- [ ] Permission errors handled gracefully without path exposure
- [ ] No secrets accidentally displayed in output
- [ ] No privilege escalation or sudo requirements
- [ ] Scripts run successfully in restricted permission environments
- [ ] Error messages don't leak filesystem structure
- [ ] Optional privacy markers supported (`privacy: private`)
- [ ] Documentation warns users about sharing command output

## Related Security Documentation

- Shell script security guidelines: `docs/CONTRIBUTING.md` (shellcheck requirements)
- Privacy engineering: `~/.claude/agents/privacy-security-auditor/privacy-security-auditor.md`
- Secret detection patterns: (to be created in user-level knowledge base)
- AIDA privacy policy: (to be created)

---

**Analysis Complete**: Privacy and security concerns identified with clear mitigation strategies. Primary risks are information disclosure (path exposure, metadata leakage) and inadequate separation between global and project contexts. All risks are manageable with proper implementation of recommended controls.

**Next Steps**:

1. Implement frontmatter-only parsing in CLI scripts
2. Add path sanitization to output formatting
3. Include global/project separation in display logic
4. Add optional privacy markers to agent/command schema
5. Document privacy considerations in `/agent-list --help` output
