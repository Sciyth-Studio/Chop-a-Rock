---
description: 9-step first-time tutorial (train, chop, arms, train, chop, geode, crack, collect, final); server owns the step in PlayerData, client draws pinned notification text, pathfinding chevrons, SpotlightUI on buy buttons and red pad locks. Built 2026-10-16.
type: system
updated: 2026-10-17
---
# Tutorial

Plan and decisions: `TutorialSystemPlan.md` (approved 2026-10-16). Pacing rule from the user: a training step lasts at most ~5 s, and a chopping step needs at most 3 rocks.

## Steps
`Tutorial.luau` (shared) numbers them: Train 1, Chop 2, BuyArms 3, TrainAgain 4, ChopAgain 5, BuyGeode 6, Crack 7, Collect 8, Final 9, Done 10, FirstRebirth 11 (funnel only). Goals are in `TutorialConfig` (Strength 4 and 10). The cash goals read `ArmConfig.Tiers[2].Price` and `GeodeConfig.Geodes.Forest.Price` ($150 each since 2026-10-16), so changing a price moves the step.

## Server: `TutorialService`
- Owns `Tutorial = { Step, Taps, Furthest }` in `PlayerData`. New profiles start at 1. Old profiles with any progress are migrated to Done in `PlayerData.Migrate`. `DataService:ResetData` restarts it, and admin presets set Done unless the preset is fresh.
- `check(player)` runs every 0.25 s for every player:
  - Later milestones win: a hatched Rok goes to Collect, a held geode to Crack, `ArmTier` 2 to TrainAgain.
  - Cash dropping below the goal sends the step back.
  - Training steps need a rep made during the step (`TrainingService.Trained` adds to `Taps`).
  - Collect waits for `PedestalService.Collected`.
  - Final turns into Done after 3 s.
- Funnel: `LogOnboardingFunnelStepEvent` logs each step once, tracked by `Furthest`. Step 1 is logged on join. FirstRebirth is logged for done players with `Rebirths > 0`. The `TutorialSkip` packet logs the custom event `TutorialSkipped` (value = step) and sets `Furthest` without logging the skipped steps.
- Gates, all through the shared module:
  - Chopping is refused outside the chop steps (`RockService`).
  - `ArmService.BuyTier` and `GeodeService/Purchasing` only work on their own step.
  - The first Basic rock in step Chop is forced Perfect on every hit, with no Master roll.
  - No Rush rock while the tutorial runs.
- Weather is ignored for tutorial players:
  - `WeatherService:RollStormRock(player)` and `RollHatchModifier(player)` return nil.
  - Catch rolls skip them.
  - `StartStorm` skips them.
  - Start and end notices skip them.

## Client: `TutorialController`
- `init` pins two notifications through `NotificationController:Pin(id, "Tutorial", text, order)`: the title with progress ("Break the boards! 2/4", "$87/$150") and the detail.
  - Pins never time out, bypass the Notifications setting, and sit at the top of the `Notifications` container.
  - Detail text adapts to the device: "Press E", "Tap Train" or "Press X" for training; "Hold E to chop a Stone" then "Press E on the rainbow!" (gamepad R2, touch "Tap Chop").
  - While the tutorial runs it hides `MenuButtons`, `TeleportBar`, `WeatherPill`, `DiamondRockPill`, `HotStreakBar` and `TrainingHint` by forcing `Enabled = false`, and restores them at Done.
- `Targets` finds each step's target:
  - Own plot = `BasePlots` child whose `OwnerUserId` matches.
  - The stand front comes from the `TrainingBoard` tag.
  - Nearest `Rocks.Rock_Basic`, the `ShopPad` tagged parts by `Screen`, `GeodeSpot`, and `Pedestal<slot>.EarningsPad`.
- `Path` runs `PathfindingService` from the character to a standing spot in front of the target.
  - It recomputes every 1 s, when the goal moves more than 3 studs, or when the player strays more than 6 studs.
  - `ComputeAsync` runs on its own thread and keeps the last path. With no path it falls back to a straight line.
- `Guide` (`Workspace.TutorialGuide`):
  - Arrows use the existing "Speed Arrows" image (white double chevron, black outline, points up in the image), registry key `Image_GuideArrow` = `Assets/Images/GuideArrow`, rbxassetid://10249261576. The user chose it over modelled arrows on 2026-10-17.
  - 36 pooled invisible flat Parts carry it as a Top decal, turned by `ChevronYawDegrees` (180; the user confirmed the direction on screen 2026-10-17). They are parked at y -500.
  - The marker is a `TutorialMarker` BillboardGui showing the same image turned 180° to point down, bobbing above the target.
  - The `UI_RockLabel` billboard reused as the target label.
  - One pulsing Highlight.
  - Everything is hidden during a chop or training round, while the step's shop panel is open, and during `HatchReveal` and `Letterbox`.
- `Spotlight` wraps SpotlightUI (Rectangle, pulse 8, `DisplayOrder` 8 so the dim stays under the Notifications text). Targets:
  - `Shop…Tier2.BuyButton` and `GeodeStand…BuyOne`.
  - During the first Stone's chop rounds (`Tutorial.ForcesPerfect`), the Good-to-Perfect range of the meter. The meter is one gradient, so `Spotlight` keeps an invisible `TutorialGoodZone` Frame inside `ChopMeter.Bar` sized to the Good band from `ChopZones.Bands(center, ratio)`, refit every frame as the zone moves. Asked for by the user 2026-10-17 instead of the whole bar.
- Cutscenes hold the tutorial: while `HatchController:IsPlaying()` (your own hatch only, through the reveal screen closing), `HatchReveal` or `Letterbox` is up, the guide, spotlight and pinned text are cleared. The next step (and its sound) appears only after. The server also keeps Crack until `GeodeService:IsRevealing` ends.
- No Master chop (rocks or geode crack, admin-forced included) and no Hot Streak (`RecordChop` isn't called, multiplier 1) while the tutorial runs.
- Hidden screens track their own code's wanted state both ways (an own-writes counter tells the tutorial's forced `false` apart from the screen closing itself). Before 2026-10-17 a screen that closed while hidden came back on at Done, which left "Press Space to stop training" stuck.
- `Locks` puts a red Neon box and a "Arms first!"-style billboard over every pad that's closed for the step. `ShopPad` won't open a closed pad, and `RockController` hides chop prompts when chopping is locked.
- `StarterGui.TutorialHud` (a copy of a Teleport Bar button, top right) has the Skip button. The first tap shows "Sure?" for 3 s and the second sends `TutorialSkip`. It shows until Final.

## SpotlightUI
Vendored unmodified at `vendor/SpotlightUI` from `Vvshenok/SpotlightUI` commit `614cc28` (MIT, no releases published), mapped to `ReplicatedStorage.SpotlightUI` in `default.project.json`. It ships its own Janitor and GoodSignal and prints a banner on require.

## Tested in Play (2026-10-16, by value, not seen on screen)
- Full path on a reset profile, with these timings: 4 reps / ~4 s, 3 Stones ($88 + $53 + $9), arms bought through the spotlight, 3 reps at +2, 2 Stones, geode bought, cracked (Sprout), pad collected, Done after 3 s.
- The funnel fired 10 events, once each.
- Spotlight cut-outs were centred on both buy buttons within 1 px.
- Reset restarts the tutorial, and Done persists across Play.
- During a Sandstorm the tutorial player had 0 storm rocks, no pill and no notice; the weather shows after Skip.
- Skip with confirm works.
- Decal arrows (2026-10-17): the user played them and confirmed they point the right way.
- 2026-10-17 fixes: the user tested the chop-bar spotlight (works, asked for the Good-to-Perfect range instead). The Good-zone spotlight, master/streak off, hatch hold and hidden-screen fix pass the checks but are not playtested.
- **Not checked:** how the chevrons, marker, locks and spotlight look; touch and gamepad text; the move-back rule; phone layout of the Skip button.

## Gotchas
- `user_mouse_input` with an `instance_path` on `TutorialHud.Container.SkipButton.Button` clicked the middle of the screen. Click by coordinates, with x/y on the down and up steps.
- Two separate tool calls take longer than the 3 s Skip confirm. Send both taps in one batch.

Related: [[Shop Pads]], [[Weather]], [[Pedestals]], [[Geode Shop]], [[Rebirth Gated By Strength]], [[UI Feel]]
