---
description: Reference sheet for Bloky, the first Rok (pet rock); chamfered cube body with chamfered-square cartoon eyes.
type: reference
---
# Bloky reference

"Rok" is the user's name for pet rocks (2026-10-03). Bloky is the first one: a common starter Rok.

![[Bloky Reference Sheet.png]]

Take from it:
- Body: a chunky cube, a little wider than tall, with broad single-segment chamfers on every edge and corner. Flat bottom. Plain grey.
- Eyes: chamfered squares, not ovals (the user asked for this). Each has a white outer square, a black chamfered-square pupil and a small white square glint at the top right. They stand slightly out from the front face. No mouth, no limbs.
- The front is the face with the eyes (Blender -Y, Roblox -Z).

Build (Blender, `Rok` collection): `Bloky` body about 2 x 1.9 x 1.9 studs with stud UVs; `Bloky_Eyes` (whites + glints) and `Bloky_Pupils` are separate meshes so the colours stay on the parts and the eyes can blink later.

In Studio (2026-10-03): `ReplicatedStorage.Assets.Models.Model_Rok_Bloky` (AssetRegistry key `Model_Rok_Bloky`), PrimaryPart `Bloky`, pivot at bottom centre, front faces -Z. Body Plastic grey 120 with the `2022 Small Stud` MaterialVariant (Plastic copy, small outlet studs; was `2022 Inlet` until 2026-10-14); eyes SmoothPlastic 245 white, pupils SmoothPlastic 20 black. Parts are anchored with no welds yet; the pet-follow code will need to weld them or move the model as one. FBX: `assets/Roks/Bloky/Bloky.fbx`.

Related: [[Geode Reference]], [[Studs On Models By Default]]
