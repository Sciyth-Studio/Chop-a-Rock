---
description: Index screen (built 2026-10-06): Roks and Rocks pages, silhouettes until found, one-time cash + strength reward per entry, +10% money per completed zone, red badge on the HUD Index button.
type: system
---
# Index

Built from `IndexSystemPlan.md` on 2026-10-06. The user picked a purple header and approved the rest of the plan's recommendations. Layout comes from [[Index UI Reference]]; style is [[Menu Panel Style]].

- **Pages** (`IndexConfig.Pages`): `Roks` (hatch counts, `Index.Pets`) and `Rocks` (break counts per `RockKey`, `Index.Rocks`, recorded on a normal or Master break). Each page has zones; each zone lists entry keys. A Rok zone names its `GeodeKey` for the "1 in N" odds line (base luck).
- **Rewards** (all *draft*): one claim per entry, cash + strength by rarity (`IndexConfig.PetRewards`; rocks use `RockReward`). A completed zone gives a permanent +10% money (`ZoneCashBonus`), applied in RockService after the rebirth multiplier. Claims are stored in `Index.Claimed.Pets / Rocks / Zones` (zone key `Page:Zone`) and kept through rebirth.
- **Code:** `IndexService` owns all `Index` writes (`RecordPet` is called by PetService, `RecordRock` by RockService) and the claim packets `ClaimIndex`, `ClaimIndexZone`, `ClaimAllIndex`. `ReplicatedStorage.IndexRewards` is the shared rule module, so the server, the screen and the badge count the same way. Screen: `Screens/Index.luau`. Badge: `MenuButtons.luau` with `MenuButtonConfig.IndexBadge`.
- **Studio:** `StarterGui.Index.Panel` (1000x700): `Tabs` (`TabTemplate`), `HeaderBar`, `Sections` scroll (`SectionTemplate` with `ZoneName`, `Grid.CardTemplate`, `ProgressRow.Progress` + `ZoneReward`), `Detail` (`Preview`, `EntryName`, `Rarity`, `Odds`, `Stat`, `Count`, `Rewards.RewardTemplate`, `ClaimButton`), `ClaimAll`. Cards are the Geode card (rarity glow + `WeldTexture`) plus a red `Alert` "!" and a full-card `Select` button. `MenuButtons.Container.IndexButton.Badge` shows the waiting count.
- **Rock previews:** `Assets/Models/Model_RockPreview_<RockKey>`, copies of the Workspace rock MeshParts with tags, attributes and highlights stripped. A new rock kind needs one plus an `IndexConfig.RockPreviewKeys` entry.
- **To add a zone:** add it to both pages in `IndexConfig` (geode key and Rok keys; rock keys).
- **Later:** weather-modifier and Golden tabs go in the tab column, with their own `Index` and `Claimed` tables.

Found while testing: when several cash changes landed in one frame (Claim All), the HUD money label could end on an older total, because each floating "+$" animation wrote its own total when it finished. It now writes the latest total.

Related: [[Geode Stand UI Reference]], [[ViewportFrame Gotchas]]
