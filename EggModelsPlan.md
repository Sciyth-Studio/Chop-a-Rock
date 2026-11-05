# Egg models: plan for world 1

Status: **draft, 2026-11-05.** Nothing is built. The looks, colours and sizes are Claude's drafts for the user to change. Section 2 has the decisions that are the user's.

Replaces the 5 geode models with 20 eggs, 2 per zone. This fills in decision D3 of `ZoneGeodesPlan.md` ("2 looks per zone, based on the zone's rocks, purely visual") with eggs instead of geodes. Both eggs in a zone give the same Pets at the same odds.

Why eggs fit now: the Pets are animals ([[Animal Pets]]), so hatching one from an egg makes more sense than cracking it out of a rock. The rocks themselves stay as the game's theme, because each egg is dressed from one of its zone's rocks.

## 1. The 20 eggs

Each look is taken from one rock in that zone, using its props from `Vault/Reference/World 1 Rocks.md` and `Vault/Reference/Zone Rocks Reference.md`. Shell colours are chosen to stand out against the zone floor, since players hunt for these. All colours are drafts, to be judged on the real floor in Studio because the lighting shifts them.

| Zone (floor RGB) | Egg | From | Shell RGB | On the shell |
|---|---|---|---|---|
| Forest (39, 70, 45) | `ForestMossy` | Mossy Boulder | 235, 225, 190 | Thick moss cap with drips, 60, 190, 50 |
| | `ForestMushroom` | Zone decor, see note | 225, 50, 40 | White spots, small mushrooms at the base |
| Desert (160, 132, 79) | `DesertMesa` | Sandstone | 255, 130, 40 | Stepped bands in 200, 70, 30, grass tuft on top |
| | `DesertCactus` | Cactus Boulder | 230, 90, 40 | Two small saguaros, 60, 190, 60 |
| Jungle (50, 130, 40) | `JungleVine` | Vine Boulder | 210, 160, 90 | Wrapped vines, yellow flowers |
| | `JungleTiki` | Tiki Boulder | 255, 170, 0 | Carved face in 95, 62, 38, palm leaves on top |
| Ocean (0, 55, 110) | `OceanReef` | Reef Boulder | 255, 90, 120 | Coral on top, one starfish on the side |
| | `OceanBarnacle` | Barnacle Rock | 0, 190, 255 | Cream cone barnacles |
| Snow (240, 245, 255) | `SnowCap` | Snowy Rock | 40, 110, 235 | Thick white cap with drips |
| | `SnowIcicle` | Drift Boulder | 0, 170, 255 | White snow collar with icicles hanging from it |
| Swamp (50, 70, 40) | `SwampMud` | Muddy Rock | 170, 210, 60 | Mud cap with drips in 85, 60, 35, cattails at the side |
| | `SwampLily` | Reedy Boulder | 40, 190, 150 | Lily pad and pink flower on top |
| Savanna (200, 175, 70) | `SavannaAcacia` | Acacia Boulder | 225, 85, 35 | Small flat-topped acacia on top |
| | `SavannaAnthill` | Anthill Boulder | 130, 85, 55 | Termite spires off-centre on top |
| Bamboo (120, 150, 90) | `BambooStalk` | Shooty Rock | 90, 220, 110 | Ringed segment bands, cone shoots on top |
| | `BambooPagoda` | Pagoda Boulder | 205, 200, 185 | Two red roof tiers (200, 50, 40) as a cap, dark window |
| Volcano (40, 35, 35) | `VolcanoEmber` | Ember Boulder | 60, 50, 50 | Carved cracks, Neon 255, 120, 0 |
| | `VolcanoCrater` | Crater Boulder | 170, 70, 40 | Raised rim on top, Neon pool 255, 90, 0 |
| Ruins (110, 115, 100) | `RuinsRune` | Rune Rock | 90, 85, 110 | Carved runes, Neon 170, 80, 255 |
| | (`RuinsRune` is now painted with the 24 Elder Futhark runes, user 2026-11-05) | | | |
| | `RuinsColumn` | Pillar Boulder | 222, 192, 132 | Fluted grooves, ring at the top, moss patch |

- **Forest note:** the Forest's first two rocks have no props, so only one egg can come from a rock. `ForestMushroom` comes from the zone's Mushroom decor instead. `ForestStone`, a plain speckled grey egg, is the fallback if the rock rule should hold strictly.
- **Left out on purpose:** Fern, Canyon, Kelp, Igloo, Rooty, Grassy, Bamboo Boulder, Smoky and Statue. Igloo is white and would vanish on the Snow floor. Statue's fist is too tall for the height limit. Smoke is left off the crater egg for the first pass ([[Keep Decor Simple]]).
- **Player-facing names:** none per look. Both are "<Zone> Egg". The look names above are only for files and asset keys, as `Model_Egg_<Look>`.

## 2. Decisions for the user

**A. The look stays with the egg after you pick it up. Decided by the user, 2026-11-05.**
Today it can't. `GrantGeodes` takes only a zone key, and the hand, hotbar, pad and hatch all read `GeodeConfig.Geodes[key].ModelKey`. A mushroom egg would turn into a mossy egg the moment it's picked up.

Built as one item per look, the option Claude recommended: add a second key per zone (such as `ForestB`) built in `GeodeConfig`, like the Lucky and Falling keys. The hand, pad and hatch then show the right egg with no other change, and no `PlayerData` change because `data.Geodes` already takes any key. The cost is that each zone can take two hotbar stacks, and geodes fill the hotbar before Pets. One stack that remembers each egg's look was the alternative, but it needs a new saved field and the most code.

**B. Players see the word "egg". Decided by the user, 2026-11-05.**
Otherwise a "Forest Geode" prompt would sit on an egg. The strings change along with the models in step 7, so no egg name shows on a geode. About 15 strings change: `DisplayName` and `ShortName` in `GeodeConfig`, notices in `GeodeFallConfig`, `ToolbarConfig.GeodeCountFormat`, tutorial text in `Tutorial.luau` and `TutorialController`, the zone prompt, and "Lucky Geode" in `ShopCards` and `Gifts`.

Code names and saved keys stay `Geode` (`GeodeService`, `data.Geodes`), so there's no migration and no risk to saves. The user would also rename "Lucky Geode" products on Roblox.

**C. Shell style.**
Recommended: **faceted, low-poly**, like Nesty's eggs and the rocks, about 12 sides and 8 rings. A smooth egg wouldn't match anything else in the game. The geode notes record that the user hates bumps and knobs, so props should be clean shapes and shells stay plain.

**D. Studs. Every egg has them (user, 2026-11-05).**
`Animal Stud` on shells, with props and Neon parts plain, as on the Pets ([[Studs On Models By Default]]). The painted eggs (`JungleTiki`, `VolcanoEmber`, `VolcanoCrater`, `RuinsRune`) have the same studs baked into their textures.

**E. The lineup.**
Approve or change the table in section 1.

## 3. Model rules (from the code)

The code reads these from every egg, so they're requirements, not style.

| Rule | Why |
|---|---|
| Fits inside 6 x 6.9 x 6 studs. Shell about 4.8 wide, 5.6 tall | Spawn spots clear only `ClearanceSize` 8 x 7 x 8, scaled per zone like the eggs. The geodes are 6.2 x 5.3 x 5.2 |
| Model has `PrimaryPart` = the shell | `ZoneGeodeController.buildModel` skips a model without one, so the egg silently never spawns |
| The shell is the lowest part, flat-bottomed | `GeodeFallService/Spawning.Place` seats the model using the shell's size alone and collides only the shell |
| Pivot at bottom centre, on the origin | Pads and the hatch use `PivotTo(spot)` with no correction |
| Keep the shell upright, with its parts as children under one Model | `Tools.build` welds every part to the shell, which becomes the `Handle`, and `HeldGrip` uses the bounding box |
| Under about 800 triangles, including props | Up to 4 per zone, plus 8 pads, in view at once. The shell is about 200 |
| Simple rebuilt props, not the full decor meshes | The decor acacia and bamboo are up to about 2k triangles. This departs from [[Rock Props Reuse Decor]] on cost; they should still look like the decor |

No split models are needed, as `SplitModelKey` is only declared and nothing reads it. No icons are needed yet either: `ItemIcons` and `ItemIconConfig` have no geode entries, so the hotbar and Pets panel draw the 3D model.

## 4. Build order

Uses `model-workflow` and `batch-model`.

1. **User:** answer section 2.
2. **Prompts:** Claude writes `assets/Eggs/Prompts.md`. Two lineups with no images attached, carrying a written style block ([[Decor Without References]]): Forest to Snow, then Swamp to Ruins, 10 eggs each.
3. **User:** runs both lineups in ChatGPT and sends them back. Most eggs are round, so the lineups should be enough. Six-view sheets are only for the ones that aren't clear from a lineup, probably `JungleTiki` and `BambooPagoda`.
4. **Forest pilot:** build the shared shell (`tools/meshlab/models/EggShell.luau`) and the 2 Forest eggs in meshlab with Lune (user, 2026-11-05). The user approved the shell from renders on 2026-11-05 and asked for the rest straight away, so the in-game check moves to step 6. Upload after asking. Load them in Studio, point `ZoneGeodeConfig.Zones.Forest.Looks` at them and have the user look at them on the floor, in the hand and on a pad. Settles shell shape, size and studs before the other 18.
5. **Batch the other 18:** one `tools/meshlab/models/Egg<Look>.luau` per egg, one shared feedback round on renders. Neon cracks, runes and the crater pool go in `part("Glow")`. All 18 built 2026-11-05, waiting on the user's feedback. Then a colour pass on the real floors.
6. **Into Studio:** upload after asking. `Model_Egg_<Look>` in `ReplicatedStorage.Assets.Models.Eggs`, `AssetRegistry` entries, user saves.
7. **Code (done 2026-11-05, not playtested):**
   - `ZoneGeodeConfig.Looks` lists the new keys, and `GeodeConfig.ModelKey` moves to look 1.
   - Add the second keys and pass the spawned look through `ZoneGeodeService` to `GrantGeodes`. `GeodeOrder.Sorted` and the `GeodeConfig.Geodes` loops in `GeodeConfig` and `GeodeFallService/Spawning` must skip them, or `ForStrength`, admin commands and Geode Fall would treat them as extra zones.
   - Change the player-facing strings from "geode" to "egg".
   - Run `check.ps1`.
8. **Playtest (user):** take one in each zone, hold it, place it, hatch it, and see a Geode Fall land. Lucky and Falling eggs use look 1.
9. **Clean up after approval:** remove the old `Model_Geode_*` and `Model_GeodeSplit_*` templates and registry entries, and drop `SplitModelKey`. Update the vault notes.

## 5. Not covered

- **Zones 6-10 can't spawn eggs yet.** They have no `GeodeConfig` entries or `ZoneGeodeConfig.Zones` lines. Their prices and strength gates are in `World1Plan.md` and their hatch times in [[Zone Geodes And Enemies]], but the odds need setting. The 10 eggs can be built before that, and they appear once the zones are added.
- **Sounds:** opening still plays `SFX_Rock_Crack` and `SFX_Rock_Break`. Cracking sounds suit an egg, so they stay for now.
- **Falling and Lucky looks:** they look the same as a normal egg, as they do today with geodes. A distinct look would be separate work.
- **Geode Fall effects:** the meteor still works with an egg, though an egg crashing unbroken is a bit funny. The zone crystal effects stay unless the user wants them changed.
