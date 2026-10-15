---
description: Reference sheet for Berry, the Legendary forest Rok; Bloky's body and eyes with a faceted leaf crown and four glowing magenta berries.
type: reference
---
# Berry reference

Berry is the Legendary forest Rok in the [[Master Game Plan]] §03 lineup (sheet received 2026-10-04).

![[Berry Reference Sheet.webp]]

Take from it:
- Body and eyes: the same as [[Bloky Reference]]. Reuse Bloky's meshes ([[Reuse Rok Eyes]]).
- Crown: a dense wreath of chunky, faceted, pointed leaves around the rim of the top face, leaning outward and overhanging the edge a little. One taller leaf at the front centre and one at the back centre. The middle of the top face stays visible from above.
- Berries: four glowing magenta faceted balls set into the wreath, two each side of the front leaf as seen from the front. They are the Legendary Neon accent.
- Leaves and berries are separate meshes so each keeps its colour; no studs on them.
- Front is the eyes view (top-left of the sheet).

Build (Blender, approved 2026-10-04): `Berry`, `Berry_Eyes` and `Berry_Pupils` are copies of Nesty's (Bloky's) meshes. `Berry_Leaves` is 22 overlapping faceted leaf shells, 16 tris each (a ring of 12 outward-leaning leaves, an inner ring of 8 and two tall centre leaves), 352 tris. `Berry_Berries` is four 8x4 low-poly spheres, 192 tris. Preview colours: leaves (110, 205, 25), berries (255, 5, 190). Files: `assets/Roks/Berry/` (`Berry.fbx`, `Berry.blend`, `Berry_preview.png`).

In Studio (2026-10-04): `ReplicatedStorage.Assets.Models.Model_Rok_Berry` (AssetRegistry key `Model_Rok_Berry`), PrimaryPart `Berry`, pivot at bottom centre, front faces -Z, anchored, Hull collision, still has `RBX_ReimportId` ([[Studio Reimport]]). Body is Plastic grey 120 with the `2022 Small Stud` MaterialVariant (Plastic copy, small outlet studs; was `2022 Inlet` until 2026-10-14); other parts SmoothPlastic (Neon for glowing accents).

Related: [[Roks Stay Rocks]], [[Sprout Reference]], [[Nesty Reference]]
