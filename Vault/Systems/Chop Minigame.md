---
description: 2026-11-03 horizontal chop bar with a flexed-arm marker; over-the-shoulder camera on wind-up, chop camera for the impact
type: system
---
# Chop Minigame

**2026-11-03, draft, not playtested.** Look and camera from the user's reference. Timing and quality rules didn't change (`ChopZones`, `ChopTiming`, server judging). Rocks, Geode Fall and the Diamond Rock all share it.

![[Chop Bar Reference.webp]]
Take from the reference: wide bar low on screen, thin black outline, translucent body, red at the end, flexed-arm marker, camera behind the player's back with the target in the middle.

## The bar
- `StarterGui.ChopBar` (`Screens/ChopBar.luau`): `Bar` 1400x96 at 77% height, `Fill` + `RampGradient` (rotation 0), `Cursor` holding the Strength icon with black outlines. Position 0 is the left end, 1 the right.
- Colours map to the reference: Bad is solid red, Mid is the translucent body (`ChopConfig.MeterBodyColor`, `MeterBodyTransparency`), Good, Great and Perfect stay solid green, blue, purple. "Too weak" rocks fill the bar red.
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
