---
description: 2026-11-03 original chop bar style turned horizontal, square corners; over-the-shoulder camera on wind-up, chop camera for the impact; hotbar hidden
type: system
---
# Chop Minigame

**2026-11-03, draft, not playtested.** Look and camera from the user's reference. Timing and quality rules didn't change (`ChopZones`, `ChopTiming`, server judging). Rocks, Geode Fall and the Diamond Rock all share it.

![[Chop Bar Reference.webp]]
Take from the reference: the camera angle and the bar's size and place only. The user corrected a first try that copied its translucent body and arm marker: the bar keeps the game's own style, only turned horizontal, with square corners.

## The bar
- `StarterGui.ChopBar` (`Screens/ChopBar.luau`) is styled like the enemy fight bar (`EnemyFight.Container.HealthBar`), the user's choice after trying the old meter turned sideways. `Bar` is 916x96 centred at 83.5% height, as measured from the user's 1080p reference: dark background, 3 px black `OuterStroke`, and an inset `Track` holding `Fill` + `RampGradient` (rotation 0), `StudTexture`, `Shade`, `Bevel` and `Lip`.
- The five quality colours stay solid in one gradient. `Bevel` and `Lip` are see-through white and black, because a single tint can't match five colours. They sit beside `Fill` in `Track`, not inside it.
- `Cursor` is the fight bar's divider: white, 22 wide, 4 px black outline, 14 taller than the track. It sits in `CursorLane`, unclipped and the same size as `Track`, so position 0 to 1 lines up with the zones.
- `ChopBar.luau` looks up `Fill` and `Cursor` inside `Bar`, because `LeaveBlock` has its own `Fill`.
- Close is a red block button under the bar: `LeaveRoot` (220x72 at 93% height, holds `ScreenScale`) > `LeaveBlock` (copied from a `TeleportBar` button) > `LeaveButton`. It keeps `ButtonFeel` hover because the `ScreenScale` sits on the wrapper.
- The `Toolbar` screen (hotbar and Pets button) closes during a chop and reopens after it, with the `TeleportBar`.
- `TutorialChopBarHint` sits above the Good band, arrow pointing down. `Spotlight`'s `TutorialGoodZone` is a vertical slice of `Bar`.

## The camera
`ChopController.stepCamera` is the only per-round camera writer, except the Master cinematic, and it does nothing once the shot has settled, so it doesn't fight other camera code.
- Wind-up: `WindUpCameraOffset` from the player's flattened snap position. It looks at the rock, but no higher than `WindUpCameraMaxLookHeightStuds` above the root, so the player stays in frame on big rocks.
- Release: to the old chop camera in `ImpactCameraSeconds`. `LiveSplit` still cuts square to this view.
- After a hit: holds `ImpactCameraHoldSeconds`, then returns in `WindUpCameraReturnSeconds`, timed to land before the next round (0.78 s after impact, from `RoundPauseSeconds` minus `SlowMoPreImpactSeconds`). A Master also waits `StrikeHoldSeconds`.
- Walls: a ray from the player's shoulder height to the camera pulls it in. It skips fully transparent parts and other characters. If less than `WindUpCameraMinDistanceStuds` is clear, the wind-up uses the chop camera instead.

## Gotchas
- The bar is a new ScreenGui rather than an edit of `ChopMeter` because Team Create applies Studio edits at once, while the code in Studio stayed on the vertical version until this branch merges. Delete `StarterGui.ChopMeter` and `TutorialChopHint` after the merge ([[To Do]]).
- A UIGradient holds 20 keypoints at most. The ramp uses at most 18 (9 pieces).
- A player zoomed into first person keeps a hidden character in the wind-up shot, because the transparency controller stops updating under a Scriptable camera. Not handled.

See [[Chop Timing Uses Client Time]], [[Tutorial]], [[Slice Test]].
