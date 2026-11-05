# Animal Pets: config swap and save migration plan

Status: code, migration and Studio changes built on branch `animal-pets-swap`, 2026-11-04. Not merged and not tested in play. This is what puts the 32 animals in the game. Models, textures and icons are already done; see `AnimalPetsPlan.md` and the vault note Animal Pets.

Income, odds, rarities, prices and traits don't change. Only which model and name each Pet uses.

## 1. Old to new

Each old Pet becomes the new Pet of the same zone and rarity.

| Zone | Common | Uncommon | Rare | Epic | Legendary | Secret |
|---|---|---|---|---|---|---|
| Forest | Bloky → Bunny | Sprout → Squirrel | Shroomy → Fox | Nesty → Owl | Berry → Bear | Treebo → Unicorn |
| Desert | Pointy → Gecko | Spike → Armadillo | Howdy → Scorpion | Flowy → Vulture | Ankhy → Camel | Sunny → Sphinx |
| Jungle | Roly → Monkey | Leafy → Toucan | Viney → Sloth | Coco → Tiger | Tiki → Gorilla | Bloomy → Panther |
| Ocean | Drip → Crab | Bubbly → Clownfish | Shelly → Turtle | Reefy → Octopus | Glowy → Shark | Chompy → Narwhal |
| Snow | Hexy → Penguin | Beanie → Seal | Cozy → Reindeer | Stacky → Walrus | Climby → ArcticWolf | Starry → Yeti |
| Exclusive | | | | | Champ → Capybara | Kingy → KingRex |

No new key matches an old one, so the mapping can't collide. Display names are the real names, with "Arctic Wolf" and "King Rex" spaced.

## 2. Code changes

| File | Change |
|---|---|
| `Config/PetConfig.luau` | Rename all 32 keys, `DisplayName` and `ModelKey`. Keep every other value. King Rex keeps `IncomeRule`, `IncomeMultiplier` and `AuraKey` |
| `Config/GeodeConfig.luau` | 30 `PetKey` values, with weights unchanged |
| `Config/IndexConfig.luau` | The five `Entries` lists |
| `Config/EnemyConfig.luau` | `PetKeys` and `FallbackPetKey`, which become Bunny, Gecko, Monkey, Crab and Penguin |
| `Config/TutorialConfig.luau` | `FirstPetKey` becomes Fox |
| `Config/MonetizationConfig.luau` | `StarterPack.PetKey` becomes Capybara. The exclusive's `Key` and `PetKey` become KingRex. The gift's `Target` becomes KingRex |
| `Config/AdminConfig.luau` | Four preset Pet lists |
| `Data/PlayerData.luau` | The save migration in section 3 |

**Exclusive details found while planning:**
- Gifts use `Target` as both a `PetConfig` key and an `Exclusives` key, so the exclusive's `Key` can't stay "Kingy" while its Pet changes. All of them move together.
- `StockKey = "Kingy_1"` stays, so the sold count of 500 carries over. It's only a DataStore key that players never see.
- The gift's own `Key = "Exclusive_Kingy"` stays, so unclaimed `GiftCredits` still work.

## 3. Save migration

A new `src/server/Data/PetKeyMigration.luau` holds the table above. `PlayerData.Migrate` applies it to:

- `Pets[id].Key`, which keeps size, trait, modifier, slot and income as they are.
- `Index.Pets`: move counts to the new key, adding them if both exist.
- `Index.Claimed.Pets`: move the claims, so nobody can claim the same reward twice.
- `PendingPets`: move and add counts.
- `Exclusives`: Kingy becomes KingRex.

It must be safe to run every time a save loads. Old keys are only ever moved, and a save with no old keys changes nothing.

**No `SchemaVersion` bump.** `DataService` runs `Validate` before `Migrate`, and `Validate` rejects any version other than 1, so a bump would need more changes for no benefit. The existing migrations in `Migrate` also run this way without a version. This replaces the note in `AnimalPetsPlan.md` that said to bump it.

**Rollback warning:** once a save has migrated, an older server won't recognise its Pet keys. Don't roll the game back past this change without a plan for that.

## 4. Studio changes

- `Workspace.ExclusiveStand`: set the `Exclusive` attribute to KingRex and the billboard `Title` from "Kingy" to "King Rex".
- Placeholder text that code overwrites at runtime says Bloky, Sprout or Shroomy in `HatchReveal`, `Index`, `Pets`, `EnemyFight` and the two `Assets.VFX.Pedestal` labels. Update it to animal names for tidiness.
- After testing, move the 32 old `Model_Pet_*` rock models to `ServerStorage` and remove their `AssetRegistry` entries. Don't delete them.

`ServerStorage` backups can stay as they are.

## 5. Your decisions

1. **Loading screen:** `StarterGui.LoadingCover` bounces a Bloky image. Keep it as a mascot, or use an animal? I'd use the Fox.
2. **Pets button:** the HUD button shows a grey rock Pet. It should become an animal too. I'd use the Fox.
3. **Robux product names:** the developer products are still named Kingy, Gift: Kingy and so on, and players can see those names on purchase prompts. Renaming goes through the API, and I'd do it at the same time as the swap. Should I?
4. **Golem Pet:** it stays a rock as planned, and isn't built yet, so nothing changes here.

## 6. Order

1. **Commit first.** 25 `src` files have uncommitted work from several sessions on `master`, including `PetConfig`, `GeodeConfig`, `EnemyConfig`, `MonetizationConfig` and `TutorialConfig`. Without a clean point, this swap can't be reviewed or undone separately. Your call on how to commit it.
2. Make the code and migration changes, and run `check.ps1`.
3. Make the Studio changes.
4. Test, below.
5. Commit the swap on its own.
6. Rename the products if you agree.
7. Archive the old rock models.

## 7. Testing

**Save migration:** load a save holding old Pets, including Pets on pedestals, Index claims and Kingy. Check nothing is lost, income is unchanged and claims can't be repeated. Load it a second time and check nothing changes.

**In play, for the shapes most likely to cause trouble:**
- King Rex on the exclusive stand at 3x, with the gold aura, on a pedestal and held overhead.
- The Squirrel, Scorpion, Shark, Narwhal, Crab and Monkey on pedestals and held, since they stick out furthest.
- The hatch reveal and in-world label height.
- Idle breathing, blinking and hopping. The breathing code scales each part around the body, so check nothing separates, especially King Rex.
- Enemy fights: giant Bunny, Gecko, Monkey, Crab and Penguin, including their health label height and the camera shots.
- The tutorial's Huge Fox, the Index, Pets panel, Sell Shop, toolbar, gifts and starter pack.
- Neon parts, and the studs on the Tiger and Panther.

**Expect some tuning:** the old Pets were all about the same size, and these aren't. King Rex is 5.4 studs tall against about 2 for a rock Pet, so pedestal and held positions may need per-Pet offsets, which would be a small extra change.
