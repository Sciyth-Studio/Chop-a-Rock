---
description: 2026-11-03 six-view sheets for the Desert, Jungle, Ocean and Snow animal Pets; what to take from them; batch-built in one .blend per zone.
type: reference
---
# Desert to Snow animal sheets

Prompts: `assets/Pets/Animals/<Zone>.md`. The front is the top-left view. Models keep Bloky's real body and eyes, with top parts kept on the body. Builds: `assets/Pets/<Zone>/<Zone>Animals.blend`, one collection per Pet, each holding a copy of the Fox as the body source. Approved and exported 2026-11-03 to `assets/Pets/<Name>/<Name>.fbx`, each checked by re-import. Not uploaded or in Studio yet. Sheets are also at `assets/Pets/<Name>/<Name>_sheet.webp`.

## Desert
![[Gecko Reference Sheet.webp]]
![[Armadillo Reference Sheet.webp]]
![[Scorpion Reference Sheet.webp]]
![[Vulture Reference Sheet.webp]]
![[Camel Reference Sheet.webp]]
![[Sphinx Reference Sheet.webp]]

## Jungle
![[Monkey Reference Sheet.webp]]
![[Toucan Reference Sheet.webp]]
![[Sloth Reference Sheet.webp]]
![[Tiger Reference Sheet.webp]]
![[Gorilla Reference Sheet.webp]]
![[Panther Reference Sheet.webp]]

## Ocean
![[Crab Reference Sheet.webp]]
![[Clownfish Reference Sheet.webp]]
![[Turtle Reference Sheet.webp]]
![[Octopus Reference Sheet.webp]]
![[Shark Reference Sheet.webp]]
![[Narwhal Reference Sheet.webp]]

## Snow
![[Penguin Reference Sheet.webp]]
![[Seal Reference Sheet.webp]]
![[Reindeer Reference Sheet.webp]]
![[Walrus Reference Sheet.webp]]
![[ArcticWolf Reference Sheet.webp]]
![[Yeti Reference Sheet.webp]]

Take from them:
- **Glowing parts (Neon when imported):** Camel tassels, Sphinx gems, Gorilla cheek stripes, Panther claws and tail tip, Shark gills, Narwhal horn, Arctic Wolf ear inners and tail tip, Yeti chest marks.
- **No feet:** Clownfish, Turtle, Shark, Narwhal, Seal and Walrus sit on a flat bottom. The Octopus rests on its arms and the Crab on its legs.
- **Mouths:** Clownfish pout, Turtle and Narwhal smile lines, Shark teeth. See [[Animal Pets]].
- **The Toucan's beak** overlaps the inner rim of its eyes, like its sheet.


## Exported models

Sizes are studs W x D x H. Every Pet also has `_Eyes` and `_Pupils`, which aren't listed.

### Desert

| Pet | Tris | Size | Parts and colours (RGB) |
|---|---|---|---|
| Gecko | 756 | 2.03 x 3.09 x 2.11 | `Gecko` 140, 235, 30; `_Legs` 140, 235, 30; `_Spots` 255, 145, 30; `_Tail` 140, 235, 30 |
| Armadillo | 500 | 2.8 x 4.04 x 2.68 | `Armadillo` 245, 115, 115; `_BandDark` 120, 85, 80; `_BandLight` 175, 130, 115; `_Feet` 105, 70, 65; `_Pink` 245, 115, 115; `_Tip` 105, 70, 65 |
| Scorpion | 660 | 3.01 x 4.18 x 3.51 | `Scorpion` 200, 55, 40; `_Legs` 225, 75, 55; `_Stinger` 255, 205, 30; `_Tail` 200, 55, 40 |
| Vulture | 514 | 2.74 x 2.44 x 2.18 | `Vulture` 115, 85, 80; `_Cap` 250, 140, 150; `_Collar` 240, 235, 225; `_Wings` 90, 65, 60; `_Yellow` 255, 200, 20 |
| Camel | 576 | 2.24 x 2.96 x 2.8 | `Camel` 255, 175, 30; `_Blanket` 235, 65, 45; `_Ears` 255, 175, 30; `_Feet` 105, 70, 50; `_Humps` 255, 175, 30; `_Snout` 245, 195, 130; `_Tail` 255, 175, 30; `_Tassels` 255, 225, 40 |
| Sphinx | 900 | 2.8 x 3.18 x 2.76 | `Sphinx` 255, 200, 40; `_Blue` 30, 130, 230; `_EarInner` 255, 150, 90; `_Gems` 90, 230, 255; `_Gold` 255, 205, 40; `_Nose` 95, 55, 40; `_Tail` 255, 205, 40 |

### Jungle

| Pet | Tris | Size | Parts and colours (RGB) |
|---|---|---|---|
| Monkey | 708 | 3.14 x 2.96 x 3.52 | `Monkey` 185, 95, 50; `_Cream` 250, 210, 160; `_Ears` 185, 95, 50; `_Nostrils` 150, 95, 60; `_Tail` 185, 95, 50 |
| Toucan | 508 | 2.67 x 3.59 x 2.1 | `Toucan` 45, 45, 55; `_BeakMid` 255, 130, 20; `_BeakTip` 35, 35, 40; `_BeakTop` 255, 215, 30; `_Feet` 255, 110, 15; `_White` 245, 245, 245; `_Wings` 45, 45, 55 |
| Sloth | 530 | 2.56 x 2.12 x 2.56 | `Sloth` 150, 115, 90; `_Claws` 245, 225, 190; `_Cream` 240, 215, 180; `_Dark` 95, 65, 50; `_Fur` 150, 115, 90; `_Leaves` 90, 200, 30 |
| Tiger | 592 | 2.0 x 3.26 x 2.96 | `Tiger` 255, 140, 20; `_Dark` 40, 30, 25; `_Nose` 255, 120, 170; `_TailDark1` 40, 30, 25; `_TailDark2` 40, 30, 25; `_TailOrange1` 255, 140, 20; `_TailOrange2` 255, 140, 20; `_TailOrange3` 255, 140, 20; `_TailTip` 245, 245, 245; `_White` 245, 245, 245 |
| Gorilla | 652 | 3.06 x 2.21 x 2.28 | `Gorilla` 55, 55, 62; `_Face` 125, 125, 135; `_Fur` 55, 55, 62; `_Glow` 40, 240, 255; `_Nostrils` 55, 55, 62; `_Silver` 150, 152, 160 |
| Panther | 602 | 2.0 x 3.17 x 2.84 | `Panther` 38, 38, 42; `_EarInner` 55, 55, 60; `_Fur` 35, 35, 38; `_Gold` 255, 195, 30; `_Nose` 25, 25, 25; `_Snout` 80, 80, 85; `_Tail` 35, 35, 38 |

### Ocean

| Pet | Tris | Size | Parts and colours (RGB) |
|---|---|---|---|
| Crab | 528 | 4.08 x 2.04 x 2.1 | `Crab` 250, 45, 35; `_Legs` 250, 45, 35 |
| Clownfish | 436 | 3.38 x 2.97 x 2.74 | `Clownfish` 255, 130, 15; `_Black` 25, 25, 25; `_Fins` 255, 130, 15; `_White` 245, 245, 245 |
| Turtle | 548 | 3.62 x 3.16 x 2.07 | `Turtle` 110, 225, 50; `_Mouth` 25, 25, 25; `_Panel` 220, 135, 75; `_Shell` 185, 105, 55; `_Skin` 110, 225, 50 |
| Octopus | 800 | 2.94 x 2.87 x 2.73 | `Octopus` 230, 75, 225; `_Arms` 240, 90, 235; `_Dome` 230, 75, 225; `_Spots` 255, 150, 245 |
| Shark | 440 | 4.08 x 3.16 x 2.78 | `Shark` 105, 140, 185; `_Fins` 105, 140, 185; `_Gills` 40, 240, 255; `_Mouth` 35, 35, 40; `_Teeth` 245, 245, 245; `_White` 245, 245, 245 |
| Narwhal | 740 | 3.84 x 3.14 x 3.42 | `Narwhal` 130, 195, 250; `_Belly` 230, 235, 245; `_Fins` 130, 195, 250; `_Horn` 250, 250, 255; `_Mouth` 25, 25, 25; `_Spots` 60, 135, 225; `_Tail` 130, 195, 250 |

### Snow

| Pet | Tris | Size | Parts and colours (RGB) |
|---|---|---|---|
| Penguin | 304 | 2.88 x 2.84 x 2.1 | `Penguin` 45, 45, 50; `_Flippers` 45, 45, 50; `_Orange` 255, 140, 15; `_White` 245, 245, 245 |
| Seal | 590 | 3.56 x 3.07 x 1.89 | `Seal` 135, 150, 175; `_Flippers` 135, 150, 175; `_Muzzle` 245, 245, 245; `_Nose` 25, 25, 25; `_Spots` 95, 110, 130 |
| Reindeer | 524 | 2.0 x 2.67 x 3.3 | `Reindeer` 200, 95, 45; `_Antlers` 240, 180, 105; `_Cream` 250, 215, 170; `_Ears` 200, 95, 45; `_Feet` 85, 50, 35; `_Nose` 40, 30, 30; `_Pink` 255, 170, 150; `_Tail` 245, 245, 245 |
| Walrus | 426 | 3.56 x 3.07 x 1.88 | `Walrus` 190, 85, 55; `_Flippers` 190, 85, 55; `_Muzzle` 250, 195, 140; `_Nose` 90, 45, 30; `_Tusks` 245, 245, 245 |
| ArcticWolf | 476 | 2.11 x 3.43 x 2.84 | `ArcticWolf` 135, 160, 195; `_Ears` 135, 160, 195; `_Glow` 110, 220, 255; `_Nose` 25, 25, 25; `_Tail` 135, 160, 195; `_TailTip` 110, 220, 255; `_White` 245, 245, 245 |
| Yeti | 758 | 3.44 x 2.31 x 3.28 | `Yeti` 140, 205, 250; `_Brow` 165, 220, 255; `_Fur` 140, 205, 250; `_Glow` 70, 240, 240; `_Horns` 245, 248, 252; `_Shag` 140, 205, 250 |

Notes for import:
- The Tiger and Panther bodies use painted textures, `Tiger_body.png` and `Panther_body.png` (see [[Animal Pets]]). Set the part white, or the colour will tint the texture.
- The Yeti has its own rounder body. The Walrus's eyes sit 0.12 studs higher than other Pets' to fit its tusks. The Sphinx is 900 tris, allowed because it's a Secret.
Related: [[Animal Pets]], [[Forest Animal Sheets]], [[Reuse Pet Eyes]]
