---
name: vfx
description: Use when making or changing any visual effect in Chop a Rock (a chop hit, rock break, perfect or master burst, hatch reveal, cash pop, aura, trail, beam, shockwave, sparkle, dust, camera shake or impact frame), when drawing particle textures or flipbooks, when making mesh effects (crescent slash, shockwave ring, swirl, dome), when matching a reference clip of an effect, or when playing effects from code. Covers design rules measured from published Roblox effects, picking textures from the user's VFX texture kit, drawing textures with numpy, building templates with Build, checking frames with Capture, uploading, and wiring effects into the game. Use it even for "make the chop look juicier" or "add some sparkles".
---

# VFX

`SK` = this folder (`.claude/skills/vfx`). Adapted from the `roblox-vfx`
skill, itself adapted from the VFX half of Roqer's `roblox-animation-vfx`
skill (github.com/S4US/Roqer, skills MIT-licensed by TabooHarmony,
`LICENSE-ROQER-SKILLS.txt`), wired to this project's `Roblox_Studio` MCP,
Rojo layout and Python.

**Read `LESSONS.md` first.** It holds every rule the user has taught about
effects, and it wins over anything below that disagrees. Write new VFX
feedback there. `references/studied.md` breaks down the user's reference
effects in `Workspace.VFXReference` (auras, tornado, lightning, explosion,
burst); they set the quality bar, so read it and look at the folder in Studio
before building anything similar.

## The loop

1. **Name the moment** and where the player sees it (`vfx-design.md` §1).
   Chop effects are seen from right behind the character at 10-20 studs;
   base and shop effects from farther away. A frequent small hit (every
   chop) is small, one hue and short; a reward beat (Perfect, Master,
   hatch, rebirth) is staged. Ask the user (one AskUserQuestion round) for
   anything unclear: mood, palette, how big a moment it is. Read
   `Lighting`'s `BloomEffect` before picking Brightness.
2. **Plan the layers** from a skeleton (`vfx-craft.md` §4) on the intensity
   curve (`vfx-design.md` §6): anticipation, flash, body, secondaries,
   smoke. Player-facing visuals are proposed to the user before they are
   final (AGENTS.md project rules).
3. **Get the textures** (`vfx-textures.md`). Check the user's texture kit
   first (`kit.py search`, then look at the contact sheets) and bring the
   chosen ones in with `kit.py prepare`; draw with numpy only what the kit
   lacks. Everything lands in `assets/VFX/<Effect>/`. Read every `review`
   sheet, and preview them in Studio without uploading.
4. **Build the template** with `Build` in
   `ReplicatedStorage.Assets.VFX.<Feature>.VFX_<Name>`, timing by attributes
   (`EmitCount` / `EmitDelay` / `EmitDuration`). Register it in
   `src/shared/AssetRegistry.luau`, run `./scripts/check.ps1`, add a
   showcase stand (below).
5. **Check it** in Edit with `Capture.hold` at 4-6 moments, close and from
   the player's camera (`vfx-craft.md` §6, including this Studio's capture
   gotchas). Fix, re-check.
6. **Upload** the settled textures in one batch once the user approves the
   look (`vfx-textures.md`; Open Cloud under the group), swap out
   preview addresses, wire it to gameplay (below), and check once in a
   playtest with the `studio-playtest` skill. Remind the user to save the
   place: templates live in the place file, not on disk.
7. Tell the user what was checked (by value versus seen on screen); ask them
   to watch it at full speed; write feedback into `LESSONS.md`.

## References (load what the effect needs, together in one go)

| File | Load when |
|---|---|
| `references/vfx-design.md` | **Always.** What the effect is for, palette, value (dark layers, black twins), brightness vs bloom, layers, timing curve, motion. Numbers measured from published effects |
| `references/vfx-craft.md` | **Always.** Where templates and the runtime live, emit attributes, replication, particle properties, layer skeletons with `Build` examples, budgets, the check loop |
| `references/studied.md` | Anything similar to the user's reference effects (auras, tornado, lightning, explosion, burst, ground trail); cleared texture ids |
| `references/vfx-textures.md` | Most effects: picking textures from the kit, drawing particle textures and flipbooks, preview, check, upload |
| `references/vfx-motion.md` | Projectiles, volleys, trails, beams, slashes, dashes, orbs, sigils, auras |
| `references/vfx-mesh-shapes.md` | Crescent meshes, shockwave rings, swirls, domes, ground waves |
| `references/vfx-camera-world.md` | Camera shake, FOV, blur, impact frames, lights, craters, scorch marks, cast pose from code |
| `references/vfx-rendered-flipbooks.md` | A flipbook rendered from a 3D scene in Blender instead of drawn |
| `references/vfx-reference.md` | The user supplied a video or GIF of an effect to match |

## Pieces

| Piece | Where |
|---|---|
| Effect templates | `ReplicatedStorage.Assets.VFX.<Feature>` (`Chop`, `Rock`, `Rush`, `Diamond`, `Aura`, `Hatch`, `Level`, `HotStreak`, `Training`, `Pedestal`, ...), one Model (or Attachment for older effects) per effect named `VFX_<Name>`, registered in `AssetRegistry` (`Category = "VFX"`; it and the showcase search subfolders recursively) |
| Runtime | `ReplicatedStorage.VFX.{Emit, Build, Capture, Shapes}`, vendored in `vendor/RobloxVFX/src` and synced by Rojo. Never edit them; wrap them |
| `Emit` | Plays effects from attributes; `play(template, cf, options?)`, `emit(inst, options?)`; handle `time`, `finished`, `root`, `freeze`, `setTimeScale`, `stop` |
| `Build` | `Build.run(path, steps)`: JSON/table steps -> instances (sequences, ranges, enums, `$id` links), one undo step, report string; `Build.previewLeftovers()` |
| `Capture` | `Capture.aim`, `Capture.playerView`, `Capture.hold(template, cf, t)`, `Capture.slow`, `Capture.release`, `Capture.marker` |
| `Shapes` | EditableMesh shapes (`Arc`, `Ring`, `TornRing`, `Cone`, `Swirl`, `Shell`, custom) baked from shape spots; `Shapes.prepare(template)` |
| Texture kit | `C:/Users/Admin/Downloads/VFX Assets` (1,935 ready-made textures, outside the repo); catalog and per-folder contact sheets in its `_catalog/` |
| `scripts/kit.py` | Kit catalog: `index`, `folders`, `search`, `sheet`, `prepare` (copies chosen ids into `assets/VFX/<Effect>/` at Roblox sizes, records sources) |
| `scripts/vfxtex.py` | numpy texture library (`tex_stroke`, `tex_blob`, `tex_warp`, `draw_flipbook`...) + CLI `check`, `review`, `preview`, `clean-preview` |
| `scripts/vfxblender.py` | For the `Blender` MCP: `flipbook()` renders a scene to a sheet; `vfx_arc/ring/cone/swirl/shell/surface`; `export_glb` |
| `scripts/clip_frames.py` | Reference clip -> labelled frame sheet + timing/brightness/colour table (ffmpeg, on PATH) |
| `scripts/upload_images.ps1` | Uploads PNGs as group-owned `Image` assets through Open Cloud; prints ids and merges them into `assets.json` |
| Texture scripts and PNGs | `assets/VFX/<Effect>/` (`textures.py`, the PNGs, `kit_sources.json` for kit textures, `assets.json` id map); review sheets go in the scratchpad, never there |
| Python (`PY`) | `C:/Users/Admin/AppData/Local/Python/bin/python3.exe` (numpy, Pillow). Plain `python`/`python3` hit the Store stub |
| Showcase | `Workspace.VFXShowcase` + `SK/plugin/VFXShowcase.lua` (below) |

## Ground rules

- **Particles, not 3D objects.** Effects are layered ParticleEmitters, Beams
  and Trails with real textures. Never ball/part clusters for smoke, fire or
  explosions. Mesh shapes are a layer (crescent, shockwave), not the effect.
- **Studio = `Roblox_Studio` MCP**, with the `studio_id` from
  `list_roblox_studios`. `execute_luau` with `datamodel_type` `Edit` (Play
  stopped) for building and checking.
- **Code lives on disk.** Rojo syncs `src/` and `vendor/`; never push Luau
  into Studio by setting `Source`.
- **Tool calls in one turn race.** Hold/aim in one turn, `screen_capture` in
  the next.
- **`require` caches in edit mode** for the whole Studio session: after a
  module changes, require a fresh clone or restart Studio.
- **Effects are client-side.** The server decides and tells clients through
  a Packet (names and CFrames, never instances); damage and rewards never
  wait on an effect.
- **Uploads are irreversible and moderated:** only the settled set, one batch,
  say how many first. Upload under the group with `upload_images.ps1`, not
  the Studio MCP's `upload_image` (vault [[Open Cloud Key]]).
- **`Shapes` in shipped effects** needs **Allow Mesh & Image APIs** on in
  Game Settings > Security, or `CreateEditableMesh` fails on clients. Ask
  the user to confirm it is on before relying on a baked shape in the game.
- **Particles can't show inside a ViewportFrame** (vault [[ViewportFrame
  Gotchas]]); hatch-scene effects must live in the world.

## Playing effects from code

```lua
local VFX = require(ReplicatedStorage.VFX.Emit) :: any
local template = AssetRegistry.get("VFX_Chop_Hit")
if template:IsA("Model") then
	local handle = VFX.play(template, CFrame.new(position))
	handle:freeze(0.05)
end
```

- `play(template, cframe, options?)` clones a Model or BasePart, places it,
  plays it and destroys it at the end. `options`: `parent`, `timeScale`,
  `onDone`. `emit(root, options?)` plays emitters already in place (on a
  weapon, the arm, a pedestal) and restores them afterwards; use it for
  Attachment templates (parent the clone first).
- The existing controllers keep the local name `VFXEmit` for this module
  (`RockController/Effects`, `CashPopController`, `WeatherController`, ...).
- Fetch the template once per controller and keep it (`AssetRegistry.get`
  returns a clone and `play` clones again). For effects that fire many times
  a second, pool instead of cloning.
- A mesh-shape template plays through `VFX.play(Shapes.prepare(template),
  cframe)`; call `prepare` once at load.

## Showcase

`Workspace.VFXShowcase` (tagged `EditorOnly`) holds a stand for every effect
with a dummy (rock, R15 rig, board) so the user can look at them in Edit
without pressing Play. Row `Chop` faces -X at X 300, row `Player` at X 340,
around Z -395. The local plugin `SK/plugin/VFXShowcase.lua` (installed by
copying it to `%LOCALAPPDATA%\Roblox\Plugins\`, loaded when Studio starts)
replays them on a loop with `ReplicatedStorage.VFX.Emit`; its "Loop VFX"
toolbar button toggles them, and toggling off and on reloads the templates
and configs. Everything it spawns is `Archivable = false`, so it is never
saved. If the plugin changes, copy it to the Plugins folder again.

When you add an effect, add a stand: duplicate a similar one and set its
attributes.

| Attribute | Meaning |
| --- | --- |
| `Mode` | `Model` (a Model template played with `emit` at the stand's `EffectAnchor` part), `Attachment` (an Attachment template parented to `EffectAnchor`, every emitter `Emit(EmitCount)`), `HeadFire` (Hot Streak fire on the `Dummy` rig's head), `Aura` (the aura template worn by a hidden copy of `Dummy` that walks back and forth so the trail shows; spins `SpinDegreesPerSecond` attachments) |
| `Effect` | Template name in `ReplicatedStorage.Assets.VFX` |
| `Loop` | Seconds between plays (default 3) |
| `Quality`, `RockColor`, `Scale`, `CountScale` | Chop tinting and scaling, as `RockController/Effects.luau` does it |
| `Color` | Recolour every emitter (board break, hatch burst) |
| `Then`, `ThenDelay` | A second template after a delay (Master wind-up, then burst) |
| `Tier` | Hot Streak tier for `HeadFire` |
| `WalkStuds` | How far an `Aura` walker goes each way (default 8) |

Physics doesn't run in Edit, so coins and rock chunks only show in Play.
