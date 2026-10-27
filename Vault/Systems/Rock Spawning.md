---
description: Per-player rocks rise at random clear spots inside RockSpawnArea boxes (built 2026-10-06); server keeps data only, the client draws the rocks and effects.
type: system
---
# Rock spawning

Built 2026-10-06 from `RockSpawnSystemPlan.md` (all of D1–D10 approved as written).

## Studio
- **Spawn area:** parts tagged `RockSpawnArea` with a `Zone` attribute (`"Forest"`), half-transparent blue in Studio, hidden by the server at start. The forest box is `Forest Zone.RockSpawnArea`, 216 x 30 x 164 at (42, 13, -111) (116 deep at z -135 until the zones went 1.4x longer on 2026-10-16, see [[Zone Line]]), covering the floor between the side terraces. To change where rocks go, move or resize it, or add more boxes with the same tag and attribute.
- **Templates:** the three hand-placed rocks became `ReplicatedStorage.Assets.Models.Model_Rock_Basic/Second/Third` (MeshParts that keep their `RockKey`, `SplitModel`, MaterialVariant and rotation; no `ChopRock` tag on the template). `Workspace.Rocks` was removed. Since 2026-10-24 every rock gets a random yaw (0-360°) on top of the template's rotation, so they no longer all face one way. The server picks it and sends it in `RockSpawned`. The chop camera and stand spot use world (or approach) offsets, so they don't turn with the rock.
- **Desert (2026-10-07):** `Workspace.ZoneDesert` (outside `Workspace.Zones`, built by the user) has its own `RockSpawnArea` with `Zone` = `"Desert"`, 170 x 30 x 116 at (19, 13, -15). It stops at x 104 so rocks stay out of the river (x 106 to 134). Its rocks are `DesertFirst/Second/Third`: placeholder templates `Model_Rock_Desert*` (the boulder mesh scaled 0.65 / 1.1 / 1.75 and tinted tan / orange / red, split with `Model_RockSplit_Boulder`) plus `Model_RockPreview_Desert*`. Names and numbers are drafts. A playtest got 962 spots and a 5 / 3 / 2 mix.
- **Jungle, ocean, snow (2026-10-10):** same pattern as the desert: `Workspace.Zones.Zone<Name>.RockSpawnArea` (`Zone` = Jungle / Ocean / Snow, 216 x 30 x 164 at x 42, y 13, zone centre z; the desert's box is the same since its rebuild) and rocks `<Zone>First/Second/Third` (weights 50 / 30 / 20). Not playtested.
- **Dust:** `Assets.VFX.VFX_Rock_Dust` is a placeholder smoke burst (`EmitCount` attribute) for the rise. Hit and break effects are in [[Chop Effects]]. `SFX_Rock_Rise` (rumble, rbxassetid://9118657619) starts 0.6s in (`RiseSoundStartSeconds`): the file is silent for 0.28s and only swells at ~0.95s, so played from the start it landed after the 0.6s rise. `LocalSound.Play(key, startSeconds)` does the same for 2D sounds (level-up starts 0.3s in).

## How it works
- `RockService` samples the areas at server start (about 1,280 forest spots in ~100 ms). For each 4-stud column it raycasts down through everything collidable and takes the lowest surface, then steps up through anything stacked within 1.5 studs (`GroundStepStuds`). It then checks each rock kind's box and a 3 x 5 x 3 standing spot where the chop snaps the player. Only collidable parts block.
- Each player's rocks are data on the server (id, kind, CFrame). The mix is fixed by the zone weights: each new rock is the kind furthest below its share of `RockCount` (`RockCount` 25 per zone since 2026-10-17, was 15 from 2026-10-16 and 10 before; forest: about 12-13 Stone / 7-8 Boulder / 5 Mossy), so a broken rock comes back as the same kind at a new spot. Ties pick at random. They're created when that client sends `RockReady`, replaced 2s after a break (Master: after the wind-up too), and sent only to that player (`RockSpawned`). `RockChop(id)` starts a chop; the server checks ownership, rise time and range.
- `RockController` (client) builds the part from the template, rises it, adds the prompt, and tags it `ChopRock` once it's up, so `RockLabels` and the guide arrow pick it up. Hit, crack, break and Master effects moved here from the server (`RockController/Effects`). Rock prompts are off while any chop minigame is open (`ChopController.ActiveChanged`).
- Other players within 150 studs get `RockChopShown` with dust, sound and a small grey chunk spray, but no rock.
- Admin "Spawn Spots" (Ctrl+Shift+K) shows every spot as a dot coloured by the biggest rock that fits: grey Stone, blue Boulder, green Mossy.
- Values live in `RockSpawnConfig`. The chopped-rock timings stay in `RockConfig` (`RespawnSeconds` is now just how long the pieces stay).

## Gotchas
- `Forest Zone.ZoneTemplate.Floor` is rotated 90°, so the forest runs along X (floor x -68..152, z -195..-75), not along Z as the model's bounding box suggests. Past z -75 is bare Baseplate with no wall.
- The floor sits on the Baseplate. Taking the plain lowest surface put every rock on the Baseplate, inside the floor. That's why the ground search steps up through stacked surfaces.
- **Random yaw and spacing (2026-10-24):** spots are sampled before any yaw is known, so the wall/prop check uses an upright square as wide as the rock's XZ diagonal (fits any yaw; about 4% fewer spots). Rock-to-rock spacing must not use that diagonal circle: it jammed Snow (no room for a 25th rock, SnowThird kept failing). Instead the yaw is picked before the spot, and `Spawner` measures both rotated boxes along the line between their centres (a separating-axis test) plus `RockGapStuds`. Spacing is only checked within a zone, so rocks either side of a zone border (Ocean/Snow at z ~475) can still touch.

Related: [[Forest Rock Tiers]], [[Admin Panel]], [[Index]]
