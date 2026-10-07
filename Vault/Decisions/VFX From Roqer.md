---
description: 2026-10-07 — VFX pipeline adopted from Roqer (S4US) with the author's permission: vendored emit module, derived Blender helpers, the vfx skill.
type: decision
---
# VFX from Roqer

**2026-10-07.** The user wanted Roqer's VFX ability (https://github.com/S4US/Roqer), not the rest of the app. Roqer's desktop app and MCP server were not adopted: its script edits go into Studio's copy, which fights Rojo, and its VFX checking tools (`capture_moments`, `reference_clip`) only exist inside the app.

What was taken, all from commit `bf7118b`:

- **`vendor/VFXEmit/Emit.luau`**: Roqer's emit module, unmodified, mapped to `ReplicatedStorage.VFXEmit`. It plays effects from the `EmitCount` / `EmitDelay` / `EmitDuration` attribute convention our existing effects already use, with slow motion and hitstop.
- **`.claude/skills/vfx/scripts/`**: `vfx_draw.py` (texture and flipbook drawing) and `vfx_shapes.py` (mesh shapes), derived from Roqer's Blender helpers. Dev tools only; nothing ships.
- **`.claude/skills/vfx/references/`**: design rules and recipes condensed from Roqer's VFX docs.

**Permission:** Roqer is AGPL-3.0-or-later. S4US gave the user permission by DM to use the emit module in the game and to use the Blender helpers. Keep the attribution headers and `vendor/VFXEmit/README.md`.

Related: [[Asset Ownership]] (upload textures to the Sciyth Studio group)
