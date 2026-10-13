---
description: Workspace.VFXShowcase - a stand with a dummy for every effect, replayed on a loop in Edit by the local VFXShowcase plugin, so effects can be viewed without Play.
type: reference
---
# VFX Showcase

Built 2026-10-08 because the user wanted to look at every effect without pressing Play.

- `Workspace.VFXShowcase` (tagged `EditorOnly`, so it never reaches players) sits outside the lobby's +X wall: row `Chop` at X 300 (rock dummies: Crack, Hit Good/Perfect, Break Bad/Good/Great, Perfect Burst, Master wind-up then burst, Rock Rise Dust), row `Player` at X 340 (R15 dummies: Level Up, Cash Pop, Hot Streak tiers 1 to 4, plus Board Break and Hatch Burst, then Aura Leaf, Wind, Thunder, Spirit, Dragon at Z -296 to -208). Stands face -X.
- The local plugin `VFXShowcase.lua` (source in `.claude/skills/vfx/plugin/`, installed in `%LOCALAPPDATA%\Roblox\Plugins\`) replays them; toolbar button "Loop VFX" toggles it and reloads templates and configs. It loads when Studio starts, not when the file is copied in.
- Spawned effects are `Archivable = false`, so saving the place never saves them.
- Physics doesn't run in Edit: coins and rock chunks only show in Play.
- New effect: add a stand (attributes in the `vfx` skill, "Showcase").

Related: [[Chop Effects]], [[Hot Streak]], [[VFX From Roqer]]
