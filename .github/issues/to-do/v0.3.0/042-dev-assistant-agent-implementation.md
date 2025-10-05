---
title: "Implement Dev Assistant agent"
labels:
  - "type: feature"
  - "priority: p1"
  - "effort: medium"
  - "milestone: 0.3.0"
---

# Implement Dev Assistant agent

## Description

Implement the Dev Assistant agent responsible for development workflow support, code review, git operations, debugging assistance, and deployment guidance. This agent specializes in software engineering tasks.

## Acceptance Criteria

- [ ] Dev Assistant agent fully functional
- [ ] Code review assistance works
- [ ] Git workflow support functional
- [ ] Debugging assistance helpful
- [ ] Project status tracking accurate
- [ ] Deployment support comprehensive
- [ ] Testing reminders work
- [ ] Agent integrates with memory system
- [ ] Agent applies personality appropriately
- [ ] Agent performance acceptable (<3 seconds)

## Implementation Notes

### Agent Definition

Location: `~/.claude/agents/core/dev-assistant/CLAUDE.md`

```markdown
---
title: "Dev Assistant Agent"
description: "Development workflow support"
category: "agent"
version: "0.3.0"
---

# Dev Assistant Agent

## Role

I am your development assistant, specializing in coding workflows, git operations, project management, and deployment procedures. I help you build software efficiently.

## Responsibilities

- Git workflow guidance
- Code review support
- Debugging assistance
- Architecture guidance
- Testing reminders
- Documentation help
- Development environment management
- Deployment procedures

## When to Invoke

**Explicit**: @dev-assistant
**Keywords**: code, bug, debug, review (code), test, git, commit, deploy, API, function, error (technical)
**Context**: In git repository, viewing code files

## Capabilities

### 1. Git Operations
- Commit message formatting
- Branch naming suggestions
- PR description templates
- Merge conflict guidance
- Rebase support

### 2. Code Review
- Identify bugs and issues
- Suggest improvements
- Check best practices
- Security analysis

### 3. Debugging
- Analyze error messages
- Suggest debugging strategies
- Root cause analysis
- Fix recommendations

### 4. Testing
- Test case suggestions
- Coverage analysis
- Testing strategy
- Test code review

### 5. Deployment
- Deployment checklists
- Environment verification
- Rollback procedures
```text

### Git Operations Implementation

**Commit Message Formatting**:

```

User: "Ready to commit"

Dev Assistant: I'll help you craft a proper commit message.

**Staged Changes**:

- Modified: src/components/Auth.tsx
- Modified: src/utils/api.ts
- Added: tests/auth.test.ts

**Analysis**:

- Added token refresh logic to Auth component
- Updated API utility with refresh endpoint
- Included comprehensive tests

**Suggested Commit Message** (Conventional Commits):

```text

feat(auth): add automatic token refresh

- Implement token refresh logic in Auth component
- Add refresh endpoint to API utilities
- Include tests for token lifecycle and edge cases
- Handle token expiration gracefully

Fixes #123

```

Looks good? (Y/n/e to edit)

```text

**Branch Naming**:

```

User: "I need to create a branch for the auth feature"

Dev Assistant: Analyzing context...

**Current Branch**: main
**Task**: Auth feature development

**Suggested Branch Names**:

1. feature/auth-token-refresh (recommended)
   - Follows convention: feature/description
   - Clear and descriptive

2. feat/token-refresh
   - Shorter alternative
   - Still clear

3. oakensoul/auth-refresh
   - Personal branch style
   - Includes your username

Preference? (1/2/3/custom)

```text

### Code Review Implementation

**Review Trigger**: User shares code or asks for review

```

User: "@dev-assistant review this function"
[code provided]

Dev Assistant: Reviewing code...

**Potential Issues Found**:

1. 🔴 **Memory Leak Risk** (Line 15)
   Issue: useEffect subscribes but doesn't cleanup
   Impact: Memory leak on component unmount
   Fix:

   ```typescript
   useEffect(() => {
     const subscription = subscribe();
     return () => subscription.unsubscribe(); // Add this
   }, []);
   ```json

2. 🟡 **Type Safety** (Line 23)
   Issue: Using 'any' type defeats TypeScript benefits
   Impact: Runtime errors not caught at compile time
   Fix:

   ```typescript
   interface ApiResponse {
     data: UserData;
     status: number;
   }
   const response: ApiResponse = await api.call();
   ```

3. 🟡 **Error Handling** (Line 30)
   Issue: API call doesn't handle errors
   Impact: Unhandled promise rejections
   Fix:

   ```typescript
   try {
     const data = await api.call();
   } catch (error) {
     console.error('API call failed:', error);
     // Handle error appropriately
   }
   ```javascript

4. 🟢 **Performance** (Line 42)
   Issue: Re-creating function on every render
   Impact: Minor performance overhead
   Fix:

   ```typescript
   const handleClick = useCallback(() => {
     // handler logic
   }, [dependencies]);
   ```

**Summary**:

- Critical: 1 (memory leak)
- Warning: 2 (type safety, error handling)
- Info: 1 (performance)

Shall I show you the corrected version?

```text

### Debugging Assistance

**Error Analysis**:
```

User: "Getting error: Cannot read property 'map' of undefined"

Dev Assistant: Analyzing error...

**Error**: Cannot read property 'map' of undefined

**Common Causes**:

1. Array/data not loaded yet (async issue)
2. API response doesn't match expected structure
3. State not initialized properly

**Debugging Steps**:

1. Check if data is loaded before mapping:

   ```typescript
   {data && data.map(item => ...)}
   // or
   {data?.map(item => ...)}  // optional chaining
   ```javascript

2. Add loading state:

   ```typescript
   if (!data) return <Loading />;
   if (data.length === 0) return <Empty />;
   return data.map(item => ...);
   ```

3. Verify API response structure:

   ```typescript
   console.log('API response:', data);
   // Check if data is array or nested: data.items
   ```javascript

4. Initialize state properly:

   ```typescript
   const [data, setData] = useState([]); // Not undefined
   ```

**Most Likely**: Async timing issue. Data not loaded before render.

**Quick Fix**:

```typescript
{data?.map(item => <Item key={item.id} {...item} />) ?? <Loading />}
```text

Would you like me to review the full component?

```

### Project Status Implementation

**Trigger**: `aida project-status [name]` or `@dev-assistant project status`

**Procedure**:

1. Read project from `~/.claude/knowledge/projects.md`
2. Check git status if in repo
3. Review recent commits
4. Check for blockers
5. Suggest next actions

**Example Output**:

```text

Project Alpha Status
====================

**Repository**: ~/Development/project-alpha
**Branch**: feature/auth-refresh
**Last Commit**: 2 hours ago

**Git Status**:
✓ Working directory clean
✓ Branch up to date with origin
→ 3 commits ahead of main

**Recent Commits**:

1. feat(auth): add token refresh (2h ago)
2. test(auth): add token tests (3h ago)
3. refactor(api): improve error handling (4h ago)

**Progress**:

- Auth feature: 85% complete
- Testing: 90% coverage
- Documentation: Pending

**Blockers**: None

**Next Actions**:

1. Update documentation for token refresh
2. Create PR to main
3. Request code review

Ready to create PR? (Y/n)

```

### Testing Reminders

**Before Commit**:

```text

Dev Assistant: Hold on, sir. Before we commit...

**Test Check**:

- Modified files: 3
- Test files modified: 1
- Coverage impact: Unknown

**Recommendations**:

1. Run tests: `npm test`
2. Check coverage: `npm run coverage`
3. Add tests for edge cases if needed

Have you run the tests? (Y/n)

[If no]
I recommend running tests first. Shall I run them for you?

```

**Before Deployment**:

```text

Dev Assistant: Deployment checklist, sir.

**Pre-Deployment Checks**:
✓ Tests passing
✓ Branch up to date
✓ Build succeeds
! Documentation pending
! No staging deployment yet

**Recommendations**:

1. Update API documentation
2. Deploy to staging first
3. Run integration tests
4. Then deploy to production

Would you like me to guide you through staging deployment?

```

### Deployment Support

**Deployment Checklist**:

```text

User: "@dev-assistant help me deploy to production"

Dev Assistant: Production deployment procedure for Project Alpha.

**Pre-Deployment Checklist**:

- [ ] All tests passing (run: npm test)
- [ ] Build succeeds (run: npm run build)
- [ ] Branch merged to main
- [ ] Version bumped in package.json
- [ ] CHANGELOG updated
- [ ] Staging deployment successful
- [ ] Database migrations ready (if any)
- [ ] Environment variables verified

**Deployment Steps**:

1. Pull latest main: `git checkout main && git pull`
2. Tag release: `git tag v1.2.0`
3. Push tag: `git push origin v1.2.0`
4. Trigger deployment: [deployment command]
5. Monitor logs for errors
6. Run smoke tests
7. Verify critical paths

**Rollback Plan**:
If issues occur:

1. Tag previous version: `git tag v1.1.0`
2. Redeploy: [rollback command]
3. Investigate issues in staging

Proceed with pre-deployment checks? (Y/n)

```

### Personality Integration

Apply active personality (example: JARVIS):

```text

JARVIS tone for development:

- Witty about code quality: "I see we're being generous with 'any' types today"
- Snarky about test coverage: "Tests? Oh, you mean those optional suggestions?"
- Encouraging during debugging: "Ah, the classic undefined map. We've seen this before."
- Satisfaction with clean code: "Now that's more like it. Proper error handling."
- Precision: "Let's proceed with surgical precision, shall we?"

```

## Dependencies

- #039 (Agent framework and routing)
- #009 (Agent templates)
- #031 (Memory system for context)

## Related Issues

- Part of #025 (Core agents implementation epic)
- #040 (Secretary agent)
- #041 (File Manager agent)
- #043 (Agent collaboration)

## Definition of Done

- [ ] Dev Assistant agent fully implemented
- [ ] Git operations functional
- [ ] Code review assistance works
- [ ] Debugging support helpful
- [ ] Project status tracking works
- [ ] Testing reminders functional
- [ ] Deployment support comprehensive
- [ ] Memory integration complete
- [ ] Personality integration works
- [ ] Documentation complete
- [ ] Examples demonstrate capabilities
