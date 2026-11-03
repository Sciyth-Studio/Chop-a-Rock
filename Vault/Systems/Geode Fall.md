---
description: Geode Fall - server-wide event, one geode per player (max 4) crashes into zones players have reached; since 2026-11-03 the first to press Take gets a Falling Geode item (Rare or better), no chop and no fight; where state lives, pickup and anti-teleport rules, admin commands.
type: system
---
# Geode Fall

Design and approval: [[Geode Fall Event]]. All numbers are drafts in `GeodeFallConfig`.

## Rules as built
- **Timer (since 2026-10-29):** rolled by the [[Event Clock]]. **Zones:** each geode picks a random zone that some non-tutorial player in the server has reached (`PeakStrength` at least the zone geode's `StrengthRequired`, `Spawning.EligibleZones`). Notices name the zone, or "N zones" (`ManyZonesText`). Count `BaseCount` 6 to `MaxCount` 8. Before that: every 20-25 min. Skipped (retry in 30 s) while weather is on, when the next weather would start before the fall ends (`WeatherService:SecondsUntilNext`), while a Diamond Rock is out, or within 2 min after one (`DiamondRockService:IsActive` / `SecondsSinceEnded`). Admin starts ignore these checks. A Diamond Rock can still spawn during a fall; its pill sits at y 130 and the Geode Fall pill at y 190, so they don't overlap.
- **Zone and count:** weighted by players (not in the tutorial) standing in zones that have a `GeodeConfig` geode. Count 3, +1 per 4 players above 4, max 5 (`Spawning.Count`).
- **Timeline:** warning notice + pill countdown (10 s). 2 s before landing the server parents the geodes; clients hold them 220 studs up, play `VFX_GeodeFall_Marker` (an orange ring closing in on the spot), then drop them over 1.2 s wearing `VFX_GeodeFall_Meteor` (cel fire, smoke trail, embers, glow). On landing: `VFX_GeodeFall_Impact`, the cannon landing sound and a camera shake. Landed geodes get `VFX_GeodeFall_Idle` (zone-coloured glints, rising motes, ground glow, a little smoulder, a 160-stud textured light pillar, a small light) and a "Falling Geode" / "Name's Geode" label with health bar and m:ss, plus a Chop prompt. The idle effect and label go the moment a geode is cracked or times out (`LandTrove`); 90 s after landing the rest sink.
- **VFX (2026-10-20, user: hero = meteor impact; palette = fiery meteor + zone crystals):** templates in `Assets.VFX.GeodeFall`, all built with `Build` from cleared reference textures (no uploads): cel fire sheets 11395089850 / 11395090403 / 11395118687 (orange baked in, never tinted), dark smoke 10180479311, embers 8068783649, glow 8708637750, rock bits 8132607319, star 3052949762, ring 4609193944, pillar beam 3029306948, and our Diamond flash 137739014780004, shards 75840693106402 and cannon ring 86973755749304. Zone colour goes only on layers with the `ZoneTint` attribute (crystals, glints, motes, ground glow, pillar, light), placeholder purple in the templates. Impact layers: flash body + flare (0-0.12 s), fire bursts and a fire column (to ~0.8 s, growing), ground shockwave, zone crystals and glints, rock bits, embers, warm-to-grey dust (to ~2 s), dark smoke, orange light. Showcase stand "Geode Fall Impact" at Z -131 in the Chop row. Checked held frames at 0.04, 0.35 and 1.0 s from 40 studs in Edit; idle checked once (light and pillar). Not yet seen at full speed or in Play.
- **Landing height (fixed 2026-10-20):** geode models pivot at their base (PivotOffset -2.64), so the server places the pivot at ground - `SinkStuds`; it used to add half the height and the geodes hovered. The hatch spot uses the pivot too.
- **Spots:** `RockService:FindRingSpot` with a filter: at least 40 studs from every part in `Workspace.TeleportPoints` (Rocks, shops, cannon landings) and 30 studs from other geodes in the fall. Each geode reserves its own area (`ReserveArea(owner, ...)`, owner `GeodeFall<id>`).
- **Picking up (2026-11-03, user):** a Take prompt, no chop and no fight. The first press wins; the geode sinks for everyone (`GeodeFallTaken`). The server checks range, not chopping or fighting, the tutorial, the anti-teleport flag, Strength at least the zone geode's `StrengthRequired` and bag room. A full bag or too little Strength leaves the geode for someone else.
- **Reward:** one `Falling<Zone>` geode in `data.Geodes` (`GeodeOrder.FallingKey`), built in `GeodeConfig` next to the Lucky keys, `IsFalling` keeps it out of `GeodeOrder.Sorted`. It has the zone's Pets and hatch time with `MinRarity` Rare (`FallingMinRarity`). It's placed and opened on a hatch pad like any geode, so luck and weather apply when you open it, and Legendary and Secret pulls are announced by `Opening`.
- **Full bag:** `GeodeService:HasBagRoom` (Pets + geodes + filled pads under the Backpack size) refuses the pickup with "Bag full! Sell Pets". The geode stays until it times out.
- **Anti-teleport:** every 0.25 s during a fall the server samples each root. A horizontal step over WalkSpeed x 1.5 x dt + 12 studs flags the player for 5 s, and their pickups are ignored. Exempt: cannon flights (`CannonService:IsLaunching`, `Landed`), the teleport bar (`TeleportService` calls `GeodeFallService:AllowMove`), respawns, being launched by an enemy. Admin warps are not exempt.

## Where things live
- Server: `GeodeFallService` (`init` timer, pickup; `Spawning` zone, count, spot filter, model, attributes; `Movement` anti-teleport; `Types`). Model `Workspace.FallingGeode` (Persistent, tag `GeodeFall`), attributes on its part: `GeodeFallId`, `Zone`, `LandsAt`, `EndsAt` (server time). Workspace attributes for the pill: `GeodeFallZone`, `GeodeFallLandsAt`, `GeodeFallEndsAt`, `GeodeFallLeft`, `GeodeFallTotal`.
- Packets: `GeodeFallTake(id)` request, `GeodeFallTaken(id)` to all.
- Client: `RockController/GeodeFall.luau` (fall, marker, trail, landing, beacon, label, prompt, sink). `Screens/GeodeFallPill` reads the workspace attributes.
- Studio: `StarterGui.GeodeFallPill`, a copy of `DiamondRockPill` at y 190, 640 wide, purple text (made 2026-10-20 through the MCP; save the place). The label reuses `UI_DiamondLabel` repainted in the zone colour. Effects: `Assets.VFX.GeodeFall.VFX_GeodeFall_{Meteor,Marker,Impact,Idle}` (registered in `AssetRegistry`); sounds reuse `SFX_Cannon_Whoosh` / `SFX_Cannon_Land`.
- Also changed: `RockService` reserves several areas at once (`ReserveArea(owner, zone, position, radius)`, `ReleaseArea(owner)`; the Diamond Rock passes `DiamondRock`) and `FindRingSpot` takes an optional spot filter. `TutorialConfig.HiddenScreens` hides the pill.
- Admin: "Start Geode Fall" (Ctrl+Shift+F, your zone or the busiest; alias `geodefall`) and "Geode Fall: 10s Left" (alias `geodefallend`).

## Checked
`check.ps1` passes (format, types, build). Not playtested yet (the user tests).

## Open
- Not measured in the [[Balance Model]] yet.

## Feedback 2026-10-20 (first playtest)
"the geodes don't land on the ground (they hover)", "the vfx are lacking", "the beacon and ui timer don't despawn properly". Fixed: landing height (pivot at the base), effects remade as the four templates above, beacon/label cleared on crack or timeout instead of when the model goes 12 s later.

Related: [[Geode Fall Event]], [[Diamond Rock]], [[Geode Shop]], [[Hatch Reveal Reference]], [[Admin Panel]]

## Change 2026-11-03 (user)
Count is one geode per player in the server, capped at 4 (`MaxCount`). Each geode sends its own "Geode falling in <zone>!" notification, identical ones stack as x2; one "landed" line follows. The `GeodeFallPill` timer is gone.

## Change 2026-11-03: pickup (user)
See [[Geodes As Inventory Items]]. Not played yet. The label's health bar is hidden in code (the `UI_DiamondLabel` template is shared with the Diamond Rock); the label shows only "Falling Geode" and the time left.
