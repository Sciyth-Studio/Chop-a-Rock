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

- Menu buttons live in `StarterGui.MenuButtons.Container`, a vertical list at left-center. The hidden frame `MenuButtonTemplate` holds the style: duplicate it, rename it `<Name>Button`, set `Visible = true` and a `LayoutOrder`, and add `{ Name, Screen }` to `MenuButtonConfig.Buttons`. `MenuButtons.luau` wires the click to `UIController`.
- Style: 96x96 square with sharp corners, black background with a horizontal `UIGradient` (transparency 0.3 at both edges, 0.6 in the center). A child frame named `InnerBorder` (size 1,-6 by 1,-6, transparent, `ZIndex` 1) carries a white `UIStroke` (3px, 50% transparent, `Border` mode); the stroke draws outward, so the inset keeps its outer edge flush with the box. The icon is a 78px `ImageLabel` named `Icon`, centered in the upper part and allowed to overflow the box, with a black copy named `IconShadow` behind it (82px, offset 4px right and 6px down from the icon center, 40% transparent). Set the same `Image` on both.
- The label is bottom-anchored, non-italic, `Chrome` text style (attribute `TextStyle`, gradient and grey stroke, 2px thick). Short words such as SHOP and BAG use a 0.4 label height so the text is larger; long words are limited by the width. The invisible `TextButton` named `Button` covers the frame and receives the click.
- Current buttons, top to bottom: `ShopButton`, `BagButton`, `RebirthButton`. Icon asset ids live in `IconConfig`.
