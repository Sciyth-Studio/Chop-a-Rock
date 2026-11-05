---
description: 2026-11-03, not playtested - held Pets and geodes sit above the head with both arms up; HeldItemController plays the clip, HeldGrip places the item from a measured grip.
type: system
---
# Held Items

The user asked (2026-11-03) for players to hold held items above their head.

- **Pose:** `Anim_Held_Overhead` (asset 100500275101266, `assets/Animations/Held/held_clips.py`) raises both arms at Action priority and leaves the legs and torso to the walk animation. `HeldItemController` plays it on your own character while it has any Tool, and Roblox replicates it to other players.
- **Place:** `Utils/HeldGrip` sets `Tool.Grip` so the item's bottom sits `HeldItemConfig.GapStuds` above the head, centred, facing the way the character faces. `OverheadGrip` was measured on a default R15 rig with the clip playing. Change the clip and it has to be measured again. Avatars with very different proportions will sit a little off.
- **Measuring:** `Animator:StepAnimations` errors in Play. In Play, make a rig with `CreateHumanoidModelFromDescription`, play the clip and wait about 0.5 s, then read the parts. The grip is `CFrame.new(0, headTop, 0):Inverse() * rootToHand * RightGripAttachment.CFrame`.

Related: [[Toolbar]], [[Pedestals]], [[Geodes As Inventory Items]], [[Animation Uploads]]
