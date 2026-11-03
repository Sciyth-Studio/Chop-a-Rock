---
description: 2026-10-31 - when a zone decor model exists for a rock's prop (acacia, bamboo, cattails, termite mound...), the rock uses the actual meshlab decor mesh, not a hand-built lookalike.
type: decision
---
# Rock props reuse decor (2026-10-31)

The user saw that the meshlab decor models could serve as rock props ("this is a game changer"). They said yes to swapping them in for the zone 6-10 rocks.

- **Why:** a hand-built termite mound "looked nothing like the ones in game". The real decor mesh matches the zone exactly and costs nothing to make.
- **How:** import `tools/meshlab/out/Decor<Name>_s1.obj` into Blender with `forward_axis="Z"`, `up_axis="Y"` (like `export_fbx.py`), scale it by 0.5 × a fit factor (meshlab is 1 unit = 1 stud, Blender rocks are 1 unit = 2 studs), and seat it by ray-casting the rock top. Export it in the rock's FBX. In Studio, set the prop to white Plastic + `2022 Stud` so the vertex colours show.
- **For a different shape on the rock**, change the decor's seed or size in its `.luau` file and re-run it, rather than hand-modelling.
- **Live slicing:** `MeshSlicer` copies vertex colours through the cut (2026-10-31), so the sliced halves keep their colours.
- Props with no decor model (mud, roots, pagoda, fist, carved cracks and runes) are still built in Blender.

Related: [[World 1 Rocks]], [[Meshlab]], [[Decor Lineups]], [[Slice Test]]
