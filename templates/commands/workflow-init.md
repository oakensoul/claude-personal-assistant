---
name: workflow-init
description: Initialize workflow configuration for a project with interactive setup
model: sonnet[1m+]
args: {}
---

# Workflow Init Command

Interactively initialize workflow configuration for a project. Creates `${CLAUDE_CONFIG_DIR}/workflow-config.json` and optionally sets up directory structure for issue tracking, time tracking, and documentation.

## Usage

```bash
/workflow-init
```text

## Instructions

1. **Check Existing Configuration**:
   - Check if `${CLAUDE_CONFIG_DIR}/workflow-config.json` already exists
   - If exists:
     - Display: "Workflow configuration already exists at ${CLAUDE_CONFIG_DIR}/workflow-config.json"
     - Ask: "Would you like to (r)econfigure, (v)iew existing, or (c)ancel? [r/v/c]"
     - If view: Display current config and exit
     - If cancel: Exit command
     - If reconfigure: Continue with backup of existing config
   - Create backup if reconfiguring: `${CLAUDE_CONFIG_DIR}/workflow-config.json.backup.{timestamp}`

2. **Welcome and Overview**:
   - Display welcome message:

     ```
     🚀 Workflow Configuration Setup
     ================================

     This will help you configure:
     • Issue tracking and documentation
     • Time tracking
     • Branch naming conventions
     • Pull request automation
     • GitHub issue creation

     You can skip any section by pressing Enter for defaults.
     Press Ctrl+C to cancel at any time.
     ```

3. **Detect Project Type**:
   - Check for language/framework indicators:
     - `package.json` → Node.js/JavaScript
     - `pyproject.toml` or `setup.py` → Python
     - `Cargo.toml` → Rust
     - `go.mod` → Go
     - `composer.json` → PHP
   - Check for existing directories:
     - `.github/` → GitHub integration present
     - `docs/` → Documentation directory
   - Store detected info for smart defaults

4. **Configure Issue Tracking**:
   - Display section header:

     ```
     📋 Issue Tracking Configuration
     ================================
     ```

   - Ask: "Enable issue tracking and documentation? [Y/n]"
     - Default: Yes
     - If no: Set `issue_tracking.enabled = false`, skip to step 5

   - Ask: "Where should issue documentation be stored?"
     - Options:

       ```
       1. .github/issues (recommended for GitHub projects)
       2. ${CLAUDE_CONFIG_DIR}/issues
       3. docs/issues
       4. Custom path
       ```

     - Default: `.github/issues` if `.github/` exists, else `${CLAUDE_CONFIG_DIR}/issues`
     - If custom: Prompt for path

   - Ask: "Subdirectory for in-progress issues? [in-progress]"
     - Default: `in-progress`

   - Ask: "Subdirectory for completed issues? [completed]"
     - Default: `completed`

   - Preview:

     ```
     Issue tracking structure:
     {directory}/
       {in-progress}/
         issue-{id}/
           README.md
       {completed}/
         issue-{id}/
           README.md
     ```

   - Ask: "Create directories now? [Y/n]"
     - If yes: Create `{directory}/{in-progress}/` and `{directory}/{completed}/`
     - Add to `.gitignore`: `{directory}/{in-progress}/` (keep in-progress issues out of git)

5. **Configure Time Tracking**:
   - Display section header:

     ```
     ⏱️  Time Tracking Configuration
     ================================
     ```

   - Ask: "Enable time tracking? [Y/n]"
     - Default: Yes
     - If no: Set `time_tracking.enabled = false`, skip to step 6

   - Ask: "Where should time logs be stored? [.time-tracking]"
     - Default: `.time-tracking`

   - Ask: "Prefix for time-tracking branches? [time-tracking]"
     - Default: `time-tracking`
     - Explain: "Branches will be named: {prefix}/{developer}/{date}"

   - Ask: "Create time-tracking directory now? [Y/n]"
     - If yes: Create `{directory}/`
     - Add to `.gitignore`: `{directory}/*.md` (keep logs private until ready to commit)

6. **Configure Branching**:
   - Display section header:

     ```
     🌿 Branch Naming Configuration
     ================================
     ```

   - Ask: "Branch naming format:"
     - Options:

       ```
       1. milestone-v{milestone}/{type}/{id}-{description} (default - includes milestone)
       2. {type}/{id}-{description} (simple - no milestone)
       3. {type}/{id} (minimal)
       4. {id}-{description} (no type prefix)
       5. Custom format
       ```

     - Default: Option 1
     - If custom: Prompt for format template
     - Explain available placeholders: {milestone}, {type}, {id}, {description}

   - Ask: "Require milestone for all branches? [Y/n]"
     - Default: Yes if milestone in format, No otherwise
     - Warn: "If yes, /start-work will fail if issue has no milestone"

7. **Configure Pull Request Automation**:
   - Display section header:

     ```
     🔄 Pull Request Configuration
     ================================
     ```

   - **Versioning**:
     - Ask: "Enable automatic versioning? [Y/n]"
       - Default: Yes if package.json/pyproject.toml/Cargo.toml/install.sh detected
       - If no: Skip version config

     - Ask: "Which files contain version numbers?" (multi-select)
       - If Node.js detected: Default `package.json`
       - If Python detected: Default `pyproject.toml`
       - If Rust detected: Default `Cargo.toml`
       - If Shell script detected (install.sh, setup.sh): Default `install.sh`
       - Allow adding more: "Enter additional files (comma-separated, or press Enter to skip)"
       - Explain: "For bash/shell scripts, list files with VERSION= declarations"

     - Ask: "Changelog file path? [CHANGELOG.md]"
       - Default: `CHANGELOG.md`
       - Note: Supports both root and docs/ subdirectory

     - Ask: "Update README with latest changelog entries? [Y/n]"
       - Default: Yes
       - If yes, ask: "README path? [README.md]"

   - **Reviewer Assignment**:
     - Ask: "How should reviewers be assigned?"
       - Options:

         ```
         1. none - No automatic reviewer assignment (default)
         2. query - Ask who should review when creating PR (most flexible)
         3. list - Assign all team members to every PR
         4. round-robin - Rotate through team members
         5. auto - Let GitHub suggest reviewers
         ```

       - Default: `none`

     - If query:
       - Ask: "Enter team member GitHub usernames for suggestions (comma-separated, or press Enter to skip):"
       - Parse and validate usernames (optional)
       - Explain: "You'll be prompted to select reviewers when running /open-pr"
       - Note: "You can always override with: /open-pr reviewers=\"user1,user2\""

     - If list:
       - Ask: "Enter team member GitHub usernames (comma-separated):"
       - Parse and validate usernames
       - Show assignment: "Every PR will be assigned to: user1, user2, user3"
       - Example use case: "Useful for small teams or always including bots like github-copilot[bot]"

     - If round-robin:
       - Ask: "Enter team member GitHub usernames (comma-separated):"
       - Parse and validate usernames
       - Show rotation order: "Reviewers will rotate: user1 → user2 → user3 → user1..."

   - **Merge Strategy**:
     - Ask: "Expected merge strategy?"
       - Options:

         ```
         1. squash - Squash commits when merging (default)
         2. merge - Standard merge commit
         3. rebase - Rebase and merge
         ```

       - Default: `squash`
       - Explain: "This affects /cleanup-main behavior"

8. **Configure Issue Creation**:
   - Display section header:

     ```
     🎯 Issue Creation Configuration
     ================================
     ```

   - Ask: "Require milestone when creating issues? [Y/n]"
     - Default: Same as branching milestone requirement

   - Ask: "Auto-assign issues to creator? [y/N]"
     - Default: No

   - Ask: "Use structured issue body template? [Y/n]"
     - Default: Yes
     - Explain: "Includes sections for Requirements, Technical Details, Success Criteria"

9. **Configure Product Manager** (NEW):
   - Display section header:

     ```
     👔 Product Manager Configuration
     =================================

     This has TWO parts:
     1. YOUR PERSONAL PM PHILOSOPHY (applies to ALL projects)
     2. THIS PROJECT'S SPECIFIC REQUIREMENTS (applies to this project only)
     ```

   - **PART 1: User-Level Configuration (Applies to ALL Projects)**
     - Display:

       ```
       📋 Part 1: Your Personal PM Philosophy
       ======================================
       Location: ~/${CLAUDE_CONFIG_DIR}/agents/product-manager/
       Scope: Applies to ALL your projects

       ```

   - Check if user-level PM exists: `~/${CLAUDE_CONFIG_DIR}/agents/product-manager/`
   - If not exists:
     - Display: "No personal Product Manager agent found. Let's create one!"
     - Ask: "What's your PERSONAL product management philosophy? (This will be used across all your projects)"
       - Options:

         ```
         1. User-first (prioritize UX over features)
         2. Data-driven (metrics and analytics guide decisions)
         3. Business-focused (revenue and growth priority)
         4. Engineering-led (technical excellence first)
         5. Balanced (pragmatic mix of all above)
         6. Custom
         ```

       - Default: Balanced

     - Ask: "What's your PERSONAL prioritization framework? (Your default approach across all projects)"
       - Options:

         ```
         1. RICE (Reach, Impact, Confidence, Effort)
         2. Value vs Complexity
         3. MoSCoW (Must/Should/Could/Won't)
         4. WSJF (Weighted Shortest Job First)
         5. Custom
         ```

       - Default: Value vs Complexity

     - Ask: "How do you PERSONALLY prefer to communicate with stakeholders? (Your general style)"
       - Options:

         ```
         1. Concise (bullet points, executive summaries)
         2. Detailed (comprehensive docs with context)
         3. Visual (diagrams and mockups heavy)
         4. Conversational (discussion-oriented)
         ```

       - Default: Concise

     - Display: "Creating user-level PM agent at ~/${CLAUDE_CONFIG_DIR}/agents/product-manager/"
     - Create user-level PM agent with these preferences
     - Update `~/${CLAUDE_CONFIG_DIR}/agents/product-manager/instructions.md`
     - Update `~/${CLAUDE_CONFIG_DIR}/agents/product-manager/knowledge/preferences.md`
     - Display: "✓ Personal PM philosophy saved (will be reused across all projects)"

   - If exists:
     - Display: "✓ Found existing personal Product Manager agent at ~/${CLAUDE_CONFIG_DIR}/agents/product-manager/"
     - Ask: "Reconfigure your PERSONAL PM philosophy? (affects all projects) [y/N]"
       - If yes: Follow creation flow above
       - If no: Display "✓ Using existing personal PM philosophy"

   - **PART 2: Project-Level Configuration (THIS PROJECT ONLY)**
     - Display:

       ```

       📋 Part 2: This Project's Specific Requirements
       ===============================================
       Location: {project-path}/${CLAUDE_CONFIG_DIR}/agents/product-manager/
       Scope: Applies ONLY to this project

       ```

     - Ask: "What's THIS PROJECT'S domain?"
       - Options:

         ```
         1. Developer Tools (frameworks, libraries, CLI)
         2. Web Application (SaaS, e-commerce)
         3. System Utilities (automation, scripting)
         4. Data/Analytics
         5. Mobile Application
         6. Enterprise Software
         7. Custom
         ```

       - Default: Based on detected project type

     - Ask: "What product patterns apply to THIS PROJECT?" (multi-select)
       - Options:

         ```
         [ ] Open source (community-driven)
         [ ] Enterprise (compliance, support SLAs)
         [ ] Dogfooding (we use what we build)
         [ ] API-first (developer experience priority)
         [ ] Privacy-focused (data protection critical)
         [ ] Performance-critical (speed matters most)
         ```

     - Ask: "THIS PROJECT'S specific PM instructions (optional):"
       - Example: "AIDA uses AGPL-3.0 license, semantic versioning required, developer experience is paramount"
       - Display: "Creating project-specific PM config at {project-path}/${CLAUDE_CONFIG_DIR}/agents/product-manager/"
       - Create `{project-path}/${CLAUDE_CONFIG_DIR}/agents/product-manager/instructions.md`

     - Display:

       ```
       ✓ Product Manager configured:
         - Personal philosophy: ~/${CLAUDE_CONFIG_DIR}/agents/product-manager/ (all projects)
         - Project requirements: {project-path}/${CLAUDE_CONFIG_DIR}/agents/product-manager/ (this project only)
       ```

10. **Configure Tech Lead** (NEW):
    - Display section header:

      ```
      🔧 Tech Lead Configuration
      ==============================

      This has TWO parts:
      1. YOUR PERSONAL TECH PHILOSOPHY (applies to ALL projects)
      2. THIS PROJECT'S SPECIFIC REQUIREMENTS (applies to this project only)
      ```

    - **PART 1: User-Level Configuration (Applies to ALL Projects)**
      - Display:

        ```
        ⚙️  Part 1: Your Personal Tech Philosophy
        ========================================
        Location: ~/${CLAUDE_CONFIG_DIR}/agents/tech-lead/
        Scope: Applies to ALL your projects

        ```

    - Check if user-level Tech Lead exists: `~/${CLAUDE_CONFIG_DIR}/agents/tech-lead/`
    - If not exists:
      - Display: "No personal Tech Lead agent found. Let's create one!"
      - Ask: "What's your PERSONAL technical philosophy? (This will be used across all your projects)"
        - Options:

          ```
          1. Pragmatic (balance speed and quality)
          2. Perfectionist (high standards, comprehensive)
          3. Minimalist (simplicity over features)
          4. Innovative (cutting-edge technology adoption)
          5. Conservative (proven, stable technologies)
          6. Custom
          ```

        - Default: Pragmatic

      - Ask: "Your PERSONAL primary technology stack? (Your general expertise across all projects)" (multi-select)
        - Options (show relevant ones):

          ```
          Languages:
          [ ] Bash/Shell scripting
          [ ] JavaScript/Node.js
          [ ] TypeScript
          [ ] Python
          [ ] Rust
          [ ] Go
          [ ] PHP
          [ ] Other: ___

          Frameworks:
          [ ] React/Next.js
          [ ] Vue
          [ ] Express
          [ ] FastAPI
          [ ] Other: ___

          Tools:
          [ ] Git
          [ ] Docker
          [ ] Kubernetes
          [ ] CI/CD (GitHub Actions, etc.)
          [ ] Other: ___
          ```

      - Ask: "Architecture patterns you PERSONALLY prefer? (Your general approach)" (multi-select)
        - Options:

          ```
          [ ] Monolith
          [ ] Microservices
          [ ] Serverless
          [ ] Event-driven
          [ ] Layered architecture
          [ ] Hexagonal/Clean architecture
          [ ] Modular/Plugin
          ```

      - Ask: "Your PERSONAL code review priorities? (rank all in order of importance)"
        - Options:

          ```
          1. Security
          2. Performance
          3. Maintainability
          4. Test coverage
          5. Documentation
          6. Consistency with standards
          ```

        - Default: Maintainability, Security, Consistency with standards
        - Note: "Rank ALL items in order (e.g., '3,1,6,5,2,4')"

      - Display: "Creating user-level Tech Lead agent at ~/${CLAUDE_CONFIG_DIR}/agents/tech-lead/"
      - Create user-level Tech Lead with these preferences
      - Update `~/${CLAUDE_CONFIG_DIR}/agents/tech-lead/instructions.md`
      - Update `~/${CLAUDE_CONFIG_DIR}/agents/tech-lead/knowledge/tech-stack.md`
      - Update `~/${CLAUDE_CONFIG_DIR}/agents/tech-lead/knowledge/standards.md`
      - Display: "✓ Personal Tech Lead philosophy saved (will be reused across all projects)"

    - If exists:
      - Display: "✓ Found existing personal Tech Lead agent at ~/${CLAUDE_CONFIG_DIR}/agents/tech-lead/"
      - Ask: "Reconfigure your PERSONAL Tech Lead philosophy? (affects all projects) [y/N]"
        - If yes: Follow creation flow above
        - If no: Display "✓ Using existing personal Tech Lead philosophy"

    - **PART 2: Project-Level Configuration (THIS PROJECT ONLY)**
      - Display:

        ```

        ⚙️  Part 2: This Project's Specific Requirements
        ===============================================
        Location: {project-path}/${CLAUDE_CONFIG_DIR}/agents/tech-lead/
        Scope: Applies ONLY to this project

        ```

      - Display: "Detected tech stack for THIS PROJECT: {detected-technologies}"
      - Ask: "Does THIS PROJECT use additional technologies? (comma-separated, or Enter to skip)"
        - Auto-detect from project (package.json, pyproject.toml, install.sh, etc.)
        - Example: "docker, github-actions, shellcheck"

      - Ask: "THIS PROJECT'S specific technical guidelines (optional):"
        - Example: "All shell scripts must pass shellcheck, use bash 3.2+ for macOS compatibility, container-based testing required"
        - Display: "Creating project-specific Tech Lead config at {project-path}/${CLAUDE_CONFIG_DIR}/agents/tech-lead/"
        - Create `{project-path}/${CLAUDE_CONFIG_DIR}/agents/tech-lead/instructions.md`

      - Display:

        ```
        ✓ Tech Lead configured:
          - Personal philosophy: ~/${CLAUDE_CONFIG_DIR}/agents/tech-lead/ (all projects)
          - Project requirements: {project-path}/${CLAUDE_CONFIG_DIR}/agents/tech-lead/ (this project only)
        ```

11. **Configure Expert Analysis** (NEW):
    - Display section header:

      ```
      🔬 Expert Analysis Workflow
      ===============================
      ```

    - Ask: "Enable expert analysis workflow? [Y/n]"
      - Default: Yes if both PM and Tech Lead configured
      - Explain: "Coordinates multi-agent analysis for requirements and technical specs"
      - If no: Set `expert_analysis.enabled = false`, skip to step 12

    - **Product Analysis Agents**:
      - Display: "Select product stakeholder agents (in addition to Product Manager):"
      - Show available agents from `~/${CLAUDE_CONFIG_DIR}/agents/` and global agents:

        ```
        Available agents:
        [ ] configuration-specialist (configuration design)
        [ ] integration-specialist (cross-system integration)
        [ ] privacy-security-auditor (privacy and security)
        [ ] aida-product-manager (AIDA-specific PM)
        [ ] larp-product-manager (LARP-specific PM)
        [x] Select all relevant
        [ ] None (PM only)
        ```

      - Default: Auto-select based on project type

    - **Technical Analysis Agents**:
      - Display: "Select technical implementation agents (in addition to Tech Lead):"
      - Show available agents:

        ```
        Available agents:
        [ ] shell-script-specialist (bash/shell expertise)
        [ ] devops-engineer (CI/CD, deployment)
        [ ] shell-systems-ux-designer (CLI UX design)
        [ ] nextjs-engineer (Next.js/React)
        [ ] php-engineer (PHP development)
        [ ] strapi-backend-engineer (Strapi CMS)
        [ ] api-design-architect (API design)
        [x] Select all relevant
        [ ] None (Tech Lead only)
        ```

      - Default: Auto-select based on detected tech stack

    - **Q&A Mode**:
      - Ask: "How should stakeholder Q&A work?"
        - Options:

          ```
          1. Interactive - Ask each question one at a time (thorough)
          2. Batch - Show all questions, collect all answers (faster)
          ```

        - Default: Interactive

    - **Document Format**:
      - Ask: "Document style preference?"
        - Options:

          ```
          1. Concise - Bullet points, executive summaries (recommended)
          2. Comprehensive - Detailed explanations and context
          ```

        - Default: Concise

    - Preview configuration:

      ```
      Expert Analysis Configuration:
      • Product Manager: product-manager
      • Tech Lead: tech-lead
      • Product agents: {list}
      • Technical agents: {list}
      • Q&A mode: {interactive|batch}
      • Document format: {concise|comprehensive}
      ```

    - Display: "✓ Expert analysis workflow configured"
    - Display: "   Run /expert-analysis after /start-work to begin analysis"

12. **Generate Configuration File**:

- Build complete configuration object from answers
- Show preview:

     ```
     📄 Configuration Preview
     ========================

     {Pretty-printed JSON configuration}

     This will be saved to: ${CLAUDE_CONFIG_DIR}/workflow-config.json
     ```

- Ask: "Save this configuration? [Y/n]"
  - If no: Ask "Would you like to (e)dit answers, (c)ancel, or (s)ave anyway? [e/c/s]"
  - If edit: Go back to specific section
  - If cancel: Exit without saving

- Create `${CLAUDE_CONFIG_DIR}/` directory if not exists
- Write configuration to `${CLAUDE_CONFIG_DIR}/workflow-config.json`
- Format JSON with 2-space indentation for readability

12.1. **GitHub Configuration**:

The workflow-config.json now includes a comprehensive GitHub configuration section:

- **Label Architecture**: 26 labels for version control and build strategies
- **Issue → PR Mapping**: Automatic label application based on issue type
- **Build Logic**: Multi-domain detection and override support
- **Project Configuration**: Status values and board views

For complete label taxonomy and usage guidelines, see:
- `docs/development/LABELS.md` - Label reference guide
- `.github/GITHUB_SETUP_GUIDE.md` - Manual setup instructions

**Next Step**: After workflow-init completes, run `/github-init` to set up GitHub repository with labels and automations.

13. **Optional: Add to .gitignore**:
    - Check if `.gitignore` exists in project root
    - Ask: "Add workflow directories to .gitignore? [Y/n]"
      - Default: Yes
    - If yes, append:

      ```
      # Claude Code Workflow
      {issue_tracking.directory}/drafts/
      {issue_tracking.directory}/{issue_tracking.states.in_progress}/
      {time_tracking.directory}/*.md
      ```

    - Note: drafts/ are local-only (not published yet), in-progress/ is active work

14. **Optional: Create README for Issue Directory**:
    - If issue tracking enabled and directory created
    - Ask: "Create README for issue tracking directory? [Y/n]"
      - Default: Yes
    - Create `{issue_tracking.directory}/README.md`:

      ```markdown
      # Issue Documentation

      This directory contains documentation for GitHub issues.

      ## Structure

      - `drafts/` - Local issue drafts (gitignored, not yet published)
      - `{in-progress}/` - Active work on issues (gitignored)
      - `{completed}/` - Completed issues with resolution details (committed)

      ## Workflow

      1. Create issue draft: `/create-issue`
         - Creates: `drafts/milestone-vX.Y/{type}-{slug}/README.md`
         - Draft is local-only, can be refined before publishing

      2. Publish draft to GitHub: `/publish-issue {slug}`
         - Creates GitHub issue
         - Deletes local draft

      3. Start work on published issue: `/start-work <github-issue-id>`
         - Creates: `{in-progress}/issue-<id>/README.md`
         - Contains issue details and requirements

      4. Work on the issue and update notes

      5. Create PR when ready: `/open-pr`
         - Moves to: `{completed}/issue-<id>/README.md`
         - Adds resolution details and PR link

      ## Notes

      - Drafts are gitignored (local refinement space)
      - In-progress issues are gitignored (active work)
      - Completed issues are committed with PRs
      - Each issue has its own directory for related files
      ```

15. **Summary and Next Steps**:
    - Display success message:

      ```
      ✅ Workflow Configuration Complete!
      ===================================

      Created:
      ✓ ${CLAUDE_CONFIG_DIR}/workflow-config.json
      {If PM created:}
      ✓ ~/${CLAUDE_CONFIG_DIR}/agents/product-manager/
      {End if}
      {If Tech Lead created:}
      ✓ ~/${CLAUDE_CONFIG_DIR}/agents/tech-lead/
      {End if}
      {If directories created:}
      ✓ {issue_tracking.directory}/{in-progress}/
      ✓ {issue_tracking.directory}/{completed}/
      ✓ {time_tracking.directory}/
      {End if}
      {If gitignore updated:}
      ✓ Updated .gitignore
      {End if}

      Configuration Summary:
      • Issue tracking: {enabled/disabled}
      • Time tracking: {enabled/disabled}
      • Branch format: {format}
      • Versioning: {enabled/disabled}
      • Reviewers: {strategy}
      • Merge strategy: {strategy}
      {If PM configured:}
      • Product Manager: Configured for {domain}
      {End if}
      {If Tech Lead configured:}
      • Tech Lead: Configured with {tech-stack}
      {End if}
      {If Expert Analysis enabled:}
      • Expert Analysis: Enabled with {agent-count} agents
      {End if}

      Next Steps:
      1. Review configuration: cat ${CLAUDE_CONFIG_DIR}/workflow-config.json

      2. Set up GitHub repository (RECOMMENDED):
         /github-init

         This will:
         • Create all 26 GitHub labels
         • Set up project board automations
         • Configure verification cache
         • Guide through manual setup steps

      3. Test workflow commands:
         /create-issue        - Create a GitHub issue
         /start-work <id>     - Start work on an issue
         {If Expert Analysis enabled:}
         /expert-analysis     - Run multi-agent analysis on current issue
         {End if}
         /track-time 2h       - Log development time
         /open-pr             - Create pull request

      4. Customize further if needed:
         {editor} ${CLAUDE_CONFIG_DIR}/workflow-config.json

      Documentation: {path-to-README-if-exists}
      ```

## Examples

```bash
# Interactive setup
/workflow-init

# The command will guide you through:
# 1. Issue tracking setup
# 2. Time tracking configuration
# 3. Branch naming conventions
# 4. PR automation settings
# 5. Issue creation preferences
```text

## Common Configurations

### Minimal Setup (No Workflow)

```text
Issue tracking: No
Time tracking: No
Branch format: {type}/{id}
Versioning: No
Reviewers: none
```text

### Standard GitHub Project

```text
Issue tracking: Yes (.github/issues)
Time tracking: Yes (.time-tracking)
Branch format: milestone-v{milestone}/{type}/{id}-{description}
Versioning: Yes (package.json, CHANGELOG.md)
Reviewers: round-robin (team members)
Merge strategy: squash
```text

### Simple Solo Project

```text
Issue tracking: Yes (${CLAUDE_CONFIG_DIR}/issues)
Time tracking: No
Branch format: {type}/{id}
Versioning: Yes (package.json only)
Reviewers: none
Merge strategy: merge
```text

### Small Team with GitHub Copilot

```text
Issue tracking: Yes (.github/issues)
Time tracking: Yes (.time-tracking)
Branch format: milestone-v{milestone}/{type}/{id}-{description}
Versioning: Yes (package.json, CHANGELOG.md)
Reviewers: list (all team members + github-copilot[bot])
Merge strategy: squash
```text

### Flexible Review Assignment

```text
Issue tracking: Yes (.github/issues)
Time tracking: No
Branch format: {type}/{id}-{description}
Versioning: Yes (package.json)
Reviewers: query (prompt at PR creation)
Merge strategy: squash
```text

## Error Handling

- **Permission denied**: Display error if cannot write to ${CLAUDE_CONFIG_DIR}/ or project directories
- **Invalid team member**: Warn if GitHub username doesn't exist (optional validation)
- **Existing config**: Safely backup before overwriting
- **Git not initialized**: Warn that some features require git repository
- **No package.json**: Suggest manual version file configuration

## Configuration Schema

The command generates configuration conforming to `workflow-config.schema.json`:

```json
{
  "workflow": {
    "issue_tracking": {
      "enabled": true,
      "directory": ".github/issues",
      "states": {
        "in_progress": "in-progress",
        "completed": "completed"
      }
    },
    "time_tracking": {
      "enabled": true,
      "directory": ".time-tracking",
      "branch_prefix": "time-tracking"
    },
    "branching": {
      "format": "milestone-v{milestone}/{type}/{id}-{description}",
      "requires_milestone": true
    },
    "pull_requests": {
      "versioning": {
        "enabled": true,
        "files": ["package.json"],
        "changelog": "CHANGELOG.md",
        "readme_summary": true,
        "readme_path": "README.md"
      },
      "reviewers": {
        "strategy": "round-robin",
        "team": ["user1", "user2"]
      },
      "comments": {
        "strategy_options": ["none", "query", "list", "round-robin", "auto"],
        "query_example": {"strategy": "query", "team": ["user1", "user2"]},
        "list_example": {"strategy": "list", "team": ["user1", "github-copilot[bot]"]},
        "none_example": {"strategy": "none"},
        "auto_example": {"strategy": "auto"}
      },
      "merge_strategy": "squash"
    },
    "issue_creation": {
      "requires_milestone": true,
      "auto_assign": false,
      "templates": {
        "use_structured_body": true
      }
    },
    "expert_analysis": {
      "enabled": true,
      "product_manager": {
        "agent": "product-manager",
        "domain": "Developer Tools",
        "patterns": ["open source", "dogfooding"]
      },
      "tech_lead": {
        "agent": "tech-lead",
        "philosophy": "pragmatic",
        "tech_stack": ["bash", "javascript", "typescript"]
      },
      "agents": {
        "product": ["configuration-specialist", "integration-specialist"],
        "technical": ["shell-script-specialist", "devops-engineer"]
      },
      "qa_mode": "interactive",
      "document_format": "concise"
    }
  }
}
```text

## Integration Notes

- **Works with all workflow commands**: `/start-work`, `/expert-analysis`, `/open-pr`, `/track-time`, `/create-issue`, `/cleanup-main`
- **Validates configuration**: Checks paths exist, creates if needed
- **Smart defaults**: Detects project type and suggests appropriate settings
- **Safe overwrite**: Backs up existing config before changes
- **Git integration**: Optional .gitignore updates for privacy
- **Agent creation**: Creates user-level Product Manager and Tech Lead agents
- **Project customization**: Stores project-specific PM and Tech Lead knowledge

## Related Commands

- `/start-work <issue-id>` - Uses issue_tracking and branching config
- `/expert-analysis` - Uses expert_analysis config for multi-agent workflow
- `/open-pr` - Uses versioning, reviewers, and merge_strategy config
- `/track-time <hours>` - Uses time_tracking config
- `/create-issue` - Uses issue_creation config
- `/cleanup-main` - Uses merge_strategy config

## Notes

- Configuration is project-specific (stored in `${CLAUDE_CONFIG_DIR}/workflow-config.json`)
- Can be committed to version control to share with team
- Can be reconfigured anytime by running `/workflow-init` again
- All settings are optional - commands work with defaults if config missing
- Interactive prompts make it easy for non-technical users

---

**Remember**: This command makes workflow setup accessible to everyone. Smart defaults mean users can hit Enter through most questions and get a working configuration.
