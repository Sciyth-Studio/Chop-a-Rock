---
description: 2026-10-14 six-view sheets for the six desert Roks (Pointy, Spike, Howdy, Flowy, Sunny, Ankhy) with what to take from each and where the views disagree.
type: reference
---
# Desert Rok sheets

Six-view sheets received 2026-10-14 from the step 2 prompts in `assets/Roks/Desert/Prompts.md`, made from the [[Desert Roks Lineup]]. Copies sit in `assets/Roks/<Name>/<Name>_sheet.webp`. All bodies are golden amber 215, 152, 35 ([[Coloured Roks After Forest]]) and reuse Bloky's eyes ([[Reuse Rok Eyes]]). Studs come from `2022 Small Stud` in Studio, not the sheets ([[Tintable Mesh Textures]]).

## Pointy (Common)
![[Pointy Reference Sheet.webp]]
- New body, not Bloky's: a square-based pyramid, about as tall as wide, broad chamfer on every edge and a small flat top. Eyes sit low on the front face, angled back with the slope.

## Spike (Uncommon)
![[Spike Reference Sheet.webp]]
- Bloky body. One faceted green cactus column centred on top, about half the body's height, one short arm on its right (seen from the front), pink flower with a yellow centre on the tip.

## Howdy (Rare)
![[Howdy Reference Sheet.webp]]
- Bloky body. Dark brown hat, wide brim curled up at the sides, pinched crown, red band; brim a little wider than the body. The sheet draws it level, not tilted; either is fine.

## Flowy (Epic)
![[Flowy Reference Sheet.webp]]
- Bloky body. A clump of faceted leaves near the back of the top with two stems: a taller big magenta flower and a shorter smaller one, yellow centres. The views don't agree on which side the big flower is; pick the front view (big flower on the left, seen from the front).

## Sunny (Secret)
![[Sunny Reference Sheet.webp]]
- Bloky body. The side views still look like crystal shards, but the top-down view shows the intent: a flat gold disc on top with about twelve rays, alternating long and short. Model the rays as flat faceted triangles fanning up and out (a sun, not gems), lemon yellow Neon.

## Ankhy (Legendary)
![[Ankhy Reference Sheet.webp]]
- Bloky body. A blue and gold striped headdress covers the top, sides and back and hangs to the ground, with short flaps forward at the bottom of each side; the face stays open. No forehead band was drawn. A glowing gold ankh stands on top centre (Neon). The top-down view draws the ankh lying flat; ignore that.

## Builds (approved and exported 2026-10-14)
All six are in `assets/Roks/<Name>/` (`<Name>.blend`, `<Name>.fbx`, previews). Every body except Pointy is a copy of Bloky's mesh; every Rok has `<Name>_Eyes` and `<Name>_Pupils` copied from Bloky's. Body colour 215, 152, 35 with `2022 Small Stud`; props SmoothPlastic, Neon where noted.
- **Pointy:** new 60-tri body, a chamfered square pyramid, 1.2 x 1.2 x 1.0 Blender units (2.4 x 2.4 x 2 studs), bigger than Bloky so the unresized eyes fit. The eyes are tilted about 27 degrees to lie flat on the sloped front, the one exception to [[Reuse Rok Eyes]].
- **Spike:** `Spike_Cactus` (116 tris, 60, 200, 30), `Spike_Flower` (50, 255, 40, 170), `Spike_FlowerCentre` (20, 255, 220, 0).
- **Howdy:** `Howdy_Hat` (280 tris, 95, 45, 15; level, curled brim, creased crown), `Howdy_Band` (44, 230, 0, 0).
- **Flowy:** `Flowy_Plant` (282 tris: 11 leaves plus two stems, 70, 200, 25), `Flowy_Petals` (168, 255, 0, 190), `Flowy_Centres` (40, 255, 220, 0). Flowers tilt toward the front.
- **Ankhy:** `Ankhy_Gold` and `Ankhy_Blue` (882 tris together; 255, 190, 0 and 0, 70, 230), `Ankhy_Ankh` (168, 255, 200, 0, Neon). The headdress is a convex-hull dome with the face opening cut out by a boolean, then bisected into eight horizontal bands plus stripes fanning from the ankh over the dome; faces are sorted into the two colour meshes.
- **Sunny:** `Sunny_Ring` (68 tris, 255, 190, 0), `Sunny_Rays` (96, 255, 230, 0, Neon). Twelve flat rays alternate long and short; the front and back long rays stand nearly upright and the side rays splay out past the body, like the sheet's front view.

Gotcha: the FBX exporter skips objects whose collection is hidden in the view layer (the eye icon), and still writes a near-empty file. Pointy's first export came out at 4 KB with no meshes; unhide the collection and check by re-importing.

In Studio (2026-10-14): uploaded through Open Cloud as group Model assets (Pointy 131592999608227, Spike 127567033739157, Howdy 86246164925555, Flowy 98135525547965, Ankhy 122828638797557, Sunny 108212276393682), loaded with `InsertService:LoadAsset` into `ReplicatedStorage.Assets.Models.Roks` as `Model_Rok_<Name>`, with `AssetRegistry` entries. PrimaryPart is the body, pivot at bottom centre, front faces -Z, anchored, Hull collision. Body Plastic + `2022 Small Stud` 215, 152, 35; eyes SmoothPlastic 245, pupils 20; props SmoothPlastic in the colours above, `Ankhy_Ankh` and `Sunny_Rays` Neon. No `RBX_ReimportId` (not imported through 3D Importer), so updates mean re-upload and `ApplyMesh`. In `PetConfig` and the Desert Geode since 2026-10-14 ([[Geode Shop]]). Under the game lighting the body reads quite yellow rather than amber, and Ankhy's gold stripes sit close to it.
