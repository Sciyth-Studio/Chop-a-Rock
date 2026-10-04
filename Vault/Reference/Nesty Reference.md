---
description: Reference sheet for Nesty, the Epic forest Rok; Bloky's body and eyes with a twig nest holding three pebble eggs on top.
type: reference
---
# Nesty reference

Nesty is the Epic forest Rok in the [[Master Game Plan]] §03 lineup (sheet received 2026-10-04).

![[Nesty Reference Sheet.webp]]

Take from it:
- Body and eyes: the same as [[Bloky Reference]]. Reuse Bloky's meshes rather than remodelling.
- Nest: a woven twig ring sitting on the top face, about as wide as the body (a touch wider), about a third of the body's height, with short twig stubs poking out of the rim all round. Brown.
- Eggs: three pale blue faceted pebble eggs inside, one at the back and two in front (seen from above), sticking up well above the rim.
- Front is the eyes view (top-left of the sheet).

Tri budget (the user was worried about the nest): don't model individual twigs. The nest is three stacked, twisted four-sided rings (10 segments each) plus 8 three-sided twig stubs and a hidden floor disc; eggs are 8-sided, 3-ring low-poly eggs.

Build (Blender, approved 2026-10-04): `Nesty`, `Nesty_Eyes` and `Nesty_Pupils` are Bloky's meshes copied from Sprout. `Nesty_Nest` is 340 tris (overlapping closed shells, not unioned) and `Nesty_Eggs` is 144 tris; the user asked for bigger, flatter eggs, so each is about 0.33 units wide and 0.34 tall (pebble-like, not tall eggs). Preview colours: nest (150, 85, 35), eggs (170, 210, 245). Files: `assets/Roks/Nesty/` (`Nesty.fbx`, `Nesty.blend`, `Nesty_preview.png`).

In Studio (2026-10-04): `ReplicatedStorage.Assets.Models.Model_Rok_Nesty` (AssetRegistry key `Model_Rok_Nesty`), PrimaryPart `Nesty`, pivot at bottom centre, front faces -Z, anchored, Hull collision, still has `RBX_ReimportId` ([[Studio Reimport]]). Body is Plastic grey 120 with the `2022 Inlet` MaterialVariant like Bloky; other parts SmoothPlastic (Neon for glowing accents).

Related: [[Roks Stay Rocks]], [[Reuse Rok Eyes]], [[Sprout Reference]], [[Shroomy Reference]]
