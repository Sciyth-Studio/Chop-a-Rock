---
description: House style for menu panels/screens (Rebirth, Shop, etc.) — HUD-button layered gradients, sharp corners, Chrome headers, roomy layout. Reference screenshots give layout, not style.
type: preference
updated: 2026-10-02
---
Every menu panel follows the HUD menu-button look, not the look of whatever reference screenshot it was based on. "Copy everything" from a reference means copy its **layout and content**; the **style** is always this house style.

**Panel / box recipe** (same as `MenuButtons` buttons):
- Black background with a horizontal `UIGradient` — transparency 0.3 at both edges, 0.6 in the center.
- `ColorGlow` child frame (ZIndex one below) with a colored `UIGradient`, rotation 270, transparency 0.3 → 1, so the color rises from the bottom. Panel color matches its menu button (Rebirth = red). Inner boxes use their own color (cash/strength pills = green).
- `InnerBorder` frame (size 1,-6 by 1,-6) with a white 3px `UIStroke`, 25% transparent, `Border` mode, `LineJoinMode` Miter.
- **Sharp corners everywhere.** No `UICorner` on panels, boxes, bars or buttons.

**Meter recipe** (the EXP bar's construction, `ExpBar.Container`): box recipe without the glow, a `Track` inset 12px, and a `Fill` with a vertical gradient (dark edges, light center) plus the stud texture (`rbxassetid://73393331823706`, tiled 23px, tinted darker, 40% transparent). Use it, always full, for:
- **Menu headers**: a bar in the panel's color (Rebirth = red) holding the title and close button. It sits flush against the panel's top and sides (position 0,0, full width) with no gap.
- **Close button**: the menu-button box minus the color glow: black horizontal gradient (0.3/0.6/0.3) plus the white inner border. The X is notification-style text. It sits inside the header bar (56×56, 14px from the right edge), so the header shows through it.
  - Rejected on 2026-10-02 as "ugly": cutting the X out into its own corner tile with nothing behind it (the panel split into tiles so the header stopped short of the corner).
- **Action buttons**: in their own color (Rebirth = grey locked / green ready, Skip = purple). Button text is a child label, not the TextButton's own text, because the fill covers it.
- **Value boxes**: colored by what they show (cash = green, strength = orange).
- **Progress bars** tracking level use the EXP bar's own gold/yellow, filled to the ratio.

Colors (edge / center / studs): Gold 255,170,0 / 255,245,130 / 190,100,0 · Red 230,0,0 / 255,130,120 / 140,0,0 · Green 0,190,40 / 150,255,120 / 0,120,20 · Orange 255,110,0 / 255,205,120 / 170,60,0 · Grey 120,120,120 / 215,215,215 / 70,70,70 · Purple 150,0,255 / 220,150,255 / 90,0,160.

**Header text layout**: put the title and value in a horizontal `UIListLayout` with fixed `TextSize` and `AutomaticSize` X. Side-by-side `TextScaled` boxes overlapped at runtime.

**Text:**
- Menu header title (e.g. "REBIRTH:") uses the `Chrome` text style.
- Header values (e.g. the rebirth count) match the HUD friends row: `Gold` style, italic.
- HUD-style drop shadows on header labels: a `<Name>Shadow` copy, black, 40% transparent, offset 2px right and 3px down. Screen code must update the shadow's text too.
- **Body text, button text, warnings and the close X use the notification text style**: plain white, 3px black `UIStroke` (2px on small text), not italic, no gradient, no `TextStyle`, no shadow. This includes warning lines; the red "Rebirth only consumes Cash" was changed to white.
- Text inside a progress bar keeps the EXP bar's Chrome style.
- Arrow glyphs (▶) are body text too: notification style.

**Action buttons are the focus:** make them wide (Rebirth panel: 290×60 each, 24px apart) with clear space above and below.

**Icons** next to values copy the HUD rows: eight `IconOutline1..8` copies offset ±3px (attribute `IconOutline=Icon`) tinted a dark shade of the icon's hue (money 0,90,20; strength 140,45,0), a black `IconShadow` 4px larger at 40% transparency offset 1px right and 2px down, and the icon on top.

**Spacing:** give things room. The first Rebirth panel (560×410 with big buttons) was rejected as cramped; 760×520 with 200×56 buttons was right.

**Why:** the user's critiques of the Rebirth screen (2026-10-02). Round 1: transparent background didn't match the HUD, no Chrome header, round corners, buttons too big and frame too small, bar didn't match the level bar. Round 2: header, buttons and value boxes should all be EXP-bar-style meters in their own colors, and the rebirth bar goes back to the EXP bar's yellow since both track level.

See [[UI Style References]], [[UI Text Style]], [[High Saturation Colors]], [[UI Built In Studio]].
