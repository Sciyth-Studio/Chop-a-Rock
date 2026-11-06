---
description: 2026-11-05 audit of the Robux code against the LihFolk monetization checklist; Skip Hatch pauses the hatch timer while the Robux dialog is open, the Index shows odds at the player's real luck, and the luck cards' Details show Rare-or-better odds before ▶ after. Not playtested.
type: system
updated: 2026-11-05
---
# Monetization compliance

Audit on 2026-11-05 against the [[LihFolk Vault]] `roblox-monetization-compliance` skill. Receipts, pass caching and fail-closed PolicyService were already right.

## Fixed 2026-11-05 (not playtested)
- **Skip Hatch pauses the timer (user's call).** A Skip Hatch receipt used to stay pending forever if the egg finished while the Robux dialog was open, because `GeodeService:SkipHatch` found nothing to skip. Now `GeodeService` pauses that pad when it prompts. The pad's `PausedSeconds` attribute freezes the countdown in `HatchPadInfo`. If the player cancels (`PromptProductPurchaseFinished`, not purchased), `ReadyAt` moves later by the time paused. If they buy, the pause stays until the receipt's `SkipHatch` clears it. If they leave while paused, `PlayerReleasing` shifts `ReadyAt` in the saved data.
- **Boost buys past the cap are refused** (tested in Play). Personal boosts stop at 6 h and server boosts at 2 h. Buying more used to take the Robux and cut the extra time off; now the client refuses the buy with a "Boost time is full" notice. See [[Boosts Lead Into Passes]].
- Left open: if a purchase goes through but the receipt only arrives on a later visit, the egg has usually finished by then and the receipt still can't grant.
- **Luck is published as the `HatchLuck` player attribute** (`LuckConfig.LuckAttribute`, the same `Luck.Total` the server rolls with), refreshed every `HatchRefreshSeconds`. The Index "1 in N" uses it and updates live.
- **Luck cards show numbers.** Details on 2x Luck, VIP (its Details button is now shown) and Server 2x Luck sends a second notice: `RobuxShopConfig.Texts.LuckOdds`, "Rare or better from Forest eggs: x% ▶ y%", for the zone the player's Best Strength reaches. The wording is a draft.

## Things to know
- **Luck doesn't change Lucky Egg odds.** Lucky Eggs are Rare or better, luck scales every Rare+ Pet equally, and `HatchOdds.Chances` renormalises it away. Only the size roll uses luck. The "2x Luck" blurb ("on every egg you hatch") overstates this for Lucky Eggs.
- **Still open from the audit:** restricted players can buy the Luck pass, VIP and Server Luck. The Lucky Egg block is client-only. Lucky Eggs' mutation, trait and size rolls have no odds shown. PolicyService is checked once with no retry. A gift can be given twice after a crash. King Rex stock can oversell across servers.

Related: [[Robux Shop Plan Approved]], [[Monetization References]], [[Geode Shop]]
