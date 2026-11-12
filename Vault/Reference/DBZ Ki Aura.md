---
description: Workspace.DBZKiAura - 2026-11-12 Dragon Ball style gold ki aura showcase (rippling wave shells off the body), built with the roblox-aura-vfx skill; layers, IDs and lessons.
type: reference
---
# DBZ Ki Aura

Built 2026-11-12 with the `roblox-aura-vfx` skill (zip in Downloads). Not playtested by the user yet; motion and timing need their eyes.

- `Workspace.DBZKiAura` at (1500, 0, -1500), tagged `StudioOnly` (stripped in live servers, shows in Studio playtests), ModelStreamingMode Persistent. Own dark slate floor, R6 rig, `PowerUpIdle` KeyframeSequence + `AuraDriver` client script (plays the idle via RegisterKeyframeSequence, pulses the PointLight). Lighting was set to night only for captures and put back; set `Lighting.ClockTime = 0` to view it as intended.
- Signature: gold flame-outline wave shells growing outward from the torso every 0.4 s (`Torso.Waves`), echoed by ripple rings on the floor.
- User feedback 2026-11-12: first pass was too tall, and they disliked the smooth ellipse ring sprites (6707322206 / 7083340510 squashed tall) coming off the body; those were removed. Flames now reach about a head above the rig (squash ~0.1, size ~3.3).
- Then removed at the user's request: the spinning stroke circle (shell + sphere + black twin) and every floor layer (glow, ripple rings, dust, debris). The aura is body-only now; only the gold PointLight still tints the floor.
- Palette: gold (white core -> 255,205,50 -> orange edge), cyan lightning accent, black twins.
- 2026-11-12 the user made it the game's base aura: rebuilt in white as `VFX_Aura` with stage and palette attributes (see [[Auras]]). The showcase rig here stays the original gold version and is not kept in sync.
- Recolouring lesson: textures with colour baked in (241600108 gold flame, 358152490 gold teardrop, 348501325 cyan lightning) can't be tinted to other hues because tinting multiplies (gold x blue = near black). The base uses white 567395887 for every flame and wave layer and white flipbook lightning 13771290435.
- Preview lesson: Studio caches `require` in Edit, so a config edited on disk reads stale from the command bar; clone the ModuleScripts and require the clones.

## Textures checked on a sheet
| ID | Looks like |
|---|---|
| 567395887 | white spiky DBZ flame aura (tints well) |
| 241600108 | gold spiky flame aura (colour baked in) |
| 358152490, 567485584, 1216336525 | gold teardrop aura outline (colour baked in) |
| 567454904, 1003176273 | orange/red flame aura (baked) |
| 567463923 | soft cream round glow |
| 348501325 / 348501416 | cyan lightning bits / cyan lightning ring (baked) |
| 80103256348315 | 4x4 rising chevron wave arcs |
| 12914395250 | filled ring with inward gradient (reads as a disc, not a ripple) |
| 106822944701902 | thin double shockwave rings, faint |

## Lessons
- Edit `screen_capture` with a camera position far from the real Studio camera shows no particles or billboards: move `workspace.CurrentCamera` there first, wait ~5 s, then capture.
- With `FacingCameraWorldUp` (and plain camera-facing), **positive** Squash makes a sprite taller; negative widens it. Negative = longer only with VelocityParallel.
- A gold PointLight turns blue clothing nearly black; use light or warm outfits on gold auras.
- Dark sphere twins with positive ZOffset draw over the torso; give them negative ZOffset.

Related: [[VFX Showcase]], [[Auras]], [[VFX Texture Kit]]
