---
description: Building-style models (shop stall, base, pedestal/geode stand, training stand and boards) are flat-coloured, no baked shading; the user went off the baked look 2026-10-10.
type: preference
---
# Flat shading on buildings

Said 2026-10-10: "flat looks better for the style." This replaces the 2026-10-04 preference for baked face shading with an edge glow.

- Building and structure models get no vertex colours: just `rb.planar_stud_uvs(me)`, the stud MaterialVariant and the part `Color`. Don't call `rb.face_shade_colors` in their build scripts.
- 2026-10-10: the shop stall, geode stand (+ crystals, also the base pedestal mesh), training stand, board, board split and BoardStack were flattened. The `FaceShade` attribute was removed, the edge-glow inset faces were dissolved back (about 3-5x fewer triangles), the stud UVs were redone, and the `.blend` and FBX files in `assets/` were overwritten. The builders no longer call the shading.
- The old base plot is not flattened because it is being replaced (see [[Bases]]).
- Rocks are not affected. Moss and other rock vertex colours stay.
- Applied in Studio 2026-10-10: the flat FBXs were uploaded through Open Cloud and `ApplyMesh` was run on all 31 copies (4 stalls, `Model_GeodeStand`, 9 pedestals, the stand frame, board, split pieces and 4 BoardStacks), keeping their size and CFrame.

Related: [[Baked Face Shading]] (the technique, kept for reference), [[Studs On Models By Default]], [[Studio Reimport]]
