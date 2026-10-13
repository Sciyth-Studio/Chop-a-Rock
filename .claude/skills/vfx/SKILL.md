---
name: vfx
description: Use when making or changing any visual effect in Chop a Rock (a chop hit, rock break, perfect or master burst, hatch reveal, cash pop, aura, trail, shockwave, sparkle, dust), when drawing particle textures or flipbooks, when making mesh effects (crescent slash, shockwave ring, swirl, dome), or when playing effects from code. Covers design rules, drawing textures with the bundled Blender scripts, building the effect template in Studio, playing it with VFXEmit, checking it frame by frame, and uploading. Use it even for "make the chop look juicier" or "add some sparkles".
---

# VFX

Based on Roqer's VFX skill and tooling by S4US (https://github.com/S4US/Roqer), used with permission. `references/design.md` holds the design rules, `references/recipes.md` the layer skeletons and property values, and `references/textures.md` how to draw textures and mesh shapes. Load `design.md` and `recipes.md` for every effect, and `textures.md` when the effect draws its own textures or meshes, which most should. `references/studied.md` breaks down the user's reference effects in `Workspace.VFXReference` (aura, tornado, lightning, explosion, burst); it sets the quality bar, so read it and look at the folder in Studio before building anything similar.

## Pieces

| Piece | Where |
| --- | --- |
| Effect templates | `ReplicatedStorage.Assets.VFX`, in a feature subfolder (`Chop`, `Rock`, `Rush`, `Diamond`, `Aura`, `Hatch`, `Level`, `HotStreak`, `Training`, `Pedestal`; AssetRegistry and the showcase plugin search them recursively), one Model (or Attachment for older effects) per effect, named `VFX_<Name>`, registered in `src/shared/AssetRegistry.luau` (`Category = "VFX"`) |
| Player module | `ReplicatedStorage.VFXEmit` (vendored at `vendor/VFXEmit/Emit.luau`, unmodified; never edit it, wrap it) |
| Texture and flipbook drawing | `scripts/vfx_draw.py` (numpy only; runs in Blender's Python) |
| Mesh shapes | `scripts/vfx_shapes.py` (Blender) |
| Drawn files | `assets/VFX/<Effect>/` (hand-off folder, not committed); review copies in `%TEMP%\vfx_review` |

## Workflow

1. **Brief.** Name the effect's job and where the player sees it: chop effects are seen from right behind the character at 10 to 20 studs, base and shop effects from farther away. Ask the user (one AskUserQuestion round) for anything unclear: mood, palette, how big a moment it is. Palette defaults follow the vault: [[High Saturation Colors]] and the chop-quality palette. Read the place's `BloomEffect` (`Lighting`) before picking Brightness.
2. **Plan the layers** from `recipes.md`: list each layer's role, texture, timing, Brightness and LightEmission. Player-facing visuals are proposed to the user before they are final (AGENTS.md project rules).
3. **Draw textures and meshes** (`textures.md`). Read every `review` PNG the scripts return before using a texture, and fix every `clipped_frames` or unexpected `empty_frames`.
4. **Preview textures in Studio** without uploading: `vd.studio_preview(path)` copies the PNG into Studio's content folder and returns an `rbxasset://textures/vfx-preview/...` address. Only this computer can see it. A redraw needs a new preview call, because Studio caches each file name for the session.
5. **Build the template** in Studio with `execute_luau` (Edit, Play stopped): a Model named `VFX_<Name>` in its feature subfolder of `ReplicatedStorage.Assets.VFX` with an invisible, anchored, non-colliding `Root` part as PrimaryPart, Attachments holding the emitters, and the emit attributes (below). Add the AssetRegistry entry and run `./scripts/check.ps1`.
6. **Check it frame by frame** (below), from close and from the player's camera.
7. **Upload settled textures** only after the user approves the look. Uploads are irreversible and moderated: say how many there will be and get a yes first. The game's assets belong to the Sciyth Studio group (vault [[Asset Ownership]]), so ask the user to upload to the group, or confirm before using `upload_image`. `upload_image` only takes HTTP URLs: serve `assets/VFX/<Effect>/` on `127.0.0.1` with a small Node static server (PNGs only), and stop it afterwards. It uploads as the Studio user's own account (GuiltyArcher), not the group, so the group-owned game can't load the images until they are shared with the experience: Output logs "The experience doesn't have access permission to use asset id ... Click to share access" and `PreloadAsync` reports `Failure` (seen 2026-10-07 on VFX_LevelUp; vault [[Asset Ownership]]). Before uploading, tell the user this and offer the alternative of importing the PNGs through Studio with the group place open. After an `upload_image` upload, ask the user to click "Click to share access" on each Output message (or share each image with the experience in Creator Hub). Then replace every `rbxasset://textures/vfx-preview/` address; scan with `execute_luau` over `game:GetDescendants()` for any left.
8. **Wire into code** (below), playtest with the `studio-playtest` skill, and remind the user to save the place.

## Emit attributes

VFXEmit reads the attribute convention that VFX Editor, VFX Forge and similar plugins share, so the user can tune effects by hand:

| On | Attribute | Meaning |
| --- | --- | --- |
| ParticleEmitter | `EmitCount` | Burst this many (capped at 500) |
| ParticleEmitter | `EmitDuration` | Turn on at `Rate` for this many seconds |
| ParticleEmitter, Beam, Trail, lights | `EmitDelay` | Seconds from the effect's start (absolute, never summed with a parent's) |
| Beam, Trail | `EmitDuration` | Enabled for this long |
| PointLight, SpotLight, SurfaceLight | `EmitDuration` | On, then Brightness fades to 0 over this long |
| Model or Folder holding `Start` and `End` parts | `Duration` (0.4), `Easing` ("Quad"), `EasingDirection` ("Out"), `Spin` (degrees about Start's up axis), `EmitDelay` | `Start` tweens to `End`'s CFrame, Size, Transparency, Color and SpecialMesh Scale; Decals on Start fade to the same-named Decal on End. End is never shown |
| The effect's root | `EffectDuration` | Overrides when the effect ends |

Emitters with none of these keep running untouched. Our existing effects already use `EmitCount`, so they play through VFXEmit as they are.

## Playing effects from code

Effects are presentation and play on the client only. The server decides an event happened and tells clients through a Packet (name or key and a CFrame or position, never instances). Never make rewards or damage wait on an effect.

```lua
local VFXEmit = require(ReplicatedStorage.VFXEmit)
local template = AssetRegistry.get("VFX_Chop_Hit")
local handle = VFXEmit.play(template, CFrame.new(position))
handle:freeze(0.05)
```

- `VFXEmit.play(template, cframe, options?)` clones a Model or BasePart, places it, plays it and destroys it at the end. `options`: `parent`, `timeScale`, `onDone`.
- `VFXEmit.emit(root, options?)` plays emitters already in place (on a weapon, the arm, a pedestal) and restores them afterwards. Use it for Attachment templates: parent the clone first, then emit.
- The handle has `time`, `finished`, `root`, `stop()`, `setTimeScale(scale)` (0 to 1; slow motion) and `freeze(seconds)` (hitstop).
- `AssetRegistry.get` returns a clone; `VFXEmit.play` clones again. Fetch the template once per controller with `AssetRegistry.get` and keep it, or play the fetched clone in place with `emit`.
- A missing VFX asset comes back from `AssetRegistry.get` as a placeholder Attachment, and `VFXEmit.play` errors on anything but a Model or BasePart. Check `IsA("Model")` before `play` and skip the effect otherwise.
- VFXEmit is untyped (vendor). Cast its results to a local type in strict code.
- For effects that fire constantly, pool instead of cloning every time.

## Showcase

`Workspace.VFXShowcase` (tagged `EditorOnly`) holds a stand for every effect with a dummy (rock, R15 rig, board) so the user can look at them in Edit without pressing Play. Row `Chop` faces -X at X 300, row `Player` at X 340, around Z -395. The local plugin `plugin/VFXShowcase.lua` (installed by copying it to `%LOCALAPPDATA%\Roblox\Plugins\`, loaded when Studio starts) replays them on a loop; its "Loop VFX" toolbar button toggles them, and toggling off and on reloads the templates and configs. Everything it spawns is `Archivable = false`, so it is never saved.

When you add an effect, add a stand: duplicate a similar one and set its attributes.

| Attribute | Meaning |
| --- | --- |
| `Mode` | `Model` (a Model template played with `VFXEmit.emit` at the stand's `EffectAnchor` part), `Attachment` (an Attachment template parented to `EffectAnchor`, every emitter `Emit(EmitCount)`), `HeadFire` (Hot Streak fire on the `Dummy` rig's head), `Aura` (the aura template worn by a hidden copy of `Dummy` that walks back and forth so the trail shows; spins `SpinDegreesPerSecond` attachments) |
| `Effect` | Template name in `ReplicatedStorage.Assets.VFX` |
| `Loop` | Seconds between plays (default 3) |
| `Quality`, `RockColor`, `Scale`, `CountScale` | Chop tinting and scaling, as `RockController/Effects.luau` does it |
| `Color` | Recolour every emitter (board break, hatch burst) |
| `Then`, `ThenDelay` | A second template after a delay (Master wind-up, then burst) |
| `Tier` | Hot Streak tier for `HeadFire` |
| `WalkStuds` | How far an `Aura` walker goes each way (default 8) |

Physics doesn't run in Edit, so coins and rock chunks only show in Play. If the plugin's behaviour changes, update the copy in the Plugins folder too.

## Checking an effect

Effects play in Edit mode, so tune there and playtest at the end. `require` caches a ModuleScript for the Studio session in Edit, so after changing a module an effect uses, delete and recreate it (or restart Play) before trusting what you see.

Particles only age while Studio draws frames, and it stops drawing when its window is in the background (2026-10-09): a particle growing 1 to 20 studs over 4 s was still 1 stud after 2 s, so layers that start at size 0 or Transparency 1 never appear in a capture. Ask the user to bring Studio to the front before checking frames. Particles also only simulate near the real Edit camera (2026-10-10): `screen_capture`'s `camera_position` moves the view for the shot, but emitters far from where the user's camera sits stay frozen or empty. Set `workspace.CurrentCamera.CFrame` next to the effect with `execute_luau`, wait about 2 s, then call `screen_capture` without a camera position. Forcing a particle visible doesn't get around it: on 2026-10-10, a ground circle set to Transparency 0 and fired with `Emit(1)` still didn't show in a background capture, while Beams and Trails did.

In Play, `screen_capture` arrives too late for a 1 s effect and ignored a Scriptable camera set from the Client on 2026-10-07, though on 2026-10-09 it followed one (set `CameraType` and `CFrame` in one call, capture, then set it back to Custom). Judge looks in Edit; in Play, check physics pieces (coins, chunks) by sampling their positions over time with `execute_luau`.

1. Put a transparent anchored marker part where the effect plays (`Workspace.VFXPreview`), and point a Scriptable camera at it, once close (side and slightly above) and once from where the player's camera would be. Put the camera back to Custom afterwards (vault [[Always Restore Camera Type]]).
2. Hold the effect at chosen moments. One `execute_luau` call starts it slowed down and stops it at the first moment:
   ```lua
   local VFXEmit = require(game.ReplicatedStorage.VFXEmit)
   local h = VFXEmit.play(game.ReplicatedStorage.Assets.VFX:FindFirstChild("VFX_Name", true), workspace.VFXPreview.CFrame, { timeScale = 0.05 })
   _G.vfx = h
   while h.time < 0.1 and not h.finished do task.wait() end
   h:setTimeScale(0)
   ```
   Then call `screen_capture`, advance with the same loop to the next moment (`h:setTimeScale(0.05)`, wait for `h.time`, `setTimeScale(0)`), and repeat. Check 4 to 6 moments: anticipation, the flash (about 0.03 s), the peak, the body at about 0.3 s, the smoke, and just after the end. Trails lose their segments when frozen; check them at `timeScale` 0.05 without stopping. Finish with `_G.vfx:stop()`.
   Unconfirmed (2026-10-07): two flipbook particles emitted in Edit mode and frozen with `TimeScale = 0` after 0.05 s and 0.35 s showed the same frame. Before trusting a held frame's age in Edit mode, compare it with a playtest capture.
3. Ask of each capture the questions in `design.md` ("Review"). Check the output for `VFXEmit:` warnings.
4. Remove the marker. Tell the user what was checked and ask them to watch it at full speed: effects are judged by eye, and a screenshot of a held frame is not the effect.
