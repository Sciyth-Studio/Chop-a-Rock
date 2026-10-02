---
description: The Chop a Rock design source-of-truth doc — where all gameplay/progression/monetization decisions live and where every design change is logged.
type: reference
updated: 2026-09-27
---
The master plan is `Chop_a_Rock_Master_Game_Plan.txt` at the repo root (outside the vault). It defines:

- Game vision, target audience, main selling point (§00)
- Core gameplay loop (§02)
- Visual direction (§03)
- Workflow, AI/user division of labor, output style, asset-handoff convention (§04)
- First-player experience (§05)
- World structure (§06)
- Progression, economy, rewards (§07)
- Core systems required (§08)
- UI / audio / feedback (§09)
- Scope, MVP definition, monetization, risks (§10)
- **Decision Log** at the end: every design change gets a dated entry. Claude updates it when the user resolves an [OPEN]/[TBD]/[PROPOSED] item.

Tags:
- `[PROPOSED]` — AI suggestion, not approved; do not build from it.
- `[OPEN]` — unanswered question; blocks dependent development.
- `[TBD]` — user deliberately deferred.
- `[PLAYTEST]` — build as a configurable value, tune through playtesting.

Precedence (the doc's FINAL AI INSTRUCTION): AGENTS.md wins for code standards; this doc wins for game design; on any conflict, surface it rather than silently choose. See [[Chop a Rock]], [[Code Output Rules]], [[Only Surface Blocking Opens]].
