---
description: Tag any R15 rig `ChopDummy` and the client loops the chop animation on it (wind-up loop, strike every training interval) via `Utils/ChopAnimation`.
type: reference
updated: 2026-10-10
---
The chop is two animation clips (2026-10-10, made by the user's friend): `Anim_Chop_WindUp` (looped ready bob) and `Anim_Chop_Strike`. They are Animation instances in `ReplicatedStorage.Assets.Animations`, looked up through `AssetRegistry`. The source KeyframeSequences (`KarateChopWindUp`, `KarateChopStrike`) live in `Workspace.TemplateR15.AnimSaves`. The old procedural `ChopPose` joint-Transform pose was deleted in the swap.

- `src/shared/Utils/ChopAnimation.luau` loads the tracks and switches between None / WindUp / Strike. `ChopAnimationController` drives the player (meter: wind-up until release, then strike; training and dummy: strike starts so its impact lands on the chop). The `ChopDummy` client component (`src/client/Components/ChopDummy.luau`) loops the training timing on any tagged R15 Model.
- Strike timing lives in `Config/ChopAnimationConfig`: the strike starts at 0.12 s (skipping the clip's recovery from its own end pose) and impacts at 0.33 s. The last pose is held by setting speed to 0 near the end.
- Master uses the same two clips (wind-up during the 3 s cinematic, strike timed to the impact). A one-arm master swing is deferred, see [[To Do]].
- An Animation with an empty `AnimationId` gives no track, so nothing plays until the ids are filled. To test unpublished clips in Play: on the Client, `KeyframeSequenceProvider:RegisterKeyframeSequence` each KeyframeSequence, put the result in the Animation's `AnimationId`, then `LoadCharacter` from the Server.
- The first dummy stands by the VFX showcase (about X 330, Z -286) as a direct child of Workspace: anchored HumanoidRootPart, `Animate` script removed, `ModelStreamingMode = Atomic`. Copy it to add more; each gets a random phase offset. Keep every dummy `Atomic`, or it streams in part by part and the load times out.
- It only moves in Play. Do not put it inside `VFXShowcase` (that folder is `EditorOnly`, so it never reaches Play).

See [[Chop Effects]], [[Asset Ownership]].
