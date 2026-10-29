---
description: Green lobby stall where Roks from the Backpack are sold (built 2026-10-06); replaced the Delete button. Panel, sorting, sell price and the shopkeeper.
type: system
---
# Sell Shop

The user asked (2026-10-06) for a shop to sell Roks, so deleting is no longer needed. The layout follows their reference screenshot (a "Sell Pets" panel from another game).

![[Sell Shop UI Reference.png]]

Take from it: the sort sidebar with Select All, the card grid (stat on the card, price bar along the bottom), and the Total Value bar with Sell. The weight label became the rarity, since Roks have no weight.

## World
- `Workspace.SellShop` is a clone of `Workspace.GeodeShop`, 16 studs to its right (x = 42 since the 2026-10-18 lobby shrink). Green stripes, pad and highlight `0,200,40`. Its sign "Sell Shop" uses the `Green` style colours. The `GojoRok` decoration wasn't copied.
- `ShopPad` attributes: `Screen = SellShop`, `ShopName = Sell Shop` (see [[Shop Pads]]).
- Shopkeeper `GuiltyArcher` (user 467512659, since 2026-10-18; was `Karlosush`, 531562578, kept in `ServerStorage.AuraBackup.Karlosush_SellKeeper`), R6, standing behind the counter like the Geode Shop's. The pose was copied from the old keeper's part offsets from its HumanoidRootPart (set each Motor6D's C0 so the parts land there).

## Code
- Server: `PetService:Sell(player, ids)` handles the `SellPets` packet (`{ String }` in, total `NumberF64` out). One bad id (unknown, duplicate or placed on a pedestal) rejects the whole sale. Money is added with `AdjustCash`, with no multipliers.
- Price: `RokValue.Sell(petKey)` = `MoneyPerSecond x PetConfig.SellValueSeconds`: 60 since 2026-10-19 (was 100). At 100, hatching and selling made money in the Ocean and Snow, which would let the planned auto-open gamepass print cash. 60 keeps the Snow at about 0.8x the geode price, or 0.9x during weather ([[Balance Pass Oct 18]]).
- Client: `Screens/SellShop.luau` + `StarterGui.SellShop` (lime header, 920x640): `Sidebar.SortList.SortTemplate` (`Arrow`, `Label`), `Sidebar.SelectAllButton` (`Box.Tick`), `Grid` (ScrollingFrame, `CardTemplate` with `RarityBar.Rarity` (ribbon, see [[Rarity Ribbon And Modifier Tags]]), `Preview`, `Modifier`, `Rate`, `PriceBar.Price`, `Select`), `EmptyLabel`, `Footer` (`Total`, `SellButton`).
- Sorts are listed in `SellShopConfig.Sorts`: Value, Rarity, Newest. A new sort starts descending, and clicking the active one flips it (▼ / ▲, both render in the game font). Ties fall back to value, then id.
- Only Roks in the Backpack are listed (`Slot == nil`).

## Gotcha
- `CreateHumanoidModelFromDescription` in Edit mode: parent the model to Workspace and wait about a second before anchoring. Anchoring first leaves the accessories unwelded and scattered. Position it by its `HumanoidRootPart` (set `PrimaryPart`), because the model's default pivot is 1.5 studs lower.

Related: [[Pedestals]], [[Shopkeeper Avatar]], [[Stand Name Signs]], [[Menu Panel Style]]

**Freeze fix (2026-10-29):** selling a full Backpack froze the game. `PetService.Sell` removed each Rok with its own `replica:Set({ "Pets", id }, nil)`, so every client observer of `Pets` (Toolbar, Roks panel, Sell Shop, Index and more) rebuilt once per Rok, up to 100 times in one frame. Sell and `RemoveUnplaced` now build the kept table and call `replica:Set({ "Pets" }, kept)` once. Do the same for any future bulk change to Pets.
