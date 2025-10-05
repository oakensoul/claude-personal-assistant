---
title: "Project-Specific Agents"
description: "Pre-built agent configurations for different tech stacks and project types"
category: "guide"
tags: ["agents", "project-agents", "tech-stacks", "frameworks", "templates"]
last_updated: "2025-10-04"
status: "published"
audience: "users"
---

# Project-Specific Agents

Pre-built agent configurations for different tech stacks and project types.

## What Are Project Agents?

Project agents are specialized CLAUDE.md configurations tailored for specific technologies, frameworks, or project types. When installed into a project directory, they provide Claude with deep knowledge about that tech stack, including:

- Best practices and conventions
- Common patterns and anti-patterns
- Testing and deployment procedures
- Project structure guidelines
- Framework-specific guidance

## Available Agents

### Frontend Frameworks

- **[React](react/CLAUDE.md)** - React applications (hooks, components, state management)
- **[Next.js](nextjs/CLAUDE.md)** - Next.js applications (App Router, Server Components, SSR/SSG)
- **[Vue.js](vue/CLAUDE.md)** - Vue.js applications (Composition API, Vue Router, Pinia)
- **[Svelte](svelte/CLAUDE.md)** - Svelte applications (stores, reactivity, SvelteKit)

### Backend Frameworks

- **[Node.js/Express](nodejs/CLAUDE.md)** - Node.js with Express
- **[Python/FastAPI](python-fastapi/CLAUDE.md)** - Python with FastAPI
- **[Python/Django](python-django/CLAUDE.md)** - Python with Django
- **[Go](golang/CLAUDE.md)** - Go applications (standard library, common patterns)
- **[Rust](rust/CLAUDE.md)** - Rust applications (ownership, borrowing, cargo)

### Languages

- **[TypeScript](typescript/CLAUDE.md)** - TypeScript projects (types, generics, advanced patterns)
- **[Python](python/CLAUDE.md)** - General Python projects (PEP 8, testing, virtual envs)
- **[JavaScript](javascript/CLAUDE.md)** - Modern JavaScript (ES6+, async patterns)

### DevOps & Tools

- **[Docker](docker/CLAUDE.md)** - Containerized applications
- **[Kubernetes](kubernetes/CLAUDE.md)** - K8s deployments
- **[CI/CD](cicd/CLAUDE.md)** - CI/CD pipelines (GitHub Actions, GitLab CI)

### Mobile

- **[React Native](react-native/CLAUDE.md)** - React Native applications
- **[iOS/Swift](ios/CLAUDE.md)** - iOS applications with Swift
- **[Android/Kotlin](android/CLAUDE.md)** - Android applications with Kotlin

## How to Use Project Agents

### Installing an Agent

Navigate to your project directory and install the appropriate agent:

```bash
cd ~/Development/personal/my-react-app/
jarvis agent install react
```

This will:

1. Copy the React agent CLAUDE.md to your project directory
2. Merge with existing project CLAUDE.md if present
3. Make Claude aware of React-specific patterns and practices

### Using with Claude

Once installed, Claude will automatically understand the tech stack when you work in that directory:

```text
You: "How should I structure this authentication component?"

Claude: [Reads project CLAUDE.md with React agent]
        "For this React project, I recommend creating a custom
        useAuth hook to manage authentication state..."
```

### Multiple Agents

For full-stack projects, you can install multiple agents:

```bash
# Full-stack Next.js + Python project
jarvis agent install nextjs
jarvis agent install python-fastapi
```

Claude will understand both contexts and help with both frontend and backend.

### Listing Installed Agents

```bash
jarvis agent list
```

Shows which agents are installed in the current project.

### Updating Agents

When agent templates are updated:

```bash
jarvis agent update react
```

Updates the installed agent while preserving your customizations.

### Removing Agents

```bash
jarvis agent remove react
```

Removes the agent from the project.

## Project Agent Structure

Each agent is a CLAUDE.md file with this structure:

```text
# [Technology] Project Agent

## Project Type: [Type]

**Tech Stack**: [Stack details]

## Best Practices
[Framework-specific best practices]

## Code Conventions
[Naming, file structure, etc.]

## Common Patterns
[Design patterns for this tech]

## Testing
[Testing approaches and tools]

## Development Commands
[Common dev commands]

## Deployment
[Deployment procedures]

## Common Issues
[Known problems and solutions]

## Project-Specific Commands
[Custom commands for this tech]
```

## Creating Custom Agents

Want to create your own project agent? See [Creating Custom Project Agents](../docs/project-agents/creating-agents.md).

### Quick Example

Create a custom agent for your specific needs:

```bash
# Create custom agent
mkdir -p ~/.claude/custom-agents/my-stack/
vim ~/.claude/custom-agents/my-stack/CLAUDE.md

# Install in project
jarvis agent install my-stack --custom
```

## Agent Development

### Contributing New Agents

We welcome contributions of new project agents! To contribute:

1. Fork the repository
2. Create `project-agents/your-tech/CLAUDE.md`
3. Follow the [agent template structure](#project-agent-structure)
4. Test with real projects
5. Submit a pull request

See [CONTRIBUTING.md](../docs/developer-guide/CONTRIBUTING.md) for details.

### Agent Template

Start with our template:

```bash
cp project-agents/_template/CLAUDE.md project-agents/your-tech/
```

### Testing Agents

Test your agent:

```bash
# Install in test project
cd ~/test-project/
jarvis agent install your-tech --dev

# Test with Claude
# Verify Claude understands the tech stack
# Check guidance is accurate and helpful
```

## Examples

### Example 1: React Project

```bash
cd ~/Development/personal/my-react-app/
jarvis agent install react

# Now Claude knows React patterns
You: "Create a custom hook for fetching user data"
Claude: "Here's a useUserData hook following React best practices..."
```

### Example 2: Full-Stack Next.js + FastAPI

```bash
cd ~/Development/work/saas-app/
jarvis agent install nextjs
jarvis agent install python-fastapi

# Claude understands both stacks
You: "How should I structure the API calls from Next.js to FastAPI?"
Claude: "For this Next.js + FastAPI stack, I recommend..."
```

### Example 3: DevOps Project

```bash
cd ~/Development/infrastructure/k8s-cluster/
jarvis agent install kubernetes
jarvis agent install docker

# Claude helps with DevOps tasks
You: "Help me optimize this Dockerfile for production"
Claude: "For production Kubernetes deployments, here's an optimized Dockerfile..."
```

## Agent Updates

Agents are versioned with AIDE releases. Update to get latest improvements:

```bash
# Update AIDE framework
cd ~/.aide
git pull

# Update installed agents
cd ~/Development/personal/my-react-app/
jarvis agent update react
```

## FAQ

**Q: Can I have multiple agents in one project?**
A: Yes! Full-stack projects often need frontend + backend agents.

**Q: Do agents conflict with each other?**
A: No, agents are designed to work together. Claude merges their guidance.

**Q: Can I customize an installed agent?**
A: Yes! Edit the project's CLAUDE.md to add your specific preferences.

**Q: Are agents required?**
A: No, they're optional. AIDE works fine without them, but agents provide tech-specific guidance.

**Q: How do agents differ from the main AIDE config?**
A: Main AIDE config (~/CLAUDE.md) is for life management. Project agents are for code/tech guidance.

**Q: Can I create private agents for my company?**
A: Yes! Create custom agents in your private dotfiles repo.

## Roadmap

**Coming Soon:**

- More framework agents (Angular, Ember, etc.)
- Database-specific agents (PostgreSQL, MongoDB, etc.)
- Cloud platform agents (AWS, GCP, Azure)
- Testing framework agents (Jest, Pytest, etc.)
- Language-specific linters and formatters guidance

**Future:**

- Agent marketplace
- Community-contributed agents
- Agent discovery tool
- Automatic agent detection (read package.json, go.mod, etc.)

## Support

Questions about project agents?

- Check [Project Agents Documentation](../docs/project-agents/)
- Ask in GitHub Discussions
- Create an issue

---

**Project agents make Claude a tech-stack expert for your specific projects!**
