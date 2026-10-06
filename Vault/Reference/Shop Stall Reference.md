---
description: Reference sheet for the striped-awning market stall shop stands in the lobby centre (2026-10-03); open before modelling shop props.
type: reference
---
# Shop stall reference

![[Shop Stall Reference Sheet.png]]

Generated with Nano Banana 2 from the step 3 prompt. The labelled FRONT VIEW is the customer side.

Take from it:
- Wooden counter across the front with a top shelf that overhangs it; open behind for the shopkeeper.
- Four square posts; the back posts are taller so the awning slopes down to the front.
- Awning stripes run front to back (7 across, coloured on both outer edges), and each stripe ends in a triangular point on the front valance.
- Ignore the side views' mismatched counter depth; the 3/4 view is the truth.

## Approved model (2026-10-03)

- Wood 12.6 × 11.25 × 8.3 studs; awning 14 studs wide (7 stripes of 2 studs so studs sit whole in each stripe), 0.5 studs thick, 12 high at the back sloping to 10 at the front; about 330 tris.
- User asked for the thicker awning after the first pass (it was 0.16 studs).
- Built front facing Blender +Y. Through `rock_builder.export_fbx` that imported facing Roblox **+Z**, not -Z as expected (checked by raycast: the awning is lower on +Z). For a front at Roblox -Z, model the front facing Blender -Y.
- In Studio (2026-10-03) it replaced the Arm Shop visuals: `ShopStall` sits inside `Workspace.ShopKiosk` (tag, prompt part, NPC, ring, light kept); the old covers, pillars and holders are in `ServerStorage.OldArmShopVisuals`. Stripes orange `255,110,0` (Strength colour), wood the old kiosk brown `98,46,0`, all SmoothPlastic with the inlet stud SurfaceAppearance. As of 2026-10-04 the user has changed this: wood `190,90,30` Plastic with `2022 Inlet`, stripes Glacier with `2022 Weld` (white stripes `215,215,215`). The Model still has its `RBX_ReimportId`, so it updates with [[Studio Reimport]].
- Files and builder script (`build_shop_stall.py`, uses `rock_builder`) in `assets/Lobby/ShopStall/`.

Build: three meshes so the stripes can be recoloured per shop in Studio (wood, white stripes, coloured stripes), all with stud UVs ([[Studs On Models By Default]]). Since 2026-10-04 all three carry greyscale [[Baked Face Shading]].
