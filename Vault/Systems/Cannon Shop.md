---
description: Lobby Cannon Shop (built 2026-10-20) - one cash cannon per zone from the desert on, strength-gated; owned cannons kept through rebirth, one equipped; the lobby cannon fires you on a ~2 s arc to the equipped zone's entrance, or opens the shop when none is equipped. CannonService, CannonController, CannonConfig, Screens/CannonShop.
type: system
updated: 2026-10-20
---
# Cannon Shop

Spec: [[Cannons And Auras Replace Arms]]. Built 2026-10-20 with placeholder models; the real stall, lobby cannon and per-zone cannon models come from `model-workflow`.

## Config (`CannonConfig`, all drafts)
| Cannon | Strength | Price | Colour | Marker |
|---|---|---|---|---|
| Desert | 500 | $80K | 255,170,0 | `TeleportPoints.CannonDesert` |
| Jungle | 62,500 | $5.1M | 0,210,40 | `CannonJungle` |
| Ocean | 7.81M | $328M | 0,90,255 | `CannonOcean` |
| Snow | 976.56M | $21B | 140,220,255 | `CannonSnow` |
Strength = the zone's first rock; price = about 25 of its chops. Matches the Config and Payback tabs of [[Balance Model]] v7 (each cannon costs 3 to 6 min of income in the zone before it). Flight 2 s, arc height max(60, 25% of distance), cooldown 3 s, prompt range 10. No-cannon colour grey 120.

## Data and server
- `PlayerData.Cannons` (`{ [key]: true }`) and `EquippedCannon` (`""` = none). Kept through rebirth (user, 2026-10-20). In admin snapshots.
- `CannonService`: `Buy` (not owned, strength and cash checked on the server, then equips it), `Equip(key)` (`""` unequips; must own), `SetOwned` (admin), `IsLaunching`, `Find`. Packets `BuyCannon(key)`, `EquipCannon(key)`.
- Launch: the service puts a "Fire / Cannon" custom-style ProximityPrompt on `Workspace.LobbyCannon` (at `PromptAnchor`, else the PrimaryPart). Triggered with nothing equipped: notification "Buy a cannon to fire!" + `CannonEmpty`, and the client opens the shop (user's pick 2026-10-20). Otherwise it checks alive, not revealing a hatch, not already flying, cooldown, ends every activity through `TeleportService:EndActivities`, streams the destination in, fires `CannonLaunch(start, end, height, seconds)` to the owner and after the flight `PivotTo`s the character onto the marker (server-authoritative landing). `TeleportService` refuses teleports while a flight is running.

## Client
- `CannonController`: flies the local character along a parabola (PlatformStand, `MovementLock`, root CFrame and velocity set every PreSimulation; the default camera follows), lands facing the travel direction. Tints every BasePart in `LobbyCannon` with the attribute `ZoneTint = true` to the equipped cannon's colour (grey when none), locally per player.
- `Screens/CannonShop.luau` + `StarterGui.CannonShop` (a copy of the Aura Shop panel, orange header, title "Cannon Shop"). Rows `Cannon<Key>` from the same `RowTemplate`: button reads "<N> Strength" (grey) until strong enough, then the price (green if affordable, grey if not), then "Equip" / "Unequip" (orange, `ColorGlow` on the equipped one). Icon tinted by the cannon colour; **still the aura icon** until a cannon icon exists. The header icon is also still the aura one.
- Opened by the `ShopPad` in `Workspace.CannonShop` (`Screen = CannonShop`, `ShopName = Cannon Shop`, orange).

## World (placeholders, Studio)
- `Workspace.CannonShop`: copy of the Aura Shop stall at x 74 (right of the Aura Shop), recoloured orange, sign "Cannon Shop" (Gold), no shopkeeper.
- `Workspace.LobbyCannon` at (94, -275): grey `Base` block with a `PromptAnchor` attachment, cylinder `Barrel` (`ZoneTint`) aimed up toward +Z with a `Muzzle` attachment at the tip.
- Markers `TeleportPoints.Cannon<Zone>` at x 42, 14 studs inside each zone's near edge (z -13, 155, 323, 491), y 0.9, facing +Z.

## What the real models must provide
- Lobby cannon: a Model named `LobbyCannon` directly in Workspace; parts to recolour per zone carry the boolean attribute `ZoneTint`; an Attachment (or part) named `Muzzle` where the player leaves; an Attachment or part named `PromptAnchor` for the prompt (else the PrimaryPart). Set `ModelStreamingMode` Persistent or Atomic so clients get the whole model.
- Stall: a Model with a `ShopPad`-tagged part, `Screen = CannonShop`, `ShopName = Cannon Shop`. Name it `CannonShop` to match the others.
- Per-zone cannon models aren't read by code yet; a shop row preview or the lobby cannon swapping models per zone would be new work.

## Tested in Play (2026-10-20, by value)
Empty cannon opens the shop; buying through the real button at 600 strength / $100K equips Desert and turns the barrel 255,170,0; the flight peaks about 72 studs and lands on `CannonDesert` after 2 s, PlatformStand off, walk speed back. Jungle buy refused under strength, equipping an unowned cannon refused, unequip turns the barrel grey. Not seen on screen: the arc, camera, shop panel look.

User tested it 2026-10-20: "it tested fine". Panel restyle inspo: [[Cannon Shop UI Reference]].

Related: [[Auras]], [[Shop Pads]], [[Teleport Bar]], [[Admin Panel]], [[Balance Model]]
