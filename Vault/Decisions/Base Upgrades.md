---
description: 2026-11-09 — 8 base levels bought from a sign at the base; each makes the pen (and plot) longer, adds a pen slot (8 to 15) and cuts hatch time 5%; no extra hatch pads; prices about 2 min of income, one level per zone Desert to Bamboo Forest (drafts)
type: decision
---
# Base upgrades (2026-11-09)

The user asked for "the base upgrade system (its just a sign you click)" with the base remodelled in Lune ([[Bases]], [[Meshlab]]).

## What the user picked
- **Levels only expand the pen.** "levels are just supposed to expand the pen ngl, more advanced stuff could potentially be an index reward" (a fancier base as an Index reward is an idea, not built).
- **Gains: more pen slots and a hatch time boost**, "needs to be balanced". +1 slot and -5% hatch per level was the pick.
- **8 levels, no more egg pads**: hatch pads stay at 8.
- **The pen only gets longer** (not wider), and the plot's floor grows with it: "it looks weird to not also have the floor under the pen match how long it currently is".

## Numbers (drafts, `BaseUpgradeConfig.Levels`)
| Level | Price | Pen slots | Hatch time | Plot / pen length |
|---|---|---|---|---|
| 1 | free | 8 | x1 | 66 / 28 |
| 2 | $500K | 9 | x0.95 | 70 / 32 |
| 3 | $40M | 10 | x0.90 | 74 / 36 |
| 4 | $3B | 11 | x0.85 | 78 / 40 |
| 5 | $200B | 12 | x0.80 | 82 / 44 |
| 6 | $15T | 13 | x0.75 | 86 / 48 |
| 7 | $1Qa | 14 | x0.70 | 90 / 52 |
| 8 | $60Qa | 15 | x0.65 | 94 / 56 (the old size) |

Level n is meant to be bought in zone n (Desert = level 2 ... Bamboo Forest = level 8), at about 2 minutes of a quarter of that zone's end income, like the mid-zone stands. Cash only: short of cash, the sign opens the [[Cash Packs]] prompt (no Robux button on signs).

## Balance (Balance Model v16, see [[Balance Model]])
- With game values it drops to 29 / 51: Pets too strong from the Swamp on (50-58% share). The hatch boost does most of it; the slots alone keep 35 / 51.
- **Applied (user picked "Trim zone 6-10 Pets", 2026-11-09):** zone 6-10 Pet income mult. is now Swamp 0.8, Savanna 0.6, Bamboo 0.55, Volcano 0.55, Golem Ruins 0.5 (it was 1 / 0.75 x4). Every zone 6-10 Pet's `MoneyPerSecond` in `PetConfig` was scaled by new ÷ old (x0.8, x0.8, x0.733, x0.733, x0.667). v16 then passes 34 / 51 with every Pets-share check passing. The rejected alternative was a smaller hatch step (-2% per level still failed Bamboo to Golem Ruins).

Related: [[Bases]], [[Pedestals]], [[Training Upgrade Sign Reference]]
