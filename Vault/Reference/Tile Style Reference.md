---
description: 2026-10-15 style the user wants next (HUD button tiles + Daily Rewards panel): outline + colour-to-clear gradient + shade box tiles, translucent dark bodies, stud headers, no stripes, square corners; pilot on menu buttons and shops.
type: reference
updated: 2026-10-15
---
# Tile style reference

The user asked to restyle toward this look on 2026-10-15. These screenshots give the **style**. A first pass was applied to the HUD menu buttons and the shop panels; it is a pilot, not yet approved. If approved it supersedes parts of [[Menu Panel Style]].

![[Tile Style Ref HUD Buttons.png]]
![[Tile Style Ref Daily Rewards.png]]

## User's breakdown and rules (2026-10-15)
- **No rounded corners**, ever (same as [[Menu Panel Style]]). Ignore the rounding in these references.
- Their HUD button is three layers: an outer outline, a gradient fill whose colour fades to transparent at the top, and a semi-transparent box on top of that.

## What the references show
- HUD buttons: square tiles with a thick dark charcoal frame and a thin black outline, big overflowing 3D icons, white label with a black stroke at the bottom, red square "!" badge top-right. Two-column grid.
- Panel: bright stud-textured header (lego studs, no diagonal stripes) with a black outline, white title, icon overlapping the top-left corner; red square close button.
- Body: translucent dark over the blurred world, no stud texture. Cards are translucent dark with a charcoal border and a sunburst behind the item.
- Buttons: stud-textured fill, black outline, white stroked text (slate "Claimed", magenta "Skip All").

## Applied (2026-10-15, Studio only, pilot)
- Backups of the old screens: `ServerStorage.UIBackup.BeforeTileStyle` (MenuButtons, Shop, GeodeStand, SellShop, AuraShop, RobuxShop).
- Menu tiles (`MenuButtonTemplate` and every `<Name>Button`), matched to a zoomed crop of the reference Index tile:
  - Tile: background transparent, `OuterStroke` 3px black, Miter. Old `UIGradient`, `StudTexture` and `InnerBorder` off.
  - `Track` (full size, transparent) holds `Fill`: the button colour with a vertical `UIGradient`, transparency 1 at the top to 0.3 at the bottom (user tuned: 0 too strong, 0.6 too faint). The gradient fills the whole tile up to the black outline. Named `Track.Fill` so `ButtonFeel` darkens the colour on hover.
  - `Shade`: a plain black box at 0.5 transparency, inset 3px (size 1,-6 by 1,-6; was 5px, user asked for it a bit bigger), above the gradient. The gradient shows as a coloured ring around it.
  - Colours: Shop 255,130,0; Roks 0,150,255; Index 170,50,255; Rebirth 255,30,70; template grey 150.
  - Icon 64px at 0.5,0 / 0.42,0 (inside the tile, no overflow; the user said 88 was too large); `IconShadow` 67px, offset 3,4.
  - All at `ZIndex` 0. Grid gap 16 (`MenuButtonConfig.ButtonGapPixels` and both layouts), container x 18. One column.
  - Notification badge (`IndexButton.Badge`, 2026-10-15), from the reference below: red vertical gradient 255,0,0 → 190,0,0, 3px dark maroon stroke 77,13,13, white "!" (`Chrome`, 3px black stroke). It shows "!" instead of the reward count. While visible it wiggles every 3 s through -16, 14, -10, 6, 0 degrees, 0.08 s per swing (`MenuButtonConfig.IndexBadge`, `MenuButtons.luau`).

![[Tile Style Ref Badge.png]]
- Rejected attempts (2026-10-15): (1) a solid charcoal frame ring and a full-size flat shade box, which hid the black outline and read as no shade; (2) the gradient inset inside a dark ring, which put the gradient where the box belongs.
- Shop panels (Shop, GeodeStand, SellShop, AuraShop, RobuxShop): `Panel` 14,16,20 at 0.15, panel `StudTexture` and `InnerBorder` hidden.
- Headers, copied from the header reference below (user, 2026-10-15):
  - `Header` background is the outline: a dark shade of the header colour (stud colour mixed 55% toward black). `Track` is inset 4px on every side.
  - `Fill` gradient runs light at the top (centre colour, 12% toward white) to the edge colour at the bottom, instead of dark edges and a light centre. `Stripes` hidden, studs at 0.55.
  - `Track.Bevel`: a 4px light stroke (centre colour 55% toward white, 0.15 transparent) along the fill's edge; the frame is inset by the stroke thickness so the stroke stays inside the fill. Was 2px; the user asked for it a bit thicker.
  - `Track.Lip`: a 9px darker band along the bottom (stud colour mixed toward the edge colour) with a 2px light `Highlight` line on top of it, so the bar looks like a raised block.
  - The original colours are kept in the `Header` attributes `BaseEdge` and `BaseCenter`.
  - Close button: red gradient 255,45,45 → 225,15,20; `OuterStroke` 3px dark maroon 95,5,10; inner bevel 2px 255,125,125; a 7px dark red `Lip` (165,0,10) at the bottom; the X has a maroon stroke and a maroon `XShadow` copy 3px below it.
  - Header icon (2026-10-15): `Icon` ImageLabel parented to `Header` (not the `HeaderText` list), 122px, centre 52px from the left and 10px above the middle, rotated -8, `ZIndex` 10, overflowing the bar. Eight black `IconOutline1..8` copies offset 3px (`ZIndex` 9) give it a dark outline, and `IconShadow` (126px, black, 0.4, 4px right and 6px down, `ZIndex` 8) sits behind. `HeaderText` starts at x 120.
  - Icons reuse existing art: Arm Shop = Strength arm `124121424211029`, Geode = Roks crystal `126551755246168`, Sell Roks = Money `120312068437386` (it used the crystal inline before), Aura Shop = Hot Streak flame `94131698155889`, Robux Shop = Shop basket `137511164992804`.

![[Tile Style Ref Header.png]]
- **Block button = THE button style (user, 2026-10-15).** Every shop button with `Track.Fill` (Arm/Aura `BuyButton`, Geode `BuyOne`/`BuyThree`/`Blocker`/`LuckToggle`/`TabTemplate`, Sell `SortTemplate`/`SelectAllButton`/`SellButton`) is built like the headers and teleport bar: background = dark outline colour, `Track` inset 4px, `Fill` gradient light top → edge bottom, studs 0.55, `Stripes` and `InnerBorder` hidden, `Track.Bevel` (4px stroke, 3px under 56px tall), `Track.Lip` (11% of the height, 5–9px) + 2px `Highlight`, 3px black `OuterStroke`. Code paints all of it through `Utils/BlockButton.Paint(fill, {Edge, Center, Studs})` with ratios in `BlockButtonConfig`. The shop palettes have pale centres, so the fill top is `Edge` mixed 40% toward `Center` (not the centre itself), the bevel is that top 45% toward white and the lip highlight 10% toward white; the user compared Buy 3 with the Shops teleport button (2026-10-15) and the pale version washed out. `Lip` and `Highlight` sit one `ZIndex` above `Fill` and `Bevel`, so the bevel never draws over the lip. Every button label is `Chrome` (attribute + `UIGradient`) with a `<Label>Shadow` copy (black, 0.4, 2px right 3px down); code moving a price label uses `BlockButton.PlaceLabel` so its shadow follows; Shop, AuraShop, GeodeStand and SellShop call it. New buttons copy one of these and call `BlockButton.Paint`. The training stand upgrade sign (`Model_BasePlot.UpgradeSign.Board.UpgradeGui`, `CashButton` and `RobuxButton`, a Sibling-ZIndex SurfaceGui so `Bevel` is `Fill` z+1 and `Lip` z+2) uses it too since 2026-10-15: studs instead of weld, Chrome labels with shadows, `TrainingUpgradeSign.luau` paints through `BlockButton.Paint` and keeps the shadow text in sync. Old sign GUI backed up in `UIBackup.BeforeTileStyle.UpgradeGui`. The Robux button's `RobuxIcon` is now an ImageLabel (46px, with a black `RobuxIconShadow`) showing the user's white Robux icon from their Free Icon Pack v3.1, uploaded through Open Cloud as group Image `137237246101535` (`IconConfig.Robux`, source `assets/Textures/UI/Icons/RobuxWhite.png`); it was an empty TextLabel before. Its price label moved to x 62. Shop close button X is 1,-4 (was 1,-18; user asked for it larger). Rebirth, Settings, Index, Roks and Admin still use the old paint.
- Before that pass: weld texture swapped back to studs (23px, 0.45). Cards with `ColorGlow`: 10,12,16 at 0.4, `OuterStroke` 4px 40,42,48, `InnerBorder` hidden. Sell Shop `Sidebar` and `Footer` match the cards.
- Arm Shop `RowTemplate`: `Rays` ImageLabel (hatch reveal sunburst `98918865309369`, white, 0.78, 190px) behind a now transparent `Preview`.
- Teleport bar (Base / Shops / Rocks, 2026-10-15): styled exactly like the shop headers (the user asked). Each button's background is the dark outline colour, `Track` inset 4px, light-top `Fill`, `Bevel`, `Lip` + `Highlight`, studs 0.55, `Stripes` hidden; the old white `InnerBorder` is hidden. `OuterStroke` stays 3px black. Original colours in the `BaseEdge` / `BaseCenter` attributes.
- Rebirth panel (2026-10-15, after the user pointed out it was missed): same body, header (Rebirth arrows icon `110491182765186` overlapping the left end), close button with big X, block `RebirthButton` / `SkipButton` and block value pills (Cash, Strength, Luck before/after), all labels in them `Chrome` with shadows. Skip's Robux glyph is now the uploaded Robux image. `Rebirth.luau` paints through `BlockButton.Paint`. The `LevelBar` meter keeps its old look. Old panel in `UIBackup.BeforeTileStyle.Rebirth`.
- Index, Roks, Settings, Admin (2026-10-15): same body, header and close button; every `Track.Fill` button is a block button with Chrome labels and shadows; grey row cards (`HeaderBar`, `Detail`, Roks `RowTemplate`, Settings rows, Index `CardTemplate`) use the dark card look. Index gets the purple book header icon. Roks has no header icon: it would cover the "x/3 Placed" title and the "+1 Slot" button in its header. Index `Alert` squares match the menu badge (red gradient, maroon stroke, Chrome "!"). Meters keep their bar paint (`paintMeter`): the Index zone progress bar and the Settings volume slider. Code paints buttons with `BlockButton.Paint` and writes button text with `BlockButton.SetText` (keeps `<Label>Shadow` in sync). Old panels in `UIBackup.BeforeTileStyle`.
- **Progress bars = block bars with the weld texture (user, 2026-10-15).** Rebirth `LevelBar`, Settings `VolumeSlider`, Index section `Progress`, `HotStreakBar.Container` and `ChopMeter.HealthBar`: background = dark outline colour, 3px black `OuterStroke`, `Track` inset 4px (empty part 28,28,30, clipped), `Fill` light-top gradient with `StudTexture` showing the weld `129370550834255` (128px tile, 0.4, tinted the studs colour), and `Bevel` + `Lip` inside `Fill` so they follow its width (`BlockButton.Paint` finds them there). Labels sit above them. `HealthFill` now lives in a `Track` (ChopMeter finds it recursively) and lost its rounded corners. Code paints bars with `BlockButton.Paint` too.
- **Hot streak bar fire (2026-10-15):** the fire icon is gone. Two tiled ImageLabels inside the fill, `FireBack` and `FireFront`, both show kit K1868 only (the user rejected the K1879 wisps: vertical stripes). K1868 is a flame wall rising from the bottom, seamless left to right; `assets/VFX/HotStreakBar/textures.py` crops off its empty top 160 rows (so the flames fill the bar top to bottom, user asked) and turns black into alpha; image `103912085781850`. Tiles are the full fill height, 96px and 70px wide, and scroll sideways in opposite directions; each label is one tile wider than the fill and wraps at one tile (`HotStreakBar.luau` `scrollFire`, speeds in `HotStreakConfig.BarFireLayers`). Colours: never white (the user called the white fire ugly). The fill is painted darker (tier `Dark` edge, `Main` centre, studs `Dark` 40% toward black, `BarStudsDarken`); `FireBack` takes the tier `Main` colour at 0.35 transparency, `FireFront` the tier `Light` colour at 0.1. The VFX kit's beam/trail folder is where tileable fire lives; sprites don't tile.
- Testing tip: `require` of a controller from `execute_luau` gives a separate copy, so `UIController:Open` there does nothing visible; click the menu button with `user_mouse_input` (`instance_path` `LocalPlayer.PlayerGui.MenuButtons.Container.<Name>Button.Button`) to open a screen for real.
- Not touched yet: hatch reveal, HUD rows, Index reward tiles.

## Open questions for the user
- Two-column tile grid like the reference, or keep one column of four?
- Header icon overlapping the top-left corner (the Sell Shop already has one inline).
- Roll the look out to the remaining panels.

Related: [[Studded Panel Style Reference]], [[Menu Panel Style]], [[UI Feel]], [[UI Built In Studio]].
