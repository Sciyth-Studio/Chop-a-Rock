---
description: The user's inspo (2026-10-20) for the Cannon Shop panel - a "Jurassic Airlines" travel shop with one big zone-coloured card per tier (name, tier line, model preview, zone block, cash price, Robux price, Unequip on the equipped one); layout only, house style applies.
type: reference
---
# Cannon Shop UI reference

![[Cannon Shop Inspo.png]]

Shared 2026-10-20 after the user tested the first Cannon Shop ("this is what the cannon inspo looks like. it tested fine"). Another game's pterodactyl travel shop; take the layout, not the theme. Style is still [[Menu Panel Style]].

What to take:
- One subtitle line under the header ("Buy once. Fly forever.") with the player's cash on the right, and one footer line ("Choose your next adventure").
- A horizontal scroll of tall cards, one per tier. Each card is tinted in its zone's colour: name, then a "Tier N" line, then a big model preview on a light panel, then a darker block with "Zone N" and the zone name.
- Buttons stack at the bottom of each card: cash price in grey and a yellow Robux price under it. The equipped card has a green outline, a green tick on the preview and a single green "Unequip" button.

Tried 2026-10-20 (zone-tinted cards, Zone block, price button, cash on the subtitle line, footer; no Robux row or preview), then the user asked for the Aura Shop style instead. The try is kept in `ServerStorage.UIBackup.CannonShop.InspoRestyle`; see [[Cannon Shop]].

Related: [[Cannon Shop]], [[UI Style References]]
