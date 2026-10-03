---
description: On a MeshPart, a transparent TextureID renders black; use SurfaceAppearance with AlphaMode Overlay so Color shows through.
type: reference
---
# Tintable mesh textures

Seen 2026-10-02 putting inlet studs on BoulderRock:

- A transparent PNG set as a MeshPart's `TextureID` does **not** let the part's `Color` show through. The transparent areas render black.
- What works: leave `TextureID` empty and add a `SurfaceAppearance` with `AlphaMode = Overlay` and `ColorMap` = the PNG. The part's `Color` fills the transparent areas, so code can still recolour the rock.
- A `SurfaceAppearance` can be created and its `ColorMap` set from the Studio MCP's `execute_luau` in Edit. Set `ColorMap` before parenting it. Changing `ColorMap` on one that is already parented doesn't redraw (the studs vanished); destroy it and create a new one instead.
- Rechecked with the correct image id: TextureID still renders the transparent areas black.
- Inlet stud image id: `rbxassetid://138660298161877` (from `assets/Textures/Studs/SingleInletStud.png`).

Related: [[Rocks Look Like Boulders]]. The procedure lives in the `rock-model` skill.
