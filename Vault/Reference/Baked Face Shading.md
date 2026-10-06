---
description: Greyscale shading by face direction baked into vertex colours in Blender (2026-10-04), so models look shaded and still recolour from the part Color.
type: reference
---
# Baked face shading

The user wants models such as buildings to have baked shading like the toolbox trees: tops brightest, sides a bit darker, undersides darkest.

![[Baked Shading Reference.png]]

Take from it: each face is shaded by which way it points. It is not real-time shadow and not texture detail.

- `rock_builder.face_shade_colors(me)` writes a greyscale face-corner colour attribute `FaceShade`. Default values: up 1.0, down 0.55, +X 0.88, -X 0.78, +Y 0.92, -Y 0.72. Sloped faces blend between them. Pass `shades=` to change the contrast.
- It is greyscale, so the MeshPart `Color` multiplies it and the model stays recolourable. The stud MaterialVariant still works on top.
- The FBX exporter writes the colours (`colors_type` defaults to SRGB in Blender 5.2). No change to `export_fbx` was needed.
- Blender MCP gotcha: `bpy.ops.wm.open_mainfile` and an FBX export in the same `execute_blender_code` call fails (`Context has no selected_objects`). Run the export in a second call.
- **Edge glow** (approved 2026-10-04): `face_shade_colors(me, edge_width=0.12, edge_shade=0.62)` merges coplanar triangles back into whole faces, groups connected flat faces into regions, insets each region by a fixed width (`inset_region`, clamped on thin regions), and darkens every vertex on a real (non-flat) edge so the shading fades toward the middle. It adds about 4–5x the triangles. Run `planar_stud_uvs` after it, because it changes the geometry.
- Why regions and not single faces: on boolean-unioned meshes (the training stand) a flat face with a part joined into it, like a foot top with a post in it, stays split into several faces. Insetting each face separately put dark smudges along those internal seams. With regions, only real edges and the joint creases go dark, which reads as crevice shadow.
- Decide which vertices are dark after the inset, by checking for non-flat edges. `inset_region` doesn't keep the original vertices on the outside, and tracking them beforehand gave inverted shading (bright rim, dark band).
- Zero-length edges (doubled corner points) make `inset_region` throw spiky triangles. The base plot's Voronoi crack stones had them. `edge_glow_inset` now runs `dissolve_degenerate` first. Don't use `remove_doubles` there, because it would weld separate boxes that touch at corners.
- Watch for coplanar faces that overlap inside one mesh: the shading makes them flicker visibly. The stall's awning slab and its front points shared a plane until the slab was shortened.
- First used on the shop stall ([[Shop Stall Reference]]). AO was skipped: these meshes only have vertices at the corners, so per-vertex AO smears across whole faces.

Related: [[Forest Rock Tiers]] (moss uses the same vertex-colour approach), [[Tintable Mesh Textures]]
