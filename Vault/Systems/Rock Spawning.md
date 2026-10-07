---
description: Per-player rocks rise at random clear spots inside RockSpawnArea boxes (built 2026-10-06); server keeps data only, the client draws the rocks and effects.
type: system
---
# Rock spawning

Built 2026-10-06 from `RockSpawnSystemPlan.md` (all of D1–D10 approved as written).

## Studio
- **Spawn area:** parts tagged `RockSpawnArea` with a `Zone` attribute (`"Forest"`), half-transparent blue in Studio, hidden by the server at start. The forest box is `Forest Zone.RockSpawnArea`, 216 x 30 x 116 at (42, 13, -135), covering the floor between the side terraces. To change where rocks go, move or resize it, or add more boxes with the same tag and attribute.
- **Templates:** the three hand-placed rocks became `ReplicatedStorage.Assets.Models.Model_Rock_Basic/Second/Third` (MeshParts that keep their `RockKey`, `SplitModel`, MaterialVariant and rotation; no `ChopRock` tag on the template). `Workspace.Rocks` was removed. Rocks spawn with the template's rotation, so the chop camera framing stays as tuned.
- **Dust:** `Assets.VFX.VFX_Rock_Dust` is a placeholder smoke burst (`EmitCount` attribute) for the rise. Hit and break effects are in [[Chop Effects]]. `SFX_Rock_Rise` (rumble) is still missing, so the rise is silent and the client warns once.

## How it works
- `RockService` samples the areas at server start (about 1,280 forest spots in ~100 ms). For each 4-stud column it raycasts down through everything collidable and takes the lowest surface, then steps up through anything stacked within 1.5 studs (`GroundStepStuds`). It then checks each rock kind's box and a 3 x 5 x 3 standing spot where the chop snaps the player. Only collidable parts block.
- Each player's rocks are data on the server (id, kind, CFrame). The mix is fixed by the zone weights: each new rock is the kind furthest below its share of `RockCount` (forest: always 5 Stone / 3 Boulder / 2 Mossy), so a broken rock comes back as the same kind at a new spot. Ties pick at random. They're created when that client sends `RockReady`, replaced 2s after a break (Master: after the wind-up too), and sent only to that player (`RockSpawned`). `RockChop(id)` starts a chop; the server checks ownership, rise time and range.
- `RockController` (client) builds the part from the template, rises it, adds the prompt, and tags it `ChopRock` once it's up, so `RockLabels` and the guide arrow pick it up. Hit, crack, break and Master effects moved here from the server (`RockController/Effects`). Rock prompts are off while any chop minigame is open (`ChopController.ActiveChanged`).
- Other players within 150 studs get `RockChopShown` with dust, sound and a small grey chunk spray, but no rock.
- Admin "Spawn Spots" (Ctrl+Shift+K) shows every spot as a dot coloured by the biggest rock that fits: grey Stone, blue Boulder, green Mossy.
- Values live in `RockSpawnConfig`. The chopped-rock timings stay in `RockConfig` (`RespawnSeconds` is now just how long the pieces stay).

## Gotchas
- `Forest Zone.ZoneTemplate.Floor` is rotated 90°, so the forest runs along X (floor x -68..152, z -195..-75), not along Z as the model's bounding box suggests. Past z -75 is bare Baseplate with no wall.
- The floor sits on the Baseplate. Taking the plain lowest surface put every rock on the Baseplate, inside the floor. That's why the ground search steps up through stacked surfaces.

Related: [[Forest Rock Tiers]], [[Admin Panel]], [[Index]]
