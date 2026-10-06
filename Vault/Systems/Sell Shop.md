---
description: Green lobby stall where Roks from the Backpack are sold (built 2026-10-06); replaced the Delete button. Panel, sorting, sell price and the shopkeeper.
type: system
---
# Sell Shop

The user asked (2026-10-06) for a shop to sell Roks, so deleting is no longer needed. The layout follows their reference screenshot (a "Sell Pets" panel from another game).

![[Sell Shop UI Reference.png]]

Take from it: the sort sidebar with Select All, the card grid (stat on the card, price bar along the bottom), and the Total Value bar with Sell. The weight label became the rarity, since Roks have no weight.

## World
- `Workspace.SellShop` is a clone of `Workspace.GeodeShop`, 16 studs to its right (x = 74). Green stripes, pad and highlight `0,200,40`. Its sign "Sell Shop" uses the `Green` style colours. The `GojoRok` decoration wasn't copied.
- `ShopPad` attributes: `Screen = SellShop`, `ShopName = Sell Shop` (see [[Shop Pads]]).
- Shopkeeper `Karlosush` (user 531562578), R6, standing behind the counter like the Geode Shop's.

## Code
- Server: `PetService:Sell(player, ids)` handles the `SellPets` packet (`{ String }` in, total `NumberF64` out). One bad id (unknown, duplicate or placed on a pedestal) rejects the whole sale. Money is added with `AdjustCash`, with no multipliers.
- Price: `RokValue.Sell(petKey)` = `MoneyPerSecond x PetConfig.SellValueSeconds` (draft 100).
- Client: `Screens/SellShop.luau` + `StarterGui.SellShop` (lime header, 920x640): `Sidebar.SortList.SortTemplate` (`Arrow`, `Label`), `Sidebar.SelectAllButton` (`Box.Tick`), `Grid` (ScrollingFrame, `CardTemplate` with `Rarity`, `Preview`, `Rate`, `PriceBar.Price`, `Select`), `EmptyLabel`, `Footer` (`Total`, `SellButton`).
- Sorts are listed in `SellShopConfig.Sorts`: Value, Rarity, Newest. A new sort starts descending, and clicking the active one flips it (▼ / ▲, both render in the game font). Ties fall back to value, then id.
- Only Roks in the Backpack are listed (`Slot == nil`).

## Gotcha
- `CreateHumanoidModelFromDescription` in Edit mode: parent the model to Workspace and wait about a second before anchoring. Anchoring first leaves the accessories unwelded and scattered. Position it by its `HumanoidRootPart` (set `PrimaryPart`), because the model's default pivot is 1.5 studs lower.

Related: [[Pedestals]], [[Shopkeeper Avatar]], [[Stand Name Signs]], [[Menu Panel Style]]
