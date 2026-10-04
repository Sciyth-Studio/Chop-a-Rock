---
description: Studs come from the 2022 stud MaterialVariants in MaterialService (2026-10-03); the old SurfaceAppearance overlay and the TextureID black-render gotcha.
type: reference
---
# Tintable mesh textures

## Current: stud MaterialVariants (2026-10-03)
The user brought a toolbox stud pack into MaterialService and asked for every stud texture outside the UI to use it.

- `MaterialService` variants include `2022 Inlet` (BaseMaterial changed to Plastic), `2022 Stud` (Plastic; this is the **outlet** stud), `2022 Big Stud`, `2022 Small Stud`, `2022 Universal`, `2022 Weld`, `2022 Diamond Stud` and `2022 Glue`. The lobby's older Glacier copies of `2022 Stud` and `2022 Weld` are still there and still in use.
- To stud a part: `Material = Plastic`, `MaterialVariant = "2022 Inlet"` (or `"2022 Stud"` for outlet). Remove any `SurfaceAppearance` first, because it overrides the variant.
- On MeshParts the variant follows the mesh UVs, so the stud-grid UVs from `rock_builder.planar_stud_uvs` give the same stud size as before. Part `Color` and baked vertex colours (moss) still tint it.
- 64 parts were converted. `BasePlot_Floor` uses `2022 Stud` (outlet); everything else that had the inlet overlay uses `2022 Inlet`.
- Code that copies a part's look must copy `MaterialVariant` along with `Material`. `SplitModel` and the RockService chunk/half effects now do.
- Not converted: `ServerStorage.OldArmShopVisuals` (unused; has stud `Texture`s with the same 2022 image) and the `Baseplate`'s top Texture `79447581991048` (hidden under the lobby).

## Old approach (replaced)
- A transparent PNG as a MeshPart's `TextureID` renders its transparent areas black. A `SurfaceAppearance` with `AlphaMode = Overlay` and `ColorMap` set to the PNG let the part colour show through. Set `ColorMap` before parenting, and destroy and recreate to change it.
- The inlet stud image id was `rbxassetid://138660298161877` (`assets/Textures/Studs/SingleInletStud.png`).

Related: [[Studs On Models By Default]], [[Rocks Look Like Boulders]]
