---
title: "ADR-010: Command Structure Refactoring"
status: "accepted"
date: "2025-10-16"
deciders: ["rob", "system-architect"]
consulted: []
informed: []
---

# ADR-010: Command Structure Refactoring

## Status

**Accepted** - 2025-10-16

## Context

AIDA currently has 29 commands with inconsistent naming and organization. After implementing:

- ADR-006: Analyst/Engineer Agent Pattern
- ADR-007: Product/Platform/API Engineering Model
- ADR-008: Engineers Own Testing Philosophy
- ADR-009: Skills System Architecture

We need to refactor commands to align with these architectural decisions and provide a clear, workflow-oriented command structure.

### Current Issues

1. **Inconsistent naming**: `/create-agent` vs `/start-work` vs `/open-pr`
2. **Technology-focused**: `/github-init`, `/start-work` emphasize technology over workflow
3. **Unclear grouping**: No visual grouping of related commands
4. **Missing meta-commands**: No way to list, optimize, or validate agents/skills/commands
5. **Agent naming confusion**: "claude-agent-manager" unclear scope

### Key Insights

#### 1. Developers Think in Workflows, Not Technologies

When working, developers don't think:

- ❌ "I need to interact with GitHub issues"
- ✅ "I need to plan my work"

When managing AIDA, developers don't think:

- ❌ "I need the Claude agent manager"
- ✅ "I need to optimize my agents"

#### 2. Granularity Builds Trust (Critical for AI Adoption)

**The fundamental challenge**: Developers won't trust "Do issue X from start to finish and commit it."

**Why command granularity matters**: We're bringing developers into agentic workflows. They need **baby steps** where they can:

- See what the AI did
- Verify each step
- Course-correct when needed
- Build confidence gradually
- Maintain control throughout

**Each command is a trust checkpoint**, not just a technical step.

### The Trust Journey

Developers move through adoption stages:

#### Stage 1: "I don't trust AI at all"

```text
/issue-create       # I'll write my own issue
/issue-publish      # I'll publish it myself
/issue-start        # OK, AI can set up my branch... I'll verify
```

→ **Trust building**: AI handles low-risk setup tasks

#### Stage 2: "AI can help, but I verify everything"

```text
/issue-analyze      # AI analyzes → I review → iterate
/issue-implement    # AI suggests code → I review each change
/issue-checkpoint   # I control my own commits and progress
```

→ **Trust building**: AI provides value, human retains control

#### Stage 3: "I'm building confidence"

```text
/issue-pause        # AI manages context switching (low risk)
/issue-resume       # Shows me where I left off (useful!)
/issue-review       # Multiple review gates (quality, security)
```

→ **Trust building**: AI handles more, but with transparency

#### Stage 4: "I trust the workflow"

```text
/issue-submit       # AI handles PR creation (I've verified everything)
/issue-complete     # Cleanup is safe to automate
```

→ **Trust achieved**: Developer confidently delegates

**Key principle**: Each command is **optional**. Developers skip steps as they gain confidence, but granularity remains for those who need control.

## Decision

### 1. Workflow-Oriented Command Naming

**Principle**: Commands reflect **what you're doing** (workflow), not **what you're using** (technology).

**Issue Workflow** (work happens around issues):

```text
/issue-create       Create issue draft locally
/issue-publish      Publish to work tracker (GitHub, Jira, etc.)
/issue-start        Start work (branch, workspace)
/issue-analyze      Analyze requirements (business + technical)
/issue-implement    Implement the solution
/issue-checkpoint   Save progress (commit, log time, document)
/issue-pause        Context switch (stash changes, return to main)
/issue-resume       Resume paused issue (checkout branch, unstash)
/issue-review       Review work (quality, security, compliance)
/issue-ship-it      🚢 Create PR and ship it!
/issue-complete     Complete and cleanup
```

**Why "issue" prefix**: The unit of work is an **issue** (technology-agnostic: GitHub, Jira, Trello, etc.)

**Why all 11 steps**: Each step is a **conversation waypoint** - natural places to pause, reflect, discuss, iterate. Not just automation.

**Why "ship-it"**: Makes shipping code FUN. You should feel excited typing `/issue-ship-it`! 🚢

### 2. Noun-Verb Naming Convention

**Pattern**: `/{noun}-{verb}` (not `/{verb}-{noun}`)

**Examples**:

- `/agent-create` (not `/create-agent`)
- `/issue-start` (not `/start-work`)
- `/pr-open` (not `/open-pr`)

**Rationale**:

- **Visual grouping**: `/agent-*`, `/issue-*`, `/skill-*`, `/pr-*`
- **Autocomplete-friendly**: Type `/agent` → see all agent commands
- **Semantic clarity**: Clear what you're operating on

**Migration**: Support both old and new names via aliases during transition.

### 3. Semantic Prefixes for Grouping

**Principle**: Use semantic prefixes to group related commands, not nested hierarchies.

**Groups**:

- `/aida-*` - AIDA system operations (init, status, validate)
- `/agent-*` - Agent management (create, install, optimize, etc.)
- `/skill-*` - Skill management (create, install, list, etc.)
- `/command-*` - Command management (create, list, etc.)
- `/issue-*` - Issue workflow (create → complete)
- `/pr-*` - Pull request workflow (open, cleanup)
- `/github-*` - GitHub infrastructure (init, sync, status)

**Why flat namespace**:

- Faster to type (`/issue-create` vs `/github issue create`)
- Simpler autocomplete
- Less cognitive load
- Aligns with how Claude Code slash commands work (no space parsing)

### 4. Meta-Agent Naming: "aida"

**Decision**: Rename "claude-agent-manager" to simply **"aida"**

**Purpose**: Manages AIDA itself (agents, skills, commands, configuration)

**Rationale**:

- **Simple**: Just "aida", not "aida-manager" or "aida-architect"
- **Clear scope**: If it's about AIDA itself, invoke "aida"
- **No confusion**: Developers don't think "I need the Claude agent manager", they think "I need to manage AIDA"

### 5. Modes Modify Commands, Not Define Them

**Principle**: Modes are **variations of a workflow**, not different operations.

**Correct** (modes within commands):

```text
/agent-create --global      (mode: where to create)
/agent-optimize --tokens    (mode: what to optimize)
/github-init --labels-only  (mode: how much to initialize)
```

**Incorrect** (parent/child commands):

```text
/agent create               (requires space parsing)
/agent optimize             (not how Claude Code works)
```

**Modes designed per-command** during implementation, not upfront.

### 6. Documentation Auto-Updates

**Decision**: Documentation updates are **part of all operations**, not a separate command.

When you:

- `/agent-create` → Documentation generated
- `/agent-upgrade` → Documentation updated
- `/agent-optimize` → Documentation reflects changes
- `/agent-validate` → Documentation checked

**Why**: Documentation is a byproduct of work, not a separate task.

## 7. Team Reporting and Communication Workflows

### Context: Work Documentation and Executive Communication

**Source**: Requirements extracted from "ETL and Tell" team journaling system

**Problem**: Engineering teams need to document daily work, compile team reports, and communicate technical achievements to executives in accessible language.

**Current pain points**:

- Individual daily work is lost without documentation
- Team accomplishments are hard to surface for leadership
- Technical reports don't translate well for executive consumption
- No systematic way to track time, blockers, and non-code work
- Git commits don't tell the full story (meetings, planning, troubleshooting)

### Core Requirements

#### 1. Daily Work Journaling

**Purpose**: Document daily engineering work with factual accuracy

**Requirements**:

- **Git commit analysis** - Scan multiple repositories for user commits in time range
- **Time tracking** - day_start, day_end, break_time, hours_worked (prevents double-counting)
- **Conversational interviewing** - Ask about meetings, code reviews, non-commit work
- **Multi-source integration** - Git + JIRA/work tracker + direct user input
- **Strict factual accuracy** - NEVER make up statistics, metrics, or claims
- **Structured output** - Obsidian-compatible markdown with frontmatter
- **User configuration** - Git identifiers, default hours, timezone per team member

**Data sources**:

- Git commits (local and remote, all configured repos)
- Work tracker activity (JIRA, Linear, GitHub Issues, etc.)
- Direct user input via conversational interview

**Captured information**:

- Code commits with context (what, why, not just message)
- Meetings attended (what, when, outcomes)
- Code reviews performed
- Non-commit work (planning, documentation, troubleshooting, mentoring)
- Blockers and challenges encountered
- Key accomplishments

**Output structure**:

```markdown
daily/{username}/{YYYY}/{MM}/{YYYY-MM-DD}.md

Frontmatter:
- title, date, author, type: daily
- day_start, day_end, break_time, hours_worked
- timezone, tags

Sections:
- Summary (2-3 sentences)
- Git Activity (by repository)
- Meetings
- Code Reviews
- Other Work
- Accomplishments
- Blockers & Challenges
```

#### 2. Team Reporting

**Purpose**: Compile individual entries into team-wide reports

**Weekly summaries** (personal):

- Compile individual's daily entries for the week
- Identify patterns and themes
- Highlight major accomplishments
- Document challenges overcome

**Monthly summaries** (personal):

- Roll up weekly summaries
- High-level accomplishments and projects
- Growth and learning
- Key themes

**Team reports** (compiled):

- Aggregate all team members' entries
- Executive summary of team activities
- Individual team member sections with attribution
- Team-wide patterns and collective achievements

#### 3. Executive Communication

**Purpose**: Transform technical reports into executive-friendly summaries

**Requirements**:

- **Audience-aware writing** - Different tone for executives vs technical teams
- **Business impact framing** - Focus on "so what" and business value
- **Cultural adaptation** - Match company culture (professional, startup, sports company, etc.)
- **Still factual** - No made-up metrics even in executive summaries
- **Configurable personality** - Light commentary if appropriate for culture
- **Highlight extraction** - Pull key sections for landing pages/wikis

**Tone configuration** (per company culture):

- Professional (traditional corporate)
- Engaging (startup, casual)
- Light commentary (sports companies, creative industries)
- Humor level: minimal → moderate → enthusiastic

**Output examples**:

```markdown
Executive Weekly:
- Opening with engaging hook
- High-level achievements (3-5 major items)
- Team momentum indicators
- Notable individual contributions
- Forward-looking statement

Executive Monthly:
- Month's theme/narrative
- Major accomplishments
- Key themes and focus areas
- Business impact
```

#### 4. Integration and Publishing

**Purpose**: Connect to external systems (work trackers, wikis, etc.)

**Requirements**:

- **MCP-based integrations** - Use Model Context Protocol for tool integration
- **Wiki publishing** - Confluence, Notion, GitBook, etc.
- **Work tracker sync** - JIRA, Linear, GitHub Issues
- **Page hierarchy management** - Maintain organized wiki structures
- **Markdown conversion** - Transform to wiki-native format
- **Automated workflows** - Publish on schedule or trigger

### Generalized Concepts

**Remove company-specific references**:

- ❌ "Splash Sports" → ✅ Configurable company name
- ❌ "sports commentary" → ✅ Configurable cultural tone
- ❌ "Data Engineering Squad" → ✅ Team name from config

**Make integrations pluggable**:

- Git analysis (any git repository)
- Work tracker (JIRA, Linear, GitHub, etc.)
- Wiki system (Confluence, Notion, GitBook, etc.)

**Configuration-driven**:

```yaml
team_reporting:
  company_name: "Your Company"
  team_name: "Engineering Team"
  cultural_tone: "professional"  # professional | engaging | light-commentary
  humor_level: "minimal"         # minimal | moderate | enthusiastic
  max_puns_per_summary: 2
  git_repos:
    - /path/to/repo1
    - /path/to/repo2
  work_tracker:
    type: jira  # jira | linear | github
    project_key: "PROJ"
  wiki:
    type: confluence  # confluence | notion | gitbook
    space_key: "TEAM"
```

### Proposed Command Structure

Using our workflow-oriented naming and noun-verb convention:

**Journal Workflow** (individual work documentation):

```text
/journal-daily          Create daily journal entry with git analysis
/journal-weekly         Compile week's daily entries into summary
/journal-monthly        Compile month's weekly summaries
```

**Team Report Workflow** (team-wide compilation):

```text
/team-report-weekly     Compile all team members' weekly summaries
/team-report-monthly    Compile team's monthly report
```

**Executive Summary Workflow** (leadership communication):

```text
/executive-summary-weekly   Transform team report → executive summary
/executive-summary-monthly  Transform monthly report → executive summary
```

**Publishing Workflow** (external integration):

```text
/wiki-publish-summary   Publish executive summary to wiki
/wiki-update-index      Update landing page with latest highlights
```

**Configuration & Setup**:

```text
/journal-configure      Set up user preferences (git identifiers, hours, timezone)
/team-configure         Set up team reporting config
```

### Skills Structure

Following ADR-009 (Skills System Architecture), create reusable skills:

```text
~/.claude/skills/
├── work-documentation/
│   ├── daily-journaling/
│   │   ├── README.md
│   │   ├── git-analysis.md
│   │   ├── time-tracking.md
│   │   ├── interview-questions.md
│   │   └── frontmatter-templates.md
│   ├── team-reporting/
│   │   ├── README.md
│   │   ├── compilation-patterns.md
│   │   ├── attribution-guidelines.md
│   │   └── aggregation-rules.md
│   └── git-commit-analysis/
│       ├── README.md
│       ├── multi-repo-scanning.md
│       ├── commit-message-parsing.md
│       └── time-range-filtering.md
├── communication/
│   ├── executive-summaries/
│   │   ├── README.md
│   │   ├── business-impact-framing.md
│   │   ├── audience-adaptation.md
│   │   ├── highlight-extraction.md
│   │   └── cultural-tone-matching.md
│   ├── technical-to-business-translation/
│   │   ├── README.md
│   │   ├── framing-technical-work.md
│   │   ├── avoiding-jargon.md
│   │   └── business-value-language.md
│   └── factual-accuracy/
│       ├── README.md
│       ├── no-made-up-statistics.md
│       └── evidence-based-claims.md
└── integrations/
    ├── mcp-atlassian/
    │   ├── README.md
    │   ├── jira-operations.md
    │   └── confluence-publishing.md
    ├── git-analysis/
    │   ├── README.md
    │   ├── repo-scanning.md
    │   └── commit-extraction.md
    └── wiki-publishing/
        ├── README.md
        ├── markdown-conversion.md
        └── page-hierarchy.md
```

### Agent Candidates

**Potential future agents** (to be designed):

1. **team-chronicler** - Daily/weekly work documentation
    - Uses: daily-journaling, git-commit-analysis, time-tracking skills
    - Responsibilities: Conduct interviews, analyze git activity, create structured entries
    - Tone: Factual, professional, conversational

2. **executive-communicator** - Transform technical → business language
    - Uses: executive-summaries, technical-to-business-translation skills
    - Responsibilities: Create executive summaries, frame business impact, match cultural tone
    - Tone: Configurable (professional, engaging, light commentary)

3. **work-tracker-specialist** - Integration with JIRA/Linear/GitHub
    - Uses: mcp-atlassian, work tracker integration skills
    - Responsibilities: Sync work tracker activity, manage tickets, update wikis
    - Tone: Efficient, meticulous

**Note**: These could alternatively be modes/personalities of existing agents (tech-lead, product-manager) rather than separate agents. Design decision deferred.

### Implementation Considerations

**Phase 1: Skills Development** (foundational)

- Create skills in `~/.claude/skills/` structure
- Document patterns and best practices
- Make them available to all agents

**Phase 2: Command Design** (workflow)

- Design `/journal-*` commands
- Design `/team-report-*` commands
- Design `/executive-summary-*` commands
- Follow noun-verb convention

**Phase 3: Agent Decision** (later)

- Decide if dedicated agents needed or if existing agents can handle
- Consider: tech-lead uses team-reporting skills for status updates
- Consider: product-manager uses executive-communication skills for stakeholder updates

**Phase 4: Integration** (final)

- MCP integrations (JIRA, Confluence, etc.)
- Wiki publishing workflows
- Automated publishing pipelines

### Key Principles (from ETL and Tell)

1. **Factual Accuracy is Sacred**
    - NEVER make up statistics, metrics, or performance claims
    - All numbers must come from actual data (git, JIRA, user input)
    - If information is missing, ask the user - don't invent

2. **Time Tracking Prevents Double-Counting**
    - Use day_start/day_end to define work boundaries
    - Track break_time separately
    - hours_worked = (day_end - day_start) - break_time
    - User's stated hours are authoritative, not git commit timestamps

3. **Conversational Interviewing**
    - Ask open-ended questions to gather context
    - Probe for non-commit work (meetings, planning, troubleshooting)
    - Be thorough but respectful of user's time
    - Don't re-ask what user already provided

4. **Attribution Matters**
    - Give credit to individuals for their contributions
    - Maintain attribution through all compilation levels
    - Team reports should celebrate individual achievements

5. **Cultural Adaptation**
    - Executive summaries should match company culture
    - Configuration-driven tone (professional, engaging, light commentary)
    - Humor level configurable (some cultures appreciate it, others don't)

6. **Comprehensive Documentation**
    - Capture both code work AND non-code work
    - Include "why" context, not just "what"
    - Document blockers and challenges, not just wins
    - Provide both summaries AND detailed information

### Benefits

**For Individual Engineers**:

- Daily work is documented for future reference
- Easier performance reviews (comprehensive work log)
- Clearer communication of accomplishments
- Time tracking for billing/planning

**For Engineering Managers**:

- Team visibility without micromanagement
- Easy compilation of team reports for leadership
- Identify patterns, blockers, and bottlenecks
- Recognition and attribution of team contributions

**For Executives**:

- Technical work explained in business terms
- High-level awareness without technical details
- Team momentum and progress visibility
- Engaging summaries that respect their time

### Success Metrics

- Individual engineers create daily entries (adoption)
- Weekly team reports generated consistently
- Executive summaries published on schedule
- Leadership engagement with summaries (readership)
- Reduced time spent on status reports (efficiency)
- Team satisfaction with recognition/attribution

### References

- ETL and Tell: <https://github.com/betterpool/etl-and-tell> (internal)
- Original agents: The Journalist, The Sportscaster, The Atlassian Specialist
- Key insight: "Factual accuracy + cultural adaptation + attribution = valuable team reporting"

**Decision**: Add team reporting and executive communication workflows to AIDA command structure. Implement as skills first, then design commands, defer agent decision.

**Status**: Requirements captured, skills structure designed, command naming proposed. Implementation deferred to future milestone.

## Command Structure

### Issue Workflow Commands (13)

```bash
# Issue Lifecycle
/issue-create       # Create issue draft locally
/issue-publish      # Publish to GitHub/Jira/etc (slug|--milestone|--all)
/issue-start        # Start work (branch, workspace) (issue-id)

# Development & Progress
/issue-analyze      # Analyze requirements (business + technical)
/issue-implement    # Implement the solution
/issue-checkpoint   # Save progress (commit, track time, document)
/issue-pause        # Pause work (stash, return to main) [--checkpoint|--no-checkpoint]
/issue-resume       # Resume work (checkout branch, unstash) (issue-id)

# Automation (start → analyze → implement → review → ship-it)
/issue-autopilot    # 🤖 Automate entire workflow (issue-id)
/issue-yolo         # 😎 Same as autopilot, with personality! (issue-id)

# Completion
/issue-review       # Review work (quality, security, compliance)
/issue-ship-it      # 🚢 Create PR and ship it! (reviewers)
/issue-complete     # Complete and cleanup
```

**Aliases for backward compatibility**:

- `/create-issue` → `/issue-create`
- `/publish-issue` → `/issue-publish`
- `/start-work` → `/issue-start`
- `/expert-analysis` → `/issue-analyze`
- `/implement` → `/issue-implement`
- `/open-pr` → `/issue-ship-it`
- `/cleanup-main` → `/issue-complete`

#### Detailed Command Specifications

**`/issue-checkpoint`** - Save incremental progress

**Purpose**: Document progress, commit work, track time while staying on current branch.

**Use case**: End of day, completed a milestone, want to save work but continue later.

```text
/issue-checkpoint

# Interactive prompts:
→ "What have you accomplished?"
→ "Time spent since last checkpoint? (e.g., 2h, 90m)"

# Actions:
→ Creates commit: "checkpoint: issue #42 - 2025-10-16

   Progress:
   Added validation logic for login flow

   Time: 2h"
→ Logs time: Updates .time-tracking/YYYY-MM.md
→ Updates notes: .github/issues/in-progress/issue-42/NOTES.md
→ Stays on current branch (continue working)

# Confirmation:
✓ Checkpoint saved
  Continue working or /issue-pause to switch contexts
```

**`/issue-pause [--checkpoint|--no-checkpoint]`** - Context switch to different work

**Purpose**: Stash uncommitted changes and return to main for other work.

**Use case**: Urgent bug needs fixing, need to switch to different issue, end of day cleanup.

**Default behavior** (no mode): Ask what to do

```text
/issue-pause

→ ⚠️  You have uncommitted changes:
   M src/auth/login.ts
   M tests/auth.test.ts

   Options:
   [c] Checkpoint first, then pause (commits changes, then stash remaining)
   [s] Stash without committing
   [a] Abort pause

   Choice: _
```

**With modes**:

```text
# Checkpoint first (commits work, then stashes, then returns to main)
/issue-pause --checkpoint
→ Runs /issue-checkpoint
→ Stashes any remaining uncommitted work
→ Checkouts main
→ Updates issue notes: "Paused: 2025-10-16 15:30"

# Just stash (no commit)
/issue-pause --no-checkpoint
→ Stashes uncommitted work
→ Checkouts main
→ Updates issue notes: "Paused: 2025-10-16 15:30"
```

**Confirmation**:

```text
✓ Issue #42 paused
  Stash: issue-42
  Resume with: /issue-resume 42
```

**`/issue-resume <issue-id>`** - Resume paused work

**Purpose**: Return to paused work with full context of where you left off.

**Use case**: Next day after pause, switching back from urgent work.

```text
/issue-resume 42

# Actions:
→ Finds branch for issue-42: milestone-v0.1/feature/42-login-validation
→ Checkouts branch
→ Finds and unstashes work (if stashed)
→ Displays progress summary

# Output:
✓ Resumed issue #42: Implement login validation

📊 Progress Summary:
   Branch: milestone-v0.1/feature/42-login-validation
   Total time: 5.5h
   Estimated remaining: 2.5h

📝 Last checkpoints:
   [2025-10-16 15:45] Added validation logic (2h)
   [2025-10-16 13:30] Set up test structure (1.5h)
   [2025-10-16 10:00] Created branch and workspace (2h)

🔄 Unstashed changes:
   M src/auth/login.ts (3 lines added)
   M tests/auth.test.ts (new file)

💡 Next steps (from last checkpoint):
   - Add edge case tests
   - Update documentation
   - Run security review

Continue working or run /issue-checkpoint when ready to save progress.
```

**`/issue-autopilot <issue-id>`** - Automate full workflow

**Purpose**: Fully automate the development workflow from start to shipped PR.

**Use case**: Simple, well-defined issues; experienced developers with high AI trust; batch processing multiple issues.

**Aliases**: `/issue-yolo` (same command, different personality!)

```text
# Professional version
/issue-autopilot 42

🤖 Autopilot engaged for issue #42

→ Starting work (creating branch, workspace)...
   ✓ Branch: milestone-v0.1/feature/42-login-validation
   ✓ Workspace: .github/issues/in-progress/issue-42/

→ Analyzing requirements...
   ✓ Business requirements documented
   ✓ Technical specifications complete
   ✓ Edge cases identified

→ Implementing solution...
   ✓ Code written: 3 files modified
   ✓ Tests added: 12 new tests
   ✓ Documentation updated

→ Running quality reviews...
   ✓ Code quality: PASS
   ✓ Security scan: PASS
   ✓ Performance check: PASS

→ Creating pull request...
   ✓ Version bumped: 0.1.3 → 0.1.4
   ✓ CHANGELOG updated
   ✓ PR #156 created

✓ Autopilot complete! PR ready for review.
  Review at: https://github.com/org/repo/pull/156

  Run /issue-complete after merge to finish up.

# Fun version (same command!)
/issue-yolo 42

😎 YOLO MODE ACTIVATED

→ Starting work...
→ Analyzing requirements...
→ Implementing solution...
→ Running quality reviews...
→ Creating pull request...

✓ PR #156 created - YOU ONLY LIVE ONCE! 🎉
```

**What it does**:

1. Runs `/issue-start` - Sets up branch and workspace
2. Runs `/issue-analyze` - Deep requirements analysis
3. Runs `/issue-implement` - Writes the code
4. Runs `/issue-review` - Quality, security, compliance checks
5. Runs `/issue-ship-it` - Creates PR with version bump and changelog

**Checkpoints**: Pauses at each step for review if errors detected (can abort anytime)

**When to use**:

- ✅ Simple issues (update docs, fix typos, update dependencies)
- ✅ Well-defined requirements (no ambiguity)
- ✅ Emergency fixes (need it done fast)
- ✅ High trust in AI (experienced with AIDA)
- ❌ Complex features (use manual workflow)
- ❌ Learning new codebase (use manual workflow)
- ❌ High-stakes changes (use manual workflow)

**The choice is yours**: Use `/issue-autopilot` for professional teams, `/issue-yolo` when you're feeling spicy! 🌶️

### AIDA Meta Commands

**Agent Management** (7):

```bash
/agent-create       # Create new agent [--global|--local] [--from-template]
/agent-install      # Install global agent to project (agent-name|--list|--all)
/agent-upgrade      # Upgrade to newer version (agent-name)
/agent-optimize     # Optimize [--tokens|--gaps|--skills|--all] (agent-name)
/agent-validate     # Validate configuration (agent-name|--all)
/agent-analyze      # Analyze gaps/redundancy (agent-name)
/agent-list         # List available agents
```

**Aliases**:

- `/create-agent` → `/agent-create`
- `/install-agent` → `/agent-install`

**Skill Management** (5):

```bash
/skill-create       # Create new skill [--global|--local]
/skill-install      # Install global skill to project (skill-name|--list|--all)
/skill-upgrade      # Upgrade to newer version (skill-name)
/skill-validate     # Validate skill configuration (skill-name|--all)
/skill-list         # List available skills
```

**Command Management** (4):

```bash
/command-create     # Create new command [--global|--local]
/command-install    # Install global command to project (command-name|--list|--all)
/command-validate   # Validate command configuration (command-name|--all)
/command-list       # List available commands [--category]
```

**Aliases**:

- `/create-command` → `/command-create`

**System Management** (4):

```bash
/aida-init [provider]       # Initialize AIDA (github|gitlab|bitbucket|--minimal)
/aida-configure [section]   # Update configuration (vcs|team|integrations)
/aida-status                # Show configuration status
/aida-validate [--fix]      # Validate entire setup
```

**Aliases**:

- `/workflow-init` → `/aida-init`

**VCS Configuration Examples**:

```bash
# Interactive mode (default - asks questions)
/aida-init

# Quick setup with provider
/aida-init github
/aida-init gitlab
/aida-init bitbucket

# Minimal setup (essential config only)
/aida-init --minimal

# Update specific configuration
/aida-configure vcs          # Just update VCS settings
/aida-configure team         # Just update team settings
/aida-configure integrations # Just update integrations
```

**Configuration Storage** (`{PROJECT_ROOT}/.claude/config.yml`):

```yaml
# VCS Configuration
vcs:
  provider: github  # github, gitlab, bitbucket
  base_url: https://github.com
  api_url: https://api.github.com

work_tracker:
  provider: github  # github, jira, linear
  base_url: https://github.com

# Team Configuration
team:
  name: engineering
  default_reviewers:
    - alice
    - bob

# Integrations
integrations:
  datadog:
    enabled: true
  slack:
    enabled: true
    channel: "#eng-notifications"
  pagerduty:
    enabled: false
```

### Repository Management Commands (11)

**Repository Lifecycle** (5):

```bash
/repository-create      # Create new repository (local + remote)
/repository-clone       # Clone existing repository
/repository-fork        # Fork repository for contribution
/repository-archive     # Archive old/inactive repository
/repository-delete      # Delete repository [--confirm]
```

**Repository Configuration** (4):

```bash
/repository-configure   # Configure settings (branch protection, webhooks, secrets)
/repository-access      # Manage collaborators and team access
/repository-sync        # Sync fork with upstream
/repository-template    # Create repository from template
```

**Repository Information** (2):

```bash
/repository-status      # Show repository health/metrics
/repository-list        # List repositories [--org|--user|--all]
```

**Differentiation from GitHub commands**:

- `/github-init` - Sets up GitHub **integration** for project (labels, milestones, workflow)
- `/github-sync` - Syncs **labels/milestones** between repos
- `/repository-*` - Manages the **repository itself** (creation, settings, access)

**Example Use Cases**:

```bash
# Create new microservice
/repository-create
→ Interactive prompts:
  • Repository name: user-service
  • Description: User management microservice
  • Visibility: [private/public]
  • Initialize with: [README/gitignore/license]
  • Template: [none/nodejs/python/react]

→ Actions:
  • Creates local repository
  • Creates GitHub/GitLab repository
  • Sets up branch protection
  • Adds team access (if configured)
  • Runs /github-init to set up labels/milestones

# Manage access for team member
/repository-access
→ Prompts:
  • Action: [add/remove/list]
  • User/Team: @johndoe
  • Permission: [read/write/admin/maintain]

→ Updates VCS access
→ Documents in .github/COLLABORATORS.md (if exists)

# Archive old project
/repository-archive
→ Confirmation:
  ⚠️  Archive repository "old-prototype"?

  This will:
  • Make repository read-only
  • Hide from search results
  • Preserve all history

  [y/N]: _

→ Archives on VCS provider
→ Updates local tracking
```

### SSH Key Management Commands (6)

**SSH Key Lifecycle**:

```bash
/ssh-create-key         # Create new SSH key pair (interactive: type, bits, comment)
/ssh-add-key [service]  # Add SSH key to service (github|snowflake|gitlab|aws)
/ssh-list-keys          # List all SSH keys and their usage
/ssh-rotate-key         # Rotate SSH key (generate new, update services, delete old)
/ssh-audit-keys         # Audit SSH keys (strength, age, usage, security)
/ssh-backup-keys        # Backup SSH keys securely
```

**Key Features**:

- **Interactive workflow**: Guides through each step (no quickstart)
- **Service-specific knowledge**: Uses skills (github-ssh-keys, snowflake-ssh-keys, gitlab-ssh-keys, aws-ssh-keys)
- **Audit capabilities**: Check encryption strength, key age, last used date
- **Rotation automation**: Updates all services using the key
- **Security best practices**: Passphrases, key types (Ed25519 recommended), permissions

**Example Workflows**:

```bash
# Create new SSH key
/ssh-create-key
→ Interactive prompts:
  • Purpose: [GitHub/Snowflake/GitLab/AWS/Custom]
  • Key type: [Ed25519 (recommended)/RSA 4096/ECDSA]
  • Comment: rob@work-laptop
  • Passphrase: [required for security]

→ Actions:
  • Generates key pair: ~/.ssh/id_ed25519_{purpose}
  • Sets correct permissions (600)
  • Adds to ssh-agent
  • Shows public key for copying

# Add key to service
/ssh-add-key github
→ Uses github-ssh-keys skill for service-specific instructions
→ Copies public key to clipboard
→ Opens browser to GitHub SSH keys page (optional)
→ Guides through verification: ssh -T git@github.com
→ Documents key in ~/.ssh/key-inventory.yml

# Audit all keys
/ssh-audit-keys
→ Output:
  📋 SSH Key Audit Report

  ✓ id_ed25519_github (Ed25519, 256-bit)
    Added: 2024-10-15 (1 day ago)
    Used: 2025-10-16 09:30 (today)
    Services: GitHub
    Status: ✓ Secure

  ⚠️  id_rsa_old (RSA, 2048-bit)
    Added: 2023-05-20 (17 months ago)
    Used: 2024-08-10 (2 months ago)
    Services: GitLab
    Status: ⚠️  Weak encryption, should rotate

  Recommendations:
  • Rotate id_rsa_old (weak encryption)
  • Consider rotating keys older than 1 year

# Rotate old key
/ssh-rotate-key id_rsa_old
→ Actions:
  • Generates new key (same purpose, better encryption)
  • Identifies services using old key: GitLab
  • Updates each service with new key
  • Verifies new key works
  • Removes old key from services
  • Archives old key (doesn't delete immediately)
  • Updates key inventory

→ Safety:
  • Keeps backup of old key for 30 days
  • Confirms each service updated successfully
  • Rollback option if issues detected
```

### GitHub/Infrastructure Commands (3)

```bash
/github-init        # Initialize GitHub [--full|--labels-only|--verify|--reset]
/github-sync        # Sync labels/milestones [--check|--fix|--report]
/github-status      # Show GitHub integration status
```

**Note**: Technology-specific naming acceptable for **infrastructure setup**, not workflows.

### Pull Request Commands (2)

```bash
/pr-open            # Create pull request (reviewers)
/pr-cleanup         # Post-merge cleanup
```

**Aliases**:

- `/open-pr` → `/pr-open`
- `/cleanup-main` → `/pr-cleanup`

## Total Commands by Category

### Core Workflow Commands

- **Issue Workflow**: 13 commands (create, publish, start, analyze, implement, checkpoint, pause, resume, review, ship-it, complete, autopilot, yolo)
- **Repository Management**: 11 commands (create, clone, fork, archive, delete, configure, access, sync, template, status, list)
- **SSH Key Management**: 6 commands (create-key, add-key, list-keys, rotate-key, audit-keys, backup-keys)
- **Pull Request**: 2 commands (open, cleanup) - merged into issue workflow conceptually

### AIDA Meta Commands

- **Agent Management**: 7 commands (create, install, upgrade, optimize, validate, analyze, list)
- **Skill Management**: 5 commands (create, install, upgrade, validate, list)
- **Command Management**: 4 commands (create, install, validate, list)
- **System Management**: 4 commands (init, configure, status, validate)

### Infrastructure Commands

- **GitHub Integration**: 3 commands (init, sync, status)

### Domain-Specific Commands (Unchanged)

- **Operations & Debugging**: 3 commands (/debug, /incident, /runbook)
- **Time Tracking**: 1 command (/track-time)
- **Security & Compliance**: 3 commands (/security-audit, /compliance-check, /pii-scan)
- **Code Quality**: 2 commands (/code-review, /script-audit)
- **Documentation**: 1 command (/generate-docs)
- **Testing**: 1 command (/test-plan)
- **Cost Management**: 2 commands (/cost-review, /optimize-warehouse)
- **Data Quality**: 2 commands (/metric-audit, /sla-report)
- **AWS**: 1 command (/aws-review)

**Total**: 70 commands

- **New/Refactored**: 51 commands (issue workflow, repository, SSH, AIDA meta)
- **Domain-specific (unchanged)**: 19 commands
- **Aliases**: 10 (backward compatibility)

## Consequences

### Positive

1. **Trust and adoption**: Granularity is intentional - developers can verify each step, build confidence, and gradually delegate more to AI
2. **Workflow clarity**: Commands reflect developer mental model (what am I doing?)
3. **Visual grouping**: Semantic prefixes group related commands (`/agent-*`, `/issue-*`, `/repository-*`, `/ssh-*`)
4. **Discoverability**: Type `/issue` → autocomplete shows full workflow
5. **Conversation waypoints**: 13-step issue workflow provides natural pause points for iteration and discussion
6. **Progress management**: `/issue-checkpoint`, `/issue-pause`, `/issue-resume` enable flexible work patterns
7. **Dopamine gamification**: Each command completion gives a small win, keeping developers motivated (vs one long command with no feedback)
8. **Full automation option**: `/issue-autopilot` or `/issue-yolo` for when you trust AI completely
9. **Personality choice**: Same command with different vibes (`/issue-autopilot` professional, `/issue-yolo` fun) - teams choose their culture
10. **Fun shipping**: `/issue-ship-it` makes deploying code feel celebratory 🚢
11. **Consistency**: Noun-verb naming across all commands
12. **Technology agnostic**: `/issue-*` works with GitHub, Jira, etc.; `/repository-*` works across VCS providers
13. **Meta-operations**: Can now create, optimize, validate AIDA components
14. **Documentation**: Auto-updated as part of all operations
15. **VCS flexibility**: `/aida-init [provider]` supports GitHub, GitLab, Bitbucket with quick setup modes
16. **Repository management**: Complete lifecycle from creation to archival
17. **SSH key security**: Automated audit, rotation, and security best practices
18. **Multi-provider support**: Configuration system supports any VCS/work tracker combination

### Negative

1. **Breaking changes**: Old command names deprecated (mitigated by aliases)
2. **More commands**: 70 vs 29 (but this is a FEATURE for adoption, not a bug - granularity builds trust)
3. **Learning curve**: Users must learn new names (mitigated by clear patterns, semantic prefixes, and autocomplete)
4. **Configuration complexity**: VCS provider configuration adds setup step (mitigated by auto-detection and quick modes)

### Neutral

1. **Migration timeline**: Support aliases for 6-9 months before removal
2. **Mode design**: Defined per-command during implementation
3. **Agent "aida"**: Replaces unclear "claude-agent-manager" concept

## Implementation Plan

### Phase 1: Foundation & Configuration (Week 1-2)

1. **Create "aida" agent** (replaces "claude-agent-manager")
2. **Add alias support** to command loader (frontmatter `aliases: []` field)
3. **Implement configuration system**:
    - Create `.claude/config.yml` schema
    - Add VCS provider detection from git remote
    - Implement `/aida-init [provider]` with modes (github|gitlab|bitbucket|--minimal)
    - Implement `/aida-configure [section]` for updates
    - Implement `/aida-status` (show current configuration)
4. **Implement discoverability commands**:
    - `/agent-list`, `/skill-list`, `/command-list`

### Phase 2: Issue Workflow Refactoring (Week 3-4)

1. **Rename existing commands** with aliases:
    - `/create-issue` → `/issue-create`
    - `/publish-issue` → `/issue-publish`
    - `/start-work` → `/issue-start`
    - `/expert-analysis` → `/issue-analyze`
    - `/implement` → `/issue-implement`
    - `/open-pr` → `/issue-ship-it`
    - `/cleanup-main` → `/issue-complete`

2. **Create new issue workflow commands**:
    - `/issue-checkpoint` (save progress, track time)
    - `/issue-pause [--checkpoint|--no-checkpoint]` (context switch)
    - `/issue-resume <issue-id>` (resume with context)
    - `/issue-review` (analyst reviews)
    - `/issue-autopilot <issue-id>` (full automation)
    - `/issue-yolo <issue-id>` (alias to autopilot)

### Phase 3: Repository & SSH Management (Week 5-6)

1. **Implement repository commands**:
    - Lifecycle: `/repository-create`, `/repository-clone`, `/repository-fork`, `/repository-archive`, `/repository-delete`
    - Configuration: `/repository-configure`, `/repository-access`, `/repository-sync`, `/repository-template`
    - Information: `/repository-status`, `/repository-list`

2. **Implement SSH key commands**:
    - `/ssh-create-key`, `/ssh-add-key [service]`, `/ssh-list-keys`
    - `/ssh-rotate-key`, `/ssh-audit-keys`, `/ssh-backup-keys`

3. **Create SSH key skills**:
    - `github-ssh-keys`, `snowflake-ssh-keys`, `gitlab-ssh-keys`, `aws-ssh-keys`

### Phase 4: Agent/Skill/Command Management (Week 7-8)

1. **Rename existing commands** with aliases:
    - `/create-agent` → `/agent-create`
    - `/install-agent` → `/agent-install`
    - `/create-command` → `/command-create`

2. **Create new agent commands**:
    - `/agent-upgrade`, `/agent-optimize`, `/agent-validate`, `/agent-analyze`

3. **Create new skill commands**:
    - `/skill-create`, `/skill-install`, `/skill-upgrade`, `/skill-validate`

4. **Create new system commands**:
    - `/aida-validate [--fix]`

### Phase 5: Documentation & Migration (Week 9-10)

1. **Update all documentation** to use new names
2. **Add workflow guides**:
    - 13-step issue workflow (with checkpoint/pause/resume/autopilot)
    - Repository management lifecycle
    - SSH key security best practices
    - VCS provider setup guide
3. **Create migration guide** (old → new command mapping)
4. **Add deprecation warnings** to old command names (future: v0.3+)
5. **Create video tutorials** for key workflows (optional)

## Related ADRs

- **ADR-006**: Analyst/Engineer Agent Pattern (impacts `/issue-review` design)
- **ADR-007**: Product/Platform/API Engineering Model (impacts agent organization)
- **ADR-008**: Engineers Own Testing Philosophy (impacts review workflows)
- **ADR-009**: Skills System Architecture (requires skill management commands)

## References

- [Command Templates README](../../../templates/commands/README.md)
- [System Architect Analysis](../command-structure-analysis-2025-10-16.md) (if created)
- [Skills Catalog](../skills-catalog.md)

## Notes

### Why 13 Steps in Issue Workflow?

Each step is a **conversation waypoint** or **automation option**:

**Manual Workflow (11 steps)**:

1. **Create**: Draft locally, refine before publishing
2. **Publish**: Commit to work tracker
3. **Start**: Set up development environment
4. **Analyze**: Deep requirements analysis (often iterative)
5. **Implement**: Do the work
6. **Checkpoint**: Save progress, track time (can happen multiple times)
7. **Pause**: Context switch to different work (stash changes)
8. **Resume**: Return to paused work with full context
9. **Review**: Quality gates (code, security, compliance)
10. **Ship it**: Create PR with proper metadata 🚢
11. **Complete**: Clean up after merge

**Automation Workflow (2 commands)**:

12. **Autopilot**: Automate steps 3-10 (start → analyze → implement → review → ship-it)
13. **YOLO**: Same as autopilot, with personality! 😎

This supports **both** iterative, conversational development (manual) **and** full automation (when trust is high).

### Progress Management Commands

Added three commands for flexible work patterns:

1. **`/issue-checkpoint`**: Save progress (commit, track time, document) while staying on branch
    - Use case: End of day, milestone completed, want to save work
    - Stays on branch - developer continues working

2. **`/issue-pause [--checkpoint|--no-checkpoint]`**: Context switch to different work
    - Use case: Urgent bug, switching issues, end of day cleanup
    - Stashes work, returns to main
    - Default: Asks whether to checkpoint first
    - Modes: `--checkpoint` (commit then stash), `--no-checkpoint` (just stash)

3. **`/issue-resume <issue-id>`**: Resume paused work with full context
    - Use case: Next day, switching back from urgent work
    - Shows progress summary, checkpoints, next steps
    - Unstashes work automatically

**Rationale**: Developers need flexible work patterns - not just linear "start → finish" flows. Real work involves context switching, incremental progress, and resuming where you left off.

### The Key Architectural Principle

#### "Granularity builds trust"

The 11-step issue workflow (vs a single "do issue X" command) is **intentional product design for AI adoption**:

- Developers won't trust "AI does everything"
- They need **baby steps** where they verify each action
- Each command is an **optional checkpoint** where humans maintain control
- As trust builds, developers skip steps - but granularity remains for those who need it

**This is change management, not just technical workflow.**

### Repository Management vs GitHub Integration

**Critical distinction** between repository management and GitHub integration:

**`/repository-*` commands** (manage the repository itself):

- Create, clone, fork, archive, delete repositories
- Configure repository settings (branch protection, webhooks, secrets)
- Manage access (collaborators, teams, permissions)
- Technology-agnostic where possible (works with GitHub, GitLab, Bitbucket)

**`/github-*` commands** (manage GitHub integration for a project):

- Initialize GitHub labels, milestones, project structure
- Sync labels/milestones across repositories
- Show GitHub integration status
- Technology-specific (GitHub only)

**Example workflow**:

```bash
# Create new repository
/repository-create          # Creates repo on VCS provider

# Set up GitHub integration for project
/github-init               # Sets up labels, milestones, workflow

# Later: manage repository settings
/repository-configure      # Branch protection, webhooks, etc.
```

### SSH Key Management Philosophy

**Security-first design** for SSH key commands:

1. **No shortcuts**: Every command is interactive with security guidance
2. **Service-specific knowledge**: Uses skills (github-ssh-keys, snowflake-ssh-keys, etc.) for provider-specific instructions
3. **Audit-first**: `/ssh-audit-keys` shows security status (key strength, age, usage)
4. **Rotation automation**: `/ssh-rotate-key` safely updates all services using a key
5. **Inventory tracking**: Maintains `~/.ssh/key-inventory.yml` with key metadata

**Why 6 commands**:

- **Create**: Generate key with best practices (Ed25519, passphrase, permissions)
- **Add**: Service-specific setup (different process for GitHub vs Snowflake vs AWS)
- **List**: Quick overview of all keys and usage
- **Rotate**: Safe rotation with service updates and verification
- **Audit**: Security analysis and recommendations
- **Backup**: Secure backup procedures

**Pain point addressed**: Developers often have 5-10 SSH keys with no tracking of:

- Which services use which keys
- When keys were created
- When keys were last used
- Whether keys use secure encryption

### VCS Provider Configuration

**Design principle**: Auto-detect where possible, configure once, work everywhere.

**Auto-detection**:

```bash
# Detects from git remote origin URL
git remote -v
→ github.com → GitHub
→ gitlab.com → GitLab
→ bitbucket.org → Bitbucket
```

**Configuration hierarchy**:

1. **Project-level** (highest priority): `{PROJECT_ROOT}/.claude/config.yml`
2. **User-level** (default): `~/.claude/config.yml`

**Quick setup modes**:

- `/aida-init` - Interactive (full questions)
- `/aida-init github` - Quick setup (auto-detects, minimal prompts)
- `/aida-init --minimal` - Essential config only

**Configuration separation**:

- **VCS provider**: Where code lives (GitHub, GitLab, Bitbucket)
- **Work tracker**: Where issues live (can be same or different: Jira, Linear, etc.)
- **Team settings**: Default reviewers, team name
- **Integrations**: DataDog, Slack, PagerDuty, etc.

### Business Metrics Skill Category

During this discussion, identified missing **business-metrics** skill category (added to catalog):

- SaaS metrics (ARR, MRR, churn, NRR, GRR)
- Product metrics (DAU, MAU, activation, retention)
- Financial metrics (burn rate, runway, CAC, LTV)
- Engagement metrics (session duration, frequency)
- Growth metrics (viral coefficient, k-factor)
- A/B test metrics (statistical significance, sample size)
- Cohort analysis patterns

**Total**: 177 skills across 28 categories

## Complete Command Reference

### Issue Workflow (13 commands)

**Issue Lifecycle**:

- `/issue-create` - Create issue draft locally
- `/issue-publish [slug|--milestone|--all]` - Publish to work tracker
- `/issue-start <issue-id>` - Start work (branch, workspace)

**Development & Progress**:

- `/issue-analyze` - Analyze requirements (business + technical)
- `/issue-implement` - Implement the solution
- `/issue-checkpoint` - Save progress (commit, track time, document)
- `/issue-pause [--checkpoint|--no-checkpoint]` - Context switch (stash, return to main)
- `/issue-resume <issue-id>` - Resume paused work with context

**Quality & Completion**:

- `/issue-review` - Review work (quality, security, compliance)
- `/issue-ship-it [reviewers]` - Create PR and ship! 🚢
- `/issue-complete` - Complete and cleanup after merge

**Automation**:

- `/issue-autopilot <issue-id>` - Automate entire workflow 🤖
- `/issue-yolo <issue-id>` - Same as autopilot, with personality! 😎

**Aliases**: `/create-issue`, `/publish-issue`, `/start-work`, `/expert-analysis`, `/implement`, `/open-pr`, `/cleanup-main`

### Repository Management (11 commands)

**Repository Lifecycle**:

- `/repository-create` - Create new repository (local + remote)
- `/repository-clone` - Clone existing repository
- `/repository-fork` - Fork repository for contribution
- `/repository-archive` - Archive old/inactive repository
- `/repository-delete [--confirm]` - Delete repository

**Repository Configuration**:

- `/repository-configure` - Configure settings (branch protection, webhooks, secrets)
- `/repository-access` - Manage collaborators and team access
- `/repository-sync` - Sync fork with upstream
- `/repository-template` - Create repository from template

**Repository Information**:

- `/repository-status` - Show repository health/metrics
- `/repository-list [--org|--user|--all]` - List repositories

### SSH Key Management (6 commands)

**SSH Key Lifecycle**:

- `/ssh-create-key` - Create new SSH key pair (interactive)
- `/ssh-add-key [service]` - Add SSH key to service (github|snowflake|gitlab|aws)
- `/ssh-list-keys` - List all SSH keys and their usage
- `/ssh-rotate-key` - Rotate SSH key (generate new, update services, delete old)
- `/ssh-audit-keys` - Audit SSH keys (strength, age, usage, security)
- `/ssh-backup-keys` - Backup SSH keys securely

### Agent Management (7 commands)

- `/agent-create [--global|--local] [--from-template]` - Create new agent
- `/agent-install <name|--list|--all>` - Install global agent to project
- `/agent-upgrade <name>` - Upgrade to newer version
- `/agent-optimize [--tokens|--gaps|--skills|--all] <name>` - Optimize agent
- `/agent-validate <name|--all>` - Validate configuration
- `/agent-analyze <name>` - Analyze gaps/redundancy
- `/agent-list` - List available agents

**Aliases**: `/create-agent`, `/install-agent`

### Skill Management (5 commands)

- `/skill-create [--global|--local]` - Create new skill
- `/skill-install <name|--list|--all>` - Install global skill to project
- `/skill-upgrade <name>` - Upgrade to newer version
- `/skill-validate <name|--all>` - Validate skill configuration
- `/skill-list` - List available skills

### Command Management (4 commands)

- `/command-create [--global|--local]` - Create new command
- `/command-install <name|--list|--all>` - Install global command to project
- `/command-validate <name|--all>` - Validate command configuration
- `/command-list [--category]` - List available commands

**Aliases**: `/create-command`

### System Management (4 commands)

- `/aida-init [provider]` - Initialize AIDA (github|gitlab|bitbucket|--minimal)
- `/aida-configure [section]` - Update configuration (vcs|team|integrations)
- `/aida-status` - Show configuration status
- `/aida-validate [--fix]` - Validate entire setup

**Aliases**: `/workflow-init`

### GitHub Integration (3 commands)

- `/github-init [--full|--labels-only|--verify|--reset]` - Initialize GitHub integration
- `/github-sync [--check|--fix|--report]` - Sync labels/milestones
- `/github-status` - Show GitHub integration status

### Pull Request (2 commands)

- `/pr-open [reviewers]` - Create pull request
- `/pr-cleanup` - Post-merge cleanup

**Aliases**: `/open-pr`, `/cleanup-main`

### Operations & Debugging (3 commands)

- `/debug` - Debug production issues with multi-agent orchestration
- `/incident` - Incident management workflow (multi-stage)
- `/runbook <name|list>` - Execute operational runbooks

### Time Tracking (1 command)

- `/track-time` - Track and allocate time across issues

### Security & Compliance (3 commands)

- `/security-audit` - Comprehensive security audit
- `/compliance-check` - Data compliance audit (GDPR, HIPAA, PCI)
- `/pii-scan [domain]` - Scan for PII/sensitive data

### Code Quality (2 commands)

- `/code-review [focus]` - Code review (security|performance|quality|all)
- `/script-audit [check]` - Shell script audit (compatibility|security|style|all)

### Documentation (1 command)

- `/generate-docs [audience]` - Generate documentation (developers|customers|partners)

### Testing (1 command)

- `/test-plan [issue-id]` - Generate comprehensive test plan

### Cost Management (2 commands)

- `/cost-review [dimension]` - Snowflake cost analysis (warehouse|team|domain|user|query-type)
- `/optimize-warehouse` - Analyze warehouse utilization and optimize

### Data Quality (2 commands)

- `/metric-audit` - Audit metric definitions for consistency
- `/sla-report` - Generate SLA compliance reports and error budgets

### AWS (1 command)

- `/aws-review [scope]` - Review AWS infrastructure (all|cdk|cost|security|stack-name)

#### Total: 70 commands

- **Core workflow**: 32 commands (issue, repository, SSH, PR)
- **AIDA meta**: 23 commands (agent, skill, command, system, GitHub)
- **Domain-specific**: 15 commands (operations, security, quality, docs, testing, cost, data, AWS)
- **Time tracking**: 1 command

**Aliases: 10** (backward compatibility for 6-9 months)
