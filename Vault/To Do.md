---
description: Running task list for Chop a Rock — what's next, what's waiting on the user, what's deferred. Claude keeps it current.
type: project
updated: 2026-10-19
---
# To Do

Phases live in `ROADMAP.md`; this is the task-level list. Claude ticks items off (deletes them) when they're done and verified in code, and adds new ones as the user approves work. Only list things that matter now; see [[Only Surface Blocking Opens]].

## Next
- [ ] Cannons and auras replace arms (approved 2026-10-18, see [[Cannons And Auras Replace Arms]]). Aura merge built, checked and committed 2026-10-19 (see [[Auras]]); row icon uploaded 2026-10-20 (waiting on saving the place). Cannon Shop built 2026-10-20 with placeholder models (see [[Cannon Shop]]): waiting on the user's playtest and saving the place; then the real stall and lobby cannon models via `model-workflow`. Cannon launch effects and sounds built 2026-10-20 (charge, blast, trail, landing, equip; see [[Cannon Shop]] § Effects); textures uploaded: waiting on the user to watch them, pick sounds from `ServerStorage.CannonSoundOptions` and save the place
- [ ] Roks for zones 2-5 (started 2026-10-13): 24 Roks, lineups approved in the master plan §03 (desert) and [[Zones After Desert]] (jungle, ocean, snow). One zone at a time, desert first, `model-workflow` per Rok with Bloky's body and eyes ([[Reuse Rok Eyes]]). Desert done 2026-10-14 (models, `PetConfig`, Desert Geode, Index zone, Geode Shop tab; see [[Geode Shop]]). Jungle in config 2026-10-16 (`PetConfig`, Jungle Geode, Index zone, pink geode models, Bloomy petals Neon); waiting on the user's playtest and saving the place. Ocean in config 2026-10-19 (`PetConfig`, Ocean Geode, Index zone, coral geode models); waiting on saving the place. Snow in config 2026-10-20 (`PetConfig`, Snow Geode, Index zone, frost blue geode models); waiting on the user's playtest and saving the place. Next zones: models, then `PetConfig`, `GeodeConfig.Geodes.<Zone>` with `TabName` and `Order`, geode models and the Index Roks zone (`new-zone` step 6)
- [ ] Training tiers + strength-gated rebirth: built, checked and committed 2026-10-19 (see [[Rebirth Gated By Strength]]). Still to do: stands for zones after Snow
- [ ] Training Robux buys cash (2026-10-18, see [[Rebirth Gated By Strength]]): rename the five stand developer products on Roblox to their cash amounts
- [ ] Zone rock models with props: the user watches a perfect break in each zone. The white snow props glow under bloom; tone them down if that bothers the user. See [[Zone Rocks Reference]]
- [ ] Training minigames (added 2026-10-15): design approved 2026-10-20 (see [[Training Minigame Board Slice]]). First game, Board Slice, built and checked in Play and committed 2026-10-20: waiting on the user's playtest (feel, look, phone swipe), the draft numbers in `TrainingMinigameConfig` and saving the place (new `StarterGui.TrainingMinigame`). Later games not chosen yet
- [ ] Geode pity (added 2026-10-15, not started): a pity counter on geode hatches so a rare Rok is guaranteed after enough misses. Thresholds, which rarities count and whether it's per geode or shared aren't decided yet. Not planned yet
- [ ] Geode upgrades/levels (added 2026-10-15, not started): geodes level up or get upgraded. What a level changes and how you raise it aren't decided yet. Not planned yet
- [ ] Leaderboards (added 2026-10-21, not started): which stats get boards (cash, strength, rebirths, Roks found…), in-world boards or a UI screen, and global or per-server aren't decided yet. Not planned yet

## Admin panel (approved 2026-10-08, see [[Admin Panel]])
- [ ] Phase 1 playtest: still to check: Arms picker, Set Slots, auto-preset, My Base warp
- [ ] Next ideas (not approved): target picker so commands act on other players, inspect a player, kick/ban, server announcement, admin action log

## Waiting on the user
- [ ] Cap pad banking while a player is online and AFK? Pads fill without limit during a live session; only offline time is capped (4 h). See [[Pedestals]].
- [ ] Diamond Rock break and per-hit effects (Claude proposes a look first), see [[Diamond Rock]]
- [ ] Item icons — decisions D1–D6 in `IconSystemPlan.md`
- [ ] Cannon hint (staggered tutorial): built 2026-10-20 from `CannonHintSystemPlan.md`, passes check.ps1; waiting on the user's playtest. See [[Tutorial]] § Staggered hints

## Deferred until the user raises it
- Ascended Chop (1 in 1,000)
- Master chop as a one-arm swing with its own animation (user plans to ask for it later; master reuses the normal clips until then)

## Housekeeping
- [ ] Hot Streak: share the flame icon (94131698155889, user-owned) with the game
