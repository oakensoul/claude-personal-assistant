---
agent: shell-script-specialist
updated: "2025-10-04"
knowledge_count: 0
memory_type: "agent-specific"
---

# Knowledge Index for Shell Script Specialist

This index catalogs all knowledge resources available to the shell-script-specialist agent. These act as persistent memories that the agent can reference during execution for bash/zsh scripting, cross-platform compatibility, and shell best practices.

## Local Knowledge Files

### Core Concepts
<!-- Add core concept files here as they are created -->

### Patterns
<!-- Add pattern files here as they are created -->

### Decisions
<!-- Add decision files here as they are created -->

## External Documentation Links

### Shell Scripting
- [Bash Reference Manual](https://www.gnu.org/software/bash/manual/bash.html) - Official GNU Bash documentation
- [Bash Hackers Wiki](https://wiki.bash-hackers.org/) - Community-maintained bash scripting guide
- [ShellCheck Wiki](https://www.shellcheck.net/wiki/) - Common shell script issues and best practices
- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html) - Shell scripting conventions and standards

### Zsh Specific
- [Zsh Documentation](https://zsh.sourceforge.io/Doc/) - Official Zsh documentation
- [Zsh Guide](https://zsh.sourceforge.io/Guide/) - User's guide to Zsh features
- [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh/wiki) - Popular Zsh framework documentation

### Cross-Platform Compatibility
- [POSIX Shell Spec](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html) - POSIX shell command language
- [macOS vs Linux Differences](https://ponderthebits.com/2017/01/know-your-tools-linux-gnu-vs-mac-bsd-command-line-utilities-grep-strings-sed-and-find/) - Platform-specific command differences
- [Detecting OS in Shell Scripts](https://stackoverflow.com/questions/3466166/how-to-check-if-running-in-cygwin-mac-or-linux) - Cross-platform detection patterns

### Script Quality & Testing
- [ShellCheck](https://github.com/koalaman/shellcheck) - Static analysis tool for shell scripts
- [BATS](https://github.com/bats-core/bats-core) - Bash Automated Testing System
- [shUnit2](https://github.com/kward/shunit2) - Unit testing framework for shell scripts

### Error Handling & Debugging
- [Bash Error Handling](https://wizardzines.com/comics/bash-errors/) - Visual guide to bash error handling
- [Bash Debugging](https://tldp.org/LDP/Bash-Beginners-Guide/html/sect_02_03.html) - Debugging techniques
- [Unofficial Bash Strict Mode](http://redsymbol.net/articles/unofficial-bash-strict-mode/) - Best practices for robust scripts

### Security
- [Shell Script Security](https://github.com/anordal/shellharden/blob/master/how_to_do_things_safely_in_bash.md) - Safe scripting practices
- [Input Validation in Shell](https://www.cyberciti.biz/tips/bash-shell-parameter-substitution-2.html) - Secure input handling

## Usage Notes

**When to Add Knowledge:**
- New cross-platform pattern discovered → Add to patterns section
- Important scripting decision made → Record in decisions history
- Useful shell utility or technique found → Add to external links
- Error handling pattern developed → Document in patterns
- Platform compatibility issue solved → Add to core concepts

**Knowledge Maintenance:**
- Update this index.md when adding/removing files
- Increment knowledge_count in frontmatter
- Update the `updated` date
- Keep knowledge focused on shell scripting and platform compatibility
- Link to official documentation rather than duplicating it

**Memory Philosophy:**
- **CLAUDE.md**: Quick reference for when to use shell-script-specialist agent (always in context)
- **Knowledge Base**: Detailed scripting patterns, compatibility solutions, decision history (loaded when agent invokes)
- Both systems work together for efficient context management

## Knowledge Priorities

**High Priority Knowledge:**
1. Cross-platform compatibility patterns (macOS/Linux)
2. Bash vs Zsh differences and best practices
3. POSIX compliance and portability
4. Error handling and input validation patterns
5. Script testing and quality assurance techniques

**Medium Priority Knowledge:**
1. Performance optimization for shell scripts
2. Advanced bash/zsh features and idioms
3. Integration with system utilities (grep, sed, awk)
4. Script packaging and distribution patterns

**Low Priority Knowledge:**
1. Platform-specific documentation (link to official docs instead)
2. Basic shell concepts (focus on AIDA-specific patterns)
3. Generic scripting tutorials (focus on project-specific solutions)