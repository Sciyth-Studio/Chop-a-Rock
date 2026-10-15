---
description: Hot Streak (2026-10-08) - chained Good+ chops multiply chop money and add walk speed; where state lives, how speed bonuses combine with freezes, config, sounds, gotchas.
type: system
---
# Hot Streak

Good, Great, Perfect or Master chops on rocks add 1 to a streak count. Mid holds, Bad drops one tier step (never to zero; with no tier it holds), a too-weak crack is ignored. 8 s without a chop clears it; respawn and leaving clear it. Not saved.

Easy rocks don't count (2026-10-10): if the player's strength is more than `MaxStrengthRatio` (25, draft) times the rock's requirement, the chop doesn't build, drop or refresh the streak and gets no multiplier. Tiers are 5x apart, so only the top two breakable tiers count. Diamond Rock chops call `KeepAlive` instead: the timer refreshes, but there's no build, drop or multiplier (see [[Diamond Rock]]).

## Where things live
- `HotStreakService` (server) owns count and tier and publishes player attributes `HotStreakTier`, `HotStreakCount`, `HotStreakExpiresAt` (server time). Every client reads them, so other players' head fire needs no packet. `RockService` calls `RecordChop` (returns the multiplier for this chop) and `ApplyCashMultiplier`, next to the other cash multipliers. `ChopResult` carries the multiplier so the client can show it.
- Numbers (tiers, fade, colours, fire scales, screen effect strengths, sound pitch) are all in `HotStreakConfig`: x1.1 / x1.25 / x1.5 / x2 at 3 / 6 / 10 / 15 chops, +2 / +4 / +6 / +8 walk speed. All drafts.
- Client: `HotStreakController` (head fire on every streaking character, loop and up sounds, FOV punch and camera shake, signals `Changed`, `TierUp`, `Dropped`). Tier-up and drop effects wait for `ChopController.ResultShown` so they land on the chop impact. Screens: `HotStreakBar` (a 65% copy of the level bar, `StarterGui.HotStreakBar.Container`, a CanvasGroup so it can blink; sits `BarGapPixels` above `ExpBar.Container` and slides into its slot while the level bar is closed during chops) and `HotStreakFx` (vignette, "Hot Streak x1.5" pop, "Streak down"). Chop cash pop text is `CashPopController:PlayText` using the `CashPopText` billboard.

## Walk speed
- `WalkSpeedService` sums named bonuses per player (`SetBonus(player, source, amount)`; auras and pet speed traits can add their own source) on top of `WalkSpeedConfig.BaseWalkSpeed` and publishes the player attribute `WalkSpeedTarget`. `Freeze(player)` (ref-counted, used by `TrainingService`) makes the target 0.
- Nothing saves and restores WalkSpeed any more. The client `WalkSpeedController` writes the target to the humanoid unless `MovementLock.IsLocked`, and `MovementLock` restores the current target on its last release, so a bonus that changes mid-chop is never lost and a lock can never restore a stale value. The server never writes `Humanoid.WalkSpeed`.

## Sounds
`SFX_HotStreak_Loop` and `SFX_HotStreak_Up` live in `Assets/Sounds` with empty SoundIds. An empty id warns once and skips.

## Gotchas
- Head fire textures (checked 2026-10-14) are third-party Creator Store images, not ours: `Flame` 11534281007 (ReiAkaris) and `FlameBack` 4509687978 (Senzial). Nothing to upload unless we want our own.
- The bar flame icon is `IconConfig.HotStreak` (94131698155889), uploaded from the user's account: it fails to load in the group game until shared with the experience (Output "Click to share access").
- The head fire only exists on characters in Play; to see it in Edit, look at the Hot Streak stands in [[VFX Showcase]]. Rate-based emitters do run in Edit mode (checked 2026-10-08).
- Camera shake adds an offset after the camera script each frame, so it also works while ChopController holds the camera Scriptable.

Related: [[Chop Effects]], [[Movement Lock]], [[Settings]]
