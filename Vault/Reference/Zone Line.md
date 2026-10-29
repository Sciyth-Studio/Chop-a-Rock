---
description: Where each zone sits in the straight line (168 studs apart on +Z since 2026-10-16), its folder and its floor/terrace colours; zone order forest, desert, jungle, ocean, snow, then the zones 6-10 blockouts (swamp, savanna, bamboo forest, volcano, golem ruins); all on whole studs.
type: reference
---
# Zone line

Zone order (user, 2026-10-07): forest → desert → jungle → ocean → snow. This replaced the earlier planning order (snow before jungle and ocean).

Each zone is a 220 x 168 floor (x -68 to 152), and the line runs along +Z, 168 studs per zone. Terraces sit at x -98 and x 182, 36 tall. How to add one: the `new-zone` skill.

On 2026-10-16 the user asked for every zone to be 1.4x longer (was 120 deep). Floors and terrace walls were stretched on Z, starting from the forest's near edge at z -195. Spawn areas went to 164 deep, and entrance signs and admin warps moved with their zone's near edge. Code has no zone coordinates in it, so only Studio changed.

| Zone | Folder | Z range (centre) | Floor / cap | Middle layer | Bottom layer |
|---|---|---|---|---|---|
| Forest | `Workspace.Zones.ZoneForest` | -195 to -27 (-111) | 39, 70, 45 | 112, 72, 39 | 98, 63, 34 |
| Desert | `Workspace.Zones.ZoneDesert` | -27 to 141 (57) | 160, 132, 79 | 138, 114, 68 | 113, 93, 56 |
| Jungle | `Workspace.Zones.ZoneJungle` | 141 to 309 (225) | 50, 130, 40 | 115, 80, 45 | 90, 62, 35 |
| Ocean (deep ocean) | `Workspace.Zones.ZoneOcean` | 309 to 477 (393) | 0, 55, 110 | 15, 30, 90 | 25, 15, 65 |
| Snow | `Workspace.Zones.ZoneSnow` | 477 to 645 (561) | 240, 245, 255 | 150, 190, 230 | 110, 150, 200 |
| Swamp | `Workspace.Zones.ZoneSwamp` | 645 to 813 (729) | 50, 70, 40 | 95, 80, 50 | 70, 58, 38 |
| Savanna | `Workspace.Zones.ZoneSavanna` | 813 to 981 (897) | 200, 175, 70 | 175, 110, 60 | 140, 85, 45 |
| Bamboo Forest | `Workspace.Zones.ZoneBambooForest` | 981 to 1149 (1065) | 120, 150, 90 | 105, 115, 95 | 80, 90, 72 |
| Volcano | `Workspace.Zones.ZoneVolcano` | 1149 to 1317 (1233) | 40, 35, 35 | 90, 50, 40 | 60, 35, 30 |
| Golem Ruins | `Workspace.Zones.ZoneGolemRuins` | 1317 to 1485 (1401) | 110, 115, 100 | 135, 130, 120 | 100, 96, 88 |

**Zones 6-10 blockouts (2026-10-29):** clones of the snow `ZoneTemplate` (floor, terraces, `ZoneEntrance`) plus a `RockSpawnArea` (`Zone` = Swamp / Savanna / BambooForest / Volcano / GolemRuins), nothing else. Colours are placeholders from [[World 1 Plan]] floor colours. Signs: Swamp Green, Savanna Gold, "Bamboo Forest" Green ("Bamboo Forest Zone" overflowed the sign), Volcano Red, Golem Ruins Chrome; strength ranges typed from `World1Plan.md` (First to Third rock), not from `RockConfig`, which has no entries for these zones yet. Code skips spawn areas whose zone has no `RockSpawnConfig` entry, so the boxes are harmless until then. Not built: rocks, Roks, geodes, decor, floor decor, admin warps, cannons, config, the Golem arena. From the Swamp on, the zones run past the Baseplate's z 1024 edge, which is fine ([[World 1 Plan]]: no Baseplate limit).

**Grid (2026-10-29):** every lobby and zone floor, terrace and spawn area is on whole studs, and each zone meets the next with no gap from the lobby (z -465 to -195) to Golem Ruins. There used to be a 0.054-stud gap between the lobby and the forest: the `Lobby` model was 0.136 too far +Z (far edge z -194.864) and the forest floor and terraces were 0.190 too far +Z (near edge z -194.810, overlapping the desert by 0.19). Both were snapped back onto the grid, and the desert's sign moved from z -27.19 to -27. The lobby shops, teleport points and other lobby props were left where they were. To check the grid, measure each part's world box edges, not the models' bounding boxes. The rotated floors make those misleading.

Jungle, ocean and snow (2026-10-10) now each have: the floor and terrace walls, a `ZoneEntrance` sign inside `ZoneTemplate` (style Green / Sky / Chrome, strength range in compact form such as "62.5K N to 1.56M N Strength"), a `RockSpawnArea` (216 x 30 x 164 at x 42, y 13, zone centre z; `Zone` = Jungle / Ocean / Snow), three placeholder rocks each (`Model_Rock_<Zone>First/Second/Third` plus `Model_RockPreview_*`: the desert templates cloned, boulder mesh sized and tinted per [[Zones After Desert]], split with `Model_RockSplit_Boulder`), `RockConfig` / `RockSpawnConfig` / `IndexConfig` Rocks page / `AssetRegistry` entries, and an admin warp. Not built: Roks, geodes, geode stands, Index Roks pages, decoration, gates. Not playtested yet, so spawn spots and the rock mix are unchecked. The colours are drafts. The ocean is a deep-ocean theme (user, 2026-10-07), not a beach. Its first teal-blue try (0, 110, 150) looked like the snow's icy walls under the game's blue lighting, so it went darker navy. The lobby is at z about -395, past the forest's near edge. The Baseplate reaches z 1024, so about two more zones fit before the line runs off it.

**Decor (2026-10-28):** each zone has a `Decor` model, `Workspace.Zones.<Zone>.Decor`, holding 40 props cloned from `ReplicatedStorage.Assets.Models.Decor` ([[Meshlab]]). They sit 20 per terrace on the terrace tops (y 36; left x -158 to -68, right x 152 to 242), because the spawn area covers the whole floor. They're scattered with a fixed seed, crowded towards the edge you see from the floor, kept inside the terrace and zone, and at 0.85-1.2 scale with random yaw. Mixes: forest Pine/Bush/Stump/Mushroom, desert Cactus/PricklyPear, jungle Palm/LeafPlant/Bush/Mushroom, ocean Kelp/Coral/Starfish, snow SnowPine/SnowPile. Trees and cacti collide; the small props don't. All props are CanTouch/CanQuery off. Not looked at from the floor yet.

**Floor decor (2026-10-28):** each zone also has a sparse `FloorDecor` model with 8-10 props on the playing floor (y 1). They're at least 22 studs apart, 18+ studs from every `TeleportPoints`/`AdminWarps` marker, and 10+ from the zone ends. Tall trees (Pine, JungleTree, SnowPine) sit only in a band along the side walls. They are **CanCollide + CanQuery on on purpose**: `RockService/SpawnPoints` raycasts and box-checks with `RespectCanCollide`, so collidable decor keeps rock spots and their chop stand spots clear automatically. Spots are sampled at server start, so moving floor decor needs a server restart. Mixes: forest Bush/Stump/Mushroom/Pine, desert PricklyPear/Cactus, jungle LeafPlant/JungleBush/Mushroom/JungleTree, ocean Starfish/Coral/Kelp, snow SnowPile/SnowPine. The terraces use the same jungle swap: JungleTree replaced the Palm (no zone is a beach), and Bush became JungleBush.

Related: [[Rock Spawning]], [[Forest Zone Entrance]]
