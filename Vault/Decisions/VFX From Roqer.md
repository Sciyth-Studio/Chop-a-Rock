---
description: VFX pipeline from Roqer (S4US). Since 2026-10-15 the vfx skill is the MIT roblox-vfx skill, adapted to this project, with its Emit/Build/Capture/Shapes runtime vendored at ReplicatedStorage.VFX.
type: decision
---
# VFX from Roqer

**2026-10-07.** The user wanted Roqer's VFX ability (https://github.com/S4US/Roqer), not the rest of the app. Roqer's desktop app and MCP server were not adopted: its script edits go into Studio's copy, which fights Rojo, and its VFX checking tools (`capture_moments`, `reference_clip`) only exist inside the app. First version: Roqer's emit module vendored at `vendor/VFXEmit` (AGPL, used with S4US's DM permission), derived Blender helpers `vfx_draw.py` / `vfx_shapes.py`, and condensed references.

**2026-10-08:** S4US also okayed sharing it however the user likes. A generic, tool-neutral copy of that first skill lives at `shared/roblox-vfx/` for other devs. It is a separate copy, not updated by later changes, so it is now older than `.claude/skills/vfx`.

**2026-10-15: replaced.** The user downloaded the `roblox-vfx` skill (adapted from Roqer's `roblox-animation-vfx` skill, MIT, TabooHarmony) and asked to replace the vfx skill with it. What changed:
- **Runtime:** `vendor/RobloxVFX/src` (`Emit`, `Build`, `Capture`, `Shapes`, unmodified) mapped to `ReplicatedStorage.VFX`. `Emit` is the old VFXEmit with only its header changed; `vendor/VFXEmit` is gone and every `require(ReplicatedStorage.VFXEmit)` now reads `ReplicatedStorage.VFX.Emit` (the showcase plugin too). Playtested clean the same day.
- **Skill:** the upstream references (`vfx-design`, `vfx-craft`, `vfx-textures`, `vfx-motion`, `vfx-mesh-shapes`, `vfx-camera-world`, `vfx-reference`, `vfx-rendered-flipbooks`) rewired to the `Roblox_Studio` MCP, the `Assets.VFX.<Feature>.VFX_<Name>` + AssetRegistry layout, our capture gotchas and Open Cloud group uploads (new `scripts/upload_images.ps1`). The user's taught rules from the old `design.md` moved into `LESSONS.md`; `studied.md`, the showcase plugin and its docs were kept. Old `vfx_draw.py` / `vfx_shapes.py` were dropped for `vfxtex.py` / `vfxblender.py` / `clip_frames.py`.
- **Python:** `C:/Users/Admin/AppData/Local/Python/bin/python3.exe` has numpy and Pillow; bare `python`/`python3` in the shell hit the Microsoft Store stub.
- `Build`, `Capture` and `Shapes` (an Arc baked to a MeshPart) checked in Edit the same day.

Related: [[Asset Ownership]], [[Open Cloud Key]], [[VFX Showcase]], [[VFX Reference Folder]]
