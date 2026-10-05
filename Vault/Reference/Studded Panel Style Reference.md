---
description: Six simulator screenshots (2026-10-05) for the UI restyle: dark grey stud body, striped gradient headers, white text with black stroke, sharp black outlines.
type: reference
updated: 2026-10-05
---
# Studded panel style reference

The user wants the whole UI restyled to this look (2026-10-05). Unlike [[UI Style References]], these screenshots give the **style**, not just layout.

![[Panel Style Ref Food Shop.png]]
![[Panel Style Ref Exclusive Shop.webp]]
![[Panel Style Ref Offline Earnings.webp]]
![[Panel Style Ref Daily Rewards.webp]]
![[Panel Style Ref Free Gift.webp]]
![[Panel Style Ref Sell.webp]]

## Core elements (user's list)
- Dark grey stud-textured background on menus.
- White text with a black stroke for headers and most body text.
- Header boxes in bright gradients with stud texture.
- Whole frames encased in a sharp black stroke.

## Also in the screenshots
- Wide diagonal "/" stripes on headers, the active card and as a shine on buttons.
- Black divider line between the header and the body; thin lighter grey line just inside the body's black outline.
- Pink-red square close button with a light pink inner bevel and black stroke.
- Buttons: black stroke, lighter inner bevel, diagonal shine. Green = primary, yellow = secondary, rainbow = best-value Robux tier, faded = disabled.
- Colour is reserved for values (green money, cyan shards); names white; sublines small dim grey.
- Lighter grey row cards with a bevel; darker inset icon slots; small dark tag chips.
- Big 3D icons that may overflow their frames.

## Decisions (2026-10-05)
- Order: menus first, then meters, then HUD buttons.
- Keep the current font (`FontConfig`, Builder Sans ExtraBold) for now.
- Corners always sharp, including the bits the references round.
- Header titles keep their drop shadow (`TitleShadow`: black, 40% transparent, offset 2px right and 3px down, 4px stroke to match the title).
- Header title: `Chrome` text style (attribute `TextStyle`, UIGradient, 4px black stroke), text size 62 in a 72px row; no count or value beside it. The user's standing rule from 2026-10-05: **every UI header uses Chrome**.
- `Chrome` text style uses a black stroke.
- Studs are the existing texture `rbxassetid://73393331823706`.
- Stripes are `rbxassetid://124988166234585` (source `assets/Textures/UI/DiagonalStripesVaried.png`, 512px tile of white "/" bands of uneven width and spacing), tiled at 512px; strength set with `ImageTransparency` (header 0.6, buttons and bars 0.65). The user rejected the first even-stripe texture (`137618070041196`, `DiagonalStripes.png`) because evenly spaced bands don't match the references.

Supersedes the look in [[Menu Panel Style]] once the pilot is approved. Related: [[UI Text Style]], [[UI Built In Studio]].
