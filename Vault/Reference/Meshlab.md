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
   **Facing (fixed 2026-10-27):** the OBJ import must use `forward_axis="Z"` so the model's front (-Z) lands on Blender -Y, which the Roblox importer reads as -Z. With `NEGATIVE_Z` (render.py's axes) the intro car came into Roblox turned 180°. The OBJ importer puts the axis change on the object's rotation, not on the vertices, so measure in world space (`matrix_world`) when checking. Assets uploaded before the fix (trees `93515148251335`, car `91666183075378`) face +Z; the car was turned in Studio.
3. `InsertService:LoadAsset(id)` gives one MeshPart per seed at **1 OBJ unit = 1 stud**. No 2x scale here, unlike `rock_builder` exports.
4. MeshPart `Color` white (it multiplies the vertex colours), Plastic plus the stud variant. Studs line up with `Shapes.PITCH = 1.0`.

The kit's own Studio loaders (`StudioBuild`, `MeshDataLoader`) build EditableMeshes at runtime and add no studs. They aren't used here.

## Forest tree
`tools/meshlab/models/ForestTree.luau` is TreeBlob restyled for the intro set: bark (120, 70, 30), greens around (35-55, 150-175, 30-35) with a brighter patch, 8-10 wide, 6 courses of 1.3, a 5.5-7 trunk and about 1.4-1.6k triangles. Seeds 1-4 are asset `93515148251335` (FBX in `assets/Decor/ForestTree/`), with the loaded copy in `ServerStorage.ForestTree_Meshes`. Placed in the intro set 2026-10-27, see [[Intro Cutscene]].

## Intro car
`tools/meshlab/models/IntroCar.luau`, built from a ChatGPT six-view sheet ([[Intro Car Reference]]): the first reference + meshlab test, 2026-10-27. The sheet gave the parts list, colours and placement well. The curves (bubbly fenders, soft hood) became blocks and arches, because the kit only has boxes, lathes and lofts. About 5.9k triangles with `beginBake({ cell = 2.5 })`. The default 0.8-1.2 cell split faces finer and pushed the first pass to 7.5k. Asset `91666183075378`, FBX in `assets/Decor/IntroCar/`. To get one object named `Body`, export a copy of the OBJ named `Body.obj`.

**Studs on round parts look bad** (user, 2026-10-27, on the headlights): lathe/cylinder details get stud UVs that wrap the stud around small curved faces. `IntroCar` has a `plain(fn)` helper that points every UV of what `fn` builds at (0.03, 0.03), a flat spot of the stud tile, so lights, wheels, exhaust and the steering wheel come out plain in the render and under `2022 Stud` in Studio. Use it for any small round detail.

## Zone decor
14 props in the JungleTree style ([[Decor In ForestTree Style]], [[Decor Lineups]]): `tools/meshlab/models/Decor*.luau`, seed 1, 240-2.1k triangles each. They are Pine, SnowPine, Bush, JungleBush, Stump, Mushroom, Cactus, PricklyPear, JungleTree, LeafPlant, Kelp, Coral, Starfish, SnowPile. `DecorSnowPine` and `DecorJungleBush` are wrappers that pass `opts` to `DecorPine` / `DecorBush`. All are in one `assets/Decor/ZoneDecor/ZoneDecor.fbx`, current asset `88340003908610` ("Zone Decor v3", 2026-10-28). Earlier uploads were v1 `101703227545289` (first pass), v2 `123819425751797` (contrast recolour), and the lone JungleTree `128488033006874`.

History (all 2026-10-28):
- Palms went into the jungle first. They were wrong: palms are beach trees and no zone is a beach. They were replaced by `DecorJungleTree` (buttress roots, three layered canopy pads, vines), which the user liked a lot.
- The user then had every prop restyled to match it: crossed-box courses in alternating shades, chunky banded trunks and stems, root fins on the pine and stump.
- Greens on green floors sit close to the floor colour (user): forest pine and bush near 39,70,45, and jungle tree, leaf plant and JungleBush near 50,130,40. Cactus, kelp and snow pine aren't on green floors.
- Coral tips step in twice in the branch's own pink. The user disliked both wider light-pink caps and a lighter tip colour.

Swapping a restyle onto placed copies: record each copy's scale as old height / old template height, `ApplyMesh` the new mesh, set `Size = newTemplate.Size * scale`, reset `PivotOffset` to the bottom, `PivotTo` the old pivot, then re-check the terrace and floor edges (11 props needed nudging).

`Workspace.DecorShowcase` (EditorOnly, x -280) shows each zone's props on a plate in that zone's terrace colour. Templates are MeshParts in `ReplicatedStorage.Assets.Models.Decor` (the unused old Palm is still there), set to Color white, Plastic, `2022 Stud`, Anchored, with `PivotOffset` at the bottom centre. They're placed as `Workspace.Zones.<Zone>.Decor` and `FloorDecor` ([[Zone Line]]). `CollisionFidelity` can't be set from `execute_luau` (it stays Default).

Its AO bake darkens vertex colours by up to 25%. Leave it off for buildings ([[Flat Shading On Buildings]]).

Related: [[Keep Decor Simple]], [[Studs On Models By Default]], [[Tintable Mesh Textures]]
