---
description: Running task list for Chop a Rock — what's next, what's waiting on the user, what's deferred. Claude keeps it current.
type: project
updated: 2026-10-28
---
# To Do

Phases live in `ROADMAP.md`; this is the task-level list. Claude ticks items off (deletes them) when they're done and verified in code, and adds new ones as the user approves work. Only list things that matter now; see [[Only Surface Blocking Opens]]. Pre-launch work from Hud's Guide lives in [[Launch Checklist]]; move an item here once the user picks it up.

## Next
- [ ] Tutorial + hints (2026-10-27, in playtest by the user): 5-step tutorial, aura, Boulder and rebirth hints, 4-word text, one line on screen, head start, idle highlight, completion banner, camera turns to walk targets, Starter Offer after the Boulder hint. See [[Tutorial]]
- [ ] Finish world 1: Swamp, Savanna, Bamboo Forest, Volcano, Golem Ruins + the Golem boss (added 2026-10-28, planned and approved 2026-10-29 in `World1Plan.md`, see [[World 1 Plan]]; not built). Next: reference sheets and models, Swamp first
- [ ] Finish the toolbar (added 2026-10-24): built 2026-10-29 from the user's reference (custom 7-slot Rok hotbar, Roks button on it, searchable stacked-card Roks panel, house menu style, white size tags) on branch `claude/frosty-goldberg-1004c7`, checked in Play. Left: merge into master; check the hotbar hides during geode cracks and the intro

## Waiting on the user
- [ ] Make the game 6-year-old friendly (added 2026-10-28, proposed, not approved; the user picks it up when home, 2026-10-29): the user found kindergarteners need it (they play steal-an-egg games). 1) Easier chop timing: at low strength the Perfect window is ~70 ms and Bad pays 0.15x. Proposed `ZoneWidthMultiplier` 1.5 → 2.5, `CycleSeconds` 1.5 → 2.0, Bad payout 0.15 → 0.4, Mid 0.5 → 0.7 (`ChopConfig.luau`). 2) Shorter notifications: at most ~4 words, with an icon and a number in place of sentences (e.g. "Backpack full! Sell some Roks or you won't get this one", "Falling Geodes in the %s %d/%d left %d:%02d"). 3) Ground arrow or beam to each tutorial target; check what the tutorial's camera turn already covers first ([[Tutorial]]). 4) Click to chop (user, 2026-10-29): add left click (MouseButton1) to the strike binding in `ChopController` (now E / Space / ButtonR2 / touch button), ignoring clicks that land on UI. Big money numbers stay ([[Big Numbers Over Small Ones]]). Still need what the kids actually struggled with, and which changes the user approves
- [ ] Save the place in Studio (2026-10-27): Rok icon swap, collect pad restyle, shop rail, VIP base, Champ and Kingy models, Kingy's aura template, `StarterGui.TutorialComplete` banner, `StarterGui.FreeGift` and `Workspace.FreeGift`, the Rok size labels (`HatchReveal` and `SellShop` `SizeLabel`) (2026-10-28)

## Deferred until the user raises it
- Ascended Chop (1 in 1,000)
- Board Slice minigame polish and later training games (Board Slice saved 2026-10-21; user may improve it later, see [[Training Minigame Board Slice]])
- Rok upgrades (user 2026-10-22: "the idea is good but i think i should save it for an update"; no plan file yet). Compared 2026-10-22: A) Golden fusion, 5 of the same Rok → Golden x3 $/s, Rainbow later; already in the Master Game Plan's Collection section, uses duplicates, Golden Index tab, no hatch-and-sell loop below x5. B) Feed Roks for XP, Lv 1-10, +20% each. C) Cash Upgrade sign per pedestal, Lv 1-5, +50% each, a direct money sink. Claude recommended A. The user wants a Robux shortcut; where it happens (Roks panel or lobby stand) is undecided. Any of them lifts pets from ~15% to ~35% of Snow income at max, so re-tune in the [[Balance Model]] first. When picked up, write `RokUpgradeSystemPlan.md`
- Admin panel next ideas (not approved; "later", 2026-10-22): target picker so commands act on other players, inspect a player, kick/ban, server announcement, admin action log. See [[Admin Panel]]
