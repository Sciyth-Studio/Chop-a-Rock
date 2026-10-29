---
description: Roblox-style top-right player list (leaderstats) showing Strength, Money and Rebirths, ranked by Strength; PlayerListService, PlayerListConfig
type: system
updated: 2026-10-28
---
Built 2026-10-28, not playtested. Separate from the global in-world [[Leaderboards]].

- `PlayerListService` (server) puts a `leaderstats` folder on each player when their data loads (again after a data reset) and removes it on leave. It holds one `NumberValue` per stat.
- Every `RefreshSeconds` (0.5) it copies `Strength`, `Cash` and `Rebirths` from player data (floored, never negative), writing only when the value changes.
- NumberValues, not StringValues (user, 2026-10-28): the Roblox player list ranks players by the first column, Strength, which it can't do with text. Roblox does its own number display, so there's no `$` and no game-style compact text.
- Columns, labels and order live in `PlayerListConfig.Stats` (first entry is the ranked column).
- The intro cutscene hides the PlayerList CoreGui and restores it at the end.
