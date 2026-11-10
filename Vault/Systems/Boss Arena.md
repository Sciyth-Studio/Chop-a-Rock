---
description: Boss Arena (built 2026-11-09) - walled 288x288 courtyard behind the lobby in the lobby's colours with a Ruins-stone centre square, through a 60-stud gateway in the lobby's new back wall; boss-clock events (Diamond Rock now, the Golem fight later) happen here.
type: system
---
# Boss Arena

The user asked on 2026-11-09 (feedback item 4): every boss event takes place in an arena behind the lobby, on its own timer ([[Event Clock]]); Diamond Rocks fall here, scaled up; the Golem fight will be here too. The old walled arena past the Ruins (`Zones.ZoneRuins.BossArena`, empty wall models by then) was deleted.

## Build (Studio, `Workspace.BossArena`)
- (Original build, before the resize below.) `Floor`: one part 376 x 1 x 376 at (42, 1, -643), top at y 1.5 like the lobby floor, colour 120,116,106, Glacier + `2022 Stud`. Covers z -455 (the lobby's open back edge) to -831.
- `Walls`, each the lobby's three layers (ThirdLayerWall 16 tall, SecondLayerWall 15, FirstLayerWall 4; 36 total, 8 thick) in [[Zone Line]] Ruins colours (bottom 100,96,88, middle 135,130,120, top 110,115,100):
  - `FrontRightWall` x -196 to 12 and `FrontLeftWall` x 72 to 280, z -463 to -455. They run the lobby's full width, so they also close its back edge; the gap between them is the 60-stud gateway at x 12 to 72, centred on the lobby (x 42).
  - `RightWall` x -146 to -138 and `LeftWall` x 222 to 230, z -823 to -463.
  - `BackWall` x -146 to 230, z -831 to -823.
  - Inside: x -138 to 222, z -823 to -463 (360 x 360).
- `DiamondSpot`: an invisible 4 x 0.2 x 4 marker at (42, 1.6, -643), the arena centre. `DiamondRockService` spawns on it.
- No sign, decor, teleport button or `LobbyWallsHigh` cap yet.

Not playtested.

Related: [[Diamond Rock]], [[Event Clock]], [[World 1 Plan]], [[Zone Line]]

## Change 2026-11-09 (user): smaller, lobby colours
"Shrink the arena's area to about 65%", "recolor its walls to match the lobby", "the very center should be ruins colored".
- Inside is now 288 x 288 (x -102 to 186, z -751 to -463; 64% of the area). `RightWall` x -110 to -102, `LeftWall` x 186 to 194, `BackWall` z -759 to -751; the front walls and the gateway are unchanged.
- Walls use the lobby wall colours (read from `Lobby.LobbyWalls.LeftWall`: green top, brown middle and bottom). `Floor` is 304 x 304 at (42, 1, -607) in the lobby floor green.
- `Centre`: a 120 x 120 x 1 plate at (42, 1.2, -607), Ruins floor colour 110,115,100, top 0.2 above the floor (no z-fighting). `DiamondSpot` moved onto it at (42, 1.8, -607).

**Fix 2026-11-09 (user: "the arena's floor and the lobby floor don't match up"):** the lobby floor's top is at y 1.0 (`LobbyFloor` y 0.5, 1 thick), but the arena `Floor` had been placed with its top at 1.5. `Floor` moved to y 0.5 (top 1.0, flush with the lobby), `Centre` to y 0.7 (top 1.2), `DiamondSpot` to y 1.3. Check floor heights by part top (Position.Y + Size.Y/2), not rounded positions.
