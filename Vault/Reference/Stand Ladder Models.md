---
description: Meshlab builds for the 20-stand training ladder (2026-11-09) - one Stand<Family>.luau per build, seed convention, part names per family, approval and export status
type: reference
---
# Stand ladder models

The 20-stand ladder from [[Rebirth Removed]] is modelled in meshlab ([[Meshlab]]) from the lineup sheets in `assets/Training/Stands/` (prompts in `Prompts.md` there). Wood was remodelled too (user, 2026-11-09, "to maintain style parity"), keeping the old colours and the two-plank board; the old model is in [[Training Stand Reference]].

## Files and seeds
- `tools/meshlab/models/Stand<Family>.luau`: `StandWood`, `StandForgedMetal`, `StandPreciousMetal`, `StandCutGem`, `StandRawCrystal`, `StandMeteorite`, `StandDarkMatter`, `StandNeutronStar`. Shared helpers are in `StandKit.luau` (`Kit.Run`, chamfered `Kit.Ring`/`Kit.Stack` lofts that cut cleanly at x = 0, `Kit.Rough`, `Kit.Plain`).
- Seeds: 0 = white meshes for export (whole breakable plus `_L`/`_R` halves cut at x = 0), 1..n = one colour, 11..10+n = that colour with the split pulled apart. (`StandForgedMetal` predates the kit: 6/16 are its lineups.)
- **One white upload per recolour family.** Each stand template gets its look from part `Color` and `Material`, not vertex colours. Glowing bits (band, lava, crystals, glow strips, star) are their own plain meshes (no studs), so they can be Neon.
- Previews: `assets/Training/Stands/<Family>_Preview_v<N>.png` (rows: front, 3/4, split). Export: run seed 0 and pack every OBJ in `out/Stand<Family>_s0/` into one FBX with `export_fbx.py`; MeshParts load named after the OBJs.
- All keep the old footprint: about 5.5 wide, breakable centre 3.6-3.75 up, front -Z, pivot bottom centre.

## Parts (breakable first, its props after it)
- Wood: `Frame` (with the brace fins and low crossbar); `Board` (two stacked planks).
- Forged metal: `Frame`; `Plate` + `Band` + `Rivets`. The bracket caps on top are part of `Plate`, so they don't float when it breaks.
- Precious metal: `Frame` (with the diamond emblems); `Bar` (ingot).
- Cut gem: `Frame` (with prongs); `Gem` (plain, Glass in Studio).
- Raw crystal: `Frame`; `Slab` + `Crystals`. Each crystal sits in the half its base is in, so none is cut.
- Meteorite: `Frame`; `Rock` (chunks) + `Lava` (a core showing through the gaps as cracks).
- Dark Matter: `Frame` + `Glow`; `Cube` (swirl = decal in Studio).
- Neutron Star: `Frame` (with the crossed rings) + `Glow`; `Star`.

## Approved and in Studio (2026-11-09)
- The user approved everything: forged metal v2 (plate 1.0 deep, asked for), Wood v2, the rest at v1. Wood v1's split preview looked like the halves floated; the preview had lifted them. Split previews now only spread the halves sideways.
- One FBX per family in `assets/Training/Stands/<Family>/Stand_<Family>.fbx`, holding the stand and split meshes. Group assets ("Training Stand <Family>"): Wood 96898548347247, ForgedMetal 80079650794780, PreciousMetal 94961018336031, CutGem 105930851437792, RawCrystal 72608630905232, Meteorite 90047769257640, DarkMatter 80190826625529, NeutronStar 75285028803899.
- Templates `Model_TrainingStand_<Key>` + `Model_TrainingSplit_<Key>` are in `ReplicatedStorage.Assets.Models.Training` for Wood, Bronze, Iron, Steel, Titanium, Tungsten, Silver, Gold, Platinum, Obsidian, Diamond, BlackDiamond, Amethyst, Emerald, Sapphire, Ruby, Painite, Meteorite, DarkMatter, NeutronStar. All are registered in `AssetRegistry`.
  - The pivot is the bottom centre: Frame `PivotOffset` = its CFrame inverse, the Frame is the PrimaryPart. A moved copy stays upright.
  - The breakable is tagged `TrainingBoard`, with `SplitModel` set. Props sit under it with CanCollide off. A copy of the old Wood `SignAnchor` + `StandSign` ("<Name> Training") is under each breakable.
  - Materials: studded parts are Plastic + `2022 Inlet`. Neon: Tungsten band, crystals, lava, glow strips, star. Glass gems with Transparency 0.1 / 0.35 / 0.05 (Obsidian / Diamond / Black Diamond), set on the split pieces too, because `SplitModel.Spawn` copies Color/Material but not Transparency. The Dark Matter cube is plain Plastic for a swirl decal.
- The old `Model_TrainingStand_Wood`, `Model_TrainingStand_Steel`, `Model_TrainingSplit_Steel` and the old stand from `Model_BasePlot` are in `ServerStorage.TrainingStandsBackup_Before20Ladder`. The name clash means the current Steel tier now shows the new forged Steel.
- **Wood lives in `Model_BasePlot`:** `Stands.Apply` never swaps a plot whose key is Wood, so the new Wood was cloned into `Model_BasePlot.TrainingStand` (StandKey Wood). `ServerStorage.Model_BasePlot_PreHatch` still has the old one.
## In code (2026-11-09)
- `TrainingConfig.Stands` is the 20-stand ladder, prices and strength per rep from [[Rebirth Removed]]. Break sounds reuse the old six: Wood `Chop`; forged metal `Steel`; precious metal `Vault`; raw crystal `Brick`; cut gem `Core`; space `Cosmic`, plus `VFX_Train_CosmicBreak`. No other stand has a break effect yet (VFX deferred by the user).
- Old saves: `PlayerData.Migrate` remaps a save with no `TrainingLadder` by price through `TrainingConfig.OldTierMap` (Wood 1, Brick 3 Iron, Steel 5 Gold, Vault 7 Amethyst, Core 9 Titanium, Cosmic 11 Ruby), then sets `TrainingLadder` = `LadderVersion` (2). New saves start on 2. Admin snapshots without the field are remapped the same way. Admin presets: Desert = Iron (3), Late Game = Silver (4).
- `TrainingMinigameConfig.PieceColors` has a colour per stand key.
- The Brick/Vault/Core/Cosmic templates and their registry entries are unused now but not deleted.
- In the [[Balance Model]] since v15.
- Gotcha (fixed 2026-11-09): the copied `StandSign` BillboardGuis had no `Adornee`, so they drew at the breakable's centre on top of the Train prompt. The old stands set `Adornee` = the `SignAnchor` attachment (about 4 studs above the board). Fixed on all 20 templates and `Assets.Models.Base.Model_BasePlot`. A copied sign always needs its Adornee re-set. The copied `SignAnchor` also kept the old Wood offset (2.66 studs behind the board), which looked off to the side in game; every anchor is now straight above the board centre at 7.4 studs over the stand pivot (sign bottom about 6.65, clear of the crystals' 6.12 top).
- Not done: the Black Diamond sparkles and Dark Matter swirl (VFX/decal work); playtesting.
