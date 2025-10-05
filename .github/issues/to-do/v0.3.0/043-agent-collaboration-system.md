---
title: "Implement agent collaboration system"
labels:
  - "type: feature"
  - "priority: p2"
  - "effort: small"
  - "milestone: 0.3.0"
---

# Implement agent collaboration system

## Description

Implement the agent collaboration system that allows agents to invoke other agents and coordinate complex workflows. This enables multi-agent workflows where agents work together to solve comprehensive tasks.

## Acceptance Criteria

- [ ] Agents can invoke other agents
- [ ] Agent-to-agent communication works
- [ ] Collaboration context preserved across agents
- [ ] Circular invocation prevented
- [ ] Collaboration history tracked
- [ ] User remains aware of agent switching
- [ ] Performance acceptable for multi-agent workflows
- [ ] Error handling for failed agent invocations
- [ ] Documentation explains collaboration patterns
- [ ] Examples demonstrate multi-agent workflows

## Implementation Notes

### Agent Invocation API

Add to agent context (`~/.claude/agents/framework/agent-context.md`):

```python
def invoke_agent(agent_name, request, context=None):
    """
    Invoke another agent from current agent.

    Args:
        agent_name: Name of agent to invoke
        request: Request to send to agent
        context: Optional context to pass

    Returns:
        Agent response

    Raises:
        AgentNotFoundError: If agent doesn't exist
        CircularInvocationError: If invocation would create loop
    """
    # Check if agent exists
    if agent_name not in registered_agents:
        raise AgentNotFoundError(f"Agent '{agent_name}' not found")

    # Prevent circular invocations
    if agent_name in context.get('invocation_chain', []):
        raise CircularInvocationError(
            f"Circular invocation detected: {context['invocation_chain']}"
        )

    # Build invocation context
    invocation_context = {
        'invocation_chain': context.get('invocation_chain', []) + [current_agent],
        'original_request': context.get('original_request', request),
        'shared_memory': context.get('shared_memory', {}),
        'user_id': context.get('user_id'),
    }

    # Invoke agent
    response = execute_agent(agent_name, request, invocation_context)

    # Log collaboration
    log_collaboration(current_agent, agent_name, request, response)

    return response
```text

### Collaboration Patterns

#### Pattern 1: Sequential Collaboration

Secretary asks File Manager for cleanup, then continues planning:

```

User: "Help me start my day"

Secretary: Let me help you plan your day.

First, let's check if any cleanup is needed.
[@file-manager: Check Downloads and Desktop status]

File Manager: Downloads has 23 files, Desktop has 12 items.
              Recommend 15-minute cleanup before starting work.

Secretary: I recommend:

  1. [9:00-9:15] Quick cleanup (File Manager can help)
  2. [9:15-9:30] Review today's tasks
  3. [9:30-10:00] Priority task #1: Fix production bug

Shall we start with the cleanup?

```text

#### Pattern 2: Parallel Information Gathering

Secretary asks both File Manager and Dev Assistant for status:

```

User: "What's my status?"

Secretary: Gathering status information...

[@file-manager: System health check]
[@dev-assistant: Active project status]

File Manager: System healthy. Downloads: 5 files, Desktop: 2 items.

Dev Assistant: Project Alpha 85% complete. 3 commits ahead of main.
               Ready for PR review.

Secretary:
**Overall Status**:

- System: ✓ Healthy (minimal cleanup needed)
- Active Work: Project Alpha at 85%
- Next Actions: Create PR for Project Alpha

Detailed breakdown:
[... combines info from both agents ...]

```text

#### Pattern 3: Expert Handoff

Secretary recognizes technical question and hands off to Dev Assistant:

```

User: "I'm getting a TypeError in my React component"

Secretary: This appears to be a technical issue.
           [@dev-assistant: User has TypeError in React component]

Dev Assistant: I'll help you debug that.

Can you share the error message and relevant code?

[... Dev Assistant continues with debugging ...]

```text

#### Pattern 4: Coordinated Workflow

Multi-agent deployment workflow:

```

User: "@secretary prepare for deployment"

Secretary: Preparing deployment workflow...

First, let me check the code is ready.
[@dev-assistant: Verify code ready for deployment]

Dev Assistant: Checking deployment readiness...

- Tests: ✓ Passing
- Build: ✓ Success
- Coverage: ✓ 85%
! Documentation needs update

Secretary: Before deployment:
  [@dev-assistant: What docs need updating?]

Dev Assistant: API documentation needs:

- New endpoints documented
- Auth flow updated
- Rate limits noted

Secretary: Deployment Plan:

  1. [10 min] Update API documentation
     [@dev-assistant will guide]
  2. [5 min] System cleanup
     [@file-manager will ensure clean state]
  3. [15 min] Deploy to staging
     [@dev-assistant will execute]
  4. [10 min] Run smoke tests
  5. [15 min] Deploy to production

Total time: ~55 minutes

Ready to begin? (Y/n)

```text

### Collaboration Visualization

Show user when agents collaborate:

```

User: "Help me start my day"

Secretary → File Manager
  ↓ "Check Downloads and Desktop"
  ↳ "23 files in Downloads, 12 items on Desktop"

Secretary → Dev Assistant
  ↓ "Any urgent dev tasks?"
  ↳ "Production bug in payment processing"

Secretary (coordinating):
✓ File cleanup needed (15 min)
✓ Urgent bug found (priority)

Recommended Plan:

  1. Fix production bug (urgent)
  2. Quick file cleanup
  3. Regular daily tasks

```text

### Preventing Circular Invocations

Track invocation chain and prevent loops:

```python
# Example invocation chain
invocation_chain = [
    'secretary',      # User invoked secretary
    'file-manager',   # Secretary invoked file-manager
    'dev-assistant',  # File-manager invoked dev-assistant
]

# Prevent dev-assistant from invoking secretary (would create loop)
if 'secretary' in invocation_chain:
    raise CircularInvocationError(
        "Cannot invoke 'secretary' - would create circular invocation"
    )
```

### Collaboration History

Track agent collaborations in memory:

```markdown
## Agent Collaboration History

### 2025-10-04 09:00 - Morning Planning
**Initiated by**: User
**Primary Agent**: Secretary
**Collaborating Agents**: File Manager, Dev Assistant

**Flow**:
1. User → Secretary: "Help me start my day"
2. Secretary → File Manager: "Check system status"
3. Secretary → Dev Assistant: "Any urgent tasks?"
4. Secretary → User: Coordinated plan

**Outcome**: Daily plan created with file cleanup and bug fix prioritized

---

### 2025-10-04 14:30 - Deployment Preparation
**Initiated by**: User
**Primary Agent**: Secretary
**Collaborating Agents**: Dev Assistant

**Flow**:
1. User → Secretary: "Prepare for deployment"
2. Secretary → Dev Assistant: "Verify deployment readiness"
3. Dev Assistant → User: Documentation update needed
4. Secretary → User: Deployment plan with steps

**Outcome**: Deployment plan created, documentation identified as blocker
```text

### Error Handling

Handle agent invocation failures gracefully:

```

Secretary: Let me check with the Dev Assistant...
[@dev-assistant: Project status]

[Dev Assistant temporarily unavailable]

Secretary: I'm having trouble reaching the Dev Assistant.
           Let me provide status from my records instead.

**Project Alpha** (last updated 2 hours ago):

- Status: 80% complete
- Last commit: feat(auth): add token refresh
- Next actions: Testing and documentation

Would you like me to try the Dev Assistant again, or proceed with this information?

```text

## Dependencies

- #039 (Agent framework and routing)
- #040 (Secretary agent)
- #041 (File Manager agent)
- #042 (Dev Assistant agent)

## Related Issues

- Part of #025 (Core agents implementation epic)
- Completes the agent system implementation

## Definition of Done

- [ ] Agent invocation API implemented
- [ ] Collaboration patterns work correctly
- [ ] Circular invocation prevented
- [ ] Collaboration visualization clear
- [ ] Collaboration history tracked
- [ ] Error handling comprehensive
- [ ] Performance acceptable
- [ ] Documentation complete
- [ ] Examples demonstrate patterns
- [ ] Multi-agent workflows tested
