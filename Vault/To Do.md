---
description: Running task list for Chop a Rock — what's next, what's waiting on the user, what's deferred. Claude keeps it current.
type: project
updated: 2026-10-09
---
# To Do

Phases live in `ROADMAP.md`; this is the task-level list. Claude ticks items off (deletes them) when they're done and verified in code, and adds new ones as the user approves work. Only list things that matter now; see [[Only Surface Blocking Opens]].

## Next
- [ ] Base remodel: in Studio 2026-10-10, now 8 spots (see [[Bases]]). The user sets Max Players to 8, saves the place, playtests (claim, pedestals, pads, geode crack, training stand, spawn) and signs off; then Claude deletes `ServerStorage.Model_BasePlot_Old`. The lobby lighting tints the black and grey blue
- [ ] Training upgrade tiers: user rejected the plain Board/Bricks/Glass/Steel ladder (2026-10-10), wants each tier to feel harder and look cooler. Six tiers (Wood, Brick, Steel, Vault, Energy Core, Cosmic) were drafted, each with its own stand. ChatGPT prompt given; waiting on the reference sheet. Names, unlocks and multipliers not decided
- [ ] Zone rock models with props (2026-10-10): all 12 desert, jungle, ocean and snow rocks are built, uploaded and wired into Studio, and checked by value in Play. Still to do: the user saves the place, watches a perfect break in each zone, and commits the code (`RockTemplate`, `SplitModel`, `Effects`, `AssetRegistry`). The white snow props glow under bloom; tone them down if that bothers the user. See [[Zone Rocks Reference]]
- [ ] Rush Rocks: user watches it in Play and signs off the look; real chime and tick sounds (placeholders now), see [[Rush Rocks]]
- [ ] Diamond Rock: user watches it in Play and signs off the look; test with 2+ players (Studio local server); real crystal model (`model-workflow`) and sounds, see [[Diamond Rock]]

## Batch approved 2026-10-10
- [ ] Built 2026-10-10, not committed: shopkeeper, shops centred, `RobuxShop` placeholder, Hot Streak easy-rock gate (25x draft), Diamond economy (no streak, x15), Diamond sound slots, rebirth formulas + Luck row with clover icon, sound subfolders, Teleport Bar (colours and 3 s cooldown drafts). User saves the place, plays a Diamond with Hot Streak, an easy rock and the bar on phone size, then commits
- [ ] Diamond Rock sounds: paste SoundIds into `Assets/Sounds/Diamond/SFX_Diamond_Shimmer/Beacon/Shatter/Tick/Despawn/Payout`. Shatter and Payout untested until then
- [ ] Robux shop contents (not planned yet; panel is an empty yellow `StarterGui.RobuxShop`)
- [ ] Unused Decal `113266790078316` (failed clover upload) can be deleted from the group
- [ ] Long numbers ("24,414,062,500") on rock labels, Index detail, geode text, Sell Shop: switch to compact? (asked 2026-10-10)
- [ ] Zones after the desert: placeholder rocks, signs and spawn areas for jungle, ocean, snow are built (2026-10-10), playtest and balance them; Roks, geodes, geode stands and Index Roks pages wait on models (see [[Zones After Desert]])
- [ ] Money sinks: no plan yet, user will raise ideas (see [[Big Numbers Over Small Ones]])

## Admin panel (approved 2026-10-08, see [[Admin Panel]])
- [ ] Phase 1 playtest: Desert preset, Set Cash "2.5m" and the Desert warp checked in Play 2026-10-09; still to check: Arms picker, Set Slots, Set Level, auto-preset, My Base warp
- [ ] Phase 2: Rok picker (+ trait/modifier), N geodes of a type, force any hatch rarity, fill/clear Backpack, fill pedestals; complete/reset Index page or zone, claim all; force next chop quality, always-perfect / one-hit / ignore-strength toggles, spawn a chosen rock, instant respawn; set Hot Streak tier, freeze timer; simulate N hours offline
- [ ] Phase 3: Ctrl+Shift+Space command bar, save/load snapshots (Studio), weather/Rush/Diamond commands as those systems land

## Waiting on the user
- [ ] Diamond Rock VFX (arrival, idle glow, beacon; built 2026-10-09): user watches it in Play with Studio in front and signs off; then upload the 12 textures in `assets/VFX/Diamond/` and replace the preview addresses. Break and per-hit effects still to do, see [[Diamond Rock]]
- [ ] Auras (built 2026-10-09, see [[Auras]]): user watches the 5 effects (showcase stands or Play) with Studio in front and signs off; then upload the 12 textures in `assets/VFX/Aura/` and replace the preview addresses (templates + `AuraConfig.Icon`). Rebirths 2 to 5 need entries in `RebirthConfig` before auras 2 to 5 can be reached. Aura Shop shopkeeper?
- [ ] Item icons — decisions D1–D6 in `IconSystemPlan.md`
- [ ] Chop animations (published 2026-10-10: WindUp 83046642519862, Strike 86582123703470, group-owned): user tunes `WindUpSpeed` and watches a Master chop in Play, see [[Chop Dummy]]

## Deferred until the user raises it
- Ascended Chop (1 in 1,000)
- Master chop as a one-arm swing with its own animation (user plans to ask for it later; master reuses the normal clips until then)

## Housekeeping
- [ ] `shared/roblox-vfx/` is untracked — commit or ignore
- [ ] Hot Streak: drop SoundIds into SFX_HotStreak_Loop / SFX_HotStreak_Up; upload head fire textures; share the flame icon (94131698155889) with the game
