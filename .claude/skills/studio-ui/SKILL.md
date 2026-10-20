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
- Every UI header title (panel and menu headers) uses the `Chrome` style with a 4px black stroke and a `TitleShadow` copy. Body and button text in the studded panel style is plain white with a black stroke (see the vault's Studded Panel Style Reference).
- No all-caps text ("Rebirth", not "REBIRTH"); see the vault's No All Caps In UI.
- Use the font from `FontConfig`; `Typography.Apply(root)` sets it (screens get it from `UIController`, world templates call it themselves). Set the boolean attribute `Italic` on a label for the italic variant.

## Named text styles

- Named styles live in `src/shared/Config/TextStyleConfig.luau`: `Chrome` (light grey to white, black stroke since 2026-10-05; used above rocks, prompt rock name and key, training hint, non-Perfect meter results), `Gold` (orange to light yellow, brown stroke; titles), `Sky` (blue to light blue, navy stroke; shop names and info), `Red` and `Orange` (Aura and Cannon Shop stall signs), `Strength` (orange; all strength text) and `Green` (money green).
- To use one: give the label a `UIGradient` and a `UIStroke`, then set the string attribute `TextStyle` to the style name. `Typography.Apply` applies the colors on load; `Typography.ApplyTextStyle(label, name)` applies one at runtime.
- To add a style, add an entry to `TextStyleConfig.Styles`; do not hardcode gradient colors on individual labels.
- Do not put a gradient on a TextButton whose background is visible; the gradient also tints the background. Use a colored text stroke instead.

## Other UI conventions

- Buttons use the block style (2026-10-15, the one button style): dark outline-colour background, `Track` inset 4px holding `Fill` (gradient light top to edge bottom, studs) plus `Bevel` and `Lip` (with `Highlight`), 3px black `OuterStroke`, sharp corners. Paint state colours only with `Utils/BlockButton.Paint(fill, colors)`, never by setting the gradient by hand. Full spec in the vault's Tile Style Reference.

- Backgrounds behind HUD text are black gradients that fade out toward the end of the number.
- The chop meter is an empty rounded bar whose fill uses a gradient anchored to the bar and fills through the five quality colors; Perfect result text keeps its rainbow.
- Notifications are black gradient bars with `Chrome`-style text; kinds and timings are in `NotificationConfig`.

## Menu buttons

- Menu buttons live in `StarterGui.MenuButtons.Container`, a vertical list pinned to the left edge at 45% of the screen height (anchor 0,0.5). The hidden frame `MenuButtonTemplate` holds the style: duplicate it, rename it `<Name>Button`, set `Visible = true` and a `LayoutOrder`, and add `{ Name, Screen }` to `MenuButtonConfig.Buttons`. `MenuButtons.luau` wires the click to `UIController`.
- Style (tile pilot, 2026-10-15; full spec in the vault's Tile Style Reference): 96x96, sharp corners (never `UICorner`), everything at `ZIndex` 0. Tile background transparent with a 3px black `OuterStroke` (`Border`, Miter); its old `UIGradient`, `StudTexture`, `ColorGlow` and `InnerBorder` are off. `Track` (full size, transparent) holds `Fill` (the button's own colour, vertical `UIGradient` from 0.3 transparency at the bottom to clear at the top, filling the tile up to the outline). `Shade` sits above it: plain black at 0.5, inset 3px (1,-6 by 1,-6). A new button sets its own `Fill` colour. The icon is a 64px `ImageLabel` named `Icon` at 0.5,0 / 0.42,0, inside the tile, with a black copy named `IconShadow` behind it (67px, offset 3px right and 4px down, 40% transparent). Set the same `Image` on both.
- The label is bottom-anchored, non-italic, `Chrome` text style (attribute `TextStyle`, gradient and black stroke, 3px thick). Short words such as Shop, Roks and Index use a 0.4 label height so the text is larger; long words are limited by the width. A copy named `LabelShadow` sits behind it (black, 40% transparent, offset 2px right and 3px down, own 3px black stroke, no gradient or `TextStyle`); set the text on both. The invisible `TextButton` named `Button` covers the frame and receives the click.
- Current buttons, in order: `ShopButton`, `RoksButton` (opens the Roks pedestal panel; was `BagButton`), `IndexButton`, `RebirthButton`. Icon asset ids live in `IconConfig`. `IndexButton` has a red `Badge` (shown while index rewards wait, driven by `MenuButtonConfig.IndexBadge`): 34px, white background with a red `UIGradient` 255,0,0 to 190,0,0, 3px maroon 77,13,13 stroke, centre anchor; `Mark` shows `Symbol` ("!", no count since 2026-10-15) in `Chrome` with a 3px black stroke. Every `WiggleEverySeconds` (3) it swings through `WiggleDegrees` while visible.
- New icons: `upload_image` uploads to the user's personal account, and those images do not load in the group-owned game. Ask the user to import the PNG through Studio (it lands in the group) and give you the id. Check it loads with `ContentProvider:PreloadAsync` (status `Success`).
- Compact layout: when the preferred input is touch or the screen's short side is under `PhoneMaxShortSidePixels`, `MenuButtons.luau` swaps the container's desktop `UIGridLayout` (`GridLayout`, one column; a grid since 2026-10-14 so hover grow doesn't push neighbours, see the vault's UI Feel) for the `UIGridLayout` named `PhoneLayout`, sets its `FillDirectionMaxCells` to `PhoneColumns` (4, one row), moves the container to `PhoneTopPixels` from the top and resizes it. Both layouts are parked in the `LayoutStore` folder. Never park a layout object directly in a ScreenGui: it lays out that ScreenGui's children and collapses the container. The layout swap and scaling run only while the game is playing, not in Edit mode or the Edit-mode device emulator.

## Scaling and shadows

- Screens shrink on small screens with a `UIScale` named `ScreenScale` on each of the screen's root frames. `ViewportScale.Bind(gui, trove)` in a screen module drives every `ScreenScale` inside it: scale is the short side divided by `ScaleConfig.ReferenceShortSidePixels`, clamped to `MinScale`..1. To opt a screen in, add a `ScreenScale` to each root frame and call `Bind`. Scaled so far: `Hud.Container`, `ExpBar.Container`, `MenuButtons.Container`, `ChopMeter` (`Bar`, `ResultLabel`, `HealthBar`, `LeaveButton`), `TrainingHint.Hint`, `Notifications.Container` and `Shop.Panel`.
- Pixel-sized billboards (`ChopPrompt`) keep their content in a `Root` frame (size equal to the billboard's pixel size) holding a `ScreenScale`; `ViewportScale.ApplyToBillboard(template)` scales both that `UIScale` and the billboard `Size` when the clone is created. Billboards sized in studs (`RockLabel`) already scale with the screen and need nothing.
- Touch HUD: while the preferred input is touch, `Hud.luau` lifts `Hud.Container` above the movement thumbstick by `HudConfig.TouchLiftSmallPixels` (short side up to `TouchSmallScreenMaxShortSidePixels`, Roblox's small thumbstick) or `TouchLiftLargePixels`. Roblox hides its touch controls under the same switch, so the HUD only moves while the thumbstick shows. In the Studio emulator, moving the mouse over the viewport flips the preferred input to keyboard and mouse.
- Text widths inside a scaled container: `TextBounds` is in on-screen pixels, so divide it by the `ScreenScale` value before using it in an `Offset` (as `Hud.luau` does for backdrops, the invite button and money deltas).
- Touch: ContextActionService bindings for the minigame chop release (`CHOP`) and training stop (`STOP`) create on-screen touch buttons (`createTouchButton` true plus `SetTitle`); keyboard-only bindings leave phones without a way to play.
- HUD rows have shadows: `IconShadow` (black icon copy, 68px, about 3px right and 4px down) and `<Label>Shadow` (black label copy next to the real label, offset 2px right and 3px down). `Hud.luau` keeps the shadow text in sync through `setText` and `HudConfig.ShadowSuffix`; a missing shadow is skipped. The HUD `ZIndex` order is backdrop 1, shadows 2, outlines and labels 3, icon 4.

## Arm Shop

- `StarterGui.Shop.Panel` uses the vault's Menu Panel Style recipe with an orange header (760x560; about 3.2 cards visible so players see there is more to scroll). `List` is a horizontal ScrollingFrame (X scrolling, horizontal `UIListLayout`, scrollbar along the bottom); `RowTemplate` (hidden) is a 200px-wide vertical card holding `ColorGlow` (shown on the equipped tier), `Preview` (168px ViewportFrame on top), `TierName`, `TierInfo` and `BuyButton` (bottom) (`Track.Fill` with gradient and `StudTexture`, child `Label`, `PriceIcon` group with outlines and shadow).
- `Shop.luau` clones a row per `ArmConfig` tier, builds each arm preview from `Model_ArmPreview` (material and colour from `tier.Visual`, runtime camera), and recolours `Fill` from `ShopConfig.Palette` (Green affordable, Grey too expensive or locked, Orange owned and equipped). The price icon hides on non-price states and the label layout swaps through `ShopConfig.PriceLabel`.
- Gotchas: [[ViewportFrame Gotchas]] in the vault.

## Geode Stand

- `StarterGui.GeodeStand.Panel` is a copy of the Arm Shop panel recoloured Sky blue (header fill edge 0,110,255 / centre 130,205,255 / studs 0,60,170), 944x660 since 2026-10-14. Children:
  - `Tabs`: left column (copied from the Index tabs), one `TabTemplate` clone per geode zone; code paints the active tab Sky and idle grey and opens on the zone the player's strength reaches. The grid and buy buttons sit 92 px right of centre.
  - `Grid`: `UIGridLayout`, 3 columns, 228x189 cells, holding the hidden `CardTemplate`. Each card has `ColorGlow` (code sets the rarity colour), `WeldTexture` (black weld texture over the glow), `Preview` (ViewportFrame), `Odds` (top-left) and `PetName` (bottom).
  - `LuckToggle`: top-right of the body.
  - `BuyOne` / `BuyThree`: 300x76 at the bottom, each with an `Amount` label, a `PriceIcon` and a price `Label`.
  - `Blocker`: a full-width grey bar for "NEED X STRENGTH" / "BAG FULL!".
- `GeodeStand.luau` builds one card per `GeodeConfig` pet when `GeodeStandOpen` arrives. Colours and preview camera settings are in `GeodeStandConfig`. A pet whose rarity is `HiddenUntilFound` and isn't in the player's index shows as a black silhouette (ViewportFrame `ImageColor3` black) named "???". `BuyThree` hides unless affordable, and `BuyOne` then moves to the centre.

## Index

- `StarterGui.Index.Panel` is the house panel with a purple header (edge 120,0,220 / centre 200,120,255 / studs 70,0,140), 1000x700. Left: `Tabs` (`TabTemplate` buttons with `Label` and `Count`). Middle: `HeaderBar` (`PageName`, `Count`), `Sections` scroll of `SectionTemplate` (`ZoneName`, `Grid` of 136px `CardTemplate`, `ProgressRow` with an EXP-bar-style `Progress` and a `ZoneReward` button), and `ClaimAll` at the bottom. Right: `Detail` card (`Preview`, `EntryName` Chrome, `Rarity` with a disabled rainbow `UIGradient`, `Odds`, `Stat`, `Count`, `RewardsTitle`, `Rewards` with a hidden `RewardTemplate` tile, `ClaimButton`).
- Cards are the Geode card minus `Odds`, plus `Alert` (red "!" square, top-right) and a full-card invisible `Select` TextButton. The selected card's `OuterStroke` turns white.
- `Index.luau` builds tabs, sections and cards from `IndexConfig`. Colours, texts and preview camera are in `IndexConfig`. See the vault note [[Index]].

## Hatch reveal screen

- Layout follows the vault note [[Hatch Reveal Reference]]. `StarterGui.HatchReveal` (DisplayOrder 9, IgnoreGuiInset, non-modal) holds:
  - `Shade`: full-screen black at 0.3 transparency.
  - `Content` (640x760 at 0.45 height, `ScreenScale`) → `Body` (with a `PopScale` UIScale for the pop-in). `Body` holds:
    - `PetName` (Chrome, 88)
    - `RarityLabel` (automatic X width; a disabled `UIGradient` for the Secret rainbow)
    - `Odds` (Gold)
    - `Rays` (ImageLabel; the sunburst id comes from `HatchRevealConfig.RaysImage`; spun and tinted by code)
    - `Preview` (ViewportFrame, 420)
    - `NewBadge` (Green, rotated 14)
    - `Stat` (horizontal list: `StatIcon` money image + `StatValue` Green)
    - `Trait` (Gold)
    - `Continue` (Chrome)
  - `Dismiss`: full screen, ZIndex 50.
- `HatchReveal.luau` fills it from `HatchController.Revealed`. On open it adds a `BlurEffect`, pops in, spins the rays, and closes `Hud`, `ExpBar` and `MenuButtons` (`HatchRevealConfig.HiddenScreens`). On close it reopens whichever of those were open.
