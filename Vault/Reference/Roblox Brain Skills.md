---
description: Four general Roblox skills copied from the MIT roblox-brain repo (2026-11-13) into .claude/skills; what they add and which project skills override them
type: reference
---
# Roblox Brain Skills

Source: `https://github.com/tabooharmony/roblox-brain` (MIT, v2.3.1, skills last reviewed 2026-10-14). On 2026-11-13 four of its 29 skills were copied into `.claude/skills/`, each with its `references/full.md`. The other 25 were skipped because they mostly repeat Roblox knowledge Claude already has.

- `roblox-monetization`: newer APIs from after Claude's training cutoff: Robux transfers (`PromptRobuxTransferAsync`), managed pricing and `GetUsersPriceLevelsAsync`, and subscriptions (`Players.UserSubscriptionStatusChanged` with `GetUserSubscriptionStatusAsync`).
- `roblox-gui`: layout on phones, tablets, TVs and controllers: safe areas, `ViewportDisplaySize`, and gamepad focus. `studio-ui` and the UI preferences in this vault take precedence; a note at the top of the skill says so.
- `roblox-input`: `Enum.PreferredInput`, touch action buttons, gamepad tool activation, and button hints for each platform.
- `roblox-studio-mcp`: MCP reliability habits (silent failures, truncated script reads, the ground-truth rule, editing the wrong place) and how to diagnose asset privacy. `studio-playtest` and [[User Playtests Changes]] take precedence; a note at the top of the skill says so.

To update a skill, copy it again from the repo and add the precedence note back to `roblox-gui` and `roblox-studio-mcp`.
