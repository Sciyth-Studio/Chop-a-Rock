---
description: The project in this repo is "Chop a Rock", a Roblox game built on Frazer's roblox-game-boilerplate. Points to the design source of truth.
type: project
updated: 2026-10-02
---
`C:\Users\Admin\Documents\RobloxDev` is the Roblox game **Chop a Rock** (working title), built on top of `frrazer/roblox-game-boilerplate` (cloned 2026-09-26). Renamed in Rojo to `KarateChop` — the DataModel/place name and the Rojo project name may drift from the game's marketing name; do not "correct" one to match the other without asking.

The user's game studio is **Sciyth Studio** (GitHub org `Sciyth-Studio`). As of 2026-10-02 this game lives at `github.com/Sciyth-Studio/Chop-a-Rock` (`origin`); Frazer's boilerplate is kept as the `upstream` remote for pulling base updates.

Genre: simulator/RNG for ages 6–12. Core action: hold-and-release timing chop on tiered rocks. Two progression axes: **strength** (training + strict money-bought arm upgrades) and **luck** (improves hatch rarity of **pet rocks**, which hatch from geodes bought with money; equipped ones follow the player for boosts, the rest sit on base pedestals for offline income). Gems were removed entirely on 2026-09-30. One karate chop, big anime impact.

**Design source of truth:** [[Master Game Plan]] — always consult it before proposing player-facing decisions.

**Why:** the plan doc has strict rules (propose-and-wait for player-facing changes, whole-file output, no scope creep) that came from the user, not from this codebase. Silently building without checking would violate them.

**How to apply:** before proposing gameplay, progression, monetization, lore, systems, or UI decisions, read the plan doc and honor [PROPOSED]/[OPEN]/[TBD]/[PLAYTEST] tags. Never invent player-facing mechanics not in the doc; never build from [PROPOSED] items until the user approves. Follow [[Code Output Rules]] for how to produce code changes.
