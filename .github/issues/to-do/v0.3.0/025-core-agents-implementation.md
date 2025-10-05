---
title: "Implement core specialized agents"
labels:
  - "type: epic"
  - "priority: p1"
  - "effort: xlarge"
  - "milestone: 0.3.0"
---

# Implement core specialized agents

> **Epic**: This is a large feature that has been broken down into smaller, more manageable issues. See the sub-issues below for implementation details.

## Description

Implement the three core specialized agents (Secretary, File Manager, Dev Assistant) with agent routing to automatically invoke the right agent for the right task. This provides expert assistance across different domains.

## Sub-Issues

This epic is broken down into the following issues:

- #039 - Agent framework and routing system
- #040 - Secretary agent implementation
- #041 - File Manager agent implementation
- #042 - Dev Assistant agent implementation
- #043 - Agent collaboration system

## Acceptance Criteria

- [ ] Secretary Agent fully implemented and functional
- [ ] File Manager Agent fully implemented and functional
- [ ] Dev Assistant Agent fully implemented and functional
- [ ] Agent routing system directs requests to appropriate agent
- [ ] Agent invocation supports direct calling: `@secretary schedule meeting`
- [ ] Agents have access to shared memory and knowledge
- [ ] Agent responses are contextual and specialized
- [ ] Agent performance is acceptable (response time < 3 seconds)
- [ ] Agents can collaborate (one agent calling another)
- [ ] Agent help/documentation for each agent

## Implementation Notes

### Agent Framework Architecture

```text
~/.claude/agents/
├── framework/
│   ├── agent-base.md           # Base agent interface
│   ├── agent-router.md         # Routing logic
│   └── agent-context.md        # Shared context
├── core/
│   ├── secretary/
│   │   ├── CLAUDE.md          # Agent definition
│   │   ├── procedures.md      # Agent procedures
│   │   └── knowledge.md       # Agent-specific knowledge
│   ├── file-manager/
│   │   ├── CLAUDE.md
│   │   ├── procedures.md
│   │   └── knowledge.md
│   └── dev-assistant/
│       ├── CLAUDE.md
│       ├── procedures.md
│       └── knowledge.md
└── routing-rules.yaml
```

### Secretary Agent

**Responsibilities**:

- Scheduling and calendar management
- Task organization and prioritization
- Communication drafting and review
- Meeting preparation and notes
- Daily/weekly planning assistance
- Reminder and follow-up tracking

**Example Capabilities**:

```text
User: "@secretary Schedule a meeting with the team next Tuesday at 2pm"
Secretary: I'll help you schedule that meeting. Let me check your calendar...

Available: Tuesday, Oct 15 at 2:00 PM (1 hour block free)

I can help you:
  1. Create calendar event (if calendar integrated)
  2. Draft meeting invite email
  3. Set reminder to prepare agenda
  4. Add to your tasks list

What would you like me to do?
```

**Agent Definition** (`~/.claude/agents/core/secretary/CLAUDE.md`):

```markdown
# Secretary Agent

**Role**: Personal secretary for scheduling, organization, and communication

**Expertise**:
- Calendar and schedule management
- Task prioritization and organization
- Professional communication
- Meeting facilitation
- Time management strategies

**When to Invoke**:
- User mentions scheduling, calendar, meetings
- User requests help with communication (email, message)
- User asks about tasks, priorities, or planning
- Keywords: "schedule", "meeting", "task", "remind", "plan"

**Capabilities**:
1. Schedule Management
   - Parse calendar requests
   - Suggest meeting times
   - Set reminders
   - Track commitments

2. Task Organization
   - Capture tasks from conversation
   - Prioritize based on urgency/importance
   - Suggest task breakdown
   - Track progress

3. Communication
   - Draft professional emails
   - Review messages for tone
   - Suggest responses
   - Format communication

4. Planning
   - Daily planning (morning routine)
   - Weekly planning (Sunday review)
   - Meeting preparation
   - Follow-up tracking

**Personality Trait**: Organized, proactive, detail-oriented
```text

### File Manager Agent

**Responsibilities**:

- File organization and cleanup
- File search and discovery
- Directory structure recommendations
- File naming conventions
- Batch file operations
- File analysis and categorization

**Example Capabilities**:

```
User: "@file-manager My Downloads folder is a mess. Can you help organize it?"
File Manager: Let me analyze your Downloads folder...

Found 127 files (3.2 GB):
  - 47 PDFs (documents, invoices, manuals)
  - 32 images (screenshots, photos)
  - 18 installers/DMGs
  - 15 ZIP archives
  - 15 miscellaneous

I recommend:
  1. Archive: Move 18 old installers to ~/.Trash
  2. Organize PDFs:
     - Invoices → ~/Documents/Invoices/
     - Manuals → ~/Documents/Manuals/
     - Other → ~/Documents/Downloads-Archive/
  3. Screenshots → ~/Pictures/Screenshots/
  4. Extract ZIPs if needed, then delete

Proceed with this organization? (Y/n)
```text

**Agent Definition**:

```markdown
# File Manager Agent

**Role**: File system organization and management expert

**Expertise**:
- File organization strategies
- Directory structure best practices
- File naming conventions
- Batch operations
- File discovery and search
- Storage optimization

**When to Invoke**:
- User mentions files, folders, directories
- User asks about finding or organizing files
- User needs file operations (move, rename, delete)
- Keywords: "file", "folder", "directory", "organize", "find", "cleanup"

**Capabilities**:
1. File Organization
   - Analyze directory contents
   - Suggest organization strategies
   - Batch move/rename operations
   - Cleanup recommendations

2. File Discovery
   - Search by name, type, date
   - Find duplicates
   - Locate related files
   - Recent file tracking

3. Directory Structure
   - Recommend project structures
   - Create directory templates
   - Maintain conventions
   - Enforce standards

4. File Operations
   - Safe batch operations
   - Backup before moving
   - Undo capability
   - Operation logging

**Personality Trait**: Systematic, thorough, cautious
```

### Dev Assistant Agent

**Responsibilities**:

- Code review and suggestions
- Debugging assistance
- Architecture guidance
- Testing recommendations
- Documentation help
- Git workflow assistance

**Example Capabilities**:

```javascript
User: "@dev-assistant Review this function for potential bugs"
Dev Assistant: I'll review the code...

Potential Issues Found:

1. **Memory Leak Risk** (Line 15)
   - useEffect subscribes but doesn't cleanup
   - Fix: Add return () => subscription.unsubscribe()

2. **Type Safety** (Line 23)
   - Using 'any' type defeats TypeScript benefits
   - Fix: Define proper interface for response

3. **Error Handling** (Line 30)
   - API call doesn't handle errors
   - Fix: Add try/catch or .catch() handler

4. **Performance** (Line 42)
   - Re-creating function on every render
   - Fix: Wrap in useCallback

Shall I show you the corrected code?
```

**Agent Definition**:

```markdown
# Dev Assistant Agent

**Role**: Software development and engineering expert

**Expertise**:
- Code review and quality
- Debugging strategies
- Architecture patterns
- Testing best practices
- Documentation standards
- Git workflow

**When to Invoke**:
- User mentions code, programming, development
- User asks for debugging help
- User requests code review
- Keywords: "code", "bug", "review", "test", "git", "deploy"

**Capabilities**:
1. Code Review
   - Identify bugs and issues
   - Suggest improvements
   - Check best practices
   - Security analysis

2. Debugging
   - Analyze error messages
   - Suggest debugging strategies
   - Root cause analysis
   - Fix recommendations

3. Architecture
   - Design pattern suggestions
   - Code structure advice
   - Scalability considerations
   - Trade-off analysis

4. Testing
   - Test case suggestions
   - Coverage analysis
   - Testing strategy
   - Test code review

5. Git Assistance
   - Commit message suggestions
   - Branch strategy advice
   - Merge conflict help
   - PR review

**Personality Trait**: Analytical, precise, pragmatic
```text

### Agent Routing System

**Routing Rules** (`~/.claude/agents/routing-rules.yaml`):

```yaml
routing_rules:
  # Explicit agent invocation
  explicit:
    patterns:
      - pattern: "@secretary"
        agent: secretary
      - pattern: "@file-manager"
        agent: file-manager
      - pattern: "@dev-assistant"
        agent: dev-assistant

  # Keyword-based routing
  keywords:
    secretary:
      - schedule
      - meeting
      - calendar
      - task
      - remind
      - plan
      - email
      - organize (when referring to time/tasks)

    file-manager:
      - file
      - folder
      - directory
      - organize (when referring to files)
      - cleanup (when referring to files)
      - find (when referring to files)
      - Downloads
      - Desktop

    dev-assistant:
      - code
      - bug
      - debug
      - review (when referring to code)
      - test
      - git
      - commit
      - deploy
      - API
      - function
      - error (when technical)

  # Context-based routing
  context:
    - condition: "in_git_repository"
      hint_agent: dev-assistant
      confidence: 0.7

    - condition: "looking_at_code_file"
      hint_agent: dev-assistant
      confidence: 0.8

    - condition: "many_files_in_directory"
      hint_agent: file-manager
      confidence: 0.6

  # Default routing
  default:
    agent: null  # No specific agent, use general AIDA
    confidence: 0.5
```

**Routing Logic**:

```python
def route_request(user_input, context):
    # 1. Check for explicit agent invocation
    if user_input.startswith("@"):
        agent = extract_agent_from_mention(user_input)
        return (agent, 1.0)  # confidence: 100%

    # 2. Check keyword matches
    keyword_scores = calculate_keyword_scores(user_input)
    if max(keyword_scores.values()) > 0.7:
        return (top_agent, max_score)

    # 3. Check context hints
    context_hints = check_context_conditions(context)
    if max(context_hints.values()) > 0.6:
        return (top_agent, max_score)

    # 4. Use default (general AIDA)
    return (None, 0.5)
```text

### Agent Collaboration

Agents can invoke other agents:

```
User: "Help me start my day"

Secretary: Let me help you plan your day.

First, let me check for any file organization needed.
[@file-manager: Any cleanup needed on Desktop or Downloads?]

File Manager: Desktop has 12 files, Downloads has 23 files.
              Recommend 15-minute cleanup before starting work.

Secretary: I recommend:
  1. [9:00-9:15] Quick cleanup (File Manager can help)
  2. [9:15-9:30] Review today's tasks
  3. [9:30-10:00] Priority task #1: Fix production bug

  [@dev-assistant: Any urgent dev tasks?]

Dev Assistant: Production bug in payment processing (reported 2h ago)
               This should be top priority.

Secretary: Updated plan:
  1. [9:00-9:15] Quick cleanup
  2. [9:15-10:30] **URGENT: Fix payment processing bug**
  3. [10:30-11:00] Code review for PR #123

Shall I set reminders for these?
```text

## Dependencies

- #009 (Agent templates provide foundation)
- #022 (Enhanced memory for agent context)
- #011 (Core procedures for agent behaviors)

## Related Issues

- #023 (Knowledge capture agents can use)
- #024 (Decision documentation agents can use)
- #018 (Project agents build on this framework)

## Definition of Done

- [ ] All three core agents implemented
- [ ] Agent routing correctly identifies which agent to use
- [ ] Explicit agent invocation works (@agent-name)
- [ ] Agents have access to shared memory
- [ ] Agent responses are high quality and specialized
- [ ] Agents can collaborate when needed
- [ ] Agent performance is acceptable
- [ ] Documentation for each agent
- [ ] Examples demonstrate agent capabilities
- [ ] Unit tests for routing logic
