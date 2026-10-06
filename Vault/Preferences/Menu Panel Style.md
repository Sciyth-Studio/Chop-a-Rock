---
description: House recipe for menu panels (Rebirth, Shop, Geode Stand, Settings, Admin): dark grey stud body, striped gradient header, Chrome title, black outlines, sharp corners.
type: preference
updated: 2026-10-05
---
Every menu panel uses this recipe, taken from [[Studded Panel Style Reference]]. The Rebirth panel was the approved pilot (2026-10-05). Shop, Geode Stand, Settings, Admin and the hatch reveal card were restyled to match the same day. Reference screenshots of other games give **layout and content** only; the **style** is always this one.

**Panel body**
- `Panel` background 44,44,46, opaque. A 5px black `UIStroke` named `OuterStroke` (`Border`, `LineJoinMode` Miter).
- `StudTexture` ImageLabel covering the panel: `rbxassetid://73393331823706`, tiled 23px, tinted black, `ImageTransparency` 0.55, ZIndex 2.
- `InnerBorder` sits just below the header (position y = header height + 3, size 1,-6 by 1,-(header + 6)): a 3px opaque `UIStroke` in 88,88,94. It forms the thin lighter line inside the black outline.
- No `ColorGlow` and no translucent gradient on the panel.
- **Sharp corners everywhere.** No `UICorner`, even where a reference rounds things.

**Header** (84px tall, flush at the top)
- `Header` background black. `Track` at 0,0, size 1,0 by 1,-5, so 5px of black shows as the divider under the header.
- `Track.Fill` keeps the meter gradient (vertical: dark edges, light centre) and studs in the panel's colour. It also holds `Stripes` with `ClipsDescendants` on.
- `Stripes` ImageLabel: `rbxassetid://124988166234585` (uneven "/" bands), tiled 512px, white, `ImageTransparency` 0.8 on headers and 0.84 on buttons and bars. The user asked to lower the strength twice; don't go stronger.
- Title: `Chrome` text style (attribute `TextStyle`, UIGradient, 4px black stroke). Text size 62 in a 72px row. Title Case with no colon ("Rebirth"). No count or value beside it.
- `TitleShadow`: black, 40% transparent, offset 2px right and 3px down, 4px stroke. Headers keep their drop shadow.
- **Close button** (56×56, 14px from the right, centred 2px up): pink-red vertical gradient (255,95,150 → 230,15,85), 3px black `OuterStroke`, `InnerBorder` stroke 255,175,205 opaque, white X with a black stroke.

**Buttons, value boxes and bars** (anything with `Track.Fill` and `InnerBorder`)
- Background solid black. `Track` inset 3px (size 1,-6 by 1,-6), so a 3px black frame shows.
- `InnerBorder` (size 1,-10 by 1,-10) sits above the fill, with a 2px white stroke at 50% transparency, as a bevel.
- `Fill`: meter gradient and studs in the box's colour, plus `Stripes`. Code recolours only the gradient and `StudTexture`, so `Stripes` survives repaints.
- **Buttons use the weld texture, not studs (2026-10-05).** On menu buttons (Rebirth/Skip, Shop Buy, Settings toggles, Admin commands, Geode Buy/Blocker/Luck), the `StudTexture` child of `Fill` shows `rbxassetid://129370550834255`. That is the user's diamond-lattice "weld" texture, tiled 128px at 40% transparency. The name stays `StudTexture` so screen code still tints it. Value pills, bars and headers keep the studs.
- Empty bar tracks are 28,28,30.
- Colours: Rebirth ready green / locked grey, Skip purple, cash pills green, strength pills orange, level bars EXP gold.

**Cards** (Shop rows, Geode cards: `InnerBorder` plus `ColorGlow`, no `Track`)
- Background 58,58,62, 3px black `OuterStroke`. `InnerBorder` (1,-6) has a 3px opaque 100,100,106 stroke.
- `ColorGlow` has the card's own ZIndex, so it draws over the grey. It shows the equipped arm or the rarity colour.
- Geode cards (2026-10-06) add `WeldTexture` over the glow: the weld texture `rbxassetid://129370550834255`, tiled 128px, black, 40% transparent, same ZIndex as the card and ordered after `ColorGlow`. The user asked for it instead of the glow being only a gradient. The Index cards reuse this card.
- Arm previews sit in a dark inset slot: 32,32,34 with a 3px 100,100,106 stroke. Geode pet previews have no slot (transparent), so black "???" silhouettes stay readable.
- Scrollbars: 8px, 120,120,126.

**Text**
- Body, button and warning text: plain white with a 3px black stroke (2px on small text), not italic, no gradient.
- Values may be coloured in the HUD style. Example: "Rebirth only consumes **CASH**" uses `Green` italic with a shadow.
- No all caps ([[No All Caps In UI]]); CASH there is the one exception.
- Text inside bars uses `Chrome`.

**HUD menu buttons (2026-10-05)**
- The user first tried icon-only buttons (icon, shadow and label with no box), then asked for the grey stud box back.
- Each button: background 44,44,46 with `StudTexture` and a 3px black `OuterStroke`, plus `InnerBorder` with a 3px 88,88,94 line. Everything sits at `ZIndex` 0, so the icon shadow and label draw above it.
- 88px icon with a 92px shadow; labels have a 3px stroke. Full spec is in the `studio-ui` skill.

**EXP bar (`ExpBar.Container`, 2026-10-05)**
- Solid black box with `Track` inset 4px (1,-8). The empty track is the grey stud body: 44,44,46 plus `StudTexture`.
- Gold `Fill` with `Stripes` at 0.84. `InnerBorder` (1,-12) sits above the fill with a 2px white stroke at 50%.
- Labels stay `Chrome` with drop shadows.

**Panel colours:** Rebirth red, Arm Shop orange, Geode Stand sky blue, Admin red, Settings grey.

**Spacing:** give things room. The first Rebirth panel (560×410) was rejected as cramped; 760×520 was right.

**History:** before 2026-10-05, panels used the HUD menu-button look: a translucent black gradient, a coloured glow rising from the bottom, and a white inner border. That look was replaced. A copy of each old panel is in `ServerStorage.UIBackup` until the user says to delete it.

See [[UI Text Style]], [[High Saturation Colors]], [[UI Built In Studio]].
