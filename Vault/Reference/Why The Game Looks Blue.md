---
description: Tested 2026-10-03 — the blue cast comes from the skybox lighting the scene (EnvironmentDiffuse/Specular 1), helped by a blue OutdoorAmbient and ColorCorrection saturation +0.5.
type: reference
---
# Why the game looks blue

Grey parts (the 67,67,67 lobby walls, the dark-grey base plot) render navy. Tested by turning the Lighting settings off one at a time and screenshotting the same view, then restoring them:

1. **Neutral Ambient/OutdoorAmbient (150 grey):** walls a little less blue, still navy. A minor factor.
2. **EnvironmentDiffuseScale and EnvironmentSpecularScale 0:** walls go **black**. They get almost no sun (noon, `ClockTime` 12, so vertical faces miss the direct light) and are lit almost entirely by the skybox `__WORLDFX` (blue sky images, e.g. `rbxassetid://6295671667`). This is the main cause.
3. **ColorCorrection off:** everything turns neutral grey. Its `Saturation` 0.5 boosts whatever tint there is, `Contrast` 0.5 crushes the darks, and `TintColor` 243,234,255 adds a slight blue-purple.

Current values: Brightness 4, Ambient 124,155,184, OutdoorAmbient 157,178,255, EnvDiffuse 1, EnvSpecular 1, ColorCorrection tint 243,234,255 / sat 0.5 / contrast 0.5. Atmosphere density is 0, so it has no effect. `Workspace.VFX` is a neutral ColorCorrectionEffect and does nothing in Workspace anyway.

Workaround in use: plot greys are slightly warm (82,76,70) to cancel the blue. Changing the lighting is player-facing, so get the user's go-ahead first.

Related: [[Base Plot Reference]], [[High Saturation Colors]]
