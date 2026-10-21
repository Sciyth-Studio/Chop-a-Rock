---
description: Four Robux cash packs worth N geodes of the player's zone; pressing a buy you can't afford opens the Robux prompt for the smallest covering pack straight away
type: system
updated: 2026-10-21
---
# Cash Packs

Built 2026-10-21. The user asked for currency developer products "that can fill the gap" instead of renaming the stand products, picked packs scaled to the player, and wanted them prompted "every time they can't afford something instead of just being told they don't have enough". Numbers are drafts.

**Packs** (`CashPackConfig.Packs`, products created through Open Cloud, see [[Open Cloud Key]]):

| Pack | Product id | Robux | Worth |
|---|---|---|---|
| Small | 3720804848 | 25 | 3 geodes |
| Medium | 3720804851 | 79 | 12 geodes |
| Large | 3720804855 | 199 | 40 geodes |
| Huge | 3720804860 | 499 | 150 geodes |

"Geodes" means the price of the geode for the zone the player's strength reaches (`GeodeOrder.ForStrength`, the same zone the [[Geode Shop]] opens on). `Utils/CashPack.Value` works it out. The server grant (`PurchaseService/Products`) runs it at receipt time, so the amount follows the player's zone. `CashPack.Covering(shortfall, strength)` picks the smallest pack that covers the gap, or Huge if none does.

**No middleman (user, 2026-10-21):** "no middleman between pressing the button to buy the item and the robux prompt". Pressing a buy you can't afford calls `CashPackController:Prompt(shortfall)`, which opens Roblox's purchase prompt for the covering pack directly. A first version had a "Need More Cash?" pick-a-pack popup. The user dropped it, and its ScreenGui is parked in `ServerStorage.UIBackup.CashPacks`. After a purchase the controller plays `SFX_Money_Gain` and notifies "+$X cash!". It doesn't auto-buy the item.

**Prompted from:** Aura Shop buy (`Screens/Shop`), Cannon Shop buy once strength is met (`Screens/CannonShop`), Geode Shop buy (`Screens/GeodeStand`, tutorial prices included), Roks panel +1 Slot (`Screens/Roks`), and the training Upgrade sign's cash button (`Components/TrainingUpgradeSign`).

**Replaced:** the training sign's purple Robux button (removed from `Assets.Models.Base.Model_BasePlot`; the cash button now spans the sign). The five stand products (3719074519/40/43/45/47) are off sale and have no grant. See [[Rebirth Gated By Strength]].
