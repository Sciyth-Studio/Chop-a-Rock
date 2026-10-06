---
description: Building-style models (shop stall, base, wood training stand, other structures) get baked face shading with the edge glow, kept greyscale so they stay recolourable.
type: preference
---
# Baked shading on buildings

Said 2026-10-04 after approving the shop stall: the same shading is going onto the other building models, naming the base and the wood training stand.

- Building and structure models get [[Baked Face Shading]] with the edge glow: `rock_builder.face_shade_colors(me, edge_width=0.12, edge_shade=0.62)`, then `planar_stud_uvs`. Put the call in the model's build script so a rebuild keeps it.
- It must stay greyscale so the part `Color` can recolour the model. The user asked for this on the stall.
- Show a preview tinted with the Studio colours before exporting. The user approves the look first.
- Update existing models with [[Studio Reimport]], not a fresh import, when the Studio Model still has its `RBX_ReimportId` and its original part names.
- Rocks are not included unless the user asks. They use their own vertex colours (moss) and the boulder look.

Related: [[Studs On Models By Default]], [[Shop Stall Reference]]
