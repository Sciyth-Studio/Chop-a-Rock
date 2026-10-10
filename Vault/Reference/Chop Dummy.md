---
description: Tag any R15 rig `ChopDummy` and the client loops the procedural chop pose on it; the pose math is shared in `Utils/ChopPose`.
type: reference
updated: 2026-10-09
---
The chop "animation" is procedural joint Transforms, not an Animation asset, so a dummy can't just play a track. `src/shared/Utils/ChopPose.luau` holds the rig lookup and pose math; `ChopAnimationController` uses it for the player and the `ChopDummy` client component (`src/client/Components/ChopDummy.luau`) loops the training-style wind-up and strike on any tagged R15 Model.

- The first dummy stands by the VFX showcase (about X 330, Z -286) as a direct child of Workspace: anchored HumanoidRootPart, `Animate` script removed, `ModelStreamingMode = Atomic`. Copy it to add more; each gets a random phase offset.
- Workspace streams. A dummy far from spawn on `Default` streaming mode arrives part by part, `ChopPose.Build` times out after 10 s and it never moves. Keep every dummy `Atomic`.
- It only moves in Play: joint Transforms do not render in Edit, so the showcase plugin cannot drive it. Do not put it inside `VFXShowcase` (that folder is `EditorOnly`, so it never reaches Play).
- Anchored dummies can't use HipHeight, so the crouch drop goes on `LowerTorso.Root.Transform` instead.

See [[Chop Effects]].
