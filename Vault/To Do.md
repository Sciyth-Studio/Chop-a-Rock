---
description: Running task list for Chop a Rock — what's next, what's waiting on the user, what's deferred. Claude keeps it current.
type: project
updated: 2026-10-22
---
# To Do

Phases live in `ROADMAP.md`; this is the task-level list. Claude ticks items off (deletes them) when they're done and verified in code, and adds new ones as the user approves work. Only list things that matter now; see [[Only Surface Blocking Opens]].

## Next
- [ ] Robux shop (added 2026-10-22, not started): one fully finished shop for everything sold for Robux, with every item wired to a real dev product. It should be more enticing than the rest of the UI (bigger, brighter, more motion than the standard menu panels)
- [ ] Expanded monetization + starter pack (added 2026-10-22, not started): more things to buy with Robux, plus a one-time starter pack offer for new players
- [ ] Tracking funnels (added 2026-10-22, not started): analytics funnels for the player journey (e.g. tutorial steps, first geode, first rebirth, shop opens to purchases)
- [ ] Intro cutscene (added 2026-10-22, not started): a short cutscene for first-time players before the tutorial
- [ ] Base floors (added 2026-10-22, not started): extra floors on player bases (more pedestal room as you progress). How floors unlock and what they cost isn't decided yet. See [[Bases]], [[Pedestals]]
- [ ] Training stands for zones after Snow (not started as of 2026-10-22); tiers and strength-gated rebirth are done, see [[Rebirth Gated By Strength]]
- [ ] Leaderboard extras (liked 2026-10-21): weekly reset tab, crown/title over #1, "You passed X!" toast. Built 2026-10-22 from `LeaderboardExtrasPlan.md`, not playtested; crown modelled and in Studio 2026-10-22 (see [[Leaderboards]])

## Waiting on the user
- [ ] Item icons: all 45 icons (every zone's Roks and rocks) are uploaded and live in the Index and Geode Stand (2026-10-24, [[Item Icons]]). The zone rocks got realistic colours the same day. The user still needs to save the place (new `Icon` slots and the rock recolour)

## Deferred until the user raises it
- Ascended Chop (1 in 1,000)
- Board Slice minigame polish and later training games (Board Slice saved 2026-10-21; user may improve it later, see [[Training Minigame Board Slice]])
- Rok upgrades (user 2026-10-22: "the idea is good but i think i should save it for an update"; no plan file yet). Compared 2026-10-22: A) Golden fusion, 5 of the same Rok → Golden x3 $/s, Rainbow later; already in the Master Game Plan's Collection section, uses duplicates, Golden Index tab, no hatch-and-sell loop below x5. B) Feed Roks for XP, Lv 1-10, +20% each. C) Cash Upgrade sign per pedestal, Lv 1-5, +50% each, a direct money sink. Claude recommended A. The user wants a Robux shortcut; where it happens (Roks panel or lobby stand) is undecided. Any of them lifts pets from ~15% to ~35% of Snow income at max, so re-tune in the [[Balance Model]] first. When picked up, write `RokUpgradeSystemPlan.md`
- Admin panel next ideas (not approved; "later", 2026-10-22): target picker so commands act on other players, inspect a player, kick/ban, server announcement, admin action log. See [[Admin Panel]]
