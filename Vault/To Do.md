---
description: Running task list for Chop a Rock — what's next, what's waiting on the user, what's deferred. Claude keeps it current.
type: project
updated: 2026-10-21
---
# To Do

Phases live in `ROADMAP.md`; this is the task-level list. Claude ticks items off (deletes them) when they're done and verified in code, and adds new ones as the user approves work. Only list things that matter now; see [[Only Surface Blocking Opens]].

## Next
- [ ] Cannons and auras replace arms (approved 2026-10-18, see [[Cannons And Auras Replace Arms]]). Aura merge built, checked and committed 2026-10-19 (see [[Auras]]); row icon uploaded 2026-10-20 (waiting on saving the place). Cannon Shop built 2026-10-20 with placeholder models (see [[Cannon Shop]]): waiting on the user's playtest and saving the place; then the real stall and lobby cannon models via `model-workflow`. Cannon launch effects and sounds built 2026-10-20 (charge, blast, trail, landing, equip; see [[Cannon Shop]] § Effects); textures uploaded: waiting on the user to watch them, pick sounds from `ServerStorage.CannonSoundOptions` and save the place
- [ ] Lobby declutter (asked 2026-10-21): move the `LobbyCannon` onto the lobby's back wall and fire yourself from the Cannon Shop (red Fire button). Built 2026-10-21, check.ps1 passes: waiting on the user's playtest, saving the place and a commit
- [ ] Training tiers + strength-gated rebirth: built, checked and committed 2026-10-19 (see [[Rebirth Gated By Strength]]). Still to do: stands for zones after Snow (not started as of 2026-10-21)
- [ ] Cash packs (built 2026-10-21, see [[Cash Packs]]): direct Robux prompt since 2026-10-21 (no popup). Waiting on the user's playtest (the prompt at each buy spot, a test purchase in Studio), the draft pack sizes and Robux prices, and saving the place (sign Robux button removed, old popup moved to `ServerStorage.UIBackup.CashPacks`)
- [ ] Zone rock models with props: the user watches a perfect break in each zone. The white snow props glow under bloom; tone them down if that bothers the user. See [[Zone Rocks Reference]]
- [ ] Geode pity (added 2026-10-15, not started): a pity counter on geode hatches so a rare Rok is guaranteed after enough misses. Thresholds, which rarities count and whether it's per geode or shared aren't decided yet. Not planned yet
- [ ] Geode upgrades/levels (added 2026-10-15, not started): geodes level up or get upgraded. What a level changes and how you raise it aren't decided yet. Not planned yet
- [ ] Leaderboards (built and tested 2026-10-21, see [[Leaderboards]]): model the proper slabs (user)
- [ ] Leaderboard extras (liked 2026-10-21, not started): weekly reset tab, crown/title over #1, "You passed X!" toast

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
- Board Slice minigame polish and later training games (Board Slice saved 2026-10-21; user may improve it later, see [[Training Minigame Board Slice]])

## Housekeeping
- [ ] Hot Streak: share the flame icon (94131698155889, user-owned) with the game
