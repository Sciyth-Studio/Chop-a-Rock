---
description: Facts measured in the 2026-10-23 icon spike: stud tile size, Roblox to Blender axes, ViewportFrame lighting maths, renderer gotchas
type: reference
---
# Item icon rendering

Learned while rendering the first two icons (Bloky, Basic rock) in Blender for `IconSystemPlan.md`. The draft renderer is `.claude/skills/item-icons/scripts/icon_renderer.py`. It runs headless with `blender.exe -b --factory-startup --python icon_renderer.py -- Pet/Bloky Rock/Basic`, so the Blender GUI and MCP add-on aren't needed. One icon takes about 30 s on Cycles.

## Stud tiling
- On MeshParts, one MaterialVariant tile covers **`StudsPerTile` studs in world space**, whatever the UV scale. Measured with a head-on ViewportFrame capture: `2022 Small Stud` (0.5) repeats every 0.495 studs on Bloky, and `2022 Inlet` (1) every 0.99 studs on the rock, even though the two meshes have very different UV-per-stud ratios. To match in Blender, scale the UVs by (world studs per UV unit) / StudsPerTile (`world_per_uv`).
- **Rok bodies use `2022 Small Stud`** (outlet, 0.5), not Inlet. Rocks use `2022 Inlet` (1).
- The stud look is mostly in the variant's ColorMap. An ambient-only capture shows it: Small Stud is a rounded square with a dark "L" on its lower left, and Inlet is a recessed square with a dark inner edge on its top and right.
- The 2022 texture ids (`10509827175` and so on) can't be downloaded: Open Cloud asset-delivery needs a scope the key lacks, `assetdelivery` needs a cookie, and `CreateEditableImageAsync` has no permission. The renderer uses tiles taken from captures and redrawn (`textures/Inlet.png`).

## Axes
- An FBX exported with `rock_builder.export_fbx` and imported back into Blender: **Roblox (x, y, z) = Blender (-x, z, y)**, a 180° turn about up. Checked with Bloky's eyes (Blender -Y = Roblox front -Z) and the pupil highlights (Blender +X = Roblox -X).
- Roblox `Orientation` is applied as Ry · Rx · Rz. A part's mesh is centred on its bounds and scaled per axis by `Size / extent`.
- Rocks export at 2 studs per Blender unit, and Roks at 1. `Size / MeshSize` covers the rest. The Basic rock is the Boulder mesh at 0.6x, turned 180° ([[Forest Rock Tiers]]).

## ViewportFrame lighting (card previews)
- Cards use `Ambient` 170, `LightColor` white and `LightDirection` (-1, -1, -1), so the light comes from the back upper +X and front faces get ambient only.
- Studio multiplies in **sRGB space**: a face lit only by ambient shows exactly colour × 170/255 (120 → 80, eye white 245 → 165, pupil 20 → 14). Lit faces add about 0.58 × N·L.

## Renderer gotchas
- Set the render resolution **before** fitting the camera. `world_to_camera_view` uses the scene's frame, and the factory 1920×1080 frame squashed the fit.
- Make the camera sensor square (36×36). The default 36×24 mixes axes when you set `angle`.
- A uniform white world makes black plastic look grey through specular. Keep `Specular IOR Level` around 0.25.
- Stud placement fits each stud by its own size, not its tile, and tries five phase offsets per face to fit the most. Without that, Bloky's front (1.36 × 1.24 studs between big chamfers) gets no studs around the eyes. Studs that would sit under another part (found with a BVH ray along the normal) are skipped.

Related: [[Rok Icon Reference]], [[Tintable Mesh Textures]], [[ViewportFrame Gotchas]]
