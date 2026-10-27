---
description: The game's icon style comes from the user's Free Icon Pack v3.1 (Basic) in Downloads; the ChatGPT style sheet is eight of its icons; use pack icons before prompting.
type: reference
---
# Game icon pack

Found 2026-10-25 while getting the Robux shop icons.

- **Source:** `C:\Users\Admin\Downloads\Free Icon Pack v3.1 (Basic)` by gvesster. About 150 icons in folders `Animal`, `Currency`, `Exclusive`, `Food`, `Item`, `Main`, `Nature`, `Player`, `Social`, `UI`. The largest size is 256 px, plus 64 px. Each icon comes as "1st", "2nd" (a second colourway), "1st Outline" (dark navy outline), "Black" and "White" (silhouettes), and sometimes "Golden"/"Green"/"Red" colourways.
- **It is the game's style.** The HUD icons (arm, cash, basket, Roks, crystal, book, rebirth arrows, fire) are this pack's icons. The ChatGPT style sheet, `assets/Icons/Cannon/IconStyleSheet.png`, is eight of them. The cannon, the weather icons and the shop prompts (`assets/Icons/Shop/Prompts.md`) were all made to match it. The sheet's style is flat-colour chunky 3D, white highlight slivers, **no outline**.
- **Use the "1st" (no outline) version** for any icon that gets the `IconOutline` copies (HUD, shop, pills). Those copies draw the black outline, so a baked outline would come out doubled.
- **Look in the pack before writing a ChatGPT prompt.** It covers a lot already: Chest, Green Cash, Planet (globe), 4 Players, Auto Open (the Rebirth arrows in green), Hammer, Lucky Block, VIP, Crown, Gift, Clock, Backpack, Skip, Potion, Trophy, Medal, Rocket, Magnet, Key and more.
- **Licence:** commercial use and editing in our own project are fine. Reselling the icons or putting them in an asset pack is not. Credit is optional.
- **Prepping:** the PNGs are palette mode (`P`). Convert to RGBA, keep 256 px (upscaling only blurs, and the UI shows them at 150 px or less), upload as Image under the group ([[Open Cloud Key]]).

Robux shop picks (2026-10-25), in `assets/Icons/Shop/`: Crown 1st (VIP), Red Gift 1st (Gift), Golden Clock 1st (timed boosts), Golden Backpack 1st (Big Backpack), Skip 1st (the tutorial Skip button, replacing its text), Green Planet 1st as `ServerBadge` (sits on the clover, money and arm icons for server-wide boosts). Uploaded as Image under the group through Open Cloud (`.claude/skills/vfx/scripts/upload_images.ps1 -Prefix Shop`; ids in `assets/Icons/Shop/assets.json`), all Success in an Edit-mode `PreloadAsync` on ImageLabels, in `IconConfig` as `Crown` 117415041002029, `Gift` 132080330376191, `Clock` 139362520433112, `Backpack` 135474126728093, `Skip` 102429972816165, `ServerBadge` 91457041311285.

**ChatGPT shop icons (2026-10-25)**, made from `assets/Icons/Shop/Prompts.md` and in `IconConfig`: `LuckyGeode` 86432488077969, `AutoOpen` 88428093722478, and the cash ladder `Cash1` 101112809904563, `Cash2` (= `Money`, the pack's cash stack) 120312068437386, `Cash3` 118503914460480, `Cash4` 123447750647234, `Cash5` 79905876183400. Cash5 is a chest of cash and is also used for Welcome back / Claim x3. ChatGPT exports carry a faint haze out to the image edges, and the chest had a thick white glow. The clean-up: alpha below 150 goes to 0, a smoothstep ramp from 150 to 230, 255 above; for a white glow, also zero the light, low-saturation pixels (min RGB > 150, saturation < 60) under alpha 240; drop islands under 400 px; trim, pad 4%, resize to 512. Check the result with 8 black offset copies on a coloured backdrop, the way the shop draws it.

**Shop effect textures (2026-10-25, from the user)** in `assets/Textures/UI/Shop/`, soft alpha kept: `ShineStreaks` 79969058523004 (diagonal shine streaks), `SparkleCross` 119639383812050 (four-point lens-flare star), `SparkleBurst` 90541591019914 (many-pointed starburst). They are not in `IconConfig`; the shop code picks them up.

Related: [[Tile Style Reference]], [[Weather]], [[Asset Ownership]]
