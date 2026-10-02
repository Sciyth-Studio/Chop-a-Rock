---
description: How code changes are delivered on Chop a Rock — whole files, no comments, no scope creep, propose-and-wait for player-facing decisions.
type: preference
updated: 2026-09-27
---
1. **Whole files every time** — when editing a file, output/hand over the whole file rather than partial snippets. (The user's review workflow: they diff whole files.)
2. **Comments only when requested** — no explanatory comments in code. Matches the AGENTS.md rule too.
3. **No changes outside the requested scope** — even when outputting a whole file, do not tidy, refactor, or "improve" unrelated code. Only touch what the request covers.
4. **Propose-and-wait on anything player-facing** — new gameplay mechanics, progression tweaks, UI decisions, monetization, lore, or content decisions must be surfaced for approval before implementation. Internal implementation details (naming, structure inside a system) that follow AGENTS.md may be decided unilaterally.
5. **User reviews git diffs before committing** — keep diffs surgical and readable.

**Why:** these rules come from §04 "AI'S PURPOSE AND OBJECTIVE" of the [[Master Game Plan]]. The user reviews every diff manually and does not want scope-crept commits or unapproved gameplay changes.

**How to apply:** before writing code for a task, ask: is any part of this player-facing and not yet approved in the plan doc? If yes, propose first. Restrict changes to what the request explicitly asked for; if something adjacent looks wrong, flag it in chat instead of fixing it silently.
