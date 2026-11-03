---
description: 2026-11-03 replacement for Rush Rocks; any rock has a draft 2% chance to spawn gold and pays x3; no timer or countdown.
type: system
---
# Golden Rocks

The user removed Rush Rocks on 2026-11-03 because they barely happened, and replaced them with a chance for golden rocks to spawn.

- Each normal spawn rolls `GoldenRockConfig.Chance` (2%, draft) and pays `PayoutMultiplier` (x3, draft, same as Rush). Never during the tutorial or for forced spawns.
- The server sets `Modifier = "Golden"`; `RockController/Golden` paints the rock gold with an outline and glow, and plays the burst and chime on break. `ChopController` shows the gold cash pop.
- Admin: Next Rock: Golden (Ctrl+Shift+R, alias `golden`). Analytics source `GoldenRock`.
- It reuses the Rush templates `VFX_Rush_Glow`, `VFX_Rush_Burst`, `SFX_Rush_Chime`. `RushCountdown`, `VFX_Rush_Pillar` and `SFX_Rush_Tick` are unused in Studio now.

Related: [[Chop Effects]], [[Rock Spawning]]
