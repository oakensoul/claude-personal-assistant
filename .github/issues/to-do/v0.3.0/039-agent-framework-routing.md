---
title: "Implement agent framework and routing system"
labels:
  - "type: feature"
  - "priority: p1"
  - "effort: medium"
  - "milestone: 0.3.0"
---

# Implement agent framework and routing system

## Description

Create the foundational agent framework and intelligent routing system that automatically directs requests to the appropriate specialized agent based on explicit mentions, keywords, and context.

## Acceptance Criteria

- [ ] Agent base framework defined and documented
- [ ] Agent routing system implemented
- [ ] Explicit agent invocation works (@agent-name)
- [ ] Keyword-based routing functional
- [ ] Context-based routing functional
- [ ] Routing confidence scoring implemented
- [ ] Agent can access shared memory and knowledge
- [ ] Agent context propagation works
- [ ] Routing rules configurable via YAML
- [ ] Routing performance acceptable (<100ms)
- [ ] Agent registry system implemented

## Implementation Notes

### Agent Framework Architecture

```
~/.claude/agents/
├── framework/
│   ├── agent-base.md           # Base agent interface
│   ├── agent-router.md         # Routing logic
│   ├── agent-context.md        # Shared context
│   └── agent-registry.md       # Agent discovery
├── core/
│   ├── secretary/
│   ├── file-manager/
│   └── dev-assistant/
└── routing-rules.yaml
```

### Agent Base Interface

Define standard agent structure in `~/.claude/agents/framework/agent-base.md`:

```markdown
# Agent Base Interface

All agents must implement:

## Required Sections

### Role
Clear description of agent's purpose and expertise

### Responsibilities
Specific tasks this agent handles

### When to Invoke
Patterns and keywords that trigger this agent

### Capabilities
Detailed list of what this agent can do

### Knowledge Sources
Which files/systems this agent accesses

### Personality Integration
How agent applies active personality

## Shared Access

All agents have access to:
- `~/.claude/memory/` - All memory categories
- `~/.claude/knowledge/` - Knowledge base
- `~/.claude/config/` - Configuration
- Active personality settings
- Current context
```

### Routing Rules (YAML)

`~/.claude/agents/routing-rules.yaml`:
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
      - organize  # when referring to time/tasks

    file-manager:
      - file
      - folder
      - directory
      - organize  # when referring to files
      - cleanup   # when referring to files
      - find      # when referring to files
      - Downloads
      - Desktop

    dev-assistant:
      - code
      - bug
      - debug
      - review    # when referring to code
      - test
      - git
      - commit
      - deploy
      - API
      - function
      - error     # when technical

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

  # Confidence thresholds
  thresholds:
    explicit: 1.0        # Always use explicitly mentioned agent
    keyword: 0.7         # High keyword match confidence
    context: 0.6         # Context hint confidence
    default: 0.5         # No specific agent

  # Default routing
  default:
    agent: null          # No specific agent, use general AIDA
    confidence: 0.5
```

### Routing Logic

Implement routing algorithm:

```python
def route_request(user_input, context):
    """
    Route user request to appropriate agent.

    Priority:
    1. Explicit agent mention (@agent-name)
    2. Keyword matching
    3. Context hints
    4. Default (no agent)

    Returns: (agent_name, confidence_score)
    """

    # 1. Check for explicit agent invocation
    if user_input.startswith("@"):
        agent = extract_agent_from_mention(user_input)
        if agent in registered_agents:
            return (agent, 1.0)  # confidence: 100%

    # 2. Check keyword matches
    keyword_scores = {}
    for agent, keywords in routing_rules['keywords'].items():
        score = 0
        for keyword in keywords:
            if keyword.lower() in user_input.lower():
                score += 1
        if score > 0:
            # Normalize by number of words
            keyword_scores[agent] = score / len(user_input.split())

    if keyword_scores:
        top_agent = max(keyword_scores, key=keyword_scores.get)
        top_score = keyword_scores[top_agent]
        if top_score >= routing_rules['thresholds']['keyword']:
            return (top_agent, top_score)

    # 3. Check context hints
    context_hints = {}
    for rule in routing_rules['context']:
        if check_context_condition(rule['condition'], context):
            agent = rule['hint_agent']
            confidence = rule['confidence']
            context_hints[agent] = confidence

    if context_hints:
        top_agent = max(context_hints, key=context_hints.get)
        top_score = context_hints[top_agent]
        if top_score >= routing_rules['thresholds']['context']:
            return (top_agent, top_score)

    # 4. Use default (general AIDA)
    return (None, 0.5)
```

### Agent Context

Shared context available to all agents (`~/.claude/agents/framework/agent-context.md`):

```markdown
# Agent Context

Shared context accessible to all agents:

## Current State
- Active user
- Current working directory
- Current project (if in project directory)
- Active personality
- Conversation history (recent)

## Memory Access
- `~/.claude/memory/tasks/` - Task tracking
- `~/.claude/memory/knowledge/` - Learnings
- `~/.claude/memory/decisions/` - ADRs/PDRs
- `~/.claude/memory/context/` - Current context
- `~/.claude/memory/preferences/` - User preferences

## Knowledge Access
- `~/.claude/knowledge/` - Knowledge base
- Project-specific `CLAUDE.md` (if available)

## Configuration Access
- `~/.claude/config/config.yaml` - System config
- `~/.claude/config/personality.yaml` - Active personality

## Methods

### read_memory(category, filename)
Read from memory system

### write_memory(category, filename, content)
Write to memory system

### search_memory(query, filters)
Search across memory

### get_current_context()
Get current state and context

### get_user_preferences(category)
Get user preferences

### invoke_agent(agent_name, request)
Invoke another agent (for collaboration)
```

### Agent Registry

Track available agents (`~/.claude/agents/framework/agent-registry.md`):

```yaml
agents:
  secretary:
    name: "Secretary"
    description: "Daily workflow and planning management"
    status: "active"
    version: "0.3.0"
    location: "~/.claude/agents/core/secretary/"

  file-manager:
    name: "File Manager"
    description: "File organization and system maintenance"
    status: "active"
    version: "0.3.0"
    location: "~/.claude/agents/core/file-manager/"

  dev-assistant:
    name: "Dev Assistant"
    description: "Development workflow support"
    status: "active"
    version: "0.3.0"
    location: "~/.claude/agents/core/dev-assistant/"
```

### Routing Visualization

```bash
$ aida agents route "help me organize my Downloads folder"

Routing Analysis:
==================

Input: "help me organize my Downloads folder"

Explicit mention: None
Keyword matches:
  - file-manager: organize, folder, Downloads (score: 0.75)
  - secretary: organize (score: 0.25)

Context hints:
  - None

Selected Agent: file-manager
Confidence: 0.75 (keyword match)

[Execute with file-manager? (Y/n)]
```

## Dependencies

- #009 (Agent templates provide foundation)
- #031 (Memory system for shared context)

## Related Issues

- Part of #025 (Core agents implementation epic)
- #040, #041, #042 (Individual agent implementations)
- #043 (Agent collaboration builds on this)

## Definition of Done

- [ ] Agent base interface documented
- [ ] Routing system implemented and tested
- [ ] Explicit invocation works
- [ ] Keyword routing works
- [ ] Context routing works
- [ ] Routing rules configurable
- [ ] Agent context propagation works
- [ ] Agent registry functional
- [ ] Performance meets requirements
- [ ] Documentation complete
- [ ] Examples demonstrate routing
