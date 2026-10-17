---
description: Neon floor rectangles in front of the Arm Shop and Geode shop stalls; standing in one opens that shop, walking off closes it. Replaced the shop ProximityPrompts on 2026-10-05.
type: system
---
# Shop pads

The user asked (2026-10-05) for both shops to open by proximity using a neon pad, orange for the Arm Shop and blue for the Geode shop, with a fading glow rising off it. This replaced the "Shop" / "Open" ProximityPrompts (and `ShopService`, which only made that prompt).

- Authored in Studio: a `ShopPad` Part inside each shop model (`Workspace.ArmShop`, `Workspace.GeodeShop`). Flat Neon block, 0.1 thick, as wide as the stall (14 studs, the awning) and 6 deep, on the floor 0.5 studs in front of the counter, Transparency 0.35, colour = the shop's stripe colour. Started as 8-stud circles; the user asked for stall-width rectangles the same day.
- Tag `ShopPad`. Attributes: `Screen` (UIController screen name: `Shop`, `GeodeStand`) and optional `ScreenKey` passed to the screen's `Open` (the geode key, `Forest`).
- The glow wall is a VFX template since 2026-10-16: `ReplicatedStorage.Assets.VFX.Shop.VFX_ShopPad` holds one `Wall` Beam (texture `WallBands`, rbxassetid://97523146716987, drawn by `assets/VFX/ShopPad/textures.py`: two bright bands on a 0.65-alpha strip; Wrap, TextureLength 4, TextureSpeed 0.625 scrolls them up; Transparency 0 to 1 fades it upward; LightEmission 0.6; `HeightStuds` attribute = 4). The user asked for the same look as the old code-animated beams, just as a VFX asset; the code no longer animates anything. Tune the look on the template, not in code.
- `src/client/Components/ShopPad.luau` clones that Beam once per side, tinted to the pad colour, and opens the screen when the character's root enters the rectangle (checked in the pad's local space) and closes it on leaving (1 stud of exit padding). Tunables in `ShopPadConfig`. Draft values, not yet approved.
- Reopening: if the player closes the shop while still standing on the pad, an "Open <ShopName>" prompt (the game's custom prompt style, E / tap) appears at the pad centre and reopens it. It is hidden while the shop is open or the player is off the pad. The user asked for this so they don't have to walk out and back in. The pad's `ShopName` attribute ("Arm Shop", "Geode Shop") is the prompt's object text.
- Pads so far: Arm Shop (orange, `Shop`), Geode Shop (blue, `GeodeStand`), Sell Shop (green, `SellShop`, added 2026-10-06, see [[Sell Shop]]), Aura Shop (red, `AuraShop`, added 2026-10-09, see [[Auras]]).
- To add a shop: put a tagged pad part in front of it with `Screen` and `ShopName` set; the colour comes from the part.
- `UIController:Open(name, argument)` passes `argument` to the screen's `Open`. `GeodeStand` reads its geode key from it.
- The Arm Shop model still carries the `ShopKiosk` tag and its invisible `ShopKiosk` part: the guide arrow (`GuideController/ArrowTrail`) points at it. The Geode shop doesn't have them.

Gotcha: a Beam with `FaceCamera = false` spreads its width along its attachments' **SecondaryAxis** (Y). For a vertical wall segment set the attachment CFrame with `CFrame.fromMatrix(position, outward, tangent)`; with Y pointing up the beam has zero width and is invisible.

Related: [[Stand Name Signs]], [[Geode Stand UI Reference]], [[Shop Stall Reference]]

## Shop menu button (2026-10-10)
The HUD "Shop" menu button now opens `RobuxShop` (a yellow, empty placeholder panel, `Screens/RobuxShop.luau`, copy of the Aura Shop panel). The Arm Shop opens only from its floor pad (`Screen = Shop`).
