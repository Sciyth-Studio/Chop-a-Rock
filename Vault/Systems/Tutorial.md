---
description: 5-step first-time tutorial (train, chop, geode, crack, collect, then a 3 s finish) since 2026-10-27, no Skip, followed by a staggered aura hint; server owns the step in PlayerData, client draws pinned notification text, straight-line chevrons, teleport-button spotlights, SpotlightUI on buy buttons, a chop-meter pointer and red pad locks. Built 2026-10-16.
type: system
updated: 2026-10-27
---
# Tutorial

Plan and decisions: `TutorialSystemPlan.md` (approved 2026-10-16). Pacing rule from the user: a training step lasts at most ~5 s, and a chopping step needs at most 3 rocks.

## Steps
`Tutorial.luau` (shared) numbers them: Train 1, Chop 2, BuyGeode 3, Crack 4, Collect 5, Final 6, Done 7, then funnel-only milestones AuraBought 8, AuraTrained 9, SecondRok 10, FirstRebirth 11, Played30Min 12, Played60Min 13 (`Tutorial.LastMilestone`). 2026-10-27 (user, from Hud's Guide via the [[Launch Checklist]]): the aura, train-again and chop-again steps moved out to the staggered [[#Aura hint]], so the core is about a minute. Goals are in `TutorialConfig` (Strength 4). The chop cash goal is `TutorialConfig.GeodePrice` ($150), so changing it moves the step. Since 2026-10-19 the Forest Geode costs $500 everywhere else; during the BuyGeode step a single Forest geode costs `TutorialConfig.GeodePrice` instead (`Tutorial.GeodeCost`, used by `GeodeService/Purchasing` and the Geode Shop's price label, which also watches `Tutorial` data). Buying 3 costs full price. The $150 Forest geode had made hatch-and-sell pay ([[Balance Pass Oct 18]]).

## Server: `TutorialService`
- Owns `Tutorial = { Step, Taps, Furthest }` in `PlayerData`. New profiles start at 1. Old profiles with any progress are migrated to Done in `PlayerData.Migrate`. `DataService:ResetData` restarts it, and admin presets set Done unless the preset is fresh.
- `check(player)` runs every 0.25 s for every player:
  - Later milestones win: a hatched Rok goes to Collect, a held geode to Crack.
  - Cash dropping below the goal sends the step back.
  - Training steps need a rep made during the step (`TrainingService.Trained` adds to `Taps`).
  - Collect waits for `PedestalService.Collected`.
  - Final turns into Done after 3 s.
- Funnel: `LogOnboardingFunnelStepEvent` logs each step once, tracked by `Furthest`, filling in every step up to the furthest reached. Step 1 is logged on join. After Done, `milestone(data)` picks the highest milestone reached (60 / 30 min of `Playtime`, a rebirth, 2 Rok kinds in `Index.Pets`, Silver Aura bought, then aura hint Done) and logs up to it, so out-of-order milestones count as passed. Migrated old profiles and non-fresh admin presets start at `LastMilestone`. Thresholds in `TutorialConfig` (`SecondRokCount`, `Played30MinSeconds`, `Played60MinSeconds`). Economy events and the Robux shop funnel are in [[Analytics]].
- Gates, all through the shared module:
  - Chopping is refused outside the chop steps (`RockService`).
  - Auras can't be bought at all during the tutorial, and `GeodeService/Purchasing` only works on BuyGeode.
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
- `Teleports` (2026-10-19, user: "use teleport buttons as much as possible"): each step has a teleport (Train/Crack/Collect → Base, Chop → Rocks, BuyGeode → Geode). When it would save at least `TeleportSavingStuds` (40) of walking, or for Rocks whenever the player is behind the `TeleportPoints.Rocks` marker (lobby side of the gateway; the nearest Stone can be closer to the base through the zone wall), the spotlight goes on that bar button, the detail reads "Click Rocks to teleport there!" ("Tap" on touch), and the ground arrows hide. Shop teleports spotlight `ShopsButton` ("Click Shops at the top!") until the fan is open, then the `GeodeOption` slot (`AuraOption` for the aura hint).
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
- No Skip in the tutorial since 2026-10-27 (user, Hud's Guide: players skip by accident and get lost). The `TutorialSkip` packet and `TutorialSkipped` event are gone. `StarterGui.TutorialHud` (Skip with "Sure?" confirm) now shows only for the cannon hint.

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

## Staggered hints
Systems unlocked long after the tutorial get their own short guide when they unlock, not extra tutorial steps (user agreed 2026-10-20 for the cannon). First one: the Desert Cannon (`CannonHintSystemPlan.md`, approved and built 2026-10-20, passes check.ps1, waiting on the user's playtest), starting after rebirth 1 at 500 Strength (user).
- Stages in shared `CannonHint.luau`: Locked 0, Save 1, Buy 2, Fire 3, Done 4, stored in `PlayerData.Hints.Cannon` (furthest in `Hints.CannonFurthest`). Settings in `TutorialConfig.CannonHint`.
- `CannonHintService` re-decides every 0.25 s (later milestones win, Buy falls back to Save when cash drops), logs custom event `CannonHint` (value = stage) once per stage, sends "Desert Cannon unlocked!" on unlock. `CannonService.Landed(player, key)` from any cannon landing sets Done (with "Welcome to the Desert!" only if the hint was showing). Packet `CannonHintSkip` → Done + `CannonHintSkipped`.
- Client: a second session in `TutorialController` (`HintSession`, child `CannonHint.luau` builds the text, target and spotlight). Quiet while Strength < 500 unless in Fire, during hatches and `CannonController:IsFlying()`. Teleport hints go through `Teleports.ForDestination("Cannon", …)` (the shop is beside the lobby cannon). `TutorialHud` Skip shows during Buy/Fire.
- Migrate: profiles that own a cannon start Done. `ResetData` and presets set `Hints = {}`, so a preset with rebirths and 500+ Strength shows the hint. Rebirth needs `100 x 125^(n-1)` Strength, so each run after a rebirth is one zone further: run 1 forest, run 2 desert, run 3 jungle. Time later hints by rebirth count the same way. It reuses this controller's guide, spotlight, teleport and pinned-text parts and never locks anything.

Related: [[Shop Pads]], [[Weather]], [[Pedestals]], [[Geode Shop]], [[Rebirth Gated By Strength]], [[UI Feel]]

## Aura hint
Built 2026-10-27, the staggered half of the old aura steps (user approved the preview: core tutorial, then the aura hint, cannon hint unchanged). The user playtested the new tutorial and hint on 2026-10-27.
- Stages in shared `AuraHint.luau`: Locked 0, Save 1, Buy 2, Train 3, Done 4, in `PlayerData.Hints.Aura` (furthest in `Hints.AuraFurthest`, reps in `Hints.AuraReps`). Settings in `TutorialConfig.AuraHint` (tier 2 = Silver Aura, 3 reps).
- `AuraHintService` re-decides every 0.25 s once the tutorial is Done: Save until cash covers the aura, Buy, then Train after the buy, Done after 3 training reps (`TrainingService.Trained`). Any rebirth, or owning the aura before the hint ever started, goes straight to Done silently. Sends "Silver Aura unlocked!" on unlock, logs custom event `AuraHint` (value = stage) once per stage. No Skip.
- Client: shares the cannon hint's `HintSession`. `hintKinds` lists aura then cannon; the first active one shows. Child `AuraHint.luau` builds the text: "Save up for it: $x/$150", arrows and the Aura teleport to the red pad then a spotlight on `Shop.Tier2.BuyButton`, then "Train with your new aura! n/3" with the Base teleport and "Your aura gives x1.25 strength per rep!" while training. Views now carry their own `Teleport` id.
- Admin: Reset Tutorial has an "Aura Hint" choice.

## Good-zone spotlight
`Spotlight.TargetFor` spotlights the chop meter's Good band (a `Frame` made inside `ChopMeter.Bar`) during the first forced-Perfect Stone and, since 2026-10-27 (user, after playtesting), during the Crack step's minigame too, so the first geode open shows where to release. The crack isn't forced Perfect.

## Boulder hint
Built 2026-10-27 (user: "a staggered tutorial step for the first rock upgrade after you've trained to reach it"; picked the version with a training goal). Not playtested yet.
- Stages in shared `RockHint.luau`: Locked 0, Train 1, Chop 2, Done 3, in `PlayerData.Hints.Rock` (furthest in `Hints.RockFurthest`). Settings in `TutorialConfig.RockHint` (`RockKey = "Second"`, the Boulder).
- `RockHintService` re-decides every 0.25 s: Train starts once the aura hint is Done ("Train to unlock the Boulder! x/20", arrows and the Base teleport to your stand); at the Boulder's `StrengthRequired` it goes to Chop with a "Boulder unlocked!" notice ("Chop a Boulder! 4x cash", the multiple is Boulder ÷ Stone `BasePayout`, arrows to the nearest `Rock_Second`, Rocks teleport). Done on the first Boulder break (`Index.Rocks.Second`), or any rebirth. Already broken or rebirthed before it started = silent Done. Logs custom event `RockHint` per stage.
- Client: first in `hintKinds` (Boulder, then aura, then cannon), so its Chop stage shows over a waiting aura hint. Child `RockHint.luau`; `Targets.NearestRock(key)` replaced the Stone-only finder.
- Admin: Reset Tutorial has a "Boulder Hint" choice.

## Polish pass (2026-10-27)
Built from `TutorialPolishPlan.md` (user approved all six). Passes check.ps1, not playtested.
- **4 words max** (user rule, stricter than the guide's 5) for every title and detail line in the tutorial and all hints. Key names count, counters don't. The plan has the full before/after table.
- **Head start:** `TutorialConfig.StartStrength = 1` is the `PlayerData.Template` Strength, so the boards read 1/4 on join. The Chop title hides its cash counter until cash is above $0. Entering the aura hint's Train stage sets `Hints.AuraReps = 1` (buying counts as the first rep).
- **Praise removed (2026-10-27, user, after the playtest).** No step or hint praise; only the step sound plays.
- **Idle forgiveness:** `checkIdle` in `TutorialController`. After `IdleSeconds` (20) with no input (`UserInputService.InputBegan`), no movement (`Humanoid.MoveDirection`) and no step change, the guide goes urgent: `Guide.SetUrgent` doubles the marker and triples the highlight pulse, `SFX_Notification` pings every 20 s, the detail reads "Click here!"/"Tap here!" with a spotlighted button or "Over here!" with a world target, and teleports ignore the 40-stud rule (`Teleports.For(..., isForced)`). Runs in the core tutorial (not Final, not mid-chop or training) and in hint stages listed in `IdleStages` (aura Buy, cannon Buy, rebirth Ready).
- **Completion:** when the client sees the tutorial go to Done it calls `RebirthEffectController:PlayBurst()` (rebirth `VFX_LevelUp` + `SFX_Level_Up`) and opens `StarterGui.TutorialComplete` ("Tutorial complete!" Chrome, "Free 2x Strength!" Green, cloned from the WelcomeBack card labels; built in Studio 2026-10-27, needs a place save) for `CompleteSeconds` (2.5). The banner's reward text comes from the `TasteBoostKey` boost. The old "Free 2x Strength for 5 min!" notification is gone; the 5 min boost itself is unchanged.
- **Starter Offer hold:** `OfferService` opens the 24 h starter window on `RockHintService.Finished` (Boulder hint Done) instead of `TutorialService.Finished` (user, guide's "first give, then ask"). The rebirth second chance is unchanged.

## Rebirth hint
Built 2026-10-27 with the polish pass. Not playtested.
- Shared `RebirthHint.luau`: Locked 0, Ready 1, Done 2 in `Hints.Rebirth` (furthest `Hints.RebirthFurthest`), settings `TutorialConfig.RebirthHint`. Ready once the Boulder hint is Done and Strength reaches `RebirthStats.Get(1).StrengthRequired` (100). Done on the first rebirth (silent if already rebirthed). `RebirthHintService` logs `RebirthHint` per stage.
- Client `RebirthHint.luau`: "Rebirth for x1.25 cash!" / "Click Rebirth!", spotlight on `MenuButtons.Container.RebirthButton`, then `Rebirth…Buttons.RebirthButton` once the panel is open. Kept positive (user): no reset warning, the panel explains.
- Hint order in `hintKinds`: Boulder, rebirth, aura, cannon. Chain: tutorial → aura → Boulder → rebirth → cannon. Admin Reset Tutorial has a "Rebirth Hint" choice.

## One line of text (2026-10-27)
User rule after the playtest: **at most one line of tutorial/hint text on screen at a time.**
- Title and detail share one pinned notification (`TitleId`; `DetailId` is always unpinned). For `TitleSeconds` (2) after a step or hint stage starts, or after the line was hidden, it shows the title (the goal); after that the detail (the action), or the title when there's no detail. "Follow the arrows" and "Keep going!" are gone: the title shows instead.
- Hidden: during a tutorial chop/crack round (the meter arrow is the line, shown only after the pin's `FadeOutSeconds` fade so they never overlap); while GeodeStand, Shop or SellShop is open (the spotlight shows the button), or the hint's own panel; while the `TutorialComplete` banner is open; and while a normal notification is showing (`NotificationController.Notified`, ~3.25 s).
- `NotificationController.Notify` drops normal notifications while the tutorial runs and while the completion banner is open. This removed "Stone unlocked!", "Bought a Forest Geode!" and "Crack it at your base!" (and admin notices) during the tutorial, and "Silver Aura unlocked!" during the banner.
- The banner shows "Tutorial complete!" then "Free 2x Strength!" one after the other (`CompleteSeconds` 3.5, swap halfway); Reward sits where Title is.
- `RockHintService` no longer sends "Boulder unlocked!" (StatsService already does).
- Claude's playtest 2026-10-27, logged every 0.1 s: one line throughout the tutorial except a 0.4 s overlap at chop start (fixed afterwards, not re-run) and the aura notice during the banner (fixed afterwards, not re-run). Idle "Click here!" fired after 20 s. The user took over testing after that.
- Other text seen on screen during the tutorial (not changed; the user's call): the "#1 on 4 boards" crown title over your head (solo test only), pedestal "Locked"/"$1,000" labels, rock name + strength labels, prompt text ("E / Training Board / Train"), "Geode first!" lock labels, the "Stand"/"Pit" target labels, the leaderboard boards, the paused 2x Strength boost pill, the full Geode Stand panel and the hatch reveal.

## Playtest fixes (2026-10-27, from the user's playtest)
Pass check.ps1; the user is testing.
- **Geode step waits for the rock:** if the Chop step's cash goal is reached mid-rock, the client keeps showing the Chop step (line, meter arrow, sound) until the chop minigame ends (`ChopEnded` when the rock breaks). The server only gates starting a chop, so finishing the rock is allowed.
- **One collect line:** the Collect title is "Step on green pad!" and it has no detail line (the user said the two lines said the same thing).
- **Floor arrows to pads:** arrows used to stop `ChevronStopDistance` (9) studs short of every target, so the short pit-to-pad walk showed almost none. Pad targets (earnings pads, shop pads) now carry `StopStuds = PadStopStuds` (1) and `Guide.DrawPath` takes it.
- **Shops close on the next step:** the aura hint's `CloseStages` closes the Shop when it reaches Train (buying the aura), so the Base spotlight isn't under the open shop. The core tutorial closes GeodeStand when BuyGeode is done.
- **Camera turns to walk targets** (user: little kids don't rotate the camera): `TutorialController/CameraTurn` eases the Custom camera's yaw around `camera.Focus` over `CameraTurnSeconds` (0.5), bound at `RenderPriority.Camera + 1`. It fires once each time a walk target appears (new target, or a jump of more than `CameraTurnJumpStuds` (20) such as a teleport), only while the player has to walk (target not near, no teleport hint, not chopping or training). It runs in the core tutorial and every hint. Not checked in Play.
- **No turn when a teleport would help** (user, 2026-10-27): the turn is skipped while `Teleports.IsWorthUsing(destination, target)` is true, i.e. the step's teleport would save at least `CameraTurnTeleportShare` (0.5) of `TeleportSavingStuds` (20 studs), or the player is outside the zone for Rocks. This also covers the moments the teleport hint flickers off. After landing, the turn to the walk target still happens.

