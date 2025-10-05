---
title: "Implement project-specific agents system"
labels:
  - "type: feature"
  - "priority: p2"
  - "effort: xlarge"
  - "milestone: 0.5.0"
  - "epic: needs-breakdown"
---

# Implement project-specific agents system

> **⚠️ Epic Breakdown Required**: This is an XLarge effort issue that should be broken down into smaller, more atomic issues before milestone work begins. This breakdown should happen during sprint planning for v0.5.0.

## Description

Create the project-specific agent system that allows users to install technology-stack-specific guidance into their project directories. Agents provide best practices, patterns, and workflows for React, Next.js, Go, Python, etc.

## Suggested Breakdown

When breaking down this epic, consider creating separate issues for:

1. **Project Agent Framework** - Base system for project-specific agents
2. **Agent Installation System** - CLI commands to install agents into projects
3. **Agent Template System** - Template structure for creating new agents
4. **React Agent** - React/TypeScript best practices and patterns
5. **Next.js Agent** - Next.js-specific guidance and workflows
6. **Go Agent** - Go best practices and idioms
7. **Python Agent** - Python best practices and patterns
8. **Agent Discovery & Listing** - Browse and discover available agents
9. **Custom Agent Creation** - Documentation and tooling for custom agents
10. **Agent Merging & Updates** - Handle updates to project CLAUDE.md files

Each sub-issue should be scoped to Small or Medium effort.

## Acceptance Criteria

- [ ] Directory `project-agents/` created with structure
- [ ] Agent template system defined
- [ ] React agent created (`project-agents/react/CLAUDE.md`)
- [ ] Next.js agent created (`project-agents/nextjs/CLAUDE.md`)
- [ ] Go agent created (`project-agents/golang/CLAUDE.md`)
- [ ] Python agent created (`project-agents/python/CLAUDE.md`)
- [ ] CLI command `${ASSISTANT_NAME} agent install [type]` implemented
- [ ] CLI command `${ASSISTANT_NAME} agent list` shows available agents
- [ ] Agent installation merges with existing project CLAUDE.md
- [ ] Documentation explains how to create custom agents
- [ ] Documentation explains how to use project agents

## Implementation Notes

### Project Agent Structure

```
project-agents/
├── README.md                    # Overview and guide
├── _template/                   # Template for creating new agents
│   └── CLAUDE.md
├── react/
│   └── CLAUDE.md
├── nextjs/
│   └── CLAUDE.md
├── golang/
│   └── CLAUDE.md
├── python/
│   └── CLAUDE.md
├── nodejs/
│   └── CLAUDE.md
├── typescript/
│   └── CLAUDE.md
└── docker/
    └── CLAUDE.md
```

### Agent Template (_template/CLAUDE.md)

```markdown
---
title: "[Technology] Project Agent"
description: "Project-specific guidance for [Technology] development"
agent_type: "project"
technology: "[technology-name]"
version: "1.0.0"
---

# [Technology] Project Agent

> Project-specific guidance for [Technology] development.
> Installed in: [Project Directory]

## Project Type: [Technology] Application

**Tech Stack**: [Primary technologies]

## Best Practices

### [Category 1]
- Best practice 1
- Best practice 2

### [Category 2]
- Best practice 1
- Best practice 2

## Code Conventions

### File Structure
```
[Recommended structure]
```

### Naming Conventions
- [Convention 1]
- [Convention 2]

## Development Commands

### [Command Category]
```bash
[commands with explanations]
```

## Common Patterns

### [Pattern Name]
[Description and example]

## Common Issues

### Problem: [Issue]
**Solution**: [Solution]

## Project-Specific Commands

When working in this [Technology] project, I understand:
- [Capability 1]
- [Capability 2]
```

### React Agent

Create detailed React agent at `project-agents/react/CLAUDE.md`:

```markdown
---
title: "React Project Agent"
description: "Best practices and patterns for React development"
agent_type: "project"
technology: "react"
version: "1.0.0"
---

# React Project Agent

## Project Type: React Application

**Tech Stack**: React, JavaScript/TypeScript

## Best Practices

### Component Structure
- Use functional components with hooks
- Keep components small and focused (< 200 lines)
- Separate business logic from presentation
- One component per file
- Use composition over inheritance

### State Management
- useState for local state
- useContext for shared state across components
- Consider Redux/Zustand for complex global state
- Avoid prop drilling (max 2-3 levels)
- Lift state up when multiple components need it

### Performance
- Use React.memo for expensive components
- Use useMemo for expensive calculations
- Use useCallback for functions passed to children
- Lazy load routes and heavy components
- Virtualize long lists (react-window, react-virtual)

### Side Effects
- useEffect for side effects only
- Cleanup functions for subscriptions
- Dependencies array must be complete
- Avoid useEffect for derived state

## Code Conventions

### File Structure
```
src/
├── components/
│   ├── common/          # Reusable UI components
│   │   ├── Button/
│   │   │   ├── Button.tsx
│   │   │   ├── Button.test.tsx
│   │   │   └── Button.module.css
│   │   └── Input/
│   └── features/        # Feature-specific components
│       └── auth/
│           ├── LoginForm.tsx
│           └── RegisterForm.tsx
├── hooks/               # Custom hooks
│   ├── useAuth.ts
│   └── useApi.ts
├── context/             # Context providers
│   └── AuthContext.tsx
├── utils/               # Utility functions
│   └── formatDate.ts
├── services/            # API and external services
│   └── api.ts
├── types/               # TypeScript types
│   └── User.ts
└── App.tsx
```

### Naming Conventions
- **Components**: PascalCase (`UserProfile.tsx`)
- **Hooks**: camelCase with "use" prefix (`useAuth.ts`)
- **Utils**: camelCase (`formatDate.ts`)
- **Constants**: UPPER_SNAKE_CASE (`API_URL`)
- **Types**: PascalCase (`User`, `AuthState`)

### Import Order
```typescript
// 1. External libraries
import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';

// 2. Internal components
import { Button } from '@/components/common/Button';
import { LoginForm } from '@/components/features/auth/LoginForm';

// 3. Hooks and utils
import { useAuth } from '@/hooks/useAuth';
import { formatDate } from '@/utils/formatDate';

// 4. Types
import type { User } from '@/types/User';

// 5. Styles
import styles from './Component.module.css';
```

## Common Patterns

### Custom Hooks
```typescript
// Good: Reusable logic in custom hook
function useLocalStorage<T>(key: string, initialValue: T) {
  const [value, setValue] = useState<T>(() => {
    const stored = localStorage.getItem(key);
    return stored ? JSON.parse(stored) : initialValue;
  });

  useEffect(() => {
    localStorage.setItem(key, JSON.stringify(value));
  }, [key, value]);

  return [value, setValue] as const;
}
```

### Component Composition
```typescript
// Good: Composition pattern
function Card({ children }: { children: React.ReactNode }) {
  return <div className="card">{children}</div>;
}

function CardHeader({ children }: { children: React.ReactNode }) {
  return <div className="card-header">{children}</div>;
}

// Usage
<Card>
  <CardHeader>Title</CardHeader>
  <p>Content</p>
</Card>
```

### Error Boundaries
```typescript
class ErrorBoundary extends React.Component<Props, State> {
  static getDerivedStateFromError(error: Error) {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, info: React.ErrorInfo) {
    logError(error, info);
  }

  render() {
    if (this.state.hasError) {
      return <ErrorFallback error={this.state.error} />;
    }
    return this.props.children;
  }
}
```

## Development Commands

### Start Development Server
```bash
npm run dev        # or yarn dev
# Usually runs on http://localhost:3000
```

### Testing
```bash
npm test                # Run tests
npm run test:watch      # Watch mode
npm run test:coverage   # Coverage report
```

### Building
```bash
npm run build          # Production build
npm run preview        # Preview build locally
```

### Linting
```bash
npm run lint           # Check for issues
npm run lint:fix       # Auto-fix issues
```

## Common Issues

### Problem: Component re-renders too often
**Symptoms**: Sluggish UI, console.logs firing repeatedly

**Solutions**:
1. Use React.memo to prevent unnecessary re-renders
2. Use useMemo for expensive calculations
3. Use useCallback for functions passed to children
4. Check dependencies in useEffect
5. Use React DevTools Profiler to find issues

### Problem: State updates don't reflect
**Symptoms**: setState doesn't seem to work

**Solutions**:
1. Remember setState is async
2. Use functional updates: `setState(prev => prev + 1)`
3. Don't mutate state directly
4. Check if state is actually changing (React uses Object.is)

### Problem: useEffect running too often
**Symptoms**: Infinite loops, excessive API calls

**Solutions**:
1. Add proper dependencies array
2. Use useCallback for function dependencies
3. Consider if useEffect is needed (derived state?)
4. Split into multiple useEffects by concern

## Testing with React Testing Library

### Component Testing Pattern
```typescript
import { render, screen, fireEvent } from '@testing-library/react';
import { LoginForm } from './LoginForm';

describe('LoginForm', () => {
  it('should submit form with credentials', () => {
    const onSubmit = jest.fn();
    render(<LoginForm onSubmit={onSubmit} />);

    fireEvent.change(screen.getByLabelText(/email/i), {
      target: { value: 'user@example.com' }
    });

    fireEvent.change(screen.getByLabelText(/password/i), {
      target: { value: 'password123' }
    });

    fireEvent.click(screen.getByRole('button', { name: /login/i }));

    expect(onSubmit).toHaveBeenCalledWith({
      email: 'user@example.com',
      password: 'password123'
    });
  });
});
```

## Libraries and Tools

### Recommended Libraries
- **Routing**: React Router
- **State**: Zustand or Redux Toolkit
- **Forms**: React Hook Form
- **HTTP**: Axios or TanStack Query
- **Styling**: Tailwind CSS or CSS Modules
- **Testing**: React Testing Library + Jest
- **Dev Tools**: React DevTools, Redux DevTools

## Project-Specific Commands

When working in this React project, I understand:
- React 18 features (Suspense, Transitions, etc.)
- Component patterns and anti-patterns
- Performance optimization techniques
- Testing best practices
- Common library patterns (Router, Query, etc.)
- Build and deployment considerations

---

**Generated by AIDA** | React Agent v1.0.0
```

### CLI Agent Installation

Add to CLI tool:

```bash
agent_install() {
    local agent_type="$1"

    if [[ -z "$agent_type" ]]; then
        error "Please specify an agent type"
        echo "Use: ${ASSISTANT_NAME} agent list"
        exit 1
    fi

    # Check if in a project directory
    if [[ ! -d ".git" ]] && [[ ! -f "package.json" ]] && [[ ! -f "go.mod" ]]; then
        warn "Not in a project directory"
        read -p "Install agent here anyway? (y/N): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 0
        fi
    fi

    # Check if agent exists
    if [[ ! -f "$AIDE_FRAMEWORK/project-agents/$agent_type/CLAUDE.md" ]]; then
        error "Agent '$agent_type' not found"
        agent_list
        exit 1
    fi

    # Check if CLAUDE.md already exists
    if [[ -f "CLAUDE.md" ]]; then
        info "Existing CLAUDE.md found"
        info "Agent will be appended to existing file"
        echo ""
        read -p "Continue? (y/N): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 0
        fi

        # Append agent to existing file
        echo "" >> CLAUDE.md
        echo "---" >> CLAUDE.md
        echo "" >> CLAUDE.md
        cat "$AIDE_FRAMEWORK/project-agents/$agent_type/CLAUDE.md" >> CLAUDE.md
    else
        # Copy agent as new CLAUDE.md
        cp "$AIDE_FRAMEWORK/project-agents/$agent_type/CLAUDE.md" CLAUDE.md
    fi

    success "Installed $agent_type agent to $(pwd)/CLAUDE.md"
    info "Claude will now have $agent_type-specific guidance for this project"
}

agent_list() {
    info "Available project agents:"
    echo ""

    for agent_dir in "$AIDE_FRAMEWORK"/project-agents/*/; do
        if [[ -d "$agent_dir" ]] && [[ ! "$agent_dir" == *"_template"* ]]; then
            local name=$(basename "$agent_dir")
            local desc=$(grep "description:" "$agent_dir/CLAUDE.md" | head -1 | cut -d'"' -f2)
            echo "  $name"
            echo "    $desc"
            echo ""
        fi
    done

    echo "Usage: ${ASSISTANT_NAME} agent install [type]"
}
```

### User Workflow

```bash
# List available agents
$ cd ~/Development/personal/my-react-app
$ jarvis agent list

Available project agents:

  react
    Best practices and patterns for React development

  nextjs
    Next.js-specific patterns and conventions

  python
    Python best practices and common frameworks

  golang
    Go idioms and project structure

Usage: jarvis agent install [type]

# Install agent
$ jarvis agent install react

✓ Installed react agent to /Users/you/Development/personal/my-react-app/CLAUDE.md
Claude will now have react-specific guidance for this project

# Now Claude understands React patterns
$ [In Claude conversation]
"How should I structure this authentication component?"

Claude: [Reads CLAUDE.md with React agent]
"For this React project, I recommend using a functional component with hooks.
Based on the project structure, create components/features/auth/LoginForm.tsx..."
```

## Dependencies

- #010 (CLI tool template for agent commands)

## Related Issues

- #009 (Dev Assistant agent integrates with project agents)

## Definition of Done

- [ ] Project agents directory structure created
- [ ] At least 4 tech-specific agents created (React, Next.js, Go, Python)
- [ ] Agent installation CLI commands work
- [ ] Agent merging with existing CLAUDE.md works
- [ ] Documentation for creating custom agents
- [ ] Documentation for using project agents
- [ ] Tested in real projects
- [ ] Ready for 0.5.0 milestone
