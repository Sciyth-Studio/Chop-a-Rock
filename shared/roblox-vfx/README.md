# roblox-vfx

An agent skill for making Roblox visual effects: design rules, layer recipes, Blender scripts that draw particle textures, flipbooks and mesh shapes, and `VFXEmit`, a module that plays effects authored with the emit-attribute convention (VFX Editor, VFX Forge and similar plugins).

It is a plain `SKILL.md` folder, so any coding agent that reads skills can use it: Claude Code, Codex and others.

## Install

Copy this whole folder (keep the name `roblox-vfx`) into your agent's skills folder:

| Agent | Per-user | Per-project |
| --- | --- | --- |
| Claude Code | `~/.claude/skills/roblox-vfx/` | `.claude/skills/roblox-vfx/` |
| Codex | `~/.codex/skills/roblox-vfx/` | `.agents/skills/roblox-vfx/` |

Check your agent's docs if its version reads skills from somewhere else. For an agent without skill support, add a line to its instructions file (such as `AGENTS.md`): "For any visual effect work, read `<path>/roblox-vfx/SKILL.md` first."

## Needs

- Roblox Studio with an MCP server that exposes `execute_luau` and `screen_capture` (`upload_image` is optional).
- Blender with an MCP add-on that runs Python, for drawing textures and meshes.
- The first time the skill runs in a project, it asks where effects live and records the answers in the project's agent instructions.

## Contents

| File | What |
| --- | --- |
| `SKILL.md` | Workflow, emit attributes, playing effects from code, frame-by-frame checking |
| `references/design.md` | Colour, value, brightness, timing and budget rules, plus review questions |
| `references/recipes.md` | Layer skeletons with starting values, and Luau that builds a template |
| `references/textures.md` | Drawing textures and mesh shapes with the scripts |
| `scripts/vfx_draw.py` | Texture and flipbook drawing (numpy only) |
| `scripts/vfx_shapes.py` | Mesh shapes and FBX export (Blender) |
| `templates/VFXEmit.luau` | The player module; copy into the place as a ModuleScript |

## Credits

Built on [Roqer](https://github.com/S4US/Roqer) by S4US (commit `bf7118b`), shared with the author's permission. `templates/VFXEmit.luau` is Roqer's emit module, unmodified. The Blender scripts are derived from Roqer's Blender helpers, and the references are condensed from Roqer's VFX docs. Keep the attribution headers in the files.
