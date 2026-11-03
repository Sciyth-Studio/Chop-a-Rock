---
description: 2026-11-01 - phone layouts removed, mobile locked to landscape, and every screen's UI scaled proportionally to a 1920x1080 PC screen (min of width and height ratio, no clamps) so phones look 1:1 with PC.
type: decision
---
# Proportional UI scaling, landscape only (2026-11-01)

The user said mobile UI scaling "still sucks". First they had it all scrapped and mobile locked to landscape, then asked to "scale the PC UI 1 to 1 with mobile".

Now:
- One layout on every device. The phone layouts are gone: the `MenuButtons` grid swap (`LayoutStore`/`PhoneLayout` deleted in Studio), the TeleportBar right-anchored layout, and the HUD touch dock.
- `StarterGui.ScreenOrientation` is `LandscapeSensor` (was `Sensor`).
- `Utils/ViewportScale.Compute` = `min(viewport.X / 1920, viewport.Y / 1080)` (`ScaleConfig.ReferenceWidthPixels` / `ReferenceHeightPixels`). There are no min/max clamps and no fit-to-screen. Every `ScreenScale` UIScale gets that factor, so pixel-sized UI takes the same share of the screen as on a 1080p PC. Factors: 1080p 1.0, the user's Studio viewport (1868x841) 0.78, iPad 0.61, iPhone landscape about 0.36, 1440p 1.33.
- The 43 `ScreenScale`s were deleted, then recreated at the same paths (StarterGui roots and `ChopPrompt.Root`). Old copies under `ServerStorage.UIBackup` are inert.

Known limit: a root frame's own Position offset (edge margins such as the toolbar's 12 px) isn't scaled, so margins are a little larger on phones than true 1:1.

Replaced (2026-10-21 system): short side / 600, clamped to 0.5-1 below 1080 and up to 2 above, plus fit-to-screen. Phones landed around 0.62-0.65, which is why the UI looked too big there.

## Edge-glued bars (2026-11-01)
The fade bars (Strength, Money, Friend Boost, weather, boost pills) left a gap at the screen edge on small screens. Their container's 16 px margin wasn't scaled, but the backdrop's -16 bleed was. Now a `ScreenScale` with the attribute `ScalePosition = true` (on `Hud.Container` and `WeatherPill.Container`) makes `ViewportScale.Bind` scale its frame's Position offsets too, so margin and bleed cancel at every scale. BoostPills scales `EdgeOffsetPixels` in its own `place()`. Use `ScalePosition` only on frames whose Position no code sets.

Same day: the Shop, Index and Rebirth menu buttons went to 1.5x (144 px, container 144x648) and the toolbar's Pets toggle to 156 px, with sizes, offsets and strokes scaled in Studio. 2x was tried first and the user called it overkill.

## Offer rail and menu column (2026-11-01)
- `ScreenScale` takes an optional number attribute `ScaleMultiplier` that `ViewportScale.Bind` multiplies into the screen factor. `OfferRail.Container` has 1.5, because the user wanted the purchasables bigger on phones ("i need money"). Use it instead of resizing parts when the screen's code has pixel constants.
- `OfferRail.Container` is anchored (1, 0.5) at (1, -16, 0.5, -90) and its list is centre-aligned. The -90 nudge was asked for so it clears two active boost pills. `MenuButtons.Container` is anchored (0, 0.5) at (0, 18, 0.5, 0) and its grid is centre-aligned. Both have `ScalePosition`, so the two columns sit at mid-height on every screen.
- With an offer card and both boosts showing, the rail runs from y about 51 to 849 at 1080p. Two boost pills reach up to y 852; a third or more still overlaps.
