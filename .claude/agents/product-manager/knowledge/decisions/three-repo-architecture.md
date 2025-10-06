---
title: "Three-Repo Architecture Decision"
category: "decisions"
tags: ["architecture", "privacy", "decision-record", "infrastructure"]
last_updated: "2025-10-04"
decision_date: "2025-10-04"
status: "decided"
---

# Decision: Three-Repo Architecture

## Context

AIDA is an open-source framework for building personal AI assistants. We needed to decide how to structure repositories to balance:

- **Shareability**: Framework should be public and shareable
- **Privacy**: User data and secrets should remain private
- **Flexibility**: Users should control their configurations
- **Collaboration**: Users should be able to contribute to framework

## Decision

**We chose a three-repository architecture**:

1. **`claude-personal-assistant`** (public) - Framework, templates, install scripts
2. **`dotfiles`** (public) - Generic shell configs and AIDA templates
3. **`dotfiles-private`** (private) - Secrets, API keys, company-specific configs

## Rationale

### Separation of Concerns

#### Framework vs Configuration vs Secrets

The three-repo split cleanly separates:

| Repo | Contains | Visibility | Changes |
|------|----------|------------|---------|
| claude-personal-assistant | AIDA framework code, agents, personalities, install scripts | Public | Infrequent (releases) |
| dotfiles | Shell configs (.zshrc), AIDA templates, public configs | Public | Occasional (new tools) |
| dotfiles-private | API keys, secrets, company configs, personal notes | Private | Frequent (daily work) |

**Why This Matters**:

- **Framework**: Can be shared openly, community contributions welcome
- **Dotfiles**: Can be shared as templates, help others set up similar environments
- **Dotfiles-Private**: Never accidentally exposed, safe to commit sensitive data

### Privacy by Design

#### Public Framework + Private Data

Users can:

- Fork and contribute to `claude-personal-assistant` (framework improvements)
- Share `dotfiles` as examples (help others)
- Keep `dotfiles-private` completely confidential

**Scenario**: User wants to share their AIDA setup with colleague

- ✅ Share `claude-personal-assistant` repo (framework code)
- ✅ Share `dotfiles` repo (shell config examples)
- ❌ Never share `dotfiles-private` (contains secrets)

**Privacy Guarantee**: No path from public repos to private data.

### Version Control Benefits

#### Different Update Cadence

| Repo | Update Frequency | Reason |
|------|-----------------|--------|
| claude-personal-assistant | Releases (weeks/months) | Framework updates, new features |
| dotfiles | Occasional (weeks) | New tools, config changes |
| dotfiles-private | Daily/frequent | Work projects, API keys, notes |

**Why Separate Repos**:

- Framework updates don't pollute private repo history
- Private work doesn't appear in framework commit log
- Can share framework git history without exposing private commits

### Installation Model

#### System-Level vs User-Level

```text
Framework (system-level):
  ~/.aida/                      # From claude-personal-assistant
  ├── agents/                   # Pre-built agents
  ├── personalities/            # Pre-built personalities
  ├── templates/                # Templates for user config
  └── scripts/                  # Install/update scripts

User Config (user-level):
  ~/.claude/                    # Generated from templates
  ├── config.yaml              # User configuration
  ├── personalities/           # User's custom personalities
  └── memory/                  # User's memory/data

Dotfiles (public templates):
  ~/dotfiles/                   # From dotfiles repo
  ├── .zshrc                   # Shell config
  ├── .config/                 # Tool configs
  └── aida/                    # AIDA config templates

Dotfiles Private (secrets):
  ~/dotfiles-private/          # From dotfiles-private repo
  ├── .env                     # API keys, secrets
  ├── work/                    # Work-specific configs
  └── personal/                # Personal notes/data
```

**Installation Flow**:

1. Clone `claude-personal-assistant` → run `./install.sh` → creates `~/.aida/`
2. (Optional) Clone `dotfiles` → run `stow` → symlinks to `~/`
3. (Private) Clone `dotfiles-private` → manual setup → keeps secrets secure

### GNU Stow Integration

#### Dotfiles Management

Using GNU Stow for dotfiles management:

```bash
# dotfiles repo structure:
dotfiles/
├── zsh/
│   └── .zshrc
├── vim/
│   └── .vimrc
├── aida/
│   └── .config/aida/templates/

# Stow creates symlinks:
cd ~/dotfiles
stow zsh    # Creates ~/.zshrc -> ~/dotfiles/zsh/.zshrc
stow vim    # Creates ~/.vimrc -> ~/dotfiles/vim/.vimrc
stow aida   # Creates ~/.config/aida/ -> ~/dotfiles/aida/.config/aida/
```text

**Why Stow**:

- Symlinks keep dotfiles in git repo (easy to version control)
- Can selectively enable configs (stow only what you need)
- Easy to share dotfiles without exposing private data
- Standard tool in Unix/Linux world

**Dotfiles vs Dotfiles-Private**:

- `dotfiles`: Stow-managed, symlinked, public
- `dotfiles-private`: Not stowed, direct files, private

## Alternatives Considered

### Alternative 1: Single Monorepo

**Approach**: Everything in one repository

- Framework code, user configs, secrets all in `claude-personal-assistant`
- Users fork repo and customize

**Pros**:

- Simpler: Only one repo to manage
- Easier for beginners (one clone, one setup)
- No cross-repo dependencies

**Cons**:

- **Cannot share**: Forking exposes your private data and secrets
- **Git pollution**: User's daily work commits mixed with framework code
- **No contribution path**: Can't contribute to framework without exposing personal data
- **Update conflicts**: Framework updates conflict with user customizations

**Why Rejected**: Privacy concerns, no way to share framework publicly

### Alternative 2: Two-Repo (Framework + Everything Else)

**Approach**: Split into framework and user configs

1. `claude-personal-assistant` (public) - Framework code
2. `aida-config` (private) - User configs, dotfiles, secrets, everything

**Pros**:

- Cleaner than monorepo (framework is shareable)
- Simpler than three repos (only two to manage)
- Clear separation: code vs config

**Cons**:

- **Public dotfiles**: Can't share generic dotfiles (mixed with secrets)
- **All or nothing**: Either share everything or nothing
- **No template dotfiles**: Users start from scratch on dotfiles

**Why Rejected**: Doesn't enable sharing generic dotfiles as templates

### Alternative 3: Four-Repo (Even More Separation)

**Approach**: Split further

1. `claude-core` - Core AIDA framework
2. `claude-agents` - Pre-built agents (separate from core)
3. `dotfiles` - Public dotfiles templates
4. `dotfiles-private` - Private configs and secrets

**Pros**:

- Maximum separation and flexibility
- Agents can be versioned independently
- Core framework stays minimal

**Cons**:

- **Over-engineered**: Too many repos to manage
- **Complex setup**: Users need to clone 4 repos and understand relationships
- **Unclear boundaries**: Where does agent go vs core?
- **Maintenance burden**: Coordinate releases across 4 repos

**Why Rejected**: Too complex for little benefit over three repos

### Alternative 4: Mono-Repo with Separate User Data Directory

**Approach**: Framework in repo, user data outside version control

1. `claude-personal-assistant` (public) - Framework + templates
2. `~/.aida/user/` - User data (not in any git repo)

**Pros**:

- Simple: Only one repo for framework
- Private by default: User data never in git
- No accidental commits of secrets

**Cons**:

- **No version control for user data**: Can't track config changes
- **No backup**: User loses data if machine crashes
- **No sync**: Can't sync configs across machines
- **No sharing**: Can't share dotfiles with others

**Why Rejected**: Users want to version control their configs and dotfiles

## Implementation Details

### Directory Structure

**Framework Installation** (`~/.aida/`):

```

~/.aida/                         # Installed from claude-personal-assistant
├── agents/                      # Pre-built agents
│   ├── dev-assistant.md
│   ├── secretary.md
│   └── file-manager.md
├── personalities/               # Pre-built personalities
│   ├── jarvis.yaml
│   ├── alfred.yaml
│   └── friday.yaml
├── templates/                   # Templates for user config
│   ├── knowledge/
│   ├── workflows/
│   └── config.yaml.template
└── bin/                        # AIDA CLI scripts
    ├── aida
    └── install.sh

```text

**User Configuration** (`~/.claude/`):

```

~/.claude/                       # Generated during installation
├── config.yaml                 # User's AIDA config
├── personalities/              # User's custom personalities
│   └── my-custom.yaml
├── memory/                     # User's memory/data
│   ├── conversations/
│   ├── tasks/
│   └── decisions/
└── agents/                     # User's custom agents
    └── kubernetes-expert.md

```text

**Public Dotfiles** (`~/dotfiles/`):

```

~/dotfiles/                      # Stow-managed, public repo
├── zsh/
│   └── .zshrc
├── vim/
│   └── .vimrc
├── git/
│   └── .gitconfig
└── aida/
    └── .config/aida/
        └── templates/          # AIDA config templates

```text

**Private Dotfiles** (`~/dotfiles-private/`):

```

~/dotfiles-private/              # Private repo, NOT stowed
├── .env                        # API keys, secrets
├── work/                       # Work-specific configs
│   ├── company-a/
│   └── company-b/
└── personal/                   # Personal notes
    ├── journal/
    └── projects/

```text

### Repository Responsibilities

#### claude-personal-assistant (Public Framework)

**Contains**:

- AIDA framework code (bash scripts, CLI)
- Pre-built agents (dev-assistant, secretary, file-manager)
- Pre-built personalities (JARVIS, Alfred, FRIDAY, Sage, Drill Sergeant)
- Installation scripts (`install.sh`, `update.sh`)
- Templates for user configuration
- Documentation (README, guides, tutorials)

**Update Frequency**: Releases (0.1.0, 0.2.0, etc.)

**Contributors**: Open to community contributions

**Installation**: `git clone` + `./install.sh` → installs to `~/.aida/`

#### dotfiles (Public Templates)

**Contains**:

- Shell configs (.zshrc, .bashrc) - generic, shareable
- Tool configs (.vimrc, .tmuxconf) - personal but public
- Git config (.gitconfig) - public template (no credentials)
- AIDA config templates - examples for others
- Homebrew bundle (Brewfile) - tools I use

**Update Frequency**: Occasional (new tools, config tweaks)

**Contributors**: Personal repo, but others can fork as template

**Installation**: `git clone` + `stow` → symlinks to `~/`

#### dotfiles-private (Private Secrets)

**Contains**:

- API keys and secrets (.env files)
- Work-specific configs (company-specific settings)
- Personal notes and journal (not for sharing)
- Private AIDA memory/data (proprietary work)
- SSH keys, GPG keys, credentials

**Update Frequency**: Daily/frequent (active work)

**Contributors**: Only me (private repo)

**Installation**: `git clone` (private repo, manual setup)

### Cross-Repo Relationships

**Dependencies**:

```

claude-personal-assistant (standalone, no dependencies)
  ↓ (installs framework to ~/.aida/)

dotfiles (optional, enhances shell experience)
  ↓ (provides AIDA config templates)

dotfiles-private (optional, for secrets and private data)
  ↓ (referenced by AIDA for API keys)

```text

**Installation Order**:

1. **Required**: `claude-personal-assistant` (installs AIDA framework)
2. **Optional**: `dotfiles` (enhances shell, provides templates)
3. **Optional**: `dotfiles-private` (adds secrets and private configs)

**Why This Order**:

- AIDA works without dotfiles (standalone)
- Dotfiles work without dotfiles-private (public configs)
- Dotfiles-private referenced last (secrets loaded at runtime)

### Development Mode

**Dev Mode Workflow** (for framework contributors):

```bash
# Clone framework repo to development directory
cd ~/Developer/
git clone git@github.com:oakensoul/claude-personal-assistant.git

# Install in dev mode (creates symlinks)
cd claude-personal-assistant
./install.sh --dev

# Now ~/.aida/ is symlinked to ~/Developer/claude-personal-assistant/
# Changes to source files immediately reflect in installed version
```

**Why Symlinks**:

- Edit source files in `~/Developer/claude-personal-assistant/`
- Changes immediately available in `~/.aida/`
- No need to reinstall after each change
- Can test and iterate quickly

**User Data Unaffected**:

- `~/.claude/` still contains user data (not symlinked)
- User can switch between dev and production modes
- No risk of losing user data during development

## Benefits Realized

### Privacy & Security

**Clear Boundaries**:

- Public repos: No secrets ever
- Private repo: Confidential data never exposed
- Framework: Safe to share, fork, contribute

**Example Scenario**: Contributing to AIDA

1. Fork `claude-personal-assistant` on GitHub
2. Make changes to framework code
3. Submit pull request
4. **No risk**: Your private data is in separate repo, never exposed

### Shareability

**Framework**:

- ✅ Can share framework repo publicly
- ✅ Others can use as template
- ✅ Community can contribute improvements

**Dotfiles**:

- ✅ Can share dotfiles as examples
- ✅ Others can fork and adapt
- ✅ Showcases configuration patterns

**Private Data**:

- ❌ Never shared (by design)
- ✅ Version controlled (for backup)
- ✅ Synced across user's devices (private repo)

### Collaboration

**Open Source Framework**:

- Community can submit agents
- Community can submit personalities
- Community can improve install scripts
- No privacy concerns (framework has no user data)

**Template Dotfiles**:

- Users can share dotfiles as inspiration
- "Check out my AIDA setup" (share dotfiles repo)
- Helps others configure their environments

### Maintainability

**Framework Updates**:

- Release new version of `claude-personal-assistant`
- Users run `aida update`
- Framework updates without touching user data

**Dotfiles Evolution**:

- Add new tools to `dotfiles`
- Commit and push
- Other machines pull changes
- Symlinks automatically reflect updates

**Private Data Sync**:

- Work on machine A, commit to `dotfiles-private`
- Pull on machine B
- Private data synced securely

## Trade-offs Accepted

### Complexity

**More Repos = More Complexity**:

- Users need to understand three repos
- Setup requires multiple clone commands
- Dependencies between repos must be documented

**Mitigation**:

- Install script handles most complexity
- Clear documentation of repo purposes
- Installation is mostly automated

### Initial Setup Time

**More Steps**:

- Clone framework repo
- Run install script
- (Optional) Clone dotfiles repo
- (Optional) Clone dotfiles-private repo

**Mitigation**:

- Most users only need framework (others optional)
- Install script automates framework setup
- Documentation provides clear steps

### Coordination

**Keeping Repos in Sync**:

- Framework changes may require dotfiles updates
- Dotfiles templates should match framework expectations

**Mitigation**:

- Framework is self-contained (doesn't require dotfiles)
- Dotfiles are optional enhancements
- Version framework explicitly (0.1.0, 0.2.0)

## Success Metrics

Validating this decision:

**Privacy**:

- Zero accidental secret exposures
- Users report confidence in sharing framework
- No reports of private data leaks

**Adoption**:

- Users successfully set up AIDA from public repo
- Community forks and contributes to framework
- Users share dotfiles as templates

**Contribution**:

- Pull requests to framework (no privacy concerns)
- Community agents and personalities contributed
- Framework improvements from community

**Maintainability**:

- Framework updates don't break user configs
- Clear separation enables independent versioning
- Users can upgrade framework without risk

## Future Considerations

### Potential Fourth Repo: Community Contributions

**If community growth happens**:

- `aida-community` repo for community agents/personalities
- Curated contributions, reviewed and tested
- Users can opt-in to community extensions

**Why Not Now**:

- Premature (no community yet)
- Can add later if needed
- Community can contribute to main repo for now

### Dotfiles Monorepo Alternative

**If Stow becomes limiting**:

- Consider monorepo with Stow packages: `dotfiles/packages/zsh/`, `dotfiles/packages/vim/`
- Or tool like chezmoi (more powerful than Stow)
- Or Nix home-manager (declarative configs)

**Why Not Now**:

- Stow works well for current needs
- Simpler is better for v1.0
- Can migrate later if needed

### Framework Plugins Repository

**If plugin ecosystem grows**:

- `aida-plugins` repo for official plugins
- Separate from community plugins
- Versioned and supported

**Why Not Now**:

- No plugin system yet (planned for 0.5.0)
- Cross that bridge when we get there

## Related Decisions

- **Privacy**: See `/Users/oakensoul/Developer/oakensoul/claude-personal-assistant/.claude/agents/product-manager/knowledge/core-concepts/design-principles.md` (privacy principle)
- **Installation**: See roadmap 0.1.0 milestone (install.sh implementation)
- **Naming**: See `/Users/oakensoul/Developer/oakensoul/claude-personal-assistant/.claude/agents/product-manager/knowledge/decisions/naming-decisions.md` (directory naming)

## Conclusion

Three-repo architecture provides:

- **Privacy**: Clear separation between public framework and private data
- **Shareability**: Framework and dotfiles can be shared openly
- **Flexibility**: Users control their configurations
- **Collaboration**: Community can contribute without privacy concerns
- **Maintainability**: Independent versioning and updates

The complexity of managing three repos is justified by privacy and shareability benefits.

**Status**: ✅ Decided and implemented in repository structure
