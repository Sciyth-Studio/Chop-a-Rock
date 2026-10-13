---
description: Eight base plots (six until 2026-10-10) spawned at runtime from BaseSpot marker parts in a U around the lobby shops; claim on join, per-base spawn and owner-only training stand (built 2026-10-06).
type: system
---
# Bases

The user asked (2026-10-06) for 6 bases in a horseshoe on `LobbyFloor`, placed from parts rather than by hand, the three shops moved to the middle in a row, an owner-only wood training stand outside each base and a spawn point per base.

## Layout (Studio)
- `Workspace.BaseSpots` holds `BaseSpot1`–`BaseSpot6` (tag `BaseSpot`): 90 x 0.2 x 90 yellow half-transparent plates, no collide/touch/query. The plot's pivot goes at the plate's **bottom centre**, and the plate's **front face (LookVector) is the base entrance**. To move a base, move its plate. Spots are claimed in name order (`BasePlot1` first).
- A true circular horseshoe doesn't fit: six 90-stud plots on the 340-stud floor overlap at every radius that stays on the floor. So it's a U. Relative to the floor centre (42, -364.86): sides at x = ±124 (z = 78 and -22) facing inward, back pair at x = ±50, z = -122 facing +Z. Gaps are 10 studs and the outer edges are 1 stud from the floor edge. The open end faces the forest (+Z).
- Shops (`ArmShop`, `GeodeShop`, `SellShop`) sit in a row at x 18 / 34 / 50 / 66 (`AuraShop` is the fourth; recentred on the floor centre x 42 on 2026-10-10), z -354.06, still facing +Z (toward the forest). The stray `Workspace.Berry` mesh by the geode shop moved with them.
- Removed from Workspace: the hand-placed `BasePlot`, the lobby `TrainingStand` and the lobby `SpawnLocation`.

## Template
`ReplicatedStorage.Assets.Models.Model_BasePlot` now also holds (plot-local, entrance = local -Z):
- `TrainingStand` (the old lobby stand, with its "Wood Training" sign) at (22, 0, -53), front facing away from the base.
- `BaseSpawn` (copy of the old invisible, non-colliding SpawnLocation, Duration 0) at (0, 0.5, -54), facing into the base.

## Server
- `BaseService` clones the template onto every `BaseSpot` into `Workspace.BasePlots` in `Start`, and hides the plates. On claim it sets `player.RespawnLocation` to the plot's `BaseSpawn` and moves the current character there (the first character can spawn at any base before data loads).
- `TrainingService`: a board inside a `BasePlot`-tagged model only works for that plot's owner (checked on trigger and every tick). Its prompt gets the `OwnedPrompt` tag, `Active` = true and an `OwnerUserId` that follows the plot's, so other players don't see it. Boards outside plots stay public. Boards outside Workspace (the template) are skipped.

Related: [[Base Plot Reference]], [[Pedestals]], [[Training Stand Reference]], [[Shop Pads]]

## Remodel in Studio (2026-10-10)
- `Model_BasePlot` was rebuilt on the 64 x 64 remodel ([[Base Plot Reference]]), uploaded through Open Cloud (asset 84516811219303) and loaded with `InsertService`. Parts and colours: `BasePlot_Floor` 20,20,20 `2022 Stud`; `_Stone` 128 grey, `_Trim` white and `_Crack` 90 grey, all `2022 Inlet`. Floor, stone and trim use PreciseConvexDecomposition collision, the crack Hull. The PrimaryPart is the floor, pivot at bottom centre, and the entrance is local -Z as before.
- The top surface is at y 2.4. `Pedestal1`-`4` sit at x +21 and `5`-`8` at x -21, at z -19.5, -6.5, 6.5, 19.5 (pivot y 2.7). Pads face inward, centre x ±12.75. `GeodeSpot` is 0.3 above the crack centre in the centred pit. `TrainingStand` is at (22, 0, -37) and `BaseSpawn` at (0, 0.5, -38), just outside the front edge (-32).
- **8 spots (2026-10-10, user asked):** `BaseSpot1`-`8`, 64 x 64, in a U with 3 per side and 2 at the back. Left side x -95 facing +X, at z -235.34 / -336.34 / -437.34 (`1`-`3`). Back z -501.86 facing +Z, at x 2 / 82 (`4`, `5`). Right side x 179 facing -X, at z -437.34 / -336.34 / -235.34 (`6`-`8`). Outer edges are 1 stud from the side walls, and the back pair has a 16-stud gap. The user placed the side columns by hand (2026-10-10). The plots are 37 studs apart, about 8.5 studs from the forest edge, and the last side plot's rear edge (z -469.34) lines up with the back pair's front edge (-469.86). So the side columns end where the back row starts, and no plot sits beside the back pair. Take this as the model for "balanced, no views blocked": even gaps between plots, and corners left open rather than evenly spaced to the walls (Claude's equal-gaps-to-walls version still boxed the back corners in; packing them at the forest edge was an overcorrection). The forest gateway (x -7 to 91) sits between the columns. Checked for overlaps against everything on the lobby floor. **Server size must be 8** (Game Settings > Places > Max Players; it was 60): a 9th player gets no base, and `BaseService` only warns.
- The old template is kept as `ServerStorage.Model_BasePlot_Old`. Delete it once the new one is signed off.
- In the lobby lighting the black reads navy and the grey reads light blue ([[Why The Game Looks Blue]]). The part colours are left literal per [[Literal Black And Grey]]; whether to adjust the lighting is the user's call.
