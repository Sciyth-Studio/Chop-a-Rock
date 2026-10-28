---
description: Claude can make and upload R15 animations itself - pose data in Python to .rbxmx, Open Cloud upload as model/x-rbxm under the group, preview in Edit with StepAnimations; joint sign conventions; uploads can't be archived or updated.
type: reference
---
# Animation uploads

Found 2026-10-27 while making the [[Intro Cutscene]] clips.

- **Writer:** `scripts/animation_rbxmx.py` turns a clip (keyframes of per-joint Euler degrees + offsets) into a KeyframeSequence `.rbxmx`, with `KeyframeMarker`s for events, and uploads it. A clip file imports it (`assets/Animations/Intro/intro_clips.py build|upload [names]`). Python is `py -3` on this machine (no `python`).
- **Upload:** Open Cloud `assets/v1/assets`, `assetType` **Animation**, creator group 10962733, with the file part sent as `type=model/x-rbxm` even though the file is XML. `model/x-rbxmx` is refused ("not supported yet"). Approved instantly. The key in [[Open Cloud Key]] needs no extra scope.
- **No clean-up:** animations can't be archived ("not an archivable asset type"), and a PATCH with a new file didn't make a new revision. Every draft is a new group asset, so preview before uploading and re-upload only the clips that changed.
- **Preview in Edit:** load the uploaded id on a TemplateR15 clone with `Animator:LoadAnimation`, wait for `Length > 0`, `Play(0, 1, 0)`, set `TimePosition`, then `Animator:StepAnimations(0.001)`. Parts only move if every part except `HumanoidRootPart` is **unanchored** (TemplateR15 has anchored limbs). Writing `Motor6D.Transform` or C0 by hand doesn't render in Edit. A row of clones at different times makes a contact sheet in one `screen_capture`. `KeyframeSequenceProvider:RegisterKeyframeSequence` also works but Studio's HTTP is off, so big clip data can't be fetched into Studio; uploading was simpler.
- **Parent before loading:** `LoadAnimation` on a rig that isn't in the DataModel yet gives tracks whose `Length` stays 0, with no error (the intro's first playtest: "Animations did not load in time"). Parent the rig to workspace first.
- **R15 joint signs** (Pose = `CFrame.new(p) * CFrame.Angles(rx, ry, rz)`, rig facing -Z): shoulders and hips +rx swing forward/up; elbows +rx bend; knees -rx bend; waist and neck +rx lean back / look up; left shoulder -rz and right +rz raise sideways; LowerTorso (Root) +ry turns left, offsets are in root space (-Z forward, +X right).
- **No fast jitter layers:** a "tremble" that flips sign every 2 frames, sampled every 3, aliases into a slow, random-looking wobble. The user read the Master's wind-up as an animation bug (2026-10-28). Keep any shake slower than the sample rate, or leave it out.
- **Switch clips and move roots in `PreAnimation`, not `Heartbeat`:** a travel clip (root offset baked in) followed by moving the root and playing the next clip from `Heartbeat` shows one frame with both the old pose's offset and the moved root. Heartbeat runs after that frame's animation step, so the next render has the new root but the old pose. The intro's player copy "flickered" after the car hit (BoingOut to Dazed) until the timeline moved to `RunService.PreAnimation` (2026-10-28).
- Euler values interpolate component-wise between dense samples (every 3 frames), so a 360° flip is fine; sparse keys take the short way round.

Related: [[Open Cloud Key]], [[Intro Cutscene]], [[Chop Dummy]]
