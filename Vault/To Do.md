---
description: Running task list for Chop a Rock — what's next, what's waiting on the user, what's deferred. Claude keeps it current.
type: project
updated: 2026-10-28
---
# To Do

Phases live in `ROADMAP.md`; this is the task-level list. Claude ticks items off (deletes them) when they're done and verified in code, and adds new ones as the user approves work. Only list things that matter now; see [[Only Surface Blocking Opens]]. Pre-launch work from Hud's Guide lives in [[Launch Checklist]]; move an item here once the user picks it up.

## Next
- [ ] Robux shop + expanded monetization + starter pack (added 2026-10-22, in progress, plan approved 2026-10-24 in `RobuxShopPlan.md`, see [[Robux Shop Plan Approved]]): shop screen, starter offer, boosts, Lucky Geodes, gifting, VIP (chat tag, gold name, gold base), exclusive Kingy stand and the 6 game passes on Roblox are built. The user looked at the VIP base and the exclusive stand on 2026-10-27 and both are fine. Gifting and shop motion still haven't been playtested
- [ ] Champ and Kingy Roks (added 2026-10-25, in progress): models and icons made, exclusive income and modifier fixes tested in Play. Kingy has a gold aura and earns 3x your best Rok's base $/s with no modifiers (2026-10-27)
- [ ] Tracking funnels (added 2026-10-22, in progress): the onboarding funnel now runs 13 steps past the tutorial to 60 min played (2026-10-27, see [[Tutorial]]). Economy events and the Robux shop funnel built 2026-10-27 ([[Analytics]]). Left: check both in Creator Hub after a live session ([[Launch Checklist]] §2)
- [ ] Tutorial + hints (2026-10-27, in playtest by the user): 5-step tutorial, aura, Boulder and rebirth hints, 4-word text, one line on screen, head start, idle highlight, completion banner, camera turns to walk targets, Starter Offer after the Boulder hint. See [[Tutorial]]
- [x] Intro cutscene (added 2026-10-22, built 2026-10-27, signed off by the user 2026-10-28 after a round of feedback): 22.6 s wordless Tom & Jerry style "The Master" story before the tutorial, animations made by Claude, music cues picked by the user. See [[Intro Cutscene]]
- [ ] Base floors (added 2026-10-22, not started): extra floors on player bases (more pedestal room as you progress). How floors unlock and what they cost isn't decided yet. See [[Bases]], [[Pedestals]]
- [ ] Training stands for zones after Snow (not started as of 2026-10-22); tiers and strength-gated rebirth are done, see [[Rebirth Gated By Strength]]
- [ ] Finish the auto-open geodes game pass (added 2026-10-24, user asked to finish it 2026-10-28): a gamepass that keeps cracking geodes for you, each auto-open rolling a random hit quality. Plan approved 2026-10-24 in `AutoOpenGeodePlan.md` ([[Auto Open At The Pit]]): only at your own pit, cracks only geodes you own, uses the model's quality mix, no auto-sell, 199 R$ game pass. Already decided: it cracks through the same `Release` so pity works ([[Balance Pass Oct 18]], `GeodePitySystemPlan.md`), and sell value was cut to 60 s so it can't print cash ([[Sell Shop]])
- [ ] Finish the toolbar (added 2026-10-24, user asked to finish it 2026-10-28): what to change isn't decided yet
- [ ] Rok size variations (added 2026-10-28, not started): 5 size tiers by rarity, from Normal and Large up to Enormous; the middle tier names, odds and what size changes (looks only, or $/s too) aren't decided yet
- [ ] Remove the strength requirement to open geodes (added 2026-10-28, not started). See [[Geode Shop]]

## Waiting on the user
- [ ] Save the place in Studio (2026-10-27): Rok icon swap, collect pad restyle, shop rail, VIP base, Champ and Kingy models, Kingy's aura template, `StarterGui.TutorialComplete` banner, `StarterGui.FreeGift` and `Workspace.FreeGift` (2026-10-28)

## Deferred until the user raises it
- Ascended Chop (1 in 1,000)
- Board Slice minigame polish and later training games (Board Slice saved 2026-10-21; user may improve it later, see [[Training Minigame Board Slice]])
- Rok upgrades (user 2026-10-22: "the idea is good but i think i should save it for an update"; no plan file yet). Compared 2026-10-22: A) Golden fusion, 5 of the same Rok → Golden x3 $/s, Rainbow later; already in the Master Game Plan's Collection section, uses duplicates, Golden Index tab, no hatch-and-sell loop below x5. B) Feed Roks for XP, Lv 1-10, +20% each. C) Cash Upgrade sign per pedestal, Lv 1-5, +50% each, a direct money sink. Claude recommended A. The user wants a Robux shortcut; where it happens (Roks panel or lobby stand) is undecided. Any of them lifts pets from ~15% to ~35% of Snow income at max, so re-tune in the [[Balance Model]] first. When picked up, write `RokUpgradeSystemPlan.md`
- Admin panel next ideas (not approved; "later", 2026-10-22): target picker so commands act on other players, inspect a player, kick/ban, server announcement, admin action log. See [[Admin Panel]]
