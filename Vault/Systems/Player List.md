---
description: Roblox-style top-right player list (leaderstats) showing Strength and Money, ranked by Strength; PlayerListService, PlayerListConfig
type: system
updated: 2026-10-28
---
Built 2026-10-28, not playtested. Separate from the global in-world [[Leaderboards]].

- `PlayerListService` (server) puts a `leaderstats` folder on each player when their data loads (again after a data reset) and removes it on leave. It holds one `NumberValue` per stat.
- Every `RefreshSeconds` (0.5) it copies `Strength` and `Cash` from player data (floored, never negative), writing only when the value changes.
- NumberValues, not StringValues (user, 2026-10-28): the Roblox player list ranks players by the first column, Strength, which it can't do with text. Roblox does its own number display, so there's no `$` and no game-style compact text.
- Columns, labels and order live in `PlayerListConfig.Stats` (first entry is the ranked column).
- The Rebirths column was removed 2026-11-09 with rebirth ([[Rebirth Removed]]).
- The intro cutscene hides the PlayerList CoreGui and restores it at the end.

**2026-11-12:** Strength and Money are StringValues written with `NumberFormat.Compact` (up to De, 1e33). Roblox's own number shortening ran out before the game's late values (user). Trade-off: the list sorts strings by text, so ranking by Strength may be off.
