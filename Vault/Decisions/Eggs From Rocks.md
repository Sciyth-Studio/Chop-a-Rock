---
description: 2026-11-06 - new core loop approved in direction - eggs fly out of broken rocks as black eggs, shuffle type (rare egg ~1 in 5) and luck (x1-x3) weighted by chop skill, grabbing one starts an enemy fight played on the chop bar; lose = 1 free retry per 24 h then a Retry developer product; still carried home to hatch pads. Plan in NewLoopPlan.md, not built.
type: decision
---
# Eggs from rocks (2026-11-06)

Plan: `NewLoopPlan.md` (v3). Not built. Numbers are drafts until the [[Balance Model]] pass.

**Why:** outside testers on 2026-11-05 said rocks and eggs were two unconnected loops ([[Playtest Feedback Nov 5]]). A third tester (scándi) said picking up a loose egg "did not make that much sense" and suggested the black shuffling egg and a fight.

## The user's calls
- Loop: train, break rock, egg flies out black, shuffles type and luck multiplier, grab it, fight the zone enemy, carry it home, hatch it on a pad, Pets earn, get stronger.
- The fight uses the **chop timing bar**, not spam clicking: one minigame is easier for ages 6-12, adds time pressure, and timing fights haven't been done. No running away, so no speed training; Strength stays the only trained stat.
- **Chop skill shifts the shuffle's odds** (type and luck).
- The luck number **counts up through the hundredths** (x1.00, x1.01, ...) and lands on a value like x1.73, not fixed tiers (user, 2026-11-06).
- The zone's second egg look is the **rare egg**, about **1 in 5**, with better odds.
- **Rock cash** changes only after the Balance Model.
- **Losing a fight:** 1 free retry per 24 h, then retries are a developer product. Without a retry the egg is gone.
- Eggs are **still carried home** to hatch pads.

Replaces the free zone eggs and spam-click combat of [[Zone Geodes And Enemies]]. Enemies, Geode Fall, Lucky Eggs, the Starter Egg and pads stay.

## Build status (2026-11-06)
Built, passes check.ps1, **not playtested** (user: don't test). Not committed.
- Rocks: `RockService/Session.RecordSkill` averages `EggDropConfig.SkillByQuality` per chop; `RockBroken` now fires `(player, Types.Broken)` with Skill, HadMaster, IsGolden, Ground, Origin.
- Drops: `ZoneGeodeService` (folder now, `Roll.luau`) listens to `RockBroken`; no more ring spawns. Luck to the hundredth stored as hundredths (100 = x1.00), rare = the zone's second look. Max 4 on the ground, 120 s each. Tutorial eggs are the normal look at x2.00.
- Fight: `EnemyService` runs chop rounds (`EnemyChopStart`, then the shared `ChopRoundStart` / `ChopRelease` / `ChopResult` / `ChopEnded`); `EnemyController` hands the enemy's part to `ChopController:BeginExternal`. 6 hits in 12 s, Good 1 / Great 2 / Perfect 3, Master finishes; tutorial fight 2 hits, no timer, every chop counts as at least Good. `EnemyFight` screen keeps only the banner, countdown and result.
- Retry: `EggRetry` screen (Studio, cloned from Sell Shop) with Give Up / Retry; free retry every 24 h (`FreeRetryAt`), then `RetryCredits` from the "Retry Fight" product (`MonetizationConfig.RetryFight.ProductId` is empty until the user creates it, 9 R$ draft). Timer pauses while the Robux prompt is open.
- Luck: `PlayerData.EggLuck[key]` (sorted lists), pad `Luck`, opening multiplies `Luck.Total`; hotbar, Pets panel and pad label show "x1.73". Rare eggs get `rarePets` odds in `GeodeConfig` (Common/Uncommon x0.5, others x2) and the name prefix "Rare".
- Studio (save the place): `StarterGui.EggRetry`, `ChopBar.Bar.TimerText` + shadow.
- Not done: Diamond Rock egg, "Lucky x2" on the hatch reveal, Good-band spotlight in the tutorial fight, leftover click-combat fields in `EnemyConfig` and ring-spawn fields in `ZoneGeodeConfig`, Balance Model v14.

## Playtest round 1 (user, 2026-11-06): "it works", then these changes (built, checks pass, not retested)
- Luck rolls to **x10.00** (`LuckMaxHundredths` 1000) for hype; the hatch effect is remapped so balance is unchanged: `Utils/EggLuck.Effect` turns x1-x10 into x1-x3 (`EffectMaxMultiplier`). Master floor x5.50, Golden +x2.25, tutorial egg x5.50 (same effect as the old x2.00 / +0.5 / x2.00). Eggs saved before this read their old values on the new scale (test data only).
- **Egg size grows with luck** up to x1.8 at x10 (`MaxSizeScale`): ground eggs grow on landing, pad eggs (`Effects.ShowOnPad` scale), held eggs (tool rebuilt when the stack's best luck changes).
- **Held items at real size:** egg tools at scale 1 (was 0.5), Pet tools at 2 = the pen's `PetScale` (was 0.6), times Pet size.
- **White outline** (Highlight) on eggs on the ground, including during the count-up and on the other look while it flickers.
- **Egg label:** `UI_EggInfo` (Studio, `Assets.VFX.Pedestal.EggInfo`): clover + luck in Chrome. The Gold egg-name `Title` under it was removed 2026-11-09 (user: eggs have their own designs and pickup prompts); the rows moved up and the billboard is 3.98 tall instead of 5.6; old version in `UIBackup["EggInfo.BeforeTitleRemoval"]`. Picking an egg up no longer sends a "+1 <egg>" notification (zone eggs and Geode Fall eggs). The clover is a placeholder (`IconConfig.Luck`) until the user imports `Clover 2nd 256px.png` and gives the id (`EggDropConfig.LuckIcon`).
- **Rare egg** no longer says "Rare".
- **Ready to hatch:** green glow, white outline and a rock back and forth (`HatchPadInfo`, `GeodeConfig.ReadyGlow*` / `ReadyRock*`).
- **Fight:** the screen tints red and desaturates as the timer runs out (`EnemyConfig.DangerTint`). Guardian name labels 1.8x bigger, 6 studs above the head (user will check).
- **Eggs drop after the Master cinematic** (impact delay + strike hold), and after the slow-mo on normal breaks.
- **Retry** only works while standing in the egg's zone ("Go back to your egg's zone!"), so the guardian can't follow you out. Retry card header and buttons repainted with `BlockButton.Paint`.
- **Pen placement is manual** (see [[Pedestals]]).

- 2026-11-06: Retry Fight product created (3729033078, 9 R$) and the clover uploaded (90789156311854) through Open Cloud; the user pointed out Claude can do both itself. Hatch pad labels now use `UI_EggInfo` too (clover + luck, name, timer in the new `Detail` line).

## Round 2 (user, 2026-11-06), built, checks pass, not retested
- Hatched Pets carry `RevealAt` (server time when the reveal ends); the hotbar and Pets panel skip them until then (`PetStacks.NextReveal`), so the hotbar no longer spoils the hatch.
- Hatch pads are press-only (`HatchPromptHoldSeconds` 0); the pen prompts already were. Custom prompts also take a click.
- The tutorial fight is coached like the first chop (`Tutorial.IsCoachedFight`): Good-band spotlight, the arrow hint and "Click in glow!".
- Tutorial review fixes: GetGeode says "Press E to grab!" (was "take"); pads say "Press" not "Hold"; the guide no longer adds its own "Egg" label on top of the egg label; chopping is allowed in the GetGeode step and the guide points at a rock if no egg is out, and tutorial eggs never expire, so a lost egg can't strand a new player.
- Dropped eggs hide while you fight a guardian, so the egg no longer blocks the camera.

- 2026-11-06 (user: "first pet should be player placed and part of tutorial"): nothing auto-places any more. After the first hatch the new Pet is put in your hand (`PetService:Equip`, after the reveal), the Open step stays until a Pet is placed (`TutorialService.decide`), the title becomes "Place your Pet!", the guide points at the pen (label "Pen") and the text is "Press E to place!" (or "Click your Pet!" if it was put away). Final follows once it is in the pen. Step numbers unchanged, so saves and the funnel are unaffected; the funnel's Final step now also means "placed".

## Round 3 (user, 2026-11-06), built, checks pass, not retested
- **Into your hand:** a won egg is equipped right after the fight (`GeodeService:Equip`), and every hatched Pet is equipped when its reveal ends (`PedestalService` `handNewPet`, skipped while training or chopping).
- **Auto-place:** standing on your own plot with eggs fills every free pad (checked once a second in `GeodeService`, plot bounding box, luckiest egg first). The tutorial Place step now says "Take your egg home!" with no button text.
- **New Pet popup:** a hotbar-style card (cloned `SlotTemplate`, 150 px) pops up above the hotbar in `Toolbar.PopupRoot` (Studio) for each new Pet once its reveal ends, 2 s each, queued (`ToolbarConfig.Popup*`).
- **Pad label** follows the user's reference: `EggInfo` has a `TimerRow` (clock icon `IconConfig.Clock` + time) and a `Progress` bar; when ready the clock and bar hide and the text turns Green "Ready!". Pad prompts say "Hatch" and "Skip Timer".
- 2026-11-06 (user): while holding an egg (not during the tutorial) a red block "DROP" button (`StarterGui.EggDrop`, all caps allowed here) replaces the hotbar. Dropping puts the egg on the ground 4 studs ahead with its luck (`EggDropHeld` packet, `GeodeService:TakeOne`); grabbing a dropped egg gives it back with no fight (`IsFree`). Dropped eggs still roll away after 2 min.
