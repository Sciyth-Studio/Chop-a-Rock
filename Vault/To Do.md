---
description: Running task list for Chop a Rock — what's next, what's waiting on the user, what's deferred. Claude keeps it current.
type: project
updated: 2026-10-28
---
# To Do

Phases live in `ROADMAP.md`; this is the task-level list. Claude ticks items off (deletes them) when they're done and verified in code, and adds new ones as the user approves work. Only list things that matter now; see [[Only Surface Blocking Opens]]. Pre-launch work from Hud's Guide lives in [[Launch Checklist]]; move an item here once the user picks it up.

## Next
- [ ] Tutorial + hints (2026-10-27, in playtest by the user): 5-step tutorial, aura, Boulder and rebirth hints, 4-word text, one line on screen, head start, idle highlight, completion banner, camera turns to walk targets, Starter Offer after the Boulder hint. See [[Tutorial]]
- [ ] Finish world 1: 5 more zones + a final Golem boss (added 2026-10-28, not started; replaces the base floors and post-Snow training stands items). Zone themes, the boss fight and the reward aren't decided yet. See the `new-zone` skill, [[Rebirth Gated By Strength]], [[Bases]]
- [ ] Finish the auto-open geodes game pass (added 2026-10-24, user asked to finish it 2026-10-28): a gamepass that keeps cracking geodes for you, each auto-open rolling a random hit quality. Plan approved 2026-10-24 in `AutoOpenGeodePlan.md` ([[Auto Open At The Pit]]): only at your own pit, cracks only geodes you own, uses the model's quality mix, no auto-sell, 199 R$ game pass. Already decided: it cracks through the same `Release` so pity works ([[Balance Pass Oct 18]], `GeodePitySystemPlan.md`), and sell value was cut to 60 s so it can't print cash ([[Sell Shop]])
- [ ] Finish the toolbar (added 2026-10-24, user asked to finish it 2026-10-28): what to change isn't decided yet
- [ ] Rok size variations (added 2026-10-28, not started): 5 size tiers by rarity, from Normal and Large up to Enormous; the middle tier names, odds and what size changes (looks only, or $/s too) aren't decided yet
- [ ] Remove the strength requirement to open geodes (added 2026-10-28, not started). See [[Geode Shop]]

- [ ] Make the game 6-year-old friendly (added 2026-10-28, proposed, not approved): the user found kindergarteners need it (they play steal-an-egg games). 1) Easier chop timing: at low strength the Perfect window is ~70 ms and Bad pays 0.15x. Proposed `ZoneWidthMultiplier` 1.5 → 2.5, `CycleSeconds` 1.5 → 2.0, Bad payout 0.15 → 0.4, Mid 0.5 → 0.7 (`ChopConfig.luau`). 2) Shorter notifications: at most ~4 words, with an icon and a number in place of sentences (e.g. "Backpack full! Sell some Roks or you won't get this one", "Falling Geodes in the %s %d/%d left %d:%02d"). 3) Ground arrow or beam to each tutorial target; check what the tutorial's camera turn already covers first ([[Tutorial]]). Big money numbers stay ([[Big Numbers Over Small Ones]]). Still need what the kids actually struggled with, and which changes the user approves

## Waiting on the user
- [ ] Save the place in Studio (2026-10-27): Rok icon swap, collect pad restyle, shop rail, VIP base, Champ and Kingy models, Kingy's aura template, `StarterGui.TutorialComplete` banner, `StarterGui.FreeGift` and `Workspace.FreeGift` (2026-10-28)

## Deferred until the user raises it
- Ascended Chop (1 in 1,000)
- Board Slice minigame polish and later training games (Board Slice saved 2026-10-21; user may improve it later, see [[Training Minigame Board Slice]])
- Rok upgrades (user 2026-10-22: "the idea is good but i think i should save it for an update"; no plan file yet). Compared 2026-10-22: A) Golden fusion, 5 of the same Rok → Golden x3 $/s, Rainbow later; already in the Master Game Plan's Collection section, uses duplicates, Golden Index tab, no hatch-and-sell loop below x5. B) Feed Roks for XP, Lv 1-10, +20% each. C) Cash Upgrade sign per pedestal, Lv 1-5, +50% each, a direct money sink. Claude recommended A. The user wants a Robux shortcut; where it happens (Roks panel or lobby stand) is undecided. Any of them lifts pets from ~15% to ~35% of Snow income at max, so re-tune in the [[Balance Model]] first. When picked up, write `RokUpgradeSystemPlan.md`
- Admin panel next ideas (not approved; "later", 2026-10-22): target picker so commands act on other players, inspect a player, kick/ban, server announcement, admin action log. See [[Admin Panel]]
