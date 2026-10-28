---
description: MIT meshlab kit (zriptic/roclicks-skills) in tools/meshlab for code-built stud props; how to run, export and upload them on this machine, and the gotchas found (first used 2026-10-27 for the intro trees)
type: reference
---
# Meshlab

meshlab builds stud-style props as Luau code that writes an EditableMesh. Under Lune it writes an `.obj` file, and headless Blender renders it with Studio-like lighting. Source: `https://github.com/zriptic/roclicks-skills/tree/main/meshlab` (MIT). Copied to `tools/meshlab/` on 2026-10-27 (`out/` is git-ignored). The game's own models go in `tools/meshlab/models/`.

## Running it here
- Lune is installed globally through Aftman (0.11.1; the kit was written against 0.10.5 and the models still build). It isn't in `aftman.toml`.
- Run from `tools/`: `lune run meshlab/run ForestTree 3` writes `tools/meshlab/out/ForestTree_s3.obj`.
- Blender isn't on PATH: use `"/c/Program Files/Blender Foundation/Blender 5.2/blender.exe"`. `render.py` works on 5.2.
- Pass Blender scripts **absolute** paths. With relative paths `render.py` prints "rendered" but no PNG ends up anywhere findable.

## Into Studio (the route used)
1. `blender -b -P tools/meshlab/tools/export_fbx.py -- <out.fbx> <a.obj> [b.obj ...]` packs several OBJs into one FBX, one object per OBJ, with vertex colours kept.
2. `.claude/skills/rock-model/scripts/upload_model.ps1 -Path <fbx> -Name "<Name With Spaces>"` uploads it to the group ([[Open Cloud Key]]).
3. `InsertService:LoadAsset(id)` gives one MeshPart per seed at **1 OBJ unit = 1 stud**. No 2x scale here, unlike `rock_builder` exports.
4. MeshPart `Color` white (it multiplies the vertex colours), Plastic plus the stud variant. Studs line up with `Shapes.PITCH = 1.0`.

The kit's own Studio loaders (`StudioBuild`, `MeshDataLoader`) build EditableMeshes at runtime and add no studs. They aren't used here.

## Forest tree
`tools/meshlab/models/ForestTree.luau` is TreeBlob restyled for the intro set: bark (120, 70, 30), greens around (35-55, 150-175, 30-35) with a brighter patch, 8-10 wide, 6 courses of 1.3, a 5.5-7 trunk and about 1.4-1.6k triangles. Seeds 1-4 are asset `93515148251335` (FBX in `assets/Decor/ForestTree/`), with the loaded copy in `ServerStorage.ForestTree_Meshes`. Placed in the intro set 2026-10-27, see [[Intro Cutscene]].

Its AO bake darkens vertex colours by up to 25%. Leave it off for buildings ([[Flat Shading On Buildings]]).

Related: [[Keep Decor Simple]], [[Studs On Models By Default]], [[Tintable Mesh Textures]]
