---
description: Freeze the local player's movement only through Utils/MovementLock; hand-rolled WalkSpeed save/restore leaves players stuck when locks overlap.
type: gotcha
---
**Bug (2026-10-07):** after a chop the player could not walk or jump. On the client, WalkSpeed, JumpPower and JumpHeight were all 0, while the server still had 16 / 50 / 7.2. The animations were still playing, so the pose code was not the cause.

**Cause:** ChopController and HatchController each saved WalkSpeed, set it to 0 and restored the saved value later. Hatch reveals wait for the chop minigame to end, so several geodes that finish during a chop all start together right after it. The second one saves the 0 the first one set, finishes last and restores 0.

**Rule:** client code that freezes the player calls `MovementLock.Acquire(humanoid)` (`src/shared/Utils/MovementLock.luau`) and calls the function it returns to release. Locks are counted per humanoid: the first lock saves the values and only the last release restores them. Never write WalkSpeed, JumpPower or JumpHeight directly to freeze the player.

**Walk speed (2026-10-08):** MovementLock no longer owns the speed value. It restores the server-published `WalkSpeedTarget` (see [[Hot Streak]]), and TrainingService freezes through `WalkSpeedService:Freeze`, so the old overlap risk is gone.
