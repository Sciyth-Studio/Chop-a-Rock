---
description: ViewportFrame gotchas found building the Arm Shop previews (cameras, particles, R15 meshes).
type: reference
updated: 2026-10-03
---
- A `Camera` authored inside a ViewportFrame in StarterGui does not reach PlayerGui. Create it at runtime, set `CurrentCamera`, and put the FieldOfView in config.
- ViewportFrames do not render particles.
- Real R15 arm meshes: in Edit mode, `Players:CreateHumanoidModelFromDescription(Instance.new("HumanoidDescription"), Enum.HumanoidRigType.R15)`, take `RightUpperArm`, `RightLowerArm`, `RightHand`, strip constraints, and pose them with the elbow and wrist rig attachments. Saved as `Assets/Models/Model_ArmPreview` (AssetRegistry key `Model_ArmPreview`).
- Frame the camera from `Model:GetBoundingBox()`; `size.Magnitude / 2` overestimates the radius, so padding 0.8 fills the box.
- Set `Ambient` and `LightColor` on the ViewportFrame or materials render flat.
- No engine API or Studio tool can save a ViewportFrame or viewport render to a file. MCP `screen_capture` returns the picture to Claude only. Static icons are rendered in Blender instead (see `IconSystemPlan.md`, 2026-10-06).

See [[Menu Panel Style]].
