---
description: 9-step first-time tutorial (train, chop, aura, train, chop, geode, crack, collect, final); server owns the step in PlayerData, client draws pinned notification text, straight-line chevrons, teleport-button spotlights, SpotlightUI on buy buttons, a chop-meter pointer and red pad locks. Built 2026-10-16.
type: system
updated: 2026-10-19
---
# Tutorial

Plan and decisions: `TutorialSystemPlan.md` (approved 2026-10-16). Pacing rule from the user: a training step lasts at most ~5 s, and a chopping step needs at most 3 rocks.

## Steps
`Tutorial.luau` (shared) numbers them: Train 1, Chop 2, BuyAura 3 (was BuyArms), TrainAgain 4, ChopAgain 5, BuyGeode 6, Crack 7, Collect 8, Final 9, Done 10, FirstRebirth 11 (funnel only). Goals are in `TutorialConfig` (Strength 4 and 10). The cash goals read `AuraConfig.Tiers[2].Price` (Silver Aura) and `TutorialConfig.GeodePrice` ($150 each since 2026-10-16), so changing a price moves the step. Since 2026-10-19 the Forest Geode costs $500 everywhere else; during the BuyGeode step a single Forest geode costs `TutorialConfig.GeodePrice` instead (`Tutorial.GeodeCost`, used by `GeodeService/Purchasing` and the Geode Shop's price label, which also watches `Tutorial` data). Buying 3 costs full price. The $150 Forest geode had made hatch-and-sell pay ([[Balance Pass Oct 18]]).

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
  - `AuraService.BuyTier` and `GeodeService/Purchasing` only work on their own step.
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
  - Detail text adapts to the device: "Press E", "Tap Train" or "Press X" for training; "Hold E to chop a Stone" then "Press E when the line is in the glowing zone!" (gamepad R2, touch "Tap Chop").
  - While the tutorial runs it hides `MenuButtons`, `WeatherPill`, `DiamondRockPill`, `HotStreakBar` and `TrainingHint` by taking them out of PlayerGui (`Parent = nil`) and puts them back at Done. The `TeleportBar` stays visible since 2026-10-19.
- `Teleports` (2026-10-19, user: "use teleport buttons as much as possible"): each step has a teleport (Train/TrainAgain/Crack/Collect → Base, chop steps → Rocks, BuyAura → Aura, BuyGeode → Geode). When it would save at least `TeleportSavingStuds` (40) of walking, or for Rocks whenever the player is behind the `TeleportPoints.Rocks` marker (lobby side of the gateway; the nearest Stone can be closer to the base through the zone wall), the spotlight goes on that bar button, the detail reads "Click Rocks to teleport there!" ("Tap" on touch), and the ground arrows hide. Shop teleports spotlight `ShopsButton` ("Click Shops at the top!") until the fan is open, then the `AuraOption` / `GeodeOption` slot.
- `Layout` keeps the pinned text under the bar while the tutorial runs: it offsets `Notifications.Container` to `NotificationGapPixels` below the bar, or below the lowest Shops fan slot while the fan is open, so the fan never covers "Click Aura to teleport there!". It leaves the text in place while Shop, GeodeStand or SellShop is open, and restores it at Done. The bar keeps DisplayOrder 0 so shop panels and the hatch reveal draw over it (a 2026-10-19 try at 11 put the bar over the panels).
- `Targets` finds each step's target:
  - Own plot = `BasePlots` child whose `OwnerUserId` matches.
  - The stand front comes from the `TrainingBoard` tag.
  - Nearest `Rocks.Rock_Basic`, the `ShopPad` tagged parts by `Screen`, `GeodeSpot`, and `Pedestal<slot>.EarningsPad`.
- Arrows run in a straight line from the character to a standing spot in front of the target. The `PathfindingService` version (`Path.luau`) was removed 2026-10-19 at the user's request.
- `Guide` (`Workspace.TutorialGuide`):
  - Arrows use the existing "Speed Arrows" image (white double chevron, black outline, points up in the image), registry key `Image_GuideArrow` = `Assets/Images/GuideArrow`, rbxassetid://10249261576. The user chose it over modelled arrows on 2026-10-17.
  - 36 pooled invisible flat Parts carry it as a Top decal, turned by `ChevronYawDegrees` (180; the user confirmed the direction on screen 2026-10-17). They are parked at y -500.
  - The marker is a `TutorialMarker` BillboardGui showing the same image turned 180° to point down, bobbing above the target.
  - The `UI_RockLabel` billboard reused as the target label. Stones get no label (user, 2026-10-19); `Target.Label` is optional.
  - One pulsing Highlight.
  - Everything is hidden during a chop or training round, while the step's shop panel is open, and during `HatchReveal` and `Letterbox`.
- `Spotlight` wraps SpotlightUI (Rectangle, pulse 8, `DisplayOrder` 8 so the dim stays under the Notifications text). Targets:
  - `Shop…Tier2.BuyButton` and `GeodeStand…BuyOne`.
  - During the first Stone's chop rounds (`Tutorial.ForcesPerfect`), the Good-to-Perfect range of the meter. The meter is one gradient, so `Spotlight` keeps an invisible `TutorialGoodZone` Frame inside `ChopMeter.Bar` sized to the Good band from `ChopZones.Bands(center, ratio)`, refit every frame as the zone moves. Asked for by the user 2026-10-17 instead of the whole bar.
- `ChopHint` (2026-10-19, user asked for the minigame to be "clear as day"): `StarterGui.TutorialChopHint` (DisplayOrder 9, above the spotlight dim) holds `Pointer` (ScreenScale) → `ArrowBody` (84 px, `Pulse` UIScale; one object can't stack two UIScales) with the guide arrow image turned 90° to point right and its shadow, plus `Label`/`LabelShadow` directly in `Pointer`. Only the arrow grows, because scaling the text box re-wrapped the text (user, 2026-10-19). During every tutorial chop and crack round it sits `ChopHintGapPixels` left of `ChopMeter.Bar`, its tip on the middle of the Good band, and switches between "Press E when the line is here" (`Chrome`, white arrow, gentle bob) and "Now! Press E!" (`Green`, green arrow, scale 1.25) while the cursor is inside the band. Hidden once released, when the rock can't be broken, and outside the tutorial. Positions checked by value; the look was seen in a screenshot of a preview copy, not in a real round.
- Cutscenes hold the tutorial: while `HatchController:IsPlaying()` (your own hatch only, through the reveal screen closing), `HatchReveal` or `Letterbox` is up, the guide, spotlight and pinned text are cleared. The next step (and its sound) appears only after. The server also keeps Crack until `GeodeService:IsRevealing` ends.
- No Master chop (rocks or geode crack, admin-forced included) and no Hot Streak (`RecordChop` isn't called, multiplier 1) while the tutorial runs.
- Hidden screens are reparented, never forced `Enabled = false` (2026-10-19). Forcing `Enabled` lost the screen's own state: when TrainingHint closed while already forced off, no change event fired, so it came back on at Done with "Press Space to stop training" stuck (seen twice: 2026-10-17 and 2026-10-19). Out of PlayerGui, screens keep writing their own `Enabled`. Tested in Play: train, stop, Skip → TrainingHint back with `Enabled = false`.
- Spotlight hide then show within the fade (teleport button → buy button after a teleport onto a shop pad): SpotlightUI's `Hide()` disables its gui after a delayed fade, which turned off the next spotlight. `Spotlight.Update` re-enables the gui every frame while it has a target.
- `Locks` puts a red Neon box and a "Aura first!"-style billboard over every pad that's closed for the step. `ShopPad` won't open a closed pad, and `RockController` hides chop prompts when chopping is locked.
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
