---
description: Three top-centre buttons (Base, Shops, Rocks) that teleport the player, 60% of screen width; TeleportService, TeleportConfig, Workspace.TeleportPoints markers (built 2026-10-10, colours and cooldown are drafts).
type: system
---
# Teleport bar

Requested 2026-10-10. Three buttons in a row at the top centre of the screen, in the striped gradient header look with the `Chrome` text: Base (green 0,170,40 / 130,255,130), Shops (blue 0,110,255 / 130,205,255), Rocks (orange 255,120,0 / 255,200,110). Colours and the cooldown are drafts.

## Client
- `StarterGui.TeleportBar.Container` (anchor 0.5,0, y 12, size 0.336 scale wide (`TeleportConfig.BarWidthScale`; 0.42 until 2026-10-14, when the user asked for 20% skinnier buttons) with a `UIAspectRatioConstraint` 6.32 (was 7.9; height unchanged, about 99 px at 1868 wide), `ScaleWithParentSize`, no `ScreenScale`) holds `BaseButton`, `ShopsButton`, `RocksButton` (0.32 wide each, 2% gaps). Each is a black frame with a 3px `OuterStroke` (same as the HUD menu buttons), an inset `Track.Fill` (gradient, `StudTexture`, `Stripes`: same assets and 0.8 transparency as the panel headers), `InnerBorder`, `Label` + `LabelShadow` (`Chrome`, TextScaled, 3px stroke, max 60) and an invisible `Button` TextButton. Gradients are saturated: green 0,160,30 to 0,235,60, blue 0,90,235 to 0,170,255, orange 235,85,0 to 255,160,0.
- `Screens/TeleportBar.luau` (non-modal, StartsOpen) fires `Packets.Teleport(id)` on click, with a client-side debounce of `CooldownSeconds` (clicks inside it are ignored). Desktop: centred, 33.6% wide. On touch or a short side under 600 it anchors right (16 px margin) and caps the width to the space right of the phone menu buttons. It moves `DiamondRockPill.Container` to just under the bar (`PillGapPixels`). Phone layout is verified by arithmetic only.
- `ChopController` closes the bar during the chop minigame, the same way it closes `ExpBar`, because `ChopMeter.HealthBar` sits in the same top-centre spot (y -20, 45% wide).


## Server
- `TeleportService` handles `Teleport` (rate limit 6 per second). It checks the destination id, data loaded, character alive, a hatch reveal not playing (`GeodeService:IsRevealing`, the geode lock) and the per-player cooldown (`TeleportConfig.CooldownSeconds`; only successful teleports start it).
- Before moving it ends every activity the way leaving does: `RockService:EndSession`, `DiamondRockService:EndSession`, `GeodeService:EndSession`, `TrainingService:Stop` (releases the walk-speed freeze and jump lock) and fires `ChopEnded` so the client closes the minigame and releases its `MovementLock`.
- Then it calls `player:RequestStreamAroundAsync(destination, StreamTimeoutSeconds)` in a `task.spawn` (StreamingEnabled is on; never block the move on it) and `PivotTo(target.CFrame * (0, Size.Y/2 + HipHeight + root half height, 0))`, so the player faces the marker front. Measured in Studio: click to arrival about 0.17 s for all three. Slow teleports on live servers come from streaming the far area in; the server path itself never yields.
- Base: `BaseService:GetSpawn(player)` (the plot's `BaseSpawn`). Shops and Rocks: parts in `Workspace.TeleportPoints`.

## Markers (`Workspace.TeleportPoints`)
Invisible, anchored, no collide/touch/query, not tagged `EditorOnly` (code reads them from Workspace). 4 x 0.2 x 4, top flush with the lobby floor (y 1.0).
- `Shops` at (42, 0.9, -334) facing -Z, ten studs in front of the shop pads (pads end at z -342.2). Moving the shops means moving this.
- `Rocks` at (42, 0.9, -205) facing +Z: lobby side of the forest gateway (`ZoneEntrance` at z -195). Always the forest, never a later zone.

Related: [[Admin Panel]], [[Bases]], [[Forest Zone Entrance]], [[Menu Panel Style]]
