---
description: Every model gets the inlet stud overlay unless the user says otherwise; build stud-grid UVs and keep colour on the part.
type: preference
---
# Studs on models by default

Said 2026-10-03 while planning the shop stall: "Assume stud texture unless otherwise is said."

- Every new model gets stud-grid UVs in Blender (`rock_builder.planar_stud_uvs`). In Studio it gets `Material` Plastic and `MaterialVariant` `2022 Inlet`, or `2022 Stud` for outlet studs (the base plot floor). Rock Pets use `2022 Small Stud` (small outlet; user, 2026-10-14). **Animal Pets use `Animal Stud`** (user, 2026-11-04, after trying no studs, `2022 Small Stud` and `2022 Tiny Stud`): a flat, faint outlet stud on every part except eyes and Neon, with no shading, modelled on a reference the user liked. See [[Animal Pets]]. The part `Color` still tints it. This replaced the SurfaceAppearance overlay on 2026-10-03; see [[Tintable Mesh Textures]].
- Only skip studs when the user asks for that model to be plain.
- Reference sheet prompts still say "no studs": studs are added in Roblox, not drawn into the design.

Related: [[Tintable Mesh Textures]]
