---
description: Where each zone sits in the straight line (120 studs apart on +Z), its folder and its floor/terrace colours; zone order forest, desert, jungle, ocean, snow.
type: reference
---
# Zone line

Zone order (user, 2026-10-07): forest → desert → jungle → ocean → snow. This replaced the earlier planning order (snow before jungle and ocean).

Each zone is a 220 x 120 floor (x -68 to 152), and the line runs along +Z, 120 studs per zone. Terraces sit at x -98 and x 182, 36 tall. How to add one: the `new-zone` skill.

| Zone | Folder | Z range (centre) | Floor / cap | Middle layer | Bottom layer |
|---|---|---|---|---|---|
| Forest | `Workspace.Zones.ZoneForest` | -195 to -75 (-135) | 39, 70, 45 | 112, 72, 39 | 98, 63, 34 |
| Desert | `Workspace.ZoneDesert` (user-built, outside `Zones`) | -75 to 45 (-15) | 160, 132, 79 | 138, 114, 68 | 113, 93, 56 |
| Jungle | `Workspace.Zones.ZoneJungle` | 45 to 165 (105) | 50, 130, 40 | 115, 80, 45 | 90, 62, 35 |
| Ocean (deep ocean) | `Workspace.Zones.ZoneOcean` | 165 to 285 (225) | 0, 55, 110 | 15, 30, 90 | 25, 15, 65 |
| Snow | `Workspace.Zones.ZoneSnow` | 285 to 405 (345) | 240, 245, 255 | 150, 190, 230 | 110, 150, 200 |

Jungle, ocean and snow are bases only (floor plus terrace walls, made 2026-10-07). They have no entrance sign, spawn area, rocks or decoration yet, and their colours are drafts. The ocean is a deep-ocean theme (user, 2026-10-07), not a beach. Its first teal-blue try (0, 110, 150) looked like the snow's icy walls under the game's blue lighting, so it went darker navy. The lobby is at z about -395, past the forest's near edge. The Baseplate reaches z 1024, so about five more zones fit before the line runs off it.

Related: [[Rock Spawning]], [[Forest Zone Entrance]]
