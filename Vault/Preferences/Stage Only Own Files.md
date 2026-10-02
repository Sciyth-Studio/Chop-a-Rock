---
description: Other Claude sessions edit this repo concurrently; when committing, stage only the files this session changed, never `git add src` or `-A`.
type: preference
updated: 2026-09-30
---
When committing, stage files by explicit path — only those this session changed. Check `git status` first and leave anything unfamiliar alone.

**Why:** on 2026-09-30 a `git add src` swept another session's uncommitted menu-button work (MenuButtons.luau, IconConfig, MenuButtonConfig, UIController/init.luau) into the wrong commit; those came from a different session running in parallel.

**How to apply:** before every commit, list the files changed this session and `git add` them individually. If unexpected modified/untracked files appear, don't stage them and don't flag them unless they block the commit. Relates to [[Code Output Rules]].
