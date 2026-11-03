---
description: Free geodes spawning anywhere in each zone (since 2026-11-03), 4 per player per zone, new one 30 s after a pickup; server data, client draws; going for one calls EnemyService:RequestFight, then GeodeService:GrantGeodes. Not playtested.
type: system
---
# Zone geodes

Step 5 of `ZoneGeodesPlan.md`, the spawning half ([[Zone Geodes And Enemies]]). Not playtested. The numbers below are drafts.

## Studio
- **Ring markers:** one flat cylinder part per zone, `Workspace.Zones.Zone<Name>.ZoneGeodeRing`, tagged `ZoneGeodeRing`, with `Zone` = the zone key. Orange and half transparent in Studio, hidden by the server at start. CanCollide, CanQuery and CanTouch are off.
- **The user can move or resize them.** They are read at server start (`Utils/ZoneRings`), so a change applies on the next Play. Radius = the part's largest size / 2. The ring is now only the enemy's home and a space rocks stay out of; geodes no longer stay inside it.
- Radius is 30 x the zone scale: Forest 30, Desert 35, Jungle 40, Ocean 46, Snow 52, Swamp 60, Savanna 69, Bamboo 80, Volcano 92, Ruins 106.
- Most rings sit a little off the zone's centre, so no collidable floor decor is inside them. No decor was moved.

## How it works
- `RockService/SpawnPoints` samples rings along with rocks. A rock kind's spot is dropped if the rock would touch a ring (spot within ring radius + rock radius). Strips by distance from `ZoneEntrance` are unchanged, measured over the spots that remain. Diamond Rock and Geode Fall spots (`FindRingSpot`) stay out of rings too.
- Every grid point in the zone's `RockSpawnArea` with room for a geode becomes a geode spot (`RockService:GetGeodeSpots(zone)`). Room means nothing in a box of `ClearanceSize` x zone scale, non-collidable parts included, so walls, decor and steep ground are all avoided. The `[RockService] <Zone>: N spawn spots, M geode spots` lines show them.
- `ZoneGeodeService` keeps each player's geodes as server data, sent only to that player (`ZoneGeodeSpawned`, `ZoneGeodeRemoved`). `ZoneGeodeController` draws them and adds the prompt. Nothing is saved: geodes come back on rejoin.
- Spots avoid the inner 35% of the ring (the enemy's home), keep 30 studs x zone scale between a player's geodes (draft, was 10), 6 studs from the player, and clear of that player's rocks (`IsClearOfRocks`). Each geode also blocks its spot for that player's new rocks only (`RockService:BlockSpot`, `UnblockSpot`).
- Taking one (`ZoneGeodeTake`) checks range, not busy chopping, the tutorial, Strength at least the zone's weakest rock ("Get stronger!") and bag room, then calls `EnemyService:RequestFight`. "Won" or "Fled" grants through `GeodeService:GrantGeodes(player, zone, 1)`, rechecking bag room.
- Bag rule: `GeodeService:HasBagRoom`: Pets + `data.Geodes` + entries in `data.HatchPads` must stay under the Backpack size.
- Looks: `ZoneGeodeConfig.Zones[zone].Looks` lists 2 model keys per zone, picked at random per spawn. Both are the zone's old geode model until the 20 look models exist. Purely visual.
- Admin: "Spawn Zone Geode" (Events tab, `zonegeode`) puts one in front of you, in the zone you're standing in. It can go over the 4; no replacement spawns until the zone drops below 4.

## Temporary or unfinished
- `ZoneGeodeConfig.GrantWithoutEnemyService = true`: while `EnemyService` isn't registered, taking a geode is an instant win. Set it to false once enemies are merged (it does nothing then anyway, since the service exists).
- **Zones 6-10 have rings but no geodes:** they have no `GeodeConfig` entry or models. To add one: `GeodeConfig` entry plus a `ZoneGeodeConfig.Zones` line.
- **Tutorial:** geodes can't be taken while the tutorial runs (server check in `onTake`, prompt check in the controller). The new "Get Geode" tutorial step must lift both.
- **Look isn't saved:** `GrantGeodes` takes only a key, so the look a player picked up doesn't reach the bag or `HatchPads[slot].Look`.

Related: [[Rock Spawning]], [[Zone Line]], [[Admin Panel]], [[Geode Shop]]

## Checked 2026-11-03
In Edit, sampling every third grid point of Forest, Desert and Snow with the same box: 93-95% of points are clear (218/234, 210/221, 222/234), and every blocked point hit decor (Bush, Pine, Cactus, SnowPine and similar). Not played: the enemy's charge from far across a zone is untested, and it covers any distance in 1.2 s (`ChargeSeconds`), so it may need a longer run in the larger zones.

Related: [[Geodes As Inventory Items]]
