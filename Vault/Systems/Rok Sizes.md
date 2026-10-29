---
description: Rok size tiers (built 2026-10-28) - Normal, Large, Huge, Giant, Enormous rolled on every grant, luck pushes the big sizes, looks only (no $/s), scaled models, size labels.
type: system
---
# Rok sizes

Decided by the user 2026-10-28. Every number is a draft in `RokSizeConfig`.

## Rules
- Tiers, odds and model scale: Normal 70% x1, Large 20% x1.2, Huge 7% x1.4, Giant 2.5% x1.65, Enormous 0.5% x2.
- Looks only: size never changes $/s, sell value, Equip Best or the [[Balance Model]].
- Luck raises the big sizes: `RokSize.Chances(luck)` multiplies every non-Normal tier by the hatch luck (`GeodeService/Luck.Total`, the same number geode odds use), capped so the big sizes together reach at most `MaxBigShare` (75%). Normal takes the rest. Only geode cracks pass luck. Geode Fall, admin, purchase and pending grants roll at luck 1.
- Exclusive Roks (Champ, Kingy) are always Normal, like modifiers.

## Where things live
- Shared: `Config/RokSizeConfig` (order, weights, scales, the `TextStyle` per tier, the `Size` attribute name, `InfoLiftStudsPerScale`), `RokSize` (Get, IsShown, Scale, Chances, Roll, Name = "Huge Zappy Bloky").
- Data: `Pet.Size` (nil = Normal). `PetService.add` rolls it; `PetService:SetSize` is the admin path (fires `ModifierChanged` so pedestals rebuild).
- Scaling: `PedestalService/Display` scales `PlacedRok` by `RokScale x size` and rebuilds it when the size changes; `PetService/Tools` scales the held tool by `ToolScale x size` and moves the grip with it.
- `GeodeHatched` carries the size (after the modifier string).
- UI: `HatchReveal.Content.Body.SizeLabel` (Trait copy at y 548, under the preview) and `SellShop` `CardTemplate.SizeLabel` (Modifier copy at y 36, top of the preview) show the tier name in its text style (Large Green, Huge Sky, Giant Orange, Enormous Gold); hidden for Normal. Tool names, the pedestal prompt, the pedestal title and Roks panel rows use the prefixed name. The pedestal info billboard rises `InfoLiftStudsPerScale` x (scale - 1) studs so it clears big Roks.
- Admin: Roks tab "Held Rok: Set Size" (alias `size`).

Related: [[Pedestals]], [[Weather]], [[Geode Shop]], [[Sell Shop]]

## Tested 2026-10-28
Play with the worktree scripts pushed into Studio: `Chances` at luck 1 gave exactly 70/20/7/2.5/0.5 and 100k rolls matched; luck 2 gives Normal 40%, luck 4 and up hits the 75% cap (Normal 25%). Admin Grant Random Rok + Set Size Enormous + Equip Best: the pedestal `PlacedRok` scaled 4.00 (2 x 2), title "Enormous Bloky", seen on screen. The HatchReveal screen module drawn with a Giant Zappy Nesty showed "Giant" in orange under the preview (seen). Not checked: a real geode crack end to end (a `GeodeHatched` fired from the Studio server context didn't open the reveal), the held tool and grip, the Sell Shop card label, the info billboard lift after it dropped from 6 to 4.5 studs per scale.
