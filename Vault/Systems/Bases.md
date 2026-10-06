---
description: Six base plots spawned at runtime from BaseSpot marker parts in a U around the lobby shops; claim on join, per-base spawn and owner-only training stand (built 2026-10-06).
type: system
---
# Bases

The user asked (2026-10-06) for 6 bases in a horseshoe on `LobbyFloor`, placed from parts rather than by hand, the three shops moved to the middle in a row, an owner-only wood training stand outside each base and a spawn point per base.

## Layout (Studio)
- `Workspace.BaseSpots` holds `BaseSpot1`–`BaseSpot6` (tag `BaseSpot`): 90 x 0.2 x 90 yellow half-transparent plates, no collide/touch/query. The plot's pivot goes at the plate's **bottom centre**, and the plate's **front face (LookVector) is the base entrance**. To move a base, move its plate. Spots are claimed in name order (`BasePlot1` first).
- A true circular horseshoe doesn't fit: six 90-stud plots on the 340-stud floor overlap at every radius that stays on the floor. So it's a U. Relative to the floor centre (42, -364.86): sides at x = ±124 (z = 78 and -22) facing inward, back pair at x = ±50, z = -122 facing +Z. Gaps are 10 studs and the outer edges are 1 stud from the floor edge. The open end faces the forest (+Z).
- Shops (`ArmShop`, `GeodeShop`, `SellShop`) sit in a row at x 26 / 42 / 58, z -354.06, still facing +Z (toward the forest). The stray `Workspace.Berry` mesh by the geode shop moved with them.
- Removed from Workspace: the hand-placed `BasePlot`, the lobby `TrainingStand` and the lobby `SpawnLocation`.

## Template
`ReplicatedStorage.Assets.Models.Model_BasePlot` now also holds (plot-local, entrance = local -Z):
- `TrainingStand` (the old lobby stand, with its "Wood Training" sign) at (22, 0, -53), front facing away from the base.
- `BaseSpawn` (copy of the old invisible, non-colliding SpawnLocation, Duration 0) at (0, 0.5, -54), facing into the base.

## Server
- `BaseService` clones the template onto every `BaseSpot` into `Workspace.BasePlots` in `Start`, and hides the plates. On claim it sets `player.RespawnLocation` to the plot's `BaseSpawn` and moves the current character there (the first character can spawn at any base before data loads).
- `TrainingService`: a board inside a `BasePlot`-tagged model only works for that plot's owner (checked on trigger and every tick). Its prompt gets the `OwnedPrompt` tag, `Active` = true and an `OwnerUserId` that follows the plot's, so other players don't see it. Boards outside plots stay public. Boards outside Workspace (the template) are skipped.

Related: [[Base Plot Reference]], [[Pedestals]], [[Training Stand Reference]], [[Shop Pads]]
