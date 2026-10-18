---
description: The invisible wall with the zone sign across the forest zone gateway; how it is built and how to copy it for other zones.
type: reference
---
# Forest zone entrance sign

`Workspace.Forest Zone.ZoneEntrance` is a 98 x 52 x 1 part across the gateway (x -7 to 91, z -195, in the front stone wall's tunnel). Fully transparent, `CanCollide`, `CanTouch` and `CanQuery` off so players, the camera and raycasts pass through. Its `ZoneSign` SurfaceGui (Front face, canvas 700 x 371) holds a `Holder` frame with a `Title` label ("Forest Zone", `Green` style) and a `Strength` label ("4 N to 100 N Strength", `Strength` style), both italic.

The strength range is typed by hand: 4 is the stone's `StrengthRequired` (2 until 2026-10-17) and 100 the mossy boulder's in `RockConfig` (doubled 2026-10-03 for pacing). Update the sign if those change; it is easy to miss because nothing in code reads it.

For the next zone, duplicate the part, move it to that zone's gateway, and change the text and styles. See [[UI Text Style]], [[Forest Rock Tiers]].

The forest sign now lives at `Workspace.Zones.ZoneForest.ZoneTemplate.ZoneEntrance`. The desert copy is `Workspace.ZoneDesert.ZoneTemplate.ZoneEntrance` at z -75: "Desert Zone" in `Gold` and "500 N to 12,500 N Strength" (draft numbers, 2026-10-07). World SurfaceGuis are not restyled at runtime, so after changing a `TextStyle` attribute, bake it in Edit with `Typography.ApplyTextStyle`.
