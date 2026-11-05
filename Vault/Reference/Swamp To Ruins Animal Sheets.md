---
description: 2026-11-04 six-view sheets for the Swamp, Savanna, Bamboo, Volcano and Ruins animal Pets; what to take from them; batch-built in one .blend per zone.
type: reference
---
# Swamp to Ruins animal sheets

Prompts: `assets/Pets/Animals/<Zone>.md`. The front is the top-left view. Sheets are also at `assets/Pets/<Name>/<Name>_sheet.webp`. Builds: `assets/Pets/<Zone>/<Zone>Animals.blend`. Approved and exported 2026-11-04 to `assets/Pets/<Name>/<Name>.fbx`, each checked by re-import. Uploaded to the group and loaded in Studio 2026-11-04 as `Model_Pet_<Name>` in `ReplicatedStorage.Assets.Models.Pets`, with Neon and textures set and `AssetRegistry` entries, shifted so the body's XZ centre is on the origin. Config doesn't use them yet. Group Model assets: Frog 120367187515942, Duck 127180419333894, Snail 132793926453834, Beaver 103752115844992, Alligator 121719987432123, Hydra 73237167673519, Zebra 80899253480285, Giraffe 116989295634970, Rhino 136712896837839, Elephant 78121644911790, Cheetah 106272408570702, Lion 127157038704549, Beetle 107539943647969, Koi 126302882924159, Crane 111222950682675, Panda 133100069354401, RedPanda 113282228673131, MonkeySensei 77305454613435, Salamander 134038531560040, ImpCat 81123979285615, LavaTortoise 125209370689676, Hellhound 101065850723773, Dragon 108415409929321, Phoenix 118648334241505, Bat 115739522318051, Raven 70483097351009, WizardCat 107954191611924, GuardDog 76101525353364, Minotaur 131818493493863, NineTailedFox 97164786514554. Textures, as Image assets: Zebra 134880057800566, Giraffe 117120893173028, Cheetah 78294015828963, Koi 80971736636046, Hellhound 105468077907039, RedPanda 128253688023690, LavaTortoise shell 137669091306620.

## Swamp
![[Frog Reference Sheet.webp]]
![[Duck Reference Sheet.webp]]
![[Snail Reference Sheet.webp]]
![[Beaver Reference Sheet.webp]]
![[Alligator Reference Sheet.webp]]
![[Hydra Reference Sheet.webp]]

## Savanna
![[Zebra Reference Sheet.webp]]
![[Giraffe Reference Sheet.webp]]
![[Rhino Reference Sheet.webp]]
![[Elephant Reference Sheet.webp]]
![[Cheetah Reference Sheet.webp]]
![[Lion Reference Sheet.webp]]

## Bamboo
![[Beetle Reference Sheet.webp]]
![[Koi Reference Sheet.webp]]
![[Crane Reference Sheet.webp]]
![[Panda Reference Sheet.webp]]
![[RedPanda Reference Sheet.webp]]
![[MonkeySensei Reference Sheet.webp]]

## Volcano
![[Salamander Reference Sheet.webp]]
![[ImpCat Reference Sheet.webp]]
![[LavaTortoise Reference Sheet.webp]]
![[Hellhound Reference Sheet.webp]]
![[Dragon Reference Sheet.webp]]
![[Phoenix Reference Sheet.webp]]

## Ruins
![[Bat Reference Sheet.webp]]
![[Raven Reference Sheet.webp]]
![[WizardCat Reference Sheet.webp]]
![[GuardDog Reference Sheet.webp]]
![[Minotaur Reference Sheet.webp]]
![[NineTailedFox Reference Sheet.webp]]

Take from them:
- **Body:** Bloky's cube, except the Dragon and Hydra, which may break the rule (user, 2026-11-04). The Alligator, Salamander, Guard Dog, Griffin and Wizard Cat were drawn with longer or taller bodies, but they're still built on the cube unless the user says otherwise.
- **Ids below predate studs:** the `Animal Stud` rollout (2026-11-04) re-uploaded every model and painted texture; see [[Animal Pets]].
- **Painted, not modelled:** patterns that would use too many triangles. Built with painted bodies (`<Name>_body.png`, set on a white part): Zebra, Giraffe, Cheetah, Koi, Salamander, Nine-Tailed Fox. Each painted Pet also needs gold and blue textures for the tints in [[Animal Pets]].
- **Second pass (2026-11-04):** the user asked for every issue from a sheet comparison to be fixed. The Alligator, Beetle and Koi now have their own reshaped bodies, so they aren't Bloky's exact cube. Keep wings angled back and parts chunky, because thin, flat parts vanish from the side.
- **Reuse first (user, 2026-11-04):** many of these are already represented in the first 32, so reuse their parts instead of redesigning them. Bases: Monkey Sensei = Monkey; Wizard Cat = Panther; Nine-Tailed Fox = Fox (nine scaled tails); Salamander = Gecko. Borrowed parts: Hellhound ears from the Arctic Wolf; Zebra, Giraffe and Rhino ears from the Fox and hooves from the Reindeer; Beaver and Panda feet and nose from the Bear; Cheetah and Lion snout and nose from the Panther; Raven wings, beak and feet and Griffin beak and feet from the Vulture; Crane wings and feet from the Toucan; Phoenix beak and feet from the Owl.
- **Lava textures:** the Hellhound's cracks are on its painted body. The Lava Tortoise's drips are on `assets/Pets/LavaTortoise/LavaTortoise_shell.png`, so that texture goes on the `LavaTortoise_Shell` part, not the body. Textures can't be Neon, so these don't truly glow.
- **Alligator and Griffin:** may break the body rule (user, 2026-11-04). The Alligator has a long, low body; the user calls it a crocodile, but the Pet is still named Alligator. The user dropped the Griffin (2026-11-04), saying it might not work in this style, even after it broke the body rule. The Minotaur replaces it as Ruins Legendary, chosen over a Stone Gargoyle and a Mimic. Its prompt stands alone and doesn't attach the lineup. The Griffin's sheet and build are unused; don't export them. The Minotaur (`Minotaur_` parts in `RuinsAnimals.blend`) sits 0.2 units higher than Bloky so its tall hooves and gold cuffs show, like its sheet. It's 1574 triangles.
- **Red Panda and Nine-Tailed Fox:** the Red Panda's face markings are painted on its body. The Nine-Tailed Fox has no speckles (user, 2026-11-04), so its body is plain.
- **Over 800 triangles:** Hydra 1712, Nine-Tailed Fox 1192, Dragon 1148, Monkey Sensei 1062, Wizard Cat 1028, Phoenix 1022, Alligator 924, Snail 900, Guard Dog 890, Griffin 876.
- **Effects, not modelled:** the Cheetah streaks, Nine-Tailed Fox portal, Lion glow and Phoenix flames, through `AuraKey` in `PetConfig`. Keep effects to Legendary and Secret.
- **Sheet mistakes to ignore:** the Koi's tail fin is drawn off to one side, the Monkey Sensei's side view has flat ear slabs, the Panda's eye outline is doubled, and the Hydra's top view has a narrower middle head.

## Exported models

Sizes are studs W x D x H. Every Pet also has `_Eyes` and `_Pupils`, which aren't listed.

### Swamp

| Pet | Tris | Size | Parts and colours (RGB) |
|---|---|---|---|
| Frog | 672 | 2.88 x 2.1 x 2.1 | `Frog` 120, 230, 30; `_Belly` 250, 225, 115; `_Legs` 135, 240, 35 |
| Duck | 386 | 2.64 x 2.1 x 2.98 | `Duck` 245, 245, 245; `_Bill` 255, 150, 20; `_Feet` 255, 145, 20; `_Tail` 232, 232, 238; `_Wings` 232, 232, 238 |
| Snail | 900 | 2.11 x 2.62 x 2.66 | `Snail` 240, 160, 130; `_Shell` 255, 145, 25; `_Stalks` 245, 165, 135; `_Swirl` 180, 85, 25 |
| Beaver | 656 | 2.16 x 2.4 x 3.06 | `Beaver` 185, 110, 60; `_Ears` 175, 100, 55; `_Feet` 85, 60, 45; `_Grid` 60, 40, 30; `_Muzzle` 250, 205, 150; `_Nose` 25, 25, 25; `_Tail` 90, 60, 45; `_Teeth` 250, 250, 250 |
| Alligator | 924 | 2.24 x 2.0 x 5.11 | `Alligator` 140, 195, 25; `_Feet` 125, 185, 25; `_Glow` 205, 255, 40; `_Nostrils` 60, 90, 15; `_Ridges` 45, 130, 35; `_Snout` 140, 195, 25; `_Tail` 140, 195, 25; `_Teeth` 245, 245, 245 |
| Hydra | 1712 | 5.04 x 5.12 x 5.39 | `Hydra` 35, 185, 70; `_Feet` 20, 150, 60; `_Glow` 205, 255, 40; `_Heads` 35, 185, 70; `_Necks` 35, 185, 70; `_Nostrils` 15, 85, 40; `_Patches` 15, 120, 55; `_Snouts` 45, 200, 80; `_Tail` 35, 185, 70; `_Teeth` 245, 245, 245 |

### Savanna

| Pet | Tris | Size | Parts and colours (RGB) |
|---|---|---|---|
| Zebra | 462 | 2.0 x 2.6 x 2.82 | `Zebra` 245, 245, 245; `_EarInner` 250, 150, 150; `_Ears` 245, 245, 245; `_Hooves` 40, 38, 40; `_Mane` 40, 38, 40; `_Muzzle` 40, 38, 40; `_Tail` 245, 245, 245; `_Tuft` 40, 38, 40 |
| Giraffe | 538 | 2.0 x 2.8 x 2.64 | `Giraffe` 255, 175, 30; `_EarInner` 250, 165, 130; `_Ears` 255, 175, 30; `_Hooves` 90, 55, 35; `_Horns` 255, 175, 30; `_Knobs` 90, 55, 35; `_Snout` 245, 190, 110; `_Tail` 255, 175, 30; `_Tuft` 90, 55, 35 |
| Rhino | 500 | 2.0 x 2.33 x 2.76 | `Rhino` 140, 140, 146; `_EarInner` 250, 150, 150; `_Ears` 140, 140, 146; `_Feet` 75, 75, 80; `_Horn` 250, 235, 200; `_Snout` 140, 140, 146; `_Tail` 140, 140, 146 |
| Elephant | 618 | 3.8 x 2.24 x 3.0 | `Elephant` 125, 140, 175; `_EarInner` 250, 165, 160; `_Ears` 125, 140, 175; `_Feet` 125, 140, 175; `_Nails` 250, 238, 210; `_Tail` 125, 140, 175; `_Trunk` 125, 140, 175; `_Tuft` 125, 140, 175; `_Tusks` 250, 238, 210 |
| Cheetah | 548 | 2.08 x 2.44 x 3.5 | `Cheetah` 250, 170, 30; `_EarInner` 250, 225, 180; `_Ears` 40, 38, 40; `_Feet` 250, 225, 180; `_Nose` 25, 25, 25; `_Snout` 250, 235, 205; `_Tail` 250, 170, 30; `_TailBands` 40, 38, 40 |
| Lion | 598 | 3.04 x 2.93 x 3.45 | `Lion` 255, 175, 40; `_EarInner` 250, 180, 100; `_Ears` 255, 205, 60; `_Feet` 250, 225, 180; `_Mane` 255, 190, 40; `_Nose` 40, 30, 30; `_Snout` 250, 240, 225; `_Tail` 255, 175, 40; `_Tuft` 90, 60, 45 |

### Bamboo

| Pet | Tris | Size | Parts and colours (RGB) |
|---|---|---|---|
| Beetle | 622 | 2.34 x 2.88 x 2.56 | `Beetle` 28, 212, 202; `_Antennae` 20, 125, 140; `_Horn` 20, 125, 140; `_Legs` 50, 50, 55; `_Seam` 15, 130, 130 |
| Koi | 624 | 2.67 x 2.58 x 3.43 | `Koi` 250, 232, 212; `_Fins` 252, 225, 200; `_Mouth` 25, 25, 25; `_Tail` 255, 225, 190; `_TailRoot` 245, 85, 35; `_Whiskers` 252, 225, 200 |
| Crane | 548 | 2.8 x 2.15 x 2.72 | `Crane` 245, 245, 245; `_Band` 40, 38, 40; `_Beak` 55, 55, 60; `_Cap` 250, 45, 35; `_Feet` 60, 60, 65; `_WingTips` 40, 38, 40; `_Wings` 240, 240, 244 |
| Panda | 576 | 2.2 x 2.5 x 2.18 | `Panda` 245, 245, 245; `_Black` 40, 38, 40; `_Feet` 40, 38, 40; `_Nose` 25, 25, 25; `_Snout` 250, 250, 250 |
| RedPanda | 576 | 2.04 x 2.66 x 3.5 | `RedPanda` 230, 100, 40; `_EarInner` 230, 100, 40; `_Ears` 250, 238, 225; `_Feet` 75, 45, 35; `_Nose` 60, 40, 35; `_Snout` 250, 238, 225; `_Tail` 230, 100, 40; `_TailGlow` 255, 225, 90 |
| MonkeySensei | 1062 | 3.36 x 3.72 x 4.36 | `MonkeySensei` 190, 190, 195; `_Beard` 250, 250, 250; `_Cream` 232, 232, 236; `_Ears` 190, 190, 195; `_Hat` 245, 195, 100; `_Nostrils` 130, 130, 135; `_Ring` 255, 215, 50; `_Tail` 190, 190, 195 |

### Volcano

| Pet | Tris | Size | Parts and colours (RGB) |
|---|---|---|---|
| Salamander | 756 | 2.03 x 2.11 x 3.09 | `Salamander` 255, 140, 20; `_Legs` 255, 130, 15; `_Spots` 75, 50, 40; `_Tail` 255, 140, 20 |
| ImpCat | 722 | 3.28 x 2.76 x 3.2 | `ImpCat` 235, 30, 35; `_EarInner` 250, 130, 130; `_Ears` 235, 30, 35; `_Feet` 40, 38, 40; `_Horns` 40, 38, 40; `_Ribs` 40, 38, 40; `_Tail` 235, 30, 35; `_TailTip` 235, 30, 35; `_Wings` 215, 25, 30 |
| LavaTortoise | 492 | 2.96 x 2.69 x 3.48 | `LavaTortoise` 205, 145, 85; `_Base` 205, 145, 85; `_Crater` 255, 225, 40; `_Feet` 85, 75, 78; `_Lava` 255, 115, 15; `_Shell` 85, 75, 78; `_Tail` 205, 145, 85 |
| Hellhound | 702 | 2.72 x 2.92 x 3.02 | `Hellhound` 72, 65, 66; `_Collar` 40, 35, 35; `_EarInner` 255, 125, 15; `_Ears` 55, 50, 52; `_Feet` 72, 65, 66; `_Flame` 255, 135, 20; `_FlameInner` 255, 225, 50; `_Nose` 255, 125, 15; `_Snout` 55, 50, 52; `_Spikes` 145, 145, 150; `_Tail` 55, 50, 52; `_Toes` 255, 125, 15 |
| Dragon | 1148 | 4.85 x 4.6 x 4.63 | `Dragon` 225, 30, 30; `_Arms` 225, 30, 30; `_Belly` 255, 190, 30; `_BellyLines` 245, 135, 20; `_Brow` 200, 25, 25; `_Crest` 225, 30, 30; `_Horns` 250, 215, 110; `_Legs` 225, 30, 30; `_Nostrils` 120, 15, 20; `_Snout` 225, 30, 30; `_Spines` 205, 25, 25; `_Tail` 225, 30, 30; `_WingRibs` 225, 30, 30; `_Wings` 255, 140, 20 |
| Phoenix | 1022 | 4.96 x 3.55 x 4.11 | `Phoenix` 255, 110, 20; `_BeakFeet` 255, 200, 40; `_Belly` 255, 150, 30; `_Glow` 255, 215, 50; `_Plumes` 240, 60, 25; `_Shoulders` 250, 95, 20 |

### Ruins

| Pet | Tris | Size | Parts and colours (RGB) |
|---|---|---|---|
| Bat | 562 | 3.7 x 3.04 x 2.15 | `Bat` 95, 45, 150; `_EarInner` 255, 130, 195; `_Ears` 95, 45, 150; `_Feet` 105, 50, 165; `_Snout` 145, 90, 200; `_WingRibs` 95, 45, 150; `_Wings` 255, 110, 190 |
| Raven | 442 | 2.74 x 2.1 x 3.45 | `Raven` 40, 55, 105; `_BeakFeet` 135, 135, 140; `_Tail` 45, 60, 115; `_Wings` 32, 45, 90 |
| WizardCat | 1028 | 3.04 x 3.76 x 3.42 | `WizardCat` 48, 48, 54; `_Chest` 245, 245, 245; `_Claws` 245, 245, 245; `_EarInner` 255, 160, 190; `_Ears` 48, 48, 54; `_Hat` 20, 80, 230; `_Legs` 48, 48, 54; `_Nose` 60, 60, 65; `_Snout` 135, 135, 140; `_Stars` 255, 225, 40; `_Tail` 48, 48, 54; `_TailTip` 48, 48, 54 |
| GuardDog | 890 | 2.75 x 4.06 x 2.63 | `GuardDog` 225, 165, 75; `_Ears` 150, 85, 50; `_Feet` 205, 135, 60; `_Helmet` 215, 170, 85; `_Nose` 25, 25, 25; `_Plume` 240, 45, 35; `_ShieldBoss` 250, 195, 45; `_ShieldFace` 150, 130, 100; `_ShieldRim` 240, 180, 40; `_Slits` 45, 38, 30; `_Snout` 150, 85, 50; `_Tail` 150, 85, 50 |
| Minotaur | 1574 | 4.03 x 3.35 x 3.47 | `Minotaur` 165, 65, 40; `_Belt` 190, 130, 60; `_Cuffs` 255, 200, 40; `_EarInner` 235, 175, 125; `_Ears` 150, 58, 36; `_Emblem` 255, 200, 40; `_Hooves` 70, 48, 40; `_HornTips` 255, 200, 40; `_Horns` 250, 225, 175; `_Nostrils` 55, 38, 32; `_Ring` 255, 200, 40; `_Snout` 235, 175, 125; `_Tail` 165, 65, 40; `_TailTuft` 85, 50, 38; `_Tuft` 85, 50, 38 |
| NineTailedFox | 1192 | 2.91 x 2.68 x 3.15 | `NineTailedFox` 75, 35, 150; `_Dark` 50, 25, 105; `_Ears` 75, 35, 150; `_Lilac` 165, 120, 225; `_TailTips` 255, 150, 245; `_Tails` 70, 32, 140 |

Notes for import:
- Painted bodies, set white with the PNG as `TextureID`: Zebra, Giraffe, Cheetah, Koi, Hellhound and Red Panda (`<Name>_body.png`). The Lava Tortoise's texture goes on `LavaTortoise_Shell` (`LavaTortoise_shell.png`).
- Neon parts: Alligator and Hydra `_Glow`; Red Panda `_TailGlow`; Monkey Sensei `_Ring`; Lava Tortoise `_Lava`, `_Crater`; Hellhound `_EarInner`, `_Nose`, `_Toes`, `_Flame`, `_FlameInner`; Dragon `_Belly`; Phoenix `_Glow`; Minotaur `_HornTips`, `_Ring`, `_Emblem`; Nine-Tailed Fox `_TailTips`.
- Effects still to make through `AuraKey`: Cheetah streaks, Nine-Tailed Fox portal, Lion glow, Phoenix flames.
- The Griffin isn't exported. Its objects remain in `RuinsAnimals.blend`.
Related: [[Animal Pets]], [[Desert To Snow Animal Sheets]], [[Reuse Pet Eyes]]
