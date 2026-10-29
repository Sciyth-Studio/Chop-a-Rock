---
description: Auto Open game pass (built 2026-10-28) - a third pit prompt starts hands-off cracking of owned geodes with a rolled hit quality through Cracking.Finish; stop pill, range/out-of-geodes/bag-full stops; GeodeService/AutoOpen, AutoOpenConfig, Screens/AutoOpenButton.
type: system
---
# Auto Open

Built 2026-10-28 from `AutoOpenGeodePlan.md` (decisions in [[Auto Open At The Pit]]). Game pass 2053686145, 199 R$ (`MonetizationConfig.Passes`, key `AutoOpen`; VIP includes it). Ownership comes from `PassService:Owns`, like every pass.

- **Prompt:** `AutoPrompt` on a `GeodeAutoSpot` attachment `AutoOpenConfig.PromptOffset` (0, 6, 0) above `GeodeSpot`, so it stacks above the Crack and Choose Geode prompts instead of overlapping them. Key R / ButtonL1 (draft; F was taken by Choose Geode). Owned: "Auto Open", same hold as Crack. Not owned: "Auto Open (R$ 199)", no hold, and `Screens/AutoOpenButton` calls `PurchaseController:PromptPass("AutoOpen")`. Hidden while cracking or auto-opening, with no geodes, and during the tutorial.
- **Loop (server, `GeodeService/init`):** `autoCounts[player]` marks a running player. Each step calls `AutoOpen.Next` (checks: pass, tutorial, no rock chop, in range, a geode to crack, Backpack room), then `Cracking.Begin(..., isAuto = true)` (no `ChopMinigameStart`, so no chop camera), waits `StartDelaySeconds` (0.3), then `Cracking.Finish` with `AutoOpen.RollQuality` (5/15/40/25/15 Bad to Perfect, no Master). The next step starts when the pit lock (`releaseLock`, shared with manual cracks) ends.
- **Same crack as by hand:** `Cracking.Release` now does only the timing half (quality, Master roll, `RecordChop`) and calls `Cracking.Finish`. Pity, weather modifiers, Index, Auto Equip, Secret announcements and admin Next Hatch all run unchanged. Perfect Chops aren't counted for auto cracks.
- **Stops:** Stop button (`StopAutoOpen` packet), more than `RangeStuds` (14) from the pit (checked every 0.5 s on the server), out of geodes ("All geodes opened!"), Backpack full ("Bag full! Sell some Roks"), `GeodeService:EndSession` (teleports), plot released, leaving. The reveal already playing finishes. Auto sessions ignore `ChopRelease` and `ChopLeave` from the client.
- **No "too weak" stop:** the strength gate on geodes was removed in parallel (branch `claude/ecstatic-burnell-7f4781`), so auto-open never reads `CanBreak`.
- **Client:** `StarterGui.AutoOpenButton` (Studio): `Container` 460x60 bottom centre (copy of the `GeodeFallPill` pill) with `Label`/`LabelShadow` "Auto Open · N opened" and a red block `Stop` button (copy of the GeodePicker buy button, painted with `BlockButton.Paint`). Shown while the `AutoOpening` player attribute is set; the count is `AutoOpenCount`.
- **Admin:** "Toggle Fake Pass (Studio)" with `AutoOpen` (and `VIP`, which includes it) tests the no-pass path.
- **Playtested 2026-10-28** (worktree scripts pushed into Studio, then restored): 30+ auto cracks chained about 4-6 s apart with the reveal each time, count and pill updated; Stop button (real click), walking 32 studs away, Backpack full, and running out (17 opened then "All geodes opened!") all stopped it; without the pass the prompt read "Auto Open (R$ 199)" with no hold and started nothing; 10,000 rolls gave 5.1/15.0/40.8/24.0/15.1. The three pit prompts showed on separate attachments. Checked by value, not on screen: the Robux purchase dialog, the pill's look, and the prompt stack's look.
- Not built from the plan: a strike animation for auto cracks (the pit hit effect and reveal play); the balance model v10 "Auto-open" row; the Master Game Plan §10 line.

Related: [[Geode Shop]], [[Auto Open At The Pit]], [[Balance Pass Oct 18]]
