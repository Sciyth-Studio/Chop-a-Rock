---
description: 2026-11-05 - two egg models per zone replace the geodes; built and switched over in all ten zones, playtested by Claude, not committed; plan in EggModelsPlan.md.
type: decision
---
# Eggs replace geodes (2026-11-05)

The user asked for two egg models per zone to replace the geodes. The plan is `EggModelsPlan.md`: 20 eggs, each dressed from a rock in its zone, purely visual.

**The look stays with the egg after pickup (user, 2026-11-05).** Code can't do that today: `GrantGeodes` takes only a zone key and everything downstream reads `ModelKey`. The plan adds a second item key per zone, so a zone can take two hotbar stacks.

**Players see the word "egg" (user, 2026-11-05).** Code names and saved keys stay `Geode` (`GeodeService`, `data.Geodes`), so there's no migration. The strings change along with the models. The user also renames the "Lucky Geode" products on Roblox.

**Playtested by Claude 2026-11-05 (user on Remote Control), not committed:** all 40 eggs spawn upright on the floor in all ten zones. Checked by running the real prompts: Fled path (Forest), a real fight won (Swamp), Ruins pickup, hold, place, hatch, Lucky Ruins hatching a Nine-Tailed Fox, and Geode Fall. Seen on screen: the hotbar pictures, pad and reveal labels. Not seen: most eggs in their real zones, and the look of the reveal at full speed.

**Zones 6-10 config added 2026-11-05 (user asked):** `PetConfig` (30 animals), `GeodeConfig`, `ZoneGeodeConfig`, `IndexConfig` Pets pages, `EnemyConfig`, `GeodeFallConfig` colours. Income and prices are `World1Plan.md`'s rule, with the 2026-11-03 Pet income multipliers (Swamp x1, the rest x0.75) applied. Hatch 11, 12, 15, 20, 27 min. Odds are `World1Plan.md`'s, with Legendary and Secret x1.2 taken from Common as on the other zones. Gate is the zone's weakest rock, per [[Zone Geodes And Enemies]], not `World1Plan.md`'s second rock. All drafts until a Balance Model pass; the Balance Model was not rerun.

**Switched over 2026-11-05 (user):** every zone now spawns, holds, places and hatches eggs. `GeodeConfig` has a second item per zone (`ForestB` and so on, `IsSecondLook`, `SecondLookSuffix`), left out of `GeodeOrder.Sorted` so prices, cash packs and admin lists still see one per zone, but in `GeodeOrder.All` so they stack and place. `ZoneGeodeConfig.Zones[zone].Looks` lists those item keys, and `ZoneGeodeService` grants the one that spawned. Old saved geodes become that zone's first egg. Players see "egg" everywhere; code, saved keys and admin labels keep `Geode`. Left over: the Lucky card's `IconConfig.LuckyGeode` image is still geode art, the "Lucky Geode" products on Roblox keep their names until the user renames them, and the old `Model_Geode_*` templates stay until the eggs are approved in play.

**Models in Studio 2026-11-05:** 20 `Model_Egg_<Look>` in `ReplicatedStorage.Assets.Models.Eggs` with `AssetRegistry` entries, `Animal Stud` on the bodies. Group Model assets, named "Egg <Look>": ForestMossy 114150917258628, ForestMushroom 85932693194945, DesertMesa 102128612458084, DesertCactus 117078771126248, JungleVine 76258129245906, JungleTiki 84314462052921 (painted, "Egg JungleTiki Painted"; 133719649691888 is the unused raised version), OceanReef 84355443311743, OceanBarnacle 82178205187658, SnowCap 139635300166492, SnowIcicle 136649998021643, SwampMud 130664910402090, SwampLily 99566380882748, SavannaAcacia 81255734224398, SavannaAnthill 125562772056216, BambooStalk 108788624249561, BambooPagoda 137488145364386, VolcanoEmber 128228137805846, VolcanoCrater 93472907249901, RuinsRune 92199937387290 (painted, "Egg RuinsRune Painted"; 135069100717661 is the unused raised version), RuinsColumn 85074058106820. `Workspace.EggShowcase` (EditorOnly, x -1200) shows each pair on a plate in its zone's floor colour.

Open for the user: final approval of the looks in play.

This fills in the geode looks from [[Zone Geodes And Enemies]]. It reverses the old rule in [[Geode Reference]] that a geode mustn't read as an egg.

Related: [[Animal Pets]], [[Zone Geodes]], [[Geode Fall]]
