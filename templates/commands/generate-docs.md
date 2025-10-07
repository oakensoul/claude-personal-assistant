---
name: generate-docs
description: Generate documentation for features, APIs, or components with intelligent scope detection and delegation to technical-writer agent
model: sonnet[1m]
args:
  --branch:
    description: Scope documentation to current branch changes only
    required: false
  --project:
    description: Scope documentation to entire project
    required: false
  --files:
    description: Scope to specific files or patterns (e.g., "api/*.ts")
    required: false
  --type:
    description: Documentation type (api, user, integration, developer, readme)
    required: false
  --audience:
    description: Target audience (developers, customers, partners)
    required: false
---

# Generate Documentation Command

Generates comprehensive documentation for features, APIs, or components with intelligent scope detection and audience-appropriate content. Delegates to the technical-writer agent for professional documentation creation.

## Instructions

1. **Detect Current Context**:
   - Get current branch name: `git branch --show-current`
   - Determine branch type:
     - Feature branch pattern: `milestone-v{x.y}/{type}/{id}-{description}`
     - Main branch: `main` or `master`
     - Other branches: Custom naming
   - Extract issue number if feature branch (parse from branch name)
   - Check for related issue documentation in `.github/issues/in-progress/issue-{id}/`
   - Determine smart default scope based on context:
     - On feature branch → Default to `--branch` scope
     - On main branch → Default to `--project` scope
     - Custom branch → Prompt for scope selection

2. **Parse Command Arguments** (if provided):
   - Check for `--branch` flag → Set scope to branch changes only
   - Check for `--project` flag → Set scope to entire project
   - Check for `--files <pattern>` flag → Set scope to specific file pattern
   - Check for `--type <type>` flag → Set documentation type
   - Check for `--audience <audience>` flag → Set target audience
   - Validate flags don't conflict (e.g., can't use both --branch and --project)
   - If conflicting flags, display error and show valid combinations

3. **Scope Selection** (if not provided via arguments):
   - Display detected context:

     ```text
     Documentation Context Detection
     ================================

     Current branch: {branch-name}
     {If feature branch:}
     Detected issue: #{issue-number} - {issue-title}
     Branch type: {type} (feature/bug/chore/etc.)
     {End if}

     Scope Options:
     ```

   - If on feature branch, show:

     ```text
     1. Current branch changes (default) - Document what was built in this branch
        Files changed: {count}
        {List top 5 changed files}
     2. Entire project - Scan all code for documentation targets
     3. Specific files/components - Manual file pattern selection

     Select scope [1]:
     ```

   - If on main branch, show:

     ```text
     1. Entire project (default) - Scan all code for documentation targets
     2. Specific files/components - Manual file pattern selection

     Select scope [1]:
     ```

   - Parse user selection
   - If specific files selected, prompt: "Enter file pattern (e.g., 'api/*.ts', 'src/components/**/*.tsx'):"
   - Validate file pattern and check if files exist
   - Store selected scope for next steps

4. **Documentation Type Selection** (if not provided via --type argument):
   - Display options based on scope:

     ```text
     Documentation Type
     ==================

     What type of documentation do you want to generate?

     1. API Reference - Endpoint documentation with parameters, responses, examples
     2. User Guide - Customer-facing how-to documentation
     3. Integration Guide - Partner/third-party integration instructions
     4. Developer Guide - Internal development documentation
     5. README - Project or component overview

     Select type [1]:
     ```

   - Parse selection and validate
   - Map selection to type value (api, user, integration, developer, readme)
   - Store documentation type for delegation

5. **Audience Selection** (if not provided via --audience argument):
   - Display options based on documentation type:

     ```text
     Target Audience
     ===============

     Who is the primary audience for this documentation?

     1. Developers (technical, detailed, code-focused)
     2. Customers (non-technical, task-oriented, UI-focused)
     3. Integration Partners (technical, integration-focused, API-focused)

     Select audience [1]:
     ```

   - For README type, suggest "Developers" as default
   - For API Reference, suggest "Developers" or "Integration Partners"
   - For User Guide, suggest "Customers"
   - Parse selection and validate
   - Store audience for delegation

6. **Analyze Scope and Identify Documentable Elements**:
   - Based on selected scope, gather code context:

   **For Branch Scope**:
   - Run: `git diff main...HEAD --name-only`
   - Filter for code files (exclude .md, .json config, etc.)
   - For each changed file:
     - Read file content
     - Identify documentable elements:
       - API routes and endpoints (Express, Next.js API routes)
       - Public functions and classes
       - React components
       - Configuration options
       - Data models and schemas
   - Extract issue context if available:
     - Read `.github/issues/in-progress/issue-{id}/README.md`
     - Parse issue title, description, requirements

   **For Project Scope**:
   - Based on documentation type, scan relevant directories:
     - API Reference → `pages/api/**/*.ts`, `src/api/**/*.ts`
     - Components → `src/components/**/*.tsx`, `components/**/*.tsx`
     - Configuration → `*.config.js`, `*.config.ts`
   - Identify undocumented elements (no existing docs in docs/ directory)
   - List top 10 candidates for documentation
   - Ask user: "Found {count} documentable items. Generate docs for all? (y/n/select)"
   - If "select", show numbered list and allow multi-selection

   **For File Pattern Scope**:
   - Use provided glob pattern: `find . -path "{pattern}"`
   - Read matching files
   - Identify documentable elements as above

7. **Prepare Technical Writer Context**:
   - Compile comprehensive context for technical-writer agent:

     ```json
     {
       "scope": "branch|project|files",
       "scope_details": {
         "branch_name": "{branch-name}",
         "issue_number": "{issue-id}",
         "issue_title": "{issue-title}",
         "file_pattern": "{pattern if files scope}"
       },
       "documentation_type": "api|user|integration|developer|readme",
       "target_audience": "developers|customers|partners",
       "files": [
         {
           "path": "{file-path}",
           "content": "{file-content}",
           "documentable_elements": [
             {
               "type": "endpoint|function|class|component|config",
               "name": "{element-name}",
               "signature": "{signature}",
               "location": "{line-number}"
             }
           ]
         }
       ],
       "issue_context": {
         "title": "{issue-title}",
         "description": "{issue-description}",
         "requirements": "{extracted-requirements}"
       },
       "project_requirements": {
         "multi_tenant": true,
         "white_label": true,
         "no_hardcoded_data": true
       }
     }
     ```

8. **Delegate to Technical Writer Agent**:
   - Invoke `technical-writer` subagent with comprehensive context:

     ```text
     Context:
     - Scope: {scope} ({scope-details})
     - Documentation Type: {type}
     - Target Audience: {audience}
     - Files to document: {file-list}
     - Documentable elements: {elements}
     - Issue context: {issue-info if available}
     - Project requirements: Multi-tenant, white-label, configuration-driven

     Tasks:
     1. Analyze provided code files and documentable elements
     2. Generate comprehensive documentation for {type} type
     3. Ensure content is appropriate for {audience} audience
     4. Include proper frontmatter with metadata:
        ---
        title: "{generated-title}"
        description: "{generated-description}"
        type: "{doc-type}"
        audience: "{audience}"
        created: "{today-date}"
        updated: "{today-date}"
        version: "1.0.0"
        tags:
          - "{relevant-tag-1}"
          - "{relevant-tag-2}"
        ---
     5. For API documentation include:
        - Authentication requirements
        - Endpoint URLs (configuration-driven, no hardcoded URLs)
        - Request parameters with types and validation
        - Response formats with examples
        - Error codes and handling
        - Code examples in multiple languages (curl, JavaScript, Python)
     6. For User Guides include:
        - Step-by-step instructions
        - Screenshot placeholders with descriptions
        - Common use cases and workflows
        - Troubleshooting section
        - FAQ section
     7. For Integration Guides include:
        - Prerequisites and setup requirements
        - Configuration steps (environment variables, etc.)
        - Authentication and authorization
        - Integration examples
        - Testing and validation steps
     8. For Developer Guides include:
        - Architecture overview
        - Setup and installation
        - Development workflow
        - Code patterns and best practices
        - Testing guidelines
     9. For README files include:
        - Project/component overview
        - Features and capabilities
        - Installation and setup
        - Usage examples
        - Configuration options
        - Contributing guidelines (if project-level)
     10. Ensure all content is configuration-driven (no hardcoded company names)
     11. Add cross-references to related documentation
     12. Include code examples with proper syntax highlighting
     13. Add screenshot placeholders where visual documentation needed
     14. Return documentation content organized by output file

     Return:
     - Generated documentation files with paths
     - Word counts for each file
     - List of screenshot placeholders that need images
     - Cross-reference suggestions
     ```

   - If delegation fails, display error and halt
   - Receive generated documentation from technical-writer agent

9. **Determine Output Paths**:
   - Based on documentation type, determine output directory:
     - API Reference → `docs/api/`
     - User Guide → `docs/user/`
     - Integration Guide → `docs/integration/`
     - Developer Guide → `docs/developer/`
     - README → Component directory or project root
   - For each documentation file from technical-writer:
     - Generate appropriate filename:
       - API docs: `{endpoint-or-resource-name}.md`
       - User guides: `{feature-or-task-name}.md`
       - Integration: `{integration-type}.md`
       - Developer: `{topic-or-component}.md`
       - README: `README.md`
     - Check if file already exists
     - If exists, ask: "File {path} exists. Overwrite? (y/n/merge)"
     - If merge selected, append content or create versioned file

10. **Create Documentation Files**:
    - Create output directories if they don't exist: `mkdir -p docs/api docs/user docs/integration docs/developer`
    - For each documentation file:
      - Write content to determined path
      - Ensure proper frontmatter is included
      - Validate markdown formatting
      - Track created files for summary
    - If documentation index exists (`docs/README.md` or `docs/index.md`):
      - Update table of contents with new documentation
      - Add links to newly created files
      - Organize by category/type

11. **Stage Documentation Files**:
    - Stage all created/modified documentation files: `git add docs/`
    - If README files created: `git add */README.md`
    - If documentation index updated: `git add docs/README.md docs/index.md`
    - Display staged files for user review

12. **Display Generation Summary**:
    - Show comprehensive summary:

      ```text
      ✓ Documentation Generated Successfully
      ======================================

      Scope: {scope} ({scope-description})
      Type: {documentation-type}
      Audience: {target-audience}
      {If issue context:}
      Issue: #{issue-number} - {issue-title}
      {End if}

      Files Created:
      {For each file:}
      - {file-path} ({word-count} words)
        {If screenshot placeholders:}
        → {count} screenshot placeholders need images
        {End if}
      {End for}

      Total: {file-count} files, {total-words} words

      {If screenshot placeholders exist:}
      Screenshot Placeholders:
      {For each placeholder:}
      - {file-path}: {placeholder-description}
      {End for}
      {End if}

      {If cross-references suggested:}
      Suggested Cross-References:
      {For each suggestion:}
      - Link {file-1} ↔ {file-2}: {reason}
      {End for}
      {End if}

      Next Steps:
      1. Review generated documentation for accuracy
      2. Add screenshots to placeholder sections (if applicable)
      3. Update cross-references if needed
      4. Commit documentation with code changes:
         git commit -m "docs: add {type} documentation for {scope-description}"
      {If on feature branch:}
      5. Include in PR when running /open-pr
      {Else:}
      5. Create PR for documentation updates
      {End if}

      Staged Files:
      {List of staged files}
      ```

13. **Offer Additional Actions**:
    - Ask user: "Would you like to perform any additional actions? (commit/review/cancel)"
    - If "commit":
      - Prompt for commit message (suggest: "docs: add {type} documentation for {scope}")
      - Create commit: `git commit -m "{message}"`
      - Display: "✓ Documentation committed: {commit-hash}"
    - If "review":
      - Display: "Review documentation files and run 'git add' and 'git commit' when ready"
    - If "cancel":
      - Unstage files: `git restore --staged docs/`
      - Display: "Documentation files created but not staged. Review and stage manually."

## Workflow Integration Examples

### Feature Branch Workflow (Most Common)

```bash
# 1. Start work on issue
/start-work 42

# 2. Implement feature
# ... write code ...

# 3. Generate documentation for feature (smart default: branch scope)
/generate-docs
→ Detects feature branch
→ Defaults to branch scope (documents changes only)
→ Prompts for documentation type (API, user, etc.)
→ Delegates to technical-writer agent
→ Creates docs/api/customers.md

# 4. Review and commit
git commit -m "docs: add customer API documentation"

# 5. Create PR with code AND documentation
/open-pr
```text

### Project-Wide Documentation Backfill

```bash
# From main branch or any branch
/generate-docs --project --type api
→ Scans entire project for API endpoints
→ Lists undocumented APIs
→ Generates comprehensive API reference
→ Creates multiple files in docs/api/

# Or with interactive prompts
/generate-docs
→ Select: Entire project
→ Select: API Reference
→ Select: Developers
→ Generates documentation for all APIs
```text

### Specific Component Documentation

```bash
# Document specific files or patterns
/generate-docs --files "src/components/customer/*.tsx" --type developer
→ Analyzes customer components
→ Generates developer documentation
→ Creates docs/developer/customer-components.md

# Or with interactive selection
/generate-docs
→ Select: Specific files/components
→ Enter pattern: "src/components/customer/*.tsx"
→ Select: Developer Guide
→ Select: Developers
```text

### README Generation

```bash
# Generate README for a component
/generate-docs --files "src/components/Dashboard" --type readme
→ Analyzes Dashboard component and related files
→ Generates comprehensive README
→ Creates src/components/Dashboard/README.md

# Generate project README update
/generate-docs --project --type readme --audience developers
→ Analyzes entire project
→ Updates or creates project README.md
```text

## Error Handling

### Scope and Context Errors

- **Not a git repository**: Display error "Must be in a git repository to use /generate-docs"
- **No changes in branch scope**: Display error "No changes found in current branch. Switch to --project scope or --files scope?"
- **File pattern matches no files**: Display error "Pattern '{pattern}' matches no files. Check pattern syntax and try again"
- **Cannot determine scope**: Display error "Unable to determine documentation scope. Please specify --branch, --project, or --files"

### Documentation Type Errors

- **Invalid type argument**: Display error "Invalid type '{type}'. Valid types: api, user, integration, developer, readme"
- **No documentable elements found**: Display error "No documentable elements found in scope. Ensure you're analyzing code files, not config/docs"
- **Type mismatch with scope**: Warn "Documentation type '{type}' may not be appropriate for selected files. Continue? (y/n)"

### Technical Writer Delegation Errors

- **Agent invocation fails**: Display error "Failed to invoke technical-writer agent: {error}. Check agent configuration"
- **Insufficient context**: Display error "Not enough context to generate documentation. Try widening scope or providing more files"
- **Generation timeout**: Display error "Documentation generation timed out. Try smaller scope or fewer files"

### File Creation Errors

- **Permission denied**: Display error "Cannot write to {path}. Check directory permissions"
- **Disk full**: Display error "Insufficient disk space to create documentation files"
- **Invalid filename**: Display error "Cannot create file '{filename}'. Check for invalid characters"
- **Merge conflict on existing docs**: Display error "Cannot merge with existing {path}. Choose overwrite or manual merge"

### Git Staging Errors

- **Cannot stage files**: Display error "Failed to stage documentation files: {error}. Stage manually with 'git add docs/'"
- **Detached HEAD state**: Warn "In detached HEAD state. Documentation created but not staged. Create branch before committing"

## Examples

```bash
# Smart default - detects branch and suggests scope
/generate-docs

# Explicit branch scope with type
/generate-docs --branch --type api

# Full project API documentation
/generate-docs --project --type api --audience developers

# Specific files with user guide
/generate-docs --files "src/features/onboarding/**/*.tsx" --type user --audience customers

# Integration documentation for specific API files
/generate-docs --files "pages/api/integrations/*.ts" --type integration --audience partners

# Component README generation
/generate-docs --files "src/components/CustomerDashboard" --type readme
```text

## Notes

- **Smart Defaults**: Command detects branch context and suggests appropriate scope
- **Interactive Prompts**: User-friendly prompts for all required selections
- **Technical Writer Delegation**: Leverages technical-writer agent's expertise and knowledge base
- **Multi-Tenant Safe**: All generated documentation is configuration-driven (no hardcoded client data)
- **Comprehensive Output**: Includes frontmatter, code examples, cross-references, screenshot placeholders
- **Workflow Integration**: Designed to run after implementation, before PR creation
- **Flexible Scoping**: Supports branch-level, project-level, and file-specific documentation
- **Audience-Aware**: Content tailored to developers, customers, or integration partners
- **Version Controlled**: Documentation changes are staged and ready for commit
- **Quality Assurance**: Technical-writer agent ensures professional documentation standards

## Success Criteria

- [ ] Command detects current branch context and suggests smart defaults
- [ ] Supports three scope modes: branch, project, file-specific
- [ ] Prompts for documentation type (API, user, integration, developer, README)
- [ ] Prompts for target audience (developers, customers, partners)
- [ ] Analyzes code files to identify documentable elements
- [ ] Successfully delegates to technical-writer agent with comprehensive context
- [ ] Generates documentation with proper frontmatter and metadata
- [ ] Includes code examples with syntax highlighting
- [ ] Creates files in appropriate directory structure (docs/api/, docs/user/, etc.)
- [ ] Ensures configuration-driven content (no hardcoded client data)
- [ ] Adds screenshot placeholders where visual documentation needed
- [ ] Includes cross-references to related documentation
- [ ] Stages created files for git commit
- [ ] Provides clear output summary with file paths and word counts
- [ ] Integrates smoothly with feature workflow (/start-work → code → /generate-docs → /open-pr)
- [ ] Handles errors gracefully with helpful error messages

## Related Commands

- `/start-work <issue-id>` - Start work on an issue (begin feature development)
- `/open-pr` - Create pull request (include documentation with code changes)
- `/create-issue` - Create new GitHub issue (may need documentation as deliverable)
- `/cleanup-main` - Post-merge cleanup (after documentation PR is merged)

## Related Agents

- `technical-writer` - Primary agent for documentation generation (handles all writing)
- `claude-agent-manager` - If creating documentation about agents/commands
- `devops-engineer` - For git operations and branch management

## Integration Notes

**With `/start-work`**:

- Run `/generate-docs` after implementing feature to document changes
- Uses issue context from `.github/issues/in-progress/issue-{id}/` for better documentation

**With `/open-pr`**:

- Generated documentation should be committed before running `/open-pr`
- Documentation commits are included in PR along with code changes
- PR description can reference new documentation files

**With Feature Workflow**:

1. `/start-work {issue}` - Begin feature implementation
2. Implement feature code
3. `/generate-docs` - Document the feature (default: branch scope)
4. Review and commit documentation
5. `/open-pr` - Create PR with code and docs

**With Multi-Tenant Architecture**:

- All generated documentation uses configuration placeholders
- No hardcoded company names, URLs, or client-specific data
- Examples use environment variables and configuration objects
- Technical-writer agent ensures white-label compatibility
