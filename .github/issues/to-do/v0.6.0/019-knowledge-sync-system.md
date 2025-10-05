---
title: "Implement knowledge sync and scrubbing system"
labels:
  - "type: feature"
  - "priority: p2"
  - "effort: xlarge"
  - "milestone: 0.6.0"
  - "epic: needs-breakdown"
---

# Implement knowledge sync and scrubbing system

> **⚠️ Epic Breakdown Required**: This is an XLarge effort issue that should be broken down into smaller, more atomic issues before milestone work begins. This breakdown should happen during sprint planning for v0.6.0.

## Description

Create the knowledge sync system that extracts learnings and patterns from work projects and stores them in the personal knowledge management system (Obsidian) while scrubbing sensitive information. This allows users to build a knowledge base from proprietary work without leaking sensitive data.

## Suggested Breakdown

When breaking down this epic, consider creating separate issues for:

1. **Scrubbing Rules Engine** - Define and implement data scrubbing rules
2. **Scrubbing Rule Profiles** - Predefined profiles for work/OSS/learning contexts
3. **Knowledge Discovery System** - Identify documentation and patterns to extract
4. **Sensitive Data Detection** - Identify company names, IPs, credentials, etc.
5. **Data Replacement System** - Replace sensitive data with placeholders
6. **PKM Storage Integration** - Create and organize Obsidian notes
7. **Dry-Run and Preview Mode** - Safe testing before actual sync
8. **Review Interface** - Review changes before committing
9. **Audit System** - Track what was synced and scrubbed
10. **Legal & Privacy Documentation** - Guidelines and best practices

Each sub-issue should be scoped to Small or Medium effort.

## Acceptance Criteria

- [ ] Scrubbing rules engine defined and implemented
- [ ] Knowledge discovery system identifies documentation
- [ ] Scrubbing engine replaces sensitive data with placeholders
- [ ] PKM storage system creates Obsidian notes
- [ ] Safety features: dry-run mode, review before save, audit tool
- [ ] CLI command `${ASSISTANT_NAME} sync-knowledge` implemented
- [ ] Command supports flags: `--dry-run`, `--profile [work|oss|learning]`, `--review`
- [ ] Documentation explains legal/privacy considerations
- [ ] Documentation provides examples and best practices

## Implementation Notes

### Scrubbing Rules Engine

Define what to scrub and what to preserve:

```yaml
# scrubbing-profiles/work.yaml
---
profile_name: "work"
description: "Scrub work project knowledge for personal PKM"

scrub_patterns:
  # Company and client information
  company_names:
    - pattern: '\b(CompanyName|COMPANY|OurCompany)\b'
      replacement: '[COMPANY]'
    - pattern: '\b(ClientName|CLIENT_A)\b'
      replacement: '[CLIENT]'

  # People
  names:
    - pattern: '@(firstname\.lastname|flastname)'
      replacement: '@[COLLEAGUE]'
    - pattern: '\b([A-Z][a-z]+ [A-Z][a-z]+)\b'  # Names in docs
      replacement: '[PERSON]'
      whitelist:  # Don't scrub these
        - "React"
        - "TypeScript"
        - "Next.js"

  # URLs and endpoints
  internal_urls:
    - pattern: 'https?://[^/]*\.company\.com[^\s]*'
      replacement: 'https://[INTERNAL-URL]'
    - pattern: 'https?://internal\.[^\s]*'
      replacement: 'https://[INTERNAL]'

  # API keys and secrets (just in case)
  secrets:
    - pattern: '\b[A-Z0-9]{32,}\b'
      replacement: '[API-KEY]'
    - pattern: 'password\s*[:=]\s*\S+'
      replacement: 'password: [REDACTED]'

  # Email addresses
  emails:
    - pattern: '[a-zA-Z0-9._%+-]+@company\.com'
      replacement: '[EMAIL]'

  # IP addresses
  ips:
    - pattern: '\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b'
      replacement: '[IP-ADDRESS]'

preserve_patterns:
  # Technology names and terms
  technologies:
    - React
    - TypeScript
    - PostgreSQL
    - AWS
    - Docker
    - Kubernetes
    # ... (comprehensive list)

  # Public URLs
  public_urls:
    - github.com
    - stackoverflow.com
    - npmjs.com
    - docs.*
    # ... (known public domains)

  # Generic patterns
  generic:
    - pattern: '(architecture|pattern|solution|approach|technique)'
    - pattern: '(problem|issue|challenge|bug)'
```

### Knowledge Discovery

Scan project for valuable documentation:

```bash
discover_knowledge() {
    local project_dir="$1"

    info "Discovering knowledge in $project_dir..."

    # Find documentation
    local docs=(
        "README.md"
        "ARCHITECTURE.md"
        "ADR/*.md"           # Architecture Decision Records
        "docs/**/*.md"
        "wiki/**/*.md"
    )

    # Find problem-solution pairs
    grep -r "TODO\|FIXME\|NOTE\|HACK" "$project_dir" --include="*.md"

    # Find code patterns
    # - Custom hooks (if React)
    # - Utility functions
    # - Configuration patterns
}
```

### Scrubbing Engine

```bash
scrub_content() {
    local file="$1"
    local profile="$2"
    local output_file="$3"

    # Load scrubbing profile
    local profile_config="$AIDE_FRAMEWORK/scrubbing-profiles/${profile}.yaml"

    # Apply scrubbing rules
    # 1. Replace company names
    # 2. Replace people names
    # 3. Replace internal URLs
    # 4. Replace secrets
    # 5. Replace emails and IPs

    # Preserve technology names
    # Preserve code patterns
    # Preserve problem-solution structure

    # Generate scrubbed version
    # Show diff for review
}
```

### PKM Storage

```bash
store_in_pkm() {
    local scrubbed_file="$1"
    local category="$2"

    # Convert to Obsidian markdown
    # Add frontmatter
    # Add tags
    # Create backlinks
    # Organize by category

    local vault="$HOME/Knowledge/Obsidian-Vault"
    local dest="$vault/Learnings/$category/$(basename "$scrubbed_file")"

    # Add metadata
    cat > "$dest" << EOF
---
title: "[Topic]"
source: "[Project] (scrubbed)"
category: "$category"
tags: [learning, pattern, scrubbed]
date: $(date +%Y-%m-%d)
---

# [Topic]

> **Source**: Work project (confidential details removed)
> **Extracted**: $(date +%Y-%m-%d)

$(cat "$scrubbed_file")

---

**Related Notes**:
- [[Pattern - Similar Topic]]
- [[Learning - Related Concept]]
EOF

    # Update index
    update_knowledge_index "$category" "$dest"
}
```

### Safety Features

```bash
# Dry-run mode
sync_knowledge() {
    local project="$1"
    local profile="${2:-work}"
    local dry_run="${3:-false}"

    if [[ "$dry_run" == "true" ]]; then
        info "DRY RUN MODE - No files will be modified"
    fi

    # Discover knowledge
    local docs=$(discover_knowledge "$project")

    # Scrub each document
    for doc in $docs; do
        local scrubbed="/tmp/scrubbed-$(basename "$doc")"

        scrub_content "$doc" "$profile" "$scrubbed"

        # Show diff
        info "Changes for $doc:"
        diff -u "$doc" "$scrubbed" | head -50

        if [[ "$dry_run" != "true" ]]; then
            read -p "Save to PKM? (y/N): " -n 1 -r
            echo ""
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                store_in_pkm "$scrubbed" "patterns"
            fi
        fi
    done
}

# Audit tool
audit_scrubbing() {
    local pkm_file="$1"

    info "Auditing $pkm_file for leaked sensitive data..."

    # Check for common sensitive patterns
    local issues=0

    # Check for email addresses
    if grep -E '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' "$pkm_file"; then
        warn "Found potential email addresses"
        ((issues++))
    fi

    # Check for URLs with company domains
    if grep -E 'https?://[^/]*\.mycompany\.com' "$pkm_file"; then
        warn "Found potential internal URLs"
        ((issues++))
    fi

    # Check for long alphanumeric strings (potential keys)
    if grep -E '\b[A-Z0-9]{32,}\b' "$pkm_file"; then
        warn "Found potential API keys"
        ((issues++))
    fi

    if [[ $issues -eq 0 ]]; then
        success "No sensitive data detected"
    else
        error "Found $issues potential issues - review before sharing"
    fi
}
```

### CLI Integration

```bash
# Add to CLI tool
case "$1" in
    "sync-knowledge"|"knowledge-sync")
        shift
        handle_knowledge_sync "$@"
        ;;
esac

handle_knowledge_sync() {
    local dry_run=false
    local profile="work"
    local review=true
    local project_dir="."

    # Parse flags
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                dry_run=true
                shift
                ;;
            --profile)
                profile="$2"
                shift 2
                ;;
            --no-review)
                review=false
                shift
                ;;
            *)
                project_dir="$1"
                shift
                ;;
        esac
    done

    sync_knowledge "$project_dir" "$profile" "$dry_run" "$review"
}
```

### Example Workflow

```bash
# Dry run to see what would be scrubbed
$ jarvis sync-knowledge --dry-run

Discovering knowledge in current project...

Found documentation:
- README.md
- docs/architecture.md
- docs/api-guide.md
- ADR/001-database-choice.md

Would scrub:
- 15 company name references
- 8 internal URLs
- 3 email addresses
- 2 people names

Preview of docs/architecture.md:
---
- CompanyName uses microservices architecture
+ [COMPANY] uses microservices architecture

- API endpoint: https://internal.company.com/api/v1
+ API endpoint: https://[INTERNAL-URL]/api/v1

Continue with actual sync? (y/N):

# Actually sync with review
$ jarvis sync-knowledge --profile work

[Shows changes for each file]
[User reviews and approves]

✓ Synced 4 documents to ~/Knowledge/Obsidian-Vault/Learnings/
✓ Created backlinks and tags
✓ Updated knowledge index

# Audit a file
$ jarvis audit ~/Knowledge/Obsidian-Vault/Learnings/patterns/architecture.md

Auditing for leaked sensitive data...
✓ No sensitive data detected

File is safe to reference and share publicly if needed.
```

## Dependencies

- #016 (Obsidian templates for PKM storage)

## Related Issues

- #017 (Extended commands)
- #009 (File Manager agent might help organize)

## Definition of Done

- [ ] Scrubbing rules engine implemented
- [ ] Multiple scrubbing profiles created (work, oss, learning)
- [ ] Knowledge discovery finds relevant docs
- [ ] Scrubbing engine works accurately
- [ ] PKM storage creates proper Obsidian notes
- [ ] Dry-run mode works
- [ ] Review process works
- [ ] Audit tool detects leaks
- [ ] CLI commands functional
- [ ] Comprehensive documentation
- [ ] Legal/privacy guidelines provided
- [ ] Tested with real work projects
- [ ] No sensitive data leaks in testing
