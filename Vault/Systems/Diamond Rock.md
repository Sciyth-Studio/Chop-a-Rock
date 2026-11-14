---
description: Diamond Rock (built 2026-10-09) - shared server-wide special rock rolled by the 5-min Event Clock (since 2026-10-29) at a random clear spot in a busy zone, 60 s countdown, paid per hit by damage share; where state lives, how chopping in slots works, admin commands.
type: system
---
# Diamond Rock

Approved 2026-10-09. The user rejected dedicated marker spots, so it picks a random clear spot in the zone. All numbers are drafts in `DiamondRockConfig`.

## Rules
- **When and where:** since 2026-10-29 the [[Event Clock]] decides when (no own timer). The server picks a zone weighted by how many players stand in its `RockSpawnArea`. If nobody is in a zone, that slot is skipped. `RockService:FindRingSpot` tries up to 300 sampled spots for one where the rock box and all 8 standing spots (a ring at the chop snap distance) are clear and level (`SpawnPoints.FitsRing`). Characters are excluded from the check.
- **Your rocks in the way:** `RockService:ReserveArea` sinks any per-player rock within the ring plus 4 studs (`RockRemoved` packet) and respawns it elsewhere. New spawns avoid that circle until `ReleaseArea`. Rush rocks and the rock you are chopping are left alone.
- **Who can chop:** strength of the zone's first rock. Weaker players get the normal too-weak crack.
- **Numbers:** value = 15x the zone's top rock payout (forest: 12,000; was 50x until 2026-10-10, when a desert diamond with Hot Streak paid a solo player ~9M). Health = top rock strength x Good damage x 45 chops (forest: 4,500). Each hit pays value x damage / max health, then friend, rebirth and Index multipliers. Hot Streak does not multiply it: a diamond chop only keeps the streak alive (`HotStreakService:KeepAlive`) and `ChopResult` carries multiplier 1. A Master deals 5x a Perfect's damage instead of finishing it, so the next round waits `ImpactDelaySeconds + StrikeHoldSeconds + RoundPauseSeconds` (before 2026-10-13 it used only the 0.9 s pause and the meter came back during the cinematic). Countdown 60 s after a 1.2 s rise.
- **End:** on break or timeout, everyone's chop session ends (`ChopEnded` packet for everyone but the breaker), everyone who earned gets "Diamond Rock: +$X", and the area is released.

## Where things live
- Server: `DiamondRockService` (`init` state, sessions and timer; `Spawning` zone pick, stats, model; `Chopping` damage, payout, slot pick). The rock is a real server part, `Workspace.DiamondRock` (Model, Persistent streaming, tag `DiamondRock`), with attributes on `Rock`: `Zone`, `Health`, `MaxHealth`, `EndsAt` (server time), `StrengthRequired`, `ChopSlots`. Chop start reuses `ChopMinigameStart` with the part.
- Chop slots: the server gives the player the free slot closest to where they stand and sets player attribute `ChopSlot`. `ChopController` rotates the snap and camera offsets by `(slot - 1) / slots * 2pi + pi` when the rock has `ChopSlots`. Both sides use direction `(sin a, 0, cos a)`.
- Client: `RockController/Diamond.luau` (rise, ring, camera shake within 90 studs, neon beacon 400 studs tall, `VFX_Diamond_Glow` sparkles on the rock and up the beacon ("Column" emitter), the prompt (its `DiamondLabel` billboard was replaced on 2026-11-11 by the top-of-screen boss bar, see [[Boss Bar Research]]; `Diamond.luau` only keeps the tick sound for the last 10 s), hit shards and break burst, sink on `DiamondEnded`). The HUD pill is the `DiamondRockPill` screen ("Diamond Rock in the Forest 0:42", top centre). (The old `ArrowTrail` guide arrow that pointed at it was removed 2026-10-16.)
- Studio: `Assets.Models.Rocks.Model_Rock_Diamond` (crystal cluster since 2026-10-13, see [[Diamond Rock Reference]]; 25 x 19.6 x 20.4 studs, colour 0,160,230, split `Model_RockSplit_DiamondRock`; no Reflectance, which washed the old placeholder out to a flat blob), `Assets.VFX.DiamondLabel`, `VFX_Diamond_Glow/Ring/Shards/Burst`, `Sounds.SFX_Diamond_Appear/Hit` (placeholders), and empty-SoundId `SFX_Diamond_Shimmer` (loop on the rock, 90 studs), `Beacon` (loop on the beacon, 400 studs), `Shatter`, `Tick` (each of the last 10 s), `Despawn`, `Payout` (client plays it when the "Diamond Rock: +$" notice arrives); played in `Diamond.luau`, keys in `DiamondRockConfig`, registered in `AssetRegistry`; an empty SoundId warns once and skips; loops stop on break and timeout, `StarterGui.DiamondRockPill`. Showcase stands "Diamond Ring/Shards/Burst" in [[VFX Showcase]].
- VFX pass 2026-10-09 (arrival, idle glow, beacon; the user left per-hit and break for later). The rise waits `ArrivalDelaySeconds` (0.5) so the lead-up plays first: ground glow, scorched glowing cracks, glints gathering inward (`GatherArea` part). Then a star flash, a neon `Column` that shoots up to 300 studs and thins out, two shockwave rings, flying shards, sparkles, dust and a cyan light. `VFX_Diamond_Glow` children: `Glints` and `Shimmer` (rock surface), `Column` (beacon), and Attachments `Base` and `Top`, which code puts on the beacon at the rock's base and at `BeaconHeight`. `Base` holds `Halo` (slow broken ring, 40 studs), `BeaconRings` (rings rising up the beam) and the `Sheath` Beam (camera-facing scrolling light, Base to Top). The beacon core is thinner and brighter now (width 2, transparency 0.2). Textures are drawn in `assets/VFX/Diamond/`, signed off and uploaded under the group 2026-10-13; templates use `rbxassetid://` addresses. The old templates are in `ServerStorage.VFXBackups`.
- Admin: "Spawn Diamond Rock" (Ctrl+Shift+D, in your zone or the busiest) and "Diamond: 10s Left" (Ctrl+Shift+T).

## Tested 2026-10-09
Playtest, one player: spawned in the forest, beacon, label, pill and prompt up; snapped to slot 3 at 17.5 studs; Perfect hits did 192.5 damage and paid 1,711; the 10 s timeout ended the chop, turned the time red, sank the rock and showed "+$5,304"; a one-hit break paid 40,000; per-player rocks cleared to 23 studs from centre. Not tested with several players at once.

2026-10-21: a Master on a Diamond Rock left the letterbox up until the rock died (it closed only on chop end). `ChopController` now closes it on the next `ChopRoundStart`. User-tested in the snow zone: a strong save one-shots the forest diamond with a Master, so test multi-hit behaviour in a later zone.

**2026-11-11:** `ZoneStats` / `BestZone` moved to `ServerScriptService.Utils.ArenaShare` (shared with [[World Bosses]]). The Diamond won't spawn while a boss is in the arena, and a boss won't spawn while a Diamond is out.

Related: [[Rock Spawning]], [[Golden Rocks]], [[Chop Effects]], [[Admin Panel]]

## Change 2026-11-03 (user)
The `DiamondRockPill` timer is gone; the spawn notification names the zone.

## Change 2026-11-09 (user): the arena
The Diamond Rock now only spawns in the [[Boss Arena]], on the boss clock ([[Event Clock]], every 15 min at :02:30). Rules that replace the zone ones above:
- **Where:** on `Workspace.BossArena.DiamondSpot`, at `ArenaScale` 2 (about 50 x 39 x 41 studs). No zone pick, no `FindRingSpot` and no `ReserveArea` (no per-player rocks there). `Zone` attribute = "Arena". Notice "Diamond Rock in the Arena!". Countdown 90 s (was 60) to give time to walk over. 12 chop slots (was 8).
- **Who:** anyone out of the tutorial; no strength gate (no crack).
- **Health:** the sum, over every player in the server out of the tutorial, of their own share: their best zone's top rock strength x Good damage x `HealthChops` (45) x `HealthShare` (0.35). A player's best zone is the furthest zone whose geode `StrengthRequired` their `PeakStrength` reaches (`Spawning.BestZone`), Forest if none.
- **Pay:** each hit pays the hitter's own value (15 x their best zone's top rock payout) x damage / their own share, then the usual friend, Index and pass multipliers. So dealing your own share earns your full value; more players means more health and more total pay.
- Not playtested. The client effects (ring, label height, beacon) were made for the 25-stud rock and weren't checked at 2x.

**Camera (2026-11-09, user: "don't reset the camera every hit for the diamond rock"):** `ChopController` sets `chopCamera = windUpCamera` when the rock has `ChopSlots`, so on the Diamond the camera stays on the over-the-shoulder shot for the whole fight. Shakes, flashes and the Master cinematic still play.

## Diamond Colossus model (2026-11-09, user approved the draft)
- Model `tools/meshlab/models/DiamondRock.luau` → `assets/Rocks/Diamond/DiamondRockV2/DiamondRock.fbx` → Open Cloud model 117428719934905. Template `Assets.Models.Rocks.Model_Rock_Diamond` is now the `Rock` MeshPart (stone, Color white over vertex colours, Plastic + `2022 Inlet`, Hull, about 106 x 31 x 92) with children `Crystals` (Hull, collides), `Core` (Neon 190,250,255), `Veins` (Neon 80,220,255) and `Shards`, all unanchored, Massless and welded to `Rock`. Crystals, Core and Veins use WeldConstraints; Shards uses a `Weld` named `ShardSpin`, so the client can turn its `C0`. No `SplitModel` attribute. The old crystal cluster is in `ServerStorage.ModelBackups["Model_Rock_Diamond.BeforeColossus"]`.
- Built at full size, so `ArenaScale` is 1. `Spawning.Build` moves every descendant part by the same offset as `Rock`, then the welds hold them.
- Client (`RockController/Diamond.luau`): `animateParts` spins the shards (`ShardSpinRadPerSec` 0.35) and pulses the core colour toward `CoreDimColor` (`CorePulseSeconds` 1.6, depth 0.6) on RenderStepped. A break shatters into chunks instead of splitting (`Effects.Break(..., nil, true)`, new `isWhole` argument). Rise, sink and hide carry the welded parts along.
- Stand distance: the template's `Rock` has attribute `ChopScale` = 6.5 (new `ChopConfig.ScaleAttribute`), so choppers stand about 52 studs from the centre, just outside the rim. Without it they'd stand at 92 / 10 x 8 = 74 studs. `Spawning.StandDistance` was unused and is gone.
- Checked in Edit with a preview copy on `DiamondSpot`: meshes load, Neon veins and heart glow, studs on the stone. Not playtested (rise, chop spots, label height, hit effects at this size, shard spin).

## Colossus VFX, first pass (2026-11-10, user picked "First pass, B1 hero" from `DiamondColossusVfxPlan.md`)
- **Heart halo (the hero):** `Assets.VFX.Diamond.VFX_Diamond_Heart`. Its `Heart` attachment is moved onto the `Core` part at setup (`addHeart`): `Halo` (soft cyan glow, about 55 studs), `Rays` (kit ray burst K0099, about 85 studs, turning slowly), `Motes` (rising sparkles) and `HeartLight` (cyan PointLight, range 60). The Core is opaque, so the sprites only show around its edge and through the gaps between the spires. `animateParts` pulses the light between `HeartLightMin` and `HeartLightMax` in step with the core colour.
- **Hit reaction (code):** each non-break hit calls `Kick`. The shards spin up to `KickSpinMultiplier` (3x) and ease back over `KickSeconds` (1 s), and the core and light flash white for `FlashSeconds` (0.15 s). A new hit restarts the kick, so 12 players don't stack strobes.
- **Hit impact:** `VFX_Diamond_Hit` (flash star, glow, a ring facing the player, crystal shards, sparkles) replaces `VFX_Diamond_Shards`. It's placed by `hitCFrame`: a ray from the camera toward the heart (at camera height, capped at the heart's height) onto the rock, so it lands on the slab in front of the player. The shared `Effects.Hit` still plays too.
- **Break:** `VFX_Diamond_Break` replaces `VFX_Diamond_Burst`.
  - 0-0.4 s, the charge-up (`ChargeSeconds`): `Charge` pulls the shard ring in (Shards MeshPart size down to `ChargeShardScale` 0.35), spins it fast and whites out the core, while a `Swell` glow grows.
  - At 0.4 s: the flash, a light pillar (a `Start`/`End` tween copied from the Ring's Column), 40 crystal chunks, sparkles, a ground ring, a tilted ring, dust and a big PointLight; the heart halo is removed; the shatter sound, `shakeCamera` and `Effects.Break` fire.
  - From 0.6 s: `Fallout` glints drift down over the arena for 4 s.
- **Beacon:** `BeaconTransparency` is 1, so the Neon cylinder is gone. The `Sheath` beam from `VFX_Diamond_Glow` is the beacon now.
- Textures are the project's existing uploads plus `Rays` = `assets/VFX/DiamondColossus/Flares_K0099.png`, uploaded 2026-11-10 as rbxassetid://116225784092446 (user approved).
- Checked in Edit only, on a stand-in Colossus: the halo, the break at 0.5 s and 0.9 s, and a hit from 60 studs. Not playtested. No showcase stand (the model is 100 studs).
- **Sunk into the floor (2026-11-10, user: "too much base, only like half of the base rock is needed"):** `DiamondRockConfig.SinkStuds` = 12 (the Diamond no longer uses `RockSpawnConfig.SinkStuds`), so about half of the stone ring shows and it looks like it's breaking out of the ground. The client's `groundCFrame(part)` (the part's bottom + `SinkStuds`) places the arrival ring, the glow base and the break effect on the floor. `VFX_Diamond_Break` has its `Heart` and `Tilted` attachments and `Pillar.Start` at Y 24 (36 - `SinkStuds`): change them if `SinkStuds` changes.
- **Vein haze and low health (2026-11-10, user picked "Low health + vein haze"):**
  - **Haze:** `VFX_Diamond_Veins` has 13 attachments, placed at the outer vein strips. The positions were read from the Veins mesh with EditableMesh and are local to the `Veins` part; if the model changes, rebuild them. Each attachment has a `Haze` emitter (soft cyan glow rising, Rate 1.2) and a `Fizz` emitter (tiny sparkles). `attachTemplate` moves the template's Root children onto the matching part at setup.
  - **Low health:** below `LowHealthRatio` (25% of `MaxHealth`), the heart pulses faster (`LowPulseSeconds` 0.6, phase carried over so it doesn't jump), and the Veins colour flickers toward `VeinDimColor` with noise. The haze rate goes up x`LowHazeRateMultiplier` (2.5), and `VFX_Diamond_Crumble`'s `Crumble` emitter (on `Crystals`, Box volume, falling crystal bits) turns on. The heart stays cyan (no pink shift). Emitter changes happen only when the state flips. At the break, every placed attachment and emitter is destroyed.
  - Checked in Edit only (haze and crumble seen on a stand-in rock). The flicker and pulse are code, so a playtest is still needed.
- **Chop snap after sinking (2026-11-10, user: "player gets placed in the ground when trying to chop"):** `ChopController` put the player on the rock's bottom, which is now 12 studs underground. The server sets `ChopConfig.GroundOffsetAttribute` ("ChopGroundOffset") = `SinkStuds` on the Diamond's `Rock`, and the snap adds it to the ground height. Any future sunk rock should set the same attribute.
- **Arrival, glow rescale, shard trails, big hits (2026-11-10, user: "just do 1, 2, 3, and 4"):**
  - **Arrival:** `RingKey` now points at `VFX_Diamond_Arrival` (the old `VFX_Diamond_Ring` template stays but is unused). It plays on the floor when the Colossus starts to rise:
    - cyan `Cracks` plus a dark `CrackScorch` twin grow to about 70 studs in 1.5 s and last 10 s;
    - a `GroundGlow`;
    - a grey `DustWall` (Rate 28, from 0.5 s to 1.7 s) and stone `Rubble` while it rises;
    - at 1.7 s, when the rise finishes (`ArrivalDelaySeconds` + `RiseSeconds`): a soft white heart flash, a glow, two ground shockwaves (to 240 studs) and a light.
    - `Effects.Rise`'s callback now also calls `shakeCamera`.
  - **Glow rescale:** in `VFX_Diamond_Glow`, the ground `Halo` is now 140 studs (it was 40, hidden under the stone), `BeaconRings` go from 36 to 12, and the `Sheath` beam is 18/6 wide.
  - **Shard trails:** `VFX_Diamond_ShardTrails` has 10 Top/Bottom attachment pairs, 4 studs apart, at the shard centres (read from the Shards mesh, local to `Shards`), each with a `ShardTrail` (0.7 s, cyan, FaceCamera). They're attached to the shard part, so the hit kick stretches them. Not seen moving in Edit: check them in the playtest.
  - **Big hits:** on a Perfect or Master hit, `VFX_Diamond_BigHit` plays at the same `hitCFrame`: a cyan crescent `Slash` (kit K0638, rbxassetid://95718059865237) with a white twin, 5 crystal `Chunks` and a glow. A Master hit also calls `shakeCamera`.
  - The STAR texture (97917584432190) shows a scatter of spiky clip-art stars when big, so the arrival and break `Flash` layers now use the soft glow in white.
  - Textures: the kit's K0099 (rays) and K0638 (slash), plus earlier project uploads. No preview addresses are left.

**Music (2026-11-11):** while it is out, players near the arena hear the boss fight music, 2 semitones higher under 25% health. See [[Boss Music]].

Since 2026-11-11 a crystal cavern set rises around it in the arena and sinks when it is removed (see [[Boss Arena]], `BossArenaController`).

## Health fix 2026-11-12 (user: "diamond rock hp bar doesn't work")
The boss bar was fine; the health was the problem. Each player's share used their best zone's top rock strength, about 25x a player who just reached the zone, so a solo late-game player needed about 290 Good hits and the bar barely moved. `shareOf` now uses `max(the player's strength, the zone's first rock)` x Good damage x `HealthChops` x `HealthShare`, the same base as the bosses (`BossService/Fight.Share`): about 16 Good hits per share. Pay per hit still divides by your own share, so dealing your share earns your full value.
