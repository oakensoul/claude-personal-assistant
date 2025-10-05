---
title: "AIDA Target Audience"
category: "core-concepts"
tags: ["audience", "personas", "use-cases", "users"]
last_updated: "2025-10-04"
---

# AIDA Target Audience

## Overview

AIDA targets users who want AI assistance that's personal, customizable, and privacy-aware. While AIDA is accessible to anyone comfortable with command-line tools, certain user types will find it particularly valuable.

## Primary Audience

### Developers

**Who**: Software engineers, DevOps, full-stack developers, data scientists
**Why AIDA**:

- CLI-first fits existing workflow (terminal, git, editors)
- Customizable agents for tech-stack specific assistance
- Integration with development tools (git, Obsidian, dotfiles)
- Privacy-aware (can work on proprietary code without data leaks)
- Extensible (can add custom agents and workflows)

**Common Use Cases**:

- Daily standup preparation and task prioritization
- Project planning and architecture decisions
- Code review assistance and documentation
- Knowledge management (learnings, patterns, decisions)
- Context switching between multiple projects

**Pain Points AIDA Solves**:

- Generic AI tools don't remember project context
- Switching between ChatGPT tabs loses conversation history
- No way to customize AI behavior for different contexts (work vs personal)
- Concern about sending proprietary code to cloud AI services
- Manually managing TODO lists, notes, and project status

### Tech-Savvy Power Users

**Who**: System administrators, technical writers, researchers, advanced macOS users
**Why AIDA**:

- Comfortable with terminal and configuration files
- Want personal assistant that integrates with their workflow
- Value privacy and local-first approach
- Appreciate customization and control
- Use text-based tools (vim, tmux, Obsidian, etc.)

**Common Use Cases**:

- Knowledge capture and synthesis
- Research assistance and note-taking
- System administration tasks and automation
- Writing technical documentation
- Personal productivity and task management

**Pain Points AIDA Solves**:

- AI tools feel impersonal and generic
- No memory of previous conversations or preferences
- Limited customization options
- Data privacy concerns with cloud services
- Disconnected tools (AI, notes, tasks, calendar)

## Secondary Audience

### Solo Developers & Indie Hackers

**Who**: Independent developers, freelancers, startup founders
**Why AIDA**:

- Wearing multiple hats (dev, PM, designer, marketer)
- Need assistant for diverse tasks beyond just coding
- Appreciate open-source and customizable tools
- Often working alone, need "thought partner"
- Budget-conscious (prefer self-hosted/local tools)

**Common Use Cases**:

- Product planning and prioritization
- Marketing copy and content creation
- Customer support and documentation
- Financial tracking and business planning
- Learning new technologies and skills

**Pain Points AIDA Solves**:

- Juggling multiple roles without team support
- Context switching between business and technical tasks
- Need for different "modes" (e.g., creative vs analytical)
- Isolation (no team to bounce ideas off)
- Cost of multiple SaaS tools

### Team Leads & Engineering Managers

**Who**: Tech leads, engineering managers, project managers
**Why AIDA**:

- Need to organize team workflows and knowledge
- Balance technical and leadership responsibilities
- Want AI that understands technical context
- Value privacy for sensitive team/business info
- Appreciate structured knowledge management

**Common Use Cases**:

- Sprint planning and roadmap management
- One-on-one preparation and follow-up
- Team documentation and knowledge sharing
- Performance review and feedback preparation
- Technical decision documentation

**Pain Points AIDA Solves**:

- Losing track of team context and decisions
- No central place for team knowledge
- Generic AI doesn't understand technical nuances
- Privacy concerns with sensitive team information
- Difficulty switching between IC work and management tasks

### Knowledge Workers

**Who**: Researchers, writers, analysts, consultants
**Why AIDA**:

- Work with large amounts of information
- Need to synthesize and connect ideas
- Value structured knowledge management
- Comfortable with text-based workflows
- Appreciate customizable tools

**Common Use Cases**:

- Research synthesis and note-taking
- Writing assistance and editing
- Information organization and retrieval
- Idea generation and brainstorming
- Project and client management

**Pain Points AIDA Solves**:

- Information overload without good organization
- AI tools don't remember previous research context
- Disconnected tools for notes, tasks, writing
- Privacy concerns with proprietary research
- Generic AI lacks domain-specific knowledge

## Anti-Personas (Who AIDA Is NOT For)

### Non-Technical Users

**Why Not**: AIDA assumes comfort with command-line, configuration files, and text-based workflows. Users who prefer GUI applications and avoid the terminal will find AIDA frustrating.

**Alternative**: Wait for future web dashboard (post-1.0.0) or use consumer AI tools like ChatGPT app

### Windows-Primary Users

**Why Not**: AIDA focuses on macOS and Linux. Windows support is not a priority for early releases.

**Alternative**: Wait for Windows support (post-1.0.0) or use WSL/Linux VM

### Enterprise Teams Needing Multi-User Features

**Why Not**: AIDA focuses on individual productivity, not team collaboration. No shared workspaces, role-based access, or team analytics.

**Alternative**: Look for enterprise AI tools with team features

### Users Needing Mobile Access

**Why Not**: AIDA is CLI-first, no mobile app planned for 1.0.0.

**Alternative**: Use Claude mobile app for basic AI assistance

### Users Requiring 24/7 Availability

**Why Not**: AIDA is local-first, runs on user's machine, not cloud-hosted.

**Alternative**: Use cloud AI services with guaranteed uptime

## User Personas

### Persona 1: "Sarah the Solo Developer"

- **Age**: 28
- **Role**: Full-stack developer, indie hacker
- **Goals**: Build and ship products quickly, learn new technologies, maintain work-life balance
- **Challenges**: Working alone, context switching, staying organized
- **Tech Stack**: TypeScript, React, Node.js, PostgreSQL, Vercel
- **Tools**: VS Code, iTerm, Obsidian, GitHub, Linear
- **AIDA Use**:
  - Morning routine: "What should I focus on today?"
  - Project planning: "Help me prioritize features for v2.0"
  - Learning: "Explain WebSockets like I'm familiar with REST APIs"
  - Context switching: Switch between JARVIS (work) and FRIDAY (learning) personalities

### Persona 2: "David the DevOps Engineer"

- **Age**: 35
- **Role**: Senior DevOps engineer at mid-size startup
- **Goals**: Automate infrastructure, maintain system reliability, document decisions
- **Challenges**: Oncall rotations, multiple environments, knowledge sharing with team
- **Tech Stack**: Kubernetes, Terraform, AWS, Python, Go, Datadog
- **Tools**: Terminal, vim, tmux, Confluence, PagerDuty
- **AIDA Use**:
  - Incident response: "What are common causes of 503 errors in k8s?"
  - Documentation: "Generate runbook for database failover procedure"
  - Learning: "Help me understand Istio service mesh concepts"
  - Knowledge capture: "Remember that we use Terraform workspaces for env separation"

### Persona 3: "Maria the Tech Lead"

- **Age**: 32
- **Role**: Engineering team lead at Series B company
- **Goals**: Ship features on time, grow team members, maintain code quality
- **Challenges**: Balance coding with management, track team progress, make technical decisions
- **Tech Stack**: Java, Spring Boot, Kafka, PostgreSQL, Kubernetes
- **Tools**: IntelliJ, Jira, Slack, GitHub, Confluence
- **AIDA Use**:
  - Sprint planning: "What features should we prioritize this sprint?"
  - One-on-ones: "Prepare talking points for 1:1 with junior engineer"
  - Technical decisions: "Document decision to use Kafka vs RabbitMQ"
  - Code review: "Review this PR and suggest improvements"

### Persona 4: "Alex the Researcher"

- **Age**: 40
- **Role**: Independent AI researcher and technical writer
- **Goals**: Synthesize research, write articles, stay current with AI developments
- **Challenges**: Information overload, organizing notes, connecting ideas
- **Tech Stack**: Python, Jupyter, pandas, scikit-learn, PyTorch
- **Tools**: VS Code, Obsidian, Zotero, Terminal, git
- **AIDA Use**:
  - Research synthesis: "Summarize key points from recent papers on LLM reasoning"
  - Writing assistance: "Help me outline article on transformer architectures"
  - Knowledge organization: "Connect this concept to previous research on attention mechanisms"
  - Idea generation: "What are emerging research directions in multimodal AI?"

## Use Cases by Category

### Daily Workflow Management

- Start-of-day planning and prioritization
- End-of-day summary and reflection
- Context switching between projects
- Task tracking and completion
- Time management and focus

### Development Assistance

- Code review and improvement suggestions
- API design and architecture decisions
- Documentation generation
- Debugging assistance
- Learning new technologies

### Knowledge Management

- Note-taking and organization
- Research synthesis
- Decision documentation
- Pattern recognition and sharing
- Knowledge retrieval and search

### Project Management

- Roadmap planning and prioritization
- Feature scoping and estimation
- Sprint planning and retrospectives
- Milestone tracking
- Stakeholder communication

### Writing & Communication

- Technical writing and documentation
- Email drafting and responses
- Presentation preparation
- Blog posts and articles
- Team communication

### Learning & Growth

- Technology exploration and learning
- Code examples and tutorials
- Concept explanations
- Best practices and patterns
- Skill development tracking

## Adoption Journey

### Awareness

**How they discover AIDA**:

- GitHub search for "AI assistant CLI"
- Hacker News discussions
- Reddit (r/commandline, r/MacOS, r/selfhosted)
- Dev.to articles and tutorials
- Word-of-mouth from colleagues

**Initial Questions**:

- "What makes this different from ChatGPT?"
- "Is my data private?"
- "How hard is it to set up?"
- "Can I customize it?"

### Evaluation

**Trial Phase**:

- Install AIDA and try default JARVIS personality
- Run through basic commands (status, help)
- Test conversation quality
- Evaluate vs current workflow

**Key Decision Factors**:

- Ease of installation
- Quality of AI responses
- Privacy and data control
- Customization options
- Personality system appeal

### Adoption

**Initial Usage**:

- Use for daily standup preparation
- Try different personalities
- Integrate into morning routine
- Start capturing notes and decisions

**Habit Formation**:

- AIDA becomes default for questions/help
- Prefer AIDA over switching to browser
- Customize personality to preferences
- Share AIDA with colleagues

### Advocacy

**Power User Stage**:

- Create custom agents
- Share personality configurations
- Contribute to documentation
- Help others adopt AIDA
- Provide feedback and feature requests

## Success Metrics

AIDA is reaching its target audience when:

- 70%+ of users are developers or tech-savvy power users
- Users adopt AIDA within first week of installation
- Daily active users stick around for 30+ days
- Users customize personalities (not just using defaults)
- Community contributions emerge (agents, workflows, personalities)
- Positive feedback on privacy and local-first approach

## References

- **Product Vision**: See `/Users/oakensoul/Developer/oakensoul/claude-personal-assistant/.claude/agents/aida-product-manager/knowledge/core-concepts/product-vision.md`
- **User Stories**: See `/Users/oakensoul/Developer/oakensoul/claude-personal-assistant/.claude/agents/aida-product-manager/knowledge/patterns/user-stories.md`
- **Design Principles**: See `/Users/oakensoul/Developer/oakensoul/claude-personal-assistant/.claude/agents/aida-product-manager/knowledge/core-concepts/design-principles.md`
