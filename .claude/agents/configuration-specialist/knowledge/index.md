---
agent: configuration-specialist
updated: "2025-10-04"
knowledge_count: 0
memory_type: "agent-specific"
---

# Knowledge Index for Configuration Specialist

This index catalogs all knowledge resources available to the configuration-specialist agent. These act as persistent memories that the agent can reference during execution for YAML/JSON/TOML configuration, validation, templating, and configuration management.

## Local Knowledge Files

### Core Concepts
<!-- Add core concept files here as they are created -->

### Patterns
<!-- Add pattern files here as they are created -->

### Decisions
<!-- Add decision files here as they are created -->

## External Documentation Links

### Configuration Formats
- [YAML Specification](https://yaml.org/spec/1.2.2/) - Official YAML language spec
- [JSON Schema](https://json-schema.org/) - JSON validation and documentation standard
- [TOML Specification](https://toml.io/en/) - TOML configuration format spec
- [YAML vs JSON vs TOML](https://www.cloudbees.com/blog/yaml-tutorial-everything-you-need-get-started) - Format comparison guide

### YAML Best Practices
- [YAML Gotchas](https://hitchdev.com/strictyaml/why/implicit-typing-removed/) - Common YAML pitfalls
- [YAML Style Guide](https://yamllint.readthedocs.io/en/stable/rules.html) - Linting rules and conventions
- [YAML Multiline Strings](https://yaml-multiline.info/) - Guide to YAML string formatting
- [YAML Anchors & Aliases](https://support.atlassian.com/bitbucket-cloud/docs/yaml-anchors/) - Reusing configuration blocks

### Validation & Schema
- [JSON Schema Validation](https://json-schema.org/understanding-json-schema/) - Schema validation patterns
- [YAML Schema Validation](https://github.com/23andMe/Yamale) - YAML validation tools
- [ajv JSON Validator](https://ajv.js.org/) - Fast JSON schema validator
- [Configuration Validation Patterns](https://martinfowler.com/articles/domain-oriented-observability.html#ValidatingConfiguration) - Best practices

### Templating & Generation
- [Jinja2 Templates](https://jinja.palletsprojects.com/en/3.1.x/) - Powerful templating engine
- [Handlebars Templates](https://handlebarsjs.com/guide/) - Logic-less templates
- [envsubst](https://www.gnu.org/software/gettext/manual/html_node/envsubst-Invocation.html) - Environment variable substitution
- [yq](https://github.com/mikefarah/yq) - YAML/JSON/XML processor

### Configuration Management
- [12 Factor App - Config](https://12factor.net/config) - Configuration best practices
- [Environment-based Config](https://blog.heroku.com/twelve-factor-apps) - Multi-environment patterns
- [Feature Flags](https://martinfowler.com/articles/feature-toggles.html) - Configuration-driven features
- [Configuration as Code](https://octopus.com/blog/config-as-code-what-is-it-how-is-it-beneficial) - Version control for configs

### Security & Secrets
- [Secrets in Configuration](https://blog.gitguardian.com/secrets-api-management/) - Secure configuration patterns
- [SOPS](https://github.com/mozilla/sops) - Secrets management for config files
- [git-crypt](https://github.com/AGWA/git-crypt) - Transparent file encryption in git
- [Vault Configuration](https://www.vaultproject.io/docs/configuration) - HashiCorp Vault patterns

### Testing & Validation
- [Configuration Testing](https://semaphoreci.com/blog/test-configuration-files) - How to test config files
- [Schema-based Testing](https://json-schema.org/understanding-json-schema/reference/generic.html) - Validation-driven testing
- [Config Linting Tools](https://yamllint.readthedocs.io/en/stable/) - Automated config checking

### Documentation
- [Self-Documenting Config](https://github.com/kubernetes/community/blob/master/contributors/devel/sig-architecture/api-conventions.md#documentation) - Config documentation patterns
- [JSON Schema Annotations](https://json-schema.org/understanding-json-schema/reference/annotations.html) - Documenting schemas
- [Configuration Comments](https://stackoverflow.com/questions/2276572/putting-comments-in-json) - Best practices

## Usage Notes

**When to Add Knowledge:**
- New configuration pattern discovered → Add to patterns section
- Important config decision made → Record in decisions history
- Useful validation tool found → Add to external links
- Template pattern developed → Document in patterns
- Schema design created → Add to core concepts

**Knowledge Maintenance:**
- Update this index.md when adding/removing files
- Increment knowledge_count in frontmatter
- Update the `updated` date
- Keep knowledge focused on configuration management topics
- Link to official documentation rather than duplicating it

**Memory Philosophy:**
- **CLAUDE.md**: Quick reference for when to use configuration-specialist agent (always in context)
- **Knowledge Base**: Detailed config patterns, validation schemas, decision history (loaded when agent invokes)
- Both systems work together for efficient context management

## Knowledge Priorities

**High Priority Knowledge:**
1. YAML configuration patterns for AIDA personalities
2. Configuration validation and schema design
3. Template generation and variable substitution
4. Environment-specific configuration management
5. Secrets handling in configuration files

**Medium Priority Knowledge:**
1. Multi-format configuration (YAML/JSON/TOML) conversion
2. Configuration testing and validation strategies
3. Self-documenting configuration patterns
4. Configuration versioning and migration

**Low Priority Knowledge:**
1. Format-specific edge cases (document as encountered)
2. Advanced templating features (focus on common patterns)
3. Generic configuration concepts (focus on AIDA-specific needs)