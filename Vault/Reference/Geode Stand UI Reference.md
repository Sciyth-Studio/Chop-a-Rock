---
description: Two egg-shop screenshots the user picked (2026-10-04) as the layout for the geode stand's odds/buy panel; layout only, house style applies.
type: reference
---
# Geode stand UI reference

![[Geode Stand UI Ref Panel.png]]
![[Geode Stand UI Ref Billboard.png]]

Take from them (layout and content only; style is [[Menu Panel Style]]):
- Header with the geode's name, then one short line of text, then a **3 x 2 grid of pet cards**, then **big buttons along the bottom**.
- Each card: odds % in the top-left, the pet picture in the middle, the name along the bottom. The second shot tints each card by rarity; ours uses the rarity colour as the card's glow.
- How it opens: a **centred modal** with a close X. On 2026-10-04 it opened from a prompt; since 2026-10-05 it opens when the player steps on the blue neon rectangle in front of the Geode shop stall (see [[Shop Pads]]). Still a centred modal, not the second shot's floating panel, and no key hints on the buttons.
- No line of text under the header. The user disliked "You have 2 · crack them at your base".

Ignore: the "Click to toggle auto-sell" line and auto-sell itself (we have no selling), Auto-Hatch / Multi / the +3/+8/+16 egg buttons (multi-crack and monetisation wait for §10), and rounded corners.

Used by `GeodeSystemPlan.md` (stand screen). Related: [[Geode Stand Reference]], [[UI Style References]], [[ViewportFrame Gotchas]]
