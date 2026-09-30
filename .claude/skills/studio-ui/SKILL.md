---
name: studio-ui
description: Use when creating, restyling or editing any player-facing UI or world-space text in this Roblox game (HUD, screens, billboards, prompts, notifications, meter). Covers the house text style rules, the named TextStyle system, and how UI is authored in Studio.
---

# Studio UI for Chop a Rock

## Authoring rules

- Author UI in Studio through the Roblox Studio MCP (`execute_luau` in the Edit datamodel). Code finds elements by name and checks the class with `IsA`; a missing element must warn and disable that piece, never error.
- Screens live in `StarterGui` and are driven by a module in `src/client/Controllers/UIController/Screens/`. World UI templates (RockLabel, ChopPrompt, etc.) live in `ReplicatedStorage.Assets.VFX` and are fetched through `AssetRegistry`, never by path.
- Studio edits are not in git. Tell the user to save the place file after UI changes.
- Studio must be stopped (Edit mode) before editing UI. If `execute_luau` says the Edit datamodel is unavailable in Play mode, stop play with `start_stop_play` (`is_start: false`) first.
- After changing files on disk, wait a few seconds in Edit mode for Rojo to sync before starting Play; edits made during Play are not applied until it stops.
- Do not add comments to code. Keep tunable numbers in `src/shared/Config`.

## House text style

- Default to a colored stroke and a gradient text fill, on a white-based TextLabel: base `TextColor3` white, a vertical `UIGradient` (rotation 90: darker edges, lighter center), and a `UIStroke` in a dark shade of the same hue.
- Use plain white with a black stroke, or a plain black stroke, only when the user explicitly asks for it.
- Colors default to max saturation unless the user says otherwise.
- Use the font from `FontConfig`; `Typography.Apply(root)` sets it (screens get it from `UIController`, world templates call it themselves). Set the boolean attribute `Italic` on a label for the italic variant.

## Named text styles

- Named styles live in `src/shared/Config/TextStyleConfig.luau`: `Chrome` (light grey to white, grey stroke; used above rocks, prompt rock name and key, training hint, non-Perfect meter results), `Gold` (orange to light yellow, brown stroke; titles) and `Sky` (blue to light blue, navy stroke; shop names and info).
- To use one: give the label a `UIGradient` and a `UIStroke`, then set the string attribute `TextStyle` to the style name. `Typography.Apply` applies the colors on load; `Typography.ApplyTextStyle(label, name)` applies one at runtime.
- To add a style, add an entry to `TextStyleConfig.Styles`; do not hardcode gradient colors on individual labels.
- Do not put a gradient on a TextButton whose background is visible; the gradient also tints the background. Use a colored text stroke instead.

## Other UI conventions

- Backgrounds behind HUD text are black gradients that fade out toward the end of the number.
- The chop meter is an empty rounded bar whose fill uses a gradient anchored to the bar and fills through the five quality colors; Perfect result text keeps its rainbow.
- Notifications are black gradient bars with `Chrome`-style text; kinds and timings are in `NotificationConfig`.

## Menu buttons

- Menu buttons live in `StarterGui.MenuButtons.Container`, a vertical list pinned to the left edge at 45% of the screen height (anchor 0,0.5). The hidden frame `MenuButtonTemplate` holds the style: duplicate it, rename it `<Name>Button`, set `Visible = true` and a `LayoutOrder`, and add `{ Name, Screen }` to `MenuButtonConfig.Buttons`. `MenuButtons.luau` wires the click to `UIController`.
- Style: 96x96 square with sharp corners, black background with a horizontal `UIGradient` (transparency 0.3 at both edges, 0.6 in the center). A child frame named `InnerBorder` (size 1,-6 by 1,-6, transparent, `ZIndex` 1) carries a white `UIStroke` (3px, 75% opaque, `Border` mode, `LineJoinMode` Miter so the corners stay sharp); the stroke draws outward, so the inset keeps its outer edge flush with the box. The icon is a 78px `ImageLabel` named `Icon`, centered in the upper part and allowed to overflow the box, with a black copy named `IconShadow` behind it (82px, offset 4px right and 6px down from the icon center, 40% transparent). Set the same `Image` on both.
- The label is bottom-anchored, non-italic, `Chrome` text style (attribute `TextStyle`, gradient and grey stroke, 2px thick). Short words such as SHOP, BAG and INDEX use a 0.4 label height so the text is larger; long words are limited by the width. A copy named `LabelShadow` sits behind it (black, 40% transparent, offset 2px right and 3px down, own 2px black stroke, no gradient or `TextStyle`); set the text on both. The invisible `TextButton` named `Button` covers the frame and receives the click.
- Current buttons, in order: `ShopButton`, `BagButton`, `IndexButton`, `RebirthButton`. Icon asset ids live in `IconConfig`. To upload an icon, copy the PNG to a scratch folder, serve it over a temporary local HTTP server (`upload_image` only accepts http(s) URLs), upload, then stop the server. Python may be only a Store stub, so use Node.
- Phone layout: when the screen's short side is under `PhoneMaxShortSidePixels`, `MenuButtons.luau` swaps the container's `UIListLayout` for the `UIGridLayout` named `PhoneLayout` (2 columns) and resizes the container. Both layouts are parked in the `LayoutStore` folder. Never park a layout object directly in a ScreenGui: it lays out that ScreenGui's children and collapses the container. The layout swap and scaling run only while the game is playing, not in Edit mode or the Edit-mode device emulator.

## Scaling and shadows

- Screens shrink on small screens with a `UIScale` named `ScreenScale` on the screen's root frame (`Hud.Container`, `MenuButtons.Container`). `ViewportScale.Bind(gui, trove)` in a screen module drives it: scale is the short side divided by `ScaleConfig.ReferenceShortSidePixels`, clamped to `MinScale`..1. Add a `ScreenScale` to a root frame and call `Bind` to opt a screen in. World-space billboards are not covered by it.
- HUD rows have shadows: `IconShadow` (black icon copy, 68px, about 3px right and 4px down) and `<Label>Shadow` (black label copy next to the real label, offset 2px right and 3px down). `Hud.luau` keeps the shadow text in sync through `setText` and `HudConfig.ShadowSuffix`; a missing shadow is skipped. The HUD `ZIndex` order is backdrop 1, shadows 2, outlines and labels 3, icon 4.
