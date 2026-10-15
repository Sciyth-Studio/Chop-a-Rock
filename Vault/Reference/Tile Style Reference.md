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
- Every button with `Track.Fill`: `Stripes` hidden, weld texture swapped back to studs (23px, 0.45). Cards with `ColorGlow`: 10,12,16 at 0.4, `OuterStroke` 4px 40,42,48, `InnerBorder` hidden. Sell Shop `Sidebar` and `Footer` match the cards.
- Arm Shop `RowTemplate`: `Rays` ImageLabel (hatch reveal sunburst `98918865309369`, white, 0.78, 190px) behind a now transparent `Preview`.
- Teleport bar (Base / Shops / Rocks, 2026-10-15): styled exactly like the shop headers (the user asked). Each button's background is the dark outline colour, `Track` inset 4px, light-top `Fill`, `Bevel`, `Lip` + `Highlight`, studs 0.55, `Stripes` hidden; the old white `InnerBorder` is hidden. `OuterStroke` stays 3px black. Original colours in the `BaseEdge` / `BaseCenter` attributes.
- Not touched yet: Index, Rebirth, Roks, Settings, Admin, hatch reveal, HUD rows.

## Open questions for the user
- Two-column tile grid like the reference, or keep one column of four?
- Header icon overlapping the top-left corner (the Sell Shop already has one inline).
- Roll the look out to the remaining panels.

Related: [[Studded Panel Style Reference]], [[Menu Panel Style]], [[UI Feel]], [[UI Built In Studio]].
