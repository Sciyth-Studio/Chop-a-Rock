# RobloxVFX

The runtime modules of the `roblox-vfx` skill, vendored unmodified in `src/`:

| Module | What |
| --- | --- |
| `Emit` | Plays effects from the `EmitCount` / `EmitDelay` / `EmitDuration` attributes; `play`, `emit`, handle `freeze`, `setTimeScale`, `stop` |
| `Build` | Builds instances from JSON or table steps; `Build.run(root, steps)`, `Build.previewLeftovers()` (dev tool) |
| `Capture` | Holds an effect at a moment and aims the camera, for checking frames (dev tool) |
| `Shapes` | EditableMesh shapes (`Arc`, `Ring`, `TornRing`, `Cone`, `Swirl`, `Shell`) baked from shape spots |

- Source: the `roblox-vfx` skill (`templates/`), adapted from Roqer's `roblox-animation-vfx` skill (github.com/S4US/Roqer). MIT, Copyright (c) 2026 TabooHarmony; see `LICENSE`. `Emit` is the same code as the earlier `vendor/VFXEmit` (Roqer `bf7118b`) apart from its header line.
- Mapped by `default.project.json` to `ReplicatedStorage.VFX` (`ReplicatedStorage.VFX.Emit` etc.). Type checking is off for `vendor/` (`vendor/.luaurc`).
- Used by the `vfx` skill (`.claude/skills/vfx`).

To update, replace the files in `src/` with newer copies from the skill's `templates/` and run `./scripts/check.ps1`.
