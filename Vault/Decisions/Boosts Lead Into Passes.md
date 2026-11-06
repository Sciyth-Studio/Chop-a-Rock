---
description: 2026-11-05 user call — timed boosts are a funnel into the permanent 2x passes; the rail shows only x2 Strength and only while training, no x2 Cash rail button, the run-out card pitches the pass, and boost buys that would pass the cap are refused
type: decision
updated: 2026-11-05
---
# Boosts lead into passes

User, 2026-11-05: "the plan was to have timed boosts lead into full gamepass purchase". They also asked for the 2x Strength rail button to show only while training and for 2x Cash to have no rail button.

How it works now:
- **Funnel:** the free 5 min 2x Strength after the tutorial only counts down while training, so it runs out partway through a session. The run-out card (`OfferRail`, `BoostEnded`) then says "2x Strength ran out! Get it forever?", with **Forever (pass price)** as the main button and **15 min** as the second. Players who own the pass (or VIP) get the old "Keep it going?" card with 15 min and 1 hour. The card shows once per boost per session.
- **Rail:** boosts with `IsOnRail = true` in `MonetizationConfig.Boosts` get a rail button (only Strength). The others' rail parts (`<Key>Button*` in `OfferRail.Container.Boosts`) are hidden and the frame shrinks to the top of them. `OnlyWhileTraining` boosts show only while `TrainingController:IsTraining()`, checked once a second. 2x Cash is still sold in the Robux Shop and can be gifted.
- **Cap:** `PurchaseController:PromptBoost` and `PromptServerBoost` refuse a buy that would go over `BoostCapSeconds` (6 h) or `ServerBoostCapSeconds` (2 h) and show `BoostFullText`. Before this, the server cut the extra time off but still took the Robux. `BoostService` still clamps as a backstop. Gifts aren't checked against the recipient's cap.
- Pass owners can still buy boosts: the pass and the boost add together (3x).

Tested in Play 2026-11-05: the rail is hidden when not training and shows only Strength while training; over-cap buys are refused. The run-out card wasn't seen on screen (it needs 15 min of training).

Watch: with no rail button, 2x Cash loses its cheap first buy. If 2x Cash pass sales are weak, bring the button back for players who don't own the pass.

Related: [[Robux Shop Plan Approved]], [[Monetization Compliance]], [[Monetization References]]
