---
description: Reference sheet for Treebo, the Secret forest Rok; Bloky's body and eyes with a faceted three-blob tree growing from the back right of the top, and glowing fireflies.
type: reference
---
# Treebo reference

Treebo is the Secret forest Rok in the [[Master Game Plan]] §03 lineup (sheet received 2026-10-04).

![[Treebo Reference Sheet.webp]]

Take from it:
- Body and eyes: the same as [[Bloky Reference]]. Reuse Bloky's meshes ([[Reuse Rok Eyes]]).
- Tree: a short, twisted brown trunk growing out of the top face toward the back right (seen from the front), sunk into the back-top edge, with two short branches.
- Canopy: three faceted green blobs, one big one on top and two smaller ones low on the left and right. It overhangs the back and right of the body and rises about the body's height again.
- Fireflies: about ten small glowing yellow cubes floating around the canopy. They are the Secret Neon accent. They're a mesh, not particles, so they show in ViewportFrames ([[ViewportFrame Gotchas]]).
- Eyebrows: Treebo is the only Rok with eyebrows (the user asked, 2026-10-04); they aren't on the sheet. An exception to [[Roks Stay Rocks]], so don't add them to other Roks unless asked.
- Front is the eyes view (top-left of the sheet).

Build (Blender, approved 2026-10-04): `Treebo`, `Treebo_Eyes` and `Treebo_Pupils` are copied from Berry (Bloky's meshes). `Treebo_Trunk` is six tapered prisms overlapping as closed shells (96 tris); the user asked for a wider trunk, so the main trunk is about 0.28 units across at the base (0.14 radius). `Treebo_Leaves` is three jittered subdivision-2 icospheres (240 tris). `Treebo_Fireflies` is ten 0.06-unit cubes (120 tris). `Treebo_Brows` (88 tris) is two bevelled bars above the eyes, tilted 10 degrees with the inner ends higher, black like the pupils. Preview colours: trunk (125, 75, 35), leaves (110, 205, 25), fireflies (255, 235, 60). Files: `assets/Roks/Treebo/` (`Treebo.fbx`, `Treebo.blend`, `Treebo_preview.png`).

In Studio (2026-10-04): `ReplicatedStorage.Assets.Models.Model_Rok_Treebo` (AssetRegistry key `Model_Rok_Treebo`), PrimaryPart `Treebo`, pivot at bottom centre, front faces -Z, anchored, Hull collision, still has `RBX_ReimportId` ([[Studio Reimport]]). Body is Plastic grey 120 with the `2022 Small Stud` MaterialVariant (Plastic copy, small outlet studs; was `2022 Inlet` until 2026-10-14); other parts SmoothPlastic (Neon for glowing accents).

Related: [[Roks Stay Rocks]], [[Berry Reference]], [[Sprout Reference]]
