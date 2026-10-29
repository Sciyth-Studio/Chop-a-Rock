---
description: Rok size tiers (built 2026-10-28, reworked 2026-10-29) - Tiny, Normal, Big, Giant, Huge, Colossal rolled on every grant, luck pushes only the sizes above Normal, looks only (no $/s), scaled models, size labels.
type: system
---
# Rok sizes

Decided by the user 2026-10-28. Every number is a draft in `RokSizeConfig`.

## Rules
- Tiers, odds and model scale (user, 2026-10-29): Tiny 15% x0.75, Normal 55% x1, Big 20% x1.2, Giant 7% x1.4, Huge 2.5% x1.65, Colossal 0.5% x2. Tiny is smaller than a normal Rok.
- Looks only: size never changes $/s, sell value, Equip Best or the [[Balance Model]].
- Luck raises only the sizes bigger than Normal (Scale > 1): `RokSize.Chances(luck)` multiplies them by the hatch luck (`GeodeService/Luck.Total`, the same number geode odds use), capped so together they reach at most `MaxBigShare` (75%). Tiny and Normal shrink together to make room, so luck makes Tiny rarer too (luck 2: Tiny 8.6%, Normal 31%; cap: Tiny 5.4%, Normal 20%). Only geode cracks pass luck. Geode Fall, admin, purchase and pending grants roll at luck 1.
- Exclusive Roks (Champ, Kingy) are always Normal, like modifiers.

## Where things live
- Shared: `Config/RokSizeConfig` (order, weights, scales, the `TextStyle` per tier, the `Size` attribute name, `InfoLiftStudsPerScale`), `RokSize` (Get, IsShown, Scale, Chances, Roll, Name = "Huge Zappy Bloky").
- Data: `Pet.Size` (nil = Normal). `PetService.add` rolls it; `PetService:SetSize` is the admin path (fires `ModifierChanged` so pedestals rebuild).
- Scaling: `PedestalService/Display` scales `PlacedRok` by `RokScale x size` and rebuilds it when the size changes; `PetService/Tools` scales the held tool by `ToolScale x size` and moves the grip with it.
- `GeodeHatched` carries the size (after the modifier string).
- UI: `HatchReveal.Content.Body.SizeLabel` (Trait copy at y 548, under the preview) and `SellShop` `CardTemplate.SizeLabel` (Modifier copy at y 36, top of the preview) show the tier name in its text style (Tiny Chrome, Big Green, Giant Sky, Huge Orange, Colossal Gold); hidden for Normal. Tool names, the pedestal prompt, the pedestal title and Roks panel rows use the prefixed name. The pedestal info billboard moves `InfoLiftStudsPerScale` x (scale - 1) studs, so it rises over big Roks and drops a little for Tiny.
- Admin: Roks tab "Held Rok: Set Size" (alias `size`).

Related: [[Pedestals]], [[Weather]], [[Geode Shop]], [[Sell Shop]]

## Tested 2026-10-28
Play with the worktree scripts pushed into Studio: `Chances` at luck 1 gave exactly 70/20/7/2.5/0.5 and 100k rolls matched; luck 2 gives Normal 40%, luck 4 and up hits the 75% cap (Normal 25%). Admin Grant Random Rok + Set Size Enormous + Equip Best: the pedestal `PlacedRok` scaled 4.00 (2 x 2), title "Enormous Bloky", seen on screen. The HatchReveal screen module drawn with a Giant Zappy Nesty showed "Giant" in orange under the preview (seen). Not checked: a real geode crack end to end (a `GeodeHatched` fired from the Studio server context didn't open the reveal), the held tool and grip, the Sell Shop card label, the info billboard lift after it dropped from 6 to 4.5 studs per scale.

**Names reworked 2026-10-29 (user):** after a short-lived L/XL/XXL/XXXL rename, the user picked Tiny, Normal, Big, Giant, Huge, Colossal and added Tiny below Normal. The update wasn't published yet, so the keys changed too (no migration). Old test keys (`Large`, `Enormous`) fall back to Normal. The test notes above use the old names.

**Pedestal sign (user, 2026-10-29):** size sits on its own line above the Rok name, the same way weather modifiers do. The title shows only the Rok name. `PedestalInfo` (Studio, `Assets.VFX.Pedestal`) grew from 4.4 to 5.4 studs tall and gained a `Size` label (a Modifier copy) on the top row: rows are Size, Modifier, Title, Detail. With no modifier, the size moves down into the Modifier row so it sits right above the name. It's painted with the tier's `TextStyle`. `PedestalConfig.InfoHeightStuds` went from 7.5 to 8, so the name and $/s stay where they were. Tool names, the pedestal prompt and the Roks panel still use the prefixed name ("Colossal Bloky").
