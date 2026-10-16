---
description: Running task list for Chop a Rock — what's next, what's waiting on the user, what's deferred. Claude keeps it current.
type: project
updated: 2026-10-16
---
# To Do

Phases live in `ROADMAP.md`; this is the task-level list. Claude ticks items off (deletes them) when they're done and verified in code, and adds new ones as the user approves work. Only list things that matter now; see [[Only Surface Blocking Opens]].

## Next
- [ ] Roks for zones 2-5 (started 2026-10-13): 24 Roks, lineups approved in the master plan §03 (desert) and [[Zones After Desert]] (jungle, ocean, snow). One zone at a time, desert first, `model-workflow` per Rok with Bloky's body and eyes ([[Reuse Rok Eyes]]). Desert done 2026-10-14 (models, `PetConfig`, Desert Geode, Index zone, Geode Shop tab; see [[Geode Shop]]). Next zones: models, then `PetConfig`, `GeodeConfig.Geodes.<Zone>` with `TabName` and `Order`, geode models and the Index Roks zone (`new-zone` step 6)
- [ ] Training tiers + strength-gated rebirth: built and checked in Play 2026-10-13 (see [[Rebirth Gated By Strength]]). Still to do: the user playtests the pacing and listens to the per-tier break sounds (added 2026-10-14, alternates in `ServerStorage.TrainingSoundOptions`); check on a phone that the Core and Cosmic VFX pixel squares show (VFX approved 2026-10-14); stands for zones after Snow. Not committed
- [ ] Zone rock models with props: the user watches a perfect break in each zone. The white snow props glow under bloom; tone them down if that bothers the user. See [[Zone Rocks Reference]]
- [ ] Training minigames (added 2026-10-15, not started): games to play at a training stand while strength goes up. The user is making a Fruit Ninja clone first (2026-10-16). Not planned yet
- [ ] Geode pity (added 2026-10-15, not started): a pity counter on geode hatches so a rare Rok is guaranteed after enough misses. Thresholds, which rarities count and whether it's per geode or shared aren't decided yet. Not planned yet
- [ ] Geode upgrades/levels (added 2026-10-15, not started): geodes level up or get upgraded. What a level changes and how you raise it aren't decided yet. Not planned yet

## Batch approved 2026-10-10
- [ ] User plays a Diamond with Hot Streak, an easy rock and the Teleport Bar on phone size (colours and 3 s cooldown are drafts)
- [ ] Robux shop contents (not planned yet; panel is an empty yellow `StarterGui.RobuxShop`)
- [ ] Unused Decal `113266790078316` (failed clover upload) can be deleted from the group
- [ ] Rock numbers compact from 1,000 up (2026-10-13, `NumberFormat.CompactRock`): user checks in Play. Chop cash pops still compact only from 1M; geode text, Index rewards, Roks and Sell Shop keep commas
- [ ] Master chop on the Diamond Rock rearmed the meter mid-cinematic: fixed 2026-10-13, user checks it in Play after restarting Studio
- [ ] Zones after the desert: playtest and balance the jungle, ocean and snow rocks
- [ ] Money sinks: no plan yet, user will raise ideas (see [[Big Numbers Over Small Ones]])

## Admin panel (approved 2026-10-08, see [[Admin Panel]])
- [ ] Phase 1 playtest: still to check: Arms picker, Set Slots, auto-preset, My Base warp
- [ ] Phase 2: Rok picker (+ trait/modifier), N geodes of a type, force any hatch rarity, fill/clear Backpack, fill pedestals; complete/reset Index page or zone, claim all; force next chop quality, always-perfect / one-hit / ignore-strength toggles, spawn a chosen rock, instant respawn; set Hot Streak tier, freeze timer; simulate N hours offline
- [ ] Phase 3: Ctrl+Shift+Space command bar, save/load snapshots (Studio)

## Waiting on the user
- [ ] Diamond Rock break and per-hit effects (Claude proposes a look first), see [[Diamond Rock]]
- [ ] Item icons — decisions D1–D6 in `IconSystemPlan.md`

## Deferred until the user raises it
- Ascended Chop (1 in 1,000)
- Master chop as a one-arm swing with its own animation (user plans to ask for it later; master reuses the normal clips until then)

## Housekeeping
- [ ] Hot Streak: share the flame icon (94131698155889, user-owned) with the game
