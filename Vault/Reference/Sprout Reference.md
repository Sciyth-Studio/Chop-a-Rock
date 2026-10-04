---
description: Reference sheet for Sprout, the Uncommon forest Rok; Bloky's body and eyes with a two-leaf seedling on top.
type: reference
---
# Sprout reference

Sprout is the Uncommon forest Rok in the [[Master Game Plan]] §03 lineup (sheet received 2026-10-04).

![[Sprout Reference Sheet.webp]]

Take from it:
- Body and eyes: the same as [[Bloky Reference]] (chamfered cube, chamfered-square eyes on the front). Reuse Bloky's meshes rather than remodelling.
- Sprout: a short curved green stem rising from the centre of the top face, splitting into two faceted, pointed leaves that angle up and out to the left and right (seen from the front). Leaves are low-poly almond shapes with a centre crease. From the side they lean slightly toward the back.
- Sprout is about half the body's height; each leaf is about a third of the body's width.
- The sprout is its own mesh so its green stays on the part; no studs on the sprout.
- Front is the eyes view (top-left of the sheet).

Build (Blender, approved 2026-10-04): `Sprout`, `Sprout_Eyes` and `Sprout_Pupils` are Bloky's meshes renamed (imported from Bloky's FBX). `Sprout_Leaves` is new: a six-sided curved stem sunk 0.05 units into the top face plus two lofted, faceted leaves unioned into one watertight mesh (198 tris, cleaned with a 0.006 merge), about 1.4 studs across and 1.2 studs taller than the body. Leaf green is (110, 205, 25). Files: `assets/Roks/Sprout/` (`Sprout.fbx`, `Sprout.blend`, `Sprout_preview.png`).

In Studio (2026-10-04): `ReplicatedStorage.Assets.Models.Model_Rok_Sprout` (AssetRegistry key `Model_Rok_Sprout`), PrimaryPart `Sprout`, pivot at bottom centre, front faces -Z, anchored, Hull collision, still has `RBX_ReimportId` ([[Studio Reimport]]). Body is Plastic grey 120 with the `2022 Inlet` MaterialVariant like Bloky; other parts SmoothPlastic (Neon for glowing accents).

Related: [[Roks Stay Rocks]], [[Bloky Reference]]
