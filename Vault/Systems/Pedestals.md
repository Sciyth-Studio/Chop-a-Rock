---
description: Roks as Backpack tools, base pedestals earning flat $/s onto green pads, slot buying, Equip Best and the Roks panel (built 2026-10-06).
type: system
---
# Pedestals and Rok tools

Plan and decisions: `PetBaseSystemPlan.md` (approved 2026-10-06), Master Game Plan Decision Log 2026-10-06.

## Server
- `PetService` (folder): `Tools.luau` keeps one `Tool` per unplaced Rok in the Backpack (attribute `PetId`, handle = the Rok model's PrimaryPart renamed `Handle`, scaled by `PetConfig.ToolScale`, `PetConfig.ToolGrip`). Tools are rebuilt whenever a new `Backpack` appears (respawn). `HeldChanged` fires when a Rok tool enters or leaves the character. `PutAway` is called by RockService, GeodeService/Cracking and TrainingService when a chop, crack or training round starts.
- `PedestalService` (folder): `Placement` (place, pick up, Equip Best, buy slot, sanitise bad slots on load), `Earnings` (pure math), `Display` (Rok model `PlacedRok` on the pedestal, pedestal attributes, the `PedestalPrompt`). Prompts are server-made with the `OwnedPrompt` tag, like the geode pit.
- Data: `Pet.Slot` (1-8 when placed), `PedestalSlots` (unlocked count), `PedestalEarnings` (uncollected money per slot, string keys). Slots unlock in `PedestalConfig.UnlockOrder` (1,5,2,6,3,7,4,8: entrance end first, alternating sides).
- Earnings never tick through data. Each slot keeps `Banked` + `Rate` + `BankedAt` (server time); the current amount is `Banked + Rate x elapsed`. Data is flushed every `FlushSeconds` and written directly in `PlayerReleasing`. Offline time comes from `LastSeenAt` (set on every save), at `OfflineRateMultiplier`, capped by `EconomyConfig.OfflineCapSeconds`.
- Collect: owner touches the pedestal's `EarningsPad` (server `Touched`, 1 s cooldown per slot).

## Client
- `Components/Pedestal.luau` (tag `Pedestal`, added by the server) clones `Assets/VFX/PedestalPad` (`Amount`) onto the pad and `PedestalInfo` (`Title`, `Detail`) above the pedestal, and counts the pad up locally from the attributes. Visitors see them too.
- `Screens/Roks.luau` + `StarterGui.Roks` (teal header, copy of the Shop panel): title "X/Y Placed", `Header.SlotButton`, `List.RowTemplate` (`Preview`, `RokName`, `UnequipButton`), `EmptyLabel`, `EquipBestButton`. Opened by the `RoksButton` menu button (was `BagButton`).
- The Delete button shown while holding a Rok (`HeldRok`) was removed the same day; Roks are sold at the [[Sell Shop]] instead.
- `ExpBar.Container` moved to y = 1,-84 so it clears the Roblox hotbar.

## Gotchas
- The pedestal prompt range (10) is measured from the pedestal centre; the pad is 8.25 away, so standing on the pad is just inside range.
- Hotbar icons are empty until the item-icon pipeline (`IconSystemPlan.md`) lands; set `Tool.TextureId` from it then.

Related: [[Base Plot Reference]], [[Index]], [[Menu Panel Style]]
