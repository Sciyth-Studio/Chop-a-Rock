---
description: One lobby Geode Shop sells every zone's geode through zone tabs; it opens on the best geode the player's strength qualifies for. Adding a zone geode = config only.
type: system
---
# Geode Shop

Decided 2026-10-14 (user): geodes are bought from the one lobby Geode Shop, with a tab per zone like the [[Index]], not from a stand in each zone. It opens on the highest zone whose geode `StrengthRequired` the player meets (Forest below that).

- GUI: `StarterGui.GeodeStand.Panel`, widened to 944 for a `Tabs` column on the left (copied from the Index tabs; `TabTemplate` with `Label` = zone, `Count` = "<n> Strength"). The grid and buy buttons moved 92 px right; `GeodeStandConfig.ButtonCenterOffsetPixels` keeps the buy buttons centred under the grid. Active tab Sky blue, idle grey (`GeodeStandConfig.Palette.TabActive/TabIdle`).
- Code: `GeodeStand.luau` builds one tab per geode in `Order`; `Open` ignores the pad's `ScreenKey` and picks `GeodeOrder.ForStrength`. Tabs for zones the player can't reach still show the odds, with the "Need X Strength" blocker.
- `Utils/GeodeOrder`: `Sorted()` (by `Order`) and `ForStrength(strength)`. Admin "Grant Rok" and "+1 Geode" use the same pick, so they follow the player's strength.
- Adding a zone: `PetConfig` Roks, a `GeodeConfig.Geodes.<Zone>` entry with `TabName` and `Order`, the geode models, and the `IndexConfig` Roks zone. No new stand.
- Desert (2026-10-14): Desert Geode $40,000, 2,500 Strength, `Model_Geode_Desert` / `Model_GeodeSplit_Desert` (the Basic models with the shell 220, 140, 40; crystals unchanged). Odds 57.5 / 25 / 11 / 5 / 1.35 / 0.15 (Claude's draft between forest and jungle; the shop shows Ankhy as 1.4%). Income forest x80.
- Tested in Play 2026-10-14: opens on Forest at 100 Strength and on Desert at 3,000; tab switch, blocker, buying a Desert Geode, and admin grants rolling desert Roks onto pedestals all work. A real crack of a Desert Geode was not played through.
- Crack order (user, 2026-10-14): a player holding several geode kinds cracks the highest-zone one first (`Cracking.PickGeode` walks `GeodeOrder.Sorted()` from the top).

Related: [[Index]], [[Pedestals]], [[Zones After Desert]], [[Desert Rok Sheets]]

- Jungle (2026-10-16): Jungle Geode $2,560,000, 312,500 Strength, Order 3, `Model_Geode_Jungle` / `Model_GeodeSplit_Jungle` (Desert models copied, shell 235, 35, 130 to match the jungle Roks; crystals unchanged). Odds 55 / 25 / 12 / 6 / 1.8 / 0.2 from [[Zones After Desert]]. User approved the numbers and colour 2026-10-16; the user playtests it.
- Ocean (2026-10-19): Ocean Geode $491,520,000 (was $163,840,000 until 2026-10-19, see [[Balance Pass Oct 18]]), 39,062,500 Strength, Order 4, `Model_Geode_Ocean` / `Model_GeodeSplit_Ocean` (Jungle models copied, shell coral orange 255, 95, 70 to match the ocean Roks; crystals unchanged). Odds 50 / 25 / 14 / 8 / 2.6 / 0.4 for Drip / Bubbly / Shelly / Reefy / Glowy / Chompy from [[Zones After Desert]]. Tested in Play 2026-10-19: at 40M Strength the admin pick is Ocean, buying three works, a real crack hatched Bubbly onto a pedestal and a forced Secret hatched Chompy; both show as found in the Index's Ocean section. Shell colour checked by value only; the place needs saving for the new geode models.
- Snow (2026-10-20): Snow Geode $36,700,160,000 (x3.5, [[Balance Pass Oct 18]]), 976,562,500 Strength (SnowFirst, the weakest snow rock), Order 5, `Model_Geode_Snow` / `Model_GeodeSplit_Snow` (Ocean models copied in Studio, shell frost blue 40, 150, 255 to match the snow Roks; crystals unchanged). Odds 45 / 25 / 16 / 10 / 3.5 / 0.5 for Hexy / Beanie / Cozy / Stacky / Climby / Starry from [[Zones After Desert]]. Not playtested; the place needs saving for the new geode models.
