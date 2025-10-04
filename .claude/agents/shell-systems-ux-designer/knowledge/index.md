---
agent: shell-systems-ux-designer
updated: "2025-10-04"
knowledge_count: 0
memory_type: "agent-specific"
---

# Knowledge Index for Shell Systems UX Designer

This index catalogs all knowledge resources available to the shell-systems-ux-designer agent. These act as persistent memories that the agent can reference during execution for CLI UX design, help text creation, and error message crafting.

## Local Knowledge Files

### Core Concepts
<!-- Add core concept files here as they are created -->

### Patterns
<!-- Add pattern files here as they are created -->

### Decisions
<!-- Add decision files here as they are created -->

## External Documentation Links

### CLI UX Design
- [Command Line Interface Guidelines](https://clig.dev/) - Open-source guide to CLI design
- [12 Factor CLI Apps](https://medium.com/@jdxcode/12-factor-cli-apps-dd3c227a0e46) - Principles for modern CLI design
- [Human-Centered CLI Design](https://www.nngroup.com/articles/command-line-tools/) - UX principles for command-line tools
- [Designing CLI Tools](https://increment.com/software-architecture/designing-cli-tools/) - User experience in terminal applications

### Help Text & Documentation
- [man page format](https://man7.org/linux/man-pages/man7/man-pages.7.html) - Standard manual page formatting
- [GNU Standards for CLI](https://www.gnu.org/prep/standards/html_node/Command_002dLine-Interfaces.html) - GNU command-line interface conventions
- [POSIX Utility Conventions](https://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap12.html) - Standard argument syntax

### Error Messages & Feedback
- [Writing Helpful Error Messages](https://www.nngroup.com/articles/error-message-guidelines/) - UX guidelines for error messages
- [CLI Error Handling Patterns](https://github.com/cli-guidelines/cli-guidelines#errors) - Best practices for CLI errors
- [Exit Status Conventions](https://tldp.org/LDP/abs/html/exitcodes.html) - Standard exit codes for scripts

### Color & Formatting
- [ANSI Color Codes](https://gist.github.com/fnky/458719343aabd01cfb17a3a4f7296797) - Terminal color and formatting reference
- [Terminal Color Accessibility](https://www.a11yproject.com/posts/terminal-accessibility/) - Accessible terminal output design
- [Rich CLI](https://github.com/Textualize/rich) - Python library for rich terminal output (design patterns applicable)

### Interactive CLI
- [Prompt Design Patterns](https://github.com/terkelg/prompts) - Interactive prompt patterns
- [Progress Indicators](https://github.com/sindresorhus/cli-spinners) - Loading and progress display
- [CLI Autocomplete](https://github.com/withfig/autocomplete) - Command completion patterns

### Testing & Validation
- [CLI Testing Strategies](https://github.com/cli-guidelines/cli-guidelines#testing) - How to test CLI UX
- [Accessibility Testing for CLI](https://developer.paciellogroup.com/blog/2018/03/short-note-on-getting-spaced-out-with-sc-1-4-12-text-spacing/) - Ensuring accessible terminal experiences

## Usage Notes

**When to Add Knowledge:**
- New UX pattern for CLI discovered → Add to patterns section
- Important design decision made → Record in decisions history
- Useful CLI tool or library found → Add to external links
- Help text template created → Document in patterns
- User feedback on UX implemented → Add to core concepts

**Knowledge Maintenance:**
- Update this index.md when adding/removing files
- Increment knowledge_count in frontmatter
- Update the `updated` date
- Keep knowledge focused on CLI UX and user experience design
- Link to official documentation rather than duplicating it

**Memory Philosophy:**
- **CLAUDE.md**: Quick reference for when to use shell-systems-ux-designer agent (always in context)
- **Knowledge Base**: Detailed UX patterns, help text templates, decision history (loaded when agent invokes)
- Both systems work together for efficient context management

## Knowledge Priorities

**High Priority Knowledge:**
1. CLI help text templates and conventions
2. Error message formatting and clarity patterns
3. Interactive prompt design for AIDA commands
4. Progress indicator and feedback patterns
5. Accessibility considerations for terminal UX

**Medium Priority Knowledge:**
1. Color and formatting standards for consistency
2. Command naming conventions and discoverability
3. Autocomplete and suggestion patterns
4. Output formatting for different verbosity levels

**Low Priority Knowledge:**
1. Platform-specific terminal capabilities (document as needed)
2. Advanced terminal features (focus on widely-supported patterns)
3. Generic UX principles (focus on CLI-specific applications)