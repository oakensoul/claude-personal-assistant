---
title: "Technical Analysis - Configuration System (#55)"
agent: "configuration-specialist"
issue: 55
created: "2025-10-20"
status: "draft"
category: "technical"
---

# Configuration Specialist Technical Analysis: Issue #55

## Executive Summary

**Overall Assessment**: MEDIUM-HIGH COMPLEXITY with HIGH IMPACT

This is a well-scoped configuration infrastructure redesign that builds on existing `aida-config-helper.sh` foundation. The PRD is comprehensive and realistic. Primary technical challenges are **schema evolution strategy**, **validation error UX**, and **migration reliability**.

**Recommended Approach**: Incremental implementation with JSON Schema draft-07, three-tier validation (structure → provider rules → connectivity), and robust auto-migration with rollback support.

**Key Risk**: Breaking existing workflows during migration. Mitigate with comprehensive testing, clear deprecation timeline, and auto-migration with backup.

---

## 1. Implementation Approach

### 1.1 JSON Schema Design

#### Recommendation: JSON Schema Draft-07

**Rationale**:

- Industry standard with excellent tooling support
- Native support in many languages (Python, Go, JavaScript, Rust)
- `jq` can validate draft-07 schemas (via external validator)
- VS Code/IntelliJ provide autocomplete with `$schema` reference

**Schema Structure**:

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://github.com/oakensoul/claude-personal-assistant/schemas/aida-config-v1.json",
  "title": "AIDA Configuration Schema",
  "description": "Configuration schema for AIDA (Agentic Intelligence Digital Assistant)",
  "type": "object",
  "required": ["config_version"],

  "properties": {
    "config_version": {
      "type": "string",
      "pattern": "^\\d+\\.\\d+$",
      "description": "Schema version (major.minor format)",
      "examples": ["1.0", "1.1", "2.0"]
    },

    "vcs": {
      "type": "object",
      "description": "Version control system configuration",
      "required": ["provider"],
      "properties": {
        "provider": {
          "type": "string",
          "enum": ["github", "gitlab", "bitbucket", "none"],
          "description": "VCS provider type"
        },
        "owner": {
          "type": "string",
          "pattern": "^[a-zA-Z0-9-]+$",
          "description": "Repository owner/organization"
        },
        "repo": {
          "type": "string",
          "pattern": "^[a-zA-Z0-9_.-]+$",
          "description": "Repository name"
        },
        "main_branch": {
          "type": "string",
          "default": "main",
          "description": "Default branch name"
        },
        "auto_detect": {
          "type": "boolean",
          "default": true,
          "description": "Enable auto-detection from git remote"
        },
        "_detected": {
          "type": "boolean",
          "description": "Metadata: was configuration auto-detected?"
        },
        "_detection_method": {
          "type": "string",
          "enum": ["git_remote", "manual", "wizard"],
          "description": "Metadata: how configuration was determined"
        },
        "_detection_timestamp": {
          "type": "string",
          "format": "date-time",
          "description": "Metadata: when auto-detection occurred"
        },
        "_detection_confidence": {
          "type": "string",
          "enum": ["high", "medium", "low"],
          "description": "Metadata: confidence level of auto-detection"
        },

        "github": {
          "type": "object",
          "description": "GitHub-specific configuration",
          "properties": {
            "enterprise_url": {
              "type": ["string", "null"],
              "format": "uri",
              "pattern": "^https://",
              "description": "GitHub Enterprise URL (null for github.com)"
            }
          }
        },

        "gitlab": {
          "type": "object",
          "description": "GitLab-specific configuration",
          "properties": {
            "project_id": {
              "type": "string",
              "pattern": "^\\d+$",
              "description": "GitLab project ID (numeric)"
            },
            "group": {
              "type": ["string", "null"],
              "description": "GitLab group name (if part of group)"
            },
            "self_hosted_url": {
              "type": ["string", "null"],
              "format": "uri",
              "pattern": "^https://",
              "description": "Self-hosted GitLab URL (null for gitlab.com)"
            }
          },
          "required": ["project_id"]
        },

        "bitbucket": {
          "type": "object",
          "description": "Bitbucket-specific configuration",
          "properties": {
            "workspace": {
              "type": "string",
              "pattern": "^[a-z0-9-]+$",
              "description": "Bitbucket workspace slug"
            },
            "repo_slug": {
              "type": "string",
              "pattern": "^[a-z0-9-]+$",
              "description": "Repository slug (URL-friendly name)"
            }
          },
          "required": ["workspace", "repo_slug"]
        }
      },

      "allOf": [
        {
          "if": {
            "properties": { "provider": { "const": "github" } }
          },
          "then": {
            "required": ["owner", "repo"]
          }
        },
        {
          "if": {
            "properties": { "provider": { "const": "gitlab" } }
          },
          "then": {
            "required": ["owner", "repo", "gitlab"]
          }
        },
        {
          "if": {
            "properties": { "provider": { "const": "bitbucket" } }
          },
          "then": {
            "required": ["bitbucket"]
          }
        }
      ]
    },

    "work_tracker": {
      "type": "object",
      "description": "Work tracking system configuration",
      "required": ["provider"],
      "properties": {
        "provider": {
          "type": "string",
          "enum": ["github_issues", "jira", "linear", "none"],
          "description": "Work tracker provider type"
        },

        "github_issues": {
          "type": "object",
          "description": "GitHub Issues configuration",
          "properties": {
            "enabled": {
              "type": "boolean",
              "default": true
            }
          }
        },

        "jira": {
          "type": "object",
          "description": "Jira work tracker configuration",
          "properties": {
            "base_url": {
              "type": "string",
              "format": "uri",
              "pattern": "^https://",
              "description": "Jira instance URL"
            },
            "project_key": {
              "type": "string",
              "pattern": "^[A-Z][A-Z0-9]{0,9}$",
              "description": "Jira project key (uppercase, max 10 chars)"
            }
          },
          "required": ["base_url", "project_key"]
        },

        "linear": {
          "type": "object",
          "description": "Linear work tracker configuration",
          "properties": {
            "team_id": {
              "type": "string",
              "pattern": "^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$",
              "description": "Linear team UUID"
            },
            "board_id": {
              "type": "string",
              "pattern": "^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$",
              "description": "Linear board UUID"
            }
          },
          "required": ["team_id"]
        }
      },

      "allOf": [
        {
          "if": {
            "properties": { "provider": { "const": "jira" } }
          },
          "then": {
            "required": ["jira"]
          }
        },
        {
          "if": {
            "properties": { "provider": { "const": "linear" } }
          },
          "then": {
            "required": ["linear"]
          }
        }
      ]
    },

    "team": {
      "type": "object",
      "description": "Team configuration",
      "properties": {
        "review_strategy": {
          "type": "string",
          "enum": ["list", "round-robin", "query", "none"],
          "default": "list",
          "description": "How to select PR reviewers"
        },
        "default_reviewers": {
          "type": "array",
          "items": {
            "type": "string",
            "pattern": "^[a-zA-Z0-9-]+$",
            "description": "VCS username (GitHub handle, GitLab username)"
          },
          "uniqueItems": true,
          "description": "List of default reviewers"
        },
        "members": {
          "type": "array",
          "items": {
            "type": "object",
            "required": ["username", "role"],
            "properties": {
              "username": {
                "type": "string",
                "pattern": "^[a-zA-Z0-9-]+$",
                "description": "VCS username"
              },
              "role": {
                "type": "string",
                "enum": ["developer", "tech-lead", "reviewer"],
                "description": "Team member role"
              },
              "availability": {
                "type": "string",
                "enum": ["available", "limited", "unavailable"],
                "default": "available",
                "description": "Current availability status"
              }
            }
          },
          "description": "Team member list with roles"
        }
      }
    },

    "workflow": {
      "type": "object",
      "description": "Workflow automation settings",
      "properties": {
        "commit": {
          "type": "object",
          "properties": {
            "auto_commit": {
              "type": "boolean",
              "default": true,
              "description": "Auto-commit after each task completion"
            }
          }
        },
        "pr": {
          "type": "object",
          "properties": {
            "auto_version_bump": {
              "type": "boolean",
              "default": true,
              "description": "Automatically bump version when creating PR"
            },
            "update_changelog": {
              "type": "boolean",
              "default": true,
              "description": "Update CHANGELOG.md with PR"
            },
            "draft_by_default": {
              "type": "boolean",
              "default": false,
              "description": "Create PRs as draft by default"
            }
          }
        }
      }
    }
  },

  "additionalProperties": false
}
```

**Key Design Decisions**:

1. **`additionalProperties: false`** - Strict schema catches typos, forces explicit evolution
2. **Metadata fields (`_detected`, `_detection_method`)** - Track provenance for debugging
3. **Conditional validation (`allOf` + `if/then`)** - Provider-specific required fields
4. **Pattern validation** - Enforce format constraints (URLs, usernames, project keys)
5. **Default values** - Documented in schema for clarity

### 1.2 Validation Architecture

**Three-Tier Validation Strategy**:

```text
┌─────────────────────────────────────────────────────────────┐
│ Tier 1: Structural Validation (JSON Schema)                │
│ - Type checking (string, boolean, object)                  │
│ - Required fields per provider                             │
│ - Enum values (provider types, strategies)                 │
│ - Pattern matching (URLs, usernames, UUIDs)                │
│ - Exit code: 1                                             │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ Tier 2: Provider-Specific Business Rules                   │
│ - GitHub: owner+repo required if provider=github           │
│ - GitLab: project_id must exist if gitlab subsection       │
│ - Jira: project_key format validation (uppercase, max 10)  │
│ - Linear: team_id must be valid UUID                       │
│ - Exit code: 2                                             │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ Tier 3: Connectivity Validation (OPTIONAL, --verify)       │
│ - GitHub: Can we fetch repo metadata with API?             │
│ - GitLab: Does project_id exist?                           │
│ - Jira: Is base_url reachable? Does project_key exist?     │
│ - Linear: Can we authenticate with team_id?                │
│ - Exit code: 3                                             │
└─────────────────────────────────────────────────────────────┘
```

**Implementation Pattern**:

```bash
#!/usr/bin/env bash
# lib/installer-common/config-validator.sh

set -euo pipefail

# Tier 1: JSON Schema Validation
validate_structure() {
    local config_file="$1"
    local schema_file="$2"

    # Use check-jsonschema (Python) or ajv (Node.js) for validation
    if command -v check-jsonschema >/dev/null 2>&1; then
        check-jsonschema --schemafile "$schema_file" "$config_file" 2>&1
        return $?
    elif command -v ajv >/dev/null 2>&1; then
        ajv validate -s "$schema_file" -d "$config_file" 2>&1
        return $?
    else
        # Fallback: Basic jq validation (no schema enforcement)
        jq empty "$config_file" 2>&1
        return $?
    fi
}

# Tier 2: Provider-Specific Business Rules
validate_provider_rules() {
    local config_file="$1"

    local provider
    provider=$(jq -r '.vcs.provider // "none"' "$config_file")

    case "$provider" in
        github)
            validate_github_config "$config_file"
            ;;
        gitlab)
            validate_gitlab_config "$config_file"
            ;;
        bitbucket)
            validate_bitbucket_config "$config_file"
            ;;
        none)
            return 0
            ;;
        *)
            echo "ERROR: Unknown VCS provider: $provider"
            return 2
            ;;
    esac
}

validate_github_config() {
    local config_file="$1"
    local errors=0

    local owner
    owner=$(jq -r '.vcs.owner // ""' "$config_file")

    local repo
    repo=$(jq -r '.vcs.repo // ""' "$config_file")

    if [[ -z "$owner" ]]; then
        echo "ERROR: GitHub provider requires 'vcs.owner' field"
        errors=$((errors + 1))
    fi

    if [[ -z "$repo" ]]; then
        echo "ERROR: GitHub provider requires 'vcs.repo' field"
        errors=$((errors + 1))
    fi

    # Show helpful error with auto-detected values
    if [[ $errors -gt 0 ]]; then
        show_github_fix_suggestion
        return 2
    fi

    return 0
}

validate_gitlab_config() {
    local config_file="$1"
    local errors=0

    local project_id
    project_id=$(jq -r '.vcs.gitlab.project_id // ""' "$config_file")

    if [[ -z "$project_id" ]]; then
        echo "ERROR: GitLab provider requires 'vcs.gitlab.project_id' field"
        errors=$((errors + 1))
    fi

    # Validate project_id is numeric
    if [[ -n "$project_id" ]] && ! [[ "$project_id" =~ ^[0-9]+$ ]]; then
        echo "ERROR: GitLab project_id must be numeric (e.g., '12345'), got: '$project_id'"
        errors=$((errors + 1))
    fi

    if [[ $errors -gt 0 ]]; then
        show_gitlab_fix_suggestion
        return 2
    fi

    return 0
}

# Tier 3: Connectivity Validation (OPTIONAL)
validate_connectivity() {
    local config_file="$1"

    local provider
    provider=$(jq -r '.vcs.provider // "none"' "$config_file")

    case "$provider" in
        github)
            verify_github_connection "$config_file"
            ;;
        gitlab)
            verify_gitlab_connection "$config_file"
            ;;
        *)
            echo "INFO: Connectivity validation not implemented for provider: $provider"
            return 0
            ;;
    esac
}

verify_github_connection() {
    local config_file="$1"

    local owner
    owner=$(jq -r '.vcs.owner' "$config_file")

    local repo
    repo=$(jq -r '.vcs.repo' "$config_file")

    # Try to fetch repo metadata from GitHub API
    local response
    response=$(curl -s -f -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/$owner/$repo" 2>&1)

    if [[ $? -ne 0 ]]; then
        echo "ERROR: Cannot connect to GitHub repository: $owner/$repo"
        echo "  API response: $response"
        return 3
    fi

    echo "✓ GitHub repository verified: $owner/$repo"
    return 0
}

# Error message templates with auto-detected values
show_github_fix_suggestion() {
    # Try to auto-detect from git remote
    local remote_url
    remote_url=$(git config --get remote.origin.url 2>/dev/null || echo "")

    local detected_owner=""
    local detected_repo=""

    if [[ -n "$remote_url" ]]; then
        # Parse GitHub URL (both SSH and HTTPS)
        if [[ "$remote_url" =~ github\.com[:/]([^/]+)/([^/]+)(\.git)?$ ]]; then
            detected_owner="${BASH_REMATCH[1]}"
            detected_repo="${BASH_REMATCH[2]%.git}"
        fi
    fi

    echo ""
    echo "Auto-detected from git remote:"
    if [[ -n "$detected_owner" ]] && [[ -n "$detected_repo" ]]; then
        echo "  Remote URL: $remote_url"
        echo "  Owner: $detected_owner"
        echo "  Repo: $detected_repo"
        echo ""
        echo "Quick fix:"
        echo "  aida-config-helper.sh --set vcs.owner \"$detected_owner\""
        echo "  aida-config-helper.sh --set vcs.repo \"$detected_repo\""
    else
        echo "  (Could not auto-detect from git remote)"
        echo ""
        echo "Manually set values:"
        echo "  aida-config-helper.sh --set vcs.owner \"your-org\""
        echo "  aida-config-helper.sh --set vcs.repo \"your-repo\""
    fi
    echo ""
    echo "See: aida-config-helper.sh --help vcs"
}

# Main validation orchestrator
main() {
    local config_file="${1:-.aida/config.json}"
    local schema_file="${2:-${AIDA_HOME:-~/.aida}/lib/installer-common/config-schema.json}"
    local verify_connection=false

    # Parse flags
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --verify-connection)
                verify_connection=true
                shift
                ;;
            *)
                shift
                ;;
        esac
    done

    echo "Validating configuration: $config_file"
    echo ""

    # Tier 1: Structure
    echo "[1/3] Validating structure (JSON Schema)..."
    if ! validate_structure "$config_file" "$schema_file"; then
        echo "✗ Structure validation failed"
        exit 1
    fi
    echo "✓ Structure validation passed"
    echo ""

    # Tier 2: Provider rules
    echo "[2/3] Validating provider-specific rules..."
    if ! validate_provider_rules "$config_file"; then
        echo "✗ Provider validation failed"
        exit 2
    fi
    echo "✓ Provider validation passed"
    echo ""

    # Tier 3: Connectivity (optional)
    if [[ "$verify_connection" == true ]]; then
        echo "[3/3] Verifying connectivity (optional)..."
        if ! validate_connectivity "$config_file"; then
            echo "✗ Connectivity validation failed"
            exit 3
        fi
        echo "✓ Connectivity validation passed"
        echo ""
    else
        echo "[3/3] Connectivity validation skipped (use --verify-connection to enable)"
        echo ""
    fi

    echo "✓ Configuration is valid"
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

### 1.3 Schema Evolution & Migration Strategy

**Versioning Approach**:

```json
{
  "config_version": "1.0",  // MAJOR.MINOR format
  // Config structure...
}
```

**Version Compatibility Rules**:

- **MAJOR version change**: Breaking changes, requires migration
- **MINOR version change**: Backward-compatible additions (new optional fields)

**Migration Implementation**:

```bash
#!/usr/bin/env bash
# lib/installer-common/config-migrator.sh

migrate_config() {
    local config_file="$1"

    # Detect current version
    local current_version
    current_version=$(jq -r '.config_version // "0.0"' "$config_file")

    local target_version="1.0"

    # No migration needed
    if [[ "$current_version" == "$target_version" ]]; then
        echo "Configuration already at version $target_version"
        return 0
    fi

    echo "Migrating configuration from v$current_version to v$target_version"

    # Backup original config
    local backup_file="${config_file}.backup-$(date +%Y%m%d-%H%M%S)"
    cp "$config_file" "$backup_file"
    echo "Backup created: $backup_file"

    # Apply migrations in sequence
    case "$current_version" in
        0.0)
            # Migrate from legacy github.* namespace
            migrate_0_0_to_1_0 "$config_file"
            ;;
        *)
            echo "ERROR: Unknown config version: $current_version"
            echo "Restoring from backup..."
            cp "$backup_file" "$config_file"
            return 1
            ;;
    esac

    # Validate migrated config
    if ! validate_config "$config_file"; then
        echo "ERROR: Migrated config failed validation"
        echo "Restoring from backup..."
        cp "$backup_file" "$config_file"
        return 1
    fi

    echo "✓ Migration successful"
    echo "  Backup: $backup_file"
    echo "  To rollback: cp $backup_file $config_file"

    return 0
}

migrate_0_0_to_1_0() {
    local config_file="$1"

    # Transform: github.* → vcs.github.*
    jq '
        # Add config_version
        .config_version = "1.0" |

        # Create vcs namespace
        .vcs = {
            provider: "github",
            owner: .github.owner // "",
            repo: .github.repo // "",
            main_branch: .github.main_branch // .workflow.default_base_branch // "main",
            auto_detect: true,
            _detected: false,
            _detection_method: "migration",
            github: {
                enterprise_url: .github.enterprise_url // null
            }
        } |

        # Create work_tracker namespace (default to github_issues)
        .work_tracker = {
            provider: "github_issues",
            github_issues: {
                enabled: true
            }
        } |

        # Preserve workflow settings
        .workflow = {
            commit: {
                auto_commit: .workflow.auto_commit // .workflow.commit_after_each_task // true
            },
            pr: {
                auto_version_bump: .workflow.auto_version_bump // true,
                update_changelog: .workflow.update_changelog // true,
                draft_by_default: false
            }
        } |

        # Remove old github namespace (now in vcs.github)
        del(.github)
    ' "$config_file" > "${config_file}.tmp"

    mv "${config_file}.tmp" "$config_file"
}
```

**Schema Change Process**:

1. **Add new optional field**: Update schema, increment MINOR version
2. **Add new required field**: Requires MAJOR version bump + migration
3. **Remove field**: Deprecate in v1.x, remove in v2.0
4. **Rename field**: Deprecate old name in v1.x, remove in v2.0

---

## 2. Technical Concerns

### 2.1 Schema Complexity vs Usability

**Current Concern**: PRD schema has 4 namespaces × 3-5 subsections = high complexity

**Mitigation Strategies**:

1. **Progressive Disclosure in Validation Errors**:

   ```text
   ERROR: Configuration incomplete

   Required for GitHub:
     ✗ vcs.owner
     ✗ vcs.repo

   Optional (auto-detected):
     ✓ vcs.main_branch (auto-detected: main)
     ✓ vcs.github.enterprise_url (not required for github.com)
   ```

2. **Schema Documentation Generation**:

   - Generate markdown reference from JSON Schema
   - Create interactive HTML docs with examples
   - Provide "quick start" templates for common scenarios

3. **Template Configs**:

   ```bash
   # lib/templates/config-github-simple.json
   {
     "config_version": "1.0",
     "vcs": {
       "provider": "github",
       "owner": "your-org",
       "repo": "your-repo"
     }
   }

   # lib/templates/config-jira-gitlab.json
   {
     "config_version": "1.0",
     "vcs": {
       "provider": "gitlab",
       "owner": "your-group",
       "repo": "your-project",
       "gitlab": {
         "project_id": "12345"
       }
     },
     "work_tracker": {
       "provider": "jira",
       "jira": {
         "base_url": "https://your-org.atlassian.net",
         "project_key": "PROJ"
       }
     }
   }
   ```

4. **IDE Autocomplete Support**:

   ```json
   {
     "$schema": "https://raw.githubusercontent.com/oakensoul/claude-personal-assistant/main/lib/installer-common/config-schema.json",
     "config_version": "1.0"
     // VS Code now provides autocomplete for all fields
   }
   ```

### 2.2 Validation Performance

**Concern**: JSON Schema validation + provider rules + connectivity checks could be slow

**Performance Budget**:

- Tier 1 (structure): < 50ms
- Tier 2 (provider rules): < 100ms
- Tier 3 (connectivity): < 2000ms (only with `--verify-connection`)

**Optimization Strategies**:

1. **Schema Validation Caching**:

   ```bash
   # Cache schema validator instance (in Python/Node.js)
   # Bash: Skip schema validation if config unchanged (checksum-based)
   if [[ "$config_checksum" == "$cached_checksum" ]]; then
       echo "Using cached validation result"
       return 0
   fi
   ```

2. **Lazy Provider Rule Validation**:

   ```bash
   # Only validate sections that exist in config
   if jq -e '.vcs.gitlab' "$config_file" >/dev/null 2>&1; then
       validate_gitlab_config "$config_file"
   fi
   ```

3. **Parallel Connectivity Checks** (if multiple providers in future):

   ```bash
   # Run connectivity checks in parallel
   verify_github_connection "$config_file" &
   verify_jira_connection "$config_file" &
   wait
   ```

4. **Skip Connectivity by Default**:
   - Tier 3 validation only runs with `--verify-connection` flag
   - Most validations complete in < 150ms

**Benchmark Target**:

- **Fast path** (cache hit): < 10ms
- **Slow path** (full validation, no connectivity): < 150ms
- **Full validation** (with connectivity): < 2000ms

### 2.3 Adding New Providers Without Breaking Changes

**Design Pattern: Provider Subsection Isolation**:

```json
{
  "vcs": {
    "provider": "gitea",  // New provider added to enum
    "owner": "your-org",
    "repo": "your-repo",

    // Existing providers unchanged
    "github": { ... },
    "gitlab": { ... },

    // New provider subsection (isolated)
    "gitea": {
      "instance_url": "https://gitea.example.com",
      "api_version": "v1"
    }
  }
}
```

**Schema Evolution for New Provider**:

1. **Add new enum value**: `"provider": "gitea"` (MINOR version bump)
2. **Add new subsection**: `"gitea": { ... }` (MINOR version bump)
3. **Add conditional validation**: If provider=gitea, require gitea subsection
4. **Update auto-detection**: Add gitea URL pattern matching

**No Breaking Changes Because**:

- Existing provider configs unaffected
- New subsections are isolated (no cross-provider dependencies)
- `additionalProperties: false` only applies to top-level, not subsections

**Provider Plugin Pattern** (Future Enhancement):

```bash
# lib/vcs-providers/gitea.sh (plugin)
provider_name="gitea"
provider_url_patterns=("gitea\\..*" ".*\\.gitea\\..*")

detect_gitea() {
    local remote_url="$1"
    # Detection logic...
}

validate_gitea() {
    local config_file="$1"
    # Validation logic...
}

verify_gitea_connection() {
    local config_file="$1"
    # Connectivity check...
}
```

### 2.4 Default Value Strategy

**Three Types of Defaults**:

1. **Schema Defaults** (in JSON Schema):

   ```json
   {
     "main_branch": {
       "type": "string",
       "default": "main"  // Schema-level default
     }
   }
   ```

2. **System Defaults** (in aida-config-helper.sh):

   ```bash
   get_system_defaults() {
       jq -n '{
           vcs: {
               provider: "github",
               main_branch: "main",
               auto_detect: true
           }
       }'
   }
   ```

3. **Auto-Detected Defaults** (runtime):

   ```bash
   auto_detect_vcs() {
       local remote_url
       remote_url=$(git config --get remote.origin.url)

       # Detect provider from URL
       # Set owner, repo, main_branch from git config
   }
   ```

**Precedence** (highest to lowest):

1. User-specified value in config file
2. Auto-detected value (if auto_detect=true)
3. System default (from aida-config-helper.sh)
4. Schema default (from JSON Schema)

**Implementation**:

```bash
get_config_value_with_defaults() {
    local key="$1"

    # Try user config first
    local value
    value=$(jq -r ".$key" .aida/config.json 2>/dev/null)

    if [[ "$value" != "null" ]] && [[ -n "$value" ]]; then
        echo "$value"
        return 0
    fi

    # Try auto-detection (if enabled)
    if [[ "$(jq -r '.vcs.auto_detect // true' .aida/config.json)" == "true" ]]; then
        value=$(auto_detect_config_value "$key")
        if [[ -n "$value" ]]; then
            echo "$value"
            return 0
        fi
    fi

    # Fall back to system default
    value=$(get_system_defaults | jq -r ".$key")
    echo "$value"
}
```

---

## 3. Dependencies & Integration

### 3.1 JSON Schema Validator Selection

**Options Analysis**:

| Tool | Language | Speed | Features | Availability |
|------|----------|-------|----------|--------------|
| `ajv-cli` | Node.js | Fast | Full draft-07 support, custom formats | `npm install -g ajv-cli` |
| `check-jsonschema` | Python | Medium | Draft-07, good errors | `pip install check-jsonschema` |
| `jq` native | Bash | Fast | Basic validation only (no schema) | Built-in (macOS, Linux) |

**Recommended Approach**: **Tiered Fallback**

```bash
validate_with_schema() {
    local config_file="$1"
    local schema_file="$2"

    # Tier 1: Try ajv-cli (best errors)
    if command -v ajv >/dev/null 2>&1; then
        ajv validate -s "$schema_file" -d "$config_file"
        return $?
    fi

    # Tier 2: Try check-jsonschema (good errors)
    if command -v check-jsonschema >/dev/null 2>&1; then
        check-jsonschema --schemafile "$schema_file" "$config_file"
        return $?
    fi

    # Tier 3: Fallback to jq (basic validation only)
    if command -v jq >/dev/null 2>&1; then
        echo "WARNING: Full JSON Schema validation unavailable (install ajv-cli or check-jsonschema)"
        echo "Running basic JSON syntax validation..."
        jq empty "$config_file"
        return $?
    fi

    echo "ERROR: No JSON validator available (jq, ajv-cli, or check-jsonschema required)"
    return 1
}
```

**Rationale**:

- Don't force users to install Python/Node.js just for validation
- Graceful degradation to basic jq validation
- Installer can recommend `ajv-cli` or `check-jsonschema` for best experience

### 3.2 Schema Documentation Generation

**Tool**: `jsonschema2md` (Python) or `json-schema-md-doc` (Node.js)

**Generated Output Example**:

```markdown
# AIDA Configuration Schema v1.0

## Properties

### `config_version` (required)

**Type**: `string`
**Pattern**: `^\d+\.\d+$`
**Description**: Schema version (major.minor format)
**Examples**: `"1.0"`, `"1.1"`, `"2.0"`

### `vcs` (optional)

**Type**: `object`
**Description**: Version control system configuration

#### `vcs.provider` (required)

**Type**: `string`
**Enum**: `"github"`, `"gitlab"`, `"bitbucket"`, `"none"`
**Description**: VCS provider type
```

**Integration in Build Process**:

```bash
# scripts/generate-schema-docs.sh

#!/usr/bin/env bash

set -euo pipefail

readonly SCHEMA_FILE="lib/installer-common/config-schema.json"
readonly OUTPUT_FILE="docs/configuration/schema-reference.md"

# Generate markdown from JSON Schema
if command -v jsonschema2md >/dev/null 2>&1; then
    jsonschema2md "$SCHEMA_FILE" "$OUTPUT_FILE"
    echo "✓ Schema documentation generated: $OUTPUT_FILE"
else
    echo "ERROR: jsonschema2md not found (pip install jsonschema2md)"
    exit 1
fi
```

### 3.3 IDE Support for Autocomplete

**VS Code Integration**:

```json
// .aida/config.json
{
  "$schema": "https://raw.githubusercontent.com/oakensoul/claude-personal-assistant/main/lib/installer-common/config-schema.json",
  "config_version": "1.0",
  "vcs": {
    // VS Code provides autocomplete here ↓
    "provider": "github",  // Autocomplete suggests: github, gitlab, bitbucket, none
    "owner": "",           // Shows description from schema
    "repo": ""
  }
}
```

**IntelliJ/WebStorm Integration**:

- Same `$schema` reference works automatically
- Settings > Languages & Frameworks > Schemas and DTDs > JSON Schema Mappings
- Add mapping: `*.aida/config.json` → schema URL

**Benefits**:

- Real-time validation in IDE
- Autocomplete for all fields
- Inline documentation from schema descriptions
- Reduces config errors before commit

### 3.4 Config Templates in Installer

**Template Strategy**:

```bash
# install.sh (during /aida-init or initial setup)

create_initial_config() {
    local config_file=".aida/config.json"

    # Detect VCS provider from git remote
    local provider
    provider=$(auto_detect_vcs_provider)

    # Select appropriate template
    local template_file
    case "$provider" in
        github)
            template_file="${AIDA_HOME}/lib/templates/config-github.json"
            ;;
        gitlab)
            template_file="${AIDA_HOME}/lib/templates/config-gitlab.json"
            ;;
        *)
            template_file="${AIDA_HOME}/lib/templates/config-default.json"
            ;;
    esac

    # Copy template and fill in auto-detected values
    jq --arg provider "$provider" \
       --arg owner "$(auto_detect_owner)" \
       --arg repo "$(auto_detect_repo)" \
       '.vcs.provider = $provider | .vcs.owner = $owner | .vcs.repo = $repo' \
       "$template_file" > "$config_file"

    echo "✓ Configuration created: $config_file"
    echo "  Provider: $provider (auto-detected)"
    echo "  Owner: $(auto_detect_owner)"
    echo "  Repo: $(auto_detect_repo)"
}
```

---

## 4. Effort & Complexity Estimation

### 4.1 Task Breakdown

| Task | Complexity | Effort | Dependencies |
|------|-----------|--------|--------------|
| **JSON Schema Design** | MEDIUM | 4-6 hours | None |
| **VCS Auto-Detection** | MEDIUM | 3-4 hours | None |
| **Hierarchical Config Loading** | LOW | 1-2 hours | Existing aida-config-helper.sh |
| **Tier 1 Validation (Structure)** | LOW | 2-3 hours | JSON Schema validator |
| **Tier 2 Validation (Provider Rules)** | MEDIUM | 4-6 hours | Schema design |
| **Tier 3 Validation (Connectivity)** | MEDIUM | 3-4 hours | Provider rules |
| **Error Message Templates** | MEDIUM | 3-4 hours | Validation tiers |
| **Migration Script (github.* → vcs.*)** | HIGH | 6-8 hours | Schema design |
| **Template Config Files** | LOW | 2-3 hours | Schema design |
| **Pre-commit Hook (Secret Detection)** | LOW | 2-3 hours | None |
| **Schema Documentation Generation** | LOW | 2-3 hours | Schema design |
| **Integration Tests** | HIGH | 6-8 hours | All validation tiers |
| **Installer Integration** | MEDIUM | 3-4 hours | Migration script |
| **Documentation (Schema, Security, Patterns)** | MEDIUM | 4-6 hours | All features |

**Total Estimated Effort**: **40-60 hours** (1-1.5 weeks for experienced developer)

### 4.2 Critical Path

```text
JSON Schema Design (6h)
    ↓
VCS Auto-Detection (4h)
    ↓
Tier 1-2 Validation (10h)
    ↓
Migration Script (8h) ← CRITICAL PATH BOTTLENECK
    ↓
Integration Tests (8h)
    ↓
Documentation (6h)

TOTAL CRITICAL PATH: ~42 hours
```

**Risk Areas** (likely to take longer than estimated):

1. **Migration Script**: Complex jq transformations, edge cases, rollback logic
2. **Integration Tests**: Need to test all provider combinations, error paths
3. **Error Message Templates**: Iteration required to get UX right

### 4.3 Phased Implementation Recommendation

#### Phase 1: Core Infrastructure (Week 1)

- JSON Schema design and validation
- VCS auto-detection function
- Hierarchical config loading (extend aida-config-helper.sh)
- Basic migration script (github.*→ vcs.*)

#### Phase 2: Validation & UX (Week 2)

- Provider-specific validation rules
- Error message templates with auto-detection hints
- Pre-commit hook for secret detection
- Template config files

#### Phase 3: Testing & Documentation (Week 3)

- Integration tests (all providers, error paths)
- Schema documentation generation
- Security model documentation
- Migration testing with real configs

#### Phase 4: Installer Integration (Week 4)

- Update install.sh to set file permissions
- Create .gitignore entries automatically
- Add config validation to pre-commit hooks
- Release with deprecation notice for old format

---

## 5. Questions & Clarifications

### 5.1 Schema Design Questions

**Q1: Should schema be strict (`additionalProperties: false`) or permissive?**

**Recommendation**: **STRICT (`additionalProperties: false`)**

**Rationale**:

- **Catches typos early**: `vcs.owenr` → error, not silent failure
- **Forces explicit evolution**: New fields require schema update + version bump
- **Better IDE autocomplete**: Only valid fields suggested
- **Clear migration path**: Schema change = version bump = migration trigger

**Trade-off Accepted**:

- Users can't add custom fields (but they can use `_metadata` section for extensions)
- Requires more frequent schema updates (mitigated by MINOR version bumps)

**Q2: How to version schema for evolution?**

**Recommendation**: **Semantic Versioning in `config_version` field**

```json
{
  "config_version": "1.0",  // MAJOR.MINOR format
  // When to bump:
  // - MAJOR: Breaking changes (remove/rename required field, change validation)
  // - MINOR: Backward-compatible additions (new optional field, new provider)
}
```

**Migration Trigger**:

```bash
# On first command execution after schema change
current_version=$(jq -r '.config_version // "0.0"' .aida/config.json)

if [[ "$current_version" != "1.0" ]]; then
    echo "Configuration schema outdated (v$current_version → v1.0)"
    echo "Running auto-migration..."
    migrate_config .aida/config.json
fi
```

**Q3: Should we generate docs from schema?**

**Recommendation**: **YES - Generate markdown reference from JSON Schema**

**Benefits**:

- **Single source of truth**: Schema = validation + documentation
- **Always up-to-date**: Docs regenerated on schema change
- **IDE integration**: Same schema powers autocomplete
- **Version-specific docs**: Each schema version has corresponding docs

**Implementation**:

```bash
# pre-commit hook or CI check
if [[ config-schema.json changed ]]; then
    ./scripts/generate-schema-docs.sh
    git add docs/configuration/schema-reference.md
fi
```

**Q4: What's the strategy for deprecating old fields?**

**Recommendation**: **Two-Version Deprecation Period**

**Process**:

1. **v1.0**: Add new field, mark old field as deprecated (schema + docs)

   ```json
   {
     "old_field": {
       "type": "string",
       "deprecated": true,
       "description": "DEPRECATED: Use new_field instead. Will be removed in v2.0."
     },
     "new_field": {
       "type": "string",
       "description": "Replacement for old_field"
     }
   }
   ```

2. **v1.1-v1.x**: Support both fields, log deprecation warning

   ```bash
   if jq -e '.old_field' .aida/config.json >/dev/null 2>&1; then
       echo "WARNING: 'old_field' is deprecated and will be removed in v2.0"
       echo "  Use 'new_field' instead"
       echo "  See: docs/migration/v1-to-v2.md"
   fi
   ```

3. **v2.0**: Remove old field, migration auto-converts

   ```bash
   migrate_1_x_to_2_0() {
       jq '.new_field = .old_field | del(.old_field)' config.json
   }
   ```

**Timeline Example**:

- v0.1.6 (current): `github.*` namespace (no warnings)
- v0.2.0 (Issue #55): `vcs.*` namespace added, `github.*` deprecated (warnings)
- v0.3.0: Both supported (warnings continue)
- v0.4.0: `github.*` removed, auto-migration required

### 5.2 Validation Strategy Questions

**Q5: Should validation fail fast or collect all errors?**

**Recommendation**: **Collect all errors in each tier, fail fast across tiers**

**Rationale**:

- **Within tier**: Show all errors at once (better UX than fixing one error at a time)
- **Across tiers**: Stop after first tier failure (no point checking provider rules if structure invalid)

**Implementation**:

```bash
validate_all() {
    local config_file="$1"
    local errors=()

    # Tier 1: Structure validation
    if ! structure_errors=$(validate_structure "$config_file" 2>&1); then
        errors+=("STRUCTURE: $structure_errors")
        # Stop here - structure invalid, provider validation will fail
        show_all_errors "${errors[@]}"
        exit 1
    fi

    # Tier 2: Provider rules (collect all errors in this tier)
    provider_errors=$(validate_provider_rules "$config_file" 2>&1)
    if [[ -n "$provider_errors" ]]; then
        errors+=("PROVIDER: $provider_errors")
    fi

    # Tier 3: Connectivity (optional, only if Tier 2 passed)
    if [[ ${#errors[@]} -eq 0 ]] && [[ "$verify_connection" == true ]]; then
        connectivity_errors=$(validate_connectivity "$config_file" 2>&1)
        if [[ -n "$connectivity_errors" ]]; then
            errors+=("CONNECTIVITY: $connectivity_errors")
        fi
    fi

    # Report all collected errors
    if [[ ${#errors[@]} -gt 0 ]]; then
        show_all_errors "${errors[@]}"
        exit 2
    fi

    return 0
}
```

**Q6: How verbose should auto-detection feedback be?**

**Recommendation**: **Progressive verbosity with flags**

**Levels**:

1. **Default (quiet success, loud failure)**:

   ```bash
   # Success (no output)
   $ aida-config-helper.sh --validate
   ✓ Configuration valid

   # Failure (detailed errors)
   $ aida-config-helper.sh --validate
   ✗ Configuration invalid

   ERROR: GitHub configuration incomplete
     Required fields missing:
       ✗ vcs.owner
       ✗ vcs.repo
   ```

2. **Verbose (`--verbose`)**: Show what was auto-detected

   ```bash
   $ aida-config-helper.sh --validate --verbose
   [Auto-Detection]
   ✓ VCS provider: github (from git remote: git@github.com:owner/repo.git)
   ✓ Owner: owner
   ✓ Repo: repo
   ✓ Main branch: main (from git symbolic-ref)

   [Validation]
   ✓ Structure validation passed
   ✓ Provider rules validation passed

   ✓ Configuration valid
   ```

3. **Debug (`--debug`)**: Show merge process, all config sources

   ```bash
   $ aida-config-helper.sh --validate --debug
   [Config Sources]
   1. System defaults: {...}
   2. User config (~/.claude/config.json): {...}
   3. Project config (.aida/config.json): {...}
   4. Auto-detected values: {...}

   [Merge Result]
   Final config: {...}

   [Validation]
   ...
   ```

### 5.3 Implementation Details Questions

**Q7: How to handle git repositories with multiple remotes (origin + upstream)?**

**Recommendation**: **Use primary remote (origin), warn if multiple providers detected**

**Implementation**:

```bash
auto_detect_vcs_provider() {
    # Try origin first (primary remote)
    local origin_url
    origin_url=$(git config --get remote.origin.url 2>/dev/null || echo "")

    if [[ -n "$origin_url" ]]; then
        detect_provider_from_url "$origin_url"
        return $?
    fi

    # Fall back to any remote if origin missing
    local all_remotes
    all_remotes=$(git remote 2>/dev/null || echo "")

    if [[ -z "$all_remotes" ]]; then
        echo "none"
        return 0
    fi

    # Use first remote found
    local first_remote
    first_remote=$(echo "$all_remotes" | head -n1)

    local remote_url
    remote_url=$(git config --get "remote.$first_remote.url")

    echo "WARNING: No 'origin' remote found, using '$first_remote' instead" >&2

    detect_provider_from_url "$remote_url"
}
```

**Q8: Should we support monorepos (multiple .aida/config.json files)?**

**Recommendation**: **Defer to future issue, but design namespace to support it**

**Current Scope** (Issue #55):

- Single `.aida/config.json` per git repository
- Config location: `$(git rev-parse --show-toplevel)/.aida/config.json`

**Future Enhancement** (Post-v1.0):

- Support nested `.aida/config.json` in subdirectories
- Hierarchical merge: `repo-root/.aida/config.json` ← `subdir/.aida/config.json`
- Use case: Monorepo with multiple projects, each with different VCS provider or work tracker

**Design Compatibility**:

- Current namespace structure already supports this (no breaking changes needed)
- Just need to update config loading to traverse up directory tree

---

## 6. Security Considerations

### 6.1 Secret Detection in Pre-Commit Hook

**Implementation**:

```bash
#!/usr/bin/env bash
# .git/hooks/pre-commit (or .pre-commit-config.yaml)

set -euo pipefail

echo "Checking for secrets in config files..."

# Patterns to detect
readonly SECRET_PATTERNS=(
    'ghp_[a-zA-Z0-9]{36}'           # GitHub personal access token
    'gho_[a-zA-Z0-9]{36}'           # GitHub OAuth token
    'github_pat_[a-zA-Z0-9]{22}_[a-zA-Z0-9]{59}'  # GitHub fine-grained PAT
    'glpat-[a-zA-Z0-9_-]{20}'       # GitLab personal access token
    '"api_key"\s*:\s*"[^"]+"'       # Generic API key in JSON
    '"token"\s*:\s*"[^"]+"'         # Generic token in JSON
    '"password"\s*:\s*"[^"]+"'      # Password in JSON
    'AKIA[0-9A-Z]{16}'              # AWS access key
)

# Files to check
readonly CONFIG_FILES=(
    ".aida/config.json"
    ".github/workflow-config.json"
    "$HOME/.claude/config.json"
)

errors=0

for config_file in "${CONFIG_FILES[@]}"; do
    if [[ ! -f "$config_file" ]]; then
        continue
    fi

    # Check if file is staged for commit
    if ! git diff --cached --name-only | grep -q "^$config_file$"; then
        continue
    fi

    echo "Scanning: $config_file"

    for pattern in "${SECRET_PATTERNS[@]}"; do
        if grep -E "$pattern" "$config_file" >/dev/null 2>&1; then
            echo "ERROR: Potential secret detected in $config_file"
            echo "  Pattern matched: $pattern"
            echo ""
            echo "To fix:"
            echo "  1. Remove secret from config file"
            echo "  2. Store secret in environment variable or keychain"
            echo "  3. Reference env var name in config (e.g., \"token\": \"\${GITHUB_TOKEN}\")"
            echo ""
            errors=$((errors + 1))
        fi
    done
done

if [[ $errors -gt 0 ]]; then
    echo "✗ Pre-commit check failed: $errors secret(s) detected"
    echo ""
    echo "To bypass this check (NOT RECOMMENDED):"
    echo "  git commit --no-verify"
    exit 1
fi

echo "✓ No secrets detected in config files"
exit 0
```

### 6.2 File Permission Enforcement

**Installer Integration**:

```bash
# install.sh or /aida-init command

set_config_permissions() {
    # User config: private (600)
    if [[ -f "${HOME}/.claude/config.json" ]]; then
        chmod 600 "${HOME}/.claude/config.json"
        echo "✓ Set permissions: ~/.claude/config.json (600 - user-only)"
    fi

    # Project config: readable (644)
    if [[ -f ".aida/config.json" ]]; then
        chmod 644 ".aida/config.json"
        echo "✓ Set permissions: .aida/config.json (644 - world-readable)"
    fi
}
```

**Validation Check**:

```bash
check_config_permissions() {
    local config_file="$1"
    local required_perms="$2"  # e.g., "600" or "644"

    local actual_perms
    actual_perms=$(stat -f "%A" "$config_file" 2>/dev/null || stat -c "%a" "$config_file" 2>/dev/null)

    if [[ "$actual_perms" != "$required_perms" ]]; then
        echo "WARNING: Incorrect permissions on $config_file"
        echo "  Expected: $required_perms"
        echo "  Actual: $actual_perms"
        echo "  Fix: chmod $required_perms $config_file"
    fi
}
```

---

## 7. Testing Strategy

### 7.1 Unit Tests

**Test Coverage**:

```bash
# tests/unit/test-config-validation.sh

test_schema_validation_github() {
    local config='{"config_version":"1.0","vcs":{"provider":"github","owner":"test","repo":"repo"}}'
    echo "$config" > /tmp/test-config.json

    if validate_structure /tmp/test-config.json; then
        echo "✓ Valid GitHub config passed"
    else
        echo "✗ Valid GitHub config failed validation"
        return 1
    fi
}

test_schema_validation_missing_required() {
    local config='{"config_version":"1.0","vcs":{"provider":"github"}}'
    echo "$config" > /tmp/test-config.json

    if ! validate_provider_rules /tmp/test-config.json 2>&1 | grep -q "owner"; then
        echo "✗ Should have detected missing 'owner' field"
        return 1
    fi

    echo "✓ Correctly detected missing required field"
}

test_auto_detection_github() {
    # Setup mock git remote
    git init /tmp/test-repo
    cd /tmp/test-repo
    git remote add origin git@github.com:oakensoul/test-repo.git

    local provider
    provider=$(auto_detect_vcs_provider)

    if [[ "$provider" != "github" ]]; then
        echo "✗ Failed to detect GitHub provider"
        return 1
    fi

    echo "✓ Auto-detected GitHub provider"
}
```

### 7.2 Integration Tests

**Test Scenarios**:

1. **Migration from v0 (github.*) to v1.0 (vcs.*)**:

   ```bash
   test_migration_github_to_vcs() {
       # Create old-format config
       echo '{"github":{"owner":"test","repo":"repo"}}' > /tmp/old-config.json

       # Run migration
       migrate_config /tmp/old-config.json

       # Verify new format
       local provider
       provider=$(jq -r '.vcs.provider' /tmp/old-config.json)

       if [[ "$provider" != "github" ]]; then
           echo "✗ Migration failed: provider not set"
           return 1
       fi

       echo "✓ Migration successful"
   }
   ```

2. **Hierarchical config merging (user + project)**:

   ```bash
   test_hierarchical_merge() {
       # User config
       echo '{"vcs":{"main_branch":"develop"}}' > ~/.claude/config.json

       # Project config
       echo '{"vcs":{"provider":"github","owner":"test","repo":"repo"}}' > .aida/config.json

       # Merge
       local merged
       merged=$(merge_configs)

       # Verify project overrides user
       local provider
       provider=$(echo "$merged" | jq -r '.vcs.provider')

       if [[ "$provider" != "github" ]]; then
           echo "✗ Merge failed: project config not applied"
           return 1
       fi

       echo "✓ Hierarchical merge successful"
   }
   ```

3. **Secret detection in pre-commit hook**:

   ```bash
   test_secret_detection() {
       # Create config with secret
       echo '{"github":{"token":"ghp_1234567890123456789012345678901234567890"}}' > .aida/config.json

       # Stage for commit
       git add .aida/config.json

       # Run pre-commit hook
       if .git/hooks/pre-commit; then
           echo "✗ Pre-commit hook should have blocked secret"
           return 1
       fi

       echo "✓ Secret detection working"
   }
   ```

### 7.3 Edge Case Tests

**Critical Edge Cases**:

1. **Empty config file**: Should use system defaults
2. **Invalid JSON**: Should show clear syntax error
3. **Unknown provider**: Should suggest valid providers
4. **Missing git remote**: Should gracefully fall back
5. **Multiple remotes with different providers**: Should use origin, warn about others
6. **Config with comments** (invalid JSON): Should show helpful error
7. **Partial config** (only vcs namespace): Should merge with defaults
8. **Circular env var references**: Should detect and error

---

## 8. Documentation Requirements

### 8.1 Schema Reference Documentation

**Generated from JSON Schema** (see Section 3.2):

- Markdown reference with all fields, types, validation rules
- Examples for each provider type
- Migration guides for version upgrades

**Location**: `docs/configuration/schema-reference.md`

### 8.2 Security Model Documentation

**Topics to Cover**:

- **Why secrets don't belong in config files** (committed to git, readable by all)
- **How to store secrets** (environment variables, keychain, secret managers)
- **Pre-commit hook** (what it checks, how to fix violations)
- **File permissions** (user config 600, project config 644)
- **Audit trail** (what is logged, where, how to review)

**Location**: `docs/configuration/security-model.md`

### 8.3 Provider Pattern Documentation

**Topics to Cover**:

- **Auto-detection patterns** (how git remote URL is parsed)
- **Provider-specific validation** (required fields per provider)
- **Adding custom providers** (plugin architecture, template)
- **Feature detection** (how to check if provider supports feature)
- **Graceful degradation** (fallback when feature unavailable)

**Location**: `docs/integration/vcs-provider-patterns.md`

### 8.4 Migration Guide Documentation

**Topics to Cover**:

- **Why migration is needed** (old namespace → new namespace)
- **What changes** (field mappings, new required fields)
- **How to migrate** (automatic vs manual, rollback)
- **Validation after migration** (how to verify success)
- **Troubleshooting** (common issues, how to fix)

**Location**: `docs/migration/v0-to-v1-config.md`

---

## 9. Recommendations Summary

### 9.1 Approve for Implementation

**Overall Assessment**: ✅ **APPROVE WITH RECOMMENDATIONS**

This is a **well-designed infrastructure upgrade** with clear scope, realistic timeline, and good technical decisions. The PRD addresses the right concerns (security, extensibility, multi-provider support) and provides a solid foundation for Issues #56-59.

### 9.2 Key Recommendations

**CRITICAL (Must Address)**:

1. **Use JSON Schema draft-07** for validation (industry standard, excellent tooling)
2. **Implement three-tier validation** (structure → provider rules → connectivity)
3. **Auto-migration with rollback** (backup before migration, restore on failure)
4. **Pre-commit hook for secret detection** (block commits with secrets)
5. **Progressive error messages** (what → why → how to fix, with auto-detected values)

**HIGH PRIORITY (Should Address)**:

1. **Schema documentation generation** (single source of truth, always up-to-date)
2. **IDE autocomplete support** (`$schema` reference for VS Code/IntelliJ)
3. **Template configs for common scenarios** (GitHub simple, GitLab+Jira, etc.)
4. **Tiered validator fallback** (ajv-cli → check-jsonschema → jq)
5. **Comprehensive integration tests** (all providers, migration, secret detection)

**NICE TO HAVE (Defer if Needed)**:

1. **Verbose/debug output modes** (can add in Issue #56)
2. **Connectivity validation** (Tier 3, optional `--verify-connection` flag)
3. **Provider plugin architecture** (document pattern, implement in future)
4. **Monorepo support** (defer to post-v1.0)

### 9.3 Risk Mitigation Strategies

**Migration Risk** (HIGH):

- Backup config before migration (with timestamp)
- Validate migrated config before overwriting original
- Restore from backup on validation failure
- Support both old and new formats for 2 minor versions (v0.2.x, v0.3.x)

**Performance Risk** (MEDIUM):

- Cache validation results (checksum-based invalidation)
- Skip connectivity validation by default (opt-in with `--verify-connection`)
- Lazy load provider-specific validation (only validate sections that exist)

**Usability Risk** (MEDIUM):

- Progressive disclosure in error messages (show detected values, suggest fixes)
- Template configs reduce manual editing
- IDE autocomplete reduces config errors
- Clear documentation with examples

### 9.4 Coordination Points

**Before Implementation**:

1. **Tech Lead**: Approve schema design and namespace structure
2. **Security Engineer**: Review secret detection patterns and file permissions
3. **UX Designer**: Review error message templates and verbosity levels

**During Implementation**:

1. **DevOps Engineer**: Coordinate CI/CD integration for config validation
2. **Documentation Team**: Review generated schema docs and migration guide

**After Implementation**:

1. **All Stakeholders**: Test migration with real configs (Issue #56 prerequisite)
2. **Users**: Beta test auto-detection and validation feedback

---

## 10. Next Steps

**Immediate Actions** (Before Starting Implementation):

1. **Create JSON Schema definition** (`lib/installer-common/config-schema.json`)
2. **Set up validator selection logic** (ajv-cli → check-jsonschema → jq fallback)
3. **Design migration script structure** (with backup and rollback)
4. **Draft error message templates** (with auto-detection hints)

**Implementation Sequence**:

1. Week 1: Schema design, auto-detection, hierarchical loading, basic migration
2. Week 2: Validation tiers, error messages, pre-commit hook, templates
3. Week 3: Integration tests, documentation, schema docs generation
4. Week 4: Installer integration, release preparation, deprecation notices

**Definition of Done** (Issue #55):

- ✅ JSON Schema created and validated
- ✅ Auto-detection extracts provider/owner/repo from git remote
- ✅ Three-tier validation enforces required fields per provider
- ✅ Hierarchical loading merges user + project config
- ✅ Migration script converts `github.*` → `vcs.github.*`
- ✅ Pre-commit hook detects secrets in config files
- ✅ Template config files created with examples
- ✅ Integration tests pass (all providers, migration, secret detection)
- ✅ Documentation: schema reference, security model, provider patterns, migration guide

---

**Related Files**:

- PRD: `.github/issues/in-progress/issue-55/PRD.md`
- Existing Config Helper: `/Users/rob/Develop/oakensoul/claude-personal-assistant/lib/aida-config-helper.sh`
- Sample Configs: `/Users/rob/Develop/oakensoul/claude-personal-assistant/tests/fixtures/configs/`

**Coordinates With**:

- **tech-lead** (schema design approval, architecture decisions)
- **privacy-security-auditor** (secret detection patterns, file permissions)
- **shell-systems-ux-designer** (error message templates, verbosity levels)
- **integration-specialist** (provider plugin architecture, extensibility)
- **devops-engineer** (CI/CD integration, pre-commit hooks)
