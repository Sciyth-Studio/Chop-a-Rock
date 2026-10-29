---
description: 2026-10-20, approved and built — Geode Fall, a server-wide event where 3-5 geodes crash into one zone and players race to claim and chop them for a guaranteed Rare-or-better Rok from that zone's geode; no per-player cap, claims can't be stolen, full Backpack = no Rok and the geode respawns. Built 2026-10-20, not playtested.
type: decision
---
# Geode Fall event (proposed 2026-10-20)

**Status: approved 2026-10-20 ("Build Geode Fall as the note says, including the Backpack full warning") and built the same day; how it works and where it lives: [[Geode Fall]]. The numbers below are still drafts. Built differently from this note: luck has no effect on the Rare+ split (every Rare+ rarity is lucky and scaled the same).**

The user wants geodes that spawn on the map as a random event, give guaranteed good Roks, and are shared by the whole server so "everyone races to get them", because "the game kinda lacks competition between players". Every event so far is personal ([[Rush Rocks]], [[Weather]]) or shared but co-op ([[Diamond Rock]] pays everyone by damage share). Geode Fall is the first event where one player wins something and another doesn't.

## How a fall plays
1. **Warning (10 s):** a server-wide notification and a HUD pill: "Geodes falling in the Jungle!" Only the zone is shown, not the spots, so nobody gets there before anyone else.
2. **Impact:** 3-5 geodes streak down and land at random clear spots across that zone's `RockSpawnArea`, each with a short beacon and a shadow marker 2 s before it lands. Spots are found the same way the Diamond Rock finds its spot (`RockService:FindRingSpot` / `ReserveArea`), so players' own rocks move out of the way.
3. **Claim by chopping:** the first player to start chopping a geode claims it. Their name shows on its label and only they can chop it; nobody can steal it while they keep chopping. If they stop for 3 s (walk off, get distracted, rejoin), it's free again. Arriving first gets you the claim; chopping well (fewer chops, see below) is what lands it. Once one is cracked, the winner can run for the next.
4. **Crack open:** when its health hits 0 it plays the normal geode crack and [[Hatch Reveal Reference|hatch reveal]] for the winner, and everyone nearby sees it split. A Legendary or Secret pull is announced to the whole server ("X cracked a Legendary Tiki from a Falling Geode!").
   - **Full Backpack** (`PetConfig.MaxPets`, 100): the winner gets nothing and the geode respawns, full health and unclaimed, at a new clear spot in the same zone, with the same 90 s timer still running. Claude's addition (not asked for, needs the user's OK): a "Backpack full!" warning when a player with a full Backpack claims one, so they know before they spend the chops.
5. **Despawn:** geodes nobody has cracked sink after 90 s. The pill counts down and shows how many are left ("2 of 4 left").

## Draft numbers (`GeodeFallConfig`, not approved)
| What | Draft | Why |
|---|---|---|
| Interval | every 20-25 min | rarer than the Diamond Rock (10-15 min) so it stays special |
| Never during | Weather (:00-:05, :30-:35) or a live Diamond Rock (and 2 min after one) | so events don't stack up and blur together |
| Zone | weighted by players standing in each zone, like the Diamond Rock; retry in 30 s if nobody's in a zone | it falls where people are |
| Geodes per fall | 3, +1 per 4 players above 4, max 5 | several winners per fall, but never one each |
| Per player | no cap: a player can win every geode in a fall (user, 2026-10-20: "there HAS to be competition") | |
| Warning | 10 s | everyone gets the same head start |
| Lifetime | 90 s after impact | |
| Health | 6 Good chops (Good damage × the zone's weakest-rock strength × 6) | short enough to race, long enough to fight over |
| Perfect / Master | normal chop damage, so a Perfect lands it faster | chop skill matters, not just speed |
| Claim timeout | 3 s without a chop | a claim can't be held by standing still |
| Strength gate | the zone geode's `StrengthRequired` (weakest rock in the zone) | was the same gate as buying that geode; buying is ungated since 2026-10-28, this gate stays |
| Keep-out | spots at least 40 studs from `TeleportPoints` and cannon landing points | the Rocks button and cannons can't drop you right on one |

## Reward: Rare or better from that zone's geode
The pull uses the zone's own `GeodeConfig` table with Common and Uncommon taken out, so the odds above Rare stay in the same proportions as buying one. Luck applies the same way it does to a bought geode. Odds from the current weights:

| Zone | Rare | Epic | Legendary | Secret |
|---|---|---|---|---|
| Forest | 66.7% | 26.0% | 6.7% | 0.67% |
| Desert | 62.9% | 28.6% | 7.7% | 0.86% |
| Jungle | 60.0% | 30.0% | 9.0% | 1.0% |
| Ocean | 56.0% | 32.0% | 10.4% | 1.6% |

One win is worth about 5-7 bought geodes' chance at Rare+ (Forest 15% per geode, Ocean 25%). At one fall every ~22 min, a server hands out about 8-14 an hour; with no per-player cap, one fast player could take all of them, about 13 an hour at most in a busy server. That still needs checking in the [[Balance Model]], mainly against the Index claims and Sell Shop value of Epic+ Roks.

## Fairness and server checks
- **The server owns everything.** It decides spots, claims, health and the pull. A claim or a chop counts only if the server sees the player within chop range plus slack, the same as the Diamond Rock (`ChopRangeSlackStuds`).
- **Teleport exploits:** reject a claim if the player's server position jumped more than their walk speed allows since the last check, outside an official teleport or cannon shot. This is the first reward where one player's cheat takes it from another, so it matters more here than for personal rocks.
- **New players:** the strength gate keeps players who are too weak out of zones above them, and because falls follow where players are, they still land in the forest when that's where people are.
- **Alone in a server:** it still runs. It becomes a free Rare+ Rok, which is fine.

## Reused pieces
Diamond Rock spot-finding and area reserve, its beacon/label/pill pattern, `ChopService` hits on a shared server rock, geode crack + hatch reveal, notifications, and the admin command pattern (add a "Start Geode Fall" command and key).

## Answered by the user (2026-10-20)
- **Per player:** no cap. "There HAS to be competition."
- **Floor:** Rare or better.
- **Stealing:** a claim can't be stolen.
- **Announcement:** yes, Legendary and Secret pulls go to the whole server.
- **Full Backpack:** "they don't get it and it respawns."
- **Model:** "just a geode with vfx". Each zone's existing geode model (`GeodeConfig.Geodes[zone].ModelKey` / `SplitModelKey`) with a falling trail, landing impact and a glow while it waits. No new model.

Related: [[Diamond Rock]], [[Geode Shop]], [[Weather]], [[Rush Rocks]], [[Balance Model]], [[Hatch Reveal Reference]]
