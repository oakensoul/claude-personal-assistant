---
title: "Q&A Log - Issue #33"
description: "Questions and answers from expert analysis phase"
issue: "#33"
date: "2025-10-06"
---

# Q&A Log: Issue #33

Expert analysis Q&A session conducted during `/expert-analysis` workflow.

## Questions & Answers

### Q1: Dotfiles Fallback Utilities

**Question**: Should dotfiles bundle a fallback copy of installer-common utilities?

**Options**:
- A: Hard dependency (dotfiles requires AIDA pre-installed)
- B: Bundle fallback utilities (dotfiles can install standalone)
- C: Defer to v0.2.0

**Answer**: **A - Hard dependency**

**Rationale**: "There's really no reason to use my 'dotfiles' project if you're not using AIDA. There are lots of great options out there." - User decision aligns with recommended approach for v0.1.2 (simpler implementation, clear dependency model).

**Impact**:
- Dotfiles installer will require AIDA to be installed first
- Installation order: AIDA → dotfiles → dotfiles-private
- Clear error message if AIDA missing with installation instructions
- Can add fallback in v0.2.0 if needed

---

### Q2: realpath Requirement on macOS

**Question**: Should we require realpath (via Homebrew) or provide fallback?

**Options**:
- A: Require realpath (fail with clear error + brew install instructions)
- B: Python fallback (use Python's os.path.realpath)
- C: Pure Bash fallback

**Answer**: **A - Require realpath**

**Rationale**: "That's probably fine, but what about on Windows? My guess is that installing dotfiles, will have a list of required things that need to be installed when you install it or before you install it."

**Implementation**:
- Document realpath as prerequisite
- Fail with clear error message if missing
- Provide installation instructions:
  - macOS: `brew install coreutils`
  - Linux: `sudo apt-get install coreutils` (usually pre-installed)
- Windows: Not in scope for v0.1.2 (macOS/Linux primary platforms)

**Note**: User correctly identified that prerequisites should be documented. Future Windows support would be separate effort with its own prerequisites.

---

### Q3: Error Message Verbosity

**Question**: How verbose should error messages be?

**Options**:
- A: Generic to user, detailed to secure log file (~/.aida/logs/)
- B: Detailed to user (may expose system info)
- C: Minimal (just "Error occurred")

**Answer**: **A - Generic to user, detailed to logs**

**Rationale**: "This is fine, as long as we have it well documented where the logs are. Our users are going to be highly technical, so having access to the logs isn't something that is going to be a risk."

**Implementation**:
- User-facing messages: Generic, actionable (e.g., "Version mismatch. See logs for details.")
- Log file: Detailed error messages, stack traces, system info
- Log location: `~/.aida/logs/install.log` (permissions: 600)
- Documentation: README.md must clearly document log location
- Path scrubbing: Replace `/Users/username/` with `~/` in user-facing messages

**Documentation Requirements**:
- Add "Troubleshooting" section to lib/installer-common/README.md
- Document log location and format
- Provide examples of how to read logs for debugging

---

## Decisions Summary

All blocking questions resolved:

1. ✅ **Dotfiles dependency**: Hard dependency on AIDA (no fallback for v0.1.2)
2. ✅ **realpath requirement**: Required, document as prerequisite
3. ✅ **Error verbosity**: Generic to user, detailed to logs (document log location)

## Impact on Implementation

These decisions clarify:

- **Scope**: AIDA installer integration only (dotfiles requires AIDA)
- **Platform**: macOS/Linux (Windows deferred)
- **Prerequisites**: Document realpath requirement clearly
- **UX**: Clear error messages + detailed logs for troubleshooting
- **Testing**: Add "missing realpath" test scenario

## Next Steps

Proceed to Implementation Summary phase with all questions resolved.

---

**Session Date**: 2025-10-06
**Participants**: Product Manager (synthesized), Tech Lead (synthesized), User (oakensoul)
**Status**: Complete
