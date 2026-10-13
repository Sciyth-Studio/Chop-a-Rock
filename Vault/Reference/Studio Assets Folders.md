---
description: ReplicatedStorage.Assets is sorted into feature subfolders (2026-10-11); AssetRegistry finds templates recursively, so a new asset goes in its subfolder.
type: reference
---
# Studio Assets folders

Since 2026-10-11 `ReplicatedStorage.Assets` categories are split into subfolders:

- **Models:** `Rocks/<Zone>` (Forest, Desert, Jungle, Ocean, Snow; each holds that zone's `Model_Rock_*`, `Model_RockPreview_*` and `Model_RockSplit_*`), `Model_Rock_Diamond` loose in `Rocks`, plus `Roks`, `Geodes`, `Base`, `Training` (board split and `Model_ArmPreview`).
- **VFX:** `Chop` (hit, crack, break, Perfect/Master, cash pop, `CashPopText`, `VFX_DamageNumber`), `Rock` (rise dust, `RockLabel`, `ChopPrompt`), `Rush`, `Diamond`, `Aura`, `Pedestal`, `Hatch`, `Level`, `HotStreak`, `Training`.
- **Sounds:** already grouped by feature before this.

`AssetRegistry.get` searches each category recursively (`FindFirstChild(name, true)`), and so do the VFXShowcase plugin and `rock-model/scripts/wire_rocks.luau`, which puts replacements back in the old one's folder. Instance names must stay unique within a category. Never index a template by path (`Assets.VFX.VFX_X`); use AssetRegistry or `FindFirstChild(name, true)`.

Older notes that say a template is in `Assets.Models` or `Assets.VFX` still hold; it is now in a subfolder.

Related: [[VFX Showcase]], [[Zone Line]]
