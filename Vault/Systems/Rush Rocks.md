---
description: Rush Rocks (built 2026-10-09) - after ~3 min of chopping the next respawned rock rises gold near the player with a 20 s countdown and pays x3; how it is timed, picked, shown and tested.
type: system
---
# Rush Rocks

Approved 2026-10-09 as proposed. All numbers are drafts in `RushRockConfig`.

## Rules
- **Timer:** only chopping time counts. Each chop adds the gap since the previous chop if that gap was 8 s or less (`ActiveWindowSeconds`). At 180 s (`IntervalSeconds`) a rush is due. The timer pauses while a rush is scheduled or out, and resets when one spawns.
- **Which rock:** the next rock retired (broken) while a rush is due respawns gold, in that rock's zone. Kind is the one the mix wants if the player can break it, otherwise the strongest breakable kind in the zone. If nothing is breakable it spawns normal and stays due.
- **Where:** random free spot within 60 studs of the player (`SpawnRadiusStuds`), else the nearest free spot.
- **Countdown:** 20 s from when it finishes rising. If the player is mid-chop on it at 0, the server rechecks every 0.5 s and keeps the x3 until that session ends. Then the rock turns normal and stays in the mix.
- **Pay:** `Rush.ApplyPayout` multiplies the chop payout x3 before Hot Streak, friend, rebirth and Index multipliers, so they stack.

## Where things live
- Server: `RockService/Rush.luau` (timer, kind pick, payout) and the wiring in `RockService/init.luau` (`rushStates`, `expireRush`, `spawnRock(..., isRush)`). `Rock.Modifier = "Rush"` goes out in `RockSpawned`; `RockRushEnded(id)` says it timed out. `Spawner.PickSpotNear` picks the spot.
- Client: `RockController/Rush.luau` paints the part gold, adds the `RushOutline` Highlight, moves the `VFX_Rush_Glow` emitters onto the part (Box surface sparkles), plays `VFX_Rush_Pillar` and `SFX_Rush_Chime`, and runs the `RushCountdown` billboard ("Rush! 20", red with a pulse and `SFX_Rush_Tick` for the last 5 s). It sets the part attribute `RushEndsAt`. The old guide arrow (`ArrowTrail`) that pointed at it was removed 2026-10-16.
- Studio assets in `ReplicatedStorage.Assets`: `VFX/RushCountdown` (a copy of `CashPopText` plus a UIScale), `VFX/VFX_Rush_Glow`, `VFX_Rush_Pillar`, `VFX_Rush_Burst` (reuse the cash pop's uploaded glint textures), `Sounds/SFX_Rush_Chime` (level-up sound sped up) and `SFX_Rush_Tick` (notification sound sped up) as placeholders. Showcase stands "Rush Pillar" and "Rush Burst" in [[VFX Showcase]].
- Admin: "Next Rock: Rush" (Ctrl+Shift+R) fills the timer, so the next rock you break comes back gold.

## Tested 2026-10-09
Playtest: forced rush, broke a Stone, a gold Stone rose with the countdown and outline; it timed out back to normal. A second one broken with a Perfect paid 210 against 70 on a normal Stone. No client or server errors. The countdown billboard was checked by values only (billboards don't show in `screen_capture`).

Related: [[Rock Spawning]], [[Hot Streak]], [[Chop Effects]]
