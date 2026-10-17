---
description: 2026-10-16 six-view sheets for the six jungle Roks (Roly, Leafy, Viney, Coco, Tiki, Bloomy), the first batch-modelled set; what to take from each.
type: reference
---
# Jungle Rok sheets

Received 2026-10-16 from the sheet prompts in `assets/Roks/Jungle/Prompts.md` (batch mode, see the `model-workflow` skill). Copies in `assets/Roks/<Name>/<Name>_sheet.webp`. Front = the view where the eyes face forward. Body dragon fruit pink 235, 35, 130 ([[Coloured Roks After Forest]]), eyes reused ([[Reuse Rok Eyes]]).

![[Roly Reference Sheet.webp]]
![[Leafy Reference Sheet.webp]]
![[Viney Reference Sheet.webp]]
![[Coco Reference Sheet.webp]]
![[Tiki Reference Sheet.webp]]
![[Bloomy Reference Sheet.webp]]

Take from them:
- **Roly:** new body, Bloky made wider and chunkier with bigger chamfers; no prop.
- **Leafy:** one big lime leaf on a curved stem, arching left to right and wider than the body.
- **Viney:** two vine bands with small leaves crossing the body (an X at the back), passing below and above the eyes; three yellow flowers with orange centres on top.
- **Coco:** five drooping palm fronds from the top centre, two brown coconuts at their base toward the front.
- **Tiki:** grey moai-like stone head on top (brow, big nose, chin, collar) with glowing turquoise eye frames, mouth line, forehead triangle and collar band.
- **Bloomy:** the body sits raised in a giant yellow flower (six outer petals plus an inner ring, front petal low so the eyes show) with green leaves underneath. Much wider than the other Roks.

Build: all six in `assets/Roks/Jungle/JungleRoks.blend`, one collection per Rok, laid out along X for previews (reset `location.x` to 0 before export). Previews `assets/Roks/Jungle/lineup_*.png`. One feedback round: Viney needed a vine across the top joining its flowers (the sheet draws them on vines, not on the bare body). Approved and exported 2026-10-16 to `assets/Roks/<Name>/<Name>.fbx`, checked by re-import (all start at ground level).

Meshes and colours (body 235, 35, 130 + `2022 Small Stud`; eyes and pupils as Bloky's):
- **Roly:** body only, 60 tris, 2.24 x 1.96 x 2.28 studs.
- **Leafy:** `Leafy_Leaf` 90, 220, 30; `Leafy_Stem` 40, 160, 30.
- **Viney:** `Viney_Vines` 50, 190, 35 (about 620 tris); `Viney_Flower_Petals` 255, 220, 0; `Viney_Flower_Centers` 255, 130, 0.
- **Coco:** `Coco_Fronds` 80, 210, 30; `Coco_Coconuts` 125, 70, 30.
- **Tiki:** `Tiki_Head` grey 120, 120, 120; `Tiki_Marks` 0, 230, 255 Neon.
- **Bloomy:** `Bloomy_Petals` 255, 205, 0 Neon (user, 2026-10-16); `Bloomy_Leaves` 60, 180, 30. Body and eyes raised 0.6 studs onto the flower; 4.7 x 2.7 x 4.3 studs, twice the others' width.

In Studio (2026-10-16): uploaded through Open Cloud as group Model assets (Roly 72027607003434, Leafy 84093217154930, Viney 117570926518541, Coco 86502061654584, Tiki 121761499064084, Bloomy 82958782956639), loaded with `InsertService:LoadAsset` into `ReplicatedStorage.Assets.Models.Roks` as `Model_Rok_<Name>`, with `AssetRegistry` entries. Set up like the desert six: PrimaryPart is the body, pivot at bottom centre on the origin, front faces -Z, anchored. Body Plastic + `2022 Small Stud`; props SmoothPlastic, `Tiki_Marks` Neon. In `PetConfig`, the Jungle Geode and the Index Roks page since 2026-10-16 ([[Geode Shop]]). Bloomy shows about 9.4 studs wide on pedestals (x2); user said leave it big.

Gotcha: belt-wrapped vines and petal bases can dip below z = 0. Clamp them to 0 before export, or the bounding box drops the pivot under the body.
