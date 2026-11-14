---
description: Attack warnings and danger areas are drawn with textures (decals, SurfaceGuis, textured beams), never coloured or neon Parts; ask the user before drawing a missing texture.
type: preference
---
# Textured attack telegraphs

The user (2026-11-12) doesn't want the area highlight for any move made from Parts. Boss moves and any later attacks show their warnings and danger areas with textures wherever possible.

How to apply:
- Use Decals or SurfaceGuis on the floor, ImageLabels, or Beams with a texture. Look in the VFX texture kit first (see the vfx skill).
- Parts are only for invisible hitboxes and anchors.
- If no texture fits (a sweep arc, a crack ring, a spike marker), ask the user before drawing one. They may draw it themselves.

Boss attacks follow this from 2026-11-12: `BossAttackController/Canvas.luau` draws every shape on one SurfaceGui over an invisible anchor. Each shape has a texture slot in `BossFxConfig.Textures`, and a plain GUI Frame stands in while a slot is empty. The textures were drawn and uploaded the same day; ids are listed in [[World Bosses]].

Related: [[World Bosses]], [[Boss Arena]]
