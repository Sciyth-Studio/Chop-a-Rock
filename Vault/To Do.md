---
description: Running task list for Chop a Rock — what's next, what's waiting on the user, what's deferred. Claude keeps it current.
type: project
updated: 2026-10-09
---
# To Do

Phases live in `ROADMAP.md`; this is the task-level list. Claude ticks items off (deletes them) when they're done and verified in code, and adds new ones as the user approves work. Only list things that matter now; see [[Only Surface Blocking Opens]].

## Next
- [ ] Desert: real models for the three placeholder rocks (`rock-model` skill)
- [ ] Rush Rocks: user watches it in Play and signs off the look; real chime and tick sounds (placeholders now), see [[Rush Rocks]]
- [ ] Diamond Rock: user watches it in Play and signs off the look; test with 2+ players (Studio local server); real crystal model (`model-workflow`) and sounds, see [[Diamond Rock]]

## Admin panel (approved 2026-10-08, see [[Admin Panel]])
- [ ] Phase 1 playtest: Desert preset, Set Cash "2.5m" and the Desert warp checked in Play 2026-10-09; still to check: Arms picker, Set Slots, Set Level, auto-preset, My Base warp
- [ ] Phase 2: Rok picker (+ trait/modifier), N geodes of a type, force any hatch rarity, fill/clear Backpack, fill pedestals; complete/reset Index page or zone, claim all; force next chop quality, always-perfect / one-hit / ignore-strength toggles, spawn a chosen rock, instant respawn; set Hot Streak tier, freeze timer; simulate N hours offline
- [ ] Phase 3: Ctrl+Shift+Space command bar, save/load snapshots (Studio), weather/Rush/Diamond commands as those systems land

## Waiting on the user
- [ ] Diamond Rock VFX (arrival, idle glow, beacon; built 2026-10-09): user watches it in Play with Studio in front and signs off; then upload the 9 textures in `assets/VFX/Diamond/` and replace the preview addresses. Break and per-hit effects still to do, see [[Diamond Rock]]
- [ ] Auras (arms and legs only, give walk speed) — how they are earned, stacking with the streak
- [ ] Jungle, ocean and snow rock lineups (proposals not approved)
- [ ] Ocean Rok lineup — planned for beach/pirate, zone is now deep ocean
- [ ] Item icons — decisions D1–D6 in `IconSystemPlan.md`
- [ ] Chop animations (published 2026-10-10: WindUp 83046642519862, Strike 86582123703470, group-owned): user tunes `WindUpSpeed` and watches a Master chop in Play, see [[Chop Dummy]]

## Deferred until the user raises it
- Ascended Chop (1 in 1,000)
- Master chop as a one-arm swing with its own animation (user plans to ask for it later; master reuses the normal clips until then)

## Housekeeping
- [ ] `shared/roblox-vfx/` is untracked — commit or ignore
- [ ] Hot Streak: drop SoundIds into SFX_HotStreak_Loop / SFX_HotStreak_Up; upload head fire textures; share the flame icon (94131698155889) with the game
