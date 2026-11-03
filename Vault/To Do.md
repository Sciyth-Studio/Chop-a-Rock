---
description: Running task list for Chop a Rock — what's next, what's waiting on the user, what's deferred. Claude keeps it current.
type: project
updated: 2026-10-29
---
# To Do

Phases live in `ROADMAP.md`; this is the task-level list. Claude ticks items off (deletes them) when they're done and verified in code, and adds new ones as the user approves work. Only list things that matter now; see [[Only Surface Blocking Opens]]. Pre-launch work from Hud's Guide lives in [[Launch Checklist]]; move an item here once the user picks it up.

## Next
- [ ] Zone geodes, enemies and the new base (approved 2026-11-03, not built): `ZoneGeodesPlan.md`, see [[Zone Geodes And Enemies]]. Next: commit the 2026-11-03 work on `master`, then the Balance Model pass
- [ ] Tutorial + hints (2026-10-27, in playtest by the user): 5-step tutorial, aura, Boulder and rebirth hints, 4-word text, one line on screen, head start, idle highlight, completion banner, camera turns to walk targets, Starter Offer after the Boulder hint. See [[Tutorial]]
- [ ] Finish world 1: Swamp, Savanna, Bamboo Forest, Volcano, Golem Ruins + the Golem boss (added 2026-10-28, planned and approved 2026-10-29 in `World1Plan.md`, see [[World 1 Plan]]). Floor, terrace, entrance sign and spawn area blockouts for all five done 2026-10-29 ([[Zone Line]]); no rocks, Pets, geodes, decor or config yet. Decor for zones 6-10 built, recoloured against the floors and scattered on terraces and floors 2026-10-29 ([[Decor Lineups]], [[Meshlab]], [[Zone Line]]); the boss arena has none. Rocks for zones 6-10 built, uploaded, templated and configured 2026-10-31 ([[World 1 Rocks]]): RockConfig, AssetRegistry, Index Rocks pages, RockSpawnConfig; not playtested, no Index icons yet
- [ ] Kid-friendly pass (built 2026-10-29, not playtested; idea came from talking to a 6-year-old, not a playtest): phone-only easier chop timing (touch: zones x2.5, line 2.0 s; PC/controller unchanged; payouts unchanged), left click to chop (tutorial says "Click"), short notifications with an icon, a free first Master Chop 2-4 min after the tutorial, and a Huge Shroomy from the tutorial geode. Ground arrows skipped (the tutorial already has chevrons and teleport spotlights). See [[Kid Friendly Pass]]
- [ ] Wild Geodes (built 2026-10-29, not playtested): after 4-6 min of chopping, the next rock you break had a geode hidden in it and opens straight into the hatch reveal; luck from the breaking chop, Uncommon or better, no tell. Timer and floor are drafts. See [[Wild Geode]]
- [ ] Stepped hatch reveal (added 2026-10-31, not planned yet): the geode cracks showing a lower rarity's colours, shudders, then steps up to the real rarity, sometimes more than once, like slot reels stopping one by one. The Pet is rolled before the reveal starts, so it's presentation only, and only real wins get the bigger build-up (no fake near misses). Builds on the reveal's grow-by-rarity ([[Hatch Reveal Reference]]). Propose the steps and timing per rarity before building

- [ ] Notes and tester feedback, 2026-11-03. Code done, passes check.ps1, not playtested: rebirth stops training, Geode Fall count = players capped at 4 with one notification per geode, Geode Fall and Diamond Rock pills removed, all 8 pedestals free (old saves migrated), rebirth luck removed, minigame hitbox no longer offset by the top inset.
  - Second playtest notes done in code 2026-11-03, passes check.ps1, not playtested: chop input delay 0.1 s (draft, was 0.3), "N" removed from strength, landing notifications name the zone, Rush Rocks replaced by [[Golden Rocks]]. Base and income redesign moved to its own session
  - New asks: anime-style chop slashes in the player's aura colour; explain Board Slice for young kids; aura reminders
  - Studio, once the place is open: change the Cannon Shop subtitle "Buy once. Fire forever."; delete `StarterGui.GeodeFallPill` and `DiamondRockPill`; remove `LuckBefore` and `LuckAfter` from the Rebirth panel; square the chop meter bar's corners; move the rock health bar left of the chop animation in the same style, getting more cracked as health drops; make the Free Gift pad's yellow border more visible (user wrote "lower the transparency"); starter pack and 2x power/strength rework, 2x icons scale with hover; redo the right-side UI
  - Map: scale up zone-side decor and add taller grass-coloured walls on top of the terraces
  - Rebirth every rock built 2026-11-03, drafts in [[Rebirth Gated By Strength]]; the Balance Model needs a new version
  - Needs the user's decision: Brick price and rate (the slow early game), geode Pet income, full list of milestone hints (new aura, new training, rebirth time, new geode, training upgrade in the tutorial), skipping the geode cutscene
  - Tester's suggestion: watch someone new play the first few minutes without helping

## Waiting on the user
- Zone geodes, Robux side: confirm the skip-wait dev product (9 R$); take "Gift: Auto Open" (3722325313) off sale; drop "Auto Open" from the VIP pass description. See [[Zone Geodes And Enemies]]

## Deferred until the user raises it
- Ascended Chop (1 in 1,000)
- Board Slice minigame polish and later training games (Board Slice saved 2026-10-21; user may improve it later, see [[Training Minigame Board Slice]])
- Pet upgrades (user 2026-10-22: "the idea is good but i think i should save it for an update"; no plan file yet). Compared 2026-10-22: A) Golden fusion, 5 of the same Pet → Golden x3 $/s, Rainbow later; already in the Master Game Plan's Collection section, uses duplicates, Golden Index tab, no hatch-and-sell loop below x5. B) Feed Pets for XP, Lv 1-10, +20% each. C) Cash Upgrade sign per pedestal, Lv 1-5, +50% each, a direct money sink. Claude recommended A. The user wants a Robux shortcut; where it happens (Pets panel or lobby stand) is undecided. Any of them lifts pets from ~15% to ~35% of Snow income at max, so re-tune in the [[Balance Model]] first. When picked up, write `PetUpgradeSystemPlan.md`
- Admin panel next ideas (not approved; "later", 2026-10-22): target picker so commands act on other players, inspect a player, kick/ban, server announcement, admin action log. See [[Admin Panel]]
