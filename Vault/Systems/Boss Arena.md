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

- **Frost Yeti ice clusters (2026-11-12, user):** the 7 `IceCrystal` props in `Model_Arena_FrostYeti.Props` are now the meshlab `IceSpike` crystals (variants 1-3 in turn), each a MeshPart named `IceCrystal` scaled to about the old height (22-27 studs), on the old spot with a random turn. Hull collision; old CanCollide, CanTouch and CastShadow kept. The old clusters are in `ServerStorage.ArenaBackups["IceCrystals.BeforeIceSpike"]`.

Related: [[Diamond Rock]], [[Event Clock]], [[World 1 Plan]], [[Zone Line]]

## Change 2026-11-09 (user): smaller, lobby colours
"Shrink the arena's area to about 65%", "recolor its walls to match the lobby", "the very center should be ruins colored".
- Inside is now 288 x 288 (x -102 to 186, z -751 to -463; 64% of the area). `RightWall` x -110 to -102, `LeftWall` x 186 to 194, `BackWall` z -759 to -751; the front walls and the gateway are unchanged.
- Walls use the lobby wall colours (read from `Lobby.LobbyWalls.LeftWall`: green top, brown middle and bottom). `Floor` is 304 x 304 at (42, 1, -607) in the lobby floor green.
- `Centre`: a 120 x 120 x 1 plate at (42, 1.2, -607), Ruins floor colour 110,115,100, top 0.2 above the floor (no z-fighting). `DiamondSpot` moved onto it at (42, 1.8, -607).

**Fix 2026-11-09 (user: "the arena's floor and the lobby floor don't match up"):** the lobby floor's top is at y 1.0 (`LobbyFloor` y 0.5, 1 thick), but the arena `Floor` had been placed with its top at 1.5. `Floor` moved to y 0.5 (top 1.0, flush with the lobby), `Centre` to y 0.7 (top 1.2), `DiamondSpot` to y 1.3. Check floor heights by part top (Position.Y + Size.Y/2), not rounded positions.

## Boss sets (2026-11-11, arena themes session)
User: each boss gets its own set that rises out of the ground when it spawns and sinks after the fight. Boulder Crab "a sand island surrounded by ground that looks like water", Big Croc "a swamp", Frost Yeti "a frozen forest".
- **Templates:** `ReplicatedStorage.Assets.Models.Arenas.Model_Arena_BoulderCrab / _BigCroc / _FrostYeti` (AssetRegistry keys of the same name), pivot at the arena floor top (42, 1, -607). Each has `Ground` (a 24 x 24 grid of 12-stud `2022 Stud` tiles, two-tone by grid parity, outer tiles 1 stud into the walls), `Props` (each child rises as one piece; `Solid` attribute = keeps collision after rising) and `Ambience` (invisible box parts with emitters, off until the set is up). Model attribute `DustColor` tints the dust.
- **Heights:** walkable tiles top at 1.3 (the chop code stands players at `DiamondSpot` 1.3, so keep the fight area there); water and swamp ponds top at 1.05 over the floor's 1.0. The water is plain floor, walkable.
- **Clear space:** props sit 104+ studs from the centre (the Croc at 1.5x is 143 long) and outside the gateway lane (|x| < 42 on the gate side). Only flat starfish and beach rocks sit closer, on the Crab's island rim.
- **Crab:** sand island (r 90), wet-sand rim, cyan shallows, deep blue water; four corner sand islets with palms and starfish; coral, kelp, white wave bars, three-slab beach rocks; water glints.
- **Croc:** mud clearing (r 66), moss ground, murky ponds in the outer ring (noise-picked tiles); dead trees, lily pads on ponds, cattails on pond edges, swamp bushes, mushrooms, stumps; low green mist and fireflies.
- **Yeti:** frozen ice pond (r 72) under the fight, snow ground; 26 snowy pines, ice crystal clusters (part slabs, solid), snow piles; snowfall.
- Props are the zone decor meshes (`Assets.Models.Decor`) scaled 2-4.6x, per [[Keep Decor Simple]].
- **Code:** `src/client/Controllers/BossArenaController/` (`init` watches the `WorldBoss` tag and its `Boss`/`Phase` attributes; `Motion` collects pieces, schedules and moves them with BulkMoveTo; `Effects` dust puffs and the camera rumble). Numbers in `BossConfig.ArenaThemes`. Client-only: the server never sees the sets.
- **Rise** (boss seen while Sleeping): tiles ripple up from the centre outward over 1.4 s, then props pop up one after another around the arena (sorted by angle, 3.2 s spread, 1.3 s each, back-ease overshoot, small jitter, a dust puff sized to the prop); light camera rumble only while the camera is Custom and near the arena. Joining mid-fight shows the set already up.
- **Sink:** 2.5 s after `Defeated`/`Leaving`, or at once when the boss model is removed: props drop in reverse order, then tiles ripple back inward, then the set is destroyed.
- Sound (2026-11-12): `Effects.Rumble` also plays `SFX_Arena_Grind` (asset 98241988442808, Volume 0.4) looped, 2D, only when your camera is within `ShakeRangeStuds`, faded out over `GrindFadeSeconds` (0.6) as the rise or sink ends; `StopRumble` cuts it. Made from Freesound 222521 uagadugu "Cracking Earthquake" 0-6 s plus 578491 PostProdDog "Heavy stone door opens 2" (both CC0). earshot reads it as a deep rumble or eruption more than a stone scrape. Measured, not heard.

## Colosseum redesign (2026-11-11, user approved the plan; "no banners")
User: "redesign the base arena with nothing on it so it looks cooler". Plan approved with a claw crest, the dais swapping with the boss sets, and no banners.
- **Found:** the front was open across the full 288 width. `FrontRightWall`/`FrontLeftWall` only run x -196..-102 and 186..280, not up to a 60-stud gateway as the original build said.
- **`BossArena.Dais`** (Model, Persistent streaming; everything in its `Ground` child sinks for a boss): stud cylinder discs `PavingOuter` r128 top 1.08, `PavingMiddle` r108 1.16, `PavingInner` r90 1.24 (covers the old `Centre` square, which is untouched underneath), `Inlay` r66 1.28 dark, `Floor` r54 1.32 (≈ `DiamondSpot`, so chop standing height is unchanged); a `Rim` curb of 32 Inlet segments at r 68 (top 2.4 / 2.402 alternating); three red/orange `Claw` stud plates (top ~1.44); four Neon cyan `Rune` strips from r 71 to the walls, one straight out to the gate.
- **`BossArena.Colosseum`** (always visible, neutral stone + fire only so it suits every boss set): `Stands` (four tiers outside the side and back walls, tops 40/46/52/58, `2022 Big Stud`, merlons along the top), `Towers` (four 26x66x26 corner towers with a band, cap, merlons and a `Brazier`: Neon coals, fire and ember emitters, PointLight), `Gate` (pillars at x 0-13 and 71-84, lintel at y 44-52, five ivory WedgePart spikes, two lintel braziers, `Sign` "Boss Arena" in Gold text style on the lobby face, and `GateWallRight`/`GateWallLeft`, copies of `FrontRightWall` closing x -103..1 and 83..187, so the way in is the 58-stud arch).
- **Swap:** `BossArenaController` collects `Dais.Ground` once (`BossConfig.ArenaThemes.DaisName`). When a boss set starts rising, the dais sinks (rings first, then rim and runes rippling outward). When the last set has sunk and been destroyed, it rises back. Joining mid-fight hides it instantly. Client-only, like the sets.
- No banners (user). The "today's boss" gate banner was skipped (it needs the boss clock).

## Diamond Rock set (2026-11-11)
User: "diamond rock is technically a boss so it should have a lot of the same stuff as the rest of them".
- `Model_Arena_DiamondRock` (`BossConfig.ArenaThemes.Sets.DiamondRock`, `DiamondSetKey`), a crystal cavern: dark slate checker tiles (lighter inside r 60), 114 Neon cyan `Vein` segments branching from r 34 out to the walls (top ~1.5, no collision), six dark `Outcrop` rock stacks with crystal clusters on top (r 104+) and twelve `CrystalCluster`s (r 80+; bigger near the walls; every few has a Neon core and a cyan PointLight). The crystals are Inlet Plastic in the Colossus cyans (0,230,255 / 90,240,255 / 190,250,255). Floating cyan glints come on once it is up.
- `BossArenaController` also watches the `DiamondRock` tag (`DiamondRockConfig.Tag`): it always rises when the model appears (alongside the Colossus's 0.5 s + 1.2 s rise) and sinks when the model is removed. The dais swaps out the same way as for the bosses.
- Props stay 80+ studs from the centre (the Colossus is about 106 x 92, players stand about 52 out).

## Meshlab props (2026-11-11, prompts written)
User: "a ton of the arena assets would probably look better if i meshlab modeled the assets". Prompts in `assets/Arena/Prompts.md`: Lineup A Colosseum (corner tower, gate arch with ivory tusks, coal fire bowl, a chopping-hand emblem medallion for the dais centre) and Lineup B nature (beach rock cluster, crystal cluster drawn cyan and recoloured ice blue for the Yeti, crystal outcrop). The user may swap the dais's claw crest for the chopping hand ("it makes sense"). Waiting on the user to run the prompts.

## Meshlab props swapped in (2026-11-11)
User: the sheets "do need to be in my prop style" ([[Decor In ForestTree Style]]), and "just make a hand symbol" instead of ChatGPT's chop hand. Models in `tools/meshlab/models/` (`ArenaParts` shared stone colours, crossed/round/disc courses and the coal bowl; `DecorArenaTower`, `DecorArenaGate`, `DecorArenaBrazier`, `DecorArenaHand`, `DecorBeachRocks`, `DecorCrystalCluster`, `DecorIceCluster` wrapper, `DecorCrystalOutcrop`). The Colosseum pieces are built at world size with **no AO bake** (the bake split big faces to 20k triangles; buildings are flat anyway). Contact sheet `assets/Arena/ArenaPropsSheet.png`; FBX `assets/Arena/Props/ArenaProps.fbx`, asset `78310464473734` ("Arena Props v1"). Templates (MeshParts, white, Plastic, `2022 Stud`, pivot at the mesh origin = base centre) in `ReplicatedStorage.Assets.Models.Decor`: `ArenaTower`, `ArenaGate`, `ArenaBrazier`, `ArenaHand`, `BeachRocks`, `CrystalCluster`, `IceCluster`, `CrystalOutcrop`. Backups in `ServerStorage.ArenaBackups` (`Colosseum.BeforeMeshlab`, `Dais.BeforeMeshlab`, `ArenaSets.BeforeMeshlab`); the raw import is `ServerStorage.ArenaPropsImport`.
- **Towers / gate:** the mesh is added inside each `Tower` model and `Gate` (turned 180° so the sign panel faces the lobby, base y 1.0) with `CanCollide` off; the old parts stay as **invisible colliders**, so the gateway's collision is the old boxes, not the mesh. The gate's 10 WedgePart spikes were deleted. The `Sign` moved to (42, 50, -450.6) onto the new panel.
- **Fire:** the lintel braziers carry `ArenaBrazier` at 0.62 on the lintel (y 56.2). Each brazier's `Coals` part (invisible) was moved onto the new coal heap. The old `Fire` emitter used the cel-fire 4x4 sheet with `FlipbookLayout` None (all 16 frames at once, wispy); user: "rework the fire ... to look more solid". Now per `Flame` attachment: `Core` (11395089850 Grid4x4 OneShot, FacingCameraWorldUp, LE 0, Brightness 4, opaque to 70% of life, Rate 22), `Heart` (yellow fire sprite 10630207905), `Glow` (soft glow 8708637750) and the old `Embers`; sizes x2.2 on the towers. Not seen in Play (Edit captures don't show particles).
- **Dais:** the 9 `Claw` plates are replaced by `Hand` (ArenaHand, base y 1.3, fingers toward -Z) in `Dais.Ground`, so it sinks with the dais.
- **Sets:** BeachRock x4, IceCrystal x7 (scaled 1.7 more, ~23 tall), Outcrop x6 and 12 ground CrystalClusters are now single MeshParts (attributes copied, bottoms at y 0.6). The 6 clusters that sat on top of the old outcrops were removed (the outcrop grows its own crystals); their PointLights moved onto the nearest outcrop.

## After the user's play (2026-11-11)
- **Fire, second pass** (user: "fire looks flat now"): `Core` now has LE 0.25, random spin, drag, upward acceleration and a 16° spread with a size swell (so overlapping copies give depth); new `Licks` (flame sheet 11204150798, stretch with `Squash` to 0.9, shoot up and stop), a brighter `Heart` (LE 0.8) and a warm `Smoke` wisp rising above (soft glow 8708637750, LE 0). Not seen by Claude (particles don't show in Edit captures).
- **Rune strips removed** (user: "remove the glowing blue lines from arena"): the four Neon `Rune` strips in `Dais` are deleted.
- **Defeat:** the arena set now sinks 6.5 s after `Defeated`/`Leaving` (`SinkDelaySeconds`), in step with the boss lying down for 7 s.
