---
name: rock-model
description: Use when making a new rock model or rock variant for Chop a Rock in Blender (a chop rock, tier rock, decor rock, boulder or "another rock like BlockRock"), when reshaping or resizing an existing rock mesh, or when making the pre-split pieces a rock breaks into on a perfect chop. Covers taking design input from the user, building the blocky mesh with the bundled rock_builder.py through the Blender MCP, quality checks, the automatic straight split, FBX export, and wiring the imported rock and split model into Studio (ChopRock tag, RockKey, SplitModel, AssetRegistry). Use it even when the user only says "make a mossy rock" or "split this rock".
---

# Rock models

Rocks in this game are blocky boulders: several tapered, clipped-corner prisms merged into one watertight mesh, flat on the bottom, plain colored in Roblox. Every chop rock also gets a pre-split pair of pieces that the perfect-break code clones, scales and flings (`Effects.luau`, `SplitModel` attribute). `scripts/rock_builder.py` does the geometry; this file is the workflow around it.

The tier list and zone themes change often. Never assume a tier's look from memory or from an earlier rock: ask the user for the design inspiration of the rock you are making, and use the Master Game Plan (`Chop_a_Rock_Master_Game_Plan.txt`, §03) only as background. The art direction there ("smooth cartoon, minimal textures", bright mood) still applies.

## 1. Get the design input

Before building, ask the user (one AskUserQuestion round, offer a recommended option each time) for whatever is not already clear:

- **Inspiration**: reference image, an existing rock to riff on, or a few words (e.g. "tall and spiky", "flat slab pile").
- **Size in studs**: footprint width and height. BlockRock is about 12 wide x 5.4 tall x 9.3 deep. Players are about 5 studs tall and the plan wants rocks to dwarf them.
- **Color** (RGB) and **material** in Roblox. Default is plain SmoothPlastic with no texture; the color lives on the MeshPart so code can recolor it.
- **Extras** that belong to this variant (moss caps, crystals, glowing veins). Extras are separate meshes on top of the base rock, not part of it; confirm scope before making them.
- Whether it is a **chop rock** (needs a split) or **decor** (no split).

Player-facing looks are proposed and approved before they are final (AGENTS.md project rules).

## 2. Load the builder in Blender

Run this first in `execute_blender_code` (re-run after editing the script):

```python
import sys, types
path = r"C:\Users\Admin\Documents\RobloxDev\.claude\skills\rock-model\scripts\rock_builder.py"
mod = types.ModuleType("rock_builder"); mod.__file__ = path
exec(compile(open(path, encoding="utf-8").read(), path, "exec"), mod.__dict__)
sys.modules["rock_builder"] = mod
```

Later calls use `rb = sys.modules["rock_builder"]`. Inspect the scene first (`get_objects_summary`); the builder only touches objects it names and its own `RockBuilder` collection.

## 3. Design the blocks

A rock is a list of block dicts in Blender units (1 unit = 2 studs after export):

| Key | Meaning |
| --- | --- |
| `x`, `y` | Center of the block's footprint. +Y is the back, -Y the front. |
| `z0` | Bottom height (0 = ground; raised blocks sit into the mass below). |
| `w`, `d`, `h` | Footprint width, depth, height. |
| `taper` | Top size as a fraction of the bottom (0.84 to 0.93 reads well; vary it per block). |
| `clips` | Corner cut lengths for the 4 corners (front-left, front-right, back-right, back-left); 0 keeps the corner square. |
| `rot` | Rotation about vertical, degrees (keep within about +/-20). |

What makes it read as a boulder rather than crates (lessons from BlockRock, see `references/recipes.md` for its full spec):

- One broad main mass, a lower and wider top tier that sinks into it, and 5 to 7 satellite blocks at varied heights around it, overlapping the main mass so the front is never one flat slab.
- Clip one to four corners on most blocks; plain rectangles look like boxes.
- Vary size, height, taper and rotation between blocks; similar evenly spaced blocks look stacked.
- Avoid block edges that nearly coincide (within ~0.1): they create slivers and open edges. Nudge positions instead.
- Keep the front-to-back centre line (x = 0) clear of block side faces running nearly parallel to it, by at least 0.25 units: that is where the split goes (step 5). Blocks straddling the centre or sitting fully to one side are fine.
- The front of the rock is -Y: that side faces the player during the chop.
- `height_scale` stretches every block's `z0` and `h`; use it for "a bit taller/shorter" requests instead of editing each block.

### Boulder style (current look for chop rocks)

Since 2026-10-02 chop rocks are faceted boulders (Vault: `Reference/Boulder Reference`, `Decisions/Rocks Look Like Boulders`) rather than stacked blocks. `build_boulder` carves a box with flat planes around an ellipsoid, so every facet is one truly flat face and the stud grid runs unbroken across it:

```python
rock, report = rb.build_boulder("BoulderRock", width=6.0, depth=5.0, height=3.5, facets=30,
    cut_depth=(0.02, 0.2), min_nz=-0.5, center_height=0.3, lean=(0.12, 0.08), seed=4)
```

`width`, `depth`, `height` are the target size in Blender units (studs / 2); `facets` sets how many flat faces; `min_nz` below 0 lets lower facets tuck in at the base; `center_height` lower means a rounder bottom bulge; `seed` picks the variant. Render four seeds side by side, pick with the user, then apply the stud overlay material and split it with `find_mesh_split` (step 5) instead of `find_straight_split`:

```python
mat = rb.stud_overlay_material("BoulderRock_Mat", (120, 120, 120), r"C:\Users\Admin\Documents\RobloxDev\assets\Textures\Studs\SingleInletStud.png")
chosen, tried = rb.find_mesh_split(rock, merges=(0.0,))
pieces, split_report = rb.split_rock(rock, chosen["steps"], 0, chosen["merge"])
for p in pieces:
    rb.planar_stud_uvs(p.data)
    p.data.materials.clear(); p.data.materials.append(mat)
```

Studs come from a see-through stud PNG applied as a `SurfaceAppearance` with `AlphaMode` Overlay (step 7), so the MeshPart's `Color` still sets the rock's colour. Keep all facets one colour.

## 4. Build and check

```python
rock, report = rb.build_rock("MossRock", blocks, height_scale=1.0, color=(120, 120, 120))
```

It unions the blocks with the exact boolean, recenters (bottom center at the origin), tries several vertex-merge distances and keeps the cleanest, adds per-block stud-grid UVs (only used if a texture is ever applied), and gives it a plain material. `rock` is None with an `error` if no candidate was clean; move the offending blocks.

Accept only when the report shows `nonmanifold` 0, `self_intersections` 0, `islands` 1, `min_z` 0 and `visible_slivers` 0, with `tris` around 150 to 400. `dims_studs` is (width, height, depth) in studs as Roblox will import it; compare it with what the user asked for.

Render and look at it before showing the user, from front and back:

```python
rb.render_preview([rock], r"<scratchpad>\front.png", (4.5, -8.5, 6.5))
rb.render_preview([rock], r"<scratchpad>\back.png", (-5, 8.5, 6.0))
```

Scale camera distances with the rock's size. Previews use the Standard view transform and neutral light so the grey reads true; Roblox's place lighting (bright, blue sky) will still shift colors, so judge final colors in Studio.

## 5. Split (chop rocks only)

Rocks split in two with one straight vertical cut **along the chop direction, through the middle**. The chop minigame snaps the player to the rock's -Z side facing +Z (`ChopConfig.PlayerSnapOffsetFromRock`, `ChopController`), so the hand comes down in the rock's front-to-back plane; a crack at any other angle looks wrong (the user called it out). In Blender that plane is x = 0 running along Y (angle 0), because Blender -Y becomes Roblox -Z, the player's side. A stepped zig-zag cut was also tried and rejected; only use `find_split_steps` if the user asks for one.

```python
from mathutils import Vector
offset = Vector((*report["offset"], 0))
candidates = rb.find_straight_split(blocks, height_scale, offset)
pieces, split_report = rb.split_rock(rock, candidates[0]["steps"], candidates[0]["angle"])
```

`find_straight_split` defaults to angle 0 and cut positions within 0.2 units (0.4 studs) of centre with a 44-56% volume split. It ranks clean candidates (`clean` true: `clearance` of at least 0.25 from any block face running nearly parallel to the cut, which is what causes thin fins and slivers) by closeness to centre.

If no candidate is `clean`, a block edge is crowding the centre line. Run `rb.block_clearances(blocks, height_scale, offset)` to see which blocks are within 0.25 of x = 0, nudge them sideways (BlockRock's two front blocks moved about 0.35 units each), rebuild, and search again. This is why step 3 says to keep the centre line clear.

Accept a split when both pieces have `nonmanifold` 0, `self_intersections` 0, `islands` 1 and no visible slivers, and `volume_matches_rock` is true; otherwise try the next candidate. Check it from the player's camera: move the pieces to x = -0.8 and +0.8 and render from about `(0, -11, 7)` looking at `(0, 0, 1.2)` (scale with rock size); that render is also the user-facing split preview. Put the pieces back at the origin before exporting: they must keep their positions relative to each other.

## 6. Export

Each rock gets its own folder inside its zone folder, `assets/Rocks/<Zone>/<Name>/` (Forest, Desert, Jungle, Ocean, Snow). A zone's shared `.blend` sits in the zone folder as `<Zone>Rocks.blend`:

```python
import os
d = r"C:\Users\Admin\Documents\RobloxDev\assets\Rocks\MossRock"
os.makedirs(d, exist_ok=True)
rb.export_fbx([rock], d + r"\MossRock.fbx")
rb.export_fbx(pieces, d + r"\MossRock_Split.fbx")
```

Also save previews (`<Name>_preview.png`, `<Name>_Split_preview.png` with the pieces apart) and a `.blend` copy (`bpy.ops.wm.save_as_mainfile(filepath=..., copy=True)`, then delete any `.blend1`). Keep only those five files in the folder; scratch renders go in the scratchpad. `assets/` is the hand-off folder for the user and is not committed. Textures the user supplies live in `assets/Textures/` (stud images in `assets/Textures/Studs/`).

## Props (zone rocks from the desert on)

Since 2026-10-10 the desert, jungle, ocean and snow rocks carry their theme through separate prop meshes (cactus, skull, flowers, vines, kelp, snow caps), each in its own colour. Their reference sheets are in the vault (`Reference/Zone Rocks Reference`).

- **Bodies:** `build_layers` for stepped or mesa shapes (stacked sloped slabs), and `build_boulder` for round ones. Run `fix_slivers` when the report shows slivers.
- **Props:** `grass_tuft`, `skull`, `flowers`, `blossom` and `saguaro`, plus `hull_into` / `ring` / `make_obj` for new prop shapes. Each prop is one mesh in one colour, made of convex hulls; it doesn't need to be watertight.
- **Placement:** keep each prop wholly on one side of x = 0, so it rides with one split half. Find the surface by ray-casting.
- **Export:** export the rock and its props together into `<Name>.fbx`, and the two pieces and the same props into `<Name>_Split.fbx`.
- **Studio template:** props are MeshParts parented under the rock MeshPart. Leave them Anchored and don't add welds: `RockTemplate.Build` unanchors them, welds them to the rock with a `Weld` that has an explicit C0, and makes them non-colliding and massless. Don't use `WeldConstraint` here. Made outside Workspace, it locks in the offset the parts have when they enter Workspace, which is after the rock has moved, so the props were left about 170 studs away (2026-10-10). That way they follow the rock as it rises, shakes and sinks, and `Effects` hides them on break.
- **Studio split model:** each prop is parented under the piece on its side. `SplitModel.Spawn` sizes and positions from the direct child pieces only, recolours only the pieces, and welds each prop to its piece. Props keep their own colours.
- Also put the props under the `Model_RockPreview_*` copy used by the Index.

## 7. Import and wire up in Studio

**Claude imports the models itself (since 2026-10-10).** Upload each FBX with `scripts/upload_model.ps1 -Path <fbx> -Name <name>`. It uses Open Cloud with the `ROBLOX_API_KEY` user env var, puts the asset under the Sciyth Studio group and prints the asset id. Then, in Edit, load it with `InsertService:LoadAsset(id)` through `execute_luau` and wire it up as below. For rocks that replace an existing `Model_Rock_<Key>` template, fill in `ROCKS` and `PROP_COLORS` in `scripts/wire_rocks.luau` and paste it into `execute_luau`. It swaps the template and the Index preview and builds `Model_RockSplit_<Name>` with the props sorted onto their halves. Then add the registry entries. The manual 3D Importer steps that follow are the fallback. Imported MeshParts arrive unanchored, grey and with Default collision fidelity.

The user imports; you cannot run the 3D Importer. Tell them:

1. Import 3D, pick `assets/Rocks/<Zone>/<Name>/<Name>.fbx`, keep File Dimensions at the default and do not rescale (`export_fbx` scales the vertices 2x on export, so 1 Blender unit imports as 2 studs; the FBX unit-scale option is ignored by Roblox's importer, and before 2026-10-02 rocks exported at 1:1 so the user had to scale every import 2x), Anchored on, then Import.
2. Import 3D again with `<Name>_Split.fbx`. It arrives as one Model holding both pieces.
3. Tell you when both are in Workspace.

Then, with Play stopped, do the wiring through the Studio MCP (`execute_luau`, Edit):

- **Split model**: rename it `Model_RockSplit_<Shape>` (one per mesh shape, not per tier: pieces take the rock's color and material at break time), move it to `ReplicatedStorage.Assets.Models.Rocks.<Zone>`, and set each piece to `CollisionFidelity` Hull. Add `Model_RockSplit_<Shape> = { Category = "Models", InstanceName = "Model_RockSplit_<Shape>" }` to `src/shared/AssetRegistry.luau` and run `./scripts/check.ps1`.
- **Studs**: on the rock and on every split piece, leave `TextureID` empty, set `Material` Plastic and `MaterialVariant` `2022 Inlet` (a stud MaterialVariant in MaterialService; `2022 Stud` is the outlet stud), and set `Color` to the rock colour. The variant follows the mesh's stud-grid UVs. Don't add a `SurfaceAppearance`, because it would override the variant. The break code copies `Material` and `MaterialVariant` onto the pieces and debris.
- **Rock**: take the MeshPart out of its import Model, name it `Rock_<RockKey>`, parent it to `Workspace.Rocks`, tag `ChopRock`, set attributes `RockKey` (a key in `RockConfig`) and `SplitModel` (the registry key), set `Color`, `Material` Plastic with `MaterialVariant` `2022 Inlet`, `TextureID` empty, `CollisionFidelity` Hull, `Anchored` true, `Archivable` true, and place it so its bottom sits on the ground where the old rock was (Position.Y = ground + Size.Y / 2). When replacing an existing rock, copy its position and attributes first, then delete the old part and the empty import Models.
- `CollisionFidelity` cannot be changed from `execute_luau` (the write is silently ignored), so ask the user to set it to Hull in Properties on the rock and on each split piece. The 3D Importer brings meshes in as default-grey Plastic with fidelity Default; everything else above is set by script.
- Verify by values (tag, attributes, size, position, registry lookup), then playtest a perfect break following the `studio-playtest` skill and report what was seen versus checked by value.
- Remind the user to save the place: Studio edits are not in git.

## Gotchas

- A MeshPart's `TextureID` overrides `Color` entirely, and its transparent pixels render black, not the part colour (seen on BoulderRock, 2026-10-02). For studs, use the MaterialVariants (see Studs above); never bake the colour into an image.
- The exported FBX carries no texture path (`path_mode="STRIP"`), so imports come in untextured.
- Exact booleans need watertight inputs; the builder's blocks always are. If you add custom geometry, run `rb.stats(obj.data)` on it before combining.
- Axes (measured on BlockRock's import): Blender X becomes Roblox -X, Blender Y becomes Roblox +Z, Blender Z becomes Roblox Y (up). So Blender's -Y side faces the player. The base plot import (2026-10-03) came in the other way round, with Blender -Y on Roblox +Z, so after importing, check orientation from a known part instead of assuming.
- Keep chop rocks unrotated about the vertical axis in Studio. The player snap offset is in world space, so a rotated rock would be chopped at an angle to its pre-cut split.
